"""Approval board: every episode passes four gates before its final render.

    Environment -> Characters -> Script & voice -> Shots

`prepare` renders what each gate needs into episodes/<id>/review/ and writes
board.json (items with media, details and automatic suggestions). Claude adds
its own critique to review/suggestions.json. `serve` runs a local page where
the user approves an item or requests changes (with a note, and ticks on the
suggestions to apply); decisions go to review/decisions.json. `notes` prints
what the user asked for. A decision remembers the fingerprint of what was
reviewed, so anything changed afterwards needs a fresh look.
See docs/REVIEW.md.
"""
from __future__ import annotations

import copy
import hashlib
import json
import os
import shutil
import subprocess
import sys
import threading
import time
import webbrowser
from argparse import Namespace
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
UI = Path(__file__).resolve().parent / "review_ui" / "index.html"
GATES = [
    ("env", "Environment", "The set and its look, from the key angles. No people yet."),
    ("cast", "Characters", "Every character in the episode: turnaround, and each action they perform."),
    ("voice", "Script & voice", "The script, then every narration and character line as it will be heard."),
    ("shots", "Shots", "Every shot: storyboard frames and a draft clip with sound."),
]
STATUSES = ("pending", "approved", "changes")
STAGES = {"supermarket": "aisle_4.front", "town": "town_center"}  # open space on every side


# --- files ------------------------------------------------------------------

def review_dir(ep_path: Path) -> Path:
    return ep_path.parent / "review"


def _write_json(path: Path, data) -> None:
    """Atomic + fsync'd: decisions must survive a power cut mid-write."""
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)


def _read_json(path: Path, default):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError):
        return default


def _fingerprint(rd: Path, item: dict) -> str:
    h = hashlib.sha1()
    for m in item.get("media", []):
        if m.get("src"):
            p = rd / m["src"]
            h.update(p.read_bytes() if p.exists() else b"missing")
        if m.get("text"):
            h.update(m["text"].encode("utf-8"))
    h.update(json.dumps(item.get("details", {}), sort_keys=True).encode("utf-8"))
    return h.hexdigest()[:16]


def _luma(path: Path) -> float:
    """Mean brightness 0..255 of an image (tiny grayscale decode via ffmpeg)."""
    p = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(path), "-vf", "scale=48:-1,format=gray",
                        "-f", "rawvideo", "-"], capture_output=True)
    data = p.stdout
    return sum(data) / max(len(data), 1)


def _dark_suggestion(path: Path, what: str) -> list[dict]:
    y = _luma(path)
    if y < 28:
        return [{"id": "auto:dark", "source": "auto",
                 "text": f"{what} is very dark (average brightness {y:.0f}/255): on a phone it may read as black. "
                         "Raise exposure or add a practical light near the subject."}]
    return []


# --- prepare ----------------------------------------------------------------

def _stills(cfg: dict, spec: dict, out: Path, work: Path, name: str) -> list[Path]:
    import tf
    out.mkdir(parents=True, exist_ok=True)
    for f in out.glob("*.png"):
        f.unlink()
    spec_path = work / f"{name}.json"
    spec_path.parent.mkdir(parents=True, exist_ok=True)
    spec_path.write_text(json.dumps(spec, indent=1), encoding="utf-8")
    views = spec["preview"]["views"]
    code = tf.run_godot(cfg, ["--spec", str(spec_path), "--stills", str(out)],
                        pre_args=["--quit-after", str(600 + 60 * len(views))])
    stills = sorted(out.glob("[0-9]*_*.png"))
    if code != 0 or len(stills) != len(views):
        raise SystemExit(f"ERROR: review stills for {name} failed ({len(stills)}/{len(views)} rendered)")
    return stills


def _episode_spec(ep_path: Path, ep: dict) -> dict:
    spec = _read_json(ROOT / ep["set"], None)
    if spec is None:
        raise SystemExit(f"ERROR: episode set {ep['set']} not found")
    spec = copy.deepcopy(spec)
    if "look" in ep:
        spec["look"] = ep["look"]
    return spec


def _gate_env(cfg, ep_path, ep, rd) -> list[dict]:
    spec = _episode_spec(ep_path, ep)
    actor_ids = {a["id"] for a in spec.get("actors", [])}
    views = [v for v in spec.get("preview", {}).get("views", [])
             if not any(f'"{aid}' in json.dumps(v) for aid in actor_ids)]
    if not views:
        raise SystemExit("ERROR: the set spec has no preview views without actors to review the environment with")
    spec["actors"] = []
    spec["preview"] = {"resolution": [540, 960], "views": views}
    stills = _stills(cfg, spec, rd / "env", rd / "work", "env")
    look = spec["look"]
    items = []
    for v, still in zip(views, stills):
        name = v.get("name", still.stem[3:]) if isinstance(v, dict) else str(v)
        items.append({
            "id": f"env:{name}", "title": name.replace("_", " ").capitalize(),
            "media": [{"type": "image", "src": f"env/{still.name}"}],
            "details": {"set": f"{spec['set']['generator']} (seed {spec['set']['seed']})",
                        "params": spec["set"].get("params", {}), "look": look},
            "suggestions": _dark_suggestion(still, "This angle"),
        })
    return items


def _characters(ep: dict) -> dict[str, set]:
    """character id -> actions it performs in the episode."""
    import episode_audio  # noqa: F401  (keeps the import graph obvious)
    chars: dict[str, set] = {}
    for a in ep.get("actors", []):
        ids = a.get("crowd", {}).get("characters") or [a.get("character")]
        acts = set()
        if a.get("action"):
            acts.add(a["action"])
        r = a.get("route", {})
        for k in ("gait", "then"):
            if r.get(k):
                acts.add(r[k])
        for c in a.get("cues", []):
            if c.get("action"):
                acts.add(c["action"])
        for cid in ids:
            chars.setdefault(cid, set()).update(acts)
    return chars


def _freeze_for(action: str) -> float | str:
    acts = _read_json(ROOT / "library" / "actions.json", {}).get("actions", {})
    a = acts.get(action, {})
    marks = a.get("marks", {})
    if marks:
        return sorted(marks, key=lambda m: marks[m])[len(marks) // 2]
    return 0.25 if a.get("gait") else 0.5


def _gate_cast(cfg, ep_path, ep, rd) -> list[dict]:
    base = _episode_spec(ep_path, ep)
    review_cfg = ep.get("review", {})
    gen = base["set"]["generator"]
    stage = review_cfg.get("stage", STAGES.get(gen, "town_center"))
    # The stage may be an anchor name or {"anchor", "offset"}; actions line up behind it.
    st_anchor = stage if isinstance(stage, str) else stage["anchor"]
    st_off = [0, 0, 0] if isinstance(stage, str) else list(stage.get("offset", [0, 0, 0]))
    base["set"].setdefault("params", {}).update(review_cfg.get("cast_params", {}))
    items = []
    for cid, actions in sorted(_characters(ep).items()):
        info = _read_json(ROOT / "library" / "characters" / f"{cid}.json", {})
        actors = [{"id": "c", "character": cid, "at": stage}]
        views = [{"name": f"turn_{ang}", "t": 1, "at": {"anchor": "c", "orbit": {"distance": 3.0, "angle": ang, "height": 1.35}},
                  "look_at": "c.chest", "lens_mm": 40} for ang in (0, 45, 90, 180)]
        for k, act in enumerate(sorted(actions)):
            aid = f"a{k}"
            actors.append({"id": aid, "character": cid, "at": {"anchor": st_anchor, "offset": [st_off[0], 0, st_off[2] + 3.5 * (k + 1)]},
                           "action": act, "freeze": _freeze_for(act), "facing": "back"})
            views.append({"name": f"act_{act}", "t": 1, "at": {"anchor": aid, "offset": [0.5, 1.3, 2.6]},
                          "look_at": f"{aid}.chest", "lens_mm": 35, "dof": {"strength": 0.6}})
        spec = copy.deepcopy(base)
        spec["actors"] = actors
        spec["preview"] = {"resolution": [540, 960], "views": views}
        stills = _stills(cfg, spec, rd / "cast" / cid, rd / "work", f"cast_{cid}")
        media = [{"type": "image", "src": f"cast/{cid}/{s.name}",
                  "caption": s.stem[3:].replace("turn_", "turnaround ").replace("act_", "action: ")} for s in stills]
        sugg = []
        if not info.get("description"):
            sugg.append({"id": "auto:nodesc", "source": "auto", "text": "This character has no description in its library file."})
        items.append({
            "id": f"cast:{cid}", "title": cid.replace("_", " ").capitalize(), "media": media,
            "details": {"description": info.get("description", ""), "body": info.get("body"), "height": info.get("height"),
                        "colors": info.get("colors", {}), "actions in this episode": sorted(actions),
                        "props": [p.get("model") for p in info.get("props", [])]},
            "suggestions": sugg,
        })
    return items


def _gate_voice(cfg, ep_path, ep, rd, res) -> list[dict]:
    import episode_audio
    import numpy as np
    import sfx
    items = []
    script = ep_path.parent / "script.md"
    if script.exists():
        items.append({"id": "voice:script", "title": "Script", "media": [{"type": "text", "text": script.read_text(encoding="utf-8")}],
                      "details": {"file": str(script.relative_to(ROOT))}, "suggestions": []})
    out = rd / "voice"
    out.mkdir(parents=True, exist_ok=True)
    narr = ep.get("narration", {})
    for ln in res["lines"]:
        x = episode_audio._load_wav(ln["wav"])
        if ln.get("fx") == "toy":
            x = sfx.toy_voice(x)
        elif ln.get("fx") == "toy_chorus":
            x = sfx.toy_chorus(x)
        x = x / max(float(np.max(np.abs(x))), 1e-6) * 0.8
        dst = out / f"{ln['id']}.wav"
        episode_audio._write_wav(dst, x, sfx.SR)
        n_words = len(ln["words"])
        pace = n_words / max(ln["dur"], 0.1)
        sugg = []
        if not ln.get("fx") and n_words >= 4 and pace < 1.7:
            sugg.append({"id": "auto:slow", "source": "auto", "text": f"Slow delivery ({pace:.1f} words/s). Shorts hold better around 2.2–2.8: raise speed or ask for a tighter read."})
        if not ln.get("fx") and pace > 3.3:
            sugg.append({"id": "auto:fast", "source": "auto", "text": f"Fast delivery ({pace:.1f} words/s): it may feel rushed; lower the speed."})
        items.append({
            "id": f"voice:{ln['id']}", "title": f"{ln['id']}: {ln['text'][:48]}" + ("…" if len(ln["text"]) > 48 else ""),
            "media": [{"type": "audio", "src": f"voice/{ln['id']}.wav"}, {"type": "text", "text": ln["text"]}],
            "details": {"voice": ln.get("voice", narr.get("voice")), "style": ln.get("style", narr.get("style", "")),
                        "speed": ln.get("speed", narr.get("speed", 1.0)), "fx": ln.get("fx"), "shot": ln["shot"],
                        "duration": f"{ln['dur']:.2f} s", "pace": f"{pace:.1f} words/s"},
            "suggestions": sugg,
        })
    return items


def _gate_shots(cfg, ep_path, ep, rd, res) -> list[dict]:
    import tf
    code = tf.cmd_storyboard(cfg, Namespace(episode=str(ep_path)))
    if code != 0:
        raise SystemExit("ERROR: storyboard failed")
    code = tf.cmd_render(cfg, Namespace(episode=str(ep_path), draft=True, shots=None, remix=False, force=True))
    if code != 0:
        raise SystemExit("ERROR: draft animatic failed")
    sb = ep_path.parent / "preview" / "storyboard"
    animatic = ep_path.parent / "preview" / "animatic" / f"{ep['id']}_animatic.mp4"
    out = rd / "shots"
    out.mkdir(parents=True, exist_ok=True)
    items = []
    for i, s in enumerate(res["shots"]):
        key = f"{i:02d}_{s['name']}"
        media = []
        for j, label in zip("abc", ("start", "middle", "end")):
            src = sb / f"{key}_{j}.png"
            dst = out / f"{key}_{j}.png"
            shutil.copyfile(src, dst)
            media.append({"type": "image", "src": f"shots/{dst.name}", "caption": label})
        clip = out / f"{key}.mp4"
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-ss", f"{s['edit']:.3f}", "-i", str(animatic),
                        "-t", f"{s['duration']:.3f}", "-c:v", "libx264", "-preset", "veryfast", "-crf", "23",
                        "-c:a", "aac", "-b:a", "128k", "-movflags", "+faststart", str(clip)], check=True)
        media.insert(0, {"type": "video", "src": f"shots/{clip.name}", "caption": "draft (half size, 15 fps)"})
        lines = [ln for ln in res["lines"] if ln["shot"] == s["name"]]
        shot_spec = next(x for x in ep["shots"] if x["name"] == s["name"])
        sugg = _dark_suggestion(out / f"{key}_b.png", "The middle of this shot")
        if s["duration"] < 1.2:
            sugg.append({"id": "auto:short", "source": "auto", "text": f"Only {s['duration']:.1f} s: viewers may not register it."})
        if s["duration"] > 7.5 and "from" not in shot_spec["camera"]:
            sugg.append({"id": "auto:static", "source": "auto",
                         "text": f"{s['duration']:.1f} s on a static camera: add a slow push-in or split it into two angles to hold attention."})
        items.append({
            "id": f"shot:{s['name']}", "title": f"{i + 1}. {s['name'].replace('_', ' ')}", "media": media,
            "details": {"duration": f"{s['duration']:.2f} s", "starts at": f"{s['edit']:.2f} s",
                        "narration": " / ".join(ln["text"] for ln in lines) or "(none)",
                        "camera": shot_spec["camera"], "note": shot_spec.get("note", "")},
            "suggestions": sugg,
        })
    return items


def prepare(cfg: dict, ep_path: Path, gates: list[str] | None = None) -> Path:
    import tf
    rd = review_dir(ep_path)
    rd.mkdir(parents=True, exist_ok=True)
    ep = json.loads(ep_path.read_text(encoding="utf-8"))
    board = _read_json(rd / "board.json", {"gates": []})
    old = {g["id"]: g for g in board.get("gates", [])}
    _, res = tf.resolve_episode(ep_path, verbose=False)
    todo = gates or [g[0] for g in GATES]
    out_gates = []
    for gid, title, desc in GATES:
        if gid in todo:
            print(f"[TownForge] review: preparing {title}")
            items = {"env": lambda: _gate_env(cfg, ep_path, ep, rd),
                     "cast": lambda: _gate_cast(cfg, ep_path, ep, rd),
                     "voice": lambda: _gate_voice(cfg, ep_path, ep, rd, res),
                     "shots": lambda: _gate_shots(cfg, ep_path, ep, rd, res)}[gid]()
            for it in items:
                it["fingerprint"] = _fingerprint(rd, it)
            out_gates.append({"id": gid, "title": title, "description": desc, "items": items})
        elif gid in old:
            out_gates.append(old[gid])
    board = {"episode": ep.get("id"), "title": ep.get("title", ""), "prepared": time.strftime("%Y-%m-%d %H:%M"),
             "gates": out_gates}
    _write_json(rd / "board.json", board)
    print(f"[TownForge] review board -> {rd / 'board.json'} ({sum(len(g['items']) for g in out_gates)} items)")
    return rd


# --- state ------------------------------------------------------------------

def merged(rd: Path) -> dict:
    """Board + Claude's suggestions + the user's decisions, with gate locks."""
    board = _read_json(rd / "board.json", {"gates": []})
    claude = _read_json(rd / "suggestions.json", {})
    decisions = _read_json(rd / "decisions.json", {})
    open_ = True
    for g in board["gates"]:
        g["open"] = open_
        approved = 0
        for it in g["items"]:
            it["suggestions"] = it.get("suggestions", []) + [
                {**s, "source": "claude"} for s in claude.get(it["id"], [])]
            d = decisions.get(it["id"], {})
            stale = bool(d) and d.get("fingerprint") != it["fingerprint"]
            it["decision"] = {"status": "pending" if stale else d.get("status", "pending"), "note": d.get("note", ""),
                              "accepted": d.get("accepted", []), "stale": stale and d.get("status") == "approved",
                              "updated": d.get("updated")}
            approved += it["decision"]["status"] == "approved"
        g["approved"] = approved
        g["complete"] = approved == len(g["items"]) and bool(g["items"])
        open_ = open_ and g["complete"]
    board["all_approved"] = bool(board["gates"]) and all(g["complete"] for g in board["gates"])
    return board


def decide(rd: Path, item_id: str, status: str, note: str, accepted: list, fingerprint: str) -> None:
    if status not in STATUSES:
        raise ValueError(f"status must be one of {STATUSES}")
    path = rd / "decisions.json"
    with _LOCK:
        d = _read_json(path, {})
        d[item_id] = {"status": status, "note": note, "accepted": accepted, "fingerprint": fingerprint,
                      "updated": time.strftime("%Y-%m-%d %H:%M:%S")}
        _write_json(path, d)


_LOCK = threading.Lock()


def unapproved(ep_path: Path) -> list[str]:
    rd = review_dir(ep_path)
    if not (rd / "board.json").exists():
        return ["(no review board yet: run `tf review prepare`)"]
    out = []
    for g in merged(rd)["gates"]:
        for it in g["items"]:
            if it["decision"]["status"] != "approved":
                out.append(f"{g['title']}: {it['title']} ({'changed since approval' if it['decision']['stale'] else it['decision']['status']})")
    return out


def notes(ep_path: Path) -> str:
    """What the user asked for, compact, for Claude to act on."""
    b = merged(review_dir(ep_path))
    lines = [f"Review of {b.get('episode')} (prepared {b.get('prepared')})"]
    for g in b["gates"]:
        lines.append(f"\n## {g['title']}: {g['approved']}/{len(g['items'])} approved" + ("" if g["open"] else " (locked)"))
        for it in g["items"]:
            d = it["decision"]
            acc = [s for s in it["suggestions"] if s["id"] in d["accepted"]]
            if d["status"] == "approved" and not acc and not d["note"]:
                continue
            lines.append(f"- [{d['status'].upper()}{' / STALE' if d['stale'] else ''}] {it['id']}: {it['title']}")
            if d["note"]:
                lines.append(f"    note: {d['note']}")
            for s in acc:
                lines.append(f"    do: {s['text']}")
    return "\n".join(lines)


# --- server -----------------------------------------------------------------

_MIME = {".png": "image/png", ".jpg": "image/jpeg", ".wav": "audio/wav", ".mp4": "video/mp4",
         ".json": "application/json", ".html": "text/html; charset=utf-8"}


def make_handler(rd: Path):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):  # quiet
            pass

        def _send(self, code, body: bytes, ctype: str, extra: dict | None = None):
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            for k, v in (extra or {}).items():
                self.send_header(k, v)
            self.end_headers()
            self.wfile.write(body)

        def _json(self, data, code=200):
            self._send(code, json.dumps(data).encode("utf-8"), "application/json")

        def do_GET(self):
            path = self.path.split("?", 1)[0]
            if path in ("/", "/index.html"):
                return self._send(200, UI.read_bytes(), _MIME[".html"])
            if path == "/api/board":
                return self._json(merged(rd))
            if path.startswith("/media/"):
                return self._media(path[len("/media/"):])
            self._send(404, b"not found", "text/plain")

        def _media(self, rel: str):
            from urllib.parse import unquote
            p = (rd / unquote(rel)).resolve()
            if rd.resolve() not in p.parents or not p.is_file():
                return self._send(404, b"not found", "text/plain")
            data = p.read_bytes()
            ctype = _MIME.get(p.suffix.lower(), "application/octet-stream")
            rng = self.headers.get("Range")
            if rng and rng.startswith("bytes="):  # seeking in audio/video
                a, _, b = rng[6:].partition("-")
                start = int(a or 0)
                end = int(b) if b else len(data) - 1
                end = min(end, len(data) - 1)
                return self._send(206, data[start:end + 1], ctype,
                                  {"Content-Range": f"bytes {start}-{end}/{len(data)}", "Accept-Ranges": "bytes"})
            self._send(200, data, ctype, {"Accept-Ranges": "bytes"})

        def do_POST(self):
            n = int(self.headers.get("Content-Length", 0))
            try:
                body = json.loads(self.rfile.read(n) or b"{}")
                if self.path == "/api/decision":
                    decide(rd, body["item"], body["status"], body.get("note", ""), body.get("accepted", []),
                           body["fingerprint"])
                    return self._json({"ok": True})
                if self.path == "/api/approve_gate":
                    b = merged(rd)
                    g = next(g for g in b["gates"] if g["id"] == body["gate"])
                    if not g["open"]:
                        return self._json({"ok": False, "error": "this gate is locked"}, 409)
                    for it in g["items"]:
                        if it["decision"]["status"] == "pending":
                            decide(rd, it["id"], "approved", it["decision"]["note"], it["decision"]["accepted"],
                                   it["fingerprint"])
                    return self._json({"ok": True})
            except (KeyError, ValueError, StopIteration, json.JSONDecodeError) as e:
                return self._json({"ok": False, "error": str(e)}, 400)
            self._send(404, b"not found", "text/plain")

    return Handler


def serve(ep_path: Path, port: int = 8765, open_browser: bool = True) -> None:
    rd = review_dir(ep_path)
    if not (rd / "board.json").exists():
        raise SystemExit(f"ERROR: no review board for this episode; run: python pipeline/tf.py review prepare {ep_path.parent.name}")
    for p in range(port, port + 20):
        try:
            httpd = ThreadingHTTPServer(("127.0.0.1", p), make_handler(rd))
            break
        except OSError:
            continue
    else:
        raise SystemExit("ERROR: no free port")
    url = f"http://127.0.0.1:{httpd.server_address[1]}/"
    print(f"[TownForge] review board for {ep_path.parent.name}: {url}  (Ctrl+C to stop)")
    sys.stdout.flush()
    if open_browser:
        threading.Timer(0.6, lambda: webbrowser.open(url)).start()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
