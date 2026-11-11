"""Writes specs/sets/jio_stage.json and episodes/jio_story/episode.json. Run: python episodes/jio_story/make_episode.py .
(The episode is generated: edit this file, not episode.json.)"""
import json
import sys
from pathlib import Path

ROOT = Path(sys.argv[1])

bays = [
    {"id": "empire", "floor": "tiles", "floor_colors": ["#3b2a7a", "#2a1d5c"], "wall": "skyline", "neon": [],
     "neon_colors": ["#5fe3ff", "#ff4fd8"], "size": [10, 8],
     "pedestal": {"style": "drums", "height": 1.8, "radius": 1.7}, "note": "Mukesh on a mountain of oil drums under a night skyline"},
    {"id": "tribute", "floor": "wood", "floor_colors": ["#8a5a3a", "#6a4028"], "wall": "panels", "wall_color": "#3a2a7a",
     "neon": ["strip"], "neon_colors": ["#ffd27a", "#ff9ad5"], "size": [8, 6], "light": "#ffe2b8",
     "note": "Dhirubhai's garlanded portrait; the scales"},
    {"id": "split", "floor": "checker", "floor_colors": ["#5a2a8a", "#3a1d66"], "wall": "tiles", "wall_color": "#2b3fa8",
     "neon": ["ring", "tubes"], "neon_colors": ["#5fe3ff", "#ff4fd8"], "size": [9, 7], "note": "The family empire split: a cake on a table"},
    {"id": "street", "floor": "road", "floor_colors": ["#4a4152", "#8a7866"], "wall": "bazaar", "neon": [],
     "neon_colors": ["#5fe3ff", "#ff4fd8"], "size": [14, 10], "light": "#ffe7c4",
     "note": "India on 2G: an Indian market street at night, everyone staring at loading phones"},
]
spec = {"schema_version": "0.1", "set": {"id": "jio_stage", "generator": "stage", "seed": 11, "params": {"bays": bays}},
        "look": "neon_night",
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


def cam(at, look, lens=35):
    return {"at": at, "look_at": look, "lens_mm": lens}


def move(a, b, ease="in_out"):
    return {"from": a, "to": b, "ease": ease}


# The rest of the approved script (episodes/jio_story/script.md, lines 6-24): spoken in the
# same single take, filmed later.
REST = [
    "Airtel, Vodafone and Idea make their money on voice calls. So data stays a luxury.",
    "But you see something they don't.",
    "In 2010, your deal with Anil ends. Weeks later, an unknown company called Infotel wins 4G airwaves in all 22 circles of India. Within hours, you buy 95 percent of it.",
    "Then your daughter Isha comes home from Yale and says, \"Dad, the internet in our house sucks.\"",
    "Your son Akash adds: telecom isn't about calls anymore. It's about data.",
    "So you decide: data should be like oxygen. Cheap enough for everyone.",
    "You don't fix old towers. You build India's first 4G-only network, where even phone calls travel as data.",
    "You lay three lakh kilometres of fibre. The bill: one and a half lakh crore rupees. You call it the world's biggest startup.",
    "On September 5th, 2016, you launch Jio. And everything is free. Calls. Data. Apps.",
    "Sixteen million people join in 26 days. A hundred million in 170 days. That's seven new customers every second.",
    "Your rivals run to the regulator, crying predatory pricing. You say their networks are dropping your calls.",
    "And the insane part? You even give away the phone. The JioPhone, at an effective price of zero.",
    "Data crashes from 250 rupees a gigabyte to under 20. India becomes the world's biggest consumer of mobile data.",
    "Telenor exits. Tata exits. Aircel goes bankrupt. Even your brother's company shuts down. Vodafone and Idea merge just to survive.",
    "By 2019, Jio is number one.",
    "Then Facebook pays 5.7 billion dollars for a slice. Google pays 4.5 billion.",
    "Today, 524 million Indians are on Jio.",
    "Your father wanted a phone call cheaper than a postcard. You made it free.",
    "That's why you call it Jio. In Hindi, it means \"live\".",
]


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
]

reveals = [
    # empire: dressing + the three businesses
    {"id": "reliance_sign", "t": 0, "enter": "none", "text": "RELIANCE", "color": "#ff4fd8", "glow": 1.6, "size": 0.9,
     "at": A("empire", [0, 4.3, -3.4])},
    {"id": "refinery", "t": W("n1b", "refineries"), "shape": "refinery", "size": 0.75, "at": A("m", [-0.82, 0.55, 0.3]),
     "bob": 0.04, "sound": "pop", "until": L("n1c", offset=0.3)},
    {"id": "pump", "t": W("n1b", "petrol"), "shape": "pump", "size": 0.65, "at": A("m", [0.8, 0.55, 0.3]),
     "bob": 0.04, "sound": "pop", "until": L("n1c", offset=0.3)},
    {"id": "plastic", "t": W("n1b", "plastics"), "shape": "bottle", "color": "#4a90e2", "size": 0.36,
     "at": A("m", [0.55, 1.35, 0.35]), "bob": 0.05, "spin": 40, "sound": "pop", "until": L("n1c", offset=0.3)},
    {"id": "lost_postcard", "t": W("n1c", "father"), "until": L("n1c", edge="end"), "exit": "drop", "shape": "postcard",
     "size": 0.38, "enter": "move", "from": [1.6, 0.5, 0], "enter_time": 1.3, "spin": 60, "at": A("m", [0.7, 1.3, 0.7])},
    # tribute: the portrait and the scales
    {"id": "cabinet", "t": 0, "enter": "none", "shape": "box", "color": "#6a4028", "size": 0.66, "at": A("tribute.back", [0, 0, 0.62])},
    {"id": "portrait", "t": 0, "enter": "none", "shape": "frame", "size": 1.15, "at": A("tribute.back", [0, 0.62, 0.4])},
    {"id": "garland", "t": 0, "enter": "none", "shape": "garland", "size": 0.92, "at": A("tribute.back", [0, 1.77, 0.47])},
    {"id": "name", "t": 0, "enter": "none", "text": "DHIRUBHAI AMBANI", "color": "#ffd27a", "glow": 0.4, "size": 0.09,
     "at": A("tribute.back", [0, 0.44, 0.97])},
    {"id": "years", "t": 0, "enter": "none", "text": "1932 - 2002", "color": "#ffd27a", "glow": 0.3, "size": 0.065,
     "at": A("tribute.back", [0, 0.31, 0.97])},
    {"id": "y2002", "t": W("n2", "2002"), "text": "2002", "color": "#5fe3ff", "glow": 1.2, "size": 0.32,
     "at": A("tribute.back", [1.0, 2.0, 0.6]), "sound": "pop"},
    {"id": "scales", "t": 0, "enter": "none", "shape": "scales", "size": 0.9, "at": A("tribute", [0, 0, 1.2])},
    {"id": "call_phone", "t": W("n2", "phone"), "shape": "phone", "size": 0.22, "enter": "settle", "enter_time": 1.1,
     "at": A("tribute", [-0.45, 0.45, 1.2]), "face": face_cam("tribute"), "sound": "pop"},
    {"id": "call_postcard", "t": W("n2", "postcard"), "shape": "postcard", "size": 0.28, "enter": "settle", "enter_time": 1.1,
     "at": A("tribute", [0.45, 0.45, 1.2]), "face": face_cam("tribute"), "sound": "pop"},
    {"id": "paise", "t": W("n2", "postcard", offset=0.3), "text": "50 PAISE", "color": "#ffd84a", "glow": 0.8, "size": 0.09,
     "enter": "rise", "at": A("tribute", [0.45, 0.86, 1.25])},
    # split: table, cake, halves, phone, sign
    {"id": "table", "t": 0, "enter": "none", "prop": "quaternius_fantasy_props/Table_Large", "size": 2.0, "at": A("split", [0, 0, 0])},
    {"id": "cake", "t": 0, "enter": "none", "until": W("n3a", "splits"), "exit": "none", "shape": "cake", "label": "RELIANCE",
     "label_color": "#7a1f4a", "size": 0.55, "at": A("split", [0, 0.57, 0])},
    {"id": "cake_l", "t": W("n3a", "splits"), "enter": "move", "from": [0.24, 0, 0], "enter_time": 0.45, "shape": "cake_half",
     "size": 0.55, "yaw": 90, "at": A("split", [-0.26, 0.57, 0])},
    {"id": "cake_r", "t": W("n3a", "splits"), "enter": "move", "from": [-0.24, 0, 0], "enter_time": 0.45, "shape": "cake_half",
     "size": 0.55, "yaw": -90, "at": A("split", [0.26, 0.57, 0])},
    {"id": "anil_phone", "t": W("n3b", "phone"), "shape": "phone", "size": 0.26, "enter": "drop", "at": A("a.hand", [0, 0, 0.06]),
     "face": face_cam("split"), "sound": "pop"},
    {"id": "no_telecom", "t": W("n3c", "stay"), "shape": "sign", "label": "NO TELECOM", "label_color": "#c0262d", "size": 0.85,
     "enter": "rise", "at": A("m2", [-0.9, 0, 0.15]), "face": face_cam("split"), "sound": "pop"},
    # watch: binoculars
    {"id": "binoculars", "t": L("n4", offset=-0.05), "shape": "binoculars", "size": 0.626, "enter": "pop", "enter_time": 0.2,
     "at": "m.face", "face": A("m", [0, 1.3, 4])},
    # street: 2015, 2G, spinners, the price counter, the big spinner
    {"id": "y2015", "t": W("n5a", "2015"), "until": L("n5b"), "text": "2015", "color": "#5fe3ff", "glow": 1.2, "size": 0.6,
     "at": A("street", [0, 4.4, -1.5]), "sound": "pop"},
    {"id": "twog", "t": W("n5a", "2G."), "until": L("n5b"), "text": "2G", "color": "#ff4d5a", "glow": 1.4, "size": 1.1,
     "at": A("street", [0, 2.4, -0.5]), "sound": "pop"},
    {"id": "price", "t": L("n5b"), "until": L("n5c"), "at": A("street", [0, 2.3, 2.0]), "size": 0.75, "color": "#ffffff",
     "counter": {"from": 0, "to": 250, "prefix": "₹", "land": W("n5b", "250"), "label": "PER GB"}},
    {"id": "big_spinner", "t": L("n5c"), "shape": "spinner", "size": 0.36, "roll": 300, "at": A("y.head", [0, 0.42, 0]),
     "face": face_cam("street", 12)},
]
for k, cid in enumerate([1, 4, 6, 9, 12, 14]):
    reveals.append({"id": f"spin_{cid}", "t": W("n5a", "slow", offset=0.07 * k), "shape": "spinner", "size": 0.4, "roll": 320,
                    "at": A(f"c_{cid}.head", [0, 0.5, 0]), "face": face_cam("street", 12)})

ep = {
    "schema_version": "0.1", "id": "jio_story", "title": "How Mukesh Ambani built Jio",
    "description": "Toon Short: the story of Jio. SAMPLE: script lines 1-5 (the lost dream, the 2G market).",
    "set": "specs/sets/jio_stage.json", "look": "neon_night",
    "format": {"resolution": [1080, 1920], "fps": 30, "motion_blur": 3},
    "narration": {"voice": "Puck", "style": "fast, punchy, confident YouTube Shorts explainer narrator, playful and a little cheeky",
                  "speed": 1.08, "model": "gemini-3.8-flash-tts", "single_take": True,
                  "script": [t for _, t, _ in lines] + REST},
    "lines": [{"id": i, "text": t, "shot": s, "at": 0.1} for i, t, s in lines],
    "captions": {"style": "toon"},
    "ambience": [{"sound": "beat", "gain": -19, "duck": 0.55}],
    "sfx": [
        {"sound": "tick", "at": L("n5b"), "repeat": 10, "every": 0.09, "gain": -10},
        {"sound": "ding", "at": W("n5b", "250", edge="end"), "gain": -6},
        {"sound": "thud", "at": W("n3a", "splits"), "gain": -8},
    ],
    "actors": [
        {"id": "m", "character": "toon_mukesh", "at": "empire.pedestal", "cues": [
            {"t": 0, "expression": "smug"}, {"t": W("n1b", "plastics"), "expression": "star_eyes"},
            {"t": W("n1c", "lost"), "expression": "sad"},
            {"t": L("n4", offset=-0.05), "expression": "surprised", "hands": "face"}]},
        {"id": "d", "character": "toon_dhirubhai", "at": "tribute.back", "action": "idle", "freeze": 0.3},
        {"id": "m2", "character": "toon_mukesh", "at": A("split", [-0.6, 0, -0.85]), "facing": face_cam("split", 3), "cues": [
            {"t": 0, "expression": "happy"}, {"t": W("n3a", "splits"), "expression": "shocked"},
            {"t": W("n3c", "agree"), "expression": "sad"}, {"t": W("n3c", "telecom."), "expression": "deadpan"}]},
        {"id": "a", "character": "toon_anil", "at": A("split", [0.6, 0, -0.85]), "facing": face_cam("split", 3), "cues": [
            {"t": 0, "expression": "happy"}, {"t": W("n3a", "splits"), "expression": "surprised"},
            {"t": W("n3b", "Anil"), "expression": "smug"}, {"t": W("n3b", "company,"), "expression": "wink"}]},
        {"id": "c", "character": "toon_you", "at": A("street", [0, 0, 0.3]), "action": "phone",
         "crowd": {"count": 16, "area": [10, 4], "characters": ["toon_you", "toon_partner", "toon_redhead", "toon_nerd",
                                                               "toon_founder", "toon_scientist_b"], "seed": 4}},
        {"id": "y", "character": "toon_you", "at": A("street", [0.4, 0, 3.4]), "action": "phone", "cues": [
            {"t": 0, "expression": "deadpan"}, {"t": W("n5c", "buffers"), "expression": "side_eye"},
            {"t": W("n5c", "forever."), "expression": "sleepy"}]},
    ],
    "reveals": reveals,
    "shots": [
        {"name": "open", "duration": fit(0.15, 1.6),
         "camera": move(cam(A("empire", [0, 9, 13]), A("empire", [0, 3, 0]), 24), cam(A("m", [0, 1.0, 3.4]), "m.head", 32))},
        {"name": "empire_items", "duration": fit(),
         "camera": move(cam(A("m", [0, 1.1, 5.8]), A("m", [0, 0.95, 0]), 30), cam(A("m", [0, 1.1, 5.0]), A("m", [0, 1.0, 0]), 30))},
        {"name": "lost", "duration": fit(0.35), "whip_out": "left",
         "camera": move(cam(A("m", [0, 1.05, 2.7]), "m.head", 35), cam(A("m", [0, 1.08, 1.7]), "m.head", 38))},
        {"name": "tribute", "duration": fit(0.35), "whip_in": "left", "whip_out": "right",
         "camera": move(cam(A("tribute", [0, 1.5, 5.4]), A("tribute", [0, 1.05, -0.9]), 52),
                        cam(A("tribute", [0, 1.3, 4.3]), A("tribute", [0, 0.95, -0.5]), 52))},
        {"name": "split", "duration": fit(0.2), "whip_in": "right",
         "camera": move(cam(A("split", [0, 1.7, 6.0]), A("split", [0, 0.85, -0.3]), 30), cam(A("split", [0, 1.5, 4.9]), A("split", [0, 0.85, -0.3]), 30))},
        {"name": "anil_phone", "duration": fit(),
         "camera": move(cam(A("a", [0.3, 1.4, 2.4]), A("a", [0, 0.95, 0]), 35), cam(A("a", [0.25, 1.35, 2.0]), A("a", [0, 0.95, 0]), 35))},
        {"name": "no_telecom", "duration": fit(0.35), "whip_out": "left",
         "camera": move(cam(A("m2", [-0.5, 1.05, 3.0]), A("m2", [-0.45, 0.85, 0]), 30), cam(A("m2", [-0.45, 1.05, 2.6]), A("m2", [-0.45, 0.85, 0]), 30))},
        {"name": "watch", "duration": fit(0.35, 1.3), "whip_in": "left", "whip_out": "down",
         "camera": move(cam(A("m", [0.25, 1.18, 1.9]), "m.head", 40), cam(A("m", [0.18, 1.16, 1.35]), "m.head", 42))},
        {"name": "street_2g", "duration": fit(0.15), "whip_in": "down",
         "camera": move(cam(A("street", [0, 6, 13]), A("street", [0, 1.2, -2]), 24), cam(A("street", [0, 3.0, 9.0]), A("street", [0, 2.2, -2.5]), 26))},
        {"name": "price", "duration": fit(0.15),
         "camera": move(cam(A("street", [0, 2.6, 7.8]), "price", 30), cam(A("street", [0, 2.5, 5.4]), "price", 30))},
        {"name": "buffer", "duration": fit(0.6, 1.4),
         "camera": move(cam(A("y", [0, 1.1, 2.1]), "y.head", 38), cam(A("y", [0, 1.12, 1.5]), "y.head", 40))},
    ],
}
(ROOT / "episodes/jio_story/episode.json").write_text(json.dumps(ep, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
print(len(ep["shots"]), "shots", len(reveals), "reveals")
