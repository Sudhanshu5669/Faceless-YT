extends RefCounted
## Inside the 800 mm escape pipe at the rubble face (line 19 onward): the rat-hole miners' workplace.
##
## Local frame: the pipe's axis runs along x at y = R (its floor at y = 0), from the mouth far back at -x to the face
## at x = 0, where broken rock, a twisted rib and soil fill the bore. A festoon cable with two bulbs along the crown,
## the yellow air duct on the floor. Lit by the miners' headlamps and the bulbs; nothing else reaches in here.
##
## params:
##   floor   {actor id: [x, z]}: where each miner lies (prone, head toward the face; the gag poses them)
##   digger  {"id", "strikes": [t, ...]}: hammer on chisel at the face, chips flying at each strike
##   hauler  {"id", "t0", "t1"}: drags a tasla of spoil back toward the mouth between t0 and t1
##   through {"t", "light"} (line 21): the face caves in and light from the trapped side pours through
## anchors: face (the chisel's point), cam (a spot just off the face looking back down the pipe)

const Motion = preload("res://scripts/timeline/motion.gd")

const R := 0.4
const LEN := 14.0

const NOISE_GLSL := """
float h3(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float n3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
float fbm(vec3 p) { return n3(p) * 0.55 + n3(p * 2.1 + 7.0) * 0.3 + n3(p * 4.3 + 3.0) * 0.15; }
"""

## Mill-scaled steel gone rusty, scuffed bright along the floor where bodies and pans slide.
const STEEL_SHADER := """
shader_type spatial;
render_mode cull_disabled;
varying vec3 lp;
void vertex() { lp = VERTEX; }
//NOISE
void fragment() {
	float rust = smoothstep(0.45, 0.75, fbm(lp * vec3(3.0, 1.2, 3.0)));
	vec3 col = mix(vec3(0.17, 0.16, 0.155), vec3(0.36, 0.18, 0.08), rust * 0.8);
	float floor_wear = smoothstep(-0.25, -0.38, lp.z) ;
	col = mix(col, vec3(0.5, 0.48, 0.45), floor_wear * 0.0);
	ALBEDO = col * (0.85 + 0.3 * fbm(lp * 8.0));
	METALLIC = mix(0.6, 0.1, rust);
	ROUGHNESS = mix(0.5, 0.9, rust);
}
"""

## Broken rock and soil at the face.
const ROCK_SHADER := """
shader_type spatial;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
//NOISE
void fragment() {
	float n = fbm(wp * 4.0);
	ALBEDO = mix(vec3(0.3, 0.27, 0.23), vec3(0.45, 0.4, 0.33), n) * (0.7 + 0.4 * n3(wp * 14.0));
	ROUGHNESS = 0.95;
}
"""

var _shaders := {}
var _tools := {}
var _chips: MultiMesh
var _pan: Node3D
var _face: Node3D
var _light_in: OmniLight3D
var _lamps := {}


func _shader(code: String) -> ShaderMaterial:
	if not _shaders.has(code):
		var s := Shader.new()
		s.code = code.replace("//NOISE", NOISE_GLSL)
		_shaders[code] = s
	var m := ShaderMaterial.new()
	m.shader = _shaders[code]
	return m


func _mat(color: String, rough: float = 0.85, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = rough
	m.metallic = metal
	return m


func _lit(color: String, energy: float) -> StandardMaterial3D:
	var m := _mat(color, 0.4)
	m.emission_enabled = true
	m.emission = Color(color)
	m.emission_energy_multiplier = energy
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _rod(parent: Node3D, a: Vector3, b: Vector3, r: float, mat: Material, sides: int = 8) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = a.distance_to(b)
	mesh.radial_segments = sides
	mesh.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	var y := (b - a).normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y, x.cross(y).normalized()), (a + b) * 0.5)
	parent.add_child(mi)
	return mi


func _hash(n: float) -> float:
	return fposmod(sin(n * 127.1 + 311.7) * 43758.5453, 1.0)


func _stone() -> Mesh:
	var src := SphereMesh.new()
	src.radius = 0.5
	src.height = 1.0
	src.radial_segments = 8
	src.rings = 5
	return src


func build(g: Dictionary) -> Node3D:
	var root := Node3D.new()
	# The pipe: a full steel tube with weld collars every 6 m.
	var tube := CylinderMesh.new()
	tube.top_radius = R
	tube.bottom_radius = R
	tube.height = LEN
	tube.radial_segments = 48
	tube.rings = 30
	tube.cap_top = false
	tube.cap_bottom = false
	var t := MeshInstance3D.new()
	t.mesh = tube
	t.material_override = _shader(STEEL_SHADER)
	t.rotation.z = PI * 0.5
	t.position = Vector3(-LEN * 0.5, R, 0)
	root.add_child(t)
	var x := -3.0
	while x > -LEN:
		var c := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = R - 0.03
		tm.outer_radius = R - 0.005
		tm.rings = 40
		tm.ring_segments = 6
		c.mesh = tm
		c.material_override = _mat("#2e2a27", 0.6, 0.5)
		c.rotation.z = PI * 0.5
		c.position = Vector3(x, R, 0)
		root.add_child(c)
		x -= 6.0
	# The face: broken rock, soil and a bent rib packed into the bore.
	_face = Node3D.new()
	root.add_child(_face)
	var rock := _shader(ROCK_SHADER)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2111
	for i in 34:
		var s := MeshInstance3D.new()
		s.mesh = _stone()
		s.material_override = rock
		var sz := rng.randf_range(0.12, 0.34)
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * (R - 0.05)
		s.transform = Transform3D(Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, 0)).scaled(Vector3(sz, sz * 0.8, sz)),
			Vector3(0.08 + rng.randf_range(0.0, 0.25), R + sin(a) * r, cos(a) * r))
		_face.add_child(s)
	_box(_face, Vector3(0.05, 0.9, 0.12), Vector3(0.12, R, 0.05), _mat("#5e3320", 0.75, 0.5)).rotation = Vector3(0.0, 0.0, 0.5)
	# A festoon cable along the crown, two bulbs, the duct on the floor.
	var cable := _mat("#111111", 0.6)
	_rod(root, Vector3(-LEN, 2.0 * R - 0.06, -0.12), Vector3(-0.3, 2.0 * R - 0.06, -0.12), 0.007, cable, 4)
	for bx in [-1.9, -5.5]:
		_box(root, Vector3(0.05, 0.07, 0.05), Vector3(bx, 2.0 * R - 0.12, -0.12), _lit("#ffd39a", 9.0))
		var b := OmniLight3D.new()
		b.position = Vector3(bx, 2.0 * R - 0.18, -0.1)
		b.light_color = Color("#ffcf8f")
		b.light_energy = 0.55
		b.omni_range = 2.4
		b.shadow_enabled = true
		root.add_child(b)
	_rod(root, Vector3(-LEN, 0.1, 0.24), Vector3(-0.9, 0.1, 0.24), 0.09, _mat("#e2b21b", 0.6), 12)
	# Chips off the chisel.
	_chips = MultiMesh.new()
	_chips.transform_format = MultiMesh.TRANSFORM_3D
	_chips.mesh = _stone()
	_chips.instance_count = 60
	var cmi := MultiMeshInstance3D.new()
	cmi.multimesh = _chips
	cmi.material_override = rock
	root.add_child(cmi)
	# The hauler's tasla, heaped with spoil.
	_pan = Node3D.new()
	root.add_child(_pan)
	var pan := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.23
	cm.bottom_radius = 0.16
	cm.height = 0.09
	cm.cap_top = false
	pan.mesh = cm
	var pm := _mat("#8f9398", 0.4, 0.7)
	pm.cull_mode = BaseMaterial3D.CULL_DISABLED
	pan.material_override = pm
	pan.position = Vector3(0, 0.05, 0)
	_pan.add_child(pan)
	for i in 9:
		var s := MeshInstance3D.new()
		s.mesh = _stone()
		s.material_override = rock
		var sz := 0.07 + _hash(i * 2.0) * 0.06
		s.transform = Transform3D(Basis.from_scale(Vector3(sz, sz * 0.7, sz)), Vector3((_hash(i) - 0.5) * 0.24, 0.1, (_hash(i * 3.0) - 0.5) * 0.24))
		_pan.add_child(s)
	_pan.visible = false
	# His headlamp's light bouncing back off the rock just in front of him: what lights the digger's face.
	var bounce := OmniLight3D.new()
	bounce.position = Vector3(-0.15, R, 0.0)
	bounce.light_color = Color("#ffcf9a")
	bounce.light_energy = 1.1
	bounce.omni_range = 1.6
	bounce.omni_attenuation = 1.3
	root.add_child(bounce)
	# Light from the trapped side, when the face gives way (line 21).
	_light_in = OmniLight3D.new()
	_light_in.position = Vector3(0.9, R, 0)
	_light_in.light_color = Color("#ffd9a0")
	_light_in.light_energy = 0.0
	_light_in.omni_range = 6.0
	_light_in.shadow_enabled = true
	root.add_child(_light_in)
	return root


func _tool(kind: String) -> Node3D:
	var n := Node3D.new()
	var wood := _mat("#7a5532", 0.8)
	var steel := _mat("#5e6266", 0.45, 0.75)
	if kind == "hammer":
		_rod(n, Vector3(0, -0.06, 0), Vector3(0, 0.26, 0), 0.016, wood, 8)
		_box(n, Vector3(0.13, 0.055, 0.055), Vector3(0, 0.27, 0), steel)
	else:
		_rod(n, Vector3(0, -0.12, 0), Vector3(0, 0.12, 0), 0.011, steel, 6)
		_box(n, Vector3(0.012, 0.03, 0.02), Vector3(0, 0.135, 0), _mat("#c9ccd0", 0.3, 0.85))
	return n


func pose(root: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	# Everything in this gag's own frame: the anchor it sits on is turned, so map through the root's transform.
	var G: Transform3D = root.global_transform
	var Gi: Transform3D = G.affine_inverse()
	# The miners lie along the pipe, head toward the face, propped on their elbows.
	for id in p.get("floor", {}):
		var a = ctx["actor"].call(String(id)) if ctx.has("actor") else null
		if a == null:
			continue
		var at: Array = p["floor"][id]
		a.global_transform = Transform3D(G.basis * Basis.from_euler(Vector3(1.38, PI * 0.5, 0.0)), G * Vector3(float(at[0]), 0.02, float(at[1])))
		if not _lamps.has(id):
			var lamp := SpotLight3D.new()
			lamp.light_color = Color("#fff1d8")
			lamp.light_energy = 2.2
			lamp.spot_range = 5.0
			lamp.spot_angle = 30.0
			lamp.shadow_enabled = true
			root.add_child(lamp)
			_lamps[id] = lamp
		var hd: Vector3 = Gi * (a.anchor_points()[String(id) + ".head"]["pos"] as Vector3)
		(_lamps[id] as SpotLight3D).transform = Transform3D(Basis.looking_at(Vector3(1, -0.15, 0).normalized()), hd + Vector3(0.12, 0.2, 0))
	var face_pt := Vector3(0.06, R - 0.02, -0.05)
	# The digger: left hand holds the chisel's point on the face; the right swings the club hammer onto it.
	if p.has("digger"):
		var dp: Dictionary = p["digger"]
		var id := String(dp.get("id", ""))
		var a = ctx["actor"].call(id) if ctx.has("actor") else null
		if a != null:
			for kind in ["hammer", "chisel"]:
				if not _tools.has(id + kind):
					var n := _tool(kind)
					root.add_child(n)
					_tools[id + kind] = n
			var strikes: Array = dp.get("strikes", [])
			var swing := 0.0          # 0 = on the chisel, 1 = drawn back
			for st in strikes:
				# Up on the back swing, fast down onto the chisel.
				var s0 := float(st)
				if t >= s0 - 0.32 and t < s0 - 0.12:
					swing = Motion.out_cubic(Motion.seg(t, s0 - 0.32, s0 - 0.12))
				elif t >= s0 - 0.12 and t < s0:
					swing = 1.0 - Motion.in_cubic(Motion.seg(t, s0 - 0.12, s0))
			var chisel_back := face_pt + Vector3(-0.22, 0.04, 0.0)
			var chisel := _tools[id + "chisel"] as Node3D
			chisel.transform = Transform3D(Basis(Vector3.BACK, -PI * 0.5), (face_pt + chisel_back) * 0.5)
			a.aim_hand("l", G * (chisel_back + Vector3(-0.02, 0, 0.03)), 1.0)
			var hit := chisel_back + Vector3(-0.08, 0.03, 0.0)
			var raised := chisel_back + Vector3(-0.28, 0.22, -0.12)
			var hand := hit.lerp(raised, swing)
			a.aim_hand("r", G * hand, 1.0)
			var hammer := _tools[id + "hammer"] as Node3D
			var up := (Vector3(1, 0.4, 0) * (1.0 - swing) + Vector3(0.3, 1.0, 0.1) * swing).normalized()
			var xb := up.cross(Vector3.BACK).normalized()
			hammer.transform = Transform3D(Basis(xb, up, xb.cross(up)), hand)
			# Chips at each strike.
			for i in _chips.instance_count:
				var st_i := float(strikes[i % maxi(strikes.size(), 1)]) if strikes.size() > 0 else 1.0e9
				var age := t - st_i - _hash(i * 1.3) * 0.04
				var xf := Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), face_pt)
				if age > 0.0 and age < 0.6:
					var v := Vector3(-1.0 - _hash(i * 2.9) * 1.8, 0.6 + _hash(i * 4.4) * 1.2, (_hash(i * 6.6) - 0.5) * 1.6)
					var pos := face_pt + v * age + Vector3(0, -4.9 * age * age, 0)
					pos.y = maxf(pos.y, 0.03)
					var sz := 0.012 + _hash(i * 8.1) * 0.025
					xf = Transform3D(Basis.from_euler(Vector3(age * 12.0, i, 0)).scaled(Vector3.ONE * sz), pos)
				_chips.set_instance_transform(i, xf)
	# The hauler drags a tasla of spoil back toward the mouth.
	if p.has("hauler"):
		var hp: Dictionary = p["hauler"]
		var a = ctx["actor"].call(String(hp.get("id", ""))) if ctx.has("actor") else null
		_pan.visible = a != null
		if a != null:
			var k := Motion.in_out(Motion.seg(t, float(hp.get("t0", 1.0e9)), float(hp.get("t1", 1.0e9))))
			var hd: Vector3 = Gi * (a.anchor_points()[String(hp.get("id", "")) + ".head"]["pos"] as Vector3)
			var pan_at := Vector3(hd.x + 0.45 - 0.35 * k, 0.0, 0.05)
			_pan.position = pan_at
			for side in ["l", "r"]:
				var sg := 1.0 if side == "l" else -1.0
				a.aim_hand(side, G * (pan_at + Vector3(-0.15, 0.1, sg * 0.18)), 1.0)
	# Line 21: the last of the face falls away and light pours in from the trapped side.
	if p.has("through"):
		var tp: Dictionary = p["through"]
		var k := Motion.out_cubic(Motion.seg(t, float(tp.get("t", 1.0e9)), float(tp.get("t", 1.0e9)) + 0.6))
		_face.position = Vector3(0.8 * k, -0.25 * k, 0.0)
		_light_in.light_energy = float(tp.get("light", 3.0)) * k
	return {"face": G * face_pt, "cam": G * Vector3(0.0, R + 0.12, 0.22)}
