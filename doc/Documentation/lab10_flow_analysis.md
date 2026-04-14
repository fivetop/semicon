# lab10_flow 분석

작성일: 2026-03-08
대상 경로: /DATA/home/edu118/PT_2016.06/lab10_flow

## 1) 요약
- 전체 용량: 약 6.2M
- 총 파일 수: 191개
- 주요 목적: PrimeTime RM(Reference Methodology) 기반 STA 플로우 실습 및 세션 재현

## 2) 디렉토리 구조
- /DATA/home/edu118/PT_2016.06/lab10_flow/.solutions
- /DATA/home/edu118/PT_2016.06/lab10_flow/pt_scripts
- /DATA/home/edu118/PT_2016.06/lab10_flow/orca_savesession
- /DATA/home/edu118/PT_2016.06/lab10_flow/joe_project_dir
- /DATA/home/edu118/PT_2016.06/lab10_flow/common_setup.tcl
- /DATA/home/edu118/PT_2016.06/lab10_flow/pt_setup.tcl
- /DATA/home/edu118/PT_2016.06/lab10_flow/.synopsys_pt.setup

## 3) 핵심 스크립트 역할
- `common_setup.tcl`
  - 공통 변수 정의: DESIGN_NAME=ORCA, ref 경로, 라이브러리/링크 설정
- `pt_setup.tcl`
  - 런타임 설정: reports 디렉토리 생성, 넷리스트/파라시틱/제약 파일 목록 지정
- `pt_scripts/pt.tcl`
  - RM 스타일 메인 실행 스크립트
  - read_verilog -> link_design -> read_parasitics -> 제약 적용 -> update_timing/check_timing -> 리포트 생성
- `.solutions/run.tcl`
  - 실습 정답용 간소 실행 스크립트
  - 읽기/링크/파라시틱/제약 후 save_session 수행

## 4) 세션 데이터 구성
`orca_savesession` 분석:
- 용량: 약 6.1M (폴더 대부분)
- 패턴별 파일 수:
  - `mod*`: 93개
  - `nmp*`: 89개
  - 기타: 4개 (`README`, `cmd_log`, `lib_map`, `ndx`)

해석:
- 보고서 텍스트 저장소라기보다 PrimeTime save_session 복원 데이터 중심 구조입니다.

## 5) 특이사항
- `pt_scripts/pt.tcl`은 "Save Session" 섹션 헤더는 있으나, 파일 내 명시적 `save_session`/`quit` 구문이 보이지 않습니다.
- 반면 `.solutions/run.tcl`에는 `save_session orca_savesession`이 포함되어 있어 교육용/정답용 실행 차이가 존재합니다.
- `joe_project_dir`는 현재 비어 있습니다.

## 6) 결론
`lab10_flow`는 ORCA 설계를 대상으로 PrimeTime RM 방식의 표준 STA 절차를 학습하는 폴더이며,
실행 스크립트, 공통 설정, 세션 스냅샷 데이터가 분리되어 있어 플로우 구성 요소를 단계적으로 이해하기 좋게 구성되어 있습니다.
