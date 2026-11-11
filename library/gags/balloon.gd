## library:balloon — a balloon on a string, held by someone, that can slip away and float up
## (losing a dream, a wish, a business; or something rising happily). Carries an optional
## shape hanging under it ("phone", "card", ...: any reveal shape).
##
##   {"id": "dream", "script": "library:balloon", "t": ..., "at": {"anchor": "m", "offset": [0.3, 0.9, 0.2]},
##    "params": {"hold": "m.hand", "release": {"line": "n1c", "word": "lost"}, "rise": 1.1, "drift": [0.25, 0, -0.35],
##               "color": "#e8343c", "carry": "phone", "carry_color": "#16181d", "size": 0.55, "seed": 2}}
##
## "at" is a fixed spot by the hand; before "release" the string runs from "hold" (the moving hand)
## up to the balloon, which bobs. After it the balloon rises (eases in, then "rise" m/s),
## drifts and sways, the string dangling under it. Anchors: "<id>.balloon", "<id>.hand".
extends RefCounted

const Toon = preload("res://scripts/actors/toon.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")


func validate(g: Dictionary) -> Array:
	var e := []
	for k in g.get("params", {}):
		if not (k in ["release", "hold", "rise", "drift", "color", "carry", "carry_color", "carry_size", "size", "length", "seed"]):
			e.append("balloon: unknown param '%s'" % k)
	return e


func build(g: Dictionary) -> Node3D:
	var p: Dictionary = g.get("params", {})
	var size := float(p.get("size", 0.5))
	var n := Node3D.new()
	var b := Node3D.new()
	b.name = "balloon"
	n.add_child(b)
	var body := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = size * 0.5
	sm.height = size * 1.15
	body.mesh = sm
	var mat := Toon.material(Color(String(p.get("color", "#e8343c"))), Toon.OUTLINE * 0.6).duplicate() as StandardMaterial3D
	mat.roughness = 0.25
	mat.metallic_specular = 0.8
	body.material_override = mat
	b.add_child(body)
	var knot := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = size * 0.05
	cm.bottom_radius = size * 0.1
	cm.height = size * 0.1
	knot.mesh = cm
	knot.material_override = mat
	knot.position = Vector3(0, -size * 0.6, 0)
	b.add_child(knot)
	if p.has("carry"):
		var c := Reveals.shape_node(String(p["carry"]), float(p.get("carry_size", size * 0.55)),
			Color(String(p.get("carry_color", "#16181d"))))
		c.name = "carry"
		n.add_child(c)
	var s := MeshInstance3D.new()
	s.name = "string"
	var sc := CylinderMesh.new()
	sc.top_radius = 0.005
	sc.bottom_radius = 0.005
	sc.height = 1.0
	s.mesh = sc
	s.material_override = Toon.material(Color("f4f4f2"), 0.0)
	n.add_child(s)
	return n


func _span(mi: Node3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var len := maxf(d.length(), 0.001)
	var y := d / len
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y * len, x.cross(y)), (a + b) * 0.5)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	var size := float(p.get("size", 0.5))
	var length := float(p.get("length", 0.9))
	var release := float(p.get("release", INF))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s/%d" % [g["id"], int(p.get("seed", 0))])
	var phase := rng.randf() * TAU
	var sway := Vector3(sin(t * 1.7 + phase) * 0.06, sin(t * 2.3 + phase) * 0.03, cos(t * 1.3 + phase) * 0.04)
	# The gag stands where the string is held ("at": a fixed point by the hand); "hold" (optional,
	# e.g. "m.hand") pins the string's end to the moving hand until the release.
	var hand := Vector3.ZERO
	if p.has("hold") and t < release:
		var h: Dictionary = ctx["point"].call(p["hold"])
		if not h.has("error"):
			hand = node.to_local(h["pos"])
	var bpos := Vector3(0, length, 0) + sway
	if t >= release:
		# Rise: eases in over 0.6 s, then climbs at "rise" m/s, drifting and swaying more.
		var dt := t - release
		var up := float(p.get("rise", 1.0)) * (dt * dt / 1.2 if dt < 0.6 else dt - 0.3)
		var dr: Array = p.get("drift", [0.2, 0, -0.3])
		var wob := Vector3(sin(dt * 2.6 + phase) * 0.12, 0, cos(dt * 1.9 + phase) * 0.08)
		bpos += Vector3(0, up, 0) + Vector3(float(dr[0]), float(dr[1]), float(dr[2])) * dt + wob
		hand = bpos - Vector3(sin(dt * 3.0 + phase) * 0.12, length, 0)
	var b := node.get_node("balloon") as Node3D
	b.position = bpos
	b.rotation = Vector3(sway.z * 2.0, 0, -sway.x * 2.0)
	var knot := bpos + Vector3(0, -size * 0.65, 0)
	if node.has_node("carry"):
		var c := node.get_node("carry") as Node3D
		var cs := float(p.get("carry_size", size * 0.55))
		# The carried thing hangs from the string, a third of the way down.
		c.position = knot + Vector3(0, -length * 0.3 - cs, 0)
		c.rotation = Vector3(0, sin(t * 1.1 + phase) * 0.4, 0)
	_span(node.get_node("string") as Node3D, hand, knot)
	return {"balloon": node.to_global(bpos), "hand": node.to_global(hand)}
