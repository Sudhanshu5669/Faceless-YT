"""Gale Crater, Mars (gags/gale_crater.gd, gag id "gale") and the tweet cards (library post_card).

Tweet texts are faithful to the reported posts of 24 Sep 2014 (see script.md, line 18): Curiosity's opened
"Namaste, @MarsOrbiter!" and congratulated ISRO on reaching Mars orbit; MOM replied
"Howdy @MarsCuriosity ? Keep in touch. I'll be around." Avatars: the agencies' logos (stand-ins for the
accounts' profile pictures).
"""
from .common import W, frame, cam, move
from . import space

MARS_Z = 90000.0
P = frame("mars", MARS_Z)

LOOK = {
    "base": "day", "time": "14:00", "ssao": True,
    "weather": {"fog": 0.0, "clouds": 0.06},
    "sun": {"elevation": 32, "azimuth": 140, "energy": 2.0, "color": "#ffe2c0", "shadows": True, "softness": 0.6,
            "visible": True, "size": 1.0, "glow": 0.6},
    "moon": {"energy": 0, "visible": False},
    "ambient": {"color": "#c08a62", "energy": 0.55},
    "sky": {"top": "#b9865c", "horizon": "#e2b78c", "stars": 0, "clouds": 0.06, "cloud_color": "#d9b08a"},
    "fog": {"begin": 40, "end": 900, "color": "#c99a70", "volumetric": 0.0},
    "ground_fog": {"density": 0.004, "height": 3.0, "falloff": 0.3, "color": "#c08e66"},
    "glow": {"enabled": True, "intensity": 0.5, "bloom": 0.03, "threshold": 1.2},
    "grade": {"contrast": 1.08, "saturation": 0.95, "vignette": 0.25, "grain": 0.05},
    "practical_lights": {"level": 0},
}

CURIOSITY_TWEET = {"name": "Curiosity Rover", "handle": "@MarsCuriosity", "verified": True,
                   "text": "Namaste, @MarsOrbiter! Congratulations to @ISRO and India's first interplanetary mission upon achieving Mars orbit.",
                   "date": "24 Sep 2014", "avatar": "library/logos/nasa-meatball.svg", "width": 2.0}
MOM_TWEET = {"name": "ISRO's Mars Orbiter", "handle": "@MarsOrbiter", "verified": True,
             "text": "Howdy @MarsCuriosity ? Keep in touch. I'll be around.",
             "date": "24 Sep 2014", "avatar": "library/logos/isro.svg", "width": 2.4}

CAM_AT = P(2.6, 0.9, 6.2)

GAGS = [
    {"id": "gale", "script": "gags/gale_crater.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"hail": [W("l18a", "Namaste", -0.1), W("l18a", edge="end")], "mom": [W("l18a"), W("l18b", edge="end")]}},
    {"id": "tweet_curiosity", "script": "library:post_card", "t": W("l18a", "tweets", -0.05), "until": W("l18b"),
     "at": P(1.2, 2.55, 2.6), "face": CAM_AT, "params": CURIOSITY_TWEET},
    {"id": "tweet_mom", "script": "library:post_card", "t": W("l18b", "reply", 0.0), "until": W("l19a"),
     "at": space.A("mom_m", 1.8, 3.4, 3.2), "face": space.A("mom_m", 6.5, 3.2, 10.0), "params": MOM_TWEET},
]

SHOTS = {
    "curiosity_wave": {"look": LOOK, "camera": move(
        cam(CAM_AT, P(0.3, 1.6, 0), 26), cam(P(2.3, 0.8, 5.6), P(0.2, 2.6, 0.2), 26), "in_out")},
}

PLACE = {"gags": GAGS, "actors": [], "shots": SHOTS}
