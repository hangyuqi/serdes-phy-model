# ==========================================
# PCIe PHY DV Makefile for VCS & Verdi
# ==========================================

# 默认变量
TESTNAME ?= test_random_payload
SEED     ?= $(shell date +%s)
FSDB     ?= tb.fsdb

# 路径定义
SRC_DIR  = ./src
TB_DIR   = ./tb
INCDIR   = +incdir+$(SRC_DIR)+$(TB_DIR)

# VCS 编译选项
VCS_OPTS = -sverilog -full64 -timescale=1ns/1ps \
           -debug_access+all -kdb -lca \
           $(INCDIR)

# SIM 运行选项
SIM_OPTS = +TESTNAME=$(TESTNAME) +ntb_random_seed=$(SEED)

# 源文件列表 (注意Class编译顺序，被继承和被调用的基础类需放在前面)
SV_FILES = $(TB_DIR)/phy_if.sv \
           $(TB_DIR)/phy_trans.sv \
           $(TB_DIR)/pcie_ts_pkt.sv \
           $(TB_DIR)/phy_checker.sv \
           $(TB_DIR)/base_test.sv \
           $(TB_DIR)/test_random_payload.sv \
           $(TB_DIR)/test_ts_loopback.sv \
           $(TB_DIR)/tb_top.sv \
           $(SRC_DIR)/pcie_phy_dut.v

.PHONY: clean comp sim run verdi

run: comp sim

comp:
	vcs $(VCS_OPTS) $(SV_FILES) | tee comp.log

sim:
	./simv $(SIM_OPTS) -l sim_$(TESTNAME).log

verdi:
	verdi -ssf $(FSDB) -nologo &

clean:
	rm -rf csrc simv* *.log *.vpd *.fsdb *.key novas* verdi* DVEfiles