"""The device vault, deep under the range, May 1998 (gags/vault.gd, gag id "vault").

Frame: the chamber's axis at the origin, floor y 0, 14 m across and 16 m high, gantries at 5 m and 10 m. The device
stands on end on its plinth on the axis at (0, 0, 0), about 5 m tall, its sticker facing +z (the camera's side). lid_wh, lid_taj and lid_kumbh
are one continuous camera move; at each cut the sticker changes and the crew is somewhere else, doing something else.
"""
from .common import W, frame, cam, move
from . import range as range_place

VAULT_Z = 33000.0
P = frame("bunker", VAULT_Z)

DEV = (0.0, 0.0, 0.0)
WH = [{"shot": "lid_wh", "offset": -0.1}, {"shot": "lid_taj"}]
TAJ = [{"shot": "lid_taj"}, {"shot": "lid_kumbh"}]
KUM = [{"shot": "lid_kumbh"}, W("l12a", offset=0.0)]

# Underground: no sun or sky; hard work lights, the cold shaft of light from the opening, a haze for the beams, the
# sparks glowing. Deep contrast.
LOOK_VAULT = dict(range_place.LOOK_DEEP,
                  ambient={"color": "#12151c", "energy": 0.012, "sky": 0.0},
                  fog={"begin": 300, "end": 2600, "curve": 1.8, "volumetric": 0.06, "color": "#15171b",
                       "anisotropy": 0.7, "length": 24},
                  glow={"enabled": True, "intensity": 1.1, "bloom": 0.1, "threshold": 0.85},
                  grade={"contrast": 1.3, "saturation": 0.92, "vignette": 0.7, "grain": 0.06})

STICKERS = "library/logos/pokhran/generated/"
WELDERS = [[-3.0, 10.35, -5.3], [4.3, 10.35, -4.5], [-5.6, 5.35, -2.4]]


def crew(tag, window, people):
    """people: [(character, x, z, action, facing (x, z), expression, extra), ...] on the floor (or y from extra)."""
    out = []
    for i, (ch, x, z, action, face, expr, extra) in enumerate(people):
        y = extra.get("y", 0.0)
        a = {"id": f"vt_{tag}{i}", "character": ch, "at": P(x, y, z), "facing": P(face[0], y, face[1]),
             "action": action, "shown": [window], "cues": [{"t": 0.0, "expression": expr}]}
        if y:
            a["keep_y"] = True
        if "route" in extra:
            a["route"] = extra["route"]
        if "head" in extra:
            a["cues"][0]["head"] = extra["head"]
            a["cues"][0]["head_turn"] = 0.01
        out.append(a)
    return out


ACTORS = []
# The device stands on the chamber's axis (5 m tall on its plinth, radius 1.5). The camera stands at +z looking -z and
# arcs from x 0.9 to -0.9: the crew at the plinth's foot flank the device (never between the lens and the casing), the
# carriers cross behind it, the welders work the gantries above.
# White House: two engineers checking the device on clipboards, one at the junction box, a jawan carrying a crate across
# behind, welders on the gantries.
ACTORS += crew("wh", WH, [
    ("toon_sci_fatigues_a", -0.75, 2.35, "idle", (0.0, 0.0), "thinking", {}),
    ("toon_barc_sci", 1.95, 2.0, "idle", (0.0, 0.0), "determined", {}),
    ("toon_jawan_c", -2.0, -1.25, "fix", (-2.4, -2.0), "effort", {}),
    ("toon_jawan_a", -3.8, -3.1, "idle", (3.4, -3.3), "effort",
     {"route": {"via": [P(3.4, 0, -3.3)], "gait": "walk", "start": {"shot": "lid_wh", "offset": -0.5}}}),
    ("toon_jawan_d", -2.9, -5.0, "crouch", (-3.0, -6.5), "effort", {"y": 10.06}),
    ("toon_jawan_b", 4.0, -4.1, "crouch", (4.6, -5.6), "effort", {"y": 10.06}),
])
# Taj Mahal: the crew has moved round: the clipboards swapped sides, a jawan hauling a crate the other way, a scientist
# on the stairs, someone checking the plinth.
ACTORS += crew("tj", TAJ, [
    ("toon_sci_fatigues_a", 1.25, 2.3, "idle", (0.0, 0.0), "determined", {}),
    ("toon_barc_sci", -1.3, 2.2, "idle", (0.0, 0.0), "thinking", {}),
    ("toon_jawan_c", 3.6, -2.6, "idle", (-3.4, -3.0), "effort",
     {"route": {"via": [P(-3.4, 0, -3.0)], "gait": "walk", "start": {"shot": "lid_taj", "offset": -0.3}}}),
    ("toon_sci_fatigues_b", -6.0, -0.6, "idle", (-5.6, 1.5), "nervous", {"y": 3.1}),
    ("toon_jawan_d", -3.1, -5.1, "crouch", (-3.0, -6.5), "effort", {"y": 10.06}),
    ("toon_jawan_b", 1.7, -1.1, "fix", (1.1, -0.8), "determined", {}),
])
# Kumbhkaran: the shift goes on: new positions again; and one jawan has fallen asleep against the plinth, like the giant
# (front right of the device, clear of the lens's line to it).
ACTORS += crew("km", KUM, [
    ("toon_sci_fatigues_a", -2.15, 0.85, "idle", (0.0, 0.0), "side_eye", {}),
    ("toon_barc_sci", 1.35, -1.6, "idle", (0.0, 0.0), "determined", {}),
    ("toon_jawan_c", 1.0, 1.7, "sit", (1.6, 3.0), "sleepy", {"head": [24, 0, 12]}),
    ("toon_jawan_a", 3.0, -3.2, "idle", (-3.0, -3.6), "effort",
     {"route": {"via": [P(-3.0, 0, -3.6)], "gait": "walk", "start": {"shot": "lid_kumbh", "offset": -0.4}}}),
    ("toon_jawan_d", 4.2, -4.3, "crouch", (4.6, -5.6), "effort", {"y": 10.06}),
    ("toon_sci_fatigues_b", -2.0, -1.25, "fix", (-2.4, -2.0), "thinking", {}),
])

GAGS = [{"id": "vault", "script": "gags/vault.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"stickers": [[0.0, STICKERS + "sticker_white_house.png"],
                                 [{"shot": "lid_taj"}, STICKERS + "sticker_taj_mahal.png"],
                                 [{"shot": "lid_kumbh"}, STICKERS + "sticker_kumbhkaran.png"]],
                    "welders": WELDERS,
                    "clipboards": ["vt_wh0", "vt_wh1", "vt_tj0", "vt_tj1", "vt_tj3", "vt_km0", "vt_km1"],
                    "crates": ["vt_wh3", "vt_tj2", "vt_km3"],
                    "lift": [[{"shot": "lid_wh"}, 0.2], [W("l12a", offset=0.0), 7.0]]}}]

# One continuous move round the device, low and looking up at it (the gantries and the falling sparks above it).
_LOOK = P(0.0, 3.0, 0.0)
_K = [cam(P(0.9, 1.3, 6.0), _LOOK, 28, {"strength": 0.1}),
      cam(P(0.3, 1.28, 6.05), _LOOK, 28, {"strength": 0.1}),
      cam(P(-0.3, 1.26, 6.05), _LOOK, 28, {"strength": 0.1}),
      cam(P(-0.9, 1.24, 6.0), _LOOK, 28, {"strength": 0.1})]

SHOTS = {
    # Underground, sparks raining from the welders on the gantries, the device stood on end in its pool of work light:
    # "White House" on its sticker; engineers on clipboards; one continuous arc through the three lines.
    "lid_wh": {"look": LOOK_VAULT, "camera": move(_K[0], _K[1], "linear")},
    # The same move: the sticker is now the Taj Mahal, the crew elsewhere, a crate going the other way.
    "lid_taj": {"look": LOOK_VAULT, "camera": move(_K[1], _K[2], "linear")},
    # Kumbhkaran: the sleeping giant on the sticker; a jawan asleep against the plinth.
    "lid_kumbh": {"look": LOOK_VAULT, "camera": move(_K[2], _K[3], "out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
