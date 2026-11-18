extends RefCounted
## A single patient is pulled from the Silkyara rescue pipe in the finished tunnel.
## All animation is seekable: the trolley and both rescuers are posed from scene time.

const Motion = preload("res://scripts/timeline/motion.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")
const MOUTH := Vector3(0.0, 0.5, -15.2)

var _trolley: Node3D
var _rope: MeshInstance3D
var _key: SpotLight3D


func _mat(color: String, rough := 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = rough
	return m


func _lit(color: String, energy: float) -> StandardMaterial3D:
	var m := _mat(color, 0.45)
	m.emission_enabled = true
	m.emission = Color(color)
	m.emission_energy_multiplier = energy
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = mat
	n.position = pos
	parent.add_child(n)
	return n


func _rod(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 1.0
	mesh.radial_segments = 10
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = mat
	parent.add_child(n)
	_segment(n, a, b)
	return n


func _segment(n: Node3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var y := d.normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	n.transform = Transform3D(Basis(x, y, x.cross(y)).scaled(Vector3(1, d.length(), 1)), (a + b) * 0.5)


func _spot(parent: Node3D, at: Vector3, aim: Vector3, color: String, energy: float, radius: float, angle: float) -> SpotLight3D:
	var light := SpotLight3D.new()
	light.transform = Transform3D(Basis.looking_at((aim - at).normalized()), at)
	light.light_color = Color(color)
	light.light_energy = energy
	light.spot_range = radius
	light.spot_angle = angle
	light.shadow_enabled = false
	parent.add_child(light)
	return light


func build(_g: Dictionary) -> Node3D:
	var root := Node3D.new()
	var steel := _mat("#596168", 0.48)
	var dark := _mat("#262b2f", 0.85)
	var orange := _mat("#a85d30", 0.8)
	var wood := _mat("#574638", 0.95)
	# A real 800 mm steel casing, recessed into the collapse, with welded lip.
	var tube := CylinderMesh.new()
	tube.top_radius = 0.43
	tube.bottom_radius = 0.43
	tube.height = 3.2
	tube.radial_segments = 48
	tube.cap_top = false
	tube.cap_bottom = false
	var casing := MeshInstance3D.new()
	casing.mesh = tube
	casing.material_override = steel
	casing.rotation.x = PI * 0.5
	casing.position = MOUTH + Vector3(0, 0, -1.6)
	root.add_child(casing)
	var lip := TorusMesh.new()
	lip.inner_radius = 0.405
	lip.outer_radius = 0.45
	lip.rings = 48
	lip.ring_segments = 8
	var rim := MeshInstance3D.new()
	rim.mesh = lip
	rim.rotation.x = PI * 0.5
	rim.position = MOUTH
	rim.material_override = _mat("#929793", 0.4)
	root.add_child(rim)
	# Dark inner bore masks the rock behind the casing, without a luminous backdrop.
	var bore := CylinderMesh.new()
	bore.top_radius = 0.405
	bore.bottom_radius = 0.405
	bore.height = 0.02
	var cap := MeshInstance3D.new()
	cap.mesh = bore
	cap.rotation.x = PI * 0.5
	cap.position = MOUTH + Vector3(0, 0, -1.8)
	cap.material_override = _mat("#080b0d")
	root.add_child(cap)
	# Level timber runway and two steel guide tracks, tied into the tunnel floor.
	for i in 10:
		_box(root, Vector3(1.65, 0.07, 0.27), Vector3(0, 0.045, -15.2 + i * 0.27), wood)
	for x in [-0.31, 0.31]:
		_box(root, Vector3(0.045, 0.035, 2.9), Vector3(x, 0.1, -13.85), steel)
	# Low, narrow wheeled rescue board: the casters fit through the pipe.
	_trolley = Node3D.new()
	root.add_child(_trolley)
	_box(_trolley, Vector3(0.56, 0.055, 1.9), Vector3(0, 0.15, 0), orange)
	# A padded head support extends beneath the oversized toon head.
	_box(_trolley, Vector3(0.62, 0.08, 0.55), Vector3(0, 0.17, 0.85), _mat("#6d5a46", 0.9))
	for x in [-0.29, 0.29]:
		_rod(_trolley, Vector3(x, 0.18, -0.95), Vector3(x, 0.18, 0.95), 0.02, steel)
	for z in [-0.83, 0.83]:
		_rod(_trolley, Vector3(-0.29, 0.18, z), Vector3(0.29, 0.18, z), 0.02, steel)
		for x in [-0.22, 0.22]:
			_rod(_trolley, Vector3(x - 0.025, 0.06, z), Vector3(x + 0.025, 0.06, z), 0.06, dark)
	for z in [-0.38, 0.35]:
		_box(_trolley, Vector3(0.53, 0.012, 0.09), Vector3(0, 0.185, z), dark)
	_rope = _rod(root, Vector3(0, 0.2, -13.0), Vector3(0, 0.55, -12.0), 0.012, _mat("#b0a080"))
	# A visible practical and a broad, restrained rim light. Face fill stays soft.
	var lamp_at := Vector3(-2.3, 1.95, -13.1)
	for i in 3:
		var a := TAU * i / 3.0
		_rod(root, lamp_at + Vector3(cos(a) * 0.35, -1.95, sin(a) * 0.35), lamp_at, 0.018, dark)
	_box(root, Vector3(0.28, 0.18, 0.1), lamp_at, _lit("#ffe1b5", 2.5))
	_key = _spot(root, lamp_at + Vector3(0.1, 0, 0), Vector3(0, 0.65, -13.9), "#ffd9ad", 1.3, 7.0, 48.0)
	_spot(root, Vector3(1.5, 2.1, -16.0), Vector3(0, 0.7, -13.6), "#b8d3ed", 1.5, 7.0, 40.0)
	root.visible = false
	return root


func pose(root: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	var start := float(p.get("from", 1.0e9))
	var end := float(p.get("until", 1.0e9))
	var on := t >= start and t < end
	root.visible = on
	var patient = ctx["actor"].call(String(p.get("patient", "")))
	var puller = ctx["actor"].call(String(p.get("puller", "")))
	var helper = ctx["actor"].call(String(p.get("helper", "")))
	for a in [patient, puller, helper]:
		if a != null:
			a.visible = on
	if not on:
		return {}
	var G := root.global_transform
	var k := Motion.in_out(Motion.seg(t, float(p.get("pull0", start)), float(p.get("pull1", end))))
	var z := lerpf(-15.4, -13.15, k)
	_trolley.position = Vector3(0, 0.03, z)
	if patient != null:
		# get_up frozen at its first frame is already supine, oriented toward +z.
		patient.global_transform = G * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0.39, z))
		patient._pose_head(Vector3(-0.55, 0.0, 0.0))
	if puller != null:
		var pp := Vector3(-0.72, 0.0, z + 1.1)
		puller.global_transform = G * Transform3D(Basis.IDENTITY, pp)
		Crawl.long_arms(puller, 1.25)
		var grip := Vector3(-0.38, 0.54, z + 1.13)
		puller.aim_hand("r", G * grip, 1.0)
		puller.aim_hand("l", G * (grip + Vector3(0.15, -0.04, 0.05)), 1.0)
		_segment(_rope, Vector3(0, 0.19, z + 0.93), grip)
	if helper != null:
		helper.global_transform = G * Transform3D(Basis.IDENTITY, Vector3(0.85, 0.0, -14.8))
		helper.aim_hand("r", G * Vector3(0.3, 0.25, z - 0.45), 0.65)
	return {"patient": G * Vector3(0, 0.5, z)}
