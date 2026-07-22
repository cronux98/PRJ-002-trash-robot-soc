// Module: uart
// Description: UART 115200 8N1 TX+RX, Wishbone B4 slave
// Source: IP-005 v4 Architecture §4.4, REUSE_INTERNAL
// Address: 0x8000_0000 - 0x8000_0FFF
// Version: v4 — 32-bit address, irq_tx/irq_rx naming per v4 spec

module uart (
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

    // UART pins
    output reg         uart_tx,
    input  wire        uart_rx,

    // Interrupts
    output reg         irq_tx,
    output reg         irq_rx
);

    wire _unused = |{wb_adr_i[31:5], wb_adr_i[1:0], wb_dat_i[31:8], wb_sel_i};

    localparam ADDR_TXDATA = 3'h0;  // 0x00: TXDATA (write)
    localparam ADDR_RXDATA = 3'h1;  // 0x04: RXDATA (read)
    localparam ADDR_STATUS = 3'h2;  // 0x08: STATUS
    localparam ADDR_CTRL   = 3'h3;  // 0x0C: CTRL

    // Baud rate: 33.3MHz / 115200 / 16 ≈ 18
    localparam BAUD_DIV = 16'd18;

    reg [ 7:0] txdata_reg;
    reg [ 7:0] rxdata_reg;
    reg [ 7:0] status_reg;  // [0]=TX_EMPTY, [1]=RX_READY, [2]=RX_FRAME_ERR
    reg [ 2:0] ctrl_reg;    // [0]=TX_EN, [1]=RX_EN, [2]=IRQ_EN
    reg        tx_pending;

    // Baud generator
    reg [15:0] baud_counter;
    wire       baud_tick;
    assign baud_tick = (baud_counter == 16'd0);

    // RX dedicated bit timer
    reg [15:0] rx_timer;
    wire       rx_tick;
    assign rx_tick = (rx_timer == 16'd0);

    // TX FSM
    localparam TX_IDLE  = 2'd0;
    localparam TX_START = 2'd1;
    localparam TX_DATA  = 2'd2;
    localparam TX_STOP  = 2'd3;
    reg [1:0] tx_state;
    reg [3:0] tx_bit_count;
    reg [7:0] tx_shift_reg;

    // RX FSM
    localparam RX_IDLE  = 2'd0;
    localparam RX_START = 2'd1;
    localparam RX_DATA  = 2'd2;
    localparam RX_STOP  = 2'd3;
    reg [1:0] rx_state;
    reg [3:0] rx_bit_count;
    reg [7:0] rx_shift_reg;
    reg       uart_rx_d;
    reg       uart_rx_sync;
    reg       rx_done_pulse;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            tx_state     <= TX_IDLE;
            tx_bit_count <= 4'd0;
            tx_shift_reg <= 8'd0;
            uart_tx      <= 1'b1;
            rx_state     <= RX_IDLE;
            rx_bit_count <= 4'd0;
            rx_shift_reg <= 8'd0;
            rx_done_pulse <= 1'b0;
            uart_rx_sync  <= 1'b1;
            uart_rx_d     <= 1'b1;
            baud_counter  <= 16'd0;
            rx_timer      <= 16'd0;
            txdata_reg    <= 8'd0;
            ctrl_reg      <= 3'd0;
            tx_pending    <= 1'b0;
            rxdata_reg    <= 8'd0;
            status_reg    <= 8'h01;  // TX_EMPTY=1
            irq_tx        <= 1'b0;
            irq_rx        <= 1'b0;
            wb_ack_o      <= 1'b0;
            wb_dat_o      <= 32'd0;
        end else begin
            wb_ack_o      <= 1'b0;
            rx_done_pulse <= 1'b0;
            irq_tx        <= 1'b0;
            irq_rx        <= 1'b0;

            // Baud generator
            if (baud_tick)
                baud_counter <= BAUD_DIV;
            else
                baud_counter <= baud_counter - 16'd1;

            // RX timer
            if (rx_tick)
                rx_timer <= BAUD_DIV;
            else if (rx_timer != 16'd0)
                rx_timer <= rx_timer - 16'd1;

            // 2-FF sync for RX
            uart_rx_sync <= uart_rx;
            uart_rx_d    <= uart_rx_sync;

            // TX FSM
            status_reg[0] <= (tx_state == TX_IDLE);
            if (tx_state == TX_IDLE)
                irq_tx <= ctrl_reg[0];

            if (baud_tick) begin
                case (tx_state)
                    TX_IDLE: begin
                        uart_tx <= 1'b1;
                        if (ctrl_reg[0] && tx_pending) begin
                            tx_shift_reg <= txdata_reg;
                            tx_bit_count <= 4'd0;
                            tx_state     <= TX_START;
                            tx_pending   <= 1'b0;
                        end
                    end
                    TX_START: begin
                        uart_tx <= 1'b0;
                        tx_state <= TX_DATA;
                    end
                    TX_DATA: begin
                        uart_tx <= tx_shift_reg[0];
                        tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
                        tx_bit_count <= tx_bit_count + 4'd1;
                        if (tx_bit_count == 4'd7)
                            tx_state <= TX_STOP;
                    end
                    TX_STOP: begin
                        uart_tx <= 1'b1;
                        tx_state <= TX_IDLE;
                    end
                    default: tx_state <= TX_IDLE;
                endcase
            end

            // RX FSM
            if (ctrl_reg[1]) begin
                case (rx_state)
                    RX_IDLE: begin
                        if (uart_rx_d == 1'b0) begin
                            rx_timer     <= (BAUD_DIV >> 1) - 2;
                            rx_state     <= RX_START;
                            rx_bit_count <= 4'd0;
                        end
                    end
                    RX_START: begin
                        if (rx_tick) begin
                            rx_timer <= BAUD_DIV;
                            rx_state <= RX_DATA;
                        end
                    end
                    RX_DATA: begin
                        if (rx_tick) begin
                            rx_shift_reg <= {uart_rx_d, rx_shift_reg[7:1]};
                            rx_bit_count <= rx_bit_count + 4'd1;
                            if (rx_bit_count == 4'd7)
                                rx_state <= RX_STOP;
                            rx_timer <= BAUD_DIV;
                        end
                    end
                    RX_STOP: begin
                        if (rx_tick) begin
                            if (uart_rx_d == 1'b1) begin
                                rxdata_reg <= rx_shift_reg;
                                if (status_reg[1])
                                    status_reg[3] <= 1'b1;
                                status_reg[1] <= 1'b1;
                                rx_done_pulse <= 1'b1;
                            end else begin
                                status_reg[2] <= 1'b1;
                            end
                            rx_state <= RX_IDLE;
                        end
                    end
                    default: rx_state <= RX_IDLE;
                endcase
            end

            if (rx_done_pulse)
                irq_rx <= 1'b1;

            // Wishbone B4
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    case (wb_adr_i[4:2])
                        ADDR_TXDATA: begin
                            txdata_reg <= wb_dat_i[7:0];
                            tx_pending <= 1'b1;
                        end
                        ADDR_CTRL: ctrl_reg <= wb_dat_i[2:0];
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[4:2])
                        ADDR_TXDATA: wb_dat_o <= {24'd0, txdata_reg};
                        ADDR_RXDATA: begin
                            wb_dat_o      <= {24'd0, rxdata_reg};
                            status_reg[1] <= 1'b0;
                        end
                        ADDR_STATUS: wb_dat_o <= {24'd0, status_reg};
                        ADDR_CTRL:   wb_dat_o <= {29'd0, ctrl_reg};
                        default:     wb_dat_o <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
