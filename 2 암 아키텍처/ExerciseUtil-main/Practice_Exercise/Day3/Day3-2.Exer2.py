from pynq.lib.logictools.waveform import draw_wavedrom
waveform_dict = {
  "signal": [
    { "name": "SCK", "wave": "p..............................." },    { "name": "WS",  "wave": "0...............1..............." },
    { "name": "SD",  "wave": "1..01010101010101...010101010101" },
    { "name": "",    "wave": "44444444444444444444444444444444",
      "data": ["L15", "L14", "L13", "L12", "L11", "L10", "L9", "L8", "L7", "L6", "L5", "L4", "L3", "L2", "L1", "L0",
        "R15", "R14", "R13", "R12", "R11", "R10", "R9", "R8", "R7", "R6", "R5", "R4", "R3", "R2", "R1", "R0"]}
  ], "head": { "text": "I2S Audio Transmission (16-bit stereo)" }
}
draw_wavedrom(waveform_dict )
