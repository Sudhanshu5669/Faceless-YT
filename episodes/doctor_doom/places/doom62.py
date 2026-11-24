"""Fantastic Four #5 (1962): Doom's lab and Blackbeard's ship (gags/doom62.gd, gag id "doom62_set").

Frame: LAB at the origin: the time platform at (-2.2, 0, -1.5), the cage at (2.4, 0, -1.8), Doom's console at
(0.5, 0, -3.0); SEA at (400, 0, 0) with the ship centred there (deck ~2.6 m up).

doom62_kidnap (v0e: Sue in the force-field cage, Doom at his console), doom62_platform (v0f: Reed, Johnny and the Thing
on the time platform; it flashes on "machine,"), pirate_chest (v0g: the chest hauled aboard on "treasure"),
pirate_thing (v0h: the Thing at the wheel in a tricorn hat, shrugging), doom62_feet (v0i: the chest at Doom's feet;
he doesn't look down).
"""
from .common import W, frame, cam, move

P = frame("board", 200000.0)
S = 400.0

LOOK_LAB62 = {
    "base": "night_fog", "time": "23:00",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.0},
    "sun": {"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "sky": {"top": "#04060a", "horizon": "#0a0e14", "clouds": 0.0, "stars": 0.0},
    "ambient": {"color": "#1e2a24", "energy": 0.12, "sky": 0.0},
    "fog": {"begin": 400, "end": 3000, "curve": 1.8, "volumetric": 0.012, "color": "#8ab09a", "anisotropy": 0.5, "length": 20},
    "glow": {"enabled": True, "intensity": 0.85, "bloom": 0.06, "threshold": 1.05},
    "ssao": True,
    "grade": {"contrast": 1.2, "saturation": 1.08, "vignette": 0.5, "grain": 0.05},
}
LOOK_SEA = dict(LOOK_LAB62, sky={"top": "#060a12", "horizon": "#1a2232", "clouds": 0.6, "stars": 0.0},
                weather={"fog": 0.2, "rain": 0.8, "clouds": 0.9, "wind": 0.8},
                ambient={"color": "#2a3448", "energy": 0.3, "sky": 0.0},
                fog={"begin": 20, "end": 300, "curve": 1.3, "volumetric": 0.008, "color": "#3a4658"})


def span(a, b):
    return [{"shot": a, "offset": -0.1}, {"shot": b}]


ACTORS = [
    {"id": "doom62", "character": "toon_doom_extra", "at": P(0.5, 0, -2.7), "facing": P(-2.2, 0, -1.5), "action": "idle",
     "shown": [span("doom62_kidnap", "pirate_chest")], "cues": [{"t": 0.0, "expression": "smug"}]},
    {"id": "doom62_b", "character": "toon_doom_extra", "at": P(0.9, 0, 0.3), "facing": P(0.9, 0, 6.0), "action": "idle",
     "shown": [span("doom62_feet", "shop_stack")], "cues": [{"t": 0.0, "expression": "smug"}]},
    {"id": "sue", "character": "toon_sue", "at": P(2.4, 0, -1.8), "facing": P(2.4, 0, 3.0), "action": "idle",
     "shown": [span("doom62_kidnap", "pirate_chest")], "cues": [{"t": 0.0, "expression": "shocked"}]},
    {"id": "thing_sea", "character": "toon_thing", "at": P(S + 0.0, 2.6, -2.2), "facing": P(S + 0.0, 2.6, 6.0), "keep_y": True,
     "action": "idle", "shown": [span("pirate_chest", "doom62_feet")],
     "cues": [{"t": 0.0, "expression": "deadpan"}, {"t": W("v0h", "Blackbeard.", 0.0), "expression": "side_eye"}]},
]
for _i, (_ch, _x, _z) in enumerate([("toon_reed_ff", -2.6, -1.2), ("toon_johnny", -1.8, -1.2), ("toon_thing", -2.2, -1.9)]):
    ACTORS.append({"id": f"ff_{_i}", "character": _ch, "at": P(_x, 0.26, _z), "facing": P(_x, 0.26, 3.0), "keep_y": True,
                   "action": "idle", "shown": [span("doom62_kidnap", "pirate_chest")],
                   "cues": [{"t": 0.0, "expression": "angry"}, {"t": W("v0f", "time", 0.0), "expression": "shocked"}]})

GAGS = [
    {"id": "doom62_set", "script": "gags/doom62.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"platform": W("v0f", "machine,", 0.1), "gone": ["ff_0", "ff_1", "ff_2"], "chest": W("v0i", 0, -0.2),
                "haul": W("v0g", "treasure", -0.3), "hat": {"actor": "thing_sea"},
                "lightning": [W("v0g", "steal", 0.0), W("v0h", "Thing", 0.0)]}},
    {"id": "doom62_suits", "script": "library:doom_suit", "t": 0, "at": P(0, 0, 0),
     "params": {"actors": [{"actor": "doom62"}, {"actor": "doom62_b"}]}},
]

SHOTS = {
    # Sue in the glowing cage; Doom at his dials.
    "doom62_kidnap": {"look": LOOK_LAB62, "camera": move(
        cam(P(1.4, 1.5, 3.2), P(1.6, 1.2, -2.0), 30, {"strength": 0.08}),
        cam(P(1.0, 1.55, 2.6), P(1.4, 1.2, -2.0), 30, {"strength": 0.08}), "in")},
    # The other three forced onto the time platform; it charges and flashes on "machine,".
    "doom62_platform": {"look": LOOK_LAB62, "shake": [{"t": W("v0f", "machine,", 0.1), "amount": 0.1}], "camera": move(
        cam(P(0.4, 1.4, 3.0), P(-2.2, 1.3, -1.5), 30, {"strength": 0.08}),
        cam(P(0.0, 1.4, 2.4), P(-2.2, 1.3, -1.5), 30, {"strength": 0.08}), "in")},
    # Blackbeard's ship in the storm; the chest hauled up over the rail.
    "pirate_chest": {"look": LOOK_SEA, "camera": move(
        cam(P(S + 6.5, 2.4, 7.5), P(S + 1.5, 2.4, 1.8), 28, {"strength": 0.04}),
        cam(P(S + 5.0, 3.0, 6.0), P(S + 1.0, 2.8, 1.8), 28, {"strength": 0.04}), "in_out")},
    # The Thing at the helm in a tricorn hat.
    "pirate_thing": {"look": LOOK_SEA, "camera": move(
        cam(P(S + 1.6, 3.9, 0.6), P(S + 0.0, 3.7, -2.2), 32, {"strength": 0.12}),
        cam(P(S + 1.3, 3.85, 0.2), P(S + 0.0, 3.7, -2.2), 32, {"strength": 0.12}), "in")},
    # Back in the lab: the chest lands at Doom's feet; he looks at us, not at it.
    "doom62_feet": {"look": LOOK_LAB62, "camera": move(
        cam(P(0.9, 0.7, 3.4), P(0.9, 0.9, 0.6), 30, {"strength": 0.1}),
        cam(P(0.9, 0.9, 2.8), P(0.9, 1.1, 0.4), 30, {"strength": 0.1}), "in")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
