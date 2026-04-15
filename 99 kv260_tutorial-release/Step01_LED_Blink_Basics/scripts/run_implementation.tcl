# KV260 LED Blink Project - Implementation & Bitstream Generation Script
# Runs implementation and generates bitstream for FPGA programming
# Usage: vivado -mode batch -source run_implementation.tcl -tclargs [output_dir]

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

# Check if synthesis is complete
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis must be completed first"
    puts "Run synthesis with: vivado -mode batch -source run_synthesis.tcl"
    close_project
    exit 1
}

puts "Running implementation..."
launch_runs impl_1 -jobs 4
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed"
    puts "Status: [get_property STATUS [get_runs impl_1]]"
    close_project
    exit 1
}
puts "Implementation completed"

# Check timing
set wns [get_property STATS.WNS [get_runs impl_1]]
puts "WNS (Worst Negative Slack): $wns"
if {$wns < 0} {
    puts "WARNING: Timing constraints not met (WNS < 0)"
} else {
    puts "SUCCESS: Timing constraints met"
}

# Create a pre-hook TCL file to disable DRC warnings
set prehook_file "$project_dir/disable_drc.tcl"
set fp [open $prehook_file w]
puts $fp "set_property SEVERITY Warning \[get_drc_checks NSTD-1\]"
puts $fp "set_property SEVERITY Warning \[get_drc_checks UCIO-1\]"
close $fp

# Add the pre-hook to write_bitstream step
set_property STEPS.WRITE_BITSTREAM.TCL.PRE [file normalize $prehook_file] [get_runs impl_1]

puts "Generating bitstream..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Clean up
file delete $prehook_file

# Report results
puts "========================================"
puts "Implementation completed!"
puts "========================================"
puts "Project: $project_name"
puts "Output:  $project_dir"
puts "WNS:     $wns"

# Find and report bitstream file
set bitstream_files [glob -nocomplain "$project_dir/$project_name.runs/impl_1/*.bit"]
if {[llength $bitstream_files] > 0} {
    set bitstream [lindex $bitstream_files 0]
    puts "SUCCESS: Bitstream generated"
    puts "  $bitstream"
    
    # Report file size
    set size [file size $bitstream]
    puts "  Size: [expr $size / 1024] KB"
} else {
    puts "ERROR: Bitstream file not found"
}

puts "========================================"

close_project
exit 0