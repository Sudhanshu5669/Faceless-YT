## Mukesh lowers his binoculars at the chai stall and lets a grin slip.
extends RefCounted

const KitDB = preload("res://scripts/world/kit_db.gd")
const BinocularPose = preload("res://scripts/timeline/binocular_pose.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")


func build(_gag: Dictionary) -> Node3D:
	var stall := Node3D.new()
	_catalog(stall, "quaternius_fantasy_props/Stall_Cart_Empty", Vector3(-0.44, 0, -1.39), 0.79, -7)
	_catalog(stall, "quaternius_fantasy_props/Bench", Vector3(0.04, -0.13, -0.22), 0.81)
	_catalog(stall, "quaternius_downtown/Building_Small_1", Vector3(2.6, 0, -4.3), 0.30, -9)
	_catalog(stall, "quaternius_downtown/Building_Medium_2_001", Vector3(-2.4, 0, -5.05), 0.35, 7)
	_catalog(stall, "quaternius_nature/PalmTree_2", Vector3(1.12, 0, -2.25), 0.83, -20)
	_catalog(stall, "quaternius_fantasy_props/Pot_1_Lid", Vector3(-0.93, 0.80, -1.16), 0.53)
	for index in 3:
		_catalog(stall, "fab_cartoon_food/Mug_1", Vector3(0.38 - 0.14 * index, 0.83, -1.09), 0.62)

	var timber := _material("4b2f26", 0.62)
	var signboard := _material("7c2f2d", 0.63)
	var gold := _material("db9a4f", 0.49)
	_box(stall, Vector3(-0.59, 1.67, -0.91), Vector3(0.85, 0.24, 0.056), timber)
	_box(stall, Vector3(-0.59, 1.67, -0.875), Vector3(0.81, 0.20, 0.019), signboard)
	var lettering := Reveals.text_node("CHAI", 0.14, Color("ffe0a1"))
	lettering.position = Vector3(-0.59, 1.67, -0.86)
	stall.add_child(lettering)

	_box(stall, Vector3(-0.64, 0.31, 0.31), Vector3(0.39, 0.055, 0.35), timber)
	for x in [-0.78, -0.49]:
		_box(stall, Vector3(x, 0.15, 0.32), Vector3(0.055, 0.30, 0.28), timber)
	_catalog(stall, "fab_cartoon_food/Mug_2", Vector3(-0.63, 0.34, 0.31), 0.85, -30)

	var glass := _material("ffcc8c", 0.35)
	glass.emission_enabled = true
	glass.emission = Color("ffb968")
	glass.emission_energy_multiplier = 1.3
	_box(stall, Vector3(0.51, 1.49, -0.91), Vector3(0.018, 0.38, 0.018), gold)
	_box(stall, Vector3(0.51, 1.28, -0.91), Vector3(0.11, 0.10, 0.08), glass)
	_box(stall, Vector3(0.51, 1.345, -0.91), Vector3(0.16, 0.041, 0.13), timber)
	_light(stall, Vector3(-0.84, 2.09, 1.53), Vector3(0, 0.93, 0.18), Color("ffe0b0"), 2.35, true)
	_light(stall, Vector3(1.28, 1.85, -0.42), Vector3(0, 1.11, 0.10), Color("84d6df"), 1.9)
	_light(stall, Vector3(0.22, 1.88, 0.02), Vector3(-0.52, 1.14, -1.19), Color("ffbc7b"), 1.9)

	stall.add_child(BinocularPose.build())
	return stall


func pose(stall: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var actor = ctx["actor"].call("chai_mukesh")
	var holder: Node3D = ctx["holder"]
	var params: Dictionary = gag["params"]
	var lower := float(params["lower"])
	var drop := Motion.seg(t, lower - 0.08, lower + 0.50)
	# Play the established two-handed lift in reverse, starting just before contact.
	BinocularPose.pose(stall.get_node("binoculars"), actor, -0.001 - 0.39 * drop, 0.0, holder.position)
	var move := Motion.smooth(Motion.seg(t, float(gag["t"]), float(params["end"])))
	var camera := Vector3(0.47, 1.47, 3.58).lerp(Vector3(0.29, 1.35, 2.78), move)
	var focus := Vector3(-0.06, 1.00, 0.02).lerp(Vector3(0.03, 1.01, 0.05), move)
	return {"camera": holder.position + camera, "focus": holder.position + focus}


func _catalog(root: Node3D, id: String, at: Vector3, size: float, yaw: float = 0) -> void:
	var prop := KitDB.static_node(id, size)
	if prop != null:
		prop.position = at
		prop.rotation_degrees.y = yaw
		root.add_child(prop)


func _light(root: Node3D, at: Vector3, target: Vector3, tint: Color, energy: float, shadows: bool = false) -> void:
	var lamp := SpotLight3D.new()
	lamp.light_color = tint
	lamp.light_energy = energy
	lamp.spot_range = 5.0
	lamp.spot_angle = 39.0
	lamp.shadow_enabled = shadows
	lamp.shadow_bias = 0.03
	lamp.shadow_normal_bias = 0.32
	lamp.transform = Transform3D(Basis.looking_at(target - at), at)
	root.add_child(lamp)


func _material(hex: String, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.roughness = roughness
	return mat


func _box(root: Node3D, at: Vector3, size: Vector3, mat: Material) -> void:
	var geometry := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	geometry.mesh = box
	geometry.material_override = mat
	geometry.position = at
	root.add_child(geometry)
