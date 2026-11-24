"""A school courtyard on National Technology Day, 11 May (gags/school.gd, gag id "school").

Frame: the hero kid at the origin facing +z; the project tables at z -1.2; the banner across at y 2.75, z -1.8; the
schoolhouse verandah behind at z -6. Cameras stand at +z looking -z.

tech_day: "And every May 11th, India celebrates National Technology Day.": under the banner, among the projects, a kid
lifts his cardboard satellite high on its string on "National Technology Day"; the other kids go star-eyed.
"""
from .common import W, frame, cam, move
from . import range as range_place

SCHOOL_Z = 65000.0
P = frame("bunker", SCHOOL_Z)      # the bunker bay (see the handoff: spare anchors)

LOOK_SCHOOL = dict(range_place.LOOK_AFTERNOON, time="10:00",
                   sun={"elevation": 48, "azimuth": 60, "color": "#fff0d8", "energy": 3.0, "softness": 0.6,
                        "visible": False, "size": 1.2, "glow": 1.0, "shadows": True},
                   sky={"top": "#6d97cf", "horizon": "#dfe4e6", "clouds": 0.0},
                   ambient={"color": "#c0b6a4", "energy": 0.42, "sky": 0.6},
                   fog={"begin": 60, "end": 900, "curve": 1.6, "volumetric": 0.0})

TD = [{"shot": "tech_day", "offset": -0.1}, {"shot": "end_range"}]
LIFT = W("l20", "National", 0.0)

ACTORS = [
    {"id": "sk_hero", "character": "toon_school_kid_a", "at": P(0.0, 0, 0.0), "facing": P(0.0, 0, 5.0), "action": "idle",
     "shown": [TD], "cues": [{"t": 0.0, "expression": "happy"}, {"t": LIFT, "expression": "cheer"}]},
]
for _i, (_ch, _x, _z, _f) in enumerate([("toon_school_kid_b", -0.75, 0.25, (0.0, 0.0)), ("toon_school_kid_c", 0.8, 0.3, (0.0, 0.0)),
                                         ("toon_school_kid_d", -1.45, -0.2, (0.0, 0.0)), ("toon_market_kid", 1.5, -0.15, (0.0, 0.0))]):
    ACTORS.append({"id": f"sk_{_i}", "character": _ch, "at": P(_x, 0, _z), "facing": P(_f[0], 0, _f[1] + 0.4),
                   "action": "idle", "shown": [TD],
                   "cues": [{"t": 0.0, "expression": "happy"}, {"t": W("l20", "National", 0.2), "expression": "star_eyes",
                                                               "head": [-18, 0, 0], "head_turn": 0.3}]})
ACTORS.append({"id": "sk_teacher", "character": "toon_school_teacher", "at": P(-0.4, 0, -2.6), "facing": P(0.0, 0, 3.0),
               "action": "idle", "shown": [TD], "cues": [{"t": 0.0, "expression": "happy"},
                                                         {"t": W("l20", "Technology", 0.0), "expression": "laugh"}]})

GAGS = [{"id": "school", "script": "gags/school.gd", "t": 0, "at": P(0, 0, 0),
         "params": {"banner": ["NATIONAL TECHNOLOGY DAY", "11 MAY"], "satellite": {"actor": "sk_hero", "lift": LIFT}}}]

SHOTS = {
    # Low, kid height: the banner over the tables, the kids gathered; a slow push; on "National Technology Day" the hero
    # hoists his cardboard satellite on its string up under the banner, swinging; the others go star-eyed.
    "tech_day": {"look": LOOK_SCHOOL, "camera": move(
        cam(P(0.2, 1.0, 5.2), P(0.0, 1.55, -1.0), 28, {"strength": 0.08}),
        cam(P(0.15, 1.05, 3.8), P(0.0, 1.7, -1.0), 28, {"strength": 0.1}), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "shots": SHOTS}
