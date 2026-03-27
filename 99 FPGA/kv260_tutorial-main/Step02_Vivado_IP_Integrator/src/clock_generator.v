// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51.
// SPDX-License-Identifier: SHL-0.51

`timescale 1ns / 1ps

// Engineer:  KV260 Training Team
// Description: Clock Generator Module - Generates multiple clock domains from input clock

module clock_generator #(
    parameter INPUT_CLK_PERIOD = 10_000,  // Input clock period in ps (100MHz = 10000ps)
    parameter CLKOUT0_DIVIDE = 1,         // 100MHz
    parameter CLKOUT1_DIVIDE = 2,         // 50MHz
    parameter CLKOUT2_DIVIDE = 4,         // 25MHz
    parameter CLKOUT3_DIVIDE = 8          // 12.5MHz
)(
    input  wire clk,            // Input clock (100MHz from PS)
    input  wire rstn,           // Active low reset
    input  wire locked,         // DCM locked signal
    
    output reg  clk_out0,       // 100MHz
    output reg  clk_out1,       // 50MHz
    output reg  clk_out2,       // 25MHz
    output reg  clk_out3        // 12.5MHz
);

    // Clock divider counters
    reg [31:0] counter0;
    reg [31:0] counter1;
    reg [31:0] counter2;
    reg [31:0] counter3;
    
    // Local parameters for divide values
    localparam DIV0 = CLKOUT0_DIVIDE;
    localparam DIV1 = CLKOUT1_DIVIDE;
    localparam DIV2 = CLKOUT2_DIVIDE;
    localparam DIV3 = CLKOUT3_DIVIDE;
    
    // Clock output generation - when DCM is locked
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            clk_out0 <= 1'b0;
            clk_out1 <= 1'b0;
            clk_out2 <= 1'b0;
            clk_out3 <= 1'b0;
            
            counter0 <= 32'd0;
            counter1 <= 32'd0;
            counter2 <= 32'd0;
            counter3 <= 32'd0;
        end else if (locked) begin
            // CLKOUT0 - 100MHz (toggle every half cycle)
            if (counter0 < (DIV0 / 2) - 1) begin
                counter0 <= counter0 + 1;
            end else begin
                counter0 <= 32'd0;
                clk_out0 <= ~clk_out0;
            end
            
            // CLKOUT1 - 50MHz (divide by 2)
            if (counter1 < (DIV1 / 2) - 1) begin
                counter1 <= counter1 + 1;
            end else begin
                counter1 <= 32'd0;
                clk_out1 <= ~clk_out1;
            end
            
            // CLKOUT2 - 25MHz (divide by 4)
            if (counter2 < (DIV2 / 2) - 1) begin
                counter2 <= counter2 + 1;
            end else begin
                counter2 <= 32'd0;
                clk_out2 <= ~clk_out2;
            end
            
            // CLKOUT3 - 12.5MHz (divide by 8)
            if (counter3 < (DIV3 / 2) - 1) begin
                counter3 <= counter3 + 1;
            end else begin
                counter3 <= 32'd0;
                clk_out3 <= ~clk_out3;
            end
        end else begin
            // Reset outputs when not locked
            clk_out0 <= 1'b0;
            clk_out1 <= 1'b0;
            clk_out2 <= 1'b0;
            clk_out3 <= 1'b0;
        end
    end

endmodule