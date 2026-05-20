# TEC-8 EPM7128 Electronic Clock Design

## Goal

Implement a resource-conscious electronic clock with a single alarm feature for the TEC-8 platform on the `EPM7128SLC84-15` CPLD. The display format is `HH:MM:SS`, with the lowest digit driven by direct 7-segment decode and the other five digits driven as BCD outputs.

## Platform Constraints

- `LG1` is the lowest digit and must be driven directly through `LG1-D0..D6`.
- `LG2..LG6` expose 4-bit BCD outputs (`A` = LSB, `D` = MSB).
- The seven-segment display is common cathode, so direct segment outputs are active high.
- Required control signals are `CLR#`, `QD`, and `PULSE`.
- From `实验五+六-预习.pdf`, `MF=1MHz`, `CP1=100KHz/10KHz`, `CP2=1KHz/100Hz`, and `CP3=10Hz/1Hz`.
- Approved interaction:
  - `QD` toggles run/pause.
  - While paused, `PULSE` increments the selected field.
  - `K0` selects hour adjustment, `K1` selects minute adjustment, and no `K0/K1` selected means second adjustment.
- Alarm extension:
  - `K2=1` selects alarm view/set mode
  - `K3=1` enables the alarm
  - the platform speaker is reused on pin 52
- Hourly chime extension:
  - `K4=1` enables the hourly chime
  - `K4=0` disables the hourly chime

## Architecture

- Store time directly as six BCD digits to avoid binary-to-BCD conversion logic.
- Store alarm time directly as six BCD digits (`HHMMSS`) so the alarm can trigger at an exact second without binary-to-BCD conversion.
- Use `CP2` as the single synchronous clock domain for the design.
- Synchronize `CP3`, `QD`, `PULSE`, and `K0..K3` into the `CP2` domain.
- Treat `CP3` as a synchronized second-tick source and the alarm beep cadence source.
- Reuse `CP2` for the alarm speaker tone so the RTL no longer consumes the `CP1` input.
- Recommended bench setup:
  - `CP2` set to `1KHz` for responsive control sampling and an audible tone near `500Hz`
  - `CP3` set to `1Hz` so alarm beeps are spaced by about one second
  - `CP1` left unused
- Keep the control path minimal:
  - asynchronous clear on `CLR#`
  - `QD` toggles a single `run_enable` bit
  - `PULSE` updates hours, minutes, or seconds only when paused and no alarm is actively sounding
- Manual hour and minute adjustment preserves the current seconds field. Manual second adjustment is available when neither `K0` nor `K1` is selected.
- A single `blink_phase` bit, toggled by synchronized `CP3`, blanks the currently selected setting field while paused.
- Display behavior:
  - `K2=0`: show current time
  - `K2=1`: show alarm time as `HH:MM:SS`
- Alarm behavior:
  - trigger when current time reaches `alarm_hour:alarm_minute:alarm_second`
  - keep sounding until `QD` is pressed or `K3` is cleared
  - use a `CP2`-clocked tone flip-flop gated by a short beep window
  - restart that short beep window on each synchronized `CP3` second tick while the alarm remains active
- Hourly chime behavior:
  - when `K4=1`, trigger one short beep as running time crosses `HH:00:00`
  - do not trigger the chime from paused manual setting

## Hardware Budget

- Latest baseline fit: `120 / 128 macrocells` and `42 / 68 pins`.
- The design is capacity-limited rather than speed-limited; `CP2` timing margin is much larger than the recommended `1KHz` board clock.
- Future RTL features should first reduce or share existing logic. A target of `124 / 128 macrocells` or less leaves a small practical repair margin.
- Known risky additions on this device: bidirectional setting through `K5`, countdown mode, multiple alarms, long-press auto-repeat, and complex speaker patterns.
- Better near-term work: reduce duplicated BCD increment logic, make setting/update paths share more hardware, shorten the beep counter if acceptable, and strengthen testbench/documentation coverage.

## Root Cause Notes

- The first version used `posedge cp3` and `posedge pulse` in the same sequential block.
- On `MAX7000S`, Quartus mapped `pulse` onto asynchronous control paths for the time registers.
- That structure is legal enough to compile but unsafe on hardware, and it explains the observed unstable low digits.
- A later unfinished bidirectional setting experiment exceeded the macrocell budget. Do not revive that approach without first simplifying the current BCD update logic.

## Verification

- Simulate with Icarus Verilog:
  - reset behavior
  - normal counting
  - pause behavior
  - manual second/minute/hour adjustment
  - alarm view and alarm setting
  - alarm trigger at exact `HH:MM:SS`
  - `QD` alarm dismiss behavior
  - `K3` alarm enable gating
  - `K4` hourly chime gating
  - selected-field blinking
  - `23:59:59 -> 00:00:00` rollover
- Compile with Quartus II 9.0 SP2 for `EPM7128SLC84-15`.
