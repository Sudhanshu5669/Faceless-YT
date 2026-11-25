"""Shimla, 16:06: the hill town and the observatory's seismograph (gags/shimla.gd "shimla_set").

Frame: the town on its ridge along x around the origin, the valley toward +z; the instrument room at z +600 (drum at
(0, 1.28, 598.15)).
"""
from .common import W, frame, cam, move

P = frame("shimla", 0.0)
R = 600.0

LOOK_SHIMLA = {
    "base": "day", "time": "16:06",
    "weather": {"fog": 0.0, "clouds": 0.0, "wind": 0.2},
    "sun": {"elevation": 28, "azimuth": 250, "color": "#ffd8a8", "energy": 2.8, "softness": 0.6, "visible": True,
            "size": 1.2, "glow": 1.4, "shadows": True},
    "sky": {"top": "#4f78aa", "horizon": "#dfd4c0", "clouds": 0.0},
    "ambient": {"color": "#8a96a0", "energy": 0.32, "sky": 0.5},
    "fog": {"begin": 200, "end": 7000, "curve": 1.0, "volumetric": 0.0, "color": "#b4c0cc", "anisotropy": 0.5, "length": 400},
    "glow": {"enabled": True, "intensity": 0.6, "bloom": 0.05, "threshold": 1.1},
    "ssao": True,
    "grade": {"contrast": 1.14, "saturation": 1.02, "vignette": 0.42, "grain": 0.035},
}
LOOK_ROOM = {
    "base": "night_fog", "time": "16:06",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.0},
    "sun": {"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "sky": {"top": "#1a1c20", "horizon": "#202226", "clouds": 0.0, "stars": 0.0},
    "ambient": {"color": "#5a5650", "energy": 0.3, "sky": 0.0},
    "fog": {"begin": 300, "end": 900, "curve": 1.6, "volumetric": 0.02, "color": "#d8ccb8", "anisotropy": 0.6, "length": 20},
    "glow": {"enabled": True, "intensity": 0.7, "bloom": 0.05, "threshold": 1.05},
    "ssao": True,
    "grade": {"contrast": 1.18, "saturation": 1.0, "vignette": 0.5, "grain": 0.04},
}

GAGS = [{"id": "shimla_set", "script": "gags/shimla.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"shock": W("l16c", "shake.", -0.1)}}]

REVEALS = [
    {"id": "n_km1700", "t": W("l16b", offset=0.05), "until": {"shot": "seismograph"}, "at": P(10.0, 120.0, -120.0), "size": 18.0,
     "counter": {"from": 0, "to": 1700, "suffix": " KM", "land": W("l16b", "hundred", 0.1), "label": "AWAY"}, "sound": "ding"},
]

SHOTS = {
    # The hill town in the late sun across the valley, deodars below, ranges behind; a slow push.
    "shimla_town": {"look": LOOK_SHIMLA, "camera": move(
        cam(P(-40.0, 10.0, 300.0), P(10.0, 40.0, -200.0), 24),
        cam(P(-36.0, 8.0, 270.0), P(10.0, 44.0, -200.0), 24), "in_out")},
    # The seismograph under its glass: the drum turns, the stylus jumps and scrawls a spike; the lamp sways.
    "seismograph": {"look": LOOK_ROOM, "camera": move(
        cam(P(0.75, 1.62, R - 0.55), P(0.0, 1.27, R - 1.75), 36),
        cam(P(0.6, 1.58, R - 0.75), P(0.0, 1.27, R - 1.75), 42), "in_out")},
}

PLACE = {"gags": GAGS, "actors": [], "reveals": REVEALS, "shots": SHOTS}
