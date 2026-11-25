"""Girgaum, 14 April 1944, ~16:10: a lane of balconied buildings, gold falling from the sky, burning cotton on the roofs
(gags/girgaum.gd "girgaum_set"). The Parsi gentleman's flat is places/flat.py; the street 12 km away is places/city.py.

Frame: the street centre along z (x 0), toward the docks = -z; facades at x +-7; balconies at y 4.5 (and 8.0).
"""
from .common import W, frame, cam, move

P = frame("girgaum", 0.0)

LOOK_GIRGAUM = {
    "base": "day", "time": "16:12",
    "weather": {"fog": 0.0, "clouds": 0.0, "wind": 0.3},
    "sun": {"elevation": 30, "azimuth": 250, "color": "#ffcf96", "energy": 3.2, "softness": 0.6, "visible": False,
            "size": 1.2, "glow": 1.2, "shadows": True},
    "sky": {"top": "#4a6c98", "horizon": "#e8c49a", "clouds": 0.0},
    "ambient": {"color": "#a88e70", "energy": 0.3, "sky": 0.5},
    "fog": {"begin": 120, "end": 4200, "curve": 1.3, "volumetric": 0.002, "color": "#c8a884", "anisotropy": 0.6, "length": 300},
    "glow": {"enabled": True, "intensity": 0.75, "bloom": 0.06, "threshold": 1.05},
    "ssao": True,
    "grade": {"contrast": 1.2, "saturation": 1.08, "vignette": 0.46, "grain": 0.04},
}

GOLD = {"t0": {"line": "l1", "edge": "start", "offset": -4.0}, "hero": W("l1", "gold", 0.0), "near": [5.2, 4.7, -11.0]}

ACTORS = []
# People in the lane and on the balconies, looking up at the sky (the hook), then running from the burning cotton.
for _i, (_ch, _x, _y, _z) in enumerate([("toon_market_man", -2.6, 0.0, -9.0), ("toon_market_woman", 1.8, 0.0, -12.0),
                                         ("toon_market_kid", -1.2, 0.0, -14.5), ("toon_market_vendor", 3.6, 0.0, -18.0),
                                         ("toon_market_elder", -5.6, 4.68, -6.5), ("toon_market_woman_b", 5.6, 4.68, -11.0),
                                         ("toon_market_vendor_b", -5.5, 4.68, -16.0), ("toon_shopkeeper", 5.7, 8.18, -7.5)]):
    ACTORS.append({"id": f"gg_{_i}", "character": _ch, "at": P(_x, _y, _z), "keep_y": True, "facing": P(_x * 0.6, _y + 8.0, -60.0),
                   "action": "idle", "cues": [{"t": 0.0, "expression": "surprised"},
                                              {"t": W("l1", "gold", 0.15 + _i * 0.06), "expression": "shocked", "head": [-25, 0, 0]},
                                              {"t": W("l2a", "Real", 0.1), "expression": "star_eyes" if _i % 3 == 0 else "shocked"},
                                              {"t": W("l17a", "Burning", 0.1 + _i * 0.05), "expression": "panic"}]})

GAGS = [{"id": "girgaum_set", "script": "gags/girgaum.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"variant": "girgaum", "column": True, "gold": GOLD,
                    "cotton": {"t0": W("l17a", "Burning", -0.6)}}}]

SHOTS = {
    # Frame 1 is the money shot: low in the lane, looking up between the balconies at the black column over the docks;
    # gold bars tumble out of the sky catching the sun; on "gold" a bar drops past the lens.
    "hook_rain": {"look": LOOK_GIRGAUM, "camera": move(
        cam(P(0.4, 1.1, 6.0), P(0.0, 22.0, -60.0), 20),
        cam(P(0.3, 1.3, 4.6), P(0.0, 24.0, -60.0), 20), "out")},
    # On the first-floor balcony across: neighbours stare up as bars fall past them into the lane.
    "gold_fall": {"look": LOOK_GIRGAUM, "camera": move(
        cam(P(3.2, 6.2, -15.2), P(5.5, 6.4, -11.0), 30),
        cam(P(3.4, 6.1, -14.6), P(5.5, 6.8, -11.0), 30), "in_out")},
    # Burning cotton bales arc over the rooftops trailing smoke and smash onto the tiles; people run.
    "cotton_rain": {"look": LOOK_GIRGAUM, "camera": move(
        cam(P(1.5, 1.4, 4.0), P(0.0, 18.0, -50.0), 22),
        cam(P(1.2, 1.6, 2.5), P(0.0, 20.0, -50.0), 22), "in_out")},
    # And with it, gold: the hook again, now we know.
    "gold_rain": {"look": LOOK_GIRGAUM, "camera": move(
        cam(P(-0.4, 1.5, 0.0), P(0.0, 26.0, -70.0), 22),
        cam(P(-0.3, 1.2, -1.5), P(0.0, 22.0, -70.0), 22), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
