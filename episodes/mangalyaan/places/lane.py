"""Old Ahmedabad at night (gags/amdavad_lane.gd, gag id "pol"): a busy Manek Chowk-style market street, the hook.
Shot 1 (hook_street): the auto weaves in through the evening crowd and brakes at the camera.
Shot 2 (auto_meter): the meter lands on ₹10. (Shot 3, the same auto in space, is in places/space.py.)
Frame: the street runs along z (9.2 m between the house fronts), the auto stops at x 0.9, z 0, nose toward -z.
"""
from .common import W, frame, cam, move

LANE_Z = 4000.0
P = frame("lane", LANE_Z)

LOOK = {
    "base": "night_fog", "time": "21:30", "ssao": True,
    "weather": {"fog": 0.0, "clouds": 0.08},
    "sun": {"energy": 0, "visible": False},
    "moon": {"energy": 0.06, "visible": False},
    "ambient": {"color": "#7a7690", "energy": 0.16},
    "sky": {"top": "#050812", "horizon": "#2a2230", "stars": 0.9, "clouds": 0.08, "cloud_color": "#3a3446"},
    "fog": {"begin": 25, "end": 160, "color": "#2a2122", "volumetric": 0.02, "anisotropy": 0.55, "length": 40},
    "ground_fog": {"density": 0.0},
    "glow": {"enabled": True, "intensity": 0.85, "bloom": 0.07, "threshold": 1.0},
    "grade": {"contrast": 1.12, "saturation": 1.0, "vignette": 0.3, "grain": 0.05},
    "practical_lights": {"level": 0},
}

DRIVE = [W("l1a1", offset=-0.35), W("l1a2", offset=-0.05)]

ACTORS = [
    # The driver: the gag moves him with the auto.
    {"id": "driver", "character": "toon_auto_driver", "at": P(0.9, 0.42, 0.05), "facing": P(0.9, 0.42, 9),
     "action": "sit", "keep_y": True, "cues": [
         {"t": 0.0, "expression": "determined"},
         {"t": W("l1a2", "costs"), "expression": "deadpan", "head": [0, 25, 0]},
         {"t": W("l1a2", "ten", 0.1), "expression": "smug", "head": [0, 30, 0]},
     ]},
    # The market: vendors at their carts, people with somewhere to be.
    {"id": "vendor_a", "character": "toon_market_vendor", "at": P(-3.0, 0, -3.0), "facing": P(0, 0, -3.0), "action": "interact",
     "cues": [{"t": 0.0, "expression": "happy"}]},
    {"id": "vendor_b", "character": "toon_market_vendor_b", "at": P(3.0, 0, -8.5), "facing": P(0, 0, -8.5), "action": "interact",
     "cues": [{"t": 0.0, "expression": "grin"}]},
    {"id": "eater_a", "character": "toon_market_man", "at": P(-1.9, 0, -2.4), "facing": P(-3.0, 0, -3.0), "action": "eat",
     "cues": [{"t": 0.0, "expression": "laugh"}]},
    {"id": "eater_b", "character": "toon_market_woman", "at": P(-1.9, 0, -3.6), "facing": P(-3.0, 0, -3.0), "action": "talk",
     "cues": [{"t": 0.0, "expression": "happy"}]},
    {"id": "eater_c", "character": "toon_market_elder", "at": P(2.0, 0, -9.0), "facing": P(3.0, 0, -8.5), "action": "eat",
     "cues": [{"t": 0.0, "expression": "neutral"}]},
    {"id": "walker_a", "character": "toon_market_woman_b", "at": P(3.4, 0, 2.0), "facing": P(3.4, 0, -20), "action": "idle",
     "route": {"via": [P(3.2, 0, -14)], "gait": "walk"}, "cues": [{"t": 0.0, "expression": "neutral"}]},
    {"id": "walker_b", "character": "toon_market_kid", "at": P(-3.4, 0, -16), "facing": P(-3.4, 0, 5), "action": "idle",
     "route": {"via": [P(-3.0, 0, 3.0)], "gait": "jog"}, "cues": [{"t": 0.0, "expression": "laugh"}]},
    {"id": "walker_c", "character": "toon_market_man", "at": P(-2.6, 0, -9), "facing": P(-2.6, 0, 5), "action": "phone",
     "route": {"via": [P(-2.7, 0, 1.0)], "gait": "walk"}, "cues": [{"t": 0.0, "expression": "deadpan"}]},
    {"id": "walker_d", "character": "toon_market_woman", "at": P(2.4, 0, -20), "facing": P(2.4, 0, 0), "action": "idle",
     "route": {"via": [P(2.6, 0, -4.0)], "gait": "walk"}, "cues": [{"t": 0.0, "expression": "happy"}]},
]

GAGS = [{"id": "pol", "script": "gags/amdavad_lane.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"meter": {"start": W("l1a2", "costs", -0.25), "land": W("l1a2", "ten"), "to": 10},
                    "drive_in": DRIVE, "driver": "driver"}}]

SHOTS = {
    "hook_street": {"look": LOOK, "shake": [{"t": W("l1a2", offset=-0.08), "amount": 0.12}], "camera": move(
        cam(P(2.1, 0.55, 4.6), "pol.auto", 32, {"strength": 0.2}),
        cam(P(1.95, 0.6, 3.9), "pol.auto", 30, {"strength": 0.2}), "out")},
    "auto_meter": {"look": LOOK, "camera": move(
        cam(P(1.62, 1.52, -0.3), P(1.25, 1.2, 0.55), 40, {"strength": 0.4, "focus": 0.95}),
        cam(P(1.58, 1.48, -0.18), P(1.25, 1.2, 0.55), 46, {"strength": 0.45, "focus": 0.82}), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
