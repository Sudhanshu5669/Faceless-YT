## The waiting tent at the range, 11 May 1998: an olive ridge tent with its front flaps tied back, a long bench packed
## with bored scientists in the shade, a clock hung on the back pole, water bottles and a clay matka on the sand; outside,
## a tumbleweed rolls past with the wind.
##
## Local frame: the tent's centre on the sand at the origin, y up, the open front facing +z (cameras usually stand
## outside at +z looking in). The bench runs along x at z BENCH_Z.
##
## params:
##   clock      [[t, "HH:MM"], ...]   the clock on the back pole: between keys the hands whirl round (a time-lapse,
##              eased); one-minute keys clunk
##   sitters    [actor ids]   the bench follows their hips (its height from their average)
##   chins      [actor ids]   both hands propped under the chin, elbows on knees (bored)
##   fan        [actor ids]   fans himself with a buff file folder in the right hand (fast, limp-wristed)
##   tumbleweed {"from": t, "to": t, "a": [x, z], "b": [x, z], "r": 0.38, "hops": 4}   a ball of dry twigs rolls from a to b
##              (eased in and out a little), hopping and spinning as it goes
##   sweep      {"from": t, "to": t}   time-lapse light: a hard sunbeam through the opening slides across the floor and
##              the faces from left to right
## anchors: clock, bench, mouth (the middle of the opening), tumbleweed
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")
const PH := "incoming/polyhaven_pokhran/models/"
const HL := 2.5          # half length (z)
const HW := 2.1          # half width (x)
const WALL := 1.45
const RIDGE := 2.7
const BENCH_Z := -0.55
const CLOCK_AT := Vector3(0.0, 1.9, -HL + 0.06)
const A0_MIN := 57.4
const A0_HOUR := 305.5
const A0_SEC := 180.0

const CANVAS := """
shader_type spatial;
render_mode cull_disabled;
varying vec3 wp;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 q = wp.xz + vec2(wp.y * 0.7);
	float n = n2(q * 2.0) * 0.5 + n2(q * 7.0) * 0.3 + n2(q * 30.0) * 0.2;
	vec3 c = vec3(0.30, 0.32, 0.20) * (0.8 + 0.35 * n);
	// Sun-faded patches and dusty streaks.
	c = mix(c, vec3(0.42, 0.41, 0.30), smoothstep(0.6, 0.85, n2(q * 0.8 + 3.0)) * 0.5);
	ALBEDO = c;
	ROUGHNESS = 0.95;
	// A little light through the weave from the sunny side.
	BACKLIGHT = vec3(0.35, 0.3, 0.15);
}
"""

var _p := {}
var _bench: Node3D
var _min_hand: Node3D
var _hour_hand: Node3D
var _sec_hand: Node3D
var _tw: Node3D
var _files := {}
var _beam: SpotLight3D


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "wait_tent"))
	var canvas := Kit.shader(CANVAS)
	var pole := Kit.mat("#5a4630", 0.8)
	var rope := Kit.mat("#9a8a66", 0.9)
	# The canvas: two roof slopes, two side walls, the back gable; the front gable open with its flaps rolled and tied.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nu := 12
	for s: float in [-1.0, 1.0]:
		for i in nu:
			var z0 := -HL + 2.0 * HL * float(i) / nu
			var z1 := -HL + 2.0 * HL * float(i + 1) / nu
			var sag0 := 0.07 * sin(PI * float(i) / nu)
			var sag1 := 0.07 * sin(PI * float(i + 1) / nu)
			_quad(st, [Vector3(0, RIDGE, z0), Vector3(0, RIDGE, z1), Vector3(s * HW, WALL - sag1, z1), Vector3(s * HW, WALL - sag0, z0)])
			_quad(st, [Vector3(s * HW, WALL - sag0, z0), Vector3(s * HW, WALL - sag1, z1), Vector3(s * (HW + 0.08), 0, z1), Vector3(s * (HW + 0.08), 0, z0)])
	var gb := [Vector3(-HW - 0.08, 0, -HL), Vector3(HW + 0.08, 0, -HL), Vector3(HW, WALL, -HL), Vector3(0, RIDGE, -HL), Vector3(-HW, WALL, -HL)]
	for k in [[0, 1, 2], [0, 2, 4], [4, 2, 3]]:
		for idx in k:
			st.add_vertex(gb[idx])
	# The front flaps, rolled up into sausages along each side of the opening and tied.
	st.generate_normals()
	var tent := MeshInstance3D.new()
	tent.mesh = st.commit()
	tent.material_override = canvas
	root.add_child(tent)
	for s: float in [-1.0, 1.0]:
		Kit.rod(root, Vector3(s * 0.25, RIDGE - 0.15, HL + 0.02), Vector3(s * (HW - 0.1), WALL - 0.05, HL + 0.02), 0.11, canvas, 10)
		Kit.rod(root, Vector3(s * (HW - 0.05), WALL, HL + 0.02), Vector3(s * (HW + 0.05), 0.1, HL + 0.02), 0.1, canvas, 10)
		for k in 2:
			var tp := Vector3(s * (0.8 + 0.7 * k), lerpf(RIDGE - 0.15, WALL - 0.05, (0.55 + 0.7 * k) / (HW - 0.35)), HL + 0.02)
			Kit.cyl(root, 0.125, 0.125, 0.03, tp, rope, 10, Vector3(0, 0, PI / 2 * s))
	# Poles, ridge, guy ropes and pegs.
	for zz: float in [-HL, HL]:
		Kit.rod(root, Vector3(0, 0, zz), Vector3(0, RIDGE + 0.12, zz), 0.04, pole, 8)
		Kit.rod(root, Vector3(0, RIDGE + 0.05, zz), Vector3(0, 0.02, zz + signf(zz) * 1.6), 0.007, rope, 4)
	for s: float in [-1.0, 1.0]:
		for k in 3:
			var z := -HL + 0.4 + (2.0 * HL - 0.8) * float(k) / 2.0
			Kit.rod(root, Vector3(s * HW, WALL, z), Vector3(s * (HW + 1.3), 0.02, z), 0.007, rope, 4)
			Kit.rod(root, Vector3(s * (HW + 1.3), -0.1, z), Vector3(s * (HW + 1.3), 0.14, z), 0.02, pole, 6)
	# A groundsheet inside.
	Kit.box(root, Vector3(2.0 * HW - 0.2, 0.01, 2.0 * HL - 0.3), Vector3(0, 0.005, -0.1), Kit.mat("#4a4a3a", 0.95))
	# The bench (its height follows the sitters).
	_bench = Node3D.new()
	_bench.position = Vector3(0, 0.45, BENCH_Z)
	root.add_child(_bench)
	var wood := Kit.mat("#6a4a2c", 0.75)
	Kit.box(_bench, Vector3(3.9, 0.05, 0.34), Vector3(0, 0, 0), wood)
	for bx: float in [-1.75, 0.0, 1.75]:
		Kit.box(_bench, Vector3(0.05, 1.0, 0.28), Vector3(bx, -0.5, 0), wood)
	# The clock on the back pole, facing the opening.
	var clock := Kit.model(PH + "wall_clock/wall_clock_2k.gltf")
	clock.position = CLOCK_AT
	clock.scale = Vector3.ONE * 2.2
	root.add_child(clock)
	_min_hand = clock.find_child("wall_clock_minute_hand", true, false) as Node3D
	_hour_hand = clock.find_child("wall_clock_hours_hand", true, false) as Node3D
	_sec_hand = clock.find_child("wall_clock_second_hand", true, false) as Node3D
	Kit.rod(root, CLOCK_AT + Vector3(0, 0.36, 0.0), Vector3(0, CLOCK_AT.y + 0.5, -HL + 0.02), 0.006, rope, 4)
	# Water: a clay matka on a ring, steel bottles, a stack of files and a crate on the sand.
	var matka := Node3D.new()
	matka.position = Vector3(1.7, 0, 1.2)
	root.add_child(matka)
	Kit.ball(matka, 0.24, Vector3(0, 0.27, 0), Kit.mat("#9a4a2a", 0.85), 20, Vector3(1, 0.95, 1))
	Kit.cyl(matka, 0.1, 0.12, 0.08, Vector3(0, 0.52, 0), Kit.mat("#8a4224", 0.85), 16)
	Kit.cyl(matka, 0.2, 0.2, 0.06, Vector3(0, 0.03, 0), Kit.mat("#5a4a30", 0.9), 16)
	for k in 3:
		var th := Kit.model(PH + "plastic_thermos/plastic_thermos_2k.gltf")
		th.position = Vector3(-1.75 + 0.16 * k, 0, 1.0 + 0.1 * (k % 2))
		th.rotation.y = 0.7 * k
		root.add_child(th)
	var crate := Kit.model(PH + "wooden_military_crate/wooden_military_crate_2k.gltf")
	crate.position = Vector3(-1.5, 0, -1.8)
	crate.rotation.y = 0.2
	root.add_child(crate)
	for k in 4:
		Kit.box(root, Vector3(0.3, 0.025, 0.24), Vector3(-1.5, 0.52 + 0.026 * k, -1.8), Kit.mat("#c8a868" if k % 2 == 0 else "#b89858", 0.9), Vector3(0, 0.1 * k, 0))
	# Warm bounce from the sunlit sand in front, so faces in the shade read.
	Kit.omni(root, Vector3(0, 0.5, 1.6), Color(1.0, 0.82, 0.6), 0.9, 4.5, false, 0.2)
	# The time-lapse sunbeam.
	_beam = Kit.spot(root, Vector3(0, 6.0, 7.0), Vector3(0, 0.6, BENCH_Z), Color(1.0, 0.9, 0.7), 0.0, 14.0, 9.0, true, 0.2)
	# Files for the fanners.
	for aid in _p.get("fan", []):
		var f := Node3D.new()
		Kit.box(f, Vector3(0.24, 0.32, 0.012), Vector3(0, 0.16, 0), Kit.mat("#d9b878", 0.9))
		Kit.box(f, Vector3(0.22, 0.3, 0.014), Vector3(0.01, 0.15, 0), Kit.mat("#f0ece0", 0.9))
		root.add_child(f)
		_files[String(aid)] = f
	# The tumbleweed: a loose ball of thin dry twigs.
	var tw: Dictionary = _p.get("tumbleweed", {})
	if not tw.is_empty():
		_tw = Node3D.new()
		_tw.name = "tumbleweed"
		root.add_child(_tw)
		var r := float(tw.get("r", 0.38))
		var rng := Kit.rng("tumbleweed")
		var twig := Kit.mat("#a08a5e", 0.95)
		var twig2 := Kit.mat("#7a6644", 0.95)
		for k in 150:
			var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
			var p0 := d * r * rng.randf_range(0.2, 0.95)
			var bend := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
			var p1 := (p0 + bend * r * rng.randf_range(0.35, 0.8)).limit_length(r)
			Kit.rod(_tw, p0, p1, rng.randf_range(0.004, 0.009), twig if k % 3 != 0 else twig2, 4)
	return root


static func _quad(st: SurfaceTool, q: Array) -> void:
	for k in [0, 1, 2, 0, 2, 3]:
		st.add_vertex(q[k])


static func _minutes(s: String) -> float:
	var parts := s.split(":")
	return float(int(parts[0]) * 60 + int(parts[1]))


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var inv := gt.affine_inverse()
	# The clock.
	var keys: Array = _p.get("clock", [[0.0, "09:00"]])
	var m := _minutes(String(keys[0][1]))
	var whirl := 0.0
	for i in range(1, keys.size()):
		var a: Array = keys[i - 1]
		var b: Array = keys[i]
		if t >= float(a[0]):
			var u := Motion.seg(t, float(a[0]), float(b[0]))
			var dm := _minutes(String(b[1])) - _minutes(String(a[1]))
			var e := Motion.out_back(clampf((u - 0.75) / 0.25, 0.0, 1.0), 2.4) if absf(dm) <= 2.0 else Motion.in_out(u)
			m = _minutes(String(a[1])) + dm * e
			if absf(dm) > 2.0 and u > 0.0 and u < 1.0:
				whirl = 1.0
	_min_hand.rotation.z = -deg_to_rad(fmod(m, 60.0) / 60.0 * 360.0 - A0_MIN)
	_hour_hand.rotation.z = -deg_to_rad(fmod(m / 60.0, 12.0) / 12.0 * 360.0 - A0_HOUR)
	var sec: float = floor(t) * 6.0 + 6.0 * Motion.out_back(clampf(fmod(t, 1.0) / 0.15, 0.0, 1.0), 2.0)
	if whirl > 0.0:
		sec = m * 360.0
	_sec_hand.rotation.z = -deg_to_rad(sec - A0_SEC)
	# The time-lapse sunbeam slides across the bench.
	var sw: Dictionary = _p.get("sweep", {})
	if not sw.is_empty():
		var u := Motion.seg(t, float(sw["from"]), float(sw["to"]))
		var on := u > 0.0 and u < 1.0
		_beam.light_energy = 9.0 * sin(PI * u) if on else 0.0
		var tgt := Vector3(lerpf(-2.4, 2.4, u), 0.7, BENCH_Z + 0.2)
		_beam.look_at_from_position(gt * Vector3(lerpf(4.0, -4.0, u), 6.0, 7.0), gt * tgt, Vector3.UP)
	# The tumbleweed.
	var tw: Dictionary = _p.get("tumbleweed", {})
	if _tw != null:
		var t0 := float(tw["from"])
		var t1 := float(tw["to"])
		var r := float(tw.get("r", 0.38))
		_tw.visible = t >= t0 - 0.05 and t <= t1 + 0.05
		var u := clampf((t - t0) / maxf(t1 - t0, 0.01), 0.0, 1.0)
		var a2: Array = tw["a"]
		var b2: Array = tw["b"]
		var a := Vector3(float(a2[0]), 0, float(a2[1]))
		var b := Vector3(float(b2[0]), 0, float(b2[1]))
		var pos := a.lerp(b, u)
		var hops := float(tw.get("hops", 4))
		var hop := absf(sin(u * hops * PI)) * (0.45 + 0.25 * sin(u * 7.0))
		var dist := (b - a).length() * u
		var axis := Vector3.UP.cross((b - a).normalized()).normalized()
		_tw.position = pos + Vector3(0, r + hop, 0)
		_tw.basis = Basis(axis, dist / r) * Basis(Vector3(0, 1, 0), 0.4 * sin(u * 9.0))
		# A little squash on each landing.
		var land := 1.0 - clampf(hop / 0.12, 0.0, 1.0)
		_tw.scale = Vector3(1.0 + 0.12 * land, 1.0 - 0.15 * land, 1.0 + 0.12 * land)
	if not ctx.has("actor"):
		return _anchors(gt)
	# Bench height from the sitters' hips.
	var hs := 0.0
	var n := 0
	for aid in _p.get("sitters", []):
		var a = ctx["actor"].call(String(aid))
		if a != null and a.visible:
			var hip: Vector3 = inv * ((a.bone_world("thigh_l") + a.bone_world("thigh_r")) * 0.5)
			hs += hip.y
			n += 1
	if n > 0:
		_bench.position.y = hs / n - 0.09
	# Chins on fists.
	for aid in _p.get("chins", []):
		var a = ctx["actor"].call(String(aid))
		if a == null or not a.visible:
			continue
		Crawl.long_arms(a, 1.25)
		var ay := float(a.rotation.y)
		var fwd := Vector3(sin(ay), 0, cos(ay))
		var left := Vector3(cos(ay), 0, -sin(ay))
		var head: Vector3 = a.bone_world("Head")
		var chin := head + fwd * 0.16 + Vector3(0, -0.12, 0)
		a.aim_hand("l", chin + left * 0.06, 1.0)
		a.aim_hand("r", chin - left * 0.06, 1.0)
	# Fanning with a file.
	for aid in _files:
		var a = ctx["actor"].call(aid)
		var f: Node3D = _files[aid]
		f.visible = a != null and a.visible
		if not f.visible:
			continue
		Crawl.long_arms(a, 1.3)
		var ay := float(a.rotation.y)
		var fwd := Vector3(sin(ay), 0, cos(ay))
		var left := Vector3(cos(ay), 0, -sin(ay))
		var chest: Vector3 = a.bone_world("spine_03")
		var flap := sin(t * 18.0)
		var hand := chest + fwd * 0.3 - left * 0.12 + Vector3(0, 0.22, 0)
		a.aim_hand("r", hand, 1.0)
		var fl := inv * hand
		f.transform = Transform3D(Basis(inv.basis * Vector3.UP, ay - gt.basis.get_euler().y + PI) * Basis(Vector3(0, 1, 0), 0.5 * flap) * Basis(Vector3(1, 0, 0), -0.3), fl)
	return _anchors(gt)


func _anchors(gt: Transform3D) -> Dictionary:
	return {"clock": gt * (CLOCK_AT + Vector3(0, 0, 0.05)), "bench": gt * Vector3(0, 1.0, BENCH_Z),
		"mouth": gt * Vector3(0, 1.2, HL), "tumbleweed": _tw.global_position if _tw != null else gt * Vector3.ZERO}
