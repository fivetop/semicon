from waveform_logger import WaveformLogger
from pynq.lib.logictools.waveform import draw_wavedrom


class AHBLiteProtocol:
    def __init__(self):
        self.signals = {}
        self._init_signals()

    def get_clock_signal(self):
        return "HCLK"
    def get_control_signals(self):
        return ["HWRITE", "HREADY"]
    def get_data_signals(self):
        return ["HTRANS", "HADDR", "HRDATA", "HBURST"]

    def _init_signals(self):
        for sig in self.get_control_signals():
            self.signals[sig] = 0
        for sig in self.get_data_signals():
            self.signals[sig] = 0

    def get_data_validity(self):
        return {
            "HTRANS": lambda s: True,
            "HBURST": lambda s: True,
            "HADDR":  lambda s: s["HREADY"] == 1 and s["HTRANS"] in (2, 3),
            "HRDATA": lambda s: True
        }


class AHBMaster:
    IDLE = 0
    NONSEQ = 2
    SEQ = 3

    def __init__(self, signals):
        self.signals = signals

        self.addr = 0
        self.start_addr = 0
        self.read_count = 0
        self.pending_start = False

        self.signals["HTRANS"] = self.IDLE
        self.signals["HREADY"] = 0
        self.signals["HADDR"] = 0
        self.signals["HBURST"] = 0

    def read_burst(self, start_addr, burst_type):
        self.start_addr = start_addr
        self.addr = start_addr
        self.read_count = 4 if burst_type in (2, 3) else 1
        self.signals["HBURST"] = burst_type
        self.pending_start = True

    def _next_addr_incr(self):
        return self.addr + 1

    def _next_addr_wrap4(self):
        base = self.start_addr & ~0x3
        offset = (self.addr + 1) & 0x3
        return base + offset

    def tick(self):
        sig = self.signals

        if self.read_count <= 0:
            sig["HTRANS"] = self.IDLE
            sig["HREADY"] = 0
            return

        if self.pending_start:
            self.pending_start = False

        sig["HREADY"] = 1
        sig["HADDR"] = self.addr
        sig["HTRANS"] = self.NONSEQ if self.read_count == 4 else self.SEQ

        if self.read_count > 1:
            if sig["HBURST"] == 2:
                self.addr = self._next_addr_wrap4()
            else:
                self.addr = self._next_addr_incr()
        self.read_count -= 1

    def is_done(self):
        return self.signals["HTRANS"] == self.IDLE and self.signals["HREADY"] == 0


class AHBSlave:
    NONSEQ = 2
    SEQ = 3

    def __init__(self, signals, mem_size=16, base_value=0x10):
        self.signals = signals
        self.memory = [(base_value + i) & 0xFF for i in range(mem_size)]
        self.prev_active = False
        self.prev_addr = 0
        self.signals["HRDATA"] = 0xDEAD

    def tick(self):
        if self.prev_active:
            a = self.prev_addr
            self.signals["HRDATA"] = self.memory[a] if 0 <= a < len(self.memory) else 0
        else:
            self.signals["HRDATA"] = 0xDEAD

        sig = self.signals
        curr_active = (sig.get("HREADY", 0) == 1) and (sig.get("HTRANS", 0) in (self.NONSEQ, self.SEQ))
        if curr_active:
            self.prev_addr = sig.get("HADDR", 0)
        self.prev_active = curr_active

class AHBSimulator:
    def __init__(self):
        self.protocol = AHBLiteProtocol()
        self.signals = self.protocol.signals
        self.master = AHBMaster(self.signals)
        self.slave  = AHBSlave(self.signals)
        self.logger = WaveformLogger(self.protocol)
        self.cycle = 0

    def step(self):
        self.master.tick()
        self.slave.tick()
        self.logger.record(self.signals)
        self.cycle += 1

    def read_burst(self, addr, burst_type, add_idle=False):
        self.master.read_burst(addr, burst_type)
        self.logger.record(self.signals)

        self.step()
        while not self.master.is_done():
            self.step()
        self.step()

    def get_waveform(self):
        return self.logger.to_wavedrom()



sim = AHBSimulator()
sim.read_burst(addr=0x2, burst_type=2, add_idle=True)
waveform = sim.get_waveform()
draw_wavedrom(waveform)
