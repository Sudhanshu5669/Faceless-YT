## A clinic handout turns the data-as-oxygen metaphor into two physical transfers.
extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")
const TANK_SIZE := 0.56
const PHONE_SIZE := 0.263
const HOSE_SEGMENTS := 12


func build(_gag: Dictionary) -> Node3D:
	var clinic := Node3D.new()
	_dress_clinic(clinic)
	clinic.add_child(_stethoscope())
	for index in 2:
		var kit := Node3D.new()
		kit.name = "kit_%d" % index
		clinic.add_child(kit)
		var tank := _tank(TANK_SIZE)
		tank.name = "tank"
		kit.add_child(tank)
		kit.add_child(_phone())
		kit.add_child(_hose())
	return clinic


func _dress_clinic(clinic: Node3D) -> void:
	var tile := Kit.mat("9aa9a2")
	var trim := Kit.mat("5c7776", 0.63)
	var dark := Kit.mat("2f4c4f")
	Kit.add_box(clinic, Vector3(5.5, 2.34, 0.12), Vector3(0, 1.17, -1.64), tile)
	Kit.add_box(clinic, Vector3(5.5, 0.12, 0.13), Vector3(0, 0.06, -1.59), trim)
	Kit.add_box(clinic, Vector3(5.5, 0.075, 0.11), Vector3(0, 0.96, -1.58), trim)
	Kit.add_box(clinic, Vector3(1.77, 0.44, 0.06), Vector3(0, 1.97, -1.55), dark)
	Kit.add_box(clinic, Vector3(1.69, 0.36, 0.035), Vector3(0, 1.97, -1.50), Kit.mat("366a67"))
	_text(clinic, "OXYGEN STATION", 0.105, "ecf6e9", Vector3(0, 2.04, -1.477))
	_text(clinic, "ऑक्सीजन", 0.075, "bedad2", Vector3(0, 1.90, -1.477))
	for x in [-0.72, 0.72]:
		Kit.add_box(clinic, Vector3(0.035, 0.13, 0.013), Vector3(x, 2.02, -1.472), _ink("c5e8d3"))
		Kit.add_box(clinic, Vector3(0.13, 0.035, 0.013), Vector3(x, 2.02, -1.472), _ink("c5e8d3"))
	var bench := KitDB.static_node("quaternius_fantasy_props/Bench", 0.67)
	bench.position = Vector3(-0.30, 0.0, -1.19)
	clinic.add_child(bench)
	var cabinet := KitDB.static_node("quaternius_fantasy_props/Cabinet", 0.68)
	cabinet.position = Vector3(1.09, 0, -1.12)
	clinic.add_child(cabinet)
	for index in 2:
		var spare := _tank(0.43)
		spare.position = Vector3(0.92 + index * 0.23, 0.68, -1.07)
		spare.rotation_degrees.y = -11 + 18 * index
		clinic.add_child(spare)
	var planter := KitDB.static_node("quaternius_downtown/Prop_Planter_Single", 0.30)
	planter.position = Vector3(-1.41, 0, -1.04)
	clinic.add_child(planter)
	var plant := KitDB.static_node("quaternius_nature/Plant_2", 0.43)
	plant.position = Vector3(-1.41, 0.17, -1.04)
	clinic.add_child(plant)
	_light(clinic, Vector3(0, 2.35, 1.48), "fff2d6", 1.20, 4.5)
	_light(clinic, Vector3(0.65, 1.80, -0.75), "91d4d6", 1.10, 3.1)


func _tank(size: float) -> Node3D:
	var tank := Reveals.shape_node("tank", size, Color("29816e"))
	Kit.add_box(tank, Vector3(size * 0.22, size * 0.17, 0.009),
		Vector3(0, size * 0.40, size * 0.164), _ink("e0e9d3"))
	_text(tank, "O₂", size * 0.117, "37625e", Vector3(0, size * 0.401, size * 0.177))
	Kit.add_mesh(tank, Kit.cylinder(size * 0.105, size * 0.105, 0.024, Kit.mat("b0b5a7", 0.43, 0.40), 20),
		Vector3(0, 0.014, 0))
	return tank


func _phone() -> Node3D:
	var phone := Reveals.shape_node("phone", PHONE_SIZE, Color("233b49"))
	phone.name = "phone"
	Kit.add_box(phone, Vector3(0.111, 0.224, 0.003),
		Vector3(0, PHONE_SIZE * 0.5, 0.011), _ink("233544"))
	for index in 4:
		var bar := Kit.add_box(phone, Vector3(0.012, 0.026 + index * 0.018, 0.003),
			Vector3(-0.032 + index * 0.021, 0.108 + index * 0.009, 0.014), _ink("65e8ab"))
		bar.name = "bar_%d" % index
		bar.hide()
	Kit.add_box(phone, Vector3(0.032, 0.006, 0.002), Vector3(0, 0.036, 0.014), _ink("a3c2be"))
	return phone


func _hose() -> Node3D:
	var tube := Node3D.new()
	tube.name = "hose"
	for index in HOSE_SEGMENTS:
		var segment := Reveals.shape_node("link", 0.019, Color("61bdb1"))
		segment.name = "segment_%d" % index
		tube.add_child(segment)
	var plug := Kit.add_mesh(tube, Kit.cylinder(0.019, 0.019, 0.031, Kit.mat("c5b78b"), 12),
		Vector3.ZERO, Vector3.ZERO, "plug", false)
	plug.hide()
	var pulse := Kit.add_mesh(tube, Kit.sphere(0.028, 0.056, _ink("c3ffe1")),
		Vector3.ZERO, Vector3.ZERO, "pulse", false)
	pulse.hide()
	tube.hide()
	return tube


func _stethoscope() -> Node3D:
	var scope := Node3D.new()
	scope.name = "stethoscope"
	var rubber := Kit.mat("293d48", 0.70)
	var silver := Kit.mat("b9c8c8", 0.36, 0.47)
	var points := [Vector3(-0.104, 0.105, -0.012), Vector3(-0.107, -0.041, 0.036),
		Vector3(-0.065, -0.119, 0.052), Vector3(0.006, -0.143, 0.059), Vector3(0.077, -0.091, 0.05),
		Vector3(0.102, 0.016, 0.027), Vector3(0.077, 0.105, -0.012)]
	for index in points.size() - 1:
		var a: Vector3 = points[index]
		var b: Vector3 = points[index + 1]
		var segment := Kit.add_mesh(scope, Kit.cylinder(0.010, 0.010, a.distance_to(b) + 0.007, rubber, 10),
			(a + b) * 0.5)
		segment.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	Kit.add_mesh(scope, Kit.cylinder(0.038, 0.035, 0.016, silver, 18),
		Vector3(0.006, -0.147, 0.066), Vector3(90, 0, 0))
	return scope


func _ink(color: String) -> StandardMaterial3D:
	var mat := Kit.mat(color).duplicate() as StandardMaterial3D
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


func _text(root: Node3D, value: String, size: float, color: String, at: Vector3) -> void:
	var label := Reveals.text_node(value, size, Color(color))
	label.material_override = _ink(color)
	label.position = at
	root.add_child(label)


func _light(root: Node3D, at: Vector3, color: String, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = Color(color)
	light.light_energy = energy
	light.omni_range = reach
	root.add_child(light)


func pose(clinic: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var origin: Vector3 = ctx["holder"].position
	var doctor = ctx["actor"].call("doctor_mukesh")
	var scope := clinic.get_node("stethoscope") as Node3D
	var chest: Vector3 = doctor.bone_world("spine_03")
	scope.position = chest - origin + Vector3(0, 0.032, 0.16)
	for index in 2:
		var recipient = ctx["actor"].call("oxygen_recipient_%d" % index)
		var kit := clinic.get_node("kit_%d" % index) as Node3D
		var side := -1.0 if index == 0 else 1.0
		_pose_handoff(kit, doctor, recipient, side, origin, float(p["handoffs"][index]), t)
	var push := Motion.smooth(Motion.seg(t, float(gag["t"]), float(p["end"])))
	var camera := Vector3(0.22, 1.63, 4.25).lerp(Vector3(0.14, 1.50, 3.75), push)
	var focus := Vector3(0, 1.04, 0.19).lerp(Vector3(0.016, 1.02, 0.24), push)
	return {"camera": origin + camera, "focus": origin + focus}


func _pose_handoff(kit: Node3D, doctor, recipient, side: float, origin: Vector3, contact: float, t: float) -> void:
	var doc_arm := "r" if side < 0 else "l"
	var receive_arm := "l" if side < 0 else "r"
	var offer := Motion.smooth(Motion.seg(t, contact - 0.62, contact))
	var release := Motion.smooth(Motion.seg(t, contact + 0.07, contact + 0.30))
	var receive := Motion.smooth(Motion.seg(t, contact - 0.24, contact))
	var take := Motion.smooth(Motion.seg(t, contact + 0.04, contact + 0.36))
	var trade := Motion.smooth(Motion.seg(t, contact - 0.02, contact + 0.10))
	var meet := Vector3(side * 0.37, 0.84, 0.31)
	var doc_grip := Motion.arc(Vector3(side * 0.24, 0.73, 0.10), meet, 0.042, offer)
	doc_grip = doc_grip.lerp(Vector3(side * 0.26, 0.68, 0.11), release)
	doctor.aim_hand(doc_arm, origin + doc_grip, 1.0 - release, 0.052)
	var rec_grip := Motion.arc(Vector3(side * 0.56, 0.64, 0.57), meet, 0.035, receive)
	rec_grip = Motion.arc(rec_grip, Vector3(side * 0.55, 0.74, 0.64), 0.033, take)
	recipient.aim_hand(receive_arm, origin + rec_grip, 1.0, 0.044)
	var doc_hand: Vector3 = doctor.bone_world("hand_" + doc_arm)
	var rec_hand: Vector3 = recipient.bone_world("hand_" + receive_arm)
	var tank := kit.get_node("tank") as Node3D
	tank.rotation = Vector3(-0.15 + 0.16 * take, -side * 0.12, side * (0.12 - take * 0.12))
	tank.position = doc_hand.lerp(rec_hand, trade) - origin - tank.basis * Vector3(-side * 0.086, 0.25, 0.017)

	var check := Motion.smooth(Motion.seg(t, contact + 0.01, contact + 0.37))
	var phone_hand := Motion.arc(Vector3(side * 0.89, 0.64, 0.59),
		Vector3(side * 0.89, 0.98, 0.68), 0.034, check)
	recipient.aim_hand(doc_arm, origin + phone_hand, 1.0, 0.052)
	var phone := kit.get_node("phone") as Node3D
	phone.rotation = Vector3(lerpf(-0.46, -0.15, check), -side * 0.20, side * 0.09)
	phone.position = recipient.bone_world("hand_" + doc_arm) - origin - phone.basis * Vector3(side * 0.034, 0.048, 0)

	var valve := tank.position + tank.basis * Vector3(0, TANK_SIZE * 0.96, 0.034)
	var port := phone.position + phone.basis * Vector3(0, 0.015, 0.015)
	var age := t - contact
	_pose_hose(kit.get_node("hose"), valve, port, age)
	for index in 4:
		(phone.get_node("bar_%d" % index) as Node3D).visible = age >= 0.27 + 0.047 * index


func _hose_point(valve: Vector3, port: Vector3, k: float) -> Vector3:
	var bow := sin(PI * k)
	return valve.lerp(port, k) + Vector3(0, -0.098 * bow, 0.068 * bow)


func _pose_hose(hose: Node3D, valve: Vector3, port: Vector3, age: float) -> void:
	var reach := Motion.out_cubic(Motion.seg(age, 0.035, 0.25))
	hose.visible = reach > 0.002
	for index in HOSE_SEGMENTS:
		var a := _hose_point(valve, port, reach * float(index) / HOSE_SEGMENTS)
		var b := _hose_point(valve, port, reach * float(index + 1) / HOSE_SEGMENTS)
		var delta := b - a
		var segment := hose.get_node("segment_%d" % index) as Node3D
		if delta.length_squared() > 0.0000001:
			var aim := Basis(Quaternion(Vector3.UP, delta.normalized()))
			segment.transform = Transform3D(aim.scaled_local(Vector3(1, delta.length() + 0.006, 1)), a)
	var plug := hose.get_node("plug") as Node3D
	plug.position = _hose_point(valve, port, reach)
	plug.visible = reach > 0.002
	var pulse := hose.get_node("pulse") as Node3D
	var flow := Motion.seg(age, 0.25, 0.45)
	pulse.visible = age >= 0.25 and flow < 1.0
	pulse.position = _hose_point(valve, port, flow)
