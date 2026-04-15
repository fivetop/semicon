`timescale 1ns / 1ps

// LED Blink Module for KV260
// Toggles LED every 50M clock cycles (0.5s at 100MHz = 1Hz blink rate)

module led_blink #(
    parameter COUNTER_MAX = 27'd50_000_000  // Default for 1Hz at 100MHz
) (
    input  wire clk,        // 100MHz clock from PS pl_clk0
    input  wire resetn,     // Active-low reset from PS pl_resetn0
    output reg  led_out     // LED output to PMOD1 Pin 1 (H12)
);

    // Counter parameters
    // 27-bit counter: 2^27 = 134,217,728 > 100,000,000
    // Toggle after 50,000,000 cycles (0.5 seconds at 100MHz)
    
    // Internal counter
    reg [26:0] counter;
    
    // Synchronous reset and counter logic
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            // Reset state: clear counter and turn off LED
            counter <= 27'd0;
            led_out <= 1'b0;
        end else begin
            if (counter >= COUNTER_MAX - 1) begin
                // Counter reached half-period, toggle LED
                counter <= 27'd0;
                led_out <= ~led_out;
            end else begin
                // Increment counter
                counter <= counter + 27'd1;
            end
        end
    end
    
endmodule
