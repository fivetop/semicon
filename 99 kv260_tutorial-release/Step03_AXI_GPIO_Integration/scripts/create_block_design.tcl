###############################################################################
# create_block_design.tcl - AXI GPIO Integration Block Design
# Vivado 2025.2 대응
#
# fw_pynq/project_1의 TCL 생성 기능을 기반으로 작성
###############################################################################

set project_name "kv260_axi_gpio"
set bd_name "design_1"

# 스크립트 위치 감지
set script_dir [file dirname [file normalize [info script]]]
set project_root [file dirname $script_dir]
set project_dir "$project_root/out"

puts "=========================================="
puts "Creating Block Design: $bd_name"
puts "Project: $project_dir"
puts "=========================================="

# 프로젝트 열기
puts "Opening project: $project_dir/$project_name.xpr"
open_project $project_dir/$project_name.xpr

# Block Design 생성
create_bd_design $bd_name
current_bd_design $bd_name
puts "Created Block Design: $bd_name"

# GPIO 인터페이스 포트 생성
set led_out [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 led_out]

# Zynq UltraScale+ MPSoC 생성
set zynq_ultra_ps_e_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.5 zynq_ultra_ps_e_0]

# KV260 보드 프리셋 적용
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e \
    -config {apply_board_preset "KV260"} [get_bd_cells zynq_ultra_ps_e_0]

# M_AXI_GP0 활성화 (my_block_design.tcl과 동일)
set_property -dict [list \
    CONFIG.PSU_BANK_0_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_BANK_1_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_BANK_2_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_BANK_3_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU__USE__M_AXI_GP0 {1} \
    CONFIG.PSU__USE__M_AXI_GP1 {0} \
    CONFIG.PSU__USE__M_AXI_GP2 {0} \
    CONFIG.PSU__USE__IRQ0 {1} \
] $zynq_ultra_ps_e_0

# AXI GPIO 생성
set axi_gpio_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0]
set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_GPIO_WIDTH {4} \
] $axi_gpio_0

# AXI SmartConnect 생성
set axi_smc [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc]
set_property CONFIG.NUM_SI {1} $axi_smc

# Processor System Reset 생성
set rst_ps8_0_99M [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps8_0_99M]

# 인터페이스 연결
connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports led_out] [get_bd_intf_pins axi_gpio_0/GPIO]
connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_smc/M00_AXI] [get_bd_intf_pins axi_gpio_0/S_AXI]
connect_bd_intf_net -intf_net zynq_ultra_ps_e_0_M_AXI_HPM0_FPD [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD] [get_bd_intf_pins axi_smc/S00_AXI]

# 포트 연결
connect_bd_net -net rst_ps8_0_99M_peripheral_aresetn [get_bd_pins rst_ps8_0_99M/peripheral_aresetn] [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins axi_smc/aresetn]
connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk] [get_bd_pins axi_smc/aclk] [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins rst_ps8_0_99M/slowest_sync_clk]
connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins rst_ps8_0_99M/ext_reset_in]

# 주소 할당
assign_bd_address -offset 0xA0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force

# 저장
save_bd_design

# 프로젝트 닫기
close_project

puts ""
puts "Block Design created successfully!"
puts "Done!"