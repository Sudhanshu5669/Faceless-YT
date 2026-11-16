# Toon characters

The channel's house style ("meme stick figures", see `.claude/skills/toon-short/SKILL.md`):
a big white sphere head with a flat drawn face, a helmet of hair, a bean-shaped torso that **is**
the outfit, thin black stick limbs, ball hands, round shoes, and a dark outline on everything.

Proportions (measured on the reference): head ≈ 38 % of the height, torso ≈ 32 %, legs ≈ 28 %.

## How it works

- `godot/scripts/actors/toon.gd` builds the parts from primitive meshes and hangs them on a
  **short-legged copy of the mannequin skeleton** (`toon_skeleton`: hips dropped, shins and
  thighs shortened, every rest rotation kept).
- The actor retargets the mannequin's pose onto that copy (rig `toon` in `library/rigs.json`),
  so **every action in `library/actions.json` plays on a toon** (walk, idle, talk, phone, nod,
  dance, sit, jump, punch, …). Walk speed is scaled to the shorter legs, so feet stay planted.
- The face is a shader (`godot/shaders/toon_face.gdshader`) that draws brows, eyes, mouth and
  extras from signed distance fields. An expression is only a set of uniforms, so a **face swap is
  instant**, and in this style the face swaps are most of the acting.
- Outline: inverted hull (`toon_outline.gdshader`). Hair: `toon_hair.gdshader` (painted strands).

## Character JSON

```json
{
  "id": "toon_you", "description": "...", "tags": ["toon", "human"],
  "height": 1.4, "idle": "idle", "gait": "walk",
  "toon": {
    "skin": "#f4f4f2",
    "hair": {"style": "tuft", "color": "#6b3d1e"},
    "outfit": {"style": "hoodie", "color": "#2f7be0"},
    "shoes": "#f2f2f2",
    "accessories": ["smart_glasses"],
    "face": "smug",
    "girth": 1.0
  }
}
```

| Key | Values |
|---|---|
| `skin` | Head colour. White is the norm; green (`#7ed957`) is the "evil true face" gag. |
| `hair.style` | `bowl`, `tuft` (bowl + spike on top), `slick` (combed back), `curly` (ball curls), `cap` (baseball cap), `beanie`, `bob`, `bun`, `bald`, `hardhat` (site helmet: ribbed dome, brim, front peak; `color` is the shell; `"lamp": true` adds a strapped headlamp whose lens is the node `lamp_lens` with its own emissive material, so a gag can switch one worker's lamp). |
| `outfit.style` | `hoodie` (drawstrings, pocket, hood), `suit` (+ `"chain": true` gold chain, `"tie": "#hex"`), `tee`, `labcoat` (+ `tie`), `dress`, `shirt`, `hivis` (safety vest in `color` with reflective tape round the waist and over the shoulders, a zip, trousers in `accent`; the tape glows faintly so it reads in a dark set). `accent` recolours drawstrings. |
| `accessories` | `glasses`, `round_glasses`, `sunglasses`, `smart_glasses` (thick frame + LED). |
| `face` | Default expression (a key of `library/toon/faces.json`). |
| `girth` | Torso width, 0.7..1.5. |

A toon takes no `model` or `colors`. Ready-made cast: `toon_you` (everyman, blue hoodie),
`toon_boss` (billionaire: suit, gold chain, curls), `toon_boss_evil` (same, green skin),
`toon_agent`, `toon_partner`, `toon_founder`, `toon_scientist`, `toon_scientist_b`,
`toon_redhead`, `toon_nerd`. Site crew (hard hat + hi-vis): `toon_tunnel_worker`, `_lime`, `_blue`,
`_red`, `toon_tunnel_engineer` (white helmet, glasses), `toon_tunnel_digger` (pickaxe in hand).
Run `python pipeline/tf.py library` to list them.

## Expressions

An actor cue swaps the face: `{"t": {"line": "n3", "word": "billion"}, "expression": "star_eyes"}`.
It can stand alone or ride on a cue with an `action`. Presets (`library/toon/faces.json`):

`neutral`, `smug`, `deadpan`, `side_eye`, `scheming`, `wink`, `happy`, `laugh`, `grin`, `cheer`,
`star_eyes`, `love`, `shocked`, `panic` (sweat drop), `surprised`, `nervous`, `angry`, `furious`,
`sad`, `crying` (tears), `dead` (X_X), `sleepy`, `thinking`, `determined`, `cool`.

A preset sets: `eyes` (`lazy`, `dot`, `wide`, `happy`, `closed`, `x`, `star`, `heart`, `sleepy`,
`none`, or `[left, right]` for a wink), `look` [x, y], `eye_size`, `eye_y`, `lid`, `lid_tilt`,
`brows`, `brow_tilt` (+ worried, − angry), `brow_y`, `mouth` (`smirk`, `smile`, `flat`, `frown`,
`open`, `grin`, `laugh`, `wavy`, `o`, `none`), `mouth_x`, `mouth_w`, `sweat`, `blush`, `tears`.
New presets are fine; keep the description one line.

## Anchors

Toon actors have the usual anchors (`<id>`, `.head`, `.eyes`, `.chest`, `.hand`), adjusted for
the big head: `.head` is the head's centre, `.eyes` sits just in front of the face.
