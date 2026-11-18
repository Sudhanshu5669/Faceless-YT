# Vocabulary you can use today

A quick index. The authoritative lists are in the docs named in each row; `tf library` and
`tf props` show what is installed.

## Characters and faces (docs/TOON_SPEC.md, docs/ACTOR_SPEC.md)

- **Cast:** the `toon_*` characters in `library/characters/`. All actions in
  `library/actions.json` work on toons.
- **Expressions** (actor cue `"expression"`): `smug`, `deadpan`, `side_eye`, `scheming`, `wink`,
  `happy`, `laugh`, `grin`, `cheer`, `star_eyes`, `love`, `shocked`, `panic`, `surprised`,
  `nervous`, `angry`, `furious`, `sad`, `crying`, `dead`, `sleepy`, `thinking`, `determined`, `cool`,
  `effort`, `strain`, `neutral`. The "true face" gag is a cut to `toon_boss_evil`.
- **Routes:** run actors in on a word (`"route": {"via": [...], "gait": "run", "start": word,
  "arrive": word}`).
- **Procedural poses:** `godot/scripts/actors/toon_crawl.gd` (crawl, haul, dig; two-bone IK).

## Reveals (docs/REVEALS_SPEC.md)

- **Shapes:** `box sphere cylinder cone ring coin card cash bottle pin chip phone`, any catalog
  prop, 3D `text`, `counter` (`"group": "indian"` → 3,00,000).
- **Story shapes:** `refinery pump postcard scales frame garland cake cake_half binoculars sign
  spinner tower rickshaw plaque india crown moneybag vitrine laptop tank receipt podium cake_slice
  bowling_ball globe orbit tape knife` (+ `label` on card/sign/cake/pump/postcard/moneybag/tank/receipt;
  `india` is the map, pins by lon/lat).
- **Entrances:** `pop drop rise slide_left slide_right beam grow`, `enter: "move"` with `from`.
  Then `spin`, `bob`, `glow`, `roll`, `moves` [{t, by, dur | until, turn, tip}] (moves add up: two make an arc).
- `at` can be an actor anchor (`"boss.hand"`, `"boss.head"`): things sit in hands and float over heads.
  Reveal ids are camera anchors. `link` lines draw red link graphs and hoses.
- Anchor offsets are `[right, up, forward]` with `right = forward × up` (facing +z, right is world −x).

## Gags (docs/GAGS_SPEC.md)

`episodes/<id>/gags/*.gd` or `library:<name>`: `build()` + `pose(t)`, anchors `<gag>.<name>`,
params with word-time refs. Library: `cash_stream`, `balance_scale`, `balloon`, `beard`, `door`,
`snail`.

## Sets (docs/SET_SPEC.md)

- **India-first:** wall `bazaar` + floor `road` for streets (painted shop rows, Hindi signboards,
  autos, wires, fairy lights); wall `haveli` + floor `marble`/`wood` for interiors (`"sides": true`
  for a room). Never the plain blue grid/tile look.
- **`generator: "stage"`** (example `specs/sets/jio_stage.json`): bays with floors, walls, neon,
  pedestals, `"mood": "dramatic"`. Anchors `<bay>`, `.left/.right/.back/.front/.wall/.sky/.pedestal`.
- Other generators: town (suburban), supermarket, downtown. Bespoke places (tunnels, rigs, lanes)
  are gag scripts.

## Camera and timeline (docs/CAMERA_SPEC.md, docs/TIMELINE_SPEC.md)

- Shots: `at`, `look_at`, `lens_mm`, `dof`, `roll`, `pan`, `tilt`, `exposure`, templates
  (`low_hero`, `worm_eye`, `god_view`, `dutch_dread`, `establishing_drone`, `long_lens_watcher`).
- Moves: `from` / `to` / `ease`. Transitions: `whip_in`/`whip_out` (`left|right|up|down`),
  `iris_in`/`iris_out` (`binoculars|circle`). `shake`, `hold`.
- Format: `"format": {"resolution": [1080, 1920], "fps": 60, "motion_blur": 2}`.

## Looks (docs/LOOK_SPEC.md)

`toon_drama`, `dusk`, `day`, `night_fog`, `neon_night`, `storm_night`, `blood_moon`, `eclipse_noon`;
time, weather, fog, palette and grade overrides.

## Sound and voice (docs/AUDIO_SPEC.md)

- **Effects:** `pop`, `whoosh`, `ding`, `tick`, `cash`, `thud`, `click`, `sting`, `whistle`, `rip`,
  plus recorded effects per episode (`episodes/<id>/audio/`, with SOURCES.md).
- **Beds:** `beat` (`"ambience": [{"sound": "beat", "gain": -19, "duck": 0.55}]`) and ambiences.
- **Voice:** one take for the whole script (Gemini TTS, or local Qwen). Gemini: style in a
  `[bracket tag]`, `batch_words` ≤ 16–30, free tier ~10 requests a day per model.
- **Captions:** `"captions": {"max_words": 2, "style": "toon"}`.

## Not built yet

Approximate with what exists and note the gap in your report; don't fake it with coordinates.
- Push-through / light-tunnel transitions (whips and the binocular iris exist).
- A sunburst "shock" background; UI cards with real content (tweets, chats, posts) as a vocabulary
  item (build per episode as a gag for now).
- Blending between actions (switches are instant); routes are straight lines between waypoints.
