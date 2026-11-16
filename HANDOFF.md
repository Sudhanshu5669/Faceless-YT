# Handoff: where TownForge is, and what to do next

*Last updated 2026-11-15. Read this first in a new session (Claude or Codex), then
`AGENTS.md`, then `docs/VISION_AND_ROADMAP.md`.*

## START HERE: current task (for whoever picks this up)

### Silkyara rescue Short: hook APPROVED, beat 4 revised for review (2026-11-15, latest)

**Progress log (newest first; Claude keeps this current so Codex can continue mid-beat):**
- **Line 12 built (2026-11-16).** "The next day, a camera crawls down the same pipe. For the first time, the world
  sees their faces." Shots 0-25 approved; `scope_faces`, `tv_screen`, `tv_react` approved; `scope_pipe` reworked
  after "why does the camera look disconnected from the pipe", waiting for re-review.
  - `scope_pipe` (3.25 s): chase camera on gag anchor `collapse.scope_chase` (on the pipe axis, 0.3 m behind the
    head, NOT with its judder). The head slides on the pipe floor (lifted to the axis just before `t_out`), its cable
    leaves the back of the head (`_span` stretches a unit cylinder). The pipe interior is lit IN ITS SHADER
    (`PIPE_SHADER`, unshaded: LED pool ahead of the head + daylight from the mouth): scene lights leak straight
    through the thin tube from the tunnel and burn it white. Keep the camera on the axis: 4 cm from the wall, the
    near plane clips through it.
  - `scope_faces` (1.5 s): the scope's POV; line-11 men + `FACES_CAST` crowd and wave (crew role `wave`); faces
    go surprised (FACES_START) -> laugh on "For". LEDs dim after `t_out` so faces don't burn.
  - `tv_screen` (1.0 s) / `tv_react` (1.35 s): the exterior `tv` monitor (SubViewport camera on `collapse.scope`);
    `TV_CAST` (official, engineer, relatives) in a horseshoe. The portal gag now runs AFTER the collapse gag
    so it can read the scope anchors. `tv_watch` was split into these two.
  - **Next: line 13** "The big drill chews in. Twenty metres. Thirty. Forty-seven." (beats.md Act 2: lines
    13-16, then Act 3 rat-hole miners and the rescue, 17-23, then the Vakeel Hasan twist, 24-26). The user asked
    why the story stopped at line 12: it hasn't; 14 lines remain to build.
- **Khichdi shots reworked (2026-11-16), waiting for re-review.** User notes were: `khichdi_cook` "does not look
  realistic", `khichdi_pour` "does not look cinematic and realistic", `khichdi_bottle` "unprofessional and non
  cinematic". Also still waiting: `plan_rig`, `day9_tally` (fixed 11-15) and the unreviewed airlift/rig/narrow shots.
  - Bottles are now **wide-mouth clear plastic bottles** (`SiteKitchen.wide_bottle`, as at Silkyara; thick
    khichdi can't go through a funnel into a narrow PET neck). The funnel is gone. The khichdi top is a lumpy
    surface (`khichdi_surface`) with bubbles, not a flat disc; its shader is double-sided.
  - `khichdi_cook` (`KITCHEN_LOOK`, darker ambient): medium 3/4 shot, the lit tunnel mouth behind the cook. Key is
    a tube light on the front pole, rim is a bulb behind him that backlights the steam. Steam drifts away from his
    face (`steam_pose` wind). He folds the khichdi with both hands on a short karchi (`_karchi_xf` aims a karchi
    at a grip). The pot is lowered (`POT_Y`): toon heads start at ~0.95 m, so hands must sit at ~0.83 m.
  - `khichdi_pour`: overhead food insert. The karchi tips (roll +), a dollop slides into the open bottle, the fill
    rises, two taps on the rim. Eye-level and low inserts failed: the big toon head fills the action area.
    No hand on the clear bottle (it shows through and hides the fill).
  - `khichdi_bottle`: reverse angle from the rubble slope over the narrow pipe's mouth. The bottle slides out
    toward camera, he catches it and holds it up on his left (the side the bulb lights), cap off, steam. A hand lamp
    near the pipe lights the faces. `meal_catch` stepped back to z -15.35.
- **`feed_out` approved. `feed_in` round 2** (user: "since in previous shot we showed food coming in jar, show it
  for this shot as well. dry fruits, puffed rice, all coming in jars"): tunnel gag `_build_jars`/`_pose_jars`, param
  `jars` {from, until, list: [{t, kind rice|fruit, catcher}]}: a wide outlet on the supply line at the valve; on
  "puffed" a red-lidded jar of puffed rice shoots out on a blue air puff into `life_mate`'s hands, on "dry" a
  green-lidded jar of almonds/cashews/raisins into `life_valve`'s; both held up at chest height. The helmet pour
  (param `feed`) is no longer used. Camera now by the wall beside the outlet, facing the men.
- **`feed_out` round 4** (user: "the jar does not instantly start moving when oxygen hits it"): the jar's travel
  was `in_cubic` (zero speed at the hit). It is now an impulse: x = x0 + v0*dt + a*dt^2/2 with v0 = 7 m/s from the
  hit frame, `a` solved so it still reaches x1 at `jar1`. Checked frames around the hit: it leaves on contact.
- **`feed_out` round 3** (user: "i want the camera to come with the food and the oxygen fast"): the camera now
  rides on gag anchor `mountain_section.jar` (just ahead of and beside the jar, looking back), still while the air
  column arrives, then launched with it on "oxygen"; the jar travels 39 m (`xpipe.x1` = TOE_A + 40) with in_cubic
  acceleration; pipe clamps every 1.2 m and the rubble face blur past for speed.
- **`feed_out` round 2** (user: "looks bad. i want it to look like the oxygen is pushing the food"): restaged as
  cause and effect. Camera low beside the cut-open pipe looking back up it; the jar rests big in frame; a blue
  air column (additive box + streaks bunched at its front, `_xp_front`) rushes down the pipe and hits the jar's lid
  on "oxygen" (param `xpipe.hit`, shake 0.3); the jar squashes and is driven out past the camera with the column
  behind it and a pressure ring at the lid. The blue omni light is off (it washed the rubble blue).
- **User review round 1 on lines 7-11 (2026-11-15), changes made by Claude, waiting for re-review:**
  - `feed_out` ("show in a more abstract way that oxygen is travelling through the pipe as blue lines ... a jar of
    food being passed in through the air pressure"): rebuilt as an x-ray of the supply pipe cut open along the
    section plane (`mountain_section.gd` `_build_xpipe`/`_pose_xpipe`, param `xpipe`), 240 blue oxygen streaks,
    a glass jar of puffed rice with a red lid riding them; the camera rides on gag anchor `mountain_section.jar`.
    The old packet/hose staging is gone from the episode (code left in the gag). `feed_in`'s air blast moved to
    just before "puffed" so the jar arrives -> blast -> rice.
  - `plan_rig` ("the right half of the shot is cut"): the camera was seeing past the cutaway's cut plane; it now
    sits at z -1.4 looking deeper into the bore and above the thrust block.
  - `day9_tally` ("tally marks in a weird position"): boxes floating off the wall replaced by chalk decals
    projected onto the lining (`_chalk_texture`), five-gate first then singles, lower and nearer the drawer,
    who draws the ninth with his left hand.
  Shots 12-17, 19-20, 22-25 have no verdict yet. Line 12 is still paused (see the next entry).
- **User back (2026-11-15): reviewing lines 7-11 on the shot-loop board** (`tf shot silkyara_rescue --serve`,
  joined preview `review/shot_loop/pending_lines7to11.mp4`). **Line 12 paused mid-build, NOT rendered:** "The next
  day, a camera crawls down the same pipe. For the first time, the world sees their faces." (voiced, 6.16 s).
  Written but unwired: tunnel gag `_build_scope`/`_pose_scope` (param `scope` {from, t0, t_out, t_stop}: endoscope
  POV inside a 22 m open interior of the narrow pipe, anchors `collapse.scope` / `collapse.scope_ahead`), role
  `wave`; exterior gag `_build_tv`/`_pose_tv` (param `tv`: monitor at `TV_AT` whose screen is a SubViewport camera
  placed at `collapse.scope`). To finish: move the `portal` gag AFTER `collapse` in the gags list (so it can read
  the scope anchors), add a waving crowd at the pipe mouth (crew role `wave`), families at the monitor (exterior
  `appear`), real cameras for `scope_pipe` (~3.4 s), `scope_faces` (~1.5 s), `tv_watch` (~2.6 s), then render.
- **Line 11 built (Claude):** "Day nine. A narrow pipe gets through first, and the first hot meal goes in:
  khichdi, packed in bottles." (The Week: khichdi in bottles through the new 6-inch pipe on 20 Nov.) Five shots:
  `day9_tally` (chalk tally on the -X wall, params `tally`, the ninth stroke drawn by `meal_draw`'s hand),
  `narrow_pipe` (params `narrow`: the 6-inch pipe noses out of the rubble at x -1.6 with dust; a bulb on a pole
  is the key), `khichdi_cook` + `khichdi_pour` (exterior gag `_build_kitchen` at `KITCHEN` (11, 0, 28): tarp,
  gas stove, steaming patila, ladle into a funnelled bottle; new character `toon_site_cook`; exterior param
  `appear` keeps the kitchen crew out of the hook), `khichdi_bottle` (bottle pops out into `meal_catch`'s hands,
  held up by his face like a trophy, cap off, steam). The line-8 cast and mats leave at `MEAL_START`.
  Lesson: the toon `crouch` animation turns the body away; a standing catch reads better. Rubble rocks near
  the toe block low cameras: shoot from above them.
- **Line 10 built (Claude):** "The plan: push a steel pipe through the rubble, wide enough to crawl through."
  Cutaway rescue side (`mountain_section.gd`, `_build_rig`/`_pose_rig`): the line-4/7 rescuers and props retire
  at `PLAN_START` (params `vanish`, `feed_out.until`); `PLAN_CAST` appears. The shared auger rig sits on timber at
  the rubble toe (`RIG_AT`), carriage + casing + flight drive 2.3 m in (`rig.push0/push1`), debris spits at the bite.
  A spare 800 mm pipe (`SPARE_A/B`, open tube, work lamp at the mouth): `plan_crawl` sneaks in and the gag squashes
  him (scale y 0.5) as he enters. Shots `plan_rig` 1.3 / `rig_push` 2.3 / `pipe_crawl` 2.2. The second "through"
  in the line is referenced by word index (`L10(13)`); `"occurrence": 2` also works.
- **Line 9 built (Claude):** narration changed to "A twenty-five-tonne auger drill is flown in from Delhi by
  the air force." (sources agree on IAF C-130J Hercules to Chinyalisaur, 15 Nov 2023, ~25 t; they disagree on
  two vs three pieces). New gag `gags/airlift.gd` on the new `airstrip` bay, placed `AIR_Z = 6000` m out
  (helpers `AIR()` for the strip, `PL()` for points riding with the plane via gag anchor `airlift.plane`):
  valley airstrip by a reservoir, hook conifers, a C-130J lofted from fuselage `STATIONS` (wing, 4 engines with
  prop blur discs, fin with tricolour flash, IAF roundels, sponsons, hinged ramp, `SKIN_SHADER` sag/droop
  while loaded), ribbed hold with a work light on the rig. New shared builder `godot/scripts/world/auger_rig.gd`
  (track, rams, yellow drive unit, casing pipe with spiral flight: nodes `carriage`, `flight`), for lines 10-14.
  - `airlift_hold` (2.28 s, dim `AIR_HOLD_LOOK`): from the cockpit end along the rig; "25 TONNES" counter lands on
    "tonne" with a creak and shake. `airlift_sky` (1.4 s): low camera ahead, the plane against the valley.
    `airlift_ramp` (2.55 s): it passes low over the camera, slams down on "air", rolls, the ramp drops after "force".
  - Engine change: `godot/scripts/main.gd` re-poses reveals anchored to gag anchors after the gags each frame
    (reveals were placed before gags, so "airlift.plane" never resolved). Documented in REVEALS_SPEC. Tests pass.
- **Line 8 built (Claude):** "To stay sane, they walk the tunnel and do yoga." Story time jumps: every hook
  crew member (and the line 6/7 cast) has `until` = `SANE_START`, so the 41 vanish from the post-collapse
  rows; their props hide with them. `full_power` (param) brings the trapped-side lamps back to full.
  - `laps` (2.35 s): `LAP_CAST`, pairs and singles walking away down the lit bore; camera follows at walking pace.
  - `yoga` (2.45 s): `YOGA_CAST`/`YOGA_CREW` on cardboard mats (param `mats`), role `yoga`: arms straight out
    (warrior; arms raised over the head were hidden behind the toon heads), two in tree pose (foot IK to the
    other knee), `yoga_3` wobbles and topples onto his mat ("dead" X eyes, thud), the others laugh.
- **User away (2026-11-15): "keep working and making videos till i come back ... keep up the high quality
  cinematic work for each shot".** Claude keeps building line by line; every new shot waits for the
  user's review in the shot loop. Lines 6 approved ("approved. go on. you're doing a much better work").
- **Line 7 built (Claude):** "Through it come oxygen, puffed rice and dry fruit."
  - `feed_out` (1.35 s, cutaway rescue side, `mountain_section.gd` `_build_feed_out`): `feed_push` (hidden
    before the scene via param `appear`) rams a clear packet of puffed rice (visible grains) into the pipe's
    open end; the engineer `sec_eng` seats the brass coupling of the yellow compressor hose on it just
    before the cut on "oxygen".
  - `feed_in` (3.35 s, tunnel, `tunnel_collapse.gd` `_pose_feed`): the valve was shut off-screen (`valve.close`),
    `life_valve` stepped back, `life_mate` walked over and crouches holding his own hard hat upside down
    (the toon's `hardhat` node is hidden and a duplicate is held, hand IK). "oxygen": a soft blast of grit and
    air, shake 0.2; "puffed rice": 260 grains arc into the helmet (14 % spill); "dry fruit": almonds, cashews,
    raisins on top; faces star_eyes -> laugh -> love.
  - Final renders, framing clean, tests pass. Preview `review/shot_loop/lines6to7_preview.mp4`.
- **Line 6 rebuilt by Claude (2026-11-15, latest):** the user said Codex's shots were not cinematic
  enough. Lines 4 and 5 (`plug_*`, `tunnel_space`) are approved. Line 6 "The lights still work. And so
  does one pipe." was restaged inside the hook's own tunnel (`gags/tunnel_collapse.gd`), not the cutaway:
  - `lifeline_lights` (1.85 s): `life_lamp` inspects the rubble with his headlamp glaring into the lens,
    reaches to the side of his helmet and clicks it off on "lights" (crew `lamp_off`, role `lamp_click`);
    lit by the bore's lamps he goes surprised -> happy. It does NOT switch the tunnel lamps on: they came
    back in the approved `alive` shot, so a breaker gag would contradict it.
  - `lifeline_pipe` (2.4 s): the water main on the +X wall (the construction water line that kept working:
    AP / BBC via The Week) has a gate valve at `VALVE_Z = -6.4` on a branch dropped to hip height.
    `life_valve` grips the red handwheel (role `valve`, hand IK on the rim), spins it a turn and a
    quarter, water bursts out on "pipe" (tearing jet shader, spray, wet film), he turns to camera laughing;
    `life_mate` jumps behind. Not used: an "answering knock" through the pipe (contact was by
    walkie-talkie / a note, so that would be invented).
  - New tunnel gag features: crew `from` (hidden before a scene time, so line-6 actors never appear in the
    approved hook), `lamp_off`, roles `lamp_click` and `valve`, param `valve` {z, open}; `LAMPS` pool 20.
    The spoil heap sits at (3.25, -9.5): keep cameras and props clear of it.
  - Rendered final; framing clean; `tf test` passes. Joined preview of lines 4-6:
    `review/shot_loop/lines4to6_preview.mp4`. **Waiting for the user's verdicts on `lifeline_lights` and
    `lifeline_pipe`.** Next: line 7 "Through it come oxygen, puffed rice and dry fruit." (same valve/pipe:
    rescuers outside push packets in; inside they shoot out of the pipe into hands).
- **Terra handoff (2026-11-15, current):** The user asked to stop this pass and continue in GPT-6.1
  Terra. Fable's five approved hook shots are the quality reference for the episode. The user
  specifically said “use same models and same animation techniques, lighting etc” and wants the
  environment to look as realistic in future shots as it does in the hook. Review the approved
  `00_mountain.mp4`, `01_work.mp4`, `03_collapse.mp4` and `04_alive.mp4` in the shot loop alongside
  each new render. Reuse the existing toon worker rigs and actions, hand IK for props, textured wet
  roadway, stained concrete and steel ribs, practical lamps and motivated movement from the hook.
  Keep hands and held objects readable at phone size. Check the motion in rendered footage around
  release and contact as well as the framing report.
  **Current review state:** The user judged the first `plug_throw` and `plug_catch` previews weak.
  They asked for cinematic, realistic restaging. The revised clips are ready in
  `episodes/silkyara_rescue/review/shot_loop/` as `05_plug_throw.mp4`, `06_plug_catch.mp4` and
  `07_plug_wide.mp4`. Their previous versions are archived by the shot loop. The user has yet to
  see or approve these revisions. The wide shot was refreshed for material and lighting continuity.
  All five hook verdicts remain approved. There is no verdict for the wide shot. No commit was made.
  **What changed:** the hero cameras moved to worker height. The engineer uses the existing throw
  animation and left-hand IK for the reel. The hook now spends 0.26 s in its final approach before
  the catcher takes it on “Sixty”; the hand recoils and the 60 m counter lands on the same word.
  The close-up tape uses low emission and the wide shot brightens it as a measurement guide.
  `godot/scripts/world/silkyara_tunnel_finish.gd` shares the hook's concrete and wet-road shaders
  and rib mesh between `tunnel_collapse.gd` and `mountain_section.gd`. Lighting reuses the hook's
  tunnel look, sodium fixtures and rescue-side cool floodlighting. The approved hook clips were
  used as references, and the hook was not rerendered after extracting the shared finish.
  **Verified:** `python pipeline/tf.py shot silkyara_rescue plug_throw,plug_catch,plug_wide --final`
  succeeded at 1080×1920, 30 fps with two motion blur samples per frame. Framing reported zero issues.
  `python pipeline/tf.py test` passed (42 Godot + 20 Python). Frame review shows some double edges
  on the fastest part of the throw with two samples. Check that in playback first if doing another
  polish pass. The tape throw is an illustrative device for the measurement.
  **Next:** Review the revised line 4 clips with the user and address their verdicts in the shot
  loop. Then build line 5, “Behind it: two kilometres of finished tunnel, eight and a half metres
  high.” Use the approved inside-the-bore hook as the reference for the headlamp sweep up to the
  crown and the receding lamps that establish distance. Line 5 has not been built.
- **Beat 4 review renders ready (2026-11-15):** `plug_throw`, `plug_catch`, and `plug_wide` are
  rendered at 1080×1920 and 30 fps in `episodes/silkyara_rescue/review/shot_loop/` (05–07).
  All three framing checks passed and the rendered frames were inspected at 0.2 s intervals.
  The cutaway gag id is now `mountain_section`, distinct from the `section` bay anchor. The engineer
  launches the tape into fractured rubble, the trapped worker catches it with his near hand as
  the counter and ding land on “Sixty”, and the wide track ends at the lit portal and its red dumper.
  The count appears once, in the catch. The separate wide-shot label was removed because it tracked
  offscreen. All five hook approvals are recorded. The three beat 4 shots await the user's verdicts.
  **Next:** record the user's verdicts, then build beat 5 using the worker's headlamp to reveal the
  crown and draw out the length of the finished bore (see `beats.md`).
  The user specifically wants Fable's approved hook to set the environmental quality bar for future
  shots. Use its practical work lights, concrete lining and site detail as visual references.
- **Beat 4 state (stopped here, usage limit, 2026-11-15):** code is written but NOT rendered or seen yet.
  `gags/mountain_section.gd` (cutaway: cut face, plug, back half of the bore, lamps, pines on top, tape
  + hook + reel), bay `section` added to `specs/sets/silkyara.json`, and in `make_episode.py`: `X()`,
  `SIXTY()`, `SECTION_CAST` (engineer `sec_eng`, catcher `sec_catch`, 3 rescuers, 6 trapped),
  `SECTION_LOOK`, line `plug` (voiced with Qwen, 4.0 s, starts 0.85 s into `plug_catch`), shots
  `plug_throw` 0.95 s / `plug_catch` 1.75 s / `plug_wide` 3.6 s, reveals `plug_count` (0->60 m landing on
  "Sixty") and `plug_span` ("60 m" text over the plug from "rock"), sfx (whoosh, tick run, click).
  **Next:** `python pipeline/tf.py shot silkyara_rescue plug_throw,plug_catch,plug_wide`, look at frames
  every 0.2 s. Expect to tune: the throw cue timing (`T_THROW - 0.42` vs the OverhandThrow release), the
  cameras (lens/framing in 9:16, especially the `plug_wide` track: it must end on the portal glow), the
  counter position, and whether the script compiles (traps listed below). Then show the user the three
  shots for verdicts (rule 1). `tf voice` prints a SoX warning; it is harmless (Qwen still renders).
- All five hook shots approved by the user ("i love the five hook shots"); verdicts recorded with
  `tf shot silkyara_rescue <name> --decide approved`. The user said "lets make the video further".
- Script fixes in `episodes/silkyara_rescue/beats.md`: line 18 now says the 2014 ban was on rat-hole
  coal mining in Meghalaya; line 19 dropped "three at a time, two-hour shifts" (single source). Line 9
  ("flown in from Delhi, in three pieces") stays as written; the narration does not name the air force.
- Assets imported 2026-11-15 (user approved the download): `quaternius_nature_mega` (Stylized Nature
  MegaKit Standard, CC0: Pine_1-5, rocks, ferns, grass) and `majadroid_construction` (3D House
  Construction Site, CC0: dumper/concrete/small trucks, office containers, crane, fence, materials).
  Both are in `pipeline/asset_packs.json`; `tf assets import` rebuilds them from `incoming/`.
- **Beat 4 in progress**: "Sixty metres of rock now stand between them and the way out."
  Gag: a cutaway (section) of the mountain along the bore. An engineer on the rescue side flings the
  hook of a surveyor's tape; it zips 60 m along the gap under the crown over the rubble; a trapped
  worker catches it on "Sixty" and a counter lands on 60 m; then a lateral track from the trapped
  men's lamps across the plug to the portal ("between them and the way out"). Three shots:
  `plug_throw` (~0.9 s, no narration yet), `plug_catch` (line starts here, catch on "Sixty"),
  `plug_wide`. New bay `section` in `specs/sets/silkyara.json`; gag `gags/mountain_section.gd`
  (placed 2600 m in front of its anchor so the exterior terrain never intersects it). The same
  section set is meant for beats 10, 13, 15 and 20 (the pipe pushing through the heap).
  Status is in the bullets above this one as they are added.

### Silkyara rescue Short: hook rebuilt, history (2026-11-15)

**The task.** A Short about the 2023 Silkyara tunnel collapse ("41 Workers Trapped Inside a Mountain").
Only the hook exists. The user rejected Codex's first tunnel shot (41 identical idle workers, flat
light, one static camera) in these words: "it just added the numbers but it didn't feel busy",
"their models looked bad", "make the shot look more alive when suddenly the wall collapses, I want
it to look cinematic... it can be multiple shots... it is the hook", and later "we also need to make
it look realistic". Read that as: **realistic place, toon actors** (same direction as the Mumbai
lunch Short), people doing distinct jobs, a hook cut into several short shots.

**What exists now** (10.9 s, final quality, all five clips rendered):

| Shot | Scene time | What happens |
|---|---|---|
| `mountain` | 0.00-2.50 | Rebuilt 2026-11-15 (session 2): a drone crane down a forested Garhwal valley, off a snow range, to the floodlit portal; ends at walker height behind a worker heading in. |
| `work` | 2.50-4.75 | Push down a working bore: barrow crossing the foreground, scaffold crew welding a rib, pipe carriers, diggers, the tipper crawling in. |
| `chai` | 4.75-6.05 | Tea break on the pipe stack. Grit patters on a helmet, the lamps dip, he looks up. |
| `collapse` | 6.05-8.10 | Long lens up the bore: the crown fails toward the crew (lining panels, ribs, the duct, rock), cables arc, lamps die, the crew runs at the lens, the dust wall takes the frame. |
| `alive` | `skip` 13 s, 2.76 s | Headlamps in the hanging dust; the power stutters back on the word "alive". |

The script so far is three lines (narration: local Qwen, voice Aiden, cached per line):
"Before dawn in Uttarakhand." / "Forty-one workers are deep inside the Silkyara tunnel when part of
it collapses." / "They're alive." The user allowed Qwen for new or changed lines.
**Script draft v1 (2026-11-15): `episodes/silkyara_rescue/beats.md`**: 26 beats, about 2:10. It runs
from sealed in (60 m plug, 2 km of tunnel with lights and water, the supply pipe) through the machines
(auger, khichdi on day 9, the first video, 47 m, the blades snap on day 13, vertical drilling) and the
rat-hole miners (12 men, 12 m by hand, the breakthrough on day 17, 41 stretchers and 41 ambulances) to
the twist: the DDA demolishes Vakeel Hasan's house on 28 Feb 2024. Every fact is sourced in the file,
and three lines are marked CHECK. **It waits for the user's edits.** Don't record or build beats 4+ until
they approve it, and get the hook verdicts first.

**State of approval.** No shot has a verdict (`python pipeline/tf.py shot silkyara_rescue --status`).
Clips: `episodes/silkyara_rescue/review/shot_loop/00_mountain.mp4` … `04_alive.mp4`, joined as
`hook_preview.mp4` in the same folder (the joined file is made by hand with ffmpeg concat; re-make it
after re-rendering). Browser loop: `python pipeline/tf.py shot silkyara_rescue --serve`. Get a verdict
per shot before building further (standing rule 1). **Nothing is committed**: the Silkyara files are
untracked, next to Codex's uncommitted Mumbai lunch / Jio / Qwen work in the same tree. Commit only
when the user asks. `tf test` passed (42 Godot + 20 Python) after the toon changes.

**Files.**
- `episodes/silkyara_rescue/make_episode.py` writes `episode.json`. **Edit the .py, then run
  `python episodes/silkyara_rescue/make_episode.py`.** It holds the crew table (41 rows: id, character,
  place, facing, action, extras), the looks (`TUNNEL`, `DARK`), cameras, sound, and the timing helpers
  `T(offset)` (seconds from the roof letting go = word "collapses" - 0.05) and `A(offset)` (from the
  word "alive").
- `episodes/silkyara_rescue/gags/tunnel_collapse.gd` (about 1,400 lines) is the whole tunnel and
  everything in it. Sections: the bore (`_shell`, shaders), services (ribs, duct, mains), light
  (`_wall_light`, tower, crown stand light), the site (scaffold, pipe stack, spoil, stores), the tipper,
  what the crew holds, the fall (panels, heap, rock, dust, billows, sparks, grit), then `pose` and its
  parts. Params: `impact`, `alive`, `crew`, `trickles`.
- `episodes/silkyara_rescue/gags/silkyara_exterior.gd` (rebuilt this session: valley, portal, yard, fire drum, dumper, forest, snow range, mist) and `specs/sets/silkyara.json` (Codex's set)
- `godot/scripts/actors/toon.gd`: new hair style `hardhat` (+ `"lamp": true`) and outfit `hivis`
  (docs/TOON_SPEC.md). Characters `library/characters/toon_tunnel_{worker,worker_lime,worker_blue,worker_red,engineer,digger}.json`.
- `output/silkyara_backup/`: Codex's original `episode.json` and gag. `output/silkyara_cast_test.json`:
  a line-up of the six worker characters (`python pipeline/tf.py preview-set output/silkyara_cast_test.json --out output/previews/silkyara_cast`).

**How the scene is set up (read before changing it).**
- Everything in the tunnel uses the gag's own frame: x across the bore (+x is screen right when looking
  toward the portal), y up from the floor, z along the bore. **-z is the way out.** The crew works
  z = -14..+10, the collapse plugs z = -36..-20 (`CZ0`, `CZ1`), the rubble toe is `PLUG_TOE` = -16.5.
  In `make_episode.py`, `P(x, y, z)` converts to the stage anchor (it negates x and subtracts 118).
- The tunnel bay sits 118 m under its stage anchor, so **the gag sets every crew actor's height each
  frame** (`crew[id].y`: 0, the scaffold deck 3.225, the mid deck, the pipe-stack seat). An actor
  missing from `params.crew` floats at y = 0, far above the tunnel. Actor anchors are computed before
  the gag runs, so **cameras must use `P(...)` points**, not `<actor>.head`. A crew member with
  `"hero": "name"` gets a gag anchor `collapse.name` at their head if a camera needs to follow one.
- One route per actor. People who walk before the collapse arrive just before the warning, then duck
  in place (cue `crouch` + the gag's hands-over-head, `cower`). Everyone else stands at a job and runs
  on a route that starts at the impact, to a slot from `SLOTS` (assigned in `build_crew`). Runners
  arrive after the shot ends on purpose, so nobody stops in frame. The dust is the cover for the rest.
- Roles with props and hand IK live in `_pose_crew`: `barrow`, `pipe_a` (+ `mate`), `chai`, `engineer`,
  `welder`, `sprayer`, `bag`, `signal`, `point`. Adding a role means a prop in `_build_crew_props` and a
  branch in `_pose_crew`.
- The collapse is a pure function of `dt = t - impact`. The failure runs up the bore toward the crew
  for 0.85 s (panels release far to near), then the dust surges down it: `_front(dt)` is the dust face,
  `_reach(z)` when it gets to a point, `_power(z, t, ...)` how bright a lamp at z burns (warning dip at
  -0.8 s, stutter at the impact, death 0.3 s after the dust reaches it, everything dark by 1.95 s, a weak
  return after `alive` for lamps beyond `CZ1 + 9`). Dust density hangs and thins over about 15 s, which
  is why `alive` uses `"skip": 13`.
- Timeline: the three cuts inside the one narration line are **fixed durations** read off the word
  times (`python pipeline/tf.py voice silkyara_rescue`). If that line is re-recorded or rewritten,
  re-time `work`, `chai` and `collapse`.

**How to iterate (fast).** `python pipeline/tf.py shot silkyara_rescue work,chai,collapse,alive`
renders all four at 1080x1920 in about 15 s (`--final`: 60 fps + motion blur, about 30 s). Then look
at frames, not just the strip: `ffmpeg -ss <t> -i review/shot_loop/03_collapse.mp4 -frames:v 1 -vf scale=540:-1 out.png`
at several times, and Read them. The collapse needs samples every 0.2-0.3 s to judge.
`python pipeline/tf.py storyboard silkyara_rescue` gives start/mid/end of every shot.

**Decisions already made, and why (don't undo by accident).**
- The collapse is filmed on a 31-34 mm lens from z = +1.6..+4.2. From the wide camera the fall was 35 m
  away and invisible.
- The tipper parks on the +x side (it crawls in during `work` and stops 1.1 s before the impact). In
  the centre lane it hid the whole fall.
- The rock cavity behind the falling lining is a shell **outside** the bore (`_shell(..., hollow=true)`).
  A box there blocked the view down the tunnel.
- No daylight glow at the far end: it read as a screen, and it is before dawn.
- Lamps stay lit for 0.3 s inside the dust so the dust wall is lit as it comes; otherwise it is a
  black wall nobody can see.
- Billows (`_puffs`, opaque lumpy spheres) give the dust a face; the `FogVolume` alone was only a fade.
  They pour down from the hole at 60 % size instead of growing from a bead (that looked like bubbles).
- Power facts: reports say electricity and the water pipe survived in the trapped section, which is why
  the lamps come back on "alive". Verify before stating it in narration.

**Known weak points, in the order I would fix them.**
1. `mountain` (rebuilt, `gags/silkyara_exterior.gd`): near forest = Quaternius Stylized Nature MegaKit pines
   (CC0, pack `quaternius_nature_mega`), far forest = the procedural conifer. The dumper here and in the
   tunnel is `majadroid_construction/Trucks#Dumper Truck Red` (CC0, Majadroid, imported 2026-11-15; its
   wheels don't turn). The cut face above the portal is a smooth lit blob. Exterior frame: portal faces +z,
   `S(x, y, z)` in make_episode.py; `_height()` is the terrain (the raise over the bore stops 25-60 m back;
   an unbounded raise made a 1.6 km fin that looked like a light column in the sky).
2. The fall is dust-led: individual lining panels read for about half a second. Closer or slower
   panels, or a second angle on the crown, would sell it more.
3. (done) The tipper is now the Majadroid model in both the exterior and the tunnel.
4. `alive`: from the high camera the nearest workers show helmet tops more than faces; the crowd is
   still a loose grid.
5. Sound was placed by measurement, not by ear: grit ticks, `creak`, two layers of `audio/rockfall.wav`
   (its attack is 0.5 s into the file), `rip`, thuds, a `whoosh`, coughs. There is no welding, engine or
   site ambience beyond `audio/underground.wav`. `audio/` has no SOURCES.md for Codex's four recordings:
   ask the user or Codex where they came from before publishing.
6. With motion blur, an instant action switch (cue `crouch`, a route starting) ghosts for one frame.
7. The invert (floor) shader still shows faint facets in raking light.

**Traps hit in this session.**
- Gag scripts are compiled at load: GDScript has no `step()`, `floor()` returns Variant (use `floorf`),
  and locals named after built-ins (`len`, `floor`, `load`, `step`) break things. A compile error shows
  as "script does not compile (error 43)"; the real message is a few lines above it in the output.
- `Basis.looking_at(d)` points **-Z** at d. Spot lights shine along -Z, so that is right for lights and
  wrong for anything modelled along +Z.
- Shader source is assembled with `.replace("//NOISE", NOISE_GLSL)`, not `%` formatting.
- In Git Bash on this machine, long `python - <<'PY'` heredocs with triple-quoted strings fail with
  "unexpected EOF". Write the patch script to a file and run it.
- Don't `cd` into subfolders in the shell and then use relative paths; the working directory sticks.

### Mumbai lunch Short (2026-11-14)

The user chose **How Mumbai Delivers Your Lunch by Train** with calm camera motion,
realistic Mumbai environments, toon actors, and recorded sound effects. The eight-shot
script and plan are in `episodes/mumbai_lunch/beats.md`. The first shot is the kitchen.
Review `episodes/mumbai_lunch/review/shot_loop/00_kitchen.mp4` and wait for the user's
verdict before building the Dadar lane shot. The shot uses an audition take from local
Qwen Aiden and Nightflame's recorded metal clasp. Further field recordings are in
`output/mumbai_lunch/sfx/` with sources in `episodes/mumbai_lunch/audio/SOURCES.md`.
Godot 4.7.2 reported Vulkan ray-tracing pipeline support on the RTX 4050. The review
clip uses Forward+ lighting, ambient occlusion and a reflection probe.

### Local Qwen narration for the UPI Short (2026-11-14, installed and verified)

The user liked **What If UPI Went Down for 10 Minutes?** and asked for local TTS with acting
directions so rewriting one line during animation does not spend another Gemini request.
The integration is in the working tree. Set `narration.model` to `qwen3-tts-1.7b-customvoice`,
use `Ryan` or another Qwen speaker, and set `style` on individual lines as needed. Qwen caches each
line separately, loads the model once for missing takes, and uses the existing CTC timing and captions.
The official Qwen runtime is isolated in `pipeline/qwen_tts_local.py` and `.venv/qwen-tts/`.
This setup uses BF16 and PyTorch SDPA on CUDA.

- Both model files under `models/qwen3-tts/1.7b-customvoice/` and the CUDA PyTorch wheel passed
  SHA-256 verification. Qwen 0.1.1, PyTorch and torchaudio 2.8.0+cu128 are installed in
  `.venv/qwen-tts/`. `pip check` passed and PyTorch detected the RTX 4050. New-machine setup is in
  `docs/AUDIO_SPEC.md`.
- `python pipeline/tf.py voice output/upi_voice_audition.json` generated both takes on the GPU and
  aligned all 20 words. The combined listening sample is `output/upi_voice_audition.wav` (10.19 s).
  Changing only the coin line in `output/upi_voice_audition_rewrite.json` generated one new take and
  kept the setup WAV's path and modification time. The user's listening verdict is the next step.
- Qwen printed optional SoX and FlashAttention warnings during the successful run. The Windows worker
  publishes finished takes by rename because the sandbox denied hard-link creation.
- `tf test` passed 42 Godot and 20 Python tests, including the one-line cache regression. In the
  Codex Windows sandbox, set `TEMP` and `TMP` to a directory under `output/` for this command
  to avoid the sandbox temp volume's `os.replace` error. `tf voice jio_story` also resolved all 31 shots
  from the existing take. No commit was made.

**2026-11-12, latest: the Jio rebuild is on the user's edited v2 script.**
THE SCRIPT IS DONE: `episodes/jio_story/script_v2.html` (read it) and `episodes/jio_story/script_v2.json`
(same data: 31 beats, each `line` = exact narration, `see` = what happens on screen, `status`, `note`).
**Where status is "change", the user's `note` is the direction to build; it overrides `see`.** 15 beats
changed, 16 kept. (Source: the user's script board https://claude.ai/artifact/1xDaZcFHEzD4MoREmX5dHB ;
the denser planning doc with camera/sound/sources per beat is https://claude.ai/artifact/AcvhvS6ZSqgfomymyqivfE ,
and the fact sources are also in `episodes/jio_story/script.md`.)

`make_episode.py` generates all 31 exact narration lines and matching shots with the old timing
references removed. The new single take is recorded and aligned (124.6 s). Keep the complete v2
narration script and voice settings so later renders reuse that take.

**All 31 shots are approved. The final 60 fps render is complete.**
Final video: `episodes/jio_story/renders/jio_story.mp4` (1080 × 1920, 60 fps, 2:10.74,
with narration, effects, music and burned-in captions). All 31 shot files were rendered fresh
and the complete MP4 passed video and audio decoding.
Beat 23 now uses a truck-mounted JioPhone launcher with three bursts that pile handsets around the crowd.
Beat 27 now uses a timed turn and sit, with Mukesh's seated pose anchored to the rising chair.
The user asked to continue making shots while away and to leave each verdict for their return.
The review clips are in `episodes/jio_story/review/shot_loop/`, indexed from
`22_beat_23.mp4` through `30_beat_31.mp4`.
Beat 22 takes place in the new `trai_office` bay. In `gags/trai_complaint.gd`, the three rivals
run to the regulator, file a tariff complaint and cry into buckets. Mukesh hands over a ringing
phone, Vodafone drops it, and the camera follows it to the floor as the screen reads “CALL DROPPED.”
Review `review/shot_loop/21_beat_22.mp4`.
Beat 21 cuts inside the same branch to the `jio_activation` bay. In `gags/activation_gate.gd`,
a shop clock spins through the milestone, then ticks once per second as two groups of seven
customers jog through a ratcheting turnstile. Review `review/shot_loop/20_beat_21.mp4`.
Beat 20 uses the new `jio_store` bay and `gags/sim_queue.gd`: a clerk hands a Jio SIM to the
first customer on “join,” the camera pulls back as the queue steps around the corner, and the
counters land on “million” and “26.” Review `review/shot_loop/19_beat_20.mp4`.
Beat 19 (launch) uses the new `jio_launch` bay (dark auditorium) and `gags/jio_launch.gd`: the date
on the LED screen, Mukesh slams a launch button on "launch" (screen flashes to the Jio disc, crowd
throws its arms up, `cheer` sfx), flings three handfuls of Jio SIM cards into the crowd/at the lens on
"And / everything / free", then the camera pushes in while he slaps red FREE tags on a desk phone
(calls), a Jio 4G recharge voucher (data) and an app-filled phone (apps). Crowd = `LAUNCH_FANS` in
`make_episode.py`. The Jio logo is a text recreation (white "Jio" on a blue disc), no logo file yet.
New one-shot sound: `cheer` (pipeline/sfx.py). Review `review/shot_loop/18_beat_19.mp4` or
`tf shot jio_story --serve`.
The user asked to carry the watchtower shot's realism into the other shots. Use it as the
reference for depth in the set, lighting that fits the place, and continuous, grounded motion.
Follow AGENTS.md "standing rules" (incl. rule 10: no generic labelled cubes) and docs/MOTION_SPEC.md.

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
This progress is for the v1 cut. The active v2 cut starts with `tower_open`.

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
