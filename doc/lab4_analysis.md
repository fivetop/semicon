# lab4 분석 정리

## 1) 실습 목표
`romee/lab4`는 DC 기본 합성 흐름에 더해, 실제 칩 환경을 반영한 I/O 환경 제약까지 포함해 보는 단계입니다.

핵심 포인트:
1. RTL 읽기/링크
2. 타이밍 제약 적용
3. 환경 제약(입력 구동, 입력 transition, 출력 load) 적용
4. 포트/디자인 리포트 확인
5. `ddc` 저장

## 2) 폴더 구성
- `.synopsys_dc.setup`
- `common_setup.tcl`
- `dc_setup.tcl`
- `.solutions/dc.tcl`
- `.solutions/MY_DESIGN.con`
- `rtl/MY_DESIGN.v`
- `scripts/` (write_script 출력)
- `unmapped/` (`MY_DESIGN.ddc` 출력)

## 3) 실행 흐름 (`.solutions/dc.tcl`)
`lab4` 실행 스크립트는 매우 단순합니다.

1. `read_verilog MY_DESIGN.v`
2. `link`
3. `source .solutions/MY_DESIGN.con`
4. `report_port -verbose`
5. `report_design`
6. `write_script -out scripts/MY_DESIGN.wscr`
7. `write_file -format ddc -hier -out unmapped/MY_DESIGN.ddc`

특징:
- `lab3`에 있던 `check_timing`, `report_clock`보다 `report_port`, `report_design` 중심으로 보는 구성입니다.

## 4) 제약 파일 요약 (`.solutions/MY_DESIGN.con`)

### 4-1. 기본 타이밍 제약
- `reset_design`
- `create_clock -period 3.0 [get_ports clk]` (333 MHz)
- clock latency:
  - source max 0.7ns
  - network max 0.3ns
- `set_clock_uncertainty -setup 0.15`
- `set_clock_transition -max 0.12`
- I/O delay:
  - `data*` input delay 0.45ns
  - `sel` input delay 0.4ns
  - `out1` output delay 0.5ns
  - `out2` output delay 2.04ns
  - `out3` output delay 0.4ns
- 조합 경로(`Cin* -> Cout`) 제약:
  - `set_input_delay -max 0.3 [get_ports Cin*]`
  - `set_output_delay -max 0.1 [get_ports Cout]`

### 4-2. lab4 핵심 추가점: 환경 제약
- 입력 구동 셀 지정:
  - `set_driving_cell -max -lib_cell bufbd1 ...`
  - 대상: `clk`, `Cin*` 제외한 입력
- 칩 레벨 입력(`Cin*`) transition 지정:
  - `set_input_transition -max 0.12 [get_ports Cin*]`
- 출력 부하 지정:
  - `out*`: `2 * load_of(bufbd7/I)`
  - `Cout*`: 0.025pF

즉, `lab4`는 wire-load 기반 기본 제약에서 한 단계 나아가 "포트 환경 모델링"을 학습하는 lab입니다.

## 5) RTL 구조 요약 (`rtl/MY_DESIGN.v`)

### Top: `MY_DESIGN`
- 하위 모듈:
  - `ARITH U1_ARITH`
  - `COMBO U_COMBO`
- 순차 블록(`posedge clk`)에서 `R1~R4` 갱신
- 조합 블록에서 `out1/out2/out3` 계산

### `ARITH`
- `sel=0`이면 `a+b`
- `sel=1`이면 `a-b`

### `COMBO`
- 내부 `ARITH` 출력(`arth_o`) + `Cin1`으로 `Cout` 생성

## 6) 검토 시 주의 포인트

1. 조합 always 블록에 nonblocking(`<=`) 사용
- `always @ (out2, R1, R3, R4)` 내부에서 `out1/out2/out3 <= ...`
- 조합 로직은 보통 `always @*` + blocking(`=`)이 권장됩니다.

2. `out3 <= out2 - R3` 의존성
- 같은 블록에서 `out2 <= R3 & R4`를 기술했더라도 nonblocking이므로 `out3` 계산은 이전 `out2` 영향을 받을 수 있습니다.

3. `ARITH` case default 없음
- `sel`이 X/Z일 때 시뮬레이션 동작이 명확하지 않을 수 있습니다.

## 7) 결론
`lab4`는 `lab3`의 기본 타이밍 제약 학습을 확장해, I/O 환경 제약까지 포함한 보다 현실적인 합성 전처리 단계를 익히는 실습입니다.
실무적으로는 제약 품질이 QoR에 직접 영향을 주므로, 환경 제약(구동/부하/transition) 해석 능력이 핵심입니다.
