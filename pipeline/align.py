"""Word timings for captions: Gemini listens to a narration clip and returns
each word with its start/end time. Cached next to the clip.

Gemini TTS gives no timestamps, so this is how captions stay in sync. The
script text is passed in so the transcript keeps the script's spelling; times
are sanity-checked and repaired (monotonic, inside the clip).
"""
from __future__ import annotations

import base64
import json
import re
import time
import urllib.error
import urllib.request
from pathlib import Path

import tts

MODEL = "gemini-3.5-flash-lite"  # ~4 s per clip; the full flash models think for minutes on this
API = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"

PROMPT = """You are a forced aligner. The audio is a narration of exactly this script:

{script}

Return JSON only: a list of objects {{"w": word, "s": start_seconds, "e": end_seconds}}, one per
spoken word of the script, in order, spelled exactly as in the script (keep punctuation attached
to the word). Times are seconds from the start of the audio, to 2 decimals. If the audio contains
extra speech that is not in the script, list those words too, with "extra": true."""


def _call(audio: bytes, prompt: str) -> str:
    body = {"contents": [{"parts": [
                {"inlineData": {"mimeType": "audio/wav", "data": base64.b64encode(audio).decode("ascii")}},
                {"text": prompt}]}],
            "generationConfig": {"responseMimeType": "application/json", "temperature": 0}}
    req = urllib.request.Request(API.format(model=MODEL), data=json.dumps(body).encode("utf-8"),
                                 headers={"x-goog-api-key": tts.api_key(), "Content-Type": "application/json"})
    delay = 4.0
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=180) as resp:
                data = json.load(resp)
            return data["candidates"][0]["content"]["parts"][0]["text"]
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 503) and attempt < 4:
                time.sleep(delay)
                delay *= 2
                continue
            raise SystemExit(f"ERROR: alignment failed ({e.code}): {e.read().decode('utf-8', 'replace')[:400]}")
    raise SystemExit("ERROR: alignment failed")


def words(wav: Path, script: str) -> list[dict]:
    """[{"w", "s", "e"(, "extra")}] for a narration clip, cached as <wav>.words.json."""
    cache = wav.with_suffix(".words.json")
    if cache.exists():
        return json.loads(cache.read_text(encoding="utf-8"))
    raw = _call(wav.read_bytes(), PROMPT.format(script=script))
    # The model sometimes appends text after the JSON array: parse the first value only.
    items, _ = json.JSONDecoder().raw_decode(raw.strip())
    dur = tts.duration(wav)
    out, last = [], 0.0
    for i, it in enumerate(items):
        s = min(max(float(it.get("s", last)), last), dur)
        # A missing end time: the next word's start (or the clip's end).
        nxt = items[i + 1].get("s") if i + 1 < len(items) else None
        e = float(it.get("e", nxt if nxt is not None else dur))
        e = min(max(e, s + 0.05), dur)
        rec = {"w": str(it["w"]), "s": round(s, 3), "e": round(e, 3)}
        if it.get("extra"):
            rec["extra"] = True
        out.append(rec)
        last = s
    cache.write_text(json.dumps(out, indent=1), encoding="utf-8")
    return out


def script_words(text: str) -> list[str]:
    return re.findall(r"\S+", text)
