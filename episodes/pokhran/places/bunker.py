"""The firing control bunker at the range, 11 May 1998 (gags/control.gd, gag id "control").

Frame: the room's floor centre at the origin; the slit window in the front wall at z -2.2 (looking out, -z); the
steel table against it (top 0.76, x -0.95..0.95, z -2.0..-1.2) with the firing panel (the key at (0.3, 0.875, -1.55));
the wall clock at (0.5, 2.06) and the tear-off calendar at (1.22, 1.98) on the front wall above the slot. Cameras stand
inside at +z.

clock_nine: the calendar's page is ripped off on "11th" (10 -> 11), the clock's minute hand clunks onto 9:00 on "nine".
key_turn: macro on the firing key: the operator's hand turns it a quarter on "turns"; the ARM lamps flip red.
"""
from .common import W, frame, cam, move
from . import range as range_place

BUNKER_Z = 41000.0
P = frame("bunker", BUNKER_Z)

# Inside the bunker at midday: no sun or sky, only the white-hot slot and its raking beam through the dust; deep
# shadow everywhere else.
LOOK_BUNKER = dict(range_place.LOOK_DEEP,
                   ambient={"color": "#2a2620", "energy": 0.06, "sky": 0.0},
                   fog={"begin": 300, "end": 2600, "curve": 1.8, "volumetric": 0.02, "color": "#5a4a38",
                        "anisotropy": 0.65, "length": 8},
                   glow={"enabled": True, "intensity": 0.8, "bloom": 0.06, "threshold": 1.0},
                   grade={"contrast": 1.2, "saturation": 0.98, "vignette": 0.5, "grain": 0.05})

CLOCK = [{"shot": "clock_nine", "offset": -0.1}, {"shot": "windsock"}]
KEY = [{"shot": "key_turn", "offset": -0.1}, {"shot": "desert_jumps"}]
BOTH = [CLOCK, KEY]

ACTORS = [
    # The firing officer at the panel (on a stool), his right hand on the key.
    {"id": "fire_op", "character": "toon_sci_fatigues_b", "at": P(0.3, 0, -0.92), "facing": P(0.3, 0, -3.0),
     "action": "sit", "shown": BOTH,
     "cues": [{"t": 0.0, "expression": "determined"},
              {"t": W("l14b", "turns.", -0.3), "expression": "nervous"},
              {"t": W("l14b", "turns.", 0.1), "expression": "determined"}]},
    # The radio man on the field telephone at the other end of the table.
    {"id": "radio_op", "character": "toon_jawan_b", "at": P(-0.62, 0, -0.95), "facing": P(-0.62, 0, -3.0),
     "action": "sit", "shown": BOTH, "cues": [{"t": 0.0, "expression": "deadpan"}]},
    # Beside the calendar: he tears off yesterday on "11th".
    {"id": "cal_man", "character": "toon_barc_sci", "at": P(0.95, 0, -1.98), "facing": P(0.45, 0, -2.3),
     "action": "idle", "shown": [CLOCK],
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": W("l12a", "11th.", 0.1), "expression": "grin"}]},
    # Kalam behind them, arms folded, eyes on the clock.
    {"id": "kalam_bunker", "character": "toon_kalam_fatigues", "at": P(-0.35, 0, 0.1), "facing": P(0.5, 0, -2.2),
     "action": "fold_arms", "shown": BOTH, "cues": [{"t": 0.0, "expression": "determined", "head": [0, 0, -14]}]},
]

GAGS = [{"id": "control", "script": "gags/control.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"clock": [[0.0, "08:59"], [W("l12a", "nine", -0.3), "08:59"], [W("l12a", "nine", 0.02), "09:00"]],
                    "calendar": {"from": "10", "to": "11", "month": "MAY", "tear": W("l12a", "11th.", 0.0),
                                 "hand": "cal_man"},
                    "key": {"turn": W("l14b", "turns.", 0.0), "hand": "fire_op"},
                    "sitters": ["fire_op", "radio_op"]}}]

SHOTS = {
    # Square on the wall over the slot: the clock above the tear-off calendar (stacked for 9:16). A hand comes in and rips
    # off the 10th on "11th" (the page flutters away); a slow push to the clock as the minute hand clunks onto 9:00 on
    # "nine". The slot blazes white below.
    "clock_nine": {"look": LOOK_BUNKER, "camera": move(
        cam(P(0.5, 1.95, -0.2), P(0.5, 1.95, -2.2), 35, {"strength": 0.1}),
        cam(P(0.5, 2.0, -0.85), P(0.5, 2.02, -2.2), 35, {"strength": 0.12}), "out")},
    # Low behind the panel, looking back at the operator: the key big and sharp in the foreground, his face beyond in
    # the light from the slot; a quarter turn and a hard click on "turns", the ARM lamps go red and red light floods his
    # face. A slow creep in.
    "key_turn": {"look": LOOK_BUNKER, "shake": [{"t": W("l14b", "turns.", 0.02), "amount": 0.12}], "camera": move(
        cam(P(0.44, 1.16, -1.98), P(0.3, 0.98, -1.2), 30, {"strength": 0.12}),
        cam(P(0.41, 1.13, -1.92), P(0.3, 0.97, -1.2), 30, {"strength": 0.14}), "out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
