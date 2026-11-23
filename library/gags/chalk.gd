## library:chalk — words chalked by hand on a flat surface (a steel lid, a blackboard laid flat, a crate top, a
## wall when the gag is tipped up), written stroke by stroke in single-stroke capitals, with an actor's hand
## following the chalk's tip.
##
##   {"id": "wh_chalk", "script": "library:chalk", "t": ..., "at": <point on the surface>, "face": <the reader>,
##    "params": {"lines": ["WHITE", "HOUSE"], "size": 0.2, "done": 8,
##               "write": {"from": {"line": "l2d"}, "to": {"line": "l2d", "word": "House"}},
##               "hand": "jawan", "side": "r", "reach": 1.3, "color": "#f2efe6", "seed": 3}}
##
## The text lies in the holder's XZ plane, centred on "at", its letters' tops toward -z (away from the reader),
## so give the gag "face" = where the reader (the camera) stands. "done" letters are already there at the gag's
## t; the rest are written between write.from and write.to (the last stroke ends on write.to), then the hand
## lifts away and a puff of chalk dust hangs over the last stroke. "hand": an actor whose arm ("side") follows
## the tip (two-bone IK; "reach" lengthens a toon's short arms); a stick of chalk sits between hand and tip.
## Letters: A B E H I J K L M N O R S T U W, and spaces. Anchors: "<id>.tip", "<id>.text" (centre).
extends RefCounted

const Motion = preload("res://scripts/timeline/motion.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")

## Single-stroke capitals in a 1-high box (x right, y up). Each letter: [advance, [stroke, ...]], each stroke a
## polyline; arcs are listed as points.
const GLYPHS := {
	"A": [0.68, [[[0.0, 0.0], [0.3, 1.0], [0.6, 0.0]], [[0.12, 0.38], [0.48, 0.38]]]],
	"B": [0.66, [[[0.0, 0.0], [0.0, 1.0], [0.34, 1.0], [0.5, 0.92], [0.53, 0.76], [0.46, 0.6], [0.3, 0.53], [0.0, 0.53]],
		[[0.3, 0.53], [0.5, 0.46], [0.57, 0.3], [0.52, 0.1], [0.36, 0.0], [0.0, 0.0]]]],
	"E": [0.6, [[[0.5, 1.0], [0.0, 1.0], [0.0, 0.0], [0.52, 0.0]], [[0.0, 0.52], [0.4, 0.52]]]],
	"H": [0.7, [[[0.0, 1.0], [0.0, 0.0]], [[0.56, 1.0], [0.56, 0.0]], [[0.0, 0.5], [0.56, 0.5]]]],
	"I": [0.3, [[[0.12, 1.0], [0.12, 0.0]]]],
	"J": [0.58, [[[0.5, 1.0], [0.5, 0.28], [0.45, 0.1], [0.3, 0.0], [0.14, 0.04], [0.02, 0.2]]]],
	"K": [0.64, [[[0.0, 1.0], [0.0, 0.0]], [[0.54, 1.0], [0.04, 0.44], [0.56, 0.0]]]],
	"L": [0.56, [[[0.0, 1.0], [0.0, 0.0], [0.48, 0.0]]]],
	"M": [0.8, [[[0.0, 0.0], [0.0, 1.0], [0.33, 0.42], [0.66, 1.0], [0.66, 0.0]]]],
	"N": [0.72, [[[0.0, 0.0], [0.0, 1.0], [0.58, 0.0], [0.58, 1.0]]]],
	"O": [0.74, [[[0.3, 1.0], [0.12, 0.92], [0.02, 0.7], [0.0, 0.45], [0.06, 0.2], [0.2, 0.03], [0.36, 0.0], [0.52, 0.06],
		[0.62, 0.25], [0.64, 0.52], [0.58, 0.78], [0.45, 0.96], [0.3, 1.0], [0.2, 0.97]]]],
	"R": [0.66, [[[0.0, 0.0], [0.0, 1.0], [0.34, 1.0], [0.5, 0.92], [0.54, 0.76], [0.47, 0.6], [0.3, 0.52], [0.0, 0.52]],
		[[0.24, 0.52], [0.56, 0.0]]]],
	"S": [0.64, [[[0.54, 0.86], [0.44, 0.97], [0.26, 1.0], [0.09, 0.93], [0.03, 0.77], [0.1, 0.62], [0.3, 0.53], [0.48, 0.44],
		[0.57, 0.28], [0.52, 0.1], [0.35, 0.0], [0.15, 0.02], [0.0, 0.14]]]],
	"T": [0.64, [[[0.0, 1.0], [0.6, 1.0]], [[0.3, 1.0], [0.3, 0.0]]]],
	"U": [0.68, [[[0.0, 1.0], [0.0, 0.3], [0.06, 0.1], [0.2, 0.0], [0.36, 0.0], [0.5, 0.1], [0.56, 0.3], [0.56, 1.0]]]],
	"W": [0.88, [[[0.0, 1.0], [0.18, 0.0], [0.4, 0.66], [0.62, 0.0], [0.8, 1.0]]]],
}

const CHALK := """
shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform float reveal = 0.0;
uniform vec4 color : source_color = vec4(0.95, 0.94, 0.9, 1.0);
varying vec3 lp;
float h3(vec3 p) { p = fract(p * vec3(0.1031, 0.1030, 0.0973)); p += dot(p, p.yxz + 33.33); return fract((p.x + p.y) * p.z); }
float n3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
void vertex() { lp = VERTEX; }
void fragment() {
	if (UV.x > reveal) { discard; }
	// Chalk on rough steel: dense in the middle of the stroke, broken toward the edges, a fine grain, dragged
	// streaks along the stroke direction.
	float across = abs(UV.y);
	float grain = n3(vec3(lp.xz * 900.0, 1.0)) * 0.55 + n3(vec3(lp.xz * 260.0, 2.0)) * 0.45;
	float cover = (1.0 - smoothstep(0.35, 1.0, across)) * 1.15 - (1.0 - grain) * 0.75;
	cover -= 0.25 * smoothstep(0.6, 0.9, n3(vec3(UV.x * 40.0, across * 6.0, 3.0)));
	ALPHA = clamp(cover * 2.0, 0.0, 1.0);
	ALPHA_SCISSOR_THRESHOLD = 0.35;
	ALBEDO = color.rgb * (0.9 + 0.1 * grain);
	ROUGHNESS = 1.0;
	SPECULAR = 0.2;
}
"""

var _mat: ShaderMaterial
var _path: Array = []        # [{"a": Vector3, "b": Vector3, "s0": float, "s1": float, "up": bool}]
var _total := 0.0
var _start_s := 0.0
var _stick: MeshInstance3D
var _dust: Array = []
var _centre := Vector3.ZERO


func validate(g: Dictionary) -> Array:
	var e := []
	var p: Dictionary = g.get("params", {})
	for k in p:
		if not (k in ["lines", "size", "gap", "done", "write", "hand", "side", "reach", "color", "seed", "width"]):
			e.append("chalk: unknown param '%s'" % k)
	for line in p.get("lines", []):
		for ch in String(line):
			if ch != " " and not GLYPHS.has(ch):
				e.append("chalk: no glyph for '%s' (known: %s)" % [ch, "".join(PackedStringArray(GLYPHS.keys()))])
	if not p.has("lines"):
		e.append("chalk: needs 'lines'")
	return e


func build(g: Dictionary) -> Node3D:
	var p: Dictionary = g.get("params", {})
	var size := float(p.get("size", 0.2))
	var gap := float(p.get("gap", 1.45))
	var width := float(p.get("width", 0.085)) * size
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(g.get("id", "chalk"))) + int(p.get("seed", 0))
	var lines: Array = p.get("lines", [])
	var done := int(p.get("done", 0))
	# Lay out the path in writing order: letters left to right, lines top to bottom; pen-up hops between strokes.
	var hop := size * 0.5
	var s := 0.0
	var prev_end = null
	var letter_i := 0
	for li in lines.size():
		var line := String(lines[li])
		var w := 0.0
		for ch in line:
			w += size * (0.45 if ch == " " else float(GLYPHS[ch][0]))
		var x := -w * 0.5
		var z0 := (float(li) - (lines.size() - 1) * 0.5) * size * gap + size * 0.5
		for ch in line:
			if ch == " ":
				x += size * 0.45
				continue
			if letter_i == done:
				_start_s = s
			var glyph: Array = GLYPHS[ch]
			var slant := r.randf_range(-0.05, 0.05)
			var jit := Vector2(r.randf_range(-0.02, 0.02), r.randf_range(-0.03, 0.03)) * size
			for stroke in glyph[1]:
				var pts := []
				for q in stroke:
					var qx := float(q[0]) + slant * float(q[1])
					var pt := Vector3(x + qx * size + jit.x + r.randf_range(-0.008, 0.008) * size, 0.0,
						z0 - float(q[1]) * size + jit.y + r.randf_range(-0.008, 0.008) * size)
					pts.append(pt)
				if prev_end != null:
					var d: float = (prev_end as Vector3).distance_to(pts[0])
					var hs := hop + d * 0.6
					_path.append({"a": prev_end, "b": pts[0], "s0": s, "s1": s + hs, "up": true})
					s += hs
				for i in pts.size() - 1:
					var a: Vector3 = pts[i]
					var b: Vector3 = pts[i + 1]
					var l := a.distance_to(b)
					_path.append({"a": a, "b": b, "s0": s, "s1": s + l, "up": false})
					s += l
				prev_end = pts[-1]
			x += size * float(glyph[0])
			letter_i += 1
	_total = s
	if done >= letter_i:
		_start_s = _total
	# One ribbon mesh: UV.x = the writing parameter at that point, UV.y = -1..1 across the stroke.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for seg in _path:
		if seg["up"]:
			continue
		var a: Vector3 = seg["a"]
		var b: Vector3 = seg["b"]
		var d := (b - a)
		if d.length() < 0.0001:
			continue
		var n := Vector3(-d.z, 0, d.x).normalized() * width * 0.5
		var ext := d.normalized() * width * 0.35
		var a2 := a - ext
		var b2 := b + ext
		var y := Vector3(0, 0.0015, 0)
		var s0: float = seg["s0"]
		var s1: float = seg["s1"]
		var quad := [[a2 - n, s0, -1.0], [b2 - n, s1, -1.0], [b2 + n, s1, 1.0], [a2 - n, s0, -1.0], [b2 + n, s1, 1.0], [a2 + n, s0, 1.0]]
		for v in quad:
			st.set_uv(Vector2(v[1], v[2]))
			st.add_vertex((v[0] as Vector3) + y)
	var mi := MeshInstance3D.new()
	mi.name = "text"
	mi.mesh = st.commit()
	_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = CHALK
	_mat.shader = sh
	_mat.set_shader_parameter("color", Color(String(p.get("color", "#f2efe6"))))
	mi.material_override = _mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var root := Node3D.new()
	root.add_child(mi)
	# The chalk stick (only while a hand holds it) and the dust puff.
	_stick = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = size * 0.05
	cm.bottom_radius = size * 0.05
	cm.height = 1.0
	cm.radial_segments = 8
	_stick.mesh = cm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color("f4f2ea")
	sm.roughness = 1.0
	_stick.material_override = sm
	_stick.visible = false
	root.add_child(_stick)
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.97, 0.96, 0.93, 0.55)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var bm := SphereMesh.new()
	bm.radius = 1.0
	bm.height = 2.0
	bm.radial_segments = 8
	bm.rings = 4
	for i in 14:
		var b := MeshInstance3D.new()
		b.mesh = bm
		b.material_override = dm
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		b.visible = false
		root.add_child(b)
		_dust.append([b, Vector3(r.randf_range(-1, 1), r.randf_range(0.6, 1.6), r.randf_range(-1, 1)).normalized(), r.randf_range(0.5, 1.0)])
	return root


## The chalk tip at writing parameter s (local), and whether the chalk is lifted there.
func _tip(s: float) -> Array:
	for seg in _path:
		if s <= float(seg["s1"]) or seg == _path[-1]:
			var k := clampf((s - float(seg["s0"])) / maxf(float(seg["s1"]) - float(seg["s0"]), 0.0001), 0.0, 1.0)
			var lift := sin(k * PI) * 0.06 if seg["up"] else 0.0
			return [(seg["a"] as Vector3).lerp(seg["b"], k) + Vector3(0, lift, 0), seg["up"]]
	return [Vector3.ZERO, false]


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	var size := float(p.get("size", 0.2))
	var gt := node.global_transform
	var w: Dictionary = p.get("write", {})
	var t0 := float(w.get("from", g.get("t", 0.0)))
	var t1 := float(w.get("to", t0 + 1.0))
	# Writing pace: steady, a touch quicker mid-run; the last stroke lands exactly on t1.
	var u := Motion.seg(t, t0, t1)
	var k := u * u * (1.6 - 0.6 * u)
	var s := lerpf(_start_s, _total, k) if t >= t0 else _start_s
	_mat.set_shader_parameter("reveal", s + 0.0001)
	var tip_info := _tip(s)
	var tip: Vector3 = tip_info[0]
	var writing := t >= t0 - 0.3 and t <= t1
	var after := clampf((t - t1) / 0.35, 0.0, 1.0)
	var hand_id := String(p.get("hand", ""))
	var actor = ctx["actor"].call(hand_id) if hand_id != "" and ctx.has("actor") else null
	_stick.visible = false
	if actor != null:
		var side := String(p.get("side", "r"))
		if float(p.get("reach", 1.0)) != 1.0:
			Crawl.long_arms(actor, float(p["reach"]))
		# The hand rides just above the tip (pressing on the down-strokes), then lifts away after the last stroke.
		var press := 0.0 if tip_info[1] else -0.006 * sin(t * 40.0)
		var target := gt * (tip + Vector3(0, size * 0.42 + press, 0))
		var weight := 1.0 - Motion.smooth(after)
		if t < t1 + 0.35:
			actor.aim_hand(side, target, weight)
		var hand: Vector3 = gt.affine_inverse() * actor.bone_world("hand_" + side)
		var nib := tip if weight > 0.5 else hand + Vector3(0, -size * 0.3, 0)
		var axis := hand - nib
		if axis.length() > 0.01:
			_stick.visible = true
			var len := minf(axis.length(), size * 0.5)
			var dir := axis.normalized()
			_stick.transform = Transform3D(_basis_y(dir).scaled(Vector3(1, len, 1)), nib + dir * len * 0.5)
	# A puff of chalk dust off the last stroke.
	var age := t - t1
	for dd in _dust:
		var b: MeshInstance3D = dd[0]
		b.visible = age > 0.0 and age < 1.0
		if b.visible:
			var e := Motion.out_cubic(clampf(age / 0.9, 0.0, 1.0))
			b.position = _tip(_total)[0] + (dd[1] as Vector3) * size * 0.45 * e * float(dd[2]) + Vector3(0, size * 0.1 * age, 0)
			b.scale = Vector3.ONE * size * 0.05 * (0.6 + e) * (1.0 - age)
	return {"tip": gt * tip, "text": gt * Vector3(0, 0, 0)}


static func _basis_y(d: Vector3) -> Basis:
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD)
	if x.length() < 0.01:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	return Basis(x, y, x.cross(y).normalized())
