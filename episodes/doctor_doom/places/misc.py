"""The smaller places (gags/misc.gd, gag id "misc_set"): hell, the hospital, the dressing room, the film
poster table, the campus gate, the mirror. Areas (gag-local z): HELL 0, HOSP 300, DRESS 900, TABLE 2100,
CAMPUS 1500, MIRROR 1800.
"""
from .common import W, frame, cam, move

P = frame("board", 7200.0)   # near the origin (float precision); gags are shown only in their shots
H, HO, DR, CA, MI = 0.0, 300.0, 900.0, 1500.0, 1800.0
TB = 2100.0   # the table where the Fox posters are thrown down (reels_mcmahon)

_NIGHT = {
    "base": "night_fog", "time": "23:00",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.0},
    "sun": {"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "sky": {"top": "#04060a", "horizon": "#0c1018", "clouds": 0.0, "stars": 0.0},
    "ambient": {"color": "#1c2230", "energy": 0.12, "sky": 0.0},
    "fog": {"begin": 400, "end": 3000, "curve": 1.8, "volumetric": 0.01, "color": "#8a96a8", "anisotropy": 0.5, "length": 25},
    "glow": {"enabled": True, "intensity": 0.85, "bloom": 0.06, "threshold": 1.05},
    "ssao": True,
    "grade": {"contrast": 1.2, "saturation": 1.02, "vignette": 0.5, "grain": 0.045},
}
LOOK_HELL = dict(_NIGHT, ambient={"color": "#3a1008", "energy": 0.25, "sky": 0.0},
                 fog={"begin": 400, "end": 3000, "curve": 1.8, "volumetric": 0.0012, "color": "#ff5a2a", "anisotropy": 0.4,
                      "length": 40},
                 glow={"enabled": True, "intensity": 0.5, "bloom": 0.0, "threshold": 1.3})   # thin haze, tight glow: thicker fog washed the Devil's silhouette out
LOOK_RAIN = dict(_NIGHT, ambient={"color": "#2a3448", "energy": 0.25, "sky": 0.0},
                 fog={"begin": 10, "end": 120, "curve": 1.3, "volumetric": 0.01, "color": "#4a5468"})


def span(a, b):
    return [{"shot": a, "offset": -0.1}, {"shot": b}]


ACTORS = [
    {"id": "doom_hell", "character": "doom_realistic", "at": P(-5.0, 0, H + 2.0), "facing": P(6.0, 0, H - 6.0), "action": "idle",
     "shown": [span("hell_fight", "surfer_sky")], "cues": [{"t": 0.0, "expression": "furious"}]},
    {"id": "tony_bed", "freeze": 0.35, "character": "toon_rdj", "at": P(0.0, 0.85, HO + 0.35), "facing": P(0.0, 0.85, HO + 3.0), "keep_y": True,
     "action": "idle", "shown": [span("hosp_bed", "hosp_helmet")], "cues": [{"t": 0.0, "expression": "sleepy"}]},
    {"id": "rdj_dress", "freeze": 0.35, "character": "toon_rdj", "at": P(0.1, 0, DR - 0.45), "facing": P(0.1, 0, DR - 2.0), "action": "sit",
     "shown": [span("dress_oscar", "cinema_2008")], "cues": [{"t": 0.0, "expression": "smug"}]},
    {"id": "victor_gate", "character": "toon_victor_young", "at": P(0.0, 0, CA - 7.0), "facing": P(0.0, 0, CA + 6.0), "action": "idle",
     "route": {"via": [P(0.4, 0, CA + 3.0)], "gait": "walk", "start": W("v5", 0, -0.4), "arrive": W("v5", "forever.", 0.3)},
     "shown": [span("campus_gates", "mirror_scar")], "cues": [{"t": 0.0, "expression": "angry"}]},
    {"id": "victor_mirror", "freeze": 0.35, "character": "toon_victor_young", "at": P(0.0, 0, MI + 1.0), "facing": P(0.0, 0, MI - 3.0), "action": "idle",
     "shown": [span("mirror_scar", "tibet_cliff")], "cues": [{"t": 0.0, "expression": "sad"}]},
    {"id": "victor_reflect", "freeze": 0.35, "character": "toon_victor_young", "at": P(0.0, 0, MI - 1.0), "facing": P(0.0, 0, MI + 3.0), "action": "idle",
     "shown": [span("mirror_scar", "tibet_cliff")],
     "cues": [{"t": 0.0, "expression": "sad"}, {"t": W("v7", "ruined.", 0.0), "expression": "furious"}]},
]

GAGS = [
    {"id": "misc_set", "script": "gags/misc.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"clash": W("d6", "Devil", 0.0),
                "thrown": [W("r4", "McMahon", 0.0), W("r4", "2007.", 0.0), W("r5", "2015.", 0.0)], "scar": {"actor": "victor_reflect", "warp": W("v7", 0, -0.1)},
                "bandage": {"actor": "victor_gate"}}},
]

SHOTS = {
    # Hell: low behind Doom's shoulder on the ledge, the horned Devil towering black against the furnace; their
    # spells meet with sparks on "Devil". (The old wide made Doom a speck and fogged the Devil out.)
    "hell_fight": {"look": LOOK_HELL, "shake": [{"t": W("d6", "Devil", 0.0), "amount": 0.1}], "camera": move(
        cam(P(-7.4, 0.4, H + 9.6), P(11.0, 8.0, H - 7.5), 45),
        cam(P(-6.9, 0.45, H + 8.9), P(11.0, 8.4, H - 7.5), 45), "in")},
    # ICU: slide past the monitor toward the pillow so the line ends on Tony.
    "hosp_bed": {"look": _NIGHT, "camera": move(
        cam(P(2.15, 1.85, HO + 0.5), P(-0.4, 1.25, HO - 0.85), 39),
        cam(P(1.05, 1.58, HO + 0.0), P(0.0, 1.02, HO - 1.02), 43), "in_out")},
    # The dressing room: the golden statuette in front, Downey at the bulb-lit mirror behind.
    "dress_oscar": {"look": _NIGHT, "camera": move(
        cam(P(-1.5, 1.05, DR + 0.05), P(-0.5, 0.95, DR - 1.1), 35, {"strength": 0.2}),
        cam(P(-1.35, 1.05, DR - 0.05), P(-0.45, 0.95, DR - 1.1), 35, {"strength": 0.2}), "in")},
    # The user: "show posters being thrown on table instead": the 2005 and 2007 one-sheets slap down on their years.
    "reels_mcmahon": {"look": _NIGHT, "camera": move(
        cam(P(0.0, 2.05, TB + 1.35), P(0.0, 0.9, TB + 0.05), 32, {"strength": 0.05}),
        cam(P(0.0, 1.95, TB + 1.25), P(0.0, 0.9, TB + 0.05), 32, {"strength": 0.05}), "in")},
    # The same table: the 2015 one-sheet lands on top of the pile on "2015."
    "reels_kebbell": {"look": _NIGHT, "camera": move(
        cam(P(0.15, 1.95, TB + 1.25), P(0.0, 0.9, TB + 0.1), 32, {"strength": 0.05}),
        cam(P(0.1, 1.85, TB + 1.12), P(0.0, 0.9, TB + 0.12), 32, {"strength": 0.05}), "in")},
    # The campus gate at night in the rain: Victor, bandaged, walks out toward us.
    "campus_gates": {"look": LOOK_RAIN, "camera": move(
        cam(P(1.2, 1.3, CA + 6.0), P(0.0, 1.6, CA - 3.0), 30, {"strength": 0.05}),
        cam(P(0.9, 1.25, CA + 5.0), P(0.2, 1.3, CA + 1.0), 30, {"strength": 0.06}), "in_out")},
    # Over his shoulder into the mirror: a small scar on his cheek.
    "mirror_scar": {"look": _NIGHT, "camera": move(
        cam(P(-1.5, 1.4, MI + 3.0), P(0.0, 1.15, MI - 1.0), 30, {"strength": 0.1}),
        cam(P(-1.35, 1.38, MI + 2.7), P(0.0, 1.15, MI - 1.0), 30, {"strength": 0.1}), "in")},
    # The reflection warps; the scar grows until it fills his face.
    "mirror_warp": {"look": _NIGHT, "camera": move(
        cam(P(-0.9, 1.25, MI + 2.4), P(0.0, 1.15, MI - 1.0), 45, {"strength": 0.12}),
        cam(P(-0.8, 1.22, MI + 2.1), P(0.0, 1.15, MI - 1.0), 45, {"strength": 0.14}), "in")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
