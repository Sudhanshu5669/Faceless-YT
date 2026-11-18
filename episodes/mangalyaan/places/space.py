"""Space: Earth, Mars, the orbits and the spacecraft (gags/space.gd, gag id "cosmos").

Gag-local frame: Earth at the origin (R 60), Mars at z -6000 (R 36), deep space at x -6000, the diagram
at x +6000. The key light comes from SUN (elevation, azimuth), the same in the look and the gag.
"""
from .common import W, frame, cam, move

SPACE_Z = 40000.0
SUN = [12, 62]
P = frame("space", SPACE_Z)


def M(x, y, z):
    """Mars-relative point."""
    return P(x, y, z - 6000.0)


def D(x, y, z):
    """Diagram-relative point."""
    return P(x + 6000.0, y, z)


def C(x, y, z):
    return P(x - 6000.0, y, z)


def A(name, dx=0.0, dy=0.0, dz=0.0):
    """A point near one of the gag's moving anchors (offsets in gag axes)."""
    return {"anchor": "cosmos." + name, "offset": [round(-dx, 3), round(dy, 3), round(dz, 3)]}


LOOK = {
    "base": "night_fog", "time": "22:00", "ssao": False,
    "weather": {"fog": 0.0, "clouds": 0.0},
    "sun": {"elevation": SUN[0], "azimuth": SUN[1], "energy": 2.1, "color": "#fff4e6", "shadows": True,
            "softness": 0.05, "visible": False},
    "moon": {"energy": 0, "visible": False},
    "ambient": {"color": "#5a6a8a", "energy": 0.03},
    "sky": {"top": "#000000", "horizon": "#000000", "stars": 0, "clouds": 0,
            "panorama": "incoming/sss_textures/8k_stars_milky_way.jpg", "panorama_energy": 0.55, "panorama_yaw": 40,
            "panorama_tilt": 25},
    "fog": {"begin": 50000, "end": 60000, "volumetric": 0.0},
    "ground_fog": {"density": 0.0},
    "glow": {"enabled": True, "intensity": 0.8, "bloom": 0.05, "threshold": 1.3},
    "grade": {"contrast": 1.08, "saturation": 1.02, "vignette": 0.28, "grain": 0.04},
    "practical_lights": {"level": 0},
}

GAG = {
    "id": "cosmos", "script": "gags/space.gd", "t": 0, "at": P(0, 0, 0),
    "params": {
        "sun": SUN,
        "club": [W("l2b", "America"), W("l2b", "Soviet"), W("l2b", "Europe"), W("l2b", edge="end", offset=0.4)],
        "nozomi": [W("l3a1", "Japan", -0.3), W("l3a2", "China", -0.1)],
        "china": [W("l3a2", "China", -0.15), W("l3b", offset=-0.05)],
        "arcs": [W("l3b", "More", -0.1), W("l3b", "failed", -0.2), W("l3b", "half"), W("l3b", edge="end", offset=0.8)],
        "loops": [W("l8b", "Around", -0.1), W("l8b", edge="end", offset=0.1)],
        "tmi": [W("l10b", "final", -0.35), W("l10b", edge="end", offset=0.3)],
        "escape": [W("l10c", "mother", -0.2), W("l10c", edge="end", offset=0.25)],
        "cruise": [W("l11a"), W("l11a", edge="end")],
        "maven": [W("l12a", "Two", -0.2), W("l12a", "Mars", 0.3)],
        "tags": [W("l12b", "six"), W("l12b", "seventy-four", -0.15), W("l12b", edge="end", offset=0.5)],
        "test": [W("l13b", "fires", -0.05), W("l13b", edge="end", offset=0.8)],
        "moi": [W("l14a", "real", -0.2), W("l14a", "burn", -0.1), W("l15c", "behind", -0.4), W("l17b", "orbit", -0.3),
                W("l17b", edge="end", offset=0.4)],
        "ghost": [W("l14b", "fly", -0.2), W("l14b", edge="end", offset=0.2)],
        "pulse": [W("l15b", "signal", -0.1), W("l15b", edge="end")],
        "reply": [W("l18b"), W("l18b", edge="end")],
        "years": [W("l21a"), W("l21a", "six"), W("l21b", "eight"), W("l21b", edge="end", offset=0.3)],
    },
}

DOF_LOW = {"strength": 0.0}

SHOTS = {
    "mars_club": {"look": LOOK, "camera": move(
        cam(M(-45, 30, 150), M(0, 4, 0), 24), cam(M(30, 18, 138), M(0, 4, 0), 24), "in_out")},
    "fail_japan": {"look": LOOK, "camera": move(
        cam(M(150, 30, 175), M(30, 4, 30), 30), cam(M(165, 26, 150), M(40, 0, 0), 30), "linear")},
    "fail_china": {"look": LOOK, "camera": move(
        cam(A("grunt", 9, 4, 13), A("grunt", 0, -2, 0), 32), cam(A("grunt", 8, 3.5, 12), A("grunt", 0, -3, 0), 32), "linear")},
    "mars_graveyard": {"look": LOOK, "camera": move(
        cam(D(0, 0, 105), D(0, 0, 0), 30), cam(D(0, 0, 128), D(0, 0, 0), 30), "out")},
    "orbit_loops": {"look": LOOK, "camera": move(
        cam(P(-190, 300, -120), P(120, -20, 60), 30), cam(P(-215, 340, -80), P(130, -20, 60), 30), "in_out")},
    "tmi_burn": {"look": LOOK, "camera": move(
        cam(A("mom_e", -3.5, 11, -3.5), A("mom_e", 3.5, -1.5, 4), 30), cam(A("mom_e", -3, 9.5, -2.8), A("mom_e", 3.5, -1.5, 4), 30), "in_out")},
    "slingshot": {"look": LOOK, "camera": move(
        cam(P(-150, 70, -110), A("mom_e"), 32), cam(P(-160, 80, -100), A("mom_e"), 32), "in"), "whip_out": "up"},
    "cruise_sleep": {"look": LOOK, "camera": move(
        cam(A("mom_c", 6, 2, 9), A("mom_c"), 35), cam(A("mom_c", 4.5, 1.5, 6.5), A("mom_c"), 35), "in_out")},
    "maven_arrival": {"look": LOOK, "camera": move(
        cam(A("maven", 12, 4, 16), A("maven", -4, -2, -10), 32), cam(A("maven", 10, 3, 13), A("maven", -4, -2, -10), 32), "in_out")},
    "price_tags": {"look": LOOK, "camera": move(
        cam(A("maven", 2, 0, 28), A("maven", 0, -1, 0), 35), cam(A("maven", 1.5, -1, 25), A("maven", 0, -1.5, 0), 35), "in_out")},
    "test_fire": {"look": LOOK, "camera": move(
        cam(A("mom_m", -10, 2.0, 3.5), A("mom_m", 0, 0, 2.0), 30), cam(A("mom_m", -9, 1.8, 3.2), A("mom_m", 0, 0, 2.0), 30), "in_out")},
    "moi_start": {"look": LOOK, "camera": move(
        cam(A("mom_m", -7, 3.5, 7), M(0, 0, 0), 26), cam(A("mom_m", -6, 3, 6), M(0, 0, 0), 26), "in_out")},
    "moi_risk": {"look": LOOK, "camera": move(
        cam(M(120, 45, 150), M(-30, 0, 20), 28), cam(M(105, 40, 135), M(-35, 0, -40), 28), "in_out")},
    "signal_crawl": {"look": LOOK, "camera": move(
        cam(D(0, 0, 120), D(0, 0, 0), 30), cam(D(0, -6, 112), D(0, -4, 0), 30), "in_out")},
    "behind_mars": {"look": LOOK, "camera": move(
        cam(M(70, 20, 60), A("mom_m"), 30), cam(M(55, 16, 40), A("mom_m"), 30), "in_out")},
    "in_orbit": {"look": LOOK, "camera": move(
        cam(M(-40, 50, 150), M(-10, 0, -20), 26), cam(M(-60, 45, 140), M(-10, 0, -20), 26), "out")},
    "mom_reply": {"look": LOOK, "camera": move(
        cam(A("mom_m", 6.5, 3.2, 10.0), A("mom_m", 1.0, 1.6, 1.5), 34), cam(A("mom_m", 6.0, 3.0, 9.2), A("mom_m", 1.0, 1.8, 1.5), 34), "in_out")},
    "six_months": {"look": LOOK, "camera": move(
        cam(M(0, 110, 170), M(0, 0, 0), 26), cam(M(20, 100, 160), M(0, 0, 0), 26), "in_out")},
    "eight_years": {"look": LOOK, "camera": move(
        cam(M(20, 100, 160), M(0, 0, 0), 26), cam(M(50, 140, 190), M(0, 0, 0), 26), "in_out")},
}

REVEALS = [
    {"id": "delay_count", "t": W("l15b", "takes", -0.1), "until": W("l15c"), "at": D(13, 2, 18), "size": 6.0,
     "counter": {"from": 0, "to": 12, "decimals": 0, "suffix": " MIN", "land": W("l15b", "twelve"),
                 "label": "EACH WAY"}, "sound": "tick"},
    {"id": "six_count", "t": W("l21a", "built", -0.1), "until": W("l21b"), "at": M(0, 52, 40), "size": 9.0,
     "counter": {"from": 0, "to": 6, "decimals": 0, "suffix": " MONTHS", "land": W("l21a", "months"),
                 "label": "DESIGNED TO LAST"}, "sound": "ding"},
    {"id": "eight_count", "t": W("l21b"), "until": W("l22"), "at": M(0, 52, 40), "size": 9.0,
     "counter": {"from": 1, "to": 8, "decimals": 0, "suffix": " YEARS", "land": W("l21b", "years"),
                 "label": "ACTUALLY WORKED"}, "sound": "ding"},
]

PLACE = {"gags": [GAG], "actors": [], "shots": SHOTS, "reveals": REVEALS}
