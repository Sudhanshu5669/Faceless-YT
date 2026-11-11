# Gags: custom scripted set pieces

The vocabulary (sets, actors, cues, reveals, cameras) covers a lot, but the best ideas are
specific: Zuckerberg hauling a nuclear power plant on a cord, a cash cannon that buries a man in
money, a photocopier that clones a rival. **When an idea needs something the vocabulary lacks, the
director writes a gag**: a small GDScript file that builds the thing and animates it from time.
This is how the model making a video invents and implements its own effects for that video.

## In the episode

```json
"gags": [
  { "id": "cannon", "script": "gags/cash_cannon.gd",
    "t": {"line": "n8d"}, "until": {"line": "n9a"},
    "at": {"anchor": "office", "offset": [-0.25, 0, 2.5]}, "face": "rep",
    "params": {"roll_in": {"line": "n8d", "word": "you"},
               "shots": {"from": {"line": "n8d", "word": "buy"}, "until": {"line": "n8d", "word": "percent"}, "every": 0.14}} },
  { "id": "cash", "script": "library:cash_stream", "t": {"line": "n8d"},
    "at": {"anchor": "office", "offset": [0, 0, -1.0]},
    "params": {"from": "cannon.muzzle", "fire": {"line": "n8d", "word": "buy"}, "count": 360} }
]
```

| Key | Meaning |
|---|---|
| `id` | Unique, no dots. Also an anchor (where the gag stands), plus `<id>.<name>` for the anchors the script returns. |
| `script` | `gags/<file>.gd` relative to the episode folder, or `library:<name>` for `library/gags/<name>.gd`. |
| `t`, `until` | Shown from / until (word references like everywhere else). |
| `at`, `face` | Where it stands and what it faces (any point: anchor, `{anchor, offset}`, actor anchor, reveal or another gag's anchor). |
| `params` | Free-form, for the script. Time references inside (`{"line", "word"}`) are resolved to scene seconds. |

Order matters: a gag can use the anchors of gags listed before it (`cash` fires from `cannon.muzzle`).

## Writing a gag script

```gdscript
extends RefCounted
const Toon = preload("res://scripts/actors/toon.gd")   # engine helpers are available

func validate(g: Dictionary) -> Array:      # optional: param errors (the episode won't render)
    return []

func build(g: Dictionary) -> Node3D:        # once: make the nodes (meshes, materials)
    ...

func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
    # every frame, in ANY order (renders seek): set everything from t alone
    var p := g.get("params", {})
    var target: Dictionary = ctx["point"].call("rep.chest")   # resolve any point now
    ...
    return {"muzzle": some_world_position}   # becomes the anchor "<id>.muzzle"
```

Rules (the same as the rest of the engine):

- **Pure function of time.** No state carried between frames, no `randf()`. For randomness, seed a
  `RandomNumberGenerator` from `g["id"]` (+ an index): the same frame always looks the same.
- **Toon look.** Use `Toon.material(color, Toon.OUTLINE * 0.7)` (outline + sheen), `Toon.sphere`,
  rounded shapes, bright saturated colours, and an emissive accent where light should pop.
- **Cheap.** Hundreds of copies: one `MultiMesh` (see `library/gags/cash_stream.gd`). Reuse meshes.
- **Readable in 9:16.** Keep the action on the vertical axis; return anchors the camera can follow.
- `ctx`: `point` (Callable, resolves a point at this moment), `age` (t - g.t), `holder` (the node
  placed at `at`; the content is its child "content").

## The library

`library/gags/` holds gags worth reusing (with a header comment: what it does, params, anchors).
When an episode's gag turns out generic, move it there and reference it as `library:<name>`.

| Gag | What it does |
|---|---|
| `cash_stream` | Bills fly in arcs from a source and pile up into a growing heap (cash cannons, money rain, burying someone). Anchors: `top`, `landing`. |

Example of an episode gag: `episodes/jio_story/gags/cash_cannon.gd` (rolls in, recoils and flashes
on each shot; anchors `muzzle`, `breech`).
