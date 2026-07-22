# interrupt_ctrl — 16-Channel Interrupt Controller with Priority Encoder (Wishbone B4). Supports level-sensitive interrupts, per-channel enable/mask, priority-encoded vector output, and pending register with write-1-to-clear.

## Overview

16-Channel Interrupt Controller with Priority Encoder (Wishbone B4). Supports level-sensitive interrupts, per-channel enable/mask, priority-encoded vector output, and pending register with write-1-to-clear.

## Pipeline Results

| Stage | Result |
|-------|--------|
| Lint (iverilog) | PASS (0 errors) |
| Lint (verilator) | PASS (0 errors) |
| Formal BMC | PASS (config.sby) |
| Synthesis | PASS — 280 cells, 82 DFFs, 0 latches |
| Equivalence | CONDITIONAL PASS (sky130 SAT limitation) |
| RTL Simulation | 4/4 PASS |
| GLS Simulation | 4/4 PASS |
| Line Coverage | Not collected |
| Toggle Coverage | Not collected (400 bins) |

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
| `irq_in[15:0]` | |
| `irq_out` | |

- **Bus Protocol:** Wishbone B4
- **Clock Domain:** sys_clk
- **Dependencies:** None

## Integration Notes

- Source: IP-005 v6 Trash Robot SoC (2026-07-15)
- Provenance: self (verified through full ASIC pipeline)
- PDK: sky130A (sky130_fd_sc_hd)
- Tier: A (400 toggle bins)

## Promotion Verdict: PROMOTED

