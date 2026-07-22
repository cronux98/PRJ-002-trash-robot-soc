// Module: wb_interconnect
// Description: Wishbone B4 shared bus fabric — 1 master (PicoRV32) to 14 slaves
// Source: IP-005 v4 Architecture §4.2, REUSE_INTERNAL (BUG-004 fix)
// Version: v4 — 14 slaves, 4KB peripheral alignment, addr[31:12] decode, registered read-data

module wb_interconnect (
    input  wire        clk_i,
    input  wire        rst_ni,

    // Master side (from PicoRV32)
    input  wire [31:0] m_wb_adr_i,
    input  wire [31:0] m_wb_dat_i,
    output reg  [31:0] m_wb_dat_o,
    input  wire [ 3:0] m_wb_sel_i,
    input  wire        m_wb_we_i,
    input  wire        m_wb_stb_i,
    input  wire        m_wb_cyc_i,
    output wire        m_wb_ack_o,

    // Slave 0: sram_512b     [0x0000_0000]
    output wire [31:0] s0_wb_adr_o,
    output wire [31:0] s0_wb_dat_o,
    input  wire [31:0] s0_wb_dat_i,
    output wire [ 3:0] s0_wb_sel_o,
    output wire        s0_wb_we_o,
    output wire        s0_wb_stb_o,
    output wire        s0_wb_cyc_o,
    input  wire        s0_wb_ack_i,

    // Slave 1: uart          [0x8000_0000]
    output wire [31:0] s1_wb_adr_o,
    output wire [31:0] s1_wb_dat_o,
    input  wire [31:0] s1_wb_dat_i,
    output wire [ 3:0] s1_wb_sel_o,
    output wire        s1_wb_we_o,
    output wire        s1_wb_stb_o,
    output wire        s1_wb_cyc_o,
    input  wire        s1_wb_ack_i,

    // Slave 2: i2c_master    [0x8000_1000]
    output wire [31:0] s2_wb_adr_o,
    output wire [31:0] s2_wb_dat_o,
    input  wire [31:0] s2_wb_dat_i,
    output wire [ 3:0] s2_wb_sel_o,
    output wire        s2_wb_we_o,
    output wire        s2_wb_stb_o,
    output wire        s2_wb_cyc_o,
    input  wire        s2_wb_ack_i,

    // Slave 3: motor_pwm     [0x8000_2000]
    output wire [31:0] s3_wb_adr_o,
    output wire [31:0] s3_wb_dat_o,
    input  wire [31:0] s3_wb_dat_i,
    output wire [ 3:0] s3_wb_sel_o,
    output wire        s3_wb_we_o,
    output wire        s3_wb_stb_o,
    output wire        s3_wb_cyc_o,
    input  wire        s3_wb_ack_i,

    // Slave 4: ultrasonic    [0x8000_3000]
    output wire [31:0] s4_wb_adr_o,
    output wire [31:0] s4_wb_dat_o,
    input  wire [31:0] s4_wb_dat_i,
    output wire [ 3:0] s4_wb_sel_o,
    output wire        s4_wb_we_o,
    output wire        s4_wb_stb_o,
    output wire        s4_wb_cyc_o,
    input  wire        s4_wb_ack_i,

    // Slave 5: gpio          [0x8000_4000]
    output wire [31:0] s5_wb_adr_o,
    output wire [31:0] s5_wb_dat_o,
    input  wire [31:0] s5_wb_dat_i,
    output wire [ 3:0] s5_wb_sel_o,
    output wire        s5_wb_we_o,
    output wire        s5_wb_stb_o,
    output wire        s5_wb_cyc_o,
    input  wire        s5_wb_ack_i,

    // Slave 6: timer         [0x8000_5000]
    output wire [31:0] s6_wb_adr_o,
    output wire [31:0] s6_wb_dat_o,
    input  wire [31:0] s6_wb_dat_i,
    output wire [ 3:0] s6_wb_sel_o,
    output wire        s6_wb_we_o,
    output wire        s6_wb_stb_o,
    output wire        s6_wb_cyc_o,
    input  wire        s6_wb_ack_i,

    // Slave 7: watchdog      [0x8000_6000]
    output wire [31:0] s7_wb_adr_o,
    output wire [31:0] s7_wb_dat_o,
    input  wire [31:0] s7_wb_dat_i,
    output wire [ 3:0] s7_wb_sel_o,
    output wire        s7_wb_we_o,
    output wire        s7_wb_stb_o,
    output wire        s7_wb_cyc_o,
    input  wire        s7_wb_ack_i,

    // Slave 8: interrupt_ctrl [0x8000_7000]
    output wire [31:0] s8_wb_adr_o,
    output wire [31:0] s8_wb_dat_o,
    input  wire [31:0] s8_wb_dat_i,
    output wire [ 3:0] s8_wb_sel_o,
    output wire        s8_wb_we_o,
    output wire        s8_wb_stb_o,
    output wire        s8_wb_cyc_o,
    input  wire        s8_wb_ack_i,

    // Slave 9: rgb_led_pwm   [0x8000_8000]
    output wire [31:0] s9_wb_adr_o,
    output wire [31:0] s9_wb_dat_o,
    input  wire [31:0] s9_wb_dat_i,
    output wire [ 3:0] s9_wb_sel_o,
    output wire        s9_wb_we_o,
    output wire        s9_wb_stb_o,
    output wire        s9_wb_cyc_o,
    input  wire        s9_wb_ack_i,

    // Slave 10: weight_detect [0x8000_9000]
    output wire [31:0] s10_wb_adr_o,
    output wire [31:0] s10_wb_dat_o,
    input  wire [31:0] s10_wb_dat_i,
    output wire [ 3:0] s10_wb_sel_o,
    output wire        s10_wb_we_o,
    output wire        s10_wb_stb_o,
    output wire        s10_wb_cyc_o,
    input  wire        s10_wb_ack_i,

    // Slave 11: power_mgr    [0x8000_A000]
    output wire [31:0] s11_wb_adr_o,
    output wire [31:0] s11_wb_dat_o,
    input  wire [31:0] s11_wb_dat_i,
    output wire [ 3:0] s11_wb_sel_o,
    output wire        s11_wb_we_o,
    output wire        s11_wb_stb_o,
    output wire        s11_wb_cyc_o,
    input  wire        s11_wb_ack_i
);

    // =====================================================================
    // Address Decode: addr[31:12] for 4KB peripheral slots
    // addr[31:9] for SRAM (0x0000_0000 - 0x0000_01FF)
    // =====================================================================

    // SRAM: adr[31:9] == 23'h000000
    wire sel_sram;
    assign sel_sram = (m_wb_adr_i[31:9] == 23'h000000);

    // Peripheral select: one-hot from adr[31:12]
    wire [13:0] slave_sel;
    assign slave_sel[0]  = sel_sram;
    assign slave_sel[1]  = (m_wb_adr_i[31:12] == 20'h80000);  // UART
    assign slave_sel[2]  = (m_wb_adr_i[31:12] == 20'h80001);  // I2C
    assign slave_sel[3]  = (m_wb_adr_i[31:12] == 20'h80002);  // Motor PWM
    assign slave_sel[4]  = (m_wb_adr_i[31:12] == 20'h80003);  // Ultrasonic
    assign slave_sel[5]  = (m_wb_adr_i[31:12] == 20'h80004);  // GPIO
    assign slave_sel[6]  = (m_wb_adr_i[31:12] == 20'h80005);  // Timer
    assign slave_sel[7]  = (m_wb_adr_i[31:12] == 20'h80006);  // Watchdog
    assign slave_sel[8]  = (m_wb_adr_i[31:12] == 20'h80007);  // Interrupt Ctrl
    assign slave_sel[9]  = (m_wb_adr_i[31:12] == 20'h80008);  // RGB LED PWM
    assign slave_sel[10] = (m_wb_adr_i[31:12] == 20'h80009);  // Weight Detect
    assign slave_sel[11] = (m_wb_adr_i[31:12] == 20'h8000A);  // Power Mgr
    // slaves 12-13: reserved/unused
    assign slave_sel[12] = 1'b0;
    assign slave_sel[13] = 1'b0;

    wire any_sel;
    assign any_sel = |slave_sel;
    // any_sel used below in registered output stage (latched on ack_comb)

    // =====================================================================
    // Slave signal routing (fan-out, gated by select)
    // =====================================================================

    // ARRAY approach: use generate for clean fan-out
    // We'll define slave outputs via wires and assign

    // Slave 0: SRAM
    assign s0_wb_adr_o = m_wb_adr_i;
    assign s0_wb_dat_o = m_wb_dat_i;
    assign s0_wb_sel_o = m_wb_sel_i;
    assign s0_wb_we_o  = m_wb_we_i;
    assign s0_wb_stb_o = m_wb_stb_i & slave_sel[0];
    assign s0_wb_cyc_o = m_wb_cyc_i & slave_sel[0];

    // Slave 1: UART
    assign s1_wb_adr_o = m_wb_adr_i;
    assign s1_wb_dat_o = m_wb_dat_i;
    assign s1_wb_sel_o = m_wb_sel_i;
    assign s1_wb_we_o  = m_wb_we_i;
    assign s1_wb_stb_o = m_wb_stb_i & slave_sel[1];
    assign s1_wb_cyc_o = m_wb_cyc_i & slave_sel[1];

    // Slave 2: I2C
    assign s2_wb_adr_o = m_wb_adr_i;
    assign s2_wb_dat_o = m_wb_dat_i;
    assign s2_wb_sel_o = m_wb_sel_i;
    assign s2_wb_we_o  = m_wb_we_i;
    assign s2_wb_stb_o = m_wb_stb_i & slave_sel[2];
    assign s2_wb_cyc_o = m_wb_cyc_i & slave_sel[2];

    // Slave 3: Motor PWM
    assign s3_wb_adr_o = m_wb_adr_i;
    assign s3_wb_dat_o = m_wb_dat_i;
    assign s3_wb_sel_o = m_wb_sel_i;
    assign s3_wb_we_o  = m_wb_we_i;
    assign s3_wb_stb_o = m_wb_stb_i & slave_sel[3];
    assign s3_wb_cyc_o = m_wb_cyc_i & slave_sel[3];

    // Slave 4: Ultrasonic
    assign s4_wb_adr_o = m_wb_adr_i;
    assign s4_wb_dat_o = m_wb_dat_i;
    assign s4_wb_sel_o = m_wb_sel_i;
    assign s4_wb_we_o  = m_wb_we_i;
    assign s4_wb_stb_o = m_wb_stb_i & slave_sel[4];
    assign s4_wb_cyc_o = m_wb_cyc_i & slave_sel[4];

    // Slave 5: GPIO
    assign s5_wb_adr_o = m_wb_adr_i;
    assign s5_wb_dat_o = m_wb_dat_i;
    assign s5_wb_sel_o = m_wb_sel_i;
    assign s5_wb_we_o  = m_wb_we_i;
    assign s5_wb_stb_o = m_wb_stb_i & slave_sel[5];
    assign s5_wb_cyc_o = m_wb_cyc_i & slave_sel[5];

    // Slave 6: Timer
    assign s6_wb_adr_o = m_wb_adr_i;
    assign s6_wb_dat_o = m_wb_dat_i;
    assign s6_wb_sel_o = m_wb_sel_i;
    assign s6_wb_we_o  = m_wb_we_i;
    assign s6_wb_stb_o = m_wb_stb_i & slave_sel[6];
    assign s6_wb_cyc_o = m_wb_cyc_i & slave_sel[6];

    // Slave 7: Watchdog
    assign s7_wb_adr_o = m_wb_adr_i;
    assign s7_wb_dat_o = m_wb_dat_i;
    assign s7_wb_sel_o = m_wb_sel_i;
    assign s7_wb_we_o  = m_wb_we_i;
    assign s7_wb_stb_o = m_wb_stb_i & slave_sel[7];
    assign s7_wb_cyc_o = m_wb_cyc_i & slave_sel[7];

    // Slave 8: Interrupt Ctrl
    assign s8_wb_adr_o = m_wb_adr_i;
    assign s8_wb_dat_o = m_wb_dat_i;
    assign s8_wb_sel_o = m_wb_sel_i;
    assign s8_wb_we_o  = m_wb_we_i;
    assign s8_wb_stb_o = m_wb_stb_i & slave_sel[8];
    assign s8_wb_cyc_o = m_wb_cyc_i & slave_sel[8];

    // Slave 9: RGB LED PWM
    assign s9_wb_adr_o = m_wb_adr_i;
    assign s9_wb_dat_o = m_wb_dat_i;
    assign s9_wb_sel_o = m_wb_sel_i;
    assign s9_wb_we_o  = m_wb_we_i;
    assign s9_wb_stb_o = m_wb_stb_i & slave_sel[9];
    assign s9_wb_cyc_o = m_wb_cyc_i & slave_sel[9];

    // Slave 10: Weight Detect
    assign s10_wb_adr_o = m_wb_adr_i;
    assign s10_wb_dat_o = m_wb_dat_i;
    assign s10_wb_sel_o = m_wb_sel_i;
    assign s10_wb_we_o  = m_wb_we_i;
    assign s10_wb_stb_o = m_wb_stb_i & slave_sel[10];
    assign s10_wb_cyc_o = m_wb_cyc_i & slave_sel[10];

    // Slave 11: Power Mgr
    assign s11_wb_adr_o = m_wb_adr_i;
    assign s11_wb_dat_o = m_wb_dat_i;
    assign s11_wb_sel_o = m_wb_sel_i;
    assign s11_wb_we_o  = m_wb_we_i;
    assign s11_wb_stb_o = m_wb_stb_i & slave_sel[11];
    assign s11_wb_cyc_o = m_wb_cyc_i & slave_sel[11];

    // =====================================================================
    // BUG-004 FIX: Registered read-data path
    //    Comb. 12:1 MUX → Register (latched on ack) → Master
    // =====================================================================

    wire [31:0] read_data_comb;
    assign read_data_comb =
        slave_sel[0]  ? s0_wb_dat_i  :
        slave_sel[1]  ? s1_wb_dat_i  :
        slave_sel[2]  ? s2_wb_dat_i  :
        slave_sel[3]  ? s3_wb_dat_i  :
        slave_sel[4]  ? s4_wb_dat_i  :
        slave_sel[5]  ? s5_wb_dat_i  :
        slave_sel[6]  ? s6_wb_dat_i  :
        slave_sel[7]  ? s7_wb_dat_i  :
        slave_sel[8]  ? s8_wb_dat_i  :
        slave_sel[9]  ? s9_wb_dat_i  :
        slave_sel[10] ? s10_wb_dat_i :
        slave_sel[11] ? s11_wb_dat_i :
        32'h00000000;

    // ACK aggregation: OR of selected slave ACK, or 1 for unmapped (default slave)
    wire ack_comb;
    assign ack_comb =
        slave_sel[0]  ? s0_wb_ack_i  :
        slave_sel[1]  ? s1_wb_ack_i  :
        slave_sel[2]  ? s2_wb_ack_i  :
        slave_sel[3]  ? s3_wb_ack_i  :
        slave_sel[4]  ? s4_wb_ack_i  :
        slave_sel[5]  ? s5_wb_ack_i  :
        slave_sel[6]  ? s6_wb_ack_i  :
        slave_sel[7]  ? s7_wb_ack_i  :
        slave_sel[8]  ? s8_wb_ack_i  :
        slave_sel[9]  ? s9_wb_ack_i  :
        slave_sel[10] ? s10_wb_ack_i :
        slave_sel[11] ? s11_wb_ack_i :
        (m_wb_cyc_i & m_wb_stb_i);

    // Registered output stage
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            m_wb_dat_o <= 32'd0;
        end else if (ack_comb && any_sel) begin
            m_wb_dat_o <= read_data_comb;
        end else if (ack_comb && !any_sel) begin
            m_wb_dat_o <= 32'd0;
        end
    end

    assign m_wb_ack_o = ack_comb;

endmodule
