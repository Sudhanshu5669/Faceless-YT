## Khetolai, the village nearest the Pokhran range (Jaisalmer district), May 1998: round mud huts (jhumpa) with
## thatched cones and lime-washed bands, flat-roofed mud houses with parapets, low mud compound walls, khejri trees, a
## stone well with a pulley frame, a charpai in a tree's shade; beyond the last wall, the open Thar.
##
## Local frame: the lane runs along z through the origin (x = 0), the village behind (-z), the open desert toward +z,
## where cameras usually stand looking -z. Ground y 0 (flat in the village, low dunes far out).
##
## params:
##   tyre     [{"actor": id}]   the actor runs a bicycle tyre along with a stick (the tyre rolls beside his right hand)
##   pots     [actor ids]   two clay matkas stacked on the head, a hand up steadying them
##   well     {"actor": id, "from": t, "to": t}   she hauls the bucket up the well hand over hand on the pulley rope
##   dust     {"from": t, "to": t, "dir": [x, z]}   wisps of sand blowing in from the desert along dir, low over the ground
##   crack    {"from": t, "to": t, "hut": 0, "angle": deg, "shake": t}   a crack runs up the hut's mud wall (from the
##            plinth toward the eave, zigzag, with two branches) between from and to, at `angle` degrees round from its
##            door; from `shake` the thatch sheds dust and mud chips fall
##   ripple   {"t": t, "at": [x, z]}   an open clay matka full of water on a stand at (x, z): at t its surface rings with
##            concentric ripples (the shock arriving through the ground)
## anchors: pot (the water's surface), crack (the crack's middle), well, lane (the lane's middle at head height), tree, wall (the hero hut wall facing +z)
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")
const PB := "incoming/pokhran_blender/"
const TX := "incoming/polyhaven_pokhran/textures/"
const WELL_AT := Vector3(-3.6, 0, -2.4)
const TREE_AT := Vector3(4.2, 0, -8.5)
# Huts: [x, z, radius, height]
const HUTS := [[-6.2, -6.5, 2.0, 2.1], [6.6, -3.8, 1.8, 2.0], [-9.5, -14.5, 2.2, 2.3], [9.0, -14.0, 1.9, 2.0],
	[-2.4, -19.0, 2.1, 2.2], [13.5, -22.0, 2.0, 2.1], [-14.0, -4.5, 1.8, 1.9], [-15.5, -20.0, 2.0, 2.1]]
# Flat-roofed houses: [x, z, w, d, h, yaw]
const HOUSES := [[11.5, -7.0, 5.0, 4.0, 2.7, 0.1], [-11.0, -27.0, 6.0, 4.5, 2.8, -0.08], [4.0, -28.0, 5.5, 4.0, 2.6, 0.05]]

const GROUND := """
shader_type spatial;
uniform sampler2D a_alb : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D b_alb : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 wp;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y); }
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float d = length(w.xz - MODEL_MATRIX[3].xz);
	float far = smoothstep(60.0, 300.0, d);
	VERTEX.y += far * (3.0 * (0.5 + 0.5 * sin(w.x * 0.02 + 1.7 * sin(w.z * 0.007))) + 1.5 * sin(w.z * 0.013) * sin(w.x * 0.017));
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 uv = wp.xz / 3.0;
	vec3 packed_earth = texture(a_alb, uv).rgb * vec3(1.05, 0.95, 0.85);
	vec3 sand = texture(b_alb, uv * 0.7).rgb * vec3(1.08, 0.98, 0.86);
	float d = length(wp.xz - NODE_POSITION_WORLD.xz + vec2(0.0, 10.0));
	float k = smoothstep(18.0, 34.0, d + 6.0 * n2(wp.xz * 0.08));
	// The beaten lane.
	float lane = 1.0 - smoothstep(1.2, 2.6, abs(wp.x - NODE_POSITION_WORLD.x + 0.6 * sin(wp.z * 0.08)));
	vec3 c = mix(packed_earth, sand, k);
	c = mix(c, c * vec3(0.92, 0.88, 0.82), lane * (1.0 - k) * 0.6);
	ALBEDO = c;
	ROUGHNESS = 0.95;
}
"""

const LEAF := """
shader_type spatial;
render_mode cull_disabled;
void fragment() {
	vec3 c = COLOR.rgb * vec3(0.66, 0.66, 0.56);
	ALBEDO = c;
	ROUGHNESS = 0.72;
	SPECULAR = 0.3;
	BACKLIGHT = c * vec3(0.95, 1.0, 0.6) * 0.55;
}
"""

const BARK := """
shader_type spatial;
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.95;
	SPECULAR = 0.25;
}
"""

const WATER := """
shader_type spatial;
uniform float s = -1.0;
void fragment() {
	vec2 q = UV - 0.5;
	float d = length(q) * 2.0;
	float k = 0.0;
	if (s > 0.0) {
		float env = exp(-s * 0.9) * smoothstep(0.0, 0.05, s);
		k = env * sin(d * 46.0 - s * 26.0) * smoothstep(1.0, 0.2, d);
	}
	vec3 deep = vec3(0.05, 0.07, 0.07);
	ALBEDO = deep;
	NORMAL_MAP = normalize(vec3(q / max(d, 0.001) * k * 0.9, 1.0)) * 0.5 + 0.5;
	ROUGHNESS = 0.04;
	SPECULAR = 0.8;
	METALLIC = 0.0;
}
"""

const DUST := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform float a = 0.0;
varying float fade;
void vertex() { fade = INSTANCE_CUSTOM.r; }
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y); }
void fragment() {
	vec2 q = UV - 0.5;
	float r = length(q * vec2(1.0, 2.2)) * 2.0;
	float n = n2(UV * 6.0 + fade * 3.0) * 0.6 + 0.4;
	ALBEDO = vec3(0.86, 0.74, 0.56);
	ALPHA = clamp((1.0 - r) * n * fade * 0.22, 0.0, 1.0) * a;
}
"""

var _p := {}
var _tyres := {}
var _pots := {}
var _bucket: Node3D
var _rope_up: MeshInstance3D
var _dust: MultiMeshInstance3D
var _dust_mat: ShaderMaterial
var _hero_wall := Vector3.ZERO
var _crack_segs: Array = []      # [node, t_appear]
var _crack_mid := Vector3.ZERO
var _water_mat: ShaderMaterial
var _pot_top := Vector3.ZERO
var _chips: Array = []           # [node, start, t0]
var _eave_dust: Array = []


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "village"))
	# The ground: a big disc, packed earth in the village, sand beyond, dunes far out.
	var gm := Kit.shader(GROUND)
	gm.set_shader_parameter("a_alb", Kit.texture(TX + "dry_ground_01_diff_2k.jpg"))
	gm.set_shader_parameter("b_alb", Kit.texture(TX + "sand_01_diff_2k.jpg"))
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1600, 1600)
	pm.subdivide_width = 160
	pm.subdivide_depth = 160
	ground.mesh = pm
	ground.material_override = gm
	root.add_child(ground)
	var mud := Kit.mat("#b88656", 0.95)
	var mud2 := Kit.mat("#c79a68", 0.95)
	var lime := Kit.mat("#e8e0cc", 0.9)
	var ochre := Kit.mat("#b8642e", 0.9)
	var thatch := Kit.mat("#8c7446", 0.98)
	var dark := Kit.mat("#1c1410", 0.95)
	# Round huts: mud wall, a lime-washed plinth band and an ochre band, a dark doorway facing the lane, thatch cone
	# with a little topknot.
	for i in HUTS.size():
		var hd: Array = HUTS[i]
		var at := Vector3(float(hd[0]), 0, float(hd[1]))
		var r := float(hd[2])
		var h := float(hd[3])
		Kit.cyl(root, r, r * 1.03, h, at + Vector3(0, h * 0.5, 0), mud if i % 2 == 0 else mud2, 24)
		Kit.cyl(root, r * 1.035, r * 1.06, 0.35, at + Vector3(0, 0.175, 0), lime, 24)
		Kit.cyl(root, r * 1.012, r * 1.012, 0.12, at + Vector3(0, 0.55, 0), ochre, 24)
		Kit.cyl(root, 0.06, r * 1.32, r * 1.2, at + Vector3(0, h + r * 0.58, 0), thatch, 20)
		Kit.cyl(root, 0.0, 0.16, 0.4, at + Vector3(0, h + r * 1.2 + 0.18, 0), thatch, 8)
		var to_lane := Vector3(-at.x, 0, 4.0).normalized()
		var door := Kit.box(root, Vector3(0.8, 1.55, 0.2), at + to_lane * (r - 0.02) + Vector3(0, 0.78, 0), dark)
		door.rotation.y = atan2(to_lane.x, to_lane.z)
		if i == 0:
			_hero_wall = at + Vector3(0.55, 1.2, 0.0).rotated(Vector3.UP, 0.0) + Vector3(0.0, 0, r * 0.9)
	# Flat-roofed mud houses with parapets and a lime-washed door frame.
	for hd in HOUSES:
		var hn := Node3D.new()
		hn.position = Vector3(float(hd[0]), 0, float(hd[1]))
		hn.rotation.y = float(hd[5])
		root.add_child(hn)
		var w := float(hd[2])
		var d := float(hd[3])
		var h := float(hd[4])
		Kit.box(hn, Vector3(w, h, d), Vector3(0, h * 0.5, 0), mud2)
		Kit.box(hn, Vector3(w + 0.1, 0.3, d + 0.1), Vector3(0, h + 0.15, 0), mud)
		Kit.box(hn, Vector3(w + 0.12, 0.3, d + 0.12), Vector3(0, 0.15, 0), lime)
		Kit.box(hn, Vector3(1.1, 1.9, 0.1), Vector3(-w * 0.2, 0.95, d * 0.5 + 0.02), lime)
		Kit.box(hn, Vector3(0.85, 1.75, 0.1), Vector3(-w * 0.2, 0.875, d * 0.5 + 0.05), dark)
	# Low mud compound walls along both sides of the lane: continuous, rounded with a lime-washed cap, a gateway now and
	# then into a compound.
	for side: float in [-1.0, 1.0]:
		var z := 2.0
		var seg := 0
		while z > -32.0:
			var len := 4.5 + 2.0 * absf(sin(z * 0.9 + side))
			var x := side * (3.3 + 0.25 * sin(z * 0.4))
			if seg % 3 != 1:
				var hh := 0.95 + 0.1 * sin(z * 1.7)
				Kit.slab(root, Vector3(0.45, hh, len), 0.12, Vector3(x, hh * 0.5, z - len * 0.5), mud)
				Kit.slab(root, Vector3(0.5, 0.08, len + 0.04), 0.03, Vector3(x, hh, z - len * 0.5), lime)
			z -= len + (1.6 if seg % 3 == 1 else 0.0)
			seg += 1
	# Khejri trees; the hero tree shades a charpai.
	var trees := [[TREE_AT.x, TREE_AT.z, 1.3, "khejri_a.glb"], [-12.0, -10.0, 1.1, "khejri_b.glb"], [16.0, -16.0, 1.2, "khejri_c.glb"],
		[-6.0, -30.0, 1.2, "khejri_b.glb"], [22.0, 4.0, 1.0, "khejri_a.glb"]]
	var leaf_mat := Kit.shader(LEAF)
	var bark_mat := Kit.shader(BARK)
	for tr in trees:
		var m := Kit.model(PB + String(tr[3]))
		for mi in m.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = leaf_mat if String(mi.name).ends_with("leaves") else bark_mat
		m.position = Vector3(float(tr[0]), 0, float(tr[1]))
		m.scale = Vector3.ONE * float(tr[2])
		m.rotation.y = float(tr[0]) * 0.7
		root.add_child(m)
	_charpai(root, TREE_AT + Vector3(1.4, 0, 1.6), 0.4)
	_well(root)
	_crack_build(root)
	_ripple_build(root)
	# Scattered: a few pots by the huts, a pile of dung cakes, stones.
	for k in 6:
		var pt := Vector3(-5.0 + 2.2 * k + 0.6 * sin(k * 3.1), 0, -4.2 - 3.0 * absf(sin(k * 1.7)))
		if absf(pt.x) < 2.6:
			continue
		Kit.ball(root, 0.2, pt + Vector3(0, 0.2, 0), Kit.mat("#9a4a2a", 0.85), 16, Vector3(1, 0.9, 1))
	for k in 12:
		Kit.cyl(root, 0.13, 0.14, 0.04, Vector3(7.8 + 0.25 * (k % 4), 0.02 + 0.04 * (k / 4), -1.8 + 0.2 * (k % 3)), Kit.mat("#5a4632", 0.98), 10)
	# Held props.
	for e in _p.get("tyre", []):
		var tn := Node3D.new()
		var tyre := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.25
		tm.outer_radius = 0.31
		tm.rings = 24
		tm.ring_segments = 8
		tyre.mesh = tm
		tyre.material_override = Kit.mat("#1a1a1a", 0.8)
		tyre.rotation.z = PI / 2
		tn.add_child(tyre)
		root.add_child(tn)
		var stick := MeshInstance3D.new()
		root.add_child(stick)
		_tyres[String(e["actor"])] = [tn, stick]
	for aid in _p.get("pots", []):
		var pn := Node3D.new()
		Kit.ball(pn, 0.2, Vector3(0, 0.17, 0), Kit.mat("#9a4a2a", 0.85), 16, Vector3(1, 0.85, 1))
		Kit.cyl(pn, 0.07, 0.09, 0.07, Vector3(0, 0.34, 0), Kit.mat("#8a4224", 0.85), 12)
		Kit.ball(pn, 0.15, Vector3(0, 0.5, 0), Kit.mat("#a85634", 0.85), 16, Vector3(1, 0.85, 1))
		Kit.cyl(pn, 0.05, 0.07, 0.06, Vector3(0, 0.63, 0), Kit.mat("#8a4224", 0.85), 12)
		Kit.cyl(pn, 0.11, 0.11, 0.04, Vector3(0, 0.01, 0), Kit.mat("#c8302a", 0.9), 12)
		root.add_child(pn)
		_pots[String(aid)] = pn
	# Dust wisps.
	var dd: Dictionary = _p.get("dust", {})
	if not dd.is_empty():
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		var q := QuadMesh.new()
		q.size = Vector2(4.0, 1.2)
		mm.mesh = q
		mm.instance_count = 18
		_dust = MultiMeshInstance3D.new()
		_dust.multimesh = mm
		_dust_mat = Kit.shader(DUST)
		_dust.material_override = _dust_mat
		_dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_dust.extra_cull_margin = 60.0
		root.add_child(_dust)
	return root


func _crack_build(root: Node3D) -> void:
	var cd: Dictionary = _p.get("crack", {})
	if cd.is_empty():
		return
	var hd: Array = HUTS[int(cd.get("hut", 0))]
	var c := Vector3(float(hd[0]), 0, float(hd[1]))
	var r := float(hd[2])
	var h := float(hd[3])
	var to_lane := Vector3(-c.x, 0, 4.0).normalized()
	var a0 := atan2(to_lane.z, to_lane.x) + deg_to_rad(float(cd.get("angle", 30.0)))
	var t0 := float(cd["from"])
	var t1 := float(cd["to"])
	var dark := Kit.mat("#120c08", 0.95)
	var rng := Kit.rng("crack")
	# The main crack: a zigzag from the plinth band up to the eave; two branches off it.
	var paths := [[a0, 0.36, h - 0.05, 0.0, 1.0, 0.03], [a0 + 0.05, 1.0, 1.65, 0.45, 0.8, 0.018], [a0 - 0.02, 1.45, 1.9, 0.62, 0.95, 0.015]]
	for pi in paths.size():
		var pd: Array = paths[pi]
		var ang := float(pd[0])
		var y := float(pd[1])
		var y1 := float(pd[2])
		var n := 14 if pi == 0 else 6
		var prev := Vector3(cos(ang) * (r + 0.012), y, sin(ang) * (r + 0.012)) + c
		for k in n:
			var u := float(k + 1) / n
			ang += rng.randf_range(-0.07, 0.07) + (0.03 if pi == 1 else (-0.03 if pi == 2 else 0.0))
			var yy := lerpf(float(pd[1]), y1, u)
			var nxt := Vector3(cos(ang) * (r + 0.012), yy, sin(ang) * (r + 0.012)) + c
			var seg := MeshInstance3D.new()
			var bm := BoxMesh.new()
			var w := float(pd[5]) * (1.0 - 0.5 * u)
			bm.size = Vector3(w, (nxt - prev).length() + w, 0.012)
			seg.mesh = bm
			seg.material_override = dark
			var up := (nxt - prev).normalized()
			var out := Vector3(cos(ang), 0, sin(ang))
			var side := up.cross(out).normalized()
			seg.transform = Transform3D(Basis(side, up, side.cross(up)), (prev + nxt) * 0.5)
			root.add_child(seg)
			var tu := lerpf(float(pd[3]), float(pd[4]), u)
			_crack_segs.append([seg, lerpf(t0, t1, tu)])
			if pi == 0 and k == n / 2:
				_crack_mid = nxt
			prev = nxt
	# Mud chips and eave dust (from the shake).
	var mud := Kit.mat("#a87a4c", 0.95)
	for k in 10:
		var ang := a0 + rng.randf_range(-0.3, 0.3)
		var st := Vector3(cos(ang) * (r + 0.05), rng.randf_range(0.8, h), sin(ang) * (r + 0.05)) + c
		var chip := Kit.box(root, Vector3(0.05, 0.035, 0.04) * rng.randf_range(0.7, 1.4), st, mud)
		chip.visible = false
		_chips.append([chip, st, rng.randf_range(0.0, 0.9), Vector3(cos(ang), 0, sin(ang)) * rng.randf_range(0.2, 0.6)])
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.82, 0.72, 0.56, 0.0)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dm.billboard_keep_scale = true
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var gtex := GradientTexture2D.new()
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.5)
	gtex.fill_to = Vector2(1.0, 0.5)
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	gtex.gradient = gr
	dm.albedo_texture = gtex
	for k in 8:
		var ang := a0 + rng.randf_range(-0.5, 0.5)
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.5, 0.5)
		q.mesh = qm
		q.material_override = dm.duplicate()
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(q)
		_eave_dust.append([q, Vector3(cos(ang) * (r * 1.25), h + 0.05, sin(ang) * (r * 1.25)) + c, rng.randf_range(0.0, 0.6)])


func _ripple_build(root: Node3D) -> void:
	var rd: Dictionary = _p.get("ripple", {})
	if rd.is_empty():
		return
	var at := Vector3(float(rd["at"][0]), 0, float(rd["at"][1]))
	var wood := Kit.mat("#5e4428", 0.85)
	# A low wooden stand, the open matka on it, full to the neck.
	Kit.box(root, Vector3(0.5, 0.06, 0.5), at + Vector3(0, 0.42, 0), wood)
	for sx: float in [-0.21, 0.21]:
		for sz: float in [-0.21, 0.21]:
			Kit.box(root, Vector3(0.05, 0.42, 0.05), at + Vector3(sx, 0.21, sz), wood)
	var clay := Kit.mat("#9a4a2a", 0.85)
	Kit.ball(root, 0.27, at + Vector3(0, 0.7, 0), clay, 24, Vector3(1, 0.92, 1))
	Kit.cyl(root, 0.17, 0.15, 0.1, at + Vector3(0, 0.98, 0), clay, 20)
	var lip := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.15
	tm.outer_radius = 0.19
	lip.mesh = tm
	lip.material_override = Kit.mat("#8a3e22", 0.85)
	lip.position = at + Vector3(0, 1.03, 0)
	root.add_child(lip)
	_water_mat = Kit.shader(WATER)
	_pot_top = at + Vector3(0, 1.02, 0)
	var w := Kit.quad(root, Vector2(0.32, 0.32), _pot_top, _water_mat, Vector3(-PI / 2, 0, 0))
	w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# A brass lota beside it.
	Kit.cyl(root, 0.06, 0.08, 0.14, at + Vector3(0.18, 0.52, 0.12), Kit.mat("#c9a24a", 0.3, 0.9), 14)


func _charpai(root: Node3D, at: Vector3, yaw: float) -> void:
	var n := Node3D.new()
	n.position = at
	n.rotation.y = yaw
	root.add_child(n)
	var wood := Kit.mat("#6a4a2a", 0.8)
	for sx: float in [-0.95, 0.95]:
		Kit.box(n, Vector3(0.07, 0.07, 1.0), Vector3(sx, 0.42, 0), wood)
	for sz: float in [-0.48, 0.48]:
		Kit.box(n, Vector3(1.97, 0.07, 0.07), Vector3(0, 0.42, sz), wood)
	for sx: float in [-0.95, 0.95]:
		for sz: float in [-0.48, 0.48]:
			Kit.cyl(n, 0.045, 0.04, 0.45, Vector3(sx, 0.22, sz), wood, 8)
	Kit.box(n, Vector3(1.85, 0.02, 0.9), Vector3(0, 0.43, 0), Kit.mat("#c8b27a", 0.95))


func _well(root: Node3D) -> void:
	var stone := Kit.mat("#a89070", 0.9)
	var lime := Kit.mat("#e2dccb", 0.9)
	var wood := Kit.mat("#5e4428", 0.8)
	Kit.cyl(root, 1.9, 2.0, 0.3, WELL_AT + Vector3(0, 0.15, 0), stone, 28)
	Kit.cyl(root, 0.95, 1.0, 0.75, WELL_AT + Vector3(0, 0.67, 0), lime, 24)
	Kit.cyl(root, 0.78, 0.78, 0.76, WELL_AT + Vector3(0, 0.68, 0), Kit.mat("#141210", 0.95), 24)
	for s: float in [-1.0, 1.0]:
		Kit.box(root, Vector3(0.28, 2.0, 0.28), WELL_AT + Vector3(s * 1.0, 1.3, 0), lime)
	Kit.rod(root, WELL_AT + Vector3(-1.1, 2.25, 0), WELL_AT + Vector3(1.1, 2.25, 0), 0.06, wood, 8)
	Kit.cyl(root, 0.16, 0.16, 0.08, WELL_AT + Vector3(0, 2.1, 0), Kit.mat("#3a3a3a", 0.5, 0.6), 16, Vector3(0, 0, PI / 2))
	_bucket = Node3D.new()
	root.add_child(_bucket)
	Kit.cyl(_bucket, 0.17, 0.13, 0.26, Vector3(0, 0.13, 0), Kit.mat("#8a8a82", 0.4, 0.7), 14)
	_rope_up = MeshInstance3D.new()
	root.add_child(_rope_up)


func _rope(mi: MeshInstance3D, a: Vector3, b: Vector3, r: float) -> void:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = maxf((b - a).length(), 0.01)
	c.radial_segments = 6
	mi.mesh = c
	if mi.material_override == null:
		mi.material_override = Kit.mat("#b8a47a", 0.9)
	var up := (b - a).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	mi.transform = Transform3D(Basis(side, up, side.cross(up)), (a + b) * 0.5)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var inv := gt.affine_inverse()
	# The well: the bucket climbs from the dark water to the lip; the rope runs from the pulley down to it.
	var wd: Dictionary = _p.get("well", {})
	var pulley := WELL_AT + Vector3(0, 2.1, 0.0)
	var wu := Motion.in_out(Motion.seg(t, float(wd.get("from", 0.0)), float(wd.get("to", 1.0))))
	var by := lerpf(-1.6, 0.85, wu)
	_bucket.position = WELL_AT + Vector3(0.1, by, 0.05)
	_rope(_rope_up, pulley + Vector3(0.1, -0.12, 0.05), _bucket.position + Vector3(0, 0.3, 0), 0.012)
	if ctx.has("actor") and wd.has("actor"):
		var a = ctx["actor"].call(String(wd["actor"]))
		if a != null and a.visible:
			Crawl.long_arms(a, 1.35)
			# Hand over hand on the rope in front of her chest.
			var ay := float(a.rotation.y)
			var fwd := Vector3(sin(ay), 0, cos(ay))
			var chest: Vector3 = a.bone_world("spine_03")
			var ph := t * 3.2
			var hi := chest + fwd * 0.32 + Vector3(0, 0.32, 0)
			var lo := chest + fwd * 0.3 + Vector3(0, -0.05, 0)
			var k1 := 0.5 + 0.5 * sin(ph)
			var k2 := 0.5 + 0.5 * sin(ph + PI)
			a.aim_hand("l", lo.lerp(hi, k1), 1.0)
			a.aim_hand("r", lo.lerp(hi, k2), 1.0)
	# Tyres: rolling beside the runner's right hand, the stick from the hand to the hub.
	if ctx.has("actor"):
		for aid in _tyres:
			var e: Array = _tyres[aid]
			var a = ctx["actor"].call(aid)
			var tn: Node3D = e[0]
			var stick: MeshInstance3D = e[1]
			tn.visible = a != null and a.visible
			stick.visible = tn.visible
			if not tn.visible:
				continue
			var ay := float(a.rotation.y)
			var fwd := Vector3(sin(ay), 0, cos(ay))
			var right := -Vector3(cos(ay), 0, -sin(ay))
			var root_p: Vector3 = a.global_position
			var hub := root_p + fwd * 0.7 + right * 0.28 + Vector3(0, 0.31, 0)
			var lyaw := ay - gt.basis.get_euler().y
			var rolled := (inv * root_p).dot(Vector3(sin(lyaw), 0, cos(lyaw))) / 0.31
			tn.transform = Transform3D(Basis(Vector3.UP, lyaw) * Basis(Vector3(1, 0, 0), rolled) * Basis(Vector3(0, 0, 1), 0.06 * sin(t * 7.0)), inv * hub)
			Crawl.long_arms(a, 1.2)
			var hand := root_p + fwd * 0.3 + right * 0.25 + Vector3(0, 0.55, 0)
			a.aim_hand("r", hand, 1.0)
			_rope(stick, inv * hand, inv * (hub + Vector3(0, 0.05, 0) - fwd * 0.05), 0.012)
			stick.material_override = Kit.mat("#7a5a32", 0.8)
		# Pots on heads, a hand up steadying them.
		for aid in _pots:
			var a = ctx["actor"].call(aid)
			var pn: Node3D = _pots[aid]
			pn.visible = a != null and a.visible
			if not pn.visible:
				continue
			var top: Vector3 = a.bone_world("Head") + Vector3(0, 0.3, 0)
			var ay := float(a.rotation.y)
			pn.transform = Transform3D(Basis(Vector3.UP, ay - gt.basis.get_euler().y) * Basis(Vector3(0, 0, 1), 0.04 * sin(t * 6.0)), inv * top)
			Crawl.long_arms(a, 1.5)
			a.aim_hand("l", top + Vector3(0, 0.25, 0) + Vector3(cos(ay), 0, -sin(ay)) * 0.18, 1.0)
	# Dust wisps drifting in from the desert, low over the ground, fading in and out.
	var dd: Dictionary = _p.get("dust", {})
	if _dust != null:
		var u := Motion.seg(t, float(dd["from"]), float(dd["to"]))
		_dust_mat.set_shader_parameter("a", sin(PI * u) if u > 0.0 and u < 1.0 else 0.0)
		var dir2: Array = dd.get("dir", [0.0, -1.0])
		var dir := Vector3(float(dir2[0]), 0, float(dir2[1])).normalized()
		var mm := _dust.multimesh
		for k in mm.instance_count:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(Vector2i(k, 77))
			var life := rng.randf_range(2.5, 4.0)
			var age := fposmod(t + rng.randf() * life, life)
			var start := Vector3(rng.randf_range(-12, 12), rng.randf_range(0.1, 0.8), rng.randf_range(-16, 2)) - dir * 6.0
			var p := start + dir * age * 3.0
			var face := Basis.looking_at(-dir, Vector3.UP)
			mm.set_instance_transform(k, Transform3D(face.rotated(Vector3.UP, PI / 2) * Basis.from_scale(Vector3.ONE * (0.8 + age * 0.4)), p))
			mm.set_instance_custom_data(k, Color(sin(PI * age / life), 0, 0, 0))
	# The crack grows; chips fall; the thatch sheds dust.
	var cd: Dictionary = _p.get("crack", {})
	for e in _crack_segs:
		(e[0] as Node3D).visible = t >= float(e[1])
	if not cd.is_empty():
		var sk := float(cd.get("shake", cd["from"]))
		for e in _chips:
			var a := t - sk - float(e[2])
			var nd: Node3D = e[0]
			nd.visible = a > 0.0 and a < 1.2
			if nd.visible:
				var st: Vector3 = e[1]
				var y := maxf(st.y - 4.9 * a * a, 0.02)
				nd.position = Vector3(st.x, y, st.z) + (e[3] as Vector3) * minf(a, 0.5)
				nd.rotation = Vector3(a * 9.0, a * 7.0, 0)
		for e in _eave_dust:
			var a := t - sk - float(e[2])
			var q: MeshInstance3D = e[0]
			q.visible = a > 0.0 and a < 2.0
			if q.visible:
				q.position = (e[1] as Vector3) + Vector3(0.1 * a, -0.6 * a, 0.1 * a)
				q.scale = Vector3.ONE * (0.4 + 1.2 * a)
				(q.material_override as StandardMaterial3D).albedo_color.a = 0.45 * sin(PI * a / 2.0)
	if _water_mat != null:
		_water_mat.set_shader_parameter("s", t - float((_p.get("ripple", {}) as Dictionary).get("t", 1e9)))
	return {"pot": gt * _pot_top, "crack": gt * _crack_mid, "well": gt * (WELL_AT + Vector3(0, 1.2, 0)), "lane": gt * Vector3(0, 1.2, -4.0),
		"tree": gt * (TREE_AT + Vector3(0, 2.0, 0)), "wall": gt * _hero_wall}
