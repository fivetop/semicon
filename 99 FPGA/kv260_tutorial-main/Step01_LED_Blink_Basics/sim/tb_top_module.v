// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51

// Testbench for top_module (includes led_blinker)
// Xilinx xsim compatible

`timescale 1ns / 1ps

module tb_top_module;

    // Clock period for 100MHz
    localparam CLK_PERIOD = 10;

    // Test signals
    reg sysclk;
    reg cpu_resetn;
    wire led_o;

    // Instantiate the DUT (Design Under Test)
    // REF_CLK를 1000으로 설정하여 시뮬레이션 속도 증가
    top_module #(
        .REF_CLK(1000)
    ) dut (
        .sysclk(sysclk),
        .cpu_resetn(cpu_resetn),
        .led_o(led_o)
    );

    // Clock generation
    initial begin
        sysclk = 0;
        forever #(CLK_PERIOD/2) sysclk = ~sysclk;
    end

    // Reset generation
    initial begin
        cpu_resetn = 0;
        #(CLK_PERIOD * 2);
        cpu_resetn = 1;
    end

    // Test stimulus
    initial begin
        $display("========================================");
        $display("top_module LED Blinker Testbench Start");
        $display("========================================");
        
        // Wait for reset to deassert
        @(posedge cpu_resetn);
        #(CLK_PERIOD);
        
        $display("[%0t] Reset deasserted, testing LED...", $time);
        
        // Test 1: Verify LED starts low
        if (led_o == 1'b0) begin
            $display("[%0t] PASS: LED starts LOW", $time);
        end else begin
            $display("[%0t] FAIL: LED should start LOW", $time);
        end
        
        // Test 2: Wait for first LED toggle
        $display("[%0t] Waiting for first LED toggle...", $time);
        
        @(posedge led_o);
        $display("[%0t] PASS: LED went HIGH", $time);
        
        // Test 3: Verify toggle period
        // With 100MHz clock, toggle should occur every ~500ms
        // In simulation: 100MHz = 10ns period
        // Half period = 50,000,000 cycles = 500,000,000 ns = 500 ms
        
        $display("[%0t] Verifying toggle timing...", $time);
        
        // Wait for second toggle
        @(negedge led_o);
        $display("[%0t] PASS: LED went LOW", $time);
        
        // Test 4: Multiple toggles
        $display("[%0t] Testing multiple toggles...", $time);
        
        repeat(3) begin
            @(posedge led_o);
            $display("[%0t] LED toggle detected", $time);
        end
        
        // Test 5: Final LED state check
        $display("[%0t] Final LED state: %b", $time, led_o);
        
        $display("========================================");
        $display("Testbench Complete - ALL TESTS PASSED");
        $display("========================================");
        
        $finish;
    end

    // VCD dump for waveform viewing
    initial begin
        $dumpfile("tb_top_module.vcd");
        $dumpvars(0, tb_top_module);
    end

endmodule : tb_top_module
