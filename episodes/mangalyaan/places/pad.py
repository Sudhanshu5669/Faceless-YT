"""Satish Dhawan Space Centre, Sriharikota (gags/sriharikota.gd, gag id "shar"): PSLV-C25 on the First Launch
Pad, its afternoon launch (5 Nov 2013, 14:38 IST) and the launch control room (the week's delay).
Frame: the rocket at the origin, the umbilical tower at x +9.5, the sea toward +z; control room at x +900.
"""
from .common import W, frame, cam, move

PAD_Z = 19000.0
P = frame("pad", PAD_Z)


def CR(x, y, z):
    return P(x + 900.0, y, z)


def MC(x, y, z):
    """The Mission Control Centre hall (mission_control.gd in launch mode), far from the pad."""
    return P(x + 3000.0, y, z)


ROWS = [(-5.0, 0.0), (-2.2, 0.3), (0.6, 0.6)]


def seat(ri, x):
    z, fy = ROWS[ri]
    return MC(x, fy, z + 0.22)


LOOK = {
    "base": "day", "time": "14:30", "ssao": True,
    "weather": {"fog": 0.25, "clouds": 0.25},
    "sun": {"elevation": 52, "azimuth": 200, "energy": 2.4, "color": "#fff1d8", "shadows": True, "softness": 0.4},
    "ambient": {"color": "#a9bcd2", "energy": 0.45},
    "sky": {"top": "#4f86c6", "horizon": "#d9e2e6", "clouds": 0.25,
            "bodies": [{"kind": "planet", "elevation": 34, "azimuth": 108, "size": 0.9, "color": "#ff5a2a", "glow": 1.4}]},
    "fog": {"begin": 300, "end": 4000, "color": "#c9d3d8", "volumetric": 0.0},
    "ground_fog": {"density": 0.002, "height": 6.0, "falloff": 0.2, "color": "#d8dcdc"},
    "glow": {"enabled": True, "intensity": 0.6, "bloom": 0.04, "threshold": 1.2},
    "grade": {"contrast": 1.08, "saturation": 1.0, "vignette": 0.22, "grain": 0.04},
}
ROOM_LOOK = dict(LOOK, ambient={"color": "#8a95a8", "energy": 0.25},
                 grade={"contrast": 1.1, "saturation": 0.95, "vignette": 0.3, "grain": 0.05})

MCC_CAST = ["toon_isro_ctrl_b", "toon_isro_ctrl_e", "toon_isro_ctrl_a", "toon_isro_ctrl_h", "toon_isro_ctrl_f",
            "toon_isro_ctrl_c", "toon_isro_ctrl_g", "toon_isro_ctrl_d"]
MCC_SEATS = [(0, -4.4), (0, 0.0), (0, 4.4), (0, 6.6), (1, -6.6), (1, -2.2), (1, 2.2), (1, 4.4), (2, -3.3), (2, 1.1), (2, 3.3)]

ACTORS = [
    {"id": "hero_shar", "character": "toon_isro_eng", "at": seat(0, 2.2), "facing": MC(2.2, 0, -30), "action": "sit",
     "keep_y": True, "cues": [
         {"t": 0.0, "expression": "side_eye"},
         {"t": W("l9a", "week", 0.1), "expression": "deadpan"},
     ]},
] + [
    {"id": f"mcc_{k}", "character": MCC_CAST[k % len(MCC_CAST)], "at": seat(ri, x), "facing": MC(x, 0, -30),
     "action": ["sit", "sit_talk", "sit"][k % 3], "keep_y": True,
     "cues": [{"t": 0.0, "expression": ["nervous", "deadpan", "thinking", "side_eye"][k % 4]}]}
    for k, (ri, x) in enumerate(MCC_SEATS)
]

GAGS = [{"id": "shar", "script": "gags/sriharikota.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"arc": [W("l7", "throw", -0.3), W("l7", "Mars", 0.2)],
                    "launch": W("l10a", "2013", -0.3),
                    "hold": [W("l9a"), W("l9a", edge="end")],
                    }},
        {"id": "mcc", "script": "gags/mission_control.gd", "t": 0, "at": MC(0, 0, 0),
         "params": {"mode": "launch", "header": "PSLV-C25 · MARS ORBITER MISSION", "hold": [W("l9a"), W("l9a", edge="end")]}}]

SHOTS = {
    "pslv_pad": {"look": LOOK, "camera": move(
        cam(P(14, 1.8, 26), P(0, 22, 0), 22), cam(P(48, 4.0, 120), P(-60, 80, 40), 18), "in_out")},
    "countdown_wait": {"look": ROOM_LOOK, "camera": move(
        cam(MC(3.5, 1.4, -3.6), MC(0.6, 2.9, -9.0), 26, {"strength": 0.2}),
        cam(MC(3.3, 1.35, -3.9), MC(0.4, 3.1, -9.0), 28, {"strength": 0.2}), "in_out")},
    "launch": {"look": LOOK, "camera": move(
        cam(P(55, 3, 120), "shar.base", 45), cam(P(55, 3, 120), "shar.rocket", 45), "in")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
