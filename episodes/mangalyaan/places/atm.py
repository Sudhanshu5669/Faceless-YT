"""An ATM in an Indian market, November 2016 (gags/atm_market.gd, gag id "atm_kiosk"), line 22: the new ₹2,000
note carries a Mangalyaan motif on its back (RBI). Frame: the kiosk front at z 0, the ATM slot at (0.1, 1.05, -1.06).
"""
from .common import W, frame, cam, move

ATM_Z = 63000.0
P = frame("atm", ATM_Z)

LOOK = {
    "base": "night_fog", "time": "20:30", "ssao": True,
    "weather": {"fog": 0.0, "clouds": 0.08},
    "sun": {"energy": 0, "visible": False}, "moon": {"energy": 0, "visible": False},
    "ambient": {"color": "#707a90", "energy": 0.2},
    "sky": {"top": "#05070d", "horizon": "#1b1a24", "stars": 0.3, "clouds": 0.08},
    "fog": {"begin": 40, "end": 400, "color": "#1a1614", "volumetric": 0.0},
    "ground_fog": {"density": 0.0},
    "glow": {"enabled": True, "intensity": 0.75, "bloom": 0.06, "threshold": 1.1},
    "grade": {"contrast": 1.1, "saturation": 1.0, "vignette": 0.3, "grain": 0.05},
    "practical_lights": {"level": 0},
}

ACTORS = [
    {"id": "atm_user", "character": "toon_atm_customer", "at": P(0.25, 0, -0.3), "facing": P(0.1, 0, -9), "action": "interact",
     "cues": [{"t": 0.0, "expression": "neutral"}, {"t": W("l22", "picture"), "expression": "star_eyes"}]},
    {"id": "queue_1", "character": "toon_isro_ctrl_g", "at": P(2.2, 0, 1.2), "facing": P(0.2, 0, 0.3), "action": "phone",
     "cues": [{"t": 0.0, "expression": "deadpan"}]},
    {"id": "queue_2", "character": "toon_isro_ctrl_c", "at": P(3.2, 0, 1.5), "facing": P(0.2, 0, 0.3), "action": "fold_arms",
     "cues": [{"t": 0.0, "expression": "side_eye"}]},
    {"id": "queue_3", "character": "toon_isro_ctrl_f", "at": P(4.2, 0, 1.6), "facing": P(0.2, 0, 0.3), "action": "idle",
     "cues": [{"t": 0.0, "expression": "sleepy"}]},
]

GAGS = [{"id": "atm_kiosk", "script": "gags/atm_market.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"note": {"out": W("l22", "picture", -0.2), "flip": W("l22", "two-thousand-rupee", -0.4)}}}]

SHOTS = {
    "atm_note": {"look": LOOK, "camera": move(
        cam(P(-0.95, 1.45, -0.55), "atm_kiosk.slot", 32, {"strength": 0.35}),
        cam(P(-0.8, 1.35, -0.62), "atm_kiosk.note", 40, {"strength": 0.4}), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
