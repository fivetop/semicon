`timescale 1ns / 1ps

// Testbench for LED Blink Module
// Verifies LED toggles every 50M clock cycles (0.5s at 100MHz = 1 full toggle)

module tb_led_blink;

    // Clock period: 10ns for 100MHz
    localparam CLOCK_PERIOD = 10;
    localparam TOGGLE_CYCLES = 50_000_000;  // Real timing for hardware
    
    // Testbench signals
    reg clk;
    reg resetn;
    wire led_out;
    
    // Test control
    integer cycle_count;
    integer toggle_count;
    reg initial_led_state;
    reg toggle_detected;
    integer fail_count;
    
    // DUT instantiation with fast simulation parameter
    led_blink #(.COUNTER_MAX(TOGGLE_CYCLES)) uut (
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
        $display("LED Blink Testbench Started (with Reset)");
        $display("Clock: 100MHz, Toggle Cycles: %d", TOGGLE_CYCLES);
        $display("========================================");
        
        // Initialize
        cycle_count = 0;
        toggle_count = 0;
        toggle_detected = 0;
        fail_count = 0;
        resetn = 0;  // Start in reset
        
        // Apply reset for 10 clock cycles
        repeat(10) @(posedge clk);
        $display("[%t] Releasing reset", $time);
        resetn = 1;
        
        // Wait for first clock after reset and capture initial LED state
        @(posedge clk);
        initial_led_state = led_out;
        $display("[%t] Initial LED state after reset: %b", $time, led_out);
        
        // Check reset functionality - LED should be 0 after reset
        if (led_out !== 1'b0) begin
            $display("ERROR: LED not in reset state (0) after reset release");
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: Reset functionality verified - LED starts at 0");
        end
        
        // Track LED transitions
        forever begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            
            // Detect toggle
            if (led_out != initial_led_state) begin
                toggle_detected = 1;
                toggle_count = toggle_count + 1;
                $display("[%t] LED Toggle #%d detected at cycle %d", 
                         $time, toggle_count, cycle_count);
                initial_led_state = led_out;
                
                // Check if toggle happened at correct time
                if (toggle_count == 1 && cycle_count != TOGGLE_CYCLES) begin
                    $display("ERROR: First toggle at cycle %d, expected %d", 
                             cycle_count, TOGGLE_CYCLES);
                    fail_count = fail_count + 1;
                end
            end
            
            // Stop after second toggle (full cycle = 1 second)
            if (toggle_count >= 2) begin
                // Verify timing - expect ~2 * TOGGLE_CYCLES for full blink cycle
                if (cycle_count >= (TOGGLE_CYCLES * 2) && cycle_count <= (TOGGLE_CYCLES * 2) + 100) begin
                    $display("========================================");
                    if (fail_count == 0) begin
                        $display("TEST PASSED: LED toggled at correct intervals");
                        $display("- Reset functionality: PASS");
                        $display("- Toggle timing: PASS");
                        $display("Total cycles: %d", cycle_count);
                        $display("========================================");
                        $display("PASS: LED toggle and reset verified");
                    end else begin
                        $display("TEST FAILED: %d errors detected", fail_count);
                        $display("========================================");
                        $display("FAIL");
                    end
                end else begin
                    $display("========================================");
                    $display("TEST FAILED: Incorrect timing");
                    $display("Total cycles: %d, Expected: ~%d", 
                             cycle_count, TOGGLE_CYCLES * 2);
                    $display("========================================");
                    $display("FAIL");
                    fail_count = fail_count + 1;
                end
                $finish;
            end
            
            // Timeout protection (10x expected cycles)
            if (cycle_count > TOGGLE_CYCLES * 10) begin
                $display("ERROR: Timeout - LED never toggled");
                $display("FAIL");
                $finish;
            end
        end
    end
    
    // Monitor LED state
    initial begin
        $monitor("Time: %t, LED: %b, Cycles: %d", $time, led_out, cycle_count);
    end

endmodule
