"""Narration via Gemini text-to-speech (stdlib only).

The API key comes from GEMINI_API_KEY in the environment or in .env at the repo
root (git-ignored). Every line is cached by (model, voice, style, text) under
library/../output/tts_cache/, so re-rendering an episode never re-bills a line.
"""
from __future__ import annotations

import base64
import hashlib
import io
import json
import os
import time
import urllib.error
import urllib.request
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / "output" / "tts_cache"
DEFAULT_MODEL = "gemini-3.8-flash-tts"
API = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
SAMPLE_RATE = 24000  # Gemini TTS: 24 kHz, 16-bit mono


def api_key() -> str:
    key = os.environ.get("GEMINI_API_KEY", "").strip()
    env = ROOT / ".env"
    if not key and env.exists():
        for line in env.read_text(encoding="utf-8").splitlines():
            if line.strip().startswith("GEMINI_API_KEY="):
                key = line.split("=", 1)[1].strip().strip('"').strip("'")
    if not key:
        raise SystemExit("ERROR: no GEMINI_API_KEY (set it in .env at the repo root)")
    return key


def _cache_path(text: str, voice: str, style: str, model: str) -> Path:
    h = hashlib.sha256(json.dumps([model, voice, style, text]).encode("utf-8")).hexdigest()[:20]
    return CACHE / f"{voice}_{h}.wav"


def _to_wav(blob: bytes, mime: str) -> bytes:
    """Gemini returns either a WAV file or raw 16-bit PCM (audio/L16)."""
    if blob[:4] == b"RIFF":
        return blob
    buf = io.BytesIO()
    rate = SAMPLE_RATE
    if "rate=" in mime:
        rate = int(mime.split("rate=")[1].split(";")[0])
    with wave.open(buf, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(blob)
    return buf.getvalue()


def synthesize(text: str, voice: str, style: str = "", model: str = DEFAULT_MODEL,
               retries: int = 4) -> Path:
    """Speak `text` with a Gemini prebuilt voice; `style` is a short delivery
    direction ("low, tense, intimate whisper"), sent as a [bracket tag]. Returns the cached WAV path."""
    out = _cache_path(text, voice, style, model)
    if out.exists():
        return out
    CACHE.mkdir(parents=True, exist_ok=True)
    # Direction goes in a leading [bracket tag]: a "Say it like this: ..." prefix
    # gets read aloud by the newer TTS models, a tag does not.
    prompt = f"[{style.strip()}] {text}" if style.strip() else text
    body = {"contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"responseModalities": ["AUDIO"],
                                 "speechConfig": {"voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voice}}}}}
    req = urllib.request.Request(API.format(model=model), data=json.dumps(body).encode("utf-8"),
                                 headers={"x-goog-api-key": api_key(), "Content-Type": "application/json"})
    delay = 4.0
    for attempt in range(retries + 1):
        try:
            with urllib.request.urlopen(req, timeout=180) as resp:
                data = json.load(resp)
            break
        except urllib.error.HTTPError as e:
            msg = e.read().decode("utf-8", "replace")[:400]
            if e.code in (429, 500, 503) and attempt < retries:
                time.sleep(delay)
                delay *= 2
                continue
            raise SystemExit(f"ERROR: Gemini TTS failed ({e.code}): {msg}")
    try:
        inline = data["candidates"][0]["content"]["parts"][0]["inlineData"]
    except (KeyError, IndexError):
        raise SystemExit(f"ERROR: Gemini TTS returned no audio: {json.dumps(data)[:400]}")
    out.write_bytes(_to_wav(base64.b64decode(inline["data"]), inline.get("mimeType", "")))
    return out


def duration(path: Path) -> float:
    with wave.open(str(path), "rb") as w:
        return w.getnframes() / float(w.getframerate())
