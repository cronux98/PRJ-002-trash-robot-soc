# SRAM 512B Memory — Research Note

**Date:** 2026-07-15
**Category:** memory
**Sources:** 2

## Priority Source: OpenRAM (sky130 SRAM Generator)

- **Source:** https://github.com/VLSIDA/OpenRAM
- **PDK:** sky130A

### Key Findings
- **Technology:** sky130 SRAM — 130nm CMOS
- **Configuration:** 128 words × 32 bits = 512B
- **Option A — OpenRAM macro:** Generated SRAM bitcell array. Lower area, requires PDK-specific memory compiler.
- **Option B — FF-based:** Synthesized register file. Higher area (~7,430 FF cells), easier tool flow.
- **V5 used:** FF-based SRAM (simpler, proven)

### For IP-005 v6
- **512B unified Von Neumann** — code + data share address space
- **Wishbone B4 slave interface** — 9-bit address (word-aligned), 32-bit data
- **Byte-enable:** sel[3:0] for byte/halfword/word
- **Single-cycle read/write** — classic mode Wishbone
- **Boot:** `$readmemh("firmware.hex", mem)` in simulation; Caravel QSPI pathway in hardware

### Edge Cases & Pitfalls
- **Von Neumann bottleneck:** Code + data share 512B. v4/v5 firmware proven fit with ~10-15% headroom.
- **Byte-enable complexity:** FF-based byte-enable logic multiplies cell count ~4× vs word-only. Accept for 512B.
- **Read-during-write:** Return old value (classic register file behavior).
- **Simulation boot:** Use `ifdef SIMULATION` + `$readmemh` — hardcoded ROM = synthesis bloat.

## Secondary Source: IP-005 v5 sram_512b Module

- **Source:** IP-005 v5 02_architecture_stage
- **GDS Proven:** 26,798 placed cells, DRC 0, LVS match

### Layout
```
Address Range        | Usage
0x0000 - 0x007F     | .text (firmware code)     ~64 words (256B)
0x0080 - 0x009F     | Interrupt vector table     ~8 words (32B)
0x00A0 - 0x00BF     | .rodata                    ~8 words (32B)
0x00C0 - 0x00FF     | Stack (grows down)         ~16 words (64B)
0x0100 - 0x017F     | BSS / heap / scratch       ~32 words (128B)
```

## Summary
512B FF-based SRAM is proven on sky130A. OpenRAM macro optional but not required for v6 — FF-based gives predictable synthesis and area.
