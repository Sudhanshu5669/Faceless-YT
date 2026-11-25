"""Latveria (gags/latveria.gd, gag id "latveria_set"): the valley camp, the wagon, the blizzard forest, the chest, and
the liner to New York.

Frame (gag-local): valley camp fire at (0, 0, 0); WAGON interior at (0, 0, 300); FOREST at (300, 0, 0) with the great
tree at (300, 0, -10); CHEST at (0, 0, 600); LINER deck at (-400, 0, 0) with the bow rail at z -25.

Restraint: the parents' deaths are never shown. Cynthia: her green spark fades by the cradle. Werner: the snow mound
grows at the tree's foot while the boy stands.
"""
from .common import W, frame, cam, move

P = frame("board", 4800.0)   # near the origin (float precision); gags are shown only in their shots
WG, FO, CH, LI = (0.0, 300.0), (300.0, 0.0), (0.0, 600.0), (-3000.0, 0.0)

_BASE = {
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.0},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "ssao": True,
}
LOOK_DAWN = dict(_BASE, base="day", time="07:10",
                 sun={"elevation": 7, "azimuth": 110, "color": "#ffc29a", "energy": 1.8, "softness": 0.7, "visible": True,
                      "size": 1.4, "glow": 1.6, "shadows": True},
                 sky={"top": "#4a6a9a", "horizon": "#f2c8a8", "clouds": 0.2},
                 ambient={"color": "#8a9ab8", "energy": 0.4, "sky": 0.6},
                 fog={"begin": 40, "end": 600, "curve": 1.4, "volumetric": 0.006, "color": "#c8d0e0"},
                 glow={"enabled": True, "intensity": 0.6, "bloom": 0.04, "threshold": 1.15},
                 grade={"contrast": 1.12, "saturation": 0.95, "vignette": 0.4, "grain": 0.04})
LOOK_NIGHT = dict(_BASE, base="night_fog", time="23:00",
                  sun={"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
                  sky={"top": "#05070c", "horizon": "#101826", "clouds": 0.0, "stars": 0.0},
                  ambient={"color": "#1c2434", "energy": 0.1, "sky": 0.0},
                  fog={"begin": 400, "end": 3000, "curve": 1.8, "volumetric": 0.01, "color": "#8a96a8", "anisotropy": 0.5,
                       "length": 20},
                  glow={"enabled": True, "intensity": 0.8, "bloom": 0.05, "threshold": 1.05},
                  grade={"contrast": 1.2, "saturation": 1.0, "vignette": 0.5, "grain": 0.045})
LOOK_STORM = dict(LOOK_NIGHT, ambient={"color": "#3a4a68", "energy": 0.45, "sky": 0.0},
                  fog={"begin": 5, "end": 60, "curve": 1.2, "volumetric": 0.02, "color": "#6a7890", "anisotropy": 0.3,
                       "length": 40})
LOOK_SEA = dict(LOOK_DAWN, time="06:40", sun={"elevation": 4, "azimuth": 160, "color": "#ffb88a", "energy": 1.5,
                                               "softness": 0.8, "visible": True, "size": 1.6, "glow": 2.0, "shadows": True},
                fog={"begin": 60, "end": 1400, "curve": 1.3, "volumetric": 0.004, "color": "#c8b8a8"})


def span(a, b):
    return [{"shot": a, "offset": -0.1}, {"shot": b}]


ACTORS = [
    {"id": "cynthia", "character": "witch_green",   # VLTXD's Latverian witch (the user, 2026-11-25)
     "at": P(WG[0] - 0.2, 0, WG[1] + 0.35), "facing": P(WG[0] + 0.6, 0, WG[1] - 0.4),
     "action": "idle", "shown": [span("lat_wagon", "lat_healer")],
     "cues": [{"t": 0.0, "expression": "happy"}, {"t": W("v0m", "witch.", 0.0), "expression": "smug"},
              {"t": W("v0m", "dies", 0.0), "expression": "sleepy"}]},
    {"id": "werner", "character": "toon_werner", "at": P(-2.2, 0, 1.6), "facing": P(0.0, 0, 0.0), "action": "idle",
     "shown": [span("lat_healer", "lat_flee")], "cues": [{"t": 0.0, "expression": "thinking"}]},
    {"id": "werner_flee", "character": "toon_werner", "at": P(FO[0] + 7.0, 0, 10.0), "facing": P(FO[0], 0, -8.0),
     "action": "idle", "route": {"via": [P(FO[0] + 1.2, 0, -7.2)], "gait": "walk", "start": W("v0o", 0, -0.3),
                                 "arrive": W("v0o", "snow,", 0.6)},
     "shown": [span("lat_flee", "lat_freeze")], "cues": [{"t": 0.0, "expression": "panic"}]},
    {"id": "boy_flee", "character": "toon_victor_boy", "at": P(FO[0] + 7.6, 0, 10.6), "facing": P(FO[0], 0, -8.0),
     "action": "idle", "route": {"via": [P(FO[0] + 0.4, 0, -6.9)], "gait": "walk", "start": W("v0o", 0, -0.2),
                                 "arrive": W("v0o", "snow,", 0.8)},
     "shown": [span("lat_flee", "lat_freeze")], "cues": [{"t": 0.0, "expression": "nervous"}]},
    {"id": "boy_tree", "character": "toon_victor_boy", "at": P(FO[0] - 0.6, 0, -6.6), "facing": P(FO[0] + 0.6, 0, -8.4),
     "action": "idle", "shown": [span("lat_freeze", "lat_chest")], "cues": [{"t": 0.0, "expression": "crying"}]},
    {"id": "boy_chest", "freeze": 0.35, "character": "toon_victor_boy", "at": P(CH[0], 0, CH[1] + 0.85), "facing": P(CH[0], 0, CH[1] - 1.0),
     "action": "idle", "shown": [span("lat_chest", "liner_deck")],
     "cues": [{"t": 0.0, "expression": "sad"}, {"t": W("v0q", "secret:", 0.0), "expression": "surprised"},
              {"t": W("v0r", "swears", 0.0), "expression": "angry"}]},
    {"id": "victor_ship", "character": "toon_victor_young", "at": P(LI[0] + 1.0, 0.2, -24.2), "facing": P(LI[0], 0.2, -60.0),
     "keep_y": True, "action": "idle", "shown": [span("liner_deck", "lab_machine")],
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": W("v0s", "scholarship.", 0.0), "expression": "smug"}]},
]
for _i, (_ch, _x, _z) in enumerate([("witch_purple", 1.6, 1.8), ("toon_market_kid", -0.9, -1.8), ("witch_orange", 2.0, -1.2)]):
    ACTORS.append({"id": f"camp_{_i}", "character": _ch, "at": P(_x, 0, _z), "facing": P(0.0, 0, 0.0), "action": "idle",
                   "shown": [span("lat_valley", "lat_wagon"), span("lat_healer", "lat_flee")],
                   "cues": [{"t": 0.0, "expression": "happy"}]})

GAGS = [
    {"id": "latveria_set", "script": "gags/latveria.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"snow": 0.5, "spark": W("v0m", "dies", 0.0), "mound": W("v0p", 0, -0.2), "chest": W("v0q", "secret:", 0.0)}},
]

SHOTS = {
    # High over the valley at dawn: mountains, pines, the camp's smoke rising; a slow crane down.
    "lat_valley": {"look": LOOK_DAWN, "camera": move(
        cam(P(14.0, 16.0, 46.0), P(0.0, 2.0, -30.0), 24, {"strength": 0.03}),
        cam(P(9.0, 9.0, 32.0), P(0.0, 1.5, -20.0), 24, {"strength": 0.03}), "in_out")},
    # The painted wagons round the fire in the foreground; the Baron's castle on its crag beyond.
    "lat_castle": {"look": LOOK_DAWN, "camera": move(
        cam(P(-9.0, 1.8, 13.0), P(40.0, 30.0, -150.0), 32, {"strength": 0.05}),
        cam(P(-7.0, 2.2, 11.0), P(45.0, 33.0, -150.0), 32, {"strength": 0.05}), "in_out")},
    # Inside a wagon by candlelight: the cradle; his mother's green spark fades.
    "lat_wagon": {"look": LOOK_NIGHT, "camera": move(
        cam(P(WG[0] + 1.4, 1.2, WG[1] + 1.1), P(WG[0] + 0.1, 0.9, WG[1] - 0.2), 26, {"strength": 0.12}),
        cam(P(WG[0] + 1.3, 1.15, WG[1] + 0.95), P(WG[0] + 0.2, 0.85, WG[1] - 0.25), 26, {"strength": 0.12}), "in")},
    # Werner by the fire, his healer's satchel; a slow push.
    "lat_healer": {"look": LOOK_DAWN, "camera": move(
        cam(P(1.5, 1.3, 4.6), P(-2.2, 1.15, 1.6), 35, {"strength": 0.15}),
        cam(P(0.8, 1.3, 4.0), P(-2.2, 1.15, 1.6), 35, {"strength": 0.15}), "in")},
    # The blizzard: father and son struggle through the pines toward the great tree; low and tracking.
    "lat_flee": {"look": LOOK_STORM, "camera": move(
        cam(P(FO[0] + 9.5, 1.1, 6.0), P(FO[0] + 6.5, 1.0, 8.0), 28, {"strength": 0.04}),
        cam(P(FO[0] + 4.5, 1.2, -1.0), P(FO[0] + 1.0, 1.0, -6.5), 28, {"strength": 0.04}), "in_out")},
    # Dawn under the great tree: the snow mound, the boy alone.
    "lat_freeze": {"look": LOOK_STORM, "camera": move(
        cam(P(FO[0] + 2.6, 1.6, -2.4), P(FO[0], 0.8, -7.8), 32, {"strength": 0.06}),
        cam(P(FO[0] + 2.0, 1.4, -3.6), P(FO[0], 0.75, -7.8), 32, {"strength": 0.06}), "in")},
    # The carved chest opens; green light floods the boy's face.
    "lat_chest": {"look": LOOK_NIGHT, "camera": move(
        cam(P(CH[0] + 1.3, 0.85, CH[1] + 1.8), P(CH[0], 0.55, CH[1] + 0.2), 32, {"strength": 0.15}),
        cam(P(CH[0] + 1.0, 0.8, CH[1] + 1.5), P(CH[0], 0.6, CH[1] + 0.4), 32, {"strength": 0.15}), "in")},
    # Close on the boy's face in the green light: he swears revenge.
    "lat_vow": {"look": LOOK_NIGHT, "camera": move(
        cam(P(CH[0] + 0.25, 0.9, CH[1] + 0.25), P(CH[0], 0.88, CH[1] + 0.85), 40, {"strength": 0.3}),
        cam(P(CH[0] + 0.2, 0.9, CH[1] + 0.35), P(CH[0], 0.88, CH[1] + 0.85), 40, {"strength": 0.3}), "in")},
    # The liner at dawn: Victor at the bow rail, New York rising out of the fog.
    "liner_deck": {"look": LOOK_SEA, "camera": move(
        cam(P(LI[0] + 3.0, 1.9, -19.0), P(LI[0] - 20.0, 30.0, -900.0), 30, {"strength": 0.04}),
        cam(P(LI[0] + 2.4, 1.7, -21.0), P(LI[0] - 20.0, 32.0, -900.0), 30, {"strength": 0.04}), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
