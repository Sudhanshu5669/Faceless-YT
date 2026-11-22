"""Forced alignment: word times measured from the audio by an acoustic model.

Ported from Auto-Slop-Generator (backend/core/alignment). A wav2vec2 CTC model
(facebook/wav2vec2-base-960h, Apache-2.0, ONNX export) scores every 20 ms frame
of the narration against 32 tokens (A-Z, ', a word separator, blank). Viterbi
then finds the single most likely way the KNOWN script maps onto those frames.
Because the script is an input, words cannot be invented, dropped, reordered,
timed past the end of the file or collapsed onto one time; same audio in, same
times out, offline and free. (The old aligner asked Gemini for timestamps: it
wrote numbers that looked like timings and drifted by seconds.)

TownForge additions over the port:
  * numbers have several spoken forms ("2015" = "twenty fifteen" or "two thousand
    fifteen", "170" = "one hundred (and) seventy", "5.7" = "five point seven");
    each alternative is tried and the one the audio supports best is kept;
  * WAVs are read and resampled with numpy/scipy (no ffmpeg call).

Model files: models/alignment/ (git-ignored): wav2vec2-base-960h.onnx + vocab.json,
or "alignment_model" in config.local.json. Needs: numpy, scipy, onnxruntime.
"""
from __future__ import annotations

import itertools
import json
import re
import wave
from math import gcd
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent.parent
MODEL_DIR = ROOT / "models" / "alignment"
MODEL_FILE = "wav2vec2-base-960h.onnx"
MODEL_URL = "https://huggingface.co/onnx-community/wav2vec2-base-960h-ONNX/resolve/main/onnx/model.onnx"
SAMPLE_RATE = 16_000
SAMPLES_PER_FRAME = 320           # wav2vec2-base: conv strides multiply to 320 = 20 ms at 16 kHz
CHUNK = 20 * SAMPLE_RATE          # attention is quadratic: 20 s windows,
OVERLAP = 2 * SAMPLE_RATE         # 2 s overlap, half trimmed from each side of a seam
NEG_INF = -1e30


class AlignError(RuntimeError):
    pass


# --- model ---------------------------------------------------------------------------------

_session = None
_vocab: dict | None = None


def model_path() -> Path:
    cfg = ROOT / "config.local.json"
    if cfg.exists():
        p = json.loads(cfg.read_text(encoding="utf-8")).get("alignment_model")
        if p:
            return Path(p) if Path(p).is_absolute() else ROOT / p
    return MODEL_DIR / MODEL_FILE


def _load():
    global _session, _vocab
    if _session is None:
        path = model_path()
        if not path.exists():
            raise AlignError(f"ERROR: the alignment model is missing: {path}\n"
                             f"Download it (378 MB, Apache-2.0) from {MODEL_URL}\n"
                             f"and its vocab.json from the same repo into {path.parent}")
        try:
            import onnxruntime as ort
        except ImportError as e:
            raise AlignError("ERROR: forced alignment needs onnxruntime: pip install onnxruntime") from e
        opts = ort.SessionOptions()
        opts.log_severity_level = 3
        _session = ort.InferenceSession(str(path), opts, providers=["CPUExecutionProvider"])
        _vocab = json.loads((path.parent / "vocab.json").read_text(encoding="utf-8"))
    return _session, _vocab


# --- audio ---------------------------------------------------------------------------------

def _decode(wav_path: Path) -> np.ndarray:
    """Mono float32 at 16 kHz, zero mean and unit variance (the model expects do_normalize)."""
    from scipy.signal import resample_poly
    with wave.open(str(wav_path), "rb") as w:
        rate, ch, width = w.getframerate(), w.getnchannels(), w.getsampwidth()
        raw = w.readframes(w.getnframes())
    if width != 2:
        raise AlignError(f"ERROR: {wav_path}: only 16-bit WAV is supported")
    x = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
    if ch > 1:
        x = x.reshape(-1, ch).mean(axis=1)
    if rate != SAMPLE_RATE:
        g = gcd(rate, SAMPLE_RATE)
        x = resample_poly(x, SAMPLE_RATE // g, rate // g).astype(np.float32)
    x = x - x.mean()
    sd = float(x.std())
    return (x / sd if sd > 1e-7 else x).astype(np.float32)


def _logits(x: np.ndarray) -> np.ndarray:
    """Frame logits [T, 32], in overlapping 20 s windows stitched on one frame grid."""
    sess, _ = _load()
    iname, oname = sess.get_inputs()[0].name, sess.get_outputs()[0].name
    if x.size <= CHUNK:
        return np.asarray(sess.run([oname], {iname: x[None, :]})[0][0], dtype=np.float32)
    hop, trim = CHUNK - OVERLAP, (OVERLAP // SAMPLES_PER_FRAME) // 2
    parts, start = [], 0
    while True:
        end = min(x.size, start + CHUNK)
        seg = x[start:end]
        if seg.size < SAMPLES_PER_FRAME:
            break
        out = np.asarray(sess.run([oname], {iname: seg[None, :]})[0][0], dtype=np.float32)
        lo = 0 if start == 0 else trim
        hi = out.shape[0] if end >= x.size else max(lo, out.shape[0] - trim)
        if hi > lo:
            parts.append((start // SAMPLES_PER_FRAME + lo, out[lo:hi]))
        if end >= x.size:
            break
        start += hop
    total = max(o + b.shape[0] for o, b in parts)
    res = np.zeros((total, parts[0][1].shape[1]), dtype=np.float32)
    for o, b in parts:
        res[o:o + b.shape[0]] = b
    return res


def _log_softmax(z: np.ndarray) -> np.ndarray:
    z = z - z.max(axis=-1, keepdims=True)
    return z - np.log(np.exp(z).sum(axis=-1, keepdims=True))


# --- Viterbi over the CTC trellis ----------------------------------------------------------

def _viterbi(lp: np.ndarray, targets: np.ndarray, blank: int = 0):
    """Best path of `targets` (no blanks) through log-probs lp [T, V].
    Returns (total log-prob, [(first_frame, last_frame, score)] per target token)."""
    T, n = lp.shape[0], int(targets.size)
    need = n + int(np.sum(targets[1:] == targets[:-1]))
    if T < need:
        raise AlignError(f"ERROR: the audio is too short for the script ({T} frames for {need} tokens)")
    S = 2 * n + 1
    states = np.full(S, blank, dtype=np.int64)
    states[1::2] = targets
    can_skip = np.zeros(S, dtype=bool)
    can_skip[3::2] = targets[1:] != targets[:-1]
    em = lp[:, states]
    alpha = np.full(S, NEG_INF, dtype=np.float32)
    alpha[0], alpha[1] = em[0, 0], em[0, 1]
    back = np.zeros((T, S), dtype=np.uint8)
    cand = np.empty((3, S), dtype=np.float32)
    idx = np.arange(S)
    for t in range(1, T):
        cand[0] = alpha
        cand[1, 0] = NEG_INF
        cand[1, 1:] = alpha[:-1]
        cand[2] = NEG_INF
        cand[2, 2:] = np.where(can_skip[2:], alpha[:-2], NEG_INF)
        ch = np.argmax(cand, axis=0).astype(np.uint8)
        back[t] = ch
        alpha = cand[ch, idx] + em[t]
    s = S - 1 if alpha[-1] >= alpha[-2] else S - 2
    total = float(alpha[s])
    if total <= NEG_INF / 2:
        raise AlignError("ERROR: no alignment path: the audio and the script do not correspond")
    path = np.empty(T, dtype=np.int32)
    for t in range(T - 1, 0, -1):
        path[t] = s
        s -= int(back[t, s])
    path[0] = s
    fscore = np.exp(em[np.arange(T), path])
    spans = []
    for k in range(n):
        occ = np.flatnonzero(path == 2 * k + 1)
        a, b = int(occ[0]), int(occ[-1])
        spans.append((a, b, float(fscore[a:b + 1].mean())))
    return total, spans


# --- script -> spellings -------------------------------------------------------------------

ONES = ["ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN",
        "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTEEN", "NINETEEN"]
TENS = ["", "", "TWENTY", "THIRTY", "FORTY", "FIFTY", "SIXTY", "SEVENTY", "EIGHTY", "NINETY"]
ORD = {"ONE": "FIRST", "TWO": "SECOND", "THREE": "THIRD", "FIVE": "FIFTH", "EIGHT": "EIGHTH", "NINE": "NINTH",
       "TWELVE": "TWELFTH"}
SYMBOLS = {"&": "AND", "%": "PERCENT", "+": "PLUS", "=": "EQUALS", "@": "AT", "₹": "RUPEES", "$": "DOLLARS"}


def _under_1000(n: int, with_and: bool) -> list[str]:
    out = []
    if n >= 100:
        out += [ONES[n // 100], "HUNDRED"]
        n %= 100
        if n and with_and:
            out.append("AND")
    if n >= 20:
        out.append(TENS[n // 10])
        if n % 10:
            out.append(ONES[n % 10])
    elif n:
        out.append(ONES[n])
    return out


def _cardinal(n: int, with_and: bool) -> list[str]:
    if n == 0:
        return ["ZERO"]
    out = []
    for scale, name in ((10**9, "BILLION"), (10**6, "MILLION"), (1000, "THOUSAND")):
        if n >= scale:
            out += _under_1000(n // scale, with_and) + [name]
            n %= scale
    return out + _under_1000(n, with_and)


def _number_forms(digits: str) -> list[str]:
    """Every likely spoken form of a run of digits, most likely first."""
    n = int(digits)
    forms = [_cardinal(n, False), _cardinal(n, True)]
    if len(digits) == 4 and 1100 <= n <= 2099:         # a year
        hi, lo = divmod(n, 100)
        pair = _under_1000(hi, False) + (["HUNDRED"] if lo == 0 else (["OH", ONES[lo]] if lo < 10 else _under_1000(lo, False)))
        forms = [pair] + forms if not 2000 <= n <= 2009 else forms + [pair]
    if 100 <= n < 200:                                  # "a hundred and seventy"
        forms += [["A"] + f[1:] for f in forms if f[0] == "ONE"]
    out = []
    for f in forms:
        s = " ".join(f)
        if s not in out:
            out.append(s)
    return out


def _ordinal(words: str) -> str:
    w = words.split()
    last = w[-1]
    w[-1] = ORD.get(last, last[:-1] + "IETH" if last.endswith("Y") else last + "TH")
    return " ".join(w)


def spellings(word: str) -> list[str]:
    """The spoken forms of one script word (uppercase A-Z ' and spaces), most likely first.
    [""] means unspoken (an em dash, a stray quote, a [style tag])."""
    t = re.sub(r"\[[^\]\n]{1,48}\]", " ", word)
    t = t.replace("’", "'").replace("‘", "'")
    t = re.sub(r"[‐-―−]", " ", t)
    pieces: list[list[str]] = []
    # Split into digit runs (with decimals / ordinals) and the text between.
    for m in re.finditer(r"(\d[\d,]*)(?:\.(\d+))?(st|nd|rd|th)?|([^\d]+)", t, flags=re.IGNORECASE):
        if m.group(4) is not None:
            txt = m.group(4)
            for sym, spoken in SYMBOLS.items():
                txt = txt.replace(sym, f" {spoken} ")
            txt = re.sub(r"[^A-Z' ]+", " ", txt.upper())
            txt = " ".join(p.strip("'") for p in txt.split() if p.strip("'"))
            if txt:
                pieces.append([txt])
            continue
        whole = m.group(1).replace(",", "")
        forms = _number_forms(whole)
        if m.group(2):                                  # 5.7 -> FIVE POINT SEVEN
            frac = " ".join(ONES[int(d)] for d in m.group(2))
            forms = [f"{f} POINT {frac}" for f in forms[:2]]
        if m.group(3):
            forms = [_ordinal(forms[0])]
        pieces.append(forms)
    if not pieces:
        return [""]
    return [" ".join(c) for c in itertools.islice(itertools.product(*pieces), 8)]


# --- alignment -----------------------------------------------------------------------------

def align(wav_path: Path, words: list[str]) -> list[dict]:
    """Times for every script word: [{"w", "s", "e", "score"}] in order, seconds from the
    start of the WAV. Unspoken words get a zero-length time at the next spoken word."""
    _, vocab = _load()
    sep, unk, blank = vocab.get("|", 4), vocab.get("<unk>", 3), vocab.get("<pad>", 0)
    x = _decode(wav_path)
    lp = _log_softmax(_logits(x))
    spf = (x.size / SAMPLE_RATE) / lp.shape[0]
    alts = [spellings(w) for w in words]
    choice = [0] * len(words)

    def run(ch):
        targets, spans = [], []
        for k, (a, c) in enumerate(zip(alts, ch)):
            sp = a[c]
            if not sp:
                spans.append(None)
                continue
            if targets:
                targets.append(sep)
            b = len(targets)
            targets += [sep if ch_ == " " else vocab.get(ch_, unk) for ch_ in sp]
            spans.append((b, len(targets)))
        total, fs = _viterbi(lp, np.asarray(targets, dtype=np.int64), blank)
        return total, spans, fs

    best = run(choice)
    # Numbers with several spoken forms: keep the form the audio supports best.
    for k, a in enumerate(alts):
        for c in range(1, len(a)):
            trial = choice[:k] + [c] + choice[k + 1:]
            r = run(trial)
            if r[0] > best[0] + 1e-3:
                best, choice = r, trial
    _, spans, fs = best
    out = []
    for k, (w, sp) in enumerate(zip(words, spans)):
        if sp is None:
            out.append({"w": w, "s": None, "e": None, "score": 0.0})
            continue
        b, e = sp
        a0, a1 = fs[b][0], fs[e - 1][1]
        out.append({"w": w, "s": round(a0 * spf, 3), "e": round((a1 + 1) * spf, 3),
                    "score": round(float(np.mean([fs[i][2] for i in range(b, e)])), 3), "spoken": alts[k][choice[k]]})
    nxt = round(x.size / SAMPLE_RATE, 3)
    for r in reversed(out):
        if r["s"] is None:
            r["s"] = r["e"] = nxt
        nxt = r["s"]
    return out


def transcribe(wav_path: Path) -> str:
    """Greedy CTC transcript of a take (upper case, no punctuation): used to check that bracketed delivery tags
    were performed, not read aloud."""
    _, vocab = _load()
    inv = {v: k for k, v in vocab.items()}
    blank = vocab.get("<pad>", 0)
    ids = _logits(_decode(Path(wav_path))).argmax(-1)
    out, prev = [], -1
    for i in ids:
        if i != prev and i != blank:
            out.append(inv.get(int(i), ""))
        prev = i
    return "".join(out).replace("|", " ").strip()
