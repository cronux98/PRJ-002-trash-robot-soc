# SoC System — Research Note

**Date:** 2026-07-15
**Category:** system
**Sources:** 2

## Priority Source: Caravel Harness (Efabless)

- **Source:** https://github.com/efabless/caravel_user_project
- **License:** Apache 2.0

### Key Specifications
- **User area:** 3000 µm × 3600 µm = 10.8 mm²
- **IO pads:** 38 GPIO pads available
- **Management core:** Caravel harness provides management SoC (clock, reset, GPIO muxing)
- **Power:** 1.8V core, 3.3V IO
- **Boot:** QSPI flash → Caravel loads firmware → user project enabled
- **Clock:** External oscillator via Caravel → 33.3 MHz to user project

### IP-005 Pin Mapping (Caravel GPIO)
| IP-005 Signal | Caravel GPIO | Direction |
|---------------|-------------|-----------|
| uart_tx_o | gpio[0] | output |
| uart_rx_i | gpio[1] | input |
| i2c_scl_io | gpio[2] | inout |
| i2c_sda_io | gpio[3] | inout |
| gpio_io[15:0] | gpio[4:19] | inout |
| pwm_a_o[3:0] | gpio[20:23] | output |
| pwm_b_o[3:0] | gpio[24:27] | output |
| fault_i[3:0] | gpio[28:31] | input |
| trig_o[1:0] | gpio[32:33] | output |
| echo_i[1:0] | gpio[34:35] | input |

### Clock & Reset Flow
```
External OSC → Caravel harness → user_clock2 (33.3 MHz) → IP-005 clk_i
Caravel power-on reset → user_reset_n → IP-005 rst_ni
```

### Edge Cases & Pitfalls
- **Caravel GPIO config:** Must set management SoC registers to route user GPIO correctly
- **Pin direction:** Caravel GPIO pads are bidirectional — configure direction in user project
- **QSPI boot:** Caravel loads firmware from QSPI flash before enabling user project
- **Area constraint:** User area 10.8 mm² total; IP-005 targets < 3.0 mm² (~28% utilization)

## Secondary Source: IP-005 v5 Full GDS

- ***Proven:** GDS at 1.17 mm² within Caravel user area
- **Integration:** Caravel wrapper verified LVS match

## Summary
Caravel harness provides clock, reset, GPIO routing, and QSPI boot. IP-005 occupies ~28% of user area. v5 GDS integration proven.
