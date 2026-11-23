"""The Pokhran field firing range, Thar desert (gags/range.gd, gag id "range_site").

Frame: the White House shaft plate at the origin (top at y 0.26); cameras usually stand south (+z) looking
north (-z). The tripod apex at (0, 5.2, 0); the winch at (4.6, 0, 1.4) behind a sandbag horseshoe; the spoil
heap at (-5.6, 0, -3.2); the hero khejri at (-6.8, 0, -11.5); the camp (olive tents) north-west at about
(-8..-31, -27..-44); the windsock at (10.5, 0, -17). A truck track crosses in front at z ~5.6 (x = 0).
The ground is not flat: place actors with range_ground() heights only where it matters (keep_y off snaps them).
"""
from .common import W, frame, cam, move

RANGE_Z = 15000.0
P = frame("range", RANGE_Z)

# Afternoon in May (the tests fired at 15:45): the sun high in the south-west, behind the shaft from the usual
# camera side, so the tripod, the tree and the jawans get a warm rim; a pale, dusty sky; haze swallowing the
# far dunes. Fill comes from the sky (blue from above) plus warm bounce off the sand.
LOOK_AFTERNOON = {
    "base": "day", "time": "15:45",
    "weather": {"fog": 0.0, "clouds": 0.0, "wind": 0.4},
    "sun": {"elevation": 36, "azimuth": 212, "color": "#ffe2b6", "energy": 3.1, "softness": 0.7,
            "visible": True, "size": 1.3, "glow": 1.4, "shadows": True},
    "sky": {"top": "#7998bd", "horizon": "#e8dcc4", "clouds": 0.0},
    "ambient": {"color": "#b89c78", "energy": 0.32, "sky": 0.55},
    "fog": {"begin": 25, "end": 2300, "curve": 1.8, "volumetric": 0.0},
    "glow": {"enabled": True, "intensity": 0.55, "bloom": 0.04, "threshold": 1.15},
    "ssao": True,
    "grade": {"contrast": 1.15, "saturation": 1.02, "vignette": 0.42, "grain": 0.035},
}

ACTORS = [
    # A jawan carrying two jerrycans of water across the site, behind the shaft.
    {"id": "jawan_noon", "character": "toon_jawan_a", "at": P(0.51, 0, -4.1), "facing": P(-0.83, 0, -3.03),
     "route": {"via": [P(-0.83, 0, -3.03)], "gait": "walk", "start": W("l2b", offset=-0.6),
               "arrive": W("l2b", edge="end", offset=0.3)},
     "cues": [{"t": 0.0, "expression": "deadpan"}], "shown": [[W("l2b", offset=-1.0), W("l2b", edge="end", offset=0.6)]]},
]

# lid_chalk: the chalked text on the plate faces a camera in front of it (C points from the text to the camera,
# chosen so the afternoon sun falls three-quarters across the jawan's face); the jawan crouches just beyond the
# text facing us, reaching forward to finish the E of HOUSE (bottom right). The text sits off the cable gland.
CX, CZ = -0.9986, -0.0523      # toward the camera (west; the firing cables run off east, behind)
RX, RZ = -0.0523, 0.9986       # the text's right (as the camera sees it)
T = (0.42 * CX - 0.32 * RX, 0.262, 0.42 * CZ - 0.32 * RZ)   # text centre: 0.42 toward camera, 0.32 left


def TP(right, fwd, y=0.262):
    """A point in the text frame (right, toward-camera), on the plate unless y is given."""
    return P(T[0] + RX * right + CX * fwd, y, T[2] + RZ * right + CZ * fwd)


ACTORS.append(
    {"id": "jawan_chalk", "character": "toon_jawan_c", "at": TP(0.1, -0.42), "facing": TP(0.1, 3.0),
     "action": "crouch", "keep_y": True, "cues": [
         {"t": 0.0, "expression": "determined"},
         {"t": W("l2d", "House", 0.12), "expression": "smug"},
     ], "shown": [[W("l2d", offset=-1.0), W("l2d", edge="end", offset=0.6)]]})

# range_1995: December 1995, the same shaft out in the open. A crane truck lowers casing into the shaft; a Sikh
# jawan on the collar guides it with both hands; the foreman calls the crane down; a scientist with a clipboard
# watches. The casing's foot goes into the shaft on "right here".
Y1995 = [W("l3b", offset=-0.8), W("l3c", offset=-0.02)]
# The site stays as it was in 1995 while the prints are looked at in Delhi and until the test is called off.
Y1995_LATE = [W("l4a", offset=-0.8), W("l5a", offset=-0.02)]
ACTORS += [
    {"id": "guide_95", "character": "toon_jawan_b", "at": P(0.84, 0.222, -0.32), "facing": P(0.3, 0.222, 1.1),
     "action": "idle", "keep_y": True, "shown": [Y1995],
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": W("l3b", "here", 0.1), "expression": "happy"}]},
    {"id": "foreman_95", "character": "toon_jawan_d", "at": P(-1.35, 0, -1.7), "facing": P(0.2, 0, 0.3),
     "action": "call_out", "shown": [Y1995],
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": W("l3b", "here", 0.05), "action": "idle", "expression": "grin"}]},
    {"id": "sci_95", "character": "toon_barc_sci", "at": P(-2.05, 0, 0.15), "facing": P(0.3, 0, 0.6),
     "action": "idle", "shown": [Y1995],
     "cues": [{"t": 0.0, "expression": "thinking"}, {"t": W("l3b", "nuclear", 0.0), "expression": "determined"},
              {"t": W("l3b", "here", 0.1), "expression": "happy"}]},
]

# shovel_back: the call-off. Two jawans shovel the spoil back into the open shaft; a truck pulls away in its dust.
SHOVEL = [W("l4d", offset=-0.8), W("l5a", offset=-0.02)]
ACTORS += [
    {"id": "shovel_a", "character": "toon_jawan_a", "at": P(-2.15, 0, 0.42), "facing": P(0.0, 0, -0.1),
     "action": "idle", "shown": [SHOVEL],
     "cues": [{"t": 0.0, "expression": "sad"}]},
    {"id": "shovel_b", "character": "toon_jawan_c", "at": P(-1.45, 0, 1.92), "facing": P(0.0, 0, 0.3),
     "action": "idle", "shown": [SHOVEL],
     "cues": [{"t": 0.0, "expression": "sad"}, {"t": W("l4d", "cancelled", 0.1), "expression": "crying"}]},
]

# team_lookup (1998, dusk): four of the team stand shoulder to shoulder in front of the tripod, watching the satellite
# cross; on "nothing" they turn to each other in pairs. They face the afterglow (azimuth 200), the camera low behind.
import math as _m
_F = (_m.sin(_m.radians(200)), _m.cos(_m.radians(200)))      # toward the satellite / the glow
_RW = (-_F[1], _F[0])                                           # along the row (each man's right)
_C = (2.5, 6.5)
LOOKUP = [W("l5d", offset=-0.8), W("l6a", offset=-0.3)]   # gone before night_work (its camera stands here)


def _row(k):
    x, z = _C[0] + _RW[0] * 0.8 * k, _C[1] + _RW[1] * 0.8 * k
    return P(x, 0, z), P(x + _F[0] * 10, 0, z + _F[1] * 10)


for i, (ch, k, yaw) in enumerate([("toon_jawan_a", -1.5, -62), ("toon_barc_sci", -0.5, 58),
                                  ("toon_jawan_b", 0.5, -60), ("toon_jawan_d", 1.5, 62)]):
    at, facing = _row(k)
    ACTORS.append({"id": f"lookup_{i}", "character": ch, "at": at, "facing": facing, "action": "idle",
                   "shown": [LOOKUP], "phase": 0.3 * i,
                   "cues": [{"t": 0.0, "expression": "determined", "head": [-42, 0, 0], "head_turn": 0.01},
                            {"t": W("l5d", "nothing", -0.1 + 0.06 * i), "expression": "scheming",
                             "head": [-4, yaw, 0], "head_turn": 0.45}]})

# night_work (1998): only the work lamp over the shaft head and a hand torch; a jawan hugs a sandbag past the lamp.
NIGHT = [W("l6a", offset=-0.8), W("l6a", edge="end", offset=0.6)]
ACTORS += [
    {"id": "night_bag", "character": "toon_jawan_c", "at": P(1.85, 0, 3.25), "facing": P(-2.2, 0, 4.8), "action": "idle",
     "route": {"via": [P(-2.2, 0, 4.8)], "gait": "walk_carry", "start": W("l6a", offset=-0.7)},
     "shown": [NIGHT], "cues": [{"t": 0.0, "expression": "effort"}]},
    {"id": "night_torch", "character": "toon_jawan_a", "at": P(-1.7, 0, -1.3), "facing": P(0.8, 0, 0.6),
     "action": "torch", "shown": [NIGHT], "cues": [{"t": 0.0, "expression": "determined"}]},
]

# truck_park (1998, dawn): a canopy truck reverses into its own old tyre marks; a jawan palms it to a stop on "exact".
PARK_AT = (8.5, 10.0)          # the truck's centre when parked; it faces -z (yaw 90), its rear toward the camera
PARK = [W("l6b", offset=-0.8), W("l6c", offset=0.2)]
ACTORS += [
    {"id": "park_jawan", "character": "toon_jawan_d", "at": P(10.2, 0, 10.9), "facing": P(9.7, 0, 13.0),
     "action": "idle", "shown": [PARK],
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": W("l6b", "exact", 0.35), "expression": "smug"}]},
]

# dune_shape (1998, dawn): the dug sand patted by hand into a crescent dune; one jawan blows the wind ripples onto it.
DUNE_AT = (-4.5, 9.0)        # open ground south-west of the shaft, clear of the spoil heap
DUNE = [W("l7a", offset=-0.8), W("l7b", offset=0.15)]


def DP(x, y, z):
    """A point relative to the dune's centre (its +z is the wind's way)."""
    return P(DUNE_AT[0] + x, y, DUNE_AT[1] + z)


ACTORS += [
    {"id": "dune_a", "character": "toon_jawan_a", "at": DP(-0.5, 0, 1.12), "facing": DP(0, 0, 0), "action": "crouch",
     "shown": [DUNE], "cues": [{"t": 0.0, "expression": "effort"}, {"t": W("l7a", "wind", 0.5), "expression": "happy"}]},
    {"id": "dune_b", "character": "toon_jawan_b", "at": DP(0.62, 0, 1.0), "facing": DP(0, 0, 0), "action": "crouch",
     "shown": [DUNE], "cues": [{"t": 0.0, "expression": "effort"}, {"t": W("l7a", "wind", 0.6), "expression": "grin"}]},
    {"id": "dune_blow", "character": "toon_jawan_c", "at": DP(-1.12, 0, -0.95), "facing": DP(0.1, 0, -0.15), "action": "crouch",
     "shown": [DUNE], "cues": [{"t": 0.0, "expression": "determined"},
                               {"t": W("l7a", "wind", -0.45), "expression": "surprised", "head": [24, 0, 0], "head_turn": 0.3},
                               {"t": W("l7a", "wind", 0.55), "expression": "smug", "head": [0, 0, 0], "head_turn": 0.4}]},
]

# net_drape (1998, dawn): another shaft head; two jawans on its far side fling a camouflage net over it toward us.
NET_AT = (13.0, -5.0)
NETW = [W("l7b", offset=-0.8), W("l8a", offset=0.05)]


def NP(x, y, z):
    """A point relative to the second shaft head (net-local: -z is the throwers' side)."""
    return P(NET_AT[0] + x, y, NET_AT[1] + z)


ACTORS += [
    {"id": "net_a", "character": "toon_jawan_d", "at": NP(-0.55, 0, -3.8), "facing": NP(-0.3, 0, 0), "action": "idle",
     "shown": [NETW], "cues": [{"t": 0.0, "expression": "effort"}, {"t": W("l7b", "nets", 0.4), "expression": "happy"}]},
    {"id": "net_b", "character": "toon_jawan_a", "at": NP(0.55, 0, -3.8), "facing": NP(0.3, 0, 0), "action": "idle",
     "shown": [NETW], "cues": [{"t": 0.0, "expression": "effort"}, {"t": W("l7b", "nets", 0.5), "expression": "grin"}]},
]

# pass_watch (1998, afternoon): a lookout checks his watch against his list of pass times; fist up on "overhead".
LOOKOUT = [W("l8a", offset=-0.8), W("l8c", offset=0.0)]
ACTORS += [
    {"id": "lookout", "character": "toon_jawan_b", "at": P(1.6, 0, 6.2), "facing": P(0.4, 0, 0), "action": "idle",
     "shown": [LOOKOUT],
     "cues": [{"t": 0.0, "expression": "nervous", "head": [24, 6, 0], "head_turn": 0.01},
              {"t": W("l8a", "overhead", -0.15), "expression": "determined", "head": [-18, 0, 0], "head_turn": 0.25}]},
]

# statue (1998, afternoon): on "stops" everyone on the site freezes mid-motion while the satellite passes.
STATUE = [W("l8b", offset=-1.2), W("l8c", offset=0.0)]
FREEZE = W("l8b", "stops", 0.0)
ACTORS += [
    {"id": "st_bag", "character": "toon_jawan_a", "at": P(-1.0, 0, 4.9), "facing": P(2.4, 0, 4.4), "action": "idle",
     "route": {"via": [P(2.4, 0, 4.4)], "gait": "walk_carry", "start": W("l8b", offset=-1.1)}, "shown": [STATUE],
     "cues": [{"t": 0.0, "expression": "effort"}, {"t": FREEZE, "hold": True}]},
    {"id": "st_walk", "character": "toon_jawan_c", "at": P(2.8, 0, 6.0), "facing": P(0.4, 0, 7.0), "action": "idle",
     "route": {"via": [P(0.4, 0, 7.0)], "gait": "walk", "start": W("l8b", offset=-1.0)}, "shown": [STATUE],
     "cues": [{"t": 0.0, "expression": "deadpan"}, {"t": FREEZE, "hold": True}]},
    {"id": "st_chop", "character": "toon_jawan_d", "at": P(-0.6, 0, 7.6), "facing": P(0.2, 0, 10.5), "action": "chop",
     "shown": [STATUE], "cues": [{"t": 0.0, "expression": "effort"}, {"t": FREEZE, "hold": True}]},
    {"id": "st_chai", "character": "toon_barc_sci", "at": P(1.3, 0, 8.8), "facing": P(0.6, 0, 11.8), "action": "eat",
     "shown": [STATUE], "cues": [{"t": 0.0, "expression": "happy"}, {"t": FREEZE, "hold": True}]},
]

# cricket (1998, afternoon): gully cricket on the sand south of the shaft; the batsman lofts it on "cricket".
CRICKET = [W("l8c", offset=-1.0), W("l9a", offset=0.0)]   # through cricket_feed: the live satellite view sees them
HIT = W("l8c", "cricket", 0.0)
ACTORS += [
    {"id": "cr_bat", "character": "toon_jawan_a", "at": P(-3.0, 0, 16.0), "facing": P(-3.0, 0, 0.0), "action": "idle",
     "shown": [CRICKET], "cues": [{"t": 0.0, "expression": "determined"}, {"t": W("l8c", "cricket", 0.15), "expression": "grin"}]},
    {"id": "cr_bowl", "character": "toon_jawan_c", "at": P(-3.1, 0, 1.0), "facing": P(-3.0, 0, 16.0), "action": "idle",
     "route": {"via": [P(-3.05, 0, 6.6)], "gait": "jog", "start": W("l8c", "cricket", -1.4), "arrive": W("l8c", "cricket", -0.62)},
     "shown": [CRICKET],
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": W("l8c", "cricket", -0.62), "action": "throw"},
              {"t": W("l8c", "cricket", 0.2), "expression": "shocked", "head": [-30, 0, 0], "head_turn": 0.3}]},
    {"id": "cr_field_a", "character": "toon_jawan_d", "at": P(-6.2, 0, 10.5), "facing": P(-3.0, 0, 13.0), "action": "idle",
     "shown": [CRICKET], "cues": [{"t": 0.0, "expression": "happy"},
                                  {"t": W("l8c", "cricket", 0.2), "expression": "cheer", "head": [-25, 0, 0], "head_turn": 0.3}]},
    {"id": "cr_field_b", "character": "toon_jawan_b", "at": P(0.4, 0, 11.2), "facing": P(-3.0, 0, 13.0), "action": "idle",
     "shown": [CRICKET], "cues": [{"t": 0.0, "expression": "happy"},
                                  {"t": W("l8c", "cricket", 0.25), "expression": "laugh", "head": [-28, 0, 0], "head_turn": 0.3}]},
]

# jeep_arrive (1998): a jeep brakes to a stop at the camp; scientists in borrowed fatigues climb out; on "soldiers" one
# scientist's oversized cap slides over his eyes. (kalam_tape continues at the same jeep.)
JEEP_AT = (-6.0, -19.0)          # facing -z (north, toward the camp)
JEEPW = [W("l9a", offset=-1.6), W("l10a", offset=0.0)]
ACTORS += [
    {"id": "jeep_driver", "character": "toon_jawan_a", "at": P(-5.64, 0, -19.1), "facing": P(-5.64, 0, -30.0),
     "action": "drive", "shown": [JEEPW], "cues": [{"t": 0.0, "expression": "deadpan"}]},
    {"id": "sci_f1", "character": "toon_sci_fatigues_a", "at": P(-6.85, 0, -19.05), "facing": P(-8.2, 0, -19.6),
     "action": "idle", "route": {"via": [P(-7.95, 0, -19.5)], "gait": "walk", "start": W("l9a", offset=0.1)},
     "shown": [JEEPW], "cues": [{"t": 0.0, "expression": "nervous"},
                                {"t": W("l9a", "soldiers", 0.05), "expression": "surprised"}]},
    {"id": "sci_f2", "character": "toon_sci_fatigues_b", "at": P(-8.4, 0, -18.4), "facing": P(-10.6, 0, -24.2),
     "action": "idle", "shown": [JEEPW], "cues": [{"t": 0.0, "expression": "deadpan"},
                                                  {"t": W("l9a", "soldiers", 0.3), "expression": "side_eye", "head": [0, -35, 0], "head_turn": 0.4}]},
]

# kalam_tape (1998): Kalam steps out from behind the jeep last, his white hair escaping under a perched patrol cap; the
# camera pushes in to his name tape, PRITHVIRAJ, on "Prithviraj"; he winks.
ACTORS += [
    {"id": "kalam_field", "character": "toon_kalam_fatigues", "at": P(-6.45, 0, -15.75), "facing": P(-9.6, 0, -12.9),
     "action": "idle", "route": {"via": [P(-7.3, 0, -16.55)], "gait": "walk", "start": W("l9b", "Abdul", -0.9),
                                 "arrive": W("l9b", "Kalam,", 0.2)},
     "shown": [[{"shot": "kalam_tape", "offset": 0.05}, W("l10a", offset=0.0)]],      # appears at the cut (l9b starts before it)
     "cues": [{"t": 0.0, "expression": "happy"},
              {"t": W("l9b", "gets", 0.0), "facing": P(-9.6, 0, -12.9), "turn": 0.45},
              {"t": W("l9b", "Prithviraj.", 0.25), "expression": "wink"}]},
]

# A December morning: a low winter sun (about 32 degrees at ten), front-left of the 1995 camera; crisp, a little cooler.
LOOK_1995 = dict(LOOK_AFTERNOON,
                 time="10:00",
                 sun={"elevation": 32, "azimuth": 333, "color": "#fff0d8", "energy": 3.0, "softness": 0.6,
                      "visible": True, "size": 1.3, "glow": 1.2, "shadows": True},
                 sky={"top": "#6f93c4", "horizon": "#dcdcd2", "clouds": 0.0},
                 ambient={"color": "#a8a8a0", "energy": 0.3, "sky": 0.6},
                 grade={"contrast": 1.14, "saturation": 0.98, "vignette": 0.38, "grain": 0.035})

GAGS = [{"id": "range_site", "script": "gags/range.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"carry": [{"actor": "jawan_noon", "what": "jerrycans"}, {"actor": "night_bag", "what": "sandbag"}],
                    "night": {"on": [NIGHT], "lamp": [1.8, 1.6], "torch": ["night_torch"]},
                    "dune": {"at": [DUNE_AT[0], DUNE_AT[1], 0.0], "scale": 0.7, "shape": [W("l7a", "Shaped", -0.3), W("l7a", "dunes", 0.35)],
                             "blow": W("l7a", "wind", -0.15), "hands": ["dune_a", "dune_b"], "blower": "dune_blow"},
                    "net": {"at": [NET_AT[0], NET_AT[1], 0.0], "size": [7.0, 6.0], "land": W("l7b", "nets", 0.05),
                            "fly": 1.6, "hands": ["net_a", "net_b"]},
                    "watch": {"actor": "lookout", "fist": W("l8a", "overhead", 0.0), "time": "13:47", "show": P(0.72, 1.22, 4.8),
                              "list": ["09:12", "11:30", "13:47", "16:05"]},
                    "chai": ["st_chai"],
                    "cricket": {"bat": "cr_bat", "bowl": "cr_bowl", "release": W("l8c", "cricket", -0.5), "hit": HIT,
                                "stumps": [-3.0, 16.45]},
                    "jeep": {"at": [JEEP_AT[0], JEEP_AT[1], 90.0], "stop": W("l9a", offset=0.15), "run": 6.0,
                             "driver": "jeep_driver", "slip": {"actor": "sci_f1", "t": W("l9a", "soldiers", 0.0)}},
                    "disguise": [{"actor": "kalam_field", "cap": True, "tape": "PRITHVIRAJ"}],
                    "park": {"at": [PARK_AT[0], PARK_AT[1], 90.0], "from": W("l6b", offset=-0.6),
                             "to": W("l6b", "exact", 0.0), "back": 6.5, "actor": "park_jawan"}, "wind": [[0.0, 115.0, 0.55]], "shimmer": 1.0,
                    "tufts": [[2.31, 3.99, 1.15], [3.74, 3.34, 1.0], [1.19, 3.04, 0.9], [3.7, 1.95, 0.85]],
                    "clear": [[4.33, 5.8, 1.8], [3.83, 5.29, 1.6], [-4.5, 9.0, 2.6], [-1.6, 6.5, 1.4], [13.0, -5.0, 5.0], [15.5, 2.5, 1.5]],
                    "dive": {"from": W("l2c"), "to": W("l2c", edge="end", offset=0.12), "y1": -186.0},
                    "drip": W("l2e", "bomb", 0.04),
                    "y1995": [Y1995, Y1995_LATE],
                    "lower": {"from": W("l3b", "India's", 0.0), "to": W("l3b", "here", 0.0)},
                    "leave": {"from": W("l4d", "cancelled", -0.45), "truck": 3},
                    "piles": [[-1.55, 0.3, 0.42], [-1.0, 1.35, 0.38]],
                    "shovel": [{"actor": "shovel_a", "phase": 0.0, "period": 1.0},
                               {"actor": "shovel_b", "phase": 0.45, "period": 1.1}],
                    "guide": {"actor": "guide_95"}, "clipboard": {"actor": "sci_95"},
                    "bushes": [[1.1, 2.5, 0.75, 0.6]]}},
        # 1998: a reconnaissance satellite slides across the dusk sky over the site, catching the sun on "satellites".
        {"id": "sat_dusk", "script": "library:sky_pass", "t": 0, "at": P(0, 0, 0), "until": W("l6a", offset=-0.3),
         "params": {"from": W("l5c", offset=-0.3), "to": W("l5c", edge="end", offset=0.9), "a": [184.0, 29.0],
                    "b": [221.0, 39.0], "distance": 3000.0, "size": 3.2, "brightness": 3.5,
                    "flare": W("l5c", "satellites", 0.05)}},
        {"id": "sat_dusk2", "script": "library:sky_pass", "t": W("l5d", offset=-0.5), "at": P(0, 0, 0),
         "until": W("l6a", offset=-0.3),
         "params": {"from": W("l5d", offset=-0.4), "to": W("l5d", edge="end", offset=0.1), "a": [199.0, 41.0],
                    "b": [214.0, 47.0], "distance": 3000.0, "size": 3.2, "brightness": 3.5}},
        {"id": "wh_chalk", "script": "library:chalk", "t": W("l2d", offset=-0.4), "until": W("l3a"),
         "at": TP(0, 0), "face": TP(0, 5.0),
         "params": {"lines": ["WHITE", "HOUSE"], "size": 0.18, "gap": 1.35, "done": 8, "width": 0.13,
                    "write": {"from": W("l2d", offset=-0.25), "to": W("l2d", "House")},
                    "hand": "jawan_chalk", "side": "r", "reach": 1.3, "seed": 3}}]

# The usual range camera looks into the afternoon sun (az 212): forward F, right R in the ground plane.
F = (-0.53, -0.85)
R = (0.85, -0.53)


def V(right, fwd, y):
    """A gag-local point from (right, forward) in the sun-facing camera frame, metres from the plate."""
    return P(R[0] * right + F[0] * fwd, y, R[1] * right + F[1] * fwd)


# Down the shaft: the same afternoon on top, but no haze in the bore (fog starts far below the bottom).
LOOK_DIVE = dict(LOOK_AFTERNOON, fog={"begin": 400, "end": 2600, "curve": 1.8, "volumetric": 0.0})

# The chamber 205 m down: no sun, no sky; the work lamp is the only light. A little dust in the air shows its rays.
LOOK_DEEP = dict(LOOK_AFTERNOON,
                 sun={"energy": 0, "visible": False},
                 ambient={"color": "#1a1c22", "energy": 0.02, "sky": 0.0},
                 fog={"begin": 300, "end": 2600, "curve": 1.8, "volumetric": 0.03, "color": "#3a3028",
                      "anisotropy": 0.6, "length": 10},
                 glow={"enabled": True, "intensity": 0.9, "bloom": 0.06, "threshold": 0.95},
                 grade={"contrast": 1.18, "saturation": 0.95, "vignette": 0.5, "grain": 0.05})

# Dusk, 1998: the sun just down behind the site, an orange band on the horizon fading up into deep blue, the first
# stars; the ground lit only by the sky (cool), the tree and the tripod in silhouette against the glow.
LOOK_DUSK = dict(LOOK_AFTERNOON,
                 time="19:30",
                 sun={"elevation": -3.5, "azimuth": 214, "color": "#ff8a4a", "energy": 0.25, "softness": 1.0,
                      "visible": True, "size": 1.0, "glow": 3.0, "glow_color": "#ff7a3a", "shadows": False},
                 sky={"top": "#1c2a52", "horizon": "#e98a52", "stars": 0.35, "clouds": 0.0},
                 ambient={"color": "#6a6a8a", "energy": 0.2, "sky": 0.85},
                 fog={"begin": 40, "end": 1900, "curve": 1.6, "volumetric": 0.0},
                 glow={"enabled": True, "intensity": 0.85, "bloom": 0.06, "threshold": 1.0},
                 grade={"contrast": 1.12, "saturation": 1.04, "vignette": 0.48, "grain": 0.04})

# Night, 1998: no moon, a deep starfield over the plain; the ground barely there in cold starlight; the only real light
# is the warm work lamp over the shaft and a cool hand torch.
LOOK_NIGHT = dict(LOOK_AFTERNOON,
                  time="23:30",
                  sun={"elevation": -30, "azimuth": 214, "energy": 0.0, "visible": False, "shadows": False},
                  moon={"elevation": 24, "azimuth": 196, "color": "#8fa8e0", "energy": 0.22, "visible": False,
                        "shadows": True, "softness": 1.0},
                  sky={"top": "#03050c", "horizon": "#111a2c", "stars": 1.3, "clouds": 0.0},
                  ambient={"color": "#2c3858", "energy": 0.1, "sky": 0.5},
                  fog={"begin": 30, "end": 900, "curve": 1.4, "volumetric": 0.012, "color": "#202634",
                       "anisotropy": 0.5, "length": 14},
                  glow={"enabled": True, "intensity": 0.9, "bloom": 0.07, "threshold": 0.9},
                  grade={"contrast": 1.16, "saturation": 0.92, "vignette": 0.55, "grain": 0.05})

# Dawn, 1998: the sun just up (5 degrees) straight ahead of the usual -z camera, backlighting the truck; long shadows
# toward the lens, a cool sky overhead, haze on the plain.
LOOK_DAWN = dict(LOOK_AFTERNOON,
                 time="06:05",
                 sun={"elevation": 5, "azimuth": 168, "color": "#ffb47a", "energy": 2.4, "softness": 0.8,
                      "visible": True, "size": 1.2, "glow": 2.2, "glow_color": "#ffa060", "shadows": True},
                 sky={"top": "#5d7cae", "horizon": "#f2c49a", "clouds": 0.0},
                 ambient={"color": "#8a8aa0", "energy": 0.26, "sky": 0.7},
                 fog={"begin": 30, "end": 1500, "curve": 1.6, "volumetric": 0.0},
                 glow={"enabled": True, "intensity": 0.7, "bloom": 0.05, "threshold": 1.05},
                 grade={"contrast": 1.14, "saturation": 1.0, "vignette": 0.44, "grain": 0.035})

# Chamber points: x/z from the canister's axis, y above the chamber floor (205 m down).
FLOOR = -205.0


def D(x, y, z):
    return P(x, FLOOR + y, z)


REVEALS = [
    {"id": "depth_count", "t": W("l2c", offset=0.05), "until": W("l2d"), "at": "range_site.dive_count", "size": 0.2,
     "billboard": "full", "face": "range_site.dive_face",
     "counter": {"from": 0, "to": 200, "decimals": 0, "suffix": " M", "land": W("l2c", "hundred", 0.1),
                 "label": "DEEP"}, "enter": "pop", "sound": "ding"},
]

SHOTS = {
    # Whip in from the feed: low on the sand, into the sun. The plate and its collar fill the lower third, the
    # tripod climbs to the sheave with the sun burning beside it, the khejri stands behind the legs; a jawan
    # crosses with a sandbag. Crane up as the line plays.
    "range_noon": {"look": LOOK_AFTERNOON, "camera": move(
        cam(V(0.6, -7.2, 0.3), V(0.0, 0.0, 2.2), 30, {"strength": 0.1}),
        cam(V(0.45, -6.5, 1.4), V(0.0, 0.0, 2.6), 32, {"strength": 0.1}), "in_out")},
    # Top-down onto the plate, through the cable gland and down the bore, circling the cable bundle; the depth
    # counter falls with the camera and lands on "two hundred"; the lamp at the bottom glows ahead.
    # Insert from above on the plate: the jawan's chalk finishes the E of HOUSE on "House"; he rocks back and
    # turns to us, smug. A slow push and a slight turn.
    "lid_chalk": {"look": LOOK_AFTERNOON, "camera": move(
        cam(TP(0.06, 1.72, 1.2), TP(0.04, -0.12, 0.55), 29, {"strength": 0.12}),
        cam(TP(0.1, 1.6, 1.14), TP(0.05, -0.14, 0.58), 31, {"strength": 0.12}), "in_out")},
    # At the bottom: the sealed canister in its cage, the lamp swinging, deep shadow; a slow push from low as a drop
    # of water falls from the bore and splashes on the lid on "bomb".
    "device_inside": {"look": LOOK_DEEP, "camera": move(
        cam(D(0.72, 1.1, 1.45), D(0.0, 1.2, 0.0), 22, {"strength": 0.15}),
        cam(D(0.55, 2.05, 1.12), D(0.1, 1.5, 0.08), 28, {"strength": 0.15}), "in_out")},
    # High and wide on the open site, December 1995: the crane's boom over the shaft, the casing going down, the
    # team round it, trucks parked in plain view; a slow push in as the casing enters the shaft on "right here".
    "range_1995": {"look": LOOK_1995, "camera": move(
        cam(P(3.4, 4.3, 8.8), P(-0.5, 2.7, -0.6), 26, {"strength": 0.1}),
        cam(P(1.9, 2.5, 5.0), P(-0.4, 1.45, -0.7), 30, {"strength": 0.12}), "in_out")},
    # The call-off, wide and still: the jawans shovel the sand back into the open shaft in the foreground; behind them a
    # truck pulls away in a long plume of dust on "cancelled".
    "shovel_back": {"look": LOOK_1995, "camera": move(
        cam(P(2.9, 2.5, 4.3), P(-2.0, 0.95, 0.35), 26, {"strength": 0.12}),
        cam(P(2.7, 2.45, 4.1), P(-2.0, 1.0, 0.3), 26, {"strength": 0.12}), "linear")},
    # Same desert: dusk, wide on the same site (the plate, the tripod, the hero khejri against the afterglow); a slow tilt
    # up into the darkening sky, where a satellite's point of light slides across and glints on "satellites".
    "same_desert": {"look": LOOK_DUSK, "camera": move(
        cam(P(4.0, 1.1, 8.5), P(-3.2, 2.4, -9.0), 26, {"strength": 0.1}),
        cam(P(3.8, 1.0, 8.2), P(-3.2, 9.0, -9.0), 26, {"strength": 0.1}), "in_out")},
    # Low in front of the team, on a diagonal so the row recedes: four faces lit warm by the afterglow they face, heads
    # tipped back, watching the satellite cross above (behind the lens); on "nothing" they turn to each other in pairs,
    # scheming. A slow creep in.
    "team_lookup": {"look": LOOK_DUSK, "camera": move(
        cam(P(_C[0] + _F[0] * 3.0 + _RW[0] * 2.0, 0.55, _C[1] + _F[1] * 3.0 + _RW[1] * 2.0),
            P(_C[0] + _RW[0] * 0.1, 1.5, _C[1] + _RW[1] * 0.1), 26, {"strength": 0.07}),
        cam(P(_C[0] + _F[0] * 2.6 + _RW[0] * 1.75, 0.6, _C[1] + _F[1] * 2.6 + _RW[1] * 1.75),
            P(_C[0] + _RW[0] * 0.1, 1.45, _C[1] + _RW[1] * 0.1), 27, {"strength": 0.08}), "linear")},
    # Night: a low tracking shot moving with a jawan who hugs a sandbag past the shaded work lamp over the shaft head;
    # beyond him another jawan's torch beam sweeps the sand; everything else is dark under the stars.
    "night_work": {"look": LOOK_NIGHT, "camera": move(
        cam(P(2.45, 1.05, 6.4), P(0.75, 1.0, 1.8), 30, {"strength": 0.1}),
        cam(P(2.15, 1.0, 6.45), P(0.4, 1.0, 1.85), 30, {"strength": 0.1}), "linear")},
    # Dawn, low on the sand at the spot's rear quarter: the rear wheel's old imprint in the foreground; the truck backs
    # along its ruts, backlit by the rising sun, and its wheel stops dead on the imprint on "exact"; the jawan's palm is up.
    "truck_park": {"look": LOOK_DAWN, "camera": move(
        cam(P(PARK_AT[0] + 3.35, 1.3, PARK_AT[1] + 4.6), P(PARK_AT[0] + 0.8, 0.45, PARK_AT[1] + 1.4), 30, {"strength": 0.1}),
        cam(P(PARK_AT[0] + 3.2, 1.22, PARK_AT[1] + 4.4), P(PARK_AT[0] + 0.85, 0.5, PARK_AT[1] + 1.5), 30, {"strength": 0.1}),
        "linear")},
    # Low and close at the dune's side: the jawans pat the dug heap into a crescent; on "the wind" one leans in and blows,
    # and ripples run across the windward slope in the raking dawn light. A slow push.
    "dune_shape": {"look": LOOK_DAWN, "camera": move(
        cam(DP(2.0, 1.45, -3.0), DP(-0.1, 0.25, 0.1), 30, {"strength": 0.1}),
        cam(DP(1.4, 0.9, -2.35), DP(-0.2, 0.2, -0.3), 30, {"strength": 0.12}), "in_out")},
    # Wide on another shaft head at dawn: two jawans behind it fling a garnished camouflage net; it unfurls toward us,
    # billows and settles over the poles on "nets", the low sun through its holes. A slight crane up.
    "net_drape": {"look": LOOK_DAWN, "camera": move(
        cam(NP(1.9, 1.5, 6.0), NP(0.0, 1.05, -1.2), 26, {"strength": 0.1}),
        cam(NP(1.7, 2.6, 5.6), NP(0.0, 0.75, -0.9), 26, {"strength": 0.1}), "in_out")},
    # Three-quarter front on the lookout: head bent to his raised wrist (the watch, his pencilled list of pass times);
    # on "overhead" his fist shoots up, he looks to the sky, the camera tilts up with him.
    "pass_watch": {"look": LOOK_AFTERNOON, "camera": {
        "from": cam(P(0.72, 1.22, 4.8), P(1.55, 1.12, 6.05), 32, {"strength": 0.12}),
        "to": cam(P(0.66, 1.08, 4.75), P(1.5, 1.42, 6.05), 28, {"strength": 0.1}),
        "ease": "in_out", "start": W("l8a", "overhead", -0.2), "end": W("l8a", "overhead", 0.45)}},
    # Wide on the working site: on "stops" every man freezes mid-motion (mid-stride with a sandbag, mid-swing, mid-sip
    # of chai, on one leg), the lookout's fist still up beyond them; a held beat of stillness.
    "statue": {"look": LOOK_AFTERNOON, "hold": 0.6, "camera": move(
        cam(P(0.2, 1.75, 12.6), P(0.6, 0.95, 5.6), 28, {"strength": 0.08}),
        cam(P(0.2, 1.72, 12.3), P(0.6, 0.95, 5.6), 28, {"strength": 0.08}), "linear")},
    # Low behind the tent-peg stumps: the bowler runs in, the ball bounces once and the batsman lofts it on "cricket";
    # the camera tilts up after it over the bowler's head, the fielders looking up.
    "cricket": {"look": LOOK_AFTERNOON, "camera": {
        "from": cam(P(-1.55, 0.75, 19.6), P(-3.35, 1.0, 8.0), 30, {"strength": 0.1}),
        "to": cam(P(-1.55, 0.8, 19.5), P(-3.3, 4.2, 8.5), 28, {"strength": 0.08}),
        "ease": "in_out", "start": W("l8c", "cricket", 0.0), "end": W("l8c", "cricket", 0.6)}},
    # At the camp, front three-quarter: the jeep brakes to a stop toward us; the scientists in baggy fatigues step out;
    # on "soldiers" one's oversized cap slides down over his glasses; the other side-eyes him.
    "jeep_arrive": {"look": LOOK_AFTERNOON, "camera": move(
        cam(P(-10.6, 1.3, -24.2), P(-6.6, 1.0, -19.0), 28, {"strength": 0.1}),
        cam(P(-10.3, 1.25, -23.6), P(-6.9, 1.05, -19.1), 30, {"strength": 0.1}), "in_out")},
    # Kalam steps out from behind the parked jeep, the last to arrive, white hair spilling from under the perched cap (on
    # "Abdul Kalam"); the camera pushes in to his chest and face: the name tape PRITHVIRAJ on "Prithviraj"; a wink.
    "kalam_tape": {"look": LOOK_AFTERNOON, "camera": {
        "from": cam(P(-9.6, 1.3, -12.9), P(-7.0, 1.0, -16.6), 30, {"strength": 0.1}),
        "to": cam(P(-8.05, 1.02, -15.4), P(-7.32, 0.92, -16.55), 36, {"strength": 0.14}),
        "ease": "in_out", "start": W("l9b", "fake", 0.0), "end": W("l9b", "Prithviraj.", 0.1)}},
    "shaft_dive": {"look": LOOK_DIVE, "camera": cam("range_site.dive_cam", "range_site.dive_look", 24)},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS, "reveals": REVEALS}
