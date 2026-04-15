# KV260 Vivado 교육 튜토리얼 #2 - Vivado IP Integrator

본 튜토리얼은 Vivado IP Integrator의 심화 기능을 학습합니다. KV260 Getting Started부터 시작하여 PS-PL 인터페이스, 블록 자동화, 클럭 관리, 플랫폼 익스포트까지 다룹니다.

---

## Copyright

Copyright 2017 ETH Zurich and University of Bologna.
Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51.

---

## Section 1: 개요

### 1.1 본 튜토리얼의 목표
- Vivado IP Integrator의 기본 사용법 습득
- PS-PL 인터페이스 이해
- 블록 자동화 (Block Automation) 활용
- 플랫폼 익스포트 (XSA) 이해

### 1.2 학습 개념
- **PS (Processing System)**: Zynq의 프로세서 부분
- **PL (Programmable Logic)**: FPGA 논리 부분
- **Block Automation**: Vivado가 자동으로 연결해주는 기능
- **Board Preset**: 보드별 최적화된 설정

---

## Section 2: 프로젝트 생성

### 2.1 RTL vs Fixed Platform 선택
Vivado에서는 두 가지 유형의 프로젝트를 생성할 수 있습니다:

| 유형 | 설명 | 사용처 |
|------|------|--------|
| RTL Project | PL만 설계 | 간단한 FPGA 디자인 |
| Embedded Project | PS+PL 설계 | Zynq 사용 |

KV260에서는 **Embedded Project** 또는 **RTL Project with Zynq**를 사용합니다.

### 2.2 Vivado 프로젝트 생성
```bash
source /tools/Xilinx/Vivado/2021.2/settings64.sh
vivado &
```

1. Create Project → RTL Project
2. 프로젝트 이름: `kv260_ipi_demo`
3. 보드 선택: **Kria KV260 Vision AI Starter Kit**

### 2.3 Extensible Vitis Platform 옵션
추후 Vitis에서 소프트웨어 개발을 원하면:
- **Enable platform** 옵션 체크
- **Extensible Vitis Platform** 생성 가능

---

## Section 3: Zynq UltraScale+ MPSoC 심화

### 3.1 PS 아키텍처 이해
Zynq UltraScale+ MPSoC는 다음으로 구성됩니다:

```
+------------------------------------------+
|         Processing System (PS)          |
|  +----------+  +----------+  +--------+ |
|  |  ARM     |  |  ARM     |  |  RPU   | |
|  |  Cortex-A53 x4 |  Cortex-R5 |        | |
|  +----------+  +----------+  +--------+ |
|  +----------+  +------------------+    |
|  |  DDR4    |  |  GGUS            |    |
|  |  Controller |  |  (GPU/VDMA)   |    |
|  +----------+  +------------------+    |
+------------------------------------------+
|         Programmable Logic (PL)         |
+------------------------------------------+
```

### 3.2 클럭 및 리셋 설정
PS는 다음 클럭을 PL에 공급합니다:

| 신호 | 기본 주파수 | 용도 |
|------|-----------|------|
| pl_clk0 | 100MHz | 주 클럭 |
| pl_clk1 | 사용 가능 (선택) | 추가 클럭 |
| pl_clk2 | 사용 가능 (선택) | 추가 클럭 |
| pl_clk3 | 사용 가능 (선택) | 추가 클럭 |
| pl_resetn0 | - | 주 리셋 |

### 3.3 DDR4, QSPI, eMMC 구성
KV260의 기본 구성:
- **DDR4**: 2GB (PS용)
- **QSPI**: 부트 플래시
- **eMMC**: 추가 스토리지 (일부 모델)

---

## Section 4: 블록 자동화의 이해

### 4.1 Run Block Automation이란?
Run Block Automation은 Vivado가 PS IP의 연결을 자동으로 설정해주는 기능입니다.

**자동으로 연결되는 항목:**
- AXI 버스
- 클럭 (pl_clk0)
- 리셋 (pl_resetn0)
- 인터럽트

### 4.2 Board Preset vs User Configuration

| 설정 방식 | 설명 |
|-----------|------|
| Board Preset | 보드 제조사가 제공한 최적화된 설정 |
| User Configuration | 사용자가 수동으로 설정 |

KV260에서는 **Board Preset**을 사용하는 것이 권장됩니다.

### 4.3 수동 연결 vs 자동 연결
```
자동 연결 (Run Connection Automation):
+----------+          +----------+
|  Zynq PS | -------->|  GPIO    |
+----------+          +----------+

수동 연결:
+----------+          +----------+
|  Zynq PS | -axi--->|  AXI BUS  |
+----------+          +----------+
```

---

## Section 5: Clocking Wizard 추가

### 5.1 클럭 생성 IP 사용
Clocking Wizard는 PL에서 다른 주파수의 클럭을 생성합니다.

1. BD에서 '+' 버튼 클릭
2. `Clocking Wizard` 검색
3. `clk_wiz` 추가

### 5.2 클럭 주파수 설정
Clocking Wizard를 더블 클릭하여 설정:

| 포트 | 출력 주파수 |
|------|-----------|
| clk_out1 | 100MHz |
| clk_out2 | 200MHz |
| clk_out3 | 400MHz |
| clk_out4 | 50MHz |

### 5.3 클럭 라우팅
```
PS (pl_clk0 100MHz) --> Clocking Wizard --> PL Logic
                           |
                      clk_out1 (100MHz)
                      clk_out2 (200MHz)
                      clk_out3 (400MHz)
                      clk_out4 (50MHz)
```

---

## Section 6: Processor System Reset

### 6.1 리셋 IP 사용
Processor System Reset IP는 PS의 리셋 신호를 PL에 전달합니다.

1. BD에서 '+' 버튼 클릭
2. `Processor System Reset` 검색
3. `proc_sys_reset_0` 추가

### 6.2 연결
```
PS (pl_resetn0) --> proc_sys_reset_0 --> PL Logic (peripheral_resetn)
                           |
                      dcm_locked (클럭이 잠금 될 때까지 리셋 유지)
```

### 6.3 비동기 리셋 처리
- 비동기 리셋은 클럭 에지에서 동기화 필요
- Processor System Reset이 자동으로 처리

---

## Section 7: 플랫폼 인터페이스 설정

### 7.1 Platform Setup 탭
플랫폼 익스포트 시 필요한 인터페이스를 설정합니다.

**위치**: Tools → Platform Setup

### 7.2 PFM.CLK 설정
```
PFM.CLK:
  - pl_clk0: 100MHz (Default)
  - pl_clk1: 200MHz (Optional)
  - pl_clk2: Optional
```

### 7.3 PFM.IRQ 설정
```
PFM.IRQ:
  - Interrupt ID 0-31: PS to PL interrupts
  - PL to PS interrupts: 32-91
```

---

## Section 8: PS-PL 인터페이스 이해

### 8.1 M_AXI_HPM0_FPD/LPD
| 인터페이스 | 설명 | 용도 |
|-----------|------|------|
| M_AXI_HPM0_FPD | 고성능 AXI (Full Power Domain) | 메모리 접근 |
| M_AXI_HPM0_LPD | 저전력 Domain AXI | 저전력 장치 |

### 8.2 S_AXI_HPx_FPD
고성능 (High Performance) slave 포트:
- S_AXI_HP0_FPD ~ S_AXI_HP3_FPD
- DDR 메모리 직접 접근

### 8.3 pl_clk0, pl_resetn0
```
+----------+        +----------+
|    PS    |        |    PL    |
| pl_clk0  |------->|  클럭 입력 |
| pl_resetn|------->|  리셋 입력 |
+----------+        +----------+
```

---

## Section 9: HDL Wrapper 이해

### 9.1 Create HDL Wrapper란?
HDL Wrapper는 Block Design을 Verilog/VHDL로 변환합니다.

**두 가지 모드:**
| 모드 | 설명 |
|------|------|
| Vivado Managed | Vivado가 자동으로 관리 |
| User Managed | 사용자가 수동으로 관리 |

### 9.2 Vivado Managed vs User Managed
```
Vivado Managed:
  - BD 변경 시 자동으로 Wrapper 재생성
  - 간단한 프로젝트에 적합

User Managed:
  - 사용자가 직접 Wrapper 편집 가능
  - 고급 커스터마이징에 필요
```

---

## Section 10: 하드웨어 익스포트 (XSA)

### 10.1 XSA 파일 생성
XSA (Xilinx Shell Archive)는 하드웨어 플랫폼 정의입니다.

**방법 1: File 메뉴**
```
File → Export → Export Hardware
→ Include bitstream (체크)
→ XSA 파일 선택
```

**방법 2: TCL 명령**
```tcl
write_hw_platform -force -file kv260_platform.xsa
```

### 10.2 Pre-synthesis vs Post-synthesis
| 옵션 | 설명 | 용도 |
|------|------|------|
| Pre-synthesis | 합성 전 RTL | RTL 시뮬레이션 |
| Post-synthesis | 합성 후 네트리스트 | 구현/_BIT스트림 |
| Post-implementation | 배치 배선 후 | 최종 테스트 |

### 10.3 Vitis/PetaLinux 연동
XSA 파일은 Vitis에서 플랫폼으로 사용됩니다:

```bash
# Vitis에서 플랫폼 생성
vitis --platform ~/kv260_platform.xsa
```

---

## Section 11: 검증 체크리스트

- [ ] Zynq PS가 블록 디자인에 추가됨
- [ ] Block Automation이 정상 동작
- [ ] Clocking Wizard가 클럭 생성
- [ ] Processor System Reset이 연결됨
- [ ] HDL Wrapper가 생성됨
- [ ] XSA 파일이 익스포트됨

---

## Section 12: 심화 연습 문제

1. **Clocking Wizard 설정**: 다양한 출력 주파수를 설정해 보세요.
2. **AXI 브릿지**: PS와 PL 간 AXI 통신을 설정해 보세요.
3. **인터럽트**: PL에서 PS로 인터럽트를 보내는 시스템을 구성해 보세요.

---

본 튜토리얼을 통해 Vivado IP Integrator의 핵심 기능을 학습했습니다. 다음 단계에서는 AXI GPIO를 사용하여 PS-PL 통신을 실습합니다.
