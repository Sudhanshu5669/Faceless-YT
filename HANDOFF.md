# Handoff: where TownForge is, and what to do next

*Last updated 2026-11-10. Read this first in a new session, then `docs/VISION_AND_ROADMAP.md`.*

## State in one paragraph

TownForge renders narrated YouTube Shorts from JSON specs: procedural sets (town, supermarket),
looks, actors with cues, timed shots with camera moves, Gemini TTS narration with word-timed
captions, synthesized sound, and an **approval board** that gates the final render. The current
episode is `episodes/supermarket_silence` ("A Toy Starts Talking", pitch C, Charon voice, script
approved). A 64.7 s draft render exists (`renders/supermarket_silence.mp4`) and its review board is
prepared, but the user has not started reviewing yet. New Fab assets for the supermarket are
imported and catalogued, but **not used by the set yet**.

## Git

- Committed: `09acfcb` (timeline), `a2805d3` (supermarket set + sound pipeline + captions).
- **Uncommitted** (commit on main when the user agrees; see memory "commit-on-main"):
  - Review board: `pipeline/review.py`, `pipeline/review_ui/index.html`, `docs/REVIEW.md`,
    `tests/python/test_review.py`, `tf review` / render gating in `pipeline/tf.py`,
    `"review"` key handling, `episodes/supermarket_silence/review/suggestions.json`.
  - Fab assets: 7 packs in `pipeline/asset_packs.json` (+ `split_roots` support in
    `godot/tools/catalog.gd` and `godot/scripts/world/kit_db.gd`), `library/catalog.json` (606 models),
    `docs/ASSET_PIPELINE.md` (Fab section), `specs/sets/freshway.json` (view fixes).
  - `.gitignore` additions (review media ignored; decisions/suggestions kept), this file.
- Never commit: `.env` (Gemini key, git-ignored), `incoming/`, `godot/assets/`, `output/`.

## Next steps, in order

1. **Ask the user** whether to commit the uncommitted work above, and how the review is going.
2. **Review loop** (`docs/REVIEW.md`): the user runs `python pipeline/tf.py review serve supermarket_silence`,
   approves or requests changes gate by gate (Environment → Characters → Script & voice → Shots), and
   says "review done". Then run `python pipeline/tf.py review notes supermarket_silence`, apply every
   note and every ticked suggestion, re-run `tf review prepare supermarket_silence --gate <changed gates>`,
   update `review/suggestions.json` (drop what's done, add new critique after looking at the media),
   and tell the user what changed.
3. **Use the Fab assets in the supermarket set** (probably the first Environment change). Proposed:
   a kit `library/kits/supermarket.json` + `"kit"` param in the supermarket generator/builder
   (procedural boxes stay as the `primitive` fallback). Roles from `library/thumbs/_sheets/fab_store_racks_1.png`:

   | Role | Model id |
   |---|---|
   | aisle gondola (double-sided) | `fab_store_racks/Store Racks Pack#Cube_018` |
   | wall shelf | `fab_store_racks/Store Racks Pack#Cube_016` |
   | end cap with sign | `fab_store_racks/Store Racks Pack#Cube_007` |
   | upright fridge (glass door) | `fab_store_racks/Store Racks Pack#Cube_020` |
   | chest freezers | `…#Cube_036`, `…#Cube_027` |
   | checkout counter (belt) / register | `…#Cube`, `…#Cube_011` |
   | deli counters / produce bins / crate display | `…#Cube_049`, `…#Cube_031` / `…#Cube_005` / `…#Cube_040` |
   | shelf products | `fab_cartoon_food/*` (bottles, cartons, bread…; skip `All_Food`), `fab_lowpoly_food/*` (milk, snack bag, yogurt, chocolate) |
   | carts / baskets | `fab_shopping_cart/5_shopping_cart`, `fab_shopping_basket/Shopping_Basket` |
   | debris ("trapped for 7 hours") | `fab_garbage_bin/garbage_bin_trash_bags`, `fab_cardboard_box/cardboard_box` |

   Ids are exact (Godot turned the `.` in node names into `_`). Sizes are in metres except
   `fab_garbage_bin` (centimetres: 671 × 277 × 416 → scale 0.01). Fixtures: gondola 1.88 × 2.31 × 1.3 m,
   checkout 1.84 × 0.91 × 1.2 m, cart 0.78 × 0.81 × 0.49 (a bit small: scale ~1.25). Fixtures are orange/cream low-poly: consider recolouring to fit the night look.
   Keep MultiMesh for products (`KitDB.parts`). After the change: `tf preview-set specs/sets/freshway.json`,
   look at the contact sheet, then re-prepare the env, cast and shots gates.
   The CC-BY packs (basket, garbage bin, cardboard box) need these credits in the video description:
   see the `"credit"` fields in `pipeline/asset_packs.json`.
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
