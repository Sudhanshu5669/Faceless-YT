# Asset pipeline

```
incoming/*.zip ──extract──► godot/assets/<pack>/ ──Godot import──► catalog.json + thumbnails ──curate──► library/kits/*.json
   (downloads)    (asset_packs.json)        (.godot/imported)       (tools/catalog.gd)                (hand-written roles)
```

```bash
python pipeline/tf.py assets import            # everything: extract, import, catalog (≈3 min)
python pipeline/tf.py assets catalog [--pack ID]
python pipeline/tf.py library                  # kits + catalog summary
```

`godot/assets/` and `library/thumbs/` are git-ignored: they rebuild from `incoming/`.
`library/catalog.json` and `library/kits/` are tracked.

## Adding a pack

1. Download it into `incoming/`. **Check that the license is CC0** (or another license that allows
   commercial video use) before importing.
2. Add an entry to `pipeline/asset_packs.json`: which zip, which folders and patterns, and where they
   go. Prefer glTF/GLB, then FBX. `.blend` needs Blender and is skipped.
3. `tf assets import`, then **look at** `library/thumbs/_sheets/<pack>_N.png`.
4. Add the category heuristics for the pack in `tools/catalog.gd` (`_category`) if the defaults
   are wrong.
5. Put the models into a kit (or a new kit) by role.

## Fab packs

Fab (fab.com) downloads are fine when the listing's licence is **Fab Standard** or **CC BY 4.0**, the
item is free under that licence (not a "From free" personal tier), and it ships **glTF/GLB/FBX/OBJ**
(not UE-only). Fab zips have no licence file, so each one in `incoming/` gets a `LICENSE.txt` added
(title, author, listing URL, licence, credit line). CC-BY packs carry a `"credit"` in
`asset_packs.json`; **put those credit lines in the video description** of any episode that shows them.
Bare `.glb` downloads are wrapped in a zip with their licence. Downloads go through the user's browser:
Claude triggers the download, the user saves it to `incoming/`, Claude renames it `fab_<what>_<author>.zip`.

`"split_roots": true` on a pack: the file holds several props as root nodes (e.g. the 12 store
fixtures in one glTF). Each root becomes its own model, `<pack>/<file>#<node>`, with its own size and
thumbnail; `KitDB.instance` / `parts` load only that node.

## Catalog (generated)

`library/catalog.json` has one entry per model:

| Field | Meaning |
|---|---|
| `id` | `<pack>/<name>`. Kits and specs use this. |
| `path` | `res://` path of the source file. |
| `category`, `tags` | Heuristic: house, tree, bush, rock, vehicle, prop, building_part, street, character… |
| `size`, `min` | Measured bounding box in the model's own units. **Packs use different units**: Kenney ≈ 1 unit = 8 m (houses) / toy-scale cars, Quaternius nature ≈ ⅓ scale, Quaternius UAL and Downtown are metres. Kits normalise this. |
| `tris`, `rigged`, `animations` | Triangle count; whether it has a skeleton; animation names (UAL has 86, incl. `Zombie_Walk_Fwd_Loop`, `Idle_TalkingPhone_Loop`, `Sitting_Idle_Loop`, `Death01`). |
| `thumb` | `library/thumbs/<pack>/<name>.png`, rendered from front-right-above. Model front is +Z. |

## Kits (curated)

A kit maps roles to catalog models and says how to fit them. `library/kits/suburban.json`:

- `house.models`: 21 Kenney houses. The generator picks one per lot and takes footprint and
  height from the model's measured size (scaled to `target_width`), so rects, anchors and
  driveways match what is drawn.
- `house.atlas`: Kenney models sample one palette texture. The swatches for `roof`, `walls` and
  `windows` were found by measuring triangle area per swatch (`tools/swatch_probe.gd`). Each house
  gets its own roof colour (`roof_colors`, or the look's `palette.roof`), wall colour (the generator's
  siding, through `palette.siding`), white roofs under snow, and glowing or dark windows at night.
- `tree.seasons` / `bush.seasons`: models per season (`summer`, `autumn`, `winter`, `dead`,
  `dead_winter`) and per tree variant (`round`, `tall`, `pine`). Heights are normalised to `tree.height`.
  A look with snow cover ≥ 0.4 switches to winter automatically.
- `car`: everyday models plus `rare` ones (police, taxi, delivery) at `rare_chance`, uniform `scale`.

Set params `"kit": "suburban" | "primitive"` and `"season"` choose the kit. `primitive` is the
procedural fallback that needs no assets.

`library/kits/supermarket.json` (supermarket generator, `"kit": "supermarket"`):

- `gondola`, `wall_shelf`: rack models plus their measured board heights (`levels`, metres above
  the floor in the model's normalised frame), `reach` / `front` (centre to board edge), usable
  `depth` and `shelf_len` (board length between uprights). The generator tiles gondolas from the
  model's length, so stock, toys and anchors sit on the boards that are drawn. Measure a new rack
  with `godot --headless --path godot --script res://tools/fixture_probe.gd -- "<model id>"`
  (prints materials and every upward-facing surface height).
- `recolor`: flat albedo colours (hex without `#`) → new colours, applied to every fixture
  (`KitDB.static_node(id, scale, recolor)`). The Fab racks' orange/cream became green/grey.
- `fridge.door_materials`: material names swapped for a glow (on) or dark glass (off) per freezer switch.
- `checkout` (`counter`, `register`), `clutter` (`cart`, `basket`, `box`, `trash`, each with `scale`;
  the garbage bin pack is in centimetres-ish units → 0.0042).
- `stock`: per shelf category, product `models` and `mix` (share of runs that stay procedural
  boxes/cans); `stock_scale` shrinks products (they are also fitted under the board above).
  Categories without an entry (cereal, pasta, cleaning, household) stay procedural.
- `credits`: the CC-BY packs (basket, garbage bin, cardboard box) need the credit lines from
  `pipeline/asset_packs.json` in the video description.

## Imported, not used yet

- **Characters**: `quaternius_ual/UAL1_Standard`, `UAL2_Standard` (male mannequin + 43 animations
  each), `Mannequin_F`; `kenney_characters/characterMedium` with skins (zombies, survivors…) and
  separate idle/run/jump animations. These are for the actors layer.
- **Downtown City**: modular buildings, streets, props, for a future `downtown` generator.
- **Fantasy Props**: barrels, crates, furniture, candles… for interiors and set dressing.
- **Nature extras**: rocks, cacti, palms, willows, logs, flowers, grass.

## Known limitations

- `front_door` anchors on kit houses sit at the centre of the front face. Kenney doors are often
  off-centre. A per-model `door_x` in the kit would fix this.
- Palette recolouring reaches kit houses (roof, walls) but not kit trees or cars.
