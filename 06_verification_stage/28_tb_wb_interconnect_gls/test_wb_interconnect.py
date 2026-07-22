"""
cocotb testbench for wb_interconnect — Wishbone B4 shared bus fabric
Tests: address decode, slave routing, read-data mux, ACK aggregation, default slave
"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from wb_driver import safe_int


async def reset_dut(dut, cycles=4):
    dut.rst_ni.value = 0
    await ClockCycles(dut.clk_i, cycles)
    dut.rst_ni.value = 1
    await ClockCycles(dut.clk_i, 2)


async def wb_init(dut):
    dut.m_wb_adr_i.value = 0
    dut.m_wb_dat_i.value = 0
    dut.m_wb_sel_i.value = 0
    dut.m_wb_we_i.value = 0
    dut.m_wb_stb_i.value = 0
    dut.m_wb_cyc_i.value = 0
    # Init all slave ack/data inputs
    for i in range(12):
        getattr(dut, f"s{i}_wb_ack_i").value = 0
        getattr(dut, f"s{i}_wb_dat_i").value = 0


@cocotb.test()
async def test_reset(dut):
    """Verify reset clears m_wb_dat_o."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await ClockCycles(dut.clk_i, 2)
    dut.rst_ni.value = 0
    await ClockCycles(dut.clk_i, 4)
    await Timer(1, unit='ns')
    assert safe_int(dut.m_wb_dat_o) == 0
    dut.rst_ni.value = 1


@cocotb.test()
async def test_address_decode(dut):
    """Verify each address window routes to correct slave."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)

    # Test each peripheral address window
    tests = [
        (0x00000000, 0),  # SRAM
        (0x80000000, 1),  # UART
        (0x80001000, 2),  # I2C
        (0x80002000, 3),  # Motor PWM
        (0x80003000, 4),  # Ultrasonic
        (0x80004000, 5),  # GPIO
        (0x80005000, 6),  # Timer
        (0x80006000, 7),  # Watchdog
        (0x80007000, 8),  # Interrupt Ctrl
        (0x80008000, 9),  # RGB LED
        (0x80009000, 10), # Weight Detect
        (0x8000A000, 11), # Power Mgr
    ]

    for addr, slave_idx in tests:
        dut.m_wb_adr_i.value = addr
        dut.m_wb_cyc_i.value = 1
        dut.m_wb_stb_i.value = 1
        dut.m_wb_sel_i.value = 0xF
        await RisingEdge(dut.clk_i)
        await Timer(1, unit='ns')

        # Check that only the target slave gets CYC/STB
        for i in range(12):
            cyc = safe_int(getattr(dut, f"s{i}_wb_cyc_o"))
            stb = safe_int(getattr(dut, f"s{i}_wb_stb_o"))
            if i == slave_idx:
                assert cyc == 1, f"Addr 0x{addr:08X}: s{slave_idx} CYC should be 1"
                assert stb == 1, f"Addr 0x{addr:08X}: s{slave_idx} STB should be 1"
            else:
                assert cyc == 0, f"Addr 0x{addr:08X}: s{i} CYC should be 0"
                assert stb == 0, f"Addr 0x{addr:08X}: s{i} STB should be 0"

        dut.m_wb_cyc_i.value = 0
        dut.m_wb_stb_i.value = 0
        await ClockCycles(dut.clk_i, 2)


@cocotb.test()
async def test_read_data_mux(dut):
    """Verify slave read data is muxed to master."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)

    # Target GPIO (slave 5), drive s5_wb_dat_i = 0xDEADBEEF
    dut.m_wb_adr_i.value = 0x80004000
    dut.m_wb_cyc_i.value = 1
    dut.m_wb_stb_i.value = 1
    dut.m_wb_we_i.value = 0
    dut.m_wb_sel_i.value = 0xF
    dut.s5_wb_ack_i.value = 1
    dut.s5_wb_dat_i.value = 0xDEADBEEF

    await RisingEdge(dut.clk_i)
    await Timer(1, unit='ns')

    # m_wb_ack_o should be combinational (driven by s5_wb_ack_i)
    ack = safe_int(dut.m_wb_ack_o)
    assert ack == 1, f"m_wb_ack_o should assert when slave acks"

    # m_wb_dat_o registered on ack → appears after posedge
    await RisingEdge(dut.clk_i)
    await Timer(1, unit='ns')
    data = safe_int(dut.m_wb_dat_o)
    assert data == 0xDEADBEEF, f"Read data: expected 0xDEADBEEF, got 0x{data:08X}"

    dut.m_wb_cyc_i.value = 0
    dut.m_wb_stb_i.value = 0
    dut.s5_wb_ack_i.value = 0


@cocotb.test()
async def test_default_slave(dut):
    """Unmapped address gets ACK=1 (default slave), data=0."""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit='ns').start())
    await wb_init(dut)
    await reset_dut(dut)

    # Address 0xFFFF0000 — not mapped to any slave
    dut.m_wb_adr_i.value = 0xFFFF0000
    dut.m_wb_cyc_i.value = 1
    dut.m_wb_stb_i.value = 1
    dut.m_wb_sel_i.value = 0xF

    await RisingEdge(dut.clk_i)
    await Timer(1, unit='ns')

    # Default slave should ACK immediately
    ack = safe_int(dut.m_wb_ack_o)
    assert ack == 1, "Default slave should ACK unmapped address"

    # Default slave returns 0
    await RisingEdge(dut.clk_i)
    await Timer(1, unit='ns')
    data = safe_int(dut.m_wb_dat_o)
    assert data == 0, f"Default slave should return 0, got 0x{data:08X}"

    dut.m_wb_cyc_i.value = 0
    dut.m_wb_stb_i.value = 0
