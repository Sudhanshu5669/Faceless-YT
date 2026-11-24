"""The Lok Sabha chamber, Parliament House, New Delhi, 27 May 1998 (gags/lok_sabha.gd, gag id "lok_sabha").

Frame: the well's centre at the origin; the Speaker's dais at z -8.5 facing +z; seven tiers of benches arc round the
centre (angle 0 = +z) between -150 and +150 degrees, tier i at radius 6 + 1.5 i on a floor 0.42 i high. The treasury
benches are on the Speaker's right (-x).

lok_sabha: "On May 27th, Vajpayee tells Parliament: India is now a nuclear weapon state.": Vajpayee stands at his
front-row desk on the treasury side and speaks; on "nuclear weapon state" the House thumps its desks.
"""
import math
from .common import W, frame, cam, move
from . import range as range_place

LS_Z = 73000.0
P = frame("bunker", LS_Z)      # the bunker bay (see the handoff: spare anchors)

LOOK_LS = dict(range_place.LOOK_DEEP,
               ambient={"color": "#b09070", "energy": 0.45, "sky": 0.0},
               fog={"begin": 200, "end": 2600, "curve": 1.8, "volumetric": 0.0},
               glow={"enabled": True, "intensity": 0.7, "bloom": 0.06, "threshold": 1.0},
               grade={"contrast": 1.12, "saturation": 1.02, "vignette": 0.42, "grain": 0.035})

LS = [{"shot": "lok_sabha", "offset": -0.1}, {"shot": "kalam_cap"}]
THUMP = W("l18b", "nuclear", 0.0)


def seat(tier, deg, out=0.1):
    a = math.radians(deg)
    r = 6.0 + 1.5 * tier + out
    return (round(math.sin(a) * r, 3), round(0.42 * tier, 3), round(math.cos(a) * r, 3))


VJ = seat(0, -108, 0.15)
ACTORS = [
    {"id": "vajpayee_ls", "character": "toon_vajpayee", "at": P(*VJ), "keep_y": True, "facing": P(0.0, VJ[1], -4.0),
     "action": "talk", "shown": [LS], "cues": [{"t": 0.0, "expression": "determined"},
                                               {"t": W("l18b", "state.", 0.1), "expression": "smug"}]},
    {"id": "speaker_ls", "character": "toon_official", "at": P(0.0, 1.2, -8.15), "keep_y": True, "facing": P(0.0, 1.2, 3.0),
     "action": "sit", "shown": [LS], "cues": [{"t": 0.0, "expression": "neutral"}]},
]
_MPS = ["toon_market_elder", "toon_market_man", "toon_shopkeeper", "toon_farmer", "toon_market_woman", "toon_official",
        "toon_market_vendor", "toon_market_woman_b", "toon_partner", "toon_market_vendor_b", "toon_isro_ctrl_c", "toon_scientist"]
_THUMPERS = []
_k = 0
for _tier, _degs in [(0, [-140, -125, -90, -75, -60, 60, 80, 100, 125]), (1, [-135, -115, -100, -85, -65, 70, 95, 120]),
                     (2, [-128, -110, -92, -70, 65, 90, 112]), (3, [-120, -100, -80, 80, 105])]:
    for _d in _degs:
        _x, _y, _z = seat(_tier, _d)
        _id = f"mp_{_k}"
        ACTORS.append({"id": _id, "character": _MPS[_k % len(_MPS)], "at": P(_x, _y, _z), "keep_y": True,
                       "facing": P(0.0, _y, 0.0), "action": "sit", "shown": [LS],
                       "cues": [{"t": 0.0, "expression": "neutral" if _k % 3 else "thinking"},
                                {"t": THUMP, "expression": "cheer" if _d < 0 else "shocked"}]})
        if _d < 0 or _k % 2 == 0:
            _THUMPERS.append(_id)
        _k += 1

GAGS = [{"id": "lok_sabha", "script": "gags/lok_sabha.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"thump": {"from": THUMP, "ids": _THUMPERS}}}]

SHOTS = {
    # From the gallery across the House, a slow crane down into the well, ending in front of Vajpayee standing at his desk
    # on the treasury benches (the tiers rising behind him); on "nuclear weapon state" the benches thump their desks.
    "lok_sabha": {"look": LOOK_LS, "camera": move(
        cam(P(8.5, 7.2, 8.0), P(VJ[0], 1.4, VJ[2]), 30, {"strength": 0.06}),
        cam(P(-3.5, 1.45, -3.7), P(VJ[0], 1.35, VJ[2]), 32, {"strength": 0.12}), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
