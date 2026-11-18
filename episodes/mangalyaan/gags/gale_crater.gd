extends RefCounted
## Gale Crater on Mars, September 2014: NASA's Curiosity rover (the real NASA 3D model) on dusty ground with
## flat rocks and sand ripples, Mount Sharp's layered slopes on the horizon, a butterscotch sky. On the word the
## rover sends a greeting up: rings of radio waves rise from its high-gain antenna toward a moving dot (MOM).
##
## Local frame: the rover at the origin facing -Z (toward Mount Sharp, at z -600).
## params: hail [t0, t1] (the radio rings), mom [t0, t1] (the dot crossing the sky)
## anchors: rover, mast, sky, mom

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const GROUND := """
shader_type spatial;
uniform sampler2D rocks : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rocks_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 wp;
//NOISE
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = (fbm(w * 0.04) - 0.5) * 3.0 + (fbm(w * 0.25) - 0.5) * 0.35;
	// Ripples of dark sand in the hollows.
	h += sin(w.x * 1.6 + w.z * 0.7 + fbm(w * 0.1) * 6.0) * 0.04;
	float flt = smoothstep(14.0, 6.0, length(w.xz - vec2(MODEL_MATRIX[3].x, MODEL_MATRIX[3].z + 60.0)));
	VERTEX.y += h * (1.0 - flt);
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 uv = wp.xz * 0.12;
	vec3 r = texture(rocks, uv).rgb;
	vec3 s = texture(sand, wp.xz * 0.2).rgb;
	float m = smoothstep(0.45, 0.6, fbm(wp * 0.15));
	vec3 col = mix(r, s * 0.8, m);
	float l = dot(col, vec3(0.33));
	col = vec3(l) * vec3(1.35, 0.78, 0.5) * 1.05;
	NORMAL_MAP = texture(rocks_n, uv).rgb;
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
}
"""

## Mount Sharp: a broad mound with horizontal strata, hazed by distance (the fog does the rest).
const MOUNT := """
shader_type spatial;
varying vec3 wp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float strata = sin(wp.y * 0.9 + fbm(wp * 0.02) * 6.0) * 0.5 + 0.5;
	vec3 col = mix(vec3(0.55, 0.36, 0.24), vec3(0.72, 0.52, 0.36), strata);
	col *= 0.85 + 0.25 * fbm(wp * 0.05);
	ALBEDO = col;
	ROUGHNESS = 1.0;
}
"""

const RING := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform float fade = 1.0;
void fragment() { ALBEDO = vec3(0.9, 0.95, 1.0) * fade * 0.8; }
"""

var _p := {}
var _rings: Array = []
var _dot: MeshInstance3D
var _mast_at := Vector3(0.0, 2.1, -0.9)


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(300, 300)
	plane.subdivide_width = 240
	plane.subdivide_depth = 240
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	var gm := Kit.shader(GROUND)
	var ph := "incoming/polyhaven_textures/"
	gm.set_shader_parameter("rocks", Kit.texture(ph + "aerial_rocks_02_diff_2k.jpg"))
	gm.set_shader_parameter("sand", Kit.texture(ph + "coast_sand_05_diff_2k.jpg"))
	gm.set_shader_parameter("rocks_n", Kit.texture(ph + "aerial_rocks_02_nor_gl_2k.jpg", true))
	ground.material_override = gm
	ground.position = Vector3(0, 0, -60)
	root.add_child(ground)
	# Flat, broken rocks scattered around (bedrock slabs and loose stones).
	var r := Kit.rng("gale")
	var rock_m := Kit.mat("#7a4a32", 0.95)
	var dark_m := Kit.mat("#4a2e22", 0.9)
	for i in 140:
		var a := r.randf() * TAU
		var d := r.randf_range(3.5, 60.0)
		var p := Vector3(cos(a) * d, 0, sin(a) * d - 8.0)
		var s := r.randf_range(0.08, 0.7) * (1.0 if d > 8.0 else 0.6)
		var rock := Kit.ball(root, 1.0, p + Vector3(0, s * 0.15, 0), dark_m if r.randf() < 0.4 else rock_m, 8,
			Vector3(s * r.randf_range(0.8, 1.6), s * r.randf_range(0.25, 0.55), s * r.randf_range(0.8, 1.6)))
		rock.rotation = Vector3(r.randf_range(-0.2, 0.2), r.randf() * TAU, r.randf_range(-0.2, 0.2))
	# Mount Sharp and the crater rim.
	var mound := Kit.ball(root, 1.0, Vector3(40, -60, -700), Kit.shader(MOUNT), 48, Vector3(520, 200, 260))
	mound.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rim := Kit.ball(root, 1.0, Vector3(-600, -80, 200), Kit.shader(MOUNT), 32, Vector3(500, 130, 900))
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The rover.
	var rover := Kit.model("incoming/nasa_models/Curiosity_static.glb")
	var holder := Node3D.new()
	holder.add_child(rover)
	var bb := Kit.bounds(rover)
	var k := 3.0 / maxf(maxf(bb.size.x, bb.size.z), 0.001)
	rover.scale = Vector3.ONE * k
	rover.position = Vector3(-bb.get_center().x * k, -bb.position.y * k - 0.04, -bb.get_center().z * k)
	holder.rotation = Vector3(0, 0.0, 0)
	root.add_child(holder)
	_mast_at = Vector3(0.0, bb.size.y * k * 0.95, 0.0)
	# Radio rings and MOM's dot.
	for i in 5:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.96
		tm.outer_radius = 1.0
		tm.rings = 48
		tm.ring_segments = 6
		ring.mesh = tm
		ring.material_override = Kit.shader(RING)
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(ring)
		_rings.append(ring)
	_dot = Kit.ball(root, 0.6, Vector3(0, 60, -40), Kit.flat(Color(1.0, 0.95, 0.8), true), 12)
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var hail = _p.get("hail", [])
	var sky := Vector3(-6, 70, -50)
	for i in _rings.size():
		var ring: MeshInstance3D = _rings[i]
		ring.visible = false
		if hail is Array and hail.size() >= 2:
			var age: float = t - float(hail[0]) - 0.32 * i
			if age > 0.0 and t < float(hail[1]) + 1.5:
				var u := clampf(age / 1.6, 0.0, 1.0)
				ring.visible = u < 1.0
				var p := _mast_at.lerp(_mast_at + (sky - _mast_at).normalized() * 9.0, Motion.out_cubic(u))
				ring.position = p
				ring.basis = Basis(Quaternion(Vector3.UP, (sky - _mast_at).normalized())).scaled(Vector3.ONE * (0.25 + 1.6 * u))
				(ring.material_override as ShaderMaterial).set_shader_parameter("fade", 1.0 - u)
	var mw = _p.get("mom", [])
	var mu := 0.0
	if mw is Array and mw.size() >= 2:
		mu = clampf((t - float(mw[0])) / maxf(float(mw[1]) - float(mw[0]), 0.01), 0.0, 1.0)
	_dot.position = Vector3(-30, 68, -60).lerp(Vector3(30, 74, -40), mu)
	_dot.scale = Vector3.ONE * (1.0 + 0.5 * absf(sin(t * 7.0)))
	return {"rover": gt * Vector3(0, 0.9, 0), "mast": gt * _mast_at, "sky": gt * sky, "mom": gt * _dot.position}
