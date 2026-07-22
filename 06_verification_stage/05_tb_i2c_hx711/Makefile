SIM = icarus
TOPLEVEL_LANG = verilog
VERILOG_SOURCES = ../../03_frontend-stage/rtl-i2c_hx711/rtl/i2c_master.v \
                  ../../03_frontend-stage/rtl-i2c_hx711/rtl/i2c_controller.v
TOPLEVEL = i2c_master
COCOTB_TEST_MODULES = test_i2c_hx711
COMPILE_ARGS = -g2005 -I../../03_frontend-stage/
include $(shell cocotb-config --makefiles)/Makefile.sim
