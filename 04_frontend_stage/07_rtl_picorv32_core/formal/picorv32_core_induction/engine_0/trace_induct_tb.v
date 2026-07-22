`ifndef VERILATOR
module testbench;
  reg [4095:0] vcdfile;
  reg clock;
`else
module testbench(input clock, output reg genclock);
  initial genclock = 1;
`endif
  reg genclock = 1;
  reg [31:0] cycle = 0;
  reg [31:0] PI_pcpi_rd;
  reg [0:0] PI_mem_ready;
  reg [0:0] PI_pcpi_wait;
  reg [0:0] PI_pcpi_wr;
  reg [31:0] PI_irq;
  wire [0:0] PI_clk = clock;
  reg [0:0] PI_pcpi_ready;
  reg [31:0] PI_mem_rdata;
  reg [0:0] PI_resetn;
  picorv32 UUT (
    .pcpi_rd(PI_pcpi_rd),
    .mem_ready(PI_mem_ready),
    .pcpi_wait(PI_pcpi_wait),
    .pcpi_wr(PI_pcpi_wr),
    .irq(PI_irq),
    .clk(PI_clk),
    .pcpi_ready(PI_pcpi_ready),
    .mem_rdata(PI_mem_rdata),
    .resetn(PI_resetn)
  );
`ifndef VERILATOR
  initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
      $dumpfile(vcdfile);
      $dumpvars(0, testbench);
    end
    #5 clock = 0;
    while (genclock) begin
      #5 clock = 0;
      #5 clock = 1;
    end
  end
`endif
  initial begin
`ifndef VERILATOR
    #1;
`endif
    // UUT.$auto$async2sync.\cc:107:execute$3848  = 1'b0;
    // UUT.$auto$async2sync.\cc:107:execute$3872  = 1'b0;
    // UUT.$auto$async2sync.\cc:107:execute$3878  = 1'b0;
    // UUT.$auto$async2sync.\cc:107:execute$3884  = 1'b0;
    // UUT.$auto$async2sync.\cc:107:execute$3890  = 1'b0;
    // UUT.$auto$async2sync.\cc:107:execute$3896  = 1'b0;
    // UUT.$auto$async2sync.\cc:107:execute$3902  = 1'b0;
    // UUT.$auto$async2sync.\cc:107:execute$3908  = 1'b0;
    // UUT.$auto$async2sync.\cc:107:execute$3914  = 1'b0;
    // UUT.$auto$async2sync.\cc:107:execute$3944  = 1'b0;
    // UUT.$auto$async2sync.\cc:107:execute$3956  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$3864  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$3870  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$3876  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$3882  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$3888  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$3894  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$3900  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$3906  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$3912  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$3918  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$3924  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$3930  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$3936  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$3942  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$3948  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$3960  = 1'b0;
    UUT.alu_out_q = 32'b00000000000000000000000000000000;
    UUT.cached_ascii_instr = 64'b0000000000000000000000000000000000000000000000000000000000000000;
    UUT.cached_insn_imm = 32'b00000000000000000000000000000000;
    UUT.cached_insn_rd = 5'b00000;
    UUT.cached_insn_rs1 = 5'b00000;
    UUT.cached_insn_rs2 = 5'b00000;
    UUT.compressed_instr = 1'b0;
    UUT.count_cycle = 64'b1111111111111111111111111111111111111111111111111111111111101111;
    UUT.count_instr = 64'b0000000000000000000000000000000000000000000000000000000000000000;
    UUT.cpu_state = 8'b00001000;
    UUT.dbg_next = 1'b0;
    UUT.dbg_rs1val = 32'b00000000000000000000000000000000;
    UUT.dbg_rs1val_valid = 1'b0;
    UUT.dbg_rs2val = 32'b00000000000000000000000000000000;
    UUT.dbg_rs2val_valid = 1'b0;
    UUT.decoded_imm = 32'b00000100011111111010001101100100;
    UUT.decoded_imm_j = 32'b00000000000001110010100000000100;
    UUT.decoded_rd = 5'b00011;
    UUT.decoded_rs1 = 5'b00000;
    UUT.decoded_rs2 = 5'b00000;
    UUT.decoder_pseudo_trigger = 1'b0;
    UUT.decoder_pseudo_trigger_q = 1'b0;
    UUT.decoder_trigger = 1'b0;
    UUT.decoder_trigger_q = 1'b0;
    UUT.do_waitirq = 1'b0;
    UUT.eoi = 32'b00000000000000000000000000000000;
    UUT.instr_add = 1'b0;
    UUT.instr_addi = 1'b0;
    UUT.instr_and = 1'b0;
    UUT.instr_andi = 1'b0;
    UUT.instr_auipc = 1'b0;
    UUT.instr_beq = 1'b0;
    UUT.instr_bge = 1'b0;
    UUT.instr_bgeu = 1'b0;
    UUT.instr_blt = 1'b0;
    UUT.instr_bltu = 1'b0;
    UUT.instr_bne = 1'b0;
    UUT.instr_getq = 1'b0;
    UUT.instr_jal = 1'b0;
    UUT.instr_jalr = 1'b0;
    UUT.instr_lb = 1'b1;
    UUT.instr_lbu = 1'b0;
    UUT.instr_lh = 1'b0;
    UUT.instr_lhu = 1'b0;
    UUT.instr_lui = 1'b0;
    UUT.instr_lw = 1'b0;
    UUT.instr_maskirq = 1'b0;
    UUT.instr_or = 1'b0;
    UUT.instr_ori = 1'b0;
    UUT.instr_rdcycle = 1'b0;
    UUT.instr_rdcycleh = 1'b0;
    UUT.instr_rdinstr = 1'b0;
    UUT.instr_rdinstrh = 1'b0;
    UUT.instr_retirq = 1'b0;
    UUT.instr_sb = 1'b0;
    UUT.instr_setq = 1'b0;
    UUT.instr_sh = 1'b0;
    UUT.instr_sll = 1'b0;
    UUT.instr_slli = 1'b0;
    UUT.instr_slt = 1'b0;
    UUT.instr_slti = 1'b0;
    UUT.instr_sltiu = 1'b0;
    UUT.instr_sltu = 1'b0;
    UUT.instr_sra = 1'b0;
    UUT.instr_srai = 1'b0;
    UUT.instr_srl = 1'b0;
    UUT.instr_srli = 1'b0;
    UUT.instr_sub = 1'b0;
    UUT.instr_sw = 1'b0;
    UUT.instr_timer = 1'b0;
    UUT.instr_waitirq = 1'b0;
    UUT.instr_xor = 1'b0;
    UUT.instr_xori = 1'b0;
    UUT.is_alu_reg_imm = 1'b0;
    UUT.is_alu_reg_reg = 1'b1;
    UUT.is_beq_bne_blt_bge_bltu_bgeu = 1'b1;
    UUT.is_compare = 1'b0;
    UUT.is_jalr_addi_slti_sltiu_xori_ori_andi = 1'b0;
    UUT.is_lb_lh_lw_lbu_lhu = 1'b0;
    UUT.is_lbu_lhu_lw = 1'b0;
    UUT.is_lui_auipc_jal = 1'b0;
    UUT.is_lui_auipc_jal_jalr_addi_add_sub = 1'b0;
    UUT.is_sb_sh_sw = 1'b0;
    UUT.is_sll_srl_sra = 1'b0;
    UUT.is_slli_srli_srai = 1'b0;
    UUT.is_slti_blt_slt = 1'b0;
    UUT.is_sltiu_bltu_sltu = 1'b0;
    UUT.last_mem_la_addr = 32'b00000000000000000000000000000000;
    UUT.last_mem_la_read = 1'b0;
    UUT.last_mem_la_wdata = 32'b00000000000000000000000000000000;
    UUT.last_mem_la_write = 1'b0;
    UUT.last_mem_la_wstrb = 4'b1000;
    UUT.last_mem_nowait = 4'b0100;
    UUT.latched_branch = 1'b1;
    UUT.latched_compr = 1'b0;
    UUT.latched_is_lb = 1'b0;
    UUT.latched_is_lh = 1'b0;
    UUT.latched_is_lu = 1'b0;
    UUT.latched_rd = 5'b00000;
    UUT.latched_stalu = 1'b0;
    UUT.latched_store = 1'b1;
    UUT.mem_addr = 32'b10000000101101100100100100101000;
    UUT.mem_do_prefetch = 1'b1;
    UUT.mem_do_rdata = 1'b0;
    UUT.mem_do_rinst = 1'b0;
    UUT.mem_do_wdata = 1'b0;
    UUT.mem_instr = 1'b0;
    UUT.mem_rdata_q = 32'b00000000000000000000000000000000;
    UUT.mem_state = 2'b11;
    UUT.mem_valid = 1'b1;
    UUT.mem_wdata = 32'b00001000110110011010010010001111;
    UUT.mem_wordsize = 2'b00;
    UUT.mem_wstrb = 4'b0000;
    UUT.pcpi_insn = 32'b00000000000000000000000000000000;
    UUT.pcpi_valid = 1'b0;
    UUT.q_ascii_instr = 64'b0000000000000000000000000000000000000000000000000000000000000000;
    UUT.q_insn_imm = 32'b00000000000000000000000000000000;
    UUT.q_insn_rd = 5'b00000;
    UUT.q_insn_rs1 = 5'b00000;
    UUT.q_insn_rs2 = 5'b00000;
    UUT.reg_next_pc = 32'b01100011101111111010000100100000;
    UUT.reg_op1 = 32'b10000000101101100100100100101010;
    UUT.reg_op2 = 32'b10000000011100110001010010100101;
    UUT.reg_out = 32'b00000000000000000000000000000000;
    UUT.reg_pc = 32'b01111011011100000101000100100000;
    UUT.reg_sh = 5'b00000;
    UUT.trace_data = 36'b000000000000000000000000000000000000;
    UUT.trace_valid = 1'b0;
    UUT.trap = 1'b0;
    UUT.cpuregs[5'b00000] = 32'b01111111111111111111111110100000;
    UUT.cpuregs[5'b00001] = 32'b01111111111111111111111110100000;

    // state 0
    PI_pcpi_rd = 32'b00000000000000000000000000000000;
    PI_mem_ready = 1'b0;
    PI_pcpi_wait = 1'b0;
    PI_pcpi_wr = 1'b0;
    PI_irq = 32'b00000000000000000000000000000000;
    PI_pcpi_ready = 1'b0;
    PI_mem_rdata = 32'b00000000000000000000000000000000;
    PI_resetn = 1'b1;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b1;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b00000000000000000000000000000000;
      PI_resetn <= 1'b1;
    end

    // state 2
    if (cycle == 1) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b0;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b00000000000000000000000000000000;
      PI_resetn <= 1'b1;
    end

    // state 3
    if (cycle == 2) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b0;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b00000000000000000000000000000000;
      PI_resetn <= 1'b1;
    end

    // state 4
    if (cycle == 3) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b0;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b00000000000000000000000000000000;
      PI_resetn <= 1'b1;
    end

    // state 5
    if (cycle == 4) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b1;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b00000000000000000000000000000000;
      PI_resetn <= 1'b1;
    end

    // state 6
    if (cycle == 5) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b1;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b00110110010000000010000000000000;
      PI_resetn <= 1'b1;
    end

    // state 7
    if (cycle == 6) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b0;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b00000000000000000000000000000000;
      PI_resetn <= 1'b1;
    end

    // state 8
    if (cycle == 7) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b0;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b00000000000000000000000000000000;
      PI_resetn <= 1'b1;
    end

    // state 9
    if (cycle == 8) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b0;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b00110110010000000010000000000000;
      PI_resetn <= 1'b1;
    end

    // state 10
    if (cycle == 9) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b1;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b00110110010000000010000000000000;
      PI_resetn <= 1'b1;
    end

    // state 11
    if (cycle == 10) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b1;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b00000000000001010110000011100011;
      PI_resetn <= 1'b1;
    end

    // state 12
    if (cycle == 11) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b1;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b00000001101000001110000111100011;
      PI_resetn <= 1'b1;
    end

    // state 13
    if (cycle == 12) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b0;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b00000001000000000101000000000111;
      PI_resetn <= 1'b1;
    end

    // state 14
    if (cycle == 13) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b0;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b10000001101000001110000111100011;
      PI_resetn <= 1'b1;
    end

    // state 15
    if (cycle == 14) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b1;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b11000000000100000010100001110011;
      PI_resetn <= 1'b1;
    end

    // state 16
    if (cycle == 15) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b0;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b10000001000000000000000001100111;
      PI_resetn <= 1'b1;
    end

    // state 17
    if (cycle == 16) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b0;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b10000001101001010000000000000011;
      PI_resetn <= 1'b1;
    end

    // state 18
    if (cycle == 17) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b0;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b00000000000000000000000000000011;
      PI_resetn <= 1'b1;
    end

    // state 19
    if (cycle == 18) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b0;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b00000000000000000000000000000000;
      PI_resetn <= 1'b1;
    end

    // state 20
    if (cycle == 19) begin
      PI_pcpi_rd <= 32'b00000000000000000000000000000000;
      PI_mem_ready <= 1'b1;
      PI_pcpi_wait <= 1'b0;
      PI_pcpi_wr <= 1'b0;
      PI_irq <= 32'b00000000000000000000000000000000;
      PI_pcpi_ready <= 1'b0;
      PI_mem_rdata <= 32'b00000000000000000000000000000000;
      PI_resetn <= 1'b1;
    end

    genclock <= cycle < 20;
    cycle <= cycle + 1;
  end
endmodule
