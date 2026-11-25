# Bombay Gold: handoff (read this first to continue the video)

*Last updated 2026-11-25 (night). Also read `AGENTS.md` (the user's standing rules) and the `toon-short` skill.*

**The video:** "It rained gold on Bombay", a 9:16 Short (131.5 s, 52 shots) on the 14 April 1944 Fort Stikine
explosion. The user gave Claude end-to-end ownership of the channel and full permission to drive this video; they
asked to **review every shot before the final render** (`python pipeline/tf.py shot bombay_gold --serve`,
http://127.0.0.1:8770/).

## Where we stopped (2026-11-25, late night) — READ FIRST

- **All 52 shots approved by the user (round 2). Final render started** (`tf render bombay_gold`, log
  `output/bombay_gold_render.log`, ~1.5 h) -> `renders/bombay_gold.mp4`. Next: watch samples of the MP4 (strip with
  ffmpeg), check duration vs 131.51 s and loudness, then thumbnail + title + description (credits in ASSETS.md).


- Review round 1: 43 approved, 9 "changes" (gold_fall railings, man_lift angle/table clip, ground glitch on
  stikine_bow/dock_moor/engines_race/helmets, flat_return = gold bar silhouette against the burning sky,
  police_desk/cheque_999 "policeman's head on the table"). **All 9 fixed and committed (b6909cc)**; review clips
  re-rendered for them + bar_wall, window_whip, hook_rain, cotton_rain, gold_rain (same sets changed).
  Fixes: quay wall tops 6 cm under the paving (coplanar = z-fighting); balcony actors at x +-6.35; table scaled 0.75
  (TOP 0.75), man at (1.45, 0, -1.0); police platform 0.6 m, inspector y 0.6, eye-level cameras; new actor
  `parsi_eve` at the window + `_bar_sil` dark bar + sky panel colour ramps to burning red at `dusk`; the Parsi cap
  sits on the `<id>.head` anchor (= drawn toon head centre, ~1.19 m) + 0.25, NOT bone_world("head") (~1.6 m).
- **Next:** the user re-reviews the re-rendered clips (`python pipeline/tf.py shot bombay_gold --serve --port 8771`;
  port 8770 is held by an old doctor_doom server). `tf render bombay_gold` refuses until every shot is approved
  (do not --force). Check power (BatteryStatus 2) right before rendering; ~1.5 h.
- Frame drift **fixed** (2026-11-25): `Episode.timeline(ep, fps, blur)` and `tf._episode_frames(ep, fps, blur)` take
  each shot's frames from the cumulative edit time (whole blur groups); tests pass. Bombay Gold: 15782 sub-frames =
  131.517 s for 131.510 s of narration.
- Kimodo (`E:\AgentTools\kimodo`): venv + torch 2.6 cu124 OK, SOMA-X installed from a local clone (git-lfs hook
  blocked the pip clone; `git restore` finished it), deps installed; **kimodo itself won't build: its
  MotionCorrection C++ extension needs MSVC** (no compiler on this PC). Waiting for the user: install "Build Tools for
  Visual Studio 2022" (Desktop development with C++), then `cd repo && ../venv/Scripts/python.exe -m pip install -e .
  --no-deps --no-build-isolation`. The user also needs an HF token in `E:\AgentTools\kimodo\.env` (Llama-3 licence).

## State

- Script v1 approved (`script.md`); one Gemini take cached (lines were later split into sub-lines without new tags,
  which reuses the cached take: keep doing that to add cuts for free).
- All 52 shots built and storyboarded; `tf framing` clean; `tf test` passes. Review clips (30 fps, no blur) render into
  `review/shot_loop/`. **Waiting on the user's verdicts**, then the final render (`tf render bombay_gold`, ~1.5 h:
  a 1.24 s shot took 63 s at final quality incl. ~20 s of set-up).
- Sound: `make_audio.py` builds `audio/lib/` (git-ignored) from the Sonniss bundle + Scott Buckley (CC BY: credit
  Penumbra and Memories Of Stone). SFX/beds/music cues are in `make_episode.py` (SFX, MUSIC).
- Assets + credits: `ASSETS.md` (Sketchfab CC BY models downloaded by Claude via the user's Chrome; Poly Haven CC0).

## Places (gags/ + places/)

| Place | Gag | Shots |
|---|---|---|
| Victoria Dock (the whole afternoon, blast, night, dawn) | `dock.gd` + `dock_props.gd` | 25 |
| No. 2 hold, inside | `hold.gd` | 5 |
| Girgaum lane / the Parsi gentleman's flat | `girgaum.gd` / `flat.gd` | 4 / 4 |
| Dadar street 12 km away | `girgaum.gd` variant "dadar" | 1 |
| Shimla (town + seismograph room) | `shimla.gd` | 2 |
| Police station + relief fund box | `police.gd` | 3 |
| Fire Service Day today | `firestation.gd` | 2 |
| Mumbai port 2011, the dredger | `port.gd` | 4 |

`fx.gd`: shared camera-sorted billboard smoke/fire/spray and the jute bale material (load it at runtime with
`load(Paths.repo_path(...))`; wrap untyped returns, e.g. `_h()`, for GDScript type inference).

## Lessons

- The Liberty ship model (`liberty_ship/scene_fort.gltf`): bow at the painted-name end; one 8k atlas (repainted:
  FORT STIKINE, Red Ensign, 4k copies). Real deck heights came from a raycast probe (deck ~7.2 m above water, No. 2
  hatch top 8.4 m, foremast x +40): measure, don't guess.
- Portrait frames are narrow (~±15° horizontally at 24 mm): aim cameras so subjects sit near the line of sight.
- Toon white heads bloom in hard sun: give modern crowds dark caps, lower sun energy, raise the glow threshold.
- The lite TTS read a leading [style] aloud: the narration now has no style; `_check_verbatim` fails on that.
