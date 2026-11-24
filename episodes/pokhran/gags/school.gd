## A school courtyard in India on National Technology Day (11 May): a cream-and-maroon two-storey schoolhouse with an
## arched verandah and green-shuttered windows, tricolour bunting, a cloth banner, trestle tables of science projects (a
## model rocket, a paper windmill, a satellite dish, a volcano); the hero kid's cardboard satellite on a string.
##
## Local frame: the hero kid stands at the origin facing +z (cameras at +z looking -z); the tables at z -1.2; the
## banner strung across at y 2.6, z -1.6; the building's verandah at z -6.
##
## params:
##   banner    ["LINE 1", "LINE 2"]   the banner's text
##   satellite {"actor": id, "lift": t}   a cardboard satellite (gold-foil body, blue solar panels, a dish) dangling
##             on a string from the actor's right hand: held low, then lifted high on `lift`, swinging and spinning
## anchors: banner, satellite, tables
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")

var _p := {}
var _sat: Node3D
var _string: MeshInstance3D
var _mill: Node3D


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "school"))
	var cream := Kit.mat("#ecdcb4", 0.9)
	var maroon := Kit.mat("#7a2a24", 0.85)
	var green := Kit.mat("#3c6b4a", 0.7)
	var dark := Kit.mat("#2a2420", 0.9)
	# The courtyard: packed earth with a paved strip; a low wall at the front.
	Kit.box(root, Vector3(60, 0.1, 40), Vector3(0, -0.05, 4), Kit.mat("#b49a78", 0.95))
	Kit.box(root, Vector3(24, 0.02, 3.0), Vector3(0, 0.01, -4.6), Kit.mat("#a8a29a", 0.9))
	# The schoolhouse: two storeys, a maroon dado band, an arched verandah below, a balcony rail above.
	var bz := -7.5
	Kit.box(root, Vector3(26, 7.2, 3.0), Vector3(0, 3.6, bz - 1.5), cream)
	Kit.box(root, Vector3(26.1, 1.0, 3.1), Vector3(0, 0.5, bz - 1.5), maroon)
	Kit.box(root, Vector3(26.4, 0.35, 4.4), Vector3(0, 3.55, bz + 0.2), cream)
	Kit.box(root, Vector3(26.4, 0.4, 4.4), Vector3(0, 7.3, bz + 0.2), maroon)
	for k in 9:
		var x := -12.0 + 3.0 * k
		Kit.box(root, Vector3(0.45, 3.4, 0.45), Vector3(x, 1.7, bz + 2.2), cream)
		Kit.box(root, Vector3(0.5, 0.6, 0.5), Vector3(x, 0.3, bz + 2.2), maroon)
		if k < 8:
			# The arch spandrel between columns.
			Kit.box(root, Vector3(2.6, 0.5, 0.3), Vector3(x + 1.5, 3.15, bz + 2.2), cream)
			Kit.ball(root, 1.0, Vector3(x + 1.5, 2.75, bz + 2.2), Kit.mat("#e2d0a6", 0.9), 16, Vector3(1.25, 0.5, 0.12))
			# Doors and windows in the back wall; upstairs windows with green shutters.
			Kit.box(root, Vector3(1.0, 2.1, 0.1), Vector3(x + 1.5, 1.05, bz - 0.02), dark)
			Kit.box(root, Vector3(1.0, 1.2, 0.1), Vector3(x + 1.5, 5.3, bz + 0.02), dark)
			for s: float in [-1.0, 1.0]:
				Kit.box(root, Vector3(0.5, 1.25, 0.06), Vector3(x + 1.5 + s * 0.78, 5.3, bz + 0.06), green)
		Kit.rod(root, Vector3(x, 4.25, bz + 2.3), Vector3(x + 3.0 if k < 8 else x, 4.25, bz + 2.3), 0.03, green, 6)
	# Tricolour bunting: triangles on strings across the courtyard.
	var cols := ["#ff9933", "#f8f8f8", "#138808"]
	for line in 3:
		var a := Vector3(-8.0, 4.4 - line * 0.2, -4.0 + line * 2.8)
		var b := Vector3(8.0, 4.4 - line * 0.2, -4.0 + line * 2.8)
		var n := 26
		for i in n + 1:
			var u := float(i) / n
			var p := a.lerp(b, u) + Vector3(0, -0.6 * sin(PI * u), 0)
			if i < n:
				var p2 := a.lerp(b, float(i + 1) / n) + Vector3(0, -0.6 * sin(PI * float(i + 1) / n), 0)
				Kit.rod(root, p, p2, 0.006, dark, 4)
				var tri := MeshInstance3D.new()
				var pm := PrismMesh.new()
				pm.size = Vector3(0.28, 0.34, 0.005)
				tri.mesh = pm
				tri.material_override = Kit.mat(cols[(i + line) % 3], 0.8)
				tri.position = (p + p2) * 0.5 + Vector3(0, -0.19, 0)
				tri.rotation = Vector3(0, 0, PI)
				root.add_child(tri)
	# The banner on two bamboo poles.
	for s: float in [-1.0, 1.0]:
		Kit.rod(root, Vector3(s * 2.6, 0, -1.8), Vector3(s * 2.6, 3.3, -1.8), 0.05, Kit.mat("#b8945a", 0.8), 8)
	Kit.box(root, Vector3(5.0, 0.9, 0.02), Vector3(0, 2.75, -1.8), Kit.mat("#fbf6ea", 0.95))
	Kit.box(root, Vector3(5.0, 0.08, 0.025), Vector3(0, 3.16, -1.8), Kit.mat("#ff9933", 0.8))
	Kit.box(root, Vector3(5.0, 0.08, 0.025), Vector3(0, 2.34, -1.8), Kit.mat("#138808", 0.8))
	var lines: Array = _p.get("banner", ["NATIONAL TECHNOLOGY DAY", "11 MAY"])
	Kit.text(root, String(lines[0]), 0.3, "#1e2c5a", Vector3(0, 2.86, -1.785), Vector3.ZERO, true)
	if lines.size() > 1:
		Kit.text(root, String(lines[1]), 0.2, "#b3171f", Vector3(0, 2.52, -1.785), Vector3.ZERO, true)
	# Trestle tables with the projects.
	var cloth := Kit.mat("#2a4a8a", 0.9)
	for s: float in [-1.0, 1.0]:
		var tc := Vector3(s * 1.7, 0, -1.2)
		Kit.box(root, Vector3(2.0, 0.05, 0.8), tc + Vector3(0, 0.72, 0), cloth)
		Kit.box(root, Vector3(2.0, 0.6, 0.02), tc + Vector3(0, 0.42, 0.4), cloth)
	# A model rocket (tricolour band, a nose cone, fins).
	var rk := Vector3(-2.3, 0.745, -1.25)
	Kit.cyl(root, 0.07, 0.07, 0.6, rk + Vector3(0, 0.3, 0), Kit.mat("#f2f2ee", 0.5), 16)
	Kit.cyl(root, 0.0, 0.07, 0.2, rk + Vector3(0, 0.7, 0), Kit.mat("#c81e1e", 0.5), 16)
	Kit.cyl(root, 0.072, 0.072, 0.06, rk + Vector3(0, 0.4, 0), Kit.mat("#ff9933", 0.6), 16)
	for k in 3:
		var a := TAU * k / 3.0
		Kit.box(root, Vector3(0.12, 0.14, 0.01), rk + Vector3(cos(a) * 0.1, 0.07, sin(a) * 0.1), Kit.mat("#444", 0.6), Vector3(0, -a, 0))
	# A paper windmill (spins).
	_mill = Node3D.new()
	var mp := Vector3(-1.2, 0.745, -1.2)
	Kit.rod(root, mp, mp + Vector3(0, 0.5, 0), 0.01, Kit.mat("#b8945a", 0.8), 6)
	_mill.position = mp + Vector3(0, 0.5, 0.02)
	root.add_child(_mill)
	for k in 4:
		var bl := Kit.box(_mill, Vector3(0.05, 0.16, 0.005), Vector3(0, 0.08, 0), Kit.mat(["#ff9933", "#f8f8f8", "#138808", "#1e2c5a"][k], 0.7))
		var pv := Node3D.new()
		pv.rotation.z = TAU * k / 4.0
		_mill.add_child(pv)
		bl.reparent(pv, false)
	# A small satellite dish of foil and a clay "volcano".
	var dp := Vector3(1.4, 0.745, -1.2)
	Kit.rod(root, dp, dp + Vector3(0, 0.25, 0), 0.012, Kit.mat("#888", 0.4, 0.6), 6)
	Kit.ball(root, 0.16, dp + Vector3(0, 0.3, 0.02), Kit.mat("#d8d8d8", 0.2, 0.9), 16, Vector3(1, 1, 0.35))
	var vp := Vector3(2.3, 0.745, -1.25)
	Kit.cyl(root, 0.04, 0.22, 0.26, vp + Vector3(0, 0.13, 0), Kit.mat("#7a5032", 0.9), 16)
	Kit.cyl(root, 0.035, 0.035, 0.01, vp + Vector3(0, 0.26, 0), Kit.lit("#ff5a1e", 2.0), 12)
	# The hero satellite on its string.
	_sat = Node3D.new()
	root.add_child(_sat)
	var satc := Node3D.new()
	satc.scale = Vector3.ONE * 1.8
	_sat.add_child(satc)
	var foil := Kit.mat("#d8b04a", 0.25, 0.9)
	Kit.box(satc, Vector3(0.16, 0.16, 0.16), Vector3(0, -0.08, 0), foil)
	for s: float in [-1.0, 1.0]:
		Kit.rod(satc, Vector3(s * 0.08, -0.08, 0), Vector3(s * 0.14, -0.08, 0), 0.006, Kit.mat("#888", 0.4, 0.6), 4)
		Kit.box(satc, Vector3(0.24, 0.12, 0.006), Vector3(s * 0.27, -0.08, 0), Kit.mat("#1e3a8a", 0.3, 0.4))
	Kit.ball(satc, 0.06, Vector3(0, -0.17, 0.06), Kit.mat("#eeeeee", 0.3, 0.6), 12, Vector3(1, 1, 0.4))
	_string = MeshInstance3D.new()
	_string.material_override = Kit.mat("#f0f0f0", 0.9)
	root.add_child(_string)
	# Morning: a warm bounce off the courtyard.
	Kit.omni(root, Vector3(0, 1.0, 2.0), Color(1.0, 0.88, 0.72), 0.6, 6.0, false, 0.2)
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var inv := gt.affine_inverse()
	_mill.rotation.z = -t * 6.0
	var sd: Dictionary = _p.get("satellite", {})
	var sat_at := Vector3(0.3, 1.0, 0.4)
	if not sd.is_empty() and ctx.has("actor"):
		var a = ctx["actor"].call(String(sd["actor"]))
		if a != null and a.visible:
			var lift := float(sd["lift"])
			var ay := float(a.rotation.y)
			var fwd := Vector3(sin(ay), 0, cos(ay))
			var right := -Vector3(cos(ay), 0, -sin(ay))
			var chest: Vector3 = a.bone_world("spine_03")
			var low := chest + fwd * 0.28 + right * 0.12 + Vector3(0, 0.05, 0)
			var high := chest + fwd * 0.12 + right * 0.16 + Vector3(0, 1.3, 0)
			var k := Motion.out_back(Motion.seg(t, lift - 0.15, lift + 0.3), 1.6)
			var hand := low.lerp(high, k)
			Crawl.long_arms(a, 1.9)
			a.aim_hand("r", hand, 1.0)
			# The satellite hangs 0.45 m below the hand, swinging from the jerk of the lift, turning slowly.
			var dt := t - (lift + 0.1)
			var sw := 0.5 * exp(-maxf(dt, 0.0) * 0.8) * sin(maxf(dt, 0.0) * 4.2) if dt > 0.0 else 0.05 * sin(t * 3.0)
			var hang := Vector3(sin(sw) * 0.3, -cos(sw) * 0.3, 0.0)
			var hl: Vector3 = inv * hand
			_sat.position = hl + Basis(Vector3.UP, ay - gt.basis.get_euler().y) * hang
			_sat.rotation = Vector3(0, t * 0.9, -sw)
			sat_at = _sat.position
			var up := (hl - _sat.position)
			var c := CylinderMesh.new()
			c.top_radius = 0.002
			c.bottom_radius = 0.002
			c.height = up.length()
			c.radial_segments = 4
			_string.mesh = c
			var y := up.normalized()
			var x := y.cross(Vector3.FORWARD).normalized()
			_string.transform = Transform3D(Basis(x, y, x.cross(y)), (hl + _sat.position) * 0.5)
	return {"banner": gt * Vector3(0, 2.75, -1.8), "satellite": gt * sat_at, "tables": gt * Vector3(0, 0.8, -1.2)}
