# KV260 AXI GPIO Vitis/Standalone 예제

이 프로젝트는 Xilinx Vitis 2025.2를 사용하여 KV260 보드에서 Standalone(Bare-metal) 기반으로 AXI GPIO LED 애플리케이션을 구축하고 실행하는 예제를 제공합니다.

## 사전 준비사항

- Vitis 2025.2 설치됨
- XSA 파일: `/home/woody/SoGang/2026-03/kv260_vivado_tutorial/Step03_AXI_GPIO_Integration/out/result_files/kv260_axi_gpio.xsa`
- KV260 보드

---

## Step 0: Vitis 워크스페이스 생성

Vitis를 처음 실행할 때 워크스페이스를 생성합니다.

### 0.1 Vitis 실행

```bash
vitis &
```

### 0.2 워크스페이스 선택

1. Vitis IDE가 실행되면 Browse 버튼 클릭
2. 워크스페이스 폴더 생성 및 선택:
   ```
   /home/woody/SoGang/2026-03/kv260_vivado_tutorial/Step03_AXI_GPIO_Integration/fw_vitis/standalone
   ```
3. Launch 버튼 클릭

이제 Vitis IDE가 열립니다.

---

## Step 1: Standalone Platform 생성

Vitis에서 Standalone Platform을 생성하는 방법입니다.

### 1.1 Platform Project 생성

1. **File → New Component → Platform**
2. Component Name: `kv260_platform` 입력 → **Next**

### 1.2 Hardware Design 선택

1. Select Hardware Design (XSA): 찾아보기 버튼 클릭
2. XSA 파일 선택:
   ```
   /home/woody/SoGang/2026-03/kv260_vivado_tutorial/Step03_AXI_GPIO_Integration/out/result_files/kv260_axi_gpio.xsa
   ```
3. **Next**

### 1.3 Operating System 및 Processor 선택

1. Operating system: **standalone** 선택 (드롭다운 메뉴)
2. Processor: **psu_cortexa53** 선택
3. 설정 확인:
   - ☑ Generate Boot Artifacts
4. **Next** → **Finish**

### 1.4 Platform 빌드

Platform이 생성되면 Automatically build가 시작됩니다.

빌드가 완료될 때까지 기다립니다.

### 1.5 Platform 빌드 확인

Platform 빌드가 완료되면 다음 파일이 생성됩니다:
```
kv260_platform/export/kv260_platform/kv260_platform.xpfm
```

---

## Step 2: Application Project 생성

AXI GPIO LED 제어를 위한 Application Project를 생성합니다.

### 2.1 Application Project 생성

1. **File → New Component → Application**
2. Component Name: `app_axi_gpio` 입력 → **Next**

### 2.2 Platform 선택

1. Select Platform에서 방금 생성한 `kv260_platform` 선택
2. **Next**

### 2.3 Domain 선택

1. System project: `Standalone on psu_cortexa53` 선택
2. **Next**

### 2.4 Template 선택

1. Template: `Empty Application` 또는 `Standalone Empty Application` 선택
2. **Finish**

### 2.5 소스 코드 추가

1. 생성된 프로젝트의 `src` 폴더 우클릭 → **Add Files**
2. 소스 파일 선택:
   ```
   /home/woody/SoGang/2026-03/kv260_vivado_tutorial/Step03_AXI_GPIO_Integration/fw_vitis/standalone/src/axi_gpio.c
   ```

**중요: default로 생성된 helloworld.c 제거**
1. `src` 폴더의 `helloworld.c` 파일 선택
2. 우클릭 → **Delete**
3. Confirm 클릭
- 이 파일을 그대로 두면 "multiple definition of `main`" 에러 발생

또는 bash로 복사:
```bash
cp /home/woody/SoGang/2026-03/kv260_vivado_tutorial/Step03_AXI_GPIO_Integration/fw_vitis/standalone/src/axi_gpio.c \
   <app_dir>/src/
```

### 2.6 빌드

1. 프로젝트(app_axi_gpio) 우클릭 → **Build Project**
2. 또는 단축키 `Ctrl+B`

빌드가 완료되면 다음 파일이 생성됩니다:
```
app_axi_gpio/Binary/app_axi_gpio.elf
```

---

## KV260에서 실행

빌드된 ELF 파일을 KV260로 전송하고 실행합니다.

### 3.1 파일 전송

```bash
# KV260의 IP 주소를 확인하고 변경
KV260_IP="192.168.1.100"

scp <app_dir>/app_axi_gpio/Binary/app_axi_gpio.elf xilinx@${KV260_IP}:/home/xilinx/
```

### 3.2 SSH로 접속 및 실행

```bash
ssh xilinx@${KV260_IP}

chmod +x app_axi_gpio.elf
sudo ./app_axi_gpio.elf
```

### 3.3 출력

```
KV260 AXI GPIO LED Test
========================
Starting LED blink pattern...
LED Value: 0x1
LED Value: 0x2
LED Value: 0x4
LED Value: 0x8
LED Value: 0xF
LED Value: 0x0
...
LED Test Complete!
```

---

## 구조 설명

### Standalone GPIO 접근

Standalone(Bare-metal) 환경에서는 Xilinx의 드라이버 라이브러리를 사용합니다:

```c
#include "xparameters.h"
#include "xgpio.h"

// GPIO 초기화
XGpio_Initialize(&gpio, GPIO_DEVICE_ID);

// 출력 설정
XGpio_SetDataDirection(&gpio, LED_CHANNEL, 0x0);

// LED 제어
XGpio_DiscreteWrite(&gpio, LED_CHANNEL, led_value);
```

주요 함수:
- `XGpio_Initialize()`: GPIO 드라이버 초기화
- `XGpio_SetDataDirection()`: 채널 방향 설정 (0 = 출력)
- `XGpio_DiscreteWrite()`: GPIO에 값 쓰기
- `XGpio_DiscreteRead()`: GPIO에서 값 읽기

---

## 문제 해결

### ELF 실행 오류
- 아키텍처 확인: `file app_axi_gpio.elf` → aarch64여야 함
- 실행 권한: `chmod +x app_gpio.elf`

### GPIO 초기화 오류
- XSA 파일에 AXI GPIO IP가 포함되어 있는지 확인
- GPIO_DEVICE_ID가 xparameters.h와 일치하는지 확인

### 빌드 오류
- cross compiler 경로 확인
- Platform 생성 여부 확인

---

## 파일 위치 요약

| 파일 | 위치 |
|------|-------|
| XSA | `../../../out/result_files/kv260_axi_gpio.xsa` |
| Standalone 소스 | `src/axi_gpio.c` |
| Platform | `kv260_platform/export/kv260_platform/` |
| ELF | `app_axi_gpio/Binary/app_axi_gpio.elf` |

---

## 관련 문서

- [Vitis 공식 문서](https://www.xilinx.com/html_docs/xilinx2025_2/vitis_doc/index.html)
- [KV260 보드 문서](https://www.xilinx.com/products/boards-and-kits/kv260.html)
- [Xilinx AXI GPIO 드라이버 문서](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841846/AXI+GPIO)