# Power Manager — Research Note

**Date:** 2026-07-15
**Category:** governance
**Sources:** 2

## Priority Source: ARM Power Management Controller (PMC)

- **Source:** ARM IHI 0048 — Power Policy Unit Architecture

### Key Specifications
- **Clock gating:** Per-module clock enable signals (reduce dynamic power)
- **Sleep states:** ACTIVE → SLEEP → WAKE finite state machine
- **Wake sources:** External (RTC, button, interrupt) + internal (core sleep request)
- **Graceful wake:** Clocks restored before CPU sees wake event

### For IP-005 v6
- **Interface:** Wishbone B4 slave
- **Address:** 0xE000
- **Registers:** CTRL (sleep/wake/sleep_req), CLK_EN (bit-per-module), SLEEP_SRC (wake source), STATUS (current state)
- **Outputs:** clk_gate_o (per-module clock enable), pwr_irq_o (ch 13, LOW priority)
- **Inputs:** wake_rtc_i, wake_button_i, core_sleep_i

### State Machine
```
                   core_sleep_i=1
        ACTIVE ──────────────────► SLEEP
          ▲                          │
          │     wake_rtc_i=1 or      │
          │     wake_button_i=1      │
          │                          ▼
          └───────────────────── WAKE
                (restore clocks)
```

### Clock Gating Granularity
Each of 14 peripheral modules can be independently clock-gated. CPU and SRAM are always-on (sleep mode gates them too).

### Edge Cases & Pitfalls
- **Clock glitch:** Gating during active bus transaction → corrupted data. Wait for wb_cyc=0 before gating.
- **Wake latency:** Clock tree restart time (~2-3 cycles) must be accounted for.
- **Always-on domain:** power_mgr itself must be on an ungated clock.
- **Multiple wake sources:** If both RTC and button fire simultaneously, SLEEP_SRC reflects first detected.
- **Core sleep timing:** After core asserts sleep request, wait for all bus transactions to complete before gating clocks.

## Secondary Source: IP-005 v5 Power Manager Module

- **V5 Cell Count:** 193 (RTL), ~300 (placed)
- **GDS Proven:** Yes

## Summary
Clock gating power manager with ACTIVE/SLEEP/WAKE FSM. Per-module clock control. RTC and button wake sources. v5 proven.
