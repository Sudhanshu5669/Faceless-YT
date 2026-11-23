# TownForge — shared instructions for coding agents

TownForge turns an approved story into a rendered, animated YouTube episode
("what if you…" hypotheticals, Shorts first). Godot 4.7 builds and films the
world; Python runs the pipeline; an LLM acts as director by writing JSON specs.

**Start with `HANDOFF.md`** (current state and next steps; older session notes in
`docs/history/`), then
`docs/VISION_AND_ROADMAP.md` (goals, workflow, status, what's next).
Read `docs/ARCHITECTURE.md` before changing structure. The director's vocabulary:

- `docs/SET_SPEC.md`: sets (towns) and their params
- `docs/LOOK_SPEC.md`: time, weather, light, sky, palette, grade (incl. absurd looks)
- `docs/CAMERA_SPEC.md`: anchors, shots, lenses, shot templates
- `docs/ASSET_PIPELINE.md`: importing packs, the model catalog, kits
- `docs/ACTOR_SPEC.md`: characters, actions (sequences, freeze marks), routes, crowds, cues/holds, actor anchors
- `docs/TIMELINE_SPEC.md`: episodes, timed shots, camera moves, set events, storyboard, video render
- `docs/AUDIO_SPEC.md`: narration (Gemini TTS), voice-first timing, word time refs, effects, beds, captions
- `docs/REVIEW.md`: the approval board (environment → characters → script & voice → shots) and the review loop
- `docs/TOON_SPEC.md`: the house toon characters (sphere heads, drawn faces, expressions)
- `docs/REVEALS_SPEC.md`: reveals and counters: things that appear on a word
- `docs/GAGS_SPEC.md`: **gags**: custom GDScript set pieces the director writes per video (cash cannon,
  a cord hauling a power plant...) + the reusable `library/gags/`
- `docs/MOTION_SPEC.md`: **motion rules** (anticipation, easing, squash & stretch, arcs, follow-through,
  impact tiers + camera shake, timing, stagger) and `godot/scripts/timeline/motion.gd`, the helpers every
  gag uses. Distilled from the installed skills `disney-animation-rule-skill`, `game-feel`, `animation-principles`

**Making a video in the house style?** Follow the `toon-short` skill
(`.claude/skills/toon-short/SKILL.md`): workflow, rules and checklists, with references for
cinematics, realism, assets (how to ask before downloading), motion, script and gags, vocabulary.

## The user's standing rules (for every model: Claude, Codex, anyone)

These come from the user's own feedback; they override defaults. The `toon-short` skill explains how to apply them.

1. **Shot-by-shot approval.** Make one shot, show it (`tf shot EPISODE NAME`, or the browser page
   `tf shot EPISODE --serve`), get approve / changes / reject, then the next. Read verdicts with
   `tf shot EPISODE --status`. Never batch-render a whole video for the user's first look. Once an
   episode's look is approved and the user says to keep going, build the rest autonomously,
   self-review every shot and present them together.
   **Always send the user a push notification** (Claude: the PushNotification tool) whenever a shot or a
   batch is finished and waiting for their approval (user, 2026-11-23).
2. **9:16 framing.** Nothing may be cut off by the narrow frame: stack reveals vertically on/above a
   character, never left/right; `tf framing EPISODE` must report nothing before a shot is shown.
3. **Action, not apparition.** Each narration line is a mini scene: a character DOES something to an
   object in a recognisable place, and the camera lands on the result (fire, throw, give, carry,
   bury, pile up). Things arrive because someone causes them, not by popping in.
4. **Real references are allowed and wanted** (user's decision, 2026-11-11: news commentary / free
   speech): real company logos, caricatures of the real people, faithful recreations of real tweets
   and headlines with real counts. Facts and quotes must be accurate; never invent a quote or a post.
   Keep logo files under `library/logos/` with a SOURCES.md (where each came from); ask the user
   before downloading files.
5. **Look:** India-first sets (no plain blue grid/tile), dramatic lighting (subject brightest, rim
   light, dark surroundings, depth of field), soft continuous motion, held props really held.
6. Quality bar: the reference channel @afterhourtheories. Commit directly on `main`.
7. **Invent, then implement.** For every line, brainstorm several literal, physical sight gags and
   pick the funniest one with a clear action and payoff (Zuckerberg needs energy → he hauls a
   nuclear plant on a rope). If the vocabulary can't express it, write a gag script
   (`episodes/<id>/gags/*.gd`, docs/GAGS_SPEC.md) instead of settling for a pop-in. Move generic
   gags to `library/gags/`.
   Animate every gag by docs/MOTION_SPEC.md: block phases (anticipation → action → contact → settle),
   land the contact on the word, ease everything, squash on impact, shake the camera on big hits.
8. **Reuse before you build** (user, 2026-11-12). For a prop: `python pipeline/tf.py props <words>`
   (the imported catalog: Quaternius, Kenney, Fab packs); use it when it fits the meaning (a wooden
   barrel is not an oil drum). For a system (water, boats/buoyancy, ropes, particles, crowds): look for
   a free Godot add-on (Godot Asset Library, MIT/CC0) or a CC0 asset pack (Kenney, Quaternius, Poly
   Pizza CC0) before writing one. Check the licence allows commercial video, keep its LICENSE, and
   ask the user before downloading (list name, source, size, licence). Build from primitives last.
   **Download first, build last** (user, 2026-11-23): before spending effort modelling, sculpting (Blender) or
   hand-animating anything (a vehicle, an aircraft, a building, a creature, a motion), the FIRST step is to search for
   a ready-made model or animation to download (Poly Pizza, Sketchfab CC0/CC-BY with downloads, Kenney, Quaternius,
   Poly Haven, the Smithsonian/NASA 3D, Mixamo-style motion libraries); list the candidates (name, source, size,
   licence) for the user. Only if none meets the scene's expectations (look, accuracy, licence) build it yourself.
9. **Never be lazy about places** (user, 2026-11-12). Every beat happens where the story says it
   happens (the TELECOM door is in Reliance Infocomm's lobby, not the family dining room that
   already existed). Build a new bay (set) and dress it (sign, brand colours, furniture from
   `tf props`) for each new place; reuse a set only for a deliberate callback or the same scene.
10. **No generic labelled cubes** (user, 2026-11-12: "where do you see generic labelled cubes irl?").
   Never show a thing as a box/cube with its name on it ("DATA", "VIDEO", "1 GB", "INFOTEL"). Show the
   real object people recognise: a film reel for video, a recharge scratch card for mobile data, the
   company's real sign or logo. Text only where text exists in reality (signs, price tags, headlines).

## Commands

```bash
python pipeline/tf.py test                          # Godot (headless) + Python tests — run before finishing any change
python pipeline/tf.py library                       # list saved looks, shot templates, named views
python pipeline/tf.py validate specs/sets/blackwood.json
python pipeline/tf.py preview-set [SPEC] [--look NAME] [--time 03:33] [--weather fog=0.8,rain=0.5] [--seed N]
                                                    # renders stills + contact_sheet.png into output/previews/
python pipeline/tf.py look save NAME FILE --description "..."   # validate + save a new look to the library
python pipeline/tf.py storyboard EPISODE             # episodes/<id>/preview/storyboard.png (start/mid/end per shot)
python pipeline/tf.py voice EPISODE                  # narration (cached TTS) + timing table, no render
python pipeline/tf.py render EPISODE [--draft] [--shots a,b] [--remix] [--png]   # episodes/<id>/renders/<id>.mp4 (--remix: sound only; frames stream to ffmpeg, --png saves them)
python pipeline/tf.py framing EPISODE [--shots a,b]   # every reveal stays inside the 9:16 frame? (lists what is cut off)
python pipeline/tf.py shot EPISODE NAME [--final]    # the shot-by-shot loop: one full-size clip + strip + framing check
python pipeline/tf.py shot EPISODE NAME --decide approved|changes|rejected [--note ...]   # record the user's verdict
python pipeline/tf.py shot EPISODE --status          # every shot and its verdict
python pipeline/tf.py shot EPISODE --serve           # the shot loop in the browser (watch, decide, render): http://127.0.0.1:8770/
python pipeline/tf.py review prepare|serve|notes EPISODE   # approval board; final renders need every item approved
python pipeline/tf.py explore [SPEC]                # interactive fly-through (T/Y time, F/C/R/X weather)
python pipeline/tf.py assets import                 # incoming/*.zip -> Godot assets -> library/catalog.json + thumbnails
```

## The library grows

When a look or shot you invent is good and plausibly reusable, save it
(`tf look save`, or a JSON file in `library/shots/`) with a clear one-line
description and tags. Check `tf library` before inventing something that may exist.

Tool paths come from `config.local.json` (git-ignored; copy `config.example.json`).
The Gemini key is `GEMINI_API_KEY` in `.env` (git-ignored). The sound pipeline uses numpy + scipy; word timing uses onnxruntime + the wav2vec2 model in
`models/alignment/` (git-ignored; see docs/AUDIO_SPEC.md).

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
9. **No generative image/video services.** Everything is rendered by Godot. (Exception the user made, 2026-11-24: the three pokhran device stickers were generated with Codex image generation at their request; ask before any other use.)

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
godot/scripts/timeline/   episode (load, validate, timeline, camera moves), set_events (timed switches)
library/characters/       character definitions (JSON)
library/actions.json      action vocabulary -> animations, measured gait speeds
godot/tools/              catalog + thumbnails, atlas swatch probe, locomotion probe, character probe
specs/sets/               set specs (JSON)
pipeline/tf.py            pipeline CLI
pipeline/                 tts (Gemini), align + ctc_align (forced-aligned word times), episode_audio (resolve, mix, captions), sfx (synth), review (+ review_ui/)
output/                   renders and previews (git-ignored)
```
