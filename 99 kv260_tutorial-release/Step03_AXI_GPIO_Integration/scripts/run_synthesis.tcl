###############################################################################
# run_synthesis.tcl - 합성 스크립트
# Vivado 2025.2 대응
###############################################################################

set project_name "kv260_axi_gpio"
set bd_name "design_1"

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

# BD HDL 래퍼 생성
puts "Creating HDL Wrapper..."

# 프로젝트의 sources_1 파일셋에서 BD 파일 찾아서 래퍼 생성
set bd_file [get_files -of [get_filesets sources_1] -filter "NAME =~ *${bd_name}.bd"]
if {$bd_file ne ""} {
    puts "Found BD file: $bd_file"
    
    # 래퍼 생성 (HDL 자동 생성됨)
    puts "Creating wrapper..."
    make_wrapper -files $bd_file -top -force
    
    # 생성된 파일 확인 및 추가
    set wrapper_file "$project_dir/$project_name.gen/sources_1/bd/$bd_name/hdl/${bd_name}_wrapper.v"
    if {[file exists $wrapper_file]} {
        puts "Wrapper created: $wrapper_file"
        # 파일을 sources_1에 추가
        add_files -fileset sources_1 $wrapper_file
        # top 모듈 설정
        set_property top ${bd_name}_wrapper [get_filesets sources_1]
        puts "Added $wrapper_file to sources_1 and set as top"
    }
} else {
    puts "Warning: BD file not found"
}

# 합성 실행

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
