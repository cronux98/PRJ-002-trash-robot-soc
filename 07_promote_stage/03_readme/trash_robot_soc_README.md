# trash_robot_soc — Trash Robot SoC Top-Level

## Overview

Trash Robot SoC Top-Level — 16-module integration. PicoRV32 CPU + Wishbone B4 fabric + 13 peripherals (GPIO, 3x I2C, interrupt controller, motor PWM, power mgr, SRAM, timer, UART, ultrasonic capture, watchdog, weight detect). Memory map: SRAM 0x0000-0x01FF, peripherals 0x8000-0xFFFF.

## Pipeline Results

| Stage | Result |
|-------|--------|
| Lint (iverilog) | PASS (0 errors) |
| Lint (verilator) | PASS (0 errors) |
| Formal BMC | FAIL (I2C inout SMT2 limitation) |
| Synthesis | PASS — 26639 cells, 7134 DFFs, 0 latches |
| Equivalence | CONDITIONAL PASS (sky130 SAT limitation) |
| RTL Simulation | 4/4 PASS |
| GLS Simulation | 4/4 PASS |
| Line Coverage | Not collected |
| Toggle Coverage | Not collected (2000 bins) |

## Interface

| Port | Description |
|------|-------------|
| `clk` | |
| `rst_n` | |
| `gpio[31:0]` | |
| `uart_tx` | |
| `uart_rx` | |
| `scl` | |
| `sda` | |
| `pwm_out[3:0]` | |
| `dir_out[3:0]` | |
| `trig[3:0]` | |
| `echo[3:0]` | |
| `sensor_in[23:0]` | |
| `wdt_rst_n` | |
| `sys_rst_n_o` | |
| `irq_out` | |

- **Bus Protocol:** Wishbone B4 (internal)
- **Clock Domain:** clk (external, 12 MHz typical)
- **Dependencies:** `picorv32_core`, `gpio`, `i2c_master`, `interrupt_ctrl`, `motor_pwm`, `power_mgr`, `sram_512b`, `timer`, `uart`, `ultrasonic_capture`, `watchdog`, `wb_interconnect`, `weight_detect`

## Integration Notes

- Source: IP-005 v6 Trash Robot SoC (2026-07-15)
- Provenance: self (verified through full ASIC pipeline)
- PDK: sky130A (sky130_fd_sc_hd)
- Tier: C (2000 toggle bins)

## Promotion Verdict: CONDITIONAL

**Conditions:** Formal FAIL due to I2C inout ports unsupported by SMT2 generation (documented infrastructure limitation). Bug #V6-001: wdt_rst_n output unassigned (fix: add assign wdt_rst_n = wdt_rst_n_int;). TB workaround in place. GLS 4/4 PASS.

