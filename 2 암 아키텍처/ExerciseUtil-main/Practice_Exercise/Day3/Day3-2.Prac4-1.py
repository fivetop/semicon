import json

with open("wavedrom_trace.json", "r") as f:
    waveform_lanes = json.load(f)
    
from pynq.lib.logictools.waveform import draw_wavedrom

waveform_dict = {
    'signal': waveform_lanes,
    'head': {'text': ['tspan', {'class': 'info h3'}, 'I2C Transactions']}
}
draw_wavedrom(waveform_dict)