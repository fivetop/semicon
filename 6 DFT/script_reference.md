# 4_ATPG 스크립트 레퍼런스

## 1. 개요

이 문서는 ATPG 워크스페이스의 실행 스크립트가 각각 어떤 역할을 하는지,
어떤 변수를 사용하고, 어떤 결과를 만드는지를 정리한다.

## 2. 셸 레벨 스크립트

### 2.1 `setup.sh`

역할:

- ATPG 실행에 필요한 셸 환경을 준비한다.

현재 동작:

- `work_path`를 `/DATA/home/edu118/DC_LAB/4_ATPG`로 설정한다.
- `tool_path`를 TetraMAX 설치 루트로 설정한다.
- `path`에 TetraMAX 실행 경로를 추가한다.
- `g` alias를 `gvim`으로 지정한다.

중요 사항:

- 파일 이름은 `.sh`지만 실제 문법은 csh다.

### 2.2 `:run_tmax`

역할:

- ATPG 플로우 전체를 시작하는 메인 배치 스크립트다.

이곳에서 설정하는 변수:

- `ver`
- `top`
- `scan_comp`
- `NET`

각 변수의 실무 의미:

- `ver`
   - 결과물 버전 구분자다.
   - `2_Output`, `3_Log`, `4_Report` 폴더 이름에 직접 반영된다.
- `top`
   - ATPG 대상 최상위 모듈 이름이다.
- `scan_comp`
   - compression SPF를 쓸지 internal SPF를 쓸지 결정한다.
- `NET`
   - 대상 스캔 넷리스트 경로다.

실행 내용:

1. 실행 변수 export
2. `./setup.sh` 호출
3. 출력, 로그, 리포트 폴더 생성
4. `0_Script/main.tcl`을 사용해 TetraMAX 실행

주요 출력 영향 경로:

- `2_Output/${ver}/...`
- `3_Log/${ver}/...`
- `4_Report/${ver}/...`

## 3. TCL 플로우 진입점

### 3.1 `0_Script/main.tcl`

역할:

- 전체 순서를 제어하는 메인 흐름 제어기다.

실행 내용:

- 번호가 붙은 TCL 스크립트를 정해진 순서대로 호출한다.
- ATPG 플로우를 단계별로 분해해 관리하기 쉽게 만든다.

왜 중요한가:

- TetraMAX 내부에서의 기준 플로우 정의다.
- 단계 순서가 바뀌면 전체 동작이 달라질 수 있다.

## 4. 단계별 TCL 스크립트

### 4.1 `0_run_atpg_setup.tcl`

역할:

- 실행 환경 변수와 버전별 파생 경로를 초기화한다.

읽는 값:

- `ver`
- `top`
- `NET`
- `scan_comp`

생성하는 값:

- `compress_spf`
- `internal_spf`
- `3_Log/${ver}` 아래 로그 경로

핵심 효과:

- 이후 단계가 공통 변수 집합을 공유하도록 실행 문맥을 통일한다.

### 4.2 `1_run_atpg_read_netlist.tcl`

역할:

- 공정 라이브러리와 설계 넷리스트를 읽는다.

주요 동작:

1. 표준셀 라이브러리 읽기
2. `tmax_model/` 아래 IO 모델 읽기
3. `-define TETRAMAX` 옵션으로 PLL 라이브러리 읽기
4. SRAM 매크로를 블랙박스로 선언
5. `top` 값을 사용해 `DESIGN_NAME` 설정
6. `NET`에 지정된 스캔 넷리스트 읽기

왜 중요한가:

- 이 단계가 틀리면 이후 모든 단계가 연쇄적으로 실패한다.

### 4.3 `2_run_atpg_build.tcl`

역할:

- ATPG 가능한 내부 모델을 만든다.

주요 동작:

- `B12` 규칙 완화
- ATPG equivalence learning 활성화
- `run_build_model ${DESIGN_NAME}` 실행

왜 중요한가:

- 읽어들인 넷리스트를 DRC와 패턴 생성이 가능한 내부 표현으로 바꾼다.

### 4.4 `3_run_atpg_drc.tcl`

역할:

- 선택된 scan protocol 파일을 사용해 DRC를 수행한다.

주요 동작:

- unstable set/reset 허용
- dynamic clock DRC 옵션 적용
- `scan_comp` 값에 따라 SPF 선택

분기 규칙:

- `scan_comp == 1`이면 `compress_spf` 사용
- 그 외에는 `internal_spf` 사용

왜 중요한가:

- ATPG 전에 test protocol과 scan 구조가 유효한지 검증하는 단계다.

### 4.5 `4_run_atpg_tmax2pt.tcl`

역할:

- TetraMAX 정보를 바탕으로 PrimeTime 스타일 제약 파일을 만든다.

주요 동작:

- Synopsys 제공 `tmax2pt.tcl` 호출
- shift 제약 파일 생성
- capture 제약 파일 생성

생성 파일:

- `2_Output/${ver}/${DESIGN_NAME}_shift.tcl`
- `2_Output/${ver}/${DESIGN_NAME}_capture.tcl`

### 4.6 `5_run_atpg.tcl`

역할:

- fault 모델과 ATPG 전략을 정의하고 압축 ATPG를 실행한다.

주요 동작:

1. compressor, decompressor 모듈을 no-fault 처리
2. stuck-at fault model 선택
3. 전체 fault 추가
4. 시뮬레이션 옵션과 process 수 설정
5. fill, coverage, merge, decision, power 옵션 설정
6. `run_atpg -auto_compression` 실행
7. 요약 리포트 출력

확인된 주요 옵션:

- `-num_processes 4`
- `-coverage 98`
- `-power_budget min`
- `-power_effort high`

### 4.7 `6_run_atpg_write_patterns.tcl`

역할:

- 생성된 패턴을 내보내고 테스트벤치를 만든다.

저장 형식:

- WGL
- binary
- serial STIL
- parallel STIL
- shift 전용 STIL

추가 생성물:

- serial, parallel, shift 패턴용 `write_testbench` 결과

왜 중요한가:

- 후속 검증이나 테스터 전달에 필요한 산출물을 만드는 단계다.

### 4.8 `7_run_atpg_reports.tcl`

역할:

- 최종 분석 및 coverage 리포트를 생성한다.

생성 항목:

- fault summary 파일
- all-fault 파일
- collapsed 및 uncollapsed fault 리포트
- AU, UD, ND 분석 리포트
- scan chain 리포트
- scan cell 및 nonscan cell 리포트
- PI/PO constraint 및 mask 리포트
- coverage 상세 리포트
- compressor 및 lockup latch 리포트

왜 중요한가:

- ATPG 결과 품질을 판단하는 핵심 근거 자료다.

## 5. 참고 스크립트

### 5.1 `atpg_compress.tcl`

역할:

- 전체 ATPG 플로우를 단일 파일로 담고 있는 과거형 참고 스크립트다.

확인된 특징:

- setup, import, build, DRC, ATPG, 출력, 리포트가 하나의 파일에 합쳐져 있다.
- 번호형 스크립트와 유사한 로직을 포함한다.
- 과거 옵션과 실험용 주석이 함께 남아 있다.

권장 사용 방식:

- 예전 옵션을 복원하거나 레거시 동작을 비교할 때 참고용으로 사용한다.
- 유지보수 기준 진입점은 `main.tcl`과 번호형 TCL 스크립트로 본다.

## 6. 실무상 수정 포인트

플로우를 수정할 때 비교적 안전한 위치는 다음과 같다.

1. `:run_tmax`에서 실행 버전과 상위 입력 선택 수정
2. `0_run_atpg_setup.tcl`에서 공통 변수와 입력 경로 연결 수정
3. `3_run_atpg_drc.tcl`에서 DRC/SPF 선택 로직 수정
4. `5_run_atpg.tcl`에서 ATPG 전략 수정
5. `6_run_atpg_write_patterns.tcl`에서 패턴 출력 정책 수정
6. `7_run_atpg_reports.tcl`에서 최종 리포트 구성 수정

## 7. 혼동하기 쉬운 스크립트 쌍

다음 쌍은 역할이 비슷해 보여도 다르다.

1. `setup.sh` 와 `0_run_atpg_setup.tcl`
    - `setup.sh`는 셸 환경 설정 파일이다.
    - `0_run_atpg_setup.tcl`은 TetraMAX 내부 실행 변수 초기화 파일이다.
2. `main.tcl` 과 `atpg_compress.tcl`
    - `main.tcl`은 현재 사용 중인 모듈형 플로우다.
    - `atpg_compress.tcl`은 과거형 단일 파일 참고 스크립트다.