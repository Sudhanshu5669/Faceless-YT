## A Bombay street, 14 April 1944, late afternoon (Girgaum; with variant "dadar" a wider street 12 km out): three- and
## four-storey plastered buildings in faded yellow, cream, blue-grey and pink, wooden balconies with turned railings,
## green shutters, Mangalore-tile eaves, shopfronts with cloth awnings, tram rails, a handcart, gas lamps. Beyond the
## rooftops (toward -z) the black column of the docks. Gold bars tumble out of the sky, catching the sun; burning
## cotton falls on the roofs; with variant "dadar", the shockwave rolls up the street and a shop window bursts.
##
## Local frame: the street centre along z (x 0), the docks far toward -z; facades at x +-HALF; floor y 0. Cameras low
## in the street looking -z / up.
##
## params:
##   variant  "girgaum" | "dadar"
##   gold     {"t0": t, "hero": t}   bars falling from t0; one hero bar falls past the lens on `hero`
##   cotton   {"t0": t}   burning bales arcing over the roofs from t0
##   column   true       the smoke column over the docks
##   shock    t          (dadar) the shockwave: dust front up the street, the shop window bursts, signs swing
## anchors: sky, street, balcony_l, balcony_r, shop, column
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Paths = preload("res://scripts/core/paths.gd")

const PH := "incoming/bombay_gold/polyhaven/"

var FX
var _p := {}
var HALF := 7.0
var _bars: MultiMesh
var _hero: MeshInstance3D
var _smoke
var _fire
var _shards: MultiMesh
var _glass: MeshInstance3D
var _sign: Node3D
var _gold_mat: StandardMaterial3D
var _bales: MultiMesh


func _h(i: int, salt: int) -> float:
	var x := sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453
	return x - floor(x)


func _tex(name: String, scale: float, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var b := PH + "textures/" + name
	return Kit.textured(b + "_diff_2k.jpg", b + "_nor_gl_2k.jpg", b + "_rough_2k.jpg", Vector3.ONE * scale, tint, true)


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	FX = load(Paths.repo_path("episodes/bombay_gold/gags/fx.gd"))
	var dadar: bool = String(_p.get("variant", "girgaum")) == "dadar"
	HALF = 10.0 if dadar else 7.0
	var root := Node3D.new()
	root.name = String(g.get("id", "street"))
	var rng := Kit.rng("street_" + String(_p.get("variant", "girgaum")))
	# Road, tram rails, footpaths with kerbs.
	Kit.box(root, Vector3(HALF * 2.0, 0.2, 420), Vector3(0, -0.1, -150), _tex("cobblestone_floor_04", 0.5, Color(0.72, 0.68, 0.62)))
	for sx: float in [-1.0, 1.0]:
		Kit.box(root, Vector3(2.4, 0.18, 420), Vector3(sx * (HALF - 1.2), 0.09, -150), _tex("stone_pavers", 0.6, Color(0.8, 0.76, 0.7)))
	var rail := Kit.mat("#3c3834", 0.35, 0.85)
	for rx: float in [-0.75, 0.75]:
		Kit.box(root, Vector3(0.08, 0.05, 420), Vector3(rx - 1.6, 0.02, -150), rail)
		Kit.box(root, Vector3(0.08, 0.05, 420), Vector3(rx + 1.6, 0.02, -150), rail)
	# Buildings along both sides.
	var plasters := [_tex("yellow_plaster", 0.25, Color(0.96, 0.86, 0.62)), _tex("plastered_wall_04", 0.25, Color(0.9, 0.86, 0.78)),
		_tex("peeling_painted_wall", 0.25, Color(0.72, 0.8, 0.86)), _tex("worn_mossy_plasterwall", 0.25, Color(0.92, 0.78, 0.74)),
		_tex("white_plaster_rough_02", 0.25, Color(0.94, 0.9, 0.82))]
	var wood := _tex("weathered_brown_planks", 0.9, Color(0.6, 0.42, 0.3))
	var shutter_cols := [Kit.mat("#3e5c46", 0.8), Kit.mat("#5a3a26", 0.8), Kit.mat("#2e4a5e", 0.8)]
	var dark := Kit.mat("#14110e", 0.9)
	var tiles := _tex("clay_roof_tiles_02", 0.6)
	var awnings := [Kit.mat("#b8442e", 0.9), Kit.mat("#d8c8a0", 0.9), Kit.mat("#3c6a4a", 0.9), Kit.mat("#c89a3a", 0.9)]
	for side: float in [-1.0, 1.0]:
		var z := 16.0
		var k := 0
		while z > -320.0:
			var w := rng.randf_range(9.0, 13.0)
			var floors := rng.randi_range(3, 4)
			var fh := 3.5
			var h := 4.5 + floors * fh
			var cz := z - w * 0.5
			var fx := side * (HALF + 6.0)
			var mat: Material = plasters[(k + (0 if side < 0 else 2)) % plasters.size()]
			Kit.box(root, Vector3(12.0, h, w - 0.2), Vector3(fx, h * 0.5, cz), mat)
			# Cornice and the tiled eave.
			Kit.box(root, Vector3(0.6, 0.35, w), Vector3(side * (HALF + 0.2), h - 0.2, cz), Kit.mat("#d8ccb4", 0.8))
			Kit.box(root, Vector3(1.6, 0.18, w + 0.2), Vector3(side * (HALF - 0.3), h + 0.25, cz), tiles, Vector3(0, 0, side * 0.35))
			# Ground floor: shop opening, awning.
			Kit.box(root, Vector3(0.2, 3.0, w * 0.7), Vector3(side * (HALF - 0.02), 1.5, cz), dark)
			var aw := Kit.box(root, Vector3(1.8, 0.06, w * 0.75), Vector3(side * (HALF - 0.85), 3.55, cz), awnings[(k + int(side > 0)) % 4], Vector3(0, 0, side * 0.3))
			aw.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			# Upper floors: windows with shutters; a wooden balcony on floor 1 (and 2 on some).
			for f in floors:
				var y := 4.5 + f * fh + 1.6
				var nw := int(w / 3.2)
				for wi in nw:
					var wz := cz - w * 0.5 + (wi + 0.5) * (w / nw)
					Kit.box(root, Vector3(0.1, 1.9, 1.1), Vector3(side * (HALF - 0.02), y, wz), dark)
					var sh: Material = shutter_cols[(k + f + wi) % 3]
					Kit.box(root, Vector3(0.06, 1.9, 0.5), Vector3(side * (HALF - 0.08), y, wz - 0.82), sh)
					Kit.box(root, Vector3(0.06, 1.9, 0.5), Vector3(side * (HALF - 0.08), y, wz + 0.82), sh)
					Kit.ball(root, 0.56, Vector3(side * (HALF - 0.03), y + 0.95, wz), Kit.mat("#3a2e24", 0.8), 12, Vector3(0.1, 0.45, 1.0))
				if f == 0 or (f == 1 and k % 2 == 0):
					var by := 4.5 + f * fh
					Kit.box(root, Vector3(1.3, 0.18, w - 1.0), Vector3(side * (HALF - 0.65), by, cz), wood)
					Kit.box(root, Vector3(0.08, 0.1, w - 1.0), Vector3(side * (HALF - 1.28), by + 1.0, cz), wood)
					var nb := int((w - 1.0) / 0.22)
					for b in nb:
						Kit.box(root, Vector3(0.05, 0.9, 0.05), Vector3(side * (HALF - 1.28), by + 0.5, cz - (w - 1.0) * 0.5 + b * 0.22 + 0.1), wood)
					for b in 3:
						Kit.box(root, Vector3(0.1, 3.3, 0.1), Vector3(side * (HALF - 1.25), by + 1.65, cz - (w - 1.2) * 0.5 + b * (w - 1.2) * 0.5), wood)
			z -= w
			k += 1
	# A handcart and gas lamps.
	for k2 in 6:
		var lz := 8.0 - k2 * 26.0
		for sx: float in [-1.0, 1.0]:
			var lamp := Kit.model(PH + "models/street_lamp_01/street_lamp_01_2k.gltf")
			lamp.position = Vector3(sx * (HALF - 2.1), 0.18, lz + (13.0 if sx > 0 else 0.0))
			lamp.rotation.y = PI * 0.5 if sx > 0 else -PI * 0.5
			root.add_child(lamp)
	var cart := Node3D.new()
	cart.position = Vector3(-3.0, 0, -6.0)
	cart.rotation.y = 0.3
	root.add_child(cart)
	Kit.box(cart, Vector3(1.2, 0.08, 2.2), Vector3(0, 0.75, 0), wood)
	for sx: float in [-1.0, 1.0]:
		Kit.cyl(cart, 0.55, 0.55, 0.06, Vector3(sx * 0.66, 0.55, 0.2), Kit.mat("#5a3e2a", 0.8), 18, Vector3(0, 0, PI * 0.5))
		Kit.rod(cart, Vector3(sx * 0.45, 0.78, -1.1), Vector3(sx * 0.4, 0.95, -2.2), 0.04, wood, 6)
	for b in 4:
		Kit.box(cart, Vector3(0.5, 0.3, 0.4), Vector3(-0.3 + (b % 2) * 0.6, 0.95, -0.5 + (b / 2) * 0.6), Kit.mat("#9c8a6a", 0.9))
	# Dadar: a shopfront with a big plate-glass window and a hanging sign (the window bursts on the shock).
	if dadar:
		var sz := -14.0
		Kit.box(root, Vector3(0.3, 3.4, 6.0), Vector3(-HALF + 0.1, 1.7, sz), Kit.mat("#3a2a1c", 0.7))
		_glass = MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(5.0, 2.4)
		_glass.mesh = q
		var gm := StandardMaterial3D.new()
		gm.albedo_color = Color(0.72, 0.82, 0.88, 0.42)
		gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm.metallic = 0.6
		gm.roughness = 0.05
		_glass.material_override = gm
		_glass.position = Vector3(-HALF + 0.3, 1.9, sz)
		_glass.rotation.y = PI * 0.5
		root.add_child(_glass)
		for k3 in 3:
			var shelf := Kit.box(root, Vector3(1.2, 0.05, 5.0), Vector3(-HALF - 0.4, 0.9 + k3 * 0.6, sz), wood)
			for jx in 6:
				Kit.cyl(root, 0.08, 0.08, 0.3, Vector3(-HALF - 0.4, 1.08 + k3 * 0.6, sz - 2.0 + jx * 0.8), Kit.mat(["#c8642e", "#3a7a5a", "#d8b84a"][(jx + k3) % 3], 0.4), 10)
		var shard := PrismMesh.new()
		shard.size = Vector3(0.4, 0.5, 0.01)
		_shards = MultiMesh.new()
		_shards.transform_format = MultiMesh.TRANSFORM_3D
		_shards.mesh = shard
		_shards.instance_count = 140
		_shards.visible_instance_count = 0
		var smi := MultiMeshInstance3D.new()
		smi.multimesh = _shards
		smi.material_override = gm
		root.add_child(smi)
		Kit.omni(root, Vector3(-HALF - 1.2, 2.4, sz), "#ffcf8a", 3.0, 6.0, true, 0.4)
		_sign = Node3D.new()
		_sign.position = Vector3(-HALF + 1.4, 4.2, sz + 4.0)
		root.add_child(_sign)
		Kit.box(_sign, Vector3(0.06, 0.9, 1.6), Vector3(0, -0.5, 0), Kit.mat("#1e3a5a", 0.6))
	# Gold bars: a MultiMesh of tumbling bars, and a hero bar.
	_gold_mat = StandardMaterial3D.new()
	_gold_mat.albedo_color = Color("#f4c84a")
	_gold_mat.metallic = 1.0
	_gold_mat.roughness = 0.16
	_gold_mat.emission_enabled = true
	_gold_mat.emission = Color("#ffb428")
	_gold_mat.emission_energy_multiplier = 0.5
	var bar := BoxMesh.new()
	bar.size = Vector3(0.26, 0.08, 0.13)
	_bars = MultiMesh.new()
	_bars.transform_format = MultiMesh.TRANSFORM_3D
	_bars.mesh = bar
	_bars.instance_count = 160
	_bars.visible_instance_count = 0
	var bmi := MultiMeshInstance3D.new()
	bmi.multimesh = _bars
	bmi.material_override = _gold_mat
	bmi.extra_cull_margin = 500.0
	root.add_child(bmi)
	_hero = MeshInstance3D.new()
	_hero.mesh = bar
	_hero.material_override = _gold_mat
	_hero.scale = Vector3.ONE * 1.0
	root.add_child(_hero)
	var bb := BoxMesh.new()
	bb.size = Vector3(1.36, 0.68, 0.86)
	_bales = MultiMesh.new()
	_bales.transform_format = MultiMesh.TRANSFORM_3D
	_bales.mesh = bb
	_bales.instance_count = 16
	_bales.visible_instance_count = 0
	var bami := MultiMeshInstance3D.new()
	bami.multimesh = _bales
	bami.material_override = Kit.mat("#2a2018", 0.95)
	bami.extra_cull_margin = 300.0
	root.add_child(bami)
	_smoke = FX.layer(root, 700, "smoke")
	_smoke.mat.set_shader_parameter("fog_far", 12000.0)
	_smoke.mat.set_shader_parameter("lit_col", Color(0.78, 0.62, 0.46))
	_smoke.mat.set_shader_parameter("shade_col", Color(0.16, 0.13, 0.11))
	_fire = FX.layer(root, 300, "fire")
	return root


func _bar_pose(i: int, t: float, t0: float) -> Transform3D:
	# Bar i: drops from high over the street with a slight drift, tumbling; lands and lies still.
	var born := t0 + _h(i, 1) * 6.0
	var a := t - born
	var x := (_h(i, 2) - 0.5) * HALF * 2.4
	var z := -8.0 - _h(i, 3) * 90.0
	var y0 := 40.0 + _h(i, 4) * 50.0
	var vy := -6.0 - _h(i, 5) * 6.0
	var y := y0 + vy * a - 4.9 * a * a
	var spin := Vector3(_h(i, 6) * 9.0 + 3.0, _h(i, 7) * 7.0, _h(i, 8) * 8.0)
	var drift := Vector3(_h(i, 9) - 0.5, 0, _h(i, 10) - 0.5) * 4.0 * a
	var s := 1.6 + _h(i, 11) * 0.6
	if y <= 0.05:
		return Transform3D(Basis(Vector3.UP, _h(i, 12) * TAU).scaled(Vector3.ONE * s), Vector3(x, 0.05, z) + drift.limit_length(8.0))
	return Transform3D(Basis.from_euler(spin * a).scaled(Vector3.ONE * s), Vector3(x, y, z) + drift)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var inv := gt.affine_inverse()
	var cam := node.get_viewport().get_camera_3d()
	var cam_l: Vector3 = (inv * cam.global_position) if cam else Vector3(0, 2, 10)
	FX.begin(_smoke)
	FX.begin(_fire)
	# The column over the docks: towering, black at the base, sunlit brown above.
	var col := Vector3(40.0, 0.0, -1100.0)
	if _p.get("column", false):
		# A static-looking towering column: many big puffs stacked to ~700 m, drifting slowly, a spreading top.
		for j in 70:
			var u := float(j) / 70.0
			var y := u * 700.0 + _h(j, 900) * 30.0
			var w := 60.0 + u * 160.0
			var p := col + Vector3((_h(j, 901) - 0.5) * w - u * 120.0, y, (_h(j, 902) - 0.5) * w * 0.5) + Vector3(sin(t * 0.07 + j) * 6.0, 0, 0)
			var sz := 110.0 + u * 160.0 + _h(j, 903) * 60.0
			FX.add(_smoke, p, sz, Color(_h(j, 904), clampf(0.5 - u, 0.0, 0.5), 0.6 + 0.35 * (1.0 - u), 0.92))
	# Gold.
	var gd: Dictionary = _p.get("gold", {})
	var n := 0
	if not gd.is_empty() and t >= float(gd.get("t0", 1e9)):
		var t0 := float(gd["t0"])
		for i in _bars.instance_count:
			if t >= t0 + _h(i, 1) * 6.0:
				_bars.set_instance_transform(n, _bar_pose(i, t, t0))
				n += 1
	if gd.has("near") and t >= float(gd.get("t0", 1e9)):
		var c: Array = gd["near"]
		var cn := Vector3(float(c[0]), float(c[1]), float(c[2]))
		for j in 26:
			if n >= _bars.instance_count:
				break
			var born := float(gd["t0"]) + 2.0 + _h(j, 500) * 6.0
			var a := fmod(t - born, 2.2)
			if t < born:
				continue
			var p := cn + Vector3((_h(j, 501) - 0.5) * 4.0, 7.0 - 9.0 * a - 4.9 * a * a * 0.4, (_h(j, 502) - 0.5) * 3.0)
			if p.y < 0.05:
				continue
			_bars.set_instance_transform(n, Transform3D(Basis.from_euler(Vector3(a * 8.0, a * 3.0 + j, a * 6.0)).scaled(Vector3.ONE * 1.3), p))
			n += 1
	_bars.visible_instance_count = n
	# The hero bar: falls past the lens on `hero`, end over end, glinting.
	_hero.visible = false
	if gd.has("hero"):
		var ht := float(gd["hero"])
		var a := t - (ht - 0.55)
		if a > 0.0 and a < 1.6:
			var p := cam_l + Vector3(0.35, 3.2, -3.0) + Vector3(-0.1, -9.0, 0.6) * a + Vector3(0, -2.0 * a * a, 0)
			_hero.visible = true
			_hero.transform = Transform3D(Basis.from_euler(Vector3(a * 7.0, a * 2.0, a * 5.0)).scaled(Vector3.ONE * 1.3), p)
	# Burning cotton arcing over the roofs and landing on them.
	var cd: Dictionary = _p.get("cotton", {})
	var nb := 0
	if not cd.is_empty() and t >= float(cd.get("t0", 1e9)):
		var c0 := float(cd["t0"])
		for j in 16:
			var born := c0 - 2.0 + _h(j, 30) * 3.0
			var a := t - born
			if a < 0.0:
				continue
			var p0 := Vector3((_h(j, 31) - 0.5) * 40.0, 70.0 + _h(j, 32) * 30.0, -60.0 - _h(j, 33) * 120.0)
			var v := Vector3((_h(j, 34) - 0.5) * 6.0, -4.0, 10.0 + _h(j, 35) * 6.0)
			var p := p0 + v * a + Vector3(0, -4.9 * a * a, 0)
			var roof := 17.0 + _h(j, 36) * 4.0
			if p.y < roof:
				var land := p0 + v * maxf(a - 0.01, 0.0)
				p = Vector3(clampf(land.x, -HALF - 6.0, HALF + 6.0) + signf(land.x) * 6.0 if absf(land.x) < HALF else land.x, roof, land.z)
				FX.flames(_fire, p, Vector2(1.2, 1.2), t, {"t0": born, "ramp": 0.5, "count": 4, "height": 3.0, "size": 2.5, "seed": 900 + j})
				FX.plume(_smoke, p + Vector3(0, 1.5, 0), t, {"t0": born + 1.0, "rate": 1.5, "life": 6.0, "rise": 3.0, "spread": 1.0, "grow": 1.2,
					"size0": 2.5, "wind": Vector3(-0.8, 0, 0.5), "alpha": 0.7, "dark": 0.85, "glow": 0.3, "seed": 950 + j})
			else:
				var vel := (v + Vector3(0, -9.8 * a, 0)).normalized()
				_bales.set_instance_transform(nb, Transform3D(Basis.from_euler(Vector3(a * 2.0, a * 1.3 + j, a)).scaled(Vector3.ONE * 1.6), p))
				nb += 1
				FX.add(_fire, p, 5.0, Color(_h(j, 37), 1.1, 0, 1.0))
				FX.add(_fire, p - vel * 1.8, 4.0, Color(_h(j, 38), 0.9, 0, 0.85))
				FX.add(_fire, p - vel * 3.4, 3.0, Color(_h(j, 41), 0.6, 0, 0.6))
				for tr in 7:
					FX.add(_smoke, p - vel * (3.0 + tr * 2.6), 3.0 + tr * 1.1, Color(_h(j, 39 + tr), clampf(0.5 - tr * 0.08, 0.0, 0.5), 0.85, 0.75 - tr * 0.08))
	_bales.visible_instance_count = nb
	# Dadar: the shockwave front of dust rolling up the street, the window bursts, the sign swings.
	if _shards != null:
		var st := float(_p.get("shock", 1e9))
		var a := t - st
		_shards.visible_instance_count = 0
		_glass.visible = a < 0.0
		if a >= -0.6:
			var front := -150.0 + (a + 0.6) * 250.0
			for k in 14:
				FX.add(_smoke, Vector3((_h(k, 60) - 0.5) * HALF * 2.0, 1.0 + _h(k, 61) * 4.0, front + _h(k, 62) * 6.0), 5.0 + _h(k, 63) * 3.0,
					Color(_h(k, 64), 0, 0.1, clampf(0.6 - maxf(a, 0.0) * 0.3, 0.0, 0.6)))
		if a >= 0.0:
			var nn := 0
			for i in _shards.instance_count:
				var v := Vector3(2.0 + _h(i, 70) * 6.0, _h(i, 71) * 4.0 - 1.0, (_h(i, 72) - 0.5) * 6.0)
				var p := Vector3(-HALF + 0.3, 0.8 + _h(i, 73) * 2.2, -14.0 + (_h(i, 74) - 0.5) * 5.0) + v * a + Vector3(0, -4.9 * a * a, 0)
				if p.y < 0.03:
					p.y = 0.03
				_shards.set_instance_transform(nn, Transform3D(Basis.from_euler(Vector3(a * 9.0 * _h(i, 75), a * 7.0, a * 5.0 * _h(i, 76))).scaled(Vector3.ONE * (0.4 + _h(i, 77))), p))
				nn += 1
			_shards.visible_instance_count = nn
		_sign.rotation.x = (0.9 * exp(-a * 1.5) * sin(a * 7.0)) if a > 0.0 else 0.0
	FX.finish(_smoke, cam_l, t)
	FX.finish(_fire, cam_l, t)
	return {"sky": gt * Vector3(0, 40, -80), "street": gt * Vector3(0, 0, -10), "balcony_l": gt * Vector3(-HALF + 0.7, 4.7, -4.0),
		"balcony_r": gt * Vector3(HALF - 0.7, 4.7, -8.0), "shop": gt * Vector3(-HALF + 0.3, 1.9, -14.0), "column": gt * (col + Vector3(0, 300, 0))}
