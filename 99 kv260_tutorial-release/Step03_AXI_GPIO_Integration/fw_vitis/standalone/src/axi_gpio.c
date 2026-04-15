/* 
 * GPIO LED Control Application 
 * AXI GPIO를 사용하여 KV260 LED 제어
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "xparameters.h"
#include "xgpio.h"

// 장치 ID (Vivado에서 자동 생성됨)
#define GPIO_DEVICE_ID  XPAR_AXI_GPIO_0_DEVICE_ID
#define LED_CHANNEL     1

int main() {    
    XGpio gpio;    
    int status;    
    int led_value = 0;    
    printf("KV260 AXI GPIO LED Test\n");
    printf("========================\n");
        
    // GPIO 초기화    
    status = XGpio_Initialize(&gpio, GPIO_DEVICE_ID);   
    if (status != XST_SUCCESS) {        
        printf("XGpio_Initialize failed!\n");        
        return XST_FAILURE;   
    }    

    // 채널 1을 출력으로 설정 (0 = 출력)
    XGpio_SetDataDirection(&gpio, LED_CHANNEL, 0x0);
    printf("Starting LED blink pattern...\n");    

    // LED 패턴 시퀀스    
    int patterns[] = {0x1, 0x2, 0x4, 0x8, 0xF, 0x0};    
    int pattern_count = sizeof(patterns) / sizeof(patterns[0]);    

    // 10번 반복    
    for (int repeat = 0; repeat < 10; repeat++) {        
        for (int i = 0; i < pattern_count; i++) {            
            led_value = patterns[i];            
            XGpio_DiscreteWrite(&gpio, LED_CHANNEL, led_value);
            printf("LED Value: 0x%X\n", led_value);            
            usleep(300000);  // 300ms 대기        
        }
    }    

    // 모든 LED 끄기    
    XGpio_DiscreteWrite(&gpio, LED_CHANNEL, 0x0);    
    printf("LED Test Complete!\n");    
    return 0;
}
