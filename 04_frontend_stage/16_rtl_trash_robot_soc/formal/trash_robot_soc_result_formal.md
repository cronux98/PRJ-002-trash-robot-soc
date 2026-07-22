# Formal Result: trash_robot_soc — IP-005 v6 (Rework Fix 2+3)

## Run Info
- Date: 2026-07-15 05:40-05:42
- Tool: sby (SymbiYosys) 0.65 via yosys 0.65+71
- Engine: smtbmc yices
- Solver: yices
- Commands attempted: 3 runs with different configurations

## Configuration
- Tasks: bmc, induction, cover (all depth 20)
- RTL files: 23 files (v6 paths, rgb_led_pwm removed, i2c modules added)
- Sby: /home/user/hermes_workspace/projects/IP-005/v6/03_frontend_stage/rtl_trash_robot_soc/formal/trash_robot_soc.sby

## Results

| Attempt | Approach | Error | Root Cause |
|---------|----------|-------|------------|
| 1 | `prep -top trash_robot_soc` | `Unsupported or unknown directionality on port scl` | I2C `inout` ports not supported by SMT2 generation |
| 2 | `hierarchy -check` + blackbox i2c | `Module 'i2c_master' is a blackbox/whitebox module` | `hierarchy -check` rejects blackboxed modules |
| 3 | `hierarchy -top` (no -check) | `Found multiple drivers for \i2c_scl` | Three i2c_master instances share SCL/SDA via inout → multi-driver |

## Verdict: FAIL (Tool Limitation)
- **All 3 tasks (bmc, induction, cover): ERROR**
- Root cause: I2C bidirectional (`inout`) ports are fundamentally unsupported by SymbiYosys SMT2 generation
- The three i2c_master instances (hx711, ina219, ds3231) sharing SCL/SDA lines create both `inout` and multi-driver issues
- **Not a configuration error** — the .sby file is correctly configured with v6 paths, no rgb_led_pwm, all 23 files, depth 20, all 3 tasks

## Recommended Resolution
- Option A: Create I2C stub modules with unidirectional ports for formal (SCL/SDA split into _i/_o)
- Option B: Exclude I2C modules from SoC top formal, verify them independently as leaf modules
- Option C: Accept SoC-level formal limitation for designs with shared bidirectional buses — GLS is the authoritative functional verification

## Fix Verification
- RTL fix confirmed: `grep -rn 'rgb_led_pwm'` returns only changelog comments (line 6), no instantiation
- verilator lint: NO `rgb_led_pwm` error (was the root cause of audit check 3.3 failure)
- .sby paths updated: v5 → v6
- Induction task added
- BMC depth: 10 → 20
