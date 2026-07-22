// Module: gpio
// Description: 12-bit GPIO with per-pin direction, data, and pin-change interrupt
// Source: IP-005 v4 Architecture §4.8, REUSE_INTERNAL
// Address: 0x8000_4000 - 0x8000_4FFF
// Version: v4 — 12-bit, full 32-bit WB, single irq_pin output

module gpio (
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

    // GPIO pins
    input  wire [11:0] gpio_i,
    output reg  [11:0] gpio_o,
    output reg  [11:0] gpio_oe,

    // Interrupt
    output reg         irq_pin
);

    wire _unused = |{wb_adr_i[31:5], wb_adr_i[1:0], wb_dat_i[31:12], wb_sel_i};

    localparam ADDR_DATA_IN  = 3'h0;  // 0x00: DATA_IN (read-only)
    localparam ADDR_DATA_OUT = 3'h1;  // 0x04: DATA_OUT
    localparam ADDR_DIR      = 3'h2;  // 0x08: DIR
    localparam ADDR_IRQ_CFG  = 3'h3;  // 0x0C: IRQ_CFG

    reg [11:0] dir_reg;
    reg [11:0] out_reg;
    reg [11:0] irq_cfg;  // Per-pin IRQ enable

    // 2-FF synchronizers on inputs
    reg [11:0] gpio_sync1, gpio_sync2;
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            gpio_sync1 <= 12'd0;
            gpio_sync2 <= 12'd0;
        end else begin
            gpio_sync1 <= gpio_i;
            gpio_sync2 <= gpio_sync1;
        end
    end

    // Edge detection for pin-change interrupt
    reg [11:0] gpio_prev;
    wire [11:0] pin_change;
    assign pin_change = gpio_sync2 ^ gpio_prev;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            gpio_prev <= 12'd0;
        end else begin
            gpio_prev <= gpio_sync2;
        end
    end

    // Main always block: outputs, IRQ, Wishbone
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            dir_reg  <= 12'd0;
            out_reg  <= 12'd0;
            irq_cfg  <= 12'd0;
            gpio_o   <= 12'd0;
            gpio_oe  <= 12'd0;
            irq_pin  <= 1'b0;
            wb_ack_o <= 1'b0;
            wb_dat_o <= 32'd0;
        end else begin
            wb_ack_o <= 1'b0;

            // GPIO outputs
            gpio_o  <= out_reg;
            gpio_oe <= dir_reg;

            // Pin-change interrupt: any enabled pin that changed asserts IRQ
            irq_pin <= |(pin_change & irq_cfg);

            // Wishbone B4 slave
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;

                if (wb_we_i) begin
                    case (wb_adr_i[4:2])
                        ADDR_DATA_OUT: out_reg <= wb_dat_i[11:0];
                        ADDR_DIR:      dir_reg <= wb_dat_i[11:0];
                        ADDR_IRQ_CFG:  irq_cfg <= wb_dat_i[11:0];
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[4:2])
                        ADDR_DATA_IN:  wb_dat_o <= {20'd0, gpio_sync2};
                        ADDR_DATA_OUT: wb_dat_o <= {20'd0, out_reg};
                        ADDR_DIR:      wb_dat_o <= {20'd0, dir_reg};
                        ADDR_IRQ_CFG:  wb_dat_o <= {20'd0, irq_cfg};
                        default:       wb_dat_o <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
