extends RefCounted
## SCI Nalanda in bad weather in the South Pacific, October 2013 (line 9): the tracking ship that held up the
## launch by a week. Night, rain, a heavy swell.
##
## The ship stays level in the gag's frame (so the deckhand, an actor, stays on its deck); the sea and the
## horizon heave around it instead, and the camera rolls with it. Local frame: the ship along z (bow at -z),
## deck at y 6, 120 m long, 20 m beam. A white bridge aft, the funnel, hatch covers, two cranes, and the
## portable tracking dish on a steel frame forward of the bridge. Spray bursts over the bow on each wave.
##
## params: waves [t0, t1] (the spray timing runs from t0), lightning [t, ...]
## anchors: dish, bow, bridge, deck

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const DECK := 6.0

## A storm sea: summed Gerstner-like waves in the vertex shader, dark water, foam on the crests.
const SEA := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform float t = 0.0;
uniform float heave = 1.0;
varying vec3 wp;
varying float crest;
//NOISE
vec3 wave(vec2 p, vec2 dir, float len, float amp, float speed) {
	float k = 6.2831853 / len;
	float ph = k * dot(dir, p) - speed * t;
	return vec3(dir.x * amp * cos(ph), amp * sin(ph), dir.y * amp * cos(ph));
}
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 p = w.xz;
	vec3 d = vec3(0.0);
	d += wave(p, normalize(vec2(0.2, 1.0)), 60.0, 2.6 * heave, 1.1);
	d += wave(p, normalize(vec2(-0.5, 0.8)), 31.0, 1.2 * heave, 1.6);
	d += wave(p, normalize(vec2(0.9, 0.4)), 17.0, 0.55 * heave, 2.2);
	d += wave(p, normalize(vec2(-0.2, -1.0)), 9.0, 0.25 * heave, 3.0);
	VERTEX += d;
	crest = d.y;
	wp = w + d;
}
void fragment() {
	float foam = smoothstep(2.4, 3.6, crest) * (0.6 + 0.4 * fbm(wp * 0.4 + vec3(t * 0.3)));
	foam += smoothstep(0.72, 0.8, fbm(wp * 0.15 + vec3(0.0, 0.0, t * 0.1))) * 0.35;
	vec3 water = mix(vec3(0.015, 0.035, 0.045), vec3(0.03, 0.08, 0.09), smoothstep(-2.0, 3.0, crest));
	ALBEDO = mix(water, vec3(0.8, 0.85, 0.86), clamp(foam, 0.0, 1.0));
	ROUGHNESS = mix(0.08, 0.7, foam);
	SPECULAR = 0.6;
}
"""

const SPRAY := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform float fade = 1.0;
varying vec3 lp;
//NOISE
void vertex() { lp = VERTEX; VERTEX += NORMAL * (fbm(VERTEX * 2.0) - 0.5) * 0.5; }
void fragment() { ALBEDO = vec3(0.55, 0.62, 0.66) * fade * (0.5 + 0.5 * fbm(lp * 3.0)); }
"""

var _p := {}
var _sea_mat: ShaderMaterial
var _sea: MeshInstance3D
var _horizon: Node3D
var _sprays: Array = []
var _flash: OmniLight3D


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	_horizon = Node3D.new()
	root.add_child(_horizon)
	var plane := PlaneMesh.new()
	plane.size = Vector2(900, 900)
	plane.subdivide_width = 260
	plane.subdivide_depth = 260
	_sea = MeshInstance3D.new()
	_sea.mesh = plane
	_sea_mat = Kit.shader(SEA)
	_sea.material_override = _sea_mat
	_sea.position = Vector3(0, 2.5, 0)
	_horizon.add_child(_sea)
	_ship(root)
	for i in 10:
		var m := Kit.shader(SPRAY)
		var b := Kit.ball(root, 1.0, Vector3.ZERO, m, 16)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_sprays.append(b)
	_flash = Kit.omni(root, Vector3(-200, 140, -300), "#cfdcff", 0.0, 900.0, false, 0.0)
	return root


func _ship(root: Node3D) -> void:
	var hull_black := Kit.mat("#141516", 0.55, 0.0, 0.6)
	var boot_red := Kit.mat("#8a1f19", 0.6)
	var white := Kit.mat("#d9dad6", 0.6)
	var deck := Kit.mat("#4a5a3e", 0.75)
	var steel := Kit.mat("#7c8186", 0.45, 0.0, 0.6)
	# Hull: a long box with a raked, narrowing bow (stacked slabs) and a red boot-top below the waterline.
	Kit.box(root, Vector3(20, 9, 96), Vector3(0, 1.5, 10), hull_black)
	Kit.box(root, Vector3(20.2, 3.0, 96.2), Vector3(0, -1.5, 10), boot_red)
	for k in 8:
		var w := 20.0 - 2.3 * k
		Kit.box(root, Vector3(w, 9, 3.2), Vector3(0, 1.5 + k * 0.08, -39.5 - 3.0 * k), hull_black)
	Kit.box(root, Vector3(20, 0.3, 120), Vector3(0, DECK, 0), deck)
	# Hatch covers and the two deck cranes.
	for z in [-30.0, -14.0, 8.0, 24.0]:
		Kit.box(root, Vector3(14, 1.2, 12), Vector3(0, DECK + 0.6, z), Kit.mat("#2e4a6e", 0.6))
	for z in [-22.0, 16.0]:
		Kit.cyl(root, 0.9, 1.1, 10, Vector3(-6.5, DECK + 5, z), Kit.mat("#c9a22a", 0.5), 12)
		Kit.rod(root, Vector3(-6.5, DECK + 9, z), Vector3(4, DECK + 14, z + 6), 0.4, Kit.mat("#c9a22a", 0.5), 8)
	# The superstructure aft: five decks of white with lit windows, the bridge on top, the funnel.
	Kit.box(root, Vector3(18, 14, 12), Vector3(0, DECK + 7, 44), white)
	Kit.box(root, Vector3(22, 3, 8), Vector3(0, DECK + 15.5, 42), white)
	for f in 5:
		for x in range(-7, 8, 2):
			var lit := (x + f) % 3 != 0
			Kit.box(root, Vector3(1.2, 0.9, 0.1), Vector3(x, DECK + 2 + f * 2.6, 37.95), Kit.lit("#ffd9a0", 1.8) if lit else Kit.mat("#0d0f12", 0.2))
	for x in range(-10, 11, 2):
		Kit.box(root, Vector3(1.6, 1.0, 0.1), Vector3(x, DECK + 15.8, 37.95), Kit.lit("#bfe0ff", 1.4))
	Kit.cyl(root, 2.4, 2.6, 8, Vector3(0, DECK + 19, 48), Kit.mat("#1b1c1e", 0.5), 16)
	Kit.cyl(root, 2.62, 2.62, 1.5, Vector3(0, DECK + 21, 48), Kit.mat("#2a5aa8", 0.5), 16)
	Kit.rod(root, Vector3(0, DECK + 17, 40), Vector3(0, DECK + 30, 40), 0.15, steel, 6)
	Kit.ball(root, 0.25, Vector3(0, DECK + 30, 40), Kit.lit("#ff2a1a", 3.0), 8)
	# The tracking terminal: a 4 m dish on a steel pedestal and frame, forward of the bridge.
	var dish := Node3D.new()
	dish.position = Vector3(3.0, DECK, 33)
	root.add_child(dish)
	for x in [-1.8, 1.8]:
		for z in [-1.8, 1.8]:
			Kit.rod(dish, Vector3(x, 0, z), Vector3(x * 0.4, 3.2, z * 0.4), 0.1, steel, 6)
	Kit.box(dish, Vector3(4.2, 0.2, 4.2), Vector3(0, 0.1, 0), steel)
	Kit.cyl(dish, 0.6, 0.8, 1.2, Vector3(0, 3.6, 0), white, 16)
	var bowl := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 2.0
	sm.height = 0.9
	sm.is_hemisphere = true
	sm.radial_segments = 40
	sm.rings = 10
	bowl.mesh = sm
	bowl.material_override = white
	bowl.position = Vector3(0, 4.9, 0.6)
	bowl.rotation = Vector3(-2.3, 0, 0)
	dish.add_child(bowl)
	for k in 3:
		var a := TAU * float(k) / 3.0
		Kit.rod(dish, Vector3(0, 4.9, 0.6) + Vector3(cos(a) * 1.7, 0.4, sin(a) * 1.7).rotated(Vector3.RIGHT, -0.75), Vector3(0, 6.2, 1.9), 0.05, steel, 4)
	# Railings along the deck edge; the deck lights.
	for s in [-1.0, 1.0]:
		Kit.box(root, Vector3(0.06, 0.06, 100), Vector3(s * 9.8, DECK + 1.1, 2), steel)
		for z in range(-46, 50, 3):
			Kit.rod(root, Vector3(s * 9.8, DECK, z), Vector3(s * 9.8, DECK + 1.1, z), 0.03, steel, 4)
	Kit.spot(root, Vector3(0, DECK + 16, 37), Vector3(2, DECK, 26), "#ffe0b0", 9.0, 30.0, 45.0, true, 1.0)
	Kit.spot(root, Vector3(-6.5, DECK + 10, 16), Vector3(0, DECK, -20), "#ffd8a0", 6.0, 50.0, 30.0, false, 1.0)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	_sea_mat.set_shader_parameter("t", t)
	# The sea heaves round the ship: pitch and roll of the whole horizon.
	var pitch := 0.07 * sin(t * 0.95) + 0.025 * sin(t * 2.1)
	var roll := 0.05 * sin(t * 0.7 + 1.0)
	_horizon.rotation = Vector3(pitch, 0, roll)
	_horizon.position = Vector3(0, 1.4 * sin(t * 0.95 + 0.6), 0)
	# Spray: bursts over the bow every wave (on the pitch's downswing), arcing up and back, fading.
	var w = _p.get("waves", [])
	var t0 := float(w[0]) if w is Array and w.size() >= 1 else 0.0
	var period := TAU / 0.95
	for i in _sprays.size():
		var b: MeshInstance3D = _sprays[i]
		var phase := fposmod(t - t0 - 0.12 * i, period)
		var u := clampf(phase / 1.6, 0.0, 1.0)
		b.visible = phase < 1.6
		var side := -1.0 if i % 2 == 0 else 1.0
		b.position = Vector3(side * (2.0 + 0.6 * i), DECK + 1.0 + 9.0 * sin(u * PI) * (0.8 + 0.06 * i), -48.0 + 22.0 * u)
		b.scale = Vector3.ONE * (1.5 + 4.0 * u)
		(b.material_override as ShaderMaterial).set_shader_parameter("fade", (1.0 - u) * 0.9)
	# Lightning far off.
	var flash := 0.0
	for lt in _p.get("lightning", []):
		var a := t - float(lt)
		if a > 0.0 and a < 0.35:
			flash = maxf(flash, (1.0 - a / 0.35) * (0.6 + 0.4 * sin(a * 90.0)))
	_flash.light_energy = 6.0 * flash
	return {"dish": gt * Vector3(3.0, DECK + 4.5, 33), "bow": gt * Vector3(0, DECK + 2, -55), "bridge": gt * Vector3(0, DECK + 15, 38),
		"deck": gt * Vector3(2.0, DECK, 28)}
