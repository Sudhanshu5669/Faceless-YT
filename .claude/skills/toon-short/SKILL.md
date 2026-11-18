---
name: toon-short
description: Direct a TownForge YouTube Short end to end: toon actors with swappable drawn faces in realistic, cinematically lit Godot sets, narrated "Imagine you're…" / true-story scripts, every noun and number landing on its word. Covers pitching, scripting, beat sheets, sight gags, cinematography (9:16 framing, lenses, moves, lighting, coverage), realism (places, materials, crowds, factual accuracy), motion, asking the user to download assets, the shot-by-shot review loop and the final render. Use when planning, scripting, storyboarding, building, fixing or reviewing any episode, or when asked for a video "like afterhourtheories", "in the toon style", "more cinematic" or "more realistic".
---

# Toon Short: the director's playbook

You are the director. The engine executes. You write JSON specs and gag scripts; Godot builds
the world, films it and renders the video. Specs name places (anchors), never raw coordinates for
objects (AGENTS.md rule 1).

**The house style in one breath.** Narrated fast and in second person or as a true story. Toon
characters (sphere heads, drawn faces that swap to act) **do physical things to real objects in
real-looking places**. Every noun appears on its word and every number is a counter that lands on
the spoken number. The camera never stops moving; light is dramatic and motivated; the end loops
back to the opening. Quality bar: the channel @afterhourtheories, pushed further toward realism.

**Toon actors, realistic world.** The people are stylised; everything around them (the tunnel, the
lane, the rig, the light, the dust) must look like the real place. That contrast is the channel's
look. "Not realistic" and "not cinematic" are the two verdicts that sink shots: the references
below exist to prevent them.

## Read before you work

| When you are… | Read |
|---|---|
| writing a pitch, script, beat sheet or inventing the gag for a line | [references/script-and-gags.md](references/script-and-gags.md) |
| placing a camera, choosing a lens, cutting a sequence, lighting a shot | [references/cinematics.md](references/cinematics.md) |
| building or dressing a place, a machine, a crowd; checking facts | [references/realism.md](references/realism.md) |
| animating anything (gags, props, procedural poses) | [references/motion.md](references/motion.md) |
| needing a model, texture, HDRI, sound, font, logo or Godot add-on you don't have | [references/assets.md](references/assets.md) |
| looking up shapes, expressions, set options, sounds, transitions | [references/vocabulary.md](references/vocabulary.md) |

Engine specs live in `docs/` (CAMERA_SPEC, TIMELINE_SPEC, REVEALS_SPEC, GAGS_SPEC, MOTION_SPEC,
TOON_SPEC, ACTOR_SPEC, AUDIO_SPEC, LOOK_SPEC, SET_SPEC, ASSET_PIPELINE). The skill tells you what
to make; the docs tell you how to write it.

## The user's standing rules (non-negotiable)

1. **Shot-by-shot approval** for a new episode: build one shot, show it (`tf shot <ep> <name>` or
   the browser page `tf shot <ep> --serve`), get approve / changes / reject, then the next. Once
   an episode's look is approved and the user says to keep going, build the rest autonomously,
   self-review every shot and present them together. Never batch-render for a first look.
2. **9:16 framing:** nothing important is cut off. Stack things vertically, never spread them
   left/right. `tf framing <ep>` must report nothing before a shot is shown.
3. **Action, not apparition:** each line is a mini scene in which someone *does* something to an
   object in a recognisable place, and the camera lands on the result. Nothing pops in uncaused.
4. **Real references, faithfully:** real logos, caricatures of real people, recreations of real
   tweets and headlines with real numbers. Facts and quotes must be accurate and sourced; never
   invent a quote or a post.
5. **Every beat in its own place:** build and dress the place the story names. Reuse a set only for
   a deliberate callback.
6. **No labelled cubes:** show the real object (a film reel, a recharge card, the company's real
   sign). Text only where text exists in reality.
7. **Reuse before you build, and ask before you download:** search the catalog first; propose free
   packs (with name, source, size and licence) and wait for a yes. See references/assets.md.
8. **India-first sets** (no plain blue grid or tile), dramatic light, soft continuous motion, held
   props really held.
9. **No generative image or video services.** Everything is rendered by Godot.
10. Commit directly on `main`.

## The workflow

1. **Pitch** three angles (hook, title, escalation, ending); the user picks one.
2. **Script** with the formula in references/script-and-gags.md. Check every fact and number and
   keep the sources. The user approves the script.
3. **Beat sheet** (`episodes/<id>/beats.md`): per line, the gag, the place, what lands on which
   word, faces, camera and sound. Every row needs a word-anchored action or a face swap.
4. **Places, cast and assets.** List every place, character and hero prop the beats need. Run
   `python pipeline/tf.py props <words>` and `tf library`. For anything missing, prepare an asset
   request (references/assets.md) and ask the user **once, batched**, before building.
5. **Voice first:** `tf voice <id>` (one take for the whole script; words timed by forced
   alignment). Shot timing comes from the real narration, never from guesses.
6. **Build each shot:** the set or gag (`episodes/<id>/gags/*.gd`), actors and cues, the camera
   (references/cinematics.md), light and atmosphere (references/realism.md), motion phases
   (references/motion.md). Generate `episode.json` from `episodes/<id>/make_episode.py`.
7. **Self-review, then show:** `tf shot <id> <name>`; look at 8 evenly spaced frames, one frame at
   full size and one brightened; `tf framing`; `tf test`. Fix what you see before the user sees it.
   Record the user's verdict with `tf shot <id> <name> --decide …`.
8. **Final render** once every shot is approved: `tf render <id>` (1080×1920, 60 fps, motion blur).
   Watch samples of the finished MP4. Then the thumbnail, title and description (with CC-BY credit
   lines for any pack that needs them).
9. **Grow the library:** save good looks (`tf look save`), shot templates (`library/shots/`),
   generic gags (`library/gags/`), and add new lessons to this skill's references.

## Shot checklist (before the user sees anything)

- [ ] The action reads from three stills (start, contact, settle) with no effects or captions.
- [ ] Someone causes what happens; contacts land on their words; the payoff holds ≥ 0.4 s, still alive.
- [ ] The place is the one the story names, dressed with real objects, signage and wear.
- [ ] Lit like a film set: motivated key, rim/back light, faint fill, subject brightest, air (fog, dust).
- [ ] The camera moves with purpose; the lens suits the shot; there is foreground/midground/background depth.
- [ ] Faces are readable (grey with shading, not a white disc) and fill 15 %+ of the frame in character beats.
- [ ] Nothing important is cut off in 9:16 or hidden under the captions (lower third) or the Shorts UI (right edge).
- [ ] Facts, counts, dates, logos and quotes are accurate and sourced.
- [ ] `tf framing` is clean and `tf test` passes.
- [ ] Compared side by side with an approved shot of the same episode: no less depth, contrast or motion.

## Episode checklist

- [ ] The hook lands in the first 2 s; the hook is several shots, not one static wide.
- [ ] Mean shot ≈ 1.5–2.2 s; no static shot over 4 s; at most one or two slower breathers a minute.
- [ ] Counters land on the spoken number, then `ding`.
- [ ] Faces swap every ~0.4–1.5 s in character beats and match the line's emotion.
- [ ] The ending loops to the opening set (transformed) or lands a clear final image.
- [ ] Sound: a bed under everything plus about one effect per second; −14 LUFS.
- [ ] Every downloaded asset has its LICENSE kept and its credit line in the video description.
