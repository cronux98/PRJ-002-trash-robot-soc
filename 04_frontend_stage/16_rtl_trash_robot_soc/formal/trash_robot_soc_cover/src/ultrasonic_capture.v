// Module: ultrasonic_capture
// Description: 2-channel HC-SR04 ultrasonic pulse capture with distance calculation
// Source: IP-005 v4 Architecture §4.7, CREATE
// Address: 0x8000_3000 - 0x8000_3FFF
// Version: v4 — new CREATE module

module ultrasonic_capture (
    input  wire        clk_i,
    input  wire        rst_ni,

    // Wishbone B4 slave
    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output reg  [31:0] wb_dat_o,
    input  wire [ 3:0] wb_sel_i,
    input  wire        wb_we_i,
    input  wire        wb_stb_i,
    input  wire        wb_cyc_i,
    output reg         wb_ack_o,

    // HC-SR04 pins
    output reg  [1:0]  trig_o,
    input  wire [1:0]  echo_i,

    // Interrupt
    output reg         irq_done
);

    // Tie off unused WB bits
    wire _unused_wb = |{wb_adr_i[31:5], wb_adr_i[1:0], wb_dat_i[31:2], wb_sel_i};

    localparam ADDR_CTRL    = 3'h0;  // 0x00
    localparam ADDR_STATUS  = 3'h1;  // 0x04
    localparam ADDR_ECHO_CH0 = 3'h2;  // 0x08
    localparam ADDR_ECHO_CH1 = 3'h3;  // 0x0C
    localparam ADDR_DIST_CH0 = 3'h4;  // 0x10
    localparam ADDR_DIST_CH1 = 3'h5;  // 0x14

    // TRIG pulse: 10µs at 33.3MHz = 333 clocks
    localparam TRIG_CLOCKS = 16'd333;
    // 58 µs/cm → 58*33.3 = 1931 clocks/cm → dist_cm_x100 = clocks * 100 / 1931

    // FSM states per channel
    localparam CH_IDLE = 2'd0;
    localparam CH_TRIG = 2'd1;
    localparam CH_WAIT = 2'd2;
    localparam CH_DONE = 2'd3;

    // Channel 0
    reg [1:0]  ch0_state;
    reg [15:0] ch0_trig_cnt;
    reg [19:0] ch0_echo_cnt;
    reg [15:0] ch0_echo_val;
    reg [15:0] ch0_dist_val;
    reg        ch0_echo_prev;
    reg        ch0_start;

    // Channel 1
    reg [1:0]  ch1_state;
    reg [15:0] ch1_trig_cnt;
    reg [19:0] ch1_echo_cnt;
    reg [15:0] ch1_echo_val;
    reg [15:0] ch1_dist_val;
    reg        ch1_echo_prev;
    reg        ch1_start;

    // Echo synchronizers
    reg [1:0] echo_sync1, echo_sync2;

    // Distance calc: echo_clocks * 100 / 1931
    // Use integer multiplication with saturation
    function [15:0] calc_distance;
        input [19:0] echo_clocks;
        reg [35:0] temp;
        begin
            temp = echo_clocks * 20'd100;
            if (temp > 36'd6553500)
                calc_distance = 16'hFFFF;
            else
                calc_distance = temp[15:0] / 16'd1931;
        end
    endfunction

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ch0_state     <= CH_IDLE;
            ch0_trig_cnt  <= 16'd0;
            ch0_echo_cnt  <= 20'd0;
            ch0_echo_val  <= 16'd0;
            ch0_dist_val  <= 16'd0;
            ch0_echo_prev <= 1'b0;
            ch0_start     <= 1'b0;
            ch1_state     <= CH_IDLE;
            ch1_trig_cnt  <= 16'd0;
            ch1_echo_cnt  <= 20'd0;
            ch1_echo_val  <= 16'd0;
            ch1_dist_val  <= 16'd0;
            ch1_echo_prev <= 1'b0;
            ch1_start     <= 1'b0;
            echo_sync1    <= 2'd0;
            echo_sync2    <= 2'd0;
            trig_o        <= 2'd0;
            irq_done      <= 1'b0;
            wb_ack_o      <= 1'b0;
            wb_dat_o      <= 32'd0;
        end else begin
            wb_ack_o  <= 1'b0;
            irq_done  <= 1'b0;
            ch0_start <= 1'b0;
            ch1_start <= 1'b0;

            // Echo input synchronizers
            echo_sync1 <= echo_i;
            echo_sync2 <= echo_sync1;

            // CHANNEL 0
            case (ch0_state)
                CH_IDLE: begin
                    trig_o[0] <= 1'b0;
                    if (ch0_start) begin
                        ch0_state    <= CH_TRIG;
                        ch0_trig_cnt <= TRIG_CLOCKS;
                    end
                end
                CH_TRIG: begin
                    trig_o[0] <= 1'b1;
                    if (ch0_trig_cnt > 0)
                        ch0_trig_cnt <= ch0_trig_cnt - 16'd1;
                    else begin
                        ch0_state     <= CH_WAIT;
                        ch0_echo_cnt  <= 20'd0;
                        ch0_echo_prev <= 1'b0;
                    end
                end
                CH_WAIT: begin
                    trig_o[0] <= 1'b0;
                    if (!ch0_echo_prev && echo_sync2[0])
                        ch0_echo_cnt <= 20'd0;
                    if (echo_sync2[0])
                        ch0_echo_cnt <= ch0_echo_cnt + 20'd1;
                    if (ch0_echo_prev && !echo_sync2[0] && ch0_echo_cnt > 0) begin
                        ch0_echo_val <= ch0_echo_cnt[15:0];
                        ch0_dist_val <= calc_distance(ch0_echo_cnt);
                        ch0_state    <= CH_DONE;
                    end
                    ch0_echo_prev <= echo_sync2[0];
                end
                CH_DONE: begin
                    trig_o[0] <= 1'b0;
                    irq_done  <= 1'b1;
                    ch0_state <= CH_IDLE;
                end
                default: ch0_state <= CH_IDLE;
            endcase

            // CHANNEL 1
            case (ch1_state)
                CH_IDLE: begin
                    trig_o[1] <= 1'b0;
                    if (ch1_start) begin
                        ch1_state    <= CH_TRIG;
                        ch1_trig_cnt <= TRIG_CLOCKS;
                    end
                end
                CH_TRIG: begin
                    trig_o[1] <= 1'b1;
                    if (ch1_trig_cnt > 0)
                        ch1_trig_cnt <= ch1_trig_cnt - 16'd1;
                    else begin
                        ch1_state     <= CH_WAIT;
                        ch1_echo_cnt  <= 20'd0;
                        ch1_echo_prev <= 1'b0;
                    end
                end
                CH_WAIT: begin
                    trig_o[1] <= 1'b0;
                    if (!ch1_echo_prev && echo_sync2[1])
                        ch1_echo_cnt <= 20'd0;
                    if (echo_sync2[1])
                        ch1_echo_cnt <= ch1_echo_cnt + 20'd1;
                    if (ch1_echo_prev && !echo_sync2[1] && ch1_echo_cnt > 0) begin
                        ch1_echo_val <= ch1_echo_cnt[15:0];
                        ch1_dist_val <= calc_distance(ch1_echo_cnt);
                        ch1_state    <= CH_DONE;
                    end
                    ch1_echo_prev <= echo_sync2[1];
                end
                CH_DONE: begin
                    trig_o[1] <= 1'b0;
                    irq_done  <= 1'b1;
                    ch1_state <= CH_IDLE;
                end
                default: ch1_state <= CH_IDLE;
            endcase

            // Wishbone B4
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    case (wb_adr_i[4:2])
                        ADDR_CTRL: begin
                            if (wb_dat_i[0]) ch0_start <= 1'b1;
                            if (wb_dat_i[1]) ch1_start <= 1'b1;
                        end
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[4:2])
                        ADDR_STATUS:  wb_dat_o <= {28'd0,
                            (ch1_state == CH_IDLE), 1'b0,
                            (ch0_state == CH_IDLE), 1'b0};
                        ADDR_ECHO_CH0: wb_dat_o <= {16'd0, ch0_echo_val};
                        ADDR_ECHO_CH1: wb_dat_o <= {16'd0, ch1_echo_val};
                        ADDR_DIST_CH0: wb_dat_o <= {16'd0, ch0_dist_val};
                        ADDR_DIST_CH1: wb_dat_o <= {16'd0, ch1_dist_val};
                        default:       wb_dat_o <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
