// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51

`timescale 1ns / 1ps

module led_on (
    input  wire clk,
    output wire led
);
    // LED를 항상 High(1) 상태로 유지
    assign led = 1'b1;
endmodule : led_on
