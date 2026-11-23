"""Low orbit over India, December 1995: a US reconnaissance satellite (gags/orbit.gd) above the Earth
(library:earth). The point straight below the satellite is 350 km south of Pokhran, so the range lies just ahead
along a north-going track; north is gag-local -Z, east +X. Units: Earth at 1/1000 scale (R 6371, altitude 600),
the satellite at true size (12 m): far below it, the Earth barely moves as the camera does.
"""
import math
from .common import W, frame, cam, move

ORBIT_Z = -30000.0
P = frame("orbit", ORBIT_Z)

R, ALT = 6371.0, 600.0
AHEAD = 350.0
POKHRAN = (27.095, 71.75)
SUN = [35.0, 45.0]          # mid-morning in December: the sun in the south-east, about 35 degrees up

TH = AHEAD / R
TARGET = (0.0, -ALT - R * (1 - math.cos(TH)), -R * math.sin(TH))

LOOK = {
    "base": "night_fog", "time": "22:00", "ssao": False,
    "weather": {"fog": 0.0, "clouds": 0.0},
    "sun": {"elevation": SUN[0], "azimuth": SUN[1], "energy": 1.5, "color": "#fff6ea", "shadows": True,
            "softness": 0.05, "visible": False},
    "moon": {"energy": 0, "visible": False},
    "ambient": {"color": "#4a5a7a", "energy": 0.04},
    "sky": {"top": "#000000", "horizon": "#000000", "stars": 0, "clouds": 0,
            "panorama": "incoming/sss_textures/8k_stars_milky_way.jpg", "panorama_energy": 0.18, "panorama_yaw": 120,
            "panorama_tilt": 10},
    "fog": {"begin": 50000, "end": 60000, "volumetric": 0.0},
    "ground_fog": {"density": 0.0},
    "glow": {"enabled": True, "intensity": 0.8, "bloom": 0.05, "threshold": 1.2},
    "grade": {"contrast": 1.1, "saturation": 1.04, "vignette": 0.3, "grain": 0.035},
    "practical_lights": {"level": 0},
}

GAGS = [
    {"id": "earth", "script": "library:earth", "t": 0, "at": P(0, 0, 0),
     "params": {"radius": R, "altitude": ALT, "up": [round(POKHRAN[0] - math.degrees(TH), 4), POKHRAN[1]], "heading": 0,
                "sun": SUN, "clouds": 0.3, "spin": 0.004, "day_gain": 1.0}},
    {"id": "spysat", "script": "gags/orbit.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"aim": [round(v, 2) for v in TARGET],
                "turn": {"from": W("l3c", "spy", -0.2), "to": W("l3c", "satellites", 0.35)},
                "click": W("l3c", "watching", 0.12)}},
]

SHOTS = {
    # Behind the satellite, the curve of the Earth below (the Thar, the Arabian Sea, the Himalaya far off); a slow
    # arc as it turns its telescope down toward Rajasthan; the shutter's glint on "watching".
    "sat_turn": {"look": LOOK, "camera": move(
        cam(P(26.5, 1.5, 6.3), P(0.0, -4.6, -0.6), 30, far=12000.0),
        cam(P(24.5, 3.4, -1.5), P(0.0, -4.4, -1.8), 30, far=12000.0), "in_out")},
}

PLACE = {"gags": GAGS, "actors": [], "shots": SHOTS}
