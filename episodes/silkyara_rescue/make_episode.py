"""Generates episodes/silkyara_rescue/episode.json (edit this file, not the JSON).

    python episodes/silkyara_rescue/make_episode.py

The hook: the mountain, then four shots inside the tunnel on one narration line.
  work      the night shift, busy, as the dumper drives in
  chai      a tea break; grit patters on a helmet, the lamps dip, he looks up
  collapse  the crown comes down between the crew and the way out; the dust takes the bore
  alive     later: headlamps in the dust, the power stutters back, forty-one faces

Everything inside the tunnel is placed in the gag's own frame (gags/tunnel_collapse.gd):
x across the bore (+x = screen right when looking toward the portal), z along it (-z = the way
out, the collapse plugs z = -36..-20), y up from the floor.
"""
import json
import math
import random
from pathlib import Path

HERE = Path(__file__).resolve().parent
DEPTH = -118.0     # the tunnel bay sits this far under its stage anchor


def P(x, y, z):
    """A point in the tunnel gag's frame."""
    return {"anchor": "tunnel", "offset": [round(-x, 3), round(y + DEPTH, 3), round(z, 3)]}


def S(x, y, z):
    """A point in the exterior gag's frame (gags/silkyara_exterior.gd): the portal faces +z."""
    return {"anchor": "slope", "offset": [round(-x, 3), round(y, 3), round(z, 3)]}


SECTION_Z = 2600.0   # the cutaway sits far in front of its anchor, clear of the exterior terrain


def X(x, y, z):
    """A point in the cutaway's frame (gags/mountain_section.gd): bore along x, way out at -x."""
    return {"anchor": "section", "offset": [round(-x, 3), round(y, 3), round(z + SECTION_Z, 3)]}


def SIXTY(offset=0.0):
    return {"line": "plug", "word": "Sixty", "offset": round(offset, 3)}


def T(offset=0.0):
    """Scene time relative to the roof letting go (the word "collapses")."""
    return {"line": "inside", "word": "collapses", "offset": round(offset - 0.05, 3)}


ALIVE = {"line": "alive", "word": "alive"}


def A(offset=0.0):
    return {"line": "alive", "word": "alive", "offset": round(offset, 3)}


PLUG = (0.0, -18.0)
SCAFFOLD_Y = 3.225
SEAT_Y = 0.1

rng = random.Random(41)

# ---------------------------------------------------------------------------------- the crew
# (id, character, x, z, facing (x, z), action, extras)
# extras: role, y, walk=(x, z, start, arrive, gait) a walk that ends as the mountain warns,
#         stay=True ducks where they stand instead of running, hero="anchor name"
W, LIME, BLUE, RED, ENG, DIG = ("toon_tunnel_worker", "toon_tunnel_worker_lime", "toon_tunnel_worker_blue",
                               "toon_tunnel_worker_red", "toon_tunnel_engineer", "toon_tunnel_digger")
CREW = [
    # On the scaffold, welding a rib.
    ("welder", W, -3.95, -6.0, (-9.0, -6.0), "fix", {"role": "welder", "y": SCAFFOLD_Y, "stay": True}),
    ("weld_mate", LIME, -3.25, -5.45, (-5.0, -6.2), "idle", {"role": "point", "y": SCAFFOLD_Y, "stay": True}),
    ("scaf_mid", RED, -3.2, -6.3, (1.0, -5.0), "idle", {"y": 1.725, "stay": True}),
    ("scaf_foot", W, -2.05, -5.1, (-3.4, -6.0), "idle", {"role": "point", "phase": 1.4}),
    # Tea on the pipe stack.
    ("chai_1", LIME, 3.5, 5.3, (1.2, 8.6), "sit", {"role": "chai", "y": SEAT_Y, "hero": "tea", "face": "happy"}),
    ("chai_2", W, 3.5, 4.15, (-2.0, 4.6), "sit", {"role": "chai", "y": SEAT_Y, "phase": 1.9, "face": "happy"}),
    ("chai_3", RED, 3.5, 3.0, (-2.0, 4.4), "sit_talk", {"y": SEAT_Y}),
    # Crossing the foreground with a barrow of spoil.
    ("barrow", RED, 2.7, 3.4, (-2.0, 1.9), "idle", {"role": "barrow", "walk": (-2.1, 1.9, -5.0, -1.0, "walk"), "stay": True}),
    # Two carrying a pipe down the bore.
    ("pipe_a", W, -1.05, -0.6, (-1.05, -9.0), "idle", {"role": "pipe_a", "mate": "pipe_b", "walk": (-1.05, -5.0, -5.4, -0.85, "walk_carry"), "stay": True}),
    ("pipe_b", LIME, -1.05, 2.0, (-1.05, -9.0), "idle", {"walk": (-1.05, -2.4, -5.4, -0.85, "walk_carry"), "stay": True}),
    # Cement on a shoulder, and the one walking back for the next bag.
    ("bag_1", LIME, -2.3, 0.4, (-1.9, -9.0), "idle", {"role": "bag", "walk": (-1.95, -3.9, -5.2, -0.7, "walk_carry"), "stay": True}),
    ("bag_2", W, -2.0, -3.4, (-2.6, 2.0), "idle", {"walk": (-2.7, 0.2, -5.0, -0.9, "walk"), "stay": True}),
    # People with somewhere to be.
    ("walk_1", BLUE, 0.3, -14.4, (0.3, 2.0), "idle", {"walk": (0.6, -7.3, -5.2, -0.6, "walk")}),
    ("walk_2", W, 1.9, 5.2, (1.9, -9.0), "idle", {"walk": (2.05, 0.3, -5.2, -0.8, "walk"), "stay": True}),
    ("walk_3", RED, -2.2, -13.4, (-2.2, 2.0), "idle", {"walk": (-2.5, -7.7, -5.0, -0.7, "walk")}),
    ("walk_4", LIME, 1.2, -7.4, (1.0, 4.0), "idle", {"walk": (1.1, -4.6, -5.3, -0.9, "walk")}),
    # The engineer and the foreman, looking at the rib going in.
    ("engineer", ENG, 0.45, -2.9, (-4.0, -6.0), "idle", {"role": "engineer"}),
    ("foreman", BLUE, 1.15, -3.35, (0.45, -2.9), "talk", {}),
    # Breaking and clearing spoil.
    ("dig_1", DIG, 2.1, -8.5, (3.2, -9.3), "chop", {}),
    ("dig_2", DIG, 2.35, -10.7, (3.3, -9.8), "chop", {"phase": 0.5}),
    ("dig_3", DIG, 1.95, -9.6, (3.3, -9.5), "chop", {"phase": 1.1}),
    ("dig_boss", RED, 1.35, -10.9, (3.0, -9.6), "fold_arms", {}),
    # Guiding the dumper in.
    ("signal", W, 1.15, -12.6, (2.6, -22.0), "idle", {"role": "signal"}),
    # Shotcrete on the -X wall.
    ("spray_1", BLUE, -3.55, -12.3, (-9.0, -12.9), "idle", {"role": "sprayer"}),
    ("spray_2", W, -3.1, -11.0, (-3.55, -12.3), "idle", {}),
    ("spray_3", LIME, -2.9, -13.7, (-3.6, -12.4), "fold_arms", {}),
    # Tying reinforcement by the -X wall.
    ("rebar_1", W, -3.75, -8.9, (-9.0, -9.2), "crouch", {}),
    ("rebar_2", RED, -3.7, -10.1, (-9.0, -9.9), "fix", {}),
    # Drilling for rock bolts on the +X wall.
    ("drill_1", BLUE, 4.0, -5.1, (9.0, -5.1), "push", {}),
    ("drill_2", W, 3.35, -5.9, (4.3, -5.3), "idle", {"role": "point"}),
    ("drill_3", LIME, 4.05, -6.5, (9.0, -6.5), "fix", {}),
    # Survey, mid bore.
    ("survey_1", ENG, -0.9, -6.8, (0.3, -22.0), "phone", {}),
    ("survey_2", W, -0.15, -7.5, (-0.9, -6.8), "idle", {}),
    # Stores at the camera end.
    ("store_1", LIME, -2.7, 2.9, (-3.6, 1.7), "talk", {}),
    ("store_2", W, -3.0, 0.3, (-3.6, 1.5), "pick_up", {}),
    ("radio", BLUE, 3.7, -0.5, (0.0, -6.0), "phone", {}),
    ("drums", RED, 4.0, -3.3, (4.2, -1.9), "interact", {}),
    ("mid_walk", W, 1.3, -6.0, (1.3, 4.0), "idle", {"walk": (1.5, -1.6, -5.3, -1.0, "walk")}),
    # Coming up from deeper in the bore.
    ("rear_1", W, -2.9, 11.6, (-2.9, -9.0), "idle", {"walk": (-2.9, 6.6, -5.2, -0.6, "walk"), "stay": True}),
    ("rear_2", LIME, -1.2, 12.4, (-1.2, -9.0), "idle", {"walk": (-1.3, 7.6, -5.2, -0.5, "walk"), "stay": True}),
    ("rear_3", BLUE, 1.2, 11.0, (1.2, -9.0), "idle", {"walk": (1.2, 5.5, -5.0, -0.7, "walk_carry"), "stay": True}),
]
assert len(CREW) == 41, len(CREW)

# Where the runners end up: rows across the bore, facing the rubble.
SLOTS = [(x, z) for z, xs in [
    (-6.4, [-1.4, 0.3, 2.0]), (-4.7, [-0.3, 1.3, 2.9]), (-3.0, [-2.9, 0.4, 2.1, 3.7]),
    (-1.2, [-3.5, -1.9, -0.2, 1.5, 3.1]), (0.7, [-2.3, 0.9, 2.6]), (2.5, [-2.0, 0.9, 2.3]),
    (4.6, [-2.6, -0.7, 1.3]), (7.0, [-1.5, 0.5, 2.3]), (9.0, [-3.2, -0.6, 1.2, 3.3]), (11.2, [-1.8, 0.4, 2.6]),
    (13.4, [-3.0, 1.0, 3.2])] for x in xs]


def final_spot(c):
    ex = c[6]
    if "walk" in ex:
        return ex["walk"][0], ex["walk"][1]
    return c[2], c[3]


def build_crew():
    stays = lambda c: bool(c[6].get("stay")) or "walk" in c[6]   # one route each: walkers duck where they stop
    taken = [final_spot(c) for c in CREW if stays(c)]
    free = [s for s in SLOTS if all(math.dist(s, t) > 0.95 for t in taken)]
    runners = sorted((c for c in CREW if not stays(c)), key=lambda c: final_spot(c)[1])
    actors, crew, ends = [], {}, {}
    for c in runners:
        fx, fz = final_spot(c)
        # Nearest free row first, staying on their own side of the dumper's lane.
        best = min(free, key=lambda s: (s[1] - fz) * 0.5 + abs(s[0] - fx) * 1.2 if s[1] > fz + 2.0 else 99.0)
        free.remove(best)
        ends[c[0]] = (round(best[0] + rng.uniform(-0.4, 0.4), 2), round(best[1] + rng.uniform(-0.5, 0.5), 2))
    for c in CREW:
        cid, char, x, z, face, action, ex = c
        a = {"id": cid, "character": char, "at": P(x, 0, z), "facing": P(face[0], 0, face[1]), "action": action}
        if "phase" in ex:
            a["phase"] = ex["phase"]
        fx, fz = final_spot(c)
        near = max(0.0, min(1.0, (fz + 17.0) / 30.0))        # 0 beside the fall, 1 far up the bore
        react = 0.08 + near * 0.3 + rng.random() * 0.12
        cues = [{"t": T(-0.74 + rng.random() * 0.12), "head": [-16, 0, 0], "head_turn": 0.18, "expression": "surprised"}]
        if "face" in ex:
            cues.insert(0, {"t": 0.0, "expression": ex["face"]})
        info = {k: ex[k] for k in ("role", "y", "mate", "hero", "phase") if k in ex}
        if "walk" in ex:
            wx, wz, start, arrive, gait = ex["walk"]
            a["route"] = {"via": [P(wx, 0, wz)], "gait": gait, "start": T(start), "arrive": T(arrive),
                          "then": "idle", "then_facing": P(PLUG[0], 0, PLUG[1])}
        if stays(c):
            info["cower"] = round(react, 3)
            cues.append({"t": T(react), "action": "crouch", "head": [0, 0, 0], "head_turn": 0.1, "expression": "panic"})
            ends[cid] = (fx, fz)
        else:
            ex_, ez = ends[cid]
            dist = math.dist((fx, fz), (ex_, ez))
            via = []
            # Round the dumper's lane and the scaffold rather than through them.
            if fz < -9.5:
                via.append(P(2.0 if fx > -0.5 else -2.3, 0, -8.6))
            via.append(P(ex_, 0, ez))
            a["route"] = {"via": via, "gait": "run", "start": T(react),
                          "arrive": T(max(react + 0.75 + dist / 7.0, 1.75 + rng.random() * 0.35)), "then": "idle",
                          "then_facing": P(PLUG[0], 0, PLUG[1])}
            cues.append({"t": T(react), "head": [0, 0, 0], "head_turn": 0.1, "expression": "panic"})
        after = rng.choice(["idle", "idle", "idle", "idle", "fold_arms", "crouch", "crouch", "shake_head", "call_out", "talk"])
        if cid == "radio":
            after = "phone"
        if ends[cid][1] < -6.9:
            after = "idle"        # nearest the rubble = nearest the last camera: faces, not helmet tops
        if "cower" in info and after != "crouch":
            info["rise"] = True
        cues.append({"t": A(-12.0 + rng.random() * 3), "action": after, "facing": P(PLUG[0] + rng.uniform(-3.5, 3.5), 0, PLUG[1]),
                     "expression": rng.choice(["nervous", "sad", "sad", "surprised", "crying", "determined"])})
        a["cues"] = cues
        actors.append(a)
        info["until"] = SANE_START
        crew[cid] = info
    # Real headlamp beams go to whoever ends up nearest the rubble (the front of the last shot).
    with_lamp = [c[0] for c in CREW if c[1] != ENG]
    for cid in sorted(with_lamp, key=lambda i: ends[i][1])[:18]:
        crew[cid]["lamp"] = True
    return actors, crew


# ---------------------------------------------------------------------------------- looks
TUNNEL = {
    "base": "night_fog", "time": "05:30", "ssao": True, "weather": {"fog": 0},
    "ambient": {"color": "#7d8fb5", "energy": 0.085},
    "sun": {"energy": 0}, "moon": {"energy": 0},
    "fog": {"begin": 40, "end": 160, "color": "#3b352f", "volumetric": 0.014, "anisotropy": 0.55, "length": 90},
    "glow": {"enabled": True, "intensity": 0.9, "bloom": 0.1, "threshold": 1.0},
    "grade": {"contrast": 1.1, "saturation": 1.06, "vignette": 0.3},
}
DARK = dict(TUNNEL, ambient={"color": "#8a8fa6", "energy": 0.03},
            fog={"begin": 40, "end": 160, "color": "#4a4138", "volumetric": 0.012, "anisotropy": 0.6, "length": 90},
            grade={"contrast": 1.12, "saturation": 1.0, "vignette": 0.38})


# ---------------------------------------------------------------------------------- outside
# The night shift walking up to the mouth and warming their hands at the fire drum.
OUTSIDE = [
    {"id": "out_walk_1", "character": W, "at": S(-3.0, 0, 41.5), "facing": S(-1.0, 0, 0), "action": "walk",
     "route": {"via": [S(-2.5, 0, 37.3)], "gait": "walk", "start": 0.0, "arrive": 3.4, "then": "idle"}},
    {"id": "out_walk_2", "character": LIME, "at": S(-0.6, 0, 43.4), "facing": S(0.4, 0, 0), "action": "walk",
     "route": {"via": [S(-0.3, 0, 38.9)], "gait": "walk", "start": 0.0, "arrive": 3.5, "then": "idle"}},
    {"id": "out_walk_3", "character": BLUE, "at": S(-2.6, 0, 20.5), "facing": S(-1.5, 0, 0), "action": "walk_carry",
     "route": {"via": [S(-2.2, 0, 16.6)], "gait": "walk_carry", "start": 0.0, "arrive": 3.4, "then": "idle"}},
    {"id": "out_fire_1", "character": RED, "at": S(-7.25, 0, 18.15), "facing": S(-6.2, 0, 17.5), "action": "interact"},
    {"id": "out_fire_2", "character": W, "at": S(-5.25, 0, 18.3), "facing": S(-6.2, 0, 17.5), "action": "talk", "phase": 0.7},
    {"id": "out_fire_3", "character": ENG, "at": S(-6.5, 0, 16.4), "facing": S(-6.2, 0, 17.5), "action": "fold_arms"},
]
OUTSIDE_LAMPS = ["out_walk_1", "out_walk_2", "out_walk_3"]

MOUNTAIN = {
    "base": "night_fog", "time": "05:30", "ssao": True, "weather": {"fog": 0},
    "ambient": {"color": "#6a7ca6", "energy": 0.55},
    "sun": {"energy": 0}, "moon": {"energy": 0, "visible": False},
    "sky": {"top": "#0c1a33", "horizon": "#8c8296", "stars": 0.25, "clouds": 0.1, "cloud_color": "#2c3550"},
    "lights": [{"elevation": 32, "azimuth": 20, "color": "#8197c8", "energy": 0.1, "shadows": False}],
    "fog": {"begin": 40, "end": 8000, "color": "#3a4766", "volumetric": 0.004, "anisotropy": 0.5, "length": 320},
    "ground_fog": {"density": 0.012, "height": 6.0, "falloff": 0.15, "color": "#3a4560"},
    "glow": {"enabled": True, "intensity": 0.9, "bloom": 0.1, "threshold": 1.0},
    "grade": {"contrast": 1.12, "saturation": 1.04, "vignette": 0.32},
}


# ---------------------------------------------------------------------------------- the cutaway
# Beat 4: the engineer flings the tape's hook over the plug; a trapped worker catches it on "Sixty".
TOE_A, TOE_B = -7.5, 68.0
T_THROW, T_CATCH = -1.30, 0.0          # relative to the word "Sixty"
SECTION_CAST = [
    {"id": "sec_eng", "character": ENG, "at": X(TOE_A - 1.7, 0, -1.6), "facing": X(TOE_A + 5.0, 3.0, 0.8), "action": "idle",
     "cues": [{"t": 0.0, "expression": "determined"},
              {"t": SIXTY(T_THROW - 0.35), "action": "throw"},
              {"t": SIXTY(0.15), "action": "idle", "expression": "happy"}]},
    {"id": "sec_resc_1", "character": W, "at": X(-13.0, 0, -2.6), "facing": X(0, 3, -2), "action": "torch",
     "cues": [{"t": 0.0, "expression": "nervous"}, {"t": SIXTY(0.3), "expression": "surprised"}]},
    {"id": "sec_resc_2", "character": LIME, "at": X(-11.2, 0, -4.0), "facing": X(0, 3, -2), "action": "fold_arms",
     "cues": [{"t": 0.0, "expression": "thinking"}]},
    {"id": "sec_resc_3", "character": BLUE, "at": X(-16.0, 0, -1.3), "facing": X(0, 3, -2), "action": "phone",
     "cues": [{"t": 0.0, "expression": "determined"}]},
    {"id": "sec_catch", "character": RED, "at": X(TOE_B + 1.7, 0, -1.6), "facing": X(TOE_B - 4.0, 3.0, 0.9), "action": "idle",
     "cues": [{"t": 0.0, "expression": "sad"},
              {"t": SIXTY(-0.55), "expression": "surprised", "head": [-14, 0, 0], "head_turn": 0.12},
              {"t": SIXTY(-0.42), "action": "interact"},
              {"t": SIXTY(0.05), "expression": "determined", "head": [0, 0, 0], "head_turn": 0.2},
              {"t": SIXTY(0.9), "expression": "nervous"}]},
]
for i, (dx, dz, char, act, face) in enumerate([(2.2, -3.4, W, "idle", "nervous"), (3.6, -1.4, LIME, "fold_arms", "sad"),
                                               (5.0, -3.9, BLUE, "idle", "thinking"), (6.4, -2.2, W, "lantern", "nervous"),
                                               (8.3, -3.0, RED, "idle", "sad"), (10.2, -1.6, LIME, "fold_arms", "determined")]):
    SECTION_CAST.append({"id": f"sec_trap_{i + 1}", "character": char, "at": X(TOE_B + dx, 0, dz), "facing": X(TOE_B - 3.0, 2.0, -2.0),
                         "action": act, "phase": round(i * 0.37, 2),
                         "cues": [{"t": 0.0, "expression": face}, {"t": SIXTY(0.2 + i * 0.07), "expression": "surprised"},
                                  {"t": SIXTY(0.8 + i * 0.06), "expression": "happy" if i % 2 else "determined"}]})

# The site kitchen at night: darker surroundings so the tube light and bulb under the tarp carry the shot.
KITCHEN_LOOK = dict(MOUNTAIN, ambient={"color": "#6a7ca6", "energy": 0.28},
                    grade={"contrast": 1.14, "saturation": 1.05, "vignette": 0.4})

SECTION_LOOK = dict(MOUNTAIN,
                    ambient={"color": "#6a7ca6", "energy": 0.35},
                    fog={"begin": 150, "end": 4000, "color": "#2b3650", "volumetric": 0.003, "anisotropy": 0.5, "length": 160},
                    ground_fog={"density": 0.0, "height": 6.0, "falloff": 0.15, "color": "#3a4560"})


SECTION_CLOSE_LOOK = dict(TUNNEL,
                          ambient={"color": "#8a8fa6", "energy": 0.18},
                          fog={"begin": 34, "end": 180, "color": "#3b352f",
                               "volumetric": 0.011, "anisotropy": 0.55, "length": 90})


# ---------------------------------------------------------------------------------- line 6
# "The lights still work. And so does one pipe."
# Shot 1: a worker inspecting the rubble by headlamp clicks it off on "lights": he doesn't need it.
# Shot 2: at the water main (the pipe that runs through the rubble), a worker spins a gate valve's
# handwheel and water bursts out on "pipe" (the construction water line kept working: AP, BBC).
SANE_START = {"line": "sane", "edge": "start", "offset": -0.35}


def L8(word, offset=0.0):
    return {"line": "sane", "word": word, "offset": round(offset, 3)}


MEAL_START = {"line": "meal", "edge": "start", "offset": -2.0}


def L11(word, offset=0.0):
    return {"line": "meal", "word": word, "offset": round(offset, 3)}


# Line 12 starts 0.3 s into scope_pipe; the scene begins with that shot.
FACES_START = {"line": "faces", "edge": "start", "offset": -0.3}


def L12(word, offset=0.0):
    return {"line": "faces", "word": word, "offset": round(offset, 3)}


def L6(word, offset=0.0):
    return {"line": "lifeline", "word": word, "offset": round(offset, 3)}


def L7(word, offset=0.0):
    return {"line": "feed", "word": word, "offset": round(offset, 3)}


L6_FROM = {"line": "lifeline", "edge": "start", "offset": -2.0}
VALVE_Z = -6.4
LIFE_CAST = [
    {"id": "life_lamp", "character": RED, "at": P(-1.7, 0, -10.0), "facing": P(-1.3, 0, -16.5), "action": "idle",
     "cues": [{"t": 0.0, "expression": "nervous", "head": [8, 0, 0], "head_turn": 0.2},
              {"t": L6("lights", 0.12), "expression": "surprised", "head": [-16, -10, 0], "head_turn": 0.22},
              {"t": L6("still", 0.1), "expression": "happy"}]},
    {"id": "life_valve", "character": LIME, "at": P(3.82, 0, VALVE_Z + 0.5), "facing": P(4.3, 0, VALVE_Z - 0.1), "action": "idle",
     "route": {"via": [P(3.05, 0, VALVE_Z - 0.75)], "gait": "walk", "start": {"line": "lifeline", "edge": "end", "offset": 0.4},
               "arrive": L7("Through", 0.3), "then": "idle", "then_facing": P(4.0, 0, VALVE_Z - 0.1)},
     "cues": [{"t": 0.0, "expression": "determined", "head": [14, 0, 0], "head_turn": 0.2},
              {"t": L6("pipe", 0.02), "expression": "surprised", "head": [-8, 40, 0], "head_turn": 0.12},
              {"t": L6("pipe", 0.35), "expression": "laugh"},
              {"t": L7("puffed", 0.1), "expression": "surprised"},
              {"t": L7("dry", 0.35), "expression": "star_eyes"},
              {"t": L7("fruit.", 0.5), "expression": "laugh"}]},
    {"id": "life_mate", "character": W, "at": P(2.25, 0, VALVE_Z + 1.7), "facing": P(3.9, 0, VALVE_Z), "action": "fold_arms",
     "route": {"via": [P(2.92, 0, VALVE_Z + 0.32)], "gait": "walk", "start": {"line": "lifeline", "edge": "end", "offset": 0.25},
               "arrive": L7("Through", 0.2), "then": "idle", "then_facing": P(3.95, 0, VALVE_Z)},
     "cues": [{"t": 0.0, "expression": "thinking"},
              {"t": L6("pipe", 0.1), "expression": "star_eyes"},
              {"t": L6("pipe", 0.22), "action": "jump"},
              {"t": L7("Through", 0.0), "expression": "nervous"},
              {"t": L7("oxygen", 0.06), "expression": "surprised", "head": [14, 0, 0], "head_turn": 0.08},
              {"t": L7("oxygen", 0.45), "expression": "happy", "head": [0, 0, 0], "head_turn": 0.3},
              {"t": L7("puffed", 0.1), "expression": "star_eyes", "head": [10, 0, 0], "head_turn": 0.25},
              {"t": L7("dry", 0.12), "expression": "laugh"},
              {"t": L7("fruit", 0.7), "expression": "love"}]},
]
LIFE_CREW = {
    "life_lamp": {"y": 0.0, "from": L6_FROM, "until": SANE_START, "lamp": True, "role": "lamp_click", "lamp_off": L6("lights", 0.0)},
    "life_valve": {"y": 0.0, "from": L6_FROM, "until": SANE_START, "role": "valve"},
    "life_mate": {"y": 0.0, "from": L6_FROM, "until": SANE_START},
}


# ---------------------------------------------------------------------------------- line 7
# "Through it come oxygen, puffed rice and dry fruit."
# Outside (the cutaway's rescue side): a rescuer rams a packet of puffed rice into the pipe's open end,
# the engineer seats the compressor hose on it. Inside: the mate holds his helmet upside down under the
# spout; air blasts out on "oxygen", puffed rice fills the helmet on "puffed rice", dry fruit on "dry fruit".
FEED_START = {"line": "feed", "edge": "start", "offset": -0.7}
FEED_CAST = [
    {"id": "feed_push", "character": BLUE, "at": X(TOE_A - 2.05, 0, -0.95), "facing": X(TOE_A - 0.8, 0, -1.25), "action": "idle",
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": L7("it", 0.12), "expression": "happy"}]},
]
FEED_BOWL = [3.33, 0.3, -6.4]


# ---------------------------------------------------------------------------------- line 8
# "To stay sane, they walk the tunnel and do yoga."
# Laps: pairs and singles walking away down the lit bore. Yoga: a leader on a cardboard mat, the group
# copying him; two in tree pose; one wobbles and topples onto his mat.
LAP_WALK = (-1.2, 13.0)     # start offset from the line, and how far they walk
LAP_CAST = []
for i, (x, z, char, face, turn) in enumerate([(1.25, 2.0, W, "laugh", 18), (0.35, 2.35, LIME, "happy", -16),
                                               (1.35, 5.1, BLUE, "determined", 0), (0.45, 5.45, RED, "happy", -12),
                                               (1.0, 8.4, W, "thinking", 0), (0.4, 10.9, LIME, "happy", 14),
                                               (1.35, 11.3, RED, "laugh", -14)]):
    LAP_CAST.append({"id": f"lap_{i + 1}", "character": char, "at": P(x, 0, z), "facing": P(x, 0, z + 5.0), "action": "idle",
                     "route": {"via": [P(x + (0.15 if i % 2 else -0.1), 0, z + LAP_WALK[1])], "gait": "walk",
                               "start": L8("To", LAP_WALK[0] - i * 0.06), "arrive": L8("To", LAP_WALK[0] + 11.0 - i * 0.06), "then": "idle"},
                     "cues": [{"t": 0.0, "expression": face, "head": [0, turn, 0], "head_turn": 0.3}]})
YOGA_AT = [  # (x, z, char, pose, face)
    (-1.8, 22.4, W, "y", "determined"), (-0.6, 22.4, LIME, "tree", "thinking"), (0.6, 22.4, BLUE, "wobble", "nervous"),
    (1.8, 22.4, RED, "y", "happy"), (-1.2, 20.6, LIME, "y", "sleepy"), (0.0, 20.6, W, "tree", "determined"),
    (1.2, 20.6, BLUE, "y", "happy")]
YOGA_CAST = [{"id": "yoga_lead", "character": RED, "at": P(0.0, 0, 25.4), "facing": P(0.0, 0, 21.0), "action": "idle",
              "cues": [{"t": 0.0, "expression": "happy"}, {"t": L8("yoga", 0.3), "expression": "determined"},
                       {"t": L8("yoga", 1.25), "expression": "shocked", "head": [6, 25, 0], "head_turn": 0.15}]}]
YOGA_CREW = {"yoga_lead": {"y": 0.0, "from": SANE_START, "role": "yoga", "yoga": {"start": L8("and", -0.05), "pose": "tree"}}}
for i, (x, z, char, pose, face) in enumerate(YOGA_AT):
    cid = f"yoga_{i + 1}"
    cues = [{"t": 0.0, "expression": face}]
    if pose == "wobble":
        cues += [{"t": L8("yoga", 0.35), "expression": "panic"}, {"t": L8("yoga", 1.05), "expression": "dead"}]
    else:
        cues += [{"t": L8("yoga", 1.2 + i * 0.05), "expression": "laugh", "head": [4, 20 if x < 0.6 else -20, 0], "head_turn": 0.18}]
    YOGA_CAST.append({"id": cid, "character": char, "at": P(x, 0, z), "facing": P(x, 0, z + 5.0), "action": "idle", "cues": cues})
    yoga = {"start": L8("do", -0.08 + i * 0.05), "pose": pose}
    if pose == "wobble":
        yoga["fall"] = L8("yoga", 0.65)
    YOGA_CREW[cid] = {"y": 0.0, "from": SANE_START, "role": "yoga", "yoga": yoga}
LINE8_CREW = {**YOGA_CREW, **{a["id"]: {"y": 0.0, "from": SANE_START} for a in LAP_CAST}}
for _c in LINE8_CREW.values():
    _c["until"] = MEAL_START
MATS = {"from": SANE_START, "until": MEAL_START, "at": [[0.0, 25.4, 0.0]] + [[x, z, 0.0] for x, z, *_ in YOGA_AT]}


# ---------------------------------------------------------------------------------- line 9
# "A twenty-five-tonne auger drill is flown in from Delhi by the air force."
# The hold (the rig chained inside the straining Hercules), air-to-air over the valley, the ramp at the airstrip.
AIR_Z = 6000.0


def AIR(x, y, z):
    """A point in the airstrip gag's frame (gags/airlift.gd): runway along z, the plane travels -z."""
    return {"anchor": "airstrip", "offset": [round(-x, 3), round(y, 3), round(z + AIR_Z, 3)]}


def PL(x, y, z):
    """A point riding with the plane (its origin)."""
    return {"anchor": "airlift.plane", "offset": [round(-x, 3), round(y, 3), round(z, 3)]}


def L9(word, offset=0.0):
    return {"line": "airlift", "word": word, "offset": round(offset, 3)}


AIR_LOOK = {
    "base": "day", "time": "08:10", "ssao": True, "weather": {"fog": 0},
    "sun": {"elevation": 17, "azimuth": 125, "energy": 1.6, "color": "#ffe2b8", "shadows": True},
    "moon": {"energy": 0, "visible": False},
    "ambient": {"color": "#a9bcd6", "energy": 0.55},
    "sky": {"top": "#4f7fbf", "horizon": "#d8d4cb", "stars": 0, "clouds": 0.0},
    "fog": {"begin": 250, "end": 9000, "color": "#b4c0cc", "volumetric": 0.0006, "anisotropy": 0.6, "length": 300},
    "glow": {"enabled": True, "intensity": 0.6, "bloom": 0.05, "threshold": 1.1},
    "grade": {"contrast": 1.08, "saturation": 1.05, "vignette": 0.25},
}
AIR_HOLD_LOOK = dict(AIR_LOOK, ambient={"color": "#8a93a3", "energy": 0.07},
                     sun={"elevation": 17, "azimuth": 125, "energy": 0.0},
                     fog={"begin": 250, "end": 9000, "color": "#2a2e33", "volumetric": 0.02, "anisotropy": 0.5, "length": 40},
                     grade={"contrast": 1.12, "saturation": 1.0, "vignette": 0.35})
AIR_CAST = [
    {"id": "air_marshal", "character": W, "at": AIR(-5.0, 0, -24.0), "facing": AIR(0, 0, 0), "action": "torch",
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": L9("force", 0.3), "expression": "happy"}]},
    {"id": "air_officer", "character": ENG, "at": AIR(-19.5, 0, 21.5), "facing": AIR(0, 0, 10.0), "action": "fold_arms",
     "cues": [{"t": 0.0, "expression": "thinking"}, {"t": L9("force", 0.4), "expression": "star_eyes"}]},
    {"id": "air_crew", "character": BLUE, "at": AIR(-18.5, 0, 24.5), "facing": AIR(0, 0, 10.0), "action": "phone",
     "cues": [{"t": 0.0, "expression": "nervous"}, {"t": L9("force", 0.5), "expression": "happy"}]},
]


# ---------------------------------------------------------------------------------- line 10
# "The plan: push a steel pipe through the rubble, wide enough to crawl through."
# The auger rig at the rescue face drives the 800 mm pipe into the heap; a rescuer squeezes into a spare pipe.
def L10(word, offset=0.0):
    return {"line": "plan", "word": word, "offset": round(offset, 3)}


PLAN_START = {"line": "plan", "edge": "start", "offset": -1.6}
PLAN_CAST = [
    {"id": "plan_op", "character": BLUE, "at": X(TOE_A - 4.75, 0, -4.35), "facing": X(TOE_A - 4.95, 0, -2.6), "action": "idle",
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": L10("push", -0.25), "action": "interact"},
              {"t": L10("rubble", 0.2), "expression": "happy"}]},
    {"id": "plan_sig", "character": W, "at": X(TOE_A - 1.2, 0, -4.6), "facing": X(TOE_A, 0, -2.5), "action": "idle",
     "cues": [{"t": 0.0, "expression": "nervous"}, {"t": L10("push", -0.1), "action": "call_out", "expression": "determined"},
              {"t": L10("rubble", 0.0), "expression": "surprised"}]},
    {"id": "plan_eng", "character": ENG, "at": X(TOE_A - 8.6, 0, -5.0), "facing": X(TOE_A - 3.0, 0, -2.5), "action": "fold_arms",
     "cues": [{"t": 0.0, "expression": "thinking"}, {"t": L10("rubble", 0.3), "expression": "smug"}]},
    {"id": "plan_crawl", "character": RED, "at": X(TOE_A - 25.9, 0, -2.6), "facing": X(TOE_A - 31.0, 0, -2.6), "action": "idle",
     "route": {"via": [X(TOE_A - 27.75, 0, -2.6)], "gait": "sneak", "start": L10("wide", -0.35), "arrive": L10(13, 0.9),
               "then": "crouch"},
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": L10("crawl", 0.0), "expression": "nervous"},
              {"t": L10(13, 0.35), "expression": "grin"}]},
]


# ---------------------------------------------------------------------------------- line 11
# "Day nine. A narrow pipe gets through first, and the first hot meal goes in: khichdi, packed in bottles."
MEAL_CAST = [
    {"id": "meal_draw", "character": W, "at": P(-4.25, 0, 0.32), "facing": P(-5.0, 0, 0.6), "action": "idle",
     "cues": [{"t": 0.0, "expression": "determined", "head": [6, 0, 0], "head_turn": 0.2},
              {"t": L11("nine.", 0.35), "expression": "sad", "head": [0, 0, 0], "head_turn": 0.3}]},
    {"id": "meal_catch", "character": LIME, "at": P(-1.6, 0, -15.35), "facing": P(-1.6, 0, -17.5), "action": "idle",
     "cues": [{"t": 0.0, "expression": "nervous"}, {"t": L11("narrow", 0.3), "expression": "surprised"},
              {"t": L11("bottles.", -0.25), "expression": "star_eyes"}, {"t": L11("bottles.", 0.5), "expression": "love"}]},
    {"id": "meal_w1", "character": W, "at": P(-2.95, 0, -15.55), "facing": P(-1.6, 0, -16.6), "action": "idle",
     "cues": [{"t": 0.0, "expression": "sad"}, {"t": L11("narrow", 0.4), "expression": "shocked"},
              {"t": L11(7, 0.2), "expression": "happy"}, {"t": L11("bottles.", 0.6), "expression": "laugh"}]},
    {"id": "meal_w2", "character": BLUE, "at": P(-2.35, 0, -14.55), "facing": P(-1.6, 0, -16.6), "action": "fold_arms",
     "cues": [{"t": 0.0, "expression": "thinking"}, {"t": L11("narrow", 0.5), "expression": "surprised"},
              {"t": L11(7, 0.3), "expression": "cheer"}]},
]
MEAL_CREW = {a["id"]: {"y": 0.0, "from": MEAL_START} for a in MEAL_CAST}
for _id in ["meal_w1", "meal_w2"]:
    MEAL_CREW[_id]["lamp"] = True

# ---------------------------------------------------------------------------------- line 12
# "The next day, a camera crawls down the same pipe. For the first time, the world sees their faces."
# (21 Nov 2023: an endoscopic camera pushed through the 6-inch pipe; the first video of the 41 went out.)
# Shot 1: chase the endoscope head down the inside of the pipe toward the light. Shot 2: its POV as it noses
# out: the men crowd the lens and wave. Shot 3: outside, an official, the engineer and relatives lean in to the
# monitor that shows the same feed (a SubViewport camera on the scope's lens).
for _a in MEAL_CAST:
    _f = {"meal_catch": "laugh", "meal_w1": "cheer", "meal_w2": "laugh"}.get(_a["id"])
    if _f:
        _a["cues"] += [{"t": FACES_START, "expression": "surprised"}, {"t": L12("For", 0.1), "expression": _f}]
for _i, _id in enumerate(["meal_catch", "meal_w1", "meal_w2"]):
    MEAL_CREW[_id].update({"role": "wave", "wave": {"start": L12("For", 0.05 * _i), "phase": _i * 1.3,
                                                    "hand": "l" if _i == 1 else "r"}})
FACE_AT = (-1.6, 1.0, -16.07)     # the scope's lens once it is out
FACES_CAST = []
for _i, (_x, _z, _char, _face) in enumerate([(-0.85, -15.15, W, "laugh"), (-2.3, -14.85, RED, "cheer"),
                                              (-1.15, -14.35, BLUE, "happy"), (-2.0, -13.95, LIME, "laugh")]):
    FACES_CAST.append({"id": f"face_{_i + 1}", "character": _char, "at": P(_x, 0, _z), "facing": P(*FACE_AT),
                       "action": "idle", "phase": round(_i * 0.41, 2),
                       "cues": [{"t": 0.0, "expression": "surprised"}, {"t": L12("For", 0.1 + 0.06 * _i), "expression": _face}]})
FACES_CREW = {a["id"]: {"y": 0.0, "from": FACES_START, "lamp": i % 2 == 0, "role": "wave",
                        "wave": {"start": L12("For", 0.08 + 0.07 * i), "phase": 0.7 + i * 1.1, "hand": "l" if i % 2 else "r"}}
              for i, a in enumerate(FACES_CAST)}

# Outside at the monitor (exterior gag frame; TV_AT = (-17.5, 0, 31), screen facing +z).
TV_CAST = [
    {"id": "tv_official", "character": "toon_official", "at": S(-17.0, 0, 32.0), "facing": S(-17.5, 1.3, 31.0), "action": "idle",
     "cues": [{"t": 0.0, "expression": "nervous"}, {"t": L12("world", 0.1), "expression": "surprised"},
              {"t": L12("faces.", 0.1), "expression": "happy"}]},
    {"id": "tv_engineer", "character": ENG, "at": S(-16.55, 0, 32.35), "facing": S(-17.5, 1.3, 31.0), "action": "fold_arms",
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": L12("faces.", 0.0), "expression": "grin"}]},
    {"id": "tv_brother", "character": "toon_shopkeeper", "at": S(-18.4, 0, 31.95), "facing": S(-17.5, 1.3, 31.0), "action": "idle",
     "cues": [{"t": 0.0, "expression": "sad"}, {"t": L12("sees", 0.0), "expression": "shocked"},
              {"t": L12("faces.", 0.05), "expression": "crying"}]},
    {"id": "tv_mother", "character": "toon_partner", "at": S(-18.0, 0, 31.7), "facing": S(-17.5, 1.3, 31.0), "action": "idle",
     "cues": [{"t": 0.0, "expression": "nervous"}, {"t": L12("faces.", -0.1), "expression": "crying"}]},
    {"id": "tv_father", "character": "toon_dadar_packer", "at": S(-17.95, 0, 32.45), "facing": S(-17.5, 1.3, 31.0), "action": "idle",
     "cues": [{"t": 0.0, "expression": "thinking"}, {"t": L12("faces.", 0.15), "expression": "laugh"}]},
]
KITCHEN_CAST = [
    {"id": "meal_cook", "character": "toon_site_cook", "at": S(11.0, 0, 27.32), "facing": S(11.0, 0, 29.5), "action": "idle",
     "cues": [{"t": 0.0, "expression": "happy"}, {"t": L11("khichdi,", 0.1), "expression": "grin"}]},
    {"id": "meal_runner", "character": BLUE, "at": S(12.5, 0, 27.4), "facing": S(12.5, 0, 29.0), "action": "idle",
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": L11("khichdi,", 0.3), "expression": "happy"}]},
]


# ---------------------------------------------------------------------------------- line 13
# "The big drill chews in. Twenty metres. Thirty. Forty-seven."
# An x-ray of the plug (the 800 mm casing cut open on the section plane, like line 7's oxygen pipe): the auger's
# head bites a boulder on "chews", then the string surges and stalls on each number (each surge is a time-lapse of
# days: sections welded on at the rig, pushed in). The counter rides the nose and lands on the spoken number.
# Times are from the line's start (word times from the aligned take: chews 0.92, in 1.35, Twenty 1.83,
# Thirty 3.31, Forty-seven 4.24).
def LD(x):
    return {"line": "drill", "edge": "start", "offset": round(x, 3)}


DRILL_START = LD(-0.25)
BORE_KEYS = [(-0.25, 0.0), (0.9, 1.3), (1.25, 1.6), (1.42, 1.6), (1.92, 20.0), (2.55, 20.0),
             (3.38, 30.0), (3.65, 30.0), (4.35, 47.0)]


def _in_out(x):
    return 4 * x ** 3 if x < 0.5 else 1 - (-2 * x + 2) ** 3 / 2


def bore_counter_keys(t_from):
    """The counter follows the same eased surges as the gag (sampled), from t_from on."""
    keys = []
    for (t0, d0), (t1, d1) in zip(BORE_KEYS, BORE_KEYS[1:]):
        n = 1 if d0 == d1 else 8
        for i in range(n):
            t = t0 + (t1 - t0) * i / n
            if t >= t_from:
                keys.append([LD(t), round(d0 + (d1 - d0) * _in_out(i / n))])
    keys.append([LD(BORE_KEYS[-1][0]), int(BORE_KEYS[-1][1])])
    return keys


# ---------------------------------------------------------------------------------- line 14
# "Day thirteen, it hits steel, and its blades snap off inside the pipe."  (Day 13 = 24 Nov 2023; Tribune timeline.)
# The day-nine chalk tally again, now twelve marks and the thirteenth drawn on "thirteen"; then the x-ray: the head
# grinds into a buried rib girder on "steel" (sparks), and on "snap" the front of the flight shears and jams.
# Word times from the line start: thirteen 0.26, steel 1.41, blades 2.51, snap 2.95, inside 3.54, pipe 3.98-4.18.
def LS(x):
    return {"line": "snap", "edge": "start", "offset": round(x, 3)}


# ---------------------------------------------------------------------------------- line 16
# "So a second rig starts drilling straight down, from the top of the mountain."
# (SJVN's vertical drilling from the hilltop began on 26 Nov 2023; it needed about 86 m.)
# A crawler drill rig on the ridge over the trapped section: the operator throws the lever on "rig", the rotary
# head spins and feeds down on "drilling"; then the camera plunges down the cut face along the planned borehole to
# the trapped men's lamps far below. Word times from the line start: rig 1.02, drilling 1.81, straight 2.31,
# down 2.81, top 3.9, mountain 4.4-4.72.
def LV(x):
    return {"line": "vertical", "edge": "start", "offset": round(x, 3)}


RIDGE_X, RIDGE_Z = 76.0, -1.8


def GA(anchor, x, y, z):
    """A point relative to one of the section gag's anchors (x mirrored like the other gag anchors)."""
    return {"anchor": "mountain_section." + anchor, "offset": [round(-x, 3), round(y, 3), round(z, 3)]}


RIDGE_CAST = [
    {"id": "ridge_op", "character": ENG, "at": X(RIDGE_X + 0.2, 0, RIDGE_Z + 2.2), "facing": X(RIDGE_X - 1.2, 0.6, RIDGE_Z + 4.0),
     "action": "idle", "cues": [{"t": 0.0, "expression": "determined"}, {"t": LV(1.6), "expression": "grin"}]},
    {"id": "ridge_hand", "character": W, "at": X(RIDGE_X + 3.3, 0, RIDGE_Z + 1.6), "facing": X(RIDGE_X + 1.85, 2.0, RIDGE_Z),
     "action": "fold_arms", "phase": 0.4, "cues": [{"t": 0.0, "expression": "thinking"}, {"t": LV(1.9), "expression": "surprised"}]},
]


# ---------------------------------------------------------------------------------- line 17
# "Then they call in twelve rat-hole miners."  (Twelve men, most from the Delhi firm Rockwell Enterprises,
# reached Silkyara on 26-27 Nov 2023: Outlook, Al Jazeera.) Daytime at the portal: a pickup rolls up and the
# twelve walk to the mouth in ordinary clothes with their own tools (club hammers, chisels, phawdas, steel taslas
# carried on the head); two officials step aside. Word times: call 0.4, twelve 0.95, rat-hole 1.49, miners 2.22.
def LM(x):
    return {"line": "miners", "edge": "start", "offset": round(x, 3)}


DAY_YARD = {"base": "day", "time": "15:40", "weather": {"clouds": 0.35, "fog": 0.0}, "ssao": True,
            "grade": {"contrast": 1.08, "saturation": 1.03, "vignette": 0.3}}
MINER_CHARS = ["toon_rathole_miner_a", "toon_rathole_miner_b", "toon_rathole_miner_c", "toon_rathole_miner_d"]
MINER_TOOLS = ["hammer", "tasla", "phawda", "hammer", "chisel", "tasla", "hammer", "phawda", "tasla", "hammer", "chisel", "tasla"]
MINERS = []
# A loose group, not a file: where each one is when the shot opens (x, z), and how far he walks to the mouth.
_GROUP = [(-1.6, 9.0), (-2.7, 9.4), (-0.7, 9.9), (-3.4, 10.3), (-1.9, 10.6), (-2.9, 11.3), (-0.9, 11.2), (-1.5, 12.1),
          (-3.6, 12.0), (-2.4, 12.6), (-0.6, 12.9), (-1.8, 13.6)]
for _i, (_x, _z0) in enumerate(_GROUP):
    MINERS.append({"id": f"miner_{_i + 1}", "character": MINER_CHARS[_i % 4], "at": S(_x, 0, _z0), "facing": S(_x * 0.6, 0, 0.0),
                   "action": "walk", "phase": round(_i * 0.29, 2),
                   "route": {"via": [S(_x * 0.75, 0, _z0 - 4.2 - (_i % 3) * 0.3)], "gait": "walk",
                             "start": LM(-0.3 + (_i % 4) * 0.12), "arrive": LM(3.0)},
                   "cues": [{"t": 0.0, "expression": ["determined", "neutral", "thinking", "determined"][_i % 4]}]})
YARD_OFFICIALS = [
    {"id": "yard_official", "character": "toon_official", "at": S(0.6, 0, 6.2), "facing": S(-2.0, 0, 10.0), "action": "idle",
     "route": {"via": [S(1.9, 0, 5.6)], "gait": "walk", "start": LM(0.1), "arrive": LM(1.1), "then": "idle"},
     "cues": [{"t": 0.0, "expression": "nervous"}, {"t": LM(1.2), "expression": "surprised"}]},
    {"id": "yard_eng", "character": ENG, "at": S(-3.8, 0, 5.8), "facing": S(-2.5, 0, 10.0), "action": "fold_arms",
     "route": {"via": [S(-5.0, 0, 5.4)], "gait": "walk", "start": LM(0.2), "arrive": LM(1.2), "then": "fold_arms"},
     "cues": [{"t": 0.0, "expression": "thinking"}, {"t": LM(1.5), "expression": "determined"}]},
]
YARD_CAST = MINERS + YARD_OFFICIALS


def NOSE(x, y, z):
    """A point riding with the auger's nose (gag anchor; x mirrored like the other gag anchors)."""
    return {"anchor": "mountain_section.nose", "offset": [round(-x, 3), round(y, 3), round(z, 3)]}


X_CAM = {"at": {"anchor": "section", "offset": [0, 3, 20]}, "look_at": {"anchor": "section", "offset": [0, 2, 0]}, "lens_mm": 24}   # placeholder


def cam(at, look, lens, dof=None, **kw):
    c = {"at": P(*at), "look_at": P(*look), "lens_mm": lens}
    if dof:
        c["dof"] = dof
    c.update(kw)
    return c


def build():
    actors, crew = build_crew()
    episode = {
        "id": "silkyara_rescue",
        "title": "41 Workers Trapped Inside a Mountain",
        "set": "specs/sets/silkyara.json",
        "format": {"resolution": [1080, 1920], "fps": 30, "motion_blur": 2},
        "narration": {"model": "qwen3-tts-1.7b-customvoice", "voice": "Aiden"},
        "captions": {"enabled": True, "max_words": 2, "position": 0.87},
        "lines": [
            {"id": "dawn", "shot": "mountain", "at": 0.2, "text": "Before dawn in Uttarakhand."},
            {"id": "inside", "shot": "work", "at": 0.18,
             "text": "Forty-one workers are deep inside the Silkyara tunnel when part of it collapses."},
            {"id": "alive", "shot": "alive", "at": 0.85, "text": "They're alive."},
            {"id": "plug", "shot": "plug_catch", "at": 0.85, "text": "Sixty metres of rock now stand between them and the way out."},
            {"id": "space", "shot": "tunnel_space", "at": 0.25, "text": "Behind it: two kilometres of finished tunnel, eight and a half metres high."},
            {"id": "lifeline", "shot": "lifeline_lights", "at": 0.5, "text": "The lights still work. And so does one pipe."},
            {"id": "feed", "shot": "feed_out", "at": 0.35, "text": "Through it come oxygen, puffed rice and dry fruit."},
            {"id": "sane", "shot": "laps", "at": 0.3, "text": "To stay sane, they walk the tunnel and do yoga."},
            {"id": "airlift", "shot": "airlift_hold", "at": 0.35, "text": "A twenty-five-tonne auger drill is flown in from Delhi by the air force."},
            {"id": "plan", "shot": "plan_rig", "at": 0.3, "text": "The plan: push a steel pipe through the rubble, wide enough to crawl through."},
            {"id": "meal", "shot": "day9_tally", "at": 0.3, "text": "Day nine. A narrow pipe gets through first, and the first hot meal goes in: khichdi, packed in bottles."},
            {"id": "faces", "shot": "scope_pipe", "at": 0.3, "text": "The next day, a camera crawls down the same pipe. For the first time, the world sees their faces."},
            {"id": "drill", "shot": "auger_chew", "at": 0.25, "text": "The big drill chews in. Twenty metres. Thirty. Forty-seven."},
            {"id": "snap", "shot": "tally13", "at": 0.25, "text": "Day thirteen, it hits steel, and its blades snap off inside the pipe."},
            {"id": "short", "shot": "gap_short", "at": 0.2, "text": "About ten metres short."},
            {"id": "vertical", "shot": "ridge_rig", "at": 0.25, "text": "So a second rig starts drilling straight down, from the top of the mountain."},
            {"id": "miners", "shot": "miners_arrive", "at": 0.25, "text": "Then they call in twelve rat-hole miners."},
            {"id": "banned", "shot": "ph_banned", "at": 0.25, "text": "Rat-hole mining is so dangerous that it was banned in Meghalaya's coal mines in 2014."},
            {"id": "dig", "shot": "ph_dig", "at": 0.25, "text": "One after another, they crawl into the pipe and dig with hammers and chisels."},
            {"id": "twelve", "shot": "ph_twelve", "at": 0.25, "text": "Twelve metres, in about a day."},
            {"id": "through", "shot": "ph_through", "at": 0.25, "text": "Day seventeen, just after seven in the evening: they break through."},
            {"id": "out", "shot": "ph_out", "at": 0.25, "text": "Then all forty-one come out, one by one, on wheeled stretchers."},
            {"id": "ambulances", "shot": "ph_ambulances", "at": 0.25, "text": "Forty-one men. Forty-one ambulances waiting outside."},
            {"id": "bulldozer", "shot": "ph_bulldozer", "at": 0.25, "text": "Three months later, bulldozers come for the house of the man who led those miners, Vakeel Hasan."},
            {"id": "dda", "shot": "ph_dda", "at": 0.25, "text": "Delhi's development authority says the house stood on its land."},
            {"id": "street", "shot": "ph_street", "at": 0.25, "text": "He got forty-one men out of a mountain. That night, his family slept on the street."},
        ],
        "actors": YARD_CAST + RIDGE_CAST + OUTSIDE + KITCHEN_CAST + TV_CAST + FACES_CAST + SECTION_CAST + FEED_CAST + PLAN_CAST + LIFE_CAST + LAP_CAST + YOGA_CAST + MEAL_CAST + AIR_CAST + actors,
        "gags": [
            {"id": "mountain_section", "script": "gags/mountain_section.gd", "at": {"anchor": "section", "offset": [0, 0, SECTION_Z]}, "t": 0,
             "params": {"throw": SIXTY(T_THROW), "catch": SIXTY(T_CATCH), "thrower": "sec_eng", "catcher": "sec_catch",
                        "appear": {"feed_push": PLAN_START, **{a["id"]: PLAN_START for a in PLAN_CAST}},
                        "vanish": {i: PLAN_START for i in ["sec_eng", "sec_resc_1", "sec_resc_2", "sec_resc_3", "feed_push"]},
                        "rig": {"from": PLAN_START, "push0": L10("push", 0.0), "push1": L10("rubble", 0.45), "bite": L10("steel", 0.1), "dist": 2.3},
                        "spare": {"from": PLAN_START, "crawler": "plan_crawl"},
                        "xauger": {"from": DRILL_START, "chew": LD(0.97), "boulder_at": 1.3, "metres": 57,
                                   "keys": [[LD(t), d] for t, d in BORE_KEYS] + [[LS(1.38), 47.0], [LS(1.8), 47.3]],
                                   "girder": LS(-0.3), "hit": LS(1.45), "snap": LS(2.97)},
                        "ridge": {"from": LV(-0.3), "lever": LV(1.0), "start": LV(1.5), "down0": LV(1.6), "down1": LV(4.6), "deep": 6.0, "xray": LV(2.44),
                                  "crew": [a["id"] for a in RIDGE_CAST], "op": "ridge_op"},
                        "xpipe": {"from": FEED_START, "until": L7("puffed", 0.2), "flow": L7("Through", -0.15),
                                  "hit": L7("oxygen", 0.0), "jar1": L7("puffed", 0.05), "x0": TOE_A + 1.0, "x1": TOE_A + 40.0},
                        "wide": SIXTY(0.82), "measure_until": {"line": "lifeline", "edge": "start", "offset": -0.3},
                        "point_pipe": {"line": "lifeline", "word": "pipe"}, "light_start": {"line": "lifeline", "edge": "start", "offset": -0.3},
                        "light_on": {"line": "lifeline", "word": "lights"}}},
            {"id": "airlift", "script": "gags/airlift.gd", "at": {"anchor": "airstrip", "offset": [0, 0, AIR_Z]}, "t": 0,
             "params": {"land": L9("air", 0.05), "stop": L9("force", 0.55), "ramp": L9("force", 0.6)}},
            {"id": "collapse", "script": "gags/tunnel_collapse.gd", "at": {"anchor": "tunnel", "offset": [0, DEPTH, 0]}, "t": 0,
             "params": {"impact": T(0.0), "alive": ALIVE, "crew": {**crew, **LIFE_CREW, **LINE8_CREW, **MEAL_CREW, **FACES_CREW},
                        "tally": {"from": MEAL_START, "x": -4.6, "y": 1.38, "z": 1.0, "draw0": L11("Day", -0.15),
                                  "draw1": L11("nine.", 0.2), "drawer": "meal_draw",
                                  "later": [{"t": LS(-0.3), "marks": 12, "draw0": LS(0.2), "draw1": LS(0.62)}]},
                        "narrow": {"from": MEAL_START, "at": [-1.6, 1.0, -16.45], "t0": L11("narrow", -0.1), "t1": L11(7, 0.0),
                                   "bottle": L11("packed", 0.05), "catch": L11("packed", 0.45), "open": L11("bottles.", 0.25),
                                   "catcher": "meal_catch", "bottle_until": FACES_START}, "mats": MATS, "full_power": SANE_START,
                        "scope": {"from": FACES_START, "t0": FACES_START, "t_out": L12("pipe.", 0.3), "t_stop": L12("For", 0.45)},
                        "valve": {"z": VALVE_Z, "open": L6("pipe", 0.0), "close": L7("Through", -0.4)},
                        "jars": {"from": L7("Through", -0.4), "until": SANE_START,
                                 "list": [{"t": L7("puffed", 0.0), "kind": "rice", "catcher": "life_mate"},
                                          {"t": L7("dry", 0.0), "kind": "fruit", "catcher": "life_valve"}]},
                        "trickles": [
                            {"x": 3.5, "z": 5.3, "t": T(-1.95), "land": 1.55, "spread": 0.05, "build": 0.7},
                            {"x": 0.6, "z": -23.0, "t": T(-3.2), "build": 2.0, "spread": 0.12},
                            {"x": -1.6, "z": -27.0, "t": T(-2.0), "build": 1.4, "spread": 0.12},
                            {"x": 1.9, "z": -21.5, "t": T(-1.1), "build": 0.8, "spread": 0.15},
                            {"x": -0.8, "z": -19.0, "t": T(-0.7), "build": 0.5, "spread": 0.15},
                        ]}},
            {"id": "portal", "script": "gags/silkyara_exterior.gd", "at": "slope", "t": 0,
             "params": {"appear": {**{a["id"]: MEAL_START for a in KITCHEN_CAST}, **{a["id"]: FACES_START for a in TV_CAST},
                                   **{a["id"]: LM(-0.3) for a in YARD_CAST}},
                        "vanish": {a["id"]: {"line": "banned", "edge": "start", "offset": -0.3} for a in YARD_CAST},
                        "miners": {"from": LM(-0.3), "until": {"line": "banned", "edge": "start", "offset": -0.3},
                                   "truck": {"t0": LM(-0.3), "t1": LM(0.5), "z0": 24.0, "z1": 15.5, "x": -5.6},
                                   "tools": {m["id"]: MINER_TOOLS[i] for i, m in enumerate(MINERS)}},
                        "tv": {"from": FACES_START, "feed": "collapse.scope", "aim": "collapse.scope_ahead"},
                        "kitchen": {"from": MEAL_START, "pour0": L11("khichdi,", -0.05), "pour1": L11("khichdi,", 0.45), "cook": "meal_cook", "pourer": "meal_runner"},
                        "lamps": OUTSIDE_LAMPS, "truck": {"t0": 0.0, "t1": 3.2, "z0": 27.0, "z1": 17.5}}},
        ],
        "sfx": [
            {"sound": "rip", "at": LD(0.75), "gain": -6},
            {"sound": "thud", "at": LD(0.97), "gain": -2},
            {"sound": "whoosh", "at": LD(1.42), "gain": -9}, {"sound": "thud", "at": LD(1.92), "gain": -7},
            {"sound": "whoosh", "at": LD(2.55), "gain": -9}, {"sound": "thud", "at": LD(3.38), "gain": -7},
            {"sound": "whoosh", "at": LD(3.65), "gain": -9}, {"sound": "thud", "at": LD(4.35), "gain": -5},
            {"sound": "ding", "at": LD(4.35), "gain": -9},
            {"sound": "tick", "at": LS(0.22), "gain": -12, "repeat": 3, "every": 0.12},
            {"sound": "rip", "at": LS(1.38), "gain": -3}, {"sound": "thud", "at": LS(1.45), "gain": -4},
            {"sound": "thud", "at": LS(2.97), "gain": 0}, {"sound": "sting", "at": LS(2.97), "gain": -10},
            {"sound": "creak", "at": LS(3.3), "gain": -6},
            {"sound": "click", "at": LV(1.0), "gain": -4}, {"sound": "creak", "at": LV(1.5), "gain": -6},
            {"sound": "whoosh", "at": LV(2.5), "gain": -5},
            {"sound": "tick", "at": LM(0.35), "gain": -14, "repeat": 6, "every": 0.1},
            {"file": "audio/mountain_wind_short.wav", "at": 0, "gain": -10},
            {"file": "audio/underground.wav", "at": {"line": "inside", "offset": -0.18}, "gain": -13},
            # grit on a helmet, then the mountain: the recording's attack is 0.5 s in
            {"sound": "tick", "at": {"line": "inside", "word": "collapses", "offset": -1.0}, "gain": -14, "repeat": 6, "every": 0.1},
            {"sound": "creak", "at": {"line": "inside", "word": "collapses", "offset": -0.85}, "gain": -9},
            {"file": "audio/rockfall.wav", "at": {"line": "inside", "word": "collapses", "offset": -0.5}, "gain": -1},
            {"sound": "rip", "at": {"line": "inside", "word": "collapses", "offset": 0.22}, "gain": -9},
            {"sound": "thud", "at": {"line": "inside", "word": "collapses", "offset": 0.4}, "gain": -6},
            {"file": "audio/rockfall.wav", "at": {"line": "inside", "word": "collapses", "offset": 0.3}, "gain": -5},
            {"sound": "thud", "at": {"line": "inside", "word": "collapses", "offset": 0.85}, "gain": -7, "salt": 3},
            {"sound": "whoosh", "at": {"line": "inside", "word": "collapses", "offset": 1.2}, "gain": -7},
            {"file": "audio/cough.wav", "at": {"line": "alive", "offset": -0.7}, "gain": -9},
            {"file": "audio/cough.wav", "at": {"line": "alive", "offset": 1.15}, "gain": -13},
            # Beat 4: the throw, the tape running out over the rubble, the catch.
            {"file": "audio/underground.wav", "at": SIXTY(-1.9), "gain": -15},
            {"sound": "whoosh", "at": SIXTY(T_THROW - 0.025), "gain": -16},
            {"sound": "tick", "at": SIXTY(T_THROW + 0.05), "gain": -20, "repeat": 14, "every": 0.08},
            {"sound": "click", "at": SIXTY(T_CATCH), "gain": -6},
            {"sound": "ding", "at": SIXTY(0.0), "gain": -12},
            {"sound": "click", "at": L6("lights", 0.0), "gain": -8},
            {"sound": "tick", "at": L6("pipe", -0.95), "gain": -13, "repeat": 6, "every": 0.15},
            {"sound": "whoosh", "at": L6("pipe", -0.02), "gain": -7},
            {"sound": "rip", "at": L6("pipe", 0.0), "gain": -13},
            # Line 7: the ram, the coupling, the blast, rice pattering, nuts rattling.
            {"sound": "whoosh", "at": L7("Through", -0.15), "gain": -9},
            {"sound": "whoosh", "at": L7("it", 0.0), "gain": -6},
            {"sound": "tick", "at": L7("it", 0.1), "gain": -17, "repeat": 9, "every": 0.12},
            {"sound": "whoosh", "at": L7("puffed", -0.03), "gain": -8},
            {"sound": "click", "at": L7("puffed", 0.32), "gain": -9},
            {"sound": "whoosh", "at": L7("dry", -0.03), "gain": -8},
            {"sound": "click", "at": L7("dry", 0.32), "gain": -9},
            # Line 8: footsteps, the fall onto the cardboard.
            {"sound": "tick", "at": L8("To", -0.3), "gain": -21, "repeat": 10, "every": 0.24},
            {"sound": "thud", "at": L8("yoga", 1.07), "gain": -8},
            # Line 9: the hold creaks under the rig, the fly-past, the touchdown, the ramp.
            {"sound": "creak", "at": L9("twenty-five-tonne", 0.7), "gain": -9},
            {"sound": "whoosh", "at": L9("is", 0.2), "gain": -6},
            {"sound": "whoosh", "at": L9("by", -0.05), "gain": -3},
            {"sound": "thud", "at": L9("air", 0.05), "gain": -3},
            {"sound": "click", "at": L9("force", 0.6), "gain": -6},
            {"sound": "sting", "at": L9("force", 1.1), "gain": -10},
            # Line 10: the rams, the grinding bite, the squeeze.
            {"sound": "creak", "at": L10("push", -0.1), "gain": -8},
            {"sound": "rip", "at": L10("steel", 0.1), "gain": -10},
            {"sound": "tick", "at": L10("steel", 0.1), "gain": -15, "repeat": 10, "every": 0.11},
            {"sound": "thud", "at": L10("rubble", 0.0), "gain": -7},
            {"sound": "creak", "at": L10("crawl", 0.1), "gain": -12},
            # Line 11: chalk, the pipe grinding out, the dust, the pour, the catch, the cap.
            {"sound": "tick", "at": L11("Day", -0.1), "gain": -16, "repeat": 3, "every": 0.12},
            {"sound": "rip", "at": L11("narrow", -0.1), "gain": -12},
            {"sound": "thud", "at": L11(7, 0.0), "gain": -9},
            {"sound": "whoosh", "at": L11(7, 0.02), "gain": -12},
            {"sound": "pop", "at": L11("khichdi,", 0.3), "gain": -10},
            {"sound": "pop", "at": L11("packed", 0.05), "gain": -8},
            {"sound": "click", "at": L11("packed", 0.45), "gain": -8},
            {"sound": "pop", "at": L11("bottles.", 0.3), "gain": -9},
        ],
        "shots": [
            {"name": "mountain", "duration": 2.5, "look": MOUNTAIN,
             "note": "Before dawn: tilt down off the snow range, over the forested slope, to the lit mouth.",
             "camera": {"from": {"at": S(-46.0, 64.0, 190.0), "look_at": S(25.0, 75.0, -500.0), "lens_mm": 24},
                        "to": {"at": S(-5.6, 3.4, 47.0), "look_at": S(0.4, 4.4, 0.0), "lens_mm": 30, "dof": {"strength": 0.3, "focus": 38.0}},
                        "ease": "in_out"}},
            {"name": "work", "duration": 2.25, "look": TUNNEL,
             "note": "The night shift: a slow push down a busy bore as the dumper drives in.",
             "camera": {"from": cam((0.7, 1.0, 7.6), (-0.4, 2.7, -12.0), 20),
                        "to": cam((0.2, 1.12, 5.3), (-0.4, 2.6, -12.0), 21),
                        "ease": "linear"}},
            {"name": "chai", "duration": 1.3, "look": TUNNEL,
             "note": "Tea break. Grit patters on his helmet, the lamps dip, he looks up.",
             "camera": {"from": cam((2.45, 1.0, 7.5), (3.42, 1.42, 5.3), 34, {"strength": 0.5, "focus": 2.4}),
                        "to": cam((2.5, 0.98, 7.3), (3.42, 1.5, 5.3), 36, {"strength": 0.5, "focus": 2.2}),
                        "ease": "in_out"},
             "shake": [{"t": T(-0.78), "amount": 0.14}]},
            {"name": "collapse", "duration": 2.05, "look": TUNNEL,
             "note": "The crown comes down between the crew and the way out; the dust takes the bore.",
             "camera": {"from": cam((-0.5, 1.8, 1.6), (0.2, 3.3, -22.0), 34),
                        "to": cam((-0.6, 1.8, 4.2), (0.1, 2.9, -22.0), 31),
                        "ease": "in"},
             "shake": [{"t": T(-0.3), "amount": 0.15}, {"t": T(0.0), "amount": 0.6}, {"t": T(0.42), "amount": 0.9},
                       {"t": T(0.9), "amount": 0.7}, {"t": T(1.4), "amount": 0.5}]},
            {"name": "alive", "duration": {"fit": True, "min": 2.7, "tail": 0.95}, "skip": 13.0, "look": DARK,
             "note": "Later. Headlamps in the dust; the power stutters back on the word; forty-one faces.",
             "camera": {"from": cam((-0.4, 2.7, -12.2), (0.1, 1.15, -1.5), 30),
                        "to": cam((-0.3, 2.5, -11.0), (0.1, 1.2, -1.5), 31),
                        "ease": "out"}},
            # Beat 4 (the cutaway): throw, catch on "Sixty", track from the trapped men to the way out.
            {"name": "plug_throw", "duration": 0.95, "look": SECTION_CLOSE_LOOK,
             "note": "Rescue side of the plug: the engineer winds up and flings the tape's hook up into the gap.",
             "camera": {"from": {"at": X(TOE_A - 2.6, 1.4, 1.4), "look_at": X(TOE_A - 1.94, 1.3, -1.55), "lens_mm": 31, "dof": {"strength": 0.2}},
                        "to": {"at": X(TOE_A - 2.75, 1.6, 1.2), "look_at": X(TOE_A - 1.15, 1.55, -1.5), "lens_mm": 32, "dof": {"strength": 0.2}},
                        "ease": "in_out"}},
            {"name": "plug_catch", "duration": 1.75, "look": SECTION_CLOSE_LOOK,
             "note": "Trapped side: the hook shoots out of the gap, slides down, he catches it on 'Sixty'; 60 m lands.",
             "camera": {"from": {"at": X(TOE_B - 0.15, 1.48, 1.3), "look_at": X(TOE_B + 1.47, 1.48, -1.6), "lens_mm": 34, "dof": {"strength": 0.19}},
                        "to": {"at": X(TOE_B + 0.12, 1.42, 1.0), "look_at": X(TOE_B + 1.45, 1.45, -1.53), "lens_mm": 35, "dof": {"strength": 0.19}},
                        "ease": "in_out"}},
            {"name": "plug_wide", "duration": 3.6, "look": SECTION_LOOK,
             "note": "Pull out and track along the cutaway: the lit trapped men, 60 m of rubble, the way out.",
             "camera": {"from": {"at": X(TOE_B + 7.0, 11.0, 64.0), "look_at": X(TOE_B + 3.0, 14.0, 0.0), "lens_mm": 25},
                        "to": {"at": X(-93.0, 13.5, 76.0), "look_at": X(-92.0, 15.0, 0.0), "lens_mm": 25},
                        "ease": "in_out"}},
            {"name": "tunnel_space", "duration": {"fit": True, "min": 4.0, "tail": 0.45}, "look": dict(TUNNEL, ssr=True),
             "note": "Inside the surviving bore: move through the workers and look up to the ribbed crown.",
             "camera": {"from": cam((-0.4, 2.3, -11.5), (0.0, 1.4, 1.0), 28),
                        "to": cam((-0.1, 2.0, -8.0), (0.1, 5.6, 8.0), 26),
                        "ease": "in_out"}},
            {"name": "lifeline_lights", "duration": 1.85, "look": dict(TUNNEL, ssr=True),
             "note": "At the rubble, his headlamp in our eyes; he clicks it off on 'lights' and looks up: the lamps burn all the way down the bore.",
             "camera": {"from": cam((-1.2, 1.4, -13.6), (-1.95, 1.75, 2.0), 33),
                        "to": cam((-1.05, 1.62, -12.95), (-2.0, 2.35, 6.0), 31),
                        "ease": "in_out"}},
            {"name": "lifeline_pipe", "duration": 2.4, "look": dict(TUNNEL, ssr=True),
             "note": "The water main out of the rubble: he spins the gate valve open and water bursts out on 'pipe'.",
             "camera": {"from": cam((1.3, 2.15, -9.6), (3.85, 0.85, -6.2), 30),
                        "to": cam((1.6, 1.95, -9.1), (3.8, 0.85, -6.25), 33),
                        "ease": "in_out"},
             "shake": [{"t": L6("pipe", 0.02), "amount": 0.12}]},
            {"name": "feed_out", "duration": 2.0, "look": SECTION_LOOK,
             "note": "X-ray of the supply pipe through the rubble: blue oxygen lines race through it, a jar of puffed rice rides the air.",
             "camera": {"from": {"at": {"anchor": "mountain_section.jar", "offset": [-0.95, 0.32, 0.72]},
                                 "look_at": {"anchor": "mountain_section.jar", "offset": [0.45, -0.04, 0.0]}, "lens_mm": 24},
                        "to": {"at": {"anchor": "mountain_section.jar", "offset": [-0.62, 0.2, 0.52]},
                               "look_at": {"anchor": "mountain_section.jar", "offset": [0.4, -0.03, 0.0]}, "lens_mm": 22},
                        "ease": "in"},
             "shake": [{"t": L7("oxygen", 0.0), "amount": 0.3}]},
            {"name": "feed_in", "duration": 3.35, "look": dict(TUNNEL, ssr=True),
             "note": "Inside: jars shoot out of the supply line on puffs of air: puffed rice into one man's hands, dry fruit into the other's.",
             "camera": {"from": cam((4.55, 1.45, -4.95), (3.0, 1.0, -6.6), 24),
                        "to": cam((4.45, 1.38, -5.15), (3.0, 1.0, -6.6), 26),
                        "ease": "in_out"},
             "shake": [{"t": L7("puffed", 0.0), "amount": 0.15}, {"t": L7("dry", 0.0), "amount": 0.15}]},
            {"name": "laps", "duration": 2.35, "look": dict(TUNNEL, ssr=True),
             "note": "Days later: pairs and singles walking laps away from us down the lit bore, lamps receding.",
             "camera": {"from": cam((-0.6, 1.45, 0.4), (0.9, 1.25, 24.0), 28),
                        "to": cam((-0.4, 1.5, 3.1), (0.9, 1.3, 24.0), 28),
                        "ease": "linear"}},
            {"name": "yoga", "duration": 2.45, "look": dict(TUNNEL, ssr=True),
             "note": "Yoga on cardboard mats: the leader in front, the group copies; one wobbles and topples.",
             "camera": {"from": cam((1.7, 1.3, 25.3), (-0.3, 0.95, 21.4), 26),
                        "to": cam((1.5, 1.22, 24.8), (-0.3, 0.92, 21.4), 28),
                        "ease": "in_out"}},
            {"name": "airlift_hold", "duration": 2.28, "look": AIR_HOLD_LOOK,
             "note": "Inside the Hercules: the 25-tonne auger rig chained in the hold; the floor flexes; 25 t lands on 'tonne'.",
             "camera": {"from": {"at": PL(1.05, -0.05, -11.3), "look_at": PL(-0.15, -0.3, -1.0), "lens_mm": 22},
                        "to": {"at": PL(0.85, -0.2, -10.4), "look_at": PL(-0.15, -0.35, -1.0), "lens_mm": 23},
                        "ease": "in_out"},
             "shake": [{"t": L9("A", 0.0), "amount": 0.12}, {"t": L9("twenty-five-tonne", 0.75), "amount": 0.3}]},
            {"name": "airlift_sky", "duration": 1.4, "look": AIR_LOOK,
             "note": "Air to air: the grey IAF Hercules, belly sagging, props a blur, dropping into the valley.",
             "camera": {"from": {"at": PL(-24.0, -6.0, -34.0), "look_at": PL(0.0, 1.5, 0.0), "lens_mm": 30},
                        "to": {"at": PL(-21.0, -5.0, -24.0), "look_at": PL(0.0, 1.5, 2.0), "lens_mm": 30},
                        "ease": "in_out"}},
            {"name": "airlift_ramp", "duration": 2.55, "look": AIR_LOOK,
             "note": "On the airstrip: it rolls to a halt, nose dips, the ramp drops on 'force' and the rig is there.",
             "camera": {"from": {"at": AIR(8.0, 1.5, 34.0), "look_at": AIR(0.0, 9.0, 22.0), "lens_mm": 24},
                        "to": {"at": AIR(6.5, 1.5, 30.0), "look_at": AIR(0.0, 2.2, 4.0), "lens_mm": 30},
                        "ease": "in_out"}},
            {"name": "plan_rig", "duration": 1.3, "look": SECTION_LOOK,
             "note": "The auger rig set up at the rescue face of the rubble, its crew at the controls.",
             "camera": {"from": {"at": X(TOE_A - 13.5, 3.4, -1.6), "look_at": X(TOE_A - 1.0, 0.9, -4.8), "lens_mm": 25},
                        "to": {"at": X(TOE_A - 12.4, 3.1, -1.6), "look_at": X(TOE_A - 0.8, 0.9, -4.8), "lens_mm": 26},
                        "ease": "in_out"}},
            {"name": "rig_push", "duration": 2.3, "look": SECTION_LOOK,
             "note": "Low along the casing: the rams shove, the spinning auger and the pipe bite into the heap.",
             "camera": {"from": {"at": X(TOE_A - 3.4, 1.55, -0.45), "look_at": X(TOE_A + 1.0, 1.25, -2.7), "lens_mm": 27},
                        "to": {"at": X(TOE_A - 3.0, 1.45, -0.5), "look_at": X(TOE_A + 1.2, 1.25, -2.7), "lens_mm": 29},
                        "ease": "in_out"},
             "shake": [{"t": L10("push", 0.0), "amount": 0.15}, {"t": L10("rubble", 0.0), "amount": 0.25}]},
            {"name": "pipe_crawl", "duration": 2.2, "look": SECTION_LOOK,
             "note": "From inside a spare 800 mm pipe: a rescuer squeezes in on hands and knees, squashed flat, and grins.",
             "camera": {"from": {"at": X(TOE_A - 30.2, 0.45, -2.6), "look_at": X(TOE_A - 22.0, 0.6, -2.6), "lens_mm": 24},
                        "to": {"at": X(TOE_A - 29.7, 0.44, -2.6), "look_at": X(TOE_A - 22.0, 0.58, -2.6), "lens_mm": 26},
                        "ease": "in_out"}},
            {"name": "day9_tally", "duration": 1.55, "look": dict(TUNNEL, ssr=True),
             "note": "Day nine: the ninth chalk tally on the lining wall.",
             "camera": {"from": cam((-3.75, 1.47, 2.05), (-4.95, 1.36, 0.88), 30),
                        "to": cam((-3.9, 1.45, 1.85), (-4.95, 1.36, 0.88), 32),
                        "ease": "in_out"}},
            {"name": "narrow_pipe", "duration": 2.15, "look": dict(TUNNEL, ssr=True),
             "note": "A 6-inch pipe noses out of the rubble with a puff of dust; the men lean in.",
             "camera": {"from": cam((0.45, 1.75, -13.7), (-1.55, 1.0, -16.4), 27),
                        "to": cam((0.25, 1.6, -14.05), (-1.55, 1.0, -16.4), 29),
                        "ease": "in_out"},
             "shake": [{"t": L11(7, 0.0), "amount": 0.15}]},
            {"name": "khichdi_cook", "duration": 2.1, "look": KITCHEN_LOOK,
             "note": "Outside at night under the tarp: the cook folds a big degchi of khichdi with both hands on the karchi; "
                     "steam backlit by the bulb, the lit tunnel mouth soft behind him. Slow push in.",
             "camera": {"from": {"at": S(12.3, 1.34, 29.75), "look_at": S(11.0, 0.98, 27.55), "lens_mm": 35, "dof": {"strength": 0.25, "focus": 2.5}},
                        "to": {"at": S(12.18, 1.3, 29.52), "look_at": S(11.0, 0.98, 27.55), "lens_mm": 40, "dof": {"strength": 0.25, "focus": 2.25}},
                        "ease": "in_out"}},
            {"name": "khichdi_pour", "duration": 1.25, "look": KITCHEN_LOOK,
             "note": "Overhead food insert at the bottling table: a karchi tips khichdi into an open wide-mouth bottle he steadies; it plops, "
                     "the bottle fills; filled, capped bottles soft in the foreground.",
             "camera": {"from": {"at": S(12.74, 1.56, 28.18), "look_at": S(12.56, 1.0, 27.9), "lens_mm": 50, "dof": {"strength": 0.45, "focus": 0.66}},
                        "to": {"at": S(12.72, 1.5, 28.15), "look_at": S(12.56, 1.0, 27.9), "lens_mm": 55, "dof": {"strength": 0.45, "focus": 0.6}},
                        "ease": "in_out"}},
            {"name": "khichdi_bottle", "duration": 2.0, "look": dict(TUNNEL, ssr=True),
             "note": "Inside, reverse angle over the narrow pipe: the bottle slides out into his hands; he lifts it by his face, "
                     "cap off, steam.",
             "camera": {"from": cam((-0.95, 1.85, -17.2), (-1.75, 1.15, -15.5), 26, {"strength": 0.3, "focus": 2.0}),
                        "to": cam((-1.0, 1.82, -17.1), (-1.75, 1.17, -15.5), 29, {"strength": 0.3, "focus": 1.9}),
                        "ease": "in_out"}},
            {"name": "scope_pipe", "duration": 3.25, "look": dict(TUNNEL, ssr=True),
             "note": "Inside the 6-inch pipe, riding just behind the endoscope head: its LED ring lights the rusty steel and the "
                     "weld seams racing past; the mouth is a warm disc of light ahead that grows.",
             "camera": {"from": {"at": {"anchor": "collapse.scope_chase"}, "look_at": {"anchor": "collapse.scope_chase_ahead"}, "lens_mm": 20},
                        "to": {"at": {"anchor": "collapse.scope_chase"}, "look_at": {"anchor": "collapse.scope_chase_ahead"}, "lens_mm": 18},
                        "ease": "linear"}},
            {"name": "scope_faces", "duration": 1.5, "look": dict(TUNNEL, ssr=True),
             "note": "The endoscope's view as it noses out: the men crowd the lens, laughing and waving.",
             "camera": {"at": {"anchor": "collapse.scope"}, "look_at": {"anchor": "collapse.scope_ahead"}, "lens_mm": 16}},
            {"name": "tv_screen", "duration": 1.0, "look": KITCHEN_LOOK,
             "note": "Outside at night, over the shoulders of the official and a mother: the site monitor shows the men waving.",
             "camera": {"from": {"at": S(-17.45, 1.45, 32.3), "look_at": S(-17.5, 1.31, 30.93), "lens_mm": 38, "dof": {"strength": 0.2, "focus": 1.4}},
                        "to": {"at": S(-17.47, 1.4, 32.0), "look_at": S(-17.5, 1.31, 30.93), "lens_mm": 40, "dof": {"strength": 0.2, "focus": 1.07}},
                        "ease": "in_out"}},
            {"name": "tv_react", "duration": 1.35, "look": KITCHEN_LOOK,
             "note": "From beside the monitor: the mother and brother, lit by the screen, break into tears; the official smiles.",
             "camera": {"from": {"at": S(-16.92, 1.3, 31.1), "look_at": S(-18.1, 1.2, 31.95), "lens_mm": 30, "dof": {"strength": 0.25, "focus": 1.3}},
                        "to": {"at": S(-17.0, 1.29, 31.16), "look_at": S(-18.1, 1.2, 31.95), "lens_mm": 33, "dof": {"strength": 0.25, "focus": 1.2}},
                        "ease": "in_out"}},
            {"name": "auger_chew", "duration": 1.75, "look": SECTION_LOOK,
             "note": "X-ray of the plug at the rescue face: the casing's cutting head grinds into a boulder and it bursts on "
                     "\"chews\"; spoil rides back along the spinning flight.",
             "camera": {"from": {"at": NOSE(2.5, 0.75, 3.1), "look_at": NOSE(0.45, 0.0, 0.15), "lens_mm": 25},
                        "to": {"at": NOSE(2.1, 0.62, 2.6), "look_at": NOSE(0.45, 0.0, 0.15), "lens_mm": 27},
                        "ease": "in_out"},
             "shake": [{"t": LD(0.97), "amount": 0.35}]},
            {"name": "auger_ride", "duration": 3.9, "look": SECTION_LOOK,
             "note": "Riding with the nose through the cut-open rubble: it surges and stalls, the counter on it lands on 20, 30, 47.",
             "camera": {"from": {"at": NOSE(1.35, 0.6, 2.5), "look_at": NOSE(-0.7, 0.0, 0.1), "lens_mm": 24},
                        "to": {"at": NOSE(1.2, 0.55, 2.3), "look_at": NOSE(-0.7, 0.0, 0.1), "lens_mm": 22},
                        "ease": "linear"},
             "shake": [{"t": LD(1.92), "amount": 0.18}, {"t": LD(3.38), "amount": 0.18}, {"t": LD(4.35), "amount": 0.25}]},
            {"name": "tally13", "duration": 1.2, "look": dict(TUNNEL, ssr=True),
             "note": "Day thirteen: the same chalk tally, now twelve marks; the thirteenth goes up.",
             "camera": {"from": cam((-3.95, 1.47, 2.05), (-4.95, 1.36, 0.92), 31),
                        "to": cam((-4.05, 1.45, 1.85), (-4.95, 1.36, 0.92), 33), "ease": "in_out"}},
            {"name": "steel_hit", "duration": 1.25, "look": SECTION_LOOK,
             "note": "X-ray at the nose: the head grinds into a buried rib girder; sparks fountain at us.",
             "camera": {"from": {"at": NOSE(1.7, 0.35, 1.9), "look_at": NOSE(0.6, 0.05, 0.2), "lens_mm": 24},
                        "to": {"at": NOSE(1.5, 0.3, 1.7), "look_at": NOSE(0.6, 0.05, 0.2), "lens_mm": 26}, "ease": "in_out"},
             "shake": [{"t": LS(1.45), "amount": 0.35}]},
            {"name": "blades_snap", "duration": 2.43, "look": SECTION_LOOK,
             "note": "Close on the flight: on \"snap\" it shears, a piece flies at us, the rest wedge in the casing and it "
                     "jams dead; pull back along the pipe on \"inside the pipe\".",
             "camera": {"from": {"at": NOSE(0.7, 0.55, 1.6), "look_at": NOSE(-0.6, 0.0, 0.2), "lens_mm": 24},
                        "to": {"at": NOSE(-1.6, 0.85, 3.0), "look_at": NOSE(-0.9, 0.0, 0.2), "lens_mm": 24}, "ease": "in_out"},
             "shake": [{"t": LS(2.97), "amount": 0.45}]},
            {"name": "gap_short", "duration": 2.2, "look": SECTION_LOOK,
             "note": "From behind the jammed head, down the rubble still in the way to the trapped side's lamps; a line grows "
                     "from the head to the far face and the counter lands on 10 m on \"ten\".",
             "camera": {"from": {"at": NOSE(-2.6, 0.6, 1.25), "look_at": X(68.5, 1.2, -1.8), "lens_mm": 28},
                        "to": {"at": NOSE(-1.9, 0.55, 1.15), "look_at": X(68.5, 1.25, -1.8), "lens_mm": 30}, "ease": "in_out"}},
            {"name": "ridge_rig", "duration": 2.7, "look": SECTION_LOOK,
             "note": "The mountain top over the trapped section: a crawler drill rig, its mast against the sky; the operator throws "
                     "the lever on \"rig\", the rotary head spins and feeds down on \"drilling\", mud spits from the collar.",
             "camera": {"from": {"at": GA("ridge", -4.6, 2.5, 8.4), "look_at": GA("ridge", 0.6, 3.2, 0.6), "lens_mm": 22},
                        "to": {"at": GA("ridge", -3.9, 2.3, 7.6), "look_at": GA("ridge", 0.6, 3.0, 0.6), "lens_mm": 23}, "ease": "in_out"},
             "shake": [{"t": LV(1.5), "amount": 0.12}]},
            {"name": "drill_down", "duration": 2.7, "look": SECTION_LOOK,
             "note": "X-ray down the cut face: from the bit a few metres in, the camera plunges along the glowing planned line "
                     "through about a hundred metres of rock to the trapped men's lamps below.",
             "camera": {"from": {"at": GA("hole", -1.6, 3.2, 4.6), "look_at": GA("hole", 0.0, -3.0, 0.0), "lens_mm": 24},
                        "to": {"at": GA("deep", -1.2, 4.5, 4.2), "look_at": GA("deep", 0.0, -1.0, -1.2), "lens_mm": 24}, "ease": "in_out"}},
            {"name": "miners_arrive", "duration": 3.1, "look": DAY_YARD,
             "note": "Day at the portal: twelve rat-hole miners walk to the mouth with their own tools, taslas on their heads; "
                     "a pickup has just pulled up behind; officials step aside. The count lands on 12 on \"twelve\".",
             "camera": {"from": {"at": S(0.9, 1.75, 1.6), "look_at": S(-1.8, 1.25, 11.0), "lens_mm": 30},
                        "to": {"at": S(0.8, 1.7, 2.1), "look_at": S(-1.8, 1.25, 11.0), "lens_mm": 32}, "ease": "in_out"}},
            {"name": "ph_banned", "duration": 6.9, "look": SECTION_LOOK, "camera": X_CAM},
            {"name": "ph_dig", "duration": 6.48, "look": SECTION_LOOK, "camera": X_CAM},
            {"name": "ph_twelve", "duration": 3.12, "look": SECTION_LOOK, "camera": X_CAM},
            {"name": "ph_through", "duration": 5.22, "look": SECTION_LOOK, "camera": X_CAM},
            {"name": "ph_out", "duration": 5.22, "look": SECTION_LOOK, "camera": X_CAM},
            {"name": "ph_ambulances", "duration": 3.12, "look": SECTION_LOOK, "camera": X_CAM},
            {"name": "ph_bulldozer", "duration": 7.74, "look": SECTION_LOOK, "camera": X_CAM},
            {"name": "ph_dda", "duration": 4.8, "look": SECTION_LOOK, "camera": X_CAM},
            {"name": "ph_street", "duration": 7.32, "look": SECTION_LOOK, "camera": X_CAM},
        ],
        "reveals": [
            {"id": "miner_count", "t": LM(0.3), "until": LM(2.9), "at": S(-1.8, 3.1, 11.0), "size": 0.75, "enter": "pop",
             "counter": {"from": 0, "to": 12, "land": {"line": "miners", "word": "twelve", "offset": 0.05}}, "sound": "ding"},
            {"id": "gap_line", "shape": "link", "t": {"line": "short", "word": "About", "offset": 0.0},
             "at": NOSE(0.45, 0.0, 0.35), "to": X(66.9, 1.37, 0.44), "size": 0.035},
            {"id": "gap_count", "t": {"line": "short", "word": "About", "offset": 0.1}, "at": X(60.9, 2.3, 1.3), "size": 0.65,
             "enter": "pop", "counter": {"from": 0, "to": 10, "land": {"line": "short", "word": "ten", "offset": 0.05}, "suffix": " m"},
             "sound": "ding"},
            {"id": "bore_count", "t": LD(1.45), "until": LS(0.9), "at": NOSE(0.0, 1.05, 0.25), "size": 0.3, "enter": "pop", "glow": 0.25,
             "counter": {"keys": bore_counter_keys(1.45), "suffix": " m"}},
            {"id": "air_count", "t": L9("twenty-five-tonne", -0.02), "until": L9("is", 0.0), "at": PL(0.0, 1.2, -6.6),
             "size": 0.42, "enter": "pop", "counter": {"from": 0, "to": 25, "land": L9("twenty-five-tonne", 0.72), "suffix": " TONNES"},
             "sound": "ding"},
            {"id": "plug_count", "t": SIXTY(-0.8), "until": SIXTY(0.82),
             "at": X(TOE_B + 1.43, 2.34, -1.3), "size": 0.24, "enter": "none", "glow": 0.25,
             "counter": {"keys": [[SIXTY(-0.8), 0], [SIXTY(-0.025), 59], [SIXTY(0.0), 60]], "suffix": " m"}},
        ],
    }
    (HERE / "episode.json").write_text(json.dumps(episode, indent=1) + "\n", encoding="utf-8")
    print(f"wrote episode.json: {len(actors)} workers, {len(episode['shots'])} shots")


if __name__ == "__main__":
    build()
