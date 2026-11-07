# OBS QSV HEVC Low Power（实验版）

为 OBS Studio 增加独立的 **QuickSync HEVC (Low Power - Experimental)** 编码器。基于 OBS 33.0.1 QSV 源码，强制 Intel HEVC Low Power 路径并关闭前瞻；用于排查普通路径 TU1 编码跟不上实时帧率的问题。

这是个人实验项目，与 OBS Project / Intel 无隶属关系。不是通用修复，也不保证所有硬件、驱动、OBS 版本或直播平台可用。

## 下载与安装

从本仓库 Releases 下载 ZIP，校验 SHA256。仅实测 Windows x64、OBS 33.0.1、i5-12600K / UHD 770，OBS 在独显上渲染。需要 Intel 显卡驱动、支持 HEVC Low Power 的 Intel 核显，以及 Visual C++ 2015–2022 x64 运行库。插件未签名，请审查源码并自行决定是否运行。

1. 完全退出 OBS，备份现有配置。
2. 将 ZIP 中 `obs-plugins` 和 `data` 文件夹合并复制到 OBS 安装根目录。可能需要管理员权限；不要删除或替换原版 QSV DLL。
3. 打开 OBS，在高级输出中选择 **QuickSync HEVC (Low Power - Experimental)**。
4. 先复制一份配置测试。直播用 CBR，码率和关键帧间隔遵守平台要求，并确认平台允许 HEVC；CQP 录制结果不能直接代表同码率 CBR 直播结果。
5. 检查“统计”中的编码跳帧和日志，以及实际输出能否正常解码。不要仅凭 CPU 使用率判断编码器余量。

TU1、6400 kbps、1080p60、B 帧 2 都是测试配置，未写死。建议先保留自己已经验证稳定的参数。无需为了本插件修改 BIOS 功耗、电流、CEP 或超频选项。

## 修改了什么

- HEVC 设置 `LowPower=MFX_CODINGOPTION_ON`；初始化和前端参数层均将 `nLADEPTH` 清零。
- 增加驱动接受的 LowPower / TargetUsage / AsyncDepth 日志。
- 使用独立编码器 ID 和 DLL 名，只注册 HEVC，避免与原版 H.264 / HEVC / AV1 重复注册。
- 没有重写码率控制、HEVC 算法，没有修改 OBS 主程序或 Intel 显卡驱动。

完整说明见 [CHANGES.md](CHANGES.md)，相对上游的三文件补丁见 [patches](patches/obs-33.0.1-lowpower.patch)。`src/` 保留该插件对应源码及原始版权声明。

## 限制与排查

Low Power 是 Intel 驱动提供的另一条编码路径，并非降低分辨率或帧率的开关。同样 TU1 不保证相同工具组合或画质；目标平台不支持时可能初始化失败。该版本强制关闭前瞻，没有切换回普通路径的开关；需要普通路径时选择原版编码器。

日志中的 `LowPower=16` 表示 ON。当前参数日志在返回状态检查前输出，必须同时确认初始化成功和有效码流，不能把这一行单独当作成功证据。OBS 升级后必须重新验证 API、加载和输出兼容性。核显运行 OBS 时的跨显卡捕获问题与此插件是不同环节；本插件不要求开启 SLI/Crossfire 捕获兼容选项。

如启动失败、黑屏或输出异常，先切换回原版编码器。卸载时退出 OBS，仅删除 `obs-plugins/64bit/obs-qsv-lowpower.dll` 与 `data/obs-plugins/obs-qsv-lowpower`。不要删除原版 `obs-qsv11`。

## 验证结果与画质边界

本机独立 OBS 运行库回放约 60 秒：驱动返回 LowPower ON、TU1、AsyncDepth 4，编码跳帧 0/3601。安装后的桌面 OBS 回放测试编码跳帧 0/3578。这些是回放验证，不是所有游戏、持续直播或其他驱动的稳定性保证。

同一段 20 秒、已压缩参考素材，1080p60、CBR 目标 6400 kbps、TU1、B2、GOP120 的离线 FFmpeg 对比：

| 路径 | 实际视频码率 | 平均 VMAF | SSIM | 平均 PSNR |
|---|---:|---:|---:|---:|
| 普通 TU1 | 6.586 Mb/s | 87.849 | 0.984218 | 37.473 dB |
| Low Power TU1 | 6.391 Mb/s | 89.408 | 0.985325 | 37.955 dB |

采用 Netflix vmaf_v0.6.1 模型。实际码率约差 3%，并非严格等码率。局部帧 Low Power 也可能更差；短片的平均值不能推出普遍画质更高或无损。原始录制、截图和包含个人路径的日志不随公开仓库发布。

## 从源码构建

安装 Git、CMake ≥3.28、Visual Studio 2022（C++ 桌面开发及 Windows SDK）和 OBS 33.0.1 x64，然后在 PowerShell 执行：

```powershell
./scripts/build.ps1 -ObsRoot 'C:\Program Files\obs-studio'
```

脚本将下载固定提交的 OBS 头文件和 Intel libvpl，在本仓库 `deps/`、`build/` 构建，并写入 `dist/`，不会自动安装插件。导入库由本机原版 OBS DLL 导出表生成。请勿把它用于不可信的 OBS 安装目录。

上游固定版本：

- OBS 33.0.1：`65c320b46e1af5c7a555161aea6182cdf7a8c524`
- Intel libvpl：`412c5cffe3022d5ebb8a955c3b30afe7bd2e3929`（静态调度库，设备运行时仍来自驱动）

首次验证使用 MSVC 19.39、Windows SDK 10.0.22621.0、CMake 4.4.4、Release x64、C11/C++17。不同工具链重建的哈希可能不同。

## 许可证

本项目按 GPL-2.0 发布，见 [LICENSE](LICENSE)。保留上游文件的原始许可证声明；部分 Intel QSV 源码提供 BSD-3-Clause / GPL-2.0 双许可，见 `src/obs-qsv11-LICENSE.txt` 和澄清邮件。Intel libvpl 使用 MIT 许可，见 `licenses/Intel-VPL-LICENSE`。OBS 和 Intel 商标归各自所有者。本软件不提供担保。
