// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51

`timescale 1ns / 1ps

module tb_reset_controller;

    localparam CLK_PERIOD = 10;  // 100MHz

    reg clk;
    reg ext_rstn;
    reg dcm_locked;
    wire pl_resetn;
    wire peripheral_rstn;

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // DUT instantiation
    reset_controller #(
        .RESET_CYCLES(10)
    ) dut (
        .clk(clk),
        .ext_rstn(ext_rstn),
        .dcm_locked(dcm_locked),
        .pl_resetn(pl_resetn),
        .peripheral_rstn(peripheral_rstn)
    );

    // Test stimulus
    initial begin
        $display("========================================");
        $display("Reset Controller Testbench Start");
        $display("========================================");
        
        ext_rstn = 0;
        dcm_locked = 0;
        
        #(CLK_PERIOD * 5);
        $display("[%0t] Deasserting external reset", $time);
        ext_rstn = 1;
        
        #(CLK_PERIOD * 3);
        $display("[%0t] DCM locked", $time);
        dcm_locked = 1;
        
        #(CLK_PERIOD * 50);
        
        $display("========================================");
        $display("Reset Controller Test Complete");
        $display("========================================");
        
        $finish;
    end

    // Monitor reset signals
    always @(posedge clk) begin
        if (pl_resetn !== 1'b0 && pl_resetn !== 1'b1) begin
            $display("[%0t] pl_resetn: X", $time);
        end
    end

    // Timeout
    initial begin
        #(200000);
        $display("ERROR: Timeout!");
        $finish;
    end

endmodule : tb_reset_controller
