# KV260 LED 깜빡이기 프로젝트 (Step 01)

KV260 (Kria Vision AI Starter Kit) 보드와 외부 LED를 사용하여 기초적인 Verilog 하드웨어 설계를 실습합니다.

## 프로젝트 개요
KV260 보드는 사용자 제어가 가능한 내장 LED가 없기 때문에, PMOD 커넥터를 통해 외부 LED를 연결하여 깜빡이는 회로를 구성합니다. 100MHz 클록 신호를 분주하여 약 1초 간격으로 LED를 켜며, reset 신호를 통해 안정적인 동작을 보장합니다.

## 준비물
- **FPGA 보드**: Xilinx Kria KV260 Starter Kit
- **LED**: 일반 고휘도 LED 1개
- **저항**: 330Ω (LED 보호용)
- **점퍼 와이어**: PMOD 연결용

## 하드웨어 구성 (PMOD1)
KV260의 PMOD1 커넥터 1번 핀(H12)을 사용하여 LED를 제어합니다. LED의 긴 다리(+)를 330Ω 저항을 거쳐 PMOD1 1번 핀에 연결하고, 짧은 다리(-)를 PMOD1 GND 핀에 연결합니다.

### 핀 맵 (PMOD1)
| PMOD1 Pin | FPGA Pin | 신호 이름 | 설명 |
| :--- | :--- | :--- | :--- |
| **Pin 1** | **H12** | **LED_OUT** | HDA11 (LVCMOS33) |
| Pin 5 | GND | GND | 접지 |

### 배선도 (Text Diagram)
```text
[KV260 PMOD1]          [회로 구성]
Pin 1 (H12)  --------> [330Ω 저항] --------> [LED +]
                                             [LED -]
Pin 5 (GND)  ------------------------------> [GND]
```

## 개발 환경
- **Vivado**: 2021.2
- **언어**: Verilog
- **클록 소스**: Zynq UltraScale+ PS `pl_clk0` (100MHz)
- **Reset 소스**: Zynq UltraScale+ PS `pl_resetn0` (Active-Low)

## 빌드 방법
Vivado 2021.2 환경에서 아래 명령어를 사용하여 비트스트림을 생성할 수 있습니다.

```bash
# Vivado 환경 설정 (Linux 기준)
source /tools/Xilinx/Vivado/2021.2/settings64.sh

# 프로젝트 디렉토리 이동
cd Step01_LED_Blink_Basics

# 자동 빌드 실행
./build.sh
```

### 시뮬레이션 검증
빌드 전에 시뮬레이션으로 설계를 검증할 수 있습니다:

```bash
# 표준 시뮬레이션 (50M 사이클, 실제 타이밍)
xvlog src/led_blink.v sim/tb_led_blink.v
xelab -debug typical tb_led_blink -s tb_led_blink
xsim tb_led_blink -runall

# 빠른 시뮬레이션 (1000 사이클, Reset 기능 검증)
xvlog src/led_blink.v sim/tb_led_blink_fast.v
xelab -debug typical tb_led_blink_fast -s tb_led_blink_fast
xsim tb_led_blink_fast -runall

# 예상 출력: "PASS: LED toggle and reset verified"
```

**검증 항목**:
- ✅ Reset 기능: LED가 reset 시 0으로 초기화
- ✅ Reset 중 동작: 동작 중 reset 적용 시 즉시 0으로 변경  
- ✅ 정상 동작: Reset 해제 후 정상적인 1Hz 깜빡임

## 주요 사항
- KV260은 PL(Programmable Logic) 단독으로 동작하지 않으며, PS(Processing System)에서 클록(100MHz)과 reset 신호를 공급해주어야 합니다.
- LED 보호를 위해 반드시 330Ω 저항을 직렬로 연결하십시오.
- Reset 신호(`pl_resetn0`)는 Active-Low로 동작하며, 설계의 안정성을 보장합니다.
- 결과물은 `out/` 디렉토리에 생성됩니다.
