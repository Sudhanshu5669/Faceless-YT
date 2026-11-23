"""Blender asset script: an Indian Air Force Antonov An-32 for the Pokhran episode (run headless; glTF out for Godot).

    "E:/Program Files/Blender/blender.exe" -b --factory-startup --python episodes/pokhran/blender/aircraft.py -- OUT_DIR

Writes into OUT_DIR (default incoming/pokhran_blender/):
  an32.glb   the An-32 twin turboprop transport: a round fuselage with a glazed navigator's nose and a stepped cockpit,
             a HIGH wing with the two engines mounted ABOVE it (the An-32's signature, for hot-and-high fields), big
             four-blade propellers (objects "prop_l" / "prop_r", origin at the hub, spin about local X), the main
             wheels in the nacelles, the upswept rear fuselage with the cargo ramp (object "ramp", hinged at its front
             edge), a tall fin with a long dorsal fillet, the tailplane with dihedral, ventral strakes. IAF light grey,
             roundels on the wings and fuselage, the tricolour fin flash. 23.8 m long, 29.2 m span, 8.75 m high.
Forward is +X, up +Z (glTF keeps +X forward; Z up becomes Y up). Materials (override by name in Godot): skin, skin_dark,
glass, prop, metal, tyre, roundel_saffron, roundel_white, roundel_green, black.
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


def loft(name, sections, material, segs=32, cap=True):
    """A body of revolution-ish loft: sections = [(x, z_centre, half_width_y, half_height_z, squareness)]."""
    bm = bmesh.new()
    rings = []
    for x, zc, ry, rz, sq in sections:
        ring = []
        for i in range(segs):
            a = 2 * math.pi * i / segs
            c, s = math.cos(a), math.sin(a)
            e = 2.0 / (2.0 + sq)
            cy = math.copysign(abs(c) ** e, c)
            sz = math.copysign(abs(s) ** e, s)
            ring.append(bm.verts.new((x, ry * cy, zc + rz * sz)))
        rings.append(ring)
    for r0, r1 in zip(rings, rings[1:]):
        for i in range(segs):
            bm.faces.new((r0[i], r0[(i + 1) % segs], r1[(i + 1) % segs], r1[i]))
    if cap:
        for ring, rev in ((rings[0], True), (rings[-1], False)):
            c = bm.verts.new(sum((v.co for v in ring), Vector()) / len(ring))
            for i in range(segs):
                f = (ring[i], ring[(i + 1) % segs], c)
                bm.faces.new(f[::-1] if rev else f)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj(name, bm, material)


def wing_panel(name, root, tip, chord_r, chord_t, thick, sweep, dihedral_z, material):
    """A tapered wing panel from y=root to y=tip (signed), leading edge swept back by `sweep` metres at the tip."""
    bm = bmesh.new()
    prof = []
    n = 12
    for i in range(n):
        u = i / (n - 1)
        # A cambered aerofoil: thick at a quarter chord, sharp trailing edge.
        t = thick * 5.0 * (0.2969 * math.sqrt(u) - 0.126 * u - 0.3516 * u * u + 0.2843 * u ** 3 - 0.1036 * u ** 4)
        prof.append((u, t))
    secs = []
    for y, c, dx, dz in ((root[0], chord_r, root[1], root[2]), (tip[0], chord_t, tip[1], tip[2])):
        top = [bm.verts.new((dx - u * c, y, dz + t * c * 0.55)) for u, t in prof]
        bot = [bm.verts.new((dx - u * c, y, dz - t * c * 0.45)) for u, t in prof]
        secs.append((top, bot))
    (t0, b0), (t1, b1) = secs
    for i in range(n - 1):
        bm.faces.new((t0[i], t0[i + 1], t1[i + 1], t1[i]))
        bm.faces.new((b0[i + 1], b0[i], b1[i], b1[i + 1]))
    for top, bot, rev in ((t0, b0, False), (t1, b1, True)):
        ring = top + bot[::-1]
        f = bm.faces.new(ring[::-1] if rev else ring)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj(name, bm, material)


def cyl(name, r, depth, at, material, axis="X", segs=24, r2=None):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=r, radius2=r if r2 is None else r2, depth=depth)
    ob = obj(name, bm, material)
    ob.location = at
    ob.rotation_euler = {"X": (0, math.pi / 2, 0), "Y": (math.pi / 2, 0, 0), "Z": (0, 0, 0)}[axis]
    return ob


def disc(name, r, at, normal_axis, material, segs=40):
    """A flat disc (roundel ring), facing +/- along an axis."""
    bm = bmesh.new()
    bmesh.ops.create_circle(bm, cap_ends=True, segments=segs, radius=r)
    ob = obj(name, bm, material, smooth=False)
    ob.location = at
    ob.rotation_euler = {"Z": (0, 0, 0), "Y": (math.pi / 2, 0, 0), "-Y": (-math.pi / 2, 0, 0)}[normal_axis]
    return ob


def roundel(prefix, at, r, axis):
    # Concentric saffron, white, green (each a slightly raised disc so they stack).
    off = {"Z": Vector((0, 0, 0.006)), "Y": Vector((0, -0.006, 0)), "-Y": Vector((0, 0.006, 0))}[axis]
    disc(prefix + "_s", r, Vector(at), axis, mat("roundel_saffron", (0.93, 0.45, 0.12), 0.45))
    disc(prefix + "_w", r * 0.66, Vector(at) + off, axis, mat("roundel_white", (0.92, 0.92, 0.9), 0.45))
    disc(prefix + "_g", r * 0.33, Vector(at) + off * 2, axis, mat("roundel_green", (0.07, 0.42, 0.18), 0.45))


def an32():
    clear()
    skin = mat("skin", (0.58, 0.6, 0.62), 0.42, 0.15)
    dark = mat("skin_dark", (0.34, 0.35, 0.37), 0.5, 0.15)
    glass = mat("glass", (0.03, 0.05, 0.07), 0.05, 0.3)
    metal = mat("metal", (0.35, 0.35, 0.36), 0.35, 0.8)
    black = mat("black", (0.03, 0.03, 0.03), 0.6)
    tyre = mat("tyre", (0.035, 0.034, 0.032), 0.9)
    prop = mat("prop", (0.05, 0.05, 0.05), 0.5)
    # Fuselage: nose at +X 11.9, tail at -11.9. Round, 2.9 m wide; the rear sweeps up to the tail.
    R = 1.45
    secs = [
        (11.9, 1.95, 0.05, 0.05, 0.0), (11.7, 1.95, 0.45, 0.42, 0.0), (11.2, 2.0, 0.9, 0.85, 0.0),
        (10.4, 2.1, 1.22, 1.2, 0.0), (9.4, 2.2, 1.4, 1.42, 0.2), (8.2, 2.25, R, R, 0.3),
        (2.0, 2.25, R, R, 0.3), (-4.0, 2.25, R, R, 0.3), (-6.0, 2.45, R * 0.97, 1.3, 0.3),
        (-8.0, 2.95, R * 0.8, 1.0, 0.2), (-10.0, 3.55, R * 0.5, 0.62, 0.1), (-11.9, 4.1, 0.16, 0.2, 0.0),
    ]
    loft("fuselage", secs, skin, 36)
    # The glazed navigator's nose and the stepped cockpit windows.
    for i in range(6):
        a = -0.7 + 0.28 * i
        cyl(f"nose_glass{i}", 0.17, 0.05, (11.45, math.sin(a) * 0.62, 1.78 + math.cos(a) * 0.1), glass, "X", 12)
    for side in (-1, 1):
        for i in range(3):
            b = bmesh.new()
            bmesh.ops.create_cube(b, size=1.0)
            bmesh.ops.scale(b, vec=Vector((0.48, 0.05, 0.36)), verts=b.verts)
            w = obj(f"cockpit_win{side}{i}", b, glass, smooth=False)
            w.location = (10.2 - 0.52 * i, side * (1.06 + 0.1 * i), 2.95 - 0.05 * i)
            w.rotation_euler = (side * 0.5, 0, 0)
        for i in range(8):
            cyl(f"porthole{side}{i}", 0.16, 0.06, (6.5 - 1.4 * i, side * 1.44, 2.45), glass, "Y", 16)
    # Wing: high on the fuselage top; 29.2 m span; centre section and tapered outer panels with dihedral on the outers.
    wz = 3.55
    wing_panel("wing_c", (-4.2, 1.6, wz), (4.2, 1.6, wz), 3.6, 3.4, 0.16, 0.0, 0.0, skin)
    for side in (-1, 1):
        wing_panel(f"wing_o{side}", (side * 4.2, 1.6, wz), (side * 14.6, 0.9, wz + 0.55), 3.4, 1.5, 0.12, 0.0, 0.0, skin)
    # The engines: nacelles mounted ABOVE the wing at y = +/-3.9; long, with the main gear bays below the wing.
    for side, nm in ((-1, "r"), (1, "l")):
        y = side * 3.95
        nac = [(4.4, wz + 0.55, 0.05, 0.05, 0.0), (4.2, wz + 0.55, 0.5, 0.55, 0.0), (3.4, wz + 0.6, 0.72, 0.78, 0.2),
               (0.5, wz + 0.55, 0.7, 0.72, 0.3), (-1.8, wz + 0.4, 0.45, 0.45, 0.2), (-2.8, wz + 0.3, 0.1, 0.1, 0.0)]
        n = loft(f"nacelle_{nm}", nac, skin, 24)
        n.location.y = y
        intake = cyl(f"intake_{nm}", 0.2, 0.3, (3.9, y, wz + 1.25), dark, "X", 16)
        gear = loft(f"gearpod_{nm}", [(2.2, wz - 0.4, 0.05, 0.05, 0), (1.8, wz - 0.45, 0.42, 0.42, 0.2),
                                       (-1.4, wz - 0.45, 0.42, 0.4, 0.2), (-2.6, wz - 0.35, 0.05, 0.05, 0)], dark, 16)
        gear.location.y = y
        # Main wheels (twin) under the pod, on a strut.
        cyl(f"strut_{nm}", 0.09, 2.2, (0.3, y, wz - 1.55), metal, "Z", 10)
        for k in (-1, 1):
            t = cyl(f"wheel_{nm}{k}", 0.52, 0.32, (0.3, y + k * 0.25, 1.0), tyre, "Y", 24)
        # The propeller: spinner + four broad blades; its own object with the origin at the hub.
        hub = Vector((4.62, y, wz + 0.58))
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=20, radius1=0.42, radius2=0.02, depth=0.8,
                              matrix=Matrix.Translation((0.4, 0, 0)) @ Matrix.Rotation(math.pi / 2, 4, "Y"))
        for k in range(4):
            a = math.pi / 2 * k + 0.4
            for v in bmesh.ops.create_cube(bm, size=1.0)["verts"]:
                co = Vector((v.co.x * 0.08, v.co.y * 0.32, v.co.z * 1.95 + 1.0))
                co = Matrix.Rotation(0.35, 3, "Z") @ co
                v.co = Matrix.Rotation(a, 3, "X") @ co
        p = obj(f"prop_{nm}", bm, prop, smooth=False)
        p.location = hub
    # Tail: the upswept rear with the cargo ramp (its own object, hinged at the front edge), the fin with a long
    # dorsal fillet, the tailplane with dihedral, two ventral strakes.
    b = bmesh.new()
    bmesh.ops.create_cube(b, size=1.0)
    bmesh.ops.scale(b, vec=Vector((4.4, 2.1, 0.12)), verts=b.verts)
    for v in b.verts:
        v.co.x -= 2.2
    ramp = obj("ramp", b, dark, smooth=False)
    ramp.location = (-4.2, 0, 1.0)
    ramp.rotation_euler = (0, -0.21, 0)
    fin = bmesh.new()
    pts = [(-8.0, 3.7), (-11.6, 4.0), (-12.0, 8.75), (-10.2, 8.75), (-8.8, 4.6)]
    vs = [fin.verts.new((x, -0.14, z)) for x, z in pts] + [fin.verts.new((x, 0.14, z)) for x, z in pts]
    n = len(pts)
    fin.faces.new(vs[:n][::-1])
    fin.faces.new(vs[n:])
    for i in range(n):
        fin.faces.new((vs[i], vs[(i + 1) % n], vs[n + (i + 1) % n], vs[n + i]))
    obj("fin", fin, skin, smooth=False)
    dors = bmesh.new()
    pts = [(-3.5, 3.6), (-9.0, 4.6), (-8.0, 3.7)]
    vs = [dors.verts.new((x, -0.1, z)) for x, z in pts] + [dors.verts.new((x, 0.1, z)) for x, z in pts]
    dors.faces.new(vs[:3][::-1])
    dors.faces.new(vs[3:])
    for i in range(3):
        dors.faces.new((vs[i], vs[(i + 1) % 3], vs[3 + (i + 1) % 3], vs[3 + i]))
    obj("dorsal", dors, skin, smooth=False)
    for side in (-1, 1):
        wing_panel(f"tailplane{side}", (side * 0.2, -9.9, 4.2), (side * 5.0, -11.0, 4.55), 2.6, 1.3, 0.1, 0.0, 0.0, skin)
        b = bmesh.new()
        bmesh.ops.create_cube(b, size=1.0)
        bmesh.ops.scale(b, vec=Vector((2.6, 0.08, 0.7)), verts=b.verts)
        s = obj(f"strake{side}", b, skin, smooth=False)
        s.location = (-7.6, side * 0.7, 1.65)
        s.rotation_euler = (side * 0.45, -0.28, 0)
    # Nose gear.
    cyl("nose_strut", 0.07, 1.3, (9.6, 0, 0.95), metal, "Z", 10)
    for k in (-1, 1):
        cyl(f"nose_wheel{k}", 0.34, 0.22, (9.6, k * 0.15, 0.36), tyre, "Y", 20)
    # Markings: roundels on the outer wings (top) and the rear fuselage sides; the tricolour fin flash.
    for side in (-1, 1):
        roundel(f"rw{side}", (0.6, side * 10.5, wz + 0.47), 0.75, "Z")
        roundel(f"rf{side}", (-3.2, side * 1.47, 2.35), 0.62, "Y" if side < 0 else "-Y")
    for i, (cname, rgb) in enumerate((("roundel_saffron", (0.93, 0.45, 0.12)), ("roundel_white", (0.92, 0.92, 0.9)), ("roundel_green", (0.07, 0.42, 0.18)))):
        for side in (-1, 1):
            b = bmesh.new()
            bmesh.ops.create_cube(b, size=1.0)
            bmesh.ops.scale(b, vec=Vector((1.2, 0.02, 0.32)), verts=b.verts)
            f = obj(f"flash{i}{side}", b, mat(cname, rgb, 0.45), smooth=False)
            f.location = (-11.0, side * 0.15, 7.4 - 0.34 * i)
    export("an32")


def export(name):
    path = str(OUT / f"{name}.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True)
    print("wrote", path)


if __name__ == "__main__":
    an32()
