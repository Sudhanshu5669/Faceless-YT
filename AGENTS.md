# TownForge — shared instructions for coding agents

TownForge turns an approved story into a rendered, animated YouTube episode
("what if you…" hypotheticals, Shorts first). Godot 4.7 builds and films the
world; Python runs the pipeline; an LLM acts as director by writing JSON specs.

Start with `docs/VISION_AND_ROADMAP.md` (goals, workflow, status, what's next).
Read `docs/ARCHITECTURE.md` before changing structure. The director's vocabulary:

- `docs/SET_SPEC.md`: sets (towns) and their params
- `docs/LOOK_SPEC.md`: time, weather, light, sky, palette, grade (incl. absurd looks)
- `docs/CAMERA_SPEC.md`: anchors, shots, lenses, shot templates
- `docs/ASSET_PIPELINE.md`: importing packs, the model catalog, kits
- `docs/ACTOR_SPEC.md`: characters, actions (sequences, freeze marks), routes, crowds, cues/holds, actor anchors
- `docs/TIMELINE_SPEC.md`: episodes, timed shots, camera moves, storyboard, video render

## Commands

```bash
python pipeline/tf.py test                          # Godot (headless) + Python tests — run before finishing any change
python pipeline/tf.py library                       # list saved looks, shot templates, named views
python pipeline/tf.py validate specs/sets/blackwood.json
python pipeline/tf.py preview-set [SPEC] [--look NAME] [--time 03:33] [--weather fog=0.8,rain=0.5] [--seed N]
                                                    # renders stills + contact_sheet.png into output/previews/
python pipeline/tf.py look save NAME FILE --description "..."   # validate + save a new look to the library
python pipeline/tf.py storyboard EPISODE             # episodes/<id>/preview/storyboard.png (start/mid/end per shot)
python pipeline/tf.py render EPISODE [--draft] [--shots a,b]   # episodes/<id>/renders/<id>.mp4
python pipeline/tf.py explore [SPEC]                # interactive fly-through (T/Y time, F/C/R/X weather)
python pipeline/tf.py assets import                 # incoming/*.zip -> Godot assets -> library/catalog.json + thumbnails
```

## The library grows

When a look or shot you invent is good and plausibly reusable, save it
(`tf look save`, or a JSON file in `library/shots/`) with a clear one-line
description and tags. Check `tf library` before inventing something that may exist.

Tool paths come from `config.local.json` (git-ignored; copy `config.example.json`).

## Rules

1. **The LLM directs, the engine executes.** Specs name things (`house:house_4`,
   `look: night_fog`); they never contain raw coordinates for objects. If a shot
   needs something the vocabulary lacks, add it to the engine, not to the spec.
2. **Deterministic.** Same spec + seed → identical layout and frames. Use the
   generator's named RNG streams (`_rng(seed, "trees")`); never `randf()`/`randi()`
   globals, never `Array.shuffle()`, never wall-clock time.
3. **Generator / builder split.** Generators (`godot/scripts/world/generators/`)
   return pure data and create no nodes. Builders (`.../builders/`) turn data into
   nodes. New location types add one of each and register in `set_builder.gd`.
4. **Node names = layout ids** (`house_3`, `light_12`) so later stages can find them.
5. **Validate loudly.** Unknown params, looks or views are errors, not silent
   defaults. Never ignore a failed render.
6. **Visual changes need eyes.** After changing anything visual, run
   `preview-set` and actually look at `contact_sheet.png` before calling it done.
7. **Performance budget:** RTX 4050 6 GB / 16 GB RAM. Use shared materials and
   meshes (`prop_kit.gd` caches them) and MultiMesh for anything repeated hundreds
   of times. Shadow-casting only where it reads on screen.
8. **Never overwrite user assets** in `library/` without asking.
   Only import packs whose license allows commercial video use (CC0 so far); keep each pack's LICENSE.txt.
9. **No generative image/video services.** Everything is rendered by Godot.

## Code conventions

- GDScript, static typing where the type is known. Use `preload()` constants,
  not `class_name` (the project runs without an editor import step).
- Units are metres, Y up. Rects are `[x0, z0, x1, z1]` in world XZ. A house's
  local +Z faces its street.
- Python: standard library only unless a dependency clearly earns its place.

## Layout

```
godot/scripts/core/       spec loading + validation
godot/scripts/world/      generators (data), builders (nodes), prop_kit (shared meshes/materials)
godot/scripts/look/       look_compiler (time + weather models, validation) → look.gd (env, sky, lights, fog, particles, grade)
godot/scripts/camera/     anchors, shot resolution, named views, fly camera
godot/shaders/            sky (gradient, stars, clouds, sky bodies), grade (vignette, grain)
godot/tests/run_tests.gd  headless test runner
library/looks/            saved looks (JSON)
library/shots/            saved shot templates (JSON)
library/kits/             curated model roles per kit (JSON)
episodes/<id>/            episode.json (+ git-ignored renders/, preview/)
library/catalog.json      generated model catalog (sizes, categories, animations)
godot/assets/             imported packs (git-ignored, rebuilt from incoming/)
godot/scripts/actors/     cast (bodies, merged animations, action sequences), actor (pose_at(t)), director (plans, crowds, cues)
godot/scripts/timeline/   episode (load, validate, timeline, camera moves)
library/characters/       character definitions (JSON)
library/actions.json      action vocabulary -> animations, measured gait speeds
godot/tools/              catalog + thumbnails, atlas swatch probe, locomotion probe, character probe
specs/sets/               set specs (JSON)
pipeline/tf.py            pipeline CLI
output/                   renders and previews (git-ignored)
```
