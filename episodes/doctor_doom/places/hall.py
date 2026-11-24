"""Hall H, San Diego Comic-Con, 27 July 2024: the Marvel Studios panel (gags/hall_h.gd, gag id "hall").

Frame: the stage's front edge at z 0; the stage top at y 1.4; figures on stage at z -2.8..-3.4; the seats from z 4
to z 75. Cameras in the hall stand at +z looking -z.

hall_wide:   "July 2024. Hall H, San Diego Comic-Con."  high over 6,000 heads toward the lit stage; a slow crane in.
hall_walk:   "More than six thousand fans watch a line of masked men in green cloaks walk onto the stage."  from the
             front rows: the figures stride out of the haze, backlit into silhouettes; phones come up in the foreground.
hall_unmask: "Then one of them takes off his mask."  the centre figure reaches up and lifts the mask off on "mask.".
hall_reveal: "It's Robert Downey Junior. Iron Man himself."  reverse over his shoulder: the hall erupts.
hall_quote:  "And he tells the crowd: new mask, same task."  his smug close-up; the screens behind show it live.
"""
from .common import W, frame, cam, move

P = frame("hall", 0.0)
STAGE = 1.4

LOOK_HALL = {
    "base": "night_fog", "time": "21:00",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.0},
    "sun": {"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "sky": {"top": "#020203", "horizon": "#030304", "clouds": 0.0, "stars": 0.0},
    "ambient": {"color": "#1a2430", "energy": 0.05, "sky": 0.0},
    "fog": {"begin": 400, "end": 3000, "curve": 1.8, "volumetric": 0.013, "color": "#7f9a88", "anisotropy": 0.6,
            "length": 90},
    "glow": {"enabled": True, "intensity": 0.8, "bloom": 0.05, "threshold": 1.2},
    "ssao": True,
    "grade": {"contrast": 1.22, "saturation": 1.05, "vignette": 0.5, "grain": 0.04},
}

UNMASK = W("h3", "mask.", -0.1)


def span(a, b):
    return [{"shot": a, "offset": -0.1}, {"shot": b}] if b else [{"shot": a, "offset": -0.1}, W("e2", "task.", 3.0)]

CHEER = W("h3", "mask.", 0.35)

ACTORS = [
    {"id": "rdj", "character": "toon_rdj", "at": P(0.0, STAGE, -9.5), "facing": P(0.0, STAGE, 5.0), "keep_y": True,
     "action": "idle",
     "route": {"via": [P(0.0, STAGE, -2.8)], "gait": "walk", "start": W("h2", "line", -0.2), "arrive": W("h2", "stage.", 0.2)},
     "cues": [{"t": 0.0, "expression": "smug"}, {"t": UNMASK, "expression": "smug"},
              {"t": W("h4", "Robert", 0.0), "expression": "grin"}, {"t": W("h5", "new", 0.0), "expression": "smug"},
              {"t": W("h5", "task.", 0.1), "expression": "wink"},
              {"t": W("r1", 0), "expression": "smug"}, {"t": W("e1", "mask", 0.0), "expression": "scheming"},
              {"t": W("e2", "task.", 0.0), "expression": "wink"}]},
]
DOOM_SPANS = [span("hall_wide", "gal_helmet"), span("hall_why", "dress_oscar"), span("hall_russos", "board_contract"),
              span("hall_end", None)]
ACTORS[0]["shown"] = DOOM_SPANS
# Six more Doom figures fanning out to a line on both sides.
for _i, _x in enumerate([-1.7, 1.7, -3.4, 3.4, -5.1, 5.1]):
    ACTORS.append({"id": f"doom_{_i}", "character": "toon_doom_extra", "at": P(_x * 2.2, STAGE, -9.5 + 0.3 * (_i % 2)),
                   "facing": P(_x, STAGE, 5.0), "keep_y": True, "action": "idle",
                   "route": {"via": [P(_x, STAGE, -3.3 - 0.05 * abs(_x))], "gait": "walk",
                             "start": W("h2", "line", -0.5 + 0.12 * _i), "arrive": W("h2", "stage.", 0.1 + 0.1 * _i)},
                   "cues": [{"t": 0.0, "expression": "smug"}], "shown": DOOM_SPANS})
# 2022: Feige alone at the lectern; chapter 4: the Russos on stage.
ACTORS.append({"id": "feige_hall", "character": "toon_feige", "at": P(-3.2, STAGE, -3.0), "facing": P(0.0, STAGE, 6.0),
               "keep_y": True, "action": "talk", "shown": [span("hall_2022", "board_plan")],
               "cues": [{"t": 0.0, "expression": "happy"}, {"t": W("c1j", "Kang", 0.0), "expression": "grin"}]})
for _i, (_ch, _x) in enumerate([("toon_russo_joe", -2.6), ("toon_russo_anthony", -3.6)]):
    ACTORS.append({"id": f"russo_{_i}", "character": _ch, "at": P(_x, STAGE, -1.6), "facing": P(0.0, STAGE, 6.0),
                   "keep_y": True, "action": "idle", "shown": [span("hall_russos", "board_contract")],
                   "cues": [{"t": 0.0, "expression": "happy"}, {"t": W("r10", "Endgame,", 0.0), "expression": "grin"}]})

GAGS = [
    {"id": "hall_set", "script": "gags/hall_h.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"screens": [{"t": 0.0, "show": "logo"}, {"t": W("h3", "takes", 0.0), "show": "live", "actor": "rdj"},
                            {"t": W("c1i", 0, -0.3), "show": "logo"},
                            {"t": W("c1j", 0, -0.1), "show": "title", "text": "AVENGERS: THE KANG DYNASTY"},
                            {"t": W("r1", 0, -0.3), "show": "live", "actor": "rdj"},
                            {"t": W("r10", 0, -0.3), "show": "logo"},
                            {"t": W("e1", 0, -0.3), "show": "live", "actor": "rdj"}],
                "flare": W("e2", "task.", 0.25),
                "beams": {"focus": W("h3", "Then", 0.0), "x": 0.0, "z": -2.8},
                "flash": UNMASK, "phones": W("h2", "fans", 0.0), "cheer": CHEER,
                "follow": {"x": 0.0, "z": -2.8}}},
    {"id": "suits", "script": "library:doom_suit", "t": 0, "at": P(0, 0, 0),
     "params": {"actors": [{"actor": "rdj", "unmask": UNMASK, "remask": W("e2", "Same", 0.0)}]
                         + [{"actor": f"doom_{i}"} for i in range(6)]}},
]

SHOTS = {
    # High at the back of the hall over 6,000 heads: the stage a lit box of green haze under the giant screen. A slow
    # crane down and in.
    "hall_wide": {"look": LOOK_HALL, "camera": move(
        cam(P(10.0, 9.5, 40.0), P(0.0, 4.5, -6.0), 24),
        cam(P(7.0, 7.8, 30.0), P(0.0, 4.2, -6.0), 24), "in_out")},
    # A standing fan's view from the rows: heads and phones below, the line of figures striding out of the backlit
    # haze; a slow drift right and in.
    "hall_walk": {"look": LOOK_HALL, "camera": move(
        cam(P(-1.2, 2.35, 9.5), P(0.0, 2.5, -5.0), 45, {"strength": 0.08}),
        cam(P(0.8, 2.3, 8.3), P(0.0, 2.5, -4.5), 45, {"strength": 0.08}), "in_out")},
    # Low, close on the centre figure: he reaches up and lifts the mask off on "mask.".
    "hall_unmask": {"look": LOOK_HALL, "camera": move(
        cam(P(0.45, 2.7, 1.2), P(0.0, 2.85, -2.8), 50, {"strength": 0.12}),
        cam(P(0.3, 2.76, 0.3), P(0.0, 2.88, -2.8), 50, {"strength": 0.14}), "out")},
    # Reverse, over his shoulder from upstage: the hall erupts. A crane up.
    "hall_reveal": {"look": LOOK_HALL, "shake": [{"t": W("h4", "Robert", 0.0), "amount": 0.05}], "camera": move(
        cam(P(0.9, 3.4, -4.7), P(-1.0, 1.2, 22.0), 22),
        cam(P(1.4, 5.3, -5.7), P(-1.0, 0.9, 22.0), 22), "out")},
    # His smug close-up, low; the centre screen behind shows him live.
    "hall_quote": {"look": LOOK_HALL, "camera": move(
        cam(P(-0.35, 2.45, 0.2), P(0.0, 3.0, -2.8), 40, {"strength": 0.1}),
        cam(P(-0.25, 2.5, -0.5), P(0.0, 3.0, -2.8), 40, {"strength": 0.12}), "in_out")},
    # 2022: Feige at the stage edge; the hall roars as the title fills the screens.
    "hall_2022": {"look": LOOK_HALL, "camera": move(
        cam(P(-6.0, 3.2, 14.0), P(-2.0, 4.5, -8.0), 28, {"strength": 0.05}),
        cam(P(-4.5, 3.6, 11.5), P(-1.5, 5.0, -8.0), 28, {"strength": 0.05}), "in_out")},
    # AVENGERS: THE KANG DYNASTY on the giant screen; the crowd's phones in the foreground.
    "hall_kang": {"look": LOOK_HALL, "camera": move(
        cam(P(0.5, 2.4, 9.0), P(0.0, 8.6, -12.2), 32, {"strength": 0.05}),
        cam(P(0.3, 2.6, 7.5), P(0.0, 8.6, -12.2), 32, {"strength": 0.05}), "in")},
    # Chapter 4: back in Hall H, quieter: the line of masks, the unmasked man in the middle, a slow push.
    "hall_why": {"look": LOOK_HALL, "camera": move(
        cam(P(0.0, 2.6, 5.5), P(0.0, 2.7, -3.0), 35, {"strength": 0.08}),
        cam(P(0.0, 2.65, 4.2), P(0.0, 2.75, -3.0), 35, {"strength": 0.1}), "in")},
    # The Russos at the side of the stage, waving to the hall.
    "hall_russos": {"look": LOOK_HALL, "camera": move(
        cam(P(-1.4, 2.5, 2.3), P(-3.1, 2.55, -1.6), 40, {"strength": 0.12}),
        cam(P(-1.7, 2.5, 2.0), P(-3.1, 2.55, -1.6), 40, {"strength": 0.12}), "in_out")},
    # The bookend: he lifts the mask back to his face.
    "hall_end": {"look": LOOK_HALL, "camera": move(
        cam(P(-0.35, 2.45, 0.6), P(0.0, 2.9, -2.8), 40, {"strength": 0.1}),
        cam(P(-0.25, 2.5, -0.2), P(0.0, 2.9, -2.8), 40, {"strength": 0.12}), "in")},
    # The mask closes on "Same"; the screens flare green on "task."; hold, then black.
    "hall_final": {"look": LOOK_HALL, "duration": {"fit": True, "min": 1.0, "tail": 1.5},
                   "shake": [{"t": W("e2", "task.", 0.25), "amount": 0.06}], "camera": move(
        cam(P(0.0, 2.6, 1.6), P(0.0, 2.85, -2.8), 32, {"strength": 0.08}),
        cam(P(0.0, 2.9, 4.5), P(0.0, 3.4, -2.8), 28, {"strength": 0.06}), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
