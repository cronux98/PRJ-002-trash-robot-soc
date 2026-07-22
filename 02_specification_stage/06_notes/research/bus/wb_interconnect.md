# Wishbone Interconnect — Research Note

**Date:** 2026-07-15
**Category:** bus
**Sources:** 1

## Priority Source: Wishbone B4 Shared Bus Architecture

- **Source:** Wishbone B4 specification
- **Derived:** IP-005 v5 wb_interconnect module

### Key Specifications
- **Topology:** Shared bus, 1 master → 14 slaves
- **Address decode:** Combinational — wb_adr[15:12] routed to slave select
- **Data mux:** 14:1 mux on read data (wb_dat_i from selected slave)
- **Acknowledge:** OR of all slave ACK signals (only selected slave responds)
- **Error:** OR of all slave ERR signals
- **Latency:** 0-cycle decode (combinational), 1-cycle access (registered response)

### Slave Select Decode
```verilog
case (wb_adr[15:12])
    4'h0: slave_sel = 0;  // sram_512b
    4'h2: slave_sel = 1;  // uart
    4'h3: slave_sel = 2;  // reserved (spi)
    4'h4: slave_sel = 3;  // i2c_hx711
    4'h5: slave_sel = 4;  // gpio
    4'h6: slave_sel = 5;  // timer
    4'h7: slave_sel = 6;  // motor_pwm
    4'h8: slave_sel = 7;  // ultrasonic_capture
    4'h9: slave_sel = 8;  // weight_detect
    4'hA: slave_sel = 9;  // i2c_ina219
    4'hB: slave_sel = 10; // i2c_ds3231
    4'hC: slave_sel = 11; // interrupt_ctrl
    4'hD: slave_sel = 12; // watchdog
    4'hE: slave_sel = 13; // power_mgr
    default: slave_sel = 14; // no slave → err
endcase
```

### Edge Cases & Pitfalls
- **Unselected slave response:** All unselected slaves must drive wb_dat_o = 0, wb_ack_o = 0
- **Default slave:** Unmapped addresses → wb_err_o = 1, wb_ack_o = 0
- **Combinational decode timing:** wb_adr → slave_sel is purely combinational. Must meet timing at 33.3 MHz (30 ns period — trivial for simple decode)
- **Single-cycle back-to-back:** Classic mode requires CYC/STB deassertion between transfers. No pipelining.

## V5 Heritage
- **Cell Count:** 314 (RTL)
- **GDS Proven:** Yes

## Summary
Combinational-address-decode Wishbone B4 shared bus. 1 master → 14 slaves. 314 cells. v5 proven.
