"""Blender asset script for the Pokhran range (run headless; writes glTF binaries for Godot).

    "E:/Program Files/Blender/blender.exe" -b --factory-startup --python episodes/pokhran/blender/range_assets.py -- OUT_DIR

Writes into OUT_DIR (default incoming/pokhran_blender/, git-ignored, rebuilt from this script):
  khejri_a.glb, khejri_b.glb, khejri_c.glb   Prosopis cineraria, the Thar's signature tree: a short crooked
      trunk with fissured bark and a flared base, spreading branches that fork and droop, and feathery
      grey-green bipinnate leaf sprays as real geometry (no alpha cards, so they cast shadows and backlight).
      c is lopped (pollarded): a stubby trunk with a dense ball of regrowth, as villagers cut them for fodder.
      Materials: "bark" (vertex colour: dark fissures / lighter ridges) and "leaf" (vertex colour per spray).
  sandbag.glb   one filled hessian sandbag, 0.55 x 0.32 x 0.14 m, a sagging pillow with a tied neck.
  ker_a.glb, ker_b.glb   ker bushes (Capparis decidua): leafless tangles of glaucous green twigs, about 1.5 m.
  grass_a.glb, grass_b.glb   dry sewan-grass tufts (Lasiurus sindicus), 0.3-0.6 m.

Deterministic: every random draw comes from random.Random(seed) per asset.
"""
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Vector, Matrix, noise

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
REPO = Path(__file__).resolve().parents[3]
OUT = Path(ARGS[0]) if ARGS else REPO / "incoming" / "pokhran_blender"
OUT.mkdir(parents=True, exist_ok=True)


def clear():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials):
        for d in list(coll):
            coll.remove(d)


def material(name, rgb, rough=0.9):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    # Multiply by the vertex colour so the variation survives export.
    vc = m.node_tree.nodes.new("ShaderNodeVertexColor")
    vc.layer_name = "Col"
    m.node_tree.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
    return m


class MeshBuf:
    def __init__(self):
        self.v, self.f, self.c = [], [], []

    def add(self, verts, faces, col):
        base = len(self.v)
        self.v += verts
        self.c += [col] * len(verts) if not callable(col) else [col(p) for p in verts]
        self.f += [tuple(i + base for i in face) for face in faces]

    def obj(self, name, mat):
        me = bpy.data.meshes.new(name)
        me.from_pydata([tuple(p) for p in self.v], [], self.f)
        attr = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
        for i, c in enumerate(self.c):
            attr.data[i].color = (*c, 1.0)
        me.materials.append(mat)
        for p in me.polygons:
            p.use_smooth = True
        me.validate()
        ob = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(ob)
        return ob


# --- the tree --------------------------------------------------------------------------------

def frames(points):
    """Parallel-transport frames along a polyline: (tangent, normal, binormal) per point."""
    ts = []
    for i in range(len(points)):
        a = points[max(i - 1, 0)]
        b = points[min(i + 1, len(points) - 1)]
        ts.append((b - a).normalized())
    n = ts[0].orthogonal().normalized()
    out = []
    for i, t in enumerate(ts):
        if i > 0:
            n = (n - t * n.dot(t)).normalized()
        out.append((t, n, t.cross(n).normalized()))
    return out


def tube(buf, points, radii, sides, bark_seed, rough=0.12):
    """A closed tube along points with per-point radius; the surface gets vertical bark fissures."""
    fr = frames(points)
    ring0 = len(buf.v)
    verts, cols = [], []
    length = 0.0
    for i, (p, r) in enumerate(zip(points, radii)):
        if i > 0:
            length += (p - points[i - 1]).length
        t, n, b = fr[i]
        for k in range(sides):
            a = 2 * math.pi * k / sides
            d = n * math.cos(a) + b * math.sin(a)
            # Fissures: ridged noise stretched along the branch, deeper on thick wood.
            q = Vector((math.cos(a) * 3.0, math.sin(a) * 3.0, length * 0.9 + bark_seed))
            ridge = 1.0 - abs(noise.noise(q * 1.7))
            fiss = (ridge ** 3) * rough * min(r / 0.12, 1.0)
            lump = noise.noise(q * 0.5 + Vector((bark_seed, 0, 0))) * 0.08
            rr = r * (1.0 - fiss + lump)
            verts.append(p + d * rr)
            g = 0.16 + 0.34 * (1.0 - ridge ** 3) + 0.06 * noise.noise(q * 4.0)
            cols.append((g * 0.9, g * 0.82, g * 0.74))
    faces = []
    for i in range(len(points) - 1):
        for k in range(sides):
            a = i * sides + k
            b = i * sides + (k + 1) % sides
            faces.append((a, b, b + sides, a + sides))
    # Cap the tip.
    tip = len(verts)
    verts.append(points[-1] + fr[-1][0] * radii[-1] * 0.6)
    cols.append(cols[-1])
    last = (len(points) - 1) * sides
    for k in range(sides):
        faces.append((last + k, last + (k + 1) % sides, tip))
    buf.v += verts
    buf.c += cols
    buf.f += [tuple(i + ring0 for i in fc) for fc in faces]


def leaf_spray(buf, rng, at, direction, size, tint, lod=False):
    """A drooping bipinnate spray: a rachis with 2-3 pairs of pinnae, each with paired narrow leaflets."""
    up = Vector((0, 0, 1))
    d = (direction + Vector((0, 0, -0.55))).normalized()
    side = d.cross(up)
    if side.length < 1e-3:
        side = Vector((1, 0, 0))
    side.normalize()
    pairs = rng.randint(2, 3)
    if lod:
        pairs = 1
    for j in range(pairs):
        base = at + d * size * (0.25 + 0.3 * j)
        for s in (-1, 1):
            pd = (d * 0.55 + side * s * 0.9 + Vector((0, 0, -0.25))).normalized()
            plen = size * rng.uniform(0.75, 1.0)
            n_leaf = 3 if lod else 7
            for k in range(n_leaf):
                c = base + pd * plen * (k + 0.5) / n_leaf
                nrm = pd.cross(side * s).normalized()
                if nrm.z < 0:
                    nrm = -nrm
                for s2 in (-1, 1):
                    ld = (pd * 0.45 + nrm.cross(pd).normalized() * s2).normalized()
                    L = size * (0.46 if lod else 0.2) * rng.uniform(0.85, 1.15)
                    W = L * 0.32
                    w = nrm.cross(ld).normalized() * W * 0.5
                    p0 = c
                    p1 = c + ld * L * 0.5 + w
                    p2 = c + ld * L
                    p3 = c + ld * L * 0.5 - w
                    droop = Vector((0, 0, -L * 0.18))
                    quad = [p0, p1 + droop * 0.5, p2 + droop, p3 + droop * 0.5]
                    buf.add(quad, [(0, 1, 2, 3)], tint)


def grow(rng, branches, start, direction, length, radius, depth, max_depth, sprays):
    """Recursive branch: a bent polyline, forks into 2-3 children; leaf sprays on the outer two levels."""
    segs = max(4, int(length / 0.18))
    pts, rad = [start.copy()], [radius]
    d = direction.normalized()
    p = start.copy()
    bend = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-0.3, 0.3))) * 0.35
    for i in range(1, segs + 1):
        f = i / segs
        # Crooked: wander, curve outward, and droop under weight toward the tip on thin wood.
        d = (d + bend * (1.0 / segs) + Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-1, 1))) * 0.12).normalized()
        if depth >= max_depth - 1:
            d = (d + Vector((0, 0, -0.06 * f))).normalized()
        p = p + d * (length / segs)
        pts.append(p.copy())
        rad.append(radius * (1.0 - 0.55 * f))
    branches.append((pts, rad, depth))
    if depth >= max_depth - 2:
        for i in range(2, len(pts), 1 if depth == max_depth else 2):
            if rng.random() < 0.92:
                out = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-0.2, 0.4)))
                sprays.append((pts[i], (frames(pts)[i][0] * 0.6 + out.normalized()).normalized()))
    if depth >= max_depth:
        for _ in range(3):
            sprays.append((pts[-1], (d + Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), 0))).normalized()))
        return
    n_kids = 2 if rng.random() < 0.6 else 3
    for k in range(n_kids):
        t = rng.uniform(0.55, 1.0) if k else 1.0
        idx = min(int(t * segs), segs)
        axis = d.orthogonal().normalized()
        rot = Matrix.Rotation(rng.uniform(0, 2 * math.pi), 3, d) @ Matrix.Rotation(math.radians(rng.uniform(22, 48)), 3, axis)
        cd = (rot @ d).normalized()
        cd.z = max(cd.z, -0.15)
        grow(rng, branches, pts[idx], cd, length * rng.uniform(0.6, 0.72),
             rad[idx] * (0.72 if n_kids == 2 else 0.62), depth + 1, max_depth, sprays)


def khejri(name, seed, lopped=False, lod=False):
    clear()
    rng = random.Random(seed)
    branches, sprays = [], []
    # The trunk: short, leaning, kinked, with a flared base.
    h = rng.uniform(1.4, 1.7) if lopped else rng.uniform(1.7, 2.3)
    lean = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), 0)).normalized() * rng.uniform(0.12, 0.3)
    tp, tr = [], []
    for i in range(13):
        f = i / 12
        kink = Vector((math.sin(f * 5 + seed) * 0.06, math.cos(f * 4 + seed) * 0.06, 0))
        tp.append(Vector((0, 0, h * f)) + lean * h * f * f + kink)
        tr.append(0.25 * (1.0 + 0.6 * (1.0 - min(f / 0.15, 1.0)) ** 2) * (1.0 - 0.3 * f))
    branches.append((tp, tr, 0))
    top = tp[-1]
    n_main = rng.randint(4, 6) if not lopped else rng.randint(7, 9)
    for k in range(n_main):
        az = 2 * math.pi * (k + rng.uniform(-0.25, 0.25)) / n_main
        el = math.radians(rng.uniform(38, 62) if not lopped else rng.uniform(45, 75))
        d = Vector((math.cos(az) * math.cos(el), math.sin(az) * math.cos(el), math.sin(el)))
        start = top + Vector((0, 0, rng.uniform(-0.35, 0.05)))
        if lopped:
            grow(rng, branches, start, d, rng.uniform(1.0, 1.5), 0.05, 2, 5, sprays)
        else:
            grow(rng, branches, start, d, rng.uniform(1.5, 2.1), 0.12, 1, 5, sprays)
    if lopped:
        # The lopped stumps: blunt knuckles at the trunk top.
        for k in range(5):
            az = 2 * math.pi * k / 5 + 0.3
            d = Vector((math.cos(az) * 0.6, math.sin(az) * 0.6, 0.8)).normalized()
            pts = [top, top + d * 0.35]
            branches.append((pts, [0.12, 0.1], 1))
    bark = MeshBuf()
    for pts, rad, depth in branches:
        if lod and rad[0] < 0.012:
            continue
        sides = 14 if depth == 0 else (8 if rad[0] > 0.04 else (5 if rad[0] > 0.012 else 4))
        tube(bark, pts, rad, sides, seed * 7.1 + len(pts), 0.22 if depth == 0 else 0.12)
    leaves = MeshBuf()
    for at, d in sprays:
        g = rng.uniform(-0.05, 0.05)
        tint = (0.44 + g, 0.5 + g + rng.uniform(-0.03, 0.03), 0.36 + g * 0.5)
        leaf_spray(leaves, rng, at, d, rng.uniform(0.3, 0.42), tint, lod)
    mb = material("bark", (1, 1, 1), 0.95)
    ml = material("leaf", (1, 1, 1), 0.7)
    bark.obj(name + "_bark", mb)
    leaves.obj(name + "_leaves", ml)
    export(name)
    print(f"{name}: {len(bark.v)} bark verts, {len(leaves.f)} leaflets, {len(sprays)} sprays")


# --- the sandbag ---------------------------------------------------------------------------

def sandbag():
    clear()
    buf = MeshBuf()
    L, W, H = 0.55, 0.32, 0.14
    nu, nv = 28, 16
    verts, faces = [], []
    # A superellipsoid pillow: flat-ish top and bottom, sagging belly, pinched neck at +x.
    for i in range(nv + 1):
        th = math.pi * i / nv - math.pi / 2
        for j in range(nu):
            ph = 2 * math.pi * j / nu
            cx, sx = math.cos(ph), math.sin(ph)
            ct, st = math.cos(th), math.sin(th)
            e = 0.35
            x = math.copysign(abs(ct) ** e * abs(cx) ** e, cx) * L / 2
            y = math.copysign(abs(ct) ** e * abs(sx) ** e, sx) * W / 2
            z = math.copysign(abs(st) ** 0.6, st) * H / 2
            # Neck: squeeze the +x end into a gathered tie.
            u = max(0.0, x / (L / 2))
            pinch = 1.0 - 0.55 * u ** 6
            y *= pinch
            z = z * pinch + (0.015 * u ** 6)
            # Sag: the belly settles, the top dips between the ends, cloth wrinkles.
            z -= 0.02 * (1.0 - (2 * x / L) ** 2) * (1 if z > 0 else 0)
            wr = noise.noise(Vector((x * 18, y * 18, z * 18))) * 0.006
            p = Vector((x, y, z + H / 2))
            p += Vector((cx, sx, st)).normalized() * wr
            verts.append(p)
    for i in range(nv):
        for j in range(nu):
            a = i * nu + j
            b = i * nu + (j + 1) % nu
            faces.append((a, b, b + nu, a + nu))
    buf.add(verts, faces, lambda p: (0.72 + 0.1 * noise.noise(p * 9), 0.64 + 0.1 * noise.noise(p * 9), 0.48))
    buf.obj("sandbag", material("hessian", (1, 1, 1), 0.98))
    export("sandbag")


def ker(name, seed):
    """Ker (Capparis decidua): a leafless, much-branched shrub of glaucous green twigs, 1.2-2.4 m, rounded and
    tangled, grey-brown old wood at the base. One material "bark" (vertex colour: brown base to green twigs)."""
    clear()
    rng = random.Random(seed)
    branches, dummy = [], []
    n = rng.randint(16, 20)
    for k in range(n):
        az = 2 * math.pi * (k + rng.uniform(-0.4, 0.4)) / n
        el = math.radians(rng.uniform(22, 72))
        d = Vector((math.cos(az) * math.cos(el), math.sin(az) * math.cos(el), math.sin(el)))
        start = Vector((rng.uniform(-0.15, 0.15), rng.uniform(-0.15, 0.15), 0.0))
        grow(rng, branches, start, d, rng.uniform(0.42, 0.6), 0.03, 2, 6, dummy)
    buf = MeshBuf()
    for pts, rad, depth in branches:
        sides = 6 if rad[0] > 0.02 else 4
        tube(buf, pts, [max(r, 0.004) for r in rad], sides, seed * 3.3 + len(pts), 0.05)
    # Recolour: old stems grey-brown, the outer twigs glaucous green.
    for i, v in enumerate(buf.v):
        h = min(max((v.z - 0.1) / 0.9, 0.0), 1.0)
        g = buf.c[i][0]
        old = (0.3 * g + 0.12, 0.27 * g + 0.1, 0.22 * g + 0.08)
        young = (0.33, 0.43 + 0.05 * rng.random(), 0.27)
        buf.c[i] = tuple(o + (y - o) * h for o, y in zip(old, young))
    buf.obj(name, material("bark", (1, 1, 1), 0.85))
    export(name)
    print(f"{name}: {len(buf.f)} faces")


def grass(name, seed):
    """A tuft of dry sewan grass (Lasiurus sindicus) in May: 30-45 thin arching blades, straw-gold tips over a
    grey-green base, 0.3-0.6 m. Material "grass" (vertex colour)."""
    clear()
    rng = random.Random(seed)
    buf = MeshBuf()
    for b in range(rng.randint(30, 45)):
        az = rng.uniform(0, 2 * math.pi)
        lean = rng.uniform(0.15, 0.9)
        hgt = rng.uniform(0.28, 0.6)
        base = Vector((math.cos(az) * rng.uniform(0, 0.06), math.sin(az) * rng.uniform(0, 0.06), 0))
        out = Vector((math.cos(az), math.sin(az), 0))
        side = Vector((-math.sin(az), math.cos(az), 0))
        w0 = rng.uniform(0.006, 0.011)
        segs = 5
        verts, faces, cols = [], [], []
        for i in range(segs + 1):
            f = i / segs
            c = base + out * lean * hgt * f * f * 0.9 + Vector((0, 0, hgt * (f - 0.35 * lean * f * f)))
            w = w0 * (1.0 - f) + 0.0008
            verts += [c - side * w, c + side * w]
            tip = f ** 1.4
            col = (0.42 + 0.4 * tip, 0.42 + 0.3 * tip, 0.3 + 0.12 * tip)
            cols += [col, col]
        for i in range(segs):
            faces.append((2 * i, 2 * i + 1, 2 * i + 3, 2 * i + 2))
        base_i = len(buf.v)
        buf.v += verts
        buf.c += cols
        buf.f += [tuple(j + base_i for j in fc) for fc in faces]
    buf.obj(name, material("grass", (1, 1, 1), 0.9))
    export(name)


def export(name):
    path = str(OUT / f"{name}.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True)
    print("wrote", path)


if __name__ == "__main__":
    khejri("khejri_a", 11)
    khejri("khejri_b", 23)
    khejri("khejri_c", 37, lopped=True)
    # Far versions (the same trees, a sixth of the leaflets, larger): for trees beyond ~60 m.
    khejri("khejri_a_far", 11, lod=True)
    khejri("khejri_b_far", 23, lod=True)
    khejri("khejri_c_far", 37, lopped=True, lod=True)
    sandbag()
    ker("ker_a", 5)
    ker("ker_b", 9)
    grass("grass_a", 3)
    grass("grass_b", 4)
