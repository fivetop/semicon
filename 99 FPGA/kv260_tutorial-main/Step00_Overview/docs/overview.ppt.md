# KV260 Vivado 교육 과정

본 교육 과정은 Kria KV260 Vision AI Starter Kit을 활용하여 Vivado FPGA 설계의 기초부터 고급 기술까지 단계별로 학습합니다.

---

## 교육 개요

### 대상
- 반도체설계 신입 엔지니어
- FPGA/SoC 개발을 원하는 엔지니어

### 일정
- **총 기간**: 2주 (10일)
- **하드웨어**: KV260 보드 (팀당 1대)

### 기술 스택
- **Vivado**: 2021.2
- **HDL**: Verilog
- **PYNQ**: Ubuntu 기반

---

## 커리큘럼

### Step 01: LED Blink 기초
**내용**: 가장 기본적인 LED 제어 회로 설계
- Vivado 프로젝트 생성
- Verilog RTL 코딩
- 블록 디자인 기초
- PYNQ에서 FPGA 프로그래밍

### Step 02: Vivado IP Integrator
**내용**: PS-PL 인터페이스와 블록 자동화
- Zynq UltraScale+ MPSoC 심화
- Clocking Wizard
- Processor System Reset
- 플랫폼 익스포트 (XSA)

### Step 03: AXI GPIO Integration
**내용**: PS-PL 통신 구현
- AXI GPIO IP 사용
- Python으로 LED 제어
- 인터럽트 기초

### Step 04: Vitis HLS + 커스텀 IP
**내용**: C/C++에서 RTL 생성
- Vitis HLS 기초
- 커스텀 IP 생성
- PMOD 인터페이스 제어

### Step 05: KV260 BIST Platform
**내용**: 비전 AI 플랫폼 분석
- KV260 아키텍처
- MIPI 카메라, VCU, DisplayPort
- PetaLinux 연동

---

## 학습 목표

### 기초 수준 (Step 01-02)
- Vivado 환경 구축
- RTL 코딩 이해
- 프로젝트 생성 및 빌드

### 중급 수준 (Step 03-04)
- PS-PL 통신 구현
- 커스텀 IP 개발
- 디바이스 드라이버 작성

### 고급 수준 (Step 05)
- 비전 AI 플랫폼 이해
- 전체 시스템 통합
- 커스텀 애플리케이션 개발

---

## 필수 준비물

### 하드웨어
- KV260 Vision AI Starter Kit
- 마이크로 USB 케이블
- 이더넷 케이블
- SD 카드

### 소프트웨어
- Vivado Design Suite 2021.2
- PYNQ 이미지 (KV260용)
- VSCode + Verilog 확장

---

## 교육 환경 설정

### 1일차: Vivado 설치
- Vivado 2021.2 설치
- KV260 보드 파일 추가

### 2일차: 개발 환경
- VSCode 설정
- Git 설정
- TCL 스크립트 이해

---

## 각 Step 진행 방식

```
1. 이론 학습 (30분)
2. 실습 가이드 따라하기 (1시간)
3. 심화 연습 문제 (30분)
4. 검증 및 질문 (30분)
```

---

## 예상 학습 결과

### 완료 후 역량
- Vivado로 FPGA 프로젝트 생성 가능
- Verilog로 RTL 설계 가능
- PS-PL 통신 구현 가능
- 커스텀 IP 개발 가능
- 비전 AI 애플리케이션 개발 기반 확보

---

## 참고 자료

### 공식 문서
- KV260 User Guide (UG1089)
- Vivado Design Suite Documentation
- PYNQ Documentation

### 실습 자료
- 본 튜토리얼 (Step 01-05)
- Vivado TCL 스크립트
- Verilog 소스 코드

---

## 다음 단계

**Step 01: LED Blink 기초**

Vivado를 사용하여 가장 기본적인 LED 제어 회로를设计和实现합니다.
