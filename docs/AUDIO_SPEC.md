# Sound: narration, timing, captions, effects

Episodes are **voice first**: the narration is spoken (Gemini TTS) before anything is rendered,
and its real length sets the shot lengths. Every time in the episode can point at a word of the
narration, so re-recording a line re-times the whole edit by itself.

```bash
python pipeline/tf.py voice <id>             # speak + time every line, print the timing table (no render)
python pipeline/tf.py storyboard <id>        # resolves the voice first, then stills
python pipeline/tf.py render <id>            # picture + soundtrack + captions -> renders/<id>.mp4
python pipeline/tf.py render <id> --remix    # sound and captions only, over the rendered picture
```

The key is `GEMINI_API_KEY` in `.env` at the repo root (git-ignored). Every take is cached in
`output/tts_cache/` by (model, voice, style, text), so re-renders never call the API again.

## Narration and lines

```json
"narration": { "voice": "Charon", "style": "low, tense, intimate horror narration, slightly slow", "speed": 1.22 },
"lines": [
  { "id": "toy1", "text": "Let's play!", "voice": "Leda", "style": "cheerful, bright, sing-song toy voice",
    "fx": "toy", "shot": "toy_wakes", "at": 0.35, "speed": 1.0 },
  { "id": "n1", "text": "Three A.M. Aisle six. And a toy just said: let's play.", "shot": "horde_turns", "at": 0.2 }
]
```

| Field | Meaning |
|---|---|
| `voice` | A Gemini prebuilt voice (Charon, Kore, Enceladus, Algenib, Leda, Puck…). Default: `narration.voice`. |
| `style` | Short delivery direction, sent as a `[bracket tag]` (a "Say it like…:" prefix gets read aloud). |
| `speed` | Time-stretch with pitch kept (ffmpeg `atempo`); word times are rescaled. |
| `shot`, `at` | The line starts `at` seconds into that shot (it may run past the cut). |
| `fx` | `toy` (pitched up, band-limited, bit-crushed) or `toy_chorus` (many toys, out of sync). |
| `gain` | dB. `caption: false` hides it from the captions. |

`narration.model` picks the TTS model (default `gemini-3.8-flash-tts`). For drafts,
`TOWNFORGE_TTS_MODEL=gemini-3.8-flash-lite-tts` overrides it without editing the episode.

**Quota and reliability.** On the free tier each TTS model allows 10 requests a day. Lines with
the same voice and style are spoken in batches of up to 30 words per request, then cut apart at the
quietest point between lines (an episode is about 4–5 requests). TTS sometimes stops before the last
word; the pipeline detects this (from the word timings) and retakes once with a throwaway word
after the last line. Word timings come from `gemini-3.5-flash-lite` listening to the take
(`pipeline/align.py`, cached as `.words.json`).

## Timing

Shot `duration` can be seconds, `"fit"` (its lines plus a 0.25 s tail), or
`{"fit": true, "min": 1.8, "tail": 0.6}`. `"skip": 6.0` on a shot jumps story time forward
at that cut (actors are further along; the edit is shorter).

**Time references** work anywhere a time is expected (actor cues, route `start`/`arrive`,
`events`, `sfx.at`, `ambience` curves):

| Form | Means |
|---|---|
| `12.5` | Scene seconds. |
| `{"shot": "reach", "at": 0.4}` | 0.4 s into a shot. |
| `{"line": "n8"}` / `{"line": "n8", "edge": "end"}` | When a line starts / ends. |
| `{"line": "n6", "word": "batteries", "edge": "end", "offset": 0.1}` | When a word starts (or ends). `"word": 3` = the 4th word. |

The resolver writes `episodes/<id>/build/episode.resolved.json` (numbers only) for Godot.

## Effects and beds

```json
"sfx": [ { "sound": "glass_bang", "at": {"line": "toy3", "offset": 0.5}, "repeat": 8, "every": 0.22, "gain": -5 } ],
"ambience": [
  { "sound": "zombies", "gain": -15, "duck": 0.5,
    "curve": [[0, 0.25], [{"line": "n7", "offset": -0.35}, 0.7], [{"line": "n7", "offset": -0.25}, 0.0]] }
],
"end_black": 1.5
```

- One-shots: `glass_bang`, `creak`, `sting` (1.4 s swell into a boom: place it 1.4 s early), `thud`, `click`.
- Beds (cover the whole episode): `room_tone`, `drone`, `zombies` (a groaning crowd), `heartbeat`.
  `curve` = [[time, level 0..1], …], linear. `duck` = how far the bed dips under narration.
- All sounds are synthesized (`pipeline/sfx.py`, numpy + scipy), deterministic and license-free.
  A CC0 sample pack can replace any of them under the same name later.
- The mix is limited and normalised to **−14 LUFS**, −1.5 dBTP (YouTube).

## Captions

Word-by-word, burned in (ASS via libass): chunks of up to 3 words, the spoken word in yellow,
toy lines in cyan italics. `"captions": {"position": 0.66, "max_words": 3, "enabled": true}`;
`position` is the fraction of the frame height (Shorts UI covers the bottom ~20%).
