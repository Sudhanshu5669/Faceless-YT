## The split and its callback, acted out on the family-room floor with toys.
extends RefCounted

const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")
const Toon = preload("res://scripts/actors/toon.gd")

const TRAY_Y := 0.085
const RUG_Y := 0.022
const REFINERY := Vector3(-0.116, TRAY_Y, 0.24)
const BOTTLE := Vector3(-0.136, TRAY_Y, 0.43)
const CELL := Vector3(0.135, TRAY_Y, 0.27)
const PHONE := Vector3(0.082, TRAY_Y, 0.40)
const PHONE_GIFT := Vector3(0.37, RUG_Y, 0.38)


func build(_gag: Dictionary) -> Node3D:
	var room := Node3D.new()
	_dress_room(room)
	var tray := KitDB.static_node("fab_cartoon_food/Plate", 2.55)
	if tray != null:
		tray.scale.y *= 0.48
		tray.position = Vector3(0, RUG_Y, 0.48)
		room.add_child(tray)
	_add_toy(room, "refinery", Reveals.shape_node("refinery", 0.23, Color("a5b9c4")), REFINERY)
	_add_toy(room, "bottle", _oil_bottle(), BOTTLE)
	_add_toy(room, "cell", _cell(), CELL)
	_add_toy(room, "phone", _phone(), PHONE)
	var second_phone := _phone("a53c37")
	second_phone.scale = Vector3.ONE * 1.12
	second_phone.hide()
	_add_toy(room, "second_phone", second_phone, PHONE)
	var spark := Node3D.new()
	spark.name = "contact"
	room.add_child(spark)
	var ink := _material("ffdd99", 0.65)
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 3:
		var ray := _box(spark, Vector3(0.057, 0, 0), Vector3(0.105, 0.014, 0.012), ink)
		ray.rotate_z(deg_to_rad(35.0 + i * 53.0))
		ray.position = ray.position.rotated(Vector3.BACK, ray.rotation.z)
	_light(room, Vector3(-1.02, 2.46, 1.69), Vector3(0, 0.37, 0.13), Color("ffe0ac"), 3.3, true)
	_light(room, Vector3(1.68, 1.56, -0.54), Vector3(0, 0.54, 0.24), Color("9cc9ee"), 2.05)
	return room


func _dress_room(room: Node3D) -> void:
	var rug := _material("652d43", 0.88)
	var border := _material("cb924d", 0.77)
	var motif := _material("9f5e56", 0.83)
	var walnut := _material("492b22", 0.62)
	var upholstery := _material("375956", 0.86)
	_box(room, Vector3(0, 0.013, 0.28), Vector3(2.42, 0.018, 2.08), rug)
	for side in [-1.0, 1.0]:
		_box(room, Vector3(side * 1.14, 0.024, 0.28), Vector3(0.047, 0.006, 1.96), border)
		_box(room, Vector3(0, 0.026, 0.28 + side * 0.98), Vector3(2.31, 0.006, 0.043), border)
		for i in 7:
			var tile := _box(room, Vector3(side * 1.04, 0.024, -0.59 + i * 0.29),
				Vector3(0.10, 0.004, 0.10), motif)
			tile.rotation_degrees.y = 45
	_box(room, Vector3(0, 0.25, -1.56), Vector3(2.56, 0.21, 0.69), walnut)
	_box(room, Vector3(0, 0.44, -1.56), Vector3(2.47, 0.19, 0.63), upholstery)
	_box(room, Vector3(0, 0.64, -1.83), Vector3(2.56, 0.47, 0.16), walnut)
	for side in [-1.0, 1.0]:
		for z in [-1.82, -1.32]:
			_box(room, Vector3(side * 1.10, 0.12, z), Vector3(0.13, 0.23, 0.13), walnut)
		var cushion := _mesh(room, Toon.sphere(0.24), Vector3(side * 0.87, 0.61, -1.62), border)
		cushion.scale = Vector3(1.0, 0.66, 0.42)
		cushion.rotation_degrees.z = side * 13.0
		var pot_at := Vector3(side * 1.45, 0, -0.83)
		_cylinder(room, pot_at + Vector3.UP * 0.17, 0.16, 0.29, motif)
		var palm := KitDB.static_node("quaternius_nature/PalmTree_2", 0.46)
		if palm != null:
			palm.position = pot_at + Vector3.UP * 0.28
			room.add_child(palm)


func _phone(color: String = "315276") -> Node3D:
	var toy := Node3D.new()
	var shell := _material(color, 0.38)
	var silver := _material("8fa9bd", 0.36)
	var glass := _material("b2e1ce", 0.34)
	_box(toy, Vector3(0, 0.022, 0), Vector3(0.100, 0.045, 0.188), shell)
	_box(toy, Vector3(0, 0.049, -0.043), Vector3(0.073, 0.011, 0.058), silver)
	_box(toy, Vector3(0, 0.056, -0.043), Vector3(0.058, 0.007, 0.043), glass)
	for row in 4:
		for column in 3:
			_box(toy, Vector3((column - 1) * 0.023, 0.049, 0.005 + row * 0.018),
				Vector3(0.016, 0.011, 0.012), silver)
	return toy


func _cell() -> Node3D:
	var toy := Node3D.new()
	var copper := _material("d59056", 0.30)
	var graphite := _material("252538", 0.42)
	_cylinder(toy, Vector3(0, 0.067, 0), 0.035, 0.13, graphite)
	_cylinder(toy, Vector3(0, 0.125, 0), 0.035, 0.035, copper)
	_cylinder(toy, Vector3(0, 0.148, 0), 0.017, 0.013, copper)
	return toy


func _oil_bottle() -> Node3D:
	var toy := Node3D.new()
	var body := _mesh(toy, Toon.sphere(0.085), Vector3(0, 0.074, 0), _material("c28031", 0.34))
	body.scale = Vector3(0.71, 0.97, 0.49)
	_cylinder(toy, Vector3(0, 0.155, 0), 0.032, 0.031, _material("283242", 0.46))
	return toy


func pose(room: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var holder: Node3D = ctx["holder"]
	var origin := holder.position
	var mother = ctx["actor"].call("kokila")
	var mukesh = ctx["actor"].call("baby_mukesh")
	var anil = ctx["actor"].call("baby_anil")
	var reunion := float(p["reunion"])
	var reunited := t >= reunion
	room.visible = t < float(p["split_end"]) or reunited
	if not room.visible:
		return {}
	var second_phone := room.get_node("second_phone") as Node3D
	second_phone.visible = reunited
	if reunited:
		# The callback stays with the two children on the rug.
		mother.position.x -= 2.30
		return _pose_reunion(room, mukesh, anil, origin, p, t)
	var split := float(p["split"])
	var gift := float(p["phone"])
	var reach := float(p["reach"])
	var swat := float(p["swat"])
	var serving := _gesture(t, split - 0.34, split - 0.05, split + 0.43, split + 0.76)
	serving += _gesture(t, gift - 0.74, gift - 0.42, gift, gift + 0.28)
	var swatting := _gesture(t, swat - 0.35, swat, swat + 0.09, swat + 0.40)
	mother.sit_on_floor(0.29, origin.y + RUG_Y, deg_to_rad(4.0 + 19.0 * serving + 9.0 * swatting))
	mukesh.sit_on_floor(0.145, origin.y + RUG_Y)
	anil.sit_on_floor(0.143, origin.y + RUG_Y)

	# The same arc moves each toy and the hand pushing it. The second pair
	# follows at a slight delay, with the phone held back for its spoken cue.
	var first := Motion.out_cubic(Motion.seg(t, split - 0.05, split + 0.46))
	var second := Motion.out_cubic(Motion.seg(t, split + 0.08, split + 0.57))
	var delivery := Motion.smooth(Motion.seg(t, gift - 0.42, gift))
	var refinery := Motion.arc(REFINERY, Vector3(-0.405, RUG_Y, 0.49), 0.034, first)
	var bottle := Motion.arc(BOTTLE, Vector3(-0.350, RUG_Y, 0.65), 0.037, first)
	var cell := Motion.arc(CELL, Vector3(0.42, RUG_Y, 0.59), 0.035, second)
	var phone := Motion.arc(PHONE, PHONE_GIFT, 0.062, delivery)
	_set_toy(room, "refinery", refinery, -0.22 * first)
	_set_toy(room, "bottle", bottle, 0.15 * first)
	_set_toy(room, "cell", cell, -0.08 * second)
	_set_toy(room, "phone", phone, -0.24 * delivery)
	(room.get_node("phone") as Node3D).rotation.x = 0.0
	(room.get_node("phone") as Node3D).rotation.z = 0.0
	mother.aim_hand("r", origin + refinery.lerp(bottle, 0.28) + Vector3(0.045, 0.095, -0.017),
		_gesture(t, split - 0.28, split - 0.05, split + 0.32, split + 0.57))
	mother.aim_hand("l", origin + cell + Vector3(-0.035, 0.095, -0.035),
		_gesture(t, split - 0.20, split + 0.08, split + 0.42, split + 0.66))
	mother.aim_hand("l", origin + phone + Vector3(-0.022, 0.065, -0.015),
		_gesture(t, gift - 0.65, gift - 0.42, gift, gift + 0.23))
	anil.aim_hand("r", origin + PHONE_GIFT + Vector3(0.063, 0.073, 0.01),
		_gesture(t, gift - 0.09, gift + 0.18, swat + 0.09, swat + 0.60))

	var contact := Vector3(-0.155, 0.329, 0.216)
	var extend := Motion.smooth(Motion.seg(t, reach, swat))
	var recoil := Motion.out_cubic(Motion.seg(t, swat, swat + 0.22))
	var try_hand := Motion.arc(Vector3(-0.30, 0.25, 0.34), contact, 0.075, extend)
	try_hand = Motion.arc(try_hand, Vector3(-0.33, 0.42, 0.35), 0.085, recoil)
	mukesh.aim_hand("l", origin + try_hand, _gesture(t, reach, reach + 0.26, swat + 0.18, swat + 0.68))

	var wind := Motion.smooth(Motion.seg(t, swat - 0.39, swat - 0.15))
	var strike := Motion.in_cubic(Motion.seg(t, swat - 0.15, swat))
	var withdraw := Motion.out_cubic(Motion.seg(t, swat, swat + 0.26))
	var raised := Vector3(-0.18, 0.51, 0.12)
	var slap := Vector3(-0.18, 0.31, 0.14).lerp(raised, wind)
	slap = Motion.arc(slap, contact + Vector3.UP * 0.028, 0.036, strike)
	slap = Motion.arc(slap, Vector3(-0.24, 0.34, 0.24), 0.055, withdraw)
	mother.aim_hand("r", origin + slap, _gesture(t, swat - 0.44, swat - 0.20, swat + 0.26, swat + 0.69))

	var spark := room.get_node("contact") as Node3D
	var impact := t - swat
	spark.visible = impact >= 0.0 and impact < 0.13
	spark.position = contact + Vector3(0, 0.02, 0.042)
	spark.scale = Vector3.ONE * lerpf(0.4, 1.14, Motion.out_cubic(Motion.seg(impact, 0, 0.13)))
	return {}


func _pose_reunion(room: Node3D, mukesh, anil, origin: Vector3, p: Dictionary, t: float) -> Dictionary:
	var start := float(p["reunion"])
	var show := float(p["show_phone"])
	var raise := Motion.smooth(Motion.seg(t, show - 0.57, show))
	var reaction := Motion.smooth(Motion.seg(t, show + 0.04, show + 0.35))
	mukesh.sit_on_floor(0.145, origin.y + RUG_Y, deg_to_rad(5.0 * raise))
	anil.sit_on_floor(0.143, origin.y + RUG_Y, deg_to_rad(-9.0 * reaction))
	_set_toy(room, "refinery", Vector3(-0.405, RUG_Y, 0.49), -0.22)
	_set_toy(room, "bottle", Vector3(-0.350, RUG_Y, 0.65), 0.15)
	_set_toy(room, "cell", Vector3(0.42, RUG_Y, 0.59), -0.08)
	(room.get_node("contact") as Node3D).hide()

	var grip := Motion.arc(Vector3(-0.29, 0.24, 0.46), Vector3(-0.11, 0.35, 0.47), 0.044, raise)
	var settle := 0.011 * Motion.wobble(t - show, 3.4, 8.0) * Motion.smooth(Motion.seg(t, show, show + 0.08))
	grip.y += settle
	_hold_phone(room.get_node("second_phone"), mukesh, "l", origin, grip,
		Vector3(lerpf(0.65, 1.46, raise), 0.18 + 0.28 * raise, -0.17))

	var anil_grip := Vector3(0.29, 0.25, 0.47).lerp(Vector3(0.38, 0.30, 0.44), reaction)
	_hold_phone(room.get_node("phone"), anil, "r", origin, anil_grip,
		Vector3(1.20 - 0.15 * reaction, -0.30, 0.13))

	var slide := Motion.smooth(Motion.seg(t, start, float(p["end"])))
	var camera := Vector3(-0.13, 1.12, 2.78).lerp(Vector3(-0.08, 0.92, 2.42), slide)
	var focus := Vector3(0, 0.45, 0.28).lerp(Vector3(0, 0.48, 0.30), slide)
	return {"camera": origin + camera, "focus": origin + focus}


func _hold_phone(phone: Node3D, actor, side: String, origin: Vector3, grip: Vector3, angles: Vector3) -> void:
	actor.aim_hand(side, origin + grip)
	phone.rotation = angles
	var edge := 0.039 if side == "l" else -0.039
	phone.position = actor.bone_world("hand_" + side) - origin - phone.basis * Vector3(edge, 0.024, 0.049)


func _gesture(t: float, start: float, arrive: float, release: float, end: float) -> float:
	return Motion.smooth(Motion.seg(t, start, arrive)) * (1.0 - Motion.smooth(Motion.seg(t, release, end)))


func _add_toy(room: Node3D, id: String, toy: Node3D, at: Vector3) -> void:
	toy.name = id
	toy.position = at
	room.add_child(toy)


func _set_toy(room: Node3D, id: String, at: Vector3, yaw: float) -> void:
	var toy := room.get_node(id) as Node3D
	toy.position = at
	toy.rotation.y = yaw


func _light(room: Node3D, at: Vector3, target: Vector3, tint: Color, energy: float, shadows: bool = false) -> void:
	var lamp := SpotLight3D.new()
	lamp.light_color = tint
	lamp.light_energy = energy
	lamp.spot_angle = 39.0
	lamp.spot_range = 5.0
	lamp.shadow_enabled = shadows
	lamp.shadow_bias = 0.03
	lamp.shadow_normal_bias = 0.30
	lamp.transform = Transform3D(Basis.looking_at(target - at), at)
	room.add_child(lamp)


func _material(hex: String, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.roughness = roughness
	return mat


func _box(room: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(room, mesh, at, mat)


func _cylinder(room: Node3D, at: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	return _mesh(room, mesh, at, mat)


func _mesh(room: Node3D, mesh: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = mesh
	item.material_override = mat
	item.position = at
	room.add_child(item)
	return item
