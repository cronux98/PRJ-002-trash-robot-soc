// Module: sram_512b
// Description: 512B unified SRAM (128x32-bit), Wishbone B4 slave, single-cycle R/W
// Source: IP-005 v4 Architecture §4.3, REUSE_INTERNAL
// Address: 0x0000_0000 - 0x0000_01FF
// Version: v4 — adapted for full 32-bit address, single-cycle ack

module sram_512b (
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
    output reg         wb_ack_o
);

    // Tie off unused WB bits for lint cleanliness
    wire _unused = |{wb_adr_i[31:9], wb_adr_i[1:0]};

    // 128 x 32-bit SRAM array (inferred)
    reg [31:0] mem [0:127];

    // Use only address bits [8:2] for word addressing (512B = 128 words)
    wire [6:0] word_addr;
    assign word_addr = wb_adr_i[8:2];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wb_ack_o <= 1'b0;
            wb_dat_o <= 32'd0;
        end else if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
            wb_ack_o <= 1'b1;
            if (wb_we_i) begin
                if (wb_sel_i[0]) mem[word_addr][ 7: 0] <= wb_dat_i[ 7: 0];
                if (wb_sel_i[1]) mem[word_addr][15: 8] <= wb_dat_i[15: 8];
                if (wb_sel_i[2]) mem[word_addr][23:16] <= wb_dat_i[23:16];
                if (wb_sel_i[3]) mem[word_addr][31:24] <= wb_dat_i[31:24];
            end else begin
                wb_dat_o <= mem[word_addr];
            end
        end else begin
            wb_ack_o <= 1'b0;
        end
    end

endmodule
