`timescale 1ns / 1ps

// Fast Testbench for LED Blink Module with Reset
// Uses reduced counter for faster simulation

module tb_led_blink_fast;

    // Clock period: 10ns for 100MHz
    localparam CLOCK_PERIOD = 10;
    localparam FAST_CYCLES = 1000;  // Much faster for simulation
    
    // Testbench signals
    reg clk;
    reg resetn;
    wire led_out;
    
    // Test control
    integer cycle_count;
    integer toggle_count;
    reg initial_led_state;
    reg test_passed;
    
    // DUT instantiation with fast simulation parameter
    led_blink #(.COUNTER_MAX(FAST_CYCLES)) uut (
        .clk(clk),
        .resetn(resetn),
        .led_out(led_out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLOCK_PERIOD/2) clk = ~clk;
    end
    
    // Test sequence
    initial begin
        $display("========================================");
        $display("LED Blink Fast Testbench with Reset");
        $display("Clock: 100MHz, Toggle Cycles: %d", FAST_CYCLES);
        $display("========================================");
        
        // Initialize
        cycle_count = 0;
        toggle_count = 0;
        test_passed = 1;
        resetn = 0;  // Start in reset
        
        // Apply reset for 5 clock cycles
        repeat(5) @(posedge clk);
        $display("[%t] Releasing reset", $time);
        resetn = 1;
        
        // Wait for first clock after reset
        @(posedge clk);
        initial_led_state = led_out;
        $display("[%t] LED after reset: %b", $time, led_out);
        
        // Check reset functionality
        if (led_out !== 1'b0) begin
            $display("ERROR: LED not in reset state after reset");
            test_passed = 0;
        end else begin
            $display("PASS: Reset functionality verified");
        end
        
        // Test reset during operation
        // Wait for half toggle period
        repeat(FAST_CYCLES/2) @(posedge clk);
        $display("[%t] Applying reset during operation", $time);
        resetn = 0;
        @(posedge clk);
        @(posedge clk);
        
        if (led_out !== 1'b0) begin
            $display("ERROR: LED not reset during operation");
            test_passed = 0;
        end else begin
            $display("PASS: Reset during operation verified");
        end
        
        // Release reset and test normal operation
        resetn = 1;
        @(posedge clk);
        
        // Wait for first toggle
        repeat(FAST_CYCLES + 10) @(posedge clk);
        if (led_out !== 1'b1) begin
            $display("ERROR: LED did not toggle after reset release");
            test_passed = 0;
        end else begin
            $display("PASS: LED toggled after reset release");
        end
        
        // Wait for second toggle  
        repeat(FAST_CYCLES + 10) @(posedge clk);
        if (led_out !== 1'b0) begin
            $display("ERROR: LED did not toggle back");
            test_passed = 0;
        end else begin
            $display("PASS: LED toggled back to 0");
        end
        
        // Final results
        $display("========================================");
        if (test_passed) begin
            $display("ALL TESTS PASSED");
            $display("✓ Reset functionality: PASS");
            $display("✓ Reset during operation: PASS"); 
            $display("✓ Normal toggle operation: PASS");
            $display("========================================");
            $display("PASS: LED toggle and reset verified");
        end else begin
            $display("SOME TESTS FAILED");
            $display("========================================");
            $display("FAIL");
        end
        
        $finish;
    end

endmodule