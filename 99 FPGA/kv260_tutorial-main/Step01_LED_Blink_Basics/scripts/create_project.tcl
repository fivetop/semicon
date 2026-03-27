###############################################################################
# create_project.tcl - KV260 LED Blink 프로젝트 생성 스크립트
# Vivado 2021.2対応
###############################################################################

set project_name "kv260_led_blink"

# 스크립트 위치 감지
set script_dir [file dirname [file normalize [info script]]]
set project_root [file dirname $script_dir]
set project_dir "$project_root/out"

puts "=========================================="
puts "KV260 LED Blink Project Generator"
puts "=========================================="
puts "Project Root: $project_root"
puts "Output Dir: $project_dir"

# 프로젝트 생성
if {[file exists $project_dir]} {
    puts "Removing existing project..."
    file delete -force $project_dir
}

puts "Creating project: $project_name"
create_project $project_name $project_dir -part xck26-sfvc784-2LV-c -force

# 소스 파일 추가
puts "Adding source files..."
set src_files [glob -nocomplain -directory $project_root/src *.v]
if {[llength $src_files] > 0} {
    add_files -fileset sources_1 $src_files
    puts "Added [llength $src_files] Verilog files"
}

# 제약조건 파일 추가
puts "Adding constraint files..."
set xdc_files [glob -nocomplain -directory $project_root/constraints *.xdc]
if {[llength $xdc_files] > 0} {
    add_files -fileset constrs_1 $xdc_files
    puts "Added [llength $xdc_files] XDC files"
}

# 프로젝트 설정
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]
update_compile_order -fileset sources_1

puts ""
puts "=========================================="
puts "Project created: $project_dir/$project_name.xpr"
puts "=========================================="

# 프로젝트 닫기
close_project
