# TEC-8 电子钟

本工程面向 `TEC-8 + EPM7128SLC84-15`，显示格式为 `HH:MM:SS`。

本版按照 PPT 平台约束修正为单时钟同步结构：`CP2` 只用于内部同步与按键采样，`CP3` 作为外部秒脉冲输入，避免 `PULSE/QD` 被综合成异步控制后在板上乱跳。

## 控制方式

- `CLR#`：低电平异步复位到 `00:00:00`
- `QD`：运行/暂停切换
- `PULSE`：暂停状态下单步校时
- `K0=1`：`PULSE` 加 1 小时
- `K1=1`：`PULSE` 加 1 分钟

校时时会把秒清零，便于重新对时。

## 时钟说明

- `CP2`：同步采样时钟，接 PPT 中的 `1KHz/100Hz` 引脚
- `CP3`：运行计时基准，接 PPT 中的 `10Hz/1Hz` 引脚

结合 [实验五+六-预习.pdf](/D:/clock/实验五+六-预习.pdf) 的引脚说明，上板时建议：

- 将 `DZ8` 短接到 `1Hz`，让 `CP3` 提供每秒一次计时脉冲
- 将 `CP2` 选择为 `100Hz` 或 `1KHz`，用于同步 `QD/PULSE/K0/K1`

这样既符合 PPT 的接法，也能避免按键/脉冲直接进异步控制后导致显示乱跳。

## 显示分配

- `LG1`：秒个位，采用共阴极 7 段直译码
- `LG2`：秒十位，BCD
- `LG3`：分个位，BCD
- `LG4`：分十位，BCD
- `LG5`：时个位，BCD
- `LG6`：时十位，BCD

## 工程文件

- 顶层 RTL：[src/clock.v](/D:/clock/src/clock.v)
- 测试台：[sim/tb_clock.v](/D:/clock/sim/tb_clock.v)
- 设计说明：[docs/superpowers/specs/2026-04-22-tec8-clock-design.md](/D:/clock/docs/superpowers/specs/2026-04-22-tec8-clock-design.md)

## 验证命令

```powershell
iverilog -g2001 -o sim/tb_clock.vvp src/clock.v sim/tb_clock.v
vvp sim/tb_clock.vvp
quartus_sh --flow compile clock
```

## 编译结果

- `Quartus` 输出编程文件：`clock.pof`
- 资源占用：`52 / 128 macrocells`
