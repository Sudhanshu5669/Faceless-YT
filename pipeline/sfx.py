"""Procedural sound effects and beds (numpy + scipy), deterministic by name.

Every sound is synthesized, never downloaded, so it is license-free and the
same every render. Beds (room_tone, drone, zombies, heartbeat) take a duration
and an intensity curve; one-shots (glass_bang, creak, sting, thud) are short.
A CC0 sample pack can replace any of these later under the same names.
"""
from __future__ import annotations

import zlib

import numpy as np
from scipy import signal

SR = 48000

BEDS = ["room_tone", "drone", "zombies", "heartbeat", "beat"]
ONE_SHOTS = ["glass_bang", "creak", "sting", "thud", "click", "pop", "whoosh", "ding", "tick", "cash"]


def _rng(name: str, salt: int = 0) -> np.random.Generator:
    return np.random.default_rng(zlib.crc32(f"{name}/{salt}".encode()))


def _t(dur: float) -> np.ndarray:
    return np.arange(int(dur * SR)) / SR


def _bandpass(x: np.ndarray, lo: float, hi: float, order: int = 2) -> np.ndarray:
    sos = signal.butter(order, [lo, hi], btype="band", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def _lowpass(x: np.ndarray, f: float, order: int = 2) -> np.ndarray:
    return signal.sosfilt(signal.butter(order, f, btype="low", fs=SR, output="sos"), x)


def _highpass(x: np.ndarray, f: float, order: int = 2) -> np.ndarray:
    return signal.sosfilt(signal.butter(order, f, btype="high", fs=SR, output="sos"), x)


def _norm(x: np.ndarray, peak: float = 0.9) -> np.ndarray:
    m = float(np.max(np.abs(x))) or 1.0
    return x * (peak / m)


def _fade(x: np.ndarray, fin: float = 0.01, fout: float = 0.05) -> np.ndarray:
    n_in, n_out = int(fin * SR), int(fout * SR)
    y = x.copy()
    if n_in:
        y[:n_in] *= np.linspace(0, 1, n_in)
    if n_out:
        y[-n_out:] *= np.linspace(1, 0, n_out)
    return y


def curve(points: list, dur: float) -> np.ndarray:
    """Per-sample gain from [[time_s, level], ...] (linear, held at the ends)."""
    t = _t(dur)
    if not points:
        return np.ones_like(t)
    pts = sorted(points)
    return np.interp(t, [p[0] for p in pts], [p[1] for p in pts])


# --- beds -------------------------------------------------------------------

def room_tone(dur: float) -> np.ndarray:
    """Fluorescent hum and air: the sound of an empty store at night."""
    r = _rng("room_tone")
    t = _t(dur)
    hum = 0.5 * np.sin(2 * np.pi * 120 * t) + 0.2 * np.sin(2 * np.pi * 240 * t) + 0.08 * np.sin(2 * np.pi * 360 * t)
    air = _lowpass(r.standard_normal(t.size), 400)
    return _norm(0.35 * hum * (1 + 0.1 * np.sin(2 * np.pi * 0.3 * t)) + 2.0 * air, 0.5)


def drone(dur: float) -> np.ndarray:
    """A low, slowly beating dissonant drone (the score)."""
    r = _rng("drone")
    t = _t(dur)
    x = np.zeros_like(t)
    for f, a in [(41.2, 1.0), (41.7, 0.8), (55.0, 0.55), (61.7, 0.35), (82.4, 0.25), (116.5, 0.12)]:
        lfo = 1 + 0.25 * np.sin(2 * np.pi * r.uniform(0.03, 0.12) * t + r.uniform(0, 6.28))
        x += a * lfo * np.sin(2 * np.pi * f * t + r.uniform(0, 6.28))
    x += 0.6 * _bandpass(r.standard_normal(t.size), 60, 300)
    return _norm(_lowpass(x, 500), 0.8)


def zombies(dur: float, voices: int = 22) -> np.ndarray:
    """A crowd of groaning voices heard through glass: glottal pulse trains
    with jittery pitch, shaped by "uh"/"oh" formants, swelling at random."""
    r = _rng("zombies")
    t = _t(dur)
    out = np.zeros_like(t)
    for v in range(voices):
        f0 = r.uniform(62, 125)
        vib = 1 + 0.04 * np.sin(2 * np.pi * r.uniform(3, 6) * t) + 0.03 * _lowpass(r.standard_normal(t.size), 4) * 8
        phase = np.cumsum(f0 * vib / SR)
        src = 2 * (phase % 1.0) - 1.0          # sawtooth ~ glottal pulses
        src += 0.3 * r.standard_normal(t.size)  # breath
        f1, f2 = r.uniform(380, 620), r.uniform(800, 1150)
        voiced = _bandpass(src, f1 * 0.8, f1 * 1.25) + 0.5 * _bandpass(src, f2 * 0.85, f2 * 1.2)
        # Groans: 1-3 s swells with gaps.
        env = np.zeros_like(t)
        pos = r.uniform(0, 2.0)
        while pos < dur:
            length = r.uniform(1.0, 3.2)
            i0, i1 = int(pos * SR), min(int((pos + length) * SR), t.size)
            if i1 > i0:
                env[i0:i1] = np.sin(np.linspace(0, np.pi, i1 - i0)) ** 1.5 * r.uniform(0.4, 1.0)
            pos += length + r.uniform(0.3, 2.5)
        out += voiced * env
    return _norm(_lowpass(out, 2400), 0.8)


def heartbeat(dur: float, bpm: float = 64) -> np.ndarray:
    t = _t(dur)
    out = np.zeros_like(t)
    beat = 60.0 / bpm
    one = _thump(0.18, 52)
    pos = 0.0
    while pos < dur:
        for off, g in [(0.0, 1.0), (0.24, 0.65)]:
            i0 = int((pos + off) * SR)
            i1 = min(i0 + one.size, out.size)
            if i0 < out.size:
                out[i0:i1] += g * one[: i1 - i0]
        pos += beat
    return _norm(out, 0.9)


def beat(dur: float, bpm: float = 104.0) -> np.ndarray:
    """Upbeat explainer music bed (the toon style's constant music): four-on-the-floor-ish
    kick, claps on 2 and 4, swung hats, a plucky bass and chord stabs over Am-F-C-G.
    Synthesized, deterministic, license-free. Loops seamlessly every 4 bars."""
    r = _rng("beat")
    n = int(dur * SR)
    out = np.zeros(n)
    spb = 60.0 / bpm                    # seconds per beat
    bar = 4 * spb
    roots = [110.0, 87.31, 130.81, 98.0]                # A2, F2, C3, G2
    chords = [[220.0, 261.63, 329.63], [174.61, 220.0, 261.63], [261.63, 329.63, 392.0], [196.0, 246.94, 293.66]]

    def add(x: np.ndarray, t0: float, gain: float) -> None:
        i = int(t0 * SR)
        if i >= n:
            return
        m = min(x.size, n - i)
        out[i:i + m] += x[:m] * gain

    def kick() -> np.ndarray:
        t = _t(0.35)
        f = 45 + 80 * np.exp(-t * 28)
        return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 9)

    def clap(salt: int) -> np.ndarray:
        rr = _rng("clap", salt)
        t = _t(0.22)
        x = _bandpass(rr.standard_normal(t.size), 900, 5000)
        env = np.exp(-t * 22) * (1 + 0.6 * (np.sin(2 * np.pi * 90 * t) > 0.6))
        return x * env

    def hat(salt: int, open_: bool) -> np.ndarray:
        rr = _rng("hat", salt)
        t = _t(0.18 if open_ else 0.05)
        return _highpass(rr.standard_normal(t.size), 7000) * np.exp(-t * (18 if open_ else 90))

    def pluck(freqs: list, length: float, cutoff: float) -> np.ndarray:
        t = _t(length)
        x = np.zeros_like(t)
        for f in freqs:
            ph = (f * t) % 1.0
            x += 2 * ph - 1
        x = _lowpass(x, cutoff)
        return x * np.exp(-t * 7) / len(freqs)

    def bass_note(f: float, length: float) -> np.ndarray:
        t = _t(length)
        x = np.sin(2 * np.pi * f * t) + 0.35 * _lowpass(2 * ((f * t) % 1.0) - 1, 600)
        return x * np.minimum(1, t * 200) * np.exp(-t * 3.5)

    kicks = kick()
    beats = int(dur / spb) + 1
    for b in range(beats):
        t0 = b * spb
        bar_i = (b // 4) % 4
        beat_in_bar = b % 4
        add(kicks, t0, 0.9)
        if beat_in_bar in (1, 3):
            add(clap(b), t0, 0.32)
        for half in (0, 1):
            swing = 0.07 * spb if half else 0.0
            add(hat(b * 2 + half, open_=(half == 1 and beat_in_bar == 3)), t0 + half * spb / 2 + swing,
                0.10 + 0.05 * half + r.uniform(-0.02, 0.02))
        root = roots[bar_i]
        for half in (0, 1):
            f = root * (2 if (half == 1 and beat_in_bar % 2 == 1) else 1)
            add(bass_note(f, spb / 2 * 0.9), t0 + half * spb / 2, 0.42)
        if beat_in_bar in (1, 3):
            add(pluck(chords[bar_i], spb * 0.9, 2200), t0 + spb / 2, 0.22)
    # Soft pad: the chord, sustained, ducked by the kick (a little pump).
    t = _t(dur)
    pad = np.zeros(n)
    for k, ch in enumerate(chords):
        seg = (np.floor(t / bar) % 4) == k
        for f in ch:
            pad += seg * np.sin(2 * np.pi * f * t) * 0.25
    pump = 1 - 0.6 * np.exp(-((t % spb) * 9))
    out += _lowpass(pad, 1500) * pump * 0.18
    return _fade(_norm(out, 0.6), 0.3, 1.0)


# --- one-shots --------------------------------------------------------------

def _thump(dur: float, f: float) -> np.ndarray:
    t = _t(dur)
    freq = f * (1 + 1.5 * np.exp(-t * 30))
    return np.sin(2 * np.pi * np.cumsum(freq) / SR) * np.exp(-t * 18)


def glass_bang(salt: int = 0) -> np.ndarray:
    """A fist on a big shop window: a low thud plus a short glassy rattle."""
    r = _rng("glass_bang", salt)
    t = _t(0.9)
    body = _thump(0.9, r.uniform(55, 75))
    knock = _lowpass(r.standard_normal(t.size), 900) * np.exp(-t * 40) * 0.8
    rattle = np.zeros_like(t)
    for _ in range(9):
        f = r.uniform(1800, 5200)
        rattle += np.sin(2 * np.pi * f * t + r.uniform(0, 6.28)) * np.exp(-t * r.uniform(9, 22)) * r.uniform(0.05, 0.15)
    return _fade(_norm(body + knock + rattle, 0.95))


def creak(salt: int = 0) -> np.ndarray:
    """Glass under strain: stick-slip clicks at a wandering rate through
    resonances, about 2 s."""
    r = _rng("creak", salt)
    dur = 2.0
    t = _t(dur)
    rate = 25 + 60 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.6 * t + r.uniform(0, 6.28))) + 15 * _lowpass(r.standard_normal(t.size), 3) * 6
    phase = np.cumsum(rate / SR)
    clicks = (np.diff(np.floor(phase), prepend=0) > 0).astype(float) * r.uniform(0.5, 1.0, t.size)
    x = _bandpass(clicks, 350, 520, 3) + 0.6 * _bandpass(clicks, 1100, 1500, 3) + 0.25 * _bandpass(clicks, 2600, 3300, 2)
    env = np.sin(np.linspace(0, np.pi, t.size)) ** 0.8
    return _fade(_norm(x * env, 0.85), 0.05, 0.2)


def sting(salt: int = 0) -> np.ndarray:
    """1.4 s dissonant swell into a low boom: the scare."""
    r = _rng("sting", salt)
    rise, tail = 1.4, 2.6
    t = _t(rise)
    sw = np.zeros_like(t)
    for f in [220, 233.1, 311.1, 329.6, 466.2, 493.9]:
        ph = np.cumsum(np.full(t.size, f) * (1 + 0.02 * t) / SR)
        sw += 2 * (ph % 1.0) - 1.0
    sw = _bandpass(sw, 200, 3000) * (t / rise) ** 3
    tt = _t(tail)
    boom = _thump(tail, 38) * 1.6 + _lowpass(r.standard_normal(tt.size), 300) * np.exp(-tt * 3) * 0.6
    hiss = _highpass(r.standard_normal(tt.size), 3000) * np.exp(-tt * 6) * 0.15
    return _fade(_norm(np.concatenate([sw * 0.35, boom + hiss]), 0.95), 0.0, 0.5)


def thud(salt: int = 0) -> np.ndarray:
    return _fade(_norm(_thump(0.6, 48), 0.9))


def click(salt: int = 0) -> np.ndarray:
    """A small plastic click (battery cover)."""
    r = _rng("click", salt)
    t = _t(0.08)
    return _fade(_norm(_bandpass(r.standard_normal(t.size), 2000, 6000) * np.exp(-t * 120), 0.8), 0.0, 0.01)


# --- toon explainer one-shots (reveals, counters, whip pans) -------------------

def pop(salt: int = 0) -> np.ndarray:
    """A bubbly cartoon pop: something appears."""
    r = _rng("pop", salt)
    t = _t(0.16)
    f0 = r.uniform(380, 520)
    freq = f0 * (1 + 2.2 * (1 - np.exp(-t * 60)))
    tone = np.sin(2 * np.pi * np.cumsum(freq) / SR) * np.exp(-t * 32)
    click_ = _bandpass(r.standard_normal(t.size), 1500, 7000) * np.exp(-t * 300) * 0.4
    return _fade(_norm(tone + click_, 0.85), 0.0, 0.02)


def whoosh(salt: int = 0) -> np.ndarray:
    """An air swish for whip pans and fast moves (0.45 s)."""
    r = _rng("whoosh", salt)
    dur = 0.45
    t = _t(dur)
    noise = r.standard_normal(t.size)
    env = np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 2
    # Sweep the band up then down: the doppler feel.
    centre = 600 + 2600 * np.sin(np.pi * t / dur)
    x = np.zeros_like(t)
    for lo, hi in [(300, 900), (900, 2200), (2200, 5000)]:
        band = _bandpass(noise, lo, hi)
        w = np.exp(-((centre - (lo + hi) / 2) / ((hi - lo) * 0.9)) ** 2)
        x += band * w
    return _fade(_norm(x * env, 0.8), 0.01, 0.05)


def ding(salt: int = 0) -> np.ndarray:
    """A bright bell: a counter lands, a badge appears (1.2 s)."""
    t = _t(1.2)
    x = np.zeros_like(t)
    for f, a, d in [(1318.5, 1.0, 4.0), (2637.0, 0.35, 6.0), (3955.5, 0.15, 9.0), (1976.0, 0.25, 5.0)]:
        x += a * np.sin(2 * np.pi * f * t) * np.exp(-t * d)
    return _fade(_norm(x, 0.7), 0.002, 0.1)


def tick(salt: int = 0) -> np.ndarray:
    """A tiny tick for a counter running up (use with repeat/every)."""
    r = _rng("tick", salt)
    t = _t(0.04)
    return _fade(_norm(_bandpass(r.standard_normal(t.size), 3000, 8000) * np.exp(-t * 200), 0.5), 0.0, 0.005)


def cash(salt: int = 0) -> np.ndarray:
    """Cash register 'ka-ching': a click then a bright bell."""
    t = _t(0.06)
    c = _bandpass(_rng("cash", salt).standard_normal(t.size), 1500, 6000) * np.exp(-t * 90)
    bell = ding(salt)
    return _fade(_norm(np.concatenate([c * 0.8, np.zeros(int(0.03 * SR)), bell]), 0.8), 0.0, 0.1)


def make(name: str, dur: float = 0.0, salt: int = 0) -> np.ndarray:
    beds = {"room_tone": room_tone, "drone": drone, "zombies": zombies, "heartbeat": heartbeat, "beat": beat}
    shots = {"glass_bang": glass_bang, "creak": creak, "sting": sting, "thud": thud, "click": click,
             "pop": pop, "whoosh": whoosh, "ding": ding, "tick": tick, "cash": cash}
    if name in beds:
        return beds[name](dur)
    if name in shots:
        return shots[name](salt)
    raise SystemExit(f"ERROR: unknown sound '{name}' (beds: {', '.join(BEDS)}; one-shots: {', '.join(ONE_SHOTS)})")


# --- voice effects ----------------------------------------------------------

def resample(x: np.ndarray, factor: float) -> np.ndarray:
    """Play back `factor` times faster (higher pitch)."""
    n = int(x.size / factor)
    return np.interp(np.arange(n) * factor, np.arange(x.size), x)


def toy_voice(x: np.ndarray) -> np.ndarray:
    """A cheap electronic toy speaker: pitched up, band-limited, bit-crushed."""
    y = resample(x, 1.18)
    y = _bandpass(y, 450, 4200, 2)
    y = _norm(y, 0.9)
    y = np.round(y * 24) / 24        # ~5-bit crunch
    return _norm(_lowpass(y, 6000), 0.9)


def toy_chorus(x: np.ndarray, copies: int = 9) -> np.ndarray:
    """Many toys at once, slightly out of sync and tune."""
    r = _rng("toy_chorus")
    base = toy_voice(x)
    out = np.zeros(base.size + int(0.12 * SR) + int(base.size * 0.08))
    for i in range(copies):
        v = resample(base, r.uniform(0.94, 1.08))
        off = int(r.uniform(0, 0.12) * SR)
        out[off:off + v.size] += v * r.uniform(0.5, 1.0)
    return _norm(out, 0.95)
