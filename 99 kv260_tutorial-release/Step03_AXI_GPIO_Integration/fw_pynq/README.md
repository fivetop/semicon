# KV260 AXI GPIO PYNQ 예제 / KV260 AXI GPIO PYNQ Example

이 프로젝트는 KV260 보드에서 PYNQ를 사용하여 AXI GPIO를 제어하는 예제를 제공합니다.  
This project provides an example of controlling AXI GPIO using PYNQ on the KV260 board.

---

## 필요한 파일 / Required Files

PYNQ 보드에서 실행하려면 다음 파일들이 필요합니다:  
To run on the PYNQ board, the following files are needed:

1. **.bit 파일**: `out/result_files/kv260_axi_gpio.bit`
2. **HWH 파일**: `out/result_files/kv260_axi_gpio.hwh`
3. **Python 예제**: `fw_pynq/src/axi_gpio.py`

---

## KV260에서 실행하는 방법 / How to Run on KV260

### 1. 파일 전송 (PC에서 KV260로) / File Transfer (PC to KV260)

PC에서 KV260 보드로 필요한 파일들을 전송합니다:  
Transfer the required files from PC to KV260 board:

```bash
# KV260의 IP 주소를 확인하고 아래 주소를 변경하세요
# Change the IP address to your KV260's IP
KV260_IP="192.168.1.100"

# .bit 파일 전송 / Transfer .bit file
scp ./out/result_files/kv260_axi_gpio.bit ubuntu@${KV260_IP}:~/kv260_axi_gpio.bit

# .hwh 파일 전송 (PYNQ Overlay 정보) / Transfer .hwh file (PYNQ Overlay metadata)
scp ./out/result_files/kv260_axi_gpio.hwh ubuntu@${KV260_IP}:~/kv260_axi_gpio.hwh

# Python 예제 파일 전송 / Transfer Python example file
scp ./fw_pynq/src/axi_gpio.py ubuntu@${KV260_IP}:~/axi_gpio.py
```

### 2. KV260에서 Jupyter Notebook 실행 / Run Jupyter Notebook on KV260

1. KV260의 Jupyter Notebook에 접속합니다:  
   Access KV260's Jupyter Notebook:
   - 브라우저에서 `http://<KV260_IP>:9090` 열기  
   Open `http://<KV260_IP>:9090` in browser

2. 새 Notebook을 만들거나 기존 Notebook을 엽니다  
   Create a new Notebook or open an existing Notebook

3. 다음 코드를 실행합니다:  
   Run the following code:

```python
from pynq import Overlay
import time

# 1. Overlay 로드 / Load Overlay
overlay = Overlay('/home/ubuntu/kv260_axi_gpio.bit')

# 2. AXI GPIO 접근 / Access AXI GPIO
led_gpio = overlay.axi_gpio_0.channel1

# 3. LED 제어 / Control LED
led_gpio.write(1, 0xF)  # 모든 LED 켜기 (0xF = 1111) / Turn on all LEDs
time.sleep(1)
led_gpio.write(1, 0x0)  # 모든 LED 끄기 / Turn off all LEDs
time.sleep(1)

# 4. 개별 LED 제어 / Control individual LED
led_gpio.write(1, 0x1)  # LED0 만 켜기 / Turn on LED0 only
time.sleep(0.5)
led_gpio.write(1, 0x2)  # LED1 만 켜기 / Turn on LED1 only
time.sleep(0.5)
led_gpio.write(1, 0x4)  # LED2 만 켜기 / Turn on LED2 only
time.sleep(0.5)
led_gpio.write(1, 0x8)  # LED3 만 켜기 / Turn on LED3 only

# 5. LED 상태 읽기 / Read LED status
status = led_gpio.read()
print(f"LED Status: {status:04b}")
```

### 3. LED 연결 / Connect LED

KV260 보드의 PMOD 또는 Raspberry Pi 커넥터에 LED를 연결합니다:  
Connect LEDs to KV260 board's PMOD or Raspberry Pi connector:

- **AXI GPIO 4-bit 출력**: 4개의 LED를 개별적으로 제어 가능  
- **AXI GPIO 4-bit output**: Can control 4 LEDs individually

---

## 파일 설명 / File Description

| 파일 / File | 설명 / Description |
|-------------|-------------------|
| `kv260_axi_gpio.bit` | FPGA 비트스트림 (하드웨어 디자인) / FPGA bitstream (hardware design) |
| `kv260_axi_gpio.hwh` | 하드웨어 힌들러 (PYNQ Overlay 메타데이터) / Hardware handler (PYNQ Overlay metadata) |
| `kv260_axi_gpio.xsa` | Xilinx 하드웨어 설명 파일 (Vivado 내보내기) / Xilinx hardware description file (Vivado export) |
| `axi_gpio.py` | PYNQ Python 예제 코드 / PYNQ Python example code |

---

## 참고사항 / Notes

- KV260의 기본 IP 주소 / Default KV260 IP: `192.168.1.100`
- 기본 사용자 / Default user: `xilinx`, 비밀번호 / password: `xilinx`
- PYNQ Jupyter Notebook 접근 포트 / PYNQ Jupyter Notebook port: `9090`

---

## 문제 해결 / Troubleshooting

### Overlay 로드 오류가 발생하면 / If Overlay load error occurs
- .bit와 .hwh 파일이 같은 디렉토리에 있는지 확인  
  Check if .bit and .hwh files are in the same directory
- 파일 권한 확인: `ls -la /home/xilinx/`  
  Check file permissions: `ls -la /home/xilinx/`

### GPIO 접근 오류가 발생하면 / If GPIO access error occurs
- IP가 제대로 연결되었는지 확인  
  Check if IP is properly connected
- Block Design에서 GPIO 설정 확인  
  Check GPIO settings in Block Design

---

자세한 내용은 [PYNQ 공식 문서](https://pynq.readthedocs.io/)를 참고하세요.  
For more details, refer to [PYNQ Official Documentation](https://pynq.readthedocs.io/).