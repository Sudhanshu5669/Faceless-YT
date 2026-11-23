"""The Prime Minister's office, South Block (gags/pm_office.gd, gag id "pmo").

Frame: the desk's centre at the origin, its top at 0.77; the PM sits at (0, 0, -0.78) facing +z (visitors);
the arched window in the -x wall (the PM's right), the room 7.4 m wide, 4.3 m high, back wall at z -2.7.
December 1995 (Rao) and 1998 (Vajpayee) use the same room.
"""
from .common import W, frame, cam, move

OFFICE_Z = 9000.0
P = frame("office", OFFICE_Z)

# A winter afternoon in Delhi: a low sun (about 20 degrees) streaming through the arched window from the -x side,
# a little dust in the beam, a cool tube light on the far wall, the room otherwise dim.
LOOK_1995 = {
    "base": "night_fog", "time": "15:00", "ssao": True,
    "weather": {"fog": 0.0, "clouds": 0.0},
    "sun": {"elevation": 20, "azimuth": 258, "color": "#ffd9a8", "energy": 3.4, "shadows": True, "softness": 0.6,
            "visible": False},
    "moon": {"energy": 0, "visible": False},
    "ambient": {"color": "#6a5a4a", "energy": 0.16},
    "sky": {"top": "#9ab4d0", "horizon": "#e8dcc4", "stars": 0, "clouds": 0},
    "fog": {"begin": 200, "end": 400, "volumetric": 0.018, "color": "#d8c4a4", "anisotropy": 0.7, "length": 14},
    "ground_fog": {"density": 0.0},
    "glow": {"enabled": True, "intensity": 0.7, "bloom": 0.05, "threshold": 1.1},
    "grade": {"contrast": 1.14, "saturation": 0.98, "vignette": 0.42, "grain": 0.04},
    "practical_lights": {"level": 0},
}

R1995 = [W("l4a", offset=-0.8), W("l4d", offset=-0.05)]

ACTORS = [
    {"id": "rao", "character": "toon_rao", "at": P(0, 0, -0.78), "facing": P(0, 0, 3.0), "action": "sit",
     "shown": [R1995],
     "cues": [{"t": 0.0, "expression": "nervous"},
              {"t": W("l4a", "Times", 0.02), "expression": "surprised"},
              {"t": W("l4a", "Times", 0.45), "expression": "nervous"}]},
]

GAGS = [{"id": "pmo", "script": "gags/pm_office.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"sitter": "rao",
                    "paper": {"slap": W("l4a", "Times", 0.0),
                              "folio": "THE NEW YORK TIMES, FRIDAY, DECEMBER 15, 1995",
                              "headline": ["U.S. Suspects India", "Prepares To Conduct", "Nuclear Test"],
                              "byline": "By TIM WEINER",
                              "dateline": "WASHINGTON, Dec. 14 —"}}}]

SHOTS = {
    # Insert from above the desk, the visitors' side: an aide's arm slaps the folded New York Times down on
    # "Times", close and readable; then the camera rises and backs off (eased in) to Rao behind the desk, staring at
    # it, the paper in the foreground.
    "nyt_slap": {"look": LOOK_1995, "camera": move(
        cam(P(0.1, 1.5, 0.66), P(0.05, 0.78, 0.0), 30, {"strength": 0.12}),
        cam(P(0.1, 1.98, 1.08), P(0.04, 0.98, -0.38), 30, {"strength": 0.12}), "in"),
        "shake": [{"t": W("l4a", "Times", 0.0), "amount": 0.15}]},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
