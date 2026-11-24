## Marvel Studios, a boardroom at night: dark wood panels, a long walnut table with leather chairs and pendant lamps,
## a glass wall onto the night city (the look's panorama), and at the far end the saga plan: a cork wall of title
## cards (the real titles of the Multiverse Saga built round Kang) tied with red string to the big centre card,
## THE KANG DYNASTY. On `pull` the actor yanks the centre card off; on `collapse` the strings go slack, the cards
## peel off their pins and flutter down in a wave from the centre, and the cork wall itself topples onto the floor.
##
## Local frame: the plan wall at z -6.0 facing +z (its face at z -5.85), centre (0, 2.1); the table runs from z -4.3
## to z 2.5 along x 0; cameras at +z looking -z.
##
## params:
##   pull      {"actor": id, "t": t}   the actor reaches up and tears the centre card off on t (keeps it in hand)
##   collapse  t   the wave of falling cards, then the wall
## anchors: wall, kang (the centre card), floor
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Paths = preload("res://scripts/core/paths.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")

const PH := "incoming/polyhaven_doom/"
const WALL_Z := -5.85
const KANG := Vector3(0, 2.75, -5.82)

# (title, x, y, w, h, colour): the real titles; the Kang card in the middle at the top.
const CARDS := [
	["THE KANG\nDYNASTY", 0.0, 2.75, 1.25, 0.9, "#3b2a6a"],
	["LOKI", -2.35, 2.55, 0.8, 1.05, "#2a4a2a"],
	["ANT-MAN AND THE WASP:\nQUANTUMANIA", -1.25, 1.55, 0.9, 1.15, "#5a2a1e"],
	["LOKI\nSEASON 2", 1.3, 1.55, 0.8, 1.05, "#26403a"],
	["AVENGERS:\nSECRET WARS", 2.45, 2.55, 0.95, 1.1, "#1e2a4a"],
]

var _p := {}
var _cards: Array[Node3D] = []        # [0] = Kang
var _card_rest: Array[Transform3D] = []
var _notes: Array[Node3D] = []
var _note_rest: Array[Transform3D] = []
var _strings: MeshInstance3D
var _wall: Node3D
var _string_mat: StandardMaterial3D


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "board"))
	var wood := Kit.textured(PH + "textures/dark_wood_diff_2k.jpg", PH + "textures/dark_wood_nor_gl_2k.jpg",
		PH + "textures/dark_wood_rough_2k.jpg", Vector3(3, 3, 1), Color("#8a6a52"))
	var carpet := Kit.textured(PH + "textures/dirty_carpet_diff_2k.jpg", PH + "textures/dirty_carpet_nor_gl_2k.jpg",
		PH + "textures/dirty_carpet_rough_2k.jpg", Vector3(8, 8, 1), Color("#3a3a44"))
	# Room: carpet, wood-panelled end and left walls, a glass wall on the right with thin mullions, a dark ceiling.
	Kit.box(root, Vector3(10, 0.1, 13), Vector3(0, -0.05, -0.5), carpet)
	Kit.box(root, Vector3(10, 4.0, 0.2), Vector3(0, 2.0, -6.3), wood)
	Kit.box(root, Vector3(0.2, 4.0, 13), Vector3(-4.6, 2.0, -0.5), wood)
	for k in 12:
		Kit.box(root, Vector3(0.06, 4.0, 0.06), Vector3(-4.48, 2.0, -6.0 + k * 1.1), Kit.mat("#1a120c", 0.5))
	Kit.box(root, Vector3(10, 0.2, 13), Vector3(0, 4.05, -0.5), Kit.mat("#141416", 0.8))
	var glass := Kit.mat("#0a0c10", 0.05, 0.0, 0.9)
	glass = glass.duplicate()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.05, 0.06, 0.08, 0.18)
	Kit.box(root, Vector3(0.04, 4.0, 13), Vector3(4.6, 2.0, -0.5), glass)
	for k in 9:
		Kit.box(root, Vector3(0.08, 4.0, 0.08), Vector3(4.58, 2.0, -6.0 + k * 1.6), Kit.mat("#202226", 0.4, 0.6))
	# The table, the chairs, the lamps.
	Kit.slab(root, Vector3(1.6, 0.07, 6.6), 0.4, Vector3(0, 0.76, -0.9), wood)
	for z: float in [-3.6, 1.8]:
		Kit.box(root, Vector3(0.9, 0.7, 0.12), Vector3(0, 0.37, z), Kit.mat("#141210", 0.6))
	var chair := PH + "models/modern_arm_chair_01/modern_arm_chair_01_2k.gltf"
	for i in 5:
		var z := -3.6 + i * 1.3
		for s: float in [-1.0, 1.0]:
			var c := Kit.model(chair)
			c.position = Vector3(s * 1.15, 0, z)
			c.rotation = Vector3(0, -s * PI / 2, 0)
			root.add_child(c)
	for i in 3:
		var z := -3.2 + i * 2.2
		var lamp := Kit.model(PH + "models/modern_ceiling_lamp_01/modern_ceiling_lamp_01_2k.gltf")
		lamp.position = Vector3(0, 2.9, z)
		root.add_child(lamp)
		Kit.rod(root, Vector3(0, 3.3, z), Vector3(0, 4.0, z), 0.006, Kit.mat("#111111", 0.5), 4)
		Kit.spot(root, Vector3(0, 2.85, z), Vector3(0, 0.76, z), "#ffd2a0", 9.0, 5.0, 38.0, true, 0.3)
	var notes := PH + "models/office_notepads/office_notepads_2k.gltf"
	if not FileAccess.file_exists(Paths.repo_path(notes)):
		notes = "incoming/polyhaven_pokhran/models/office_notepads/office_notepads_2k.gltf"
	for i in 4:
		var n := Kit.model(notes)
		n.position = Vector3(-0.45 if i % 2 == 0 else 0.45, 0.8, -3.2 + i * 1.4)
		n.rotation = Vector3(0, 0.3 * (i - 1.5), 0)
		root.add_child(n)
	# The plan wall: cork on a frame, lit by two picture lights.
	_wall = Node3D.new()
	_wall.name = "plan_wall"
	root.add_child(_wall)
	var cork := Kit.mat("#a7834f", 0.95)
	Kit.box(_wall, Vector3(6.6, 2.9, 0.08), Vector3(0, 2.05, -5.95), cork)
	for s: float in [-1.0, 1.0]:
		Kit.box(_wall, Vector3(6.8, 0.08, 0.12), Vector3(0, 2.05 + s * 1.48, -5.93), Kit.mat("#2a1e14", 0.6))
		Kit.box(_wall, Vector3(0.08, 3.0, 0.12), Vector3(s * 3.36, 2.05, -5.93), Kit.mat("#2a1e14", 0.6))
	Kit.spot(root, Vector3(-1.8, 3.9, -4.2), Vector3(-1.0, 2.1, -5.9), "#ffe2bc", 7.0, 6.0, 42.0, true, 0.4)
	Kit.spot(root, Vector3(1.8, 3.9, -4.2), Vector3(1.0, 2.1, -5.9), "#ffe2bc", 7.0, 6.0, 42.0, true, 0.4)
	# Title cards (poster boards with their titles) on pins.
	for c in CARDS:
		var card := Node3D.new()
		root.add_child(card)
		var w := float(c[3])
		var h := float(c[4])
		Kit.box(card, Vector3(w, h, 0.012), Vector3(0, -h * 0.5, 0), Kit.mat(String(c[5]), 0.7))
		Kit.box(card, Vector3(w - 0.06, h - 0.06, 0.004), Vector3(0, -h * 0.5, 0.007), Kit.mat(String(c[5]).replace("#", "#") , 0.5))
		var th := 0.17 if w > 1.0 else 0.1
		var label := Kit.text(card, String(c[0]), th, Color("#f2ead8"), Vector3(0, -h * 0.5, 0.012), Vector3.ZERO, true)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Kit.ball(card, 0.025, Vector3(0, -0.04, 0.02), Kit.mat("#c81e1e", 0.4), 10)
		var xf := Transform3D(Basis.IDENTITY, Vector3(float(c[1]), float(c[2]) + h * 0.5, WALL_Z + 0.02))
		card.transform = xf
		_cards.append(card)
		_card_rest.append(xf)
	# Sticky notes and index cards scattered round them.
	var rng := Kit.rng("board_notes")
	var note_cols := ["#f2e46a", "#f4f1e6", "#f2a6b6", "#9ed7f2", "#f4f1e6"]
	for i in 34:
		var nd := Node3D.new()
		root.add_child(nd)
		var big := i % 3 == 0
		var sz := Vector2(0.2, 0.13) if big else Vector2(0.11, 0.11)
		Kit.box(nd, Vector3(sz.x, sz.y, 0.003), Vector3(0, -sz.y * 0.5, 0), Kit.mat(note_cols[i % note_cols.size()], 0.8))
		for l in 3:
			Kit.box(nd, Vector3(sz.x * 0.7, 0.006, 0.002), Vector3(0, -0.03 - l * 0.025, 0.002), Kit.mat("#3a3a48", 0.8))
		var x := rng.randf_range(-3.1, 3.1)
		var y := rng.randf_range(0.75, 3.45)
		var xf := Transform3D(Basis.from_euler(Vector3(0, 0, rng.randf_range(-0.12, 0.12))), Vector3(x, y, WALL_Z + 0.015))
		nd.transform = xf
		_notes.append(nd)
		_note_rest.append(xf)
	# Red string (rebuilt each frame).
	_string_mat = StandardMaterial3D.new()
	_string_mat.albedo_color = Color("#c81e1e")
	_string_mat.roughness = 0.6
	_strings = MeshInstance3D.new()
	_strings.mesh = ImmediateMesh.new()
	_strings.material_override = _string_mat
	_strings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(_strings)
	return root


## A falling card: pinned until t0, swings down off its pin, peels off and flutters to the floor.
func _fall(rest: Transform3D, t0: float, t: float, seed: int, floor_y: float) -> Transform3D:
	var k := t - t0
	if k <= 0.0:
		return rest
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var side := rng.randf_range(-1.0, 1.0)
	# Swing on the pin (0..0.25 s), then drop with flutter.
	var swing := Motion.out_back(clampf(k / 0.25, 0.0, 1.0), 1.4) * side * 0.6
	var drop := maxf(k - 0.2, 0.0)
	var y := rest.origin.y - 2.2 * drop * drop - 0.4 * drop
	var land := false
	if y < floor_y:
		y = floor_y
		land = true
	var x := rest.origin.x + side * 0.4 * drop + 0.08 * sin(drop * 9.0 + seed)
	var z := rest.origin.z + 0.5 * drop + 0.3 * drop * drop
	var tilt := Vector3(0.6 * drop + 0.3 * sin(drop * 7.0 + seed), 0.4 * side * drop, swing + 0.5 * side * drop)
	if land:
		tilt = Vector3(-PI / 2 + 0.05 * side, side * 0.6, 0)
	return Transform3D(Basis.from_euler(tilt), Vector3(x, y, z))


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var col_t := float(_p.get("collapse", 1e9))
	var pd: Dictionary = _p.get("pull", {})
	var pull_t := float(pd.get("t", 1e9))
	# Cards: the Kang card in hand after the pull, the others in a wave from the centre.
	for i in _cards.size():
		var rest := _card_rest[i]
		if i == 0:
			var xf := rest
			if t >= pull_t and ctx.has("actor") and pd.has("actor"):
				var a = ctx["actor"].call(String(pd["actor"]))
				if a != null:
					var k := Motion.out_cubic(Motion.seg(t, pull_t, pull_t + 0.25))
					var hand: Vector3 = node.global_transform.affine_inverse() * a.bone_world("hand_r")
					var held := Transform3D(Basis.from_euler(Vector3(0.2, 0.3, -0.5)), hand + Vector3(0, 0.35, 0.05))
					xf = Transform3D(Basis(rest.basis.get_rotation_quaternion().slerp(held.basis.get_rotation_quaternion(), k)),
						rest.origin.lerp(held.origin, k))
			_cards[i].transform = xf
		else:
			var d := absf(rest.origin.x) * 0.12
			_cards[i].transform = _fall(rest, col_t + d + 0.05 * i, t, 50 + i, 0.02)
	for i in _notes.size():
		var rest := _note_rest[i]
		var d := Vector2(rest.origin.x, rest.origin.y - 2.7).length() * 0.12
		_notes[i].transform = _fall(rest, col_t + d, t, 200 + i, 0.01)
	# The cork wall topples forward at the end of the wave.
	var wall_t := col_t + 0.8
	var wk := Motion.in_cubic(Motion.seg(t, wall_t, wall_t + 0.55))
	var bounce := 0.0
	if t > wall_t + 0.55:
		bounce = Motion.impact(t - (wall_t + 0.55), 0.06, 5.0, 8.0)
	_wall.transform = Transform3D(Basis.from_euler(Vector3(wk * 1.38 - bounce, 0, 0)), Vector3(0, 0, -5.95)) \
		* Transform3D(Basis.IDENTITY, Vector3(0, 0, 5.95))
	# Strings: from every card's pin to the Kang card's pin; sag goes slack once a card moves.
	var im := _strings.mesh as ImmediateMesh
	im.clear_surfaces()
	var kp := _cards[0].transform.origin + Vector3(0, -0.04, 0.02)
	var begun := false
	for i in range(1, _cards.size()):
		var cp := _cards[i].transform.origin + _cards[i].transform.basis * Vector3(0, -0.04, 0.02)
		var moved := t > col_t + absf(_card_rest[i].origin.x) * 0.12 + 0.05 * i or t > pull_t
		if t > pull_t + 0.6 and t > col_t + 0.3:
			continue
		var sag := 0.05 if not moved else 0.35
		if not begun:
			im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			begun = true
		var n := 12
		for j in n:
			var u0 := float(j) / n
			var u1 := float(j + 1) / n
			var p0 := kp.lerp(cp, u0) + Vector3(0, -sag * sin(PI * u0), 0.01)
			var p1 := kp.lerp(cp, u1) + Vector3(0, -sag * sin(PI * u1), 0.01)
			var w := Vector3(0, 0.005, 0)
			for v in [p0 - w, p0 + w, p1 + w, p0 - w, p1 + w, p1 - w]:
				im.surface_add_vertex(v)
	if begun:
		im.surface_end()
	return {"wall": node.global_transform * Vector3(0, 2.1, WALL_Z), "kang": node.global_transform * KANG,
		"floor": node.global_transform * Vector3(0, 0, -4.5)}
