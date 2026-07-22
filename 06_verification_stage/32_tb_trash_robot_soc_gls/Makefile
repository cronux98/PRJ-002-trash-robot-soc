SIM = icarus
TOPLEVEL_LANG = verilog

VERILOG_SOURCES = /home/smdadmin/.ciel/ciel/sky130/versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/sky130B/libs.ref/sky130_fd_sc_hd/verilog/primitives.v \
                  /home/smdadmin/.ciel/ciel/sky130/versions/8afc8346a57fe1ab7934ba5a6056ea8b43078e71/sky130B/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v \
                  $(shell pwd)/../../03_frontend-stage/rtl-trash_robot_soc/synth/trash_robot_soc_netlist.v

TOPLEVEL = trash_robot_soc
COCOTB_TEST_MODULES = test_trash_robot_soc

COMPILE_ARGS = -g2005 -DGLS

include $(shell cocotb-config --makefiles)/Makefile.sim
