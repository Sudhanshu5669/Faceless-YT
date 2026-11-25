"""Builds episodes/bombay_gold/audio/lib/ (git-ignored) from the downloaded packs in incoming/.

    python episodes/bombay_gold/make_audio.py

Sound effects: Sonniss GDC 2026 Game Audio Bundle (licence v2.0: commercial use in our video, no attribution; the raw
sounds may not be redistributed, so they never enter git). Each effect is cut at its onset (so `at` = the hit) and
saved as mono 16-bit WAV. Ambiences take a fixed or the loudest window.
Music: Scott Buckley, CC BY 4.0 (credit in the description: incoming/music_doom/LICENSE.txt), converted to WAV.
"""
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SON = ROOT / "incoming" / "sonniss_gdc2026" / "wav"
MUS = ROOT / "incoming" / "music_doom"
OUT = HERE / "audio" / "lib"
SR = 48000

# name: (pack folder fragment, file fragment, mode, seconds)   mode: "onset" | "loud" | start second
SFX = {
    "braam": ("Cinematic Horn Braams", "Huge-32", "onset", 6.0),
    "braam_b": ("Cinematic Horn Braams", "Huge-67", "onset", 6.0),
    "boom_big": ("Trailer Booms", "011", "onset", 7.0),
    "boom_mid": ("Trailer Booms", "075", "onset", 6.0),
    "boom_far": ("Trailer Booms", "214", "onset", 6.0),
    "woosh_debris": ("Colossal Impacts", "Woosh Debris", "onset", 3.0),
    "impact_sweep": ("Colossal Impacts", "Impact Cut Sweep", "onset", 4.0),
    "metal_crash": ("Moaning Metal", "Metal Hit Thud", "onset", 4.0),
    "metal_scrape": ("Moaning Metal", "Metal Scrape Low Tonal", "onset", 4.0),
    "glass": ("Elemental Mutation", "Glass Crystal Fragments", "onset", 2.5),
    "smash": ("Halloween Game", "Heavy Impact Smash", "onset", 2.0),
    "fire_crackle": ("Campfire - Bonfire", "Pine Branches", 2.0, 14.0),
    "water_douse": ("Campfire - Bonfire", "Putting Out Fire", "onset", 5.0),
    "bell": ("Church Bells", "Near Distance", "onset", 6.0),
    "clock_tick": ("Antique Clocks", "Crooked Antique Clock", "onset", 4.0),
    "truck_pass": ("Pass-By - Trains", "Freight Truck Pass By", "loud", 5.0),
    "dock_amb": ("Ship Repair Factory", "Factory Hall Busy", "loud", 16.0),
    "crane": ("Ship Repair Factory", "Crane Onboard", "loud", 6.0),
    "walla_panic": ("Crowds Walla", "Cruise Ship Walla", "loud", 10.0),
    "street_amb": ("Urban Life Exteriors", "City Courtyard Calm", 3.0, 14.0),
    "wind": ("Extreme Winds", "Eye Of The Storm", 3.0, 14.0),
}

MUSIC = {
    "penumbra": "Penumbra.mp3",
    "memories_of_stone": "MemoriesOfStone.mp3",
    "unraveling": "Unraveling.mp3",
}


def decode(path: Path, channels: int) -> np.ndarray:
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "s16le", "-ac", str(channels), "-ar", str(SR), "-"],
                         capture_output=True, check=True).stdout
    x = np.frombuffer(raw, dtype=np.int16).astype(np.float64) / 32768.0
    return x.reshape(-1, channels) if channels > 1 else x


def write(path: Path, x: np.ndarray, channels: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(channels)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def find(pack: str, frag: str) -> Path:
    for d in SON.iterdir():
        if pack in d.name:
            for f in d.rglob("*.wav"):
                if frag in f.name:
                    return f
    raise SystemExit(f"ERROR: no file matching {pack!r} / {frag!r} in {SON}")


def main() -> int:
    only_music = "--music" in sys.argv
    for name, (pack, frag, mode, secs) in ({} if only_music else SFX).items():
        x = decode(find(pack, frag), 1)
        n = int(secs * SR)
        if mode == "onset":
            peak = np.max(np.abs(x)) or 1.0
            idx = np.argmax(np.abs(x) > 0.12 * peak)
            i0 = max(0, idx - int(0.01 * SR))
        elif mode == "loud":
            n = min(n, x.size - 1)
            c = np.concatenate([[0.0], np.cumsum(x * x)])
            i0 = int(np.argmax(c[n:] - c[:-n]))
        else:
            i0 = int(float(mode) * SR)
        seg = x[i0:i0 + n].copy()
        fade = min(int(0.3 * SR), seg.size)
        seg[-fade:] *= np.linspace(1.0, 0.0, fade)
        peak = np.max(np.abs(seg)) or 1.0
        write(OUT / "sfx" / f"{name}.wav", seg / peak * 0.9, 1)
        print(f"sfx   {name:16} {seg.size / SR:5.1f} s")
    for name, fn in MUSIC.items():
        x = decode(MUS / fn, 2)
        write(OUT / "music" / f"{name}.wav", x.reshape(-1), 2)
        m = x.mean(axis=1)
        blocks = m[: m.size // (SR * 4) * SR * 4].reshape(-1, SR * 4)
        env = np.sqrt((blocks ** 2).mean(axis=1))
        print(f"music {name:16} {x.shape[0] / SR:6.1f} s  rms/4s: " + " ".join(f"{v:.2f}" for v in env[:40]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
