// pmod_io.cpp
// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51

#include <stdio.h>
#include <stdint.h>

typedef unsigned short int u16;

// PMOD I/O 제어 함수
// io_ctrl: 제어 코드 (0xf=초기화, 0xa=SET, 0x5=CLEAR, 0x1=WRITE, 0x0=READ)
// io_num: 비트 번호 (0-7)
// pmod: PMOD 값 (참조로 반환)
u16 pmod_io(u16 io_ctrl, u16 io_num, u16& pmod) {
    #pragma HLS INTERFACE ap_ctrl_none port=return
    #pragma HLS INTERFACE s_axilite port=io_ctrl
    #pragma HLS INTERFACE s_axilite port=io_num
    #pragma HLS INTERFACE s_axilite port=pmod

    u16 pmod_mask = 0;
    
    if (io_ctrl == 0xf) {
        // 초기화: 모든 출력 0
        pmod_mask = 0;
        pmod = 0;
    } else if (io_ctrl == 0xa) {
        // SET: 해당 비트만 1로
        pmod_mask = (1 << io_num);
        pmod = pmod | pmod_mask;
    } else if (io_ctrl == 0x5) {
        // CLEAR: 해당 비트만 0으로
        pmod_mask = ~(1 << io_num);
        pmod = pmod & pmod_mask;
    } else if (io_ctrl == 0x1) {
        // WRITE: 직접 쓰기
        pmod_mask = io_num;
        pmod = pmod_mask;
    } else {
        // READ: 현재 값 유지
        pmod_mask = pmod;
    }
    
    return pmod_mask;
}
