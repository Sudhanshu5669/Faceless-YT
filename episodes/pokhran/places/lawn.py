"""The Prime Minister's residence lawn, New Delhi, evening of 11 May 1998 (gags/pm_lawn.gd, gag id "lawn_pm").

Frame: the lectern at the origin facing +z, top at 0.92; Vajpayee stands at (0, 0, -0.42) facing +z.
The press line is at z +2.5..3.5. TV_CAM / TV_LOOK: the news camera whose picture plays on the analyst's TV.
"""
from .common import W, frame, cam, move

LAWN_Z = 6000.0
P = frame("lawn", LAWN_Z)

TV_CAM = P(0.35, 1.3, 2.6)
TV_LOOK = P(0.0, 1.08, -0.42)

ACTORS = [
    {"id": "vajpayee", "character": "toon_vajpayee", "at": P(0, 0, -0.42), "facing": P(0.2, 0, 3),
     "action": "talk", "cues": [{"t": 0.0, "expression": "determined"}]},
]

GAGS = [{"id": "lawn_pm", "script": "gags/pm_lawn.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"flashes": [W("l1b", "announced", 0.05 + 0.27 * i) for i in range(6)]}}]

SHOTS = {}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
