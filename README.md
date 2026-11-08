# OBS QSV HEVC Low Power

一个用于 Windows OBS Studio 的实验性 HEVC 编码插件。使用 Intel 的 Low Power（VDEnc）编码路径，可在部分设备上提升 QSV HEVC 编码性能。

插件会新增 **QuickSync HEVC (Low Power - Experimental)**，与原版 QSV 编码器并存。

[下载安装包](https://github.com/wymxedq/obs-qsv-lowpower/releases) · [技术说明](docs/technical-notes.md) · [构建方法](docs/building.md)

## 使用要求

- Windows x64、OBS Studio 33.0.1。
- 支持 **HEVC Low Power** 的 Intel GPU，并已安装显卡驱动。
- Visual C++ 2015–2022 x64 运行库。

目前已在 **i5-12600K / UHD 770** 上验证，OBS 使用独显渲染。其他设备和 OBS 版本尚未实测；发布插件未签名。

### 哪些显卡支持？

| 平台 | HEVC Low Power |
|---|---|
| 第 6～9 代酷睿核显 | 不支持 |
| 第 10 代 Comet Lake 核显 | 不支持 |
| 第 10 代 Ice Lake 核显 | 支持 |
| 第 11～14 代酷睿对应核显 | 支持 |
| Core Ultra 的 Meteor Lake、Arrow Lake、Lunar Lake 核显 | 支持 |
| Intel DG1、Arc A / B 系列独显 | 支持 |
| Apollo Lake、Gemini Lake 核显 | 不支持 |

注意第 10 代存在两种架构，不能仅凭“第 10 代”判断。**i5-6300HQ / HD 530、HD/UHD 620 和 UHD 630 不支持这里需要的 HEVC Low Power**，即使它们支持普通 QSV HEVC 编码。

这张表是硬件能力参考，不是插件实测名单。依据为 Intel 的 [HEVC VDEnc 能力表](https://github.com/intel/media-driver/blob/master/docs/media_features.md#supported-encoding-input-format-and-max-resolution)和[平台分类](https://github.com/intel/media-driver#supported-platforms)；这些资料来自 Linux 驱动，Windows 下能否使用仍取决于具体驱动。未列出的平台需另行核查。

## 安装

1. 从 [Releases](https://github.com/wymxedq/obs-qsv-lowpower/releases) 下载 Windows x64 ZIP 安装包。
2. 完全退出 OBS。
3. 解压，将 `obs-plugins` 和 `data` 文件夹复制到 OBS 安装目录，合并同名文件夹。
4. 启动 OBS，在“设置 → 输出”中选择高级模式，再选择 **QuickSync HEVC (Low Power - Experimental)**。

安装后目录应如下所示：

```text
obs-studio/
├─ obs-plugins/64bit/obs-qsv-lowpower.dll
└─ data/obs-plugins/obs-qsv-lowpower/locale/
```

原版 QSV 插件保留，无需替换。首次使用建议复制一份 OBS 配置，保留原来的稳定设置。

## 使用建议

先沿用自己的分辨率、帧率和码率，录制后检查 OBS“统计”中的编码跳帧，并播放文件确认输出正常。TU1、6400 kbps、1080p60、B 帧 2 是本项目的测试参数，不是固定要求。

编码时请确认平台支持 HEVC，按平台要求设置 CBR、码率及关键帧间隔。CQP 录制效果不能直接代表 CBR 直播效果。

Low Power 不代表降频或降低分辨率。同一 TU 档位下，它与普通路径的画质也可能不同。本项目的短片对比没有显示平均画质下降，但不足以保证所有场景的效果；测试数据和前瞻设置见[技术说明](docs/technical-notes.md)。

## 常见问题

**选择后无法开始录制怎么办？**

先切回原版编码器。硬件支持 Low Power，也可能不支持当前的位深、码率控制或 B 帧组合。查看 OBS 日志中的初始化错误；要确认实际采用了 Low Power，还需结合成功输出及 `LowPower=16` 的参数日志，不能只看编码器名称。

**安装后一定会更快吗？**

不一定。如果原版已经采用 Low Power，或者瓶颈在游戏捕获、渲染、磁盘等其他环节，插件可能没有帮助。无需为本插件调整 BIOS 电流限制、CEP 或超频设置。

**如何卸载？**

退出 OBS，删除以下两项，再选择原版编码器：

- `obs-plugins/64bit/obs-qsv-lowpower.dll`
- `data/obs-plugins/obs-qsv-lowpower/`

## 源码与许可证

基于 OBS Studio 33.0.1 的 QSV 插件修改，采用 GPL-2.0 许可。项目与 OBS Project、Intel 无隶属关系。

[修改说明](CHANGES.md) · [上游补丁](patches/obs-33.0.1-lowpower.patch) · [构建方法](docs/building.md) · [许可证](LICENSE)

上游版权及许可证声明保留在 `src/`，Intel libvpl 的 MIT 许可证位于 `licenses/`。
