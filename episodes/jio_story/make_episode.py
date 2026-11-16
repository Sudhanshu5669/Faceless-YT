"""Generate the in-production cut from the approved Jio v2 script."""
import json
import math
import sys
from pathlib import Path


ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[2]
EPISODE = ROOT / "episodes/jio_story"
BEATS = json.loads((EPISODE / "script_v2.json").read_text(encoding="utf-8"))["beats"]
SET_PATH = "specs/sets/jio_tower.json"
SIGNAL_SHOPPERS = [
    ("toon_boss", -2.45, 2.45, 1.16, 0.02),
    ("toon_partner", -1.04, 2.39, 1.08, 0.11),
    ("toon_you", 0.43, 2.49, 1.21, -0.04),
    ("toon_redhead", 1.92, 2.56, 0.93, -0.14),
    ("toon_anil", -1.56, 1.26, -1.11, -0.03),
    ("toon_shopkeeper", -0.18, 1.19, -1.07, -0.16),
    ("toon_isha", 1.24, 1.25, -1.14, -0.03),
    ("toon_nerd", 2.70, 1.37, -0.91, 0.04),
    ("toon_founder", -2.36, 0.54, 0.82, -0.10),
    ("toon_you", -1.08, 0.57, 1.09, -0.08),
    ("toon_partner", 0.43, 0.41, 1.10, 0.04),
    ("toon_shopkeeper", 1.85, 0.42, 0.98, 0.13),
    ("toon_nerd", -1.42, -1.30, -0.93, -0.20),
    ("toon_redhead", -0.03, -1.26, -0.85, -0.13),
    ("toon_isha", 1.25, -1.20, -0.86, -0.04),
    ("toon_founder", 2.70, -1.02, -0.87, -0.18),
]
RECHARGE_PASSERS = [
    ("toon_you", 2.15, -1.05, 1.42, -0.30),
    ("toon_partner", -2.40, 0.48, 1.10, -0.18),
    ("toon_nerd", -0.35, 2.62, 0.86, 0.06),
    ("toon_redhead", 0.77, -2.20, 0.27, -0.08),
]
LAUNCH_FANS = [
    ("toon_you", -2.30, 0.78), ("toon_redhead", -1.45, 0.70), ("toon_nerd", -0.62, 0.82),
    ("toon_isha", 0.95, 0.74), ("toon_partner", 1.80, 0.80), ("toon_shopkeeper", 2.55, 0.86),
    ("toon_founder", -2.70, 1.55), ("toon_partner", -1.85, 1.50), ("toon_boss", -0.95, 1.58),
    ("toon_you", 1.30, 1.52), ("toon_anil", 2.15, 1.60),
    ("toon_isha", -2.20, 2.35), ("toon_shopkeeper", -1.30, 2.28), ("toon_redhead", 1.55, 2.30),
    ("toon_nerd", 2.55, 2.38), ("toon_founder", -0.15, 3.30),
]
SIM_QUEUE = [
    # Bay offsets and staggered steps through the bend in the pavement queue.
    ("toon_partner", -0.52, 1.78, -0.43, 1.30),
    ("toon_nerd", -1.00, 2.59, -0.65, 2.13),
    ("toon_redhead", -1.76, 3.05, -1.28, 2.79),
    ("toon_you", -2.60, 2.88, -2.11, 3.04),
    ("toon_founder", -3.20, 2.23, -2.88, 2.69),
    ("toon_isha", -3.40, 1.38, -3.30, 1.91),
    ("toon_partner", -3.48, 0.51, -3.43, 1.04),
    ("toon_shopkeeper", -3.50, -0.37, -3.50, 0.16),
    ("toon_you", -3.48, -1.24, -3.50, -0.71),
    ("toon_redhead", -3.34, -2.10, -3.45, -1.58),
    ("toon_nerd", -3.12, -2.95, -3.28, -2.44),
]
GATE_CUSTOMERS = [
    "toon_partner", "toon_nerd", "toon_redhead", "toon_you", "toon_founder", "toon_isha",
    "toon_shopkeeper", "toon_you", "toon_redhead", "toon_partner", "toon_nerd",
    "toon_isha", "toon_founder", "toon_boss",
]
GATE_SPACING = 0.12
GATE_GROUP_SIZE = 7
TELCO_KINGS = [
    ("airtel", "toon_boss", 0.91, -0.05, 10),
    ("vodafone", "toon_founder", 0, 0.26, 0),
    ("idea", "toon_nerd", -0.91, -0.05, -10),
]


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def word(text, **timing):
    return {"line": "n1", "word": text, **timing}


def street_word(text, **timing):
    return {"line": "n2", "word": text, **timing}


def family_word(text, **timing):
    return {"line": "n3", "word": text, **timing}


def court_word(text, **timing):
    return {"line": "n8", "word": text, **timing}


def auction_word(text, **timing):
    return {"line": "n11", "word": text, **timing}


def cash_word(text, **timing):
    return {"line": "n12", "word": text, **timing}


def home_word(text, **timing):
    return {"line": "n13", "word": text, **timing}


def akash_word(text, **timing):
    return {"line": "n14", "word": text, **timing}


def oxygen_word(text, **timing):
    return {"line": "n15", "word": text, **timing}


def tower_word(text, **timing):
    return {"line": "n16", "word": text, **timing}


def fibre_word(text, **timing):
    return {"line": "n17", "word": text, **timing}


def startup_word(text, **timing):
    return {"line": "n18", "word": text, **timing}


def launch_word(text, **timing):
    return {"line": "n19", "word": text, **timing}


def queue_word(text, **timing):
    return {"line": "n20", "word": text, **timing}


def gate_word(text, **timing):
    return {"line": "n21", "word": text, **timing}


def regulator_word(text, **timing):
    return {"line": "n22", "word": text, **timing}


def phone_word(text, **timing):
    return {"line": "n23", "word": text, **timing}


def rate_word(text, **timing):
    return {"line": "n24", "word": text, **timing}


def globe_word(text, **timing):
    return {"line": "n25", "word": text, **timing}


def fallout_word(text, **timing):
    return {"line": "n26", "word": text, **timing}


def throne_word(text, **timing):
    return {"line": "n27", "word": text, **timing}


def investment_word(text, **timing):
    return {"line": "n28", "word": text, **timing}


def today_word(text, **timing):
    return {"line": "n29", "word": text, **timing}


def payoff_word(text, **timing):
    return {"line": "n30", "word": text, **timing}


def closing_word(text, **timing):
    return {"line": "n31", "word": text, **timing}


def complaining_rival(index, carrier, character, x):
    return {
        "id": f"complaint_{carrier}",
        "character": character,
        "at": {"anchor": "trai_office", "offset": [x + 0.5, 0, 3.5 + 0.38 * index]},
        "facing": 166,
        "action": "idle",
        "route": {
            "via": [{"anchor": "trai_office", "offset": [x, 0, 0.40 + abs(x) * 0.29]}],
            "gait": "jog",
            "start": regulator_word("run", offset=index * 0.07),
            "arrive": regulator_word("regulator", offset=index * 0.08),
            "then_facing": 22 + 11 * index,
        },
        "cues": [
            {"t": 0, "expression": "furious"},
            {"t": regulator_word("crying", offset=index * 0.08), "expression": "crying",
             "head": [13, -3 + 4 * index, 4], "head_turn": 0.16},
            {"t": regulator_word("dropping"), "expression": "shocked", "head": [24, 2, 2],
             "head_turn": 0.14},
        ],
    }


def gate_crossing(index, offset=0):
    group, place = divmod(index, GATE_GROUP_SIZE)
    return gate_word("seven", offset=group + place * GATE_SPACING + offset)


def gate_customer(index, character):
    lane = {"anchor": "jio_activation"}
    last = index == len(GATE_CUSTOMERS) - 1
    waypoints = [[0, 0, 6.25]]
    after_gate = 5.60
    if last:
        waypoints = [[0, 0, 1.46], [-1.09, 0, 2.42]]
        after_gate = 0.81 + math.hypot(1.09, 0.96)
    return {
        "id": f"gate_customer_{index}",
        "character": character,
        "at": {**lane, "offset": [0, 0, -5.28 - index * 0.79]},
        "facing": 0,
        "phase": (index % 4) * 0.11,
        "action": "idle",
        "route": {
            "via": [{**lane, "offset": point} for point in waypoints],
            "gait": "jog",
            "start": gate_crossing(index, -(5.93 + index * 0.79) / 6.6),
            "arrive": gate_crossing(index, after_gate / 6.6),
        },
        "cues": [
            {"t": 0, "expression": ["determined", "happy", "smug"][index % 3]},
            {"t": gate_crossing(index), "expression": ["grin", "cheer", "star_eyes"][index % 3]},
            *([{"t": gate_crossing(index, 0.36), "expression": "cheer", "head": [-12, 12, -5],
                "head_turn": 0.16}] if last else []),
        ],
    }


def build_set():
    return {
        "schema_version": "0.1",
        "set": {
            "id": "jio_tower",
            "seed": 11,
            "generator": "stage",
            "params": {"bays": [{
                "id": "penthouse",
                "floor": "wood",
                "floor_colors": ["#392e30", "#221d23"],
                "wall": "panels",
                "wall_color": "#37271f",
                "neon": [],
                "neon_colors": ["#65afff", "#eaaa58"],
                "size": [10, 8],
                "sides": True,
                "mood": "dramatic",
                "light": "#ffe1bc",
            }, {
                "id": "postal_street",
                "floor": "road",
                "floor_colors": ["#514956", "#967660"],
                "wall": "bazaar",
                "size": [10, 12],
                "neon": [],
                "neon_colors": ["#ffba68", "#75cae0"],
                "light": "#ffdbac",
                "mood": "dramatic",
            }, {
                "id": "family_room",
                "floor": "wood",
                "floor_colors": ["#634432", "#49312b"],
                "wall": "haveli",
                "wall_color": "#725747",
                "size": [8, 7],
                "sides": True,
                "neon": [],
                "neon_colors": ["#82bed1", "#f6b36b"],
                "light": "#ffe1ae",
                "mood": "dramatic",
            }, {
                "id": "watchtower",
                "floor": "none",
                "wall": "none",
                "size": [3, 3],
                "neon": [],
                "neon_colors": ["#78bddb", "#ffc178"],
                "light": "#f7d0b2",
                "mood": "dramatic",
            }, {
                "id": "chai_stall",
                "floor": "road",
                "floor_colors": ["#4b4244", "#876b54"],
                "wall": "none",
                "size": [8, 9],
                "neon": [],
                "neon_colors": ["#f4ab63", "#78bdcb"],
                "light": "#ffe0ad",
                "mood": "dramatic",
            }, {
                "id": "signal_bazaar",
                "floor": "road",
                "floor_colors": ["#484450", "#8d7660"],
                "wall": "none",
                "size": [12, 16],
                "neon": [],
                "neon_colors": ["#8dcdd6", "#fcb472"],
                "light": "#f5d3aa",
                "mood": "dramatic",
            }, {
                "id": "recharge_shop",
                "floor": "road",
                "floor_colors": ["#4c4850", "#927d68"],
                "wall": "none",
                "size": [12, 8],
                "neon": [],
                "neon_colors": ["#87b7c6", "#f8bd74"],
                "light": "#ffe1ba",
                "mood": "dramatic",
            }, {
                "id": "telecom_durbar",
                "floor": "marble",
                "floor_colors": ["#4c3139", "#312831"],
                "wall": "haveli",
                "wall_color": "#6d493d",
                "size": [8, 8],
                "sides": True,
                "neon": [],
                "neon_colors": ["#72b1ca", "#ed9d62"],
                "light": "#ffe2aa",
                "mood": "dramatic",
            }, {
                "id": "infotel_auction",
                "floor": "wood",
                "floor_colors": ["#3f352f", "#252628"],
                "wall": "panels",
                "wall_color": "#243036",
                "size": [7.5, 7],
                "sides": True,
                "neon": [],
                "neon_colors": ["#93c0d3", "#f6bd7b"],
                "light": "#ffd7ac",
                "mood": "dramatic",
            }, {
                "id": "auction_exit",
                "floor": "marble",
                "floor_colors": ["#74675b", "#51484a"],
                "wall": "panels",
                "wall_color": "#354248",
                "size": [6, 6.5],
                "sides": True,
                "neon": [],
                "neon_colors": ["#85b9cb", "#e0a76b"],
                "light": "#ffe0bb",
                "mood": "dramatic",
            }, {
                "id": "oxygen_clinic",
                "floor": "tiles",
                "floor_colors": ["#52605c", "#424f4f"],
                "wall": "panels",
                "wall_color": "#425c5d",
                "size": [7, 7],
                "sides": True,
                "neon": [],
                "neon_colors": ["#85cecc", "#e6b18c"],
                "light": "#fff0d3",
                "mood": "dramatic",
            }, {
                "id": "network_field",
                "floor": "none",
                "wall": "none",
                "size": [12, 16],
                "neon": [],
                "neon_colors": ["#87b4d2", "#f6c287"],
                "light": "#ffe0af",
                "mood": "dramatic",
            }, {
                "id": "startup_refinery",
                "floor": "plain",
                "floor_colors": ["#44454c", "#35393e"],
                "wall": "none",
                "size": [22, 23],
                "neon": [],
                "neon_colors": ["#7cb8e4", "#efaf70"],
                "light": "#ffe3ba",
                "mood": "dramatic",
            }, {
                "id": "fibre_depot",
                "floor": "none",
                "wall": "none",
                "size": [11, 12],
                "neon": [],
                "neon_colors": ["#87bed2", "#efb580"],
                "light": "#ffe0af",
                "mood": "dramatic",
            }, {
                "id": "ambani_lounge",
                "floor": "wood",
                "floor_colors": ["#544036", "#392c2d"],
                "wall": "haveli",
                "wall_color": "#5f4c45",
                "size": [8, 7],
                "sides": True,
                "neon": [],
                "neon_colors": ["#8fbee3", "#e9a977"],
                "light": "#ffe0bb",
                "mood": "dramatic",
            }, {
                "id": "jio_launch",
                "floor": "carpet",
                "floor_colors": ["#1b1c2a", "#141522"],
                "wall": "panels",
                "wall_color": "#11131c",
                "size": [10, 10],
                "sides": True,
                "neon": [],
                "neon_colors": ["#3f7bff", "#c84fd8"],
                "light": "#d6dcff",
                "mood": "dramatic",
            }, {
                "id": "jio_store",
                "floor": "plain",
                "floor_colors": ["#25232b", "#282631"],
                "wall": "skyline",
                "size": [12, 12],
                "neon": [],
                "neon_colors": ["#5e9fff", "#ffd199"],
                "light": "#fff0d7",
                "mood": "dramatic",
            }, {
                "id": "jio_activation",
                "floor": "tiles",
                "floor_colors": ["#303038", "#383842"],
                "wall": "panels",
                "wall_color": "#192438",
                "size": [9, 13],
                "sides": True,
                "neon": [],
                "neon_colors": ["#4198ff", "#ffbf77"],
                "light": "#ffe5c4",
                "mood": "dramatic",
            }, {
                "id": "trai_office",
                "floor": "wood",
                "floor_colors": ["#45302c", "#322726"],
                "wall": "panels",
                "wall_color": "#493e42",
                "size": [8, 9],
                "sides": True,
                "neon": [],
                "neon_colors": ["#8bb4f5", "#ffc087"],
                "light": "#ffead2",
                "mood": "dramatic",
            }, {
                "id": "jiophone_lane",
                "floor": "road",
                "floor_colors": ["#45424a", "#554c48"],
                "wall": "bazaar",
                "size": [12, 11],
                "neon": [],
                "neon_colors": ["#579bff", "#ffbd77"],
                "light": "#ffe0b4",
                "mood": "dramatic",
            }, {
                "id": "data_globe",
                "floor": "wood",
                "floor_colors": ["#332c31", "#271e25"],
                "wall": "haveli",
                "wall_color": "#463845",
                "size": [7, 7],
                "sides": True,
                "neon": [],
                "neon_colors": ["#5999ef", "#f2c396"],
                "light": "#ffecd3",
                "mood": "dramatic",
            }, {
                "id": "jio_investments",
                "floor": "marble",
                "floor_colors": ["#333442", "#262633"],
                "wall": "panels",
                "wall_color": "#1f2d50",
                "size": [10, 9],
                "sides": True,
                "neon": [],
                "neon_colors": ["#5086f2", "#f7ba86"],
                "light": "#ffe7cc",
                "mood": "dramatic",
            }]},
        },
        "look": "toon_drama",
        "preview": {"resolution": [540, 960], "views": [{
            "name": "penthouse",
            "at": {"anchor": "penthouse", "offset": [0, 1.6, 3.8]},
            "look_at": {"anchor": "penthouse", "offset": [0, 1.2, 0]},
            "lens_mm": 28,
        }, {
            "name": "family_room",
            "at": {"anchor": "family_room", "offset": [0, 2.0, 3.6]},
            "look_at": {"anchor": "family_room", "offset": [0, 0.64, 0]},
            "lens_mm": 30,
        }, {
            "name": "postal_street",
            "at": {"anchor": "postal_street", "offset": [-0.2, 2.7, 6.7]},
            "look_at": {"anchor": "postal_street", "offset": [0, 1.3, 0]},
            "lens_mm": 28,
        }, {
            "name": "chai_stall",
            "at": {"anchor": "chai_stall", "offset": [0, 1.5, 4]},
            "look_at": {"anchor": "chai_stall", "offset": [0, 1.05, 0]},
            "lens_mm": 30,
        }, {
            "name": "watchtower",
            "at": {"anchor": "watchtower", "offset": [-1.55, -1.52, 7.35]},
            "look_at": {"anchor": "watchtower", "offset": [-0.26, -0.16, 1.1]},
            "lens_mm": 29,
        }, {
            "name": "signal_bazaar",
            "at": {"anchor": "signal_bazaar", "offset": [-0.65, 3.26, 8.65]},
            "look_at": {"anchor": "signal_bazaar", "offset": [-0.27, 1.81, 0.55]},
            "lens_mm": 25,
        }, {
            "name": "recharge_shop",
            "at": {"anchor": "recharge_shop", "offset": [0.82, 2.1, 6.45]},
            "look_at": {"anchor": "recharge_shop", "offset": [0, 1.9, -0.85]},
            "lens_mm": 31,
        }, {
            "name": "telecom_durbar",
            "at": {"anchor": "telecom_durbar", "offset": [0, 2.05, 5.35]},
            "look_at": {"anchor": "telecom_durbar", "offset": [0, 1.76, 0]},
            "lens_mm": 31,
        }, {
            "name": "infotel_auction",
            "at": {"anchor": "infotel_auction", "offset": [-0.26, 1.86, 4.45]},
            "look_at": {"anchor": "infotel_auction", "offset": [0, 1.78, -0.32]},
            "lens_mm": 35,
        }, {
            "name": "auction_exit",
            "at": {"anchor": "auction_exit", "offset": [-0.35, 1.64, 3.88]},
            "look_at": {"anchor": "auction_exit", "offset": [0, 1.11, 0]},
            "lens_mm": 31,
        }, {
            "name": "ambani_lounge",
            "at": {"anchor": "ambani_lounge", "offset": [0.39, 1.84, 3.83]},
            "look_at": {"anchor": "ambani_lounge", "offset": [0, 1.10, 0.27]},
            "lens_mm": 33,
        }, {
            "name": "oxygen_clinic",
            "at": {"anchor": "oxygen_clinic", "offset": [-0.21, 1.69, 4.22]},
            "look_at": {"anchor": "oxygen_clinic", "offset": [0, 1.20, 0.23]},
            "lens_mm": 31,
        }, {
            "name": "network_field",
            "at": {"anchor": "network_field", "offset": [-1.25, 1.54, 3.90]},
            "look_at": {"anchor": "network_field", "offset": [0.22, 0.85, -0.30]},
            "lens_mm": 32,
        }, {
            "name": "fibre_depot",
            "at": {"anchor": "fibre_depot", "offset": [-1.13, 1.61, 4.21]},
            "look_at": {"anchor": "fibre_depot", "offset": [0, 1.32, -0.15]},
            "lens_mm": 30,
        }, {
            "name": "startup_refinery",
            "at": {"anchor": "startup_refinery", "offset": [-1.18, 3.36, 9.02]},
            "look_at": {"anchor": "startup_refinery", "offset": [0.12, 3.02, -0.30]},
            "lens_mm": 32,
        }, {
            "name": "jio_launch",
            "at": {"anchor": "jio_launch", "offset": [0.30, 1.92, 6.0]},
            "look_at": {"anchor": "jio_launch", "offset": [0.0, 2.25, -1.9]},
            "lens_mm": 26,
        }, {
            "name": "jio_store",
            "at": {"anchor": "jio_store", "offset": [-3.1, 3.8, 7.0]},
            "look_at": {"anchor": "jio_store", "offset": [-1.4, 1.38, 0.2]},
            "lens_mm": 27,
        }, {
            "name": "jio_activation",
            "at": {"anchor": "jio_activation", "offset": [-2.55, 3.1, 6.35]},
            "look_at": {"anchor": "jio_activation", "offset": [0, 1.49, 0.12]},
            "lens_mm": 29,
        }, {
            "name": "trai_office",
            "at": {"anchor": "trai_office", "offset": [-1.1, 2.18, 5.25]},
            "look_at": {"anchor": "trai_office", "offset": [0, 1.43, 0.05]},
            "lens_mm": 26,
        }, {
            "name": "jiophone_lane",
            "at": {"anchor": "jiophone_lane", "offset": [-1.2, 2.30, 5.80]},
            "look_at": {"anchor": "jiophone_lane", "offset": [0, 1.50, 0]},
            "lens_mm": 26,
        }]},
    }


def build():
    # A single full take is shared across every shot review as the cut grows.
    script = [beat["line"] for beat in BEATS]
    names = ["tower_open", *(f"beat_{number:02d}" for number in range(2, len(script) + 1))]
    placeholder = {"at": "penthouse.front", "look_at": "penthouse"}
    shots = [{"name": name, "duration": "fit", "camera": placeholder} for name in names]
    shots[0] = {
        "name": names[0],
        "duration": "fit",
        "camera": {"at": "office.camera", "look_at": "office.focus", "lens_mm": 28,
                   "dof": {"strength": 0.40}},
        "shake": [{"t": word("lost"), "amount": 0.18}],
    }
    shots[1] = {
        "name": names[1],
        "duration": "fit",
        "camera": {"at": "postal_choice.camera", "look_at": "postal_choice.focus",
                   "lens_mm": 25},
    }
    shots[2] = {
        "name": names[2],
        "duration": "fit",
        "camera": {
            "from": {
                "at": {"anchor": "family_room", "offset": [-0.25, 2.05, 3.35]},
                "look_at": {"anchor": "family_room", "offset": [0, 0.46, 0.13]},
                "lens_mm": 31,
            },
            "to": {
                "at": {"anchor": "family_room", "offset": [-0.22, 1.13, 2.67]},
                "look_at": {"anchor": "family_room", "offset": [0, 0.48, 0.12]},
                "lens_mm": 31,
            },
            "ease": "in_out",
        },
        "shake": [{"t": family_word("out"), "amount": 0.16}],
    }
    shots[3] = {
        "name": names[3],
        "duration": "fit",
        "hold": 0.36,
        "camera": {
            "from": {
                "at": {"anchor": "watchtower", "offset": [-1.55, -1.52, 7.35]},
                "look_at": {"anchor": "watchtower", "offset": [-0.26, -0.16, 1.1]},
                "lens_mm": 29,
            },
            "to": {
                "at": {"anchor": "watchtower", "offset": [-0.64, -0.36, 4.78]},
                "look_at": {"anchor": "watchtower", "offset": [-0.24, 0.72, 1.16]},
                "lens_mm": 31,
            },
            "ease": "in_out",
        },
    }
    shots[4] = {
        "name": names[4],
        "duration": "fit",
        "look": {
            "base": "day", "time": "14:10",
            "weather": {"clouds": 0.21},
            "sky": {"top": "#5199d9", "horizon": "#b5d6eb"},
            "sun": {"elevation": 49, "azimuth": -32, "energy": 1.32},
            "ambient": {"color": "#a4c5de", "energy": 0.52},
            "grade": {"saturation": 1.06, "contrast": 1.04, "vignette": 0.10},
        },
        "camera": {"at": "signal_hunt.camera", "look_at": "signal_hunt.focus",
                   "lens_mm": 25},
    }
    shots[5] = {
        "name": names[5],
        "duration": "fit",
        "look": {
            "base": "day", "time": "16:40",
            "sun": {"elevation": 31, "azimuth": -38, "energy": 1.02},
            "ambient": {"color": "#a4c5de", "energy": 0.38},
            "grade": {"saturation": 1.05, "contrast": 1.05, "vignette": 0.15},
        },
        "camera": {"at": "recharge.camera", "look_at": "recharge.focus", "lens_mm": 31},
    }
    shots[6] = {
        "name": names[6],
        "duration": "fit",
        "look": shots[5]["look"],
        "camera": {"at": "recharge.camera", "look_at": "recharge.focus", "lens_mm": 33},
    }
    shots[7] = {
        "name": names[7],
        "duration": "fit",
        "camera": {"at": "telco_court.camera", "look_at": "telco_court.focus", "lens_mm": 31},
    }
    shots[8] = {
        "name": names[8],
        "duration": "fit",
        "camera": {"at": "chai_watch.camera", "look_at": "chai_watch.focus", "lens_mm": 32,
                   "dof": {"strength": 0.22}},
    }
    shots[9] = {
        "name": names[9],
        "duration": "fit",
        "camera": {"at": "toy_split.camera", "look_at": "toy_split.focus", "lens_mm": 35,
                   "dof": {"strength": 0.18}},
    }
    shots[10] = {
        "name": names[10],
        "duration": "fit",
        "camera": {"at": "auction.camera", "look_at": "auction.focus", "lens_mm": 35},
    }
    shots[11] = {
        "name": names[11],
        "duration": "fit",
        "camera": {"at": "cash_blaster.camera", "look_at": "cash_blaster.focus", "lens_mm": 31},
        "shake": [{"t": cash_word("buy"), "amount": 0.52}],
    }
    shots[12] = {
        "name": names[12],
        "duration": "fit",
        "hold": 0.46,
        "camera": {"at": "router_vacuum.camera", "look_at": "router_vacuum.focus", "lens_mm": 33},
    }
    shots[13] = {
        "name": names[13],
        "duration": "fit",
        "hold": 0.30,
        "camera": {"at": "akash_data.camera", "look_at": "akash_data.focus", "lens_mm": 32},
        "shake": [{"t": akash_word("calls"), "amount": 0.14}],
    }
    shots[14] = {
        "name": names[14],
        "duration": "fit",
        "hold": 0.38,
        "camera": {"at": "oxygen.camera", "look_at": "oxygen.focus", "lens_mm": 31},
    }
    shots[15] = {
        "name": names[15],
        "duration": "fit",
        "look": {
            "base": "day", "time": "16:50",
            "weather": {"clouds": 0.25},
            "sky": {"top": "#548cc6", "horizon": "#bed8e0"},
            "sun": {"elevation": 32, "azimuth": -39, "energy": 1.05},
            "ambient": {"color": "#a4c5db", "energy": 0.44},
            "grade": {"contrast": 1.06, "saturation": 1.08, "vignette": 0.12},
        },
        "camera": {"at": "network_build.camera", "look_at": "network_build.focus", "lens_mm": 32},
        "shake": [
            {"t": tower_word("towers", offset=0.44), "amount": 0.31},
            {"t": tower_word("towers", offset=1.00), "amount": 0.28},
        ],
    }
    shots[16] = {
        "name": names[16],
        "duration": "fit",
        "hold": 0.38,
        "look": shots[15]["look"],
        "camera": {"at": "fibre_lay.camera", "look_at": "fibre_lay.focus", "lens_mm": 30},
    }
    shots[17] = {
        "name": names[17],
        "duration": "fit",
        "camera": {"at": "startup.camera", "look_at": "startup.focus", "lens_mm": 32},
    }
    shots[18] = {
        "name": names[18],
        "duration": "fit",
        "hold": 0.30,
        "camera": {"at": "launch.camera", "look_at": "launch.focus", "lens_mm": 27,
                   "dof": {"strength": 0.20}},
        "shake": [{"t": launch_word("launch"), "amount": 0.34}],
    }
    shots[19] = {
        "name": names[19],
        "duration": "fit",
        "hold": 0.25,
        "camera": {"at": "sim_store.camera", "look_at": "sim_store.focus", "lens_mm": 25,
                   "dof": {"strength": 0.13}},
    }
    shots[20] = {
        "name": names[20],
        "duration": "fit",
        "hold": 0.53,
        "camera": {"at": "activation.camera", "look_at": "activation.focus", "lens_mm": 28,
                   "dof": {"strength": 0.16}},
    }
    shots[21] = {
        "name": names[21],
        "duration": "fit",
        "hold": 0.36,
        "camera": {"at": "complaint.camera", "look_at": "complaint.focus", "lens_mm": 25,
                   "dof": {"strength": 0.13}},
        "shake": [{"t": regulator_word("calls"), "amount": 0.26}],
    }
    shots[22] = {
        "name": names[22],
        "duration": "fit",
        "hold": 0.25,
        "camera": {"at": "phone_truck.camera", "look_at": "phone_truck.focus", "lens_mm": 27,
                   "dof": {"strength": 0.18}},
        "shake": [{"t": phone_word("give"), "amount": 0.35},
                  {"t": phone_word("JioPhone"), "amount": 0.30}],
    }
    shots[23] = {
        "name": names[23],
        "duration": "fit",
        "hold": 0.38,
        "camera": {"at": "busy_recharge.camera", "look_at": "busy_recharge.focus", "lens_mm": 29,
                   "dof": {"strength": 0.15}},
    }
    shots[24] = {
        "name": names[24],
        "duration": "fit",
        "hold": 0.34,
        "camera": {"at": "data_earth.camera", "look_at": "data_earth.focus", "lens_mm": 30},
    }
    shots[25] = {
        "name": names[25],
        "duration": "fit",
        "hold": 0.25,
        "camera": {"at": "fallen_kings.camera", "look_at": "fallen_kings.focus", "lens_mm": 28,
                   "dof": {"strength": 0.15}},
    }
    shots[26] = {
        "name": names[26],
        "duration": "fit",
        "hold": 0.62,
        "camera": {"at": "jio_throne.camera", "look_at": "jio_throne.focus", "lens_mm": 29},
        "shake": [{"t": throne_word("one"), "amount": 0.24}],
    }
    shots[27] = {
        "name": names[27],
        "duration": "fit",
        "hold": 0.38,
        "camera": {"at": "investment_cake.camera", "look_at": "investment_cake.focus", "lens_mm": 25,
                   "dof": {"strength": 0.11}},
    }
    shots[28] = {
        "name": names[28],
        "duration": "fit",
        "hold": 0.25,
        "camera": {"at": "postal_today.camera", "look_at": "postal_today.focus", "lens_mm": 28},
    }
    shots[29] = {
        "name": names[29],
        "duration": "fit",
        "camera": {"at": "penthouse_payoff.camera", "look_at": "penthouse_payoff.focus",
                   "lens_mm": 27, "dof": {"strength": 0.14}},
    }
    shots[30] = {
        "name": names[30],
        "duration": "fit",
        "hold": 0.40,
        "camera": {"at": "penthouse_payoff.camera", "look_at": "penthouse_payoff.focus",
                   "lens_mm": 28, "dof": {"strength": 0.19}},
    }
    return {
        "schema_version": "0.1",
        "id": "jio_story",
        "title": "How Mukesh Ambani built Jio",
        "description": "The 31-beat Jio v2 cut.",
        "set": SET_PATH,
        "look": "toon_drama",
        "format": {"resolution": [1080, 1920], "fps": 60, "motion_blur": 3},
        "narration": {
            "voice": "Puck",
            "style": "fast, punchy, confident YouTube Shorts explainer narrator, playful and a little cheeky",
            "speed": 1.08,
            "model": "gemini-3.8-flash-tts",
            "single_take": True,
            "script": script,
        },
        "lines": [
            {"id": f"n{number}", "text": line, "shot": name}
            for number, (line, name) in enumerate(zip(script, names), start=1)
        ],
        "captions": {"style": "toon", "max_words": 2, "position": 0.79},
        "ambience": [{"sound": "beat", "gain": -22, "duck": 0.55}],
        "actors": [{
            "id": "mukesh",
            "character": "toon_mukesh",
            "at": {"anchor": "penthouse", "offset": [0, 0, 0.09]},
            "facing": 0,
            "action": "sit",
            "cues": [
                {"t": 0, "expression": "sad", "hands": "chin"},
                {"t": word("lost"), "expression": "side_eye"},
                {"t": word("business"), "expression": "sad"},
                {"t": {"line": "n30"}, "expression": "smug", "hands": "none",
                 "head": [-12, -16, -6], "head_turn": 0.3},
                {"t": payoff_word("free"), "expression": "laugh", "head": [-10, 3, -3],
                 "head_turn": 0.22},
                {"t": {"line": "n31"}, "expression": "happy"},
                {"t": closing_word("Jio"), "expression": "wink", "head": [-4, 0, 0],
                 "head_turn": 0.18},
                {"t": closing_word("live"), "expression": "sleepy", "head": [17, -3, 10],
                 "head_turn": 0.40},
            ],
        }, {
            "id": "postal_shopper",
            "character": "toon_you",
            "at": {"anchor": "postal_street", "offset": [0, 0, 3.55]},
            "facing": 180,
            "action": "idle",
            "cues": [
                {"t": street_word("2002", offset=0.25), "head": [-4, -6, 2], "head_turn": 0.15},
                {"t": street_word("2002", offset=0.40), "head": [2, 34, -5], "head_turn": 0.52},
                {"t": street_word("Dhirubhai"), "head": [4, 28, -6], "head_turn": 0.22},
                {"t": street_word("phone", offset=-0.53), "head": [0, -36, 6], "head_turn": 0.55},
                {"t": street_word("call"), "head": [2, -30, 7], "head_turn": 0.24},
                {"t": street_word("cost", offset=-0.03), "head": [7, -8, -11], "head_turn": 0.51},
                {"t": street_word("postcard"), "head": [4, -4, -8], "head_turn": 0.42},
            ],
        }, {
            "id": "kokila",
            "character": "toon_kokilaben",
            "at": {"anchor": "family_room", "offset": [0, 0, -0.07]},
            "facing": 0,
            "action": "sit",
            "cues": [
                {"t": 0, "expression": "happy", "head": [16, 0, 0]},
                {"t": family_word("phone"), "head": [11, 20, 0], "head_turn": 0.36},
                {"t": family_word("promise"), "head": [8, -22, 3], "head_turn": 0.32},
                {"t": family_word("stay"), "expression": "angry"},
                {"t": family_word("out"), "head": [5, -22, 1], "head_turn": 0.17},
                {"t": family_word("telecom"), "head": [7, -32, -4], "head_turn": 0.16},
                {"t": family_word("telecom", offset=0.19), "head": [10, -16, 3], "head_turn": 0.23},
            ],
        }, {
            "id": "baby_mukesh",
            "character": "toon_baby_mukesh",
            "at": {"anchor": "family_room", "offset": [0.42, 0, 0.20]},
            "facing": 44,
            "action": "sit",
            "cues": [
                {"t": 0, "head": [15, 0, 1]},
                {"t": family_word("phone"), "head": [12, 23, -6], "head_turn": 0.32,
                 "expression": "surprised"},
                {"t": family_word("out"), "head": [-8, -9, 8], "head_turn": 0.16,
                 "expression": "shocked"},
                {"t": family_word("telecom"), "head": [13, 0, 0], "head_turn": 0.34,
                 "expression": "sad"},
                {"t": {"line": "n10"}, "head": [5, 12, -4], "head_turn": 0.28,
                 "expression": "smug"},
                {"t": {"line": "n10", "word": "ends", "offset": -0.10},
                 "head": [-6, 19, 4], "head_turn": 0.25, "expression": "happy"},
            ],
        }, {
            "id": "baby_anil",
            "character": "toon_baby_anil",
            "at": {"anchor": "family_room", "offset": [-0.47, 0, 0.21]},
            "facing": -43,
            "action": "sit",
            "cues": [
                {"t": 0, "head": [15, 0, -2]},
                {"t": family_word("phone"), "head": [17, -12, -5], "head_turn": 0.30,
                 "expression": "cheer"},
                {"t": family_word("out"), "expression": "surprised",
                 "head": [1, -11, -7], "head_turn": 0.20},
                {"t": {"line": "n10"}, "head": [13, -6, 0], "head_turn": 0.25,
                 "expression": "neutral"},
                {"t": {"line": "n10", "word": "ends", "offset": 0.10},
                 "head": [-4, -25, -7], "head_turn": 0.23, "expression": "surprised"},
            ],
        }, {
            "id": "watching_mukesh",
            "character": "toon_mukesh",
            "at": {"anchor": "watchtower", "offset": [0.29, 0, 1.30]},
            "facing": 0,
            "action": "idle_formal",
            "cues": [
                {"t": 0, "expression": "side_eye", "head": [7, -7, 0]},
                {"t": {"line": "n4", "word": "watch", "offset": -0.29},
                 "head": [7, 3, 0], "head_turn": 0.29},
            ],
        }, {
            "id": "signal_climber",
            "character": "toon_you",
            "at": {"anchor": "signal_bazaar", "offset": [0.69, 0, 0.46]},
            "facing": 14,
            "action": "idle_formal",
            "cues": [
                {"t": 0, "expression": "nervous", "head": [-12, 22, -4]},
                {"t": {"line": "n5", "word": "most"}, "head": [-18, 33, -8], "head_turn": 0.45},
            ],
        }, *[
            {
                "id": f"signal_shopper_{index}",
                "character": character,
                "at": {"anchor": "signal_bazaar", "offset": [-x, 0, z]},
                "route": {
                    "via": [{"anchor": "signal_bazaar", "offset": [-(x + dx), 0, z + dz]}],
                    "gait": "walk",
                    "start": {"line": "n5", "offset": -0.11 + (index % 4) * 0.062},
                    "arrive": {"line": "n6", "offset": 0.30},
                },
                "action": "idle",
                "cues": [{
                    "t": {"line": "n5", "word": "online", "offset": -0.22 + (index % 5) * 0.075},
                    "expression": "nervous" if index % 3 else "surprised",
                    "head": [-20 - (index % 3) * 5, 38 + (index % 4) * 5, -5],
                    "head_turn": 0.45,
                }],
            }
            for index, (character, x, z, dx, dz) in enumerate(SIGNAL_SHOPPERS)
        ], {
            "id": "recharge_owner",
            "character": "toon_shopkeeper",
            "at": {"anchor": "recharge_shop", "offset": [-0.28, 0, -1.58]},
            "facing": 9,
            "action": "idle_formal",
            "cues": [
                {"t": 0, "expression": "happy", "head": [0, -24, -3]},
                {"t": {"line": "n6", "word": "costs"}, "head": [1, 15, 3], "head_turn": 0.46},
                {"t": {"line": "n6", "word": "rupees"}, "expression": "deadpan",
                 "head": [6, 21, 3], "head_turn": 0.35},
                {"t": {"line": "n7", "word": "video"}, "expression": "thinking",
                 "head": [12, 26, -5], "head_turn": 0.26},
                {"t": {"line": "n7", "word": "forever"}, "expression": "sad",
                 "head": [20, 19, -6], "head_turn": 0.28},
            ],
        }, *[
            {
                "id": f"recharge_passer_{index}",
                "character": character,
                "at": {"anchor": "recharge_shop", "offset": [x, 0, z]},
                "route": {
                    "via": [{"anchor": "recharge_shop", "offset": [end_x, 0, z]}],
                    "gait": "walk",
                    "start": {"line": "n6", "offset": lead},
                    "arrive": {"line": "n7", "offset": 0.30},
                },
                "action": "idle",
                "cues": [{"t": 0, "expression": "deadpan"}],
            }
            for index, (character, x, end_x, z, lead) in enumerate(RECHARGE_PASSERS)
        ], *[
            {
                "id": f"king_{carrier}",
                "character": character,
                "at": {"anchor": "telecom_durbar", "offset": [x, 0, z]},
                "facing": facing,
                "action": "sit",
                "cues": [
                    {"t": 0, "expression": "smug"},
                    {"t": court_word(carrier), "expression": "laugh", "head": [-7, 0, 4],
                     "head_turn": 0.26},
                    {"t": court_word("calls", offset=0.10 * index), "expression": "happy",
                     "head": [-12, 0, -4], "head_turn": 0.24},
                    {"t": court_word("data"), "expression": "laugh", "head": [-6, 0, 3],
                     "head_turn": 0.25},
                ],
            }
            for index, (carrier, character, x, z, facing) in enumerate(TELCO_KINGS)
        ], {
            "id": "chai_mukesh",
            "character": "toon_mukesh",
            "at": {"anchor": "chai_stall", "offset": [-0.08, 0, 0.06]},
            "facing": 8,
            "action": "sit",
            "cues": [
                {"t": 0, "expression": "thinking", "head": [2, 0, -2]},
                {"t": {"line": "n9", "word": "see"}, "expression": "side_eye",
                 "head": [5, -10, -2], "head_turn": 0.30},
                {"t": {"line": "n9", "word": "don't", "offset": -0.10}, "expression": "happy",
                 "head": [-5, 4, 3], "head_turn": 0.33},
            ],
        }, {
            "id": "infotel_bidder",
            "character": "toon_nerd",
            "at": {"anchor": "infotel_auction", "offset": [-0.17, 0, 0.10]},
            "facing": -9,
            "action": "sit",
            "cues": [
                {"t": 0, "expression": "thinking", "head": [9, -18, 2]},
                {"t": auction_word("wins"), "expression": "happy", "head": [6, -13, 1],
                 "head_turn": 0.24},
                {"t": auction_word("22"), "expression": "cheer", "head": [-9, 0, -6],
                 "head_turn": 0.23},
            ],
        }, {
            "id": "leaving_bidder",
            "character": "toon_nerd",
            "at": {"anchor": "auction_exit", "offset": [-0.42, 0, -0.96]},
            "facing": -9,
            "route": {
                "via": [{"anchor": "auction_exit", "offset": [-0.19, 0, 0.43]}],
                "gait": "walk",
                "start": {"line": "n12", "offset": -0.15},
                "arrive": cash_word("buy", offset=0.28),
            },
            "action": "idle",
            "cues": [
                {"t": 0, "expression": "happy"},
                {"t": cash_word("buy", offset=0.14), "expression": "shocked",
                 "head": [-12, -24, 6], "head_turn": 0.19},
                {"t": cash_word("percent", offset=0.18), "expression": "surprised",
                 "head": [2, -13, -4], "head_turn": 0.30},
            ],
        }, {
            "id": "cash_mukesh",
            "character": "toon_mukesh",
            "at": {"anchor": "auction_exit", "offset": [0.63, 0, -0.69]},
            "facing": 34,
            "action": "idle_formal",
            "cues": [
                {"t": 0, "expression": "smug", "head": [5, 10, -1]},
                {"t": cash_word("buy"), "expression": "happy", "head": [3, 15, -3],
                 "head_turn": 0.20},
            ],
        }, {
            "id": "isha_home",
            "character": "toon_isha",
            "at": {"anchor": "ambani_lounge", "offset": [0.54, 0, 0.22]},
            "facing": 24,
            "action": "sit",
            "cues": [
                {"t": 0, "expression": "deadpan", "head": [10, 13, -2]},
                {"t": home_word("Dad"), "expression": "side_eye", "head": [-7, 25, 3],
                 "head_turn": 0.28},
                {"t": home_word("internet"), "expression": "angry",
                 "head": [8, 15, -5], "head_turn": 0.25},
                {"t": home_word("sucks"), "expression": "surprised", "head": [0, 20, -4],
                 "head_turn": 0.19},
            ],
        }, {
            "id": "home_mukesh",
            "character": "toon_mukesh",
            "at": {"anchor": "ambani_lounge", "offset": [-0.82, 0, -0.46]},
            "facing": -14,
            "action": "idle_formal",
            "cues": [
                {"t": 0, "expression": "neutral", "head": [0, -7, 0]},
                {"t": home_word("Dad"), "expression": "thinking", "head": [8, -19, -2],
                 "head_turn": 0.32},
                {"t": home_word("sucks"), "expression": "shocked", "head": [10, -12, 5],
                 "head_turn": 0.20},
                {"t": {"line": "n14"}, "expression": "thinking", "head": [1, 18, 2],
                 "head_turn": 0.37},
            ],
        }, {
            "id": "akash_home",
            "character": "toon_akash",
            "at": {"anchor": "ambani_lounge", "offset": [-1.61, 0, 0.19]},
            "facing": 3,
            "action": "idle_formal",
            "cues": [
                {"t": 0, "expression": "thinking", "head": [4, -7, 1]},
                {"t": akash_word("calls"), "expression": "smug", "head": [8, -19, -4],
                 "head_turn": 0.29},
                {"t": akash_word("data"), "expression": "happy", "head": [-12, 7, 2],
                 "head_turn": 0.24},
            ],
        }, {
            "id": "doctor_mukesh",
            "character": "toon_mukesh_doctor",
            "at": {"anchor": "oxygen_clinic", "offset": [0, 0, -0.14]},
            "facing": 0,
            "action": "idle_formal",
            "cues": [
                {"t": 0, "expression": "happy", "head": [1, -10, -3]},
                {"t": oxygen_word("oxygen"), "head": [6, -23, -2], "head_turn": 0.31},
                {"t": oxygen_word("Cheap"), "head": [1, 19, 3], "head_turn": 0.46},
            ],
        }, *[
            {
                "id": f"oxygen_recipient_{index}",
                "character": character,
                "at": {"anchor": "oxygen_clinic", "offset": [-x, 0, 0.37]},
                "facing": yaw,
                "action": "idle",
                "cues": [
                    {"t": 0, "expression": "sad", "head": [9, 0, 0]},
                    {"t": oxygen_word(contact, offset=0.20), "expression": "happy",
                     "head": [-8, 0, yaw * 0.19], "head_turn": 0.24},
                ],
            }
            for index, (character, x, yaw, contact) in enumerate([
                ("toon_you", -0.74, 17, "oxygen"), ("toon_partner", 0.74, -15, "everyone"),
            ])
        ], {
            "id": "network_mukesh",
            "character": "toon_mukesh",
            "at": {"anchor": "network_field", "offset": [0.88, 0, 0.72]},
            "facing": 72,
            "action": "idle_formal",
            "cues": [
                {"t": 0, "expression": "side_eye", "head": [0, 2, 0]},
                {"t": tower_word("towers"), "expression": "determined", "head": [3, 0, -4],
                 "head_turn": 0.20},
                {"t": tower_word("build"), "expression": "smug", "head": [9, -16, 0],
                 "head_turn": 0.29},
                {"t": tower_word("4G-only"), "expression": "happy", "head": [-12, 9, 3],
                 "head_turn": 0.30},
            ],
        }, {
            "id": "fibre_mukesh",
            "character": "toon_mukesh",
            "at": {"anchor": "fibre_depot", "offset": [0.68, 0, -0.82]},
            "facing": 7,
            "route": {
                "via": [
                    {"anchor": "fibre_depot", "offset": [0.51, 0, 0.38]},
                    {"anchor": "fibre_depot", "offset": [0.25, 0, 1.32]},
                ],
                "gait": "run",
                "start": {"line": "n17", "offset": -0.07},
                "arrive": fibre_word("fibre", offset=0.15),
            },
            "action": "idle_formal",
            "cues": [
                {"t": 0, "expression": "determined", "head": [8, 0, -1]},
                {"t": fibre_word("fibre", offset=0.18), "expression": "happy",
                 "head": [-10, 2, 1], "head_turn": 0.22},
            ],
        }, {
            "id": "startup_mukesh",
            "character": "toon_mukesh_startup",
            "at": {"anchor": "startup_refinery", "offset": [0.19, 0, 0.22]},
            "facing": 2,
            "action": "sit",
            "cues": [
                {"t": 0, "expression": "thinking", "head": [7, 12, 0]},
                {"t": startup_word("rupees"), "expression": "surprised",
                 "head": [15, 14, 3], "head_turn": 0.27},
                {"t": startup_word("startup"), "expression": "smug",
                 "head": [-5, 0, -2], "head_turn": 0.26},
            ],
        }, {
            "id": "launch_mukesh",
            "character": "toon_mukesh",
            "at": {"anchor": "jio_launch", "offset": [-0.10, 0, -1.55]},
            "facing": 0,
            "action": "idle_formal",
            "cues": [
                {"t": 0, "expression": "smug", "head": [4, -8, 0]},
                {"t": launch_word("launch", offset=-0.45), "expression": "determined",
                 "head": [12, -16, 2], "head_turn": 0.22},
                {"t": launch_word("Jio", offset=0.05), "expression": "grin",
                 "head": [-6, 4, -2], "head_turn": 0.25},
                {"t": launch_word("And", offset=-0.2), "expression": "laugh",
                 "head": [-4, -14, 3], "head_turn": 0.22},
                {"t": launch_word("Calls", offset=-0.35), "expression": "grin",
                 "head": [-2, 24, -3], "head_turn": 0.24},
                {"t": launch_word("Apps", offset=0.25), "expression": "wink",
                 "head": [-4, 4, 2], "head_turn": 0.22},
            ],
        }, *[
            {
                "id": f"launch_fan_{index}",
                "character": character,
                "at": {"anchor": "jio_launch", "offset": [x, 0, z]},
                "facing": 180 + x * 4,
                "action": "idle",
                "cues": [
                    {"t": 0, "expression": "surprised" if index % 2 else "happy",
                     "head": [-14, 0, 0]},
                    {"t": launch_word("launch", offset=0.08 + (index % 5) * 0.05),
                     "expression": ["cheer", "star_eyes", "laugh"][index % 3],
                     "head": [-24, 0, (index % 3 - 1) * 6], "head_turn": 0.18},
                ],
            }
            for index, (character, x, z) in enumerate(LAUNCH_FANS)
        ], {
            "id": "sim_clerk",
            "character": "toon_shopkeeper",
            "at": {"anchor": "jio_store", "offset": [0.34, 0, -0.32]},
            "facing": 28,
            "action": "idle_formal",
            "cues": [
                {"t": 0, "expression": "happy", "head": [12, 5, -2]},
                {"t": queue_word("join"), "expression": "grin", "head": [-1, -7, 0],
                 "head_turn": 0.22},
            ],
        }, {
            "id": "sim_customer",
            "character": "toon_you",
            "at": {"anchor": "jio_store", "offset": [-0.36, 0, 0.59]},
            "facing": 220,
            "action": "idle",
            "cues": [
                {"t": 0, "expression": "happy", "head": [8, 12, 3]},
                {"t": queue_word("join"), "expression": "star_eyes",
                 "head": [11, -8, -3], "head_turn": 0.19},
                {"t": queue_word("in"), "facing": 44, "turn": 0.35,
                 "expression": "grin", "head": [-4, 3, 0], "head_turn": 0.24},
            ],
        }, *[
            {
                "id": f"sim_queue_{index}",
                "character": character,
                "at": {"anchor": "jio_store", "offset": [x, 0, z]},
                "facing": math.degrees(math.atan2(x - end_x, end_z - z)),
                "action": "idle",
                "phase": index * 0.27,
                "route": {
                    "via": [{"anchor": "jio_store", "offset": [end_x, 0, end_z]}],
                    "gait": "walk",
                    "start": queue_word("join", offset=index * 0.07),
                    "arrive": queue_word("join", offset=0.56 + index * 0.07),
                },
                "cues": [{"t": 0, "expression": ["happy", "thinking", "smug"][index % 3]}],
            }
            for index, (character, x, z, end_x, end_z) in enumerate(SIM_QUEUE)
        ], *[gate_customer(index, character) for index, character in enumerate(GATE_CUSTOMERS)], *[
            complaining_rival(index, carrier, character, x)
            for index, (carrier, character, x, _, _) in enumerate(TELCO_KINGS)
        ], {
            "id": "complaint_official",
            "character": "toon_official",
            "at": {"anchor": "trai_office", "offset": [0.21, 0, -1.05]},
            "facing": 12,
            "action": "idle_formal",
            "cues": [
                {"t": 0, "expression": "deadpan"},
                {"t": regulator_word("crying"), "expression": "side_eye", "head": [9, -15, 1],
                 "head_turn": 0.22},
                {"t": regulator_word("calls"), "expression": "shocked"},
            ],
        }, {
            "id": "complaint_mukesh",
            "character": "toon_mukesh",
            "at": {"anchor": "trai_office", "offset": [-1.9, 0, 0.62]},
            "facing": -70,
            "action": "idle",
            "route": {
                "via": [{"anchor": "trai_office", "offset": [-1.00, 0, 1.65]}],
                "gait": "walk",
                "start": regulator_word("You", offset=-0.15),
                "arrive": regulator_word("their"),
                "then_facing": -58,
            },
            "cues": [
                {"t": 0, "expression": "side_eye"},
                {"t": regulator_word("calls"), "expression": "deadpan", "head": [21, -2, 2],
                 "head_turn": 0.18},
            ],
        }, {
            "id": "phone_mukesh",
            "character": "toon_mukesh",
            "at": {"anchor": "jiophone_lane", "offset": [0.20, 0, -0.25]},
            "facing": 0,
            "action": "idle_formal",
            "cues": [
                {"t": 0, "expression": "smug"},
                {"t": phone_word("give"), "expression": "laugh"},
                {"t": phone_word("JioPhone"), "expression": "grin"},
                {"t": phone_word("zero"), "expression": "wink"},
            ],
        }, *[
            {
                "id": f"phone_fan_{i}",
                "character": character,
                "at": {"anchor": "jiophone_lane", "offset": [x, 0, z]},
                "facing": 178 - x * 12,
                "action": "idle",
                "phase": i * 0.37,
                "cues": [
                    {"t": 0, "expression": "happy"},
                    {"t": phone_word("give", offset=i * 0.075), "expression": "star_eyes"},
                ],
            }
            for i, (character, x, z) in enumerate([
                ("toon_partner", -1.30, 1.39), ("toon_you", 1.24, 1.36),
                ("toon_redhead", -0.85, 2.47), ("toon_nerd", 0.83, 2.44),
            ])
        ], {
            "id": "busy_recharge_owner",
            "character": "toon_shopkeeper",
            "at": {"anchor": "recharge_shop", "offset": [-0.28, 0, -1.58]},
            "facing": 9,
            "action": "idle_formal",
            "cues": [
                {"t": 0, "expression": "sad"},
                {"t": rate_word("crashes"), "expression": "surprised"},
                {"t": rate_word("20"), "expression": "laugh", "head": [8, -11, 2], "head_turn": 0.2},
            ],
        }, *[
            {
                "id": f"busy_recharge_{index}",
                "character": character,
                "at": {"anchor": "recharge_shop", "offset": [start_x, 0, start_z]},
                "facing": 170,
                "action": "idle",
                "route": {
                    "via": [{"anchor": "recharge_shop", "offset": [x, 0, z]}],
                    "gait": "jog",
                    "start": rate_word("crashes", offset=0.12 * index),
                    "arrive": rate_word("gigabyte", offset=0.09 * index),
                    "then_facing": 180,
                },
                "cues": [
                    {"t": 0, "expression": "happy"},
                    {"t": rate_word("20"), "expression": "star_eyes"},
                ],
            }
            for index, (character, start_x, start_z, x, z) in enumerate([
                ("toon_you", -2.70, 3.35, -0.55, 0.02),
                ("toon_partner", 2.87, 3.48, 0.56, 0.30),
                ("toon_nerd", -1.69, 4.07, -1.48, 0.60),
                ("toon_redhead", 1.86, 4.15, 1.49, 0.76),
                ("toon_founder", 0.85, 4.58, 0.50, 1.48),
                ("toon_isha", -0.66, 4.75, -0.57, 1.54),
            ])
        ], {
            "id": "globe_mukesh",
            "character": "toon_mukesh",
            "at": {"anchor": "data_globe", "offset": [0.83, 0, 0.18]},
            "facing": 43,
            "action": "idle",
            "cues": [
                {"t": 0, "expression": "thinking"},
                {"t": globe_word("biggest"), "expression": "grin", "head": [-10, 0, 0], "head_turn": 0.25},
            ],
        }, *[
            {
                "id": f"fallen_{carrier}",
                "character": character,
                "at": {"anchor": "telecom_durbar", "offset": [x * 0.80, 0, 0.88 + index * 0.10]},
                "facing": [-29, 0, 32][index],
                "action": "crouch",
                "cues": [
                    {"t": 0, "expression": "crying"},
                    {"t": fallout_word("bankrupt"), "expression": "panic"},
                    {"t": fallout_word("merge"), "expression": "crying", "head": [13, 7, -6],
                     "head_turn": 0.24},
                ],
            }
            for index, (carrier, character, x, _, _) in enumerate(TELCO_KINGS)
        ], {
            "id": "throne_mukesh",
            "character": "toon_mukesh",
            "at": {"anchor": "telecom_durbar", "offset": [-0.95, 0, 0.71]},
            "facing": -90,
            "action": "idle",
            "route": {
                "via": [{"anchor": "telecom_durbar", "offset": [0, 0, 0.71]}],
                "gait": "walk",
                "start": {"line": "n27"},
                "arrive": throne_word("2019", edge="end", offset=-0.22),
                "then_facing": 0,
            },
            "cues": [
                {"t": 0, "expression": "smug"},
                {"t": throne_word("Jio", offset=0.06), "action": "sit_down"},
                {"t": throne_word("number", offset=0.19), "action": "sit", "expression": "grin"},
                {"t": throne_word("one"), "expression": "cool"},
            ],
        }, {
            "id": "invest_mukesh",
            "character": "toon_mukesh",
            "at": {"anchor": "jio_investments", "offset": [0, 0, -0.66]},
            "action": "idle_formal",
            "cues": [{"t": 0, "expression": "smug"}, {"t": investment_word("slice"), "expression": "grin"}],
        }, *[
            {
                "id": f"invest_buyer_{i}",
                "character": character,
                "at": {"anchor": "jio_investments", "offset": [side * 2.70, 0, 0.90]},
                "facing": side * 75,
                "action": "idle",
                "route": {
                    "via": [{"anchor": "jio_investments", "offset": [side * 0.89, 0, 0.78]}],
                    "gait": "walk_carry",
                    "start": investment_word(brand),
                    "arrive": investment_word(price, offset=-0.12),
                    "then_facing": side * 28,
                },
                "cues": [{"t": 0, "expression": "determined"},
                         {"t": investment_word(price), "expression": "happy"}],
            }
            for i, (character, side, brand, price) in enumerate([
                ("toon_founder", 1, "Facebook", "5.7"),
                ("toon_pichai", -1, "Google", "4.5"),
            ])
        ], {
            "id": "postal_today_shopper",
            "character": "toon_you",
            "at": {"anchor": "postal_street", "offset": [-0.48, 0, 0.97]},
            "facing": 17,
            "action": "idle",
            "route": {
                "via": [{"anchor": "postal_street", "offset": [0.37, 0, 3.58]}],
                "gait": "walk",
                "start": today_word("Today", offset=-0.10),
                "arrive": today_word("Jio"),
                "then": "phone",
            },
            "cues": [
                {"t": 0, "expression": "happy", "head": [0, -8, 1]},
                {"t": today_word("Jio"), "expression": "laugh", "head": [-4, 12, 1], "head_turn": 0.24},
            ],
        }],
        "gags": [{
            "id": "office",
            "script": "gags/tower_open.gd",
            "at": "penthouse",
            "t": 0,
            "until": {"line": "n30"},
            "params": {
                "arrive": word("Ambani", edge="end"),
                "refinery": word("refineries"),
                "pump": word("pumps"),
                "bottle": word("plastics"),
                "burst": word("lost"),
            },
        }, {
            "id": "postal_choice",
            "script": "gags/postal_choice.gd",
            "at": "postal_street",
            "t": 0,
            "until": {"line": "n29"},
            "params": {
                "street_start": {"line": "n2"},
                "street_end": {"line": "n3"},
            },
        }, {
            "id": "toy_split",
            "script": "gags/family_split.gd",
            "at": "family_room",
            "t": {"line": "n3"},
            "until": {"line": "n11"},
            "params": {
                "split": family_word("splits"),
                "phone": family_word("phone"),
                "reach": family_word("promise"),
                "swat": family_word("out"),
                "split_end": {"line": "n4"},
                "reunion": {"line": "n10"},
                "show_phone": {"line": "n10", "word": "ends"},
                "end": {"line": "n11"},
            },
        }, {
            "id": "tower_watch",
            "script": "gags/tower_watch.gd",
            "at": "watchtower",
            "t": {"line": "n4"},
            "until": {"line": "n5"},
            "params": {"watch": {"line": "n4", "word": "watch"}},
        }, {
            "id": "signal_hunt",
            "script": "gags/signal_hunt.gd",
            "at": "signal_bazaar",
            "t": {"line": "n5"},
            "until": {"line": "n6"},
            "params": {
                "crowd_count": len(SIGNAL_SHOPPERS),
                "pullback": {"line": "n5", "word": "2015", "edge": "end"},
                "online": {"line": "n5", "word": "online"},
                "slow": {"line": "n5", "word": "slow"},
                "end": {"line": "n6"},
            },
        }, {
            "id": "recharge",
            "script": "gags/recharge_shop.gd",
            "at": "recharge_shop",
            "t": {"line": "n6"},
            "until": {"line": "n8"},
            "params": {
                "price": {"line": "n6", "word": "250"},
                "closeup": {"line": "n7"},
                "play": {"line": "n7", "word": "video"},
                "buffer": {"line": "n7", "word": "buffers"},
                "give_up": {"line": "n7", "word": "forever"},
                "end": {"line": "n8"},
            },
        }, {
            "id": "telco_court",
            "script": "gags/telco_court.gd",
            "at": "telecom_durbar",
            "t": {"line": "n8"},
            "until": {"line": "n9"},
            "params": {
                "toast": [court_word(carrier) for carrier, *_ in TELCO_KINGS],
                "money": court_word("money"),
                "sip": court_word("calls"),
                "rattle": court_word("data"),
                "end": {"line": "n9"},
            },
        }, {
            "id": "chai_watch",
            "script": "gags/chai_watch.gd",
            "at": "chai_stall",
            "t": {"line": "n9"},
            "until": {"line": "n10"},
            "params": {
                "lower": {"line": "n9", "word": "see"},
                "end": {"line": "n10"},
            },
        }, {
            "id": "auction",
            "script": "gags/infotel_auction.gd",
            "at": "infotel_auction",
            "t": {"line": "n11"},
            "until": {"line": "n12"},
            "params": {
                "first_win": auction_word("wins"),
                "twenty_two": auction_word("22"),
                "end": {"line": "n12"},
            },
        }, {
            "id": "cash_blaster",
            "script": "gags/cash_blaster.gd",
            "at": "auction_exit",
            "t": {"line": "n12"},
            "until": {"line": "n13"},
            "params": {"fire": cash_word("buy"), "end": {"line": "n13"}},
        }, {
            "id": "acquisition_cash",
            "script": "library:cash_stream",
            "at": {"anchor": "auction_exit", "offset": [-0.19, 0.05, 0.43]},
            "t": {"line": "n12"},
            "until": {"line": "n13"},
            "params": {
                "from": "cash_blaster.muzzle", "fire": cash_word("buy"),
                "duration": 0.53, "flight": 0.31, "arc": 0.33,
                "count": 840, "radius": 0.83, "height": 0.95,
                "size": 0.23, "seed": 12, "color": "#79ad74",
            },
        }, {
            "id": "router_vacuum",
            "script": "gags/router_vacuum.gd",
            "at": "ambani_lounge",
            "t": {"line": "n13"},
            "until": {"line": "n15"},
            "params": {
                "dad": home_word("Dad"),
                "tap": home_word("internet"),
                "suck": home_word("sucks"),
                "end": {"line": "n14"},
            },
        }, {
            "id": "akash_data",
            "script": "gags/akash_data.gd",
            "at": "ambani_lounge",
            "t": {"line": "n14"},
            "until": {"line": "n15"},
            "params": {
                "show": akash_word("Akash"),
                "calls": akash_word("calls"),
                "data": akash_word("data"),
                "end": {"line": "n15"},
            },
        }, {
            "id": "oxygen",
            "script": "gags/oxygen_station.gd",
            "at": "oxygen_clinic",
            "t": {"line": "n15"},
            "until": {"line": "n16"},
            "params": {
                "handoffs": [oxygen_word("oxygen"), oxygen_word("everyone")],
                "end": {"line": "n16"},
            },
        }, {
            "id": "network_build",
            "script": "gags/network_build.gd",
            "at": "network_field",
            "t": {"line": "n16"},
            "until": {"line": "n17"},
            "params": {
                "push": tower_word("towers"),
                "build": tower_word("build"),
                "rise": tower_word("4G-only"),
                "data": tower_word("data"),
                "end": {"line": "n17"},
            },
        }, {
            "id": "fibre_lay",
            "script": "gags/fibre_lay.gd",
            "at": "fibre_depot",
            "t": {"line": "n17"},
            "until": {"line": "n18"},
            "params": {
                "lay": fibre_word("lay"),
                "count": fibre_word("lakh"),
                "finish": fibre_word("fibre"),
                "end": {"line": "n18"},
            },
        }, {
            "id": "startup",
            "script": "gags/startup_refinery.gd",
            "at": "startup_refinery",
            "t": {"line": "n18"},
            "until": {"line": "n19"},
            "params": {
                "bill": startup_word("bill"),
                "total": startup_word("rupees"),
                "pull": startup_word("call"),
                "startup": startup_word("startup"),
            },
        }, {
            "id": "launch",
            "script": "gags/jio_launch.gd",
            "at": "jio_launch",
            "t": {"line": "n19"},
            "until": {"line": "n20"},
            "params": {
                "launch": launch_word("launch"),
                "throws": [launch_word("And"), launch_word("everything"), launch_word("free")],
                "slaps": [launch_word("Calls"), launch_word("Data"), launch_word("Apps")],
                "fans": len(LAUNCH_FANS),
            },
        }, {
            "id": "sim_store",
            "script": "gags/sim_queue.gd",
            "at": "jio_store",
            "t": {"line": "n20"},
            "until": {"line": "n21"},
            "params": {
                "join": queue_word("join"),
                "wide": queue_word("days"),
            },
        }, {
            "id": "activation",
            "script": "gags/activation_gate.gd",
            "at": "jio_activation",
            "t": {"line": "n21"},
            "until": {"line": "n22"},
            "params": {
                "rush": gate_word("seven"),
                "days": gate_word("170"),
                "crossings": [gate_crossing(index) for index in range(len(GATE_CUSTOMERS))],
            },
        }, {
            "id": "complaint",
            "script": "gags/trai_complaint.gd",
            "at": "trai_office",
            "t": {"line": "n22"},
            "until": {"line": "n23"},
            "params": {
                "run": regulator_word("run"),
                "cry": regulator_word("crying"),
                "file": regulator_word("pricing"),
                "ring": regulator_word("networks"),
                "drop": regulator_word("dropping"),
                "hit": regulator_word("calls"),
            },
        }, {
            "id": "phone_truck",
            "script": "gags/jiophone_truck.gd",
            "at": "jiophone_lane",
            "t": {"line": "n23"},
            "until": {"line": "n24"},
            "params": {
                "releases": [phone_word("give"), phone_word("phone"), phone_word("JioPhone")],
                "zero": phone_word("zero"),
            },
        }, {
            "id": "busy_recharge",
            "script": "gags/recharge_shop.gd",
            "at": "recharge_shop",
            "t": {"line": "n24"},
            "until": {"line": "n25"},
            "params": {"busy": rate_word("20"), "offer": rate_word("gigabyte")},
        }, {
            "id": "data_earth",
            "script": "gags/data_globe.gd",
            "at": "data_globe",
            "t": {"line": "n25"},
            "until": {"line": "n26"},
            "params": {"spin": globe_word("India"), "land": globe_word("biggest"), "data": globe_word("data")},
        }, {
            "id": "fallen_kings",
            "script": "gags/telco_court.gd",
            "at": "telecom_durbar",
            "t": {"line": "n26"},
            "until": {"line": "n27"},
            "params": {
                "fallout": [fallout_word("Telenor"), fallout_word("Tata"), fallout_word("Aircel"),
                            fallout_word("brother's")],
                "fly": fallout_word("down"),
                "merge": fallout_word("merge"),
            },
        }, {
            "id": "jio_throne",
            "script": "gags/telco_court.gd",
            "at": "telecom_durbar",
            "t": {"line": "n27"},
            "until": {"line": "n28"},
            "params": {"ascend": throne_word("one"), "sit": throne_word("Jio", offset=0.06),
                       "contact": throne_word("number", offset=0.19)},
        }, {
            "id": "investment_cake",
            "script": "gags/investment_cake.gd",
            "at": "jio_investments",
            "t": {"line": "n28"},
            "until": {"line": "n29"},
            "params": {
                "arrivals": [investment_word("Facebook"), investment_word("Google")],
                "payments": [investment_word("5.7"), investment_word("4.5")],
                "slices": [investment_word("slice"), investment_word("billion", occurrence=2)],
            },
        }, {
            "id": "postal_today",
            "script": "gags/postal_choice.gd",
            "at": "postal_street",
            "t": {"line": "n29"},
            "until": {"line": "n30"},
            "params": {"today": today_word("Today"), "connect": today_word("Jio")},
        }, {
            "id": "penthouse_payoff",
            "script": "gags/tower_open.gd",
            "at": "penthouse",
            "t": {"line": "n30"},
            "params": {
                "toast": payoff_word("free"),
                "close": {"line": "n31"},
                "wink": closing_word("Jio"),
                "sleep": closing_word("live"),
            },
        }],
        "reveals": [{
            "id": "postal_question",
            "text": "?",
            "at": {"anchor": "postal_shopper.head", "offset": [0, 0.46, 0]},
            "t": street_word("less", offset=0.04),
            "until": {"line": "n3"},
            "size": 0.45,
            "color": "#ffca54",
            "enter": "pop",
            "enter_time": 0.28,
            "exit": "none",
            "bob": 0.016,
            "sound": "pop",
        }, {
            "id": "sim_subscribers",
            "counter": {"from": 0, "to": 16, "suffix": " MILLION",
                        "land": queue_word("million"), "label": "SUBSCRIBERS"},
            "at": {"anchor": "jio_store", "offset": [-0.30, 3.24, 0.22]},
            "t": queue_word("Sixteen"),
            "until": {"line": "n21"},
            "size": 0.29,
            "color": "#f5faff",
            "enter": "none",
            "exit": "none",
        }, {
            "id": "sim_days",
            "counter": {"from": 1, "to": 26, "suffix": " DAYS", "land": queue_word("26")},
            "at": {"anchor": "jio_store", "offset": [-0.30, 2.79, 0.22]},
            "t": queue_word("in"),
            "until": {"line": "n21"},
            "size": 0.22,
            "color": "#e1ecff",
            "enter": "none",
            "exit": "none",
        }, {
            "id": "activation_milestone",
            "counter": {"from": 16, "to": 100, "suffix": " MILLION",
                        "land": gate_word("million"), "label": "SUBSCRIBERS"},
            "at": {"anchor": "jio_activation", "offset": [0.20, 3.48, 0.0]},
            "t": gate_word("hundred", offset=-0.24),
            "until": gate_word("seven", offset=-0.16),
            "size": 0.31,
            "color": "#f5faff",
            "enter": "none",
            "exit": "none",
        }, {
            "id": "activation_days",
            "counter": {"from": 26, "to": 170, "suffix": " DAYS", "land": gate_word("170")},
            "at": {"anchor": "jio_activation", "offset": [0.20, 3.01, 0.0]},
            "t": gate_word("in"),
            "until": gate_word("seven", offset=-0.16),
            "size": 0.23,
            "color": "#e1ecff",
            "enter": "none",
            "exit": "none",
        }, {
            "id": "activation_rate",
            "counter": {"from": 0, "to": 7, "prefix": "+", "land": gate_word("seven"),
                        "label": "CUSTOMERS / SECOND"},
            "at": {"anchor": "jio_activation", "offset": [0.20, 3.40, 0.0]},
            "t": gate_word("seven", offset=-0.15),
            "until": {"line": "n22"},
            "size": 0.41,
            "color": "#f5faff",
            "enter": "none",
            "exit": "none",
        }, {
            "id": "effective_jiophone_price",
            "counter": {"from": 1500, "to": 0, "prefix": "₹", "land": phone_word("zero"),
                        "label": "EFFECTIVE PRICE"},
            "at": {"anchor": "jiophone_lane", "offset": [0, 2.81, 0.0]},
            "t": phone_word("effective"),
            "until": {"line": "n24"},
            "size": 0.36,
            "color": "#fff0dd",
            "enter": "none",
            "exit": "none",
        }, {
            "id": "jio_rank",
            "counter": {"from": 3, "to": 1, "prefix": "#", "land": throne_word("one"),
                        "label": "JIO · 2019"},
            "at": {"anchor": "telecom_durbar", "offset": [0, 3.15, 0.04]},
            "t": throne_word("number"),
            "until": {"line": "n28"},
            "size": 0.47,
            "color": "#fff0dc",
            "enter": "none",
            "exit": "none",
        }, {
            "id": "facebook_investment",
            "counter": {"from": 0, "to": 5.7, "prefix": "$", "suffix": " BILLION", "decimals": 1,
                        "land": investment_word("5.7"), "label": "FACEBOOK"},
            "at": {"anchor": "jio_investments", "offset": [0, 2.45, 0.14]},
            "t": investment_word("pays"),
            "until": investment_word("Google"),
            "size": 0.31, "color": "#dcecff", "enter": "none", "exit": "none",
        }, {
            "id": "google_investment",
            "counter": {"from": 0, "to": 4.5, "prefix": "$", "suffix": " BILLION", "decimals": 1,
                        "land": investment_word("4.5"), "label": "GOOGLE"},
            "at": {"anchor": "jio_investments", "offset": [0, 2.45, 0.14]},
            "t": investment_word("Google", offset=0.23),
            "until": {"line": "n29"},
            "size": 0.31, "color": "#dcecff", "enter": "none", "exit": "none",
        }, {
            "id": "jio_today_subscribers",
            "counter": {"from": 100, "to": 524, "suffix": " MILLION",
                        "land": today_word("million"), "label": "JIO SUBSCRIBERS · MAR 2026"},
            "at": {"anchor": "postal_street", "offset": [0.02, 2.82, 1.33]},
            "t": today_word("Today", offset=0.48),
            "until": {"line": "n30"},
            "size": 0.31, "color": "#dcecff", "enter": "none", "exit": "none",
        }],
        "sfx": [
            {"sound": "whoosh", "at": word("Mukesh", offset=-0.25), "gain": -12},
            {"sound": "tick", "at": word("refineries"), "gain": -7},
            {"sound": "tick", "at": word("pumps"), "gain": -7},
            {"sound": "tick", "at": word("plastics"), "gain": -7},
            {"sound": "pop", "at": word("lost"), "repeat": 3, "every": 0.055, "gain": -4},
            {"sound": "click", "at": family_word("splits", offset=0.32), "gain": -13},
            {"sound": "click", "at": family_word("phone"), "gain": -10},
            {"sound": "whoosh", "at": family_word("stay", offset=0.13), "gain": -19},
            {"sound": "thud", "at": family_word("out"), "gain": -9},
            {"sound": "click", "at": {"line": "n4", "word": "watch"}, "gain": -14},
            {"sound": "whoosh", "at": {"line": "n4", "word": "So", "offset": -0.20}, "gain": -17},
            {"sound": "whoosh", "at": {"line": "n5", "word": "most", "offset": -0.12}, "gain": -18},
            {"sound": "tick", "at": {"line": "n5", "word": "slow"}, "gain": -13},
            {"sound": "tick", "at": court_word("money", offset=0.42),
             "repeat": 4, "every": 0.095, "gain": -13},
            {"sound": "creak", "at": court_word("data"), "gain": -17},
            {"sound": "click", "at": {"line": "n10", "word": "ends"}, "gain": -16},
            {"sound": "click", "at": auction_word("wins"), "gain": -13},
            {"sound": "tick", "at": auction_word("wins", offset=0.16),
             "repeat": 12, "every": 0.12, "gain": -20},
            {"sound": "ding", "at": auction_word("22"), "gain": -10},
            {"sound": "thud", "at": cash_word("buy"), "gain": -8},
            {"sound": "cash", "at": cash_word("buy", offset=0.06),
             "repeat": 5, "every": 0.13, "gain": -9},
            {"sound": "click", "at": home_word("internet"), "gain": -16},
            {"sound": "whoosh", "at": home_word("sucks", offset=-0.05), "gain": -9},
            {"sound": "pop", "at": home_word("sucks", offset=0.36), "gain": -14},
            {"sound": "thud", "at": akash_word("calls"), "gain": -13},
            {"sound": "whoosh", "at": akash_word("data"), "gain": -13},
            {"sound": "ding", "at": akash_word("data", offset=0.17), "gain": -15},
            {"sound": "click", "at": oxygen_word("oxygen"), "gain": -15},
            {"sound": "click", "at": oxygen_word("everyone"), "gain": -15},
            {"sound": "ding", "at": oxygen_word("oxygen", offset=0.25), "gain": -15},
            {"sound": "ding", "at": oxygen_word("everyone", offset=0.25), "gain": -15},
            {"sound": "thud", "at": tower_word("towers", offset=0.45),
             "repeat": 4, "every": 0.24, "gain": -11},
            {"sound": "click", "at": tower_word("build"), "gain": -13},
            {"sound": "whoosh", "at": tower_word("4G-only", offset=-0.08), "gain": -12},
            {"sound": "ding", "at": tower_word("data"), "gain": -14},
            {"sound": "whoosh", "at": fibre_word("lay"), "gain": -17},
            {"sound": "tick", "at": fibre_word("lay"), "repeat": 8, "every": 0.115, "gain": -18},
            {"sound": "ding", "at": fibre_word("lakh"), "gain": -11},
            {"sound": "click", "at": startup_word("bill"), "gain": -12},
            {"sound": "tick", "at": startup_word("bill", offset=0.08),
             "repeat": 16, "every": 0.11, "gain": -17},
            {"sound": "ding", "at": startup_word("rupees"), "gain": -13},
            {"sound": "thud", "at": launch_word("launch"), "gain": -6},
            {"sound": "sting", "at": launch_word("launch", offset=0.03), "gain": -14},
            {"sound": "cheer", "at": launch_word("launch", offset=0.12), "gain": -11},
            {"sound": "cheer", "at": launch_word("everything"), "gain": -14},
            {"sound": "whoosh", "at": launch_word("And", offset=0.08), "gain": -14},
            {"sound": "whoosh", "at": launch_word("everything", offset=0.08), "gain": -14},
            {"sound": "whoosh", "at": launch_word("free", offset=0.08), "gain": -13},
            {"sound": "pop", "at": launch_word("Calls"), "gain": -6},
            {"sound": "pop", "at": launch_word("Data"), "gain": -6},
            {"sound": "pop", "at": launch_word("Apps"), "gain": -5},
            {"sound": "tick", "at": queue_word("Sixteen"), "repeat": 4, "every": 0.075, "gain": -18},
            {"sound": "ding", "at": queue_word("million"), "gain": -12},
            {"sound": "click", "at": queue_word("join"), "gain": -11},
            {"sound": "ding", "at": queue_word("26"), "gain": -16},
            {"sound": "tick", "at": gate_word("hundred", offset=-0.20),
             "repeat": 5, "every": 0.10, "gain": -19},
            {"sound": "ding", "at": gate_word("million"), "gain": -12},
            {"sound": "ding", "at": gate_word("170"), "gain": -15},
            {"sound": "tick", "at": gate_word("seven"), "repeat": 2, "every": 1.0, "gain": -8},
            {"sound": "click", "at": gate_word("seven", offset=0.03),
             "repeat": GATE_GROUP_SIZE, "every": GATE_SPACING, "gain": -15},
            {"sound": "click", "at": gate_word("seven", offset=1.03),
             "repeat": GATE_GROUP_SIZE, "every": GATE_SPACING, "gain": -15},
            {"sound": "whoosh", "at": regulator_word("run"), "gain": -18},
            {"sound": "pop", "at": regulator_word("crying"), "repeat": 4, "every": 0.12, "gain": -19},
            {"sound": "thud", "at": regulator_word("pricing"), "gain": -17},
            {"sound": "ding", "at": regulator_word("networks"), "repeat": 2, "every": 0.19, "gain": -14},
            {"sound": "click", "at": regulator_word("calls"), "gain": -6},
            {"sound": "thud", "at": regulator_word("calls"), "gain": -13},
            {"sound": "thud", "at": phone_word("give"), "gain": -10},
            {"sound": "thud", "at": phone_word("phone"), "gain": -13},
            {"sound": "thud", "at": phone_word("JioPhone"), "gain": -10},
            {"sound": "click", "at": phone_word("give", offset=0.06), "repeat": 14, "every": 0.095, "gain": -20},
            {"sound": "cheer", "at": phone_word("give", offset=0.18), "gain": -17},
            {"sound": "tick", "at": phone_word("effective"), "repeat": 7, "every": 0.12, "gain": -18},
            {"sound": "ding", "at": phone_word("zero"), "gain": -10},
            {"sound": "whoosh", "at": rate_word("crashes"), "gain": -18},
            {"sound": "click", "at": rate_word("gigabyte"), "gain": -16},
            {"sound": "ding", "at": rate_word("20"), "gain": -11},
            {"sound": "whoosh", "at": globe_word("India"), "gain": -18},
            {"sound": "ding", "at": globe_word("biggest"), "gain": -14},
            {"sound": "cash", "at": fallout_word("bankrupt"), "gain": -15},
            {"sound": "tick", "at": fallout_word("down"), "gain": -17},
            {"sound": "thud", "at": fallout_word("merge"), "gain": -15},
            {"sound": "sting", "at": throne_word("one"), "gain": -13},
            {"sound": "thud", "at": throne_word("number", offset=0.19), "gain": -17},
            {"sound": "cash", "at": investment_word("5.7"), "gain": -13},
            {"sound": "cash", "at": investment_word("4.5"), "gain": -13},
            {"sound": "pop", "at": investment_word("slice"), "gain": -16},
            {"sound": "ding", "at": today_word("million"), "gain": -13},
            {"sound": "ding", "at": payoff_word("free"), "gain": -15},
            {"sound": "tick", "at": closing_word("Jio"), "gain": -17},
        ],
        "shots": shots,
    }


if __name__ == "__main__":
    write_json(ROOT / SET_PATH, build_set())
    write_json(EPISODE / "episode.json", build())
