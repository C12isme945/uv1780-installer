# UV-1780 / UVProbe Windows 一行安装

适用于 Intel/AMD Windows 10（32/64 位）和 Windows 11（64 位）。使用系统自带 Windows PowerShell，无需 Python、Git、WSL、Office 或预装 VC++。默认预装软件和驱动，不需要连接仪器。

## 一行安装

在 Windows PowerShell 或 Windows 终端中运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://cdn.jsdelivr.net/gh/C12isme945/uv1780-installer@v2.70.2.2/install.ps1 | iex"
```

完整安装包已按所有者要求[公开发布](https://github.com/C12isme945/uv1780-packages/releases/tag/v2.70.2)，**不需要 GitHub 账号或 token**。脚本会匿名下载固定版本，校验文件大小和 SHA256，再请求 Windows 管理员权限安装。安装完成后可断网使用；仪器连接仍需在 UVProbe 内配置和确认。

如果 jsDelivr 不可达，可从 [GitHub 源码](https://github.com/C12isme945/uv1780-installer/blob/v2.70.2.2/install.ps1)下载脚本后执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

也可以直接从 Releases 下载 EXE，双击完成离线安装。

## 可切换下载源

目前没有配置或验证大陆直连的二进制镜像，不能保证 GitHub 下载在大陆可达。jsDelivr 只分发脚本。脚本已支持自定义 HTTPS 下载源，先尝试指定源，失败后回退到公开 GitHub Releases。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -InstallerUrl 'https://your-download-host.example/UV1780_UVProbe270_Setup.exe'
```

上面的域名是示例，需替换为实际地址。也可以设置 `UV1780_INSTALLER_URL` 后使用一行安装命令。多个地址通过 `-MirrorUrls` 传入。所有下载源都必须通过固定 SHA256 校验；安装脚本不读取或发送 GitHub token。

## 离线安装与仅下载

先把 EXE 和脚本复制到目标电脑，再运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -LocalInstaller .\UV1780_UVProbe270_Setup.exe
```

仅下载并校验，不安装：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -DownloadOnly
```

## 版本和验证

安装入口版本为 **2.70.2.2**，部署包保持 **2.70.2**，文件大小 **18,834,906 字节**。

```text
FE84BC5DD5FA0C552FCF3FC5DB20939F34E3C86ACAB03CD70FB8DB3471FF0FEA
```

默认缓存和安装日志位于 `%LOCALAPPDATA%\UV1780\Installer\2.70.2`。下载、缓存复用和执行前均校验哈希。不会自动重启或启动测量。ARM Windows 和 S 模式不支持。

42 项包回归检查及 148 项组件加载检查已通过；全新 Windows 实装和完整仪器测量仍未完成验收。公开 Releases 提供断网验收工具。

## 范围

本仓库提供自主编写的安装脚本，完整原厂软件位于公开部署包仓库。脚本的 MIT 许可证仅适用于本仓库脚本，不改变原厂软件与第三方组件的许可。
