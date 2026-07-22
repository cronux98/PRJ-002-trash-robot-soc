SIM = icarus
TOPLEVEL_LANG = verilog
VERILOG_SOURCES = ../../03_frontend-stage/rtl-ultrasonic_capture/rtl/ultrasonic_capture.v \
                  ../../03_frontend-stage/rtl-ultrasonic_capture/rtl/ultrasonic_fsm.v
TOPLEVEL = ultrasonic_capture
COCOTB_TEST_MODULES = test_ultrasonic_capture
COMPILE_ARGS = -g2005 -I../../03_frontend-stage/
include $(shell cocotb-config --makefiles)/Makefile.sim
