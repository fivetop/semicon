# Copyright 2017 ETH Zurich and University of Bologna.
# Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51.
# SPDX-License-Identifier: SHL-0.51

# KV260 Pin Constraints for Step02 - IP Integrator Demo
# PMOD_A connector pins for clock status display

# Clock Constraint (100MHz from PS pl_clk0)
create_clock -period 10.000 -name sysclk -waveform {0.000 5.000} [get_ports sysclk]

# Primary System Clock (from PS)
# Bank 50 - Bank voltage: 1.8V
set_property PACKAGE_PIN E12 [get_ports sysclk]
set_property IOSTANDARD LVCMOS18 [get_ports sysclk]

# System Reset (from PS push button)
# SW16 - Button next to Ethernet port
set_property PACKAGE_PIN C12 [get_ports sys_rstn]
set_property IOSTANDARD LVCMOS18 [get_ports sys_rstn]

# PMOD_A Connector Pin Assignment (JE Connector)
# PMOD pin 1 - 100MHz clock status output
set_property PACKAGE_PIN H12 [get_ports pmod_clk_100m]
set_property IOSTANDARD LVCMOS33 [get_ports pmod_clk_100m]

# PMOD pin 2 - 50MHz clock status output
set_property PACKAGE_PIN H11 [get_ports pmod_clk_50m]
set_property IOSTANDARD LVCMOS33 [get_ports pmod_clk_50m]

# PMOD pin 3 - 25MHz clock status output
set_property PACKAGE_PIN G14 [get_ports pmod_clk_25m]
set_property IOSTANDARD LVCMOS33 [get_ports pmod_clk_25m]

# PMOD pin 4 - 12.5MHz clock status output
set_property PACKAGE_PIN G13 [get_ports pmod_clk_12m]
set_property IOSTANDARD LVCMOS33 [get_ports pmod_clk_12m]

# Configuration options
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]