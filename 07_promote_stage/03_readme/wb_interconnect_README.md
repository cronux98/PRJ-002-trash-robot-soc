# wb_interconnect — Wishbone B4 Shared Bus Interconnect (16-master x 16-slave). Round-robin arbitration, 32-bit data, 32-bit address. Signal names use _i (slave→master) and _o (master→slave) convention.

## Overview

Wishbone B4 Shared Bus Interconnect (16-master x 16-slave). Round-robin arbitration, 32-bit data, 32-bit address. Signal names use _i (slave→master) and _o (master→slave) convention.

## Pipeline Results

| Stage | Result |
|-------|--------|
| Lint (iverilog) | PASS (0 errors) |
| Lint (verilator) | PASS (0 errors) |
| Formal BMC | PASS (config.sby) |
| Synthesis | PASS — 367 cells, 32 DFFs, 0 latches |
| Equivalence | CONDITIONAL PASS (sky130 SAT limitation) |
| RTL Simulation | 4/4 PASS |
| GLS Simulation | 4/4 PASS |
| Line Coverage | Not collected |
| Toggle Coverage | Not collected (300 bins) |

## Interface

| Port | Description |
|------|-------------|
| `wb_clk_i` | |
| `wb_rst_i` | |
| `wbm_adr_o[31:0]` | |
| `wbm_dat_o[31:0]` | |
| `wbm_dat_i[31:0]` | |
| `wbm_we_o` | |
| `wbm_sel_o[3:0]` | |
| `wbm_stb_o` | |
| `wbm_ack_i` | |
| `wbm_cyc_o` | |
| `wbs_adr_i[31:0]` | |
| `wbs_dat_i[31:0]` | |
| `wbs_dat_o[31:0]` | |
| `wbs_we_i` | |
| `wbs_sel_i[3:0]` | |
| `wbs_stb_i` | |
| `wbs_ack_o` | |
| `wbs_cyc_i` | |

- **Bus Protocol:** Wishbone B4
- **Clock Domain:** sys_clk
- **Dependencies:** None

## Integration Notes

- Source: IP-005 v6 Trash Robot SoC (2026-07-15)
- Provenance: self (verified through full ASIC pipeline)
- PDK: sky130A (sky130_fd_sc_hd)
- Tier: A (300 toggle bins)

## Promotion Verdict: PROMOTED

