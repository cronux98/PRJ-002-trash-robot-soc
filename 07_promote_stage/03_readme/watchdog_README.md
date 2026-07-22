# watchdog — Watchdog Timer (Wishbone B4). Countdown timer with configurable timeout period. Requires 0xDEADBEEF magic key write to reload register (address 0x08) to prevent system reset. Asserts wdt_rst_n on timeout.

## Overview

Watchdog Timer (Wishbone B4). Countdown timer with configurable timeout period. Requires 0xDEADBEEF magic key write to reload register (address 0x08) to prevent system reset. Asserts wdt_rst_n on timeout.

## Pipeline Results

| Stage | Result |
|-------|--------|
| Lint (iverilog) | PASS (0 errors) |
| Lint (verilator) | PASS (0 errors) |
| Formal BMC | PASS (watchdog.sby) |
| Synthesis | PASS — 608 cells, 108 DFFs, 0 latches |
| Equivalence | CONDITIONAL PASS (sky130 SAT limitation) |
| RTL Simulation | 4/4 PASS |
| GLS Simulation | 4/4 PASS |
| Line Coverage | 100% |
| Toggle Coverage | 50.7% (428 bins) |

## Interface

| Port | Description |
|------|-------------|
| `wb_clk_i` | |
| `wb_rst_i` | |
| `wb_adr_i[3:0]` | |
| `wb_dat_i[31:0]` | |
| `wb_dat_o[31:0]` | |
| `wb_we_i` | |
| `wb_sel_i[3:0]` | |
| `wb_stb_i` | |
| `wb_ack_o` | |
| `wdt_rst_n` | |

- **Bus Protocol:** Wishbone B4
- **Clock Domain:** sys_clk
- **Dependencies:** None

## Integration Notes

- Source: IP-005 v6 Trash Robot SoC (2026-07-15)
- Provenance: self (verified through full ASIC pipeline)
- PDK: sky130A (sky130_fd_sc_hd)
- Tier: A (428 toggle bins)

## Promotion Verdict: PROMOTED

