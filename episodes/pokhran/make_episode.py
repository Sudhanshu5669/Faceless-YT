"""Generates episodes/pokhran/episode.json (edit this file, not the JSON).

    python episodes/pokhran/make_episode.py

"India blew up the White House": Pokhran-II, May 1998, told as a heist.
Script: script.md (approved 2026-11-22). Beats and places: beats.md.

Every place is a gag script in gags/, standing far from the others on one stage set
(specs/sets/pokhran.json): desk (US analyst's office), range (Pokhran), orbit (spy satellite), office
(South Block), bunker, airstrip (Jaisalmer), village (Khetolai), lawn (PM's residence), capitol,
lok_sabha, rashtrapati, school.
"""
import importlib
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

# Place modules (places/<name>.py), each with PLACE = {"gags", "actors", "shots"}; added as they are built.
PLACE_MODULES = [m for m in ["desk", "range", "orbit", "office", "bunker", "airstrip", "village", "lawn",
                             "capitol", "lok_sabha", "rashtrapati", "school"]
                 if (HERE / "places" / f"{m}.py").exists()]

NARRATION = {"model": "gemini-3.8-flash-tts", "voice": "Charon", "single_take": True,
             "style": "gripping true-story narrator for a YouTube Short, telling a heist: brisk, confident and "
                      "a little sly, conspiratorial and hushed in the secret night work, tense while the team waits "
                      "on the wind, then proud and punchy at the announcement",
             "speed": 1.0}

# (line id, first shot, start inside that shot, text, optional style)
LINES = [
    ("l1a", "hook_feed", 0.2, "On May 11th, 1998, India blew up the White House.", None),
    ("l1b", "hook_analyst", 0.05, "And America only found out when India announced it.", None),
    ("l2a", "snow_globe", 0.15, "Not that White House.", None),
    ("l2b", "range_noon", 0.05, "A shaft in the Rajasthan desert,", None),
    ("l2c", "shaft_dive", 0.0, "two hundred metres deep,", None),
    ("l2d", "lid_chalk", 0.0, "code-named White House.", None),
    ("l2e", "device_inside", 0.1, "With a hydrogen bomb inside.", None),
    ("l3a", "rewind", 0.25, "Rewind to 1995.", None),
    ("l3b", "range_1995", 0.1, "Imagine you're India's nuclear team, getting ready to test right here.", None),
    ("l3c", "sat_turn", 0.05, "But American spy satellites are watching.", None),
    ("l4a", "nyt_slap", 0.15, "The New York Times prints it.", None),
    ("l4b", "wisner_photos", 0.0, "The US ambassador shows up with the photos.", None),
    ("l4c", "rao_phone", 0.0, "President Clinton calls your Prime Minister.", None),
    ("l4d", "shovel_back", 0.0, "Test cancelled.", None),
    ("l5a", "office_1998", 0.25, "Now it's 1998.", None),
    ("l5b", "vajpayee_order", 0.05, "A new Prime Minister, Atal Bihari Vajpayee, gives the order: do it again.", None),
    ("l5c", "same_desert", 0.1, "Same desert. Same satellites.", None),
    ("l5d", "team_lookup", 0.0, "But this time, they must see nothing.", None),
    ("l6a", "night_work", 0.2, "So you work only at night.", None),
    ("l6b", "truck_park", 0.05, "And by sunrise, every truck is back in its exact parking spot,", None),
    ("l6c", "photos_same", 0.0, "so the morning photos look the same.", None),
    ("l7a", "dune_shape", 0.15, "The sand you dig out? Shaped by hand into dunes, the way the wind would make them.", None),
    ("l7b", "net_drape", 0.05, "The shafts hide under camouflage nets.", None),
    ("l8a", "pass_watch", 0.2, "When a satellite passes overhead,", None),
    ("l8b", "statue", 0.0, "work stops.", None),
    ("l8c", "cricket", 0.15, "In between, the soldiers play cricket,", None),
    ("l8d", "cricket_feed", 0.0, "so the pictures show a bored army camp.", None),
    ("l9a", "jeep_arrive", 0.2, "Your scientists arrive dressed as soldiers.", None),
    ("l9b", "kalam_tape", 0.05, "Even India's missile man, Abdul Kalam, gets a fake army name: Prithviraj.", None),
    ("l10a", "an32_land", 0.2, "The bombs arrive at dawn: flown in from Mumbai on an air force plane,", None),
    ("l10b", "convoy", 0.0, "then driven into the desert by an army convoy.", None),
    ("l11a", "cage_lower", 0.15, "Three go down into the shafts.", None),
    ("l11b", "lid_wh", 0.05, "Code names: White House,", None),
    ("l11c", "lid_taj", 0.0, "Taj Mahal,", None),
    ("l11d", "lid_kumbh", 0.0, "and Kumbhkaran.", None),
    ("l12a", "clock_nine", 0.25, "May 11th. Everything is set for nine a.m.", None),
    ("l12b", "windsock", 0.05, "Then the wind blows the wrong way.", None),
    ("l12c", "village_far", 0.0, "If anything leaks, it must not drift toward people.", None),
    ("l13a", "wait_row", 0.2, "So the most secret team in India just waits.", "Slower and deadpan."),
    ("l13b", "wait_clock", 0.1, "Six hours. Staring at the wind.", "Slow, dry, deadpan."),
    ("l14a", "wind_turns", 0.3, "At three forty-five p.m., the wind turns.", "Tense, hushed."),
    ("l14b", "key_turn", 0.05, "The key turns.", "Tense, hushed."),
    ("l14c", "desert_jumps", 0.05, "The desert jumps.", "Punchy."),
    ("l14d", "khetolai_crack", 0.15, "In Khetolai, the nearest village, people say their walls cracked.", None),
    ("l15a", "presser_walk", 0.25, "Hours later, Vajpayee walks out to the cameras:", None),
    ("l15b", "presser_quote", 0.05, "Today, at fifteen forty-five hours, India conducted three underground nuclear tests in the Pokhran range.",
     "Read as a quote: measured, formal, proud."),
    ("l16a", "phones_ring", 0.2, "In Washington, the phones start ringing.", None),
    ("l16b", "analyst_feed", 0.0, "America's spies had missed the whole thing.", None),
    ("l17a", "senator", 0.15, "A US senator calls it a colossal failure.", None),
    ("l17b", "review_drop", 0.05, "The CIA's own review finds it simply assumed India would never test.", None),
    ("l18a", "two_more", 0.2, "Two days later, you test two more.", None),
    ("l18b", "lok_sabha", 0.05, "On May 27th, Vajpayee tells Parliament: India is now a nuclear weapon state.",
     "Proud and firm."),
    ("l19a", "kalam_cap", 0.3, "Four years later, the scientist with the fake army name,", None),
    ("l19c", "never_noticed", 0.0, "the one the satellites never noticed,", None),
    ("l19b", "rashtrapati", 0.0, "becomes the President of India.", "Warm and proud."),
    ("l20", "tech_day", 0.3, "And every May 11th, India celebrates National Technology Day.", None),
    ("l21a", "end_range", 0.25, "All because of one afternoon in the desert,", None),
    ("l21b", "end_feed", 0.0, "when India blew up the White House.", "Sly, landing the punchline."),
]

# (shot, place) in edit order. Cameras and durations are filled in place by place (see beats.md).
SHOTS = [
    ("hook_feed", "desk"), ("hook_analyst", "desk"), ("snow_globe", "desk"),
    ("range_noon", "range"), ("shaft_dive", "range"), ("lid_chalk", "range"), ("device_inside", "range"),
    ("rewind", "desk"), ("range_1995", "range"), ("sat_turn", "orbit"),
    ("nyt_slap", "office"), ("wisner_photos", "office"), ("rao_phone", "office"), ("shovel_back", "range"),
    ("office_1998", "office"), ("vajpayee_order", "office"), ("same_desert", "range"), ("team_lookup", "range"),
    ("night_work", "range"), ("truck_park", "range"), ("photos_same", "desk"),
    ("dune_shape", "range"), ("net_drape", "range"),
    ("pass_watch", "range"), ("statue", "range"), ("cricket", "range"), ("cricket_feed", "desk"),
    ("jeep_arrive", "range"), ("kalam_tape", "range"),
    ("an32_land", "airstrip"), ("convoy", "range"),
    ("cage_lower", "range"), ("lid_wh", "range"), ("lid_taj", "range"), ("lid_kumbh", "range"),
    ("clock_nine", "bunker"), ("windsock", "range"), ("village_far", "village"),
    ("wait_row", "bunker"), ("wait_clock", "bunker"),
    ("wind_turns", "range"), ("key_turn", "bunker"), ("desert_jumps", "range"), ("khetolai_crack", "village"),
    ("presser_walk", "lawn"), ("presser_quote", "lawn"),
    ("phones_ring", "desk"), ("analyst_feed", "desk"),
    ("senator", "capitol"), ("review_drop", "desk"),
    ("two_more", "range"), ("lok_sabha", "lok_sabha"),
    ("kalam_cap", "range"), ("never_noticed", "desk"), ("rashtrapati", "rashtrapati"),
    ("tech_day", "school"),
    ("end_range", "range"), ("end_feed", "desk"),
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
        "id": "pokhran",
        "title": "India Blew Up the White House",
        "description": "Pokhran-II (Operation Shakti), May 1998: how India hid its nuclear tests from US spy satellites.",
        "set": "specs/sets/pokhran.json",
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
