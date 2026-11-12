## Mukesh topples the old masts, then brings a new row up on their foundations.
extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")
const OLD_START := Vector3(-0.35, 0.028, 0.51)
const STEP := Vector3(0.24, 0, -0.94)
const NEW_OFFSET := Vector3(0.53, 0.058, 0.16)
const OLD_HEIGHT := 1.43
const NEW_HEIGHT := 1.67
const TOWER_COUNT := 4
const CONTROL := Vector3(-0.66, 0.0, 1.05)


func build(_gag: Dictionary) -> Node3D:
	var field := Node3D.new()
	_dress_field(field)
	field.add_child(_controls())
	for index in TOWER_COUNT:
		var old := _mast(OLD_HEIGHT, false)
		old.name = "old_%d" % index
		old.position = OLD_START + STEP * index
		field.add_child(old)
		var fresh := _mast(NEW_HEIGHT, true)
		fresh.name = "fresh_%d" % index
		field.add_child(fresh)
		var footing := OLD_START + STEP * index + NEW_OFFSET
		Kit.add_box(field, Vector3(0.42, 0.096, 0.40), footing - Vector3.UP * 0.040,
			Kit.mat("8f8a79"))
		Kit.add_box(field, Vector3(0.30, 0.030, 0.30), footing + Vector3.UP * 0.010,
			Kit.mat("b3b6a6"))
		if index < TOWER_COUNT - 1:
			var packet := Node3D.new()
			packet.name = "signal_%d" % index
			field.add_child(packet)
			var glow := _glow("84e9f8")
			for trail in 5:
				var size := 0.051 - trail * 0.007
				Kit.add_mesh(packet, Kit.sphere(size, size * 2.0, glow),
					Vector3.ZERO, Vector3.ZERO, "", false)
	return field


func _dress_field(field: Node3D) -> void:
	var clay := Kit.mat("96775a")
	var grass := Kit.mat("788458")
	var path := Kit.mat("b79873")
	Kit.add_box(field, Vector3(32, 0.21, 32), Vector3(0, -0.126, -6.4), grass)
	Kit.add_box(field, Vector3(4.6, 0.14, 13.6), Vector3(0.02, -0.075, -3.23), clay)
	var lane := Kit.add_box(field, Vector3(1.05, 0.027, 13.6), Vector3(-1.03, -0.015, -3.28), path)
	lane.rotation_degrees.y = -5
	for index in 6:
		var soil := Kit.mat("6d7350" if index % 2 == 0 else "85855b")
		Kit.add_box(field, Vector3(1.25, 0.032, 4.1 + index * 0.25),
			Vector3(3.19 + index * 1.27, -0.018, -3.90 - index * 0.19), soil)
	_prop(field, "quaternius_downtown/Building_Small_1", Vector3(-3.35, 0, -7.02), 0.24, -11)
	_prop(field, "quaternius_downtown/Building_Medium_2_001", Vector3(3.8, 0, -11.5), 0.23, 11)
	_prop(field, "quaternius_nature/PalmTree_1", Vector3(-2.8, 0, -2.41), 0.79, -16)
	_prop(field, "quaternius_nature/PalmTree_3", Vector3(3.07, 0, -4.80), 0.98, 23)
	_prop(field, "quaternius_nature/PalmTree_2", Vector3(4.88, 0, -7.38), 0.82, 12)
	_prop(field, "quaternius_nature/PalmTree_4", Vector3(-4.3, 0, -9.62), 0.92, -13)
	_prop(field, "quaternius_nature/Bush_2", Vector3(1.86, 0, -1.27), 0.52)
	_prop(field, "quaternius_nature/Bush_1", Vector3(-2.03, 0, -0.80), 0.43)
	_prop(field, "quaternius_nature/Rock_5", Vector3(1.75, 0, -0.03), 0.35, 14)
	_prop(field, "quaternius_nature/Rock_3", Vector3(-1.28, 0, -1.19), 0.32, -23)
	_prop(field, "kenney_suburban/fence-1x4", Vector3(2.0, 0, -2.12), 1.1, 90)
	_prop(field, "kenney_suburban/fence-1x4", Vector3(2.0, 0, -3.91), 1.1, 90)
	var steel := Kit.mat("58635b", 0.54, 0.42)
	Kit.add_box(field, Vector3(0.39, 0.36, 0.24), Vector3(1.09, 0.18, -0.78), steel)
	Kit.add_box(field, Vector3(0.31, 0.27, 0.025), Vector3(1.09, 0.18, -0.648), Kit.mat("75857a"))
	Kit.add_box(field, Vector3(0.047, 0.030, 0.021), Vector3(1.17, 0.18, -0.630), Kit.mat("3d4541"))


func _mast(height: float, fresh: bool) -> Node3D:
	var color := Color("8db9bf" if fresh else "946b51")
	var mast := Reveals.shape_node("tower", height, color)
	if fresh:
		var beacon := mast.get_child(mast.get_child_count() - 1) as MeshInstance3D
		beacon.material_override = _glow("71d5e9")
	var beam := Kit.mat("7eacb6" if fresh else "6d4d3e", 0.43 if fresh else 0.79, 0.42)
	# Fill the shared mast's open bays with alternating diagonal braces.
	for face in 4:
		var yaw := PI * 0.5 * face
		for index in 5:
			var a := _corner(height, 0.12 + index * 0.15, -1.0 if index % 2 == 0 else 1.0)
			var b := _corner(height, 0.27 + index * 0.15, 1.0 if index % 2 == 0 else -1.0)
			_beam(mast, a.rotated(Vector3.UP, yaw), b.rotated(Vector3.UP, yaw), height * 0.007, beam)
	if fresh:
		var ceramic := Kit.mat("d0dfe0", 0.37, 0.21)
		for side in [-1.0, 1.0]:
			Kit.add_box(mast, Vector3(0.065, 0.222, 0.035),
				Vector3(side * 0.14, height * 0.84, 0.10), ceramic)
		var tag := Kit.add_box(mast, Vector3(0.17, 0.083, 0.022), Vector3(0, height * 0.51, 0.14),
			Kit.mat("24687f"))
		var text := Reveals.text_node("4G", 0.061, Color("eff6ef"))
		text.position = tag.position + Vector3(0, 0.001, 0.015)
		mast.add_child(text)
	return mast


func _corner(height: float, k: float, side: float) -> Vector3:
	var radius := height * lerpf(0.16, 0.04, k) / sqrt(2.0)
	return Vector3(side * radius, height * k, radius)


func _controls() -> Node3D:
	var panel := Node3D.new()
	panel.name = "control"
	panel.position = CONTROL
	var metal := Kit.mat("48565d", 0.58, 0.31)
	Kit.add_box(panel, Vector3(0.27, 0.055, 0.25), Vector3(0, 0.027, 0), metal)
	Kit.add_box(panel, Vector3(0.075, 0.63, 0.08), Vector3(0, 0.33, 0), metal)
	Kit.add_box(panel, Vector3(0.225, 0.092, 0.165), Vector3(0, 0.668, 0), Kit.mat("b67b33"))
	var ring := Kit.mat("624b38", 0.58, 0.25)
	Kit.add_mesh(panel, Kit.cylinder(0.052, 0.053, 0.019, ring, 20), Vector3(0, 0.721, 0))
	var button := Kit.add_mesh(panel, Kit.cylinder(0.038, 0.039, 0.022, _glow("f7b975"), 20),
		Vector3(0, 0.742, 0), Vector3.ZERO, "button")
	button.material_override = _glow("f7b975")
	return panel


func _beam(root: Node3D, a: Vector3, b: Vector3, thickness: float, material: Material) -> void:
	var delta := b - a
	var piece := Kit.add_mesh(root, Kit.cylinder(thickness, thickness, delta.length(), material, 8), (a + b) * 0.5)
	piece.quaternion = Quaternion(Vector3.UP, delta.normalized())


func _glow(color: String) -> StandardMaterial3D:
	var material := Kit.mat(color).duplicate() as StandardMaterial3D
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(color)
	material.emission_energy_multiplier = 0.45
	return material


func _prop(root: Node3D, id: String, at: Vector3, scale: float, yaw: float = 0.0) -> void:
	var prop := KitDB.static_node(id, scale)
	prop.position = at
	prop.rotation_degrees.y = yaw
	root.add_child(prop)


func pose(field: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var shove := float(p["push"])
	var build_at := float(p["build"])
	var rise := float(p["rise"])
	var data := float(p["data"])
	var origin: Vector3 = ctx["holder"].position
	_pose_builder(field, ctx["actor"].call("network_mukesh"), origin, shove, build_at, t)
	_pose_masts(field, shove, rise, data, t)
	var pull := Motion.smooth(Motion.seg(t, shove - 0.14, rise + 0.42))
	var drift := Motion.smooth(Motion.seg(t, float(gag["t"]), float(p["end"])))
	var camera := Vector3(1.21, 1.42, 3.76).lerp(Vector3(1.61, 2.47, 4.78), pull)
	camera.x += 0.11 * drift
	var focus := Vector3(-0.25, 0.95, 0.23).lerp(Vector3(-0.22, 0.91, -0.63), pull)
	return {"camera": origin + camera, "focus": origin + focus}


func _pose_builder(field: Node3D, actor, origin: Vector3, shove: float, build_at: float, t: float) -> void:
	var push := Motion.smooth(Motion.seg(t, shove - 0.29, shove)) * (1.0 - Motion.out_cubic(Motion.seg(t, shove + 0.06, shove + 0.38)))
	var press := Motion.smooth(Motion.seg(t, build_at - 0.24, build_at)) * (1.0 - Motion.smooth(Motion.seg(t, build_at + 0.09, build_at + 0.29)))
	var hand := Motion.arc(Vector3(-0.70, 0.78, 0.89), Vector3(-0.51, 0.88, 0.58), 0.056, push)
	hand = hand.lerp(CONTROL + Vector3(0, 0.760, 0), press)
	actor.aim_hand("r", origin + hand, maxf(0.60, maxf(push, press)), 0.04 * push)
	actor.aim_hand("l", origin + Vector3(-0.51, 0.81, 0.46), 0.84 * push, 0.045 * push)
	var button := field.get_node("control/button") as MeshInstance3D
	button.position.y = 0.742 - 0.016 * press
	var material := button.material_override as StandardMaterial3D
	var color := Color("90d6a6" if t >= build_at else "f7b975")
	material.albedo_color = color
	material.emission = color


func _pose_masts(field: Node3D, shove: float, rise: float, data: float, t: float) -> void:
	var axis := Vector3.UP.cross(STEP).normalized()
	for index in TOWER_COUNT:
		var base := OLD_START + STEP * index
		var old := field.get_node("old_%d" % index) as Node3D
		var fall_start := shove + index * 0.26
		var tip := Motion.seg(t, fall_start, fall_start + 0.45)
		var angle := (1.0 - cos(tip * PI * 0.5)) * deg_to_rad(84.0)
		var shake := Motion.wobble(t - fall_start - 0.45, 5.0, 9.0) * 0.049
		old.quaternion = Quaternion(axis, angle - shake)
		old.position = base + Vector3.UP * (0.080 * tip * tip)

		var fresh := field.get_node("fresh_%d" % index) as Node3D
		var start := rise - 0.23 + index * 0.105
		var growth := Motion.out_back(Motion.seg(t, start, start + 0.54), 0.43)
		fresh.position = base + NEW_OFFSET - Vector3.UP * (NEW_HEIGHT * 1.16 * (1.0 - growth))
		fresh.visible = t >= start

		if index < TOWER_COUNT - 1:
			var packet := field.get_node("signal_%d" % index) as Node3D
			var aerial := base + NEW_OFFSET + Vector3.UP * (NEW_HEIGHT * 1.02)
			_pose_packet(packet, aerial, data - 0.23 + 0.13 * index, t)


func _pose_packet(packet: Node3D, aerial: Vector3, launch: float, t: float) -> void:
	for index in packet.get_child_count():
		var pulse := packet.get_child(index) as Node3D
		var start := launch + index * 0.021
		var flight := Motion.smooth(Motion.seg(t, start, start + 0.33))
		pulse.visible = t >= start and t < start + 0.33
		pulse.position = Motion.arc(aerial, aerial + STEP, 0.29, flight)
		pulse.scale = Vector3.ONE * (0.50 + 0.58 * sin(flight * PI))
