# Set spec (schema 0.1)

A set spec describes one location, how it is lit, and how to preview it.

```json
{
  "schema_version": "0.1",
  "set": {
    "id": "blackwood",
    "generator": "town",
    "seed": 333,
    "params": { "blocks_x": 3, "blocks_z": 2 }
  },
  "look": "night_fog",
  "preview": {
    "resolution": [540, 960],
    "views": ["aerial", "street", "house", "intersection", "entrance"]
  }
}
```

| Field | Meaning |
|---|---|
| `set.generator` | Which generator builds the set. Available: `town`. |
| `set.seed` | Integer. Same seed + params → identical set. |
| `set.params` | Generator params; unknown keys and out-of-range values are errors. |
| `look` | A file in `library/looks/` (`night_fog`, `dusk`, `day`). |
| `preview.resolution` | Still size `[w, h]`, 64–4096. Portrait for Shorts. |
| `preview.views` | Named views to render (see below). |

## `town` params

| Param | Default | Range | Notes |
|---|---|---|---|
| `blocks_x`, `blocks_z` | 3, 2 | 1–8 | Grid of blocks. The middle E-W road is the main street. |
| `block_w`, `block_d` | 64, 52 | 30–150, 40–120 | Block size in metres. Houses line the E-W streets. |
| `road_w`, `sidewalk_w` | 8, 2.2 | 5–16, 1–5 | |
| `lot_w` | 15 | 12–40 | Target lot width; lots are stretched to fill the block. |
| `house_density` | 0.9 | 0–1 | Chance a lot has a house; the rest are vacant lots. |
| `two_story_chance`, `garage_chance` | 0.35, 0.6 | 0–1 | |
| `tree_density` | 0.6 | 0–3 | Yard trees per area. |
| `car_density` | 0.4 | 0–1 | Driveway and street parking. |
| `light_spacing` | 22 | 8–80 | Metres between streetlights. |
| `exit_roads` | true | bool | Main street continues out of town into the forest. |
| `forest_band`, `forest_density` | 45, 0.5 | 0–150, 0–2 | Forest ring around the town. |
| `kit` | `"suburban"` | kit id or `"primitive"` | Which models dress the set (see ASSET_PIPELINE.md). `primitive` = procedural boxes, no assets needed. |
| `season` | `"summer"` | summer, autumn, winter, dead, dead_winter | Tree and bush models. `dead` = bare trees, ideal for horror. Snow in the look switches to winter automatically. |

## Views

| View | Shot |
|---|---|
| `aerial` | High establishing shot down the main street. |
| `street` | Eye level on the main street, looking along it. |
| `house` / `house:<id>` | From the road in front of a house. Default: most central main-street house with a clear view. |
| `intersection` | Low angle across the town-center intersection. |
| `entrance` | On the road outside town, looking in. Needs `exit_roads`. |

## Outputs of `preview-set`

In `output/previews/<set>_s<seed>_<look>/`:

- `NN_<view>.png` — one still per view
- `contact_sheet.png` — all stills side by side
- `layout.json` — the full generated layout (geometry; for debugging)
- `manifest.json` — named places only: streets with names, houses with
  addresses and anchors, vacant lots, counts. **This is what a director reads.**
