###############################################################################
# run_all.tcl - 전체 빌드 스크립트
# Vivado 2025.2 대응
#
# 사용법:
#   vivado -mode batch -source run_all.tcl
###############################################################################

puts "=========================================="
puts "KV260 AXI GPIO - Full Build"
puts "=========================================="

# 스크립트 위치 감지
set script_dir [file dirname [file normalize [info script]]]
set project_root [file dirname $script_dir]

# Step 1: 프로젝트 생성
puts {Step 1/4: Creating project...}
source $script_dir/create_project.tcl

# Step 2: 블록 디자인 생성
puts {Step 2/4: Creating Block Design...}
source $script_dir/create_block_design.tcl

# Step 3: 합성
puts {Step 3/4: Running Synthesis...}
source $script_dir/run_synthesis.tcl

# Step 4: 구현 및 비트스트림
puts {Step 4/4: Running Implementation & Bitstream...}
source $script_dir/run_implementation.tcl

puts ""
puts "=========================================="
puts "ALL BUILDS COMPLETED!"
puts "=========================================="