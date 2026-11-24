"""Khetolai, the village nearest the range, May 1998 (gags/village.gd, gag id "village").

Frame: the lane runs along z through the origin (x = 0); huts and houses behind (-z), the open desert toward +z where
cameras stand looking -z. The well at (-3.6, 0, -2.4); the hero khejri at (4.2, 0, -8.5) with a charpai beside it.

village_far: "If anything leaks, it must not drift toward people.": morning; dust wisps blow in from the desert past
the lens into the village; down the lane two kids run a bicycle tyre with a stick toward us, a woman crosses with
matkas stacked on her head, another hauls a bucket up the well, an old man dozes on a charpai. On "people" the kids
are close.
"""
from .common import W, frame, cam, move
from . import range as range_place

# On the bunker bay: the set's "village" anchor renders nothing (2026-11-24; to investigate).
VILLAGE_Z = 49000.0
P = frame("bunker", VILLAGE_Z)

LOOK_VILLAGE = dict(range_place.LOOK_MORNING,
                    ambient={"color": "#b89c78", "energy": 0.36, "sky": 0.6},
                    fog={"begin": 40, "end": 1800, "curve": 1.6, "volumetric": 0.0, "color": "#d8c8a8"})

VF = [{"shot": "village_far", "offset": -0.1}, {"shot": "wait_row"}]
_GO = {"shot": "village_far", "offset": -0.4}

ACTORS = [
    # Two kids racing a bicycle tyre down the lane toward us.
    {"id": "vk_tyre", "character": "toon_market_kid", "at": P(0.35, 0, -5.5), "facing": P(0.4, 0, 6.0), "action": "idle",
     "shown": [VF], "route": {"via": [P(0.45, 0, 4.2)], "gait": "run", "start": _GO},
     "cues": [{"t": 0.0, "expression": "laugh"}]},
    {"id": "vk_chase", "character": "toon_hasan_child_a", "at": P(-0.9, 0, -7.4), "facing": P(-0.6, 0, 6.0), "action": "idle",
     "shown": [VF], "route": {"via": [P(-0.7, 0, 2.6)], "gait": "run", "start": _GO},
     "cues": [{"t": 0.0, "expression": "grin"}]},
    # A woman crossing the lane with two matkas on her head.
    {"id": "vw_pots", "character": "toon_market_woman", "at": P(-6.0, 0, -9.6), "facing": P(3.0, 0, -10.4), "action": "idle",
     "shown": [VF], "route": {"via": [P(3.0, 0, -10.4)], "gait": "walk", "start": _GO},
     "cues": [{"t": 0.0, "expression": "happy"}]},
    # Another hauling the bucket up the well (side-on to us).
    {"id": "vw_well", "character": "toon_hasan_wife", "at": P(-2.35, 0, -2.4), "facing": P(-3.6, 0, -2.4), "action": "idle",
     "shown": [VF], "cues": [{"t": 0.0, "expression": "effort"}]},
    # The old man dozing on the charpai under the khejri.
    {"id": "v_elder", "character": "toon_market_elder", "at": P(5.6, 0, -6.9), "facing": P(5.2, 0, 2.0), "action": "sit",
     "shown": [VF], "cues": [{"t": 0.0, "expression": "sleepy", "head": [20, 0, 14], "head_turn": 0.01}]},
    # A small girl at a hut door, waving at the runners.
    {"id": "vk_door", "character": "toon_hasan_child_b", "at": P(-5.0, 0, -4.4), "facing": P(0.0, 0, -1.0), "action": "idle",
     "shown": [VF], "cues": [{"t": 0.0, "expression": "happy"}]},
]

GAGS = [{"id": "village", "script": "gags/village.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"tyre": [{"actor": "vk_tyre"}], "pots": ["vw_pots"],
                    "well": {"actor": "vw_well", "from": {"shot": "village_far", "offset": -0.3}, "to": W("l12c", edge="end", offset=0.4)},
                    "dust": {"from": {"shot": "village_far", "offset": -0.4}, "to": W("l12c", edge="end", offset=0.6), "dir": [0.25, -1.0]}}}]

SHOTS = {
    # From the desert's edge, low, the dust blowing past us into the village: a slow push down the lane as the kids race
    # their tyre toward us; on "people" they're close, laughing.
    "village_far": {"look": LOOK_VILLAGE, "camera": move(
        cam(P(1.4, 1.35, 13.0), P(0.0, 1.3, -6.0), 32, {"strength": 0.06}),
        cam(P(0.8, 1.15, 7.5), P(0.1, 1.0, -1.0), 32, {"strength": 0.08}), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
