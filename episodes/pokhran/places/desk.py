"""The US imagery analyst's office near Washington, 1998 (gags/analyst_room.gd, gag id "office_us").

Room frame: the desk against the front wall (z -2.2), top at y 0.62; the hero CRT screen centre at
(0, 1.02, -1.86) facing +z; the analyst sits at (0, 0, -0.62) facing -z; the wall TV at (0.55, 1.72, 2.05)
on the back wall; the window with blinds in the -x wall (frame right when looking +z).
"""
from .common import W, frame, cam, move
from . import lawn
from . import range as range_place
from . import rashtrapati

DESK_Z = 3000.0
P = frame("desk", DESK_Z)

SCREEN = (0.0, 1.02, -1.86)

LOOK = {
    "base": "night_fog", "time": "05:50", "ssao": True,
    "weather": {"fog": 0.0, "clouds": 0.0},
    "sun": {"energy": 0, "visible": False}, "moon": {"energy": 0, "visible": False},
    "ambient": {"color": "#46506a", "energy": 0.12},
    "sky": {"top": "#04050a", "horizon": "#0a0c12", "stars": 0},
    "fog": {"begin": 1, "end": 30, "color": "#10141c", "volumetric": 0.02, "anisotropy": 0.5, "length": 12},
    "ground_fog": {"density": 0.0},
    "glow": {"enabled": True, "intensity": 0.8, "bloom": 0.08, "threshold": 1.0},
    "grade": {"contrast": 1.14, "saturation": 0.92, "vignette": 0.38, "grain": 0.06},
    "practical_lights": {"level": 0},
}

ANNOUNCED = W("l1b", "announced", -0.1)

ACTORS = [
    {"id": "analyst", "character": "toon_analyst", "at": P(0.25, 0, -0.62), "facing": P(0.1, 0, -30),
     "action": "sit", "keep_y": True,
     # Off for senator (the CIA man has the room; the camera pulls back through his chair).
     "shown": [[0.0, {"shot": "senator"}], [{"shot": "review_drop"}, {"shot": "end_feed", "offset": 30.0}]],
     "cues": [
         {"t": 0.0, "expression": "sleepy"},
         {"t": ANNOUNCED, "expression": "shocked", "action": "sit_talk"},
         {"t": W("l1b", "it", 0.1), "expression": "panic"},
         {"t": W("l2a"), "expression": "nervous"},
         # 1998, the morning prints: he compares two identical views of the range, shrugs on "the same", nods off.
         {"t": W("l6c", offset=-0.6), "action": "sit", "expression": "side_eye", "head": [26, 8, 0], "head_turn": 0.3},
         {"t": W("l6c", "photos", 0.0), "head": [28, -10, 0], "head_turn": 0.35},
         {"t": W("l6c", "look", 0.0), "head": [28, 10, 0], "head_turn": 0.3},
         {"t": W("l6c", "same.", -0.15), "expression": "deadpan", "head": [-4, 0, 0], "head_turn": 0.3},
         {"t": W("l6c", "same.", 0.55), "expression": "sleepy", "head": [12, 0, 6], "head_turn": 0.6},
         # The feed shows soldiers playing cricket: he watches, bored, and slumps on "bored".
         {"t": W("l8d", offset=-0.6), "expression": "deadpan", "head": [4, 0, 0], "head_turn": 0.3},
         {"t": W("l8d", "bored", 0.0), "expression": "sleepy", "head": [38, 0, 10], "head_turn": 0.5},
         # The review lands on his desk on "assumed": he jumps, then sinks, then the tears.
         {"t": {"shot": "review_drop", "offset": -0.1}, "action": "sit", "expression": "nervous", "head": [-6, 25, 0], "head_turn": 0.3},
         {"t": W("l17b", "assumed", 0.0), "expression": "shocked", "head": [-16, 10, 0], "head_turn": 0.12},
         {"t": W("l17b", "never", 0.0), "expression": "sad", "head": [26, 0, 0], "head_turn": 0.8},
         {"t": W("l17b", "test.", 0.1), "expression": "crying", "head": [34, 0, 8], "head_turn": 0.6},
         # never_noticed (2002): dozing at his feed; Kalam on the TV behind him; he jolts awake on "noticed".
         {"t": {"shot": "never_noticed", "offset": -0.1}, "action": "sit", "expression": "sleepy", "head": [30, 0, 12], "head_turn": 0.01},
         {"t": W("l19c", "noticed,", -0.1), "action": "sit_talk", "expression": "shocked", "head": [-12, 0, 0], "head_turn": 0.12},
         # end_feed: back to the night shift as the Short began (it loops into hook_feed).
         {"t": {"shot": "end_feed", "offset": -0.05}, "action": "sit", "expression": "sleepy", "head": [0, 0, 0], "head_turn": 0.01},
     ]},
]

# The CIA man (a stand-in, no real person): he watches India's blast on the wall TV, then rounds on us, furious.
TV = (-0.55, 1.95, 2.0)     # gags/analyst_room.gd TV_AT
ACTORS.append({"id": "cia_agent", "character": "toon_agent", "at": P(-0.35, 0, 1.3), "facing": P(0.05, 0, -3.0),
               "action": "idle", "shown": [[{"shot": "senator", "offset": -0.1}, {"shot": "review_drop"}]],
               "cues": [{"t": 0.0, "expression": "furious"},
                        {"t": W("l17a", "colossal", -0.1), "action": "call_out", "expression": "furious"}]})
# review_drop: he stands at the desk's end with the review in hand and slams it down on "assumed".
ACTORS.append({"id": "cia_agent2", "character": "toon_agent", "at": P(-0.62, 0, -1.2), "facing": P(0.3, 0, -1.5),
               "action": "idle", "shown": [[{"shot": "review_drop", "offset": -0.1}, {"shot": "two_more"}]],
               "cues": [{"t": 0.0, "expression": "angry"}, {"t": W("l17b", "assumed", 0.3), "expression": "smug"}]})

GAGS = [{"id": "office_us", "script": "gags/analyst_room.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"wh": {"blast": W("l1a", "blew", -0.05), "rewind": W("l2a", "Not", -0.05),
                           "switch": W("l2a", "White", 0.05)},
                    "rewind": {"from": W("l3a", "Rewind", -0.1), "until": W("l3a", "1995.", 0.05), "to": "DEC 1995"},
                    "live": {"from": W("l8d", offset=-0.6), "until": W("l9a", offset=0.0),
                             "cam": range_place.P(-3.0, 260.0, 11.5), "ortho": 24.0, "stamp": "MAY 1998"},
                    "prints": {"cam": range_place.P(4.5, 260.0, 5.5), "ortho": 22.0, "slide": W("l6c", "morning", 0.0),
                               "hand": "analyst", "shrug": W("l6c", "same.", -0.1)},
                    "spill": W("l19c", "noticed,", -0.02),
                    "loop": {"from": {"shot": "end_feed", "offset": -0.05}, "end": W("l21b", edge="end", offset=0.15)},
                    "report": {"hand": "cia_agent2", "drop": W("l17b", "assumed", 0.0), "at": [-0.12, -1.48]},
                    "tv": {"on": ANNOUNCED, "cam": lawn.TV_CAM, "look": lawn.TV_LOOK, "fov": 26.0,
                           # senator: the TV is showing the blast footage (the replay window in range.py).
                           "feeds": [[{"shot": "senator", "offset": -0.1},
                                      range_place.P(range_place._BJ_CAM[0], round(range_place._BJ_Y, 3), range_place._BJ_CAM[1]),
                                      range_place.P(0.0, 190.0, 0.0), 34.0,
                                      {"bg": "#a9bcd4", "ambient": 1.25, "ambient_color": "#e8d8c0"}],
                                     # never_noticed (2002): Kalam, President, at Rashtrapati Bhavan on the news.
                                     [{"shot": "never_noticed", "offset": -0.1},
                                      rashtrapati.P(0.7, 6.2, -10.4), rashtrapati.P(0.0, 6.0, -12.6), 22.0,
                                      {"bg": "#9cb8dc", "ambient": 1.1, "ambient_color": "#efe2cc"}]]}}}]

SX, SY, SZ = SCREEN
STAMP = (-0.07, 1.158, -1.814)     # the date stamp on the hero CRT (gag-local)
SHOTS = {
    # Cold open: on the monitor, push in to the feed (America's White House) as it blows up.
    "hook_feed": {"look": LOOK, "camera": move(
        cam(P(SX - 0.12, SY + 0.12, SZ + 0.95), P(SX + 0.01, SY - 0.01, SZ), 38, {"strength": 0.2}),
        cam(P(SX, SY, SZ + 0.5), P(SX, SY, SZ), 40), "out"),
        "shake": [{"t": W("l1a", "blew", 0.0), "amount": 0.55}]},
    # Reverse: from beside the monitor at the analyst asleep; the TV behind him flicks on; he jolts awake.
    "hook_analyst": {"look": LOOK, "camera": move(
        cam(P(-0.17, 0.9, -1.67), P(0.17, 1.4, 0.8), 16, {"strength": 0.12}),
        cam(P(-0.14, 0.94, -1.56), P(0.16, 1.48, 0.8), 18, {"strength": 0.15}), "in_out")},
    # Back on the feed, framed as hook_feed ends: the blast rewinds, then the feed switches to Pokhran.
    "feed_rewind": {"look": LOOK, "hold": 0.45, "camera": move(
        cam(P(SX, SY, SZ + 0.52), P(SX, SY, SZ), 40),
        cam(P(SX, SY, SZ + 0.47), P(SX, SY, SZ), 40), "in_out")},
    # Back on the analyst's monitor, a little wider than the hook so the date stamp reads: the tape rewinds through
    # the years and lands on December 1995; a slow push.
    "rewind": {"look": LOOK, "camera": move(
        cam(P(SX + 0.02, SY + 0.03, SZ + 0.6), P(SX - 0.02, SY + 0.02, SZ), 40, {"strength": 0.15}),
        cam(P(STAMP[0], STAMP[1] - 0.03, STAMP[2] + 0.3), P(STAMP[0], STAMP[1] - 0.06, STAMP[2]), 40, {"strength": 0.12}), "in_out")},
    # High from the monitor's side: the morning prints in the foreground, the analyst above them. The second print slides
    # in beside the first (the same site, the same parked trucks); he looks from one to the other, shrugs on "the same",
    # nods off. A slow push.
    "photos_same": {"look": LOOK, "camera": move(
        cam(P(0.16, 1.3, -1.74), P(0.22, 0.78, -0.95), 24, {"strength": 0.12}),
        cam(P(0.18, 1.24, -1.62), P(0.23, 0.82, -0.9), 26, {"strength": 0.12}), "in_out")},
    # Over the analyst's head onto his monitor: the live feed from orbit, soldiers as specks playing cricket on the
    # sand; on "bored" his head sinks into the bottom of the frame. A slow push.
    "cricket_feed": {"look": LOOK, "camera": move(
        cam(P(0.12, 1.5, 0.05), P(SX + 0.02, SY - 0.08, SZ), 42, {"strength": 0.1}),
        cam(P(0.1, 1.45, -0.2), P(SX + 0.02, SY - 0.08, SZ), 46, {"strength": 0.1}), "linear")},
}

TX, TY, TZ = TV
SHOTS["senator"] = {
    # The blast fills the frame (it is on the CIA man's wall TV, CRT lines and all); on "colossal" the camera rips back
    # across the dark office and finds him in front of the TV, sunglasses on, rounding on us, furious.
    "look": LOOK, "camera": {
        "from": cam(P(TX, TY, TZ - 0.55), P(TX, TY, TZ), 34),
        "to": cam(P(0.1, 1.42, -1.05), P(-0.42, 1.45, 1.6), 26, {"strength": 0.1}),
        "ease": "in_out", "start": W("l17a", "colossal", -0.35), "end": W("l17a", "failure.", 0.05)}}

SHOTS["review_drop"] = {
    # Top-down on the desk: the review slams down on "assumed" (the mug and the globe jump); then the camera drops to
    # the analyst's face across the monitor as he sinks, then the tears.
    "look": LOOK, "shake": [{"t": W("l17b", "assumed", 0.0), "amount": 0.35}], "camera": {
        "from": cam(P(-0.05, 1.95, -1.25), P(-0.1, 0.62, -1.5), 30, {"strength": 0.1}),
        "to": cam(P(-0.02, 0.9, -1.72), P(0.25, 1.02, -0.62), 26, {"strength": 0.14}),
        "ease": "in_out", "start": W("l17b", "assumed", 0.35), "end": W("l17b", "never", 0.2)}}

SHOTS["end_feed"] = {
    # Out of the sky and into the feed: tight on the monitor (America's White House from orbit, intact, its pass
    # drifting), easing back to exactly hook_feed's opening frame, so the Short loops into its own first shot.
    "look": LOOK, "camera": {
        "from": cam(P(SX, SY, SZ + 0.28), P(SX, SY, SZ), 40, {"strength": 0.2}),
        "to": cam(P(SX - 0.12, SY + 0.12, SZ + 0.95), P(SX + 0.01, SY - 0.01, SZ), 38, {"strength": 0.2}),
        "ease": "in_out", "start": {"shot": "end_feed", "offset": 0.1}, "end": W("l21b", edge="end", offset=0.0)}}

SHOTS["never_noticed"] = {
    # From beside the monitor: the analyst, 2002, asleep at his feed; on the wall TV behind him Kalam, now President, at
    # Rashtrapati Bhavan. On "noticed" he jolts awake and the coffee goes over. A slow push.
    "look": LOOK, "camera": move(
        cam(P(-0.17, 0.9, -1.67), P(0.17, 1.4, 0.8), 18, {"strength": 0.12}),
        cam(P(-0.13, 0.95, -1.52), P(0.15, 1.45, 0.8), 20, {"strength": 0.15}), "in_out")}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
