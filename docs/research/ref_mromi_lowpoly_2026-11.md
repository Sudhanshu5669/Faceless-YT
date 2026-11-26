# Reference: "How to Make Low Poly Shorts Using Claude" (Mr omi), what we can learn

https://youtu.be/lBh7dN2ts88 · 6:49 · uploaded 2026-11-11 · 22k subscribers, 66k views (2026-11-26).
Transcript (automatic captions, private, git-ignored): `output/research/mromi_lBh7dN2ts88/transcript.md`.
Method: transcript plus sampled frames, mostly every 2 s of the finished short at 4:52-5:50. Sound was not judged.

## Pace

| | Seconds per shot or scene | Words a minute |
|---|---|---|
| His finished short (42 scenes, ~59 s) | ~1.4 (his own scene count) | ~200 (from caption timing) |
| Our silkyara / bombay_gold | 2.4 / 2.5 | script target ~150 |
| Our pokhran / mangalyaan | 2.8 / 3.1 | |
| Our own skill's target | ~1.8 | 130-170 s videos at ~150 |

Mangalyaan is our slowest cut and our best performer, so pace alone does not decide views.

## What his short does

- **One causal chain.** What-if hook, then every line causes the next problem ("but", "so"), ending on a twist.
- **First line is the premise and Frame 1 is already the action** (he jumps through the ceiling).
- **One recurring protagonist** who suffers every consequence; face swaps do the acting.
- **Insert shots** break up the places: a giant stopwatch or scale, an x-ray body, a diagram of the mechanism on a
  flat textured background, a big number on top (x100, 0.03 SEC, 1 IN 3).
- **Hard changes of angle:** feet-only close-up at the contact, tall low angle for height, top-down for the fall.
- **Comparisons made physical:** "an elephant on your shoulders" is an elephant on his shoulders.

## His process

- Kimodo for motion (as we now do); he reports a ~1 GB motion model and ~15 GB text reader. His screen shows an
  interactive prompt with the model already loaded. Our batch runner (`pipeline/kimodo_batch.py`) now does this;
  it saves only about a third, because each prompt still takes 93-112 s.
- Claude renders a still of every scene, checks it and fixes it, four rounds, before the creator looks.
- Sounds: AI-generated effects, checked by Gemini, which invented sounds in one test; the creator finishes by ear.
  His tip: a real scream on a scared face.
- Faces are swapped pictures (we already do this). Photo faces and the low-poly look are his style, not ours.
- The claim of reference shorts with 350 million views is his; not checked. The skill is sold in his paid community.

## Proposed for us (needs the user's yes)

1. Adani: cut to ~1.8 s or less per shot and trim lines; rewrite list lines as cause and effect.
2. A reusable insert stage in `library/gags/` (textured backdrop, one giant object, a big number).
3. A Kimodo batch runner that loads the text reader once for all of an episode's motions.
4. A shot rule: every action beat gets a contact close-up from a new angle.
5. Reaction sounds on face swaps, from our licensed recorded effects.

## His characters (searched 2026-11-26)

100+ low-poly people in a T-pose with photo-textured faces. **The pack was not identified** (not in the
description; a commenter asked for it). **Free only** (user, 2026-11-26), downloadable, licence allows commercial
use by its label. Looks judged from thumbnails; rigs as each page says; texture origins not checked.

| Model | Licence | Rig | Notes |
|---|---|---|---|
| [Male, garwiglino1](https://sketchfab.com/3d-models/4b1f3b3fc7d74f1abdd7c9427e2aa0a9) | CC BY | yes (UE5) | 936 faces |
| [Retro PSX Male Pack, jonniemadeit](https://sketchfab.com/3d-models/82c270a7123a492dae842fa2e9edeed3) | CC BY | not stated | many men, swappable heads and outfits, 44 textures |
| [Female secretary, vinrax](https://sketchfab.com/3d-models/8898a87225604a1fb335b47efff9c088) | CC BY | yes | 932 faces |
| [Male PS1-style, vinrax](https://sketchfab.com/3d-models/78640adbd76b48129e9316259695c742) | Sketchfab Free Standard | yes | "found on my hdd": origin doubtful |
| [PSXprop male 02, WardsterSAW](https://sketchfab.com/3d-models/06f178a3d2894fa6bb774a90af88e64e) | Free Standard | yes, 1 anim | 645 faces |
| [PSX Characters Pack, Shazly](https://sketchfab.com/3d-models/b25e1b712e274d5bb8d95ef121fa773f) | CC BY | not stated | a few men, plainer |

Not this look: Denys Almaral's free samples and RachelC04's "All Characters" are flat-coloured.
