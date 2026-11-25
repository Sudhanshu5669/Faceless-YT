"""Victoria Dock, Bombay, 14 April 1944 (gags/dock.gd "dock_set" + gags/dock_props.gd "dock_props").

Frame (local metres): the water at y 0; the near quay edge at z +11.5, deck at y 2.6; the Fort Stikine along x
(midships x 0, bow +x, centreline z 0; deck ~5.5); No. 2 hold at x +33; the dock office and clock tower at
(6, 2.6, 38.5), clock faces at y ~23.4; the Fort Crevier bow-to-bow, her bow at x ~+101; the Jalapadma astern at
x -168. Cameras mostly on or above the near quay looking -z, or across the basin looking +z.
"""
from .common import W, frame, cam, move

P = frame("dock", 0.0)
QZ, QH = 11.5, 2.6
HOLD2 = (32.0, 8.4, 0.0)
DECK = 7.2
TOWER = (6.0, QH, QZ + 27.0)
GANG_X = 24.0


def _look(time, elev, az, sun_col, energy, sky_top, sky_hor, amb_col, amb_e, fog_col, fog_end, vol=0.004, grade=None,
          glow=0.55, sun_vis=True):
    return {
        "base": "day", "time": time,
        "weather": {"fog": 0.0, "clouds": 0.0, "wind": 0.3},
        "sun": {"elevation": elev, "azimuth": az, "color": sun_col, "energy": energy, "softness": 0.6,
                "visible": sun_vis, "size": 1.2, "glow": 1.3, "shadows": True},
        "sky": {"top": sky_top, "horizon": sky_hor, "clouds": 0.0},
        "ambient": {"color": amb_col, "energy": amb_e, "sky": 0.5},
        "fog": {"begin": 80, "end": fog_end, "curve": 1.4, "volumetric": vol, "color": fog_col, "anisotropy": 0.65,
                "length": 400},
        "glow": {"enabled": True, "intensity": glow, "bloom": 0.05, "threshold": 1.1},
        "ssao": True,
        "grade": grade or {"contrast": 1.16, "saturation": 1.02, "vignette": 0.42, "grain": 0.035},
    }


LOOK_NOON = _look("12:30", 58, 205, "#fff0d6", 2.7, "#4f86c6", "#d6dde0", "#a8b0b8", 0.36, "#c8d2da", 3200, 0.0)
LOOK_1345 = _look("13:45", 50, 220, "#ffecd0", 2.7, "#5184c0", "#d8d8d2", "#aaa89e", 0.34, "#ccd0cc", 3000, 0.001)
LOOK_1550 = _look("15:50", 36, 238, "#ffd9a8", 3.0, "#5d7ea8", "#e2c49a", "#a88f6e", 0.28, "#c8ae88", 1800, 0.003,
                  {"contrast": 1.2, "saturation": 1.05, "vignette": 0.46, "grain": 0.04})
LOOK_1606 = _look("16:06", 33, 240, "#ffd09a", 3.2, "#56769e", "#e6c290", "#a48a68", 0.26, "#caa880", 2600, 0.0025,
                  {"contrast": 1.22, "saturation": 1.06, "vignette": 0.48, "grain": 0.04}, glow=0.75)
LOOK_NIGHT = {
    "base": "night_fog", "time": "23:00",
    "weather": {"fog": 0.0, "rain": 0.0, "clouds": 0.0, "wind": 0.2},
    "sun": {"elevation": -20, "azimuth": 0, "color": "#000000", "energy": 0.0, "visible": False, "shadows": False},
    "moon": {"elevation": -20, "visible": False, "energy": 0.0},
    "sky": {"top": "#05060a", "horizon": "#3a1a0c", "clouds": 0.0, "stars": 0.0},
    "ambient": {"color": "#3a2418", "energy": 0.12, "sky": 0.0},
    "fog": {"begin": 200, "end": 2500, "curve": 1.6, "volumetric": 0.004, "color": "#6a3a20", "anisotropy": 0.6, "length": 300},
    "glow": {"enabled": True, "intensity": 0.9, "bloom": 0.08, "threshold": 1.0},
    "ssao": True,
    "grade": {"contrast": 1.22, "saturation": 1.08, "vignette": 0.52, "grain": 0.045},
}
LOOK_DAWN = _look("06:10", 4, 80, "#ffb48a", 1.6, "#4a5e86", "#e8a88a", "#7a7c8e", 0.36, "#b0a4a8", 1600, 0.006,
                  {"contrast": 1.12, "saturation": 0.9, "vignette": 0.46, "grain": 0.04}, glow=0.6)

# Times (scene seconds once resolved).
T = {
    "smoke": {"shot": "clock_1230"}, "alarm": W("l10", "alarm"), "engines": W("l11a", "Firemen"), "boats": W("l11b", "Fireboats"),
    "hoses": W("l11c", "pour"), "pops": W("l12a", "going"), "abandon": W("l12b", "abandon"),
    "blast": W("l14c", "explodes"), "surge": W("l15", "throws"), "land": W("l15b", "dock."), "second": W("l18", "second"),
    "night": {"shot": "night_masts"}, "dawn": {"shot": "dawn_ruins"}, "helmets": {"shot": "helmets"},
}
CLOCK = [[0, 12 * 60 + 30], [{"shot": "clock_1345"}, 13 * 60 + 45], [{"shot": "abandon"}, 15 * 60 + 50],
         [W("l13", "Sixteen", 0.0), 16 * 60 + 6]]


def only(shot, nxt):
    return [[{"shot": shot}, {"shot": nxt}]]


ACTORS = [
    # The Fort Crevier's chief officer on her forecastle, binoculars up, toward the Stikine.
    {"id": "crevier_officer", "character": "toon_ship_officer", "at": P(116.0, 9.25, -5.0), "keep_y": True,
     "facing": P(32.0, 9.2, 1.0), "action": "idle", "shown": only("officer_bino", "smoke_hold"),
     "cues": [{"t": 0.0, "expression": "neutral"}, {"t": W("l9c", "officer", 0.2), "expression": "thinking"}, {"t": W("l9d", "sees", -0.1), "expression": "surprised"},
              {"t": W("l9d", "smoke", 0.2), "expression": "shocked"}]},
    # The dock officer at the fire bell.
    {"id": "dock_officer", "character": "toon_dock_officer", "at": P(TOWER[0] - 3.0, QH, TOWER[2] - 4.9), "keep_y": True,
     "facing": P(TOWER[0] - 2.2, QH, TOWER[2] - 4.0), "action": "idle", "shown": only("clock_1345", "engines_race"),
     "cues": [{"t": 0.0, "expression": "nervous"}, {"t": W("l10", "alarm", -0.2), "expression": "panic"}]},
    # Cotton: three dockworkers heaving the bales.
    {"id": "dw_a", "character": "toon_dockworker_a", "at": P(34.2, QH, QZ + 10.9), "keep_y": True, "facing": P(34.6, QH, QZ + 8.0),
     "action": "push", "shown": only("cotton_sling", "gold_crates"), "cues": [{"t": 0.0, "expression": "effort"}]},
    {"id": "dw_b", "character": "toon_dockworker_b", "at": P(38.9, QH, QZ + 11.6), "keep_y": True, "facing": P(36.0, 6.0, QZ + 2.0),
     "action": "call_out", "shown": only("cotton_sling", "gold_crates"), "cues": [{"t": 0.0, "expression": "determined"}]},
    {"id": "dw_c", "character": "toon_dockworker_c", "at": P(36.4, QH, QZ + 11.2), "keep_y": True, "facing": P(36.4, QH, QZ + 8.0),
     "action": "interact", "shown": only("cotton_sling", "gold_crates"), "cues": [{"t": 0.0, "expression": "strain"}]},
    # Gold: two sentries and a dockworker guiding the sling down.
    {"id": "guard_a", "character": "toon_guard_1944", "at": P(28.2, QH, QZ + 3.6), "keep_y": True, "facing": P(30.0, QH, QZ + 5.5),
     "action": "idle_formal", "shown": only("gold_crates", "xray_stack"),
     "cues": [{"t": 0.0, "expression": "deadpan"}, {"t": W("l7", "gold.", 0.05), "expression": "surprised"}]},
    {"id": "guard_b", "character": "toon_guard_1944", "at": P(31.9, QH, QZ + 3.4), "keep_y": True, "facing": P(30.0, QH, QZ + 5.5),
     "action": "idle_formal", "shown": only("gold_crates", "xray_stack"),
     "cues": [{"t": 0.0, "expression": "deadpan"}, {"t": W("l7", "gold.", 0.15), "expression": "star_eyes"}]},
    {"id": "gold_dw", "character": "toon_dockworker_b", "at": P(30.8, QH, QZ + 2.6), "keep_y": True, "facing": P(30.0, 3.4, QZ + 4.0),
     "action": "interact", "shown": only("gold_crates", "xray_stack"), "cues": [{"t": 0.0, "expression": "effort"}]},
    # Hoses: three firemen at the quay edge, nozzles on the hold.
    {"id": "hose_a", "character": "toon_bfb_fireman", "at": P(28.5, QH, QZ + 1.7), "keep_y": True, "facing": P(33.0, 9.0, 0.0),
     "action": "torch", "shown": only("hoses_900", "hold_steam"), "cues": [{"t": 0.0, "expression": "strain"}]},
    {"id": "hose_b", "character": "toon_bfb_fireman_b", "at": P(32.4, QH, QZ + 2.1), "keep_y": True, "facing": P(33.0, 9.0, 0.0),
     "action": "torch", "shown": only("hoses_900", "hold_steam"), "cues": [{"t": 0.0, "expression": "determined"}]},
    {"id": "hose_c", "character": "toon_bfb_fireman", "at": P(36.6, QH, QZ + 1.8), "keep_y": True, "facing": P(33.0, 9.0, 0.0),
     "action": "torch", "shown": only("hoses_900", "hold_steam"), "cues": [{"t": 0.0, "expression": "effort"}]},
    # Abandon ship: the officer with the megaphone.
    {"id": "chief", "character": "toon_bfb_chief", "at": P(20.2, QH, QZ + 5.0), "keep_y": True, "facing": P(24.0, 5.0, QZ + 3.0),
     "action": "idle", "shown": only("abandon", "clock_406"),
     "cues": [{"t": 0.0, "expression": "determined"}, {"t": W("l12b", "abandon", -0.1), "expression": "furious"}]},
]
# Dockworkers carrying loads along the quay past the ship.
for _i, (_ch, _x, _z, _dir) in enumerate([("toon_dockworker_a", -18.0, 4.2, 1), ("toon_dockworker_b", 14.0, 6.0, -1),
                                           ("toon_dockworker_c", -10.0, 3.4, 1), ("toon_dockworker_a", 20.0, 7.4, -1),
                                           ("toon_dockworker_b", -4.0, 4.8, 1), ("toon_dockworker_c", 26.0, 8.6, -1),
                                           ("toon_dockworker_a", -14.0, 9.4, 1), ("toon_dockworker_b", 8.0, 3.0, 1)]):
    ACTORS.append({"id": f"porter_{_i}", "character": _ch, "at": P(_x, QH, QZ + _z), "keep_y": True,
                   "facing": P(_x + 10 * _dir, QH, QZ + _z), "action": "idle", "shown": only("dock_wide", "xray_munitions"),
                   "route": {"via": [P(_x + 24 * _dir, QH, QZ + _z)], "gait": "walk_carry", "speed": 0.9},
                   "cues": [{"t": 0.0, "expression": "effort" if _i % 2 else "determined"}]})
# Firemen pouring down the gangway on the order.
for _i, (_ch, _dx) in enumerate([("toon_bfb_fireman", 0.0), ("toon_bfb_fireman_b", 0.45), ("toon_bfb_fireman", -0.4)]):
    ACTORS.append({"id": f"runner_{_i}", "character": _ch, "at": P(GANG_X + _dx, 7.3, 8.0 - _i * 0.9), "keep_y": True,
                   "facing": P(GANG_X, QH, 20.0), "action": "idle", "shown": only("abandon", "clock_406"),
                   "route": {"via": [P(GANG_X + _dx, 7.3, 8.6), P(GANG_X + _dx, QH + 0.1, QZ + 2.4), P(GANG_X - 4.0 + _dx * 3, QH, QZ + 16.0)],
                             "gait": "run", "speed": 5.0, "start": W("l12b", "abandon", 0.1 + _i * 0.25)},
                   "cues": [{"t": 0.0, "expression": "panic"}]})
# Dawn: a family walks out through the ruins with what they could carry.
for _i, (_ch, _x, _z) in enumerate([("toon_market_man", -30.6, 50.0), ("toon_market_woman", -29.2, 51.2),
                                     ("toon_market_kid", -30.0, 52.6), ("toon_market_elder", -32.0, 53.8)]):
    ACTORS.append({"id": f"family_{_i}", "character": _ch, "at": P(_x, QH, QZ + _z), "keep_y": True,
                   "facing": P(_x + 4.0, QH, QZ + 30.0), "action": "idle", "shown": only("families_walk", "helmets"),
                   "route": {"via": [P(_x + 3.0, QH, QZ + _z - 18.0)], "gait": "walk_carry", "speed": 0.75},
                   "cues": [{"t": 0.0, "expression": "sad"}]})

GAGS = [
    {"id": "dock_set", "script": "gags/dock.gd", "t": 0, "at": P(0, 0, 0),
     "params": dict(T, clock=CLOCK, bell={"actor": "dock_officer"},
                    megaphone={"actor": "chief", "from": W("l12b", "comes")},
                    nozzles=[{"actor": "hose_a", "aim": [30.5, 9.8, 0.5]}, {"actor": "hose_b", "aim": [32.0, 10.2, 0.0]},
                             {"actor": "hose_c", "aim": [33.5, 9.8, -0.5]}])},
    {"id": "dock_props", "script": "gags/dock_props.gd", "t": 0, "at": P(0, 0, 0),
     "params": {"loads": {"t": [W("l5b", "Torpedoes,"), W("l5b", "mines,"), W("l5b", "shells.")], "until": {"shot": "cotton_sling"}},
                "cotton": {"lift": W("l6", "bales"), "until": {"shot": "gold_crates"}},
                "gold": {"land": W("l7", "crates"), "glint": W("l7", "gold."), "until": {"shot": "xray_stack"}},
                "halyard": True,
                "binoculars": {"actor": "crevier_officer", "lower": W("l9c", "ship", -0.15)}}},
]

REVEALS = [
    {"id": "n_cotton", "t": W("l6", offset=0.05), "until": {"shot": "gold_crates"}, "at": P(36.0, 11.5, QZ + 6.0), "size": 1.0,
     "counter": {"from": 0, "to": 8700, "land": W("l6", "hundred", 0.1), "label": "BALES OF COTTON"}, "sound": "ding"},
    {"id": "n_gold", "t": W("l7", offset=0.05), "until": {"shot": "xray_stack"}, "at": P(30.0, 5.5, QZ + 4.4), "size": 0.4,
     "counter": {"from": 0, "to": 31, "land": W("l7", "thirty-one", 0.15), "label": "CRATES OF GOLD"}, "sound": "ding"},
    {"id": "n_water", "t": W("l11c", offset=0.05), "until": {"shot": "hold_steam"}, "at": P(32.0, 19.0, 4.0), "size": 1.6,
     "counter": {"from": 0, "to": 900, "land": W("l11c", "hundred", 0.1), "label": "TONS OF WATER"}, "sound": "ding"},
    {"id": "n_ships", "t": W("l19a", offset=0.05), "until": {"shot": "dock_fire"}, "at": P(20.0, 32.0, -30.0), "size": 6.0,
     "counter": {"from": 0, "to": 13, "land": W("l19a", "Thirteen", 0.2), "label": "SHIPS LOST"}, "sound": "ding"},
    {"id": "n_days", "t": W("l19b", offset=0.05), "until": {"shot": "dawn_ruins"}, "at": P(0.0, 120.0, 30.0), "size": 20.0,
     "counter": {"from": 0, "to": 3, "land": W("l19b", "three", 0.1), "label": "DAYS ON FIRE"}, "sound": "ding"},
    {"id": "n_dead", "t": W("l20a", offset=0.05), "until": {"shot": "families_walk"}, "at": P(0.0, 22.0, QZ + 40.0), "size": 4.5,
     "counter": {"from": 0, "to": 700, "suffix": "+", "land": W("l20a", "hundred", 0.1), "label": "LIVES LOST"}},
    {"id": "n_homes", "t": W("l20b", offset=0.05), "until": {"shot": "helmets"}, "at": P(-29.0, 8.0, QZ + 44.0), "size": 1.2,
     "counter": {"from": 0, "to": 80000, "land": W("l20b", "thousand", 0.1), "label": "LOST THEIR HOMES"}},
    {"id": "n_firemen", "t": W("l21a", offset=0.05), "until": {"shot": "fire_day"}, "at": P(28.0, 5.4, QZ + 9.0), "size": 1.0,
     "counter": {"from": 0, "to": 66, "land": W("l21a", "Sixty-six", 0.2), "label": "FIREMEN"}},
]

SHOTS = {
    # High over the basin from across the water: the whole dock at noon, the Stikine at the near quay among cranes and
    # crowds, the sheds and the city beyond in haze. A slow crane down toward her.
    "dock_wide": {"look": LOOK_NOON, "camera": move(
        cam(P(120, 46, -92), P(10, 10, 24), 24),
        cam(P(100, 30, -74), P(14, 9, 18), 24), "in_out")},
    # Along the quay at her bow: the hull rises over us, FORT STIKINE on the bow; a slow track toward the stem.
    "stikine_bow": {"look": LOOK_NOON, "camera": move(
        cam(P(40, 4.0, 19), P(62, 8.5, 6), 24),
        cam(P(52, 3.8, 17.5), P(64, 8.2, 6.5), 24), "in_out")},
    # From the deck at No. 2 hatch, looking up: the derricks swing down a torpedo, a mine, a pallet of shells.
    "crane_shells": {"look": LOOK_NOON, "camera": move(
        cam(P(26.4, 9.4, 5.6), P(31.6, 13.6, 0.0), 24),
        cam(P(26.8, 9.3, 5.2), P(31.6, 13.2, 0.0), 24), "out")},
    # Low on the quay among the bales: three men heave, the sling of bales rises toward the derrick.
    "cotton_sling": {"look": LOOK_NOON, "camera": move(
        cam(P(32.0, 4.2, QZ + 18.5), P(36.0, 5.6, QZ + 7.0), 26),
        cam(P(33.0, 4.0, QZ + 17.0), P(36.0, 6.6, QZ + 6.5), 26), "in_out")},
    # The gold comes ashore: sentries watch the crates land; the top lid slips and the bars catch the sun.
    "gold_crates": {"look": LOOK_NOON, "camera": move(
        cam(P(28.6, 4.3, QZ + 10.5), P(30.0, 3.7, QZ + 4.0), 30),
        cam(P(29.0, 4.0, QZ + 9.2), P(30.0, 3.7, QZ + 4.0), 32), "in_out")},
    # Up the foremast from the deck: the signal halyards hang empty; no red flag.
    "empty_mast": {"look": LOOK_NOON, "camera": move(
        cam(P(35.0, 9.0, 6.0), P(39.5, 13.0, 0.0), 22),
        cam(P(35.4, 9.0, 5.6), P(40.0, 23.0, 0.0), 22), "in_out")},
    # On the Fort Crevier's forecastle behind her officer: he lowers his binoculars; smoke curls from the Stikine's No. 2
    # hold beyond; the dock clock stands over it all at 12:30.
    "clock_1230": {"look": LOOK_NOON, "camera": move(
        cam(P(TOWER[0] - 4.0, 19.5, TOWER[2] - 16.0), P(TOWER[0], 23.0, TOWER[2] - 3.3), 40),
        cam(P(TOWER[0] - 3.0, 20.5, TOWER[2] - 13.0), P(TOWER[0], 23.2, TOWER[2] - 3.3), 42), "in_out")},
    # Along the quay: the whole length of her, moored fore and aft, cranes and crowds along the apron.
    "dock_moor": {"look": LOOK_NOON, "camera": move(
        cam(P(-36.0, 4.4, QZ + 7.5), P(20.0, 8.0, 2.0), 24),
        cam(P(-31.0, 4.8, QZ + 7.0), P(24.0, 8.5, 2.0), 24), "in_out")},
    # The officer on the Fort Crevier's forecastle, three-quarter front: he lowers his binoculars and stares.
    "officer_bino": {"look": LOOK_NOON, "camera": move(
        cam(P(113.2, 10.75, -1.4), P(116.0, 10.65, -5.0), 34),
        cam(P(113.5, 10.7, -1.8), P(116.0, 10.6, -5.0), 36), "in_out")},
    # His view: smoke curling out of the Stikine's No. 2 hold ventilators.
    "smoke_hold": {"look": LOOK_NOON, "camera": move(
        cam(P(104.0, 11.8, -9.0), P(32.0, 13.5, 0.0), 55),
        cam(P(103.0, 11.6, -8.6), P(32.0, 15.0, 0.0), 60), "in_out")},
    # At the dock office: the clock reads 13:45; below it the dock officer hauls on the fire bell.
    "clock_1345": {"look": LOOK_1345, "camera": move(
        cam(P(TOWER[0] - 6.0, 6.0, TOWER[2] - 17.0), P(TOWER[0], 21.0, TOWER[2] - 3.3), 24),
        cam(P(TOWER[0] - 6.5, 5.0, TOWER[2] - 15.0), P(TOWER[0] - 2.5, 4.6, TOWER[2] - 4.0), 24), "in_out")},
    # Low on the quay: the fire engines charge down at us.
    "engines_race": {"look": LOOK_1345, "shake": [{"t": W("l11a", "race"), "amount": 0.08}], "camera": move(
        cam(P(GANG_X + 3.0, QH + 0.9, QZ + 6.5), P(90.0, QH + 2.5, QZ + 9.5), 26),
        cam(P(GANG_X + 2.0, QH + 1.0, QZ + 6.0), P(70.0, QH + 2.2, QZ + 9.5), 26), "out")},
    # From the water on her far side: the fireboats surge in alongside under the smoke.
    "fireboats": {"look": LOOK_1345, "camera": move(
        cam(P(58.0, 2.4, -34.0), P(34.0, 6.0, -18.0), 26),
        cam(P(52.0, 2.2, -32.0), P(30.0, 6.5, -19.0), 26), "out")},
    # From the quay: three hoses and the fireboats' monitors arc water into the hold; the smoke thickens.
    "hoses_900": {"look": LOOK_1550, "camera": move(
        cam(P(31.0, 5.0, QZ + 12.5), P(31.5, 8.5, 0.0), 24),
        cam(P(31.2, 4.8, QZ + 11.0), P(31.5, 9.0, 0.0), 24), "in_out")},
    # On the quay: the fire officer raises the megaphone and bellows; firemen pour down the gangway; the hold is ablaze.
    "abandon": {"look": LOOK_1550, "camera": move(
        cam(P(19.0, 4.1, QZ + 10.5), P(22.4, 4.6, 4.0), 26),
        cam(P(19.3, 4.0, QZ + 9.8), P(22.4, 5.2, 4.0), 26), "in_out")},
    # The clock face alone, smoke drifting past: the minute hand clicks onto 4:06.
    "clock_406": {"look": LOOK_1606, "camera": move(
        cam(P(TOWER[0] - 1.0, 21.8, TOWER[2] - 12.0), P(TOWER[0], 23.4, TOWER[2] - 3.3), 55),
        cam(P(TOWER[0] - 0.8, 22.1, TOWER[2] - 10.5), P(TOWER[0], 23.4, TOWER[2] - 3.3), 55), "in_out")},
    # 4:06 p.m.: a beat of quiet from the quay: firemen still at the hoses, the black column standing over her.
    "calm_406": {"look": LOOK_1606, "camera": move(
        cam(P(-20.0, 4.6, QZ + 26.0), P(28.0, 16.0, 0.0), 24),
        cam(P(-17.0, 4.4, QZ + 24.0), P(28.0, 17.0, 0.0), 24), "in_out")},
    # The grand wide from across the basin: the flash, the fireball, the shockwave across the water, the column.
    "blast_wide": {"look": LOOK_1606, "shake": [{"t": W("l14c", "explodes", 0.25), "amount": 0.55}], "camera": move(
        cam(P(190, 30, -210), P(25, 45, 0), 24),
        cam(P(178, 27, -196), P(25, 60, 0), 24), "in_out")},
    # Closer, into the fire: the hull is torn in two.
    "hull_split": {"look": LOOK_1606, "shake": [{"t": W("l14b", "torn"), "amount": 0.2}], "camera": move(
        cam(P(110, 14, -95), P(10, 14, 0), 26),
        cam(P(104, 12, -88), P(10, 12, 0), 26), "in_out")},
    # From the water astern: the surge heaves the Jalapadma up out of the basin.
    "jala_lift": {"look": LOOK_1606, "camera": move(
        cam(P(-120.0, 2.0, -50.0), P(-165.0, 8.0, 0.0), 26),
        cam(P(-124.0, 2.4, -46.0), P(-163.0, 12.0, 6.0), 26), "in_out")},
    # On the quay astern: the surge lifts the Jalapadma out of the water and slams her onto the dock, crushing a crane.
    "jalapadma": {"look": LOOK_1606, "shake": [{"t": W("l15b", "dock.", 0.05), "amount": 0.4}], "camera": move(
        cam(P(-250.0, 7.0, QZ + 26.0), P(-160.0, 9.0, QZ + 8.0), 24),
        cam(P(-246.0, 6.6, QZ + 26.0), P(-160.0, 8.0, QZ + 10.0), 24), "in_out")},
    # From behind the sheds: the second explosion doubles the column.
    "second_blast": {"look": LOOK_1606, "shake": [{"t": W("l18", "second", 0.25), "amount": 0.35}], "camera": move(
        cam(P(60, 55, 260), P(0, 70, 0), 26),
        cam(P(56, 50, 248), P(0, 78, 0), 26), "in_out")},
    # Night, low on the water: the masts of sunken ships against the burning docks.
    "night_masts": {"look": LOOK_NIGHT, "camera": move(
        cam(P(75, 3.0, -112), P(-5, 16, 30), 24),
        cam(P(70, 2.6, -108), P(-5, 17, 30), 24), "in_out")},
    # The inferno from above: the whole dock district burning into the night.
    "dock_fire": {"look": LOOK_NIGHT, "camera": move(
        cam(P(190, 120, -260), P(0, 10, 40), 24),
        cam(P(176, 108, -240), P(0, 14, 40), 24), "in_out")},
    # Dawn: smoke over the flattened sheds and the wreck.
    "dawn_ruins": {"look": LOOK_DAWN, "camera": move(
        cam(P(-50, 14, QZ + 96), P(10, 4, QZ + 30), 24),
        cam(P(-46, 12, QZ + 88), P(10, 5, QZ + 30), 24), "in_out")},
    # A family walks out through the ruins with what they could carry.
    "families_walk": {"look": LOOK_DAWN, "camera": move(
        cam(P(-24.0, QH + 1.6, QZ + 24.0), P(-30.0, QH + 2.6, QZ + 52.0), 30),
        cam(P(-24.3, QH + 1.5, QZ + 25.5), P(-30.0, QH + 2.6, QZ + 52.0), 30), "in_out")},
    # The 66 brass helmets in rows on the quay at dawn; a slow crane up over them.
    "helmets": {"look": LOOK_DAWN, "camera": move(
        cam(P(28.0, QH + 0.6, QZ + 2.4), P(28.0, QH + 0.3, QZ + 9.5), 28),
        cam(P(28.0, QH + 8.0, QZ + 0.5), P(28.0, QH, QZ + 9.0), 28), "in_out")},
}

PLACE = {"gags": GAGS, "actors": ACTORS, "reveals": REVEALS, "shots": SHOTS}
