## A climber and a bazaar full of shoppers try to coax a signal from their phones.
extends RefCounted

const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")

const PALM_BASE := Vector3(-0.85, 0, -0.08)
const PALM_SCALE := 1.15
const BAR_WIDTH := 2.95
const OPEN_CAMERA := Vector3(0.57, 1.84, 0.24)
const OPEN_FOCUS := Vector3(-0.50, 3.48, 0.56)


func build(gag: Dictionary) -> Node3D:
	var market := Node3D.new()
	_dress_market(market)
	market.add_child(_airliner())
	var phone := _phone(0.20)
	phone.name = "climber_phone"
	market.add_child(phone)
	for index in int(gag["params"]["crowd_count"]):
		var handset := _phone(0.19)
		handset.name = "phone_%d" % index
		market.add_child(handset)
	market.add_child(_loading_bar())
	return market


func _dress_market(root: Node3D) -> void:
	_prop(root, "quaternius_nature/PalmTree_1", PALM_BASE, PALM_SCALE)
	_market_buildings(root)
	var terrace := _material("8b6650", 0.92)
	var trim := _material("ab8060", 0.83)
	_box(root, Vector3(-0.87, 0.059, -0.36), Vector3(1.51, 0.118, 1.39), terrace)
	for x in [-1.61, -0.13]:
		_box(root, Vector3(x, 0.123, -0.36), Vector3(0.061, 0.038, 1.42), trim)
	for z in [-1.04, 0.33]:
		_box(root, Vector3(-0.87, 0.127, z), Vector3(1.49, 0.036, 0.06), trim)
	for palm in [
		["PalmTree_2", Vector3(-3.35, 0, -1.84), 1.14, 36],
		["PalmTree_3", Vector3(2.85, 0, -1.35), 1.07, -31],
		["PalmTree_4", Vector3(4.1, 0, -3.46), 0.92, 28],
		["PalmTree_2", Vector3(-4.55, 0, 2.51), 0.96, -18],
		["PalmTree_3", Vector3(4.25, 0, 1.9), 0.83, 51],
	]:
		_prop(root, "quaternius_nature/" + String(palm[0]), palm[1], palm[2], palm[3])
	for bush in [Vector3(-1.55, 0.03, -0.86), Vector3(-0.22, 0.03, -0.87),
			Vector3(2.84, 0, -1.55), Vector3(-3.0, 0, -1.87)]:
		_prop(root, "quaternius_nature/Bush_2", bush, 0.47)
	_prop(root, "quaternius_fantasy_props/Stall_Cart_Empty", Vector3(-2.95, 0, -2.25), 0.78, 12)
	_prop(root, "quaternius_fantasy_props/Stall_Empty", Vector3(2.6, 0, -2.66), 0.86, -17)
	for crate in [
		["FarmCrate_Apple", Vector3(-3.02, 0.83, -1.99), 1.03, 14],
		["FarmCrate_Carrot", Vector3(-2.33, 0.83, -2.04), 0.90, 11],
		["FarmCrate_Apple", Vector3(2.62, 0.78, -2.41), 1.0, -17],
		["FarmCrate_Carrot", Vector3(3.16, 0, -1.96), 0.98, -22],
		["Crate_Wooden", Vector3(-3.16, 0, 1.32), 0.71, 18],
		["FarmCrate_Apple", Vector3(-3.16, 0.65, 1.32), 0.81, 13],
	]:
		_prop(root, "quaternius_fantasy_props/" + String(crate[0]), crate[1], crate[2], crate[3])
	var auto := Reveals.shape_node("rickshaw", 1.85, Color("2c715b"))
	auto.position = Vector3(2.04, 0, -3.35)
	auto.rotation_degrees.y = -62
	root.add_child(auto)


func _market_buildings(root: Node3D) -> void:
	# The storefronts and balcony facades sit behind the produce carts.
	var stone := _material("5a4a52", 0.87)
	var curb := _material("928072", 0.85)
	_box(root, Vector3(0, -0.13, -6.4), Vector3(22, 0.16, 5.4), stone)
	_box(root, Vector3(0, 0.044, -4.24), Vector3(12.5, 0.087, 1.14), curb)
	_prop(root, "quaternius_downtown/Building_Small_1", Vector3(-4.4, 0.065, -6.72), 0.40, 8)
	_prop(root, "quaternius_downtown/Building_Medium_2_001", Vector3(0.52, 0.065, -7.24), 0.34, 0)
	_prop(root, "quaternius_downtown/Building_Small_1", Vector3(5.54, 0.065, -6.98), 0.38, -14)
	_prop(root, "quaternius_downtown/Building_Medium_2_001", Vector3(-4.3, 0, -13.5), 0.53, -5)
	_prop(root, "quaternius_downtown/Building_Large_2", Vector3(4.1, 0, -13.9), 0.49, 10)
	var brass := _material("684d36", 0.61)
	var glass := _material("c8b297", 0.42)
	for x in [-3.45, 0.49, 4.30]:
		_box(root, Vector3(x, 2.18, -4.0), Vector3(0.048, 0.075, 0.47), brass)
		_box(root, Vector3(x, 2.09, -3.76), Vector3(0.21, 0.13, 0.18), glass)
		_box(root, Vector3(x, 2.18, -3.76), Vector3(0.25, 0.057, 0.21), brass)


func _phone(size: float) -> Node3D:
	var handset := Reveals.shape_node("phone", size, Color("273946"))
	var camera := _unlit("96b1bb")
	_box(handset, Vector3(-size * 0.14, size * 0.84, -size * 0.034),
		Vector3(size * 0.088, size * 0.075, 0.006), camera)
	return handset


func _loading_bar() -> Node3D:
	var bar := Node3D.new()
	bar.name = "loading"
	var frame := _unlit("28384a")
	var inset := _unlit("121b28")
	var outline := _unlit("89b8bd")
	var stalled := _unlit("edb45d")
	_box(bar, Vector3.ZERO, Vector3(BAR_WIDTH + 0.08, 0.33, 0.055), outline)
	_box(bar, Vector3(0, 0, 0.032), Vector3(BAR_WIDTH, 0.255, 0.026), frame)
	_box(bar, Vector3(0.24, 0, 0.049), Vector3(2.31, 0.126, 0.021), inset)
	var fill := _box(bar, Vector3(-0.91, 0, 0.065), Vector3(1.0, 0.087, 0.018), stalled)
	fill.name = "fill"
	var label := Reveals.text_node("2G", 0.142, Color("f6e7cc"))
	label.position = Vector3(-1.20, -0.004, 0.059)
	bar.add_child(label)
	return bar


func pose(market: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var params: Dictionary = gag["params"]
	var origin: Vector3 = ctx["holder"].position
	var back := Motion.smooth(Motion.seg(t, float(params["pullback"]) - 0.06, float(params["slow"]) + 0.08))
	var drift := Motion.smooth(Motion.seg(t, float(params["slow"]), float(params["end"])))
	var age := float(ctx["age"])
	var camera := OPEN_CAMERA.lerp(Vector3(0.68, 3.86, 9.52), back)
	camera += Vector3(0.61 * sin(back * PI), 0.12, 0.21 * drift)
	var focus := OPEN_FOCUS.lerp(Vector3(0.22, 2.02, 0.65), back)
	var flight_direction := (OPEN_FOCUS - OPEN_CAMERA).normalized()
	var screen_right := flight_direction.cross(Vector3.UP).normalized()
	var screen_up := screen_right.cross(flight_direction)
	var plane := market.get_node("airliner") as Node3D
	plane.position = OPEN_CAMERA + flight_direction * 68.0 + screen_up * 27.0
	plane.position += screen_right * (-23.0 + 17.0 * age)
	plane.rotation = Vector3(0, atan2(-screen_right.z, screen_right.x), 0)
	_pose_climber(market, ctx["actor"].call("signal_climber"), origin, age)
	for index in int(params["crowd_count"]):
		_pose_shopper(market, ctx["actor"].call("signal_shopper_%d" % index), origin, index, t, float(params["online"]))
	var bar := market.get_node("loading") as Node3D
	var slow := float(params["slow"])
	var appear := Motion.out_back(Motion.seg(t, slow, slow + 0.19), 0.8)
	bar.visible = t >= slow
	bar.position = Vector3(0.64, 2.38 + 0.11 * (appear - 1.0), 1.30)
	bar.basis = Basis.looking_at(bar.position - camera).scaled(Vector3.ONE * maxf(0.001, appear))
	var fill := bar.get_node("fill") as Node3D
	var loaded := 0.29 * Motion.out_cubic(Motion.seg(t, slow + 0.09, slow + 0.44))
	fill.visible = loaded > 0.004
	fill.position.x = -0.90 + loaded * 0.5
	fill.scale.x = loaded
	return {"camera": origin + camera, "focus": origin + focus}


func _pose_climber(market: Node3D, actor, origin: Vector3, age: float) -> void:
	# The trunk contact points are sampled from PalmTree_1's curved trunk.
	actor.body.position.y += 2.21
	actor.aim_hand("r", origin + Vector3(-0.899, 3.21, 0.325))
	actor.aim_foot("r", origin + Vector3(-0.971, 2.41, 0.40), Vector3(0.27, 0.68, 0.78))
	actor.aim_foot("l", origin + Vector3(-0.88, 2.54, 0.35), Vector3(0.85, 0.64, 0.35))
	var head: Vector3 = actor.anchor_points()["signal_climber.head"]["pos"]
	var sweep := Vector3(0.06 * sin(age * 4.7), 0.052 * sin(age * 5.4 - 0.8), 0.045 * cos(age * 4.7))
	var target := head + Vector3(0.39, 0.02, 0.15) + sweep
	actor.aim_hand("l", target, 1.0, 0.065)
	var phone := market.get_node("climber_phone") as Node3D
	phone.position = actor.bone_world("hand_l") - origin - Vector3(0.007, 0.036, 0.008)
	phone.rotation = Vector3(-0.16, 2.12 + sweep.z * 3.0, -0.18 + sweep.y)


func _pose_shopper(market: Node3D, actor, origin: Vector3, index: int, t: float, online: float) -> void:
	var head: Vector3 = actor.anchor_points()[actor.actor_id + ".head"]["pos"]
	var forward := Vector3(sin(actor.rotation.y), 0, cos(actor.rotation.y))
	var lateral := Vector3(cos(actor.rotation.y), 0, -sin(actor.rotation.y))
	var start := online - 0.26 + (index % 5) * 0.083
	var lift := Motion.smooth(Motion.seg(t, start, start + 0.48))
	var search := sin(t * (3.2 + index * 0.12) + index * 1.07)
	var low := head + lateral * 0.22 + forward * 0.21 - Vector3.UP * 0.43
	var high := head + lateral * (0.32 + 0.030 * search) + forward * 0.078 + Vector3.UP * (0.26 + 0.054 * search)
	actor.aim_hand("l", Motion.arc(low, high, 0.043, lift), 1.0, 0.145 * lift)
	var phone := market.get_node("phone_%d" % index) as Node3D
	phone.position = actor.bone_world("hand_l") - origin + Vector3(-0.005, lerpf(-0.03, 0.012, lift), 0)
	phone.rotation = Vector3(0.24 - 0.42 * lift, actor.rotation.y + 2.16 + 0.27 * search,
		0.18 + search * lift * 0.16)


func _prop(root: Node3D, id: String, at: Vector3, size: float, yaw: float = 0) -> void:
	var model := KitDB.static_node(id, size)
	if model != null:
		model.position = at
		model.rotation_degrees.y = yaw
		root.add_child(model)


func _unlit(hex: String) -> StandardMaterial3D:
	var mat := _material(hex, 0.75)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


func _material(hex: String, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.roughness = roughness
	return mat


func _box(root: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = at
	root.add_child(node)
	return node


func _airliner() -> Node3D:
	var plane := Node3D.new()
	plane.name = "airliner"
	var shell := _unlit("eff2f3")
	var trim := _unlit("829aa9")
	var body := CapsuleMesh.new()
	body.radius = 0.27
	body.height = 5.6
	_air_part(plane, body, Vector3.ZERO, shell).rotation.z = PI * 0.5
	for side in [-1.0, 1.0]:
		var wing := _box(plane, Vector3(-0.45, -0.055, side * 1.19), Vector3(0.86, 0.068, 2.51), shell)
		wing.rotation_degrees.y = -side * 24.0
		var stabilizer := _box(plane, Vector3(-2.03, 0.06, side * 0.43), Vector3(0.53, 0.055, 0.97), shell)
		stabilizer.rotation_degrees.y = -side * 27.0
		var nacelle := CapsuleMesh.new()
		nacelle.radius = 0.19
		nacelle.height = 0.93
		_air_part(plane, nacelle, Vector3(-0.16, -0.20, side * 0.93), trim).rotation.z = PI * 0.5
	var tail := _box(plane, Vector3(-2.05, 0.45, 0), Vector3(0.53, 0.94, 0.07), trim)
	tail.rotation_degrees.z = 24.0
	_box(plane, Vector3(2.09, 0.147, 0), Vector3(0.36, 0.105, 0.45), trim)
	return plane


func _air_part(parent: Node3D, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	part.position = at
	parent.add_child(part)
	return part
