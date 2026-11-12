## The telecom kings toast from heaps of gold while their captive tower rattles its cage.
extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")

const FANTASY := "quaternius_fantasy_props/"
const CARRIERS := ["airtel", "vodafone", "idea"]
const VELVET := ["8b253d", "ad3529", "a37b23"]
const SEATS := [Vector3(-0.91, 0, -0.05), Vector3(0, 0, 0.26), Vector3(0.91, 0, -0.05)]
const CAGE_HOOK := Vector3(0.0, 4.62, -0.10)
const CAGE_DROP := 2.38
const TOSSED_COINS := 6


func build(gag: Dictionary) -> Node3D:
	var court := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(gag["id"]))
	_dress_hall(court)
	for index in CARRIERS.size():
		var table := Node3D.new()
		table.name = CARRIERS[index]
		court.add_child(table)
		_throne(table, index)
		_pile(table, index, rng)
		var crown := Reveals.shape_node("crown", 0.66, Color("dfa935"))
		crown.name = "crown"
		table.add_child(crown)
		table.add_child(_goblet())
		for coin_index in TOSSED_COINS:
			var coin := _coin_prop("Coin", 1.22, _gold(coin_index))
			coin.name = "coin_%d" % coin_index
			coin.hide()
			table.add_child(coin)
	court.add_child(_cage())
	return court


func _dress_hall(court: Node3D) -> void:
	var walnut := Kit.mat("3a2430")
	var stone := Kit.mat("67483e")
	var gold := Kit.mat("b58748", 0.42, 0.43)
	Kit.add_box(court, Vector3(8.1, 0.16, 5.6), Vector3(0, 4.70, -1.12), walnut)
	for z in [-3.02, -1.84, -0.10, 1.34]:
		Kit.add_box(court, Vector3(8.1, 0.13, 0.19), Vector3(0, 4.57, z), stone)
	Kit.add_box(court, Vector3(3.54, 0.14, 2.37), Vector3(0, 0.06, 0.08), walnut)
	Kit.add_box(court, Vector3(3.61, 0.035, 0.045), Vector3(0, 0.11, 1.29), gold)
	Kit.add_box(court, Vector3(2.65, 0.045, 1.04), Vector3(0, 0.018, 1.82), Kit.mat("562534"))
	for side in [-1.0, 1.0]:
		var x: float = side * 2.26
		Kit.add_box(court, Vector3(0.58, 0.22, 0.61), Vector3(x, 0.11, -1.83), stone)
		_cylinder(court, Vector3(x, 2.50, -1.83), 0.20, 0.23, 4.6, stone)
		for y in [0.29, 0.49, 3.89, 4.54]:
			_cylinder(court, Vector3(x, y, -1.83), 0.255, 0.255, 0.076, gold)
		var lantern := KitDB.static_node(FANTASY + "Lantern_Wall", 0.43)
		lantern.position = Vector3(side * 2.05, 1.98, -1.65)
		lantern.rotation_degrees.y = 90.0 * side
		court.add_child(lantern)
		_light(court, Vector3(side * 2.0, 2.29, -1.20), "ffb95f", 1.05, 3.2)
	_light(court, Vector3(0.20, 1.85, 1.95), "ffd28a", 1.1, 5.0)


func _throne(group: Node3D, index: int) -> void:
	var seat: Vector3 = SEATS[index]
	var wood := KitDB.static_node(FANTASY + "Chair_1", 1.02)
	wood.position = seat + Vector3(0, 0.12, -0.05)
	group.add_child(wood)
	var trim := Kit.mat("ac7833", 0.33, 0.55)
	var fabric := Kit.mat(VELVET[index], 0.88)
	Kit.add_box(group, Vector3(0.64, 0.97, 0.10), seat + Vector3(0, 0.91, -0.32), trim)
	Kit.add_box(group, Vector3(0.55, 0.84, 0.08), seat + Vector3(0, 0.89, -0.26), fabric)
	for side in [-1.0, 1.0]:
		var x: float = side * 0.31
		_cylinder(group, seat + Vector3(x, 0.88, -0.31), 0.035, 0.041, 1.12, trim)
		Kit.add_mesh(group, Kit.sphere(0.064, 0.126, trim), seat + Vector3(x, 1.45, -0.31))
	var sign := Vector3(seat.x, 0.25, 1.28)
	Kit.add_box(group, Vector3(0.83, 0.24, 0.045), sign, trim)
	Kit.add_box(group, Vector3(0.77, 0.185, 0.02), sign + Vector3(0, 0, 0.029), fabric)
	_lettering(group, CARRIERS[index].to_upper(), 0.106, "fff0ce", sign + Vector3(0, -0.004, 0.045))


func _gold(index: int) -> StandardMaterial3D:
	const TONES := ["c4812a", "e2a845", "f5c55b", "b9752b"]
	return Kit.mat(TONES[index % TONES.size()], 0.34, 0.48)


func _pile(group: Node3D, index: int, rng: RandomNumberGenerator) -> void:
	var seat: Vector3 = SEATS[index]
	for ring in 4:
		var radius := [0.57, 0.43, 0.28, 0.12][ring] as float
		for slot in 14 - ring * 3:
			var angle := TAU * float(slot) / float(14 - ring * 3) + ring * 0.45
			var pile := _coin_prop("Coin_Pile_2" if slot % 3 else "Coin_Pile",
				rng.randf_range(1.15, 2.0), _gold(slot + ring))
			pile.position = seat + Vector3(cos(angle) * radius, 0.12 + ring * 0.112,
				0.43 + sin(angle) * radius * 0.76)
			pile.rotation_degrees = Vector3(rng.randf_range(-12, 12), rng.randf_range(0, 360), rng.randf_range(-11, 11))
			group.add_child(pile)


func _coin_prop(model: String, size: float, material: Material) -> Node3D:
	var prop := KitDB.static_node(FANTASY + model, size)
	for child in prop.get_children():
		var coin := child as MeshInstance3D
		coin.material_override = material
		coin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return prop


func _goblet() -> Node3D:
	var cup := Node3D.new()
	cup.name = "goblet"
	var gold := Kit.mat("d2a04c", 0.28, 0.61)
	_cylinder(cup, Vector3(0, 0.014, 0), 0.037, 0.043, 0.027, gold)
	_cylinder(cup, Vector3(0, 0.058, 0), 0.012, 0.016, 0.07, gold)
	_cylinder(cup, Vector3(0, 0.121, 0), 0.062, 0.022, 0.094, gold)
	var rim := TorusMesh.new()
	rim.inner_radius = 0.052
	rim.outer_radius = 0.065
	rim.rings = 20
	rim.ring_segments = 8
	rim.material = gold
	Kit.add_mesh(cup, rim, Vector3(0, 0.169, 0))
	_cylinder(cup, Vector3(0, 0.17, 0), 0.052, 0.052, 0.008, Kit.mat("6c142a", 0.24))
	return cup


func _cage() -> Node3D:
	var chain := Node3D.new()
	chain.name = "chain"
	chain.position = CAGE_HOOK
	var steel := Kit.mat("79717e", 0.42, 0.55)
	var link := TorusMesh.new()
	link.inner_radius = 0.029
	link.outer_radius = 0.048
	link.rings = 14
	link.ring_segments = 7
	link.material = steel
	for index in 19:
		var part := Kit.add_mesh(chain, link, Vector3(0, -0.035 - index * 0.079, 0),
			Vector3(90, 90 * (index % 2), 0), "", false)
		part.scale = Vector3(0.78, 1.0, 1.14)
	# The imported cage has a dense grid that hides the captive at Shorts size.
	var cage := _prison_bars()
	cage.position = Vector3(0, -CAGE_DROP, 0)
	chain.add_child(cage)
	var tower := Reveals.shape_node("tower", 0.70, Color("80d5e3"))
	tower.name = "tower"
	tower.position = cage.position + Vector3(0, 0.10, 0.03)
	chain.add_child(tower)
	var plaque := cage.position + Vector3(0, 0.10, 0.53)
	Kit.add_box(chain, Vector3(0.54, 0.153, 0.042), plaque, Kit.mat("68513e", 0.41, 0.39))
	Kit.add_box(chain, Vector3(0.48, 0.112, 0.022), plaque + Vector3(0, 0, 0.025), Kit.mat("213b4a"))
	_lettering(chain, "DATA", 0.097, "e9f7fc", plaque + Vector3(0, -0.004, 0.044))
	_light(chain, cage.position + Vector3(0.0, 0.59, 0.42), "9cddff", 1.25, 2.75)
	return chain


func _prison_bars() -> Node3D:
	var cage := Node3D.new()
	var frame := Kit.mat("53434a", 0.44, 0.51)
	var bars := Kit.mat("6d6670", 0.37, 0.62)
	var brass := Kit.mat("c28b48", 0.40, 0.48)
	for y in [0.046, 0.925]:
		Kit.add_box(cage, Vector3(1.04, 0.092, 0.92), Vector3(0, y, 0), frame)
		Kit.add_box(cage, Vector3(1.065, 0.021, 0.942), Vector3(0, y + 0.026, 0), brass)
	for side in [-1.0, 1.0]:
		var z: float = side * 0.435
		for x in [-0.49, 0.49]:
			_cylinder(cage, Vector3(x, 0.49, z), 0.036, 0.036, 0.88, frame)
		for x in [-0.30, 0.0, 0.30]:
			_cylinder(cage, Vector3(x, 0.49, z), 0.014, 0.014, 0.88, bars)
		for depth in [-0.24, 0.0, 0.24]:
			_cylinder(cage, Vector3(side * 0.49, 0.49, depth), 0.017, 0.017, 0.88, bars)
	# A narrow hinged gate and its brass lock sit in the front plane.
	for y in [0.24, 0.74]:
		Kit.add_box(cage, Vector3(0.07, 0.06, 0.041), Vector3(-0.45, y, 0.466), brass)
	Kit.add_box(cage, Vector3(0.16, 0.045, 0.034), Vector3(0.39, 0.44, 0.468), brass)
	Kit.add_box(cage, Vector3(0.065, 0.083, 0.044), Vector3(0.405, 0.408, 0.50), brass)
	return cage


func _cylinder(root: Node3D, at: Vector3, top: float, bottom: float, height: float, material: Material) -> void:
	Kit.add_mesh(root, Kit.cylinder(top, bottom, height, material, 20), at)


func _lettering(root: Node3D, value: String, size: float, color: String, at: Vector3) -> void:
	var label := Reveals.text_node(value, size, Color(color))
	(label.material_override as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	label.position = at
	root.add_child(label)


func _light(root: Node3D, at: Vector3, color: String, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = Color(color)
	light.light_energy = energy
	light.omni_range = reach
	root.add_child(light)


func pose(court: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var params: Dictionary = gag["params"]
	var origin: Vector3 = ctx["holder"].position
	var age := float(ctx["age"])
	for index in CARRIERS.size():
		var actor = ctx["actor"].call("king_" + CARRIERS[index])
		_pose_king(court.get_node(CARRIERS[index]), actor, origin, index, t, age, params)
	var chain := court.get_node("chain") as Node3D
	var rattle := float(params["rattle"])
	var pull := Motion.smooth(Motion.seg(t, rattle - 0.26, rattle))
	var rebound := Motion.wobble(t - rattle, 1.95, 2.6)
	var swing := pull if t < rattle else rebound
	chain.rotation = Vector3(0.019 * sin(age * 1.9), 0.10 + 0.035 * sin(age * 2.2),
		0.021 * sin(age * 2.75) + swing * 0.076)
	var tower := chain.get_node("tower") as Node3D
	tower.rotation.z = -0.10 * swing
	var move := Motion.smooth(Motion.seg(t, rattle - 0.38, rattle + 0.62))
	var drift := Motion.smooth(Motion.seg(t, float(gag["t"]), float(params["end"])))
	var camera := Vector3(-0.18, 1.65, 5.06).lerp(Vector3(0.47, 3.18, 2.60), move)
	camera.x += 0.17 * drift
	var focus := Vector3(0, 1.55, 0.28).lerp(Vector3(0, 2.87, -0.02), move)
	return {"camera": origin + camera, "focus": origin + focus}


func _pose_king(group: Node3D, actor, origin: Vector3, index: int, t: float, age: float, params: Dictionary) -> void:
	var seat: Vector3 = SEATS[index]
	var toast := float(params["toast"][index])
	var sip := float(params["sip"]) + index * 0.10
	var toss := float(params["money"]) + index * 0.072
	var laugh := Motion.smooth(Motion.seg(t, toast, toast + 0.30))
	var drink := Motion.smooth(Motion.seg(t, sip - 0.32, sip)) * (1.0 - Motion.smooth(Motion.seg(t, sip + 0.12, sip + 0.55)))
	actor.body.position.y += 0.10 + laugh * (1.0 - drink) * 0.025 * sin(age * 15.4 + index * 1.5)
	var head: Vector3 = actor.anchor_points()[actor.actor_id + ".head"]["pos"] - origin
	var crown := group.get_node("crown") as Node3D
	crown.position = head + Vector3(0, 0.205, -0.012)
	crown.rotation = Vector3(-0.08 - drink * 0.12, 0.22 * index, 0.045 * sin(age * 7.3 + index))
	var raise := Motion.out_cubic(Motion.seg(t, toast - 0.11, toast + 0.42))
	var low := seat + Vector3(0.27, 0.63, 0.35)
	var high := head + Vector3(0.25, -0.13, 0.22)
	var grip := Motion.arc(low, high, 0.032, raise).lerp(head + Vector3(0.04, -0.16, 0.29), drink)
	actor.aim_hand("l", origin + grip)
	var cup := group.get_node("goblet") as Node3D
	cup.scale = Vector3.ONE * 1.16
	cup.rotation = Vector3(-0.06 - drink * 0.91, 0.0, 0.10 - drink * 0.07)
	cup.position = actor.bone_world("hand_l") - origin - cup.basis * Vector3(0.002, 0.055, 0.0)
	var wind := Motion.smooth(Motion.seg(t, toss - 0.33, toss - 0.16))
	var throw := Motion.out_cubic(Motion.seg(t, toss - 0.16, toss))
	var rest := seat + Vector3(-0.25, 0.56, 0.24)
	var scoop := rest + Vector3(-0.045, -0.13, 0.08)
	var release := seat + Vector3(-0.32, 0.94, 0.22)
	var fling := Motion.arc(rest.lerp(scoop, wind), release, 0.045, throw)
	fling = fling.lerp(rest, Motion.smooth(Motion.seg(t, toss + 0.09, toss + 0.40)))
	actor.aim_hand("r", origin + fling)
	_pose_coins(group, seat, release, t - toss)


func _pose_coins(group: Node3D, seat: Vector3, release: Vector3, age: float) -> void:
	for index in TOSSED_COINS:
		var coin := group.get_node("coin_%d" % index) as Node3D
		var delay := index * 0.019
		var travel := 0.45 + index * 0.039
		var k := Motion.seg(age, delay, delay + travel)
		var landing := seat + Vector3(-0.49 + index * 0.13, 0.21 + float(index % 3) * 0.077, 0.65 + index * 0.049)
		coin.visible = age >= delay
		coin.position = Motion.arc(release, landing, 0.24 + index * 0.031, k)
		coin.position.y += maxf(0.0, Motion.wobble(age - delay - travel, 5.0, 11.0)) * 0.039
		coin.rotation = Vector3(lerpf(0.0, -PI * 0.5 - TAU, k), float(index) * 0.65 + k * TAU, k * TAU * 2.0)
