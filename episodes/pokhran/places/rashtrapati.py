"""Rashtrapati Bhavan, New Delhi, July 2002 (gags/rashtrapati.gd, gag id "rashtrapati").

Frame: the foot of the great stair at z 0 (x 0), rising toward -z to the landing at y 4.8 (z -12); the colonnade at
z -19; the dome's centre at (0, 0, -34). Cameras stand at +z looking -z (the facade faces east: morning sun on it).

rashtrapati: "becomes the President of India.": low at the foot of the steps, the President's Bodyguard lining them
in scarlet with lances; Kalam in a dark bandhgala walks across the landing toward the doors; the camera cranes up the
facade to the dome and the tricolour on "President".
"""
from .common import W, frame, cam, move
from . import range as range_place

RB_Z = 57000.0
P = frame("bunker", RB_Z)     # the bunker bay (the set's spare anchors render nothing; see the handoff)

LANDING_Y = 4.8
STEPS_D = 12.0
STEP_N = 24

LOOK_RB = dict(range_place.LOOK_AFTERNOON, time="08:30",
               sun={"elevation": 28, "azimuth": 35, "color": "#ffe6c4", "energy": 3.0, "softness": 0.6,
                    "visible": False, "size": 1.2, "glow": 1.0, "shadows": True},
               sky={"top": "#6f95c8", "horizon": "#e4dccb", "clouds": 0.0},
               ambient={"color": "#b0a48e", "energy": 0.38, "sky": 0.6},
               fog={"begin": 80, "end": 1500, "curve": 1.6, "volumetric": 0.0})

# Kalam stands on the landing from never_noticed (he is on the analyst's TV) and walks in rashtrapati.
RB = [{"shot": "never_noticed", "offset": -0.1}, {"shot": "tech_day"}]


def step_y(z):
    """The top of the step at z (z between -12 and 0), or the landing."""
    if z <= -STEPS_D:
        return LANDING_Y
    if z >= 0:
        return 0.0
    i = int(-z / (STEPS_D / STEP_N))
    return round((LANDING_Y / STEP_N) * (i + 1), 3)


ACTORS = [
    {"id": "kalam_rb", "character": "toon_kalam_bandhgala", "at": P(0.0, LANDING_Y, -12.6), "keep_y": True,
     "facing": P(0.0, LANDING_Y, -20.0), "action": "idle", "shown": [RB],
     "route": {"via": [P(0.0, LANDING_Y, -16.5)], "gait": "walk", "start": {"shot": "rashtrapati", "offset": -0.3}},
     "cues": [{"t": 0.0, "expression": "happy"}]},
]
_GUARDS = []
for _k, _z in enumerate([-2.3, -5.3, -8.3, -11.3]):
    for _s in (-1.0, 1.0):
        _GUARDS.append((f"pbg_{_k}_{'l' if _s < 0 else 'r'}", _s * (3.2 + 0.15 * _k), _z))
for _id, _x, _z in _GUARDS:
    _y = step_y(_z)
    ACTORS.append({"id": _id, "character": "toon_pbg", "at": P(_x, _y, _z), "keep_y": True,
                   "facing": P(0.0, _y, _z), "action": "idle", "shown": [RB],
                   "cues": [{"t": 0.0, "expression": "determined"}]})

GAGS = [{"id": "rashtrapati", "script": "gags/rashtrapati.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"lances": [g[0] for g in _GUARDS], "flag": True}}]

SHOTS = {
    # Low at the foot of the steps between the bodyguard; Kalam crossing the landing above; on "President" the camera
    # cranes up the colonnade to the dome and the tricolour against the morning sky.
    "rashtrapati": {"look": LOOK_RB, "camera": {
        "from": cam(P(0.4, 1.0, 9.0), P(0.0, 5.6, -14.0), 24, {"strength": 0.06}),
        "to": cam(P(0.3, 10.0, 7.0), P(0.0, 36.0, -34.0), 24, {"strength": 0.04}),
        "ease": "in_out", "start": W("l19b", "President", -0.35), "end": W("l19b", "India.", 0.3)}},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
