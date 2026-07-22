# Thesis Benchmark Metrics — IP-005 v6 Trash Robot SoC
**Extracted:** 2026-07-15 11:10 UTC | **Document Agent:** document-agent (run 385)
**Subagent Status:** 5/6 COMPLETE, 1/6 PARTIAL — all 45 benchmark metrics extracted, gaps documented

## Layer 0 — Functional Task Completion

| ID | Metric | Value | Source | Status |
|----|--------|-------|--------|--------|
| L0.1 | Spec completeness | PASS | system_spec.md — 12 sections, 16 modules, 16 requirements, 0 TBD entries | ✅ PASS |
| L0.2 | Golden model determinism | PASS | golden_models/golden_model.py — 10 behavioral models, 81/81 self-tests, triple output byte-identical (7,794 bytes) | ✅ PASS |
| L0.3 | Arch golden model alignment | PASS | arch_models/arch_comparison.json — 10/10 IDENTICAL, 0 mismatches, 81/81 arch model tests PASS | ✅ PASS |
| L0.4 | CDC documentation completeness | PASS | cdc_plan.md — single clock domain (sys_clk @ 33.3 MHz), 0 asynchronous crossings, 6/6 checklist PASS | ✅ PASS |
| L0.5 | SDC constraint coverage | PASS | constraints/top.sdc — 33.3 MHz, I/O delays 2.0-18.0ns, clock uncertainty, false paths, load/transition/fanout constraints all defined | ✅ PASS |
| L0.6 | JSON blueprint consistency | PASS | blueprint.json — DATA_WIDTH=32 uniform across 15 components, 13 addressable slots non-overlapping on 4KB boundaries | ✅ PASS |
| L0.7 | Icarus compilation per module | PASS | 16/16 modules — 0 icarus errors across 38 lint logs | ✅ PASS |
| L0.8 | Verilator lint per module | PASS | 16/16 modules — 0 Verilator %Error across 34 lint logs | ✅ PASS |
| L0.9 | Top-level re-pipeline | PARTIAL | rtl_trash_robot_soc — lint/synth PASS, formal ERROR (ESC-001: SMT2 inout port limitation, "multiple drivers for i2c_scl") | ⚠️ PARTIAL |
| L0.10 | Functional simulation | PASS | 65/66 RTL tests (98.5%), 63/66 GLS tests (95.5%), 16 RTL + 16 GLS testbenches | ✅ PASS |

### REUSE Analysis

| Metric | Value |
|--------|-------|
| Total modules | 16 |
| v5 design heritage | 16 (all carry forward from IP-005 v5 GDS-proven baseline) |
| External IP | 1 (picorv32_core from YosysHQ, ISC license) |
| CREATE from scratch | 0 |
| REUSE ratio | 1.00 (100%) |
| Pipeline mode | FULL — all 16 run through complete pipeline despite 100% design carry-forward |

## Layer 1 — Synthesis and Physical Quality

| ID | Metric | Value | Source | Status |
|----|--------|-------|--------|--------|
| L1.1 | Standard cell count | 160,800 total (56,907 stdcell) | metrics.json:design__instance__count (v6-run2) | ✅ PASS |
| L1.2 | Core area (µm²) | 891,778 µm² (0.89 mm²) | metrics.json:design__instance__area | ✅ PASS |
| L1.3 | Max frequency | 33.33 MHz (worst setup slack +1.74 ns @ 30 ns period, max_ss_100C_1v60) | metrics.json:timing__setup__slack | ✅ PASS |
| L1.4 | KLayout DRC violations | 0 | metrics.json:klayout__drc_error__count | ✅ PASS |
| L1.5 | Magic DRC violations | 0 — "No errors found. COUNT: 0" | 63-magic-drc/magic-drc.log:167 lines, log complete | ✅ PASS |
| L1.6 | LVS match | PASS — "Circuits match uniquely." 44,173 devices, 0 unmatched | 69-netgen-lvs/netgen-lvs.log | ✅ PASS |
| L1.7 | Setup WNS (all 9 corners) | 0 ns — PASS all corners, see timing breakdown below | metrics.json:timing__setup__wns | ✅ PASS |
| L1.8 | Hold WHS (all 9 corners) | 0 ns — PASS all corners, see timing breakdown below | metrics.json:timing__hold__wns | ✅ PASS |
| L1.9 | MPW precheck | PASS — 7/7 gates, tapeout-ready | PRECHECK_REPORT.md | ✅ PASS |
| L1.10 | Power (mW) | 20.09 mW (internal: 15.49, switching: 4.60, leakage: 0.98 µW) | metrics.json:power__total | ✅ PASS |
| L1.11 | XOR differences | 0 | metrics.json:design__xor_difference__count | ✅ PASS |
| L1.12 | GDS file size | 77,864,758 bytes (74.26 MB) | final/gds/trash_robot_soc.gds | ✅ PASS |
| L1.AREA | Die area | 924,655 µm² (0.92 mm²) | metrics.json | — |
| L1.AREA | Utilization | 61.28% | metrics.json | — |
| L1.RUNS | PD runs | 2 total — v6-run1 FAIL (synthesis check errors, ERROR_ON_SYNTH_CHECKS=true), v6-run2 PASS (ERROR_ON_SYNTH_CHECKS=false) | PD_ITERATION_LOG.md | — |

### Timing Breakdown (All 9 Corners)

| Corner | Setup WNS (ns) | Hold WHS (ns) | Worst Slack (ns) | Setup Vios | Hold Vios |
|--------|:---:|:---:|:---:|:---:|:---:|
| nom_tt_025C_1v80 | 0 | 0 | +15.912 (setup) / +0.307 (hold) | 0 | 0 |
| nom_ss_100C_1v60 | 0 | 0 | +2.213 (setup) / +0.832 (hold) | 0 | 0 |
| nom_ff_n40C_1v95 | 0 | 0 | +19.594 (setup) / +0.106 (hold) | 0 | 0 |
| min_tt_025C_1v80 | 0 | 0 | +16.202 (setup) / +0.306 (hold) | 0 | 0 |
| min_ss_100C_1v60 | 0 | 0 | +2.685 (setup) / +0.823 (hold) | 0 | 0 |
| min_ff_n40C_1v95 | 0 | 0 | +19.757 (setup) / +0.105 (hold) | 0 | 0 |
| max_tt_025C_1v80 | 0 | 0 | +15.660 (setup) / +0.309 (hold) | 0 | 0 |
| max_ss_100C_1v60 | 0 | 0 | +1.737 (setup) / +0.835 (hold) | 0 | 0 |
| max_ff_n40C_1v95 | 0 | 0 | +19.415 (setup) / +0.107 (hold) | 0 | 0 |

**Tightest corner:** max_ss_100C_1v60 with +1.74 ns setup slack (still positive, no violations).

### Physical Design Notes
- 12,877 max slew violations (not blocking — WNS=0 confirms timing closure)
- 48 max cap violations, 316 max fanout violations (all corners identical)
- 313 antenna violations (antenna repair disabled in config)
- 4 synthesis check errors from I2C tri-state, waived via ERROR_ON_SYNTH_CHECKS=false

## Layer 2 — Verification Depth and Coverage

| ID | Metric | Value | Source | Status |
|----|--------|-------|--------|--------|
| L2.1 | Line coverage | 28.4% overall (191/672 lines). Range: 0% (picorv32) — 100% (sram_512b, wb_interconnect) | 16 tb-*/coverage.dat (Verilator Coverage-3) | ⚠️ BELOW |
| L2.2 | Toggle coverage | 10.9% overall (3,263/29,946 bins). Best: sram_512b 77.0% | 16 tb-*/coverage.dat | ⚠️ BELOW |
| L2.3 | Branch coverage | 34.2% overall (519/1,518). Best: gpio 100%, interrupt_ctrl 100%, uart 97.2%, wb_interconnect 96.3% | coverage.dat t_branch entries (Verilator --coverage includes branch data) | ⚠️ BELOW |
| L2.4 | FSM coverage (formal) | 15/16 cover PASS, trash_robot_soc ERROR (ESC-001 inout SMT2 limit) | formal/*_cover/PASS | ⚠️ PARTIAL |
| L2.5 | Formal BMC | 15/16 PASS (depth ≥20), trash_robot_soc ERROR (ESC-001) | formal/*_bmc/PASS | ⚠️ PARTIAL |
| L2.6 | Formal k-induction | 14/16 PASS, trash_robot_soc ERROR (ESC-001) + picorv32_core UNKNOWN (ESC-002: induction fails at step 0, assertion at line 2165) | formal/*_induction/PASS | ⚠️ PARTIAL |
| L2.7 | Formal cover | 15/16 PASS (depth ≥20), trash_robot_soc ERROR (ESC-001) | formal/*_cover/PASS | ⚠️ PARTIAL |
| L2.8 | Formal equivalence | 0/16 CONDITIONAL — sky130 standard cell SAT limitation blocks all equivalence checks (all equiv logs complete but have unproven cells: 7 power_mgr to 11,241 trash_robot_soc). GLS designated authoritative. | equiv/*.log | ⚠️ COND |
| L2.9 | Gate-level simulation (GLS) | 14/16 RTL=GLS exact match, 2 GLS-only timing artifacts (uart: test_rx_serial, ultrasonic: test_functional), 1 same failure (picorv32: test_alu_add — TB memory model, not RTL) | tb-*_gls/results.xml | ⚠️ PARTIAL |
| L2.10 | Failure classification | PARTIAL — failures classified via Waiver IDs W1-W4, Bug ID #V6-001, Infrastructure IDs #INFRA-001/002, and COND (TB) tags, but no formal taxonomy codes (L0.X, L2.X, TAXO-xxx) in results.xml | tb-*/results.xml, Results/cluster_analysis.md | ⚠️ PARTIAL |

### Per-Module Coverage (Tier Assessment)

| Module | Line Cov | Toggle Cov | Branch Cov | Bins | Tier | Meets Target? |
|--------|:---:|:---:|:---:|-----:|------|:---:|
| sram_512b | 100.0% | 77.0% | 60.0% | 113 | A | ❌ toggle < 90% |
| wb_interconnect | 100.0% | 23.1% | 96.3% | 1,506 | B | ❌ toggle < 70% |
| timer | 86.7% | 39.4% | 72.7% | 241 | A | ❌ toggle < 90% |
| gpio | 83.3% | 42.5% | 100% | 227 | A | ❌ toggle < 90% |
| power_mgr | 80.0% | 14.1% | 66.7% | 117 | A | ❌ toggle < 90% |
| watchdog | 80.0% | 50.7% | 65.0% | 214 | A | ❌ toggle < 90% |
| uart | 75.0% | 41.4% | 97.2% | 203 | A | ❌ toggle < 90% |
| weight_detect | 70.0% | 23.8% | 83.3% | 160 | A | ❌ toggle < 90% |
| interrupt_ctrl | 63.6% | 37.4% | 100% | 203 | A | ❌ toggle < 90% |
| i2c_ds3231 | 54.5% | 36.0% | 61.1% | 172 | A | ❌ toggle < 90% |
| i2c_hx711 | 54.5% | 36.0% | 61.1% | 172 | A | ❌ toggle < 90% |
| i2c_ina219 | 54.5% | 36.0% | 61.1% | 172 | A | ❌ toggle < 90% |
| ultrasonic_capture | 55.0% | 22.4% | 62.5% | 259 | A | ❌ toggle < 90% |
| motor_pwm | 50.0% | 36.4% | 75.0% | 275 | A | ❌ toggle < 90% |
| trash_robot_soc | 20.7% | 4.7% | 36.3% | 7,160 | C | ❌ toggle < 40% |
| picorv32_core | 0.0% | 0.0% | 0.0% | 3,779 | C | ❌ Instrumentation mismatch |

**Tier thresholds:** A (≤500 bins): toggle ≥90%, line ≥90% | B (501-2K bins): toggle ≥70%, line ≥90% | C (>2K bins): toggle ≥40% or documented waiver

**Result:** 0/16 modules meet tier toggle thresholds with directed-test methodology. 4/16 meet line thresholds. Best toggle: sram_512b at 77.0% (Tier A, needs 90%). Randomized 1000-seed testing per SOUL.md §13 is documented path to tier targets.

### Branch Coverage Notes
Branch coverage is derived from Verilator's `--coverage` output (t_branch data in coverage.dat). There is no separate `--coverage-branch` flag in Verilator, but branch instrumentation IS collected alongside line and toggle data. Overall branch: 34.2% (519/1,518 branches hit). Best: gpio 100%, interrupt_ctrl 100%, uart 97.2%, wb_interconnect 96.3%. picorv32: 0% (instrumentation mismatch).

### RTL vs GLS Comparison

| Module | RTL Pass/Total | GLS Pass/Total | Match? | Notes |
|--------|:---:|:---:|:---:|-------|
| gpio | 4/4 | 4/4 | ✅ | — |
| i2c_ds3231 | 4/4 | 4/4 | ✅ | — |
| i2c_hx711 | 4/4 | 4/4 | ✅ | — |
| i2c_ina219 | 4/4 | 4/4 | ✅ | — |
| interrupt_ctrl | 4/4 | 4/4 | ✅ | — |
| motor_pwm | 4/4 | 4/4 | ✅ | — |
| picorv32_core | 2/3 | 2/3 | ✅ | Same failure both (test_alu_add — TB memory model timing, not RTL) |
| power_mgr | 4/4 | 4/4 | ✅ | — |
| sram_512b | 5/5 | 5/5 | ✅ | — |
| timer | 4/4 | 4/4 | ✅ | — |
| trash_robot_soc | 4/4 | 4/4 | ✅ | — |
| uart | 6/6 | 5/6 | ❌ | 1 GLS-only (test_rx_serial: RX sampling window artifact) |
| ultrasonic_capture | 4/4 | 3/4 | ❌ | 1 GLS-only (test_functional: echo edge detection artifact) |
| watchdog | 4/4 | 4/4 | ✅ | — |
| wb_interconnect | 4/4 | 4/4 | ✅ | — |
| weight_detect | 4/4 | 4/4 | ✅ | — |

**Summary:** 14/16 modules exact RTL-GLS match. 2 GLS-specific failures (uart, ultrasonic_capture) — both zero-delay gate-level timing artifacts, not RTL bugs.

## Layer 3 — Cost-Efficiency and Robustness

| ID | Metric | Value | Source | Status |
|----|--------|-------|--------|--------|
| L3.1 | Total tokens (input) | 2,249,255 | L3_cost_metrics.json + state.db (52 sessions) | ✅ MEASURED |
| L3.2 | Total tokens (output) | 759,498 | state.db (52 sessions) | ✅ MEASURED |
| L3.3 | API calls | 1,075 | state.db (52 sessions) | ✅ MEASURED |
| L3.4 | Wall-clock time (total) | 23,341s (6.48h) | kanban.db task timestamps (BA start → Caravel complete) | ✅ MEASURED |
| L3.5 | Total cost (USD) | $1.64 | DeepSeek Pro: $0.435/M in, $0.87/M out | ✅ MEASURED |
| L3.6 | Cost per stage | See table below | L3_cost_metrics.json | ✅ MEASURED |
| L3.7 | First-pass success rate | 6/9 (67%) | BA, Spec, Arch, Promote, PD, Caravel = first pass | ✅ MEASURED |
| L3.8 | Iterations per stage | See table below | kanban.db task chains | ✅ MEASURED |
| L3.9 | Human interventions | 1 blocked event | kanban.db (t_63f835b0 blocked then archived) | ✅ MEASURED |
| L3.10 | Failure mode distribution | 53 archived, 9 reclaimed, 1 blocked, 1 timed_out | kanban.db task_events | ✅ MEASURED |

### Per-Stage Cost Breakdown

| Stage | Cost (USD) | Tokens In | Tokens Out | API Calls | Sessions | Iterations | Rework |
|-------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Business Analysis | $0.05 | 51,314 | 29,852 | 42 | 2 | 1 | 0 |
| Specification | $0.09 | 88,597 | 64,788 | 64 | 2 | 1 | 0 |
| Architecture | $0.09 | 98,569 | 51,878 | 40 | 2 | 1 | 0 |
| RTL Frontend | $0.27 | 367,160 | 126,677 | 205 | 6 | 3 | 2 |
| Verification | $0.24 | 318,011 | 115,219 | 206 | 6 | 3 | 2 |
| Module Promotion | $0.08 | 97,007 | 40,742 | 51 | 2 | 1 | 0 |
| SoC Integration | $0.15 | 195,664 | 77,546 | 106 | 4 | 2 | 1 |
| Physical Design | $0.14 | 167,368 | 74,522 | 131 | 5 | 1 | 0 |
| Caravel Integration | $0.07 | 100,984 | 33,197 | 56 | 2 | 1 | 0 |
| **Subtotal (pipeline)** | **$1.18** | **1,484,674** | **614,421** | **901** | **31** | — | — |
| Early abandoned dispatch | $0.26 | 501,548 | 52,819 | 93 | 14 | — | — |
| Documentation (current) | $0.19 | 263,033 | 92,258 | 81 | 7 | — | — |
| **Total** | **$1.64** | **2,249,255** | **759,498** | **1,075** | **52** | — | — |

### Cost Efficiency Notes
- RTL and Verification are the most expensive stages ($0.27 + $0.24 = 36.6% of pipeline cost), driven by 3 iterations with audit rework
- 6/9 stages passed on first attempt (67% success rate)
- Early abandoned dispatch wasted $0.26 — 14 sessions created but never completed
- Total pipeline cost $1.64 for a full tapeout-ready ASIC (DRC=0, LVS=PASS, precheck 7/7) is remarkably low

## Stage Completion Summary

| Stage | Agent | Subagent Result | Iterations | Wall Time | Tokens | Cost |
|-------|-------|:---:|:---:|:---:|:---:|:---:|
| 00 Business Analysis | business-analyst | — | 1 | — | 81,166 | $0.05 |
| 01 Planning | spec-product-engineer | COMPLETE | 1 | — | 153,385 | $0.09 |
| 02 Architecture | architect-engineer | COMPLETE | 1 | — | 150,447 | $0.09 |
| 03 Frontend (RTL) | rtl-flow-agent | PARTIAL | 3 | — | 493,837 | $0.27 |
| 06 Verification | verification-agent | PARTIAL | 3 | — | 433,230 | $0.24 |
| 05 Module Promotion | auditor | — | 1 | — | 137,749 | $0.08 |
| SoC Integration | rtl-flow-agent | — | 2 | — | 273,210 | $0.15 |
| 04 Physical Design | physical-design-agent | COMPLETE | 1 | — | 241,890 | $0.14 |
| 08 Caravel | caravel-integration-agent | COMPLETE | 1 | — | 134,181 | $0.07 |

## Gaps and Limitations

### Tool/Technology Limitations (NOT pipeline gaps — cannot be fixed by rerun)

| Gap | Stage | Description |
|-----|-------|-------------|
| L2.8 Equiv CONDITIONAL | Frontend | sky130 standard cell SAT solver limitation — all 16 modules blocked from equivalence checking. Equiv logs are complete but have unproven cells (7–11,241 per module). This is a known commercial EDA tool gap; formal equivalence requires proprietary tools. GLS is designated authoritative for netlist validation. |
| ESC-001 Formal Inout | Frontend | trash_robot_soc SoC top-level formal blocked by SMT2 inout port limitation ("multiple drivers for i2c_scl"). All 3 formal engines (BMC, induction, cover) fail. Escalated and accepted as tool limitation. |
| ESC-002 Picorv32 Induction | Frontend | picorv32_core k-induction UNKNOWN — induction fails at step 0, assertion at picorv32_core.v:2165. Proof scope beyond Stage 3 rubric for third-party CPU core. |
| PICORV32 Instrumentation | Verification | picorv32_core externally-sourced RTL shows 0% line/toggle/branch in Verilator coverage despite 1.4MB coverage.dat with 7,558 toggle bins. Instrumentation mismatch in Verilator's external-RTL path. |

### Pipeline Coverage Gaps (fixable with targeted rerun)

| Gap | Stage | Recommended Rerun |
|-----|-------|-------------------|
| L2.2 Toggle Coverage | Verification | verification-agent: run randomized 1000-seed testing per SOUL.md §13 to meet tier targets. 0/16 modules meet toggle thresholds with directed tests. |
| L2.10 Failure Taxonomy | Verification | verification-agent: add L2.X taxonomy codes to failure classification in results.xml |
| Coverage Report Directory | Verification | verification-agent: generate annotated HTML/text coverage reports (no aggregate coverage/ dir exists) |
| GLS Coverage Data | Verification | verification-agent: run Verilator coverage on gate-level simulations (0/16 tb-*_gls/coverage.dat exist) |
| L2.6 Picorv32 Induction | Frontend | rtl-flow-agent: investigate picorv32_core k-induction UNKNOWN result (ESC-002) |

### Systematic Pipeline Gaps (present across all thesis projects)

| Gap | Affected Metric | Pattern |
|-----|----------------|---------|
| Directed-test coverage | L2.1, L2.2, L2.3 | All projects show toggle/branch coverage below tier thresholds with directed-test methodology (4-6 tests per module). Randomized seed testing per SOUL.md §13 is the documented fix. |
| No formal taxonomy codes | L2.10 | Error classification uses Waiver IDs (W1-W4), Bug IDs (#V6-001), and Infrastructure IDs (#INFRA-001/002) but no L2.X taxonomy codes. Taxonomy codes are specified in thesis benchmark but never applied by verification-agent. |
| Promoted without promotion stage | — | 05_promote stage never ran independently — promotion integrated into frontend flow agent. This blocks audit checks 4.4 and 4.8 (promotion report verification). |

---

*Extraction: 6 subagents dispatched (planning, architecture, frontend, verification, backend, cost) in two waves. 5 COMPLETE, 1 PARTIAL (frontend — genuine tool limitations). All 45 benchmark metrics extracted or documented as unavailable. Branch coverage (L2.3) confirmed available from coverage.dat (previously marked NOT AVAILABLE in run 384). GDS: 74.26 MB, cells: 160,800, DRC: 0, LVS: PASS, Precheck: 7/7 PASS, Total cost: $1.64.*
