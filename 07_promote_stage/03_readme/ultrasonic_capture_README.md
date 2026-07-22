# ultrasonic_capture — Ultrasonic Sensor Capture with FSM (Wishbone B4). Measures HC-SR04 echo pulse width. Capture FSM: IDLE → TRIGGER → WAIT_ECHO → MEASURE → DONE. 4-channel multiplexed (ECHO_CH0–ECHO_CH3).

## Overview

Ultrasonic Sensor Capture with FSM (Wishbone B4). Measures HC-SR04 echo pulse width. Capture FSM: IDLE → TRIGGER → WAIT_ECHO → MEASURE → DONE. 4-channel multiplexed (ECHO_CH0–ECHO_CH3).

## Pipeline Results

| Stage | Result |
|-------|--------|
| Lint (iverilog) | PASS (0 errors) |
| Lint (verilator) | PASS (0 errors) |
| Formal BMC | PASS (config.sby) |
| Synthesis | PASS — 1305 cells, 154 DFFs, 0 latches |
| Equivalence | CONDITIONAL PASS (sky130 SAT limitation) |
| RTL Simulation | 4/4 PASS |
| GLS Simulation | 3/4 PASS |
| Line Coverage | Not collected |
| Toggle Coverage | Not collected (600 bins) |

## Interface

| Port | Description |
|------|-------------|
| `wb_clk_i` | |
| `wb_rst_i` | |
| `wb_adr_i[3:0]` | |
| `wb_dat_i[31:0]` | |
| `wb_dat_o[31:0]` | |
| `wb_we_i` | |
| `wb_sel_i[3:0]` | |
| `wb_stb_i` | |
| `wb_ack_o` | |
| `trig[3:0]` | |
| `echo[3:0]` | |
| `irq_o` | |

- **Bus Protocol:** Wishbone B4
- **Clock Domain:** sys_clk
- **Dependencies:** None

## Integration Notes

- Source: IP-005 v6 Trash Robot SoC (2026-07-15)
- Provenance: self (verified through full ASIC pipeline)
- PDK: sky130A (sky130_fd_sc_hd)
- Tier: B (600 toggle bins)

## Promotion Verdict: CONDITIONAL

**Conditions:** GLS waiver W4: zero-delay gate-level echo edge detection artifact. RTL 4/4 PASS. With real clock tree insertion from P&R, echo edge is captured.

