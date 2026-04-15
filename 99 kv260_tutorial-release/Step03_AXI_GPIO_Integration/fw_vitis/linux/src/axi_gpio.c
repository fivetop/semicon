/* 
 * AXI GPIO LED Control Application (Vitis Linux Platform)
 * Linux sysfs interface - 교육용 단순화 버전
 */
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#define GPIO_PATH  "/sys/class/gpio"
#define GPIO_BASE  504

int main()
{
    int fd, led, repeat, i, value;
    char path[128];
    char buf[16];

    printf("KV260 AXI GPIO LED Test (Linux)\n");
    printf("===========================\n");

    /* GPIO pins을 userspace로 export */
    for (led = 0; led < 4; led++) {
        fd = open(GPIO_PATH "/export", O_WRONLY);
        snprintf(buf, 16, "%d", GPIO_BASE + led);
        write(fd, buf, strlen(buf));
        close(fd);
        usleep(50000);
    }

    /* GPIO를 output으로 설정하고 끄기 */
    for (led = 0; led < 4; led++) {
        snprintf(path, 128, GPIO_PATH "/gpio%d/direction", GPIO_BASE + led);
        fd = open(path, O_WRONLY);
        write(fd, "out", 3);
        close(fd);

        snprintf(path, 128, GPIO_PATH "/gpio%d/value", GPIO_BASE + led);
        fd = open(path, O_WRONLY);
        write(fd, "0", 1);
        close(fd);
    }

    printf("Starting LED blink pattern...\n");

    /* LED blinking: 10회 반복 */
    int patterns[] = {0x1, 0x2, 0x4, 0x8, 0xF, 0x0};
    
    for (repeat = 0; repeat < 10; repeat++) {
        for (i = 0; i < 6; i++) {
            value = patterns[i];
            
            for (led = 0; led < 4; led++) {
                snprintf(path, 128, GPIO_PATH "/gpio%d/value", GPIO_BASE + led);
                fd = open(path, O_WRONLY);
                write(fd, (value >> led) & 1 ? "1" : "0", 1);
                close(fd);
            }
            
            printf("LED Value: 0x%X\n", value);
            usleep(300000);
        }
    }

    /* 모든 LED 끄기 */
    for (led = 0; led < 4; led++) {
        snprintf(path, 128, GPIO_PATH "/gpio%d/value", GPIO_BASE + led);
        fd = open(path, O_WRONLY);
        write(fd, "0", 1);
        close(fd);
    }

    printf("LED Test Complete!\n");
    return 0;
}