extends RefCounted
## ISTRAC's Mission Operations Complex, Bengaluru, before dawn on 24 Sep 2014 (and on 22 Sep, the test fire).
##
## Local frame: the room faces -Z (the screen wall at z = -9). Three tiers of consoles rise toward the back:
## row 1 at z -5 (floor 0), row 2 at z -2.2 (floor 0.3), row 3 at z 0.6 (floor 0.6). Behind a glass wall at
## z 3.4 the visitors' gallery stands on a 1.3 m platform. Each console carries two monitors facing the
## controller; the controllers face the screen wall, lit blue from below by their monitors and from the front
## by the big screens. Warm down-lights over the gangway, darkness in the corners.
##
## params (scene seconds):
##   lost      t: the main screen's trace goes flat and the screens drop to "no signal"
##   static    [t0, t1]: the main screen shows static
##   back      t: the signal returns: the trace jumps, the screens go green
##   erupt     t: papers thrown in the air
##   key       {"t": t, "actor": id}: the command key goes down under that actor's right hand
##   hug       {"t": t, "a": id, "b": id}: a and b embrace (arms round each other's backs)
##   beard     [t0, t1]: night time-lapse over the room (the light dims and blues)
## anchors: screen (main screen centre), clock, key, gallery, row1, row2, row3, door

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const ROWS := [[-5.0, 0.0], [-2.2, 0.3], [0.6, 0.6]]
const GALLERY_Z := 3.4
const GALLERY_Y := 1.3
const W := 9.5

## Mission displays: navy, a grid, a Mars orbit diagram or telemetry plots, a trace; modes by uniforms.
const SCREEN_SHADER := """
shader_type spatial;
render_mode unshaded;
uniform int kind = 0;          // 0 orbit diagram, 1 telemetry plots, 2 trace, 3 monitor text blocks
uniform float t = 0.0;
uniform float lost = 0.0;      // 0 live .. 1 flat / no signal
uniform float noise = 0.0;     // static
uniform float good = 0.0;      // signal back: green
uniform float seed = 0.0;
uniform float energy = 1.6;
varying vec2 uv2;
//NOISE
void vertex() { uv2 = UV; }
float line(float d, float w) { return 1.0 - smoothstep(0.0, w, abs(d)); }
void fragment() {
	vec2 uv = uv2;
	vec3 bg = vec3(0.02, 0.05, 0.12);
	vec3 col = bg;
	vec2 g = fract(uv * vec2(16.0, 9.0));
	col += vec3(0.04, 0.09, 0.16) * (line(g.x, 0.03) + line(g.y, 0.03));
	vec3 ink = mix(vec3(0.45, 0.8, 1.0), vec3(0.4, 1.0, 0.55), good);
	if (kind == 0) {
		// Mars, MOM's approach and the planned orbit.
		vec2 p = (uv - vec2(0.55, 0.5)) * vec2(16.0 / 9.0, 1.0);
		float r = length(p);
		col = mix(col, vec3(0.75, 0.32, 0.16) * (0.6 + 0.4 * fbm(vec3(p * 9.0, 1.0))), 1.0 - smoothstep(0.17, 0.175, r));
		float e = length(p / vec2(0.42, 0.27)) - 1.0;
		col += ink * line(e, 0.012) * 0.8;
		float a = atan(p.y, p.x);
		vec2 ap = vec2(-0.55 + t * 0.0, 0.3);
		float approach = abs(p.y - 0.28 + (p.x + 0.9) * -0.18);
		col += vec3(1.0, 0.8, 0.4) * line(approach, 0.008) * step(p.x, -0.42) * 0.7;
		vec2 dot2 = vec2(-0.42, 0.24);
		col += vec3(1.0, 0.85, 0.5) * (1.0 - smoothstep(0.0, 0.02, length(p - dot2))) * (0.6 + 0.4 * sin(t * 8.0));
	} else if (kind == 1) {
		for (int i = 0; i < 3; i++) {
			float fi = float(i);
			float y0 = 0.2 + fi * 0.3;
			float wv = sin(uv.x * (8.0 + fi * 5.0) + t * (1.0 + fi) + seed) * 0.06 + (fbm(vec3(uv.x * 14.0 + t * 0.5, fi, seed)) - 0.5) * 0.08;
			wv *= 1.0 - lost;
			col += mix(ink, vec3(1.0, 0.75, 0.3), fi * 0.4) * line(uv.y - y0 - wv, 0.006) * 0.9;
		}
	} else if (kind == 2) {
		float x = uv.x;
		float live = sin(x * 40.0 + t * 6.0) * 0.12 * (0.6 + 0.4 * fbm(vec3(x * 10.0, t, seed)));
		float y = 0.5 + live * (1.0 - lost) + (good > 0.0 ? sin(x * 26.0 - t * 9.0) * 0.18 * good : 0.0);
		col += mix(ink, vec3(1.0, 0.35, 0.3), lost * (1.0 - good)) * line(uv.y - y, 0.008) * 1.2;
	} else {
		float rowi = floor(uv.y * 14.0);
		float len = fract(sin(rowi * 12.9898 + seed) * 43758.5453) * 0.7 + 0.15;
		float on = step(fract(uv.y * 14.0), 0.55) * step(uv.x, len) * step(0.06, uv.x);
		col += ink * on * 0.55;
		col += ink * line(uv.y - 0.94, 0.01) * 0.6;
	}
	float st = noise * h3(vec3(floor(uv * vec2(320.0, 180.0)), floor(t * 30.0)));
	col = mix(col, vec3(st), clamp(noise, 0.0, 1.0) * 0.85);
	ALBEDO = col * energy;
}
"""

const FLOOR_SHADER := """
shader_type spatial;
varying vec3 wp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	// Grey-blue carpet tiles, 0.5 m, slightly different in tone, with wear in the gangway.
	vec2 c = floor(wp.xz / 0.5);
	float tone = h3(vec3(c, 3.0)) * 0.06;
	float fib = fbm(wp * 40.0) * 0.12;
	vec3 col = vec3(0.16, 0.19, 0.24) * (0.92 + tone + fib);
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
}
"""

const WALL_SHADER := """
shader_type spatial;
uniform vec3 base : source_color = vec3(0.42, 0.44, 0.48);
varying vec3 wp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	// Acoustic panels: 1.2 m bays with a dark seam, a faint fabric weave.
	float seam = 1.0 - smoothstep(0.0, 0.015, min(fract(wp.x / 1.2 + wp.z / 1.2), 1.0 - fract(wp.x / 1.2 + wp.z / 1.2)));
	vec3 col = base * (0.9 + 0.12 * fbm(wp * vec3(30.0, 60.0, 30.0)));
	col *= 1.0 - seam * 0.5;
	ALBEDO = col;
	ROUGHNESS = 0.9;
}
"""

var _p := {}
var _screens: Array = []      # [ShaderMaterial, kind]
var _monitors: Array = []
var _key: Node3D
var _key_at := Vector3.ZERO
var _clock_hand: Node3D
var _clock_min: Node3D
var _papers: MultiMesh
var _paper_data: Array = []
var _downlights: Array = []
var _label_status: Label3D


func validate(g: Dictionary) -> Array:
	var e := []
	for k in g.get("params", {}):
		if not (k in ["lost", "static", "back", "erupt", "key", "hug", "beard"]):
			e.append("mission_control: unknown param '%s'" % k)
	return e


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	_room(root)
	_screen_wall(root)
	_consoles(root)
	_gallery(root)
	_lights(root)
	_paper_burst(root)
	return root


func _room(root: Node3D) -> void:
	var floor_m := Kit.shader(FLOOR_SHADER)
	Kit.box(root, Vector3(2 * W, 0.1, 18), Vector3(0, -0.05, -1.0), floor_m)
	# Tiers (risers) under rows 2 and 3, and the gallery platform.
	var riser := Kit.mat("#2b2f37", 0.85)
	for r in ROWS:
		if float(r[1]) > 0.0:
			Kit.box(root, Vector3(2 * W - 1.0, float(r[1]), 2.8), Vector3(0, float(r[1]) * 0.5, float(r[0]) + 0.6), floor_m)
			Kit.box(root, Vector3(2 * W - 1.0, 0.03, 0.06), Vector3(0, float(r[1]) + 0.01, float(r[0]) - 0.78), Kit.lit("#7fb2ff", 0.6))
	Kit.box(root, Vector3(2 * W, GALLERY_Y, 4.6), Vector3(0, GALLERY_Y * 0.5, GALLERY_Z + 2.3), riser)
	var wall := Kit.shader(WALL_SHADER)
	Kit.box(root, Vector3(0.2, 6.5, 18), Vector3(-W, 3.25, -1.0), wall)
	Kit.box(root, Vector3(0.2, 6.5, 18), Vector3(W, 3.25, -1.0), wall)
	Kit.box(root, Vector3(2 * W, 0.2, 18), Vector3(0, 6.5, -1.0), Kit.mat("#1a1c21", 0.9))
	Kit.box(root, Vector3(2 * W, 6.5, 0.2), Vector3(0, 3.25, 8.0), wall)
	# Ceiling grid of light panels (off) and a soffit over the screen wall.
	for x in range(-8, 9, 4):
		for z in range(-7, 7, 3):
			Kit.box(root, Vector3(1.2, 0.04, 0.6), Vector3(x, 6.38, z), Kit.mat("#2c2f35", 0.6))


func _screen_wall(root: Node3D) -> void:
	var z := -9.0
	Kit.box(root, Vector3(2 * W, 6.5, 0.3), Vector3(0, 3.25, z - 0.15), Kit.mat("#14161b", 0.8))
	# The main screen (orbit diagram) with two telemetry screens either side and a trace screen below them.
	var spec := [
		[Vector3(0, 3.35, z + 0.02), Vector2(6.4, 3.6), 0],
		[Vector3(-5.6, 3.9, z + 0.02), Vector2(3.6, 2.0), 1],
		[Vector3(5.6, 3.9, z + 0.02), Vector2(3.6, 2.0), 2],
		[Vector3(-5.6, 1.75, z + 0.02), Vector2(3.6, 1.6), 3],
		[Vector3(5.6, 1.75, z + 0.02), Vector2(3.6, 1.6), 1],
	]
	for i in spec.size():
		var s: Array = spec[i]
		var m := Kit.shader(SCREEN_SHADER)
		m.set_shader_parameter("kind", int(s[2]))
		m.set_shader_parameter("seed", float(i) * 3.7)
		var size: Vector2 = s[1]
		Kit.box(root, Vector3(size.x + 0.16, size.y + 0.16, 0.08), (s[0] as Vector3) + Vector3(0, 0, -0.03), Kit.mat("#08090b", 0.4))
		Kit.quad(root, size, (s[0] as Vector3) + Vector3(0, 0, 0.03), m)
		_screens.append([m, int(s[2])])
		var l := Kit.omni(root, (s[0] as Vector3) + Vector3(0, 0, 1.5), "#6fa8ff", 1.4 if i == 0 else 0.6, 12.0, false, 0.3)
		l.name = "screen_light_%d" % i
	# Header strip with the mission name, the ISRO logo above it.
	Kit.text(root, "MARS ORBITER MISSION", 0.34, Color("cfe3ff"), Vector3(0, 5.55, z + 0.05), Vector3.ZERO, true, 1.4)
	var logo := Kit.quad(root, Vector2(1.0, 1.0), Vector3(-3.3, 5.6, z + 0.05), _logo_mat())
	Kit.quad(root, Vector2(1.0, 1.0), Vector3(3.3, 5.6, z + 0.05), _logo_mat())
	_label_status = Kit.text(root, "LIVE", 0.22, Color("8fd3ff"), Vector3(0, 1.38, z + 0.05), Vector3.ZERO, true, 1.6)
	# The wall clock (IST), top right.
	var clock := Node3D.new()
	clock.position = Vector3(7.8, 5.5, z + 0.1)
	root.add_child(clock)
	Kit.cyl(clock, 0.42, 0.42, 0.06, Vector3.ZERO, Kit.mat("#e9e6de", 0.5), 40, Vector3(PI / 2, 0, 0))
	Kit.cyl(clock, 0.45, 0.45, 0.05, Vector3(0, 0, -0.01), Kit.mat("#1b1c20", 0.4), 40, Vector3(PI / 2, 0, 0))
	for i in 12:
		var a := TAU * float(i) / 12.0
		Kit.box(clock, Vector3(0.02, 0.07, 0.01), Vector3(sin(a) * 0.34, cos(a) * 0.34, 0.035), Kit.mat("#202125", 0.5), Vector3(0, 0, -a))
	_clock_min = Node3D.new()
	_clock_min.position = Vector3(0, 0, 0.04)
	clock.add_child(_clock_min)
	Kit.box(_clock_min, Vector3(0.025, 0.3, 0.01), Vector3(0, 0.13, 0), Kit.mat("#202125", 0.5))
	_clock_hand = Node3D.new()
	_clock_hand.position = Vector3(0, 0, 0.05)
	clock.add_child(_clock_hand)
	Kit.box(_clock_hand, Vector3(0.012, 0.36, 0.01), Vector3(0, 0.14, 0), Kit.mat("#c4282b", 0.5))


func _logo_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = Kit.texture("library/logos/isro.svg", false, 3.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.emission_enabled = true
	m.emission_texture = m.albedo_texture
	m.emission_energy_multiplier = 0.35
	m.roughness = 0.6
	return m


func _consoles(root: Node3D) -> void:
	var top := Kit.mat("#3a3f48", 0.45, 0.0, 0.6)
	var body := Kit.mat("#23262c", 0.7)
	var edge := Kit.mat("#8a8f98", 0.35)
	var seats := [[-6.6, -4.4, -2.2, 0.0, 2.2, 4.4, 6.6], [-6.6, -4.4, -2.2, 0.0, 2.2, 4.4, 6.6], [-5.5, -3.3, -1.1, 1.1, 3.3, 5.5]]
	for ri in ROWS.size():
		var z := float(ROWS[ri][0])
		var fy := float(ROWS[ri][1])
		# One long console per row, with a kick panel and a lit edge.
		Kit.slab(root, Vector3(2 * W - 2.0, 0.06, 0.95), 0.08, Vector3(0, fy + 0.62, z - 0.55), top)
		Kit.box(root, Vector3(2 * W - 2.2, 0.56, 0.08), Vector3(0, fy + 0.31, z - 0.95), body)
		Kit.box(root, Vector3(2 * W - 2.0, 0.02, 0.02), Vector3(0, fy + 0.655, z - 0.08), edge)
		for x in seats[ri]:
			var cx := float(x)
			# Two monitors angled in, facing the controller (+Z).
			for s in [-1.0, 1.0]:
				var mon := Node3D.new()
				mon.position = Vector3(cx + s * 0.36, fy + 0.66, z - 0.78)
				mon.rotation = Vector3(0, -s * 0.18, 0)
				root.add_child(mon)
				Kit.box(mon, Vector3(0.06, 0.12, 0.06), Vector3(0, 0.06, -0.02), body)
				Kit.slab(mon, Vector3(0.62, 0.04, 0.38), 0.01, Vector3(0, 0.22, 0), Kit.mat("#0c0d10", 0.4), Vector3(PI / 2, 0, 0))
				var sm := Kit.shader(SCREEN_SHADER)
				sm.set_shader_parameter("kind", 3 if s < 0.0 else 1)
				sm.set_shader_parameter("seed", cx * 1.3 + float(ri) * 7.1 + s)
				sm.set_shader_parameter("energy", 1.25)
				Kit.quad(mon, Vector2(0.57, 0.33), Vector3(0, 0.22, 0.024), sm)
				_monitors.append(sm)
			# A keyboard, a mouse, a steel tumbler of filter coffee on some desks, papers.
			Kit.box(root, Vector3(0.44, 0.02, 0.15), Vector3(cx, fy + 0.66, z - 0.36), Kit.mat("#16171b", 0.5))
			var r := Kit.rng("desk", int(cx * 10.0) + ri * 100)
			if r.randf() < 0.55:
				Kit.cyl(root, 0.035, 0.03, 0.1, Vector3(cx + 0.42, fy + 0.7, z - 0.32), Kit.mat("#c9ccd0", 0.25, 0.0, 0.9), 16)
			if r.randf() < 0.6:
				Kit.box(root, Vector3(0.21, 0.004, 0.3), Vector3(cx - 0.45, fy + 0.653, z - 0.3), Kit.mat("#ece8de", 0.85), Vector3(0, r.randf_range(-0.3, 0.3), 0))
			# Chair: a dark office chair behind each seat.
			Kit.cyl(root, 0.03, 0.03, 0.4, Vector3(cx, fy + 0.2, z + 0.2), edge, 8)
			Kit.cyl(root, 0.25, 0.25, 0.04, Vector3(cx, fy + 0.02, z + 0.2), body, 5)
			Kit.slab(root, Vector3(0.48, 0.07, 0.46), 0.08, Vector3(cx, fy + 0.43, z + 0.2), Kit.mat("#1f2228", 0.8))
			Kit.slab(root, Vector3(0.46, 0.55, 0.07), 0.06, Vector3(cx, fy + 0.78, z + 0.47), Kit.mat("#1f2228", 0.8))
	# The command key: a red guarded button on row 1, right of centre.
	_key = Node3D.new()
	_key_at = Vector3(1.95, 0.665, -5.25)
	_key.position = _key_at
	root.add_child(_key)
	Kit.box(_key, Vector3(0.14, 0.03, 0.14), Vector3(0, 0.0, 0), Kit.mat("#222428", 0.5))
	var cap := Kit.cyl(_key, 0.045, 0.045, 0.035, Vector3(0, 0.03, 0), Kit.mat("#d1262b", 0.35, 0.0, 0.7), 20)
	cap.name = "cap"
	var guard := Kit.box(_key, Vector3(0.13, 0.008, 0.13), Vector3(0, 0.08, -0.05), Kit.mat("#c9d6e0", 0.1, 0.0, 0.9), Vector3(-1.2, 0, 0))
	guard.name = "guard"
	guard.transparency = 0.45


func _gallery(root: Node3D) -> void:
	# Glass wall with mullions; inside, a row of chairs, a warm wash.
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.55, 0.65, 0.75, 0.12)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.04
	glass.metallic_specular = 1.0
	Kit.box(root, Vector3(2 * W, 3.2, 0.03), Vector3(0, GALLERY_Y + 1.6, GALLERY_Z), glass)
	for x in range(-9, 10, 3):
		Kit.box(root, Vector3(0.06, 3.2, 0.08), Vector3(x, GALLERY_Y + 1.6, GALLERY_Z), Kit.mat("#2a2d33", 0.4))
	Kit.box(root, Vector3(2 * W, 0.06, 0.1), Vector3(0, GALLERY_Y + 0.62, GALLERY_Z + 0.05), Kit.mat("#2a2d33", 0.4))
	for x in range(-6, 7, 2):
		Kit.slab(root, Vector3(0.55, 0.08, 0.5), 0.08, Vector3(x, GALLERY_Y + 0.45, GALLERY_Z + 1.8), Kit.mat("#5a2a24", 0.7))
		Kit.slab(root, Vector3(0.55, 0.6, 0.08), 0.06, Vector3(x, GALLERY_Y + 0.8, GALLERY_Z + 2.08), Kit.mat("#5a2a24", 0.7))


func _lights(root: Node3D) -> void:
	# Warm down-lights over the gangways and the gallery; cool fill from the monitors per row.
	for x in [-6.0, -2.0, 2.0, 6.0]:
		for z in [-6.5, -3.5, -0.8]:
			var l := Kit.spot(root, Vector3(x, 6.2, z), Vector3(x, 0, z), "#ffc98a", 2.6, 9.0, 34.0, false, 0.5)
			_downlights.append(l)
	for x in [-5.0, 0.0, 5.0]:
		Kit.spot(root, Vector3(x, 6.0, GALLERY_Z + 2.0), Vector3(x, GALLERY_Y, GALLERY_Z + 1.0), "#ffd29a", 2.2, 8.0, 40.0, true, 0.3)
	for r in ROWS:
		for x in [-5.5, 0.0, 5.5]:
			Kit.omni(root, Vector3(x, float(r[1]) + 1.05, float(r[0]) - 0.55), "#7fb6ff", 1.1, 3.6, false, 0.2)
	# Rim light from the screens, raking across the rows.
	Kit.spot(root, Vector3(0, 4.5, -8.5), Vector3(0, 0.8, 0), "#8fbaff", 2.4, 20.0, 50.0, true, 0.4)


## Sheets of paper thrown up when the room erupts: arcs, flutter, settle.
func _paper_burst(root: Node3D) -> void:
	var qm := QuadMesh.new()
	qm.size = Vector2(0.21, 0.297)
	_papers = MultiMesh.new()
	_papers.transform_format = MultiMesh.TRANSFORM_3D
	_papers.mesh = qm
	_papers.instance_count = 60
	var r := Kit.rng("papers")
	for i in 60:
		var start := Vector3(r.randf_range(-7, 7), 0, 0)
		var ri := r.randi_range(0, 2)
		start.z = float(ROWS[ri][0]) - 0.4
		start.y = float(ROWS[ri][1]) + 0.8
		_paper_data.append([start, Vector3(r.randf_range(-1.2, 1.2), r.randf_range(4.0, 6.5), r.randf_range(-1.5, 0.8)),
			r.randf_range(0.0, 0.6), Vector3(r.randf_range(-6, 6), r.randf_range(-6, 6), r.randf_range(-6, 6))])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _papers
	var pm := Kit.mat("#f1eee6", 0.8)
	pm.cull_mode = BaseMaterial3D.CULL_DISABLED
	mmi.material_override = pm
	root.add_child(mmi)


func _f(key: String, fallback: float = 1e9) -> float:
	var v = _p.get(key, null)
	if v is Array:
		return float(v[0]) if v.size() > 0 else fallback
	if v is Dictionary:
		return float(v.get("t", fallback))
	return float(v) if v != null else fallback


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var lost_t := _f("lost")
	var back_t := _f("back")
	var lost := clampf((t - lost_t) / 0.4, 0.0, 1.0) * (1.0 - clampf((t - back_t) / 0.3, 0.0, 1.0))
	var good := clampf((t - back_t) / 0.3, 0.0, 1.0)
	var noise := 0.0
	var st = _p.get("static", null)
	if st is Array and st.size() >= 2 and t >= float(st[0]) and t < float(st[1]):
		noise = 0.75 + 0.25 * sin(t * 40.0)
	for s in _screens:
		var m: ShaderMaterial = s[0]
		m.set_shader_parameter("t", t)
		m.set_shader_parameter("lost", lost)
		m.set_shader_parameter("good", good)
		m.set_shader_parameter("noise", noise if int(s[1]) == 0 else noise * 0.4)
	for m in _monitors:
		(m as ShaderMaterial).set_shader_parameter("t", t)
		(m as ShaderMaterial).set_shader_parameter("lost", lost * 0.6)
		(m as ShaderMaterial).set_shader_parameter("good", good)
	_label_status.text = "SIGNAL ACQUIRED" if good > 0.5 else ("NO SIGNAL" if lost > 0.5 else "LIVE")
	_label_status.modulate = (Color("6dff8a") if good > 0.5 else (Color("ff6b5e") if lost > 0.5 else Color("8fd3ff"))) * 1.6
	# The clock: a second hand ticking (a tick per second), the minute hand creeping.
	_clock_hand.rotation = Vector3(0, 0, -TAU * floor(t) / 60.0)
	_clock_min.rotation = Vector3(0, 0, -TAU * (17.0 + t / 60.0) / 60.0)
	# Night time-lapse for the beard shot: the down-lights dim.
	var bw = _p.get("beard", null)
	var dim := 1.0
	if bw is Array and bw.size() >= 2 and t >= float(bw[0]) and t <= float(bw[1]):
		var u := (t - float(bw[0])) / maxf(float(bw[1]) - float(bw[0]), 0.01)
		dim = 0.55 + 0.45 * absf(cos(u * PI * 3.0))
	# The house lights come up when the room erupts.
	dim *= 1.0 + 0.7 * clampf((t - _f("erupt")) / 0.8, 0.0, 1.0)
	for l in _downlights:
		(l as SpotLight3D).light_energy = 2.6 * dim
	# The command key: the guard flips up, the cap goes down under the finger, comes back up.
	var key = _p.get("key", null)
	var cap := _key.get_node("cap") as Node3D
	var guard := _key.get_node("guard") as Node3D
	var kt := _f("key")
	var press := 0.0
	if key is Dictionary:
		guard.rotation = Vector3(-1.2 - 1.6 * Motion.out_cubic(clampf((t - kt + 1.3) / 0.4, 0.0, 1.0)), 0, 0)
		press = Motion.impact(t - kt, 1.0, 3.0, 12.0) if t >= kt else 0.0
		press = clampf(1.0 - absf(t - kt) / 0.18, 0.0, 1.0)
		cap.position = Vector3(0, 0.03 - 0.018 * press, 0)
		var act = ctx.get("actor", null)
		if act and t > kt - 0.9 and t < kt + 0.9:
			var who = act.call(String(key.get("actor", "")))
			if who:
				var reach := Motion.in_out(clampf((t - kt + 0.9) / 0.75, 0.0, 1.0)) * (1.0 - Motion.in_out(clampf((t - kt - 0.3) / 0.6, 0.0, 1.0)))
				var target := node.global_transform * (_key_at + Vector3(0, 0.07 - 0.03 * press, 0.02))
				who.aim_hand("r", target, reach, 0.0)
	# The hug.
	var hug = _p.get("hug", null)
	var act2 = ctx.get("actor", null)
	if hug is Dictionary and act2:
		var ht := float(hug.get("t", 1e9))
		var w := Motion.out_cubic(clampf((t - ht + 0.35) / 0.35, 0.0, 1.0))
		if w > 0.0:
			var a = act2.call(String(hug.get("a", "")))
			var b = act2.call(String(hug.get("b", "")))
			if a and b:
				var pa: Vector3 = a.bone_world("spine_03")
				var pb: Vector3 = b.bone_world("spine_03")
				var d := (pb - pa)
				d.y = 0.0
				var side := d.normalized().cross(Vector3.UP)
				var pat := 0.03 * sin(t * 14.0) if t > ht + 0.3 else 0.0
				a.aim_hand("l", pb - d.normalized() * 0.05 + side * 0.14 + Vector3(0, 0.05 + pat, 0), w)
				a.aim_hand("r", pb - d.normalized() * 0.05 - side * 0.14 + Vector3(0, 0.08, 0), w)
				b.aim_hand("l", pa + d.normalized() * 0.05 - side * 0.14 + Vector3(0, 0.05, 0), w)
				b.aim_hand("r", pa + d.normalized() * 0.05 + side * 0.14 + Vector3(0, 0.08 - pat, 0), w)
	# Papers.
	var et := _f("erupt")
	for i in _paper_data.size():
		var d: Array = _paper_data[i]
		var age: float = t - et - float(d[2])
		var xf := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.0001), Vector3(0, -50, 0))
		if age > 0.0:
			var v: Vector3 = d[1]
			# Up fast, then drag: sheets drift down slowly, fluttering.
			var up := v.y * (1.0 - exp(-age * 2.2)) / 2.2 - 0.9 * maxf(age - 0.6, 0.0)
			var pos: Vector3 = (d[0] as Vector3) + Vector3(v.x * (1.0 - exp(-age * 1.5)) / 1.5 + sin(age * 3.0 + i) * 0.25, up, v.z * (1.0 - exp(-age * 1.5)) / 1.5)
			var floor_y := 0.02
			pos.y = maxf(pos.y, floor_y)
			var sp: Vector3 = d[3]
			var basis := Basis.from_euler(sp * age * (0.4 if pos.y > floor_y + 0.01 else 0.0) + Vector3(PI / 2, 0, 0))
			xf = Transform3D(basis, pos)
		_papers.set_instance_transform(i, xf)
	var gt := node.global_transform
	return {"screen": gt * Vector3(0, 3.35, -9.0), "clock": gt * Vector3(7.8, 5.5, -8.9), "key": gt * _key_at,
		"gallery": gt * Vector3(0, GALLERY_Y, GALLERY_Z + 1.2), "row1": gt * Vector3(0, 0, ROWS[0][0]),
		"row2": gt * Vector3(0, ROWS[1][1], ROWS[1][0]), "row3": gt * Vector3(0, ROWS[2][1], ROWS[2][0])}
