SIM = icarus
TOPLEVEL_LANG = verilog

VERILOG_SOURCES = ../../03_frontend-stage/rtl-trash_robot_soc/rtl/trash_robot_soc.v \
                  ../../03_frontend-stage/rtl-picorv32_core/rtl/picorv32_core.v \
                  ../../03_frontend-stage/rtl-wb_interconnect/rtl/wb_interconnect.v \
                  ../../03_frontend-stage/rtl-sram_512b/rtl/sram_512b.v \
                  ../../03_frontend-stage/rtl-uart/rtl/uart.v \
                  ../../03_frontend-stage/rtl-i2c_hx711/rtl/i2c_master.v \
                  ../../03_frontend-stage/rtl-i2c_hx711/rtl/i2c_controller.v \
                  ../../03_frontend-stage/rtl-motor_pwm/rtl/motor_pwm.v \
                  ../../03_frontend-stage/rtl-motor_pwm/rtl/motor_pwm_ctrl.v \
                  ../../03_frontend-stage/rtl-ultrasonic_capture/rtl/ultrasonic_capture.v \
                  ../../03_frontend-stage/rtl-ultrasonic_capture/rtl/ultrasonic_fsm.v \
                  ../../03_frontend-stage/rtl-gpio/rtl/gpio.v \
                  ../../03_frontend-stage/rtl-timer/rtl/timer.v \
                  ../../03_frontend-stage/rtl-watchdog/rtl/watchdog.v \
                  ../../03_frontend-stage/rtl-interrupt_ctrl/rtl/interrupt_ctrl.v \
                  ../../03_frontend-stage/rtl-interrupt_ctrl/rtl/intc.v \
                  ../../03_frontend-stage/rtl-weight_detect/rtl/weight_detect.v \
                  ../../03_frontend-stage/rtl-power_mgr/rtl/power_mgr.v

TOPLEVEL = trash_robot_soc
COCOTB_TEST_MODULES = test_trash_robot_soc

COMPILE_ARGS = -g2005

include $(shell cocotb-config --makefiles)/Makefile.sim
