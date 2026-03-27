# Copyright 2017 ETH Zurich and University of Bologna.
# Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51.
# SPDX-License-Identifier: SHL-0.51

# Step03: KV260 Pin Constraints for AXI GPIO Demo

# System Clock
set_property PACKAGE_PIN E12 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS18 [get_ports sys_clk]

# System Reset (SW16)
set_property PACKAGE_PIN C12 [get_ports sys_rstn]
set_property IOSTANDARD LVCMOS18 [get_ports sys_rstn]

# PL User LEDs (Green)
# LED 0
set_property PACKAGE_PIN T14 [get_ports {gpio_out[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {gpio_out[0]}]

# LED 1
set_property PACKAGE_PIN U14 [get_ports {gpio_out[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {gpio_out[1]}]

# LED 2
set_property PACKAGE_PIN V14 [get_ports {gpio_out[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {gpio_out[2]}]

# LED 3
set_property PACKAGE_PIN V13 [get_ports {gpio_out[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {gpio_out[3]}]

# Configuration
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
