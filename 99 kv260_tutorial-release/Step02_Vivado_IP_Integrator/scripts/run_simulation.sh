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

echo "Compiling Verilog/SystemVerilog sources..."
xvlog -m64 --sv --lib xil_defaultlib "$SRC_DIR/clock_generator.v"
xvlog -m64 --sv --lib xil_defaultlib "$SRC_DIR/reset_controller.v"
xvlog -m64 --sv --lib xil_defaultlib "$SRC_DIR/platform_wrapper.v"

echo "Compiling testbenches..."
xvlog -m64 --sv --lib xil_defaultlib "$SIM_DIR/tb_platform_wrapper.sv"

echo "Compiling complete!"

xelab -debug typical tb_platform_wrapper -s tb_platform_wrapper

if [ "$1" = "-gui" ]; then
    echo "Launching GUI..."
    xsim tb_platform_wrapper -gui
else
    echo "Running simulation..."
    xsim tb_platform_wrapper -runall
fi

echo "=========================================="
echo "Simulation Complete"
echo "=========================================="
