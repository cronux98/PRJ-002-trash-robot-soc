# Third-Party Components — PRJ-002 Trash Robot SoC

This project integrates open-source hardware IP from multiple sources. Each component retains its original license. This file documents attribution as required by those licenses.

## RISC-V Core

**Component:** PicoRV32 RV32IM (size-optimized configuration)
**Source:** YosysHQ / Claire Wolf — https://github.com/YosysHQ/picorv32
**License:** ISC (permissive, equivalent to MIT/BSD)
**Copyright:** Claire Wolf
**Files:** `04_frontend_stage/07_rtl_picorv32_core/rtl/picorv32.v`

## SRAM Macro

**Component:** OpenRAM Sky130 SRAM (512B, 128×32-bit)
**Source:** OpenRAM Project — https://github.com/VLSIDA/OpenRAM
**License:** BSD 3-Clause
**Files:** `04_frontend_stage/09_rtl_sram_512b/`

## Caravel Harness

**Component:** Caravel SoC Harness (user_project_wrapper)
**Source:** Efabless — https://github.com/efabless/caravel_user_project
**License:** Apache 2.0
**Files:** `09_caravel_stage/01_caravel/caravel_wrapper/`

## Wishbone B4 Specification

**Component:** Wishbone B4 Interconnect specification
**Source:** OpenCores — https://opencores.org/howto/wishbone
**License:** CC-BY-4.0 (specification), custom RTL implementations
**Files:** `04_frontend_stage/14_rtl_wb_interconnect/`

## Custom IP (Original Work)

The following modules are original designs created by the Hermes agentic ASIC framework:

| Block | File |
|-------|------|
| trash_robot_soc (top-level) | `04_frontend_stage/16_rtl_trash_robot_soc/` |
| gpio (16-bit, interrupt-capable) | `04_frontend_stage/01_rtl_gpio/` |
| i2c_master (×3 instances: DS3231, HX711, INA219) | `04_frontend_stage/02_rtl_i2c_ds3231/`, `03_rtl_i2c_hx711/`, `04_rtl_i2c_ina219/` |
| interrupt_ctrl (16-channel priority encoder) | `04_frontend_stage/05_rtl_interrupt_ctrl/` |
| motor_pwm (4-ch DRV8833 PHASE/ENABLE) | `04_frontend_stage/06_rtl_motor_pwm/` |
| power_mgr (clock gating + sleep/wake FSM) | `04_frontend_stage/08_rtl_power_mgr/` |
| sram_512b (unified Von Neumann) | `04_frontend_stage/09_rtl_sram_512b/` |
| timer (32-bit + aux PWM) | `04_frontend_stage/10_rtl_timer/` |
| uart (Wishbone B4) | `04_frontend_stage/11_rtl_uart/` |
| ultrasonic_capture (HC-SR04 echo capture) | `04_frontend_stage/12_rtl_ultrasonic_capture/` |
| watchdog (dual-stage, magic-key reload) | `04_frontend_stage/13_rtl_watchdog/` |
| wb_interconnect (14-slave address decoder) | `04_frontend_stage/14_rtl_wb_interconnect/` |
| weight_detect (HX711 threshold + interrupt) | `04_frontend_stage/15_rtl_weight_detect/` |

**License:** Apache 2.0 (same as rest of project)

## PDK

**Component:** SkyWater sky130_fd_sc_hd (130nm open-source PDK)
**Source:** SkyWater Technology / Google — https://github.com/google/skywater-pdk
**License:** Apache 2.0

## Toolchain

The following open-source EDA tools were used by the agentic framework (not distributed in this repository):

| Tool | Version | License |
|------|---------|---------|
| Yosys | 0.62 | ISC |
| OpenROAD | 2026-02-17 | BSD 3-Clause |
| Magic VLSI | 8.3.623 | MIT-style |
| Klayout | 0.30.7 | GPL |
| Netgen | 1.5.316 | GPL |
| Icarus Verilog | s20250103 | GPL |
| Verilator | 5.044 | LGPL |
| cocotb | 1.9.x | BSD 3-Clause |
| SymbiYosys | — | ISC |

## Framework

The agentic workflow that produced this chip uses the Hermes agent framework and the Vera ASIC orchestration system. No human wrote RTL, testbenches, SDC constraints, or invoked EDA tools — all design artifacts were produced autonomously by Claude Opus 4.8 subagents working from specification documents and project templates.

---

*If you believe any attribution is missing or incorrect, please open an issue.*
