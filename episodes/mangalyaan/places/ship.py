"""SCI Nalanda in a South Pacific storm (gags/pacific_ship.gd, gag id "nalanda"), line 9: bad weather delayed its
arrival in Fiji and so the launch moved from 28 Oct to 5 Nov 2013 (Business Standard, SpacePolicyOnline).
Frame: the ship along z, bow at -z, deck at y 6; the tracking dish at (3, 6, 33).
"""
from .common import W, frame, cam, move

SHIP_Z = 56000.0
P = frame("ship", SHIP_Z)

LOOK = {
    "base": "storm_night", "time": "01:00", "ssao": True,
    "weather": {"rain": 0.45, "wind": 0.8, "clouds": 0.85, "fog": 0.0},
    "sun": {"energy": 0, "visible": False}, "moon": {"elevation": 30, "azimuth": 160, "energy": 0.45, "color": "#9fb4d8", "visible": False, "shadows": True},
    "ambient": {"color": "#56657c", "energy": 0.28},
    "fog": {"begin": 30, "end": 600, "color": "#0c1116", "volumetric": 0.0},
    "ground_fog": {"density": 0.0},
    "glow": {"enabled": True, "intensity": 0.7, "bloom": 0.05, "threshold": 1.1},
    "grade": {"contrast": 1.12, "saturation": 0.85, "vignette": 0.35, "grain": 0.06},
    "practical_lights": {"level": 0},
}

ACTORS = [
    {"id": "deckhand", "character": "toon_deckhand", "at": P(4.8, 6.15, 30.4), "facing": P(3.0, 6.15, 33), "action": "fix",
     "keep_y": True, "cues": [{"t": 0.0, "expression": "panic"},
                              {"t": W("l9b", "weather"), "expression": "shocked", "head": [-10, 30, 0]},
                              {"t": W("l9b", "Pacific"), "expression": "panic", "head": [0, 0, 0]}]},
]

GAGS = [{"id": "nalanda", "script": "gags/pacific_ship.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"waves": [W("l9b", "bad", -0.6)], "lightning": [W("l9b", "stuck", 0.0), W("l9b", "Pacific", 0.15)]}}]

SHOTS = {
    "ship_storm": {"look": LOOK, "camera": move(
        cam(P(-120, 30, -95), P(0, 8, 10), 26, roll=-5), cam(P(-110, 26, -80), P(2, 8, 14), 28, roll=4), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
