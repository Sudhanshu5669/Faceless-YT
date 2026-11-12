## A continuous approach through the penthouse window, with practical desk lifts
## and a balloon-like burst on "lost". The camera anchors are seekable with the gag.
extends RefCounted

const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")
const Toon = preload("res://scripts/actors/toon.gd")

const LOGO := "res://../library/logos/reliance-industries-golden.png"
const DESK_Y := 0.63
const WINDOW_Z := 5.2
const MODEL_NAMES := ["refinery", "pump", "bottle"]
const COLORS := [Color("dfded9"), Color("e84239"), Color("56b6ff")]
const DISPLAYS := [
	Vector3(-0.57, DESK_Y, 0.87), Vector3(0.53, DESK_Y, 0.87), Vector3(0.01, DESK_Y, 1.13),
]


func build(_gag: Dictionary) -> Node3D:
	var root := Node3D.new()
	_build_facade(root)
	_build_office(root)
	for i in MODEL_NAMES.size():
		_build_display(root, i)
	return root


func _build_facade(root: Node3D) -> void:
	var steel := _material("344760", 0.55, 0.52)
	var mullion := _lit("486883", 0.28)
	var glass := _lit("192d50", 0.35)
	var lit_windows := [_lit("5479a8", 0.40), _lit("eac382", 0.45), _lit("234b6b", 0.55)]
	# The open center bay is the actual route into the room. Surround it with
	# window bands, vertical ribs and a two-step crown to read as a tower at distance.
	# The stage's wood floor is at y = 0. Keep the tower roof below it
	# and extend only the narrow sill past the floor's front edge (z = 5).
	_box(root, Vector3(0, -11.56, WINDOW_Z - 4.2), Vector3(12.0, 22.88, 8.2), steel)
	_box(root, Vector3(0, 4.9, WINDOW_Z - 3.1), Vector3(12.0, 2.0, 6.2), steel)
	_box(root, Vector3(0, 6.1, WINDOW_Z - 3.9), Vector3(9.0, 0.42, 4.6), steel)
	_box(root, Vector3(0, 6.4, WINDOW_Z - 3.9), Vector3(6.0, 0.22, 2.9), lit_windows[0])
	_box(root, Vector3(0, -0.10, WINDOW_Z - 0.04), Vector3(10.0, 0.15, 0.44), steel)
	_box(root, Vector3(0, 3.96, 1.15), Vector3(10.0, 0.16, 8.35), steel)
	for x in [-4.35, 4.35]:
		_box(root, Vector3(x, 1.93, WINDOW_Z), Vector3(3.3, 3.84, 0.24), glass)
	for x in [-6.0, -4.35, -2.7, 2.7, 4.35, 6.0]:
		_box(root, Vector3(x, 0.4, WINDOW_Z + 0.16), Vector3(0.13, 11.0, 0.26), steel)
	for x in [-5.94, 5.94]:
		_box(root, Vector3(x, -8.15, WINDOW_Z + 0.19), Vector3(0.10, 23.9, 0.13), mullion)
	for floor_number in 11:
		var y := -1.15 - floor_number * 1.99
		for column in 8:
			var x := (column - 3.5) * 1.47
			var pattern := posmod(column * 7 + floor_number * 11 + column * floor_number, 13)
			var glazing: StandardMaterial3D = lit_windows[pattern % 3] if pattern < 6 else glass
			_box(root, Vector3(x, y, WINDOW_Z + 0.01), Vector3(1.30, 1.57, 0.12), glazing)
	_box(root, Vector3(0, 4.06, WINDOW_Z + 0.25), Vector3(12, 0.12, 0.12), lit_windows[0])
	for x in [-1.17, 1.17]:
		_box(root, Vector3(x, 1.92, WINDOW_Z), Vector3(0.10, 3.84, 0.16), steel)
	_box(root, Vector3(0, -23.18, 0), Vector3(60, 0.28, 56), _material("262a39", 0.88))
	_build_city_depth(root)


func _build_city_depth(root: Node3D) -> void:
	var asphalt := _material("28283b", 0.40)
	var road_paint := _lit("84754f", 0.55)
	var street_metal := _material("393646", 0.48)
	var street_glass := _lit("ffc579", 1.2)
	_box(root, Vector3(0, -23.02, 10.5), Vector3(42, 0.04, 7.0), asphalt)
	for dash in 17:
		_box(root, Vector3(-20 + dash * 2.5, -22.992, 10.5), Vector3(1.25, 0.013, 0.10), road_paint)
	_place_catalog(root, "kenney_cars/suv-luxury", Vector3(-3.4, -23.0, 12.1), 0.70, 90)
	_place_catalog(root, "kenney_cars/suv", Vector3(3.1, -23.0, 8.7), 0.64, -90)
	for x in [-8.8, -5.4, 4.0, 7.5]:
		_place_catalog(root, "quaternius_nature/PalmTree_2", Vector3(x, -23.0, 6.1), 0.86, x * 14)
		_cylinder(root, Vector3(x, -21.2, 7.0), 0.055, 3.60, street_metal)
		_box(root, Vector3(x, -19.40, 7.23), Vector3(0.14, 0.09, 0.58), street_metal)
		_box(root, Vector3(x, -19.46, 7.46), Vector3(0.13, 0.038, 0.19), street_glass)
		_spot(root, Vector3(x, -19.4, 7.3), Vector3(x, -23, 10.1), Color("ffc579"), 3.0, 48)

	# The near and far rows pass at different rates during the window approach.
	_place_catalog(root, "quaternius_downtown/Building_Large_2", Vector3(14.5, -23.0, 12.7), 0.72, -17)
	_place_catalog(root, "quaternius_downtown/Building_Medium_2_001", Vector3(-12.4, -23.0, 7.4), 0.86, 9)
	_place_catalog(root, "quaternius_downtown/Building_Small_1", Vector3(11.0, -23.0, -10.0), 1.05, 12)
	_place_catalog(root, "quaternius_downtown/Building_Large_2", Vector3(-16.0, -23.0, -13.0), 1.0)

	var distant := _lit("252746", 0.62)
	var roof_light := _lit("dd8a93", 1.4)
	var windows := _lit("9e80a7", 0.65)
	var window_mesh := BoxMesh.new()
	window_mesh.size = Vector3(0.36, 0.25, 0.04)
	var window_positions: Array[Vector3] = []
	for i in 12:
		var x := -42.0 + i * 7.7
		var z := -21.0 - (i % 3) * 7.0
		var height := 18.0 + posmod(i * 19, 17)
		var width := 3.4 + (i % 4) * 0.6
		var roof_y := -23.0 + height
		_box(root, Vector3(x, -23 + height * 0.5, z), Vector3(width, height, 3.8), distant)
		_box(root, Vector3(x, roof_y + 0.45, z), Vector3(width * 0.55, 0.9, 2.3), distant)
		_box(root, Vector3(x, roof_y + 0.93, z), Vector3(0.14, 0.12, 0.14), roof_light)
		for row in 12:
			for column in 3:
				if posmod(row * 3 + column * 7 + i, 5) < 2:
					window_positions.append(Vector3(x + (column - 1) * 0.86, roof_y - 0.8 - row * 0.83, z + 1.93))
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = window_mesh
	batch.instance_count = window_positions.size()
	for i in window_positions.size():
		batch.set_instance_transform(i, Transform3D(Basis.IDENTITY, window_positions[i]))
	var distant_windows := MultiMeshInstance3D.new()
	distant_windows.multimesh = batch
	distant_windows.material_override = windows
	distant_windows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(distant_windows)


func _place_catalog(root: Node3D, id: String, at: Vector3, size: float, yaw: float = 0) -> void:
	var prop := KitDB.static_node(id, size)
	if prop != null:
		prop.position = at
		prop.rotation_degrees.y = yaw
		root.add_child(prop)


func _build_office(root: Node3D) -> void:
	var walnut := _material("4e251b", 0.38)
	var leather := _material("261d30", 0.51)
	var brass := _material("d39434", 0.32, 0.62)
	var bright_gold := _material("f7c44a", 0.26, 0.53)
	var vault := _material("425167", 0.41, 0.52)
	var shadow := _material("191620", 0.58)
	var paper := _material("9fb58a", 0.84)
	var band := _material("e3caa4", 0.78)
	_build_office_depth(root, brass)
	# Executive chair and desk. Desk lifts stay low enough to keep the face visible.
	_box(root, Vector3(0, 0.34, -0.16), Vector3(0.64, 0.14, 0.60), leather)
	_box(root, Vector3(0, 0.87, -0.43), Vector3(0.65, 0.93, 0.17), leather)
	_box(root, Vector3(0, 0.17, -0.18), Vector3(0.12, 0.34, 0.12), vault)
	for x in [-0.32, 0.32]:
		_box(root, Vector3(x, 0.56, -0.10), Vector3(0.11, 0.08, 0.50), leather)
	_box(root, Vector3(0, DESK_Y - 0.055, 0.77), Vector3(2.16, 0.11, 1.12), walnut)
	_box(root, Vector3(0, 0.55, 1.34), Vector3(2.10, 0.025, 0.026), brass)
	for x in [-0.87, 0.87]:
		_box(root, Vector3(x, 0.27, 0.75), Vector3(0.30, 0.54, 0.87), walnut)
	_box(root, Vector3(0, 0.39, 1.24), Vector3(1.52, 0.30, 0.11), walnut)

	# Open safes with recessed shelves and swung doors. Gold, paper bands and handles
	# use separate materials so the contents remain legible in warm side light.
	for side in [-1.0, 1.0]:
		var safe := Node3D.new()
		safe.position = Vector3(0, 0, -0.46 if side > 0 else 0.04)
		root.add_child(safe)
		var x: float = side * 1.27
		_box(safe, Vector3(x, 0.80, -1.85), Vector3(1.00, 1.60, 0.52), vault)
		_box(safe, Vector3(x, 0.81, -1.58), Vector3(0.84, 1.34, 0.03), shadow)
		var door := _box(safe, Vector3(x + side * 0.46, 0.79, -1.22), Vector3(0.59, 1.48, 0.12), vault)
		door.rotation_degrees.y = side * 62.0
		var wheel := _cylinder(door, Vector3(0.06, 0.04, 0.085), 0.13, 0.045, brass)
		wheel.rotation.x = PI * 0.5
		for shelf in 3:
			var y := 0.29 + shelf * 0.42
			_box(safe, Vector3(x, y, -1.42), Vector3(0.80, 0.045, 0.34), vault)
			for stack in 3:
				var px := x + (stack - 1) * 0.235
				for layer in 2 + (shelf + stack) % 2:
					var at := Vector3(px, y + 0.055 + layer * 0.067, -1.36)
					if (stack + shelf) % 2 == 0:
						_cylinder(safe, at, 0.105, 0.065, bright_gold, 4).rotation.y = PI * 0.25
					else:
						_cash(safe, at, paper, band)
		for stack in 4:
			var at := Vector3(x + (stack % 2) * side * 0.22, 0.06, -0.94 + (stack / 2.0) * 0.24)
			_cash(safe, at, paper, band)
			_cash(safe, at + Vector3.UP * 0.067, paper, band)

	_mount_sign(root, brass)
	_spot(root, Vector3(0.65, 2.8, 2.75), Vector3(0, 0.9, 0.2), Color("ffe3c1"), 2.8, 37)
	_spot(root, Vector3(-1.7, 2.5, -0.7), Vector3(0, 0.9, 0), Color("9ad1ff"), 2.0, 42)
	_spot(root, Vector3(0, 3.4, -1.4), Vector3(0, 1.55, -3.7), Color("ffc982"), 2.6, 53)


func _build_office_depth(root: Node3D, brass: Material) -> void:
	var stone := _material("284844", 0.67)
	var wood := _material("623c30", 0.48)
	var dark_wood := _material("342322", 0.59)
	var cove := _lit("f8be78", 1.15)
	var rug := _material("5e2c38", 0.95)
	var ceiling := _lit("392e32", 0.31)
	_box(root, Vector3(0, 1.81, -3.81), Vector3(3.30, 3.62, 0.18), stone)
	_box(root, Vector3(0, 0.019, 0.66), Vector3(3.44, 0.035, 3.55), rug)
	_box(root, Vector3(0, 0.043, 2.36), Vector3(3.24, 0.009, 0.027), brass)
	_box(root, Vector3(0, 3.60, 0.82), Vector3(9.9, 0.16, 8.70), dark_wood)
	_box(root, Vector3(0, 3.48, 0.10), Vector3(3.8, 0.10, 5.9), ceiling)
	for side in [-1.0, 1.0]:
		_box(root, Vector3(side * 2.33, 1.79, -3.61), Vector3(1.48, 3.57, 0.26), dark_wood)
		for rib in 10:
			var x: float = side * (1.64 + rib * 0.145)
			_box(root, Vector3(x, 1.82, -3.43), Vector3(0.069, 3.52, 0.13), wood)
		_box(root, Vector3(side * 1.63, 1.76, -3.57), Vector3(0.034, 3.28, 0.04), cove)
		_box(root, Vector3(side * 2.39, 3.49, 0.79), Vector3(0.044, 0.042, 7.75), cove)
		_spot(root, Vector3(side * 2.15, 3.40, -2.50),
			Vector3(side * 1.8, 1.2, -3.64), Color("f9ad6f"), 3.2, 35)

	# A suspended desk light sits well in front of the sign and gives the
	# overhead part of the frame another plane during the push.
	for x in [-0.63, 0.63]:
		_cylinder(root, Vector3(x, 3.23, 0.57), 0.012, 0.43, brass)
	_box(root, Vector3(0, 3.01, 0.57), Vector3(1.60, 0.07, 0.21), brass)
	_box(root, Vector3(0, 2.966, 0.57), Vector3(1.49, 0.031, 0.15), _lit("f2c59f", 0.85))
	var desk_light := _spot(root, Vector3(-0.58, 2.92, 0.57),
		Vector3(0, DESK_Y, 0.99), Color("ffd5a2"), 1.6, 32)
	desk_light.spot_range = 4.1
	desk_light.shadow_enabled = true
	desk_light.shadow_bias = 0.025
	desk_light.shadow_normal_bias = 0.30

	# Leaves and a shaded floor lamp give the approach a near layer outside the desk action.
	_cylinder(root, Vector3(-1.89, 0.24, 1.88), 0.27, 0.48, dark_wood)
	_place_catalog(root, "quaternius_nature/PalmTree_2", Vector3(-1.89, 0.35, 1.88), 0.66, -23)
	var lamp_at := Vector3(1.71, 0, 0.58)
	_cylinder(root, lamp_at + Vector3.UP * 0.035, 0.19, 0.07, brass)
	_cylinder(root, lamp_at + Vector3.UP * 0.95, 0.021, 1.82, brass)
	_cylinder(root, lamp_at + Vector3.UP * 1.80, 0.22, 0.31, _lit("dfb08e", 0.52))
	_spot(root, lamp_at + Vector3.UP * 1.63, lamp_at + Vector3(0.1, 0.24, -0.3), Color("ffd3a1"), 1.8, 40)


func _mount_sign(root: Node3D, brass: Material) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(LOGO))
	assert(image != null and not image.is_empty(), "Missing approved Reliance master logo")
	image = image.get_region(image.get_used_rect())
	var backing := _box(root, Vector3(0, 2.48, -3.67), Vector3(1.51, 1.06, 0.06), brass)
	backing.scale = Vector3(1.22, 1.22, 1.0)
	var face := _box(backing, Vector3(0, 0, 0.035), Vector3(1.43, 0.98, 0.02), _lit("e4d6ba", 0.34))
	var quad := QuadMesh.new()
	quad.size = Vector2(1.16, 1.16 * image.get_height() / image.get_width())
	var ink := StandardMaterial3D.new()
	ink.albedo_texture = ImageTexture.create_from_image(image)
	ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh(face, quad, Vector3(0, 0, 0.014), ink)


func _build_display(root: Node3D, index: int) -> void:
	var slot := Node3D.new()
	slot.name = MODEL_NAMES[index]
	root.add_child(slot)
	var model: Node3D
	if index == 2:
		model = Node3D.new()
		# The catalog bottles are drinks. Build a squat shampoo bottle with a
		# wide flat face and flip-top cap so it reads without a label.
		var body := _mesh(model, Toon.sphere(0.17), Vector3(0, 0.163, 0), _material("57baff", 0.30))
		body.scale = Vector3(0.74, 1.05, 0.44)
		var cap := _cylinder(model, Vector3(0, 0.338, 0), 0.075, 0.057, _material("f5ebd8", 0.38))
		cap.scale.z = 0.72
	else:
		model = Reveals.shape_node(MODEL_NAMES[index], 0.47 if index == 0 else 0.40, COLORS[index])
	model.name = "model"
	slot.add_child(model)
	var debris := Node3D.new()
	debris.name = "debris"
	slot.add_child(debris)
	var glint := _lit(COLORS[index].to_html(false), 1.15)
	for j in 10:
		_box(debris, Vector3.ZERO, Vector3(0.043, 0.061, 0.023), glint)


func pose(root: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var arrival := float(p["arrive"])
	var flight := Motion.smooth(Motion.seg(t, 0.04, arrival))
	var glide := Motion.out_cubic(Motion.seg(t, arrival, float(p["burst"]) + 1.6))
	var camera := Vector3(3.85, 6.65, 37.0).lerp(Vector3(0.32, 1.63, 4.72), flight)
	camera += Vector3(-0.44, -0.03, -1.0) * glide
	var focus := Vector3(0, -5.3, WINDOW_Z).lerp(Vector3(0, 1.29, 0.2), flight)
	for index in MODEL_NAMES.size():
		var slot := root.get_node(MODEL_NAMES[index]) as Node3D
		var contact := float(p[MODEL_NAMES[index]])
		var burst := float(p["burst"]) + index * 0.055
		_pose_display(slot, DISPLAYS[index], t, contact, burst)
	var holder: Node3D = ctx["holder"]
	return {"camera": holder.position + camera, "focus": holder.position + focus}


func _pose_display(slot: Node3D, at: Vector3, t: float, contact: float, burst: float) -> void:
	var model := slot.get_node("model") as Node3D
	var debris := slot.get_node("debris") as Node3D
	var lift := Motion.out_cubic(Motion.seg(t, contact - 0.19, contact))
	var settle := Motion.impact(t - contact, 0.15)
	var wind := -Motion.wind_up(t, burst, 0.16)
	model.visible = t >= contact - 0.19 and t < burst
	model.position = at + Vector3.UP * lerpf(-0.41, 0.0, lift)
	var model_size := 0.68 if slot.name == &"bottle" else 1.0
	model.scale = Motion.squash(settle + wind * 0.18) * model_size
	model.rotation.z = 0.10 * Motion.wobble(t - contact) - wind * 0.07
	var age := t - burst
	debris.visible = age >= 0.0 and age < 0.39
	if debris.visible:
		var progress := Motion.seg(age, 0.0, 0.39)
		for j in debris.get_child_count():
			var fragment := debris.get_child(j) as Node3D
			var angle := TAU * j / debris.get_child_count()
			var direction := Vector3(cos(angle), sin(angle), 0.18 * cos(angle * 3.0))
			var center := at + Vector3.UP * 0.23
			fragment.position = Motion.arc(center, center + direction * 0.42, 0.13, Motion.out_cubic(progress))
			fragment.rotation.z = angle + progress * 4.0
			fragment.scale = Vector3.ONE * (1.0 - progress)


func _cash(root: Node3D, at: Vector3, paper: Material, band: Material) -> void:
	var bundle := _box(root, at, Vector3(0.20, 0.057, 0.135), paper)
	_box(bundle, Vector3.ZERO, Vector3(0.056, 0.061, 0.140), band)


func _spot(root: Node3D, at: Vector3, target: Vector3, color: Color, energy: float, angle: float) -> SpotLight3D:
	var lamp := SpotLight3D.new()
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.spot_angle = angle
	lamp.spot_range = 8.0
	lamp.transform = Transform3D(Basis.looking_at(target - at), at)
	root.add_child(lamp)
	return lamp


func _material(color: String, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color)
	mat.roughness = roughness
	mat.metallic = metallic
	return mat


func _lit(color: String, energy: float) -> StandardMaterial3D:
	var mat := _material(color, 0.55)
	mat.emission_enabled = true
	mat.emission = Color(color)
	mat.emission_energy_multiplier = energy
	return mat


func _box(root: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(root, mesh, at, mat)


func _cylinder(root: Node3D, at: Vector3, radius: float, height: float, mat: Material, sides: int = 24) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.85
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	return _mesh(root, mesh, at, mat)


func _mesh(root: Node3D, mesh: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = mesh
	item.material_override = mat
	item.position = at
	root.add_child(item)
	return item
