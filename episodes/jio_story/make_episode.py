"""Writes specs/sets/jio_stage.json and episodes/jio_story/episode.json. Run: python episodes/jio_story/make_episode.py .
(The episode is generated: edit this file, not episode.json.)

The full Short: script lines 1-24 (episodes/jio_story/script.md), one shot per narration line.
Lines are cut at the same words as the single narration take, so the voice never changes."""
import json
import sys
from pathlib import Path

ROOT = Path(sys.argv[1])

bays = [
    {"id": "empire", "floor": "road", "floor_colors": ["#4a4152", "#8a7866"], "wall": "bazaar", "neon": [],
     "neon_colors": ["#5fe3ff", "#ff4fd8"], "size": [10, 8], "light": "#ffe7c4",
     "pedestal": {"style": "drums", "height": 1.8, "radius": 1.7}, "note": "Mukesh on a mountain of oil drums under a night skyline"},
    {"id": "tribute", "floor": "wood", "floor_colors": ["#8a5a3a", "#6a4028"], "wall": "haveli", "wall_color": "#e8c9a0",
     "neon": [], "neon_colors": ["#ffd27a", "#ff9ad5"], "size": [8, 6], "light": "#ffe2b8",
     "note": "Dhirubhai's garlanded portrait; the scales"},
    {"id": "split", "floor": "marble", "floor_colors": ["#efe6d6", "#c0392b"], "wall": "haveli", "wall_color": "#d98a7a",
     "neon": [], "neon_colors": ["#f2c230", "#ff9ad5"], "size": [9, 7], "sides": True, "light": "#ffe2b8", "note": "The family empire split: a cake on a table"},
    {"id": "street", "floor": "road", "floor_colors": ["#4a4152", "#8a7866"], "wall": "bazaar", "neon": [],
     "neon_colors": ["#5fe3ff", "#ff4fd8"], "size": [14, 10], "light": "#ffe7c4",
     "note": "India on 2G: an Indian market street at night, everyone staring at loading phones"},
    {"id": "rivals", "floor": "marble", "floor_colors": ["#e9dcc4", "#b8860b"], "wall": "haveli", "wall_color": "#8a2a3e",
     "neon": [], "neon_colors": ["#f2c230", "#ff9ad5"], "size": [14, 9], "sides": True, "light": "#ffe2b8",
     "note": "The telcos' durbar: crowned towers on bags of MINUTES; later they fall"},
    {"id": "war_room", "floor": "marble", "floor_colors": ["#3a3230", "#c9a227"], "wall": "haveli", "wall_color": "#2f5a55",
     "neon": [], "neon_colors": ["#f2c230", "#5fe3ff"], "size": [12, 10], "sides": True, "light": "#ffe2b8",
     "note": "Mukesh's war room: the map of India on the floor (circles, fibre, number one)"},
    {"id": "home", "floor": "wood", "floor_colors": ["#9a6a44", "#7a4e30"], "wall": "haveli", "wall_color": "#9fc7b0",
     "neon": [], "neon_colors": ["#ffd27a", "#ff9ad5"], "size": [9, 7], "sides": True, "light": "#ffe2b8",
     "note": "The family home: Isha's laptop, Akash's point"},
    {"id": "field", "floor": "road", "floor_colors": ["#3e3a48", "#7a6a5a"], "wall": "bazaar", "neon": [],
     "neon_colors": ["#5fe3ff", "#ff4fd8"], "size": [14, 10], "light": "#ffe7c4",
     "note": "Old 2G towers fall like dominoes; shiny 4G towers rise"},
    {"id": "launch", "floor": "wood", "floor_colors": ["#5a3a2a", "#3e281c"], "wall": "haveli", "wall_color": "#3a2a5a",
     "neon": ["arch"], "neon_colors": ["#3d7bff", "#ff4fd8"], "size": [10, 8], "light": "#ffe7c4",
     "pedestal": {"style": "neon", "height": 0.35, "radius": 1.25}, "note": "The launch stage: Jio, free stuff, the JioPhone, the podium"},
    {"id": "office", "floor": "wood", "floor_colors": ["#6a4a34", "#4e3626"], "wall": "haveli", "wall_color": "#33465e",
     "neon": [], "neon_colors": ["#5fe3ff", "#ffd84a"], "size": [8, 7], "sides": True, "light": "#ffe7c4",
     "note": "Infotel's tiny office: the cash-cannon buyout (gag pilot)"},
    {"id": "nation", "floor": "marble", "floor_colors": ["#2a2238", "#4a3a5a"], "wall": "none", "neon": [],
     "neon_colors": ["#5fe3ff", "#ff4fd8"], "size": [26, 26], "light": "#ffe7c4",
     "note": "524 million: the crowd stands in the shape of India, seen from above"},
    {"id": "court", "floor": "wood", "floor_colors": ["#8a6a4a", "#6a4e34"], "wall": "haveli", "wall_color": "#c9d6c0",
     "neon": [], "neon_colors": ["#ffd27a", "#ff9ad5"], "size": [10, 7], "sides": True, "light": "#fff1dc",
     "note": "The regulator's office: rivals crying predatory pricing"},
]
for _b in bays:
    _b["mood"] = "dramatic"
spec = {"schema_version": "0.1", "set": {"id": "jio_stage", "generator": "stage", "seed": 11, "params": {"bays": bays}},
        "look": "toon_drama",
        "preview": {"resolution": [540, 960], "views": [
            {"name": b["id"], "t": 1, "at": {"anchor": b["id"], "offset": [0, 2.6, b["size"][1] * 0.9]},
             "look_at": {"anchor": b["id"], "offset": [0, 1.0, 0]}, "lens_mm": 26} for b in bays]}}
(ROOT / "specs/sets/jio_stage.json").write_text(json.dumps(spec, indent=2) + "\n", encoding="utf-8")


def W(line, word, **k):
    return dict({"line": line, "word": word}, **k)


def L(line, **k):
    return dict({"line": line}, **k)


def fit(tail=0.15, mn=0.9):
    return {"fit": True, "tail": tail, "min": mn}


def face_cam(bay, z=6):
    return {"anchor": bay, "offset": [0, 1.0, z]}


def A(anchor, off):
    return {"anchor": anchor, "offset": off}


def S(anchor, sx, up, fwd):
    """A point in screen terms for things facing the camera (+z): sx > 0 is screen right.
    (Anchor offsets are [right, up, forward], and facing +z, 'right' is world -x.)"""
    return {"anchor": anchor, "offset": [-sx, up, fwd]}


def cam(at, look, lens=35):
    # Depth of field on every shot: the background softens, the subject pops (reference look).
    return {"at": at, "look_at": look, "lens_mm": lens, "dof": {"strength": 0.45}}


def move(a, b, ease="in_out"):
    return {"from": a, "to": b, "ease": ease}


# --- the map of India (same projection as the engine's "india" shape) ---------------------
MAP_SIZE = 5.0
MAP_Z = 0.6       # the map's centre, metres forward of the war_room anchor
MAP_TOP = MAP_SIZE * 0.03


def on_map(lon, lat, up=0.0):
    k = MAP_SIZE / 29.0
    x = (lon - 82.5) * k
    z = -(lat - 22.5) * k + MAP_Z
    return S("war_room", x, MAP_TOP + up, z)


# The 22 telecom circles, by a city in each (north to south, roughly).
CIRCLES = [(74.8, 34.1), (77.2, 31.6), (75.4, 30.6), (76.0, 29.0), (77.2, 28.6), (79.6, 28.4), (75.8, 26.9),
           (81.0, 26.8), (85.1, 25.6), (88.4, 26.7), (91.7, 26.1), (93.9, 24.6), (88.4, 22.6), (85.8, 20.3),
           (77.4, 23.3), (72.6, 23.0), (79.1, 21.1), (72.9, 19.1), (78.5, 17.4), (80.3, 13.1), (77.6, 13.0), (76.3, 10.0)]
# Fibre routes between cities (lon, lat), drawn as glowing beads in order.
FIBRE = [[(74.8, 34.1), (75.4, 30.6), (77.2, 28.6), (75.8, 26.9), (72.6, 23.0), (72.9, 19.1), (77.6, 13.0), (76.3, 10.0)],
         [(77.2, 28.6), (81.0, 26.8), (85.1, 25.6), (88.4, 22.6), (85.8, 20.3), (80.3, 13.1), (77.6, 13.0)],
         [(88.4, 22.6), (88.4, 26.7), (91.7, 26.1), (93.9, 24.6)],
         [(72.9, 19.1), (79.1, 21.1), (77.4, 23.3), (77.2, 28.6)], [(79.1, 21.1), (78.5, 17.4), (80.3, 13.1)]]


def beads(route, step=0.3):
    k = MAP_SIZE / 29.0
    out = []
    for (a, b) in zip(route, route[1:]):
        d = (((b[0] - a[0]) * k) ** 2 + ((b[1] - a[1]) * k) ** 2) ** 0.5
        n = max(1, int(d / step))
        for i in range(n):
            u = i / n
            out.append((a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u))
    out.append(route[-1])
    return out


# The narration: ONE take of the whole script; each entry below is one line (and starts one shot).
lines = [
    ("n1a", "Imagine you're Mukesh Ambani.", "open"),
    ("n1b", "You run refineries, petrol and plastics.", "empire_items"),
    ("n1c", "But you lost the one business your father dreamed about.", "lost"),
    ("n2", "In 2002, your father Dhirubhai wanted a phone call to cost less than a postcard.", "tribute"),
    ("n3a", "Then the family empire splits.", "split"),
    ("n3b", "Your brother Anil gets the phone company,", "anil_phone"),
    ("n3c", "and you agree to stay out of telecom.", "no_telecom"),
    ("n4", "So you watch.", "watch"),
    ("n5a", "In 2015, most Indians are online on slow 2G.", "street_2g"),
    ("n5b", "One gigabyte costs about 250 rupees,", "price"),
    ("n5c", "and every video buffers forever.", "buffer"),
    ("n6a", "Airtel, Vodafone and Idea make their money on voice calls.", "rivals"),
    ("n6b", "So data stays a luxury.", "luxury"),
    ("n7", "But you see something they don't.", "sees"),
    ("n8a", "In 2010, your deal with Anil ends.", "deal_ends"),
    ("n8b", "Weeks later, an unknown company called Infotel", "infotel"),
    ("n8c", "wins 4G airwaves in all 22 circles of India.", "circles"),
    ("n8d", "Within hours, you buy 95 percent of it.", "buy95"),
    ("n9a", "Then your daughter Isha comes home from Yale and says,", "isha"),
    ("n9b", "\"Dad, the internet in our house sucks.\"", "sucks"),
    ("n10a", "Your son Akash adds: telecom isn't about calls anymore.", "akash"),
    ("n10b", "It's about data.", "data_box"),
    ("n11a", "So you decide: data should be like oxygen.", "oxygen"),
    ("n11b", "Cheap enough for everyone.", "everyone"),
    ("n12a", "You don't fix old towers.", "old_towers"),
    ("n12b", "You build India's first 4G-only network,", "build4g"),
    ("n12c", "where even phone calls travel as data.", "volte"),
    ("n13a", "You lay three lakh kilometres of fibre.", "fibre"),
    ("n13b", "The bill: one and a half lakh crore rupees.", "bill"),
    ("n13c", "You call it the world's biggest startup.", "startup"),
    ("n14a", "On September 5th, 2016, you launch Jio.", "launch"),
    ("n14b", "And everything is free. Calls. Data. Apps.", "free3"),
    ("n15a", "Sixteen million people join in 26 days.", "join16"),
    ("n15b", "A hundred million in 170 days.", "join100"),
    ("n15c", "That's seven new customers every second.", "seven"),
    ("n16a", "Your rivals run to the regulator, crying predatory pricing.", "regulator"),
    ("n16b", "You say their networks are dropping your calls.", "dropped"),
    ("n17a", "And the insane part? You even give away the phone.", "insane"),
    ("n17b", "The JioPhone, at an effective price of zero.", "zero"),
    ("n18a", "Data crashes from 250 rupees a gigabyte to under 20.", "crash"),
    ("n18b", "India becomes the world's biggest consumer of mobile data.", "biggest"),
    ("n19a", "Telenor exits. Tata exits. Aircel goes bankrupt.", "exits"),
    ("n19b", "Even your brother's company shuts down.", "rcom"),
    ("n19c", "Vodafone and Idea merge just to survive.", "merge"),
    ("n20", "By 2019, Jio is number one.", "number1"),
    ("n21a", "Then Facebook pays 5.7 billion dollars for a slice.", "facebook"),
    ("n21b", "Google pays 4.5 billion.", "google"),
    ("n22", "Today, 524 million Indians are on Jio.", "today"),
    ("n23a", "Your father wanted a phone call cheaper than a postcard.", "callback"),
    ("n23b", "You made it free.", "made_free"),
    ("n24a", "That's why you call it Jio.", "jio_name"),
    ("n24b", "In Hindi, it means \"live\".", "loop"),
]

# The exact text of the cached single take (script.md lines 1-24): the lines above must join to it.
TAKE = ("Imagine you're Mukesh Ambani. You run refineries, petrol and plastics. But you lost the one business your father "
        "dreamed about. In 2002, your father Dhirubhai wanted a phone call to cost less than a postcard. Then the family "
        "empire splits. Your brother Anil gets the phone company, and you agree to stay out of telecom. So you watch. In "
        "2015, most Indians are online on slow 2G. One gigabyte costs about 250 rupees, and every video buffers forever. "
        "Airtel, Vodafone and Idea make their money on voice calls. So data stays a luxury. But you see something they "
        "don't. In 2010, your deal with Anil ends. Weeks later, an unknown company called Infotel wins 4G airwaves in all "
        "22 circles of India. Within hours, you buy 95 percent of it. Then your daughter Isha comes home from Yale and "
        "says, \"Dad, the internet in our house sucks.\" Your son Akash adds: telecom isn't about calls anymore. It's about "
        "data. So you decide: data should be like oxygen. Cheap enough for everyone. You don't fix old towers. You build "
        "India's first 4G-only network, where even phone calls travel as data. You lay three lakh kilometres of fibre. The "
        "bill: one and a half lakh crore rupees. You call it the world's biggest startup. On September 5th, 2016, you "
        "launch Jio. And everything is free. Calls. Data. Apps. Sixteen million people join in 26 days. A hundred million "
        "in 170 days. That's seven new customers every second. Your rivals run to the regulator, crying predatory pricing. "
        "You say their networks are dropping your calls. And the insane part? You even give away the phone. The JioPhone, "
        "at an effective price of zero. Data crashes from 250 rupees a gigabyte to under 20. India becomes the world's "
        "biggest consumer of mobile data. Telenor exits. Tata exits. Aircel goes bankrupt. Even your brother's company "
        "shuts down. Vodafone and Idea merge just to survive. By 2019, Jio is number one. Then Facebook pays 5.7 billion "
        "dollars for a slice. Google pays 4.5 billion. Today, 524 million Indians are on Jio. Your father wanted a phone "
        "call cheaper than a postcard. You made it free. That's why you call it Jio. In Hindi, it means \"live\".")
assert " ".join(t for _, t, _ in lines) == TAKE, "the lines no longer join to the cached take"

sfx = [
    {"sound": "tick", "at": L("n5b"), "repeat": 10, "every": 0.09, "gain": -10},
    {"sound": "ding", "at": W("n5b", "250", edge="end"), "gain": -6},
    {"sound": "thud", "at": W("n3a", "splits"), "gain": -8},
    {"sound": "whistle", "at": W("n3a", "splits", offset=-0.35), "gain": -9},
    {"sound": "rip", "at": W("n3a", "splits"), "gain": -5},
]

reveals = [
    # empire: dressing + the three businesses
    {"id": "reliance_sign", "t": 0, "enter": "none", "text": "RELIANCE", "color": "#ff4fd8", "glow": 1.6, "size": 0.9,
     "at": A("empire", [0, 7.1, -2.9])},
    # Shot 1: his name lands over his head, stacked (9:16 is narrow).
    {"id": "name_1", "t": W("n1a", "Mukesh"), "until": L("n1b"), "text": "MUKESH", "color": "#1b1440", "glow": 0.0,
     "size": 0.24, "at": A("m.head", [0, 0.7, 0]), "sound": "pop"},
    {"id": "name_2", "t": W("n1a", "Ambani."), "until": L("n1b"), "text": "AMBANI", "color": "#1b1440", "glow": 0.0,
     "size": 0.24, "at": A("m.head", [0, 0.42, 0]), "sound": "pop"},
    # Shot 2: his three businesses stack up on his head, one per word (a balancing tower: 9:16 is tall).
    {"id": "refinery", "t": W("n1b", "refineries"), "shape": "refinery", "size": 0.62, "enter": "drop", "enter_time": 0.3,
     "at": A("m.head", [0, 0.36, 0]), "face": A("m", [0, 1.3, 5]), "bob": 0.02, "sound": "pop", "until": W("n1c", "father")},
    {"id": "pump", "t": W("n1b", "petrol"), "shape": "pump", "size": 0.55, "enter": "drop", "enter_time": 0.3,
     "at": A("m.head", [0, 1.1, 0]), "face": A("m", [0, 1.3, 5]), "bob": 0.03, "sound": "pop", "until": W("n1c", "father")},
    {"id": "plastic", "t": W("n1b", "plastics"), "shape": "bottle", "color": "#4a90e2", "size": 0.42, "enter": "drop",
     "enter_time": 0.3, "at": A("m.head", [0, 1.72, 0]), "bob": 0.04, "spin": 40, "sound": "pop", "until": W("n1c", "father")},
    # tribute: the portrait and the scales
    {"id": "cabinet", "t": 0, "enter": "none", "shape": "box", "color": "#6a4028", "size": 0.6, "at": A("tribute.back", [0, 0, 0.3])},
    {"id": "portrait", "t": 0, "enter": "none", "shape": "frame", "size": 1.15, "at": A("tribute.back", [0, 0.62, 0.4])},
    {"id": "garland", "t": 0, "enter": "none", "shape": "garland", "size": 0.92, "at": A("tribute.back", [0, 1.77, 0.47])},
    {"id": "name", "t": 0, "enter": "none", "shape": "plaque", "label": "DHIRUBHAI AMBANI", "label_color": "#3a2208",
     "size": 0.78, "at": A("tribute.back", [0, 0.56, 0.47])},
    {"id": "y2002", "t": W("n2", "2002"), "until": L("n3a"), "text": "2002", "color": "#5fe3ff", "glow": 1.2, "size": 0.26,
     "at": A("tribute.back", [0, 2.02, 0.75]), "sound": "pop"},
    # split: table, cake, halves, phone, sign
    {"id": "table", "t": 0, "enter": "none", "prop": "quaternius_fantasy_props/Table_Large", "size": 2.0, "at": A("split", [0, 0, 0])},
    # yaw 90: the cut faces +x, the half sits at world -x (screen left); yaw -90 the mirror.
    {"id": "cake_l", "t": 0, "enter": "none", "shape": "cake_half", "size": 0.55, "yaw": 90, "at": A("split", [0, 0.57, 0]),
     "moves": [{"t": W("n3a", "splits"), "by": [-0.62, 0, 0], "dur": 0.32}]},
    {"id": "cake_r", "t": 0, "enter": "none", "shape": "cake_half", "size": 0.55, "yaw": -90, "at": A("split", [0, 0.57, 0]),
     "moves": [{"t": W("n3a", "splits"), "by": [0.62, 0, 0], "dur": 0.32}]},
    {"id": "cake_txt_l", "t": 0, "enter": "none", "text": "RELI", "color": "#7a1f4a", "glow": 0.0, "size": 0.075,
     "at": A("split", [0.085, 0.645, 0.29]), "moves": [{"t": W("n3a", "splits"), "by": [-0.62, 0, 0], "dur": 0.32}]},
    {"id": "cake_txt_r", "t": 0, "enter": "none", "text": "ANCE", "color": "#7a1f4a", "glow": 0.0, "size": 0.075,
     "at": A("split", [-0.1, 0.645, 0.29]), "moves": [{"t": W("n3a", "splits"), "by": [0.62, 0, 0], "dur": 0.32}]},
    # Shot 5: a tug-of-war over the Reliance cake, Kokilaben referees; on "splits" the rope snaps and it tears.
    {"id": "tug_rope", "t": L("n3a"), "until": W("n3a", "splits", offset=0.04), "exit": "none", "shape": "link",
     "enter": "none", "size": 0.06, "color": "#e0b070", "at": "m2.hand", "to": "a.hand"},
    {"id": "whistle", "t": L("n3a"), "until": L("n3b"), "shape": "cylinder", "color": "#d8dce4", "size": 0.08,
     "enter": "none", "at": A("k.face", [0, -0.12, 0.16])},
    {"id": "anil_phone", "t": W("n3b", "phone"), "shape": "phone", "size": 0.26, "enter": "drop", "at": A("a.hand", [0, 0, 0.06]),
     "face": face_cam("split"), "sound": "pop"},
    # 2010: the deal ends, the sign falls over.
    {"id": "no_telecom", "t": W("n3c", "stay"), "shape": "sign", "label": "NO TELECOM", "label_color": "#c0262d", "size": 0.85,
     "enter": "rise", "at": A("m2", [-0.9, 0, 0.15]), "face": face_cam("split"), "sound": "pop",
     "moves": [{"t": W("n8a", "ends."), "tip": -82, "dur": 0.7}]},
    {"id": "y2010", "t": W("n8a", "2010,"), "text": "2010", "color": "#5fe3ff", "glow": 1.2, "size": 0.26,
     "at": A("m2", [0.0, 1.62, 0.1]), "sound": "pop"},
    # watch: binoculars
    {"id": "binoculars", "t": L("n4", offset=-0.05), "until": L("n5a"), "shape": "binoculars", "size": 0.626, "enter": "pop",
     "enter_time": 0.2, "at": "m.face", "face": A("m", [0, 1.3, 4])},
    # street: 2015, 2G, spinners, the price counter, the big spinner
    {"id": "y2015", "t": W("n5a", "2015"), "until": L("n5b"), "text": "2015", "color": "#5fe3ff", "glow": 1.2, "size": 0.6,
     "at": A("street", [0, 4.4, -1.5]), "sound": "pop"},
    {"id": "twog", "t": W("n5a", "2G."), "until": L("n5b"), "text": "2G", "color": "#ff4d5a", "glow": 1.4, "size": 1.1,
     "at": A("street", [0, 2.4, -0.5]), "sound": "pop"},
    {"id": "price", "t": L("n5b"), "until": L("n5c"), "at": A("street", [0, 2.3, 2.0]), "size": 0.75, "color": "#ffffff",
     "counter": {"from": 0, "to": 250, "prefix": "₹", "land": W("n5b", "250"), "label": "PER GB"}},
    {"id": "big_spinner", "t": L("n5c"), "until": L("n6a"), "shape": "spinner", "size": 0.36, "roll": 300,
     "at": A("y.head", [0, 0.42, 0]), "face": face_cam("street", 12)},
]
SNAIL_MOVE = [{"t": W("n5a", "slow"), "until": L("n6a"), "by": [1.0, 0, 0]}]
reveals += [
    {"id": "snail", "t": W("n5a", "slow"), "until": L("n6a"), "shape": "snail", "size": 0.6, "at": S("street", -1.7, 0, 3.9),
     "moves": SNAIL_MOVE, "sound": "pop"},
    {"id": "snail_data", "t": W("n5a", "slow", offset=0.15), "until": L("n6a"), "shape": "box", "label": "DATA",
     "label_color": "#0d2a4a", "color": "#5fe3ff", "glow": 0.7, "size": 0.2, "at": S("street", -1.73, 0.38, 3.9), "moves": SNAIL_MOVE},
]
CROWD_HEADS = [1, 4, 6, 9, 12, 14]
for k, cid in enumerate(CROWD_HEADS):
    reveals.append({"id": f"spin_{cid}", "t": W("n5a", "slow", offset=0.07 * k), "until": L("n6a"), "shape": "spinner",
                    "size": 0.4, "roll": 320, "at": A(f"c_{cid}.head", [0, 0.5, 0]), "face": face_cam("street", 12)})

# --- n6: the telcos' durbar -----------------------------------------------------------------
TELCOS = [("airtel", "AIRTEL", -2.6, "Airtel,", "#e8343c"), ("vodafone", "VODAFONE", 0.0, "Vodafone", "#e60000"),
          ("idea", "IDEA", 2.6, "Idea", "#f2c230")]
for k, (tid, name, sx, word, colr) in enumerate(TELCOS):
    merge = [{"t": W("n19c", "merge"), "by": [-sx * 0.42 + (0.35 if tid == "vodafone" else -0.35) * 0, 0, 0], "dur": 0.8}] \
        if tid in ("vodafone", "idea") else []
    # Vodafone and Idea slide toward each other on "merge" (world metres: screen right is +x).
    if tid == "vodafone":
        merge = [{"t": W("n19c", "merge"), "by": [1.05, 0, 0], "dur": 0.8}]
    if tid == "idea":
        merge = [{"t": W("n19c", "merge"), "by": [-1.05, 0, 0], "dur": 0.8}]
    reveals += [
        {"id": f"tw_{tid}", "t": W("n6a", word), "shape": "tower", "size": 3.0, "color": colr, "sound": "pop",
         "at": S("rivals", sx, 0, 0.4), "moves": merge},
        {"id": f"pl_{tid}", "t": W("n6a", word), "shape": "plaque", "label": name, "label_color": "#ffffff", "color": colr,
         "size": 1.1, "at": S("rivals", sx, 0.05, 1.15), "moves": merge},
        {"id": f"crown_{tid}", "t": W("n6a", "money", offset=0.08 * k), "shape": "crown", "size": 0.55, "enter": "drop",
         "at": S("rivals", sx, 3.0, 0.4), "sound": "pop", "moves": merge,
         **({"until": W("n19c", "survive."), "exit": "drop"} if tid in ("vodafone", "idea") else {})},
        {"id": f"bag_{tid}", "t": W("n6a", "calls.", offset=0.08 * k - 0.25), "shape": "moneybag", "label": "MINUTES",
         "label_color": "#5a3a10", "size": 0.75, "enter": "drop", "at": S("rivals", sx + 0.85, 0, 1.0), "sound": "cash"},
    ]
reveals += [
    {"id": "meter", "t": W("n6a", "money"), "until": L("n6b"), "shape": "meter", "size": 0.8, "at": S("rivals", 0, 1.55, 2.6),
     "sound": "click"},
    {"id": "fare", "t": W("n6a", "money"), "until": L("n6b"), "at": S("rivals", 0, 1.62, 2.85), "size": 0.16, "color": "#ffe0d0",
     "glow": 1.2, "counter": {"from": 0, "to": 9999, "prefix": "₹", "land": W("n6a", "calls."), "label": "PER MINUTE",
                              "land_color": "#ffd84a"}},
]
sfx += [{"sound": "tick", "at": W("n6a", "money"), "repeat": 14, "every": 0.1, "gain": -10},
        {"sound": "cash", "at": W("n6a", "calls.", edge="end"), "gain": -5}]
# The small players behind (they fall in n19); they are there from the start.
# A JIO bowling ball knocks them over, one per name, all toward screen right.
SMALL = [("telenor", "TELENOR", -3.9, -2.2, -80, W("n19a", "exits.", occurrence=1)),
         ("tata", "TATA", -1.3, -2.2, -80, W("n19a", "exits.", occurrence=2)),
         ("aircel", "AIRCEL", 1.3, -2.2, -80, W("n19a", "bankrupt.")),
         ("rcom", "RCOM", 3.9, -2.2, -80, W("n19b", "down."))]
for tid, name, sx, fz, tip, when in SMALL:
    reveals += [
        {"id": f"tw_{tid}", "t": 0, "enter": "none", "shape": "tower", "size": 2.1, "color": "#b9bec8",
         "at": S("rivals", sx, 0, fz), "moves": [{"t": when, "tip": tip, "dur": 0.75}]},
        {"id": f"pl_{tid}", "t": 0, "enter": "none", "shape": "plaque", "label": name, "label_color": "#ffffff",
         "color": "#5a5f6e", "size": 0.9, "at": S("rivals", sx, 0.05, fz + 0.55)},
    ]
    sfx.append({"sound": "thud", "at": dict(when, offset=0.45), "gain": -6})
reveals += [
    {"id": "vitrine", "t": W("n6b", "data"), "until": L("n7"), "shape": "vitrine", "size": 1.2, "at": S("rivals", 0, 0, 2.6), "sound": "pop"},
    {"id": "data_tiny", "t": W("n6b", "data", offset=0.1), "until": L("n7"), "shape": "box", "label": "DATA", "label_color": "#0d2a4a",
     "color": "#5fe3ff", "glow": 0.6, "size": 0.16, "at": S("rivals", 0, 0.56, 2.6), "spin": 25},
    {"id": "luxury_txt", "t": W("n6b", "luxury."), "until": L("n7"), "text": "LUXURY", "color": "#f2c230", "glow": 1.0, "size": 0.2,
     "at": S("rivals", 0, 1.45, 2.6), "sound": "ding"},
]

# --- n7, n8: the war room and the map -------------------------------------------------------
reveals += [
    {"id": "binoculars2", "t": W("n7", "see"), "until": W("n7", "don't."), "shape": "binoculars", "size": 0.626,
     "enter": "pop", "enter_time": 0.2, "at": "m3.face", "face": A("m3", [0, 1.3, 4])},
    {"id": "sees_data", "t": W("n7", "something"), "until": L("n8a"), "text": "DATA", "color": "#5fe3ff", "glow": 1.4,
     "size": 0.22, "at": A("m3", [0, 1.72, 0.3]), "sound": "ding"},
    {"id": "map", "t": 0, "enter": "none", "shape": "india", "size": MAP_SIZE, "color": "#ff9a3c",
     "at": S("war_room", 0, 0, MAP_Z)},
    {"id": "map_rim", "t": 0, "enter": "none", "shape": "india", "size": MAP_SIZE * 1.025, "color": "#6a2e10",
     "at": S("war_room", 0, -0.012, MAP_Z)},
    {"id": "infotel", "t": W("n8b", "Infotel"), "until": L("n9a"), "shape": "box", "label": "INFOTEL", "label_color": "#ffffff",
     "color": "#7a5fd0", "size": 0.6, "at": on_map(78.5, 22.0), "sound": "pop"},
    {"id": "unknown_q", "t": W("n8b", "unknown"), "until": W("n8b", "Infotel"), "text": "?", "color": "#ffffff", "glow": 1.0,
     "size": 0.8, "at": on_map(78.5, 22.0, 0.3), "sound": "pop"},
    {"id": "fourg_air", "t": W("n8c", "4G"), "until": L("n8d"), "text": "4G", "color": "#5fe3ff", "glow": 1.4, "size": 0.7,
     "at": on_map(84.0, 31.0, 1.6), "sound": "whoosh"},
    {"id": "circles_n", "t": W("n8c", "4G"), "until": L("n8d"), "at": on_map(80.0, 36.0, 0.9), "size": 0.6,
     "color": "#ffffff", "counter": {"from": 0, "to": 22, "land": W("n8c", "22"), "label": "CIRCLES"}},
]
t_first, t_land = W("n8c", "4G"), W("n8c", "22")
# A red link graph: a line shoots from Infotel to each circle, the pin pops where it lands.
for k, (lon, lat) in enumerate(CIRCLES):
    t_link = round(0.06 * k, 3)
    reveals.append({"id": f"link_{k}", "t": W("n8c", "wins", offset=t_link), "until": L("n9a"), "shape": "link",
                    "size": 0.035, "color": "#ff3b4a", "enter_time": 0.25, "at": on_map(78.5, 22.0, 0.3),
                    "to": on_map(lon, lat, 0.12)})
    reveals.append({"id": f"pin_{k}", "t": W("n8c", "wins", offset=t_link + 0.2), "shape": "pin", "size": 0.26,
                    "at": on_map(lon, lat), "face": S("war_room", 0, 3, 9)})
sfx += [{"sound": "tick", "at": W("n8c", "wins", offset=0.2), "repeat": 12, "every": 0.11, "gain": -11},
        {"sound": "ding", "at": W("n8c", "22", edge="end"), "gain": -6}]
sfx.append({"sound": "ding", "at": W("n8d", "95", edge="end"), "gain": -6})

# --- n8d PILOT: Mukesh fires a cash cannon into Infotel's office; the money buries the rep ------
reveals += [
    {"id": "inf_desk", "t": 0, "enter": "none", "prop": "quaternius_fantasy_props/Table_Large", "size": 1.8,
     "at": S("office", 0, 0, -0.2)},
    {"id": "inf_sign", "t": 0, "enter": "none", "shape": "plaque", "label": "INFOTEL BROADBAND", "label_color": "#ffffff",
     "color": "#7a5fd0", "size": 2.0, "at": A("office.wall", [0, 0.55, 0.05])},
    {"id": "stake_flag", "t": W("n8d", "95"), "shape": "sign", "label": "95% STAKE", "label_color": "#c0262d", "size": 0.75,
     "enter": "drop", "enter_time": 0.3, "at": S("office", 0.05, 0.75, -0.85), "face": S("office", 0, 1.2, 6), "sound": "thud"},
]
MOUTH = {"anchor": "m.face", "offset": [0, -0.13, 0.17]}
GAGS = [
    # Shot 1 (and the loop): Mukesh sips crude oil from a little barrel through a bendy straw.
    {"id": "straw", "script": "gags/straw_barrel.gd", "t": 0, "until": L("n1b"), "at": "m.chest",
     "face": A("m", [0, 1.2, 4]), "params": {"mouth": MOUTH, "sips": {"from": 0.25, "until": L("n1b", offset=-0.4), "every": 0.75}}},
    {"id": "straw_end", "script": "gags/straw_barrel.gd", "t": L("n24b"), "at": "m.chest",
     "face": A("m", [0, 1.2, 4]), "params": {"mouth": MOUTH, "sips": {"from": L("n24b", offset=0.2), "until": L("n24b", edge="end"), "every": 0.75}}},
    # Shot 3: the dream slips away: the balloon with the phone escapes his hand on "lost" and floats to the moon.
    {"id": "dream", "script": "library:balloon", "t": L("n1b"), "until": L("n2"), "at": A("m", [-0.32, 0.75, 0.25]),
     "params": {"hold": "m.hand", "release": W("n1c", "lost"), "rise": 1.25, "drift": [0.15, 0, -0.25], "length": 1.0,
                "color": "#e8343c", "carry": "phone", "carry_color": "#16181d", "carry_size": 0.3, "size": 0.55, "seed": 2}},
    # Shot 4 (and the bookend, shots 49-50): the brass balance. A 50-paise postcard sits on one pan;
    # the phone lands on "phone" and its pan crashes down (calls cost a fortune); on "less" it rises above the
    # postcard (his dream); on "free" (shot 50) it shoots up.
    {"id": "scale", "script": "library:balance_scale", "t": 0, "at": A("tribute", [0, 0, 1.2]), "face": A("tribute", [0, 1, 6]),
     "params": {"size": 0.95,
                "left": {"shape": "postcard", "size": 0.3, "color": "#f6ecd2", "t": L("n2"), "label": "50 PAISE"},
                "right": {"shape": "phone", "size": 0.26, "color": "#16181d", "t": W("n2", "phone")},
                "tilt": [[0, 0], [W("n2", "phone", offset=0.3), 24], [W("n2", "less"), -16], [W("n23b", "free."), -34]]}},
    {"id": "cannon", "script": "gags/cash_cannon.gd", "t": L("n8d"), "until": L("n9a"), "at": S("office", 0.25, 0, 2.5),
     "face": "rep", "params": {"roll_in": W("n8d", "you"), "roll_from": [0, 0, -2.2], "roll_time": 0.7,
                               "shots": {"from": W("n8d", "buy"), "until": W("n8d", "percent"), "every": 0.14}}},
    {"id": "cash", "script": "library:cash_stream", "t": L("n8d"), "until": L("n9a"), "at": S("office", 0, 0, -1.0),
     "params": {"from": "cannon.muzzle", "fire": W("n8d", "buy"), "duration": 0.9, "count": 360, "radius": 1.2,
                "height": 1.15, "flight": 0.42, "arc": 0.9, "size": 0.17, "seed": 8}},
]
sfx += [{"sound": "thud", "at": W("n8d", "buy", offset=0.14 * j), "gain": -9} for j in range(6)]
sfx += [{"sound": "cash", "at": W("n8d", "buy", offset=0.3), "gain": -3}, {"sound": "cash", "at": W("n8d", "95"), "gain": -6}]

# --- n9, n10: home ----------------------------------------------------------------------------
reveals += [
    {"id": "home_table", "t": 0, "enter": "none", "prop": "quaternius_fantasy_props/Table_Large", "size": 2.0,
     "at": S("home", 0, 0, 0)},
    {"id": "laptop", "t": 0, "enter": "none", "shape": "laptop", "size": 0.5, "at": S("home", -0.25, 0.57, 0.05)},
    {"id": "yale", "t": W("n9a", "Yale"), "until": L("n9b"), "text": "YALE", "color": "#0f4d92", "glow": 0.2, "size": 0.24,
     "at": A("isha", [0, 1.75, 0]), "sound": "pop"},
    {"id": "loading", "t": W("n9b", "internet"), "until": L("n10b"), "at": S("home", -0.25, 1.05, 0.1), "size": 0.2,
     "color": "#ffffff", "counter": {"from": 0, "to": 3, "suffix": "%", "land": W("n9b", "house"), "label": "LOADING...",
                                     "land_color": "#ff4d5a"}},
    {"id": "bin", "t": 0, "enter": "none", "shape": "bin", "size": 0.55, "at": S("home", 2.05, 0, 0.7)},
    {"id": "akash_phone", "t": W("n10a", "telecom"), "until": W("n10a", "anymore.", offset=0.55), "exit": "none", "shape": "phone",
     "size": 0.34, "at": A("akash", [0.36, 0.8, 0.3]), "face": face_cam("home"), "sound": "pop",
     "moves": [{"t": W("n10a", "anymore."), "by": [0.62, 0.55, 0.25], "dur": 0.27, "turn": 160},
               {"t": W("n10a", "anymore.", offset=0.27), "by": [0.62, -0.9, 0.25], "dur": 0.27, "turn": 160}]},
    {"id": "calls_txt", "t": W("n10a", "calls"), "until": W("n10a", "anymore.", edge="end"), "exit": "pop", "text": "CALLS",
     "color": "#ffffff", "glow": 0.8, "size": 0.15, "at": A("akash", [0.3, 1.28, 0.3])},
    {"id": "data_big", "t": W("n10b", "data."), "shape": "box", "label": "DATA", "label_color": "#0d2a4a", "color": "#5fe3ff",
     "glow": 0.9, "size": 0.8, "enter": "rise", "at": S("home", 0.0, 0.9, -1.2), "spin": 20, "sound": "whoosh"},
]

sfx.append({"sound": "thud", "at": W("n10a", "anymore.", offset=0.55), "gain": -6})

# --- n11: oxygen (war room), everyone (street) ----------------------------------------------
reveals += [
    {"id": "tank", "t": W("n11a", "like", offset=0.2), "shape": "tank", "label": "DATA", "label_color": "#ffffff", "size": 0.9,
     "enter": "drop", "at": S("war_room", 0.45, 0, -2.2), "sound": "pop"},
    {"id": "o2", "t": W("n11a", "oxygen.", offset=0.1), "text": "O₂", "color": "#7cff6b", "glow": 1.0, "size": 0.3,
     "at": S("war_room", 0.45, 1.15, -2.0)},
    {"id": "tank_sky", "t": W("n11b", "Cheap"), "until": L("n15a"), "shape": "tank", "label": "DATA", "label_color": "#ffffff",
     "size": 1.9, "enter": "beam", "color": "#2f9e6a", "at": S("street", 0, 2.2, 1.0), "bob": 0.08, "sound": "whoosh"},
]

for k in range(16):
    reveals += [
        {"id": f"o2_hose_{k}", "t": W("n11b", "enough", offset=0.05 * k), "until": L("n15a"), "shape": "link", "size": 0.025,
         "color": "#7cff6b", "enter_time": 0.3, "at": S("street", 0, 2.25, 1.0), "to": A(f"c_{k}.head", [0, 0.42, 0])},
        {"id": f"o2_mini_{k}", "t": W("n11b", "enough", offset=0.05 * k + 0.25), "until": L("n15a"), "shape": "tank",
         "color": "#2f9e6a", "size": 0.3, "at": A(f"c_{k}.head", [0, 0.3, 0])},
    ]
sfx.append({"sound": "whoosh", "at": W("n11b", "enough"), "gain": -8})

# --- n12: towers (field) ----------------------------------------------------------------------
for k, sx in enumerate([-3.6, -1.6, 0.4, 2.4]):
    reveals += [
        {"id": f"old_{k}", "t": 0, "enter": "none", "shape": "tower", "size": 2.3, "color": "#8a6a4a",
         "at": S("field", sx, 0, 0.0), "moves": [{"t": W("n12a", "fix", offset=0.1 + 0.2 * k), "tip": -84, "dur": 0.55}]},
        {"id": f"old_lbl_{k}", "t": 0, "until": W("n12a", "fix", offset=0.1 + 0.2 * k), "text": "2G", "enter": "none",
         "color": "#ff4d5a", "glow": 1.0, "size": 0.32, "at": S("field", sx, 2.55, 0.0)},
    ]
    sfx.append({"sound": "thud", "at": W("n12a", "fix", offset=0.2 * k + 0.5), "gain": -8})
for k, (sx, word) in enumerate([(-2.2, "build"), (2.2, "first"), (0.0, "network,")]):
    reveals.append({"id": f"new_{k}", "t": W("n12b", word), "shape": "tower", "size": 3.8, "color": "#bfefff", "glow": 0.5,
                    "enter": "rise", "enter_time": 0.5, "at": S("field", sx, 0, -2.6), "sound": "whoosh"})
reveals += [
    {"id": "fourg_big", "t": W("n12b", "4G-only"), "until": L("n12c"), "text": "4G ONLY", "color": "#5fe3ff", "glow": 1.4,
     "size": 0.85, "enter": "beam", "at": S("field", 0, 3.9, -2.6), "sound": "ding"},
    {"id": "call_phone2", "t": W("n12c", "phone"), "until": W("n12c", "calls", offset=0.3), "shape": "phone", "size": 0.45,
     "color": "#16181d", "at": S("field", -0.7, 1.05, 2.8), "face": face_cam("field", 8), "sound": "pop"},
    {"id": "call_word", "t": W("n12c", "phone"), "until": W("n12c", "calls", offset=0.3), "text": "CALL", "color": "#ffffff",
     "glow": 1.0, "size": 0.2, "at": S("field", -0.7, 1.7, 2.8)},
    {"id": "crate", "t": W("n12c", "calls"), "until": W("n12c", "data.", edge="end", offset=0.2), "shape": "box",
     "label": "DATA", "label_color": "#0d2a4a", "color": "#5fe3ff", "glow": 0.8, "size": 0.55, "enter": "drop",
     "enter_time": 0.3, "at": S("field", -0.7, 1.0, 2.8), "sound": "thud",
     "moves": [{"t": W("n12c", "travel"), "until": W("n12c", "data."), "by": [0.7, 2.3, -5.3], "turn": 180}]},
    {"id": "call_eq", "t": W("n12c", "data."), "text": "CALL = DATA", "color": "#ffffff", "glow": 1.0, "size": 0.3,
     "at": S("field", 0, 4.6, -2.6), "sound": "ding"},
]
sfx.append({"sound": "whoosh", "at": W("n12c", "travel"), "gain": -6})

# --- n13: fibre, the bill, the startup (war room) -------------------------------------------
bead_pts = []
for route in FIBRE:
    bead_pts += beads(route)
for k, (lon, lat) in enumerate(bead_pts):
    u = k / max(1, len(bead_pts) - 1)
    reveals.append({"id": f"fib_{k}", "t": W("n13a", "lay", offset=round(1.6 * u, 3)), "shape": "sphere", "color": "#5fe3ff",
                    "glow": 2.0, "size": 0.09, "enter_time": 0.2, "at": on_map(lon, lat, 0.0)})
GLOBE = S("war_room", -0.6, 1.75, -1.0)
reveals += [
    {"id": "globe", "t": W("n13a", "lay"), "until": L("n13b"), "shape": "globe", "size": 1.3, "enter": "grow",
     "at": GLOBE, "spin": 35, "sound": "whoosh"},
    {"id": "earth_x", "t": W("n13a", "fibre."), "until": L("n13b"), "text": "7.5x AROUND THE EARTH", "color": "#f2c230",
     "glow": 1.2, "size": 0.16, "at": S("war_room", -0.6, 2.65, -1.0), "sound": "ding"},
]
for k in range(8):
    reveals.append({"id": f"orbit_{k}", "t": W("n13a", "three", offset=0.13 * k), "until": L("n13b"), "shape": "orbit",
                    "size": 1.42 + 0.02 * k, "color": "#5fe3ff", "glow": 1.6, "enter": "grow", "enter_time": 0.25,
                    "yaw": k * 23, "tilt": -70 + k * 19, "at": GLOBE})
reveals += [
    {"id": "fibre_km", "t": W("n13a", "lay"), "until": L("n13b"), "at": S("war_room", -0.6, 0.35, -0.6), "size": 0.34, "color": "#ffffff",
     "counter": {"from": 0, "to": 300000, "group": "indian", "suffix": " KM", "land": W("n13a", "lakh"), "label": "OF FIBRE"}},
    {"id": "receipt", "t": W("n13b", "bill:"), "shape": "receipt", "label": "BILL", "label_color": "#1b1b22", "size": 1.5,
     "enter": "rise", "enter_time": 0.8, "at": S("war_room", -0.9, 0, -2.1), "sound": "click"},
    {"id": "bill_amt", "t": W("n13b", "bill:"), "until": L("n13c", edge="end"), "at": S("war_room", -0.9, 1.75, -1.6), "size": 0.32,
     "color": "#ffffff", "counter": {"from": 0, "to": 150000, "group": "indian", "prefix": "₹", "land": W("n13b", "crore"),
                                     "label": "CRORE"}},
    {"id": "startup_txt", "t": W("n13c", "biggest"), "until": L("n14a"), "text": "WORLD'S BIGGEST STARTUP", "color": "#f2c230",
     "glow": 1.2, "size": 0.15, "at": A("m3", [0, 1.62, 0.25]), "sound": "ding"},
]
for k in range(1, 5):
    reveals.append({"id": f"receipt_{k}", "t": W("n13b", "one", offset=0.3 * k), "until": L("n14a"), "shape": "receipt",
                    "size": 1.5, "enter": "rise", "enter_time": 0.35, "at": S("war_room", -0.9, 1.48 * k, -2.1)})
reveals += [
    {"id": "garage_tiny", "t": W("n13c", "call"), "until": L("n14a"), "shape": "garage", "size": 0.32, "label": "STARTUP",
     "label_color": "#1b1b22", "at": A("m3", [-0.55, 0, 0.35]), "face": A("m3", [0, 1, 6]), "sound": "pop"},
    {"id": "garage_giant", "t": W("n13c", "biggest"), "until": L("n14a"), "shape": "garage", "size": 3.4, "label": "STARTUP",
     "label_color": "#1b1b22", "enter": "rise", "enter_time": 0.5, "at": S("war_room", 1.35, 0, -4.0), "sound": "whoosh"},
]
sfx += [{"sound": "tick", "at": W("n13a", "lay"), "repeat": 12, "every": 0.09, "gain": -11},
        {"sound": "ding", "at": W("n13a", "lakh", edge="end"), "gain": -6},
        {"sound": "tick", "at": W("n13b", "bill:"), "repeat": 14, "every": 0.09, "gain": -11},
        {"sound": "cash", "at": W("n13b", "crore", edge="end"), "gain": -5}]

# --- n14, n17, n20, n21: the launch stage -----------------------------------------------------
reveals += [
    {"id": "launch_date", "t": W("n14a", "September"), "until": L("n14b"), "text": "5 SEP 2016", "color": "#ffffff", "glow": 1.0,
     "size": 0.32, "at": S("launch", 0, 2.25, -0.6), "sound": "pop"},
    {"id": "jio_neon", "t": W("n14a", "Jio."), "text": "JIO", "color": "#3d7bff", "glow": 2.2, "size": 1.3, "enter": "beam",
     "at": S("launch", 0, 3.6, -3.0), "sound": "sting"},
]
for k, (word, sx, shape, extra) in enumerate([("Calls.", -1.15, "phone", {"color": "#16181d"}),
                                              ("Data.", 0.0, "box", {"label": "DATA", "label_color": "#0d2a4a", "color": "#5fe3ff", "glow": 0.6}),
                                              ("Apps.", 1.15, "card", {"color": "#ff4fd8"})]):
    reveals += [
        {"id": f"free_item_{k}", "t": W("n14b", word), "until": L("n15a"), "shape": shape, "size": 0.5 if shape != "box" else 0.4,
         "enter": "drop", "at": S("launch.pedestal", sx, 0.9, 0.3), "face": face_cam("launch", 8), "sound": "pop", **extra},
        {"id": f"free_tag_{k}", "t": W("n14b", word, offset=0.15), "until": L("n15a"), "text": "FREE", "color": "#7cff6b",
         "glow": 1.2, "size": 0.2, "at": S("launch.pedestal", sx, 0.55, 0.6)},
    ]
reveals += [
    {"id": "everything_free", "t": W("n14b", "free."), "until": W("n14b", "Data."), "text": "FREE!", "color": "#7cff6b",
     "glow": 1.4, "size": 0.5, "at": S("launch", 0, 2.0, 0.6), "sound": "ding"},
    # n17: Mukesh fires free phones into the crowd, then the JioPhone and its price falling to zero.
    {"id": "phone_stand", "t": W("n17a", "phone."), "until": L("n18a"), "shape": "box", "color": "#2a2f6e", "size": 0.5,
     "enter": "rise", "at": S("launch.pedestal", 0, 0, 0)},
    {"id": "jiophone", "t": W("n17a", "phone."), "until": L("n18a"), "shape": "phone", "size": 1.0, "color": "#1b2a6a",
     "enter": "drop", "at": S("launch.pedestal", 0, 0.5, 0), "face": face_cam("launch", 8), "sound": "thud"},
    {"id": "insane_txt", "t": W("n17a", "insane"), "until": L("n17b"), "text": "INSANE", "color": "#ff4d5a", "glow": 1.3,
     "size": 0.45, "at": S("launch", 0, 1.75, 1.2), "sound": "sting"},
    {"id": "jiophone_name", "t": W("n17b", "JioPhone,"), "until": L("n18a"), "text": "JIOPHONE", "color": "#3d7bff", "glow": 1.2,
     "size": 0.26, "at": S("launch", 0, 2.95, 0.9), "sound": "pop"},
    {"id": "phone_price", "t": W("n17b", "JioPhone,"), "until": L("n18a"), "at": S("launch", 0, 2.15, 0.9), "size": 0.38,
     "color": "#ffffff", "counter": {"from": 1500, "to": 0, "prefix": "₹", "land": W("n17b", "zero."), "label": "PRICE",
                                     "land_color": "#7cff6b"}},
    # n20: the podium, Jio on top, a crown.
    {"id": "podium", "t": W("n20", "2019,"), "until": L("n21a"), "shape": "podium", "size": 2.0, "enter": "rise",
     "at": S("launch.pedestal", 0, 0, 0), "sound": "whoosh"},
    {"id": "pod_airtel", "t": W("n20", "2019,", offset=0.25), "until": L("n21a"), "shape": "tower", "size": 0.95,
     "color": "#d8dce4", "at": S("launch.pedestal", -0.72, 0.68, 0)},
    {"id": "pod_vi", "t": W("n20", "2019,", offset=0.35), "until": L("n21a"), "shape": "tower", "size": 0.8,
     "color": "#d8dce4", "at": S("launch.pedestal", 0.72, 0.48, 0)},
    {"id": "pod_jio", "t": W("n20", "Jio"), "until": L("n21a"), "shape": "tower", "size": 1.25, "color": "#bfefff", "glow": 0.6,
     "enter": "drop", "at": S("launch.pedestal", 0, 1.0, 0), "sound": "pop"},
    {"id": "pod_crown", "t": W("n20", "one."), "until": L("n21a"), "shape": "crown", "size": 0.32, "enter": "drop",
     "at": S("launch.pedestal", 0, 2.25, 0), "sound": "ding"},
    {"id": "pod_l1", "t": W("n20", "2019,", offset=0.25), "until": L("n21a"), "text": "AIRTEL", "color": "#ffffff", "glow": 0.6,
     "size": 0.13, "at": S("launch.pedestal", -0.72, 1.75, 0.2)},
    {"id": "pod_l3", "t": W("n20", "2019,", offset=0.35), "until": L("n21a"), "text": "VI", "color": "#ffffff", "glow": 0.6,
     "size": 0.13, "at": S("launch.pedestal", 0.72, 1.4, 0.2)},
    {"id": "pod_l2", "t": W("n20", "Jio"), "until": L("n21a"), "text": "JIO", "color": "#3d7bff", "glow": 1.4,
     "size": 0.2, "at": S("launch.pedestal", 0, 2.65, 0.2)},
    # n21: the Jio cake; Facebook and Google buy slices.
    {"id": "jio_cake", "t": L("n21a"), "shape": "cake", "label": "JIO", "label_color": "#1b2a6a", "size": 1.2, "enter": "drop",
     "at": S("launch.pedestal", 0, 0, 0.1)},
    {"id": "slice_fb", "t": W("n21a", "slice."), "enter": "none", "shape": "cake_slice", "size": 1.22,
     "at": S("launch.pedestal", 0, 0, 0.1), "sound": "whoosh",
     "moves": [{"t": W("n21a", "slice."), "by": [-1.35, 1.05, 0.7], "dur": 0.7, "turn": -40}]},
    {"id": "slice_go", "t": W("n21b", "billion."), "enter": "none", "shape": "cake_slice", "size": 1.22, "yaw": 40,
     "at": S("launch.pedestal", 0, 0, 0.1), "sound": "whoosh",
     "moves": [{"t": W("n21b", "billion."), "by": [1.35, 1.05, 0.7], "dur": 0.7, "turn": 40}]},
    {"id": "fb_name", "t": W("n21a", "Facebook"), "text": "FACEBOOK", "color": "#5f9bff", "glow": 1.2, "size": 0.26,
     "at": S("launch", -1.35, 2.75, 0.3), "sound": "pop"},
    {"id": "fb_amt", "t": W("n21a", "pays"), "at": S("launch", -1.35, 1.95, 0.3), "size": 0.42, "color": "#ffffff",
     "counter": {"from": 0, "to": 5.7, "decimals": 1, "prefix": "$", "suffix": "B", "land": W("n21a", "5.7")}},
    {"id": "fb_cash", "t": W("n21a", "dollars"), "shape": "cash", "size": 0.55, "enter": "drop",
     "at": S("launch", -1.3, 0, 1.4), "sound": "cash"},
    {"id": "go_name", "t": W("n21b", "Google"), "text": "GOOGLE", "color": "#ffffff", "glow": 1.2, "size": 0.26,
     "at": S("launch", 1.35, 2.75, 0.3), "sound": "pop"},
    {"id": "go_amt", "t": W("n21b", "pays"), "at": S("launch", 1.35, 1.95, 0.3), "size": 0.42, "color": "#ffffff",
     "counter": {"from": 0, "to": 4.5, "decimals": 1, "prefix": "$", "suffix": "B", "land": W("n21b", "4.5")}},
    {"id": "go_cash", "t": W("n21b", "billion."), "shape": "cash", "size": 0.55, "enter": "drop",
     "at": S("launch", 1.3, 0, 1.4), "sound": "cash"},
]
for j in range(10):
    side = -1 if j % 2 == 0 else 1
    dx = 0.85 * side + 1.75 + (j % 3 - 1) * 0.45                      # world metres from Mukesh to the audience
    t0 = round(0.11 * j, 3)
    reveals.append({"id": f"flying_phone_{j}", "t": W("n17a", "give", offset=t0), "until": W("n17a", "give", offset=t0 + 0.84),
                    "exit": "pop", "shape": "phone", "size": 0.45, "color": "#1b2a6a", "enter_time": 0.1, "spin": 400,
                    "at": S("launch", -1.75, 1.15, 1.6),
                    "moves": [{"t": W("n17a", "give", offset=t0), "by": [dx * 0.5, 1.6, 0.75], "dur": 0.42},
                              {"t": W("n17a", "give", offset=t0 + 0.42), "by": [dx * 0.5, -1.3, 0.75], "dur": 0.42}]})
sfx += [{"sound": "whoosh", "at": W("n17a", "give", offset=0.1 * j), "gain": -10} for j in range(0, 10, 3)]
sfx += [{"sound": "tick", "at": W("n17b", "JioPhone,"), "repeat": 14, "every": 0.11, "gain": -11},
        {"sound": "ding", "at": W("n17b", "zero.", edge="end"), "gain": -6},
        {"sound": "ding", "at": W("n21a", "5.7", edge="end"), "gain": -6},
        {"sound": "ding", "at": W("n21b", "4.5", edge="end"), "gain": -6}]

# --- n15, n18a, n22: the street, transformed -------------------------------------------------
reveals += [
    {"id": "users", "t": L("n15a"), "until": L("n15c"), "at": S("street", 0, 2.7, 1.2), "size": 0.62, "color": "#ffffff",
     "counter": {"keys": [[L("n15a"), 0], [W("n15a", "million"), 16], [W("n15b", "hundred"), 16], [W("n15b", "million"), 100]],
                 "suffix": " MILLION", "label": "ON JIO"}},
    {"id": "days26", "t": W("n15a", "26"), "until": L("n15b"), "text": "IN 26 DAYS", "color": "#f2c230", "glow": 1.0,
     "size": 0.32, "at": S("street", 0, 1.85, 1.6), "sound": "pop"},
    {"id": "days170", "t": W("n15b", "170"), "until": L("n15c"), "text": "IN 170 DAYS", "color": "#f2c230", "glow": 1.0,
     "size": 0.32, "at": S("street", 0, 1.85, 1.6), "sound": "pop"},
    {"id": "clock", "t": L("n15c"), "until": L("n16a"), "shape": "clock", "size": 0.62, "at": S("street", -0.72, 3.35, 2.4),
     "sound": "pop"},
    {"id": "clock_hand", "t": L("n15c"), "until": L("n16a"), "shape": "clock_hand", "size": 0.62, "roll": 360,
     "at": S("street", -0.72, 3.35, 2.4)},
    {"id": "per_sec", "t": W("n15c", "seven"), "until": L("n16a"), "at": S("street", 0.55, 3.1, 2.4), "size": 0.42,
     "color": "#ffffff", "counter": {"keys": [[W("n15c", "seven"), 0], [W("n15c", "seven", edge="end"), 7],
                                              [W("n15c", "customers"), 14], [W("n15c", "every"), 21], [W("n15c", "second."), 28]],
                                     "prefix": "+", "label": "+7 EVERY SECOND"}},
    {"id": "rocket", "t": W("n18a", "crashes"), "until": W("n18a", "crashes", offset=1.1), "shape": "rocket", "size": 1.0,
     "tilt": -90, "enter_time": 0.05, "at": S("street", -5.5, 1.6, 3.2), "sound": "whoosh",
     "moves": [{"t": W("n18a", "crashes"), "by": [11.0, 0.8, 0], "dur": 1.1}]},
    {"id": "crash_price", "t": L("n18a"), "until": L("n18b"), "at": S("street", 0, 2.3, 2.0), "size": 0.75, "color": "#ffffff",
     "counter": {"from": 250, "to": 18, "prefix": "₹", "land": W("n18a", "20."), "label": "PER GB", "land_color": "#7cff6b"}},
    {"id": "nation_map", "t": 0, "enter": "none", "shape": "india", "size": 16.0, "color": "#ff9a3c", "glow": 0.25,
     "at": S("nation", 0, 0, 0)},
    {"id": "today_n", "t": L("n22"), "at": S("nation", 0, 3.0, -9.5), "size": 1.6, "color": "#ffffff",
     "counter": {"from": 0, "to": 524, "land": W("n22", "524"), "suffix": " MILLION", "label": "INDIANS ON JIO"}},
]
for k, cid in enumerate(CROWD_HEADS):
    reveals.append({"id": f"fourg_{cid}", "t": W("n15a", "join", offset=0.09 * k), "text": "4G", "color": "#7cff6b",
                    "glow": 1.3, "size": 0.26, "at": A(f"c_{cid}.head", [0, 0.45, 0]), "sound": "pop" if k == 0 else None})
    if reveals[-1]["sound"] is None:
        del reveals[-1]["sound"]
for row, word in enumerate([W("n15c", "seven"), W("n15c", "customers"), W("n15c", "every"), W("n15c", "second.")]):
    for k in range(7):
        reveals.append({"id": f"new_user_{row}_{k}", "t": dict(word, offset=0.035 * k), "until": L("n16a"), "shape": "phone",
                        "size": 0.34, "color": "#1b2a6a", "enter": "drop", "enter_time": 0.25,
                        "at": S("street", -1.26 + 0.42 * k, 1.0 + 0.4 * row, 2.4), "face": face_cam("street", 12)})
    sfx.append({"sound": "tick", "at": word, "gain": -6})
    sfx.append({"sound": "pop", "at": dict(word, offset=0.1), "gain": -8})
sfx += [{"sound": "tick", "at": L("n15a"), "repeat": 6, "every": 0.1, "gain": -11},
        {"sound": "ding", "at": W("n15a", "million", edge="end"), "gain": -6},
        {"sound": "ding", "at": W("n15b", "million", edge="end"), "gain": -6},
        {"sound": "thud", "at": W("n18a", "crashes"), "gain": -6},
        {"sound": "tick", "at": W("n18a", "crashes"), "repeat": 18, "every": 0.1, "gain": -11},
        {"sound": "ding", "at": W("n18a", "20.", edge="end"), "gain": -6},
        {"sound": "tick", "at": L("n22"), "repeat": 8, "every": 0.1, "gain": -11},
        {"sound": "ding", "at": W("n22", "524", edge="end"), "gain": -6}]

# --- n16: the regulator ------------------------------------------------------------------------
reveals += [
    {"id": "court_table", "t": 0, "enter": "none", "prop": "quaternius_fantasy_props/Table_Large", "size": 2.0,
     "at": S("court", 0, 0, -0.9)},
    {"id": "trai", "t": 0, "enter": "none", "shape": "plaque", "label": "TRAI", "label_color": "#ffffff", "color": "#2a5a9a",
     "size": 0.8, "at": S("court", 0, 0.6, -0.55)},
    {"id": "predatory", "t": W("n16a", "predatory"), "until": L("n16b"), "text": "PREDATORY PRICING!", "color": "#d0142a",
     "glow": 0.25, "size": 0.15, "at": S("court", -1.0, 1.95, 1.4), "sound": "sting"},
    {"id": "waah", "t": W("n16a", "crying"), "until": L("n16b"), "text": "WAAAH!", "color": "#2f7fd8", "glow": 0.3,
     "size": 0.2, "at": S("court", -1.7, 0.45, 1.9), "sound": "sting"},
    {"id": "dropped_txt", "t": W("n16b", "networks"), "text": "CALL DROPPED", "color": "#d0142a", "glow": 0.3, "size": 0.12,
     "at": A("mc", [0.35, 1.42, 0.3]), "sound": "click"},
    {"id": "mc_phone", "t": W("n16b", "say"), "shape": "phone", "size": 0.36, "at": A("mc", [0.5, 0.85, 0.3]),
     "face": face_cam("court", 8), "sound": "pop"},
]

for k, rid in enumerate(["riv1", "riv2", "riv3"]):
    for j in range(5):
        for side in (-1, 1):
            t0 = round(0.16 * j + 0.05 * k + (0.08 if side > 0 else 0), 3)
            reveals.append({"id": f"tear_{rid}_{j}_{'l' if side < 0 else 'r'}", "t": W("n16a", "crying", offset=t0),
                            "until": W("n16a", "crying", offset=t0 + 0.55), "exit": "none", "shape": "sphere", "size": 0.06,
                            "color": "#6fd0ff", "glow": 0.5, "enter_time": 0.08,
                            "at": A(f"{rid}.head", [0.1 * side, 0.02, 0.3]),
                            "moves": [{"t": W("n16a", "crying", offset=t0), "by": [0.12 * side, -0.9, 0.1], "dur": 0.55}]})
sfx.append({"sound": "thud", "at": W("n16a", "pricing."), "gain": -4})

# --- n18b: number one in the world (war room) ------------------------------------------------
reveals += [
    {"id": "map_glow", "t": W("n18b", "India"), "shape": "india", "size": MAP_SIZE, "color": "#5fe3ff", "glow": 1.4,
     "enter": "grow", "enter_time": 0.8, "at": S("war_room", 0, 0.006, MAP_Z), "sound": "whoosh"},
    {"id": "world_no1", "t": W("n18b", "biggest"), "at": on_map(80.0, 36.0, 1.0), "text": "#1 IN THE WORLD", "color": "#f2c230",
     "glow": 1.3, "size": 0.42, "sound": "ding"},
    {"id": "mobile_data", "t": W("n18b", "mobile"), "at": on_map(80.0, 36.0, 0.45), "text": "MOBILE DATA", "color": "#ffffff",
     "glow": 1.0, "size": 0.3, "sound": "pop"},
]

# --- n19: the fall (rivals) --------------------------------------------------------------------
HITS = [L("n19a"), W("n19a", "exits.", occurrence=1), W("n19a", "exits.", occurrence=2), W("n19a", "bankrupt."), W("n19b", "down.")]
ball_moves = [{"t": a, "until": b, "by": [d, 0, 0]} for a, b, d in zip(HITS, HITS[1:], [2.3, 2.6, 2.6, 2.6])]
ball_moves.append({"t": HITS[-1], "by": [2.9, 0, 0], "dur": 0.7})
reveals += [
    {"id": "bowling", "t": L("n19a"), "enter": "none", "shape": "bowling_ball", "label": "JIO", "label_color": "#ffffff",
     "size": 0.75, "roll": 420, "at": S("rivals", -6.6, 0.375, -1.4), "moves": ball_moves},
    {"id": "strike", "t": W("n19b", "down.", offset=0.3), "until": L("n19c"), "text": "STRIKE!", "color": "#f2c230",
     "glow": 1.2, "size": 0.32, "at": S("rivals", 4.4, 2.4, -1.4), "sound": "ding"},
    {"id": "tape", "t": W("n19c", "just"), "shape": "tape", "size": 1.0, "at": S("rivals", 1.3, 1.1, 0.75), "sound": "click"},
]
for j in range(6):
    sx = 1.3 + (-0.35 if j % 2 == 0 else 0.35)
    t0 = round(0.12 * j, 3)
    reveals.append({"id": f"sweat_{j}", "t": W("n19c", "merge", offset=0.4 + t0), "until": W("n19c", "merge", offset=0.95 + t0),
                    "exit": "none", "shape": "sphere", "size": 0.08, "color": "#6fd0ff", "glow": 0.5, "enter_time": 0.08,
                    "at": S("rivals", sx, 2.7, 0.7),
                    "moves": [{"t": W("n19c", "merge", offset=0.4 + t0), "by": [0.2 * (1 if j % 2 else -1), -1.6, 0], "dur": 0.55}]})
reveals += [
    {"id": "vi_txt", "t": W("n19c", "merge"), "text": "VODAFONE IDEA", "color": "#ffd84a", "glow": 1.0, "size": 0.26,
     "at": S("rivals", 1.3, 3.75, 0.4), "sound": "thud"},
]

# --- n23, n24: the ending (tribute, then the opening set) -------------------------------------
reveals += [
    {"id": "free_final", "t": W("n23b", "free."), "text": "FREE", "color": "#7cff6b", "glow": 1.4, "size": 0.16,
     "at": A("tribute", [-0.45, 0.82, 1.25]), "sound": "ding"},
    {"id": "jio_word", "t": W("n24a", "Jio."), "text": "JIO", "color": "#1f4fd8", "glow": 0.4, "size": 0.5,
     "at": A("mt", [0, 1.55, 0.2]), "sound": "pop"},
    {"id": "jiyo", "t": W("n24b", "Hindi,"), "text": "जियो", "color": "#ffd84a", "glow": 1.5, "size": 0.9,
     "at": A("empire", [0, 4.7, 0.4]), "sound": "pop"},
    {"id": "live", "t": W("n24b", "live\"."), "text": "= LIVE", "color": "#5fe3ff", "glow": 1.5, "size": 0.7,
     "at": A("empire", [0, 3.75, 0.4]), "sound": "ding"},
]

FANS = ["toon_you", "toon_partner", "toon_redhead", "toon_nerd", "toon_founder", "toon_scientist_b"]

for k in range(26):
    x = -4.2 + (k * 0.37) % 8.4
    z = -1.5 + (k * 0.61) % 4.0
    t0 = round(0.06 * k, 3)
    reveals.append({"id": f"lantern_{k}", "t": W("n24b", "Hindi,", offset=t0), "shape": "sphere", "size": 0.3 + 0.08 * (k % 3),
                    "color": "#ffb347", "glow": 2.2, "at": S("empire", x, 0.4 + (k % 4) * 0.3, z),
                    "moves": [{"t": W("n24b", "Hindi,", offset=t0), "by": [0.3 * ((k % 5) - 2), 7.5, 0], "dur": 3.2}]})

ep = {
    "schema_version": "0.1", "id": "jio_story", "title": "How Mukesh Ambani built Jio",
    "description": "Toon Short: the story of Jio, in 24 lines (script.md).",
    "set": "specs/sets/jio_stage.json", "look": "toon_drama",
    "format": {"resolution": [1080, 1920], "fps": 60, "motion_blur": 3},
    "narration": {"voice": "Puck", "style": "fast, punchy, confident YouTube Shorts explainer narrator, playful and a little cheeky",
                  "speed": 1.08, "model": "gemini-3.8-flash-tts", "single_take": True,
                  "script": [t for _, t, _ in lines]},
    "lines": [{"id": i, "text": t, "shot": s, "at": 0.1} for i, t, s in lines],
    "captions": {"style": "toon"},
    # The approval board films each character on the open road of the "field" bay.
    "review": {"stage": {"anchor": "field", "offset": [0, 0, 1.0]}},
    "ambience": [{"sound": "beat", "gain": -19, "duck": 0.55}],
    "sfx": sfx,
    "actors": [
        {"id": "m", "character": "toon_mukesh", "at": "empire.pedestal", "cues": [
            {"t": 0, "expression": "smug", "hands": "chest"}, {"t": L("n1b"), "hands": "none"},
            {"t": W("n1b", "plastics"), "expression": "star_eyes"},
            {"t": W("n1c", "lost"), "expression": "shocked"}, {"t": W("n1c", "lost", offset=0.15), "action": "jump"},
            {"t": W("n1c", "business"), "expression": "sad", "action": "idle"},
            {"t": L("n4", offset=-0.05), "expression": "surprised", "hands": "face"},
            {"t": L("n5a"), "expression": "deadpan", "hands": "none"},
            {"t": L("n24b"), "hands": "chest"},
            {"t": W("n24b", "Hindi,"), "expression": "happy"}, {"t": W("n24b", "live\"."), "expression": "wink"}]},
        {"id": "d", "character": "toon_dhirubhai", "at": "tribute.back", "action": "idle", "freeze": 0.3, "cues": [
            {"t": 0, "expression": "happy"}, {"t": W("n23b", "free."), "expression": "laugh"}]},
        {"id": "guard", "character": "toon_agent", "at": S("rivals", 0.95, 0, 3.0), "facing": face_cam("rivals", 8),
         "action": "fold_arms", "route": {"via": [S("rivals", 6.6, 0, 3.6)], "gait": "walk", "start": L("n7")},
         "cues": [{"t": 0, "expression": "deadpan"}, {"t": W("n6b", "luxury."), "expression": "side_eye"}]},
        {"id": "m2", "character": "toon_mukesh", "at": A("split", [-0.6, 0, -0.85]), "facing": face_cam("split", 3), "cues": [
            {"t": 0, "expression": "happy"}, {"t": L("n3a"), "expression": "determined"},
            {"t": W("n3a", "splits"), "expression": "shocked", "action": "knocked_back"}, {"t": L("n3b"), "action": "idle"},
            {"t": W("n3c", "agree"), "expression": "sad"}, {"t": W("n3c", "telecom."), "expression": "deadpan"},
            {"t": W("n8a", "deal"), "expression": "side_eye"}, {"t": W("n8a", "ends."), "expression": "grin"}]},
        {"id": "a", "character": "toon_anil", "at": A("split", [0.6, 0, -0.85]), "facing": face_cam("split", 3), "cues": [
            {"t": 0, "expression": "happy"}, {"t": L("n3a"), "expression": "determined"},
            {"t": W("n3a", "splits"), "expression": "surprised", "action": "knocked_back"}, {"t": L("n3b"), "action": "idle"},
            {"t": W("n3b", "Anil"), "expression": "smug"}, {"t": W("n3b", "company,"), "expression": "wink"},
            {"t": W("n8a", "ends."), "expression": "nervous"}]},
        # Shot 5: Kokilaben referees the split, with a whistle.
        {"id": "k", "character": "toon_kokilaben", "at": A("split", [0, 0, -1.7]), "facing": face_cam("split", 6), "cues": [
            {"t": 0, "expression": "deadpan"}, {"t": W("n3a", "splits", offset=-0.35), "expression": "furious"},
            {"t": W("n3a", "splits", offset=0.4), "expression": "sad"}]},
        {"id": "c", "character": "toon_you", "at": A("street", [0, 0, 0.3]), "action": "phone",
         "crowd": {"count": 16, "area": [10, 4], "characters": ["toon_you", "toon_partner", "toon_redhead", "toon_nerd",
                                                               "toon_founder", "toon_scientist_b"], "seed": 4},
         "cues": [{"t": 0, "expression": "deadpan"}, {"t": W("n11b", "everyone."), "expression": "surprised"},
                  {"t": W("n15a", "join"), "expression": "happy"}, {"t": W("n15b", "million"), "expression": "star_eyes"},
                  {"t": W("n18a", "20."), "expression": "laugh"}, {"t": L("n22"), "expression": "cheer"}]},
        {"id": "y", "character": "toon_you", "at": A("street", [0.4, 0, 3.4]), "action": "phone", "cues": [
            {"t": 0, "expression": "deadpan"}, {"t": W("n5c", "buffers"), "expression": "side_eye"},
            {"t": W("n5c", "forever."), "expression": "sleepy"}, {"t": W("n11b", "everyone."), "expression": "surprised"},
            {"t": W("n15a", "join"), "expression": "happy"}, {"t": W("n18a", "crashes"), "expression": "shocked"},
            {"t": W("n18a", "20."), "expression": "star_eyes"}, {"t": L("n22"), "expression": "laugh"}]},
        # The telcos' durbar: Anil by his company's tower.
        {"id": "a2", "character": "toon_anil", "at": S("rivals", 4.9, 0, -0.5), "facing": face_cam("rivals", 8), "cues": [
            {"t": 0, "expression": "smug"}, {"t": W("n19b", "brother's"), "expression": "nervous"},
            {"t": W("n19b", "down."), "expression": "crying"}]},
        # The war room: Mukesh behind the map.
        {"id": "m3", "character": "toon_mukesh", "at": S("war_room", 1.35, 0, -2.4), "facing": face_cam("war_room", 8), "cues": [
            {"t": 0, "expression": "deadpan"}, {"t": W("n7", "see"), "expression": "surprised", "hands": "face"},
            {"t": W("n7", "don't."), "expression": "scheming", "hands": "none"},
            {"t": W("n8c", "22"), "expression": "star_eyes"}, {"t": W("n8d", "buy"), "expression": "grin"},
            {"t": W("n11a", "decide:"), "expression": "thinking"}, {"t": W("n11a", "oxygen."), "expression": "determined"},
            {"t": W("n13a", "lay"), "expression": "determined"}, {"t": W("n13b", "crore"), "expression": "shocked"},
            {"t": W("n13c", "call"), "expression": "smug"}, {"t": W("n13c", "biggest"), "expression": "star_eyes"},
            {"t": W("n18b", "India"), "expression": "happy"}, {"t": W("n18b", "biggest"), "expression": "cool"}]},
        # n8d pilot: the Infotel rep behind his desk, Mukesh beside the cannon.
        {"id": "rep", "character": "toon_nerd", "at": S("office", 0, 0, -1.0), "facing": face_cam("office", 6), "cues": [
            {"t": 0, "expression": "happy"}, {"t": W("n8d", "hours,"), "expression": "surprised"},
            {"t": W("n8d", "buy"), "expression": "panic"}, {"t": W("n8d", "95"), "expression": "star_eyes"},
            {"t": W("n8d", "it."), "expression": "grin"}]},
        {"id": "mi", "character": "toon_mukesh", "at": S("office", -0.4, 0, 2.25), "facing": "rep", "cues": [
            {"t": 0, "expression": "smug"}, {"t": W("n8d", "buy"), "expression": "grin"}]},
        # Home: Isha and Akash at the table.
        {"id": "isha", "character": "toon_isha", "at": S("home", -1.25, 0, -0.1), "facing": face_cam("home", 6), "cues": [
            {"t": 0, "expression": "happy"}, {"t": W("n9a", "says,"), "expression": "side_eye", "action": "talk"},
            {"t": W("n9b", "internet"), "expression": "angry"}, {"t": W("n9b", "sucks.\""), "expression": "furious"},
            {"t": L("n10a"), "expression": "deadpan", "action": "fold_arms"}, {"t": W("n10b", "data."), "expression": "surprised"}]},
        {"id": "akash", "character": "toon_akash", "at": S("home", 1.15, 0, -0.1), "facing": face_cam("home", 6), "cues": [
            {"t": 0, "expression": "deadpan"}, {"t": W("n9b", "sucks.\""), "expression": "laugh"},
            {"t": W("n10a", "adds:"), "expression": "thinking", "action": "talk"},
            {"t": W("n10a", "anymore.", offset=-0.25), "action": "throw"}, {"t": W("n10a", "anymore."), "expression": "side_eye"},
            {"t": W("n10b", "data."), "expression": "star_eyes", "action": "idle"}]},
        # The field: Mukesh in front of the towers.
        # Shoves the first 2G tower (dominoes), then walks to his mark to send a call.
        {"id": "mf", "character": "toon_mukesh", "at": S("field", -4.35, 0, 0.0), "facing": S("field", -3.6, 1.0, 0.0),
         "route": {"via": [S("field", -1.6, 0, 2.6)], "gait": "walk", "start": W("n12b", "You"), "arrive": W("n12c", "phone"),
                   "then": "idle", "then_facing": face_cam("field", 8)},
         "cues": [
            {"t": 0, "expression": "smug"}, {"t": W("n12a", "don't"), "expression": "determined", "action": "push"},
            {"t": W("n12a", "towers."), "expression": "grin", "action": "idle"},
            {"t": W("n12b", "build"), "expression": "determined"}, {"t": W("n12b", "4G-only"), "expression": "star_eyes"},
            {"t": W("n12c", "phone"), "expression": "grin"}]},
        # The launch stage.
        {"id": "ml", "character": "toon_mukesh", "at": S("launch", -1.75, 0, 1.4), "facing": face_cam("launch", 8), "cues": [
            {"t": 0, "expression": "smug"}, {"t": W("n14a", "launch"), "expression": "grin"},
            {"t": W("n14a", "Jio."), "expression": "cheer", "action": "dance"},
            {"t": W("n14b", "free."), "expression": "laugh"},
            {"t": L("n17a"), "expression": "scheming", "action": "idle"},
            {"t": W("n17a", "give", offset=-0.2), "expression": "laugh", "action": "throw"},
            {"t": W("n17a", "phone."), "expression": "wink", "action": "idle"},
            {"t": W("n17b", "zero."), "expression": "grin"},
            {"t": W("n20", "2019,"), "expression": "smug"}, {"t": W("n20", "one."), "expression": "cool"},
            {"t": W("n21a", "pays"), "expression": "star_eyes"}, {"t": W("n21b", "pays"), "expression": "love"}]},
        # The stampede: fans sprint in from behind the camera on "everything is free" and stay as the audience.
        *[{"id": f"fans_{side}", "character": "toon_you", "at": S("launch", 0.85 * sgn, 0, 9.6), "action": "idle",
           "route": {"via": [S("launch", 0.85 * sgn, 0, 3.1)], "gait": "run", "start": W("n14b", "everything"),
                     "arrive": W("n14b", "Apps."), "then": "dance", "then_facing": S("launch", 0, 1.0, 0)},
           "crowd": {"count": 7, "area": [1.5, 1.6], "characters": FANS, "seed": 8 + k, "start_spread": 0.4, "spacing": 0.7},
           "cues": [{"t": 0, "expression": "star_eyes"}]} for k, (side, sgn) in enumerate([("l", -1), ("r", 1)])],
        # 524 million: India made of people (seen from above in the last street shot's place).
        {"id": "people", "character": "toon_you", "at": S("nation", 0, 0, 0), "action": "phone",
         "crowd": {"count": 110, "radius": 8.0, "shape": "india", "spacing": 0.8, "characters": FANS, "seed": 3},
         "cues": [{"t": 0, "expression": "happy"}, {"t": W("n22", "Jio."), "expression": "cheer"}]},
        # The regulator's office.
        {"id": "reg", "character": "toon_official", "at": S("court", 0, 0, -1.9), "facing": face_cam("court", 8), "cues": [
            {"t": 0, "expression": "deadpan"}, {"t": W("n16a", "crying"), "expression": "side_eye"},
            {"t": W("n16a", "pricing.", offset=-0.25), "action": "hit"}, {"t": W("n16b", "say"), "action": "idle"},
            {"t": W("n16b", "dropping"), "expression": "surprised"}]},
        {"id": "riv1", "character": "toon_boss", "at": S("court", -4.4, 0, 2.4), "facing": face_cam("court", 8),
         "route": {"via": [S("court", -2.4, 0, 0.7)], "gait": "run", "start": L("n16a", offset=0.0), "arrive": W("n16a", "regulator,"),
                   "then": "idle", "then_facing": face_cam("court", 8)}, "cues": [
            {"t": 0, "expression": "angry"}, {"t": W("n16a", "crying"), "expression": "crying"},
            {"t": W("n16b", "say"), "expression": "shocked"}]},
        {"id": "riv2", "character": "toon_partner", "at": S("court", -4.4, 0, 2.75), "facing": face_cam("court", 8),
         "route": {"via": [S("court", -1.5, 0, 1.1)], "gait": "run", "start": L("n16a", offset=0.1), "arrive": W("n16a", "regulator,"),
                   "then": "idle", "then_facing": face_cam("court", 8)}, "cues": [
            {"t": 0, "expression": "panic"}, {"t": W("n16a", "crying"), "expression": "crying"},
            {"t": W("n16b", "say"), "expression": "nervous"}]},
        {"id": "riv3", "character": "toon_founder", "at": S("court", -4.4, 0, 3.0999999999999996), "facing": face_cam("court", 8),
         "route": {"via": [S("court", -0.6, 0, 0.7)], "gait": "run", "start": L("n16a", offset=0.2), "arrive": W("n16a", "regulator,"),
                   "then": "idle", "then_facing": face_cam("court", 8)}, "cues": [
            {"t": 0, "expression": "furious"}, {"t": W("n16a", "predatory"), "expression": "crying"},
            {"t": W("n16b", "say"), "expression": "angry"}]},
        {"id": "mc", "character": "toon_mukesh", "at": S("court", 1.9, 0, 0.9), "facing": face_cam("court", 8), "cues": [
            {"t": 0, "expression": "smug"}, {"t": W("n16a", "crying"), "expression": "sleepy"},
            {"t": W("n16b", "say"), "expression": "side_eye"}, {"t": W("n16b", "calls."), "expression": "wink"}]},
        # The ending: Mukesh beside his father's portrait.
        {"id": "mt", "character": "toon_mukesh", "at": A("tribute.back", [2.9, 0, 1.4]), "facing": face_cam("tribute", 6),
         "route": {"via": [A("tribute.back", [1.25, 0, 0.9])], "gait": "walk", "start": W("n22", "Today,"), "arrive": L("n23a"),
                   "then": "idle", "then_facing": face_cam("tribute", 6)}, "cues": [
            {"t": 0, "expression": "happy"}, {"t": L("n23a"), "expression": "sad"},
            {"t": W("n23b", "free."), "expression": "happy", "hands": "chest"}, {"t": W("n24a", "Jio."), "expression": "grin"}]},
    ],
    "reveals": reveals,
    "gags": GAGS,
    "shots": [
        {"name": "open", "duration": fit(0.15, 1.6),
         "camera": move(cam(A("empire", [0, 9, 13]), A("empire", [0, 3, 0]), 24), cam(A("m", [0, 1.0, 3.4]), "m.head", 32))},
        {"name": "empire_items", "duration": fit(),
         "camera": move(cam(A("m", [0, 1.4, 3.6]), A("m", [0, 1.2, 0]), 30), cam(A("m", [0, 2.0, 3.5]), A("m", [0, 2.1, 0]), 30))},
        {"name": "lost", "duration": fit(0.35), "whip_out": "up",
         "camera": move(cam(A("m", [0, 1.6, 3.6]), A("m", [0, 1.5, 0]), 30), cam(A("m", [0, 2.6, 4.8]), "dream.balloon", 30), "in")},
        {"name": "tribute", "duration": fit(0.35), "whip_in": "left", "whip_out": "right",
         "camera": move(cam(A("tribute", [0, 1.5, 5.4]), A("tribute", [0, 1.05, -0.9]), 52),
                        cam(A("tribute", [0, 1.3, 4.3]), A("tribute", [0, 0.95, -0.5]), 52))},
        {"name": "split", "duration": fit(0.2), "whip_in": "right",
         "camera": move(cam(A("split", [0, 1.7, 6.0]), A("split", [0, 0.85, -0.3]), 30), cam(A("split", [0, 1.25, 3.0]), A("split", [0, 0.85, 0]), 32))},
        {"name": "anil_phone", "duration": fit(),
         "camera": move(cam(A("a", [0.3, 1.4, 2.4]), A("a", [0, 0.95, 0]), 35), cam(A("a", [0.25, 1.35, 2.0]), A("a", [0, 0.95, 0]), 35))},
        {"name": "no_telecom", "duration": fit(0.35), "whip_out": "left",
         "camera": move(cam(A("m2", [-0.5, 1.05, 3.0]), A("m2", [-0.45, 0.85, 0]), 30), cam(A("m2", [-0.45, 1.05, 2.6]), A("m2", [-0.45, 0.85, 0]), 30))},
        {"name": "watch", "duration": fit(0.35, 1.3), "whip_in": "left",
         "camera": move(cam(A("m", [0.25, 1.18, 1.9]), "m.head", 40), cam(A("m.face", [0, 0, 0.42]), "m.face", 45), "in")},
        {"name": "street_2g", "duration": fit(0.15), "iris_in": "binoculars",
         "camera": move(cam(A("street", [0, 6, 13]), A("street", [0, 1.2, -2]), 24), cam(A("street", [0, 3.0, 9.0]), A("street", [0, 2.2, -2.5]), 26))},
        {"name": "price", "duration": fit(0.15),
         "camera": move(cam(A("street", [0, 2.6, 7.8]), "price", 30), cam(A("street", [0, 2.5, 5.4]), "price", 30))},
        {"name": "buffer", "duration": fit(0.6, 1.4), "whip_out": "right",
         "camera": move(cam(A("y", [0, 1.1, 2.1]), "y.head", 38), cam(A("y", [0.3, 0.85, 2.6]), A("y", [0.4, 0.55, 0]), 30))},
        # n6 the durbar
        {"name": "rivals", "duration": "fit", "whip_in": "right",
         "camera": move(cam(S("rivals", 0, 2.2, 10.5), S("rivals", 0, 1.9, 0), 28), cam(S("rivals", 0, 2.0, 8.6), S("rivals", 0, 1.9, 0.4), 28))},
        {"name": "luxury", "duration": "fit",
         "camera": move(cam(S("rivals", 0, 1.3, 5.6), S("rivals", 0, 0.9, 2.6), 35), cam(S("rivals", 0, 1.1, 4.4), S("rivals", 0, 0.9, 2.6), 38))},
        # n7 the war room
        {"name": "sees", "duration": "fit", "whip_out": "left",
         "camera": move(cam(A("m3", [0, 1.15, 3.0]), "m3.head", 35), cam(A("m3", [0, 1.12, 1.6]), "m3.head", 40))},
        # n8
        {"name": "deal_ends", "duration": "fit", "whip_in": "left",
         "camera": move(cam(A("m2", [-0.45, 1.15, 3.4]), A("m2", [-0.45, 0.95, 0]), 30), cam(A("m2", [-0.45, 1.1, 2.8]), A("m2", [-0.45, 0.9, 0]), 30))},
        {"name": "infotel", "duration": "fit",
         "camera": move(cam(S("war_room", 0, 6.4, 6.2), S("war_room", 0, 0, 0.2), 26), cam(S("war_room", 0, 5.0, 5.0), on_map(78.5, 22.0), 28))},
        {"name": "circles", "duration": "fit",
         "camera": move(cam(S("war_room", 0, 5.5, 6.6), S("war_room", 0, 0, 0.0), 26), cam(S("war_room", 0, 6.8, 5.8), S("war_room", 0, 0.3, -0.2), 26))},
        {"name": "buy95", "duration": "fit", "whip_in": "right", "whip_out": "right",
         "camera": move(cam(S("office", 1.8, 1.8, 5.0), S("office", -0.05, 0.8, 1.9), 26), cam(S("office", 1.25, 2.15, 3.3), S("office", -0.05, 0.95, -0.6), 28))},
        # n9, n10 home
        {"name": "isha", "duration": "fit", "whip_in": "right",
         "camera": move(cam(S("home", -0.9, 1.3, 3.2), S("home", -0.9, 1.0, 0), 38), cam(S("home", -0.9, 1.25, 2.6), S("home", -0.9, 1.05, 0), 38))},
        {"name": "sucks", "duration": "fit",
         "camera": move(cam(S("home", -0.75, 1.2, 2.9), S("home", -0.75, 1.0, 0), 32), cam(S("home", -0.75, 1.15, 2.4), S("home", -0.75, 1.0, 0), 32))},
        {"name": "akash", "duration": "fit",
         "camera": move(cam(A("akash", [-0.3, 1.2, 3.0]), A("akash", [-0.3, 0.95, 0]), 32), cam(A("akash", [-0.4, 1.1, 2.6]), A("akash", [-0.4, 0.8, 0.2]), 32))},
        {"name": "data_box", "duration": "fit",
         "camera": move(cam(S("home", 0.3, 1.2, 3.4), S("home", 0.2, 1.15, -0.8), 30), cam(S("home", 0.2, 1.3, 4.0), S("home", 0.1, 1.35, -0.9), 28))},
        # n11
        {"name": "oxygen", "duration": "fit", "whip_in": "up",
         "camera": move(cam(A("m3", [0.45, 1.2, 3.2]), A("m3", [0.45, 0.85, 0]), 32), cam(A("m3", [0.45, 1.15, 2.5]), A("m3", [0.45, 0.9, 0]), 33))},
        {"name": "everyone", "duration": "fit",
         "camera": move(cam(S("street", 0, 2.2, 9.5), S("street", 0, 2.4, -1.2), 26), cam(S("street", 0, 1.6, 7.0), S("street", 0, 2.6, -1.2), 26))},
        # n12 the field
        {"name": "old_towers", "duration": "fit",
         "camera": move(cam(S("field", -3.4, 1.2, 4.6), S("field", -3.7, 1.0, 0), 26), cam(S("field", -1.6, 1.3, 5.6), S("field", -1.2, 0.8, 0), 26))},
        {"name": "build4g", "duration": "fit",
         "camera": move(cam(S("field", 0, 0.8, 6.4), S("field", 0, 2.6, -2.6), 24), cam(S("field", 0, 0.7, 7.6), S("field", 0, 2.8, -2.6), 24))},
        {"name": "volte", "duration": "fit",
         "camera": move(cam(S("field", -0.9, 1.4, 5.8), S("field", -0.8, 1.3, 2.6), 28), cam(S("field", -0.4, 1.0, 7.6), S("field", 0, 3.0, -2.4), 26))},
        # n13 the war room
        {"name": "fibre", "duration": "fit",
         "camera": move(cam(S("war_room", -0.6, 1.8, 3.3), S("war_room", -0.6, 1.45, -1.0), 30), cam(S("war_room", -0.6, 1.9, 2.5), S("war_room", -0.6, 1.65, -1.0), 32))},
        {"name": "bill", "duration": "fit",
         "camera": move(cam(S("war_room", -0.4, 1.4, 3.6), S("war_room", -0.5, 1.2, -2.0), 30), cam(S("war_room", -0.5, 1.2, 3.8), S("war_room", -0.7, 3.4, -2.0), 26))},
        {"name": "startup", "duration": "fit",
         "camera": move(cam(A("m3", [-0.2, 1.3, 2.4]), A("m3", [-0.2, 1.1, 0]), 32), cam(A("m3", [0, 1.7, 5.6]), A("m3", [0, 1.7, -1.6]), 26))},
        # n14 launch
        {"name": "launch", "duration": "fit", "whip_in": "up",
         "camera": move(cam(S("launch", -0.6, 1.4, 7.0), S("launch", -0.4, 1.9, -0.5), 26), cam(S("launch", -0.5, 1.3, 6.0), S("launch", -0.3, 2.2, -0.8), 26))},
        {"name": "free3", "duration": "fit",
         "camera": move(cam(S("launch", 0, 2.5, 7.8), S("launch", 0, 1.1, 0.4), 26), cam(S("launch", 0, 2.3, 6.8), S("launch", 0, 1.2, 0.4), 27))},
        # n15 the street, transformed
        {"name": "join16", "duration": "fit", "whip_in": "down",
         "camera": move(cam(S("street", 0, 2.8, 7.8), S("street", 0, 2.4, 1.2), 28), cam(S("street", 0, 3.0, 9.0), S("street", 0, 2.4, 1.2), 26))},
        {"name": "join100", "duration": "fit",
         "camera": move(cam(S("street", 0, 3.2, 9.6), S("street", 0, 2.3, 1.2), 26), cam(S("street", 0, 4.8, 12.5), S("street", 0, 2.0, 0.5), 24))},
        {"name": "seven", "duration": "fit", "whip_out": "right",
         "camera": move(cam(S("street", 0, 2.3, 7.0), S("street", 0, 2.4, 2.4), 30), cam(S("street", 0, 2.4, 6.0), S("street", 0, 2.6, 2.4), 30))},
        # n16 the regulator
        {"name": "regulator", "duration": "fit", "whip_in": "right",
         "camera": move(cam(S("court", -1.6, 1.5, 5.6), S("court", -1.8, 1.1, 1.0), 28), cam(S("court", -1.2, 1.35, 4.0), S("court", -1.2, 1.2, 0.8), 30))},
        {"name": "dropped", "duration": "fit",
         "camera": move(cam(A("mc", [0.35, 1.2, 3.3]), A("mc", [0.35, 1.05, 0]), 35), cam(A("mc", [0.35, 1.15, 2.7]), A("mc", [0.35, 1.1, 0]), 35))},
        # n17 launch: the phone
        {"name": "insane", "duration": "fit", "whip_in": "left",
         "camera": move(cam(S("launch", -0.6, 2.2, 7.0), S("launch", -0.5, 1.3, 1.2), 26), cam(S("launch", -0.2, 2.4, 7.8), S("launch", 0, 1.3, 1.6), 24))},
        {"name": "zero", "duration": "fit", "whip_out": "down",
         "camera": move(cam(S("launch", 0, 2.7, 6.2), S("launch", 0, 1.3, 0.2), 30), cam(S("launch", 0, 2.6, 5.2), S("launch", 0, 1.4, 0.2), 32))},
        # n18
        {"name": "crash", "duration": "fit", "whip_in": "down",
         "camera": move(cam(S("street", 0, 2.6, 7.8), S("street", 0, 2.3, 2.0), 30), cam(A("y", [0, 1.4, 2.6]), A("y", [0, 1.4, 0]), 32))},
        {"name": "biggest", "duration": "fit", "whip_out": "right",
         "camera": move(cam(S("war_room", 0, 5.0, 7.0), S("war_room", 0, 0.4, 0.0), 26), cam(S("war_room", 0, 6.6, 6.6), S("war_room", 0, 0.8, -0.4), 26))},
        # n19 the durbar falls
        {"name": "exits", "duration": "fit", "whip_in": "right",
         "camera": move(cam(S("rivals", -6.3, 0.9, -0.55), S("rivals", -3.0, 0.5, -1.7), 30), cam(S("rivals", 0.6, 1.2, -0.45), S("rivals", 4.2, 0.5, -1.8), 28))},
        {"name": "rcom", "duration": "fit",
         "camera": move(cam(S("rivals", 4.3, 1.5, 3.8), S("rivals", 4.3, 0.9, -1.4), 30), cam(S("rivals", 4.4, 1.4, 3.0), S("rivals", 4.4, 0.9, -1.4), 32))},
        {"name": "merge", "duration": "fit", "whip_out": "up",
         "camera": move(cam(S("rivals", 1.3, 2.0, 7.0), S("rivals", 1.3, 1.9, 0.4), 30), cam(S("rivals", 1.3, 1.9, 5.6), S("rivals", 1.3, 1.9, 0.4), 32))},
        # n20, n21 launch: number one, the cake
        {"name": "number1", "duration": "fit", "whip_in": "up",
         "camera": move(cam(S("launch", -0.5, 2.8, 7.4), S("launch", -0.5, 1.5, 0.0), 26), cam(S("launch", -0.4, 2.7, 6.4), S("launch", -0.4, 1.6, 0.0), 26))},
        {"name": "facebook", "duration": "fit",
         "camera": move(cam(S("launch", -0.5, 2.8, 7.0), S("launch", -0.5, 1.6, 0.3), 26), cam(S("launch", -0.3, 2.8, 6.4), S("launch", -0.3, 1.7, 0.3), 26))},
        {"name": "google", "duration": "fit", "whip_out": "down",
         "camera": move(cam(S("launch", 0.5, 2.8, 6.6), S("launch", 0.5, 1.7, 0.3), 26), cam(S("launch", 0.2, 2.9, 7.6), S("launch", 0.1, 1.6, 0.3), 24))},
        # n22 the street, everyone
        {"name": "today", "duration": "fit", "whip_in": "down",
         "camera": move(cam(S("nation", 0.4, 1.3, 7.4), S("nation", 0.4, 1.1, 3.0), 28), cam(S("nation", 0, 21, 15), S("nation", 0, 0, -0.8), 24))},
        # n23, n24 the ending
        {"name": "callback", "duration": "fit", "whip_in": "left",
         "camera": move(cam(A("tribute", [0, 1.5, 5.4]), A("tribute", [0, 1.05, -0.9]), 52),
                        cam(A("tribute", [0, 1.3, 4.3]), A("tribute", [0, 0.95, -0.5]), 52))},
        {"name": "made_free", "duration": "fit",
         "camera": move(cam(A("tribute", [0, 1.0, 3.2]), A("tribute", [0, 0.8, 1.2]), 40), cam(A("tribute", [0, 1.2, 3.6]), A("tribute", [0, 1.3, 1.0]), 36))},
        {"name": "jio_name", "duration": "fit", "whip_out": "left",
         "camera": move(cam(A("tribute", [0.6, 1.4, 4.4]), A("tribute.back", [0.6, 1.2, 0.5]), 38),
                        cam(A("tribute", [0.6, 1.4, 3.8]), A("tribute.back", [0.6, 1.25, 0.5]), 40))},
        # The bookend: back out to the opening frame (the Short loops).
        {"name": "loop", "duration": "fit", "whip_in": "left",
         "camera": move(cam(A("m", [0, 1.6, 4.6]), A("m", [0, 1.8, 0]), 30), cam(A("empire", [0, 9, 13]), A("empire", [0, 3, 0]), 24))},
    ],
}
(ROOT / "episodes/jio_story/episode.json").write_text(json.dumps(ep, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
print(len(ep["shots"]), "shots", len(reveals), "reveals", len(ep["actors"]), "actors")
