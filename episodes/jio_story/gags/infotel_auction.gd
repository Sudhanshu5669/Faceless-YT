## A bidder taps through the e-auction while the wall display tallies the 22 service areas.
extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")

const MAP_SIZE := 1.93
const MAP_CENTER := Vector3(0.0, 2.22, -1.04)
const KEY := Vector3(-0.17, 0.72, 0.70)
const BID_TAPS := [0, 5, 11, 16]
## Representative points inside the service areas in the DoT's 2010 BWA final results.
## They are illustrative markers, not boundaries or the chronological order of the rounds.
const CIRCLES := [
	["Delhi", 77.21, 28.61], ["Mumbai", 72.88, 19.08], ["Gujarat", 72.57, 23.02],
	["Maharashtra", 74.24, 16.70], ["Karnataka", 76.64, 12.30], ["Kerala", 76.27, 9.97],
	["Tamil Nadu", 78.12, 9.93], ["Andhra Pradesh", 78.49, 17.39],
	["Madhya Pradesh", 77.41, 23.26], ["Rajasthan", 75.79, 26.91],
	["Punjab", 75.86, 30.90], ["Jammu & Kashmir", 74.80, 34.08],
	["Himachal Pradesh", 77.17, 31.10], ["Haryana", 76.59, 29.80],
	["Uttar Pradesh (W)", 78.02, 27.18], ["Uttar Pradesh (E)", 80.95, 26.85],
	["Bihar", 85.14, 25.59], ["Orissa", 85.82, 20.30],
	["Kolkata", 88.36, 22.57], ["West Bengal", 87.32, 24.04],
	["Assam", 92.78, 26.65], ["North East", 94.11, 25.67],
]


func build(_gag: Dictionary) -> Node3D:
	var room := Node3D.new()
	_workstation(room)
	_display(room)
	var screen_light := OmniLight3D.new()
	screen_light.light_color = Color("a8d8ec")
	screen_light.light_energy = 0.32
	screen_light.omni_range = 1.25
	screen_light.position = Vector3(-0.20, 0.86, 0.79)
	room.add_child(screen_light)
	_light(room, Vector3(0.73, 2.39, 1.74), "ffd6a3", 1.55, 4.5)
	_light(room, Vector3(-0.79, 1.48, -0.46), "6ad7e1", 1.28, 3.4)
	return room


func _workstation(room: Node3D) -> void:
	var desk := KitDB.static_node("quaternius_fantasy_props/Table_Large", 0.82)
	desk.position = Vector3(0, 0, 0.94)
	room.add_child(desk)
	var chair := KitDB.static_node("quaternius_fantasy_props/Chair_1", 0.89)
	chair.position = Vector3(0.17, 0, 0.04)
	room.add_child(chair)
	var laptop := Reveals.shape_node("laptop", 0.52, Color("3e4e56"))
	laptop.rotation_degrees.y = 161.0
	laptop.position = Vector3(-0.25, 0.67, 0.79)
	room.add_child(laptop)
	var stand := Kit.mat("263038")
	var trim := Kit.mat("ab7950", 0.57, 0.33)
	Kit.add_box(room, Vector3(0.81, 0.13, 0.035), Vector3(0.14, 0.56, 1.405), trim)
	Kit.add_box(room, Vector3(0.77, 0.102, 0.018), Vector3(0.14, 0.56, 1.428), stand)
	_text(room, "INFOTEL BROADBAND", 0.067, "e8e1c7", Vector3(0.14, 0.561, 1.441))
	for index in 3:
		var file := Kit.add_box(room, Vector3(0.22, 0.026, 0.30),
			Vector3(0.64, 0.686 + 0.028 * index, 0.91), Kit.mat(["827365", "a1947f", "5c6969"][index]))
		file.rotation_degrees.y = -6.0 + 8.0 * index
	var mug := KitDB.static_node("fab_cartoon_food/Mug_1", 0.88)
	mug.position = Vector3(-0.70, 0.67, 0.89)
	mug.rotation_degrees.y = -22
	room.add_child(mug)


func _display(room: Node3D) -> void:
	var outer := Kit.mat("535e64", 0.43, 0.47)
	var glass := _ink("122831")
	var line := _ink("284750")
	Kit.add_box(room, Vector3(2.27, 2.64, 0.15), Vector3(0, 2.37, -1.19), outer)
	Kit.add_box(room, Vector3(2.19, 2.55, 0.026), Vector3(0, 2.37, -1.102), glass)
	Kit.add_box(room, Vector3(2.13, 0.39, 0.014), Vector3(0, 3.410, -1.084), _ink("1d3740"))
	for index in 8:
		Kit.add_box(room, Vector3(2.02, 0.008, 0.003),
			Vector3(0, 1.25 + 0.255 * index, -1.086), line, 0, "", false)
	for index in 9:
		Kit.add_box(room, Vector3(0.008, 1.95, 0.003),
			Vector3(-0.98 + 0.245 * index, 2.20, -1.086), line, 0, "", false)
	var india := Reveals.shape_node("india", MAP_SIZE, Color("3d7881"))
	india.position = MAP_CENTER
	india.rotation_degrees.x = 90
	(india.get_child(0) as MeshInstance3D).material_override = _ink("416f77")
	room.add_child(india)
	_text(room, "BWA SPECTRUM AUCTION", 0.104, "bed4d3", Vector3(0, 3.54, -1.067))
	var count := _text(room, "00 / 22", 0.235, "e8ece7", Vector3(-0.18, 3.30, -1.067))
	count.name = "count"
	_text(room, "CIRCLES", 0.085, "aac6c8", Vector3(0.48, 3.286, -1.067))
	for index in CIRCLES.size():
		var circle: Array = CIRCLES[index]
		var point := Reveals.india_point(circle[1], circle[2], MAP_SIZE)
		var at := MAP_CENTER + Vector3(point.x, -point.z, 0.071)
		_dot(room, at, 0.018, _ink("a2b0a6"))
		var pin := Node3D.new()
		pin.name = "pin_%d" % index
		pin.set_meta("target", at + Vector3(0, 0, 0.013))
		_dot(pin, Vector3.ZERO, 0.034, _ink("442c25"))
		_dot(pin, Vector3(0, 0, 0.007), 0.023, _ink("ffcd70"))
		_dot(pin, Vector3(0, 0, 0.013), 0.010, _ink("fff1aa"))
		pin.hide()
		room.add_child(pin)


func _dot(root: Node3D, at: Vector3, radius: float, material: Material) -> void:
	Kit.add_mesh(root, Kit.cylinder(radius, radius, 0.009, material, 16), at, Vector3(90, 0, 0), "", false)


func _ink(color: String) -> StandardMaterial3D:
	var material := Kit.mat(color).duplicate() as StandardMaterial3D
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _text(root: Node3D, value: String, size: float, color: String, at: Vector3) -> MeshInstance3D:
	var label := Reveals.text_node(value, size, Color(color))
	label.material_override = _ink(color)
	label.position = at
	root.add_child(label)
	return label


func _light(root: Node3D, at: Vector3, color: String, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = Color(color)
	light.light_energy = energy
	light.omni_range = reach
	root.add_child(light)


func _landing(index: int, first: float, last: float) -> float:
	return lerpf(first, last, float(index) / float(CIRCLES.size() - 1))


func pose(room: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var first := float(p["first_win"])
	var last := float(p["twenty_two"])
	var origin: Vector3 = ctx["holder"].position
	var actor = ctx["actor"].call("infotel_bidder")
	_pose_bidder(actor, origin, first, last, t)
	_pose_board(room, first, last, t)
	var scan := Motion.smooth(Motion.seg(t, float(gag["t"]), first))
	var push := Motion.smooth(Motion.seg(t, first - 0.26, last + 0.16))
	var camera := Vector3(0.60, 1.67, 4.28).lerp(Vector3(0.16, 2.42, 3.38), push)
	camera.x += 0.31 * (1.0 - scan)
	var focus := Vector3(-0.03, 1.67, 0.10).lerp(Vector3(0, 2.43, -0.56), push)
	return {"camera": origin + camera, "focus": origin + focus}


func _pose_bidder(actor, origin: Vector3, first: float, last: float, t: float) -> void:
	var press := 0.0
	for index in BID_TAPS:
		var contact := _landing(index, first, last) - 0.045
		var down := Motion.smooth(Motion.seg(t, contact - 0.16, contact))
		var up := Motion.out_cubic(Motion.seg(t, contact + 0.03, contact + 0.19))
		press = maxf(press, down * (1.0 - up))
	var celebrate := Motion.smooth(Motion.seg(t, last, last + 0.35))
	actor.body.position.y += 0.16 + 0.047 * celebrate
	var typing := (1.0 - Motion.smooth(Motion.seg(t, first - 0.33, first))) * (0.5 + 0.5 * sin(t * 17.0))
	var rest := KEY + Vector3(0.06 - 0.032 * typing, 0.08 - 0.058 * typing, -0.03)
	var reach := Motion.arc(rest, KEY, 0.021, press)
	reach = Motion.arc(reach, Vector3(-0.27, 0.95, 0.49), 0.048, celebrate)
	actor.aim_hand("r", origin + reach, 1.0, 0.045)
	actor.aim_hand("l", origin + Vector3(0.43, 0.70, 0.78))


func _pose_board(room: Node3D, first: float, last: float, t: float) -> void:
	var total := 0
	for index in CIRCLES.size():
		var pin := room.get_node("pin_%d" % index) as Node3D
		var hit := _landing(index, first, last)
		var target: Vector3 = pin.get_meta("target")
		var drop := Motion.in_cubic(Motion.seg(t, hit - 0.17, hit))
		pin.visible = t >= hit - 0.17
		pin.position = target + Vector3(0, 0.155 * (1.0 - drop), 0.20 * (1.0 - drop))
		pin.position.z += 0.024 * maxf(0.0, Motion.wobble(t - hit, 5.6, 11.0))
		total += int(t >= hit)
	var count := room.get_node("count") as MeshInstance3D
	var glyphs := count.mesh as TextMesh
	var value := "%02d / %d" % [total, CIRCLES.size()]
	if glyphs.text != value:
		glyphs.text = value
	(count.material_override as StandardMaterial3D).albedo_color = Color("ffcf75" if total == CIRCLES.size() else "e8ece7")
