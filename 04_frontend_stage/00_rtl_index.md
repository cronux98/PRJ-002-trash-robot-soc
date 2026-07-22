# Frontend RTL Modules — IP-005 v6a

**Project:** IP-005 v6a  
**Pipeline:** RTL → Lint → cocotb Sim → Formal → Synth → Equiv → GLS → Audit  
**Modules:** 16 (15 peripherals + 1 top-level SoC)  
**Ordering:** Bottom-up — peripherals first, CPU, interconnect, then top module last

---

## Module Index

| # | Module | Directory | Type | Bus | Status |
|---|--------|-----------|------|-----|--------|
| 1 | gpio | [01_rtl_gpio](01_rtl_gpio/) | REUSE | Wishbone | PENDING |
| 2 | i2c_ds3231 | [02_rtl_i2c_ds3231](02_rtl_i2c_ds3231/) | REUSE | Wishbone | PENDING |
| 3 | i2c_hx711 | [03_rtl_i2c_hx711](03_rtl_i2c_hx711/) | REUSE | Wishbone | PENDING |
| 4 | i2c_ina219 | [04_rtl_i2c_ina219](04_rtl_i2c_ina219/) | REUSE | Wishbone | PENDING |
| 5 | interrupt_ctrl | [05_rtl_interrupt_ctrl](05_rtl_interrupt_ctrl/) | REUSE | Wishbone | PENDING |
| 6 | motor_pwm | [06_rtl_motor_pwm](06_rtl_motor_pwm/) | REUSE | Wishbone | PENDING |
| 7 | picorv32_core | [07_rtl_picorv32_core](07_rtl_picorv32_core/) | REUSE (ext) | Wishbone | PENDING |
| 8 | power_mgr | [08_rtl_power_mgr](08_rtl_power_mgr/) | REUSE | Wishbone | PENDING |
| 9 | sram_512b | [09_rtl_sram_512b](09_rtl_sram_512b/) | REUSE | Wishbone | PENDING |
| 10 | timer | [10_rtl_timer](10_rtl_timer/) | REUSE | Wishbone | PENDING |
| 11 | uart | [11_rtl_uart](11_rtl_uart/) | REUSE | Wishbone | PENDING |
| 12 | ultrasonic_capture | [12_rtl_ultrasonic_capture](12_rtl_ultrasonic_capture/) | REUSE | Wishbone | PENDING |
| 13 | watchdog | [13_rtl_watchdog](13_rtl_watchdog/) | REUSE | Wishbone | PENDING |
| 14 | wb_interconnect | [14_rtl_wb_interconnect](14_rtl_wb_interconnect/) | REUSE | Wishbone | PENDING |
| 15 | weight_detect | [15_rtl_weight_detect](15_rtl_weight_detect/) | REUSE | Wishbone | PENDING |
| 16 | **trash_robot_soc** | [16_rtl_trash_robot_soc](16_rtl_trash_robot_soc/) | **TOP** | Wishbone | PENDING |

---

## Pipeline Summary

| Metric | Target | Actual |
|--------|--------|--------|
| Modules | 16 | — |
| Lint PASS | 16/16 | — |
| Formal BMC ≥ 20 | 16/16 | — |
| Synthesis PASS | 16/16 | — |
| Equivalence PASS | 16/16 | — |
| GLS match | 16/16 | — |

---

*Index last updated: 2026-07-16*
