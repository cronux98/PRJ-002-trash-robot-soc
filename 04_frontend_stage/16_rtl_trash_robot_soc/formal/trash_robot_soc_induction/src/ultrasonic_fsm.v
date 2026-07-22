// Module: ultrasonic_fsm
// Description: Dual-channel HC-SR04 ultrasonic sensor interface
// Source: ARCHITECTURE.md §4.10, CREATE
// Address: 0x1500-0x15FF
// Version: v3 — 33.3MHz timing: TRIG=333 cycles, TIMEOUT=1,265,400 cycles (38ms)

module ultrasonic_fsm (
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

    // Ultrasonic sensor
    output reg  [ 1:0] trig_o,
    input  wire [ 1:0] echo_i,

    // Interrupt
    output reg         intr_done_o
);

    wire _wb_unused = |{wb_adr_i[11:5], wb_adr_i[1:0], wb_dat_i[31:16], wb_sel_i};

    // Registers (CSR)
    // DISTANCE[0]: front (addr 0x00), DISTANCE[1]: rear (addr 0x04)
    // STATUS: [1:0]=BUSY, [3:2]=TIMEOUT, [5:4]=DONE (addr 0x08)
    // CTRL: [0]=EN, [1]=CH_SEL (addr 0x0C)
    // TIMEOUT: timeout cycles (addr 0x10)
    reg [20:0] distance_reg [0:1];
    reg [ 5:0] status_reg;
    reg [ 1:0] ctrl_reg;
    reg [20:0] timeout_reg;

    // v3 33.3MHz: 10µs trigger = 333 cycles, 38ms timeout = 1,265,400 cycles
    localparam TRIG_CYCLES      = 21'd333;
    localparam DEFAULT_TIMEOUT  = 21'd1265400;
    localparam MIN_ECHO_CYCLES  = 21'd5;

    // 2-FF synchronizers on echo inputs
    reg [1:0] echo_sync1, echo_sync2, echo_sync3, echo_sync4;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            echo_sync1 <= 2'd0;
            echo_sync2 <= 2'd0;
            echo_sync3 <= 2'd0;
            echo_sync4 <= 2'd0;
        end else begin
            echo_sync1 <= echo_i;
            echo_sync2 <= echo_sync1;
            echo_sync3 <= echo_sync2;
            echo_sync4 <= echo_sync3;
        end
    end

    // Channel FSM
    localparam FSM_IDLE       = 3'd0;
    localparam FSM_TRIGGER    = 3'd1;
    localparam FSM_WAIT_ECHO  = 3'd2;
    localparam FSM_CAPTURE    = 3'd3;
    localparam FSM_DONE       = 3'd4;

    reg [2:0] fsm_state [0:1];
    reg [20:0] counter [0:1];
    reg [20:0] capture_count [0:1];
    reg [ 4:0] glitch_filter [0:1];
    reg        done_sticky [0:1];   // sticky DONE flag, set by FSM, cleared by WB
    reg        done_clear  [0:1];   // WB requests clear of done_sticky

    genvar ch;
    generate
        for (ch = 0; ch < 2; ch = ch + 1) begin : sensor_ch
            always @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    fsm_state[ch]     <= FSM_IDLE;
                    counter[ch]       <= 21'd0;
                    capture_count[ch] <= 21'd0;
                    glitch_filter[ch] <= 5'd0;
                    done_sticky[ch]   <= 1'b0;
                end else begin
                    // Sticky DONE: set when entering DONE, cleared by WB via done_clear
                    if (done_clear[ch])
                        done_sticky[ch] <= 1'b0;
                    else if (fsm_state[ch] == FSM_DONE)
                        done_sticky[ch] <= 1'b1;
                    case (fsm_state[ch])
                        FSM_IDLE: begin
                            counter[ch]       <= 21'd0;
                            capture_count[ch] <= 21'd0;
                            glitch_filter[ch] <= 5'd0;
                            if (ctrl_reg[0] && (ch == ctrl_reg[1]))
                                fsm_state[ch] <= FSM_TRIGGER;
                        end

                        FSM_TRIGGER: begin
                            counter[ch] <= counter[ch] + 21'd1;
                            if (counter[ch] >= TRIG_CYCLES) begin
                                fsm_state[ch] <= FSM_WAIT_ECHO;
                                counter[ch]   <= 21'd0;
                            end
                        end

                        FSM_WAIT_ECHO: begin
                            counter[ch] <= counter[ch] + 21'd1;
                            if (counter[ch] >= timeout_reg) begin
                                distance_reg[ch] <= 21'h1F_FFFF;
                                fsm_state[ch]    <= FSM_DONE;
                                counter[ch]      <= 21'd0;
                            end else if (echo_sync3[ch]) begin
                                // Echo is high — count for glitch filter
                                glitch_filter[ch] <= glitch_filter[ch] + 5'd1;
                                if (glitch_filter[ch] >= MIN_ECHO_CYCLES - 1) begin
                                    fsm_state[ch]    <= FSM_CAPTURE;
                                    counter[ch]       <= 21'd0;
                                    capture_count[ch] <= 21'd0;
                                    glitch_filter[ch] <= 5'd0;
                                end
                            end else begin
                                glitch_filter[ch] <= 5'd0;
                            end
                        end

                        FSM_CAPTURE: begin
                            counter[ch] <= counter[ch] + 21'd1;
                            if (!echo_sync3[ch]) begin
                                // Echo went low — capture distance
                                distance_reg[ch] <= capture_count[ch];
                                fsm_state[ch]    <= FSM_DONE;
                            end else if (echo_sync3[ch]) begin
                                capture_count[ch] <= capture_count[ch] + 21'd1;
                            end
                            if (counter[ch] >= timeout_reg) begin
                                distance_reg[ch] <= 21'h1F_FFFF;
                                fsm_state[ch]    <= FSM_DONE;
                            end
                        end

                        FSM_DONE: begin
                            fsm_state[ch] <= FSM_IDLE;
                            counter[ch]   <= 21'd0;
                        end

                        default: fsm_state[ch] <= FSM_IDLE;
                    endcase
                end
            end
        end
    endgenerate

    // Output drivers
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            trig_o      <= 2'd0;
            intr_done_o <= 1'b0;
        end else begin
            intr_done_o <= 1'b0;
            trig_o[0]   <= (fsm_state[0] == FSM_TRIGGER);
            trig_o[1]   <= (fsm_state[1] == FSM_TRIGGER);
            if ((fsm_state[0] == FSM_DONE && ctrl_reg[1] == 1'b0) ||
                (fsm_state[1] == FSM_DONE && ctrl_reg[1] == 1'b1))
                intr_done_o <= 1'b1;
        end
    end

    // Wishbone B4 slave + status register (single block, no multi-driver)
    // DONE bits are sticky: set by FSM block (done_sticky), cleared on DIST read
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ctrl_reg    <= 2'd0;
            timeout_reg <= DEFAULT_TIMEOUT;
            wb_ack_o    <= 1'b0;
            wb_dat_o    <= 32'd0;
            status_reg  <= 6'd0;
            done_clear[0] <= 1'b0;
            done_clear[1] <= 1'b0;
        end else begin
            wb_ack_o    <= 1'b0;
            done_clear[0] <= 1'b0;  // default: clear pulse lasts one cycle
            done_clear[1] <= 1'b0;

            // --- Status register updates (BUSY, TIMEOUT are continuous; DONE from sticky) ---
            status_reg[0] <= (fsm_state[0] != FSM_IDLE);
            status_reg[1] <= (fsm_state[1] != FSM_IDLE);
            status_reg[2] <= (fsm_state[0] == FSM_DONE && distance_reg[0] == 21'h1F_FFFF);
            status_reg[3] <= (fsm_state[1] == FSM_DONE && distance_reg[1] == 21'h1F_FFFF);
            status_reg[4] <= done_sticky[0];
            status_reg[5] <= done_sticky[1];

            // --- Wishbone B4 ---
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    case (wb_adr_i[4:2])
                        3'h3: ctrl_reg    <= wb_dat_i[1:0];
                        3'h4: timeout_reg <= wb_dat_i[20:0];
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[4:2])
                        3'h0: begin
                            wb_dat_o      <= {11'd0, distance_reg[0]};
                            done_clear[0] <= 1'b1;  // clear DONE[0] on read
                        end
                        3'h1: begin
                            wb_dat_o      <= {11'd0, distance_reg[1]};
                            done_clear[1] <= 1'b1;  // clear DONE[1] on read
                        end
                        3'h2: wb_dat_o <= {26'd0, status_reg};
                        3'h3: wb_dat_o <= {30'd0, ctrl_reg};
                        3'h4: wb_dat_o <= {11'd0, timeout_reg};
                        default: wb_dat_o <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
