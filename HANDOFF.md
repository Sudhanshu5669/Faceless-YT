# Handoff: where TownForge is, and what to do next

*Last updated 2026-11-23. Read this first in a new session (Claude, Codex or anyone), then
`AGENTS.md` and the `toon-short` skill. Keep this file short: current state and next steps only.
Older session notes (detailed per-shot history, plans, gotchas) are in
[`docs/history/handoff-log-2026-11.md`](docs/history/handoff-log-2026-11.md).*

## State

- **Repository:** pushed to `github.com/Sudhanshu5669/Faceless-YT` (`origin`, branch `main`).
  The working tree is clean; commit directly on `main`.
- **Skill:** `.claude/skills/toon-short/` was reorganised on 2026-11-18 into `SKILL.md` (workflow,
  standing rules, checklists) plus `references/` (cinematics, realism, assets, motion,
  script-and-gags, vocabulary). Add new lessons to the matching reference file.

## Episodes

| Episode | State | Next |
|---|---|---|
| `silkyara_rescue` | All 55 shots approved; final render done at 60 fps (`renders/silkyara_rescue.mp4`, 134.5 s, −14.1 LUFS). Thumbnail scripts in `thumbnail/`. | The user reviews the final MP4. Open accuracy flag: the approved `demolition` shows a two-storey facade; reporting describes Hasan's house as single-storey (tell the user before changing an approved shot). **Before publishing:** `audio/` (cough, mountain_wind, rockfall, underground) has no SOURCES.md; find where these recordings came from and confirm their licence. |
| `jio_story` | Final rendered (`renders/jio_story.mp4`, 129.6 s, 60 fps). Some early shots still have labelled-cube debt (see the history log, "No generic labelled cubes"). | Only if the user asks for a v2. |
| `mumbai_lunch` | First shot (`00_kitchen`) built with local Qwen narration and recorded effects; plan in `beats.md`. | Wait for the user's verdict on the kitchen shot, then the Dadar lane shot. |
| `dream_town` | Script drafts (`script.md`, `script_long_draft.md`), set `specs/sets/dream_town_opening.json`, an opening gag. | Pitch/script approval with the user before building shots. |
| `pokhran` | **In progress (2026-11-23), shots 0-18 of 58 built.** Browser loop: `tf shot pokhran --serve`. **Approved (16):** hook_feed, hook_analyst, feed_rewind, range_noon, shaft_dive, lid_chalk, device_inside, rewind, range_1995, sat_turn, nyt_slap, wisner_photos, rao_phone, shovel_back, office_1998, vajpayee_order. **Rendered, self-reviewed, awaiting the user:** same_desert (dusk, `library:sky_pass` satellite glint), team_lookup (four of the team look up, turn to each other on "nothing"). **WIP:** night_work: built (`LOOK_NIGHT`, range param `night`: shaded work lamp + hand torch; actors `night_bag` carrying a sandbag, `night_torch`), one clip rendered but **not yet looked at**; the storyboard was too dark (bodies unreadable), so a faint moon rim light was added; check the clip, fix, commit. **Workflow (user, 2026-11-23):** they found pokhran slow vs mangalyaan; build the rest in batches, self-review with storyboard stills (`tf storyboard pokhran --shots X`), render clips only once stills look right, present batches together. **Open question for the user:** they asked for a "real nuclear blast with a mushroom cloud"; Pokhran-II was underground (no mushroom cloud; beats.md and the PM's statement say so). Offered: a grand, true underground heave (dome, shock ripple, dust curtain, crater), or a "what you're imagining" mushroom beat cut off by "Nope. Underground." Wait for their answer before building `desert_jumps`. New this session: `toon_kalam` (hair `mop`), `toon_chidambaram` (outfit `safari`), actor cue `head` for look up/turns (already existed; `actor.tilt_head` + pm_office `heads` also added), camera moves with `start`/`end`, `library:sky_pass`. Places: range (`gags/range.gd`, 1995/1998 eras via `y1995`; looks AFTERNOON, 1995, DUSK, NIGHT, DIVE, DEEP), orbit, office (`gags/pm_office.gd`), desk/analyst room, lawn. Blender scripts in `episodes/pokhran/blender/` -> `incoming/pokhran_blender/`. | Finish night_work, then truck_park, photos_same, dune_shape, net_drape, pass_watch, statue, cricket... (beats.md table). Lens note: `lens_mm` sets the vertical field of view in 9:16 (24 mm is very wide). **Do not render when the user says so or on battery/power cuts** (damaged battery). |
| `mangalyaan` | **Final rendered (2026-11-19).** All 49 shots approved (21 in the shot loop, the rest by the user in chat). `renders/mangalyaan.mp4`: 1080x1920, 60 fps, motion blur 2, 154.1 s, -14.0 LUFS, Gemini single take (Charon). Effects are the built-in synthesised ones (no recorded audio to license). | Description credits: "Planet textures: Solar System Scope (solarsystemscope.com), CC BY 4.0" and "Curiosity and MAVEN 3D models: NASA/JPL-Caltech". Thumbnail, title and description if the user asks. |
| `supermarket_silence`, `blackwood_333` | Early pipeline tests, parked. | — |

## Practical notes

- Run `python pipeline/tf.py test` before committing (42 Godot + 20 Python tests). If the sandbox
  temp dir causes `os.replace` errors on Windows, set TEMP/TMP to `output/test_temp`.
- Edit an episode's `make_episode.py`, not its `episode.json` (the script generates it).
- Narration is one cached take per episode; Gemini's free tier allows about 10 TTS requests a day
  per model, so don't regenerate casually.
- Power cuts happen: after a restart, check JSON and Python files parse and run `git status`.
- Write long text and patch scripts with file tools, not bash heredocs (quotes break them).
