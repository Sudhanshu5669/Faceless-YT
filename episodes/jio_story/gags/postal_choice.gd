## A street-scale post office and PCO seen from behind the shopper.
extends RefCounted

const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")
const Toon = preload("res://scripts/actors/toon.gd")


func build(_gag: Dictionary) -> Node3D:
	var street := Node3D.new()
	var curb := _mat("8c7563")
	var cement := _mat("b2a18c")
	_box(street, Vector3(0, 0.031, -0.49), Vector3(8.8, 0.078, 2.77), curb)
	_box(street, Vector3(0, 0.068, 0.85), Vector3(8.85, 0.035, 0.16), cement)
	for i in 14:
		_box(street, Vector3(-4.07 + i * 0.61, 0.071, 0.52), Vector3(0.011, 0.008, 0.50), cement)
	_post_office(street)
	_phone_booth(street)
	_dress_street(street)
	_light(street, Vector3(-1.65, 3.3, 2.75), Vector3(-0.4, 0.9, 0.5), Color("ffd8ac"), 3.1, 42, true)
	_light(street, Vector3(2.5, 2.4, 0.0), Vector3(0, 1, 1), Color("83ddeb"), 2.9, 45)
	return street


func _post_office(street: Node3D) -> void:
	var root := Node3D.new()
	root.position = Vector3(-1.94, 0.07, -0.54)
	root.scale = Vector3(1.65, 1.38, 1.55)
	street.add_child(root)
	var plaster := _mat("d3a483")
	var red := _mat("ac312e")
	var cream := _mat("eed0a7")
	var dark := _mat("49303a")
	var timber := _mat("674037")
	_box(root, Vector3(0, 1.15, -0.61), Vector3(1.94, 2.30, 1.06), plaster)
	_box(root, Vector3(0, 2.31, -0.43), Vector3(2.10, 0.14, 1.55), red)
	_box(root, Vector3(0, 2.41, -0.55), Vector3(1.92, 0.08, 1.23), cream)
	_box(root, Vector3(0, 1.88, 0.015), Vector3(1.78, 0.32, 0.13), red)
	_sign(root, "POST OFFICE", Vector3(0, 1.87, 0.09), 0.18, Color("fff1cc"))
	_box(root, Vector3(0, 0.94, -0.06), Vector3(1.43, 1.11, 0.09), dark)
	_box(root, Vector3(0, 0.73, 0.01), Vector3(1.46, 0.12, 0.29), timber)
	_box(root, Vector3(0, 0.33, 0.01), Vector3(1.41, 0.67, 0.13), plaster)
	for x in [-0.76, 0.76]:
		_box(root, Vector3(x, 1.12, 0.08), Vector3(0.12, 1.42, 0.14), red)
	for x in [-0.47, -0.23, 0.01, 0.25, 0.49]:
		_box(root, Vector3(x, 1.17, -0.005), Vector3(0.037, 0.64, 0.04), timber)
	for i in 8:
		var stripe := cream if i % 2 == 0 else red
		var awning := _box(root, Vector3(-0.77 + i * 0.22, 1.61, 0.25), Vector3(0.218, 0.04, 0.53), stripe)
		awning.rotation_degrees.x = 12
		_box(root, Vector3(-0.77 + i * 0.22, 1.51, 0.50), Vector3(0.218, 0.105, 0.04), stripe)
	var postcard := Reveals.shape_node("postcard", 0.17, Color("eac693"))
	postcard.position = Vector3(0.43, 0.79, 0.16)
	postcard.rotation_degrees = Vector3(-12, -13, 0)
	root.add_child(postcard)
	_box(root, Vector3(0.28, 0.49, 0.09), Vector3(0.74, 0.20, 0.04), cream)
	_sign(root, "POSTCARD  50p", Vector3(0.28, 0.49, 0.12), 0.082, Color("602820"))

	# The pillar box has a curved cap, projecting mail slot and separate plinth.
	var mailbox := Node3D.new()
	mailbox.position = Vector3(-0.65, 0, 0.68)
	root.add_child(mailbox)
	_cylinder(mailbox, Vector3(0, 0.33, 0), 0.16, 0.59, red)
	_cylinder(mailbox, Vector3(0, 0.049, 0), 0.19, 0.09, dark)
	_cylinder(mailbox, Vector3(0, 0.65, 0), 0.18, 0.12, red, 0.12)
	_box(mailbox, Vector3(0, 0.51, 0.146), Vector3(0.19, 0.047, 0.06), dark)
	_box(mailbox, Vector3(0, 0.44, 0.158), Vector3(0.11, 0.055, 0.015), cream)


func _phone_booth(street: Node3D) -> void:
	var root := Node3D.new()
	root.position = Vector3(1.81, 0.07, -0.20)
	root.scale = Vector3(1.23, 1.33, 1.32)
	root.rotation_degrees.y = -10
	street.add_child(root)
	var yellow := _mat("e4b44d")
	var teal := _mat("385c5c")
	var enamel := _mat("fae4a1")
	var dark := _mat("272632")
	var panel := _mat("648e88")
	_box(root, Vector3(0, 0.94, -0.37), Vector3(1.18, 1.88, 0.10), teal)
	_box(root, Vector3(0, 1.93, -0.05), Vector3(1.30, 0.12, 0.99), yellow)
	_box(root, Vector3(0, 1.78, 0.43), Vector3(1.24, 0.30, 0.15), yellow)
	_sign(root, "STD  PCO", Vector3(0, 1.78, 0.514), 0.185, Color("262731"))
	for x in [-0.565, 0.565]:
		_box(root, Vector3(x, 0.85, 0.31), Vector3(0.085, 1.69, 0.095), yellow)
		_box(root, Vector3(x, 0.33, -0.022), Vector3(0.056, 0.66, 0.65), teal)
		_box(root, Vector3(x, 1.23, -0.026), Vector3(0.036, 0.80, 0.60), panel)
	_box(root, Vector3(0, 0.08, -0.03), Vector3(1.08, 0.13, 0.70), teal)
	_box(root, Vector3(0, 0.61, -0.20), Vector3(0.91, 0.095, 0.36), yellow)
	_box(root, Vector3(0, 0.48, 0.31), Vector3(0.87, 0.18, 0.033), enamel)
	_sign(root, "LOCAL CALL  Re 1", Vector3(0, 0.49, 0.335), 0.083, Color("36313b"))
	# Wall-mounted payphone with an actual receiver, keypad, display and coiled cord.
	_box(root, Vector3(0.04, 1.045, -0.233), Vector3(0.44, 0.55, 0.20), yellow)
	_box(root, Vector3(0.10, 1.19, -0.123), Vector3(0.16, 0.079, 0.026), dark)
	_box(root, Vector3(0.094, 1.19, -0.106), Vector3(0.106, 0.033, 0.009), panel)
	_box(root, Vector3(-0.135, 1.06, -0.085), Vector3(0.065, 0.30, 0.07), dark)
	for y in [0.915, 1.205]:
		_box(root, Vector3(-0.133, y, -0.075), Vector3(0.124, 0.09, 0.09), dark)
	for row in 4:
		for column in 3:
			_box(root, Vector3(0.04 + column * 0.057, 1.081 - row * 0.047, -0.118),
				Vector3(0.037, 0.027, 0.018), enamel)
	var previous := Vector3(-0.135, 0.88, -0.066)
	for i in range(1, 23):
		var progress := float(i) / 22.0
		var next := Vector3(-0.135 + 0.20 * progress + sin(progress * TAU * 5.0) * 0.013,
			0.88 - sin(progress * PI) * 0.16, -0.066 + cos(progress * TAU * 5.0) * 0.019)
		_segment(root, previous, next, 0.009, dark)
		previous = next
	_light(root, Vector3(0, 1.63, 0.03), Vector3(0, 0.9, -0.19), Color("fff0b9"), 1.6, 40)


func _dress_street(root: Node3D) -> void:
	_catalog(root, "quaternius_downtown/Building_Small_1", Vector3(-3.7, 0, -4.4), 0.26, 7)
	_catalog(root, "quaternius_downtown/Building_Medium_2_001", Vector3(3.6, 0, -4.9), 0.30, -11)
	_catalog(root, "quaternius_nature/PalmTree_2", Vector3(3.2, 0, -2.5), 1.18)
	_catalog(root, "quaternius_nature/PalmTree_1", Vector3(-4.4, 0, -2.0), 0.85)
	_catalog(root, "quaternius_fantasy_props/Bench", Vector3(-4.14, 0.07, -0.13), 0.83, 22)
	var auto := Reveals.shape_node("rickshaw", 1.90, Color("25694f"))
	auto.position = Vector3(4.06, 0, 1.56)
	auto.rotation_degrees.y = -65
	root.add_child(auto)


func pose(_street: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var params: Dictionary = gag["params"]
	var start := float(params["street_start"])
	var approach := Motion.smooth(Motion.seg(t, start, float(params["street_end"])))
	var camera := Vector3(0.36, 2.15, 9.70).lerp(Vector3(0.11, 1.79, 7.82), approach)
	var focus := Vector3(-0.16, 1.76, 0.3).lerp(Vector3(-0.17, 1.58, 1.07), approach)
	var holder: Node3D = ctx["holder"]
	return {"camera": holder.position + camera, "focus": holder.position + focus}


func _catalog(root: Node3D, id: String, at: Vector3, size: float, yaw: float = 0) -> void:
	var prop := KitDB.static_node(id, size)
	if prop != null:
		prop.position = at
		prop.rotation_degrees.y = yaw
		root.add_child(prop)


func _sign(root: Node3D, text: String, at: Vector3, height: float, color: Color) -> void:
	var letters := Reveals.text_node(text, height, color)
	letters.position = at
	root.add_child(letters)


func _light(root: Node3D, at: Vector3, target: Vector3, color: Color, energy: float, angle: float,
		shadows: bool = false) -> void:
	var lamp := SpotLight3D.new()
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.spot_angle = angle
	lamp.spot_range = 7.0
	lamp.shadow_enabled = shadows
	lamp.shadow_bias = 0.035
	lamp.shadow_normal_bias = 0.35
	lamp.transform = Transform3D(Basis.looking_at(target - at), at)
	root.add_child(lamp)


func _mat(hex: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.roughness = 0.72
	return mat


func _box(root: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(root, at, mesh, mat)


func _cylinder(root: Node3D, at: Vector3, radius: float, height: float, mat: Material,
		top: float = -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius if top < 0.0 else top
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	return _mesh(root, at, mesh, mat)


func _segment(root: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material) -> void:
	var link := _cylinder(root, (a + b) * 0.5, radius, a.distance_to(b), mat)
	link.quaternion = Quaternion(Vector3.UP, (b - a).normalized())


func _mesh(root: Node3D, at: Vector3, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = mesh
	item.material_override = mat
	item.position = at
	root.add_child(item)
	return item
