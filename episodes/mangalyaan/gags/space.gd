extends RefCounted
## Space for the Mangalyaan Short: Earth, Mars, the spacecraft and the orbits, in one gag.
##
## Four stations far apart in the gag's frame (metres; the camera never sees two at once):
##   E  Earth (R 60) at the origin: MOM's six orbit-raising loops, the TMI burn over night-side India,
##      the slingshot out; Phobos-Grunt (carrying China's Yinghuo-1) stalls and burns up.
##   M  Mars (R 36) at (0, 0, -6000): the club (Mariner 9, Mars 3, Mars Express), Nozomi passing by,
##      MAVEN's arrival, MOM's test fire, orbit insertion (part of it behind Mars), the orbit, the years.
##   C  Deep space at (-6000, 0, 0): MOM coasting with Earth and Mars as dots.
##   D  A diagram at (6000, 0, 0): a small Earth below, Mars above, 51 mission arcs (more than half
##      fail), and the radio pulse that takes twelve minutes.
## Light: the look's key light (params.sun = [elevation, azimuth], the same as the look's light) sets
## Earth's terminator; the night side shows city lights.
##
## params (times in scene seconds, resolved by the pipeline):
##   sun        [elevation, azimuth] of the key light
##   club       [t_us, t_ussr, t_eu, t_end]   the three orbiters swing in, one per word
##   nozomi     [t0, t1]                       Japan's probe drifts past Mars and tumbles away
##   china      [t0, t1]                       Phobos-Grunt + Yinghuo-1 decay and burn up over Earth
##   arcs       [t0, t1, t_count]              the 51 arcs draw; failures end in a red flash
##   loops      [t0, t1]                       six orbits, each bigger, a burn at every perigee
##   tmi        [t0, t1]                       the final burn at perigee over India at night
##   escape     [t0, t1]                       MOM flies out of the last loop
##   cruise     [t0, t1]                       coasting
##   maven      [t0, t1]                       MAVEN slides into orbit along a red carpet of light
##   tags       [t_maven, t_mom, t_end]        price tags drop on strings
##   test       [t0, t1]                       the 4-second test fire (t0 = ignition)
##   moi        [t_turn, t_ignite, t_behind, t_out, t_end]
##   ghost      [t0, t1]                       the failure path: a ghost MOM flies on past Mars
##   pulse      [t0, t1]                       a radio pulse crawls from Mars to Earth (diagram)
##   reply      [t0, t1]                       MOM blinks its dish light
##   years      [t0, t_six, t_eight, t1]       the orbit time-lapse
## anchors: earth, mars, mom_e, mom_m, mom_c, maven, diagram_earth, diagram_mars, tag_maven, tag_mom

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Paths = preload("res://scripts/core/paths.gd")

static var _mom_gd: GDScript
var FOIL_SHADER: String
var CELL_SHADER: String
var FLAME_SHADER: String


## The shared spacecraft model (gags/mom_model.gd), compiled once.
static func mom_script() -> GDScript:
	if _mom_gd == null:
		_mom_gd = GDScript.new()
		_mom_gd.source_code = FileAccess.get_file_as_string(Paths.repo_path("episodes/mangalyaan/gags/mom_model.gd"))
		_mom_gd.reload()
	return _mom_gd


func _mom(k: float = 1.0) -> Node3D:
	return mom_script().new().build(k)

const RE := 60.0
const RM := 36.0
const M_AT := Vector3(0, 0, -6000)
const C_AT := Vector3(-6000, 0, 0)
const D_AT := Vector3(6000, 0, 0)
const TEX := "incoming/sss_textures/"

# Orbit-raising: perigee and apogees (Earth radii; compressed from the real 0.04 R x 4.5..30 R).
const PERIGEE := 1.09
const APOGEES := [2.3, 3.0, 3.9, 4.6, 5.8, 7.4]
const ORBIT_TILT := Vector3(deg_to_rad(-18), deg_to_rad(152), 0)

const EARTH_SHADER := """
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;
uniform sampler2D day : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D night : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D spec : filter_linear_mipmap, repeat_enable;
uniform sampler2D nmap : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 sun_dir = vec3(0.0, 0.0, 1.0);
uniform float lon = 0.0;
uniform float night_gain = 2.6;
varying vec3 wn;
varying vec3 on;
void vertex() {
	on = normalize(VERTEX);
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	float lo = atan(on.x, on.z);
	float la = asin(clamp(on.y, -1.0, 1.0));
	vec2 uv = vec2(fract(0.5 + lo / 6.2831853 + lon), 0.5 - la / 3.14159265);
	vec3 c = texture(day, uv).rgb;
	float s = texture(spec, uv).r;
	ALBEDO = c * mix(1.05, 0.85, s);
	ROUGHNESS = mix(0.82, 0.32, s);
	SPECULAR = mix(0.25, 0.7, s);
	NORMAL_MAP = texture(nmap, uv).rgb;
	NORMAL_MAP_DEPTH = 0.6;
	float lit = dot(normalize(wn), normalize(sun_dir));
	float dark = smoothstep(0.08, -0.12, lit);
	vec3 nl = texture(night, uv).rgb;
	EMISSION = nl * nl * vec3(1.0, 0.78, 0.45) * night_gain * dark * 3.0 + c * vec3(0.5, 0.6, 0.9) * 0.035 * dark;
}
"""

const CLOUD_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_lambert;
uniform sampler2D clouds : filter_linear_mipmap_anisotropic, repeat_enable;
uniform float lon = 0.0;
uniform float amount = 0.9;
varying vec3 on;
void vertex() { on = normalize(VERTEX); }
void fragment() {
	float lo = atan(on.x, on.z);
	float la = asin(clamp(on.y, -1.0, 1.0));
	vec2 uv = vec2(fract(0.5 + lo / 6.2831853 + lon), 0.5 - la / 3.14159265);
	float a = texture(clouds, uv).r;
	ALBEDO = vec3(0.97);
	ALPHA = smoothstep(0.08, 0.85, a) * amount;
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}
"""

## The atmosphere: an additive rim, bright on the day side, a thin sunset band at the terminator.
const ATMO_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
uniform vec3 sun_dir = vec3(0.0, 0.0, 1.0);
uniform vec3 tint : source_color = vec3(0.35, 0.6, 1.0);
uniform vec3 dusk : source_color = vec3(1.0, 0.5, 0.25);
uniform float power = 2.6;
uniform float gain = 1.6;
varying vec3 wn;
void vertex() { wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }
void fragment() {
	float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float l = dot(normalize(wn), normalize(sun_dir));
	float day = smoothstep(-0.25, 0.35, l);
	float band = exp(-pow(l / 0.18, 2.0));
	vec3 c = tint * day + dusk * band * 0.6;
	ALBEDO = c * pow(rim, power) * gain;
}
"""

const MARS_SHADER := """
shader_type spatial;
uniform sampler2D albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float lon = 0.0;
varying vec3 on;
void vertex() { on = normalize(VERTEX); }
void fragment() {
	float lo = atan(on.x, on.z);
	float la = asin(clamp(on.y, -1.0, 1.0));
	vec2 uv = vec2(fract(0.5 + lo / 6.2831853 + lon), 0.5 - la / 3.14159265);
	vec3 c = texture(albedo, uv).rgb;
	// Relief from the albedo's own gradient: darker basins read as lower.
	vec2 px = vec2(1.0 / 8192.0, 1.0 / 4096.0) * 2.0;
	float h0 = dot(c, vec3(0.33));
	float hx = dot(texture(albedo, uv + vec2(px.x, 0.0)).rgb, vec3(0.33));
	float hy = dot(texture(albedo, uv + vec2(0.0, px.y)).rgb, vec3(0.33));
	NORMAL_MAP = normalize(vec3((h0 - hx) * 6.0, (h0 - hy) * 6.0, 1.0)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.0;
	ALBEDO = pow(c, vec3(1.08)) * vec3(1.04, 0.98, 0.94);
	ROUGHNESS = 0.96;
	SPECULAR = 0.15;
}
"""

## Glowing tube (orbit trails, arcs): `reveal` 0..1 along the path, a bright head.
const TRAIL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec3 color : source_color = vec3(1.0, 0.75, 0.3);
uniform float reveal = 1.0;
uniform float start = 0.0;
uniform float gain = 1.0;
uniform float head = 1.0;
varying vec2 uv2;
void vertex() { uv2 = UV; }
void fragment() {
	if (uv2.x > reveal || uv2.x < start) { discard; }
	float tail = 0.35 + 0.65 * exp(-(reveal - uv2.x) * 9.0) * head + 0.65 * (1.0 - head);
	float across = 1.0 - abs(uv2.y * 2.0 - 1.0);
	ALBEDO = color * gain * tail * (0.4 + 0.6 * across);
}
"""

var _p := {}
var _sun := Vector3(0, 0, 1)
var _earth: Node3D
var _earth_mats: Array = []
var _mars: Node3D
var _mars_mats: Array = []
var _moms := {}
var _flames := {}
var _loops: Array = []
var _loop_mats: Array = []
var _escape_mat: ShaderMaterial
var _club := {}
var _club_trails := {}
var _nozomi: Node3D
var _grunt: Node3D
var _grunt_fire: MeshInstance3D
var _grunt_fire_mat: ShaderMaterial
var _maven: Node3D
var _carpet_mat: ShaderMaterial
var _tags := {}
var _ghost: Node3D
var _ghost_mat: ShaderMaterial
var _arc_mats: Array = []
var _arc_fail: Array = []
var _arc_flash: Array = []
var _pulse: MeshInstance3D
var _pulse_mat: ShaderMaterial
var _orbit_m_mat: ShaderMaterial
var _dish_light := {}
var _d_earth: Node3D
var _d_mars: Node3D
var _counter: Label3D
var _counter_sub: Label3D


func validate(g: Dictionary) -> Array:
	var e := []
	var known := ["sun", "club", "nozomi", "china", "arcs", "loops", "tmi", "escape", "cruise", "maven", "tags", "test",
		"moi", "ghost", "pulse", "reply", "years"]
	for k in g.get("params", {}):
		if not (k in known):
			e.append("space: unknown param '%s'" % k)
	return e


func build(g: Dictionary) -> Node3D:
	var ms := mom_script()
	FOIL_SHADER = ms.get_script_constant_map()["FOIL_SHADER"]
	CELL_SHADER = ms.get_script_constant_map()["CELL_SHADER"]
	FLAME_SHADER = ms.get_script_constant_map()["FLAME_SHADER"]
	_p = g.get("params", {})
	var s: Array = _p.get("sun", [10, 60])
	var b := Basis.from_euler(Vector3(deg_to_rad(-float(s[0])), deg_to_rad(float(s[1])), 0))
	_sun = -(b * Vector3.FORWARD)
	var root := Node3D.new()
	_build_earth(root)
	_build_mars(root)
	_build_moms(root)
	_build_loops(root)
	_build_club(root)
	_build_failures(root)
	_build_maven(root)
	_build_tags(root)
	_build_ghost(root)
	_build_diagram(root)
	return root


# --- planets -----------------------------------------------------------------------

func _planet_mesh(r: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 192
	m.rings = 96
	return m


func _earth_at(root: Node3D, at: Vector3, r: float) -> Node3D:
	var n := Node3D.new()
	n.position = at
	root.add_child(n)
	var body := MeshInstance3D.new()
	body.mesh = _planet_mesh(r)
	var em := Kit.shader(EARTH_SHADER)
	em.set_shader_parameter("day", Kit.texture(TEX + "8k_earth_daymap.jpg"))
	em.set_shader_parameter("night", Kit.texture(TEX + "8k_earth_nightmap.jpg"))
	em.set_shader_parameter("spec", Kit.texture(TEX + "8k_earth_specular_map_4k.png", true))
	em.set_shader_parameter("nmap", Kit.texture(TEX + "8k_earth_normal_map_4k.png", true))
	em.set_shader_parameter("sun_dir", _sun)
	body.material_override = em
	n.add_child(body)
	var cl := MeshInstance3D.new()
	cl.mesh = _planet_mesh(r * 1.006)
	var cm := Kit.shader(CLOUD_SHADER)
	cm.set_shader_parameter("clouds", Kit.texture(TEX + "8k_earth_clouds.jpg", true))
	cl.material_override = cm
	cl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(cl)
	var at_m := MeshInstance3D.new()
	at_m.mesh = _planet_mesh(r * 1.035)
	var am := Kit.shader(ATMO_SHADER)
	am.set_shader_parameter("sun_dir", _sun)
	at_m.material_override = am
	at_m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(at_m)
	_earth_mats.append([em, cm])
	return n


func _mars_at(root: Node3D, at: Vector3, r: float) -> Node3D:
	var n := Node3D.new()
	n.position = at
	root.add_child(n)
	var body := MeshInstance3D.new()
	body.mesh = _planet_mesh(r)
	var mm := Kit.shader(MARS_SHADER)
	mm.set_shader_parameter("albedo", Kit.texture(TEX + "8k_mars.jpg"))
	body.material_override = mm
	n.add_child(body)
	var haze := MeshInstance3D.new()
	haze.mesh = _planet_mesh(r * 1.02)
	var hm := Kit.shader(ATMO_SHADER)
	hm.set_shader_parameter("sun_dir", _sun)
	hm.set_shader_parameter("tint", Color(0.95, 0.62, 0.42))
	hm.set_shader_parameter("dusk", Color(0.4, 0.55, 0.9))
	hm.set_shader_parameter("power", 3.5)
	hm.set_shader_parameter("gain", 0.9)
	haze.material_override = hm
	haze.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(haze)
	_mars_mats.append(mm)
	return n


func _build_earth(root: Node3D) -> void:
	_earth = _earth_at(root, Vector3.ZERO, RE)
	_earth.rotation = Vector3(deg_to_rad(-23.4), 0, 0)


func _build_mars(root: Node3D) -> void:
	_mars = _mars_at(root, M_AT, RM)
	_mars.rotation = Vector3(deg_to_rad(-25.2), 0, 0)


# --- spacecraft ----------------------------------------------------------------------

## Turn the solar wing about its boom so the cells face the sun.
func _aim_wing(m: Node3D) -> void:
	var wing := m.get_node_or_null("wing") as Node3D
	if wing == null:
		return
	var sl := m.basis.inverse() * _sun
	wing.rotation = Vector3(atan2(sl.z, sl.y), 0, 0)


## Set an engine's burn (0..1) and plume length (m).
func _burn(m: Node3D, power: float, length: float, t: float) -> void:
	_aim_wing(m)
	var eng := m.get_node("engine")
	var flame := eng.get_node("flame") as MeshInstance3D
	var fmat := flame.material_override as ShaderMaterial
	fmat.set_shader_parameter("power", power)
	fmat.set_shader_parameter("flick", t)
	flame.visible = power > 0.001
	flame.scale = Vector3(0.45 + 0.25 * power, length, 0.45 + 0.25 * power)
	flame.position = Vector3(0, -0.45 - length * 0.5, 0)
	var fl := eng.get_node("flame_light") as OmniLight3D
	fl.light_energy = 0.7 * power
	var glow := eng.get_node("bell_glow") as MeshInstance3D
	glow.material_override = Kit.lit("#ff5a14", snappedf(3.0 * power, 0.05))


func _build_moms(root: Node3D) -> void:
	for id in ["mom_e", "mom_m", "mom_c", "mom_r"]:
		var m := _mom(1.0)
		m.name = id
		root.add_child(m)
		_moms[id] = m


## A simple flag (rectangular decal) on a spacecraft: "us", "ussr", "eu", "jp", "cn".
func _flag(parent: Node3D, kind: String, size: Vector2, pos: Vector3, rot: Vector3) -> void:
	var f := Node3D.new()
	f.position = pos
	f.rotation = rot
	parent.add_child(f)
	var w := size.x
	var h := size.y
	match kind:
		"us":
			for i in 13:
				Kit.quad(f, Vector2(w, h / 13.0), Vector3(0, h * 0.5 - h / 13.0 * (i + 0.5), 0), Kit.mat("#b22234" if i % 2 == 0 else "#f4f4f4", 0.7))
			Kit.quad(f, Vector2(w * 0.4, h * 7.0 / 13.0), Vector3(-w * 0.3, h * 0.5 - h * 3.5 / 13.0, 0.002), Kit.mat("#3c3b6e", 0.7))
			for i in 5:
				for j in 4:
					Kit.ball(f, h * 0.018, Vector3(-w * 0.47 + w * 0.08 * i, h * 0.45 - h * 0.1 * j, 0.004), Kit.mat("#ffffff", 0.6), 6)
		"ussr":
			Kit.quad(f, size, Vector3.ZERO, Kit.mat("#cc0000", 0.7))
			Kit.quad(f, Vector2(w, h) * 0.14, Vector3(-w * 0.32, h * 0.28, 0.002), Kit.mat("#ffd700", 0.6))
		"eu":
			Kit.quad(f, size, Vector3.ZERO, Kit.mat("#003399", 0.7))
			for i in 12:
				var a := TAU * float(i) / 12.0
				Kit.ball(f, h * 0.05, Vector3(cos(a), sin(a), 0) * h * 0.33 + Vector3(0, 0, 0.003), Kit.mat("#ffcc00", 0.5), 8)
		"jp":
			Kit.quad(f, size, Vector3.ZERO, Kit.mat("#f6f6f6", 0.7))
			Kit.cyl(f, h * 0.3, h * 0.3, 0.004, Vector3(0, 0, 0.003), Kit.mat("#bc002d", 0.6), 32, Vector3(PI / 2, 0, 0))
		"cn":
			Kit.quad(f, size, Vector3.ZERO, Kit.mat("#de2910", 0.7))
			Kit.ball(f, h * 0.12, Vector3(-w * 0.33, h * 0.22, 0.003), Kit.mat("#ffde00", 0.5), 8, Vector3(1, 1, 0.1))
			for i in 4:
				var a := -0.9 + 0.6 * float(i)
				Kit.ball(f, h * 0.045, Vector3(-w * 0.15 + cos(a) * w * 0.06, h * 0.22 + sin(a) * h * 0.25, 0.003), Kit.mat("#ffde00", 0.5), 6, Vector3(1, 1, 0.1))


## Mariner 9 (US, 1971): an octagonal bus, four solar panels in a cross, a dish on top.
func _mariner(k: float) -> Node3D:
	var n := Node3D.new()
	var bus := Kit.cyl(n, 0.7 * k, 0.7 * k, 0.45 * k, Vector3.ZERO, Kit.mat("#d8c79c", 0.4, 0.0, 0.8), 8)
	var cells := Kit.shader(CELL_SHADER)
	for i in 4:
		var a := TAU * float(i) / 4.0 + PI / 4.0
		var pnl := Kit.quad(n, Vector2(2.1, 0.9) * k, Vector3(cos(a), 0, sin(a)) * 1.85 * k, cells, Vector3(-PI / 2, -a, 0))
		pnl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var dish := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.55 * k
	sm.height = 0.28 * k
	sm.is_hemisphere = true
	dish.mesh = sm
	dish.material_override = Kit.mat("#efeee8", 0.5)
	dish.rotation = Vector3(PI, 0, 0)
	dish.position = Vector3(0, 0.62, 0) * k
	n.add_child(dish)
	Kit.cyl(n, 0.12 * k, 0.12 * k, 0.4 * k, Vector3(0, -0.4, 0) * k, Kit.mat("#2a2622", 0.4), 12)
	_flag(n, "us", Vector2(0.62, 0.34) * k, Vector3(0, 0, 0.72) * k, Vector3.ZERO)
	return n


## Mars 3 (USSR, 1971): a tall cylindrical tank with two big panels and a dish.
func _mars3(k: float) -> Node3D:
	var n := Node3D.new()
	Kit.cyl(n, 0.6 * k, 0.6 * k, 1.8 * k, Vector3.ZERO, Kit.mat("#8f9790", 0.35, 0.0, 0.8), 24)
	Kit.ball(n, 0.6 * k, Vector3(0, 0.9, 0) * k, Kit.mat("#8f9790", 0.35, 0.0, 0.8), 24, Vector3(1, 0.5, 1))
	var cells := Kit.shader(CELL_SHADER)
	for s in [-1.0, 1.0]:
		Kit.quad(n, Vector2(2.3, 1.2) * k, Vector3(s * 1.85, 0.2, 0) * k, cells, Vector3(0, 0, 0))
		Kit.quad(n, Vector2(2.3, 1.2) * k, Vector3(s * 1.85, 0.2, -0.01) * k, Kit.mat("#3a3d44", 0.7), Vector3(0, PI, 0))
	var dish := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.8 * k
	sm.height = 0.4 * k
	sm.is_hemisphere = true
	dish.mesh = sm
	dish.material_override = Kit.mat("#e6e4dd", 0.5)
	dish.rotation = Vector3(PI * 0.75, 0, 0)
	dish.position = Vector3(0, 0.5, 0.75) * k
	n.add_child(dish)
	_flag(n, "ussr", Vector2(0.6, 0.4) * k, Vector3(0, -0.3, 0.61) * k, Vector3.ZERO)
	return n


## Mars Express (ESA, 2003): a gold box with two long panel wings and a dish.
func _mex(k: float) -> Node3D:
	var n := Node3D.new()
	Kit.slab(n, Vector3(1.5, 1.4, 1.8) * k, 0.05 * k, Vector3.ZERO, Kit.shader(FOIL_SHADER))
	var cells := Kit.shader(CELL_SHADER)
	for s in [-1.0, 1.0]:
		for i in 2:
			Kit.quad(n, Vector2(2.0, 1.6) * k, Vector3(s * (1.9 + 2.05 * i), 0, 0) * k, cells, Vector3(-PI / 2, 0, 0))
	var dish := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.8 * k
	sm.height = 0.35 * k
	sm.is_hemisphere = true
	dish.mesh = sm
	dish.material_override = Kit.mat("#efeee8", 0.5)
	dish.rotation = Vector3(PI / 2, 0, 0)
	dish.position = Vector3(0, 0, -1.05) * k
	n.add_child(dish)
	_flag(n, "eu", Vector2(0.6, 0.4) * k, Vector3(0, 0, 0.92) * k, Vector3.ZERO)
	return n


## Nozomi (Japan, 1998): a small octagonal box, a dish and a long boom.
func _nozomi_craft(k: float) -> Node3D:
	var n := Node3D.new()
	Kit.cyl(n, 0.65 * k, 0.65 * k, 0.6 * k, Vector3.ZERO, Kit.shader(FOIL_SHADER), 8)
	var cells := Kit.shader(CELL_SHADER)
	for s in [-1.0, 1.0]:
		Kit.quad(n, Vector2(1.3, 0.8) * k, Vector3(s * 1.3, 0, 0) * k, cells, Vector3(-PI / 2, 0, 0))
	var dish := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.8 * k
	sm.height = 0.3 * k
	sm.is_hemisphere = true
	dish.mesh = sm
	dish.material_override = Kit.mat("#efeee8", 0.5)
	dish.rotation = Vector3(PI, 0, 0)
	dish.position = Vector3(0, 0.6, 0) * k
	n.add_child(dish)
	Kit.rod(n, Vector3(0, -0.3, 0) * k, Vector3(0, -3.0, 0.4) * k, 0.02 * k, Kit.mat("#c9ccd2", 0.3), 6)
	_flag(n, "jp", Vector2(0.5, 0.34) * k, Vector3(0, 0, 0.66) * k, Vector3.ZERO)
	return n


## Phobos-Grunt (Russia, 2011) carrying Yinghuo-1 (China): a ring of spherical tanks under a
## lander frame, with China's small orbiter box on top.
func _grunt_craft(k: float) -> Node3D:
	var n := Node3D.new()
	var grey := Kit.mat("#a3a6a0", 0.4, 0.0, 0.8)
	var foil := Kit.shader(FOIL_SHADER)
	for i in 6:
		var a := TAU * float(i) / 6.0
		Kit.ball(n, 0.55 * k, Vector3(cos(a), 0, sin(a)) * 1.0 * k, grey, 20)
	Kit.cyl(n, 1.1 * k, 1.1 * k, 0.5 * k, Vector3(0, 0.55, 0) * k, foil, 16)
	Kit.cyl(n, 0.7 * k, 0.9 * k, 0.6 * k, Vector3(0, 1.1, 0) * k, Kit.mat("#ece9e1", 0.6), 16)
	var cells := Kit.shader(CELL_SHADER)
	for s in [-1.0, 1.0]:
		Kit.quad(n, Vector2(2.0, 1.0) * k, Vector3(s * 2.1, 0.6, 0) * k, cells, Vector3(-PI / 2, 0, 0))
	var yh := Node3D.new()
	yh.position = Vector3(0, 1.65, 0) * k
	n.add_child(yh)
	Kit.slab(yh, Vector3(0.75, 0.6, 0.75) * k, 0.03 * k, Vector3.ZERO, foil)
	for s in [-1.0, 1.0]:
		Kit.quad(yh, Vector2(0.9, 0.5) * k, Vector3(s * 0.85, 0, 0) * k, cells, Vector3(-PI / 2, 0, 0))
	_flag(yh, "cn", Vector2(0.42, 0.28) * k, Vector3(0, 0, 0.39) * k, Vector3.ZERO)
	var fire := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	fire.mesh = sm
	_grunt_fire_mat = Kit.shader(FLAME_SHADER)
	_grunt_fire_mat.set_shader_parameter("edge", Color(1.0, 0.35, 0.08))
	fire.material_override = _grunt_fire_mat
	fire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(fire)
	_grunt_fire = fire
	return n


func _build_club(root: Node3D) -> void:
	var makers := {"us": _mariner(4.0), "ussr": _mars3(4.0), "eu": _mex(4.0)}
	for k in makers:
		var c: Node3D = makers[k]
		root.add_child(c)
		_club[k] = c
		var trail := _tube_ellipse(1.0, 1.0, 0.0, 160, 0.004)
		var tm := Kit.shader(TRAIL_SHADER)
		tm.set_shader_parameter("color", {"us": Color(0.6, 0.75, 1.0), "ussr": Color(1.0, 0.45, 0.35), "eu": Color(0.55, 0.65, 1.0)}[k])
		tm.set_shader_parameter("gain", 0.9)
		trail.material_override = tm
		root.add_child(trail)
		_club_trails[k] = [trail, tm]


func _build_failures(root: Node3D) -> void:
	_nozomi = _nozomi_craft(3.0)
	root.add_child(_nozomi)
	_grunt = _grunt_craft(2.5)
	root.add_child(_grunt)


func _build_maven(root: Node3D) -> void:
	var m := Kit.model("incoming/nasa_models/Maven.glb")
	var holder := Node3D.new()
	holder.add_child(m)
	var bb := Kit.bounds(m)
	var span := maxf(bb.size.x, maxf(bb.size.y, bb.size.z))
	var k := 11.4 / maxf(span, 0.001)
	m.scale = Vector3.ONE * k
	m.position = -bb.get_center() * k
	root.add_child(holder)
	_maven = holder
	var carpet := _tube_curve(func(u: float) -> Vector3: return _maven_path(u), 120, 0.22)
	_carpet_mat = Kit.shader(TRAIL_SHADER)
	_carpet_mat.set_shader_parameter("color", Color(1.0, 0.55, 0.3))
	_carpet_mat.set_shader_parameter("gain", 0.8)
	carpet.material_override = _carpet_mat
	root.add_child(carpet)


## Price tags: a manila card on a string, with its printed price.
func _tag(root: Node3D, price: String, sub: String) -> Node3D:
	var n := Node3D.new()
	root.add_child(n)
	var card := Node3D.new()
	card.name = "card"
	n.add_child(card)
	var w := 4.8
	var h := 1.7
	Kit.slab(card, Vector3(w, 0.03, h), 0.12, Vector3.ZERO, Kit.mat("#e9d9b0", 0.85), Vector3(PI / 2, 0, 0))
	Kit.cyl(card, 0.09, 0.09, 0.05, Vector3(-w * 0.44, h * 0.32, 0), Kit.mat("#b8a77d", 0.6), 16, Vector3(PI / 2, 0, 0))
	Kit.text(card, price, 0.56, Color("1c1a17"), Vector3(0.22, 0.14, 0.03))
	Kit.text(card, sub, 0.24, Color("4a4237"), Vector3(0.22, -0.42, 0.03), Vector3.ZERO, false)
	var string := Kit.rod(n, Vector3(-w * 0.44, h * 0.32, 0), Vector3(-w * 0.44, h * 0.32 + 12.0, 0), 0.012, Kit.mat("#d9d2c0", 0.8), 6)
	string.name = "string"
	return n


func _build_tags(root: Node3D) -> void:
	_tags["maven"] = _tag(root, "$671 MILLION", "NASA · MAVEN")
	_tags["mom"] = _tag(root, "$74 MILLION", "ISRO · MOM")


func _build_ghost(root: Node3D) -> void:
	_ghost = _mom(1.0)
	root.add_child(_ghost)
	for mi in _ghost.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).transparency = 0.45
	var path := _tube_curve(func(u: float) -> Vector3: return _ghost_path(u), 140, 0.18)
	_ghost_mat = Kit.shader(TRAIL_SHADER)
	_ghost_mat.set_shader_parameter("color", Color(0.75, 0.8, 0.9))
	_ghost_mat.set_shader_parameter("gain", 0.9)
	path.material_override = _ghost_mat
	root.add_child(path)
	var orbit := _tube_ellipse(RM * 1.9, RM * 1.25, 0.0, 200, 0.08)
	orbit.position = M_AT
	orbit.rotation = Vector3(deg_to_rad(12), deg_to_rad(-35), 0)
	_orbit_m_mat = Kit.shader(TRAIL_SHADER)
	_orbit_m_mat.set_shader_parameter("color", Color(1.0, 0.78, 0.35))
	_orbit_m_mat.set_shader_parameter("gain", 0.8)
	_orbit_m_mat.set_shader_parameter("head", 0.0)
	orbit.material_override = _orbit_m_mat
	root.add_child(orbit)


func _build_loops(root: Node3D) -> void:
	for i in APOGEES.size():
		var rp := PERIGEE * RE
		var ra := float(APOGEES[i]) * RE
		var tube := _tube_kepler(rp, ra, 220, 0.35 + 0.05 * i)
		tube.rotation = ORBIT_TILT
		var tm := Kit.shader(TRAIL_SHADER)
		tm.set_shader_parameter("color", Color(1.0, 0.72, 0.3).lerp(Color(1.0, 0.9, 0.6), float(i) / 6.0))
		tm.set_shader_parameter("gain", 0.9)
		tube.material_override = tm
		root.add_child(tube)
		_loops.append(tube)
		_loop_mats.append(tm)
	var esc := _tube_curve(func(u: float) -> Vector3: return _escape_path(u), 200, 0.55)
	_escape_mat = Kit.shader(TRAIL_SHADER)
	_escape_mat.set_shader_parameter("color", Color(1.0, 0.85, 0.5))
	_escape_mat.set_shader_parameter("gain", 1.2)
	esc.material_override = _escape_mat
	root.add_child(esc)


func _build_diagram(root: Node3D) -> void:
	_d_earth = _earth_at(root, D_AT + Vector3(0, -55, 0), 7.0)
	_d_mars = _mars_at(root, D_AT + Vector3(0, 55, 0), 4.5)
	var r := Kit.rng("arcs")
	for i in 51:
		var fail := i in FAILS
		var side := -1.0 if i % 2 == 0 else 1.0
		var bend := side * (6.0 + r.randf() * 26.0)
		var depth := (r.randf() - 0.5) * 30.0
		var stop := 1.0 if not fail else 0.35 + r.randf() * 0.62
		var curve := func(u: float) -> Vector3:
			var a := D_AT + Vector3(0, -48, 0)
			var b := D_AT + Vector3(0, 50.5, 0)
			return a.lerp(b, u) + Vector3(sin(u * PI) * bend, 0, sin(u * PI) * depth)
		var tube := _tube_curve(curve, 60, 0.7)
		var tm := Kit.shader(TRAIL_SHADER)
		tm.set_shader_parameter("color", Color(0.55, 0.85, 1.0))
		tm.set_shader_parameter("gain", 1.1)
		tube.material_override = tm
		root.add_child(tube)
		_arc_mats.append(tm)
		_arc_fail.append(stop)
		var fl := Kit.ball(root, 1.0, curve.call(stop), Kit.flat(Color(1.0, 0.3, 0.2), true), 12)
		fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_arc_flash.append(fl)
	_pulse = Kit.ball(root, 1.6, D_AT, Kit.flat(Color(1.0, 0.95, 0.7), true), 16)
	_pulse.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var line := _tube_curve(func(u: float) -> Vector3: return D_AT + Vector3(0, 50.5 - 101.0 * u, 0), 40, 0.12)
	_pulse_mat = Kit.shader(TRAIL_SHADER)
	_pulse_mat.set_shader_parameter("color", Color(1.0, 0.9, 0.6))
	_pulse_mat.set_shader_parameter("gain", 0.9)
	line.material_override = _pulse_mat
	root.add_child(line)
	_counter = Kit.text(root, "", 9.0, Color(1, 1, 1), D_AT + Vector3(0, 8, 14), Vector3.ZERO, true, 1.6, Color(0, 0, 0, 0.6))
	_counter_sub = Kit.text(root, "", 3.2, Color(0.85, 0.9, 1.0), D_AT + Vector3(0, 0, 14), Vector3.ZERO, true, 1.3, Color(0, 0, 0, 0.6))


## Which of the 51 arcs fail (30 of 51, spread evenly so the red stays mixed with the blue).
const FAILS := [0, 2, 3, 5, 6, 8, 10, 11, 13, 15, 16, 18, 19, 21, 23, 24, 26, 28, 29, 31, 33, 34, 36, 38, 40, 41, 43, 45, 47, 49]


# --- tubes ----------------------------------------------------------------------------

## A tube through `n` samples of curve(u), u 0..1; UV.x = u, UV.y round the tube.
func _tube_curve(curve: Callable, n: int, r: float) -> MeshInstance3D:
	var pts := []
	for i in n + 1:
		pts.append(curve.call(float(i) / n))
	return _tube(pts, r)


func _tube_ellipse(a: float, b: float, phase: float, n: int, r: float) -> MeshInstance3D:
	var pts := []
	for i in n + 1:
		var th := phase + TAU * float(i) / n
		pts.append(Vector3(cos(th) * a, 0, sin(th) * b))
	return _tube(pts, r)


## A Kepler ellipse with Earth at the focus, sampled by true anomaly from perigee (+X).
func _tube_kepler(rp: float, ra: float, n: int, r: float) -> MeshInstance3D:
	var pts := []
	for i in n + 1:
		pts.append(_kepler_pos(rp, ra, float(i) / n, false))
	return _tube(pts, r)


func _tube(pts: Array, r: float) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 6
	var n := pts.size()
	for i in n:
		var p: Vector3 = pts[i]
		var tng: Vector3 = ((pts[mini(i + 1, n - 1)] as Vector3) - (pts[maxi(i - 1, 0)] as Vector3)).normalized()
		var ref := Vector3.UP if absf(tng.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		var x := tng.cross(ref).normalized()
		var y := tng.cross(x).normalized()
		for j in sides + 1:
			var a := TAU * float(j) / sides
			st.set_uv(Vector2(float(i) / float(n - 1), float(j) / sides))
			st.add_vertex(p + (x * cos(a) + y * sin(a)) * r)
	for i in n - 1:
		for j in sides:
			var a := i * (sides + 1) + j
			var b := a + sides + 1
			st.add_index(a); st.add_index(b); st.add_index(a + 1)
			st.add_index(a + 1); st.add_index(b); st.add_index(b + 1)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# --- paths ----------------------------------------------------------------------------

## Position on a Kepler ellipse (Earth-centred, orbit plane XZ, perigee at +X) at orbit fraction f
## (time-uniform when `timed`, so it races through perigee and crawls at apogee).
func _kepler_pos(rp: float, ra: float, f: float, timed: bool) -> Vector3:
	var a := (rp + ra) * 0.5
	var e := (ra - rp) / (ra + rp)
	var th := TAU * f
	if timed:
		var m := TAU * f
		var ea := m
		for k in 8:
			ea = ea - (ea - e * sin(ea) - m) / (1.0 - e * cos(ea))
		th = 2.0 * atan2(sqrt(1.0 + e) * sin(ea * 0.5), sqrt(1.0 - e) * cos(ea * 0.5))
	var r := a * (1.0 - e * e) / (1.0 + e * cos(th))
	return Vector3(cos(th) * r, 0, -sin(th) * r)


func _orbit_xf() -> Basis:
	return Basis.from_euler(ORBIT_TILT)


## Out of the last loop: from perigee, a hyperbola-like sweep that straightens out toward -Z.
func _escape_path(u: float) -> Vector3:
	var rp := PERIGEE * RE
	var th := u * 2.2
	var r := rp * (1.0 + 1.3) / (1.0 + 1.3 * cos(th))
	var p := Vector3(cos(th) * r, 0, -sin(th) * r)
	return _orbit_xf() * p


func _maven_path(u: float) -> Vector3:
	var a := M_AT + Vector3(260, 40, 120)
	var b := M_AT + Vector3(RM * 1.6, 8, -RM * 0.8)
	var c := M_AT + Vector3(-RM * 1.2, 2, -RM * 1.5)
	var q := a.lerp(b, u)
	var r := b.lerp(c, u)
	return q.lerp(r, u)


## The failure path: past Mars and on into the dark.
func _ghost_path(u: float) -> Vector3:
	var a := M_AT + Vector3(-60, 6, 300)
	var b := M_AT + Vector3(-RM * 1.35, 0, 0)
	var c := M_AT + Vector3(-30, -12, -420)
	var q := a.lerp(b, u)
	var r := b.lerp(c, u)
	return q.lerp(r, u)


## MOM's approach and insertion: in along +Z, the burn bends the path round behind Mars (-X side
## from the camera), out the far side into the orbit.
func _moi_path(u: float) -> Vector3:
	var a := M_AT + Vector3(70, 10, 320)
	var b := M_AT + Vector3(RM * 1.25, 4, RM * 0.3)
	var c := M_AT + Vector3(-RM * 0.2, 0, -RM * 1.4)
	var q := a.lerp(b, u)
	var r := b.lerp(c, u)
	return q.lerp(r, u)


# --- pose -------------------------------------------------------------------------------

func _w(key: String) -> Array:
	var v = _p.get(key, [])
	return v if v is Array else []


func _in(key: String, t: float, pad: float = 0.0) -> bool:
	var w := _w(key)
	if w.size() < 2:
		return false
	var hi := -INF
	for v in w:
		hi = maxf(hi, float(v))
	return t >= float(w[0]) - pad and t <= hi + pad


func _f(key: String, i: int, fallback: float = 0.0) -> float:
	var w := _w(key)
	return float(w[i]) if w.size() > i else fallback


func _look_along(n: Node3D, pos: Vector3, fwd: Vector3, up: Vector3 = Vector3.UP) -> void:
	n.position = pos
	if fwd.length() > 1e-5:
		var f := fwd.normalized()
		var u := up if absf(f.dot(up.normalized())) < 0.98 else Vector3.RIGHT
		n.basis = Basis.looking_at(f, u)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var out := {}
	# Planets turn slowly (time-lapse-ish so a held shot still lives). India faces the camera side
	# (+Z) for the TMI shot; lon shifts the texture east-west.
	for pair in _earth_mats:
		(pair[0] as ShaderMaterial).set_shader_parameter("lon", 0.484 + t * 0.0009)
		(pair[1] as ShaderMaterial).set_shader_parameter("lon", 0.47 + t * 0.0011)
	for mm in _mars_mats:
		(mm as ShaderMaterial).set_shader_parameter("lon", 0.1 + t * 0.0008)
	out["earth"] = node.global_transform * Vector3.ZERO
	out["mars"] = node.global_transform * M_AT
	_pose_club(node, t, out)
	_pose_failures(node, t, out)
	_pose_loops(node, t, out)
	_pose_cruise(node, t, out)
	_pose_mars_mom(node, t, out)
	_pose_maven(node, t, out)
	_pose_diagram(node, t, out)
	return out


func _pose_club(node: Node3D, t: float, out: Dictionary) -> void:
	var keys := ["us", "ussr", "eu"]
	var on := _in("club", t, 0.5)
	for i in 3:
		var k: String = keys[i]
		var c: Node3D = _club[k]
		var trail: MeshInstance3D = _club_trails[k][0]
		var tm: ShaderMaterial = _club_trails[k][1]
		c.visible = on
		trail.visible = on
		if not on:
			continue
		var t0 := _f("club", i)
		var age := t - t0
		var tilt := Basis.from_euler(Vector3(deg_to_rad(float([18.0, -12.0, 30.0][i])), deg_to_rad(float([0.0, 70.0, -50.0][i])), 0))
		var ra: float = RM * float([1.75, 1.95, 2.15][i])
		var rb: float = RM * float([1.4, 1.55, 1.7][i])
		# Swing in from far out along a spiral, then circle; the trail follows.
		var arrive := Motion.out_cubic(clampf(age / 1.1, 0.0, 1.0))
		var th := -1.4 + age * 0.55 + i * 2.1
		var far := lerpf(3.2, 1.0, arrive)
		var p := Vector3(cos(th) * ra * far, 0, sin(th) * rb * far)
		c.position = M_AT + tilt * p
		var vel := tilt * Vector3(-sin(th) * ra, 0, cos(th) * rb)
		_look_along(c, c.position, vel)
		c.rotate_object_local(Vector3.UP, PI / 2)
		trail.position = M_AT
		trail.basis = tilt * Basis.from_scale(Vector3(ra, (ra + rb) * 0.5, rb))
		c.visible = age > -0.05
		trail.visible = age > 0.2
		var frac := fposmod(th, TAU) / TAU
		tm.set_shader_parameter("reveal", frac)
		tm.set_shader_parameter("start", maxf(0.0, frac - clampf((age - 0.2) * 0.12, 0.0, 0.35)))
		out["club_" + k] = node.global_transform * c.position


func _pose_failures(node: Node3D, t: float, out: Dictionary) -> void:
	# Nozomi: drifts in toward Mars, misses, tumbles away into the dark.
	var on := _in("nozomi", t, 1.5)
	_nozomi.visible = on
	if true:
		var t0 := _f("nozomi", 0)
		var t1 := _f("nozomi", 1, t0 + 1.4)
		var u := clampf((t - t0) / maxf(t1 - t0, 0.01), 0.0, 1.0)
		var a := M_AT + Vector3(40, 12, 150)
		var b := M_AT + Vector3(RM * 1.6, 6, 0)
		var c := M_AT + Vector3(90, -8, -200)
		var p := a.lerp(b, u).lerp(b.lerp(c, u), u)
		_nozomi.position = p
		var tumble := Motion.in_cubic(clampf((u - 0.45) / 0.55, 0.0, 1.0))
		_nozomi.rotation = Vector3(0.3 + tumble * 5.0, 0.6 + u * 0.4 + tumble * 3.0, tumble * 2.0)
		out["nozomi"] = node.global_transform * p
	# Phobos-Grunt: stuck in a low orbit, it sinks, glows and burns up over Earth.
	on = _in("china", t, 0.3)
	_grunt.visible = on
	if true:
		var t0 := _f("china", 0)
		var t1 := _f("china", 1, t0 + 1.4)
		var u := clampf((t - t0) / maxf(t1 - t0, 0.01), 0.0, 1.0)
		var th := 0.35 + u * 0.55
		var r := RE * lerpf(1.28, 1.01, Motion.in_cubic(u))
		var gb := Basis.from_euler(Vector3(deg_to_rad(20), deg_to_rad(-50), 0))
		var p := gb * Vector3(cos(th) * r, 0, -sin(th) * r)
		var dir := gb * Vector3(-sin(th), 0, -cos(th))
		_look_along(_grunt, p, dir)
		_grunt.rotate_object_local(Vector3.RIGHT, u * 1.6)
		var heat := smoothstep(0.35, 0.8, u)
		_grunt_fire.visible = heat > 0.0
		_grunt_fire.scale = Vector3(2.4, 2.4, 6.0) * (0.6 + heat)
		_grunt_fire.position = Vector3(0, 0, 3.0 * heat)
		_grunt_fire_mat.set_shader_parameter("power", heat * 1.2)
		_grunt_fire_mat.set_shader_parameter("flick", t)
		out["grunt"] = node.global_transform * p


func _pose_loops(node: Node3D, t: float, out: Dictionary) -> void:
	var mom: Node3D = _moms["mom_e"]
	var l0 := _f("loops", 0, -100.0)
	var l1 := _f("loops", 1, l0 + 5.0)
	var tmi0 := _f("tmi", 0, l1)
	var tmi1 := _f("tmi", 1, tmi0 + 2.3)
	var e0 := _f("escape", 0, tmi1)
	var e1 := _f("escape", 1, e0 + 3.0)
	var nl := APOGEES.size()
	var per := (l1 - l0) / float(nl)
	var rp := PERIGEE * RE
	var power := 0.0
	var pos := Vector3.ZERO
	var vel := Vector3.ZERO
	# Trails: loop i is drawn as MOM flies it, then stays (dimmer) once done.
	for i in nl:
		var tm: ShaderMaterial = _loop_mats[i]
		var ti := l0 + per * i
		var frac := clampf((t - ti) / per, 0.0, 1.0)
		(_loops[i] as MeshInstance3D).visible = t > ti and t < tmi0 - 0.2
		tm.set_shader_parameter("reveal", _true_frac(rp, float(APOGEES[i]) * RE, frac))
		tm.set_shader_parameter("gain", 0.9 if frac < 1.0 else 0.4)
	if t < l1:
		var i := clampi(int(floor((t - l0) / per)), 0, nl - 1)
		var frac := clampf((t - l0 - per * i) / per, 0.0, 1.0)
		var ra := float(APOGEES[i]) * RE
		pos = _orbit_xf() * _kepler_pos(rp, ra, frac, true)
		vel = _orbit_xf() * (_kepler_pos(rp, ra, frac + 0.002, true) - _kepler_pos(rp, ra, frac, true))
		# A short burn as each loop starts (at perigee).
		var since := frac * per
		power = 1.0 - smoothstep(0.12, 0.3, since) if t > l0 else 0.0
	elif t < e0:
		# The final burn at perigee: MOM nearly still over the night side, engine blazing.
		var ra := float(APOGEES[nl - 1]) * RE
		var u := clampf((t - tmi0) / maxf(tmi1 - tmi0, 0.01), 0.0, 1.0)
		pos = _orbit_xf() * _kepler_pos(rp, ra, -0.006 + 0.012 * u, false)
		vel = _orbit_xf() * Vector3(0, 0, -1)
		power = smoothstep(0.0, 0.15, u) * (1.0 - smoothstep(0.9, 1.0, u)) if t >= tmi0 else 0.0
	else:
		var u := Motion.in_cubic(clampf((t - e0) / maxf(e1 - e0, 0.01), 0.0, 1.0))
		pos = _escape_path(u)
		vel = _escape_path(u + 0.01) - pos
		power = 0.0
	_escape_mat.set_shader_parameter("reveal", Motion.in_cubic(clampf((t - e0) / maxf(e1 - e0, 0.01), 0.0, 1.0)))
	var mom_k := 1.0
	mom.scale = Vector3.ONE * mom_k
	# Engine points backward along the burn: thrust is along the velocity, so the nozzle (-Y) trails.
	_look_along(mom, pos, vel)
	mom.rotate_object_local(Vector3.RIGHT, -PI / 2)
	_burn(mom, power, 1.6 + 0.8 * power, t)
	out["mom_e"] = node.global_transform * pos
	out["loops_center"] = node.global_transform * Vector3.ZERO


## Arc-length-ish fraction of a Kepler orbit drawn (the tube is sampled by true anomaly).
func _true_frac(rp: float, ra: float, f: float) -> float:
	if f <= 0.0:
		return 0.0
	if f >= 1.0:
		return 1.0
	var e := (ra - rp) / (ra + rp)
	var m := TAU * f
	var ea := m
	for k in 8:
		ea = ea - (ea - e * sin(ea) - m) / (1.0 - e * cos(ea))
	var th := 2.0 * atan2(sqrt(1.0 + e) * sin(ea * 0.5), sqrt(1.0 - e) * cos(ea * 0.5))
	return fposmod(th, TAU) / TAU


func _pose_cruise(node: Node3D, t: float, out: Dictionary) -> void:
	var mom: Node3D = _moms["mom_c"]
	var c0 := _f("cruise", 0, 0.0)
	var age := t - c0
	var p := C_AT + Vector3(0, 0, -age * 0.6)
	mom.position = p
	mom.basis = Basis.from_euler(Vector3(deg_to_rad(-70), deg_to_rad(20 + age * 1.5), deg_to_rad(8)))
	# The engine still warm from the last burn, cooling.
	_burn(mom, 0.0, 1.0, t)
	out["mom_c"] = node.global_transform * p


func _pose_mars_mom(node: Node3D, t: float, out: Dictionary) -> void:
	var mom: Node3D = _moms["mom_m"]
	var power := 0.0
	var plume := 3.0
	var pos := M_AT + Vector3(90, 14, 520)
	var fwd := Vector3(0, 0, -1)
	var test0 := _f("test", 0, -100.0)
	var test1 := _f("test", 1, test0 + 1.2)
	var turn := _f("moi", 0, 1e9)
	var ign := _f("moi", 1, 1e9)
	var behind := _f("moi", 2, 1e9)
	var outt := _f("moi", 3, 1e9)
	var mend := _f("moi", 4, 1e9)
	if t < turn:
		# Cruise in toward Mars; the test fire happens here.
		var u := clampf((t - (test0 - 4.0)) / 12.0, 0.0, 1.0)
		pos = M_AT + Vector3(90, 14, 520).lerp(Vector3(80, 12, 380), u)
		fwd = Vector3(-0.1, -0.02, -1).normalized()
		if t >= test0 and t < test0 + 1.8:
			var a := (t - test0) / 1.8
			power = smoothstep(0.0, 0.08, a) * (1.0 - smoothstep(0.75, 1.0, a))
	elif t < outt:
		# The insertion: turn engine-first, ignite, bend round behind Mars.
		var u := clampf((t - turn) / maxf(outt - turn, 0.01), 0.0, 1.0)
		var s := Motion.smooth(u)
		pos = _moi_path(s)
		var vel := _moi_path(minf(s + 0.01, 1.0)) - _moi_path(maxf(s - 0.01, 0.0))
		var spin := Motion.in_out(clampf((t - turn) / maxf(ign - turn, 0.01), 0.0, 1.0))
		# Engine first: before the turn the nozzle trails; after it, the nozzle leads (braking).
		fwd = vel.normalized().lerp(-vel.normalized(), spin)
		if t >= ign:
			power = smoothstep(0.0, 0.4, t - ign)
		plume = 4.5
	else:
		# In orbit: the long ellipse, engine off; for the years, MOM laps it fast.
		var y0 := _f("years", 0, 1e9)
		var y1 := _f("years", 3, y0 + 6.0)
		var laps := 0.0
		if t > y0:
			laps = Motion.in_cubic(clampf((t - y0) / maxf(y1 - y0, 0.01), 0.0, 1.0)) * 7.0
		var th := 2.2 + (t - outt) * 0.12 + laps * TAU
		var tilt := Basis.from_euler(Vector3(deg_to_rad(12), deg_to_rad(-35), 0))
		var p := Vector3(cos(th) * RM * 1.9, 0, sin(th) * RM * 1.25)
		pos = M_AT + tilt * p
		fwd = tilt * Vector3(-sin(th) * 1.9, 0, cos(th) * 1.25)
	_look_along(mom, pos, fwd)
	mom.rotate_object_local(Vector3.RIGHT, -PI / 2)
	_burn(mom, power, plume, t)
	# The orbit line appears once MOM is in orbit.
	_orbit_m_mat.set_shader_parameter("reveal", clampf((t - outt) / 1.2, 0.0, 1.0))
	_orbit_m_mat.set_shader_parameter("gain", 0.75 if t < _f("years", 0, 1e9) else 1.0)
	# The dish light blinks for the reply.
	var led := mom.get_node("hga/led") as MeshInstance3D
	var blink := 0.0
	if _in("reply", t):
		blink = 1.0 if fposmod(t - _f("reply", 0), 0.6) < 0.25 else 0.0
	led.material_override = Kit.lit("#ffe9b0", 6.0 * blink)
	out["mom_m"] = node.global_transform * pos
	# The ghost: only during its line.
	var gon := _in("ghost", t, 0.2)
	_ghost.visible = gon
	if gon:
		var u := clampf((t - _f("ghost", 0)) / maxf(_f("ghost", 1) - _f("ghost", 0), 0.01), 0.0, 1.0)
		var s := Motion.in_out(u)
		var gp := _ghost_path(s)
		_look_along(_ghost, gp, _ghost_path(minf(s + 0.01, 1.0)) - gp)
		_ghost.rotate_object_local(Vector3.RIGHT, -PI / 2)
		_ghost_mat.set_shader_parameter("reveal", s)
		out["ghost"] = node.global_transform * gp
	else:
		_ghost_mat.set_shader_parameter("reveal", 0.0)


func _pose_maven(node: Node3D, t: float, out: Dictionary) -> void:
	var m0 := _f("maven", 0, -100.0)
	var m1 := _f("maven", 1, m0 + 4.0)
	var u := Motion.out_cubic(clampf((t - m0) / maxf(m1 - m0, 0.01), 0.0, 1.0))
	var p := _maven_path(u)
	var v := _maven_path(minf(u + 0.01, 1.0)) - _maven_path(maxf(u - 0.01, 0.0))
	_look_along(_maven, p, v)
	_maven.visible = t > m0 - 0.5 and t < _f("tags", 2, m1 + 8.0) + 0.5
	_carpet_mat.set_shader_parameter("reveal", u)
	out["maven"] = node.global_transform * p
	# Price tags: each drops on its string, overshoots, swings; MAVEN's above MAVEN, MOM's above MOM.
	var tg := _w("tags")
	for key in ["maven"]:
		var tag: Node3D = _tags[key]
		var on := tg.size() >= 3 and t > float(tg[0]) - 0.2 and t < float(tg[2]) + 0.5
		tag.visible = on
		if not on:
			continue
		var t0 := float(tg[0])
		var hang := p + Vector3(0, 7.5, 0)
		var drop := Motion.out_back(clampf((t - t0) / 0.45, 0.0, 1.0), 1.4)
		var swing := 0.15 * Motion.wobble(maxf(t - t0 - 0.35, 0.0), 2.2, 2.5) if t > t0 + 0.35 else 0.0
		tag.position = hang + Vector3(0, (1.0 - drop) * 14.0, 0)
		tag.rotation = Vector3(0, 0, swing)
		tag.visible = t > t0 - 0.05
		out["tag_" + key] = node.global_transform * hang
	# MOM for the price-tag shot: a second, posed MOM below MAVEN.
	var mr: Node3D = _moms["mom_r"]
	var mp := p + Vector3(-1.5, -10.0, 4.0)
	mr.visible = tg.size() >= 3 and t > float(tg[0]) - 0.5 and t < float(tg[2]) + 0.5
	mr.position = mp
	mr.rotation = Vector3(deg_to_rad(-20), deg_to_rad(35 + t * 4.0), deg_to_rad(10))
	_burn(mr, 0.0, 1.0, t)
	out["mom_r"] = node.global_transform * mp
	if tg.size() >= 3:
		var tag2: Node3D = _tags["mom"]
		var t0 := float(tg[1])
		var hang := mp + Vector3(0, 3.6, 0)
		var drop := Motion.out_back(clampf((t - t0) / 0.45, 0.0, 1.0), 1.4)
		var swing := 0.15 * Motion.wobble(maxf(t - t0 - 0.35, 0.0), 2.2, 2.5) if t > t0 + 0.35 else 0.0
		tag2.position = hang + Vector3(0, (1.0 - drop) * 12.0, 0)
		tag2.rotation = Vector3(0, 0, swing)
		tag2.visible = mr.visible and t > t0 - 0.05
		out["tag_mom"] = node.global_transform * hang


func _pose_diagram(node: Node3D, t: float, out: Dictionary) -> void:
	out["diagram_earth"] = node.global_transform * (D_AT + Vector3(0, -55, 0))
	out["diagram_mars"] = node.global_transform * (D_AT + Vector3(0, 55, 0))
	out["diagram"] = node.global_transform * D_AT
	var a0 := _f("arcs", 0, 1e9)
	var a1 := _f("arcs", 1, a0 + 2.5)
	var ac := _f("arcs", 2, a1)
	var arcs_on := _in("arcs", t, 0.3)
	var drawn := 0
	var good := 0
	for i in 51:
		var tm: ShaderMaterial = _arc_mats[i]
		var ti := a0 + (a1 - a0) * float(i) / 51.0
		var u := clampf((t - ti) / 0.5, 0.0, 1.0)
		var stop: float = _arc_fail[i]
		var fail := stop < 1.0
		tm.set_shader_parameter("reveal", minf(u, stop) if arcs_on else 0.0)
		tm.set_shader_parameter("color", Color(1.0, 0.32, 0.25) if fail and u >= stop else Color(0.55, 0.85, 1.0))
		var fl: MeshInstance3D = _arc_flash[i]
		var since := t - (ti + 0.5 * stop)
		fl.visible = arcs_on and fail and since > 0.0 and since < 0.6
		fl.scale = Vector3.ONE * (0.6 + 2.2 * Motion.out_cubic(clampf(since / 0.25, 0.0, 1.0))) * (1.0 - clampf((since - 0.25) / 0.35, 0.0, 1.0))
		if u > 0.0 and arcs_on:
			drawn += 1
			if not fail and u >= 1.0:
				good += 1
	_counter.visible = arcs_on and t > a0 + 0.3
	_counter_sub.visible = _counter.visible
	_counter.text = "%d / %d" % [good, maxi(drawn, 1)]
	_counter_sub.text = "MISSIONS TO MARS THAT SUCCEEDED"
	if t >= ac:
		_counter.text = "21 / 51"
	# The radio pulse: from Mars down to Earth.
	var pon := _in("pulse", t, 0.2)
	_pulse.visible = pon
	if pon:
		var u := clampf((t - _f("pulse", 0)) / maxf(_f("pulse", 1) - _f("pulse", 0), 0.01), 0.0, 1.0)
		_pulse.position = D_AT + Vector3(0, 50.5 - 101.0 * u, 0)
		_pulse_mat.set_shader_parameter("reveal", u)
		out["pulse"] = node.global_transform * _pulse.position
	else:
		_pulse_mat.set_shader_parameter("reveal", 0.0)
