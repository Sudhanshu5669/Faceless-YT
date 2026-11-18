"""A pol lane in old Ahmedabad at night (gags/amdavad_lane.gd, gag id "pol"): the hook (line 1) and the ending
(line 24). Frame: the lane runs along z, the auto at x 0.6 facing -z, the sodium lamp on the left wall.
"""
from .common import W, frame, cam, move

LANE_Z = 4000.0
P = frame("lane", LANE_Z)

LOOK = {
    "base": "night_fog", "time": "21:30", "ssao": True,
    "weather": {"fog": 0.0, "clouds": 0.08},
    "sun": {"energy": 0, "visible": False},
    "moon": {"energy": 0.06, "visible": False},
    "ambient": {"color": "#6c6f86", "energy": 0.1},
    "sky": {"top": "#050812", "horizon": "#2a2230", "stars": 0.9, "clouds": 0.08, "cloud_color": "#3a3446"},
    "fog": {"begin": 25, "end": 160, "color": "#2a2122", "volumetric": 0.018, "anisotropy": 0.55, "length": 40},
    "ground_fog": {"density": 0.0},
    "glow": {"enabled": True, "intensity": 0.8, "bloom": 0.06, "threshold": 1.05},
    "grade": {"contrast": 1.12, "saturation": 0.95, "vignette": 0.32, "grain": 0.05},
    "practical_lights": {"level": 0},
}

ACTORS = [
    {"id": "driver", "character": "toon_auto_driver", "at": P(0.6, 0.42, -0.05), "facing": P(0.6, 0.42, -9),
     "action": "sit", "keep_y": True, "cues": [
         {"t": 0.0, "expression": "deadpan"},
         {"t": W("l1a", "ten", 0.15), "expression": "side_eye"},
         {"t": W("l1b", "Mars", -0.15), "expression": "shocked", "head": [-35, 10, 0], "head_turn": 0.35},
         {"t": W("l1b", "seven", 0.1), "expression": "star_eyes", "head": [-40, 0, 0]},
         {"t": W("l24"), "expression": "deadpan", "head": [0, 0, 0]},
         {"t": W("l24", "seven"), "expression": "grin", "head": [-25, 0, 0]},
     ]},
]

GAGS = [{"id": "pol", "script": "gags/amdavad_lane.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"meter": {"start": W("l1a", "auto", -0.1), "land": W("l1a", "ten"), "to": 10},
                    "meter2": {"start": W("l24", "Not", -0.1), "land": W("l24", "seven"), "to": 7},
                    "streak": [W("l1b", "India", -0.1), W("l1b", "seven", 0.3)],
                    "streak2": [W("l24", "bad"), W("l24", edge="end", offset=0.4)]}},
]

REVEALS = [
    {"id": "per_km", "t": W("l1b", "Mars", 0.05), "until": W("l2a"), "at": P(-0.6, 7.0, 5.5), "size": 0.95,
     "counter": {"from": 10, "to": 7, "decimals": 0, "prefix": "₹", "suffix": " / KM", "land": W("l1b", "seven"),
                 "label": "TO MARS"}, "sound": "ding"},
    {"id": "per_km_end", "t": W("l24", "seven", -0.05), "at": P(0.2, 6.4, 5.5), "size": 0.95,
     "text": "₹7 / KM", "color": "#ffd84a", "enter": "pop", "sound": "ding"},
]

SHOTS = {
    "auto_meter": {"look": LOOK, "camera": move(
        cam(P(-0.02, 1.52, -0.08), "pol.meter", 50, {"strength": 0.5}),
        cam(P(-0.05, 1.5, -0.12), "pol.meter", 58, {"strength": 0.5}), "in_out")},
    "auto_overtake": {"look": LOOK, "camera": move(
        cam(P(1.05, 0.4, -3.6), P(0.5, 1.15, 0.0), 22),
        cam(P(1.05, 0.4, -3.6), P(0.2, 7.5, 5.5), 22), "in_out")},
    "auto_end": {"look": LOOK, "camera": move(
        cam(P(1.15, 0.45, -3.9), P(0.45, 1.6, 0.0), 22),
        cam(P(1.1, 0.42, -3.7), P(0.3, 5.0, 5.0), 22), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS, "reveals": REVEALS}
