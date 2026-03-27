# Copyright 2017 ETH Zurich and University of Bologna.
# Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51.
# SPDX-License-Identifier: SHL-0.51

# Step03: Create Vivado Project for AXI GPIO
puts "Creating AXI GPIO Project"
set project_name "kv260_axi_gpio"
set project_dir "C:/Xilinx/Vivado_Projects/${project_name}"
set part_name "xck26-sfvc784-2LV-c"
file mkdir ${project_dir}
create_project ${project_name} ${project_dir} -part ${part_name} -force
set_property target_language Verilog [current_project]
puts "Project created: ${project_name}"