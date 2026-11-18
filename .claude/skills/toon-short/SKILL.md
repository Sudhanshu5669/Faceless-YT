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

11. **Action, not apparition (the user's biggest note).** Each line is a mini scene: a character DOES
    something to an object, in a specific recognisable place, and the camera lands on the result
    (Zuck fires a money cannon → cash buries the founder → he pops out grinning; then Zuck walks into
    the next set carrying a money bag). Things should arrive because someone throws, gives, fires or
    carries them, not just pop in beside a static character. Use the real entity's identity (its
    office sign, brand colours, a caricature of the real founder, its real tweet/headline on a UI card)
    rather than a labelled box. See HANDOFF.md "THE REAL GAP" for the engine pieces this needs.

## Motion craft: how every gag moves (docs/MOTION_SPEC.md)

The reference feels alive because every action has weight. For each beat, before writing code:

1. **One sentence:** who does what to which object, with what force, ending where, feeling how.
2. **Phase table:** rest → **anticipation** (0.12–0.25 s, opposite the action) → action (eased,
   on an **arc**) → **contact on the narration word** → overshoot → settle (`Motion.wobble`).
3. **Weight on contact:** squash with volume kept (`Motion.squash(Motion.impact(dt, s))`) sized by
   force, and a feedback bundle by tier: small (squash 0.15, `pop`), medium (shake 0.4, `thud`),
   large (shake 0.8, flash, `sting`/`cash`). Shake: the shot's `"shake": [{"t": word, "amount"}]`.
4. **Follow-through:** attached parts (labels, flags, tails, signs, hair) lag the body (`f(t - 0.06)`)
   and settle after it. Secondary action starts and ends later than the primary.
5. **Easing:** ease-out to arrive, ease-in to leave, in-out to reposition, `out_back` to pop.
   Linear only for loops. Light things snap (0.15–0.3 s), heavy things lumber (0.5–0.9 s).
6. **Stagger** groups 40–80 ms apart (≤ 0.8 s total); ≤ a third of things moving at once.
7. **Hold the payoff ≥ 0.4 s**, with something still alive (a wobble, a blink, a bob).
8. **Check stills:** the action reads from 3 frames (start, contact, settle) with no effects.

Gags preload `res://scripts/timeline/motion.gd`. For deeper craft, load the installed skills
`disney-animation-rule-skill` (phase blocking, deterministic procedural motion), `game-feel` (impact
juice tiers, trauma shake) and `animation-principles` (curves, durations, stagger).

## Realism and cinematics: what makes a shot pass review (learned on silkyara_rescue, 2026-11)

The user's verdicts on rejected shots were "not realistic", "not cinematic", "moving like statues",
"horrible". Every one of them had the same causes. Check these before showing a shot.

**Stage for the lens, not for the story diagram.**
1. **Decide what must read, then pick the angle that shows it in profile.** A tool pointing at the
   lens is a dot. Hammer → chisel → rock must lie *across* the frame. Faces want a 3/4 front view.
   If the action and the face can't share one angle, put the action low in the frame and the face
   above it (9:16 is tall: use it).
2. **A toon's head is 38 % of its height and its arms are short.** Hands can't work in front of the
   face: they end up behind or inside the head. Work happens *below the chin*; raise the camera until
   the tools drop under the chin line, or lengthen the arms (`Crawl.long_arms(actor, 1.45)`).
   Never shoot a toon from behind/above: you get a helmet and no acting.
3. **Never film a stiff body being slid.** If there is no clip (crawl, haul, dig), pose it
   procedurally: plant hands and knees in the world and pull the body past them
   (`godot/scripts/actors/toon_crawl.gd`: `Crawl.pose`, `Crawl.surge`, `Crawl.arm`). Speed must
   pulse (pull, rest), shoulders roll, the head stays up and nods. A lying person is the `get_up`
   action frozen at 0, not an upright idle rotated onto its back.
4. **Every blow has four parts** (docs/MOTION_SPEC.md): wind-up (ease-out, ~0.24 s), strike
   (ease-in, ~0.1 s, contact ON the word), recoil (the tool bounces), consequence (body jolts,
   face swaps to `strain`, chips + dust + 0.2 shake, the thing struck moves). The third hit pays
   off (the stone splits).
5. **One hero prop, exaggerated ~1.3x.** Tools sized true to life vanish beside a 0.6 m head.

**Light like a film set.**
6. **Motivate every light, and use three depths:** a key from a practical in the scene (headlamp,
   hand lamp, flood), a rim/back light from another practical behind the subject (the man behind
   him, the lit mouth of the pipe), and a faint fill so blacks keep detail. Subject brightest,
   surroundings dark, never flat ambient.
7. **White toon heads clip fast.** Keep any light within 1 m of a face under ~0.4 energy and check
   the face is grey-with-shading, not a white disc. A headlamp's *lens* glows (emissive + bloom);
   its *beam* is a separate spot aimed at the work, never into the lens.
8. **Air makes depth:** volumetric fog (0.015–0.02) so beams show, additive dust motes, a soft puff
   on impacts. Additive only: unlit shaded motes read as dirt specks on the wall behind.

**Materials that survive a close-up.**
9. **No `metallic` in enclosed dark sets.** With no sky or probe to reflect, a metal renders black
   and noisy masks turn into black blotches. Use a dielectric with low roughness and high
   `SPECULAR` so the lamps' highlights say "steel".
10. **Noise at the right scale:** large smooth masks (rust, stains) at 0.3–2 cycles/m, stretched
    along the object's grain; grain at 150+ cycles/m at ±8 %. Mid frequencies (5–40 /m) read as
    camouflage. Add the features a real one has (spiral weld seam, butt welds, drag track, mud line).
11. **Thin curved shells don't cast shadows** (set `cast_shadow` off): they only give acne.
12. **Nothing within 20 cm of the lens** unless it is meant to be a blurred foreground frame. A
    pebble 5 cm away is a wall. Clear a niche for the camera when it sits inside rubble.

**Find faults fast.**
13. **Look at 8 evenly spaced frames, then one frame at full size, then one brightened**
    (`ffmpeg ... -vf eq=gamma=2.2`): black areas hide wrong poses. When the layout is unclear, render
    one diagnostic side view with `"exposure": 3.5` and a far camera, then restore the real one.
14. **Isolate before guessing:** swap a suspect material for a flat colour for one render. It tells
    you in 30 s whether a defect is texture, shadow or geometry.
15. **Compare against an approved shot of the same episode** side by side. If yours has less depth,
    less contrast or less motion, it is not done.

## Ideation: the gag for each line (do this before any JSON)

For every narration line, write 3-5 candidate sight gags, then pick one. A good gag is:
- **Literal and physical:** the metaphor in the sentence happens to objects ("needs energy" →
  he hauls a nuclear plant on a rope; "buys the company" → a cash cannon buries the founder).
- **Caused by someone:** a character acts, the object reacts, the camera lands on the result.
- **Specific:** the real company (logo, office sign, colours), the real person (caricature), the
  real artifact (tweet, headline, receipt), a recognisable Indian place where it fits.
- **Escalating** across the episode, with callbacks (the snail returns as a rocket).
- **Readable in 9:16:** cause at the bottom, result on top, or a follow from one to the other.
- **Real objects, never labelled cubes:** "video" is a film reel, "mobile data" is a recharge scratch
  card or a SIM, a company is its real sign/logo/product. A box with a word on it is a placeholder,
  not a gag (AGENTS rule 10). Text only where text exists in reality.
- **In its own place:** where the story happens (a company's lobby, a post office, a recharge stall),
  built and dressed for it. Never park a beat in whatever set already exists; reuse only for callbacks.
Then check `python pipeline/tf.py library`, `python pipeline/tf.py props <words>` (existing models)
and `library/gags/`; for whole systems (water, boats, ropes) look for a free Godot add-on or CC0 pack
first (ask the user before downloading). If nothing fits, write a gag
script (docs/GAGS_SPEC.md: `build()` + `pose(t)`, pure in time) in `episodes/<id>/gags/`.
Example pilot: jio_story shot `buy95` (gags `cannon` + `library:cash_stream`).

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
   `library/characters/` (`toon` block, docs/TOON_SPEC.md). For real stories, caricature
   the real people (`toon_mukesh`, `toon_anil`...) and use the real companies' logos, and recreate
   real tweets and headlines (approved by the user, 2026-11-11: news commentary / free speech). Keep
   the quotes faithful and the facts checked; never invent a quote or a post.
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
  spinner tower rickshaw plaque india crown moneybag vitrine laptop tank receipt podium`
  (+ `label` text on card/sign/cake/pump/postcard/box/moneybag/tank/receipt; `india` is the map,
  flat on the floor, pins by lon/lat: see REVEALS_SPEC.md), moves `tip` (knock over: towers,
  dominoes), counters `"group": "indian"` (3,00,000), `link` lines (red link graphs, hoses),
  `cake_slice bowling_ball globe orbit tape knife`, crowds `"shape": "india"`, routes that run actors
  in on a word (`"route": {"via": [...], "gait": "run", "start": word, "arrive": word}`), `roll` (spin in the
  frame plane, for spinners), `enter: "move"` with `from: [x,y,z]` (slide in from an offset).
- **Sets, India-first (the user does NOT want the plain blue grid/tile look anywhere):** street
  scenes use wall `bazaar` + floor `road` (painted shop row, signboards incl. Hindi, autos,
  wires and fairy lights); interiors use wall `haveli` + floor `marble` or `wood` (arched windows,
  pillars, toran, lanterns; `"sides": true` for a room). Reveals: `moves` [{t, by, dur, turn}]
  slide things after they appear (`tip` knocks them over) (e.g. a cake made of two `cake_half`s that slide apart);
  `plaque` (+ label) for name plates. Don't let a `whip_out` eat a shot's payoff: if the reveal lands in
  the last ~0.4 s of a line, cut instead. Anchor offsets are [right, up, forward]: facing +z, right
  is world -x.
- **Sets (all options):** `generator: "stage"` (specs/sets/jio_stage.json is the example): bays with
  floors `checker tiles grid wood plain carpet`, walls `tiles panels plain grid brick skyline none`,
  neon `ring tubes strip arch frame`, pedestals `neon drums cash crates plain`. Anchors:
  `<bay>`, `.left/.right/.back/.front/.wall/.sky/.pedestal`. Look: `neon_night`.
- **Transitions:** shot `iris_in` / `iris_out`: `binoculars|circle` (the frame seen through a mask that
  opens; push the camera into the binocular lenses at the end of the shot before: a POV cut).
  Shot `whip_in` / `whip_out`: `left|right|up|down` (adds a whoosh); set
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

- Push-through / light-tunnel transitions (whip pans and the binocular iris exist).
- A sunburst "shock" background, UI cards with real content (profiles, chats, posts), red link
  lines between cards, a real Indian map.
- Crowds of reveals (cash rain, many cards), and a bold display font for text and counters.

## Checklist before you call an episode done

- [ ] Every line has a picture, and every noun or number has a reveal or counter on its word.
- [ ] Counters land on the spoken number and then `ding`.
- [ ] Faces swap at least every ~1.5 s in character beats, and match the line's emotion.
- [ ] Mean shot ≈ 1.5–2.2 s; no static shot over 4 s.
- [ ] The opening hook lands in the first 2 s, and the ending loops to the opening set.
- [ ] Facts checked; real logos, caricatures and recreated tweets/headlines are faithful (no invented quotes).
- [ ] Storyboard viewed, reveals visible, faces readable, nothing under the captions.
- [ ] Every action has anticipation, an eased move on an arc, a contact on its word and a settle;
      impacts squash and big ones shake the camera; nothing moves linearly except loops.
- [ ] Nothing pops in uncaused (rule 11), and each payoff holds ≥ 0.4 s with something still alive.
- [ ] When a new look, shot or face preset is good and reusable, save it to the library.
