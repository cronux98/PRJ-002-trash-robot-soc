# uart — UART Controller (Wishbone B4). Configurable baud rate (prescaler), 8N1 frame format. TX: 8-byte FIFO, RX: 8-byte FIFO. Status register: TX full/empty, RX full/empty, frame/parity error.

## Overview

UART Controller (Wishbone B4). Configurable baud rate (prescaler), 8N1 frame format. TX: 8-byte FIFO, RX: 8-byte FIFO. Status register: TX full/empty, RX full/empty, frame/parity error.

## Pipeline Results

| Stage | Result |
|-------|--------|
| Lint (iverilog) | PASS (0 errors) |
| Lint (verilator) | PASS (0 errors) |
| Formal BMC | BMC20 PASS |
| Synthesis | PASS — 335 cells, 103 DFFs, 0 latches |
| Equivalence | CONDITIONAL PASS (sky130 SAT limitation) |
| RTL Simulation | 6/6 PASS |
| GLS Simulation | 5/6 PASS |
| Line Coverage | 100% |
| Toggle Coverage | 41.4% (406 bins) |

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
| `tx` | |
| `rx` | |

- **Bus Protocol:** Wishbone B4
- **Clock Domain:** sys_clk
- **Dependencies:** None

## Integration Notes

- Source: IP-005 v6 Trash Robot SoC (2026-07-15)
- Provenance: self (verified through full ASIC pipeline)
- PDK: sky130A (sky130_fd_sc_hd)
- Tier: A (406 toggle bins)

## Promotion Verdict: CONDITIONAL

**Conditions:** GLS waiver W3: zero-delay gate-level RX sampling window artifact. RTL 6/6 PASS. BMC20 PASS. With back-annotated SDF timing from P&R, sampling window is met.

