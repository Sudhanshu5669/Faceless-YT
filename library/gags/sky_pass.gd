## library:sky_pass — a satellite crossing the twilight sky, seen from the ground: a steady point of reflected
## sunlight sliding along a great circle between two sky directions (no trail, no blinking: that is how a satellite
## looks after sunset), fading in and out at the ends, with an optional brief flare (sunlight glancing off a panel).
##
##   {"id": "sat", "script": "library:sky_pass", "t": 0, "at": <point on the ground>,
##    "params": {"from": t, "to": t, "a": [azimuth, elevation], "b": [azimuth, elevation], "distance": 3000,
##               "size": 1.0, "brightness": 3.0, "color": "#fff4e6", "fade": 0.35, "flare": t}}
##
## Azimuths as in looks: 0 = gag-local +Z, 90 = +X; elevations in degrees above the horizon. The point moves at a
## constant angular speed from `a` (at `from`) to `b` (at `to`), and is hidden outside [from - fade, to + fade].
## `size` scales its apparent size (1 = a bright star). It is drawn unshaded, without fog, additively, so it reads
## through haze; keep the camera's `far` beyond `distance`. Anchors: "<id>.point".
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const POINT := """
shader_type spatial;
render_mode unshaded, fog_disabled, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 color : source_color = vec4(1.0, 0.96, 0.9, 1.0);
uniform float brightness = 3.0;
uniform float alpha = 1.0;
void vertex() {
	// Always face the camera.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0, 0, 0), vec4(0, length(MODEL_MATRIX[1].xyz), 0, 0),
		vec4(0, 0, 1, 0), vec4(0, 0, 0, 1));
}
void fragment() {
	float r = length(UV - 0.5) * 2.0;
	// A hard core and a soft halo (the bloom does the rest).
	float core = exp(-r * r * 90.0);
	float halo = exp(-r * r * 9.0) * 0.18;
	ALBEDO = color.rgb * (core * brightness + halo) * alpha;
}
"""

var _pt: MeshInstance3D
var _mat: ShaderMaterial


func validate(g: Dictionary) -> Array:
	var e := []
	var p: Dictionary = g.get("params", {})
	for k in p:
		if not (k in ["from", "to", "a", "b", "distance", "size", "brightness", "color", "fade", "flare"]):
			e.append("sky_pass: unknown param '%s'" % k)
	for k in ["a", "b"]:
		if not (p.get(k) is Array and (p.get(k) as Array).size() == 2):
			e.append("sky_pass: '%s' must be [azimuth, elevation]" % k)
	return e


func build(g: Dictionary) -> Node3D:
	var p: Dictionary = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "sky_pass"))
	_pt = MeshInstance3D.new()
	var q := QuadMesh.new()
	# A bright star is about 0.12 degrees across with its halo at this size.
	var d := float(p.get("distance", 3000.0))
	var w := d * deg_to_rad(0.5) * float(p.get("size", 1.0))
	q.size = Vector2(w, w)
	_pt.mesh = q
	_pt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pt.extra_cull_margin = w
	_mat = Kit.shader(POINT)
	_mat.set_shader_parameter("color", Color(String(p.get("color", "#fff4e6"))))
	_mat.set_shader_parameter("brightness", float(p.get("brightness", 3.0)))
	_pt.material_override = _mat
	root.add_child(_pt)
	return root


static func _dir(az_el: Array) -> Vector3:
	var az := deg_to_rad(float(az_el[0]))
	var el := deg_to_rad(float(az_el[1]))
	return Vector3(sin(az) * cos(el), sin(el), cos(az) * cos(el))


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	var t0 := float(p.get("from", 0.0))
	var t1 := float(p.get("to", t0 + 1.0))
	var fade := float(p.get("fade", 0.35))
	var a := _dir(p.get("a", [0.0, 30.0]))
	var b := _dir(p.get("b", [40.0, 50.0]))
	# Constant angular speed along the great circle (extrapolated a little into the fades).
	# (u runs past 0..1 through the fades, so the point keeps moving while it fades in and out).
	var u := (t - t0) / maxf(t1 - t0, 0.001)
	var axis := a.cross(b)
	var dir := a.rotated(axis.normalized(), a.angle_to(b) * u) if axis.length() > 0.0001 else a
	var d := float(p.get("distance", 3000.0))
	_pt.position = dir * d
	var vis := Motion.seg(t, t0 - fade, t0) * (1.0 - Motion.seg(t, t1, t1 + fade))
	_pt.visible = vis > 0.001
	var fl := float(p.get("flare", 1e9))
	var flare := exp(-pow((t - fl) / 0.12, 2.0)) * 4.0
	_mat.set_shader_parameter("alpha", vis * (1.0 + flare))
	return {"point": node.global_transform * _pt.position}
