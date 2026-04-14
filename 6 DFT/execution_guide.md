# 4_ATPG 실행 가이드

## 1. 목적

이 문서는 `4_ATPG` 폴더에서 ATPG 플로우를 어떻게 실행하는지,
어떤 입력 데이터에 의존하는지, 결과물이 어디에 생성되는지,
실행 후 무엇을 확인해야 하는지를 설명한다.

## 2. 주요 진입점

셸 실행 진입점:

- `:run_tmax`

TetraMAX 내부 TCL 진입점:

- `0_Script/main.tcl`

환경 설정 파일:

- `setup.sh`

중요 사항:

- `setup.sh`는 `setenv`, `set path` 같은 csh 문법을 사용한다.
- `:run_tmax`도 csh shebang을 사용한다.
- 파일 이름은 `.sh`지만 실제로는 csh 기반 실행 환경으로 취급해야 한다.

## 3. 필수 입력 데이터

현재 플로우는 다음 입력 데이터에 의존한다.

### 3.1 설계 넷리스트

`:run_tmax`에서 다음과 같이 지정한다.

- `setenv NET ../3_DFT/2_Output/${ver}/ORCA_scan_comp.v`

### 3.2 SPF 파일

`0_run_atpg_setup.tcl`에서 다음 경로를 만든다.

- `../3_DFT/2_Output/${ver}/scan_comp.spf`
- `../3_DFT/2_Output/${ver}/scan_internal.spf`

### 3.3 공정 및 보조 라이브러리

`1_run_atpg_read_netlist.tcl`에서 다음 파일들을 읽는다.

- `../SAED32_EDK/lib/stdcell_rvt/verilog/saed32nm.tv`
- `./tmax_model/saed32nm_std_io_fc.tv`
- `./tmax_model/common.v`
- `../SAED32_EDK/lib/pll/verilog/PLL.v`

### 3.4 TetraMAX 실행 파일

`setup.sh`에서 `tool_path`를 설정하고,
`:run_tmax`는 `$tool_path/bin/tmax`를 호출한다.

## 4. :run_tmax 실행 변수 설명

`:run_tmax`는 환경 변수를 이용해 전체 실행 대상을 제어한다.

현재 값:

- `ver=03_1211_comp`
- `top=ORCA`
- `scan_comp=1`
- `NET=../3_DFT/2_Output/${ver}/ORCA_scan_comp.v`

각 변수의 의미는 다음과 같다.

### 4.1 `ver`

역할:

- 이번 실행의 버전 이름이다.
- 출력, 로그, 리포트 폴더 이름에 그대로 사용된다.

영향 받는 위치:

- `2_Output/${ver}`
- `3_Log/${ver}`
- `4_Report/${ver}`
- `../3_DFT/2_Output/${ver}`

실무 규칙:

- 새 실험을 할 때는 기존 값 재사용보다 새 버전명을 쓰는 편이 안전하다.
- 입력 버전과 출력 버전이 다르면 디버깅이 매우 어려워진다.

예시:

- `03_1211_comp`
- `03_0320_comp`

### 4.2 `top`

역할:

- TetraMAX가 처리할 최상위 모듈 이름이다.
- 내부적으로 `DESIGN_NAME`에 전달된다.

실무 규칙:

- 스캔 넷리스트 내부의 실제 top module 이름과 정확히 일치해야 한다.
- 값이 틀리면 `run_build_model ${DESIGN_NAME}` 단계에서 실패할 수 있다.

현재 예시:

- `ORCA`

### 4.3 `scan_comp`

역할:

- DRC 단계에서 어떤 SPF를 사용할지 결정한다.

값 의미:

- `1`: compression SPF 사용
- 그 외 값: internal SPF 사용

실제 동작 위치:

- `0_Script/3_run_atpg_drc.tcl`

실무 규칙:

- compression ATPG 흐름이면 `1`을 유지한다.
- 내부 scan 기준 검토가 필요할 때만 다른 값을 사용한다.

### 4.4 `NET`

역할:

- ATPG 대상 스캔 넷리스트 경로다.

현재 예시:

- `../3_DFT/2_Output/${ver}/ORCA_scan_comp.v`

실무 규칙:

- 반드시 `ver`와 같은 버전의 DFT 산출물을 가리키게 맞춘다.
- `top`과 `NET`이 서로 다른 설계 버전을 가리키면 흐름 분석이 꼬인다.

## 5. 표준 실행 절차

### 5.1 새 실행 버전 준비

새 실행을 시작하기 전 `:run_tmax`의 `ver` 값을 먼저 바꾼다.

예시 패턴:

- `03_0320_comp`
- `03_1211_comp`

이렇게 해야 이전 결과와 새 결과가 섞이지 않는다.

### 5.2 입력 준비 상태 확인

실행 전 다음 항목이 선택한 `ver`에 대해 존재하는지 확인한다.

1. `../3_DFT/2_Output/${ver}/` 아래 넷리스트
2. `scan_comp.spf`
3. `scan_internal.spf`
4. 공정 라이브러리 경로
5. `tmax_model/` 내부 파일

### 5.3 플로우 실행

셸 래퍼를 실행한다.

```csh
./:run_tmax
```

이 스크립트가 수행하는 일:

1. 실행 변수 export
2. `./setup.sh` 호출
3. 아래 폴더가 없으면 생성
   - `2_Output/${ver}`
   - `3_Log/${ver}`
   - `4_Report/${ver}`
4. 다음 명령으로 TetraMAX 실행

```csh
$tool_path/bin/tmax -64 -tcl -shell ./0_Script/main.tcl | tee 3_Log/${ver}/scan_dc.log
```

## 6. TetraMAX 내부 실행 순서

`main.tcl`은 다음 순서로 플로우를 수행한다.

1. `0_run_atpg_setup.tcl`
2. `1_run_atpg_read_netlist.tcl`
3. `2_run_atpg_build.tcl`
4. `3_run_atpg_drc.tcl`
5. `4_run_atpg_tmax2pt.tcl`
6. `5_run_atpg.tcl`
7. `6_run_atpg_write_patterns.tcl`
8. `7_run_atpg_reports.tcl`

## 7. 예상 결과물

### 7.1 `2_Output/${ver}`

패턴 및 타이밍 산출물:

- `*_compress_full.wgl`
- `*_compress_full.bin`
- `*_compress_full_serial.stil`
- `*_compress_short_serial.stil`
- `*_compress_full_parallel.stil`
- `*_compress_short_parallel.stil`
- `*_compress_shift.stil`
- `*_shift.tcl`
- `*_capture.tcl`
- `*.maxtb.v`
- `*.maxtb.dat`

### 7.2 `3_Log/${ver}`

실행 로그:

- `tmax_compress.log`
- `scan_dc.log`
- 반복 실행 시 회전 로그

### 7.3 `4_Report/${ver}`

coverage, fault, scan, mask 관련 리포트:

- `*_sa_faults.tmax`
- `*_sa_all_faults.tmax`
- `*.faults.rpt`
- `*.faults_AU.rpt`
- `*.faults_UD.rpt`
- `*.faults_ND.rpt`
- `*.scan_chains.rpt`
- `*.scan_cells.rpt`
- `*.nonscan_cells.rpt`
- `*.constraints.rpt`
- `*.coverage_level_16.rpt`
- `*_stuck_compressors.rpt`
- `*_stuck_lockup_latches.rpt`

## 8. 실행 후 점검 항목

실행 후 다음 항목을 확인한다.

1. `3_Log/${ver}/tmax_compress.log`가 생성되었는지
2. 로그가 fatal error에서 멈추지 않았는지
3. `2_Output/${ver}`에 STIL, WGL, binary, testbench 파일이 생성되었는지
4. `4_Report/${ver}`에 fault summary와 scan 리포트가 생성되었는지
5. coverage 리포트가 기대 수준으로 생성되었는지
6. compression 모드일 경우 compressor 리포트가 존재하는지

## 9. 운용 규칙

1. 덮어쓰기 의도가 없으면 기존 `ver`를 재사용하지 않는다.
2. `top`은 반드시 실제 스캔 넷리스트의 최상위 모듈명과 일치시킨다.
3. `NET`, `scan_comp.spf`, `scan_internal.spf`는 반드시 같은 DFT 버전에서 가져온다.
4. compression 플로우라면 `scan_comp=1`을 유지하고 compression SPF 유효성을 먼저 확인한다.
5. 과거 버전 폴더는 참고용으로만 보고 새 실험 결과를 덮어쓰지 않는다.

## 10. 자주 막히는 지점

### 10.1 외부 DFT 산출물 누락

`../3_DFT/2_Output/${ver}/` 아래에 필요한 넷리스트나 SPF가 없으면
실행은 시작되더라도 read 단계나 DRC 단계에서 실패한다.

### 10.2 라이브러리 경로 불일치

SAED 라이브러리 경로나 `tmax_model/` 내부 파일 경로가 잘못되면
넷리스트 import 초반에 실패한다.

### 10.3 top 이름 불일치

`top` 값이 실제 넷리스트의 top module 이름과 다르면
`run_build_model ${DESIGN_NAME}` 단계가 실패한다.

### 10.4 버전 혼선

`NET`은 한 버전을 가리키는데 결과 출력은 다른 `ver` 폴더에 쓰면
실행 추적과 디버깅이 어려워진다.
입력과 출력은 항상 같은 `ver` 기준으로 묶어야 한다.

## 11. 다음 문서 확장 아이디어

프로젝트가 커지면 다음 문서가 추가로 유용하다.

1. `ver`별 실행 이력 문서
2. 버전 간 coverage 비교표
3. DRC warning 분류 가이드