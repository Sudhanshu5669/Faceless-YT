"""The US imagery analyst's office near Washington, 1998 (gags/analyst_room.gd, gag id "office_us").

Room frame: the desk against the front wall (z -2.2), top at y 0.62; the hero CRT screen centre at
(0, 1.02, -1.86) facing +z; the analyst sits at (0, 0, -0.62) facing -z; the wall TV at (0.55, 1.72, 2.05)
on the back wall; the window with blinds in the -x wall (frame right when looking +z).
"""
from .common import W, frame, cam, move
from . import lawn

DESK_Z = 3000.0
P = frame("desk", DESK_Z)

SCREEN = (0.0, 1.02, -1.86)

LOOK = {
    "base": "night_fog", "time": "05:50", "ssao": True,
    "weather": {"fog": 0.0, "clouds": 0.0},
    "sun": {"energy": 0, "visible": False}, "moon": {"energy": 0, "visible": False},
    "ambient": {"color": "#46506a", "energy": 0.12},
    "sky": {"top": "#04050a", "horizon": "#0a0c12", "stars": 0},
    "fog": {"begin": 1, "end": 30, "color": "#10141c", "volumetric": 0.02, "anisotropy": 0.5, "length": 12},
    "ground_fog": {"density": 0.0},
    "glow": {"enabled": True, "intensity": 0.8, "bloom": 0.08, "threshold": 1.0},
    "grade": {"contrast": 1.14, "saturation": 0.92, "vignette": 0.38, "grain": 0.06},
    "practical_lights": {"level": 0},
}

ANNOUNCED = W("l1b", "announced", -0.1)

ACTORS = [
    {"id": "analyst", "character": "toon_analyst", "at": P(0.25, 0, -0.62), "facing": P(0.1, 0, -30),
     "action": "sit", "keep_y": True, "cues": [
         {"t": 0.0, "expression": "sleepy"},
         {"t": ANNOUNCED, "expression": "shocked", "action": "sit_talk"},
         {"t": W("l1b", "it", 0.1), "expression": "panic"},
         {"t": W("l2a"), "expression": "nervous"},
     ]},
]

GAGS = [{"id": "office_us", "script": "gags/analyst_room.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"blast": [W("l1a", "blew", -0.05)],
                    "rewind": {"from": W("l3a", "Rewind"), "until": W("l3a", "1995.", 0.4)},
                    "knock": W("l2a", None, -0.35),
                    "tv": {"on": ANNOUNCED, "cam": lawn.TV_CAM, "look": lawn.TV_LOOK, "fov": 26.0}}}]

SX, SY, SZ = SCREEN
SHOTS = {
    # Over the sleeping analyst's shoulder, push in until the feed fills the frame as the ground blows up.
    "hook_feed": {"look": LOOK, "camera": move(
        cam(P(SX - 0.4, SY + 0.44, SZ + 1.95), P(SX + 0.02, SY - 0.02, SZ), 36, {"strength": 0.25}),
        cam(P(SX, SY, SZ + 0.5), P(SX, SY, SZ), 40), "out"),
        "shake": [{"t": W("l1a", "blew", 0.0), "amount": 0.55}]},
    # Reverse: from beside the monitor at the analyst asleep; the TV behind him flicks on; he jolts awake.
    "hook_analyst": {"look": LOOK, "camera": move(
        cam(P(-0.17, 0.9, -1.67), P(0.17, 1.4, 0.8), 16, {"strength": 0.12}),
        cam(P(-0.14, 0.94, -1.56), P(0.16, 1.48, 0.8), 18, {"strength": 0.15}), "in_out")},
    # Macro on the snow globe as the snow swirls.
    "snow_globe": {"look": LOOK, "camera": move(
        cam(P(0.42, 0.74, -1.18), "office_us.globe", 60, {"strength": 0.6}),
        cam(P(0.45, 0.72, -1.24), "office_us.globe", 70, {"strength": 0.7}), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
