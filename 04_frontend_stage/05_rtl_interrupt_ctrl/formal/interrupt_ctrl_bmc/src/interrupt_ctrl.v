// Module: interrupt_ctrl
// Description: 16-source interrupt controller with edge/level config, priority encoder
// Source: IP-005 v4 Architecture §4.11, CREATE
// Address: 0x8000_7000 - 0x8000_7FFF
// Version: v4 — new CREATE module

module interrupt_ctrl (
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

    // Interrupt sources
    input  wire [15:0] irq_in,

    // Aggregated IRQ output
    output reg         irq_out
);

    wire _unused = |{wb_adr_i[31:5], wb_adr_i[1:0], wb_dat_i[31:16], wb_sel_i};

    localparam ADDR_PENDING  = 3'h0;  // 0x00
    localparam ADDR_ENABLE   = 3'h1;  // 0x04
    localparam ADDR_EDGE_CFG = 3'h2;  // 0x08
    localparam ADDR_SOFTWARE = 3'h3;  // 0x0C

    reg [15:0] pending;
    reg [15:0] enable;
    reg [15:0] edge_cfg;    // 1=edge (rising), 0=level
    reg [15:0] irq_in_prev; // Previous state for edge detect

    // Edge detection: rising edge
    wire [15:0] edge_rise;
    assign edge_rise = irq_in & ~irq_in_prev;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            pending     <= 16'd0;
            enable      <= 16'd0;
            edge_cfg    <= 16'hFFFF;  // default: all edge-triggered
            irq_in_prev <= 16'd0;
            irq_out     <= 1'b0;
            wb_ack_o    <= 1'b0;
            wb_dat_o    <= 32'd0;
        end else begin
            wb_ack_o <= 1'b0;

            // Store previous state for edge detection
            irq_in_prev <= irq_in;

            // Update pending bits
            // Edge-triggered: set on rising edge
            pending <= (pending | (edge_rise & edge_cfg))
                     | (irq_in & ~edge_cfg);  // Level-triggered: follow input

            // IRQ output: any enabled pending source
            irq_out <= |(pending & enable);

            // Wishbone B4
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;

                if (wb_we_i) begin
                    case (wb_adr_i[4:2])
                        ADDR_PENDING: begin
                            // W1C: write 1 to clear
                            pending <= pending & ~wb_dat_i[15:0];
                        end
                        ADDR_ENABLE:   enable   <= wb_dat_i[15:0];
                        ADDR_EDGE_CFG: edge_cfg <= wb_dat_i[15:0];
                        ADDR_SOFTWARE: begin
                            // Software interrupt trigger: auto-clear after 1 cycle
                            pending <= pending | wb_dat_i[15:0];
                        end
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[4:2])
                        ADDR_PENDING:  wb_dat_o <= {16'd0, pending};
                        ADDR_ENABLE:   wb_dat_o <= {16'd0, enable};
                        ADDR_EDGE_CFG: wb_dat_o <= {16'd0, edge_cfg};
                        ADDR_SOFTWARE: wb_dat_o <= 32'd0;
                        default:       wb_dat_o <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
