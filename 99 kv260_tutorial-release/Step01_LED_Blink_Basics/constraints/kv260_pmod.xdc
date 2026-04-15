# KV260 PMOD1 Pin Constraints
# LED Blink Project
# PMOD1 Pin 1 = H12 (HDA11)

# LED output pin - PMOD1 Pin 1
set_property PACKAGE_PIN H12 [get_ports led_out]
set_property IOSTANDARD LVCMOS33 [get_ports led_out]
set_property SLEW SLOW [get_ports led_out]
set_property DRIVE 4 [get_ports led_out]

# Clock input - from PS pl_clk0 (100MHz)
# Add timing constraint for clock
#create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]
#set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Reset input - from PS pl_resetn0 (active-low)
#set_property IOSTANDARD LVCMOS33 [get_ports resetn]

# Disable DRC warnings for clock (comes from PS, not external pin)
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
