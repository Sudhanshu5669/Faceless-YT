"""Tibet (gags/tibet.gd, gag id "tibet_set"): the monastery on its cliff, and the forge.

Frame: the monastery at (0, 10..25, -62) on a crag; the forge at (0, 0, 300): anvil at (0, 0.7, 0), coals at
(-1.6, 0.85, -0.8). Victor (unmasked, in a dark tunic) stands at (-0.4, 0, 0.9); a monk hammers at (0.75, 0, 0.6).

tibet_cliff (v8: dusk, prayer flags, the monastery), tibet_forge (v9: hammer blows on the plate, sparks),
tibet_mask (v10: the tongs bring the red-hot mask toward the lens; white on "red-hot.").
"""
from .common import W, frame, cam, move

P = frame("board", -4800.0)   # near the origin (float precision); gags are shown only in their shots
F = 300.0

LOOK_DUSK = {
    "base": "dusk", "time": "18:10",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.2, "wind": 0.3},
    "sun": {"elevation": 3, "azimuth": 250, "color": "#ff9a6a", "energy": 1.6, "softness": 0.8, "visible": True,
            "size": 1.6, "glow": 2.2, "shadows": True},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "sky": {"top": "#2a3a6a", "horizon": "#ff9a6a", "clouds": 0.25},
    "ambient": {"color": "#6a6a8a", "energy": 0.35, "sky": 0.5},
    "fog": {"begin": 60, "end": 900, "curve": 1.4, "volumetric": 0.004, "color": "#c8a8a0"},
    "glow": {"enabled": True, "intensity": 0.6, "bloom": 0.04, "threshold": 1.15},
    "ssao": True,
    "grade": {"contrast": 1.14, "saturation": 1.0, "vignette": 0.4, "grain": 0.04},
}
LOOK_FORGE = dict(LOOK_DUSK, base="night_fog", time="22:00",
                  sun={"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
                  sky={"top": "#05060a", "horizon": "#0a0c12", "clouds": 0.0, "stars": 0.0},
                  ambient={"color": "#2a1c16", "energy": 0.08, "sky": 0.0},
                  fog={"begin": 400, "end": 3000, "curve": 1.8, "volumetric": 0.02, "color": "#c08060", "anisotropy": 0.5,
                       "length": 15},
                  glow={"enabled": True, "intensity": 0.9, "bloom": 0.06, "threshold": 1.0},
                  grade={"contrast": 1.22, "saturation": 1.05, "vignette": 0.5, "grain": 0.05})


def span(a, b):
    return [{"shot": a, "offset": -0.1}, {"shot": b}]


ACTORS = [
    {"id": "victor_forge", "character": "toon_victor_young", "at": P(-1.0, 0, F + 0.55), "facing": P(0.0, 0, F), "action": "idle",
     "shown": [span("tibet_forge", "castle_gates")],
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": W("v10", "red-hot.", -0.6), "expression": "determined"}]},
    {"id": "monk_0", "character": "toon_monk", "at": P(0.85, 0, F + 0.35), "facing": P(0.0, 0, F), "action": "idle",
     "shown": [span("tibet_forge", "castle_gates")], "cues": [{"t": 0.0, "expression": "determined"}]},
    {"id": "monk_1", "character": "toon_monk", "at": P(-2.4, 0, F + 0.2), "facing": P(-1.6, 0, F - 0.8), "action": "idle",
     "shown": [span("tibet_forge", "castle_gates")], "cues": [{"t": 0.0, "expression": "thinking"}]},
]

GAGS = [
    {"id": "tibet_set", "script": "gags/tibet.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"smith": "monk_0", "strikes": [W("v9", "forges", 0.0), W("v9", "his", 0.0), W("v9", "armor.", 0.0)],
                "mask": {"t": W("v10", 0, -0.2), "white": W("v10", "red-hot.", 0.1)}}},
]

SHOTS = {
    # Dusk: the monastery on its crag, prayer flags snapping down the slope; a slow rise.
    "tibet_cliff": {"look": LOOK_DUSK, "camera": move(
        cam(P(-26.0, 6.0, -12.0), P(0.0, 18.0, -62.0), 26, {"strength": 0.03}),
        cam(P(-22.0, 10.0, -18.0), P(0.0, 19.0, -62.0), 26, {"strength": 0.03}), "in_out")},
    # The forge: the monk's hammer falls on the glowing plate, sparks on each word.
    "tibet_forge": {"look": LOOK_FORGE, "shake": [{"t": W("v9", "armor.", 0.0), "amount": 0.06}], "camera": move(
        cam(P(0.3, 1.35, F + 2.6), P(-0.05, 0.85, F), 32, {"strength": 0.12}),
        cam(P(0.2, 1.3, F + 2.2), P(-0.05, 0.85, F), 32, {"strength": 0.14}), "in")},
    # The tongs bring the glowing mask out of the coals toward us; white on "red-hot.".
    "tibet_mask": {"look": LOOK_FORGE, "camera": move(
        cam(P(0.1, 1.45, F + 2.6), P(-1.2, 1.0, F - 0.6), 30, {"strength": 0.12}),
        cam(P(-0.05, 1.35, F + 2.2), P(-0.1, 1.25, F + 0.9), 30, {"strength": 0.18}), "in")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
