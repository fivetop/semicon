from pynq.lib.logictools.waveform import draw_wavedrom

waveform_dict = {
    "signal": [
        { "name": "TX", "wave": "101.010.101..........."},
        { "name": "", "wave": "44444444444xxxxxxxxxxx", "data": ["Idle", "Start", "1", "1", "0", "1", "0", "0", "1", "0", "Stop"]}
    ],
    "foot": {"tock": 0},
    "head": {"text": "UART Transmission @19200 baud: 0x4B (01001011)"}
}
draw_wavedrom(waveform_dict )
