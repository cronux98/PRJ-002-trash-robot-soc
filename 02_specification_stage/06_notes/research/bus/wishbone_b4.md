# Wishbone B4 Bus Protocol — Research Note

**Date:** 2026-07-15
**Category:** bus
**Sources:** 2

## Priority Spec: Wishbone B4 Specification (OpenCores)

- **Source:** https://opencores.org/howto/wishbone
- **License:** Public domain specification

### Key Specifications
- **Classic mode:** Single-cycle transfer (no pipelining, no burst)
- **Signals:** cyc, stb, we, adr, dat_i, dat_o, sel, ack, err
- **Data width:** 32-bit (standard)
- **Address width:** 16-bit (64KB addressable)
- **Byte select:** sel[3:0] for byte/halfword/word access
- **Little-endian**
- **Wishbone B4** adds: err signal, improved handshake

### Topology for IP-005
- **Shared bus** with combinational address decode
- **1 master** (PicoRV32 via wishbone wrapper)
- **14 slaves** — shared bus sufficient, no crossbar needed
- **Address decode:** wb_adr[15:12] selects slave port

### Timing (Classic Mode)
```
CLK:  ──┐     ┌──┐     ┌──┐     ┌──  (33.3 MHz)
CYC:   ────┐               ┌────   (master asserts)
STB:        ────┐       ┌──       (strobe follows cyc)
ACK:            ────┐ ┌──         (slave responds)
DATA:  <valid on ACK assertion>
```

### Edge Cases & Pitfalls
- **No burst support** in classic mode — sequential reads require separate CYC/STB per access
- **ACK latency** should be 1 cycle for simple slaves (SRAM, GPIO)
- **ERR signal** should be asserted for unimplemented addresses
- **sel[3:0]** for byte-level writes: all 4 bits = word, 1 bit = byte
- **wbm_err_o** routing: unclaimed addresses → err response, not silent fail

## Secondary Source: PicoRV32 Wishbone Wrapper (picorv32_wb)

- **Source:** https://github.com/YosysHQ/picorv32 (picorv32_wb module)

### Key Details
- Converts PicoRV32 native memory interface to Wishbone B4 master
- `mem_valid → wb_cyc + wb_stb`
- `mem_ready ← wb_ack`
- Address pass-through (16-bit)
- Data width: 32-bit

## Summary
Wishbone B4 classic mode is the simplest open-standard bus. Single-cycle, single-master, shared topology — ideal for IP-005's size constraints.
