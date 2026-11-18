# Handoff: where TownForge is, and what to do next

*Last updated 2026-11-18. Read this first in a new session (Claude, Codex or anyone), then
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
| `mangalyaan` | **Second frame review (2026-11-19).** User approved 3-12, 15, 17, 20-23, 25, 28-33, 35-37, 39, 44-45 of the first pass. Reworked since: new hook (busy Manek Chowk street → meter ₹10 → the same auto in space beside Mars, meter ₹7; ending = the space auto in Mars orbit), Sriharikota launch hall (mission_control.gd mode "launch"), Sun-centred transfer map replacing the beard gag, broadside budget scale, catapult at chest, bigger price tags, chair/paper/rover/ATM/NYT-facade fixes, floating cash bug. Gemini single take (Charon, 154 s, 49 shots). Frames: `preview/frames_all/`, page `preview/frames.html`. | User reviews the new frames; then shot clips and the final render. |
| `supermarket_silence`, `blackwood_333` | Early pipeline tests, parked. | — |

## Practical notes

- Run `python pipeline/tf.py test` before committing (42 Godot + 20 Python tests). If the sandbox
  temp dir causes `os.replace` errors on Windows, set TEMP/TMP to `output/test_temp`.
- Edit an episode's `make_episode.py`, not its `episode.json` (the script generates it).
- Narration is one cached take per episode; Gemini's free tier allows about 10 TTS requests a day
  per model, so don't regenerate casually.
- Power cuts happen: after a restart, check JSON and Python files parse and run `git status`.
- Write long text and patch scripts with file tools, not bash heredocs (quotes break them).
