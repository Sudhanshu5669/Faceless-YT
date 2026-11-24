## Rashtrapati Bhavan, New Delhi, July 2002 (dramatised, the forecourt front): a broad flight of red sandstone steps up
## to a colonnade of cream columns on a red podium, the facade behind with dark doorways, chhatris at the corners, the great
## dome on its drum with the tricolour flying above; the President's Bodyguard lining the steps in scarlet with lances.
##
## Local frame: the foot of the steps at z 0, centred on x 0, rising toward -z (STEP_N steps up to the landing at y
## LANDING_Y, z -STEPS_D); the colonnade at z COL_Z; the dome's centre at DOME_AT. Cameras stand at +z looking -z.
##
## params:
##   lances  [actor ids]   each holds a ceremonial lance upright in the right hand, a red-and-white pennant near the tip
##   flag    true   the tricolour on the dome's flagpole, rippling
## anchors: landing (its middle, head height), dome (its top), doors
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")
const STEP_N := 24
const STEPS_D := 12.0
const LANDING_Y := 4.8
const COL_Z := -19.0
const WALL_Z := -23.0
const DOME_AT := Vector3(0.0, 0.0, -34.0)
const HALF_W := 34.0

const STONE := """
shader_type spatial;
uniform vec3 base : source_color = vec3(0.72, 0.36, 0.26);
uniform float scale = 1.0;
varying vec3 wp;
float h(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float n3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h(i), h(i + vec3(1, 0, 0)), f.x), mix(h(i + vec3(0, 1, 0)), h(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h(i + vec3(0, 0, 1)), h(i + vec3(1, 0, 1)), f.x), mix(h(i + vec3(0, 1, 1)), h(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 q = wp * scale;
	float n = n3(q * 2.0) * 0.5 + n3(q * 7.0) * 0.3 + n3(q * 0.5) * 0.2;
	vec3 c = base * (0.86 + 0.25 * n);
	// Ashlar courses: horizontal joints every 0.6 m, staggered vertical joints.
	float row = floor(wp.y / 0.6);
	float jy = smoothstep(0.0, 0.025, abs(fract(wp.y / 0.6) - 0.5) * 2.0 - 0.94 + 0.94);
	float u = (wp.x + wp.z) / 1.4 + row * 0.5;
	float jx = smoothstep(0.0, 0.02, abs(fract(u) - 0.5) * 2.0 - 0.96 + 0.96);
	c *= 0.82 + 0.18 * min(jy, jx);
	ALBEDO = c;
	ROUGHNESS = 0.85;
}
"""

var _p := {}
var _lances := {}
var _flag: MeshInstance3D
var _flag_mat: ShaderMaterial

const FLAG := """
shader_type spatial;
render_mode cull_disabled;
uniform float t = 0.0;
void vertex() {
	float k = UV.x;
	VERTEX.z += k * 0.35 * sin(UV.x * 6.0 - t * 5.0) + k * 0.12 * sin(UV.y * 4.0 - t * 3.0);
}
void fragment() {
	vec3 saffron = vec3(1.0, 0.6, 0.2);
	vec3 white = vec3(0.97);
	vec3 green = vec3(0.07, 0.53, 0.03);
	vec3 c = UV.y < 0.333 ? saffron : (UV.y < 0.667 ? white : green);
	// The Ashoka Chakra: a navy wheel in the white band.
	vec2 q = (UV - vec2(0.5)) * vec2(1.5, 1.0);
	float r = length(q);
	float ring = smoothstep(0.012, 0.0, abs(r - 0.13));
	float ang = atan(q.y, q.x);
	float spokes = smoothstep(0.06, 0.0, abs(fract(ang / 6.2832 * 24.0) - 0.5) * 2.0 * r) * step(r, 0.13);
	c = mix(c, vec3(0.0, 0.0, 0.5), max(ring, spokes * 0.9));
	ALBEDO = c;
	ROUGHNESS = 0.8;
}
"""


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "rashtrapati"))
	var red := Kit.shader(STONE)
	red.set_shader_parameter("base", Color(0.68, 0.33, 0.24))
	var cream := Kit.shader(STONE)
	cream.set_shader_parameter("base", Color(0.9, 0.8, 0.64))
	var dark := Kit.mat("#2a1e18", 0.8)
	# The forecourt: a wide sandstone apron.
	Kit.box(root, Vector3(200, 0.2, 140), Vector3(0, -0.1, 30), red)
	# The steps.
	var sd := STEPS_D / STEP_N
	var sh := LANDING_Y / STEP_N
	for i in STEP_N:
		Kit.box(root, Vector3(HALF_W * 1.2, sh * (i + 1), sd), Vector3(0, sh * (i + 1) * 0.5, -sd * (i + 0.5)), red if i % 6 != 5 else cream)
	# Side cheek walls of the stair with lamp standards.
	for s: float in [-1.0, 1.0]:
		var cw := Kit.box(root, Vector3(1.6, LANDING_Y + 1.0, STEPS_D + 1.0), Vector3(s * (HALF_W * 0.6 + 0.8), (LANDING_Y + 1.0) * 0.5 - 0.5, -STEPS_D * 0.5), red)
		cw.rotation.x = 0.0
		for k in 3:
			var lz := -1.0 - k * 5.0
			var ly := LANDING_Y * (1.0 - lz / -STEPS_D * -1.0) * 0.0 + (LANDING_Y + 0.5) * (-lz / STEPS_D) + 0.5
			var lp := Vector3(s * (HALF_W * 0.6 + 0.8), ly + 0.4, lz)
			Kit.cyl(root, 0.08, 0.12, 2.2, lp + Vector3(0, 1.1, 0), Kit.mat("#20201e", 0.4, 0.6), 10)
			Kit.ball(root, 0.22, lp + Vector3(0, 2.35, 0), Kit.mat("#f4ead0", 0.3), 14)
	# The landing and the podium.
	Kit.box(root, Vector3(HALF_W * 2.0, LANDING_Y, 30.0), Vector3(0, LANDING_Y * 0.5, -STEPS_D - 15.0), red)
	# The colonnade: cream columns with bell capitals on bases, an entablature, the frieze.
	var col_h := 10.0
	for k in 14:
		var x := -16.25 + 2.5 * k
		var base := Vector3(x, LANDING_Y, COL_Z)
		Kit.box(root, Vector3(1.4, 0.5, 1.4), base + Vector3(0, 0.25, 0), cream)
		Kit.cyl(root, 0.52, 0.58, col_h, base + Vector3(0, 0.5 + col_h * 0.5, 0), cream, 20)
		Kit.cyl(root, 0.85, 0.55, 0.6, base + Vector3(0, 0.5 + col_h + 0.3, 0), cream, 20)
		# The Delhi Order's hanging bells, a band of dark stone.
		Kit.cyl(root, 0.6, 0.6, 0.2, base + Vector3(0, 0.5 + col_h * 0.72, 0), Kit.mat("#8a6a4a", 0.8), 20)
	var top := LANDING_Y + 0.5 + col_h + 0.6
	Kit.box(root, Vector3(38.0, 1.4, 2.4), Vector3(0, top + 0.7, COL_Z), cream)
	Kit.box(root, Vector3(38.6, 0.3, 2.8), Vector3(0, top + 1.55, COL_Z), cream)
	Kit.box(root, Vector3(38.0, 1.2, 0.5), Vector3(0, top + 2.3, COL_Z + 1.0), red)
	# The facade wall behind the columns: cream over red, dark tall doorways and windows.
	Kit.box(root, Vector3(HALF_W * 2.0, top + 2.5 - LANDING_Y, 1.0), Vector3(0, LANDING_Y + (top + 2.5 - LANDING_Y) * 0.5, WALL_Z), cream)
	Kit.box(root, Vector3(HALF_W * 2.0 + 0.2, 3.0, 1.2), Vector3(0, LANDING_Y + 1.5, WALL_Z), red)
	for k in 7:
		var x := -12.0 + 4.0 * k
		Kit.box(root, Vector3(1.8, 5.0, 0.2), Vector3(x, LANDING_Y + 2.5, WALL_Z + 0.55), dark)
		Kit.box(root, Vector3(1.4, 2.2, 0.2), Vector3(x, LANDING_Y + 7.6, WALL_Z + 0.55), dark)
	# Wings either side, lower, red and cream bands, chhatris on the corners.
	for s: float in [-1.0, 1.0]:
		Kit.box(root, Vector3(30.0, 13.0, 18.0), Vector3(s * 34.0, LANDING_Y + 6.5, WALL_Z - 4.0), cream)
		Kit.box(root, Vector3(30.2, 3.0, 18.2), Vector3(s * 34.0, LANDING_Y + 1.5, WALL_Z - 4.0), red)
		Kit.box(root, Vector3(30.4, 0.6, 18.4), Vector3(s * 34.0, LANDING_Y + 13.3, WALL_Z - 4.0), red)
		for k in 6:
			Kit.box(root, Vector3(1.2, 2.0, 0.2), Vector3(s * (22.0 + 4.0 * k), LANDING_Y + 6.0, WALL_Z + 5.05), dark)
		var ch := Vector3(s * 20.5, top + 2.5, COL_Z - 1.0)
		for cx: float in [-1.0, 1.0]:
			for cz: float in [-1.0, 1.0]:
				Kit.cyl(root, 0.12, 0.12, 2.2, ch + Vector3(cx * 1.0, 1.1, cz * 1.0), cream, 8)
		Kit.box(root, Vector3(2.6, 0.25, 2.6), ch + Vector3(0, 2.3, 0), cream)
		Kit.ball(root, 1.2, ch + Vector3(0, 2.6, 0), cream, 20, Vector3(1, 0.8, 1))
	# The dome: a red drum with a cream colonnade band, the hemisphere, the finial; the tricolour above.
	var dy := top + 2.5
	Kit.cyl(root, 13.0, 13.0, 4.0, DOME_AT + Vector3(0, dy + 2.0, 0), red, 48)
	for k in 32:
		var a := TAU * k / 32.0
		Kit.cyl(root, 0.35, 0.35, 4.0, DOME_AT + Vector3(cos(a) * 12.4, dy + 6.0, sin(a) * 12.4), cream, 10)
	Kit.cyl(root, 12.0, 12.0, 4.0, DOME_AT + Vector3(0, dy + 6.0, 0), cream, 48)
	Kit.cyl(root, 13.0, 13.0, 0.8, DOME_AT + Vector3(0, dy + 8.4, 0), red, 48)
	Kit.ball(root, 11.6, DOME_AT + Vector3(0, dy + 8.8, 0), cream, 48, Vector3(1, 0.95, 1))
	Kit.cyl(root, 0.5, 1.4, 1.6, DOME_AT + Vector3(0, dy + 8.8 + 11.0 + 0.6, 0), red, 16)
	var pole_base := DOME_AT + Vector3(0, dy + 8.8 + 11.0 + 1.4, 0)
	Kit.rod(root, pole_base, pole_base + Vector3(0, 9.0, 0), 0.09, Kit.mat("#d8d8d0", 0.3, 0.6), 8)
	_flag_mat = Kit.shader(FLAG)
	_flag = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(6.0, 4.0)
	pm.subdivide_width = 16
	pm.subdivide_depth = 8
	pm.orientation = PlaneMesh.FACE_Z
	_flag.mesh = pm
	_flag.material_override = _flag_mat
	_flag.position = pole_base + Vector3(3.05, 7.0, 0)
	root.add_child(_flag)
	# Lances for the bodyguard.
	for aid in _p.get("lances", []):
		var ln := Node3D.new()
		Kit.rod(ln, Vector3(0, -1.2, 0), Vector3(0, 1.6, 0), 0.016, Kit.mat("#5a3a20", 0.7), 6)
		Kit.cyl(ln, 0.0, 0.03, 0.16, Vector3(0, 1.68, 0), Kit.mat("#d8d8d8", 0.2, 0.9), 8)
		Kit.box(ln, Vector3(0.3, 0.09, 0.005), Vector3(0.15, 1.5, 0), Kit.mat("#c81e1e", 0.7))
		Kit.box(ln, Vector3(0.3, 0.09, 0.005), Vector3(0.15, 1.41, 0), Kit.mat("#f2f2f2", 0.7))
		root.add_child(ln)
		_lances[String(aid)] = ln
	# Morning sun is the key; a little bounce off the pale stone.
	Kit.omni(root, Vector3(0, 3.0, 4.0), Color(1.0, 0.85, 0.7), 0.6, 18.0, false, 0.2)
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var inv := gt.affine_inverse()
	_flag_mat.set_shader_parameter("t", t)
	if ctx.has("actor"):
		for aid in _lances:
			var a = ctx["actor"].call(aid)
			var ln: Node3D = _lances[aid]
			ln.visible = a != null and a.visible
			if not ln.visible:
				continue
			var ay := float(a.rotation.y)
			var fwd := Vector3(sin(ay), 0, cos(ay))
			var right := -Vector3(cos(ay), 0, -sin(ay))
			var hand: Vector3 = a.bone_world("spine_03") + right * 0.3 + fwd * 0.12 + Vector3(0, -0.05, 0)
			ln.transform = Transform3D(Basis(Vector3.UP, ay - gt.basis.get_euler().y), inv * hand)
			Crawl.long_arms(a, 1.2)
			a.aim_hand("r", hand, 1.0)
	var dy := LANDING_Y + 0.5 + 10.0 + 0.6 + 2.5
	return {"landing": gt * Vector3(0, LANDING_Y + 1.3, -STEPS_D - 1.0), "dome": gt * (DOME_AT + Vector3(0, dy + 21.0, 0)),
		"doors": gt * Vector3(0, LANDING_Y + 2.0, WALL_Z + 0.6)}
