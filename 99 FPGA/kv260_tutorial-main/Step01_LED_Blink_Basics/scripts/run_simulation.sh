#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$PROJECT_ROOT/src"
SIM_DIR="$PROJECT_ROOT/sim"

XSIM_BIN="/tools/Xilinx/Vivado/2021.2/bin"

export PATH="$XSIM_BIN:$PATH"

echo "=========================================="
echo "Running Xilinx xsim Simulation"
echo "=========================================="

cd "$SIM_DIR"

echo "Compiling Verilog sources..."
xvlog -m64 --sv --lib xil_defaultlib "$SRC_DIR/led_blinker.v"
xvlog -m64 --sv --lib xil_defaultlib "$SRC_DIR/top_module.v"
xvlog -m64 --sv --lib xil_defaultlib "$SIM_DIR/tb_top_module.v"

echo "Creating snapshot..."
xelab -debug typical tb_top_module -s tb_top_module

if [ "$1" = "-gui" ]; then
    echo "Launching GUI..."
    xsim tb_top_module -gui
else
    echo "Running simulation..."
    xsim tb_top_module -runall
fi

echo "=========================================="
echo "Simulation Complete"
echo "=========================================="
