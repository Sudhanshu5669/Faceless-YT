# Actors

Actors are characters placed in a set, doing an action, optionally moving along a route.
They live in a spec's `"actors"` list. Every actor is posed by a **pure function of time**:
the same `t` always gives the same position, facing and skeleton pose. Stills (`"t"` on a
shot), the explore window and later video renders all use it.

```json
"actors": [
  { "id": "you", "character": "you", "at": "house_9.front_door", "action": "phone" },
  { "id": "walker", "character": "neighbor_a", "at": { "anchor": "house_9.curb", "offset": [-5, 0, 0.6] },
    "facing": 90, "action": "walk", "freeze": 0.3 },
  { "id": "stranger", "character": "stranger", "at": { "anchor": "house_9.curb", "offset": [-24, 0, 1.5] },
    "facing": "you", "action": "idle_formal" },
  { "id": "horde", "character": "zombie", "at": "main_street_east",
    "crowd": { "count": 14, "radius": 6, "characters": ["zombie", "zombie_f"], "start_spread": 3 },
    "route": { "via": ["main_street_mid"], "gait": "zombie_walk" } }
]
```

`python pipeline/tf.py library` lists all characters and actions.

## Actor fields

| Field | Meaning |
|---|---|
| `id` | Unique name. It also becomes an anchor (see below). No `.` or `:`. |
| `character` | A file in `library/characters/`. |
| `at` | Where the actor stands at the start. Same point forms as cameras: `"house_4.front_door"`, `{"anchor", "offset": [right, up, forward]}`, `{"anchor", "orbit": {...}}`, `{"world": [x,y,z]}`. Feet snap to the surface (road, sidewalk, lawn, path). |
| `facing` | Default: the anchor's forward direction (at a front door, toward the street). Or degrees (`90` = +X), `"back"`, any point, or another actor's id (`"you"`): that **tracks the actor every frame** as they move. |
| `action` | What they do while standing (default: the character's `idle`). See actions below. |
| `freeze` | 0–1: hold the action at that fraction of its cycle, or a named mark of the action (`"apex"` for `jump`). Everyone frozen mid-stride, mid-jump. |
| `phase` | Seconds of animation offset (default: derived from the id, so crowds don't move in sync). |
| `route` | Movement, below. |
| `crowd` | Turns this entry into many actors, below. |
| `cues` | Timed changes: new action, new facing, hold/release. Below. |
| `shown` | `[[t0, t1], ...]` (time references): the actor exists only in these windows (absent: always). For the same place years apart: the 1995 team at the shaft is gone by 1998. |
| `keep_y` | `true`: the feet stay at the point's own height instead of snapping to the set's ground (tiers, galleries, a ship's deck built by a gag). |

### Routes

| Field | Meaning |
|---|---|
| `via` | Points to walk through, in order (from `at`). Straight lines; corners are smoothed. Pick waypoints that follow sidewalks and roads. |
| `gait` | A moving action: `walk`, `walk_formal`, `walk_carry`, `jog`, `run`, `sneak`, `zombie_walk`, `swim_forward`. Default: the character's `gait`. |
| `arrive` | Instead of `speed`: the scene time to reach the end (often a word: `{"line": "n6", "word": "grab"}`); speed follows from the distance. |
| `speed` | m/s. Default: the gait's measured natural speed (walk 0.92, jog 5.6, run 8.3, zombie_walk 0.66). Feet never slide: animation phase follows distance travelled, so other speeds just change cadence. |
| `start` | Seconds before they set off (they do `action` until then). |
| `then` | Action after arriving (default: the character's idle). |
| `then_facing`, `then_freeze` | Facing and freeze after arriving. |

### Crowds

`"crowd": {"count": 14, "radius": 6, "characters": ["zombie", "zombie_f"], "start_spread": 3, "seed": 0}`

This expands into `<id>_0` … `<id>_13`, scattered within `radius` metres of `at` (at least 0.9 m
apart). Each member gets a random character from the list and keeps its offset along the whole
route. Members start up to `start_spread` seconds apart, move at ±15 % speed, and have different
animation phases. The result is deterministic for a given id and seed.

`"area": [width, depth]` instead of `radius` scatters them in a rectangle in the `at` anchor's
frame (right × forward), e.g. a line pressed against a shop window:
`"at": {"anchor": "storefront", "offset": [4, 0, -0.55]}, "crowd": {"count": 11, "area": [20, 0.3], "spacing": 1.2}`.
`spacing` is the minimum distance between members (default 0.9 m).
`"shape": "india"` (with `radius` = half the north-south length) fills the map outline of India
instead: north is the anchor's back. 110 toons at radius 8, spacing 0.8 = "a nation", shot from above.

## Actors as anchors

At each moment, every actor provides anchors that cameras (and other actors) can target:

| Anchor | Where |
|---|---|
| `you` | Feet. Forward = the way they face. |
| `you.head` | Top of the head (follows the animation: crouching, sitting, falling). |
| `you.eyes` | Just in front of the face. **Put POV cameras here**, not at `.head` (that is inside the head). |
| `you.chest`, `you.hand` | Chest; right hand. |

```json
{ "name": "pov", "t": 2, "at": "you.eyes", "look_at": "stranger.head", "lens_mm": 60 }
{ "name": "horde", "t": 12, "template": "low_hero", "subject": "horde_0" }
```

A shot's `"t"` is the moment the still is taken. When a tree or house blocks the line from the
camera to the subject, the render log prints `WARN shot <name>: subject hidden behind ...`.
Move the actor or the camera.

## Characters

`library/characters/<id>.json`:

```json
{ "id": "stranger", "description": "Impossibly tall, thin, pitch black, joints glowing red.",
  "tags": ["monster", "uncanny"], "body": "male", "colors": { "body": "#0c0c0e", "joints": "#ff2a2a" },
  "glow": 4.0, "height": 2.3, "width": 0.82, "idle": "idle_formal", "gait": "walk_formal",
  "props": [ { "model": "quaternius_fantasy_props/Lantern_Wall", "bone": "hand_r", "size": 0.35,
               "offset": [0, -0.12, 0.05], "rotation": [0, 0, 0] } ] }
```

- `body`: `male` or `female` (faceless Quaternius mannequins with one shared skeleton and 86 animations).
- `model` (optional): a character model from the catalog, e.g. `quaternius_modular_men/Suit`. The
  mannequin stays as the hidden animation source and its pose is **retargeted** onto the model every
  frame (`scripts/actors/retarget.gd`, bone maps in `library/rigs.json`), so every action works on it.
  The model is scaled so its head bone matches the mannequin's; `height` then scales both.
- `colors`: for a mannequin, `body` and `joints` (`glow` makes the joints emit light). For a model,
  material names → hex (`{"Suit": "#1f2d4a", "Tie": "#8a1f2a", "Skin": "#8d5a3b", "Hair": "#111111"}`);
  unknown names are errors listing the model's materials.
- `height` (m), `width` (×, for build): `height` 1.25 is a child, 2.3 is unnaturally tall.
- `props`: catalog models attached to a bone (`hand_r`, `hand_l`, `Head`, `spine_03`…). `size` = largest dimension in metres.

Current cast: `you`, `you_f`, `neighbor_a`, `neighbor_b`, `kid`, `zombie`, `zombie_f`, `stranger`,
`mannequin`, `night_watch` (mannequins), and the city people `city_*` (16 retargeted Quaternius
modular characters: suits, hoodies, jackets, summer clothes, workers, punks, a dress; varied skin,
hair and clothing colours and heights). Add more freely. A new character is one JSON file.

**City outfits** (`quaternius_modular_men/…`: `Casual`, `Casual2`, `Beach`, `Suit`, `Worker`, `Punk`,
`Farmer`, plus `Adventurer`, `King`, `Spacesuit`, `Swat`; `quaternius_modular_women/…`: `Casual`,
`Formal`, `Suit`, `Worker`, `Punk`, `Adventurer`, plus `Medieval`, `SciFi`, `Soldier`, `Witch`).
List a model's materials with
`godot --headless --path godot --script res://tools/skeleton_probe.gd -- res://assets/<pack>/<Name>.fbx`.

## Actions

`library/actions.json` maps action names to animations. Standing actions include `idle`,
`fold_arms`, `talk`, `phone`, `call_out`, `shake_head`, `nod`, `lantern`, `torch`, `crouch`, `sit`,
`sit_talk`, `dance`, `interact`, `pick_up`, `open_chest`, `push`, `fix`, `drive`, `eat`, `chop`,
`punch`, `hit`, `knocked_back`, `die`, `get_up`, `jump`, `climb`, `pistol_aim`, `sword_idle`,
`spell`, `tpose`, `zombie_idle` and `zombie_scratch`. One-shots (`die`, `sit_down`,
`knocked_back`…) hold their last frame. `get_up` frozen at 0 = lying on the ground.

### Sequences, lift and marks

An action is either one clip (`"anim"`) or a `"sequence"` of clip segments played back to back:

```json
"jump": {
  "sequence": [
    { "anim": "Jump_Land", "from": 0.76, "to": 0.19, "duration": 0.3 },
    { "anim": "Jump_Start", "from": 0.0, "to": 0.08, "duration": 0.1, "blend": 0.06 },
    ...
  ],
  "lift": { "from": 0.4, "to": 1.0, "height": 0.45 },
  "marks": { "crouch": 0.3, "takeoff": 0.4, "apex": 0.7, "touchdown": 1.0, "landed": 1.2 },
  "loop": false
}
```

- A segment plays clip time `from` → `to` (backwards when `to < from`) over `duration` seconds
  (default `|to - from|`). `blend` crossfades from the previous segment's last pose.
- `lift` raises the body on a ballistic arc between two sequence times. The Universal Animation
  Library authors airborne clips **in place** (the pelvis never rises; a game engine moves the
  character), so without `lift` a jump looks like a crouched stagger on the ground. Lift scales
  with character height, and camera anchors (`kid.head`) follow it.
- `marks` name moments in sequence seconds. A spec writes `"freeze": "apex"` instead of guessing
  a fraction. Unknown marks are errors.

`jump` is built this way: wind-up crouch → push-off → airborne (tuck) → reach for the ground →
landing. Other clips that need the world to cooperate: `climb` ends 0.6 m up (needs a 1 m ledge),
`swim`/`swim_forward` sit below the surface (need water).

Gait speeds are measured from the animations by `godot/tools/locomotion_probe.gd` (foot contact
during stance). Re-run it after adding gaits.

### Cues and holds

```json
"cues": [
  { "t": 12.4, "action": "jump" },             // start an action (one-shots play from their start)
  { "t": 13.1, "hold": true },                 // freeze completely: pose, position, route progress
  { "t": 20.0, "hold": false },                // release: carries on exactly where it stopped
  { "t": 21.0, "facing": "stranger" },          // turn (0.6 s, or "turn": seconds), keep the action; tracks a moving actor
  { "t": 29.6, "action": "hit", "freeze": 0.5 }
]
```

- `t` is scene seconds (the episode timeline, see TIMELINE_SPEC.md), in order.
- A cue has `action` (optionally with `freeze`), `facing` and/or `expression` (toon characters:
  swaps the face, see TOON_SPEC.md); a hold cue has only `t` and `hold`.
- A hold stops the actor's own clock. Everything after it (route start, later cues) happens
  that much later in the actor's own clock. "Everyone freezes at 3:33" = a hold cue on
  everyone except you.
- Turns are smooth (`turn` seconds, default 0.6; `0` snaps), and so is the turn on arriving at
  the end of a route. A held actor keeps the facing it had when the hold began.
- A cue's `head` offset is `[pitch, yaw, roll]` in degrees relative to the actor. `head_turn`
  sets how many seconds it takes to ease to that offset (default 0.6). Use `[0, 0, 0]` to return
  to the underlying animation pose.
- While walking a route, the route wins. Otherwise the most recent of "arrived" and each cue
  decides the action.

## Not yet

- Blending between actions (switches are instant).
- Pathfinding around obstacles (routes are straight lines between waypoints).
- Lip sync and facial expression (the mannequins are faceless by design; narration is second person).
- Kenney characters (different skeleton; needs animation retargeting).
