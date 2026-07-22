# ARCHITECTURE.md — Trash Robot SoC IP-005 v6

**Version:** v6
**Author:** architect-engineer (Hermes)
**Date:** 2026-07-15
**Status:** Draft
**V5 Baseline:** GDS-proven at 1.17 mm², DRC 0, LVS match, 26,798 placed cells
**Project Type:** SoC (all §1-§9 apply)

---

## §1. Overview

### 1.1 Description

Single-chip ASIC controller for an autonomous motorized wheelie bin rover. Integrates a PicoRV32 RV32IM RISC-V core with 14 Wishbone B4 slave peripherals across a shared 16-bit address bus. Fabricated on sky130A (SkyWater 130nm CMOS) via the Efabless Caravel chipIgnite MPW harness. All 16 modules carry forward from the v5 GDS-proven baseline — v6 is a full-pipeline re-execution with Python golden models and thesis-grade design documentation.

### 1.2 Block Diagram

See `block_diagrams/top_level.html` for interactive dark-theme block diagram.

Architecture: PicoRV32 (WB master) → wb_interconnect (1:14 decode, adr[15:12]) → 1× SRAM + 12× peripherals + 1× power_mgr. Shared I²C bus (single scl_io/sda_io pair) for 3× i2c_master instances. Single clock domain, no CDC needed.

### 1.3 Key Specifications

| Spec | Value |
|------|-------|
| ISA | RV32IM (PicoRV32, ISC license) |
| Pipeline | 2-3 stage (size-optimized config) |
| Clock | 33.3 MHz (single domain) |
| Process | sky130A (SkyWater 130nm CMOS) |
| Standard Cells | sky130_fd_sc_hd |
| SRAM | 512B unified Von Neumann (128×32) |
| Address Width | 16-bit (Wishbone B4) |
| Data Width | 32-bit |
| Bus Protocol | Wishbone B4 classic mode |
| Masters | 1 (PicoRV32) |
| Slaves | 14 |
| Reset | Active-low, async assert, sync deassert |
| Power States | ACTIVE / SLEEP / WAKE (power_mgr) |
| Package | Caravel harness (10.8 mm² user area) |
| Die Area Target | < 3.0 mm² |
| V5 Actual Die Area | 1.17 mm² |
| V6 Est. Die Area | ~1.3 mm² |
| Reuse Ratio | 16/16 = 100% design heritage |
| Research Index | 16 notes, 30+ sources, 0 GAPs |
| Reference | research_index.md (§1-§16) |

---

## §2. Memory Map

### 2.1 Complete Address Map

Address decode: `wbm_adr_i[15:12]` → 4-bit one-hot → 16 possible slots (14 populated, 2 reserved).

| Slot | adr[15:12] | Module | Base | End | Size | Notes |
|------|-----------|--------|------|-----|------|-------|
| 0x0 | 0000 | sram_512b | 0x0000 | 0x0FFF | 4KB (512B used) | Unified code+data |
| 0x1 | 0001 | — | 0x1000 | 0x1FFF | 4KB | Reserved (SRAM expansion) |
| 0x2 | 0010 | uart | 0x2000 | 0x2FFF | 4KB (16B regs) | ESP32-C3 telemetry |
| 0x3 | 0011 | — | 0x3000 | 0x3FFF | 4KB | SPI slot (reserved, unpopulated) |
| 0x4 | 0100 | i2c_hx711 | 0x4000 | 0x4FFF | 4KB (16B regs) | HX711 weight sensor |
| 0x5 | 0101 | gpio | 0x5000 | 0x5FFF | 4KB (16B regs) | 16-bit I/O + interrupts |
| 0x6 | 0110 | timer | 0x6000 | 0x6FFF | 4KB (16B regs) | 32-bit timer + 4-ch aux PWM |
| 0x7 | 0111 | motor_pwm | 0x7000 | 0x7FFF | 4KB (16B regs) | DRV8833 PHASE/ENABLE ×4 |
| 0x8 | 1000 | ultrasonic_capture | 0x8000 | 0x8FFF | 4KB (16B regs) | HC-SR04 ×2 echo capture |
| 0x9 | 1001 | weight_detect | 0x9000 | 0x9FFF | 4KB (16B regs) | Threshold detect + intr |
| 0xA | 1010 | i2c_ina219 | 0xA000 | 0xAFFF | 4KB (16B regs) | Solar current/voltage |
| 0xB | 1011 | i2c_ds3231 | 0xB000 | 0xBFFF | 4KB (16B regs) | Hardware RTC |
| 0xC | 1100 | interrupt_ctrl | 0xC000 | 0xCFFF | 4KB (16B regs) | 16-ch priority encoder |
| 0xD | 1101 | watchdog | 0xD000 | 0xDFFF | 4KB (16B regs) | Dual-stage, magic-key reload |
| 0xE | 1110 | power_mgr | 0xE000 | 0xEFFF | 4KB (16B regs) | Clock gating + sleep FSM |
| 0xF | 1111 | — | 0xF000 | 0xFFFF | 4KB | Reserved |

### 2.2 Boot Vector

PC = 0x0000_0000. Firmware loaded via `$readmemh` from `firmware.hex` through Caravel QSPI boot pathway.

### 2.3 SRAM Layout (512B = 128 × 32-bit words)

| Range | Words | Usage |
|-------|-------|-------|
| 0x0000-0x007F | 64 (256B) | .text (firmware code) |
| 0x0080-0x009F | 8 (32B) | Interrupt vector table |
| 0x00A0-0x00BF | 8 (32B) | .rodata |
| 0x00C0-0x00FF | 16 (64B) | Stack (grows down) |
| 0x0100-0x01FF | 32 (128B) | BSS / heap / scratch |

### 2.4 Alignment Rules

- All peripheral base addresses are 4KB-aligned (adr[11:0] = 0).
- Byte, halfword, and word accesses supported via wb_sel_i[3:0].
- Unaligned accesses: handled by PicoRV32 trap (misaligned exception), not by interconnect.

---

## §3. Pipeline

### 3.1 PicoRV32 Pipeline Overview

The PicoRV32 in the default size-optimized configuration implements a 2-3 stage microarchitecture:

- **IF (Instruction Fetch):** Fetches 32-bit instruction from Wishbone bus at PC. Increments PC by 4 (or branch target). Compressed instruction support (RVC) decodes 16-bit ops to 32-bit internally.
- **ID/EX (Decode + Execute):** Decodes instruction, reads register file (2R1W), performs ALU operation, resolves branches. Multiply/divide (M extension) uses iterative shift-add / shift-subtract state machine spanning multiple cycles.
- **WB (Writeback, overlapped):** Register file writeback in the cycle following EX completion. No separate MEM stage — loads stall ID until Wishbone ACK returns data.

**Effective CPI:** ~3-4 for typical code mix (RV32IM + RVC).

### 3.2 Key Internal State

PicoRV32 is a microcoded core — it does not expose named pipeline registers. Key internal state:

| State Element | Width | Description |
|--------------|-------|-------------|
| `reg_pc` | 32 | Program counter |
| `reg_next_pc` | 32 | Next PC (PC+4 or branch target) |
| `reg_op1` / `reg_op2` | 32 | ALU operands |
| `reg_out` | 32 | ALU / load result |
| `reg_shifter` | varies | MUL/DIV iterative state |

### 3.3 Hazard Resolution

- **Data hazards:** All loads stall the core until Wishbone ACK returns. No forwarding — PicoRV32 waits for register file write before reading result.
- **Control hazards:** Branches resolved in ID/EX. 2-cycle mispredict penalty for taken branches.
- **Structural hazards:** Single Wishbone master — no bus contention internal to the core. SRAM contention (IF vs load/store) resolved by serialized WB cycles.

### 3.4 Stall/Flush

- **Stall:** WB cycle not acknowledged → core holds state until ACK.
- **Flush:** Branch mispredict → PC redirected, partially-executed instruction discarded.
- **Interrupt:** IRQ asserted → current instruction completes, PC → trap handler (MTVEC).

---

## §4. Modules

### 4.1 picorv32_core

#### 4.1.1 Purpose
32-bit RISC-V RV32IM processor core (YosysHQ / Claire Wolf). Executes firmware from unified SRAM, controls all peripherals via Wishbone B4 master interface. ISC-licensed external IP. [Research: processor/picorv32_core.md §1]

#### 4.1.2 Interface Table
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk_i | Input | 1 | 33.3 MHz system clock |
| rst_ni | Input | 1 | Active-low async reset |
| wbm_cyc_o | Output | 1 | Wishbone cycle |
| wbm_stb_o | Output | 1 | Wishbone strobe |
| wbm_we_o | Output | 1 | Write enable |
| wbm_adr_o | Output | 16 | Byte address |
| wbm_dat_o | Output | 32 | Write data |
| wbm_sel_o | Output | 4 | Byte select |
| wbm_dat_i | Input | 32 | Read data |
| wbm_ack_i | Input | 1 | Transfer acknowledge |
| wbm_err_i | Input | 1 | Error indicator |
| irq_i | Input | 1 | External interrupt request |
| irq_ack_o | Output | 1 | Interrupt acknowledge |
| irq_id_i | Input | 5 | Interrupt ID (from INTC) |

#### 4.1.3 Functional Description
PicoRV32 configured with `ENABLE_MUL=1`, `ENABLE_DIV=1`, `ENABLE_IRQ=1`. Machine-mode only — no supervisor/user mode. Interrupts trigger trap to MTVEC; firmware reads INTC VECTOR register to identify source. Standard RISC-V privilege spec machine-mode CSRs (MSTATUS, MTVEC, MEPC, MCAUSE, MIE, MIP).

#### 4.1.4 Timing Notes
- Latency: 1 cycle per instruction (average ~3-4 CPI)
- Clock domain: sys_clk (33.3 MHz)
- Critical path: Register file read → ALU → result mux (combinational)

#### 4.1.5 Edge Cases
- **Reset:** PC = 0x0000_0000, all CSRs = reset value per RISC-V spec. MSTATUS.MIE = 0 (interrupts disabled at boot).
- **IRQ timing:** irq_i sampled at instruction boundaries. If asserted mid-multi-cycle (MUL/DIV), processed after current operation completes.
- **Bus error:** wbm_err_i assertion triggers load/store access fault exception (MCAUSE=5/7).

#### 4.1.6 Area / Timing Budget
| Metric | Estimate |
|--------|----------|
| Expected cell count | ~3,200 (synthesis) |
| Expected FF count | ~800 |
| Critical path | ~15 ns |
| Source | v5 GDS-proven, YosysHQ PicoRV32 benchmarks |

---

### 4.2 sram_512b

#### 4.2.1 Purpose
512-byte unified Von Neumann memory (128 × 32-bit words). Stores firmware code, interrupt vectors, read-only data, stack, and BSS. Single-cycle Wishbone B4 access. [Research: memory/sram_512b.md]

#### 4.2.2 Interface Table
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk_i | Input | 1 | System clock |
| rst_ni | Input | 1 | Active-low reset |
| wb_adr_i | Input | 9 | Byte address (word-aligned, adr[8:0]) |
| wb_dat_i | Input | 32 | Write data |
| wb_dat_o | Output | 32 | Read data |
| wb_sel_i | Input | 4 | Byte select |
| wb_we_i | Input | 1 | Write enable |
| wb_stb_i | Input | 1 | Strobe |
| wb_cyc_i | Input | 1 | Cycle |
| wb_ack_o | Output | 1 | Acknowledge (registered, 1-cycle) |

#### 4.2.3 Functional Description
FF-based register file (not OpenRAM macro — 512B too small for macro efficiency). 128 × 32-bit DFF array with byte-level write enables. Read is combinational (addr → data in same cycle); write is registered (data captured on posedge when wb_we_i and wb_stb_i). ACK driven combinatorially from wb_stb_i (single-cycle response).

#### 4.2.4 Timing Notes
- Latency: 1 cycle (ACK in same cycle as STB+CYC)
- Clock domain: sys_clk
- Combinational depth: 128:1 mux (~5 LUT levels) + read path

#### 4.2.5 Edge Cases
- **Simultaneous read+write:** Not possible — single WB port. Read and write are mutually exclusive (wb_we_i gates).
- **Unaligned access:** wb_sel_i[3:0] handles byte/halfword granularity.
- **Reset:** Memory contents UNDEFINED at reset (no reset on data array — saves area). Firmware loaded at boot via $readmemh.
- **Out-of-range address:** addr[8:2] selects word (0-127). addr[8] asserted → address > 0x1FF → ACK asserted but data=0x00000000.

#### 4.2.6 Area / Timing Budget
| Metric | Estimate |
|--------|----------|
| Expected cell count | ~7,430 (FF-based) |
| Expected FF count | 4,096 (128 × 32) |
| Critical path | ~5 ns |
| Source | IP-005 v1-v5 design heritage |

---

### 4.3 wb_interconnect

#### 4.3.1 Purpose
Wishbone B4 shared bus interconnect: 1 master (PicoRV32) → 14 slaves. Combinational address decode on wbm_adr_i[15:12] with registered read-data mux (BUG-004 fix from v3). [Research: bus/wishbone_b4.md, bus/wb_interconnect.md]

#### 4.3.2 Interface Table
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk_i | Input | 1 | System clock |
| rst_ni | Input | 1 | Active-low reset |
| wbm_cyc_i | Input | 1 | Master cycle |
| wbm_stb_i | Input | 1 | Master strobe |
| wbm_we_i | Input | 1 | Master write enable |
| wbm_adr_i | Input | 16 | Master address |
| wbm_dat_i | Input | 32 | Master write data |
| wbm_sel_i | Input | 4 | Master byte select |
| wbm_dat_o | Output | 32 | Read data to master |
| wbm_ack_o | Output | 1 | Acknowledge to master |
| wbm_err_o | Output | 1 | Error to master |
| wbs_cyc_o[13:0] | Output | 14 | Per-slave cycle |
| wbs_stb_o[13:0] | Output | 14 | Per-slave strobe |
| wbs_we_o[13:0] | Output | 14 | Per-slave write enable |
| wbs_adr_o[13:0][15:0] | Output | 14×16 | Per-slave address |
| wbs_dat_o[13:0][31:0] | Output | 14×32 | Per-slave write data |
| wbs_sel_o[13:0][3:0] | Output | 14×4 | Per-slave byte select |
| wbs_dat_i[13:0][31:0] | Input | 14×32 | Per-slave read data |
| wbs_ack_i[13:0] | Input | 14 | Per-slave acknowledge |

#### 4.3.3 Functional Description

**Address Decode (combinational):**
`wbm_adr_i[15:12]` → 4-to-14 one-hot decode. Slave index mapping:
- 0: sram_512b          (adr[15:12]=0000)
- 1: uart               (adr[15:12]=0010)
- 2: i2c_hx711          (adr[15:12]=0100)
- 3: gpio               (adr[15:12]=0101)
- 4: timer              (adr[15:12]=0110)
- 5: motor_pwm          (adr[15:12]=0111)
- 6: ultrasonic_capture (adr[15:12]=1000)
- 7: weight_detect      (adr[15:12]=1001)
- 8: i2c_ina219         (adr[15:12]=1010)
- 9: i2c_ds3231         (adr[15:12]=1011)
- 10: interrupt_ctrl    (adr[15:12]=1100)
- 11: watchdog          (adr[15:12]=1101)
- 12: power_mgr         (adr[15:12]=1110)
- 13: unused (reserved, ack=0, data=0)

**Read Data Mux (registered — BUG-004 fix):**
Combinational 14:1 mux selects `wbs_dat_i[sel][31:0]` based on which slave's ACK is active. Output registered into `rd_data_q` on posedge clk_i, then driven as `wbm_dat_o`. This prevents read-data glitches from propagating to the PicoRV32 during slave transitions.

**ACK/ERR aggregation:**
`wbm_ack_o = |(wbs_ack_i[13:0] & wbs_cyc_o[13:0])` — OR of all active slave ACKs.
`wbm_err_o = 1'b0` — no error detection in classic mode.

#### 4.3.4 Timing Notes
- Latency: 0 cycles decode + 1 cycle slave access + 1 cycle read-data register = 2 cycles total read latency
- Clock domain: sys_clk
- Critical path: adr[15:12] → decode → slave select → selected slave's ACK path

#### 4.3.5 Edge Cases
- **Unmapped address:** Slots 0x1 and 0xF return ack=0, data=0. PicoRV32 will hang waiting for ACK (no timeout) — firmware must never access unmapped regions.
- **Multiple ACK:** Decode is one-hot — only one slave strobed at a time. Multiple simultaneous ACKs impossible by construction.
- **Back-to-back reads to different slaves:** Read-data register guarantees clean data on slave transitions. Previous value held until new slave's ACK latches fresh data.

#### 4.3.6 Area / Timing Budget
| Metric | Estimate |
|--------|----------|
| Expected cell count | 314 (v5 synthesis) |
| Expected FF count | 64 |
| Critical path | ~8 ns |
| Source | IP-005 v3, BUG-004 fix |

---

### 4.4 uart

#### 4.4.1 Purpose
16550-compatible UART for ESP32-C3 WiFi telemetry. 115200 baud from 33.3 MHz clock (baud_div=289). Supports TX and RX with status/interrupt reporting. [Research: peripheral/uart.md]

#### 4.4.2 Interface Table
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk_i | Input | 1 | System clock |
| rst_ni | Input | 1 | Active-low reset |
| wb_* | — | — | Wishbone B4 slave (standard) |
| uart_tx_o | Output | 1 | Transmit serial output |
| uart_rx_i | Input | 1 | Receive serial input |
| intr_o | Output | 1 | Interrupt (TX done or RX ready) |

#### 4.4.3 Functional Description

**Registers (at base 0x2000):**

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | TX_DATA | R/W | 0x00 | Write: load TX shift reg; Read: returns last written |
| 0x04 | RX_DATA | R | 0x00 | Read: returns RX shift reg, clears RX_READY |
| 0x08 | STATUS | R | 0x01 | bit0=RX_READY, bit1=TX_BUSY, bit2=RX_ERROR |
| 0x0C | CTRL | R/W | 0x03 | bit0=TX_EN, bit1=RX_EN |
| 0x10 | BAUD_DIV | R/W | 289 | Baud rate divisor (33.3MHz / 115200 ≈ 289) |

**Baud generation:** 33.3 MHz / baud_div. Default 289 → ~115225 baud (0.02% error).

**TX:** Write TX_DATA → starts shift-out at configured baud rate. STATUS.TX_BUSY=1 while shifting. Completes after 10 bit-times (start + 8 data + stop). TX_BUSY auto-clears.

**RX:** Monitors uart_rx_i for start bit (falling edge). Samples at mid-bit using baud counter. 8 data bits captured → STATUS.RX_READY=1, intr_o=1.

#### 4.4.4 Timing Notes
- Latency: Register access = 1 WB cycle; TX completion = ~87 µs (10 bits at 115200)
- Clock domain: sys_clk
- Critical path: baud counter → compare (combinational)

#### 4.4.5 Edge Cases
- **W1C:** STATUS register is read-only; RX_READY clears on read of RX_DATA, not on STATUS read.
- **Read-clear:** Reading RX_DATA clears RX_READY bit in STATUS. TX_BUSY clears automatically.
- **Reset:** All registers = 0x00 except CTRL=0x03 (TX_EN=1, RX_EN=1) and BAUD_DIV=289.
- **TX_BUSY during write:** If TX_DATA written while TX_BUSY=1, data is ignored (no double-buffer). Firmware must poll STATUS before writing.
- **Baud divisor 0:** Treated as divisor=1 (33.3 Mbps — not physically usable). Minimum recommended divisor = 2.

#### 4.4.6 Area / Timing Budget
| Metric | Estimate |
|--------|----------|
| Expected cell count | ~800 (synthesis) |
| Expected FF count | ~200 |
| Critical path | ~10 ns |
| Source | IP-005 v5 |

---

### 4.5 i2c_master (×3 instances: hx711, ina219, ds3231)

#### 4.5.1 Purpose
I²C master controller for sensor interfacing. Three identical instantiations at different base addresses: HX711 weight sensor (0x4000), INA219 solar monitor (0xA000), DS3231 RTC (0xB000). Shared I²C bus (single scl_io/sda_io pair) — arbitration handled externally by firmware scheduling. [Research: peripheral/i2c_master.md]

#### 4.5.2 Interface Table
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk_i | Input | 1 | System clock |
| rst_ni | Input | 1 | Active-low reset |
| wb_* | — | — | Wishbone B4 slave (standard) |
| i2c_scl_io | Inout | 1 | I²C clock (shared bus) |
| i2c_sda_io | Inout | 1 | I²C data (shared bus) |
| intr_o | Output | 1 | Transfer complete interrupt |

#### 4.5.3 Functional Description

**Registers (per instance):**

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | DATA | R/W | 0x00 | TX/RX data byte |
| 0x04 | CTRL | R/W | 0x00 | bit0=START, bit1=STOP, bit2=RD (1=read, 0=write), bit3=ACK |
| 0x08 | STATUS | R | 0x00 | bit0=BUSY, bit1=ACK_ERR, bit2=ARB_LOST |
| 0x0C | PRESCALE | R/W | 41 | Clock prescaler (33.3MHz / (4×41) ≈ 200 kHz) |

**Protocol:** START → ADDR+R/W → ACK → DATA ×N → STOP.
Standard mode (100 kHz) and fast mode (400 kHz) via prescaler.

#### 4.5.4 Timing Notes
- Latency: 1 byte transfer = 9 SCL cycles (~45 µs at 200 kHz)
- Clock domain: sys_clk
- Prescaler: 33.3 MHz / (4 × prescale) = SCL frequency

#### 4.5.5 Edge Cases
- **W1C:** CTRL.START and CTRL.STOP are auto-clear after one cycle.
- **Read-clear:** STATUS.ACK_ERR cleared on next START.
- **Reset:** All registers = 0x00. PRESCALE must be programmed before first transfer.
- **Bus arbitration:** Multiple masters not supported. Only one i2c_master instance should be active at a time. Firmware controls access sequencing.
- **SCL stretching:** Slave can hold SCL low — master waits indefinitely (no timeout in v6).

#### 4.5.6 Area / Timing Budget (per instance)
| Metric | Estimate |
|--------|----------|
| Expected cell count | ~285 (synthesis) |
| Expected FF count | ~80 |
| Critical path | ~12 ns |
| Source | IP-005 v5 (×3 = 855 cells total) |

---

### 4.6 gpio

#### 4.6.1 Purpose
16-bit general-purpose digital I/O with 5 interrupt-capable channels. Interfaces to bump sensors (front/rear), user button, RGB LED, and reserved pins. Per-pin direction control and interrupt configuration. [Research: peripheral/gpio.md]

#### 4.6.2 Interface Table
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk_i | Input | 1 | System clock |
| rst_ni | Input | 1 | Active-low reset |
| wb_* | — | — | Wishbone B4 slave (standard) |
| gpio_io | Inout | 16 | GPIO pads |
| intr_o[4:0] | Output | 5 | Interrupt outputs |

#### 4.6.3 Functional Description

**Registers (at base 0x5000):**

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | DIR | R/W | 0x0000 | 1=output, 0=input (per pin) |
| 0x04 | OUT | R/W | 0x0000 | Output value (when DIR=1) |
| 0x08 | IN | R | — | Input value (reads pads directly) |
| 0x0C | INTE | R/W | 0x0000 | Interrupt enable (per pin, bits[4:0]) |
| 0x10 | INTTYPE | R/W | 0x0000 | 0=level, 1=edge (per interrupt pin) |
| 0x14 | INTPOL | R/W | 0x0000 | 0=active-low/falling, 1=active-high/rising |
| 0x18 | INTSTAT | R/W1C | 0x00 | Interrupt status (bits[4:0]). W1C. |

#### 4.6.4 Timing Notes
- Latency: 1 WB cycle register access; 1 cycle input sampling
- Clock domain: sys_clk

#### 4.6.5 Edge Cases
- **W1C:** INTSTAT register bits[4:0] are W1C. Write 1 to clear; write 0 has no effect. W1C takes priority over set.
- **Reset:** DIR=0x0000 (all inputs), OUT=0x0000, interrupts disabled.
- **Input synchronization:** gpio_io inputs registered through 2-stage synchronizer before IN register.
- **Interrupt generation:** intr_o asserted when (INTSTAT & INTE) ≠ 0. Level-sensitive based on INTTYPE/INTPOL config.

#### 4.6.6 Area / Timing Budget
| Metric | Estimate |
|--------|----------|
| Expected cell count | 554 (v5 synthesis) |
| Expected FF count | ~120 |
| Critical path | ~6 ns |
| Source | IP-005 v5 |

---

### 4.7 timer

#### 4.7.1 Purpose
32-bit system timer with 4-channel auxiliary PWM. Generates periodic interrupts on compare match (channel 0) and PWM outputs (channels 1-4). Core system tick for firmware scheduling. [Research: peripheral/timer.md]

#### 4.7.2 Interface Table
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk_i | Input | 1 | System clock |
| rst_ni | Input | 1 | Active-low reset |
| wb_* | — | — | Wishbone B4 slave (standard) |
| intr_o | Output | 1 | Compare match interrupt |
| pwm_o[3:0] | Output | 4 | Auxiliary PWM outputs |

#### 4.7.3 Functional Description

**Registers (at base 0x6000):**

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | COUNT | R/W | 0x00000000 | Current count value (wraps at 0xFFFFFFFF) |
| 0x04 | COMPARE | R/W | 0xFFFFFFFF | Compare threshold for interrupt / PWM period |
| 0x08 | CTRL | R/W | 0x00000001 | bit0=EN, bit1=AUTO_RESTART, bits[7:4]=PWM_EN[3:0] |
| 0x0C | PWM_DUTY[0] | R/W | 0x00000000 | PWM channel 0 duty (bits[31:0]) |
| 0x10 | PWM_DUTY[1] | R/W | 0x00000000 | PWM channel 1 duty |
| 0x14 | PWM_DUTY[2] | R/W | 0x00000000 | PWM channel 2 duty |
| 0x18 | PWM_DUTY[3] | R/W | 0x00000000 | PWM channel 3 duty |

#### 4.7.4 Timing Notes
- Latency: 1 WB cycle for register access
- Clock domain: sys_clk (33.3 MHz, 30 ns period)
- PWM resolution: 30 ns steps (33.3 MHz granularity)

#### 4.7.5 Edge Cases
- **W1C:** STATUS register W1C for interrupt flag.
- **Read-clear:** Reading STATUS clears interrupt flag.
- **Reset:** COUNT=0, COMPARE=0xFFFFFFFF, CTRL=0x01 (EN=1), PWM disabled.
- **Counter wrap:** COUNT increments every cycle when EN=1. Wraps from 0xFFFFFFFF to 0x00000000. Interrupt fires on COUNT == COMPARE.
- **PWM duty > COMPARE:** Output stays high. PWM duty is full 32-bit (not 8-bit). Register width = 32-bit, PWM uses bits [7:0] for 8-bit resolution.

#### 4.7.6 Area / Timing Budget
| Metric | Estimate |
|--------|----------|
| Expected cell count | 1,373 (v5 synthesis) |
| Expected FF count | ~300 |
| Critical path | ~10 ns |
| Source | IP-005 v5 |

---

### 4.8 motor_pwm

#### 4.8.1 Purpose
4-channel DC motor PWM controller for DRV8833 H-bridge driver. PHASE/ENABLE mode: PHASE_A/PHASE_B + ENABLE per channel. Each channel independent 8-bit duty cycle at 25 kHz carrier. Fault input monitoring with interrupt. [Research: peripheral/motor_pwm.md]

#### 4.8.2 Interface Table
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk_i | Input | 1 | System clock |
| rst_ni | Input | 1 | Active-low reset |
| wb_* | — | — | Wishbone B4 slave (standard) |
| pwm_a_o[3:0] | Output | 4 | Phase A outputs (4 channels) |
| pwm_b_o[3:0] | Output | 4 | Phase B outputs (4 channels) |
| fault_i[3:0] | Input | 4 | DRV8833 fault inputs |
| intr_o | Output | 1 | Fault interrupt |

#### 4.8.3 Functional Description

**Registers (at base 0x7000):**

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | DUTY_CH0 | R/W | 0x00000000 | Ch0: bits[7:0]=duty, bit[8]=DIR, bit[9]=EN |
| 0x04 | DUTY_CH1 | R/W | 0x00000000 | Ch1 duty/dir/enable |
| 0x08 | DUTY_CH2 | R/W | 0x00000000 | Ch2 duty/dir/enable |
| 0x0C | DUTY_CH3 | R/W | 0x00000000 | Ch3 duty/dir/enable |
| 0x10 | CTRL | R/W | 0x00000000 | bit[0]=GLOBAL_EN, bit[1]=FAULT_CLEAR (W1C) |
| 0x14 | STATUS | R | 0x00 | bit[3:0]=FAULT_FLAGS, bit[7]=ANY_FAULT |

**PWM generation:** 25 kHz carrier from 33.3 MHz (divider = 1332). PHASE mode: DIR=0 → pwm_a=EN, pwm_b=0 (forward). DIR=1 → pwm_a=0, pwm_b=EN (reverse). ENABLE=0 → both low (coast).

#### 4.8.4 Timing Notes
- PWM carrier: 25 kHz (40 µs period)
- Clock domain: sys_clk
- PWM resolution: 8-bit (256 steps per carrier period)

#### 4.8.5 Edge Cases
- **W1C:** CTRL.FAULT_CLEAR is W1C. Writing 1 clears all FAULT_FLAGS. Suppress re-trigger for 1 cycle.
- **Reset:** All DUTY registers = 0x00000000, CTRL=0x00 (global disable), motors stopped.
- **Fault handling:** fault_i asserted → STATUS.FAULT_FLAGS latched, intr_o asserted. PWM outputs frozen (held at last state). Firmware must clear fault via FAULT_CLEAR.
- **Duty register width:** 32-bit register, PWM uses bits [7:0] only. Upper bits ignored.
- **Dead-time:** 0-cycle dead time (PHASE_A and PHASE_B toggle simultaneously). DRV8833 handles shoot-through protection.

#### 4.8.6 Area / Timing Budget
| Metric | Estimate |
|--------|----------|
| Expected cell count | 470 (v5 synthesis) |
| Expected FF count | ~150 |
| Critical path | ~8 ns |
| Source | IP-005 v5 |

---

### 4.9 ultrasonic_capture

#### 4.9.1 Purpose
Dual-channel HC-SR04 ultrasonic sensor interface. Generates 10 µs trigger pulses, captures echo pulse width using 20-bit counter at 1 MHz. Supports range calculation: distance(cm) = echo_width(µs) / 58. [Research: peripheral/ultrasonic_capture.md]

#### 4.9.2 Interface Table
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk_i | Input | 1 | System clock |
| rst_ni | Input | 1 | Active-low reset |
| wb_* | — | — | Wishbone B4 slave (standard) |
| trig_o[1:0] | Output | 2 | Trigger pulses |
| echo_i[1:0] | Input | 2 | Echo inputs |
| intr_o | Output | 1 | Capture complete interrupt |

#### 4.9.3 Functional Description

**Registers (at base 0x8000):**

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | TRIG | R/W | 0x00 | Write any value → triggers measurement (both ch) |
| 0x04 | ECHO_CH0 | R | 0x00000 | 20-bit echo width in µs (ch0) |
| 0x08 | ECHO_CH1 | R | 0x00000 | 20-bit echo width in µs (ch1) |
| 0x0C | STATUS | R | 0x00 | bit[0]=CH0_DONE, bit[1]=CH1_DONE, bit[2]=TIMEOUT |
| 0x10 | CTRL | R/W | 0x00 | bit[0]=EN, bit[1]=CONTINUOUS |

**Timing:** 10 µs trigger pulse → echo goes high → 1 MHz counter increments while echo=1 → counter captured when echo falls. Timeout at ~38 ms (max range ~6.5m).

#### 4.9.4 Timing Notes
- Trigger pulse: 10 µs (334 cycles at 33.3 MHz)
- Echo counter: 1 MHz (div-by-33 from 33.3 MHz)
- Max range: ~6.5m at 20°C (38 ms timeout)
- Clock domain: sys_clk

#### 4.9.5 Edge Cases
- **Read-clear:** STATUS register read-clear — reading STATUS clears DONE flags.
- **Reset:** All registers = 0x00000000. Module idle, triggers inactive.
- **Timeout:** If echo_i never returns (no obstacle within range, or faulty sensor), ECHO register = 0xFFFFF (saturated), STATUS.TIMEOUT=1.
- **Overlapping triggers:** If TRIG written while measurement in progress, old measurement is aborted, new trigger sequence starts.
- **Echo counter saturation:** 20-bit at 1 MHz = 1.048s max. Saturated at 0xFFFFF on timeout.

#### 4.9.6 Area / Timing Budget
| Metric | Estimate |
|--------|----------|
| Expected cell count | 1,314 (v5 synthesis) |
| Expected FF count | ~250 |
| Critical path | ~12 ns |
| Source | IP-005 v5 |

---

### 4.10 weight_detect

#### 4.10.1 Purpose
HX711 load cell threshold detector. Monitors weight sensor data against a configurable threshold. Generates interrupt when weight exceeds limit (safety interlock for bin overfill prevention). [Research: peripheral/weight_detect.md]

#### 4.10.2 Interface Table
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk_i | Input | 1 | System clock |
| rst_ni | Input | 1 | Active-low reset |
| wb_* | — | — | Wishbone B4 slave (standard) |
| intr_o | Output | 1 | Threshold exceeded interrupt |

#### 4.10.3 Functional Description

**Registers (at base 0x9000):**

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | THRESHOLD | R/W | 0x00FFFFFF | Weight threshold (24-bit, HX711 raw value) |
| 0x04 | CURRENT | R | 0x00000000 | Current weight reading (from HX711 via I²C bridge) |
| 0x08 | STATUS | R | 0x00 | bit0=ABOVE_THRESH, bit1=SENSOR_OK |
| 0x0C | CTRL | R/W | 0x00 | bit0=EN |

#### 4.10.4 Timing Notes
- Latency: 1 WB cycle for register access
- Clock domain: sys_clk

#### 4.10.5 Edge Cases
- **Read-clear:** STATUS reads latched state; does NOT auto-clear.
- **Reset:** THRESHOLD=0x00FFFFFF (max), CURRENT=0, STATUS=0x02 (SENSOR_OK), CTRL=0.
- **Hysteresis:** None in v6. ABOVE_THRESH asserted when CURRENT > THRESHOLD, deasserted when CURRENT ≤ THRESHOLD.
- **Sensor disconnect:** If firmware detects no HX711 data for > 1 second, should clear SENSOR_OK via CTRL.

#### 4.10.6 Area / Timing Budget
| Metric | Estimate |
|--------|----------|
| Expected cell count | 342 (v5 synthesis) |
| Expected FF count | ~80 |
| Critical path | ~5 ns |
| Source | IP-005 v5 |

---

### 4.11 watchdog

#### 4.11.1 Purpose
Dual-stage watchdog timer: Stage 1 — warning interrupt at programmable timeout. Stage 2 — system reset if not reloaded. Magic-key reload prevents accidental refresh by runaway code. OR-ed into top-level reset tree. [Research: governance/watchdog.md]

#### 4.11.2 Interface Table
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk_i | Input | 1 | System clock |
| rst_ni | Input | 1 | Active-low reset |
| wb_* | — | — | Wishbone B4 slave (standard) |
| intr_o | Output | 1 | Warning interrupt |
| wdt_rst_o | Output | 1 | System reset output |

#### 4.11.3 Functional Description

**Registers (at base 0xD000):**

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | TIMEOUT | R/W | 0x00FFFFFF | Timeout in clock cycles (default ~25ms at 33.3MHz) |
| 0x04 | CTRL | R/W | 0x00 | bit0=EN, bit1=WARN_EN |
| 0x08 | KEY | W | — | Magic-key reload (write 0xACCE5515 to reload) |
| 0x0C | STATUS | R | 0x00 | bit0=WARNED, bit1=RESET_ISSUED |

**Sequence:** EN=1 → counter increments to TIMEOUT/2 → WARN interrupt → to TIMEOUT → wdt_rst_o asserted (pulse, 16 cycles). KEY write reloads counter to 0 (magic value 0xACCE5515). Any other value: ignored.

#### 4.11.4 Timing Notes
- Counter: 32-bit, increments at sys_clk rate
- Reset pulse width: 16 clock cycles (~480 ns)
- Clock domain: sys_clk

#### 4.11.5 Edge Cases
- **Magic key:** Only 0xACCE5515 reloads. All other writes to KEY are silently ignored. This prevents accidental reload by runaway code.
- **Reset:** TIMEOUT = 0x00FFFFFF (~25 ms), CTRL=0x00 (disabled at boot — firmware must enable).
- **W1C:** None. STATUS is read-only, clears on KEY reload.
- **Double reset:** After wdt_rst_o asserted, counter resets to 0, WARN/RESET flags cleared. Module resumes counting from 0.
- **Stuck reload:** If firmware reloads every cycle, counter never reaches threshold. This is correct — WDT is a software liveness monitor.

#### 4.11.6 Area / Timing Budget
| Metric | Estimate |
|--------|----------|
| Expected cell count | 444 (v5 synthesis) |
| Expected FF count | ~100 |
| Critical path | ~6 ns |
| Source | IP-005 v5 |

---

### 4.12 interrupt_ctrl

#### 4.12.1 Purpose
16-channel fixed-priority interrupt controller. Latches interrupt requests, applies per-channel mask, generates single-wire IRQ to PicoRV32. Firmware reads VECTOR register to identify interrupt source. Up-counting priority: Channel 0 highest → Channel 15 lowest. [Research: governance/interrupt_ctrl.md]

#### 4.12.2 Interface Table
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk_i | Input | 1 | System clock |
| rst_ni | Input | 1 | Active-low reset |
| wb_* | — | — | Wishbone B4 slave (standard) |
| irq_in_i[15:0] | Input | 16 | Interrupt requests from peripherals |
| irq_out_o | Output | 1 | Interrupt output to PicoRV32 |
| irq_id_o | Output | 5 | Interrupt ID (channel number) |

#### 4.12.3 Functional Description

**Registers (at base 0xC000):**

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | ENABLE | R/W | 0x0000 | Per-channel mask (1=enabled) |
| 0x04 | PENDING | R | 0x0000 | Latched pending interrupts |
| 0x08 | STATUS | R | 0x0000 | bit[15:0] = irq_in_i raw (pre-mask) |
| 0x0C | VECTOR | R | 0x00 | Highest priority pending channel ID |

**Priority:** Fixed up-counting. Channel 0 (highest) → Channel 15 (lowest). VECTOR returns lowest-numbered pending channel.

**Interrupt Routing Map:**

| Ch | Source | Priority | Description |
|----|--------|----------|-------------|
| 0 | timer | HIGH | Timer overflow |
| 1 | uart | HIGH | UART RX ready |
| 2 | uart | MED | UART TX done |
| 3 | gpio[0] | HIGH | Bump sensor front |
| 4 | gpio[1] | HIGH | Bump sensor rear |
| 5 | gpio[2] | MED | User button |
| 6 | motor_pwm | MED | DRV8833 fault |
| 7 | ultrasonic_capture | MED | Echo capture done |
| 8 | weight_detect | MED | Weight threshold exceeded |
| 9 | i2c_hx711 | LOW | I²C transfer done |
| 10 | i2c_ina219 | LOW | I²C transfer done |
| 11 | i2c_ds3231 | LOW | I²C transfer done |
| 12 | watchdog | HIGH | Watchdog warning |
| 13 | power_mgr | LOW | Sleep/wake status change |
| 14 | gpio[3] | LOW | Reserved |
| 15 | — | — | Reserved |

#### 4.12.4 Timing Notes
- Latency: 1 cycle to latch irq_in_i, 1 cycle for priority encode = 2 cycles to irq_out_o
- Clock domain: sys_clk

#### 4.12.5 Edge Cases
- **Pending latching:** PENDING bits are latched until acknowledged. Firmware clears pending by writing 0 to the peripheral's interrupt source register.
- **Reset:** ENABLE=0x0000 (all masked), PENDING=0x0000, VECTOR=0x00.
- **Disabled channel:** If ENABLE[n]=0, irq_in_i[n] is ignored. PENDING[n] stays 0.
- **Simultaneous interrupts:** Lowest-numbered channel wins (fixed priority, up-counting).
- **Re-assertion while pending:** If a peripheral re-asserts while its PENDING bit is already set, no change (edge not lost — level-sensitive latched design).

#### 4.12.6 Area / Timing Budget
| Metric | Estimate |
|--------|----------|
| Expected cell count | 280 (v5 synthesis) |
| Expected FF count | ~80 |
| Critical path | ~5 ns |
| Source | IP-005 v5 |

---

### 4.13 power_mgr

#### 4.13.1 Purpose
Module-level clock gating and sleep/wake power management. Controls clock enables for 14 peripherals (PicoRV32 always-on). Implements ACTIVE/SLEEP/WAKE FSM. Responds to core sleep request (WFI), RTC alarm, and button press. [Research: governance/power_mgr.md]

#### 4.13.2 Interface Table
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk_i | Input | 1 | System clock |
| rst_ni | Input | 1 | Active-low reset |
| wb_* | — | — | Wishbone B4 slave (standard) |
| clk_en_o[13:0] | Output | 14 | Per-module clock enables |
| core_sleep_i | Input | 1 | Sleep request from PicoRV32 (WFI) |
| wake_rtc_i | Input | 1 | Wake from RTC alarm |
| wake_button_i | Input | 1 | Wake from user button |
| intr_o | Output | 1 | Sleep/wake status interrupt |

#### 4.13.3 Functional Description

**Registers (at base 0xE000):**

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | CTRL | R/W | 0x3FFF | Per-module clock enable mask (bits[13:0]) |
| 0x04 | SLEEP | R/W | 0x00 | Write 1 to enter sleep (auto-clears on wake) |
| 0x08 | WAKE_SRC | R | 0x00 | Wake source: bit0=RTC, bit1=BUTTON, bit2=CORE |
| 0x0C | STATUS | R | 0x01 | bit0=ACTIVE, bit1=SLEEPING |

**FSM:**
```
ACTIVE → (core_sleep_i & SLEEP=1) → SLEEP (all clk_en_o = 0)
SLEEP → (wake_rtc_i | wake_button_i) → WAKE (clk_en_o restored) → ACTIVE
```

#### 4.13.4 Timing Notes
- Clock gating: AND-gate on clock tree per module
- Sleep entry latency: 1 cycle from core_sleep_i to clk_en_o deasserted
- Wake latency: 2 cycles (synchronizer) + 1 cycle for clock restore
- Clock domain: sys_clk

#### 4.13.5 Edge Cases
- **Reset:** CTRL=0x3FFF (all modules enabled), SLEEP=0, STATUS=ACTIVE.
- **PicoRV32 always-on:** PicoRV32 clock is never gated. Only peripherals can be gated.
- **WFI race:** If wake event arrives between WFI execution and clock gate, wake takes precedence. WAKE_SRC captures source.
- **Power sequencing:** No power sequencing in v6 — all modules share same VDD. Clock gating only, not power island switching.
- **Stuck sleep:** If both wake sources absent and core_sleep_i stuck high, system stays in SLEEP indefinitely. Watchdog (if enabled separately) can recover via reset.

#### 4.13.6 Area / Timing Budget
| Metric | Estimate |
|--------|----------|
| Expected cell count | 193 (v5 synthesis) |
| Expected FF count | ~50 |
| Critical path | ~4 ns |
| Source | IP-005 v5 |

---

## §5. Reset & Clock Strategy

### 5.1 Reset Type
- **Type:** Active-low asynchronous assert, synchronous deassert
- **Polarity:** Active low (`rst_ni`)
- **Assertion:** Any module can be asynchronously reset (rst_ni = 0 forces all FFs to reset value)
- **Deassertion:** 2-stage synchronizer ensures all modules exit reset on the same clock edge

### 5.2 Reset Distribution

```
external_rst_n ──┬──► power_mgr (always-on domain)
                  │
                  └──► rst_sync ──► all other modules
                         │
                  wdt_rst_o ──┘ (OR gate)
```

Watchdog reset (wdt_rst_o) is OR-ed with external reset. Either source can reset the system.

### 5.3 Boot Sequence

1. External reset asserted (rst_ni = 0) — all registers at reset values
2. PLL locks, clock stable at 33.3 MHz
3. External reset deasserted → 2-stage synchronizer releases internal reset
4. PicoRV32 PC = 0x0000_0000, fetches first instruction from SRAM
5. Firmware initializes peripherals, enables interrupts, enters main loop

### 5.4 Clock Strategy

- **Single clock domain:** 33.3 MHz (sys_clk) for all modules
- **Source:** External oscillator via Caravel harness
- **No clock domain crossings** — all modules on same domain → no CDC needed
- **Clock gating:** power_mgr drives per-module clock enables (AND-gate on clock tree)
- **I²C timing:** Derived from sys_clk via prescaler (not a separate clock domain)

### 5.5 Initial Register/CSR/Memory State

| Module | Key Reset Values |
|--------|-----------------|
| picorv32_core | PC=0x00000000, MSTATUS.MIE=0 |
| sram_512b | Memory contents UNDEFINED (no reset on data array) |
| uart | CTRL=0x03 (TX_EN=1, RX_EN=1), BAUD_DIV=289 |
| i2c_master ×3 | All registers=0x00, PRESCALE must be programmed |
| gpio | DIR=0x0000 (all inputs), interrupts disabled |
| timer | COUNT=0, COMPARE=0xFFFFFFFF, CTRL=0x01 |
| motor_pwm | All DUTY=0, CTRL=0 (global disable), motors stopped |
| ultrasonic_capture | All registers=0, triggers inactive |
| weight_detect | THRESHOLD=0x00FFFFFF, SENSOR_OK=1, disabled |
| watchdog | TIMEOUT=0x00FFFFFF, CTRL=0 (disabled at boot) |
| interrupt_ctrl | ENABLE=0x0000 (all masked), PENDING=0 |
| power_mgr | CTRL=0x3FFF (all enabled), STATUS=ACTIVE |

---

## §6. Coding Constraints

### 6.1 Language
- **RTL:** Verilog 2005 only (IEEE 1364-2005). No SystemVerilog in synthesizable code.
- **Testbenches:** SystemVerilog allowed for cocotb/cpp testbenches only.

### 6.2 Naming Conventions
| Element | Convention | Example |
|---------|-----------|---------|
| Inputs | `signal_name_i` | `clk_i`, `rst_ni`, `wb_adr_i` |
| Outputs | `signal_name_o` | `wb_dat_o`, `irq_out_o`, `pwm_a_o` |
| Internal wires/regs | `signal_name` (no suffix) | `counter`, `state`, `next_state` |
| Clock | `clk_i` | `clk_i` |
| Reset (active-low) | `rst_ni` | `rst_ni` |
| Wishbone signals | `wb_<sig>_<dir>` | `wb_cyc_o`, `wb_ack_i` |
| Parameters | UPPER_SNAKE_CASE | `DATA_WIDTH`, `ADDR_WIDTH` |

### 6.3 Forbidden Patterns
- No `initial` blocks in synthesizable code (use reset for initialization)
- No latches: every `if` must have `else`, every `case` must have `default`
- No partial bit-slice assignments on LHS
- No LHS concatenation in `assign` or `always @*` blocks
- No implicit wires: all signals explicitly declared with `wire` or `reg`
- No mixing blocking (`=`) and non-blocking (`<=`) in same `always` block
- No `casex` or `casez` — use `case` with explicit don't-care masking
- No tri-state logic inside the core — bidirectional pads at top-level only (Caravel GPIO)

### 6.4 Required Patterns
- Active-low async reset: `always @(posedge clk_i or negedge rst_ni)`
- Registered outputs where possible (reduces combinational depth)
- `default` in every `case` statement
- 4-space indentation, no tabs
- FSM: localparam for state encoding, 2-always-block style (combinational next_state + registered state)
- Parameterized widths: use `parameter DATA_WIDTH = 32` at module top
- `ifdef SIMULATION` guard for `$readmemh` in SRAM (ORFS compatibility)
- All bus outputs driven to 0 when not selected (avoids floating bus)

### 6.5 Module Boundaries
- Each module has exactly one clock domain (sys_clk)
- Module outputs are registered (1-cycle latency) unless combinational by design (e.g., wb_ack_o)
- Bus interfaces use Wishbone B4 classic mode: `cyc, stb, we, adr, dat_o, dat_i, sel, ack`
- No module instantiates another module's internals — clean hierarchy
- Top-level `trash_robot_top` instantiates all 15 submodules + wb_interconnect

---

## §7. CSR Summary

| Name | Address | Access | Reset Value | Module | Description |
|------|---------|--------|-------------|--------|-------------|
| uart.TX_DATA | 0x2000 | R/W | 0x00 | uart | TX shift register load |
| uart.RX_DATA | 0x2004 | R | 0x00 | uart | RX shift register read (clears RX_READY) |
| uart.STATUS | 0x2008 | R | 0x01 | uart | RX_READY, TX_BUSY, RX_ERROR |
| uart.CTRL | 0x200C | R/W | 0x03 | uart | TX_EN, RX_EN |
| uart.BAUD_DIV | 0x2010 | R/W | 289 | uart | Baud divisor |
| i2c.DATA | 0x4000/0xA000/0xB000 | R/W | 0x00 | i2c ×3 | TX/RX data byte |
| i2c.CTRL | 0x4004/0xA004/0xB004 | R/W | 0x00 | i2c ×3 | START/STOP/RD/ACK |
| i2c.STATUS | 0x4008/0xA008/0xB008 | R | 0x00 | i2c ×3 | BUSY/ACK_ERR/ARB_LOST |
| i2c.PRESCALE | 0x400C/0xA00C/0xB00C | R/W | 41 | i2c ×3 | Clock prescaler |
| gpio.DIR | 0x5000 | R/W | 0x0000 | gpio | Per-pin direction |
| gpio.OUT | 0x5004 | R/W | 0x0000 | gpio | Output value |
| gpio.IN | 0x5008 | R | — | gpio | Input value |
| gpio.INTE | 0x500C | R/W | 0x0000 | gpio | Interrupt enable mask |
| gpio.INTTYPE | 0x5010 | R/W | 0x0000 | gpio | Level/edge select |
| gpio.INTPOL | 0x5014 | R/W | 0x0000 | gpio | Polarity select |
| gpio.INTSTAT | 0x5018 | R/W1C | 0x0000 | gpio | Interrupt status (W1C) |
| timer.COUNT | 0x6000 | R/W | 0x00000000 | timer | Current count |
| timer.COMPARE | 0x6004 | R/W | 0xFFFFFFFF | timer | Compare threshold |
| timer.CTRL | 0x6008 | R/W | 0x00000001 | timer | EN, AUTO_RESTART, PWM_EN |
| timer.PWM_DUTY[3:0] | 0x600C-0x6018 | R/W | 0x00000000 | timer | PWM duty (4×32-bit) |
| motor.DUTY_CH[3:0] | 0x7000-0x700C | R/W | 0x00000000 | motor_pwm | Ch0-3 duty/dir/enable |
| motor.CTRL | 0x7010 | R/W | 0x00000000 | motor_pwm | GLOBAL_EN, FAULT_CLEAR (W1C) |
| motor.STATUS | 0x7014 | R | 0x00 | motor_pwm | FAULT_FLAGS, ANY_FAULT |
| ultrasonic.TRIG | 0x8000 | R/W | 0x00 | ultrasonic | Trigger measurement |
| ultrasonic.ECHO_CH[1:0] | 0x8004-0x8008 | R | 0x00000 | ultrasonic | Echo width (20-bit ×2) |
| ultrasonic.STATUS | 0x800C | R | 0x00 | ultrasonic | DONE flags, TIMEOUT |
| ultrasonic.CTRL | 0x8010 | R/W | 0x00 | ultrasonic | EN, CONTINUOUS |
| weight.THRESHOLD | 0x9000 | R/W | 0x00FFFFFF | weight_detect | Weight threshold (24-bit) |
| weight.CURRENT | 0x9004 | R | 0x00000000 | weight_detect | Current reading |
| weight.STATUS | 0x9008 | R | 0x02 | weight_detect | ABOVE_THRESH, SENSOR_OK |
| weight.CTRL | 0x900C | R/W | 0x00 | weight_detect | EN |
| wdt.TIMEOUT | 0xD000 | R/W | 0x00FFFFFF | watchdog | Timeout counter |
| wdt.CTRL | 0xD004 | R/W | 0x00 | watchdog | EN, WARN_EN |
| wdt.KEY | 0xD008 | W | — | watchdog | Magic-key reload (0xACCE5515) |
| wdt.STATUS | 0xD00C | R | 0x00 | watchdog | WARNED, RESET_ISSUED |
| intc.ENABLE | 0xC000 | R/W | 0x0000 | interrupt_ctrl | Per-channel mask |
| intc.PENDING | 0xC004 | R | 0x0000 | interrupt_ctrl | Latched pending |
| intc.STATUS | 0xC008 | R | 0x0000 | interrupt_ctrl | Raw irq_in |
| intc.VECTOR | 0xC00C | R | 0x00 | interrupt_ctrl | Highest pending ch ID |
| pwr.CTRL | 0xE000 | R/W | 0x3FFF | power_mgr | Clock enable mask |
| pwr.SLEEP | 0xE004 | R/W | 0x00 | power_mgr | Sleep request |
| pwr.WAKE_SRC | 0xE008 | R | 0x00 | power_mgr | Wake source |
| pwr.STATUS | 0xE00C | R | 0x01 | power_mgr | ACTIVE/SLEEPING |

---

## §8. Assumptions & Open Items

### 8.1 Simplifications (v6)
- **No RTC clock domain:** DS3231 external RTC provides time. No internal 32.768 kHz oscillator.
- **No DMA:** All data movement is CPU-mediated.
- **No SPI:** Slot 0x3 reserved but unpopulated.
- **No debug module:** JTAG debugging not included.
- **No hardware multiplier pipeline:** PicoRV32 M-extension uses iterative shift-add.
- **I²C bus sharing:** Three i2c_master instances share one physical bus pair. Firmware arbitrates access.
- **Power gating:** Clock gating only, no power island switching (single VDD domain).

### 8.2 Items Deferred to Future Versions
- SPI master (slot 0x3 already reserved)
- Hardware multiplier pipeline for faster M-extension
- DMA controller for sensor data streaming
- Dual-core or hardware accelerator for AI/ML path planning
- Secure boot with cryptographic signature verification

### 8.3 Known Limitations
- 512B SRAM is small but v4/v5 proven sufficient for firmware
- No hardware I²C bus arbitration — firmware must sequence accesses
- No ECC on SRAM (soft-error tolerance not required for consumer application)
- Watchdog cannot be disabled once enabled (safety feature, not a limitation)

---

## §9. ORFS Compatibility

### 9.1 Reference Comparison

| Metric | IP-005 v6 | PicoRV32 Ref (ORFS) | Notes |
|--------|----------|---------------------|-------|
| CPU core cells | ~3,200 | ~3,200 | Identical — same PicoRV32 config |
| Bus protocol | Wishbone B4 | Wishbone B4 | Native — no bridge needed |
| Clock | 33.3 MHz | 100 MHz | Margin at 33.3 MHz is 3× reference |
| SRAM | 512B FF-based | OpenRAM macro | FF-based = larger area but simpler timing |
| Total cells | ~17K RTL / ~27K placed | ~3.2K (core only) | 14 peripherals add ~14K cells |

### 9.2 ORFS-Friendly Design Decisions
- **No APB/AXI bridge:** PicoRV32 uses native Wishbone B4 — no protocol translation.
- **No hardcoded boot ROM:** SRAM loaded via `ifdef SIMULATION` + `$readmemh`.
- **No byte-enable inside core:** wb_sel_i[3:0] passed through to SRAM, handled there.
- **Single clock domain:** No CDC, no multi-clock SDC complexity.
- **Registered peripheral outputs:** Minimizes combinational paths crossing module boundaries.

### 9.3 Interface Complexity Assessment
- **Bus:** 1 master → 14 slaves via combinational decode. Low complexity — fewer than 20 slaves threshold.
- **I/O:** 16 GPIO, 1 UART, 1 shared I²C, 8 PWM, 2 trigger, 2 echo. Moderate — all at top level.
- **Clock/reset:** Single domain, standard async-reset-sync-deassert pattern. Fully supported by OpenROAD flow.

### 9.4 Cell Count Sanity Check
- v5 synthesis: 1,852 RTL cells → 26,798 placed cells → 14.5× inflation ratio
- v6 uses same architecture → inflation ratio should match within 10%
- Target: < 30,000 placed cells (v5 was 26,798) → well under 3.0 mm² target
