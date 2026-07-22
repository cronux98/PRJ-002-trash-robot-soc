# CDC Plan — IP-005 v6 Trash Robot SoC

**Date:** 2026-07-15
**Author:** architect-engineer (Hermes)
**Status:** PASS (No CDC Required)

---

## 1. Clock Domain Summary

| Domain | Frequency | Source | Modules |
|--------|----------|--------|---------|
| sys_clk | 33.3 MHz | External oscillator (Caravel) | All 16 modules |

**Total clock domains:** 1
**Total domain crossings:** 0

---

## 2. CDC Analysis

### 2.1 No Crossings

IP-005 v6 uses a **single clock domain** for all modules. The PicoRV32 core, SRAM, wb_interconnect, and all 14 peripheral slaves operate on sys_clk (33.3 MHz). There are no asynchronous clock domain crossings.

**Rationale:**
- PicoRV32 uses native Wishbone B4 — no bus bridge requiring clock conversion
- RTC function offloaded to external DS3231 (I²C, not a separate clock domain)
- I²C timing derived from sys_clk via prescaler (not a separate clock)
- UART baud generation uses counter from sys_clk (not a separate clock)
- Ultrasonic 1 MHz capture counter derived from sys_clk divider

### 2.2 Synchronous Domain Boundary

All Wishbone bus signals are synchronous to sys_clk. The wb_interconnect performs registered read-data mux (BUG-004 fix) — this is a synchronous register, not a CDC synchronizer.

### 2.3 Reset Synchronization

The reset tree uses a 2-stage synchronizer for deassertion:
```
rst_ni (external) → rst_sync[1:0] → internal_rst_n (all modules)
```
This is reset synchronization, not clock domain crossing. All modules share the same reset domain.

---

## 3. CDC Checklist

| # | Check | Status | Evidence |
|---|-------|--------|----------|
| 1 | All clock domains identified | PASS | 1 domain: sys_clk |
| 2 | All domain crossings enumerated | PASS | 0 crossings |
| 3 | Synchronizer type specified per crossing | N/A | No crossings |
| 4 | MTBF analysis for each crossing | N/A | No crossings |
| 5 | Reset domain crossings analyzed | PASS | Single reset domain |
| 6 | Multi-cycle paths documented | PASS | None (all single-cycle WB) |

---

## 4. Future Considerations

If future versions add a real-time clock domain (32.768 kHz) or a high-speed sensor domain:
- **Async FIFO** for data crossing between clock domains
- **2-FF synchronizer** for single-bit control signals
- **Pulse synchronizer** for single-cycle pulses
- **Gray-code counter** for multi-bit pointers crossing domains

None of these are required for v6.

---

## 5. Conclusion

**CDC Plan Verdict: PASS** — Single clock domain. No CDC analysis required.
