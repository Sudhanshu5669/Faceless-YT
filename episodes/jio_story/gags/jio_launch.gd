## Launch day: Mukesh slams the launch button, the screen lights up Jio, he flings handfuls of
## SIM cards into a cheering crowd, then slaps a FREE tag on calls, data and apps.
## params: launch (time), throws (3 times), slaps (3 times), fans (crowd size, actors launch_fan_<i>)
## anchors: camera, focus
extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")

const STAGE_H := 0.60
const MUKESH := Vector3(-0.10, STAGE_H, -1.55)
const BUTTON := Vector3(-0.58, STAGE_H, -1.27)
const BUTTON_H := 0.80
const CRATE := Vector3(-0.84, STAGE_H, -1.72)
const CRATE_TOP := 0.64
const STAND := Vector3(0.62, STAGE_H, -1.46)
const SHELVES := [0.50, 0.80, 1.10]
const SCREEN := Vector3(0.0, 2.75, -3.02)
const SCREEN_SIZE := Vector2(4.6, 2.6)
const JIO_BLUE := "0f3cc9"
const PER_THROW := 16
const IN_HAND := 5
const TAG_TILT := [-11.0, 8.0, -6.0]
## Where each FREE tag lands, relative to STAND (on the phone's face, the voucher, the screen).
const TAG_SPOTS := [Vector3(0.0, 0.585, 0.135), Vector3(0.04, 0.905, 0.045), Vector3(-0.02, 1.27, 0.040)]


func build(gag: Dictionary) -> Node3D:
	var hall := Node3D.new()
	_build_stage(hall)
	_build_screen(hall)
	_build_button(hall)
	_build_crate(hall)
	_build_stand(hall)
	for index in 3 * PER_THROW:
		var sim := _sim_card()
		sim.name = "sim_%d" % index
		hall.add_child(sim)
	for index in 3:
		var tag := _free_tag()
		tag.name = "tag_%d" % index
		hall.add_child(tag)
	return hall


# ---------------------------------------------------------------- build

func _build_stage(hall: Node3D) -> void:
	var deck := Kit.mat("1a1d25", 0.32, 0.2)
	var skirt := Kit.mat("101219", 0.8)
	var metal := Kit.mat("3a3f49", 0.4, 0.6)
	Kit.add_box(hall, Vector3(6.8, STAGE_H, 2.6), Vector3(0, STAGE_H * 0.5, -1.98), skirt)
	Kit.add_box(hall, Vector3(6.8, 0.03, 2.6), Vector3(0, STAGE_H + 0.0, -1.98), deck)
	var strip := Kit.add_box(hall, Vector3(6.8, 0.035, 0.03), Vector3(0, STAGE_H - 0.03, -0.67),
		Kit.glow_mat("3f7bff", 2.2), 0, "edge", false)
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Truss towers and a lighting bar framing the screen.
	for side in [-1.0, 1.0]:
		var x: float = side * 2.95
		for corner in [Vector2(-0.13, -0.13), Vector2(0.13, -0.13), Vector2(-0.13, 0.13), Vector2(0.13, 0.13)]:
			Kit.add_box(hall, Vector3(0.035, 4.6, 0.035), Vector3(x + corner.x, STAGE_H + 2.3, -2.7 + corner.y), metal)
		for rung in 12:
			Kit.add_box(hall, Vector3(0.26, 0.022, 0.022), Vector3(x, STAGE_H + 0.2 + rung * 0.37, -2.57), metal, 0, "", false)
		# Speaker stacks on the floor beside the stage.
		for level in 2:
			var cab := Kit.add_box(hall, Vector3(0.62, 0.62, 0.55), Vector3(side * 3.75, 0.31 + level * 0.63, -1.0), skirt)
			cab.rotation_degrees.y = -side * 14.0
			var cone := Kit.add_mesh(hall, Kit.cylinder(0.19, 0.19, 0.02, metal, 20),
				Vector3(side * 3.75 - side * 0.07, 0.31 + level * 0.63, -0.72), Vector3(90, -side * 14.0, 0))
			cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Kit.add_box(hall, Vector3(6.2, 0.26, 0.26), Vector3(0, STAGE_H + 4.55, -2.7), metal)
	Kit.add_box(hall, Vector3(11.0, 0.2, 11.0), Vector3(0, 5.9, 1.4), Kit.mat("07080c", 1.0), 0, "ceiling", false)
	for index in 6:
		var x := -2.3 + index * 0.92
		var can := Kit.add_mesh(hall, Kit.cylinder(0.09, 0.12, 0.28, skirt, 14),
			Vector3(x, STAGE_H + 4.27, -2.55), Vector3(-32, 0, 0))
		can.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		Kit.add_mesh(hall, Kit.cylinder(0.075, 0.075, 0.01, Kit.glow_mat("ffe2b8", 3.0), 14),
			Vector3(x, STAGE_H + 4.14, -2.47), Vector3(-32, 0, 0), "", false)
	# Lights: key spot on Mukesh, the screen's blue spill behind him, coloured spill on the crowd.
	var key := SpotLight3D.new()
	key.name = "key"
	key.light_color = Color("ffe6c8")
	key.spot_range = 9.0
	key.spot_angle = 17.0
	key.spot_attenuation = 0.6
	key.shadow_enabled = true
	var at := Vector3(1.1, 4.9, 1.6)
	key.transform = Transform3D(Basis.looking_at(MUKESH + Vector3(0.25, 0.85, 0) - at), at)
	hall.add_child(key)
	_omni(hall, "rim", Vector3(0.1, STAGE_H + 1.9, -2.55), "4f7dff", 3.2)
	_omni(hall, "spill_l", Vector3(-3.2, 2.1, 1.8), "c84fd8", 4.5)
	_omni(hall, "spill_r", Vector3(3.0, 2.4, 2.6), "3fb7ff", 4.5)
	_omni(hall, "front", Vector3(0.0, 1.2, 0.1), "6f8dff", 3.0)


func _build_screen(hall: Node3D) -> void:
	var bezel := Kit.mat("0b0c10", 0.5)
	Kit.add_box(hall, Vector3(SCREEN_SIZE.x + 0.16, SCREEN_SIZE.y + 0.16, 0.10), SCREEN - Vector3(0, 0, 0.06), bezel)
	var panel := MeshInstance3D.new()
	panel.name = "panel"
	var quad := QuadMesh.new()
	quad.size = SCREEN_SIZE
	panel.mesh = quad
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color("08133a")
	panel.material_override = glow
	panel.position = SCREEN
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hall.add_child(panel)
	var date := _label(hall, "5 SEPTEMBER 2016", 0.30, "eef3ff", SCREEN + Vector3(0, 0.0, 0.02))
	date.name = "date"
	var logo := Node3D.new()
	logo.name = "logo"
	logo.position = SCREEN + Vector3(0, 0.02, 0.03)
	hall.add_child(logo)
	Kit.add_mesh(logo, Kit.cylinder(0.98, 0.98, 0.02, _ink(JIO_BLUE), 48), Vector3.ZERO, Vector3(90, 0, 0), "", false)
	Kit.add_mesh(logo, Kit.cylinder(1.04, 1.04, 0.01, _ink("dfe8ff"), 48), Vector3(0, 0, -0.008), Vector3(90, 0, 0), "", false)
	_label(logo, "Jio", 0.78, "ffffff", Vector3(0, 0.04, 0.02))


func _build_button(hall: Node3D) -> void:
	var post := Kit.mat("2a2e36", 0.35, 0.5)
	var ring := Kit.mat("f2c230", 0.5)
	Kit.add_mesh(hall, Kit.cylinder(0.17, 0.2, 0.05, post, 20), BUTTON + Vector3(0, 0.025, 0))
	Kit.add_mesh(hall, Kit.cylinder(0.065, 0.065, BUTTON_H - 0.1, post, 16), BUTTON + Vector3(0, BUTTON_H * 0.5, 0))
	Kit.add_mesh(hall, Kit.cylinder(0.15, 0.15, 0.07, post, 24), BUTTON + Vector3(0, BUTTON_H - 0.03, 0))
	Kit.add_mesh(hall, Kit.cylinder(0.135, 0.135, 0.02, ring, 24), BUTTON + Vector3(0, BUTTON_H + 0.012, 0))
	var cap := Node3D.new()
	cap.name = "cap"
	cap.position = BUTTON + Vector3(0, BUTTON_H + 0.02, 0)
	hall.add_child(cap)
	var red := Kit.glow_mat("e8322f", 0.35)
	Kit.add_mesh(cap, Kit.sphere(0.10, 0.10, red, 20), Vector3(0, 0.0, 0))


func _build_crate(hall: Node3D) -> void:
	var case_mat := Kit.mat("22252c", 0.6)
	var wood := Kit.mat("8a6a48", 0.8)
	Kit.add_box(hall, Vector3(0.50, 0.32, 0.40), CRATE + Vector3(0, 0.16, 0), case_mat)
	Kit.add_box(hall, Vector3(0.50, 0.03, 0.40), CRATE + Vector3(0, 0.335, 0), wood)
	for side in [-1.0, 1.0]:
		Kit.add_box(hall, Vector3(0.50, 0.30, 0.025), CRATE + Vector3(0, 0.50, side * 0.19), wood)
		Kit.add_box(hall, Vector3(0.025, 0.30, 0.40), CRATE + Vector3(side * 0.24, 0.50, 0), wood)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("jio_launch_crate")
	for index in 34:
		var sim := _sim_card()
		sim.position = CRATE + Vector3(rng.randf_range(-0.19, 0.19), CRATE_TOP - 0.04 + rng.randf_range(-0.03, 0.03),
			rng.randf_range(-0.15, 0.15))
		sim.rotation = Vector3(rng.randf_range(-0.6, 0.6), rng.randf() * TAU, rng.randf_range(-0.6, 0.6))
		hall.add_child(sim)


func _build_stand(hall: Node3D) -> void:
	var post := Kit.mat("2a2e36", 0.35, 0.5)
	var shelf := Kit.mat("2c2f38", 0.4, 0.3)
	Kit.add_mesh(hall, Kit.cylinder(0.18, 0.2, 0.04, post, 20), STAND + Vector3(0, 0.02, -0.04))
	Kit.add_mesh(hall, Kit.cylinder(0.025, 0.025, 1.12, post, 10), STAND + Vector3(0, 0.56, -0.12))
	for height in SHELVES:
		Kit.add_box(hall, Vector3(0.40, 0.024, 0.28), STAND + Vector3(0, height, 0), shelf)
		Kit.add_box(hall, Vector3(0.40, 0.012, 0.012), STAND + Vector3(0, height + 0.006, 0.142),
			Kit.glow_mat("3f7bff", 1.4), 0, "", false)
	# Calls: a desk phone. Data: a Jio recharge voucher. Apps: a phone full of app icons.
	var landline := _landline()
	landline.position = STAND + Vector3(0, SHELVES[0] + 0.012, 0.0)
	landline.scale = Vector3.ONE * 0.95
	hall.add_child(landline)
	var voucher := _voucher()
	voucher.position = STAND + Vector3(0, SHELVES[1] + 0.012, 0.02)
	voucher.rotation_degrees.x = -14
	hall.add_child(voucher)
	var phone := _app_phone()
	phone.position = STAND + Vector3(0, SHELVES[2] + 0.012, 0.0)
	phone.rotation_degrees.x = -9
	hall.add_child(phone)


func _landline() -> Node3D:
	var phone := Node3D.new()
	var shell := Kit.mat("883638", 0.39)
	var pad := Kit.mat("d8b992", 0.46)
	var rubber := Kit.mat("392c33", 0.68)
	Kit.add_box(phone, Vector3(0.31, 0.072, 0.246), Vector3(0, 0.038, 0), rubber)
	Kit.add_box(phone, Vector3(0.32, 0.059, 0.249), Vector3(0, 0.082, 0), shell)
	Kit.add_mesh(phone, Kit.cylinder(0.071, 0.071, 0.013, pad, 24), Vector3(0, 0.119, 0.036))
	Kit.add_mesh(phone, Kit.cylinder(0.024, 0.024, 0.017, shell, 20), Vector3(0, 0.126, 0.036))
	for index in 10:
		var angle := TAU * float(index) / 10.0
		Kit.add_mesh(phone, Kit.cylinder(0.008, 0.008, 0.005, rubber, 10),
			Vector3(0.052 * cos(angle), 0.128, 0.036 + 0.052 * sin(angle)))
	var handle := Kit.add_box(phone, Vector3(0.246, 0.042, 0.053), Vector3(0, 0.156, -0.081), shell)
	handle.rotation_degrees.z = 2.5
	for side in [-1.0, 1.0]:
		Kit.add_box(phone, Vector3(0.071, 0.067, 0.098), Vector3(side * 0.113, 0.144, -0.078), shell)
		Kit.add_box(phone, Vector3(0.048, 0.009, 0.055), Vector3(side * 0.113, 0.109, -0.078), rubber)
	return phone


func _voucher() -> Node3D:
	var card := Node3D.new()
	Kit.add_box(card, Vector3(0.26, 0.16, 0.008), Vector3(0, 0.08, 0), _ink(JIO_BLUE))
	Kit.add_mesh(card, Kit.cylinder(0.034, 0.034, 0.004, _ink("ffffff"), 24), Vector3(-0.085, 0.118, 0.006),
		Vector3(90, 0, 0), "", false)
	_label(card, "Jio", 0.034, JIO_BLUE, Vector3(-0.085, 0.119, 0.009))
	_label(card, "4G DATA", 0.030, "ffffff", Vector3(0.045, 0.118, 0.006))
	Kit.add_box(card, Vector3(0.20, 0.036, 0.003), Vector3(0, 0.050, 0.005), _ink("b9bec7"), 0, "", false)
	_label(card, "RECHARGE", 0.016, "c9d6ff", Vector3(0, 0.017, 0.006))
	return card


func _app_phone() -> Node3D:
	var phone := Node3D.new()
	var size := 0.30
	Kit.add_box(phone, Vector3(size * 0.52, size, 0.016), Vector3(0, size * 0.5, 0), Kit.mat("16181d", 0.3, 0.3))
	Kit.add_box(phone, Vector3(size * 0.46, size * 0.9, 0.002), Vector3(0, size * 0.5, 0.0085), _ink("1b2a55"))
	var colors := ["e53935", "43a047", "fbc02d", "1e88e5", "8e24aa", "fb8c00", "00acc1", "d81b60",
		"7cb342", "3949ab", "f4511e", "00897b"]
	for index in 12:
		var col := index % 3
		var row := index / 3
		Kit.add_box(phone, Vector3(0.030, 0.030, 0.003),
			Vector3(-0.042 + col * 0.042, size * 0.83 - row * 0.052, 0.0105), _ink(colors[index]), 0, "", false)
	return phone


func _sim_card() -> Node3D:
	var sim := Node3D.new()
	Kit.add_box(sim, Vector3(0.17, 0.005, 0.108), Vector3.ZERO, _ink("f4f6fb"), 0, "", false)
	Kit.add_box(sim, Vector3(0.17, 0.006, 0.030), Vector3(0, 0.0005, -0.039), _ink(JIO_BLUE), 0, "", false)
	Kit.add_box(sim, Vector3(0.036, 0.004, 0.030), Vector3(-0.040, 0.003, 0.016), Kit.mat("e0b54a", 0.3, 0.8), 0, "", false)
	Kit.add_mesh(sim, Kit.cylinder(0.024, 0.024, 0.004, _ink(JIO_BLUE), 16), Vector3(0.045, 0.003, 0.014), Vector3.ZERO, "", false)
	return sim


func _free_tag() -> Node3D:
	var tag := Node3D.new()
	Kit.add_box(tag, Vector3(0.15, 0.085, 0.004), Vector3.ZERO, _ink("d82a2a"), 0, "", false)
	Kit.add_mesh(tag, Kit.cylinder(0.009, 0.009, 0.003, _ink("f6e8d0"), 12), Vector3(-0.056, 0.0, 0.003),
		Vector3(90, 0, 0), "", false)
	_label(tag, "FREE", 0.050, "ffffff", Vector3(0.012, 0.0, 0.004))
	return tag


# ---------------------------------------------------------------- pose

func pose(hall: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var origin: Vector3 = ctx["holder"].position
	var launch := float(p["launch"])
	var throws: Array = p["throws"]
	var slaps: Array = p["slaps"]
	var mukesh = ctx["actor"].call("launch_mukesh")
	mukesh.body.position.y += STAGE_H
	_pose_screen(hall, launch, t)
	_pose_launch_hand(hall, mukesh, origin, launch, t)
	var releases: Array[float] = []
	for at in throws:
		releases.append(float(at) + 0.14)
	_pose_throws(hall, mukesh, origin, releases, t)
	_pose_tags(hall, mukesh, origin, slaps, t)
	for index in int(p["fans"]):
		_pose_fan(ctx["actor"].call("launch_fan_%d" % index), index, launch, releases, t)

	var push := Motion.smooth(Motion.seg(t, releases[2] - 0.30, float(slaps[0]) - 0.10))
	var drift := Motion.smooth(Motion.seg(t, launch - 2.0, releases[2]))
	var settle := Motion.smooth(Motion.seg(t, float(slaps[0]), float(slaps[2]) + 0.6))
	var camera := Vector3(0.05, 2.02, 3.75).lerp(Vector3(0.02, 1.98, 3.20), drift)
	var focus := Vector3(0.0, 1.70, -1.9).lerp(Vector3(0.0, 1.66, -1.8), drift)
	camera = camera.lerp(Vector3(0.50, 1.76, 1.02).lerp(Vector3(0.54, 1.80, 0.92), settle), push)
	focus = focus.lerp(Vector3(0.30, 1.42, -1.5).lerp(Vector3(0.33, 1.50, -1.5), settle), push)
	return {"camera": origin + camera, "focus": origin + focus}


func _pose_screen(hall: Node3D, launch: float, t: float) -> void:
	var on := Motion.seg(t, launch, launch + 0.05)
	var flash := maxf(0.0, 1.0 - (t - launch) / 0.35) * on
	var panel := hall.get_node("panel") as MeshInstance3D
	var glow := panel.material_override as StandardMaterial3D
	glow.albedo_color = Color("08133a").lerp(Color("1238b8"), on).lerp(Color("dfe8ff"), flash)
	var date := hall.get_node("date") as Node3D
	var typed := Motion.out_cubic(Motion.seg(t, launch - 2.05, launch - 1.75))
	date.visible = t < launch and typed > 0.0
	date.scale = Vector3.ONE * maxf(0.001, Motion.out_back(typed))
	var logo := hall.get_node("logo") as Node3D
	var pop := Motion.out_back(Motion.seg(t, launch + 0.03, launch + 0.34), 2.2)
	logo.visible = t >= launch + 0.03
	logo.scale = Vector3.ONE * maxf(0.001, pop) * (1.0 + 0.025 * sin(maxf(0.0, t - launch) * 5.0))
	(hall.get_node("key") as SpotLight3D).light_energy = lerpf(2.6, 4.2, on) + 2.5 * flash
	(hall.get_node("rim") as OmniLight3D).light_energy = lerpf(0.6, 3.2, on) + 4.0 * flash
	(hall.get_node("front") as OmniLight3D).light_energy = lerpf(0.4, 1.3, on) + 2.0 * flash
	for name in ["spill_l", "spill_r"]:
		(hall.get_node(name) as OmniLight3D).light_energy = lerpf(0.5, 2.2, on) + 1.5 * flash


func _pose_launch_hand(hall: Node3D, actor, origin: Vector3, launch: float, t: float) -> void:
	var top := BUTTON + Vector3(0, BUTTON_H + 0.07, 0)
	var raise := Motion.smooth(Motion.seg(t, launch - 0.50, launch - 0.13))
	var slam := Motion.in_cubic(Motion.seg(t, launch - 0.13, launch))
	var weight := raise * (1.0 - Motion.smooth(Motion.seg(t, launch + 0.30, launch + 0.62)))
	var high := top + Vector3(0.05, 0.42, 0.10)
	var hand := high.lerp(top + Vector3(0, 0.035, 0), slam)
	hand.y += 0.02 * Motion.wobble(t - launch, 5.0, 10.0)
	if weight > 0.0:
		actor.aim_hand("r", origin + hand, weight, 0.04 * raise * (1.0 - slam))
	var cap := hall.get_node("cap") as Node3D
	var press := slam * (1.0 - Motion.out_cubic(Motion.seg(t, launch + 0.30, launch + 0.48)))
	cap.position.y = BUTTON.y + BUTTON_H + 0.02 - 0.045 * press
	cap.scale = Motion.squash(Motion.impact(t - launch, 0.35, 5.0, 8.0))


func _pose_throws(hall: Node3D, actor, origin: Vector3, releases: Array[float], t: float) -> void:
	var crate_in := CRATE + Vector3(0.06, CRATE_TOP + 0.04, 0.04)
	var wind := MUKESH + Vector3(-0.44, 1.20, -0.26)
	var fling := MUKESH + Vector3(-0.20, 1.48, 0.48)
	var follow := MUKESH + Vector3(-0.08, 1.06, 0.50)
	var active := 0
	for index in releases.size():
		if t >= releases[index] - 0.36:
			active = index
	var r: float = releases[active]
	var start := follow if active > 0 else MUKESH + Vector3(-0.30, 0.70, 0.12)
	var hand := start.lerp(crate_in, Motion.smooth(Motion.seg(t, r - 0.36, r - 0.24)))
	hand = hand.lerp(wind, Motion.smooth(Motion.seg(t, r - 0.24, r - 0.11)))
	hand = hand.lerp(fling, Motion.in_cubic(Motion.seg(t, r - 0.11, r)))
	hand = hand.lerp(follow, Motion.out_cubic(Motion.seg(t, r, r + 0.13)))
	var weight := Motion.smooth(Motion.seg(t, releases[0] - 0.50, releases[0] - 0.36))
	weight *= 1.0 - Motion.smooth(Motion.seg(t, releases[2] + 0.13, releases[2] + 0.48))
	if weight > 0.0:
		actor.aim_hand("r", origin + hand, weight, 0.06 * weight)
	var palm: Vector3 = actor.bone_world("hand_r") - origin
	for throw_index in releases.size():
		_pose_sims(hall, throw_index, releases[throw_index], palm, t)


func _pose_sims(hall: Node3D, throw_index: int, release: float, palm: Vector3, t: float) -> void:
	var rng := RandomNumberGenerator.new()
	for j in PER_THROW:
		var sim := hall.get_node("sim_%d" % (throw_index * PER_THROW + j)) as Node3D
		rng.seed = hash("jio_launch_sim_%d_%d" % [throw_index, j])
		var target := Vector3(rng.randf_range(-2.4, 2.4), 0.012, rng.randf_range(0.5, 3.4))
		if j % 4 == 0:
			target = Vector3(rng.randf_range(-0.9, 0.9), 0.012, rng.randf_range(3.6, 5.0))
		var flight := rng.randf_range(0.80, 1.10)
		var lift := rng.randf_range(0.70, 1.30)
		var spin := Vector3(rng.randf_range(-14, 14), rng.randf_range(-6, 6), rng.randf_range(-14, 14))
		var yaw := rng.randf() * TAU
		var spread := Vector3(rng.randf_range(-0.05, 0.05), rng.randf_range(-0.03, 0.03), rng.randf_range(-0.04, 0.04))
		if t < release:
			sim.visible = j < IN_HAND and t >= release - 0.24
			sim.position = palm + Vector3(-0.03 + 0.016 * j, 0.03 + 0.008 * j, 0.04)
			sim.rotation = Vector3(1.2, 0.3 + 0.32 * j, 0.2)
			continue
		sim.visible = true
		var start := palm + spread
		var k := Motion.seg(t, release, release + flight)
		sim.position = Motion.arc(start, target, lift, k)
		if k < 1.0:
			sim.rotation = spin * (t - release)
		else:
			sim.rotation = Vector3(0, yaw, 0)


func _pose_tags(hall: Node3D, actor, origin: Vector3, slaps: Array, t: float) -> void:
	var rest := MUKESH + Vector3(0.30, 0.82, 0.22)
	var hand := rest
	var held := 0
	for index in slaps.size():
		var hit := float(slaps[index])
		var spot: Vector3 = STAND + TAG_SPOTS[index]
		var back := spot + Vector3(0.10, 0.13, 0.17)
		var lift := spot + Vector3(0.05, 0.04, 0.12)
		if t >= hit - 0.32:
			hand = hand.lerp(back, Motion.smooth(Motion.seg(t, hit - 0.32, hit - 0.10)))
			hand = hand.lerp(spot + Vector3(0, 0, 0.035), Motion.in_cubic(Motion.seg(t, hit - 0.10, hit)))
			hand = hand.lerp(lift, Motion.out_cubic(Motion.seg(t, hit + 0.12, hit + 0.30)))
		if t >= hit:
			held = index + 1
	var first := float(slaps[0])
	var weight := Motion.smooth(Motion.seg(t, first - 0.62, first - 0.32))
	if weight > 0.0:
		actor.aim_hand("l", origin + hand, weight, 0.05 * weight)
	var palm: Vector3 = actor.bone_world("hand_l") - origin
	for index in slaps.size():
		var tag := hall.get_node("tag_%d" % index) as Node3D
		var hit := float(slaps[index])
		if index < held:
			tag.position = STAND + TAG_SPOTS[index] + Vector3(0, 0, 0.006)
			tag.rotation = Vector3(deg_to_rad(-12.0 if index == 1 else -8.0), 0, deg_to_rad(TAG_TILT[index]))
			var s := Motion.squash(Motion.impact(t - hit, 0.40, 5.0, 9.0))
			tag.scale = Vector3(s.y, s.x, 1.0) * (1.0 + 0.05 * Motion.wobble(t - hit, 3.0, 6.0))
		else:
			var stack := index - held
			tag.position = palm + Vector3(0.0, -0.01 - 0.004 * stack, 0.055 - 0.004 * stack)
			tag.rotation = Vector3(-0.25, 0.0, deg_to_rad(TAG_TILT[index]) * 0.5 + 0.12 * stack)
			tag.scale = Vector3.ONE


func _pose_fan(actor, index: int, launch: float, releases: Array[float], t: float) -> void:
	var forward := Vector3(sin(actor.rotation.y), 0, cos(actor.rotation.y))
	var lateral := Vector3(cos(actor.rotation.y), 0, -sin(actor.rotation.y))
	var start := launch + 0.06 + (index % 5) * 0.07
	var rise := Motion.out_back(Motion.seg(t, start, start + 0.32), 1.4)
	if rise <= 0.0:
		return
	var reach := Motion.smooth(Motion.seg(t, releases[0] + 0.2, releases[0] + 0.6))
	var pump := sin((t - start) * (7.5 + 0.4 * (index % 3)) + index * 1.3)
	var jump := absf(sin((t - start) * (4.2 + 0.2 * (index % 4)) + index)) * 0.06 * minf(rise, 1.0)
	actor.body.position.y += jump
	for side in ["l", "r"]:
		var sign := 1.0 if side == "l" else -1.0
		var shoulder: Vector3 = actor.bone_world("upperarm_" + side)
		var up := shoulder + lateral * sign * (0.30 - 0.06 * reach) + forward * (0.04 + 0.12 * reach)
		up += Vector3.UP * (0.55 + 0.08 * reach + 0.07 * pump * sign)
		actor.aim_hand(side, up, minf(rise, 1.0), 0.12 * minf(rise, 1.0))


# ---------------------------------------------------------------- helpers

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


func _omni(root: Node3D, name: String, at: Vector3, color: String, reach: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.name = name
	lamp.position = at
	lamp.light_color = Color(color)
	lamp.omni_range = reach
	root.add_child(lamp)
