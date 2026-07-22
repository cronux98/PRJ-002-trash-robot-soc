SIM = icarus
TOPLEVEL_LANG = verilog
VERILOG_SOURCES = ../../03_frontend-stage/rtl-interrupt_ctrl/rtl/interrupt_ctrl.v \
                  ../../03_frontend-stage/rtl-interrupt_ctrl/rtl/intc.v
TOPLEVEL = interrupt_ctrl
COCOTB_TEST_MODULES = test_interrupt_ctrl
COMPILE_ARGS = -g2005 -I../../03_frontend-stage/
include $(shell cocotb-config --makefiles)/Makefile.sim
