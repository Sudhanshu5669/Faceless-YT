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
| `facing` | Default: the anchor's forward direction (at a front door, toward the street). Or degrees (`90` = +X), `"back"`, another actor's id (`"you"`), or any point. |
| `action` | What they do while standing (default: the character's `idle`). See actions below. |
| `freeze` | 0–1: hold the action at that fraction of its cycle. Everyone frozen mid-stride, mid-jump. |
| `phase` | Seconds of animation offset (default: derived from the id, so crowds don't move in sync). |
| `route` | Movement, below. |
| `crowd` | Turns this entry into many actors, below. |

### Routes

| Field | Meaning |
|---|---|
| `via` | Points to walk through, in order (from `at`). Straight lines; corners are smoothed. Pick waypoints that follow sidewalks and roads. |
| `gait` | A moving action: `walk`, `walk_formal`, `walk_carry`, `jog`, `run`, `sneak`, `zombie_walk`, `swim_forward`. Default: the character's `gait`. |
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
- `colors.body`, `colors.joints`: the mannequin's two materials. `glow` makes the joints emit light.
- `height` (m), `width` (×, for build): `height` 1.25 is a child, 2.3 is unnaturally tall.
- `props`: catalog models attached to a bone (`hand_r`, `hand_l`, `Head`, `spine_03`…). `size` = largest dimension in metres.

Current cast: `you`, `you_f`, `neighbor_a`, `neighbor_b`, `kid`, `zombie`, `zombie_f`, `stranger`,
`mannequin`, `night_watch`. Add more freely. A new character is one JSON file.

## Actions

`library/actions.json` maps action names to animations. Standing actions include `idle`,
`fold_arms`, `talk`, `phone`, `call_out`, `shake_head`, `nod`, `lantern`, `torch`, `crouch`, `sit`,
`sit_talk`, `dance`, `interact`, `pick_up`, `open_chest`, `push`, `fix`, `drive`, `eat`, `chop`,
`punch`, `hit`, `knocked_back`, `die`, `get_up`, `jump`, `climb`, `pistol_aim`, `sword_idle`,
`spell`, `tpose`, `zombie_idle` and `zombie_scratch`. One-shots (`die`, `sit_down`,
`knocked_back`…) hold their last frame. `get_up` frozen at 0 = lying on the ground.

Gait speeds are measured from the animations by `godot/tools/locomotion_probe.gd` (foot contact
during stance). Re-run it after adding gaits.

## Not yet

- Blending between actions (switches are instant).
- Pathfinding around obstacles (routes are straight lines between waypoints).
- Lip sync and facial expression (the mannequins are faceless by design; narration is second person).
- Kenney characters (different skeleton; needs animation retargeting).
