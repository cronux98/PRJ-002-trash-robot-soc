SIM = icarus
TOPLEVEL_LANG = verilog
VERILOG_SOURCES = ../../03_frontend-stage/rtl-motor_pwm/rtl/motor_pwm.v \
                  ../../03_frontend-stage/rtl-motor_pwm/rtl/motor_pwm_ctrl.v
TOPLEVEL = motor_pwm
COCOTB_TEST_MODULES = test_motor_pwm
COMPILE_ARGS = -g2005 -I../../03_frontend-stage/
include $(shell cocotb-config --makefiles)/Makefile.sim
