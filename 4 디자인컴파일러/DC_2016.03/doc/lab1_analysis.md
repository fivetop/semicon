# lab1 폴더 자세한 분석

lab1은 Synopsys Design Compiler 합성 실습 폴더로, 기본 설정과 RTL 코드, 스크립트로 구성되어 있습니다.

## 주요 파일 및 폴더
- **.synopsys_dc.setup**: DC 설정 파일. 히스토리 유지, 별칭 정의(예: `rc` for report_constraint), ALIB 경로 설정(`../`), WORK 라이브러리 정의(`./work`), 메시지 억제, 공통/DC 설정 소스, 라이브러리 변수 출력.
- **common_setup.tcl**: 공통 설정 스크립트. 검색 경로(`../ref/libs/...`), 타겟/심볼 라이브러리 파일(빈칸으로 사용자 입력 필요), MW 디자인 라이브러리, 참조 라이브러리, 기술 파일(`cb13_6m.tf`), TLUPlus 파일 설정.
- **dc_setup.tcl**: DC 설정 스크립트. 검색 경로/타겟/링크/심볼 라이브러리 설정, MW 라이브러리 생성/열기, TLUPlus 파일 적용.
- **rtl/**: RTL 코드 폴더.
  - TOP.v: Verilog 모듈 파일.
  - TOP.vhd: VHDL 모듈 파일.
- **scripts/**: 스크립트 폴더.
  - TOP.con: 제약 조건 파일(Constraints).
- **mapped/**: 합성 후 매핑된 디자인 파일 폴더.
- **unmapped/**: 합성 전 언매핑된 디자인 파일 폴더.
- **work/**: 작업 라이브러리 폴더.
- **.solutions/**: 솔루션 파일 폴더.

이 폴더는 기본 합성 워크플로우를 위한 템플릿으로, 설정 파일을 채우고 RTL을 합성하는 데 사용됩니다.