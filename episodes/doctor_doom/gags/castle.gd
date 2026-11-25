## Castle Doom, Latveria. Inside: a gothic nave of towering stone columns, green banners bearing Doom's mask, iron
## braziers burning down both sides, a green carpet to a stepped dais and an iron throne with a high spiked back, tall
## lancet windows of moonlight that flare with lightning, the great doors at the far end. Outside (at x 400): the
## castle on a crag in a storm, towers and lit windows, the village lights below.
##
## Local frame: the throne at (0, DAIS, -26) facing +z; the carpet runs down the nave to the doors at z +14; columns at
## x +-5; cameras in the nave stand toward +z looking -z. The exterior castle sits at (400, 0, 0) facing +z.
##
## params:
##   doors     t   the great doors swing open (out of the dark, light floods in behind)
##   lightning [t, ...]   flashes through the windows (and over the exterior)
##   pop       {"actor": id, "t": t}   that actor's (a Doombot's) head pops off in sparks, wires showing
##   hands     {"t": t}   the gauntlet reveal for the hands shot: a glowing reactor (right) and a green spell (left),
##             drawn in front of the throne at (0, DAIS + 1.4, -24)
##   flag      {"t": t}   the Latverian flag unrolls down in front of the gate (the immunity gag), the portcullis drops
## anchors: throne, doors, hands, gate, window
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Paths = preload("res://scripts/core/paths.gd")

const DAIS := 1.2
const THRONE := Vector3(0, DAIS, -26)
const DOORS_Z := 14.0
const EXT := Vector3(400, 0, 0)
const GATE := Vector3(0, 0, 40.0)        # the outer gate court for the immunity gag (beyond the doors)

static var _suit: GDScript


static func suit() -> GDScript:
	if _suit == null:
		_suit = GDScript.new()
		_suit.source_code = FileAccess.get_file_as_string(Paths.repo_path("library/gags/doom_suit.gd"))
		_suit.reload()
	return _suit


var _p := {}
var _doors: Array[Node3D] = []
var _door_light: SpotLight3D
var _flash: Array[Light3D] = []
var _fires: Array[MeshInstance3D] = []
var _fire_lights: Array[OmniLight3D] = []
var _hands: Node3D
var _reactor: Node3D
var _spell_light: OmniLight3D
var _spell: Node3D
var _reactor_light: OmniLight3D
var _sparks: MultiMesh
var _flag: Node3D
var _portcullis: Node3D
var _windows: Array[MeshInstance3D] = []
var _win_mat: StandardMaterial3D


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "castle"))
	var stone := Kit.textured("incoming/polyhaven_doom/textures/concrete_floor_worn_001_diff_2k.jpg",
		"incoming/polyhaven_doom/textures/concrete_floor_worn_001_nor_gl_2k.jpg",
		"incoming/polyhaven_doom/textures/concrete_floor_worn_001_rough_2k.jpg", Vector3(2, 2, 1), Color("#6e7270"), true)
	var dark_stone := Kit.mat("#2a2c2e", 0.85)
	var iron := Kit.mat("#2b2e31", 0.45, 0.8)
	var green := Kit.mat("#1f5229", 0.85)
	var gold := Kit.mat("#a88a3a", 0.35, 0.8)
	# The nave: floor, walls, a vault far up.
	Kit.box(root, Vector3(22, 0.2, 48), Vector3(0, -0.1, -6), stone)
	for s: float in [-1.0, 1.0]:
		Kit.box(root, Vector3(1, 18, 48), Vector3(s * 10.5, 9, -6), stone)
	Kit.box(root, Vector3(22, 18, 1), Vector3(0, 9, -30.5), stone)
	Kit.box(root, Vector3(22, 1, 48), Vector3(0, 18.5, -6), dark_stone)
	# Ribs of the vault and the columns, every 5 m.
	for k in 9:
		var z := 10.0 - k * 4.5
		for s: float in [-1.0, 1.0]:
			Kit.cyl(root, 0.7, 0.8, 14.0, Vector3(s * 5.0, 7.0, z), stone, 16)
			Kit.box(root, Vector3(1.9, 0.6, 1.9), Vector3(s * 5.0, 0.3, z), dark_stone)
			Kit.box(root, Vector3(1.7, 0.5, 1.7), Vector3(s * 5.0, 14.2, z), dark_stone)
			# Banners: green cloth with a silver mask emblem.
			var bn := Node3D.new()
			bn.position = Vector3(s * 5.0 - s * 0.85, 9.5, z)
			bn.rotation = Vector3(0, s * PI / 2, 0)
			root.add_child(bn)
			Kit.box(bn, Vector3(1.4, 5.5, 0.04), Vector3(0, -2.6, 0), green)
			Kit.box(bn, Vector3(1.5, 0.1, 0.08), Vector3(0, 0.15, 0), gold)
			var em := MeshInstance3D.new()
			em.mesh = suit().call("_mask", 1.0)
			em.material_override = Kit.mat("#b9bec2", 0.4, 0.7)
			em.scale = Vector3(0.42, 0.48, 0.08)
			em.position = Vector3(0, -1.6, 0.04)
			bn.add_child(em)
		Kit.box(root, Vector3(10.6, 0.5, 0.8), Vector3(0, 14.8, z), dark_stone)
	# Lancet windows high in the walls: moonlit blue, flaring white on lightning.
	_win_mat = Kit.lit("#3a5590", 0.8)
	for k in 8:
		var z := 8.0 - k * 4.5
		for s: float in [-1.0, 1.0]:
			var w := Kit.box(root, Vector3(0.1, 5.0, 1.4), Vector3(s * 10.0, 9.5, z), _win_mat)
			w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_windows.append(w)
		var moon := Kit.spot(root, Vector3(-14.0, 16.0, z), Vector3(0, 0, z - 2.0), "#7f9cff", 6.0, 30.0, 18.0, true, 1.4)
		_flash.append(moon)
	# The carpet and the dais with its steps; the throne.
	Kit.box(root, Vector3(3.2, 0.03, 40), Vector3(0, 0.015, -4), Kit.mat("#174a22", 0.95))
	for k in 4:
		Kit.box(root, Vector3(9.0 - k * 1.2, DAIS / 4.0, 6.0 - k * 0.8), Vector3(0, DAIS / 8.0 + k * DAIS / 4.0, -26.0 + k * 0.1), dark_stone)
	var th := Node3D.new()
	th.position = THRONE
	root.add_child(th)
	Kit.box(th, Vector3(1.5, 0.5, 1.2), Vector3(0, 0.25, 0), iron)
	Kit.box(th, Vector3(1.5, 0.12, 1.1), Vector3(0, 0.55, 0.02), green)
	Kit.box(th, Vector3(1.7, 4.6, 0.3), Vector3(0, 2.3, -0.55), iron)
	for s: float in [-1.0, 1.0]:
		Kit.box(th, Vector3(0.2, 1.0, 1.2), Vector3(s * 0.85, 0.75, 0), iron)
		Kit.ball(th, 0.13, Vector3(s * 0.85, 1.3, 0.5), gold, 12)
	for k in 5:
		var x := -0.7 + k * 0.35
		var hgt := 0.6 + 0.5 * (1.0 - absf(x) / 0.7)
		Kit.cyl(th, 0.0, 0.09, hgt, Vector3(x, 4.6 + hgt * 0.5, -0.55), iron, 8)
	var em2 := MeshInstance3D.new()
	em2.mesh = suit().call("_mask", 1.0)
	em2.material_override = gold
	em2.scale = Vector3(0.5, 0.56, 0.12)
	em2.position = Vector3(0, 3.6, -0.38)
	th.add_child(em2)
	Kit.spot(root, THRONE + Vector3(0, 9, 5), THRONE + Vector3(0, 1.2, 0), "#9ff5b0", 18.0, 14.0, 16.0, true, 1.0)
	Kit.spot(root, THRONE + Vector3(0, 2.5, -4), THRONE + Vector3(0, 2.0, 2), "#5aff7e", 12.0, 9.0, 30.0, false, 1.5)
	# The seat's own glow: lights whoever stands before the throne (castle_king) from below, green.
	Kit.omni(root, THRONE + Vector3(0, 0.9, 1.0), "#5aff7e", 1.6, 3.5, false, 0.2)
	# Braziers down both sides: iron bowls, flickering fire, warm light.
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	for k in 8:
		var z := 8.0 - k * 4.5
		for s: float in [-1.0, 1.0]:
			var bp := Vector3(s * 3.0, 0, z + 2.2)
			Kit.cyl(root, 0.06, 0.12, 1.1, bp + Vector3(0, 0.55, 0), iron, 8)
			Kit.cyl(root, 0.45, 0.25, 0.3, bp + Vector3(0, 1.2, 0), iron, 16)
			for f in 3:
				var fm := MeshInstance3D.new()
				fm.mesh = sphere
				fm.material_override = Kit.lit("#ff8a2a", 4.0)
				fm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				fm.position = bp + Vector3(0, 1.45 + 0.15 * f, 0)
				root.add_child(fm)
				_fires.append(fm)
			_fire_lights.append(Kit.omni(root, bp + Vector3(0, 1.9, 0), "#ff9a40", 3.0, 7.0, k % 3 == 0, 0.8))
	# The great doors at the far end, with light waiting behind them.
	for s: float in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.position = Vector3(s * 3.0, 0, DOORS_Z)
		root.add_child(hinge)
		Kit.box(hinge, Vector3(3.0, 8.0, 0.4), Vector3(-s * 1.5, 4.0, 0), Kit.mat("#3a2616", 0.7))
		for b in 4:
			Kit.box(hinge, Vector3(3.05, 0.15, 0.45), Vector3(-s * 1.5, 1.0 + b * 2.0, 0), iron)
		_doors.append(hinge)
	Kit.box(root, Vector3(22, 18, 1), Vector3(-0.0, 9, DOORS_Z + 0.7), stone)
	_door_light = Kit.spot(root, Vector3(0, 4.5, DOORS_Z + 6), Vector3(0, 0, -6), "#ffe9c8", 0.0, 50.0, 30.0, true, 2.5)
	# The hands: a glowing reactor and a green spell, held in Doom's own gauntlets (params.hands.actor); the old
	# stand-alone primitive gauntlets read as two green cylinders ("the model is very weird").
	_hands = Node3D.new()
	_hands.position = THRONE + Vector3(0, 1.4, 2.0)
	root.add_child(_hands)
	_reactor = Node3D.new()
	_hands.add_child(_reactor)
	var core := Kit.ball(_reactor, 0.05, Vector3.ZERO, Kit.lit("#c9f2ff", 8.0), 16)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rtorus := TorusMesh.new()
	rtorus.inner_radius = 0.065
	rtorus.outer_radius = 0.085
	var rring := MeshInstance3D.new()
	rring.mesh = rtorus
	rring.material_override = Kit.mat("#6a7078", 0.35, 0.9)
	rring.rotation = Vector3(PI / 2, 0, 0)
	_reactor.add_child(rring)
	_reactor_light = Kit.omni(_reactor, Vector3(0, 0.05, 0.1), "#8fd8ff", 0.0, 2.5, false, 0.6)
	_spell = Node3D.new()
	_hands.add_child(_spell)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.1
	torus.outer_radius = 0.115
	for r in 3:
		var ring := MeshInstance3D.new()
		ring.mesh = torus
		ring.material_override = Kit.lit("#4dff7a", 5.0)
		ring.scale = Vector3.ONE * (1.0 + 0.4 * r)
		_spell.add_child(ring)
	_spell_light = Kit.omni(_spell, Vector3(0, 0.05, 0.1), "#4dff7a", 0.0, 2.5, false, 0.6)
	_hands.visible = false
	# Doombot sparks.
	var sm := BoxMesh.new()
	sm.size = Vector3(0.01, 0.01, 0.08)
	_sparks = MultiMesh.new()
	_sparks.transform_format = MultiMesh.TRANSFORM_3D
	_sparks.mesh = sm
	_sparks.instance_count = 60
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = _sparks
	smi.material_override = Kit.lit("#ffd27a", 6.0)
	smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(smi)
	_build_gate(root, stone, iron)
	_build_exterior(root, stone)
	return root


## The outer gate court (beyond the doors): the gatehouse arch, a portcullis, a furled Latverian flag above it.
func _build_gate(root: Node3D, stone: Material, iron: Material) -> void:
	var gt := Node3D.new()
	gt.position = GATE
	root.add_child(gt)
	Kit.box(gt, Vector3(30, 0.2, 20), Vector3(0, -0.1, 6), Kit.mat("#3a3c3a", 0.9))
	for s: float in [-1.0, 1.0]:
		Kit.box(gt, Vector3(6, 12, 4), Vector3(s * 5.5, 6, 0), stone)
		Kit.cyl(gt, 2.4, 2.6, 14, Vector3(s * 8.5, 7, 0), stone, 20)
		Kit.cyl(gt, 0.0, 2.9, 4, Vector3(s * 8.5, 16, 0), Kit.mat("#1c2a1e", 0.8), 20)
	Kit.box(gt, Vector3(5, 3.5, 4), Vector3(0, 10.25, 0), stone)
	_portcullis = Node3D.new()
	gt.add_child(_portcullis)
	for k in 7:
		Kit.box(_portcullis, Vector3(0.12, 8.5, 0.12), Vector3(-2.1 + k * 0.7, 4.25, 1.9), iron)
	for k in 6:
		Kit.box(_portcullis, Vector3(5.0, 0.12, 0.12), Vector3(0, 0.6 + k * 1.4, 1.9), iron)
	_flag = Node3D.new()
	_flag.position = Vector3(0, 12.0, 2.1)
	gt.add_child(_flag)
	# Latveria's flag here: our own design (green field, a silver mask), no claim to a real flag.
	Kit.box(_flag, Vector3(4.0, 6.0, 0.03), Vector3(0, -3.0, 0), Kit.mat("#1f5229", 0.85))
	var em := MeshInstance3D.new()
	em.mesh = suit().call("_mask", 1.0)
	em.material_override = Kit.mat("#c9ced2", 0.4, 0.7)
	em.scale = Vector3(1.0, 1.15, 0.15)
	em.position = Vector3(0, -2.8, 0.03)
	_flag.add_child(em)
	Kit.spot(gt, Vector3(0, 9, 10), Vector3(0, 4, 0), "#ffcf90", 20.0, 20.0, 40.0, true, 0.6)
	for s: float in [-1.0, 1.0]:
		Kit.ball(gt, 0.2, Vector3(s * 3.0, 4.0, 2.3), Kit.lit("#ff9a40", 4.0), 10)
		Kit.omni(gt, Vector3(s * 3.0, 4.0, 2.8), "#ff9a40", 3.0, 8.0, false, 0.5)


## The castle on its crag (exterior), with lit windows, and village lights below.
func _build_exterior(root: Node3D, stone: Material) -> void:
	var ex := Node3D.new()
	ex.position = EXT
	root.add_child(ex)
	var rock := Kit.mat("#2a2a2c", 0.95)
	Kit.cyl(ex, 30.0, 70.0, 60.0, Vector3(0, -10, -40), rock, 24)
	Kit.box(ex, Vector3(600, 1, 600), Vector3(0, -40, 0), Kit.mat("#141618", 0.95))
	var roof := Kit.mat("#18261a", 0.7)
	var lit := Kit.lit("#ffcc77", 3.0)
	var rng := Kit.rng("castle_ext")
	var towers := [Vector3(-18, 20, -30), Vector3(18, 20, -30), Vector3(-10, 20, -52), Vector3(12, 20, -55), Vector3(0, 20, -42)]
	for i in towers.size():
		var tp: Vector3 = towers[i]
		var h := 30.0 + 14.0 * (1 if i == 4 else 0) + rng.randf() * 6.0
		Kit.cyl(ex, 4.0, 4.6, h, tp + Vector3(0, h * 0.5, 0), stone, 20)
		Kit.cyl(ex, 0.0, 5.2, 10.0, tp + Vector3(0, h + 5.0, 0), roof, 20)
		for w in 6:
			var a := rng.randf() * TAU
			var wy := 6.0 + rng.randf() * (h - 10.0)
			var win := Kit.box(ex, Vector3(0.8, 1.6, 0.3), tp + Vector3(cos(a) * 4.3, wy, sin(a) * 4.3), lit, Vector3(0, -a, 0))
			win.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Kit.box(ex, Vector3(36, 22, 6), Vector3(0, 31, -30), stone)
	for k in 18:
		Kit.box(ex, Vector3(1.0, 1.6, 6.2), Vector3(-17.0 + k * 2.0, 42.8, -30), stone)
	# The great window that the final push goes into.
	var gw := Kit.box(ex, Vector3(4.0, 7.0, 0.3), Vector3(0, 33, -26.9), Kit.lit("#7dffa0", 2.5))
	gw.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Kit.omni(ex, Vector3(0, 33, -24), "#5aff7e", 10.0, 25.0, false, 1.0)
	for k in 120:
		var p := Vector3(rng.randf_range(-160, 160), -39.0, rng.randf_range(30, 200))
		var b := Kit.ball(ex, 0.4, p, Kit.lit("#ffb060", 3.0), 6)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sky_flash := Kit.omni(ex, Vector3(-60, 120, 40), "#cfd8ff", 0.0, 400.0, false, 0.0)
	_flash.append(sky_flash)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	# Doors.
	var dt := float(_p.get("doors", 1e9))
	var open := Motion.in_out(Motion.seg(t, dt, dt + 1.6))
	for i in _doors.size():
		var s := -1.0 if i == 0 else 1.0
		_doors[i].rotation = Vector3(0, s * open * 1.75, 0)
	_door_light.light_energy = 160.0 * open
	# Lightning.
	var flash := 0.0
	for lt in _p.get("lightning", []):
		var k := t - float(lt)
		if k >= 0.0 and k < 0.6:
			flash = maxf(flash, exp(-k * 9.0) + 0.6 * exp(-absf(k - 0.18) * 30.0))
	for l in _flash:
		if l is SpotLight3D:
			l.light_energy = 6.0 + 60.0 * flash
		else:
			l.light_energy = 400.0 * flash
	_win_mat.emission_energy_multiplier = 0.8 + 8.0 * flash
	# Fire flicker.
	for i in _fires.size():
		var f := _fires[i]
		var w := 0.85 + 0.15 * sin(t * (9.0 + i % 5) + i) * sin(t * 4.3 + i * 0.7)
		f.scale = Vector3(0.28, 0.36 + 0.1 * sin(t * 11.0 + i), 0.28) * w * (1.0 - 0.25 * (i % 3))
	for i in _fire_lights.size():
		_fire_lights[i].light_energy = 3.0 * (0.85 + 0.15 * sin(t * 13.0 + i * 1.7))
	# Hands.
	var hd: Dictionary = _p.get("hands", {})
	var ht := float(hd.get("t", 1e9))
	_hands.visible = t >= ht - 0.2 and t < ht + 6.0
	if _hands.visible:
		# The reactor kindles in the right palm on "smartest", the spell in the left on "sorcerer"; each hand rises
		# into view first (anticipation), then the light blooms.
		var rt := float(hd.get("reactor", ht))
		var st := float(hd.get("spell", ht))
		var r_up := Motion.out_cubic(Motion.seg(t, rt - 0.5, rt))
		var s_up := Motion.out_cubic(Motion.seg(t, st - 0.5, st))
		var r_on := Motion.out_back(Motion.seg(t, rt, rt + 0.45))
		var s_on := Motion.out_back(Motion.seg(t, st, st + 0.45))
		var inv := node.global_transform.affine_inverse()
		var a = ctx["actor"].call(String(hd["actor"])) if hd.has("actor") and ctx.has("actor") else null
		if a != null:
			var o: Vector3 = a.global_transform.origin
			var fwd := Vector3(sin(a.rotation.y), 0, cos(a.rotation.y))
			var left := Vector3(cos(a.rotation.y), 0, -sin(a.rotation.y))
			var chest := o + Vector3.UP * 1.3
			a.aim_hand("r", chest + fwd * 0.45 - left * 0.36 + Vector3.UP * 0.38, r_up)
			a.aim_hand("l", chest + fwd * 0.45 + left * 0.36 + Vector3.UP * 0.42, s_up)
			_reactor.position = inv * (a.bone_world("hand_r") + fwd * 0.06 + Vector3.UP * 0.09) - _hands.position
			_spell.position = inv * (a.bone_world("hand_l") + fwd * 0.06 + Vector3.UP * 0.16) - _hands.position
		_reactor.scale = Vector3.ONE * maxf(r_on, 0.01)
		_reactor.rotation = Vector3(0, 0, t * 1.5)
		_reactor_light.light_energy = 3.0 * clampf(r_on, 0.0, 1.0)
		_spell.rotation = Vector3(t * 2.0, t * 3.1, 0)
		_spell.scale = Vector3.ONE * maxf(s_on, 0.01)
		_spell_light.light_energy = 2.0 * clampf(s_on, 0.0, 1.0)
	# The immunity gag: flag unrolls, portcullis slams.
	var fd: Dictionary = _p.get("flag", {})
	var ft := float(fd.get("t", 1e9))
	var unroll := Motion.out_bounce(Motion.seg(t, ft, ft + 0.6))
	_flag.scale = Vector3(1.0, maxf(unroll, 0.02), 1.0)
	var drop := Motion.in_cubic(Motion.seg(t, ft + 0.7, ft + 1.0))
	var settle := Motion.impact(t - (ft + 1.0), 0.05, 6.0, 10.0) if t > ft + 1.0 else 0.0
	_portcullis.position = Vector3(0, 8.5 * (1.0 - drop) + settle, 0)
	# Doombot head pop.
	var hidden := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.001), Vector3(0, -50, 0))
	var pd: Dictionary = _p.get("pop", {})
	var pt := float(pd.get("t", 1e9))
	var origin := Vector3.ZERO
	if pd.has("actor") and ctx.has("actor"):
		var a = ctx["actor"].call(String(pd["actor"]))
		if a != null:
			var head := a.find_child("toon_head", true, false) as Node3D
			if head != null:
				var k := t - pt
				origin = node.global_transform.affine_inverse() * a.bone_world("Head")
				if k >= 0.0:
					var up := Motion.out_cubic(clampf(k / 0.5, 0.0, 1.0)) * 0.9 - 4.9 * maxf(k - 0.5, 0.0) * maxf(k - 0.5, 0.0)
					head.position = Vector3(0.15 * k, maxf(up, -0.3), 0.05 * k)
					head.rotation = Vector3(k * 3.0, k * 5.0, 0)
				else:
					head.position = Vector3.ZERO
					head.rotation = Vector3.ZERO
	var rng := RandomNumberGenerator.new()
	for i in _sparks.instance_count:
		rng.seed = 500 + i
		var k := t - pt - rng.randf() * 0.4
		if k < 0.0 or k > 0.7:
			_sparks.set_instance_transform(i, hidden)
			continue
		var v := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.5, 1.5), rng.randf_range(-1, 1)) * 3.0
		var p := origin + Vector3(0, -0.15, 0) + v * k + Vector3(0, -4.9 * k * k, 0)
		_sparks.set_instance_transform(i, Transform3D(Basis.looking_at(v.normalized(), Vector3.UP), p))
	return {"throne": node.global_transform * (THRONE + Vector3(0, 1.4, 0)), "doors": node.global_transform * Vector3(0, 4, DOORS_Z),
		"hands": node.global_transform * _hands.position, "gate": node.global_transform * (GATE + Vector3(0, 4, 2)),
		"window": node.global_transform * (EXT + Vector3(0, 33, -26.9))}
