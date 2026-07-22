// Module: intc
// Description: Interrupt controller — 13 input lines, edge/level config, priority encoder
// Source: ARCHITECTURE.md §4.14, CREATE
// Address: 0x1900-0x19FF
// Version: v3 — BUG-005 FIXED: UP-counting priority encoder (0→12, IRQ 12 wins)

module intc (
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

    // Interrupt inputs (13 lines)
    input  wire [12:0] irq_i,

    // Output to Ibex
    output reg         meip_o,
    output reg  [ 3:0] irq_id_o
);

    // Tie off unused WB interface bits
    wire _wb_unused = |{wb_adr_i[11:5], wb_adr_i[1:0], wb_dat_i[31:13], wb_sel_i};

    localparam N_IRQ = 13;

    reg [12:0] ie_reg;
    reg [12:0] ip_reg;
    reg [12:0] int_type_reg;
    reg [12:0] int_pol_reg;

    // 2-FF synchronizers
    reg [12:0] irq_sync1, irq_sync2, irq_sync_prev;
    wire [12:0] irq_rise, irq_fall;
    assign irq_rise =  irq_sync2 & ~irq_sync_prev;
    assign irq_fall = ~irq_sync2 &  irq_sync_prev;

    integer j;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ie_reg       <= 13'd0;
            ip_reg       <= 13'd0;
            int_type_reg <= 13'd0;
            int_pol_reg  <= 13'd0;
            irq_sync1    <= 13'd0;
            irq_sync2    <= 13'd0;
            irq_sync_prev<= 13'd0;
            meip_o       <= 1'b0;
            irq_id_o     <= 4'd0;
            wb_ack_o     <= 1'b0;
            wb_dat_o     <= 32'd0;
        end else begin
            wb_ack_o <= 1'b0;

            // 2-FF synchronizer
            irq_sync1     <= irq_i;
            irq_sync2     <= irq_sync1;
            irq_sync_prev <= irq_sync2;

            // Interrupt pending update per source (edge/level)
            for (j = 0; j < N_IRQ; j = j + 1) begin
                if (int_type_reg[j]) begin
                    if (int_pol_reg[j])
                        ip_reg[j] <= ip_reg[j] | irq_rise[j];
                    else
                        ip_reg[j] <= ip_reg[j] | irq_fall[j];
                end else begin
                    ip_reg[j] <= (irq_sync2[j] == int_pol_reg[j]);
                end
            end

            // W1C on IP register (write side in WB)
            if (wb_cyc_i && wb_stb_i && wb_we_i && !wb_ack_o && wb_adr_i[4:2] == 3'h1)
                ip_reg <= ip_reg & ~wb_dat_i[12:0];

            // BUG-005 FIX: UP-counting priority encoder (0→12, IRQ 12 wins with NBA)
            // Non-blocking assignments in a for loop: the LAST iteration's assignment wins.
            // Counting UP means j=12 executes last → IRQ 12 has highest priority.
            meip_o   <= 1'b0;
            irq_id_o <= 4'd0;
            for (j = 0; j < N_IRQ; j = j + 1) begin
                if (ie_reg[j] && ip_reg[j]) begin
                    meip_o   <= 1'b1;
                    irq_id_o <= j[3:0];
                end
            end

            // Wishbone B4
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    case (wb_adr_i[4:2])
                        3'h0: ie_reg       <= wb_dat_i[12:0];
                        3'h1: ip_reg       <= ip_reg & ~wb_dat_i[12:0];
                        3'h2: int_type_reg <= wb_dat_i[12:0];
                        3'h3: int_pol_reg  <= wb_dat_i[12:0];
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[4:2])
                        3'h0: wb_dat_o <= {19'd0, ie_reg};
                        3'h1: wb_dat_o <= {19'd0, ip_reg};
                        3'h2: wb_dat_o <= {19'd0, int_type_reg};
                        3'h3: wb_dat_o <= {19'd0, int_pol_reg};
                        3'h4: wb_dat_o <= {28'd0, irq_id_o};
                        3'h5: wb_dat_o <= {24'd0, irq_id_o, 4'd0}; // VECTOR_ADDR = IRQ_ID << 2
                        default: wb_dat_o <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
