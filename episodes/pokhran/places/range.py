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
     "shown": [CRICKET], "cues": [{"t": 0.0, "expression": "determined", "head": [8, 74, 0], "head_turn": 0.01},
                                  {"t": W("l8c", "cricket", 0.05), "expression": "grin", "head": [-32, 28, 0], "head_turn": 0.35}]},
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
# Scene-time plan (the shot starts 0.2 s before l9a): it charges in; slow motion (x0.2) from l9a+0.05 to +0.3 while it
# hops past the lens and the driver winks at us (1.25 s on screen); back to speed for the slide, stopping at l9a+0.8;
# the jolt drops the driver's cap. After the slow motion the scene clock runs 1.0 s behind the narration.
SLOW = {"from": W("l9a", offset=0.05), "to": W("l9a", offset=1.3), "rate": 0.2}   # 1.25 s on screen = 0.25 s of action
JEEP_STOP = W("l9a", offset=0.8)
RIDE = [W("l9a", offset=-1.6), {"shot": "kalam_tape", "offset": 0.0}]    # in the jeep for this shot
OUT = [{"shot": "kalam_tape", "offset": 0.05}, W("l10a", offset=0.0)]    # out of it (off-screen) by kalam_tape
ACTORS += [
    # The scientists ride in: one drives like a maniac (he winks at us in slow motion), the other hangs on.
    {"id": "sci_ride1", "character": "toon_sci_fatigues_a", "at": P(-5.64, 0, -19.1), "facing": P(-5.64, 0, -30.0),
     "action": "drive", "shown": [RIDE],
     "cues": [{"t": 0.0, "expression": "grin"},
              {"t": W("l9a", offset=0.08), "expression": "wink", "head": [-6, -90, 0], "head_turn": 0.08},
              {"t": W("l9a", offset=0.33), "expression": "grin", "head": [0, 0, 0], "head_turn": 0.2},
              {"t": W("l9a", offset=0.82), "expression": "surprised"}]},
    {"id": "sci_ride2", "character": "toon_sci_fatigues_b", "at": P(-6.36, 0, -19.1), "facing": P(-6.36, 0, -30.0),
     "action": "sit", "shown": [RIDE],
     "cues": [{"t": 0.0, "expression": "panic"}, {"t": W("l9a", offset=0.85), "expression": "side_eye", "head": [0, 40, 0], "head_turn": 0.3}]},
    {"id": "sci_f1", "character": "toon_sci_fatigues_a", "at": P(-6.85, 0, -19.05), "facing": P(-8.2, 0, -19.6),
     "action": "idle", "shown": [OUT], "cues": [{"t": 0.0, "expression": "nervous"},
                                {"t": W("l9a", "soldiers", 0.05), "expression": "surprised"}]},
    {"id": "sci_f2", "character": "toon_sci_fatigues_b", "at": P(-8.4, 0, -18.4), "facing": P(-10.6, 0, -24.2),
     "action": "idle", "shown": [OUT], "cues": [{"t": 0.0, "expression": "shocked"}, {"t": W("l9a", "dressed", 0.2), "expression": "deadpan"},
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

# convoy (1998, dawn): opens on EXACTLY an32_land's last frame (the same device-relative camera, in the truck's frame),
# then pulls back through the canvas, up and out: four canopy trucks rolling across the desert in their dust.
from .common import DEVICE_END_CAM as _DE, DEVICE_END_LOOK as _DL, DEVICE_END_LENS as _DLENS
CONVOY = [{"shot": "convoy", "offset": -0.1}, W("l11a", offset=0.0)]
# The match-cut camera in the carrying truck's frame (the device faces aft: the offsets turned 180 degrees about y), and
# the end of a straight dolly back along its line of sight, PULL metres out.
_CV0 = (-0.9 - _DE[0], 1.28 + _DE[1], -_DE[2])
_CVL = (-0.9 - _DL[0], 1.28 + _DL[1], -_DL[2])
_D = [_CVL[i] - _CV0[i] for i in range(3)]
_N = sum(v * v for v in _D) ** 0.5
PULL = 34.0
_CV_CAM1 = [round(_CV0[i] - _D[i] / _N * PULL, 3) for i in range(3)]
_CV_LOOK1 = [round(_CVL[i] - _D[i] / _N * PULL, 3) for i in range(3)]

# cage_lower (1998, night): a lowering yard. Three shaft heads in depth, each cage going down on "down"; a busy camp
# round the hero rig. Layout in (right, forward) metres from the hero shaft LOW_A, in the camera's frame.
LOW_A = (30.0, 30.0)
LOW_CAM = (22.0, 44.0)
_ld = (LOW_A[0] - LOW_CAM[0], LOW_A[1] - LOW_CAM[1])
_ln = (_ld[0] ** 2 + _ld[1] ** 2) ** 0.5
_LF = (_ld[0] / _ln, _ld[1] / _ln)          # forward (away from the camera)
_LR = (-_LF[1], _LF[0])                       # right


def LW(right, fwd):
    """A world (x, z) at (right, forward) metres from the hero shaft."""
    return (round(LOW_A[0] + _LR[0] * right + _LF[0] * fwd, 3), round(LOW_A[1] + _LR[1] * right + _LF[1] * fwd, 3))


def LP(right, fwd, y=0.0):
    x, z = LW(right, fwd)
    return P(x, y, z)


def _off(right, fwd):
    """An offset (x, z) in world axes for (right, forward)."""
    return [round(_LR[0] * right + _LF[0] * fwd, 3), round(_LR[1] * right + _LF[1] * fwd, 3)]


CAGE = [{"shot": "cage_lower", "offset": -0.1}, W("l11b", offset=0.0)]
DOWN = W("l11a", "down", 0.0)


def _yaw_to(fr, to):
    import math
    dx, dz = to[0] - fr[0], to[1] - fr[1]
    return round(math.degrees(math.atan2(-dz, dx)), 1)    # vehicle +x forward


ACTORS += [
    # The guides, hands to the cage as it goes in; the officer calling it down; the scientist watching it go.
    {"id": "cg_guide1", "character": "toon_jawan_b", "at": LP(-1.0, -1.25), "facing": LP(0, 0), "action": "interact",
     "shown": [CAGE], "cues": [{"t": 0.0, "expression": "effort"}]},
    {"id": "cg_guide2", "character": "toon_jawan_c", "at": LP(1.05, -1.1), "facing": LP(0, 0), "action": "interact",
     "shown": [CAGE], "cues": [{"t": 0.0, "expression": "determined"}]},
    {"id": "cg_officer", "character": "toon_jawan_d", "at": LP(-2.4, -2.4), "facing": LP(0, 0.4), "action": "call_out",
     "shown": [CAGE], "cues": [{"t": 0.0, "expression": "determined"}]},
    {"id": "cg_sci", "character": "toon_sci_fatigues_b", "at": LP(1.7, -2.7), "facing": LP(0, 0), "action": "idle",
     "shown": [CAGE], "cues": [{"t": 0.0, "expression": "nervous", "head": [-22, 0, 0], "head_turn": 0.01},
                               {"t": DOWN, "expression": "determined", "head": [10, 0, 0], "head_turn": 0.6}]},
    # The winch man at the tripod's foot, the radio man calling the next shaft, a torch signalling across the yard.
    {"id": "cg_winch", "character": "toon_jawan_a", "at": LP(2.3, 1.7), "facing": LP(0.8, 0.5), "action": "fix",
     "shown": [CAGE], "cues": [{"t": 0.0, "expression": "effort"}]},
    {"id": "cg_radio", "character": "toon_jawan_a", "at": LP(3.2, 0.6), "facing": LP(1.0, -6.0), "action": "phone",
     "shown": [CAGE], "cues": [{"t": 0.0, "expression": "deadpan"}]},
    {"id": "cg_torch", "character": "toon_jawan_c", "at": LP(-4.2, 3.6), "facing": LP(6.0, 13.0), "action": "torch",
     "shown": [CAGE], "cues": [{"t": 0.0, "expression": "determined"}]},
    # Sandbag carriers crossing between the rigs; a sentry walking his beat in the foreground.
    {"id": "cg_carry1", "character": "toon_jawan_d", "at": LP(-6.5, 6.5), "facing": LP(6.0, 8.0), "action": "idle",
     "route": {"via": [LP(6.0, 8.0)], "gait": "walk_carry", "start": {"shot": "cage_lower", "offset": -1.5}},
     "shown": [CAGE], "cues": [{"t": 0.0, "expression": "effort"}]},
    {"id": "cg_carry2", "character": "toon_jawan_b", "at": LP(-8.0, 7.2), "facing": LP(5.0, 8.8), "action": "idle",
     "route": {"via": [LP(5.0, 8.8)], "gait": "walk_carry", "start": {"shot": "cage_lower", "offset": -0.4}},
     "shown": [CAGE], "cues": [{"t": 0.0, "expression": "effort"}]},
    {"id": "cg_sentry", "character": "toon_jawan_a", "at": LP(-3.6, -5.6), "facing": LP(3.8, -4.7), "action": "idle",
     "route": {"via": [LP(3.8, -4.7)], "gait": "walk", "start": {"shot": "cage_lower", "offset": -0.8}},
     "shown": [CAGE], "cues": [{"t": 0.0, "expression": "deadpan"}]},
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
         "params": {"carry": [{"actor": "jawan_noon", "what": "jerrycans"}, {"actor": "night_bag", "what": "sandbag"},
                              {"actor": "cg_carry1", "what": "sandbag"}, {"actor": "cg_carry2", "what": "sandbag"}],
                    "night": {"on": [NIGHT, CAGE], "lamp": [1.8, 1.6], "torch": ["night_torch", "cg_torch"]},
                    "dune": {"at": [DUNE_AT[0], DUNE_AT[1], 0.0], "scale": 0.7, "shape": [W("l7a", "Shaped", -0.3), W("l7a", "dunes", 0.35)],
                             "blow": W("l7a", "wind", -0.15), "hands": ["dune_a", "dune_b"], "blower": "dune_blow"},
                    "net": {"at": [NET_AT[0], NET_AT[1], 0.0], "size": [7.0, 6.0], "land": W("l7b", "nets", 0.05),
                            "fly": 1.6, "hands": ["net_a", "net_b"]},
                    "watch": {"actor": "lookout", "fist": W("l8a", "overhead", 0.0), "time": "13:47", "show": P(0.72, 1.22, 4.8),
                              "list": ["09:12", "11:30", "13:47", "16:05"]},
                    "chai": ["st_chai"],
                    "cricket": {"bat": "cr_bat", "bowl": "cr_bowl", "release": W("l8c", "cricket", -0.5), "hit": HIT,
                                "stumps": [-3.0, 16.45]},
                    "jeep": {"at": [JEEP_AT[0], JEEP_AT[1], 90.0], "stop": JEEP_STOP, "speed": 15.0, "slide": 70.0,
                             "driver": "sci_ride1", "riders": [["sci_ride2", 0.3, -0.36]],
                             "turn": [W("l9a", offset=0.06), W("l9a", offset=0.33), -30.0],
                             "slip": {"actor": "sci_ride1", "t": W("l9a", offset=0.84)}},
                    "disguise": [{"actor": "kalam_field", "cap": True, "tape": "PRITHVIRAJ"}],
                    "convoy": {"on": [CONVOY], "t0": {"shot": "convoy"}, "start": [40.0, 70.0], "heading": 20.0,
                               "speed": 9.0, "n": 4, "gap": 17.0, "carry": 1,
                               # The device faces aft in the truck: the match-cut offsets turned 180 degrees about y.
                               "cam0": list(_CV0), "look0": list(_CVL),
                               # The pull-back (user, 2026-11-24): straight back along the line of sight, no turning.
                               "cam1": _CV_CAM1, "look1": _CV_LOOK1,
                               "lining_until": {"shot": "convoy", "offset": 0.45}},
                    "lowering": {"on": [CAGE], "down": DOWN,
                                 "shafts": [[LW(0, 0)[0], LW(0, 0)[1], 0.0, _off(2.6, 2.4), DOWN],
                                            [LW(4.5, 12.0)[0], LW(4.5, 12.0)[1], 0.0, _off(-2.6, 1.8), W("l11a", "down", -0.45)],
                                            [LW(-5.0, 22.0)[0], LW(-5.0, 22.0)[1], 0.0, _off(2.8, 1.5), W("l11a", "down", 0.35)]],
                                 # A low sandbag wall and a cable drum in the near foreground (depth, texture, the frame's
                                 # bottom third).
                                 "sandbags": [[*LW(-3.6 + 0.62 * k, 2.6 + 0.05 * (k % 2)), 8.0 * (k % 3) - 8.0, 0.0] for k in range(5)],
                                 "drum": list(LW(3.4, -3.4)),
                                 "trucks": [[LW(-9.5, 9.0)[0], LW(-9.5, 9.0)[1], _yaw_to(LW(-9.5, 9.0), LW(0, 3))],
                                            [LW(12.0, 20.0)[0], LW(12.0, 20.0)[1], _yaw_to(LW(12.0, 20.0), LW(4, 10))]]},
                    "park": {"at": [PARK_AT[0], PARK_AT[1], 90.0], "from": W("l6b", offset=-0.6),
                             "to": W("l6b", "exact", 0.0), "back": 6.5, "actor": "park_jawan"}, "wind": [[0.0, 115.0, 0.55]], "shimmer": 1.0,
                    "tufts": [[2.31, 3.99, 1.15], [3.74, 3.34, 1.0], [1.19, 3.04, 0.9], [3.7, 1.95, 0.85]],
                    "clear": [[4.33, 5.8, 1.8], [3.83, 5.29, 1.6], [-4.5, 9.0, 2.6], [-1.6, 6.5, 1.4], [13.0, -5.0, 5.0], [15.5, 2.5, 1.5], [0.3, 21.0, 2.5], [-1.4, 18.6, 2.2], [-2.6, 14.0, 2.5]],
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

# The lowering, at night: the same moonless-ish night, a thicker haze so the floodlights throw beams; deeper contrast.
LOOK_LOWER = dict(LOOK_NIGHT,
                  moon={"elevation": 28, "azimuth": 30, "color": "#8fa8e0", "energy": 0.45, "visible": False,
                        "shadows": True, "softness": 1.0},
                  fog={"begin": 20, "end": 700, "curve": 1.3, "volumetric": 0.03, "color": "#1c2230",
                       "anisotropy": 0.55, "length": 40},
                  grade={"contrast": 1.2, "saturation": 0.9, "vignette": 0.58, "grain": 0.05})

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
    # From the off side, low: the batsman side-on in profile at his tent-peg stumps, the bowler running in beyond him;
    # tap, backlift, stride and a lofted drive on "cricket"; the camera tilts up after the ball.
    "cricket": {"look": LOOK_AFTERNOON, "camera": {
        "from": cam(P(0.3, 1.1, 21.0), P(-3.6, 1.0, 11.8), 32, {"strength": 0.1}),
        "to": cam(P(0.3, 1.1, 20.9), P(-3.4, 3.8, 10.8), 30, {"strength": 0.08}),
        "ease": "in_out", "start": W("l8c", "cricket", 0.0), "end": W("l8c", "cricket", 0.6)}},
    # At window height by the track: the jeep tears in across the desert, a scientist at the wheel; as it hops past the
    # lens the shot drops into slow motion and he turns to us and winks; back to speed, it handbrake-slides broadside to
    # a stop in a burst of dust (shake) and the jolt drops his oversized cap over his eyes.
    "jeep_arrive": {"look": LOOK_AFTERNOON, "slowmo": SLOW, "shake": [{"t": JEEP_STOP, "amount": 0.35}], "camera": move(
        cam(P(-11.0, 1.5, -12.8), "range_site.jeep", 36, {"strength": 0.08}),
        cam(P(-10.7, 1.45, -13.4), "range_site.jeep", 32, {"strength": 0.1}), "linear")},
    "kalam_tape": {"look": LOOK_AFTERNOON, "camera": {
        "from": cam(P(-9.6, 1.3, -12.9), P(-7.0, 1.0, -16.6), 30, {"strength": 0.1}),
        "to": cam(P(-8.05, 1.02, -15.4), P(-7.32, 0.92, -16.55), 36, {"strength": 0.14}),
        "ease": "in_out", "start": W("l9b", "fake", 0.0), "end": W("l9b", "Prithviraj.", 0.1)}},
    # The match cut from an32_land: the same picture of the strapped device under its work light; then a straight dolly
    # back along the line of sight (no turning), out through the canvas: the device is in a truck, the second of an army
    # convoy rolling across the dawn desert in a long line of dust on "army convoy".
    "convoy": {"look": LOOK_DAWN, "camera": {
        "from": cam("range_site.convoy_cam0", "range_site.convoy_look0", _DLENS, {"strength": 0.12}),
        "to": cam("range_site.convoy_cam1", "range_site.convoy_look1", _DLENS, {"strength": 0.05}),
        "ease": "in_out", "start": {"shot": "convoy", "offset": 0.25}, "end": W("l10b", "convoy.", 0.2)}},
    # Night, serious: just above head height in the lowering yard, looking a little down onto the floodlit collar. The hero cage, a device stood on end inside it,
    # sinks into the shaft on "down" under the sodium floodlight, guides' hands on it; behind, two more rigs lit in the
    # haze lowering theirs; carriers, a radio man, a torch, a sentry, trucks with their headlights on. A slow push; a
    # held beat as it goes.
    "cage_lower": {"look": LOOK_LOWER, "hold": 1.0, "camera": move(
        cam(LP(-1.6, -7.2, 2.3), LP(0.2, 0.6, 1.2), 22, {"strength": 0.08}),
        cam(LP(-1.3, -6.1, 2.15), LP(0.2, 0.6, 1.0), 22, {"strength": 0.1}), "linear")},
    "shaft_dive": {"look": LOOK_DIVE, "camera": cam("range_site.dive_cam", "range_site.dive_look", 24)},
}

# ---- 11 May 1998: the wrong wind, the wait, the turn (windsock, wait_row, wait_clock, wind_turns) ----------------------
import math as _m


_POST_PAD = None    # (x, z, h): the observation post's flat pad (set below, mirrors range.gd post_pad)


def range_ground(x, z):
    """Terrain height at gag-local (x, z): a port of height() in gags/range.gd (keep in step)."""
    raw = _range_ground_raw(x, z)
    if _POST_PAD is None:
        return raw
    d = _m.hypot(x - _POST_PAD[0], z - _POST_PAD[1])
    u = min(1.0, max(0.0, (d - 60.0) / 60.0))
    k = u * u * (3 - 2 * u)
    return _POST_PAD[2] + (raw - _POST_PAD[2]) * k


def _range_ground_raw(x, z):
    ss = lambda a, b, v: (lambda u: u * u * (3 - 2 * u))(min(1.0, max(0.0, (v - a) / (b - a))))
    h = 0.22 * _m.sin(0.11 * x + 0.7) * _m.cos(0.083 * z + 1.3) + 0.12 * _m.sin(0.23 * x - 0.17 * z + 2.1)
    h += 0.05 * _m.sin(0.47 * x + 0.31 * z) + 0.025 * _m.sin(1.3 * x - 0.9 * z + 0.4)
    d = _m.hypot(x, z)
    far = ss(90.0, 420.0, d)
    dn = 0.5 + 0.5 * _m.sin(0.021 * x + 1.7 * _m.sin(0.006 * z) + 0.3)
    h += far * (5.0 * dn ** 3 + 2.0 * _m.sin(0.013 * z + 0.9) * _m.sin(0.017 * x))
    h += ss(700.0, 2200.0, d) * (16.0 + 10.0 * _m.sin(0.004 * x + 2.0) * _m.sin(0.0031 * z))
    h = -0.02 + (h + 0.02) * ss(6.0, 13.2, d)
    tz = 5.6 + 4.0 * _m.sin(x * 0.04 + 0.5)
    dz = abs(z - tz)
    on = 1.0 - ss(60.0, 90.0, abs(x))
    h += (-0.05 * _m.exp(-((dz - 0.85) / 0.15) ** 2) + 0.012 * _m.exp(-(dz / 0.35) ** 2)) * on
    return h


def PG(x, dy, z):
    """A gag-local point dy metres above the sand."""
    return P(x, round(range_ground(x, z) + dy, 3), z)


SOCK = (-7.6, -23.6)                 # the windsock's pole (gags/range.gd SOCK_AT)
DV = (0.75, -0.66)                   # the wrong wind: toward Khetolai (clear of the camp)
VILLAGE = (SOCK[0] + 200 * DV[0], SOCK[1] + 200 * DV[1])
YAW_WRONG = -48.7                    # the sock's heading blowing along DV
YAW_TURNED = 131.3                   # 15:45: the other way, away from the village
TENT = (-18.4, -21.4)            # west of the sock, clear of the parked jeep
TF = (0.622, -0.783)                 # the tent's open front faces this way (the sock off to its front-left)
TX = (-TF[1], TF[0])                 # the tent's local +x in gag-local coordinates


def TL(lx, lz):
    return (TENT[0] + lx * TX[0] + lz * TF[0], TENT[1] + lx * TX[1] + lz * TF[1])


def TLP(lx, dy, lz):
    x, z = TL(lx, lz)
    return PG(x, dy, z)


# The morning of 11 May: the sun low in the east, long shadows, a clean hard light. Noon for the time-lapse.
LOOK_MORNING = dict(LOOK_AFTERNOON, time="09:00",
                    sun={"elevation": 30, "azimuth": 98, "color": "#ffe8c8", "energy": 3.0, "softness": 0.6,
                         "visible": True, "size": 1.3, "glow": 1.3, "shadows": True})
LOOK_NOON = dict(LOOK_AFTERNOON, time="12:30",
                 sun={"elevation": 74, "azimuth": 170, "color": "#fff4e0", "energy": 3.3, "softness": 0.5,
                      "visible": True, "size": 1.2, "glow": 1.0, "shadows": True},
                 ambient={"color": "#c4a884", "energy": 0.4, "sky": 0.6})

TENT_ON = [{"shot": "wait_row", "offset": -0.1}, {"shot": "key_turn"}]
_BENCH = -0.55
_WAITERS = [("toon_sci_fatigues_a", -1.5), ("toon_barc_sci", -0.9), ("toon_kalam_fatigues", -0.3),
            ("toon_chidambaram", 0.3), ("toon_sci_fatigues_b", 0.9), ("toon_jawan_c", 1.5)]
_TW_FROM = W("l13a", offset=0.15)
_TW_TO = W("l13a", "waits.", 0.35)
_TURN = W("l14a", "turns.", -0.1)
for _i, (_ch, _lx) in enumerate(_WAITERS):
    _cues = [{"t": 0.0, "expression": "deadpan" if _i % 2 else "sleepy"},
             # The tumbleweed goes by: every head follows it, in unison.
             {"t": W("l13a", offset=0.2), "head": [6, 38, 0], "head_turn": 0.3},
             {"t": W("l13a", "India", 0.0), "head": [6, -38, 0], "head_turn": 1.1},
             {"t": W("l13a", "waits.", 0.25), "head": [8, 0, 0], "head_turn": 0.5},
             # Six hours: they wilt.
             {"t": W("l13b", "hours.", 0.0), "expression": "sleepy", "head": [18, 0, 10 if _i % 2 else -10], "head_turn": 0.6},
             {"t": W("l13b", "Staring", 0.0), "expression": "deadpan", "head": [2, 22, 0], "head_turn": 0.5},
             # 15:45: the wind turns; they leap up.
             {"t": _TURN, "expression": "shocked", "head": [-10, 0, 0], "head_turn": 0.2},
             {"t": W("l14a", "turns.", 0.25), "action": "jump", "expression": "cheer"}]
    if _ch == "toon_kalam_fatigues":
        # Kalam nods off during the six hours.
        _cues.insert(5, {"t": W("l13b", "hours.", 0.2), "expression": "sleepy", "head": [30, 0, 18], "head_turn": 0.8})
    ACTORS.append({"id": f"wt_{_i}", "character": _ch, "at": TLP(_lx, 0, _BENCH), "facing": TLP(_lx, 0, 6.0),
                   "action": "sit", "shown": [TENT_ON], "cues": _cues})

GAGS.append({"id": "wait_tent", "script": "gags/wait_tent.gd", "t": TENT_ON[0], "until": TENT_ON[1],
             "at": TLP(0, 0, 0), "face": TLP(0, 0, 10.0),
             "params": {"clock": [[0.0, "09:20"], [W("l13b", offset=0.05), "09:20"], [W("l13b", "hours.", 0.3), "15:00"],
                                  [W("l13b", edge="end", offset=0.2), "15:38"], [W("l14a", "turns.", 0.0), "15:45"]],
                        "sitters": [f"wt_{i}" for i in range(6)],
                        "chins": ["wt_0", "wt_3", "wt_5"], "fan": ["wt_1"],
                        "tumbleweed": {"from": _TW_FROM, "to": _TW_TO, "a": [-5.5, 2.9], "b": [5.5, 3.3], "r": 0.4, "hops": 4},
                        "sweep": {"from": W("l13b", offset=0.05), "to": W("l13b", "hours.", 0.35)}}})

_rp = GAGS[0]["params"]
_rp["wind"] = [[0.0, 115.0, 0.55], [W("l12b", "wrong", -0.2), YAW_WRONG, 0.85], [_TURN, YAW_TURNED, 0.8]]
_rp["village_far"] = {"at": list(VILLAGE), "on": [[{"shot": "windsock"}, {"shot": "village_far"}]], "n": 14}

# The windsock camera: upwind of the sock, looking down the wrong wind at the village on the horizon.
_WS_CAM = (SOCK[0] - 25 * DV[0] + 1.0 * 0.66, SOCK[1] - 25 * DV[1] + 1.0 * 0.75)
_WS_CAM_Y = range_ground(*_WS_CAM) + 2.2


def _ahead(cam_xz, cam_y, d, dist, elev_deg):
    return P(cam_xz[0] + d[0] * dist, round(cam_y + dist * _m.tan(_m.radians(elev_deg)), 3), cam_xz[1] + d[1] * dist)


_SOCK_DIR = ((SOCK[0] - _WS_CAM[0]), (SOCK[1] - _WS_CAM[1]))
_n = _m.hypot(*_SOCK_DIR)
_SOCK_DIR = (_SOCK_DIR[0] / _n, _SOCK_DIR[1] / _n)
# wind_turns: low under the sock, looking up past it at the tent.
# Side-on to the wind, so the sock swings in profile: from DV to the other way.
_WT_CAM = (SOCK[0] - 3.6 * 0.66, SOCK[1] - 3.6 * 0.75)
_WT_Y = range_ground(*_WT_CAM) + 0.5
_WT_DIR = (0.66, 0.75)

# Keep the scattered scrub off the tent, its forecourt and the camera spots.
_rp["clear"] = _rp["clear"] + [[*TL(0, 0), 4.5], [*TL(0, 4.5), 3.5], [*_WS_CAM, 2.0], [*_WT_CAM, 1.6]]
# ... and the line of sight from the sock to the village.
_rp["clear"] += [[SOCK[0] + k * DV[0], SOCK[1] + k * DV[1], 7.0] for k in range(10, 130, 10)]

SHOTS.update({
    # Low, upwind of the windsock, the sock big against the morning sky: on "wrong way" a gust whips it round to point
    # straight down the plain at Khetolai on the horizon (huts, cooking smoke), and the lens punches in toward the village.
    "windsock": {"look": LOOK_MORNING, "camera": {
        "from": cam(P(_WS_CAM[0], round(_WS_CAM_Y, 3), _WS_CAM[1]), _ahead(_WS_CAM, _WS_CAM_Y, _SOCK_DIR, 20, 6), 50, {"strength": 0.04}),
        "to": cam(P(_WS_CAM[0], round(_WS_CAM_Y, 3), _WS_CAM[1]), _ahead(_WS_CAM, _WS_CAM_Y, DV, 20, 3.5), 85),
        "ease": "out", "start": W("l12b", "wrong", 0.1), "end": W("l12b", "way.", 0.35)}},
    # Outside the tent's open front, low: a bench packed with bored scientists in the shade, chins on fists, one fanning
    # himself with a file; a tumbleweed bounces across in front and every head follows it, in unison. A slow drift.
    "wait_row": {"look": LOOK_MORNING, "camera": move(
        cam(TLP(1.0, 1.0, 5.8), TLP(0.15, 1.0, _BENCH), 30, {"strength": 0.08}),
        cam(TLP(0.7, 1.0, 5.5), TLP(0.0, 1.0, _BENCH), 30, {"strength": 0.08}), "linear")},
    # Closer, the clock on the back pole over their heads: the time-lapse: its hands whirl 9 -> 3, a sunbeam slides
    # across them, they wilt; Kalam nods off; on "Staring at the wind" they all stare out, dead-eyed.
    "wait_clock": {"look": LOOK_NOON, "camera": move(
        cam(TLP(0.75, 1.3, 3.6), TLP(0.0, 1.55, -2.4), 30, {"strength": 0.1}),
        cam(TLP(0.6, 1.33, 3.0), TLP(0.0, 1.6, -2.4), 30, {"strength": 0.12}), "linear")},
    # Low under the windsock, side-on to the wind, the sock big in profile against the afternoon sky: at 15:45, on
    # "turns", it whips round to blow the other way, away from the village (a gust, a jolt). A small push up the pole.
    "wind_turns": {"look": LOOK_AFTERNOON, "shake": [{"t": _TURN, "amount": 0.15}], "camera": move(
        cam(P(_WT_CAM[0], round(_WT_Y, 3), _WT_CAM[1]), _ahead(_WT_CAM, _WT_Y, _WT_DIR, 10, 34), 24, {"strength": 0.05}),
        cam(P(_WT_CAM[0] + 0.1, round(_WT_Y + 0.1, 3), _WT_CAM[1] + 0.3), _ahead(_WT_CAM, _WT_Y + 0.1, _WT_DIR, 10, 37), 24, {"strength": 0.05}), "linear")},
})

# ---- 15:45, 11 May 1998: Shakti-I. The desert jumps (accurate: underground, no fireball, no mushroom cloud) -----------
# Massive scale (the user, 2026-11-24: "REALLY MASSIVE scale ... EXTREMELY DETAILED"): watched from an observation post a
# kilometre out on a long lens; the team in silhouette behind the parapet in the foreground.
BLAST_T = W("l14c", "jumps.", -0.08)
BLAST_ON = [{"shot": "desert_jumps"}, {"shot": "khetolai_crack"}]
_BJ_DIR = (0.12, 0.993)                       # from the shaft toward the observation post
_BJ_D = 1000.0
_BJ_CAM = (_BJ_DIR[0] * _BJ_D, _BJ_DIR[1] * _BJ_D)
_BJ_POST = (_BJ_DIR[0] * (_BJ_D - 16.0), _BJ_DIR[1] * (_BJ_D - 16.0))
_POST_PAD = (_BJ_POST[0], _BJ_POST[1], _range_ground_raw(*_BJ_POST))
_BJ_Y = range_ground(*_BJ_CAM) + 2.3
_SHOCK = 450.0
_ARRIVE = (_BJ_D - 16.0) / _SHOCK              # scene seconds from the heave to the shock reaching the post
_rp["blast"] = {"t": BLAST_T, "at": [0.0, 0.0], "h": 30.0, "r": 130.0, "shock": _SHOCK, "ring_to": _BJ_D + 150.0,
                "toward": list(_BJ_DIR), "on": [BLAST_ON], "post": {"at": list(_BJ_POST), "face": [0.0, 0.0]}}
_SIDE = (-_BJ_DIR[1], _BJ_DIR[0])
for _i, (_ch, _off) in enumerate([("toon_sci_fatigues_a", -1.35), ("toon_kalam_fatigues", -0.45),
                                  ("toon_chidambaram", 0.45), ("toon_jawan_a", 1.35)]):
    _x = _BJ_DIR[0] * (_BJ_D - 19.0) + _SIDE[0] * _off * 1.3
    _z = _BJ_DIR[1] * (_BJ_D - 19.0) + _SIDE[1] * _off * 1.3
    ACTORS.append({"id": f"obs_{_i}", "character": _ch, "at": P(_x, round(range_ground(_x, _z), 3), _z), "keep_y": True,
                   "facing": P(0.0, round(range_ground(_x, _z), 3), 0.0),
                   "action": "idle", "shown": [[{"shot": "desert_jumps", "offset": -0.05}, {"shot": "khetolai_crack"}]],
                   "cues": [{"t": 0.0, "expression": "determined"},
                            {"t": W("l14c", "jumps.", 0.0), "expression": "shocked", "head": [-14, 0, 0], "head_turn": 0.4},
                            {"t": W("l14c", "jumps.", _ARRIVE - 0.1), "action": "crouch", "expression": "panic"}]})
LOOK_BLAST = dict(LOOK_AFTERNOON, fog={"begin": 400, "end": 9000, "curve": 1.4, "volumetric": 0.0},
                  grade={"contrast": 1.2, "saturation": 1.0, "vignette": 0.5, "grain": 0.04})
SHOTS["desert_jumps"] = {
    # A kilometre out, on a long lens over the team's shoulders at the observation post's parapet: silence; on "jumps"
    # the desert heaves up into a dome that splits into slabs, sand jets out of the cracks, rocks fly, and a column of
    # dust climbs out of the top of the frame (the lens tilts up after it); a base surge rolls out; then the shock comes
    # racing across the plain as a ring of dust and hits the post (shake), the team ducks.
    "look": LOOK_BLAST, "hold": 3.0,
    "slowmo": {"from": W("l14c", "jumps.", -0.08), "to": W("l14c", "jumps.", 0.9), "rate": 0.35},
    "shake": [{"t": W("l14c", "jumps.", -0.08 + _ARRIVE), "amount": 0.9}],
    "camera": {"from": cam(P(_BJ_CAM[0], round(_BJ_Y, 3), _BJ_CAM[1]), P(0.0, 95.0, 0.0), 50),
               "to": cam(P(_BJ_CAM[0], round(_BJ_Y + 0.4, 3), _BJ_CAM[1]), P(0.0, 215.0, 0.0), 50),
               "ease": "in_out", "start": W("l14c", "jumps.", 0.1), "end": W("l14c", "jumps.", 2.6)},
}

# ---- The blast as footage (the user's direction, 2026-11-23): it plays across presser_quote, phones_ring and
# analyst_feed under the narration (each shot a replay of the same moment from another angle), then senator opens on it
# playing on the CIA man's TV (places/desk.py) and pulls back.
# (shot, the next shot, the replay's heave relative to the shot's start): the windows abut, never overlap.
for _shot, _nxt, _off in [("presser_quote", "phones_ring", 0.7), ("phones_ring", "analyst_feed", -0.7),
                          ("analyst_feed", "senator", -0.5)]:
    _rp["blast"]["on"].append([{"shot": _shot}, {"shot": _nxt}, {"shot": _shot, "offset": _off}])
# The TV feed in senator (desk) replays it from the observation post, already towering.
_rp["blast"]["on"].append([{"shot": "senator", "offset": -0.05}, {"shot": "review_drop"}, {"shot": "senator", "offset": -3.2}])

SHOTS.update({
    # The heave from the ground, then the whole column: low on the plain 260 m off, a long crane up and back (to 900 m) as the
    # desert breaks open, sand jets out of the cracks and the dust climbs past us to its crown, 400 m up, in the
    # afternoon sun. Vajpayee's statement plays over it.
    "presser_quote": {"look": LOOK_BLAST, "camera": move(
        cam(P(-240.0, round(range_ground(-240.0, 110.0) + 1.6, 3), 110.0), P(0.0, 18.0, 0.0), 32),
        cam(P(-700.0, 300.0, 560.0), P(0.0, 210.0, 0.0), 32), "in_out")},
    # Straight down from 1.4 km: the shock ring racing out across the desert, the column boiling up at us.
    "phones_ring": {"look": LOOK_BLAST, "camera": move(
        cam(P(0.0, 1400.0, 40.0), P(0.0, 0.0, -20.0), 35),
        cam(P(0.0, 1250.0, 40.0), P(0.0, 0.0, -20.0), 35), "linear")},
    # Low on the plain 330 m out, a khejri beside us: the base surge comes rolling across the sand and swallows us.
    "analyst_feed": {"look": LOOK_BLAST, "shake": [{"t": {"shot": "analyst_feed", "offset": 1.7}, "amount": 0.5}],
                     "camera": move(cam(P(300.0, round(range_ground(300.0, 140.0) + 1.3, 3), 140.0), P(0.0, 60.0, 0.0), 26),
                                    cam(P(298.0, round(range_ground(298.0, 139.0) + 1.5, 3), 139.0), P(0.0, 110.0, 0.0), 26), "linear")},
})

# ---- two_more: 13 May 1998, two more underground tests (Shakti-IV and V): Kalam at the observation post in safety
# goggles; each lens reflects the desert heaving (accurate: dust domes, no fireball).
_K2 = (_BJ_DIR[0] * (_BJ_D - 19.0) + _SIDE[0] * 0.2, _BJ_DIR[1] * (_BJ_D - 19.0) + _SIDE[1] * 0.2)
_K2_Y = range_ground(*_K2)
ACTORS.append({"id": "kalam_gog", "character": "toon_kalam_fatigues", "at": P(_K2[0], round(_K2_Y, 3), _K2[1]), "keep_y": True,
               "facing": P(0.0, round(_K2_Y, 3), 0.0), "action": "idle",
               "shown": [[{"shot": "two_more", "offset": -0.1}, {"shot": "lok_sabha"}]],
               "cues": [{"t": 0.0, "expression": "determined"},
                        {"t": W("l18a", "more.", 0.0), "expression": "grin"}]})
_rp["blast"]["on"].append([{"shot": "two_more"}, {"shot": "lok_sabha"}, W("l18a", "more.", -0.55)])
_rp["goggles"] = {"actor": "kalam_gog", "on": [[{"shot": "two_more", "offset": -0.1}, {"shot": "lok_sabha"}]],
                  "looks": [[70.0, 30.0, 0.0], [-70.0, 30.0, 0.0]], "fov": 38.0, "r": 0.34, "up": 0.24}
_KC0 = (_K2[0] - _BJ_DIR[0] * 1.9, _K2[1] - _BJ_DIR[1] * 1.9)
_KC1 = (_K2[0] - _BJ_DIR[0] * 1.1, _K2[1] - _BJ_DIR[1] * 1.1)
SHOTS["two_more"] = {
    # Close on Kalam at the observation post, goggles on, the site behind us: on "two more" the desert heaves again and
    # the dust climbs in both lenses; he grins. A slow push into the goggles; the shock arrives as a jolt.
    "look": LOOK_BLAST, "shake": [{"t": W("l18a", "more.", 0.2), "amount": 0.25}],
    "camera": move(cam(P(_KC0[0], round(_K2_Y + 1.3, 3), _KC0[1]), "kalam_gog.head", 40, {"strength": 0.15}),
                   cam(P(_KC1[0], round(_K2_Y + 1.32, 3), _KC1[1]), "kalam_gog.head", 40, {"strength": 0.18}), "in_out")}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS, "reveals": REVEALS}
