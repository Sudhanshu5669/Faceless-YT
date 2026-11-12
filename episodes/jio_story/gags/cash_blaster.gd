## Mukesh intercepts the bidder in the exit corridor with a handheld cash blaster.
extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")
const SHOT_TARGET := Vector3(0.19, 0.88, 0.43)
const MUZZLE := Vector3(0, 0.11, 0.30)
const BUNDLE_LANDINGS := [Vector3(-0.28, 0.49, 0.70), Vector3(0.47, 0.57, 0.77),
	Vector3(0.53, 0.39, 0.31)]


func build(_gag: Dictionary) -> Node3D:
	var lobby := Node3D.new()
	_dress_exit(lobby)
	lobby.add_child(_blaster())
	for index in BUNDLE_LANDINGS.size():
		var bundle := Reveals.shape_node("cash", 0.24, Color("75a36a"))
		bundle.name = "bundle_%d" % index
		bundle.hide()
		lobby.add_child(bundle)
	return lobby


func _dress_exit(lobby: Node3D) -> void:
	var concrete := Kit.mat("4e6268")
	var jamb := Kit.mat("788986", 0.50, 0.30)
	var wood := Kit.mat("5f4133")
	var shadow := Kit.mat("182a33")
	Kit.add_box(lobby, Vector3(5.9, 2.65, 0.12), Vector3(0, 1.325, -2.52), shadow)
	for side in [-1.0, 1.0]:
		var x: float = side * 1.92 + 0.32
		Kit.add_box(lobby, Vector3(2.20, 2.75, 0.22), Vector3(x, 1.375, -1.86), concrete)
		Kit.add_box(lobby, Vector3(2.20, 0.11, 0.08), Vector3(x, 0.075, -1.71), wood)
		Kit.add_box(lobby, Vector3(2.19, 0.042, 0.047), Vector3(x, 0.98, -1.72), jamb)
	Kit.add_box(lobby, Vector3(5.9, 0.48, 0.24), Vector3(0, 2.53, -1.86), concrete)
	var frame := KitDB.static_node("quaternius_downtown/DoorFrame_Metal_Single", 0.78)
	frame.position = Vector3(0.32, 0.0, -1.79)
	lobby.add_child(frame)
	var door := KitDB.static_node("quaternius_downtown/Door_3", 0.86)
	door.position = Vector3(0.83, 0.02, -2.19)
	door.rotation_degrees.y = -68
	lobby.add_child(door)
	Kit.add_box(lobby, Vector3(1.37, 0.02, 0.36), Vector3(0.32, 0.014, -1.71), jamb)
	Kit.add_box(lobby, Vector3(0.77, 0.19, 0.037), Vector3(0.32, 2.53, -1.704), Kit.mat("225544"))
	_text(lobby, "EXIT", 0.105, "dcf8e5", Vector3(0.32, 2.534, -1.678))
	Kit.add_box(lobby, Vector3(1.05, 0.25, 0.035), Vector3(-1.17, 1.68, -1.722), wood)
	_text(lobby, "SPECTRUM AUCTION", 0.078, "f1d9af", Vector3(-1.17, 1.678, -1.697))
	var planter := KitDB.static_node("quaternius_downtown/Prop_Planter_Single", 0.36)
	planter.position = Vector3(1.42, 0, -1.32)
	lobby.add_child(planter)
	_light(lobby, Vector3(0.25, 1.51, -2.16), "77c8df", 1.45, 2.20)
	_light(lobby, Vector3(-1.02, 1.91, 0.61), "ffbe76", 1.40, 3.55)


func _blaster() -> Node3D:
	var gun := Node3D.new()
	gun.name = "gun"
	var shell := Kit.mat("9f352b", 0.44)
	var trim := Kit.mat("f1aa52", 0.32, 0.35)
	var grip := Kit.mat("293138", 0.66)
	var slots := Kit.mat("171e24", 0.48)
	Kit.add_box(gun, Vector3(0.225, 0.21, 0.44), Vector3(0, 0.11, 0.045), shell)
	Kit.add_box(gun, Vector3(0.24, 0.032, 0.43), Vector3(0, 0.224, 0.048), trim)
	Kit.add_box(gun, Vector3(0.234, 0.17, 0.045), Vector3(0, 0.111, 0.267), trim)
	Kit.add_box(gun, Vector3(0.178, 0.060, 0.012), Vector3(0, 0.111, 0.294), slots)
	var handle := Kit.add_box(gun, Vector3(0.10, 0.23, 0.11), Vector3(0, -0.096, -0.062), grip)
	handle.rotation_degrees.x = -15
	Kit.add_box(gun, Vector3(0.113, 0.027, 0.115), Vector3(0, -0.208, -0.089), shell)
	Kit.add_box(gun, Vector3(0.15, 0.045, 0.16), Vector3(0, -0.046, 0.14), grip)
	for side in [-1.0, 1.0]:
		for index in 3:
			Kit.add_box(gun, Vector3(0.008, 0.079, 0.023),
				Vector3(side * 0.115, 0.120, 0.06 + index * 0.042), trim)
	var note := Kit.mat("a8c793", 0.68)
	for index in 3:
		Kit.add_box(gun, Vector3(0.129, 0.006, 0.19),
			Vector3(0, 0.244 + index * 0.006, -0.073 - index * 0.008), note)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color("ffe2a4")
	glow.emission_enabled = true
	glow.emission = Color("ffd690")
	glow.emission_energy_multiplier = 2.2
	var flash := Kit.add_mesh(gun, Kit.sphere(0.096, 0.19, glow), MUZZLE + Vector3(0, 0, 0.038),
		Vector3.ZERO, "flash", false)
	flash.hide()
	return gun


func _text(root: Node3D, value: String, size: float, color: String, at: Vector3) -> void:
	var label := Reveals.text_node(value, size, Color(color))
	(label.material_override as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	label.position = at
	root.add_child(label)


func _light(root: Node3D, at: Vector3, color: String, energy: float, reach: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = at
	lamp.light_color = Color(color)
	lamp.light_energy = energy
	lamp.omni_range = reach
	root.add_child(lamp)


func pose(lobby: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var fire := float(p["fire"])
	var start := float(gag["t"])
	var origin: Vector3 = ctx["holder"].position
	var mukesh = ctx["actor"].call("cash_mukesh")
	var bidder = ctx["actor"].call("leaving_bidder")
	var gun := lobby.get_node("gun") as Node3D
	_pose_blaster(gun, mukesh, origin, fire, t)
	var muzzle := gun.position + gun.basis * MUZZLE
	_pose_bundles(lobby, muzzle, t - fire)
	_pose_bidder(bidder, fire, t)
	var push := Motion.smooth(Motion.seg(t, fire - 0.22, float(p["end"])))
	var drift := Motion.smooth(Motion.seg(t, start, fire))
	var camera := Vector3(0.63, 1.63, 4.13).lerp(Vector3(0.34, 1.43, 3.49), push)
	camera.x -= 0.13 * drift
	var focus := Vector3(-0.05, 1.14, -0.04).lerp(Vector3(0.02, 0.97, 0.19), push)
	return {"muzzle": origin + muzzle,
		"camera": origin + camera, "focus": origin + focus}


func _pose_blaster(gun: Node3D, actor, origin: Vector3, fire: float, t: float) -> void:
	var brace := Motion.smooth(Motion.seg(t, fire - 0.45, fire - 0.15))
	var aim := Motion.out_cubic(Motion.seg(t, fire - 0.17, fire))
	var kick := 0.0
	for offset in [0.0, 0.13, 0.26, 0.39]:
		var age := t - fire - float(offset)
		if age >= 0.0:
			kick = maxf(kick, maxf(0.0, Motion.wobble(age, 4.5, 15.0)))
	var hold := Motion.arc(Vector3(-0.45, 0.60, -0.48), Vector3(-0.38, 0.74, -0.43), 0.044, brace)
	hold = hold.lerp(Vector3(-0.31, 0.77, -0.35), aim)
	var forward := (SHOT_TARGET - hold).normalized()
	gun.basis = Basis.looking_at(forward, Vector3.UP, true).rotated(Vector3.RIGHT, -0.09 * kick)
	actor.aim_hand("r", origin + hold - forward * (0.081 * kick), 1.0, 0.055)
	gun.position = actor.bone_world("hand_r") - origin - gun.basis * Vector3(0, -0.089, -0.059)
	actor.aim_hand("l", origin + gun.position + gun.basis * Vector3(0, -0.043, 0.15), 1.0, 0.064)
	var flash := gun.get_node("flash") as Node3D
	var first_flash := t - fire
	flash.visible = first_flash >= 0.0 and first_flash < 0.066
	flash.scale = Vector3.ONE * (1.0 - Motion.seg(first_flash, 0.0, 0.066))


func _pose_bundles(lobby: Node3D, muzzle: Vector3, age: float) -> void:
	for index in BUNDLE_LANDINGS.size():
		var bundle := lobby.get_node("bundle_%d" % index) as Node3D
		var launch := 0.39 + 0.068 * index
		var arrival := launch + 0.36
		var flight := Motion.seg(age, launch, arrival)
		bundle.visible = age >= launch
		bundle.position = Motion.arc(muzzle, BUNDLE_LANDINGS[index], 0.29 + 0.026 * index, flight)
		bundle.position.y += 0.021 * maxf(0.0, Motion.wobble(age - arrival, 4.5, 12.0))
		bundle.rotation = Vector3(lerpf(-0.44, TAU, flight), (index - 1) * 0.55, 0.12 * index)


func _pose_bidder(actor, fire: float, t: float) -> void:
	var hit := fire + 0.25
	var flinch := Motion.smooth(Motion.seg(t, hit - 0.09, hit + 0.10))
	var bury := Motion.smooth(Motion.seg(t, hit + 0.12, hit + 0.54))
	var settle := Motion.smooth(Motion.seg(t, hit + 0.30, hit + 0.76))
	actor.body.position.y += -0.23 * bury + 0.037 * settle
	actor.body.rotation.x = 0.14 * flinch * (1.0 - 0.78 * settle)
	var hands := flinch * (1.0 - bury)
	var head: Vector3 = actor.anchor_points()[actor.actor_id + ".head"]["pos"]
	actor.aim_hand("l", head + Vector3(0.28, -0.22, 0.17), hands)
	actor.aim_hand("r", head + Vector3(-0.25, -0.24, 0.19), hands)
