## library:snail — a snail inching along local +z (give the gag a "face" target), dragging its
## cargo on a string (a film reel for "video"). Real snail motion, by docs/MOTION_SPEC.md:
## each step the head stretches forward (ease-out), then the tail catches up (ease-in-out); the body
## keeps its volume, the shell lags and bobs, the eye stalks trail behind the head and settle, and
## the cargo jerks after each tug of the string. It barely gets anywhere: that is the joke.
## Cargo is a real object, never a labelled box: "film_reel" (video) rolls along on its edge.
##
##   {"id": "snail", "script": "library:snail", "t": <time>, "at": {...}, "face": <direction of travel>,
##    "params": {"size": 0.34, "start": <time>, "step": 0.025, "period": 0.55, "color": "#9ccf6a",
##               "cargo": {"kind": "film_reel", "size": 0.2, "color": "#c9ccd2"}, "rope": 0.16}}
##
## Anchors: "<id>.snail" (the shell), "<id>.cargo".
extends RefCounted

const Toon = preload("res://scripts/actors/toon.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const PARAMS := ["size", "start", "step", "period", "color", "cargo", "rope"]


func validate(g: Dictionary) -> Array:
	var e := []
	for k in g.get("params", {}):
		if not (k in PARAMS):
			e.append("snail: unknown param '%s' (known: %s)" % [k, ", ".join(PackedStringArray(PARAMS))])
	return e


func _mi(m: Mesh, mat: Material, pos: Vector3, nm: String = "") -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = m
	n.material_override = mat
	n.position = pos
	if nm != "":
		n.name = nm
	return n


func build(g: Dictionary) -> Node3D:
	var p: Dictionary = g.get("params", {})
	var s := float(p.get("size", 0.34))
	var o := Toon.OUTLINE * 0.7
	var root := Node3D.new()
	var skin := Toon.material(Color(String(p.get("color", "#9ccf6a"))), o)
	var shell_mat := Toon.material(Color("b5763a"), o)
	var stripe := Toon.material(Color("6e3f1c"), 0.0)
	var white := Toon.material(Color("fbfbf6"), o)
	var black := Toon.material(Color("16181d"), 0.0)
	# Body: a long soft slug along +z. "body" gets the stretch; the mesh keeps the base shape.
	var body := Node3D.new()
	body.name = "body"
	root.add_child(body)
	var bm := _mi(Toon.sphere(s * 0.5), skin, Vector3(0, s * 0.1, 0))
	bm.scale = Vector3(0.3, 0.26, 1.0)
	body.add_child(bm)
	# Head bump + eye stalks at the front.
	var head := Node3D.new()
	head.name = "head"
	root.add_child(head)
	head.add_child(_mi(Toon.sphere(s * 0.12), skin, Vector3(0, s * 0.14, 0)))
	for side in [-1.0, 1.0]:
		var stalk := Node3D.new()
		stalk.name = "stalk_%s" % ("l" if side < 0 else "r")
		stalk.position = Vector3(side * s * 0.05, s * 0.2, s * 0.02)
		head.add_child(stalk)
		var c := CylinderMesh.new()
		c.top_radius = s * 0.016
		c.bottom_radius = s * 0.022
		c.height = s * 0.2
		var st := _mi(c, skin, Vector3(0, s * 0.1, 0))
		stalk.add_child(st)
		stalk.add_child(_mi(Toon.sphere(s * 0.045), white, Vector3(0, s * 0.21, 0)))
		stalk.add_child(_mi(Toon.sphere(s * 0.022), black, Vector3(side * s * 0.008, s * 0.215, s * 0.035)))
	# Shell: a ball with a spiral, sitting on the back half.
	var shell := Node3D.new()
	shell.name = "shell"
	root.add_child(shell)
	shell.add_child(_mi(Toon.sphere(s * 0.27), shell_mat, Vector3.ZERO))
	# The spiral, on both flat sides: rings sitting ON the shell surface (x = sqrt(R^2 - r^2)).
	var R := s * 0.27
	for i in 3:
		var rr := s * (0.19 - i * 0.065)
		var tm := TorusMesh.new()
		tm.inner_radius = rr - s * 0.018
		tm.outer_radius = rr + s * 0.018
		var x := sqrt(maxf(R * R - rr * rr, 0.0)) + s * 0.004
		for sx in [-1.0, 1.0]:
			var ring := _mi(tm, stripe, Vector3(sx * x, s * 0.01 * i, 0))
			ring.rotation = Vector3(0, 0, PI / 2)
			shell.add_child(ring)
	# Cargo on a string: a real object, never a labelled box. "film_reel" = an old metal film reel
	# standing on its edge (it rolls as it is dragged) with a strip of film trailing behind.
	var cg: Dictionary = p.get("cargo", {})
	if not cg.is_empty():
		var r := float(cg.get("size", 0.2)) * 0.5
		var cargo := Node3D.new()
		cargo.name = "cargo"
		root.add_child(cargo)
		var wheel := Node3D.new()
		wheel.name = "wheel"
		wheel.position = Vector3(0, r, 0)
		cargo.add_child(wheel)
		var metal := Toon.material(Color(String(cg.get("color", "#c9ccd2"))), o)
		var dark := Toon.material(Color("1c1d22"), 0.0)
		var film := Toon.material(Color("3a2a1e"), 0.0)
		# The flanges (two discs) with the film wound between them, face on to +-x (rolls along z).
		for sx in [-1.0, 1.0]:
			var d := CylinderMesh.new()
			d.top_radius = r
			d.bottom_radius = r
			d.height = r * 0.06
			d.radial_segments = 40
			var disc := _mi(d, metal, Vector3(sx * r * 0.2, 0, 0))
			disc.rotation = Vector3(0, 0, PI / 2)
			wheel.add_child(disc)
			# The classic reel holes: five round windows around the hub.
			for i in 5:
				var ang := TAU * i / 5.0
				var h := CylinderMesh.new()
				h.top_radius = r * 0.2
				h.bottom_radius = r * 0.2
				h.height = r * 0.07
				var hole := _mi(h, dark, Vector3(sx * r * 0.21, sin(ang) * r * 0.55, cos(ang) * r * 0.55))
				hole.rotation = Vector3(0, 0, PI / 2)
				wheel.add_child(hole)
		var fw := CylinderMesh.new()
		fw.top_radius = r * 0.8
		fw.bottom_radius = r * 0.8
		fw.height = r * 0.36
		fw.radial_segments = 40
		var wound := _mi(fw, film, Vector3.ZERO)
		wound.rotation = Vector3(0, 0, PI / 2)
		wheel.add_child(wound)
		var hb := CylinderMesh.new()
		hb.top_radius = r * 0.16
		hb.bottom_radius = r * 0.16
		hb.height = r * 0.5
		var hub := _mi(hb, metal, Vector3.ZERO)
		hub.rotation = Vector3(0, 0, PI / 2)
		wheel.add_child(hub)
		# A strip of film trailing on the floor behind it: dark band with pale frames.
		var strip := Node3D.new()
		strip.name = "strip"
		cargo.add_child(strip)
		var frames := 7
		for i in frames:
			var fb := BoxMesh.new()
			fb.size = Vector3(r * 0.34, 0.004, r * 0.3)
			strip.add_child(_mi(fb, film, Vector3(0, 0.003, -r * 0.32 * i)))
			var pic := BoxMesh.new()
			pic.size = Vector3(r * 0.22, 0.005, r * 0.2)
			strip.add_child(_mi(pic, Toon.material(Color("f3e6c0"), 0.0), Vector3(0, 0.004, -r * 0.32 * i)))
		var rope := MeshInstance3D.new()
		rope.name = "rope"
		var rc := CylinderMesh.new()
		rc.top_radius = 0.004
		rc.bottom_radius = 0.004
		rc.height = 1.0
		rope.mesh = rc
		rope.material_override = Toon.material(Color("e8e2c8"), 0.0)
		root.add_child(rope)
	return root


## The body's front and back edge (metres along +z) at time t: the inchworm step, pure in t.
func _edges(t: float, p: Dictionary) -> Vector2:
	var period := float(p.get("period", 0.55))
	var step := float(p.get("step", 0.025))
	var age := maxf(t - float(p.get("start", 0.0)), 0.0)
	var n := floorf(age / period)
	var c := fmod(age, period) / period
	var front := n * step + step * Motion.out_cubic(Motion.seg(c, 0.0, 0.45))
	var back := n * step + step * Motion.in_out(Motion.seg(c, 0.45, 0.9))
	return Vector2(front, back)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	var s := float(p.get("size", 0.34))
	var step := float(p.get("step", 0.025))
	var e := _edges(t, p)
	var mid := (e.x + e.y) * 0.5
	# Stretch while the head is ahead of the tail (exaggerated: a step is only a few cm).
	var a := clampf((e.x - e.y) / maxf(step, 0.001), 0.0, 1.0) * 0.2
	var body := node.get_node("body") as Node3D
	body.position = Vector3(0, 0, mid)
	var sq := Motion.squash(a)            # y = 1 + a (stretch), x/z thin
	body.scale = Vector3(sq.x, sq.x, sq.y)  # stretch along travel (z), thin across
	var head := node.get_node("head") as Node3D
	head.position = Vector3(0, 0, e.x + s * 0.42)
	# Eye stalks trail the head and settle (follow-through): lean back with the head's recent speed.
	var lag := _edges(t - 0.07, p)
	var lean := clampf((e.x - lag.x) / maxf(step * 0.5, 0.001), 0.0, 1.0)
	for side in ["l", "r"]:
		var st := head.get_node("stalk_" + side) as Node3D
		st.rotation = Vector3(-0.45 * lean + 0.06 * sin(t * 5.0 + (0.0 if side == "l" else 1.3)), 0, 0)
	# The shell rides the body a beat late, rising as the body stretches.
	var sh := _edges(t - 0.08, p)
	var shell := node.get_node("shell") as Node3D
	shell.position = Vector3(0, s * (0.36 + a * 0.12), (sh.x + sh.y) * 0.5 - s * 0.06)
	shell.rotation = Vector3(-a * 0.35, 0, 0)
	var out := {"snail": node.to_global(shell.position)}
	if node.has_node("cargo"):
		# The cargo follows the tail after the string goes taut (later still), with a tug tilt.
		var rope_len := float(p.get("rope", 0.16))
		var cb := _edges(t - 0.16, p)
		var cb2 := _edges(t - 0.2, p)
		var tug := clampf((cb.y - cb2.y) / maxf(step * 0.2, 0.001), 0.0, 1.0)
		var cargo := node.get_node("cargo") as Node3D
		cargo.position = Vector3(0, 0, cb.y - s * 0.5 - rope_len)
		cargo.rotation = Vector3(tug * 0.06, 0, 0)
		var r := float(p.get("cargo", {}).get("size", 0.2)) * 0.5
		# Rolls with the distance it has been dragged (no slipping), the strip trails flat behind.
		(cargo.get_node("wheel") as Node3D).rotation = Vector3(cargo.position.z / r, 0, 0)
		var strip := cargo.get_node("strip") as Node3D
		strip.position = Vector3(0, 0, -r * 0.7)
		strip.rotation = Vector3(0, 0.08 * sin(t * 2.1), 0)
		var a0 := Vector3(0, s * 0.12, e.y - s * 0.45)
		var a1 := cargo.position + Vector3(0, r, 0)
		var rope := node.get_node("rope") as Node3D
		var d := a0 - a1
		rope.position = (a0 + a1) * 0.5
		var y := d.normalized()
		var x := y.cross(Vector3.FORWARD).normalized() if absf(y.dot(Vector3.FORWARD)) < 0.99 else Vector3.RIGHT
		rope.transform = Transform3D(Basis(x, y * d.length(), x.cross(y)), (a0 + a1) * 0.5)
		out["cargo"] = node.to_global(cargo.position + Vector3(0, r, 0))
	return out
