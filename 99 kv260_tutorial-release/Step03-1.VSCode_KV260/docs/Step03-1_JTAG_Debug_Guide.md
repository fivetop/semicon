# KV260 JTAG 디버깅 환경 구축 가이드 (OpenOCD + VSCode)

본 가이드는 OpenOCD를 사용하여 KV260 보드를 JTAG으로 연결하고,
VSCode에서 소스 레벨 디버깅을 수행하는 전체 절차를 단계별로 설명합니다.

---

## 시스템 구성

```
[KV260 보드]
  Micro-USB  ─── USB-JTAG (FTDI FT4232HL, Channel 0)
  USB-A      ─── 전원
       │
  usbipd-win (Windows) ──→ WSL2 Ubuntu로 USB 포워딩
       │
[WSL2 Ubuntu]
  openocd                 ← JTAG 서버 (port 3333 listen)
       │  GDB Remote Protocol (localhost:3333)
  aarch64-linux-gnu-gdb
       │
[VSCode (Windows)]
  C/C++ Extension (cppdbg) ─→ WSL GDB 연결
  "KV260 JTAG Debug (OpenOCD)" 설정
```

---

## 사전 준비

### 필요한 소프트웨어
| 소프트웨어 | 확인 명령 | 설치 명령 (WSL) |
|-----------|----------|----------------|
| openocd | `openocd --version` | `sudo apt install openocd` |
| aarch64-linux-gnu-gdb | `aarch64-linux-gnu-gdb --version` | Vitis 2024.2에 포함 |
| usbipd-win | `usbipd list` (Windows) | [usbipd-win 설치](https://github.com/dorssel/usbipd-win) |

---

## STEP 1: USB 연결 확인

KV260의 Micro-USB 포트를 PC에 연결한 후, WSL에서 FTDI 장치가 보이는지 확인합니다.

```bash
# WSL에서 실행
lsusb | grep -i "ftdi\|future tech"
```

### 예상 출력:
```
Bus 001 Device 003: ID 0403:6011 Future Technology Devices International, Ltd FT4232H Quad HS USB-UART/FIFO IC
```

### VID:PID 확인 및 설정 수정
`0403:6011`이 출력되면 `kv260-openocd.cfg`의 설정이 이미 올바릅니다.

다른 값이 출력된 경우 `kv260-openocd.cfg`를 수정합니다:
```tcl
# 예: 0403:6010인 경우
ftdi vid_pid 0x0403 0x6010
```

---

## STEP 2: FTDI 커널 드라이버 언바인드

OpenOCD는 FTDI 장치를 libusb로 직접 제어합니다.
Linux 커널의 `ftdi_sio` 드라이버가 먼저 장치를 점유하면 OpenOCD가 접근하지 못합니다.

```bash
# 커널 드라이버 언바인드
sudo modprobe -r ftdi_sio

# 언바인드 확인 (ftdi_sio 모듈이 없어야 함)
lsmod | grep ftdi
```

### 주의사항
- `ftdi_sio` 언바인드 시 KV260의 UART 콘솔(`/dev/ttyUSBx`)도 사용 불가해집니다.
- OpenOCD 종료 후 다시 로드: `sudo modprobe ftdi_sio`

### 영구적 udev 규칙 설정 (매번 sudo 없이 사용)

```bash
# udev 규칙 파일 생성
sudo tee /etc/udev/rules.d/99-openocd-kv260.rules << 'EOF'
# KV260 FTDI FT4232H - OpenOCD 접근 허용
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6011", MODE="0666", GROUP="plugdev"
# FTDI ftdi_sio 드라이버 자동 언바인드 방지 (수동으로만)
EOF

# 규칙 적용
sudo udevadm control --reload-rules
sudo udevadm trigger
```

---

## STEP 3: OpenOCD 단독 실행 테스트

VSCode를 열기 전에 먼저 터미널에서 OpenOCD가 정상 동작하는지 확인합니다.

```bash
# Step03-1.VSCode_KV260 디렉토리에서 실행
cd /home/woody/SoGang/2026-03/kv260_vivado_tutorial/Step03-1.VSCode_KV260

sudo openocd -f kv260-openocd.cfg
```

### ✅ 성공 출력 예시:
```
Open On-Chip Debugger 0.12.0
...
Info : clock speed 1000 kHz
Info : JTAG tap: uscale.tap tap/device found: 0x5ba00477 ...
Info : JTAG tap: uscale.ps tap/device found: 0x04711093 ...
Info : uscale.apu.a53.0: hardware has 6 breakpoints, 4 watchpoints
Info : starting gdb server for uscale.apu.a53.0 on 3333
Info : Listening on port 3333 for gdb connections   ← 이 메시지까지 나와야 성공
Info : Listening on port 4444 for telnet connections
```

### ❌ 실패 케이스별 해결

| 오류 메시지 | 원인 | 해결 |
|------------|------|------|
| `libusb_open() failed with LIBUSB_ERROR_ACCESS` | sudo 없이 실행 | `sudo openocd ...` |
| `Error: no device found` | FTDI 드라이버가 점유 중 | `sudo modprobe -r ftdi_sio` 후 재시도 |
| `JTAG scan chain interrogation failed` | VID:PID 불일치 | `kv260-openocd.cfg`의 `ftdi vid_pid` 수정 |
| `Error: tap/device not found` | 케이블 불량 또는 usbipd 미연결 | USB 재연결, `usbipd attach` 확인 |
| `ftdi layout_init` 관련 오류 | FTDI 레이아웃 값 불일치 | `ftdi layout_init 0x0008 0x000b`로 변경 시도 |

---

## STEP 4: GDB 연결 테스트 (터미널)

OpenOCD가 실행 중인 상태에서 **새 터미널**을 열어 GDB 연결을 테스트합니다.

```bash
# 새 WSL 터미널에서
cd /home/woody/SoGang/2026-03/kv260_vivado_tutorial/Step03-1.VSCode_KV260

/tools/Xilinx/Vitis/2021.2/gnu/aarch64/lin/aarch64-linux/bin/aarch64-linux-gnu-gdb \
    src/gpio_led_app.elf
```

GDB 프롬프트에서 순서대로 입력합니다:

```gdb
(gdb) target extended-remote localhost:3333
```
### ✅ 예상 출력:
```
Remote debugging using localhost:3333
0x0000000000000000 in ?? ()
```

```gdb
(gdb) monitor halt
```
### ✅ 예상 출력:
```
target halted in AArch64 state due to debug-request, ...
```

```gdb
(gdb) file build/led_blink.elf
```
### ✅ 예상 출력:
```
Loading section .text, size 0x... lma 0x...
Loading section .data, size 0x... lma 0x...
Start address 0x..., load size ...
Transfer rate: ... KB/sec, ... bytes/write.
```

```gdb
(gdb) monitor reset halt
(gdb) break main
(gdb) continue
```
### ✅ 예상 출력:
```
Breakpoint 1, main () at main.c:10
10    int main(void) {
```

**브레이크포인트가 정상적으로 동작하면 JTAG 환경이 올바르게 설정된 것입니다.**

---

## STEP 5: VSCode에서 JTAG 디버깅 (F5)

STEP 3-4가 성공한 후 VSCode 디버깅을 시도합니다.

### 실행 순서:

1. **OpenOCD 종료** (STEP 3에서 실행 중이면 `Ctrl+C`)

2. **VSCode에서 Step03-1.VSCode_KV260 폴더 열기**

3. **디버그 설정 확인**
   - 왼쪽 사이드바 → `Run and Debug` (Ctrl+Shift+D)
   - 드롭다운에서 **"KV260 JTAG Debug (OpenOCD)"** 선택

4. **F5 눌러 디버깅 시작**

### F5 자동 실행 순서:
```
F5 누름
  │
  ├─ [preLaunchTask] "Start OpenOCD" 실행
  │     → sudo openocd -f kv260-openocd.cfg
  │     → "Listening on port 3333..." 메시지 감지
  │
  ├─ GDB 실행 및 localhost:3333 연결
  │
  ├─ setupCommands 순서 실행:
  │     1. monitor halt        (CPU 정지)
  │     2. file                (ELF 심볼 로드)
  │     3. monitor reset halt  (리셋 후 entry 정지)
  │
  └─ main() 진입 → 브레이크포인트 대기
```

### ✅ 성공 화면:
- VSCode 하단 상태바가 주황색으로 변경
- 소스 코드 10번째 줄(또는 `main()` 진입점)에 노란색 화살표 표시
- 좌측 패널에 LOCALS, CALL STACK, BREAKPOINTS 표시

---

## STEP 6: 브레이크포인트 동작 확인

```c
// src/main.c 에서 브레이크포인트 설정 위치 예시
int main(void) {
    // ← 여기 (Line 10) 브레이크포인트 설정
    init_gpio();
    while (1) {
        // ← 여기 (while 내부) 브레이크포인트 설정
        toggle_led();
        sleep(1);
    }
}
```

### 테스트 항목:

| 테스트 | 방법 | ✅ 성공 조건 |
|--------|------|------------|
| main() 브레이크 | F5 누름 | main 진입 시 자동 정지 |
| 소스 내 브레이크 | 라인 번호 좌측 클릭 | 해당 줄에서 정지 |
| 단계 실행 | F10 (Step Over) | 한 줄씩 이동 |
| 함수 진입 | F11 (Step Into) | 함수 내부로 이동 |
| 변수 확인 | LOCALS 패널 | 변수 값 실시간 표시 |
| 계속 실행 | F5 | 다음 브레이크까지 실행 |
| 디버그 종료 | Shift+F5 | OpenOCD도 자동 종료 |

---

## 트러블슈팅

### OpenOCD가 시작되지 않음 (preLaunchTask 오류)

```bash
# 원인: sudo 암호 프롬프트 문제
# 해결: sudoers에 openocd 추가 (암호 없이 실행)
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/openocd" | sudo tee /etc/sudoers.d/openocd
```

### GDB가 3333 포트에 연결 실패

```bash
# OpenOCD가 실행 중인지 확인
ps aux | grep openocd

# 포트 3333이 열려있는지 확인
ss -tlnp | grep 3333
```

### `monitor reset halt` 후 프로그램이 시작되지 않음

```
원인: KV260의 PS가 초기화되지 않아 DDR 메모리 접근 불가
해결: psu_init.tcl을 실행해 PS를 초기화해야 함

GDB에서 수동으로:
(gdb) monitor reset halt
(gdb) monitor load_image /path/to/psu_init.tcl
```

또는 GDB init 파일 활용 (아래 고급 설정 참고).

### 브레이크포인트에서 멈추지 않음

```bash
# 원인: 최적화 빌드 (-O2)로 인해 소스 매핑이 깨짐
# 해결: src/Makefile에서 디버그 플래그 확인

# Makefile에 다음이 있어야 함:
CFLAGS = -O0 -g3 -Wall
```

---

## 참고: 기존 gdbserver 방식과 비교

| 항목 | gdbserver (기존) | OpenOCD JTAG (현재) |
|------|-----------------|-------------------|
| 네트워크 필요 | ✅ SSH/이더넷 | ❌ USB만 |
| sudo 문제 | ✅ 있음 | ❌ udev 규칙으로 해결 |
| ELF 배포 | scp 필요 | GDB `file` 자동 |
| 하드웨어 브레이크포인트 | ❌ 소프트웨어만 | ✅ 하드웨어 4개 |
| 부팅 필요 | ✅ Linux 완전 부팅 | ⚠️ PS 초기화 필요 |

---

## 파일 구조

```
Step03-1.VSCode_KV260/
├── kv260-openocd.cfg          ← [신규] OpenOCD 설정
├── .vscode/
│   ├── launch.json            ← [수정] JTAG 설정 추가
│   └── tasks.json             ← [수정] OpenOCD 태스크 추가
├── image/
│   ├── gpio_led_rtl.bit
│   └── psu_init.tcl           ← PS 초기화 스크립트
└── src/
    ├── main.c
    ├── Makefile
    └── gpio_led_app.elf
```

---

*가이드 버전: 1.0 | 작성일: 2026-04-05 | 환경: WSL2 + OpenOCD 0.12 + Vitis 2021.2*
