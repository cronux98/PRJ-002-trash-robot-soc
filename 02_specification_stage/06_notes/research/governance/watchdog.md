# Watchdog Timer — Research Note

**Date:** 2026-07-15
**Category:** governance
**Sources:** 2

## Priority Source: ARM Generic Watchdog Timer

- **Source:** ARM IHI 0033C — ARM Architecture Reference Manual Watchdog

### Key Specifications
- **Dual-stage:** Warning timeout → interrupt; Reset timeout → hardware reset
- **Reload mechanism:** Magic-key sequence (prevent accidental disable)
- **Clock:** System clock (33.3 MHz)
- **Timeout range:** Configurable (µs to seconds range)

### For IP-005 v6
- **Interface:** Wishbone B4 slave
- **Address:** 0xD000
- **Registers:** TIMEOUT (RW, warning threshold), RESET_TIMEOUT (RW, reset threshold), CTRL (enable/clear), KEY (WO, magic value), STATUS (warning/reset flags)
- **Outputs:** wdt_irq_o (ch 12, HIGH priority), wdt_rst_o (feeds into reset tree)
- **Dual-stage sequence:**
```
1. Counter increments each clock cycle
2. Warning threshold reached → wdt_irq_o asserted (firmware can reload)
3. Firmware writes magic key to KEY register → counter reset
4. If firmware does NOT reload → counter reaches RESET_TIMEOUT → wdt_rst_o asserted
```

### Edge Cases & Pitfalls
- **Magic key:** Write specific sequence (e.g., 0xACCE5515) to KEY to reload. Wrong value → no reload, watchdog continues.
- **Reset pulse width:** wdt_rst_o must be asserted for ≥ 4 clock cycles to ensure clean reset.
- **Disable for debug:** CTRL.DISABLE bit for simulation/debug only. Must NOT be writable in production.
- **Counter overflow:** 32-bit counter at 33.3 MHz → max timeout ~129 seconds. Sufficient.
- **Sticky reset flag:** After wdt reset, STATUS.RESET flag persists across reset → firmware can detect watchdog-caused boot.

## Secondary Source: IP-005 v5 Watchdog Module

- **V5 Cell Count:** 444 (RTL), ~650 (placed)
- **GDS Proven:** Yes

## Summary
Dual-stage watchdog with magic-key reload. Warning interrupt feeds CPU, reset output feeds reset tree. v5 proven.
