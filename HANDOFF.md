# Handoff: where TownForge is, and what to do next

*Last updated 2026-11-11 (late). Read this first in a new session (Claude or Codex), then
`AGENTS.md`, then `docs/VISION_AND_ROADMAP.md`.*

## START HERE: current task (for whoever picks this up)

**Episode `jio_story`** ("How Mukesh Ambani built Jio", toon style, 52 shots, 129.7 s). A full
60 fps final exists (`episodes/jio_story/renders/jio_story.mp4`), but the user wants it **redone
shot by shot with their approval**, and at a **higher visual quality**.

### The user's rules (from their feedback; follow them)
1. **Shot-by-shot approval.** Make one shot, let the user see it, they approve / ask for changes /
   reject, then the next. Tools: `python pipeline/tf.py shot jio_story NAME` (full-size clip with
   sound + captions + frame strip + framing check) and the browser page
   `python pipeline/tf.py shot jio_story --serve` (http://127.0.0.1:8770/: watch, decide, render).
   Read their verdicts with `python pipeline/tf.py shot jio_story --status` (notes are in
   `episodes/jio_story/review/shot_decisions.json`). Fix what they ask, re-render that shot, and the
   page shows the new version. Don't show a shot that fails the framing check.
2. **9:16 framing.** Nothing may be cut off by the narrow frame. Put reveals on the vertical axis (on
   / above a character's head via `<actor>.head`, in hands, stacked), never spread left/right; place
   late reveals where the END of a push-in still sees them. `tf framing jio_story` lists every crop.
   (Shot 2 was redone this way: refinery, pump, bottle stack on Mukesh's head.)
3. **India-first sets** (no plain blue grid/tile looks), soft continuous motion (no pops/swaps of the
   same object), held props held, labels where a viewer expects them.
4. **Quality bar = the reference channel @afterhourtheories** (their "How Facebook will win the AI
   race?" Short). Commit directly on `main`. Never use generative image/video services.

### Shot loop status
Shot 1 `open` (name stacked over his head) and shot 2 `empire_items` (businesses stacked on his
head) are rendered in the shot loop and **waiting for the user's verdict**; shots 3-52 not yet
re-rendered. The framing check (`tf framing jio_story`) found crops in 27 shots of the old cut:
fix each as you reach it.

### Next: the look-dev pass (proposed to the user, likely approved; it was "start with lighting
and materials?")
Comparison with the reference (frames side by side) showed the gap is craft, not style:
1. **Lighting & colour (biggest gap):** reference = dark backgrounds, subject brightest, 2-3 neon
   colours per shot, coloured rim light, bloom, AO, depth of field. Ours = flat even light, pastel
   walls (pink/mint/white) that swallow the white toon heads. To do: per-bay lighting rig (key on
   the subject + coloured rim/back light), darker walls/floors in `make_episode.py` bays, and in
   `godot/scripts/look/look.gd` enable SSAO, glow/bloom, filmic/AgX tonemap and camera DOF
   (CameraAttributesPractical) for the toon looks. Check `neon_night` look + `stage_builder.gd`.
2. **Materials:** rounded/bevelled, slightly glossy toy surfaces instead of hard flat primitives
   (`reveals.gd` `_shape`/`_story_parts` use `_box`/`_cyl` + `Toon.material`; add a rounded-box
   mesh helper and lower roughness / add specular in `Toon.material`).
3. Composition rules (subject size, low/wide angles, foreground), a toon pose library (point,
   shrug, cheer, throw) + mouth flap on words, a 2D overlay layer (viewfinder/HUD cards), particle
   bursts. Prove 1+2 on shots 1-2 first, show before/after, then continue the shot loop.

### Practical notes
- `episodes/jio_story/make_episode.py` generates `episode.json` and `specs/sets/jio_stage.json`:
  edit the .py, run `python episodes/jio_story/make_episode.py .`. Helpers: `W(line, word)` time
  refs, `S(anchor, screen_x, up, forward)` (screen-right positive), `A(anchor, [right, up, fwd])`
  (facing +z, "right" = screen LEFT), `on_map(lon, lat)` for the India map.
- The narration is ONE cached Gemini take (no TTS calls needed; free tier = 10/day). Word times are
  measured by CTC forced alignment (`pipeline/ctc_align.py`, wav2vec2 in `models/alignment/`,
  git-ignored; needs `pip install onnxruntime`). Never go back to LLM-guessed timings.
- Renders stream raw frames into ffmpeg (no PNGs; `--png` for the old path). NVENC needs NVIDIA
  driver 610+ (installed driver too old) so x264 is used automatically.
- The old 60 fps render left ~23 GB of PNGs in `episodes/jio_story/renders/frames/` (git-ignored);
  ask the user before deleting.
- Power cuts happen: after a restart, check files parse (JSON, Python AST) and `git status`.
- Always: `python pipeline/tf.py test` before committing; look at strips/storyboards (rule 6).


## NEW DIRECTION (2026-11-11): the toon house style

The user studied the reference channel **@afterhourtheories** (frame-by-frame breakdown: memory
`reference-afterhourtheories`) and chose its style for the whole channel: meme stick-figure
toons with swappable drawn faces, everything the narrator names appearing on its word, counters
landing on spoken numbers, "Imagine you're…" scripts. **The playbook is the `toon-short` skill**
(`.claude/skills/toon-short/SKILL.md`). Done this session:

- **Toon characters** (`scripts/actors/toon.gd`, shaders `toon_face/outline/hair`,
  docs/TOON_SPEC.md): sphere head + SDF face, hair styles, bean outfits, stick limbs, outlines,
  on a short-legged copy of the mannequin skeleton (rig `toon`), so all actions work. 25
  expressions in `library/toon/faces.json`, swapped by the actor cue `"expression"`. Cast:
  `toon_you`, `toon_boss`, `toon_boss_evil`, `toon_agent`, `toon_partner`, `toon_founder`,
  `toon_scientist(_b)`, `toon_redhead`, `toon_nerd`.
- **Reveals and counters** (`scripts/timeline/reveals.gd`, docs/REVEALS_SPEC.md): episode
  `reveals` (shapes, catalog props, 3D text, counters) with word-referenced `t`/`until`/`land`,
  entrances (pop, drop, rise, slide, beam, grow), `sound`. New one-shots: pop, whoosh, ding,
  tick, cash.

Next, in order: (1) **demo episode `jio_story`** (how Mukesh Ambani built Jio): the **full
episode is built** (2026-11-11): all 24 script lines, 52 shots, 129.7 s, on the one cached narration
take (no new TTS). Generated by `episodes/jio_story/make_episode.py` (edit that, not episode.json).
10 bays in `specs/sets/jio_stage.json` (empire, tribute, split, street, rivals durbar, war_room with
the India map, home, field, launch stage, court). Draft animatic:
`episodes/jio_story/preview/animatic/jio_story_animatic.mp4`. **The review board is prepared**
(`tf review serve jio_story`, 128 items, Claude's suggestions in `review/suggestions.json`).
**Creative pass done** (2026-11-11, from the reference video's tricks): binocular push-in + `iris_in`
POV cut, knife on the cake, binocular callback, red link graph (Infotel → 22 circles), cash rain + SOLD,
oxygen hoses to every head, domino shove, call packed into a DATA crate, fibre wound round a globe 7.5x,
fan stampede + phone cannon, phone wall +7 per tick, rivals run in crying (tears, WAAAH), JIO bowling
ball (STRIKE), duct-taped Vodafone/Idea, cake slices to Facebook/Google, India made of 110 people,
Dhirubhai's portrait laughs on "free". **Waiting on the user's review**; then apply notes → final
render. **Then (same day) the rest:** missing-piece frame, snail courier, taxi meter, dustbin throw,
receipt tower, tiny vs giant STARTUP garage, clock, rocket, sky lanterns; plus the review suggestions
(brand-coloured towers, map rim, JIO neon higher, JioPhone stand, down-the-lane bowling camera,
toon_official regulator). **Final render at 60 fps** (`format.fps: 60`, motion blur 3, ~23 GB of
frames) was run with `--force` at the user's request (board items not ticked). Not built: the
queue to the horizon. **Final video: `episodes/jio_story/renders/jio_story.mp4`** (1080x1920,
60 fps, 129.6 s, 124 MB; 40 min to draw + 5 min encode). Renders now stream raw frames into ffmpeg
(no PNGs) and use NVENC when the driver allows: **NVENC needs NVIDIA driver 610+ for this ffmpeg
build; the installed driver (NVENC API 13.0) is too old, so x264 is used until it's updated**;
(2) ~~display font~~ done (Lilita One, OFL);
(3) `stage` set generator (neon pedestal, dark grid "dossier" void); (4) whip-pan and
push-through transitions + motion blur (sub-frame accumulation) + a neon night look;
(5) music bed; (6) UI cards, link lines, cash rain. The downtown/ambient-demo plan below is
paused.

## State in one paragraph

TownForge renders narrated YouTube Shorts from JSON specs: procedural sets (town, supermarket),
looks, actors with cues, timed shots with camera moves, Gemini TTS narration with word-timed
captions, synthesized sound, and an approval board that gates the final render.

**Current direction (2026-11-10): an ambient city demo video** (no narration): a downtown with lots
of people moving around, cycling through different weathers, to show what the tool can do. The user
chose, in this order: (1) better characters first, (2) a new `downtown` generator from the imported
Quaternius Downtown kit, (3) skies from Poly Haven HDRIs (CC0) combined with our rain/fog/wind.
Good SKY (Fab) was checked and can't be used: Unreal-only Blueprint, Unreal-only licence.

Step 1 is done: **retargeting** (`scripts/actors/retarget.gd`, `library/rigs.json`) drives Quaternius
Ultimate Modular Men/Women (CC0) from the mannequin's animations, and 16 city people exist
(`library/characters/city_*.json`). The supermarket episode (`supermarket_silence`) is **parked**: the
user got bored of it; its board is prepared and nothing is approved.

## Git

- Committed: `09acfcb`, `a2805d3`, `9f90348` (review board), `4d09580` (supermarket Fab kit).
- `f51471a`: character retargeting + city cast. Downtown generator: see git status.
- Never commit: `.env` (Gemini key, git-ignored), `incoming/`, `godot/assets/`, `output/`.

## Next steps, in order

1. ~~Downtown generator~~ (done 2026-11-10): `downtown_generator.gd` + `downtown_builder.gd`,
   `library/kits/downtown.json`, `specs/sets/metro.json`. Facades from modules (MultiMesh), street
   tiles, outskirts ring, streetlights/trees/cars/props, walkway graph, anchors. Builds in ~2 s.
   Known gaps: **windows stay dark at night** (lit windows need per-instance glass variants: batch
   key model+lit, emissive glass material, `practical_lights.window_lit_chance`); no traffic; no
   street signs/benches/bins (the pack has none; Fantasy Props or Fab could fill in).
2. **Crowds that wander**: many pedestrians walking the `walkways` graph (loops of sidewalk corners
   and crosswalks), using the `city_*` characters; some standing (phone, idle) at building fronts.
   Check retarget cost at crowd scale. Probably a crowd "wander" mode in actor_director.
3. **Skies**: Poly Haven HDRIs as the look's sky (panorama), per weather (clear, overcast, rain,
   fog, dusk, night). Ask before each download (filename, source, size).
4. **The demo**: an episode with no narration, long slow camera moves, weather changes between
   shots, ambient beds (our sound pipeline), rendered at 16:9 and/or 9:16.
5. Parked: supermarket review loop, final Charon narration (quota), final render. See git history
   of this file for the details.

## Open suggestions already on the board (Claude's critique, `review/suggestions.json`)

FRESHWAY sign cropped; more parking lamps; debris in the store; toy aisle needs its own dim light;
crouched reach instead of standing; "take off your shoes" has no visual; zombies need tint/eyes to
read at night; stronger last line; toy-voice on "let's play" in n1; dying-battery chorus; zombies
visible behind the toy in frame 1; tighter glass_wall lens; longer payoff shot (3.5 s, camera shake);
cut to black on "plans.". The user ticks the ones to do.

## Gotchas learned (also in memory)

- `tf validate` printed "spec OK" while a generator script failed to compile (the SCRIPT ERRORs
  only show in the log). After editing GDScript, read the whole output or run `tf test`.
- A shot camera `at: {"anchor": "<actor>"}` turns with the actor's facing: when the actor turns
  to walk away, the camera swings (that put `shoes` inside the checkout counter). Use a set
  anchor for the camera position and `look_at` the actor.
- Fab rack shelf heights come from `tools/fixture_probe.gd`; the kit's `levels` must be
  re-measured if the rack model changes.

- Gemini TTS: style goes in a `[bracket tag]` (a "Say it like…:" prefix is read aloud); long requests
  get cut off, so batches are capped at 30 words and retaken once with an "End." pad; words are timed
  by CTC forced alignment (`pipeline/ctc_align.py`, wav2vec2 in `models/alignment/`; see AUDIO_SPEC).
- Power cuts are frequent here: after a restart, check files parse (JSON, Python AST) before continuing;
  review decisions are fsync'd.
- Fab: the user saves downloads into `incoming/` when Claude triggers them in their Chrome; Claude
  renames, adds `LICENSE.txt`, registers in `asset_packs.json`, then `tf assets import` (or
  `assets catalog --pack <id>` after a targeted extract).
- Godot globals lag right after posing: use `actor.bone_world()` / `_world_of()`, not `global_transform`.
- Anchor offsets are `[right, up, forward]` with `right = forward × up`. For forward +X, right is +Z;
  for forward −Z, right is +X. Getting this wrong put cameras outside the store twice.

## Useful commands

```bash
python pipeline/tf.py test                                   # 36 Godot + 13 Python tests
python pipeline/tf.py review serve supermarket_silence       # approval page
python pipeline/tf.py review notes supermarket_silence       # what the user asked for
TOWNFORGE_TTS_MODEL=gemini-3.8-flash-lite-tts python pipeline/tf.py storyboard supermarket_silence
python pipeline/tf.py render supermarket_silence --draft     # quick animatic (allowed without approval)
python pipeline/tf.py preview-set specs/sets/freshway.json   # set stills + contact sheet
```
