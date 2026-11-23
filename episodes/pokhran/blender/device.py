"""Blender asset script: the nuclear device for the Pokhran episode (an ORIGINAL stylised design: the real Shakti devices
have never been shown). Run headless; glTF out for Godot.

    "E:/Program Files/Blender/blender.exe" -b --factory-startup --python episodes/pokhran/blender/device.py -- OUT_DIR

Writes into OUT_DIR (default incoming/pokhran_blender/):
  device.glb   a two-stage silhouette: a bulbous primary sphere, a ribbed interstage and a long secondary cylinder, in
               dark satin steel with machined bright bands and bolt flanges; a cable harness from a connector box with
               red-capped plugs; a yellow-black hazard band; small indicator lamps (material "indicator", make it glow
               in Godot); a flat "label_plate" on the secondary (stickers go there); on a steel cradle (two saddles on a
               pallet with tie-down rings) for strapping in the plane and the truck. 2.2 m long, axis along +X, sitting
               on the cradle with its base at z 0.
Materials (override by name in Godot): body, band, bolt, cable, plug, hazard, indicator, plate, cradle, pallet.
Deterministic.
"""
import math
import sys
from pathlib import Path

import bpy
import bmesh
from mathutils import Matrix, Vector

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
REPO = Path(__file__).resolve().parents[3]
OUT = Path(ARGS[0]) if ARGS else REPO / "incoming" / "pokhran_blender"
OUT.mkdir(parents=True, exist_ok=True)
MATS = {}


def clear():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials):
        for d in list(coll):
            coll.remove(d)
    MATS.clear()


def mat(name, rgb, rough=0.5, metal=0.0):
    if name in MATS:
        return MATS[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*rgb, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    MATS[name] = m
    return m


def obj(name, bm, material, smooth=True):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    ob.data.materials.append(material)
    for p in ob.data.polygons:
        p.use_smooth = smooth
    return ob


def lathe(name, profile, material, segs=48, x0=0.0):
    """Revolve [(x, r), ...] about the X axis."""
    bm = bmesh.new()
    rings = []
    for x, r in profile:
        rings.append([bm.verts.new((x0 + x, r * math.cos(2 * math.pi * i / segs), r * math.sin(2 * math.pi * i / segs)))
                      for i in range(segs)])
    for a, b in zip(rings, rings[1:]):
        for i in range(segs):
            bm.faces.new((a[i], a[(i + 1) % segs], b[(i + 1) % segs], b[i]))
    for ring, rev in ((rings[0], True), (rings[-1], False)):
        if ring[0].co.yz.length > 1e-4:
            c = bm.verts.new(sum((v.co for v in ring), Vector()) / len(ring))
            for i in range(segs):
                f = (ring[i], ring[(i + 1) % segs], c)
                bm.faces.new(f[::-1] if rev else f)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj(name, bm, material)


def box(name, size, at, material, rot=(0, 0, 0), smooth=False):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
    ob = obj(name, bm, material, smooth)
    ob.location = at
    ob.rotation_euler = rot
    return ob


def tube(name, pts, r, material, segs=8):
    """A cable through points."""
    bm = bmesh.new()
    rings = []
    for i, p in enumerate(pts):
        p = Vector(p)
        d = (Vector(pts[min(i + 1, len(pts) - 1)]) - Vector(pts[max(i - 1, 0)])).normalized()
        u = d.orthogonal().normalized()
        v = d.cross(u)
        rings.append([bm.verts.new(p + (u * math.cos(2 * math.pi * k / segs) + v * math.sin(2 * math.pi * k / segs)) * r)
                      for k in range(segs)])
    for a, b in zip(rings, rings[1:]):
        for k in range(segs):
            bm.faces.new((a[k], a[(k + 1) % segs], b[(k + 1) % segs], b[k]))
    return obj(name, bm, material)


def device():
    clear()
    body = mat("body", (0.1, 0.11, 0.12), 0.32, 0.85)
    band = mat("band", (0.62, 0.63, 0.65), 0.18, 1.0)
    bolt = mat("bolt", (0.45, 0.46, 0.48), 0.3, 1.0)
    cable = mat("cable", (0.04, 0.04, 0.045), 0.6)
    plug = mat("plug", (0.7, 0.06, 0.04), 0.45)
    hazard = mat("hazard", (0.9, 0.7, 0.05), 0.5)
    lamp = mat("indicator", (0.1, 0.9, 0.3), 0.3)
    plate = mat("plate", (0.75, 0.75, 0.72), 0.4, 0.6)
    cradle = mat("cradle", (0.2, 0.22, 0.16), 0.6, 0.4)
    pallet = mat("pallet", (0.3, 0.27, 0.2), 0.8)
    zc = 0.62           # the axis height above the pallet's base
    # The casing: primary sphere (x -1.1..-0.35), a ribbed interstage, the secondary cylinder to a domed nose.
    prof = [(-1.12, 0.0), (-1.1, 0.12), (-1.04, 0.25), (-0.94, 0.34), (-0.8, 0.39), (-0.62, 0.4), (-0.46, 0.37),
            (-0.36, 0.31), (-0.3, 0.29)]
    for k in range(5):
        x = -0.28 + 0.06 * k
        prof += [(x, 0.29), (x + 0.02, 0.31), (x + 0.04, 0.31), (x + 0.05, 0.29)]
    prof += [(0.02, 0.3), (0.06, 0.33), (0.9, 0.33), (0.98, 0.31), (1.04, 0.26), (1.08, 0.17), (1.1, 0.06), (1.105, 0.0)]
    cas = lathe("casing", prof, body, 64)
    cas.location.z = zc
    # Machined bands and bolt flanges at the joints.
    for x, r in ((-0.36, 0.325), (0.04, 0.345), (0.5, 0.345), (0.92, 0.335), (-0.62, 0.41)):
        b = lathe(f"band{x}", [(x - 0.025, r - 0.01), (x - 0.02, r), (x + 0.02, r), (x + 0.025, r - 0.01)], band, 64)
        b.location.z = zc
    for x, r in ((0.04, 0.35), (-0.36, 0.33)):
        for k in range(18):
            a = 2 * math.pi * k / 18
            bb = bmesh.new()
            bmesh.ops.create_cone(bb, cap_ends=True, segments=6, radius1=0.014, radius2=0.014, depth=0.03)
            o = obj(f"bolt{x}_{k}", bb, bolt, False)
            o.location = (x, math.cos(a) * r, zc + math.sin(a) * r)
            o.rotation_euler = (0, math.pi / 2, 0)
    # The hazard band (stripes are drawn in Godot) round the secondary near the interstage.
    hz = lathe("hazard_band", [(0.12, 0.334), (0.13, 0.336), (0.3, 0.336), (0.31, 0.334)], hazard, 64)
    hz.location.z = zc
    # The label plate on top of the secondary (stickers go here), with four screws.
    box("label_plate", (0.5, 0.36, 0.008), (0.62, 0, zc + 0.333), plate)
    for sx in (-1, 1):
        for sy in (-1, 1):
            box(f"screw{sx}{sy}", (0.016, 0.016, 0.012), (0.62 + sx * 0.23, sy * 0.16, zc + 0.338), bolt)
    # The connector box on the primary's flank, red-capped plugs, a cable harness running aft along the body.
    box("conn_box", (0.22, 0.12, 0.16), (-0.7, -0.4, zc + 0.12), body, (0.3, 0, 0))
    for k in range(4):
        c = box(f"plug{k}", (0.04, 0.05, 0.04), (-0.78 + 0.05 * k, -0.47, zc + 0.16), plug)
    for k, (dy, dz) in enumerate(((-0.33, 0.12), (-0.31, 0.18), (-0.335, 0.05))):
        pts = [(-0.74 + 0.05 * k, -0.47, zc + 0.15)]
        for i in range(10):
            x = -0.6 + 0.16 * i
            r = 0.36 if x < -0.35 else 0.315
            ang = math.atan2(dz, dy) + 0.02 * k
            pts.append((x, math.cos(ang) * (r + 0.015 + 0.008 * k), zc + math.sin(ang) * (r + 0.015 + 0.008 * k)))
        tube(f"cable{k}", pts, 0.012, cable)
    for k in range(3):
        lp = bmesh.new()
        bmesh.ops.create_uvsphere(lp, u_segments=10, v_segments=6, radius=0.012)
        o = obj(f"lamp{k}", lp, lamp)
        o.location = (-0.66 + 0.05 * k, -0.465, zc + 0.24)
    # Lifting lugs on top.
    for x in (-0.62, 0.5):
        t = bmesh.new()
        bmesh.ops.create_cone(t, cap_ends=True, segments=16, radius1=0.05, radius2=0.05, depth=0.03)
        o = obj(f"lug{x}", t, band)
        o.location = (x, 0, zc + 0.43 if x < 0 else zc + 0.37)
        o.rotation_euler = (math.pi / 2, 0, 0)
    # The cradle: two curved saddles on a steel pallet with tie-down rings at the corners.
    box("pallet", (2.3, 0.95, 0.1), (0, 0, 0.05), pallet)
    for x in (-0.62, 0.55):
        sad = bmesh.new()
        segs = 16
        inner, outer = [], []
        for i in range(segs + 1):
            a = math.pi * (1.15 + 0.7 * i / segs)
            r = 0.42 if x < 0 else 0.36
            inner.append(sad.verts.new((x - 0.05, math.cos(a) * r, zc + math.sin(a) * r)))
            outer.append(sad.verts.new((x + 0.05, math.cos(a) * r, zc + math.sin(a) * r)))
        base_i = [sad.verts.new((x - 0.05, inner[-1].co.y, 0.1)), sad.verts.new((x - 0.05, inner[0].co.y, 0.1))]
        base_o = [sad.verts.new((x + 0.05, outer[-1].co.y, 0.1)), sad.verts.new((x + 0.05, outer[0].co.y, 0.1))]
        ring_i = inner + base_i
        ring_o = outer + base_o
        sad.faces.new(ring_i[::-1])
        sad.faces.new(ring_o)
        n = len(ring_i)
        for i in range(n):
            sad.faces.new((ring_i[i], ring_i[(i + 1) % n], ring_o[(i + 1) % n], ring_o[i]))
        bmesh.ops.recalc_face_normals(sad, faces=sad.faces)
        obj(f"saddle{x}", sad, cradle, False)
    for sx in (-1, 1):
        for sy in (-1, 1):
            t = bmesh.new()
            bmesh.ops.create_cone(t, cap_ends=True, segments=12, radius1=0.035, radius2=0.035, depth=0.015)
            o = obj(f"tiedown{sx}{sy}", t, band)
            o.location = (sx * 1.05, sy * 0.42, 0.11)
    export("device")


def export(name):
    path = str(OUT / f"{name}.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True)
    print("wrote", path)


if __name__ == "__main__":
    device()
