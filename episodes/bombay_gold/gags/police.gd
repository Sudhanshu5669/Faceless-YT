## A Bombay police station, evening of 14 April 1944, and the street outside: a high room with a teak counter, ledgers,
## a wall clock, a ceiling fan, a notice board, a bench; the sub-inspector behind the counter. Outside, under a
## lamp, the relief fund's collection box on a table with a cloth banner.
## The gentleman sets the gold bar on the counter; the inspector writes him a cheque (a slip of paper); outside he
## drops it into the relief box.
##
## Local frame: the counter along x at z -1.0 (top y 1.05); the man stands at z +0.4; the inspector behind at z -1.9;
## the relief box outside at BOX (x +12) on a table, banner above.
##
## params: man, inspector (actor ids); place t (bar set on the counter); write t (cheque written); hand t (cheque handed
##   over); drop t (cheque into the box)
## anchors: counter, bar, cheque, box
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const PH := "incoming/bombay_gold/polyhaven/"
const PH0 := "incoming/polyhaven_pokhran/models/"
const BOX := Vector3(12.0, 0.0, -1.0)

var _p := {}
var _bar: MeshInstance3D
var _cheque: Node3D
var _fan: Node3D
var _slot_glow: OmniLight3D


func _tex(name: String, scale: float, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var b := PH + "textures/" + name
	return Kit.textured(b + "_diff_2k.jpg", b + "_nor_gl_2k.jpg", b + "_rough_2k.jpg", Vector3.ONE * scale, tint, true)


func _model(root: Node3D, rel: String, pos: Vector3, yaw: float, s: float = 1.0) -> Node3D:
	var n := Kit.model(rel)
	n.position = pos
	n.rotation.y = yaw
	n.scale = Vector3.ONE * s
	root.add_child(n)
	return n


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "police"))
	var wall := _tex("plastered_wall_04", 0.5, Color(0.84, 0.8, 0.66))
	var teak := _tex("weathered_brown_planks", 0.8, Color(0.55, 0.36, 0.22))
	Kit.box(root, Vector3(9, 0.1, 9), Vector3(0, -0.05, 0), _tex("terrazzo_tiles", 0.9, Color(0.75, 0.72, 0.66)))
	Kit.box(root, Vector3(9, 5, 0.2), Vector3(0, 2.5, -4.0), wall)
	Kit.box(root, Vector3(0.2, 5, 9), Vector3(-4.3, 2.5, 0), wall)
	Kit.box(root, Vector3(0.2, 5, 9), Vector3(4.3, 2.5, 0), wall)
	Kit.box(root, Vector3(9, 0.1, 9), Vector3(0, 5.0, 0), Kit.mat("#e8e2d4", 0.9))
	Kit.box(root, Vector3(9, 1.2, 0.06), Vector3(0, 0.6, -3.88), Kit.mat("#2e3a2c", 0.8))
	# The counter: a teak front with panels, a top, ledgers, an inkstand, a brass bell.
	Kit.box(root, Vector3(4.6, 0.82, 0.6), Vector3(0, 0.41, -1.0), teak)
	Kit.box(root, Vector3(4.8, 0.06, 0.8), Vector3(0, 0.85, -1.0), Kit.mat("#4a2e1c", 0.5))
	for k in 5:
		Kit.box(root, Vector3(0.7, 0.5, 0.04), Vector3(-1.8 + k * 0.9, 0.42, -0.69), Kit.mat("#3a2414", 0.6))
	Kit.box(root, Vector3(0.42, 0.07, 0.3), Vector3(-1.2, 0.92, -1.1), Kit.mat("#7a2a20", 0.7))
	Kit.box(root, Vector3(0.42, 0.06, 0.3), Vector3(-1.2, 0.985, -1.1), Kit.mat("#2a3a5a", 0.7))
	Kit.box(root, Vector3(0.5, 0.03, 0.36), Vector3(0.9, 0.895, -1.15), Kit.mat("#e8e0c8", 0.9))
	Kit.cyl(root, 0.04, 0.05, 0.07, Vector3(1.4, 0.92, -1.2), Kit.mat("#141414", 0.3, 0.3), 12)
	Kit.ball(root, 0.06, Vector3(-0.4, 0.94, -1.0), Kit.mat("#b8892e", 0.3, 0.9), 12, Vector3(1, 0.6, 1))
	# Behind the counter, a raised wooden platform for the duty officer.
	Kit.box(root, Vector3(5.0, 0.6, 2.2), Vector3(0, 0.3, -2.4), teak)
	# Behind the counter: a desk, files on shelves, a notice board; a wall clock (Poly Haven), a bench.
	_model(root, PH0 + "vintage_wooden_drawer_01/vintage_wooden_drawer_01_2k.gltf", Vector3(-2.6, 0, -3.5), 0.0, 1.2)
	_model(root, PH0 + "steel_frame_shelves_01/steel_frame_shelves_01_2k.gltf", Vector3(2.4, 0, -3.6), 0.0)
	_model(root, PH0 + "wall_clock/wall_clock_2k.gltf", Vector3(0, 3.3, -3.88), 0.0, 1.6)
	Kit.box(root, Vector3(1.4, 1.0, 0.04), Vector3(-1.5, 2.4, -3.88), Kit.mat("#6a4a2e", 0.8))
	for k in 6:
		Kit.box(root, Vector3(0.3, 0.38, 0.01), Vector3(-1.95 + (k % 3) * 0.45, 2.6 - (k / 3) * 0.45, -3.85), Kit.mat("#e8e0c8", 0.9))
	Kit.box(root, Vector3(2.4, 0.08, 0.45), Vector3(-2.8, 0.45, 1.6), teak)
	_fan = _model(root, PH0 + "ceiling_fan/ceiling_fan_2k.gltf", Vector3(0, 4.6, 0), 0.0)
	# A tall barred window, evening outside.
	Kit.box(root, Vector3(1.6, 2.4, 0.05), Vector3(3.0, 2.6, -3.88), Kit.flat("#2a3450"))
	for k in 6:
		Kit.rod(root, Vector3(2.3 + k * 0.28, 1.4, -3.84), Vector3(2.3 + k * 0.28, 3.8, -3.84), 0.015, Kit.mat("#1a1a1a", 0.4, 0.7), 6)
	# Light: a hanging lamp over the counter, the window's blue.
	Kit.omni(root, Vector3(0, 3.0, -0.6), "#ffcf90", 3.0, 8.0, true, 0.6)
	Kit.cyl(root, 0.08, 0.3, 0.22, Vector3(0, 3.2, -0.6), Kit.mat("#2e4a3a", 0.5, 0.3), 20)
	Kit.rod(root, Vector3(0, 3.3, -0.6), Vector3(0, 5.0, -0.6), 0.008, Kit.mat("#141414", 0.4), 5)
	Kit.omni(root, Vector3(3.0, 2.6, -3.2), "#5a70a0", 0.6, 4.0, false, 0.2)
	# Outside: the street at dusk, a lamp, the relief table with its box and banner.
	Kit.box(root, Vector3(14, 0.1, 14), BOX + Vector3(0, -0.05, 0), _tex("cobblestone_floor_04", 0.5, Color(0.6, 0.56, 0.5)))
	Kit.box(root, Vector3(14, 8, 0.4), BOX + Vector3(0, 4, -3.5), _tex("yellow_plaster", 0.3, Color(0.8, 0.7, 0.56)))
	for k in 4:
		Kit.box(root, Vector3(1.1, 1.8, 0.1), BOX + Vector3(-4.5 + k * 3.0, 4.5, -3.28), Kit.mat("#ffcc80", 0.5))
	Kit.box(root, Vector3(1.6, 0.06, 0.8), BOX + Vector3(0, 0.8, 0), Kit.mat("#4a2e1c", 0.6))
	for sx: float in [-0.7, 0.7]:
		for sz: float in [-0.33, 0.33]:
			Kit.box(root, Vector3(0.06, 0.8, 0.06), BOX + Vector3(sx, 0.4, sz), Kit.mat("#3a2414", 0.6))
	Kit.box(root, Vector3(0.5, 0.45, 0.4), BOX + Vector3(0, 1.05, 0), Kit.mat("#6a3a22", 0.6))
	Kit.box(root, Vector3(0.24, 0.02, 0.04), BOX + Vector3(0, 1.28, 0.05), Kit.mat("#0a0a0a", 0.6))
	Kit.box(root, Vector3(0.52, 0.06, 0.42), BOX + Vector3(0, 1.0, 0), Kit.mat("#b8892e", 0.3, 0.9))
	for sx: float in [-1.6, 1.6]:
		Kit.rod(root, BOX + Vector3(sx, 0, -0.4), BOX + Vector3(sx, 2.8, -0.4), 0.03, Kit.mat("#6a5030", 0.8), 6)
	Kit.box(root, Vector3(3.2, 0.7, 0.02), BOX + Vector3(0, 2.4, -0.4), Kit.mat("#f2ead6", 0.95))
	Kit.text(root, "RELIEF FUND", 0.34, "#8a1f1a", BOX + Vector3(0, 2.4, -0.385), Vector3.ZERO)
	var lamp := Kit.model(PH + "models/street_lamp_01/street_lamp_01_2k.gltf")
	lamp.position = BOX + Vector3(-2.6, 0, -1.2)
	root.add_child(lamp)
	Kit.omni(root, BOX + Vector3(-2.2, 3.6, -0.8), "#ffc070", 4.0, 10.0, true, 0.8)
	_slot_glow = Kit.omni(root, BOX + Vector3(0, 1.6, 0.6), "#ffe0b0", 0.0, 2.0, false, 0.0)
	# The bar and the cheque.
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("#f4c84a")
	gold.metallic = 1.0
	gold.roughness = 0.16
	gold.emission_enabled = true
	gold.emission = Color("#ffb428")
	gold.emission_energy_multiplier = 0.35
	var bm := BoxMesh.new()
	bm.size = Vector3(0.26, 0.075, 0.13)
	_bar = MeshInstance3D.new()
	_bar.mesh = bm
	_bar.material_override = gold
	root.add_child(_bar)
	_cheque = Node3D.new()
	root.add_child(_cheque)
	var cm := Kit.shader("""
shader_type spatial;
render_mode cull_disabled;
void fragment() {
	vec3 c = vec3(0.93, 0.9, 0.8);
	float line = step(0.82, fract(UV.y * 5.0)) * step(0.1, UV.x) * step(UV.x, 0.9) * 0.25;
	float band = step(UV.y, 0.18) * 0.18;
	float sig = step(0.6, UV.x) * step(UV.x, 0.88) * step(0.7, UV.y) * step(UV.y, 0.78) * (0.5 + 0.5 * sin(UV.x * 120.0));
	ALBEDO = c - vec3(line + band * vec3(0.3, 0.1, 0.0).x + sig * 0.6);
	ROUGHNESS = 0.9;
}
""")
	Kit.quad(_cheque, Vector2(0.24, 0.1), Vector3.ZERO, cm, Vector3(-PI * 0.5, 0, 0))
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var inv := gt.affine_inverse()
	_fan.rotation.y = -t * 4.0
	var place := float(_p.get("place", 1e9))
	var write := float(_p.get("write", 1e9))
	var hand_t := float(_p.get("hand", 1e9))
	var drop := float(_p.get("drop", 1e9))
	var man = ctx["actor"].call(String(_p.get("man", ""))) if ctx.has("actor") else null
	var insp = ctx["actor"].call(String(_p.get("inspector", ""))) if ctx.has("actor") else null
	var on_counter := Vector3(0.2, 0.92, -0.85)
	# The bar: in his hands, set down on the counter on `place`.
	if man != null and man.visible and t < place + 0.6:
		var fwd := Vector3(sin(man.rotation.y), 0, cos(man.rotation.y))
		var right := Vector3(cos(man.rotation.y), 0, -sin(man.rotation.y))
		var chest: Vector3 = man.bone_world("spine_03")
		var held: Vector3 = chest + fwd * 0.3
		var k := Motion.smooth(clampf((t - (place - 0.4)) / 0.5, 0.0, 1.0))
		var hp: Vector3 = held.lerp(gt * on_counter, k)
		man.aim_hand("r", hp + right * 0.1, 1.0 - clampf((t - place) / 0.4, 0.0, 1.0))
		man.aim_hand("l", hp - right * 0.1, 1.0 - clampf((t - place) / 0.4, 0.0, 1.0))
		_bar.position = inv * hp
		_bar.rotation = Vector3(0, man.rotation.y - gt.basis.get_euler().y, 0)
		if t >= place:
			_bar.position = on_counter
	else:
		_bar.position = on_counter
		_bar.rotation = Vector3(0, 0.15, 0)
	_bar.visible = t < BOX.x * 0.0 + 1e9
	# The cheque: written on the counter, handed over, carried out, dropped into the box.
	var cheque := Vector3(0.9, 0.9, -1.15)
	var crot := Vector3(0, 0.1, 0)
	if insp != null and insp.visible and t >= write - 0.3 and t < hand_t + 0.6:
		var wr := Motion.smooth(clampf((t - write) / 0.3, 0.0, 1.0))
		var scrib := Vector3(0.03 * sin(t * 18.0), 0, 0.02 * sin(t * 13.0)) * (1.0 - clampf((t - (hand_t - 0.5)) / 0.2, 0.0, 1.0))
		var pen: Vector3 = gt * (cheque + Vector3(0, 0.05, 0) + scrib)
		insp.aim_hand("r", pen, wr)
		if t >= hand_t:
			var hk := Motion.smooth(clampf((t - hand_t) / 0.5, 0.0, 1.0))
			var give: Vector3 = gt * (cheque.lerp(Vector3(0.6, 1.25, -0.5), hk))
			insp.aim_hand("l", give, 1.0)
			cheque = inv * give
			crot = Vector3(0.3 * hk, 0.1, 0)
	if man != null and man.visible and t >= drop - 1.2:
		var fwd := Vector3(sin(man.rotation.y), 0, cos(man.rotation.y))
		var chest: Vector3 = man.bone_world("spine_03")
		var into: Vector3 = gt * (BOX + Vector3(0, 1.32, 0.05))
		var k := Motion.smooth(clampf((t - (drop - 0.6)) / 0.6, 0.0, 1.0))
		var hp: Vector3 = (chest + fwd * 0.35 + Vector3(0, 0.1, 0)).lerp(into, k)
		man.aim_hand("r", hp, 1.0)
		cheque = inv * hp
		crot = Vector3(-PI * 0.5 * k, 0, 0)
	_cheque.position = cheque
	_cheque.rotation = crot
	_cheque.visible = t >= write - 0.3 and t < drop + 0.25
	_slot_glow.light_energy = (1.5 * exp(-(t - drop) * 3.0)) if t > drop else 0.0
	return {"counter": gt * Vector3(0, 1.1, -1.0), "bar": gt * _bar.position, "cheque": gt * _cheque.position, "box": gt * (BOX + Vector3(0, 1.2, 0))}
