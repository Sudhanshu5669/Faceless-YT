"""Builds episodes/doctor_doom/audio/lib/ (git-ignored) from the downloaded packs in incoming/.

    python episodes/doctor_doom/make_audio.py

Sound effects: Sonniss GDC 2026 Game Audio Bundle (licence v2.0: commercial use in our video, no attribution; the raw
sounds may not be redistributed, so they never enter git). Each effect is cut at its onset (so `at` = the hit) and
saved as mono 16-bit WAV. Long ambiences take their loudest (or a fixed) window.
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

# name: (pack folder fragment, file fragment, mode, seconds)
#   mode "onset": cut from the first loud sample, keep `seconds`
#   mode "loud":  the loudest window of `seconds`
#   mode float:   start at that second, keep `seconds`
SFX = {
    "braam_a": ("Cinematic Horn Braams", "Huge-32", "onset", 6.0),
    "braam_b": ("Cinematic Horn Braams", "Huge-67", "onset", 6.0),
    "boom_a": ("Trailer Booms", "011", "onset", 6.0),
    "boom_b": ("Trailer Booms", "075", "onset", 6.0),
    "boom_c": ("Trailer Booms", "214", "onset", 6.0),
    "impact_sweep": ("Colossal Impacts", "Impact Cut Sweep", "onset", 4.0),
    "woosh_debris": ("Colossal Impacts", "Woosh Debris", "onset", 3.0),
    "snap": ("Colossal Impacts", "Frantic Shaker Snap", "onset", 2.5),
    "impact_chord": ("Ultra Transitions", "Rapid Chord Reverb", "onset", 4.0),
    "braam_creepy": ("Ultra Transitions", "Braam Slow Dark Creepy", "onset", 6.0),
    "woosh_ui": ("Ultra Transitions", "Woosh Sweep Slide", "onset", 2.0),
    "arc_zap": ("InMotionAudio - Arc", "ArcDesign15", "onset", 1.5),
    "arc_powerup": ("InMotionAudio - Arc", "ArcPowerUpDesign04", "onset", 7.0),
    "arc_buzz": ("InMotionAudio - Arc", "Buzz27", "onset", 8.0),
    "crowd_cheer": ("Volleyball Match", "Masculine", "loud", 7.0),
    "crowd_cheer_b": ("Volleyball Match", "Feminine", "loud", 7.0),
    "wind_storm": ("Extreme Winds", "Eye Of The Storm", 3.0, 14.0),
    "metal_drag": ("Extreme Winds", "Metal Box, Drag", "onset", 4.0),
    "storm_night": ("Stormy Night Ambience", "Storm", 2.0, 14.0),
    "fire_crackle": ("Campfire - Bonfire", "Pine Branches", 2.0, 12.0),
    "paper_turn": ("Paper Foley", "Page Turn Tail", "onset", 1.5),
    "paper_rummage": ("Paper Foley", "Newspaper", "onset", 2.0),
    "metal_hit": ("Historical Weapons Vol. 2", "Sword Slide Cuts", "onset", 2.0),
    "shield_spin": ("Historical Weapons Vol. 2", "Shield Spin", "onset", 3.0),
    "wood_hit": ("Historical Weapons Vol. 2", "Spear And Stick", "onset", 1.5),
    "latch_thunk": ("Lock And Mechanism", "Latch Button", "onset", 1.5),
    "spell_drone": ("Ghostly Presences", "Evil Spell", 1.0, 10.0),
}

MUSIC = {
    "eyes_in_the_void": "EyesInTheVoid.mp3",
    "anabasis": "Anabasis_I.mp3",
    "convergence": "Convergence.mp3",
    "penumbra": "Penumbra.mp3",
    "aphelion": "Aphelion.mp3",
    "starfire": "Starfire.mp3",
    "born_of_the_sky": "BornOfTheSky.mp3",
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
    for name, (pack, frag, mode, secs) in SFX.items():
        x = decode(find(pack, frag), 1)
        n = int(secs * SR)
        if mode == "onset":
            peak = np.max(np.abs(x)) or 1.0
            idx = np.argmax(np.abs(x) > 0.12 * peak)
            i0 = max(0, idx - int(0.01 * SR))
        elif mode == "loud":
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
        print(f"music {name:16} {x.shape[0] / SR:6.1f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
