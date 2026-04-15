# KV260 Vivado 교육 튜토리얼 #5 - KV260 BIST Platform

본 튜토리얼은 KV260 Vision AI Starter Kit의 BIST (Built-In Self-Test) 플랫폼을 분석하고, 비전 AI 애플리케이션 개발을 위한 전체 시스템을 이해합니다.

---

## Copyright

Copyright 2017 ETH Zurich and University of Bologna.
Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51.

---

## Section 1:概述

### 1.1 BIST (Built-In Self-Test)란?
BIST는 시스템이 스스로 진단하는 기능입니다. KV260의 BIST 플랫폼은:

- MIPI 카메라 입력 테스트
- 비디오 인코딩/디코딩 테스트
- DisplayPort 출력 테스트
- 이더넷 연결 테스트
- DDR 메모리 테스트

### 1.2 KV260 비전 AI 앱 플랫폼 아키텍처
KV260는 다양한 비전 AI 애플리케이션을 지원합니다:

```
+--------------------------------------------------+
|              KV260 Vision AI Platform            |
+--------------------------------------------------+
|  +------------+  +------------+  +-----------+  |
|  |   MIPI     |  |    VCU     |  |  Video    |  |
|  |   CSI-2    |  | (Video     |  |  Mixer    |  |
|  |   Rx       |  |  Codec)    |  |           |  |
|  +------------+  +------------+  +-----------+  |
|       |               |               |         |
|       +---------------+---------------+         |
|                     |                          |
|              +------v------+                   |
|              | Zynq UltraScale+                |
|              |    MPSoC    |                   |
|              +------+------+                   |
|                     |                          |
|  +------------+     |     +------------+      |
|  |  Ethernet  |     |     |   DDR4     |      |
|  |  (GigE)   |     |     |   (2GB)    |      |
|  +------------+     |     +------------+      |
+---------------------+---------------------------+
```

### 1.3 본 튜토리얼의 목표
1. KV260 BIST 플랫폼 구조 이해
2. 참조 GitHub 리포지토리 활용
3. 커스텀 애플리케이션 개발을 위한 기반 마련

---

## Section 2: 참조 자료 접근

### 2.1 공식 GitHub 리포지토리 클론
KV260 비전 플랫폼의 공식 소스:

```bash
git clone --branch xlnx_rel_v2022.1 --recursive \
  https://github.com/Xilinx/kria-vitis-platforms.git

cd kria-vitis-platforms/kv260
```

### 2.2 디렉토리 구조
```
kria-vitis-platforms/
├── kv260/
│   ├── Makefile
│   ├──平台的/
│   │   ├── kv260_ispMipiRx_vcu_DP/
│   │   ├── kv260_vcuDecode_vmixDP/
│   │   └── ...
│   ├── apps/
│   │   ├── smartcam/
│   │   ├── aibox-reid/
│   │   └── ...
│   └── docs/
```

### 2.3 참조 문서
- **KV260 User Guide**: UG1089
- **Kria Apps Documentation**: xilinx.github.io/kria-apps-docs/
- **Vitis Platform Documentation**: UG1393

---

## Section 3: XSA 생성 (Makefile 기반)

### 3.1 플랫폼 선택
KV260 애플리케이션별 플랫폼:

| Application | Platform Name | 용도 |
|-------------|---------------|------|
| smartcam | kv260_ispMipiRx_vcu_DP | MIPI 카메라 + 인코딩 |
| aibox-reid | kv260_vcuDecode_vmixDP | 비디오 디코딩 |
| defect-detect | kv260_ispMipiRx_vmixDP | MIPI 카메라 + 비디오 |
| nlp-smartvision | kv260_ispMipiRx_rpiMipiRx_DP | 듀얼 카메라 |

### 3.2 make xsa 명령
```bash
cd kria-vitis-platforms/kv260

# 플랫폼 선택 후 XSA 생성
make xsa PLATFORM=kv260_ispMipiRx_vcu_DP
```

### 3.3 빌드 시간 고려사항
| 단계 | 예상 시간 |
|------|----------|
| Synthesis | 20-30분 |
| Implementation | 30-45분 |
| **총합** | **50-75분** |

*참고: SSD에서 진행 권장*

---

## Section 4: 블록 디자인 분석

### 4.1 주요 IP 블록
BIST 플랫폼의 주요 IP:

| IP | 설명 | 위치 |
|----|------|------|
| zynq_ultra_ps_e | Zynq PS | 중앙 |
| MIPI CSI-2 Rx | 카메라 입력 | PL |
| VCU | 비디오 인코딩/디코딩 | PL |
| Video Mixer | 비디오 출력 | PL |
| Clocking Wizard | 클럭 생성 | PL |
| Processor System Reset | 리셋 관리 | PL |

### 4.2 인터페이스 구성

**MIPI 카메라 입력:**
```
MIPI CSI-2 Camera --> MIPI CSI-2 Rx --> ISP --> Video Pipeline
```

**DisplayPort 출력:**
```
Video Pipeline --> Video Mixer --> DisplayPort Output
```

**이더넷:**
```
PS Ethernet --> GEM0 --> RGMII --> Gigabit Ethernet
```

**DDR 메모리:**
```
PS DDR Controller <--> DDR4 (2GB)
PL <--> AXI HP <--> DDR4
```

---

## Section 5: 블록 디자인 수정 (선택)

### 5.1 TCL 스크립트 실행
기존 블록 디자인을 열기:

```bash
cd kv260_ispMipiRx_vcu_DP
vivado -mode batch -source ../../scripts/create_project.tcl
```

### 5.2 Vivado GUI 열기
```bash
vivado kv260_ispMipiRx_vcu_DP.xpr
```

### 5.3 플랫폼 인터페이스 설정
**Platform Setup 창** (Tools → Platform Setup):

| 탭 | 설정 |
|----|------|
| Clock | pl_clk0 (100MHz), pl_clk1 (200MHz) |
| AXI Port | M_AXI_HPM0_FPD, S_AXI_HP0_FPD |
| Interrupt | IRQ_F2P[0-31] |

### 5.4 커스텀 IP 추가
1. IP Integrator에서 '+' 클릭
2. 커스텀 IP 선택
3. 연결: Run Connection Automation

---

## Section 6: 새로운 XSA 생성

### 6.1 수정된 BD 저장
```
File → Save Block Design
```

### 6.2write_hw_platform 명령
```tcl
# TCL으로 XSA 생성
write_hw_platform -force -file kv260_custom.xsa
```

### 6.3 옵션
| 옵션 | 설명 |
|------|------|
| `-force` | 기존 파일 덮어쓰기 |
| `-file` | 출력 파일명 |
| `-expand` | 포트 확장 |

---

## Section 7: Vitis 플랫폼 생성

### 7.1 Vitis 실행
```bash
source /tools/Xilinx/Vitis/2021.2/settings64.sh
vitis &
```

### 7.2 Platform 프로젝트 생성
1. **File** → **New** → **Platform Project**
2. 이름: `kv260_custom_platform`
3. **Hardware Specification (XSA)** 선택

### 7.3 Domain 설정
| Domain | 설정 |
|--------|------|
| Operating System | Linux |
| Architecture | arm64 |
| Processor | psu_cortexa53 |

### 7.4 플랫폼 빌드
```bash
# Vitis에서
Platform → Build
```

---

## Section 8: 전체 시스템 테스트

### 8.1 PetaLinux 빌드
```bash
petalinux-create --project kv260_custom \
  --template zynqMP

cd kv260_custom
petalinux-config --get-hw-description=../kv260_custom.xsa

# 빌드
petalinux-build
```

### 8.2 SD 카드 이미지 생성
```bash
petalinux-package --boot \
  --fsbl images/zynqmp_fsbl.elf \
  --fpga images/system.bit \
  --u-boot
```

### 8.3 KV260 부팅
1. SD 카드에 이미지写入
2. KV260에 SD 카드 삽입
3. 부팅 스위치 확인 (QSPI 모드)
4. 전원 인가

### 8.4 비전 앱 실행
```bash
# KV260 SSH 접속
ssh xilinx@192.168.1.100

# 앱 실행
smartcam --help
```

---

## Section 9: 설계 검증

### 9.1 MIPI 카메라 캡처 확인
```bash
# 카메라 연결 확인
v4l2-ctl --list-devices
```

### 9.2 VCU 인코딩/디코딩 확인
```bash
# 인코딩 테스트
gst-launch-1.0 v4l2src device=/dev/video0 ! \
  video/x-raw,format=NV12,width=1920,height=1080 ! \
  omxh264enc ! \
  filesink location=test.h264
```

### 9.3 DisplayPort 출력 확인
```bash
# DisplayPort 상태
xrandr --output DP-1 --mode 1920x1080
```

### 9.4 이더넷 연결 확인
```bash
# IP 설정
ip addr show eth0
ping -I eth0 8.8.8.8
```

---

## Section 10: 심화 주제

### 10.1 커스텀 IAS 센서 모듈 통합
새로운 카메라 센서 지원:

```python
# sensor.py 예시
from sensor_lib import SensorBase

class MySensor(SensorBase):
    def __init__(self):
        super().__init__()
        self.resolution = (1920, 1080)
        self.format = 'RAW10'
    
    def initialize(self):
        # 센서 초기화
        pass
```

### 10.2 DPU (Deep Learning Processing Unit) 추가
KV260에서 딥러닝 추론:

1. Vitis AI 설치
2. DPU IP 추가
3. 모델 배포

```bash
# Vitis AI로 모델 컴파일
vai_c_xir --xmodel resnet50.xir \
  --arch kv260_dpu.json \
  --output_dir compiled/
```

### 10.3 실시간 비전 처리 최적화
파이프라이닝 최적화:

```
Camera → ISP → DPU → VCU → DisplayPort
    ↑_______Pipeline___________↓
```

---

## Section 11: 참고 자료

### AMD/Xilinx 공식 문서
- **UG1089**: KV260 Starter Kit User Guide
- **UG1393**: Vitis Unified Software Platform Documentation
- **Xilinx Kria Apps Documentation**: xilinx.github.io/kria-apps-docs/

### GitHub 리소스
- **KV260 Vitis Platforms**: github.com/Xilinx/kria-vitis-platforms
- **Vitis Library**: github.com/Xilinx/Vitis_Libraries
- **Vitis AI**: github.com/Xilinx/Vitis-AI

### 학습 자료
- **KV260 Getting Started**: www.xilinx.com/kria
- **PYNQ KV260**: pynq.io
- **Vitis Tutorial**: www.xilinx.com/vitis

---

## Section 12: 검증 체크리스트

- [ ] GitHub 리포지토리 클론 완료
- [ ] XSA 생성 성공
- [ ] 블록 디자인 분석 완료
- [ ] 커스텀 IP 추가 (선택)
- [ ] Vitis 플랫폼 생성
- [ ] PetaLinux 빌드
- [ ] KV260 부팅 및 테스트

---

본 튜토리얼을 통해 KV260 BIST 플랫폼의 구조를 이해하고, 비전 AI 애플리케이션 개발을 위한 기반을 마련했습니다. 이를 바탕으로 커스텀 비전 애플리케이션 개발이 가능합니다.

---

** KV260 교육 튜토리얼 시리즈 완료 **
