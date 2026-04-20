# ==========================================
# PCIe PHY DV Makefile - 终极隔离版 (Build & Run)
# ==========================================

# 基础变量
TESTNAME   ?= test_random_payload
SEED       ?= $(shell date +%s)

# 目录定义
BUILD_DIR   = ./build
RUN_ROOT    = ./run
CUR_RUN_DIR = $(RUN_ROOT)/$(TESTNAME)

# VCS 编译选项
# 注意：移除了 -l comp.log，改为在编译命令中动态指定路径
VCS_OPTS = -sverilog -full64 -timescale=1ns/1ps \
           -debug_access+all -kdb -lca \
           -f rtl.f \
           -f tb.f

# 仿真选项
# 因为我们等下会直接进入 run/tc_name 目录去执行仿真，
# 所以 OUT_DIR 直接设为当前目录 (.) 即可
SIM_OPTS = +TESTNAME=$(TESTNAME) \
           +ntb_random_seed=$(SEED) \
           +OUT_DIR=.

.PHONY: clean comp sim run verdi prepare

# 一键执行目标
run: prepare comp sim

# 1. 准备目录结构
prepare:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(CUR_RUN_DIR)
	@echo "Directories prepared: $(BUILD_DIR) & $(CUR_RUN_DIR)"

# 2. 编译阶段 (锁定在 build 目录)
# -o:     指定可执行文件(simv)生成在 build/ 下
# -Mdir:  指定 csrc 缓存文件夹生成在 build/ 下
# -l:     指定编译日志生成在 build/ 下
comp: prepare
	vcs $(VCS_OPTS) -o $(BUILD_DIR)/simv -Mdir=$(BUILD_DIR)/csrc -l $(BUILD_DIR)/comp.log

# 3. 仿真阶段 (隔离在具体的 run 目录)
# 核心技巧：cd 到运行目录下执行 simv。这样所有仿真产生的垃圾文件（如 ucli.key）
# 都会被“关”在这个特定的用例文件夹里，绝不会污染根目录。
sim: prepare
	cd $(CUR_RUN_DIR) && ../../$(BUILD_DIR)/simv $(SIM_OPTS) -l sim.log
	@echo "Simulation Log: $(CUR_RUN_DIR)/sim.log"

# 4. 唤起 Verdi (同样隔离在 run 目录)
# 这样 Verdi 产生的 verdiLog 和 novas.rc 也会被关在用例文件夹里
verdi:
	cd $(CUR_RUN_DIR) && verdi -ssf tb.fsdb -nologo &

# 5. 一键清理
clean:
	@rm -rf $(BUILD_DIR) $(RUN_ROOT)
	@rm -rf csrc simv* *.key novas* verdi* DVEfiles *.log
	@echo "Cleaned all generated directories and files."