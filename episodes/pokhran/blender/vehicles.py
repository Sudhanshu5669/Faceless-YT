"""Blender asset script: Indian Army trucks for the Pokhran range (run headless; glTF out for Godot).

    "E:/Program Files/Blender/blender.exe" -b --factory-startup --python episodes/pokhran/blender/vehicles.py -- OUT_DIR

Writes into OUT_DIR (default incoming/pokhran_blender/):
  truck_canopy.glb    a 4x4 army cargo truck in the manner of the Shaktiman (the Indian Army's workhorse of the 1990s):
                      a short bonnet with a vertical-slat grille, round headlamps on the wings, a split windscreen,
                      big single tyres, a spare wheel behind the cab, a dropside cargo bed under a canvas canopy on
                      bows. 6.3 m long, 2.3 m wide, 3.0 m to the canopy top. Forward is +X (Blender) -> -Z in glTF? No:
                      the exporter's +Y-up conversion keeps Blender +X as glTF +X; forward = +X.
  truck_flat.glb      the same truck with an open bed (no canopy, no bows): the crane truck's chassis.
  jeep.glb            a light army 4x4 soft-top (generic, no make), 3.95 m long, right-hand drive.
Materials (override by name in Godot): paint, canvas, tyre, rim, glass, lamp, dark, wood.
Deterministic (no randomness).
"""
import math
import sys
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector, Matrix

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


def mat(name, rgb, rough=0.6, metal=0.0):
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


def link(ob, material, bevel=0.0, segs=2):
    bpy.context.scene.collection.objects.link(ob) if ob.name not in bpy.context.scene.collection.objects else None
    ob.data.materials.clear()
    ob.data.materials.append(material)
    if bevel > 0:
        md = ob.modifiers.new("bevel", "BEVEL")
        md.width = bevel
        md.segments = segs
        md.limit_method = "ANGLE"
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def box(name, size, at, material, bevel=0.02, rot=(0, 0, 0)):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.location = at
    ob.rotation_euler = rot
    bpy.context.scene.collection.objects.link(ob)
    return link(ob, material, bevel)


def cyl(name, r, depth, at, material, axis="Y", segs=32, bevel=0.0, r2=None):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=r, radius2=r if r2 is None else r2, depth=depth)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.location = at
    ob.rotation_euler = {"X": (0, math.pi / 2, 0), "Y": (math.pi / 2, 0, 0), "Z": (0, 0, 0)}[axis]
    bpy.context.scene.collection.objects.link(ob)
    return link(ob, material, bevel)


def torus(name, R, r, at, material, axis="Y"):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    segs, rsegs = 40, 14
    verts = []
    for i in range(segs):
        a = 2 * math.pi * i / segs
        ring = []
        for j in range(rsegs):
            b = 2 * math.pi * j / rsegs
            # A tyre: a squarer section than a torus (flat tread, bulging sidewalls).
            cb, sb = math.cos(b), math.sin(b)
            sq = (abs(cb) ** 0.55) * (1 if cb >= 0 else -1), (abs(sb) ** 0.7) * (1 if sb >= 0 else -1)
            rr = R + r * sq[0]
            ring.append(bm.verts.new((math.cos(a) * rr, math.sin(a) * rr, r * 1.25 * sq[1])))
        verts.append(ring)
    for i in range(segs):
        for j in range(rsegs):
            a = verts[i][j]
            b2 = verts[(i + 1) % segs][j]
            c = verts[(i + 1) % segs][(j + 1) % rsegs]
            d = verts[i][(j + 1) % rsegs]
            bm.faces.new((a, b2, c, d))
    # Tread lugs: shallow chevrons pushed out on the crown.
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.location = at
    ob.rotation_euler = (math.pi / 2, 0, 0) if axis == "Y" else (0, 0, 0)
    bpy.context.scene.collection.objects.link(ob)
    return link(ob, material)


def wheel(name, at, side):
    tyre = mat("tyre", (0.035, 0.034, 0.032), 0.92)
    rim = mat("rim", (0.2, 0.22, 0.13), 0.55)
    dark = mat("dark", (0.04, 0.04, 0.04), 0.6)
    R, r = 0.4, 0.15
    torus(name + "_tyre", R, r, at, tyre)
    cyl(name + "_rim", 0.29, 0.26, at, rim, "Y", 32, 0.01)
    cyl(name + "_hub", 0.1, 0.32, at, dark, "Y", 16, 0.01)
    for k in range(8):
        a = 2 * math.pi * k / 8
        cyl(f"{name}_lug{k}", 0.018, 0.34, (at[0] + math.cos(a) * 0.16, at[1], at[2] + math.sin(a) * 0.16), dark, "Y", 6)
    # Tread blocks across the crown.
    for k in range(28):
        a = 2 * math.pi * k / 28
        for s in (-1, 1):
            box(f"{name}_tread{k}_{s}", (0.09, 0.12, 0.035),
                (at[0] + math.cos(a) * (R + r + 0.004), at[1] + s * 0.07, at[2] + math.sin(a) * (R + r + 0.004)),
                tyre, 0.01, (0, -a + math.pi / 2, s * 0.35))


def truck(name, canopy=True):
    clear()
    paint = mat("paint", (0.22, 0.24, 0.13), 0.62)
    canvas = mat("canvas", (0.32, 0.31, 0.2), 0.95)
    glass = mat("glass", (0.03, 0.04, 0.045), 0.08, 0.4)
    lamp = mat("lamp", (0.85, 0.83, 0.75), 0.15, 0.6)
    dark = mat("dark", (0.04, 0.04, 0.04), 0.6)
    wood = mat("wood", (0.33, 0.24, 0.15), 0.85)
    W = 2.3
    # Wheels: front axle at x +2.05, rear at -1.85; track 1.9.
    for x, tag in ((2.05, "f"), (-1.85, "r")):
        for s in (-1, 1):
            wheel(f"w{tag}{'l' if s > 0 else 'r'}", (x, s * 0.95, 0.55), s)
    # Chassis rails and axles.
    for s in (-1, 1):
        box(f"rail{s}", (6.0, 0.12, 0.22), (0.1, s * 0.42, 0.78), dark, 0.01)
    for x in (2.05, -1.85):
        cyl(f"axle{x}", 0.07, 1.8, (x, 0, 0.55), dark, "Y", 12)
        box(f"diff{x}", (0.35, 0.35, 0.3), (x, 0, 0.55), dark, 0.05)
    # Front: bumper, bonnet with a sloped front, slat grille, wings over the wheels with round headlamps.
    box("bumper", (0.18, W * 0.98, 0.2), (3.16, 0, 0.72), paint, 0.03)
    for s in (-1, 1):
        box(f"hook{s}", (0.12, 0.06, 0.12), (3.28, s * 0.55, 0.7), dark, 0.02)
    box("bonnet", (0.95, 1.28, 0.62), (2.58, 0, 1.36), paint, 0.06)
    box("bonnet_top", (0.95, 1.2, 0.08), (2.55, 0, 1.69), paint, 0.03, (0, 0.06, 0))
    box("grille", (0.06, 1.12, 0.52), (3.07, 0, 1.3), dark, 0.01)
    for k in range(11):
        box(f"slat{k}", (0.05, 0.035, 0.5), (3.1, -0.5 + 0.1 * k, 1.3), paint, 0.006)
    for s in (-1, 1):
        # Wings: a curved shell over each front wheel, running back to the cab step.
        me = bpy.data.meshes.new(f"wing{s}")
        bm = bmesh.new()
        segs = 14
        prev = None
        for i in range(segs + 1):
            a = math.pi * (0.05 + 0.85 * i / segs)
            x = 2.05 + math.cos(a) * 0.68
            z = 0.55 + math.sin(a) * 0.68
            v0 = bm.verts.new((x, s * 0.72, z))
            v1 = bm.verts.new((x, s * 1.17, z))
            if prev:
                bm.faces.new((prev[0], prev[1], v1, v0))
            prev = (v0, v1)
        bm.to_mesh(me)
        bm.free()
        ob = bpy.data.objects.new(f"wing{s}", me)
        bpy.context.scene.collection.objects.link(ob)
        sol = ob.modifiers.new("thick", "SOLIDIFY")
        sol.thickness = 0.04
        link(ob, paint, 0.015)
        cyl(f"lampbody{s}", 0.13, 0.16, (2.82, s * 0.95, 1.33), paint, "X", 24, 0.02)
        cyl(f"lamp{s}", 0.105, 0.04, (2.91, s * 0.95, 1.33), lamp, "X", 24, 0.01)
        box(f"step{s}", (0.45, 0.32, 0.05), (1.6, s * 1.05, 0.72), dark, 0.01)
    # The cab: a box with a gently rounded roof, a split windscreen, door windows, mirrors on arms.
    box("cab", (1.45, W * 0.94, 1.32), (1.55, 0, 1.75), paint, 0.09)
    box("roof", (1.5, W * 0.92, 0.1), (1.53, 0, 2.43), paint, 0.05)
    for s in (-1, 1):
        box(f"wind{s}", (0.04, 0.95, 0.55), (2.27, s * 0.5, 2.02), glass, 0.01, (0, -0.12, 0))
        box(f"door_win{s}", (0.7, 0.04, 0.5), (1.65, s * W * 0.47, 2.02), glass, 0.01)
        box(f"door_seam{s}", (0.02, 0.03, 1.1), (1.2, s * W * 0.475, 1.65), dark, 0.0)
        box(f"handle{s}", (0.14, 0.04, 0.03), (1.35, s * W * 0.48, 1.7), dark, 0.01)
        box(f"mirror_arm{s}", (0.04, 0.36, 0.04), (2.2, s * 1.25, 2.12), dark, 0.0)
        box(f"mirror{s}", (0.05, 0.18, 0.26), (2.2, s * 1.42, 2.12), dark, 0.02)
    box("windbar", (0.06, 0.08, 0.56), (2.28, 0, 2.02), paint, 0.0, (0, -0.12, 0))
    # Spare wheel upright behind the cab, the jerrycan rack, the fuel tank on the side.
    wheel("spare", (0.72, 0.0, 1.75), 1)
    for ob in [o for o in bpy.data.objects if o.name.startswith("spare")]:
        ob.rotation_euler.rotate(Matrix.Rotation(math.pi / 2, 3, "Z").to_euler())
        ob.location = Vector((0.72, 0, 1.75)) + Matrix.Rotation(math.pi / 2, 3, "Z") @ (ob.location - Vector((0.72, 0, 1.75)))
    cyl("tank", 0.24, 0.9, (0.35, -1.0, 0.85), paint, "X", 24, 0.02)
    # The cargo bed: a wooden floor, dropsides and a tailgate in paint.
    bed_x0, bed_x1 = -3.1, 0.48
    L = bed_x1 - bed_x0
    cx = (bed_x0 + bed_x1) / 2
    box("bed", (L, W, 0.12), (cx, 0, 1.22), wood, 0.01)
    for s in (-1, 1):
        box(f"side{s}", (L, 0.06, 0.55), (cx, s * (W / 2 - 0.03), 1.55), paint, 0.02)
        for k in range(5):
            box(f"rib{s}{k}", (0.06, 0.08, 0.55), (bed_x0 + 0.3 + k * (L - 0.6) / 4, s * (W / 2), 1.55), paint, 0.01)
    box("front_board", (0.06, W, 0.75), (bed_x1 - 0.03, 0, 1.65), paint, 0.02)
    box("tailgate", (0.06, W, 0.55), (bed_x0 + 0.03, 0, 1.55), paint, 0.02)
    for s in (-1, 1):
        box(f"taillight{s}", (0.04, 0.14, 0.08), (bed_x0 - 0.02, s * 0.9, 1.0), mat("red", (0.5, 0.05, 0.03), 0.3), 0.01)
    if canopy:
        # Bows and the canvas: a rounded-top tilt from the cab back to the tailgate, sagging a little between bows,
        # its back flap rolled up.
        H0, H1 = 1.82, 2.95
        nb = 5
        R = 0.32                      # the radius of the rounded top's shoulders
        def section(u):
            """Point on the canopy's cross-section, u 0..1 from the left hem over the top to the right hem."""
            # Path: down the left side (straight), round the left shoulder, across the top, right shoulder, side.
            side = H1 - R - H0
            arc = math.pi * R / 2
            top = W - 2 * R
            total = 2 * side + 2 * arc + top
            d = u * total
            if d < side:
                return (-W / 2, H0 + d)
            d -= side
            if d < arc:
                a = d / R
                return (-W / 2 + R - R * math.cos(a), H1 - R + R * math.sin(a))
            d -= arc
            if d < top:
                return (-W / 2 + R + d, H1)
            d -= top
            if d < arc:
                a = d / R
                return (W / 2 - R + R * math.sin(a), H1 - R + R * math.cos(a))
            d -= arc
            return (W / 2, H1 - d)
        me = bpy.data.meshes.new("canopy")
        bm = bmesh.new()
        nu, nv = 32, 30
        grid = []
        for i in range(nu + 1):
            x = bed_x0 + L * i / nu
            bay = (i / nu) * (nb - 1)
            sag = 0.04 * math.sin(math.pi * (bay - math.floor(bay)))   # between bows the canvas sags a little
            row = []
            for j in range(nv + 1):
                y, z = section(j / nv)
                on_top = max(0.0, (z - (H1 - R)) / R)
                inward = 0.012 * math.sin(math.pi * (bay - math.floor(bay)))
                row.append(bm.verts.new((x, y * (1.0 - inward * (1.0 - on_top)), z - sag * on_top)))
            grid.append(row)
        for i in range(nu):
            for j in range(nv):
                bm.faces.new((grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]))
        # Front panel against the cab: a fan from its centre (no concave n-gon).
        c = bm.verts.new((bed_x1, 0.0, (H0 + H1) / 2))
        for j in range(nv):
            bm.faces.new((grid[nu][j], grid[nu][j + 1], c))
        bm.faces.new((grid[nu][nv], grid[nu][0], c))
        bm.to_mesh(me)
        bm.free()
        ob = bpy.data.objects.new("canopy", me)
        bpy.context.scene.collection.objects.link(ob)
        sol = ob.modifiers.new("thick", "SOLIDIFY")
        sol.thickness = 0.015
        link(ob, canvas)
        # Lashing ropes along the hem.
        for k in range(9):
            x = bed_x0 + 0.2 + k * (L - 0.4) / 8
            for s in (-1, 1):
                box(f"lash{k}{s}", (0.02, 0.02, 0.16), (x, s * (W / 2 + 0.035), H0 - 0.05), mat("rope", (0.45, 0.4, 0.3), 0.9), 0.0)
        cyl("rolled_flap", 0.1, W * 0.86, (bed_x0 - 0.04, 0, H1 - 0.16), canvas, "Y", 16)
        for s in (-1, 1):
            box(f"strap{s}", (0.02, 0.05, 0.9), (bed_x0 - 0.03, s * 0.7, H1 - 0.6), dark, 0.0)
    export(name)


def jeep(name):
    """A light army 4x4 of the 1990s (a generic soft-top, no make): boxy olive body, slotted grille, round headlamps,
    a flat folding windscreen, open doorways, a canvas top over the rear, the spare on the tailgate. 3.95 m long,
    1.55 m wide, 1.85 m to the top; right-hand drive. Forward +X."""
    clear()
    paint = mat("paint", (0.22, 0.24, 0.13), 0.62)
    canvas = mat("canvas", (0.3, 0.3, 0.19), 0.95)
    glass = mat("glass", (0.03, 0.04, 0.045), 0.08, 0.4)
    lamp = mat("lamp", (0.85, 0.83, 0.75), 0.15, 0.6)
    dark = mat("dark", (0.04, 0.04, 0.04), 0.6)
    W = 1.55
    k = 0.66      # wheel scale (the truck's 1.1 m wheel -> 0.73 m)
    for x, tag in ((1.2, "f"), (-1.2, "r")):
        for sd in (-1, 1):
            nm = f"w{tag}{'l' if sd > 0 else 'r'}"
            at = Vector((x, sd * 0.68, 0.36))
            wheel(nm, tuple(at), sd)
            for ob in [o for o in bpy.data.objects if o.name.startswith(nm + "_")]:
                ob.location = at + (ob.location - at) * k
                ob.scale = (k, k, k)
    for sd in (-1, 1):
        box(f"rail{sd}", (3.6, 0.09, 0.14), (0.0, sd * 0.38, 0.5), dark, 0.01)
    for x in (1.2, -1.2):
        cyl(f"axle{x}", 0.05, 1.3, (x, 0, 0.36), dark, "Y", 12)
    # The tub: floor and sides from the dash back to the tailgate.
    box("tub", (2.55, W, 0.5), (-0.55, 0, 0.84), paint, 0.04)
    # Bonnet, slotted grille, round headlamps, flat front wings.
    box("bonnet", (1.25, 1.42, 0.42), (1.32, 0, 0.92), paint, 0.05)
    box("bonnet_top", (1.2, 1.36, 0.05), (1.3, 0, 1.14), paint, 0.02, (0, 0.04, 0))
    box("grille", (0.05, 0.9, 0.34), (1.95, 0, 0.9), dark, 0.01)
    for i in range(7):
        box(f"slot{i}", (0.04, 0.06, 0.3), (1.97, -0.36 + 0.12 * i, 0.9), paint, 0.005)
    for sd in (-1, 1):
        cyl(f"lampbody{sd}", 0.09, 0.08, (1.95, sd * 0.56, 0.92), paint, "X", 24, 0.01)
        cyl(f"lamp{sd}", 0.075, 0.03, (2.0, sd * 0.56, 0.92), lamp, "X", 24, 0.01)
        box(f"wing{sd}", (0.95, 0.24, 0.05), (1.22, sd * 0.68, 0.76), paint, 0.02, (0, 0.0, 0))
        box(f"wing_lip{sd}", (0.95, 0.04, 0.1), (1.22, sd * 0.79, 0.72), paint, 0.01)
        box(f"rwing{sd}", (0.9, 0.12, 0.05), (-1.2, sd * 0.79, 0.78), paint, 0.02)
    box("bumper_f", (0.1, 1.5, 0.12), (2.02, 0, 0.55), dark, 0.02)
    box("bumper_r", (0.1, 1.5, 0.12), (-1.88, 0, 0.55), dark, 0.02)
    # The flat windscreen in its frame, a little raked; wipers; a mirror each side.
    box("screen_frame", (0.05, 1.45, 0.52), (0.68, 0, 1.36), paint, 0.01, (0, -0.12, 0))
    box("screen", (0.03, 1.32, 0.42), (0.7, 0, 1.36), glass, 0.0, (0, -0.12, 0))
    for sd in (-1, 1):
        box(f"mirror{sd}", (0.03, 0.12, 0.16), (0.66, sd * 0.86, 1.4), dark, 0.01)
    # The dash, two front seats, the steering wheel on the right.
    box("dash", (0.2, 1.4, 0.18), (0.58, 0, 1.12), dark, 0.02)
    for sd in (-1, 1):
        box(f"seat{sd}", (0.45, 0.48, 0.12), (0.05, sd * 0.36, 1.0), dark, 0.03)
        box(f"seatback{sd}", (0.1, 0.48, 0.5), (-0.18, sd * 0.36, 1.25), dark, 0.03, (0, 0.12, 0))
    torus("steer", 0.16, 0.018, (0.42, -0.36, 1.32), dark)
    bpy.data.objects["steer"].rotation_euler = (0, math.pi / 2 - 0.5, 0)
    # The soft top: a canvas roof over the bows from the windscreen back, closed sides and back behind the doorways.
    box("top_roof", (2.5, W + 0.02, 0.06), (-0.55, 0, 1.84), canvas, 0.04)
    box("top_back", (1.55, W + 0.02, 0.72), (-1.05, 0, 1.48), canvas, 0.06)
    for i, x in enumerate((0.66, -0.2, -1.78)):
        for sd in (-1, 1):
            cyl(f"bow{i}{sd}", 0.016, 0.72, (x, sd * 0.76, 1.48), dark, "Z", 8)
    # The tailgate with the spare wheel on it.
    nm = "spare"
    at = Vector((-1.97, 0, 0.98))
    wheel(nm, tuple(at), 1)
    for ob in [o for o in bpy.data.objects if o.name.startswith(nm + "_")]:
        rel = (ob.location - at) * k
        ob.location = at + Matrix.Rotation(math.pi / 2, 3, "Z") @ rel
        ob.scale = (k, k, k)
        ob.rotation_euler.rotate(Matrix.Rotation(math.pi / 2, 3, "Z").to_euler())
    export(name)


def export(name):
    path = str(OUT / f"{name}.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True)
    print("wrote", path)


if __name__ == "__main__":
    truck("truck_canopy", canopy=True)
    truck("truck_flat", canopy=False)
    jeep("jeep")
