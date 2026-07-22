// Module: trash_robot_soc
// Description: Top-level SoC for IP-005 v6 Trash Robot ASIC
// Source: IP-005 v6 Architecture §1-3
// Version: v6 — PicoRV32 + 13 Wishbone peripherals (3× I2C) on WB B4 bus
// Clock: 33.3 MHz single domain, Reset: async assert / sync deassert
// Changelog: v5→v6: removed rgb_led_pwm, added i2c_ina219+i2c_ds3231, wb 13 slaves
/* verilator lint_off PINCONNECTEMPTY */
/* verilator lint_off PINMISSING */
/* verilator lint_off TIMESCALEMOD */

module trash_robot_soc (
    input  wire        clk_i,
    input  wire        rst_ni,

    // UART pins
    output wire        uart_tx,
    input  wire        uart_rx,

    // I2C pins (shared bus for all 3 I2C devices)
    inout  wire        i2c_scl,
    inout  wire        i2c_sda,

    // Motor PWM outputs
    output wire [3:0]  motor_pwm_a,
    output wire [3:0]  motor_pwm_b,
    input  wire [3:0]  motor_fault,

    // HC-SR04 ultrasonic
    output wire [1:0]  trig,
    input  wire [1:0]  echo,

    // GPIO
    input  wire [11:0] gpio_i,
    output wire [11:0] gpio_o,
    output wire [11:0] gpio_oe,

    // Watchdog reset (to power_mgr)
    output wire        wdt_rst_n,

    // System reset output (from power_mgr)
    output wire        sys_rst_n_o
);

    // =====================================================================
    // Internal Wishbone bus signals
    // =====================================================================
    // CPU Master → Interconnect
    wire [31:0] cpu_wb_adr;
    wire [31:0] cpu_wb_dat_o;
    wire [31:0] cpu_wb_dat_i;
    wire [ 3:0] cpu_wb_sel;
    wire        cpu_wb_we;
    wire        cpu_wb_stb;
    wire        cpu_wb_cyc;
    wire        cpu_wb_ack;

    // Interconnect → Slaves (13 slaves)
    wire [31:0] s_wb_adr  [0:12];
    wire [31:0] s_wb_dat_o[0:12];
    wire [31:0] s_wb_dat_i[0:12];
    wire [ 3:0] s_wb_sel  [0:12];
    wire        s_wb_we   [0:12];
    wire        s_wb_stb  [0:12];
    wire        s_wb_cyc  [0:12];
    wire        s_wb_ack  [0:12];

    // Interrupts
    wire [15:0] irq_sources;
    wire        cpu_irq;

    // Watchdog reset
    wire wdt_rst_n_int;

    // Power manager
    wire sys_rst_n_int;
    wire clk_en;

    // =====================================================================
    // PicoRV32 CPU (REUSE_GITHUB)
    // =====================================================================
    picorv32 #(
        .ENABLE_COUNTERS(1),
        .ENABLE_COUNTERS64(0),
        .ENABLE_REGS_16_31(1),
        .ENABLE_REGS_DUALPORT(1),
        .TWO_STAGE_SHIFT(1),
        .BARREL_SHIFTER(0),
        .TWO_CYCLE_COMPARE(0),
        .TWO_CYCLE_ALU(0),
        .COMPRESSED_ISA(0),
        .CATCH_MISALIGN(1),
        .CATCH_ILLINSN(1),
        .ENABLE_PCPI(0),
        .ENABLE_MUL(1),
        .ENABLE_FAST_MUL(1),
        .ENABLE_DIV(1),
        .ENABLE_IRQ(1),
        .ENABLE_IRQ_QREGS(0),
        .ENABLE_IRQ_TIMER(0),
        .ENABLE_TRACE(0),
        .REGS_INIT_ZERO(1),
        .MASKED_IRQ(32'h0000_0000),
        .LATCHED_IRQ(32'hffff_ffff),
        .PROGADDR_RESET(32'h0000_0000),
        .PROGADDR_IRQ(32'h0000_0010),
        .STACKADDR(32'h0000_01FF)
    ) picorv32_inst (
        .clk         (clk_i),
        .resetn      (sys_rst_n_int),
        .trap        (),
        .mem_valid   (cpu_wb_cyc),
        .mem_instr   (),
        .mem_ready   (cpu_wb_ack),
        .mem_addr    (cpu_wb_adr),
        .mem_wdata   (cpu_wb_dat_o),
        .mem_rdata   (cpu_wb_dat_i),
        .mem_wstrb   (cpu_wb_sel),
        .irq         ({31'd0, cpu_irq}),
        .eoi         ()
    );

    assign cpu_wb_stb = cpu_wb_cyc;
    assign cpu_wb_we  = (cpu_wb_sel != 4'h0) ? 1'b1 : 1'b0;

    // =====================================================================
    // Wishbone Interconnect (REUSE_INTERNAL, v6: 13 slaves)
    // =====================================================================
    wb_interconnect wb_inst (
        .clk_i       (clk_i),
        .rst_ni      (sys_rst_n_int),
        .m_wb_adr_i  (cpu_wb_adr),
        .m_wb_dat_i  (cpu_wb_dat_o),
        .m_wb_dat_o  (cpu_wb_dat_i),
        .m_wb_sel_i  (cpu_wb_sel),
        .m_wb_we_i   (cpu_wb_we),
        .m_wb_stb_i  (cpu_wb_stb),
        .m_wb_cyc_i  (cpu_wb_cyc),
        .m_wb_ack_o  (cpu_wb_ack),
        // Slaves 0-12
        .s0_wb_adr_o (s_wb_adr[0]),  .s0_wb_dat_o (s_wb_dat_o[0]),  .s0_wb_dat_i (s_wb_dat_i[0]),
        .s0_wb_sel_o (s_wb_sel[0]),  .s0_wb_we_o  (s_wb_we[0]),   .s0_wb_stb_o (s_wb_stb[0]),
        .s0_wb_cyc_o (s_wb_cyc[0]),  .s0_wb_ack_i (s_wb_ack[0]),
        .s1_wb_adr_o (s_wb_adr[1]),  .s1_wb_dat_o (s_wb_dat_o[1]),  .s1_wb_dat_i (s_wb_dat_i[1]),
        .s1_wb_sel_o (s_wb_sel[1]),  .s1_wb_we_o  (s_wb_we[1]),   .s1_wb_stb_o (s_wb_stb[1]),
        .s1_wb_cyc_o (s_wb_cyc[1]),  .s1_wb_ack_i (s_wb_ack[1]),
        .s2_wb_adr_o (s_wb_adr[2]),  .s2_wb_dat_o (s_wb_dat_o[2]),  .s2_wb_dat_i (s_wb_dat_i[2]),
        .s2_wb_sel_o (s_wb_sel[2]),  .s2_wb_we_o  (s_wb_we[2]),   .s2_wb_stb_o (s_wb_stb[2]),
        .s2_wb_cyc_o (s_wb_cyc[2]),  .s2_wb_ack_i (s_wb_ack[2]),
        .s3_wb_adr_o (s_wb_adr[3]),  .s3_wb_dat_o (s_wb_dat_o[3]),  .s3_wb_dat_i (s_wb_dat_i[3]),
        .s3_wb_sel_o (s_wb_sel[3]),  .s3_wb_we_o  (s_wb_we[3]),   .s3_wb_stb_o (s_wb_stb[3]),
        .s3_wb_cyc_o (s_wb_cyc[3]),  .s3_wb_ack_i (s_wb_ack[3]),
        .s4_wb_adr_o (s_wb_adr[4]),  .s4_wb_dat_o (s_wb_dat_o[4]),  .s4_wb_dat_i (s_wb_dat_i[4]),
        .s4_wb_sel_o (s_wb_sel[4]),  .s4_wb_we_o  (s_wb_we[4]),   .s4_wb_stb_o (s_wb_stb[4]),
        .s4_wb_cyc_o (s_wb_cyc[4]),  .s4_wb_ack_i (s_wb_ack[4]),
        .s5_wb_adr_o (s_wb_adr[5]),  .s5_wb_dat_o (s_wb_dat_o[5]),  .s5_wb_dat_i (s_wb_dat_i[5]),
        .s5_wb_sel_o (s_wb_sel[5]),  .s5_wb_we_o  (s_wb_we[5]),   .s5_wb_stb_o (s_wb_stb[5]),
        .s5_wb_cyc_o (s_wb_cyc[5]),  .s5_wb_ack_i (s_wb_ack[5]),
        .s6_wb_adr_o (s_wb_adr[6]),  .s6_wb_dat_o (s_wb_dat_o[6]),  .s6_wb_dat_i (s_wb_dat_i[6]),
        .s6_wb_sel_o (s_wb_sel[6]),  .s6_wb_we_o  (s_wb_we[6]),   .s6_wb_stb_o (s_wb_stb[6]),
        .s6_wb_cyc_o (s_wb_cyc[6]),  .s6_wb_ack_i (s_wb_ack[6]),
        .s7_wb_adr_o (s_wb_adr[7]),  .s7_wb_dat_o (s_wb_dat_o[7]),  .s7_wb_dat_i (s_wb_dat_i[7]),
        .s7_wb_sel_o (s_wb_sel[7]),  .s7_wb_we_o  (s_wb_we[7]),   .s7_wb_stb_o (s_wb_stb[7]),
        .s7_wb_cyc_o (s_wb_cyc[7]),  .s7_wb_ack_i (s_wb_ack[7]),
        .s8_wb_adr_o (s_wb_adr[8]),  .s8_wb_dat_o (s_wb_dat_o[8]),  .s8_wb_dat_i (s_wb_dat_i[8]),
        .s8_wb_sel_o (s_wb_sel[8]),  .s8_wb_we_o  (s_wb_we[8]),   .s8_wb_stb_o (s_wb_stb[8]),
        .s8_wb_cyc_o (s_wb_cyc[8]),  .s8_wb_ack_i (s_wb_ack[8]),
        .s9_wb_adr_o (s_wb_adr[9]),  .s9_wb_dat_o (s_wb_dat_o[9]),  .s9_wb_dat_i (s_wb_dat_i[9]),
        .s9_wb_sel_o (s_wb_sel[9]),  .s9_wb_we_o  (s_wb_we[9]),   .s9_wb_stb_o (s_wb_stb[9]),
        .s9_wb_cyc_o (s_wb_cyc[9]),  .s9_wb_ack_i (s_wb_ack[9]),
        .s10_wb_adr_o(s_wb_adr[10]), .s10_wb_dat_o(s_wb_dat_o[10]), .s10_wb_dat_i(s_wb_dat_i[10]),
        .s10_wb_sel_o(s_wb_sel[10]), .s10_wb_we_o (s_wb_we[10]),  .s10_wb_stb_o(s_wb_stb[10]),
        .s10_wb_cyc_o(s_wb_cyc[10]), .s10_wb_ack_i(s_wb_ack[10]),
        .s11_wb_adr_o(s_wb_adr[11]), .s11_wb_dat_o(s_wb_dat_o[11]), .s11_wb_dat_i(s_wb_dat_i[11]),
        .s11_wb_sel_o(s_wb_sel[11]), .s11_wb_we_o (s_wb_we[11]),  .s11_wb_stb_o(s_wb_stb[11]),
        .s11_wb_cyc_o(s_wb_cyc[11]), .s11_wb_ack_i(s_wb_ack[11]),
        .s12_wb_adr_o(s_wb_adr[12]), .s12_wb_dat_o(s_wb_dat_o[12]), .s12_wb_dat_i(s_wb_dat_i[12]),
        .s12_wb_sel_o(s_wb_sel[12]), .s12_wb_we_o (s_wb_we[12]),  .s12_wb_stb_o(s_wb_stb[12]),
        .s12_wb_cyc_o(s_wb_cyc[12]), .s12_wb_ack_i(s_wb_ack[12])
    );

    // =====================================================================
    // Slave 0: SRAM 512B
    // =====================================================================
    sram_512b sram_inst (
        .clk_i    (clk_i),
        .rst_ni   (sys_rst_n_int),
        .wb_adr_i (s_wb_adr[0]),
        .wb_dat_i (s_wb_dat_o[0]),
        .wb_dat_o (s_wb_dat_i[0]),
        .wb_sel_i (s_wb_sel[0]),
        .wb_we_i  (s_wb_we[0]),
        .wb_stb_i (s_wb_stb[0]),
        .wb_cyc_i (s_wb_cyc[0]),
        .wb_ack_o (s_wb_ack[0])
    );

    // =====================================================================
    // Slave 1: UART
    // =====================================================================
    uart uart_inst (
        .clk_i    (clk_i),
        .rst_ni   (sys_rst_n_int),
        .wb_adr_i (s_wb_adr[1]),
        .wb_dat_i (s_wb_dat_o[1]),
        .wb_dat_o (s_wb_dat_i[1]),
        .wb_sel_i (s_wb_sel[1]),
        .wb_we_i  (s_wb_we[1]),
        .wb_stb_i (s_wb_stb[1]),
        .wb_cyc_i (s_wb_cyc[1]),
        .wb_ack_o (s_wb_ack[1]),
        .uart_tx  (uart_tx),
        .uart_rx  (uart_rx),
        .irq_tx   (irq_sources[1]),
        .irq_rx   (irq_sources[0])
    );

    // =====================================================================
    // Slave 2: I2C HX711 (weight sensor)
    // =====================================================================
    i2c_master i2c_hx711_inst (
        .clk_i    (clk_i),
        .rst_ni   (sys_rst_n_int),
        .wb_adr_i (s_wb_adr[2]),
        .wb_dat_i (s_wb_dat_o[2]),
        .wb_dat_o (s_wb_dat_i[2]),
        .wb_sel_i (s_wb_sel[2]),
        .wb_we_i  (s_wb_we[2]),
        .wb_stb_i (s_wb_stb[2]),
        .wb_cyc_i (s_wb_cyc[2]),
        .wb_ack_o (s_wb_ack[2]),
        .scl      (i2c_scl),
        .sda      (i2c_sda),
        .irq_done (irq_sources[2])
    );

    // =====================================================================
    // Slave 3: Motor PWM
    // =====================================================================
    motor_pwm motor_inst (
        .clk_i     (clk_i),
        .rst_ni    (sys_rst_n_int),
        .wb_adr_i  (s_wb_adr[3]),
        .wb_dat_i  (s_wb_dat_o[3]),
        .wb_dat_o  (s_wb_dat_i[3]),
        .wb_sel_i  (s_wb_sel[3]),
        .wb_we_i   (s_wb_we[3]),
        .wb_stb_i  (s_wb_stb[3]),
        .wb_cyc_i  (s_wb_cyc[3]),
        .wb_ack_o  (s_wb_ack[3]),
        .pwm_a     (motor_pwm_a),
        .pwm_b     (motor_pwm_b),
        .fault_i   (motor_fault),
        .irq_fault (irq_sources[3])
    );

    // =====================================================================
    // Slave 4: Ultrasonic Capture
    // =====================================================================
    ultrasonic_capture ultra_inst (
        .clk_i    (clk_i),
        .rst_ni   (sys_rst_n_int),
        .wb_adr_i (s_wb_adr[4]),
        .wb_dat_i (s_wb_dat_o[4]),
        .wb_dat_o (s_wb_dat_i[4]),
        .wb_sel_i (s_wb_sel[4]),
        .wb_we_i  (s_wb_we[4]),
        .wb_stb_i (s_wb_stb[4]),
        .wb_cyc_i (s_wb_cyc[4]),
        .wb_ack_o (s_wb_ack[4]),
        .trig_o   (trig),
        .echo_i   (echo),
        .irq_done (irq_sources[4])
    );

    // =====================================================================
    // Slave 5: GPIO
    // =====================================================================
    gpio gpio_inst (
        .clk_i    (clk_i),
        .rst_ni   (sys_rst_n_int),
        .wb_adr_i (s_wb_adr[5]),
        .wb_dat_i (s_wb_dat_o[5]),
        .wb_dat_o (s_wb_dat_i[5]),
        .wb_sel_i (s_wb_sel[5]),
        .wb_we_i  (s_wb_we[5]),
        .wb_stb_i (s_wb_stb[5]),
        .wb_cyc_i (s_wb_cyc[5]),
        .wb_ack_o (s_wb_ack[5]),
        .gpio_i   (gpio_i),
        .gpio_o   (gpio_o),
        .gpio_oe  (gpio_oe),
        .irq_pin  (irq_sources[5])
    );

    // =====================================================================
    // Slave 6: Timer
    // =====================================================================
    timer timer_inst (
        .clk_i     (clk_i),
        .rst_ni    (sys_rst_n_int),
        .wb_adr_i  (s_wb_adr[6]),
        .wb_dat_i  (s_wb_dat_o[6]),
        .wb_dat_o  (s_wb_dat_i[6]),
        .wb_sel_i  (s_wb_sel[6]),
        .wb_we_i   (s_wb_we[6]),
        .wb_stb_i  (s_wb_stb[6]),
        .wb_cyc_i  (s_wb_cyc[6]),
        .wb_ack_o  (s_wb_ack[6]),
        .irq_cmpa  (irq_sources[6]),
        .irq_cmpb  (irq_sources[7])
    );

    // =====================================================================
    // Slave 7: Watchdog
    // =====================================================================
    watchdog wdt_inst (
        .clk_i     (clk_i),
        .rst_ni    (sys_rst_n_int),
        .wb_adr_i  (s_wb_adr[7]),
        .wb_dat_i  (s_wb_dat_o[7]),
        .wb_dat_o  (s_wb_dat_i[7]),
        .wb_sel_i  (s_wb_sel[7]),
        .wb_we_i   (s_wb_we[7]),
        .wb_stb_i  (s_wb_stb[7]),
        .wb_cyc_i  (s_wb_cyc[7]),
        .wb_ack_o  (s_wb_ack[7]),
        .irq_warn  (irq_sources[8]),
        .rst_out_n (wdt_rst_n_int)
    );

    // =====================================================================
    // Slave 8: Interrupt Controller
    // =====================================================================
    interrupt_ctrl intc_inst (
        .clk_i    (clk_i),
        .rst_ni   (sys_rst_n_int),
        .wb_adr_i (s_wb_adr[8]),
        .wb_dat_i (s_wb_dat_o[8]),
        .wb_dat_o (s_wb_dat_i[8]),
        .wb_sel_i (s_wb_sel[8]),
        .wb_we_i  (s_wb_we[8]),
        .wb_stb_i (s_wb_stb[8]),
        .wb_cyc_i (s_wb_cyc[8]),
        .wb_ack_o (s_wb_ack[8]),
        .irq_in   (irq_sources),
        .irq_out  (cpu_irq)
    );

    // =====================================================================
    // Slave 9: Weight Detect
    // =====================================================================
    weight_detect weight_inst (
        .clk_i      (clk_i),
        .rst_ni     (sys_rst_n_int),
        .wb_adr_i   (s_wb_adr[9]),
        .wb_dat_i   (s_wb_dat_o[9]),
        .wb_dat_o   (s_wb_dat_i[9]),
        .wb_sel_i   (s_wb_sel[9]),
        .wb_we_i    (s_wb_we[9]),
        .wb_stb_i   (s_wb_stb[9]),
        .wb_cyc_i   (s_wb_cyc[9]),
        .wb_ack_o   (s_wb_ack[9]),
        .irq_thresh (irq_sources[9])
    );

    // =====================================================================
    // Slave 10: I2C INA219 (solar current/voltage)
    // =====================================================================
    i2c_master i2c_ina219_inst (
        .clk_i    (clk_i),
        .rst_ni   (sys_rst_n_int),
        .wb_adr_i (s_wb_adr[10]),
        .wb_dat_i (s_wb_dat_o[10]),
        .wb_dat_o (s_wb_dat_i[10]),
        .wb_sel_i (s_wb_sel[10]),
        .wb_we_i  (s_wb_we[10]),
        .wb_stb_i (s_wb_stb[10]),
        .wb_cyc_i (s_wb_cyc[10]),
        .wb_ack_o (s_wb_ack[10]),
        .scl      (i2c_scl),
        .sda      (i2c_sda),
        .irq_done (irq_sources[10])
    );

    // =====================================================================
    // Slave 11: Power Manager
    // =====================================================================
    power_mgr pm_inst (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .wb_adr_i   (s_wb_adr[11]),
        .wb_dat_i   (s_wb_dat_o[11]),
        .wb_dat_o   (s_wb_dat_i[11]),
        .wb_sel_i   (s_wb_sel[11]),
        .wb_we_i    (s_wb_we[11]),
        .wb_stb_i   (s_wb_stb[11]),
        .wb_cyc_i   (s_wb_cyc[11]),
        .wb_ack_o   (s_wb_ack[11]),
        .ext_rst_n  (rst_ni),
        .wdt_rst_n  (wdt_rst_n_int),
        .sys_clk_i  (clk_i),
        .sys_rst_n_o(sys_rst_n_int),
        .clk_en_o   (clk_en)
    );

    // =====================================================================
    // Slave 12: I2C DS3231 (hardware RTC)
    // =====================================================================
    i2c_master i2c_ds3231_inst (
        .clk_i    (clk_i),
        .rst_ni   (sys_rst_n_int),
        .wb_adr_i (s_wb_adr[12]),
        .wb_dat_i (s_wb_dat_o[12]),
        .wb_dat_o (s_wb_dat_i[12]),
        .wb_sel_i (s_wb_sel[12]),
        .wb_we_i  (s_wb_we[12]),
        .wb_stb_i (s_wb_stb[12]),
        .wb_cyc_i (s_wb_cyc[12]),
        .wb_ack_o (s_wb_ack[12]),
        .scl      (i2c_scl),
        .sda      (i2c_sda),
        .irq_done (irq_sources[11])
    );

    assign sys_rst_n_o = sys_rst_n_int;
    assign wdt_rst_n   = wdt_rst_n_int;  // Bug #V6-001 fix: previously unassigned

endmodule
