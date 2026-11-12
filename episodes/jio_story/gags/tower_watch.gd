## A windblown lookout with a low, rising camera move.
extends RefCounted

const KitDB = preload("res://scripts/world/kit_db.gd")
const Toon = preload("res://scripts/actors/toon.gd")
const BinocularPose = preload("res://scripts/timeline/binocular_pose.gd")

const LENGTH_STEPS := 32
const WIDTH_STEPS := 6


func build(_gag: Dictionary) -> Node3D:
	var tower := Node3D.new()
	_build_platform(tower)
	_build_distance(tower)
	tower.add_child(BinocularPose.build())
	var cloth := _material("ffffff", 0.79)
	cloth.vertex_color_use_as_albedo = true
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	var silk := _material("a32b39", 0.76)
	var scarf := Node3D.new()
	scarf.name = "scarf"
	tower.add_child(scarf)
	var wrap := TorusMesh.new()
	wrap.inner_radius = 0.098
	wrap.outer_radius = 0.166
	wrap.rings = 32
	wrap.ring_segments = 12
	_mesh(scarf, wrap, Vector3.ZERO, silk).scale.y = 1.58
	_mesh(scarf, wrap, Vector3(0.0, -0.026, 0.011), silk).rotation.z = 0.17
	var knot := _mesh(scarf, Toon.sphere(0.074), Vector3(0.142, -0.017, 0.069), silk)
	knot.scale = Vector3(0.87, 0.65, 0.68)
	knot.rotation_degrees.z = 19
	for index in 2:
		var tail := MeshInstance3D.new()
		tail.name = "tail_%d" % index
		tail.material_override = cloth
		scarf.add_child(tail)
	_spot(tower, Vector3(-2.1, 2.4, 2.5), Vector3(-0.24, 0.95, 1.3), Color("ffcfa4"), 3.3, 43, true)
	_spot(tower, Vector3(1.55, 2.5, -0.6), Vector3(-0.11, 1.12, 1.26), Color("ff9b5f"), 4.8, 38)
	_spot(tower, Vector3(0.5, 0.4, 3.5), Vector3(0.3, -1.08, 1.4), Color("73badb"), 2.0, 52)
	return tower


func _build_platform(tower: Node3D) -> void:
	var plank := [_material("715650", 0.85), _material("65454a", 0.89), _material("816058", 0.85)]
	var metal := _material("293447", 0.56, 0.55)
	var trim := _material("745053", 0.65, 0.28)
	var rivet := _material("e0a663", 0.58, 0.55)
	for i in 15:
		var x := (i - 7) * 0.22
		_box(tower, Vector3(x, -0.050, 0.0), Vector3(0.214, 0.10, 3.36), plank[i % plank.size()])
	for side in [-1.0, 1.0]:
		for z in [-1.49, 1.49]:
			_box(tower, Vector3(side * 1.45, -2.33, z), Vector3(0.17, 4.56, 0.17), metal)
			_box(tower, Vector3(side * 1.46, 0.43, z), Vector3(0.10, 0.86, 0.10), metal)
			_box(tower, Vector3(side * 1.46, 0.86, z), Vector3(0.14, 0.05, 0.14), trim)
			_box(tower, Vector3(side * 1.45, -0.45, z), Vector3(0.23, 0.27, 0.21), trim)
		_box(tower, Vector3(side * 1.46, 0.69, 0), Vector3(0.09, 0.085, 3.05), trim)
		_box(tower, Vector3(side * 1.46, 0.29, 0), Vector3(0.06, 0.05, 3.0), metal)
		_box(tower, Vector3(side * 1.48, -0.17, 0), Vector3(0.21, 0.19, 3.34), metal)
		_beam(tower, Vector3(side * 1.45, -3.75, -1.44), Vector3(side * 1.45, -0.22, 1.43), 0.11, metal)
		_beam(tower, Vector3(side * 1.45, -3.75, 1.44), Vector3(side * 1.45, -0.22, -1.43), 0.11, metal)
		# Short front rail returns leave the center clear at the low camera angle.
		_box(tower, Vector3(side * 1.24, 0.69, 1.49), Vector3(0.47, 0.074, 0.08), trim)
		_box(tower, Vector3(side * 1.025, 0.35, 1.49), Vector3(0.065, 0.69, 0.065), metal)
		_box(tower, Vector3(side * 1.05, -0.18, 1.68), Vector3(0.067, 0.061, 0.036), rivet)
	for z in [-1.55, 1.55]:
		_box(tower, Vector3(0, -0.17, z), Vector3(3.31, 0.21, 0.19), metal)
		_beam(tower, Vector3(-1.38, -3.63, z - 0.06), Vector3(1.38, -0.30, z - 0.06), 0.11, metal)
		_beam(tower, Vector3(1.38, -3.63, z + 0.06), Vector3(-1.38, -0.30, z + 0.06), 0.11, metal)
	_box(tower, Vector3(0, 0.69, -1.49), Vector3(2.96, 0.08, 0.08), trim)
	_box(tower, Vector3(0, 0.29, -1.49), Vector3(2.94, 0.05, 0.06), metal)
	# The access ladder reads on the front of the truss in the establishing frames.
	for x in [-1.06, -0.63]:
		_box(tower, Vector3(x, -1.98, 1.69), Vector3(0.055, 4.04, 0.056), trim)
	for i in 12:
		_box(tower, Vector3(-0.845, -0.20 - i * 0.32, 1.71), Vector3(0.43, 0.048, 0.044), trim)


func _build_distance(tower: Node3D) -> void:
	var far_hill := _unlit("292e50")
	var near_hill := _unlit("1c233b")
	for peak in [
		[Vector3(-10.5, -6.5, -19), Vector3(11.0, 5.4, 4.3), far_hill],
		[Vector3(7.2, -7.2, -21), Vector3(12.0, 6.8, 4.0), far_hill],
		[Vector3(-6.9, -7.7, -13), Vector3(10.5, 5.0, 3.1), near_hill],
		[Vector3(8.4, -7.2, -15), Vector3(9.7, 5.3, 3.0), near_hill],
	]:
		_mesh(tower, Toon.sphere(1.0), peak[0], peak[2]).scale = peak[1]
	var town := _unlit("20283e")
	var windows := _unlit("bf907a")
	for i in 15:
		var x := -9.0 + i * 1.18
		var z := -9.0 - (i % 3) * 0.83
		var top := -4.2 + (i * 11 % 7) * 0.29
		_box(tower, Vector3(x, top - 0.75, z), Vector3(1.01, 1.5, 1.2), town)
		for column in 3:
			if (column + i) % 3 != 0:
				_box(tower, Vector3(x + (column - 1) * 0.27, top - 0.31, z + 0.62),
					Vector3(0.10, 0.12, 0.026), windows)
	for palm_at in [Vector3(-3.8, -5.0, -3.0), Vector3(3.8, -5.4, -4.5)]:
		var palm := KitDB.static_node("quaternius_nature/PalmTree_2", 1.38)
		if palm != null:
			palm.position = palm_at
			tower.add_child(palm)


func pose(tower: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var actor = ctx["actor"].call("watching_mukesh")
	var holder: Node3D = ctx["holder"]
	BinocularPose.pose(tower.get_node("binoculars"), actor, t, float(gag["params"]["watch"]),
		holder.position, 0.45, Vector3(0.015, -0.164, 0.092), 0.006)
	var anchors: Dictionary = actor.anchor_points()
	var head: Vector3 = anchors["watching_mukesh.head"]["pos"]
	var chest: Vector3 = anchors["watching_mukesh.chest"]["pos"]
	var scarf := tower.get_node("scarf") as Node3D
	scarf.position = chest.lerp(head, 0.38) - holder.position + Vector3(0, -0.028, 0.011)
	var age := float(ctx["age"])
	var long_tail := scarf.get_node("tail_0") as MeshInstance3D
	var short_tail := scarf.get_node("tail_1") as MeshInstance3D
	long_tail.mesh = _flutter(Vector3(0.157, -0.016, 0.068), 1.08, 0.215, age, 0.0)
	short_tail.mesh = _flutter(Vector3(0.145, -0.053, 0.044), 0.67, 0.165, age, 1.65)
	return {}


func _flutter(pinned: Vector3, length: float, width: float, t: float, phase_offset: float) -> ArrayMesh:
	# Integrate unit tangents to preserve the centerline length. Each section
	# samples the gust later than the section before it, with the knot fixed.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := pinned
	for row in LENGTH_STEPS + 1:
		var u := float(row) / LENGTH_STEPS
		var wind_time := t - u * 0.37
		var gust := sin(TAU * 1.42 * wind_time + phase_offset)
		var flutter := sin(TAU * 4.35 * wind_time - u * 1.1 + phase_offset)
		var elevation := -0.22 + u * (0.20 + 0.64 * gust + 0.30 * flutter)
		var azimuth := -0.15 + u * (0.16 * gust + 0.31 * flutter)
		var tangent := Vector3(cos(azimuth) * cos(elevation), sin(elevation), sin(azimuth) * cos(elevation))
		var twist := 0.15 + u * (0.82 * gust + 0.29 * flutter)
		var across_axis := (Vector3.UP - tangent * tangent.dot(Vector3.UP)).normalized().rotated(tangent, twist)
		var normal := tangent.cross(across_axis).normalized()
		for column in WIDTH_STEPS + 1:
			var across := 2.0 * column / WIDTH_STEPS - 1.0
			var hem := absf(across)
			var spread := width * lerpf(0.36, 1.0, smoothstep(0.0, 0.31, u))
			var crease := u * (0.019 + 0.011 * flutter) * sin(across * PI * 1.6 + gust)
			var vertex := center + across_axis * (across * spread * 0.5) + normal * crease
			vertex -= tangent * smoothstep(0.88, 1.0, u) * hem * (0.022 + 0.014 * flutter)
			var dye := Color("c02b3d").lerp(Color("8e253b"), 0.25 + 0.26 * sin(u * 13.0 + across * 4.8))
			if hem > 0.94 or row == LENGTH_STEPS - 1:
				dye = Color("dc7851")
			surface.set_color(dye)
			surface.add_vertex(vertex)
		center += tangent * (length / LENGTH_STEPS)
	for row in LENGTH_STEPS:
		for column in WIDTH_STEPS:
			var near := row * (WIDTH_STEPS + 1) + column
			var far := near + WIDTH_STEPS + 1
			for index in [near, far, near + 1, near + 1, far, far + 1]:
				surface.add_index(index)
	surface.generate_normals()
	return surface.commit()


func _spot(root: Node3D, at: Vector3, target: Vector3, color: Color, energy: float, angle: float,
		shadows: bool = false) -> void:
	var lamp := SpotLight3D.new()
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.spot_angle = angle
	lamp.spot_range = 8.5
	lamp.shadow_enabled = shadows
	lamp.shadow_bias = 0.034
	lamp.shadow_normal_bias = 0.32
	lamp.transform = Transform3D(Basis.looking_at(target - at), at)
	root.add_child(lamp)


func _material(hex: String, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.roughness = roughness
	mat.metallic = metallic
	return mat


func _unlit(hex: String) -> StandardMaterial3D:
	var mat := _material(hex, 0.88)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


func _beam(root: Node3D, a: Vector3, b: Vector3, width: float, mat: Material) -> void:
	var beam := _box(root, (a + b) * 0.5, Vector3(width, a.distance_to(b), width), mat)
	beam.quaternion = Quaternion(Vector3.UP, (b - a).normalized())


func _box(root: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(root, mesh, at, mat)


func _mesh(root: Node3D, mesh: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = at
	root.add_child(instance)
	return instance
