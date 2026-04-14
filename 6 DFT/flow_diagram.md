# 4_ATPG 플로우 다이어그램

## 1. 상위 실행 흐름

```mermaid
flowchart TD
    A[:run_tmax] --> B[setup.sh]
    B --> C[$tool_path/bin/tmax -64 -tcl -shell 0_Script/main.tcl]
    C --> D[0_run_atpg_setup.tcl]
    D --> E[1_run_atpg_read_netlist.tcl]
    E --> F[2_run_atpg_build.tcl]
    F --> G[3_run_atpg_drc.tcl]
    G --> H[4_run_atpg_tmax2pt.tcl]
    H --> I[5_run_atpg.tcl]
    I --> J[6_run_atpg_write_patterns.tcl]
    J --> K[7_run_atpg_reports.tcl]
```

## 2. 입력과 출력 연결

```mermaid
flowchart LR
    A[../3_DFT/2_Output/ver/ORCA_scan_comp.v] --> DRCFlow[TetraMAX ATPG 플로우]
    B[../3_DFT/2_Output/ver/scan_comp.spf] --> DRCFlow
    C[../3_DFT/2_Output/ver/scan_internal.spf] --> DRCFlow
    L[tmax_model 및 SAED 라이브러리] --> DRCFlow

    DRCFlow --> O[2_Output/ver]
    DRCFlow --> P[3_Log/ver]
    DRCFlow --> Q[4_Report/ver]
```

## 3. 단계별 책임

```mermaid
flowchart TD
    S0[환경 및 변수 설정]
    S1[라이브러리와 넷리스트 읽기]
    S2[ATPG 모델 생성]
    S3[DRC 수행]
    S4[타이밍 제약 추출]
    S5[ATPG 실행]
    S6[패턴 및 테스트벤치 생성]
    S7[리포트 생성]

    S0 --> S1 --> S2 --> S3 --> S4 --> S5 --> S6 --> S7
```

## 4. 버전 기반 데이터 분리

```mermaid
flowchart TD
    V[ver] --> O1[2_Output/ver]
    V --> O2[3_Log/ver]
    V --> O3[4_Report/ver]
```

## 5. 해석 메모

1. 셸 래퍼는 실행 버전과 상위 입력 선택을 제어한다.
2. `0_Script/` 아래의 모듈형 TCL 플로우가 현재 기준 구현이다.
3. ATPG 작업 공간은 외부 DFT 산출물과 공정 라이브러리에 의존한다.
4. 출력, 로그, 리포트는 모두 `ver` 값으로 분리된다.
5. `3_Log/${ver}`만 있고 `2_Output/${ver}`, `4_Report/${ver}`가 비어 있으면 패턴 생성 또는 리포트 생성 전에 중단됐을 가능성이 높다.