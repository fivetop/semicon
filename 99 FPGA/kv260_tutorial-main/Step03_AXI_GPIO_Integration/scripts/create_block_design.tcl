# Copyright 2017 ETH Zurich and University of Bologna.
# Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51.
# SPDX-License-Identifier: SHL-0.51

# Step03: Create Block Design for AXI GPIO Integration
# Usage: source create_block_design.tcl

puts "=========================================="
puts "Step03: Creating AXI GPIO Block Design"
puts "=========================================="

# Create block design
set bd_name "axi_gpio_system"
create_bd_design ${bd_name}
current_bd_design ${bd_name}

# 1. Add Zynq UltraScale+ MPSoC
set zynq [create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.3 zynq_ps]
apply_board_selection -board_part "xilinx.com:kria:kv260_som:prc_ver1.0" [get_bd_cells zynq_ps]
run_bd_automation -rule xilinx.com:board_rule:zcu100 -config {apply_board_preset {1}} [get_bd_cells zynq_ps]

# Enable M_AXI_HPM0_LPD for GPIO
set_property -dict [list CONFIG.PCW_ENABLE_AXI_NOC_HP0 {1}] [get_bd_cells zynq_ps]
set_property -dict [list CONFIG.PCW_USE_M_AXI_GP0 {1}] [get_bd_cells zynq_ps]

puts "Zynq PS configured with AXI GP0"

# 2. Add AXI GPIO
set axi_gpio [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0]
set_property CONFIG.C_GPIO_WIDTH 4 [get_bd_cells axi_gpio_0]
set_property CONFIG.C_ALL_INPUTS 0 [get_bd_cells axi_gpio_0]
set_property CONFIG.C_ALL_OUTPUTS 1 [get_bd_cells axi_gpio_0]

puts "AXI GPIO added (4-bit output)"

# 3. Add AXI SmartConnect
set axi_smartconnect [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_smartconnect:1.0 axi_smartconnect_0]

puts "AXI SmartConnect added"

# 4. Make GPIO pins external
make_external [get_bd_pins axi_gpio_0/gpio]

# 5. Connect AXI interface
connect_bd_net [get_bd_pins zynq_ps/m_axi_hpm0_fpd] [get_bd_pins axi_smartconnect_0/M00_AXI]
connect_bd_net [get_bd_pins axi_smartconnect_0/S00_AXI] [get_bd_pins axi_gpio_0/S_AXI]

# 6. Connect clock and reset
connect_bd_net [get_bd_pins zynq_ps/pl_clk0] [get_bd_pins axi_gpio_0/s_axi_aclk]
connect_bd_net [get_bd_pins zynq_ps/pl_resetn0] [get_bd_pins axi_gpio_0/s_axi_aresetn]
connect_bd_net [get_bd_pins zynq_ps/pl_clk0] [get_bd_pins axi_smartconnect_0/m00_axi_aclk]
connect_bd_net [get_bd_pins zynq_ps/pl_resetn0] [get_bd_pins axi_smartconnect_0/m00_axi_aresetn]
connect_bd_net [get_bd_pins zynq_ps/pl_clk0] [get_bd_pins axi_smartconnect_0/s00_axi_aclk]
connect_bd_net [get_bd_pins zynq_ps/pl_resetn0] [get_bd_pin axi_smartconnect_0/s00_axi_aresetn]

# 7. Run connection automation
run_bd_automation -rule xilinx.com:ip automatic [get_bd_nets -of_objects [get_bd_cells zynq_ps]]

puts "=========================================="
puts "Block design created"
puts "=========================================="