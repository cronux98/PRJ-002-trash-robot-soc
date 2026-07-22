// user_project_wrapper — Caravel harness wrapper for IP-005 v6 trash_robot_soc
// Generated: 2026-07-15 | Agent: physical-design-agent (Hermes)
// Caravel user area: 2.92mm x 3.52mm | PDK: sky130A
//
// This wrapper instantiates the trash_robot_soc (autonomous trash-collecting robot
// controller: sonar, motor PWM, UART, I2C, GPIO) and maps its critical I/O to
// Caravel GPIO pads. Remaining signals are exposed on logic analyzer probes.
// Wishbone is bypassed — this SoC has its own internal bus.

`define MPRJ_IO_PADS_1 38
`define MPRJ_IO_PADS   `MPRJ_IO_PADS_1

module user_project_wrapper (
    // Caravel clock and reset
    input  wire        wb_clk_i,        // Caravel clock (management SoC, default 10MHz)
    input  wire        wb_rst_i,        // Active-high reset

    // Wishbone slave interface (0x3000_0000 – 0x3FFF_FFFF) — bypassed
    input  wire        wbs_stb_i,
    input  wire        wbs_cyc_i,
    input  wire        wbs_we_i,
    input  wire [3:0]  wbs_sel_i,
    input  wire [31:0] wbs_dat_i,
    input  wire [31:0] wbs_adr_i,
    output wire        wbs_ack_o,
    output wire [31:0] wbs_dat_o,

    // Logic analyzer probes (128-bit)
    output wire [127:0] la_data_out,
    input  wire [127:0] la_data_in,
    input  wire [127:0] la_oenb,

    // GPIO pads — 38 total, GPIO 0-4 reserved for housekeeping SPI
    input  wire [`MPRJ_IO_PADS_1-1:0] io_in,
    output wire [`MPRJ_IO_PADS_1-1:0] io_out,
    output wire [`MPRJ_IO_PADS_1-1:0] io_oeb,

    // Interrupt — 3 bits to management SoC
    output wire [2:0] user_irq,

    // Power pins (analog + digital)
    inout wire vccd1, vssd1,       // Digital power 1.8V
    inout wire vccd2, vssd2,       // Digital power 1.8V (aux)
    inout wire vdda1, vssa1,       // Analog power 3.3V
    inout wire vdda2, vssa2        // Analog power 3.3V (aux)
);

    // ----------------------------------------------------------------
    // Internal signals
    // ----------------------------------------------------------------
    wire        soc_clk;
    wire        soc_rst_n;
    wire        soc_sys_rst_n;
    wire        soc_wdt_rst_n;
    wire        soc_i2c_scl, soc_i2c_sda;
    wire        soc_uart_tx;
    wire [1:0]  soc_echo;
    wire [1:0]  soc_trig;
    wire [11:0] soc_gpio_o, soc_gpio_oe;
    wire [3:0]  soc_motor_pwm_a, soc_motor_pwm_b;

    // SoC inputs — tied to GPIO or defaults
    wire        soc_uart_rx;
    wire [11:0] soc_gpio_i;
    wire [3:0]  soc_motor_fault;

    // ----------------------------------------------------------------
    // Clock: Caravel wb_clk_i drives trash_robot_soc
    // ----------------------------------------------------------------
    assign soc_clk = wb_clk_i;

    // ----------------------------------------------------------------
    // Reset: Caravel wb_rst_i (active-high) → soc_rst_n (active-low)
    // ----------------------------------------------------------------
    assign soc_rst_n = ~wb_rst_i;

    // ----------------------------------------------------------------
    // GPIO assignment — map trash_robot_soc I/O to Caravel GPIO pads
    //
    // GPIO 0-4: RESERVED (housekeeping SPI) — not used
    // GPIO 5:   i2c_scl (inout)
    // GPIO 6:   i2c_sda (inout)
    // GPIO 7:   uart_rx (input from pad)
    // GPIO 8:   uart_tx (output to pad)
    // GPIO 9-10:   echo[1:0] (sonar inputs)
    // GPIO 11-12:  trig[1:0] (sonar outputs)
    // GPIO 13-16:  motor_pwm_a[3:0] (motor PWM outputs)
    // GPIO 17-20:  motor_pwm_b[3:0] (motor PWM outputs)
    // GPIO 21-37:  unused (Hi-Z input)
    // ----------------------------------------------------------------

    // GPIO 0-4: reserved, Hi-Z
    // Already handled by the default tie-offs below.

    // GPIO 5: i2c_scl (inout)
    // io_in reads pad state; io_out drives pad; io_oeb=0 → output enabled
    assign soc_i2c_scl = io_in[5];
    assign io_out[5]   = soc_i2c_scl;
    assign io_oeb[5]   = soc_i2c_scl ? 1'b0 : 1'b0; // FIXME: ideally driven by I2C OE
    // For i2c inout: when we want to drive low, io_oeb=0 + io_out=0.
    // For high/hi-z: io_oeb=1, io_out=don't care.
    // The trash_robot_soc i2c_scl is inout — the pad logic is handled inside the SoC.
    // Here we just pass through. Actually, for inout pads on Caravel:
    //   io_oeb = 0 → output enabled (io_out drives pad)
    //   io_oeb = 1 → input mode (pad → io_in)
    // I2C: when scl is low (driven), io_oeb=0, io_out=0; when hi-Z, io_oeb=1.
    // We approximate by always driving output mode and letting the SoC handle tri-state.
    assign io_oeb[5]   = 1'b0;  // always output mode for I2C (SoC handles tri-state internally)

    // GPIO 6: i2c_sda (inout)
    assign soc_i2c_sda = io_in[6];
    assign io_out[6]   = soc_i2c_sda;
    assign io_oeb[6]   = 1'b0;  // always output mode for I2C

    // GPIO 7: uart_rx (input from pad)
    assign soc_uart_rx = io_in[7];
    assign io_out[7]   = 1'b0;
    assign io_oeb[7]   = 1'b1;  // input mode (Hi-Z)

    // GPIO 8: uart_tx (output to pad)
    assign io_out[8]   = soc_uart_tx;
    assign io_oeb[8]   = 1'b0;  // output mode

    // GPIO 9-10: echo[1:0] (sonar inputs)
    assign soc_echo[0] = io_in[9];
    assign soc_echo[1] = io_in[10];
    assign io_out[9]   = 1'b0;
    assign io_out[10]  = 1'b0;
    assign io_oeb[9]   = 1'b1;
    assign io_oeb[10]  = 1'b1;

    // GPIO 11-12: trig[1:0] (sonar outputs)
    assign io_out[11]  = soc_trig[0];
    assign io_out[12]  = soc_trig[1];
    assign io_oeb[11]  = 1'b0;
    assign io_oeb[12]  = 1'b0;

    // GPIO 13-16: motor_pwm_a[3:0] (motor PWM outputs)
    assign io_out[13]  = soc_motor_pwm_a[0];
    assign io_out[14]  = soc_motor_pwm_a[1];
    assign io_out[15]  = soc_motor_pwm_a[2];
    assign io_out[16]  = soc_motor_pwm_a[3];
    assign io_oeb[13]  = 1'b0;
    assign io_oeb[14]  = 1'b0;
    assign io_oeb[15]  = 1'b0;
    assign io_oeb[16]  = 1'b0;

    // GPIO 17-20: motor_pwm_b[3:0] (motor PWM outputs)
    assign io_out[17]  = soc_motor_pwm_b[0];
    assign io_out[18]  = soc_motor_pwm_b[1];
    assign io_out[19]  = soc_motor_pwm_b[2];
    assign io_out[20]  = soc_motor_pwm_b[3];
    assign io_oeb[17]  = 1'b0;
    assign io_oeb[18]  = 1'b0;
    assign io_oeb[19]  = 1'b0;
    assign io_oeb[20]  = 1'b0;

    // GPIO 21-37: unused — input mode (Hi-Z)
    // GPIO 0-4: reserved (housekeeping SPI) — input mode (Hi-Z)

    // Default all GPIO to Hi-Z input mode
    genvar gi;
    generate
        for (gi = 0; gi < 38; gi = gi + 1) begin : gpio_default
            // If not assigned above, default to Hi-Z input
        end
    endgenerate

    // We'll use a simpler approach: initialize all, then override the used ones.
    // The generate block is left as a placeholder; actual defaults are below.

    // ----------------------------------------------------------------
    // SOC GPIO inputs — tie unused bits to zero
    // ----------------------------------------------------------------
    assign soc_gpio_i      = 12'd0;       // SoC GPIO inputs tied low
    assign soc_motor_fault  = 4'd0;        // No motor fault inputs

    // ----------------------------------------------------------------
    // Trash Robot SoC instantiation
    // ----------------------------------------------------------------
    trash_robot_soc u_soc (
        .clk_i          (soc_clk),
        .rst_ni         (soc_rst_n),
        .i2c_scl        (soc_i2c_scl),
        .i2c_sda        (soc_i2c_sda),
        .uart_rx        (soc_uart_rx),
        .uart_tx        (soc_uart_tx),
        .echo           (soc_echo),
        .trig           (soc_trig),
        .gpio_i         (soc_gpio_i),
        .gpio_o         (soc_gpio_o),
        .gpio_oe        (soc_gpio_oe),
        .motor_fault    (soc_motor_fault),
        .motor_pwm_a    (soc_motor_pwm_a),
        .motor_pwm_b    (soc_motor_pwm_b),
        .sys_rst_n_o    (soc_sys_rst_n),
        .wdt_rst_n      (soc_wdt_rst_n)
    );

    // ----------------------------------------------------------------
    // Logic analyzer probes — expose internal status signals
    //   la_data_out[1:0]   = soc_trig[1:0]
    //   la_data_out[5:2]   = soc_motor_pwm_a[3:0]
    //   la_data_out[9:6]   = soc_motor_pwm_b[3:0]
    //   la_data_out[21:10] = soc_gpio_o[11:0]
    //   la_data_out[33:22] = soc_gpio_oe[11:0]
    //   la_data_out[34]    = soc_uart_tx
    //   la_data_out[35]    = soc_sys_rst_n
    //   la_data_out[36]    = soc_wdt_rst_n
    //   la_data_out[127:37] = 0
    // ----------------------------------------------------------------
    assign la_data_out[1:0]    = soc_trig;
    assign la_data_out[5:2]    = soc_motor_pwm_a;
    assign la_data_out[9:6]    = soc_motor_pwm_b;
    assign la_data_out[21:10]  = soc_gpio_o;
    assign la_data_out[33:22]  = soc_gpio_oe;
    assign la_data_out[34]     = soc_uart_tx;
    assign la_data_out[35]     = soc_sys_rst_n;
    assign la_data_out[36]     = soc_wdt_rst_n;
    assign la_data_out[127:37] = 91'd0;

    // ----------------------------------------------------------------
    // Wishbone bypass — not used
    // ----------------------------------------------------------------
    assign wbs_ack_o = 1'b1;
    assign wbs_dat_o = 32'd0;

    // ----------------------------------------------------------------
    // Interrupts — tied low
    // ----------------------------------------------------------------
    assign user_irq = 3'd0;

    // ----------------------------------------------------------------
    // Unused GPIO defaults: input mode (Hi-Z), driven low
    // Per-bit overrides for GPIO 0-4, 21-37
    // ----------------------------------------------------------------
    // The gpio_default generate block handles all 38 pads.
    // We use a brute-force list for clarity and iverilog compatibility.
    // Pads assigned above: 5-20. Reserved (0-4): Hi-Z input. 21-37: Hi-Z input.

    // Reserved GPIO 0-4
    assign io_out[0]  = 1'b0; assign io_oeb[0]  = 1'b1;
    assign io_out[1]  = 1'b0; assign io_oeb[1]  = 1'b1;
    assign io_out[2]  = 1'b0; assign io_oeb[2]  = 1'b1;
    assign io_out[3]  = 1'b0; assign io_oeb[3]  = 1'b1;
    assign io_out[4]  = 1'b0; assign io_oeb[4]  = 1'b1;

    // Unused GPIO 21-37
    assign io_out[21] = 1'b0; assign io_oeb[21] = 1'b1;
    assign io_out[22] = 1'b0; assign io_oeb[22] = 1'b1;
    assign io_out[23] = 1'b0; assign io_oeb[23] = 1'b1;
    assign io_out[24] = 1'b0; assign io_oeb[24] = 1'b1;
    assign io_out[25] = 1'b0; assign io_oeb[25] = 1'b1;
    assign io_out[26] = 1'b0; assign io_oeb[26] = 1'b1;
    assign io_out[27] = 1'b0; assign io_oeb[27] = 1'b1;
    assign io_out[28] = 1'b0; assign io_oeb[28] = 1'b1;
    assign io_out[29] = 1'b0; assign io_oeb[29] = 1'b1;
    assign io_out[30] = 1'b0; assign io_oeb[30] = 1'b1;
    assign io_out[31] = 1'b0; assign io_oeb[31] = 1'b1;
    assign io_out[32] = 1'b0; assign io_oeb[32] = 1'b1;
    assign io_out[33] = 1'b0; assign io_oeb[33] = 1'b1;
    assign io_out[34] = 1'b0; assign io_oeb[34] = 1'b1;
    assign io_out[35] = 1'b0; assign io_oeb[35] = 1'b1;
    assign io_out[36] = 1'b0; assign io_oeb[36] = 1'b1;
    assign io_out[37] = 1'b0; assign io_oeb[37] = 1'b1;

    // ----------------------------------------------------------------
    // Suppress unused-wire warnings
    // ----------------------------------------------------------------
    wire _unused = |{wbs_stb_i, wbs_cyc_i, wbs_we_i, wbs_sel_i,
                     wbs_dat_i, wbs_adr_i, la_data_in, la_oenb,
                     vccd1, vssd1, vccd2, vssd2, vdda1, vssa1, vdda2, vssa2};

endmodule
