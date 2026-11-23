## library:earth — the Earth from space: Solar System Scope's 8k day map (CC BY 4.0, credit "Planet textures: Solar
## System Scope (solarsystemscope.com), CC BY 4.0"), city lights on the night side, a cloud layer, an atmosphere rim
## with a dusk band along the terminator, lit by the look's sun.
##
##   {"id": "earth", "script": "library:earth", "t": 0, "at": <point>,
##    "params": {"radius": 6371, "altitude": 600, "up": [27.1, 71.7], "heading": 0, "sun": [elev, az],
##               "clouds": 0.85, "spin": 0.0, "day_gain": 1.0}}
##
## The place `up` = [latitude, longitude] (degrees) sits straight below the gag's origin at `altitude` metres
## (gag-local -Y), north toward gag-local -Z turned by `heading` degrees: a satellite at the origin looks down on it.
## `sun` = the look's sun [elevation, azimuth] (must match, so the terminator and the lighting agree). `spin`:
## degrees per second of slow drift (the ground moving under an orbit). Units are metres; keep the camera's `far`
## beyond the horizon (sqrt(2 R h)). Anchors: "<id>.target" (the `up` point on the ground), "<id>.centre".
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Look = preload("res://scripts/look/look.gd")
const TEX := "incoming/sss_textures/"

const EARTH := """
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;
uniform sampler2D day : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D night : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D spec : filter_linear_mipmap, repeat_enable;
uniform sampler2D nmap : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
uniform float night_gain = 2.6;
uniform float day_gain = 1.0;
varying vec3 wn;
varying vec3 on;
void vertex() {
	on = normalize(VERTEX);
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	float lo = atan(on.x, on.z);
	float la = asin(clamp(on.y, -1.0, 1.0));
	vec2 uv = vec2(fract(0.5 + lo / 6.2831853), 0.5 - la / 3.14159265);
	vec3 c = texture(day, uv).rgb;
	float s = texture(spec, uv).r;
	ALBEDO = c * mix(1.05, 0.8, s) * day_gain;
	ROUGHNESS = mix(0.85, 0.28, s);
	SPECULAR = mix(0.2, 0.75, s);
	NORMAL_MAP = texture(nmap, uv).rgb;
	NORMAL_MAP_DEPTH = 0.8;
	float lit = dot(normalize(wn), normalize(sun_dir));
	float dark = smoothstep(0.08, -0.12, lit);
	vec3 nl = texture(night, uv).rgb;
	EMISSION = nl * nl * vec3(1.0, 0.78, 0.45) * night_gain * dark * 3.0 + c * vec3(0.5, 0.6, 0.9) * 0.035 * dark;
}
"""

const CLOUDS := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_lambert;
uniform sampler2D clouds : filter_linear_mipmap_anisotropic, repeat_enable;
uniform float amount = 0.85;
varying vec3 on;
void vertex() { on = normalize(VERTEX); }
void fragment() {
	float lo = atan(on.x, on.z);
	float la = asin(clamp(on.y, -1.0, 1.0));
	vec2 uv = vec2(fract(0.5 + lo / 6.2831853), 0.5 - la / 3.14159265);
	float a = texture(clouds, uv).r;
	ALBEDO = vec3(0.97);
	ALPHA = smoothstep(0.08, 0.85, a) * amount;
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}
"""

const ATMO := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 tint : source_color = vec3(0.35, 0.6, 1.0);
uniform vec3 dusk : source_color = vec3(1.0, 0.5, 0.25);
uniform float power = 2.4;
uniform float gain = 1.8;
varying vec3 wn;
void vertex() { wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }
void fragment() {
	float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float l = dot(normalize(wn), normalize(sun_dir));
	float day = smoothstep(-0.25, 0.35, l);
	float band = exp(-pow(l / 0.18, 2.0));
	ALBEDO = (tint * day + dusk * band * 0.6) * pow(rim, power) * gain;
}
"""

var _globe: Node3D
var _basis0 := Basis.IDENTITY
var _r := 6371.0
var _alt := 600.0


func validate(g: Dictionary) -> Array:
	var e := []
	for k in g.get("params", {}):
		if not (k in ["radius", "altitude", "up", "heading", "sun", "clouds", "spin", "night_gain", "day_gain"]):
			e.append("earth: unknown param '%s'" % k)
	return e


func build(g: Dictionary) -> Node3D:
	var p: Dictionary = g.get("params", {})
	_r = float(p.get("radius", 6371.0))
	_alt = float(p.get("altitude", 600.0))
	var up: Array = p.get("up", [0.0, 0.0])
	var la := deg_to_rad(float(up[0]))
	var lo := deg_to_rad(float(up[1]))
	# Texture frame: a point at (lat, lon) is (sin lon cos lat, sin lat, cos lon cos lat) on the unit sphere.
	var dir := Vector3(sin(lo) * cos(la), sin(la), cos(lo) * cos(la))
	var north := Vector3(-sin(lo) * sin(la), cos(la), -cos(lo) * sin(la))
	var east := north.cross(dir).normalized()
	# Turn the globe so `dir` points up (+Y), north toward -Z, east toward +X, then by `heading` about +Y.
	var m := Basis(east, dir, -north)
	_basis0 = Basis(Vector3.UP, deg_to_rad(float(p.get("heading", 0.0)))) * m.transposed()
	var root := Node3D.new()
	_globe = Node3D.new()
	_globe.name = "globe"
	_globe.position = Vector3(0, -_r - _alt, 0)
	_globe.basis = _basis0
	root.add_child(_globe)
	var sun := Look.sky_dir(float((p.get("sun", [45.0, 0.0]) as Array)[0]), float((p.get("sun", [45.0, 0.0]) as Array)[1]))
	var sm := SphereMesh.new()
	sm.radius = _r
	sm.height = _r * 2.0
	sm.radial_segments = 512
	sm.rings = 256
	var body := MeshInstance3D.new()
	body.mesh = sm
	var em := Kit.shader(EARTH)
	em.set_shader_parameter("day", Kit.texture(TEX + "8k_earth_daymap.jpg"))
	em.set_shader_parameter("night", Kit.texture(TEX + "8k_earth_nightmap.jpg"))
	em.set_shader_parameter("spec", Kit.texture(TEX + "8k_earth_specular_map_4k.png", true))
	em.set_shader_parameter("nmap", Kit.texture(TEX + "8k_earth_normal_map_4k.png", true))
	em.set_shader_parameter("sun_dir", sun)
	em.set_shader_parameter("night_gain", float(p.get("night_gain", 2.6)))
	em.set_shader_parameter("day_gain", float(p.get("day_gain", 1.0)))
	body.material_override = em
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_globe.add_child(body)
	var cs := SphereMesh.new()
	cs.radius = _r * 1.0012
	cs.height = _r * 2.0024
	cs.radial_segments = 512
	cs.rings = 256
	var cl := MeshInstance3D.new()
	cl.mesh = cs
	var cm := Kit.shader(CLOUDS)
	cm.set_shader_parameter("clouds", Kit.texture(TEX + "8k_earth_clouds.jpg", true))
	cm.set_shader_parameter("amount", float(p.get("clouds", 0.85)))
	cl.material_override = cm
	cl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_globe.add_child(cl)
	var as_ := SphereMesh.new()
	as_.radius = _r * 1.016
	as_.height = _r * 2.032
	as_.radial_segments = 256
	as_.rings = 128
	var at := MeshInstance3D.new()
	at.mesh = as_
	var am := Kit.shader(ATMO)
	am.set_shader_parameter("sun_dir", sun)
	at.material_override = am
	at.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_globe.add_child(at)
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	var spin := deg_to_rad(float(p.get("spin", 0.0))) * t
	# The ground drifts under the orbit: turn the globe about gag-local X (the orbit runs toward -Z).
	_globe.basis = Basis(Vector3.RIGHT, -spin) * _basis0
	var gt := node.global_transform
	return {"target": gt * Vector3(0, -_alt, 0), "centre": gt * _globe.position}
