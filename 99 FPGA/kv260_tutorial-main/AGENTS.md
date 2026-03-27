# AGENTS.md - KV260 Vivado Tutorial

## Project Overview

FPGA development tutorial for Xilinx KV260 Vision AI Starter Kit teaching Vivado-based design through 5 steps:
- Step01: LED Blink Basics
- Step02: Vivado IP Integrator
- Step03: AXI GPIO Integration
- Step04: Vitis HLS PMOD
- Step05: KV260 BIST Platform

**Tech Stack**: Vivado 2021.2, Verilog HDL, TCL scripting

---

## Build Commands

All builds run through Vivado TCL scripts in `{StepXX_XXX}/scripts/`:

```bash
# Source Vivado environment (replace /path/to with actual path)
source /tools/Xilinx/Vivado/2021.2/settings64.sh

# Navigate to step directory
cd Step01_LED_Blink_Basics/scripts

# Create project, block design, synthesis, implementation
vivado -mode batch -source create_project.tcl
vivado -mode batch -source create_block_design.tcl
vivado -mode batch -source run_synthesis.tcl
vivado -mode batch -source run_implementation.tcl

# Run all steps at once
vivado -mode batch -source run_all.tcl

# Single script
vivado -mode batch -source <script_name>.tcl
```

---

## Code Style Guidelines

### Verilog (.v) Files

**File Organization**
- License header required (Solderpad Hardware License v0.51)
- Use `module : module_name` syntax for module end
- Parameterized ports

**Naming Conventions**
- Files/Modules/Signals: `snake_case` (e.g., `led_blinker`, `sysclk`, `o_led`)
- Parameters/Constants: `UPPER_SNAKE_CASE` (e.g., `REF_CLK = 100_000_000`)

**Port Declaration Order**: Input clocks → Input resets → Input data → Output signals

**Indentation**: 4 spaces, align begin/end blocks vertically

**Example Module**
```verilog
// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51

module led_blinker #(
    parameter REF_CLK = 100_000_000
)(
    input  wire sysclk,
    output reg  o_led = 1'b0
);
    integer r_count = 0;

    always @(posedge sysclk) begin
        if (r_count < (REF_CLK / 2 - 1)) begin
            r_count <= r_count + 1;
        end else begin
            r_count <= 0;
            o_led <= ~o_led;
        end
    end
endmodule : led_blinker
```

### TCL Scripts (.tcl)

- Naming: lowercase with underscores (`create_project.tcl`)
- Structure: Header with project/version → Variables → Logic with `puts` for progress

### XDC Constraint Files (.xdc)

- Pin and timing constraints for FPGA
- Descriptive naming (e.g., `kv260_pin.xdc`)
- Comment each constraint, group logically

---

## Project Structure

```
kv260_vivado_tutorial/
├── Step01_LED_Blink_Basics/  ├── src/          # Verilog
├── scripts/        # TCL├── constraints/   # XDC
├── Step02_Vivado_IP_Integrator/├── Step03_AXI_GPIO_Integration/
├── Step04_Vitis_HLS_PMOD/
├── Step05_KV260_BIST_Platform/
└── Step00_Overview/docs/
```

---

## Error Handling

**Vivado Errors**
- Check log files for synthesis/implementation errors
- Common: unconnected ports, timing violations, missing constraints
- Use `validate_bd_design` to check block designs

**TCL Script Errors**
- Check return status of commands
- Use `puts` statements to track progress
- Verify file paths before operations

---

## Working with This Project

### Creating a New Step
1. Create directory: `StepXX_Name/`
2. Add `src/`, `scripts/`, `constraints/` subdirectories
3. Create TCL scripts following existing patterns
4. Add Verilog modules in `src/`, constraints in `constraints/`

### Modifying Existing RTL
- Maintain license headers
- Keep consistent naming conventions
- Test changes through Vivado synthesis

---

## KV260 Board Limitations (IMPORTANT)

**Hardware Constraints:**
- **Clock Source**: Main clock (100MHz)과 reset은 PS(Zynq)에서만 제공
  - PL은 독립적인 마스터 클럭 생성 불가
  - 모든 PL 클럭은 PS pl_clk0에서 파생되어야 함
- **External I/O**: PMOD connector 핀만 외부 연결 가능
  - PMOD 외에는 직접적인 GPIO 핀 접근 불가
  - LED/버튼은 PMOD 또는 커스텀 하드웨어 필요

**Design Implications:**
- Clocking Wizard IP는 PS pl_clk0에서 클럭을 분주/증폭
- RTL clock_generator는 클럭 생성용이 아닌 분주용
- 외부 신호는 PMOD 인터페이스를 통해 연결 필요
- 플랫폼 설계는 이러한 제약을 고려해야 함

---

## Notes for Agents

- This is **hardware development**, not software
- No npm/pip/compiler - use Vivado 2021.2
- All builds run through Vivado TCL scripts
- Focus on RTL design and Vivado workflows
- Read corresponding markdown docs for module questions
- Always consider KV260 hardware limitations when designing

---

## Language Guidelines (IMPORTANT)

All conversations, outputs, and documentations must use **English and Korean only**.

- **DO**: Use English and Korean
- **DO NOT**: Use Russian, Chinese, or any other languages
- Examples:
  - ❌ синтез, 上, clk上升時
  - ✅ Synthesis, 상승, 클럭 상승 edge

**Thinking**: Even internal reasoning and thought process must use English or Korean only.
  - ❌ думать, 考える, thinking in other languages
  - ✅ Reasoning in English or Korean

**Todo items**: Must also use English and Korean only.
  - ❌ "pmod 핀调查研究", "时钟分频器"
  - ✅ "PMOD 핀 조사", "클럭 분주기"
