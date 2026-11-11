# TownForge: vision and roadmap

The plan in one place. Read it at the start of a session. Update the **Status** and **Roadmap**
sections when a milestone lands.

## Vision

**Goal: grow a YouTube channel** by outperforming every other AI storytelling channel.
The engine matters only as far as it produces high-quality episodes quickly and reliably.

**Content:** hypotheticals, mostly second person: *"What if you got stuck in a supermarket during
a zombie apocalypse?"*, *"In this town, everyone freezes at 3:33 AM"*. It's inspired by the Roblox
"In this town…" hypotheticals, but **not locked to one visual style**. That freedom is why we use
Godot: real 3D sets, real camera work, consistent characters, and any look from cosy to absurd.

**Format:** Shorts first (vertical 9:16, 30–60 s), long-form (16:9, several minutes) later.
Aspect ratio is a setting, never hard-coded.

**Story world:** mixed. Some prompts become recurring series (saved towns and characters), others
are one-off anthology episodes. A generated set is fully described by `generator + seed + params`,
so any one-off can be promoted to a recurring location.

**Narration, not dialogue:** a "what if YOU…" voice-over. That avoids lip sync, and characters act
through body language and camera. The faceless mannequins suit the liminal-horror tone.

## Why we can win

Most AI story channels are TTS over AI-generated stills: inconsistent characters, no real camera
movement, no staging. We beat that on all three, and add two things they lack:

1. **The LLM directs, the engine executes.** Specs name things (`house_4.front_door`, `low_hero`,
   `night_fog`); they never hold raw geometry. Quality comes from a growing vocabulary of looks,
   shot templates, characters, actions and set generators, each tested to look good.
2. **A learning loop.** Retention data from published episodes feeds a playbook. The next
   episode starts from what worked: which hooks held, where viewers dropped off.

## The episode workflow (target)

Three human checkpoints (◆). Everything else is automated.

| # | Stage | Who | Output |
|---|---|---|---|
| 1 | **Pitch**: 3 angles on the prompt, each with hook, title, escalation, ending | Claude → ◆ you pick one | `pitch.md` |
| 2 | **Script**: write, critic pass (hook, clarity, escalation, payoff, pacing), rewrite. Each line is narration + a visual beat. Every beat is checked against the library | Claude → ◆ you approve | `script.md` |
| 3 | **Casting & sets**: map beats to characters, set generators, looks. Ask the user only when a new asset is needed | Claude | `cast.json` |
| 4 | **Voice first**: TTS narration, so real line lengths set shot timing | Engine | `audio/vo_*.wav` |
| 5 | **Shot plan**: timed shots, camera moves, actor actions, looks. Validated | Claude + engine | `episode.json` |
| 6 | **Storyboard**: contact sheet (start/mid/end per shot) + low-res animatic. Claude reviews frames first, then ◆ you watch and leave notes; only changed shots re-render | Engine + Claude → ◆ you | `preview/` |
| 7 | **Final render**: Godot Movie Maker, 1080×1920 PNG sequence at fixed fps, cached per shot | Engine | `renders/` |
| 8 | **Post**: SFX, a music bed that dips under narration, word-by-word captions, FFmpeg assembly | Engine | |
| 9 | **QA + package**: black/frozen frames, loudness −14 LUFS, length; thumbnail shot; title and description | Engine | `final/` |
| 10 | **Learn**: you paste retention numbers; the playbook is updated | You + Claude | `docs/playbook.md` |

Episode folder: `episodes/<id>/` with `pitch.md`, `script.md`, `episode.json`, `notes.md`,
`state.json` (resumable), `audio/`, `preview/`, `renders/`, `final/`.

The creative stages (1, 2, 5, review in 6) become **project skills** in `.claude/skills/`
(`/pitch`, `/write-script`, `/plan-shots`, `/review-storyboard`), each with a quality rubric.

## Status

| Layer | State | Doc |
|---|---|---|
| Sets: procedural suburban town, named places, addresses | ✅ done | SET_SPEC.md |
| Looks: time and weather models, free overrides, sky bodies, palette, grade, saved looks | ✅ done | LOOK_SPEC.md |
| Cameras: anchors, composable shots, lenses, DOF, templates, line-of-sight warnings | ✅ done | CAMERA_SPEC.md |
| Assets: 10 CC0 packs, catalog of 494 models, suburban kit (recoloured houses, seasonal trees, cars) | ✅ done | ASSET_PIPELINE.md |
| Actors: 10 characters, 47 actions, routes, crowds, `pose_at(t)` deterministic | ✅ done | ACTOR_SPEC.md |
| Timeline + video render: episode.json, camera moves, actor cues/holds, storyboard, MP4 | ✅ done | TIMELINE_SPEC.md |
| Voice and post: Gemini TTS (batched, cached), voice-first timing, word refs, synthesized SFX/beds, ducking, −14 LUFS, word-by-word captions | ✅ done (draft) | AUDIO_SPEC.md |
| Sets: supermarket (procedural), set events (switchable toys/lights) | ✅ done | SET_SPEC.md |
| Review board: approve environment → characters → script & voice → shots (local web page, Claude's suggestions, final render gated) | ✅ done | REVIEW.md |
| QA + packaging (thumbnail, title, description), shot cache | planned | |
| Creative skills (pitch, script, shot plan, review) | planned | |
| Episode manager (state.json, resumable pipeline) | planned | |

## Roadmap

1. ~~**Timeline and first clip.**~~ Done: `episodes/blackwood_333` renders a 31.5 s silent
   Short (9 shots, everyone-freezes beat). Frames are captured directly from the viewport
   under `--fixed-fps` (more control than Movie Maker: warm-up frames at cuts, per-shot folders).
2. ~~**Voice and post.**~~ Done (draft): `episodes/supermarket_silence` ("A Toy Starts Talking"),
   a 64.7 s Short with Gemini TTS narration, word-by-word captions, synthesized effects and beds,
   −14 LUFS. Remaining: final narration on the full TTS model, real SFX samples, a music bed.
3. **Storyboard checkpoint.** Storyboard + draft animatic exist (`tf storyboard`, `render --draft`);
   still to do: notes → JSON edits, shot cache by hash (re-render only what changed).
4. **Creative skills.** `/pitch`, `/write-script` (with critic rubric), `/plan-shots`,
   `/review-storyboard`; `docs/playbook.md`.
5. **First full episode:** "Blackwood: 3:33 AM", 30–60 s Short, end to end.
6. **More sets:** ~~supermarket~~ (done; dressed with the Fab `supermarket` kit), ~~downtown~~ (done: `downtown` generator, Quaternius Downtown kit),
   school, forest road, house interiors (Fantasy Props kit is imported).
7. **Character upgrades:** blending between actions, simple pathfinding, Kenney characters via
   retargeting (zombie/survivor skins), per-model door positions for kit houses.
8. **Learning loop:** retention logging per episode, playbook updates, A/B hooks.
9. **Long-form:** 16:9, multi-location episodes, chapters.

## Known gaps

- Switches between actions are instant (only clip segments inside one action blend); routes are
  straight lines between waypoints.
- One look per episode (no per-shot look changes); only hard cuts.
- Kit-house `front_door` anchors sit at the centre of the front face (Kenney doors are often off-centre).
- Palette recolouring reaches kit houses but not kit trees or cars.
- Kenney animated characters use a different skeleton (need retargeting).

## Working agreements

- Commit directly on `main`, only when asked.
- Run `python pipeline/tf.py test` before finishing any change. After any visual change, render
  previews and **look at them**.
- Only CC0 (or similarly permissive) assets; keep each pack's LICENSE.txt.
- Hardware budget: RTX 4050 6 GB, 16 GB RAM, Windows 11. Godot 4.7.2 at `E:\AgentTools\`.
