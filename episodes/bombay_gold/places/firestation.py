"""National Fire Service Day today, at a Mumbai fire station (gags/firestation.gd).

Frame: the memorial at the origin facing +z; two rows of firefighters at z +3.2 and +4.6 facing -z; the station front at
z -12 with its bays and engines; the flag at (9.5, 12.8, -3).
"""
from .common import W, frame, cam, move

P = frame("firestation", 0.0)

LOOK_DAY = {
    "base": "day", "time": "09:00",
    "weather": {"fog": 0.0, "clouds": 0.0, "wind": 0.4},
    "sun": {"elevation": 32, "azimuth": 120, "color": "#fff0d8", "energy": 2.1, "softness": 0.6, "visible": True,
            "size": 1.2, "glow": 1.3, "shadows": True},
    "sky": {"top": "#4f86c6", "horizon": "#d8dcd8", "clouds": 0.0},
    "ambient": {"color": "#a0a4a8", "energy": 0.36, "sky": 0.55},
    "fog": {"begin": 80, "end": 1500, "curve": 1.4, "volumetric": 0.003, "color": "#d0d4d6", "anisotropy": 0.6, "length": 200},
    "glow": {"enabled": True, "intensity": 0.45, "bloom": 0.03, "threshold": 1.3},
    "ssao": True,
    "grade": {"contrast": 1.14, "saturation": 1.04, "vignette": 0.42, "grain": 0.035},
}

ACTORS = []
for _i in range(16):
    _side, _k = (-1 if _i < 8 else 1), _i % 8
    _x, _z = _side * (2.6 + (_k % 2) * 1.1), 2.2 + (_k // 2) * 1.3
    ACTORS.append({"id": f"ff_{_i}", "character": "toon_fireman_today", "at": P(_x, 0.0, _z), "keep_y": True,
                   "facing": P(0.0, 0.0, _z), "action": "idle_formal",
                   "cues": [{"t": 0.0, "expression": "determined"}, {"t": W("l21c", "National", 0.2), "expression": "sad"}]})

GAGS = [{"id": "fs_set", "script": "gags/firestation.gd", "t": 0, "at": P(0, 0, 0), "params": {"salute": W("l21c", "marks", 0.0)}}]

SHOTS = {
    # Every April 14th: the memorial with its flame and marigold wreaths, the station and the flag behind; crane down.
    "fire_day": {"look": LOOK_DAY, "camera": move(
        cam(P(0.6, 5.5, 12.5), P(0.0, 3.2, -1.0), 26),
        cam(P(0.4, 2.2, 9.5), P(0.0, 2.6, -1.0), 26), "in_out")},
    # Along the rows: the firefighters salute together.
    "fire_salute": {"look": LOOK_DAY, "camera": move(
        cam(P(-0.9, 1.6, 9.0), P(-3.0, 1.5, 3.0), 30),
        cam(P(-0.8, 1.6, 8.2), P(-3.0, 1.55, 3.0), 32), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
