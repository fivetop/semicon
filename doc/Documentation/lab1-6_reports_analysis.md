# lab1-6_reports 분석

작성일: 2026-03-08
대상 경로: /DATA/home/edu118/PT_2016.06/lab1-6_reports

## 1) 요약
- 전체 용량: 약 7.5M
- 총 파일 수: 188개
- 주요 목적: PrimeTime labs 1-6 결과를 재현하기 위한 save_session 데이터 보관

## 2) 디렉토리 구조
- /DATA/home/edu118/PT_2016.06/lab1-6_reports/.solutions
- /DATA/home/edu118/PT_2016.06/lab1-6_reports/orca_savesession
- /DATA/home/edu118/PT_2016.06/lab1-6_reports/.synopsys_pt.setup

## 3) 핵심 구성 요소
- `.solutions/run.tcl`
  - labs 1-6 실행/재현용 PrimeTime 스크립트
  - `read_verilog orca_routed.v.gz`
  - `link_design ORCA`
  - `read_parasitics ORCA.SPEF.gz`
  - `source orca_pt_constraints.tcl`
  - `save_session orca_savesession`
- `.synopsys_pt.setup`
  - PrimeTime alias/로그/메시지 suppress 설정
  - `../ref/tcl_procs/*.tcl` 프로시저 로드
- `orca_savesession/README`
  - PrimeTime L-2016.06-SP2 세션 저장본 명시
  - Current Design: ORCA

## 4) 세션 데이터 패턴
`orca_savesession` 내부 파일 집계:
- `mod*`: 93개
- `nmp*`: 89개
- 기타: 4개 (`README`, `cmd_log`, `lib_map`, `ndx`)

해석:
- 텍스트 리포트 중심 폴더가 아니라, PrimeTime 세션 복구/재실행용 바이너리성 데이터가 중심입니다.

## 5) 용량 상위 파일
- `mod24`: 약 1134.6 KB
- `mod11a`: 약 897.4 KB
- `mod26`: 약 637.3 KB
- `mod29`: 약 460.8 KB
- `mod28`: 약 232.2 KB

## 6) 결론
이 폴더는 labs 1-6의 분석 결과를 "문서 형태"로 모아둔 저장소라기보다, ORCA 설계의 PrimeTime 세션 상태를 저장해 다시 열고 검증할 수 있게 만든 재현용 세션 데이터셋입니다.
