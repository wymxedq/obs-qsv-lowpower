# QSV Low Power 插件修改说明

结论：做了源码修改，不是只改编译选项。基于 OBS Studio 33.0.1 的 QSV 插件源码，3个上游文件修改，Git统计13行新增、14行删除；另有独立CMake构建文件和本地测试程序。

## 功能修改

1. QSV_Encoder_Internal.cpp：对HEVC明确设置 m_mfxEncParams.mfx.LowPower = MFX_CODINGOPTION_ON，选择Intel提供的Low Power硬件编码路径。没有重写HEVC算法或码率控制器。
2. obs-qsv11.c与内部参数初始化：将该实验HEVC编码器的 nLADEPTH 设为0。参数层和底层各设置一次，防止LowPower启用后沿用原先latency=normal所生成的60帧前瞻请求。该插件当前不提供前瞻开关。
3. QSV_Encoder_Internal.cpp：GetVideoParam后打印LowPower、TargetUsage、AsyncDepth，验证驱动实际接受值。当前日志语句位于状态检查前，因此初始化失败时不可把这一行单独当成成功证据；本次验证同时确认了返回成功、输出启动和有效码流。

## 独立注册

- 显示名称变更为 QuickSync HEVC (Low Power - Experimental)。
- 两个HEVC编码器ID变为 obs_qsv11_hevc_lowpower 与 obs_qsv11_hevc_lowpower_soft；纹理路径回退目标也一起改名。
- 移除本模块对H.264、AV1编码器的注册，避免与原版重复注册；原版模块继续提供原有编码器。
- 新DLL为obs-qsv-lowpower.dll，未替换原obs-qsv11.dll。

## 构建方式

采用独立CMake工程，仅构建该插件，没有重新编译或替换OBS主程序。
Release x64，MSVC19.39，Windows SDK10.0.22621.0，CMake4.4.4；C11/C++17。
ENABLE_HEVC用于编入HEVC支持，/utf-8、/W3等是构建选项；它们不是性能变化的主要原因。
Intel VPL调度库从官方libvpl commit 412c5cffe3022d5ebb8a955c3b30afe7bd2e3929 构建并静态链接。OBS源commit为65c320b46e1af5c7a555161aea6182cdf7a8c524。
链接本机原版obs.dll与w32-pthreads.dll，导入库根据DLL导出符号生成。没有修改Intel显卡驱动。

## 配置与算法边界

TU1、6400kbps、1080p60、B帧2是在独立测试配置中设置，不是把这些值写死在插件里。其他参数继续使用原QSV实现。
Low Power和普通路径的内部编码工具及质量/速度取舍由Intel驱动实现。两者都返回TargetUsage1，不保证等画质。
该插件强制HEVC LowPower并关闭前瞻，是实验版本，不是通用于所有平台的官方替代品。未来OBS升级需重新核对API和兼容性。

## 验证

独立OBS运行库60秒回放测试：驱动返回LowPower=16（ON）、TargetUsage=1、AsyncDepth=4；编码跳帧0/3601。
安装后的桌面OBS约一分钟回放测试：outputSkippedFrames=0、outputTotalFrames=3578，HEVC1080p60及AAC音频正常。
同一20秒素材离线画质对照：普通TU1 VMAF87.85、LowPowerTU1 VMAF89.41；这仅是该段已压缩参考素材的二次编码比较，不是普遍画质结论。

DLL SHA256：191724EDB55F80F20B8726E22F10E3FC5B328F9E59F32D83BE8FCEF1A77C73EF。
源码补丁、独立CMake和插件完整源码见公开仓库。公开包不含本地测试程序及原始日志。许可证见LICENSE、src和licenses目录。
