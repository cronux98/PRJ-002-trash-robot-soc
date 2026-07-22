# power_mgr — Power Management Unit (Wishbone B4). Controls reset sequencing (sys_rst_n_o, wdt_rst_n_o), clock gating per peripheral domain, and power state transitions. Requires ext_rst_n and wdt_rst_n inputs to be driven high for normal operation.

## Overview

Power Management Unit (Wishbone B4). Controls reset sequencing (sys_rst_n_o, wdt_rst_n_o), clock gating per peripheral domain, and power state transitions. Requires ext_rst_n and wdt_rst_n inputs to be driven high for normal operation.

## Pipeline Results

| Stage | Result |
|-------|--------|
| Lint (iverilog) | PASS (0 errors) |
| Lint (verilator) | PASS (0 errors) |
| Formal BMC | PASS (config.sby) |
| Synthesis | PASS — 22 cells, 8 DFFs, 0 latches |
| Equivalence | CONDITIONAL PASS (sky130 SAT limitation) |
| RTL Simulation | 4/4 PASS |
| GLS Simulation | 4/4 PASS |
| Line Coverage | Not collected |
| Toggle Coverage | Not collected (200 bins) |

## Interface

| Port | Description |
|------|-------------|
| `wb_clk_i` | |
| `wb_rst_i` | |
| `wb_adr_i[1:0]` | |
| `wb_dat_i[31:0]` | |
| `wb_dat_o[31:0]` | |
| `wb_we_i` | |
| `wb_sel_i[3:0]` | |
| `wb_stb_i` | |
| `wb_ack_o` | |
| `ext_rst_n` | |
| `wdt_rst_n` | |
| `sys_rst_n_o` | |
| `wdt_rst_n_o` | |
| `clk_gate_o[15:0]` | |

- **Bus Protocol:** Wishbone B4
- **Clock Domain:** sys_clk
- **Dependencies:** None

## Integration Notes

- Source: IP-005 v6 Trash Robot SoC (2026-07-15)
- Provenance: self (verified through full ASIC pipeline)
- PDK: sky130A (sky130_fd_sc_hd)
- Tier: A (200 toggle bins)

## Promotion Verdict: PROMOTED

