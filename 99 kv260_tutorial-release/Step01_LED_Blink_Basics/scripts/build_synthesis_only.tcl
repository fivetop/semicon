# KV260 LED Blink Project - Synthesis Only
# Creates Vivado project and runs synthesis to verify design

if {$argc > 0} {
    set output_dir [lindex $argv 0]
} else {
    set output_dir "out"
}
puts "Output directory: $output_dir"

set project_name "kv260_led_blink"
set project_dir "$output_dir/$project_name"

puts "Creating Vivado project..."
create_project $project_name $project_dir -part xck26-sfvc784-2LV-c -force
set_property target_language Verilog [current_project]

puts "Adding Verilog source files..."
add_files -fileset sources_1 [file normalize "src/led_blink.v"]

puts "Adding XDC constraints..."
add_files -fileset constrs_1 [file normalize "constraints/kv260_pmod.xdc"]

puts "Creating Block Design with Zynq PS..."
create_bd_design "design_1"
current_bd_design "design_1"

# Add Zynq UltraScale+ MPSoC IP
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.3 zynq_ultra_ps_e_0

# Apply KV260 board preset for proper configuration
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1"} [get_bd_cells zynq_ultra_ps_e_0]

# Configure PS for minimal LED blink design - only pl_clk0 needed
set_property -dict [list \
    CONFIG.PSU__FPGA_PL0_ENABLE {1} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {100} \
    CONFIG.PSU__USE__M_AXI_GP0 {0} \
    CONFIG.PSU__USE__M_AXI_GP1 {0} \
    CONFIG.PSU__USE__M_AXI_GP2 {0} \
] [get_bd_cells zynq_ultra_ps_e_0]

# Create clock port and connect to PS
create_bd_port -dir O -type clk clk
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_ports clk]

# Create LED output port for external connection
create_bd_port -dir O led_out

# Instantiate LED blink module in Block Design  
create_bd_cell -type module -reference led_blink led_blink_0
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins led_blink_0/clk]
connect_bd_net [get_bd_pins led_blink_0/led_out] [get_bd_ports led_out]

# Validate and save BD
validate_bd_design
save_bd_design

puts "Setting top module to BD wrapper..."
make_wrapper -files [get_files "$project_dir/$project_name.srcs/sources_1/bd/design_1/design_1.bd"] -top
add_files -norecurse "$project_dir/$project_name.gen/sources_1/bd/design_1/hdl/design_1_wrapper.v"
set_property top design_1_wrapper [get_filesets sources_1]
update_compile_order -fileset sources_1

puts "Running synthesis..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed"
    puts "Status: [get_property STATUS [get_runs synth_1]]"
    exit 1
}

puts "========================================"
puts "Synthesis completed successfully!"
puts "========================================"
puts "Project: $project_name"
puts "Output:  $project_dir"
puts "Status:  [get_property STATUS [get_runs synth_1]]"
puts "========================================"

exit 0