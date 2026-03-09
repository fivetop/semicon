# lab3 분석 정리

## 1) 실습 목표
`romee/lab3`는 Design Compiler(DC)에서 다음 순서의 기본 합성 흐름을 연습하는 실습입니다.

1. 라이브러리/환경 설정
2. RTL 읽기 및 링크
3. 타이밍 제약 적용
4. 타이밍/클럭/포트 리포트 확인
5. `ddc` 산출물 저장

## 2) 폴더 구성
- `.synopsys_dc.setup`
- `common_setup.tcl`
- `dc_setup.tcl`
- `.solutions/dc.tcl`
- `.solutions/MY_DESIGN.con`
- `rtl/MY_DESIGN.v`
- `scripts/` (write_script 출력 위치)
- `unmapped/` (`MY_DESIGN.ddc` 출력 위치)

## 3) 초기 설정 파일 역할

### `.synopsys_dc.setup`
- DC 시작 시 자동 실행되는 초기화 파일.
- `common_setup.tcl`와 `dc_setup.tcl`를 source.
- alias(`rc`, `rt`, `ra`, `rq`) 및 메시지 suppress 설정.

핵심 라인:
- `source common_setup.tcl`
- `source dc_setup.tcl`

### `common_setup.tcl`
- 논리/물리 라이브러리 관련 변수 정의.
- 주요 값:
  - `TARGET_LIBRARY_FILES = sc_max.db`
  - `SYMBOL_LIBRARY_FILES = sc.sdb`
  - `MW_DESIGN_LIB = MY_DESIGN_LIB`
  - `TECH_FILE`, `TLUPLUS_MAX_FILE`, `MAP_FILE` 경로

### `dc_setup.tcl`
- `search_path`, `target_library`, `link_library`, `symbol_library`를 실제 앱 변수로 반영.
- Milkyway design library가 없으면 생성, 있으면 열어서 재사용.
- `set_tlu_plus_files`로 RC 모델(TLU+) 연결.

## 4) 메인 실행 스크립트 흐름 (`.solutions/dc.tcl`)

1. `read_db sc_max.db`
2. `list_libs`
3. `report_lib`를 `lib.rpt`로 저장
4. `read_verilog MY_DESIGN.v`
5. `current_design MY_DESIGN`
6. `link` -> `check_design`
7. `source .solutions/MY_DESIGN.con`
8. `check_timing`, `report_clock`, `report_clock -skew`, `report_port -verbose`
9. `write_script -out scripts/MY_DESIGN.wscr`
10. `write_file -format ddc -hier -out unmapped/MY_DESIGN.ddc`

즉, 이 lab3는 compile 단계보다도 "환경/제약 인지 + 기본 검증 리포트"에 초점이 있습니다.

## 5) 제약 파일 요약 (`.solutions/MY_DESIGN.con`)

- `reset_design`으로 기존 제약 초기화
- 클럭 정의:
  - `create_clock -period 3.0 [get_ports clk]` (333 MHz)
  - source latency: `0.7ns`
  - network latency: `0.3ns`
  - setup uncertainty: `0.15ns`
  - clock transition max: `0.12ns`
- 입력 지연:
  - `data*`: `0.45ns`
  - `sel`: `0.4ns`
- 출력 지연:
  - `out1`: `0.5ns`
  - `out2`: `2.04ns`
  - `out3`: `0.4ns`
- 조합 경로 제약:
  - `Cin*` 입력 `0.3ns`
  - `Cout` 출력 `0.1ns`

## 6) RTL 구조 요약 (`rtl/MY_DESIGN.v`)

### Top: `MY_DESIGN`
- 하위 모듈:
  - `ARITH U1_ARITH` (data1/data2 기반 add/sub)
  - `COMBO U_COMBO` (Cin1/Cin2 기반 조합 출력)
- 순차 블록(`posedge clk`): `R1~R4` 레지스터 갱신
- 조합 블록: `out1`, `out2`, `out3` 계산

### Submodule: `ARITH`
- `sel=0`: `a+b`
- `sel=1`: `a-b`

### Submodule: `COMBO`
- 내부 `ARITH` 결과(`arth_o`)와 `Cin1`을 더해 `Cout` 생성

## 7) 검토 시 주의 포인트

1. 조합 always 블록에서 nonblocking(`<=`) 사용
- 코드: `always @ (out2, R1, R3, R4)` 내부 `out1/out2/out3 <= ...`
- 일반적으로 조합 논리는 `always @*` + blocking(`=`)을 더 권장.

2. `out3 <= out2 - R3`의 의존성
- 같은 블록에서 `out2 <= R3 & R4`를 먼저 기술했어도 nonblocking 특성상 `out3` 계산 시점에는 이전 `out2`가 사용될 수 있음.

3. `ARITH` case문 default 없음
- `sel`이 X/Z 상태일 때 시뮬레이션 경고 또는 예기치 않은 동작 가능.

## 8) 결론
lab3는 "DC 환경 설정 + 제약 적용 + 기본 타이밍 리포트 확인"을 익히는 실습입니다.
실무 관점에서는 조합 로직 스타일(민감도 리스트, blocking/nonblocking)과 case default 보완 여부를 함께 점검하는 것이 좋습니다.
