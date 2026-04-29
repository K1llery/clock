# TEC-8 EPM7128 Electronic Clock Design

## Goal

Implement a resource-conscious electronic clock with a single alarm feature for the TEC-8 platform on the `EPM7128SLC84-15` CPLD. The display format is `HH:MM:SS`, with `LG1` driven by direct 7-segment decode and the other five digits driven as BCD outputs.

## Platform Constraints

- `LG1` must be driven directly through `LG1-D0..D6`.
- `LG2..LG6` expose 4-bit BCD outputs (`A` = LSB, `D` = MSB).
- The seven-segment display is common cathode, so direct segment outputs are active high.
- Required control signals are `CLR#`, `QD`, and `PULSE`.
- From `实验五+六-预习.pdf`, `MF=1MHz`, `CP2=1KHz/100Hz`, and `CP3=10Hz/1Hz`.
- Approved interaction:
  - `QD` toggles run/pause.
  - While paused, `PULSE` increments the selected field.
  - `K0` selects hour adjustment and `K1` selects minute adjustment.
- Alarm extension:
  - `K2=1` selects alarm view/set mode
  - `K3=1` enables the alarm
  - the platform speaker is reused on pin 52

## Architecture

- Store time directly as six BCD digits to avoid binary-to-BCD conversion logic.
- Store alarm time directly as four BCD digits (`HHMM`) to avoid conversion logic.
- Use `CP2` as the single synchronous clock domain for the design.
- Synchronize `CP3`, `QD`, `PULSE`, and `K0..K3` into the `CP2` domain.
- Treat `CP3` only as a synchronized second-tick source.
- Recommended bench setup:
  - `CP3` set to `1Hz`
  - `CP2` set to `1KHz` when possible for a better alarm tone
- Keep the control path minimal:
  - asynchronous clear on `CLR#`
  - `QD` toggles a single `run_enable` bit
  - `PULSE` updates hours or minutes only when paused
- Reset seconds to `00` whenever hours or minutes are manually adjusted.
- Display behavior:
  - `K2=0`: show current time
  - `K2=1`: show alarm time as `HH:MM:00`
  - `LG1` shows hour tens, `LG6` hour ones, `LG5` minute tens, `LG4` minute ones, `LG3` second tens, and `LG2` second ones
- Alarm behavior:
  - trigger when current time reaches `alarm_hour:alarm_minute:00`
  - keep sounding until `QD` is pressed or `K3` is cleared
  - use a small synchronous tone flip-flop to drive the speaker with minimal logic

## Root Cause Notes

- The first version used `posedge cp3` and `posedge pulse` in the same sequential block.
- On `MAX7000S`, Quartus mapped `pulse` onto asynchronous control paths for the time registers.
- That structure is legal enough to compile but unsafe on hardware, and it explains the observed unstable low digits.

## Verification

- Simulate with Icarus Verilog:
  - reset behavior
  - normal counting
  - pause behavior
  - manual minute/hour adjustment
  - alarm view and alarm setting
  - alarm trigger at `HH:MM:00`
  - `QD` alarm dismiss behavior
  - `K3` alarm enable gating
  - `23:59:59 -> 00:00:00` rollover
- Compile with Quartus II 9.0 SP2 for `EPM7128SLC84-15`.
