# Step06: SHA-256 HW vs SW Comparison on KV260

## Overview (개요)

이 튜토리얼은 **KV260 (Xilinx Zynq UltraScale+)** 보드에서 **SHA-256 암호화 해시 연산**을 다음 세 가지 방식으로 구현하고 성능을 비교합니다:

- **HW (Hardware)**: Verilog RTL로 구현한 SHA-256 가속기 (FPGA PL 영역)
- **SW (Software - Python)**: ARM Cortex-A53 (PS) 에서 실행하는 Python `hashlib`
- **SW (Software - C)**: ARM Cortex-A53 (PS) 에서 실행하는 Optimized C 구현

### 프로젝트 특징

| 항목 | 내용 |
|------|------|
| **알고리즘** | SHA-256 (FIPS 180-4 표준) |
| **입력 블록** | 512-bit (64 bytes) |
| **출력 해시** | 256-bit (32 bytes) |
| **PL 클럭** | 100 MHz |
| **인터페이스** | AXI4-Stream (AXI DMA 기반) |
| **주요 기능** | Message Scheduler, 64-round Compression Function |

### 성능 비교 목표

```
┌─────────────────────────────────────────────────────────────┐
│                 SHA-256 HW vs SW Architecture               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Python (hashlib) ────────────────────────┐               │
│         │                                  │               │
│         ▼                                  ▼               │
│   ┌─────────┐    ┌─────────┐    ┌──────────────────┐      │
│   │ Message │───▶│ SHA-256 │───▶│ Throughput       │      │
│   │ (Bytes) │    │  SW lib │    │ (MB/s)           │      │
│   └─────────┘    └─────────┘    └──────────────────┘      │
│                                                             │
│   C (Optimized) ───────────────────────────┐               │
│         │                                  │               │
│         ▼                                  ▼               │
│   ┌─────────┐    ┌─────────┐    ┌──────────────────┐      │
│   │ Message │───▶│ SHA-256 │───▶│ Throughput       │      │
│   │ (Bytes) │    │  C Code │    │ (MB/s)           │      │
│   └─────────┘    └─────────┘    └──────────────────┘      │
│                                                             │
│   Verilog RTL ─────────────────────────────┐               │
│         │                                  │               │
│         ▼                                  ▼               │
│   ┌─────────┐    ┌─────────┐    ┌──────────────────┐      │
│   │ Message │───▶│ SHA-256 │───▶│ Throughput       │      │
│   │ Stream  │    │  Accel  │    │ (MB/s)           │      │
│   └─────────┘    └─────────┘    └──────────────────┘      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 1. Project Architecture (프로젝트 아키텍처)

### 디렉토리 구조

```
Step06_Projects/
├── docs/
│   └── Step06_SHA256_HW_SW_Comparison.md   # 본 문서
├── rtl/
│   ├── sha256_k_rom.v                       # Round constants (K)
│   ├── sha256_msg_sch.v                     # Message scheduler (W)
│   ├── sha256_core.v                        # 64-round compression core
│   ├── sha256_accel.v                       # AXI4-Stream wrapper
│   └── tb_sha256_accel.v                    # Testbench
├── vivado/
│   └── sha256_block_design.tcl              # Block design script
└── software/
    ├── sha256_sw.py                         # Python benchmark
    ├── sha256_sw.c                          # C implementation
    ├── Makefile                             # Build script
    ├── hw_accel.py                          # PYNQ control
    └── benchmark.py                         # Total benchmark runner
```

### 데이터 흐름

1. **Software**: CPU에서 데이터를 순차적으로 읽어 해시 함수를 수행합니다.
2. **Hardware**: PS 메모리의 데이터를 AXI DMA를 통해 PL 가속기로 스트리밍합니다. 가속기는 64라운드 연산을 거쳐 256비트 결과를 다시 메모리로 보냅니다.

---

## 2. Prerequisites (사전 준비)

### Hardware Requirements

- **KV260 Starter Kit**
- **MicroSD Card** (Ubuntu 22.04 + PYNQ 이미지)

### Software Requirements

```bash
# KV260 환경 설정
sudo apt-get update
sudo apt-get install -y python3-pynq python3-numpy gcc
```

---

## 3. PART A: FPGA SHA-256 RTL Design

SHA-256은 32비트 워드 연산과 64라운드 루프로 구성됩니다.

### 3.1 SHA-256 Core (sha256_core.v)

가장 핵심적인 압축 함수(Compression Function)를 구현합니다.

```verilog
// sha256_core.v - SHA-256 Compression Engine
module sha256_core (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [31:0] w_data, // From Message Scheduler
    input  wire [31:0] k_data, // From K-ROM
    output reg         ready,
    output reg         done,
    output wire [255:0] digest
);
    // Hash state H0 ~ H7
    reg [31:0] h[0:7];
    reg [31:0] a, b, c, d, e, f, g, h_v;
    reg [5:0]  round;

    // Initial Hash Values (FIPS 180-4)
    localparam [31:0] H0 = 32'h6a09e667, H1 = 32'hbb67ae85, H2 = 32'h3c6ef372, H3 = 32'ha54ff53a,
                      H4 = 32'h510e527f, H5 = 32'h9b05688c, H6 = 32'h1f83d9ab, H7 = 32'h5be0cd19;

    // Functions: Ch, Maj, S0, S1
    function [31:0] Ch (input [31:0] x, y, z); Ch = (x & y) ^ (~x & z); endfunction
    function [31:0] Maj(input [31:0] x, y, z); Maj = (x & y) ^ (x & z) ^ (y & z); endfunction
    function [31:0] ROTR(input [31:0] x, input [4:0] n); ROTR = (x >> n) | (x << (32-n)); endfunction
    function [31:0] S0 (input [31:0] x); S0 = ROTR(x, 2) ^ ROTR(x, 13) ^ ROTR(x, 22); endfunction
    function [31:0] S1 (input [31:0] x); S1 = ROTR(x, 6) ^ ROTR(x, 11) ^ ROTR(x, 25); endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7]} <= {H0, H1, H2, H3, H4, H5, H6, H7};
            round <= 0;
            ready <= 1;
            done <= 0;
        end else if (start && ready) begin
            {a, b, c, d, e, f, g, h_v} <= {h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7]};
            round <= 0;
            ready <= 0;
        end else if (!ready && !done) begin
            if (round < 64) begin
                reg [31:0] t1, t2;
                t1 = h_v + S1(e) + Ch(e, f, g) + k_data + w_data;
                t2 = S0(a) + Maj(a, b, c);
                h_v <= g; g <= f; f <= e; e <= d + t1;
                d <= c;   c <= b; b <= a; a <= t1 + t2;
                round <= round + 1;
            end else begin
                h[0] <= h[0] + a; h[1] <= h[1] + b; h[2] <= h[2] + c; h[3] <= h[3] + d;
                h[4] <= h[4] + e; h[5] <= h[5] + f; h[6] <= h[6] + g; h[7] <= h[7] + h_v;
                done <= 1;
            end
        end else if (done) begin
            done <= 0;
            ready <= 1;
        end
    end

    assign digest = {h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7]};
endmodule
```

### 3.2 Message Scheduler (sha256_msg_sch.v)

입력 512비트 블록으로부터 64개의 32비트 워드를 생성합니다.

```verilog
// sha256_msg_sch.v - 512-bit to 64-word expander
module sha256_msg_sch (
    input  wire        clk,
    input  wire [31:0] block_in,
    input  wire        load,
    input  wire [5:0]  round,
    output wire [31:0] w_out
);
    reg [31:0] w[0:15];
    integer i;

    function [31:0] ROTR(input [31:0] x, input [4:0] n); ROTR = (x >> n) | (x << (32-n)); endfunction
    function [31:0] s0(input [31:0] x); s0 = ROTR(x, 7) ^ ROTR(x, 18) ^ (x >> 3); endfunction
    function [31:0] s1(input [31:0] x); s1 = ROTR(x, 17) ^ ROTR(x, 19) ^ (x >> 10); endfunction

    wire [31:0] next_w = s1(w[14]) + w[9] + s0(w[1]) + w[0];

    always @(posedge clk) begin
        if (load) begin
            // Shift in 512 bits in 16 cycles or parallel load
            w[round[3:0]] <= block_in;
        end else if (round >= 16) begin
            for (i=0; i<15; i=i+1) w[i] <= w[i+1];
            w[15] <= next_w;
        end
    end
    assign w_out = (round < 16) ? w[round[3:0]] : w[15];
endmodule
```

### 3.3 AXI4-Stream Wrapper (sha256_accel.v)

AXI DMA와 통신하기 위한 인터페이스입니다.

```verilog
// sha256_accel.v - AXI4-Stream Interface
module sha256_accel (
    input  wire        clk,
    input  wire        aresetn,
    // Slave Stream (Input Block)
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    // Master Stream (Output Digest)
    output wire [31:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready
);
    // State machine and control logic here
    // Loads 16 words (512 bits) -> Starts sha256_core -> Outputs 8 words (256 bits)
    // ... (Implementation details omitted for brevity, logic follows standard AXI handshake)
endmodule
```

---

## 4. PART B: Vivado Block Design

### 4.1 PS-PL 연결 구조

1. **Zynq UltraScale+ MPSOC**: PL 클럭(100MHz) 및 AXI Master 제공
2. **AXI Direct Memory Access (DMA)**:
   - SG(Scatter-Gather) 비활성화 (Simple Mode)
   - MM2S: PS DDR -> SHA-256 (Input)
   - S2MM: SHA-256 -> PS DDR (Output)
3. **SHA-256 Accelerator**: 우리 가속기 IP

### 4.2 TCL 스크립트 실행

```tcl
# sha256_block_design.tcl
# 1. PS 설정
# 2. DMA 추가
# 3. SHA-256 IP 추가 및 연결
# 4. Bitstream 생성
```

---

## 5. PART C: PS Software (Python + C)

### 5.1 Python Implementation (sha256_sw.py)

Python의 기본 라이브러리를 사용하여 기준 성능을 측정합니다.

```python
import hashlib
import time
import numpy as np

def benchmark_python(data_size_mb=10):
    data = np.random.bytes(data_size_mb * 1024 * 1024)
    
    start = time.perf_counter()
    sha = hashlib.sha256()
    sha.update(data)
    digest = sha.digest()
    end = time.perf_counter()
    
    duration = end - start
    throughput = data_size_mb / duration
    print(f"Python hashlib: {throughput:.2f} MB/s")
    return throughput
```

### 5.2 Optimized C Implementation (sha256_sw.c)

```c
#include <stdio.h>
#include <stdint.h>
#include <time.h>
#include <openssl/sha.h> // 또는 직접 구현

void benchmark_c(size_t size_mb) {
    uint8_t *data = malloc(size_mb * 1024 * 1024);
    uint8_t hash[32];
    
    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);
    
    SHA256(data, size_mb * 1024 * 1024, hash);
    
    clock_gettime(CLOCK_MONOTONIC, &end);
    double time_taken = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    printf("C Implementation: %.2f MB/s\n", size_mb / time_taken);
}
```

---

## 6. PART D: PYNQ HW Acceleration

### 6.1 PYNQ Driver (hw_accel.py)

```python
from pynq import Overlay, allocate
import numpy as np
import time

class SHA256Accel:
    def __init__(self, bitfile="sha256.bit"):
        self.ol = Overlay(bitfile)
        self.dma = self.ol.axi_dma_0

    def hash(self, message_bytes):
        # 512-bit alignment padding should be handled here
        in_buffer = allocate(shape=(len(message_bytes)//4,), dtype=np.uint32)
        out_buffer = allocate(shape=(8,), dtype=np.uint32)
        
        # Transfer
        self.dma.sendchannel.transfer(in_buffer)
        self.dma.recvchannel.transfer(out_buffer)
        self.dma.sendchannel.wait()
        self.dma.recvchannel.wait()
        
        return out_buffer.tobytes().hex()
```

---

## 7. PART E: Unified Benchmark

### 성능 측정 결과 (예시)

| 구현 방식 | 성능 (MB/s) | Speedup |
|-----------|-------------|---------|
| Python (hashlib) | ~150 MB/s | 1x |
| C (OpenSSL) | ~400 MB/s | 2.6x |
| **FPGA HW (100MHz)** | **~620 MB/s** | **4.1x** |

*참고: HW 성능은 병렬 처리 및 파이프라이닝 수준에 따라 더 높아질 수 있습니다.*

---

## 8. Results Analysis (결과 분석)

- **Software**: CPU 클럭(1.2GHz)은 빠르지만, 명령어 실행 기반이므로 여러 사이클이 소모됩니다.
- **Hardware**: 클럭(100MHz)은 낮지만, 전용 로직으로 라운드 연산을 매 사이클 처리하며 데이터 스트리밍이 병렬로 이루어집니다.
- **Efficiency**: 전력 대비 성능 면에서 FPGA 가속기가 압도적으로 유리합니다.

---

## 9. Verification Checklist

- [ ] RTL 시뮬레이션에서 NIST 테스트 벡터 일치 확인
- [ ] DMA 전송 시 데이터 손실 없음 확인
- [ ] Python/C/HW 해시 결과 값이 모두 동일함 확인

---

## 10. Troubleshooting

- **DMA Timeout**: 입력 데이터가 512비트(64바이트)의 배수가 아닐 경우 발생할 수 있습니다. 패딩 처리를 확인하세요.
- **결과 불일치**: Endianness 문제를 확인하세요. SHA-256은 Big-Endian 표준입니다.

---

## 11. References

- NIST FIPS 180-4: Secure Hash Standard
- Xilinx UG585: Zynq-7000 TRM (DMA sections)
- PYNQ ReadTheDocs: DMA Library

---

*Created: 2026-04-06*
*Author: SoGang KV260 Tutorial*
*Version: 1.0*
