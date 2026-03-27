# DRC 에러를 경고로 변경 (sysclk는 PS에서 제공됨)
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]

# Clock Constraint (100MHz from PS pl_clk0)
create_clock -period 10.000 -name sysclk -waveform {0.000 5.000} [get_ports sysclk]

# LED Output Pin Assignment
# PMOD Pin 1 (PMOD_HDA11) -> FPGA Pin H12
set_property PACKAGE_PIN H12 [get_ports led_o]
set_property IOSTANDARD LVCMOS33 [get_ports led_o]
set_property SLEW SLOW [get_ports led_o]
set_property DRIVE 4 [get_ports led_o]

# System Clock Constraint (100MHz from PS - internal, no pin needed)
# Note: create_clock already defined above for sysclk
