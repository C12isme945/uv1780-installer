param([string]$InstallerPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2
$root=Split-Path $PSScriptRoot
$source=Join-Path $root 'install.ps1'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($source,[ref]$tokens,[ref]$errors)
if($errors.Count){throw ($errors|Out-String)}
foreach($fn in $ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst]},$false)){. ([scriptblock]::Create($fn.Extent.Text))}
$script:checks=0
function Assert-Test([bool]$Condition,[string]$Name){if(-not $Condition){throw ('FAILED: '+$Name)};$script:checks++;Write-Output ('PASS: '+$Name)}
foreach($address in @('http://example.com/a.exe','file:///C:/a.exe','https://user:pass@example.com/a.exe','not a URL')) {
    $rejected=$false;try{Assert-UvHttps $address|Out-Null}catch{$rejected=$true}
    Assert-Test $rejected ('Reject non-HTTPS or credential-bearing URL: '+$address)
}
Assert-Test ((Assert-UvHttps 'https://example.com/a.exe?signature=abc').Scheme -eq 'https') 'Accept signed HTTPS mirror URL'
Assert-Test (@($ast.FindAll({param($n)$n -is [Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Read-Host'},$true)).Count -eq 0) 'Public installation never prompts for credentials'
Assert-Test (-not $ast.Extent.Text.Contains('UV1780_GITHUB_TOKEN')) 'Public installation does not read GitHub tokens'
$scratch=Join-Path ([IO.Path]::GetTempPath()) ('uv1780-test-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch|Out-Null
try {
    $file=Join-Path $scratch 'test.bin'
    [IO.File]::WriteAllBytes($file,[byte[]]@(1,2,3))
    $hash=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
    Assert-UvInstaller $file $hash 3
    Assert-Test $true 'Accept correctly pinned file'
    $rejected=$false;try{Assert-UvInstaller $file ('0'*64) 3}catch{$rejected=$true}
    Assert-Test $rejected 'Reject changed payload with unchanged size'
    $rejected=$false;try{Assert-UvInstaller $file $hash 4}catch{$rejected=$true}
    Assert-Test $rejected 'Reject incorrect payload size'
    if($InstallerPath) {
        $result=& $source -LocalInstaller $InstallerPath -DownloadOnly -CacheDirectory (Join-Path $scratch 'cache')
        Assert-Test ($result.Status -eq 'downloaded-and-verified') 'Verify real release offline without elevation or installation'
    }
}finally{
    $resolved=[IO.Path]::GetFullPath($scratch)
    $tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
    if($resolved.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($resolved) -match '^uv1780-test-[0-9a-f]{32}$') {Remove-Item -LiteralPath $resolved -Recurse -Force}
}
Write-Output ('Passed '+$script:checks+' checks.')
