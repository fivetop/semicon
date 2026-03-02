from pynq.lib.logictools.waveform import draw_wavedrom

waveform_dict = {
    "signal": [
        { "name": "TX", "wave": "1.0.1...0.1.0...1.0.1."},
        { "name": "", "wave": "4.4.4.4.4.4.4.4.4.4.4.", "data": ["Idle", "Start", "1", "1", "0", "1", "0", "0", "1", "0", "Stop"]}
    ],
    "foot": {"tock": 0},
    "head": {"text": "UART Transmission @9600 baud: 0x4B (01001011)"}
}
draw_wavedrom(waveform_dict)
