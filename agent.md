# Agent Guide For `D:\clock`

This repository contains the TEC-8 / `EPM7128SLC84-15` Verilog electronic clock project. When continuing work here in a future conversation, read and follow:

- [skills/clock-project-workflow/SKILL.md](/D:/clock/skills/clock-project-workflow/SKILL.md)

## Current baseline

- Branch: `main`
- Core functions: `HH:MM:SS` clock, pause/set, full `HH:MM:SS` alarm, alarm dismiss, `K4` hourly chime switch, set-field blinking
- Verified commands on the current baseline:

```powershell
iverilog -g2001 -o sim/tb_clock.vvp src/clock.v sim/tb_clock.v
vvp sim/tb_clock.vvp
quartus_sh --flow compile clock
```

- Latest fit result: `120 / 128 macrocells`, `42 / 68 pins`
- Practical rule: this project has only 8 spare macrocells. Treat capacity as the first design constraint, and prefer changes that keep the fit at or below `124 / 128 macrocells`.

## Working defaults

- Treat this repo as an engineering workflow, not just a code dump
- Inspect the current state before editing:
  - `git status --short --branch`
  - `README.md`
  - `src/clock.v`
  - `sim/tb_clock.v`
  - `clock.qsf`
- Prefer short concrete plans before implementation
- If the request adds behavior, first name what will be removed, shared, or simplified to pay for it in macrocells
- For RTL optimization requests, apply pages 29-33 of
  `2026数字课程设计 - verilog讲座-修订版.pdf` as the local Verilog checklist:
  - keep names meaningful and add comments only around state/control or non-obvious timing paths
  - keep RTL synthesizable; `initial`, delays, simulation-only constructs, division/modulo, and loops belong in testbenches, not `src/clock.v`
  - keep register updates in the `CP2` synchronous domain unless a hardware reason requires otherwise; the alarm speaker tone reuses the `CP2` domain and the one-second beep cadence follows synchronized `CP3`
  - separate combinational next-value logic from sequential register updates; use blocking assignments in `always @(*)` / functions and non-blocking assignments in clocked blocks
  - use complete `case` / default assignments to avoid inferred latches and reduce priority-logic surprises
  - when timing reports point at a complex control path, prefer a small registered/pipelined check over deep same-cycle combinational matching
- After RTL changes, run:

```powershell
iverilog -g2001 -o sim/tb_clock.vvp src/clock.v sim/tb_clock.v
vvp sim/tb_clock.vvp
quartus_sh --flow compile clock
```

- Use `git` as part of the workflow; create meaningful commits after successful verification unless the user says not to

## Project-specific reminders

- `CP2` is the main synchronous clock domain and the alarm speaker tone source; prefer `1KHz`, which produces about a `500Hz` audible tone
- `CP1` is not used by the RTL
- `CP3` is the external timing tick source and drives the alarm's roughly one-second beep interval when set to `1Hz`
- `K4` controls hourly chime. It is part of the current user interface; keep it documented with any control changes.
- Board issues are often caused by control gating or mode interaction, not just pin mismatches
- If the alarm does not sound on hardware, check `K3=1`, an active `CP2` clock, the `PIN_52` speaker path, and whether the latest `clock.pof` was downloaded before changing RTL
- Keep `README.md` updated when controls or operating procedures change

## Resource policy for future work

- Do not reintroduce unfinished bidirectional setting / `K5` decrement logic by simply adding a second set of decrement functions. That style exceeded the device budget.
- Before adding a feature, run or inspect Quartus and record the current macrocell count. After the feature, the fit must pass on `EPM7128SLC84-15`.
- Good candidates under the current constraints:
  - resource optimization of BCD increment paths and duplicated alarm/time setting paths
  - synchronizing `K4` if hardware behavior requires it
  - documentation, testbench, and board-checklist improvements
- Risky candidates unless paired with optimization or feature removal:
  - countdown mode
  - multiple alarms
  - long-press auto repeat
  - bidirectional time setting
  - richer speaker patterns
- If a change fits only at `127 / 128` or `128 / 128`, call out the risk and prefer a smaller design. The board and Quartus fitter have little room for late fixes.

## TEC-8 physical hardware constraints

These constraints come from page 22 of `实验五+六-预习.pdf` and should be treated as the board reference for this project:

- CPLD device: `EPM7128SLC84-15`
- Main clock: `MF` on pin `55`, nominal `1MHz`
- Auxiliary clocks:
  - `CP1` on pin `56`: selectable `100KHz / 10KHz`, unused by this RTL
  - `CP2` on pin `57`: selectable `1KHz / 100Hz`, used for synchronization and alarm tone generation
  - `CP3` on pin `58`: selectable `10Hz / 1Hz`, use `1Hz` for one-second alarm beep spacing
- Board control pulses / reset:
  - `K5` on pin `76`: switch input used by this RTL as the reset source; each sampled level change resets the clock to `00:00:00`
  - `CLR#` on pin `1`: board reset signal, not consumed by this RTL
  - `QD` on pin `60`: single-pulse control input
  - `Pulse` / `PULSE` on pin `61`: interrupt/manual pulse input
- Switches: the board has 16 switch inputs `K15..K0`
  - `K0..K3`: pins `54, 81, 80, 79`
  - `K4..K7`: pins `77, 76, 75, 74`
  - `K8..K11`: pins `73, 70, 69, 68`
  - `K12..K15`: pins `67, 65, 64, 63`
- Display hardware: six numeric display positions are available as `LG1..LG6`.
- Shared-output caveat: `Speaker` is on pin `52`, the same physical pin as `LG1-D7`; using the speaker affects that decimal-point/segment output.
- LED caveat: `L0..L3` share pins with `LG2-A..D`, and `L4..L7` share pins with `LG1-D0..D3`; do not assume separate LED outputs unless the design intentionally reuses those display pins.

## TEC-8 display and pin reference

Do not re-read the PDFs for these basics unless the user explicitly asks. The project display order is intentionally:

- Human-readable order from left to right: `LG6 LG5 : LG4 LG3 : LG2 LG1`
- Meaning: `hour_tens hour_ones : minute_tens minute_ones : second_tens second_ones`
- Keep this order stable. Do not remap the clock to the standalone lab example where seconds use `LG3/LG2`.

Pin assignments from the TEC-8 materials and `clock.qsf`:

- `LG1-D0..D7`: pins `44, 45, 46, 48, 49, 50, 51, 52`
- `LG1-D7` / pin `52` is also `Speaker`; this project uses it for alarm speaker output
- `LG2-A..D`: pins `37, 39, 40, 41`
- `LG3-A..D`: pins `35, 36, 17, 18`
- `LG4-A..D`: pins `30, 31, 33, 34`
- `LG5-A..D`: pins `25, 27, 28, 29`
- `LG6-A..D`: pins `20, 21, 22, 24`

## What to tell the user at the end

Always report:

- what changed
- what files matter
- which verification commands ran
- whether `iverilog` passed
- whether `Quartus` passed
- the commit hash if a commit was created
