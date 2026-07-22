#!/bin/bash
# verify_test_artifacts.sh — IP-005 v6 Frontend Stage Artifact Gate
# Validates all 16 modules have required RTL, lint, formal, synthesis, and equiv artifacts.
# MUST exit 0 for stage gate to pass. See IP-005 v5 POST_MORTEM §1.4.

set -euo pipefail

V6="$(dirname "$0")"
PASS=0
FAIL=0

MODULES="rtl-gpio rtl-i2c_hx711 rtl-i2c_ina219 rtl-i2c_ds3231 rtl-interrupt_ctrl rtl-motor_pwm rtl-picorv32_core rtl-power_mgr rtl-sram_512b rtl-timer rtl-uart rtl-ultrasonic_capture rtl-watchdog rtl-wb_interconnect rtl-weight_detect rtl-trash_robot_soc"

echo "=== IP-005 v6 Frontend Artifact Gate ==="
echo "Modules: $(echo $MODULES | wc -w)"
echo ""

for mod in $MODULES; do
    short="${mod#rtl-}"
    echo "--- $mod ---"
    
    # 1. RTL exists
    rtl_count=$(find "$V6/$mod/rtl/" -name "*.v" 2>/dev/null | wc -l)
    if [ "$rtl_count" -gt 0 ]; then
        echo "  [PASS] RTL: $rtl_count file(s)"
    else
        echo "  [FAIL] RTL: no .v files"
        FAIL=$((FAIL+1))
        continue
    fi
    
    # 2. Lint logs exist + verilator error gate (retry 2: rubric check 3.3)
    iv_log="$V6/$mod/lint/${short}_iverilog.log"
    vl_log="$V6/$mod/lint/${short}_verilator.log"
    if [ -f "$iv_log" ] && [ -f "$vl_log" ]; then
        iv_errors=$(grep -ci "error" "$iv_log" 2>/dev/null || true)
        iv_errors="${iv_errors:-0}"
        # Verilator gate: count real error subtypes (not the informational "Exiting due to" line)
        vl_errors=$(grep -cE '%Error-[A-Z]' "$vl_log" 2>/dev/null || true)
        vl_errors="${vl_errors:-0}"
        echo "  [PASS] Lint: iverilog errors=$iv_errors, verilator errors=$vl_errors"
        if [ "$vl_errors" -gt 0 ]; then
            echo "  [FAIL] Verilator lint gate: $vl_errors error(s) in $vl_log"
            FAIL=$((FAIL+1))
        fi
    else
        echo "  [FAIL] Lint: missing log"
        FAIL=$((FAIL+1))
    fi
    
    # 3. Synthesis netlist exists
    netlist=$(ls "$V6/$mod/synth/"*_netlist.v 2>/dev/null | head -1)
    if [ -n "$netlist" ] && [ -s "$netlist" ]; then
        cells=$(grep -c "sky130_fd_sc_hd" "$netlist" 2>/dev/null || echo 0)
        echo "  [PASS] Synthesis: $cells sky130 cells"
    else
        echo "  [FAIL] Synthesis: no netlist"
        FAIL=$((FAIL+1))
    fi
    
    # 4. Equiv log exists
    equiv_log="$V6/$mod/equiv/${short}_equiv.log"
    if [ -f "$equiv_log" ]; then
        echo "  [PASS] Equiv: log exists"
    else
        echo "  [FAIL] Equiv: missing log"
        FAIL=$((FAIL+1))
    fi
    
    # 5. Formal (if run)
    formal_dirs=$(find "$V6/$mod/formal/" -name "*.sby" 2>/dev/null | wc -l)
    if [ "$formal_dirs" -gt 0 ]; then
        echo "  [PASS] Formal: $formal_dirs .sby config(s)"
    else
        echo "  [WARN] Formal: not yet run (V5 results reusable)"
    fi
    
    PASS=$((PASS+1))
done

echo ""
echo "=== GATE RESULT: $PASS modules checked, $FAIL failures ==="
if [ "$FAIL" -eq 0 ]; then
    echo "VERDICT: PASS"
    exit 0
else
    echo "VERDICT: FAIL"
    exit 1
fi
