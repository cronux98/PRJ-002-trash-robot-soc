# Weight Detect (HX711) — Research Note

**Date:** 2026-07-15
**Category:** peripheral
**Sources:** 2

## Priority Source: HX711 24-Bit ADC Datasheet (Avia Semiconductor)

- **Source:** https://cdn.sparkfun.com/datasheets/Sensors/ForceFlex/hx711_english.pdf

### Key Specifications
- **Resolution:** 24-bit ADC
- **Interface:** 2-wire (PD_SCK, DOUT) — not I²C
- **Data rate:** 10 SPS or 80 SPS (selectable)
- **Gain:** 64× or 128× (selectable)
- **Note on I²C:** HX711 uses its own 2-wire protocol, NOT I²C. The I²C master (HX711) in IP-005 is a misnomer from v4 — the weight sensor uses a dedicated HX711 controller, not generic I²C.

### For IP-005 v6
- **Interface:** Wishbone B4 slave
- **Address:** 0x9000
- **Signals:** hx711_sck_o (PD_SCK), hx711_dout_i (DOUT)
- **Function:** Threshold-based weight detection (not full 24-bit readout)
- **Registers:** CTRL (enable/gain/rate), THRESH (threshold value), STATUS (over_threshold/ready), INT_EN
- **Interrupt:** irq_o on threshold exceeded (ch 8, MED priority)

### Threshold Detection
```
1. HX711 conversion cycle → 24-bit data captured
2. Compare against THRESH register
3. If data > THRESH → STATUS.OVER = 1, irq_o asserted
4. Firmware reads STATUS to detect bin weight
```

### Edge Cases & Pitfalls
- **HX711 protocol:** Not standard I²C — clock pulses from master, data from slave on DOUT
- **Settling time:** After power-up or gain change, 4 conversion cycles before valid data
- **DRDY:** DOUT goes high when conversion in progress, low when data ready
- **Threshold hysteresis:** Single threshold → may oscillate at boundary. Consider dual-threshold (high/low) for production.

## Secondary Source: IP-005 v5 Weight Detect Module

- **V5 Cell Count:** 342 (RTL), ~500 (placed)
- **GDS Proven:** Yes

## Summary
HX711 weight sensor interface with threshold detection and interrupt. Dedicated 2-wire protocol (not I²C). v4/v5 proven.
