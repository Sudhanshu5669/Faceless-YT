## Akash bins a rotary phone and launches a fountain of photos and videos from his smartphone.
extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")
const BIN := Vector3(1.18, 0.026, 1.28)
const BIN_SIZE := 0.70
const THROW_HAND := Vector3(1.35, 0.94, 0.47)
const PHONE_SIZE := 0.245
const MEDIA_POSITIONS := [
	Vector3(1.68, 2.35, 0.34), Vector3(1.89, 2.08, 0.58), Vector3(1.53, 1.98, 0.63),
	Vector3(1.89, 1.76, 0.70), Vector3(1.61, 1.67, 0.62),
]


func build(_gag: Dictionary) -> Node3D:
	var scene := Node3D.new()
	var bin := Reveals.shape_node("bin", BIN_SIZE, Color("44565a"))
	bin.name = "bin"
	bin.position = BIN
	var wall := bin.get_child(0) as MeshInstance3D
	var open_wall := wall.mesh.duplicate() as CylinderMesh
	open_wall.cap_top = false
	wall.mesh = open_wall
	var floor := bin.get_child(2) as MeshInstance3D
	floor.position.y = 0.044
	floor.scale.x = 0.82
	floor.scale.z = 0.82
	scene.add_child(bin)
	var landline := _landline()
	landline.name = "landline"
	scene.add_child(landline)
	var phone := Reveals.shape_node("phone", PHONE_SIZE, Color("223144"))
	phone.name = "smartphone"
	scene.add_child(phone)
	Kit.add_box(phone, Vector3(0.104, 0.207, 0.003),
		Vector3(0, PHONE_SIZE * 0.5, 0.011), _ink("274761"))
	Kit.add_box(phone, Vector3(0.078, 0.068, 0.003), Vector3(0, 0.143, 0.013), _ink("77adb1"))
	for index in 3:
		Kit.add_box(phone, Vector3(0.074 - index * 0.016, 0.005, 0.003),
			Vector3(0, 0.094 - index * 0.014, 0.014), _ink("a2c0cb"))
	for index in MEDIA_POSITIONS.size():
		var card := _media_card(index)
		card.name = "media_%d" % index
		card.hide()
		scene.add_child(card)
	return scene


func _landline() -> Node3D:
	var phone := Node3D.new()
	var shell := Kit.mat("883638", 0.39)
	var pad := Kit.mat("d8b992", 0.46)
	var rubber := Kit.mat("392c33", 0.68)
	Kit.add_box(phone, Vector3(0.31, 0.072, 0.246), Vector3(0, 0.038, 0), rubber)
	Kit.add_box(phone, Vector3(0.32, 0.059, 0.249), Vector3(0, 0.082, 0), shell)
	Kit.add_mesh(phone, Kit.cylinder(0.071, 0.071, 0.013, pad, 24), Vector3(0, 0.119, 0.036))
	Kit.add_mesh(phone, Kit.cylinder(0.024, 0.024, 0.017, shell, 20), Vector3(0, 0.126, 0.036))
	for index in 10:
		var angle := TAU * float(index) / 10.0
		Kit.add_mesh(phone, Kit.cylinder(0.008, 0.008, 0.005, rubber, 10),
			Vector3(0.052 * cos(angle), 0.128, 0.036 + 0.052 * sin(angle)))
	var handle := Kit.add_box(phone, Vector3(0.246, 0.042, 0.053), Vector3(0, 0.156, -0.081), shell)
	handle.rotation_degrees.z = 2.5
	for side in [-1.0, 1.0]:
		Kit.add_box(phone, Vector3(0.071, 0.067, 0.098), Vector3(side * 0.113, 0.144, -0.078), shell)
		Kit.add_box(phone, Vector3(0.048, 0.009, 0.055), Vector3(side * 0.113, 0.109, -0.078), rubber)
	return phone


func _media_card(index: int) -> Node3D:
	var frame := Node3D.new()
	var photo := index % 2 == 0
	var border := _ink("e4ebe5" if photo else "253b51")
	var sky: String = ["8dbcd6", "b38a88", "73aaba", "4a7394", "d7a282"][index]
	var mountain: String = ["386979", "694962", "467c7d", "324963", "715568"][index]
	Kit.add_box(frame, Vector3(0.345, 0.224, 0.014), Vector3.ZERO, border)
	Kit.add_box(frame, Vector3(0.315, 0.174, 0.006), Vector3(0, 0.009, 0.009), _ink(sky))
	Kit.add_mesh(frame, Kit.cylinder(0.023, 0.023, 0.004, _ink("f9d69b"), 16),
		Vector3(0.085, 0.050, 0.015), Vector3(90, 0, 0))
	_triangle(frame, Vector3(-0.157, -0.078, 0.015), Vector3(-0.064, 0.049, 0.015),
		Vector3(0.073, -0.078, 0.015), _ink(mountain))
	_triangle(frame, Vector3(-0.019, -0.078, 0.016), Vector3(0.093, 0.018, 0.016),
		Vector3(0.157, -0.078, 0.016), _ink("547e82"))
	if not photo:
		Kit.add_mesh(frame, Kit.cylinder(0.040, 0.040, 0.005, _ink("213347"), 20),
			Vector3(0, 0.012, 0.019), Vector3(90, 0, 0))
		_triangle(frame, Vector3(-0.011, -0.007, 0.023), Vector3(-0.011, 0.032, 0.023),
			Vector3(0.024, 0.012, 0.023), _ink("f2eee4"))
		Kit.add_box(frame, Vector3(0.25, 0.007, 0.004), Vector3(0, -0.093, 0.012), _ink("b8c0bb"))
		Kit.add_box(frame, Vector3(0.074, 0.008, 0.005), Vector3(-0.089, -0.093, 0.015), _ink("dd765a"))
	return frame


func _triangle(root: Node3D, a: Vector3, b: Vector3, c: Vector3, material: Material) -> void:
	var geometry := SurfaceTool.new()
	geometry.begin(Mesh.PRIMITIVE_TRIANGLES)
	geometry.set_material(material)
	for point in [a, b, c]:
		geometry.add_vertex(point)
	geometry.generate_normals()
	Kit.add_mesh(root, geometry.commit(), Vector3.ZERO, Vector3.ZERO, "", false)


func _ink(color: String) -> StandardMaterial3D:
	var material := Kit.mat(color).duplicate() as StandardMaterial3D
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func pose(scene: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var calls := float(p["calls"])
	var data := float(p["data"])
	var origin: Vector3 = ctx["holder"].position
	var akash = ctx["actor"].call("akash_home")
	_pose_throw(scene, akash, origin, float(p["show"]), calls, data, t)
	var source := _pose_smartphone(scene, akash, origin, data, t)
	_pose_media(scene, source, data, t)
	var push := Motion.smooth(Motion.seg(t, float(gag["t"]), float(p["end"])))
	var lift := Motion.smooth(Motion.seg(t, data - 0.38, data + 0.48))
	var camera := Vector3(2.00, 1.62, 3.91).lerp(Vector3(1.91, 1.65, 3.60), push)
	var focus := Vector3(1.53, 1.11, 0.28).lerp(Vector3(1.62, 1.30, 0.40), lift)
	return {"camera": origin + camera, "focus": origin + focus}


func _pose_throw(scene: Node3D, actor, origin: Vector3, show: float, calls: float, data: float, t: float) -> void:
	var phone := scene.get_node("landline") as Node3D
	var release := calls - 0.43
	var wind := Motion.smooth(Motion.seg(t, release - 0.40, release - 0.21))
	var flick := Motion.out_cubic(Motion.seg(t, release - 0.21, release))
	var present := Motion.smooth(Motion.seg(t, show - 0.15, show + 0.23)) * (1.0 - wind)
	var rest := Vector3(1.34, 0.68 + 0.098 * present, 0.44 + 0.037 * present)
	var hand := Motion.arc(rest.lerp(Vector3(1.38, 0.74, 0.28), wind),
		THROW_HAND, 0.029, flick)
	var follow := Motion.smooth(Motion.seg(t, release, calls + 0.17))
	hand = hand.lerp(Vector3(1.35, 0.70, 0.38), follow)
	var tap := Motion.smooth(Motion.seg(t, data - 0.25, data)) * (1.0 - Motion.smooth(Motion.seg(t, data + 0.05, data + 0.24)))
	hand = hand.lerp(Vector3(1.70, 0.91, 0.46), tap)
	actor.aim_hand("r", origin + hand)
	phone.visible = t < calls + 0.18
	if t < release:
		phone.rotation = Vector3(0.45 + 0.16 * present + 0.25 * flick, -0.16, -0.09 - 0.10 * flick)
		phone.position = actor.bone_world("hand_r") - origin + Vector3(0, -0.067, 0.024)
	else:
		var flight := Motion.seg(t, release, calls)
		var drop := Motion.in_cubic(Motion.seg(t, calls, calls + 0.18))
		var lip := BIN + Vector3.UP * (BIN_SIZE * 0.92)
		phone.position = Motion.arc(THROW_HAND + Vector3(0, -0.067, 0.024), lip, 0.30, flight)
		phone.position.y -= 0.31 * drop
		phone.rotation = Vector3(lerpf(0.70, TAU, flight) + drop * 0.08,
			lerpf(-0.16, 0.18, flight), lerpf(-0.19, 0.04, flight))
	var bin := scene.get_node("bin") as Node3D
	bin.scale = Motion.squash(Motion.impact(t - calls, 0.095))
	bin.rotation.z = 0.07 * Motion.wobble(t - calls, 5.2, 10.0)


func _pose_smartphone(scene: Node3D, actor, origin: Vector3, data: float, t: float) -> Vector3:
	var phone := scene.get_node("smartphone") as Node3D
	var raise := Motion.smooth(Motion.seg(t, data - 0.43, data))
	var grip := Motion.arc(Vector3(1.79, 0.54, 0.38), Vector3(1.84, 0.93, 0.47), 0.043, raise)
	grip.y += 0.016 * Motion.wobble(t - data, 4.0, 8.0) * Motion.smooth(Motion.seg(t, data, data + 0.08))
	actor.aim_hand("l", origin + grip, 1.0, 0.038 * raise)
	phone.rotation = Vector3(lerpf(-0.55, -0.16, raise), -0.14, 0.10)
	phone.position = actor.bone_world("hand_l") - origin - phone.basis * Vector3(0.036, 0.046, 0.002)
	return phone.position + phone.basis * Vector3(0, PHONE_SIZE * 0.90, 0.021)


func _pose_media(scene: Node3D, source: Vector3, data: float, t: float) -> void:
	for index in MEDIA_POSITIONS.size():
		var card := scene.get_node("media_%d" % index) as Node3D
		var launch := data + 0.064 * index
		var flight := Motion.out_cubic(Motion.seg(t, launch, launch + 0.48))
		var target: Vector3 = MEDIA_POSITIONS[index]
		var hang := Motion.smooth(Motion.seg(t, launch + 0.42, launch + 0.62))
		card.visible = t >= launch
		card.position = Motion.arc(source, target, 0.19 + index * 0.022, flight)
		card.position.y += 0.018 * hang * sin((t - launch) * 5.0 + index * 1.55)
		var size := lerpf(0.10, 1.0, Motion.out_cubic(Motion.seg(t, launch, launch + 0.31)))
		card.scale = Vector3.ONE * size
		var bank := [-0.09, 0.12, -0.16, 0.15, -0.13][index] as float
		card.rotation = Vector3(0.12 * (1.0 - flight), 0.15 + 0.12 * sin(index * 1.7),
			bank + 0.12 * (1.0 - flight))
