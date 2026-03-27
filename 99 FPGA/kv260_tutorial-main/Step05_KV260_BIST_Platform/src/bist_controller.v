// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51.
// SPDX-License-Identifier: SHL-0.51

// Engineer:  KV260 Training Team
// Description: BIST (Built-In Self-Test) Controller for KV260 Platform

module bist_controller #(
    parameter CLK_FREQ_MHZ = 100
)(
    input  wire        clk,            // 100MHz system clock
    input  wire        rstn,           // Active low reset
    
    // Start/Status
    input  wire        start_bist,     // Start BIST
    output reg         bist_done,      // BIST complete
    output reg  [7:0]  bist_status,    // BIST status code
    
    // Memory Test Interface
    output wire [31:0] mem_addr,       // Memory address
    output wire        mem_we,         // Memory write enable
    output wire [31:0] mem_wdata,      // Memory write data
    input  wire [31:0] mem_rdata,      // Memory read data
    
    // GPIO for LEDs
    output wire [3:0]  status_led      // Status LEDs
);

    // BIST States
    typedef enum logic [2:0] {
        BIST_IDLE       = 3'b000,
        BIST_ADDR_TEST  = 3'b001,
        BIST_WRITE_TEST = 3'b010,
        BIST_READ_TEST = 3'b011,
        BIST_PATTERN    = 3'b100,
        BIST_COMPLETE   = 3'b101,
        BIST_FAIL       = 3'b110
    } bist_state_t;
    
    bist_state_t state, next_state;
    
    // Test counters
    reg [15:0] test_count;
    reg [31:0] test_addr;
    reg [31:0] test_data;
    reg [31:0] expected_data;
    reg        test_error;
    
    // State machine
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= BIST_IDLE;
            test_count <= 16'd0;
            test_addr <= 32'd0;
            test_data <= 32'd0;
            expected_data <= 32'd0;
            test_error <= 1'b0;
            bist_done <= 1'b0;
            bist_status <= 8'h00;
        end else begin
            state <= next_state;
            
            case (state)
                BIST_IDLE: begin
                    bist_done <= 1'b0;
                    bist_status <= 8'h01;
                    if (start_bist) begin
                        test_count <= 16'd0;
                        test_addr <= 32'h00000000;
                        test_error <= 1'b0;
                    end
                end
                
                BIST_ADDR_TEST: begin
                    bist_status <= 8'h02;
                    if (test_count < 16'd256) begin
                        test_addr <= {20'd0, test_count[7:0], 4'd0};
                        test_count <= test_count + 1;
                    end else begin
                        test_count <= 16'd0;
                    end
                end
                
                BIST_WRITE_TEST: begin
                    bist_status <= 8'h04;
                    test_data <= test_addr ^ 32'hAAAAAAAA;
                    test_count <= test_count + 1;
                end
                
                BIST_READ_TEST: begin
                    bist_status <= 8'h08;
                    expected_data <= test_addr ^ 32'hAAAAAAAA;
                    if (mem_rdata != expected_data) begin
                        test_error <= 1'b1;
                    end
                    test_count <= test_count + 1;
                end
                
                BIST_PATTERN: begin
                    bist_status <= 8'h10;
                    // Walking 1s pattern
                    test_data <= 32'h00000001 << test_count[4:0];
                    test_count <= test_count + 1;
                end
                
                BIST_COMPLETE: begin
                    bist_status <= 8'h80;
                    bist_done <= 1'b1;
                end
                
                BIST_FAIL: begin
                    bist_status <= 8'hFF;
                    bist_done <= 1'b1;
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            BIST_IDLE: begin
                if (start_bist) next_state = BIST_ADDR_TEST;
            end
            
            BIST_ADDR_TEST: begin
                if (test_count >= 16'd256) next_state = BIST_WRITE_TEST;
            end
            
            BIST_WRITE_TEST: begin
                if (test_count >= 16'd1024) next_state = BIST_READ_TEST;
            end
            
            BIST_READ_TEST: begin
                if (test_count >= 16'd1024) begin
                    if (test_error) next_state = BIST_FAIL;
                    else next_state = BIST_PATTERN;
                end
            end
            
            BIST_PATTERN: begin
                if (test_count >= 16'd32) begin
                    if (test_error) next_state = BIST_FAIL;
                    else next_state = BIST_COMPLETE;
                end
            end
            
            BIST_COMPLETE, BIST_FAIL: begin
                if (!start_bist) next_state = BIST_IDLE;
            end
            
            default: next_state = BIST_IDLE;
        endcase
    end
    
    // Memory interface outputs
    assign mem_addr = test_addr;
    assign mem_we = (state == BIST_WRITE_TEST) || (state == BIST_PATTERN);
    assign mem_wdata = test_data;
    
    // Status LEDs
    assign status_led[0] = bist_done;
    assign status_led[1] = test_error;
    assign status_led[2] = (state == BIST_WRITE_TEST) || (state == BIST_READ_TEST);
    assign status_led[3] = clk;

endmodule