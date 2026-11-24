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

PLACE_MODULES = [m for m in ["hall", "lab", "board"] if (HERE / "places" / f"{m}.py").exists()]

NARRATION = {"model": "gemini-3.8-flash-lite-tts", "voice": "Charon", "single_take": True, "inline_tags": True,
             "max_pause": 0.5, "speed": 1.0,
             "style": "gripping, cinematic documentary narrator for a YouTube deep dive on a comic-book villain"}

# (line id, first shot, start inside that shot, text, style). Styles are one-word inline tags (see pokhran).
LINES = [
    # Hall H (cold open). Sources: CBC / AP 2024-07-27 (the unmasking, "New mask, same task."); Hall H seats ~6,130.
    ("h1", "hall_wide", 0.3, "July 2024. Hall H, San Diego Comic-Con.", "serious"),
    ("h2", "hall_walk", 0.1, "More than six thousand fans watch a line of masked men in green cloaks walk onto the stage.",
     "whispers"),
    ("h3", "hall_unmask", 0.15, "Then one of them takes off his mask.", "tense"),
    ("h4", "hall_reveal", 0.05, "It's Robert Downey Junior. Iron Man himself.", "excited"),
    ("h5", "hall_quote", 0.1, "And he tells the crowd: new mask, same task.", "mischievously"),
    # The lab (chapter 2). Sources: Wikipedia "Doctor Doom" (Empire State University, Reed), Nerdist / TV Tropes
    # (the machine to reach his mother in the realm of the dead, Reed's warning about the calculations, the explosion).
    ("v1", "lab_machine", 0.3, "At Empire State University, Victor builds a machine to reach the realm of the dead, "
     "and speak to his mother.", "serious"),
    ("v2", "lab_warning", 0.05, "His classmate, Reed Richards, spots a flaw in the calculations.", "tense"),
    ("v3", "lab_ignore", 0.05, "Victor ignores him.", "deadpan"),
    ("v4", "lab_blast", 0.05, "The machine explodes in his face.", "shouting"),
    # The board (chapter 1). Sources: Wikipedia "Avengers: Doomsday" (The Kang Dynasty, SDCC 2022), "Jonathan Majors"
    # (convicted of assault and harassment and dropped by Marvel on 18 Dec 2023).
    ("k1", "board_plan", 0.3, "Marvel had built its next saga around one villain: Kang.", "serious"),
    ("k2", "board_news", 0.05, "Then, in December 2023, the actor who played him was convicted of assault and harassment.",
     "serious"),
    ("k3", "board_collapse", 0.05, "Marvel dropped him the same day. And the whole plan came down.", "sighs"),
]

SHOTS = [
    ("hall_wide", "hall"), ("hall_walk", "hall"), ("hall_unmask", "hall"), ("hall_reveal", "hall"), ("hall_quote", "hall"),
    ("lab_machine", "lab"), ("lab_warning", "lab"), ("lab_ignore", "lab"), ("lab_blast", "lab"),
    ("board_plan", "board"), ("board_news", "board"), ("board_collapse", "board"),
]

FIXED = {}


def placeholder_camera(place):
    return {"at": {"anchor": place, "offset": [0, 1.6, 6]}, "look_at": {"anchor": place, "offset": [0, 1.2, 0]},
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
        "ambience": [{"sound": "beat", "gain": -22, "duck": 0.55}],
        "sfx": [],
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
