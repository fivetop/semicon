/**
 * KV260 AXI GPIO LED Test (Standalone/Bare-metal)
 * 
 * This program runs on KV260 without Linux - direct hardware access via Xilinx BSP.
 * Debugging via JTAG + OpenOCD + GDB.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "xil_io.h"
#include "sleep.h"
#include "xparameters.h"

/* AXI GPIO Base Address from xparameters.h */
/* GPIO_0: 0xA0000000 (AXI GPIO for PL LEDs) */
/* GPIO_1: 0xA0001000 (AXI GPIO for Buttons/Switches) */

#define AXI_GPIO_0_BASE   XPAR_AXI_GPIO_RTL_0_BASEADDR
#define AXI_GPIO_1_BASE   XPAR_AXI_GPIO_1_BASEADDR

#define GPIO_DATA_OFFSET  0x00
#define GPIO_TRI_OFFSET   0x04

/* Utility function to print hex value */
static void printHex(unsigned int value)
{
    char buffer[9];
    int i;
    for (i = 7; i >= 0; i--) {
        buffer[i] = "0123456789ABCDEF"[value & 0xF];
        value >>= 4;
    }
    buffer[8] = '\0';
    print(buffer);
}

/* Read AXI GPIO register */
static unsigned int gpioRead(u32 base, u32 offset)
{
    return Xil_In32(base + offset);
}

/* Write AXI GPIO register */
static void gpioWrite(u32 base, u32 offset, u32 value)
{
    Xil_Out32(base + offset, value);
}

/* Set GPIO direction: 0 = output, 1 = input */
static void gpioSetDirection(u32 base, u32 direction)
{
    gpioWrite(base, GPIO_TRI_OFFSET, direction);
}

int main(void)
{
    unsigned int data_val, tri_val;
    
    print("===========================================\r\n");
    print("KV260 AXI GPIO LED Test (Standalone)\r\n");
    print("===========================================\r\n\r\n");
    
    /* Read current GPIO registers */
    data_val = gpioRead(AXI_GPIO_0_BASE, GPIO_DATA_OFFSET);
    tri_val  = gpioRead(AXI_GPIO_0_BASE, GPIO_TRI_OFFSET);
    
    print("AXI GPIO_0 Base: 0x");
    printHex(AXI_GPIO_0_BASE);
    print("\r\n");
    print("Current DATA: 0x");
    printHex(data_val);
    print("\r\n");
    print("Current TRI:  0x");
    printHex(tri_val);
    print("\r\n\r\n");
    
    /* Set GPIO direction: all outputs */
    gpioSetDirection(AXI_GPIO_0_BASE, 0x00000000);
    
    tri_val = gpioRead(AXI_GPIO_0_BASE, GPIO_TRI_OFFSET);
    print("Set GPIO direction: All output (0x00000000)\r\n");
    print("TRI after config: 0x");
    printHex(tri_val);
    print("\r\n\r\n");
    
    /* LED test pattern */
    print("Running LED test pattern...\r\n");
    print("LED pattern: 0x1 -> 0x3 -> 0x7 -> 0xF -> 0x0 (loop)\r\n\r\n");
    
    while (1) {
        /* Pattern 1: LED0 only */
        gpioWrite(AXI_GPIO_0_BASE, GPIO_DATA_OFFSET, 0x1);
        print("LED: 0x1 (DS1 ON)\r\n");
        sleep(1);
        
        /* Pattern 2: LED0 + LED1 */
        gpioWrite(AXI_GPIO_0_BASE, GPIO_DATA_OFFSET, 0x3);
        print("LED: 0x3 (DS1+DS2 ON)\r\n");
        sleep(1);
        
        /* Pattern 3: LED0 + LED1 + LED2 */
        gpioWrite(AXI_GPIO_0_BASE, GPIO_DATA_OFFSET, 0x7);
        print("LED: 0x7 (DS1+DS2+DS3 ON)\r\n");
        sleep(1);
        
        /* Pattern 4: All LEDs */
        gpioWrite(AXI_GPIO_0_BASE, GPIO_DATA_OFFSET, 0xF);
        print("LED: 0xF (ALL ON)\r\n");
        sleep(1);
        
        /* Pattern 5: All off */
        gpioWrite(AXI_GPIO_0_BASE, GPIO_DATA_OFFSET, 0x0);
        print("LED: 0x0 (ALL OFF)\r\n");
        sleep(1);
    }
    
    return 0;
}
