## library:cash_stream — bills fly in arcs from a source and pile up on a target
## (cash cannons, money rain, burying someone in money). A heap that grows as they land.
##
##   {"id": "cash", "script": "library:cash_stream", "t": <start>, "at": <where the heap sits>,
##    "params": {"from": "cannon.muzzle", "fire": {"line": "n8d", "word": "buy"},
##               "duration": 1.0, "count": 260, "radius": 0.9, "height": 0.9,
##               "flight": 0.45, "arc": 0.8, "size": 0.16, "seed": 3}}
##
## from: point the bills leave (any anchor/offset); defaults to 2 m above the heap.
## Anchors: "<id>.top" (top of the heap now), "<id>.landing" (heap centre).
extends RefCounted

const Toon = preload("res://scripts/actors/toon.gd")


func validate(g: Dictionary) -> Array:
	var e := []
	var p: Dictionary = g.get("params", {})
	for k in p:
		if not (k in ["from", "fire", "duration", "count", "radius", "height", "flight", "arc", "size", "seed", "color"]):
			e.append("cash_stream: unknown param '%s'" % k)
	if int(p.get("count", 200)) < 1 or int(p.get("count", 200)) > 2000:
		e.append("cash_stream: count must be 1..2000")
	return e


func build(g: Dictionary) -> Node3D:
	var p: Dictionary = g.get("params", {})
	var size := float(p.get("size", 0.16))
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size, size * 0.03, size * 0.46)
	mesh.material = Toon.material(Color(String(p.get("color", "#4fbf6a"))), 0.0)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = int(p.get("count", 200))
	mm.mesh = mesh
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.name = "bills"
	var n := Node3D.new()
	n.add_child(mmi)
	return n


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	var mmi := node.get_node("bills") as MultiMeshInstance3D
	var mm := mmi.multimesh
	var count := mm.instance_count
	var fire := float(p.get("fire", g["t"]))
	var dur := float(p.get("duration", 1.0))
	var radius := float(p.get("radius", 0.8))
	var height := float(p.get("height", 0.8))
	var flight := float(p.get("flight", 0.45))
	var arc := float(p.get("arc", 0.8))
	var land_c: Vector3 = (ctx["holder"] as Node3D).global_position
	var src := land_c + Vector3(0, 2.0, 0)
	if p.has("from"):
		var f: Dictionary = ctx["point"].call(p["from"])
		if not f.has("error"):
			src = f["pos"]
	var inv := mmi.global_transform.affine_inverse()
	var rng := RandomNumberGenerator.new()
	var landed := 0
	for i in count:
		# Per-bill randoms, the same every frame (seeded by gag id + index): pure in t.
		rng.seed = hash("%s/%d/%d" % [g["id"], int(p.get("seed", 0)), i])
		var ti := fire + dur * (float(i) + rng.randf()) / float(count)
		var a := rng.randf() * TAU
		var r := radius * sqrt(rng.randf())
		var k := float(i) / float(count)
		# The heap rises as more bills land: a soft cone, highest in the middle.
		var h := height * pow(k, 0.7) * pow(maxf(0.0, 1.0 - r / radius), 0.8)
		var land := land_c + Vector3(cos(a) * r, h, sin(a) * r)
		var tumble := Vector3(rng.randf_range(-6, 6), rng.randf_range(-6, 6), rng.randf_range(-6, 6))
		var rest := Basis.from_euler(Vector3(rng.randf_range(-0.25, 0.25), rng.randf() * TAU, rng.randf_range(-0.25, 0.25)))
		var tr: Transform3D
		if t < ti:
			tr = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.001), src)
		elif t < ti + flight:
			var u := (t - ti) / flight
			var pos := src.lerp(land, u) + Vector3.UP * arc * 4.0 * u * (1.0 - u)
			tr = Transform3D(Basis.from_euler(tumble * u), pos)
		else:
			tr = Transform3D(rest, land)
			landed += 1
		mm.set_instance_transform(i, inv * tr)
	var frac := float(landed) / float(count)
	return {"top": land_c + Vector3(0, height * pow(frac, 0.7), 0), "landing": land_c}
