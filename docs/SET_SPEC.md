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

## `supermarket` params

A single-storey store at night: numbered aisles of stocked double-sided shelving, a front and back
cross aisle, checkouts by a glass storefront (z = 0, facing the parking lot), a freezer wall,
a toy section, ceiling fixtures, a parking lot with sodium lamps and cars. Side walls carry stocked wall shelving.

| Param | Default | Meaning |
|---|---|---|
| `aisles` | 8 | Number of aisles (numbered 1… left to right from the entrance). |
| `kit` | `"supermarket"` | Kit that dresses the store (`library/kits/supermarket.json`: Fab racks, fridges, checkouts, food, carts) or `"primitive"` (boxes, no assets). |
| `aisle_length`, `aisle_w` | 18, 2.4 | Aisle size (m). With a model kit the length rounds to whole gondola segments (18 → 18.77 with Fab racks). |
| `shelf_d`, `shelf_h` | 1.1, 2.1 | Gondola depth and height (m), **only for kit `primitive`**; a model kit takes them from its rack model (an error otherwise). |
| `clutter` | 0.5 | 0–1: abandoned carts, baskets and boxes in the aisles and back aisle, trash bags outside, a cart corral by the doors. The toy aisle and front aisle stay clear. |
| `front_zone`, `back_zone`, `side_zone` | 9, 4, 3 | Space for checkouts / back aisle / side walls (m). |
| `checkouts` | 4 | Checkout lanes left of the entrance. |
| `toy_aisle` | 6 | Aisle with the toy section (little robots with switchable eyes); 0 = none. |
| `power` | `night` | Ceiling lights: `on`, `night` (every third), `emergency` (every ninth), `off`. Freezers glow unless `off`. |
| `parking_depth`, `car_density` | 34, 0.25 | Parking lot. |
| `name` | `FRESHWAY` | The lit sign on the facade. |

**Anchors** (all in `manifest.json`): `entrance`, `store_center`, `storefront` (+`.left`, `.right`,
`.inside`), `parking_lot`, `front_aisle` (+`.start`, `.end`), `back_aisle`, `freezers`,
`aisle_N` (+`.start`, `.mid`, `.end`, `.front` = in the front aisle facing into aisle N),
`checkout_N`, `toys` (where you stand to reach the toy shelf), `toys.shelf`, `toy_hero`.
Shelving blocks line of sight (`WARN … hidden behind gondola_N`).

**Switchables** for timeline `events` (TIMELINE_SPEC.md): `toy_hero`, any `toy_N`, the group `toys`;
`fixture_N` / `fixtures`; `freezer_N` / `freezers`; `exit_signs`.

## `downtown` params

A dense city grid (`specs/sets/metro.json`): blocks lined with 3 m-floor buildings flush to the
sidewalks, 4-lane avenues (along X, `ave_N`) and streets (along Z, `st_N`) meeting at 4-way
intersections (`cross_I_J`), streetlights, street trees, parked cars, bollards and manholes. An
outskirts ring of blocks keeps the edge streets lined on both sides; streets run on past it.

| Param | Default | Meaning |
|---|---|---|
| `blocks_x`, `blocks_z` | 4, 3 | Inner blocks (the outskirts ring adds one more all round). |
| `block_tiles_x`, `block_tiles_z` | 4, 4 | Street tiles (6 m) between intersections: block size = 6.67 + 6 × tiles m. |
| `floors` | [3, 9] | Floor range of generated buildings. |
| `skyline` | 0.6 | 0–1: how much taller buildings get toward the middle of the city. |
| `styles` | brick, metal, stone | Facade styles to mix. |
| `landmarks` | 0.15 | Chance a mid-row lot gets a premade landmark building instead. |
| `trees`, `parked_cars` | 0.5, 0.35 | Density of street trees and parked cars. |
| `outskirts` | true | The extra ring of blocks. |
| `kit` | `downtown` | `library/kits/downtown.json` (Quaternius Downtown) or `primitive` (boxes). |

**Anchors** (all in `manifest.json`): `city_center`; `cross_I_J` and its sidewalk corners
`cross_I_J.ne|nw|se|sw` (facing the crossing); `ave_N` / `st_N` (middle of the street, facing along
it) with `.start`, `.end`, `.walk_l`, `.walk_r` (sidewalks); `block_A_B` (centre, sidewalk height);
`bldg_K` (on the sidewalk in front of the building, facing it) and `bldg_K.top` (roof).
Buildings block line of sight (`WARN … hidden behind bldg_K`).

**Walkways** (`layout.walkways`): a node per sidewalk corner, edges along sidewalks and across
crosswalks: the network pedestrian crowds walk on.

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
