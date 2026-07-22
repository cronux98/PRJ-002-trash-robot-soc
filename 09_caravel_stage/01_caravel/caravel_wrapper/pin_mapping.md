# IP-005/v6 — trash_robot_soc Caravel Pin Mapping

**Generated:** 2026-07-15 | **Agent:** physical-design-agent (Hermes)
**Source:** `caravel_wrapper/verilog/rtl/user_project_wrapper.v`
**Design:** `trash_robot_soc` — Autonomous Trash Collection Robot Controller

> This document is DERIVED from the wrapper RTL. Every pin binding listed below
> exists in `user_project_wrapper.v`. No binding is asserted that isn't in the RTL.

---

## 1. Clock and Reset

| Caravel Port | Direction | Wrapper Signal | trash_robot_soc Port | Notes |
|---|---|---|---|---|
| `wb_clk_i` | input | → `soc_clk` | `clk_i` | Caravel management SoC clock (default 10MHz) |
| `wb_rst_i` | input (active-high) | → `soc_rst_n` (inverted) | `rst_ni` | SoC uses active-low reset; wrapper inverts |

**Reset inversion:**
```
Caravel wb_rst_i (active HIGH) → inverter → soc_rst_n (active LOW) → trash_robot_soc.rst_ni
```

---

## 2. GPIO Pads (38 total: GPIO 0-37)

| GPIO # | Caravel Role | Direction | trash_robot_soc Signal | Notes |
|---|---|---|---|---|
| **0** | Reserved — Housekeeping SPI CS | Hi-Z input | — | `io_oeb[0] = 1'b1` |
| **1** | Reserved — Housekeeping SPI SCLK | Hi-Z input | — | `io_oeb[1] = 1'b1` |
| **2** | Reserved — Housekeeping SPI MOSI | Hi-Z input | — | `io_oeb[2] = 1'b1` |
| **3** | Reserved — Housekeeping SPI MISO | Hi-Z input | — | `io_oeb[3] = 1'b1` |
| **4** | Reserved — Housekeeping flash CS | Hi-Z input | — | `io_oeb[4] = 1'b1` |
| **5** | User GPIO | Inout (output mode) | `i2c_scl` | I2C clock — always output mode, SoC handles tri-state |
| **6** | User GPIO | Inout (output mode) | `i2c_sda` | I2C data — always output mode, SoC handles tri-state |
| **7** | User GPIO | Input (Hi-Z) | `uart_rx` | UART receive from pad |
| **8** | User GPIO | Output | `uart_tx` | UART transmit to pad |
| **9** | User GPIO | Input (Hi-Z) | `echo[0]` | Sonar echo channel 0 |
| **10** | User GPIO | Input (Hi-Z) | `echo[1]` | Sonar echo channel 1 |
| **11** | User GPIO | Output | `trig[0]` | Sonar trigger channel 0 |
| **12** | User GPIO | Output | `trig[1]` | Sonar trigger channel 1 |
| **13** | User GPIO | Output | `motor_pwm_a[0]` | Motor PWM A channel 0 |
| **14** | User GPIO | Output | `motor_pwm_a[1]` | Motor PWM A channel 1 |
| **15** | User GPIO | Output | `motor_pwm_a[2]` | Motor PWM A channel 2 |
| **16** | User GPIO | Output | `motor_pwm_a[3]` | Motor PWM A channel 3 |
| **17** | User GPIO | Output | `motor_pwm_b[0]` | Motor PWM B channel 0 |
| **18** | User GPIO | Output | `motor_pwm_b[1]` | Motor PWM B channel 1 |
| **19** | User GPIO | Output | `motor_pwm_b[2]` | Motor PWM B channel 2 |
| **20** | User GPIO | Output | `motor_pwm_b[3]` | Motor PWM B channel 3 |
| **21–37** | User GPIO (17 pads) | Hi-Z input | — | All `io_oeb[n] = 1'b1`, `io_out[n] = 1'b0` |

**Tied-off SoC inputs (no GPIO pad):**
| Signal | Width | Tie-off | Reason |
|---|---|---|---|
| `gpio_i` | 12 | `12'd0` | SoC GPIO inputs unused — no external GPIO source |
| `motor_fault` | 4 | `4'd0` | No fault sensors connected |

---

## 3. Logic Analyzer (128-bit probe bus)

| LA Bit Range | Signal Exposed | Description |
|---|---|---|
| `la_data_out[1:0]` | `soc_trig[1:0]` | Sonar trigger outputs |
| `la_data_out[5:2]` | `soc_motor_pwm_a[3:0]` | Motor PWM A outputs |
| `la_data_out[9:6]` | `soc_motor_pwm_b[3:0]` | Motor PWM B outputs |
| `la_data_out[21:10]` | `soc_gpio_o[11:0]` | SoC GPIO output values |
| `la_data_out[33:22]` | `soc_gpio_oe[11:0]` | SoC GPIO output enables |
| `la_data_out[34]` | `soc_uart_tx` | UART TX line |
| `la_data_out[35]` | `soc_sys_rst_n` | System reset output from SoC |
| `la_data_out[36]` | `soc_wdt_rst_n` | Watchdog reset output from SoC |
| `la_data_out[127:37]` | `91'd0` | Tied off (unused) |

---

## 4. Interrupts (3 bits)

| Caravel Port | Direction | Wrapper Assignment | Notes |
|---|---|---|---|
| `user_irq[0]` | output | `1'b0` | No interrupt sources from trash_robot_soc |
| `user_irq[1]` | output | `1'b0` | No interrupt sources |
| `user_irq[2]` | output | `1'b0` | No interrupt sources |

---

## 5. Wishbone Bus — Bypassed

| Caravel Port | Direction | Wrapper Assignment | Notes |
|---|---|---|---|
| `wbs_ack_o` | output | `1'b1` | Always acknowledge (bypass) |
| `wbs_dat_o` | output | `32'd0` | No bus read data |
| `wbs_stb_i`, `wbs_cyc_i`, `wbs_we_i`, `wbs_sel_i`, `wbs_dat_i`, `wbs_adr_i` | inputs | ignored | Trash robot SoC has internal bus, not Wishbone |

---

## 6. Power Pins (8 total)

| Caravel Port | Type | Wrapper Connection |
|---|---|---|
| `vccd1` | Digital power 1.8V | Inout (connected to Caravel digital core supply) |
| `vssd1` | Digital ground | Inout |
| `vccd2` | Digital power 1.8V (aux) | Inout |
| `vssd2` | Digital ground (aux) | Inout |
| `vdda1` | Analog power 3.3V | Inout |
| `vssa1` | Analog ground | Inout |
| `vdda2` | Analog power 3.3V (aux) | Inout |
| `vssa2` | Analog ground (aux) | Inout |

---

## 7. Physical Summary

| Attribute | Value |
|---|---|
| Wrapper module | `user_project_wrapper` |
| Instantiated IP | `trash_robot_soc` (Trash Robot Controller) |
| User area | 891,778 µm² (0.89 mm²) |
| Caravel user area limit | 10,278,400 µm² (2.92 × 3.52 mm) |
| Area utilization | 8.68% of available user area |
| GPIO used | 16 / 33 (48.5%) |
| LA probes used | 37 / 128 (28.9%) |
| Interrupts used | 0 / 3 (0%) |
| GDS size | 75 MB |
| Cell count (post-P&R) | 160,800 |
| Std cells | 56,907 |

---

## 8. Unused Resources Summary

| Resource | Available | Used | Allocation |
|---|---|---|---|
| GPIO pads (user) | 33 (GPIO 5-37) | 16 | 48.5% — I2C(2), UART(2), Sonar(4), Motor PWM(8) |
| GPIO pads (reserved) | 5 (GPIO 0-4) | 0 | Caravel housekeeping — do not touch |
| Logic analyzer probes | 128 | 37 | 28.9% — motor PWM, GPIO states, UART, reset status |
| Interrupt lines | 3 | 0 | All tied low |
| Wishbone address space | 256 MB | 0 | Bypassed — SoC has internal APB bus |
| User area | 10.28 mm² | 0.89 mm² | 8.68% used |

---

## 9. Revision History

| Date | Version | Changes |
|---|---|---|
| 2026-07-15 | 1.0 | Initial pin mapping — derived from `user_project_wrapper.v` v1.0 for IP-005 v6 |
