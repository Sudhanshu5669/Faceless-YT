"""Generates episodes/doctor_doom/episode.json (edit this file, not the JSON).

    python episodes/doctor_doom/make_episode.py

"Who is Doctor Doom, and why is Iron Man playing him?": long-form (16:9, ~9.5 min), for Avengers: Doomsday
(US release 18 Dec 2026). Pitch: pitch.md. Assets: ASSETS.md. Handoff: HANDOFF.md.

DEMO STAGE (2026-11-24): three demo sequences to set the look (Hall H, the lab explosion, the Kang board). Their
lines are drafts from the pitch, fact-checked; the full script comes after the user approves the look.

Every place is a gag script in gags/ on its own bay (specs/sets/doctor_doom.json): hall (Hall H), lab (Empire State
University, 1960s), board (Marvel Studios boardroom).
"""
import importlib
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from lines import L, PLACE_OF, CHAPTERS  # noqa: E402
from sound import SFX, MUSIC, OVERLAY_AT  # noqa: E402

PLACE_MODULES = [m for m in ["hall", "lab", "board", "gallery", "cinema", "shop", "doom62", "latveria", "tibet", "castle",
                             "hell", "cosmos", "hospital", "dressing", "misc"] if (HERE / "places" / f"{m}.py").exists()]

NARRATION = {"model": "gemini-3.8-flash-lite-tts", "voice": "Charon", "single_take": True, "inline_tags": True,
             "max_pause": 0.6, "speed": 1.0, "style": "gripping documentary storyteller"}

# Lines and shots come from lines.py (the approved script, one line per shot).
LINES = [(lid, shot, 0.2 if k == 0 else 0.05, text, style) for k, (lid, shot, text, style) in enumerate(L)]
SHOTS = [(l[1], PLACE_OF[l[1].split("_")[0]]) for l in L]

FIXED = {}


def placeholder_camera(place):
    bay = place if place in ("hall", "lab", "board") else "board"
    return {"at": {"anchor": bay, "offset": [0, 1.6, 6]}, "look_at": {"anchor": bay, "offset": [0, 1.2, 0]},
            "lens_mm": 35}


def build():
    gags, actors, reveals, overrides = [], [], [], {}
    for mod in PLACE_MODULES:
        place = importlib.import_module("places." + mod).PLACE
        gags += place["gags"]
        actors += place["actors"]
        reveals += place.get("reveals", [])
        overrides.update(place["shots"])
    shots = []
    starts = {l[1] for l in LINES}
    for name, place in SHOTS:
        s = {"name": name, "camera": placeholder_camera(place)}
        if name in FIXED:
            s["duration"] = FIXED[name]
        elif name in starts:
            s["duration"] = {"fit": True, "min": 1.0, "tail": 0.3}
        else:
            s["duration"] = 2.0
        s.update(overrides.get(name, {}))
        shots.append(s)
    lines = []
    for lid, shot, at, text, style in LINES:
        ln = {"id": lid, "shot": shot, "at": at, "text": text}
        if style:
            ln["style"] = style
        lines.append(ln)
    return {
        "schema_version": "0.1",
        "id": "doctor_doom",
        "title": "Who is Doctor Doom, and why is Iron Man playing him?",
        "description": "Doctor Doom's comic origin and why Marvel cast Robert Downey Jr. as the villain of Avengers: Doomsday.",
        "set": "specs/sets/doctor_doom.json",
        "format": {"resolution": [1920, 1080], "fps": 60, "motion_blur": 2},
        "narration": NARRATION,
        "captions": {"enabled": True, "max_words": 3, "position": 0.9},
        "ambience": [],
        "music": MUSIC,
        "overlays": [{"file": f"overlays/out/{k}.mov", "at": at} for k, at in OVERLAY_AT.items()
                     if (HERE / "overlays" / "out" / f"{k}.mov").exists()],
        "sfx": SFX,
        "lines": lines,
        "actors": actors,
        "gags": gags,
        "reveals": reveals,
        "shots": shots,
    }


def main():
    episode = build()
    (HERE / "episode.json").write_text(json.dumps(episode, indent=1) + "\n", encoding="utf-8")
    print(f"wrote episode.json: {len(episode['shots'])} shots, {len(episode['lines'])} lines")


if __name__ == "__main__":
    main()
