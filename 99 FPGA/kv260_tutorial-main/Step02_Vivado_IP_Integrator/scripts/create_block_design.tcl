###############################################################################
# create_block_design.tcl - Block Design 생성 스크립트
# Vivado 2021.2 대응
#
# 옵션 (환경 변수 또는 TCL 변수):
#   USE_RTL_CLOCK  - RTL clock_generator 모듈 사용 (기본: 1)
#   USE_IP_CLOCK   - Xilinx Clocking Wizard IP 사용 (기본: 0)
#   예: set env(USE_IP_CLOCK) 1
###############################################################################

# 클럭 모드 설정 (기본값: RTL)
if {![info exists env(USE_RTL_CLOCK)]} { set env(USE_RTL_CLOCK) 1 }
if {![info exists env(USE_IP_CLOCK)]}  { set env(USE_IP_CLOCK) 0 }

set use_rtl_clock $env(USE_RTL_CLOCK)
set use_ip_clock  $env(USE_IP_CLOCK)

puts "=========================================="
puts "Block Design Options:"
puts "  USE_RTL_CLOCK: $use_rtl_clock"
puts "  USE_IP_CLOCK:  $use_ip_clock"
puts "=========================================="

set project_name "kv260_ipi"
set bd_name "system"

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

# Block Design 삭제 (이미 있으면)
set bd_exists 0
catch {
    set bd_files [get_files -of [get_filesets sources_1] -filter "NAME =~ *${bd_name}.bd"]
    if {[llength $bd_files] > 0} {
        puts "Removing old Block Design reference..."
        remove_files $bd_files
        set bd_exists 1
    }
}

# 소스 디렉토리에서도 삭제
set bd_dir "$project_dir/$project_name.srcs/sources_1/bd/$bd_name"
if {[file exists $bd_dir]} {
    puts "Deleting Block Design directory..."
    file delete -force $bd_dir
}

#.gen 디렉토리도 삭제
set gen_dir "$project_dir/$project_name.gen/sources_1/bd/$bd_name"
if {[file exists $gen_dir]} {
    file delete -force $gen_dir
}

create_bd_design $bd_name
current_bd_design $bd_name
puts "Created Block Design: $bd_name"

# 1. Zynq UltraScale+ MPSoC 추가
puts "Adding Zynq PS IP..."
set zynq_ultra_ps_e_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.3 zynq_ultra_ps_e_0 ]

# M_AXI_GP 비활성화 (PL만 사용)
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

# 2. 클럭 소스 추가 (RTL 또는 IP 선택)
puts "Adding clock source..."

# RTL clock_generator 모듈 추가 함수
proc add_rtl_clock_generator {} {
    puts "  Adding RTL clock_generator module..."
    set block_name clock_generator
    set block_cell_name clock_generator_0
    if {[catch {
        set clock_generator_0 [create_bd_cell -type module -reference $block_name $block_cell_name]
    } errmsg]} {
        puts "Warning: Unable to add referenced block <$block_name>"
    }
    
    # pl_clk0 -> clk 연결
    connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins clock_generator_0/clk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
    
    # pl_resetn -> rstn 연결
    connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins clock_generator_0/rstn] [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0]
    
    # locked 신호는 always enabled로 설정 (MMCM lock 신호 대신)
    set_property -dict [list CONFIG.PARAMETER.VALUE {1}] [get_bd_pins clock_generator_0/locked]
    
    puts "  RTL clock_generator added!"
}

# Xilinx Clocking Wizard IP 추가 함수
proc add_ip_clock_wizard {} {
    puts "  Adding Xilinx Clocking Wizard IP..."
    
    # Clocking Wizard IP 생성
    set clk_wiz_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0]
    
    # Clocking Wizard 설정 (100MHz 입력, 100MHz, 200MHz 출력)
    set_property -dict [list \
        CONFIG.PRIM_IN_FREQ {100.000} \
        CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
        CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000} \
        CONFIG.CLKOUT1_REQUESTED_OUT_PHASE {0.000} \
        CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {200.000} \
        CONFIG.CLKOUT2_REQUESTED_OUT_PHASE {0.000} \
        CONFIG.USE_RESET {false} \
        CONFIG.USE_LOCKED {true} \
    ] $clk_wiz_0
    
    # 입력 클럭 연결
    connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins clk_wiz_0/clk_in1] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
    
    # 출력 클럭 포트 생성 및 연결
    # clk_out1 (100MHz)
    set clk_port_100m [create_bd_port -dir O -type clk clk_100m]
    set_property -dict [list CONFIG.FREQ_HZ {100000000} CONFIG.ASSOCIATED_RESET {}] $clk_port_100m
    connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins clk_100m]
    
    # clk_out2 (200MHz)
    set clk_port_200m [create_bd_port -dir O -type clk clk_200m]
    set_property -dict [list CONFIG.FREQ_HZ {200000000} CONFIG.ASSOCIATED_RESET {}] $clk_port_200m
    connect_bd_net -net clk_wiz_0_clk_out2 [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins clk_200m]
    
    puts "  Clocking Wizard IP added!"
}

# 옵션에 따라 클럭 소스 추가
if {$use_rtl_clock == 1} {
    add_rtl_clock_generator
}
if {$use_ip_clock == 1} {
    add_ip_clock_wizard
}

# 3. RTL 모듈 추가 (platform_wrapper)
puts "Adding platform_wrapper RTL..."
set block_name platform_wrapper
set block_cell_name platform_wrapper_0
if {[catch {
    set platform_wrapper_0 [create_bd_cell -type module -reference $block_name $block_cell_name]
} errmsg]} {
    puts "Warning: Unable to add referenced block <$block_name>"
    set platform_wrapper_0 [create_bd_cell -type module -reference platform_wrapper platform_wrapper_0]
}

# 3. 포트 연결
puts "Connecting ports..."
connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins platform_wrapper_0/sysclk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins platform_wrapper_0/sys_rstn] [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0]
puts "Ports connected!"

# 4. PMOD 포트 Export (external ports로 설정)
puts "Exporting PMOD ports..."
foreach pmod_port {"pmod_clk_100m" "pmod_clk_50m" "pmod_clk_25m" "pmod_clk_12m"} {
    set_property -dict [list CONFIG.PORT_WIDTH {1} CONFIG.DIRECTION {output}] [get_bd_ports $pmod_port]
}
puts "PMOD ports exported!"

# 5. BD 검증 및 저장
puts "Validating Block Design..."
validate_bd_design
save_bd_design

# HDL Wrapper 생성
puts "Creating HDL Wrapper..."
make_wrapper -files [get_files $project_dir/$project_name.xpr] -top -force

# Output Products 생성
puts "Generating output products..."
generate_target all [get_files $project_dir/$project_name.srcs/sources_1/bd/$bd_name/$bd_name.bd]

puts ""
puts "=========================================="
puts "Block Design created successfully!"
puts "=========================================="

# 프로젝트 닫기
close_project
