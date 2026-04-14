# 4_ATPG 폴더 구조 명세

관련 문서:

- `README.md`
- `execution_guide.md`
- `script_reference.md`
- `flow_diagram.md`

## 1. 개요

이 디렉터리는 ORCA 스캔 압축 플로우를 위한 Synopsys TetraMAX ATPG 작업 공간이다.
입력 데이터, 실행 스크립트, 생성 결과물, 로그, 리포트를 기능별로 분리하고,
동시에 실행 버전별로도 분리하도록 구성되어 있다.

기준 경로:

- `/DATA/home/edu118/DC_LAB/4_ATPG`

주 실행 진입점:

- `:run_tmax`

주 TCL 플로우:

- `0_Script/main.tcl`

## 2. 상위 폴더 구조

```text
4_ATPG/
|-- 0_Script/
|-- 1_Input/
|   |-- netlist/
|   `-- spf/
|-- 2_Output/
|   |-- 02_1204_comp/
|   |-- 03_0320_comp/
|   `-- 03_1211_comp/
|-- 3_Log/
|   |-- 02_1204_comp/
|   |-- 03_0320_comp/
|   `-- 03_1211_comp/
|-- 4_Report/
|   |-- 02_1204_comp/
|   |-- 03_0320_comp/
|   `-- 03_1211_comp/
|-- lib/
|-- spec/
|-- tmax_model/
|-- :run_tmax
|-- command.log
`-- setup.sh
```

## 3. 폴더별 역할

### 3.1 `0_Script`

ATPG 플로우를 단계별로 나눈 TCL 스크립트들이 들어 있다.

- `0_run_atpg_setup.tcl`
  - `ver`, `top`, `NET`, `scan_comp` 같은 실행 변수를 읽는다.
  - 로그 위치와 SPF 입력 경로를 만든다.
- `1_run_atpg_read_netlist.tcl`
  - 표준셀, IO, common, PLL 라이브러리를 읽는다.
  - 대상 넷리스트를 읽고 SRAM 매크로를 블랙박스로 선언한다.
- `2_run_atpg_build.tcl`
  - 빌드 규칙을 설정하고 `run_build_model`을 실행한다.
- `3_run_atpg_drc.tcl`
  - DRC 옵션을 설정하고 compression SPF 또는 internal SPF를 사용해 DRC를 수행한다.
- `4_run_atpg_tmax2pt.tcl`
  - `tmax2pt.tcl`을 불러와 shift/capture 제약 파일을 생성한다.
- `5_run_atpg.tcl`
  - fault와 ATPG 옵션을 설정하고 압축 ATPG를 수행한다.
- `6_run_atpg_write_patterns.tcl`
  - WGL, binary, STIL, 테스트벤치 결과를 생성한다.
- `7_run_atpg_reports.tcl`
  - fault 요약, scan 리포트, mask 리포트, coverage 리포트를 생성한다.
- `main.tcl`
  - 번호 순서대로 TCL 스크립트를 호출하는 메인 제어 스크립트다.
- `atpg_compress.tcl`
  - 동일한 흐름을 단일 파일로 담은 과거형 또는 참고용 스크립트다.

### 3.2 `1_Input`

ATPG 실행에 사용되는 입력 설계 데이터가 들어 있다.

- `netlist/`
  - 스캔 넷리스트 저장 위치다.
  - 현재 예시: `ORCA_scan_comp.v`
- `spf/`
  - 스캔 프로토콜 파일 저장 위치다.
  - 현재 예시: `scan_comp.spf`, `scan_internal.spf`

참고:
현재 실제 실행 스크립트는 주로 `../3_DFT/2_Output/${ver}/` 아래의 넷리스트와 SPF를 직접 참조한다.
따라서 `1_Input`은 로컬 복사본 또는 참고 입력 저장소 성격이 강하다.

### 3.3 `2_Output`

ATPG 실행 결과물이 버전별 폴더로 정리되는 위치다.

대표 출력 파일 형식:

- `*.wgl`
- `*.bin`
- `*.stil`
- `*.maxtb.v`
- `*.maxtb.dat`
- `*_shift.tcl`
- `*_capture.tcl`

확인된 버전 폴더:

- `02_1204_comp`
- `03_1211_comp`
- `03_0320_comp`

현재 상태:

- `02_1204_comp`, `03_1211_comp`는 패턴 출력이 채워져 있다.
- `03_0320_comp`는 현재 비어 있다.

### 3.4 `3_Log`

실행 로그가 버전별로 저장되는 위치다.

대표 로그 파일:

- `tmax_compress.log`
- `tmax_compress.log.1` 같은 회전 로그
- 상위 `atpg.log`

현재 상태:

- `03_0320_comp`에는 `tmax_compress.log`만 있다.
  즉, 실행은 시작됐지만 전체 결과물 생성 전 중단됐을 가능성이 있다.

### 3.5 `4_Report`

ATPG 분석 리포트가 버전별로 저장되는 위치다.

대표 리포트 종류:

- fault summary 및 all-fault 리포트
- untestable, undetected fault 분석 리포트
- scan chain, scan cell 리포트
- nonscan cell 리포트
- feedback path 리포트
- PI/PO constraint 및 mask 리포트
- coverage 상세 리포트
- compressor, lockup latch 리포트

현재 상태:

- `02_1204_comp`, `03_1211_comp`는 리포트가 채워져 있다.
- `03_0320_comp`는 현재 비어 있다.

### 3.6 `lib`

보조 모델 데이터 아카이브를 저장하는 위치다.

- 현재 파일: `tmax_model.tar.gz`

이 파일은 현재 풀려 있는 `tmax_model/` 디렉터리의 원본 아카이브로 보인다.

### 3.7 `tmax_model`

TetraMAX 넷리스트 import 과정에서 읽는 로컬 모델 라이브러리 위치다.

확인된 파일:

- `common.v`
- `saed14nm_stdio_fc.v`
- `saed32nm_std_io_fc.tv`

이 파일들은 `1_run_atpg_read_netlist.tcl`에서 사용된다.

### 3.8 `setup.sh`

ATPG 작업 공간용 셸 환경 설정 파일이다.

현재 역할:

- `work_path`를 `/DATA/home/edu118/DC_LAB/4_ATPG`로 설정한다.
- `tool_path`를 Synopsys TetraMAX 설치 경로로 지정한다.
- `path`를 확장한다.

### 3.9 `:run_tmax`

ATPG 플로우를 시작하는 주 배치 스크립트다.

현재 동작:

- 실행 변수 설정
  - `ver=03_1211_comp`
  - `top=ORCA`
  - `scan_comp=1`
  - `NET=../3_DFT/2_Output/${ver}/ORCA_scan_comp.v`
- `setup.sh` 호출
- 버전별 출력, 로그, 리포트 폴더 자동 생성
- `0_Script/main.tcl`을 이용해 TetraMAX 실행

## 4. 실행 흐름

실제 실행 순서는 다음과 같다.

1. `:run_tmax` 실행
2. `setup.sh` 호출
3. `$tool_path/bin/tmax -64 -tcl -shell ./0_Script/main.tcl` 실행
4. `main.tcl`이 번호 순서대로 TCL 스크립트를 호출

세부 단계:

1. 실행 환경과 로그 설정
2. 라이브러리와 대상 넷리스트 읽기
3. ATPG 모델 빌드
4. 선택된 SPF로 DRC 수행
5. `tmax2pt`로 타이밍 제약 추출
6. compression 옵션으로 ATPG 수행
7. 패턴과 테스트벤치 생성
8. 리포트 생성

## 5. 버전 관리 규칙

`2_Output`, `3_Log`, `4_Report` 아래 폴더 이름은 모두 `ver` 값으로 제어된다.

예시:

- `02_1204_comp`
- `03_1211_comp`
- `03_0320_comp`

이 값이 실행 결과를 서로 섞이지 않게 분리하는 핵심 키다.

## 6. 데이터 의존 관계

스크립트에서 확인된 주요 의존성은 다음과 같다.

- 넷리스트 입력:
  - `../3_DFT/2_Output/${ver}/ORCA_scan_comp.v`
- compression SPF 입력:
  - `../3_DFT/2_Output/${ver}/scan_comp.spf`
- internal SPF 입력:
  - `../3_DFT/2_Output/${ver}/scan_internal.spf`
- 로컬 모델 라이브러리:
  - `./tmax_model/*`
- 외부 참조 라이브러리:
  - `../SAED32_EDK/...`

즉, 이 ATPG 폴더는 단독 실행형이 아니며 DFT 출력과 공정 라이브러리에 의존한다.

## 7. 현재 스냅샷

현재 워크스페이스 기준 상태는 다음과 같다.

- 활성 플로우는 `0_Script/` 아래 번호형 TCL 파이프라인으로 정리되어 있다.
- `02_1204_comp`, `03_1211_comp`의 과거 실행 결과가 남아 있다.
- `03_0320_comp`는 진행 중이거나 중간 실패한 실행으로 보인다.
- `spec/` 폴더는 문서 및 스펙 정리를 위해 추가되었다.

## 8. 권장 사용 규칙

향후 이 폴더에서 작업할 때의 기본 규칙은 다음과 같다.

1. 새 ATPG 실행 전에는 `:run_tmax`의 `ver` 값을 새 값으로 바꾼다.
2. 입력 데이터는 반드시 같은 `../3_DFT/2_Output/${ver}` 버전과 대응되게 맞춘다.
3. 서로 다른 실행 결과를 같은 버전 폴더에 섞지 않는다.
4. TetraMAX 내부 진입점은 `0_Script/main.tcl`을 기준으로 본다.
5. 셸 배치 실행 진입점은 `:run_tmax`를 기준으로 본다.
