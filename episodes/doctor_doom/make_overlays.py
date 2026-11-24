"""Renders the 2D overlays (HyperFrames, transparent ProRes 4444 at 60 fps) into overlays/out/ (git-ignored).

    python episodes/doctor_doom/make_overlays.py [name ...]

Templates: overlays/chapter (chapter cards), overlays/headline (a real headline as a news card: exact wording only,
sources in script.md). make_episode.py places every rendered file at its time (OVERLAYS there).
Needs Node 22+ and FFmpeg; HyperFrames (Apache 2.0) runs through npx with telemetry off.
"""
import json
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "overlays" / "out"

OVERLAYS = {
    "ch1": ("chapter", {"num": "CHAPTER ONE", "title": "THE VILLAIN MARVEL LOST"}),
    "ch2": ("chapter", {"num": "CHAPTER TWO", "title": "VICTOR"}),
    "ch3": ("chapter", {"num": "CHAPTER THREE", "title": "THE MOST DANGEROUS MAN IN MARVEL"}),
    "ch4": ("chapter", {"num": "CHAPTER FOUR", "title": "WHY IRON MAN"}),
    # NPR, 25 Mar 2023 (also run by NPR member stations): the arrest.
    "news_arrest": ("headline", {"outlet": "NPR", "date": "25/03/2023", "before": "Actor Jonathan Majors ",
                                 "mark": "was arrested for assault", "after": " in New York City", "dur": 5.0}),
    # Euronews (AP copy), 19 Dec 2023: the verdict and Marvel's decision.
    "news_verdict": ("headline", {"outlet": "euronews.", "date": "19/12/2023", "before": "Jonathan Majors ",
                                  "mark": "found guilty of assault", "after": " and dropped by Marvel", "dur": 6.0}),
}


def main(names: list[str]) -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, DO_NOT_TRACK="1", HYPERFRAMES_NO_TELEMETRY="1")
    npx = "npx.cmd" if os.name == "nt" else "npx"
    for name, (tpl, vars_) in OVERLAYS.items():
        if names and name not in names:
            continue
        out = OUT / f"{name}.mov"
        cmd = [npx, "-y", "hyperframes@0.9.88", "render", str(HERE / "overlays" / tpl), "--fps", "60", "--format", "mov",
               "--variables", json.dumps(vars_), "-o", str(out), "--quiet"]
        print("render", name, flush=True)
        r = subprocess.run(cmd, env=env, capture_output=True, text=True)
        if r.returncode != 0 or not out.exists():
            print(r.stdout[-2000:], r.stderr[-2000:])
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
