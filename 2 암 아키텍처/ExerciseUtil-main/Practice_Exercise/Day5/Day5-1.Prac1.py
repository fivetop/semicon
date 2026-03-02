from waveform_logger import WaveformLogger
from pynq.lib.logictools.waveform import draw_wavedrom
import random

class AXILiteProtocol:
    def __init__(self):
        self.signals = {}
        self._init_signals()

    def get_control_signals(self):
        return ["AWVALID", "AWREADY", "WVALID", "WREADY", "BVALID", "BREADY"]

    def get_data_signals(self):
        return ["AWADDR", "WDATA", "BRESP"]

    def get_clock_signal(self):
        return "ACLK"

    def _init_signals(self):
        self.signals[self.get_clock_signal()] = 0
        for sig in self.get_control_signals():
            self.signals[sig] = 0
        for sig in self.get_data_signals():
            self.signals[sig] = 0

    def get_data_validity(self):
        return {
            "AWADDR": lambda s: s["AWVALID"] == 1,
            "WDATA":  lambda s: s["WVALID"] == 1,
            "BRESP":  lambda s: s["BVALID"] == 1,
        }


class AXILiteMaster:
    def __init__(self, signals):
        self.signals = signals
        self.drive_aw = False
        self.drive_w = False
        self.awaddr = 0
        self.wdata = 0
        self.aw_done = False
        self.w_done = False
        self.b_done = False
        self.bresp = 0

    def arm_aw(self, addr):
        self.drive_aw = True
        self.awaddr = addr
        self.aw_done = False

    def arm_w(self, data):
        self.drive_w = True
        self.wdata = data
        self.w_done = False

    def tick(self):
        s = self.signals
        s["AWVALID"] = 0
        s["WVALID"] = 0
        s["BREADY"] = 1

        if self.drive_aw and not self.aw_done:
            s["AWADDR"] = self.awaddr
            s["AWVALID"] = 1

        if self.drive_w and not self.w_done:
            s["WDATA"] = self.wdata
            s["WVALID"] = 1



class AXILiteSlave:
    OKAY = 0b00

    def __init__(self, signals):
        self.signals = signals
        self.memory = {}
        self.aw_seen = False
        self.w_seen  = False
        self.aw_addr = 0
        self.w_data  = 0
        self.aw_wait = 0
        self.w_wait  = 0
        self.prev_awvalid = 0
        self.prev_wvalid  = 0
        self.b_pending = False

    def tick(self, wait_states=0):
        s = self.signals
        s["AWREADY"] = 0
        s["WREADY"]  = 0

        if self.b_pending:
            s["BRESP"] = self.OKAY
            s["BVALID"] = 1
            self.b_pending = False
        else:
            s["BVALID"] = 0

        if s["AWVALID"] == 1 and self.prev_awvalid == 0 and not self.aw_seen:
            self.aw_wait = wait_states

        if s["WVALID"] == 1 and self.prev_wvalid == 0 and not self.w_seen:
            self.w_wait = wait_states

        if s["AWVALID"] == 1 and not self.aw_seen:
            if self.aw_wait > 0:
                self.aw_wait -= 1
            else:
                s["AWREADY"] = 1
                self.aw_seen = True
                self.aw_addr = s["AWADDR"]

        if s["WVALID"] == 1 and not self.w_seen:
            if self.w_wait > 0:
                self.w_wait -= 1
            else:
                s["WREADY"] = 1
                self.w_seen = True
                self.w_data = s["WDATA"]

        if self.aw_seen and self.w_seen and s["BVALID"] == 0:
            self.b_pending = True
            self.aw_seen = False
            self.w_seen  = False
            self.aw_wait = 0
            self.w_wait  = 0

        self.prev_awvalid = s["AWVALID"]
        self.prev_wvalid  = s["WVALID"]

class AXILiteSimulator:
    def __init__(self, WaveformLogger):
        self.protocol = AXILiteProtocol()
        self.signals = self.protocol.signals
        self.master = AXILiteMaster(self.signals)
        self.slave = AXILiteSlave(self.signals)
        self.logger = WaveformLogger(self.protocol)
        self.wait_states = 0

    def step(self):
        self.signals["ACLK"] ^= 1
        self.master.tick()
        self.slave.tick(wait_states=self.wait_states)

        s = self.signals

        if self.master.drive_aw and not self.master.aw_done:
            if s["AWVALID"] == 1 and s["AWREADY"] == 1:
                self.master.aw_done = True
                self.master.drive_aw = False

        if self.master.drive_w and not self.master.w_done:
            if s["WVALID"] == 1 and s["WREADY"] == 1:
                self.master.w_done = True
                self.master.drive_w = False

        if s["BVALID"] == 1 and s["BREADY"] == 1:
            self.master.b_done = True
            self.master.bresp = s["BRESP"]

        self.logger.record(self.signals)


    def run_write_aw_w_b(self, addr, data, wait_states=0):
        self.wait_states = wait_states
        self.master.b_done = False

        self.master.arm_aw(addr)
        while not self.master.aw_done:
            self.step()

        self.master.arm_w(data)
        while not self.master.w_done:
            self.step()

        while not self.master.b_done:
            self.step()

        self.step()

    def get_waveform(self):
        return self.logger.to_wavedrom()