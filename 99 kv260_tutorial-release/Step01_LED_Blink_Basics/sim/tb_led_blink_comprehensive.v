`timescale 1ns / 1ps

//=============================================================================
// Comprehensive LED Blink Testbench with VCD Generation
// Tests reset functionality, timing, and generates waveform files
//=============================================================================

module tb_led_blink_comprehensive;

    //=========================================================================
    // Parameters and Constants
    //=========================================================================
    
    // Clock parameters
    localparam CLOCK_PERIOD = 10;           // 10ns = 100MHz
    localparam CLOCK_FREQ = 100_000_000;    // 100MHz
    
    // Counter values for different test modes
    localparam REAL_COUNTER = 50_000_000;   // Real hardware timing
    localparam FAST_COUNTER = 1000;         // Fast simulation timing
    localparam TEST_COUNTER = 100;          // Ultra-fast for comprehensive tests
    
    // Test configuration
    localparam TEST_CYCLES = TEST_COUNTER;
    localparam NUM_TOGGLES_TO_TEST = 4;     // Test 4 complete toggles
    
    //=========================================================================
    // Testbench Signals
    //=========================================================================
    
    // DUT signals
    reg clk;
    reg resetn;
    wire led_out;
    
    // Test control and monitoring
    integer cycle_count;
    integer toggle_count;
    integer reset_test_count;
    
    // Test status tracking
    reg [255:0] test_name;
    reg test_passed;
    reg all_tests_passed;
    
    // Timing measurement
    integer last_toggle_time;
    integer current_toggle_time;
    integer toggle_period;
    
    // VCD control
    reg vcd_enabled;
    
    //=========================================================================
    // DUT Instantiation
    //=========================================================================
    
    led_blink #(
        .COUNTER_MAX(TEST_CYCLES)
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .led_out(led_out)
    );
    
    //=========================================================================
    // Clock Generation
    //=========================================================================
    
    initial begin
        clk = 0;
        forever #(CLOCK_PERIOD/2) clk = ~clk;
    end
    
    //=========================================================================
    // VCD File Generation
    //=========================================================================
    
    initial begin
        // Check if VCD generation is requested via environment variable
        // Default to enabled if not specified
        if ($value$plusargs("VCD=%s", test_name)) begin
            vcd_enabled = 1;
        end else begin
            vcd_enabled = 1; // Default enabled
        end
        
        if (vcd_enabled) begin
            $dumpfile("waveforms/led_blink_tb.vcd");
            $dumpvars(0, tb_led_blink_comprehensive);
            $display("VCD file generation enabled: waveforms/led_blink_tb.vcd");
        end
    end
    
    //=========================================================================
    // Test Procedures
    //=========================================================================
    
    // Task: Apply reset and verify
    task test_reset;
        input [255:0] test_description;
        input integer reset_cycles;
        begin
            test_name = test_description;
            $display("\n--- %s ---", test_description);
            
            resetn = 0;
            repeat(reset_cycles) @(posedge clk);
            
            // Check reset state
            if (led_out !== 1'b0) begin
                $display("FAIL: LED not 0 during reset (LED=%b)", led_out);
                test_passed = 0;
            end else begin
                $display("PASS: LED correctly held at 0 during reset");
            end
            
            resetn = 1;
            @(posedge clk);
            
            // Verify LED starts at 0 after reset release
            if (led_out !== 1'b0) begin
                $display("FAIL: LED not 0 after reset release (LED=%b)", led_out);
                test_passed = 0;
            end else begin
                $display("PASS: LED correctly starts at 0 after reset release");
            end
        end
    endtask
    
    // Task: Wait for LED toggle and measure timing
    task wait_for_toggle;
        input integer timeout_cycles;
        output integer actual_cycles;
        reg prev_led_state;
        begin
            prev_led_state = led_out;
            actual_cycles = 0;
            
            while (led_out == prev_led_state && actual_cycles < timeout_cycles) begin
                @(posedge clk);
                actual_cycles = actual_cycles + 1;
            end
            
            if (actual_cycles >= timeout_cycles) begin
                $display("TIMEOUT: LED did not toggle within %d cycles", timeout_cycles);
                test_passed = 0;
            end
        end
    endtask
    
    // Task: Test normal toggle operation
    task test_toggle_timing;
        input [255:0] test_description;
        input integer expected_cycles;
        input integer tolerance;
        integer measured_cycles;
        integer i;
        begin
            test_name = test_description;
            $display("\n--- %s ---", test_description);
            
            // Test multiple toggles to verify consistency
            for (i = 0; i < NUM_TOGGLES_TO_TEST; i = i + 1) begin
                wait_for_toggle(expected_cycles * 2, measured_cycles);
                
                $display("Toggle %d: %d cycles (expected: %d ±%d)", 
                        i+1, measured_cycles, expected_cycles, tolerance);
                
                // Check timing within tolerance
                if (measured_cycles < (expected_cycles - tolerance) || 
                    measured_cycles > (expected_cycles + tolerance)) begin
                    $display("FAIL: Toggle timing outside tolerance");
                    test_passed = 0;
                end else begin
                    $display("PASS: Toggle timing within tolerance");
                end
                
                // Record toggle for monitoring
                toggle_count = toggle_count + 1;
            end
        end
    endtask
    
    // Task: Test reset during operation
    task test_reset_during_operation;
        input [255:0] test_description;
        integer wait_cycles;
        begin
            test_name = test_description;
            $display("\n--- %s ---", test_description);
            
            // Wait for half a toggle period
            wait_cycles = TEST_CYCLES / 2;
            repeat(wait_cycles) @(posedge clk);
            
            $display("Applying reset during operation at cycle %d", wait_cycles);
            resetn = 0;
            @(posedge clk);
            @(posedge clk);
            
            // Verify immediate reset
            if (led_out !== 1'b0) begin
                $display("FAIL: LED not reset during operation (LED=%b)", led_out);
                test_passed = 0;
            end else begin
                $display("PASS: LED immediately reset during operation");
            end
            
            resetn = 1;
            @(posedge clk);
            
            reset_test_count = reset_test_count + 1;
        end
    endtask
    
    //=========================================================================
    // Main Test Sequence
    //=========================================================================
    
    initial begin
        // Initialize simulation
        $display("=============================================================================");
        $display("LED Blink Comprehensive Testbench with VCD Generation");
        $display("=============================================================================");
        $display("Simulation Parameters:");
        $display("  Clock Frequency: %0d MHz", CLOCK_FREQ / 1_000_000);
        $display("  Clock Period: %0d ns", CLOCK_PERIOD);
        $display("  Counter Max: %0d cycles", TEST_CYCLES);
        $display("  Expected Toggle Period: %0d cycles", TEST_CYCLES);
        $display("  Number of Toggles to Test: %0d", NUM_TOGGLES_TO_TEST);
        $display("=============================================================================\n");
        
        // Initialize variables
        cycle_count = 0;
        toggle_count = 0;
        reset_test_count = 0;
        all_tests_passed = 1;
        test_passed = 1;
        
        // Create output directory for VCD files
        // Note: $system not supported in all simulators, directory should be created manually
        
        //=====================================================================
        // Test 1: Basic Reset Functionality
        //=====================================================================
        test_reset("Test 1: Basic Reset Functionality", 10);
        if (!test_passed) all_tests_passed = 0;
        
        //=====================================================================
        // Test 2: Normal Toggle Operation
        //=====================================================================
        test_passed = 1;
        test_toggle_timing("Test 2: Normal Toggle Operation", TEST_CYCLES, 5);
        if (!test_passed) all_tests_passed = 0;
        
        //=====================================================================
        // Test 3: Reset During Operation
        //=====================================================================
        test_passed = 1;
        test_reset_during_operation("Test 3: Reset During Operation");
        if (!test_passed) all_tests_passed = 0;
        
        //=====================================================================
        // Test 4: Multiple Reset Cycles
        //=====================================================================
        test_passed = 1;
        test_reset("Test 4: Extended Reset (20 cycles)", 20);
        if (!test_passed) all_tests_passed = 0;
        
        //=====================================================================
        // Test 5: Final Toggle Verification
        //=====================================================================
        test_passed = 1;
        test_toggle_timing("Test 5: Post-Reset Toggle Verification", TEST_CYCLES, 5);
        if (!test_passed) all_tests_passed = 0;
        
        //=====================================================================
        // Test Summary and Results
        //=====================================================================
        $display("\n=============================================================================");
        $display("TEST SUMMARY");
        $display("=============================================================================");
        $display("Total Toggles Observed: %0d", toggle_count);
        $display("Reset Tests Performed: %0d", reset_test_count + 2); // +2 for basic tests
        $display("Simulation Time: %0t", $time);
        $display("Clock Cycles Simulated: %0d", cycle_count);
        
        if (all_tests_passed) begin
            $display("\n🎉 ALL TESTS PASSED! 🎉");
            $display("✓ Reset functionality verified");
            $display("✓ Toggle timing verified");
            $display("✓ Reset during operation verified");
            $display("✓ Multiple reset cycles verified");
        end else begin
            $display("\n❌ SOME TESTS FAILED!");
            $display("Check individual test results above");
        end
        
        $display("=============================================================================");
        
        if (vcd_enabled) begin
            $display("\nVCD waveform file generated: waveforms/led_blink_tb.vcd");
            $display("Use GTKWave or similar tool to view waveforms:");
            $display("  gtkwave waveforms/led_blink_tb.vcd");
        end
        
        $display("\nSimulation completed at %0t", $time);
        
        // Final result for automated testing
        if (all_tests_passed) begin
            $display("SIMULATION_RESULT: PASS");
        end else begin
            $display("SIMULATION_RESULT: FAIL");
        end
        
        $finish;
    end
    
    //=========================================================================
    // Monitoring and Statistics
    //=========================================================================
    
    // Clock cycle counter
    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
    end
    
    // LED change monitor
    reg led_prev;
    always @(posedge clk) begin
        led_prev <= led_out;
        if (led_out != led_prev && resetn) begin
            $display("[%0t] LED Toggle #%0d: %b -> %b (cycle %0d)", 
                    $time, toggle_count + 1, led_prev, led_out, cycle_count);
        end
    end
    
    // Timeout protection
    initial begin
        #(CLOCK_PERIOD * TEST_CYCLES * NUM_TOGGLES_TO_TEST * 10); // 10x safety margin
        $display("\nERROR: Simulation timeout!");
        $display("SIMULATION_RESULT: TIMEOUT");
        $finish;
    end

endmodule