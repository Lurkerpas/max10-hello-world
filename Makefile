# maXimator (MAX 10 10M08DAF256C8G) LED chaser + "HELLO WORLD" 7-segment scroller
#
#   make verify   - simulate rtl/ with the self-checking testbench (GHDL)
#   make compile  - synthesis, fit, assemble (.sof) and timing analysis (Quartus)
#   make program  - download the .sof to the FPGA through USB-Blaster (volatile)
#   make flash    - write the .pof to the on-chip flash (persistent, overwrites
#                   the board's existing flash contents)
#
# Dependency chain: verify -> map -> fit -> asm (.sof/.pof) -> program | flash
#
# Overridable: CABLE, GHDL

PROJECT      ?= hello_world
TB_TOPS      ?= blink_tb scroller_tb
CABLE        ?= USB-Blaster
GHDL         ?= ghdl
GHDL_FLAGS   ?= --std=08

RTL_SRC      := rtl/blink.vhd rtl/scroller.vhd rtl/hello_world.vhd
TB_SRC       := tb/blink_tb.vhd tb/scroller_tb.vhd
Q_CONFIG     := $(PROJECT).qpf $(PROJECT).qsf $(PROJECT).sdc

OUT_DIR      := output_files
SIM_DIR      := build/sim
VERIFY_STAMP := build/verify.ok
MAP_RPT      := $(OUT_DIR)/$(PROJECT).map.rpt
FIT_RPT      := $(OUT_DIR)/$(PROJECT).fit.rpt
SOF          := $(OUT_DIR)/$(PROJECT).sof
POF          := $(OUT_DIR)/$(PROJECT).pof
STA_RPT      := $(OUT_DIR)/$(PROJECT).sta.rpt

QMAP := $(QUARTUS_BIN)/quartus_map
QFIT := $(QUARTUS_BIN)/quartus_fit
QASM := $(QUARTUS_BIN)/quartus_asm
QSTA := $(QUARTUS_BIN)/quartus_sta
QPGM := $(QUARTUS_BIN)/quartus_pgm

.PHONY: all verify map fit asm sta compile program flash clean help
.DELETE_ON_ERROR:

all: compile

help:
	@echo "make verify   - run the GHDL testbench"
	@echo "make compile  - Quartus map + fit + asm + sta (runs verify first if needed)"
	@echo "make program  - program $(SOF) via $(CABLE) (volatile, builds it first if needed)"
	@echo "make flash    - write $(POF) to the on-chip flash (persistent, builds it first if needed)"
	@echo "make clean    - remove generated files"
	@echo "Individual compile steps: map, fit, asm, sta"

# ---- verify ----------------------------------------------------------------
verify: $(VERIFY_STAMP)

$(VERIFY_STAMP): $(RTL_SRC) $(TB_SRC)
	@mkdir -p $(SIM_DIR)
	$(GHDL) -a $(GHDL_FLAGS) --workdir=$(SIM_DIR) $(RTL_SRC) $(TB_SRC)
	@set -e; for tb in $(TB_TOPS); do \
	  echo "== $$tb"; \
	  $(GHDL) -e $(GHDL_FLAGS) --workdir=$(SIM_DIR) $$tb; \
	  $(GHDL) -r $(GHDL_FLAGS) --workdir=$(SIM_DIR) $$tb --assert-level=error; \
	done
	@touch $@

# ---- compile ---------------------------------------------------------------
map: $(MAP_RPT)
fit: $(FIT_RPT)
asm: $(SOF)
sta: $(STA_RPT)
compile: $(SOF) $(STA_RPT)

$(MAP_RPT): $(RTL_SRC) $(Q_CONFIG) $(VERIFY_STAMP)
	$(QMAP) $(PROJECT)

$(FIT_RPT): $(MAP_RPT)
	$(QFIT) $(PROJECT)

$(SOF): $(FIT_RPT)
	$(QASM) $(PROJECT)

$(STA_RPT): $(FIT_RPT)
	$(QSTA) $(PROJECT)

# ---- program ---------------------------------------------------------------
program: $(SOF)
	$(QPGM) -c "$(CABLE)" -m jtag -o "p;$(SOF)@1"

# quartus_asm writes the .pof together with the .sof
$(POF): $(SOF)
	@test -f $@ || { echo "$@ was not generated; run 'make clean' and rebuild"; exit 1; }

# Writes the internal flash so the design loads at every power-up.
# MAX 10 flash is written in real-time ISP mode, which requires the device to
# be in user mode, so the .sof is loaded first.
flash: $(POF)
	$(QPGM) -c "$(CABLE)" -m jtag -o "p;$(SOF)@1"
	$(QPGM) --bgp -c "$(CABLE)" -m jtag -o "pv;$(POF)@1"

# ---- housekeeping ----------------------------------------------------------
clean:
	rm -rf build db incremental_db output_files qdb tmp-clearbox *.rpt *.summary *.qws *.jdi
