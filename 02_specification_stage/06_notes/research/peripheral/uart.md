# UART Peripheral — Research Note

**Date:** 2026-07-15
**Category:** peripheral
**Sources:** 2

## Priority Source: OpenTitan UART (lowRISC)

- **Source:** https://github.com/lowRISC/opentitan
- **License:** Apache 2.0

### Key Specifications
- **Protocol:** UART 16550-compatible
- **Signals:** TX, RX (full-duplex)
- **Baud rate:** Programmable (ESP32-C3 default: 115200 baud)
- **Data format:** 8N1 (8 data bits, no parity, 1 stop bit)
- **FIFO:** Optional TX/RX FIFO (8-16 deep)
- **Interrupts:** TX empty, RX full, RX timeout, error

### For IP-005 v6
- **Interface:** Wishbone B4 slave
- **Address:** 0x2000 (4KB slot)
- **Registers:** TX_DATA, RX_DATA, STATUS (TX_BUSY/RX_READY), CTRL (baud/parity), BAUD_DIV
- **Baud generation:** System clock (33.3 MHz) / baud_div → 115200 baud
- **TX:** Data written to TX_DATA → shift register → serial output
- **RX:** Start bit detect → shift register → RX_DATA

### Edge Cases & Pitfalls
- **Baud rate accuracy:** 33.3 MHz / 115200 ≈ 289.06 → baud_div=289 gives 115186 baud (0.01% error, acceptable)
- **OpenTitan uses TL-UL bus:** v4/v5 used custom Wishbone-native UART wrapper
- **Framing error:** Detect wrong stop bit → STATUS.ERROR flag
- **Overrun:** RX data received before previous read → STATUS.OVERRUN flag
- **Half-duplex shared pin:** Not used — dedicated TX and RX lines

## Secondary Source: NS16550A Datasheet

- **Source:** National Semiconductor 16550A UART datasheet (archived)
- **Relevance:** Standard register model reference

### Register Model
| Offset | Register | Description |
|--------|----------|-------------|
| 0x00 | TX_DATA/RX_DATA | Write: transmit, Read: receive |
| 0x04 | STATUS | TX_BUSY, RX_READY, ERROR, OVERRUN |
| 0x08 | CTRL | Enable, parity, stop bits, baud select |
| 0x0C | BAUD_DIV | Clock divider for baud rate |

## Summary
UART is the ESP32-C3 telemetry link. 16550-compatible register model, Wishbone B4 slave, 115200 baud. Proven on v4/v5.
