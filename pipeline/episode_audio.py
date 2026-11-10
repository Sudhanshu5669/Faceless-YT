"""Voice-first episodes: narration, timing, captions and the sound mix.

resolve(episode.json) synthesizes every line (Gemini TTS, cached), times each
word, sizes "fit" shots to their narration, and turns time references into
numbers, producing the episode Godot renders. mix() builds the soundtrack
(voice, effects, ducked beds, -14 LUFS) and write_captions() the word-by-word
captions. See docs/AUDIO_SPEC.md.

Time references (anywhere an actor cue / route / event / sound needs a time):
    12.5                                     scene seconds
    {"shot": "reach", "at": 0.4}             0.4 s into a shot
    {"line": "n8"}                           when a line starts ("edge": "end" for its end)
    {"line": "n8", "word": "batteries"}      when that word starts (+ "edge", "offset")
"""
from __future__ import annotations

import copy
import json
import os
import re
import subprocess
import wave
from pathlib import Path

import align
import tts

NARRATION_KEYS = {"voice", "style", "model", "speed"}
LINE_KEYS = {"id", "text", "voice", "style", "fx", "shot", "at", "gain", "caption", "speed"}
SFX_KEYS = {"sound", "at", "gain", "repeat", "every", "salt"}
AMBIENCE_KEYS = {"sound", "gain", "curve", "duck"}
CAPTION_KEYS = {"enabled", "max_words", "position"}
FX = {"toy", "toy_chorus"}
FIT_KEYS = {"fit", "min", "tail"}
DEFAULT_TAIL = 0.25
BATCH_WORDS = 30  # long requests get cut off unpredictably
# Keys only the Python pipeline reads (stripped before Godot renders).
AUDIO_KEYS = ["narration", "lines", "sfx", "ambience", "captions", "music", "end_black", "review"]


class EpisodeError(SystemExit):
    pass


def _err(msgs: list[str]) -> None:
    if msgs:
        raise EpisodeError("ERROR: episode sound/timing:\n  - " + "\n  - ".join(msgs))


def _norm_word(w: str) -> str:
    return re.sub(r"[^a-z0-9']", "", w.lower().replace("’", "'"))


# --- resolve ----------------------------------------------------------------

def validate(ep: dict) -> list[str]:
    e = []
    for k in ep.get("narration", {}):
        if k not in NARRATION_KEYS:
            e.append(f"narration: unknown key '{k}' (known: {', '.join(sorted(NARRATION_KEYS))})")
    shot_names = {s.get("name") for s in ep.get("shots", [])}
    ids = set()
    for i, ln in enumerate(ep.get("lines", [])):
        w = f"lines[{i}] ({ln.get('id', '?')})"
        for k in ln:
            if k not in LINE_KEYS:
                e.append(f"{w}: unknown key '{k}' (known: {', '.join(sorted(LINE_KEYS))})")
        if not ln.get("id") or ln["id"] in ids:
            e.append(f"{w}: needs a unique 'id'")
        ids.add(ln.get("id"))
        if not str(ln.get("text", "")).strip():
            e.append(f"{w}: needs 'text'")
        if ln.get("shot") not in shot_names:
            e.append(f"{w}: 'shot' must name a shot (got {ln.get('shot')!r})")
        if ln.get("fx") is not None and ln["fx"] not in FX:
            e.append(f"{w}: fx must be one of {sorted(FX)}")
    for i, s in enumerate(ep.get("sfx", [])):
        for k in s:
            if k not in SFX_KEYS:
                e.append(f"sfx[{i}]: unknown key '{k}' (known: {', '.join(sorted(SFX_KEYS))})")
        if "sound" not in s or "at" not in s:
            e.append(f"sfx[{i}]: needs 'sound' and 'at'")
    for i, a in enumerate(ep.get("ambience", [])):
        for k in a:
            if k not in AMBIENCE_KEYS:
                e.append(f"ambience[{i}]: unknown key '{k}' (known: {', '.join(sorted(AMBIENCE_KEYS))})")
    for k in ep.get("captions", {}):
        if k not in CAPTION_KEYS:
            e.append(f"captions: unknown key '{k}' (known: {', '.join(sorted(CAPTION_KEYS))})")
    for i, s in enumerate(ep.get("shots", [])):
        d = s.get("duration")
        if isinstance(d, str) and d != "fit":
            e.append(f"shots[{i}] ({s.get('name')}): duration must be seconds, \"fit\" or {{\"fit\": true, \"min\", \"tail\"}}")
        if "skip" in s and (not isinstance(s["skip"], (int, float)) or s["skip"] < 0):
            e.append(f"shots[{i}] ({s.get('name')}): skip must be seconds >= 0 (story time jumped at this cut)")
        if isinstance(d, dict):
            for k in d:
                if k not in FIT_KEYS:
                    e.append(f"shots[{i}] ({s.get('name')}): duration has unknown key '{k}' (known: fit, min, tail)")
    return e


def resolve(path: Path, verbose: bool = True) -> dict:
    ep = json.loads(path.read_text(encoding="utf-8"))
    _err(validate(ep))
    narr = ep.get("narration", {})
    # 1. Voice first: speak and time every line. Lines sharing a voice + style
    # are spoken in ONE request (consistent delivery, and the free tier allows
    # only ~10 TTS requests per model per day), then cut apart at the pauses.
    # TOWNFORGE_TTS_MODEL overrides for drafting (e.g. a lighter model with spare quota).
    model = os.environ.get("TOWNFORGE_TTS_MODEL") or narr.get("model", tts.DEFAULT_MODEL)
    groups: dict[tuple, list[str]] = {}
    for ln in ep.get("lines", []):
        key = (ln.get("voice", narr.get("voice", "Charon")), ln.get("style", narr.get("style", "")))
        if ln["text"] not in groups.setdefault(key, []):
            groups[key].append(ln["text"])
    takes: dict[tuple, dict] = {}
    for (voice, style), texts in groups.items():
        # Long TTS requests get cut off: batches of at most BATCH_WORDS words.
        chunks, cur, n_words = [], [], 0
        for t in texts:
            w = len(align.script_words(t))
            if cur and n_words + w > BATCH_WORDS:
                chunks.append(cur)
                cur, n_words = [], 0
            cur.append(t)
            n_words += w
        if cur:
            chunks.append(cur)
        for chunk in chunks:
            for text, take in zip(chunk, speak_batch(chunk, voice, style, model)):
                takes[(voice, style, text)] = take
    lines = []
    for ln in ep.get("lines", []):
        key = (ln.get("voice", narr.get("voice", "Charon")), ln.get("style", narr.get("style", "")), ln["text"])
        take = takes[key]
        speed = float(ln.get("speed", narr.get("speed", 1.0)))
        if abs(speed - 1.0) > 0.001:
            take = _tempo(take, speed)
        lines.append({**ln, "wav": take["wav"], "dur": take["dur"], "words": take["words"],
                      "at": float(ln.get("at", 0.15))})
    by_shot: dict[str, list] = {}
    for ln in lines:
        by_shot.setdefault(ln["shot"], []).append(ln)
    # 2. Shot durations ("fit" = as long as its lines) and the edit / scene timeline.
    shots, edit, scene, errors = [], 0.0, 0.0, []
    for s in ep["shots"]:
        d = s["duration"]
        if d == "fit" or isinstance(d, dict):
            opts = d if isinstance(d, dict) else {}
            mine = by_shot.get(s["name"], [])
            if not mine:
                errors.append(f"shot {s['name']}: duration \"fit\" but no line is placed in it")
                continue
            d = max(ln["at"] + ln["dur"] for ln in mine) + float(opts.get("tail", DEFAULT_TAIL))
            d = max(d, float(opts.get("min", 0.0)))
        if "scene_t" in s:
            scene = float(s["scene_t"])
        # "skip": story time jumps forward at this cut (elliptical editing).
        scene += float(s.get("skip", 0.0))
        shots.append({"name": s["name"], "duration": round(float(d), 3), "edit": edit, "scene_t": scene})
        edit += float(d)
        scene += float(d)
    _err(errors)
    shot_by = {s["name"]: s for s in shots}
    for ln in lines:
        sh = shot_by[ln["shot"]]
        ln["edit"] = sh["edit"] + ln["at"]
        ln["scene"] = sh["scene_t"] + ln["at"]
    line_by = {ln["id"]: ln for ln in lines}

    def ref(r, domain: str, where: str):
        if isinstance(r, (int, float)):
            return float(r)
        if not isinstance(r, dict):
            raise EpisodeError(f"ERROR: {where}: a time must be seconds or a reference (shot/line), got {r!r}")
        if "shot" in r:
            if r["shot"] not in shot_by:
                raise EpisodeError(f"ERROR: {where}: no shot '{r['shot']}'")
            sh = shot_by[r["shot"]]
            base = sh["edit"] if domain == "edit" else sh["scene_t"]
            return base + float(r.get("at", 0.0))
        if "line" in r:
            ln = line_by.get(r["line"])
            if ln is None:
                raise EpisodeError(f"ERROR: {where}: no line '{r['line']}'")
            base = ln["edit"] if domain == "edit" else ln["scene"]
            edge = r.get("edge", "start")
            if "word" in r:
                ws = ln["words"]
                if isinstance(r["word"], int):
                    if not 0 <= r["word"] < len(ws):
                        raise EpisodeError(f"ERROR: {where}: line {ln['id']} has {len(ws)} words")
                    w = ws[r["word"]]
                else:
                    want = _norm_word(str(r["word"]))
                    hits = [w for w in ws if _norm_word(w["w"]) == want]
                    if not hits:
                        raise EpisodeError(f"ERROR: {where}: word '{r['word']}' not in line {ln['id']} "
                                           f"({' '.join(w['w'] for w in ws)})")
                    w = hits[int(r.get("occurrence", 1)) - 1]
                t = w["e"] if edge == "end" else w["s"]
            else:
                t = ln["dur"] if edge == "end" else 0.0
            return round(base + t + float(r.get("offset", 0.0)), 3)
        raise EpisodeError(f"ERROR: {where}: a time reference needs 'shot' or 'line', got {r!r}")

    # 3. The episode Godot renders: numbers only, no sound keys.
    out = copy.deepcopy({k: v for k, v in ep.items() if k not in AUDIO_KEYS})
    for s, rs in zip(out["shots"], shots):
        s["duration"] = rs["duration"]
        s["scene_t"] = round(rs["scene_t"], 3)
        s.pop("skip", None)
    for a in out.get("actors", []):
        aid = a.get("id", "?")
        for c in a.get("cues", []):
            c["t"] = round(ref(c["t"], "scene", f"actor {aid} cue"), 3)
        r = a.get("route")
        if r:
            for k in ("start", "arrive"):
                if k in r:
                    r[k] = round(ref(r[k], "scene", f"actor {aid} route.{k}"), 3)
    for i, ev in enumerate(out.get("events", [])):
        ev["t"] = round(ref(ev["t"], "scene", f"events[{i}]"), 3)
    # 4. Sound placements on the edit timeline.
    sfx = []
    for i, s in enumerate(ep.get("sfx", [])):
        t0 = ref(s["at"], "edit", f"sfx[{i}]")
        for n in range(int(s.get("repeat", 1))):
            sfx.append({"sound": s["sound"], "t": t0 + n * float(s.get("every", 0.5)),
                        "gain": float(s.get("gain", 0.0)), "salt": int(s.get("salt", 0)) + n})
    total = sum(s["duration"] for s in shots)
    end_black = float(ep.get("end_black", 0.0))
    amb = []
    for i, a in enumerate(ep.get("ambience", [])):
        pts = [[ref(p[0], "edit", f"ambience[{i}].curve"), float(p[1])] for p in a.get("curve", [])]
        amb.append({"sound": a["sound"], "gain": float(a.get("gain", -20.0)), "curve": pts,
                    "duck": float(a.get("duck", 0.4))})
    res = {"episode": out, "shots": shots, "lines": lines, "sfx": sfx, "ambience": amb,
           "duration": total, "end_black": end_black, "captions": ep.get("captions", {}),
           "resolution": ep.get("format", {}).get("resolution", [1080, 1920])}
    if verbose:
        print_timing(res)
    return res


def _tempo(take: dict, speed: float) -> dict:
    """Time-stretch a take (pitch kept, ffmpeg atempo) and rescale its word times."""
    src = Path(take["wav"])
    dst = src.with_name(f"{src.stem}_x{speed:.3f}.wav")
    if not dst.exists():
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(src), "-af", f"atempo={speed:.4f}",
                        str(dst)], check=True)
    ws = [{"w": w["w"], "s": round(w["s"] / speed, 3), "e": round(w["e"] / speed, 3)} for w in take["words"]]
    return {"wav": str(dst), "dur": tts.duration(dst), "words": ws}


TAIL_PAD = "End."


def speak_batch(texts: list[str], voice: str, style: str, model: str, pad: bool = False) -> list[dict]:
    """Speak one or more lines in one TTS request and split the take per line.
    Returns [{"wav", "dur", "words"}] in order; the cut files are cached.
    TTS sometimes stops before the last word: then the take is redone once with
    a throwaway word after the last line (pad), which is cut off."""
    import numpy as np
    joined = "\n\n".join(texts + ([TAIL_PAD] if pad else []))
    wav = tts.synthesize(joined, voice, style, model)
    words = [w for w in align.words(wav, joined) if not w.get("extra")]
    counts = [len(align.script_words(t)) for t in texts]
    dur = tts.duration(wav)
    late = [w["w"] for w in words[:sum(counts)] if w["s"] >= dur - 0.05]
    if late:
        if not pad:
            print(f"[TownForge] {voice} take stops early (unspoken: {' '.join(late)}); retaking with a tail pad")
            return speak_batch(texts, voice, style, model, pad=True)
        raise EpisodeError(f"ERROR: the {voice} take stops early ({dur:.1f} s) even with a tail pad; unspoken: "
                           f"{' '.join(late)}. Delete {wav} (and its .words.json) to retake")
    if pad:
        words = words[:sum(counts)]
    if len(words) != sum(counts):
        raise EpisodeError(f"ERROR: alignment of the {voice} batch found {len(words)} words, script has {sum(counts)}; "
                           f"delete {wav.with_suffix('.words.json')} to re-align")
    with wave.open(str(wav), "rb") as w:
        rate = w.getframerate()
        pcm = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16)
    # Cut points: the quietest 30 ms inside each gap between lines.
    bounds, i = [], 0
    for c in counts:
        bounds.append((i, i + c - 1))
        i += c
    cuts = [0]
    win = int(0.03 * rate)
    for (a0, a1), (b0, _) in zip(bounds, bounds[1:]):
        g0, g1 = int(words[a1]["e"] * rate), int(words[b0]["s"] * rate)
        if g1 - g0 <= win:
            cuts.append((g0 + g1) // 2)
            continue
        seg = pcm[g0:g1].astype(np.float64) ** 2
        energy = np.convolve(seg, np.ones(win), "valid")
        cuts.append(g0 + int(np.argmin(energy)) + win // 2)
    # The end: after the last word (and before the pad word, if any).
    cuts.append(min(pcm.size, int((words[-1]["e"] + 0.35) * rate)) if pad else pcm.size)
    out = []
    for k, ((a0, a1), text) in enumerate(zip(bounds, texts)):
        # Trim leading/trailing pause to ~0.08 s around the words.
        s0 = max(cuts[k], int((words[a0]["s"] - 0.08) * rate))
        s1 = min(cuts[k + 1], int((words[a1]["e"] + 0.25) * rate))
        part = wav.with_name(f"{wav.stem}_part{k}.wav")
        if not part.exists():
            with wave.open(str(part), "wb") as w:
                w.setnchannels(1)
                w.setsampwidth(2)
                w.setframerate(rate)
                w.writeframes(pcm[s0:s1].tobytes())
        off = s0 / rate
        ws = [{"w": w["w"], "s": round(w["s"] - off, 3), "e": round(w["e"] - off, 3)} for w in words[a0:a1 + 1]]
        out.append({"wav": str(part), "dur": (s1 - s0) / rate, "words": ws})
    return out


def print_timing(res: dict) -> None:
    print(f"[TownForge] timing: {len(res['shots'])} shots, {res['duration']:.1f} s"
          + (f" + {res['end_black']:.1f} s black" if res["end_black"] else ""))
    for s in res["shots"]:
        print(f"  {s['edit']:6.2f}  {s['name']:<16} {s['duration']:5.2f} s")
        for ln in res["lines"]:
            if ln["shot"] == s["name"]:
                print(f"           {ln['edit']:6.2f}  {ln['id']:<6} {ln['dur']:4.1f} s  {ln['text'][:60]}")


# --- sound ------------------------------------------------------------------

def _load_wav(path: str):
    import numpy as np
    from scipy import signal
    import sfx
    with wave.open(path, "rb") as w:
        rate = w.getframerate()
        x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64) / 32768.0
        if w.getnchannels() > 1:
            x = x.reshape(-1, w.getnchannels()).mean(axis=1)
    if rate != sfx.SR:
        from math import gcd
        g = gcd(rate, sfx.SR)
        x = signal.resample_poly(x, sfx.SR // g, rate // g)
    return x


def _db(g: float) -> float:
    return 10 ** (g / 20.0)


def mix(res: dict, out_wav: Path, ffmpeg: str = "ffmpeg") -> Path:
    """Voice + effects + ducked beds -> 48 kHz stereo WAV at -14 LUFS."""
    import numpy as np
    from scipy import signal
    import sfx
    sr = sfx.SR
    total = res["duration"] + res["end_black"]
    n = int(total * sr) + sr
    voice = np.zeros(n)
    fx = np.zeros(n)

    def place(bus, x, t):
        i0 = int(t * sr)
        if i0 >= n:
            return
        i1 = min(i0 + x.size, n)
        bus[i0:i1] += x[: i1 - i0]

    for ln in res["lines"]:
        x = _load_wav(ln["wav"])
        if ln.get("fx") == "toy":
            x = sfx.toy_voice(x)
        elif ln.get("fx") == "toy_chorus":
            x = sfx.toy_chorus(x)
        place(voice, x * _db(float(ln.get("gain", 0.0))), ln["edit"])
    for s in res["sfx"]:
        place(fx, sfx.make(s["sound"], salt=s["salt"]) * _db(s["gain"]), s["t"])
    # Ducking: beds dip under the narration (envelope follower on the voice bus).
    env = np.abs(voice)
    att, rel = np.exp(-1.0 / (0.01 * sr)), np.exp(-1.0 / (0.35 * sr))
    env = signal.lfilter([1 - rel], [1, -rel], env)  # smooth (release-dominated)
    env = np.clip(env / 0.04, 0.0, 1.0)
    beds = np.zeros(n)
    for a in res["ambience"]:
        x = sfx.make(a["sound"], dur=n / sr)[:n]
        g = sfx.curve(a["curve"], n / sr)[:n] if a["curve"] else np.ones(n)
        beds += x * g * _db(a["gain"]) * (1.0 - a["duck"] * env)
    master = voice + fx + beds
    master[int(res["duration"] * sr + 2.5 * sr):] *= 0.0  # silence after the black tail
    master = np.tanh(master * 1.1) / 1.1                    # gentle safety clip
    raw = out_wav.with_name(out_wav.stem + "_raw.wav")
    _write_wav(raw, master, sr)
    _loudnorm(ffmpeg, raw, out_wav, total)
    raw.unlink()
    return out_wav


def _write_wav(path: Path, x, sr: int) -> None:
    import numpy as np
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    stereo = np.repeat(pcm[:, None], 2, axis=1)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(stereo.tobytes())


def _measure(ffmpeg: str, src: Path) -> dict:
    p = subprocess.run([ffmpeg, "-hide_banner", "-i", str(src), "-af", "loudnorm=I=-14:TP=-1.5:LRA=11:print_format=json",
                        "-f", "null", "-"], capture_output=True, text=True, encoding="utf-8", errors="replace")
    m = re.search(r"\{[^{}]*\"input_i\"[^{}]*\}", p.stderr, re.S)
    if not m:
        raise EpisodeError("ERROR: loudness measurement failed:\n" + p.stderr[-800:])
    return json.loads(m.group(0))


def _loudnorm(ffmpeg: str, src: Path, dst: Path, total: float) -> None:
    """EBU R128 to -14 LUFS integrated, -1.5 dBTP (YouTube). Short peaks (glass
    bangs, the sting) would stop a linear gain from reaching the target, so the
    mix is first raised to the target and its peaks limited, then normalised
    linearly (two passes)."""
    target = "I=-14:TP=-1.5:LRA=11"
    st = _measure(ffmpeg, src)
    gain = -14.0 - float(st["input_i"])
    limited = dst.with_name(dst.stem + "_lim.wav")
    subprocess.run([ffmpeg, "-y", "-loglevel", "error", "-i", str(src), "-af",
                    f"volume={gain:.2f}dB,alimiter=limit=0.80:attack=4:release=60:level=disabled",
                    "-ar", "48000", str(limited)], check=True)
    st = _measure(ffmpeg, limited)
    af = (f"loudnorm={target}:measured_I={st['input_i']}:measured_TP={st['input_tp']}:measured_LRA={st['input_lra']}"
          f":measured_thresh={st['input_thresh']}:offset={st['target_offset']}:linear=true,aresample=48000")
    subprocess.run([ffmpeg, "-y", "-loglevel", "error", "-i", str(limited), "-af", af, "-t", f"{total:.3f}",
                    "-ar", "48000", str(dst)], check=True)
    limited.unlink()


def measure_lufs(ffmpeg: str, path: Path) -> float:
    p = subprocess.run([ffmpeg, "-hide_banner", "-i", str(path), "-af", "loudnorm=print_format=json", "-f", "null", "-"],
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    m = re.search(r"\{[^{}]*\"input_i\"[^{}]*\}", p.stderr, re.S)
    return float(json.loads(m.group(0))["input_i"]) if m else float("nan")


# --- captions ---------------------------------------------------------------

def _ass_time(t: float) -> str:
    t = max(0.0, t)
    h = int(t // 3600)
    m = int(t % 3600 // 60)
    s = t % 60
    return f"{h}:{m:02d}:{s:05.2f}"


def write_captions(res: dict, path: Path) -> Path:
    """Word-by-word captions (ASS): short chunks, the spoken word highlighted."""
    opts = res.get("captions", {})
    w, h = res["resolution"]
    max_words = int(opts.get("max_words", 3))
    pos = float(opts.get("position", 0.64))  # fraction of the height (Shorts UI covers the bottom)
    margin_v = int(h * (1 - pos))
    fs = int(h * 0.055)  # big, Shorts-style
    header = f"""[Script Info]
ScriptType: v4.00+
PlayResX: {w}
PlayResY: {h}
WrapStyle: 2
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Narr,Arial Black,{fs},&H00FFFFFF,&H00FFFFFF,&H00000000,&H64000000,0,0,0,0,100,100,0,0,1,{max(3, fs // 11)},2,2,60,60,{margin_v},1
Style: Toy,Arial Black,{int(fs * 1.15)},&H00FFE853,&H00FFE853,&H00301000,&H64000000,0,1,0,0,100,100,2,0,1,{max(3, fs // 10)},0,2,60,60,{margin_v + int(fs * 1.4)},1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
    events = []
    hi = r"{\c&H00D7FF&\fscx108\fscy108}"   # BGR: warm yellow
    for ln in res["lines"]:
        if ln.get("caption", True) is False or not ln["words"]:
            continue
        toy = ln.get("fx") in FX
        style = "Toy" if toy else "Narr"
        ws = ln["words"]
        chunks, cur = [], []
        for wd in ws:
            cur.append(wd)
            if len(cur) >= max_words or re.search(r"[.,!?;:…]$", wd["w"]):
                chunks.append(cur)
                cur = []
        if cur:
            chunks.append(cur)
        for ci, ch in enumerate(chunks):
            c_end = ch[-1]["e"] + 0.2
            if ci + 1 < len(chunks):
                c_end = min(c_end, chunks[ci + 1][0]["s"])
            for wi, wd in enumerate(ch):
                s = wd["s"]
                e = ch[wi + 1]["s"] if wi + 1 < len(ch) else c_end
                if toy:
                    text = " ".join(x["w"] for x in ch).upper()
                else:
                    text = " ".join((hi + x["w"] + r"{\r}") if j == wi else x["w"] for j, x in enumerate(ch))
                events.append(f"Dialogue: 0,{_ass_time(ln['edit'] + s)},{_ass_time(ln['edit'] + e)},{style},,0,0,0,,{text}")
    path.write_text(header + "\n".join(events) + "\n", encoding="utf-8")
    return path


def finish(cfg_ffmpeg: str, picture: Path, audio: Path, captions: Path | None, out: Path,
           end_black: float, fps: int) -> None:
    """Burn captions, add the black tail, mux the soundtrack."""
    vf = []
    if captions is not None:
        vf.append(f"ass={captions.name}")
    if end_black > 0:
        vf.append(f"tpad=stop_mode=add:stop_duration={end_black}:color=black")
    cmd = [cfg_ffmpeg, "-y", "-loglevel", "error", "-i", str(picture.resolve()), "-i", str(audio.resolve())]
    if vf:
        cmd += ["-vf", ",".join(vf)]
    cmd += ["-map", "0:v:0", "-map", "1:a:0", "-c:v", "libx264", "-preset", "medium", "-crf", "18",
            "-pix_fmt", "yuv420p", "-r", str(fps), "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart",
            "-shortest", str(out.resolve())]
    # Run next to the .ass file: Windows drive letters break the filter's path syntax.
    subprocess.run(cmd, check=True, cwd=str((captions or out).parent))
