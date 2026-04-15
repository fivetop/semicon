# KV260 Vivado 교육 튜토리얼 #4 - Vitis HLS + 커스텀 IP

본 튜토리얼은 Vitis HLS (High-Level Synthesis)를 사용하여 C/C++ 코드를 RTL로 변환하는 방법을 학습합니다. PMOD 인터페이스를 제어하는 커스텀 IP를 만들어 Vivado에 통합합니다.

---

## Copyright

Copyright 2017 ETH Zurich and University of Bologna.
Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51.

---

## Section 1: 개요

### 1.1 Vitis HLS란?
Vitis HLS는 C/C++ 또는 OpenCL 코드를 Verilog/VHDL로 자동 변환하는 도구입니다.

**장점:**
- 하드웨어 설계 시간 단축
- 소프트웨어 개발자와 하드웨어 개발자 간 협업 용이
- 고수준 최적화 가능

### 1.2 C/C++에서 RTL 생성
```
C/C++ 코드 → Vitis HLS → Verilog/VHDL → Vivado IP
```

### 1.3 PMOD IP 개발 실습
PMOD 커넥터를 제어하는 커스텀 IP를 생성합니다:

- PMOD 출력: 특정 비트 패턴 쓰기
- PMOD 입력: 스위치 상태 읽기
- AXI4-Lite 인터페이스로 제어

---

## Section 2: Vitis HLS 환경 설정

### 2.1 Vitis HLS 실행
```bash
source /tools/Xilinx/Vivado/2021.2/settings64.sh
vitis_hls &
```

### 2.2 프로젝트 생성
1. **Create New Project**
2. **Project Name**: `pmod_io_ip`
3. **Top Function**: `pmod_io`

### 2.3 타겟 칩 선택
KV260의 FPGA 칩:

| 속성 | 값 |
|------|-----|
| Part | xck26-sfvc784-2LV-c |
| Family | zynquplus |
| Device | xck26 |
| Package | sfvc784 |
| Speed Grade | -2LV |

---

## Section 3: C++ 코드 작성

### 3.1 기본 구조
```cpp
// pmod_io.cpp
// Copyright 2017 ETH Zurich and University of Bologna.

#include <stdio.h>
#include <stdint.h>

typedef unsigned short int u16;

// PMOD I/O 제어 함수
u16 pmod_io(u16 io_ctrl, u16 io_num, u16& pmod) {
    // 함수 본문
}
```

### 3.2 AXI4-Lite 인터페이스 Pragma
Vitis HLS에서 AXI 버스를 사용하려면 pragma가 필요합니다:

```cpp
#include <stdio.h>
#include <stdint.h>

typedef unsigned short int u16;

u16 pmod_io(u16 io_ctrl, u16 io_num, u16& pmod) {
    #pragma HLS INTERFACE ap_ctrl_none port=return
    #pragma HLS INTERFACE s_axilite port=io_ctrl
    #pragma HLS INTERFACE s_axilite port=io_num
    #pragma HLS INTERFACE s_axilite port=pmod

    u16 pmod_mask;
    
    if (io_ctrl == 0xf) {
        // 초기화
        pmod_mask = 0;
    } else if (io_ctrl == 0xa) {
        // 비트 SET
        pmod_mask = (1 << io_num);
    } else if (io_ctrl == 0x5) {
        // 비트 CLEAR
        pmod_mask = ~(1 << io_num);
    } else if (io_ctrl == 0x1) {
        // 직접 쓰기
        pmod_mask = io_num;
    } else {
        // 읽기
        pmod_mask = pmod_mask;
    }
    
    pmod = pmod_mask;
    return pmod_mask;
}
```

### 3.3 함수 설명

| io_ctrl | 동작 | 설명 |
|---------|------|------|
| 0xf | 초기화 | 모든 출력 0으로 설정 |
| 0xa | SET | 해당 비트만 1로 설정 |
| 0x5 | CLEAR | 해당 비트만 0으로 설정 |
| 0x1 | WRITE | 직접 값 쓰기 |
| 0x0 | READ | 현재 값 읽기 |

---

## Section 4: C Synthesis

### 4.1 Run C Synthesis
1. **Run C Synthesis** 버튼 클릭
2. 또는Toolbar: `C Synthesis` → `Run`

### 4.2 리포트 분석
합성 후 다음 리포트를 확인합니다:

| 지표 | 설명 | 좋은 값 |
|------|------|---------|
| Fmax | 최대 동작 주파수 | > 200MHz |
| Latency | 실행 클럭 사이클 | 최소 |
| BRAM | 블록 RAM 사용량 | 0 |
| DSP | DSP 사용량 | 0 |
| FF | Flip-Flop 사용량 | 적을수록 좋음 |
| LUT | LUT 사용량 | 적을수록 좋음 |

### 4.3 오류 해결
일반적인 오류와 해결방법:

| 오류 | 해결 방법 |
|------|----------|
| `Array bound missing` | 배열 크기 명시 |
| `Pointer not aligned` | `#pragma HLS ARRAY_PARTITION` |
| `Function too complex` | 코드 분할 |

---

## Section 5: RTL 익스포트

### 5.1 Export RTL
1. **Export RTL** 버튼 클릭
2. 또는Toolbar: `Export` → `Export RTL`

### 5.2 IP Catalog 형식으로 생성
**옵션 선택:**
- **Format**: IP Catalog
- **Output Directory**: 선택

### 5.3 export.zip 생성
생성된 IP:
```
pmod_io_ip/
├── export.zip          # Vivado IP Repository용
├── ip/
│   ├── hdl/
│   ├── xgui/
│   └── component.xml
```

---

## Section 6: Vivado 통합

### 6.1 프로젝트 생성
```bash
source /tools/Xilinx/Vivado/2021.2/settings64.sh
vivado &
```

1. Create Project: RTL Project
2. 프로젝트 이름: `kv260_pmod_demo`
3. 보드: Kria KV260 Vision AI Starter Kit

### 6.2 IP Repository 추가
1. **Settings** → **IP** → **Repository**
2. **Add Repository** 클릭
3. `pmod_io_ip/export.zip` 선택
4. 또는 압축 해제된 디렉토리 선택

### 6.3 블록 디자인
설계 구성:

```
+----------------------------------+
|         design_1                 |
|                                  |
|  +----------------+              |
|  | zynq_ultra_ps_e|              |
|  |    (Zynq PS)  |              |
|  +--------+-------+              |
|           |                      |
|  +--------v--------+  +--------+ |
|  |   axi_gpio     │  | pmod_io | |
|  |  (AXI GPIO)   │  | (Custom)| |
|  +--------+-------+  +----+----+ |
|           |                |     |
|  +--------v--------+  +----v----+ |
|  |  led_gpio      │  |  pmod   | |
|  |  (External)   │  | (External| |
|  +----------------+  +---------+ |
+----------------------------------+
```

### 6.4 IP 추가
1. BD에서 '+' 버튼
2. `pmod_io` 검색 (Custom IP)
3. 추가

### 6.5 AXI GPIO 추가
AXI GPIO로 LED 제어:
1. '+' → `axi_gpio` 추가
2. GPIO Width: 4

### 6.6 Slice IP 추가
PMOD의 하위 8비트만 사용:
1. '+' → `slice` 추가
2. DIN Width: 16
3. DOUT Width: 8

### 6.7 Run Connection Automation
모든 AXI 버스 자동 연결

---

## Section 7: PMOD 핀 제약조건

### 7.1 KV260 PMOD J1 핀맵
| PMOD Pin | FPGA Pin | 신호명 |
|----------|----------|--------|
| 1 | H12 | PMOD_HDA11 |
| 2 | E10 | PMOD_HDA12 |
| 3 | D10 | PMOD_HDA13 |
| 4 | C11 | PMOD_HDA14 |
| 5 | GND | GND |
| 6 | 3.3V | VCC |

### 7.2 XDC 파일
```tcl
# PMOD J1 Output Pins
# Pin 1-4
set_property PACKAGE_PIN H12 [get_ports pmod[0]]
set_property PACKAGE_PIN E10 [get_ports pmod[1]]
set_property PACKAGE_PIN D10 [get_ports pmod[2]]
set_property PACKAGE_PIN C11 [get_ports pmod[3]]

# I/O Standard
set_property IOSTANDARD LVCMOS33 [get_ports pmod[*]]
set_property SLEW SLOW [get_ports pmod[*]]
set_property DRIVE 4 [get_ports pmod[*]]
```

### 7.3 추가 PMOD (J2)
```tcl
# PMOD J2 (사용 시)
set_property PACKAGE_PIN L1 [get_ports pmod[8]]
set_property PACKAGE_PIN M1 [get_ports pmod[9]]
set_property PACKAGE_PIN N2 [get_ports pmod[10]]
set_property PACKAGE_PIN M2 [get_ports pmod[11]]
```

---

## Section 8: 컴파일 및 비트스트림 생성

### 8.1 TCL 스크립트
```bash
source /tools/Xilinx/Vivado/2021.2/settings64.sh
vivado -mode batch -source scripts/run_all.tcl
```

### 8.2 수동 실행
1. **Run Synthesis**
2. **Run Implementation**
3. **Generate Bitstream**

---

## Section 9: Ubuntu 연동

KV260에는 Ubuntu가 실행 중이므로, PetaLinux 대신 Linux FPGA Manager 프레임워크를 통해 커스텀 IP를 로드합니다.

### 9.1 FPGA Manager란?

FPGA Manager는 Linux 커널에 내장된 FPGA 프로그래밍 서브시스템입니다. 제조사에 관계없이 통일된 인터페이스로 FPGA를 프로그래밍할 수 있도록 추상화합니다.

#### 핵심 구조

FPGA Manager는 세 가지 핵심 구성요소로 이루어져 있습니다:

| 구성요소 | 역할 |
|----------|------|
| **FPGA Manager** | Bitstream을 FPGA에 프로그래밍 |
| **FPGA Region** | 재구성 가능한 영역을 Manager, Bridge와 연결 |
| **FPGA Bridge** | 프로그래밍 중 FPGA와 나머지 시스템을 격리 |

#### 상태 머신

FPGA Manager는 다음 상태를 순서대로 거칩니다:

```
POWER_OFF → POWER_UP → RESET → FIRMWARE_REQ → WRITE_INIT → WRITE → WRITE_COMPLETE → OPERATING
```

각 상태에서 오류 발생 시 `*_ERR` 상태로 전이됩니다 (예: `WRITE_INIT_ERR`, `WRITE_ERR`).

#### sysfs 인터페이스

FPGA Manager는 `/sys/class/fpga_manager/fpga0/` 경로에 sysfs 인터페이스를 노출합니다:

| 속성 | 읽기/쓰기 | 설명 |
|------|----------|------|
| `name` | 읽기 전용 | FPGA Manager 드라이버 이름 (예: "Xilinx ZynqMP FPGA Manager") |
| `state` | 읽기 전용 | 현재 FPGA 상태 (예: "operating", "write_init_err") |
| `status` | 읽기 전용 | 상세 오류 상태 (CRC 오류, 호환되지 않는 이미지 등) |
| `firmware` | 쓰기 전용 | Bitstream 파일명을 쓰면 프로그래밍 시작 |
| `flags` | 읽기/쓰기 | Bitstream 플래그 (전체/부분, 암호화, 압축 등) |

**flags 값:**

| 값 | 의미 |
|----|------|
| `0x0` | 전체 Bitstream (기본값) |
| `0x1` | 부분 재구성 (Partial Reconfiguration) |
| `0x4` | 암호화된 Bitstream |
| `0x10` | 압축된 Bitstream |

#### FPGA Manager 상태 확인
```bash
# FPGA Manager 이름 확인
cat /sys/class/fpga_manager/fpga0/name
# 출력 예: Xilinx ZynqMP FPGA Manager

# 현재 상태 확인
cat /sys/class/fpga_manager/fpga0/state
# 출력 예: operating

# 오류 발생 시 상세 상태 확인
cat /sys/class/fpga_manager/fpga0/status
```

#### Ubuntu 필수 패키지

```bash
# FPGA Manager 도구 설치
sudo apt update
sudo apt install fpga-manager-xlnx device-tree-compiler

# 커널 모듈 확인
lsmod | grep fpga
```

### 9.2 Bitstream 변환 및 전송

FPGA Manager는 `.bit` 파일을 직접 사용할 수 없으며, 바이너리 형식(`.bit.bin`)으로 변환해야 합니다.

#### .bit → .bit.bin 변환 (bootgen 사용)

BIF 파일 작성 (`design.bif`):
```
all: {
    [destination_device = pl] pmod_demo.bit
}
```

변환 명령:
```bash
bootgen -image design.bif -arch zynqmp -o pmod_demo.bit.bin -w
```

#### KV260으로 전송
```bash
scp pmod_demo.bit.bin ubuntu@kv260:/lib/firmware/
```

### 9.3 Bitstream 로드

#### 방법 1: sysfs를 통한 직접 로드
```bash
# /lib/firmware/ 에 bitstream 복사
sudo cp pmod_demo.bit.bin /lib/firmware/

# 전체 Bitstream 플래그 설정
echo 0 | sudo tee /sys/class/fpga_manager/fpga0/flags

# Bitstream 프로그래밍 시작
echo pmod_demo.bit.bin | sudo tee /sys/class/fpga_manager/fpga0/firmware

# 상태 확인 ("operating"이면 성공)
cat /sys/class/fpga_manager/fpga0/state
```

#### 방법 2: xmutil을 통한 로드 (권장)

xmutil은 dfx-mgr 데몬을 통해 Bitstream 로드와 Device Tree Overlay 적용을 한 번에 처리합니다.

**펌웨어 패키지 생성:**
```bash
# 디렉토리 생성
sudo mkdir -p /lib/firmware/xilinx/pmod-demo

# 필요한 파일 복사
sudo cp pmod_demo.bit.bin /lib/firmware/xilinx/pmod-demo/
sudo cp pmod_demo.dtbo    /lib/firmware/xilinx/pmod-demo/
```

`shell.json` 생성:
```json
{
    "shell_type": "PL_FLAT",
    "num_slots": "1"
}
```

```bash
sudo cp shell.json /lib/firmware/xilinx/pmod-demo/
```

**로드 및 확인:**
```bash
# 사용 가능한 앱 확인
sudo xmutil listapps

# 앱 로드
sudo xmutil loadapp pmod-demo

# 앱 언로드
sudo xmutil unloadapp
```

#### 로드 확인
```bash
# 커널 메시지 확인
dmesg | tail -10
# 예상 출력:
# fpga_manager fpga0: writing pmod_demo.bit.bin to Xilinx ZynqMP FPGA Manager
# DTBO loaded through zynqMP FPGA manager successfully

# FPGA 상태 확인
cat /sys/class/fpga_manager/fpga0/state
# 예상 출력: operating
```

### 9.4 커스텀 IP 접근 (UIO 방식)

Device Tree Overlay가 적용되면 커스텀 IP가 UIO 디바이스로 등록됩니다.

```bash
# UIO 디바이스 확인
ls -la /dev/uio*

# UIO 이름 확인
cat /sys/class/uio/uio0/name

# UIO 메모리 매핑 확인
cat /sys/class/uio/uio0/maps/map0/addr   # 베이스 주소
cat /sys/class/uio/uio0/maps/map0/size   # 매핑 크기
```

### 9.5 Python에서 접근 (PYNQ 사용)
```python
from pynq import Overlay
import time

# Overlay 로드
overlay = Overlay("pmod_demo.bit")

# 커스텀 IP 접근
pmod = overlay.pmod_io_0

# PMOD에 쓰기
pmod.write(0x0, 0xf)   # 초기화
pmod.write(0x4, 0x0a)  # SET (비트 0)
pmod.write(0x8, 0x01)  # io_num = 1

# 읽기
value = pmod.read(0xc)  # pmod 값 읽기
print(f"PMOD Value: {value:08x}")
```

---

## Section 10: Device Tree Overlay

### 10.1 DTSI 파일 생성
PMOD IP의 디바이스 트리:

```dtsi
/ {
   amba_pl {
        pmod_io_0: pmod_io@43c00000 {
            compatible = "xlnx,pmod_io-1.0";
            xlnx,addrwidth = "16";
            xlnx,baseaddr = "0x43C00000";
            xlnx,range = "0x10000";
        };
    };
};
```

### 10.2 DTBO 컴파일
```bash
dtc -I dts -O dtb -o pmod_ioOverlay.dtbo pmod_ioOverlay.dts
```

### 10.3 런타임 로드
```bash
cp pmod_ioOverlay.dtbo /lib/firmware/
echo pmod_io > /sys/class/fpga_manager/fpga0/firmware
```

---

## Section 11: KV260에서 테스트

### 11.1 앱 로드 (xmutil)
```bash
# KV260에서 실행
xmutil listapps
xmutil loadapp <app_name>
```

### 11.2 Python 테스트 코드
```python
from pynq import Overlay
import time

# Overlay 로드
overlay = Overlay("pmod_demo.bit")

# 커스텀 IP 접근
pmod = overlay.pmod_io_0

# PMOD에 쓰기
pmod.write(0x0, 0xf)   # 초기화
pmod.write(0x4, 0x0a)  # SET (비트 0)
pmod.write(0x8, 0x01)  # io_num = 1

# 읽기
value = pmod.read(0xc)  # pmod 값 읽기
print(f"PMOD Value: {value:08x}")
```

### 11.3 Walking LED 테스트
```python
# 4비트 walking pattern
for i in range(4):
    pmod.write(0x4, 0x0a)  # SET 명령
    pmod.write(0x8, i)     # 비트 번호
    time.sleep(0.5)
```

---

## Section 12: HLS Pragma 참조

### 기본 Pragma

| Pragma | 설명 |
|--------|------|
| `#pragma HLS INTERFACE ap_ctrl_none port=return` | AP_CTRL_NONE 프로토콜 |
| `#pragma HLS INTERFACE s_axilite port=X` | AXI4-Lite 슬레이브 |
| `#pragma HLS INTERFACE ap_vld port=X` | Valid 신호 자동 추가 |
| `#pragma HLS INTERFACE ap_ack port=X` | Acknowledge 신호 |

### 최적화 Pragma

| Pragma | 설명 |
|--------|------|
| `#pragma HLS PIPELINE` | 파이프라이닝 |
| `#pragma HLS UNROLL` | 루프 언롤 |
| `#pragma HLS ARRAY_PARTITION` | 배열 파티션 |
| `#pragma HLS RESOURCE` | 리소스 지정 |

---

## Section 13: 검증 체크리스트

- [ ] Vitis HLS에서 C Synthesis 성공
- [ ] RTL Export 성공
- [ ] IP Repository에 IP 추가됨
- [ ] Block Design에 커스텀 IP 추가됨
- [ ] Synthesis 및 Implementation 성공
- [ ] Bitstream 생성 완료
- [ ] KV260에서 테스트 성공

---

## Section 14: Troubleshooting

### 14.1 IP가 나타나지 않음
**해결**: IP Repository 경로 확인

### 14.2 합성 오류
**증상**: C Synthesis 실패

**해결**:
- Pragma 위치 확인
- 함수 시그니처 확인

### 14.3 AXI 버스 연결 실패
**해결**:
- Run Connection Automation 재실행
- 수동 연결: S_AXI → M_AXI_HPM0_LPD

---

본 튜토리얼을 통해 Vitis HLS를 사용한 커스텀 IP 생성 방법을 학습했습니다. 다음 단계에서는 KV260 BIST (Built-In Self-Test) 플랫폼 설계를 학습합니다.
