# PT_2016.06 폴더 분석

작성일: 2026-03-08
경로: /DATA/home/edu118/PT_2016.06

## 1) 개요
- 이 디렉토리는 Synopsys PrimeTime 교육용 실습 패키지입니다.
- README에는 "PrimeTime Lab Notes Rev 2016.06"로 표기되어 있습니다.
- README 기준 대상 툴 버전은 PrimeTime 2016.06-SP2입니다.

## 2) 최상위 구조
- README
- setup.csh
- ref/
- lab1-6_reports/
- lab8_clocks/
- lab10_flow/
- lab11_specific/
- lab12_pba/
- lab13_best_practices/
- 숨김 설정/테스트 파일: .setup.modules, .testscript, .TestMaster/

## 3) 디렉토리 트리 (깊이 2)
- lab1-6_reports/orca_savesession
- lab10_flow/joe_project_dir
- lab10_flow/orca_savesession
- lab10_flow/pt_scripts
- lab11_specific/logs
- lab11_specific/orca_savesession
- lab12_pba/orca_savesession
- lab12_pba/scripts
- lab13_best_practices/logs
- lab13_best_practices/orca_savesession
- lab8_clocks/orca_savesession
- lab8_clocks/scripts
- ref/design_data
- ref/libs
- ref/scripts
- ref/scripts_pt1
- ref/tcl_procs

## 4) 용량 요약
- setup.csh: 4.0K
- README: 8.0K
- lab10_flow: 6.2M
- lab12_pba: 6.2M
- lab8_clocks: 6.2M
- lab1-6_reports: 7.5M
- lab11_specific: 7.7M
- lab13_best_practices: 7.7M
- ref: 12M

## 5) 핵심 메모
- 이 데이터셋은 클록 분석, 플로우 실행, PBA, 베스트 프랙티스 등 STA 워크플로우 중심으로 구성되어 있습니다.
- "ref/"가 가장 큰 폴더이며, 여러 실습에서 공통으로 사용하는 라이브러리와 스크립트를 포함할 가능성이 큽니다.
- 각 lab 폴더에 세션 저장본과 스크립트가 있어, 실습형 교육 구성임을 확인할 수 있습니다.

## 6) 권장 시작 순서
1. README를 먼저 읽고 setup.csh를 실행합니다.
2. ref/ (libs, tcl_procs)에서 공통 환경 구성을 확인합니다.
3. PrimeTime 핵심 플로우 이해를 위해 lab8_clocks, lab10_flow부터 시작합니다.
4. 이후 lab11_specific, lab12_pba, lab13_best_practices 순서로 진행합니다.
