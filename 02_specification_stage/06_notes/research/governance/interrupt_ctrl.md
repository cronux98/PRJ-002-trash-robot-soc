# Interrupt Controller — Research Note

**Date:** 2026-07-15
**Category:** governance
**Sources:** 2

## Priority Source: RISC-V Platform-Level Interrupt Controller (PLIC) Specification

- **Source:** https://github.com/riscv/riscv-plic-spec

### Key Specifications
- **Channels:** 16 interrupt inputs (simplified from full PLIC)
- **Priority:** Fixed priority (ch 0 highest → ch 15 lowest)
- **Masking:** Per-channel enable register
- **Pending:** Latched until acknowledged
- **Vector:** Readable register identifying highest-priority pending interrupt

### For IP-005 v6
- **Interface:** Wishbone B4 slave
- **Address:** 0xC000
- **Registers:** EN (16-bit, per-channel enable), STATUS (16-bit, per-channel pending), PENDING (16-bit, latched), VECTOR (4-bit, highest pending index)
- **Output:** irq_out → PicoRV32 IRQ input
- **Input:** irq_in[15:0] from peripherals

### Operation
```
1. Peripheral asserts irq_in[N] = 1
2. interrupt_ctrl latches STATUS[N] = 1 (PENDING[N] = 1)
3. If EN[N] = 1 and no higher-priority pending → irq_out = 1
4. CPU reads VECTOR register → identifies source N
5. CPU writes to STATUS[N] = 0 (acknowledge) → irq_out de-asserted
```

### Interrupt Channel Map
| Ch | Source | Priority |
|----|--------|----------|
| 0 | timer | HIGH |
| 1 | uart (RX ready) | HIGH |
| 2 | uart (TX done) | MED |
| 3 | gpio[0] (bump front) | HIGH |
| 4 | gpio[1] (bump rear) | HIGH |
| 5 | gpio[2] (button) | MED |
| 6 | motor_pwm (fault) | MED |
| 7 | ultrasonic_capture (done) | MED |
| 8 | weight_detect (threshold) | MED |
| 9 | i2c_hx711 (done) | LOW |
| 10 | i2c_ina219 (done) | LOW |
| 11 | i2c_ds3231 (done) | LOW |
| 12 | watchdog (warning) | HIGH |
| 13 | power_mgr (status) | LOW |
| 14-15 | Reserved | LOW |

### Edge Cases & Pitfalls
- **Simultaneous interrupts:** Fixed priority resolves — highest wins. Lower-priority interrupt stays PENDING.
- **Spurious interrupt:** irq_out asserted but VECTOR returns 0xF (no interrupt) → firmware must handle gracefully.
- **Acknowledge timing:** Writing STATUS before reading VECTOR → race condition. Read VECTOR first, then acknowledge.
- **Level vs edge:** Peripherals assert level (high). Acknowledge must clear the peripheral's interrupt condition, not just the controller's latch.

## Secondary Source: IP-005 v5 Interrupt Controller Module

- **V5 Cell Count:** 280 (RTL), ~400 (placed)
- **GDS Proven:** Yes

## Summary
16-channel fixed-priority interrupt controller. VECTOR read, per-channel mask, latched pending. v4/v5 proven.
