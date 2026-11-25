"""A comic shop at night (gags/shop.gd, gag id "shop_set").

Frame: the lamp table at (0, 0, 0) (top y 0.9), the long box on it at (-0.35, 0.9, 0); the collector stands behind it
at (-0.35, 0, -0.75) facing +z; the counter at (1.6, 1.0, -0.6); the Doom standee by the window at (3.6, 0, 2.2); the
window wall at z 3.2 with the street beyond. Cameras inside at +z looking -z.

shop_night (v0a: the rainy window, the neon sign, push in), shop_box (v0b: he draws a comic out of the long box on
"answer"), shop_cover (v0c: FF #5 held up, tilting into the lamp), shop_meet (v0d: close on Doom on the cover),
shop_stack (v0j: four comics slap down, one per name), shop_wait (r6: the standee in front, the collector and his
comic behind).
"""
from .common import W, frame, cam, move

P = frame("board", 3600.0)   # near the origin (float precision); gags are shown only in their shots

LOOK_SHOP = {
    "base": "night_fog", "time": "22:30",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.0},
    "sun": {"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "sky": {"top": "#04060c", "horizon": "#0c1220", "clouds": 0.0, "stars": 0.0},
    "ambient": {"color": "#1e2430", "energy": 0.12, "sky": 0.0},
    "fog": {"begin": 400, "end": 3000, "curve": 1.8, "volumetric": 0.008, "color": "#9aa4b8", "anisotropy": 0.5,
            "length": 20},
    "glow": {"enabled": True, "intensity": 0.8, "bloom": 0.05, "threshold": 1.1},
    "ssao": True,
    "grade": {"contrast": 1.16, "saturation": 1.05, "vignette": 0.45, "grain": 0.045},
}

PULL = W("v0b", "answer", 0.0)

ACTORS = [
    {"id": "collector", "character": "toon_nerd", "at": P(-0.35, 0, -0.75), "facing": P(-0.35, 0, 3.0), "action": "idle",
     "cues": [{"t": 0.0, "expression": "thinking"}, {"t": PULL, "expression": "star_eyes"},
              {"t": W("v0d", "Doom.", 0.0), "expression": "shocked"}, {"t": W("r6", 0), "expression": "happy"},
              {"t": W("r6", "comics.", 0.0), "expression": "star_eyes"}]},
]

GAGS = [
    {"id": "shop_set", "script": "gags/shop.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"pull": {"actor": "collector", "t": PULL}, "tilt": W("v0c", 0), "drop": W("v0d", 0, -0.55),
                "covers": ["library/logos/doom/posters/avengers1.jpg", "library/logos/doom/posters/spiderman.jpg",
                           "library/logos/doom/posters/ironman_comic.jpg", "library/logos/doom/posters/daredevil.jpg"],
                "stack": [W("v0j", "Avengers,", 0.0), W("v0j", "Spider-Man,", 0.0), W("v0j", "Iron", 0.0),
                          W("v0j", "Daredevil.", 0.0)], "rise": 1e9}},
]

SHOTS = {
    # Outside in the rain: the neon COMICS sign, the warm shop beyond the glass; a push toward the window.
    "shop_night": {"look": LOOK_SHOP, "camera": move(
        cam(P(0.8, 1.5, 8.5), P(0.0, 1.5, 0.0), 28, {"strength": 0.06}),
        cam(P(0.4, 1.55, 5.0), P(0.0, 1.35, 0.0), 28, {"strength": 0.08}), "in")},
    # Close on the long box: he reaches in and draws a comic out on "answer".
    "shop_box": {"look": LOOK_SHOP, "camera": move(
        cam(P(0.4, 1.3, 1.0), P(-0.35, 1.05, -0.2), 38, {"strength": 0.15}),
        cam(P(0.3, 1.28, 0.8), P(-0.35, 1.1, -0.3), 38, {"strength": 0.15}), "in_out")},
    # FF #5 held up under the lamp, tilting into the light.
    "shop_cover": {"look": LOOK_SHOP, "camera": move(
        cam(P(-0.15, 1.15, 0.6), P(-0.35, 1.06, -0.37), 40, {"strength": 0.22}),
        cam(P(-0.2, 1.12, 0.4), P(-0.35, 1.06, -0.37), 40, {"strength": 0.25}), "in")},
    # The comic lies face up on the floor where it fell: top-down, a slow push onto Doom.
    "shop_meet": {"look": LOOK_SHOP, "camera": move(
        cam(P(0.12, 0.75, 0.62), P(0.1, 0.0, 0.55), 40, {"strength": 0.08}),
        cam(P(0.11, 0.5, 0.6), P(0.1, 0.0, 0.55), 40, {"strength": 0.08}), "in")},
    # Top-down on the counter: four comics slap down, one per name.
    "shop_stack": {"look": LOOK_SHOP, "camera": move(
        cam(P(1.55, 1.66, -0.4), P(1.55, 1.0, -0.62), 32, {"strength": 0.05}),
        cam(P(1.55, 1.58, -0.42), P(1.55, 1.0, -0.62), 32, {"strength": 0.05}), "in")},   # covers fill the frame
    # The Doom standee in the shop window, lit; the Bleeding Cool headline slides in (overlay news_rise).
    "shop_rise": {"look": LOOK_SHOP, "camera": move(
        cam(P(-2.5, 1.5, 1.6), P(-1.5, 1.6, -3.2), 28, {"strength": 0.08}),
        cam(P(0.5, 1.5, 1.4), P(1.0, 1.6, -3.2), 28, {"strength": 0.08}), "in_out")},
    # The cardboard Doom standee by the window in front; the collector and his comic behind.
    "shop_wait": {"look": LOOK_SHOP, "camera": move(
        cam(P(2.6, 1.35, 0.7), P(3.3, 1.45, 2.0), 30, {"strength": 0.12}),
        cam(P(2.45, 1.35, 0.6), P(2.0, 1.3, -0.3), 30, {"strength": 0.12}), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
