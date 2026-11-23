"""The Pokhran field firing range, Thar desert (gags/range.gd, gag id "range_site").

Frame: the White House shaft plate at the origin (top at y 0.26); cameras usually stand south (+z) looking
north (-z). The tripod apex at (0, 5.2, 0); the winch at (4.6, 0, 1.4) behind a sandbag horseshoe; the spoil
heap at (-5.6, 0, -3.2); the hero khejri at (-6.8, 0, -11.5); the camp (olive tents) north-west at about
(-8..-31, -27..-44); the windsock at (10.5, 0, -17). A truck track crosses in front at z ~5.6 (x = 0).
The ground is not flat: place actors with range_ground() heights only where it matters (keep_y off snaps them).
"""
from .common import W, frame, cam, move

RANGE_Z = 15000.0
P = frame("range", RANGE_Z)

# Afternoon in May (the tests fired at 15:45): the sun high in the south-west, behind the shaft from the usual
# camera side, so the tripod, the tree and the jawans get a warm rim; a pale, dusty sky; haze swallowing the
# far dunes. Fill comes from the sky (blue from above) plus warm bounce off the sand.
LOOK_AFTERNOON = {
    "base": "day", "time": "15:45",
    "weather": {"fog": 0.0, "clouds": 0.0, "wind": 0.4},
    "sun": {"elevation": 36, "azimuth": 212, "color": "#ffe2b6", "energy": 3.1, "softness": 0.7,
            "visible": True, "size": 1.3, "glow": 1.4, "shadows": True},
    "sky": {"top": "#7998bd", "horizon": "#e8dcc4", "clouds": 0.0},
    "ambient": {"color": "#b89c78", "energy": 0.32, "sky": 0.55},
    "fog": {"begin": 25, "end": 2300, "curve": 1.8, "volumetric": 0.0},
    "glow": {"enabled": True, "intensity": 0.55, "bloom": 0.04, "threshold": 1.15},
    "ssao": True,
    "grade": {"contrast": 1.15, "saturation": 1.02, "vignette": 0.42, "grain": 0.035},
}

ACTORS = [
    # A jawan carrying two jerrycans of water across the site, behind the shaft.
    {"id": "jawan_noon", "character": "toon_jawan_a", "at": P(0.51, 0, -4.1), "facing": P(-0.83, 0, -3.03),
     "route": {"via": [P(-0.83, 0, -3.03)], "gait": "walk", "start": W("l2b", offset=-0.6),
               "arrive": W("l2b", edge="end", offset=0.3)},
     "cues": [{"t": 0.0, "expression": "deadpan"}]},
]

GAGS = [{"id": "range_site", "script": "gags/range.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"carry": [{"actor": "jawan_noon", "what": "jerrycans"}], "wind": [[0.0, 115.0, 0.55]], "shimmer": 1.0,
                    "tufts": [[2.31, 3.99, 1.15], [3.74, 3.34, 1.0], [1.19, 3.04, 0.9], [3.7, 1.95, 0.85]],
                    "clear": [[4.33, 5.8, 1.8], [3.83, 5.29, 1.6]],
                    "bushes": [[1.1, 2.5, 0.75, 0.6]]}}]

# The usual range camera looks into the afternoon sun (az 212): forward F, right R in the ground plane.
F = (-0.53, -0.85)
R = (0.85, -0.53)


def V(right, fwd, y):
    """A gag-local point from (right, forward) in the sun-facing camera frame, metres from the plate."""
    return P(R[0] * right + F[0] * fwd, y, R[1] * right + F[1] * fwd)


SHOTS = {
    # Whip in from the feed: low on the sand, into the sun. The plate and its collar fill the lower third, the
    # tripod climbs to the sheave with the sun burning beside it, the khejri stands behind the legs; a jawan
    # crosses with a sandbag. Crane up as the line plays.
    "range_noon": {"look": LOOK_AFTERNOON, "camera": move(
        cam(V(0.6, -7.2, 0.3), V(0.0, 0.0, 2.2), 30, {"strength": 0.1}),
        cam(V(0.45, -6.5, 1.4), V(0.0, 0.0, 2.6), 32, {"strength": 0.1}), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
