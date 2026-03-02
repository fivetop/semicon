class APBProtocol:
    def __init__(self):
        self.signals = {}
        self._init_signals()

    def get_control_signals(self):
        return ['PSEL', 'PENABLE', 'PWRITE', 'PREADY', 'PSLVERR']

    def get_data_signals(self):
        return ['PADDR', 'PWDATA', 'PRDATA']

    def get_clock_signal(self):
        return 'PCLK'

    def _init_signals(self):
        for sig in self.get_control_signals():
            self.signals[sig] = 0
        for sig in self.get_data_signals():
            self.signals[sig] = 0

    def get_data_validity(self):
        return {
            'PADDR': lambda s: s['PSEL'] == 1,
            'PWDATA': lambda s: s['PSEL'] == 1 and s['PWRITE'] == 1,
            'PRDATA': lambda s: s['PSEL'] == 1 and s['PENABLE'] == 1 and s['PWRITE'] == 0 and s['PREADY'] == 1
        }


class APBMaster:
    def __init__(self, signals):
        self.signals = signals
        self.state = "IDLE"
        self.current_addr = 0
        self.current_data = 0

    def start_write(self, addr, data):
        self.state = "SETUP"
        self.current_addr = addr
        self.current_data = data
        self.signals['PWRITE'] = 1

    def start_read(self, addr):
        self.state = "SETUP"
        self.current_addr = addr
        self.signals['PWRITE'] = 0

    def tick(self):
        if self.state == "IDLE":
            self.signals['PSEL'] = 0
            self.signals['PENABLE'] = 0

        elif self.state == "SETUP":
            self.signals['PSEL'] = 1
            self.signals['PENABLE'] = 0
            self.signals['PADDR'] = self.current_addr
            if self.signals['PWRITE']:
                self.signals['PWDATA'] = self.current_data
            self.state = "ACCESS"

        elif self.state == "ACCESS":
            self.signals['PSEL'] = 1
            self.signals['PENABLE'] = 1

            if self.signals['PREADY']:
                self.state = "IDLE"
                self.signals['PSEL'] = 0
                self.signals['PENABLE'] = 0

    def is_idle(self):
        return self.state == "IDLE"


class APBSlave:
    def __init__(self, signals):
        self.signals = signals
        self.memory = {}
        self.wait_states = 0
        self.wait_counter = 0
        self.latched_addr = 0

    def tick(self, wait_states=0):
        self.signals['PREADY'] = 0
        self.signals['PSLVERR'] = 0

        if self.signals['PSEL'] and not self.signals['PENABLE']:
            self.latched_addr = self.signals['PADDR']
            self.wait_counter = 0
            self.wait_states = wait_states


        elif self.signals['PSEL'] and self.signals['PENABLE']:
            if not self.signals['PWRITE']:
                self.signals['PRDATA'] = self.memory.get(self.latched_addr, 0)

            if self.wait_counter >= self.wait_states:
                self.signals['PREADY'] = 1

                if (self.signals['PWRITE'] == 0) and (self.latched_addr not in self.memory):
                    self.signals['PSLVERR'] = 1
                else:
                    self.signals['PSLVERR'] = 0

                if self.signals['PWRITE']:
                    self.memory[self.latched_addr] = self.signals['PWDATA']
            else:
                self.wait_counter += 1


from waveform_logger import WaveformLogger


class APBSimulator:
    def __init__(self):
        self.protocol = APBProtocol()
        self.signals = self.protocol.signals

        self.master = APBMaster(self.signals)
        self.slave = APBSlave(self.signals)

        self.logger = WaveformLogger(self.protocol)
        self.cycle = 0
        self.current_wait_states = 0

    def step(self):
        self.master.tick()
        self.slave.tick(self.current_wait_states)
        self.logger.record(self.signals)
        self.cycle += 1

    def run_transaction(self, transaction_type, addr, data=None, wait_states=0, add_idle=False):
        self.current_wait_states = wait_states

        if transaction_type == 'write':
            self.master.start_write(addr, data)
        elif transaction_type == 'read':
            self.master.start_read(addr)
        while not self.master.is_idle():
            self.step()

        if add_idle:
            self.step()

    def get_waveform(self):
        return self.logger.to_wavedrom()


import json

sim_mix = APBSimulator()
sim_mix.run_transaction('write', addr=0x20, data=0xCD, wait_states=1, add_idle=True)
sim_mix.run_transaction('read', addr=0x20, wait_states=2, add_idle=True)
sim_mix.run_transaction('read', addr=0x40, wait_states=2, add_idle=True)

waveform_mix = sim_mix.get_waveform()
draw_wavedrom(waveform_mix)
