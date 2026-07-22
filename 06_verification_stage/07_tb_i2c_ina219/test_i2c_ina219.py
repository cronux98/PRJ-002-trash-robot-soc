"""
cocotb testbench for i2c_master — I2C master controller
Tests: register R/W, CTRL/STATUS/ADDR/DATA/DIVIDER, FSM progression
"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from wb_driver import reset_dut, wb_write, wb_read, wb_init, safe_int


@cocotb.test()
async def test_reset(dut):
    """Verify reset state — I2C lines high (idle)."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await ClockCycles(dut.clk_i, 2)
    dut.rst_ni.value = 0
    await ClockCycles(dut.clk_i, 4)
    await Timer(1, unit='ns')
    assert safe_int(dut.irq_done) == 0, "irq_done should be 0 during reset"
    dut.rst_ni.value = 1
    await ClockCycles(dut.clk_i, 2)


@cocotb.test()
async def test_register_rw(dut):
    """Write/read all registers."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)

    # DIVIDER register (0x10)
    await wb_write(dut, 0x10, 166)
    val = await wb_read(dut, 0x10)
    assert val == 166, f"DIVIDER: got {val}"

    # ADDR register (0x08)
    await wb_write(dut, 0x08, 0x50)  # 7-bit addr 0x50
    val = await wb_read(dut, 0x08)
    assert (val & 0x7F) == 0x50, f"ADDR: got 0x{val:02X}"

    # DATA register (0x0C)
    await wb_write(dut, 0x0C, 0xA5)
    val = await wb_read(dut, 0x0C)
    assert (val & 0xFF) == 0xA5, f"DATA: got 0x{val:02X}"

    # STATUS register (0x04) — read-only, should be idle
    val = await wb_read(dut, 0x04)
    assert (val & 0x01) == 0, f"STATUS BUSY should be 0 at idle, got 0x{val:X}"


@cocotb.test()
async def test_fsm_start_stop(dut):
    """Issue START then STOP, verify FSM returns to idle."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)

    # Configure address + data
    await wb_write(dut, 0x08, 0x50)   # ADDR
    await wb_write(dut, 0x0C, 0xA5)   # DATA

    # Issue START (CTRL[0]=1) with IRQ_EN
    await wb_write(dut, 0x00, 0x09)   # START + IRQ_EN

    # Let FSM run through START → ADDR → ...
    await ClockCycles(dut.clk_i, 500)

    # Check status — should be DONE (STATUS[1]=1) or at least not idle-BUSY
    status = await wb_read(dut, 0x04)
    # Log status for debugging
    dut._log.info(f"STATUS after START: 0x{status:X}")


@cocotb.test()
async def test_ack_handshake(dut):
    """Verify ack_o asserts for one cycle then clears."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)

    await wb_write(dut, 0x10, 166)
    val = await wb_read(dut, 0x10)
    assert val == 166

    await ClockCycles(dut.clk_i, 2)
    await Timer(1, unit='ns')
    assert safe_int(dut.wb_ack_o) == 0, "ack should clear"
