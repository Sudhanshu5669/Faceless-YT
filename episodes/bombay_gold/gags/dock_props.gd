## The Fort Stikine's cargo and the dock's hero props (same frame as dock.gd: water y 0, near quay edge z +11.5,
## deck 2.6; No. 2 hold at x +33, bow +x):
##   loads    {"t": [t_torpedo, t_mine, t_shells]}   three derrick loads swing down over No. 2 hold, one per word,
##            stacked in height (torpedo highest, then a mine, then a pallet of shells)
##   cotton   {"lift": t}   a stack of raw-cotton bales on the quay; a sling of bales rises toward the hook on `lift`
##   gold     {"land": t, "glint": t}   crates of gold in a rope sling lowered to the quay; a lid slips, gold glints
##   halyard  true   the foremast's empty signal halyard (no red flag), flapping
##   binoculars {"actor": id, "lower": t}   the officer holds binoculars to his eyes, lowers them on `lower`
##   cap      {"actor": id}   (unused here)
## anchors: loads, bales, sling, gold, crate, halyard_top
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Paths = preload("res://scripts/core/paths.gd")

const SK := "incoming/bombay_gold/sketchfab/"
const PH := "incoming/bombay_gold/polyhaven/"
const QZ := 11.5
const QH := 2.6
const HOLD2 := Vector3(32.0, 8.4, 0.0)
const FOREMAST := Vector3(40.0, 24.0, 0.0)
const BALES := Vector3(36.0, QH, QZ + 6.4)
const GOLD := Vector3(30.0, QH, QZ + 4.0)

var _p := {}
var _loads: Array[Node3D] = []
var _cables: Array[MeshInstance3D] = []
var _sling: Node3D
var _stack: Node3D
var _sling_rope: MeshInstance3D
var _gold: Node3D
var _gold_lid: Node3D
var _gold_rope: MeshInstance3D
var _glint: OmniLight3D
var _halyard: Array[MeshInstance3D] = []
var _bino: Node3D
var _gold_mat: StandardMaterial3D


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "dock_props"))
	var steel := Kit.mat("#3a3a3c", 0.4, 0.8)
	var rope := Kit.mat("#c2ad84", 0.9)
	_gold_mat = Kit.mat("#f0c040", 0.22, 1.0)
	# Three derrick loads: a torpedo, a moored mine, a pallet of shells; each on a hook and a wire.
	var specs := [[SK + "submarine_torpedo_weapon.glb", 32.3, Vector3(0, 0, 0)], [SK + "old_sea_mine.glb", 1.15, Vector3.ZERO], ["shells", 1.0, Vector3.ZERO]]
	for i in 3:
		var holder := Node3D.new()
		root.add_child(holder)
		if specs[i][0] == "shells":
			var pallet := Kit.box(holder, Vector3(1.6, 0.14, 1.2), Vector3(0, -0.07, 0), Kit.mat("#8a6a44", 0.9))
			pallet.name = "pallet"
			for r in 3:
				for c in 4:
					var s := Kit.model(SK + "artillery_shell.glb")
					s.scale = Vector3.ONE * 0.62
					s.rotation.y = PI * 0.5
					s.position = Vector3(-0.55 + c * 0.36, 0.1 + r * 0.17, 0.0)
					holder.add_child(s)
			for s2: float in [-1.0, 1.0]:
				Kit.rod(holder, Vector3(s2 * 0.75, 0.0, 0.55), Vector3(0, 1.4, 0), 0.02, rope, 5)
				Kit.rod(holder, Vector3(s2 * 0.75, 0.0, -0.55), Vector3(0, 1.4, 0), 0.02, rope, 5)
		else:
			var m := Kit.model(specs[i][0])
			m.scale = Vector3.ONE * float(specs[i][1])
			holder.add_child(m)
			var b := Kit.bounds(m)
			m.position = -b.get_center()
			if i == 0:
				m.rotation.y = PI * 0.5
				m.position = Vector3(0, 0, 0)
				for s2: float in [-1.0, 1.0]:
					Kit.rod(holder, Vector3(s2 * 1.6, 0.25, 0), Vector3(0, 1.6, 0), 0.025, rope, 5)
			else:
				Kit.rod(holder, Vector3(0, 0.5, 0), Vector3(0, 1.4, 0), 0.03, steel, 5)
		Kit.box(holder, Vector3(0.1, 0.35, 0.06), Vector3(0, 1.55, 0), steel)
		_loads.append(holder)
		var cab := MeshInstance3D.new()
		cab.material_override = steel
		root.add_child(cab)
		_cables.append(cab)
	# Raw cotton: a stack of jute-wrapped bales with iron bands, and a sling load of six.
	var jute: Material = load(Paths.repo_path("episodes/bombay_gold/gags/fx.gd")).bale_material()
	var band := Kit.mat("#3a3632", 0.5, 0.7)
	var rng := Kit.rng("bales")
	_stack = Node3D.new()
	root.add_child(_stack)
	for row in 4:
		for col in 6:
			for lay in 3 - (row / 2):
				var p := BALES + Vector3(-4.0 + col * 1.42 + rng.randf_range(-0.05, 0.05), 0.34 + lay * 0.7, row * 0.95)
				_bale(_stack, p, rng.randf_range(-0.06, 0.06), jute, band)
	_sling = Node3D.new()
	root.add_child(_sling)
	for k in 6:
		_bale(_sling, Vector3(-0.72 + (k % 2) * 1.44, 0.34 + (k / 2) * 0.7, 0.0), 0.0, jute, band)
	for s2: float in [-1.0, 1.0]:
		Kit.rod(_sling, Vector3(s2 * 1.5, 0.0, 0.5), Vector3(0, 3.6, 0), 0.03, rope, 5)
		Kit.rod(_sling, Vector3(s2 * 1.5, 0.0, -0.5), Vector3(0, 3.6, 0), 0.03, rope, 5)
	Kit.box(_sling, Vector3(0.12, 0.4, 0.08), Vector3(0, 3.75, 0), steel)
	_sling_rope = MeshInstance3D.new()
	_sling_rope.material_override = steel
	root.add_child(_sling_rope)
	# Gold: small heavy crates in a rope sling; the top crate's lid slips, showing the bars.
	_gold = Node3D.new()
	root.add_child(_gold)
	var crate_wood := Kit.mat("#6e5034", 0.85)
	for k in 4:
		var c := Kit.model(PH + "models/wooden_crate_01/wooden_crate_01_2k.gltf")
		c.scale = Vector3.ONE * 0.85
		c.position = Vector3(-0.38 + (k % 2) * 0.76, (k / 2) * 0.31, 0)
		_gold.add_child(c)
	var top := Node3D.new()
	top.position = Vector3(0.0, 0.62, 0.0)
	_gold.add_child(top)
	Kit.box(top, Vector3(0.66, 0.24, 0.32), Vector3(0, 0.12, 0), crate_wood)
	for bx in 4:
		var bar := Kit.box(top, Vector3(0.14, 0.05, 0.26), Vector3(-0.23 + bx * 0.155, 0.25, 0), _gold_mat)
		bar.scale = Vector3(1.0, 1.0, 1.0)
	_gold_lid = Node3D.new()
	_gold_lid.position = Vector3(0.0, 0.25, 0.0)
	top.add_child(_gold_lid)
	Kit.box(_gold_lid, Vector3(0.68, 0.03, 0.34), Vector3(0, 0.015, 0), crate_wood)
	for s2: float in [-1.0, 1.0]:
		Kit.rod(_gold, Vector3(s2 * 0.85, 0.0, 0.2), Vector3(0, 2.8, 0), 0.025, rope, 5)
		Kit.rod(_gold, Vector3(s2 * 0.85, 0.0, -0.2), Vector3(0, 2.8, 0), 0.025, rope, 5)
	Kit.box(_gold, Vector3(0.1, 0.35, 0.06), Vector3(0, 2.95, 0), steel)
	_gold_rope = MeshInstance3D.new()
	_gold_rope.material_override = steel
	root.add_child(_gold_rope)
	_glint = Kit.omni(top, Vector3(0, 0.45, 0.25), "#ffd27a", 0.0, 2.5, false, 0.0)
	# The foremast's signal halyards: two thin lines from the yard down to the rail, nothing bent on.
	for k in 2:
		var h := MeshInstance3D.new()
		h.material_override = Kit.mat("#d8cfba", 0.8)
		root.add_child(h)
		_halyard.append(h)
	Kit.rod(root, FOREMAST + Vector3(0, -2.0, -4.5), FOREMAST + Vector3(0, -2.0, 4.5), 0.12, Kit.mat("#3a3530", 0.6, 0.4), 8)
	# Binoculars (two short barrels and a bridge).
	_bino = Node3D.new()
	_bino.visible = false
	root.add_child(_bino)
	var black := Kit.mat("#141414", 0.4, 0.4)
	for s2: float in [-1.0, 1.0]:
		Kit.cyl(_bino, 0.035, 0.04, 0.16, Vector3(s2 * 0.045, 0, 0), black, 12, Vector3(PI * 0.5, 0, 0))
	Kit.box(_bino, Vector3(0.06, 0.03, 0.05), Vector3.ZERO, black)
	return root


func _bale(parent: Node3D, p: Vector3, yaw: float, jute: Material, band: Material) -> void:
	Kit.slab(parent, Vector3(1.36, 0.66, 0.86), 0.12, p, jute, Vector3(0, yaw, 0))


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var inv := gt.affine_inverse()
	# Derrick loads: each swings down into place on its word, from a hook 14 m higher, settling with a sway.
	var ld: Dictionary = _p.get("loads", {})
	var lt: Array = ld.get("t", [1e9, 1e9, 1e9])
	var spots := [HOLD2 + Vector3(-1.2, 8.8, -0.6), HOLD2 + Vector3(0.8, 5.6, 0.4), HOLD2 + Vector3(-0.4, 2.4, 1.0)]
	var l_until := float(ld.get("until", 1e9))
	for i in 3:
		var t0 := float(lt[i]) - 0.45
		var u := clampf((t - t0) / 0.65, 0.0, 1.0)
		var drop := (1.0 - Motion.out_back(u, 1.2)) * 16.0
		var sway := 0.0
		if u > 0.0:
			sway = 0.35 * exp(-(t - t0) * 1.6) * sin((t - t0) * 3.2)
		var top: Vector3 = spots[i] + Vector3(0, 30.0, 0)
		var p: Vector3 = spots[i] + Vector3(sin(sway) * 2.0, drop, 0)
		_loads[i].position = p
		_loads[i].rotation = Vector3(0, 0.3 * i + t * 0.05, -sway * 0.4)
		_loads[i].visible = u > 0.0 and t < l_until
		_cables[i].visible = u > 0.0 and t < l_until
		_rod(_cables[i], p + Vector3(0, 1.7, 0), top, 0.02)
	# Cotton: the sling rises from the quay toward the derrick head on `lift`.
	var cd: Dictionary = _p.get("cotton", {})
	var lift := float(cd.get("lift", 1e9))
	var lu := Motion.smooth(clampf((t - lift + 0.3) / 2.4, 0.0, 1.0))
	var sp := BALES + Vector3(-0.5, 2.1, 1.2) + Vector3(-lu * 2.0, lu * 9.0, -lu * 7.0)
	var ssw := 0.12 * sin(t * 1.9) * lu
	_sling.position = sp
	_sling.rotation = Vector3(0, 0.2 * lu, ssw)
	_rod(_sling_rope, sp + Vector3(0, 3.9, 0), HOLD2 + Vector3(4.0, 26.0, 4.0), 0.02)
	_sling.visible = not cd.is_empty() and t < float(cd.get("until", 1e9))
	_sling_rope.visible = _sling.visible
	_stack.visible = t < float(cd.get("until", 1e9))
	# Gold: lowered to the quay on `land`; the top lid slips on `glint`, the bars catch the light.
	var gd: Dictionary = _p.get("gold", {})
	var land := float(gd.get("land", 1e9))
	var gu := clampf((t - (land - 1.6)) / 1.6, 0.0, 1.0)
	var gy := (1.0 - Motion.out_back(gu, 1.1)) * 5.0
	var gsw := 0.06 * sin(t * 2.3) * (1.0 - gu * 0.7)
	_gold.position = GOLD + Vector3(0, gy, 0)
	_gold.rotation = Vector3(0, 0.25, gsw)
	_rod(_gold_rope, _gold.position + Vector3(0, 3.1, 0), GOLD + Vector3(0, 24.0, -6.0), 0.02)
	var glint := float(gd.get("glint", 1e9))
	var lk := Motion.out_back(clampf((t - glint) / 0.35, 0.0, 1.0), 1.6)
	_gold_lid.rotation = Vector3(0, 0, -lk * 0.35)
	_gold_lid.position = Vector3(lk * 0.22, 0.25 + lk * 0.04, 0)
	_glint.light_energy = (1.6 * exp(-(t - glint) * 1.2) + 0.5) if t > glint else 0.0
	_gold.visible = not gd.is_empty() and t < float(gd.get("until", 1e9))
	_gold_rope.visible = _gold.visible
	# Halyards: slack lines from the yard, flapping in the breeze, empty.
	var hy: bool = _p.get("halyard", false)
	for k in 2:
		var a := FOREMAST + Vector3(0, -2.0, -3.6 + k * 7.2)
		var b := Vector3(FOREMAST.x - 2.0 + k * 0.6, 6.6, -6.5 + k * 13.0)
		var mid := a.lerp(b, 0.5) + Vector3(0.6 * sin(t * 2.6 + k), 0.0, 0.5 * sin(t * 3.4 + k * 2.0))
		_rod(_halyard[k], a, mid, 0.025)
		_halyard[k].visible = hy
	# Binoculars: at the officer's eyes, lowered on `lower`.
	var bd: Dictionary = _p.get("binoculars", {})
	_bino.visible = false
	if not bd.is_empty() and ctx.has("actor"):
		var a = ctx["actor"].call(String(bd["actor"]))
		if a != null and a.visible:
			var low := Motion.smooth(clampf((t - float(bd["lower"])) / 0.5, 0.0, 1.0))
			var fwd := Vector3(sin(a.rotation.y), 0, cos(a.rotation.y))
			var right := Vector3(cos(a.rotation.y), 0, -sin(a.rotation.y))
			var head: Vector3 = a.bone_world("head")
			var chest: Vector3 = a.bone_world("spine_03")
			var eyes := head + fwd * 0.42 + Vector3(0, -0.12, 0)
			var hold := chest.lerp(eyes, 1.0 - low) + fwd * (0.25 * low)
			a.aim_hand("r", hold + right * 0.06, 1.0)
			a.aim_hand("l", hold - right * 0.06, 1.0)
			_bino.visible = true
			_bino.position = inv * hold
			_bino.rotation = Vector3(-low * 0.9, a.rotation.y - gt.basis.get_euler().y, 0)
	return {"loads": gt * (HOLD2 + Vector3(0, 11, 0)), "bales": gt * (BALES + Vector3(0, 1.0, 1.5)), "sling": gt * sp,
		"gold": gt * _gold.position, "crate": gt * (_gold.position + Vector3(0, 0.8, 0)), "halyard_top": gt * (FOREMAST + Vector3(0, -2.0, 0))}


func _rod(mi: MeshInstance3D, a: Vector3, b: Vector3, r: float) -> void:
	var d := b - a
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = maxf(d.length(), 0.01)
	c.radial_segments = 5
	mi.mesh = c
	var y := d.normalized() if d.length() > 0.0001 else Vector3.UP
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT).normalized()
	mi.transform = Transform3D(Basis(x, y, x.cross(y)), (a + b) * 0.5)
