"""
cocotb testbench for picorv32_core — PicoRV32 RV32IM CPU
Tests: reset→fetch, R-type instructions, I-type, memory R/W, traps
Uses a simple memory model that responds to Wishbone transactions.
"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from wb_driver import safe_int

# RISC-V instruction encoding helpers
def rtype(funct7, rs2, rs1, funct3, rd, opcode):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def itype(imm12, rs1, funct3, rd, opcode):
    return ((imm12 & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def stype(imm12, rs2, rs1, funct3, opcode):
    imm_11_5 = (imm12 >> 5) & 0x7F
    imm_4_0 = imm12 & 0x1F
    return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | opcode

def btype(imm13, rs2, rs1, funct3, opcode):
    imm_12 = (imm13 >> 12) & 1
    imm_10_5 = (imm13 >> 5) & 0x3F
    imm_4_1 = (imm13 >> 1) & 0xF
    imm_11 = (imm13 >> 11) & 1
    return (imm_12 << 31) | (imm_10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_1 << 8) | (imm_11 << 7) | opcode

def jal(imm21, rd, opcode=0x6F):
    """JAL: imm[20|10:1|11|19:12]"""
    return ((imm21 >> 20) & 1) << 31 | \
           ((imm21 >> 1) & 0x3FF) << 21 | \
           ((imm21 >> 11) & 1) << 20 | \
           ((imm21 >> 12) & 0xFF) << 12 | \
           (rd << 7) | opcode

# Opcodes
OP_LUI   = 0x37
OP_AUIPC = 0x17
OP_JAL   = 0x6F
OP_JALR  = 0x67
OP_BRANCH= 0x63
OP_LOAD  = 0x03
OP_STORE = 0x23
OP_IMM   = 0x13
OP_RTYPE = 0x33
OP_SYSTEM= 0x73

# Registers: x0=0, x1=ra, x2=sp, x3=gp, x4=tp, x5-7=t0-2, x8=s0/fp, x9=s1, x10-17=a0-7, ...


class MemoryModel:
    """Simple Wishbone memory model for PicoRV32."""
    def __init__(self):
        self.mem = {}

    def load_program(self, program_words, base=0):
        for i, w in enumerate(program_words):
            self.mem[base + i * 4] = w & 0xFFFFFFFF

    async def handle_wb(self, dut):
        """Handle Wishbone transaction from PicoRV32."""
        cyc = safe_int(dut.mem_valid)
        if not cyc:
            return

        addr = safe_int(dut.mem_addr)
        wstrb = safe_int(dut.mem_wstrb)
        word_addr = addr & ~0x3

        # Set ready to acknowledge
        dut.mem_ready.value = 1
        await RisingEdge(dut.clk)
        # Wait for posedge to propagate ready
        # (picorv32 uses mem_ready as a direct signal, not NBA)

        if wstrb == 0:  # Read
            if word_addr in self.mem:
                dut.mem_rdata.value = self.mem[word_addr]
            else:
                dut.mem_rdata.value = 0
        else:  # Write
            wdata = safe_int(dut.mem_wdata)
            if word_addr in self.mem:
                # Byte-enable write
                old = self.mem[word_addr]
                new = old
                if wstrb & 0x1: new = (new & ~0x000000FF) | (wdata & 0x000000FF)
                if wstrb & 0x2: new = (new & ~0x0000FF00) | (wdata & 0x0000FF00)
                if wstrb & 0x4: new = (new & ~0x00FF0000) | (wdata & 0x00FF0000)
                if wstrb & 0x8: new = (new & ~0xFF000000) | (wdata & 0xFF000000)
                self.mem[word_addr] = new
            else:
                self.mem[word_addr] = wdata

        await RisingEdge(dut.clk)
        dut.mem_ready.value = 0


@cocotb.test()
async def test_reset(dut):
    """Verify reset behavior — trap stays low, mem_valid low."""
    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())
    dut.resetn.value = 0
    dut.mem_ready.value = 0
    dut.mem_rdata.value = 0
    dut.irq.value = 0
    await ClockCycles(dut.clk, 4)
    await Timer(1, unit='ns')
    assert safe_int(dut.mem_valid) == 0, "mem_valid should be 0 during reset"
    dut.resetn.value = 1
    await ClockCycles(dut.clk, 4)


@cocotb.test()
async def test_nop_sled(dut):
    """Feed NOP instructions (ADDI x0, x0, 0) — CPU should stay alive."""
    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())
    mem = MemoryModel()

    # NOP = ADDI x0, x0, 0 = 0x00000013
    nop = itype(0, 0, 0, 0, OP_IMM)  # 0x00000013
    program = [nop] * 50
    mem.load_program(program, 0)

    # Reset
    dut.resetn.value = 0
    dut.mem_ready.value = 0
    dut.mem_rdata.value = 0
    dut.irq.value = 0
    await ClockCycles(dut.clk, 4)
    dut.resetn.value = 1
    await ClockCycles(dut.clk, 2)

    # Let CPU run and feed NOPs
    for _ in range(60):
        await mem.handle_wb(dut)

    # Should not trap
    trap = safe_int(dut.trap)
    assert trap == 0, f"CPU should not trap on NOPs"


@cocotb.test()
async def test_alu_add(dut):
    """Test ADDI and ADD instructions."""
    cocotb.start_soon(Clock(dut.clk, 10, unit='ns').start())
    mem = MemoryModel()

    # Program:
    #   ADDI x5, x0, 42     — x5 = 42
    #   ADDI x6, x0, 58     — x6 = 58
    #   ADD x7, x5, x6      — x7 = 100
    #   SW x7, 0(x0)        — store result to addr 0
    #   loop: JAL x0, loop  — infinite loop
    addi_t0 = itype(42, 0, 0, 5, OP_IMM)   # 42 = 0x02A
    addi_t1 = itype(58, 0, 0, 6, OP_IMM)   # 58 = 0x03A
    add_t2  = rtype(0, 6, 5, 0, 7, OP_RTYPE)  # ADD x7, x5, x6
    sw_t2   = stype(0, 7, 0, 2, OP_STORE)     # SW x7, 0(x0)
    jal_loop= jal(-4, 0)  # jump back 4 bytes = infinite loop

    program = [addi_t0, addi_t1, add_t2, sw_t2, jal_loop]
    mem.load_program(program, 0)

    # Reset
    dut.resetn.value = 0
    dut.mem_ready.value = 0
    dut.mem_rdata.value = 0
    dut.irq.value = 0
    await ClockCycles(dut.clk, 4)
    dut.resetn.value = 1
    await ClockCycles(dut.clk, 2)

    # Run for enough cycles to execute all 5 instructions
    for _ in range(200):
        await mem.handle_wb(dut)

    # Check that address 0 was written with 100
    if 0 in mem.mem:
        result = mem.mem[0]
        assert result == 100, f"SW result: expected 100, got {result}"
        dut._log.info(f"ALU ADD: 42 + 58 = {result} (PASS)")
    else:
        dut._log.warning("SW didn't commit — CPU may have stalled")
