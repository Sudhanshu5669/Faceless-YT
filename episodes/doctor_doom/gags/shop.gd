## A comic shop at night: wood floor, wall racks of comics (MultiMesh covers in a hundred colours), tables of white
## long boxes, a counter under a warm desk lamp, the street window with a neon COMICS sign and rain, and a cardboard
## Doctor Doom standee by the window. The hero comic is the real Fantastic Four #5 cover.
##
## Local frame: the lamp table at (0, 0, 0), its top at y 0.9; the long box on it at (-0.35, 0.9, 0); the counter at
## (1.6, 0, -0.6); the window wall at z 3.2 (the street outside at z > 3.2); racks on the back wall at z -3.
## Cameras inside stand at +z looking -z (or outside the window at z ~5).
##
## params:
##   pull   {"actor": id, "t": t}   the actor reaches into the long box, draws FF #5 out on t and holds it up
##   tilt   t   the held comic tilts toward the lamp (the cover catches the light)
##   stack  [t, t, t, t]   four comics slap down on the counter one by one
##   drop   t   the hero comic slips from the hand and flutters to the floor, landing face up at (0.1, 0, 0.55)
##   rise   t   a new comic, RISE OF DOOM (the 2026 reissue of Infamous Iron Man), slaps down on the counter
##   covers ["path.jpg", ...]   optional cover textures for the four stacked comics (else plain colours)
## anchors: comic, box, counter, standee, window
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")
const Paths = preload("res://scripts/core/paths.gd")

const BOX := Vector3(-0.35, 0.62, 0.0)   # toon height: the hero table is low
const COUNTER := Vector3(1.6, 1.0, -0.6)
const COVER := "library/logos/doom/ff5_doom_debut.jpg"

var _p := {}
var _comic: Node3D
var _stack: Array[Node3D] = []
var _rise: Node3D
var _rain: MultiMesh


static var _suit: GDScript


static func suit() -> GDScript:
	if _suit == null:
		_suit = GDScript.new()
		_suit.source_code = FileAccess.get_file_as_string(Paths.repo_path("library/gags/doom_suit.gd"))
		_suit.reload()
	return _suit


func _comic_mesh(parent: Node3D, cover: String, col: Color) -> Node3D:
	var c := Node3D.new()
	parent.add_child(c)
	Kit.box(c, Vector3(0.165, 0.255, 0.002), Vector3.ZERO, Kit.mat("#efe9da", 0.8))
	var m: Material = Kit.textured(cover) if cover != "" else Kit.mat(col, 0.6)
	var q := Kit.quad(c, Vector2(0.17, 0.26), Vector3(0, 0, 0.006), m)
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The same cover on the back (turned round, so it reads the right way from either side).
	var q2 := Kit.quad(c, Vector2(0.17, 0.26), Vector3(0, 0, -0.006), m, Vector3(0, PI, 0))
	q2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return c


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "shop"))
	var wood := Kit.textured("incoming/polyhaven_doom/textures/dark_wood_diff_2k.jpg", "incoming/polyhaven_doom/textures/dark_wood_nor_gl_2k.jpg",
		"incoming/polyhaven_doom/textures/dark_wood_rough_2k.jpg", Vector3(4, 4, 1), Color("#a07a5a"))
	var wall := Kit.mat("#2c3a46", 0.9)
	Kit.box(root, Vector3(12, 0.1, 10), Vector3(0, -0.05, 0), wood)
	Kit.box(root, Vector3(12, 3.6, 0.2), Vector3(0, 1.8, -3.3), wall)
	for s: float in [-1.0, 1.0]:
		Kit.box(root, Vector3(0.2, 3.6, 10), Vector3(s * 5.0, 1.8, 0), wall)
	Kit.box(root, Vector3(12, 0.2, 10), Vector3(0, 3.65, 0), Kit.mat("#14171c", 0.9))
	# The street window: frame, glass, a neon sign, rain outside, a street lamp glow.
	for x: float in [-5.0, -1.5, 1.5, 5.0]:
		Kit.box(root, Vector3(0.18 if absf(x) < 4.0 else 3.2, 3.6, 0.2), Vector3(x if absf(x) < 4.0 else signf(x) * 3.5, 1.8, 3.25), Kit.mat("#1a1a1e", 0.6))
	Kit.box(root, Vector3(12, 0.9, 0.2), Vector3(0, 0.45, 3.25), Kit.mat("#1a1a1e", 0.6))
	var glass := Kit.mat("#0c1018", 0.05, 0.0, 0.9).duplicate()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.1, 0.12, 0.16, 0.15)
	Kit.box(root, Vector3(7, 2.7, 0.02), Vector3(0, 2.25, 3.2), glass)
	var neon := Kit.text(root, "COMICS", 0.42, Color("#ff3aa8"), Vector3(-0.2, 2.9, 3.1), Vector3(0, PI, 0), true, 3.0)
	neon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Kit.omni(root, Vector3(-0.2, 2.9, 2.9), "#ff3aa8", 2.0, 4.0, false, 0.5)
	Kit.box(root, Vector3(30, 0.1, 12), Vector3(0, -0.06, 9.5), Kit.mat("#0b0c10", 0.06, 0.0, 0.9))
	Kit.omni(root, Vector3(3.0, 4.5, 7.0), "#ffb86a", 6.0, 12.0, false, 0.6)
	var drop := BoxMesh.new()
	drop.size = Vector3(0.006, 0.35, 0.006)
	_rain = MultiMesh.new()
	_rain.transform_format = MultiMesh.TRANSFORM_3D
	_rain.mesh = drop
	_rain.instance_count = 500
	var rmi := MultiMeshInstance3D.new()
	rmi.multimesh = _rain
	var rmat := Kit.mat("#9fb4d0", 0.2).duplicate()
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.albedo_color = Color(0.7, 0.8, 0.95, 0.35)
	rmi.material_override = rmat
	rmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(rmi)
	# Wall racks of comics: a grid of covers (MultiMesh quads, a hundred colours).
	var rng := Kit.rng("shop_covers")
	var qm := QuadMesh.new()
	qm.size = Vector2(0.17, 0.26)
	var cm := MultiMesh.new()
	cm.transform_format = MultiMesh.TRANSFORM_3D
	cm.use_colors = true
	cm.mesh = qm
	var spots: Array[Transform3D] = []
	for row in 5:
		for col in 40:
			var x := -4.6 + col * 0.23
			spots.append(Transform3D(Basis.from_euler(Vector3(-0.18, 0, 0)), Vector3(x, 0.8 + row * 0.5, -3.17)))
		Kit.box(root, Vector3(9.4, 0.03, 0.12), Vector3(-0.0, 0.66 + row * 0.5, -3.12), Kit.mat("#3a2a1e", 0.6))
	for row in 4:
		for col in 30:
			spots.append(Transform3D(Basis.from_euler(Vector3(0, PI / 2, -0.18)), Vector3(-4.87, 0.8 + row * 0.5, -2.6 + col * 0.2)))
	cm.instance_count = spots.size()
	var cmat := StandardMaterial3D.new()
	cmat.vertex_color_use_as_albedo = true
	cmat.roughness = 0.55
	var cmi := MultiMeshInstance3D.new()
	cmi.multimesh = cm
	cmi.material_override = cmat
	cmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(cmi)
	var pal := ["#d8282a", "#f2c12e", "#1f6fd0", "#2aa24a", "#7a2ab0", "#f06a1e", "#101010", "#e8e0c8", "#18a0b8", "#b81e5a"]
	for i in spots.size():
		cm.set_instance_transform(i, spots[i])
		cm.set_instance_color(i, Color(pal[rng.randi() % pal.size()]).darkened(rng.randf() * 0.35))
	# Tables of long boxes; the lamp table with the hero long box.
	var card := Kit.mat("#e9e4d6", 0.85)
	for t in [Vector3(0, 0, 0), Vector3(-2.6, 0, 0.6), Vector3(-2.6, 0, -1.6)]:
		var hero: bool = t == Vector3(0, 0, 0)
		var top := 0.6 if hero else 0.88
		Kit.box(root, Vector3(1.8, 0.05, 0.8), t + Vector3(0, top, 0), Kit.mat("#4a3424", 0.6))
		for s: float in [-1.0, 1.0]:
			Kit.box(root, Vector3(0.05, top - 0.02, 0.7), t + Vector3(s * 0.85, (top - 0.02) * 0.5, 0), Kit.mat("#2a1e14", 0.6))
		for k in (1 if hero else 3):
			var bx: Vector3 = (t + Vector3(-0.35, 0.62, 0)) if hero else (t + Vector3(-0.55 + k * 0.55, 0.9, 0))
			var hgt := 0.14 if hero else 0.3
			Kit.box(root, Vector3(0.3, 0.02, 0.7), bx + Vector3(0, 0.01, 0), card)
			for s: float in [-1.0, 1.0]:
				Kit.box(root, Vector3(0.01, hgt, 0.7), bx + Vector3(s * 0.15, hgt * 0.5, 0), card)
				Kit.box(root, Vector3(0.3, hgt, 0.01), bx + Vector3(0, hgt * 0.5, s * 0.35), card)
			for j in 22:
				var c := Color(pal[rng.randi() % pal.size()])
				Kit.box(root, Vector3(0.27, 0.27 if not hero else 0.2, 0.006), bx + Vector3(0, 0.13 if not hero else 0.08, -0.32 + j * 0.03),
					Kit.mat(c, 0.6), Vector3(-0.15, 0, 0))
	# The counter and the desk lamp.
	Kit.box(root, Vector3(1.4, 1.0, 0.7), COUNTER + Vector3(0, -0.5, 0), Kit.mat("#3a2818", 0.6))
	Kit.box(root, Vector3(1.5, 0.04, 0.8), COUNTER, Kit.mat("#5a3e26", 0.4))
	Kit.rod(root, Vector3(0.45, 0.62, -0.3), Vector3(0.45, 1.5, -0.3), 0.012, Kit.mat("#202020", 0.4, 0.6), 8)
	Kit.cyl(root, 0.03, 0.12, 0.14, Vector3(0.3, 1.5, -0.2), Kit.mat("#1c3a2a", 0.4, 0.5), 16, Vector3(0.5, 0, 0.6))
	Kit.spot(root, Vector3(0.7, 1.7, 0.6), Vector3(-0.3, 1.05, -0.35), "#ffd09a", 1.3, 4.0, 40.0, true, 0.3)
	Kit.spot(root, Vector3(0.5, 2.4, 1.3), Vector3(0.1, 0.0, 0.55), "#ffd8a8", 2.2, 4.0, 22.0, true, 0.2)
	Kit.omni(root, Vector3(0, 3.2, -1.0), "#9fb8ff", 1.2, 9.0, false, 0.1)
	# The Doom standee by the window: a cardboard cutout (cloak silhouette, the mask).
	var st := Node3D.new()
	st.position = Vector3(3.6, 0, 2.2)
	st.rotation = Vector3(0, -2.6, 0)
	root.add_child(st)
	var green := Kit.mat("#1f5229", 0.85)
	Kit.box(st, Vector3(0.7, 1.3, 0.01), Vector3(0, 0.75, 0), green)
	Kit.box(st, Vector3(1.0, 0.25, 0.01), Vector3(0, 1.35, 0), green)
	var m := MeshInstance3D.new()
	m.mesh = suit().call("_mask", 1.0)
	m.material_override = Kit.mat("#8a9096", 0.45, 0.7)
	m.scale = Vector3(0.24, 0.27, 0.06)
	m.position = Vector3(0, 1.72, 0.01)
	st.add_child(m)
	Kit.box(st, Vector3(0.62, 0.12, 0.012), Vector3(0, 0.2, 0.006), Kit.mat("#101010", 0.6))
	var sl := Kit.text(st, "AVENGERS: DOOMSDAY", 0.06, Color("#e8f0e0"), Vector3(0, 0.2, 0.013), Vector3.ZERO, true)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Kit.box(st, Vector3(0.02, 1.6, 0.3), Vector3(0, 0.8, -0.16), Kit.mat("#c8b89a", 0.9), Vector3(0.15, 0, 0))
	Kit.spot(root, Vector3(2.2, 2.6, 1.0), Vector3(3.6, 1.3, 2.2), "#ffcf9a", 5.0, 5.0, 30.0, true, 0.2)
	# The hero comic and the four stacked comics.
	_comic = _comic_mesh(root, COVER, Color.WHITE)
	var covers: Array = _p.get("covers", [])
	var cols := ["#c8202a", "#1f6fd0", "#b81e1e", "#8a1a1a"]
	for i in 4:
		_stack.append(_comic_mesh(root, String(covers[i]) if i < covers.size() else "", Color(cols[i])))
	_rise = _comic_mesh(root, "", Color("#3a3f46"))
	var rt := Kit.text(_rise, "RISE OF
DOOM", 0.034, Color("#7dff9a"), Vector3(0, 0.07, 0.004), Vector3.ZERO, true, 1.2)
	rt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var em := MeshInstance3D.new()
	em.mesh = suit().call("_mask", 1.0)
	em.material_override = Kit.mat("#9aa0a6", 0.4, 0.7)
	em.scale = Vector3(0.05, 0.056, 0.012)
	em.position = Vector3(0, -0.04, 0.004)
	_rise.add_child(em)
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	# Rain beyond the window.
	var rng := RandomNumberGenerator.new()
	for i in _rain.instance_count:
		rng.seed = 31 + i
		var x := rng.randf_range(-6.0, 6.0)
		var z := rng.randf_range(3.6, 9.0)
		var y := fposmod(rng.randf() * 5.0 - t * 7.0, 5.0)
		_rain.set_instance_transform(i, Transform3D(Basis.from_euler(Vector3(0.08, 0, 0)), Vector3(x, y, z)))
	# The hero comic: in the box (standing, its top edge showing) until the pull, then up in the hand.
	var rest := Transform3D(Basis.from_euler(Vector3(-0.15, 0, 0)), BOX + Vector3(0, 0.1, 0.0))
	var xf := rest
	var pd: Dictionary = _p.get("pull", {})
	if pd.has("actor") and ctx.has("actor"):
		var a = ctx["actor"].call(String(pd["actor"]))
		var pt := float(pd.get("t", 1e9))
		if a != null:
			var reach := Motion.in_out(Motion.seg(t, pt - 0.6, pt - 0.1))
			var draw := Motion.out_cubic(Motion.seg(t, pt - 0.1, pt + 0.5))
			var tilt := Motion.in_out(Motion.seg(t, float(_p.get("tilt", 1e9)), float(_p.get("tilt", 1e9)) + 0.8))
			if reach > 0.0:
				Crawl.long_arms(a, 1.4)
			var inv: Transform3D = node.global_transform.affine_inverse()
			var ay := float(a.rotation.y)
			var fwd := Vector3(sin(ay), 0, cos(ay))
			var held_w: Vector3 = a.bone_world("spine_03") + fwd * 0.4 + Vector3(0, 0.3, 0)
			var held := Transform3D(Basis.from_euler(Vector3(0.1 - 0.35 * tilt, ay + PI + 0.3 * tilt, 0.05)), inv * held_w)
			if draw > 0.0:
				var up := rest.origin + Vector3(0, 0.3, 0)
				var pos: Vector3 = rest.origin.lerp(up, minf(draw * 2.0, 1.0)).lerp(held.origin, clampf(draw * 1.6 - 0.6, 0.0, 1.0))
				xf = Transform3D(Basis(rest.basis.get_rotation_quaternion().slerp(held.basis.get_rotation_quaternion(), draw)), pos)
			var hand_target: Vector3 = node.global_transform * (xf.origin + Vector3(0.08, -0.08, 0))
			if reach > 0.0:
				a.aim_hand("r", hand_target if draw > 0.0 else node.global_transform * (rest.origin + Vector3(0, 0.1, 0)), reach)
	var dt := float(_p.get("drop", 1e9))
	if t >= dt:
		var k := Motion.in_cubic(Motion.seg(t, dt, dt + 0.75))
		var land := Transform3D(Basis.from_euler(Vector3(-PI / 2, 0.5, 0)), Vector3(0.1, 0.006, 0.55))
		var mid := xf.origin.lerp(land.origin, k) + Vector3(0.06 * sin(k * 9.0), 0.15 * sin(PI * k), 0)
		xf = Transform3D(Basis(xf.basis.get_rotation_quaternion().slerp(land.basis.get_rotation_quaternion(), Motion.out_cubic(k))
			* Quaternion(Vector3(0, 0, 1), 0.6 * sin(k * 7.0) * (1.0 - k))), mid if k < 1.0 else land.origin)
	_comic.transform = xf
	# The stack on the counter.
	var st: Array = _p.get("stack", [])
	for i in _stack.size():
		var c := _stack[i]
		var ct := float(st[i]) if i < st.size() else 1e9
		c.visible = t >= ct - 0.35
		if c.visible:
			var k := Motion.in_cubic(Motion.seg(t, ct - 0.35, ct))
			var land := COUNTER + Vector3(-0.25 + 0.17 * i, 0.03 + 0.006 * i, 0.05 - 0.02 * i)
			var y := lerpf(land.y + 0.7, land.y, k)
			var sq := Vector3.ONE
			c.transform = Transform3D(Basis.from_euler(Vector3(-PI / 2 + (1.0 - k) * 0.6, 0.2 * (i - 1.5) + (1.0 - k) * 1.2, 0)).scaled(sq),
				Vector3(land.x, y, land.z))
	var rset := float(_p.get("rise", 1e9))
	_rise.visible = t >= rset - 0.35
	if _rise.visible:
		var k := Motion.in_cubic(Motion.seg(t, rset - 0.35, rset))
		var land := COUNTER + Vector3(0.1, 0.06, 0.12)
		var sq := Motion.squash(Motion.impact(t - rset, 0.25, 6.0, 10.0)) if t > rset else Vector3.ONE
		_rise.transform = Transform3D(Basis.from_euler(Vector3(-PI / 2 + (1.0 - k) * 0.7, 0.15 + (1.0 - k), 0)).scaled(sq),
			Vector3(land.x, lerpf(land.y + 0.8, land.y, k), land.z))
	return {"comic": node.global_transform * xf.origin, "box": node.global_transform * BOX,
		"counter": node.global_transform * COUNTER, "standee": node.global_transform * Vector3(3.6, 1.4, 2.2),
		"window": node.global_transform * Vector3(0, 2.0, 3.2)}
