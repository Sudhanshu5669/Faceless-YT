"""Generates episodes/bombay_gold/episode.json (edit this file, not the JSON).

    python episodes/bombay_gold/make_episode.py

"It rained gold on Bombay": the Fort Stikine explosion, Victoria Dock, 14 April 1944.
Script: script.md (approved 2026-11-25). Beats and places: beats.md. Facts: research.md.

Every place is a gag script in gags/ on one stage set (specs/sets/bombay_gold.json): girgaum (street and
rooftops), flat (the Parsi gentleman's home), dock (Victoria Dock: the Fort Stikine, quay, cranes, the dock
clock; day, blast, night fire, dawn aftermath), hold (No. 2 hold, X-ray cutaway and interior), city (a street
12 km away), shimla (the seismograph), police (a 1940s police station and the relief fund box outside),
firestation (National Fire Service Day today), port (Mumbai port, 2011, the dredger).
"""
import importlib
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

PLACE_MODULES = [m for m in ["girgaum", "flat", "dock", "hold", "city", "shimla", "police", "firestation", "port"]
                 if (HERE / "places" / f"{m}.py").exists()]

# One single take on the lite model with one-word inline [tags] (performed silently; tested on pokhran
# 2026-11-22: excited, sarcastic, mischievously, tense, deadpan, proud, chuckles, gasps, serious, whispers,
# laughs, sighs, shouting). Tone: a gripping, grave true-story narrator; restraint for the dead.
NARRATION = {"model": "gemini-3.8-flash-lite-tts", "voice": "Charon", "single_take": True, "inline_tags": True,
             "max_pause": 0.4, "speed": 1.0,
             "style": ""}
# (2026-11-25: the lite model read the leading [style] aloud twice, long and short; the one-word line tags carry
# the delivery instead.)

# (line id, first shot, start inside that shot, text, style)
LINES = [
    # HOOK
    ("l1", "hook_rain", 0.05, "It rained gold on Bombay.", "tense"),
    ("l2a", "gold_fall", 0.0, "Real gold bars, falling out of the sky.", "tense"),
    ("l2b", "bar_wall", 0.0, "One smashed into this man's home.", "serious"),
    ("l3a", "man_lift", 0.1, "What he did next, almost nobody would do.", "whispers"),
    ("l3b", "window_whip", 0.0, "But first: where did the gold come from?", "tense"),
    # ACT 1: THE SHIP
    ("l4a", "dock_wide", 0.25, "It's April 14, 1944. World War Two.", "serious"),
    ("l4b", "stikine_bow", 0.0, "A British cargo ship, the Fort Stikine, is tied up in Bombay's Victoria Dock.", "serious"),
    ("l5a", "xray_munitions", 0.1, "In her holds: about fourteen hundred tons of explosives.", "tense"),
    ("l5b", "crane_shells", 0.0, "Torpedoes, mines, shells.", "tense"),
    ("l6", "cotton_sling", 0.05, "Eight thousand seven hundred bales of raw cotton.", "serious"),
    ("l7", "gold_crates", 0.05, "And thirty-one crates of gold.", "whispers"),
    ("l8a", "xray_stack", 0.15, "The cotton is packed underneath the explosives.", "tense"),
    ("l8b", "empty_mast", 0.0, "And she isn't flying the red flag that warns of danger on board.", "serious"),
    # ACT 2: THE FIRE
    ("l9a", "clock_1230", 0.25, "At twelve-thirty, an officer on the next ship sees smoke coming out of hold number two.", "tense"),
    ("l9b", "vent_push", 0.05, "The hold with the gold.", "whispers"),
    ("l10", "clock_1345", 0.15, "It's more than an hour before anyone raises the alarm.", "serious"),
    ("l11a", "engines_race", 0.1, "Firemen race in.", "excited"),
    ("l11b", "fireboats", 0.0, "Fireboats pull alongside.", "tense"),
    ("l11c", "hoses_900", 0.0, "They pour more than nine hundred tons of water into the ship,", "tense"),
    ("l11d", "hold_steam", 0.0, "and still can't find the fire.", "serious"),
    ("l12a", "hold_pops", 0.15, "Down in the hold, the shells start going off.", "tense"),
    ("l12b", "abandon", 0.0, "At three-fifty comes the order: abandon ship.", "shouting"),
    ("l13", "clock_406", 0.2, "Sixteen minutes later.", "whispers"),
    # ACT 3: THE BLAST
    ("l14a", "blast_wide", 0.1, "Four-oh-six p.m. The Fort Stikine explodes.", "shouting"),
    ("l14b", "hull_split", 0.0, "The ship is torn in two.", "serious"),
    ("l15", "jalapadma", 0.05, "The blast throws another ship, the Jalapadma, out of the water and onto the dock.", "tense"),
    ("l16a", "shockwave_roofs", 0.1, "Windows shatter twelve kilometres away.", "tense"),
    ("l16b", "seismograph", 0.0, "In Shimla, seventeen hundred kilometres away, instruments feel the ground shake.", "serious"),
    ("l17a", "cotton_rain", 0.15, "Burning cotton falls across the city.", "tense"),
    ("l17b", "gold_rain", 0.0, "And with it, gold.", "whispers"),
    ("l18", "second_blast", 0.15, "Less than half an hour later, a second explosion.", "tense"),
    # ACT 4: THE COST
    ("l19a", "night_masts", 0.3, "Thirteen ships are lost.", "serious"),
    ("l19b", "dock_fire", 0.0, "The docks burn for three days.", "serious"),
    ("l20a", "dawn_ruins", 0.2, "More than seven hundred people are killed.", "serious"),
    ("l20b", "families_walk", 0.0, "Eighty thousand lose their homes.", "sighs"),
    ("l21a", "helmets", 0.2, "Sixty-six of the dead are firemen.", "serious"),
    ("l21b", "fire_day", 0.1, "That's why, every April 14th, India marks National Fire Service Day.", "proud"),
    # THE TURN
    ("l22a", "flat_return", 0.3, "And the gold bar in Girgaum?", "serious"),
    ("l22b", "police_desk", 0.0, "Its owner carries it to the police.", "serious"),
    ("l23a", "cheque_999", 0.1, "They reward him nine hundred and ninety-nine rupees.", "serious"),
    ("l23b", "relief_box", 0.0, "He gives every rupee to the relief fund for the victims.", "proud"),
    # CODA (loops to the hook)
    ("l24a", "dredger_2011", 0.3, "And the gold kept turning up.", "serious"),
    ("l24b", "grab_bar", 0.0, "As late as 2011, dredgers in Bombay's docks were still pulling the ship's gold bars out of the mud.", "tense"),
]

# (shot, place) in edit order. single_take needs a line start in every shot, so beats without their own words
# (the officer's binoculars, the fire bell, the window bursting, the closing tilt to the sky) are camera moves
# inside the shot they belong to (see beats.md).
SHOTS = [
    ("hook_rain", "girgaum"), ("gold_fall", "girgaum"), ("bar_wall", "flat"), ("man_lift", "flat"),
    ("window_whip", "flat"),
    ("dock_wide", "dock"), ("stikine_bow", "dock"), ("xray_munitions", "hold"), ("crane_shells", "dock"),
    ("cotton_sling", "dock"), ("gold_crates", "dock"), ("xray_stack", "hold"), ("empty_mast", "dock"),
    ("clock_1230", "dock"), ("vent_push", "hold"), ("clock_1345", "dock"),
    ("engines_race", "dock"), ("fireboats", "dock"), ("hoses_900", "dock"),
    ("hold_steam", "hold"), ("hold_pops", "hold"), ("abandon", "dock"), ("clock_406", "dock"),
    ("blast_wide", "dock"), ("hull_split", "dock"), ("jalapadma", "dock"), ("shockwave_roofs", "city"),
    ("seismograph", "shimla"), ("cotton_rain", "girgaum"), ("gold_rain", "girgaum"),
    ("second_blast", "dock"),
    ("night_masts", "dock"), ("dock_fire", "dock"), ("dawn_ruins", "dock"), ("families_walk", "dock"),
    ("helmets", "dock"), ("fire_day", "firestation"),
    ("flat_return", "flat"), ("police_desk", "police"), ("cheque_999", "police"), ("relief_box", "police"),
    ("dredger_2011", "port"), ("grab_bar", "port"),
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
            s["duration"] = {"fit": True, "min": 1.0, "tail": 0.15}
        else:
            s["duration"] = 1.5
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
        "id": "bombay_gold",
        "title": "It Rained Gold on Bombay",
        "description": "The Fort Stikine explosion, Victoria Dock, Bombay, 14 April 1944.",
        "set": "specs/sets/bombay_gold.json",
        "format": {"resolution": [1080, 1920], "fps": 60, "motion_blur": 2},
        "narration": NARRATION,
        "captions": {"enabled": True, "max_words": 2, "position": 0.87},
        "ambience": [{"sound": "beat", "gain": -21, "duck": 0.55}],
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
