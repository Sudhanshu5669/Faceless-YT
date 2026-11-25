# Bombay Gold: handoff (read this first to continue the video)

*Last updated 2026-11-25 (night). Also read `AGENTS.md` (the user's standing rules) and the `toon-short` skill.*

**The video:** "It rained gold on Bombay", a 9:16 Short (131.5 s, 52 shots) on the 14 April 1944 Fort Stikine
explosion. The user gave Claude end-to-end ownership of the channel and full permission to drive this video; they
asked to **review every shot before the final render** (`python pipeline/tf.py shot bombay_gold --serve`,
http://127.0.0.1:8770/).

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
