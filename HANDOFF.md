# Handoff: where TownForge is, and what to do next

*Last updated 2026-11-11. Read this first in a new session, then `docs/VISION_AND_ROADMAP.md`.*

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

Next, in order: (1) **demo episode `jio_story`** (how Mukesh Ambani built Jio): researched
script with sources in `episodes/jio_story/script.md`, **waiting for the user's approval**; then
beat sheet → episode.json → storyboard → voice → review → render;
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
  by `gemini-3.5-flash-lite` (bigger models think for minutes).
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
