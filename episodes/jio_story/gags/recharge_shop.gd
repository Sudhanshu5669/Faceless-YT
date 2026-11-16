## The shopkeeper offers a handset, then tries to watch his own video.
extends RefCounted

const KitDB = preload("res://scripts/world/kit_db.gd")
const Kit = preload("res://scripts/world/prop_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")
const SHOP_FLOOR := 0.48
const PHONE_HEIGHT := 0.21
const VIDEO_DISPLAY := """
shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform float spin;
uniform float loading;

float oval(vec2 uv, vec2 center, vec2 radius) {
	return 1.0 - smoothstep(0.96, 1.04, length((uv - center) / radius));
}

float rect(vec2 uv, vec2 lo, vec2 hi) {
	return step(lo.x, uv.x) * step(lo.y, uv.y) * step(uv.x, hi.x) * step(uv.y, hi.y);
}

void fragment() {
	vec2 uv = UV;
	vec3 ink = vec3(0.037, 0.055, 0.065);
	vec3 paper = vec3(0.80, 0.86, 0.83);
	vec3 color = ink;
	// Paused selfie thumbnail with the owner's slick hair, moustache and shop apron.
	vec3 video = mix(vec3(0.12, 0.37, 0.37), vec3(0.43, 0.22, 0.11), step(0.29, uv.y));
	video = mix(video, vec3(0.78, 0.44, 0.13), oval(uv, vec2(0.50, 0.64), vec2(0.34, 0.19)));
	video = mix(video, vec3(0.93, 0.81, 0.65), oval(uv, vec2(0.50, 0.46), vec2(0.29, 0.145)));
	video = mix(video, ink, oval(uv, vec2(0.47, 0.362), vec2(0.29, 0.060)));
	video = mix(video, ink, max(oval(uv, vec2(0.40, 0.451), vec2(0.025, 0.015)),
		oval(uv, vec2(0.61, 0.451), vec2(0.025, 0.015))));
	video = mix(video, ink, max(oval(uv, vec2(0.452, 0.511), vec2(0.065, 0.020)),
		oval(uv, vec2(0.548, 0.511), vec2(0.065, 0.020))));
	color = mix(color, video * mix(0.88, 0.42, loading), rect(uv, vec2(0.035, 0.21), vec2(0.965, 0.72)));
	// Generic player controls and a progress bar stuck near zero.
	color = mix(color, vec3(0.32, 0.36, 0.38), rect(uv, vec2(0.09, 0.765), vec2(0.91, 0.781)));
	color = mix(color, vec3(0.92, 0.35, 0.17), rect(uv, vec2(0.09, 0.765), vec2(0.17, 0.781)));
	color = mix(color, paper * 0.45, rect(uv, vec2(0.14, 0.10), vec2(0.52, 0.115)));
	vec2 d = (uv - vec2(0.50, 0.48)) * vec2(1.0, 2.03);
	float r = length(d);
	color = mix(color, ink, (1.0 - smoothstep(0.30, 0.34, r)) * loading * 0.88);
	float ring = 1.0 - smoothstep(0.022, 0.038, abs(r - 0.22));
	float arc = fract(atan(d.y, d.x) / 6.283185 - spin);
	color = mix(color, vec3(0.98, 0.99, 1.0), ring * smoothstep(0.12, 0.85, arc) * loading);
	float play = step(-0.055, d.x) * step(abs(d.y), 0.082 - (d.x + 0.055) * 0.71);
	color = mix(color, ink, (1.0 - smoothstep(0.13, 0.17, r)) * (1.0 - loading) * 0.83);
	color = mix(color, paper, play * (1.0 - loading));
	ALBEDO = color;
}
"""


func build(gag: Dictionary) -> Node3D:
	var shop := Node3D.new()
	_storefront(shop)
	_rate_board(shop)
	_stock(shop)
	if gag.get("params", {}).has("busy"):
		var board := shop.get_node("rate_text") as MeshInstance3D
		board.mesh = board.mesh.duplicate()
		var voucher := Kit.add_box(shop, Vector3(0.23, 0.15, 0.01), Vector3.ZERO, Kit.mat("2256ae"))
		voucher.name = "voucher"
		_lettering(voucher, "Jio", 0.060, "ffffff", Vector3(0, 0.02, 0.009))
		_lettering(voucher, "4G DATA", 0.035, "ffffff", Vector3(0, -0.04, 0.009))
		return shop
	shop.add_child(_opposite_side())
	var handset := Reveals.shape_node("phone", PHONE_HEIGHT, Color("1c3040"))
	handset.name = "handset"
	handset.add_child(_video_display())
	shop.add_child(handset)
	return shop


func _opposite_side() -> Node3D:
	var street := Node3D.new()
	street.name = "opposite_side"
	Kit.add_box(street, Vector3(24, 0.12, 8), Vector3(-3, -0.061, 8.6), Kit.mat("514c50"))
	Kit.add_box(street, Vector3(24, 0.14, 1.8), Vector3(-3, 0.04, 7.08), Kit.mat("887666"))
	var corner := KitDB.static_node("quaternius_downtown/Building_Small_1", 0.38)
	corner.position = Vector3(-4.45, 0.1, 10.35)
	corner.rotation_degrees.y = 172.0
	street.add_child(corner)
	var terrace := KitDB.static_node("quaternius_downtown/Building_Small_1", 0.39)
	terrace.position = Vector3(-9.45, 0.1, 10.20)
	terrace.rotation_degrees.y = 190.0
	street.add_child(terrace)
	var apartments := KitDB.static_node("quaternius_downtown/Building_Medium_2_001", 0.36)
	apartments.position = Vector3(0.57, 0.1, 10.32)
	apartments.rotation_degrees.y = 180.0
	street.add_child(apartments)
	var palm := KitDB.static_node("quaternius_nature/PalmTree_2", 1.15)
	palm.position = Vector3(-2.36, 0.11, 6.97)
	street.add_child(palm)
	street.hide()
	return street


func _video_display() -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.44, 0.90) * PHONE_HEIGHT
	var shader := Shader.new()
	shader.code = VIDEO_DISPLAY
	var material := ShaderMaterial.new()
	material.shader = shader
	var screen := MeshInstance3D.new()
	screen.name = "video_display"
	screen.mesh = mesh
	screen.position = Vector3(0, PHONE_HEIGHT * 0.5, PHONE_HEIGHT * 0.039)
	screen.material_override = material
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	screen.hide()
	return screen


func _storefront(shop: Node3D) -> void:
	var plaster := Kit.mat("9e7d65")
	var teal := Kit.mat("286263", 0.68)
	var stone := Kit.mat("897767")
	var shadow := Kit.mat("393936")
	Kit.add_box(shop, Vector3(11, 0.12, 2.48), Vector3(0, 0.045, -1.35), stone)
	Kit.add_box(shop, Vector3(11, 0.07, 0.14), Vector3(0, 0.041, -0.08), Kit.mat("a89378"))
	Kit.add_box(shop, Vector3(11, 6.4, 0.27), Vector3(0, 3.20, -2.85), plaster)
	Kit.add_box(shop, Vector3(11, 0.17, 0.41), Vector3(0, 3.90, -2.61), stone)
	for x in [-1.38, 0.0, 1.38]:
		Kit.add_box(shop, Vector3(0.96, 1.22, 0.12), Vector3(x, 4.87, -2.66), stone)
		Kit.add_box(shop, Vector3(0.79, 1.04, 0.025), Vector3(x, 4.87, -2.589), shadow)
		for bar in [-0.23, 0.0, 0.23]:
			Kit.add_box(shop, Vector3(0.028, 1.04, 0.034), Vector3(x + bar, 4.87, -2.565), teal)
		Kit.add_box(shop, Vector3(1.04, 0.075, 0.21), Vector3(x, 4.24, -2.60), stone)
	Kit.add_box(shop, Vector3(3.78, 1.47, 0.08), Vector3(0, 1.46, -2.68), shadow)
	var platform_height := SHOP_FLOOR - 0.10
	Kit.add_box(shop, Vector3(3.75, platform_height, 1.47),
		Vector3(0, SHOP_FLOOR - platform_height * 0.5, -1.93), stone)
	Kit.add_box(shop, Vector3(3.94, 1.01, 0.52), Vector3(0, 0.60, -0.93), teal)
	Kit.add_box(shop, Vector3(4.05, 0.08, 0.60), Vector3(0, 1.12, -0.93), Kit.mat("9a6942", 0.52))
	Kit.add_box(shop, Vector3(3.72, 0.062, 0.03), Vector3(0, 0.28, -0.652), Kit.mat("5f8c80"))
	for side in [-1.0, 1.0]:
		Kit.add_box(shop, Vector3(0.18, 2.62, 0.33), Vector3(side * 1.97, 1.42, -0.91), teal)
		Kit.add_box(shop, Vector3(1.72, 2.33, 0.17), Vector3(side * 2.88, 1.27, -1.01), shadow)
		for row in 19:
			Kit.add_box(shop, Vector3(1.59, 0.085, 0.035),
				Vector3(side * 2.88, 0.18 + row * 0.117, -0.90), Kit.mat("6c7374"), 0, "", false)
	Kit.add_box(shop, Vector3(4.14, 0.16, 0.78), Vector3(0, 2.43, -1.02), teal)
	Kit.add_box(shop, Vector3(4.11, 1.37, 0.24), Vector3(0, 3.12, -1.09), Kit.mat("416c65"))
	Kit.add_box(shop, Vector3(4.25, 0.09, 0.40), Vector3(0, 3.81, -1.07), teal)
	for stripe in 14:
		var fabric := Kit.mat("cfad7a" if stripe % 2 else "9f4434")
		var panel := Kit.add_box(shop, Vector3(0.296, 0.042, 0.82),
			Vector3(-1.924 + stripe * 0.296, 2.42, -0.50), fabric)
		panel.rotation_degrees.x = 14.0
		Kit.add_box(shop, Vector3(0.296, 0.13, 0.035),
			Vector3(panel.position.x, 2.27, -0.104), fabric)
	Kit.add_box(shop, Vector3(4.08, 0.47, 0.14), Vector3(0, 3.55, -1.01), teal)
	_lettering(shop, "MOBILE RECHARGE", 0.30, "f5e2af", Vector3(0, 3.55, -0.927))
	Kit.add_box(shop, Vector3(1.24, 0.055, 0.07), Vector3(-0.08, 2.25, -1.76), Kit.mat("f9ddaa"))
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 2.17, -1.14)
	lamp.light_color = Color("ffda9f")
	lamp.light_energy = 0.78
	lamp.omni_range = 3.0
	shop.add_child(lamp)


func _rate_board(shop: Node3D) -> void:
	Kit.add_box(shop, Vector3(2.38, 0.79, 0.12), Vector3(0, 2.92, -0.85), Kit.mat("513a30"))
	Kit.add_box(shop, Vector3(2.30, 0.71, 0.025), Vector3(0, 2.92, -0.78), Kit.mat("e7b44e"))
	Kit.add_box(shop, Vector3(2.17, 0.59, 0.018), Vector3(0, 2.92, -0.758), Kit.mat("632e2d"))
	var price := Reveals.text_node("₹250 / GB", 0.40, Color("ffe6a9"))
	price.name = "rate_text"
	price.position = Vector3(0, 2.91, -0.74)
	shop.add_child(price)


func _stock(shop: Node3D) -> void:
	var shelf := Kit.mat("755440")
	var cards: Array[String] = ["ae6740", "668e9b", "b9a266", "837b64"]
	for level in 3:
		var y := 1.23 + level * 0.285
		Kit.add_box(shop, Vector3(1.18, 0.045, 0.19), Vector3(-1.16, y, -2.50), shelf)
		for slot in 4:
			var card := Kit.add_box(shop, Vector3(0.18, 0.18, 0.018),
				Vector3(-1.57 + slot * 0.27, y + 0.107, -2.44), Kit.mat(cards[(level + slot) % cards.size()]))
			card.rotation_degrees.z = 6.0 - slot * 4.0
	for index in 3:
		var phone := Reveals.shape_node("phone", 0.19, Color(cards[index]))
		phone.position = Vector3(0.94 + index * 0.26, 1.20, -0.89)
		phone.rotation_degrees.x = -17.0
		shop.add_child(phone)
	var stool := KitDB.static_node("quaternius_fantasy_props/Stool", 0.84)
	stool.position = Vector3(-2.35, 0.11, -0.40)
	shop.add_child(stool)
	var planter := KitDB.static_node("quaternius_downtown/Prop_Planter_Single", 0.47)
	planter.position = Vector3(2.67, 0.11, -0.53)
	shop.add_child(planter)


func _lettering(shop: Node3D, text: String, size: float, color: String, at: Vector3) -> void:
	var label := Reveals.text_node(text, size, Color(color))
	label.position = at
	shop.add_child(label)


func pose(shop: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var params: Dictionary = gag["params"]
	if params.has("busy"):
		return _pose_busy(shop, gag, t, ctx)
	var future_owner = ctx["actor"].call("busy_recharge_owner")
	future_owner.position.y -= 10.0
	for i in 6:
		var future = ctx["actor"].call("busy_recharge_%d" % i)
		future.position.y -= 10.0
	var price := float(params["price"])
	var closeup := float(params["closeup"])
	var start := float(gag["t"])
	var origin: Vector3 = ctx["holder"].position
	var owner = ctx["actor"].call("recharge_owner")
	# Actors are grounded on the bay floor before gags pose them.
	owner.body.position.y += SHOP_FLOOR
	var handset := shop.get_node("handset") as Node3D
	var screen := handset.get_node("video_display") as MeshInstance3D
	screen.visible = t >= closeup
	(shop.get_node("opposite_side") as Node3D).visible = screen.visible
	if screen.visible:
		return _pose_video(handset, screen, owner, origin, params, t)
	var slide := Motion.smooth(Motion.seg(t, start, closeup))
	var tilt := Motion.smooth(Motion.seg(t, price - 0.53, price + 0.12))
	var camera := Vector3(-0.82, 1.95, 6.45).lerp(Vector3(0.21, 2.25, 5.77), slide)
	var focus := Vector3(-0.07, 1.78, -0.84).lerp(Vector3(0.04, 2.02, -0.84), tilt)
	var lift := Motion.out_cubic(Motion.seg(t, start + 0.13, start + 0.70))
	var lower := Motion.smooth(Motion.seg(t, price + 0.12, closeup - 0.04))
	var offer := Motion.arc(Vector3(0.56, 1.33, -1.35), Vector3(0.60, 1.54, -0.97), 0.07, lift)
	offer = offer.lerp(Vector3(0.53, 1.36, -1.26), lower)
	owner.aim_hand("l", origin + offer)
	handset.position = owner.bone_world("hand_l") - origin - Vector3(0.0, 0.018, 0.018)
	handset.rotation = Vector3(-0.52 + 0.37 * lift - 0.41 * lower, 0.16, -0.12)
	return {"camera": origin + camera, "focus": origin + focus}


func _pose_busy(shop: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var cheap := float(p["busy"])
	var offer := float(p["offer"])
	var owner = ctx["actor"].call("busy_recharge_owner")
	var shopper = ctx["actor"].call("busy_recharge_0")
	var previous_owner = ctx["actor"].call("recharge_owner")
	previous_owner.position.y -= 10.0
	for i in 4:
		var passer = ctx["actor"].call("recharge_passer_%d" % i)
		passer.position.y -= 10.0
	var origin: Vector3 = ctx["holder"].position
	owner.body.position.y += SHOP_FLOOR
	var slide := Motion.smooth(Motion.seg(t, offer - 0.36, cheap + 0.11))
	var slot := Motion.smooth(Motion.seg(t, cheap - 0.48, cheap))
	var price := shop.get_node("rate_text") as MeshInstance3D
	(price.mesh as TextMesh).text = "₹18 / GB" if t >= cheap else "₹250 / GB"
	price.rotation.x = sin(slot * PI) * 1.55 + 0.12 * Motion.wobble(t - cheap)
	var hand := Vector3(0.60, 1.28, -1.14).lerp(Vector3(0.52, 1.41, -0.61), slide)
	owner.aim_hand("l", origin + hand, 1.0)
	var reach := Motion.smooth(Motion.seg(t, offer - 0.14, cheap))
	shopper.aim_hand("l", origin + Vector3(0.52, 1.41, -0.59), reach)
	var palm: Vector3 = owner.bone_world("hand_l").lerp(shopper.bone_world("hand_l"),
		Motion.smooth(Motion.seg(t, cheap, cheap + 0.15)))
	var card := shop.get_node("voucher") as Node3D
	card.position = palm - origin + Vector3(0, 0.055, 0.045)
	card.rotation.z = -0.14 + 0.16 * reach
	var move := Motion.smooth(Motion.seg(t, float(gag["t"]), cheap + 0.45))
	var camera := Vector3(-0.80, 2.18, 6.72).lerp(Vector3(-0.52, 2.28, 5.40), move)
	var focus := Vector3(0.0, 1.77, -0.55).lerp(Vector3(0.14, 1.88, -0.76), move)
	return {"camera": origin + camera, "focus": origin + focus}


func _pose_video(handset: Node3D, screen: MeshInstance3D, owner, origin: Vector3,
		params: Dictionary, t: float) -> Dictionary:
	var start := float(params["closeup"])
	var play := float(params["play"])
	var buffer := float(params["buffer"])
	var give_up := float(params["give_up"])
	var move := Motion.smooth(Motion.seg(t, start, float(params["end"])))
	var lift := Motion.smooth(Motion.seg(t, start, play))
	var slump := Motion.smooth(Motion.seg(t, give_up, give_up + 0.33))
	# Open up a clear line from over his shoulder to the phone beside his head.
	var lean := 0.18
	owner.body.position.x -= 0.12
	owner.body.position.y -= 0.035 * slump
	owner.rotation.z = lean
	owner.body.position = owner.body.position.rotated(Vector3.FORWARD, lean)
	var grip := Motion.arc(Vector3(0.73, 1.30, -1.20), Vector3(0.80, 1.32, -1.10), 0.018, lift)
	grip.y -= 0.028 * slump
	owner.aim_hand("l", origin + grip)
	handset.rotation = Vector3(-0.61 - 0.05 * slump, PI - 0.55, 0.05)
	# Grip the lower bezel, leaving the thumbnail and spinner visible.
	var bezel := handset.basis * Vector3(-0.036, 0.031, -0.006)
	handset.position = owner.bone_world("hand_l") - origin - bezel
	var material := screen.material_override as ShaderMaterial
	material.set_shader_parameter("spin", fposmod((t - buffer) * 1.35, 1.0))
	material.set_shader_parameter("loading", Motion.smooth(Motion.seg(t, buffer - 0.05, buffer + 0.12)))
	var camera := Vector3(0.97, 2.12, -2.46).lerp(Vector3(1.02, 1.90, -1.94), move)
	var display_center := handset.position + handset.basis * Vector3(0, PHONE_HEIGHT * 0.5, 0)
	var focus := display_center + Vector3(lerpf(-0.19, -0.11, move), -0.018, 0)
	return {"camera": origin + camera, "focus": origin + focus}
