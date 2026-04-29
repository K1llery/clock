# TEC-8 电子钟

本工程面向 `TEC-8 + EPM7128SLC84-15`，显示格式为 `HH:MM:SS`。

本版按照 PPT 平台约束修正为稳定同步结构：`CP2` 只用于内部同步与按键采样，`CP3` 作为外部秒脉冲输入，避免 `PULSE/QD` 被综合成异步控制后在板上乱跳。扬声器蜂鸣单独由 `CP1` 分频产生，不再输出直流常量。

## 控制方式

- `CLR#`：低电平异步复位到 `00:00:00`
- `QD`：正常状态下运行/暂停切换；闹钟响起后按下可消音
- `PULSE`：暂停状态下单步设置
- `K0=1`：`PULSE` 加 1 小时
- `K1=1`：`PULSE` 加 1 分钟
- `K2=1`：查看/设置闹钟时间
- `K3=1`：闹钟使能，`K3=0`：闹钟关闭

普通校时时会把秒清零，便于重新对时。闹钟设置显示为 `HH:MM:00`，只保存时和分。
`K2=1` 时只响应 `K0/K1/PULSE` 的闹钟设置操作，`QD` 不会切换运行/暂停或消音，避免设置闹钟时误退出暂停走时。

## 时钟说明

- `CP1`：扬声器蜂鸣基准，接 PPT 中的 `100KHz/10KHz` 引脚；推荐选择 `100KHz`
- `CP2`：同步采样时钟，接 PPT 中的 `1KHz/100Hz` 引脚
- `CP3`：运行计时基准，接 PPT 中的 `10Hz/1Hz` 引脚

结合 [实验五+六-预习.pdf](/D:/clock/实验五+六-预习.pdf) 的引脚说明，上板时建议：

- 将 `DZ8` 短接到 `1Hz`，让 `CP3` 提供每秒一次计时脉冲
- 将 `CP2` 选择为 `1KHz`，用于同步 `QD/PULSE/K0/K1/K2/K3`
- 将 `CP1` 选择为 `100KHz`，分频后给扬声器提供约 `390Hz` 的方波蜂鸣；如果选 `10KHz`，声音会变成约 `39Hz` 的低频断续感

这样既符合 PPT 的接法，也能避免按键/脉冲直接进异步控制后导致显示乱跳。

## 闹钟功能

- 只有一组闹钟，保存 `时:分`
- `K2=1` 且暂停时，可用 `K0/K1 + PULSE` 设置闹钟时分
- 到达闹钟时间 `HH:MM:00` 时，扬声器输出由 `CP1` 分频得到的方波蜂鸣
- 响铃期间电子钟继续正常走时
- 响铃时按 `QD` 消音
- `K3` 拉低会关闭闹钟并立即停止响铃，但不会影响电子钟本身运行
- `K2` 处于闹钟查看/设置时，`QD` 被屏蔽；需要先退出 `K2` 再用 `QD` 控制走停或消音
- 扬声器复用 `PIN_52`，也就是平台资料中的 `LG1-D7//Speaker`

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
- 资源占用：`119 / 128 macrocells`
