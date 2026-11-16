extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")

const RIVALS := ["airtel", "vodafone", "idea"]
const BRANDS := ["airtel", "vodafone", "Idea"]
const COLORS := ["a82730", "bc242d", "edc044"]
const BUCKETS := [Vector3(-0.92, 0, 1.18), Vector3(0, 0, 0.93), Vector3(0.92, 0, 1.18)]
const TEARS_PER_EYE := 9
const FILING := Vector3(-0.90, 0.75, -0.20)
const HANDOVER := Vector3(0.48, 0.93, 0.92)
const DROP_FROM := Vector3(0.36, 1.08, 0.83)
const LAND := Vector3(0.58, 0.022, 1.82)


func build(_gag: Dictionary) -> Node3D:
	var office := Node3D.new()
	_build_office(office)
	var folder := Node3D.new()
	folder.name = "folder"
	office.add_child(folder)
	Kit.add_box(folder, Vector3(0.30, 0.025, 0.22), Vector3.ZERO, Kit.mat("ad7142", 0.68))
	Kit.add_box(folder, Vector3(0.245, 0.018, 0.165), Vector3(0, 0.024, 0), Kit.mat("f4dec6"))
	var title := _label(folder, "TARIFF COMPLAINT", 0.030, Vector3(0, 0.035, 0), "362a30")
	title.rotation.x = -PI * 0.5

	var tear_mat := Kit.glow_mat("61caff", 0.65)
	var tear_mesh := Kit.sphere(0.025, 0.033, tear_mat, 10)
	for index in RIVALS.size():
		_prop(office, "quaternius_fantasy_props/Bucket_Metal", 0.95, BUCKETS[index])
		var water := Kit.add_mesh(office, Kit.cylinder(0.134, 0.134, 0.012, tear_mat, 24),
			BUCKETS[index] + Vector3(0, 0.18, 0), Vector3.ZERO, "water_%d" % index, false)
		water.hide()
		var badge := Node3D.new()
		badge.name = "badge_%d" % index
		office.add_child(badge)
		Kit.add_box(badge, Vector3(0.28, 0.091, 0.015), Vector3.ZERO, Kit.mat(COLORS[index], 0.58))
		_label(badge, BRANDS[index], 0.050, Vector3(0, 0, 0.013), "28212a" if index == 2 else "ffffff")
		for bead in TEARS_PER_EYE * 2:
			Kit.add_mesh(office, tear_mesh, Vector3.ZERO, Vector3.ZERO, "tear_%d_%d" % [index, bead], false)
	office.add_child(_phone())
	return office


func _build_office(office: Node3D) -> void:
	var wood := Kit.mat("49312c", 0.48)
	var grain := Kit.mat("755344", 0.52)
	var brass := Kit.mat("b89558", 0.40, 0.55)
	var stone := Kit.mat("333b50", 0.72)
	Kit.add_box(office, Vector3(8.12, 0.11, 9.4), Vector3(0, 3.56, 0), Kit.mat("34313b", 0.89))
	for x in [-1.72, 1.72]:
		Kit.add_box(office, Vector3(0.60, 0.04, 0.11), Vector3(x, 3.48, -0.73),
			Kit.glow_mat("e6cbad", 0.5), 0, "", false)
	Kit.add_box(office, Vector3(4.5, 2.87, 0.16), Vector3(0, 1.435, -2.62), stone)
	for x in [-2.15, -1.35, 1.35, 2.15]:
		Kit.add_box(office, Vector3(0.065, 2.85, 0.05), Vector3(x, 1.425, -2.52), grain)
	Kit.add_box(office, Vector3(2.25, 0.75, 0.075), Vector3(0, 2.31, -2.49), wood)
	_label(office, "TRAI", 0.30, Vector3(0, 2.43, -2.435), "ffe3aa")
	_label(office, "TELECOM REGULATORY AUTHORITY OF INDIA", 0.077, Vector3(0, 2.14, -2.435), "e8ddd1")
	for x in [-1.98, 1.98]:
		Kit.add_box(office, Vector3(0.052, 0.54, 0.068), Vector3(x, 2.16, -2.46),
			Kit.glow_mat("ffd3a0", 0.62), 0, "", false)
	Kit.add_box(office, Vector3(2.76, 0.68, 0.72), Vector3(0, 0.34, -0.60), wood)
	Kit.add_box(office, Vector3(2.90, 0.073, 0.83), Vector3(0, 0.708, -0.60), grain)
	for x in [-1.28, 1.28]:
		Kit.add_box(office, Vector3(0.035, 0.51, 0.018), Vector3(x, 0.365, -0.235), brass)
	Kit.add_box(office, Vector3(2.60, 0.028, 0.021), Vector3(0, 0.58, -0.232), brass)
	_prop(office, "quaternius_fantasy_props/Chair_1", 1.18, Vector3(-0.20, 0, -1.32))
	_prop(office, "kenney_suburban/planter", 2.1, Vector3(1.79, 0, -1.76))
	_prop(office, "kenney_suburban/planter", 2.1, Vector3(-1.79, 0, -1.76))
	for index in 5:
		Kit.add_box(office, Vector3(0.36, 0.025, 0.24), Vector3(1.02, 0.76 + 0.027 * index, -0.61),
			Kit.mat("d8b995" if index % 2 else "48516a"), 3.0 * index)
	_omni(office, Vector3(0.2, 2.69, 1.92), "ffebd6", 3.1, 5.6)
	_omni(office, Vector3(-1.64, 1.8, -1.52), "8bb4ff", 1.5, 4.5)
	_omni(office, Vector3(1.58, 1.28, 1.90), "ffbd85", 1.4, 4.0)
	_omni(office, Vector3(0.52, 0.69, 1.52), "bddbff", 1.0, 2.25)


func _phone() -> Node3D:
	var phone := Node3D.new()
	phone.name = "phone"
	var case := Kit.mat("1d2433", 0.27, 0.4)
	Kit.add_box(phone, Vector3(0.23, 0.405, 0.029), Vector3.ZERO, case)
	Kit.add_box(phone, Vector3(0.221, 0.402, 0.012), Vector3(0, 0, -0.017), Kit.mat("4c6094", 0.37))
	Kit.add_box(phone, Vector3(0.206, 0.357, 0.007), Vector3(0, 0.013, 0.016), Kit.glow_mat("0b2352", 0.5))
	Kit.add_box(phone, Vector3(0.067, 0.008, 0.004), Vector3(0, 0.181, 0.021), case)
	var incoming := _label(phone, "Jio", 0.084, Vector3(0, 0.091, 0.025), "d9eaff")
	incoming.name = "incoming"
	_label(incoming, "CALLING", 0.028, Vector3(0, -0.072, 0), "c1ddff")
	Kit.add_mesh(incoming, Kit.cylinder(0.038, 0.038, 0.006, Kit.glow_mat("36dc93", 0.72), 24),
		Vector3(0, -0.166, 0.004), Vector3(90, 0, 0), "", false)
	var failed := _label(phone, "CALL", 0.064, Vector3(0, 0.074, 0.027), "ff9e94")
	failed.name = "failed"
	_label(failed, "DROPPED", 0.046, Vector3(0, -0.074, 0), "fff1e5")
	for tilt in [-45.0, 45.0]:
		var stroke := Kit.add_box(failed, Vector3(0.060, 0.009, 0.005), Vector3(0, -0.148, 0),
			Kit.glow_mat("ff5444", 0.75), 0, "", false)
		stroke.rotation_degrees.z = tilt
	return phone


func pose(office: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var origin: Vector3 = ctx["holder"].position
	var official = ctx["actor"].call("complaint_official")
	official.body.position.y += 0.23
	for index in RIVALS.size():
		var rival = ctx["actor"].call("complaint_" + RIVALS[index])
		var badge := office.get_node("badge_%d" % index) as Node3D
		var forward := Vector3(sin(rival.rotation.y), 0, cos(rival.rotation.y))
		badge.position = rival.bone_world("spine_03") - origin + forward * 0.145 + Vector3.DOWN * 0.04
		badge.rotation.y = rival.rotation.y
		_cry(office, rival, origin, index, t, float(p["cry"]) + index * 0.08, float(p["drop"]))
	_file_complaint(office, ctx["actor"].call("complaint_airtel"), origin, t, float(p["file"]))
	_pose_phone(office, ctx, origin, t, p)

	var arrival := Motion.smooth(Motion.seg(t, float(p["run"]) - 0.25, float(p["cry"]) + 0.15))
	var track := Motion.smooth(Motion.seg(t, float(p["ring"]) - 0.48, float(p["drop"])))
	var payoff := Motion.smooth(Motion.seg(t, float(p["drop"]) - 0.06, float(p["hit"]) + 0.20))
	var camera := Vector3(0.46, 2.13, 5.73).lerp(Vector3(0.50, 2.04, 4.76), arrival)
	var focus := Vector3(0, 1.25, 0.42).lerp(Vector3(0, 1.27, 0.15), arrival)
	camera = camera.lerp(Vector3(1.30, 1.84, 3.78), track)
	focus = focus.lerp(Vector3(0.48, 0.97, 0.75), track)
	camera = camera.lerp(Vector3(0.96, 0.99, 3.08), payoff)
	focus = focus.lerp(LAND + Vector3(0, 0.19, 0), payoff)
	return {"camera": origin + camera, "focus": origin + focus}


func _cry(office: Node3D, actor, origin: Vector3, index: int, t: float, start: float, stop: float) -> void:
	var forward := Vector3(sin(actor.rotation.y), 0, cos(actor.rotation.y))
	var right := Vector3(forward.z, 0, -forward.x)
	var eyes: Vector3 = actor.anchor_points()["%s.eyes" % actor.name]["pos"] - origin
	var bucket: Vector3 = BUCKETS[index] + Vector3(0, 0.28, 0)
	for eye in 2:
		for bead in TEARS_PER_EYE:
			var tear := office.get_node("tear_%d_%d" % [index, eye * TEARS_PER_EYE + bead]) as Node3D
			var elapsed := t - start - 0.046 * bead - 0.025 * eye
			var age := fposmod(elapsed, 0.57)
			tear.visible = elapsed >= 0.0 and t - age < stop and age < 0.49
			if tear.visible:
				var k := age / 0.49
				var side := -1.0 if eye == 0 else 1.0
				var source := eyes + forward * 0.04 + right * side * 0.097
				var landing := bucket + right * (side * 0.068 + sin(bead * 4.0) * 0.025)
				tear.position = Motion.arc(source, landing, 0.14, k)
				tear.scale = Vector3(1.0, 1.0 + 1.3 * k, 1.0)
	var water := office.get_node("water_%d" % index) as Node3D
	var fill := Motion.smooth(Motion.seg(t, start + 0.44, stop))
	water.visible = fill > 0.0
	water.position.y = 0.12 + fill * 0.115
	water.scale = Vector3.ONE * (0.85 + fill * 0.19 + 0.035 * sin(t * 23.0 + index))


func _file_complaint(office: Node3D, actor, origin: Vector3, t: float, hit: float) -> void:
	var wind := Motion.smooth(Motion.seg(t, hit - 0.66, hit - 0.18))
	var slam := Motion.in_cubic(Motion.seg(t, hit - 0.18, hit))
	var lift := Motion.out_cubic(Motion.seg(t, hit + 0.07, hit + 0.30))
	var palm := FILING + Vector3(-0.04, 0.33 * wind * (1.0 - slam) + 0.15 * lift, 0.05)
	actor.aim_hand("r", origin + palm, wind * (1.0 - lift))
	var folder := office.get_node("folder") as Node3D
	var rest := FILING + Vector3(0.045 * Motion.out_cubic(Motion.seg(t, hit, hit + 0.19)), 0, -0.10)
	folder.position = actor.bone_world("hand_r") - origin + Vector3(0, -0.03, 0.055)
	folder.position = folder.position.lerp(rest, Motion.smooth(Motion.seg(t, hit - 0.055, hit + 0.04)))
	folder.rotation = Vector3(-0.76 * (1.0 - slam), 0.26, 0.10 * Motion.wobble(t - hit))


func _pose_phone(office: Node3D, ctx: Dictionary, origin: Vector3, t: float, p: Dictionary) -> void:
	var ring := float(p["ring"])
	var drop := float(p["drop"])
	var hit := float(p["hit"])
	var mukesh = ctx["actor"].call("complaint_mukesh")
	var rival = ctx["actor"].call("complaint_vodafone")
	var handoff := Motion.smooth(Motion.seg(t, ring - 0.23, ring + 0.16))
	var release := Motion.smooth(Motion.seg(t, drop, drop + 0.18))
	var inspect := Motion.smooth(Motion.seg(t, ring + 0.10, drop))
	mukesh.aim_hand("r", origin + HANDOVER, Motion.smooth(Motion.seg(t, ring - 0.60, ring)) * (1.0 - release))
	rival.aim_hand("l", origin + HANDOVER.lerp(DROP_FROM, inspect),
		Motion.smooth(Motion.seg(t, ring - 0.30, ring + 0.05)) * (1.0 - release))
	var phone := office.get_node("phone") as Node3D
	phone.visible = t >= ring - 0.67
	(phone.get_node("incoming") as Node3D).visible = t < hit
	(phone.get_node("failed") as Node3D).visible = t >= hit
	var pass_from: Vector3 = mukesh.bone_world("hand_r") - origin
	var pass_to: Vector3 = rival.bone_world("hand_l") - origin
	phone.position = pass_from.lerp(pass_to, handoff) + Vector3(0, 0.115, 0.035)
	phone.rotation = Vector3(-0.10, -0.12, 0.10 * sin((t - ring) * 42.0))
	if t >= drop:
		var fall := Motion.seg(t, drop, hit)
		var bounce := Motion.seg(t, hit, hit + 0.25)
		var glide := Vector3(0.115, 0, 0.10) * Motion.out_cubic(bounce)
		var launch := pass_to.lerp(DROP_FROM, release) + Vector3(0, 0.115, 0.035)
		phone.position = Motion.arc(launch, LAND, 0.06, fall * fall)
		phone.position += glide + Vector3.UP * sin(bounce * PI) * 0.074
		phone.rotation = Vector3(lerpf(-0.10, -PI * 0.5, Motion.smooth(fall)),
			-0.12 + 0.17 * fall, -0.22 * sin(fall * PI) + 0.16 * Motion.wobble(t - hit))
		phone.scale = Vector3.ONE + Vector3(0.05, 0.05, -0.15) * Motion.impact(t - hit, 0.55)
	else:
		phone.scale = Vector3.ONE


func _label(root: Node3D, value: String, size: float, at: Vector3, color: String) -> MeshInstance3D:
	var label := Reveals.text_node(value, size, Color(color))
	label.position = at
	root.add_child(label)
	return label


func _prop(root: Node3D, id: String, scale: float, at: Vector3) -> void:
	var prop := KitDB.static_node(id, scale)
	if prop != null:
		prop.position = at
		root.add_child(prop)


func _omni(root: Node3D, at: Vector3, color: String, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = Color(color)
	light.light_energy = energy
	light.omni_range = reach
	root.add_child(light)
