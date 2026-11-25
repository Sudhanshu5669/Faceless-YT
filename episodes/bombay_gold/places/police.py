"""A Bombay police station on the evening of 14 April 1944, and the relief fund box outside (gags/police.gd).

Frame: the counter along x at z -1.0 (top 1.05); the gentleman at z +0.4 facing -z; the inspector behind at z -1.9
facing +z; outside, the relief table at (12, 0, -1) with the RELIEF FUND banner above (y 2.4).
"""
from .common import W, frame, cam, move

P = frame("police", 0.0)

LOOK_POLICE = {
    "base": "night_fog", "time": "19:40",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.0},
    "sun": {"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "sky": {"top": "#0e1220", "horizon": "#3a2a2a", "clouds": 0.0, "stars": 0.0},
    "ambient": {"color": "#4a4038", "energy": 0.26, "sky": 0.0},
    "fog": {"begin": 300, "end": 900, "curve": 1.6, "volumetric": 0.015, "color": "#d8b890", "anisotropy": 0.6, "length": 24},
    "glow": {"enabled": True, "intensity": 0.75, "bloom": 0.06, "threshold": 1.05},
    "ssao": True,
    "grade": {"contrast": 1.18, "saturation": 1.04, "vignette": 0.5, "grain": 0.04},
}

ACTORS = [
    {"id": "parsi_p", "character": "toon_parsi_gent", "at": P(0.2, 0.0, 0.45), "keep_y": True, "facing": P(0.2, 0.0, -2.0), "action": "idle",
     "shown": [[{"shot": "police_desk"}, {"shot": "relief_box"}]],
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": W("l23a", "reward", 0.0), "expression": "surprised"},
              {"t": W("l23a", "rupees.", 0.0), "expression": "thinking"}]},
    {"id": "inspector", "character": "toon_inspector_1944", "at": P(0.6, 0.6, -1.95), "keep_y": True, "facing": P(0.5, 0.0, 1.0),
     "action": "idle", "cues": [{"t": 0.0, "expression": "deadpan"}, {"t": W("l22b", "police.", 0.0), "expression": "shocked"},
                                {"t": W("l23a", "reward", 0.0), "expression": "happy"}]},
    {"id": "constable", "character": "toon_dockworker_b", "at": P(-2.2, 0.0, -2.6), "keep_y": True, "facing": P(0.2, 0.0, 0.0),
     "action": "idle", "cues": [{"t": 0.0, "expression": "neutral"}, {"t": W("l22b", "police.", 0.1), "expression": "star_eyes"}]},
    {"id": "parsi_out", "character": "toon_parsi_gent", "at": P(14.6, 0.0, 0.6), "keep_y": True, "facing": P(12.0, 0.0, 0.6),
     "action": "idle", "shown": [[{"shot": "relief_box"}, {"shot": "dredger_2011"}]],
     "route": {"via": [P(12.75, 0.0, 0.55)], "gait": "walk", "speed": 1.0, "then_facing": P(12.0, 0.0, 1.8)},
     "cues": [{"t": 0.0, "expression": "happy"}]},
    {"id": "volunteer", "character": "toon_market_woman_b", "at": P(13.4, 0.0, -0.9), "keep_y": True, "facing": P(12.4, 0.0, 0.6),
     "action": "idle", "shown": [[{"shot": "relief_box"}, {"shot": "dredger_2011"}]],
     "cues": [{"t": 0.0, "expression": "sad"}, {"t": W("l23b", "relief", 0.2), "expression": "love"}]},
]

GAGS = [{"id": "police_set", "script": "gags/police.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"man": "parsi_p", "inspector": "inspector", "place": W("l22b", "police.", -0.3),
                    "write": W("l23a", "reward", -0.2), "hand": W("l23a", "rupees.", -0.3), "drop": W("l23b", "relief", 0.1)}}]

REVEALS = [
    {"id": "n_999", "t": W("l23a", offset=0.05), "until": {"shot": "relief_box"}, "at": P(0.95, 1.08, -0.8), "size": 0.11,
     "counter": {"from": 0, "to": 999, "prefix": "Rs ", "land": W("l23a", "ninety-nine", 0.15), "label": "REWARD"}, "sound": "ding"},
]

SHOTS = {
    # Across the counter: he sets the gold bar down in front of the sub-inspector, whose jaw drops.
    "police_desk": {"look": LOOK_POLICE, "camera": move(
        cam(P(-1.1, 1.3, 2.0), P(0.4, 1.4, -1.6), 26),
        cam(P(-0.95, 1.3, 1.7), P(0.4, 1.4, -1.6), 28), "in_out")},
    # Over the inspector's shoulder: he writes the cheque and hands it across.
    "cheque_999": {"look": LOOK_POLICE, "camera": move(
        cam(P(1.5, 1.35, 0.3), P(0.55, 1.25, -1.6), 30),
        cam(P(1.35, 1.35, 0.1), P(0.55, 1.25, -1.6), 32), "in_out")},
    # Outside under the lamp: he walks to the relief table and drops the cheque into the box.
    "relief_box": {"look": LOOK_POLICE, "camera": move(
        cam(P(13.0, 1.6, 3.8), P(12.4, 1.75, -0.4), 26),
        cam(P(13.0, 1.55, 3.4), P(12.4, 1.7, -0.4), 28), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "reveals": REVEALS, "shots": SHOTS}
