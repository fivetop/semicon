# KV260 LED Blink Project - Synthesis Only Script
# Runs synthesis to verify design without implementation
# Usage: vivado -mode batch -source run_synthesis.tcl -tclargs [output_dir]

if {$argc > 0} {
    set output_dir [lindex $argv 0]
} else {
    set output_dir "out"
}

set project_name "kv260_led_blink"
set project_dir "$output_dir/$project_name"

# Open existing project
puts "Opening project: $project_dir"
open_project "$project_dir/$project_name.xpr"

puts "Running synthesis..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed"
    puts "Status: [get_property STATUS [get_runs synth_1]]"
    close_project
    exit 1
}

puts "========================================"
puts "Synthesis completed successfully!"
puts "========================================"
puts "Project: $project_name"
puts "Output:  $project_dir"
puts "Status:  [get_property STATUS [get_runs synth_1]]"

# Report utilization if available
if {[get_property PROGRESS [get_runs synth_1]] == "100%"} {
    puts "Resource Utilization:"
    set util_file "$project_dir/$project_name.runs/synth_1/design_1_wrapper_utilization_synth.rpt"
    if {[file exists $util_file]} {
        puts "  Utilization report: $util_file"
    }
}

puts "========================================"

close_project
exit 0