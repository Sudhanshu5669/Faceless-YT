"""The Parsi gentleman's front room in Girgaum (gags/flat.gd "flat_set").

Frame: floor y 0; the window wall at z -3 (window centred x 0.6, sill 0.9, head 3.45); the side wall the bar bursts
through at x -3.2 (hole at y 1.7, z -1.2); the round table at (0.2, 0, -0.6), top 0.76; he stands at (1.0, 0, -0.9)
reading by the window.
"""
from .common import W, frame, cam, move

P = frame("flat", 0.0)

LOOK_FLAT = {
    "base": "night_fog", "time": "16:10",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.0},
    "sun": {"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "sky": {"top": "#6a88b0", "horizon": "#e0c8a8", "clouds": 0.0, "stars": 0.0},
    "ambient": {"color": "#8a7a66", "energy": 0.35, "sky": 0.0},
    "fog": {"begin": 300, "end": 900, "curve": 1.6, "volumetric": 0.018, "color": "#e0c8a0", "anisotropy": 0.75, "length": 20},
    "glow": {"enabled": True, "intensity": 0.7, "bloom": 0.05, "threshold": 1.05},
    "ssao": True,
    "grade": {"contrast": 1.16, "saturation": 1.04, "vignette": 0.5, "grain": 0.04},
}
LOOK_EVENING = dict(LOOK_FLAT, time="19:30", ambient={"color": "#3a3028", "energy": 0.2, "sky": 0.0},
                    fog={"begin": 300, "end": 900, "curve": 1.6, "volumetric": 0.02, "color": "#c09060", "anisotropy": 0.6, "length": 20})

MAN = (1.0, 0.0, -0.9)
ACTORS = [
    {"id": "parsi", "character": "toon_parsi_gent", "at": P(*MAN), "keep_y": True, "facing": P(0.6, 0.0, -3.0), "action": "idle",
     "cues": [{"t": 0.0, "expression": "neutral"},
              {"t": W("l2b", "smashed", 0.0), "expression": "shocked", "facing": P(-3.2, 0.0, -1.2)},
              {"t": W("l2b", "home.", 0.0), "expression": "surprised", "facing": P(0.2, 0.0, -0.6)},
              {"t": W("l3a", "What", 0.0), "expression": "strain"},
              {"t": W("l3a", "nobody", 0.0), "expression": "thinking", "head": [10, 0, 0]},
              {"t": W("l3b", "first", 0.0), "expression": "nervous", "facing": P(0.6, 0.0, -3.0)},
              {"t": W("l22a", "And", 0.0), "expression": "thinking", "facing": P(0.2, 0.0, -0.6)},
              {"t": W("l22a", "Girgaum", 0.0), "expression": "determined", "facing": P(-2.0, 0.0, -1.6)}]},
]

GAGS = [{"id": "flat_set", "script": "gags/flat.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"man": "parsi", "burst": W("l2b", "smashed", -0.05), "land": W("l2b", "smashed", 0.38),
                    "lift": W("l3a", "What", -0.1), "dusk": {"shot": "flat_return"}}}]

SHOTS = {
    # The room from the far corner: he reads by the window in the low sun; on "smashed" the side wall bursts, the bar
    # flies across, thumps onto the table and skids; his newspaper drops.
    "bar_wall": {"look": LOOK_FLAT, "shake": [{"t": W("l2b", "smashed"), "amount": 0.3}], "camera": move(
        cam(P(2.6, 1.55, 2.4), P(-0.6, 1.25, -1.4), 24),
        cam(P(2.4, 1.5, 2.0), P(-0.4, 1.1, -1.2), 24), "in_out")},
    # Close, low across the table: he lifts the bar in both hands, heavy; it glints in the sun.
    "man_lift": {"look": LOOK_FLAT, "camera": move(
        cam(P(-0.25, 1.95, -0.2), P(0.9, 0.95, -0.9), 30),
        cam(P(-0.1, 1.9, -0.3), P(0.9, 1.0, -0.9), 32), "in_out")},
    # Behind him at the window, the bar in his hands, the black column over the rooftops: whip out toward it.
    "window_whip": {"look": LOOK_FLAT, "whip_out": "up", "camera": move(
        cam(P(1.9, 1.8, 0.8), P(0.4, 2.6, -12.0), 28),
        cam(P(1.6, 1.9, 0.2), P(0.4, 3.4, -12.0), 30), "in")},
    # Evening, lamp-lit: he holds the bar and makes up his mind.
    "flat_return": {"look": LOOK_EVENING, "camera": move(
        cam(P(-0.9, 1.35, -1.5), P(1.0, 1.3, -0.85), 30),
        cam(P(-0.7, 1.35, -1.45), P(1.0, 1.35, -0.85), 34), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
