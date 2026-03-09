# lab8 분석 정리

## 1) 실습 목표
`romee/lab8`는 RTL 합성 실습이 아니라, 이미 준비된 설계(`EXCEPTIONS.ddc`)에 타이밍 예외 제약을 적용하고 검증하는 실습입니다.

핵심 학습 포인트:
1. 가상 클럭(virtual clock) 추가
2. `set_clock_groups`/`set_false_path` 예외 설정
3. `set_multicycle_path`(setup/hold) 설정
4. 제약 적용 전후 리포트 확인
5. 최종 SDC 내보내기(`write_sdc`)

## 2) 폴더 구성
- `.synopsys_dc.setup`
- `common_setup.tcl`
- `dc_setup.tcl`
- `.solutions/dc.tcl`
- `.solutions/EXCEPTIONS.sdc`
- `EXCEPTIONS.ddc`

특징:
- `lab8`에는 RTL 소스가 없고, `ddc` 기반으로 예외 제약 실습을 진행합니다.

## 3) 실행 흐름 (`.solutions/dc.tcl`)

1. `read_ddc EXCEPTIONS.ddc`
2. `current_design EXCEPTIONS`
3. `link`
4. 초기 `report_constraint -all`, `report_timing`
5. `vclk` 생성 및 I/O `-add_delay` 적용
6. `set_clock_group -logically_exclusive -group clk -group vclk`
7. `set_false_path -setup` 경로 예외 적용
8. `set_multicycle_path 2 -setup -to mul_result_reg*/D`
9. `set_multicycle_path 1 -hold -to mul_result_reg*/D`
10. 최종 `report_constraint -all`
11. `write_sdc EXCEPTIONS.sdc`

## 4) 예외 제약 핵심 내용

### 4-1. 가상 클럭 기반 I/O 지연
- `create_clock -name vclk -period 6`
- 입력 포트(`coeff*`, `adr_i*`)에 `set_input_delay 0 -clock vclk -add_delay`
- 출력 포트에 `set_output_delay 0 -clock vclk -add_delay`

의미:
- 기존 `clk` 제약 외에 추가적인 타이밍 관점을 `vclk`로 병행 모델링.

### 4-2. 클럭 그룹 예외
- `set_clock_group -logically_exclusive -group clk -group vclk`
- 대안으로 상호 `set_false_path`를 쓰는 방법도 스크립트 주석에 제시됨.

의미:
- `clk`와 `vclk` 사이의 상호 경로를 타이밍 분석 대상에서 분리.

### 4-3. 경로 기반 false path
- `set_false_path -setup -from [get_clocks clk] -through $in_ports -through [all_outputs] -to [get_clocks clk]`

의미:
- 특정 setup 경로를 분석 대상에서 제외해 불필요한 위반 보고를 줄임.

### 4-4. 멀티사이클 경로
- setup: `set_multicycle_path 2 -setup -to mul_result_reg*/D`
- hold: `set_multicycle_path 1 -hold -to mul_result_reg*/D`

의미:
- setup 완화 시 hold 보정을 함께 넣어야 제약 일관성 유지 가능.

## 5) `EXCEPTIONS.sdc` 결과 관찰 포인트
`.solutions/dc.tcl` 실행 후 생성된 `.solutions/EXCEPTIONS.sdc`에는 다음이 반영됩니다.

- 기본/가상 클럭 정의 (`clk`, `vclk`)
- `set_clock_groups -logically_exclusive`
- `set_false_path -setup`
- `set_multicycle_path` setup/hold
- 포트별 input/output delay (`-add_delay` 포함)
- 일부 net load/resistance 정보

즉, 실습에서 설정한 타이밍 예외가 표준 SDC로 구체화됩니다.

## 6) lab8의 의미
`lab8`은 "합성 결과 개선"보다 "올바른 예외 제약 정의와 검증"에 집중한 실습입니다.
실무 STA에서 자주 쓰는 예외 제약 패턴을 안전하게 적용하고, 리포트로 영향도를 확인하는 방법을 익히는 단계입니다.
