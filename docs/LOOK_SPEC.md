# Looks: time, weather, light, sky, grade

A look is everything about *how the world is lit and what the air is like*.
It is applied on top of any set. In a spec, `"look"` is either a preset name
or an object.

```json
"look": "night_fog"
"look": { "base": "night_fog", "time": "03:33" }
"look": { "base": "day", "weather": { "snow": 0.8 }, "palette": { "lawn": "#ff8ad8" } }
```

Run `python pipeline/tf.py library` to see every saved look with its description.

## How a look is resolved

```
defaults → time model → weather model → explicit overrides
```

1. **base**: inherit everything from another look (a name or an inline object). Chains are allowed.
2. **time**: `"03:33"` or `3.55`. Sets the sun and moon positions, sky colours, stars, ambient light,
   exposure, and how many streetlights, windows and porch lights are on.
3. **weather**: fog, clouds, rain, snow and wind (each 0–1). These change fog, clouds, sun strength,
   shadow softness, wet roads, snow cover and particles.
4. **Explicit fields** (below) always win. That is how you get absurd looks: `"time": "12:00"` with a
   black sun is an eclipse.

## Intent fields

| Field | Meaning |
|---|---|
| `base` | Preset name or look object to inherit. |
| `time` | Hours `3.55` or `"HH:MM"`. Sunrise ≈ 06:20, sunset ≈ 19:40, moon up ≈ 18:30–06:30. |
| `weather.fog` | 0–1. Low ground fog plus distance haze. 0.7 = thick liminal fog. |
| `weather.clouds` | 0–1. Cloud cover. Dims the sun and softens shadows. |
| `weather.rain` | 0–1. Rain particles, wet glossy roads, adds clouds and some fog. |
| `weather.snow` | 0–1. Snow particles and snow cover on lawns, roofs and trees. |
| `weather.snow_cover` | 0–1. Ground cover without falling snow (the morning after). |
| `weather.wind` | 0–1. Cloud drift speed and particle slant. |
| `id`, `description`, `tags` | Required when saving a look to the library. |

## Override fields (all optional)

| Field | Keys |
|---|---|
| `sky` | `top`, `horizon` (colours), `stars` (0–2), `star_color`, `clouds` (0–1), `cloud_color`, `cloud_shadow`, `cloud_speed`, `bodies` (extra sky objects, below) |
| `sun`, `moon` | `elevation`, `azimuth` (degrees), `color` (light colour), `energy`, `shadows`, `softness` (shadow blur), `visible`, `size` (angular radius in degrees; real ≈ 0.25, default sun 1.6, moon 2.2), `disc_color` (what the disc looks like; `#000000` = eclipse), `glow`, `glow_color` (halo) |
| `lights` | Extra directional lights: `[{elevation, azimuth, color, energy, shadows}]`. Use for a second sun, a green glow from the east, and so on. |
| `ambient` | `color`, `energy`: fill light everywhere. `sky` (0–1): how much of the fill comes from the sky itself (directional: blue from above, horizon colour from the sides) instead of the flat colour; use 0.6–1 for daylight exteriors. |
| `exposure` | Overall brightness (1 = neutral). |
| `fog` | `begin`, `end` (distance fog, metres), `curve`, `volumetric` (global density), `color`, `emission` (glowing fog), `anisotropy`, `length` |
| `ground_fog` | `density`, `height`, `falloff`, `color`, `emission`: the low fog layer streetlights cut through. |
| `glow` | `enabled`, `intensity`, `bloom`, `threshold` |
| `ssao` | true/false |
| `grade` | `brightness`, `contrast`, `saturation`, `gradient_map` (list of colours = duotone/tritone remap of the whole image), `vignette` (0–1), `grain` (0–1) |
| `palette` | Recolour the world by surface slot: `ground`, `lawn`, `asphalt`, `lane_paint`, `sidewalk`, `driveway`, `walkway`, `fence`, `siding`, `roof`, `trim`, `door`, `foliage`, `bark`, `car`, `pole`. A single colour replaces every use. A list of colours remaps each original colour to one entry, so variety is kept. |
| `practical_lights` | `level` (0–1, streetlights on/off/dim), `street_light_color`, `street_light_energy`, `street_light_fog`, `window_lit_chance`, `window_color`, `window_energy`, `porch_light_chance`, `porch_light_color`, `porch_light_energy` |

### Sky bodies

`sky.bodies` adds up to 4 objects to the sky (the sun and moon are already there):

```json
{ "kind": "planet", "elevation": 25, "azimuth": -30, "size": 14, "color": "#b48cff", "glow": 0.4 }
```

`kind` is `sun` (bright disc), `moon` (cratered disc) or `planet` (banded disc). Bodies are
visual only. Add a matching entry to `lights` if one should cast light.

### Directions

`azimuth` 0 = the body sits toward +Z, 90 = toward +X, −90 = toward −X. The time model's
sun rises at azimuth −100 (the −X side of town) and sets at +100.
To point a camera at a body, use `"look_at": {"sky": "sun"}` (see CAMERA_SPEC.md).

## Examples

```json
{ "base": "night_fog", "moon": { "elevation": 16, "size": 11, "disc_color": "#d8402a", "glow": 1.6, "glow_color": "#ff3a1a" },
  "sky": { "top": "#0e0206", "horizon": "#3a0c10" }, "ground_fog": { "color": "#8a3a3a" } }        // blood moon

{ "time": "12:30", "sun": { "disc_color": "#000000", "glow": 1.6, "glow_color": "#f4f0ff", "energy": 0.18 },
  "sky": { "top": "#04060e", "horizon": "#8a5a46", "stars": 0.8 }, "practical_lights": { "level": 1.0 } }  // eclipse

{ "time": "11:00", "palette": { "lawn": "#ff8ad8", "foliage": ["#7af0ff", "#b38aff"], "roof": ["#ff5a8a", "#5ad1ff"] },
  "sky": { "top": "#ff9ad5", "horizon": "#fff1b8" } }                                                   // candy world
```

## Saving

When a look works and might be reused, save it:

```bash
python pipeline/tf.py look save blood_moon my_look.json --description "Huge red moon over crimson fog"
```

The file can hold a look object, or a spec whose `look` is an object. The look is validated before
it is saved. Invalid looks are not saved, and existing looks are not overwritten without `--force`.
