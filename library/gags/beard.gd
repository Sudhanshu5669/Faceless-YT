## library:beard — a white beard that grows from a toon's chin down to the floor ("waiting forever"),
## optionally with a cobweb spun at their hand. Motion by docs/MOTION_SPEC.md: it sprouts as stubble,
## grows like a time-lapse (ease-in-out) and lands on the floor ON the word (contact): the tip squashes
## and curls forward along the floor, then the whole beard sways a beat behind the head (follow-through).
##
##   {"id": "beard", "script": "library:beard", "t": <time>, "at": "<actor>", "face": <camera side>,
##    "params": {"head": "<actor>.head", "grow": <time>, "land": <time on the word>,
##               "color": "#f4f4f2", "width": 0.34, "head_r": 0.24, "curl": 0.14,
##               "web": {"at": "<actor>.hand", "t": <time>, "size": 0.22}}}
##
## The floor is the height of the gag's "at" (put it on the actor). Anchors: "<id>.tip", "<id>.web".
extends RefCounted

const Toon = preload("res://scripts/actors/toon.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const PARAMS := ["head", "grow", "land", "color", "width", "head_r", "curl", "web"]
const N := 16   # joints down the beard


func validate(g: Dictionary) -> Array:
	var e := []
	var p: Dictionary = g.get("params", {})
	for k in p:
		if not (k in PARAMS):
			e.append("beard: unknown param '%s' (known: %s)" % [k, ", ".join(PackedStringArray(PARAMS))])
	for k in ["head", "grow", "land"]:
		if not p.has(k):
			e.append("beard: needs param '%s'" % k)
	return e


func _radius(i: int, w: float) -> float:
	var u := float(i) / (N - 1)
	# Wide at the jaw, stays full most of the way, tapers to a point near the floor.
	return w * 0.5 * lerpf(1.0, 0.25, pow(u, 1.6))


func build(g: Dictionary) -> Node3D:
	var p: Dictionary = g.get("params", {})
	var w := float(p.get("width", 0.34))
	var mat := Toon.material(Color(String(p.get("color", "#f4f4f2"))), Toon.OUTLINE * 0.6)
	var root := Node3D.new()
	for i in N:
		var j := MeshInstance3D.new()
		j.name = "j%d" % i
		j.mesh = Toon.sphere(_radius(i, w))
		j.material_override = mat
		root.add_child(j)
		if i < N - 1:
			var c := MeshInstance3D.new()
			c.name = "c%d" % i
			var cm := CylinderMesh.new()
			cm.top_radius = _radius(i, w)
			cm.bottom_radius = _radius(i + 1, w)
			cm.height = 1.0
			c.mesh = cm
			c.material_override = mat
			root.add_child(c)
		# Fluffy outline: a tuft each side of every joint (a beard, not a cone).
		for side in ["l", "r"]:
			var tuft := MeshInstance3D.new()
			tuft.name = "%s%d" % [side, i]
			tuft.mesh = Toon.sphere(_radius(i, w) * 0.62)
			tuft.material_override = mat
			root.add_child(tuft)
	# The moustache: two curled lobes over the mouth (they sprout first).
	for side in ["mus_l", "mus_r"]:
		var m := MeshInstance3D.new()
		m.name = side
		m.mesh = Toon.sphere(w * 0.22)
		m.material_override = mat
		root.add_child(m)
	var web: Dictionary = p.get("web", {})
	if not web.is_empty():
		var wn := Node3D.new()
		wn.name = "web"
		root.add_child(wn)
		var silk := StandardMaterial3D.new()
		silk.albedo_color = Color(1, 1, 1, 0.85)
		silk.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		silk.emission_enabled = true
		silk.emission = Color("dfe7ff")
		silk.emission_energy_multiplier = 0.6
		silk.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var r := float(web.get("size", 0.22)) * 0.5
		for i in 8:
			var sp := MeshInstance3D.new()
			var sm := CylinderMesh.new()
			sm.top_radius = 0.0025
			sm.bottom_radius = 0.0025
			sm.height = r
			sp.mesh = sm
			sp.material_override = silk
			var ang := TAU * i / 8.0
			sp.rotation = Vector3(0, 0, ang)
			sp.position = Vector3(-sin(ang), cos(ang), 0) * r * 0.5
			wn.add_child(sp)
		for k in 3:
			var ring := MeshInstance3D.new()
			var tm := TorusMesh.new()
			var rr := r * (0.3 + 0.33 * k)
			tm.inner_radius = rr - 0.0025
			tm.outer_radius = rr + 0.0025
			tm.rings = 32
			ring.mesh = tm
			ring.material_override = silk
			ring.rotation = Vector3(PI / 2, 0, 0)
			wn.add_child(ring)
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	var holder: Node3D = ctx["holder"]
	var out := {}
	var h: Dictionary = ctx["point"].call(p["head"])
	var grow := float(p["grow"])
	var land := float(p["land"])
	var on := not h.has("error") and t >= grow
	for c in node.get_children():
		if c.name != "web":
			c.visible = on
	if on:
		var hr := float(p.get("head_r", 0.24))
		# Forward = the way the gag faces (give it "face": the camera side, the way the actor looks).
		var fwd := holder.global_transform.basis.z
		fwd = Vector3(fwd.x, 0, fwd.z).normalized()
		var right := Vector3.UP.cross(fwd).normalized()
		var chin: Vector3 = h["pos"] + Vector3.DOWN * hr * 0.78 + fwd * hr * 0.5
		var floor_y := holder.global_position.y
		var w := float(p.get("width", 0.34))
		var drop := maxf(chin.y - floor_y - _radius(N - 1, w), 0.05)
		# Length: stubble at once, then a time-lapse growth that reaches the floor on "land",
		# then the tip curls forward along the floor (ease-out).
		var k := Motion.seg(t, grow, land)
		var length := drop * (0.07 + 0.93 * Motion.in_out(k))
		var curl := float(p.get("curl", 0.14)) * Motion.out_cubic(Motion.seg(t, land, land + 0.35))
		var total := length + curl
		# Contact on the floor: the bottom squashes and springs back; the sway lags the head.
		var hit := Motion.impact(t - land, 0.35, 3.0, 7.0) if t >= land else 0.0
		var pts: Array[Vector3] = []
		for i in N:
			var u := float(i) / (N - 1)
			var d := u * total
			var sway := 0.035 * u * u * sin(TAU * 0.55 * t - u * 2.2) * minf(length / 0.3, 1.0)
			var bulge := fwd * 0.04 * sin(u * PI) * minf(length / 0.3, 1.0)
			var q: Vector3
			if d <= drop:
				q = chin + Vector3.DOWN * d * (1.0 + hit * u * 0.4) + right * sway + bulge
			else:
				q = Vector3(chin.x, floor_y + _radius(i, w), chin.z) + fwd * (d - drop) + right * sway
			pts.append(q)
		for i in N:
			var j := node.get_node("j%d" % i) as Node3D
			j.position = holder.to_local(pts[i])
			var sq := Motion.squash(hit * u_sq(i))
			j.scale = Vector3(sq.x, sq.y, sq.x * 0.7)
			for sd in [-1.0, 1.0]:
				var tuft := node.get_node("%s%d" % ["l" if sd < 0 else "r", i]) as Node3D
				# Irregular clumps (seeded by the joint, not a regular ridge): size, height and spread vary.
				var hsh := float((i * 7 + (3 if sd > 0 else 0)) % 5) / 4.0
				var puff := _radius(i, w) * (0.55 + 0.25 * hsh + 0.06 * sin(t * 2.6 + i * 1.7 + sd))
				tuft.position = holder.to_local(pts[i] + right * sd * puff + Vector3.UP * _radius(i, w) * 0.35 * (hsh - 0.5))
				var ts := 0.75 + 0.35 * hsh
				tuft.scale = Vector3(sq.x, sq.y * 1.25, sq.x * 0.7) * ts
			if i < N - 1:
				var c := node.get_node("c%d" % i) as Node3D
				var a := holder.to_local(pts[i])
				var b := holder.to_local(pts[i + 1])
				var dv := a - b
				var y := dv.normalized() if dv.length() > 0.0001 else Vector3.UP
				var x := y.cross(Vector3.BACK).normalized() if absf(y.dot(Vector3.BACK)) < 0.99 else Vector3.RIGHT
				var z := x.cross(y).normalized()
				c.transform = Transform3D(Basis(x * sq.x, y * maxf(dv.length(), 0.001), z * sq.x * 0.7), (a + b) * 0.5)
		out["tip"] = pts[N - 1]
		# Moustache: sprouts with an overshoot in the first 0.25 s, twitches when the beard lands.
		var ms := Motion.out_back(Motion.seg(t, grow, grow + 0.25), 2.0)
		var mouth: Vector3 = h["pos"] + Vector3.DOWN * hr * 0.62 + fwd * hr * 0.8
		for sd in [-1.0, 1.0]:
			var m := node.get_node("mus_l" if sd < 0 else "mus_r") as Node3D
			m.position = holder.to_local(mouth + right * sd * hr * 0.22)
			m.rotation = Vector3(0, 0, sd * (0.35 + 0.15 * hit))
			m.scale = Vector3(1.3, 0.5, 0.7) * maxf(ms, 0.001)
	var web: Dictionary = p.get("web", {})
	if not web.is_empty():
		var wn := node.get_node("web") as Node3D
		var wt := float(web.get("t", land))
		var at: Dictionary = ctx["point"].call(web.get("at", p["head"]))
		wn.visible = t >= wt and not at.has("error")
		if wn.visible:
			# Spun in with an overshoot, then breathes a little in the draught.
			var s := Motion.out_back(Motion.seg(t, wt, wt + 0.35), 2.2)
			wn.position = holder.to_local(at["pos"] + Vector3(0, 0.02, 0.06))
			wn.rotation = Vector3(0.1 * sin(t * 1.7), 0, 0.06 * sin(t * 1.3))
			wn.scale = Vector3.ONE * maxf(s, 0.001)
			out["web"] = at["pos"]
	return out


## How much of the landing squash a joint takes: the bottom third of the beard.
func u_sq(i: int) -> float:
	return clampf((float(i) / (N - 1) - 0.6) / 0.4, 0.0, 1.0)
