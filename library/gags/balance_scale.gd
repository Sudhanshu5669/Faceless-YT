## library:balance_scale — a brass balance whose beam tilts on cues; the pans hang level and
## carry their items (any reveal shape) that drop in on their own times.
##
##   {"id": "scale", "script": "library:balance_scale", "t": 0, "at": {...}, "face": <camera side>,
##    "params": {"size": 1.0,
##               "left":  {"shape": "phone", "color": "#16181d", "size": 0.24, "t": <time>},
##               "right": {"shape": "postcard", "size": 0.3, "t": <time>, "label": "50 PAISE"},
##               "tilt": [[<time>, 0], [<time>, -22], [<time>, 18]]}}
##
## tilt keys: [time, degrees]; positive = the LEFT pan (screen left when facing the camera) goes UP.
## Between keys the beam swings with a little overshoot. Anchors: "<id>.left", "<id>.right" (pan tops).
extends RefCounted

const Toon = preload("res://scripts/actors/toon.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")


func validate(g: Dictionary) -> Array:
	var e := []
	for k in g.get("params", {}):
		if not (k in ["size", "left", "right", "tilt", "color"]):
			e.append("balance_scale: unknown param '%s'" % k)
	return e


func _cyl(r1: float, r2: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = r1
	m.bottom_radius = r2
	m.height = h
	m.radial_segments = 24
	return m


func _mi(mesh: Mesh, mat: Material, pos: Vector3, nm := "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	if nm != "":
		mi.name = nm
	return mi


func build(g: Dictionary) -> Node3D:
	var p: Dictionary = g.get("params", {})
	var s := float(p.get("size", 1.0))
	var brass := Toon.material(Color(String(p.get("color", "#e8b52a"))), Toon.OUTLINE * 0.7)
	var n := Node3D.new()
	n.add_child(_mi(_cyl(s * 0.2, s * 0.26, s * 0.06), brass, Vector3(0, s * 0.03, 0)))
	n.add_child(_mi(_cyl(s * 0.025, s * 0.03, s * 0.8), brass, Vector3(0, s * 0.43, 0)))
	var beam := Node3D.new()
	beam.name = "beam"
	beam.position = Vector3(0, s * 0.84, 0)
	n.add_child(beam)
	var bm := BoxMesh.new()
	bm.size = Vector3(s * 1.1, s * 0.04, s * 0.05)
	beam.add_child(_mi(bm, brass, Vector3.ZERO))
	var sp := SphereMesh.new()
	sp.radius = s * 0.055
	sp.height = s * 0.11
	beam.add_child(_mi(sp, brass, Vector3.ZERO))
	for side in ["left", "right"]:
		var pan := Node3D.new()
		pan.name = "pan_" + side
		n.add_child(pan)
		pan.add_child(_mi(_cyl(s * 0.2, s * 0.13, s * 0.05), brass, Vector3.ZERO))
		var item: Dictionary = p.get(side, {})
		if not item.is_empty():
			var c := Reveals.shape_node(String(item.get("shape", "box")), float(item.get("size", s * 0.25)),
				Color(String(item.get("color", "#f6ecd2"))))
			c.name = "item"
			pan.add_child(c)
			if item.has("label"):
				var lbl := Reveals.text_node(String(item["label"]), s * 0.07, Color(String(item.get("label_color", "#ffd84a"))))
				lbl.name = "label"
				pan.add_child(lbl)
		var str := MeshInstance3D.new()
		str.name = "string_" + side
		str.mesh = _cyl(s * 0.006, s * 0.006, 1.0)
		str.material_override = Toon.material(Color("6b5a2a"), 0.0)
		n.add_child(str)
	return n


func _angle(p: Dictionary, t: float) -> float:
	var keys: Array = p.get("tilt", [])
	if keys.is_empty():
		return 0.0
	var a := float(keys[0][1])
	for i in range(1, keys.size()):
		var t0 := float(keys[i][0])
		if t < t0:
			break
		# Swing to the new angle with a damped overshoot (a real balance settles).
		var from := float(keys[i - 1][1])
		var to := float(keys[i][1])
		var dt := t - t0
		var k := 1.0 - exp(-dt * 6.0) * cos(dt * 11.0)
		a = from + (to - from) * k
	return a


func _span(mi: Node3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var len := maxf(d.length(), 0.001)
	var y := d / len
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y * len, x.cross(y)), (a + b) * 0.5)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	var s := float(p.get("size", 1.0))
	var ang := deg_to_rad(_angle(p, t))
	var beam := node.get_node("beam") as Node3D
	# Positive angle: the left end (local -x when facing the camera... screen left is local +x
	# for a node facing +z toward the camera) goes up.
	beam.rotation = Vector3(0, 0, -ang)
	var out := {}
	for side in ["left", "right"]:
		var sx := 1.0 if side == "left" else -1.0   # facing the camera, screen left = local +x
		var end := beam.position + Vector3(sx * s * 0.5 * cos(ang), sx * s * 0.5 * sin(ang), 0)
		var pan := node.get_node("pan_" + side) as Node3D
		pan.position = end + Vector3(0, -s * 0.36, 0)
		_span(node.get_node("string_" + side) as Node3D, end, pan.position + Vector3(0, s * 0.025, 0))
		var item: Dictionary = p.get(side, {})
		if pan.has_node("item"):
			var c := pan.get_node("item") as Node3D
			var it0 := float(item.get("t", g["t"]))
			var k := clampf((t - it0) / 0.35, 0.0, 1.0)
			c.visible = t >= it0
			# Drops in from above with a little bounce, sits on the pan.
			c.position = Vector3(0, s * 0.03 + (1.0 - (1.0 - pow(1.0 - k, 3.0))) * s * 0.6, 0)
			if pan.has_node("label"):
				var l := pan.get_node("label") as Node3D
				l.visible = t >= it0 + 0.3
				l.position = Vector3(0, s * 0.03 + float(item.get("size", s * 0.25)) * 0.9 + s * 0.08, 0.02)
		out[side] = node.to_global(pan.position + Vector3(0, s * 0.05, 0))
	return out
