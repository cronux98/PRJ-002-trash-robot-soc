// Module: i2c_master
// Description: I2C master controller 100kHz, 7-bit addressing, Wishbone B4 slave
// Source: IP-005 v4 Architecture §4.5, REUSE_INTERNAL (ip-003-i2c)
// Address: 0x8000_1000 - 0x8000_1FFF
// Version: v4 — adapted for v4 spec

module i2c_master (
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

    // I2C pins
    inout  wire        scl,
    inout  wire        sda,

    // Interrupt
    output reg         irq_done
);

    wire _unused = |{wb_adr_i[31:5], wb_adr_i[1:0], wb_dat_i[31:8], wb_sel_i};

    localparam ADDR_CTRL    = 3'h0;  // 0x00: CTRL
    localparam ADDR_STATUS  = 3'h1;  // 0x04: STATUS
    localparam ADDR_ADDR    = 3'h2;  // 0x08: ADDR
    localparam ADDR_DATA    = 3'h3;  // 0x0C: DATA
    localparam ADDR_DIVIDER = 3'h4;  // 0x10: DIVIDER

    // I2C clock divider: 33.3MHz / (2*(div+1)) → 100kHz: div=166
    reg [7:0] divider;   // Default 166 (0xA6)
    reg [7:0] clk_cnt;
    wire      i2c_clk_en;
    assign i2c_clk_en = (clk_cnt == 8'd0);

    // Register bank
    reg [3:0] ctrl;      // [0]=START, [1]=STOP, [2]=READ, [3]=IRQ_EN
    reg [3:0] status;    // [0]=BUSY, [1]=DONE, [2]=ACK, [3]=ERR
    reg [6:0] addr_reg;
    reg [7:0] data_reg;
    reg       start_cmd, stop_cmd, rw_bit;

    // I2C FSM
    localparam FSM_IDLE     = 4'd0;
    localparam FSM_START    = 4'd1;
    localparam FSM_ADDR     = 4'd2;
    localparam FSM_ADDR_ACK = 4'd3;
    localparam FSM_WR_DATA  = 4'd4;
    localparam FSM_WR_ACK   = 4'd5;
    localparam FSM_RD_DATA  = 4'd6;
    localparam FSM_RD_ACK   = 4'd7;
    localparam FSM_STOP     = 4'd8;

    reg [3:0] fsm_state;
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg;

    // I2C line control
    reg scl_out, sda_out;
    reg scl_oe,  sda_oe;

    assign scl = scl_oe ? scl_out : 1'bz;
    assign sda = sda_oe ? sda_out : 1'bz;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            divider    <= 8'd166;
            clk_cnt    <= 8'd0;
            ctrl       <= 4'd0;
            status     <= 4'd0;
            addr_reg   <= 7'd0;
            data_reg   <= 8'd0;
            start_cmd  <= 1'b0;
            stop_cmd   <= 1'b0;
            rw_bit     <= 1'b0;
            fsm_state  <= FSM_IDLE;
            bit_cnt    <= 4'd0;
            shift_reg  <= 8'd0;
            scl_out    <= 1'b1;
            sda_out    <= 1'b1;
            scl_oe     <= 1'b1;
            sda_oe     <= 1'b1;
            irq_done   <= 1'b0;
            wb_ack_o   <= 1'b0;
            wb_dat_o   <= 32'd0;
        end else begin
            wb_ack_o <= 1'b0;
            irq_done <= 1'b0;

            // Clock divider
            if (i2c_clk_en)
                clk_cnt <= divider;
            else
                clk_cnt <= clk_cnt - 8'd1;

            // I2C FSM — runs on i2c_clk_en ticks
            if (i2c_clk_en) begin
                case (fsm_state)
                    FSM_IDLE: begin
                        scl_out <= 1'b1;
                        sda_out <= 1'b1;
                        status[0] <= 1'b0;  // BUSY=0
                        if (start_cmd) begin
                            fsm_state <= FSM_START;
                            status[0] <= 1'b1;  // BUSY=1
                            status[1] <= 1'b0;  // DONE=0
                            start_cmd <= 1'b0;
                        end
                    end

                    FSM_START: begin
                        // START condition: SDA low while SCL high
                        sda_out <= 1'b0;
                        fsm_state <= FSM_ADDR;
                        bit_cnt   <= 4'd7;
                        shift_reg <= {addr_reg, rw_bit};
                    end

                    FSM_ADDR: begin
                        if (bit_cnt > 0) begin
                            sda_out <= shift_reg[7];
                            shift_reg <= {shift_reg[6:0], 1'b0};
                            bit_cnt <= bit_cnt - 4'd1;
                        end else begin
                            sda_out <= shift_reg[7];
                            sda_oe  <= 1'b0;  // Release SDA for ACK
                            fsm_state <= FSM_ADDR_ACK;
                        end
                    end

                    FSM_ADDR_ACK: begin
                        sda_oe  <= 1'b0;  // Release SDA for ACK
                        sda_out <= 1'b1;
                        if (~sda) begin
                            status[2] <= 1'b1;  // ACK received
                            status[3] <= 1'b0;
                            if (rw_bit)
                                fsm_state <= FSM_RD_DATA;
                            else
                                fsm_state <= FSM_WR_DATA;
                            bit_cnt <= 4'd7;
                        end else begin
                            status[3] <= 1'b1;  // ERR: NACK
                            fsm_state <= FSM_STOP;
                        end
                    end

                    FSM_WR_DATA: begin
                        if (bit_cnt > 0) begin
                            sda_out <= shift_reg[7];
                            shift_reg <= {shift_reg[6:0], 1'b0};
                            bit_cnt <= bit_cnt - 4'd1;
                        end else begin
                            sda_out <= shift_reg[7];
                            sda_oe  <= 1'b0;
                            fsm_state <= FSM_WR_ACK;
                        end
                    end

                    FSM_WR_ACK: begin
                        sda_oe <= 1'b1;
                        sda_out <= 1'b1;
                        if (stop_cmd) begin
                            fsm_state <= FSM_STOP;
                            stop_cmd <= 1'b0;
                        end else begin
                            shift_reg <= data_reg;
                            bit_cnt   <= 4'd7;
                            fsm_state <= FSM_WR_DATA;
                        end
                    end

                    FSM_RD_DATA: begin
                        sda_oe <= 1'b0;  // Release SDA
                        if (bit_cnt > 0) begin
                            shift_reg <= {shift_reg[6:0], sda};
                            bit_cnt <= bit_cnt - 4'd1;
                        end else begin
                            shift_reg <= {shift_reg[6:0], sda};
                            data_reg <= {shift_reg[6:0], sda};
                            sda_oe <= 1'b1;
                            sda_out <= 1'b0;  // NACK (master ends read)
                            fsm_state <= FSM_RD_ACK;
                        end
                    end

                    FSM_RD_ACK: begin
                        sda_out <= 1'b1;
                        fsm_state <= FSM_STOP;
                    end

                    FSM_STOP: begin
                        // STOP: SDA high while SCL high
                        sda_out <= 1'b0;
                        // Next half-cycle
                        fsm_state <= FSM_IDLE;
                        status[1] <= 1'b1;  // DONE=1
                        status[0] <= 1'b0;  // BUSY=0
                    end

                    default: fsm_state <= FSM_IDLE;
                endcase

                // SCL toggling (every i2c_clk_en)
                if (fsm_state != FSM_IDLE && fsm_state != FSM_STOP)
                    scl_out <= ~scl_out;
                else
                    scl_out <= 1'b1;

                // IRQ on DONE
                if (status[1] && ctrl[3])
                    irq_done <= 1'b1;
            end

            // Wishbone B4 slave
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;

                if (wb_we_i) begin
                    case (wb_adr_i[4:2])
                        ADDR_CTRL: begin
                            ctrl <= wb_dat_i[3:0];
                            if (wb_dat_i[0]) start_cmd <= 1'b1;
                            if (wb_dat_i[1]) stop_cmd  <= 1'b1;
                            rw_bit <= wb_dat_i[2];
                        end
                        ADDR_ADDR:    addr_reg <= wb_dat_i[6:0];
                        ADDR_DATA:    data_reg <= wb_dat_i[7:0];
                        ADDR_DIVIDER: divider  <= wb_dat_i[7:0];
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[4:2])
                        ADDR_CTRL:    wb_dat_o <= {28'd0, ctrl};
                        ADDR_STATUS:  wb_dat_o <= {28'd0, status};
                        ADDR_ADDR:    wb_dat_o <= {25'd0, addr_reg};
                        ADDR_DATA:    wb_dat_o <= {24'd0, data_reg};
                        ADDR_DIVIDER: wb_dat_o <= {24'd0, divider};
                        default:      wb_dat_o <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
