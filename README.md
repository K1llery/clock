# TEC-8 电子钟

本工程面向 `TEC-8 + EPM7128SLC84-15`，显示格式为 `HH:MM:SS`。

## 控制方式

- `CLR#`：低电平异步复位到 `00:00:00`
- `QD`：运行/暂停切换
- `PULSE`：暂停状态下单步校时
- `K0=1`：`PULSE` 加 1 小时
- `K1=1`：`PULSE` 加 1 分钟

校时时会把秒清零，便于重新对时。

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
- 资源占用：`61 / 128 macrocells`
