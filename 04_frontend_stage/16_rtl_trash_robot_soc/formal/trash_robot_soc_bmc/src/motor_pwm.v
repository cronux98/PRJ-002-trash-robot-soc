// Module: motor_pwm
// Description: 4-channel motor PWM controller (PHASE/ENABLE, 20kHz)
// Source: IP-005 v4 Architecture §4.6, REUSE_INTERNAL
// Address: 0x8000_2000 - 0x8000_2FFF
// Version: v4

module motor_pwm (
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

    // Motor outputs
    output reg  [3:0]  pwm_a,     // PHASE outputs
    output reg  [3:0]  pwm_b,     // ENABLE outputs
    input  wire [3:0]  fault_i,   // DRV8833 fault inputs
    output reg         irq_fault
);

    wire _unused = |{wb_adr_i[31:5], wb_adr_i[1:0], wb_dat_i[31:16], wb_sel_i};

    // PWM period: 33300000/20000 = 1665
    localparam PWM_MAX = 16'd1665;

    localparam ADDR_DUTY_A = 3'h0;
    localparam ADDR_DUTY_B = 3'h1;
    localparam ADDR_DUTY_C = 3'h2;
    localparam ADDR_DUTY_D = 3'h3;
    localparam ADDR_CTRL   = 3'h4;  // 0x10
    localparam ADDR_STATUS = 3'h5;  // 0x14

    reg [15:0] duty_a, duty_b, duty_c, duty_d;
    reg [ 7:0] ctrl;      // [3:0]=ENABLE, [7:4]=PHASE
    reg [ 3:0] status_fault;  // sticky, clear-on-read

    // PWM counter
    reg [15:0] pwm_cnt;

    // Clamped duties
    wire [15:0] duty_a_clamped, duty_b_clamped, duty_c_clamped, duty_d_clamped;
    assign duty_a_clamped = (duty_a > PWM_MAX) ? PWM_MAX : duty_a;
    assign duty_b_clamped = (duty_b > PWM_MAX) ? PWM_MAX : duty_b;
    assign duty_c_clamped = (duty_c > PWM_MAX) ? PWM_MAX : duty_c;
    assign duty_d_clamped = (duty_d > PWM_MAX) ? PWM_MAX : duty_d;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            duty_a    <= 16'd0;
            duty_b    <= 16'd0;
            duty_c    <= 16'd0;
            duty_d    <= 16'd0;
            ctrl      <= 8'd0;
            status_fault <= 4'd0;
            pwm_cnt   <= 16'd0;
            pwm_a     <= 4'd0;
            pwm_b     <= 4'd0;
            irq_fault <= 1'b0;
            wb_ack_o  <= 1'b0;
            wb_dat_o  <= 32'd0;
        end else begin
            wb_ack_o  <= 1'b0;
            irq_fault <= 1'b0;

            // PWM counter
            if (pwm_cnt >= PWM_MAX)
                pwm_cnt <= 16'd0;
            else
                pwm_cnt <= pwm_cnt + 16'd1;

            // PWM outputs: PHASE/ENABLE mode
            // CH0
            pwm_a[0] <= ctrl[4];
            pwm_b[0] <= ctrl[0] && (pwm_cnt < duty_a_clamped);
            // CH1
            pwm_a[1] <= ctrl[5];
            pwm_b[1] <= ctrl[1] && (pwm_cnt < duty_b_clamped);
            // CH2
            pwm_a[2] <= ctrl[6];
            pwm_b[2] <= ctrl[2] && (pwm_cnt < duty_c_clamped);
            // CH3
            pwm_a[3] <= ctrl[7];
            pwm_b[3] <= ctrl[3] && (pwm_cnt < duty_d_clamped);

            // Fault detection: latch on any rising edge
            status_fault <= status_fault | fault_i;
            irq_fault <= |status_fault;

            // Wishbone B4
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;

                if (wb_we_i) begin
                    case (wb_adr_i[4:2])
                        ADDR_DUTY_A: duty_a <= wb_dat_i[15:0];
                        ADDR_DUTY_B: duty_b <= wb_dat_i[15:0];
                        ADDR_DUTY_C: duty_c <= wb_dat_i[15:0];
                        ADDR_DUTY_D: duty_d <= wb_dat_i[15:0];
                        ADDR_CTRL:   ctrl   <= wb_dat_i[7:0];
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i[4:2])
                        ADDR_DUTY_A: wb_dat_o <= {16'd0, duty_a};
                        ADDR_DUTY_B: wb_dat_o <= {16'd0, duty_b};
                        ADDR_DUTY_C: wb_dat_o <= {16'd0, duty_c};
                        ADDR_DUTY_D: wb_dat_o <= {16'd0, duty_d};
                        ADDR_CTRL:   wb_dat_o <= {24'd0, ctrl};
                        ADDR_STATUS: begin
                            wb_dat_o <= {28'd0, status_fault};
                            status_fault <= 4'd0;  // clear-on-read
                        end
                        default: wb_dat_o <= 32'd0;
                    endcase
                end
            end
        end
    end

endmodule
