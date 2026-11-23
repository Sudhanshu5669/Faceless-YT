"""The Prime Minister's office, South Block (gags/pm_office.gd, gag id "pmo").

Frame: the desk's centre at the origin, its top at 0.77; the PM sits at (0, 0, -0.78) facing +z (visitors);
the arched window in the -x wall (the PM's right), the room 7.4 m wide, 4.3 m high, back wall at z -2.7.
December 1995 (Rao) and 1998 (Vajpayee) use the same room.
"""
from .common import W, frame, cam, move
from . import range as range_place

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

R1995 = [W("l4a", offset=-0.8), W("l4d", offset=0.05)]

V1998 = [W("l5a", offset=-0.8), W("l5c", offset=-0.02)]

ACTORS = [
    # 1998: Vajpayee in the same chair (sworn in March 1998).
    {"id": "vajpayee_pmo", "character": "toon_vajpayee", "at": P(0, 0, -0.78), "facing": P(0, 0, 3.0), "action": "sit",
     "shown": [V1998],
     "cues": [{"t": 0.0, "expression": "thinking"}]},
    # Ambassador Wisner stands at the desk and slides the satellite prints across to Rao.
    {"id": "wisner", "character": "toon_wisner", "at": P(0.42, 0, 0.82), "facing": P(0.05, 0, -0.6), "action": "idle",
     "shown": [[W("l4b", offset=-0.8), W("l4c", offset=0.04)]],
     "cues": [{"t": 0.0, "expression": "deadpan"}, {"t": W("l4b", "photos", 0.3), "expression": "side_eye"}]},
    {"id": "rao", "character": "toon_rao", "at": P(0, 0, -0.78), "facing": P(0, 0, 3.0), "action": "sit",
     "shown": [R1995],
     "cues": [{"t": 0.0, "expression": "nervous"},
              {"t": W("l4a", "Times", 0.02), "expression": "surprised"},
              {"t": W("l4a", "Times", 0.45), "expression": "nervous"},
              {"t": W("l4b", "photos", 0.05), "expression": "side_eye"},
              {"t": W("l4b", "photos", 0.7), "expression": "nervous"},
              {"t": W("l4c", "calls", 0.0), "expression": "shocked"},
              {"t": W("l4c", "calls", 0.5), "expression": "nervous"},
              {"t": W("l4c", "Minister", 0.0), "expression": "sad"}]},
]

GAGS = [{"id": "pmo", "script": "gags/pm_office.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"sitter": ["rao", "vajpayee_pmo"],
                    "calendar": {"flip": [W("l5a", offset=0.25), W("l5a", "1998.", 0.0)], "from": [1995, 12],
                                 "to": [1998, 3]},
                    "paper": {"slap": W("l4a", "Times", 0.0),
                              "folio": "THE NEW YORK TIMES, FRIDAY, DECEMBER 15, 1995",
                              "headline": ["U.S. Suspects India", "Prepares To Conduct", "Nuclear Test"],
                              "byline": "By TIM WEINER",
                              "dateline": "WASHINGTON, Dec. 14 —"},
                    "photos": {"slide": W("l4b", "photos", 0.0), "hand": "wisner",
                               "cam": range_place.P(0.0, 260.0, -0.5), "ortho": 34.0},
                    "ring": {"from": W("l4c", offset=-0.3), "lift": W("l4c", "calls", 0.15), "hand": "rao"}}}]

SHOTS = {
    # Insert from above the desk, the visitors' side: an aide's arm slaps the folded New York Times down on
    # "Times", close and readable; then the camera rises and backs off (eased in) to Rao behind the desk, staring at
    # it, the paper in the foreground.
    "nyt_slap": {"look": LOOK_1995, "camera": move(
        cam(P(0.1, 1.5, 0.66), P(0.05, 0.78, 0.0), 30, {"strength": 0.12}),
        cam(P(0.1, 1.98, 1.08), P(0.04, 0.98, -0.38), 30, {"strength": 0.12}), "in"),
        "shake": [{"t": W("l4a", "Times", 0.0), "amount": 0.15}]},
    # Over the ambassador's shoulder: he slides the top satellite print across the desk to Rao on "photos" (a live
    # overhead view of the 1995 site, the shaft ringed in grease pencil); Rao looks down at it, side-eyed.
    "wisner_photos": {"look": LOOK_1995, "camera": move(
        cam(P(1.5, 1.52, 1.3), P(-0.05, 0.93, -0.3), 34, {"strength": 0.14}),
        cam(P(1.36, 1.45, 1.16), P(-0.03, 0.92, -0.28), 36, {"strength": 0.14}), "in_out")},
    # Medium on Rao: the black phone rattles on its cradle on "calls"; he reaches for it and lifts the handset slowly to
    # his ear, the cord stretching; nervous, then sad. A slow push.
    "rao_phone": {"look": LOOK_1995, "camera": move(
        cam(P(-0.85, 1.22, 1.25), P(-0.3, 1.0, -0.5), 34, {"strength": 0.16}),
        cam(P(-0.72, 1.24, 1.0), P(-0.27, 1.05, -0.52), 36, {"strength": 0.16}), "in_out")},
    # Close on the wall calendar behind the desk: the pages flip from December 1995 to March 1998, landing on "1998";
    # the camera pulls back and round to the new Prime Minister in the chair, thinking, the calendar above his head.
    "office_1998": {"look": LOOK_1995, "camera": move(
        cam(P(-1.15, 2.0, -1.25), P(-1.2, 2.0, -2.7), 40, {"strength": 0.1}),
        cam(P(0.75, 1.45, 1.2), P(-0.3, 1.4, -1.2), 34, {"strength": 0.14}), "in_out"),
        "hold": 0.6},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
