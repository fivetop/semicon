# romee 요약 및 Lab 비교

## 1) 폴더 요약
- `DC_2016.03_lab.PDF`: Design Compiler 랩 자료 PDF
- `README`: 랩 환경/실습 안내
- `setup.csh`: Synopsys 환경 변수 및 실행 경로 설정
- `alib-52/`: 라이브러리 캐시
- `lab1/`, `lab3/`, `lab4/`, `lab5/`, `lab7/`, `lab8/`: 실습 폴더
- `ref/`: 라이브러리/툴 참조 데이터
- `doc/`: 분석 문서 저장 폴더

## 2) 분석 문서 목록
- `doc/lab1_analysis.md`
- `doc/lab3_analysis.md`
- `doc/lab4_analysis.md`
- `doc/lab5_analysis.md`
- `doc/lab7_analysis.md`
- `doc/lab8_analysis.md`

## 3) Lab 비교 (lab1~lab8)

참고: `romee`에는 `lab2`, `lab6` 폴더가 없습니다.

| Lab | 핵심 주제 | 입력 대상 | 제약 수준 | 컴파일/최적화 수준 | 산출물 포인트 |
|---|---|---|---|---|---|
| lab1 | 기본 템플릿/환경 익히기 | RTL(Verilog/VHDL) | 기초 설정 중심 | 실습 준비 단계 | 폴더/스크립트 구조 이해 |
| lab3 | 기본 합성 플로우 | `MY_DESIGN.v` | 기본 clock + I/O delay | 컴파일보다 검증 리포트 중심 | `unmapped/MY_DESIGN.ddc` |
| lab4 | 환경 모델링 추가 | `MY_DESIGN.v` | lab3 + driving cell/input transition/output load | 전처리/분석 중심 | 환경 제약 반영 DDC |
| lab5 | 고급 최적화/리타이밍 | `STOTO.v` | 상세 타이밍 + 물리 제약(`.pcon`) | `compile_ultra`, retime, incremental compile | `mapped/unmapped STOTO.ddc`, 타이밍/제약 리포트, `SVF` |
| lab7 | 네거티브 엣지/가상클럭 비교 | `MY_DESIGN.v` | 고급 I/O 타이밍 예외(2개 모델링 방식) | `compile_ultra -scan -retime` | 일반/가상클럭 버전 DDC 비교 |
| lab8 | 타이밍 예외 실습(STA 관점) | `EXCEPTIONS.ddc` | false path, clock group, multicycle 중심 | 합성보다 예외 정의/검증 중심 | `EXCEPTIONS.sdc` 생성 |

## 4) 학습 흐름
1. `lab1`: 환경/구조 익히기
2. `lab3`: 기본 제약 + 기본 합성 검증
3. `lab4`: I/O 환경 제약 확장
4. `lab5`: 실무형 최적화(경로 그룹, retiming, incremental, physical)
5. `lab7`: 네거티브 엣지 타이밍 모델링(포함 방식 vs 가상클럭)
6. `lab8`: 예외 제약 중심 STA 실습