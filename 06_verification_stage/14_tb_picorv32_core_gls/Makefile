SIM = icarus
TOPLEVEL_LANG = verilog

VERILOG_SOURCES = ~/.ciel/ciel/sky130/versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/sky130B/libs.ref/sky130_fd_sc_hd/verilog/primitives.v \
                  ~/.ciel/ciel/sky130/versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/sky130B/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v \
                  $(shell pwd)/../../03_frontend-stage/rtl-picorv32_core/synth/picorv32_core_netlist.v
TOPLEVEL = picorv32
COCOTB_TEST_MODULES = test_picorv32_core

COMPILE_ARGS = -g2005 -DGLS

include $(shell cocotb-config --makefiles)/Makefile.sim
