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

### The gag script: `episodes/jio_story/gags.md` (2026-11-12) — THE PLAN
One gag per narration segment (52), narration unchanged (cached take). Each row: the gag, on which
word, and the gag code it needs (library vs episode); a build order for the gag library; the real
logos/posts to fetch (ask the user before downloading, sources in library/logos/SOURCES.md; verify
quotes). Waiting for the user's notes on it; then build the gag library in that order and redo the
shots one at a time in the shot loop.

### Reuse before build (user, 2026-11-12) + candidate downloads (NOT fetched; ask the user first)
`tf props <words>` searches `library/catalog.json` (627 models: Quaternius downtown/nature/fantasy
props, Kenney cars/suburban/characters, Fab food/store packs). Missing for the gag script: cows and
animals (#9), cannon (built as a gag), rocket (#31), boats/raft + water (#44), money truck/scooter
(#46-47), a turnstile, a hamster. Candidate CC0 packs to propose to the user (verify licence + size
at the time): Kenney "Pirate Kit" (cannons, boats, barrels), Kenney "Space Kit" (rockets), Kenney
"Car Kit"/"Food Kit"/"Furniture Kit", Quaternius "Ultimate Animated Animals"/"Farm Animals"
(cow), Quaternius "Ultimate Spaceships", Poly Pizza CC0 items; Godot add-ons (MIT/CC0) for a
water surface + simple buoyancy. Import packs with `tf assets import` (docs/ASSET_PIPELINE.md).

### Shot loop progress (2026-11-12)
Shot 1 `open` (crude through a straw from an oil drum: `gags/straw_barrel.gd`; name over the head),
shot 2 `empire_items` (✅ approved), shot 3 `lost` (REDONE after the user disliked the bouncing
phone: the dream is a red balloon carrying a phone that slips from his hand on "lost" and floats to
the sky, `library:balloon`), shot 4 `tribute` (`library:balance_scale`: phone pan crashes, then rises
above the 50-paise postcard on "less") and shot 18 `buy95` (cash cannon pilot) are rendered and pass the framing
check; waiting for the user's verdicts. Also done: shot 5 `split` (tug-of-war over the cake, `toon_kokilaben` referees with a whistle; sfx
`whistle`, `rip`), shot 6 `anil_phone` (Anil walks off with his half crowned by the Infocomm tower).
Shots 7 `no_telecom` + 15 `deal_ends`: a new bay `infocomm` (Reliance Infocomm's lobby: blue panels,
brand sign + slogan, planters) with `library:door` (TELECOM / ANIL ONLY slams + padlock; in 2010 the
lock pops and it swings open). The user's rule: never park a beat in an existing set (AGENTS rule 9).
The catalog lacks modern office furniture: propose Kenney "Furniture Kit" (CC0) to the user.
Shot 8 `watch`: a new bay `chai` (night chai stall: catalog stall cart, pot, bench, mug); Mukesh
(`mw`, sitting) behind an ECONOMIC TIMES "TELECOM BOOM!" paper, binoculars poke through, push-in POV.
(The framing warning on the binoculars there is the intended push into the lenses.)
Shot 9 `street_2g`: the crowd jumps with their phones hunting signal (cue action jump), a man climbs
a palm tree (catalog PalmTree_1) with a "1 BAR" sign, 2015 / 2G centred; crowd spinners removed.
Shot 10 `price`: a new bay `recharge` (mobile-recharge shop: counter, signs), `toon_shopkeeper`
(moustache), a small golden `library:balance_scale` weighing a glowing 1 GB cube, ₹250 PER GB counter.
Shot 11 `buffer` (2026-11-12): continues in the recharge shop. The customer turns to us and taps play
on "video" (loading ring pops over his head); `library:snail` inches along at his feet dragging a
rolling film reel; `library:beard` grows from "buffers" and hits the floor on "forever" (squash, curl,
moustache, cobweb by his head); shot `"hold": 0.7` lets the payoff land. Waiting for the user's verdict.
Next: shot 12 `rivals`.

**Motion rules (2026-11-12):** docs/MOTION_SPEC.md + `godot/scripts/timeline/motion.gd` (phases, easing,
squash, arcs, wobble, trauma shake). Shot keys `shake` and `hold`. Reveal `pop`/`drop` squash & stretch
now (text/counters rigid). Installed skills: disney-animation-rule-skill, game-feel, animation-principles.

**No generic labelled cubes (user, 2026-11-12, AGENTS rule 10).** Debt in earlier shots to fix when
revisited: shot 10's cyan "1 GB" cube on the gold scale (→ a recharge scratch card / data voucher),
the street snail's "DATA" box (shot 9 reveals `snail`/`snail_data`), the purple INFOTEL box (shot 18),
and any other `shape: box` + `label` stand-in (grep make_episode.py for `"label"`).
The framing check now ignores whip-pan and iris moments.

### Gags: built (2026-11-12) — read docs/GAGS_SPEC.md
Episodes can now ship custom GDScript set pieces (`"gags"` in episode.json; `godot/scripts/timeline/
gags.gd` loads `episodes/<id>/gags/*.gd` or `library:<name>`; `build()` + `pose(t)` pure in time;
anchors `<id>.<name>`; params with word-time refs resolved by `episode_audio.py`). Library:
`library/gags/cash_stream.gd` (arcs + growing heap, MultiMesh). Pilot: jio_story shot `buy95` in a
new bay `office`: Mukesh's gold cash cannon (`episodes/jio_story/gags/cash_cannon.gd`) rolls in,
fires on "buy" with recoil + flash, 360 bills bury the Infotel rep (`toon_nerd`) to the chin, a
"95% STAKE" flag drops on "95". Rendered in the shot loop, waiting for the user's verdict.
The other model's `episodes/jio_story/beats.md` (action beat sheet for all 24 lines) is committed:
use it as the plan; push its ideas further toward the reference's absurd literal metaphors.
Next gags worth building into the library: a rope/cord pull (hauling something huge), a UI card
(tweet / headline / phone screen with real text and counters), a stamp, a conveyor, a crowd surge.

### THE REAL GAP (user, 2026-11-11, latest): our pipeline is reveal-driven, theirs is action-driven
The user: "not just the lighting, even their animations are better and the way they are referring
to stuff, like how they bought Scale"; "there is something very concrete about the way their
pipeline makes stuff and ours". Frame study of the reference's Scale AI beat (0:18-0:27, "you pay
$14 billion just to bring in Scale AI's founder... then you spend $2 billion to buy Manus"):
1. **Characters DO things to objects, with consequences.** Zuck fires a money CANNON (recoil) →
   hundreds of bills fly in arcs → they PILE UP and bury Alexandr Wang → he pops out grinning.
   Ours: things pop into existence beside a static character. **Every line should be a mini scene
   "subject verb object (at a place) → result", not a list of reveals.**
2. **Specific, recognisable references, not generic tokens.** The scene is Scale's office (a SCALE
   logo sign on the wall, a plant), the founder is a caricature of the real person, and the proof is
   his REAL tweet on a phone with a likes counter climbing 18K → 120K → 402K. Ours: a purple box
   labelled INFOTEL, floating 3D text "FACEBOOK". (**The user approved real logos, caricatures and faithful
   recreations of real tweets/headlines** on 2026-11-11; logo files go in `library/logos/` + SOURCES.md.)
3. **A protagonist travels through the story carrying props.** Zuck WALKS into the next set (an "AI
   STARTUP" storefront) carrying a $ money bag and drops it on the desk: continuity across shots.
   Ours: a separate static Mukesh per bay.
4. Camera follows the action (low angle on the cannon, the pile growing, then the next set).

**Engine work this implies (do this before polishing more shots; it's what the user is asking for):**
- `moves` to an ANCHOR, not just `by` offsets: `{"t", "to": "<actor>.hand" | anchor, "arc": h,
  "dur"}`, so props pass between characters (give / throw / receive) and land where people are.
- A **stream / burst** reveal: N copies of a shape emitted over time from a source anchor with
  ballistic arcs and gravity, landing and PILING (a heap that grows over a character); for cash
  cannons, confetti, rain of phones, sparks. Deterministic (seeded), MultiMesh for performance.
- **Props that travel with actors**: already possible (reveal `at: "<actor>.hand"` + actor `route`);
  use it: carry bags, phones, boxes between sets; actor cues `action: "carry"/"walk_carry"`.
- **Recoil / squash** on props: a `moves` "punch" (scale pulse) and short shake for cannons, impacts.
- **UI cards with real content**: tweet / news headline / phone screen / bank receipt as a textured
  panel rendered in Godot (SubViewport + Labels: avatar, name, handle, text, counters that climb
  on words). The style's "evidence" beats.
- **Entity identity kit**: per company a plaque/sign style (brand colours + simple mark), per real
  person a toon caricature (hair, glasses, outfit) used consistently; sets that are THEIR place
  (office sign, storefront) instead of a generic bay.
- The director (LLM) then writes each line as an action beat in make_episode.py: who, verb, object,
  where, and the result the camera lands on.

### Look-dev pass: progress (2026-11-11, late)
Done and committed: stage bays take `"mood": "dramatic"` (stage_generator/stage_builder
`_lights_dramatic`: tight warm key pool, coloured rim spot from behind, side kicker, dim wall washes,
weak fill); new look `library/looks/toon_drama.json` (low ambient, SSAO, bloom threshold 1.1,
contrast, vignette); toy-plastic sheen + Fresnel rim on every `Toon.material` (roughness 0.42,
`rim_enabled`); jio_story uses toon_drama, all bays dramatic, and `cam()` adds `"dof":
{"strength": 0.45}` to every shot. Shots 1-2 re-rendered (v3 in the shot loop; older versions in
`review/shot_loop/versions/` for before/after). Result: background blur + sheen + rim read well,
faces readable. **Still to do, in order:** (a) the bazaar/haveli backdrops are self-lit and stay
bright: in dramatic mood dim the backdrop's emissive windows/tube lights and darken its paint
(stage_builder `_bazaar`/`_haveli`), so the subject is the brightest thing; (b) rounded/bevelled
meshes for the reveal shapes (`reveals.gd` `_box`/`_cyl`), (c) composition rules + pose library +
mouth flap + 2D overlay layer + particles (see list above). Show the user before/after (shots 1-2)
in the shot-loop page and get a verdict before re-rendering further shots.

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
- The old render's PNG frames were deleted (user approved); `renders/frames/timeline.json` is kept
  for `--remix`.
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
