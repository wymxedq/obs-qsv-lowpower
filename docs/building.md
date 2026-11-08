# 从源码构建

以下命令在仓库根目录执行。

安装 Git、CMake ≥3.28、Visual Studio 2022（C++ 桌面开发及 Windows SDK）和 OBS 33.0.1 x64，然后在 PowerShell 执行：

```powershell
./scripts/build.ps1 -ObsRoot 'C:\Program Files\obs-studio'
```

脚本将下载固定提交的 OBS 头文件和 Intel libvpl，在本仓库 `deps/`、`build/` 构建，并写入 `dist/`，不会自动安装插件。导入库由本机原版 OBS DLL 导出表生成。请勿把它用于不可信的 OBS 安装目录。

上游固定版本：

- OBS 33.0.1：`65c320b46e1af5c7a555161aea6182cdf7a8c524`
- Intel libvpl：`412c5cffe3022d5ebb8a955c3b30afe7bd2e3929`（静态调度库，设备运行时仍来自驱动）

首次验证使用 MSVC 19.39、Windows SDK 10.0.22621.0、CMake 4.4.4、Release x64、C11/C++17。不同工具链重建的哈希可能不同。
