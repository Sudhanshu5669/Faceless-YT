"""Mumbai port, February 2011, dusk: a grab dredger brings up the ship's gold (gags/port.gd "port_set").

Frame: the water at y 0; the dredger's deck at y 2.25 centred at the origin, the crane at (0, *, -4) with its jib out
to the grab over the water at (0, *, 9); container cranes on the far quay at z -260; the city beyond.
"""
from .common import W, frame, cam, move

P = frame("port", 0.0)

LOOK_DUSK = {
    "base": "day", "time": "18:40",
    "weather": {"fog": 0.0, "clouds": 0.0, "wind": 0.3},
    "sun": {"elevation": 5, "azimuth": 250, "color": "#ffa868", "energy": 2.2, "softness": 0.7, "visible": True,
            "size": 1.5, "glow": 1.6, "shadows": True},
    "sky": {"top": "#32466e", "horizon": "#f0a070", "clouds": 0.0},
    "ambient": {"color": "#6a6478", "energy": 0.34, "sky": 0.5},
    "fog": {"begin": 100, "end": 1400, "curve": 1.3, "volumetric": 0.004, "color": "#c89880", "anisotropy": 0.7, "length": 300},
    "glow": {"enabled": True, "intensity": 0.75, "bloom": 0.06, "threshold": 1.05},
    "ssao": True,
    "grade": {"contrast": 1.18, "saturation": 1.06, "vignette": 0.46, "grain": 0.04},
}

ACTORS = [
    {"id": "crew_a", "character": "toon_dredger_crew", "at": P(-2.6, 2.35, 4.6), "keep_y": True, "facing": P(0.0, 6.0, 9.0), "action": "idle",
     "cues": [{"t": 0.0, "expression": "neutral"}, {"t": W("l24c", "still", 0.0), "expression": "surprised"},
              {"t": W("l24d", "gold", 0.0), "expression": "star_eyes"}]},
    {"id": "crew_b", "character": "toon_dredger_crew", "at": P(2.4, 2.35, 4.2), "keep_y": True, "facing": P(0.0, 6.0, 9.0), "action": "call_out",
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": W("l24d", "gold", 0.1), "expression": "shocked"}]},
]

GAGS = [{"id": "port_set", "script": "gags/port.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"rise": W("l24a", "kept", 0.0), "open": W("l24d", "bars", -0.6), "bar": W("l24d", "gold", -0.2)}}]

REVEALS = [
    {"id": "n_2011", "t": W("l24b", offset=0.05), "until": {"shot": "dredger_crew"}, "at": P(-5.0, 12.0, 6.0), "size": 1.3,
     "counter": {"from": 1944, "to": 2011, "commas": False, "land": W("l24b", "2011,", 0.0), "label": "STILL FINDING GOLD"}, "sound": "ding"},
]

SHOTS = {
    # Dusk on the old dock basin: the dredger's grab breaks the brown water, streaming mud; container cranes beyond.
    "dredger_2011": {"look": LOOK_DUSK, "camera": move(
        cam(P(14.0, 1.2, 22.0), P(0.0, 5.0, 6.0), 26),
        cam(P(12.0, 1.3, 19.0), P(0.0, 7.0, 6.0), 26), "in_out")},
    # 1944 to 2011: the years count up over the grab rising against the sunset.
    "grab_rise": {"look": LOOK_DUSK, "camera": move(
        cam(P(5.0, 3.4, 18.0), P(0.0, 9.0, 9.0), 28),
        cam(P(4.4, 3.2, 16.4), P(0.0, 10.5, 9.0), 28), "in_out")},
    # On deck: the crew watch the grab swing in over the hopper.
    "dredger_crew": {"look": LOOK_DUSK, "camera": move(
        cam(P(5.2, 3.9, 0.6), P(0.0, 5.8, 7.5), 24),
        cam(P(5.0, 3.9, 1.2), P(0.0, 6.6, 7.5), 24), "in_out")},
    # The grab opens: in the mud, a gold bar glints. Tilt up into the sky (the loop to the hook).
    "grab_bar": {"look": LOOK_DUSK, "camera": move(
        cam(P(3.4, 8.9, 12.8), P(0.2, 8.3, 9.2), 34),
        cam(P(3.3, 9.4, 12.5), P(9.0, 45.0, -4.0), 30), "in")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "reveals": REVEALS, "shots": SHOTS}
