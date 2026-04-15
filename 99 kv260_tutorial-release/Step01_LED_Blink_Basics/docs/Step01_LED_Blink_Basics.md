# KV260 Vivado 교육 튜토리얼 #1 - LED Blink 기초

본 튜토리얼은 Kria KV260 Vision AI Starter Kit을 활용하여 Vivado FPGA 설계의 기초를 학습하기 위한 가이드입니다. 총 5단계로 구성된 시리즈 중 첫 번째 단계로, 가장 기본적인 LED 제어 회로를 설계하고 보드에서 동작시키는 전 과정을 다룹니다.

---

## Copyright

Copyright 2017 ETH Zurich and University of Bologna.
Copyright and related rights are licensed under the Solderpad Hardware License, Version 0.51.

---

## Section 1: 환경 설정

성공적인 실습을 위해 다음 환경이 준비되어 있는지 확인하십시오.

### 1.1 Vivado 설치 확인
- **권장 버전**: Vivado Design Suite 2021.1 이상 (본 튜토리얼은 2021.2 기준)
- **설치 구성**: Zynq UltraScale+ MPSoC 장치 지원이 포함되어야 합니다.

```bash
# Vivado 환경 변수 로드
source /tools/Xilinx/Vivado/2021.2/settings64.sh

# Vivado 버전 확인
vivado -version
```

### 1.2 KV260 Ubuntu + PYNQ 설치 (선택)
PYNQ 프레임워크를 사용하려면 KV260에 Ubuntu 이미지를 설치해야 합니다.

- **권장 Ubuntu**: KV260 전용 Ubuntu 22.04 LTS 이미지
- **PYNQ 설치**:
  ```bash
  sudo pip3 install pynq
  ```

### 1.3 외부 LED 연결 방법 (PMOD)
KV260 보드에는 직접 제어 가능한 사용자 LED가 제한적이므로 PMOD 커넥터를 통해 외부 LED를 연결합니다.

**회로 구성 (ASCII)**:
```
[KV260 PMOD J1]          [Breadboard / External LED]
Pin 1 (HDA11) ---------- [Resistor 220-330 ohm] --- [+] LED [-] --- GND (Pin 5 or 11)
```

### 1.4 PMOD 핀맵 테이블 (KV260)
| PMOD Pin | FPGA Pin | Signal Name | Description |
|:---:|:---:|:---:|:---:|
| 1 | H12 | PMOD_HDA11 | 이번 실습에서 사용할 출력 핀 |
| 2 | E10 | PMOD_HDA12 | - |
| 3 | D10 | PMOD_HDA13 | - |
| 4 | C11 | PMOD_HDA14 | - |
| 5 | GND | GND | 접지 |
| 6 | VCC | 3.3V | 전원 |

---

## Section 2: Vivado 프로젝트 생성

### 2.1 Vivado 실행
터미널에서 Xilinx 환경 변수를 로드한 후 Vivado를 실행합니다.
```bash
source /tools/Xilinx/Vivado/2021.2/settings64.sh
vivado &
```

### 2.2 프로젝트 생성 마법사
1. **Quick Start**: 'Create Project' 클릭
2. **Project Name**: `kv260_led_blink` 입력
3. **Project Type**: `RTL Project` 선택, 'Do not specify sources at this time' 체크
4. **Default Part**: 
   - 'Boards' 탭 클릭
   - Search에 `Kria KV260` 입력
   - **Kria KV260 Vision AI Starter Kit** 선택 (버전은 최신 선택)
5. **Finish**: 프로젝트 생성 완료

*참고: 보드 파일이 보이지 않는 경우 Xilinx Board Store에서 다운로드해야 합니다.*

---

## Section 3: RTL 모듈 작성

두 개의 Verilog 파일을 작성합니다. 하나는 단순히 켜는 모듈, 다른 하나는 1초 간격으로 깜빡이는 모듈입니다.

### 3.1 단순 LED ON 모듈 (`led_on.v`)

```verilog
// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51

module led_on (
    input  wire clk,
    output wire led
);
    // LED를 항상 High(1) 상태로 유지
    assign led = 1'b1;
endmodule : led_on
```

### 3.2 LED Blinker 모듈 (`led_blinker.v`)

```verilog
// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51

module led_blinker #(
    parameter REF_CLK = 100_000_000  // 기본 100MHz 클락 설정
)(
    input  wire sysclk,
    output reg  o_led = 1'b0
);
    // 클락 카운트를 위한 레지스터
    integer r_count = 0;

    always @(posedge sysclk) begin
        if (r_count < (REF_CLK / 2 - 1)) begin
            r_count <= r_count + 1;
        end else begin
            r_count <= 0;
            o_led <= ~o_led; // 상태 반전 (Toggling)
        end
    end
endmodule : led_blinker
```

### 3.3 최상위 모듈 (`top_module.v`)

```verilog
// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51

module top_module (
    input  wire sysclk,
    input  wire cpu_resetn,
    output wire led_o
);

    // LED Blinker 인스턴스
    led_blinker #(
        .REF_CLK(100_000_000)
    ) u_blinker (
        .sysclk(sysclk),
        .o_led(led_o)
    );

endmodule : top_module
```

---

## Section 4: 블록 디자인 생성 (IP Integrator)

### 4.1 Block Design 시작
1. IP Integrator -> **Create Block Design** 클릭
2. Name: `design_1`

### 4.2 Zynq UltraScale+ MPSoC 추가
1. '+' 버튼 클릭 후 `Zynq UltraScale+ MPSoC` 검색하여 추가
2. 상단의 **Run Block Automation** 클릭
3. 'Apply Board Preset'이 체크된 상태로 OK 클릭 (KV260 설정 로드)

### 4.3 사용자 모듈 추가
1. 소스 창에서 `led_blinker.v`를 우클릭하여 **Add Module to Block Design** 선택
2. 블록 디자인에 `led_blinker_0` 유닛이 나타납니다.

### 4.4 연결 설정
1. `zynq_ultra_ps_e_0`의 `pl_clk0` 출력을 `led_blinker_0`의 `sysclk` 입력에 연결합니다.
2. `led_blinker_0`의 `o_led` 포트에서 우클릭하여 **Make External**을 선택합니다. 포트 이름을 `led_o`로 변경합니다.

**블록 다이어그램 구조 (ASCII)**:
```
+-----------------------+          +-----------------------+
|  Zynq UltraScale+     |          |      led_blinker      |
|        MPSoC          |          |                       |
|                       |  100MHz  |                       |
|                pl_clk0| -------->|sysclk            o_led| ===> [led_o] (External)
|                       |          |                       |
+-----------------------+          +-----------------------+
```

---

## Section 5: 제약조건 추가 (XDC)

FPGA 내부 신호를 실제 하드웨어 핀에 할당하는 과정입니다.

1. **Add Sources** -> **Add or create constraints** -> **Create File**
2. 파일 이름: `kv260_pin.xdc`
3. 아래 내용을 복사하여 붙여넣습니다:

```tcl
# LED Output Pin Assignment
# PMOD Pin 1 (PMOD_HDA11) -> FPGA Pin H12
set_property PACKAGE_PIN H12 [get_ports led_o]
set_property IOSTANDARD LVCMOS33 [get_ports led_o]
set_property SLEW SLOW [get_ports led_o]
set_property DRIVE 4 [get_ports led_o]

# System Clock Constraint (100MHz from PS)
# PS의 pl_clk0가 100MHz로 설정되어 있으므로 이에 맞춰 제약을 줍니다.
create_clock -period 10.000 -name sysclk [get_ports sysclk]
```

---

## Section 6: 설계 컴파일

### 6.1 HDL Wrapper 생성
Block Design 탭의 `design_1` 파일을 우클릭하고 **Create HDL Wrapper**를 선택합니다. 'Let Vivado manage wrapper'를 체크합니다.

### 6.2 Synthesis & Implementation
1. **Run Synthesis**: 로직으로 변환 과정을 수행합니다.
2. **Run Implementation**: 실제 배치 배선(Place and Route)을 수행합니다.
3. **Generate Bitstream**: 최종 바이너리 파일을 생성합니다.

### 6.3 리포트 확인
결과가 나오면 **Open Implemented Design**을 눌러 'Power', 'Timing', 'Utilization' 리포트를 확인합니다.
- `Utilization`: FPGA 자원을 얼마나 사용했는지 확인 (LED Blink는 매우 적게 사용함)

---

## Section 7: 하드웨어 익스포트

비트스트림 생성이 완료되면 PYNQ에서 사용할 파일을 추출해야 합니다.

### 7.1 파일 수집
프로젝트 폴더 내에서 다음 파일들을 찾으십시오:
1. **Bitstream**: `project_name.runs/impl_1/design_1_wrapper.bit`
2. **Hardware Handoff**: `project_name.gen/sources_1/bd/design_1/hw_handoff/design_1.hwh`

### 7.2 파일 이름 변경
PYNQ Overlay 시스템은 파일 이름이 동일해야 인식합니다.
- `ledblink.bit`
- `ledblink.hwh`

### 7.3 파일 전송
`scp` 명령어를 사용하여 KV260 보드로 파일을 전송합니다.
```bash
scp ledblink.bit ledblink.hwh xilinx@<KV260_IP>:/home/xilinx/pynq_overlay/
```

---

## Section 8: PYNQ에서 FPGA 프로그래밍

보드의 Jupyter Notebook 또는 SSH 터미널에서 Python 코드를 실행합니다.

```python
from pynq import Overlay

# FPGA에 비트스트림 로드 (Overlay 객체 생성 시 로드됨)
overlay = Overlay('/home/xilinx/pynq_overlay/ledblink.bit')

# 로드 성공 확인
if overlay.is_loaded():
    print("Bitstream loaded successfully!")
    print(f"Overlay name: {overlay.name}")
else:
    print("Failed to load bitstream.")
```

실행 즉시 PMOD에 연결된 LED가 1초 간격으로 깜빡이는 것을 확인할 수 있습니다.

---

## Section 9: 검증 체크리스트

실습 결과가 올바른지 다음 항목을 확인하십시오.

- [ ] Vivado에서 'Synthesis' 및 'Implementation'이 에러 없이 완료되었는가?
- [ ] XDC 파일의 핀 번호(H12)가 PMOD 1번 핀과 일치하는가?
- [ ] Bitstream 파일과 HWH 파일의 이름이 동일하게 저장되었는가?
- [ ] PYNQ Overlay 로드 시 Python 에러가 발생하지 않는가?
- [ ] LED가 실제로 약 1Hz(0.5초 ON / 0.5초 OFF) 주기로 동작하는가?

---

## Section 10: 심화 연습 문제

1. **주기 변경**: `led_blinker` 모듈의 `REF_CLK` 파라미터를 수정하여 LED가 0.1초 간격으로 매우 빠르게 깜빡이도록 설계를 변경해 보십시오.
2. **다중 LED**: PMOD의 2번 핀(E10)에도 LED를 추가 연결하고, 1번 LED와 2번 LED가 서로 교대로 깜빡이도록 Verilog 코드를 수정해 보십시오.
3. **리셋 기능**: `led_blinker` 모듈에 `rst_n` (Active Low) 입력 포트를 추가하고, 리셋이 눌려 있을 때 LED가 꺼지도록 로직을 보강해 보십시오. (이때 리셋 신호를 어떻게 공급할지도 고민해 보십시오.)

---

본 실습을 통해 Vivado 프로젝트 생성부터 Verilog 코딩, 블록 디자인, 제약조건 설정, 그리고 실제 보드 테스트까지의 전체 Flow를 경험하였습니다. 다음 단계에서는 **Vivado IP Integrator**를 더 깊게 활용하는 방법을 학습하겠습니다.
