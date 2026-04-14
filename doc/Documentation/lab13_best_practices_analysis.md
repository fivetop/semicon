# lab13_best_practices 분석

작성일: 2026-03-08
대상 경로: /DATA/home/edu118/PT_2016.06/lab13_best_practices

## 1) 요약
- 전체 용량: 약 7.7M
- 총 파일 수: 192개
- 주요 목적: ORCA PrimeTime 분석에서 권장 체크 흐름과 로그 관리 방식 학습

## 2) 디렉토리 구조
- /DATA/home/edu118/PT_2016.06/lab13_best_practices/.synopsys_pt.setup
- /DATA/home/edu118/PT_2016.06/lab13_best_practices/logs
- /DATA/home/edu118/PT_2016.06/lab13_best_practices/orca_savesession
- /DATA/home/edu118/PT_2016.06/lab13_best_practices/parasitics_command.log

## 3) 실행 흐름 (logs/RUN.tcl)
핵심 스크립트: `/DATA/home/edu118/PT_2016.06/lab13_best_practices/logs/RUN.tcl`

실행 단계:
1. 환경 설정 및 라이브러리 로드 (`search_path`, `link_path`)
2. `source ../ref/scripts/orca_pt_variables.tcl`
3. `set link_keep_unconnected_cells true` 적용
4. `read_verilog orca_routed.v.gz`, `link_design ORCA`
5. `read_parasitics ORCA.SPEF.gz`
6. `check_timing`, `report_analysis_coverage`
7. `save_session ./orca_savesession`
8. 경고/정보를 `logs/ORCA_EW.log`로 리다이렉트

## 4) Best Practices 성격의 포인트
- `suppress_message {DES-023}`: 실습 중 불필요 노이즈 최소화
- `set link_keep_unconnected_cells true`: 링크 시 비연결 셀 유지
- 리포트 파일 분리 저장:
  - `logs/ORCA_EW.log` (에러/경고)
  - `logs/ORCA_sta.rpt` (STA 커버리지)
- 종료 전 `print_message_info`로 메시지 집계

## 5) run.log에서 확인된 핵심 명령/검증
`/DATA/home/edu118/PT_2016.06/lab13_best_practices/logs/run.log` (1370 lines)
- `set_clock_gating_check` (setup/hold + high/low)
- `set_false_path` (SDRAM DQ enable 경로)
- `PLL_SHIFT` (PCI/SD PLL 경로)
- `check_timing`, `report_analysis_coverage`, `report_timing`
- `save_session ./orca_savesession`

## 6) 분석 리포트 요약
`/DATA/home/edu118/PT_2016.06/lab13_best_practices/logs/ORCA_sta.rpt`
- All Checks: 29399
- Met: 15651 (53%)
- Violated: 138
- Untested: 13610 (46%)
- out_hold 위반 비율이 높음 (39/75)

## 7) 메시지/경고 요약
run.log 종료부 기준:
- Diagnostics summary: 378 warnings, 196 informationals
- 주요 경고: `RC-009`, `RC-004`
- suppress 적용 메시지: `RC-009`, `PTE-060`, `PTE-003`, `CMD-029`, `ENV-003`

## 8) Parasitics 로그 특징
`/DATA/home/edu118/PT_2016.06/lab13_best_practices/parasitics_command.log`
- SPEF 주석 결과:
  - Annotated nets: 22678
  - Annotated capacitances: 101979
  - Annotated resistances: 79301
- Boundary/port nets 중 일부는 not annotated로 표시되어 후속 점검 포인트 제공

## 9) save_session 데이터 구성
`/DATA/home/edu118/PT_2016.06/lab13_best_practices/orca_savesession`:
- `mod*`: 93개
- `nmp*`: 89개
- 기타: 4개 (`README`, `cmd_log`, `lib_map`, `ndx`)
- 세션 README 기준 PrimeTime 버전: L-2016.06-SP2

## 10) 결론
`lab13_best_practices`는 단순 타이밍 실행보다,
노이즈 억제(suppress), 로그 분리, 체크 자동화, 세션 저장 등
실무형 PrimeTime 운영 습관을 강조하는 실습 폴더입니다.
구조적으로는 리포트 문서 + save_session 복원 데이터가 함께 제공됩니다.
