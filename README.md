# PRJ-002 — Trash Robot SoC

**I designed the agentic ASIC framework. The framework autonomously produced this chip — no human wrote RTL, testbenches, or ran EDA tools.**

![KLayout render of trash_robot_soc GDS — sky130A, 0.925mm²](layout_beauty.png)

Tapeout-ready GDS on SkyWater 130nm. PicoRV32 RV32IM, 14 Wishbone B4 peripherals, autonomous wheelie bin rover controller. DRC=0, LVS match.

---

## Chip Summary

| Metric | Value |
|--------|-------|
| **Core** | PicoRV32 RV32IM (YosysHQ, ISC license) |
| **Process** | sky130_fd_sc_hd (SkyWater 130nm) |
| **Frequency** | 33.3 MHz (single clock domain) |
| **Bus** | Wishbone B4 shared bus (16-bit addr, 32-bit data, 1 master) |
| **SRAM** | 512B unified Von Neumann (128×32-bit) |
| **Peripherals** | 14 Wishbone B4 slaves |
| **Cells** | 160,800 standard cells |
| **Die Area** | 0.925 mm² |
| **Power** | 1.8V core / 3.3V IO |
| **Flow** | LibreLane v3 (Yosys + OpenROAD + Magic + Klayout) |

---

## Peripherals

| # | Module | Interface | Function |
|---|--------|-----------|----------|
| 1 | Motor PWM ×4 | WB4 + DRV8833 | Differential-drive PHASE/ENABLE |
| 2 | Ultrasonic ×2 | WB4 + HC-SR04 | Dual-channel echo capture (20-bit) |
| 3 | I²C (HX711) | WB4 | Weight sensor safety interlock |
| 4 | I²C (INA219) | WB4 | Solar current/voltage monitor |
| 5 | I²C (DS3231) | WB4 | Hardware RTC for offline scheduling |
| 6 | UART | WB4 | ESP32-C3 WiFi telemetry |
| 7 | GPIO ×16 | WB4 | Bump sensors, button, status LEDs |
| 8 | Timer | WB4 | 32-bit + auxiliary PWM |
| 9 | Weight Detect | WB4 | Threshold detection + interrupt |
| 10 | Watchdog | WB4 | Dual-stage, magic-key reload |
| 11 | Interrupt Ctrl | WB4 | 16-channel priority encoder |
| 12 | Power Manager | WB4 | Clock gating + sleep/wake FSM |
| 13 | WB Interconnect | WB4 | 14-slave address decoder |
| 14 | SRAM 512B | WB4 | Unified code+data |

**Reuse Ratio:** 16/16 modules = 100% design heritage from v5 GDS-proven baseline.

---

## Stage Status

| # | Stage | Verdict | Retries |
|---|-------|---------|---------|
| 0 | Business Analysis | ✅ PASS | 0 |
| 1 | Specification | ✅ PASS | 0 |
| 2 | Architecture | ✅ PASS | 0 |
| 3 | Frontend (RTL) | ✅ PASS | 2 |
| 4 | Firmware | ✅ PASS | 0 |
| 5 | Verification | ✅ PASS | 0 |
| 6 | Promotion | ✅ PASS | 0 |
| 7 | Backend (P&R) | ✅ PASS | 1 |
| 8 | Caravel Integration | ✅ PASS | 0 |
| 9 | Documentation | ✅ PASS | 0 |

### Backend Results
- **Setup WNS:** Timing closed at 33.3 MHz
- **DRC:** 0 violations (Magic + Klayout)
- **LVS:** Netlist matches layout
- **STA:** 6 corners analyzed, all clean
- **Antenna:** Clean after diode insertion
- **GDS:** 7 .gds files delivered
- **SRAM:** Blackbox verified — no behavioral flop expansion

### Verification
- **Testbenches:** Cocotb-based for all 14 peripherals + SoC-level
- **GLS:** Gate-level simulation matched RTL results
- **Failure clusters:** 0 (no RTL bugs found)

---

## Repository Structure

```
├── README.md
├── layout_beauty.png          ← KLayout GDS render
├── LICENSE
├── THIRD_PARTY.md
├── waiver_ledger.json
├── .gitignore
├── 00_validation_report/      ← per-stage validation (11 reports)
├── 11_postmortem_audit/       ← postmortems (11 reports)
├── 01_business_stage/         ← market analysis
├── 02_specification_stage/    ← system specification
├── 03_architecture_stage/     ← architecture document
├── 04_frontend_stage/         ← RTL + lint/synth/formal/equiv logs
├── 05_firmware_stage/         ← BSP + drivers + bootrom
├── 06_verification_stage/     ← cocotb testbenches + results
├── 07_promote_stage/          ← per-module promotion reports
├── 08_backend_stage/          ← GDS + constraints + macros
├── 09_caravel_stage/          ← precheck logs + report
└── 10_document_stage/         ← documentation
```

---

## Third-Party Components

| Component | Source | License |
|-----------|--------|---------|
| PicoRV32 RISC-V Core | YosysHQ / Claire Wolf | ISC |
| OpenRAM SRAM Macro | OpenRAM Project | BSD 3-Clause |
| Caravel Harness | Efabless | Apache 2.0 |
| sky130 PDK | SkyWater / Google | Apache 2.0 |
| EF_UART, EF_SPI, EF_I2C, EF_GPIO8, EF_TMR32, EF_WDT32, EF_PIN_MUX | Efabless IP Library | Apache 2.0 |

See [THIRD_PARTY.md](THIRD_PARTY.md) for full attribution.

---

## License

Apache 2.0. See [LICENSE](LICENSE).

---

*Built with Vera (Hermes Agentic ASIC Framework) — PRJ-002 v6a, July 2026*
*No human wrote RTL, testbenches, constraints, or ran EDA tools for this chip.*
