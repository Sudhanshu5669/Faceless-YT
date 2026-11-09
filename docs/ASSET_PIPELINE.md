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
