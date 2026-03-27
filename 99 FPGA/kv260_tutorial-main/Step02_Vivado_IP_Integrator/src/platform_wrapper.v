// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51.
// SPDX-License-Identifier: SHL-0.51

`timescale 1ns / 1ps

// Engineer:  KV260 Training Team
// Description: Platform Wrapper - Top-level module for KV260 IP Integrator demo
//              This module demonstrates clock generation and reset controller

module platform_wrapper (
    // Zynq PS Input Clocks
    input  wire        sysclk,          // 100MHz system clock from PS
    
    // Zynq PS Reset
    input  wire        sys_rstn,        // Active low reset from PS
    
    // DCM Locked Signal (tied high when using Zynq PS directly)
    input  wire        dcm_locked,       // Clock locked signal (not used in this simple version)
    
    // PL Clock Outputs (internal use)
    output wire        pl_clk0,          // 100MHz (same as sysclk)
    output wire        pl_clk1,          // 50MHz
    output wire        pl_clk2,          // 25MHz
    output wire        pl_clk3,          // 12.5MHz
    
    // PL Reset Outputs
    output wire        pl_resetn,        // Main PL reset
    output wire        peripheral_resetn, // Peripheral reset
    
    // PMOD Output for Clock Status Display
    // PMOD_A connector pins - show divided clock outputs
    output wire        pmod_clk_100m,    // 100MHz status (PMOD pin 1)
    output wire        pmod_clk_50m,     // 50MHz status (PMOD pin 2)
    output wire        pmod_clk_25m,     // 25MHz status (PMOD pin 3)
    output wire        pmod_clk_12m      // 12.5MHz status (PMOD pin 4)
    
);

    // Clock Generator Instance
    clock_generator #(
        .INPUT_CLK_PERIOD(10_000),
        .CLKOUT0_DIVIDE(1),
        .CLKOUT1_DIVIDE(2),
        .CLKOUT2_DIVIDE(4),
        .CLKOUT3_DIVIDE(8)
    ) u_clock_generator (
        .clk        (sysclk),
        .rstn       (sys_rstn),
        .locked     (dcm_locked),
        .clk_out0   (pl_clk0),
        .clk_out1   (pl_clk1),
        .clk_out2   (pl_clk2),
        .clk_out3   (pl_clk3)
    );

    // Reset Controller Instance
    reset_controller #(
        .RESET_CYCLES(100)
    ) u_reset_controller (
        .clk                (sysclk),
        .ext_rstn           (sys_rstn),
        .dcm_locked         (dcm_locked),
        .pl_resetn          (pl_resetn),
        .peripheral_rstn    (peripheral_resetn)
    );
    
    // PMOD Output Assignment - Connect divided clocks to PMOD pins
    // These signals can be observed with logic analyzer or connected to LEDs
    assign pmod_clk_100m = pl_clk0;
    assign pmod_clk_50m  = pl_clk1;
    assign pmod_clk_25m  = pl_clk2;
    assign pmod_clk_12m  = pl_clk3;
    
endmodule : platform_wrapper
