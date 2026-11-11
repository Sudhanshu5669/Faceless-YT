"""Word timings for captions, reveals and cuts: CTC forced alignment of the known
script against the narration audio (pipeline/ctc_align.py). Cached next to the clip.

Gemini TTS gives no timestamps. This used to ask Gemini to listen and return
times; those were guesses that drifted by seconds. Now an acoustic model
(wav2vec2) measures them: offline, deterministic, never off the end of the clip.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

import ctc_align

CACHE_SUFFIX = ".ctc.json"


def words(wav: Path, script: str) -> list[dict]:
    """[{"w", "s", "e", "score"}], one per script word (script_words order), cached as
    <wav>.ctc.json. A low score (< 0.3) means the audio there doesn't sound like the word."""
    cache = wav.with_suffix(CACHE_SUFFIX)
    want = script_words(script)
    if cache.exists():
        data = json.loads(cache.read_text(encoding="utf-8"))
        if [w["w"] for w in data] == want:
            return data
    out = ctc_align.align(wav, want)
    cache.write_text(json.dumps(out, indent=1, ensure_ascii=False), encoding="utf-8")
    weak = [f"{w['w']}({w['score']:.2f})" for w in out if w["score"] < 0.3 and w["e"] > w["s"]]
    if weak:
        print(f"[TownForge] align: low-confidence words: {' '.join(weak[:12])}")
    return out


def script_words(text: str) -> list[str]:
    return re.findall(r"\S+", text)
