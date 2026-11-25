"""Marvel Studios, a boardroom at night (gags/boardroom.gd, gag id "board_set").

Frame: the plan wall at z -6 (the Kang card at (0, 2.75)); the table along x 0 from z -4.3 to 2.5 (top y 0.8); the TV
on a stand at (3.3, 1.75, -3.6); Feige at the wall at (0.75, 0, -4.85), or at the head of the table at (0, 0, 2.7) in
chapter 4. Cameras at +z looking -z.

Cold open: board_comic (o6: FF #5 slaps onto the table on "Comics."), board_crack (o7), board_ticket (o8).
Chapter 1: board_blank (c1e: Feige pins a blank card), board_flip (c1f: it flips to THE KANG DYNASTY on "Kang"),
board_loki (c1g), board_quantum (c1h), board_plan (k1), board_chart (c1k), board_fade (c1l: the line falls on
"fades"), board_arrest (c1m), board_news (k2 + the headline card), board_collapse (k3: the tear on "drops"),
board_fall (k4: the wall comes down on "comes down"), board_empty (c1n).
Chapter 3: board_titles (d16: the wall stands again: DOOMSDAY, SECRET WARS).
Chapter 4: board_contract (r11), board_question (r12), board_fox (r13: the film cans on "bought").
"""
from .common import W, frame, cam, move

P = frame("board", 40000.0)   # far from the other places

LOOK_BOARD = {
    "base": "night_fog", "time": "23:00",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.0},
    "sun": {"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "sky": {"top": "#04060a", "horizon": "#0b1220", "clouds": 0.0, "stars": 0.0,
            "panorama": "incoming/polyhaven_doom/hdris/modern_buildings_night_4k.hdr", "panorama_energy": 0.55,
            "panorama_yaw": 90},
    "ambient": {"color": "#202838", "energy": 0.12, "sky": 0.0},
    "fog": {"begin": 400, "end": 3000, "curve": 1.8, "volumetric": 0.0},
    "glow": {"enabled": True, "intensity": 0.7, "bloom": 0.04, "threshold": 1.1},
    "ssao": True,
    "grade": {"contrast": 1.18, "saturation": 0.98, "vignette": 0.45, "grain": 0.04},
}

PULL = W("k3", "drops", 0.0)
COLLAPSE = W("k4", "comes", 0.0)


def span(a, b):
    return [{"shot": a, "offset": -0.1}, {"shot": b}]


ACTORS = [
    {"id": "feige", "character": "toon_feige", "at": P(0.75, 0, -4.85), "facing": P(0.0, 0, -6.0), "action": "idle",
     "shown": [span("board_comic", "cinema_ticket"), span("board_blank", "shop_night"), span("board_titles", "hosp_bed")],
     "cues": [{"t": 0.0, "expression": "happy"},
              {"t": W("c1f", "Kang", 0.0), "expression": "star_eyes"},
              {"t": W("k1", "Kang.", 0.0), "expression": "smug"},
              {"t": W("c1k", 0), "facing": P(3.3, 0, -3.6), "expression": "nervous"},
              {"t": W("c1l", "fades", 0.0), "expression": "sad"},
              {"t": W("c1m", 0), "facing": P(0.75, 0, 2.0), "expression": "shocked"},
              {"t": W("k2", "December", 0.0), "facing": P(0.75, 0, 2.0), "expression": "surprised"},
              {"t": W("k2", "convicted", 0.0), "expression": "shocked"},
              {"t": W("k3", "Marvel", 0.0), "facing": P(0.0, 0, -6.0), "expression": "determined"},
              {"t": COLLAPSE, "facing": P(0.75, 0, 2.0), "expression": "panic"},
              {"t": W("c1n", 0), "expression": "sad"},
              {"t": W("d16", 0), "facing": P(0.0, 0, -6.0), "expression": "scheming"}]},
    {"id": "feige_table", "character": "toon_feige", "at": P(0.0, 0, 2.75), "facing": P(0.0, 0, -4.0), "action": "idle",
     "shown": [span("board_contract", "rocket_pad")],
     "cues": [{"t": 0.0, "expression": "smug"}, {"t": W("r11", "eighty", 0.0), "expression": "star_eyes"},
              {"t": W("r12", 0), "expression": "thinking"}, {"t": W("r13", "bought", 0.0), "expression": "grin"}]},
]

# RDJ's deal (r11): bills rain onto the boardroom floor and pile up; he swims on top of the heap.
HEAP = P(2.6, 0, -1.0)   # lit by the gag's heap_light (boardroom.gd: cash light)
ACTORS.append({"id": "rdj_cash", "character": "toon_rdj", "at": P(2.6, 0.5, -0.9), "facing": P(0.6, 0.5, 1.5), "keep_y": True,
               "action": "swim", "shown": [span("board_contract", "board_question")],
               "cues": [{"t": 0.0, "expression": "star_eyes"}, {"t": W("r11", "million", 0.0), "expression": "laugh"}]})
REVEALS = [
    {"id": "rdj_pay", "t": W("r11", 0, -0.1), "until": W("r12", 0),
     "at": P(2.6, 1.75, -1.0), "size": 0.36,
     "counter": {"from": 0, "to": 80000000, "prefix": "$", "suffix": "+", "commas": True,
                 "land": W("r11", "million", 0.0), "label": "REPORTED DEAL (VARIETY)"}, "sound": "ding"},
]

GAGS = [
    {"id": "board_set", "script": "gags/boardroom.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"pull": {"actor": "feige", "t": PULL}, "collapse": COLLAPSE,
                "pins_from": W("c1d", 0),
                "pins": {"0": W("c1e", "villain.", 0.0), "1": W("c1g", "Loki", 0.0), "2": W("c1h", "Quantumania", 0.0),
                         "3": W("c1i", "Comic-Con", 0.0), "4": W("c1i", "announces", 0.0)},
                "comic": W("o6", "Comics.", 0.0), "chart": {"t": W("c1k", 0), "fall": W("c1l", "fades", 0.0)},
                "rebuild": W("d15", 0), "cans": W("r13", "bought", 0.2)}},
    {"id": "cash_pile", "script": "library:cash_stream", "t": W("r11", 0, -2.2), "until": W("r12", 0), "at": HEAP,
     "params": {"fire": W("r11", 0, -2.0), "duration": 4.5, "count": 1600, "radius": 1.5, "height": 0.85,
                "flight": 0.7, "arc": 0.2, "size": 0.17, "seed": 11}},
]

WALL = P(0.0, 2.2, -6.0)
SHOTS = {
    # Low over the table: the comic drops and slaps down in front of us on "Comics."; the plan wall soft behind.
    "board_comic": {"look": LOOK_BOARD, "camera": move(
        cam(P(-0.05, 1.42, -1.25), P(-0.15, 0.8, -1.62), 40, {"strength": 0.12}),
        cam(P(-0.08, 1.32, -1.33), P(-0.15, 0.8, -1.62), 40, {"strength": 0.12}), "out")},
    # The plan wall, close and slowly tilting; strings and cards.
    "board_crack": {"look": LOOK_BOARD, "shake": [{"t": W("o7", "apart.", 0.0), "amount": 0.1}], "camera": move(
        cam(P(-1.0, 1.9, -3.4), P(0.2, 2.3, -6.0), 30, {"strength": 0.1}),
        cam(P(-0.7, 2.1, -3.7), P(0.2, 2.4, -6.0), 30, {"strength": 0.1}), "in_out")},
    # The comic on the table, the plan wall beyond: one old, one new.
    "board_ticket": {"look": LOOK_BOARD, "camera": move(
        cam(P(0.15, 0.98, -0.9), P(-0.2, 1.3, -6.0), 30, {"strength": 0.15}),
        cam(P(0.1, 1.0, -1.05), P(-0.2, 1.35, -6.0), 30, {"strength": 0.15}), "in_out")},
    # Chapter 1. Feige pins a blank card in the middle of the empty wall.
    "board_blank": {"look": LOOK_BOARD, "camera": move(
        cam(P(1.4, 1.7, -2.6), P(0.2, 2.2, -6.0), 32, {"strength": 0.1}),
        cam(P(1.2, 1.75, -3.0), P(0.1, 2.3, -6.0), 32, {"strength": 0.1}), "in_out")},
    # It flips round: THE KANG DYNASTY.
    "board_flip": {"look": LOOK_BOARD, "camera": move(
        cam(P(0.3, 2.45, -4.4), P(0.0, 2.75, -6.0), 40, {"strength": 0.12}),
        cam(P(0.25, 2.5, -4.65), P(0.0, 2.75, -6.0), 40, {"strength": 0.12}), "out")},
    # Loki flies in and pins on "Loki".
    "board_loki": {"look": LOOK_BOARD, "camera": move(
        cam(P(-1.2, 2.3, -4.1), P(-1.4, 2.4, -6.0), 35, {"strength": 0.1}),
        cam(P(-1.0, 2.35, -4.3), P(-1.3, 2.4, -6.0), 35, {"strength": 0.1}), "in_out")},
    # Quantumania pins on "Quantumania".
    "board_quantum": {"look": LOOK_BOARD, "camera": move(
        cam(P(-0.4, 1.75, -4.0), P(-1.0, 1.6, -6.0), 35, {"strength": 0.1}),
        cam(P(-0.5, 1.8, -4.2), P(-1.0, 1.65, -6.0), 35, {"strength": 0.1}), "in_out")},
    # From the head of the table, down its length under the pendant lamps to the plan wall; lands on the Kang card.
    "board_plan": {"look": LOOK_BOARD, "camera": move(
        cam(P(0.2, 1.55, 3.2), P(0.0, 1.9, -6.0), 28, {"strength": 0.08}),
        cam(P(0.3, 1.9, -1.4), P(0.0, 2.55, -6.0), 32, {"strength": 0.1}), "in_out")},
    # The TV draws the box-office line; Feige turns to it.
    "board_chart": {"look": LOOK_BOARD, "camera": move(
        cam(P(1.2, 1.6, -1.6), P(3.3, 1.75, -3.6), 35, {"strength": 0.1}),
        cam(P(1.5, 1.65, -1.9), P(3.3, 1.75, -3.6), 35, {"strength": 0.1}), "in_out")},
    # The line falls off a cliff on "fades"; over Feige's shoulder.
    "board_fade": {"look": LOOK_BOARD, "camera": move(
        cam(P(0.3, 1.45, -4.1), P(3.3, 1.65, -3.6), 30, {"strength": 0.14}),
        cam(P(0.4, 1.45, -4.3), P(3.3, 1.65, -3.6), 30, {"strength": 0.14}), "in")},
    # Feige stops; the news reaches him (the arrest headline card is added in post).
    "board_arrest": {"look": LOOK_BOARD, "camera": move(
        cam(P(1.7, 1.25, -2.5), P(0.75, 1.15, -4.85), 45, {"strength": 0.18}),
        cam(P(1.55, 1.24, -2.75), P(0.75, 1.15, -4.85), 45, {"strength": 0.18}), "in")},
    # Feige turns from the wall to us; the wall of titles soft behind him.
    # Feige framed on the left third: the euronews headline card (overlays/news_verdict) takes the right half.
    "board_news": {"look": LOOK_BOARD, "camera": move(
        cam(P(1.6, 1.3, -2.6), P(1.22, 1.15, -5.02), 40, {"strength": 0.16}),
        cam(P(1.45, 1.28, -2.9), P(1.18, 1.15, -5.0), 40, {"strength": 0.18}), "in_out")},
    # Close on the wall: Feige tears the Kang card off on "drops".
    "board_collapse": {"look": LOOK_BOARD, "camera": move(
        cam(P(-0.6, 1.75, -3.2), P(0.2, 2.3, -6.0), 30, {"strength": 0.08}),
        cam(P(-0.7, 1.7, -2.9), P(0.2, 2.2, -6.0), 30, {"strength": 0.08}), "out")},
    # Wide from the table: the cards rain and the cork wall topples on "comes down".
    "board_fall": {"look": LOOK_BOARD, "shake": [{"t": W("k4", "comes", 1.35), "amount": 0.18}], "camera": move(
        cam(P(-1.2, 1.5, -1.2), P(0.2, 1.8, -6.0), 26, {"strength": 0.06}),
        cam(P(-1.4, 1.45, -0.6), P(0.2, 1.6, -6.0), 26, {"strength": 0.06}), "out")},
    # Low, after: the wall face-down on the carpet, cards everywhere, Feige alone under a lamp.
    "board_empty": {"look": LOOK_BOARD, "camera": move(
        cam(P(1.3, 1.45, -2.2), P(0.3, 0.6, -5.0), 28, {"strength": 0.06}),
        cam(P(1.15, 1.4, -2.6), P(0.3, 0.6, -5.0), 28, {"strength": 0.06}), "in_out")},
    # After the fall: Feige among the scattered cards, a blank card in his hand. "Fast."
    "board_fast": {"look": LOOK_BOARD, "camera": move(
        cam(P(1.6, 1.2, -2.6), P(0.75, 1.1, -4.85), 35, {"strength": 0.15}),
        cam(P(1.4, 1.15, -3.0), P(0.75, 1.1, -4.85), 35, {"strength": 0.15}), "in")},
    # Chapter 3: the wall stands again with the new plan.
    "board_titles": {"look": LOOK_BOARD, "camera": move(
        cam(P(0.0, 2.0, -2.6), P(0.0, 2.6, -6.0), 32, {"strength": 0.08}),
        cam(P(0.0, 2.1, -3.2), P(0.0, 2.65, -6.0), 32, {"strength": 0.08}), "in")},
    # Chapter 4: bills pour from above onto a growing heap; RDJ swims across the top; the counter lands on "million".
    "board_contract": {"look": LOOK_BOARD, "camera": move(
        cam(P(0.9, 1.5, 2.0), P(2.6, 0.8, -1.0), 30, {"strength": 0.06}),
        cam(P(1.2, 1.7, 1.5), P(2.6, 1.0, -1.0), 30, {"strength": 0.06}), "in_out")},
    # Feige thinks, the long table and the rebuilt wall behind him.
    "board_question": {"look": LOOK_BOARD, "camera": move(
        cam(P(0.6, 1.2, 0.6), P(0.0, 1.15, 2.75), 40, {"strength": 0.15}),
        cam(P(0.5, 1.2, 0.9), P(0.0, 1.15, 2.75), 40, {"strength": 0.15}), "in_out")},
    # The two film cans slide down the table to him on "bought".
    "board_fox": {"look": LOOK_BOARD, "camera": move(
        cam(P(-0.9, 1.05, 0.2), P(0.0, 0.82, 1.6), 30, {"strength": 0.12}),
        cam(P(-0.8, 1.05, 0.5), P(0.0, 0.82, 1.6), 30, {"strength": 0.12}), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "reveals": REVEALS, "shots": SHOTS}
