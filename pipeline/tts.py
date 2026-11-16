"""Cached narration via Gemini or local Qwen3-TTS (stdlib only in the main process).

Gemini reads GEMINI_API_KEY from the environment or .env at the repo root.
Takes are cached by (model, voice, style, text) under output/tts_cache/.
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
LOCAL_MODEL = "qwen3-tts-1.7b-customvoice"
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
    prefix = "qwen" if model == LOCAL_MODEL else voice
    return CACHE / f"{prefix}_{h}.wav"


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
    """Speak `text` with the selected model and return the cached WAV path."""
    out = _cache_path(text, voice, style, model)
    if out.exists():
        return out
    if model == LOCAL_MODEL:
        prepare_local([(text, voice, style)])
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


def prepare_local(takes: list[tuple[str, str, str]]) -> None:
    """Generate missing independent takes with one model load."""
    requests = {}
    for text, voice, style in takes:
        out = _cache_path(text, voice, style, LOCAL_MODEL)
        if not out.is_file():
            requests[out] = {"text": text, "voice": voice, "style": style, "out": str(out)}
    if requests:
        import qwen_tts_local

        CACHE.mkdir(parents=True, exist_ok=True)
        qwen_tts_local.generate(list(requests.values()))


def duration(path: Path) -> float:
    with wave.open(str(path), "rb") as w:
        return w.getnframes() / float(w.getframerate())
