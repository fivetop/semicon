# lab8_clocks 분석

작성일: 2026-03-08
대상 경로: /DATA/home/edu118/PT_2016.06/lab8_clocks

## 1) 요약
- 전체 용량: 약 6.2M
- 총 파일 수: 190개
- 주요 목적: PrimeTime 클록 분석(STA) 실습 및 세션 재현

## 2) 디렉토리 구조
- /DATA/home/edu118/PT_2016.06/lab8_clocks/.solutions
- /DATA/home/edu118/PT_2016.06/lab8_clocks/scripts
- /DATA/home/edu118/PT_2016.06/lab8_clocks/orca_savesession
- /DATA/home/edu118/PT_2016.06/lab8_clocks/RUN.tcl
- /DATA/home/edu118/PT_2016.06/lab8_clocks/.synopsys_pt.setup

## 3) 실행 플로우 (RUN.tcl)
1. ORCA 라우팅 넷리스트(`orca_routed.v.gz`)를 읽고 `ORCA` 디자인 링크
2. 파라시틱(`ORCA.SPEF.gz`) 로드 및 annotation 보고
3. `orca_pt_constraints.tcl` 제약 적용 후 `check_timing`
4. `timing_remove_clock_reconvergence_pessimism` 활성화 후 `update_timing`
5. `report_analysis_coverage`, `report_constraint -all` 수행
6. `save_session ./orca_savesession`으로 세션 저장

## 4) 핵심 설정 파일
- `.synopsys_pt.setup`
  - PrimeTime alias, history, suppress_message, tcl_procs 로드 등 공통 환경 설정
- `scripts/orca_pt_variables.tcl` (실습용)
  - `sh_script_stop_severity none` 등 완화된 동작 설정
- `.solutions/orca_pt_variables.tcl` (정답/참고)
  - `sh_script_stop_severity E`
  - `timing_all_clocks_propagated true`
  - `lappend timing_check_defaults ideal_clocks`

## 5) 세션 데이터 구성 (orca_savesession)
- 용량: 약 6.1M (lab8_clocks 대부분 차지)
- 파일 패턴 집계:
  - `mod*`: 93개
  - `nmp*`: 89개
  - 기타 4개: `README`, `cmd_log`, `lib_map`, `ndx`

해석:
- 이 폴더는 리포트 문서 모음보다 PrimeTime 세션 복원/재실행용 데이터가 중심입니다.

## 6) 결론
`lab8_clocks`는 ORCA 설계의 클록 중심 STA 실습 폴더이며,
실습용 변수 스크립트와 정답 스크립트의 설정 차이를 통해
클록 전파 및 타이밍 체크 정책의 영향을 학습하도록 구성되어 있습니다.
