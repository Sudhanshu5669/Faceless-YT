## At home, Isha tries the trackpad and the router hoovers up the half-loaded page.
extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")
const LAPTOP_AT := Vector3(-0.105, 0.651, 0.61)
const LAPTOP_SIZE := 0.65
const LAPTOP_YAW := -0.28
const ROUTER_AT := Vector3(0.58, 0.65, 0.46)
const TRACKPAD := Vector3(-0.085, 0.685, 0.76)
const HOSE_PIVOT := Vector3(-0.07, 0.12, 0.015)
const INTAKE := Vector3(-0.29, 0.43, 0.19)


func build(_gag: Dictionary) -> Node3D:
	var room := Node3D.new()
	_lounge(room)
	var laptop := Reveals.shape_node("laptop", LAPTOP_SIZE, Color("394456"))
	laptop.position = LAPTOP_AT
	laptop.rotation.y = LAPTOP_YAW
	room.add_child(laptop)
	var screen_pose := _screen()
	var blank := Kit.add_box(room, Vector3(0.573, 0.328, 0.009), screen_pose.origin, _ink("172839"))
	blank.basis = screen_pose.basis
	var page := _webpage()
	page.name = "page"
	room.add_child(page)
	room.add_child(_router())
	_light(room, Vector3(-0.81, 1.67, 1.77), "ffd3ac", 1.21, 3.8)
	_light(room, Vector3(1.13, 1.82, -0.24), "9bc3ed", 1.32, 3.1)
	return room


func _lounge(room: Node3D) -> void:
	_prop(room, "quaternius_fantasy_props/Table_Large", Vector3(0.12, 0, 0.62), 0.80)
	_prop(room, "quaternius_fantasy_props/Chair_1", Vector3(-0.53, 0, 0.15), 0.90, 24)
	_prop(room, "quaternius_fantasy_props/Bookcase_2", Vector3(1.60, 0.0, -1.76), 0.80, -8)
	_prop(room, "quaternius_fantasy_props/BookGroup_Small_1", Vector3(1.46, 0.84, -1.49), 0.82)
	_prop(room, "quaternius_fantasy_props/Book_Stack_2", Vector3(0.91, 0.65, 0.55), 0.75, 16)
	_prop(room, "fab_cartoon_food/Mug_1", Vector3(-0.87, 0.65, 0.67), 0.74, -35)
	_prop(room, "quaternius_nature/Plant_2", Vector3(-1.59, 0.15, -0.84), 0.76, 20)
	Kit.add_mesh(room, Kit.cylinder(0.18, 0.14, 0.31, Kit.mat("7e4f3d"), 20), Vector3(-1.59, 0.15, -0.84))
	var brass := Kit.mat("ae804c", 0.48, 0.45)
	var upholstery := Kit.mat("465758", 0.81)
	var wood := Kit.mat("5a3d32")
	Kit.add_box(room, Vector3(2.24, 0.16, 0.66), Vector3(-0.57, 0.27, -1.21), wood)
	Kit.add_box(room, Vector3(2.19, 0.15, 0.62), Vector3(-0.57, 0.42, -1.21), upholstery)
	Kit.add_box(room, Vector3(2.25, 0.52, 0.14), Vector3(-0.57, 0.58, -1.52), upholstery)
	for side in [-1.0, 1.0]:
		Kit.add_box(room, Vector3(0.12, 0.27, 0.56), Vector3(-0.57 + side * 1.05, 0.51, -1.21), wood)
		var cushion := Kit.add_mesh(room, Kit.sphere(0.18, 0.32, Kit.mat("ad7957")),
			Vector3(-0.57 + side * 0.74, 0.59, -1.39))
		cushion.scale.z = 0.55
		cushion.rotation_degrees.z = -side * 12.0
	Kit.add_box(room, Vector3(3.04, 0.023, 2.74), Vector3(0, 0.011, 0.35), Kit.mat("5c343f"))
	for side in [-1.0, 1.0]:
		Kit.add_box(room, Vector3(2.91, 0.007, 0.033), Vector3(0, 0.026, 0.35 + side * 1.30), brass)
		Kit.add_box(room, Vector3(0.033, 0.007, 2.64), Vector3(side * 1.46, 0.026, 0.35), brass)
	room.add_child(_suitcase())


func _suitcase() -> Node3D:
	var bag := Node3D.new()
	bag.position = Vector3(-0.51, 0.03, 1.17)
	bag.rotation_degrees.y = -12
	var leather := Kit.mat("334e74", 0.68)
	var rubber := Kit.mat("222932", 0.78)
	var steel := Kit.mat("a5a7a4", 0.43, 0.52)
	Kit.add_box(bag, Vector3(0.34, 0.43, 0.21), Vector3(0, 0.262, 0), rubber)
	Kit.add_box(bag, Vector3(0.31, 0.395, 0.18), Vector3(0, 0.265, 0.043), leather)
	for x in [-0.105, -0.035, 0.035, 0.105]:
		Kit.add_box(bag, Vector3(0.013, 0.33, 0.013), Vector3(x, 0.263, 0.139), leather)
	for x in [-0.115, 0.115]:
		Kit.add_mesh(bag, Kit.sphere(0.035, 0.071, rubber), Vector3(x, 0.035, 0.071))
		Kit.add_box(bag, Vector3(0.012, 0.17, 0.013), Vector3(x * 0.52, 0.55, -0.05), steel)
	Kit.add_box(bag, Vector3(0.148, 0.025, 0.040), Vector3(0, 0.64, -0.05), rubber)
	Kit.add_box(bag, Vector3(0.15, 0.081, 0.008), Vector3(0.058, 0.417, 0.147), Kit.mat("dfd2ac"))
	_text(bag, "YALE", 0.045, "23344e", Vector3(0.058, 0.415, 0.154))
	return bag


func _screen() -> Transform3D:
	var lid := Basis(Vector3.RIGHT, -0.22)
	var laptop := Transform3D(Basis(Vector3.UP, LAPTOP_YAW), LAPTOP_AT)
	return laptop * Transform3D(lid, Vector3(0, LAPTOP_SIZE * 0.33, -LAPTOP_SIZE * 0.336) + lid.z * 0.014)


func _webpage() -> Node3D:
	var page := Node3D.new()
	Kit.add_box(page, Vector3(0.543, 0.300, 0.009), Vector3.ZERO, _ink("e4e5dc"))
	Kit.add_box(page, Vector3(0.543, 0.048, 0.004), Vector3(0, 0.126, 0.006), _ink("44759f"))
	for index in 3:
		Kit.add_mesh(page, Kit.sphere(0.0065, 0.013, _ink("c4d9e4")),
			Vector3(-0.239 + index * 0.020, 0.125, 0.010))
	Kit.add_box(page, Vector3(0.133, 0.090, 0.004), Vector3(-0.162, 0.029, 0.008), _ink("83aeb5"))
	for index in 4:
		Kit.add_box(page, Vector3(0.24 - index * 0.017, 0.010, 0.004),
			Vector3(0.057, 0.064 - index * 0.026, 0.008), _ink("738b98"))
	Kit.add_box(page, Vector3(0.43, 0.010, 0.004), Vector3(0, -0.105, 0.008), _ink("b5c1be"))
	Kit.add_box(page, Vector3(0.16, 0.010, 0.005), Vector3(-0.13, -0.105, 0.010), _ink("407bad"))
	return page


func _router() -> Node3D:
	var router := Node3D.new()
	router.name = "router"
	var body := Kit.mat("354550", 0.50)
	var top := Kit.mat("77868c", 0.46)
	var rib := Kit.mat("435763", 0.72)
	var black := Kit.mat("1c2831", 0.71)
	Kit.add_box(router, Vector3(0.37, 0.12, 0.28), Vector3(0, 0.062, 0), body)
	Kit.add_box(router, Vector3(0.367, 0.035, 0.275), Vector3(0, 0.132, 0), top)
	for index in 6:
		Kit.add_box(router, Vector3(0.016, 0.008, 0.085),
			Vector3(0.012 + index * 0.022, 0.154, -0.04), black)
	for index in 3:
		var lamp := _ink("b8ef93" if index == 0 else "72b2d0")
		Kit.add_mesh(router, Kit.sphere(0.009, 0.018, lamp),
			Vector3(-0.103 + index * 0.041, 0.08, 0.146))
	for side in [-1.0, 1.0]:
		var antenna := Kit.add_mesh(router, Kit.cylinder(0.011, 0.016, 0.26, black, 12),
			Vector3(side * 0.145, 0.233, -0.102))
		antenna.rotation_degrees.z = -side * 14.0
	var port := Kit.add_mesh(router, Kit.cylinder(0.056, 0.056, 0.024, black, 20),
		HOSE_PIVOT + Vector3(0, 0.032, 0))
	port.rotation_degrees.z = 9.0

	var elbow := Node3D.new()
	elbow.name = "elbow"
	elbow.position = HOSE_PIVOT
	router.add_child(elbow)
	var prev := Vector3.ZERO
	for index in range(1, 17):
		var k := float(index) / 16.0
		var point := Vector3(INTAKE.x * pow(k, 1.8), INTAKE.y * sin(k * PI * 0.5),
			INTAKE.z * k)
		var direction := point - prev
		var segment := Kit.add_mesh(elbow, Kit.cylinder(0.042, 0.042, direction.length() + 0.012, black, 14),
			(prev + point) * 0.5)
		segment.quaternion = Quaternion(Vector3.UP, direction.normalized())
		var ridged := Kit.add_mesh(elbow, Kit.cylinder(0.049, 0.049, 0.013, rib, 14), point)
		ridged.quaternion = segment.quaternion
		prev = point
	var nozzle := Node3D.new()
	nozzle.position = INTAKE
	nozzle.basis = Basis.looking_at(Vector3(-0.86, -0.29, 0.34), Vector3.UP, true)
	elbow.add_child(nozzle)
	Kit.add_box(nozzle, Vector3(0.176, 0.100, 0.14), Vector3(0, 0, 0.012), body)
	Kit.add_box(nozzle, Vector3(0.178, 0.087, 0.018), Vector3(0, 0, 0.087), rib)
	Kit.add_box(nozzle, Vector3(0.139, 0.057, 0.011), Vector3(0, 0, 0.099), _ink("09131b"))
	return router


func _prop(root: Node3D, id: String, at: Vector3, scale: float, yaw: float = 0) -> void:
	var prop := KitDB.static_node(id, scale)
	prop.position = at
	prop.rotation_degrees.y = yaw
	root.add_child(prop)


func _ink(color: String) -> StandardMaterial3D:
	var mat := Kit.mat(color).duplicate() as StandardMaterial3D
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


func _text(root: Node3D, value: String, size: float, color: String, at: Vector3) -> void:
	var label := Reveals.text_node(value, size, Color(color))
	label.material_override = _ink(color)
	label.position = at
	root.add_child(label)


func _light(root: Node3D, at: Vector3, color: String, energy: float, reach: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = at
	lamp.light_color = Color(color)
	lamp.light_energy = energy
	lamp.omni_range = reach
	root.add_child(lamp)


func pose(room: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var tap := float(p["tap"])
	var suck := float(p["suck"])
	var origin: Vector3 = ctx["holder"].position
	_pose_isha(ctx["actor"].call("isha_home"), origin, float(p["dad"]), tap, suck, t)
	var router := room.get_node("router") as Node3D
	var mouth := _pose_router(router, suck, t)
	_pose_page(room.get_node("page"), mouth, suck, t)
	var push := Motion.smooth(Motion.seg(t, float(gag["t"]), float(p["end"])))
	var payoff := Motion.smooth(Motion.seg(t, suck - 0.53, suck + 0.32))
	var camera := Vector3(-0.42, 1.65, 4.04).lerp(Vector3(-0.49, 1.61, 3.18), push)
	var focus := Vector3(-0.01, 0.99, 0.36).lerp(Vector3(0.07, 1.04, 0.43), payoff)
	return {"camera": origin + camera, "focus": origin + focus}


func _pose_isha(actor, origin: Vector3, dad: float, tap: float, suck: float, t: float) -> void:
	var press := Motion.smooth(Motion.seg(t, tap - 0.20, tap)) * (1.0 - Motion.out_cubic(Motion.seg(t, tap + 0.03, tap + 0.23)))
	var gesture := Motion.smooth(Motion.seg(t, tap + 0.21, tap + 0.51))
	var flinch := Motion.smooth(Motion.seg(t, suck, suck + 0.22))
	actor.body.position.y += 0.14
	var rest := TRACKPAD + Vector3(-0.08, 0.08, 0.01)
	var hand := Motion.arc(rest, TRACKPAD, 0.016, press)
	hand = Motion.arc(hand, Vector3(-0.23, 0.85, 0.62), 0.036, gesture)
	hand = hand.lerp(Vector3(-0.39, 0.83, 0.47), flinch)
	actor.aim_hand("l", origin + hand)
	var call := Motion.smooth(Motion.seg(t, dad - 0.20, dad)) * (1.0 - Motion.smooth(Motion.seg(t, dad + 0.17, dad + 0.40)))
	actor.aim_hand("r", origin + Vector3(-0.75, 0.96, 0.37), call)


func _pose_router(router: Node3D, suck: float, t: float) -> Vector3:
	var open := Motion.out_back(Motion.seg(t, suck - 0.41, suck + 0.01), 0.85)
	var shiver := 0.017 * Motion.wobble(t - suck, 9.0, 5.5)
	router.position = ROUTER_AT + Vector3(-0.066 * open + shiver, 0, 0)
	router.rotation.y = -0.13 * open
	var elbow := router.get_node("elbow") as Node3D
	elbow.visible = open > 0.012
	elbow.scale = Vector3.ONE * maxf(0.01, open)
	elbow.rotation.z = -0.48 * (1.0 - open) + shiver
	var mouth_local := INTAKE + Vector3(-0.086, -0.029, 0.034)
	return router.transform * (elbow.transform * mouth_local)


func _pose_page(page: Node3D, mouth: Vector3, suck: float, t: float) -> void:
	var depart := suck - 0.18
	var arrive := suck + 0.36
	var progress := Motion.seg(t, depart, arrive)
	var pull := progress * progress
	var lift := Motion.out_cubic(Motion.seg(t, depart, suck + 0.10))
	var screen := _screen()
	var source := screen.origin + screen.basis.z * 0.014
	var midpoint := source.lerp(mouth, 0.47) + Vector3(0, 0.26, 0.29)
	page.visible = t < arrive
	page.position = source.lerp(midpoint, pull).lerp(midpoint.lerp(mouth, pull), pull)
	page.rotation = screen.basis.get_euler() + Vector3(-0.39 * lift, 1.08 * pull, -0.36 * lift + 0.53 * pull)
	page.scale = Vector3(lerpf(1.0, 0.14, pull), lerpf(1.0, 0.21, pull), 1.0)
