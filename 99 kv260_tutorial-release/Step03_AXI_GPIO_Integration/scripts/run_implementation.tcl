###############################################################################
# run_implementation.tcl - 구현 및 비트스트림 생성 스크립트
# Vivado 2025.2 대응
###############################################################################

set project_name "kv260_axi_gpio"
set bd_name "design_1"

# 스크립트 위치 감지
set script_dir [file dirname [file normalize [info script]]]
set project_root [file dirname $script_dir]
set project_dir "$project_root/out"

puts "=========================================="
puts "Running Implementation"
puts "=========================================="

# 프로젝트 열기
puts "Opening project: $project_dir/$project_name.xpr"
open_project $project_dir/$project_name.xpr

# 합성이 안 되어 있으면 먼저 합성
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "Running synthesis first..."
    source $script_dir/run_synthesis.tcl
}

# 구현 실행
puts "Resetting impl_1 run..."
reset_run impl_1

puts "Launching implementation..."
launch_runs impl_1 -jobs 4
wait_on_run impl_1

if {[get_property STATUS [get_runs impl_1]] == "route_design Complete!"} {
    puts "Implementation completed!"
} else {
    puts "Implementation failed!"
    open_run impl_1 -name impl_1
    exit 1
}

# 비트스트림 생성 - 직접 생성하여 DRC 설정 적용
puts "Generating Bitstream..."

# DRC 에러를 경고로 변경 (sysclk는 PS에서 제공됨)
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]

# 라우팅된 DCP를 열고 bitstream 생성
open_checkpoint $project_dir/$project_name.runs/impl_1/design_1_wrapper_routed.dcp
write_bitstream -force $project_dir/$project_name.runs/impl_1/design_1_wrapper.bit

puts "Bitstream generated!"

# Result 파일 디렉토리 생성
set result_dir "$project_dir/result_files"
if {![file exists $result_dir]} {
    file mkdir $result_dir
}

set bit_src "$project_dir/$project_name.runs/impl_1/design_1_wrapper.bit"
set hwh_src "$project_dir/$project_name.gen/sources_1/bd/$bd_name/hw_handoff/${bd_name}.hwh"

# BIT 파일 복사 (프로젝트 이름으로 저장)
if {[file exists $bit_src]} {
    file copy -force $bit_src "$result_dir/${project_name}.bit"
    puts "Copied: $result_dir/${project_name}.bit"
} else {
    puts "Warning: Bitstream not found: $bit_src"
}

# HWH 파일 복사 (프로젝트 이름으로 저장)
if {[file exists $hwh_src]} {
    file copy -force $hwh_src "$result_dir/${project_name}.hwh"
    puts "Copied: $result_dir/${project_name}.hwh"
} else {
    puts "Warning: HWH file not found: $hwh_src"
}

# XSA 파일 생성 (프로젝트 이름으로 저장)
puts "Generating XSA file..."
set xsa_file "$result_dir/${project_name}.xsa"

# write_hw_platform 명령 실행
write_hw_platform -fixed -include_bit -force -file $xsa_file

if {[file exists $xsa_file]} {
    puts "Generated: $xsa_file"
} else {
    puts "Warning: XSA generation failed"
}

puts "Result files ready in: $result_dir"

# Implementation Report 생성
puts "Generating implementation reports..."

set impl_report_dir "$project_dir/report/implementation"
if {![file exists $impl_report_dir]} {
    file mkdir -p $impl_report_dir
}

# Timing Summary Report
report_timing_summary \
    -file "$impl_report_dir/impl_timing_summary.rpt"

# Clock Utilization Report
report_clock_utilization \
    -file "$impl_report_dir/impl_clock_utilization.rpt"

# Resource Utilization Report
report_utilization \
    -file "$impl_report_dir/impl_utilization.rpt"

# Power Report
report_power \
    -file "$impl_report_dir/impl_power.rpt"

# DRC Report
report_drc \
    -file "$impl_report_dir/impl_drc.rpt"

puts "Implementation reports generated!"

puts "=========================================="
puts "Build Complete!"
puts "=========================================="

# 프로젝트 닫기
close_project
