###############################################################################
# run_synthesis.tcl - 합성 스크립트
# Vivado 2021.2対応
###############################################################################

set project_name "kv260_led_blink"

# 스크립트 위치 감지
set script_dir [file dirname [file normalize [info script]]]
set project_root [file dirname $script_dir]
set project_dir "$project_root/out"

puts "=========================================="
puts "Running Synthesis"
puts "=========================================="

# 프로젝트 열기
puts "Opening project: $project_dir/$project_name.xpr"
open_project $project_dir/$project_name.xpr

# HDL Wrapper 생성
if {![file exists $project_dir/$project_name.gen/sources_1/bd/design_1/design_1.bd]} {
    puts "Creating HDL Wrapper..."
    make_wrapper -files [get_files $project_dir/$project_name.xpr] -top -force
}

# 합성 실행
puts "Resetting synth_1 run..."
reset_run synth_1

puts "Launching synthesis..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {[get_property STATUS [get_runs synth_1]] == "synth_design Complete!"} {
    puts "Synthesis completed successfully!"
} else {
    puts "Synthesis failed!"
    open_run synth_1 -name synth_1
    exit 1
}

# Design 열기 (Report 생성을 위해)
puts "Opening synthesized design..."
open_run synth_1

# Report 생성
puts "Generating reports..."

# Report 디렉토리 생성
set report_dir "$project_dir/report/synthesis"
if {![file exists $report_dir]} {
    file mkdir -p $report_dir
}

# Timing Summary Report
report_timing_summary \
    -file "$report_dir/synthesis_timing_summary.rpt"

# Clock Utilization Report
report_clock_utilization \
    -file "$report_dir/synthesis_clock_utilization.rpt"

# Resource Utilization Report
report_utilization \
    -file "$report_dir/synthesis_utilization.rpt"

# Power Report
report_power \
    -file "$report_dir/synthesis_power.rpt"

puts "Reports generated in: $report_dir"

# 프로젝트 닫기
close_project

puts "=========================================="
puts "Synthesis Complete!"
puts "=========================================="
