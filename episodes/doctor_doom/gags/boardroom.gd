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
##   pins      {"<card index>": t}   cards not listed are up from the start; listed ones fly in and pin on t
##             (index 0 is the Kang card, 1 Loki, 2 Quantumania, 3 Loki Season 2, 4 Secret Wars)
##   pins_from t   pins and the flip only apply from here (earlier, e.g. a flash-forward, the plan is complete)
##   flip      t   the Kang card shows its blank back until t, then flips round to its title
##   comic     t   a copy of Fantastic Four #5 drops onto the table and slaps flat
##   chart     {"t": t, "fall": t}   the wall TV draws a box-office line up, then it falls off a cliff from `fall`
##   rebuild   t   the wall stands again with a new plan: AVENGERS: DOOMSDAY and AVENGERS: SECRET WARS
##   contract  t   a contract slides down the table to the near end
##   cans      t   two film cans (X-MEN, FANTASTIC FOUR) slide down the table
## anchors: wall, kang (the centre card), floor, comic, tv
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
var _comic: Node3D
var _tv_line: MeshInstance3D
var _new_cards: Array[Node3D] = []
var _contract: Node3D
var _cans: Array[Node3D] = []
const COMIC_AT := Vector3(-0.15, 0.8, -1.6)
const TV_AT := Vector3(3.3, 1.75, -3.6)


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
		Kit.spot(root, Vector3(0, 2.85, z), Vector3(0, 0.76, z), "#ffd2a0", 5.0, 5.0, 38.0, true, 0.3)
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
	Kit.spot(root, Vector3(0.8, 3.9, -3.2), Vector3(0.6, 0.0, -4.8), "#ffd8a8", 6.0, 6.0, 35.0, true, 0.3)
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
	# The comic (the real cover of Fantastic Four #5) for `comic`.
	_comic = Node3D.new()
	root.add_child(_comic)
	Kit.box(_comic, Vector3(0.18, 0.006, 0.27), Vector3.ZERO, Kit.mat("#efe9da", 0.8))
	var cover := Kit.quad(_comic, Vector2(0.18, 0.27), Vector3(0, 0.0035, 0),
		Kit.textured("library/logos/doom/ff5_doom_debut.jpg"), Vector3(-PI / 2, 0, 0))
	cover.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_comic.visible = false
	# The wall TV on a floor stand, angled to the table, a dark chart screen.
	var tv := Node3D.new()
	tv.position = TV_AT
	tv.rotation = Vector3(0, -1.15, 0)
	root.add_child(tv)
	Kit.box(tv, Vector3(1.4, 0.82, 0.07), Vector3.ZERO, Kit.mat("#0c0c0e", 0.3, 0.4))
	Kit.box(tv, Vector3(1.32, 0.74, 0.01), Vector3(0, 0, 0.036), Kit.lit("#0b1626", 0.6))
	Kit.rod(tv, Vector3(0, -0.4, -0.05), Vector3(0, -1.75, -0.05), 0.03, Kit.mat("#202226", 0.4, 0.6), 8)
	Kit.box(tv, Vector3(0.5, 0.03, 0.4), Vector3(0, -1.74, -0.05), Kit.mat("#202226", 0.4, 0.6))
	for k in 4:
		Kit.box(tv, Vector3(1.2, 0.004, 0.002), Vector3(0, -0.28 + k * 0.17, 0.042), Kit.lit("#22344e", 0.8))
	Kit.text(tv, "QUANTUMANIA  WORLDWIDE BOX OFFICE", 0.045, Color("#9fb6d6"), Vector3(0, 0.31, 0.043), Vector3.ZERO, false, 1.0)
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color("#46ff78")
	_tv_line = MeshInstance3D.new()
	_tv_line.mesh = ImmediateMesh.new()
	_tv_line.material_override = lm
	tv.add_child(_tv_line)
	Kit.omni(root, TV_AT + Vector3(-0.5, 0, 0.3), "#5a8ad0", 0.8, 3.5, false, 0.1)
	# The new plan for `rebuild`.
	for c in [["AVENGERS:\nDOOMSDAY", -0.95, "#1f4d27"], ["AVENGERS:\nSECRET WARS", 0.95, "#1e2a4a"]]:
		var nc := Node3D.new()
		root.add_child(nc)
		Kit.box(nc, Vector3(1.25, 0.9, 0.012), Vector3(0, -0.45, 0), Kit.mat(String(c[2]), 0.7))
		var lab := Kit.text(nc, String(c[0]), 0.15, Color("#f2ead8"), Vector3(0, -0.45, 0.012), Vector3.ZERO, true)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Kit.ball(nc, 0.025, Vector3(0, -0.04, 0.02), Kit.mat("#c81e1e", 0.4), 10)
		nc.position = Vector3(float(c[1]), 2.95, WALL_Z + 0.02)
		nc.visible = false
		_new_cards.append(nc)
	# The contract and its pen; two film cans.
	_contract = Node3D.new()
	root.add_child(_contract)
	Kit.box(_contract, Vector3(0.21, 0.004, 0.297), Vector3.ZERO, Kit.mat("#f4f1e8", 0.85))
	for l in 9:
		Kit.box(_contract, Vector3(0.15 if l < 8 else 0.07, 0.001, 0.004), Vector3(-0.01 if l < 8 else 0.03, 0.0025, -0.11 + l * 0.024),
			Kit.mat("#4a4a56", 0.8))
	Kit.rod(_contract, Vector3(0.06, 0.01, 0.06), Vector3(0.12, 0.01, -0.05), 0.006, Kit.mat("#111111", 0.3, 0.6), 8)
	_contract.visible = false
	for c in [["X-MEN", "#c8c8c8"], ["FANTASTIC FOUR", "#c8c8c8"]]:
		var can := Node3D.new()
		root.add_child(can)
		Kit.cyl(can, 0.19, 0.19, 0.045, Vector3.ZERO, Kit.mat(String(c[1]), 0.35, 0.85), 32)
		Kit.cyl(can, 0.08, 0.08, 0.047, Vector3.ZERO, Kit.mat("#2a2a2e", 0.5, 0.6), 24)
		Kit.box(can, Vector3(0.22, 0.002, 0.07), Vector3(0, 0.024, 0.11), Kit.mat("#f2ead8", 0.8))
		Kit.text(can, String(c[0]), 0.035, Color("#1a1a1a"), Vector3(0, 0.026, 0.11), Vector3(-PI / 2, 0, 0), true)
		can.visible = false
		_cans.append(can)
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
	var pins: Dictionary = _p.get("pins", {})
	var pins_from := float(_p.get("pins_from", -1e9))
	var flip_t := float(_p.get("flip", -1e9)) if t >= pins_from else -1e9
	var rebuild_t := float(_p.get("rebuild", 1e9))
	var rebuilt := t >= rebuild_t
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
			# Blank back until `flip`.
			var fk := Motion.out_back(Motion.seg(t, flip_t, flip_t + 0.45), 1.3)
			xf.basis = xf.basis * Basis.from_euler(Vector3(0, PI * (1.0 - fk), 0))
			_cards[i].transform = xf
		else:
			var d := absf(rest.origin.x) * 0.12
			_cards[i].transform = _fall(rest, col_t + d + 0.05 * i, t, 50 + i, 0.02)
		# Pinned in on its time: flies in from the room on an arc and slaps onto the cork.
		_cards[i].visible = not rebuilt
		if pins.has(str(i)) and t >= pins_from:
			var pt := float(pins[str(i)])
			if t < pt - 0.4:
				_cards[i].visible = false
			elif t < pt:
				var k := Motion.out_cubic(Motion.seg(t, pt - 0.4, pt))
				var from := rest.origin + Vector3(0.6 * signf(rest.origin.x + 0.01), -0.9, 2.2)
				var pos: Vector3 = Motion.arc(from, rest.origin, 0.4, k)
				_cards[i].transform = Transform3D(rest.basis * Basis.from_euler(Vector3(0.6 * (1.0 - k), 0.8 * (1.0 - k), 0)), pos)
			elif t < pt + 0.25:
				_cards[i].scale = Motion.squash(Motion.impact(t - pt, 0.25, 6.0, 10.0))
		if t >= float(pins.get(str(i), -1e9)) + 0.25:
			_cards[i].scale = Vector3.ONE
	for i in _notes.size():
		var rest := _note_rest[i]
		var d := Vector2(rest.origin.x, rest.origin.y - 2.7).length() * 0.12
		_notes[i].transform = _fall(rest, col_t + d, t, 200 + i, 0.01)
	if rebuilt:
		for i in _notes.size():
			_notes[i].transform = _note_rest[i]
	for nc in _new_cards:
		nc.visible = rebuilt
	# The comic drops onto the table and slaps flat.
	var ct := float(_p.get("comic", 1e9))
	_comic.visible = t >= ct - 0.45
	if _comic.visible:
		var k := Motion.in_cubic(Motion.seg(t, ct - 0.45, ct))
		var y := lerpf(COMIC_AT.y + 0.9, COMIC_AT.y + 0.004, k)
		var tilt := (1.0 - k) * 0.9
		var sq := Vector3.ONE
		if t > ct:
			sq = Motion.squash(Motion.impact(t - ct, 0.18, 6.0, 10.0))
		_comic.transform = Transform3D(Basis.from_euler(Vector3(tilt, 0.35 + 0.4 * (1.0 - k), tilt * 0.5)).scaled(sq),
			Vector3(COMIC_AT.x, y, COMIC_AT.z))
	# The box-office line on the TV.
	var cd: Dictionary = _p.get("chart", {})
	var cim := _tv_line.mesh as ImmediateMesh
	cim.clear_surfaces()
	if cd.has("t"):
		var draw := Motion.in_out(Motion.seg(t, float(cd["t"]), float(cd["t"]) + 1.0))
		var drop := Motion.in_cubic(Motion.seg(t, float(cd.get("fall", 1e9)), float(cd.get("fall", 1e9)) + 0.9))
		var pts: Array[Vector3] = []
		var n := 40
		for j in n + 1:
			var u := float(j) / n
			if u > draw * 0.55 + drop * 0.45 + 0.001:
				break
			var v := 0.0
			if u <= 0.55:
				v = -0.25 + 0.5 * pow(u / 0.55, 0.5)
			else:
				v = 0.25 - 0.5 * pow((u - 0.55) / 0.45, 0.6)
			pts.append(Vector3(-0.6 + 1.2 * u, v, 0.044))
		if pts.size() > 1:
			cim.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			for j in pts.size() - 1:
				var w := Vector3(0, 0.008, 0)
				for v in [pts[j] - w, pts[j] + w, pts[j + 1] + w, pts[j] - w, pts[j + 1] + w, pts[j + 1] - w]:
					cim.surface_add_vertex(v)
			cim.surface_end()
	# The contract and the film cans slide down the table.
	var kt := float(_p.get("contract", 1e9))
	_contract.visible = t >= kt - 0.6
	if _contract.visible:
		var k := Motion.out_cubic(Motion.seg(t, kt - 0.6, kt))
		_contract.transform = Transform3D(Basis.from_euler(Vector3(0, 0.3 * (1.0 - k) + 0.1, 0)), Vector3(0.1, 0.803, lerpf(-3.6, 1.4, k)))
	var nt := float(_p.get("cans", 1e9))
	for j in _cans.size():
		_cans[j].visible = t >= nt - 0.7
		if _cans[j].visible:
			var k := Motion.out_cubic(Motion.seg(t, nt - 0.7 + 0.15 * j, nt + 0.15 * j))
			_cans[j].transform = Transform3D(Basis.from_euler(Vector3(0, 2.0 * (1.0 - k) + 0.2 * j, 0)),
				Vector3(-0.25 + 0.5 * j, 0.81, lerpf(-3.8, 1.0 - 0.1 * j, k)))
	# The cork wall topples forward at the end of the wave.
	var wall_t := col_t + 0.8
	var wk := Motion.in_cubic(Motion.seg(t, wall_t, wall_t + 0.55))
	var bounce := 0.0
	if t > wall_t + 0.55:
		bounce = Motion.impact(t - (wall_t + 0.55), 0.06, 5.0, 8.0)
	if rebuilt:
		wk = 0.0
		bounce = 0.0
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
		if rebuilt or not _cards[i].visible or not _cards[0].visible:
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
	if rebuilt and _new_cards.size() == 2:
		var a0 := _new_cards[0].position + Vector3(0, -0.04, 0.02)
		var a1 := _new_cards[1].position + Vector3(0, -0.04, 0.02)
		if not begun:
			im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			begun = true
		for j in 12:
			var u0 := float(j) / 12.0
			var u1 := float(j + 1) / 12.0
			var p0 := a0.lerp(a1, u0) + Vector3(0, -0.06 * sin(PI * u0), 0.01)
			var p1 := a0.lerp(a1, u1) + Vector3(0, -0.06 * sin(PI * u1), 0.01)
			var w := Vector3(0, 0.005, 0)
			for v in [p0 - w, p0 + w, p1 + w, p0 - w, p1 + w, p1 - w]:
				im.surface_add_vertex(v)
	if begun:
		im.surface_end()
	return {"wall": node.global_transform * Vector3(0, 2.1, WALL_Z), "kang": node.global_transform * KANG,
		"floor": node.global_transform * Vector3(0, 0, -4.5), "comic": node.global_transform * COMIC_AT,
		"tv": node.global_transform * TV_AT}
