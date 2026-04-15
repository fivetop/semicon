# KV260 Vivado 교육 튜토리얼 #3 - AXI GPIO Integration

본 튜토리얼은 AXI GPIO IP를 사용하여 PS(Processing System)와 PL(Programmable Logic) 간 통신을 구현합니다. KV260 보드의 LED를 AXI GPIO로 제어하는 실습을 진행합니다.

---

## Copyright

Copyright 2017 ETH Zurich and University of Bologna.
Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51.

---

## Section 1:概述

### 1.1 AXI GPIO IP란?
AXI GPIO는 AXI 버스를 통해 GPIO(General Purpose Input/Output)를 제어하는 IP입니다.

**특징:**
- AXI4-Lite 인터페이스 지원
- 1-bit ~ 32-bit GPIO 지원
- 이중 채널 (Channel 1, Channel 2)
- 인터럽트 지원 (선택)

### 1.2 PS-PL 통신의 실용 예제
```
PS (ARM 프로세서)  ----AXI 버스---->  GPIO  ---->  LED/Switch
                                              (PL)
```

PS에서 GPIO 레지스터를 쓰면 PL의 핀 상태가 변경됩니다.

---

## Section 2: 시스템 아키텍처

### 2.1 하드웨어 블록 다이어그램
```
+------------------------------------------+
|              Zynq UltraScale+            |
|  +-----------+    +------------------+   |
|  |    PS     |<-->|    AXI GPIO      |   |
|  |  (ARM)    |    |  (AXI4-Lite)    |   |
|  +-----------+    +------------------+   |
|       |                  |               |
|  pl_clk0            led_gpio           LED (PL)
|  pl_resetn          switch_gpio        Switch (PL)
+------------------------------------------+
```

### 2.2 소프트웨어 아키텍처
```
+-------------------+
|   Python/PYNQ    |
+-------------------+
|   overlay.       |
|   axi_gpio_0     |
|   .channel1     |
+-------------------+
```

---

## Section 3: Vivado 프로젝트 생성

### 3.1 프로젝트 설정
```bash
source /tools/Xilinx/Vivado/2021.2/settings64.sh
vivado &
```

1. **Create Project**: RTL Project
2. **Project Name**: `kv260_axi_gpio`
3. **Board**: Kria KV260 Vision AI Starter Kit

### 3.2 보드 선택 (KR260)
*참고: KR260도 동일한 절차를 사용합니다.*

---

## Section 4: 블록 디자인 설계

### 4.1 Zynq PS 추가 및 구성
1. IP Integrator → Create Block Design
2. '+' 버튼 → `Zynq UltraScale+ MPSoC` 추가
3. **Run Block Automation** → KV260 Preset 적용

### 4.2 M_AXI_HPM0_LPD 활성화
PS 구성에서 LPD(Low Power Domain)의 AXI 포트를 활성화합니다:

```tcl
# TCL로 설정
set_property -dict [list \
    CONFIG.PSU__AXI__HPM0_LPD__ENABLE {1} \
] [get_bd_cells zynq_ultra_ps_e_0]
```

### 4.3 PL_CLK0, PL_RESETN0 설정
KV260 Preset이 자동으로 설정합니다. 확인:
- pl_clk0: 100MHz
- pl_resetn0: Active Low

### 4.4 AXI GPIO IP 추가
1. BD에서 '+' 버튼
2. `axi_gpio` 검색
3. 추가:

| 설정 | 값 |
|------|-----|
| GPIO Width | 4 (4-bit) |
| All Inputs | 선택안함 (Output) |
| All Outputs | 선택 |
| Enable Dual Channel | 체크안함 |

### 4.5 AXI SmartConnect
Vivado가 자동으로 AXI 연결을 설정합니다:

**Run Connection Automation** 사용:
- `axi_gpio_0`의 S_AXI 포트 선택
- `Auto` 연결 선택

---

## Section 5: GPIO 포트 구성

### 5.1 Make External 명령
AXI GPIO의 GPIO 포트를 외부로 노출합니다:

1. `axi_gpio_0`의 `gpio` 포트 우클릭
2. **Make External** 선택
3. 포트 이름: `led_gpio`

### 5.2 포트 이름 설정
우클릭 → **Rename Port**:
- `gpio` → `led_gpio`

---

## Section 6: 핀 제약조건

### 6.1 KR260 LED 핀맵
| LED | Package Pin | 설명 |
|-----|-------------|------|
| LED0 (DS8) | E8 | 첫 번째 LED |
| LED1 (DS7) | F8 | 두 번째 LED |

### 6.2 XDC 파일 작성
```tcl
# KR260 LED0 (DS8) - Pin E8
set_property PACKAGE_PIN E8 [get_ports {led_gpio_tri_o[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_gpio_tri_o[0]}]

# KR260 LED1 (DS7) - Pin F8
set_property PACKAGE_PIN F8 [get_ports {led_gpio_tri_o[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_gpio_tri_o[1]}]
```

### 6.3 KV260의 경우
KV260에서는 PL User LED를 사용:

```tcl
# KV260 PL User LED
set_property PACKAGE_PIN T14 [get_ports {led_gpio_tri_o[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_gpio_tri_o[0]}]
set_property PACKAGE_PIN U14 [get_ports {led_gpio_tri_o[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_gpio_tri_o[1]}]
set_property PACKAGE_PIN V14 [get_ports {led_gpio_tri_o[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_gpio_tri_o[2]}]
set_property PACKAGE_PIN V13 [get_ports {led_gpio_tri_o[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_gpio_tri_o[3]}]
```

---

## Section 7: 컴파일 및 검증

### 7.1 Synthesis → Implementation → Bitstream
```bash
# TCL로 실행
source scripts/run_all.tcl
```

### 7.2 리소스 사용량 확인
Synthesis 후 **Synthesis Report** 확인:

| Resource | 사용량 | 비율 |
|----------|--------|------|
| LUT | ~100 | <1% |
| FF | ~50 | <1% |
| BRAM | 0 | 0% |
| DSP | 0 | 0% |

---

## Section 8: 하드웨어 익스포트

### 8.1 XSA 파일 생성
```
File → Export → Export Hardware
→ Platform Type: Fixed
→ Include bitstream: 체크
→ XSA 파일 저장
```

### 8.2 NFS로 파일 전송
```bash
scp kv260_axi_gpio.xsa xilinx@192.168.1.100:~/.
```

---

## Section 9: PYNQ/Jupyter에서 제어

### 9.1 Python Overlay 로드
```python
from pynq import Overlay

# FPGA에 Overlay 로드
overlay = Overlay("kv260_axi_gpio.bit")

# AXI GPIO 접근
led_gpio = overlay.axi_gpio_0.channel1
```

### 9.2 LED 패턴 제어
```python
import time

# 개별 LED 제어
led_gpio.write(0, 0x1)  # LED0 만 켜기
led_gpio.write(0, 0x2)  # LED1 만 켜기
led_gpio.write(0, 0x3)  # LED0, LED1 켜기
led_gpio.write(0, 0x0)  # LED 끄기

# Walking pattern
patterns = [0x1, 0x2, 0x3, 0x2]
for p in patterns:
    led_gpio.write(p, 0xF)  # 0xF = 모든 비트 업데이트
    time.sleep(0.5)
```

### 9.3 LED 읽기
```python
# 현재 LED 상태 읽기
status = led_gpio.read()
print(f"LED Status: {status:04b}")
```

---

## Section 10: 심화 주제

### 10.1 인터럽트 지원 추가
AXI GPIO에 인터럽트를 연결하면 버튼 입력 시 PS에 알림:

1. AXI GPIO에서 `ip2intc_irpt` 포트 활성화
2. Concat IP 추가
3. PS의 IRQ에 연결

### 10.2 RPU (Real-Time Unit) 통합
Cortex-R5 실시간 유닛을 사용하여 낮은 지연 시간 구현

### 10.3 FreeRTOS 연동
FreeRTOS에서 AXI GPIO를 제어하는 예제:

```c
#include "xparameters.h"
#include "xgpio.h"

XGpio led_gpio;

int main() {
    XGpio_Initialize(&led_gpio, XPAR_AXI_GPIO_0_DEVICE_ID);
    XGpio_SetDataDirection(&led_gpio, 1, 0x0);  // Output

    while(1) {
        XGpio_DiscreteWrite(&led_gpio, 1, 0x1);
        vTaskDelay(pdMS_TO_TICKS(500));
        XGpio_DiscreteWrite(&led_gpio, 1, 0x0);
        vTaskDelay(pdMS_TO_TICKS(500));
    }
}
```

---

## Section 11: 검증 체크리스트

- [ ] AXI GPIO IP가 Block Design에 추가됨
- [ ] GPIO 포트가 Make External됨
- [ ] XDC 파일에 핀 할당 완료
- [ ] Synthesis 및 Implementation 성공
- [ ] Bitstream 생성 완료
- [ ] PYNQ에서 Overlay 로드 성공
- [ ] LED 제어 성공

---

## Section 12: Troubleshooting

### 12.1 AXI 버스 연결 오류
**증상**: `ERROR: [BD 41-249] Net already has a source port`

**해결**: 이미 연결된 포트를 다시 연결하지 마세요.

### 12.2 GPIO 레지스터 접근 실패
**증상**: Python에서 `OSError: [Errno 5] Input/output error`

**해결**:
1. Bitstream이 제대로 로드되었는지 확인
2. XSA와 .bit 파일이 일치하는지 확인

### 12.3 LED가 켜지지 않음
**증상**: Python으로 쓰기してもLED가 동작안함

**해결**:
1. XDC 핀 번호가 올바른지 확인
2. IOSTANDARD가 보드와 일치하는지 확인

---

본 튜토리얼을 통해 AXI GPIO를 사용한 PS-PL 통신을 학습했습니다. 다음 단계에서는 Vitis HLS를 사용하여 C/C++에서 커스텀 IP를 생성하는 방법을 학습합니다.
