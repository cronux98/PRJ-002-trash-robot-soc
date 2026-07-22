# Market Requirements — IP-005 v6 Trash Robot ASIC

**Date:** 2026-07-15
**Based on:** Domain research, competitive analysis (5 comparables), v4 silicon validation

---

## MoSCoW Feature Classification

### MUST (Minimum Viable Product — Cannot Ship Without)

| ID | Requirement | Rationale | Source |
|----|------------|-----------|--------|
| **M1** | PicoRV32 RV32IM CPU core running at ≥ 25 MHz | Core compute. ISC license. v4/v5 proven. | v4 GDS; PicoRV32 repo |
| **M2** | 512B unified SRAM (Von Neumann, instruction + data) | Firmware proven to fit in 512B. Tight constraint forces efficiency. | v4 firmware analysis |
| **M3** | I²C master controller (400 kHz) on shared bus | HX711 + INA219 + DS3231 share one bus. Eliminates pin count. | v4 architecture |
| **M4** | 4-channel motor PWM with PHASE/ENABLE mode | DRV8833 dual H-bridge control. Dead-time insertion for safety. | DRV8833 datasheet |
| **M5** | Ultrasonic sensor capture (×2 minimum, ×4 stretch) | Obstacle detection for autonomous navigation. Pulse-width capture. | HC-SR04 datasheet |
| **M6** | Weight threshold detection via HX711 (I²C) | Safety: prevent movement when bin >30 kg. I²C register read + threshold compare. | HX711 datasheet |
| **M7** | Solar charge monitoring via INA219 (I²C) | Battery health and solar availability. Voltage + current read. | INA219 datasheet |
| **M8** | RTC alarm scheduling via DS3231 (I²C) | Wake-up timer for scheduled collection days. Offline operation. | DS3231 datasheet |
| **M9** | UART TX/RX (115200 baud, 8N1) | Communication with ESP32-C3 co-processor (WiFi bridge). | ESP32-C3 UART spec |
| **M10** | GPIO (≥ 4 pins: 2× status LED, 2× button) | User feedback and manual override. | Product requirement |
| **M11** | Wishbone B4 shared bus interconnect | Connect PicoRV32 to all 14 peripherals. v4/v5 proven. | v4 architecture |
| **M12** | Interrupt controller (≥ 8 sources) | RTC alarm, weight alert, ultrasonic echo, UART RX, timer overflow. | v4 architecture |

### SHOULD (Important — Include If Time/Area Permits)

| ID | Requirement | Rationale | v6 Priority |
|----|------------|-----------|-------------|
| **S1** | Watchdog timer (Wishbone B4) | System reliability. IP exists in library at 0.20 mm² (ip-005-watchdog). | **HIGH** |
| **S2** | Power manager (clock gating, sleep modes) | Extend battery life. IP exists at 0.09 mm² (ip-005-power-mgr). | MEDIUM |
| **S3** | RGB LED PWM driver (status indication) | Visual feedback: battery level, schedule status, error codes. IP exists at 0.22 mm². | LOW |
| **S4** | Timer/PWM general-purpose (4 channels) | Software-controlled timing beyond motor PWM. IP exists at 0.62 mm². | LOW |
| **S5** | SPI host (for future sensor expansion) | Optional external ADC/sensor bus. IP exists at 2.4 mm² (ip-005-spi-host). | **DEFER** |
| **S6** | I²C multimaster support | Allow ESP32-C3 to also be I²C master for OTA firmware updates. | MEDIUM |
| **S7** | Automated STA metric extraction in PD flow | Capture WNS, TNS, power from OpenSTA reports. v4 gap. | **HIGH** |

### COULD (Nice to Have — Include Only If Trivial)

| ID | Requirement | Rationale |
|----|------------|-----------|
| **C1** | Hardware CRC-8 for I²C data integrity | Marginal reliability gain; software CRC sufficient. |
| **C2** | Brown-out detector | sky130A I/O pads may provide this; check Caravel harness. |
| **C3** | Firmware OTA update via UART bridge | Requires bootloader in SRAM — likely won't fit in 512B. |
| **C4** | Ultrasonic temperature compensation | Improves accuracy ±2 cm; software correction feasible. |
| **C5** | Debug trace port (JTAG-lite over GPIO) | Useful for bringup but pin-constrained. |

### WON'T (Explicitly Excluded — Prevent Scope Creep)

| ID | Exclusion | Rationale |
|----|-----------|-----------|
| **W1** | WiFi/Bluetooth radio on-die | Too complex for sky130A. ESP32-C3 handles wireless. |
| **W2** | Camera/computer vision pipeline | Requires MB of SRAM, DSP. Out of scope. |
| **W3** | GPS receiver | Not needed for curb-to-curb. Ultrasonic + odometry sufficient. |
| **W4** | AI/ML accelerator | Overkill for threshold-based navigation. |
| **W5** | External DRAM/flash controller | 512B SRAM only. No external memory bus. |
| **W6** | USB interface | Debug via UART. USB PHY too complex for sky130A. |
| **W7** | CAN bus | Consumer product doesn't need automotive bus. |
| **W8** | Cryptographic accelerator | No secure data in scope. ESP32-C3 can handle TLS if needed. |
| **W9** | Audio/speech | Out of scope for bin controller. |
| **W10** | Touch/display controller | LED status indicators sufficient. |

---

## Acceptance Criteria for MUST Features

| ID | Acceptance Criterion | Metric |
|----|---------------------|--------|
| M1 | PicoRV32 executes RV32IM instruction set correctly | Pass RISC-V compliance tests (rv32ui, rv32um) |
| M2 | Firmware fits in 512B SRAM with stack + data | Binary size ≤ 450B (12.5% margin) |
| M3 | I²C master reads all 3 sensors at 400 kHz | Successful register read with ACK from each device |
| M4 | Motor PWM generates correct PHASE/ENABLE on all 4 channels | Oscilloscope capture: 8-bit resolution, dead-time ≥ 1 µs |
| M5 | Ultrasonic capture measures distance 2-400 cm | Accuracy ±3 cm vs reference measurement |
| M6 | Weight threshold triggers interrupt when >30 kg | HX711 24-bit ADC read, threshold compare, interrupt flag |
| M7 | Solar monitor reads voltage (0-26V) and current (0-3.2A) | INA219 register read with valid conversion |
| M8 | RTC alarm wakes system at scheduled time | DS3231 alarm triggers interrupt, firmware reads time |
| M9 | UART transmits "IP-005 READY\r\n" at 115200 8N1 | Logic analyzer confirms baud rate ±2% |
| M10 | GPIO toggles LED and reads button state | Blink test: 1 Hz LED, button press detected |
| M11 | All 14 modules accessible via Wishbone B4 | Memory-mapped register read/write test for each module |
| M12 | Interrupt controller routes 8 sources to PicoRV32 | Each source triggers correct ISR vector |

---

## Technical Constraints Derived From Market Research

### Bus Protocol
- **Primary:** Wishbone B4 (shared bus) — proven in v4/v5, matches PicoRV32 native interface
- **Sensor bus:** I²C (400 kHz) — shared by HX711, INA219, DS3231
- **Debug/status:** UART (115200, 8N1) — to ESP32-C3
- **Alternative considered:** TileLink — rejected. Would require bridge IP (ip-008-wb-tl-bridge, 0.28 mm²). Wishbone is simpler and sufficient.

### Memory Requirements
- **SRAM:** 512B unified (Von Neumann). v4 firmware: ~400B code + ~80B data + stack.
- **No external memory bus.** All data lives in SRAM.
- **Boot ROM:** Not needed. Caravel management SoC loads firmware via Wishbone.

### I/O Requirements
- **Digital I/O:** ~40 pins (motor PWM ×8, ultrasonic trigger/echo ×8, I²C ×2, UART ×2, GPIO ×8, debug ×4, interrupts ×4, Wishbone ×4)
- **No analog I/O on ASIC.** HX711/INA219 are external I²C devices with built-in ADCs.
- **Caravel user area I/O:** 38 GPIO pads available — sufficient for ~40 pins with multiplexing.

### Clock Frequency
- **Target:** 33.3 MHz (30 ns period)
- **Rationale:** 3× margin below PicoRV32 proven 100 MHz on sky130A. Timing closure is not a concern. Lower frequency reduces power and simplifies STA.

### Power Budget
- **Digital core:** < 0.1 mW at 33.3 MHz (TT, 25°C, 1.8V)
- **I/O pads:** ~1-2 mW (shared with Caravel harness)
- **Total ASIC:** < 3 mW
- **System-level:** Motor drivers dominate at 5-10W. ASIC is negligible.

### Die Area Budget
- **Target:** < 3.0 mm² (29% of Caravel user area: 10.28 mm²)
- **v4 actual:** 1.17 mm² (26,798 cells, DRC 0, LVS match)
- **v6 estimate:** ~1.3 mm² nominal, 2.3× margin under target
- **Cell inflation:** 14.5× from RTL cells to placed cells (v4 calibration)

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| 512B SRAM overflow | Medium | High | Firmware size budget enforced. Regression test on every commit. |
| Motor PWM safety failure | Low | Critical | Hardware dead-time + firmware watchdog + external DRV8833 fault pin |
| I²C bus contention | Low | Medium | Single-master design. ESP32-C3 is I²C slave. |
| PD tool timeout | Medium | Medium | v4 took 3.5 hr. Allocate 4+ hr budget. Use S7 metric extraction. |
| Market adoption (SmartCan precedent) | Medium | Medium | v6 is silicon-proven — reduces product risk for partners |
| Caravel harness integration | Low | Low | v4/v5 both passed Caravel integration |
| Open-source toolchain breakage | Low | Medium | Pin tool versions. v4 flow is reproducible. |

---

## Handoff Notes for Spec Agent

1. All 12 MUST requirements carry forward from v4/v5 — they are silicon-proven.
2. S1 (watchdog) and S7 (STA metrics) are HIGH priority for v6.
3. Use v4-calibrated area estimates (14.5× inflation). Do NOT use gate-count models.
4. Target 33.3 MHz with 3× headroom. PPA is not the challenge — integration is.
5. 512B SRAM is the tightest constraint. Maintain firmware size discipline.
6. All I²C peripherals share one bus. Register map must avoid address conflicts.
7. Motor PWM must support DRV8833 PHASE/ENABLE mode with hardware dead-time.
8. v6 IP library has: watchdog (0.20 mm²), power-mgr (0.09 mm²), interrupt-ctrl (0.37 mm²), motor-pwm (0.61 mm²), ultrasonic-capture (1.72 mm²), weight-detect (0.15 mm²).
