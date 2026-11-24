"""Castle Doom, Latveria (gags/castle.gd, gag id "castle_set").

Frame: the throne at (0, 1.2, -26) facing +z; the nave runs to the great doors at z 14; the outer gate court at
(0, 0, 40) (gatehouse top y 12); the exterior castle at x 400. Cameras in the nave stand toward +z looking -z.

Chapter 2: castle_gates (v11: the doors open, Doom walks in past kneeling guards), castle_throne (v12: on the throne,
lightning on "Doom."), castle_king (v12b). Chapter 3: throne_wide (d1), castle_immunity (d2: a hero with handcuffs at
the gate; the flag unrolls and the portcullis slams), castle_people (d2b: Doom above the gate, the people cheer),
doom_hands (d3: a reactor and a spell), doombots_row (d4), doombots_pop (d5: one Doombot's head pops off).
Chapter 4: castle_night (r19), castle_window (r20: the push into the lit window).
"""
from .common import W, frame, cam, move

P = frame("board", 120000.0)
TH = (0.0, 1.2, -26.0)
GZ = 40.0

LOOK_CASTLE = {
    "base": "night_fog", "time": "23:50",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.0},
    "sun": {"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "sky": {"top": "#04060c", "horizon": "#0c1220", "clouds": 0.0, "stars": 0.0},
    "ambient": {"color": "#1a2230", "energy": 0.08, "sky": 0.0},
    "fog": {"begin": 400, "end": 3000, "curve": 1.8, "volumetric": 0.016, "color": "#8a9ab0", "anisotropy": 0.6,
            "length": 60},
    "glow": {"enabled": True, "intensity": 0.85, "bloom": 0.06, "threshold": 1.05},
    "ssao": True,
    "grade": {"contrast": 1.22, "saturation": 1.0, "vignette": 0.5, "grain": 0.045},
}
LOOK_STORM = dict(LOOK_CASTLE, sky={"top": "#05070e", "horizon": "#141c2c", "clouds": 0.6, "stars": 0.0},
                  ambient={"color": "#1a2234", "energy": 0.18, "sky": 0.0},
                  weather={"fog": 0.2, "rain": 0.6, "clouds": 0.8, "wind": 0.6},
                  fog={"begin": 40, "end": 900, "curve": 1.4, "volumetric": 0.006, "color": "#3a4458"})


def span(a, b):
    return [{"shot": a, "offset": -0.1}, {"shot": b}]


ACTORS = [
    # Doom walking in (the gates shot only).
    {"id": "doom_walk", "character": "doom_realistic", "at": P(0.0, 0, 16.0), "facing": P(0.0, 0, -26.0), "action": "idle",
     "route": {"via": [P(0.0, 0, 6.0)], "gait": "walk_formal", "start": W("v11", 0, 0.2), "arrive": W("v11", "Latveria.", 0.3)},
     "shown": [span("castle_gates", "castle_throne")], "cues": [{"t": 0.0, "expression": "determined"}]},
    # Doom on the throne.
    {"id": "doom_throne", "freeze": 0.35, "character": "doom_realistic", "at": P(TH[0], TH[1] + 0.32, TH[2] + 0.28), "facing": P(0.0, 1.2, 10.0), "keep_y": True,
     "action": "sit", "shown": [span("castle_throne", "castle_immunity"), span("doom_hands", "hell_fight")],
     "cues": [{"t": 0.0, "expression": "scheming"}]},
    # Doom above the gate, before his people.
    {"id": "doom_gate", "character": "doom_realistic", "at": P(0.0, 12.0, GZ + 1.0), "facing": P(0.0, 12.0, GZ + 20.0),
     "keep_y": True, "action": "idle", "shown": [span("castle_people", "doom_hands")],
     "cues": [{"t": 0.0, "expression": "smug"}]},
    # The hero at the gate with handcuffs.
    {"id": "hero", "character": "toon_agent", "at": P(0.6, 0, GZ + 5.5), "facing": P(0.0, 0, GZ), "action": "idle",
     "shown": [span("castle_immunity", "castle_people")],
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": W("d2", "immunity.", 0.0), "expression": "surprised"},
              {"t": W("d2", "arrest", 0.0), "expression": "shocked"}]},
]
# Guards kneeling down the carpet (gates + throne shots).
for _i, (_x, _z) in enumerate([(-2.0, 4.0), (2.0, 4.0), (-2.0, -2.0), (2.0, -2.0), (-2.0, -8.0), (2.0, -8.0)]):
    ACTORS.append({"id": f"guard_{_i}", "character": "toon_doom_extra", "at": P(_x, 0, _z), "facing": P(0.0, 0, _z),
                   "action": "crouch", "shown": [span("castle_gates", "castle_immunity")],
                   "cues": [{"t": 0.0, "expression": "nervous"}]})
# Doombots in a line across the nave (doombots_row, doombots_pop).
for _i in range(7):
    ACTORS.append({"id": f"doombot_{_i}", "character": "doom_realistic", "at": P(-4.2 + 1.4 * _i, 0, -12.0),
                   "facing": P(-4.2 + 1.4 * _i, 0, 10.0), "action": "idle", "shown": [span("doombots_row", "hell_fight")],
                   "cues": [{"t": 0.0, "expression": "smug"}]})
# Villagers in the gate court cheering up at him.
for _i, (_ch, _x, _z) in enumerate([("toon_market_man", -2.0, GZ + 6.0), ("toon_market_woman", -0.8, GZ + 6.8),
                                    ("toon_market_kid", 0.4, GZ + 6.2), ("toon_market_elder", 1.6, GZ + 7.0),
                                    ("toon_market_woman_b", 2.6, GZ + 6.4), ("toon_market_vendor", -3.0, GZ + 7.2)]):
    ACTORS.append({"id": f"villager_{_i}", "character": _ch, "at": P(_x, 0, _z), "facing": P(0.0, 6.0, GZ),
                   "action": "idle", "shown": [span("castle_people", "doom_hands")],
                   "cues": [{"t": 0.0, "expression": "happy"}, {"t": W("d2b", "cares", 0.0), "expression": "cheer"}]})

GAGS = [
    {"id": "castle_set", "script": "gags/castle.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"doors": W("v11", 0, -0.2), "lightning": [W("v12", "Doom.", 0.0), W("v12b", "king", 0.0),
                                                          W("r19", "certain.", 0.0), W("r20", "world.", 0.0)],
                "pop": {"actor": "doombot_3", "t": W("d5", "real", 0.0)}, "hands": {"t": W("d3", 0)},
                "flag": {"t": W("d2", "immunity.", -0.2)}}},
    {"id": "castle_suits", "script": "library:doom_suit", "t": 0, "at": P(0, 0, 0),
     "params": {"actors": [{"actor": a} for a in ["doom_walk", "doom_throne", "doom_gate"]]
                + [{"actor": f"doombot_{i}", "hood": True} for i in range(7)]}},
]

THC = P(TH[0], TH[1] + 1.3, TH[2])
SHOTS = {
    # The doors swing open out of the dark; Doom walks in up the carpet between kneeling guards; we track back.
    "castle_gates": {"look": LOOK_CASTLE, "camera": move(
        cam(P(0.8, 1.6, 2.0), P(0.0, 2.2, 14.0), 26, {"strength": 0.05}),
        cam(P(0.6, 1.5, -0.5), P(0.0, 1.6, 6.0), 26, {"strength": 0.05}), "in_out")},
    # On the throne; lightning on "Doom."; a slow push up the carpet.
    "castle_throne": {"look": LOOK_CASTLE, "shake": [{"t": W("v12", "Doom.", 0.0), "amount": 0.05}], "camera": move(
        cam(P(0.0, 1.6, -14.0), THC, 30, {"strength": 0.06}),
        cam(P(0.0, 1.8, -19.0), THC, 30, {"strength": 0.08}), "in")},
    # Low, close on Doom on the throne: a king.
    "castle_king": {"look": LOOK_CASTLE, "camera": move(
        cam(P(1.4, 1.5, -22.5), THC, 38, {"strength": 0.12}),
        cam(P(0.9, 1.45, -23.0), THC, 38, {"strength": 0.12}), "in_out")},
    # Chapter 3: the whole nave, high: columns, banners, braziers, the throne far off.
    "throne_wide": {"look": LOOK_CASTLE, "camera": move(
        cam(P(3.5, 11.0, 12.0), P(0.0, 2.0, -26.0), 22, {"strength": 0.03}),
        cam(P(2.0, 9.0, 4.0), P(0.0, 2.0, -26.0), 22, {"strength": 0.03}), "in_out")},
    # The gate court: the hero waves his handcuffs; the flag unrolls; the portcullis slams in his face.
    "castle_immunity": {"look": LOOK_CASTLE, "shake": [{"t": W("d2", "immunity.", 0.8), "amount": 0.15}], "camera": move(
        cam(P(-3.0, 1.4, GZ + 9.5), P(0.0, 4.5, GZ), 26, {"strength": 0.05}),
        cam(P(-2.5, 1.5, GZ + 8.5), P(0.0, 5.0, GZ), 26, {"strength": 0.05}), "in_out")},
    # Doom above the gate; the people cheer below.
    "castle_people": {"look": LOOK_CASTLE, "camera": move(
        cam(P(2.5, 1.2, GZ + 10.0), P(0.0, 11.0, GZ + 1.0), 28, {"strength": 0.04}),
        cam(P(1.8, 1.3, GZ + 9.0), P(0.0, 11.5, GZ + 1.0), 28, {"strength": 0.04}), "in_out")},
    # The gauntlets: a reactor in one, a spell in the other.
    "doom_hands": {"look": LOOK_CASTLE, "camera": move(
        cam(P(0.0, 2.75, -22.6), P(0.0, 2.65, -24.0), 40, {"strength": 0.25}),
        cam(P(0.0, 2.72, -22.9), P(0.0, 2.65, -24.0), 40, {"strength": 0.25}), "in")},
    # A line of identical Dooms across the nave; a slow track along them.
    "doombots_row": {"look": LOOK_CASTLE, "camera": move(
        cam(P(-5.5, 1.3, -8.5), P(-2.0, 1.2, -12.0), 30, {"strength": 0.08}),
        cam(P(-2.0, 1.3, -8.3), P(1.5, 1.2, -12.0), 30, {"strength": 0.08}), "in_out")},
    # One head pops off in sparks.
    "doombots_pop": {"look": LOOK_CASTLE, "shake": [{"t": W("d5", "real", 0.0), "amount": 0.06}], "camera": move(
        cam(P(0.4, 1.3, -9.6), P(0.0, 1.35, -12.0), 40, {"strength": 0.15}),
        cam(P(0.35, 1.35, -9.9), P(0.0, 1.45, -12.0), 40, {"strength": 0.15}), "in_out")},
    # Chapter 4: the castle on its crag in the storm, lightning.
    "castle_night": {"look": LOOK_STORM, "camera": move(
        cam(P(430.0, -20.0, 160.0), P(400.0, 25.0, -35.0), 28, {"strength": 0.02}),
        cam(P(420.0, -12.0, 120.0), P(400.0, 27.0, -35.0), 28, {"strength": 0.02}), "in_out")},
    # The push into the great lit window.
    "castle_window": {"look": LOOK_STORM, "camera": move(
        cam(P(405.0, 20.0, 60.0), P(400.0, 33.0, -27.0), 30, {"strength": 0.02}),
        cam(P(400.5, 32.0, -18.0), P(400.0, 33.0, -27.0), 30, {"strength": 0.02}), "in")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
