#!/usr/bin/env python3
"""TownForge pipeline CLI.

  python pipeline/tf.py test                         run Godot + Python tests
  python pipeline/tf.py validate SPEC                validate a spec (no window)
  python pipeline/tf.py preview-set SPEC [options]   render preview stills + contact sheet
  python pipeline/tf.py explore [SPEC] [options]     open the fly-through window
  python pipeline/tf.py storyboard EPISODE           start/mid/end still of every shot -> storyboard.png
  python pipeline/tf.py voice EPISODE                narration (Gemini TTS, cached) + timing table, no render
  python pipeline/tf.py review prepare EPISODE       render the approval board (environment, characters, voice, shots)
  python pipeline/tf.py review serve EPISODE         open the approval page in the browser
  python pipeline/tf.py review notes EPISODE         what the user approved / asked to change
  python pipeline/tf.py render EPISODE [--draft]     render an episode to MP4 with sound and captions (--draft: half size, 15 fps)
  python pipeline/tf.py library                      list looks, shot templates and views
  python pipeline/tf.py look save NAME FILE          validate a look and save it to library/looks/
  python pipeline/tf.py assets import                incoming/*.zip -> godot/assets -> Godot import -> catalog
  python pipeline/tf.py assets catalog [--pack ID]   rebuild library/catalog.json + thumbnails only

EPISODE is episodes/<id>/episode.json or just <id>. Output goes to episodes/<id>/renders/
(final) or episodes/<id>/preview/ (draft animatic, storyboard).

Options for preview-set / explore:
  --look NAME  --time HH:MM  --weather fog=0.8,rain=0.5  --seed N

Godot / FFmpeg paths come from config.local.json at the repo root
(see config.example.json) or the TOWNFORGE_GODOT environment variable.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

ROOT = Path(__file__).resolve().parent.parent
GODOT_PROJECT = ROOT / "godot"
DEFAULT_SPEC = "specs/sets/blackwood.json"
GODOT_TIMEOUT_S = 300


def load_config() -> dict:
    cfg = {"godot": "godot", "godot_gui": None, "ffmpeg": "ffmpeg"}
    local = ROOT / "config.local.json"
    if local.exists():
        cfg.update(json.loads(local.read_text(encoding="utf-8")))
    if os.environ.get("TOWNFORGE_GODOT"):
        cfg["godot"] = os.environ["TOWNFORGE_GODOT"]
    if not cfg.get("godot_gui"):
        cfg["godot_gui"] = cfg["godot"]
    return cfg


def run_godot(cfg: dict, user_args: list[str], *, headless: bool = False,
              script: str | None = None, pre_args: list[str] | None = None,
              timeout: int = GODOT_TIMEOUT_S) -> int:
    """Run Godot, stream its [TownForge] lines and errors, return the exit code."""
    cmd = [cfg["godot"], "--path", str(GODOT_PROJECT), *(pre_args or [])]
    if headless:
        cmd.append("--headless")
    if script:
        cmd += ["--script", script]
    if user_args:
        cmd += ["--", *user_args]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8",
                              errors="replace", timeout=timeout)
    except subprocess.TimeoutExpired:
        print(f"ERROR: Godot did not finish within {timeout}s "
              "(a script error can leave the window open)", file=sys.stderr)
        return 124
    output = proc.stdout + proc.stderr
    for line in output.splitlines():
        if "Unreferenced static string" in line or "string_name.cpp" in line:
            continue  # engine shutdown noise
        if ("[TownForge]" in line or "ERROR" in line or "SCRIPT" in line or line.startswith("   at:")
                or line.startswith("  PASS") or line.startswith("  FAIL") or line.startswith("  - ")
                or line.startswith("        ")):
            print(line)
    if proc.returncode != 0 and "[TownForge]" not in output:
        print(output[-3000:])
    if script and "[TownForge] tests:" not in output:
        print("ERROR: the Godot test runner did not finish (see errors above)", file=sys.stderr)
        return proc.returncode or 1
    return proc.returncode


def contact_sheet(cfg: dict, stills: list[Path], out: Path, tile_w: int = 360) -> None:
    if not stills:
        return
    cmd = [cfg["ffmpeg"], "-y", "-loglevel", "error"]
    for s in stills:
        cmd += ["-i", str(s)]
    scaled = "".join(f"[{i}:v]scale={tile_w}:-1[v{i}];" for i in range(len(stills)))
    inputs = "".join(f"[v{i}]" for i in range(len(stills)))
    if len(stills) == 1:
        graph = f"[0:v]scale={tile_w}:-1[out]"
    else:
        graph = f"{scaled}{inputs}hstack=inputs={len(stills)}[out]"
    cmd += ["-filter_complex", graph, "-map", "[out]", "-frames:v", "1", str(out)]
    subprocess.run(cmd, check=True)


def cmd_test(cfg: dict, _args) -> int:
    code = run_godot(cfg, [], headless=True, script="res://tests/run_tests.gd")
    print("[TownForge] running Python tests")
    py_tests = str(ROOT / "tests" / "python")
    suite = unittest.defaultTestLoader.discover(py_tests, top_level_dir=py_tests)
    result = unittest.TextTestRunner(verbosity=1).run(suite)
    return code or (0 if result.wasSuccessful() else 1)


def cmd_validate(cfg: dict, args) -> int:
    path = (ROOT / args.spec) if not Path(args.spec).is_absolute() else Path(args.spec)
    if path.exists() and "shots" in _read_json(path):
        # Episodes: resolve voice timing, then resolve every camera against the
        # built set (needs a renderer).
        resolved, _ = resolve_episode(path)
        return run_godot(cfg, ["--episode", str(resolved)], pre_args=["--quit-after", "2000"])
    return run_godot(cfg, ["--spec", args.spec, "--validate"], headless=True)


# --- episodes ---------------------------------------------------------------

def episode_path(ref: str) -> Path:
    p = Path(ref)
    if not p.is_absolute():
        p = ROOT / p
    if p.is_dir():
        p = p / "episode.json"
    if not p.exists() and (ROOT / "episodes" / ref / "episode.json").exists():
        p = ROOT / "episodes" / ref / "episode.json"
    if not p.exists():
        raise SystemExit(f"ERROR: no episode at {ref} (expected episodes/<id>/episode.json)")
    return p


def resolve_episode(path: Path, verbose: bool = True) -> tuple[Path, dict]:
    """Voice first: synthesize + time the narration, size "fit" shots, resolve time
    references. Writes episodes/<id>/build/episode.resolved.json for Godot."""
    import episode_audio
    res = episode_audio.resolve(path, verbose=verbose)
    out = path.parent / "build" / "episode.resolved.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(res["episode"], indent=2), encoding="utf-8")
    return out, res


def cmd_voice(cfg: dict, args) -> int:
    resolve_episode(episode_path(args.episode))
    return 0


def _episode_frames(ep: dict, fps: int) -> int:
    return sum(max(1, round(float(s["duration"]) * fps)) for s in ep.get("shots", []))


def encode_frames(cfg: dict, frames_dir: Path, fps: int, out: Path, blur: int = 1) -> None:
    """Frames -> H.264. With blur > 1 the frames were rendered at fps * blur and every
    output frame is the average of `blur` sub-frames: real motion blur (whip pans)."""
    out.parent.mkdir(parents=True, exist_ok=True)
    vf = ["-vf", f"tmix=frames={blur},framestep={blur}"] if blur > 1 else []
    subprocess.run([cfg["ffmpeg"], "-y", "-loglevel", "error", "-framerate", str(fps * blur),
                    "-i", str(frames_dir / "%05d.png"), *vf, "-c:v", "libx264", "-preset", "medium",
                    "-crf", "18", "-pix_fmt", "yuv420p", "-r", str(fps), "-movflags", "+faststart",
                    str(out)], check=True)


def concat_videos(cfg: dict, parts: list[Path], out: Path) -> None:
    listing = out.with_suffix(".txt")
    listing.write_text("".join(f"file '{p.as_posix()}'\n" for p in parts), encoding="utf-8")
    subprocess.run([cfg["ffmpeg"], "-y", "-loglevel", "error", "-f", "concat", "-safe", "0",
                    "-i", str(listing), "-c", "copy", "-movflags", "+faststart", str(out)], check=True)
    listing.unlink()


def cmd_render(cfg: dict, args) -> int:
    path = episode_path(args.episode)
    if not args.draft and not getattr(args, "force", False):
        import review
        missing = review.unapproved(path)
        if missing:
            print("ERROR: the final render needs every review item approved (tf review serve). Not yet:\n  - "
                  + "\n  - ".join(missing[:20]) + ("\n  ..." if len(missing) > 20 else "")
                  + "\n(--draft renders anyway; --force skips this check)", file=sys.stderr)
            return 1
    resolved, res = resolve_episode(path)
    ep = _read_json(resolved)
    ep_id = ep.get("id", path.parent.name)
    fps = int(ep.get("format", {}).get("fps", 30))
    scale = 1.0
    root = path.parent / "renders"
    blur = max(1, int(ep.get("format", {}).get("motion_blur", 1)))
    if args.draft:
        fps, scale, root, blur = 15, 0.5, path.parent / "preview" / "animatic", 1
    if getattr(args, "scale", None):
        scale = float(args.scale)
    frames_root = root / "frames"
    only = [s for s in (args.shots or "").split(",") if s]
    for d in frames_root.glob("[0-9][0-9]_*"):
        if not only or d.name[3:] in only:
            for f in d.glob("*.png"):
                f.unlink()
    if getattr(args, "remix", False):
        return _remix(cfg, res, root, ep_id, fps, args.draft)
    rfps = fps * blur  # rendered frame rate (sub-frames when motion blur is on)
    total = _episode_frames(ep, rfps) + 40 * len(ep.get("shots", []))
    user = ["--episode", str(resolved), "--frames", str(frames_root), "--fps", str(rfps), "--scale", str(scale)]
    if only:
        user += ["--shots", ",".join(only)]
    print(f"[TownForge] rendering {ep_id}: {len(ep.get('shots', []))} shots, "
          f"{_episode_frames(ep, rfps)} frames at {rfps} fps" + (f" ({blur} sub-frames each)" if blur > 1 else ""))
    code = run_godot(cfg, user, pre_args=["--fixed-fps", str(rfps), "--disable-vsync", "--quit-after", str(total + 600)],
                     timeout=600 + total * 2)
    if code != 0:
        return code
    timeline = _read_json(frames_root / "timeline.json")
    parts = []
    for shot in timeline["shots"]:
        d = frames_root / shot["dir"]
        n = len(list(d.glob("*.png")))
        if n != shot["frames"]:
            if only and shot["name"] not in only:
                print(f"[TownForge] shot {shot['name']} has never been rendered; "
                      "run without --shots to assemble the full video")
                return 0
            print(f"ERROR: shot {shot['name']}: expected {shot['frames']} frames, found {n}", file=sys.stderr)
            return 1
        part = root / "shots" / f"{shot['dir']}.mp4"
        if not only or shot["name"] in only or not part.exists():
            encode_frames(cfg, d, fps, part, blur)
        parts.append(part)
    out = root / (f"{ep_id}_animatic.mp4" if args.draft else f"{ep_id}.mp4")
    secs = sum(float(s["duration"]) for s in timeline["shots"])
    has_sound = bool(res["lines"] or res["sfx"] or res["ambience"])
    if not has_sound:
        concat_videos(cfg, parts, out)
    else:
        concat_videos(cfg, parts, root / f"{ep_id}_picture.mp4")
        return _remix(cfg, res, root, ep_id, fps, args.draft)
    print(f"[TownForge] video -> {out} ({timeline['resolution'][0]}x{timeline['resolution'][1]}, "
          f"{fps} fps, {secs:.1f} s)")
    return 0


def _remix(cfg: dict, res: dict, root: Path, ep_id: str, fps: int, draft: bool) -> int:
    """Soundtrack + captions over the rendered picture (no Godot run)."""
    import episode_audio
    picture = root / f"{ep_id}_picture.mp4"
    timeline_path = root / "frames" / "timeline.json"
    if not picture.exists() or not timeline_path.exists():
        print(f"ERROR: no rendered picture at {picture}; run render without --remix first", file=sys.stderr)
        return 1
    timeline = _read_json(timeline_path)
    pic_secs = sum(float(s["duration"]) for s in timeline["shots"])
    if abs(pic_secs - res["duration"]) > 0.05:
        print(f"ERROR: the narration timing changed ({res['duration']:.2f} s vs the rendered {pic_secs:.2f} s); "
              "render the picture again (without --remix)", file=sys.stderr)
        return 1
    out = root / (f"{ep_id}_animatic.mp4" if draft else f"{ep_id}.mp4")
    audio = episode_audio.mix(res, root / "mix.wav", cfg["ffmpeg"])
    res["resolution"] = timeline["resolution"]
    captions = None
    if res["lines"] and res["captions"].get("enabled", True):
        captions = episode_audio.write_captions(res, root / "captions.ass")
    episode_audio.finish(cfg["ffmpeg"], picture, audio, captions, out, res["end_black"], fps)
    lufs = episode_audio.measure_lufs(cfg["ffmpeg"], out)
    print(f"[TownForge] sound: {len(res['lines'])} lines, {len(res['sfx'])} effects, "
          f"{len(res['ambience'])} beds, {lufs:.1f} LUFS" + (", captions burned in" if captions else ""))
    print(f"[TownForge] video -> {out} ({timeline['resolution'][0]}x{timeline['resolution'][1]}, "
          f"{fps} fps, {pic_secs + res['end_black']:.1f} s)")
    return 0


def cmd_review(cfg: dict, args) -> int:
    import review
    path = episode_path(args.episode)
    if args.action == "prepare":
        gates = [g for g in (args.gate or "").split(",") if g] or None
        review.prepare(cfg, path, gates)
        return 0
    if args.action == "serve":
        review.serve(path, args.port, not args.no_browser)
        return 0
    print(review.notes(path))
    return 0


def cmd_storyboard(cfg: dict, args) -> int:
    path = episode_path(args.episode)
    resolved, _ = resolve_episode(path)
    ep = _read_json(resolved)
    out = path.parent / "preview" / "storyboard"
    out.mkdir(parents=True, exist_ok=True)
    for f in out.glob("*.png"):
        f.unlink()
    n_shots = len(ep.get("shots", []))
    code = run_godot(cfg, ["--episode", str(resolved), "--storyboard", str(out)],
                     pre_args=["--fixed-fps", "30", "--quit-after", str(1000 + 100 * n_shots)],
                     timeout=300 + 20 * n_shots)
    if code != 0:
        return code
    stills = sorted(out.glob("[0-9][0-9]_*_[abc].png"))
    if len(stills) != 3 * n_shots:
        print(f"ERROR: expected {3 * n_shots} storyboard stills, got {len(stills)}", file=sys.stderr)
        return 1
    # One row per shot: start | middle | end.
    seq = out / "_seq"
    seq.mkdir(exist_ok=True)
    for i, s in enumerate(stills):
        (seq / f"{i:04d}.png").write_bytes(s.read_bytes())
    sheet = path.parent / "preview" / "storyboard.png"
    subprocess.run([cfg["ffmpeg"], "-y", "-loglevel", "error", "-framerate", "1", "-i", str(seq / "%04d.png"),
                    "-vf", f"scale=200:-1,tile=3x{n_shots}:padding=4:color=white", "-frames:v", "1", str(sheet)],
                   check=True)
    for f in seq.glob("*.png"):
        f.unlink()
    seq.rmdir()
    print(f"[TownForge] storyboard -> {sheet} (one row per shot: start, middle, end)")
    return 0


def _overrides(args) -> list[str]:
    out = []
    if getattr(args, "look", None):
        out += ["--look", args.look]
    if getattr(args, "seed", None) is not None:
        out += ["--seed", str(args.seed)]
    if getattr(args, "time", None):
        out += ["--time", args.time]
    if getattr(args, "weather", None):
        out += ["--weather", args.weather]
    return out


def _read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def cmd_library(_cfg: dict, _args) -> int:
    """Print what the director can use: looks, shot templates, named views."""
    print("LOOKS (library/looks) - use as \"look\": \"<id>\" or {\"base\": \"<id>\", ...overrides}")
    for path in sorted((ROOT / "library" / "looks").glob("*.json")):
        look = _read_json(path)
        bits = []
        if "base" in look:
            bits.append(f"base {look['base'] if isinstance(look['base'], str) else 'inline'}")
        if "time" in look:
            bits.append(f"time {look['time']}")
        if look.get("weather"):
            bits.append("weather " + ",".join(f"{k}={v}" for k, v in look["weather"].items()))
        tags = ",".join(look.get("tags", []))
        print(f"  {path.stem:<18} {look.get('description', '')}")
        print(f"  {'':<18} [{'; '.join(bits)}]{('  tags: ' + tags) if tags else ''}")
    print("\nSHOT TEMPLATES (library/shots) - use as {\"template\": \"<id>\", \"subject\": \"<anchor>\"}")
    for path in sorted((ROOT / "library" / "shots").glob("*.json")):
        shot = _read_json(path)
        print(f"  {path.stem:<18} {shot.get('description', '')}")
    print("\nKITS (library/kits) - set param \"kit\": \"<id>\" (or \"primitive\"), \"season\": summer|autumn|winter|dead|dead_winter")
    for path in sorted((ROOT / "library" / "kits").glob("*.json")):
        print(f"  {path.stem:<18} {_read_json(path).get('description', '')}")
    cat_path = ROOT / "library" / "catalog.json"
    if cat_path.exists():
        from collections import Counter
        models = _read_json(cat_path)["models"]
        counts = Counter(m["category"] for m in models)
        print(f"\nCATALOG (library/catalog.json) - {len(models)} models: " + ", ".join(f"{k} {v}" for k, v in counts.most_common()))
    print("\nCHARACTERS (library/characters) - actor \"character\": \"<id>\"")
    for path in sorted((ROOT / "library" / "characters").glob("*.json")):
        print(f"  {path.stem:<18} {_read_json(path).get('description', '')}")
    acts_path = ROOT / "library" / "actions.json"
    if acts_path.exists():
        acts = _read_json(acts_path)["actions"]
        moving = [f"{k} ({v['speed']} m/s)" for k, v in acts.items() if v.get("gait")]
        standing = [k + (f" (freeze marks: {', '.join(v['marks'])})" if v.get("marks") else "")
                    for k, v in acts.items() if not v.get("gait")]
        print("\nACTIONS (library/actions.json)")
        print("  standing: " + ", ".join(standing))
        print("  moving (route gaits): " + ", ".join(moving))
    print("\nNAMED VIEWS - use as \"<view>\" or {\"view\": \"<view>\", ...overrides}")
    print("  aerial, street, house[:house_N], intersection, entrance")
    return 0


def _godot_import(cfg: dict) -> int:
    print("[TownForge] Godot import (first run can take a few minutes)...")
    proc = subprocess.run([cfg["godot"], "--headless", "--path", str(GODOT_PROJECT), "--import"],
                          capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=1800)
    errors = [l for l in (proc.stdout + proc.stderr).splitlines() if "ERROR" in l]
    for line in errors[:20]:
        print(line)
    return proc.returncode or (1 if errors else 0)


def _catalog(cfg: dict, pack: str | None) -> int:
    print("[TownForge] building catalog + thumbnails...")
    extra = ["--", "--pack", pack] if pack else []
    proc = subprocess.run([cfg["godot"], "--path", str(GODOT_PROJECT), "res://tools/catalog.tscn", *extra],
                          capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=1800)
    out = proc.stdout + proc.stderr
    for line in out.splitlines():
        if "[TownForge]" in line or "SCRIPT ERROR" in line:
            print(line)
    return proc.returncode


def cmd_assets(cfg: dict, args) -> int:
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import assets
    if args.assets_command == "import":
        for r in assets.extract_all():
            print(f"[TownForge] {r['id']:<26} {r['status']:<8} {r['files']} files")
        code = _godot_import(cfg)
        if code != 0:
            return code
        return _catalog(cfg, None)
    return _catalog(cfg, args.pack)


def cmd_look_save(cfg: dict, args) -> int:
    """Save a look object (a .json file holding a look, or a spec with an inline look)."""
    src = _read_json(Path(args.file))
    look = src.get("look", src) if isinstance(src.get("look"), dict) else src
    if not isinstance(look, dict):
        print("ERROR: no look object found in", args.file, file=sys.stderr)
        return 1
    name = args.name
    dest = ROOT / "library" / "looks" / f"{name}.json"
    if dest.exists() and not args.force:
        print(f"ERROR: {dest.relative_to(ROOT)} exists (use --force to replace it)", file=sys.stderr)
        return 1
    look = {"id": name, **{k: v for k, v in look.items() if k != "id"}}
    if args.description:
        look["description"] = args.description
    if not look.get("description"):
        print("ERROR: a saved look needs a description (--description \"...\")", file=sys.stderr)
        return 1
    previous = dest.read_text(encoding="utf-8") if dest.exists() else None
    dest.write_text(json.dumps(look, indent=2) + "\n", encoding="utf-8")
    code = run_godot(cfg, ["--spec", DEFAULT_SPEC, "--look", name, "--validate"], headless=True)
    if code != 0:
        if previous is None:
            dest.unlink()
        else:
            dest.write_text(previous, encoding="utf-8")
        print("ERROR: look is invalid; nothing saved", file=sys.stderr)
        return code
    print(f"[TownForge] saved look '{name}' -> {dest.relative_to(ROOT)}")
    return 0


def cmd_preview_set(cfg: dict, args) -> int:
    spec_path = (ROOT / args.spec) if not Path(args.spec).is_absolute() else Path(args.spec)
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    set_id = spec.get("set", {}).get("id", spec_path.stem)
    look = args.look or spec.get("look", "look")
    if not isinstance(look, str):
        look = look.get("id", "inline")
    if args.time:
        look += "_t" + args.time.replace(":", "")
    if args.weather:
        look += "_" + args.weather.replace("=", "").replace(",", "_").replace(".", "")
    seed = args.seed if args.seed is not None else spec.get("set", {}).get("seed")
    out = Path(args.out) if args.out else ROOT / "output" / "previews" / f"{set_id}_s{seed}_{look}"
    out.mkdir(parents=True, exist_ok=True)
    for old in out.glob("*.png"):
        old.unlink()
    views = spec.get("preview", {}).get("views", ["aerial", "street", "house", "intersection", "entrance"])
    # Frame budget: if a script error stops the run before it quits, Godot
    # still exits instead of leaving a window open.
    budget = 600 + 60 * len(views)
    code = run_godot(cfg, ["--spec", str(spec_path), "--stills", str(out), *_overrides(args)],
                     pre_args=["--quit-after", str(budget)])
    if code != 0:
        return code
    stills = sorted(p for p in out.glob("[0-9][0-9]_*.png"))
    if len(stills) != len(views):
        print(f"ERROR: expected {len(views)} stills, got {len(stills)} (see errors above)", file=sys.stderr)
        return 1
    sheet = out / "contact_sheet.png"
    contact_sheet(cfg, stills, sheet)
    print(f"[TownForge] contact sheet -> {sheet}")
    return 0


def cmd_explore(cfg: dict, args) -> int:
    cmd = [cfg["godot_gui"], "--path", str(GODOT_PROJECT), "--", "--spec", args.spec, *_overrides(args)]
    subprocess.Popen(cmd)
    print("[TownForge] explore window launched")
    return 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="tf", description="TownForge pipeline")
    sub = ap.add_subparsers(dest="command", required=True)
    sub.add_parser("test", help="run Godot + Python tests")
    v = sub.add_parser("validate", help="validate a spec")
    v.add_argument("spec")
    for name, helptext in (("preview-set", "render preview stills + contact sheet"),
                           ("explore", "open the interactive fly-through window")):
        p = sub.add_parser(name, help=helptext)
        p.add_argument("spec", nargs="?", default=DEFAULT_SPEC)
        p.add_argument("--look", help="override the spec's look (e.g. day, dusk, night_fog)")
        p.add_argument("--seed", type=int, help="override the set seed")
        p.add_argument("--time", help="time of day on top of the look, e.g. 03:33")
        p.add_argument("--weather", help="weather on top of the look, e.g. fog=0.8,rain=0.5")
        if name == "preview-set":
            p.add_argument("--out", help="output directory (default output/previews/<set>_s<seed>_<look>)")
    rp = sub.add_parser("render", help="render an episode to MP4")
    rp.add_argument("episode", help="episodes/<id>/episode.json or <id>")
    rp.add_argument("--draft", action="store_true", help="half resolution, 15 fps animatic in preview/")
    rp.add_argument("--shots", help="re-render only these shots (comma-separated names)")
    rp.add_argument("--remix", action="store_true", help="rebuild only the sound and captions over the rendered picture")
    rp.add_argument("--force", action="store_true", help="final render even if review items are not approved")
    rp.add_argument("--scale", type=float, help="resolution scale (e.g. 0.5 for a quick look at full frame rate)")
    rv = sub.add_parser("review", help="approval board: prepare, serve, notes")
    rv.add_argument("action", choices=["prepare", "serve", "notes"])
    rv.add_argument("episode", help="episodes/<id>/episode.json or <id>")
    rv.add_argument("--gate", help="prepare only these gates: env,cast,voice,shots")
    rv.add_argument("--port", type=int, default=8765)
    rv.add_argument("--no-browser", action="store_true")
    vp = sub.add_parser("voice", help="synthesize + time the narration, print the timing table")
    vp.add_argument("episode", help="episodes/<id>/episode.json or <id>")
    sb = sub.add_parser("storyboard", help="start/mid/end stills of every shot")
    sb.add_argument("episode", help="episodes/<id>/episode.json or <id>")
    sub.add_parser("library", help="list looks, shot templates and views")
    lk = sub.add_parser("look", help="manage looks")
    lk_sub = lk.add_subparsers(dest="look_command", required=True)
    save = lk_sub.add_parser("save", help="validate a look object and save it to library/looks/")
    save.add_argument("name")
    save.add_argument("file", help="JSON file with a look object (or a spec with an inline look)")
    save.add_argument("--description")
    save.add_argument("--force", action="store_true", help="replace an existing look")
    asp = sub.add_parser("assets", help="import downloaded asset packs")
    asp_sub = asp.add_subparsers(dest="assets_command", required=True)
    asp_sub.add_parser("import", help="extract incoming/*.zip, run Godot import, rebuild catalog")
    cat = asp_sub.add_parser("catalog", help="rebuild library/catalog.json and thumbnails")
    cat.add_argument("--pack", help="only this pack")
    args = ap.parse_args(argv)
    cfg = load_config()
    if args.command == "assets":
        return cmd_assets(cfg, args)
    if args.command == "look":
        return cmd_look_save(cfg, args)
    handlers = {"test": cmd_test, "validate": cmd_validate, "library": cmd_library,
                "preview-set": cmd_preview_set, "explore": cmd_explore,
                "render": cmd_render, "storyboard": cmd_storyboard, "voice": cmd_voice, "review": cmd_review}
    return handlers[args.command](cfg, args)


if __name__ == "__main__":
    sys.exit(main())
