# lab11_specific 분석

작성일: 2026-03-08
대상 경로: /DATA/home/edu118/PT_2016.06/lab11_specific

## 1) 요약
- 전체 용량: 약 7.7M
- 총 파일 수: 191개
- 주요 목적: ORCA 설계의 PrimeTime 특정 제약/체크 시나리오 실습 (로그 중심)

## 2) 디렉토리 구조
- /DATA/home/edu118/PT_2016.06/lab11_specific/.synopsys_pt.setup
- /DATA/home/edu118/PT_2016.06/lab11_specific/logs
- /DATA/home/edu118/PT_2016.06/lab11_specific/orca_savesession

## 3) 로그 기반 실행 흐름
핵심 실행 스크립트: `/DATA/home/edu118/PT_2016.06/lab11_specific/logs/RUN.tcl`

실행 단계:
1. search_path/link_path 설정, 공통 변수 로드(`../ref/scripts/orca_pt_variables.tcl`)
2. `read_verilog orca_routed.v.gz` + `link_design ORCA`
3. `read_parasitics ORCA.SPEF.gz`
4. `remove_annotated_parasitics [get_nets -of_objects [get_ports *]]`
5. `source orca_pt_constraints.tcl` + `check_timing`
6. `report_analysis_coverage`를 `logs/ORCA_sta.rpt`에 저장
7. `save_session ./orca_savesession`

## 4) lab11 실습 포인트 (run.log 기준)
`/DATA/home/edu118/PT_2016.06/lab11_specific/logs/run.log`에서 확인된 핵심 주제:
- clock gating check 설정
  - `set_clock_gating_check -setup/-hold`
  - mux 입력 핀별 high/low gating check
- false path 설정
  - SDRAM DQ output enable 경로 false path 지정
- PLL 위상 관련 처리
  - `PLL_SHIFT I_CLOCK_GEN/I_PLL_PCI ...`
  - `PLL_SHIFT I_CLOCK_GEN/I_PLL_SD ...`
- 제약/리포트 중심 검증
  - `check_timing`, `report_analysis_coverage`, 다수 `report_timing`

## 5) 결과 리포트
`/DATA/home/edu118/PT_2016.06/lab11_specific/logs/ORCA_sta.rpt` 요약:
- All Checks: 29399
- Met: 15651 (53%)
- Violated: 138
- Untested: 13610 (46%)
- out_hold 위반 비율이 상대적으로 높음 (39/75)

## 6) 메시지/경고 특성
run.log 종료부 요약:
- Diagnostics summary: 506 warnings, 199 informationals
- 주요 경고 코드: `RC-009`, `RC-004`
- 일부 메시지(`PTE-060`, `PTE-003`, `ENV-003`)는 suppress 설정 적용

## 7) 세션 데이터 구성
`/DATA/home/edu118/PT_2016.06/lab11_specific/orca_savesession`:
- `mod*`: 93개
- `nmp*`: 89개
- 기타: 4개 (`README`, `cmd_log`, `lib_map`, `ndx`)
- 세션 README 기준 PrimeTime 버전: L-2016.06-SP2

## 8) 결론
`lab11_specific`은 단순 플로우 실행보다 clock gating, false path, PLL shift 같은
특정 STA 제약 검증 항목을 깊게 다루는 실습 폴더입니다.
구조상 리포트 텍스트보다 save_session 복원 데이터 비중이 크며,
실제 학습 포인트는 `logs/RUN.tcl`과 `logs/run.log`에 집중되어 있습니다.
