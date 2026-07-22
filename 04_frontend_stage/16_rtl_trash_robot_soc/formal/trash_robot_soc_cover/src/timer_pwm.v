// Module: timer_pwm
// Description: 32-bit general-purpose timer with 4 PWM output channels
// Source: ARCHITECTURE.md 4.8, REUSE (WEAK, ip-009-timer-wb4)
// Address: 0x5000-0x5FFF
// Version: v2 - single always block, Wishbone B4 slave, 33.3MHz

module timer_pwm (
    input  wire        clk_i,
    input  wire        rst_ni,

    // Wishbone B4 slave
    input  wire [11:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output reg  [31:0] wb_dat_o,
    input  wire [ 3:0] wb_sel_i,
    input  wire        wb_we_i,
    input  wire        wb_stb_i,
    input  wire        wb_cyc_i,
    output reg         wb_ack_o,

    // PWM outputs
    output reg  [ 3:0] pwm_o,

    // Interrupt
    output reg         intr_overflow_o
);

    // Tie off unused WB interface bits (standard bus - all bits present for compatibility)
    wire _wb_unused = |{wb_adr_i[11:5], wb_adr_i[1:0], wb_dat_i[31:16], wb_sel_i};

    // Register map (8 registers):
    // 0x00: COUNTER (RO)     0x04: PERIOD[0]    0x08: DUTY[0]
    // 0x0C: PERIOD[1]        0x10: DUTY[1]      0x14: PERIOD[2]
    // 0x18: DUTY[2]          0x1C: PERIOD[3]    0x20: DUTY[3]
    // 0x24: CTRL [0]=EN, [1:2]=PRESCALE

    reg [31:0] counter;
    reg [31:0] period_reg [0:3];
    reg [31:0] duty_reg   [0:3];
    reg [ 2:0] ctrl_reg;       // [0]=EN, [1:2]=prescale (0=/1, 1=/4, 2=/16, 3=/64)

    // Prescaler
    reg [ 6:0] prescale_counter;
    wire       pwm_tick;
    // Unused WB signal tie-offs (lint suppression)

    assign pwm_tick = (prescale_counter == 7'd0);

    integer i;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            counter          <= 32'd0;
            period_reg[0]    <= 32'd0;
            period_reg[1]    <= 32'd0;
            period_reg[2]    <= 32'd0;
            period_reg[3]    <= 32'd0;
            duty_reg[0]      <= 32'd0;
            duty_reg[1]      <= 32'd0;
            duty_reg[2]      <= 32'd0;
            duty_reg[3]      <= 32'd0;
            ctrl_reg         <= 3'd0;
            prescale_counter <= 7'd63;
            pwm_o            <= 4'd0;
            intr_overflow_o  <= 1'b0;
            wb_ack_o         <= 1'b0;
            wb_dat_o         <= 32'd0;
        end else begin
            wb_ack_o        <= 1'b0;
            intr_overflow_o <= 1'b0;

            // Prescaler
            if (ctrl_reg[0]) begin
                if (pwm_tick) begin
                    case (ctrl_reg[2:1])
                        2'd0: prescale_counter <= 7'd0;    // div 1
                        2'd1: prescale_counter <= 7'd3;    // div 4
                        2'd2: prescale_counter <= 7'd15;   // div 16
                        2'd3: prescale_counter <= 7'd63;   // div 64
                        default: prescale_counter <= 7'd0;
                    endcase
                end else begin
                    prescale_counter <= prescale_counter - 7'd1;
                end

                // Main counter
                if (pwm_tick) begin
                    counter <= counter + 32'd1;
                    if (counter == 32'hFFFF_FFFF)
                        intr_overflow_o <= 1'b1;
                end

                // PWM outputs
                for (i = 0; i < 4; i = i + 1) begin
                    if (period_reg[i] != 32'd0)
                        pwm_o[i] <= (counter < duty_reg[i]);
                    else
                        pwm_o[i] <= 1'b0;
                end
            end else begin
                counter          <= 32'd0;
                prescale_counter <= 7'd63;
                pwm_o            <= 4'd0;
            end

            // Wishbone B4
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    case (wb_adr_i[5:2])
                        4'h0:  ;  // COUNTER is RO
                        4'h1:  period_reg[0] <= wb_dat_i;
                        4'h2:  duty_reg[0]   <= wb_dat_i;
                        4'h3:  period_reg[1] <= wb_dat_i;
                        4'h4:  duty_reg[1]   <= wb_dat_i;
                        4'h5:  period_reg[2] <= wb_dat_i;
                        4'h6:  duty_reg[2]   <= wb_dat_i;
                        4'h7:  period_reg[3] <= wb_dat_i;
                        4'h8:  duty_reg[3]   <= wb_dat_i;
                        4'h9:  ctrl_reg      <= wb_dat_i[2:0];
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[5:2])
                        4'h0:  wb_dat_o <= counter;
                        4'h1:  wb_dat_o <= period_reg[0];
                        4'h2:  wb_dat_o <= duty_reg[0];
                        4'h3:  wb_dat_o <= period_reg[1];
                        4'h4:  wb_dat_o <= duty_reg[1];
                        4'h5:  wb_dat_o <= period_reg[2];
                        4'h6:  wb_dat_o <= duty_reg[2];
                        4'h7:  wb_dat_o <= period_reg[3];
                        4'h8:  wb_dat_o <= duty_reg[3];
                        4'h9:  wb_dat_o <= {29'd0, ctrl_reg};
                        default: wb_dat_o <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
