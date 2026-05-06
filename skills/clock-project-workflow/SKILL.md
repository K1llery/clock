---
name: clock-project-workflow
description: Workflow for continuing the TEC-8 / EPM7128 Verilog clock project in `D:\clock`. Use this whenever the user wants to continue this repository, add or debug clock or alarm features, inspect Quartus or Icarus results, update Verilog RTL, adjust TEC-8 pin assignments, or keep progress organized with git. This skill should trigger for follow-up work on the existing digital design project even if the user only says things like “继续做”, “修这个问题”, “上板有问题”, “加功能”, “跑仿真”, or “帮我提交”.
---

# Clock Project Workflow

Use this skill when working on the `D:\clock` TEC-8 digital clock repository. The goal is not just to edit Verilog, but to keep the project moving with a repeatable engineering loop: understand the request, inspect current context, plan, implement, verify with `iverilog`, compile with `Quartus` when relevant, and record progress with `git`.

## Project focus

- Platform: `TEC-8`
- Device: `EPM7128SLC84-15`
- Main toolchain: `iverilog`, `vvp`, `quartus_sh --flow compile clock`
- Main sources:
  - `src/clock.v`
  - `sim/tb_clock.v`
  - `clock.qsf`
  - `README.md`
  - `docs/superpowers/specs/2026-04-22-tec8-clock-design.md`

## Use this workflow

### 1. Receive the request

Start by extracting the actual job to be done:

- Is the user asking for a new feature?
- Is it a hardware bug, simulation mismatch, or board-level issue?
- Does it affect RTL only, or also constraints, testbenches, and documentation?
- Is the user asking for explanation only, or for code changes plus verification?

If the user is continuing a prior task, assume they want end-to-end execution unless they explicitly ask for analysis only.

### 2. Inspect the current state first

Before editing anything:

- Check `git status --short --branch`
- Read the relevant source files before making assumptions
- Re-read `README.md` or the design spec if the task touches clocking, pin usage, or control behavior
- If the issue mentions board behavior, compare the hardware symptom with the current RTL structure before changing code

When the issue is bug-oriented, prefer proving the root cause over guessing.

## Planning

After you have enough context, write a short concrete plan. Keep it operational, not abstract. Good plan items for this repo often look like:

1. Inspect RTL and constraints related to the reported behavior
2. Patch `src/clock.v` and `sim/tb_clock.v`
3. Run `iverilog` and `vvp`
4. Run `quartus_sh --flow compile clock` if RTL or pins changed
5. Summarize results and commit with `git`

If the user asks for a simple explanation, the plan can be shorter, but still inspect the repo first.

## Implementation rules

- Prefer minimal, targeted changes that preserve working behavior
- Keep the stable single-clock synchronous structure unless the user explicitly wants an architectural rewrite
- For RTL optimization work, use pages 29-33 of `2026数字课程设计 - verilog讲座-修订版.pdf` as the Verilog checklist:
  - meaningful names and sparse comments for state/control or timing-sensitive paths
  - synthesizable RTL only in `src/clock.v`; keep delays, `initial`, division/modulo, and other simulation-only constructs in `sim/tb_clock.v`
  - CP2 remains the main register clock domain; CP1 is only for the alarm speaker divider and must receive CP2 control through synchronizers
  - split combinational next-value calculation from sequential register updates; use blocking assignments for combinational logic and non-blocking assignments for clocked registers
  - prefer complete `case` statements with defaults over long priority chains when it improves latch safety or timing clarity
  - if Quartus reports a long control path, consider a small registered/pipelined check before adding more same-cycle combinational matching
- If a bug is caused by control gating, asynchronous behavior, or mode interaction, fix the control flow first before adding new logic
- Update the testbench whenever behavior changes
- Update `README.md` when user-visible controls or procedures change

## Verification loop

For any non-trivial RTL change, run this loop:

1. Compile simulation:

```powershell
iverilog -g2001 -o sim/tb_clock.vvp src/clock.v sim/tb_clock.v
```

2. Run the simulation:

```powershell
vvp sim/tb_clock.vvp
```

3. If RTL, timing structure, or pin-related behavior changed, run Quartus:

```powershell
quartus_sh --flow compile clock
```

4. Read the results rather than assuming success means correctness:

- Did simulation actually cover the new behavior?
- Did Quartus still fit in `EPM7128`?
- Did warnings reveal control-path or clocking problems?

If a board issue was reported, add or strengthen a test that specifically reproduces the reported symptom so it does not regress.

## Git workflow

Use git as part of the engineering process, not as an afterthought.

- Inspect `git status` before starting
- Keep commits focused on one meaningful change
- Use clear commit messages like:
  - `Fix alarm enable freezing the clock`
  - `Keep time running while alarm sounds`
  - `Add TEC-8 alarm feature`
- If you changed files but did not commit, explain why

Unless the user explicitly says not to commit, prefer creating a commit after successful verification.

## Final user update

When the work is done, report these items clearly:

- What changed
- Which files matter most
- What verification you ran
- Whether `iverilog` passed
- Whether `Quartus` passed
- The commit hash if you created one
- Any remaining hardware assumptions or risks

Keep the close-out high signal. Mention concrete file paths and commands, not vague claims.

## Common repo pitfalls

- A control like `K3` must not accidentally gate the whole clock unless that is intentional
- Alarm behavior and timekeeping should be tested both independently and together
- Board symptoms often come from control-flow structure, not just wrong pin mapping
- A passing compile is not enough if the board symptom was timing or mode related

## Suggested output structure

Use a short outcome-first summary, then verification, then risks if any. A good format is:

```markdown
Implemented the fix in `src/clock.v` and updated `sim/tb_clock.v` to lock in the behavior.

Verification:
- `iverilog ...`
- `vvp ...`
- `quartus_sh --flow compile clock`

Committed as `<hash>` with message `<message>`.
```
