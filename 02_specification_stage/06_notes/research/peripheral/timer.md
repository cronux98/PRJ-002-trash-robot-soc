# Timer Peripheral — Research Note

**Date:** 2026-07-15
**Category:** peripheral
**Sources:** 2

## Priority Source: RISC-V mtime/mtimecmp Specification

- **Source:** RISC-V Privileged Architecture v1.12
- **Relevance:** Standard timer model

### Key Specifications
- **Width:** 32-bit free-running counter
- **Clock:** System clock (33.3 MHz) → 1 tick per ~30 ns → full cycle ~129 seconds
- **Compare:** CMP register, interrupt on match
- **Auxiliary PWM:** 4-channel PWM output (derived from timer count)

### For IP-005 v6
- **Interface:** Wishbone B4 slave
- **Address:** 0x6000
- **Registers:** CNT (RO), CMP (RW), CTRL (enable/prescaler), PWM_DUTY[3:0], PWM_CTRL
- **Interrupt:** irq_o on CNT >= CMP (channel 0, HIGH priority)
- **PWM channels:** 4 auxiliary PWM outputs for non-critical PWM tasks

### Edge Cases & Pitfalls
- **Counter overflow:** 32-bit wraps naturally, compare wrap-aware
- **Prescaler:** Optional clock divider for slower tick rates
- **PWM glitch:** Duty cycle change mid-cycle → latch and apply at next period boundary
- **CNT write:** Read-only. Reset sets to 0. Cannot pre-load.

## Secondary Source: IP-005 v5 Timer Module

- **V5 Cell Count:** 1,373 (RTL), ~1,800 (placed)
- **GDS Proven:** Yes

## Summary
32-bit system timer with interrupt (channel 0) and 4 auxiliary PWM channels. V4/v5 proven.
