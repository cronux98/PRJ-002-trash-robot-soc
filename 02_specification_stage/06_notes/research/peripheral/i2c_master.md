# I²C Master Peripheral — Research Note

**Date:** 2026-07-15
**Category:** peripheral
**Sources:** 3

## Priority Source: NXP I²C Bus Specification v6.0

- **Source:** https://www.nxp.com/docs/en/user-guide/UM10204.pdf
- **Standard:** I²C-bus specification, Rev. 6, 2014

### Key Specifications
- **Modes:** Standard (100 kHz), Fast (400 kHz)
- **Signals:** SCL (clock), SDA (data) — open-drain, pull-up required
- **Addressing:** 7-bit device address + 1-bit R/W
- **Transactions:** START → ADDR+R/W → ACK → DATA → ACK → ... → STOP
- **Multi-master:** Arbitration supported (not used in IP-005)
- **Clock stretching:** Slave can hold SCL low to slow master

### For IP-005 v6
- **3 identical instantiations** with different base addresses:
  - **i2c_master_hx711** (0x4000) — HX711 weight sensor
  - **i2c_master_ina219** (0xA000) — INA219 solar monitor
  - **i2c_master_ds3231** (0xB000) — DS3231 hardware RTC
- **Shared I²C bus:** All 3 share SCL/SDA lines (time-division multiplexed)
- **Wishbone B4 slave interface**
- **Registers:** DATA (tx/rx), CTRL (start/stop/enable/speed), STATUS (busy/ack/error), ADDR (7-bit slave addr)

### Timing (Fast Mode — 400 kHz)
- **Bit period:** 2.5 µs
- **From 33.3 MHz:** prescaler = 83 → ~401 kHz (0.25% accuracy)

### Edge Cases & Pitfalls
- **Shared bus arbitration:** Only one master active at a time. Firmware ensures serialization.
- **Clock stretching:** Must handle slave stretching SCL — timeout required (~10ms).
- **NACK handling:** Slave NACKs address → STATUS.ERR, firmware retries.
- **SDA hold time:** 300 ns minimum — easily met at 33.3 MHz (30 ns period).
- **Pull-up resistors:** External (not on-chip) — Caravel PCB.

## Secondary Source: OpenCores I²C Master Controller

- **Source:** https://opencores.org/projects/i2c
- **Relevance:** Reference Wishbone-attached I²C implementation

## Tertiary Source: HX711, INA219, DS3231 Datasheets

- **HX711:** 24-bit ADC, I²C address 0x72 (typical)
- **INA219:** Current/power monitor, I²C address 0x40-0x4F (configurable)
- **DS3231:** RTC + temperature, I²C address 0x68

## Summary
I²C master ×3 for weight, solar, and RTC. Standard mode I²C with Wishbone B4 interface. Shared SCL/SDA bus. v4/v5 proven.
