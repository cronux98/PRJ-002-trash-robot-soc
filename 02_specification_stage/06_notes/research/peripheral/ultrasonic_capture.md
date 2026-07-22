# Ultrasonic Capture — Research Note

**Date:** 2026-07-15
**Category:** peripheral
**Sources:** 2

## Priority Source: HC-SR04 Ultrasonic Sensor Datasheet

- **Source:** https://cdn.sparkfun.com/datasheets/Sensors/Proximity/HCSR04.pdf

### Key Specifications
- **Principle:** Send 10µs trigger pulse → measure echo pulse width → distance = echo_time × 0.034/2 cm/µs
- **Range:** 2 cm – 400 cm
- **Accuracy:** ±3 mm
- **Trigger:** 10 µs TTL pulse (active high)
- **Echo:** TTL pulse width proportional to distance (150 µs – 25 ms)
- **Channels:** 2 independent (front + rear ultrasonic modules)

### For IP-005 v6
- **Interface:** Wishbone B4 slave
- **Address:** 0x8000
- **Signals:** trig_o[1:0] (trigger outputs), echo_i[1:0] (echo inputs)
- **Registers:** CTRL (trigger/enable), ECHO_TIME[1:0] (20-bit captured value), STATUS (done/timeout), INT_EN
- **Timer:** 20-bit up-counter at 1 MHz (1 µs resolution) → max 1.048 seconds measurement
- **Resolution:** 1 µs = ~0.017 cm at speed of sound

### Measurement Sequence
```
1. Firmware writes TRIG=1 → 10 µs pulse generated on trig_o
2. echo_i rises → internal 20-bit counter starts at 1 MHz
3. echo_i falls → counter stops, value latched to ECHO_TIME
4. STATUS.DONE = 1, irq_o asserted (ch 7, MED priority)
```

### Edge Cases & Pitfalls
- **No echo return:** echo_i never goes high → timeout after ~38 ms (max range 400 cm + margin). STATUS.TIMEOUT flag.
- **Early echo:** echo_i already high when trigger fires → previous measurement still in flight. STATUS.BUSY.
- **Counter overflow:** 20-bit at 1 MHz = 1.048s max, far exceeds worst-case echo (25 ms).
- **Metastability on echo_i:** Double-flop synchronize.
- **Concurrent triggers:** Both channels may trigger simultaneously — independent counters required.

## Secondary Source: IP-005 v5 Ultrasonic Capture Module

- **V5 Cell Count:** 1,314 (RTL), ~1,800 (placed)
- **GDS Proven:** Yes

## Summary
Dual HC-SR04 ultrasonic sensor interface. 20-bit 1 MHz echo capture, trigger generation, timeout detection. v4/v5 proven.
