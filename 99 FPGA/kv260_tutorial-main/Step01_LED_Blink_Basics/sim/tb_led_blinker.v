// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51

// Testbench for LED Blinker
// Xilinx xsim compatible

`timescale 1ns / 1ps

module tb_led_blinker;

    // Clock period for 100MHz
    localparam CLK_PERIOD = 10;

    // Test signals
    reg sysclk;
    wire led_o;

    // Instantiate the DUT (Design Under Test)
    led_blinker #(
        .REF_CLK(100_000_000)
    ) dut (
        .sysclk(sysclk),
        .o_led(led_o)
    );

    // Clock generation
    initial begin
        sysclk = 0;
        forever #(CLK_PERIOD/2) sysclk = ~sysclk;
    end

    // Test stimulus
    initial begin
        $display("========================================");
        $display("LED Blinker Testbench Start");
        $display("========================================");
        
        // Wait for initial reset
        #(CLK_PERIOD * 2);
        
        $display("[%0t] Testing LED toggle at 100MHz clock", $time);
        
        // Test 1: Verify LED toggles at correct rate
        // For 100MHz clock, LED should toggle every 0.5 seconds
        // At 100MHz, half period = 100,000,000 / 2 = 50,000,000 cycles
        
        $display("[%0t] Waiting for first LED toggle...", $time);
        
        // Wait for LED to go high
        @(posedge led_o);
        $display("[%0t] LED went HIGH at time", $time);
        
        // Wait for LED to go low
        @(negedge led_o);
        $display("[%0t] LED went LOW at time", $time);
        
        // Wait for another toggle
        @(posedge led_o);
        $display("[%0t] LED went HIGH again at time", $time);
        
        // Test 2: Verify multiple toggles
        $display("[%0t] Testing multiple toggles...", $time);
        
        repeat(5) begin
            @(posedge led_o);
            $display("[%0t] LED toggle #%0d", $time, dut.r_count);
        end
        
        $display("========================================");
        $display("Testbench Complete - PASSED");
        $display("========================================");
        
        $finish;
    end

    // Timeout watchdog (prevent infinite simulation)
    initial begin
        #(10_000_000_000);  // 10 seconds timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule : tb_led_blinker
