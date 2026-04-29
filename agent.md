# Agent Guide For `D:\clock`

This repository contains the TEC-8 / `EPM7128SLC84-15` Verilog electronic clock project. When continuing work here in a future conversation, read and follow:

- [skills/clock-project-workflow/SKILL.md](/D:/clock/skills/clock-project-workflow/SKILL.md)

## Working defaults

- Treat this repo as an engineering workflow, not just a code dump
- Inspect the current state before editing:
  - `git status --short --branch`
  - `README.md`
  - `src/clock.v`
  - `sim/tb_clock.v`
  - `clock.qsf`
- Prefer short concrete plans before implementation
- After RTL changes, run:

```powershell
iverilog -g2001 -o sim/tb_clock.vvp src/clock.v sim/tb_clock.v
vvp sim/tb_clock.vvp
quartus_sh --flow compile clock
```

- Use `git` as part of the workflow; create meaningful commits after successful verification unless the user says not to

## Project-specific reminders

- `CP2` is the main synchronous clock domain
- `CP3` is the external timing tick source
- Board issues are often caused by control gating or mode interaction, not just pin mismatches
- Keep `README.md` updated when controls or operating procedures change

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
