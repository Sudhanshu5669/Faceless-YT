## The Lok Sabha chamber, Parliament House, New Delhi, 27 May 1998 (dramatised): a horseshoe of green leather benches
## rising in tiers behind curved teak desks, round the well and the Table of the House; the Speaker's raised chair under a
## teak canopy, a gold Ashoka Chakra above; teak-panelled walls, the public galleries above them, a warm lit ceiling.
##
## Local frame: the well's centre at the origin, floor y 0; the Speaker's dais at z SPEAKER_Z facing +z; the benches arc
## round the centre (angle 0 = +z, opposite the Speaker) between -ARC and +ARC degrees; tier i sits at radius R0 + i * DR
## on a floor DY * i high. The treasury benches are on the Speaker's right (-x).
##
## params:
##   thump   {"from": t, "ids": [actor ids]}   from `from`, the actors pound their desks with both fists (the House's
##           approval), each on their own rhythm
## anchors: speaker, well, table
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")
const R0 := 6.0
const DR := 1.5
const DY := 0.42
const TIERS := 7
const ARC := 150.0
const SPEAKER_Z := -8.5
const WALL_R := 18.5

var _p := {}


static func tier_point(i: int, deg: float) -> Vector3:
	var a := deg_to_rad(deg)
	var r := R0 + DR * i
	return Vector3(sin(a) * r, DY * i, cos(a) * r)


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "lok_sabha"))
	var teak := Kit.mat("#6a3e1e", 0.55, 0.0, 0.5)
	var teak_d := Kit.mat("#4a2a14", 0.6)
	var green := Kit.mat("#2f6a3a", 0.7)
	var green_d := Kit.mat("#24542e", 0.75)
	var carpet := Kit.mat("#3a5a34", 0.95)
	# The floor of the well, carpeted.
	Kit.cyl(root, WALL_R, WALL_R, 0.1, Vector3(0, -0.05, 0), carpet, 64)
	# The tiers: a stepped floor ring, a curved teak desk in front, a green bench behind, per segment.
	for i in TIERS:
		var r := R0 + DR * i
		var arc_len := deg_to_rad(ARC * 2.0) * r
		var n := int(arc_len / 1.25)
		for k in n:
			var deg := -ARC + (2.0 * ARC) * (float(k) + 0.5) / n
			var a := deg_to_rad(deg)
			var face := atan2(-sin(a), -cos(a))     # facing the centre
			var seg := 2.0 * ARC / n
			var w := deg_to_rad(seg) * r * 1.02
			var base := Vector3(sin(a) * r, 0, cos(a) * r)
			var fl := Kit.box(root, Vector3(w, DY * i + 0.02, DR), base + Vector3(0, (DY * i + 0.02) * 0.5, 0), green_d)
			fl.rotation.y = face
			var inward := Vector3(-sin(a), 0, -cos(a))
			var desk := Kit.box(root, Vector3(w * 0.98, 0.72, 0.42), base + inward * 0.5 + Vector3(0, DY * i + 0.36, 0), teak)
			desk.rotation.y = face
			var top := Kit.box(root, Vector3(w, 0.04, 0.5), base + inward * 0.52 + Vector3(0, DY * i + 0.74, 0), teak_d)
			top.rotation.y = face
			var seat := Kit.box(root, Vector3(w * 0.96, 0.44, 0.5), base - inward * 0.25 + Vector3(0, DY * i + 0.22, 0), green)
			seat.rotation.y = face
			var back := Kit.box(root, Vector3(w * 0.96, 0.55, 0.1), base - inward * 0.52 + Vector3(0, DY * i + 0.7, 0), green)
			back.rotation.y = face
			# A microphone stalk on every other desk.
			if k % 2 == 0:
				Kit.rod(root, base + inward * 0.5 + Vector3(0, DY * i + 0.76, 0), base + inward * 0.62 + Vector3(0, DY * i + 1.05, 0), 0.008, Kit.mat("#1a1a1a", 0.4), 6)
	# The wall: teak panelling round the back of the horseshoe, the galleries above with their railings, the ceiling.
	var n_wall := 72
	for k in n_wall:
		var a := TAU * float(k) / n_wall
		var p := Vector3(sin(a) * WALL_R, 0, cos(a) * WALL_R)
		var face := atan2(-sin(a), -cos(a))
		var pn := Kit.box(root, Vector3(TAU * WALL_R / n_wall * 1.02, 5.0, 0.3), p + Vector3(0, 2.5, 0), teak if k % 2 == 0 else teak_d)
		pn.rotation.y = face
		var gal := Kit.box(root, Vector3(TAU * WALL_R / n_wall * 1.02, 2.4, 0.3), p * 1.04 + Vector3(0, 6.6, 0), Kit.mat("#1a120c", 0.9))
		gal.rotation.y = face
		var rail := Kit.box(root, Vector3(TAU * WALL_R / n_wall * 1.02, 0.15, 0.2), p * 0.99 + Vector3(0, 5.6, 0), Kit.mat("#c9a24a", 0.3, 0.8))
		rail.rotation.y = face
	Kit.cyl(root, WALL_R * 1.05, WALL_R * 1.05, 0.4, Vector3(0, 8.2, 0), teak_d, 72)
	Kit.cyl(root, WALL_R * 1.05, WALL_R * 1.05, 0.2, Vector3(0, 10.5, 0), Kit.mat("#e8dcc0", 0.8), 72)
	# The lit ceiling: warm panels in a ring, a central rose.
	for k in 24:
		var a := TAU * float(k) / 24.0
		var p := Vector3(sin(a) * 11.0, 10.35, cos(a) * 11.0)
		Kit.box(root, Vector3(2.4, 0.05, 1.4), p, Kit.lit("#ffe2b0", 1.6), Vector3(0, a, 0))
	Kit.cyl(root, 3.0, 3.0, 0.05, Vector3(0, 10.35, 0), Kit.lit("#fff0d0", 1.4), 32)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var sp := Kit.spot(root, Vector3(sin(a) * 9.0, 10.0, cos(a) * 9.0), Vector3(sin(a) * 4.0, 0, cos(a) * 4.0), Color(1.0, 0.86, 0.66), 5.0, 18.0, 45.0, k % 2 == 0, 0.3)
		sp.spot_attenuation = 0.8
	# The well: the Table of the House with clerks' chairs.
	Kit.box(root, Vector3(4.2, 0.78, 1.4), Vector3(0, 0.39, -2.6), teak)
	Kit.box(root, Vector3(4.3, 0.04, 1.5), Vector3(0, 0.8, -2.6), Kit.mat("#2f6a3a", 0.8))
	# The Speaker's dais: steps, the high-backed chair, the canopy, the Chakra above.
	var sz := SPEAKER_Z
	Kit.box(root, Vector3(6.0, 1.2, 3.0), Vector3(0, 0.6, sz - 0.5), teak_d)
	Kit.box(root, Vector3(3.6, 0.4, 0.8), Vector3(0, 0.2, sz + 1.3), teak)
	Kit.box(root, Vector3(2.4, 0.8, 0.9), Vector3(0, 1.6, sz + 0.4), teak)
	Kit.box(root, Vector3(1.1, 2.6, 0.25), Vector3(0, 2.5, sz - 0.4), green)
	Kit.box(root, Vector3(1.3, 2.8, 0.15), Vector3(0, 2.6, sz - 0.55), teak)
	for s: float in [-1.0, 1.0]:
		Kit.box(root, Vector3(0.25, 4.6, 0.25), Vector3(s * 1.6, 3.5, sz - 0.2), teak)
	Kit.box(root, Vector3(3.8, 0.5, 1.8), Vector3(0, 5.9, sz + 0.2), teak)
	Kit.box(root, Vector3(3.9, 0.12, 1.9), Vector3(0, 6.2, sz + 0.2), Kit.mat("#c9a24a", 0.3, 0.8))
	# The Ashoka Chakra in gold on the panel behind.
	var ch := Node3D.new()
	ch.position = Vector3(0, 4.6, sz - 0.68)
	root.add_child(ch)
	var gold := Kit.mat("#d4aa48", 0.3, 0.9)
	var ring := MeshInstance3D.new()
	var rt := TorusMesh.new()
	rt.inner_radius = 0.42
	rt.outer_radius = 0.5
	ring.mesh = rt
	ring.material_override = gold
	ring.rotation.x = PI / 2
	ch.add_child(ring)
	for k in 24:
		var a := TAU * float(k) / 24.0
		Kit.rod(ch, Vector3.ZERO, Vector3(cos(a), sin(a), 0) * 0.43, 0.012, gold, 4)
	Kit.cyl(ch, 0.08, 0.08, 0.04, Vector3.ZERO, gold, 16, Vector3(PI / 2, 0, 0))
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var th: Dictionary = _p.get("thump", {})
	if not th.is_empty() and ctx.has("actor") and t >= float(th["from"]):
		var ids: Array = th["ids"]
		for i in ids.size():
			var a = ctx["actor"].call(String(ids[i]))
			if a == null or not a.visible:
				continue
			var ay := float(a.rotation.y)
			var fwd := Vector3(sin(ay), 0, cos(ay))
			var left := Vector3(cos(ay), 0, -sin(ay))
			var root_p: Vector3 = a.global_position
			var desk := root_p + fwd * 0.62 + Vector3(0, 0.8, 0)
			var rate := 3.6 + 0.5 * float(i % 4)
			var ph := (t - float(th["from"])) * rate + float(i) * 0.37
			# Fists up, then slammed down onto the desk (a sharp in-cubic drop each beat).
			var u := fposmod(ph, 1.0)
			var h := 0.32 * (1.0 - Motion.in_cubic(clampf(u / 0.45, 0.0, 1.0))) if u < 0.45 else 0.32 * Motion.out_cubic(clampf((u - 0.45) / 0.55, 0.0, 1.0))
			var w := clampf((t - float(th["from"])) / 0.2, 0.0, 1.0)
			Crawl.long_arms(a, 1.3)
			a.aim_hand("l", desk + left * 0.16 + Vector3(0, h, 0), w)
			a.aim_hand("r", desk - left * 0.16 + Vector3(0, h, 0), w)
	return {"speaker": gt * Vector3(0, 2.9, SPEAKER_Z), "well": gt * Vector3(0, 1.2, 0), "table": gt * Vector3(0, 0.8, -2.6)}
