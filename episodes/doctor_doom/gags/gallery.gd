## A dark museum gallery: polished black stone, two plinths under narrow museum spots. On the left a toon red-and-gold
## armored helmet (a memorial: a black ribbon, a row of candles), on the right Doom's iron mask (the doom_suit
## faceplate). Behind them a pale wall that catches the helmet's shadow; on `morph` the light flickers and goes green
## and the shadow on the wall becomes Doom's mask.
##
## Local frame: the helmet plinth at x -1.1, the mask plinth at x +1.1, both at z 0, tops at y 1.15; the wall at z -2.6;
## cameras at +z looking -z.
##
## params:
##   spin     turns per second of the two turntables (default 0.03)
##   morph    t   the shadow on the wall becomes Doom's mask (the shadow light goes green)
##   mask_on  t   the mask plinth's spot fades up (before it the right plinth is dark)
##   both     [t, t, t]   on each beat both spots flash and both pieces turn a quarter on their turntables
##   split    t   the helmet's light goes warm gold, the mask's cold green
##   shield_on t   a round star shield (a toon caricature) leaning on the helmet's plinth catches its own spot
##   eye      {"t": t, "dx": 0.3}   the eye behind the mask's left slit slides across (the drawn eye moves)
## anchors: helmet, mask, wall_shadow
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Toon = preload("res://scripts/actors/toon.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Paths = preload("res://scripts/core/paths.gd")

const TOP := 1.15
const HX := -1.1
const MX := 1.1
const WALL_Z := -2.6
const R := 0.22

static var _suit: GDScript


## The doom_suit library gag (its static mesh builders), loaded from source like every gag.
static func suit() -> GDScript:
	if _suit == null:
		_suit = GDScript.new()
		_suit.source_code = FileAccess.get_file_as_string(Paths.repo_path("library/gags/doom_suit.gd"))
		_suit.reload()
	return _suit



## The downloaded helmet (Sketchfab "Iron-Man Helmet (MK3)" by designpill, CC BY 4.0), if present: the first
## .gltf/.glb under incoming/ironman_helmet/, scaled so its height is `height` and centred on the node's origin.
static func helmet_model(height: float) -> Node3D:
	var dir := Paths.repo_path("incoming/ironman_helmet")
	var found := ""
	var stack := [dir]
	while not stack.is_empty() and found == "":
		var d: String = stack.pop_back()
		var da := DirAccess.open(d)
		if da == null:
			continue
		for f in da.get_files():
			if f.get_extension().to_lower() in ["gltf", "glb"]:
				found = d.path_join(f)
				break
		for sub in da.get_directories():
			stack.append(d.path_join(sub))
	if found == "":
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(found, state) != OK:
		return null
	var model := doc.generate_scene(state) as Node3D
	var holder := Node3D.new()
	holder.add_child(model)
	var bb := Kit.bounds(model)
	var s := height / maxf(bb.size.y, 0.001)
	model.scale = Vector3.ONE * s
	model.position = -(bb.position + bb.size * 0.5) * s
	return holder

var _p := {}
var _helmet: Node3D
var _mask: Node3D
var _helmet_shadow: Node3D
var _mask_shadow: Node3D
var _spot_h: SpotLight3D
var _spot_m: SpotLight3D
var _shadow_light: SpotLight3D
var _eye: Node3D
var _eye_rest := Vector3.ZERO
var _candles: Array[OmniLight3D] = []
var _shield_spot: SpotLight3D
var _has_model := false


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "gallery"))
	var stone := Kit.mat("#0b0b0d", 0.12, 0.0, 0.8)
	var plinth_m := Kit.mat("#16161a", 0.35)
	Kit.box(root, Vector3(14, 0.1, 12), Vector3(0, -0.05, 1), stone)
	Kit.box(root, Vector3(14, 6, 0.2), Vector3(0, 3, WALL_Z - 0.1), Kit.mat("#b9b4aa", 0.9))
	for s: float in [-1.0, 1.0]:
		Kit.box(root, Vector3(0.2, 6, 12), Vector3(s * 5.5, 3, 1), Kit.mat("#121214", 0.9))
	Kit.box(root, Vector3(14, 0.2, 12), Vector3(0, 5.2, 1), Kit.mat("#08080a", 0.9))
	for x: float in [HX, MX]:
		Kit.slab(root, Vector3(0.62, TOP - 0.03, 0.62), 0.04, Vector3(x, (TOP - 0.03) * 0.5, 0), plinth_m)
		Kit.slab(root, Vector3(0.7, 0.04, 0.7), 0.04, Vector3(x, TOP - 0.02, 0), Kit.mat("#2a2a30", 0.25, 0.6))
		Kit.cyl(root, 0.2, 0.2, 0.03, Vector3(x, TOP + 0.015, 0), Kit.mat("#3a3a40", 0.3, 0.8), 32)
	# The helmet: a red shell, a gold faceplate (the doom_suit faceplate shape, recoloured) with glowing eyes.
	_helmet = Node3D.new()
	_helmet.position = Vector3(HX, TOP + 0.03 + R * 1.1, 0)
	root.add_child(_helmet)
	var dl := helmet_model(R * 2.35)
	_has_model = dl != null
	if dl != null:
		_helmet.add_child(dl)
		dl.position = Vector3(0, -0.06, 0)   # seated on the turntable, not floating
	else:
		var red := Kit.mat("#a3121b", 0.28, 0.8)
		var gold := Kit.mat("#d9a441", 0.25, 0.9)
		Kit.ball(_helmet, R, Vector3(0, 0.02, -0.05), red, 32, Vector3(1.0, 1.1, 0.98))
		var plate := MeshInstance3D.new()
		plate.mesh = suit().call("_mask", 1.0)
		plate.material_override = gold
		plate.scale = Vector3(1.0, 1.0, 1.0) * R * 1.06
		plate.position = Vector3(0, -0.01, 0.03)
		_helmet.add_child(plate)
		for s: float in [-1.0, 1.0]:
			var eye := Kit.box(_helmet, Vector3(R * 0.46, R * 0.12, 0.01), Vector3(s * R * 0.4, R * 0.075, R * 0.94), Kit.lit("#dff4ff", 5.0),
				Vector3(0, s * 0.35, s * -0.18))
			eye.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		Kit.box(_helmet, Vector3(R * 1.6, R * 0.06, R * 0.5), Vector3(0, R * 0.62, R * 0.55), red, Vector3(-0.4, 0, 0))
	# A memorial ribbon and candles on the helmet's plinth.
	Kit.box(root, Vector3(0.05, 0.5, 0.012), Vector3(HX + 0.22, TOP - 0.3, 0.315), Kit.mat("#050505", 0.6), Vector3(0, 0, 0.6))
	Kit.box(root, Vector3(0.05, 0.5, 0.012), Vector3(HX + 0.27, TOP - 0.3, 0.315), Kit.mat("#050505", 0.6), Vector3(0, 0, -0.6))
	for k in 5:
		var cx := HX - 0.5 + k * 0.25
		Kit.cyl(root, 0.03, 0.03, 0.12 + 0.05 * (k % 3), Vector3(cx, 0.06 + 0.025 * (k % 3), 0.75), Kit.mat("#efe6d2", 0.7), 12)
		Kit.ball(root, 0.012, Vector3(cx, 0.15 + 0.05 * (k % 3), 0.75), Kit.lit("#ffcc77", 6.0), 8, Vector3(1, 1.8, 1))
		_candles.append(Kit.omni(root, Vector3(cx, 0.22 + 0.05 * (k % 3), 0.75), "#ff9a3c", 0.25, 1.4, false, 0.2))
	# A round shield leaning on the helmet's plinth (concentric red and white, a blue centre, a white star).
	var sh := Node3D.new()
	sh.position = Vector3(HX - 0.45, 0.36, 0.25)
	sh.rotation = Vector3(-0.2, 0.5, 0)
	root.add_child(sh)
	for k in 4:
		var r := 0.34 - k * 0.075
		Kit.cyl(sh, r, r, 0.03 + 0.005 * k, Vector3(0, 0, 0.005 * k), Kit.mat(["#b3141c", "#e8e4dc", "#b3141c", "#1e3a8a"][k], 0.35, 0.6), 40,
			Vector3(PI / 2, 0, 0))
	var star := Kit.text(sh, "★", 0.16, Color("#f2efe8"), Vector3(0, -0.01, 0.04), Vector3.ZERO, true)
	star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shield_spot = Kit.spot(root, Vector3(HX - 0.9, 2.6, 1.6), Vector3(HX - 0.45, 0.36, 0.25), "#e8eeff", 0.0, 4.0, 14.0, true, 0.5)
	# Doom's mask on the right plinth (the faceplate, rivets, the brow band), with a drawn eye behind the left slit.
	_mask = Node3D.new()
	_mask.position = Vector3(MX, TOP + 0.03 + R * 1.05, 0)
	root.add_child(_mask)
	var metal := Kit.mat("#8a9096", 0.45, 0.75)
	var shell := MeshInstance3D.new()
	shell.mesh = suit().call("_mask", 1.0)
	shell.material_override = metal
	shell.scale = Vector3.ONE * R * 1.04
	_mask.add_child(shell)
	Kit.box(_mask, Vector3(R * 1.2, R * 0.07, R * 0.1), Vector3(0, R * 0.3, R * 0.93), Kit.mat("#4a4f54", 0.5, 0.7), Vector3(-0.3, 0, 0))
	Kit.box(_mask, Vector3(R * 0.09, R * 0.42, R * 0.12), Vector3(0, -R * 0.12, R * 0.97), metal, Vector3(0.12, 0, 0))
	Kit.ball(_mask, R * 0.95, Vector3(0, 0, -0.01), Kit.mat("#050505", 0.9), 24)
	_eye = Node3D.new()
	_eye_rest = Vector3(R * 0.4, R * 0.075, R * 0.86)
	_eye.position = _eye_rest
	_mask.add_child(_eye)
	Kit.ball(_eye, R * 0.13, Vector3.ZERO, Kit.mat("#e8e4da", 0.5), 16, Vector3(1.4, 0.55, 0.4))
	Kit.ball(_eye, R * 0.06, Vector3(0, 0, R * 0.04), Kit.lit("#2bff6a", 1.5), 12)
	for s: float in [-1.0, 1.0]:
		for k in 4:
			var a := s * (0.62 + 0.12 * k)
			var y := -0.15 - 0.17 * k
			Kit.ball(_mask, R * 0.03, Vector3(sin(a) * cos(y), sin(y) * 1.1, cos(a) * cos(y)) * R * 1.06, Kit.mat("#4a4f54", 0.5, 0.7), 8)
	# Shadow casters: the helmet's own shapes cast until `morph`; then an invisible Doom-mask silhouette does.
	_helmet_shadow = Node3D.new()
	_helmet.add_child(_helmet_shadow)
	_mask_shadow = Node3D.new()
	_mask_shadow.position = _helmet.position
	root.add_child(_mask_shadow)
	var ms := MeshInstance3D.new()
	ms.mesh = suit().call("_mask", 1.0)
	ms.scale = Vector3.ONE * R * 1.06
	ms.material_override = metal
	ms.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	_mask_shadow.add_child(ms)
	var hood := MeshInstance3D.new()
	hood.mesh = suit().call("_hood", 1.0)
	hood.scale = Vector3.ONE * R * 1.25
	hood.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	hood.material_override = metal
	_mask_shadow.add_child(hood)
	# Lights: two narrow museum spots, the low shadow-throwing light in front of the helmet, a faint wall wash.
	_spot_h = Kit.spot(root, Vector3(HX, 4.9, 0.9), Vector3(HX, TOP + 0.2, 0), "#fff1dc", 26.0, 7.0, 13.0, true, 0.8)
	_spot_m = Kit.spot(root, Vector3(MX, 4.9, 0.9), Vector3(MX, TOP + 0.2, 0), "#fff1dc", 0.0, 7.0, 13.0, true, 0.8)
	_shadow_light = Kit.spot(root, Vector3(HX + 0.05, TOP + 0.15, 2.4), Vector3(HX, TOP + 0.3, 0), "#ffe7c4", 18.0, 9.0, 16.0, true, 0.3)
	_shadow_light.shadow_blur = 0.6
	Kit.spot(root, Vector3(0, 5.0, 3.5), Vector3(0, 1.5, WALL_Z), "#7f8aa8", 2.5, 12.0, 45.0, false, 0.2)
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	# Face the lens, swaying gently; a full spin on each "both" beat.
	var turn := 0.22 * sin(t * 0.35)
	for b in _p.get("both", []):
		turn += Motion.out_back(Motion.seg(t, float(b), float(b) + 0.6), 1.2) * TAU
	_helmet.rotation = Vector3(0, turn, 0)
	_mask.rotation = Vector3(0, -turn, 0)
	# The shadow swap with a flicker.
	var morph := float(_p.get("morph", 1e9))
	var after := t >= morph
	var flick := 1.0
	if absf(t - morph) < 0.35:
		flick = 0.35 + 0.65 * absf(sin((t - morph) * 60.0))
	_shadow_light.light_color = Color("#ffe7c4").lerp(Color("#3dff6e"), Motion.smooth(Motion.seg(t, morph - 0.1, morph + 0.5)))
	_shadow_light.light_energy = (3.5 if _has_model else 18.0) * flick
	for mi in _helmet.find_children("*", "MeshInstance3D", true, false):
		(mi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if after else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_mask_shadow.visible = after
	_mask_shadow.rotation = Vector3(0, turn, 0)
	# Spots.
	var mask_on := Motion.smooth(Motion.seg(t, float(_p.get("mask_on", 1e9)), float(_p.get("mask_on", 1e9)) + 0.8))
	var pulse := 0.0
	for b in _p.get("both", []):
		var k := t - float(b)
		if k >= 0.0:
			pulse = maxf(pulse, exp(-k * 5.0))
	var split := Motion.smooth(Motion.seg(t, float(_p.get("split", 1e9)), float(_p.get("split", 1e9)) + 0.8))
	_spot_h.light_energy = (7.0 if _has_model else 26.0) * (1.0 + 1.5 * pulse)
	_spot_h.light_color = Color("#fff1dc").lerp(Color("#ffb347"), split)
	_spot_m.light_energy = 15.0 * mask_on * (1.0 + 1.5 * pulse)
	_spot_m.light_color = Color("#fff1dc").lerp(Color("#39ff6e"), split)
	_shield_spot.light_energy = 14.0 * Motion.smooth(Motion.seg(t, float(_p.get("shield_on", 1e9)), float(_p.get("shield_on", 1e9)) + 0.5))
	for i in _candles.size():
		_candles[i].light_energy = 0.25 * (0.85 + 0.15 * sin(t * (9.0 + i) + i))
	# The eye.
	var ed: Dictionary = _p.get("eye", {})
	var et := float(ed.get("t", 1e9))
	var dx := float(ed.get("dx", 0.3))
	_eye.position = _eye_rest + Vector3(-R * dx * Motion.in_out(Motion.seg(t, et, et + 0.6)), 0, 0)
	return {"helmet": node.global_transform * _helmet.position, "mask": node.global_transform * _mask.position,
		"wall_shadow": node.global_transform * Vector3(HX, TOP + 0.5, WALL_Z)}
