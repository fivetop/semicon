// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51

`timescale 1ns / 1ps

module led_blinker #(
    parameter REF_CLK = 100_000_000  // 기본 100MHz 클락 설정
)(
    input  wire sysclk,
    output reg  o_led = 1'b0
);
    // 클락 카운트를 위한 레지스터
    integer r_count = 0;

    always @(posedge sysclk) begin
        if (r_count < (REF_CLK / 2 - 1)) begin
            r_count <= r_count + 1;
        end else begin
            r_count <= 0;
            o_led <= ~o_led; // 상태 반전 (Toggling)
        end
    end
endmodule : led_blinker
