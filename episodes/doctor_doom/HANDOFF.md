# Doctor Doom: handoff (read this first to continue the video)

*Last updated 2026-11-25 (end of session). Update after every shot. Also read `AGENTS.md` (the user's standing
rules, incl. rule 11 "Make it grand") and the `toon-short` skill.*

**The video:** "Who is Doctor Doom, and why is Iron Man playing him?": the channel's first **long-form** video
(16:9, 1920x1080, 60 fps, ~8.5 min), for Avengers: Doomsday (US release 18 Dec 2026, premiere 14 Dec). Target upload
**Dec 12-15**. Pitch: `pitch.md`. Script + every fact's source: `script.md`. Assets + licences + credits: `ASSETS.md`.

## Where we stopped (2026-11-25)

All 114 shots are built and have review clips. The user is reviewing in the shot UI
(`python pipeline/tf.py shot doctor_doom --serve`, http://127.0.0.1:8770/). Verdicts: `review/shot_decisions.json`
(`tf shot doctor_doom --status`; it is slow on 114 shots, give it a few minutes).

- **First round of verdicts (66 approved)** were all addressed and re-rendered (see "Verdict fixes" below). The user
  has NOT yet re-reviewed those re-rendered clips; their statuses still read `changes` from round one.
- **Realistic rigged Doom** (VLTXD, see below) was swapped in and 22 shots re-rendered on 2026-11-25.
- **Pending, not rendered:** `castle_gates`: the door light was dimmed (castle.gd `_door_light` 900 -> 160) so Doom
  walks in as a silhouette instead of vanishing in the glare. Storyboard checked; run `tf shot doctor_doom castle_gates`.

## Next steps

1. Render `castle_gates` (above). Push-notify the user that the re-renders are ready.
2. The user re-reviews; fix their next verdicts the same way (storyboard, look, render the clip, notify).
3. Known soft spots still open (fix before the final):
   - Hall H screens show a red box, not the Marvel Studios logo (Wikimedia 429). Retry
     `https://upload.wikimedia.org/wikipedia/commons/6/63/Marvel_Studios_logo.svg` -> `library/logos/doom/marvel-studios.svg`.
   - hell_fight: the Devil silhouette is faint. board_news: the headline card covers Feige's face. The boardroom
     window HDRI (a river and a bridge) is not Burbank.
   - lab_blast: Victor has his back to the lens at the blast.
   - Unreviewed shots ("-"): board_ticket/loki/quantum/chart/fade/fall/empty/fast, shop_night/box/meet, lat_castle/
     healer/flee/freeze, mirror_warp, tibet_mask, emp_globe, hosp_helmet, reels_kebbell, shop_wait.
4. When every shot is approved: **final render** `python pipeline/tf.py render doctor_doom` (1920x1080, 60 fps, motion
   blur 2, music + 71 effects + 7 overlays + captions, -14 LUFS). Rebuild the git-ignored inputs first if missing:
   `python episodes/doctor_doom/make_audio.py` (audio/lib) and `python episodes/doctor_doom/make_overlays.py`
   (overlays/out). **Never render on battery** (check `(Get-CimInstance Win32_Battery).BatteryStatus` = 2).
   The render takes a while (7.6 min of 60 fps); a 114-shot `tf shot` batch once stopped at shot 105, so split big
   batches.
5. Then: thumbnail (16:9), title, description with **all credits** (below), chapters (timestamps from the overlays).

## Credits for the description (required)

- Music: each Scott Buckley track used - `'<Track>' by Scott Buckley - released under CC-BY 4.0. www.scottbuckley.com.au`
  (Eyes In The Void, Anabasis I, Convergence, Penumbra, Aphelion, Starfire; `incoming/music_doom/LICENSE.txt`).
- Iron-Man Helmet (MK3) by Ritesh/designpill, Doctor Doom's Mask by Nicolas_Laube, Doctor Doom Avengers Doomsday Low
  Poly by VLTXD: exact credit lines in `ASSETS.md` (all CC BY 4.0).
- Sound effects: Sonniss GDC 2026 bundle (no credit required). Ships: Quaternius (CC0). Poly Haven (CC0).
- Posters/covers/logos/headlines: commentary use; sources in `library/logos/SOURCES.md` and `script.md`.

## The user's decisions for this video (binding)

- Title "Who is Doctor Doom, and why is Iron Man playing him?". Demo look approved: "this is the level of grand I am
  looking for" -> rule 11 "Make it grand" (AGENTS.md + toon-short skill, cinematics.md section 10).
- Script v1 approved; v1.1 = +10 lines for length (the user chose "make it longer, option 1"). 114 shot lines in
  `lines.py`; narration single take **458.2 s** (Charon, gemini-3.8-flash-lite-tts; cached, do not regenerate casually).
- Professional grade: downloaded SFX (Sonniss), copyright-free music (Scott Buckley, CC BY), posters instead of title
  cards ("i want posters here"), real comic covers as props.
- Realistic downloaded models are wanted for Iron Man's helmet and Doom (the user chose them). Toon people otherwise.
- **The user downloads Sketchfab files themselves** (needs their login): open the exact page + target folder for them
  (`Start-Process <url>; Start-Process explorer.exe <folder>`), then they say "downloaded".
- Check licences AND provenance: "Dr Doom V2" (VisiionLovesYou) was rejected - skeleton `sv_doctordoom01_S01` points
  to a game extraction; parked in `incoming/doom_v2_rejected/`, never used. Game rips (Fortnite, MUA, Marvel Chaos)
  are out even if tagged CC BY.

## Verdict fixes made 2026-11-24/25 (what changed, so you don't redo it)

- "Shaking" was not the camera: the `Sitting_Idle` pose + idle breathing in close-ups. Seated/close-up actors now have
  `"freeze": 0.35` (faces still change).
- Posters: board cards (`boardroom.gd` CARDS + `_poster`), the rebuilt wall (Doomsday poster + Secret Wars logo), film
  reels (FF 2005/2007/2015 posters), the shop stack (Avengers #1, ASM #1, Iron Man #1, Daredevil #1). Files in
  `library/logos/doom/posters/` (fetched slowly from Wikipedia; it rate-limits hard). The Kang Dynasty has no poster
  (cancelled) and stays a title card.
- No card flip; Feige without glasses; throne seat; chest glow; mountain snow caps (z-fighting); hammer rests on the
  plate and the monk holds it; cinema_ticket = the screen lights "AVENGERS: DOOMSDAY · DEC 18"; shop comic cover
  visible, drops to the floor, shop_meet looks down at it; shop_rise = comic racks + the Bleeding Cool headline
  overlay (`news_rise`); board_contract (rejected) -> RDJ swims in a cash heap (`library:cash_stream`) with a
  $80,000,000+ counter landing on "million"; emp_cloak; city_ironman = Doom wearing the real Iron Man helmet
  (misc.gd `ironhead`); mirror reframed; the storm sky moved to z -6000 so its clouds don't show in space.
- Gallery: the Iron Man helmet is the downloaded MK3; Doom's shadow is a cut-out silhouette that looms; the right
  plinth holds the downloaded Doom bust; gal_eye = the eyes kindle green on "different".

## Realistic rigged Doom (how it works)

- Pack `vltxd_doom` (`pipeline/asset_packs.json`, from `incoming/vltxd_doom.zip`). The GTA-SA rig was re-posed from
  A-pose to a T-pose facing +Z at 1.83 m by `pipeline/blender/tpose_character.py` (reusable for other A-pose rigs).
- Retarget map `gta_ped` in `library/rigs.json` (bone names keep their leading spaces); character
  `library/characters/doom_realistic.json`.
- Used for the suited Doom: castle (doom_walk, doom_throne, doom_gate, doombot_0..6), cosmos (doom_surfer, doom_void,
  doom_emp), misc (doom_hell, doom_hosp), doom62 (doom62, doom62_b). Still toon: God Emperor (white/gold), the Iron
  Man-helmet Doom (head swap), Hall H performers + RDJ, young Victor.

## How the places work

- `make_episode.py` builds episode.json from `lines.py` (lines + shot->place map), `places/*.py` (actors, gags, shots
  per place), `sound.py` (music cues, effects, overlay times). Edit those, never episode.json.
- Each place is a gag on the "board" bay, kilometres apart (z 40000 board, 60000 gallery, 80000 cinema, 100000 shop,
  120000 castle, 140000 latveria, 160000 tibet, 180000 cosmos, 200000 doom62, 220000 misc). **Never name a gag after
  its bay** (the id becomes an anchor and shadows the bay's).
- Gag scripts load from source at runtime: no `preload` of files outside `godot/`; load library gags via
  `GDScript.new()` + `source_code` (see `suit()` in gallery.gd).
- Pipeline changes this session: stills/frames globs handle 100+ shots; recorded `music` cues in the mixer; `overlays`
  (HyperFrames renders with alpha) composited in the final render (AUDIO_SPEC.md).
- GLSL gotchas: `smoothstep(a, b, x)` needs a < b; `pow(x, y)` with x < 0 is NaN; heredocs in bash mangle `\n` and
  backslashes, so patch GDScript with the Edit tool or a .py file.
