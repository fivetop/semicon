// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51

`timescale 1ns / 1ps

module tb_platform_wrapper;

    localparam CLK_PERIOD = 10;  // 100MHz

    reg sysclk;
    reg sys_rstn;
    reg dcm_locked;
    wire pl_clk0;
    wire pl_clk1;
    wire pl_clk2;
    wire pl_clk3;
    wire pl_resetn;
    wire peripheral_resetn;

    // Clock generation
    initial begin
        sysclk = 0;
        forever #(CLK_PERIOD/2) sysclk = ~sysclk;
    end

    // DUT instantiation
    platform_wrapper dut (
        .sysclk(sysclk),
        .sys_rstn(sys_rstn),
        .dcm_locked(dcm_locked),
        .pl_clk0(pl_clk0),
        .pl_clk1(pl_clk1),
        .pl_clk2(pl_clk2),
        .pl_clk3(pl_clk3),
        .pl_resetn(pl_resetn),
        .peripheral_resetn(peripheral_resetn)
    );

    // Test stimulus
    initial begin
        $display("========================================");
        $display("Platform Wrapper Testbench Start");
        $display("========================================");
        
        sys_rstn = 0;
        dcm_locked = 0;
        
        #(CLK_PERIOD * 5);
        $display("[%0t] Deasserting external reset", $time);
        sys_rstn = 1;
        
        #(CLK_PERIOD * 3);
        $display("[%0t] DCM locked - starting reset sequence", $time);
        dcm_locked = 1;
        
        $display("[%0t] pl_resetn=%b, peripheral_resetn=%b", 
                 $time, pl_resetn, peripheral_resetn);
        
        #(CLK_PERIOD * 100);
        
        $display("========================================");
        $display("Platform Wrapper Test Complete");
        $display("========================================");
        
        $finish;
    end

    // Timeout
    initial begin
        #(500000);
        $display("ERROR: Timeout!");
        $finish;
    end

    // VCD dump
    initial begin
        $dumpfile("tb_platform_wrapper.vcd");
        $dumpvars(0, tb_platform_wrapper);
    end

endmodule : tb_platform_wrapper
