"""New York (gags/nyc.gd, gag id "nyc"): the "Elite Space Club" of the cartoon (28 Sep 2014), restaged as a real
gentlemen's club, and the newspaper's entrance buried in letters (its editorial page editor apologised on
Facebook, 5 Oct 2014: "We apologize to readers who were offended by the choice of images in this cartoon.").
Club frame: the door on the back wall at z -3 (x 1.4), the fireplace on the left wall; the entrance at x +60.
"""
from .common import W, frame, cam, move

NY_Z = 47000.0
P = frame("club", NY_Z)


def E(x, y, z):
    return P(x + 60.0, y, z)


LOOK = {
    "base": "night_fog", "time": "21:00", "ssao": True,
    "weather": {"fog": 0.0, "clouds": 0.08},
    "sun": {"energy": 0, "visible": False}, "moon": {"energy": 0, "visible": False},
    "ambient": {"color": "#7a6450", "energy": 0.3},
    "sky": {"top": "#04060c", "horizon": "#1a1820", "stars": 0, "clouds": 0.08},
    "fog": {"begin": 200, "end": 2000, "color": "#14100e", "volumetric": 0.0},
    "ground_fog": {"density": 0.0},
    "glow": {"enabled": True, "intensity": 0.7, "bloom": 0.05, "threshold": 1.1},
    "grade": {"contrast": 1.12, "saturation": 0.95, "vignette": 0.33, "grain": 0.05},
    "practical_lights": {"level": 0},
}
STREET_LOOK = dict(LOOK, ambient={"color": "#6c7890", "energy": 0.22},
                   weather={"fog": 0.0, "clouds": 0.08, "rain": 0.0})

NYT_POST = {"name": "The New York Times", "handle": "Andrew Rosenthal, Editorial Page Editor", "verified": True,
            "text": "We apologize to readers who were offended by the choice of images in this cartoon.",
            "date": "5 Oct 2014 · Facebook", "avatar": "library/logos/nyt-wordmark.svg", "width": 2.6}

ACTORS = [
    {"id": "club_a", "character": "toon_club_a", "at": P(-1.2, 0.0, 0.95), "facing": P(-0.42, 0, 1.57), "action": "sit",
     "cues": [{"t": 0.0, "expression": "smug"},
              {"t": W("l19b", "knocking", 0.1), "expression": "side_eye", "head": [0, 30, 0]},
              {"t": W("l20"), "expression": "nervous"}]},
    {"id": "club_b", "character": "toon_club_b", "at": P(0.2, 0.0, -0.45), "facing": P(-0.27, 0, 0.43), "action": "sit",
     "cues": [{"t": 0.0, "expression": "smug"},
              {"t": W("l19b", "knocking", 0.2), "expression": "side_eye", "head": [0, -35, 0]}]},
    {"id": "farmer", "character": "toon_farmer", "at": P(1.25, 0.0, -3.55), "facing": P(1.25, 0, 0), "action": "idle",
     "cues": [{"t": 0.0, "expression": "neutral"}]},
]

GAGS = [
    {"id": "nyc", "script": "gags/nyc.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"knock": [W("l19b", "knocking", -0.05), W("l19b", "door")], "reader": "club_b", "knocker": "farmer",
                "letters": [W("l20", "After", -0.2), W("l20", "apologises", -0.2)]}},
    {"id": "nyt_apology", "script": "library:post_card", "t": W("l20", "apologises"), "until": W("l21a"),
     "at": E(0.0, 3.6, 2.4), "face": E(0.0, 2.6, 9.0), "params": NYT_POST},
]

SHOTS = {
    "club_room": {"look": LOOK, "camera": move(
        cam(P(-2.7, 1.45, 1.9), P(-0.5, 1.0, 0.2), 28, {"strength": 0.25}),
        cam(P(-2.45, 1.35, 1.55), P(-0.5, 1.0, 0.2), 30, {"strength": 0.25}), "in_out")},
    "club_door": {"look": LOOK, "shake": [{"t": W("l19b", "knocking"), "amount": 0.15}], "camera": move(
        cam(P(-1.6, 1.55, 1.9), P(1.35, 1.4, -2.9), 28, {"strength": 0.2}),
        cam(P(-1.3, 1.5, 1.5), P(1.35, 1.45, -2.9), 30, {"strength": 0.2}), "in_out")},
    "letters_pile": {"look": STREET_LOOK, "camera": move(
        cam(E(0.5, 1.2, 9.0), E(0, 2.2, 0), 24), cam(E(0.3, 2.0, 11.5), E(0, 6.5, 0), 24), "in_out")},
    "apology": {"look": STREET_LOOK, "camera": move(
        cam(E(0.2, 3.1, 8.2), E(0, 3.4, 2.4), 32), cam(E(0.1, 3.3, 7.4), E(0, 3.5, 2.4), 34), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
