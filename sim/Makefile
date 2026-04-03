PROJECT_ROOT := $(abspath ..)
RTL_DIR      := $(PROJECT_ROOT)/rtl
SIM_DIR      := $(PROJECT_ROOT)/sim
TC_DIR       := $(SIM_DIR)/tc
OUT_DIR      := $(SIM_DIR)/out
DISPATCH     := $(TC_DIR)/tc_dispatch.svh

TC ?= smoke_test
TC_OUT := $(OUT_DIR)/$(TC)

# ----------------------------------------------------------------
# VCS compile flags
# ----------------------------------------------------------------
VCS_FLAGS := -sverilog \
             -f $(SIM_DIR)/filelist.f \
             -timescale=1ns/1ps \
             -debug_access+all \
             -full64 \
             -kdb \
             +v2k \
             -o $(TC_OUT)/simv \
             -l $(TC_OUT)/compile.log

# ----------------------------------------------------------------
# Targets
# ----------------------------------------------------------------
.PHONY: comp run clean help gen_dispatch verdi

help:
	@echo "Usage:"
	@echo "  make comp              — Compile design with VCS"
	@echo "  make run TC=<name>     — Compile + run testcase (default: smoke_test)"
	@echo "  make clean             — Remove all generated files"
	@echo ""
	@echo "Example:"
	@echo "  make run TC=smoke_test"

gen_dispatch:
	@{ \
	echo '// Auto-generated from tc/*.sv — do not edit'; \
	for f in $(TC_DIR)/*.sv; do \
		n=$$(basename "$$f" .sv); \
		printf '`include "%s.sv"\n' "$$n"; \
	done; \
	echo ''; \
	echo 'task run_testcase(string name);'; \
	echo '    case (name)'; \
	for f in $(TC_DIR)/*.sv; do \
		n=$$(basename "$$f" .sv); \
		printf '        "%s": %s();\n' "$$n" "$$n"; \
	done; \
	echo '        default: begin'; \
	echo '            $$display("[ERROR] Unknown testcase: %s", name);'; \
	echo '            err_count++;'; \
	echo '        end'; \
	echo '    endcase'; \
	echo 'endtask'; \
	} > $(DISPATCH)
	@echo "[gen_dispatch] $(DISPATCH) updated"

comp: gen_dispatch
	@mkdir -p $(TC_OUT)
	cd $(SIM_DIR) && vcs $(VCS_FLAGS)

run: comp
	cd $(TC_OUT) && ./simv +tc=$(TC) -l $(TC).log
	@echo '#!/bin/bash' > $(TC_OUT)/open_wave.sh
	@echo 'DIR=$$(cd "$$(dirname "$$0")" && pwd)' >> $(TC_OUT)/open_wave.sh
	@echo 'verdi -dbdir "$$DIR/simv.daidir" -ssf "$$DIR/$(TC).fsdb" &' >> $(TC_OUT)/open_wave.sh
	@chmod +x $(TC_OUT)/open_wave.sh

verdi:
	cd $(TC_OUT) && verdi -dbdir $(TC_OUT)/simv.daidir -ssf $(TC_OUT)/$(TC).fsdb &

clean:
	rm -rf $(OUT_DIR)
	rm -rf $(DISPATCH)
