# PRJ-002 — Trash Robot SoC

**Autonomous Wheelie Bin Rover Controller | sky130A | 0.925 mm² | 160K cells**

## Overview
Single-chip ASIC controller for a motorized wheelie bin rover targeting GCC residential curbside trash delivery. Integrates a PicoRV32 RV32IM RISC-V core with 14 Wishbone B4 slave peripherals — motor PWM, ultrasonic sensors, I²C weight/current/RTC, UART telemetry, and power management. GDS-proven at 1.17 mm² (v5) and re-executed for v6 with thesis-grade documentation.

## Architecture
| Spec | Value |
|------|-------|
| CPU | PicoRV32 RV32IM (2-3 stage, ISC license) |
| Bus | Wishbone B4 shared (16-bit addr, 32-bit data, 1 master, 14 slaves) |
| Clock | 33.3 MHz (single domain) |
| SRAM | 512B unified Von Neumann (128×32-bit) |
| Die Area | 0.925 mm² (v6) / 1.17 mm² (v5) |
| Cells | 160,800 placed |
| Package | Caravel harness (sky130A) |
| DRC | 0 violations |
| LVS | Match |

## Peripherals (14)
| # | Module | Interface | Function |
|---|--------|-----------|----------|
| 1 | Motor PWM ×4 | WB4 + DRV8833 | Differential-drive PHASE/ENABLE |
| 2 | Ultrasonic ×2 | WB4 + HC-SR04 | Dual-channel echo capture (20-bit) |
| 3 | I²C (HX711) | WB4 | Weight sensor safety interlock |
| 4 | I²C (INA219) | WB4 | Solar current/voltage monitor |
| 5 | I²C (DS3231) | WB4 | Hardware RTC |
| 6 | UART | WB4 | ESP32-C3 WiFi telemetry |
| 7 | GPIO ×16 | WB4 | Bump sensors, button, status LEDs |
| 8 | Timer | WB4 | 32-bit + auxiliary PWM |
| 9 | Weight Detect | WB4 | Threshold detection |
| 10 | Watchdog | WB4 | Dual-stage, magic-key reload |
| 11 | Interrupt Ctrl | WB4 | 16-channel priority encoder |
| 12 | Power Manager | WB4 | Clock gating + sleep/wake FSM |
| 13 | WB Interconnect | WB4 | 14-slave address decoder |
| 14 | SRAM 512B | WB4 | Unified code+data |

## Reuse Ratio
16/16 modules = 100% design heritage from v5. V6 is a full-pipeline re-execution with Python golden models and thesis-grade documentation.

## Status
- ✅ RTL (lint, formal, synthesis, equivalence)
- ✅ Verification (all 14 peripherals + SoC-level)
- ✅ Firmware (BSP, drivers, bootrom)
- ✅ Backend (P&R, STA 6-corners, DRC=0, LVS=match)
- ✅ GDS delivered (7 .gds files)

## Post-Mortem
See `11_postmortem_audit/` for stage-by-stage lessons learned.

---
*Built with Vera (Hermes Agentic ASIC Framework) — PRJ-002 v6a, July 2026*
