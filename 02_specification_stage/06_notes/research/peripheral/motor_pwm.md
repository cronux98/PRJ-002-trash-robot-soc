# Motor PWM Controller — Research Note

**Date:** 2026-07-15
**Category:** peripheral
**Sources:** 2

## Priority Source: DRV8833 Dual H-Bridge Motor Driver (Texas Instruments)

- **Source:** https://www.ti.com/product/DRV8833
- **Datasheet:** DRV8833 SLVSAR4F

### Key Specifications
- **Channels:** 2 H-bridges (4 half-bridges)
- **Mode:** PHASE/ENABLE or IN/IN
- **IP-005 mode:** PHASE/ENABLE — PHASE sets direction, ENABLE is PWM'd for speed
- **Frequency:** 100 Hz — 100 kHz (IP-005 uses ~25 kHz, above audible range)
- **Fault detection:** Over-current, over-temp, under-voltage → nFAULT pin

### For IP-005 v6
- **Interface:** Wishbone B4 slave
- **Address:** 0x7000
- **Signals to DRV8833:** pwm_a_o[3:0], pwm_b_o[3:0], fault_i[3:0]
- **PWM generation:** 33.3 MHz / prescaler → 25 kHz PWM base frequency
- **Duty cycle:** 8-bit or 16-bit resolution
- **Registers:** DUTY_A[3:0], DUTY_B[3:0], CTRL (enable/prescaler), FAULT (fault flags), STATUS

### PWM Generation
- **PHASE=1, ENABLE=PWM:** Motor forward at duty%
- **PHASE=0, ENABLE=PWM:** Motor reverse at duty%
- **ENABLE=0:** Motor coast (high-impedance)
- **Fault response:** Stop all PWM, latch fault bits, interrupt CPU (ch 6, MED priority)

### Edge Cases & Pitfalls
- **Dead-time:** Switching between forward/reverse requires dead-time (~1 µs) to prevent shoot-through
- **Fault recovery:** Auto-retry or manual clear depending on CTRL.AUTO_RECOVER
- **PWM resolution vs frequency tradeoff:** 33.3 MHz / 25 kHz = 1333 ticks → ~10-bit resolution
- **Simultaneous channel update:** Latch duty registers so all channels update on same PWM cycle boundary

## Secondary Source: IP-005 v5 Motor PWM Module

- **V5 Cell Count:** 470 (RTL), ~700 (placed)
- **GDS Proven:** Yes

## Summary
4-channel PHASE/ENABLE PWM for DRV8833 motor driver. ~25 kHz carrier, 10-bit resolution, fault interrupt. v4/v5 proven.
