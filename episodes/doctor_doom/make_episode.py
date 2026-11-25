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


def _shown_in(gags, own):
    """Each place's gags are drawn only during the place's own shots. The places used to be kept apart by distance
    (20-220 km out), which cost float precision: cameras stepped in 1-2 cm jumps (the 'shaking') and layered
    decals z-fought. Now they all sit within ~7 km of the origin and only the active one is visible."""
    order = [l[1] for l in LINES]
    spans, i = [], 0
    while i < len(order):
        if order[i] in own:
            j = i
            while j + 1 < len(order) and order[j + 1] in own:
                j += 1
            end = {"shot": order[j + 1]} if j + 1 < len(order) else {"line": LINES[-1][0], "edge": "end", "offset": 30.0}
            spans.append([{"shot": order[i]}, end])
            i = j + 1
        else:
            i += 1
    out = []
    for g in gags:
        g = dict(g)
        if spans and "shown" not in g:
            g["shown"] = spans
        out.append(g)
    return out


def _runs(order, keep):
    """[from, to] shot-ref spans covering the shots of `order` whose index is in `keep`."""
    spans, i = [], 0
    while i < len(order):
        if i in keep:
            j = i
            while j + 1 in keep:
                j += 1
            end = {"shot": order[j + 1]} if j + 1 < len(order) else {"line": LINES[-1][0], "edge": "end", "offset": 30.0}
            spans.append([{"shot": order[i]}, end])
            i = j + 1
        else:
            i += 1
    return spans


def _actors_in(actors, own):
    """An actor's "shown" spans clipped to its place's own shots (so it never appears in a neighbouring place now that
    the places sit close together). Spans must be written as shot references."""
    order = [l[1] for l in LINES]
    idx = {n: k for k, n in enumerate(order)}
    mine = {idx[n] for n in own if n in idx}
    out = []
    for a in actors:
        a = dict(a)
        if "shown" in a:
            cover = set()
            for sp in a["shown"]:
                if not (isinstance(sp[0], dict) and "shot" in sp[0]):
                    raise SystemExit(f"actor {a['id']}: 'shown' spans must start on a shot reference to be clipped")
                # The end: the next shot's start, or anything else (a word in the last shot) = to the end.
                stop = idx[sp[1]["shot"]] if isinstance(sp[1], dict) and sp[1].get("shot") else len(order)
                cover |= set(range(idx[sp[0]["shot"]], stop))
            a["shown"] = _runs(order, cover & mine)
        else:
            a["shown"] = _runs(order, mine)
        out.append(a)
    return out


def build():
    gags, actors, reveals, overrides = [], [], [], {}
    for mod in PLACE_MODULES:
        place = importlib.import_module("places." + mod).PLACE
        gags += _shown_in(place["gags"], set(place["shots"]))
        actors += _actors_in(place["actors"], set(place["shots"]))
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
