#!/bin/bash

# KV260 LED Blink Project - Modular Build Script
# Usage: ./build.sh [option]
# Options:
#   all         - Complete build (project + block design + synthesis + implementation)
#   project     - Create project and add source files only
#   block       - Create block design only (requires existing project)
#   synthesis   - Run synthesis only (requires block design)
#   impl        - Run implementation and generate bitstream (requires synthesis)
#   clean       - Clean output directory

set -e

# ============================================================================
# Configuration  
# ============================================================================
VIVADO_VERSION="2021.2"
VIVADO_PATH="/tools/Xilinx/Vivado/${VIVADO_VERSION}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/out"

SCRIPT_PROJECT="${SCRIPT_DIR}/scripts/create_project.tcl"
SCRIPT_BLOCK="${SCRIPT_DIR}/scripts/create_block_design.tcl"
SCRIPT_SYNTH="${SCRIPT_DIR}/scripts/run_synthesis.tcl"
SCRIPT_IMPL="${SCRIPT_DIR}/scripts/run_implementation.tcl"

# ============================================================================
# Functions
# ============================================================================

check_vivado() {
    if [ ! -f "${VIVADO_PATH}/settings64.sh" ]; then
        echo "ERROR: Vivado ${VIVADO_VERSION} not found at ${VIVADO_PATH}"
        echo "Please install Vivado ${VIVADO_VERSION} or update VIVADO_PATH in this script"
        exit 1
    fi
    
    echo "Loading Vivado ${VIVADO_VERSION} environment..."
    source "${VIVADO_PATH}/settings64.sh"
}

run_project() {
    echo "========================================="
    echo "Creating Vivado Project..."
    echo "========================================="
    mkdir -p "${OUTPUT_DIR}"
    vivado -mode batch -source "${SCRIPT_PROJECT}" -tclargs "${OUTPUT_DIR}"
}

run_block() {
    echo "========================================="
    echo "Creating Block Design..." 
    echo "========================================="
    vivado -mode batch -source "${SCRIPT_BLOCK}" -tclargs "${OUTPUT_DIR}"
}

run_synthesis() {
    echo "========================================="
    echo "Running Synthesis..."
    echo "========================================="
    vivado -mode batch -source "${SCRIPT_SYNTH}" -tclargs "${OUTPUT_DIR}"
}

run_implementation() {
    echo "========================================="
    echo "Running Implementation & Bitstream Generation..."
    echo "========================================="
    vivado -mode batch -source "${SCRIPT_IMPL}" -tclargs "${OUTPUT_DIR}"
}

clean_output() {
    echo "========================================="
    echo "Cleaning Output Directory..."
    echo "========================================="
    if [ -d "${OUTPUT_DIR}" ]; then
        rm -rf "${OUTPUT_DIR}"
        echo "Cleaned: ${OUTPUT_DIR}"
    else
        echo "Nothing to clean"
    fi
}

show_help() {
    echo "KV260 LED Blink Project - Modular Build Script"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  all         - Complete build (default)"
    echo "  project     - Create project and add source files only"
    echo "  block       - Create block design only"
    echo "  synthesis   - Run synthesis only"
    echo "  impl        - Run implementation and generate bitstream"
    echo "  clean       - Clean output directory"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Complete build"
    echo "  $0 synthesis    # Quick synthesis check"
    echo "  $0 clean        # Clean build artifacts"
}

check_results() {
    echo "========================================="
    echo "Build Results"
    echo "========================================="
    
    # Find generated bitstream
    BITSTREAM=$(find "${OUTPUT_DIR}" -name "*.bit" -type f 2>/dev/null | head -n 1)
    
    if [ -n "$BITSTREAM" ]; then
        echo "✅ SUCCESS: Bitstream generated"
        echo "   📁 $BITSTREAM"
        echo "   📏 Size: $(du -h "$BITSTREAM" | cut -f1)"
    else
        echo "⚠️  WARNING: Bitstream file not found"
    fi
    
    # Check project structure
    PROJECT_DIR="${OUTPUT_DIR}/kv260_led_blink"
    if [ -d "$PROJECT_DIR" ]; then
        echo "✅ Project directory: $PROJECT_DIR"
        
        # Check block design
        BD_FILE="$PROJECT_DIR/kv260_led_blink.srcs/sources_1/bd/design_1/design_1.bd"
        if [ -f "$BD_FILE" ]; then
            echo "✅ Block design: design_1.bd"
        fi
        
        # Check wrapper
        WRAPPER_FILE="$PROJECT_DIR/kv260_led_blink.gen/sources_1/bd/design_1/hdl/design_1_wrapper.v"
        if [ -f "$WRAPPER_FILE" ]; then
            echo "✅ BD wrapper: design_1_wrapper.v"
        fi
    fi
    
    echo "========================================="
}

# ============================================================================
# Main Script
# ============================================================================

# Parse command line argument
OPTION="${1:-all}"

case "$OPTION" in
    "help"|"-h"|"--help")
        show_help
        exit 0
        ;;
    "clean")
        clean_output
        exit 0
        ;;
    "all")
        check_vivado
        run_project
        run_block
        run_synthesis
        run_implementation
        check_results
        ;;
    "project")
        check_vivado
        run_project
        ;;
    "block")
        check_vivado
        run_block
        ;;
    "synthesis")
        check_vivado
        run_synthesis
        ;;
    "impl")
        check_vivado
        run_implementation
        check_results
        ;;
    *)
        echo "ERROR: Unknown option '$OPTION'"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac

echo "✅ Build script completed: $OPTION"