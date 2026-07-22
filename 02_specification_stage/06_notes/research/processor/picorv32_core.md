# PicoRV32 Processor Core — Research Note

**Date:** 2026-07-15
**Category:** processor
**Sources:** 3

## Priority Source: PicoRV32 (YosysHQ / Claire Wolf)

- **Repository:** https://github.com/YosysHQ/picorv32
- **License:** ISC (permissive, equivalent to MIT/BSD)
- **Version:** Latest stable (verified IP-005 v4/v5 GDS)

### Key Findings
- **ISA:** RV32IM (Base Integer + Multiply/Divide)
- **Pipeline:** 2-3 stage (configurable: ENABLE_REGS_DUALPORT for 3-stage)
- **Config flags:** ENABLE_MUL=1, ENABLE_DIV=1, ENABLE_IRQ=1, ENABLE_REGS_DUALPORT=1
- **Area:** ~3,200 cells on sky130 at 100 MHz (Yosys synthesis)
- **Bus interface:** Native memory interface wrapped to Wishbone B4 (picorv32_wb)
- **IRQ:** Single-wire with software vector read
- **No caches, no MMU, no branch prediction** — pure bare-metal microcontroller core
- **CoreMark:** ~0.5 CoreMark/MHz (size-optimized configuration)

### Edge Cases & Pitfalls
- **Memory latency:** PicoRV32 expects single-cycle memory access. Multi-cycle slaves need `mem_ready` handshake.
- **IRQ handling:** Interrupts disabled during multi-cycle instructions (MUL/DIV). Keep ISR latency < ~10 cycles.
- **Reset vector:** Hardcoded to 0x00000000. Must map SRAM to this address.
- **`$readmemh` boot:** Use `ifdef SIMULATION` + `$readmemh` pattern for firmware loading. Hardcoded boot ROM = real gates → synthesis bloat.

### V5 Heritage
- GDS-proven at 33.3 MHz on sky130A
- Wishbone B4 wrapper verified (picorv32_wb)
- 16-bit address bus, 32-bit data bus

---

## Secondary Source: RISC-V ISA Specification v2.2

- **Source:** https://riscv.org/technical/specifications/
- **Relevance:** RV32IM instruction set reference

### Key Specifications
- 40 base integer instructions (RV32I)
- 8 multiply/divide instructions (RV32M)
- Machine-mode CSRs (mstatus, mtvec, mepc, mcause, mie, mip)
- 32 general-purpose registers (x0-x31)
- Little-endian byte ordering

---

## Tertiary Source: Spike RISC-V ISA Simulator

- **Source:** https://github.com/riscv-software-src/riscv-isa-sim
- **Use:** Golden ISA reference traces for verification

## Summary
PicoRV32 is the ideal core for IP-005: small (3,200 cells), RV32IM, ISC licensed, GDS-proven on sky130A. Its minimal pipeline fits the 512B SRAM constraint and 33.3 MHz target.
