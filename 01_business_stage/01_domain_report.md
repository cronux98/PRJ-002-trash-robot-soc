# Domain Report — IP-005 v6 Trash Robot ASIC

**Date:** 2026-07-15
**Analyst:** business-analyst (Stage 0)
**Prior iterations:** v4 (GDS-proven), v5 (refined)

---

## Domain Overview

IP-005 targets the **autonomous refuse collection** domain — specifically, a
motorized wheelie bin controller ASIC that enables a standard residential trash
bin to autonomously navigate to the curb on collection day and return. The
domain sits at the intersection of consumer robotics, smart home IoT, and
embedded motor control.

The target end-user is a homeowner who replaces their existing wheelie bin
handle/axle assembly with a motorized unit containing this ASIC. The device
must operate on battery + solar, schedule collections autonomously via RTC,
navigate using ultrasonic sensors, and communicate status via WiFi (ESP32-C3
co-processor). Safety requires weight-overload detection to prevent the bin
from attempting to move when too heavy.

This is v6 of the same design — v4 completed the full ASIC pipeline through
physical design (1.17 mm² GDS, DRC 0, LVS match) and v5 refined the
architecture. v6 continues the iterative improvement cycle.

---

## Key Technical Challenges

- **Power-constrained autonomous navigation:** The system must operate from
  battery + solar with multi-day autonomy. Motor drivers dominate power (5-10W
  peak) but the ASIC controller must be negligible (< 50 mW).
- **Multi-sensor fusion on a resource-constrained SoC:** Ultrasonic distance
  (×2-4), weight strain gauge (HX711 interface), solar charge monitoring
  (INA219 interface), and RTC scheduling (DS3231 interface) must coexist on a
  shared I²C bus with deterministic firmware timing.
- **Motor PWM safety:** DRV8833 dual H-bridge requires precise PHASE/ENABLE
  PWM with dead-time control. Failure modes (overload, stall) must be detected
  and handled without software intervention where possible.
- **512B SRAM discipline:** Von Neumann unified memory for both code and data
  is extremely tight. v4 firmware fit but any feature addition risks overflow.
  This constraint forces minimalist firmware — both a strength (efficiency)
  and a weakness (vs 32KB MCU competitors).
- **Open-source toolchain reliability:** The entire flow (Yosys/OpenROAD/
  OpenSTA/Magic/Netgen) must produce DRC-clean, LVS-matching GDS. v4 proved
  this works. v6 must maintain or improve.

---

## Relevant Standards and Protocols

| Standard | Role | Notes |
|----------|------|-------|
| RISC-V RV32IM | CPU ISA | PicoRV32 core, ISC license |
| I²C (400 kHz) | Sensor bus | HX711, INA219, DS3231 peripherals |
| Wishbone B4 | On-chip bus | 14-peripheral interconnect (v5-proven) |
| PWM (PHASE/ENABLE) | Motor control | DRV8833-compatible output |
| UART 115200 | Debug/status | External ESP32-C3 link |
| sky130A PDK | Process | Open-source 130nm, Efabless MPW |
| Caravel harness | MPW platform | Apache 2.0, chipIgnite shuttle |

---

## Domain-Specific Metrics That Matter

### For Trash Robot Controllers:
- **Autonomous runtime per charge:** Target 24+ hours with solar top-up
- **Navigation accuracy:** ±15 cm obstacle detection at walking speed (0.3 m/s)
- **Weight safety threshold:** 30 kg max load detection
- **PWM resolution:** ≥ 8-bit for smooth motor ramping
- **Wake-up latency:** < 100 ms from RTC alarm to motor-ready
- **Firmware size:** Must fit in 512B unified SRAM (Von Neumann)
- **BOM cost target:** < $15 for the controller subsystem (ASIC + ESP32 + sensors)

### For ASIC in sky130A:
- **Die area:** < 3.0 mm² (Caravel user area: 10.28 mm², ~29% budget)
- **Clock frequency:** 33.3 MHz (3× margin below PicoRV32 proven 100 MHz)
- **Digital core power:** < 0.1 mW (negligible vs system motor loads)
- **DRC violations:** 0
- **LVS:** Match

---

## Industry Trends (2026)

1. **Consumer waste robotics is heating up.** Oshkosh HARR-E won CES 2025
   award, signaling corporate interest. SmartCan's failure (2019-2025, never
   shipped) proves demand without execution — an opportunity.

2. **RISC-V adoption in embedded ASICs accelerating.** ESP32-C3 brought RISC-V
   to millions of units. Open-source PDK (sky130) and toolchains (OpenROAD)
   have matured enough for production-quality tapeouts.

3. **Solar + RTC + sensor fusion is a differentiated combo.** No consumer
   trash robot integrates all three on a single controller. Existing solutions
   are either enterprise-only (HARR-E, $5000+) or DIY hobbyist (ESP32 rover,
   no product path).

4. **Smart trash bin market growing at 9.8-28.6% CAGR** depending on segment
   definition. Even the conservative estimate ($2.5B → $5.7B by 2033) supports
   a viable niche. The trash robots sub-market ($0.75B → $3.46B at 18.5% CAGR,
   DataIntelo 2025) directly validates the autonomous refuse collection category.

5. **Open-source silicon is entering a new phase.** chipIgnite at $9,750 per
   shuttle makes custom ASICs accessible. Multiple projects (OpenTitan, SERV,
   PicoRV32) have proven sky130A viability. IP-005's dual tapeout (v4+v5)
   demonstrates the open-source ASIC model works for application-specific SoCs.

---

## v6 Position vs Prior Iterations

| Aspect | v4 | v5 | v6 |
|--------|-----|-----|-----|
| Silicon validation | First GDS (1.17mm²) | Refined, not re-taped | Builds on v4+v5 |
| DRC/LVS | 0 violations, Match | Inherited from v4 | Maintain |
| Perimeter count | 15 modules | 14 peripherals | TBD (v6 additions) |
| IP library promotion | N/A | 9 modules promoted | More to promote |
| Metric extraction | Gap (no WNS) | Gap addressed (S7) | Automate STA metrics |
| Watchdog timer | None | Library available | S1 priority |
| Confidence | Speculative | v4-calibrated | Dual-tapeout proven |

---

## References

1. SkyQuest — Smart Trash Bin Market Report (March 2025): $4.89B (2024) → $47.01B (2033), 28.6% CAGR
2. Verified Market Reports — Smart Trash Bin Market (May 2026): $2.5B (2024) → $5.7B (2033), 9.8% CAGR
3. Maximize Market Research — Trash Robots Market (May 2026): $2.6B (2025) → $6.19B (2032), 13.2% CAGR
4. DataIntelo — Trash Robots (Trashbots) Market Report 2034: $0.75B (2025) → $3.46B (2034), 18.5% CAGR
5. Oshkosh HARR-E CES 2025 Award: https://www.oshkoshcorp.com/news/2025/01-09-25-oshkosh-wins-ces-picks-award
6. Efabless chipIgnite: $9,750 per shuttle (https://www.embedded.com/efabless-chipignite-enables-soc-for-9750-in-skywater-cmos-node/)
7. SiliconCompiler PicoRV32 sky130 tutorial: https://docs.siliconcompiler.com/en/v0.30.0/user_guide/tutorials/picorv32_ram.html
