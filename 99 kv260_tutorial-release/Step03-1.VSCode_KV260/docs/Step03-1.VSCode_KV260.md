# VSCode + OpenOCD JTAG Debugging (WSL → KV260)

## 개요

WSL(HOST)에서 Vitis `aarch64-none-elf-gcc`로 **Standalone (베어메탈)** 애플리케이션을 크로스빌드하고, **JTAG + OpenOCD**를 통해 KV260(TARGET)에서 직접 디버깅하는 방법을 설명합니다.

JTAG 디버깅은 네트워크(gdbserver) 방식과 달리:
- Linux 의존 없음 (베어메탈 직접 디버깅)
- 네트워크 연결 불필요
- 하드웨어 브레이크포인트 지원
- 실시간 하드웨어 접근 디버깅 가능

---

## 전체 구조

```
┌─────────────────────────────────┐          ┌──────────────────────────┐
│  WSL (HOST)                     │   JTAG   │  KV260 (TARGET)          │
│                                 │  (USB)   │                          │
│  VSCode                         │──────────│  Standalone (Bare-metal) │
│   └── launch.json ──────────────┼── GDB ───│   aarch64 CPU            │
│       └── OpenOCD (:3333) ◄─────┼──────────│   (JTAG TAP)             │
│                                 │  TCP     │                          │
│  aarch64-none-elf-gcc          │  (3333)  │                          │
│  aarch64-none-elf-gdb          │          │                          │
└─────────────────────────────────┘          └──────────────────────────┘
```

JTAG 디버거: Digilent HS-2 (FTDI FT2232H 기반)

---

## Step 1: WSL에 필요한 도구 설치

### OpenOCD 설치

```bash
sudo apt update
sudo apt install -y openocd
```

> **참고**: FTDI 드라이버가 내장되어 있어야 합니다. `lsusb`로 FT2232H 인식 확인.

### GDB for Standalone

Vitis에 포함된 `aarch64-none-elf-gdb`를 사용합니다:

```bash
ls /tools/Xilinx/Vitis/2021.2/gnu/aarch64/lin/aarch64-none/bin/aarch64-none-elf-gdb
```

---

## Step 2: BSP 확인

BSP는 이미 생성되어 있습니다:

```
bsp/psu_cortexa53_0/
├── include/        # xil_io.h, xparameters.h
├── lib/            # libxil.a
│   └── libxil.a
└── libsrc/         # 드라이버 소스
```

### 확인 명령

```bash
ls -la bsp/psu_cortexa53_0/lib/libxil.a
ls bsp/psu_cortexa53_0/include/xparameters.h
```

---

## Step 3: Linker Script 확인

`lscript.ld`는 `src/` 디렉토리에 있습니다:

```bash
ls -la src/lscript.ld
```

---

## Step 4: 애플리케이션 빌드

### 소스 코드

`src/main.c` - Standalone용 AXI GPIO LED 테스트:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "xil_io.h"
#include "sleep.h"
#include "xparameters.h"

#define AXI_GPIO_0_BASE   XPAR_AXI_GPIO_RTL_0_BASEADDR
#define GPIO_DATA_OFFSET  0x00
#define GPIO_TRI_OFFSET   0x04

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

static unsigned int gpioRead(u32 base, u32 offset)
{
    return Xil_In32(base + offset);
}

static void gpioWrite(u32 base, u32 offset, u32 value)
{
    Xil_Out32(base + offset, value);
}

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
    
    gpioSetDirection(AXI_GPIO_0_BASE, 0x00000000);
    
    tri_val = gpioRead(AXI_GPIO_0_BASE, GPIO_TRI_OFFSET);
    print("Set GPIO direction: All output (0x00000000)\r\n");
    print("TRI after config: 0x");
    printHex(tri_val);
    print("\r\n\r\n");
    
    print("Running LED test pattern...\r\n");
    print("LED pattern: 0x1 -> 0x3 -> 0x7 -> 0xF -> 0x0 (loop)\r\n\r\n");
    
    while (1) {
        gpioWrite(AXI_GPIO_0_BASE, GPIO_DATA_OFFSET, 0x1);
        print("LED: 0x1 (DS1 ON)\r\n");
        sleep(1);
        
        gpioWrite(AXI_GPIO_0_BASE, GPIO_DATA_OFFSET, 0x3);
        print("LED: 0x3 (DS1+DS2 ON)\r\n");
        sleep(1);
        
        gpioWrite(AXI_GPIO_0_BASE, GPIO_DATA_OFFSET, 0x7);
        print("LED: 0x7 (DS1+DS2+DS3 ON)\r\n");
        sleep(1);
        
        gpioWrite(AXI_GPIO_0_BASE, GPIO_DATA_OFFSET, 0xF);
        print("LED: 0xF (ALL ON)\r\n");
        sleep(1);
        
        gpioWrite(AXI_GPIO_0_BASE, GPIO_DATA_OFFSET, 0x0);
        print("LED: 0x0 (ALL OFF)\r\n");
        sleep(1);
    }
    
    return 0;
}
```

### 빌드

```bash
cd src
make clean
make
```

### 빌드 결과

```
Build complete: gpio_led_app.elf
   text	   data	    bss	    dec	    hex	filename
  30448	   1968	  11200	  43616	   aa60	gpio_led_app.elf
```

---

## Step 5: OpenOCD 설정 파일

### kv260-openocd.cfg

```tcl
adapter driver ftdi
ftdi_vid_pid 0x0403 0x6011
ftdi_channel 0

ftdi_layout_init 0x00c8 0x00eb
ftdi_layout_signal nSRST -data 0x0080
reset_config none
adapter speed 500

set PS_TAPID 0x04724093
source [find kv260-zynqmp-patched.cfg]
```

### kv260-zynqmp-patched.cfg

ZynqMP용 패치된 설정 (APB-AP 디버그 접근 지원). 파일을 프로젝트 루트에 배치합니다.

---

## Step 6: VSCode 설정

### .vscode/launch.json

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "KV260 JTAG Debug (OpenOCD)",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/src/gpio_led_app.elf",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${workspaceFolder}/src",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "miDebuggerPath": "/tools/Xilinx/Vitis/2021.2/gnu/aarch64/lin/aarch64-none/bin/aarch64-none-elf-gdb",
            "miDebuggerServerAddress": "localhost:3333",
            "preLaunchTask": "Start OpenOCD",
            "postDebugTask": "Stop OpenOCD",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                },
                {
                    "description": "Set architecture to aarch64",
                    "text": "set architecture aarch64",
                    "ignoreFailures": false
                },
                {
                    "description": "Force hardware breakpoints",
                    "text": "set breakpoint auto-hw on",
                    "ignoreFailures": false
                }
            ]
        }
    ]
}
```

### .vscode/tasks.json

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build Application",
            "type": "shell",
            "command": "make -C ${workspaceFolder}/src clean && make -C ${workspaceFolder}/src",
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "problemMatcher": ["$gcc"]
        },
        {
            "label": "Start OpenOCD",
            "type": "shell",
            "command": "env -u LD_LIBRARY_PATH openocd -s ${workspaceFolder} -f ${workspaceFolder}/kv260-openocd.cfg -c 'init' -c 'jtag arp_init-reset' -c 'uscale.a53.0 arp_examine' -c 'halt' -c 'uscale.a53.0 aarch64 dbginit'",
            "isBackground": true,
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "dedicated",
                "showReuseMessage": false,
                "clear": true
            },
            "problemMatcher": {
                "pattern": {
                    "regexp": "^(.*)$",
                    "file": 1,
                    "location": 2,
                    "message": 1
                },
                "background": {
                    "activeOnStart": true,
                    "beginsPattern": "Open On-Chip Debugger",
                    "endsPattern": "Listening on port 3333 for gdb connections"
                }
            }
        },
        {
            "label": "Stop OpenOCD",
            "type": "shell",
            "command": "pkill -f 'openocd.*kv260' || true",
            "presentation": {
                "reveal": "silent",
                "panel": "shared"
            },
            "problemMatcher": []
        },
        {
            "label": "Build and Start OpenOCD",
            "dependsOrder": "sequence",
            "dependsOn": [
                "Build Application",
                "Start OpenOCD"
            ],
            "problemMatcher": []
        }
    ]
}
```

---

## Step 7: JTAG 연결 확인

### KV260 JTAG 커넥터

JTAG 디버거(예: Digilent HS-2)를 KV260의 JTAG 커넥터에 연결:

| JTAG 커넥터 | 신호 |
|---|---|
| 1 | TCK |
| 2 | GND |
| 3 | TDO |
| 4 | VREF (3.3V) |
| 5 | TMS |
| 6 | GND |
| 7 | NC (TDI - 사용 안 함) |
| 8 | GND |
| 9 | GND |
| 10 | GND |

### USB 확인

```bash
lsusb | grep -i ft
# Bus 001 Device 005: ID 0403:6011 Future Technology Devices International, Ltd FT2232H Multi-Function Async/UART Brand
```

---

## Step 8: 디버깅 시작

### 순서

1. **JTAG 연결**: KV260에 JTAG 디버거 연결 + 전원 켜기
2. **빌드**: `Ctrl+Shift+B` 또는 `make -C src`
3. **OpenOCD 시작**: VSCode에서 `F5` 누르면 자동으로 시작됨
4. **디버깅**: 브레이크포인트 설정, 스텝 실행, 변수 확인

### VSCode 디버깅 단축키

| 단축키 | 동작 |
|---|---|
| F5 | 디버깅 시작/계속 |
| F10 | Step Over |
| F11 | Step Into |
| Shift+F11 | Step Out |
| F9 | 브레이크포인트 토글 |

### 디버깅 패널

- **좌측**: 변수, 워치, 콜스택
- **중앙**: 소스 코드 + 브레이크포인트
- **하단**: 디버그 콘솔 (GDB 출력)

---

## 트러블슈팅

### 문제 1: "No JTAG device found"

```
JTAG USB 연결 확인:
  lsusb | grep -i ft
  
FTDI 드라이버 확인:
  sudo modprobe ftdi_sio
  sudo rmmod ftdi_sio && sudo modprobe ftdi_sio
```

### 문제 2: "Cannot bind to port 3333"

```
다른 openocd 프로세스 종료:
  pkill -f openocd
  
포트 사용 확인:
  netstat -tlnp | grep 3333
```

### 문제 3: "Remote 'g' packet reply is too long"

```
launch.json의 setupCommands 확인:
  "set architecture aarch64" 필수
```

### 문제 4: "Can't add breakpoint"

```
OS Lock 문제 (Linux가 실행 중일 때):
  halt 후 aarch64 dbginit 필요
  tasks.json의 init 명령 확인
```

### 문제 5: 빌드 오류 "unrecognized command-line option"

```
Makefile의 컴파일러 옵션 확인:
  Vitis 2021.2 aarch64-none-elf-gcc는 -fmessage-length=0 미지원
  -fmessage-length=0 사용 ( 等호 필요)
```

---

## 체크리스트

| # | 항목 | 확인 방법 |
|---|---|---|
| 1 | OpenOCD 설치 | `which openocd` |
| 2 | JTAG 디버거 인식 | `lsusb \| grep 0403:6011` |
| 3 | BSP 존재 | `ls bsp/psu_cortexa53_0/lib/libxil.a` |
| 4 | lscript.ld 존재 | `ls src/lscript.ld` |
| 5 | ELF 빌드 | `make -C src` 성공 |
| 6 | launch.json 설정 | GDB 경로, 포트 확인 |
| 7 | **F5로 디버깅!** | OpenOCD 자동 시작 → JTAG 디버깅 |

---

## 참고: Standalone vs Linux

| 항목 | Linux Application | Standalone (베어메탈) |
|---|---|---|
| 툴체인 | `aarch64-linux-gnu-gcc` | `aarch64-none-elf-gcc` |
| 표준 라이브러리 | glibc | newlib |
| OS 의존성 | Linux kernel | 없음 |
| 디바이스 접근 | `/dev/mem`, `mmap()` | `Xil_In32()`, `Xil_Out32()` |
| 인쇄 함수 | `printf()` | `print()`, `xil_printf()` |
| 디버깅 | gdbserver | **OpenOCD + JTAG** |

Standalone 코드는 OS 없이 CPU에서 직접 실행되므로, JTAG로 하드웨어를 직접 디버깅할 수 있습니다.

---

## 파일 목록

```
Step03-1.VSCode_KV260/
├── kv260-openocd.cfg          # OpenOCD 설정 (FTDI)
├── kv260-zynqmp-patched.cfg  # ZynqMP JTAG 설정
├── .vscode/
│   ├── launch.json           # GDB 디버깅 설정
│   └── tasks.json            # 빌드/OpenOCD 태스크
├── src/
│   ├── main.c                # Standalone 애플리케이션
│   ├── Makefile              # 빌드용
│   └── lscript.ld            # 링크 스크립트
├── bsp/
│   └── psu_cortexa53_0/      # BSP (이미 생성됨)
│       ├── include/
│       ├── lib/
│       └── libsrc/
└── docs/
    └── Step03-1.VSCode_KV260.md  # 이 문서
```
