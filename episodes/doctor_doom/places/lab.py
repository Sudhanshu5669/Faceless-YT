"""Empire State University, a physics lab at night, early 1960s (gags/lab.gd, gag id "lab").

Frame: the ring at (0, 2.1, -4.6); the console at (1.5, 0, -1.9) with Victor in front of it at (1.5, 0, -1.15) facing
the machine; the chalkboard at (-3.3, 0, -2.2) with Reed beside it. Cameras at +z looking -z.

lab_machine: "At Empire State University, Victor builds a machine to reach the realm of the dead, and speak to his
             mother."  a slow push from the door: moonlit benches, the machine waking, arcs, the portal clouding green.
lab_warning: "His classmate, Reed Richards, spots a flaw in the calculations."  Reed circles the flaw on "flaw".
lab_ignore:  "Victor ignores him."  Victor, lit green by the portal, smirks and turns back to the lever.
lab_blast:   "The machine explodes in his face."  he throws the switch on "machine"; overload; the console blows up in
             his face on "explodes".
"""
from .common import W, frame, cam, move

P = frame("lab", 20000.0)   # far from Hall H (bays sit close together)   # far from Hall H (bays sit close together)

LOOK_LAB = {
    "base": "night_fog", "time": "23:30",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.0},
    "sun": {"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "sky": {"top": "#05070c", "horizon": "#0a0e18", "clouds": 0.0, "stars": 0.0},
    "ambient": {"color": "#26303e", "energy": 0.2, "sky": 0.0},
    "fog": {"begin": 400, "end": 3000, "curve": 1.8, "volumetric": 0.012, "color": "#8a96a8", "anisotropy": 0.55,
            "length": 30},
    "glow": {"enabled": True, "intensity": 0.85, "bloom": 0.06, "threshold": 1.1},
    "ssao": True,
    "grade": {"contrast": 1.2, "saturation": 1.0, "vignette": 0.48, "grain": 0.045},
}

POWER = W("v1", "builds", 0.0)
WARN = W("v2", "flaw", 0.0)
LEVER_T = W("v4", "machine", 0.05)
OVER = W("v4", "machine", 0.15)
BLAST = W("v4", "explodes", 0.0)

ACTORS = [
    {"id": "victor", "character": "toon_victor_young", "at": P(1.5, 0, -1.15), "facing": P(1.5, 0, -5.0), "action": "idle",
     "cues": [{"t": 0.0, "expression": "determined"},
              {"t": W("v2", "Reed", 0.0), "expression": "side_eye", "facing": P(-1.0, 0, -0.6)},
              {"t": W("v3", "ignores", 0.0), "expression": "smug"},
              {"t": W("v3", "him.", 0.1), "facing": P(1.5, 0, -5.0), "expression": "scheming"},
              {"t": BLAST, "expression": "shocked"}]},
    {"id": "reed", "character": "toon_reed_young", "at": P(-2.0, 0, -2.3), "facing": P(1.5, 0, -1.15), "action": "idle",
     "cues": [{"t": 0.0, "expression": "thinking"},
              {"t": WARN, "expression": "nervous"},
              {"t": W("v2", "calculations.", 0.1), "facing": P(1.5, 0, -1.0), "expression": "nervous"},
              {"t": BLAST, "expression": "shocked"}]},
]

GAGS = [
    {"id": "lab_set", "script": "gags/lab.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"power": POWER, "warn": WARN, "chalk": {"actor": "reed"}, "lever": {"actor": "victor", "t": LEVER_T},
                "overload": OVER, "blast": BLAST}},
]

SHOTS = {
    # Chapter 2 (flash-forward): Reed at the board, Victor at his machine, facing each other across the lab.
    "lab_double": {"look": LOOK_LAB, "camera": move(
        cam(P(-0.3, 1.25, 1.8), P(-0.3, 1.1, -1.8), 30, {"strength": 0.06}),
        cam(P(-0.2, 1.3, 1.2), P(-0.25, 1.1, -1.8), 30, {"strength": 0.06}), "in_out")},
    # From the door, low: the benches in moonlight, the machine waking at the far end, Victor at the console
    # silhouetted against the portal. A slow push in.
    "lab_machine": {"look": LOOK_LAB, "camera": move(
        cam(P(0.9, 1.05, 5.6), P(0.0, 2.0, -4.6), 24, {"strength": 0.06}),
        cam(P(0.5, 1.35, 2.6), P(0.2, 2.0, -4.6), 24, {"strength": 0.08}), "in_out")},
    # Over Victor's shoulder to Reed at the board: he circles the flaw on "flaw", then turns to warn him.
    "lab_warning": {"look": LOOK_LAB, "camera": move(
        cam(P(-2.0, 1.45, 0.35), P(-2.6, 1.3, -2.2), 30, {"strength": 0.1}),
        cam(P(-2.05, 1.42, -0.05), P(-2.6, 1.3, -2.2), 30, {"strength": 0.12}), "in_out")},
    # From the machine side: Victor's face, green from the portal behind the lens, smirks and turns away.
    "lab_ignore": {"look": LOOK_LAB, "camera": move(
        cam(P(0.35, 1.2, -0.75), P(1.5, 1.12, -1.2), 40, {"strength": 0.12}),
        cam(P(0.45, 1.19, -0.8), P(1.5, 1.12, -1.2), 40, {"strength": 0.14}), "out")},
    # From the machine side, over the console: Victor's face lit by the portal; he throws the switch and the console
    # blows up between him and the lens, in his face (the old side-on angle showed only his back).
    "lab_blast": {"look": LOOK_LAB, "shake": [{"t": BLAST, "amount": 0.35}, {"t": OVER, "amount": 0.06}], "slowmo": None,
                  "camera": move(
        cam(P(0.3, 1.45, -2.3), P(1.55, 1.12, -1.3), 30, {"strength": 0.1}),
        cam(P(0.38, 1.43, -2.18), P(1.55, 1.12, -1.3), 30, {"strength": 0.1}), "out")},
}
SHOTS["lab_blast"].pop("slowmo")

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
