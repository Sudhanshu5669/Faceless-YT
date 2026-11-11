"""The shot-by-shot loop: state on disk and the browser UI that drives it.

Files (episodes/<id>/review/):
  shot_decisions.json        the user's verdicts {shot: {status, note, updated, fingerprint, history}} (committed)
  shot_loop/index.json       every shot: name, key, edit, duration, text, fingerprint (written on each resolve)
  shot_loop/<key>.mp4        the latest clip of a shot (+ <key>_strip.png, <key>.json = its render meta)
  shot_loop/versions/        earlier clips (<key>_v<N>.mp4), to compare
  shot_loop/job.log          the output of the render running from the UI

A shot's fingerprint hashes what makes it look and sound the way it does (its camera, transitions,
lines and the reveals that appear in it), so the UI can say "changed since this clip" / "changed
since you approved it".

    python pipeline/tf.py shot jio_story --serve     # http://127.0.0.1:8770/
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import threading
import time
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import review

STATUSES = ("approved", "changes", "rejected")
UI = Path(__file__).resolve().parent / "review_ui" / "shots.html"
TF = Path(__file__).resolve().parent / "tf.py"


def loop_dir(ep_path: Path) -> Path:
    return ep_path.parent / "review" / "shot_loop"


def decisions_path(ep_path: Path) -> Path:
    return ep_path.parent / "review" / "shot_decisions.json"


def _read(path: Path, default):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return default


def fingerprint(res: dict, name: str) -> str:
    ep = res["episode"]
    shot = next(s for s in ep["shots"] if s["name"] == name)
    t0 = float(shot["scene_t"])
    t1 = t0 + float(shot["duration"])
    reveals = [r for r in ep.get("reveals", []) if t0 - 0.05 <= float(r.get("t", 0)) < t1]
    lines = [ln["text"] for ln in res["lines"] if ln["shot"] == name]
    blob = json.dumps({"shot": shot, "reveals": reveals, "lines": lines}, sort_keys=True)
    return hashlib.sha1(blob.encode("utf-8")).hexdigest()[:12]


def write_index(ep_path: Path, res: dict) -> list[dict]:
    """Every shot of the resolved episode, for the UI (called whenever tf resolves it)."""
    shots = []
    for i, s in enumerate(res["shots"]):
        lines = [ln["text"] for ln in res["lines"] if ln["shot"] == s["name"]]
        shots.append({"index": i, "name": s["name"], "key": f"{i:02d}_{s['name']}", "edit": round(float(s["edit"]), 3),
                      "duration": round(float(s["duration"]), 3), "text": " ".join(lines),
                      "fingerprint": fingerprint(res, s["name"])})
    d = loop_dir(ep_path)
    d.mkdir(parents=True, exist_ok=True)
    review._write_json(d / "index.json", {"episode": ep_path.parent.name, "title": res["episode"].get("title", ""),
                                          "updated": time.strftime("%Y-%m-%d %H:%M:%S"), "shots": shots})
    return shots


def record_render(ep_path: Path, key: str, meta: dict) -> None:
    """After a clip is made: bump its version, keep the previous clip under versions/."""
    d = loop_dir(ep_path)
    old = _read(d / f"{key}.json", {})
    version = int(old.get("version", 0)) + 1
    review._write_json(d / f"{key}.json", {**meta, "version": version, "rendered": time.strftime("%Y-%m-%d %H:%M:%S")})


def archive_clip(ep_path: Path, key: str) -> None:
    """Before a new clip replaces the old one."""
    d = loop_dir(ep_path)
    old = _read(d / f"{key}.json", {})
    clip = d / f"{key}.mp4"
    if clip.exists() and old.get("version"):
        (d / "versions").mkdir(exist_ok=True)
        clip.replace(d / "versions" / f"{key}_v{old['version']}.mp4")


def decide(ep_path: Path, name: str, status: str, note: str, fp: str = "") -> dict:
    if status not in STATUSES:
        raise ValueError(f"status must be one of {STATUSES}")
    path = decisions_path(ep_path)
    log = _read(path, {})
    prev = log.get(name, {})
    hist = list(prev.get("history", []))
    if prev.get("status"):
        hist.append({k: prev.get(k) for k in ("status", "note", "updated", "fingerprint")})
    log[name] = {"status": status, "note": note, "updated": time.strftime("%Y-%m-%d %H:%M:%S"),
                 "fingerprint": fp, "history": hist[-10:]}
    review._write_json(path, log)
    return log[name]


def state(ep_path: Path) -> dict:
    d = loop_dir(ep_path)
    idx = _read(d / "index.json", {"shots": []})
    dec = _read(decisions_path(ep_path), {})
    shots = []
    for s in idx["shots"]:
        meta = _read(d / f"{s['key']}.json", {})
        dd = dec.get(s["name"], {})
        rendered = bool(meta) and (d / f"{s['key']}.mp4").exists()
        versions = sorted(p.name for p in (d / "versions").glob(f"{s['key']}_v*.mp4")) if (d / "versions").exists() else []
        shots.append({**s, "clip": f"{s['key']}.mp4" if rendered else "", "strip": f"{s['key']}_strip.png" if rendered else "",
                      "version": meta.get("version", 0), "rendered": meta.get("rendered", ""), "final": meta.get("final", False),
                      "framing": meta.get("framing", []), "stale_clip": rendered and meta.get("fingerprint") != s["fingerprint"],
                      "decision": dd, "stale_decision": bool(dd) and dd.get("fingerprint") not in ("", s["fingerprint"]),
                      "versions": [f"versions/{v}" for v in versions]})
    return {"episode": idx.get("episode", ep_path.parent.name), "title": idx.get("title", ""), "updated": idx.get("updated", ""),
            "shots": shots, "job": JOB.status()}


# --- render jobs started from the UI --------------------------------------------------------

class Job:
    def __init__(self):
        self.proc: subprocess.Popen | None = None
        self.names: list[str] = []
        self.started = ""
        self.log: Path | None = None
        self.lock = threading.Lock()

    def start(self, ep_path: Path, args: list[str], names: list[str]) -> None:
        with self.lock:
            if self.proc and self.proc.poll() is None:
                raise RuntimeError("a render is already running")
            self.log = loop_dir(ep_path) / "job.log"
            self.log.parent.mkdir(parents=True, exist_ok=True)
            fh = open(self.log, "w", encoding="utf-8")
            self.proc = subprocess.Popen([sys.executable, str(TF), *args], stdout=fh, stderr=subprocess.STDOUT,
                                         cwd=str(TF.parent.parent))
            self.names = names
            self.started = time.strftime("%H:%M:%S")

    def status(self) -> dict:
        running = bool(self.proc and self.proc.poll() is None)
        tail = []
        if self.log and self.log.exists():
            lines = [ln for ln in self.log.read_text(encoding="utf-8", errors="replace").splitlines()
                     if "[TownForge]" in ln or ln.startswith("ERROR") or ln.startswith("  - ")]
            noise = ("leaked", "PagedAllocator", "never freed", "Pages in use")
            tail = [ln for ln in lines if not any(k in ln for k in noise)][-8:]
        return {"running": running, "names": self.names, "started": self.started, "tail": tail,
                "exit": None if running or not self.proc else self.proc.returncode}


JOB = Job()


# --- server ---------------------------------------------------------------------------------

_MIME = {".png": "image/png", ".mp4": "video/mp4", ".json": "application/json", ".html": "text/html; charset=utf-8"}


def make_handler(ep_path: Path):
    d = loop_dir(ep_path)

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):
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
            if path == "/api/state":
                return self._json(state(ep_path))
            if path.startswith("/media/"):
                from urllib.parse import unquote
                p = (d / unquote(path[len("/media/"):])).resolve()
                if d.resolve() not in p.parents or not p.is_file():
                    return self._send(404, b"not found", "text/plain")
                data = p.read_bytes()
                ctype = _MIME.get(p.suffix.lower(), "application/octet-stream")
                rng = self.headers.get("Range")
                if rng and rng.startswith("bytes="):
                    a, _, b = rng[6:].partition("-")
                    start = int(a or 0)
                    end = min(int(b) if b else len(data) - 1, len(data) - 1)
                    return self._send(206, data[start:end + 1], ctype,
                                      {"Content-Range": f"bytes {start}-{end}/{len(data)}", "Accept-Ranges": "bytes"})
                return self._send(200, data, ctype, {"Accept-Ranges": "bytes"})
            self._send(404, b"not found", "text/plain")

        def do_POST(self):
            n = int(self.headers.get("Content-Length", 0))
            try:
                body = json.loads(self.rfile.read(n) or b"{}")
                if self.path == "/api/decide":
                    st = state(ep_path)
                    shot = next(s for s in st["shots"] if s["name"] == body["name"])
                    return self._json({"ok": True, "decision": decide(ep_path, body["name"], body["status"],
                                                                     body.get("note", ""), shot["fingerprint"])})
                if self.path == "/api/render":
                    names = [x for x in body.get("names", []) if x]
                    if not names:
                        raise ValueError("no shots named")
                    JOB.start(ep_path, ["shot", ep_path.parent.name, ",".join(names)] + (["--final"] if body.get("final") else []), names)
                    return self._json({"ok": True})
                if self.path == "/api/refresh":
                    JOB.start(ep_path, ["shot", ep_path.parent.name, "--status"], [])
                    return self._json({"ok": True})
            except (KeyError, ValueError, StopIteration, RuntimeError, json.JSONDecodeError) as e:
                return self._json({"ok": False, "error": str(e)}, 400)
            self._send(404, b"not found", "text/plain")

    return Handler


def serve(ep_path: Path, port: int = 8770, open_browser: bool = True) -> None:
    for p in range(port, port + 20):
        try:
            httpd = ThreadingHTTPServer(("127.0.0.1", p), make_handler(ep_path))
            break
        except OSError:
            continue
    else:
        raise SystemExit("ERROR: no free port")
    url = f"http://127.0.0.1:{httpd.server_address[1]}/"
    print(f"[TownForge] shot loop for {ep_path.parent.name}: {url}  (Ctrl+C to stop)")
    sys.stdout.flush()
    if open_browser:
        threading.Timer(0.6, lambda: webbrowser.open(url)).start()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
