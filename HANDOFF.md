# Handoff: where TownForge is, and what to do next

*Last updated 2026-11-22. Read this first in a new session (Claude, Codex or anyone), then
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
| `pokhran` | **In progress (2026-11-22).** Pokhran-II heist ("India blew up the White House"). Script approved (`script.md`, sources), beats (`beats.md`, 58 shots), narration take timed (162.9 s, Gemini Charon). Poly Haven CC0 assets downloaded to `incoming/polyhaven_pokhran/` (`ASSETS.md`). Built: the US analyst's office (`gags/analyst_room.gd`: satellite feed on a CRT, blinds, snow globe, wall TV showing a live SubViewport of the PM's lawn) and a first lawn (`gags/pm_lawn.gd`). Hook shots `hook_feed`, `hook_analyst`, `snow_globe` rendered for review. | Hook shots APPROVED. Narration: the user wants more emotion. `make_episode.py` TAKE="tags" (lite model, one-word inline [tags] per line) gave a verbatim 172 s take except "deadpan" was read aloud twice; those two tags are now sighs/serious, so run `tf voice pokhran` once (1 lite request) and check its transcript, then re-render the hook shots and let the user listen. Never put content in a long style: take A (full model + long emotional score) improvised invented facts; `_check_verbatim` now fails such takes. Then the Pokhran range (desert: HDRIs + sandy_gravel_02, procedural Indian Army truck/Gypsy/AN-32 shot at distance, in dust or silhouette; a `fatigues` toon outfit). The user wants everything "extremely realistic and cinematic". |
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
