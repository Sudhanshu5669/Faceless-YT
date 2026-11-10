# Handoff: where TownForge is, and what to do next

*Last updated 2026-11-10. Read this first in a new session, then `docs/VISION_AND_ROADMAP.md`.*

## State in one paragraph

TownForge renders narrated YouTube Shorts from JSON specs: procedural sets (town, supermarket),
looks, actors with cues, timed shots with camera moves, Gemini TTS narration with word-timed
captions, synthesized sound, and an **approval board** that gates the final render. The current
episode is `episodes/supermarket_silence` ("A Toy Starts Talking", pitch C, Charon voice, script
approved). The supermarket is now dressed with the **Fab `supermarket` kit** (rack gondolas, wall
shelves, fridges, checkouts, food stock, carts/baskets/boxes/trash bags). The board was re-prepared
for env, cast and shots on 2026-11-10; the user has not reviewed anything yet (all 35 items pending).

## Git

- Committed: `09acfcb` (timeline), `a2805d3` (supermarket + sound + captions), `9f90348` (review
  board, Fab packs, this file).
- **Uncommitted** (ask, then commit on main): the supermarket kit work:
  `library/kits/supermarket.json`, `supermarket_generator.gd` (params `kit`, `clutter`; gondola
  segments, wall shelves, clutter, kit validation), `supermarket_builder.gd` (model fixtures, kit
  stock MultiMeshes), `kit_db.gd` (`static_node` + recolour, `override_named`), new
  `godot/tools/fixture_probe.gd`, test `supermarket kit: …`, docs (SET_SPEC, ASSET_PIPELINE,
  roadmap), `episode.json` (shot `shoes` camera now on anchor `checkout_2`), one suggestion text.
- Never commit: `.env` (Gemini key, git-ignored), `incoming/`, `godot/assets/`, `output/`.

## Next steps, in order

1. **Ask the user** whether to commit the uncommitted work above, and how the review is going.
2. **Review loop** (`docs/REVIEW.md`): the user runs `python pipeline/tf.py review serve supermarket_silence`,
   approves or requests changes gate by gate (Environment → Characters → Script & voice → Shots), and
   says "review done". Then run `python pipeline/tf.py review notes supermarket_silence`, apply every
   note and every ticked suggestion, re-run `tf review prepare supermarket_silence --gate <changed gates>`,
   update `review/suggestions.json` (drop what's done, add new critique after looking at the media),
   and tell the user what changed.
3. ~~Use the Fab assets in the supermarket set~~ (done 2026-11-10). Possible follow-ups, only if the
   review asks: end caps (`…#Cube_007`) on gondola fronts, produce/deli counters (`…#Cube_049`,
   `…#Cube_031`, `…#Cube_005`) near the front, fallen products on the floor, checkout occluder rects
   still assume a 0.9 m counter (the kit counter is 1.2 m).
4. **Final narration voice.** Narration is a DRAFT on `gemini-3.8-flash-lite-tts` (set via env var
   `TOWNFORGE_TTS_MODEL` in every command). The free tier allows 10 TTS requests per model per day; the
   user's choice was Charon on `gemini-3.8-flash-tts`. When the quota has reset (or billing is on), run
   commands **without** the env var: the voice is re-synthesized in ~4 requests, timing re-resolves
   automatically (everything references words), then the voice and shots gates need another look.
5. Final render: `python pipeline/tf.py render supermarket_silence` (refuses until the board is fully
   approved).

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
