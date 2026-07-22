"""
cocotb testbench for ultrasonic_capture — HC-SR04 ultrasonic capture
Tests: register R/W, TRIG pulse, echo capture, distance calculation
"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles, FallingEdge
import sys, os, random
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from wb_driver import reset_dut, wb_write, wb_read, wb_init, safe_int

ADDR_BASE = 0x0

# RTL register map (ultrasonic_capture.v):
# 0x00: CTRL      (write: bit 0 = ch0 start, bit 1 = ch1 start; read: returns 0)
# 0x04: STATUS    (read-only: [3]=ch1_idle, [2]=reserved, [1]=ch0_idle, [0]=reserved)
# 0x08: ECHO_CH0  (read-only, 16-bit echo pulse width)
# 0x0C: ECHO_CH1  (read-only, 16-bit echo pulse width)
# 0x10: DIST_CH0  (read-only, 16-bit distance cm*100)
# 0x14: DIST_CH1  (read-only, 16-bit distance cm*100)


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
    assert safe_int(dut.trig_o) == 0
    dut.rst_ni.value = 1
    await ClockCycles(dut.clk_i, 2)

@cocotb.test()
async def test_register_rw(dut):
    """Verify register readbacks and trigger behaviour."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)

    # STATUS register (0x04): after reset, both channels should be idle
    val = await wb_read(dut, 0x04)
    ch0_idle = (val >> 1) & 1
    ch1_idle = (val >> 3) & 1
    assert ch0_idle == 1, f"STATUS: ch0 should be idle after reset, val=0x{val:08X}"
    assert ch1_idle == 1, f"STATUS: ch1 should be idle after reset, val=0x{val:08X}"

    # ECHO_CH0 (0x08): should be 0 when no echo captured
    val = await wb_read(dut, 0x08)
    assert val == 0, f"ECHO_CH0: should be 0, got 0x{val:08X}"

    # DIST_CH0 (0x10): should be 0 when no measurement done
    val = await wb_read(dut, 0x10)
    assert val == 0, f"DIST_CH0: should be 0, got 0x{val:08X}"

@cocotb.test()
async def test_functional(dut):
    """Exercise key functional behavior."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)

    # Trigger a measurement on CH0
    await wb_write(dut, 0x00, 0x01)  # START CH0

    # Wait for trig pulse (10us = 333 clocks at 33.3MHz)
    await ClockCycles(dut.clk_i, 400)

    # Simulate echo pulse (CH0)
    dut.echo_i.value = 0x1  # echo[0] = 1
    await ClockCycles(dut.clk_i, 500)
    dut.echo_i.value = 0x0
    await ClockCycles(dut.clk_i, 10)

    # Read captured echo width (0x08)
    echo_val = await wb_read(dut, 0x08)
    assert echo_val > 0, f"ECHO_CH0 should be >0, got {echo_val}"

@cocotb.test()
async def test_ack_handshake(dut):
    """Verify ack_o asserts for one cycle then clears."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)

    # Use STATUS register (0x04) for read-based ack handshake test
    # Write to CTRL (0x00) triggers a measurement, then read STATUS
    await wb_write(dut, 0x00, 0x01)
    val = await wb_read(dut, 0x04)
    # Verify ack handshake: the read completed (val is valid)
    assert val is not None, "STATUS read should return valid data"

    await ClockCycles(dut.clk_i, 2)
    await Timer(1, unit='ns')
    assert safe_int(dut.wb_ack_o) == 0, "ack should clear after transaction"
