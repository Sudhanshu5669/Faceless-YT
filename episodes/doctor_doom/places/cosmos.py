"""Chapter 3's escalation (+ the First Steps rocket) (gags/cosmos.gd, gag id "cosmos_set").

Areas (gag-local): SKY (0,0,0) Doom on the board at (0, 5, 0); VOID (0,0,600) Doom at (0, 0, 600); WORLD (0,0,1200)
Battleworld r 30; GOD (0,0,1800) the throne at (0, 0.55, 1794); EARTH (0,0,2600) r 40, Doom before it at
(0, -5, 2652); PAD (0,0,3200) the rocket.
"""
from .common import W, frame, cam, move

P = frame("board", 180000.0)
SK = -6000.0
VO, WO, GO, EA, PA = 600.0, 1200.0, 1800.0, 5000.0, 7000.0

_DARK = {
    "base": "night_fog", "time": "23:00",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.0},
    "sun": {"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "ssao": True,
}
LOOK_STORMSKY = dict(_DARK, sun={"elevation": 25, "azimuth": 60, "color": "#c8d4ff", "energy": 1.2, "softness": 0.5,
                                 "visible": False, "shadows": True},
                     sky={"top": "#141c30", "horizon": "#4a5470", "clouds": 0.0, "stars": 0.0},
                     ambient={"color": "#5a6480", "energy": 0.5, "sky": 0.0},
                     fog={"begin": 30, "end": 500, "curve": 1.3, "volumetric": 0.004, "color": "#4a5268"},
                     glow={"enabled": True, "intensity": 0.8, "bloom": 0.05, "threshold": 1.05},
                     grade={"contrast": 1.18, "saturation": 0.95, "vignette": 0.45, "grain": 0.04})
LOOK_SPACE = dict(_DARK, sun={"elevation": 18, "azimuth": 300, "color": "#fff2e0", "energy": 2.2, "softness": 0.3,
                              "visible": False, "shadows": True},
                  sky={"top": "#000000", "horizon": "#02030a", "clouds": 0.0, "stars": 1.0,
                              "panorama": "incoming/sss_textures/8k_stars_milky_way.jpg", "panorama_energy": 0.35},
                  ambient={"color": "#1a2030", "energy": 0.12, "sky": 0.0},
                  fog={"begin": 4000, "end": 9000, "curve": 1.8, "volumetric": 0.0},
                  glow={"enabled": True, "intensity": 1.0, "bloom": 0.08, "threshold": 1.0},
                  grade={"contrast": 1.15, "saturation": 1.05, "vignette": 0.45, "grain": 0.04})
LOOK_GOLD = dict(_DARK, base="day", time="17:30",
                 sun={"elevation": 12, "azimuth": 230, "color": "#ffd08a", "energy": 2.2, "softness": 0.7, "visible": True,
                      "size": 2.0, "glow": 2.4, "shadows": True},
                 sky={"top": "#6a5aa8", "horizon": "#ffd9a0", "clouds": 0.3},
                 ambient={"color": "#c8a878", "energy": 0.45, "sky": 0.6},
                 fog={"begin": 80, "end": 900, "curve": 1.3, "volumetric": 0.003, "color": "#ffe0b0"},
                 glow={"enabled": True, "intensity": 0.8, "bloom": 0.06, "threshold": 1.1},
                 grade={"contrast": 1.1, "saturation": 1.05, "vignette": 0.4, "grain": 0.035})
LOOK_DAWN = dict(LOOK_GOLD, time="06:20",
                 sun={"elevation": 5, "azimuth": 0, "color": "#ffb48a", "energy": 2.0, "softness": 0.6, "visible": True,
                      "size": 1.6, "glow": 2.0, "shadows": True},
                 sky={"top": "#3a5a9a", "horizon": "#ffc8a0", "clouds": 0.15})


def span(a, b):
    return [{"shot": a, "offset": -0.1}, {"shot": b}]


ACTORS = [
    {"id": "doom_surfer", "freeze": 0.35, "character": "doom_realistic", "at": P(0.0, 5.0, SK), "facing": P(0.0, 5.0, SK + 10.0), "keep_y": True,
     "action": "idle", "shown": [span("surfer_sky", "beyonder_grab")], "cues": [{"t": 0.0, "expression": "determined"}]},
    {"id": "doom_void", "freeze": 0.35, "character": "doom_realistic", "at": P(0.0, 0.0, VO), "facing": P(0.0, 0.0, VO + 10.0), "keep_y": True,
     "action": "idle", "shown": [span("beyonder_grab", "bw_planet")], "cues": [{"t": 0.0, "expression": "scheming"}]},
    {"id": "doom_god", "freeze": 0.35, "character": "toon_victor_young", "at": P(0.0, 0.55, GO - 6.0), "facing": P(0.0, 0.55, GO + 10.0),
     "keep_y": True, "action": "sit", "shown": [span("bw_throne", "emp_cloak")], "cues": [{"t": 0.0, "expression": "smug"}]},
    {"id": "doom_emp", "freeze": 0.35, "character": "doom_realistic", "at": P(0.0, -5.0, EA + 52.0), "facing": P(0.0, -5.0, EA + 70.0),
     "keep_y": True, "action": "idle", "shown": [span("emp_cloak", "board_titles")], "cues": [{"t": 0.0, "expression": "smug"}]},
]

GAGS = [
    {"id": "cosmos_set", "script": "gags/cosmos.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"board": {"actor": "doom_surfer"}, "lightning": [W("d7", "Silver", 0.0), W("d7", "Surfer.", 0.2)],
                "beyonder": {"actor": "doom_void", "t": W("d8", "god.", 0.0)}, "stitch": W("d11", "stitches", 0.0),
                "stretch": {"t": W("d13", "Reed", 0.0)},
                "green": W("d15", "Overnight,", 0.0)}},
    {"id": "cosmos_suits", "script": "library:doom_suit", "t": 0, "at": P(0, 0, 0),
     "params": {"actors": [{"actor": "doom_surfer"}, {"actor": "doom_void"},
                           {"actor": "doom_god", "metal": "#d8aa3a", "tunic": "#efe9dc", "cloak_color": "#f2ece0",
                            "unmask": W("d13", "heals", 0.0), "hand": "none"},
                           {"actor": "doom_emp", "cloak_color": "#9a1420"}]}},
]

SHOTS = {
    # Above the storm: Doom rides the crackling silver board; we circle him as lightning splits the clouds.
    "surfer_sky": {"look": LOOK_STORMSKY, "camera": move(
        cam(P(2.4, 5.9, SK + 2.6), P(0.0, 5.9, SK), 28, {"strength": 0.06}),
        cam(P(-2.0, 5.4, SK + 2.8), P(0.0, 6.0, SK), 28, {"strength": 0.06}), "in_out")},
    # The void: the Beyonder's star streams across space into his reaching hand.
    "beyonder_grab": {"look": LOOK_SPACE, "camera": move(
        cam(P(2.2, 1.5, VO + 2.6), P(-1.0, 2.2, VO - 6.0), 24, {"strength": 0.03}),
        cam(P(1.8, 1.4, VO + 2.2), P(-0.3, 1.5, VO - 1.0), 24, {"strength": 0.03}), "in_out")},
    # The universe in his palm.
    "beyonder_hand": {"look": LOOK_SPACE, "camera": move(
        cam(P(0.8, 1.2, VO + 1.7), P(0.0, 1.35, VO + 0.45), 40, {"strength": 0.2}),
        cam(P(0.65, 1.22, VO + 1.45), P(0.0, 1.35, VO + 0.45), 40, {"strength": 0.22}), "in")},
    # Battleworld's pieces hang apart in space.
    "bw_planet": {"look": LOOK_SPACE, "camera": move(
        cam(P(30.0, 25.0, WO + 110.0), P(0.0, 0.0, WO), 30, {"strength": 0.02}),
        cam(P(-10.0, 18.0, WO + 100.0), P(0.0, 0.0, WO), 30, {"strength": 0.02}), "in_out")},
    # ...and fly together on "stitches", seams blazing.
    "bw_stitch": {"look": LOOK_SPACE, "shake": [{"t": W("d11", "Battleworld,", 0.0), "amount": 0.08}], "camera": move(
        cam(P(-20.0, 10.0, WO + 80.0), P(0.0, 0.0, WO), 32, {"strength": 0.02}),
        cam(P(10.0, 6.0, WO + 72.0), P(0.0, 0.0, WO), 32, {"strength": 0.02}), "in")},
    # God Emperor Doom on the throne at the crown of the world tree; low, looking up.
    "bw_throne": {"look": LOOK_GOLD, "camera": move(
        cam(P(3.2, 0.6, GO + 1.0), P(0.0, 1.6, GO - 6.0), 28, {"strength": 0.05}),
        cam(P(2.2, 0.9, GO - 1.2), P(0.0, 1.7, GO - 6.0), 28, {"strength": 0.05}), "in")},
    # From behind the throne: Reed's arm reaches in, white light, the mask lifts away; his face never shown.
    "bw_heal": {"look": LOOK_GOLD, "camera": move(
        cam(P(-3.4, 2.3, GO - 5.0), P(0.3, 1.7, GO - 5.4), 32, {"strength": 0.1}),
        cam(P(-3.0, 2.2, GO - 4.8), P(0.3, 1.7, GO - 5.4), 32, {"strength": 0.1}), "in")},
    # Before the Earth: the red cloak and the amulet drop onto his shoulders on "Supreme".
    "emp_cloak": {"look": LOOK_SPACE, "camera": move(
        cam(P(1.5, -3.85, EA + 54.4), P(0.0, -4.15, EA + 52.0), 35, {"strength": 0.05}),
        cam(P(1.25, -3.9, EA + 54.0), P(0.0, -4.1, EA + 52.0), 35, {"strength": 0.05}), "in")},
    # Pull out from Doom to the whole Earth turning green, banners rising across it.
    "emp_globe": {"look": LOOK_SPACE, "camera": move(
        cam(P(1.5, -3.5, EA + 56.0), P(0.0, -3.5, EA + 50.0), 30, {"strength": 0.03}),
        cam(P(45.0, 15.0, EA + 150.0), P(0.0, 0.0, EA), 30, {"strength": 0.02}), "in_out")},
    # Chapter 4: dawn, the retro rocket on its pad, gantry and haze.
    "rocket_pad": {"look": LOOK_DAWN, "camera": move(
        cam(P(-34.0, 2.5, PA + 48.0), P(0.0, 16.0, PA), 28, {"strength": 0.03}),
        cam(P(-26.0, 3.5, PA + 40.0), P(0.0, 18.0, PA), 28, {"strength": 0.03}), "in_out")},
    # A push into a porthole on the rocket's flank: green light, Doom's mask inside.
    "rocket_shadow": {"look": LOOK_DAWN, "camera": move(
        cam(P(3.0, 16.5, PA + 12.0), P(0.0, 18.0, PA + 2.3), 32, {"strength": 0.05}),
        cam(P(0.6, 17.9, PA + 4.6), P(0.0, 18.0, PA + 2.3), 32, {"strength": 0.08}), "in")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
