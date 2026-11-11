---
name: toon-short
description: Direct a TownForge Short in the house toon style (meme stick-figure characters with swappable faces, everything the narrator names appearing on its word, counters that land on the spoken number, "Imagine you're…" scripts). Use when planning, scripting, beat-sheeting, storyboarding or building an episode in this style, or when asked for a video "like afterhourtheories" / "in the toon style".
---

# Toon Short: the director's playbook

You are the director. You write JSON specs; the engine executes (AGENTS.md rule 1: no raw
coordinates for objects, anchors only). This style was reverse-engineered frame by frame from
the reference channel (@afterhourtheories, "How Facebook will win the AI race?": 155 s,
86 shots, mean shot 1.8 s). Vocabulary references: `docs/TOON_SPEC.md` (characters, faces),
`docs/REVEALS_SPEC.md` (reveals, counters), `docs/TIMELINE_SPEC.md`, `docs/AUDIO_SPEC.md`,
`docs/CAMERA_SPEC.md`.

## The style in one breath

A second-person "what if / imagine you're…" hypothetical, narrated fast. Cartoon stick figures
with big white heads whose **faces swap** to act. Every sentence is a **literal sight gag**,
every noun **appears on its word**, every number is a **counter that lands on the spoken
number**. The camera never stops moving, and the end **loops back to the opening shot**.

## The ten rules

1. **Show every noun on its word.** A list in the narration becomes items arriving one per word
   ("Facebook, Instagram, WhatsApp" = three things dropping in, each on its name). Use reveals with
   `t: {"line", "word"}`.
2. **Numbers are counters** that run up and **land exactly on the word that says the number**,
   then flash yellow. Add a `ding` at the landing.
3. **Make every metaphor literal.** "Losing the race" = rowing a cardboard box while rivals have
   speedboats. "Clone Twitter" = a photocopier. "AI hungry for data" = a crying baby robot fed
   bottles. Write the gag down before anything else.
4. **Faces do the acting.** Swap expressions every 0.4–1.5 s during character beats (smug →
   star_eyes → shocked). Bodies stay simple: idle, talk, phone, walk, cheer-like actions.
5. **One idea per shot, ~1.8 s per shot.** Range 0.5–4 s. A slower shot (3–4 s) is a deliberate
   breather after a fast run, at most one or two per minute.
6. **The camera always moves.** The default is a slow push-in (`from` → `to`, `in_out`). Reveals
   get a push toward them, and big statements get a pull-back reveal of scale.
7. **Reuse sets.** One "dossier" space can carry 30 s while cards pile up. A pedestal stage
   serves every product or company comparison (same shot, swapped object = A/B/C comparison).
8. **Escalate.** Each beat is bigger than the last (more cards, more money, bigger numbers). End
   the list on the biggest.
9. **Pun or twist at the end, then the bookend:** cut back to the opening set, now
   transformed (box → speedboat). There's no outro or end card, so the Short loops.
10. **Captions:** 1–2 words at a time (`"captions": {"max_words": 2}`). Sound: a bed under
    everything, plus about one effect per second (`pop` on reveals, `whoosh` on fast moves,
    `ding` and `cash` on wins).

## Workflow

1. **Script.** Use the formula below. 130–170 s for a Short, about 150 words a minute. Read
   it aloud: every sentence must suggest a picture. Check every fact and number; the reference's
   credibility comes from real figures.
2. **Beat sheet** (write it in the plan or `episodes/<id>/beats.md` before any JSON):

   | # | Line (exact words) | Gag / metaphor | On screen, on which word | Faces | Camera | Sound |
   |---|---|---|---|---|---|---|
   | 1 | "Imagine you're a tech billionaire…" | Glass tower at night | boss appears on "billionaire" | smug | push down the tower to the office | whoosh |
   | 2 | "…but you're losing the AI race." | Boss rows a cardboard box past speedboats | box on "losing", boats on "race" | smug → shocked | dolly alongside | splash/pop |

   Every row needs at least one word-anchored reveal or a face swap. If a row has neither, rewrite it.
3. **Cast.** Use the `toon_*` characters (`python pipeline/tf.py library`), or add one in
   `library/characters/` (`toon` block, docs/TOON_SPEC.md). Prefer archetypes ("a tech
   billionaire") over named real people unless the user asks for a specific person: caricaturing
   real people and using real logos is the user's call, so ask.
4. **Build `episodes/<id>/episode.json`**: lines (with `shot`), shots (`"duration": "fit"`),
   actors with `cues` (`expression`, `action`), `reveals` (props, shapes, text, counters), `sfx`,
   `captions`. Times are word references, never hand-typed seconds.
5. **Look before rendering:** `python pipeline/tf.py storyboard <id>` and read
   `episodes/<id>/preview/storyboard.png`. Check that each reveal is visible in its shot,
   counters are readable, faces read at Shorts size (a face should fill 15 %+ of the frame
   in character beats), and nothing is clipped by the caption band (lower third).
6. **Review board** (docs/REVIEW.md), then `render`. After rendering, look at the video
   (frame strip, see CLAUDE.md).

## Script formula

```
HOOK (0–5 s)      "Imagine you're <famous role>, but <you're losing / something is wrong>."
STAKES (5–15 s)   The rivals / the problem, in 2 short sentences. Then the hidden advantage:
                  "But they don't know your <secret>."  + one hard number.
ESCALATION        "So you <action>." "Then you <bigger action>." "Now you need <X>, so you <Y>."
(15–120 s)        6–12 steps, each a picture, each with a real fact/number. Group into 2–3 acts.
                  Mid-way, a "the insane part?" turn that raises the stakes.
COMPARISON        "<Rival A> knows <x>. <Rival B> knows <y>. But <you> know <z>."
PUNCHLINE         A pun or twist on the title ("…that's why you call it Facebook.")
BOOKEND (last 3 s) "Now you have won."  Back to the opening set, transformed.
```

Voice: second person, present tense, short declaratives, rhetorical questions, light
irreverence. No intro, no "in this video", no outro.

## Vocabulary you can use today

- **Characters:** the `toon_*` cast; hair, outfits and accessories are listed in docs/TOON_SPEC.md.
  All actions in `library/actions.json` work on toons.
- **Expressions** (actor cue `"expression"`): `smug`, `deadpan`, `side_eye`, `scheming`, `wink`,
  `happy`, `laugh`, `grin`, `cheer`, `star_eyes`, `love`, `shocked`, `panic`, `surprised`,
  `nervous`, `angry`, `furious`, `sad`, `crying`, `dead`, `sleepy`, `thinking`, `determined`, `cool`.
  The "true face" gag is a cut to `toon_boss_evil` (green skin, `grin`).
- **Reveals** (docs/REVEALS_SPEC.md): shapes `box sphere cylinder cone ring coin card cash bottle
  pin chip phone`, any catalog prop, 3D `text`, `counter`. Entrances `pop drop rise slide_left
  slide_right beam grow`. `spin`, `bob`, `glow`. A reveal's `at` can be an actor anchor
  (`"boss.hand"`), so things sit in hands and float over heads. Reveal ids are camera anchors.
- **Story shapes:** `refinery pump postcard scales frame garland cake cake_half binoculars sign
  spinner tower` (+ `label` text on card/sign/cake/pump/postcard/box), `roll` (spin in the
  frame plane, for spinners), `enter: "move"` with `from: [x,y,z]` (slide in from an offset).
- **Sets, India-first (the user does NOT want the plain blue grid/tile look anywhere):** street
  scenes use wall `bazaar` + floor `road` (painted shop row, signboards incl. Hindi, autos,
  wires and fairy lights); interiors use wall `haveli` + floor `marble` or `wood` (arched windows,
  pillars, toran, lanterns; `"sides": true` for a room). Reveals: `moves` [{t, by, dur, turn}]
  slide things after they appear (e.g. a cake made of two `cake_half`s that slide apart);
  `plaque` (+ label) for name plates. Anchor offsets are [right, up, forward]: facing +z, right
  is world -x.
- **Sets (all options):** `generator: "stage"` (specs/sets/jio_stage.json is the example): bays with
  floors `checker tiles grid wood plain carpet`, walls `tiles panels plain grid brick skyline none`,
  neon `ring tubes strip arch frame`, pedestals `neon drums cash crates plain`. Anchors:
  `<bay>`, `.left/.right/.back/.front/.wall/.sky/.pedestal`. Look: `neon_night`.
- **Transitions:** shot `whip_in` / `whip_out`: `left|right|up|down` (adds a whoosh); set
  `"format": {"motion_blur": 3}` for real motion blur. Captions: `"captions": {"style": "toon"}`.
- **Music:** bed `beat` (`"ambience": [{"sound": "beat", "gain": -19, "duck": 0.55}]`).
- **Voice:** `gemini-3.8-flash-lite-tts`, `batch_words: 16` (long takes get cut off).
- **Sounds:** `pop`, `whoosh`, `ding`, `tick`, `cash`, `thud`, `click`, `sting`, plus beds.
- **Camera:** shots and moves (`from`/`to`), lenses, anchors, templates (`tf library`).
- **Looks:** `dusk`, `night_fog`, `day`, … (the neon night look is not built yet; use `dusk` or
  night looks for now).

## Not built yet

If a beat needs one of these, approximate it with what exists and note the gap in your
report. Don't fake it with coordinates.

- Push-through / light-tunnel transitions (whip pans exist).
- A sunburst "shock" background, UI cards with real content (profiles, chats, posts), red link
  lines between cards, a real Indian map.
- Crowds of reveals (cash rain, many cards), and a bold display font for text and counters.

## Checklist before you call an episode done

- [ ] Every line has a picture, and every noun or number has a reveal or counter on its word.
- [ ] Counters land on the spoken number and then `ding`.
- [ ] Faces swap at least every ~1.5 s in character beats, and match the line's emotion.
- [ ] Mean shot ≈ 1.5–2.2 s; no static shot over 4 s.
- [ ] The opening hook lands in the first 2 s, and the ending loops to the opening set.
- [ ] Facts checked; real people and logos only if the user asked.
- [ ] Storyboard viewed, reveals visible, faces readable, nothing under the captions.
- [ ] When a new look, shot or face preset is good and reusable, save it to the library.
