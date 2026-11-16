extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")
const CAKE := Vector3(0, 0.73, 0.02)
const BRANDS := ["facebook", "Google"]
const COLORS := ["2453ae", "d54a42"]
const SLICE_SIZE := 0.53
const PLATE_GRIP := Vector3(0.105, -0.022, -0.025)


func build(_gag: Dictionary) -> Node3D:
	var room := Node3D.new()
	var wood := Kit.mat("50424f", 0.48)
	Kit.add_box(room, Vector3(1.81, 0.11, 0.92), Vector3(0, 0.66, 0.01), wood)
	for x in [-0.80, 0.80]:
		for z in [-0.36, 0.36]:
			Kit.add_box(room, Vector3(0.09, 0.64, 0.09), Vector3(x, 0.32, z), wood)
	Kit.add_box(room, Vector3(10, 0.16, 9), Vector3(0, 3.70, -0.25), Kit.mat("171d2a"))
	var carpet := Kit.mat("293e68", 0.89)
	Kit.add_box(room, Vector3(5.0, 0.012, 3.15), Vector3(0, 0.008, 0.33), carpet)
	var cake := Reveals.shape_node("cake", 0.99, Color("376bca"))
	cake.position = CAKE
	room.add_child(cake)
	_label(room, "Jio", 0.16, CAKE + Vector3(0, 0.23, 0.52), "ffffff")
	for i in 2:
		var truck := KitDB.static_node("kenney_cars/truck-flat", 0.83)
		if truck == null:
			truck = Node3D.new()
		truck.name = "truck_%d" % i
		room.add_child(truck)
		Kit.add_box(truck, Vector3(0.91, 0.19, 0.04), Vector3(0, 0.43, -1.04), Kit.mat(COLORS[i]))
		var sign := _label(truck, BRANDS[i], 0.12, Vector3(-0.46, 0.49, -0.50), "ffffff")
		sign.rotation.y = -PI * 0.5
		for j in 9:
			_cash(truck, Vector3((j % 3 - 1) * 0.24, 0.55 + (j / 3) * 0.081, -0.57 + (j / 3) * 0.10))
		var bundle := Node3D.new()
		bundle.name = "payment_%d" % i
		_cash(bundle, Vector3.ZERO)
		room.add_child(bundle)
		var plate := Node3D.new()
		plate.name = "plate_%d" % i
		room.add_child(plate)
		Kit.add_mesh(plate, Kit.cylinder(0.162, 0.135, 0.024, Kit.mat("e0e9f7", 0.36), 32), Vector3.ZERO)
		var slice := Reveals.shape_node("cake_slice", SLICE_SIZE, Color("376bca"))
		slice.position = Vector3(0, 0.018, -0.126)
		plate.add_child(slice)
	for pos in [Vector3(-2.50, 2.62, 0.85), Vector3(2.50, 2.62, 0.85), Vector3(0, 2.70, -1.05)]:
		var lamp := OmniLight3D.new()
		lamp.position = pos
		lamp.light_color = Color("ffc68e") if pos.x < 0 else Color("8cb5ff")
		lamp.omni_range = 5.7
		lamp.light_energy = 2.2
		room.add_child(lamp)
	return room


func _cash(root: Node3D, at: Vector3) -> void:
	Kit.add_box(root, Vector3(0.22, 0.078, 0.14), at, Kit.mat("739a71"))
	Kit.add_box(root, Vector3(0.048, 0.082, 0.144), at, Kit.mat("d7c5a3"))


func _label(root: Node3D, value: String, size: float, at: Vector3, color: String) -> MeshInstance3D:
	var label := Reveals.text_node(value, size, Color(color))
	label.position = at
	root.add_child(label)
	return label


func pose(room: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var origin: Vector3 = ctx["holder"].position
	var host = ctx["actor"].call("invest_mukesh")
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var buyer = ctx["actor"].call("invest_buyer_%d" % i)
		var arrival := float(p["arrivals"][i])
		var pay := float(p["payments"][i])
		var take := float(p["slices"][i])
		var arrive := Motion.out_cubic(Motion.seg(t, arrival - 0.36, arrival + 0.58))
		var truck := room.get_node("truck_%d" % i) as Node3D
		truck.position = Vector3(side * 5.0, 0, -1.06).lerp(Vector3(side * 1.83, 0, -0.88), arrive)
		truck.rotation.y = -PI * 0.80 if i == 0 else PI * 0.80
		var trade := Motion.smooth(Motion.seg(t, pay - 0.36, pay))
		var collect := Motion.smooth(Motion.seg(t, take - 0.10, take + 0.44))
		var exchange := Vector3(side * 0.44, 0.94, 0.28)
		var primary := "l" if i == 0 else "r"
		var secondary := "r" if i == 0 else "l"
		buyer.aim_hand(primary, origin + exchange, trade)
		var palm: Vector3 = buyer.bone_world("hand_" + primary) - origin
		var payment := room.get_node("payment_%d" % i) as Node3D
		var stack := Vector3(side * 0.69, 0.76, 0.35)
		payment.position = Motion.arc(palm, stack, 0.15, Motion.smooth(Motion.seg(t, pay, pay + 0.27)))
		payment.visible = t >= arrival
		var plate := room.get_node("plate_%d" % i) as Node3D
		plate.visible = t >= take - 0.10
		var carry: Vector3 = buyer.position - origin + Vector3(-side * 0.06, 0.66, 0.34)
		var plate_at := Motion.arc(CAKE + Vector3(side * 0.33, 0.04, 0.28), carry, 0.055, collect)
		var receive := Motion.smooth(Motion.seg(t, take - 0.19, take + 0.20))
		var inner_grip := Vector3(-side * PLATE_GRIP.x, PLATE_GRIP.y, PLATE_GRIP.z)
		var outer_grip := Vector3(side * PLATE_GRIP.x, PLATE_GRIP.y, PLATE_GRIP.z)
		buyer.aim_hand(primary, origin + plate_at + inner_grip, receive)
		buyer.aim_hand(secondary, origin + plate_at + outer_grip, receive)
		var held: Vector3 = buyer.bone_world("hand_" + primary) - origin - inner_grip
		plate.position = plate_at.lerp(held, receive)
		var serve := Motion.smooth(Motion.seg(t, take - 0.39, take - 0.12))
		serve *= 1.0 - Motion.smooth(Motion.seg(t, take, take + 0.27))
		host.aim_hand("r" if i == 0 else "l", origin + plate_at + Vector3(0, -0.025, -0.10), serve)
	var focus_shift := Motion.smooth(Motion.seg(t, float(p["arrivals"][1]) - 0.12, float(p["payments"][1])))
	var push := Motion.smooth(Motion.seg(t, float(gag["t"]), float(p["slices"][1]) + 0.25))
	var camera := Vector3(-0.62, 2.07, 5.28).lerp(Vector3(0.69, 2.04, 4.88), focus_shift)
	camera.z -= 0.23 * push
	var focus := Vector3(-0.15, 1.37, 0.21).lerp(Vector3(0.14, 1.37, 0.21), focus_shift)
	return {"camera": origin + camera, "focus": origin + focus}
