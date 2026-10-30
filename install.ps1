[CmdletBinding()]
param(
    [string]$InstallerUrl=$env:UV1780_INSTALLER_URL,
    [string[]]$MirrorUrls=@(),
    [string]$LocalInstaller,
    [string]$CacheDirectory,
    [switch]$DownloadOnly,
    [switch]$NoPrompt,
    [switch]$InteractiveSetup
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2

function Assert-UvInstaller([string]$Path,[string]$Sha256,[long]$Size) {
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){throw 'Installer file does not exist.'}
    if((Get-Item -LiteralPath $Path).Length -ne $Size){throw 'Installer size does not match this release.'}
    if((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne $Sha256){throw 'Installer SHA256 does not match this release. The file will not be run.'}
}
function Assert-UvHttps([string]$Address) {
    $uri=$null
    if(-not[Uri]::TryCreate($Address,[UriKind]::Absolute,[ref]$uri) -or $uri.Scheme -ne 'https' -or $uri.UserInfo){throw 'Download addresses must use HTTPS without embedded credentials.'}
    return $uri
}
function Receive-UvFile([string]$Address,[string]$Path) {
    $uri=Assert-UvHttps $Address
    Write-Host ('Downloading from '+$uri.DnsSafeHost+' ...')
    # Public downloads never use account credentials.
    Invoke-WebRequest -UseBasicParsing -Uri $uri.AbsoluteUri -OutFile $Path -TimeoutSec 60 -MaximumRedirection 5 | Out-Null
}
function Invoke-UvInstall {
    $version='2.70.2'
    $fileName='UV1780_UVProbe270_Setup.exe'
    $expectedSha256='FE84BC5DD5FA0C552FCF3FC5DB20939F34E3C86ACAB03CD70FB8DB3471FF0FEA'
    $expectedSize=18834906
    $repository='C12isme945/uv1780-packages'
    $tag='v2.70.2'
    if([Environment]::OSVersion.Version.Major -lt 10 -or $PSVersionTable.PSVersion.Major -lt 5){throw 'Windows 10/11 with built-in Windows PowerShell 5.x is required.'}
    if($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64'){throw 'Windows ARM is not supported by this instrument software.'}
    [Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    if(-not $CacheDirectory){$CacheDirectory=Join-Path $env:LOCALAPPDATA ('UV1780\Installer\'+$version)}
    $cache=[IO.Path]::GetFullPath($CacheDirectory)
    New-Item -ItemType Directory -Path $cache -Force|Out-Null
    $destination=Join-Path $cache $fileName
    $verified=$false
    if($LocalInstaller) {
        $destination=[IO.Path]::GetFullPath($LocalInstaller)
        Assert-UvInstaller $destination $expectedSha256 $expectedSize
        $verified=$true
    } elseif(Test-Path -LiteralPath $destination -PathType Leaf) {
        try {Assert-UvInstaller $destination $expectedSha256 $expectedSize;$verified=$true;Write-Host 'Using the verified cached installer.'}
        catch {Write-Host 'The cached copy is invalid; a verified replacement is required.'}
    }
    $temporary=Join-Path $cache ($fileName+'.'+[guid]::NewGuid().ToString('N')+'.part')
    $sources=@()
    if($InstallerUrl){$sources+=$InstallerUrl}
    $sources+=@($MirrorUrls|Where-Object {$_})
    $sources+=('https://github.com/'+$repository+'/releases/download/'+$tag+'/'+$fileName)
    try {
        if(-not $verified) {
            foreach($source in $sources) {
                try {
                    Receive-UvFile $source $temporary
                    Assert-UvInstaller $temporary $expectedSha256 $expectedSize
                    Move-Item -LiteralPath $temporary -Destination $destination -Force
                    $verified=$true;break
                }catch {Write-Host ('Download source failed: '+$_.Exception.Message)}
            }
        }
        if(-not $verified) {
            throw 'All public download sources failed. Set UV1780_INSTALLER_URL, provide -MirrorUrls, or use -LocalInstaller. No GitHub login is required.'
        }
    }finally{if(Test-Path -LiteralPath $temporary){Remove-Item -LiteralPath $temporary -Force}}
    Assert-UvInstaller $destination $expectedSha256 $expectedSize
    Write-Host ('Verified UVProbe deployment package '+$version+'.')
    if($DownloadOnly){return [pscustomobject]@{Version=$version;Path=$destination;SHA256=$expectedSha256;Status='downloaded-and-verified'}}
    $arguments=@('/NORESTART','/PREINSTALL=1',('/LOG="'+(Join-Path $cache 'setup.log')+'"'))
    if(-not $InteractiveSetup){$arguments+=@('/VERYSILENT','/SUPPRESSMSGBOXES')}
    $identity=[Security.Principal.WindowsIdentity]::GetCurrent()
    $admin=(New-Object Security.Principal.WindowsPrincipal($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    Write-Host 'Installing software and staging the driver. Allow the Windows administrator prompt if shown.'
    if($admin){$process=Start-Process -FilePath $destination -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru}
    else {$process=Start-Process -FilePath $destination -ArgumentList $arguments -Verb RunAs -WindowStyle Hidden -Wait -PassThru}
    if($process.ExitCode -notin @(0,3010)){throw ('Setup failed with code '+$process.ExitCode+'. Details: '+(Join-Path $cache 'setup.log'))}
    if($process.ExitCode -eq 3010){Write-Host 'Installation complete. Windows requests a restart; restart when convenient.'}
    else {Write-Host 'Installation complete. Connect the instrument later and run the desktop device configuration tool.'}
    return [pscustomobject]@{Version=$version;Status='installed';RebootRequired=($process.ExitCode -eq 3010)}
}
Invoke-UvInstall
