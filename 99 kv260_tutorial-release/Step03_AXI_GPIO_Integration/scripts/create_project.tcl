###############################################################################
# create_project.tcl - 프로젝트 생성 스크립트
# Vivado 2025.2 대응
###############################################################################

set project_name "kv260_axi_gpio"

# 스크립트 위치 감지
set script_dir [file dirname [file normalize [info script]]]
set project_root [file dirname $script_dir]
set project_dir "$project_root/out"

puts "=========================================="
puts "Creating KV260 AXI GPIO Project"
puts "=========================================="

puts "Project Root: $project_root"
puts "Output Dir: $project_dir"

# 기존 프로젝트 삭제
if {[file exists $project_dir]} {
    puts "Removing existing project..."
    file delete -force $project_dir
}

# 프로젝트 생성
puts "Creating project: $project_name"
create_project $project_name $project_dir -part xck26-sfvc784-2LV-c -force

# 소스 파일 추가
puts "Adding source files...ignored."

# constraint 파일 추가
puts "Adding constraint files..."
set xdc_files [glob -nocomplain -directory $project_root/constraints *.xdc]
if {[llength $xdc_files] > 0} {
    add_files -fileset constrs_1 $xdc_files
    puts "Added [llength $xdc_files] XDC files"
}

# 프로젝트 속성 설정
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]

# 컴파일 순서 업데이트
update_compile_order -fileset sources_1
puts ""

puts "=========================================="
puts "Project created: $project_dir/$project_name.xpr"
puts "=========================================="

# 프로젝트 닫기
close_project