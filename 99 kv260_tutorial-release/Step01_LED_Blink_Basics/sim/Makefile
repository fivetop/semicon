# ==============================================================================
# KV260 LED Blink Simulation Makefile
# Supports Xilinx Vivado Simulator with VCD generation
# ==============================================================================

# Vivado settings
VIVADO_VERSION = 2021.2
VIVADO_PATH = /tools/Xilinx/Vivado/$(VIVADO_VERSION)
VIVADO_ENV = $(VIVADO_PATH)/settings64.sh

# Project paths
PROJECT_ROOT = ..
SRC_DIR = $(PROJECT_ROOT)/src
SIM_DIR = .
WAVE_DIR = $(SIM_DIR)/waveforms
OUTPUT_DIR = $(SIM_DIR)/output

# Source files
RTL_SOURCES = $(SRC_DIR)/led_blink.v
TB_COMPREHENSIVE = $(SIM_DIR)/tb_led_blink_comprehensive.v
TB_FAST = $(SIM_DIR)/tb_led_blink_fast.v
TB_BASIC = $(SIM_DIR)/tb_led_blink.v

# Simulation targets
COMPREHENSIVE_TARGET = tb_led_blink_comprehensive
FAST_TARGET = tb_led_blink_fast  
BASIC_TARGET = tb_led_blink

# Compiler and simulator
XVLOG = xvlog
XELAB = xelab
XSIM = xsim

# Compilation flags
XVLOG_FLAGS = -work work
XELAB_FLAGS = -debug typical -relax
XSIM_FLAGS = -runall

# VCD generation flags
VCD_FLAGS = -testplusarg VCD=enabled

# ==============================================================================
# Main targets
# ==============================================================================

.PHONY: all comprehensive fast basic clean setup help view_waves

# Default target
all: comprehensive

# Comprehensive test with VCD generation
comprehensive: setup
	@echo "=== Running Comprehensive Simulation with VCD ==="
	@/bin/bash -c "source $(VIVADO_ENV) && \
	$(XVLOG) $(XVLOG_FLAGS) $(RTL_SOURCES) $(TB_COMPREHENSIVE) && \
	$(XELAB) $(XELAB_FLAGS) $(COMPREHENSIVE_TARGET) -s $(COMPREHENSIVE_TARGET) && \
	$(XSIM) $(COMPREHENSIVE_TARGET) $(XSIM_FLAGS) $(VCD_FLAGS)"

# Fast simulation for quick testing
fast: setup
	@echo "=== Running Fast Simulation ==="
	@/bin/bash -c "source $(VIVADO_ENV) && \
	$(XVLOG) $(XVLOG_FLAGS) $(RTL_SOURCES) $(TB_FAST) && \
	$(XELAB) $(XELAB_FLAGS) $(FAST_TARGET) -s $(FAST_TARGET) && \
	$(XSIM) $(FAST_TARGET) $(XSIM_FLAGS)"

# Basic simulation (original testbench)
basic: setup  
	@echo "=== Running Basic Simulation ==="
	@source $(VIVADO_ENV) && \
	$(XVLOG) $(XVLOG_FLAGS) $(RTL_SOURCES) $(TB_BASIC) && \
	$(XELAB) $(XELAB_FLAGS) $(BASIC_TARGET) -s $(BASIC_TARGET) && \
	$(XSIM) $(BASIC_TARGET) $(XSIM_FLAGS)

# ==============================================================================
# Individual test targets
# ==============================================================================

# Compile only (syntax check)
compile: setup
	@echo "=== Compiling RTL and Testbenches ==="
	@source $(VIVADO_ENV) && \
	$(XVLOG) $(XVLOG_FLAGS) $(RTL_SOURCES) $(TB_COMPREHENSIVE) $(TB_FAST) $(TB_BASIC)

# Elaborate only
elaborate: compile
	@echo "=== Elaborating Designs ==="
	@source $(VIVADO_ENV) && \
	$(XELAB) $(XELAB_FLAGS) $(COMPREHENSIVE_TARGET) -s $(COMPREHENSIVE_TARGET) && \
	$(XELAB) $(XELAB_FLAGS) $(FAST_TARGET) -s $(FAST_TARGET) && \
	$(XELAB) $(XELAB_FLAGS) $(BASIC_TARGET) -s $(BASIC_TARGET)

# Run simulation with custom parameters
custom: setup
	@echo "=== Running Custom Simulation ==="
	@source $(VIVADO_ENV) && \
	$(XVLOG) $(XVLOG_FLAGS) $(RTL_SOURCES) $(TB_COMPREHENSIVE) && \
	$(XELAB) $(XELAB_FLAGS) $(COMPREHENSIVE_TARGET) -s $(COMPREHENSIVE_TARGET) && \
	$(XSIM) $(COMPREHENSIVE_TARGET) $(CUSTOM_FLAGS)

# ==============================================================================
# Waveform analysis
# ==============================================================================

# View waveforms with GTKWave (if available)
view_waves: 
	@if command -v gtkwave >/dev/null 2>&1; then \
		echo "=== Opening waveforms with GTKWave ==="; \
		gtkwave $(WAVE_DIR)/led_blink_tb.vcd & \
	else \
		echo "GTKWave not found. Install with:"; \
		echo "  Ubuntu/Debian: sudo apt install gtkwave"; \
		echo "  CentOS/RHEL: sudo yum install gtkwave"; \
		echo ""; \
		echo "VCD file location: $(WAVE_DIR)/led_blink_tb.vcd"; \
	fi

# Generate waveforms without running full simulation (quick)
waves_only: setup
	@echo "=== Generating VCD file (minimal simulation) ==="
	@source $(VIVADO_ENV) && \
	$(XVLOG) $(XVLOG_FLAGS) $(RTL_SOURCES) $(TB_FAST) && \
	$(XELAB) $(XELAB_FLAGS) $(FAST_TARGET) -s $(FAST_TARGET) && \
	$(XSIM) $(FAST_TARGET) $(XSIM_FLAGS) $(VCD_FLAGS)

# ==============================================================================
# Utility targets  
# ==============================================================================

# Setup directories
setup:
	@mkdir -p $(WAVE_DIR) $(OUTPUT_DIR)
	@echo "Created output directories:"
	@echo "  Waveforms: $(WAVE_DIR)"
	@echo "  Simulation outputs: $(OUTPUT_DIR)"

# Clean all generated files
clean:
	@echo "=== Cleaning simulation files ==="
	rm -rf xsim.dir/
	rm -rf xvlog.log xvlog.pb xelab.log xelab.pb xsim.log
	rm -rf webtalk.log webtalk.jou webtalk_*.backup.log
	rm -rf $(WAVE_DIR)/*.vcd
	rm -rf $(OUTPUT_DIR)/*
	rm -rf .Xil/
	@echo "Cleaned all simulation artifacts"

# Check environment
env_check:
	@echo "=== Environment Check ==="
	@if [ -f "$(VIVADO_ENV)" ]; then \
		echo "✓ Vivado $(VIVADO_VERSION) found at $(VIVADO_PATH)"; \
	else \
		echo "✗ Vivado $(VIVADO_VERSION) not found!"; \
		echo "  Expected: $(VIVADO_PATH)"; \
		echo "  Update VIVADO_PATH in Makefile if needed"; \
		exit 1; \
	fi
	@source $(VIVADO_ENV) && which xvlog >/dev/null 2>&1 && echo "✓ Xilinx tools in PATH"

# Show simulation statistics
stats:
	@echo "=== Project Statistics ==="
	@echo "RTL files: $(shell find $(SRC_DIR) -name "*.v" | wc -l)"
	@echo "Testbench files: $(shell find $(SIM_DIR) -name "tb_*.v" | wc -l)"
	@if [ -f "$(WAVE_DIR)/led_blink_tb.vcd" ]; then \
		echo "VCD file size: $(shell du -h $(WAVE_DIR)/led_blink_tb.vcd | cut -f1)"; \
	fi

# Help target
help:
	@echo "KV260 LED Blink Simulation Makefile"
	@echo "===================================="
	@echo ""
	@echo "Main targets:"
	@echo "  all           - Run comprehensive simulation (default)"
	@echo "  comprehensive - Full simulation with VCD generation"
	@echo "  fast          - Quick simulation for development"
	@echo "  basic         - Original testbench simulation"
	@echo ""
	@echo "Development targets:"
	@echo "  compile       - Syntax check only"
	@echo "  elaborate     - Compile + elaborate"
	@echo "  custom        - Custom simulation (set CUSTOM_FLAGS)"
	@echo ""
	@echo "Waveform targets:"
	@echo "  view_waves    - Open VCD file in GTKWave"
	@echo "  waves_only    - Generate VCD without full test"
	@echo ""
	@echo "Utility targets:"
	@echo "  setup         - Create output directories"
	@echo "  clean         - Remove all generated files"
	@echo "  env_check     - Verify Vivado environment"
	@echo "  stats         - Show project statistics"
	@echo "  help          - Show this help"
	@echo ""
	@echo "Examples:"
	@echo "  make comprehensive     # Full test with waveforms"
	@echo "  make fast             # Quick development test"
	@echo "  make view_waves       # View generated waveforms"
	@echo "  make clean all        # Clean build"

# ==============================================================================
# Advanced targets
# ==============================================================================

# Regression test (all testbenches)
regression: comprehensive fast basic
	@echo "=== Regression Test Complete ==="

# Parallel simulation (if supported)
parallel: setup
	@echo "=== Running Parallel Simulations ==="
	@(make fast &); \
	(make basic &); \
	wait; \
	make comprehensive

# Performance test with timing measurement  
perf: setup
	@echo "=== Performance Test ==="
	@start_time=$$(date +%s); \
	make comprehensive; \
	end_time=$$(date +%s); \
	echo "Simulation completed in $$((end_time - start_time)) seconds"

# ==============================================================================
# Variable overrides for advanced usage
# ==============================================================================

# Override counter max for different test scenarios
# Example: make comprehensive COUNTER_MAX=1000000
ifdef COUNTER_MAX
XVLOG_FLAGS += -define COUNTER_MAX=$(COUNTER_MAX)
endif

# Enable debug mode
ifdef DEBUG
XELAB_FLAGS += -debug all
XSIM_FLAGS += -gui
endif

# Custom VCD file name
ifdef VCD_NAME
VCD_FLAGS = +VCD=$(VCD_NAME)
endif