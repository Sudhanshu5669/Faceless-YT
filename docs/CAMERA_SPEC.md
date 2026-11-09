# Cameras and shots

A shot says where the camera is, what it looks at, and with what lens. Shots
reference **named places (anchors)**, never raw geometry, so the same shot works
on any generated town.

```json
"house:house_4"                                                       // a named view
{ "template": "dutch_dread", "subject": "house_4.front_door" }        // a saved shot template
{ "at": { "anchor": "house_4.curb", "offset": [0, 1.6, 3] },          // built from scratch
  "look_at": "house_4.front_door", "lens_mm": 35, "roll": 8 }
```

## Anchors

Listed in `manifest.json` next to every preview render.

| Anchor | Where | Forward direction |
|---|---|---|
| `town_center`, `main_street_west/mid/east`, `town_entrance_east/west` | global places | along the main street (entrances: into town) |
| `house_N` / `.center` / `.roof` / `.front_door` / `.lawn` / `.driveway` / `.backyard` / `.curb` | a house | out of the house, toward its street |
| `street_hN.start/.mid/.end`, `street_vN...` | a street | along the street |
| `int_I_J` | an intersection | +X |
| `light_N` / `light_N.lamp` | a streetlight / its lamp head | over the road |
| `vacant_N` | an empty lot | toward its street |

## Points (`at`, `look_at`)

| Form | Meaning |
|---|---|
| `"house_4.curb"` | The anchor itself. |
| `{"anchor": "...", "offset": [right, up, forward]}` | Metres in the anchor's own frame. `[0, 1.6, 3]` = eye height, 3 m in front. |
| `{"anchor": "...", "orbit": {"distance": 30, "angle": 40, "height": 20}}` | Circle around the anchor. `angle` 0 = in front, 90 = to its left, 180 = behind. |
| `{"sky": "sun"}` / `{"sky": "moon"}` / `{"sky": {"elevation": 30, "azimuth": 0}}` | `look_at` only: aim at a sky body of the current look. |
| `{"world": [x, y, z]}` | Raw coordinates. Last resort; doesn't transfer to other towns. |

## Shot fields

| Field | Meaning |
|---|---|
| `view` | Start from a named view (`aerial`, `street`, `house[:id]`, `intersection`, `entrance`), then override. |
| `template` + `subject` | Start from `library/shots/<template>.json`, with `$subject` replaced by the anchor. |
| `at`, `look_at` | Points (above). `direction: {"yaw", "pitch"}` can replace `look_at`. |
| `height` | Force camera height (m above ground). |
| `lens_mm` | Focal length, full-frame equivalent on the frame's long side. 14 = ultra-wide, 24 = wide, 35 = natural, 50 = normal, 85 = portrait, 135+ = telephoto. Or `fov` in degrees. |
| `roll` | Dutch angle in degrees. |
| `pan`, `tilt` | Extra rotation after aiming, in degrees (tilt −15 = look a bit lower). |
| `dof` | `{"strength": 0–1, "focus": metres}`. Focus defaults to the `look_at` distance. |
| `exposure` | EV offset: +1 = twice as bright, −1 = half. |
| `orthographic` | View height in metres. Switches to a flat map-like projection. |
| `name` | Used for the output file name. |

## Shot templates

`python pipeline/tf.py library` lists them. A template is a JSON file in
`library/shots/` with a `description` and a `camera` that uses `$subject`:

```json
{ "id": "low_hero", "description": "Low angle, wide lens, slight tilt: the subject looms over the viewer.",
  "camera": { "at": {"anchor": "$subject", "offset": [1.5, 0.35, 5.0]},
              "look_at": {"anchor": "$subject", "offset": [0, 2.6, 0]}, "lens_mm": 18, "roll": -4 } }
```

When a custom shot works well and is reusable, save it as a template in the same way.
Every template is tested against several generated towns (`tf test`).
