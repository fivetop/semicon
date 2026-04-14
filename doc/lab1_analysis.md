# lab1 분석 정리

## 1) lab1 전체 성격
`lab1`은 Design Compiler 실습의 입문 단계로, 환경 설정 파일과 간단한 RTL(`TOP.v`)을 통해 제어 FSM + PC 업데이트 구조를 익히는 구성입니다.

## 2) 폴더 요약
- `.synopsys_dc.setup`: DC 시작 설정, alias, 공통 스크립트 source
- `common_setup.tcl`: 라이브러리/경로 변수 정의
- `dc_setup.tcl`: logical/milkyway/tluplus 적용
- `rtl/TOP.v`: Verilog 설계(Top + FSM + DECODE + COUNT)
- `rtl/TOP.vhd`: 대응 VHDL 버전
- `scripts/TOP.con`: 제약 파일
- `mapped/`, `unmapped/`, `work/`: 합성/중간 산출물 디렉터리

## 3) `rtl/TOP.v` 구조 분석

### 3-1. 상위 연결 (`TOP`)
`TOP`은 3개의 하위 모듈을 인스턴스합니다.

1. `FSM`: 현재 상태 생성
2. `DECODE`: 명령/플래그 기반 PC 제어 신호 생성
3. `COUNT`: PC 실제 갱신

신호 흐름:
- `FSM.CurrentState` -> `DECODE.CurrentState`
- `DECODE.Incrmnt_PC/Ld_Brnch_Addr/Ld_Rtn_Addr` -> `COUNT`
- `COUNT.PC` -> top 출력 `PC`

### 3-2. 상태기계 (`FSM`)
상태 전이 순서:
- `RESET_STATE -> FETCH_INSTR -> READ_OPS -> EXECUTE -> WRITEBACK -> FETCH_INSTR`

Reset 시 `Current_State`는 `RESET_STATE`로 강제되고, 이후 클럭마다 `Next_State`를 따라갑니다.

### 3-3. 디코더 (`DECODE`)
역할:
- instruction 조건 비트(`Crnt_Instrn[23:16]` 등)와 ALU 플래그를 바탕으로 branch 수행 여부(`Take_Branch`)를 판단
- `WRITEBACK` 단계에서만 PC 제어 신호를 출력

출력 제어 의도:
- branch/call 조건 만족 시 `Ld_Brnch_Addr=1`
- return 명령이면 `Ld_Rtn_Addr=1`
- branch/return이 아니면 `Incrmnt_PC=1`

### 3-4. 프로그램 카운터 (`COUNT`)
`posedge Clk`에서 다음 우선순위로 `PCint`를 갱신합니다.

1. `Reset` -> `0`
2. `Incrmnt_PC` -> `PC + 1`
3. `Ld_Rtn_Addr` -> `Return_Addr`
4. `Ld_Brnch_Addr` -> `Imm_Addr`

## 4) 합성/검증 관점 주의 포인트

1. 조합 always 블록에서 nonblocking(`<=`) 사용
- `FSM`의 next-state 조합 블록, `DECODE` 조합 블록 모두 `<=`를 많이 사용합니다.
- 일반적으로 조합 로직은 `always @*` + blocking(`=`) 스타일이 더 안전합니다.

2. 같은 조합 블록 내 신호 의존성 문제 가능
- `DECODE`에서 `Take_Branch`, `Brnch_Addr`, `Rtn_Addr`를 갱신한 뒤 같은 블록에서 다시 참조합니다.
- nonblocking 특성상 이전 값이 사용되어 시뮬레이션 의도와 어긋날 여지가 있습니다.

3. 민감도 리스트 수동 나열
- `always @(...)` 수동 나열 방식이라 신호 누락 시 시뮬레이션 mismatch 위험이 있습니다.
- `always @*`로 바꾸는 것이 유지보수에 유리합니다.

4. `COUNT` 우선순위 의존성
- 현재 로직은 `Incrmnt_PC`가 `Ld_Rtn_Addr/Ld_Brnch_Addr`보다 먼저 검사됩니다.
- 설계 의도상 decode에서 increment를 0으로 제어해 충돌을 피하지만, 제어신호 버그가 생기면 우선순위 이슈가 발생할 수 있습니다.

## 5) 결론
`lab1/rtl/TOP.v`는 교육용으로 FSM-Decode-PC 경로를 분리해 이해하기 좋은 구조입니다.
다만 실무 합성/검증 품질을 높이려면 조합 블록 코딩 스타일(`always @*`, blocking/nonblocking 정리)과 제어신호 의존성을 개선하는 것이 좋습니다.