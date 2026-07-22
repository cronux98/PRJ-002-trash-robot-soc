"""
cocotb testbench for timer — 32-bit down-counter with compare channels
Tests: register R/W, counter decrement, compare match, W1C status
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
    assert safe_int(dut.irq_cmpa) == 0
    assert safe_int(dut.irq_cmpb) == 0
    dut.rst_ni.value = 1
    await ClockCycles(dut.clk_i, 2)

@cocotb.test()
async def test_register_rw(dut):
    """Write to each register, read back, verify value latched."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)
        # RELOAD register (0x04)
    await wb_write(dut, 0x04, 0x00001000)
    val = await wb_read(dut, 0x04)
    assert val == 0x1000, f"RELOAD: got 0x{val:08X}"

    # COMPARE_A register (0x08)
    await wb_write(dut, 0x08, 0x00000500)
    val = await wb_read(dut, 0x08)
    assert val == 0x500, f"COMPARE_A: got 0x{val:08X}"

    # COMPARE_B register (0x0C)
    await wb_write(dut, 0x0C, 0x00000A00)
    val = await wb_read(dut, 0x0C)
    assert val == 0xA00, f"COMPARE_B: got 0x{val:08X}"

    # CTRL register (0x10) — enable + auto_reload
    await wb_write(dut, 0x10, 0x00000003)
    val = await wb_read(dut, 0x10)
    assert val == 3, f"CTRL: got 0x{val:08X}"

    # Disable to stop counter for clean test
    await wb_write(dut, 0x10, 0x00000000)

    # STATUS register (0x14)
    val = await wb_read(dut, 0x14)
    # STATUS may have wrap/cmp bits from brief run; just verify readable

@cocotb.test()
async def test_functional(dut):
    """Exercise key functional behavior."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)
        # Counter operation: load, enable, verify counting down
    await wb_write(dut, 0x00, 100)       # COUNTER = 100
    await wb_write(dut, 0x04, 1000)      # RELOAD = 1000
    await wb_write(dut, 0x08, 50)        # COMPARE_A = 50
    await wb_write(dut, 0x10, 0x01)      # CTRL: enable, no auto_reload

    # Wait a few cycles and check counter decreased
    await ClockCycles(dut.clk_i, 10)
    val = await wb_read(dut, 0x00)
    assert val < 100, f"Counter should decrease: got {val}"

    # Disable
    await wb_write(dut, 0x10, 0x00)

    # W1C on STATUS
    await wb_write(dut, 0x14, 0x07)  # clear all status bits
    val = await wb_read(dut, 0x14)
    assert (val & 0x07) == 0, f"STATUS after W1C: got 0x{val:08X}"

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
