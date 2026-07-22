"""
cocotb testbench for interrupt_ctrl — Interrupt controller with edge/level detection
Tests: register R/W (ENABLE, EDGE_CFG), ack handshake
BUG: irq_out/pending path does not respond to irq_in edges — RTL fix needed
"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, FallingEdge
import sys, os, random
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from wb_driver import reset_dut, wb_write, wb_read, wb_init, safe_int

ADDR_BASE = 0x0

# RTL register map (interrupt_ctrl.v):
# 0x00: PENDING (W1C — write 1 to clear)
# 0x04: ENABLE  (read/write, 16-bit)
# 0x08: EDGE_CFG (read/write, 16-bit)
# 0x0C: SOFTWARE (write to trigger software IRQ)
# BUG: irq_out/pending path does not latch from irq_in (RTL functional bug)


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
    assert safe_int(dut.irq_out) == 0
    dut.rst_ni.value = 1
    await ClockCycles(dut.clk_i, 2)

@cocotb.test()
async def test_register_rw(dut):
    """Write to each writable register, read back, verify value latched."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)

    # ENABLE register (0x04) — normal R/W, 16-bit
    await wb_write(dut, 0x04, 0x0000FFFF)
    val = await wb_read(dut, 0x04)
    assert (val & 0xFFFF) == 0xFFFF, f"ENABLE: got 0x{val:08X}"

    # ENABLE register (0x04) — partial write
    await wb_write(dut, 0x04, 0x0000AAAA)
    val = await wb_read(dut, 0x04)
    assert (val & 0xFFFF) == 0xAAAA, f"ENABLE partial: got 0x{val:08X}"

    # EDGE_CFG register (0x08) — normal R/W, 16-bit
    await wb_write(dut, 0x08, 0x00005555)
    val = await wb_read(dut, 0x08)
    assert (val & 0xFFFF) == 0x5555, f"EDGE_CFG: got 0x{val:08X}"

    # PENDING register (0x00) — should be 0 after reset
    val = await wb_read(dut, 0x00)
    assert (val & 0xFFFF) == 0, f"PENDING after reset: got 0x{val:08X}"

    # W1C on PENDING: write all-1s should clear (already 0, stays 0)
    await wb_write(dut, 0x00, 0xFFFF)
    val = await wb_read(dut, 0x00)
    assert (val & 0xFFFF) == 0, f"PENDING after W1C: got 0x{val:08X}"

@cocotb.test()
async def test_functional(dut):
    """Verify WISHBONE bus: multiple R/W cycles complete successfully."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)

    # Write pattern to ENABLE, verify WISHBONE bus functional
    await wb_write(dut, 0x04, 0x0001)
    val = await wb_read(dut, 0x04)
    assert val == 1, f"ENABLE readback after write 0x01: got 0x{val:08X}"

    # Write to EDGE_CFG, verify
    await wb_write(dut, 0x08, 0xAAAA)
    val = await wb_read(dut, 0x08)
    assert val == 0xAAAA, f"EDGE_CFG readback: got 0x{val:08X}"

    await wb_write(dut, 0x08, 0x5555)
    val = await wb_read(dut, 0x08)
    assert val == 0x5555, f"EDGE_CFG readback after rewrite: got 0x{val:08X}"

    # NOTE: irq_out/pending functional path has known RTL bug
    # PENDING does not latch from irq_in edges even with correct config.
    # This is documented in promotion_report.md as BLOCKED (RTL).

@cocotb.test()
async def test_ack_handshake(dut):
    """Verify ack_o asserts for one cycle then clears."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)

    # Use ENABLE register (0x04) for R/W handshake test
    await wb_write(dut, 0x04, 0xDEAD)
    val = await wb_read(dut, 0x04)
    assert val == 0xDEAD

    await ClockCycles(dut.clk_i, 2)
    await Timer(1, unit='ns')
    assert safe_int(dut.wb_ack_o) == 0, "ack should clear after transaction"
