# KV260 LED Blink Project - Project Creation Script
# Creates basic Vivado project structure and adds source files
# Usage: vivado -mode batch -source create_project.tcl -tclargs [output_dir]

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

puts "========================================"
puts "Project creation completed!"
puts "========================================"
puts "Project: $project_name"
puts "Output:  $project_dir" 
puts "Next step: Run create_block_design.tcl"
puts "========================================"

exit 0