extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")

const GATE := Vector3(-0.58, 0.0, 0.65)
const CLOCK := Vector3(0.0, 2.31, 0.68)


func build(_gag: Dictionary) -> Node3D:
	var store := Node3D.new()
	_build_interior(store)
	_build_gate(store)
	_build_clock(store)
	return store


func _build_interior(store: Node3D) -> void:
	var blue := Kit.mat("192e57", 0.60)
	var trim := Kit.mat("384558", 0.34, 0.35)
	var dark := Kit.mat("111621", 0.58)
	var light := Kit.glow_mat("a6d3ff", 0.80)
	var warm := Kit.glow_mat("ffe4c0", 0.45)
	# The camera is inside the same branch. The runners emerge through its vestibule.
	for side in [-1.0, 1.0]:
		var x: float = side * 2.49
		Kit.add_box(store, Vector3(3.25, 3.08, 0.22), Vector3(x, 1.54, -3.35), blue)
		Kit.add_box(store, Vector3(0.045, 2.78, 0.07), Vector3(side * 0.84, 1.39, -3.21), light, 0, "", false)
		Kit.add_box(store, Vector3(0.34, 0.015, 4.45), Vector3(side * 0.62, 0.012, -1.21), dark)
		Kit.add_box(store, Vector3(0.026, 0.021, 3.28), Vector3(side * 0.57, 0.017, -0.71), light, 0, "", false)
		for z in [-2.88, -1.85, -0.83]:
			Kit.add_box(store, Vector3(0.06, 0.79, 0.06), Vector3(side * 0.65, 0.395, z), trim)
		Kit.add_box(store, Vector3(0.048, 0.047, 2.05), Vector3(side * 0.65, 0.76, -1.86), trim)
	Kit.add_box(store, Vector3(8.0, 0.58, 0.26), Vector3(0, 2.84, -3.33), trim)
	_label(store, "Reliance Digital Express", 0.23, Vector3(-0.86, 2.84, -3.19), "eef5ff")
	Kit.add_box(store, Vector3(1.90, 2.6, 0.1), Vector3(0, 1.3, -5.15), dark)
	Kit.add_box(store, Vector3(8.6, 0.10, 12.0), Vector3(0, 3.97, 0), dark)
	for z in [-2.28, -0.40, 1.75, 3.4]:
		for x in [-2.34, 2.34]:
			Kit.add_box(store, Vector3(0.58, 0.032, 0.14), Vector3(x, 3.90, z), warm, 0, "", false)
	var checkout := KitDB.static_node("fab_store_racks/Store Racks Pack#Cube", 0.91,
		{"c65016": "#365786", "ffe5b4": "#637b9a"})
	if checkout != null:
		checkout.position = Vector3(-2.2, 0, 0.03)
		checkout.rotation.y = PI * 0.5
		store.add_child(checkout)
	var planter := KitDB.static_node("kenney_suburban/planter", 2.5)
	if planter != null:
		planter.position = Vector3(1.78, 0, -2.55)
		store.add_child(planter)
	_omni(store, Vector3(0, 2.20, -2.95), "54a4ff", 2.7, 4.6)
	_omni(store, Vector3(0.2, 2.74, 2.10), "ffe1b7", 2.8, 5.1)
	_omni(store, Vector3(1.31, 1.75, 0.74), "8abaff", 1.3, 3.6)


func _build_gate(store: Node3D) -> void:
	var steel := Kit.mat("adb8c4", 0.29, 0.65)
	var graphite := Kit.mat("293342", 0.41, 0.23)
	Kit.add_box(store, Vector3(0.31, 0.06, 0.43), GATE + Vector3(0, 0.03, 0), steel)
	Kit.add_box(store, Vector3(0.25, 0.74, 0.35), GATE + Vector3(0, 0.40, 0), graphite)
	Kit.add_box(store, Vector3(0.28, 0.085, 0.39), GATE + Vector3(0, 0.81, 0), steel)
	var signal_lamp := Kit.add_box(store, Vector3(0.09, 0.011, 0.091), GATE + Vector3(0, 0.86, 0.09),
		Kit.glow_mat("66ffbb", 0.8), 0, "signal", false)
	signal_lamp.material_override = signal_lamp.mesh.surface_get_material(0).duplicate()
	var rotor := Node3D.new()
	rotor.name = "rotor"
	rotor.position = GATE + Vector3(0.15, 0.69, 0)
	store.add_child(rotor)
	var axle := Node3D.new()
	axle.rotation.z = -PI * 0.25
	rotor.add_child(axle)
	Kit.add_mesh(axle, Kit.cylinder(0.076, 0.076, 0.12, steel, 24), Vector3.ZERO)
	var arms := Node3D.new()
	arms.name = "arms"
	axle.name = "axle"
	axle.add_child(arms)
	for index in 3:
		var spoke := Node3D.new()
		spoke.rotation.y = index * TAU / 3.0
		arms.add_child(spoke)
		var direction := Vector3(1, -1, 0).normalized()
		var bar := Kit.add_mesh(spoke, Kit.cylinder(0.022, 0.022, 0.57, steel, 16), direction * 0.28)
		bar.quaternion = Quaternion(Vector3.UP, direction)
		Kit.add_mesh(spoke, Kit.sphere(0.022, 0.022, steel, 12), direction * 0.56)
	Kit.add_box(store, Vector3(0.12, 0.76, 0.28), Vector3(0.64, 0.38, 0.65), graphite)
	Kit.add_box(store, Vector3(0.16, 0.035, 0.30), Vector3(0.64, 0.77, 0.65), steel)


func _build_clock(store: Node3D) -> void:
	var chrome := Kit.mat("8098b5", 0.30, 0.52)
	var face := Kit.mat("e8edf2", 0.52)
	var ink := Kit.mat("172436", 0.55)
	var blue := Kit.mat("2760ce", 0.5)
	var red := Kit.mat("dc4544", 0.42)
	Kit.add_box(store, Vector3(0.043, 0.15, 0.045), CLOCK + Vector3(0, 0.39, -0.045), chrome)
	Kit.add_box(store, Vector3(0.04, 0.04, 4.0), CLOCK + Vector3(0, 0.45, -2.0), chrome)
	Kit.add_mesh(store, Kit.cylinder(0.352, 0.352, 0.075, chrome, 48), CLOCK, Vector3(90, 0, 0))
	Kit.add_mesh(store, Kit.cylinder(0.315, 0.315, 0.010, face, 48), CLOCK + Vector3(0, 0, 0.04), Vector3(90, 0, 0))
	for index in 60:
		var angle := index * TAU / 60.0
		var hour := index % 5 == 0
		var mark := Kit.add_box(store, Vector3(0.017 if hour else 0.006, 0.038 if hour else 0.014, 0.004),
			CLOCK + Vector3(sin(angle) * 0.277, cos(angle) * 0.277, 0.048), ink, 0, "", false)
		mark.rotation.z = -angle
	_label(store, "Jio", 0.096, CLOCK + Vector3(0, -0.105, 0.052), "2555aa")
	_clock_hand(store, "minute", 0.195, 0.017, blue, 0.054)
	_clock_hand(store, "hour", 0.126, 0.023, ink, 0.058)
	_clock_hand(store, "seconds", 0.235, 0.008, red, 0.066)
	Kit.add_mesh(store, Kit.cylinder(0.019, 0.019, 0.018, red, 14), CLOCK + Vector3(0, 0, 0.074), Vector3(90, 0, 0))


func _clock_hand(store: Node3D, id: String, length: float, width: float, material: Material, depth: float) -> void:
	var hand := Node3D.new()
	hand.name = id
	hand.position = CLOCK + Vector3(0, 0, depth)
	store.add_child(hand)
	Kit.add_box(hand, Vector3(width, length + 0.045, 0.009), Vector3(0, (length - 0.045) * 0.5, 0),
		material, 0, "", false)


func pose(store: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var params: Dictionary = gag["params"]
	var rush := float(params["rush"])
	var days := float(params["days"])
	var fast_forward := Motion.in_out(Motion.seg(t, float(gag["t"]) + 0.20, days))
	var tick := 0.0
	for second in 2:
		var at := rush + second
		tick += Motion.out_back(Motion.seg(t, at - 0.045, at + 0.15), 1.4)
	(store.get_node("seconds") as Node3D).rotation.z = -(fast_forward * TAU * 3.0 + tick * TAU / 60.0)
	(store.get_node("minute") as Node3D).rotation.z = -0.95 - fast_forward * TAU
	(store.get_node("hour") as Node3D).rotation.z = 0.95 - fast_forward * TAU / 12.0
	var rotation_steps := 0.0
	var signal_flash := 0.0
	for crossing in params["crossings"]:
		var hit := float(crossing)
		rotation_steps += Motion.out_cubic(Motion.seg(t, hit - 0.045, hit + 0.065))
		signal_flash = maxf(signal_flash, 1.0 - absf(t - hit) / 0.085)
	(store.get_node("rotor/axle/arms") as Node3D).rotation.y = rotation_steps * TAU / 3.0
	var lamp := store.get_node("signal") as MeshInstance3D
	(lamp.material_override as StandardMaterial3D).emission_energy_multiplier = 0.25 + 1.8 * signal_flash
	var ease := Motion.smooth(Motion.seg(t, float(gag["t"]), rush))
	var wide := Motion.smooth(Motion.seg(t, rush - 0.24, rush + 0.90))
	var settle := Motion.smooth(Motion.seg(t, rush + 1.0, rush + 2.55))
	var camera := Vector3(1.79, 1.86, 4.78).lerp(Vector3(1.56, 1.90, 4.54), ease)
	camera = camera.lerp(Vector3(3.95, 2.86, 4.24), wide)
	camera = camera.lerp(Vector3(4.06, 2.97, 4.26), settle)
	var focus := Vector3(0, 1.96, 0.45).lerp(Vector3(0.14, 1.60, 0.45), wide)
	var origin: Vector3 = ctx["holder"].position
	var last_crossing := float(params["crossings"][-1])
	var last = ctx["actor"].call("gate_customer_%d" % (params["crossings"].size() - 1))
	var wave := Motion.smooth(Motion.seg(t, last_crossing + 0.36, last_crossing + 0.54))
	if wave > 0.0:
		var shoulder: Vector3 = last.bone_world("upperarm_l")
		var lift := 0.42 + 0.045 * sin((t - last_crossing) * 24.0)
		last.aim_hand("l", shoulder + Vector3(0.11, lift, 0.19), wave)
	return {"camera": origin + camera, "focus": origin + focus}


func _label(root: Node3D, title: String, height: float, at: Vector3, color: String) -> void:
	var text := Reveals.text_node(title, height, Color(color))
	text.position = at
	root.add_child(text)


func _omni(root: Node3D, at: Vector3, color: String, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = Color(color)
	light.light_energy = energy
	light.omni_range = reach
	root.add_child(light)
