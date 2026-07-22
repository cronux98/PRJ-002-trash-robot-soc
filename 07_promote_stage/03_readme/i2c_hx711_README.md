# i2c_hx711 — I2C HX711 Weight Sensor ADC Interface

## Overview

I2C HX711 Weight Sensor ADC Interface — Wishbone B4 wrapper over i2c_master core. Reads 24-bit ADC values from HX711 load cell amplifier. I2C address: 0x77.

## Pipeline Results

| Stage | Result |
|-------|--------|
| Lint (iverilog) | PASS (0 errors) |
| Lint (verilator) | PASS (0 errors) |
| Formal BMC | PASS (config.sby) |
| Synthesis | PASS — 280 cells, 69 DFFs, 0 latches |
| Equivalence | CONDITIONAL PASS (sky130 SAT limitation) |
| RTL Simulation | 4/4 PASS |
| GLS Simulation | 4/4 PASS |
| Line Coverage | Not collected |
| Toggle Coverage | Not collected (500 bins) |

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
| `scl` | |
| `sda` | |

- **Bus Protocol:** Wishbone B4 + I2C
- **Clock Domain:** sys_clk
- **Dependencies:** `i2c_master`

## Integration Notes

- Source: IP-005 v6 Trash Robot SoC (2026-07-15)
- Provenance: self (verified through full ASIC pipeline)
- PDK: sky130A (sky130_fd_sc_hd)
- Tier: A (500 toggle bins)

## Promotion Verdict: PROMOTED

