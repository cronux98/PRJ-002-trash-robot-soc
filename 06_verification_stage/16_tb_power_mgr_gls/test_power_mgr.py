"""
cocotb testbench for power_mgr — Power manager with reset sync
Tests: register reads, reset deassert sync, clk_en_o, STATUS, ack handshake
"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, FallingEdge
import sys, os, random
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from wb_driver import reset_dut, wb_write, wb_read, wb_init, safe_int

ADDR_BASE = 0x0

# RTL register map (power_mgr.v):
# 0x00: CTRL     (read-only: [1]=ext_rst_flag, [0]=wdt_rst_flag; clear-on-read)
# 0x04: STATUS   (read-only: [0]=PLL_LOCKED, tied high)
#
# Ports needing external drive:
#   ext_rst_n, wdt_rst_n — both must be 1 for sys_rst_n_o to deassert
#   sys_clk_i — clock for reset synchronizer (must toggle)


@cocotb.test()
async def test_reset(dut):
    """Verify reset clears all outputs and registers."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    # Drive sys_clk_i for the reset synchronizer
    cocotb.start_soon(Clock(dut.sys_clk_i, 10, unit='ns').start())
    await wb_init(dut)
    # Drive external resets high (not asserted)
    dut.ext_rst_n.value = 1
    dut.wdt_rst_n.value = 1
    await ClockCycles(dut.clk_i, 2)
    dut.rst_ni.value = 0
    await ClockCycles(dut.clk_i, 4)
    await Timer(1, unit='ns')
    assert safe_int(dut.wb_ack_o) == 0, "wb_ack_o should be 0 during reset"
    assert safe_int(dut.wb_dat_o) == 0, "wb_dat_o should be 0 during reset"
    assert safe_int(dut.sys_rst_n_o) == 0, "sys_rst_n_o should be 0 during reset"
    dut.rst_ni.value = 1
    await ClockCycles(dut.clk_i, 2)

@cocotb.test()
async def test_register_rw(dut):
    """Verify register reads and reset flag behaviour."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    cocotb.start_soon(Clock(dut.sys_clk_i, 10, unit='ns').start())
    await wb_init(dut)
    dut.ext_rst_n.value = 1
    dut.wdt_rst_n.value = 1
    await reset_dut(dut)

    # CTRL register (0x00): returns {30'd0, wdt_rst_flag, ext_rst_flag}
    # After clean reset with ext/wdt resets high, flags should be 0
    val = await wb_read(dut, 0x00)
    assert (val & 0x3) == 0, f"CTRL flags should be 0 after clean reset, got 0x{val:08X}"

    # STATUS register (0x04): [0]=PLL_LOCKED (tied high)
    val = await wb_read(dut, 0x04)
    assert (val & 0x1) == 1, f"STATUS[0] should be 1 (PLL_LOCKED), got 0x{val:08X}"

@cocotb.test()
async def test_functional(dut):
    """Exercise key functional behavior."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    cocotb.start_soon(Clock(dut.sys_clk_i, 10, unit='ns').start())
    await wb_init(dut)
    # Drive external resets high so sys_rst_n_o can deassert
    dut.ext_rst_n.value = 1
    dut.wdt_rst_n.value = 1
    await reset_dut(dut)

    # After reset deassert and external resets high, sys_rst_n_o should go high
    # (needs 2 cycles of sys_clk_i for the 2-FF synchronizer)
    await ClockCycles(dut.sys_clk_i, 4)
    await Timer(1, unit='ns')
    sys_rst = safe_int(dut.sys_rst_n_o)
    assert sys_rst == 1, f"sys_rst_n_o should be 1 after reset deassert, got {sys_rst}"

    # clk_en_o should be 1
    clk_en = safe_int(dut.clk_en_o)
    assert clk_en == 1, f"clk_en_o should be 1"

@cocotb.test()
async def test_ack_handshake(dut):
    """Verify ack_o asserts for one cycle then clears."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    cocotb.start_soon(Clock(dut.sys_clk_i, 10, unit='ns').start())
    await wb_init(dut)
    dut.ext_rst_n.value = 1
    dut.wdt_rst_n.value = 1
    await reset_dut(dut)

    # Use STATUS register (0x04) for read-based ack handshake test
    val = await wb_read(dut, 0x04)
    # STATUS returns {31'd0, 1'b1} (PLL_LOCKED)
    assert val == 1, f"STATUS read should return 1, got 0x{val:08X}"

    await ClockCycles(dut.clk_i, 2)
    await Timer(1, unit='ns')
    assert safe_int(dut.wb_ack_o) == 0, "ack should clear after transaction"
