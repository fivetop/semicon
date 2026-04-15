# Step02 - Vivado IP Integrator 교육 자료

## 1. 교육 개요

### 1.1 학습 목표
- Vivado IP Integrator 기본 사용법 습득
- PS-PL 인터페이스 이해
- 블록 자동화 (Block Automation) 활용
- RTL vs Xilinx IP 클럭 소스 선택 옵션 이해

### 1.2 KV260 하드웨어 한계 (중요)
- **Clock Source**: Main clock (100MHz)과 reset은 PS(Zynq)에서만 제공
  - PL은 독립적인 마스터 클럭 생성 불가
  - 모든 PL 클럭은 PS pl_clk0에서 파생되어야 함
- **External I/O**: PMOD connector 핀만 외부 연결 가능
  - PMOD 외에는 직접적인 GPIO 핀 접근 불가

---

## 2. 구현 내용

### 2.1 RTL 클럭 생성 (--rtl 옵션)

**모듈**: `clock_generator.v`
- 카운터 기반 클럭 분주
- 입력: PS pl_clk0 (100MHz)
- 출력: 100MHz, 50MHz, 25MHz, 12.5MHz

```verilog
module clock_generator #(
    parameter INPUT_CLK_PERIOD = 10_000,
    parameter CLKOUT0_DIVIDE = 1,
    parameter CLKOUT1_DIVIDE = 2,
    parameter CLKOUT2_DIVIDE = 4,
    parameter CLKOUT3_DIVIDE = 8
)(
    input  wire clk,
    input  wire rstn,
    input  wire locked,
    output reg  clk_out0,
    output reg  clk_out1,
    output reg  clk_out2,
    output reg  clk_out3
);
```

**교육적 가치**:
- 클럭 분주 원리 이해
- RTL 설계 역량 강화
- FPGA 내부 구조 학습
- 합성 가능한 코드 작성

---

### 2.2 Xilinx IP (Clocking Wizard) (--ip 옵션)

**IP**: xilinx.com:ip:clk_wiz:6.0
- MMCM (Mixed-Mode Clock Manager) 기반
- TCL로 IP 생성 및 설정

```tcl
set clk_wiz_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0]
set_property -dict [list \
    CONFIG.PRIM_IN_FREQ {100.000} \
    CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {200.000} \
    CONFIG.USE_LOCKED {true} \
] $clk_wiz_0
```

**교육적 가치**:
- IP Integrator 사용법 숙달
- Xilinx IP 활용 능력
- 실제 설계 흐름 반영
- 클럭 품질 (jitter) 최적화

---

### 2.3 클럭 소스 선택 옵션

| 옵션 | 명령어 | 설명 |
|------|--------|------|
| RTL | `vivado -mode batch -source run_all.tcl -- --rtl` | RTL clock_generator 사용 |
| IP | `vivado -mode batch -source run_all.tcl -- --ip` | Clocking Wizard IP 사용 |
| Hybrid | `vivado -mode batch -source run_all.tcl -- --rtl --ip` | 둘 다 사용 |

---

## 3. PMOD 출력 (하드웨어 연결)

### 3.1 PMOD_A 커넥터 핀 할당

| PMOD 핀 | FPGA 핀 | 신호 | 주파수 |
|---------|---------|------|--------|
| Pin 1 | H12 | pmod_clk_100m | 100MHz |
| Pin 2 | H11 | pmod_clk_50m | 50MHz |
| Pin 3 | G14 | pmod_clk_25m | 25MHz |
| Pin 4 | G13 | pmod_clk_12m | 12.5MHz |

### 3.2 XDC 제약 파일

```xdc
# PMOD_A Connector Pin Assignment (JE Connector)
set_property PACKAGE_PIN H12 [get_ports pmod_clk_100m]
set_property IOSTANDARD LVCMOS33 [get_ports pmod_clk_100m]

set_property PACKAGE_PIN H11 [get_ports pmod_clk_50m]
set_property IOSTANDARD LVCMOS33 [get_ports pmod_clk_50m]

set_property PACKAGE_PIN G14 [get_ports pmod_clk_25m]
set_property IOSTANDARD LVCMOS33 [get_ports pmod_clk_25m]

set_property PACKAGE_PIN G13 [get_ports pmod_clk_12m]
set_property IOSTANDARD LVCMOS33 [get_ports pmod_clk_12m]
```

### 3.3 교육 활용 방법
- 로직 애널라이저로 클럭波形 확인
- PMOD → LED 변환 보드로 클럭 상태 시각화
- 주파수 측정으로 클럭 분주 동작 검증

---

## 4. RTL vs IP 비교

| 항목 | RTL clock_generator | Clocking Wizard IP |
|------|---------------------|---------------------|
| 구현 복잡도 | 낮음 (카운터) | 중간 (IP 설정) |
| 클럭 품질 | 보통 | 높음 (MMCM) |
|灵活性 | 높음 (커스터마이징) | 보통 (고정된 IP) |
| 교육적 가치 | 원리 이해 | 실무 역량 |
| 사용 빈도 | 학습용 | 실제 프로젝트 |

---

## 5. 권장 교육 커리큘럼 (2시간)

| 시간 | 섹션 | 내용 | 방식 |
|------|------|------|------|
| 15분 | 이론 1 | IP Integrator 개요, PS-PL 구조 | PPT |
| 30분 | 실습 1 | RTL 클럭 생성 (--rtl) | Vivado 따라하기 |
| 15분 | 이론 2 | Clocking Wizard/MMCM 원리 | PPT |
| 30분 | 실습 2 | Xilinx IP 사용 (--ip) | Vivado 따라하기 |
| 20분 | 비교 분석 | RTL vs IP 장단점 토론 | 그룹 discussion |
| 10분 | 검증 | PMOD 핀에서 클럭 확인, 질문 | Q&A |

---

## 6. 파일 구조

```
Step02_Vivado_IP_Integrator/
├── src/
│   ├── clock_generator.v       # RTL 클럭 분주 모듈
│   ├── reset_controller.v      # 리셋 컨트롤러
│   └── platform_wrapper.v      # 최상위 모듈 (PMOD 출력 포함)
├── scripts/
│   ├── create_project.tcl      # 프로젝트 생성
│   ├── create_block_design.tcl # 블록 디자인 (RTL/IP 옵션)
│   ├── run_synthesis.tcl       # 합성
│   ├── run_implementation.tcl  # 구현
│   └── run_all.tcl             # 전체 빌드
├── constraints/
│   └── kv260_ipi.xdc           # PMOD 핀 할당
├── sim/
│   └── (시뮬레이션 파일)
└── docs/
    └── step02-education.md     # 본 파일
```

---

## 7. 확인 사항

- [ ] RTL 클럭 모듈 합성 성공
- [ ] IP 클럭 모듈 합성 성공
- [ ] PMOD 핀에서 클럭 신호 출력 확인
- [ ] RTL vs IP 비교 분석 완료