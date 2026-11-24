# Doctor Doom: handoff (read this first to continue the video)

*Last updated 2026-11-24. Update after every shot. Also read `AGENTS.md` (the user's standing rules) and the
`toon-short` skill.*

**The video:** "Who is Doctor Doom, and why is Iron Man playing him?": the channel's first **long-form** video
(16:9, 1920x1080, 60 fps, ~9.5 min), for Avengers: Doomsday (US release 18 Dec 2026, premiere 14 Dec). Target upload
**Dec 12-15**. Pitch, chapters, facts table: `pitch.md`. Assets: `ASSETS.md`.

## State

| | |
|---|---|
| Decided by the user (2026-11-24) | Title "Who is Doctor Doom, and why is Iron Man playing him?". Demo look APPROVED ("this is the level of grand I am looking for"); wants professional grade: downloaded SFX, this animation, a great script. **Script v1 APPROVED** (`script.md`, sources per line). SFX download approved (Sonniss GDC 2026, `incoming/sonniss_gdc2026/wav/`, licence in LICENSE.txt/pdf). Music: the user asked for copyright-free music -> 10 Scott Buckley tracks, CC BY 4.0, in `incoming/music_doom/` (LICENSE.txt has the credit format; credits go in the description). The user reviews everything in the shot UI (`tf shot doctor_doom --serve`). |
| Lines | `lines.py`: the approved script as 104 shot lines (one per shot: the single take needs it); `PLACE_OF` maps shot prefixes to place modules; `CHAPTERS` = chapter cards (HyperFrames, to do). |
| Narration | Full single take recorded 2026-11-24: **410.6 s (6.8 min)** of voice; 9 read-aloud tags were scrubbed automatically. Length question for the user: 6.8 min voice + cards/holds ~ 7.5 min, under the 8-min mid-roll mark -> options: add ~150 words, slow to 0.93x, music breathers, a 10-15 s end screen. |
| Script | v1.1 (user chose "make it longer, option 1", 2026-11-24): +10 lines (see script.md "v1.1 additions"), 114 shots. New take **458.2 s** (7.6 min voice) -> ~8.5 min with cards/holds/end screen. |
| Rendered clips | Hall H, lab, gallery, boardroom, cinema clips exist in `review/shot_loop/` BUT were rendered on the OLD 410 s timing: re-render everything (`tf shot doctor_doom <names>`) before review. |
| Built + storyboarded | hall (all 12), gallery (11 incl. gal_farewell, gal_return), board (21 incl. board_fast), cinema (9 incl. cinema_2008, cinema_years), shop (7 incl. shop_rise; open bug: the held FF #5 shows a blank face), lab (5 incl. lab_double), castle (11), latveria (9: lat_*, liner_deck), tibet (3). |
| Built (cosmos, 2026-11-24) | surfer_sky, beyonder_grab/hand, bw_planet/stitch/throne/heal, emp_cloak/globe, rocket_pad, rocket_shadow (now a porthole with Doom's mask inside). Earth uses the Mangalyaan-style EARTH_SHADER (StandardMaterial didn't show the maps). Open: a white spiky object shows in the VOID/WORLD shots' background (find it); Battleworld still a bit dark. |
| ALL 114 SHOTS BUILT (2026-11-24) | + doom62 (FF #5 lab, Blackbeard ship: Quaternius CC0 via Blender), misc (hell, hospital, Iron Man Doom rooftop, dressing room, film reels, campus gate, mirror). Polish list: the Devil silhouette is faint (hell_fight); (fixed: the shop FF #5 cover); a stray white object in the VOID/WORLD backgrounds; board_contract dim; helmet horns (gallery). Chapter cards + the arrest headline (HyperFrames), the sound mix, then RE-RENDER every clip on the 458 s timing. |
| (old row) | doom62 (doom62_kidnap/platform/feet, pirate_chest/thing: needs a pirate ship, ASK to download: Quaternius or Kenney Pirate Kit, CC0), campus/mirror (campus_gates, mirror_scar, mirror_warp), hell (hell_fight), cosmos (surfer_sky, beyonder_grab/hand, bw_planet/stitch/throne/heal, emp_cloak/globe, rocket_pad/shadow: the First Steps rocket, ASK: Kenney Space Kit CC0), hospital (hosp_bed/helmet, city_ironman), dressing (dress_oscar, reels_past/mcmahon/kebbell). |
| Sound (DONE 2026-11-24) | `sound.py`: 9 Scott Buckley music cues + 71 Sonniss effects on their words; WAVs built by `make_audio.py` into git-ignored `audio/lib/`. Mixer now supports recorded `music` cues. Full mix measured -14.0 LUFS, LRA 5.3. |
| Overlays (DONE) | `make_overlays.py` renders the chapter cards (ch1-ch4) and two real headlines (NPR arrest 25/03/2023, Euronews verdict 19/12/2023) with HyperFrames into git-ignored `overlays/out/`; the final render composites them under the captions (`overlays` key). |
| (old sound plan) | Not mixed yet. Plan: Buckley score per chapter (Eyes In The Void cold open, Anabasis I ch1, Penumbra ch2 origin, Aphelion ch3 escalation, Starfire/Born Of The Sky ch4 + end), Sonniss SFX per beat (Braams on reveals, Colossal Impacts on the blast/collapse, Arc for the machine, Extreme Winds for Latveria, crowd for Hall H, Paper Foley for comics). Check that `ambience`/beds accept `file` (AUDIO_SPEC says one-shots do). |

## Known soft spots (fix before final)

- Gallery: the helmet's red crown pokes up like horns; the gold faceplate shows the red shell through the mouth slot.
- board_contract is dim; the contract barely reads. board_empty opens on the end of the fall.
- The arrest headline (c1m) and the chapter cards still need their HyperFrames overlays (exact headline text, sourced).


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
