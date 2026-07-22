// Module: timer
// Description: 32-bit auto-reload down-counter timer with two compare channels
// Source: IP-005 v4 Architecture §4.9, REUSE_INTERNAL (ip-009-timer-wb4)
// Address: 0x8000_5000 - 0x8000_5FFF
// Version: v4

module timer (
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

    // Interrupts
    output reg         irq_cmpa,
    output reg         irq_cmpb
);

    wire _unused = |{wb_adr_i[31:5], wb_adr_i[1:0], wb_dat_i[31:2], wb_sel_i};

    localparam ADDR_COUNTER   = 3'h0;  // 0x00
    localparam ADDR_RELOAD    = 3'h1;  // 0x04
    localparam ADDR_COMPARE_A = 3'h2;  // 0x08
    localparam ADDR_COMPARE_B = 3'h3;  // 0x0C
    localparam ADDR_CTRL      = 3'h4;  // 0x10
    localparam ADDR_STATUS    = 3'h5;  // 0x14

    reg [31:0] counter;
    reg [31:0] reload;
    reg [31:0] compare_a, compare_b;
    reg        ctrl_enable;
    reg        ctrl_auto_reload;
    reg        status_cmpa, status_cmpb, status_wrap;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            counter         <= 32'd0;
            reload          <= 32'hFFFFFFFF;
            compare_a       <= 32'd0;
            compare_b       <= 32'd0;
            ctrl_enable     <= 1'b0;
            ctrl_auto_reload<= 1'b0;
            status_cmpa     <= 1'b0;
            status_cmpb     <= 1'b0;
            status_wrap     <= 1'b0;
            irq_cmpa        <= 1'b0;
            irq_cmpb        <= 1'b0;
            wb_ack_o        <= 1'b0;
            wb_dat_o        <= 32'd0;
        end else begin
            wb_ack_o  <= 1'b0;
            irq_cmpa  <= 1'b0;
            irq_cmpb  <= 1'b0;

            // Timer operation
            if (ctrl_enable) begin
                if (counter == 32'd0) begin
                    if (ctrl_auto_reload && reload != 32'd0) begin
                        counter <= reload;
                        status_wrap <= 1'b1;
                    end
                end else begin
                    counter <= counter - 32'd1;
                end

                // Compare match detection
                if (counter == compare_a && counter != 32'd0) begin
                    status_cmpa <= 1'b1;
                    irq_cmpa <= 1'b1;
                end
                if (counter == compare_b && counter != 32'd0) begin
                    status_cmpb <= 1'b1;
                    irq_cmpb <= 1'b1;
                end
            end

            // Wishbone B4
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;

                if (wb_we_i) begin
                    case (wb_adr_i[4:2])
                        ADDR_COUNTER:   counter          <= wb_dat_i;
                        ADDR_RELOAD:    reload           <= wb_dat_i;
                        ADDR_COMPARE_A: compare_a        <= wb_dat_i;
                        ADDR_COMPARE_B: compare_b        <= wb_dat_i;
                        ADDR_CTRL: begin
                            ctrl_enable      <= wb_dat_i[0];
                            ctrl_auto_reload <= wb_dat_i[1];
                        end
                        ADDR_STATUS: begin
                            // W1C: write 1 to clear
                            if (wb_dat_i[0]) status_cmpa <= 1'b0;
                            if (wb_dat_i[1]) status_cmpb <= 1'b0;
                            if (wb_dat_i[2]) status_wrap <= 1'b0;
                        end
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[4:2])
                        ADDR_COUNTER:   wb_dat_o <= counter;
                        ADDR_RELOAD:    wb_dat_o <= reload;
                        ADDR_COMPARE_A: wb_dat_o <= compare_a;
                        ADDR_COMPARE_B: wb_dat_o <= compare_b;
                        ADDR_CTRL:      wb_dat_o <= {30'd0, ctrl_auto_reload, ctrl_enable};
                        ADDR_STATUS:    wb_dat_o <= {29'd0, status_wrap, status_cmpb, status_cmpa};
                        default:        wb_dat_o <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
