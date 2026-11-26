#!/usr/bin/env python3
"""Generate many Kimodo motions with the text reader loaded once, and import them into library/motions/.

  python pipeline/kimodo_batch.py episodes/<id>/motions.json [--only a,b] [--force]

motions.json: {"motions": [{"name": "adani_haul", "prompt": "A person ...", "duration": 4, "seed": 42}]}

Raw files and a stick-figure strip per motion go to <kimodo_dir>/out/. Look at the strip, then add the printed action
to library/actions.json. Motions already in library/motions/ are skipped (--force regenerates and overwrites them).
"kimodo_dir" comes from config.local.json (default E:/AgentTools/kimodo). Close heavy apps first: about 20 GB of
memory is reserved while the models are loaded.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODEL = "Kimodo-SOMA-RP-v1.2"
JOB_KEYS = {"name", "prompt", "duration", "seed"}


def kimodo_dir() -> Path:
    config = ROOT / "config.local.json"
    data = json.loads(config.read_text(encoding="utf-8")) if config.exists() else {}
    return Path(data.get("kimodo_dir", "E:/AgentTools/kimodo"))


def load_jobs(path: Path, only: str, force: bool) -> list:
    jobs = json.loads(path.read_text(encoding="utf-8"))["motions"]
    seen = set()
    for job in jobs:
        unknown = set(job) - JOB_KEYS
        if unknown or not {"name", "prompt", "duration"} <= set(job):
            raise SystemExit(f"bad motion entry {job}: keys are {sorted(JOB_KEYS)} (seed optional)")
        if not re.fullmatch(r"[a-z0-9_]+", job["name"]) or job["name"] in seen:
            raise SystemExit(f"motion name '{job['name']}' must be unique, lower case, digits and _ only")
        if not 0.5 <= float(job["duration"]) <= 10:
            raise SystemExit(f"{job['name']}: duration must be 0.5-10 s")
        seen.add(job["name"])
        job.setdefault("seed", 42)
    if only:
        wanted = set(only.split(","))
        if wanted - seen:
            raise SystemExit(f"unknown motion name(s): {sorted(wanted - seen)}")
        jobs = [j for j in jobs if j["name"] in wanted]
    return [j for j in jobs if force or not (ROOT / "library" / "motions" / f"{j['name']}.json").exists()]


def strip(joints, parents, path: Path) -> None:
    """Ten frames of the motion as stick figures, seen from the front quarter."""
    import numpy as np
    from PIL import Image, ImageDraw

    hips = joints[:, 0]
    right = np.array([np.cos(np.radians(55)), 0.0, -np.sin(np.radians(55))])
    picks = np.linspace(0, len(joints) - 1, 10).astype(int)
    w, h, scale = 260, 440, 190
    sheet = Image.new("RGB", (w * 5, h * 2), (24, 26, 30))
    draw = ImageDraw.Draw(sheet)
    for n, f in enumerate(picks):
        ox, oy = (n % 5) * w + w / 2, (n // 5) * h + h - 40
        pose = joints[f] - np.array([hips[f, 0], 0.0, hips[f, 2]])
        draw.line([(ox - 100, oy), (ox + 100, oy)], fill=(70, 74, 82), width=2)
        for i, p in enumerate(parents):
            if p < 0:
                continue
            a, b = pose[p], pose[i]
            side = (255, 140, 60) if b[0] < -0.05 else (80, 180, 255) if b[0] > 0.05 else (230, 230, 230)
            draw.line([(ox + a @ right * scale, oy - a[1] * scale), (ox + b @ right * scale, oy - b[1] * scale)],
                      fill=side, width=3)
        draw.text(((n % 5) * w + 8, (n // 5) * h + 8), f"{f / 30:.1f} s", fill=(200, 200, 200))
    sheet.save(path)


def worker(jobs_file: Path) -> None:
    """Runs inside Kimodo's own Python."""
    from kimodo import load_model
    from kimodo.exports.motion_io import save_kimodo_npz
    from kimodo.tools import seed_everything

    work = json.loads(jobs_file.read_text(encoding="utf-8"))
    out = Path(work["out"])
    started = time.time()
    model = load_model(MODEL, device="cuda:0", default_family="Kimodo")
    print(f"models loaded in {time.time() - started:.0f} s", flush=True)
    skeleton = getattr(model.skeleton, "somaskel77", model.skeleton)
    parents = [int(p) for p in skeleton.joint_parents]
    for job in work["jobs"]:
        t0 = time.time()
        seed_everything(int(job["seed"]))
        result = model([job["prompt"].rstrip(".") + "."], [int(float(job["duration"]) * model.fps)],
                       constraint_lst=[], num_denoising_steps=100, num_samples=1, multi_prompt=True,
                       num_transition_frames=5, post_processing=True, return_numpy=True)
        single = {k: (v[0] if hasattr(v, "shape") and len(v.shape) > 0 and v.shape[0] == 1 else v)
                  for k, v in result.items()}
        save_kimodo_npz(str(out / f"{job['name']}.npz"), single)
        strip(single["posed_joints"], parents, out / f"{job['name']}_strip.png")
        print(f"{job['name']}: generated in {time.time() - t0:.0f} s", flush=True)


def main() -> None:
    if len(sys.argv) == 3 and sys.argv[1] == "--worker":
        worker(Path(sys.argv[2]))
        return
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("motions", type=Path)
    ap.add_argument("--only", default="")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()
    jobs = load_jobs(args.motions, args.only, args.force)
    if not jobs:
        print("nothing to do: every motion is already in library/motions/ (--force regenerates)")
        return
    base = kimodo_dir()
    python = base / "venv" / "Scripts" / "python.exe"
    if not python.exists():
        raise SystemExit(f"Kimodo not found at {base} (set \"kimodo_dir\" in config.local.json)")
    out = base / "out"
    out.mkdir(exist_ok=True)
    work = out / "jobs.json"
    work.write_text(json.dumps({"out": str(out), "jobs": jobs}), encoding="utf-8")
    for job in jobs:  # a stale file must not pass for a new result
        (out / f"{job['name']}.npz").unlink(missing_ok=True)
    env = dict(os.environ, HF_HOME=str(base / "hf"), HF_HUB_OFFLINE="1",
               TEXT_ENCODER_DEVICE="cpu", TEXT_ENCODER_MODE="local")
    started = time.time()
    # output is not piped, so progress bars cannot stall the run
    code = subprocess.run([str(python), "-I", "-X", "utf8", str(Path(__file__).resolve()), "--worker", str(work)],
                          env=env).returncode

    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from import_motion import convert

    done, failed = [], []
    for job in jobs:
        npz = out / f"{job['name']}.npz"
        if not npz.exists():
            failed.append(job["name"])
            continue
        clip = convert(npz, job["name"], job["prompt"], f"nvidia/{MODEL}", 30.0)
        target = ROOT / "library" / "motions" / f"{job['name']}.json"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(clip, separators=(",", ":")), encoding="utf-8")
        done.append(job["name"])
    print(f"\n{len(done)} of {len(jobs)} imported in {time.time() - started:.0f} s. Strips: {out}")
    for name in done:
        print(f'  "{name}": {{ "anim": "mocap_{name}", "loop": false, "description": "..." }},')
    if code != 0 or failed:
        raise SystemExit(f"ERROR: Kimodo exit code {code}; missing: {failed or 'none'}")


if __name__ == "__main__":
    main()
