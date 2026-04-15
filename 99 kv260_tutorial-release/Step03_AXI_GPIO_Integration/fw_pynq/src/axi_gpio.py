from pynq import Overlay
import time

# 1. Overlay 로드
overlay = Overlay('/home/xilinx/kv260_axi_gpio.bit')

# 2. AXI GPIO 접근
led_gpio = overlay.axi_gpio_0.channel1

# 3. LED 제어
led_gpio.write(1, 0xF)  # 모든 LED 켜기 (0xF = 1111)
time.sleep(1)
led_gpio.write(1, 0x0)  # 모든 LED 끄기
time.sleep(1)

# 4. 개별 LED 제어
led_gpio.write(1, 0x1)  # LED0 만 켜기
time.sleep(0.5)
led_gpio.write(1, 0x2)  # LED1 만 켜기
time.sleep(0.5)
led_gpio.write(1, 0x4)  # LED2 만 켜기
time.sleep(0.5)
led_gpio.write(1, 0x8)  # LED3 만 켜기

# 5. LED 상태 읽기
status = led_gpio.read()
print(f"LED Status: {status:04b}")