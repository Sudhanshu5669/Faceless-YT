"""Asset pack extraction: incoming/*.zip -> godot/assets/<pack>/.

Only files matched by pipeline/asset_packs.json are extracted. Zip entries are
treated as untrusted data: no absolute paths, no '..', nothing is executed.
"""
from __future__ import annotations

import fnmatch
import json
import shutil
import zipfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parent.parent
INCOMING = ROOT / "incoming"
ASSETS = ROOT / "godot" / "assets"
PACKS_FILE = Path(__file__).with_name("asset_packs.json")


def load_packs() -> list[dict]:
    return json.loads(PACKS_FILE.read_text(encoding="utf-8"))["packs"]


def _safe_rel(name: str) -> PurePosixPath | None:
    p = PurePosixPath(name)
    if p.is_absolute() or ".." in p.parts or ":" in name:
        return None
    return p


def _license_text(zf: zipfile.ZipFile) -> str:
    for n in zf.namelist():
        base = n.rsplit("/", 1)[-1].lower()
        if base in ("license.txt", "license_standard.txt"):
            return zf.read(n).decode("utf-8", "replace")
    return ""


def extract_pack(pack: dict, *, clean: bool = True) -> dict:
    zips = sorted(INCOMING.glob(pack["zip"]))
    if not zips:
        return {"id": pack["id"], "status": "missing", "files": 0}
    dest = ASSETS / pack["id"]
    if clean and dest.exists():
        shutil.rmtree(dest)
    dest.mkdir(parents=True, exist_ok=True)
    count = 0
    licenses = []
    for zpath in zips:
        with zipfile.ZipFile(zpath) as zf:
            licenses.append(f"--- {zpath.name} ---\n{_license_text(zf)}")
            for info in zf.infolist():
                if info.is_dir():
                    continue
                rel = _safe_rel(info.filename)
                if rel is None:
                    continue
                for folder, pattern, sub in pack["files"]:
                    path = str(rel)
                    if not path.startswith(folder):
                        continue
                    rest = path[len(folder):]
                    if "/" in rest or not fnmatch.fnmatch(rest, pattern):
                        continue
                    out = dest / sub / rest
                    out.parent.mkdir(parents=True, exist_ok=True)
                    with zf.open(info) as src, open(out, "wb") as dst:
                        shutil.copyfileobj(src, dst)
                    count += 1
                    break
    (dest / "LICENSE.txt").write_text("\n".join(licenses), encoding="utf-8")
    meta = {k: pack[k] for k in ("id", "author", "license", "url")}
    meta["sources"] = [z.name for z in zips]
    (dest / "pack.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
    return {"id": pack["id"], "status": "ok", "files": count, "zips": len(zips)}


def extract_all() -> list[dict]:
    ASSETS.mkdir(parents=True, exist_ok=True)
    return [extract_pack(p) for p in load_packs()]
