###############################################################################
# run_all.tcl - 전체 빌드 스크립트
# Vivado 2021.2 대응
#
# 사용법:
#   vivado -mode batch -source run_all.tcl
#   vivado -mode batch -source run_all.tcl -tclargs --rtl          # RTL 클럭 사용 (기본)
#   vivado -mode batch -source run_all.tcl -tclargs --ip          # Xilinx IP 사용
#   vivado -mode batch -source run_all.tcl -tclargs --rtl --ip    # 둘 다 사용
###############################################################################

#命令行 인자 파싱
set use_rtl 1
set use_ip 0

foreach arg $argv {
    if {$arg eq "--rtl"} { set use_rtl 1 }
    if {$arg eq "--ip"}  { set use_ip 1 }
}

# 옵션을 환경 변수로 설정 (create_block_design.tcl에서 사용)
set env(USE_RTL_CLOCK) $use_rtl
set env(USE_IP_CLOCK) $use_ip

puts "=========================================="
puts "KV260 IP Integrator - Full Build"
puts "=========================================="
puts "Options:"
puts "  USE_RTL_CLOCK: $use_rtl"
puts "  USE_IP_CLOCK:  $use_ip"
puts "=========================================="

# 스크립트 위치 감지
set script_dir [file dirname [file normalize [info script]]]
set project_root [file dirname $script_dir]

# Step 1: 프로젝트 생성
puts {[Step 1/4] Creating project...}
source $script_dir/create_project.tcl

# Step 2: 블록 디자인 생성
puts {[Step 2/4] Creating Block Design...}
source $script_dir/create_block_design.tcl

# Step 3: 합성
puts {[Step 3/4] Running Synthesis...}
source $script_dir/run_synthesis.tcl

# Step 4: 구현 및 비트스트림
puts {[Step 4/4] Running Implementation & Bitstream...}
source $script_dir/run_implementation.tcl

puts ""
puts "=========================================="
puts "ALL BUILDS COMPLETED!"
puts "=========================================="