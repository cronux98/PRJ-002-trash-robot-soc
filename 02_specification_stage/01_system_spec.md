# System Specification — IP-005 v6 Trash Robot SoC

**Date:** 2026-07-15
**Analyst:** spec-product-engineer (Stage 1 Planning)
**Previous Version:** v5 (GDS proven: 1.17 mm², DRC 0, LVS match, 26,798 cells)
**STATUS:** COMPLETE — AUTO-GENERATED from kanban task brief + v5 reference

---

## 1. Project Identity

| Field | Value |
|-------|-------|
| Project Name | Trash Robot SoC |
| Project ID | IP-005 |
| Version | v6 |
| Description | Autonomous motorized wheelie bin rover controller — single-chip SoC with PicoRV32 RISC-V CPU, 512B SRAM, 14 Wishbone B4 peripherals for multi-sensor interfaces, motor PWM, and ESP32-C3 telemetry. Full SoC GDS target (not SRAM-only). |
| Target Application | Residential curbside trash bin delivery (GCC market) |
| Project Type | SoC |
| Predecessor | v5 — GDS proven at 1.17 mm², 26,798 placed cells, DRC 0, LVS match |
| V6 Goal | Full-pipeline re-execution for all 16 modules; thesis-grade design documentation |

## 2. Instruction Set Architecture

| Field | Value |
|-------|-------|
| ISA | RV32IM (Base Integer + Multiply/Divide) |
| CPU Core | PicoRV32 (YosysHQ / Claire Wolf) |
| License | ISC (permissive, equivalent to MIT/BSD) |
| Privilege Modes | Machine only (bare-metal firmware, no OS) |
| CSRs | Standard RV32IM machine-mode CSRs |
| Custom Instructions | None |
| Pipeline | 2-3 stage (PicoRV32 size-optimized) |
| Config | ENABLE_MUL=1, ENABLE_DIV=1, ENABLE_IRQ=1, ENABLE_REGS_DUALPORT=1 (DEFAULT) |

## 3. Process & Technology

| Field | Value |
|-------|-------|
| PDK | sky130A (SkyWater 130nm CMOS) |
| Standard Cells | sky130_fd_sc_hd (high-density) |
| Frequency | 33.3 MHz |
| Package | Caravel harness (Efabless chipIgnite MPW) |
| User Area Available | 10.8 mm² (3000 µm × 3600 µm) |
| Target Die Area | < 3.0 mm² |
| Estimated Die Area | ~1.3 mm² (v5-calibrated) |
| V5 Actual Die Area | 1.17 mm² (26,798 cells) |
| Core Voltage | 1.8V |
| IO Voltage | 3.3V |
| Utilization Target | 50-55% (routing safety on sky130A) |

## 4. Peripherals & Interfaces

| # | Module | Interface | Description |
|---|--------|-----------|-------------|
| 1 | Motor PWM ×4 | Wishbone B4 + DRV8833 | 4-channel differential-drive PWM (PHASE/ENABLE mode) |
| 2 | Ultrasonic ×2 | Wishbone B4 + HC-SR04 | Dual-channel pulse generation + echo capture (20-bit) |
| 3 | I²C Master (HX711) | Wishbone B4 + I²C | Weight sensor interface (safety interlock) |
| 4 | I²C Master (INA219) | Wishbone B4 + I²C | Solar current/voltage monitor |
| 5 | I²C Master (DS3231) | Wishbone B4 + I²C | Hardware RTC for offline scheduling |
| 6 | UART | Wishbone B4 + TX/RX | ESP32-C3 WiFi telemetry |
| 7 | GPIO ×16 | Wishbone B4 + pads | Bump sensors, user button, status outputs |
| 8 | Timer | Wishbone B4 | 32-bit system timer with auxiliary PWM channels |
| 9 | Weight Detect | Wishbone B4 | HX711 threshold detection + interrupt |
| 10 | Watchdog | Wishbone B4 | Dual-stage (warning + reset), magic-key reload |
| 11 | Interrupt Controller | Wishbone B4 | 16-channel priority encoder |
| 12 | Power Manager | Wishbone B4 | Module clock gating, sleep/wake FSM |
| 13 | WB Interconnect | Wishbone B4 | Shared bus with combinational address decode |

**Total peripheral instances:** 14 Wishbone B4 slave ports (3× I²C counted individually).

## 5. Memory Architecture

| Field | Value |
|-------|-------|
| Architecture | Von Neumann (unified instruction + data) |
| SRAM Size | 512B (128 × 32-bit words) |
| SRAM Type | OpenRAM macro (sky130) or FF-based |
| Address Width | 16-bit (Wishbone) |
| Data Width | 32-bit |
| Byte-Enable | Yes (wb_sel_i[3:0] for byte/halfword/word) |
| Access | Single-cycle classic Wishbone (no pipelining) |
| Boot | `$readmemh` from firmware.hex (Caravel QSPI boot pathway) |
| Constraint | Von Neumann: code + data share 512B. v4/v5 proven fit. |

## 6. Bus Architecture

| Field | Value |
|-------|-------|
| Protocol | Wishbone B4 (classic mode) |
| Data Width | 32-bit |
| Address Width | 16-bit (64KB addressable) |
| Endianness | Little-endian |
| Masters | 1 (PicoRV32 via Wishbone wrapper) |
| Slaves | 14 (via wb_interconnect) |
| Interconnect | Shared bus with combinational address decode |
| Slave Select | wbm_adr_i[15:12] — 4-bit decode, 16 possible slots |
| Arbitration | Single master — no arbitration needed |
| Burst Support | None (classic mode, single-cycle) |

## 7. Clock & Reset

| Field | Value |
|-------|-------|
| Clock Domains | 1 (single domain, 33.3 MHz) |
| Clock Source | External oscillator (Caravel harness) |
| Reset Type | Active-low (rst_ni) |
| Reset Assertion | Async assert |
| Reset Deassertion | Sync deassert (2-stage synchronizer) |
| Reset Sequence | All modules reset simultaneously |
| Clock Gating | Per-module via power_mgr |
| Power States | ACTIVE → SLEEP → WAKE (FSM in power_mgr) |

## 8. Power

| Field | Value |
|-------|-------|
| Target Core Power | < 0.1 mW |
| Estimated Core Power | ~0.02 mW at 33.3 MHz |
| System Power Dominated By | DRV8833 (5-10W peak), ESP32-C3 (~200 mW WiFi active), HC-SR04 (75 mW ×2) |
| Power Domains | 1 (no multiple voltage domains) |
| Sleep Mode | Clock gating via power_mgr |
| Wake Sources | RTC (DS3231), Button, Core sleep request |

## 9. Verification

| Field | Value |
|-------|-------|
| Methodology | Python golden model → behavioral validation |
| Golden Model | Python behavioral models for all 16 modules |
| ISA Reference | PicoRV32 ISA compliance (RV32IM) |
| Formal | SymbiYosys BMC ≥ 20 (target all modules) |
| Simulation | cocotb + Icarus Verilog |
| Coverage Target | 95% line, 95% branch |
| Equivalence | Yosys equiv_simple |
| GLS | Gate-Level Simulation (target all modules) |

## 10. Physical Design

| Field | Value |
|-------|-------|
| Floorplan | Caravel user project area (3.0 × 3.6 mm) |
| Placement Utilization | 50-55% target |
| CTS | Clock tree synthesis with sky130 buffers |
| Routing | Global + detailed routing (OpenROAD) |
| DRC Target | 0 violations |
| LVS Target | Match |
| IR Drop | < 5% |
| PD Runtime Budget | 4+ hours (v5: 3.5 hr) |
| Metric Extraction | STA WNS/TNS, power from OpenSTA |

## 11. Constraints & Risks

| # | Constraint | Severity | Mitigation |
|---|-----------|----------|------------|
| C1 | 512B unified SRAM (Von Neumann) | HIGH | v4/v5 firmware fit proven; maintain compact code discipline |
| C2 | Cell inflation 12-18× RTL → placed | MEDIUM | v4: 1,852 RTL → 26,798 placed; v6 estimate calibrated from v5 |
| C3 | PD runtime may exceed timeout | MEDIUM | Allocate 4+ hour budget |
| C4 | Wishbone B4 classic mode only | LOW | No burst/pipeline — simple but area-efficient |
| C5 | PicoRV32 RV32IM area (~3,200 cells) | LOW | Well within 3.0 mm² target |
| C6 | I²C bus shared among 3 peripherals | LOW | v4/v5 proven; 100/400 kHz standard mode |
| C7 | Full pipeline on all 16 modules | HIGH (v6 new) | v5 was 100% REUSE; v6 runs each module through all stages |
| C8 | Golden models must be Python (not C++) | LOW | Python stdlib only; same behavioral fidelity as v5 C++ models |

## 12. Module Inventory

| # | Module Name | Category | Interface | V5 Source | V6 Status |
|---|-------------|----------|-----------|-----------|-----------|
| 1 | picorv32_core | Processor | Wishbone B4 master | GitHub/YosysHQ (ISC) | FULL PIPELINE |
| 2 | sram_512b | Memory | Wishbone B4 slave | IP-005 v5 (~7,430 FF cells) | FULL PIPELINE |
| 3 | wb_interconnect | Interface | Wishbone B4 fabric | IP-005 v5 (314 cells) | FULL PIPELINE |
| 4 | uart | Peripheral | Wishbone B4 slave | IP-005 v5 | FULL PIPELINE |
| 5 | i2c_master_hx711 | Peripheral | Wishbone B4 slave + I²C | IP-005 v5 | FULL PIPELINE |
| 6 | i2c_master_ina219 | Peripheral | Wishbone B4 slave + I²C | IP-005 v5 | FULL PIPELINE |
| 7 | i2c_master_ds3231 | Peripheral | Wishbone B4 slave + I²C | IP-005 v5 | FULL PIPELINE |
| 8 | gpio | Peripheral | Wishbone B4 slave | IP-005 v5 (554 cells) | FULL PIPELINE |
| 9 | timer | Peripheral | Wishbone B4 slave | IP-005 v5 (1,373 cells) | FULL PIPELINE |
| 10 | motor_pwm | Peripheral | Wishbone B4 slave + DRV8833 | IP-005 v5 (470 cells) | FULL PIPELINE |
| 11 | ultrasonic_capture | Peripheral | Wishbone B4 slave + HC-SR04 | IP-005 v5 (1,314 cells) | FULL PIPELINE |
| 12 | weight_detect | Peripheral | Wishbone B4 slave | IP-005 v5 (342 cells) | FULL PIPELINE |
| 13 | watchdog | Governance | Wishbone B4 slave | IP-005 v5 (444 cells) | FULL PIPELINE |
| 14 | interrupt_ctrl | Governance | Wishbone B4 slave | IP-005 v5 (280 cells) | FULL PIPELINE |
| 15 | power_mgr | Governance | Wishbone B4 slave | IP-005 v5 (193 cells) | FULL PIPELINE |
| 16 | trash_robot_top | Top-Level | Wishbone B4 + external I/O | IP-005 v5 (integration) | FULL PIPELINE |

**REUSE Ratio:** 100% source from v5 — all 16 modules carry forward with design heritage.
**Pipeline Mode:** FULL (not REUSE-only) — each module re-runs spec, system plan, research, golden model, and validation.
**V5 Validation:** GDS 1.17 mm², DRC 0, LVS match, 26,798 placed cells.

---

## Physical Design Feasibility (v5-Calibrated)

| Metric | v5 Estimate | v5 Actual | v6 Estimate |
|--------|------------|-----------|-------------|
| RTL cells (Yosys) | ~1,800-2,200 | 1,852 | ~1,800-2,200 |
| Placed cells (PD) | ~26,000-32,000 | 26,798 | ~26,000-32,000 |
| Die area | ~1.3 mm² | 1.17 mm² | ~1.3 mm² nominal |
| Cell inflation ratio | 14.5× | 14.5× | Calibrated |
| DRC violations | 0 (target) | 0 | 0 (target) |
| LVS | Match (target) | Match | Match (target) |
| PD runtime | 4+ hr | 3.5 hr | 4+ hr budget |

**Reference ORFS Examples:** PicoRV32 at 100 MHz on sky130hd → 3,200 cells, 0.18 mm² core-only.
**Risk Assessment:** LOW — v5 GDS proven. v6 is a full-pipeline refresh with Python golden models.

---

## Requirements Traceability

| Req ID | Source | Description | V5 Status | V6 Status |
|--------|--------|-------------|-----------|-----------|
| R1 | Task brief | PicoRV32 RV32IM @ 33.3 MHz | PASS | Carry forward |
| R2 | Task brief | 512B unified SRAM | PASS | Carry forward |
| R3 | Task brief | 14 Wishbone B4 peripherals | PASS | Carry forward |
| R4 | Task brief | Motor PWM ×4 (DRV8833) | PASS | Carry forward |
| R5 | Task brief | Ultrasonic ×2 (HC-SR04) | PASS | Carry forward |
| R6 | Task brief | HX711 weight sensor I²C | PASS | Carry forward |
| R7 | Task brief | INA219 solar monitor I²C | PASS | Carry forward |
| R8 | Task brief | DS3231 RTC I²C | PASS | Carry forward |
| R9 | Task brief | UART ESP32-C3 telemetry | PASS | Carry forward |
| R10 | Task brief | Watchdog dual-stage | PASS | Carry forward |
| R11 | Task brief | Interrupt controller 16-ch | PASS | Carry forward |
| R12 | Task brief | Power manager sleep/wake | PASS | Carry forward |
| R13 | Task brief | Full SoC GDS target | PASS | Carry forward |
| R14 | Task brief | PDK sky130A | PASS | Carry forward |
| R15 | Task brief | Full pipeline for all 16 modules | NEW | Execute |
| R16 | Task brief | Python golden models | NEW | Execute |

---

## Handoff to Architecture Stage

The architecture stage should:
1. Accept all 16 modules from this specification
2. Design Wishbone B4 interconnect with 14 slave ports
3. Maintain v5 memory map with 16-bit address decode (wbm_adr_i[15:12])
4. Design interrupt routing table for 16 interrupt channels
5. Define clock gating strategy for per-module power management
6. Generate updated block diagrams for all modules
7. Produce Python golden behavioral models for all 16 modules
