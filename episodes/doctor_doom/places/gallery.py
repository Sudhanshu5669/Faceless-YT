"""A dark museum gallery: the red-and-gold helmet and Doom's mask on two plinths (gags/gallery.gd, gag id "gallery_set").

Frame: the helmet plinth at x -1.1, the mask plinth at x +1.1, tops at y 1.15, centres at y ~1.42; the wall at z -2.6.
Cameras at +z looking -z.

Cold open: gal_helmet (o1), gal_circle (o2), gal_shadow (o3: the shadow becomes Doom's mask on "villain"),
gal_title (o4), gal_two (o5: the mask's plinth lights up on "two").
Chapter 4: gal_mirror (r7), gal_both (r8: three pulses on the three "Both"s), gal_light (r9: warm vs cold),
gal_eye (r17: the eye behind the slit moves on "different.").
"""
from .common import W, frame, cam, move

P = frame("board", 60000.0)
HX, MX, C = -1.1, 1.1, 1.42

LOOK_GALLERY = {
    "base": "night_fog", "time": "23:00",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.0},
    "sun": {"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "sky": {"top": "#020203", "horizon": "#030304", "clouds": 0.0, "stars": 0.0},
    "ambient": {"color": "#1a1d26", "energy": 0.05, "sky": 0.0},
    "fog": {"begin": 400, "end": 3000, "curve": 1.8, "volumetric": 0.02, "color": "#9a9a9a", "anisotropy": 0.6,
            "length": 20},
    "glow": {"enabled": True, "intensity": 0.8, "bloom": 0.05, "threshold": 1.1},
    "ssao": True,
    "grade": {"contrast": 1.22, "saturation": 1.0, "vignette": 0.55, "grain": 0.045},
}

GAGS = [
    {"id": "gallery_set", "script": "gags/gallery.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"spin": 0.03, "morph": W("o3", "villain", 0.0), "mask_on": W("o5", "two", -0.1),
                "both": [W("r8", 0), W("r8", 3), W("r8", 8)], "split": W("r9", "Tony", 0.0),
                "eye": {"t": W("r17", "different.", 0.0), "dx": 0.35}, "shield_on": W("c1d2", "Captain", 0.0)}},
]

SHOTS = {
    # Chapter 1: the memorial: the helmet among its candles on "Iron Man dies", the shield lit on "Captain America".
    "gal_farewell": {"look": LOOK_GALLERY, "camera": move(
        cam(P(HX + 0.9, 0.9, 1.6), P(HX - 0.1, 0.9, 0.0), 32, {"strength": 0.15}),
        cam(P(HX + 0.6, 0.85, 1.3), P(HX - 0.3, 0.7, 0.1), 32, {"strength": 0.18}), "in_out")},
    # Chapter 4: from the helmet to the mask: "the man who started it all returns as the villain".
    "gal_return": {"look": LOOK_GALLERY, "camera": move(
        cam(P(HX + 0.3, C, 1.3), P(HX, C, 0.0), 45, {"strength": 0.2}),
        cam(P(MX - 0.3, C, 1.3), P(MX, C, 0.0), 45, {"strength": 0.2}), "in_out")},
    # The helmet alone under its spot, candles below; a slow push.
    "gal_helmet": {"look": LOOK_GALLERY, "camera": move(
        cam(P(HX + 0.25, C + 0.05, 1.9), P(HX, C, 0.0), 50, {"strength": 0.18}),
        cam(P(HX + 0.2, C + 0.02, 1.35), P(HX, C, 0.0), 50, {"strength": 0.2}), "in_out")},
    # An arc round it, the candles crossing the foreground.
    "gal_circle": {"look": LOOK_GALLERY, "camera": move(
        cam(P(HX + 1.2, 1.0, 1.3), P(HX, C, 0.0), 40, {"strength": 0.16}),
        cam(P(HX - 0.9, 1.05, 1.45), P(HX, C, 0.0), 40, {"strength": 0.16}), "in_out")},
    # Wide on the helmet and the wall: the light flickers green and the shadow becomes Doom's mask on "villain".
    "gal_shadow": {"look": LOOK_GALLERY, "camera": move(
        cam(P(0.9, 1.25, 3.4), P(HX, 1.55, -1.3), 30, {"strength": 0.05}),
        cam(P(0.7, 1.3, 3.0), P(HX, 1.55, -1.5), 30, {"strength": 0.05}), "in_out")},
    # Close on the shadow mask on the wall.
    "gal_title": {"look": LOOK_GALLERY, "camera": move(
        cam(P(HX + 1.2, 1.85, 0.2), P(HX, 1.95, -2.6), 30, {"strength": 0.04}),
        cam(P(HX + 1.0, 1.85, -0.3), P(HX, 2.0, -2.6), 30, {"strength": 0.04}), "in_out")},
    # Wide and symmetrical: two plinths; the mask's spot comes up on "two".
    "gal_two": {"look": LOOK_GALLERY, "camera": move(
        cam(P(0.0, 1.45, 4.4), P(0.0, 1.3, 0.0), 28, {"strength": 0.06}),
        cam(P(0.0, 1.4, 3.6), P(0.0, 1.3, 0.0), 28, {"strength": 0.06}), "in_out")},
    # Low between the plinths: the helmet and the mask face each other above the lens.
    "gal_mirror": {"look": LOOK_GALLERY, "camera": move(
        cam(P(0.0, 0.75, 1.7), P(0.0, 1.5, 0.0), 24, {"strength": 0.08}),
        cam(P(0.0, 0.8, 1.35), P(0.0, 1.5, 0.0), 24, {"strength": 0.08}), "in_out")},
    # Both pieces; three pulses and quarter turns on the three "Both"s.
    "gal_both": {"look": LOOK_GALLERY, "camera": move(
        cam(P(0.0, 1.55, 2.7), P(0.0, 1.4, 0.0), 35, {"strength": 0.1}),
        cam(P(0.0, 1.5, 2.3), P(0.0, 1.4, 0.0), 35, {"strength": 0.1}), "in_out")},
    # Warm gold on the helmet, cold green on the mask; a slow drift from one to the other.
    "gal_light": {"look": LOOK_GALLERY, "camera": move(
        cam(P(-0.6, 1.4, 1.9), P(HX, C, 0.0), 40, {"strength": 0.12}),
        cam(P(0.6, 1.4, 1.9), P(MX, C, 0.0), 40, {"strength": 0.12}), "in_out")},
    # Extreme close-up on the mask's slit: the eye moves on "different.".
    "gal_eye": {"look": LOOK_GALLERY, "camera": move(
        cam(P(MX + 0.2, 1.66, 0.85), P(MX, 1.62, 0.0), 50, {"strength": 0.2}),
        cam(P(MX + 0.15, 1.65, 0.68), P(MX, 1.62, 0.0), 50, {"strength": 0.22}), "in")},
}

PLACE = {"gags": GAGS, "actors": [], "shots": SHOTS}
