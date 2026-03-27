###############################################################################
# create_block_design.tcl - KV260 LED Blink 블록 디자인 생성 스크립트
# Vivado 2021.2対応
###############################################################################

set project_name "kv260_led_blink"
set bd_name "design_1"

# 스크립트 위치 감지
set script_dir [file dirname [file normalize [info script]]]
set project_root [file dirname $script_dir]
set project_dir "$project_root/out"

puts "=========================================="
puts "Creating Block Design"
puts "=========================================="

# 프로젝트 열기
puts "Opening project: $project_dir/$project_name.xpr"
open_project $project_dir/$project_name.xpr

# Block Design 생성
if {[file exists $project_dir/$project_name.gen/sources_1/bd/$bd_name]} {
    delete_bd_design $bd_name
}

create_bd_design $bd_name
current_bd_design $bd_name
puts "Created Block Design: $bd_name"

# 외부 포트 생성
set led_o [ create_bd_port -dir O led_o ]

# RTL 모듈 추가
puts "Adding top_module RTL..."
set block_name top_module
set block_cell_name top_module_0
if {[catch {set top_module_0 [create_bd_cell -type module -reference $block_name $block_cell_name]} errmsg]} {
    puts "Warning: Unable to add referenced block <$block_name>"
    set top_module_0 [create_bd_cell -type module -reference top_module top_module_0]
}

# Zynq UltraScale+ MPSoC IP 추가
puts "Adding Zynq PS IP..."
set zynq_ultra_ps_e_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.3 zynq_ultra_ps_e_0 ]

# M_AXI_GP0/1/2 비활성화 (클럭 경고 방지)
puts "Configuring Zynq PS..."
set_property -dict [list \
    CONFIG.PSU__USE__M_AXI_GP0 {0} \
    CONFIG.PSU__USE__M_AXI_GP1 {0} \
    CONFIG.PSU__USE__M_AXI_GP2 {0} \
] $zynq_ultra_ps_e_0

# KV260 보드 프리셋 적용
puts "Applying KV260 preset..."
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e \
    -config {apply_board_preset "KV260"} [get_bd_cells zynq_ultra_ps_e_0]
puts "KV260 preset applied!"

# 포트 연결
puts "Connecting ports..."
connect_bd_net -net top_module_0_led_o [get_bd_ports led_o] [get_bd_pins top_module_0/led_o]
connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins top_module_0/sysclk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins top_module_0/cpu_resetn] [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0]

# BD 검증 및 저장
validate_bd_design
save_bd_design

# HDL Wrapper 생성 - HWH 파일 생성을 위해 필수
puts "Creating HDL Wrapper..."
make_wrapper -files [get_files $project_dir/$project_name.xpr] -top -force

# Generate Output Products - IP 생성
puts "Generating output products..."
generate_target all [get_files $project_dir/$project_name.srcs/sources_1/bd/$bd_name/$bd_name.bd]

puts ""
puts "=========================================="
puts "Block Design created successfully!"
puts "=========================================="

# 프로젝트 닫기
close_project