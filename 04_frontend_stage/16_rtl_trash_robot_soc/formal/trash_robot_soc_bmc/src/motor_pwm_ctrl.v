// Module: motor_pwm_ctrl
// Description: 4-channel motor PWM with dead-time insertion for DRV8833 H-bridge
// Source: ARCHITECTURE.md §4.10, CREATE
// Address: 0x7000-0x7FFF

module motor_pwm_ctrl (
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

    // Motor H-bridge outputs (4 channels)
    output reg  [ 3:0] motor_in1_o,
    output reg  [ 3:0] motor_in2_o,

    // Interrupt
    output reg         intr_fault_o
);

    // Tie off unused WB interface bits (standard bus - all bits present for compatibility)
    wire _wb_unused = |{wb_adr_i[11:5], wb_adr_i[1:0], wb_dat_i[31:10], wb_sel_i};

    // =========================================================================
    // Parameters
    // =========================================================================
    
    // =========================================================================
    // Registers — 14 CSRs total
    // =========================================================================
    // PERIOD[0-3]: PWM period in sys_clk cycles
    reg [9:0] period_reg [0:3];
    // DUTY[0-3]: duty cycle value (DUTY ≤ PERIOD)
    reg [9:0] duty_reg [0:3];
    // DEAD_TIME[0-3]: dead-time in sys_clk cycles (min 1)
    reg [7:0] dead_time_reg [0:3];
    // ENABLE[3:0]: per-channel enable
    reg [3:0] enable_reg;
    // DIR[3:0]: per-channel direction (0=IN1 active, 1=IN2 active)
    reg [3:0] dir_reg;

    // =========================================================================
    // Per-channel counters and FSM state
    // =========================================================================
    reg [9:0] pwm_counter [0:3];
    reg [7:0] dead_counter [0:3];


    // We encode a 5-state FSM per channel
    localparam FSM_IDLE     = 3'd0;
    localparam FSM_IN1_ON   = 3'd1;
    localparam FSM_DEAD1    = 3'd2;
    localparam FSM_IN2_ON   = 3'd3;
    localparam FSM_DEAD2    = 3'd4;

    reg [2:0] fsm_state [0:3];
    reg [3:0] in1_next;
    reg [3:0] in2_next;

    // =========================================================================
    // Per-channel PWM generation
    // =========================================================================
    genvar ch;
    generate
        for (ch = 0; ch < 4; ch = ch + 1) begin : pwm_channel
            always @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    pwm_counter[ch]  <= 10'd0;
                    dead_counter[ch] <= 8'd0;
                    fsm_state[ch]    <= FSM_IDLE;
                end else if (enable_reg[ch]) begin
                    case (fsm_state[ch])
                        FSM_IDLE: begin
                            pwm_counter[ch] <= 10'd0;
                            if (period_reg[ch] != 10'd0 && duty_reg[ch] != 10'd0) begin
                                fsm_state[ch] <= FSM_IN1_ON;
                            end
                        end

                        FSM_IN1_ON: begin
                            pwm_counter[ch] <= pwm_counter[ch] + 10'd1;
                            if (pwm_counter[ch] >= duty_reg[ch]) begin
                                // End of ON time — begin dead-time
                                dead_counter[ch] <= 8'd0;
                                fsm_state[ch]    <= FSM_DEAD1;
                            end
                        end

                        FSM_DEAD1: begin
                            dead_counter[ch] <= dead_counter[ch] + 8'd1;
                            if (dead_counter[ch] >= dead_time_reg[ch]) begin
                                fsm_state[ch] <= FSM_IN2_ON;
                            end
                        end

                        FSM_IN2_ON: begin
                            pwm_counter[ch] <= pwm_counter[ch] + 10'd1;
                            if (pwm_counter[ch] >= period_reg[ch]) begin
                                // End of period — begin dead-time
                                dead_counter[ch] <= 8'd0;
                                fsm_state[ch]    <= FSM_DEAD2;
                            end
                        end

                        FSM_DEAD2: begin
                            dead_counter[ch] <= dead_counter[ch] + 8'd1;
                            if (dead_counter[ch] >= dead_time_reg[ch]) begin
                                fsm_state[ch]    <= FSM_IDLE;
                                pwm_counter[ch]   <= 10'd0;
                            end
                        end

                        default: fsm_state[ch] <= FSM_IDLE;
                    endcase
                end else begin
                    fsm_state[ch]    <= FSM_IDLE;
                    pwm_counter[ch]  <= 10'd0;
                    dead_counter[ch] <= 8'd0;
                end
            end
        end
    endgenerate

    // =========================================================================
    // Output drivers with hardware dead-time interlock
    // =========================================================================
    integer j;
    always @(fsm_state[0] or fsm_state[1] or fsm_state[2] or fsm_state[3] or enable_reg or dir_reg) begin
        in1_next = 4'd0;
        in2_next = 4'd0;

        for (j = 0; j < 4; j = j + 1) begin
            if (!enable_reg[j]) begin
                // Channel disabled — both outputs low
                in1_next[j] = 1'b0;
                in2_next[j] = 1'b0;
            end else begin
                case (fsm_state[j])
                    FSM_IN1_ON: begin
                        if (dir_reg[j])
                            in2_next[j] = 1'b1;
                        else
                            in1_next[j] = 1'b1;
                    end
                    FSM_IN2_ON: begin
                        if (dir_reg[j])
                            in1_next[j] = 1'b1;
                        else
                            in2_next[j] = 1'b1;
                    end
                    // FSM_IDLE, FSM_DEAD1, FSM_DEAD2: both low (dead-time)
                    default: begin
                        in1_next[j] = 1'b0;
                        in2_next[j] = 1'b0;
                    end
                endcase
            end
        end
    end

    // =========================================================================
    // Registered outputs + hardware interlock
    // =========================================================================
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            motor_in1_o   <= 4'd0;
            motor_in2_o   <= 4'd0;
            intr_fault_o  <= 1'b0;
        end else begin
            intr_fault_o <= 1'b0;

            for (j = 0; j < 4; j = j + 1) begin
                // Hardware interlock: IN1 and IN2 never simultaneously high
                if (in1_next[j] && in2_next[j]) begin
                    motor_in1_o[j] <= 1'b0;
                    motor_in2_o[j] <= 1'b0;
                    intr_fault_o   <= 1'b1;  // Dead-time violation!
                end else begin
                    motor_in1_o[j] <= in1_next[j];
                    motor_in2_o[j] <= in2_next[j];
                end
            end
        end
    end

    // =========================================================================
    // Wishbone B4 slave — register map
    // =========================================================================
    // Register layout (4KB aligned, 4 per channel):
    // 0x00: PERIOD[0]   0x10: DUTY[0]   0x20: DEAD_TIME[0]
    // 0x04: PERIOD[1]   0x14: DUTY[1]   0x24: DEAD_TIME[1]
    // 0x08: PERIOD[2]   0x18: DUTY[2]   0x28: DEAD_TIME[2]
    // 0x0C: PERIOD[3]   0x1C: DUTY[3]   0x2C: DEAD_TIME[3]
    // 0x30: ENABLE + DIR
    wire [1:0] reg_ch;
    assign reg_ch = wb_adr_i[3:2];  // 4 channels, word-aligned

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            period_reg[0]    <= 10'd0;
            period_reg[1]    <= 10'd0;
            period_reg[2]    <= 10'd0;
            period_reg[3]    <= 10'd0;
            duty_reg[0]      <= 10'd0;
            duty_reg[1]      <= 10'd0;
            duty_reg[2]      <= 10'd0;
            duty_reg[3]      <= 10'd0;
            dead_time_reg[0] <= 8'd1;  // minimum 1-cycle dead-time
            dead_time_reg[1] <= 8'd1;
            dead_time_reg[2] <= 8'd1;
            dead_time_reg[3] <= 8'd1;
            enable_reg       <= 4'd0;
            dir_reg          <= 4'd0;
            wb_ack_o         <= 1'b0;
            wb_dat_o         <= 32'd0;
        end else begin
            wb_ack_o <= 1'b0;

            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;

                if (wb_we_i) begin
                    case (wb_adr_i[5:4])
                        2'd0: period_reg[reg_ch] <= wb_dat_i[9:0];  // PERIOD
                        2'd1: duty_reg[reg_ch]   <= wb_dat_i[9:0];  // DUTY
                        2'd2: begin
                            // Enforce minimum 1-cycle dead-time
                            dead_time_reg[reg_ch] <= (wb_dat_i[7:0] == 8'd0) ? 8'd1 : wb_dat_i[7:0];
                        end
                        2'd3: begin
                            enable_reg <= wb_dat_i[3:0];
                            dir_reg    <= wb_dat_i[7:4];
                        end
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[5:4])
                        2'd0: wb_dat_o <= {22'd0, period_reg[reg_ch]};
                        2'd1: wb_dat_o <= {22'd0, duty_reg[reg_ch]};
                        2'd2: wb_dat_o <= {24'd0, dead_time_reg[reg_ch]};
                        2'd3: wb_dat_o <= {24'd0, dir_reg, enable_reg};
                        default: wb_dat_o <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
