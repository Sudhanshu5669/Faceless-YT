## Tibet: a monastery on a snowy cliff at dusk (whitewashed walls, maroon bands, a gilded roof, prayer flags strung
## down the slope), and inside, the forge: a stone room, a bed of coals, an anvil with an armour plate glowing orange,
## a monk's hammer striking with sparks; the mask lifted red-hot in tongs (it cools to iron as it comes up).
##
## Local frame: the monastery at (0, 0, -60) on a crag; the forge interior at (0, 0, 300): the anvil at (0, 0, 0)+FORGE,
## the coals at (-1.6, 0, -0.8)+FORGE. Cameras inside stand at +z looking -z.
##
## params:
##   strikes  [t, ...]   hammer blows on the plate (sparks, a flash, a ring)
##   mask     {"t": t, "white": t}   the tongs lift the glowing mask from the coals from t, carry it toward the lens;
##            at `white` the frame floods white (the moment itself is never shown)
## anchors: monastery, anvil, coals, mask
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Paths = preload("res://scripts/core/paths.gd")

const FORGE := Vector3(0, 0, 300)

static var _suit: GDScript


static func suit() -> GDScript:
	if _suit == null:
		_suit = GDScript.new()
		_suit.source_code = FileAccess.get_file_as_string(Paths.repo_path("library/gags/doom_suit.gd"))
		_suit.reload()
	return _suit


var _p := {}
var _hammer: Node3D
var _plate_mat: StandardMaterial3D
var _sparks: MultiMesh
var _flash: OmniLight3D
var _coal_light: OmniLight3D
var _tongs: Node3D
var _mask: MeshInstance3D
var _mask_mat: StandardMaterial3D
var _white: MeshInstance3D
var _white_mat: StandardMaterial3D
var _flags: Array[MeshInstance3D] = []


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "tibet"))
	var snow := Kit.mat("#e8edf4", 0.9)
	var rock := Kit.mat("#4a4a50", 0.95)
	var white := Kit.mat("#efe9dc", 0.85)
	var maroon := Kit.mat("#6a1a1e", 0.8)
	var gold := Kit.mat("#c8962e", 0.35, 0.85)
	var rng := Kit.rng("tibet")
	# Peaks, the crag, the monastery.
	Kit.box(root, Vector3(800, 1, 800), Vector3(0, -40, 0), snow)
	for i in 12:
		var a := -1.3 + i * 0.24
		var d := 300.0 + rng.randf() * 200.0
		var h := 200.0 + rng.randf() * 180.0
		var c := Vector3(sin(a) * d, -40, -cos(a) * d - 100.0)
		Kit.cyl(root, 0.0, h * 0.55, h, c + Vector3(0, h * 0.5, 0), rock, 8)
		Kit.cyl(root, 0.0, h * 0.22, h * 0.4, c + Vector3(0, h * 0.8, 0), snow, 8)
	Kit.cyl(root, 18.0, 46.0, 50.0, Vector3(0, -16, -62), rock, 10)
	Kit.cyl(root, 18.5, 20.0, 2.0, Vector3(0, 9.5, -62), snow, 14)
	for k in 4:
		var w := 22.0 - k * 4.0
		var y := 10.0 + k * 3.2
		Kit.box(root, Vector3(w, 3.2, w * 0.6), Vector3(0, y + 1.6, -64.0 - k * 0.5), white)
		Kit.box(root, Vector3(w + 0.2, 0.7, w * 0.6 + 0.2), Vector3(0, y + 2.85, -64.0 - k * 0.5), maroon)
		for j in int(w / 2.2):
			var win := Kit.box(root, Vector3(0.7, 1.0, 0.2), Vector3(-w * 0.5 + 1.2 + j * 2.2, y + 1.5, -64.0 - k * 0.5 + w * 0.3 + 0.05),
				Kit.lit("#ffb050", 2.0))
			win.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Kit.box(root, Vector3(7.0, 0.5, 4.5), Vector3(0, 23.6, -65.5), gold)
	Kit.cyl(root, 0.0, 1.2, 2.2, Vector3(0, 25.0, -65.5), gold, 12)
	# Prayer flags strung down from the roof to the snow.
	var cols := ["#2a6ad0", "#f2f2f2", "#d02a2a", "#2aa04a", "#f2c22e"]
	var flag := QuadMesh.new()
	flag.size = Vector2(0.9, 0.6)
	for line in 4:
		var a := Vector3(-8.0 + line * 5.0, 23.0, -62.0)
		var b := Vector3(-30.0 + line * 16.0, 10.5, -30.0)
		for i in 24:
			var u := (i + 0.5) / 24.0
			var p := a.lerp(b, u) + Vector3(0, -2.0 * sin(PI * u), 0)
			var f := MeshInstance3D.new()
			f.mesh = flag
			f.material_override = Kit.mat(cols[i % 5], 0.8)
			f.position = p + Vector3(0, -0.35, 0)
			f.rotation = Vector3(0, atan2(b.x - a.x, b.z - a.z) + PI / 2, 0)
			f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(f)
			_flags.append(f)
	# The forge interior.
	var fg := Node3D.new()
	fg.position = FORGE
	root.add_child(fg)
	var stone := Kit.textured("incoming/polyhaven_doom/textures/concrete_floor_worn_001_diff_2k.jpg", "", "", Vector3(1, 1, 1),
		Color("#7a6a5e"), true)
	Kit.box(fg, Vector3(10, 0.1, 10), Vector3(0, -0.05, 0), stone)
	Kit.box(fg, Vector3(10, 5, 0.4), Vector3(0, 2.5, -3.5), stone)
	for s: float in [-1.0, 1.0]:
		Kit.box(fg, Vector3(0.4, 5, 10), Vector3(s * 4.5, 2.5, 0), stone)
	Kit.box(fg, Vector3(10, 0.3, 10), Vector3(0, 5.0, 0), Kit.mat("#1a1412", 0.9))
	# A thangka-like cloth and butter lamps on the back wall.
	Kit.box(fg, Vector3(1.6, 2.2, 0.03), Vector3(2.2, 2.6, -3.28), maroon)
	Kit.box(fg, Vector3(1.3, 1.8, 0.035), Vector3(2.2, 2.6, -3.27), gold)
	for k in 7:
		Kit.ball(fg, 0.02, Vector3(1.6 + k * 0.2, 1.3, -3.1), Kit.lit("#ffc070", 6.0), 8, Vector3(1, 1.6, 1))
	Kit.omni(fg, Vector3(2.2, 1.5, -2.8), "#ffb060", 1.0, 4.0, false, 0.2)
	# The coals: a stone hearth, a glowing bed, a hood.
	Kit.box(fg, Vector3(1.6, 0.8, 1.2), Vector3(-1.6, 0.4, -0.8), stone)
	var coals := Kit.box(fg, Vector3(1.3, 0.12, 0.9), Vector3(-1.6, 0.82, -0.8), Kit.lit("#ff5a1a", 3.0))
	coals.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_coal_light = Kit.omni(fg, Vector3(-1.6, 1.3, -0.6), "#ff7a30", 6.0, 7.0, true, 1.0)
	Kit.cyl(fg, 0.3, 0.9, 1.4, Vector3(-1.6, 2.6, -0.9), Kit.mat("#2a2420", 0.7, 0.4), 4)
	# The anvil and the plate.
	var iron := Kit.mat("#2a2c2e", 0.4, 0.85)
	Kit.box(fg, Vector3(0.5, 0.55, 0.4), Vector3(0, 0.275, 0), iron)
	Kit.box(fg, Vector3(0.9, 0.2, 0.32), Vector3(0, 0.65, 0), iron)
	Kit.cyl(fg, 0.0, 0.14, 0.4, Vector3(0.62, 0.66, 0), iron, 10, Vector3(0, 0, -PI / 2))
	_plate_mat = Kit.lit("#ff6a20", 2.5)
	var plate := Kit.slab(fg, Vector3(0.5, 0.03, 0.28), 0.08, Vector3(-0.05, 0.77, 0), _plate_mat)
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The hammer (pivot at the striker's grip).
	_hammer = Node3D.new()
	_hammer.position = Vector3(0.35, 1.25, 0.45)
	fg.add_child(_hammer)
	Kit.rod(_hammer, Vector3.ZERO, Vector3(-0.35, -0.2, -0.3), 0.025, Kit.mat("#6a4a2a", 0.7), 8)
	Kit.box(_hammer, Vector3(0.1, 0.1, 0.22), Vector3(-0.38, -0.22, -0.33), iron, Vector3(0, -0.7, 0))
	# Sparks and the strike flash.
	var sm := BoxMesh.new()
	sm.size = Vector3(0.008, 0.008, 0.06)
	_sparks = MultiMesh.new()
	_sparks.transform_format = MultiMesh.TRANSFORM_3D
	_sparks.mesh = sm
	_sparks.instance_count = 120
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = _sparks
	smi.material_override = Kit.lit("#ffcf6a", 6.0)
	smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fg.add_child(smi)
	_flash = Kit.omni(fg, Vector3(0, 1.1, 0.3), "#ffd9a0", 0.0, 6.0, false, 0.8)
	# The tongs and the mask.
	_tongs = Node3D.new()
	fg.add_child(_tongs)
	Kit.rod(_tongs, Vector3(0, 0, 0), Vector3(0, 0, 0.9), 0.012, iron, 6)
	Kit.rod(_tongs, Vector3(0.04, 0, 0), Vector3(0.04, 0, 0.9), 0.012, iron, 6)
	_mask_mat = StandardMaterial3D.new()
	_mask_mat.albedo_color = Color("#3a3c3e")
	_mask_mat.metallic = 0.8
	_mask_mat.roughness = 0.45
	_mask_mat.emission_enabled = true
	_mask_mat.emission = Color("#ff5a1a")
	_mask_mat.emission_energy_multiplier = 3.0
	_mask = MeshInstance3D.new()
	_mask.mesh = suit().call("_mask", 1.0)
	_mask.material_override = _mask_mat
	_mask.scale = Vector3.ONE * 0.2
	_tongs.add_child(_mask)
	_mask.position = Vector3(0.02, 0, -0.12)
	# The white-out quad (fills the lens).
	_white_mat = StandardMaterial3D.new()
	_white_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_white_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_white_mat.albedo_color = Color(1, 1, 1, 0)
	_white_mat.no_depth_test = true
	_white = MeshInstance3D.new()
	var wq := QuadMesh.new()
	wq.size = Vector2(40, 40)
	_white.mesh = wq
	_white.material_override = _white_mat
	_white.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fg.add_child(_white)
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	for i in _flags.size():
		_flags[i].rotation.x = 0.25 * sin(t * 3.0 + i * 0.6)
	_coal_light.light_energy = 6.0 * (0.85 + 0.15 * sin(t * 7.0) * sin(t * 2.9))
	# Hammer blows: wind-up, strike, rebound.
	var hidden := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.001), Vector3(0, -20, 0))
	var swing := 0.0
	var last := -1e9
	for st in _p.get("strikes", []):
		var s := float(st)
		if t >= s - 0.5:
			var k := t - s
			if k < 0.0:
				swing = Motion.in_out(Motion.seg(t, s - 0.5, s - 0.15)) * 1.2 - Motion.in_cubic(Motion.seg(t, s - 0.15, s)) * 1.2
			elif k < 0.4:
				swing = Motion.impact(k, 0.25, 6.0, 12.0)
			if t >= s:
				last = s
	_hammer.rotation = Vector3(0, 0, swing)
	var k2 := t - last
	_flash.light_energy = 18.0 * exp(-k2 * 10.0) if k2 >= 0.0 and k2 < 1.0 else 0.0
	_plate_mat.emission_energy_multiplier = 2.5 + 3.0 * (exp(-k2 * 6.0) if k2 >= 0.0 and k2 < 1.0 else 0.0)
	var rng := RandomNumberGenerator.new()
	for i in _sparks.instance_count:
		rng.seed = 900 + i
		var k := t - last - rng.randf() * 0.1
		if last < -1e8 or k < 0.0 or k > 0.6:
			_sparks.set_instance_transform(i, hidden)
			continue
		var v := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.3, 1.2), rng.randf_range(-1, 1)).normalized() * rng.randf_range(2.0, 4.0)
		var p := FORGE + Vector3(-0.05, 0.8, 0) + v * k + Vector3(0, -4.9 * k * k, 0)
		_sparks.set_instance_transform(i, Transform3D(Basis.looking_at(v.normalized(), Vector3.UP), p - FORGE))
	# The mask: lifted from the coals in the tongs, carried toward the lens, cooling; then white.
	var md: Dictionary = _p.get("mask", {})
	var mt := float(md.get("t", 1e9))
	var lift := Motion.in_out(Motion.seg(t, mt, mt + 2.0))
	var from := Vector3(-1.6, 0.95, -0.8)
	var to := Vector3(-0.1, 1.25, 0.9)
	var pos := from.lerp(to, lift) + Vector3(0, 0.25 * sin(PI * lift), 0)
	_tongs.position = pos + Vector3(0, 0, -0.45)
	_tongs.rotation = Vector3(0.1, 0.4 * (1.0 - lift), 0)
	_mask_mat.emission_energy_multiplier = 3.0 * (1.0 - 0.6 * lift)
	var wt := float(md.get("white", 1e9))
	var wa := Motion.in_cubic(Motion.seg(t, wt - 0.25, wt))
	_white_mat.albedo_color = Color(1, 0.97, 0.9, wa)
	_white.visible = wa > 0.0
	if _white.visible and ctx.has("point"):
		_white.position = to + Vector3(0, 0, 0.4)
	return {"monastery": node.global_transform * Vector3(0, 18, -62), "anvil": node.global_transform * (FORGE + Vector3(0, 0.8, 0)),
		"coals": node.global_transform * (FORGE + Vector3(-1.6, 0.9, -0.8)), "mask": node.global_transform * (FORGE + pos)}
