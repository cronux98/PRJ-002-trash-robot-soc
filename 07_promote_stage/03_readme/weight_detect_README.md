# weight_detect — Weight Threshold Detector (Wishbone B4). Compares 24-bit sensor input value against a programmable threshold register. Generates interrupt when sensor value exceeds threshold. Edge-selectable (rising/falling/both).

## Overview

Weight Threshold Detector (Wishbone B4). Compares 24-bit sensor input value against a programmable threshold register. Generates interrupt when sensor value exceeds threshold. Edge-selectable (rising/falling/both).

## Pipeline Results

| Stage | Result |
|-------|--------|
| Lint (iverilog) | PASS (0 errors) |
| Lint (verilator) | PASS (0 errors) |
| Formal BMC | PASS (config.sby) |
| Synthesis | PASS — 316 cells, 78 DFFs, 0 latches |
| Equivalence | CONDITIONAL PASS (sky130 SAT limitation) |
| RTL Simulation | 4/4 PASS |
| GLS Simulation | 4/4 PASS |
| Line Coverage | 100% |
| Toggle Coverage | 23.8% (320 bins) |

## Interface

| Port | Description |
|------|-------------|
| `wb_clk_i` | |
| `wb_rst_i` | |
| `wb_adr_i[2:0]` | |
| `wb_dat_i[31:0]` | |
| `wb_dat_o[31:0]` | |
| `wb_we_i` | |
| `wb_sel_i[3:0]` | |
| `wb_stb_i` | |
| `wb_ack_o` | |
| `sensor_in[23:0]` | |
| `irq_o` | |

- **Bus Protocol:** Wishbone B4
- **Clock Domain:** sys_clk
- **Dependencies:** None

## Integration Notes

- Source: IP-005 v6 Trash Robot SoC (2026-07-15)
- Provenance: self (verified through full ASIC pipeline)
- PDK: sky130A (sky130_fd_sc_hd)
- Tier: A (320 toggle bins)

## Promotion Verdict: PROMOTED

