# IP-005 v6 Verification — Bug Report

## RTL Bugs

### #V6-001: trash_robot_soc wdt_rst_n output port unassigned
- **Severity:** Medium
- **Module:** trash_robot_soc
- **File:** `03_frontend_stage/rtl_trash_robot_soc/rtl/trash_robot_soc.v:38`
- **Description:** The `wdt_rst_n` output port is declared but never assigned. Internal signal `wdt_rst_n_int` (line 72) is properly connected but there is no `assign wdt_rst_n = wdt_rst_n_int;` statement. Compare with `sys_rst_n_o` which correctly has `assign sys_rst_n_o = sys_rst_n_int;` at line 425.
- **Impact:** wdt_rst_n port is undriven (Z in iverilog, 0 in Verilator). External logic relying on this signal will see incorrect values.
- **Fix:** Add `assign wdt_rst_n = wdt_rst_n_int;` near line 425 (after sys_rst_n_o assignment).
- **Found by:** test_peripheral_port_connectivity (tb_trash_robot_soc)
- **Workaround:** Testbench skips wdt_rst_n assertion

## Infrastructure Issues

### #INFRA-001: Icarus vvp segfault on wb_interconnect teardown
- **Severity:** Low
- **Tool:** Icarus Verilog 14.0 (oss-cad-suite)
- **Module:** wb_interconnect (RTL and GLS)
- **Description:** vvp segfaults during Python teardown after all tests pass. `make` deletes results.xml on error exit. Tests themselves all pass (4/4).
- **Workaround:** Manual results.xml generated from captured PASS output
- **Status:** Known issue — also observed in v5

### #INFRA-002: Verilator coverage Makefile multi-file setup broken
- **Severity:** Low
- **Modules:** i2c_hx711, i2c_ina219, i2c_ds3231, interrupt_ctrl, motor_pwm, ultrasonic_capture
- **Description:** Makefile.verilator was created from RTL Makefile but doesn't correctly handle multi-file VERILOG_SOURCES for Verilator mode. Separate .v files need to be passed differently.
- **Impact:** No coverage.dat generated for these 5 modules
- **Workaround:** N/A — coverage data unavailable for these modules
