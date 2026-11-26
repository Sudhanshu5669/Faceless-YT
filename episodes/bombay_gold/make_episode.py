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
    ("l4b", "stikine_bow", 0.0, "A British cargo ship, the Fort Stikine,", "serious"),
    ("l4c", "dock_moor", 0.0, "is tied up in Bombay's Victoria Dock.", ""),
    ("l5a", "xray_munitions", 0.1, "In her holds: about fourteen hundred tons of explosives.", "tense"),
    ("l5b", "crane_shells", 0.0, "Torpedoes, mines, shells.", "tense"),
    ("l6", "cotton_sling", 0.05, "Eight thousand seven hundred bales of raw cotton.", "serious"),
    ("l7", "gold_crates", 0.05, "And thirty-one crates of gold.", "whispers"),
    ("l8a", "xray_stack", 0.15, "The cotton is packed underneath the explosives.", "tense"),
    ("l8b", "empty_mast", 0.0, "And she isn't flying the red flag that warns of danger on board.", "serious"),
    # ACT 2: THE FIRE
    ("l9a", "clock_1230", 0.25, "At twelve-thirty,", "tense"),
    ("l9c", "officer_bino", 0.0, "an officer on the next ship", ""),
    ("l9d", "smoke_hold", 0.0, "sees smoke coming out of hold number two.", ""),
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
    ("l14a", "calm_406", 0.1, "Four-oh-six p.m.", "shouting"),
    ("l14c", "blast_wide", 0.0, "The Fort Stikine explodes.", ""),
    ("l14b", "hull_split", 0.0, "The ship is torn in two.", "serious"),
    ("l15", "jala_lift", 0.05, "The blast throws another ship, the Jalapadma,", "tense"),
    ("l15b", "jalapadma", 0.0, "out of the water and onto the dock.", ""),
    ("l16a", "shockwave_roofs", 0.1, "Windows shatter twelve kilometres away.", "tense"),
    ("l16b", "shimla_town", 0.0, "In Shimla, seventeen hundred kilometres away,", "serious"),
    ("l16c", "seismograph", 0.0, "instruments feel the ground shake.", ""),
    ("l17a", "cotton_rain", 0.15, "Burning cotton falls across the city.", "tense"),
    ("l17b", "gold_rain", 0.0, "And with it, gold.", "whispers"),
    ("l18", "second_blast", 0.15, "Less than half an hour later, a second explosion.", "tense"),
    # ACT 4: THE COST
    ("l19a", "night_masts", 0.3, "Thirteen ships are lost.", "serious"),
    ("l19b", "dock_fire", 0.0, "The docks burn for three days.", "serious"),
    ("l20a", "dawn_ruins", 0.2, "More than seven hundred people are killed.", "serious"),
    ("l20b", "families_walk", 0.0, "Eighty thousand lose their homes.", "sighs"),
    ("l21a", "helmets", 0.2, "Sixty-six of the dead are firemen.", "serious"),
    ("l21b", "fire_day", 0.1, "That's why, every April 14th,", "proud"),
    ("l21c", "fire_salute", 0.0, "India marks National Fire Service Day.", ""),
    # THE TURN
    ("l22a", "flat_return", 0.3, "And the gold bar in Girgaum?", "serious"),
    ("l22b", "police_desk", 0.0, "Its owner carries it to the police.", "serious"),
    ("l23a", "cheque_999", 0.1, "They reward him nine hundred and ninety-nine rupees.", "serious"),
    ("l23b", "relief_box", 0.0, "He gives every rupee to the relief fund for the victims.", "proud"),
    # CODA (loops to the hook)
    ("l24a", "dredger_2011", 0.3, "And the gold kept turning up.", "serious"),
    ("l24b", "grab_rise", 0.0, "As late as 2011,", "tense"),
    ("l24c", "dredger_crew", 0.0, "dredgers in Bombay's docks were still pulling", ""),
    ("l24d", "grab_bar", 0.0, "the ship's gold bars out of the mud.", ""),
]

# (shot, place) in edit order. single_take needs a line start in every shot, so beats without their own words
# (the officer's binoculars, the fire bell, the window bursting, the closing tilt to the sky) are camera moves
# inside the shot they belong to (see beats.md).
SHOTS = [
    ("hook_rain", "girgaum"), ("gold_fall", "girgaum"), ("bar_wall", "flat"), ("man_lift", "flat"),
    ("window_whip", "flat"),
    ("dock_wide", "dock"), ("stikine_bow", "dock"), ("dock_moor", "dock"), ("xray_munitions", "hold"), ("crane_shells", "dock"),
    ("cotton_sling", "dock"), ("gold_crates", "dock"), ("xray_stack", "hold"), ("empty_mast", "dock"),
    ("clock_1230", "dock"), ("officer_bino", "dock"), ("smoke_hold", "dock"), ("vent_push", "hold"), ("clock_1345", "dock"),
    ("engines_race", "dock"), ("fireboats", "dock"), ("hoses_900", "dock"),
    ("hold_steam", "hold"), ("hold_pops", "hold"), ("abandon", "dock"), ("clock_406", "dock"),
    ("calm_406", "dock"), ("blast_wide", "dock"), ("hull_split", "dock"), ("jala_lift", "dock"), ("jalapadma", "dock"), ("shockwave_roofs", "city"),
    ("shimla_town", "shimla"), ("seismograph", "shimla"), ("cotton_rain", "girgaum"), ("gold_rain", "girgaum"),
    ("second_blast", "dock"),
    ("night_masts", "dock"), ("dock_fire", "dock"), ("dawn_ruins", "dock"), ("families_walk", "dock"),
    ("helmets", "dock"), ("fire_day", "firestation"), ("fire_salute", "firestation"),
    ("flat_return", "flat"), ("police_desk", "police"), ("cheque_999", "police"), ("relief_box", "police"),
    ("dredger_2011", "port"), ("grab_rise", "port"), ("dredger_crew", "port"), ("grab_bar", "port"),
]

FIXED = {}

def _fx(name, at, gain=-6.0, **kw):
    d = {"file": f"audio/lib/sfx/{name}.wav", "at": at, "gain": gain}
    d.update(kw)
    return d


def W(line, word=None, offset=0.0):
    r = {"line": line}
    if word is not None:
        r["word"] = word
    if offset:
        r["offset"] = offset
    return r


# Recorded effects (Sonniss GDC bundle, built by make_audio.py), each placed on its word.
SFX = [
    _fx("smash", W("l2b", "smashed"), -3.0), _fx("woosh_debris", W("l2b", "smashed", 0.05), -10.0),
    _fx("crane", W("l5b", "Torpedoes,", -0.3), -14.0),
    _fx("clock_tick", {"shot": "clock_1230"}, -11.0),
    _fx("bell", W("l10", "alarm", -0.05), -5.0),
    _fx("truck_pass", W("l11a", "Firemen", -0.6), -7.0),
    _fx("water_douse", W("l11c", "pour"), -10.0), _fx("water_douse", {"shot": "hold_steam"}, -9.0),
    _fx("smash", W("l12a", "going"), -12.0, repeat=4, every=0.55),
    _fx("clock_tick", W("l13", "Sixteen"), -9.0), _fx("clock_tick", W("l13", "later", 0.05), -5.0),
    _fx("boom_big", W("l14c", "explodes"), -1.0), _fx("impact_sweep", W("l14c", "explodes", 0.05), -8.0),
    _fx("woosh_debris", W("l14c", "explodes", 0.4), -7.0),
    _fx("metal_scrape", W("l14b", "torn"), -6.0),
    _fx("metal_crash", W("l15b", "dock.", -0.05), -3.0),
    _fx("boom_far", W("l16a", "Windows", -0.2), -9.0), _fx("glass", W("l16a", "shatter", -0.02), -3.0),
    _fx("walla_panic", W("l17a", "Burning", -0.3), -13.0),
    _fx("boom_mid", W("l18", "second"), -2.0),
    _fx("smash", W("l22b", "police.", -0.3), -14.0),
    _fx("braam_b", W("l24d", "gold", -0.1), -9.0),
]

# Beds (recorded ambiences, one-shot cues) and the score (Scott Buckley, CC BY 4.0).
MUSIC = [
    {"file": "audio/lib/sfx/street_amb.wav", "at": W("l1"), "until": {"shot": "dock_wide"}, "gain": -21, "fade_in": 0.5, "fade_out": 1.0, "duck": 0.6},
    {"file": "audio/lib/sfx/dock_amb.wav", "at": {"shot": "dock_wide"}, "until": {"shot": "vent_push"}, "gain": -22, "fade_in": 1.0, "fade_out": 1.0, "duck": 0.6},
    {"file": "audio/lib/sfx/fire_crackle.wav", "at": {"shot": "hoses_900"}, "until": W("l14c", "explodes"), "gain": -18, "fade_in": 1.5, "fade_out": 0.2, "duck": 0.6},
    {"file": "audio/lib/sfx/fire_crackle.wav", "at": {"shot": "night_masts"}, "until": {"shot": "dawn_ruins"}, "gain": -16, "fade_in": 0.5, "fade_out": 1.5, "duck": 0.6},
    {"file": "audio/lib/sfx/wind.wav", "at": {"shot": "shimla_town"}, "until": {"shot": "cotton_rain"}, "gain": -22, "fade_in": 0.5, "fade_out": 0.5, "duck": 0.6},
    {"file": "audio/lib/sfx/wind.wav", "at": {"shot": "dawn_ruins"}, "until": {"shot": "fire_day"}, "gain": -24, "fade_in": 1.0, "fade_out": 1.0, "duck": 0.6},
    {"file": "audio/lib/music/penumbra.wav", "at": {"shot": "bar_wall"}, "until": W("l14c", "explodes"), "offset": 30.0, "gain": -16,
     "fade_in": 1.2, "fade_out": 0.15, "duck": 0.55},
    {"file": "audio/lib/music/memories_of_stone.wav", "at": W("l19a"), "offset": 0.0, "gain": -15, "fade_in": 2.5, "fade_out": 2.0,
     "duck": 0.55},
]


def placeholder_camera(place):
    return {"at": {"anchor": place, "offset": [0, 1.6, 6]}, "look_at": {"anchor": place, "offset": [0, 1.2, 0]},
            "lens_mm": 35}


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


def _shown_in(items, own):
    """Each place's gags and actors are drawn only during the place's own shots (the doctor_doom fix: places sit
    within a few km of the origin for float precision, and only the active one is visible). An item's own
    "shown" spans (shot references) are clipped to its place's shots."""
    order = [l[1] for l in LINES]
    idx = {n: k for k, n in enumerate(order)}
    mine = {idx[n] for n in own if n in idx}
    out = []
    for a in items:
        a = dict(a)
        cover = mine
        if "shown" in a:
            cover = set()
            for sp in a["shown"]:
                stop = idx[sp[1]["shot"]] if isinstance(sp[1], dict) and sp[1].get("shot") else len(order)
                cover |= set(range(idx[sp[0]["shot"]], stop))
            cover &= mine
        a["shown"] = _runs(order, cover)
        out.append(a)
    return out


def build():
    gags, actors, reveals, overrides = [], [], [], {}
    for mod in PLACE_MODULES:
        place = importlib.import_module("places." + mod).PLACE
        own = set(place["shots"])
        gags += _shown_in(place["gags"], own)
        actors += _shown_in(place["actors"], own)
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
        # The drone stays out of the hook (the user found it creepy there): it fades in on the third shot.
        "ambience": [{"sound": "drone", "gain": -26, "duck": 0.5,
                      "curve": [[0, 0.0], [{"shot": "bar_wall"}, 0.0], [{"shot": "bar_wall", "at": 1.0}, 1.0]]}],
        "music": MUSIC,
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
