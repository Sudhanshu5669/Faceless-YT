# Handoff: where TownForge is, and what to do next

*Last updated 2026-11-10. Read this first in a new session, then `docs/VISION_AND_ROADMAP.md`.*

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
- Uncommitted at the time of writing: character retargeting + city cast (commit on main).
- Never commit: `.env` (Gemini key, git-ignored), `incoming/`, `godot/assets/`, `output/`.

## Next steps, in order

1. **Downtown generator** (`godot/scripts/world/generators/downtown_generator.gd` + builder, registered
   in `set_builder.gd`): city blocks from `quaternius_downtown` (106 building parts, 39 street pieces,
   props; look at `library/thumbs/_sheets/quaternius_downtown_*.png`), sidewalks, crossings, street
   furniture, named anchors (blocks, corners, crossings, sidewalks) for routes and cameras.
2. **Crowds that wander**: many pedestrians on sidewalk routes (loops between anchors), using the
   `city_*` characters. Check the cost of retargeting at crowd scale (one extra skeleton per actor).
   Per-member colour variation could replace hand-made variants later.
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
