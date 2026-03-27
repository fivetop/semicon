// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51.
// SPDX-License-Identifier: SHL-0.51

`timescale 1ns / 1ps

// Engineer:  KV260 Training Team
// Description: Reset Controller Module - Manages reset sequencing for PL logic

module reset_controller #(
    parameter RESET_CYCLES = 100  // Number of cycles to hold reset
)(
    input  wire clk,              // System clock
    input  wire ext_rstn,         // External reset (from PS)
    input  wire dcm_locked,        // DCM locked signal
    
    output reg  pl_resetn,        // PL logic reset (active low)
    output reg  peripheral_rstn   // Peripheral reset (active low)
);

    // State definitions
    localparam [1:0] RESET_IDLE    = 2'b00;
    localparam [1:0] RESET_HOLD    = 2'b01;
    localparam [1:0] RESET_RELEASE = 2'b10;
    localparam [1:0] RESET_ACTIVE  = 2'b11;
    
    reg [1:0] state;
    reg [1:0] next_state;
    
    // Counter for hold duration
    reg [31:0] hold_counter;
    
    // State transition logic
    always @(posedge clk or negedge ext_rstn) begin
        if (!ext_rstn) begin
            state <= RESET_IDLE;
            hold_counter <= 32'd0;
        end else begin
            state <= next_state;
            
            if (state == RESET_HOLD) begin
                if (hold_counter < RESET_CYCLES) begin
                    hold_counter <= hold_counter + 1;
                end else begin
                    hold_counter <= 32'd0;
                end
            end
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            RESET_IDLE: begin
                if (ext_rstn && dcm_locked) begin
                    next_state = RESET_HOLD;
                end
            end
            
            RESET_HOLD: begin
                if (hold_counter >= RESET_CYCLES) begin
                    next_state = RESET_RELEASE;
                end
            end
            
            RESET_RELEASE: begin
                next_state = RESET_ACTIVE;
            end
            
            RESET_ACTIVE: begin
                if (!ext_rstn || !dcm_locked) begin
                    next_state = RESET_IDLE;
                end
            end
            
            default: next_state = RESET_IDLE;
        endcase
    end
    
    // Output generation
    always @(posedge clk or negedge ext_rstn) begin
        if (!ext_rstn) begin
            pl_resetn <= 1'b0;
            peripheral_rstn <= 1'b0;
        end else begin
            case (state)
                RESET_IDLE: begin
                    pl_resetn <= 1'b0;
                    peripheral_rstn <= 1'b0;
                end
                
                RESET_HOLD: begin
                    pl_resetn <= 1'b0;
                    peripheral_rstn <= 1'b0;
                end
                
                RESET_RELEASE: begin
                    pl_resetn <= 1'b1;
                    peripheral_rstn <= 1'b0;
                end
                
                RESET_ACTIVE: begin
                    pl_resetn <= 1'b1;
                    peripheral_rstn <= 1'b1;
                end
                
                default: begin
                    pl_resetn <= 1'b0;
                    peripheral_rstn <= 1'b0;
                end
            endcase
        end
    end

endmodule
