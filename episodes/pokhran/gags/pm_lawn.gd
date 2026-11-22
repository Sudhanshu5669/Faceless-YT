extends RefCounted
## The lawn of the Prime Minister's residence, New Delhi, evening of 11 May 1998: Vajpayee reads the
## announcement at a lectern with a bank of microphones; press photographers' flashes pop.
##
## Local frame: the lectern stands at the origin facing +z (towards the press); its top at y 0.92. The
## speaker stands at (0, 0, -0.42). Behind: a white shamiana with a maroon valance, a clipped hedge, garden
## lamps, a dusk sky. TV crews' lights from the front left and right; a warm rim from the shamiana.
## params: flashes [t, ...] (a camera flash pops near the press line at each time)
## anchors: lectern, mics, speaker_head, press

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const LAWN := """
shader_type spatial;
//NOISE
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = fbm(wp * 2.2);
	float fine = h3(floor(wp * 180.0));
	vec3 c = mix(vec3(0.16, 0.24, 0.09), vec3(0.3, 0.33, 0.13), n);
	c = mix(c, vec3(0.36, 0.32, 0.18), smoothstep(0.62, 0.85, fbm(wp * 0.7 + 5.0)) * 0.6);
	c *= 0.85 + 0.3 * fine;
	ALBEDO = c;
	ROUGHNESS = 0.95;
}
"""

const HEDGE := """
shader_type spatial;
//NOISE
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = fbm(wp * 11.0);
	ALBEDO = mix(vec3(0.04, 0.1, 0.04), vec3(0.12, 0.22, 0.08), n);
	ROUGHNESS = 0.9;
	NORMAL_MAP = vec3(0.5 + 0.4 * (fbm(wp * 23.0) - 0.5), 0.5 + 0.4 * (fbm(wp * 23.0 + 4.0) - 0.5), 1.0);
}
"""

var _p := {}
var _flash: OmniLight3D
var _flash_ball: MeshInstance3D


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	Kit.box(root, Vector3(40, 0.05, 40), Vector3(0, -0.025, 0), Kit.shader(LAWN))
	# The shamiana: white canvas walls and roof on poles, a maroon-and-white scalloped valance.
	var canvas := Kit.mat("#efe8da", 0.9)
	var maroon := Kit.mat("#7a1a22", 0.8)
	Kit.box(root, Vector3(9, 3.0, 0.05), Vector3(0, 1.5, -3.2), canvas)
	Kit.box(root, Vector3(9, 0.05, 4.2), Vector3(0, 3.0, -1.1), canvas, Vector3(-0.05, 0, 0))
	for i in 18:
		var x := -4.25 + 0.5 * i
		Kit.box(root, Vector3(0.25, 0.32, 0.02), Vector3(x, 2.75, 1.02), maroon if i % 2 == 0 else canvas)
		Kit.ball(root, 0.13, Vector3(x + 0.25, 2.6, 1.02), maroon if i % 2 == 1 else canvas, 10, Vector3(1, 0.6, 0.15))
	for x in [-4.4, 4.4]:
		Kit.cyl(root, 0.05, 0.05, 3.0, Vector3(x, 1.5, 1.0), Kit.mat("#c9b48a", 0.6), 10)
	# A pleated backdrop behind the lectern (dark maroon velvet) so the speaker reads.
	for i in 16:
		Kit.box(root, Vector3(0.2, 2.6, 0.06), Vector3(-1.5 + 0.2 * i, 1.3, -3.1 + 0.04 * (i % 2)), Kit.mat("#4a0f16" if i % 2 else "#5c141c", 0.95))
	# Hedges and garden lamps beyond the open sides.
	var hedge := Kit.shader(HEDGE)
	for s in [-1.0, 1.0]:
		Kit.slab(root, Vector3(6, 1.1, 0.8), 0.25, Vector3(s * 8.0, 0.55, -2.0), hedge)
		for k in 3:
			var lp := Vector3(s * (5.6 + 1.8 * k), 0, 1.5)
			Kit.cyl(root, 0.03, 0.04, 1.4, lp + Vector3(0, 0.7, 0), Kit.mat("#20201e", 0.5), 8)
			Kit.ball(root, 0.12, lp + Vector3(0, 1.5, 0), Kit.lit("#ffe3a8", 3.0), 12)
			Kit.omni(root, lp + Vector3(0, 1.5, 0), "#ffcf80", 0.6, 4.0, false, 0.3)
	# The lectern: teak, a raked top, a front panel with a brass edge.
	var teak := Kit.mat("#5a3218", 0.5, 0.0, 0.5)
	Kit.slab(root, Vector3(0.62, 0.86, 0.42), 0.03, Vector3(0, 0.43, 0), teak)
	Kit.slab(root, Vector3(0.68, 0.05, 0.48), 0.015, Vector3(0, 0.9, -0.02), teak, Vector3(0.18, 0, 0))
	Kit.box(root, Vector3(0.64, 0.02, 0.01), Vector3(0, 0.75, 0.215), Kit.mat("#b8923e", 0.3, 0.0, 0.8))
	# The bank of microphones: stems clamped to the lectern edge, foam windscreens in news-crew colours.
	var cols := ["#c81e1e", "#1c1c1e", "#1f4ea8", "#e2c21c", "#1c1c1e", "#d8d8d4", "#1f7a3a", "#c81e1e", "#1c1c1e", "#2a2a6a"]
	for i in cols.size():
		var a := -0.55 + 0.12 * i
		var base := Vector3(sin(a) * 0.22, 0.93, 0.12 + cos(a) * 0.03)
		var tip := Vector3(sin(a) * 0.12, 1.12 + 0.03 * float(i % 3), -0.12 + 0.02 * float(i % 2))
		Kit.rod(root, base, tip, 0.006, Kit.mat("#111113", 0.4), 6)
		Kit.ball(root, 0.03, tip, Kit.mat(cols[i], 0.85), 12, Vector3(1, 1.3, 1))
	# TV lights: two warm keys from the press side, a cool rim from behind, a soft fill.
	Kit.spot(root, Vector3(-2.2, 2.4, 3.2), Vector3(0, 1.2, -0.4), "#ffe2b8", 5.0, 9.0, 30.0, true, 0.4)
	Kit.spot(root, Vector3(2.4, 2.2, 3.4), Vector3(0, 1.2, -0.4), "#ffe8c8", 3.0, 9.0, 30.0, false, 0.3)
	Kit.spot(root, Vector3(0.6, 2.9, -2.6), Vector3(0, 1.2, -0.4), "#cfdcff", 4.0, 6.0, 30.0, false, 0.3)
	Kit.omni(root, Vector3(0, 1.4, 2.5), "#ffeedd", 0.6, 6.0, false, 0.2)
	# A photographer's flash, moved between press positions.
	_flash = Kit.omni(root, Vector3(1.0, 1.3, 2.5), "#f4f8ff", 0.0, 7.0, false, 0.2)
	_flash_ball = Kit.ball(root, 0.03, Vector3(1.0, 1.3, 2.5), Kit.lit("#ffffff", 30.0), 8)
	_flash_ball.visible = false
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var best := 1e9
	var idx := 0
	var flashes: Array = _p.get("flashes", [])
	for i in flashes.size():
		var d := t - float(flashes[i])
		if d >= 0.0 and d < best:
			best = d
			idx = i
	var e := exp(-best * 22.0) if best < 0.4 else 0.0
	var r := Kit.rng("flash", idx)
	var at := Vector3(r.randf_range(-2.2, 2.2), r.randf_range(1.0, 1.6), r.randf_range(2.2, 3.4))
	_flash.position = at
	_flash.light_energy = 9.0 * e
	_flash_ball.position = at
	_flash_ball.visible = e > 0.05
	return {"lectern": gt * Vector3(0, 0.92, 0), "mics": gt * Vector3(0, 1.12, -0.05),
			"speaker_head": gt * Vector3(0, 1.25, -0.42), "press": gt * Vector3(0, 1.2, 3.0)}
