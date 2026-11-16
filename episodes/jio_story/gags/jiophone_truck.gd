extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")

const DECK := 0.78
const MOUNT := Vector3(-0.32, 1.39, 0.28)
const MUZZLE := Vector3(0, 0.07, 0.72)
const BATCH := 48
const BURSTS := 3


func build(_gag: Dictionary) -> Node3D:
	var lane := Node3D.new()
	var truck := KitDB.static_node("kenney_cars/truck-flat", 1.38)
	if truck != null:
		truck.position = Vector3(0, 0, -1.15)
		truck.rotation.y = PI
		lane.add_child(truck)
	var blue := Kit.mat("1643aa", 0.43)
	var steel := Kit.mat("344661", 0.38, 0.43)
	Kit.add_box(lane, Vector3(1.93, 0.065, 1.35), Vector3(0, DECK - 0.034, -0.38), steel)
	Kit.add_box(lane, Vector3(1.65, 0.21, 0.052), Vector3(0, DECK - 0.21, 0.87), blue)
	_label(lane, "JioPhone", 0.14, Vector3(0, DECK - 0.20, 0.904), "eef5ff")
	Kit.add_mesh(lane, Kit.cylinder(0.07, 0.19, MOUNT.y - DECK, steel, 24),
		Vector3(MOUNT.x, (MOUNT.y + DECK) * 0.5, MOUNT.z))
	var launcher := Node3D.new()
	launcher.name = "launcher"
	lane.add_child(launcher)
	Kit.add_box(launcher, Vector3(0.39, 0.35, 0.49), Vector3(0, 0.06, 0.07), blue)
	Kit.add_mesh(launcher, Kit.cylinder(0.14, 0.165, 0.59, steel, 32),
		Vector3(0, 0.07, 0.40), Vector3(90, 0, 0))
	Kit.add_mesh(launcher, Kit.cylinder(0.20, 0.20, 0.10, blue, 32),
		Vector3(0, 0.07, 0.68), Vector3(90, 0, 0))
	Kit.add_mesh(launcher, Kit.cylinder(0.142, 0.142, 0.012, Kit.mat("090d1a"), 32),
		MUZZLE + Vector3(0, 0, 0.016), Vector3(90, 0, 0))
	Kit.add_mesh(launcher, Kit.cylinder(0.035, 0.035, 0.38, steel, 16),
		Vector3(0, -0.08, -0.20), Vector3(0, 0, 90))
	Kit.add_box(launcher, Vector3(0.35, 0.08, 0.30), Vector3(0, 0.28, 0.09), steel)
	for i in 4:
		var loaded := _handset()
		loaded.scale *= 0.61
		loaded.rotation.x = -PI * 0.5
		loaded.position = Vector3(0, 0.33 + 0.024 * i, 0.09)
		launcher.add_child(loaded)
	var flash := Kit.add_mesh(launcher, Kit.sphere(0.13, 0.21, Kit.glow_mat("88ccff", 2.4), 18),
		MUZZLE + Vector3(0, 0, 0.17), Vector3(90, 0, 0), "flash", false)
	flash.hide()
	_build_stream(lane)
	_omni(lane, Vector3(-1.62, 2.62, 1.02), "ffdbb3", 2.8, 5.4)
	_omni(lane, Vector3(1.25, 2.45, -0.76), "599aff", 3.0, 5.4)
	_omni(lane, Vector3(0.15, 1.56, 3.07), "cad8ff", 1.65, 5.3)
	return lane


func _build_stream(lane: Node3D) -> void:
	var model := _handset()
	var root := Node3D.new()
	root.name = "phones"
	lane.add_child(root)
	# Each handset detail is instanced across the stream, keeping the keypad and Jio display readable.
	for child in model.get_children():
		var part := child as MeshInstance3D
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = part.mesh
		batch.instance_count = BATCH * BURSTS
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = batch
		instance.material_override = part.material_override
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.set_meta("local_part", part.transform)
		root.add_child(instance)
	model.free()


func _handset() -> Node3D:
	var phone := Node3D.new()
	var shell := Kit.mat("15191e", 0.36, 0.32)
	var rim := Kit.mat("404b58", 0.39, 0.25)
	var keys := Kit.mat("747e8a", 0.53)
	var display := Kit.glow_mat("18408e", 0.55)
	Kit.add_box(phone, Vector3(0.207, 0.431, 0.032), Vector3.ZERO, shell)
	Kit.add_box(phone, Vector3(0.198, 0.41, 0.006), Vector3(0, 0, 0.018), rim)
	Kit.add_box(phone, Vector3(0.177, 0.389, 0.004), Vector3(0, 0, 0.022), shell)
	Kit.add_box(phone, Vector3(0.157, 0.133, 0.004), Vector3(0, 0.098, 0.025), display)
	Kit.add_mesh(phone, Kit.cylinder(0.045, 0.045, 0.004, Kit.glow_mat("3464cf", 0.7), 24),
		Vector3(0, 0.098, 0.029), Vector3(90, 0, 0), "", false)
	_label(phone, "Jio", 0.035, Vector3(0, 0.10, 0.033), "ffffff")
	Kit.add_box(phone, Vector3(0.052, 0.005, 0.004), Vector3(0, 0.185, 0.024), keys)
	Kit.add_box(phone, Vector3(0.054, 0.035, 0.006), Vector3(0, -0.007, 0.027), keys)
	for side in [-1.0, 1.0]:
		Kit.add_box(phone, Vector3(0.034, 0.011, 0.005), Vector3(side * 0.059, -0.012, 0.028),
			Kit.glow_mat("57b87d" if side < 0 else "d95c55", 0.5))
	for row in 4:
		for col in 3:
			Kit.add_box(phone, Vector3(0.039, 0.017, 0.005),
				Vector3((col - 1) * 0.053, -0.056 - row * 0.031, 0.028), keys)
	return phone


func pose(lane: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var times: Array = p["releases"]
	var zero := float(p["zero"])
	var origin: Vector3 = ctx["holder"].position
	var mukesh = ctx["actor"].call("phone_mukesh")
	mukesh.body.position.y += DECK
	var launcher := lane.get_node("launcher") as Node3D
	launcher.transform = _launcher_at(times, t)
	mukesh.aim_hand("r", origin + launcher.transform * Vector3(-0.17, -0.08, -0.20))
	mukesh.aim_hand("l", origin + launcher.transform * Vector3(0.17, -0.08, -0.20))
	var flash := launcher.get_node("flash") as Node3D
	var flare := 0.0
	for time in times:
		var age := t - float(time)
		if age >= 0.0 and age < 0.15:
			flare = maxf(flare, 1.0 - age / 0.15)
	flash.visible = flare > 0.0
	flash.scale = Vector3.ONE * maxf(flare, 0.01)

	var heaps: Array[Vector3] = []
	for index in 4:
		var fan = ctx["actor"].call("phone_fan_%d" % index)
		var at: Vector3 = fan.position - origin
		heaps.append(at + Vector3(0, 0, 0.29))
		var surprise := Motion.smooth(Motion.seg(t, float(times[0]) + 0.12 + 0.055 * index,
			float(times[0]) + 0.45 + 0.055 * index))
		var buried := Motion.smooth(Motion.seg(t, float(times[1]) + 0.42, float(times[2]) + 0.78))
		fan.rotation.y = lerp_angle(fan.rotation.y, -0.23 if index % 2 else 0.15, buried)
		fan.body.position.y -= 0.28 * buried
		for arm in ["l", "r"]:
			var shoulder: Vector3 = fan.bone_world("upperarm_" + arm)
			var side := 1.0 if arm == "l" else -1.0
			fan.aim_hand(arm, shoulder + Vector3(-0.36 * side, 0.24 + 0.08 * sin(t * 10 + index), 0), surprise)
	_pose_stream(lane.get_node("phones"), heaps, times, t)

	var action := Motion.smooth(Motion.seg(t, float(gag["t"]), float(times[0])))
	var payoff := Motion.smooth(Motion.seg(t, float(times[2]) - 0.13, zero + 0.24))
	var camera := Vector3(-0.55, 2.55, 6.45).lerp(Vector3(-1.32, 2.29, 5.83), action)
	camera = camera.lerp(Vector3(-0.45, 2.55, 5.83), payoff)
	var focus := Vector3(0, 1.38, 0.47).lerp(Vector3(0, 1.56, 0.65), payoff)
	return {"camera": origin + camera, "focus": origin + focus}


func _launcher_at(times: Array, t: float) -> Transform3D:
	var yaw := -0.30 + 0.61 * Motion.smooth(Motion.seg(t, float(times[0]), float(times[2]) + 0.05))
	var kick := 0.0
	var anticipation := 0.0
	for time in times:
		var age := t - float(time)
		anticipation += Motion.wind_up(t, float(time), 0.17)
		if age >= 0.0:
			kick += exp(-age * 18.0)
	return Transform3D(Basis.from_euler(Vector3(-0.11 - 0.16 * kick + 0.12 * anticipation, yaw, 0)),
		MOUNT + Vector3(0, 0.027 * kick, -0.12 * kick))


func _pose_stream(root: Node3D, heaps: Array[Vector3], times: Array, t: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("jiophone_truck_handsets")
	var parts := root.get_children()
	for i in BATCH * BURSTS:
		var burst := i / BATCH
		var slot := i % BATCH
		var target := slot % heaps.size()
		var stack := i / heaps.size()
		var start := float(times[burst]) + slot * 0.007
		var flight := rng.randf_range(0.32, 0.58)
		var column := stack % 7
		var layer := stack / 7
		var angle := rng.randf_range(0.0, TAU)
		var spread := 0.22 - layer * 0.027
		var ring := TAU * float(column) / 7.0 + layer * 0.23
		var radius := spread + rng.randf_range(-0.027, 0.027)
		var height := 0.032 + layer * 0.091 + rng.randf_range(0, 0.022)
		var landing := heaps[target] + Vector3(cos(ring) * radius, height, sin(ring) * radius)
		var tilt := rng.randf_range(-0.28, 0.28)
		var turn := angle - PI
		var source := _launcher_at(times, start) * MUZZLE
		var k := Motion.seg(t, start, start + flight)
		var bounce := Motion.seg(t, start + flight, start + flight + 0.15)
		var point := Motion.arc(source, landing, 0.22 + radius * 0.68, k)
		point.y += 0.045 * sin(bounce * PI)
		var rotation := Vector3(-PI * 0.5 + tilt + (1.0 - k) * PI * 2.0, turn, tilt * 0.5)
		var scale := 0.52 if t >= start else 0.0001
		var transform := Transform3D(Basis.from_euler(rotation).scaled(Vector3.ONE * scale), point)
		for part in parts:
			part.multimesh.set_instance_transform(i, transform * (part.get_meta("local_part") as Transform3D))


func _label(root: Node3D, value: String, size: float, at: Vector3, color: String) -> void:
	var label := Reveals.text_node(value, size, Color(color))
	label.position = at
	root.add_child(label)


func _omni(root: Node3D, at: Vector3, color: String, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = Color(color)
	light.light_energy = energy
	light.omni_range = reach
	root.add_child(light)
