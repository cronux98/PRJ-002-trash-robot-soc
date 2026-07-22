# sky130A PDK — Research Note

**Date:** 2026-07-15
**Category:** pdk
**Sources:** 2

## Priority Source: SkyWater SKY130 PDK Documentation

- **Source:** https://skywater-pdk.readthedocs.io/
- **License:** Apache 2.0

### Key Specifications
- **Technology:** 130nm CMOS (sky130A)
- **Metal:** 5 layers (li1, met1-met5)
- **Standard cells:** sky130_fd_sc_hd (high-density), 7.6 track height
- **Operating voltage:** 1.8V (core), 3.3V (IO)
- **Transistors:** 0.15 µm gate length
- **MiM capacitors:** Available (2 fF/µm²)
- **SRAM:** OpenRAM compiler available
- **PDK provides:** DRC/LVS rule decks, PEX, Liberty files, LEF

### IP-005 v6 Usage
- **Standard cells:** sky130_fd_sc_hd (HD library)
- **Core voltage:** 1.8V
- **IO voltage:** 3.3V (Caravel IO pad cells)
- **Utilization target:** 50-55% (conservative for routing)

### OpenROAD Flow
- **Synthesis:** Yosys + abc
- **Floorplan:** OpenROAD init_fp
- **Placement:** global + detailed (OpenROAD)
- **CTS:** TritonCTS (sky130 buffer cells)
- **Routing:** FastRoute (global) + TritonRoute (detailed)
- **STA:** OpenSTA
- **Extraction:** OpenROAD RCX

### Edge Cases & Pitfalls
- **Routing congestion:** sky130A 5-metal stack; 50-55% utilization target for routing safety
- **Antenna rules:** sky130A has strict antenna ratio rules. Fix with jumper cells or metal-area diode insertion.
- **DRC:** 0-violation target achievable with Yosys + OpenROAD (v5 proven)
- **LVS:** Match verification — v5 passes with Calibre equivalent rules
- **PDK version:** Must pin to specific sky130A release for reproducibility

## Secondary Source: IP-005 v5 GDS Results

- **GDS Area:** 1.17 mm²
- **Placed Cells:** 26,798
- **DRC:** 0 violations
- **LVS:** Match
- **PD Runtime:** 3.5 hours

## Summary
sky130A HD cell library, 5-metal stack, 1.8V core. Open-source OpenROAD flow. v5 GDS proven at 1.17 mm², DRC 0, LVS match.
