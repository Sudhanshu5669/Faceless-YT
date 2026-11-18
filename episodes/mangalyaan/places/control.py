"""ISTRAC Mission Operations Complex, Bengaluru (gags/mission_control.gd, gag id "mox").

Room frame: the screen wall at z -9, rows at z -5 / -2.2 / 0.6 (floors 0 / 0.3 / 0.6), the gallery at z 3.4+
on a 1.3 m platform. Controllers face -Z.
"""
from .common import W, frame, cam, move

CTRL_Z = 26000.0
P = frame("control", CTRL_Z)

ROWS = [(-5.0, 0.0), (-2.2, 0.3), (0.6, 0.6)]
SEATS = [[-6.6, -4.4, -2.2, 0.0, 2.2, 4.4, 6.6], [-6.6, -4.4, -2.2, 0.0, 2.2, 4.4, 6.6], [-5.5, -3.3, -1.1, 1.1, 3.3, 5.5]]
CAST = ["toon_isro_ctrl_a", "toon_isro_ctrl_b", "toon_isro_ctrl_c", "toon_isro_ctrl_d", "toon_isro_ctrl_e",
        "toon_isro_ctrl_f", "toon_isro_ctrl_g", "toon_isro_ctrl_h"]
HERO_SEAT = (0, 4)   # row 1, x 2.2: by the command key

LOOK = {
    "base": "night_fog", "time": "05:30", "ssao": True,
    "weather": {"fog": 0.0, "clouds": 0.0},
    "sun": {"energy": 0, "visible": False}, "moon": {"energy": 0, "visible": False},
    "ambient": {"color": "#5d6b88", "energy": 0.3},
    "sky": {"top": "#05070c", "horizon": "#090c14", "stars": 0},
    "fog": {"begin": 2, "end": 60, "color": "#0f141e", "volumetric": 0.012, "anisotropy": 0.4, "length": 30},
    "ground_fog": {"density": 0.0},
    "glow": {"enabled": True, "intensity": 0.75, "bloom": 0.05, "threshold": 1.1},
    "grade": {"contrast": 1.1, "saturation": 0.95, "vignette": 0.32, "grain": 0.05},
    "practical_lights": {"level": 0},
}

ERUPT = W("l17c", "First", -0.15)
LOST = W("l15a", "watch", -0.2)
BACK = W("l17a", "comes", -0.1)


def seat_point(ri, x):
    z, fy = ROWS[ri]
    return P(x, fy, z + 0.22)


def build_cast():
    actors = []
    n = 0
    for ri, xs in enumerate(SEATS):
        for si, x in enumerate(xs):
            if (ri, si) == HERO_SEAT:
                continue
            ch = CAST[(n * 3 + ri) % len(CAST)]
            aid = f"ctrl_{ri}_{si}"
            jump = (n % 3 == 0)
            cues = [
                {"t": 0.0, "expression": "thinking"},
                {"t": W("l13b", "fires", 0.2 + 0.03 * (n % 6)), "expression": "happy"},
                {"t": W("l14a"), "expression": "determined"},
                {"t": W("l15a", "watch", 0.1 + 0.03 * (n % 6)), "expression": "nervous"},
                {"t": W("l16", "room", 0.05 * (n % 5)), "expression": "nervous", "hands": "chest" if n % 2 == 0 else "face"},
                {"t": W("l17a", "comes", 0.15 + 0.03 * (n % 4)), "expression": "shocked", "hands": "none"},
                {"t": W("l17c", "First", -0.1 + 0.05 * (n % 6)), "action": "jump" if jump else "stand_up",
                 "expression": "cheer" if n % 2 else "laugh"},
            ]
            if not jump:
                cues.append({"t": W("l17c", "Asia", 0.1 + 0.05 * (n % 4)), "action": "dance" if n % 4 == 1 else "call_out",
                             "expression": "cheer"})
            else:
                cues.append({"t": W("l17c", "country", 0.05 * (n % 3)), "action": "jump", "expression": "star_eyes"})
            actors.append({"id": aid, "character": ch, "at": seat_point(ri, x), "facing": P(x, 0, -30),
                           "action": "sit", "keep_y": True, "cues": cues})
            n += 1
    hx = SEATS[HERO_SEAT[0]][HERO_SEAT[1]]
    actors.append({"id": "hero_mox", "character": "toon_isro_eng", "at": seat_point(0, hx), "facing": P(hx, 0, -30),
                   "action": "sit", "keep_y": True, "cues": [
                       {"t": 0.0, "expression": "sleepy"},
                       {"t": W("l11b", "six", 0.0), "expression": "sleepy"},
                       {"t": W("l13a"), "expression": "determined"},
                       {"t": W("l13a", "wake", -0.4), "expression": "nervous"},
                       {"t": W("l13b", "fires", 0.15), "expression": "laugh"},
                       {"t": W("l14a"), "expression": "determined"},
                       {"t": W("l15a", "watch"), "expression": "nervous"},
                       {"t": W("l16", "room"), "expression": "nervous", "hands": "chest"},
                       {"t": W("l17a", "signal", 0.1), "expression": "shocked", "hands": "none"},
                       {"t": W("l17b", "orbit", -0.1), "expression": "star_eyes"},
                       {"t": ERUPT, "action": "jump", "expression": "cheer"},
                       {"t": W("l17c", "country"), "action": "jump", "expression": "crying"},
                   ]})
    # The gallery: the Prime Minister and the ISRO chairman, side by side behind the glass.
    actors.append({"id": "modi", "character": "toon_modi", "at": P(-0.45, 1.3, 4.35), "facing": P(-0.45, 1.3, -30),
                   "action": "idle", "keep_y": True, "cues": [
                       {"t": 0.0, "expression": "neutral"},
                       {"t": W("l16", "room"), "expression": "thinking", "hands": "chest"},
                       {"t": W("l17a", "comes", 0.2), "expression": "surprised", "hands": "none"},
                       {"t": ERUPT, "expression": "happy"},
                       {"t": W("l17c", "country", -0.6), "facing": "radhakrishnan", "turn": 0.4, "expression": "laugh"},
                   ]})
    actors.append({"id": "radhakrishnan", "character": "toon_radhakrishnan", "at": P(0.45, 1.3, 4.35),
                   "facing": P(0.45, 1.3, -30), "action": "fold_arms", "keep_y": True, "cues": [
                       {"t": 0.0, "expression": "nervous"},
                       {"t": W("l16", "room"), "expression": "nervous", "action": "idle", "hands": "face"},
                       {"t": W("l17a", "comes", 0.2), "expression": "shocked", "hands": "none"},
                       {"t": ERUPT, "expression": "cheer"},
                       {"t": W("l17c", "country", -0.6), "facing": "modi", "turn": 0.4, "expression": "crying"},
                   ]})
    return actors


GAGS = [
    {"id": "mox", "script": "gags/mission_control.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"lost": LOST, "static": [W("l15a", "watch", 0.3), BACK], "back": BACK, "erupt": ERUPT,
                "key": {"t": W("l13a", "wake"), "actor": "hero_mox"},
                "hug": {"t": W("l17c", "try", -0.45), "a": "modi", "b": "radhakrishnan"},
                }},
]

SHOTS = {
    "test_fire_key": {"look": LOOK, "camera": move(
        cam(P(3.15, 0.98, -5.45), P(2.05, 0.78, -5.1), 34, {"strength": 0.35}),
        cam(P(3.0, 0.95, -5.4), P(2.05, 0.74, -5.15), 38, {"strength": 0.4}), "in_out")},
    "room_static": {"look": LOOK, "camera": move(
        cam(P(0.6, 1.9, -1.4), "mox.screen", 30), cam(P(0.4, 2.2, -3.4), "mox.screen", 30), "in_out")},
    "room_waits": {"look": LOOK, "camera": move(
        cam(P(-4.5, 1.55, -6.7), P(-3.0, 0.95, -4.8), 30, {"strength": 0.3}),
        cam(P(3.8, 1.55, -6.7), P(2.6, 0.95, -4.8), 30, {"strength": 0.3}), "in_out")},
    "signal_back": {"look": LOOK, "camera": move(
        cam(P(5.2, 3.6, -6.2), P(5.6, 3.9, -9), 40), cam(P(5.4, 3.75, -6.9), P(5.6, 3.9, -9), 40), "out")},
    "room_erupts": {"look": LOOK, "camera": move(
        cam(P(-5.0, 2.5, -7.8), P(0, 1.1, -1.5), 22),
        cam(P(0.15, 2.2, 1.0), P(0, 2.1, 4.35), 34, {"strength": 0.2}), "in_out")},
}

PLACE = {"gags": GAGS, "actors": build_cast(), "shots": SHOTS, "reveals": []}
