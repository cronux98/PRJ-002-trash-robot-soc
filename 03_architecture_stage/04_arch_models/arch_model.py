#!/usr/bin/env python3
"""
IP-005 v6 — Architecture Behavioral Models
Trash Robot SoC — Derived from architecture_doc.md ONLY

Covers: UART, I2C Master, GPIO, Timer, Motor PWM, Ultrasonic Capture,
        Weight Detect, Watchdog, Interrupt Controller, Power Manager
Runs golden-model-compatible self-tests. Output compared to golden_output.json.
"""
import json, sys, os

# ──────────────────────────────────────────────────────────────────
# 1. UART Arch Model (from architecture_doc.md §4.4)
# ──────────────────────────────────────────────────────────────────
class UARTArchModel:
    """Architecture-doc-based UART: TX/RX shift, baud gen, 16550-compat."""
    def __init__(self, clk_hz=33_300_000, baud=115200):
        self.clk_hz = clk_hz
        self.baud = baud
        self.baud_div = round(clk_hz / baud)
        self.baud_actual = clk_hz / self.baud_div
        self.rx_data = 0
        self.tx_data = 0
        self.status = 0  # bit0=RX_READY, bit1=TX_BUSY
        self.ctrl = 0    # bit0=TX_EN, bit1=RX_EN

    def write_tx(self, data):
        self.tx_data = data & 0xFF
        self.status |= 0x2  # TX_BUSY
        return self.tx_data

    def tx_done(self):
        self.status &= ~0x2  # clear TX_BUSY
        self.tx_data = 0

    def receive(self, data):
        self.rx_data = data & 0xFF
        self.status |= 0x1  # RX_READY

    def read_rx(self):
        self.status &= ~0x1  # clear RX_READY
        return self.rx_data

    def parity_error(self):
        self.status |= 0x4  # ERROR

    @staticmethod
    def self_test():
        u = UARTArchModel()
        results = []
        results.append(("baud_accuracy", abs(u.baud_actual - 115200) < 200))
        results.append(("tx_write", u.write_tx(0xA5) == 0xA5 and u.status & 0x2))
        u.tx_done()
        results.append(("tx_done", not (u.status & 0x2)))
        u.receive(0x3C)
        results.append(("rx_receive", u.status & 0x1 and u.rx_data == 0x3C))
        d = u.read_rx()
        results.append(("rx_read", d == 0x3C and not (u.status & 0x1)))
        u.parity_error()
        results.append(("parity_error", u.status & 0x4))
        u.write_tx(0xFF); u.tx_done()
        u.receive(0xFF)
        results.append(("max_roundtrip", u.read_rx() == 0xFF))
        return results


# ──────────────────────────────────────────────────────────────────
# 2. I2C Master Arch Model (from architecture_doc.md §4.5)
# ──────────────────────────────────────────────────────────────────
class I2CMasterArchModel:
    """Architecture-doc-based I2C master: START, ADDR+R/W, DATA, STOP."""
    IDLE = 0; START = 1; ADDR = 2; DATA = 3; STOP = 4; ERROR = 5
    def __init__(self, prescaler=83):
        self.state = self.IDLE
        self.data_reg = 0
        self.addr_reg = 0
        self.ctrl = 0
        self.status = 0  # bit0=BUSY, bit1=ACK_ERR
        self.prescaler = prescaler

    def start_transfer(self, addr, rw=0):
        self.state = self.START
        self.addr_reg = (addr << 1) | rw
        self.state = self.ADDR
        return True

    def write_data(self, data):
        if self.state == self.ADDR:
            self.state = self.DATA
        self.data_reg = data & 0xFF
        return self.data_reg

    def read_data(self, data):
        if self.state == self.ADDR:
            self.state = self.DATA
        self.data_reg = data & 0xFF
        return self.data_reg

    def stop_transfer(self):
        self.state = self.IDLE
        self.ctrl = 0

    def nack(self):
        self.status |= 0x2  # ACK_ERR
        self.state = self.ERROR

    @staticmethod
    def self_test():
        i2c = I2CMasterArchModel()
        results = []
        results.append(("start_addr", i2c.start_transfer(0x68, 0)))
        results.append(("write_byte", i2c.write_data(0x42) == 0x42))
        results.append(("read_byte", i2c.read_data(0x99) == 0x99))
        i2c.stop_transfer()
        results.append(("stop", i2c.state == I2CMasterArchModel.IDLE))
        i2c.start_transfer(0x40, 1)
        i2c.nack()
        results.append(("nack_err", i2c.status & 0x2))
        i2c2 = I2CMasterArchModel()
        i2c2.start_transfer(0x50, 0)
        i2c2.write_data(0x01); i2c2.write_data(0x02); i2c2.write_data(0x03)
        results.append(("multi_write", i2c2.data_reg == 0x03))
        freq = 33_300_000 / i2c2.prescaler
        results.append(("prescaler", 390_000 < freq < 410_000))
        return results


# ──────────────────────────────────────────────────────────────────
# 3. GPIO Arch Model (from architecture_doc.md §4.6)
# ──────────────────────────────────────────────────────────────────
class GPIOArchModel:
    """Architecture-doc-based 16-bit GPIO with per-pin direction + interrupt."""
    def __init__(self, width=16):
        self.width = width
        self.dir = 0
        self.out = 0
        self.in_ = 0
        self.int_en = 0
        self.int_type = 0
        self.int_status = 0

    def set_dir(self, mask):
        self.dir = mask & ((1 << self.width) - 1)

    def write_out(self, value):
        self.out = value & ((1 << self.width) - 1)

    def set_input(self, pin_state):
        old = self.in_
        self.in_ = pin_state & ((1 << self.width) - 1)
        for i in range(self.width):
            if self.int_en & (1 << i):
                if self.int_type & (1 << i):
                    if ((old ^ self.in_) & (1 << i)):
                        self.int_status |= (1 << i)

    def read_input(self):
        return self.in_

    def get_interrupt(self):
        return (self.int_status & self.int_en) != 0

    @staticmethod
    def self_test():
        gpio = GPIOArchModel()
        results = []
        gpio.set_dir(0x000F)
        gpio.write_out(0x000A)
        results.append(("output", gpio.out == 0x000A))
        gpio.set_input(0xFF00)
        results.append(("input_read", gpio.read_input() == 0xFF00))
        gpio.set_input(0xFFF0)
        result = gpio.read_input() == 0xFFF0
        results.append(("edge_input", result))
        gpio2 = GPIOArchModel()
        gpio2.set_dir(0xFFFF)
        gpio2.write_out(0xFFFF)
        results.append(("all_ones", gpio2.out == 0xFFFF))
        gpio2.write_out(0x0000)
        results.append(("all_zeros", gpio2.out == 0x0000))
        return results


# ──────────────────────────────────────────────────────────────────
# 4. Timer Arch Model (from architecture_doc.md §4.7)
# ──────────────────────────────────────────────────────────────────
class TimerArchModel:
    """Architecture-doc-based 32-bit timer with compare interrupt + aux PWM."""
    def __init__(self):
        self.cnt = 0
        self.cmp = 0xFFFFFFFF
        self.ctrl = 0     # bit0=ENABLE, bit1=PWM_EN
        self.pwm_duty = [0, 0, 0, 0]
        self.pwm_period = 0xFFFF
        self.irq = False

    def tick(self, cycles=1):
        if not (self.ctrl & 1):
            return
        for _ in range(cycles):
            self.cnt = (self.cnt + 1) & 0xFFFFFFFF
            if self.cnt >= self.cmp:
                self.irq = True
                self.cmp = (self.cmp + 1000) & 0xFFFFFFFF

    def clear_irq(self):
        self.irq = False

    def pwm_level(self, ch):
        if not (self.ctrl & 2):
            return 0
        cycle = self.cnt % (self.pwm_period + 1)
        return 1 if cycle < self.pwm_duty[ch] else 0

    @staticmethod
    def self_test():
        t = TimerArchModel()
        results = []
        results.append(("init_zero", t.cnt == 0))
        t.ctrl = 1; t.cmp = 100
        t.tick(50)
        results.append(("tick_50", t.cnt == 50 and not t.irq))
        t.tick(50)
        results.append(("compare_irq", t.cnt == 100 and t.irq))
        t.clear_irq()
        results.append(("irq_clear", not t.irq))
        t.cnt = 0xFFFFFFFE; t.tick(3)
        results.append(("wrap", t.cnt == 1))
        t.ctrl = 3; t.pwm_duty = [32000, 0, 0, 0]; t.pwm_period = 65535; t.cnt = 0
        results.append(("pwm_high", t.pwm_level(0) == 1))
        t.cnt = 33000
        results.append(("pwm_low", t.pwm_level(0) == 0))
        t.ctrl = 0; t.cnt = 42; t.tick(10)
        results.append(("disabled", t.cnt == 42))
        t.ctrl = 1
        results.append(("pwm_disabled", t.pwm_level(0) == 0))
        return results


# ──────────────────────────────────────────────────────────────────
# 5. Motor PWM Arch Model (from architecture_doc.md §4.8)
# ──────────────────────────────────────────────────────────────────
class MotorPWMArchModel:
    """Architecture-doc-based 4-ch motor PWM: PHASE/ENABLE for DRV8833."""
    CHANNELS = 4
    def __init__(self, clk_hz=33_300_000, pwm_freq=25_000):
        self.clk_hz = clk_hz
        self.pwm_freq = pwm_freq
        self.period = clk_hz // pwm_freq  # ~1332
        self.duty_a = [0] * self.CHANNELS
        self.duty_b = [0] * self.CHANNELS
        self.ctrl = 0   # bit0=ENABLE
        self.fault = 0
        self.cycle_cnt = 0

    def tick(self, cycles=1):
        if not (self.ctrl & 1):
            return
        self.cycle_cnt = (self.cycle_cnt + cycles) % self.period

    def pwm_a(self, ch):
        if not (self.ctrl & 1) or (self.fault & (1 << ch)):
            return 0
        return 1 if self.cycle_cnt < self.duty_a[ch] else 0

    def pwm_b(self, ch):
        if not (self.ctrl & 1) or (self.fault & (1 << ch)):
            return 0
        return 1 if self.cycle_cnt < self.duty_b[ch] else 0

    def set_fault(self, mask):
        self.fault |= mask

    def clear_fault(self):
        self.fault = 0

    @staticmethod
    def self_test():
        m = MotorPWMArchModel()
        results = []
        results.append(("init_off", m.pwm_a(0) == 0 and m.pwm_b(0) == 0))
        m.ctrl = 1; m.duty_a = [m.period // 2] * 4
        m.cycle_cnt = 0
        results.append(("forward_high", m.pwm_a(0) == 1))
        m.cycle_cnt = m.period // 2 + 1
        results.append(("forward_low", m.pwm_a(0) == 0))
        m.duty_a = [m.period] * 4; m.cycle_cnt = 0
        results.append(("full_duty", m.pwm_a(0) == 1))
        m.cycle_cnt = m.period
        results.append(("full_duty_end", m.pwm_a(0) == 0))
        m.duty_a = [0] * 4; m.cycle_cnt = 0
        results.append(("zero_duty", m.pwm_a(0) == 0))
        m.duty_a = [m.period] * 4; m.cycle_cnt = 0
        m.set_fault(0x1)
        results.append(("fault_stops", m.pwm_a(0) == 0))
        m.clear_fault()
        results.append(("fault_cleared", m.pwm_a(0) == 1))
        m.ctrl = 0
        results.append(("disable", m.pwm_a(0) == 0))
        m.ctrl = 1; m.duty_a = [m.period//3, m.period//2, m.period, 0]
        m.cycle_cnt = 100
        results.append(("multi_ch", m.pwm_a(0) == 1 and m.pwm_a(3) == 0))
        freq = m.clk_hz / m.period
        results.append(("freq_accuracy", 24900 < freq < 25100))
        return results


# ──────────────────────────────────────────────────────────────────
# 6. Ultrasonic Capture Arch Model (from architecture_doc.md §4.9)
# ──────────────────────────────────────────────────────────────────
class UltrasonicArchModel:
    """Architecture-doc-based dual HC-SR04: trigger + echo capture (20-bit)."""
    def __init__(self, clk_hz=33_300_000):
        self.clk_hz = clk_hz
        self.prescaler = 33  # ~1 MHz
        self.trig = [0, 0]
        self.echo_time = [0, 0]
        self.ctrl = 0
        self.status = 0  # bit0=DONE_CH0, bit1=DONE_CH1, bit2=TIMEOUT
        self.counter = [0, 0]
        self.running = [False, False]

    def trigger(self, ch):
        self.trig[ch] = 1
        self.running[ch] = True
        self.counter[ch] = 0

    def echo_rise(self, ch):
        if self.running[ch]:
            self.counter[ch] = 0

    def tick_us(self, ch, us=1):
        if self.running[ch]:
            self.counter[ch] += us

    def echo_fall(self, ch):
        if self.running[ch]:
            self.echo_time[ch] = self.counter[ch]
            self.status |= (1 << ch)
            self.running[ch] = False

    def timeout(self, ch):
        self.status |= 0x4
        self.running[ch] = False

    def get_distance_cm(self, ch):
        return self.echo_time[ch] * 0.034 / 2

    @staticmethod
    def self_test():
        u = UltrasonicArchModel()
        results = []
        u.trigger(0)
        results.append(("trigger", u.running[0] == True))
        u.echo_rise(0)
        results.append(("echo_rise", u.counter[0] == 0))
        u.tick_us(0, 100)
        u.tick_us(0, 500)
        results.append(("tick_count", u.counter[0] == 600))
        u.echo_fall(0)
        results.append(("echo_fall", u.echo_time[0] == 600 and (u.status & 0x1)))
        d = u.get_distance_cm(0)
        results.append(("distance", 9.5 < d < 11.0))
        u.trigger(1); u.timeout(1)
        results.append(("timeout", u.status & 0x4))
        u2 = UltrasonicArchModel()
        u2.trigger(0); u2.tick_us(0, 150); u2.echo_fall(0)
        u2.trigger(1); u2.tick_us(1, 5000); u2.echo_fall(1)
        results.append(("dual_ch", u2.echo_time[0] == 150 and u2.echo_time[1] == 5000))
        return results


# ──────────────────────────────────────────────────────────────────
# 7. Weight Detect Arch Model (from architecture_doc.md §4.10)
# ──────────────────────────────────────────────────────────────────
class WeightDetectArchModel:
    """Architecture-doc-based HX711 threshold detection."""
    def __init__(self):
        self.thresh = 0x800000  # mid-scale threshold
        self.ctrl = 0
        self.status = 0  # bit0=OVER_THRESH, bit1=READY
        self.last_value = 0

    def new_sample(self, value):
        self.last_value = value & 0xFFFFFF
        if self.last_value > self.thresh:
            self.status |= 0x1
        else:
            self.status &= ~0x1

    def is_over_threshold(self):
        return bool(self.status & 0x1)

    @staticmethod
    def self_test():
        w = WeightDetectArchModel()
        results = []
        w.new_sample(0x100000)
        results.append(("below", not w.is_over_threshold()))
        w.new_sample(0x900000)
        results.append(("above", w.is_over_threshold()))
        w.new_sample(0x100000)
        results.append(("return_below", not w.is_over_threshold()))
        w.thresh = 0x800000; w.new_sample(0x800000)
        results.append(("at_thresh", not w.is_over_threshold()))
        w.new_sample(0x800001)
        results.append(("at_thresh_plus1", w.is_over_threshold()))
        w.new_sample(0xFFFFFF)
        results.append(("max_value", w.is_over_threshold()))
        w.new_sample(0x000000)
        results.append(("zero", not w.is_over_threshold()))
        w.thresh = 0x100000; w.new_sample(0x200000)
        results.append(("thresh_change", w.is_over_threshold()))
        return results


# ──────────────────────────────────────────────────────────────────
# 8. Watchdog Arch Model (from architecture_doc.md §4.11)
# ──────────────────────────────────────────────────────────────────
class WatchdogArchModel:
    """Architecture-doc-based dual-stage watchdog with magic-key reload."""
    MAGIC_KEY = 0xACCE5515
    def __init__(self):
        self.counter = 0
        self.warning_timeout = 1000
        self.reset_timeout = 2000
        self.ctrl = 0     # bit0=ENABLE, bit1=DISABLE_DEBUG
        self.status = 0   # bit0=WARNING, bit1=RESET
        self.warning_irq = False
        self.reset_out = False
        self.fed = False

    def tick(self, cycles=1):
        if not (self.ctrl & 0x1) or (self.ctrl & 0x2):
            return
        self.counter += cycles
        if self.counter >= self.warning_timeout and not (self.status & 0x1):
            self.status |= 0x1
            self.warning_irq = True
        if self.counter >= self.reset_timeout and not (self.status & 0x2):
            self.status |= 0x2
            self.reset_out = True

    def feed(self, key):
        if key == self.MAGIC_KEY:
            self.counter = 0
            self.status = 0
            self.warning_irq = False
            self.reset_out = False
            self.fed = True
            return True
        return False

    def is_fed(self):
        return self.fed

    @staticmethod
    def self_test():
        w = WatchdogArchModel()
        results = []
        w.ctrl = 1; w.tick(500)
        results.append(("tick500", w.counter == 500 and not w.warning_irq))
        w.tick(500)
        results.append(("warning", w.counter == 1000 and w.warning_irq))
        w.tick(1000)
        results.append(("reset", w.counter == 2000 and w.reset_out))
        w.ctrl = 1; w.counter = 500
        fed = w.feed(WatchdogArchModel.MAGIC_KEY)
        results.append(("feed", fed and w.counter == 0 and not w.warning_irq))
        w.counter = 500
        w.feed(0xDEADBEEF)
        results.append(("wrong_key", w.counter == 500))
        w2 = WatchdogArchModel(); w2.ctrl = 2; w2.tick(500)
        results.append(("disable_debug", w2.counter == 0))
        w3 = WatchdogArchModel(); w3.ctrl = 1; w3.counter = 999; w3.tick(1)
        results.append(("rearm_warn", w3.warning_irq))
        w3.feed(WatchdogArchModel.MAGIC_KEY); w3.tick(500)
        results.append(("rearm_after_feed", w3.counter == 500 and not w3.warning_irq))
        w4 = WatchdogArchModel(); w4.ctrl = 1
        w4.warning_timeout = 10; w4.reset_timeout = 20; w4.tick(25)
        results.append(("reset_polarity", w4.reset_out))
        return results


# ──────────────────────────────────────────────────────────────────
# 9. Interrupt Controller Arch Model (from architecture_doc.md §4.12)
# ──────────────────────────────────────────────────────────────────
class InterruptCtrlArchModel:
    """Architecture-doc-based 16-ch fixed-priority interrupt controller."""
    CHANNELS = 16
    def __init__(self):
        self.enable = 0
        self.pending = 0
        self.status = 0
        self.irq_out = False

    def set_irq(self, ch, level=1):
        if level:
            self.status |= (1 << ch)
            if self.enable & (1 << ch):
                self.pending |= (1 << ch)

    def acknowledge(self, ch):
        self.status &= ~(1 << ch)
        self.pending &= ~(1 << ch)

    def update(self):
        for i in range(self.CHANNELS):
            if self.pending & (1 << i):
                self.irq_out = True
                return i
        self.irq_out = False
        return -1

    def get_highest_pending(self):
        for i in range(self.CHANNELS):
            if self.pending & (1 << i):
                return i
        return 15

    @staticmethod
    def self_test():
        ic = InterruptCtrlArchModel()
        results = []
        results.append(("no_irqs", ic.update() == -1 and not ic.irq_out))
        ic.enable = 1 << 5
        ic.set_irq(5)
        results.append(("single_irq", ic.update() == 5 and ic.irq_out))
        ic.acknowledge(5)
        results.append(("ack_clear", ic.update() == -1 and not ic.irq_out))
        ic.enable = (1 << 10) | (1 << 0)
        ic.set_irq(10); ic.set_irq(0)
        results.append(("priority", ic.update() == 0))
        ic.acknowledge(0)
        results.append(("fallback", ic.update() == 10))
        ic.pending = 0; ic.status = 0; ic.irq_out = False
        ic.enable = 0; ic.set_irq(3)
        results.append(("disabled", ic.update() == -1))
        ic.enable = (1 << 3) | (1 << 7) | (1 << 15)
        ic.set_irq(7); ic.set_irq(15)
        results.append(("highest_pending", ic.get_highest_pending() == 7))
        ic2 = InterruptCtrlArchModel(); ic2.enable = 1 << 15
        ic2.set_irq(15)
        results.append(("ch15", ic2.update() == 15))
        ic3 = InterruptCtrlArchModel(); ic3.enable = 0xFFFF
        ic3.set_irq(3); ic3.set_irq(1); ic3.set_irq(2)
        highest = ic3.update()
        results.append(("multi_pending", highest == 1))
        return results


# ──────────────────────────────────────────────────────────────────
# 10. Power Manager Arch Model (from architecture_doc.md §4.13)
# ──────────────────────────────────────────────────────────────────
class PowerMgrArchModel:
    """Architecture-doc-based clock gating power manager with ACTIVE/SLEEP/WAKE FSM."""
    ACTIVE = 0; SLEEP = 1; WAKE = 2
    MODULES = 14
    def __init__(self):
        self.state = self.ACTIVE
        self.clk_en = (1 << self.MODULES) - 1
        self.ctrl = 0
        self.sleep_src = 0
        self.status = 0  # bit0=SLEEPING, bit1=WAKING
        self.core_sleep_req = False
        self.wake_rtc = False
        self.wake_button = False

    def request_sleep(self):
        self.core_sleep_req = True

    def trigger_rtc_wake(self):
        self.wake_rtc = True

    def trigger_button_wake(self):
        self.wake_button = True

    def tick(self):
        if self.state == self.ACTIVE:
            if self.core_sleep_req:
                self.state = self.SLEEP
                self.clk_en = 0
                self.status |= 0x1
                self.core_sleep_req = False
        elif self.state == self.SLEEP:
            if self.wake_rtc or self.wake_button:
                self.state = self.WAKE
                self.status |= 0x2
                self.wake_rtc = False
                self.wake_button = False
        elif self.state == self.WAKE:
            self.clk_en = (1 << self.MODULES) - 1
            self.state = self.ACTIVE
            self.status &= ~(0x3)

    def module_clocked(self, mod):
        return bool(self.clk_en & (1 << mod))

    @staticmethod
    def self_test():
        p = PowerMgrArchModel()
        results = []
        results.append(("init_active", p.state == PowerMgrArchModel.ACTIVE and p.clk_en == 0x3FFF))
        results.append(("mod0_clk", p.module_clocked(0)))
        p.request_sleep(); p.tick()
        results.append(("go_sleep", p.state == PowerMgrArchModel.SLEEP and p.clk_en == 0))
        results.append(("all_gated", not any(p.module_clocked(i) for i in range(PowerMgrArchModel.MODULES))))
        p.trigger_rtc_wake(); p.tick()
        results.append(("rtc_wake", p.state == PowerMgrArchModel.WAKE))
        p.tick()
        results.append(("wake_active", p.state == PowerMgrArchModel.ACTIVE and p.clk_en == 0x3FFF))
        p2 = PowerMgrArchModel(); p2.request_sleep(); p2.tick()
        p2.trigger_button_wake(); p2.tick()
        results.append(("button_wake", p2.state == PowerMgrArchModel.WAKE))
        p3 = PowerMgrArchModel(); p3.request_sleep(); p3.tick()
        p3.trigger_rtc_wake(); p3.trigger_button_wake(); p3.tick()
        results.append(("dual_wake", p3.state == PowerMgrArchModel.WAKE))
        p3.tick()
        results.append(("dual_wake_resolve", p3.state == PowerMgrArchModel.ACTIVE))
        return results


# ══════════════════════════════════════════════════════════════════
# MAIN: Run arch model self-tests and compare to golden
# ══════════════════════════════════════════════════════════════════
ARCH_MODELS = {
    "uart": UARTArchModel,
    "i2c_master": I2CMasterArchModel,
    "gpio": GPIOArchModel,
    "timer": TimerArchModel,
    "motor_pwm": MotorPWMArchModel,
    "ultrasonic_capture": UltrasonicArchModel,
    "weight_detect": WeightDetectArchModel,
    "watchdog": WatchdogArchModel,
    "interrupt_ctrl": InterruptCtrlArchModel,
    "power_mgr": PowerMgrArchModel,
}

def main():
    all_pass = True
    total_tests = 0
    total_pass = 0
    arch_results = {}

    print("=" * 60)
    print("IP-005 v6 — Architecture Model Self-Test Suite")
    print("=" * 60)

    for name, cls in ARCH_MODELS.items():
        print(f"\n--- {name} ---")
        try:
            results = cls.self_test()
        except Exception as e:
            print(f"  ERROR: {e}")
            all_pass = False
            continue

        module_pass = True
        module_results_list = []
        for test_name, passed in results:
            total_tests += 1
            status = "PASS" if passed else "FAIL"
            if passed:
                total_pass += 1
            else:
                all_pass = False
                module_pass = False
            print(f"  {test_name:30s} ... {status}")
            module_results_list.append({"test": test_name, "result": status})

        arch_results[name] = {
            "tests_run": len(results),
            "tests_passed": sum(1 for _, p in results if p),
            "results": module_results_list,
            "verdict": "PASS" if module_pass else "FAIL"
        }

    print(f"\n{'=' * 60}")
    print(f"SUMMARY: {total_pass}/{total_tests} tests passed")
    print(f"VERDICT: {'PASS' if all_pass else 'FAIL'}")
    print(f"{'=' * 60}")

    # Write arch model output
    script_dir = os.path.dirname(os.path.abspath(__file__))
    out_path = os.path.join(script_dir, "arch_output.json")
    output = {
        "project": "IP-005",
        "version": "v6",
        "model_type": "architecture",
        "total_tests": total_tests,
        "total_passed": total_pass,
        "verdict": "PASS" if all_pass else "FAIL",
        "modules": arch_results
    }
    with open(out_path, "w") as f:
        json.dump(output, f, indent=2)
    print(f"\nArch model output written to: {out_path}")

    # Load golden output and compare
    golden_path = os.path.join(os.path.dirname(script_dir), "golden_models", "golden_output.json")
    # The golden is at: 01_planning-stage/golden_models/golden_output.json
    golden_path = os.path.join(os.path.dirname(script_dir), "..", "01_planning-stage", "golden_models", "golden_output.json")
    golden_path = os.path.normpath(golden_path)

    print(f"\nLoading golden from: {golden_path}")
    if os.path.exists(golden_path):
        with open(golden_path) as f:
            golden = json.load(f)

        # Compare module by module
        print("\n" + "=" * 60)
        print("GOLDEN vs ARCHITECTURE COMPARISON")
        print("=" * 60)
        mismatches = 0
        all_identical = True
        comp_results = {}

        for name in ARCH_MODELS:
            gmod = golden.get("modules", {}).get(name, {})
            amod = arch_results.get(name, {})

            gtests = {t["test"]: t["result"] for t in gmod.get("results", [])}
            atests = {t["test"]: t["result"] for t in amod.get("results", [])}

            module_match = True
            for tname in sorted(set(list(gtests.keys()) + list(atests.keys()))):
                gr = gtests.get(tname, "MISSING")
                ar = atests.get(tname, "MISSING")
                if gr != ar:
                    module_match = False
                    all_identical = False
                    mismatches += 1
                    print(f"  MISMATCH {name}.{tname}: golden={gr} arch={ar}")

            comp_results[name] = "IDENTICAL" if module_match else "MISMATCH"
            print(f"  {name:25s} ... {comp_results[name]}")

        # Write comparison output
        comp_path = os.path.join(script_dir, "arch_comparison.json")
        comp_output = {
            "project": "IP-005",
            "version": "v6",
            "comparison_type": "golden_vs_architecture",
            "modules_compared": len(ARCH_MODELS),
            "modules_identical": sum(1 for v in comp_results.values() if v == "IDENTICAL"),
            "mismatches": mismatches,
            "verdict": "PASS" if all_identical else "FAIL",
            "module_details": comp_results
        }
        with open(comp_path, "w") as f:
            json.dump(comp_output, f, indent=2)

        print(f"\nComparison written to: {comp_path}")
        print(f"Verdict: {comp_output['verdict']} — {comp_output['modules_identical']}/{comp_output['modules_compared']} identical")
    else:
        print(f"\nWARNING: Golden output not found at {golden_path}")
        print("Skipping comparison. Arch model self-test results available in arch_output.json")

    return 0 if all_pass else 1

if __name__ == "__main__":
    sys.exit(main())
