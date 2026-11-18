extends RefCounted
## New York, September-October 2014 (lines 19-20): (a) the "Elite Space Club" of the newspaper's cartoon,
## restaged as a real gentlemen's club; (b) the newspaper's street entrance at night, buried under letters.
##
## (a) Club, local frame: a 7 x 6 m room, the door on the back wall (z -3) with a frosted glass pane, a brass
##     plate "ELITE SPACE CLUB" on it (the wording in the cartoon). Dark wood panels, a fireplace on the left
##     wall, bookshelves, green banker's lamps, a Persian rug, two leather armchairs by the fire. Outside the
##     door: the farmer and his cow (a built cow; seen through the glass).
## (b) The entrance at x +60: a glass and steel lobby front, the paper's wordmark above, a sidewalk; letters and
##     printed complaints fall and pile up against the doors.
##
## params: knock [t0, t1] (the door shakes on each knock), letters [t0, t1] (the pile grows)
## anchors: door, fire, chairs, paper, entrance, pile

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const ENT := Vector3(60, 0, 0)

const WOOD := """
shader_type spatial;
uniform vec3 base : source_color = vec3(0.24, 0.12, 0.06);
varying vec3 wp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float grain = fbm(vec3(wp.x * 0.6, wp.y * 14.0, wp.z * 0.6));
	vec3 col = base * (0.75 + 0.5 * grain);
	float panel = step(0.97, fract(wp.y / 0.9)) + step(0.985, fract((wp.x + wp.z) / 1.2));
	col *= 1.0 - 0.45 * clamp(panel, 0.0, 1.0);
	ALBEDO = col;
	ROUGHNESS = 0.38;
	SPECULAR = 0.55;
}
"""

const RUG := """
shader_type spatial;
varying vec2 uv2;
//NOISE
void vertex() { uv2 = UV; }
void fragment() {
	vec2 p = abs(uv2 - 0.5) * 2.0;
	float border = step(0.82, max(p.x, p.y));
	float medal = 1.0 - smoothstep(0.3, 0.32, length((uv2 - 0.5) * vec2(1.0, 1.4)));
	float pat = sin(uv2.x * 60.0) * sin(uv2.y * 60.0);
	vec3 col = mix(vec3(0.45, 0.07, 0.07), vec3(0.08, 0.1, 0.25), border);
	col = mix(col, vec3(0.75, 0.6, 0.3), medal * 0.7);
	col *= 0.85 + 0.15 * pat + 0.1 * fbm(vec3(uv2 * 40.0, 1.0));
	ALBEDO = col;
	ROUGHNESS = 0.95;
}
"""

const FIRE := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform float t = 0.0;
varying vec2 uv2;
//NOISE
void vertex() { uv2 = UV; }
void fragment() {
	vec2 p = uv2 - vec2(0.5, 1.0);
	float n = fbm(vec3(uv2.x * 6.0, uv2.y * 3.0 + t * 3.0, t));
	float flame = smoothstep(0.55, 0.0, length(vec2(p.x * 2.2, (p.y + 0.15) * 0.9)) - n * 0.35);
	ALBEDO = mix(vec3(1.0, 0.35, 0.05), vec3(1.0, 0.85, 0.4), flame) * flame * 3.0;
}
"""

var _p := {}
var _door: Node3D
var _fire_mat: ShaderMaterial
var _fire_light: OmniLight3D
var _letters: MultiMesh
var _letter_data: Array = []
var _apology_door: Node3D
var _paper: Node3D


func validate(g: Dictionary) -> Array:
	var e := []
	for k in g.get("params", {}):
		if not (k in ["knock", "letters", "reader", "knocker"]):
			e.append("nyc: unknown param '%s'" % k)
	return e


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	_club(root)
	_newspaper(root)
	_farmer_side(root)
	_entrance(root)
	return root


func _club(root: Node3D) -> void:
	var wood := Kit.shader(WOOD)
	Kit.box(root, Vector3(7, 0.1, 6), Vector3(0, -0.05, 0), Kit.mat("#3b2416", 0.45, 0.0, 0.6))
	var rug := Kit.quad(root, Vector2(4.2, 3.0), Vector3(0.4, 0.005, 0.3), Kit.shader(RUG), Vector3(-PI / 2, 0, 0))
	Kit.box(root, Vector3(7, 3.6, 0.2), Vector3(0, 1.8, -3.0), wood)
	Kit.box(root, Vector3(0.2, 3.6, 6), Vector3(-3.5, 1.8, 0), wood)
	Kit.box(root, Vector3(0.2, 3.6, 6), Vector3(3.5, 1.8, 0), wood)
	Kit.box(root, Vector3(7, 0.2, 6), Vector3(0, 3.6, 0), Kit.mat("#2a1810", 0.6))
	Kit.box(root, Vector3(7, 0.2, 0.2), Vector3(0, 3.45, -2.88), Kit.mat("#6a4a22", 0.4, 0.0, 0.7))
	# The door: dark wood with a frosted glass pane and the brass plate, in a moulded frame.
	_door = Node3D.new()
	_door.position = Vector3(1.4, 0, -2.88)
	root.add_child(_door)
	Kit.box(_door, Vector3(1.1, 2.3, 0.07), Vector3(0, 1.15, 0), Kit.mat("#2b160b", 0.4, 0.0, 0.6))
	var frosted := StandardMaterial3D.new()
	frosted.albedo_color = Color(0.85, 0.8, 0.68, 0.3)
	frosted.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	frosted.roughness = 0.6
	frosted.emission_enabled = true
	frosted.emission = Color(0.55, 0.45, 0.3)
	frosted.emission_energy_multiplier = 0.25
	Kit.box(_door, Vector3(0.7, 0.9, 0.02), Vector3(0, 1.65, 0.03), frosted)
	Kit.box(_door, Vector3(0.62, 0.14, 0.01), Vector3(0, 1.05, 0.045), Kit.mat("#c9a14a", 0.25, 0.0, 0.9))
	Kit.text(_door, "ELITE SPACE CLUB", 0.055, Color("2a1a08"), Vector3(0, 1.05, 0.052), Vector3.ZERO, true, 0.0, Color(0, 0, 0, 0), "body")
	Kit.ball(_door, 0.04, Vector3(0.42, 1.05, 0.06), Kit.mat("#c9a14a", 0.25, 0.0, 0.9), 12)
	Kit.box(root, Vector3(1.4, 2.6, 0.1), Vector3(1.4, 1.3, -2.92), Kit.mat("#1d0f07", 0.5))
	# Fireplace on the left wall: marble surround, the fire, a mirror above.
	var fp := Node3D.new()
	fp.position = Vector3(-3.38, 0, 0.2)
	fp.rotation = Vector3(0, PI / 2, 0)
	root.add_child(fp)
	Kit.box(fp, Vector3(1.8, 1.3, 0.3), Vector3(0, 0.65, 0), Kit.mat("#d8d2c4", 0.3, 0.0, 0.7))
	Kit.box(fp, Vector3(1.0, 0.8, 0.32), Vector3(0, 0.45, 0.02), Kit.mat("#0b0806", 0.9))
	Kit.box(fp, Vector3(2.0, 0.08, 0.4), Vector3(0, 1.33, 0.05), Kit.mat("#d8d2c4", 0.3, 0.0, 0.7))
	_fire_mat = Kit.shader(FIRE)
	Kit.quad(fp, Vector2(0.8, 0.6), Vector3(0, 0.38, 0.12), _fire_mat)
	for k in 3:
		Kit.rod(fp, Vector3(-0.3 + 0.3 * k, 0.12, 0.1), Vector3(-0.2 + 0.3 * k, 0.14, 0.2), 0.04, Kit.mat("#3a2210", 0.8), 6)
	_fire_light = Kit.omni(fp, Vector3(0, 0.5, 0.6), "#ff8a3a", 2.2, 6.0, true, 0.4)
	Kit.box(fp, Vector3(1.3, 0.9, 0.04), Vector3(0, 2.1, 0.0), Kit.mat("#b9b3a6", 0.05, 0.0, 1.0))
	# Bookshelves on the right wall.
	var r := Kit.rng("books")
	for sh in 5:
		Kit.box(root, Vector3(0.3, 0.03, 2.6), Vector3(3.3, 0.4 + 0.55 * sh, -0.6), Kit.mat("#2a160a", 0.5))
		var z := -1.85
		while z < 0.65:
			var bw := r.randf_range(0.03, 0.07)
			var bh := r.randf_range(0.3, 0.45)
			Kit.box(root, Vector3(0.24, bh, bw), Vector3(3.3, 0.42 + 0.55 * sh + bh * 0.5, z), Kit.mat(Color(r.randf_range(0.2, 0.5), r.randf_range(0.05, 0.2), r.randf_range(0.05, 0.15)), 0.7))
			z += bw + 0.005
	# Two leather armchairs (chesterfield) angled to the fire, a side table with a banker's lamp and a decanter.
	for c in [[-1.2, 0.9, 0.9], [0.2, 0.9, -0.5]]:
		var ch := Node3D.new()
		ch.position = Vector3(float(c[0]), 0, float(c[1]))
		ch.rotation = Vector3(0, float(c[2]), 0)
		root.add_child(ch)
		var leather := Kit.mat("#4a1a12", 0.35, 0.0, 0.7)
		Kit.slab(ch, Vector3(0.95, 0.42, 0.85), 0.12, Vector3(0, 0.25, 0), leather)
		Kit.slab(ch, Vector3(0.95, 0.65, 0.2), 0.08, Vector3(0, 0.75, -0.35), leather)
		for s in [-1.0, 1.0]:
			Kit.slab(ch, Vector3(0.2, 0.32, 0.85), 0.09, Vector3(s * 0.42, 0.55, 0), leather)
	Kit.cyl(root, 0.28, 0.28, 0.04, Vector3(-0.5, 0.62, 0.0), Kit.mat("#2b160b", 0.35, 0.0, 0.6), 24)
	Kit.cyl(root, 0.03, 0.03, 0.6, Vector3(-0.5, 0.31, 0.0), Kit.mat("#2b160b", 0.35), 8)
	Kit.cyl(root, 0.06, 0.08, 0.04, Vector3(-0.58, 0.66, 0.05), Kit.mat("#b48a3a", 0.25, 0.0, 0.9), 16)
	Kit.rod(root, Vector3(-0.58, 0.66, 0.05), Vector3(-0.58, 0.95, 0.05), 0.01, Kit.mat("#b48a3a", 0.25, 0.0, 0.9), 6)
	var shade := Kit.ball(root, 0.13, Vector3(-0.58, 0.98, 0.05), Kit.mat("#1f6b3c", 0.15, 0.0, 0.9), 16, Vector3(1.4, 0.45, 0.8))
	Kit.omni(root, Vector3(-0.58, 0.88, 0.05), "#ffd08a", 0.9, 3.0, true, 0.3)
	var glassm := StandardMaterial3D.new()
	glassm.albedo_color = Color(0.7, 0.45, 0.2, 0.5)
	glassm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glassm.roughness = 0.05
	Kit.cyl(root, 0.06, 0.07, 0.2, Vector3(-0.38, 0.74, -0.08), glassm, 16)
	# Wall sconces and a painting of a sailing ship.
	for x in [-2.2, 2.6]:
		Kit.ball(root, 0.07, Vector3(x, 2.3, -2.85), Kit.lit("#ffd49a", 2.0), 12)
		Kit.omni(root, Vector3(x, 2.3, -2.6), "#ffc77a", 0.6, 3.5, false, 0.3)
	Kit.box(root, Vector3(1.4, 1.0, 0.05), Vector3(-1.2, 2.2, -2.9), Kit.mat("#7a5a2a", 0.4, 0.0, 0.7))
	Kit.quad(root, Vector2(1.25, 0.85), Vector3(-1.2, 2.2, -2.87), Kit.mat("#3b4a52", 0.8))


## The broadsheet the club member reads: the wordmark on top, columns of print, a photo of a rocket.
func _newspaper(root: Node3D) -> void:
	_paper = Node3D.new()
	root.add_child(_paper)
	var sheet := Kit.mat("#ece6d6", 0.9)
	sheet.cull_mode = BaseMaterial3D.CULL_DISABLED
	for s in [-1.0, 1.0]:
		var page := Kit.quad(_paper, Vector2(0.36, 0.5), Vector3(s * 0.18, 0, 0), sheet, Vector3(0, s * -0.25, 0))
	var wm := StandardMaterial3D.new()
	wm.albedo_texture = Kit.texture("library/logos/nyt-wordmark.svg", false, 3.0)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	wm.alpha_scissor_threshold = 0.5
	wm.albedo_color = Color(0.08, 0.08, 0.08)
	wm.cull_mode = BaseMaterial3D.CULL_DISABLED
	Kit.quad(_paper, Vector2(0.3, 0.04), Vector3(-0.18, 0.2, 0.012), wm, Vector3(0, 0.25, 0))
	Kit.quad(_paper, Vector2(0.3, 0.04), Vector3(-0.18, 0.2, -0.012), wm, Vector3(0, PI + 0.25, 0))
	for k in 9:
		for s in [-1.0, 1.0]:
			Kit.quad(_paper, Vector2(0.3, 0.012), Vector3(s * 0.18, 0.12 - k * 0.03, s * 0.0 - 0.012 * s), Kit.mat("#8a8678", 0.9), Vector3(0, s * -0.25 + PI, 0))


## Outside the club's door: a corridor, the farmer (an actor) and his cow (built here).
func _farmer_side(root: Node3D) -> void:
	Kit.box(root, Vector3(4, 0.1, 3), Vector3(1.4, -0.05, -4.6), Kit.mat("#5a5048", 0.7))
	Kit.omni(root, Vector3(1.4, 2.5, -4.5), "#ffe2b0", 1.2, 4.0, false, 0.3)
	var cow := Node3D.new()
	cow.position = Vector3(2.15, 0, -4.3)
	cow.rotation = Vector3(0, -PI / 2.6, 0)
	root.add_child(cow)
	var hide := Kit.mat("#efe9df", 0.8)
	var spot := Kit.mat("#3b2a22", 0.8)
	Kit.ball(cow, 1.0, Vector3(0, 1.0, 0), hide, 24, Vector3(0.42, 0.42, 0.85))
	Kit.ball(cow, 0.22, Vector3(0, 1.25, 0.95), hide, 18, Vector3(1.0, 1.0, 1.25))
	Kit.ball(cow, 0.12, Vector3(0, 1.17, 1.2), Kit.mat("#d9a89a", 0.7), 12, Vector3(1.3, 0.8, 0.8))
	for s in [-1.0, 1.0]:
		Kit.cyl(cow, 0.02, 0.04, 0.22, Vector3(s * 0.15, 1.48, 0.9), Kit.mat("#d8cdb8", 0.6), 8, Vector3(0, 0, -s * 0.6))
		Kit.ball(cow, 0.06, Vector3(s * 0.25, 1.32, 0.88), hide, 8, Vector3(1.5, 0.6, 0.8))
		for z in [-0.55, 0.55]:
			Kit.cyl(cow, 0.06, 0.07, 0.75, Vector3(s * 0.22, 0.38, z), hide, 8)
			Kit.cyl(cow, 0.07, 0.07, 0.06, Vector3(s * 0.22, 0.03, z), Kit.mat("#2a2420", 0.6), 8)
	Kit.ball(cow, 0.25, Vector3(0.2, 1.15, -0.2), spot, 12, Vector3(1.0, 0.9, 1.6))
	Kit.ball(cow, 0.2, Vector3(-0.22, 0.95, 0.35), spot, 12, Vector3(1.0, 1.0, 1.4))
	Kit.rod(cow, Vector3(0, 1.1, -0.82), Vector3(0, 0.55, -0.95), 0.02, hide, 6)


func _entrance(root: Node3D) -> void:
	var e := Node3D.new()
	e.position = ENT
	root.add_child(e)
	Kit.box(e, Vector3(30, 0.15, 12), Vector3(0, -0.07, 2), Kit.mat("#7d7a75", 0.8))
	Kit.box(e, Vector3(30, 0.2, 8), Vector3(0, -0.1, 12), Kit.mat("#2b2b2d", 0.9))
	# The lobby front: tall glass panels between steel fins, the doors in the middle, the wordmark above.
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.25, 0.3, 0.32, 0.6)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	glass.metallic_specular = 1.0
	Kit.box(e, Vector3(30, 9, 0.1), Vector3(0, 4.5, -0.2), glass)
	Kit.box(e, Vector3(30, 12, 0.3), Vector3(0, 15, -0.3), Kit.mat("#8f8d88", 0.6))
	for x in range(-14, 15, 2):
		Kit.box(e, Vector3(0.12, 9, 0.5), Vector3(x, 4.5, 0.0), Kit.mat("#bfc2c4", 0.3, 0.0, 0.8))
	Kit.box(e, Vector3(30, 20, 0.2), Vector3(0, 10, -6), Kit.lit("#ffe7c0", 0.6))
	var wm := StandardMaterial3D.new()
	wm.albedo_texture = Kit.texture("library/logos/nyt-wordmark.svg", false, 6.0)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	wm.alpha_scissor_threshold = 0.5
	wm.albedo_color = Color(0.08, 0.08, 0.08)
	Kit.quad(e, Vector2(8.0, 1.08), Vector3(0, 7.2, 0.15), wm)
	_apology_door = Node3D.new()
	_apology_door.position = Vector3(0, 0, 0.05)
	e.add_child(_apology_door)
	Kit.box(_apology_door, Vector3(1.2, 2.6, 0.06), Vector3(0.6, 1.3, 0), glass)
	Kit.box(_apology_door, Vector3(0.05, 1.0, 0.08), Vector3(1.05, 1.2, 0.06), Kit.mat("#c0c4c6", 0.2, 0.0, 0.9))
	Kit.spot(e, Vector3(0, 7, 6), Vector3(0, 0, 0.5), "#ffe2b8", 3.0, 14.0, 55.0, true, 0.5)
	Kit.omni(e, Vector3(0, 2.5, 3), "#9fb6d8", 0.6, 10.0, false, 0.3)
	# Letters: envelopes and printed sheets.
	var qm := QuadMesh.new()
	qm.size = Vector2(0.24, 0.12)
	_letters = MultiMesh.new()
	_letters.transform_format = MultiMesh.TRANSFORM_3D
	_letters.use_colors = true
	_letters.mesh = qm
	_letters.instance_count = 700
	var r := Kit.rng("letters")
	for i in 700:
		var land := Vector3(r.randf_range(-3.4, 3.4), 0, r.randf_range(0.15, 2.2))
		_letter_data.append([land, r.randf(), r.randf_range(-PI, PI), Vector3(r.randf_range(-1, 1), r.randf_range(-1, 1), r.randf_range(-1, 1))])
		var tint := Color("f3efe4") if r.randf() < 0.6 else Color("e8dcc0")
		_letters.set_instance_color(i, tint)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _letters
	var lm := StandardMaterial3D.new()
	lm.vertex_color_use_as_albedo = true
	lm.cull_mode = BaseMaterial3D.CULL_DISABLED
	lm.roughness = 0.85
	mmi.material_override = lm
	e.add_child(mmi)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	_fire_mat.set_shader_parameter("t", t)
	_fire_light.light_energy = 2.0 + 0.4 * sin(t * 11.0) + 0.25 * sin(t * 23.0)
	# Knocks: three raps, the door jumps on each.
	var kn = _p.get("knock", [])
	var shake := 0.0
	if kn is Array and kn.size() >= 2:
		var k0 := float(kn[0])
		for i in 3:
			var kt := k0 + 0.22 * i
			if t > kt:
				shake += Motion.impact(t - kt, 1.0, 9.0, 18.0)
	_door.position = Vector3(1.4, 0, -2.88 + 0.012 * shake)
	_door.rotation = Vector3(0.004 * shake, 0, 0)
	# The reader holds the paper up in both hands; the knocker raps the glass.
	var act = ctx.get("actor", null)
	var rd = act.call(String(_p.get("reader", ""))) if act else null
	if rd:
		var chest: Vector3 = ctx["point"].call(String(_p.get("reader", "")) + ".chest").get("pos", Vector3.ZERO)
		var fwd := Vector3(sin(rd.rotation.y), 0, cos(rd.rotation.y))
		var lower := clampf((t - float(kn[0]) - 0.15) / 0.35, 0.0, 1.0) if kn is Array and kn.size() >= 2 else 0.0
		var at := chest + fwd * 0.32 + Vector3(0, 0.18 - 0.32 * Motion.out_cubic(lower), 0)
		_paper.position = node.global_transform.affine_inverse() * at
		_paper.basis = Basis.looking_at(-(node.global_transform.basis.inverse() * fwd), Vector3.UP)
		var side := fwd.cross(Vector3.UP).normalized()
		rd.aim_hand("l", at - side * 0.3, 1.0)
		rd.aim_hand("r", at + side * 0.3, 1.0)
	var kr = act.call(String(_p.get("knocker", ""))) if act else null
	if kr and kn is Array and kn.size() >= 2:
		var k0 := float(kn[0])
		var w := clampf((t - k0 + 0.4) / 0.3, 0.0, 1.0) * (1.0 - clampf((t - k0 - 1.0) / 0.3, 0.0, 1.0))
		var rap := 0.0
		for i in 3:
			rap = maxf(rap, 1.0 - absf(t - (k0 + 0.22 * i)) / 0.1)
		var glass := gt * Vector3(1.4, 1.65, -2.92 - 0.06 + 0.05 * (1.0 - rap))
		kr.aim_hand("r", glass, w)
	# Letters: they rain down and heap up against the doors (the heap grows from the glass outward).
	var lw = _p.get("letters", [])
	var l0 := float(lw[0]) if lw is Array and lw.size() >= 1 else 1e9
	var l1 := float(lw[1]) if lw is Array and lw.size() >= 2 else l0 + 3.0
	for i in _letter_data.size():
		var d: Array = _letter_data[i]
		var ti := l0 + (l1 - l0) * float(d[1])
		var age := t - ti
		var land: Vector3 = d[0]
		var stack := float(i) / 700.0
		var rest_y := 0.02 + stack * 1.6 * exp(-land.z * 0.8) * (1.0 - absf(land.x) / 4.0)
		var xf := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.0001), Vector3(0, -50, 0))
		if age > 0.0:
			var fall := clampf(age / 0.7, 0.0, 1.0)
			var pos := land + Vector3(sin(age * 4.0 + i) * 0.2 * (1.0 - fall), lerpf(9.0, rest_y, Motion.in_cubic(fall)), 0)
			var spin: Vector3 = (d[3] as Vector3) * (1.0 - fall) * age * 4.0
			var basis := Basis.from_euler(Vector3(-PI / 2 + spin.x, float(d[2]), spin.z))
			if fall >= 1.0:
				basis = Basis.from_euler(Vector3(-PI / 2 + 0.3 * sin(float(i)), float(d[2]), 0.2 * cos(float(i) * 1.7)))
			xf = Transform3D(basis, pos)
		_letters.set_instance_transform(i, xf)
	return {"door": gt * Vector3(1.4, 1.5, -2.85), "fire": gt * Vector3(-3.2, 0.6, 0.2), "chairs": gt * Vector3(-0.5, 0.9, 0.2),
		"entrance": gt * (ENT + Vector3(0, 2.0, 0)), "pile": gt * (ENT + Vector3(0, 0.6, 1.0))}
