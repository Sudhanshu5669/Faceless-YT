extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")
const CENTER := Vector3(0.25, 1.35, 0)
const RADIUS := 0.83
# Simplified outlines for the desk globe. Use the existing India outline for the highlight.
const CONTINENTS := [
	[[-168, 64], [-140, 71], [-93, 75], [-57, 54], [-76, 42], [-82, 25], [-95, 16],
		[-116, 29], [-128, 48], [-155, 58]],
	[[-80, 9], [-63, 11], [-46, 0], [-35, -9], [-55, -34], [-68, -55], [-77, -19]],
	[[-12, 35], [-17, 15], [3, 2], [11, -17], [29, -35], [41, -15], [51, 12],
		[32, 30], [10, 37]],
	[[-11, 37], [-4, 57], [28, 72], [66, 72], [110, 74], [163, 66], [179, 56],
		[137, 37], [126, 18], [109, 1], [99, 8], [95, 23], [80, 31], [67, 25],
		[54, 25], [38, 41], [19, 39]],
	[[114, -21], [129, -12], [147, -15], [154, -28], [144, -40], [118, -34]],
	[[-72, 62], [-53, 60], [-20, 78], [-40, 83], [-69, 78]],
]


func build(_gag: Dictionary) -> Node3D:
	var room := Node3D.new()
	var bronze := Kit.mat("ab8049", 0.34, 0.52)
	var wood := Kit.mat("523c36", 0.5)
	Kit.add_box(room, Vector3(1.72, 0.12, 1.03), Vector3(0.27, 0.46, 0), wood)
	for x in [-0.40, 0.95]:
		for z in [-0.39, 0.39]:
			Kit.add_box(room, Vector3(0.075, 0.41, 0.08), Vector3(x, 0.205, z), wood)
	Kit.add_mesh(room, Kit.cylinder(0.28, 0.37, 0.05, bronze, 36), Vector3(CENTER.x, 0.55, 0))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.87
	ring.outer_radius = 0.90
	ring.material = bronze
	var meridian := Kit.add_mesh(room, ring, CENTER, Vector3(0, 0, 90), "", false)
	meridian.rotate_y(1.12)
	var globe := Node3D.new()
	globe.name = "globe"
	globe.position = CENTER
	room.add_child(globe)
	Kit.add_mesh(globe, Kit.sphere(RADIUS, RADIUS * 2, Kit.mat("183864", 0.50), 64), Vector3.ZERO)
	for outline in CONTINENTS:
		_surface(globe, outline, RADIUS + 0.009, Kit.mat("487773", 0.72))
	var india := _surface(globe, Reveals.INDIA, RADIUS + 0.017, Kit.glow_mat("ffb14e", 0.65).duplicate())
	india.name = "india"
	var halo := OmniLight3D.new()
	halo.name = "light"
	halo.light_color = Color("ffaf54")
	halo.omni_range = 1.0
	halo.position = _sphere_point(Vector2(80, 22), RADIUS + 0.16)
	globe.add_child(halo)
	return room


func _sphere_point(point: Vector2, radius: float) -> Vector3:
	var longitude := deg_to_rad(point.x - 82.5)
	var latitude := deg_to_rad(point.y - 10.0)
	return Vector3(sin(longitude) * cos(latitude), sin(latitude), cos(longitude) * cos(latitude)) * radius


func _surface(root: Node3D, outline: Array, radius: float, material: Material) -> MeshInstance3D:
	var polygon := PackedVector2Array()
	for p in outline:
		polygon.append(Vector2(p[0], p[1]))
	var indices := Geometry2D.triangulate_polygon(polygon)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, indices.size(), 3):
		_triangle(surface, polygon[indices[i]], polygon[indices[i + 1]], polygon[indices[i + 2]], radius, 3)
	surface.set_material(material)
	var mesh := Kit.add_mesh(root, surface.commit(), Vector3.ZERO, Vector3.ZERO, "", false)
	(mesh.mesh.surface_get_material(0) as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	return mesh


func _triangle(s: SurfaceTool, a: Vector2, b: Vector2, c: Vector2, radius: float, depth: int) -> void:
	if depth <= 0:
		for point in [a, b, c]:
			var v := _sphere_point(point, radius)
			s.set_normal(v.normalized())
			s.add_vertex(v)
		return
	var ab := (a + b) * 0.5
	var bc := (b + c) * 0.5
	var ca := (c + a) * 0.5
	_triangle(s, a, ab, ca, radius, depth - 1)
	_triangle(s, ab, b, bc, radius, depth - 1)
	_triangle(s, ca, bc, c, radius, depth - 1)
	_triangle(s, ab, bc, ca, radius, depth - 1)


func pose(room: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var spin := float(p["spin"])
	var land := float(p["land"])
	var data := float(p["data"])
	var globe := room.get_node("globe") as Node3D
	var turn := Motion.out_cubic(Motion.seg(t, spin + 0.14, land + 0.10))
	globe.rotation.y = -1.03 + 1.12 * turn + 0.06 * Motion.wobble(t - land, 2.0, 4.0)
	var india := globe.get_node("india") as MeshInstance3D
	var bright := Motion.out_cubic(Motion.seg(t, land, land + 0.28))
	var lamp := india.mesh.surface_get_material(0) as StandardMaterial3D
	lamp.albedo_color = Color("5b8b7d").lerp(Color("ffb85c"), bright)
	lamp.emission_energy_multiplier = 0.08 + bright * 1.4 + 0.3 * Motion.wobble(t - data)
	(globe.get_node("light") as OmniLight3D).light_energy = bright * 0.55
	var origin: Vector3 = ctx["holder"].position
	var actor = ctx["actor"].call("globe_mukesh")
	var gesture := Motion.smooth(Motion.seg(t, spin, spin + 0.19))
	gesture *= 1.0 - Motion.smooth(Motion.seg(t, land + 0.14, land + 0.43))
	var hand := Vector3(-0.34, 1.19, 0.36).lerp(Vector3(-0.20, 1.29, 0.62), turn)
	actor.aim_hand("l", origin + hand, gesture)
	var push := Motion.smooth(Motion.seg(t, spin + 0.19, data + 0.34))
	var camera := Vector3(0.0, 1.85, 4.5).lerp(Vector3(0.34, 1.68, 3.52), push)
	var focus := Vector3(0.01, 1.35, 0.05).lerp(CENTER, push)
	return {"camera": origin + camera, "focus": origin + focus}
