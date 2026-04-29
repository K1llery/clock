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

## What to tell the user at the end

Always report:

- what changed
- what files matter
- which verification commands ran
- whether `iverilog` passed
- whether `Quartus` passed
- the commit hash if a commit was created
