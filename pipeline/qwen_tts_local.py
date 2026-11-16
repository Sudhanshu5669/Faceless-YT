"""Run the optional Qwen runtime in its own Python environment."""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path
from tempfile import NamedTemporaryFile

ROOT = Path(__file__).resolve().parent.parent
MODEL = ROOT / "models" / "qwen3-tts" / "1.7b-customvoice"
ENV = ROOT / ".venv" / "qwen-tts"
PYTHON = ENV / ("Scripts/python.exe" if os.name == "nt" else "bin/python")


def generate(requests: list[dict[str, str]]) -> None:
    if not PYTHON.is_file() or not all((MODEL / name).is_file() for name in (
        "model.safetensors", "speech_tokenizer/model.safetensors",
    )):
        raise SystemExit("ERROR: local Qwen TTS is missing its runtime or model weights. See docs/AUDIO_SPEC.md.")
    env = {**os.environ, "HF_HUB_OFFLINE": "1", "PYTHONIOENCODING": "utf-8"}
    result = subprocess.run([str(PYTHON), str(Path(__file__).resolve())],
                            input=json.dumps(requests), text=True, encoding="utf-8", env=env)
    if result.returncode:
        raise SystemExit(f"ERROR: local Qwen TTS exited with code {result.returncode}")


def _run(requests: list[dict[str, str]]) -> None:
    import soundfile as sf
    import torch
    from qwen_tts import Qwen3TTSModel

    if not torch.cuda.is_available():
        raise SystemExit("ERROR: local Qwen TTS requires CUDA PyTorch in .venv/qwen-tts. See docs/AUDIO_SPEC.md.")
    print(f"[TownForge] Qwen TTS: loading on {torch.cuda.get_device_name()} for {len(requests)} take(s)", flush=True)
    model = Qwen3TTSModel.from_pretrained(str(MODEL), device_map="cuda:0", dtype=torch.bfloat16,
                                         attn_implementation="sdpa", local_files_only=True)
    for request in requests:
        out = Path(request["out"])
        if out.is_file():
            continue
        wavs, rate = model.generate_custom_voice(text=request["text"], speaker=request["voice"],
                                                 language="English", instruct=request["style"])
        if wavs[0].size == 0:
            raise SystemExit("ERROR: Qwen TTS returned an empty take")
        # Publish a complete WAV even if two CLI calls synthesize the same take.
        with NamedTemporaryFile(dir=out.parent, suffix=".wav", delete=False) as file:
            temp = Path(file.name)
        try:
            sf.write(temp, wavs[0], rate, subtype="PCM_16")
            try:
                if os.name == "nt":
                    temp.rename(out)  # Windows rename fails if the destination exists.
                else:
                    os.link(temp, out)
            except FileExistsError:
                pass  # Keep the first take and the word timings derived from it.
        finally:
            temp.unlink(missing_ok=True)


if __name__ == "__main__":
    _run(json.load(sys.stdin))
