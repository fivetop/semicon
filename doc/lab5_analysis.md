# lab5 분석 정리

## 1) 실습 목표
`romee/lab5`는 Design Compiler 기본 합성에서 한 단계 나아가, 고급 최적화 옵션과 리타이밍(retiming), 물리 제약(physical constraints), 증분 컴파일(incremental compile)까지 다루는 실습입니다.

핵심 학습 포인트:
1. 경로 그룹별 최적화 우선순위 설정
2. 블록 단위 retiming 허용/금지 제어
3. `compile_ultra -spg -retime -scan` 적용
4. 증분 컴파일로 제약 위반 개선
5. 물리 제약 보고(`report_physical_constraints`)

## 2) 폴더 구성
- `.synopsys_dc.setup`
- `common_setup.tcl`
- `dc_setup.tcl`
- `.solutions/dc.tcl`
- `.solutions/dc_w_check_expl.tcl`
- `rtl/STOTO.v`
- `scripts/STOTO.con`
- `scripts/STOTO.pcon`
- `scripts/fm.tcl`
- `num_cores.sh`
- `mapped/`, `unmapped/` (산출물 저장 위치)

## 3) 메인 실행 흐름 (`.solutions/dc.tcl`)

1. `set_svf STOTO.svf`
2. `read_verilog STOTO.v`
3. `current_design STOTO`
4. `link`, `check_design`
5. `source STOTO.con` -> `check_timing`
6. `source STOTO.pcon`
7. `report_clock` 후 path group 설정
8. ungroup/retime/dont_retime/cost priority 속성 설정
9. `compile_ultra -spg -retime -scan`
10. constraint/timing 리포트 저장
11. `mapped/STOTO.ddc` 저장
12. `compile_ultra ... -incremental` 재실행
13. `rc_incr_compile.rpt` 및 `report_physical_constraints`

## 4) 제약 파일 요약

### 4-1. 타이밍 제약 (`scripts/STOTO.con`)
- `create_clock -period 2.1 [get_ports clk]`
- `set_clock_uncertainty -setup 0.1`
- `set_clock_transition -max 0.05`
- 입력 포트별 개별 input delay 적용
  - 예: `a1` 1.9ns, `a2/b*/c*/d*` 0.2ns, `M` 0.05ns, `X` 0.2ns, `N` 0.3ns
- `set_driving_cell -max -no_design_rule -lib_cell inv0d1 [all_inputs]`
- 출력 제약:
  - `set_output_delay -max 0.2 [all_outputs]`
  - `set_load -max 0.5 [all_outputs]`

### 4-2. 물리 제약 (`scripts/STOTO.pcon`)
- 배치 영역 설정:
  - `set_placement_area -coordinate {0 0 150 100}`
- 배치 금지(blockage) 설정:
  - `create_placement_blockage -name Blockage1 -coordinate {0 80 20 100}`

## 5) 최적화 전략 포인트 (`dc.tcl`)
- 경로 그룹:
  - `clk` 그룹에 높은 가중치(`-weight 5`)와 critical range(`0.21`) 적용
  - I/O 경로는 별도 그룹(`INPUTS`, `OUTPUTS`, `COMBO`)으로 분리
- 계층/리타이밍 제어:
  - `INPUT`은 `set_ungroup ... false`로 계층 유지
  - `PIPELINE`은 `set_optimize_registers true -design PIPELINE`로 retiming 허용
  - `I_MIDDLE/I_PIPELINE/z_reg*`는 `set_dont_retime`로 이동 금지
  - `I_MIDDLE/I_DONT_PIPELINE`도 retiming 금지
- 비용 우선순위:
  - 1차는 `set_cost_priority -delay`로 setup 타이밍 우선
  - 2차 incremental 전 `set_cost_priority -default`로 DRC 우선 복귀

## 6) RTL 구조 요약 (`rtl/STOTO.v`)
- Top `STOTO`는 `INPUT -> MIDDLE -> OUTPUT` 구조
- `MIDDLE` 내부:
  - `PIPELINE` 블록: 2-stage 레지스터 파이프라인(`z1`, `z`)
  - `DONT_PIPELINE` 블록: `GLUE`, `ARITH`, `RANDOM` 조합
- 학습용 함정(trap):
  - `module INCORRECT;`가 함께 있어 `current_design STOTO`를 명시하지 않으면 잘못된 top으로 진행될 수 있음

## 7) 산출물/리포트
- `unmapped/STOTO.ddc`: 컴파일 전 저장본
- `mapped/STOTO.ddc`: 컴파일 후 저장본
- `rc_compile_ultra.rpt`: 1차 제약 리포트
- `rt_compile_ultra.rpt`: 1차 타이밍 리포트
- `rc_incr_compile.rpt`: 증분 컴파일 후 제약 리포트
- `STOTO.svf`: Formality용 SVF

## 8) 결론
`lab5`는 단순 제약 학습(lab3/lab4)에서 확장되어, 실무에 가까운 최적화 제어(경로 그룹, retiming 정책, 멀티코어, 증분 컴파일, 물리 제약 반영)를 체험하는 핵심 단계입니다.
