# TownForge architecture

## Goal

Grow a YouTube channel with "what if you…" hypothetical stories rendered in
stylized 3D. The human approves at three checkpoints (pitch, script,
storyboard); everything else is automated. Shorts (9:16) first, long-form later.

## Pipeline (target)

```
prompt → ① pitch ◆ → ② script ◆ → ③ casting & sets → ④ voice (TTS first)
       → ⑤ shot plan (episode.json) → ⑥ storyboard ◆ → ⑦ final render
       → ⑧ post (sfx, music, captions) → ⑨ QA + package → ⑩ learn
◆ = human checkpoint
```

Status: built so far are the **set layer** (procedural towns), the **look layer**
(time and weather models plus free-form overrides, see LOOK_SPEC.md), the **camera
layer** (anchors, shots and templates, see CAMERA_SPEC.md), the **asset layer**
(catalog and kits, see ASSET_PIPELINE.md) and the **actor layer** (characters,
actions, routes and crowds, posed as a pure function of time, see ACTOR_SPEC.md)
and the **timeline layer** (episode.json: timed shots, camera moves, actor cues,
storyboard and MP4 render, see TIMELINE_SPEC.md). Audio is next.

## Layers

| Layer | Who | What |
|---|---|---|
| Story | LLM + human | pitch.md, script.md |
| Direction | LLM | episode.json: shots, actions, camera, look — names only, no coordinates |
| World library | library/ | looks, (later) characters, props, animations, sfx |
| Engine | Godot | builds sets from specs, places actors, renders deterministically |
| Production | Python | runs Godot, TTS, FFmpeg, QA; tracks episode state |

## The set layer (built)

```
spec JSON ──► Spec.validate ──► SetBuilder.generate ──► layout (pure data, JSON-able)
                                        │                    │
                                        │                    ├─► manifest.json (named places, for the director)
                                        ▼                    ▼
                               Look.apply (env)     SetBuilder.build ──► Godot nodes
                                                                         │
                                                         Views.frame ──► camera ──► stills / explore
```

- **Generators** are deterministic: `(params, seed) → layout`. Each subsystem
  (names, houses, street cars, trees) has its own RNG stream, so tweaking one
  param doesn't reshuffle unrelated content.
- **Layouts carry semantics**: streets have names, houses have addresses and
  anchors (`front_door`, `lawn`, `driveway`, `backyard`, `curb`), the town has
  `town_center`, `main_street_*`, `town_entrance_*`. Shots target these.
- **Looks** are JSON presets applied on top of any set: sky, sun/moon, ambient,
  distance fog (fades to the horizon colour — no seams), volumetric fog, a low
  ground-fog volume, glow, grade, and practical lights (streetlights, windows,
  porch lights).
- **Views** are the first shot templates: `aerial`, `street`, `house[:id]`,
  `intersection`, `entrance`. They frame for portrait and avoid obvious
  occlusion (house view picks a house with a clear line of sight).

## Series vs anthology

A generated set is fully described by `generator + seed + params`. A one-off
town becomes a recurring series location by saving its spec; later, manual
overrides will layer on top (`seed + overrides`).

## Next layers

See **docs/VISION_AND_ROADMAP.md** for the full plan, current status and roadmap.
Next up: voice and post (narration, captions, SFX, music).
