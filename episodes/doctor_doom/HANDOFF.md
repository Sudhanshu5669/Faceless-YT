# Doctor Doom: handoff (read this first to continue the video)

*Last updated 2026-11-24. Update after every shot. Also read `AGENTS.md` (the user's standing rules) and the
`toon-short` skill.*

**The video:** "Who is Doctor Doom, and why is Iron Man playing him?": the channel's first **long-form** video
(16:9, 1920x1080, 60 fps, ~9.5 min), for Avengers: Doomsday (US release 18 Dec 2026, premiere 14 Dec). Target upload
**Dec 12-15**. Pitch, chapters, facts table: `pitch.md`. Assets: `ASSETS.md`.

## State

| | |
|---|---|
| Decided by the user (2026-11-24) | Title "Who is Doctor Doom, and why is Iron Man playing him?"; HyperFrames approved for 2D overlays; real comic covers allowed (held as props, a few seconds); Poly Haven + logos download approved. "Make the animation look grand." Demo shots first, then the full script. |
| DEMO shots built + rendered (review clips, 30 fps), WAITING for the user | **Hall H** (`places/hall.py`, `gags/hall_h.gd`): hall_wide, hall_walk, hall_unmask, hall_reveal, hall_quote. **Lab** (`places/lab.py`, `gags/lab.gd`): lab_machine, lab_warning, lab_ignore, lab_blast. **Boardroom** (`places/board.py`, `gags/boardroom.gd`): board_plan, board_news (+ HyperFrames headline composited into the review clip), board_collapse. Clips: `review/shot_loop/`; browser: `python pipeline/tf.py shot doctor_doom --serve`. |
| Narration | Demo take only (Charon, gemini-3.8-flash-lite-tts, 53 s). The take read the style direction aloud at the start; it was trimmed off the cached `_scrub.wav` (backup `output/scrub_backup_doom.wav`). Keep `style` short or drop it. The full script needs a new take. |
| Next | 1) The user's verdict on the demo look. 2) Write `script.md` (~1,400 words, chapters in pitch.md, every fact sourced). 3) `beats.md`. 4) Build the remaining places (Latveria camp in the snow, Tibet monastery forge, Castle Doom throne room, Battleworld, courthouse exterior, cinema). |

## Known soft spots in the demo (fix before final)

- Hall screens show a red box, not the Marvel Studios logo: Wikimedia rate-limited the download (429). Retry
  `https://upload.wikimedia.org/wikipedia/commons/6/63/Marvel_Studios_logo.svg` into `library/logos/doom/marvel-studios.svg`
  (public domain text logo); `hall_h.gd` picks it up automatically.
- RDJ's hair/forehead still catch too much of the follow spot in hall_quote.
- Beam cones (`hall_h.gd` BEAM_SHADER) still show faceted edges in hall_walk.
- lab_blast: by the blast Victor has his back to the camera, so "in his face" isn't literal; turn him to the lens or
  move the camera round.
- board_news: the headline card covers Feige's face; move the card right or reframe. The night view through the glass
  (Poly Haven `modern_buildings_night`: a river and bridge) isn't Burbank; find a better match.
- board_collapse: the clip ends (end of the demo audio) before the cork wall finishes falling; in the full edit the
  next line gives it room.

## How the places work

- Each place is a gag on its own bay, kilometres apart (`frame("lab", 20000)`, `frame("board", 40000)`): the bays
  sit close together and Hall H is 130 m wide. **Never name a gag after its bay** (a gag's id becomes an anchor and
  shadows the bay's anchor, so every camera offset doubles): gag ids are `hall_set`, `lab_set`, `board_set`.
- Doom's costume is `library/gags/doom_suit.gd` (mask with eye slits so the drawn eyes act through it, hood, mantle,
  cloak, tunic, belt; `unmask` lifts the mask and drops the hood). Our own toon design, not a copy of a model.
- Toon heads: for a `height` 1.5 toon the head centre is about 1.12-1.2 m; aim close-ups there.
- New characters: `toon_rdj` (slick hair, moustache + **goatee**: new toon key `goatee`), `toon_doom_extra`,
  `toon_victor_young`, `toon_reed_young`, `toon_feige`.
- GLSL gotchas met here: `smoothstep(a, b, x)` needs a < b; `pow(x, y)` with x < 0 is NaN (a white square on screen).

## HyperFrames (2D overlays)

Installed in the scratchpad only (`npx hyperframes`, v0.9.88, Apache 2.0, telemetry off with
`HYPERFRAMES_NO_TELEMETRY=1`). Compositions live in `overlays/<name>/index.html`. Render transparent:
`npx hyperframes render <dir> --fps 60 --format mov -o out.mov` (ProRes 4444 with alpha, 5 s in ~25-55 s), then
overlay in ffmpeg. GSAP loads from a CDN in the composition: vendor it before the final. To do: an `overlays` list in
`episode.json` that the final render composites automatically.

## Sources (facts used in the demo lines)

CBC / AP 2024-07-27 (the unmasking at Hall H, "New mask, same task"); The Vendry / SDCC blog (Hall H ~6,130 seated,
6,500 often quoted, so the line says "more than six thousand"); Wikipedia "Doctor Doom" (FF #5 July 1962, Lee & Kirby,
origin in FF Annual #2 1964, Empire State University, Reed, Tibet, diplomatic immunity, Infamous Iron Man 2016);
Nerdist / TV Tropes (the machine to reach his mother in the realm of the dead, Reed's warning, the explosion);
Wikipedia "Avengers: Doomsday" (Kang Dynasty SDCC 2022, retitled + RDJ SDCC 2024, release dates, cast);
Wikipedia "Jonathan Majors", Fortune 2023-12-18, Euronews 2023-12-19 (split verdict: third-degree assault and
harassment; Marvel dropped him the same day; headline "Jonathan Majors found guilty of assault and dropped by Marvel").
