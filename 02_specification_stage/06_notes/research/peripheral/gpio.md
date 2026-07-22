# GPIO Peripheral — Research Note

**Date:** 2026-07-15
**Category:** peripheral
**Sources:** 2

## Priority Source: OpenTitan GPIO (lowRISC)

- **Source:** https://github.com/lowRISC/opentitan
- **License:** Apache 2.0

### Key Specifications
- **Width:** 16-bit configurable I/O
- **Direction:** Per-pin input/output (DIR register)
- **Output:** OUT register (set/clear)
- **Input:** IN register (read pin state)
- **Interrupts:** Rising/falling/both edge, level-high/level-low, per-pin mask

### For IP-005 v6
- **Interface:** Wishbone B4 slave
- **Address:** 0x5000
- **Registers:** DIR, OUT, IN, INT_EN, INT_TYPE, INT_STATUS
- **Pin assignments:**
  - GPIO[0]: Bump sensor front (input, interrupt)
  - GPIO[1]: Bump sensor rear (input, interrupt)
  - GPIO[2]: User button (input, interrupt)
  - GPIO[3]: Reserved (input/output)
  - GPIO[4:15]: General purpose or reserved

### Edge Cases & Pitfalls
- **Metastability:** Double-flop synchronize all inputs
- **Interrupt aggregation:** Each pin's interrupt OR'd into single irq_o
- **Output glitching:** DIR change while OUT=1 on external bus → transient. Change DIR before OUT.
- **Open-drain emulation:** DIR=0, OUT=0 → pull low; DIR=0, OUT=1 → float (external pull-up)

## Secondary Source: IP-005 v5 GPIO Module

- **V5 Cell Count:** 554 (RTL), ~800 (placed)
- **GDS Proven:** Yes

## Summary
16-bit GPIO for bump sensors, button, and status outputs. Interrupt per pin. Wishbone B4 slave. v4/v5 proven.
