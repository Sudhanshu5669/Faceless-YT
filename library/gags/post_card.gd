## library:post_card — a social-media post recreated as a card in the scene (a tweet, a status), for faithful
## recreations of real posts (AGENTS.md rule 4: real text only). It pops in on its time with an overshoot,
## settles and bobs very slightly; it always turns to face `face` (put the camera's position there).
##
##   {"id": "tweet1", "script": "library:post_card", "t": <time>, "at": <point>, "face": <point>,
##    "params": {"name": "Curiosity Rover", "handle": "@MarsCuriosity", "text": "Namaste, @MarsOrbiter! ...",
##               "date": "24 Sep 2014", "avatar": "library/logos/nasa-meatball.svg", "verified": true,
##               "width": 1.0, "dark": false, "accent": "#1d9bf0"}}
##
## width: card width in metres (height follows the text).
## Anchors: "<id>.top" (the card's top edge), "<id>.bottom".
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const PARAMS := ["name", "handle", "text", "date", "avatar", "verified", "width", "dark", "accent"]

var _card: Node3D
var _h := 0.5


func validate(g: Dictionary) -> Array:
	var e := []
	var p: Dictionary = g.get("params", {})
	for k in p:
		if not (k in PARAMS):
			e.append("post_card: unknown param '%s'" % k)
	for k in ["name", "handle", "text"]:
		if not p.has(k):
			e.append("post_card: needs '%s'" % k)
	return e


## Greedy word wrap to about `cols` characters per line.
func _wrap(s: String, cols: int) -> Array:
	var lines := []
	var cur := ""
	for w in s.split(" "):
		if cur.length() + w.length() + 1 > cols and cur != "":
			lines.append(cur)
			cur = w
		else:
			cur = w if cur == "" else cur + " " + w
	if cur != "":
		lines.append(cur)
	return lines


func build(g: Dictionary) -> Node3D:
	var p: Dictionary = g.get("params", {})
	var w := float(p.get("width", 1.0))
	var dark := bool(p.get("dark", false))
	var bg := Color("15202b") if dark else Color("ffffff")
	var ink := Color("e7e9ea") if dark else Color("0f1419")
	var grey := Color("8b98a5") if dark else Color("536471")
	var accent := Color(String(p.get("accent", "#1d9bf0")))
	var root := Node3D.new()
	_card = Node3D.new()
	root.add_child(_card)
	var lines := _wrap(String(p["text"]), 34)
	var line_h := w * 0.062
	_h = w * 0.3 + line_h * float(lines.size()) + w * 0.12
	var top := _h * 0.5
	var plate := Kit.slab(_card, Vector3(w, 0.012, _h), w * 0.04, Vector3.ZERO, Kit.flat(bg.darkened(0.06)), Vector3(PI / 2, 0, 0))
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Avatar: a round image.
	var av := String(p.get("avatar", ""))
	var am := StandardMaterial3D.new()
	am.albedo_color = Color.WHITE
	if av != "":
		am.albedo_texture = Kit.texture(av, false, 2.0)
		am.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		am.alpha_scissor_threshold = 0.5
	am.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var r := w * 0.065
	var disc := Kit.cyl(_card, r, r, 0.004, Vector3(-w * 0.5 + w * 0.1, top - w * 0.1, 0.008), Kit.mat("#e6ecf0", 0.6), 32, Vector3(PI / 2, 0, 0))
	Kit.quad(_card, Vector2(r * 1.7, r * 1.7), Vector3(-w * 0.5 + w * 0.1, top - w * 0.1, 0.011), am)
	var x0 := -w * 0.5 + w * 0.19
	var name_l := Kit.text(_card, String(p["name"]), w * 0.042, ink, Vector3(0, top - w * 0.075, 0.012), Vector3.ZERO, true, 0.0, Color(0, 0, 0, 0), "body")
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_l.position.x = x0
	name_l.font_size = 72
	if bool(p.get("verified", false)):
		Kit.cyl(_card, w * 0.016, w * 0.016, 0.003, Vector3(x0 + w * 0.042 * 0.55 * String(p["name"]).length() + w * 0.025, top - w * 0.075, 0.012), Kit.mat(accent, 0.5), 16, Vector3(PI / 2, 0, 0))
	var hl := Kit.text(_card, String(p["handle"]), w * 0.036, grey, Vector3(x0, top - w * 0.125, 0.012), Vector3.ZERO, false, 0.0, Color(0, 0, 0, 0), "body")
	hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var y := top - w * 0.21
	for ln in lines:
		var lbl := Kit.text(_card, String(ln), w * 0.045, ink, Vector3(-w * 0.5 + w * 0.06, y, 0.012), Vector3.ZERO, false, 0.0, Color(0, 0, 0, 0), "body")
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		y -= line_h
	if p.has("date"):
		var dl := Kit.text(_card, String(p["date"]), w * 0.034, grey, Vector3(-w * 0.5 + w * 0.06, -_h * 0.5 + w * 0.06, 0.012), Vector3.ZERO, false, 0.0, Color(0, 0, 0, 0), "body")
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var age: float = ctx["age"]
	var s := Motion.out_back(clampf(age / 0.35, 0.0, 1.0), 1.6)
	_card.scale = Vector3.ONE * maxf(s, 0.001)
	_card.position = Vector3(0, 0.01 * sin(t * 2.0), 0)
	var gt := node.global_transform
	return {"top": gt * Vector3(0, _h * 0.5, 0), "bottom": gt * Vector3(0, -_h * 0.5, 0)}
