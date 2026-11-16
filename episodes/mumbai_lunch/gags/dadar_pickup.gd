extends RefCounted
## A doorstep handoff, a last space in the rear rack, and the loaded bicycle rolling away.

const Motion = preload("res://scripts/timeline/motion.gd")
const Meshes = preload("res://scripts/world/builders/kitchen_dressing.gd")
const Tiffin = preload("res://scripts/world/builders/steel_tiffin.gd")
const DOORSTEP := Vector3(-0.68, 1.04, -0.24)
const RACK_SLOT := Vector3(-0.69, 0.84, 0.14)
const GRIP := Vector3(0, Tiffin.HANDLE_HEIGHT, -0.023)
const HANDLEBAR := Vector3(0.53, 1.02, -0.21)
const WHEEL_RADIUS := 0.35


func build(_gag: Dictionary) -> Node3D:
	var root := Node3D.new()
	_build_facades(root)
	var bike := _build_bicycle()
	root.add_child(bike)
	var hero := Tiffin.build()
	hero.name = "hero"
	root.add_child(hero)
	var cap := Node3D.new()
	cap.name = "cap"
	var cotton := Meshes.material(Color("#f5efdf"), 0.94)
	var crown := Tiffin._disc(cap, 0.172, 0.094, Vector3.ZERO, cotton)
	crown.scale.z = 0.73
	var rim := Tiffin._disc(cap, 0.175, 0.016, Vector3.DOWN * 0.046, cotton)
	rim.scale.z = 0.75
	root.add_child(cap)
	return root


func pose(root: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var handoff := float(p["handoff"])
	var load_at := float(p["load"])
	var roll_at := float(p["roll"])
	var holder := ctx["holder"] as Node3D
	var bike := root.get_node("bike") as Node3D
	var hero := root.get_node("hero") as Node3D
	var loading := Motion.smooth(Motion.seg(t, handoff + 0.22, load_at))
	var travel := Motion.seg(t, roll_at, roll_at + 1.75)
	var offset := travel * travel * 1.55
	var impact := maxf(0.0, t - load_at)
	var lean := 0.12 * sin(impact * 15.0) * exp(-5.5 * impact)
	bike.position.x = offset
	bike.rotation.x = lean + 0.09 * sin(PI * travel)
	for wheel in ["rear", "front"]:
		var pivot := bike.get_node(wheel) as Node3D
		pivot.rotation.z = -offset / WHEEL_RADIUS

	hero.position = Motion.arc(DOORSTEP, RACK_SLOT, 0.16, loading)
	hero.rotation = Vector3(lerpf(0.53, 0.0, loading), lerpf(0.33, 0.0, loading), sin(PI * loading) * -0.13)
	if t >= load_at:
		hero.position = bike.position + bike.basis * RACK_SLOT
		hero.rotation = bike.rotation

	if ctx.has("actor"):
		var packer = ctx["actor"].call("door_packer")
		var courier = ctx["actor"].call("courier")
		var grip := holder.position + hero.position + hero.basis * GRIP
		if packer != null:
			var release := Motion.smooth(Motion.seg(t, handoff, handoff + 0.27))
			packer.aim_hand("l", grip + Vector3(-0.045, 0, 0), 1.0 - release, 0.04)
		if courier != null:
			var step_to_bar := Motion.smooth(Motion.seg(t, load_at + 0.13, roll_at + 0.25))
			courier.position.x += offset + step_to_bar * 0.46
			courier.rotation.y = lerp_angle(courier.rotation.y, PI * 0.43, Motion.smooth(Motion.seg(t, load_at, roll_at + 0.35)))
			var take := Motion.smooth(Motion.seg(t, handoff - 0.27, handoff))
			var let_go := Motion.smooth(Motion.seg(t, load_at, load_at + 0.25))
			courier.aim_hand("r", grip + Vector3(0.03, 0, 0), take * (1.0 - let_go))
			courier.aim_hand("l", holder.position + bike.position + bike.basis * HANDLEBAR, step_to_bar)
			var cap := root.get_node("cap") as Node3D
			cap.position = courier.anchor_points()["courier.head"]["pos"] - holder.position + Vector3.UP * 0.286
			cap.rotation.y = courier.rotation.y

	var wide := Motion.smooth(Motion.seg(t, handoff, load_at + 0.20))
	var focus := hero.position.lerp(Vector3(-0.06 + offset, 0.98, 0.02), wide)
	return {"focus": holder.position + focus + Vector3.UP * lerpf(0.26, 0.09, wide)}


func _build_bicycle() -> Node3D:
	var bike := Node3D.new()
	bike.name = "bike"
	var enamel := Meshes.material(Color("#173231"), 0.39, 0.48)
	var steel := Meshes.material(Color("#b5b8af"), 0.27, 0.82)
	var rubber := Meshes.material(Color("#252725"), 0.92)
	var leather := Meshes.material(Color("#4d382b"), 0.82)
	var rear := Vector3(-0.68, WHEEL_RADIUS, 0)
	var front := Vector3(0.68, WHEEL_RADIUS, 0)
	var crank := Vector3(-0.13, 0.35, 0)
	var seat := Vector3(-0.32, 0.82, 0)
	var neck := Vector3(0.49, 0.81, 0)
	_wheel(bike, "rear", rear, rubber, steel)
	_wheel(bike, "front", front, rubber, steel)
	for link in [[rear, seat], [rear, crank], [crank, seat], [seat, neck], [neck, crank], [neck, front]]:
		_tube(bike, link[0], link[1], 0.018, enamel)
	_tube(bike, seat, seat + Vector3.UP * 0.10, 0.015, steel)
	Meshes.box(bike, Vector3(0.23, 0.039, 0.13), seat + Vector3(-0.025, 0.11, 0), leather)
	_tube(bike, neck, Vector3(0.43, 1.00, 0), 0.016, steel)
	for side in [-1.0, 1.0]:
		var bend := Vector3(0.47, 1.025, 0.14 * side)
		var grip := Vector3(0.53, 1.02, 0.24 * side)
		_tube(bike, Vector3(0.43, 1.00, 0), bend, 0.012, steel)
		_tube(bike, bend, grip, 0.018, rubber)
		var stays := Vector3(rear.x, RACK_SLOT.y - 0.05, side * 0.27)
		_tube(bike, rear, stays, 0.013, steel)
		_tube(bike, stays + Vector3.LEFT * 0.29, stays + Vector3.RIGHT * 0.30, 0.018, enamel)
	for x in [-0.96, -0.78, -0.59, -0.39]:
		_tube(bike, Vector3(x, 0.82, -0.27), Vector3(x, 0.82, 0.27), 0.016, steel)
	_tube(bike, crank + Vector3.BACK * 0.11, crank + Vector3(0.07, -0.09, 0.11), 0.012, steel)
	Meshes.box(bike, Vector3(0.065, 0.022, 0.085), crank + Vector3(0.07, -0.09, 0.14), rubber)

	var spots := [Vector3(-0.94, 0.84, 0.13), Vector3(-0.43, 0.84, 0.13),
		Vector3(-0.94, 0.84, -0.12), Vector3(-0.69, 0.84, -0.12), Vector3(-0.43, 0.84, -0.12)]
	var markings := ["CH 2", "CH 7", "CH 3", "CH 5", "CH 1"]
	for i in spots.size():
		var cargo := Tiffin.build(markings[i])
		cargo.position = spots[i]
		cargo.scale.y = 0.74 + (i % 3) * 0.085
		bike.add_child(cargo)
	return bike


func _wheel(parent: Node3D, key: String, center: Vector3, rubber: Material, steel: Material) -> void:
	var pivot := Node3D.new()
	pivot.name = key
	pivot.position = center
	parent.add_child(pivot)
	_ring(pivot, WHEEL_RADIUS - 0.037, WHEEL_RADIUS, rubber)
	_ring(pivot, WHEEL_RADIUS - 0.054, WHEEL_RADIUS - 0.033, steel)
	_tube(pivot, Vector3.FORWARD * 0.041, Vector3.BACK * 0.041, 0.024, steel)
	for i in 16:
		var angle := TAU * i / 16.0
		var rim := Vector3(cos(angle), sin(angle), 0) * (WHEEL_RADIUS - 0.046)
		_tube(pivot, Vector3(0, 0, 0.027 if i % 2 else -0.027), rim, 0.003, steel)


func _ring(parent: Node3D, inner: float, outer: float, material: Material) -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = inner
	ring.outer_radius = outer
	ring.rings = 64
	ring.ring_segments = 12
	var instance := MeshInstance3D.new()
	instance.mesh = ring
	instance.material_override = material
	instance.rotation.x = PI * 0.5
	parent.add_child(instance)


func _tube(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var instance := Tiffin._disc(parent, radius, start.distance_to(end), (start + end) * 0.5, material)
	var direction := (end - start).normalized()
	instance.quaternion = Quaternion(Vector3.UP, direction)


func _build_facades(root: Node3D) -> void:
	var ochre := Meshes.material(Color("#a7886f"), 0.93)
	var plaster := Meshes.material(Color("#cbb498"), 0.96)
	var stone := Meshes.material(Color("#8e8575"), 0.93)
	var blue := Meshes.material(Color("#526b69"), 0.78)
	var iron := Meshes.material(Color("#3d433f"), 0.66, 0.35)
	var recess := Meshes.material(Color("#544032"), 0.95)
	var foliage := Meshes.material(Color("#777c4c"), 0.90)

	# Deep doorway, raised stone sill and a patterned grille on the street-facing window.
	Meshes.box(root, Vector3(1.18, 4.5, 0.35), Vector3(-1.99, 2.25, -1.67), plaster)
	Meshes.box(root, Vector3(4.9, 4.5, 0.35), Vector3(1.90, 2.25, -1.67), plaster)
	Meshes.box(root, Vector3(0.99, 2.42, 0.34), Vector3(-0.96, 3.26, -1.67), plaster)
	Meshes.box(root, Vector3(0.94, 2.06, 0.12), Vector3(-0.95, 1.03, -2.23), recess)
	for x in [-1.42, -0.50]:
		Meshes.box(root, Vector3(0.12, 2.08, 0.30), Vector3(x, 1.04, -1.47), blue)
	Meshes.box(root, Vector3(1.02, 0.12, 0.30), Vector3(-0.96, 2.07, -1.47), blue)
	Meshes.box(root, Vector3(1.06, 0.08, 0.51), Vector3(-0.96, 0.035, -1.34), stone)
	for y in [1.49, 3.12]:
		var center := Vector3(0.62, y, -1.46)
		Meshes.box(root, Vector3(1.27, 1.05, 0.055), center, recess)
		Meshes.box(root, Vector3(1.42, 0.10, 0.27), center + Vector3(0, -0.54, 0.04), stone)
		for i in 8:
			var x := -0.56 + i * 0.16
			Meshes.box(root, Vector3(0.018, 1.02, 0.04), center + Vector3(x, 0, 0.055), iron)
		for height in [-0.30, 0.14, 0.42]:
			Meshes.box(root, Vector3(1.27, 0.022, 0.04), center + Vector3(0, height, 0.064), iron)

	# Aging balcony bands, water pipe and darker adjacent facade build depth behind the handoff.
	for x in [-3.35, 4.70, 7.70]:
		Meshes.box(root, Vector3(3.1, 4.9, 0.55), Vector3(x, 2.45, -2.02), ochre)
		for y in [2.44, 4.06]:
			Meshes.box(root, Vector3(2.72, 0.15, 0.55), Vector3(x, y, -1.65), stone)
			Meshes.box(root, Vector3(2.28, 0.58, 0.045), Vector3(x, y + 0.5, -1.70), blue)
			for i in 13:
				Meshes.box(root, Vector3(0.019, 0.47, 0.029), Vector3(x - 1.31 + i * 0.217, y + 0.27, -1.39), iron)
			Meshes.box(root, Vector3(2.66, 0.038, 0.047), Vector3(x, y + 0.51, -1.39), iron)
	_tube(root, Vector3(1.42, 0.14, -1.35), Vector3(1.42, 4.2, -1.35), 0.026, blue)
	Meshes.box(root, Vector3(14.9, 0.08, 0.52), Vector3(0.5, 0.036, -1.27), stone)
	for x in [-1.67, 2.36]:
		var soil := Tiffin._disc(root, 0.12, 0.18, Vector3(x, 0.16, -1.15), ochre)
		soil.scale.x = 0.83
		for i in 6:
			var angle := TAU * i / 6.0
			var stem := Vector3(x, 0.23, -1.15)
			var tip := stem + Vector3(cos(angle) * 0.15, 0.22 + 0.033 * (i % 3), sin(angle) * 0.12)
			_tube(root, stem, tip, 0.013, foliage)
			var leaf := Tiffin._disc(root, 0.065, 0.012, tip, foliage)
			leaf.scale.z = 0.46
			leaf.rotation = Vector3(0.30, angle, 0.48)
