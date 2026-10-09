# ==============================================================================
# Makefile for AMBA 3 APB SystemVerilog Architecture and Testbench
# ==============================================================================

# Simulator selector: questa (default, works with Questa/ModelSim), vcs, xcelium
SIM ?= questa

# Windows shell configuration for GNU Make
ifeq ($(OS),Windows_NT)
    SHELL := cmd.exe
    .SHELLFLAGS := /c
endif

# Auto-detect source directory whether run from root or inside APB_SV/
ifeq ($(wildcard tb_top.sv),tb_top.sv)
    SRC_DIR ?= .
else
    SRC_DIR ?= APB_SV
endif

TOP_TB    ?= tb_top
TOP_FILE  ?= $(SRC_DIR)/tb_top.sv
INCDIR    ?= $(SRC_DIR)
WORK_LIB  ?= work

# Simulator Flags
VLOG_FLAGS ?= -sv -work $(WORK_LIB) +incdir+$(INCDIR)
VSIM_FLAGS ?= -voptargs="+acc" -lib $(WORK_LIB)
VSIM_BATCH ?= -c -do "run -all; quit -f"
VSIM_GUI   ?= -gui -do "add wave -position insertpoint sim:/$(TOP_TB)/intf/*; run -all"
VSIM_COV   ?= -c -coverage -do "coverage save -onexit cov.ucdb; run -all; quit -f"

VCS_FLAGS  ?= -sverilog -full64 +incdir+$(INCDIR) -top $(TOP_TB) -debug_access+all
XRUN_FLAGS ?= -sv -64bit +incdir+$(INCDIR) -top $(TOP_TB) -access +rwc

.PHONY: all help compile sim run gui cov clean

# Default: compile and run batch simulation
all: compile sim

# Display target list and usage instructions
help:
	@echo ==============================================================================
	@echo                     AMBA APB SV Testbench Makefile
	@echo ==============================================================================
	@echo   make compile    : Compile DUT and SystemVerilog testbench
	@echo   make sim        : Run batch simulation in command-line mode
	@echo   make run        : Alias for make sim
	@echo   make gui        : Open QuestaSim/ModelSim GUI with waveforms
	@echo   make cov        : Run simulation with code and functional coverage
	@echo   make all        : Compile and run batch simulation (default)
	@echo   make clean      : Remove all simulation artifacts, databases, and logs
	@echo   make help       : Show this help message
	@echo.
	@echo   Options:
	@echo     SIM=questa    : Use QuestaSim / ModelSim (default)
	@echo     SIM=vcs       : Use Synopsys VCS
	@echo     SIM=xcelium   : Use Cadence Xcelium
	@echo ==============================================================================

# Compilation target
compile:
ifeq ($(SIM),vcs)
	vcs $(VCS_FLAGS) $(TOP_FILE) -l compile.log
else ifeq ($(SIM),xcelium)
	xrun -compile $(XRUN_FLAGS) $(TOP_FILE)
else
	vlib $(WORK_LIB)
	vlog $(VLOG_FLAGS) $(TOP_FILE)
endif

# Simulation target (batch mode)
sim:
ifeq ($(SIM),vcs)
	./simv -l sim.log
else ifeq ($(SIM),xcelium)
	xrun $(XRUN_FLAGS) $(TOP_FILE) -l sim.log
else
	vsim $(VSIM_FLAGS) $(VSIM_BATCH) $(TOP_TB)
endif

run: sim

# Simulation in GUI mode with waveforms
gui:
ifeq ($(SIM),vcs)
	./simv -gui
else ifeq ($(SIM),xcelium)
	xrun $(XRUN_FLAGS) $(TOP_FILE) -gui
else
	vsim $(VSIM_FLAGS) $(VSIM_GUI) $(TOP_TB)
endif

# Coverage target
cov:
ifeq ($(SIM),questa)
	vlib $(WORK_LIB)
	vlog -cover bcesfx $(VLOG_FLAGS) $(TOP_FILE)
	vsim $(VSIM_FLAGS) $(VSIM_COV) $(TOP_TB)
else
	@echo Coverage target currently configured for QuestaSim
endif

# Clean simulation artifacts
clean:
ifeq ($(OS),Windows_NT)
	@if exist $(WORK_LIB) rmdir /s /q $(WORK_LIB)
	@if exist covhtmlreport rmdir /s /q covhtmlreport
	@if exist simv.daidir rmdir /s /q simv.daidir
	@if exist xcelium.d rmdir /s /q xcelium.d
	@if exist transcript del /f /q transcript
	@if exist vsim.wlf del /f /q vsim.wlf
	@if exist vsim.dbg del /f /q vsim.dbg
	@if exist log.txt del /f /q log.txt
	@if exist cov.ucdb del /f /q cov.ucdb
	@if exist simv del /f /q simv
	@if exist ucli.key del /f /q ucli.key
	@if exist vc_hdrs.h del /f /q vc_hdrs.h
	@if exist xrun.history del /f /q xrun.history
	@if exist xrun.log del /f /q xrun.log
	@if exist *.log del /f /q *.log
else
	@rm -rf $(WORK_LIB) transcript vsim.wlf vsim.dbg log.txt *.log *.vstf *.cov cov.ucdb covhtmlreport simv simv.daidir ucli.key vc_hdrs.h xcelium.d xrun.history xrun.log
endif
	@echo Clean completed.

