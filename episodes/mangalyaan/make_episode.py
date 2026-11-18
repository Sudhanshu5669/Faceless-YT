"""Generates episodes/mangalyaan/episode.json (edit this file, not the JSON).

    python episodes/mangalyaan/make_episode.py

"How India went to Mars for less than an auto ride": the Mars Orbiter Mission, 2012-2022.
Script: script.md (approved 2026-11-18). Beats and places: beats.md.

Every place is a gag script in gags/, standing far from the others on one stage set
(specs/sets/mangalyaan.json): lane (Ahmedabad), lab (ISRO Satellite Centre), space, pad (Sriharikota),
ship (SCI Nalanda in the Pacific), control (ISTRAC), mars (Gale Crater), club (New York), atm.
"""
import importlib
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

# Place modules (places/<name>.py), each with PLACE = {"gags", "actors", "shots"}.
PLACE_MODULES = ["space", "control", "lab", "lane", "mars", "pad", "club", "ship", "atm"]

NARRATION = {"model": "gemini-3.8-flash-tts", "voice": "Charon", "single_take": True,
             "style": "inspiring documentary narrator for a YouTube Short: brisk, warm and clear, quiet wonder, "
                      "tense and hushed when the room waits, rising to joyful pride at the Mars orbit",
             "speed": 1.0}

# (line id, first shot, start inside that shot, text, optional style)
LINES = [
    ("l1a1", "hook_street", 0.25, "A one-kilometre auto ride in Ahmedabad", None),
    ("l1a2", "auto_meter", 0.0, "costs about ten rupees.", None),
    ("l1b", "auto_space", 0.1, "India went to Mars for seven.", None),
    ("l2a", "isro_window", 0.2, "Imagine you're ISRO, in 2012.", None),
    ("l2b", "mars_club", 0.15, "America, the Soviet Union and Europe have all reached Mars.", None),
    ("l3a1", "fail_japan", 0.15, "Japan tried.", None),
    ("l3a2", "fail_china", 0.0, "China tried. Both failed.", None),
    ("l3b", "mars_graveyard", 0.15, "More than half of all missions to Mars have failed.", None),
    ("l4", "moon_window", 0.2, "And you've never sent anything farther than the Moon.", None),
    ("l5a", "approval", 0.2, "In August 2012, the government says yes.", None),
    ("l5b", "orrery", 0.1, "Mars only comes close every 26 months.", None),
    ("l5c", "calendar", 0.1, "Miss November 2013, and you wait more than two years.", None),
    ("l5d", "cleanroom_build", 0.15, "So you have fifteen months.", None),
    ("l6a", "budget_stack", 0.15, "Your budget: four hundred and fifty crore rupees.", None),
    ("l6b", "budget_gravity", 0.05, "Less than it cost Hollywood to make the movie Gravity.", None),
    ("l7", "pslv_pad", 0.2, "There's one more problem. Your rocket, the PSLV, isn't strong enough to throw anything to Mars.", None),
    ("l8a", "gulel", 0.1, "So you don't throw it. You swing it.", None),
    ("l8b", "orbit_loops", 0.1, "Around the Earth, again and again, every loop bigger than the last.", None),
    ("l9a", "countdown_wait", 0.15, "You even delay launch by a week,", None),
    ("l9b", "ship_storm", 0.05, "because one of your tracking ships is stuck in bad weather in the Pacific.", None),
    ("l10a", "launch", 0.3, "On November 5th, 2013, you launch.", None),
    ("l10b", "tmi_burn", 0.1, "A month later, the final burn.", None),
    ("l10c", "slingshot", 0.05, "ISRO calls it the mother of all slingshots.", None),
    ("l11a", "cruise_sleep", 0.3, "Then, for ten months, your main engine sleeps,", None),
    ("l11b", "cruise_map", 0.05, "while you cross more than six hundred million kilometres of space.", None),
    ("l12a", "maven_arrival", 0.2, "Two days before you arrive, NASA's MAVEN reaches Mars.", None),
    ("l12b", "price_tags", 0.1, "It cost six hundred and seventy-one million dollars. You cost about seventy-four.", None),
    ("l13a", "test_fire_key", 0.25, "September 22nd. You wake the engine up for four seconds.", None),
    ("l13b", "test_fire", 0.2, "It fires.", None),
    ("l14a", "moi_start", 0.25, "September 24th. The real thing: a 24-minute burn.", None),
    ("l14b", "moi_risk", 0.1, "If it fails, you fly right past Mars, forever.", None),
    ("l15a", "room_static", 0.15, "And you can't even watch.", None),
    ("l15b", "signal_crawl", 0.1, "Every signal takes twelve minutes to reach you,", None),
    ("l15c", "behind_mars", 0.05, "and part of the burn happens behind Mars.", None),
    ("l16", "room_waits", 0.4, "So the whole room waits.",
     "Hushed and slow, holding the breath."),
    ("l17a", "signal_back", 0.3, "Then the signal comes back.", None),
    ("l17b", "in_orbit", 0.1, "You're in orbit.", None),
    ("l17c", "room_erupts", 0.1, "First in Asia. And the first country ever to reach Mars on its first try.",
     "Rising, proud and joyful."),
    ("l18a", "curiosity_wave", 0.2, "NASA's Curiosity rover tweets: Namaste, Mars Orbiter!", None),
    ("l18b", "mom_reply", 0.1, "And you reply: Howdy, Curiosity? Keep in touch. I'll be around.", None),
    ("l19a", "club_room", 0.2, "Four days later, The New York Times prints a cartoon:", None),
    ("l19b", "club_door", 0.05, "India as a farmer with a cow, knocking on the door of the Elite Space Club.", None),
    ("l20a", "letters_pile", 0.15, "After thousands of complaints,", None),
    ("l20b", "apology", 0.0, "the paper apologises.", None),
    ("l21a", "six_months", 0.2, "And the insane part? You were built to last six months.", None),
    ("l21b", "eight_years", 0.05, "You keep working for almost eight years.", None),
    ("l22", "atm_note", 0.2, "Your picture even ends up on India's new two-thousand-rupee note.", None),
    ("l23", "window_mars", 0.25, "In Hindi, Mars is Mangal. It also means auspicious.", None),
    ("l24", "auto_end", 0.2, "Not bad, for seven rupees a kilometre.", None),
]

# (shot, place) in edit order. Cameras and durations are filled in place by place (see beats.md).
SHOTS = [
    ("hook_street", "lane"), ("auto_meter", "lane"), ("auto_space", "space"),
    ("isro_window", "lab"), ("mars_club", "space"),
    ("fail_japan", "space"), ("fail_china", "space"), ("mars_graveyard", "space"),
    ("moon_window", "lab"), ("approval", "lab"), ("orrery", "lab"), ("calendar", "lab"),
    ("cleanroom_build", "lab"), ("budget_stack", "lab"), ("budget_gravity", "lab"),
    ("pslv_pad", "pad"), ("gulel", "lab"), ("orbit_loops", "space"),
    ("countdown_wait", "pad"), ("ship_storm", "ship"),
    ("launch", "pad"), ("tmi_burn", "space"), ("slingshot", "space"),
    ("cruise_sleep", "space"), ("cruise_map", "space"),
    ("maven_arrival", "space"), ("price_tags", "space"),
    ("test_fire_key", "control"), ("test_fire", "space"),
    ("moi_start", "space"), ("moi_risk", "space"),
    ("room_static", "control"), ("signal_crawl", "space"), ("behind_mars", "space"),
    ("room_waits", "control"),
    ("signal_back", "control"), ("in_orbit", "space"), ("room_erupts", "control"),
    ("curiosity_wave", "mars"), ("mom_reply", "space"),
    ("club_room", "club"), ("club_door", "club"), ("letters_pile", "club"), ("apology", "club"),
    ("six_months", "space"), ("eight_years", "space"),
    ("atm_note", "atm"),
    ("window_mars", "lab"),
    ("auto_end", "space"),
]

# Shots that carry no line start: fixed lengths for now (retimed against the voice per place).
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
            s["duration"] = {"fit": True, "min": 1.2, "tail": 0.2}
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
        "id": "mangalyaan",
        "title": "How India Went to Mars for Less Than an Auto Ride",
        "description": "ISRO's Mars Orbiter Mission (Mangalyaan), 2012-2022, as a toon Short.",
        "set": "specs/sets/mangalyaan.json",
        "format": {"resolution": [1080, 1920], "fps": 60, "motion_blur": 2},
        "narration": NARRATION,
        "captions": {"enabled": True, "max_words": 2, "position": 0.87},
        "ambience": [{"sound": "beat", "gain": -22, "duck": 0.55}],
        "sfx": [
            {"sound": "whoosh", "at": {"line": "l1a1", "offset": -0.2}, "gain": -6},
            {"sound": "click", "at": {"line": "l1a2", "word": "costs", "offset": -0.25}},
            {"sound": "whoosh", "at": {"line": "l1b", "offset": -0.15}, "gain": -3},
            {"sound": "thud", "at": {"line": "l5a", "word": "yes"}},
            {"sound": "cash", "at": {"line": "l6a", "word": "four"}},
            {"sound": "thud", "at": {"line": "l6b", "word": "Gravity"}},
            {"sound": "whoosh", "at": {"line": "l10c", "word": "slingshots", "offset": -0.3}},
            {"sound": "click", "at": {"line": "l13a", "word": "wake"}},
            {"sound": "thud", "at": {"line": "l13b", "word": "fires"}, "gain": -4},
            {"sound": "sting", "at": {"line": "l17a", "word": "comes", "offset": -1.4}, "gain": -4},
            {"sound": "pop", "at": {"line": "l18a", "word": "tweets"}},
            {"sound": "pop", "at": {"line": "l18b", "word": "reply"}},
            {"sound": "thud", "at": {"line": "l19b", "word": "knocking"}, "repeat": 3, "every": 0.22, "gain": -6},
            {"sound": "rip", "at": {"line": "l20a", "word": "thousands"}, "gain": -10},
            {"sound": "click", "at": {"line": "l22", "word": "picture", "offset": -0.2}},
        ],
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
