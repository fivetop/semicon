# lab7 분석 정리

## 1) 실습 목표
`romee/lab7`는 `lab4`의 기본 타이밍/환경 제약을 확장해, 네거티브 엣지(negative-edge) I/O 타이밍을 두 가지 방식으로 모델링하는 실습입니다.

핵심 비교 대상:
1. 단일 클럭 + `-network_latency_included/-source_latency_included` 방식
2. 가상 클럭(virtual clock) 분리 방식 (`F4_clk`, `F5_clk`)

## 2) 폴더 구성
- `.synopsys_dc.setup`
- `common_setup.tcl`
- `dc_setup.tcl`
- `.solutions/dc.tcl`
- `.solutions/dc_w_vclk.tcl`
- `.solutions/MY_DESIGN.con`
- `.solutions/MY_DESIGN_w_vclk.con`
- `rtl/MY_DESIGN.v`
- `mapped/`, `unmapped/`, `scripts/` (실행 산출물/스크립트 위치)

## 3) 실행 흐름 비교

### 3-1. 기본 흐름 (`.solutions/dc.tcl`)
1. `read_verilog MY_DESIGN.v`
2. `link`
3. `source .solutions/MY_DESIGN.con`
4. `check_timing`, `report_design`, `report_clock`, `report_port -verbose`
5. `compile_ultra -scan -retime`
6. 위반/타이밍 리포트 확인
7. `mapped/MY_DESIGN.ddc` 저장

### 3-2. 가상클럭 흐름 (`.solutions/dc_w_vclk.tcl`)
- 실행 절차는 기본 흐름과 동일하나, 제약 파일과 출력 파일이 다릅니다.
- 제약 파일: `.solutions/MY_DESIGN_w_vclk.con`
- 출력 파일: `mapped/MY_DESIGN_w_vclk.ddc`

## 4) 제약 파일 핵심

### 4-1. 공통 베이스 제약 (두 파일 공통)
- `my_clk` 3.0ns, waveform `{0 1.2}`
- `set_clock_latency`(source 0.7ns, network 0.3ns)
- `set_clock_uncertainty -setup 0.15`
- `set_clock_transition -max 0.12`
- input/output delay (`data*`, `sel`, `out1/2/3`, `Cin*`, `Cout`)
- 환경 제약:
  - driving cell (`bufbd1`)
  - input transition (`Cin*` 0.12ns)
  - output load (`out*`/`Cout*`)

### 4-2. 차이점 A: `MY_DESIGN.con`
- 네거티브 엣지 추가 제약을 **기존 `my_clk`에 포함**해 모델링.
- 입력은 `-add_delay -clock_fall` + `-network_latency_included -source_latency_included` 사용.
- 출력도 동일 개념으로 포함해 모델링하며, 계산 결과로 음수 output delay(`-0.94`)를 사용.

### 4-3. 차이점 B: `MY_DESIGN_w_vclk.con`
- 네거티브 엣지 경로를 **가상 클럭으로 분리**해 모델링.
- `F4_clk` 생성 후 `sel` 입력 추가 지연 적용.
- `F5_clk` 생성 후 `out1` 출력 추가 지연 적용.
- 즉, 포함(included) 옵션 대신 별도 캡처 클럭 정의로 의도를 명확히 분리.

## 5) RTL 구조 요약 (`rtl/MY_DESIGN.v`)
- Top `MY_DESIGN`은 `ARITH`, `COMBO` 하위 모듈 포함.
- 순차 블록(`posedge clk`)에서 `R1~R4` 갱신.
- 조합 블록에서 `out1/out2/out3` 계산.
- `ARITH`: `sel`에 따라 add/sub.
- `COMBO`: `Cin1/Cin2` 기반 조합 출력 `Cout` 생성.

## 6) 검토 시 주의 포인트
1. 조합 always 블록에서 nonblocking(`<=`) 사용
- `always @ (out2, R1, R3, R4)` 내부 `out1/out2/out3 <= ...`
- 일반적으로 조합 블록은 `always @*` + blocking(`=`) 권장.

2. `out3 <= out2 - R3` 의존성
- 같은 블록에서 `out2 <= R3 & R4`를 먼저 기술했더라도 nonblocking 특성상 `out3` 계산 시 이전 `out2` 값 영향 가능.

3. `ARITH` case의 default 부재
- `sel`이 X/Z 상태일 때 시뮬레이션 해석이 불명확할 수 있음.

## 7) 결론
`lab7`의 본질은 같은 네거티브 엣지 타이밍 요구사항을
1) 단일 클럭에 latency 포함 방식으로 표현하는 법과
2) 가상 클럭으로 분리해 표현하는 법
두 가지로 비교 학습하는 데 있습니다.
