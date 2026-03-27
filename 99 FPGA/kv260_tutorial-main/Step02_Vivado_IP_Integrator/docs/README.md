# Step02_Vivado_IP_Integrator - Supporting Files

이 디렉토리에는 Step02 튜토리얼의 supporting 파일과 빌드 결과물이 포함되어 있습니다.

---

## 디렉토리 구조

```
Step02_Vivado_IP_Integrator/
├── src/                    # RTL 소스 파일
│   ├── clock_generator.v   # 클럭 생성 모듈 (카운터 기반)
│   ├── reset_controller.v # 리셋 컨트롤러 모듈
│   └── platform_wrapper.v  # 최상위 플랫폼 래퍼 모듈
├── scripts/                # Vivado TCL 스크립트
│   ├── create_project.tcl      # 프로젝트 생성
│   ├── create_block_design.tcl # 블록 디자인 생성 (Zynq PS + RTL)
│   ├── run_synthesis.tcl        # 합성 실행 및 리포트
│   ├── run_implementation.tcl   # 구현 실행, bitstream, PYNQ 파일
│   └── run_all.tcl              # 전체 빌드 (프로젝트 → 합성 → 구현)
├── constraints/            # XDC 제약 파일
│   └── kv260_ipi.xdc       # KV260 핀 할당, 클럭 제약
├── sim/                    # 시뮬레이션
│   ├── tb_clock_generator.sv
│   ├── tb_reset_controller.sv
│   └── tb_platform_wrapper.sv
├── pynq/                   # PYNQ 전송용 파일
│   ├── platform_wrapper.bit
│   └── system_wrapper.hwh
├── out/                    # 빌드 출력 (합성/구현 결과)
└── docs/                   # 본 파일
```

---

## 빌드 실행 방법

```bash
# 1. Vivado 환경 설정
source /tools/Xilinx/Vivado/2021.2/settings64.sh

# 2. 전체 빌드 (기본: RTL 클럭 사용)
cd Step02_Vivado_IP_Integrator/scripts
vivado -mode batch -source run_all.tcl

# 또는 개별 실행
vivado -mode batch -source create_project.tcl
vivado -mode batch -source create_block_design.tcl
vivado -mode batch -source run_synthesis.tcl
vivado -mode batch -source run_implementation.tcl
```

### 클럭 소스 옵션

| 옵션 | 설명 | 명령어 |
|------|------|--------|
| RTL (기본) | RTL clock_generator 모듈 사용 | `vivado -mode batch -source run_all.tcl -- --rtl` |
| IP | Xilinx Clocking Wizard IP 사용 | `vivado -mode batch -source run_all.tcl -- --ip` |
| Hybrid | RTL + IP 모두 사용 | `vivado -mode batch -source run_all.tcl -- --rtl --ip` |

**교육적 의도:**
- `--rtl`: RTL 클럭 분주 원리 학습 (카운터 기반)
- `--ip`: Xilinx IP 사용법 숙달 (Clocking Wizard)
- `--rtl --ip`: 두 가지 방식 비교 학습

---

## 시뮬레이션 실행

```bash
cd Step02_Vivado_IP_Integrator/scripts
./run_simulation.sh
```

---

## 주요 구현 내용

### 1. 클럭 소스 (RTL/IP 선택 가능)
- **RTL clock_generator**: PS pl_clk0 (100MHz) 입력, 카운터 기반 클럭 분주 (100/50/25/12.5MHz)
- **Xilinx Clocking Wizard IP**: MMCM 기반 클럭 생성 (100/200MHz)
- `run_all.tcl`에서 `--rtl`, `--ip`, `--rtl --ip` 옵션으로 선택

### 2. RTL 모듈
- **clock_generator**: PS pl_clk0 (100MHz) 입력받아 내부 클럭 생성
- **reset_controller**: PS pl_resetn0 입력받아 리셋 신호 생성
- **platform_wrapper**: Zynq PS + RTL 모듈 통합 블록 디자인 래퍼

### 2. 블록 디자인 구성 (TCL)
- Zynq UltraScale+ MPSoC IP 추가
- Board Preset: KV260 선택
- RTL 모듈 연결 (clock_generator, reset_controller)
- AXI 인터페이스 자동 연결 (Block Automation)

### 3. 제약 설정
- sysclk: Bank 45, LVCMOS18, 100MHz
- LED: Bank 44, LVCMOS33
- 생성된 클럭에 대한 timing constraint

### 4. PYNQ 파일 생성
- `platform_wrapper.bit`: Bitstream 파일
- `system_wrapper.hwh`: 하드웨어 하이버네이션 파일

---

## 빌드 로그

빌드 로그 및 Jou 파일:
- `vivado.log`: 최신 빌드 로그
- `vivado.jou`: 실행된 TCL 명령 기록
- `out/`: 합성/구현 결과 디렉토리

---

## 참고

- 상세 튜토리얼 내용: `../../Step02_Vivado_IP_Integrator.md`
- Step01과 동일한 구조를 따름