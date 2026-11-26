#!/usr/bin/env python3
"""Turn a Kimodo motion (SOMA skeleton, .npz) into library/motions/<name>.json, which cast.gd plays on any actor.

  python pipeline/import_motion.py E:/AgentTools/kimodo/test_out/walk_wave.npz walk_wave --prompt "..."

Then add an action in library/actions.json: {"anim": "mocap_<name>", "loop": false}.
Kimodo's rest pose is a T-pose facing +Z with identity rotations, so each joint's global rotation is already its
rotation away from rest; the engine applies it to the mannequin (godot/scripts/actors/mocap.gd).
"""
import argparse
import json
from pathlib import Path

import numpy as np
from scipy.spatial.transform import Rotation

ROOT = Path(__file__).resolve().parents[1]

# somaskel77 joint order (kimodo/skeleton/definitions.py), only the indices used here.
JOINTS = {"Hips": 0, "Spine1": 1, "Spine2": 2, "Chest": 3, "Neck1": 4, "Neck2": 5, "Head": 6,
          "LeftShoulder": 11, "LeftArm": 12, "LeftForeArm": 13, "LeftHand": 14}
LEFT_HAND_JOINTS = 25  # LeftHand .. LeftHandPinkyEnd; the right arm and the legs follow


def _indices() -> dict:
    out = dict(JOINTS)
    right = JOINTS["LeftHand"] + LEFT_HAND_JOINTS
    for i, name in enumerate(["RightShoulder", "RightArm", "RightForeArm", "RightHand"]):
        out[name] = right + i
    legs = out["RightHand"] + LEFT_HAND_JOINTS
    for i, name in enumerate(["LeftLeg", "LeftShin", "LeftFoot", "LeftToeBase", "LeftToeEnd",
                              "RightLeg", "RightShin", "RightFoot", "RightToeBase", "RightToeEnd"]):
        out[name] = legs + i
    return out


# mannequin bone -> SOMA joint
BONES = {"pelvis": "Hips", "spine_01": "Spine1", "spine_02": "Spine2", "spine_03": "Chest",
         "neck_01": "Neck1", "Head": "Head"}
# limb bones whose rest direction is aligned: mannequin bone -> (SOMA joint, SOMA child joint)
LIMBS = {}
for side, word in (("l", "Left"), ("r", "Right")):
    BONES.update({f"clavicle_{side}": f"{word}Shoulder", f"upperarm_{side}": f"{word}Arm",
                  f"lowerarm_{side}": f"{word}ForeArm", f"hand_{side}": f"{word}Hand",
                  f"thigh_{side}": f"{word}Leg", f"calf_{side}": f"{word}Shin",
                  f"foot_{side}": f"{word}Foot", f"ball_{side}": f"{word}ToeBase"})
    LIMBS.update({f"upperarm_{side}": (f"{word}Arm", f"{word}ForeArm"),
                  f"lowerarm_{side}": (f"{word}ForeArm", f"{word}Hand"),
                  f"thigh_{side}": (f"{word}Leg", f"{word}Shin"),
                  f"calf_{side}": (f"{word}Shin", f"{word}Foot")})


def convert(npz_path: Path, name: str, prompt: str, model: str, fps: float) -> dict:
    data = np.load(npz_path)
    rot = data["global_rot_mats"].astype(float)
    pos = data["posed_joints"].astype(float)
    if rot.ndim != 4 or rot.shape[1] != 77:
        raise SystemExit(f"expected one somaskel77 motion (frames x 77 x 3 x 3), got {rot.shape}")
    index = _indices()

    def rest_offset(parent: str, child: str) -> np.ndarray:
        # forward kinematics: P_child - P_parent = G_parent @ rest_offset
        i, c = index[parent], index[child]
        return rot[0, i].T @ (pos[0, c] - pos[0, i])

    leg = ["Hips", "LeftLeg", "LeftShin", "LeftFoot", "LeftToeBase", "LeftToeEnd"]
    hip_height = -sum(rest_offset(a, b)[1] for a, b in zip(leg, leg[1:]))
    rest_dir = {}
    for bone, (joint, child) in LIMBS.items():
        v = rest_offset(joint, child)
        rest_dir[bone] = [round(float(x), 6) for x in v / np.linalg.norm(v)]
    if rest_dir["upperarm_l"][0] < 0.9 or rest_dir["thigh_l"][1] > -0.9:
        raise SystemExit(f"rest pose is not the expected T-pose: {rest_dir}")

    frames = {}
    for bone, joint in BONES.items():
        q = Rotation.from_matrix(rot[:, index[joint]]).as_quat()  # x, y, z, w
        for i in range(1, len(q)):  # keep neighbouring keys in one hemisphere
            if np.dot(q[i - 1], q[i]) < 0:
                q[i] = -q[i]
        frames[bone] = np.round(q, 6).tolist()
    hips = pos[:, index["Hips"]].copy()
    hips[:, [0, 2]] -= hips[0, [0, 2]]  # the actor's spot is where the motion starts
    return {"name": name, "source": "Kimodo", "model": model, "prompt": prompt, "fps": fps,
            "hip_height": round(float(hip_height), 6), "rest_dir": rest_dir,
            "hips": np.round(hips, 6).tolist(), "rotations": frames}


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("npz", type=Path)
    ap.add_argument("name")
    ap.add_argument("--prompt", default="")
    ap.add_argument("--model", default="nvidia/Kimodo-SOMA-RP-v1.2")
    ap.add_argument("--fps", type=float, default=30.0)
    args = ap.parse_args()
    out = ROOT / "library" / "motions" / f"{args.name}.json"
    if out.exists():
        raise SystemExit(f"{out} exists; delete it first or choose another name")
    clip = convert(args.npz, args.name, args.prompt, args.model, args.fps)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(clip, separators=(",", ":")), encoding="utf-8")
    print(f"{out}: {len(clip['hips'])} frames, hip height {clip['hip_height']:.3f} m, "
          f"travel {np.linalg.norm(np.array(clip['hips'][-1])[[0, 2]]):.2f} m")


if __name__ == "__main__":
    main()
