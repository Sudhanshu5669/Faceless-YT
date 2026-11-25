"""Blender (5.x) helper: make an imported rigged character usable by TownForge's retargeting.

    blender -b --python pipeline/blender/tpose_character.py -- IN.gltf OUT.glb HEIGHT \
        "L UpperArm,L ForeArm,L Hand" "R UpperArm,R ForeArm,R Hand" "L Toe0,R Toe0" "Head" [ARMATURE_OBJECT]

Env TF_STRIP_BONE_SUFFIX=1: strip Sketchfab's per-node "_NN" suffix from bone names (rig map "gta_ped_clean").
ARMATURE_OBJECT (optional): when the file holds several characters, the armature object to keep (the others and
their meshes are deleted first).

Keeps the import's own hierarchy (skinned meshes stay bound to their armature) and:
- turns the whole model about Z so it faces -Y in Blender (glTF +Z, the engine's front), judged from the toes;
- scales it so the top of the head is HEIGHT metres above the soles (from bone positions), soles at z 0;
- rotates each arm chain (bone-name fragments, shoulder first) to point straight out sideways, bakes that pose into
  the meshes and applies it as the rest pose: an A-pose rig becomes a T-pose rig;
- exports a GLB (textures embedded, no animations).
"""
import math
import os
import re
import sys

import bpy
from mathutils import Matrix, Vector

args = sys.argv[sys.argv.index("--") + 1:]
src, dst, height = args[0], args[1], float(args[2])
arm_l = [s.strip() for s in args[3].split(",")]
arm_r = [s.strip() for s in args[4].split(",")]
toes = [s.strip() for s in args[5].split(",")]
head_frag = args[6] if len(args) > 6 else "Head"
pick = args[7] if len(args) > 7 else ""   # several characters in one file: the armature object to keep

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
if pick:
    # Keep one armature and the meshes it deforms; delete the rest of the cast (VLTXD's witches: three in one file).
    keep_arm = bpy.data.objects[pick]
    for o in list(bpy.data.objects):
        other_arm = o.type == "ARMATURE" and o != keep_arm
        other_mesh = o.type == "MESH" and not any(m.type == "ARMATURE" and m.object == keep_arm for m in o.modifiers)
        if other_arm or other_mesh:
            bpy.data.objects.remove(o, do_unlink=True)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
root = arm
while root.parent is not None:
    root = root.parent


def bone(fragment):
    for b in arm.pose.bones:
        if fragment.lower() in b.name.lower():
            return b.name
    raise SystemExit(f"no bone matching {fragment!r}")


def wh(name):
    bpy.context.view_layer.update()
    return arm.matrix_world @ arm.pose.bones[name].head


def wt(name):
    bpy.context.view_layer.update()
    return arm.matrix_world @ arm.pose.bones[name].tail


def transform_root(m):
    root.matrix_world = m @ root.matrix_world
    bpy.context.view_layer.update()


head = bone(head_frag)
pelvis = bone("Pelvis")
toe_l, toe_r = bone(toes[0]), bone(toes[1])
# Face -Y: the toes point forward from the pelvis.
fwd = (wh(toe_l) + wh(toe_r)) * 0.5 - wh(pelvis)
fwd.z = 0.0
ang = math.atan2(fwd.x, -fwd.y)   # angle from -Y
transform_root(Matrix.Rotation(-ang, 4, "Z") if abs(ang) > 1e-4 else Matrix.Identity(4))
# Scale and put the soles on z 0: head top ~ the head bone's tail (or head + 0.12 of the body).
sole = min(wh(toe_l).z, wh(toe_r).z)
top = max(wt(head).z, wh(head).z + 0.07 * (wh(head).z - sole))
s = height / max(top - sole, 1e-6)
c = wh(pelvis)
transform_root(Matrix.Translation(Vector((0, 0, 0))) @ Matrix.Scale(s, 4))
sole = min(wh(toe_l).z, wh(toe_r).z)
c = wh(pelvis)
transform_root(Matrix.Translation(Vector((-c.x, -c.y, -sole))))

# Arms straight out sideways.
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="POSE")
for chain in (arm_l, arm_r):
    names = [bone(f) for f in chain]
    side = 1.0 if wh(names[0]).x > wh(pelvis).x else -1.0
    out = Vector((side, 0.0, 0.0))
    for i, n in enumerate(names[:-1]):
        pb = arm.pose.bones[n]
        cur = (wh(names[i + 1]) - wh(n)).normalized()
        q = cur.rotation_difference(out)
        mw = arm.matrix_world @ pb.matrix
        loc = mw.to_translation()
        new = Matrix.Translation(loc) @ q.to_matrix().to_4x4() @ Matrix.Translation(-loc) @ mw
        pb.matrix = arm.matrix_world.inverted() @ new
        bpy.context.view_layer.update()
bpy.ops.object.mode_set(mode="OBJECT")

# Bake the pose into the meshes and make it the rest pose.
for o in meshes:
    mod = next((md for md in o.modifiers if md.type == "ARMATURE"), None)
    if mod is None:
        continue
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.modifier_apply(modifier=mod.name)
    nm = o.modifiers.new(name="Armature", type="ARMATURE")
    nm.object = arm
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="POSE")
bpy.ops.pose.armature_apply(selected=False)
bpy.ops.object.mode_set(mode="OBJECT")

for n in [pelvis, head, toe_l, bone(arm_l[0]), bone(arm_l[1]), bone(arm_l[2]), bone(arm_r[0]), bone(arm_r[2])]:
    print("BONE", n, tuple(round(v, 3) for v in wh(n)))
if os.environ.get("TF_STRIP_BONE_SUFFIX") == "1":
    # Sketchfab numbers every node ("_03", "_045"...), differently per character in one file; strip it so one rig map
    # fits them all (renaming through the API also renames the meshes' vertex groups).
    for b_ in arm.data.bones:
        clean = re.sub(r"_\d+$", "", b_.name)
        if clean != b_.name and clean not in arm.data.bones:
            b_.name = clean
    print("BONES", sorted(b_.name for b_ in arm.data.bones))
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_animations=False)
print("EXPORTED", dst)
