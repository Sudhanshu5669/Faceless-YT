"""ISRO Satellite Centre, Bengaluru (gags/isro_lab.gd, gag id "isac"): the engineer's office at night and the
clean room (at gag x +40). Office frame: window wall at z +2, desk at z 1.3, the engineer's chair at z 0.55.
"""
from .common import W, frame, cam, move

LAB_Z = 12000.0
P = frame("lab", LAB_Z)


def CL(x, y, z):
    return P(x + 40.0, y, z)


LOOK = {
    "base": "night_fog", "time": "22:30", "ssao": True,
    "weather": {"fog": 0.0, "clouds": 0.0},
    "sun": {"energy": 0, "visible": False},
    "moon": {"elevation": 17, "azimuth": 9, "energy": 0.35, "color": "#a9c0ff", "visible": True, "size": 2.6,
             "glow": 0.5, "shadows": True},
    "ambient": {"color": "#6b7896", "energy": 0.12},
    "sky": {"top": "#04070f", "horizon": "#14203a", "stars": 1.2,
            "bodies": [{"kind": "planet", "elevation": 11, "azimuth": -11, "size": 0.32, "color": "#ff6b3d", "glow": 0.9}]},
    "fog": {"begin": 300, "end": 4000, "color": "#0c1424", "volumetric": 0.0},
    "ground_fog": {"density": 0.0},
    "glow": {"enabled": True, "intensity": 0.7, "bloom": 0.05, "threshold": 1.1},
    "grade": {"contrast": 1.08, "saturation": 0.95, "vignette": 0.3, "grain": 0.05},
    "practical_lights": {"level": 0},
}
CLEAN_LOOK = dict(LOOK, ambient={"color": "#dfe7f2", "energy": 0.35},
                  grade={"contrast": 1.04, "saturation": 0.95, "vignette": 0.22, "grain": 0.04},
                  glow={"enabled": True, "intensity": 0.5, "bloom": 0.03, "threshold": 1.3})

HEAD_UP = [-22, 0, 0]

ACTORS = [
    {"id": "hero_lab", "character": "toon_isro_eng", "at": P(0, 0, 0.55), "facing": P(0, 0, 9), "action": "sit",
     "cues": [
         {"t": 0.0, "expression": "thinking", "head": HEAD_UP},
         {"t": W("l2a", "ISRO"), "expression": "determined", "head": [-8, 0, 0]},
         {"t": W("l4"), "expression": "nervous", "head": HEAD_UP},
         {"t": W("l4", "Moon", 0.1), "expression": "sad", "head": [-26, -8, 0]},
         {"t": W("l5a"), "expression": "neutral", "head": [12, 0, 0]},
         {"t": W("l5a", "says", -0.1), "expression": "surprised", "head": [10, 0, 0]},
         {"t": W("l5a", "yes", 0.15), "expression": "cheer", "head": [4, 0, 0]},
         {"t": W("l5b"), "expression": "thinking", "head": [8, 18, 0]},
         {"t": W("l5c", "Miss"), "expression": "panic", "head": [0, 40, 0]},
         {"t": W("l6a"), "expression": "neutral", "head": [10, -14, 0]},
         {"t": W("l6a", "crore", 0.1), "expression": "nervous"},
         {"t": W("l6b", "Gravity", 0.15), "expression": "smug"},
         {"t": W("l8a"), "expression": "thinking", "head": [0, 0, 0]},
         {"t": W("l8a", "swing", -0.2), "expression": "scheming"},
         {"t": W("l23"), "expression": "happy", "head": HEAD_UP},
         {"t": W("l23", "auspicious"), "expression": "love", "head": HEAD_UP},
     ]},
    # The clean room: the hero and three technicians, each with a job.
    {"id": "hero_clean", "character": "toon_isro_eng_clean", "at": CL(1.6, 0, 1.3), "facing": CL(0, 1.2, 0),
     "action": "fix", "cues": [{"t": 0.0, "expression": "determined"}]},
    {"id": "tech_a", "character": "toon_cleanroom_a", "at": CL(-1.5, 0, 0.9), "facing": CL(0, 1, 0), "action": "interact",
     "cues": [{"t": 0.0, "expression": "determined"}]},
    {"id": "tech_b", "character": "toon_cleanroom_b", "at": CL(0.4, 0, -1.7), "facing": CL(0, 1, 0), "action": "fix",
     "cues": [{"t": 0.0, "expression": "thinking"}]},
    {"id": "tech_c", "character": "toon_cleanroom_c", "at": CL(-3.4, 0, 2.6), "facing": CL(-3.5, 0, 2.0), "action": "push",
     "cues": [{"t": 0.0, "expression": "neutral"}]},
]

GAGS = [{"id": "isac", "script": "gags/isro_lab.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"file": {"drop": W("l5a", "August", -0.3), "untie": W("l5a", "government", -0.1), "stamp": W("l5a", "yes")},
                    "orrery": W("l5b", "close", -0.2),
                    "calendar": [W("l5c", "wait", -0.1), W("l5c", "years", 0.2)],
                    "build": [W("l5d", offset=-0.1), W("l5d", "months", 0.25)],
                    "cash": W("l6a", "four", -0.15), "gravity": W("l6b", "Gravity", -0.05),
                    "gulel": {"t": W("l8a", "throw", 0.0), "actor": "hero_lab"},
                    "diya": W("l23")}},
]

REVEALS = [
    {"id": "months_count", "t": W("l5d", offset=-0.1), "until": W("l6a"), "at": CL(0, 4.25, 0.8), "size": 0.42,
     "counter": {"from": 15, "to": 0, "decimals": 0, "suffix": " MONTHS", "land": W("l5d", "months", 0.25),
                 "label": "TO LAUNCH"}, "sound": "ding"},
    {"id": "budget_count", "t": W("l6a", "four", -0.2), "until": W("l6b", edge="end", offset=0.4), "at": P(0.22, 1.4, 1.0),
     "size": 0.045, "counter": {"from": 0, "to": 450, "decimals": 0, "prefix": "₹", "suffix": " CRORE",
                                "land": W("l6a", "crore"), "label": "MARS ORBITER MISSION"}, "sound": "cash"},
]

DOF = {"strength": 0.35}
HEAD = {"anchor": "hero_lab.head"}

SHOTS = {
    "isro_window": {"look": LOOK, "camera": move(
        cam(P(0.2, 1.62, 4.4), P(0, 1.0, 0.6), 30, {"strength": 0.25}),
        cam(P(0.1, 1.5, 2.5), P(0, 0.98, 0.6), 30, {"strength": 0.3}), "in_out")},
    "moon_window": {"look": LOOK, "camera": move(
        cam(P(-0.36, 1.2, 0.2), {"sky": "moon"}, 40, {"strength": 0.5, "focus": 0.45}),
        cam(P(-0.33, 1.18, 0.26), {"sky": "moon"}, 46, {"strength": 0.5, "focus": 60.0}), "in_out")},
    "approval": {"look": LOOK, "camera": move(
        cam(P(0.05, 1.6, 0.72), P(0.12, 0.78, 1.12), 34, {"strength": 0.3}),
        cam(P(0.08, 1.48, 0.8), P(0.12, 0.8, 1.1), 36, {"strength": 0.3}), "in_out")},
    "orrery": {"look": LOOK, "camera": move(
        cam(P(-0.58, 1.12, 1.0), "isac.orrery", 45, {"strength": 0.5}),
        cam(P(-0.52, 1.08, 1.06), "isac.orrery", 50, {"strength": 0.5}), "in_out")},
    "calendar": {"look": LOOK, "camera": move(
        cam(P(-1.05, 1.5, 0.75), "isac.calendar", 35, {"strength": 0.35}),
        cam(P(-1.5, 1.55, 0.5), "isac.calendar", 35, {"strength": 0.35}), "in")},
    "cleanroom_build": {"look": CLEAN_LOOK, "camera": move(
        cam(CL(3.2, 2.3, 3.6), CL(0, 1.7, 0), 26), cam(CL(-2.8, 2.1, 3.6), CL(0, 1.8, 0), 26), "in_out")},
    "budget_stack": {"look": LOOK, "camera": move(
        cam(P(-0.38, 1.42, 0.3), P(0.55, 1.12, 1.2), 30, {"strength": 0.25}),
        cam(P(-0.33, 1.4, 0.36), P(0.55, 1.12, 1.2), 31, {"strength": 0.25}), "in_out")},
    "budget_gravity": {"look": LOOK, "shake": [{"t": W("l6b", "Gravity"), "amount": 0.35}], "camera": move(
        cam(P(-0.33, 1.4, 0.36), P(0.55, 1.12, 1.2), 31, {"strength": 0.25}),
        cam(P(-0.28, 1.38, 0.42), P(0.55, 1.1, 1.2), 32, {"strength": 0.25}), "in_out")},
    "gulel": {"look": LOOK, "camera": move(
        cam(P(0.12, 1.22, 1.72), {"anchor": "hero_lab.head", "offset": [0, -0.15, 0]}, 30, {"strength": 0.3}),
        cam(P(0.06, 1.18, 1.62), {"anchor": "hero_lab.head", "offset": [0, -0.15, 0]}, 32, {"strength": 0.3}), "in_out")},
    "window_mars": {"look": LOOK, "camera": move(
        cam(P(0.1, 1.48, 2.45), P(0, 1.0, 0.6), 30, {"strength": 0.3}),
        cam(P(0.2, 1.62, 4.4), P(0, 1.05, 0.6), 30, {"strength": 0.25}), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS, "reveals": REVEALS}
