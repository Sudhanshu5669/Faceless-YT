## No. 2 hold of the Fort Stikine, inside: a steel cavern 18 m wide, 16 m long, 9 m deep, ribbed with frames, lit by
## shafts of sun through the open hatch above. Raw cotton bales fill the bottom; on them, crates of munitions, torpedoes
## on chocks, moored mines, pallets of shells; in the after corner, the strong-cage with the gold crates.
## Over the afternoon: smoke seeps from deep in the cotton; fire-hose water cascades through the hatch into steam; the
## hidden fire glows red between the bales; shells start to go off (flashes, sparks, bursts).
##
## Local frame: the hold floor at y 0, centred; the hatch opening at y 9, x -4..4, z -3..3; the gold cage at
## (-6.5, 0, -5.5); cameras inside looking around. Cotton fills y 0..2.2; cargo above.
##
## params: smoke t (smoke seeping), water t (hoses), glow t (the fire showing), pops t (shells exploding)
## anchors: hatch, gold, bales, crates, glow
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Paths = preload("res://scripts/core/paths.gd")

const SK := "incoming/bombay_gold/sketchfab/"
const PH := "incoming/bombay_gold/polyhaven/"
const PH0 := "incoming/polyhaven_pokhran/models/"
const W := 18.0
const L := 16.0
const D := 9.0
const GOLD := Vector3(-6.0, 2.2, -5.0)
const GLOW := Vector3(2.5, 1.0, 3.0)

var FX
var _p := {}
var _smoke
var _fire
var _spray
var _sun: SpotLight3D
var _sun2: SpotLight3D
var _glow: OmniLight3D
var _pop: OmniLight3D
var _gold_light: OmniLight3D
var _sparks: MultiMesh


func _h(i: int, salt: int) -> float:
	var x := sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453
	return x - floor(x)


func _tex(name: String, scale: float, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var b := PH + "textures/" + name
	return Kit.textured(b + "_diff_2k.jpg", b + "_nor_gl_2k.jpg", b + "_rough_2k.jpg", Vector3.ONE * scale, tint, true)


func _model(root: Node3D, rel: String, pos: Vector3, yaw: float, s: float) -> Node3D:
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
	root.name = String(g.get("id", "hold"))
	var steel := _tex("rusty_metal_02", 0.25, Color(0.55, 0.5, 0.46))
	var frame_m := Kit.mat("#2c2824", 0.6, 0.6)
	# The shell: floor, sides, ends, the deck overhead with the hatch opening.
	Kit.box(root, Vector3(W, 0.3, L), Vector3(0, -0.15, 0), steel)
	for sx: float in [-1.0, 1.0]:
		Kit.box(root, Vector3(0.3, D, L), Vector3(sx * W * 0.5, D * 0.5, 0), steel)
		for k in 22:
			var z := -L * 0.5 + 0.4 + k * 0.72
			Kit.box(root, Vector3(0.35, D, 0.14), Vector3(sx * (W * 0.5 - 0.3), D * 0.5, z), frame_m)
		Kit.box(root, Vector3(0.6, 0.3, L), Vector3(sx * (W * 0.5 - 0.45), 5.2, 0), frame_m)
	for sz: float in [-1.0, 1.0]:
		Kit.box(root, Vector3(W, D, 0.3), Vector3(0, D * 0.5, sz * L * 0.5), steel)
		for k in 14:
			Kit.box(root, Vector3(0.16, D, 0.3), Vector3(-W * 0.5 + 0.6 + k * 1.3, D * 0.5, sz * (L * 0.5 - 0.25)), frame_m)
	# The deck overhead: plating around the hatch (x -4..4, z -3..3), beams across.
	Kit.box(root, Vector3(W, 0.35, (L - 6.0) * 0.5), Vector3(0, D, -1.5 - (L - 6.0) * 0.25 - 1.5), steel)
	Kit.box(root, Vector3(W, 0.35, (L - 6.0) * 0.5), Vector3(0, D, 1.5 + (L - 6.0) * 0.25 + 1.5), steel)
	Kit.box(root, Vector3((W - 8.0) * 0.5, 0.35, 6.0), Vector3(-4.0 - (W - 8.0) * 0.25, D, 0), steel)
	Kit.box(root, Vector3((W - 8.0) * 0.5, 0.35, 6.0), Vector3(4.0 + (W - 8.0) * 0.25, D, 0), steel)
	for k in 5:
		Kit.box(root, Vector3(W, 0.5, 0.25), Vector3(0, D - 0.4, -6.0 + k * 3.0), frame_m)
	for sx: float in [-1.0, 1.0]:
		Kit.box(root, Vector3(0.3, 1.2, 6.6), Vector3(sx * 4.15, D + 0.6, 0), frame_m)
	for sz: float in [-1.0, 1.0]:
		Kit.box(root, Vector3(8.6, 1.2, 0.3), Vector3(0, D + 0.6, sz * 3.15), frame_m)
	# A steel ladder down the forward bulkhead.
	for k in 26:
		Kit.rod(root, Vector3(3.0, 0.3 + k * 0.33, L * 0.5 - 0.4), Vector3(3.6, 0.3 + k * 0.33, L * 0.5 - 0.4), 0.02, frame_m, 5)
	Kit.box(root, Vector3(0.06, D, 0.06), Vector3(2.97, D * 0.5, L * 0.5 - 0.4), frame_m)
	Kit.box(root, Vector3(0.06, D, 0.06), Vector3(3.63, D * 0.5, L * 0.5 - 0.4), frame_m)
	# Raw cotton: three layers of jute bales wall to wall.
	var jute := Kit.mat("#cdbb94", 0.95)
	var band := Kit.mat("#3a3632", 0.5, 0.7)
	var rng := Kit.rng("hold_bales")
	var bale: Mesh = Kit.slab(root, Vector3(1.36, 0.68, 0.86), 0.14, Vector3(0, -50, 0), jute).mesh
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = bale
	var spots: Array = []
	for lay in 3:
		for ix in 12:
			for iz in 17:
				if ix == 0 and iz < 15:
					continue   # an access aisle along the port side
				spots.append(Vector3(-W * 0.5 + 0.9 + ix * 1.4, 0.36 + lay * 0.71, -L * 0.5 + 0.6 + iz * 0.9))
	mm.instance_count = spots.size()
	for i in spots.size():
		var p: Vector3 = spots[i]
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf_range(-0.04, 0.04)), p + Vector3(rng.randf_range(-0.04, 0.04), 0, rng.randf_range(-0.03, 0.03))))
		mm.set_instance_color(i, Color(1, 1, 1).lerp(Color(0.85, 0.8, 0.7), rng.randf()))
	var bmi := MultiMeshInstance3D.new()
	bmi.multimesh = mm
	bmi.material_override = FX.bale_material()
	root.add_child(bmi)
	# Munitions on the cotton: rows of crates, torpedoes on chocks, mines, pallets of shells.
	var top := 2.15
	for ix in 5:
		for iz in 3:
			var c := Vector3(-3.5 + ix * 2.1, top, 2.0 + iz * 1.6)
			for lay in 2 + (ix + iz) % 2:
				var crate := PH0 + ("wooden_military_crate/wooden_military_crate_2k.gltf" if (ix + lay) % 2 == 0 else "old_military_crate/old_military_crate_2k.gltf")
				_model(root, crate, c + Vector3(0, lay * 0.55, 0), 0.0 if lay % 2 == 0 else PI * 0.5, 1.6)
	for k in 3:
		var tp := Vector3(-2.0 + k * 0.95, top + 0.28, -2.2)
		var tm := _model(root, SK + "submarine_torpedo_weapon.glb", tp, PI * 0.5, 32.3)
		tm.rotation = Vector3(0, PI * 0.5, 0)
		for cz: float in [-2.0, 2.0]:
			Kit.box(root, Vector3(0.9, 0.22, 0.3), Vector3(tp.x, top + 0.1, tp.z + cz), Kit.mat("#6a4a2e", 0.9))
	for k in 4:
		_model(root, SK + "old_sea_mine.glb", Vector3(4.0 + (k % 2) * 1.3, top, -3.5 + (k / 2) * 1.4), k * 0.7, 1.1)
	for k in 3:
		var pp := Vector3(6.4, top, 1.5 + k * 1.5)
		Kit.box(root, Vector3(1.5, 0.12, 1.1), pp + Vector3(0, 0.06, 0), Kit.mat("#8a6a44", 0.9))
		for r in 3:
			for c2 in 4:
				var s := _model(root, SK + "artillery_shell.glb", pp + Vector3(-0.5 + c2 * 0.33, 0.22 + r * 0.17, 0), PI * 0.5, 0.6)
				s.rotation.y = PI * 0.5
	# The gold cage: a steel-mesh strong-cage in the after corner, crates of bullion inside.
	var cage := Kit.mat("#3c3a38", 0.5, 0.8)
	for k in 9:
		Kit.box(root, Vector3(0.05, 2.4, 0.05), GOLD + Vector3(-2.0 + k * 0.5, 1.2, 2.0), cage)
		Kit.box(root, Vector3(0.05, 2.4, 0.05), GOLD + Vector3(2.0, 1.2, -2.0 + k * 0.5), cage)
	for k in 6:
		Kit.box(root, Vector3(4.0, 0.04, 0.04), GOLD + Vector3(0, 0.1 + k * 0.45, 2.0), cage)
		Kit.box(root, Vector3(0.04, 0.04, 4.0), GOLD + Vector3(2.0, 0.1 + k * 0.45, 0), cage)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("#ffd84a")
	gold.metallic = 1.0
	gold.roughness = 0.12
	gold.emission_enabled = true
	gold.emission = Color("#ffcf50")
	gold.emission_energy_multiplier = 0.9
	for k in 12:
		var cp := GOLD + Vector3(-1.4 + (k % 4) * 0.72, (k / 8) * 0.32, -1.2 + ((k / 4) % 2) * 0.9)
		_model(root, PH + "models/wooden_crate_01/wooden_crate_01_2k.gltf", cp, 0.0, 0.85)
	var open_c := GOLD + Vector3(0.6, 0.62, 0.9)
	Kit.box(root, Vector3(0.66, 0.24, 0.32), open_c + Vector3(0, 0.12, 0), Kit.mat("#6e5034", 0.85))
	for bx in 4:
		for bz in 2:
			for by in 2:
				Kit.box(root, Vector3(0.13, 0.05, 0.12), open_c + Vector3(-0.23 + bx * 0.155, 0.2 + by * 0.055, -0.07 + bz * 0.14), gold)
	Kit.box(root, Vector3(0.68, 0.03, 0.34), open_c + Vector3(0.55, 0.05, 0.25), Kit.mat("#6e5034", 0.85), Vector3(0.2, 0.6, 0.5))
	_gold_light = Kit.omni(root, open_c + Vector3(0.2, 0.7, 0.6), "#ffcf70", 1.6, 3.2, false, 0.4)
	# Light: the sun through the hatch (a hard shaft into the haze), a bounce, a dim work lamp.
	_sun = Kit.spot(root, Vector3(-3.0, 22.0, 3.5), Vector3(1.0, 2.0, -1.0), "#ffe6bc", 40.0, 40.0, 14.0, true, 12.0)
	_sun2 = Kit.spot(root, Vector3(2.5, 22.0, -3.0), Vector3(-0.5, 2.0, 1.5), "#ffe0b0", 16.0, 40.0, 10.0, true, 8.0)
	Kit.omni(root, Vector3(0, 3.5, 0), "#c8a678", 0.6, 14.0, false, 0.2)
	Kit.omni(root, Vector3(-6.0, 6.5, 6.0), "#ffd8a0", 0.8, 8.0, true, 0.6)
	Kit.omni(root, Vector3(-7.8, 2.6, 2.0), "#ffcf90", 1.4, 7.0, true, 0.6)
	Kit.cyl(root, 0.1, 0.2, 0.25, Vector3(-8.6, 2.9, 2.0), Kit.lit("#ffd8a0", 3.0), 12, Vector3(0, 0, PI * 0.5))
	Kit.cyl(root, 0.12, 0.25, 0.3, Vector3(-6.0, 6.8, 6.0), Kit.lit("#ffd8a0", 3.0), 12)
	_glow = Kit.omni(root, GLOW, "#ff4a10", 0.0, 9.0, false, 1.5)
	_pop = Kit.omni(root, Vector3(2.0, 4.0, 0.0), "#ffd090", 0.0, 22.0, true, 2.0)
	var sm := BoxMesh.new()
	sm.size = Vector3(0.02, 0.02, 0.2)
	_sparks = MultiMesh.new()
	_sparks.transform_format = MultiMesh.TRANSFORM_3D
	_sparks.mesh = sm
	_sparks.instance_count = 200
	_sparks.visible_instance_count = 0
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = _sparks
	smi.material_override = Kit.lit("#ffcf6a", 6.0)
	smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(smi)
	_smoke = FX.layer(root, 700, "smoke")
	_fire = FX.layer(root, 300, "fire")
	_spray = FX.layer(root, 600, "spray")
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var inv := gt.affine_inverse()
	var cam := node.get_viewport().get_camera_3d()
	var cam_l: Vector3 = (inv * cam.global_position) if cam else Vector3(0, 4, 8)
	var smoke_t := float(_p.get("smoke", 1e9))
	var water_t := float(_p.get("water", 1e9))
	var glow_t := float(_p.get("glow", 1e9))
	var pops_t := float(_p.get("pops", 1e9))
	FX.begin(_smoke)
	FX.begin(_fire)
	FX.begin(_spray)
	# Smoke seeps up between the bales and pools under the deck.
	if t > smoke_t - 3.0:
		var thick := clampf((t - smoke_t) / 20.0, 0.0, 1.0)
		for k in 6:
			var src := Vector3(-5.0 + k * 2.2, 2.2, -4.0 + (k % 3) * 3.0)
			FX.plume(_smoke, src, t, {"t0": smoke_t - 3.0, "rate": 1.2 + thick * 2.5, "life": 9.0, "rise": 0.7, "spread": 1.0,
				"grow": 0.4, "size0": 1.4, "wind": Vector3(0.1, 0, 0.05), "alpha": 0.32 + thick * 0.35, "dark": 0.3 + thick * 0.4,
				"seed": 400 + k, "slow": 0.7})
	# Hose water cascades through the hatch and flashes into steam.
	if t > water_t:
		for k in 3:
			var from := Vector3(-2.0 + k * 2.0, D + 1.5, -1.0 + k * 0.8)
			FX.jet(_spray, from, Vector3(0.4 - k * 0.3, -2.0, 0.2), t, {"t0": water_t + k * 0.2, "rate": 70.0, "life": 1.4,
				"size0": 0.4, "grow": 1.6, "alpha": 0.45, "seed": 500 + k, "floor": 2.2, "scatter": 0.6})
		FX.plume(_smoke, Vector3(0, 2.4, 0), t, {"t0": water_t, "rate": 6.0, "life": 6.0, "rise": 1.4, "spread": 3.0, "grow": 1.0,
			"size0": 2.0, "wind": Vector3(0, 0, 0), "alpha": 0.4, "dark": 0.0, "seed": 520})
	# The hidden fire: a red glow deep between the bales.
	var gk := clampf((t - glow_t) / 2.0, 0.0, 1.0)
	_glow.light_energy = gk * (5.0 + 2.0 * sin(t * 11.0) + 1.5 * sin(t * 23.0))
	if gk > 0.0:
		FX.flames(_fire, GLOW + Vector3(0, -0.3, 0), Vector2(0.8, 0.5), t, {"t0": glow_t, "ramp": 2.0, "count": 6, "height": 0.6, "size": 0.9, "heat": 0.7, "seed": 600})
	# Shells going off: flashes, a burst of sparks, a puff of fire, each in its own place.
	_sparks.visible_instance_count = 0
	_pop.light_energy = 0.0
	if t > pops_t:
		var period := 0.55
		var k := int(floor((t - pops_t) / period))
		var a := fmod(t - pops_t, period)
		var c := Vector3(-4.0 + _h(k, 1) * 9.0, 2.6 + _h(k, 2) * 1.0, -3.0 + _h(k, 3) * 7.0)
		_pop.position = c + Vector3(0, 0.8, 0)
		_pop.light_energy = 140.0 * exp(-a * 7.0) + 12.0
		var n := 0
		for i in 60:
			var v := Vector3(_h(i, 10 + k) - 0.5, _h(i, 11 + k) * 0.9 + 0.2, _h(i, 12 + k) - 0.5).normalized() * (6.0 + 8.0 * _h(i, 13 + k))
			var p := c + v * a + Vector3(0, -4.9 * a * a, 0)
			var b := Basis.looking_at(v.normalized() + Vector3(0, 0.001, 0), Vector3.UP if absf(v.normalized().y) < 0.99 else Vector3.FORWARD)
			_sparks.set_instance_transform(n, Transform3D(b, p))
			n += 1
		_sparks.visible_instance_count = n
		FX.add(_fire, c + Vector3(0, 0.4, 0), 1.5 + a * 4.0, Color(_h(k, 20), clampf(1.3 - a * 2.0, 0.0, 1.3), 0, clampf(1.0 - a * 1.6, 0.0, 1.0)))
		FX.plume(_smoke, c, t, {"t0": pops_t, "rate": 3.0, "life": 5.0, "rise": 1.6, "spread": 2.0, "grow": 1.2, "size0": 1.6,
			"alpha": 0.6, "dark": 0.8, "glow": 0.6, "seed": 700})
		FX.flames(_fire, GLOW + Vector3(-1.0, 0.4, -1.0), Vector2(3.0, 2.0), t, {"t0": pops_t, "ramp": 2.0, "count": 12, "height": 2.4, "size": 2.0, "seed": 610})
	# The sun shaft dims as the smoke thickens.
	var dim := 1.0 - clampf((t - smoke_t) / 30.0, 0.0, 0.6)
	_sun.light_energy = 40.0 * dim
	_sun2.light_energy = 16.0 * dim
	_gold_light.light_energy = 1.6 + 0.5 * sin(t * 1.7)
	FX.finish(_smoke, cam_l, t)
	FX.finish(_fire, cam_l, t)
	FX.finish(_spray, cam_l, t)
	return {"hatch": gt * Vector3(0, D, 0), "gold": gt * (GOLD + Vector3(0.6, 0.9, 0.9)), "bales": gt * Vector3(0, 1.4, 0),
		"crates": gt * Vector3(0, 3.0, 3.0), "glow": gt * GLOW}
