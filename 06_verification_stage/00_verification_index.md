# 06_verification_stage — Index
**Project:** IP-005 v6a | **Agent(s):** verification-agent | **Skills:** verification-stage

## Testbenches
| # | Directory | Module | Type |
|---|-----------|--------|------|
| 1 | 01_tb_gpio | gpio | RTL |
| 2 | 02_tb_gpio_gls | gpio | GLS |
| 3–8 | 03_tb_i2c_ds3231 ... 08_tb_i2c_ina219_gls | i2c_* | RTL + GLS |
| 9–32 | 09_tb_interrupt_ctrl ... 32_tb_trash_robot_soc_gls | remaining 12 modules | RTL + GLS |

## Results & Audit
| Directory | Contents |
|-----------|----------|
| 99_results/ | Verification summary reports (bug_report, cluster_analysis, run_summary) |
| 99_audit/ | Artifact gate script (verify_test_artifacts.sh) |

## Shared
| File | Description |
|------|-------------|
| wb_driver.py | Wishbone bus driver (imported by all testbenches — do not move) |

## Validation
- **Report:** [../00_validation_report/06_verification_validation.md](../00_validation_report/06_verification_validation.md)
- **Postmortem:** [../11_postmortem_audit/06_verification_postmortem.md](../11_postmortem_audit/06_verification_postmortem.md)
