// Module: i2c_controller
// Description: I2C master, 100kHz, 7-bit addressing, WB B4 slave
// Source: ARCHITECTURE.md §4.6, CREATE
// Address: 0x1100-0x11FF
// Version: v3 — 33.3MHz, I2C_HALF=166, verilator _o/_i naming

module i2c_controller (
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

    // I2C bus
    output reg         i2c_scl_o,
    output reg         i2c_sda_oe,
    input  wire        i2c_sda_i,
    output reg         i2c_sda_o,

    output reg         intr_done_o
);

    wire _wb_unused = |{wb_adr_i[11:5], wb_adr_i[1:0], wb_dat_i[31:8], wb_sel_i};

    localparam ADDR_TXDATA = 3'h0;
    localparam ADDR_RXDATA = 3'h1;
    localparam ADDR_STATUS = 3'h2;
    localparam ADDR_CTRL   = 3'h3;
    localparam ADDR_ADDR   = 3'h4;

    reg [ 7:0] txdata_reg;
    reg [ 7:0] rxdata_reg;
    reg [ 7:0] status_reg;
    reg [ 1:0] ctrl_reg;
    reg [ 6:0] addr_reg;

    // I2C clock: 33.3MHz → 100kHz SCL, half-period ≈ 166 cycles
    localparam I2C_HALF = 16'd166;
    reg [15:0] clk_counter;
    wire       i2c_tick;
    assign i2c_tick = (clk_counter == 16'd0);

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            clk_counter <= I2C_HALF;
        end else if (ctrl_reg[0]) begin
            if (i2c_tick)
                clk_counter <= I2C_HALF;
            else
                clk_counter <= clk_counter - 16'd1;
        end
    end

    // I2C FSM: START → ADDR+R/W → ACK → DATA → ACK → ... → STOP
    localparam FSM_IDLE       = 4'd0;
    localparam FSM_START      = 4'd1;
    localparam FSM_ADDR       = 4'd2;
    localparam FSM_ADDR_ACK   = 4'd3;
    localparam FSM_WR_DATA    = 4'd4;
    localparam FSM_WR_ACK     = 4'd5;
    localparam FSM_RD_DATA    = 4'd6;
    localparam FSM_RD_ACK     = 4'd7;
    localparam FSM_STOP       = 4'd8;
    localparam FSM_DONE       = 4'd9;

    reg [3:0] fsm_state;
    reg [3:0] bit_count;
    reg [7:0] shift_reg;
    reg [1:0] scl_phase;
    reg       sda_sampled;

    // Merged always block: I2C FSM + Wishbone B4 slave (no multi-driver)
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            fsm_state   <= FSM_IDLE;
            bit_count   <= 4'd0;
            shift_reg   <= 8'd0;
            scl_phase   <= 2'd0;
            sda_sampled <= 1'b1;
            i2c_scl_o   <= 1'b1;
            i2c_sda_o   <= 1'b1;
            i2c_sda_oe  <= 1'b0;
            rxdata_reg  <= 8'd0;
            intr_done_o <= 1'b0;
            status_reg  <= 8'd0;
            txdata_reg  <= 8'd0;
            ctrl_reg    <= 2'd0;
            addr_reg    <= 7'd0;
            wb_ack_o    <= 1'b0;
            wb_dat_o    <= 32'd0;
        end else begin
            intr_done_o  <= 1'b0;
            wb_ack_o     <= 1'b0;
            status_reg[0] <= (fsm_state != FSM_IDLE && fsm_state != FSM_DONE);

            // --- I2C clock tick handling ---
            if (i2c_tick && (fsm_state != FSM_IDLE))
                scl_phase <= scl_phase + 2'd1;

            if (scl_phase == 2'd2)
                sda_sampled <= i2c_sda_i;

            // --- I2C FSM ---
            case (fsm_state)
                FSM_IDLE: begin
                    i2c_scl_o  <= 1'b1;
                    i2c_sda_o  <= 1'b1;
                    i2c_sda_oe <= 1'b0;
                    scl_phase  <= 2'd0;
                    if (ctrl_reg[0] && wb_cyc_i && wb_stb_i && wb_we_i && wb_adr_i[4:2] == ADDR_CTRL && !wb_ack_o) begin
                        fsm_state  <= FSM_START;
                        bit_count  <= 4'd0;
                    end
                end

                FSM_START: begin
                    i2c_scl_o  <= 1'b1;
                    i2c_sda_o  <= 1'b0;
                    i2c_sda_oe <= 1'b1;
                    if (scl_phase == 2'd2)
                        i2c_scl_o <= 1'b0;
                    if (scl_phase == 2'd3 && i2c_tick) begin
                        fsm_state  <= FSM_ADDR;
                        bit_count  <= 4'd7;
                        shift_reg  <= {addr_reg, ctrl_reg[1]};
                        scl_phase  <= 2'd0;
                    end
                end

                FSM_ADDR: begin
                    if (scl_phase == 2'd0) begin
                        i2c_sda_o <= shift_reg[7];
                        i2c_scl_o <= 1'b0;
                    end else if (scl_phase == 2'd2) begin
                        i2c_scl_o <= 1'b1;
                    end else if (scl_phase == 2'd3 && i2c_tick) begin
                        i2c_scl_o <= 1'b0;
                        shift_reg <= {shift_reg[6:0], 1'b0};
                        if (bit_count == 4'd0)
                            fsm_state <= FSM_ADDR_ACK;
                        else
                            bit_count <= bit_count - 4'd1;
                        scl_phase <= 2'd0;
                    end
                end

                FSM_ADDR_ACK: begin
                    i2c_sda_oe <= 1'b0;
                    if (scl_phase == 2'd2)
                        i2c_scl_o <= 1'b1;
                    else if (scl_phase == 2'd3 && i2c_tick) begin
                        i2c_scl_o <= 1'b0;
                        if (sda_sampled == 1'b1) begin
                            status_reg[1] <= 1'b1;
                            fsm_state <= FSM_STOP;
                        end else begin
                            if (ctrl_reg[1]) begin
                                fsm_state <= FSM_RD_DATA;
                            end else begin
                                shift_reg <= txdata_reg;
                                fsm_state <= FSM_WR_DATA;
                            end
                            bit_count <= 4'd7;
                        end
                        scl_phase <= 2'd0;
                    end
                end

                FSM_WR_DATA: begin
                    i2c_sda_oe <= 1'b1;
                    if (scl_phase == 2'd0)
                        i2c_sda_o <= shift_reg[7];
                    else if (scl_phase == 2'd2)
                        i2c_scl_o <= 1'b1;
                    else if (scl_phase == 2'd3 && i2c_tick) begin
                        i2c_scl_o <= 1'b0;
                        shift_reg <= {shift_reg[6:0], 1'b0};
                        if (bit_count == 4'd0)
                            fsm_state <= FSM_WR_ACK;
                        else
                            bit_count <= bit_count - 4'd1;
                        scl_phase <= 2'd0;
                    end
                end

                FSM_WR_ACK: begin
                    i2c_sda_oe <= 1'b0;
                    if (scl_phase == 2'd2)
                        i2c_scl_o <= 1'b1;
                    else if (scl_phase == 2'd3 && i2c_tick) begin
                        i2c_scl_o <= 1'b0;
                        if (sda_sampled == 1'b1)
                            status_reg[1] <= 1'b1;
                        fsm_state <= FSM_STOP;
                        scl_phase <= 2'd0;
                    end
                end

                FSM_RD_DATA: begin
                    i2c_sda_oe <= 1'b0;
                    if (scl_phase == 2'd2)
                        i2c_scl_o <= 1'b1;
                    else if (scl_phase == 2'd3 && i2c_tick) begin
                        i2c_scl_o <= 1'b0;
                        shift_reg <= {shift_reg[6:0], i2c_sda_i};
                        if (bit_count == 4'd0)
                            fsm_state <= FSM_RD_ACK;
                        else
                            bit_count <= bit_count - 4'd1;
                        scl_phase <= 2'd0;
                    end
                end

                FSM_RD_ACK: begin
                    i2c_sda_oe <= 1'b1;
                    i2c_sda_o  <= 1'b1;
                    if (scl_phase == 2'd2)
                        i2c_scl_o <= 1'b1;
                    else if (scl_phase == 2'd3 && i2c_tick) begin
                        i2c_scl_o <= 1'b0;
                        rxdata_reg  <= shift_reg;
                        fsm_state   <= FSM_STOP;
                        scl_phase   <= 2'd0;
                    end
                end

                FSM_STOP: begin
                    i2c_sda_o  <= 1'b0;
                    i2c_sda_oe <= 1'b1;
                    if (scl_phase == 2'd0) begin
                        i2c_sda_o <= 1'b0;
                        i2c_scl_o <= 1'b0;
                    end else if (scl_phase == 2'd2)
                        i2c_scl_o <= 1'b1;
                    else if (scl_phase == 2'd3 && i2c_tick) begin
                        i2c_sda_o  <= 1'b1;
                        i2c_sda_oe <= 1'b0;
                        fsm_state  <= FSM_DONE;
                        scl_phase  <= 2'd0;
                    end
                end

                FSM_DONE: begin
                    i2c_scl_o   <= 1'b1;
                    i2c_sda_o   <= 1'b1;
                    i2c_sda_oe  <= 1'b0;
                    status_reg[3] <= 1'b1;
                    status_reg[0] <= 1'b0;
                    intr_done_o <= 1'b1;
                    fsm_state   <= FSM_IDLE;
                end

                default: fsm_state <= FSM_IDLE;
            endcase

            // --- Wishbone B4 ---
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    case (wb_adr_i[4:2])
                        ADDR_TXDATA: txdata_reg <= wb_dat_i[7:0];
                        ADDR_CTRL:   ctrl_reg   <= wb_dat_i[1:0];
                        ADDR_ADDR:   addr_reg   <= wb_dat_i[6:0];
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[4:2])
                        ADDR_TXDATA: wb_dat_o <= {24'd0, txdata_reg};
                        ADDR_RXDATA: begin
                            wb_dat_o      <= {24'd0, rxdata_reg};
                            status_reg[3] <= 1'b0;
                        end
                        ADDR_STATUS: wb_dat_o <= {24'd0, status_reg};
                        ADDR_CTRL:   wb_dat_o <= {30'd0, ctrl_reg};
                        ADDR_ADDR:   wb_dat_o <= {25'd0, addr_reg};
                        default:     wb_dat_o <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
