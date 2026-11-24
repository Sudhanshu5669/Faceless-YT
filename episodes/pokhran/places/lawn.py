"""The Prime Minister's residence lawn, New Delhi, evening of 11 May 1998 (gags/pm_lawn.gd, gag id "lawn_pm").

Frame: the lectern at the origin facing +z, top at 0.92; Vajpayee stands at (0, 0, -0.42) facing +z.
The press line is at z +2.5..3.5. TV_CAM / TV_LOOK: the news camera whose picture plays on the analyst's TV.
"""
from .common import W, frame, cam, move
from . import range as range_place

LAWN_Z = 6000.0
P = frame("lawn", LAWN_Z)

TV_CAM = P(0.35, 1.3, 2.6)
TV_LOOK = P(0.0, 1.08, -0.42)

WALK = [{"shot": "presser_walk", "offset": -0.1}, {"shot": "presser_quote"}]

ACTORS = [
    # At the lectern (the analyst's TV in the hook).
    {"id": "vajpayee", "character": "toon_vajpayee", "at": P(0, 0, -0.42), "facing": P(0.2, 0, 3),
     "action": "talk", "shown": [[0.0, {"shot": "presser_walk", "offset": -0.1}]],
     "cues": [{"t": 0.0, "expression": "determined"}]},
    # presser_walk: he walks out from the shamiana's side to the microphones, arriving on "cameras".
    {"id": "vajpayee_walk", "character": "toon_vajpayee", "at": P(-2.4, 0, -1.7), "facing": P(0.0, 0, -0.42),
     "action": "idle", "shown": [WALK],
     "route": {"via": [P(-1.0, 0, -1.0), P(0.0, 0, -0.42)], "gait": "walk", "start": {"shot": "presser_walk", "offset": -0.6},
               "arrive": W("l15a", "cameras:", 0.0)},
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": W("l15a", "cameras:", 0.05), "facing": P(0.1, 0, 3.0)}]},
]
# The press line: photographers with SLRs up, shoulder to shoulder, between us and the lectern.
_PRESS = [("toon_market_man", -1.25, 3.0), ("toon_nerd", -0.75, 3.35), ("toon_shopkeeper", 0.85, 3.05),
          ("toon_isro_ctrl_b", 1.4, 3.3), ("toon_official", -1.9, 3.4)]
for _i, (_ch, _x, _z) in enumerate(_PRESS):
    ACTORS.append({"id": f"press_{_i}", "character": _ch, "at": P(_x, 0, _z), "facing": P(_x * 0.3, 0, -0.4),
                   "action": "idle", "shown": [WALK], "cues": [{"t": 0.0, "expression": "determined"}]})

GAGS = [{"id": "lawn_pm", "script": "gags/pm_lawn.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"flashes": [W("l1b", "announced", 0.05 + 0.27 * i) for i in range(6)]
                    + [W("l15a", "cameras:", -0.05 + 0.13 * i + 0.04 * (i % 3)) for i in range(9)],
                    "press": [f"press_{i}" for i in range(len(_PRESS))], "tvcam": [1.9, 3.6, 200.0]}}]

# Early evening in Delhi: the sky deep blue over the hedges, the shamiana lit by the TV lights.
LOOK_LAWN = dict(range_place.LOOK_DUSK,
                 ambient={"color": "#6a7088", "energy": 0.25, "sky": 0.4},
                 fog={"begin": 30, "end": 400, "curve": 1.5, "volumetric": 0.0},
                 glow={"enabled": True, "intensity": 0.8, "bloom": 0.08, "threshold": 1.0},
                 grade={"contrast": 1.15, "saturation": 1.0, "vignette": 0.42, "grain": 0.04})

SHOTS = {
    # A long lens through the press line (backs, raised cameras, soft in the foreground): Vajpayee walks out to the
    # microphones; on "cameras" the flashes go off in a burst.
    "presser_walk": {"look": LOOK_LAWN, "camera": move(
        cam(P(0.3, 2.0, 9.4), P(-0.75, 1.1, -0.9), 85, {"strength": 0.3}),
        cam(P(0.25, 1.98, 9.2), P(-0.1, 1.12, -0.5), 85, {"strength": 0.3}), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
