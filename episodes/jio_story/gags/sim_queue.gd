extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")

const CONTACT := Vector3(-0.06, 0.99, 0.26)
const SIM_TRAY := Vector3(-0.25, 0.78, 0.04)


func build(_gag: Dictionary) -> Node3D:
	var store := Node3D.new()
	_build_storefront(store)
	_build_pavement(store)
	for index in 4:
		var card := _sim_card()
		card.position = SIM_TRAY + Vector3(0.015 * index, 0.007 * index, -0.010 * index)
		store.add_child(card)
	var sim := _sim_card()
	sim.name = "handoff_sim"
	store.add_child(sim)
	return store


func _build_storefront(store: Node3D) -> void:
	var concrete := Kit.mat("5c5554", 0.86)
	var trim := Kit.mat("182031", 0.38, 0.32)
	var blue := Kit.mat("264389", 0.51)
	var plaster := Kit.mat("675052", 0.80)
	var window := Kit.mat("17202e", 0.25, 0.40)
	var led := Kit.glow_mat("9fc9ff", 0.60)
	var warm := Kit.glow_mat("ffe4b9", 0.55)
	# A corner branch with a recessed interior and a service counter at its entrance.
	Kit.add_box(store, Vector3(3.8, 4.0, 0.16), Vector3(-0.31, 2.0, -3.65), plaster)
	for x in [-2.22, 1.60]:
		Kit.add_box(store, Vector3(0.16, 4.0, 2.85), Vector3(x, 2.0, -2.30), concrete)
		Kit.add_box(store, Vector3(0.23, 2.39, 0.24), Vector3(x, 1.195, -0.91), trim)
	Kit.add_box(store, Vector3(3.98, 1.60, 0.23), Vector3(-0.31, 3.17, -0.91), plaster)
	Kit.add_box(store, Vector3(3.99, 0.16, 2.95), Vector3(-0.31, 2.39, -2.30), concrete)
	Kit.add_box(store, Vector3(4.13, 0.43, 0.43), Vector3(-0.31, 2.36, -0.76), blue)
	Kit.add_box(store, Vector3(4.12, 0.026, 0.18), Vector3(-0.31, 2.13, -0.64), led, 0, "", false)
	_label(store, "Reliance Digital Express", 0.18, Vector3(-0.14, 2.36, -0.532), "eef5ff")
	Kit.add_box(store, Vector3(1.36, 1.9, 0.04), Vector3(-1.38, 1.13, -0.93), window)
	for height in [0.36, 0.91, 1.45, 2.08]:
		Kit.add_box(store, Vector3(1.36, 0.027, 0.12), Vector3(-1.38, height, -0.87), trim)
	for x in [-2.07, -1.38, -0.70, 0.87]:
		Kit.add_box(store, Vector3(0.034, 2.07, 0.055), Vector3(x, 1.06, -0.86), trim)
	Kit.add_box(store, Vector3(0.59, 0.84, 0.033), Vector3(-1.38, 1.19, -0.887), blue)
	Kit.add_mesh(store, Kit.cylinder(0.22, 0.22, 0.018, Kit.glow_mat("2457d1", 0.7), 40),
		Vector3(-1.38, 1.29, -0.86), Vector3(90, 0, 0), "", false)
	_label(store, "Jio", 0.20, Vector3(-1.38, 1.30, -0.84), "ffffff")
	_label(store, "WELCOME OFFER", 0.067, Vector3(-1.38, 0.97, -0.86), "eef5ff")
	# The counter is rolled out to the threshold for the launch queue.
	Kit.add_box(store, Vector3(1.15, 0.65, 0.36), Vector3(-0.32, 0.325, 0.11), blue)
	Kit.add_box(store, Vector3(1.22, 0.07, 0.42), Vector3(-0.32, 0.685, 0.11), trim)
	Kit.add_box(store, Vector3(0.28, 0.022, 0.20), SIM_TRAY - Vector3(0, 0.035, 0), trim)
	_label(store, "SIM PICKUP", 0.085, Vector3(-0.37, 0.51, 0.295), "dfeaff")
	for x in [-1.49, -0.30, 0.82]:
		Kit.add_box(store, Vector3(0.45, 0.022, 0.07), Vector3(x, 2.26, -1.40), warm)
	_omni(store, Vector3(-0.12, 2.01, -0.90), "ffcf99", 2.2, 4.5)
	_omni(store, Vector3(-0.36, 1.97, 1.63), "d4e6ff", 1.8, 4.0)
	_omni(store, Vector3(2.77, 2.35, 0.10), "ffcb90", 1.8, 6.6)
	_omni(store, Vector3(2.02, 1.53, -3.07), "74a8ff", 1.4, 5.0)
	# Upper-floor balcony extends the building above the retail frontage.
	Kit.add_box(store, Vector3(3.42, 0.11, 0.64), Vector3(-0.34, 3.32, -0.78), concrete)
	for x in [-1.45, -0.31, 0.83]:
		Kit.add_box(store, Vector3(0.65, 0.46, 0.015), Vector3(x, 3.63, -0.786), window)
		Kit.add_box(store, Vector3(0.025, 0.46, 0.018), Vector3(x, 3.63, -0.77), trim)
	for index in 14:
		Kit.add_box(store, Vector3(0.022, 0.36, 0.026), Vector3(-1.95 + index * 0.25, 3.52, -0.45), trim)
	Kit.add_box(store, Vector3(3.36, 0.036, 0.04), Vector3(-0.32, 3.71, -0.45), trim)


func _build_pavement(store: Node3D) -> void:
	var paving := Kit.mat("65626c", 0.84)
	var seam := Kit.mat("45434c", 0.92)
	Kit.add_box(store, Vector3(7.1, 0.12, 8.8), Vector3(0.72, -0.061, -0.28), paving)
	Kit.add_box(store, Vector3(7.1, 0.14, 0.16), Vector3(0.72, -0.065, 4.14), seam)
	for row in 12:
		Kit.add_box(store, Vector3(7.1, 0.002, 0.012),
			Vector3(0.72, 0.001, -4.5 + row * 0.77), seam, 0, "", false)
	for col in 10:
		Kit.add_box(store, Vector3(0.012, 0.002, 8.8),
			Vector3(-2.73 + col * 0.76, 0.002, -0.28), seam, 0, "", false)
	var bollard := "quaternius_downtown/Prop_Bollard"
	for pos in [Vector3(0.03, 0, 2.36), Vector3(1.45, 0, 3.70), Vector3(3.1, 0, 3.83),
			Vector3(4.04, 0, 2.35), Vector3(4.03, 0, 0.70), Vector3(3.91, 0, -1.15)]:
		_place(store, bollard, 0.84, pos)
	_place(store, "kenney_suburban/planter", 1.9, Vector3(-1.93, 0, -0.47))
	_place(store, "kenney_suburban/planter", 1.9, Vector3(1.72, 0, -0.68))


func pose(store: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var join := float(gag["params"]["join"])
	var wide := float(gag["params"]["wide"])
	var pull := Motion.smooth(Motion.seg(t, join + 0.14, wide + 0.28))
	var origin: Vector3 = ctx["holder"].position
	var clerk = ctx["actor"].call("sim_clerk")
	var customer = ctx["actor"].call("sim_customer")
	var wind := Motion.smooth(Motion.seg(t, join - 0.72, join - 0.24))
	var reach := Motion.in_out(Motion.seg(t, join - 0.24, join))
	var release := Motion.out_cubic(Motion.seg(t, join, join + 0.39))
	var clerk_hand := Motion.arc(SIM_TRAY, CONTACT, 0.11, reach)
	var customer_hand := Motion.arc(Vector3(0.22, 0.74, 0.46), CONTACT, 0.04, reach)
	var turn := Motion.smooth(Motion.seg(t, join + 0.25, join + 0.75))
	var show := Vector3(0.09, 1.02, 0.69).lerp(Vector3(0.50, 1.08, 0.83), turn)
	customer_hand = Motion.arc(customer_hand, show, 0.08, release)
	clerk.aim_hand("l", origin + clerk_hand, wind * (1.0 - release))
	customer.aim_hand("l", origin + customer_hand, wind)
	var sim := store.get_node("handoff_sim") as Node3D
	# The same card travels from the tray to the clerk's palm and across to the customer.
	var clerk_palm: Vector3 = clerk.bone_world("hand_l") - origin
	var customer_palm: Vector3 = customer.bone_world("hand_l") - origin
	var pickup := Motion.smooth(Motion.seg(t, join - 0.50, join - 0.29))
	var handoff := Motion.smooth(Motion.seg(t, join - 0.055, join + 0.07))
	sim.position = SIM_TRAY.lerp(clerk_palm + Vector3(0, 0.014, 0), pickup)
	sim.position = sim.position.lerp(customer_palm + Vector3(0, 0.022, 0.013), handoff)
	sim.rotation.x = lerpf(0.0, PI * 0.44, maxf(reach * 0.65, release))
	sim.rotation.y = -0.42 * (1.0 - pull)
	sim.rotation.z = 0.16 * Motion.wobble(t - join, 4.0, 9.0)

	# Keep the shop sign and the counter in view as the camera tracks the queue around the corner.
	var approach := Motion.smooth(Motion.seg(t, join - 1.30, join))
	var camera := Vector3(-1.90, 1.67, 3.10).lerp(Vector3(-2.03, 1.65, 2.98), approach)
	camera = camera.lerp(Vector3(2.9, 4.48, 7.15), pull)
	var focus := Vector3(0.03, 1.76, 0.00).lerp(Vector3(1.48, 1.30, 0.08), pull)
	return {"camera": origin + camera, "focus": origin + focus}


func _place(root: Node3D, id: String, scale: float, at: Vector3) -> void:
	var prop := KitDB.static_node(id, scale)
	if prop != null:
		prop.position = at
		root.add_child(prop)


func _label(root: Node3D, title: String, height: float, at: Vector3, color: String) -> void:
	var text := Reveals.text_node(title, height, Color(color))
	text.position = at
	root.add_child(text)


func _sim_card() -> Node3D:
	var sim := Node3D.new()
	var blue := Kit.mat("2457d1", 0.38)
	var gold := Kit.mat("e0b54a", 0.35, 0.40)
	var contact_gap := Kit.mat("6b4d2b", 0.60)
	Kit.add_box(sim, Vector3(0.18, 0.007, 0.114), Vector3.ZERO, Kit.mat("f4f6fb", 0.55))
	Kit.add_box(sim, Vector3(0.18, 0.004, 0.029), Vector3(0, 0.004, -0.043), blue)
	Kit.add_box(sim, Vector3(0.046, 0.005, 0.036), Vector3(-0.038, 0.005, 0.012), gold)
	for z in [0.003, 0.016, 0.025]:
		Kit.add_box(sim, Vector3(0.044, 0.001, 0.0014), Vector3(-0.038, 0.008, z), contact_gap)
	Kit.add_mesh(sim, Kit.cylinder(0.022, 0.022, 0.003, blue, 24), Vector3(0.047, 0.006, 0.010))
	return sim


func _omni(root: Node3D, at: Vector3, color: String, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = Color(color)
	light.light_energy = energy
	light.omni_range = reach
	root.add_child(light)
