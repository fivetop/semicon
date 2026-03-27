// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51

`timescale 1ns / 1ps

module top_module #(
    parameter REF_CLK = 100_000_000
)(
    input  wire sysclk,
    input  wire cpu_resetn,
    output wire led_o
);

    // LED Blinker 인스턴스
    led_blinker #(
        .REF_CLK(REF_CLK)
    ) u_blinker (
        .sysclk(sysclk),
        .o_led(led_o)
    );

endmodule : top_module
