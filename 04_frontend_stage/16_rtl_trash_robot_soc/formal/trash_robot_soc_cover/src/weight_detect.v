// Module: weight_detect
// Description: HX711 weight threshold comparator — 24-bit comparison
// Source: IP-005 v4 Architecture §4.13, REUSE_INTERNAL
// Address: 0x8000_9000 - 0x8000_9FFF
// Version: v4

module weight_detect (
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

    // Interrupt output
    output reg         irq_thresh
);

    wire _unused = |{wb_adr_i[31:5], wb_adr_i[1:0], wb_dat_i[31:24], wb_sel_i};

    localparam ADDR_WEIGHT = 3'h0;  // 0x00: WEIGHT_VALUE
    localparam ADDR_THRESH = 3'h1;  // 0x04: THRESHOLD
    localparam ADDR_CTRL   = 3'h2;  // 0x08: CTRL
    localparam ADDR_STATUS = 3'h3;  // 0x0C: STATUS

    reg [23:0] weight_value;
    reg [23:0] threshold;
    reg        ctrl_direction;  // 0=above, 1=below
    reg        ctrl_irq_en;
    reg        status_above;
    reg        status_irq_flag;

    // Comparison (combinational)
    wire weight_above;
    assign weight_above = (weight_value >= threshold);

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            weight_value    <= 24'd0;
            threshold       <= 24'd0;
            ctrl_direction  <= 1'b0;
            ctrl_irq_en     <= 1'b0;
            status_above    <= 1'b0;
            status_irq_flag <= 1'b0;
            irq_thresh      <= 1'b0;
            wb_ack_o        <= 1'b0;
            wb_dat_o        <= 32'd0;
        end else begin
            wb_ack_o   <= 1'b0;
            irq_thresh <= 1'b0;

            // Update status from comparison
            status_above <= weight_above;

            // Threshold logic
            if (ctrl_direction) begin
                // Below-threshold mode: asserts when weight drops below
                if (!weight_above && ctrl_irq_en)
                    status_irq_flag <= 1'b1;
            end else begin
                // Above-threshold mode: asserts when weight equals or exceeds
                if (weight_above && ctrl_irq_en)
                    status_irq_flag <= 1'b1;
            end

            // IRQ output
            irq_thresh <= status_irq_flag && ctrl_irq_en;

            // Wishbone B4 slave
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;

                if (wb_we_i) begin
                    case (wb_adr_i[4:2])
                        ADDR_WEIGHT: weight_value   <= wb_dat_i[23:0];
                        ADDR_THRESH: threshold      <= wb_dat_i[23:0];
                        ADDR_CTRL: begin
                            ctrl_direction <= wb_dat_i[0];
                            ctrl_irq_en    <= wb_dat_i[1];
                            // Writing CTRL also clears IRQ flag
                            status_irq_flag <= 1'b0;
                        end
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[4:2])
                        ADDR_WEIGHT: wb_dat_o <= {8'd0, weight_value};
                        ADDR_THRESH: wb_dat_o <= {8'd0, threshold};
                        ADDR_CTRL:   wb_dat_o <= {30'd0, ctrl_irq_en, ctrl_direction};
                        ADDR_STATUS: wb_dat_o <= {30'd0, status_irq_flag, status_above};
                        default:     wb_dat_o <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
