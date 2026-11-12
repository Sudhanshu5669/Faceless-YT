## A rolling reel pays out enough fibre to wrap a display globe seven and a half times.
extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")
const EARTH := Vector3(0.16, 1.49, -1.12)
const GLOBE_SIZE := 1.60
const REEL_RADIUS := 0.374
const RUN_START := Vector3(-0.68, 0, -0.82)
const RUN_CORNER := Vector3(-0.51, 0, 0.38)
const COIL_SEGMENTS := 360
const LEAD_SEGMENTS := 14
## Simplified longitude/latitude silhouettes for the depot's display globe.
const LAND := [
	[[-18, 15], [-13, 29], [-6, 35], [10, 37], [24, 32], [32, 31], [35, 21],
		[43, 12], [52, 11], [45, 3], [41, -11], [34, -23], [28, -33], [19, -35],
		[12, -23], [11, -9], [8, 4], [-5, 5], [-12, 8]],
	[[-10, 38], [-9, 44], [0, 45], [8, 53], [18, 56], [22, 63], [32, 70],
		[52, 67], [68, 72], [108, 71], [140, 66], [168, 58], [152, 49], [139, 42],
		[122, 31], [110, 20], [106, 11], [100, 5], [99, 15], [93, 21], [86, 23],
		[80, 9], [73, 17], [67, 25], [57, 25], [51, 14], [44, 14], [36, 28],
		[33, 39], [27, 41], [23, 36], [17, 41], [12, 44], [4, 43], [-1, 37]],
	[[-79, 10], [-69, 12], [-60, 7], [-51, 3], [-36, -5], [-39, -15],
		[-46, -23], [-52, -31], [-59, -39], [-66, -54], [-74, -48], [-73, -32],
		[-71, -18], [-77, -8], [-80, 1]],
	[[-142, 60], [-126, 54], [-124, 45], [-117, 32], [-107, 24], [-101, 18],
		[-88, 21], [-86, 16], [-81, 9], [-77, 9], [-82, 18], [-88, 29], [-81, 30],
		[-78, 38], [-66, 46], [-57, 52], [-61, 61], [-76, 65], [-91, 71], [-112, 71]],
	[[-72, 59], [-54, 60], [-43, 65], [-23, 70], [-20, 80], [-40, 83],
		[-60, 81], [-72, 74]],
	[[-6, 49], [-3, 55], [-5, 59], [-1, 60], [1, 53], [0, 50]],
	[[49, -12], [51, -15], [48, -24], [44, -26], [43, -20], [46, -14]],
]


func build(_gag: Dictionary) -> Node3D:
	var yard := Node3D.new()
	_depot(yard)
	_build_globe(yard)
	_build_counter(yard)
	yard.add_child(_reel())
	var fibre := _fibre()
	yard.add_child(_wrap(fibre))
	var lead := Node3D.new()
	lead.name = "lead"
	yard.add_child(lead)
	for index in LEAD_SEGMENTS:
		Kit.add_mesh(lead, Kit.cylinder(0.017, 0.017, 1.0, fibre, 9),
			Vector3.ZERO, Vector3.ZERO, "", false)
	return yard


func _depot(yard: Node3D) -> void:
	var dirt := Kit.mat("97765e")
	var grass := Kit.mat("758362")
	var concrete := Kit.mat("959087")
	var siding := Kit.mat("667474")
	var trim := Kit.mat("476267", 0.55, 0.32)
	Kit.add_box(yard, Vector3(34, 0.14, 33), Vector3(0, -0.15, -6), grass)
	Kit.add_box(yard, Vector3(7.5, 0.18, 11.5), Vector3(0, -0.095, -0.46), dirt)
	Kit.add_box(yard, Vector3(4.9, 0.028, 6.2), Vector3(0, -0.022, -0.18), concrete)
	Kit.add_box(yard, Vector3(5.2, 2.54, 0.17), Vector3(0.28, 1.27, -3.22), siding)
	Kit.add_box(yard, Vector3(5.45, 0.16, 0.60), Vector3(0.28, 2.57, -3.04), trim)
	for index in 15:
		Kit.add_box(yard, Vector3(0.042, 2.33, 0.034),
			Vector3(-2.17 + index * 0.35, 1.23, -3.11), trim, 0, "", false)
	var shutter := Kit.mat("4f595b")
	Kit.add_box(yard, Vector3(1.49, 1.86, 0.093), Vector3(1.49, 0.97, -3.057), shutter)
	for index in 14:
		Kit.add_box(yard, Vector3(1.40, 0.053, 0.02),
			Vector3(1.49, 0.20 + index * 0.12, -2.999), siding, 0, "", false)
	_prop(yard, "quaternius_fantasy_props/Crate_Wooden", Vector3(-1.54, 0, -1.29), 0.71, -7)
	_prop(yard, "quaternius_fantasy_props/Crate_Metal", Vector3(1.57, 0, -1.15), 0.56, 9)
	_prop(yard, "quaternius_nature/PalmTree_2", Vector3(-3.14, 0, -3.57), 0.95, 13)
	_prop(yard, "quaternius_nature/PalmTree_3", Vector3(3.27, 0, -4.31), 0.95, -8)
	_prop(yard, "quaternius_nature/Bush_2", Vector3(-2.21, 0, -1.70), 0.48, 3)
	_prop(yard, "quaternius_nature/Rock_3", Vector3(2.32, 0, -0.37), 0.39, 24)
	for edge in [-1.0, 1.0]:
		for index in 4:
			Kit.add_box(yard, Vector3(0.040, 0.008, 0.32),
				Vector3(edge * 1.34, -0.005, -0.35 + 0.57 * index), Kit.mat("cdb289"))


func _build_globe(yard: Node3D) -> void:
	var globe := Reveals.shape_node("globe", GLOBE_SIZE, Color("386caa"))
	globe.name = "globe"
	globe.position = EARTH
	for index in range(1, globe.get_child_count()):
		(globe.get_child(index) as Node3D).hide()
	_add_land(globe)
	yard.add_child(globe)
	var metal := Kit.mat("505c63", 0.49, 0.40)
	Kit.add_mesh(yard, Kit.cylinder(0.34, 0.38, 0.095, metal, 30), Vector3(EARTH.x, 0.048, EARTH.z))
	Kit.add_mesh(yard, Kit.cylinder(0.079, 0.12, 0.66, metal, 20), Vector3(EARTH.x, 0.36, EARTH.z))
	Kit.add_mesh(yard, Kit.cylinder(0.24, 0.16, 0.070, metal, 28), Vector3(EARTH.x, 0.67, EARTH.z))


func _add_land(globe: Node3D) -> void:
	var material := Kit.mat("73a76b", 0.85).duplicate() as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	for outline in LAND:
		var polygon := PackedVector2Array()
		for point in outline:
			polygon.append(Vector2(point[0], point[1]))
		var triangles := Geometry2D.triangulate_polygon(polygon)
		for index in range(0, triangles.size(), 3):
			_land_triangle(surface, polygon[triangles[index]], polygon[triangles[index + 1]],
				polygon[triangles[index + 2]], 3)
	Kit.add_mesh(globe, surface.commit(), Vector3.ZERO)


func _land_triangle(surface: SurfaceTool, a: Vector2, b: Vector2, c: Vector2, depth: int) -> void:
	if depth > 0:
		var ab := (a + b) * 0.5
		var bc := (b + c) * 0.5
		var ca := (c + a) * 0.5
		_land_triangle(surface, a, ab, ca, depth - 1)
		_land_triangle(surface, ab, b, bc, depth - 1)
		_land_triangle(surface, ca, bc, c, depth - 1)
		_land_triangle(surface, ab, bc, ca, depth - 1)
		return
	for coordinate: Vector2 in [a, b, c]:
		var longitude := deg_to_rad(coordinate.x)
		var latitude := deg_to_rad(coordinate.y)
		var normal := Vector3(sin(longitude) * cos(latitude), sin(latitude), cos(longitude) * cos(latitude))
		surface.set_normal(normal)
		surface.add_vertex(normal * GLOBE_SIZE * 0.508)


func _build_counter(yard: Node3D) -> void:
	var casing := Kit.mat("425359", 0.5, 0.39)
	var screen := _ink("1b353e")
	for side in [-1.0, 1.0]:
		Kit.add_box(yard, Vector3(0.062, 2.84, 0.07),
			Vector3(EARTH.x + side * 0.89, 1.42, -2.17), casing)
	Kit.add_box(yard, Vector3(1.86, 0.44, 0.10), Vector3(EARTH.x, 2.78, -2.17), casing)
	Kit.add_box(yard, Vector3(1.76, 0.36, 0.018), Vector3(EARTH.x, 2.78, -2.113), screen)
	var count := _label(yard, "0 km", 0.234, "e9f6df", Vector3(EARTH.x, 2.741, -2.097))
	count.name = "count"
	_label(yard, "FIBRE LAID", 0.080, "add1c8", Vector3(EARTH.x, 2.889, -2.097))


func _reel() -> Node3D:
	var reel := Node3D.new()
	reel.name = "reel"
	var rotor := Node3D.new()
	rotor.name = "rotor"
	reel.add_child(rotor)
	var wood := Kit.mat("a77b4e", 0.76)
	var dark_wood := Kit.mat("77583c", 0.78)
	var steel := Kit.mat("6b7370", 0.49, 0.47)
	var cable := Kit.mat("c48145", 0.62)
	var band := Kit.mat("91603d", 0.70)
	_reel_disc(rotor, 0.266, 0.49, 0.0, cable)
	for index in 13:
		_reel_disc(rotor, 0.271, 0.010, -0.228 + index * 0.038, band)
	for side in [-1.0, 1.0]:
		_reel_disc(rotor, REEL_RADIUS, 0.060, side * 0.278, dark_wood)
		_reel_disc(rotor, 0.346, 0.022, side * 0.318, wood)
		_reel_disc(rotor, 0.090, 0.037, side * 0.336, steel)
		for index in 6:
			var angle := TAU * float(index) / 6.0
			var p := Vector3(side * 0.337, cos(angle) * 0.213, sin(angle) * 0.213)
			Kit.add_mesh(rotor, Kit.cylinder(0.017, 0.017, 0.021, steel, 10),
				p, Vector3(0, 0, 90))
	return reel


func _reel_disc(rotor: Node3D, radius: float, width: float, x: float, material: Material) -> void:
	Kit.add_mesh(rotor, Kit.cylinder(radius, radius, width, material, 40),
		Vector3(x, 0, 0), Vector3(0, 0, 90))


func _wrap(material: Material) -> MultiMeshInstance3D:
	var bundle := MultiMeshInstance3D.new()
	bundle.name = "wrap"
	bundle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh := MultiMesh.new()
	mesh.transform_format = MultiMesh.TRANSFORM_3D
	mesh.mesh = Kit.cylinder(0.015, 0.015, 1.0, material, 9)
	mesh.instance_count = COIL_SEGMENTS
	for index in COIL_SEGMENTS:
		var a := _coil_point(float(index) / COIL_SEGMENTS)
		var b := _coil_point(float(index + 1) / COIL_SEGMENTS)
		mesh.set_instance_transform(index, _span(a, b))
	mesh.visible_instance_count = 0
	bundle.multimesh = mesh
	return bundle


func _coil_point(k: float) -> Vector3:
	var angle := PI * 0.5 + TAU * 7.5 * k
	var latitude := lerpf(-0.67, 0.64, k)
	var radius := 0.855
	return EARTH + Vector3(cos(angle) * cos(latitude), sin(latitude), sin(angle) * cos(latitude)) * radius


func _span(a: Vector3, b: Vector3) -> Transform3D:
	var delta := b - a
	var aim := Basis(Quaternion(Vector3.UP, delta.normalized()))
	return Transform3D(aim.scaled_local(Vector3(1, delta.length() + 0.012, 1)), (a + b) * 0.5)


func _fibre() -> StandardMaterial3D:
	var cable := Kit.mat("edb56a", 0.6).duplicate() as StandardMaterial3D
	cable.emission_enabled = true
	cable.emission = Color("ef9d4d")
	cable.emission_energy_multiplier = 0.44
	return cable


func _prop(root: Node3D, id: String, at: Vector3, scale: float, yaw: float) -> void:
	var prop := KitDB.static_node(id, scale)
	prop.position = at
	prop.rotation_degrees.y = yaw
	root.add_child(prop)


func _ink(color: String) -> StandardMaterial3D:
	var material := Kit.mat(color).duplicate() as StandardMaterial3D
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _label(root: Node3D, text: String, size: float, color: String, at: Vector3) -> MeshInstance3D:
	var label := Reveals.text_node(text, size, Color(color))
	label.material_override = _ink(color)
	label.position = at
	root.add_child(label)
	return label


func pose(yard: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var origin: Vector3 = ctx["holder"].position
	var lay := float(p["lay"])
	var finish := float(p["finish"])
	var reel := yard.get_node("reel") as Node3D
	var feed := _pose_reel(reel, ctx["actor"].call("fibre_mukesh"), origin, t, finish)
	var payout := Motion.smooth(Motion.seg(t, lay - 0.06, finish + 0.055))
	var wrap := yard.get_node("wrap") as MultiMeshInstance3D
	wrap.multimesh.visible_instance_count = roundi(COIL_SEGMENTS * payout)
	_pose_lead(yard.get_node("lead"), feed)
	_pose_counter(yard.get_node("count"), t, lay, float(p["count"]))
	var follow := Motion.smooth(Motion.seg(t, float(gag["t"]), finish + 0.24))
	var camera := Vector3(1.42, 1.53, 4.18).lerp(Vector3(1.56, 1.78, 5.02), follow)
	var focus := Vector3(-0.10, 1.35, -0.36).lerp(Vector3(0.11, 1.33, 0.12), follow)
	return {"camera": origin + camera, "focus": origin + focus}


func _pose_reel(reel: Node3D, actor, origin: Vector3, t: float, finish: float) -> Vector3:
	var pos: Vector3 = actor.position - origin
	var forward := Vector3(sin(actor.rotation.y), 0, cos(actor.rotation.y))
	var side := Vector3(cos(actor.rotation.y), 0, -sin(actor.rotation.y))
	reel.rotation.y = actor.rotation.y
	reel.position = pos + forward * 0.52 + Vector3.UP * REEL_RADIUS
	var travel := RUN_START.distance_to(pos) if pos.z <= RUN_CORNER.z else RUN_START.distance_to(RUN_CORNER) + RUN_CORNER.distance_to(pos)
	(reel.get_node("rotor") as Node3D).rotation.x = travel / REEL_RADIUS
	var release := Motion.smooth(Motion.seg(t, finish + 0.18, finish + 0.37))
	for direction: float in [-1.0, 1.0]:
		var arm := "l" if direction > 0 else "r"
		var grip := reel.position + side * (direction * 0.23) + Vector3.UP * 0.252 - forward * 0.19
		actor.aim_hand(arm, origin + grip, 1.0 - 0.35 * release, 0.035)
	return reel.position + side * 0.205 - forward * 0.236 + Vector3.UP * 0.114


func _pose_lead(lead: Node3D, feed: Vector3) -> void:
	var start := _coil_point(0.0)
	var slack := minf(start.distance_to(feed) * 0.36, 0.42)
	var previous := start
	for index in LEAD_SEGMENTS:
		var k := float(index + 1) / LEAD_SEGMENTS
		var bow := sin(k * PI)
		var point := start.lerp(feed, k) + Vector3(0.32 * bow, -slack * bow, 0)
		(lead.get_child(index) as MeshInstance3D).transform = _span(previous, point)
		previous = point


func _pose_counter(count: MeshInstance3D, t: float, lay: float, land: float) -> void:
	var ramp := Motion.out_cubic(Motion.seg(t, lay, land))
	var amount := 300000 if t >= land else roundi(300.0 * ramp) * 1000
	var glyphs := count.mesh as TextMesh
	var text := Reveals.format_number(amount, 0, true, "", " km", "indian")
	if glyphs.text != text:
		glyphs.text = text
	(count.material_override as StandardMaterial3D).albedo_color = Color("f6d690" if t >= land else "e9f6df")
