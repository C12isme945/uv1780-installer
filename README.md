# UV-1780 / UVProbe Windows 安装入口

适用于 Intel/AMD Windows 10（32/64 位）和 Windows 11（64 位）。使用系统自带 Windows PowerShell，无需 Python、Git、WSL、Office 或预装 VC++。默认预装软件和驱动，不要求连接仪器。

## 一行安装

在 **Windows PowerShell** 或 Windows 终端中运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://cdn.jsdelivr.net/gh/C12isme945/uv1780-installer@v2.70.2/install.ps1 | iex"
```

该地址只提供公开的安装脚本。完整软件包保存在 [私有 Releases](https://github.com/C12isme945/uv1780-packages/releases/tag/v2.70.2)，因为其中含有原软件登记资料。第一次从 GitHub 下载时，脚本会隐藏输入地询问有该私有仓库读取权限的 GitHub token；不会要求目标电脑安装 GitHub CLI。细粒度 token 仅需允许此仓库的 Contents 读取。仓库管理员须先授予使用者仓库访问权限。

如果 jsDelivr 不可达，可从 [GitHub 源码](https://github.com/C12isme945/uv1780-installer/blob/v2.70.2/install.ps1)下载脚本后运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

## 可切换下载源

目前尚未配置或验证大陆直连的安装包下载源，**不能保证大陆网络可直接下载完整包**。jsDelivr 是脚本备用入口，不是已验证的国内二进制镜像。未来有国内 HTTPS 下载地址后，同一脚本即可使用，不需要 GitHub token。

指定安装包的完整 HTTPS URL：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -InstallerUrl 'https://your-download-host.example/UV1780_UVProbe270_Setup.exe'
```

上面的域名是示例，须替换为真实地址。也可以设置 `UV1780_INSTALLER_URL` 后使用一行安装命令。多个地址可通过 `-MirrorUrls` 传入，按顺序下载；全部失败才尝试 GitHub。GitHub token 只发往官方 API，不会发给镜像。

在无需联网的电脑上，先复制原安装包和脚本，再运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -LocalInstaller .\UV1780_UVProbe270_Setup.exe
```

仅下载与校验、暂不安装：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -DownloadOnly
```

自动化环境可通过 `UV1780_GITHUB_TOKEN` 提供 token，并加 `-NoPrompt`；不要把 token 写进公开脚本、URL 或命令历史。

## 固定版本和校验

当前固定部署包为 **2.70.2**，文件大小 **18,834,906 字节**。脚本在下载后、复用缓存时和执行前检查大小与 SHA256；错误文件不会执行。

```text
FE84BC5DD5FA0C552FCF3FC5DB20939F34E3C86ACAB03CD70FB8DB3471FF0FEA
```

默认缓存和安装日志位于 `%LOCALAPPDATA%\UV1780\Installer\2.70.2`。允许 Windows 管理员提示后安装，不自动重启，不启动仪器测量。软件包自带完整的 32 位 CRT/MFC 运行库；ARM Windows 与 S 模式不支持。

42 项包回归检查及 148 项组件加载检查已通过；全新 Windows 管理员实装和完整仪器测量尚未完成验收。验收工具在私有 Release 中。

## 范围与授权

本仓库只公开自主编写的下载和安装脚本，不公开原厂程序、数据库、登记资料或测量文件。该脚本不新增或绕过软件授权。原厂软件仅应在已有授权范围内使用。MIT 许可证仅适用于本仓库的脚本，不适用于私有软件包或第三方组件。
