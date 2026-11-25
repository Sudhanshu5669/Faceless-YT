"""A street 12 km from the docks (Dadar), 16:06: the shockwave arrives (gags/girgaum.gd, variant "dadar").

Frame: as Girgaum but wider (facades at x +-10); the shop window at (-9.7, 1.9, -14); the docks toward -z.
"""
from .common import W, frame, cam, move
from .girgaum import LOOK_GIRGAUM

P = frame("city", 0.0)

ACTORS = []
for _i, (_ch, _x, _z, _f) in enumerate([("toon_market_man", -4.0, -9.0, (-4.0, -60.0)), ("toon_market_woman", 2.5, -12.0, (2.0, -60.0)),
                                         ("toon_shopkeeper", -8.2, -15.5, (-2.0, -14.0))]):
    ACTORS.append({"id": f"dd_{_i}", "character": _ch, "at": P(_x, 0.0, _z), "keep_y": True, "facing": P(_f[0], 0.0, _f[1]), "action": "idle",
                   "cues": [{"t": 0.0, "expression": "neutral"},
                            {"t": W("l16a", "Windows", 0.0), "expression": "shocked", "facing": P(_x, 0.0, -80.0)},
                            {"t": W("l16a", "shatter", 0.05), "expression": "panic"}]})

GAGS = [{"id": "city_set", "script": "gags/girgaum.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"variant": "dadar", "column": True, "shock": W("l16a", "shatter")}}]

REVEALS = [
    {"id": "n_km12", "t": W("l16a", offset=0.05), "until": {"shot": "shimla_town"}, "at": P(-4.0, 5.6, -16.0), "size": 1.1,
     "counter": {"from": 0, "to": 12, "suffix": " KM", "land": W("l16a", "twelve", 0.1), "label": "AWAY"}, "sound": "ding"},
]

SHOTS = {
    # Low on the far side of the street: the shop's plate-glass window; the shockwave's dust front rolls up the road
    # and the window bursts on "shatter"; the sign swings, people duck.
    "shockwave_roofs": {"look": LOOK_GIRGAUM, "shake": [{"t": W("l16a", "shatter"), "amount": 0.35}], "camera": move(
        cam(P(5.0, 1.4, -6.0), P(-7.0, 2.2, -16.0), 26),
        cam(P(4.6, 1.3, -6.8), P(-7.5, 2.0, -15.0), 26), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "reveals": REVEALS, "shots": SHOTS}
