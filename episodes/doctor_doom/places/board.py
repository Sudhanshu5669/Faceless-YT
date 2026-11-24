"""Marvel Studios, a boardroom at night (gags/boardroom.gd, gag id "board_set").

Frame: the plan wall at z -6 (the Kang card at (0, 2.75)); the table along x 0 from z -4.3 to 2.5; Feige at the wall at
(0.55, 0, -4.9). Cameras at +z looking -z.

board_plan:     "Marvel had built its next saga around one villain: Kang."  down the table to the plan wall; lands on
                the Kang card on "Kang.".
board_news:     "Then, in December 2023, the actor who played him was convicted of assault and harassment."  Feige turns
                from the wall, the news on his face; the real headline (Euronews/AP, 19 Dec 2023) as a 2D card (HyperFrames).
board_collapse: "Marvel dropped him the same day. And the whole plan came down."  he tears the Kang card off on
                "dropped"; on "came down" the cards rain off the wall and the wall falls.
"""
from .common import W, frame, cam, move

P = frame("board", 40000.0)   # far from the other places

LOOK_BOARD = {
    "base": "night_fog", "time": "23:00",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.0},
    "sun": {"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "sky": {"top": "#04060a", "horizon": "#0b1220", "clouds": 0.0, "stars": 0.0,
            "panorama": "incoming/polyhaven_doom/hdris/modern_buildings_night_4k.hdr", "panorama_energy": 0.55,
            "panorama_yaw": 90},
    "ambient": {"color": "#202838", "energy": 0.12, "sky": 0.0},
    "fog": {"begin": 400, "end": 3000, "curve": 1.8, "volumetric": 0.0},
    "glow": {"enabled": True, "intensity": 0.7, "bloom": 0.04, "threshold": 1.1},
    "ssao": True,
    "grade": {"contrast": 1.18, "saturation": 0.98, "vignette": 0.45, "grain": 0.04},
}

PULL = W("k3", "dropped", 0.0)
COLLAPSE = W("k3", "came", 0.0)

ACTORS = [
    {"id": "feige", "character": "toon_feige", "at": P(0.75, 0, -4.85), "facing": P(0.0, 0, -6.0), "action": "idle",
     "cues": [{"t": 0.0, "expression": "happy"},
              {"t": W("k1", "Kang.", 0.0), "expression": "smug"},
              {"t": W("k2", "December", 0.0), "facing": P(0.75, 0, 2.0), "expression": "surprised"},
              {"t": W("k2", "convicted", 0.0), "expression": "shocked"},
              {"t": W("k3", "Marvel", 0.0), "facing": P(0.0, 0, -6.0), "expression": "determined"},
              {"t": COLLAPSE, "facing": P(0.75, 0, 2.0), "expression": "panic"}]},
]

GAGS = [
    {"id": "board_set", "script": "gags/boardroom.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"pull": {"actor": "feige", "t": PULL}, "collapse": COLLAPSE}},
]

SHOTS = {
    # From the head of the table, down its length under the pendant lamps to the plan wall; Feige admiring it; a push
    # that lands on the Kang card.
    "board_plan": {"look": LOOK_BOARD, "camera": move(
        cam(P(0.2, 1.55, 3.2), P(0.0, 1.9, -6.0), 28, {"strength": 0.08}),
        cam(P(0.3, 1.9, -1.4), P(0.0, 2.55, -6.0), 32, {"strength": 0.1}), "in_out")},
    # Feige turns from the wall to us; the wall of titles soft behind him.
    "board_news": {"look": LOOK_BOARD, "camera": move(
        cam(P(1.6, 1.3, -2.6), P(0.75, 1.15, -4.85), 40, {"strength": 0.16}),
        cam(P(1.45, 1.28, -2.9), P(0.75, 1.15, -4.85), 40, {"strength": 0.18}), "in_out")},
    # Wide from the table: the tear, then the cards rain and the wall comes down.
    "board_collapse": {"look": LOOK_BOARD, "duration": {"fit": True, "min": 1.0, "tail": 1.8}, "shake": [{"t": W("k3", "down.", 0.25), "amount": 0.18}], "camera": move(
        cam(P(-1.2, 1.5, -1.2), P(0.2, 1.8, -6.0), 26, {"strength": 0.06}),
        cam(P(-1.4, 1.45, -0.6), P(0.2, 1.6, -6.0), 26, {"strength": 0.06}), "out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
