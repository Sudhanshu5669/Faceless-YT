## A retired Parsi gentleman's flat in Girgaum, 1944: a high-ceilinged front room, pale green distempered walls over a
## dark dado, a patterned tile floor, a carved cabinet, a grandfather clock, an ornate mirror, framed portraits, a
## rocking chair, a round table with an oil lamp, a ceiling fan, a tall shuttered window onto the lane (the buildings
## opposite, the smoke column over the docks in the sky). Late sun slants in through the window.
## The gold bar bursts through the side wall (plaster, dust, a ragged hole), flies across, thumps onto the table and
## skids; he lifts it in both hands. His black Parsi cap rides on his head.
##
## Local frame: floor y 0; the window wall at z -3.0 (window centred x 0.6); the side wall the bar comes through at
## x -3.2; the table at (0.2, 0, -0.6); cameras toward -z / -x.
##
## params: man id; burst t (the wall bursts); land t (bar hits the table); lift t (he lifts it); dusk t (evening light)
## anchors: hole, table, bar, window, man_hands
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Paths = preload("res://scripts/core/paths.gd")

const PH := "incoming/bombay_gold/polyhaven/"
const PH0 := "incoming/polyhaven_pokhran/models/"
const HOLE := Vector3(-3.2, 1.7, -1.2)
const TABLE := Vector3(0.2, 0.0, -0.6)
const TOP := 0.75

var FX
var _p := {}
var _bar: MeshInstance3D
var _hole: Node3D
var _chunks: MultiMesh
var _smoke
var _cap: Node3D
var _paper: Node3D
var _sun: SpotLight3D
var _lamp: OmniLight3D
var _fan: Node3D
var _glint: OmniLight3D
var _fire
var _sky_day: MeshInstance3D
var _sky_night: MeshInstance3D
var _back: OmniLight3D
var _sky_mat: StandardMaterial3D
var _bar_mat: Material
var _bar_sil: StandardMaterial3D


func _h(i: int, salt: int) -> float:
	var x := sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453
	return x - floor(x)


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
	FX = load(Paths.repo_path("episodes/bombay_gold/gags/fx.gd"))
	var root := Node3D.new()
	root.name = String(g.get("id", "flat"))
	var wall := _tex("plastered_wall_04", 0.6, Color(0.72, 0.84, 0.74))
	var dado := Kit.mat("#3e3226", 0.7)
	var trim := Kit.mat("#e8e2d2", 0.7)
	Kit.box(root, Vector3(7.0, 0.1, 6.5), Vector3(0, -0.05, -0.25), _tex("terrazzo_tiles", 0.9, Color(0.95, 0.88, 0.8)))
	Kit.box(root, Vector3(7.0, 0.1, 6.5), Vector3(0, 4.25, -0.25), Kit.mat("#efe8d8", 0.9))
	# Window wall (z -3) with a tall opening; the side wall the bar bursts through (x -3.2); the back wall (+x).
	Kit.box(root, Vector3(2.4, 4.3, 0.25), Vector3(-2.2, 2.15, -3.1), wall)
	Kit.box(root, Vector3(2.4, 4.3, 0.25), Vector3(3.0, 2.15, -3.1), wall)
	Kit.box(root, Vector3(2.4, 0.9, 0.25), Vector3(0.6, 0.45, -3.1), wall)
	Kit.box(root, Vector3(2.4, 0.8, 0.25), Vector3(0.6, 3.9, -3.1), wall)
	Kit.box(root, Vector3(0.25, 4.3, 6.5), Vector3(-3.3, 2.15, -0.25), wall)
	Kit.box(root, Vector3(0.25, 4.3, 6.5), Vector3(3.5, 2.15, -0.25), wall)
	for spec in [[Vector3(7.0, 1.0, 0.05), Vector3(0, 0.5, -2.96)], [Vector3(0.05, 1.0, 6.5), Vector3(-3.16, 0.5, -0.25)],
			[Vector3(0.05, 1.0, 6.5), Vector3(3.36, 0.5, -0.25)]]:
		Kit.box(root, spec[0], spec[1], dado)
	Kit.box(root, Vector3(7.0, 0.08, 0.08), Vector3(0, 1.02, -2.94), trim)
	# The window: frame, two tall shutters open inward, an iron grille, the lane outside.
	var wood := Kit.mat("#4a3020", 0.7)
	Kit.box(root, Vector3(2.5, 0.12, 0.3), Vector3(0.6, 0.92, -3.05), wood)
	Kit.box(root, Vector3(2.5, 0.12, 0.3), Vector3(0.6, 3.48, -3.05), wood)
	for sx: float in [-1.0, 1.0]:
		var sh := Kit.box(root, Vector3(1.1, 2.5, 0.05), Vector3(0.6 + sx * 1.82, 2.2, -2.42), Kit.mat("#3e5c46", 0.75), Vector3(0, sx * 1.48, 0))
		sh.name = "shutter"
	for k in 7:
		Kit.rod(root, Vector3(-0.55 + k * 0.38, 0.98, -3.15), Vector3(-0.55 + k * 0.38, 3.42, -3.15), 0.012, Kit.mat("#1a1a1a", 0.4, 0.7), 6)
	# Outside: the buildings across the lane, and sky.
	var opp := _tex("yellow_plaster", 0.25, Color(0.96, 0.84, 0.6))
	Kit.box(root, Vector3(30, 9, 1.0), Vector3(0.6, -0.5, -18.0), opp)
	for k in 8:
		Kit.box(root, Vector3(1.1, 1.9, 0.1), Vector3(-8.0 + k * 2.6, 1.0, -17.45), Kit.mat("#16120e", 0.9))
	Kit.box(root, Vector3(30, 0.25, 1.6), Vector3(0.6, 4.1, -17.2), _tex("clay_roof_tiles_02", 0.5))
	_sky_mat = StandardMaterial3D.new()
	_sky_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_sky_mat.albedo_color = Color("#a8b8cc")
	_sky_mat.disable_fog = true
	_sky_day = Kit.box(root, Vector3(400, 300, 1.0), Vector3(0, 40, -120.0), _sky_mat)
	_sky_day.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The evening sky over the burning docks: a deep red-orange glow under black smoke.
	_sky_night = Kit.box(root, Vector3(400, 300, 1.0), Vector3(0, 40, -399.0), Kit.shader("""
shader_type spatial;
render_mode unshaded;
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	float y = clamp((lp.y + 0.5), 0.0, 1.0);
	ALBEDO = mix(vec3(1.0, 0.42, 0.12) * 1.6, vec3(0.06, 0.03, 0.03), smoothstep(0.08, 0.32, y));
}
"""))
	_sky_night.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sky_night.visible = false
	_back = Kit.omni(root, Vector3(0.6, 1.8, -4.5), "#ff7a2a", 0.0, 9.0, false, 1.0)
	# Furniture (Poly Haven) and a portrait.
	_model(root, PH + "models/vintage_cabinet_01/vintage_cabinet_01_2k.gltf", Vector3(3.2, 0, 0.6), -PI * 0.5, 0.95)
	_model(root, PH + "models/vintage_grandfather_clock_01/vintage_grandfather_clock_01_2k.gltf", Vector3(-2.9, 0, 1.4), PI * 0.5)
	_model(root, PH + "models/ornate_mirror_01/ornate_mirror_01_2k.gltf", Vector3(3.3, 1.7, -1.6), -PI * 0.5)
	_model(root, PH + "models/fancy_picture_frame_01/fancy_picture_frame_01_2k.gltf", Vector3(-3.15, 2.4, 0.2), PI * 0.5, 1.4)
	_model(root, PH + "models/Rockingchair_01/Rockingchair_01_2k.gltf", Vector3(1.9, 0, -1.6), -0.6)
	_model(root, PH + "models/round_wooden_table_01/round_wooden_table_01_2k.gltf", TABLE, 0.0, 0.75)
	_model(root, PH + "models/painted_wooden_chair_01/painted_wooden_chair_01_2k.gltf", TABLE + Vector3(-0.9, 0, 0.3), 1.2)
	_model(root, PH + "models/vintage_oil_lamp/vintage_oil_lamp_2k.gltf", TABLE + Vector3(-0.3, TOP, -0.2), 0.0)
	_model(root, PH + "models/wooden_bookshelf_worn/wooden_bookshelf_worn_2k.gltf", Vector3(-2.9, 0, -2.2), PI * 0.5, 0.9)
	_fan = _model(root, PH0 + "ceiling_fan/ceiling_fan_2k.gltf", Vector3(0.2, 3.6, 0.0), 0.0)
	# The hole (shown on the burst): a ragged dark patch with broken brick around it.
	_hole = Node3D.new()
	_hole.position = HOLE
	_hole.visible = false
	root.add_child(_hole)
	Kit.ball(_hole, 0.32, Vector3(0.08, 0, 0), Kit.mat("#0e0b08", 0.95), 12, Vector3(0.3, 1.0, 1.2))
	for k in 10:
		var a := k * TAU / 10.0
		Kit.box(_hole, Vector3(0.12, 0.08, 0.14), Vector3(0.14, sin(a) * 0.36, cos(a) * 0.44), Kit.mat("#a8584a", 0.9), Vector3(a, 0, 0))
	# Plaster chunks and dust.
	var chunk := BoxMesh.new()
	chunk.size = Vector3(0.08, 0.05, 0.1)
	_chunks = MultiMesh.new()
	_chunks.transform_format = MultiMesh.TRANSFORM_3D
	_chunks.mesh = chunk
	_chunks.instance_count = 90
	_chunks.visible_instance_count = 0
	var cmi := MultiMeshInstance3D.new()
	cmi.multimesh = _chunks
	cmi.material_override = Kit.mat("#d8d4c4", 0.9)
	root.add_child(cmi)
	_smoke = FX.layer(root, 400, "smoke")
	_fire = FX.layer(root, 200, "fire")
	_smoke.mat.set_shader_parameter("lit_col", Color(0.86, 0.84, 0.78))
	_smoke.mat.set_shader_parameter("shade_col", Color(0.55, 0.52, 0.48))
	# The bar.
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("#f4c84a")
	gold.metallic = 1.0
	gold.roughness = 0.2
	gold.emission_enabled = true
	gold.emission = Color("#ffb428")
	gold.emission_energy_multiplier = 0.3
	var bm := BoxMesh.new()
	bm.size = Vector3(0.26, 0.075, 0.13)
	_bar = MeshInstance3D.new()
	_bar.mesh = bm
	_bar.material_override = gold
	_bar.visible = false
	_bar_mat = gold
	_bar_sil = StandardMaterial3D.new()
	_bar_sil.albedo_color = Color("#4a3410")
	_bar_sil.metallic = 1.0
	_bar_sil.roughness = 0.28
	root.add_child(_bar)
	_glint = Kit.omni(root, Vector3.ZERO, "#ffd27a", 0.0, 1.6, false, 0.0)
	# His cap: the black Parsi topi, slightly slanted.
	_cap = Node3D.new()
	root.add_child(_cap)
	Kit.cyl(_cap, 0.15, 0.17, 0.2, Vector3(0, 0.1, 0), Kit.mat("#141210", 0.6), 20, Vector3(-0.25, 0, 0))
	# His newspaper (held until the burst, then dropped).
	_paper = Node3D.new()
	root.add_child(_paper)
	var pm := Kit.shader("""
shader_type spatial;
render_mode cull_disabled;
void fragment() {
	float col = step(0.06, fract(UV.x * 4.0)) * step(fract(UV.x * 4.0), 0.94);
	float rowl = step(0.4, fract(UV.y * 60.0));
	float head = step(UV.y, 0.12);
	ALBEDO = mix(vec3(0.9, 0.88, 0.8), vec3(0.25), clamp(col * rowl * 0.35 + head * 0.55 * step(0.1, fract(UV.x * 9.0)), 0.0, 1.0));
	ROUGHNESS = 0.95;
}
""")
	Kit.quad(_paper, Vector2(0.55, 0.42), Vector3(-0.27, 0, 0), pm, Vector3(0, 0.15, 0))
	Kit.quad(_paper, Vector2(0.55, 0.42), Vector3(0.27, 0, 0), pm, Vector3(0, -0.15, 0))
	# Light: low sun through the window (a hard shaft in the dust), a lamp for the evening.
	_sun = Kit.spot(root, Vector3(7.5, 6.0, -7.0), Vector3(-0.8, 0.0, 0.6), "#ffd49a", 22.0, 22.0, 16.0, true, 4.0)
	Kit.omni(root, Vector3(0.6, 2.4, -1.8), "#9cb8d0", 0.25, 6.0, false, 0.0)
	Kit.omni(root, Vector3(-0.3, 1.7, -0.3), "#ffd8a8", 0.45, 3.2, false, 0.0)
	_lamp = Kit.omni(root, TABLE + Vector3(-0.3, TOP + 0.4, -0.2), "#ffb460", 0.0, 6.0, true, 0.4)
	return root


func _bar_at(t: float) -> Dictionary:
	var burst := float(_p.get("burst", 1e9))
	var land := float(_p.get("land", 1e9))
	if t < burst:
		return {"vis": false}
	if t < land:
		var u := (t - burst) / maxf(land - burst, 0.05)
		var p := HOLE.lerp(TABLE + Vector3(-0.2, TOP + 0.05, 0.0), u) + Vector3(0, sin(u * PI) * 0.4, 0)
		return {"vis": true, "pos": p, "rot": Vector3(u * 9.0, u * 3.0, u * 6.0)}
	var a := t - land
	var skid := 1.0 - exp(-a * 5.0)
	var hop := absf(sin(minf(a, 0.5) * 14.0)) * 0.12 * exp(-a * 8.0)
	return {"vis": true, "pos": TABLE + Vector3(-0.2 + skid * 0.38, TOP + 0.04 + hop, 0.02 + skid * 0.06), "rot": Vector3(0, 0.4 + skid * 0.5, 0)}


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var inv := gt.affine_inverse()
	var cam := node.get_viewport().get_camera_3d()
	var cam_l: Vector3 = (inv * cam.global_position) if cam else Vector3(0, 1.6, 3)
	var burst := float(_p.get("burst", 1e9))
	var lift := float(_p.get("lift", 1e9))
	var dusk := float(_p.get("dusk", 1e9))
	_fan.rotation.y = -t * 5.0
	_hole.visible = t >= burst
	# Debris and dust from the hole.
	FX.begin(_smoke)
	var a := t - burst
	var n := 0
	if a >= 0.0 and a < 6.0:
		for i in _chunks.instance_count:
			var v := Vector3(2.0 + _h(i, 1) * 4.0, _h(i, 2) * 3.0 - 0.5, (_h(i, 3) - 0.5) * 4.0)
			var p := HOLE + Vector3(0.1, (_h(i, 4) - 0.5) * 0.5, (_h(i, 5) - 0.5) * 0.6) + v * a + Vector3(0, -4.9 * a * a, 0)
			if p.y < 0.03:
				p.y = 0.03
				p.x = HOLE.x + 0.1 + v.x * sqrt(maxf((HOLE.y + 0.5) / 4.9, 0.01))
			_chunks.set_instance_transform(n, Transform3D(Basis.from_euler(Vector3(a * 6.0 * _h(i, 6), a * 4.0, a * 5.0 * _h(i, 7))).scaled(Vector3.ONE * (0.5 + _h(i, 8) * 1.2)), p))
			n += 1
		FX.plume(_smoke, HOLE + Vector3(0.3, -0.3, 0), t, {"t0": burst, "t1": burst + 0.5, "rate": 30.0, "life": 4.0, "rise": 0.25, "spread": 0.4,
			"grow": 0.6, "size0": 0.5, "wind": Vector3(0.9, 0, 0.1), "alpha": 0.55, "dark": 0.0, "seed": 1001, "slow": 0.8})
	_chunks.visible_instance_count = n
	# The bar: flight, landing, skid; then in his hands.
	var b := _bar_at(t)
	_bar.visible = b["vis"]
	var man_id := String(_p.get("man", ""))
	var man = ctx["actor"].call(man_id) if ctx.has("actor") and man_id != "" else null
	var eve = ctx["actor"].call(String(_p.get("eve_man", ""))) if ctx.has("actor") and _p.has("eve_man") else null
	var evening: bool = eve != null and eve.visible
	var bar_pos: Vector3 = b.get("pos", Vector3.ZERO)
	if b["vis"]:
		_bar.position = bar_pos
		_bar.rotation = b["rot"]
	if evening:
		# At the window that evening: he holds the bar up against the glow of the burning docks.
		var efwd := Vector3(sin(eve.rotation.y), 0, cos(eve.rotation.y))
		var eright := Vector3(cos(eve.rotation.y), 0, -sin(eve.rotation.y))
		var ehead: Vector3 = eve.bone_world("head")
		var up := Motion.smooth(clampf((t - dusk - 0.2) / 1.2, 0.0, 1.0))
		var hp: Vector3 = (ehead + efwd * 0.45 + Vector3(0, -0.55, 0)).lerp(ehead + efwd * 0.62 + Vector3(0, -0.12, 0), up)
		eve.aim_hand("r", hp + eright * 0.11, 1.0)
		eve.aim_hand("l", hp - eright * 0.11, 1.0)
		_bar.visible = true
		_bar.material_override = _bar_sil
		_bar.position = inv * hp
		_bar.rotation = Vector3(0.15, eve.rotation.y - gt.basis.get_euler().y, 0)
		_cap.position = inv * (Vector3((ctx["point"].call(String(_p.get("eve_man", "")) + ".head") as Dictionary).get("pos", ehead)) + Vector3(0, 0.25, 0) - efwd * 0.03)
		_cap.rotation = Vector3(0, eve.rotation.y - gt.basis.get_euler().y, 0)
		_cap.visible = true
		_paper.visible = false
	elif man != null and man.visible:
		_bar.material_override = _bar_mat
		var fwd := Vector3(sin(man.rotation.y), 0, cos(man.rotation.y))
		var right := Vector3(cos(man.rotation.y), 0, -sin(man.rotation.y))
		var chest: Vector3 = man.bone_world("spine_03")
		# The newspaper, held at reading height until the burst, then dropped to the floor.
		var drop := Motion.smooth(clampf((t - burst - 0.1) / 0.5, 0.0, 1.0))
		var hold: Vector3 = chest + fwd * 0.32 + Vector3(0, 0.12, 0)
		var floor_p: Vector3 = gt * (inv * hold * Vector3(1, 0, 1) + Vector3(0, 0.02, 0))
		var pp: Vector3 = hold.lerp(floor_p + fwd * 0.4, drop)
		_paper.position = inv * pp
		_paper.rotation = Vector3(-0.3 - drop * 1.2, man.rotation.y - gt.basis.get_euler().y, drop * 0.4)
		_paper.visible = t < lift
		if t < burst + 0.15:
			man.aim_hand("r", hold + right * 0.25, 1.0)
			man.aim_hand("l", hold - right * 0.25, 1.0)
		# The lift: his hands come to the bar on the table and raise it to his chest; it is heavy.
		var lk := Motion.smooth(clampf((t - lift) / 0.9, 0.0, 1.0))
		if t >= lift and b["vis"]:
			var on_table: Vector3 = gt * bar_pos
			var held: Vector3 = man.bone_world("head") + fwd * 0.55 + Vector3(0, -0.6 - 0.03 * sin(clampf(t - lift - 0.9, 0.0, 9.0) * 3.0) * exp(-(t - lift - 0.9)), 0)
			var reach := Motion.smooth(clampf((t - lift) / 0.35, 0.0, 1.0))
			var hp: Vector3 = on_table.lerp(held, lk)
			man.aim_hand("r", hp + right * 0.1, reach)
			man.aim_hand("l", hp - right * 0.1, reach)
			if lk > 0.02:
				_bar.position = inv * hp
				_bar.rotation = Vector3(0, man.rotation.y - gt.basis.get_euler().y, 0)
		# The cap on his head.
		var head: Vector3 = man.bone_world("head")
		var hd: Dictionary = ctx["point"].call(man_id + ".head")
		# The ".head" anchor is the drawn toon head's centre; the cap sits on its crown.
		_cap.position = inv * (Vector3(hd.get("pos", man.bone_world("head"))) + Vector3(0, 0.25, 0) - fwd * 0.03)
		_cap.rotation = Vector3(0, man.rotation.y - gt.basis.get_euler().y, 0)
		_cap.visible = true
	else:
		_cap.visible = false
		_paper.visible = false
	_glint.position = _bar.position + Vector3(0, 0.2, 0.1)
	_glint.light_energy = (0.12 + 0.06 * sin(t * 5.0)) if (_bar.visible and not evening) else 0.0
	# Evening: the sun is gone, the room is dark; the sky beyond the rooftops glows over the burning docks.
	var ev := clampf((t - dusk) / 0.5, 0.0, 1.0)
	_sun.light_energy = 22.0 * (1.0 - ev)
	_lamp.light_energy = 0.0
	_sky_day.visible = true
	_sky_night.visible = false
	_sky_mat.albedo_color = Color("#a8b8cc").lerp(Color("#c2461a"), ev)
	_back.light_energy = ev * (3.2 + 0.6 * sin(t * 7.0) + 0.4 * sin(t * 13.0))
	FX.begin(_fire)
	if ev > 0.0:
		for k in 9:
			FX.flames(_fire, Vector3(-30.0 + k * 9.0, 5.5, -60.0 - (k % 3) * 25.0), Vector2(5.0, 2.0), t, {"count": 6, "height": 10.0,
				"size": 10.0, "heat": 1.0, "seed": 1200 + k})
	for j in 26:
		var u := float(j) / 26.0
		var p := Vector3(4.0 + (_h(j, 31) - 0.5) * 12.0 - u * 12.0, -8.0 + u * 95.0, -105.0 + (_h(j, 32) - 0.5) * 8.0)
		FX.add(_smoke, p, 22.0 + u * 26.0, Color(_h(j, 33), ev * 0.9 * (1.0 - u), 0.7 + 0.25 * (1.0 - u), 0.95))
	FX.finish(_smoke, cam_l, t)
	FX.finish(_fire, cam_l, t)
	return {"hole": gt * HOLE, "table": gt * (TABLE + Vector3(0, TOP, 0)), "bar": gt * _bar.position, "window": gt * Vector3(0.6, 2.2, -3.1)}
