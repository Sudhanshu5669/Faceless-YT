## A paper bill runs out of a tiny startup office bolted onto a giant refinery.
extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")
const DECK := 0.77
const SLOT := Vector3(0.31, 1.455, 1.078)
const PAPER_WIDTH := 0.587
const PAPER_SEGMENTS := 42
const ITEM_LINES := 26


func build(_gag: Dictionary) -> Node3D:
	var complex := Node3D.new()
	_build_refinery(complex)
	_build_garage(complex)
	_build_printer(complex)
	var paper := MeshInstance3D.new()
	paper.name = "paper"
	paper.mesh = ImmediateMesh.new()
	var stock := _ink("e8e0c8")
	stock.cull_mode = BaseMaterial3D.CULL_DISABLED
	paper.material_override = stock
	paper.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	complex.add_child(paper)
	var total := _label(complex, "₹1,50,000 crore", 0.070, "262c2e", Vector3.ZERO)
	total.name = "total"
	var heading := _label(complex, "NETWORK BUILDOUT", 0.041, "58616a", Vector3.ZERO)
	heading.name = "heading"
	var ink := _ink("89938f")
	for index in ITEM_LINES:
		var line := Kit.add_box(complex, Vector3(0.24 + 0.036 * (index % 5), 0.011, 0.003),
			Vector3.ZERO, ink, 0, "ink_%d" % index, false)
		line.hide()
	return complex


func _build_refinery(complex: Node3D) -> void:
	var refinery := Reveals.shape_node("refinery", 5.55, Color("818b91"))
	refinery.position = Vector3(-0.24, 0.0, -1.08)
	complex.add_child(refinery)
	var base := Kit.mat("48515d")
	var metal := Kit.mat("748b94", 0.45, 0.51)
	var dark := Kit.mat("3e515a", 0.56, 0.41)
	var paint := Kit.mat("ae8652", 0.63)
	Kit.add_box(complex, Vector3(5.75, 0.19, 3.31), Vector3(-0.30, 0.089, -1.12), base)
	for x in [-2.39, 2.31]:
		Kit.add_box(complex, Vector3(0.19, 0.085, 2.82), Vector3(x, 0.16, -0.96), paint)
	for height in [1.92, 3.08, 3.64]:
		var a := Vector3(-1.34, height, -0.30)
		var b := Vector3(1.90, height, -0.30)
		_pipe(complex, a, b, 0.087 if height == 3.08 else 0.114, metal)
		_pipe(complex, a, a + Vector3(0, 0.70, 0), 0.106, metal)
		for x in [-1.24, -0.48, 0.46, 1.32, 1.79]:
			var clamp_ring := Kit.add_mesh(complex, Kit.cylinder(0.135, 0.135, 0.048, dark, 16),
				Vector3(x, height, -0.30))
			clamp_ring.rotation_degrees.z = 90
	for x in [-1.70, 0.56]:
		Kit.add_box(complex, Vector3(1.12, 0.075, 0.34), Vector3(x, 3.20, 0.019), dark)
		for offset in [-0.49, 0.0, 0.49]:
			_pipe(complex, Vector3(x + offset, 3.20, 0.16), Vector3(x + offset, 3.49, 0.16), 0.024, paint)
		_pipe(complex, Vector3(x - 0.50, 3.48, 0.16), Vector3(x + 0.50, 3.48, 0.16), 0.022, paint)
	_prop(complex, "quaternius_fantasy_props/Crate_Metal", Vector3(1.93, 0.19, -0.04), 0.65, 8)
	_prop(complex, "quaternius_downtown/Building_Small_1", Vector3(5.0, 0.0, -9.6), 0.39, 0)
	_prop(complex, "quaternius_nature/PalmTree_2", Vector3(-4.52, 0, -4.48), 1.08, 17)
	_light(complex, Vector3(-1.83, 4.49, 2.84), "f4a76f", 2.3, 8.0)
	_light(complex, Vector3(2.53, 5.08, -2.28), "87bdf8", 2.8, 7.6)


func _build_garage(complex: Node3D) -> void:
	var trim := Kit.mat("475763", 0.52, 0.49)
	var siding := Kit.mat("748587", 0.67, 0.25)
	var wood := Kit.mat("83664b")
	var bolt := Kit.mat("b1a28b", 0.43, 0.48)
	Kit.add_box(complex, Vector3(1.75, 0.10, 1.37), Vector3(0.10, DECK - 0.05, 0.48), trim)
	Kit.add_box(complex, Vector3(1.64, 0.036, 1.26), Vector3(0.10, DECK + 0.008, 0.48), wood)
	Kit.add_box(complex, Vector3(1.68, 1.54, 0.085), Vector3(0.10, 1.53, -0.137), siding)
	for side in [-1.0, 1.0]:
		var x: float = 0.10 + side * 0.806
		Kit.add_box(complex, Vector3(0.086, 1.52, 1.24), Vector3(x, 1.53, 0.49), siding)
		Kit.add_box(complex, Vector3(0.085, 1.57, 0.084), Vector3(x, 1.55, 1.11), trim)
		Kit.add_box(complex, Vector3(0.18, 0.43, 0.091), Vector3(x, DECK - 0.21, -0.12), trim)
		_pipe(complex, Vector3(x, DECK - 0.46, -0.09), Vector3(x, DECK - 0.09, 0.98), 0.058, trim)
		for y in [DECK - 0.36, DECK - 0.14]:
			Kit.add_mesh(complex, Kit.cylinder(0.045, 0.045, 0.021, bolt, 8),
				Vector3(x, y, -0.062), Vector3(90, 0, 0))
	Kit.add_box(complex, Vector3(1.86, 0.098, 1.46), Vector3(0.10, 2.34, 0.50), trim)
	for ridge in 11:
		Kit.add_box(complex, Vector3(0.039, 0.021, 1.42),
			Vector3(-0.73 + ridge * 0.165, 2.40, 0.50), siding, 0, "", false)
	Kit.add_box(complex, Vector3(1.55, 0.166, 0.085), Vector3(0.10, 2.244, 1.115), siding)
	for index in 4:
		Kit.add_box(complex, Vector3(1.53, 0.016, 0.023), Vector3(0.10, 2.189 + index * 0.036, 1.163), trim)
	Kit.add_box(complex, Vector3(1.12, 0.175, 0.041), Vector3(0.10, 2.22, 1.197), Kit.mat("9b662f"))
	_label(complex, "STARTUP", 0.116, "fff0bc", Vector3(0.10, 2.22, 1.222))
	_prop(complex, "quaternius_fantasy_props/Table_Large", Vector3(0.07, DECK, 0.61), 0.55, 0)
	_prop(complex, "quaternius_fantasy_props/Chair_1", Vector3(-0.19, DECK, 0.14), 0.76, 0)
	var laptop := Reveals.shape_node("laptop", 0.36, Color("3b4a5a"))
	laptop.position = Vector3(-0.30, DECK + 0.447, 0.62)
	laptop.rotation_degrees.y = 166
	var lid := laptop.get_child(1) as MeshInstance3D
	lid.rotation.x = PI * 0.5
	lid.position = Vector3(0, 0.021, 0)
	(laptop.get_child(2) as MeshInstance3D).hide()
	(laptop.get_child(3) as MeshInstance3D).hide()
	complex.add_child(laptop)
	var bulb := _ink("ffc683")
	Kit.add_box(complex, Vector3(0.50, 0.034, 0.063), Vector3(-0.14, 2.211, 0.42), bulb)
	_light(complex, Vector3(-0.20, 2.06, 0.68), "ffd5a3", 1.38, 2.16)


func _build_printer(complex: Node3D) -> void:
	var shell := Kit.mat("68716d", 0.52)
	var lid := Kit.mat("88978e", 0.49)
	var dark := Kit.mat("293439", 0.65)
	Kit.add_box(complex, Vector3(0.650, 0.182, 0.35), SLOT + Vector3(0, -0.137, -0.187), shell)
	Kit.add_box(complex, Vector3(0.651, 0.078, 0.328), SLOT + Vector3(0, -0.021, -0.185), lid)
	Kit.add_box(complex, Vector3(0.594, 0.029, 0.013), SLOT + Vector3(0, 0.0, -0.010), dark)
	for index in 6:
		Kit.add_box(complex, Vector3(0.043, 0.005, 0.071),
			SLOT + Vector3(-0.23 + index * 0.064, 0.021, -0.19), dark)
	var button := Kit.add_mesh(complex, Kit.cylinder(0.039, 0.039, 0.017, _ink("e7ad67"), 20),
		SLOT + Vector3(-0.246, 0.024, -0.097), Vector3.ZERO, "button")
	button.material_override = _ink("e7ad67")
	Kit.add_mesh(complex, Kit.sphere(0.012, 0.024, _ink("90d8a5")),
		SLOT + Vector3(-0.173, 0.027, -0.096))


func _pipe(root: Node3D, a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	var delta := b - a
	var mesh := Kit.add_mesh(root, Kit.cylinder(radius, radius, delta.length(), material, 16), (a + b) * 0.5)
	mesh.quaternion = Quaternion(Vector3.UP, delta.normalized())


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


func _prop(root: Node3D, id: String, at: Vector3, scale: float, yaw: float) -> void:
	var prop := KitDB.static_node(id, scale)
	prop.position = at
	prop.rotation_degrees.y = yaw
	root.add_child(prop)


func _light(root: Node3D, at: Vector3, color: String, energy: float, reach: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = at
	lamp.light_color = Color(color)
	lamp.light_energy = energy
	lamp.omni_range = reach
	root.add_child(lamp)


func pose(complex: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var bill := float(p["bill"])
	var total := float(p["total"])
	var pull_at := float(p["pull"])
	var payoff := float(p["startup"])
	var origin: Vector3 = ctx["holder"].position
	_pose_founder(complex, ctx["actor"].call("startup_mukesh"), origin, bill, payoff, t)
	_pose_receipt(complex, bill, total, payoff, t)
	var pull := Motion.smooth(Motion.seg(t, pull_at - 0.09, payoff + 0.18))
	var glance := Motion.smooth(Motion.seg(t, bill, total))
	var camera := Vector3(0.65, 1.57, 2.50).lerp(Vector3(1.48, 3.26, 9.93), pull)
	var focus := Vector3(0.22, 1.32, 1.02).lerp(Vector3(0.25, 1.24, 1.11), glance)
	focus = focus.lerp(Vector3(0.02, 3.53, -0.17), pull)
	return {"camera": origin + camera, "focus": origin + focus}


func _pose_founder(complex: Node3D, actor, origin: Vector3, bill: float, payoff: float, t: float) -> void:
	actor.body.position.y += DECK
	var press := Motion.smooth(Motion.seg(t, bill - 0.23, bill)) * (1.0 - Motion.smooth(Motion.seg(t, bill + 0.045, bill + 0.29)))
	var tap := SLOT + Vector3(-0.246, 0.032, -0.097)
	var work := Vector3(-0.07, DECK + 0.475, 0.59)
	var lift := Motion.smooth(Motion.seg(t, payoff - 0.29, payoff))
	var hand := Motion.arc(work, tap, 0.024, press)
	hand = Motion.arc(hand, Vector3(0.01, DECK + 0.66, 0.49), 0.039, lift)
	actor.aim_hand("l", origin + hand, 1.0, 0.05)
	var button := complex.get_node("button") as Node3D
	button.position.y = SLOT.y + 0.024 - press * 0.012


func _length(t: float, bill: float, payoff: float) -> float:
	var run := Motion.seg(t, bill, payoff + 0.36)
	return 0.038 + 2.12 * run


func _paper_point(d: float, age: float) -> Vector3:
	var drop := minf(d, 1.41)
	var floor_run := maxf(d - 1.41, 0.0)
	var flutter := 0.014 * sin(d * 19.0 - age * 11.0) * smoothstep(0.03, 0.22, d)
	return SLOT + Vector3(0, -drop + flutter * (1.0 - minf(1.0, floor_run * 6.0)),
		0.205 * (1.0 - exp(-6.0 * d)) + floor_run * 0.83)


func _pose_receipt(complex: Node3D, bill: float, total: float, payoff: float, t: float) -> void:
	var length := _length(t, bill, payoff)
	var age := t - bill
	var paper := (complex.get_node("paper") as MeshInstance3D).mesh as ImmediateMesh
	paper.clear_surfaces()
	paper.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for index in PAPER_SEGMENTS + 1:
		var at := _paper_point(length * float(index) / PAPER_SEGMENTS, age)
		paper.surface_add_vertex(at - Vector3.RIGHT * (PAPER_WIDTH * 0.5))
		paper.surface_add_vertex(at + Vector3.RIGHT * (PAPER_WIDTH * 0.5))
	paper.surface_end()

	var printed := _length(total, bill, payoff) - 0.066
	var total_line := complex.get_node("total") as Node3D
	_pose_ink(total_line, length - printed, length, age, 0.056)
	var heading := complex.get_node("heading") as Node3D
	_pose_ink(heading, length - printed - 0.064, length, age, 0.026)
	for index in ITEM_LINES:
		var line := complex.get_node("ink_%d" % index) as Node3D
		var offset := 0.058 + index * 0.076
		var distance := length - offset
		_pose_ink(line, distance, length, age, 0.013)
		line.visible = line.visible and absf(offset - printed) > 0.17
		line.position.x -= 0.057 if index % 2 == 0 else -0.045


func _pose_ink(item: Node3D, distance: float, length: float, age: float, margin: float) -> void:
	item.visible = distance > margin and distance < length - margin
	var d := clampf(distance, 0.0, length)
	var at := _paper_point(d, age)
	var down := (_paper_point(d + 0.015, age) - _paper_point(d - 0.015, age)).normalized()
	var right := Vector3.RIGHT
	var normal := right.cross(-down)
	item.transform = Transform3D(Basis(right, -down, normal), at + normal * 0.006)
