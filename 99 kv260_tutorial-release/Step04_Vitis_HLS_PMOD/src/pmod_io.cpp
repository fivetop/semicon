#include <stdio.h>
#include <stdint.h>

typedef unsigned short int u16;

u16 pmod_io(u16 io_ctrl, u16 io_num, u16& pmod) {
    #pragma HLS INTERFACE ap_ctrl_none port=return
    #pragma HLS INTERFACE s_axilite port=io_ctrl
    #pragma HLS INTERFACE s_axilite port=io_num
    #pragma HLS INTERFACE s_axilite port=pmod
    static u16 pmod_mask = 0;
    
    if (io_ctrl == 0xf) {
        pmod_mask = 0;           // 초기화
    } else if (io_ctrl == 0xa) {
        pmod_mask = (1 << io_num);  // SET
    } else if (io_ctrl == 0x5) {
        pmod_mask = ~(1 << io_num); // CLEAR
    } else if (io_ctrl == 0x1) {
        pmod_mask = io_num;          // WRITE
    }
    
    pmod = pmod_mask;
    return pmod_mask;
}