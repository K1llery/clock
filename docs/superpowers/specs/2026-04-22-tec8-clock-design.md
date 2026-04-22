# TEC-8 EPM7128 Electronic Clock Design

## Goal

Implement a resource-conscious electronic clock for the TEC-8 platform on the `EPM7128SLC84-15` CPLD. The display format is `HH:MM:SS`, with the lowest digit driven by direct 7-segment decode and the other five digits driven as BCD outputs.

## Platform Constraints

- `LG1` is the lowest digit and must be driven directly through `LG1-D0..D6`.
- `LG2..LG6` expose 4-bit BCD outputs (`A` = LSB, `D` = MSB).
- The seven-segment display is common cathode, so direct segment outputs are active high.
- Required control signals are `CLR#`, `QD`, and `PULSE`.
- Approved interaction:
  - `QD` toggles run/pause.
  - While paused, `PULSE` increments the selected field.
  - `K0` selects hour adjustment and `K1` selects minute adjustment.

## Architecture

- Store time directly as six BCD digits to avoid binary-to-BCD conversion logic.
- Use `CP3` as the running tick input from the TEC-8 platform.
- Keep the control path minimal:
  - asynchronous clear on `CLR#`
  - `QD` toggles a single `run_enable` bit
  - `PULSE` updates hours or minutes only when paused
- Reset seconds to `00` whenever hours or minutes are manually adjusted.

## Verification

- Simulate with Icarus Verilog:
  - reset behavior
  - normal counting
  - pause behavior
  - manual minute/hour adjustment
  - `23:59:59 -> 00:00:00` rollover
- Compile with Quartus II 9.0 SP2 for `EPM7128SLC84-15`.
