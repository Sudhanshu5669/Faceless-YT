# TownForge

**An AI-directed studio for faceless YouTube Shorts.** An LLM (Claude, Codex…) acts as the
director: it writes the script, the beat sheet and JSON specs. Godot 4 builds the world, films it
with a real camera, and Python turns it into a finished, narrated, captioned video. No
generative image or video services are involved: every frame is rendered.

The house style: **toon actors** (sphere heads with drawn faces that swap to act) **in realistic,
cinematically lit sets**, fast second-person or true-story narration, every noun appearing on its
word and every number landing as a counter on the spoken number.

```
 pitch ─► script ─► beat sheet ─► voice (TTS + forced alignment)
                                        │ word times
                                        ▼
 sets · looks · actors · gags ─► episode.json ─► Godot (one shot) ─► you approve ─► next shot
                                                                              │
                                              final render (1080×1920, 60 fps) ◄┘
                                              + sound mix, captions, −14 LUFS
```

## What's in the box

| Layer | What it does | Docs |
|---|---|---|
| **Sets** | procedural towns, supermarkets, downtown blocks, neon stage bays, India-first streets and interiors; every place has named anchors | [SET_SPEC](docs/SET_SPEC.md) |
| **Looks** | time of day, weather, fog, sky bodies, palette, grade; saved looks like `toon_drama`, `night_fog` | [LOOK_SPEC](docs/LOOK_SPEC.md) |
| **Camera** | anchors, lenses, depth of field, moves, whip pans, iris POV cuts, shake, shot templates | [CAMERA_SPEC](docs/CAMERA_SPEC.md) |
| **Actors** | toon cast with 27 expressions, 47 actions, routes, crowds, procedural crawl/haul poses | [TOON_SPEC](docs/TOON_SPEC.md), [ACTOR_SPEC](docs/ACTOR_SPEC.md) |
| **Reveals & gags** | things that arrive on a word, counters, custom GDScript set pieces per episode | [REVEALS_SPEC](docs/REVEALS_SPEC.md), [GAGS_SPEC](docs/GAGS_SPEC.md) |
| **Motion** | anticipation, easing, squash, arcs, follow-through, impact tiers | [MOTION_SPEC](docs/MOTION_SPEC.md) |
| **Timeline** | episodes, timed shots, set events, storyboard, video render | [TIMELINE_SPEC](docs/TIMELINE_SPEC.md) |
| **Audio** | Gemini or local Qwen TTS, forced-aligned word times, synthesized effects, beds, ducking, captions | [AUDIO_SPEC](docs/AUDIO_SPEC.md) |
| **Review** | shot-by-shot approval page and the approval board that gates the final render | [REVIEW](docs/REVIEW.md) |
| **Assets** | import CC0 / Fab packs into a searchable model catalog and kits | [ASSET_PIPELINE](docs/ASSET_PIPELINE.md) |

Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Goals and roadmap:
[docs/VISION_AND_ROADMAP.md](docs/VISION_AND_ROADMAP.md).

## The director's skill

The craft lives in a Claude Code skill: [`.claude/skills/toon-short/`](.claude/skills/toon-short/SKILL.md).
It covers the whole loop: pitch and script formulas, inventing a physical sight gag for every
line, **cinematography** (9:16 framing, lenses, moves, lighting, coverage, pacing), **realism**
(researching places, materials, atmosphere, crowds with jobs, bodies that act, factual accuracy),
motion, **asking the user before downloading any asset** (with licence, source and size), the
shot-by-shot review loop and the final render. Other agents read [AGENTS.md](AGENTS.md).

Open the repo in Claude Code and ask for a video ("make a Short about…"); the skill loads itself.

## Setup

Requirements: Windows/Linux, **Godot 4.7.2**, **ffmpeg**, **Python 3.11+**, a GPU that runs
Godot's Forward+ renderer (developed on an RTX 4050 6 GB).

```bash
pip install -r requirements.txt
cp config.example.json config.local.json     # set the Godot and ffmpeg paths
echo GEMINI_API_KEY=... > .env               # narration (Gemini TTS); or set up local Qwen TTS
```

1. **Alignment model** (word timing, 378 MB): put the wav2vec2 ONNX model in `models/alignment/`
   (see [AUDIO_SPEC](docs/AUDIO_SPEC.md)).
2. **Asset packs:** the 3D packs aren't in the repo. Download the zips listed in
   [`pipeline/asset_packs.json`](pipeline/asset_packs.json) (each entry has its source URL and
   licence; Kenney and Quaternius are CC0) into `incoming/`, then run
   `python pipeline/tf.py assets import`.
3. Check everything: `python pipeline/tf.py test`.

## Everyday commands

```bash
python pipeline/tf.py library                      # looks, shot templates, kits, characters
python pipeline/tf.py props <words>                # search the model catalog
python pipeline/tf.py preview-set specs/sets/blackwood.json   # set stills + contact sheet
python pipeline/tf.py voice <episode>              # narration + word timing table
python pipeline/tf.py storyboard <episode>         # start/mid/end of every shot in one image
python pipeline/tf.py shot <episode> <shot>        # render one shot for review (clip + strip + framing)
python pipeline/tf.py shot <episode> --serve       # the review page: watch, approve, request changes
python pipeline/tf.py framing <episode>            # is anything cut off in 9:16?
python pipeline/tf.py render <episode>             # the final video
python pipeline/tf.py explore [set]                # fly through a set interactively
```

## Episodes

| Episode | What | State |
|---|---|---|
| [`silkyara_rescue`](episodes/silkyara_rescue) | The 2023 Silkyara tunnel rescue and the rat-hole miners, 55 shots | final rendered (60 fps) |
| [`jio_story`](episodes/jio_story) | How Mukesh Ambani built Jio, 52 shots | final rendered |
| [`mumbai_lunch`](episodes/mumbai_lunch) | How Mumbai's dabbawalas deliver lunch by train | in progress |
| [`dream_town`](episodes/dream_town) | "In this town, nobody is allowed to dream" | script draft |
| [`supermarket_silence`](episodes/supermarket_silence), [`blackwood_333`](episodes/blackwood_333) | early pipeline tests | parked |

Each episode folder holds the script, beat sheet, `make_episode.py` (generates `episode.json`),
gag scripts and the review decisions. Renders, previews and builds are git-ignored.

## Repository layout

```
.claude/skills/toon-short/   the director's skill (SKILL.md + references/)
docs/                        engine specs; docs/history/ holds old session logs
episodes/<id>/               scripts, beats, episode generator, gags, review decisions
godot/                       the Godot project: generators, builders, actors, camera, timeline, shaders, tests
library/                     looks, shot templates, characters, kits, gags, logos, generated model catalog
pipeline/                    tf.py CLI, TTS, alignment, sound, review server, asset import
specs/sets/                  set specs
tests/python/                Python tests
```

## Principles

- **The LLM directs, the engine executes.** Specs name places and things; they never hold raw
  coordinates for objects.
- **Deterministic.** The same spec and seed give identical frames.
- **Licensed assets only.** CC0 or licences that allow commercial video; each pack keeps its
  licence, and CC-BY credits go in the video description.
- **Accurate.** Real people, companies and events are shown faithfully, with sources kept.
