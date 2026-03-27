# Copyright 2017 ETH Zurich and University of Bologna.
# Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51.
# SPDX-License-Identifier: SHL-0.51

# Step05: Create Block Design for KV260 BIST Platform

puts "=========================================="
puts "Step05: Creating BIST Platform Block Design"
puts "=========================================="

# Create block design
set bd_name "kv260_bist_platform"
create_bd_design ${bd_name}
current_bd_design ${bd_name}

# 1. Add Zynq UltraScale+ MPSoC
set zynq [create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.3 zynq_ps]
apply_board_selection -board_part "xilinx.com:kria:kv260_som:prc_ver1.0" [get_bd_cells zynq_ps]
run_bd_automation -rule xilinx.com:board_rule:zcu100 -config {apply_board_preset {1}} [get_bd_cells zynq_ps]

puts "Zynq PS configured"

# 2. Add AXI GPIO for BIST control/status
set axi_gpio [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_bist]
set_property CONFIG.C_GPIO_WIDTH 8 [get_bd_cells axi_gpio_bist]
set_property CONFIG.C_ALL_INPUTS 0 [get_bd_cells axi_gpio_bist]
set_property CONFIG.C_ALL_OUTPUTS 1 [get_bd_cells axi_gpio_bist]

puts "AXI GPIO (8-bit) added"

# 3. Add AXI BRAM Controller for memory test
set axi_bram [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl]

# 4. Add Block RAM
set blk_ram [create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen]
set_property CONFIG.Memory_Type True_DP_RAM [get_bd_cells blk_mem_gen]
set_property CONFIG.Memory_Size 16384 [get_bd_cells blk_mem_gen]

puts "Block RAM added"

# 5. Add Clocking Wizard for additional clocks
set clk_wiz [create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz]
set_property CONFIG.PRIM_IN_FREQ 100.000 [get_bd_cells clk_wiz]
set_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 200.000 [get_bd_cells clk_wiz]
set_property CONFIG.CLKOUT2_REQUESTED_OUT_FREQ 400.000 [get_bd_cells clk_wiz]

puts "Clocking Wizard added"

# 6. Add Processor System Reset
set proc_sys_rst [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset]

puts "Processor System Reset added"

# 7. Make GPIO external
make_external [get_bd_pins axi_gpio_bist/gpio]

# 8. Run connection automation
run_bd_automation -rule xilinx.com:ip automatic

puts "=========================================="
puts "BIST Platform block design created"
puts "=========================================="