# lab12_pba 분석

작성일: 2026-03-08
대상 경로: /DATA/home/edu118/PT_2016.06/lab12_pba

## 1) 요약
- 전체 용량: 약 6.2M
- 총 파일 수: 189개
- 주요 목적: PrimeTime STA 기반 PBA(Path-Based Analysis) 실습 준비/세션 재현

## 2) 디렉토리 구조
- /DATA/home/edu118/PT_2016.06/lab12_pba/.synopsys_pt.setup
- /DATA/home/edu118/PT_2016.06/lab12_pba/RUN.tcl
- /DATA/home/edu118/PT_2016.06/lab12_pba/scripts/orca_pt_variables.tcl
- /DATA/home/edu118/PT_2016.06/lab12_pba/orca_savesession

## 3) 실행 플로우 (RUN.tcl)
1. search_path/link_path 설정, `scripts/orca_pt_variables.tcl` 로드
2. `read_verilog orca_routed.v.gz` + `link_design ORCA`
3. `read_parasitics ORCA.SPEF.gz` + `report_annotated_parasitics`
4. `source orca_pt_constraints.tcl` + `check_timing`
5. `set timing_remove_clock_reconvergence_pessimism true` 후 `update_timing`
6. `report_analysis_coverage`, `report_constraint -all`
7. `save_session ./orca_savesession`

## 4) 설정 파일 특징
- `.synopsys_pt.setup`
  - alias/history/suppress_message 설정
  - `../ref/tcl_procs/*.tcl` 자동 로드
- `scripts/orca_pt_variables.tcl`
  - `sh_continue_on_error false`, `sh_script_stop_severity E`
  - `link_create_black_boxes false`
  - 스크립트 실패 시 중단되는 보수적 설정

## 5) save_session 데이터 구성
`/DATA/home/edu118/PT_2016.06/lab12_pba/orca_savesession`:
- `mod*`: 93개
- `nmp*`: 89개
- 기타: 4개 (`README`, `cmd_log`, `lib_map`, `ndx`)
- README 기준 PrimeTime 버전: L-2016.06-SP2

## 6) 관찰 포인트 (PBA 관점)
- 폴더명은 `lab12_pba`이지만, `RUN.tcl`과 `cmd_log`(26 lines)에는
  명시적인 `-pba_mode` 옵션 호출이 직접 보이지 않습니다.
- 따라서 이 랩은 기본 STA/세션 로드를 먼저 수행한 뒤,
  저장 세션에서 PBA 명령을 추가 실습하는 형태일 가능성이 큽니다.

## 7) 용량 상위 파일
- `mod24`: 약 1133.5 KB
- `mod29`: 약 460.8 KB
- `mod26`: 약 383.0 KB
- `mod11a`: 약 315.4 KB
- `mod28`: 약 232.2 KB

## 8) 결론
`lab12_pba`는 ORCA 설계에 대해 제약/타이밍 갱신까지 수행한 상태를
세션으로 저장해 두고, 이후 PBA 중심 분석을 진행할 수 있도록 구성된 실습 폴더입니다.
구조적으로는 리포트 문서 저장소보다는 save_session 복원 데이터 비중이 큽니다.
