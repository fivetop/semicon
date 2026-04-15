// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51

`timescale 1ns / 1ps

module tb_clock_generator;

    localparam CLK_PERIOD = 10;  // 100MHz

    reg clk;
    reg rstn;
    reg locked;
    wire clk_out0;
    wire clk_out1;
    wire clk_out2;
    wire clk_out3;

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // DUT instantiation
    clock_generator #(
        .INPUT_CLK_PERIOD(10000),
        .CLKOUT0_DIVIDE(1),
        .CLKOUT1_DIVIDE(2),
        .CLKOUT2_DIVIDE(4),
        .CLKOUT3_DIVIDE(8)
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .locked(locked),
        .clk_out0(clk_out0),
        .clk_out1(clk_out1),
        .clk_out2(clk_out2),
        .clk_out3(clk_out3)
    );

    // Test stimulus
    initial begin
        $display("========================================");
        $display("Clock Generator Testbench Start");
        $display("========================================");
        
        rstn = 0;
        locked = 0;
        
        #(CLK_PERIOD * 10);
        rstn = 1;
        #(CLK_PERIOD * 2);
        locked = 1;
        
        $display("[%0t] Reset deasserted, DCM locked", $time);
        $display("CLKOUT0 frequency: %b (100MHz pass through)", clk_out0);
        
        #(CLK_PERIOD * 100);
        
        $display("========================================");
        $display("Clock Generator Test Complete");
        $display("========================================");
        
        $finish;
    end

    // Timeout
    initial begin
        #(100000);
        $display("ERROR: Timeout!");
        $finish;
    end

endmodule : tb_clock_generator
