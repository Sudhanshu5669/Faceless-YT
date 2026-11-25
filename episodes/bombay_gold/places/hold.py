"""No. 2 hold of the Fort Stikine, inside (gags/hold.gd, gag id "hold_set").

Frame: the hold floor at y 0, 18 m wide (x), 16 m long (z), 9 m deep; the hatch opening overhead at y 9 (x -4..4,
z -3..3); cotton fills y 0..2.2; munitions crates on top at z 2..6, torpedoes at z -2.2, mines at x 4..5.3,
shells at x 6.4; the gold cage in the corner at (-6, 2.2, -5).
"""
from .common import W, frame, cam, move

P = frame("hold", 0.0)

LOOK_HOLD = {
    "base": "night_fog", "time": "12:40",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.0},
    "sun": {"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "sky": {"top": "#0a0a0c", "horizon": "#141210", "clouds": 0.0, "stars": 0.0},
    "ambient": {"color": "#3a3026", "energy": 0.28, "sky": 0.0},
    "fog": {"begin": 200, "end": 900, "curve": 1.6, "volumetric": 0.06, "color": "#c8b898", "anisotropy": 0.75, "length": 40},
    "glow": {"enabled": True, "intensity": 0.8, "bloom": 0.06, "threshold": 1.05},
    "ssao": True,
    "grade": {"contrast": 1.2, "saturation": 1.0, "vignette": 0.5, "grain": 0.045},
}
LOOK_SMOKE = dict(LOOK_HOLD, fog={"begin": 200, "end": 900, "curve": 1.6, "volumetric": 0.05, "color": "#7a6a58",
                                  "anisotropy": 0.6, "length": 40})

GAGS = [{"id": "hold_set", "script": "gags/hold.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"smoke": {"shot": "vent_push"}, "water": W("l11d", "and"), "glow": W("l11d", "fire.", -0.2),
                    "pops": W("l12a", "going", -0.1)}}]

REVEALS = [
    {"id": "n_tons", "t": W("l5a", offset=0.05), "until": {"shot": "crane_shells"}, "at": P(0.0, 5.6, 3.0), "size": 0.7,
     "counter": {"from": 0, "to": 1400, "land": W("l5a", "hundred", 0.1), "label": "TONS OF EXPLOSIVES"}, "sound": "ding"},
]

SHOTS = {
    # Down through the hatch into the hold: shafts of sun in the dust, the crates of munitions stacked on the cotton.
    "xray_munitions": {"look": LOOK_HOLD, "camera": move(
        cam(P(0.5, 12.0, 0.8), P(0.0, 2.0, 2.5), 22),
        cam(P(1.2, 6.2, -2.4), P(0.5, 3.0, 4.5), 22), "in_out")},
    # Low between the stacks: cotton bales underneath, the crates of shells and torpedoes piled on top of them.
    "xray_stack": {"look": LOOK_HOLD, "camera": move(
        cam(P(-8.1, 0.8, 4.6), P(-6.6, 2.4, -1.5), 22),
        cam(P(-8.1, 1.3, 3.6), P(-6.6, 3.0, -1.5), 22), "in_out")},
    # In the smoke, a push toward the gold cage: the bars glint.
    "vent_push": {"look": LOOK_SMOKE, "camera": move(
        cam(P(-5.0, 3.75, -3.3), P(-5.4, 3.0, -4.1), 30),
        cam(P(-5.15, 3.6, -3.55), P(-5.4, 3.0, -4.1), 34), "in_out")},
    # Water cascading through the hatch into steam; deep in the bales, a red glow nobody can reach.
    "hold_steam": {"look": LOOK_SMOKE, "camera": move(
        cam(P(5.5, 3.6, 6.5), P(1.0, 4.0, 0.0), 24),
        cam(P(5.0, 3.2, 6.0), P(2.5, 1.4, 3.0), 26), "in_out")},
    # The shells go off: flashes and sparks among the crates, fire licking up.
    "hold_pops": {"look": LOOK_SMOKE, "shake": [{"t": W("l12a", "going"), "amount": 0.2}], "camera": move(
        cam(P(-6.0, 3.8, 6.8), P(1.0, 3.0, 0.0), 24),
        cam(P(-5.5, 3.6, 6.2), P(1.0, 3.2, 0.0), 24), "in_out")},
}

PLACE = {"gags": GAGS, "actors": [], "reveals": REVEALS, "shots": SHOTS}
