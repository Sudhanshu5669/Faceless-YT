# Reveals and counters

The style's core rule: **everything the narrator names appears on screen on that word.** A reveal
is something that appears in the world at a time (usually a word reference) and optionally leaves:
a catalog prop, a primitive shape, 3D text or a counter.

`reveals` lives in the episode (or in a set spec, for preview stills). Times are references like
everywhere else (AUDIO_SPEC.md): `{"line": "n3", "word": "Instagram"}`, `{"shot": "s4", "at": 0.5}`
or scene seconds.

```json
"reveals": [
  { "id": "ig", "t": {"line": "n5", "word": "Instagram"}, "shape": "bottle", "color": "#e1306c",
    "at": {"anchor": "robot.head", "offset": [0.3, 0.5, 0.3]}, "size": 0.45, "enter": "drop", "sound": "pop" },
  { "id": "users", "t": {"line": "n2", "word": "Every"}, "until": {"line": "n3", "edge": "end"},
    "at": {"anchor": "stage", "offset": [0, 2.2, 0]}, "size": 0.7,
    "counter": { "from": 0.5, "to": 3.5, "decimals": 1, "suffix": " BILLION",
                 "land": {"line": "n2", "word": "billion"}, "label": "PEOPLE OPEN THEIR APPS" },
    "sound": "ding" },
  { "id": "half", "t": {"line": "n3", "word": "half"}, "text": "HALF OF HUMANITY", "color": "#5fe3ff",
    "at": {"anchor": "stage", "offset": [0, 0.1, 1.0]}, "size": 0.3, "enter": "rise" }
]
```

| Key | Meaning |
|---|---|
| `id` | Unique; also the node name and an **anchor** for cameras (`"look_at": "users"`). |
| `t`, `until` | Appear at / leave at (time references). No `until` = stays. |
| one of `prop` / `shape` / `text` / `counter` | What appears (below). |
| `at` | Any point: anchor name, `{"anchor", "offset"}`, or an actor anchor such as `"you.hand"`. Re-resolved every frame, so it **follows actors**. |
| `size` | Metres (largest dimension; cap height for text). Default 0.5. |
| `color` | Shape tint or text colour. |
| `yaw` / `face` | Turn (degrees) or face a point. Text and counters always face the camera. |
| `enter` | `pop` (overshoot scale, default), `drop` (falls and bounces), `rise`, `slide_left`, `slide_right`, `beam` (light column, then pop), `grow`, `none`. |
| `enter_time` | Seconds (default 0.35; beam 0.5). |
| `exit` / `exit_time` | `shrink` (default), `pop`, `drop`, `rise`, `none`; default 0.25 s. |
| `spin`, `bob` | Idle motion: degrees per second; bob height in metres. |
| `glow` | Emission strength (shapes; text defaults to 0.8). |
| `sound` | A one-shot placed at `t` (`pop`, `ding`, `cash`, `whoosh`, `tick`, `thud`, `click`, …). |

**Shapes** (toon materials with outlines): `box`, `sphere`, `cylinder`, `cone`, `ring`, `coin`,
`card` (white panel + coloured header), `cash` (bill stack), `bottle`, `pin` (map pin), `chip`,
`phone` (lit screen). **Props**: any catalog id (`library/catalog.json`).

**Story shapes:** `refinery`, `pump`, `postcard`, `scales`, `frame`, `garland`, `cake`, `cake_half`,
`binoculars`, `sign`, `spinner`, `tower`, `rickshaw`, `plaque`, and `india` (the official map outline,
lying flat, north toward -z; `size` = its north-south length; pins go at the same projection:
`x = (lon - 82.5) * size / 29`, `z = -(lat - 22.5) * size / 29`), `crown`, `moneybag`, `vitrine`
(museum case with a velvet rope), `laptop` (lit screen toward +z), `tank` (oxygen cylinder), `receipt`,
`podium` (1 in the middle, 2 screen-left, 3 screen-right; block tops at 0.5, 0.34, 0.24 x size).
`label` prints text on `card sign cake cake_half pump postcard box plaque moneybag tank receipt`.

**Moves** (after the entrance): `"moves": [{"t": time, "by": [x, y, z], "dur": 0.6, "turn": deg, "tip": deg}]`.
`by` slides (world metres), `turn` yaws, `tip` knocks the thing over sideways about its base with a
small bounce (+ falls toward screen left when it faces the camera): falling towers, dominoes, a sign
that topples when a deal ends.

## Counters

```json
"counter": { "from": 0, "to": 7000000, "land": {"line": "n9", "word": "million"},
             "prefix": "", "suffix": "", "decimals": 0, "commas": true, "group": "western",
             "label": "GLASSES SOLD", "land_color": "#ffd84a" }
```

The number eases from `from` (at the reveal's `t`) to `to` at `land`, then turns `land_color`
(yellow) with a small pop. **Land it exactly on the word that says the number.** For a stepped
count ("0.5 → 1.2 → 2.1 → 3.5") give `"keys": [[time, value], ...]` instead of from/to/land.
Add `{"sound": "tick", "at": ..., "repeat": 8, "every": 0.12}` in `sfx` for a ticking run-up and
`"sound": "ding"` on the reveal (or an sfx at `land`) for the landing.
`"group": "indian"` writes lakhs and crores the Indian way (3,00,000 and 1,50,000 instead of 300,000).

## Font

Text and counters use **Lilita One** (SIL Open Font License, commercial use allowed),
`godot/fonts/lilita_one/` with its `OFL.txt`, loaded straight from the .ttf.

## Validation

Unknown keys, shapes, entrances, missing `at`, duplicate ids, `until` before `t` and bad counters
are errors. Anchors are checked when the set is built.
