"""The smaller places (gags/misc.gd, gag id "misc_set"): hell, the hospital, the rooftop, the dressing room, the film
reels, the campus gate, the mirror. Areas (gag-local z): HELL 0, HOSP 300, CITY 600, DRESS 900, REELS 1200,
CAMPUS 1500, MIRROR 1800.
"""
from .common import W, frame, cam, move

P = frame("board", 220000.0)
H, HO, CI, DR, RE, CA, MI = 0.0, 300.0, 600.0, 900.0, 1200.0, 1500.0, 1800.0

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
                 fog={"begin": 400, "end": 3000, "curve": 1.8, "volumetric": 0.01, "color": "#ff5a2a", "anisotropy": 0.4,
                      "length": 40})
LOOK_CITY = dict(_NIGHT, sky={"top": "#06080e", "horizon": "#1a2234", "clouds": 0.0, "stars": 0.0},
                 fog={"begin": 30, "end": 400, "curve": 1.3, "volumetric": 0.004, "color": "#2a3448"})
LOOK_RAIN = dict(_NIGHT, ambient={"color": "#2a3448", "energy": 0.25, "sky": 0.0},
                 fog={"begin": 10, "end": 120, "curve": 1.3, "volumetric": 0.01, "color": "#4a5468"})


def span(a, b):
    return [{"shot": a, "offset": -0.1}, {"shot": b}]


ACTORS = [
    {"id": "doom_hell", "character": "toon_doom_extra", "at": P(-5.0, 0, H + 2.0), "facing": P(6.0, 0, H - 6.0), "action": "idle",
     "shown": [span("hell_fight", "surfer_sky")], "cues": [{"t": 0.0, "expression": "furious"}]},
    {"id": "tony_bed", "freeze": 0.35, "character": "toon_rdj", "at": P(0.0, 0.75, HO - 1.6), "facing": P(0.0, 0.75, HO + 3.0), "keep_y": True,
     "action": "sit", "shown": [span("hosp_bed", "city_ironman")], "cues": [{"t": 0.0, "expression": "sleepy"}]},
    {"id": "doom_hosp", "character": "toon_doom_extra", "at": P(1.75, 0, HO - 1.0), "facing": P(1.0, 0, HO - 1.9), "action": "idle",
     "shown": [span("hosp_helmet", "city_ironman")], "cues": [{"t": 0.0, "expression": "scheming"}]},
    {"id": "doom_iron", "character": "toon_doom_extra", "at": P(0.0, 0, CI + 4.5), "facing": P(0.0, 0, CI - 5.0), "action": "idle",
     "shown": [span("city_ironman", "shop_rise")], "cues": [{"t": 0.0, "expression": "smug"}]},
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
    {"id": "misc_suits", "script": "library:doom_suit", "t": 0, "at": P(0, 0, 0),
     "params": {"actors": [{"actor": "doom_hell"}, {"actor": "doom_hosp"},
                           {"actor": "doom_iron", "hood": False}]}},
    {"id": "misc_set", "script": "gags/misc.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"clash": W("d6", "Devil", 0.0), "take": {"actor": "doom_hosp", "t": W("d18", "armor,", 0.0)},
                "slides": [W("r3", 0, 0.2), W("r4", "2007.", 0.0), W("r5", "Kebbell", 0.0)], "scar": {"actor": "victor_reflect", "warp": W("v7", 0, -0.1)},
                "bandage": {"actor": "victor_gate"}, "ironhead": {"actor": "doom_iron"}}},
]

SHOTS = {
    # Hell: on a ledge over the lava, Doom's green spell meets the horned shadow's red; sparks where they meet.
    "hell_fight": {"look": LOOK_HELL, "shake": [{"t": W("d6", "Devil", 0.0), "amount": 0.1}], "camera": move(
        cam(P(-13.0, 3.0, H + 12.0), P(0.5, 3.5, H - 2.0), 22, {"strength": 0.03}),
        cam(P(-11.5, 3.5, H + 10.5), P(0.5, 4.0, H - 2.0), 22, {"strength": 0.03}), "in")},
    # The hospital at night: Tony asleep, the monitor beeping, the helmet on the table.
    "hosp_bed": {"look": _NIGHT, "camera": move(
        cam(P(1.9, 1.35, HO + 1.4), P(0.3, 1.0, HO - 1.6), 32, {"strength": 0.12}),
        cam(P(1.6, 1.3, HO + 1.0), P(0.3, 1.0, HO - 1.6), 32, {"strength": 0.12}), "in")},
    # Doom's gauntlet takes the helmet from the table on "armor,".
    "hosp_helmet": {"look": _NIGHT, "camera": move(
        cam(P(0.6, 1.35, HO + 1.0), P(1.2, 1.1, HO - 1.6), 32, {"strength": 0.12}),
        cam(P(0.7, 1.4, HO + 0.8), P(1.2, 1.3, HO - 1.5), 32, {"strength": 0.12}), "in")},
    # Doom in red-and-grey armour on a rooftop, the city behind; low hero angle.
    "city_ironman": {"look": LOOK_CITY, "camera": move(
        cam(P(0.8, 0.9, CI + 2.4), P(0.0, 1.35, CI + 4.5), 30, {"strength": 0.06}),
        cam(P(0.6, 0.85, CI + 2.8), P(0.0, 1.4, CI + 4.5), 30, {"strength": 0.06}), "in")},
    # The dressing room: the golden statuette in front, Downey at the bulb-lit mirror behind.
    "dress_oscar": {"look": _NIGHT, "camera": move(
        cam(P(-1.5, 1.05, DR + 0.05), P(-0.5, 0.95, DR - 1.1), 35, {"strength": 0.2}),
        cam(P(-1.35, 1.05, DR - 0.05), P(-0.45, 0.95, DR - 1.1), 35, {"strength": 0.2}), "in")},
    # Film frames in the dark: the screen Dooms.
    "reels_past": {"look": _NIGHT, "camera": move(
        cam(P(0.0, 0.2, RE + 4.0), P(0.0, 0.0, RE), 30, {"strength": 0.04}),
        cam(P(0.0, 0.15, RE + 3.6), P(0.0, 0.0, RE), 30, {"strength": 0.04}), "in")},
    "reels_mcmahon": {"look": _NIGHT, "camera": move(
        cam(P(0.2, 0.15, RE + 3.6), P(0.0, 0.0, RE), 32, {"strength": 0.04}),
        cam(P(-0.2, 0.15, RE + 3.5), P(0.0, 0.0, RE), 32, {"strength": 0.04}), "in_out")},
    "reels_kebbell": {"look": _NIGHT, "camera": move(
        cam(P(-0.2, 0.15, RE + 3.5), P(0.0, 0.0, RE), 32, {"strength": 0.04}),
        cam(P(0.0, 0.1, RE + 3.3), P(0.0, 0.0, RE), 32, {"strength": 0.04}), "in")},
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
