// Module: watchdog
// Description: 32-bit watchdog timer with kick mechanism and system reset output
// Source: IP-005 v4 Architecture §4.10, REUSE_INTERNAL
// Address: 0x8000_6000 - 0x8000_6FFF
// Version: v4 — adapted for full 32-bit WB, strict v4 spec

module watchdog (
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

    // Interrupt and reset outputs
    output reg         irq_warn,
    output reg         rst_out_n
);

    wire _unused = |{wb_adr_i[31:5], wb_adr_i[1:0], wb_sel_i};

    // Register addresses (word-aligned)
    localparam ADDR_CTRL    = 3'h0;  // 0x00: CTRL
    localparam ADDR_TIMEOUT = 3'h1;  // 0x04: TIMEOUT
    localparam ADDR_KICK    = 3'h2;  // 0x08: KICK (write-only)
    localparam ADDR_COUNTER = 3'h3;  // 0x0C: COUNTER (read-only)

    // Magic kick value
    localparam KICK_MAGIC   = 32'h00ACCE55;

    // Internal registers
    reg         ctrl_enable;
    reg         ctrl_locked;
    reg  [31:0] timeout_val;
    reg  [31:0] counter;
    reg  [ 7:0] rst_pulse_cnt;

    // 75% warning threshold — combinational
    wire [31:0] warn_threshold;
    assign warn_threshold = timeout_val >> 2;  // timeout / 4, so warn at 75%

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ctrl_enable  <= 1'b0;
            ctrl_locked  <= 1'b0;
            timeout_val  <= 32'h000F4240;  // 1M clocks ~30ms default
            counter      <= 32'h000F4240;
            rst_pulse_cnt <= 8'd0;
            irq_warn     <= 1'b0;
            rst_out_n    <= 1'b1;
            wb_ack_o     <= 1'b0;
            wb_dat_o     <= 32'd0;
        end else begin
            wb_ack_o <= 1'b0;
            irq_warn <= 1'b0;

            // Reset pulse handling
            if (rst_pulse_cnt > 0) begin
                rst_pulse_cnt <= rst_pulse_cnt - 8'd1;
                if (rst_pulse_cnt == 8'd1) begin
                    rst_out_n <= 1'b1;
                    counter   <= timeout_val;
                end
            end else if (ctrl_enable) begin
                // Countdown
                if (counter > 0) begin
                    counter <= counter - 32'd1;
                end

                // Warning at 75%
                if (counter == warn_threshold && counter > 0)
                    irq_warn <= 1'b1;

                // Timeout — assert reset
                if (counter == 32'd1) begin
                    rst_out_n     <= 1'b0;
                    rst_pulse_cnt <= 8'd255;  // 256 clocks reset pulse
                end
            end

            // Wishbone B4 slave
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;

                if (wb_we_i) begin
                    case (wb_adr_i[4:2])
                        ADDR_CTRL: begin
                            if (wb_dat_i[0] && !ctrl_locked) begin
                                ctrl_enable <= 1'b1;
                                ctrl_locked <= 1'b1;
                                counter     <= timeout_val;
                            end
                        end
                        ADDR_TIMEOUT: timeout_val <= wb_dat_i;
                        ADDR_KICK: begin
                            if (wb_dat_i == KICK_MAGIC && ctrl_enable)
                                counter <= timeout_val;
                        end
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[4:2])
                        ADDR_CTRL:    wb_dat_o <= {30'd0, ctrl_locked, ctrl_enable};
                        ADDR_TIMEOUT: wb_dat_o <= timeout_val;
                        ADDR_COUNTER: wb_dat_o <= counter;
                        default:      wb_dat_o <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
