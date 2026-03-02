from pynq.overlays.base import BaseOverlay

overlay = BaseOverlay('base.bit')
trace_analyzer = overlay.trace_pmoda

trace_analyzer.setup(frequency_mhz=0.4, num_analyzer_samples=65535)

from pynq.lib.pmod import Pmod_TMP2

sensor = Pmod_TMP2(overlay.PMODA)

trace_analyzer.run()
reading = sensor.read()
trace_analyzer.stop()

print('Temperature is {} degree C.'.format(reading))
_ = trace_analyzer.analyze()

trace_analyzer.set_protocol(protocol='i2c', probes={'SCL': 'D2', 'SDA': 'D3'})

start_position, stop_position = 1, 1000
waveform_lanes = trace_analyzer.decode('pmod_i2c_trace.csv', 
                                       start_position, stop_position,
                                       'pmod_i2c_trace.pd')

waveform_dict = {'signal': waveform_lanes,
                 'foot': {'tock': start_position},
                 'head': {'text': ['tspan', {'class': 'info h3'}, 
                                   'Pmod I2C Transactions']}}

from pynq.lib.logictools.waveform import draw_wavedrom

draw_wavedrom(waveform_dict)

from pprint import pprint

pprint(trace_analyzer.get_transactions())
