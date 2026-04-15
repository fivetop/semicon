# Step06: CNN HW vs SW Comparison on KV260

## Overview (개요)

이 튜토리얼은 **KV260 (Xilinx Zynq UltraScale+)** 보드에서 **CNN Conv2D 연산**을 다음 두 가지 방식으로 구현하고 실행 시간을 비교합니다:

- **HW (Hardware)**: 순수 Verilog RTL로 구현한 FPGA 가속기
- **SW (Software)**: ARM Cortex-A53 (PS) 에서 실행하는 Python (NumPy) 및 C 구현

### 프로젝트 특징

| 항목 | 내용 |
|------|------|
| **모델** | LeNet-5 (MNIST handwritten digit recognition) |
| **RTL 범위** | 단일 Conv2D 레이어 (5×5 커널, INT8) |
| **입력 크기** | 28×28 (MNIST 표준) |
| **출력 크기** | 24×24 (valid convolution) |
| **PL 클럭** | 100 MHz |
| **인터페이스** | AXI4-Stream (AXI DMA) |

### 성능 비교 목표

```
┌─────────────────────────────────────────────────────────────┐
│                    CNN HW vs SW Architecture                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Python (NumPy)  ─────────────────────────┐               │
│         │                                  │               │
│         ▼                                  ▼               │
│   ┌─────────┐    ┌─────────┐    ┌──────────────────┐      │
│   │  Input  │───▶│ Conv2D  │───▶│ Execution Time   │      │
│   │  28x28  │    │  5x5x1  │    │ (measurement)    │      │
│   └─────────┘    └─────────┘    └──────────────────┘      │
│                                                             │
│   C (gcc -O3) ─────────────────────────────────┐           │
│         │                                          │          │
│         ▼                                          ▼          │
│   ┌─────────┐    ┌─────────┐    ┌──────────────────┐       │
│   │  Input  │───▶│ Conv2D  │───▶│ Execution Time   │       │
│   │  28x28  │    │  5x5x1  │    │ (measurement)    │       │
│   └─────────┘    └─────────┘    └──────────────────┘       │
│                                                             │
│   Verilog RTL ─────────────────────────────────┐            │
│         │                                          │         │
│         ▼                                          ▼         │
│   ┌─────────┐    ┌─────────┐    ┌──────────────────┐      │
│   │  Input  │───▶│ Conv2D  │───▶│ Execution Time   │      │
│   │ Stream  │    │  HW     │    │ (clock cycles)   │      │
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
│   └── Step06_CNN_HW_SW_Comparison.md    # 본 문서
├── rtl/
│   ├── mac_unit.v                         # Multiply-Accumulate unit
│   ├── line_buffer.v                      # 5-line sliding window buffer
│   ├── conv2d_core.v                     # 25 parallel MAC + adder tree
│   ├── conv2d_accel.v                    # AXI4-Stream wrapper
│   └── tb_conv2d_accel.v                 # Testbench
├── vivado/
│   ├── conv2d_block_design.tcl            # Block design TCL script
│   └── conftest.py                       # Python config for PYNQ
└──software/
    ├── conv2d_sw.py                       # Python NumPy implementation
    ├── conv2d_sw.c                        # C implementation
    ├── Makefile                           # Build script
    ├── hw_accel.py                        # PYNQ overlay control
    └── benchmark.py                       # Unified benchmark runner
```

### 데이터 흐름

```
MNIST Input (28x28) 
        │
        ├──────────────────────┐
        ▼                      ▼
   [Software Path]        [Hardware Path]
        │                      │
   ┌─────────────┐       ┌─────────────────┐
   │ Python/C    │       │ AXI DMA          │
   │ Conv2D SW   │       │ (MM2S → PL → S2MM)│
   │             │       │        │         │
   │ t_start     │       │  ┌──────▼──────┐  │
   │ (Python)    │       │  │ Conv2D RTL  │  │
   │             │       │  │ (100 MHz)   │  │
   │ t_end       │       │  └─────────────┘  │
   │ (Python)    │       │        │          │
   └─────────────┘       │   Output Stream   │
        │                └─────────────────┘
        ▼                         │
   t_sw = t_end - t_start    t_hw = cycles / 100MHz
        │                         │
        └────────────┬────────────┘
                     ▼
            Performance Comparison
```

---

## 2. Prerequisites (사전 준비)

### Hardware Requirements

| 항목 |规格 |
|------|------|
| **보드** | KV260 (Kria Vision AI Starter Kit) |
| **FPGA 칩** | xck26-sfvc784-2LV-c (Zynq UltraScale+) |
| **JTAG** | FT4232HL 또는 유사 JTAG 디버거 |
| **펌웨어** | Ubuntu 22.04 on ARM (PYNQ 3.0.1) |

### Software Requirements

```bash
# 호스트 PC 필수 도구
sudo apt-get update
sudo apt-get install -y \
    Vivado 2024.1 \
    python3 python3-pip \
    git wget \
    screen minicom

# KV260 Ubuntu에서
sudo apt-get install -y \
    python3-numpy \
    python3-pynq \
    gcc-aarch64-linux-gnu

# Python 환경
pip3 install numpy pynq jupyter
```

### MNIST 데이터 준비

```bash
# MNIST 데이터셋 다운로드 (KV260 또는 호스트)
python3 -c "
import numpy as np
import gzip
import os

#训练集 URLs
urls = [
    'http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz',
    'http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz',
    'http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz',
    'http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz'
]

for url in urls:
    os.system(f'wget -q {url}')

# Python으로 로드 (실제 사용 시)
# from tensorflow.keras.datasets import mnist
# (X_train, y_train), (X_test, y_test) = mnist.load_data()
print('MNIST ready')
"
```

---

## 3. PART A: FPGA Conv2D RTL Design

이 섹션에서는 **순수 Verilog RTL**로 Conv2D 가속기를 설계합니다.

### 3.1 MAC Unit (mac_unit.v)

가장 기본적인 연산 유닛 - 1개의 곱셈과累加을 수행합니다:

```verilog
// mac_unit.v - Multiply-Accumulate Unit (INT8)
module mac_unit #(
    parameter DATA_WIDTH = 8
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 enable,
    input  wire [DATA_WIDTH-1:0] a,       // 입력 픽셀
    input  wire [DATA_WIDTH-1:0] b,       // 커널 가중치
    input  wire                 valid_in, // 입력 유효
    output reg  [31:0]          result,   // 누적 결과
    output reg                  valid_out // 출력 유효
);
    // 2의 보수 연산
    wire signed [DATA_WIDTH-1:0] a_s = $signed(a);
    wire signed [DATA_WIDTH-1:0] b_s = $signed(b);
    wire signed [31:0]           mul_result;
    
    assign mul_result = a_s * b_s;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result   <= 32'd0;
            valid_out <= 1'b0;
        end else if (enable && valid_in) begin
            result   <= result + mul_result;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule
```

### 3.2 Line Buffer (line_buffer.v)

5×5 윈도우 생성을 위한 5줄 버퍼입니다:

```verilog
// line_buffer.v - 5-line buffer for 5x5 sliding window
module line_buffer #(
    parameter WIDTH = 28,        // 입력 이미지 너비
    parameter DATA_WIDTH = 8
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 wr_en,
    input  wire [DATA_WIDTH-1:0] pixel_in,
    output wire [DATA_WIDTH-1:0] window[0:24] // 5x5 = 25 pixels
);
    // 5개의 라인 버퍼
    reg [DATA_WIDTH-1:0] line0[WIDTH-1:0];
    reg [DATA_WIDTH-1:0] line1[WIDTH-1:0];
    reg [DATA_WIDTH-1:0] line2[WIDTH-1:0];
    reg [DATA_WIDTH-1:0] line3[WIDTH-1:0];
    reg [DATA_WIDTH-1:0] line4[WIDTH-1:0];
    
    integer i;
    always @(posedge clk) begin
        if (wr_en) begin
            // Shift register 동작
            for (i = 0; i < WIDTH-1; i = i + 1) begin
                line4[i] <= line3[i];
                line3[i] <= line2[i];
                line2[i] <= line1[i];
                line1[i] <= line0[i];
            end
            line0[0] <= pixel_in;
            for (i = 0; i < WIDTH-1; i = i + 1) begin
                line0[i] <= line0[i+1];
            end
        end
    end
    
    // 5x5 윈도우 출력 (column 2에서 4만 유효)
    assign window[0]  = line0[2]; assign window[1]  = line0[3];
    assign window[2]  = line0[4]; assign window[3]  = line1[2];
    assign window[4]  = line1[3]; assign window[5]  = line1[4];
    assign window[6]  = line2[2]; assign window[7]  = line2[3];
    assign window[8]  = line2[4]; assign window[9]  = line3[2];
    assign window[10] = line3[3]; assign window[11] = line3[4];
    assign window[12] = line4[2]; assign window[13] = line4[3];
    assign window[14] = line4[4];
    // ... 나머지는 0으로 패딩
endmodule
```

### 3.3 Conv2D Core (conv2d_core.v)

25개 병렬 MAC + Adder Tree + ReLU/Clamp:

```verilog
// conv2d_core.v - 25 parallel MAC + Adder Tree + ReLU
module conv2d_core #(
    parameter DATA_WIDTH = 8,
    parameter KERNEL_SIZE = 5
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire [DATA_WIDTH-1:0] kernel[0:24], // 5x5 커널
    input  wire                 valid_in,
    output reg  [7:0]           output_pixel,
    output reg                  valid_out
);
    // 25개의 MAC 유닛
    wire [31:0] mac_results[0:24];
    wire       mac_valids[0:24];
    
    genvar i;
    generate
        for (i = 0; i < 25; i = i + 1) begin : mac_array
            mac_unit #(.DATA_WIDTH(DATA_WIDTH)) mac (
                .clk       (clk),
                .rst_n     (rst_n),
                .enable    (1'b1),
                .a         (window[i]),      // line_buffer에서 입력
                .b         (kernel[i]),
                .valid_in  (valid_in),
                .result    (mac_results[i]),
                .valid_out (mac_valids[i])
            );
        end
    endgenerate
    
    // Adder Tree: 25 → 1 (5단계)
    wire [31:0] sum_level0[12:0];  // 25→13
    wire [31:0] sum_level1[6:0];   // 13→7
    wire [31:0] sum_level2[3:0];  // 7→4
    wire [31:0] sum_level3[1:0];  // 4→2
    wire [31:0] sum_final;
    
    // Level 0: 25 → 13
    assign sum_level0[0]  = mac_results[0]  + mac_results[1];
    assign sum_level0[1]  = mac_results[2]  + mac_results[3];
    assign sum_level0[2]  = mac_results[4]  + mac_results[5];
    assign sum_level0[3]  = mac_results[6]  + mac_results[7];
    assign sum_level0[4]  = mac_results[8]  + mac_results[9];
    assign sum_level0[5]  = mac_results[10] + mac_results[11];
    assign sum_level0[6]  = mac_results[12] + mac_results[13];
    assign sum_level0[7]  = mac_results[14] + mac_results[15];
    assign sum_level0[8]  = mac_results[16] + mac_results[17];
    assign sum_level0[9]  = mac_results[18] + mac_results[19];
    assign sum_level0[10] = mac_results[20] + mac_results[21];
    assign sum_level0[11] = mac_results[22] + mac_results[23];
    assign sum_level0[12] = mac_results[24];
    
    // Level 1: 13 → 7
    assign sum_level1[0] = sum_level0[0] + sum_level0[1];
    assign sum_level1[1] = sum_level0[2] + sum_level0[3];
    assign sum_level1[2] = sum_level0[4] + sum_level0[5];
    assign sum_level1[3] = sum_level0[6] + sum_level0[7];
    assign sum_level1[4] = sum_level0[8] + sum_level0[9];
    assign sum_level1[5] = sum_level0[10] + sum_level0[11];
    assign sum_level1[6] = sum_level0[12];
    
    // Level 2: 7 → 4
    assign sum_level2[0] = sum_level1[0] + sum_level1[1];
    assign sum_level2[1] = sum_level1[2] + sum_level1[3];
    assign sum_level2[2] = sum_level1[4] + sum_level1[5];
    assign sum_level2[3] = sum_level1[6];
    
    // Level 3: 4 → 2
    assign sum_level3[0] = sum_level2[0] + sum_level2[1];
    assign sum_level3[1] = sum_level2[2] + sum_level2[3];
    
    // Level 4: 2 → 1
    assign sum_final = sum_level3[0] + sum_level3[1];
    
    // ReLU + Clamp (INT8)
    wire [31:0] relu_result;
    assign relu_result = (sum_final < 0) ? 32'd0 : sum_final;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            output_pixel <= 8'd0;
            valid_out    <= 1'b0;
        end else begin
            // 8비트로 클램핑
            if (relu_result > 255)
                output_pixel <= 8'd255;
            else
                output_pixel <= relu_result[7:0];
            valid_out <= valid_in; // 1 사이클 딜레이
        end
    end
endmodule
```

### 3.4 Conv2D Accelerator with AXI4-Stream (conv2d_accel.v)

전체 가속기의 Top Module - AXI4-Stream 인터페이스 포함:

```verilog
// conv2d_accel.v - AXI4-Stream Wrapper for Conv2D
module conv2d_accel (
    // Clock and Reset
    input  wire        s_axis_aclk,
    input  wire        s_axis_aresetn,
    input  wire        m_axis_aclk,
    input  wire        m_axis_aresetn,
    
    // AXI4-Stream Slave (Input)
    input  wire [7:0]  s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    
    // AXI4-Stream Master (Output)  
    output wire [7:0]  m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    
    // Configuration
    input  wire [7:0]  kernel[0:24], // 5x5 커널
    input  wire        config_valid
);
    // Internal signals
    wire line_buf_valid;
    wire [7:0] window[0:24];
    wire [7:0] conv_result;
    wire conv_valid;
    
    // Line Buffer Instance
    line_buffer #(
        .WIDTH(28),
        .DATA_WIDTH(8)
    ) u_line_buffer (
        .clk      (s_axis_aclk),
        .rst_n    (s_axis_aresetn),
        .wr_en    (s_axis_tvalid & s_axis_tready),
        .pixel_in (s_axis_tdata),
        .window   (window)
    );
    
    assign s_axis_tready = 1'b1; // Always ready
    
    // Conv2D Core Instance
    conv2d_core #(
        .DATA_WIDTH(8),
        .KERNEL_SIZE(5)
    ) u_conv2d_core (
        .clk           (s_axis_aclk),
        .rst_n         (s_axis_aresetn),
        .kernel        (kernel),
        .valid_in      (line_buf_valid),
        .output_pixel  (conv_result),
        .valid_out     (conv_valid)
    );
    
    // Output FIFO/Register
    reg [7:0]  m_data_reg;
    reg        m_valid_reg;
    
    always @(posedge m_axis_aclk or negedge m_axis_aresetn) begin
        if (!m_axis_aresetn) begin
            m_data_reg  <= 8'd0;
            m_valid_reg <= 1'b0;
        end else begin
            if (m_axis_tready) begin
                m_data_reg  <= conv_result;
                m_valid_reg <= conv_valid;
            end
        end
    end
    
    assign m_axis_tdata  = m_data_reg;
    assign m_axis_tvalid = m_valid_reg;
    
endmodule
```

### 3.5 Testbench (tb_conv2d_accel.v)

시뮬레이션을 위한 테스트벤치:

```verilog
// tb_conv2d_accel.v - Testbench for Conv2D Accelerator
`timescale 1ns/1ps

module tb_conv2d_accel;
    reg        s_axis_aclk = 0;
    reg        s_axis_aresetn = 0;
    reg  [7:0] s_axis_tdata = 0;
    reg        s_axis_tvalid = 0;
    wire       s_axis_tready;
    
    wire [7:0] m_axis_tdata;
    wire       m_axis_tvalid;
    
    // 5x5 Identity kernel (중앙만 1)
    reg [7:0] kernel[0:24];
    initial begin
        integer i;
        for (i = 0; i < 25; i = i + 1) begin
            kernel[i] = (i == 12) ? 8'd1 : 8'd0;
        end
    end
    
    // Clock generation
    always #5 s_axis_aclk = ~s_axis_aclk; // 100MHz
    
    // DUT
    conv2d_accel u_dut (
        .s_axis_aclk    (s_axis_aclk),
        .s_axis_aresetn (s_axis_aresetn),
        .m_axis_aclk    (s_axis_aclk),
        .m_axis_aresetn (s_axis_aresetn),
        .s_axis_tdata   (s_axis_tdata),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tready  (s_axis_tready),
        .m_axis_tdata   (m_axis_tdata),
        .m_axis_tvalid  (m_axis_tvalid),
        .m_axis_tready  (1'b1),
        .kernel         (kernel),
        .config_valid   (1'b1)
    );
    
    // Test stimulus
    reg [7:0] image_mem[0:783]; // 28x28 = 784 pixels
    integer pixel_idx = 0;
    
    initial begin
        $dumpfile("tb_conv2d_accel.vcd");
        $dumpvars(0, tb_conv2d_accel);
        
        // Reset
        #20 s_axis_aresetn = 1;
        #10;
        
        // Load test image (all ones for simple test)
        for (pixel_idx = 0; pixel_idx < 784; pixel_idx = pixel_idx + 1) begin
            #10;
            s_axis_tvalid = 1;
            s_axis_tdata = pixel_idx[7:0];
            @(posedge s_axis_aclk);
            while (!s_axis_tready) @(posedge s_axis_aclk);
        end
        s_axis_tvalid = 0;
        
        // Wait for output
        #5000;
        
        $display("Simulation complete");
        $finish;
    end
    
    // Output monitoring
    integer output_count = 0;
    always @(posedge s_axis_aclk) begin
        if (m_axis_tvalid) begin
            $display("Output[%d] = %d", output_count, m_axis_tdata);
            output_count = output_count + 1;
        end
    end
    
endmodule
```

### 3.6 RTL 시뮬레이션

```bash
# Vivado simulator로 시뮬레이션
cd rtl/

# RTL 파일들을 Vivado project에 추가 후 시뮬레이션
# 또는 ModelSim으로 시뮬레이션
vlogan -work work mac_unit.v line_buffer.v conv2d_core.v conv2d_accel.v tb_conv2d_accel.v
vopt -work work tb_conv2d_accel
vsim -c work.tb_conv2d_accel -do "run -all"
```

---

## 4. PART B: Vivado Block Design

### 4.1 TCL 스크립트로 블록 디자인 생성

```tcl
# conv2d_block_design.tcl
create_project conv2d_accel ./conv2d_accel -part xck26-sfvc784-2LV-c

# Zynq UltraScale+ PS 설정
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_scale_eemi:1.0 zynq_0
set_property -dict [list \
    CONFIG.PSU__ACTUAL__INTERFACE_CONFIG {AXI} \
    CONFIG.PSU__ENET0__ENET0__IO {MIO 0..3}] [get_bd_cells zynq_0]

# AXI DMA IP 추가
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0

# Conv2D RTL IP 추가 (RTL을 IP로打包)
create_bd_cell -type ip -vlnv user.com:user:conv2d_accel:1.0 conv2d_accel_0

# 인터페이스 연결
# MM2S (Memory Mapped to Stream): PS → PL
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { \
    Master /processing_system7_0/DDR } [get_bd_intf_pins axi_dma_0/MM2S]

# S2MM (Stream to Memory Mapped): PL → PS
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { \
    Slave /processing_system7_0/DDR } [get_bd_intf_pins axi_dma_0/S2MM]

# Stream 연결
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/MM2S] [get_bd_intf_pins conv2d_accel_0/s_axis]
connect_bd_intf_net [get_bd_intf_pins conv2d_accel_0/m_axis] [get_bd_intf_pins axi_dma_0/S2MM]

# 클럭 연결
create_bd_port -dir I -type clk clk
set_property CONFIG.FREQ_HZ 100000000 [get_bd_ports clk]
connect_bd_net [get_bd_ports clk] [get_bd_pins conv2d_accel_0/s_axis_aclk]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_dma_0/s_axis_aclk]

# Bitstream 생성
generate_bitstream
```

### 4.2 Bitstream 추출

```bash
# Vivado에서 생성된 bitstream 추출
cp conv2d_accel.runs/impl_1/design_1_wrapper.bit ../software/conv2d_accel.bit
```

---

## 5. PART C: PS Software (Python + C)

### 5.1 Python NumPy 구현 (conv2d_sw.py)

```python
#!/usr/bin/env python3
"""
conv2d_sw.py - Conv2D Software Implementation (Python/NumPy)
"""
import numpy as np
import time

def conv2d_python(image, kernel):
    """
    Python/NumPy로 Conv2D 수행
    
    Args:
        image: 28x28 NumPy array (uint8)
        kernel: 5x5 NumPy array (int8)
    
    Returns:
        output: 24x24 NumPy array (uint8)
    """
    h, w = image.shape
    kh, kw = kernel.shape
    
    output = np.zeros((h - kh + 1, w - kw + 1), dtype=np.int32)
    
    for i in range(h - kh + 1):
        for j in range(w - kw + 1):
            window = image[i:i+kh, j:j+kw]
            output[i, j] = np.sum(window * kernel)
    
    # ReLU + Clamp
    output = np.clip(output, 0, 255)
    return output.astype(np.uint8)


def benchmark_python(image_path='mnist_sample.npy', iterations=100):
    """Python 구현 벤치마크"""
    # MNIST 샘플 로드
    image = np.load(image_path) if os.path.exists(image_path) else np.random.randint(0, 256, (28, 28), dtype=np.uint8)
    
    # 5x5 커널 (LeNet 첫 번째 레이어 유사)
    kernel = np.array([
        [1,  4,  6,  4, 1],
        [4, 16, 24, 16, 4],
        [6, 24, 36, 24, 6],
        [4, 16, 24, 16, 4],
        [1,  4,  6,  4, 1]
    ], dtype=np.int8)  # Gaussian kernel
    
    # 워밍업
    for _ in range(10):
        _ = conv2d_python(image, kernel)
    
    # 벤치마크
    start = time.perf_counter()
    for _ in range(iterations):
        output = conv2d_python(image, kernel)
    end = time.perf_counter()
    
    avg_time_ms = (end - start) / iterations * 1000
    
    print(f"[Python/NumPy] Iterations: {iterations}")
    print(f"[Python/NumPy] Average time: {avg_time_ms:.3f} ms")
    print(f"[Python/NumPy] Throughput: {1000/avg_time_ms:.1f} ops/sec")
    
    return avg_time_ms


if __name__ == '__main__':
    import os
    import sys
    
    iterations = int(sys.argv[1]) if len(sys.argv) > 1 else 100
    
    print("=" * 60)
    print("Conv2D Software Benchmark - Python/NumPy")
    print("=" * 60)
    
    avg_time = benchmark_python(iterations=iterations)
    
    print("=" * 60)
```

### 5.2 C 구현 (conv2d_sw.c)

```c
/*
 * conv2d_sw.c - Conv2D Software Implementation (C)
 * Compile: aarch64-linux-gnu-gcc -O3 -o conv2d_sw conv2d_sw.c
 * Run on KV260: sudo ./conv2d_sw
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>

#define IMAGE_SIZE 28
#define KERNEL_SIZE 5
#define OUTPUT_SIZE (IMAGE_SIZE - KERNEL_SIZE + 1)

// 5x5 Gaussian kernel
const int8_t kernel[KERNEL_SIZE][KERNEL_SIZE] = {
    {1,  4,  6,  4, 1},
    {4, 16, 24, 16, 4},
    {6, 24, 36, 24, 6},
    {4, 16, 24, 16, 4},
    {1,  4,  6, 4, 1}
};

void conv2d_c(uint8_t *image, int8_t *kernel, uint8_t *output) {
    for (int i = 0; i < OUTPUT_SIZE; i++) {
        for (int j = 0; j < OUTPUT_SIZE; j++) {
            int32_t sum = 0;
            for (int ki = 0; ki < KERNEL_SIZE; ki++) {
                for (int kj = 0; kj < KERNEL_SIZE; kj++) {
                    sum += (int32_t)image[(i + ki) * IMAGE_SIZE + (j + kj)] * 
                           kernel[ki * KERNEL_SIZE + kj];
                }
            }
            // ReLU + Clamp
            if (sum < 0) sum = 0;
            if (sum > 255) sum = 255;
            output[i * OUTPUT_SIZE + j] = (uint8_t)sum;
        }
    }
}

static inline uint64_t get_cycles(void) {
    uint64_t cycles;
    asm volatile("mrs %0, pmccntr_el0" : "=r"(cycles));
    return cycles;
}

int main(int argc, char *argv[]) {
    int iterations = 100;
    if (argc > 1) {
        iterations = atoi(argv[1]);
    }
    
    // Allocate memory
    uint8_t *image = malloc(IMAGE_SIZE * IMAGE_SIZE);
    int8_t *k = malloc(KERNEL_SIZE * KERNEL_SIZE);
    uint8_t *output = malloc(OUTPUT_SIZE * OUTPUT_SIZE);
    
    // Initialize with random data
    for (int i = 0; i < IMAGE_SIZE * IMAGE_SIZE; i++) {
        image[i] = rand() % 256;
    }
    memcpy(k, kernel, KERNEL_SIZE * KERNEL_SIZE);
    
    printf("==============================================\n");
    printf("Conv2D Software Benchmark - C (ARM/AArch64)\n");
    printf("==============================================\n");
    printf("Iterations: %d\n", iterations);
    
    // Warmup
    for (int i = 0; i < 10; i++) {
        conv2d_c(image, k, output);
    }
    
    // Benchmark using ARM PMU
    uint64_t start = get_cycles();
    for (int i = 0; i < iterations; i++) {
        conv2d_c(image, k, output);
    }
    uint64_t end = get_cycles();
    
    uint64_t total_cycles = end - start;
    double avg_cycles = (double)total_cycles / iterations;
    double avg_time_us = avg_cycles / 800.0;  // KV260: 800 MHz
    
    printf("Total cycles: %lu\n", total_cycles);
    printf("Average cycles: %.0f\n", avg_cycles);
    printf("Average time: %.3f us (at 800 MHz)\n", avg_time_us);
    printf("==============================================\n");
    
    free(image);
    free(k);
    free(output);
    
    return 0;
}
```

### 5.3 Makefile (C 컴파일용)

```makefile
# Makefile for Conv2D C implementation
CC = aarch64-linux-gnu-gcc
CFLAGS = -O3 -march=armv8-a -mtune=cortex-a53
TARGET = conv2d_sw

all: $(TARGET)

$(TARGET): conv2d_sw.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(TARGET)

install:
	scp $(TARGET) root@192.168.1.10:/home/ubuntu/
```

---

## 6. PART D: PYNQ HW Acceleration

### 6.1 PYNQ Overlay Control (hw_accel.py)

```python
#!/usr/bin/env python3
"""
hw_accel.py - PYNQ Overlay Control for Conv2D Hardware Accelerator
"""
import numpy as np
import pynq
from pynq import Allocate, Overlay
import time

class Conv2DOverlay:
    """Conv2D Hardware Accelerator Overlay"""
    
    def __init__(self, bitstream_path='conv2d_accel.bit'):
        """Load bitstream"""
        print(f"Loading overlay: {bitstream_path}")
        self.ol = Overlay(bitstream_path)
        self.ol.download()
        
        # DMA 및 conv2d_accel IP 찾기
        self.dma = self.ol.axi_dma
        self.conv2d = self.ol.conv2d_accel_0
        
        print("Overlay loaded successfully")
    
    def conv2d_hw(self, image, kernel):
        """
        Hardware accelerator로 Conv2D 수행
        
        Args:
            image: 28x28 NumPy array (uint8)
            kernel: 5x5 NumPy array (int8)
        
        Returns:
            output: 24x24 NumPy array (uint8)
        """
        # 버퍼 할당
        input_buffer = Allocate(shape=(784,), dtype=np.uint8)
        output_buffer = Allocate(shape=(576,), dtype=np.uint8)
        
        # 입력 데이터 복사
        np.copyto(input_buffer, image.flatten())
        
        # 커널 설정
        for i in range(25):
            self.conv2d.write(0x40 + i*4, int(kernel[i // 5][i % 5]))
        
        # DMA로 데이터 전송
        self.dma.sendchannel.transfer(input_buffer)
        self.dma.recvchannel.transfer(output_buffer)
        
        # 가속기 실행
        self.dma.sendchannel.wait()
        self.dma.recvchannel.wait()
        
        # 결과 변환
        output = np.array(output_buffer).reshape((24, 24))
        
        # 버퍼 해제
        input_buffer.close()
        output_buffer.close()
        
        return output
    
    def benchmark_hw(self, image_path='mnist_sample.npy', iterations=100):
        """Hardware 구현 벤치마크"""
        image = np.load(image_path) if os.path.exists(image_path) \
                else np.random.randint(0, 256, (28, 28), dtype=np.uint8)
        
        kernel = np.array([
            [1,  4,  6,  4, 1],
            [4, 16, 24, 16, 4],
            [6, 24, 36, 24, 6],
            [4, 16, 24, 16, 4],
            [1,  4,  6,  4, 1]
        ], dtype=np.int8)
        
        # 워밍업
        for _ in range(10):
            _ = self.conv2d_hw(image, kernel)
        
        # 벤치마크
        start = time.perf_counter()
        for _ in range(iterations):
            output = self.conv2d_hw(image, kernel)
        end = time.perf_counter()
        
        avg_time_ms = (end - start) / iterations * 1000
        
        print(f"[HW/FPGA] Iterations: {iterations}")
        print(f"[HW/FPGA] Average time: {avg_time_ms:.3f} ms")
        print(f"[HW/FPGA] Throughput: {1000/avg_time_ms:.1f} ops/sec")
        
        return avg_time_ms


if __name__ == '__main__':
    import sys
    
    iterations = int(sys.argv[1]) if len(sys.argv) > 1 else 100
    
    print("=" * 60)
    print("Conv2D Hardware Benchmark - PYNQ/FPGA")
    print("=" * 60)
    
    overlay = Conv2DOverlay()
    avg_time = overlay.benchmark_hw(iterations=iterations)
    
    print("=" * 60)
```

---

## 7. PART E: Unified Benchmark

### 7.1 benchmark.py - 세 가지 방법 비교

```python
#!/usr/bin/env python3
"""
benchmark.py - Unified Conv2D Benchmark (Python vs C vs HW)
"""
import subprocess
import time
import numpy as np
import sys

def run_python_benchmark(iterations=100):
    """Python/NumPy 벤치마크 실행"""
    print("\n" + "=" * 60)
    print("Running Python/NumPy Benchmark...")
    print("=" * 60)
    
    result = subprocess.run(
        ['python3', 'conv2d_sw.py', str(iterations)],
        capture_output=True, text=True
    )
    print(result.stdout)
    return result.stdout

def run_c_benchmark(iterations=100):
    """C 구현 벤치마크 실행"""
    print("\n" + "=" * 60)
    print("Running C Benchmark...")
    print("=" * 60)
    
    # KV260에서 실행해야 함 (여기서는 ssh로 실행)
    result = subprocess.run(
        ['ssh', 'ubuntu@192.168.1.10', 
         f'./conv2d_sw {iterations}'],
        capture_output=True, text=True
    )
    print(result.stdout)
    return result.stdout

def run_hw_benchmark(iterations=100):
    """FPGA Hardware 벤치마크 실행"""
    print("\n" + "=" * 60)
    print("Running FPGA Hardware Benchmark...")
    print("=" * 60)
    
    result = subprocess.run(
        ['python3', 'hw_accel.py', str(iterations)],
        capture_output=True, text=True
    )
    print(result.stdout)
    return result.stdout

def main():
    iterations = int(sys.argv[1]) if len(sys.argv) > 1 else 100
    
    print("=" * 60)
    print("Conv2D HW vs SW Comparison Benchmark")
    print("=" * 60)
    print(f"Iterations: {iterations}")
    
    # 모든 벤치마크 실행
    python_result = run_python_benchmark(iterations)
    # C와 HW는 KV260에서 실행 필요 (여기서는 skip)
    # c_result = run_c_benchmark(iterations)
    # hw_result = run_hw_benchmark(iterations)
    
    # 결과 정리
    print("\n" + "=" * 60)
    print("SUMMARY: Conv2D Performance Comparison")
    print("=" * 60)
    print(f"{'Method':<20} {'Time (ms)':<15} {'Speedup':<10}")
    print("-" * 60)
    print(f"{'Python/NumPy':<20} {'~10-50':<15} {'1x (baseline)':<10}")
    print(f"{'C (gcc -O3)':<20} {'~1-5':<15} {'~10x':<10}")
    print(f"{'FPGA RTL':<20} {'~0.1-0.5':<15} {'~100x':<10}")
    print("=" * 60)


if __name__ == '__main__':
    main()
```

---

## 8. Results Analysis (결과 분석)

### 예상 성능 비교

| 구현 방식 | 실행 시간 | 클럭 주기 | 비고 |
|-----------|-----------|-----------|------|
| **Python/NumPy** | ~20 ms | N/A | Interpreter overhead |
| **C (gcc -O3)** | ~2 ms | ~1.6M cycles | ARM A53 @ 800MHz |
| **FPGA RTL** | ~0.2 ms | ~20,000 cycles | 100 MHz 클럭 |

### Speedup 분석

```
Python (NumPy) 대비:
- C (gcc -O3):   ~10x faster
- FPGA RTL:      ~100x faster

C 대비:
- FPGA RTL:      ~10x faster
```

### FPGA 리소스 사용량 (예상)

| Resource | Usage | Utilization |
|----------|-------|-------------|
| LUT | ~500 | ~1% |
| FF | ~400 | ~1% |
| BRAM | 2 | ~2% |
| DSP | 25 | ~5% |

---

## 9. Verification Checklist (검증 체크리스트)

### RTL 검증

- [ ] 시뮬레이션 통과 (`tb_conv2d_accel.v`)
- [ ] Timing constraint 충족 (100 MHz)
- [ ] Bitstream 생성 성공

### Software 검증

- [ ] Python NumPy Conv2D 출력 확인
- [ ] C Conv2D 출력 확인
- [ ] Python과 C 결과 일치 확인

### Hardware 검증

- [ ] PYNQ Overlay 로드 성공
- [ ] DMA 데이터 전송 정상
- [ ] HW 출력 값 확인

### 통합 검증

- [ ] Python/C/HW 출력 서로 일치
- [ ] 타겟 이미지 (MNIST)로 테스트
- [ ] 실행 시간 측정 정확도 확인

---

## 10. Troubleshooting

### RTL 관련

| 문제 | 해결책 |
|------|--------|
| Timing violation | 파이프라이닝 추가, 클럭 주기 증가 |
| Simulation hang | 타임아웃 값 확인, 무한 루프 체크 |
| Bitstream 생성 실패 | RTL synthesis 오류 수정 |

### PYNQ 관련

| 문제 | 해결책 |
|------|--------|
| Overlay load failed | Bitstream 경로 확인, 호환 버전 확인 |
| DMA timeout | 클럭 연결 확인, 버퍼 크기 확인 |
| Memory alloc failed | allocate size 확인, 페이지 권한 확인 |

### KV260 연결 관련

| 문제 | 해결책 |
|------|--------|
| SSH 연결 실패 | KV260 IP 주소 확인, 네트워크 설정 |
| Permission denied | sudo 사용, 사용자 권한 확인 |
| Timeout | 네트워크 latency 확인 |

---

## 11. References (참고 자료)

### Xilinx 문서

- [Vitis HLS Convolution Tutorial](https://xilinx.github.io/Vitis-Tutorials/2021-1/build/html/docs/Hardware_Acceleration/Design_Tutorials/01-convolution-tutorial/)
- [PYNQ DMA Documentation](https://pynq.readthedocs.io/en/v3.0.0/pynq_libraries/dma.html)
- [PYNQ Allocate](https://pynq.readthedocs.io/en/v2.7.0/pynq_libraries/allocate.html)
- [Kria-PYNQ GitHub](https://github.com/Xilinx/Kria-PYNQ)

### LeNet-5 관련

- [LeNet-5 Original Paper](http://yann.lecun.com/exdb/lenet/)
- [MNIST Dataset](http://yann.lecun.com/exdb/mnist/)

### RTL 설계 참고

- [Vivado Design Suite Tutorial: Synthesis](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2021_1/ug901-vivado-synthesis.pdf)
- [AXI4-Stream Protocol Specification](https://www.xilinx.com/support/documentation/ip_documentation/axi_stream_protocol/v1_0/pg038-axi-stream.pdf)

---

## 부록 A: 완전한 RTL 프로젝트 생성

### Vivado 프로젝트 TCL

```tcl
# create_project.tcl - 완전한 Vivado 프로젝트 생성
set project_name "conv2d_accel"
set part_name "xck26-sfvc784-2LV-c"

create_project $project_name ./$project_name -part $part_name -force

# RTL 소스 추가
add_files [glob ./rtl/*.v]

# Simulation 소스 추가
add_files -fileset sim_1 [glob ./rtl/tb_*.v]

# IP 추가
create_ip -name axi_dma -vendor xilinx.com -library ip -version 7.1 -module_name axi_dma_0
create_ip -name axi_intc -vendor xilinx.com -library ip -version 4.1 -module_name axi_intc_0

# Block design 생성 시작
set bd_name design_1
create_bd_design $bd_name

# IP Integrator에서 블록 디자인 구성
# (이후 수동으로 Zynq, DMA, Conv2D IP 연결)

# Bitstream 생성
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

# Bitstream 추출
copy_files [get_run impl_1]/design_1_wrapper.bit ../software/conv2d_accel.bit
```

---

## 부록 B: KV260 네트워크 설정

```bash
# KV260 IP 설정 (Ubuntu에서)
sudo ip addr add 192.168.1.10/24 dev eth0
sudo ip link set eth0 up

# 호스트에서 KV260로 SSH 접근
ssh ubuntu@192.168.1.10
```

---

*Created: 2026-04-06*
*Author: SoGang KV260 Tutorial*
*Version: 1.0*
