## Latveria and the voyage: five areas of one gag.
##   VALLEY (origin): a snowy Alpine valley at dawn, mountains, snow pines (Quaternius), a Romani camp of painted
##       wagons round a campfire with smoke, falling snow, and the Baron's castle on a crag far off.
##   WAGON (0, 0, 300): a wagon interior by candlelight: a cradle, shelves of jars, a green spark that fades (`spark`).
##   FOREST (300, 0, 0): a blizzard in the pines at night, one great tree; a snow mound grows at its foot (`mound`).
##   CHEST (0, 0, 600): a dark corner, a carved chest; its lid creaks open on `chest`, green light pours out.
##   LINER (-400, 0, 0): a steamer's deck at dawn, the rail, a funnel, the sea, New York rising out of fog.
##
## params:
##   snow    0..1 density of falling snow in the valley (default 0.5); the forest always storms
##   spark   t   the green spark in the wagon fades out from t (Cynthia's death, kept off screen)
##   mound   t   from t the snow mound at the great tree's foot grows (the father, never shown frozen)
##   chest   t   the chest's lid opens
##   bow     t   the liner's bow rises and falls on the swell (always), skyline lights come up from t
## anchors: fire, castle, cradle, tree, chest, rail, skyline
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const WAGON := Vector3(0, 0, 300)
const FOREST := Vector3(300, 0, 0)
const CHEST := Vector3(0, 0, 600)
const LINER := Vector3(-3000, 0, 0)

var _p := {}
var _snow: MultiMesh
var _storm: MultiMesh
var _spark: MeshInstance3D
var _spark_light: OmniLight3D
var _mound: MeshInstance3D
var _lid: Node3D
var _chest_light: OmniLight3D
var _fire: Array[MeshInstance3D] = []
var _smoke: Array[MeshInstance3D] = []
var _deck: Node3D


func _tree(root: Node3D, pos: Vector3, scale: float, idx: int) -> void:
	var sc := KitDB.scene("quaternius_nature/PineTree_Snow_%d" % (1 + idx % 5))
	if sc == null:
		Kit.cyl(root, 0.0, 1.4 * scale, 4.0 * scale, pos + Vector3(0, 2.0 * scale, 0), Kit.mat("#2a3a30", 0.9), 10)
		return
	var n := sc.instantiate() as Node3D
	n.position = pos
	n.scale = Vector3.ONE * scale
	n.rotation = Vector3(0, idx * 1.7, 0)
	root.add_child(n)


func _flakes(root: Node3D, n: int, size: float) -> MultiMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.92, 0.95, 1.0, 0.85)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = q
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	return mm


func _wagon(root: Node3D, pos: Vector3, yaw: float, body: String, trim: String) -> void:
	var w := Node3D.new()
	w.position = pos
	w.rotation = Vector3(0, yaw, 0)
	root.add_child(w)
	Kit.box(w, Vector3(1.9, 1.5, 3.4), Vector3(0, 1.45, 0), Kit.mat(body, 0.7))
	for s: float in [-1.0, 1.0]:
		Kit.box(w, Vector3(0.06, 1.5, 3.42), Vector3(s * 0.96, 1.45, 0), Kit.mat(trim, 0.6))
		for k in 2:
			var wheel := Kit.cyl(w, 0.55, 0.55, 0.1, Vector3(s * 1.0, 0.55, -1.0 + k * 2.0), Kit.mat("#3a2618", 0.7), 16, Vector3(0, 0, PI / 2))
			wheel.name = "wheel"
			Kit.cyl(w, 0.12, 0.12, 0.14, Vector3(s * 1.04, 0.55, -1.0 + k * 2.0), Kit.mat(trim, 0.5), 10, Vector3(0, 0, PI / 2))
	var roof := Kit.cyl(w, 1.05, 1.05, 3.5, Vector3(0, 2.2, 0), Kit.mat("#ece9e2", 0.9), 20, Vector3(PI / 2, 0, 0))
	roof.scale = Vector3(1.0, 1.0, 0.55)
	Kit.box(w, Vector3(0.6, 1.0, 0.05), Vector3(0, 1.3, 1.72), Kit.mat(trim, 0.6))
	var win := Kit.box(w, Vector3(0.45, 0.4, 0.05), Vector3(0.5, 1.7, 1.72), Kit.lit("#ffb060", 2.0))
	win.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Kit.rod(w, Vector3(0.3, 2.4, -1.2), Vector3(0.3, 3.3, -1.2), 0.07, Kit.mat("#222222", 0.5, 0.6), 8)


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "latveria"))
	var snow := Kit.mat("#e6ecf4", 0.92)
	var rock := Kit.mat("#4a4c52", 0.95)
	var rng := Kit.rng("latveria")
	# VALLEY.
	Kit.box(root, Vector3(500, 1, 500), Vector3(0, -0.5, -100), snow)
	for i in 14:
		var a := -1.2 + i * 0.18
		var d := 220.0 + rng.randf() * 120.0
		var h := 90.0 + rng.randf() * 110.0
		var c := Vector3(sin(a) * d, 0, -cos(a) * d - 60.0)
		Kit.cyl(root, 0.0, h * 0.75, h, c + Vector3(0, h * 0.5 - 2, 0), rock, 10)
		Kit.cyl(root, 0.0, h * 0.3, h * 0.4, c + Vector3(0, h * 0.8 - 2, 0), snow, 10)
	for i in 70:
		var p := Vector3(rng.randf_range(-70, 70), 0, rng.randf_range(-90, 25))
		if Vector2(p.x, p.z).length() < 12.0:
			continue
		_tree(root, p, rng.randf_range(2.0, 3.6), i)
	# The Baron's castle on its crag.
	var cr := Vector3(55, 0, -160)
	Kit.cyl(root, 8.0, 22.0, 40.0, cr + Vector3(0, 18, 0), rock, 12)
	for k in 4:
		var tp := cr + Vector3(-7.0 + k * 4.5, 38.0, -2.0 + (k % 2) * 3.0)
		Kit.cyl(root, 1.6, 1.8, 14.0 + k * 2.0, tp + Vector3(0, 7.0 + k, 0), Kit.mat("#5a5a60", 0.9), 12)
		Kit.cyl(root, 0.0, 2.2, 5.0, tp + Vector3(0, 16.5 + 2.0 * k, 0), Kit.mat("#2a3a5a", 0.8), 12)
	# The camp: four wagons round a fire, smoke rising.
	_wagon(root, Vector3(-5.0, 0, -1.0), 0.6, "#8a1e24", "#e0b040")
	_wagon(root, Vector3(4.5, 0, -2.5), -0.7, "#1e5a3a", "#e0b040")
	_wagon(root, Vector3(-1.5, 0, -7.0), 0.1, "#2a3a7a", "#d84a2a")
	_wagon(root, Vector3(6.5, 0, 3.5), -1.6, "#6a3a1e", "#e0d040")
	for k in 6:
		Kit.cyl(root, 0.06, 0.06, 1.0, Vector3(cos(k) * 0.45, 0.08, sin(k) * 0.45), Kit.mat("#3a2414", 0.8), 6,
			Vector3(PI / 2, k * 0.6, 0.2))
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	for f in 4:
		var fm := MeshInstance3D.new()
		fm.mesh = sphere
		fm.material_override = Kit.lit("#ff8a2a", 4.0)
		fm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(fm)
		_fire.append(fm)
	Kit.omni(root, Vector3(0, 1.2, 0), "#ff9a40", 4.0, 12.0, true, 0.8)
	var smat := Kit.mat("#9aa0a8", 1.0).duplicate()
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color = Color(0.55, 0.58, 0.62, 0.25)
	for k in 14:
		var sm := MeshInstance3D.new()
		sm.mesh = sphere
		sm.material_override = smat
		sm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(sm)
		_smoke.append(sm)
	_snow = _flakes(root, 900, 0.05)
	# WAGON interior.
	var wg := Node3D.new()
	wg.position = WAGON
	root.add_child(wg)
	var plank := Kit.textured("incoming/polyhaven_doom/textures/dark_wood_diff_2k.jpg", "", "", Vector3(2, 2, 1), Color("#b08a60"))
	Kit.box(wg, Vector3(3.2, 0.1, 2.6), Vector3(0, -0.05, 0), plank)
	Kit.box(wg, Vector3(3.2, 2.4, 0.1), Vector3(0, 1.2, -1.3), plank)
	for s: float in [-1.0, 1.0]:
		Kit.box(wg, Vector3(0.1, 2.4, 2.6), Vector3(s * 1.6, 1.2, 0), plank)
	var ceil := Kit.cyl(wg, 1.65, 1.65, 2.6, Vector3(0, 2.3, 0), Kit.mat("#4a3020", 0.8), 20, Vector3(PI / 2, 0, 0))
	ceil.scale = Vector3(1.0, 1.0, 0.4)
	for k in 6:
		Kit.cyl(wg, 0.06, 0.06, 0.16, Vector3(-1.2 + k * 0.18, 1.75, -1.18), Kit.mat(["#6a8a5a", "#8a5a3a", "#5a6a8a"][k % 3], 0.3, 0.0, 0.8), 10)
	Kit.box(wg, Vector3(1.2, 0.03, 0.25), Vector3(-0.9, 1.66, -1.15), Kit.mat("#3a2414", 0.7))
	# The cradle on rockers, a blanket.
	Kit.box(wg, Vector3(0.8, 0.35, 0.45), Vector3(0.6, 0.45, -0.4), Kit.mat("#6a4a2a", 0.7))
	Kit.box(wg, Vector3(0.72, 0.05, 0.38), Vector3(0.6, 0.6, -0.4), Kit.mat("#c8b8a0", 0.9))
	for s: float in [-1.0, 1.0]:
		var rk := Kit.cyl(wg, 0.5, 0.5, 0.05, Vector3(0.6 + s * 0.3, 0.27, -0.4), Kit.mat("#4a3020", 0.7), 20, Vector3(0, 0, PI / 2))
		rk.scale = Vector3(1, 0.35, 1)
	Kit.cyl(wg, 0.03, 0.03, 0.16, Vector3(-0.2, 0.86, -0.2), Kit.mat("#efe6d2", 0.7), 10)
	Kit.box(wg, Vector3(0.5, 0.78, 0.4), Vector3(-0.2, 0.39, -0.2), Kit.mat("#4a3020", 0.7))
	Kit.ball(wg, 0.015, Vector3(-0.2, 0.96, -0.2), Kit.lit("#ffcc77", 6.0), 8, Vector3(1, 1.8, 1))
	Kit.omni(wg, Vector3(-0.2, 1.0, -0.1), "#ffa860", 1.6, 4.0, true, 0.3)
	_spark = Kit.ball(wg, 0.05, Vector3(0.1, 1.1, -0.1), Kit.lit("#4dff7a", 6.0), 12)
	_spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_spark_light = Kit.omni(wg, Vector3(0.1, 1.1, 0.0), "#4dff7a", 1.2, 2.5, false, 0.3)
	# FOREST in the blizzard.
	var fo := Node3D.new()
	fo.position = FOREST
	root.add_child(fo)
	Kit.box(fo, Vector3(200, 1, 200), Vector3(0, -0.5, 0), snow)
	for i in 90:
		var p := Vector3(rng.randf_range(-40, 40), 0, rng.randf_range(-50, 30))
		if Vector2(p.x, p.z + 10.0).length() < 6.0:
			continue
		_tree(fo, p, rng.randf_range(2.0, 4.0), i + 3)
	_tree(fo, Vector3(0, 0, -10), 5.5, 1)
	_mound = MeshInstance3D.new()
	_mound.mesh = sphere
	_mound.material_override = snow
	_mound.position = Vector3(0.6, 0, -8.4)
	fo.add_child(_mound)
	Kit.spot(fo, Vector3(-6, 14, 8), Vector3(0, 0, -9), "#9fb4ff", 26.0, 40.0, 40.0, true, 1.0)
	Kit.omni(fo, Vector3(3, 6, -2), "#7f94c8", 3.0, 30.0, false, 0.6)
	_storm = _flakes(fo, 2200, 0.06)
	# CHEST.
	var ch := Node3D.new()
	ch.position = CHEST
	root.add_child(ch)
	Kit.box(ch, Vector3(8, 0.1, 8), Vector3(0, -0.05, 0), plank)
	Kit.box(ch, Vector3(8, 4, 0.2), Vector3(0, 2, -1.5), Kit.mat("#2a2420", 0.9))
	Kit.spot(ch, Vector3(-2.0, 3.0, 2.5), Vector3(0, 0.4, 0.2), "#7f94c8", 3.0, 8.0, 30.0, true, 0.3)
	var oak := Kit.mat("#5a3a20", 0.6)
	var brass := Kit.mat("#b08a3a", 0.35, 0.8)
	Kit.box(ch, Vector3(0.9, 0.45, 0.55), Vector3(0, 0.225, 0), oak)
	for s: float in [-1.0, 1.0]:
		Kit.box(ch, Vector3(0.05, 0.47, 0.57), Vector3(s * 0.38, 0.235, 0), brass)
	Kit.box(ch, Vector3(0.12, 0.12, 0.02), Vector3(0, 0.38, 0.28), brass)
	_lid = Node3D.new()
	_lid.position = Vector3(0, 0.45, -0.275)
	ch.add_child(_lid)
	Kit.box(_lid, Vector3(0.92, 0.12, 0.57), Vector3(0, 0.06, 0.285), oak)
	Kit.box(_lid, Vector3(0.94, 0.03, 0.08), Vector3(0, 0.1, 0.285), brass)
	_chest_light = Kit.omni(ch, Vector3(0, 0.55, 0.05), "#4dff7a", 0.0, 4.0, true, 1.5)
	var glow := Kit.box(ch, Vector3(0.8, 0.02, 0.45), Vector3(0, 0.44, 0), Kit.lit("#4dff7a", 1.6))
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glow.name = "chest_glow"
	# LINER.
	_deck = Node3D.new()
	_deck.position = LINER
	root.add_child(_deck)
	var sea := Kit.mat("#16222e", 0.08, 0.0, 0.9)
	Kit.box(root, Vector3(2000, 0.1, 2000), LINER + Vector3(0, -3.0, -300), sea)
	Kit.box(_deck, Vector3(14, 0.2, 40), Vector3(0, 0, -6), plank)
	Kit.box(_deck, Vector3(14, 3, 40), Vector3(0, -1.6, -6), Kit.mat("#1a1a1e", 0.6))
	for s: float in [-1.0, 1.0]:
		Kit.box(_deck, Vector3(0.08, 1.0, 40), Vector3(s * 6.9, 0.6, -6), Kit.mat("#efece4", 0.5))
		for k in 20:
			Kit.box(_deck, Vector3(0.05, 1.0, 0.05), Vector3(s * 6.9, 0.5, -25 + k * 2.0), Kit.mat("#efece4", 0.5))
	Kit.box(_deck, Vector3(14, 1.0, 0.08), Vector3(0, 0.6, -26), Kit.mat("#efece4", 0.5))
	Kit.cyl(_deck, 1.6, 1.7, 7.0, Vector3(0, 3.6, 4.0), Kit.mat("#b02a1e", 0.6), 20)
	Kit.cyl(_deck, 1.62, 1.62, 1.2, Vector3(0, 6.6, 4.0), Kit.mat("#111111", 0.6), 20)
	var sky := Node3D.new()
	sky.position = LINER + Vector3(0, -3.0, -900)
	root.add_child(sky)
	var lit := Kit.lit("#ffd9a0", 2.5)
	for i in 60:
		var bw := rng.randf_range(10, 26)
		var bh := rng.randf_range(30, 170) * (1.6 if i % 11 == 0 else 1.0)
		var b := Kit.box(sky, Vector3(bw, bh, bw), Vector3(rng.randf_range(-320, 320), bh * 0.5, rng.randf_range(-60, 60)),
			Kit.mat("#3a4250", 0.8))
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for w in 3:
			var wl := Kit.box(sky, Vector3(bw * 0.7, 1.4, 0.2), Vector3(b.position.x, rng.randf_range(8, bh - 4), b.position.z + bw * 0.5 + 0.1), lit)
			wl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The Statue of Liberty (public domain monument) on her island, left of the city.
	var lib := Vector3(-260, 0, 260)
	var verd := Kit.mat("#6fa392", 0.7)
	Kit.box(sky, Vector3(30, 26, 30), lib + Vector3(0, 13, 0), Kit.mat("#8a8478", 0.9))
	Kit.cyl(sky, 4.5, 7.0, 34, lib + Vector3(0, 43, 0), verd, 16)
	Kit.ball(sky, 3.2, lib + Vector3(0, 62, 0), verd, 16)
	Kit.rod(sky, lib + Vector3(3.5, 52, 0), lib + Vector3(6.0, 78, 0), 1.2, verd, 10)
	Kit.ball(sky, 1.6, lib + Vector3(6.2, 80, 0), Kit.lit("#ffd27a", 4.0), 12)
	for k in 7:
		var a := -PI * 0.5 + k * PI / 6.0
		Kit.rod(sky, lib + Vector3(0, 64, 0), lib + Vector3(cos(a) * 4.5, 64 + sin(a) * 1.0 + 2.5, -0.5), 0.35, verd, 6)
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	# Valley snow and fire.
	var density := float(_p.get("snow", 0.5))
	var rng := RandomNumberGenerator.new()
	var hidden := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.001), Vector3(0, -50, 0))
	for i in _snow.instance_count:
		rng.seed = 11 + i
		if rng.randf() > density:
			_snow.set_instance_transform(i, hidden)
			continue
		var x := rng.randf_range(-20, 20) + sin(t * 0.7 + i) * 0.4
		var z := rng.randf_range(-20, 14)
		var y := fposmod(rng.randf() * 12.0 - t * 0.9, 12.0)
		_snow.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(x, y, z)))
	for f in _fire.size():
		var w := 0.8 + 0.2 * sin(t * (11.0 + f) + f)
		_fire[f].position = Vector3(0.1 * sin(t * 7.0 + f), 0.35 + 0.18 * f, 0.1 * cos(t * 6.0 + f))
		_fire[f].scale = Vector3(0.32, 0.5, 0.32) * w * (1.0 - 0.2 * f)
	for k in _smoke.size():
		var age := fposmod(t * 0.35 + k / float(_smoke.size()), 1.0)
		_smoke[k].position = Vector3(0.6 * age + 0.2 * sin(k), 1.2 + age * 9.0, -0.3 * age)
		_smoke[k].scale = Vector3.ONE * (0.4 + 1.6 * age)
	# The storm in the forest: hard, slanting snow.
	for i in _storm.instance_count:
		rng.seed = 7000 + i
		var x := fposmod(rng.randf_range(-25, 25) + t * 6.0, 50.0) - 25.0
		var z := rng.randf_range(-25, 15)
		var y := fposmod(rng.randf() * 14.0 - t * 3.0, 14.0)
		_storm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(x, y, z)))
	# The spark fades.
	var sk := float(_p.get("spark", 1e9))
	var fade := 1.0 - Motion.smooth(Motion.seg(t, sk, sk + 1.4))
	_spark.scale = Vector3.ONE * maxf(fade, 0.001) * (1.0 + 0.15 * sin(t * 9.0))
	_spark_light.light_energy = 1.2 * fade
	# The snow mound grows over the night (the father is never shown frozen).
	var mt := float(_p.get("mound", 1e9))
	var grow := Motion.smooth(Motion.seg(t, mt, mt + 2.5))
	_mound.scale = Vector3(0.9, 0.55, 0.7) * maxf(grow, 0.001)
	# The chest.
	var ct := float(_p.get("chest", 1e9))
	var op := Motion.out_back(Motion.seg(t, ct, ct + 1.2), 1.1)
	_lid.rotation = Vector3(-1.9 * op, 0, 0)
	_chest_light.light_energy = 1.4 * Motion.smooth(Motion.seg(t, ct, ct + 0.6))
	# The liner on the swell.
	_deck.position = LINER + Vector3(0, 0.25 * sin(t * 0.6), 0)
	_deck.rotation = Vector3(0.012 * sin(t * 0.6 + 0.5), 0, 0.01 * sin(t * 0.45))
	return {"fire": node.global_transform * Vector3(0, 0.8, 0), "castle": node.global_transform * Vector3(55, 50, -160),
		"cradle": node.global_transform * (WAGON + Vector3(0.6, 0.6, -0.4)), "tree": node.global_transform * (FOREST + Vector3(0, 2, -10)),
		"chest": node.global_transform * (CHEST + Vector3(0, 0.5, 0)), "rail": node.global_transform * (LINER + Vector3(0, 1.2, -25)),
		"skyline": node.global_transform * (LINER + Vector3(0, 40, -900))}
