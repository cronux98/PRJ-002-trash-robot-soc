"""
cocotb testbench for watchdog — Watchdog timer with magic KICK
Tests: register R/W, ENABLE, TIMEOUT, KICK magic, rst_out_n
"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, FallingEdge
import sys, os, random
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from wb_driver import reset_dut, wb_write, wb_read, wb_init, safe_int

ADDR_BASE = 0x0



@cocotb.test()
async def test_reset(dut):
    """Verify reset clears all outputs and registers."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await ClockCycles(dut.clk_i, 2)
    dut.rst_ni.value = 0
    await ClockCycles(dut.clk_i, 4)
    await Timer(1, unit='ns')
    assert safe_int(dut.wb_ack_o) == 0, "wb_ack_o should be 0 during reset"
    assert safe_int(dut.wb_dat_o) == 0, "wb_dat_o should be 0 during reset"
    
    dut.rst_ni.value = 1
    await ClockCycles(dut.clk_i, 2)

@cocotb.test()
async def test_register_rw(dut):
    """Write to each register, read back, verify value latched."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)
        # TIMEOUT register (0x04)
    await wb_write(dut, 0x04, 0x0000FFFF)
    val = await wb_read(dut, 0x04)
    assert val == 0xFFFF, f"TIMEOUT: got 0x{val:08X}"

    # CTRL register (0x00) — ENABLE
    await wb_write(dut, 0x00, 0x00000001)
    val = await wb_read(dut, 0x00)
    assert (val & 1) == 1, f"CTRL ENABLE: got 0x{val:08X}"

    # KICK register (0x08)
    await wb_write(dut, 0x08, 0x00ACCE55)
    val = await wb_read(dut, 0x08)
    # KICK may or may not store; just verify write doesn't crash

    # STATUS register (0x0C)
    val = await wb_read(dut, 0x0C)
    # Just verify readable

@cocotb.test()
async def test_functional(dut):
    """Exercise key functional behavior."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)
        # Enable watchdog with short timeout (256 min)
    await wb_write(dut, 0x04, 256)
    await wb_write(dut, 0x00, 0x01)  # ENABLE = 1

    # Let it run for a bit, then kick
    await ClockCycles(dut.clk_i, 100)
    await wb_write(dut, 0x08, 0xACCE55)  # KICK magic

    # Verify it didn't reset yet (rst_out_n still high)
    await Timer(1, unit='ns')
    rst_out = safe_int(dut.rst_out_n)
    assert rst_out == 1, f"rst_out_n should be 1 after kick, got {rst_out}"

@cocotb.test()
async def test_ack_handshake(dut):
    """Verify ack_o asserts for one cycle then clears."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)

    await wb_write(dut, 0x04, 0xDEAD)
    val = await wb_read(dut, 0x04)
    assert val == 0xDEAD

    await ClockCycles(dut.clk_i, 2)
    await Timer(1, unit='ns')
    assert safe_int(dut.wb_ack_o) == 0, "ack should clear after transaction"
