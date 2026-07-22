# sram_512b — 512-Byte SRAM (Wishbone B4). FF-based single-port memory, byte-addressable with 4-bit write strobe. 128 x 32-bit words. Used as data memory for PicoRV32 CPU.

## Overview

512-Byte SRAM (Wishbone B4). FF-based single-port memory, byte-addressable with 4-bit write strobe. 128 x 32-bit words. Used as data memory for PicoRV32 CPU.

## Pipeline Results

| Stage | Result |
|-------|--------|
| Lint (iverilog) | PASS (0 errors) |
| Lint (verilator) | PASS (0 errors) |
| Formal BMC | PASS (timed out deep) |
| Synthesis | PASS — 7478 cells, 4129 DFFs, 0 latches |
| Equivalence | CONDITIONAL PASS (sky130 SAT limitation) |
| RTL Simulation | 5/5 PASS |
| GLS Simulation | 5/5 PASS |
| Line Coverage | 100% |
| Toggle Coverage | 77.0% (226 bins) |

## Interface

| Port | Description |
|------|-------------|
| `wb_clk_i` | |
| `wb_rst_i` | |
| `wb_adr_i[8:0]` | |
| `wb_dat_i[31:0]` | |
| `wb_dat_o[31:0]` | |
| `wb_we_i` | |
| `wb_sel_i[3:0]` | |
| `wb_stb_i` | |
| `wb_ack_o` | |

- **Bus Protocol:** Wishbone B4
- **Clock Domain:** sys_clk
- **Dependencies:** None

## Integration Notes

- Source: IP-005 v6 Trash Robot SoC (2026-07-15)
- Provenance: self (verified through full ASIC pipeline)
- PDK: sky130A (sky130_fd_sc_hd)
- Tier: A (226 toggle bins)

## Promotion Verdict: PROMOTED

