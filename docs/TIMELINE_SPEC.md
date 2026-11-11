# Timeline: episodes, shots and rendering

An **episode** films one set with a cast as an ordered list of timed shots. It lives at
`episodes/<id>/episode.json`. Renders go next to it (git-ignored): `renders/` (final),
`preview/` (storyboard, draft animatic).

```json
{
  "schema_version": "0.1",
  "id": "blackwood_333",
  "title": "In this town, everyone freezes at 3:33 AM",
  "set": "specs/sets/blackwood_333.json",
  "format": { "resolution": [1080, 1920], "fps": 30 },
  "actors": [
    { "id": "kid", "character": "kid", "at": { "anchor": "house_9.lawn", "offset": [0, 0, 1] },
      "action": "idle", "cues": [ { "t": 12.4, "action": "jump" }, { "t": 13.1, "hold": true } ] }
  ],
  "shots": [
    { "name": "establishing", "duration": 4.0,
      "camera": { "from": { "template": "establishing_drone", "subject": "house_9" },
                  "to": { "at": { "anchor": "house_9", "orbit": { "distance": 22, "angle": 20, "height": 9 } },
                          "look_at": "house_9.front_door", "lens_mm": 28 },
                  "ease": "in_out" } },
    { "name": "kid_jump", "duration": 3.5,
      "camera": { "at": { "anchor": "kid", "offset": [3.2, 1.0, 0.4] },
                  "look_at": { "anchor": "kid", "offset": [0, 1.1, 0] }, "lens_mm": 35 } }
  ]
}
```

## Episode fields

| Field | Meaning |
|---|---|
| `id` | Folder and file name of the renders. |
| `title`, `description` | For humans (and later, packaging). |
| `set` | Path of a set spec. Its `set` and `look` are used; its `preview` is ignored. |
| `look` | Optional: replaces the set spec's look (preset name or object, see LOOK_SPEC.md). |
| `actors` | Optional: replaces the set spec's actors. Cues usually live here (see ACTOR_SPEC.md). |
| `format` | `resolution` `[w, h]` (default `[1080, 1920]`, 9:16 Shorts; use `[1920, 1080]` for long-form) and `fps` (default 30). |
| `shots` | The edit, in order. |

## Shots

| Field | Meaning |
|---|---|
| `name` | Unique, file-name safe (no spaces). Used for the shot's frame folder and for `--shots`. |
| `duration` | Seconds on screen. |
| `camera` | A camera description (CAMERA_SPEC.md: view, template, or `at`/`look_at`/lens…), or a **move**. No `t`: time comes from the timeline. |
| `scene_t` | Optional: scene time at the start of this shot. Default: where the previous shot ended. Use it for replays, overlapping coverage of the same moment, or time jumps. |
| `note` | Free text for the director (intent, what must read). |
| `whip_in`, `whip_out` | `left` `right` `up` `down`: a fast camera swing at the cut (adds a whoosh; use `format.motion_blur`). |
| `iris_in`, `iris_out` | `binoculars` or `circle`: the frame seen through a mask; `iris_in` holds 0.7 s, then opens over 0.6 s. Push the previous shot's camera into a pair of binoculars for a point-of-view cut. Drawn by the grade overlay (`iris_shape` / `iris_radius` shader globals, set per frame). |

**Scene time** runs continuously across cuts: shot 2 starts where shot 1 ended unless it sets
`scene_t`. Actor cues are in scene time, so the edit never changes what the actors do, only
what we see.

### Camera moves

```json
"camera": { "from": { ...camera... }, "to": { ...camera... }, "ease": "in_out" }
```

Both ends are resolved **at every frame** against the actors at that moment, so a move
whose ends are anchored to an actor follows them. Position and lens interpolate linearly,
rotation by slerp. `ease`: `linear`, `in`, `out`, `in_out` (default). A static camera aimed
at a moving actor (`"look_at": "stranger.head"`) pans to follow.

**Anchor the camera to the place, not to the actor, unless you want it to move with them.**
An offset from an actor (`{"anchor": "you", "offset": [-1, 1.5, 2]}`) is in the actor's own
frame, so when the actor turns, the camera swings around them. For a steady camera on a
character who turns, hang it off a place (`house_9.front_door`) and `look_at` the actor.

Common moves: push-in (same `look_at`, `to` closer), dolly (`from`/`to` offsets slide
sideways along a street anchor), crane-down (`orbit` high to `orbit` low), rack between two
subjects (`look_at` A then B).

## Commands

```bash
python pipeline/tf.py validate episodes/blackwood_333/episode.json   # resolves every camera at start/mid/end
python pipeline/tf.py storyboard blackwood_333                       # preview/storyboard.png: one row per shot (start, middle, end)
python pipeline/tf.py render blackwood_333 --draft                   # preview/animatic/<id>_animatic.mp4 (half size, 15 fps)
python pipeline/tf.py render blackwood_333                           # renders/<id>.mp4 (full format)
python pipeline/tf.py render blackwood_333 --shots kid_jump          # re-render one shot, re-assemble
```

Validation fails on unknown anchors, keys, actions or freeze marks. It warns
(`WARN shot <name>: subject hidden behind ...`) when a tree or house blocks the subject.

**Workflow:** write the episode → `storyboard` → read `storyboard.png` (and single stills in
`preview/storyboard/`) → fix framing and timing → `render` → check the video
(`ffmpeg ... -vf fps=4,tile=8x2` turns a stretch into one image to look at).

## How rendering works

- Godot runs with `--fixed-fps <fps>`, so every frame advances exactly 1/fps. Actors are
  posed and the camera placed from the frame's scene time. Nothing reads the wall clock.
- Shaders (sky stars and clouds, film grain) use the global `scene_time`, not engine `TIME`.
  Rain and snow restart with a fixed seed at every cut.
- After each cut, 30 warm-up frames render unsaved, so volumetric fog history settles on the
  new camera.
- Frames are captured from the main viewport (grade included) and **piped raw straight into
  one ffmpeg per shot** (`renders/shots/<NN>_<shot>.mp4`; motion-blur sub-frames are averaged
  there with `tmix`). No PNGs touch the disk (a 60 fps final with blur 3 would otherwise write
  ~23 GB). `--png` keeps the old path: `renders/frames/<NN>_<shot>/00000.png`, then encode.
  `renders/frames/timeline.json` is written either way. Shots are joined without re-encoding.
- **Encoder:** H.264 on the GPU (`h264_nvenc`, CQ 19) when a 1-frame test encode works, else x264
  (CRF 18) on the CPU. `config.local.json` `"video_encoder": "nvenc" | "x264"` forces one. The
  ffmpeg 9 build needs NVIDIA driver 610+ for NVENC (an older driver falls back to x264).
- **Determinism:** the same command gives bit-identical frames. A shot re-rendered alone
  matches the full render to about 66 dB PSNR (single-level differences from fog history:
  invisible), so `--shots` is safe.
- Speed on the RTX 4050: about 10 frames/s at 1080×1920 (a 30 s Short renders in about 75 s).
  The jio_story final (130 s, 60 fps, blur 3 = 23,346 frames, 160 toons) took 40 min to draw
  (PNG path) plus ~5 min of x264 encoding; most CPU load was PNG compression and x264.

## Set events

Switch things in the set on and off over time: toy eyes, ceiling lights, freezers.

```json
"events": [
  { "t": 0, "target": "fixture_21", "state": "on" },
  { "t": {"line": "toy2", "offset": -0.3}, "target": "toy_hero", "state": "flicker" },
  { "t": {"line": "n6", "word": "batteries", "edge": "end"}, "target": "toy_hero", "state": "off" },
  { "t": {"line": "toy3"}, "target": "toys", "state": "on" }
]
```

`target` is a switchable's name or group (the set's manifest lists them); `state` is `on`, `off`
or `flicker` (a deterministic stutter). The state at any moment is a pure function of time.
Unknown targets fail validation.

## Sound, voice-first timing, `skip`

Narration, effects, captions, `"fit"` durations, `"skip"` (jump story time at a cut) and time
references like `{"line": "n6", "word": "grab"}` are in **AUDIO_SPEC.md**.

## Not yet

- Per-shot look changes (one look per episode; the set is built once).
- Transitions other than cuts (fades, match cuts), camera shake / handheld noise.
- Shot cache by content hash (re-render only what changed, automatically).
