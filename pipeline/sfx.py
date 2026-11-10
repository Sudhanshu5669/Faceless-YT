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

BEDS = ["room_tone", "drone", "zombies", "heartbeat"]
ONE_SHOTS = ["glass_bang", "creak", "sting", "thud", "click"]


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


def make(name: str, dur: float = 0.0, salt: int = 0) -> np.ndarray:
    beds = {"room_tone": room_tone, "drone": drone, "zombies": zombies, "heartbeat": heartbeat}
    shots = {"glass_bang": glass_bang, "creak": creak, "sting": sting, "thud": thud, "click": click}
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
