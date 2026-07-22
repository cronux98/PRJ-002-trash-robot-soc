# gpio — GPIO Controller (Wishbone B4)

## Overview

GPIO Controller (Wishbone B4) — 32-bit bidirectional GPIO with configurable direction per pin. Supports input, output, open-drain modes. Register map: DATA (0x00), DIR (0x04).

## Pipeline Results

| Stage | Result |
|-------|--------|
| Lint (iverilog) | PASS (0 errors) |
| Lint (verilator) | PASS (0 errors) |
| Formal BMC | BMC20 PASS |
| Synthesis | PASS — 231 cells, 110 DFFs, 0 latches |
| Equivalence | CONDITIONAL PASS (sky130 SAT limitation) |
| RTL Simulation | 4/4 PASS |
| GLS Simulation | 4/4 PASS |
| Line Coverage | 100% |
| Toggle Coverage | 42.5% (454 bins) |

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
| `gpio_in[31:0]` | |
| `gpio_out[31:0]` | |
| `gpio_oe[31:0]` | |

- **Bus Protocol:** Wishbone B4
- **Clock Domain:** sys_clk
- **Dependencies:** None

## Integration Notes

- Source: IP-005 v6 Trash Robot SoC (2026-07-15)
- Provenance: self (verified through full ASIC pipeline)
- PDK: sky130A (sky130_fd_sc_hd)
- Tier: A (454 toggle bins)

## Promotion Verdict: PROMOTED

