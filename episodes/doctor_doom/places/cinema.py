"""A big cinema: the auditorium and, outside, the marquee (gags/cinema.gd, gag id "cinema_set").

Frame: the screen at z -14 (centre (0, 4.6)); rows rising toward +z (row k at z -8 + 1.1k + 0.55, floor y 0.35(k+1));
five toon fans sit in the front row (z -7.45, floor y 0.35); the marquee facade at x 80 facing +z.

cinema_ticket (o9: a Doomsday ticket flutters down the projector beam), cinema_2019 (c1a: packed for Endgame),
cinema_crowd (c1b), cinema_counter (c1c: the box office counts to $2.8 BILLION on "billion"), cinema_biggest (c1d:
the hall erupts), cinema_trailer (r16: the fans lit by the trailer), cinema_marquee (r18: the marquee at night).
"""
from .common import W, frame, cam, move

P = frame("board", 80000.0)
ROW0_Z, ROW0_Y = -7.45, 0.35

LOOK_CINEMA = {
    "base": "night_fog", "time": "21:00",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.0},
    "sun": {"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "sky": {"top": "#04050a", "horizon": "#0b0e18", "clouds": 0.0, "stars": 0.0},
    "ambient": {"color": "#22161a", "energy": 0.08, "sky": 0.0},
    "fog": {"begin": 400, "end": 3000, "curve": 1.8, "volumetric": 0.012, "color": "#b8b0a8", "anisotropy": 0.6,
            "length": 40},
    "glow": {"enabled": True, "intensity": 0.8, "bloom": 0.05, "threshold": 1.1},
    "ssao": True,
    "grade": {"contrast": 1.18, "saturation": 1.04, "vignette": 0.5, "grain": 0.045},
}
LOOK_STREET = dict(LOOK_CINEMA, ambient={"color": "#1a2234", "energy": 0.15, "sky": 0.0},
                   fog={"begin": 30, "end": 400, "curve": 1.4, "volumetric": 0.01, "color": "#606a80"})

CHEER = W("c1d", "biggest", -0.2)


def span(a, b):
    return [{"shot": a, "offset": -0.1}, {"shot": b}]


ACTORS = []
for _i, (_ch, _x) in enumerate([("toon_you", -2.1), ("toon_redhead", -1.45), ("toon_nerd", -0.8), ("toon_club_a", 0.8),
                                ("toon_club_b", 1.45)]):
    ACTORS.append({"id": f"fan_{_i}", "character": _ch, "at": P(_x, ROW0_Y, ROW0_Z), "facing": P(_x, ROW0_Y, -14.0),
                   "keep_y": True, "action": "sit",
                   "cues": [{"t": 0.0, "expression": "happy"}, {"t": CHEER, "expression": "cheer"},
                            {"t": W("r16", 0), "expression": "star_eyes"},
                            {"t": W("r16", "Rogers,", 0.0), "expression": "shocked"}]})

GAGS = [
    {"id": "cinema_set", "script": "gags/cinema.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"screen": [{"t": 0.0, "show": "white"},
                           {"t": W("c1a", 0, -0.3), "show": "title", "text": "AVENGERS: ENDGAME"},
                           {"t": W("c1c", 0, -0.2), "show": "black"},
                           {"t": W("c1d", 0, -0.2), "show": "white"},
                           {"t": W("r16", 0, -0.3), "show": "trailer"}],
                "cheer": CHEER, "ticket": W("o9", 0, -0.4),
                "marquee": ["AVENGERS: DOOMSDAY", "OPENS DEC 18"],
                "marquee_sets": [{"t": W("r2b", 0, -1.2), "lines": ["IRON MAN", "MAY 2 2008"]},
                                 {"t": W("r2c", 0, -0.1), "lines": ["AVENGERS: DOOMSDAY", "OPENS DEC 18"]}], "poster": "AVENGERS:\nSECRET WARS\nDECEMBER 2027"}},
]

REVEALS = [
    {"id": "endgame_bo", "t": W("c1c", 0, -0.1), "until": W("c1d", 0),
     "at": P(0.0, 4.4, -13.6), "size": 1.4,
     "counter": {"from": 0.0, "to": 2.8, "decimals": 1, "prefix": "$", "suffix": " BILLION",
                 "land": W("c1c", "billion", 0.0), "label": "WORLDWIDE BOX OFFICE"}, "sound": "ding"},
]

SHOTS = {
    # The projector beam overhead; a ticket flutters down through it and turns to the lens.
    "cinema_ticket": {"look": LOOK_CINEMA, "camera": move(
        cam(P(0.45, 4.6, -7.1), P(0.3, 4.6, -6.0), 40, {"strength": 0.25}),
        cam(P(0.4, 4.2, -6.85), P(0.3, 4.1, -6.0), 40, {"strength": 0.3}), "in_out")},
    # From the back, high: a packed house, the beam, ENDGAME on the screen.
    "cinema_2019": {"look": LOOK_CINEMA, "camera": move(
        cam(P(3.0, 8.0, 7.4), P(0.0, 3.5, -13.0), 24, {"strength": 0.04}),
        cam(P(2.2, 7.4, 6.2), P(0.0, 3.6, -13.0), 24, {"strength": 0.04}), "in_out")},
    # Low under the screen looking back up the rows: the front-row fans, the house behind, lit by the screen.
    "cinema_crowd": {"look": LOOK_CINEMA, "camera": move(
        cam(P(-1.0, 1.1, -11.0), P(-0.6, 2.2, 0.0), 28, {"strength": 0.08}),
        cam(P(0.6, 1.15, -10.6), P(-0.2, 2.2, 0.0), 28, {"strength": 0.08}), "in_out")},
    # The screen goes dark and the box office counts up to $2.8 BILLION on "billion".
    "cinema_counter": {"look": LOOK_CINEMA, "camera": move(
        cam(P(0.0, 3.8, -2.0), P(0.0, 4.4, -13.6), 30, {"strength": 0.05}),
        cam(P(0.0, 3.9, -3.5), P(0.0, 4.4, -13.6), 30, {"strength": 0.05}), "in")},
    # The house erupts, cheering; over the heads toward the white screen.
    "cinema_biggest": {"look": LOOK_CINEMA, "shake": [{"t": CHEER, "amount": 0.04}], "camera": move(
        cam(P(-2.5, 5.0, 3.0), P(0.0, 3.0, -12.0), 26, {"strength": 0.05}),
        cam(P(-1.8, 5.6, 2.2), P(0.0, 3.2, -12.0), 26, {"strength": 0.05}), "out")},
    # Chapter 4: the front-row fans lit by the trailer's flicker; a slow track along the row.
    "cinema_trailer": {"look": LOOK_CINEMA, "camera": move(
        cam(P(-2.6, 1.25, -9.4), P(-1.6, 1.0, ROW0_Z), 32, {"strength": 0.15}),
        cam(P(0.2, 1.25, -9.4), P(0.4, 1.0, ROW0_Z), 32, {"strength": 0.15}), "in_out")},
    # 2008: the same marquee reads IRON MAN; a slow tilt down from the letters.
    "cinema_2008": {"look": LOOK_STREET, "camera": move(
        cam(P(79.0, 4.5, 7.5), P(80.0, 6.6, 2.2), 30, {"strength": 0.04}),
        cam(P(79.3, 3.6, 7.0), P(80.0, 6.2, 2.2), 30, {"strength": 0.04}), "in_out")},
    # The marquee and the poster: the first Avengers film in seven years.
    "cinema_years": {"look": LOOK_STREET, "camera": move(
        cam(P(84.0, 1.5, 8.0), P(82.0, 4.5, 1.0), 26, {"strength": 0.04}),
        cam(P(83.0, 1.8, 7.0), P(81.0, 5.0, 1.0), 26, {"strength": 0.04}), "in_out")},
    # Outside, night: the marquee with chasing bulbs, the wet street, the poster.
    "cinema_marquee": {"look": LOOK_STREET, "camera": move(
        cam(P(77.5, 2.2, 9.5), P(80.0, 5.9, 2.2), 28, {"strength": 0.04}),
        cam(P(78.6, 2.6, 8.0), P(80.0, 6.1, 2.2), 28, {"strength": 0.04}), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "reveals": REVEALS, "shots": SHOTS}
