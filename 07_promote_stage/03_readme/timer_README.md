# timer — 4-Channel Timer/PWM (Wishbone B4). Each channel supports programmable period, duty cycle, prescaler (1/8/64/256), and one-shot or continuous mode. Interrupt on terminal count.

## Overview

4-Channel Timer/PWM (Wishbone B4). Each channel supports programmable period, duty cycle, prescaler (1/8/64/256), and one-shot or continuous mode. Interrupt on terminal count.

## Pipeline Results

| Stage | Result |
|-------|--------|
| Lint (iverilog) | PASS (0 errors) |
| Lint (verilator) | PASS (0 errors) |
| Formal BMC | PASS (config.sby) |
| Synthesis | PASS — 840 cells, 168 DFFs, 0 latches |
| Equivalence | CONDITIONAL PASS (sky130 SAT limitation) |
| RTL Simulation | 4/4 PASS |
| GLS Simulation | 4/4 PASS |
| Line Coverage | 100% |
| Toggle Coverage | 39.4% (482 bins) |

## Interface

| Port | Description |
|------|-------------|
| `wb_clk_i` | |
| `wb_rst_i` | |
| `wb_adr_i[4:0]` | |
| `wb_dat_i[31:0]` | |
| `wb_dat_o[31:0]` | |
| `wb_we_i` | |
| `wb_sel_i[3:0]` | |
| `wb_stb_i` | |
| `wb_ack_o` | |
| `irq_o[3:0]` | |

- **Bus Protocol:** Wishbone B4
- **Clock Domain:** sys_clk
- **Dependencies:** None

## Integration Notes

- Source: IP-005 v6 Trash Robot SoC (2026-07-15)
- Provenance: self (verified through full ASIC pipeline)
- PDK: sky130A (sky130_fd_sc_hd)
- Tier: A (482 toggle bins)

## Promotion Verdict: PROMOTED

