// Module: power_mgr
// Description: Power/Clock Manager — reset synchronizer and status registers
// Source: IP-005 v4 Architecture §4.14, REUSE_INTERNAL
// Address: 0x8000_A000 - 0x8000_AFFF
// Version: v4 — simplified: reset sync + status only, no clock gating

module power_mgr (
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

    // External inputs
    input  wire        ext_rst_n,
    input  wire        wdt_rst_n,
    input  wire        sys_clk_i,

    // Outputs
    output reg         sys_rst_n_o,
    output wire        clk_en_o
);

    wire _unused = |{wb_adr_i[31:5], wb_adr_i[1:0], wb_dat_i, wb_sel_i};

    // clk_en_o is always 1 — no clock gating in v4
    assign clk_en_o = 1'b1;

    localparam ADDR_CTRL   = 3'h0;  // 0x00: CTRL (read, clear-on-read)
    localparam ADDR_STATUS = 3'h1;  // 0x04: STATUS

    // Reset synchronizer: 2-FF chain
    reg sync_ff1, sync_ff2;
    reg ext_rst_flag, wdt_rst_flag;

    // Internal reset: async assert, sync deassert via 2-FF
    wire int_rst_n;
    assign int_rst_n = ext_rst_n & wdt_rst_n;

    always @(posedge sys_clk_i or negedge int_rst_n) begin
        if (!int_rst_n) begin
            sync_ff1 <= 1'b0;
            sync_ff2 <= 1'b0;
        end else begin
            sync_ff1 <= 1'b1;
            sync_ff2 <= sync_ff1;
        end
    end

    wire sync_rst_n;
    assign sync_rst_n = sync_ff2;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sys_rst_n_o   <= 1'b0;
            ext_rst_flag  <= 1'b0;
            wdt_rst_flag  <= 1'b0;
            wb_ack_o      <= 1'b0;
            wb_dat_o      <= 32'd0;
        end else begin
            wb_ack_o <= 1'b0;

            // Combined reset output (from sync chain AND watchdog)
            sys_rst_n_o <= sync_rst_n;

            // Detect reset sources on falling edge
            if (!ext_rst_n)
                ext_rst_flag <= 1'b1;
            if (!wdt_rst_n)
                wdt_rst_flag <= 1'b1;

            // Wishbone B4 slave (read-only registers)
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;

                if (!wb_we_i) begin
                    case (wb_adr_i[4:2])
                        ADDR_CTRL: begin
                            wb_dat_o <= {30'd0, wdt_rst_flag, ext_rst_flag};
                            // Clear-on-read
                            ext_rst_flag <= 1'b0;
                            wdt_rst_flag <= 1'b0;
                        end
                        ADDR_STATUS: wb_dat_o <= {31'd0, 1'b1};  // PLL_LOCKED tied high
                        default:     wb_dat_o <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
