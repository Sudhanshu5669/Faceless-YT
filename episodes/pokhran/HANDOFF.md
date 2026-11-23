# Pokhran: handoff (read this first to continue the video)

*Last updated 2026-11-23. Update this file after every shot (state, decisions, lessons). The repo-wide
`HANDOFF.md` points here. Also read `AGENTS.md` (the user's standing rules) and the `toon-short` skill.*

**The video:** "India blew up the White House": the true story of Pokhran-II (11 May 1998), told as an
"Imagine you're India's nuclear team" Short (~156 s, 58 shots). Script and sources: `script.md`; the shot
list with the gag for every line: `beats.md` (the source of truth for what each shot shows).

## State

| | Shots |
|---|---|
| Approved by the user (27) | hook_feed … kalam_tape (00–28), except the two below. Verdicts: `review/shot_decisions.json` |
| Fixed after "changes", re-rendered, awaiting the user's verdict | `cricket` (batsman redone: side-on stroke, seen in profile), `jeep_arrive` (redone for FUN: the jeep tears in, hops over the lens, handbrake-slides to a stop in dust; cap no longer clips) |
| Next to build | `an32_land` (NEW place: airstrip), `convoy`, then `wait_row`, `wait_clock`, `wind_turns`, `key_turn`, `desert_jumps`, `khetolai_crack`, `presser_walk`… to `end_feed` (beats.md rows 10–21) |

Check live status with `python pipeline/tf.py shot pokhran --status`.

## The user's decisions for this video (binding)

- **The blast (`desert_jumps`, `two_more`) is an accurate underground test:** the desert heaves into a dome,
  a shock ripple runs across the sand, a towering dust curtain, then the crater collapses. **No mushroom cloud**
  (Pokhran-II was underground; the PM's statement says so). Make it grand and majestic, but true.
- **Workflow:** the look is approved, so build in **batches**. Self-review each shot with storyboard stills first,
  render the full clip only when the stills look right, then present the batch. Don't run long render-fix-render
  loops for a single shot (the user found per-shot loops too slow).
- **Approval UI:** `python pipeline/tf.py shot pokhran --serve` (http://127.0.0.1:8770/). The user watches and
  decides there. Clip looping is an opt-in checkbox, off by default.
- **Notify (standing rule, AGENTS.md rule 1):** ALWAYS send a push notification whenever a shot or batch is done
  and waiting for the user's approval.
- **Power:** the laptop battery is damaged. **Never render when the user says not to, or during a power cut.**
  Check mains power with `Get-CimInstance Win32_Battery` (BatteryStatus 2 = on AC). Commit work before stopping.
- **Blender** (`config.local.json` → `blender`) is for asset work only (vehicles, trees: glTF out). Everything
  else stays in Godot. Never trade away quality (realistic, cinematic world; toon actors).
- **Accuracy:** real people are caricatures. Facts, dates, headlines and quotes must be accurate; never invent a
  quote. Month and year only where the exact day isn't public (the 1995 imagery = "DEC 1995"; the 1998 run-up
  feed = "MAY 1998").

- **Make it FUN (user, 2026-11-23):** "the shots so far are fine but it needs to be more fun". Pick the most energetic
  true version of each gag: speed, exaggeration, slapstick payoffs, whooshes, camera shakes, comic reactions.

## How to work a shot (the fast loop)

1. Read the shot's row in `beats.md` and its line in `make_episode.py` (the `LINES` table: id, shot, lead, text, style).
2. Edit the place module in `places/<place>.py` (actors, gag params, `SHOTS[name]`). Write new set-piece
   behaviour into the place's gag script (`gags/*.gd`) as a documented param; put generic pieces in `library/gags/`.
3. Storyboard just that shot. The scratch helper `sb.sh SHOT` does `make_episode.py` + `tf voice` +
   `tf storyboard pokhran --shots SHOT --scale 0.3333`, then stacks the start/mid/end stills. If the scratch dir is
   gone, run those three commands directly; stills land in `episodes/pokhran/preview/storyboard/`.
4. Look at the stills. Fix, re-storyboard. Then `python pipeline/tf.py shot pokhran SHOT` renders the clip and strip
   into `review/shot_loop/`. Check the strip (or `ffmpeg -vf "select='not(mod(n\,5))',tile=..."` frames).
5. Run `python pipeline/tf.py test` (set TEMP/TMP to `output/test_temp`), commit on `main`, update this file.

## Places, gags and what they can do

| Place (`places/`) | Gag | Frame / notes |
|---|---|---|
| `range.py` | `gags/range.gd` ("range_site") | The White House shaft plate at the origin; cameras usually stand south (+z) looking north. `P(x,y,z)` takes gag-local coords. Era: 1998 by default, 1995 inside `y1995` windows. |
| `office.py` | `gags/pm_office.gd` ("pmo") | The PM's office, South Block: desk top 0.77, the PM sits at (0,0,-0.78) facing +z. |
| `desk.py` | `gags/analyst_room.gd` ("office_us") | The US analyst's office: hero CRT at `SCREEN`, the analyst at (0.25,0,-0.62) facing -z. |
| `orbit.py` | `library:earth` + `gags/orbit.gd` | The recon satellite over India. |
| `lawn.py` | (PM's lawn press conference) | Also feeds the analyst's wall TV. |

**Range params** (documented at the top of `range.gd`):
- **Original set:** carry, wind, shimmer, tufts, bushes, clear, y1995, lower, leave, piles, shovel, drip, dive.
- **Added this session:**
  - `night`: shaded work lamp and hand torches.
  - `park`: a truck reversing onto its own tyre ruts and imprints.
  - `dune`: a heap patted into a barchan dune, with wind ripples from a blower.
  - `net`: a camouflage net flung over a second shaft head.
  - `watch`: the lookout's wristwatch and his list of pass times.
  - `chai`: a glass of tea in hand.
  - `cricket`: a side-on stroke, ball path and tent-peg stumps.
  - `jeep`: a jeep braking to a stop, a seated driver, a cap slip.
  - `disguise`: a patrol cap on the actor's own hair and a name tape.

**Range looks:** LOOK_AFTERNOON (15:45 May), LOOK_1995, LOOK_DUSK, LOOK_NIGHT, LOOK_DAWN, LOOK_DIVE, LOOK_DEEP.

**Analyst room params:**
- `wh`: the hook blast and rewind.
- `rewind`: rolls the stamp back 1998 → DEC 1995.
- `tv`: the wall TV.
- `prints` + `shrug`: two satellite prints on the desk.
- `live`: a live overhead view of any place on the hero CRT, with its own stamp.

**PM office params:** `paper` (the NYT), `photos`, `ring`, `calendar`, `heads` (seated head keys), `sitter`.

**Library additions:**
- `library/gags/sky_pass.gd`: a satellite crossing the twilight sky.
- Camera moves take `start`/`end` time references: the move runs between them and holds before and after.
- `actor.tilt_head()`.

**Characters added for this video** (`library/characters/`):
- the jawans: `toon_jawan_a..d`
- the scientists: `toon_barc_sci`, `toon_sci_fatigues_a/b`
- the leaders and diplomats: `toon_rao`, `toon_wisner`, `toon_vajpayee`
- Kalam and Chidambaram: `toon_kalam` (silver/white mop, blue shirt), `toon_kalam_fatigues`, `toon_chidambaram` (safari suit)

**Assets:**
- `blender/range_assets.py`: khejri, ker, sewan grass, sandbag.
- `blender/vehicles.py`: truck_canopy, truck_flat, jeep.
- Both write to `incoming/pokhran_blender/`.
- Poly Haven textures and models are in `incoming/polyhaven_pokhran/`.

## Lessons (avoid repeating these)

- **`lens_mm` sets the vertical field of view in 9:16.** 24 mm is very wide (73° vertical, 46° horizontal). Work out
  the horizontal half-angle (`atan(0.5625 * 18 / f)`) before placing the cast, so nobody falls off the edge.
- **Shown windows:** an actor's `shown` window must end exactly at the next line (`W(next, offset=0.0)`) or the actor
  vanishes in the last frames. A line can start before its shot, so to appear at a cut, anchor to the shot:
  `{"shot": name, "offset": 0.05}`.
- **Hidden cameras inside actors:** an actor still "shown" near a later shot's camera can put that camera inside a
  head, which turns the whole frame black (the outline shell). End windows before other shots use that ground.
- **Toon heads are huge** (radius about 0.19 × height). Over-the-shoulder shots don't work: the head fills the frame.
  Hold props out to the side, below the head. Arms are short: use `Crawl.long_arms(actor, k)` before `aim_hand`
  to reach above the head.
- **Facing after a route:** a route's arrival facing beats any earlier `facing` cue. Pin the arrival with
  `route.arrive` and put the facing cue after it. Toon walking speeds are slow.
- **Range clutter:** the spoil heap sits around (-5.6, -3.2) and is big. Check what's between camera and subject.
  Use `clear` circles to keep scattered plants off camera spots.
- **Vehicles in other shots:** a vehicle moving in a gag exists in every shot. Hide it until near its own shot,
  or it drives through other scenes (the jeep crossed the cricket ground).
- **Prints and live views:** a SubViewport rendered in a sunless look (the analyst room) needs ambient around 1.5
  plus a distant low spot over the photographed place. Otherwise it comes out black.
- **GLSL:** never call `smoothstep` with edge0 > edge1 (undefined). In GDScript, `:=` can't infer a type from a
  Variant (loop vars over literal arrays, indexing): add explicit types.
- **Patching:** patch files with Python `str.replace` scripts in the scratchpad that assert each anchor occurs exactly
  once. Choose anchors that don't cut a comment line in half.

## Next shots: notes so far

- **`an32_land`:** "The bombs arrive at dawn: flown in from **Mumbai** on an **air force plane**,"
  - New place: Jaisalmer air force station at dawn: a long runway, a low control tower, blast pens, a fuel bowser.
  - Build an AN-32 twin-turboprop in Blender: high wing, grey, IAF roundels, no airline livery.
  - Shot: a long lens down the runway; it touches down in a puff of tyre smoke on "air force plane".
  - Four olive trucks wait with tailgates down.
- **`convoy`:** four olive trucks roll past a khejri in a long line of dust on "army convoy". Reuse truck_canopy and
  the dust puffs; long lens from behind a tree.
- **The test day (13–14):**
  - `wait_row` and `wait_clock` need a NEW place: the control bunker, with a slit window, scientists and a clock.
  - `wind_turns`: the windsock `wind` keys already exist.
  - `key_turn`: macro on the firing key.
  - `desert_jumps`: see the blast decision above.
  - `khetolai_crack`: a NEW place, the village. A water pot ripples and a crack runs up a mud wall.
