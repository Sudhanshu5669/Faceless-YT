extends RefCounted
## The Prime Minister's office, South Block, New Delhi (Rao, December 1995; Vajpayee, 1998). A high room: cream
## walls over a teak dado, a maroon carpet with a border, a tall arched window (sandstone reveal, teak frame, half
## drawn curtains) throwing the low winter sun across the room, a ceiling fan turning slowly, a tube light. A big teak
## desk with a green leather top: buff files tied with red tape, a black dial phone and a beige push-button phone, a
## desk flag (the tricolour), a glass of water under a saucer lid, a brass pen stand. The PM's high-backed chair
## with a white towel over the back (it follows the sitter's hips so nothing clips).
##
## Local frame: the desk's centre at the origin, its top at y TOP; the PM sits behind it at (0, 0, -0.78) facing
## +z (the visitors' side). The window is in the -x wall (the PM's right), the door side is +z.
##
## params:
##   sitter   actor id, or a list of ids, in the PM's chair (the chair follows whichever is visible)
##   calendar {"flip": [t0, t1], "from": [1995, 12], "to": [1998, 3]}   a wall calendar on the back wall; its monthly
##            pages flip over the top, faster and faster, from `from` to `to` (each page: a printed picture, the month
##            and year, the date grid with the right weekdays)
##   paper    {"slap": t, "headline": [line, line], "folio": "...", "byline": "...", "dateline": "..."}
##            an aide's arm swings in from the visitors' side and slaps a folded newspaper onto the desk at `slap`
##   photos   {"slide": t, "hand": actor id, "cam": point, "ortho": metres}   satellite prints: a stack on the visitors'
##            side; at `slide` the top print slides across to the PM under the actor's right hand. The picture is a
##            live overhead orthographic view from `cam` (straight down), printed greyscale with a grease-pencil ring
##   ring     {"from": t, "until": t, "lift": t, "hand": actor id}   the black phone rings (the handset rattles in
##            double-ring bursts) from `from`; from `lift` the actor's right hand takes the handset slowly to the ear
## anchors: desk, paper, phone_black, phone_beige, chair, window, flag, print, handset, calendar
const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Toon = preload("res://scripts/actors/toon.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")

const TOP := 0.77
const ROOM := Vector3(7.4, 4.3, 6.4)       # x width, height, z depth
const ROOM_Z0 := -2.7                       # back wall
const PAPER := Vector2(0.343, 0.29)         # a broadsheet folded in half
const PAPER_AT := Vector3(0.05, TOP + 0.011, 0.08)
const CAL_AT := Vector3(-1.2, 2.05, ROOM_Z0 + 0.035)
const CAL_SIZE := Vector2(0.46, 0.66)
const MONTHS := ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]

const WALL := """
shader_type spatial;
varying vec3 wp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 c = vec3(0.86, 0.8, 0.66) * (0.94 + 0.08 * fbm(wp * 1.5));
	c *= 1.0 - 0.06 * smoothstep(0.6, 0.85, fbm(wp * vec3(0.6, 3.0, 0.6) + 2.0));
	ALBEDO = c;
	ROUGHNESS = 0.9;
}
"""

const TEAK := """
shader_type spatial;
uniform float gloss = 0.35;
varying vec3 lp;
//NOISE
void vertex() { lp = VERTEX; }
void fragment() {
	float grain = sin(lp.x * 60.0 + fbm(lp * vec3(2.0, 8.0, 8.0)) * 9.0) * 0.5 + 0.5;
	vec3 c = mix(vec3(0.24, 0.12, 0.05), vec3(0.4, 0.22, 0.1), grain * 0.6 + 0.4 * fbm(lp * 3.0));
	ALBEDO = c;
	ROUGHNESS = gloss;
	SPECULAR = 0.55;
}
"""

const LEATHER := """
shader_type spatial;
varying vec3 lp;
//NOISE
void vertex() { lp = VERTEX; }
void fragment() {
	vec3 c = vec3(0.07, 0.2, 0.12) * (0.85 + 0.25 * fbm(lp * 18.0));
	ALBEDO = c;
	ROUGHNESS = 0.55 + 0.2 * fbm(lp * 40.0);
	SPECULAR = 0.45;
}
"""

const CARPET := """
shader_type spatial;
varying vec3 lp;
//NOISE
void vertex() { lp = VERTEX; }
void fragment() {
	vec2 p = lp.xz;
	vec2 half = vec2(2.2, 1.7);
	vec2 d = abs(p) - half;
	float border = step(-0.32, max(d.x, d.y)) * step(max(d.x, d.y), -0.06);
	float inner = step(max(d.x, d.y), -0.32);
	vec3 maroon = vec3(0.32, 0.06, 0.06);
	vec3 navy = vec3(0.08, 0.08, 0.16);
	vec3 gold = vec3(0.6, 0.45, 0.2);
	vec2 q = fract(p * 1.2) - 0.5;
	float motif = smoothstep(0.32, 0.28, length(q)) * smoothstep(0.18, 0.22, length(q));
	vec3 c = maroon * (0.85 + 0.2 * fbm(vec3(p * 9.0, 1.0)));
	c = mix(c, gold * 0.7, motif * inner * 0.5);
	c = mix(c, navy, border);
	c = mix(c, gold, border * step(0.5, fract(dot(p, vec2(6.0, 6.0)))) * 0.35);
	c = mix(vec3(0.42, 0.36, 0.3), c, step(max(d.x, d.y), 0.0));
	ALBEDO = c;
	ROUGHNESS = 0.98;
	SPECULAR = 0.1;
}
"""

## Newsprint: off-white, a little grey, the text columns as fine grey lines (not readable, so nothing is invented),
## the fold across the middle.
const NEWSPRINT := """
shader_type spatial;
render_mode cull_disabled;
uniform float body_top = 0.42;
varying vec2 uvp;
//NOISE
void vertex() { uvp = UV; }
void fragment() {
	vec3 c = vec3(0.89, 0.87, 0.81) * (0.96 + 0.05 * n3(vec3(uvp * 400.0, 1.0)));
	vec2 p = uvp;
	// Six columns of body text below the headline block; justified lines of grey.
	float col = fract(p.x * 6.0);
	float gutter = step(0.06, col) * step(col, 0.94);
	float line = step(0.45, fract(p.y * 170.0)) * step(body_top, p.y) * step(p.y, 0.98) * gutter;
	float len = step(fract(p.y * 170.0 * 0.137 + floor(p.x * 6.0) * 0.31), 0.93);
	c = mix(c, vec3(0.42, 0.42, 0.42), line * mix(0.75, 0.0, 1.0 - len) * 0.85);
	// Column rules.
	c = mix(c, vec3(0.6), step(abs(col - 0.0), 0.004) * step(body_top, p.y) * step(0.02, p.x) * 0.7);
	// The fold (lower edge region creases).
	c *= 1.0 - 0.05 * smoothstep(0.02, 0.0, abs(p.y - 0.985));
	ALBEDO = c;
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
}
"""


## A reconnaissance print: the overhead view in greyscale, hard contrast, grain, a white border, a grease-pencil
## ring round the middle (the analyst's mark).
const PRINT := """
shader_type spatial;
uniform sampler2D view : source_color, filter_linear;
uniform float ring = 1.0;
uniform float seed = 0.0;
varying vec2 uvp;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453); }
void vertex() { uvp = UV; }
void fragment() {
	vec2 b = abs(uvp - 0.5);
	float border = step(0.455, max(b.x, b.y));
	vec2 iuv = (uvp - 0.5) / 0.91 + 0.5;
	vec3 v = texture(view, iuv).rgb;
	float g = dot(v, vec3(0.3, 0.59, 0.11));
	g = clamp((g - 0.5) * 1.15 + 0.46, 0.0, 1.0);
	g += (h(floor(uvp * 700.0)) - 0.5) * 0.12;
	vec3 c = vec3(g) * vec3(0.98, 0.97, 0.94);
	float r = abs(length((uvp - vec2(0.5, 0.5)) * vec2(1.0, 1.0)) - 0.12 - 0.01 * sin(atan(uvp.y - 0.5, uvp.x - 0.5) * 3.0));
	c = mix(c, vec3(0.75, 0.1, 0.08), (1.0 - smoothstep(0.004, 0.009, r)) * ring * (1.0 - border));
	c = mix(c, vec3(0.95, 0.94, 0.9), border);
	ALBEDO = c;
	ROUGHNESS = 0.18;
	SPECULAR = 0.7;
}
"""

const CAL_PRINT := """
shader_type spatial;
render_mode cull_disabled;
uniform float variant = 0.0;
varying vec2 uvp;
//NOISE
void vertex() { uvp = UV; }
void fragment() {
	vec2 p = uvp;
	vec3 c = vec3(0.97, 0.96, 0.92);
	// The picture: the top 45 % of the sheet, inset by a margin.
	if (p.y < 0.46 && p.x > 0.05 && p.x < 0.95 && p.y > 0.04) {
		vec2 q = vec2((p.x - 0.05) / 0.9, (p.y - 0.04) / 0.42);
		float v = variant;
		vec3 sky = mix(vec3(0.55, 0.72, 0.9), vec3(0.95, 0.75, 0.55), fract(v * 0.37) * (1.0 - q.y) * 0.8);
		float hill = 0.45 + 0.12 * sin(q.x * 6.0 + v * 2.0) + 0.06 * sin(q.x * 17.0 + v);
		float hill2 = 0.6 + 0.08 * sin(q.x * 9.0 + v * 3.0);
		c = sky;
		c = mix(c, vec3(0.35, 0.42, 0.5), step(hill, q.y));
		c = mix(c, vec3(0.2, 0.36, 0.2) * (0.8 + 0.3 * fbm(vec3(q * 20.0, v))), step(hill2, q.y));
		c = mix(c, vec3(0.4, 0.58, 0.72), step(0.85, q.y) * 0.8);
	}
	// A thin red rule under the picture.
	c = mix(c, vec3(0.75, 0.1, 0.1), step(abs(p.y - 0.49), 0.004));
	// The back of the sheet is plain paper.
	if (!FRONT_FACING) { c = vec3(0.93, 0.92, 0.88); }
	ALBEDO = c;
	ROUGHNESS = 0.6;
	SPECULAR = 0.3;
}
"""

var _p := {}
var _cal_pages: Array = []     # two pages: [node, labels {month, year, days[42]}, material]
var _chair_top: Node3D
var _chair_base: Node3D
var _fan: Node3D
var _paper: Node3D
var _arm_upper: MeshInstance3D
var _hand: MeshInstance3D
var _jiggle: Array = []
var _phone: Node3D
var _handset: Node3D
var _cord: Array = []
const HANDSET_REST := Vector3(0, 0.125, -0.04)
var _prints: Array = []
var _photo_view: SubViewport
var _photo_cam: Camera3D


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	_room(root)
	_desk(root)
	_chair(root)
	_paper_build(root)
	_photos_build(root)
	_calendar_build(root)
	return root


func _room(root: Node3D) -> void:
	var wall := Kit.shader(WALL)
	var teak := Kit.shader(TEAK)
	var hx := ROOM.x * 0.5
	var z0 := ROOM_Z0
	var z1 := ROOM_Z0 + ROOM.z
	var zc := (z0 + z1) * 0.5
	# Floor (polished stone under the carpet), ceiling, walls; the -x wall has the arched window.
	Kit.box(root, Vector3(ROOM.x, 0.05, ROOM.z), Vector3(0, -0.025, zc), Kit.mat("#a89a84", 0.35, 0.0, 0.6))
	var carpet := MeshInstance3D.new()
	var cm := PlaneMesh.new()
	cm.size = Vector2(4.8, 3.8)
	carpet.mesh = cm
	carpet.material_override = Kit.shader(CARPET)
	carpet.position = Vector3(0, 0.006, 0.2)
	root.add_child(carpet)
	Kit.box(root, Vector3(ROOM.x, 0.08, ROOM.z), Vector3(0, ROOM.y + 0.04, zc), Kit.mat("#ece8de", 0.9))
	Kit.box(root, Vector3(ROOM.x, ROOM.y, 0.1), Vector3(0, ROOM.y * 0.5, z0 - 0.05), wall)
	Kit.box(root, Vector3(ROOM.x, ROOM.y, 0.1), Vector3(0, ROOM.y * 0.5, z1 + 0.05), wall)
	Kit.box(root, Vector3(0.1, ROOM.y, ROOM.z), Vector3(hx + 0.05, ROOM.y * 0.5, zc), wall)
	# The window wall: the opening (1.5 m wide, sill at 0.9, arch springing at 2.9, crown at 3.65), built around.
	var wz := -0.3
	var ww := 1.5
	var sill := 0.9
	var spring := 2.9
	var wx := -hx - 0.05
	var thick := 0.45
	Kit.box(root, Vector3(thick, ROOM.y, wz - ww * 0.5 - z0), Vector3(wx - thick * 0.5 + 0.05, ROOM.y * 0.5, (z0 + wz - ww * 0.5) * 0.5), wall)
	Kit.box(root, Vector3(thick, ROOM.y, z1 - (wz + ww * 0.5)), Vector3(wx - thick * 0.5 + 0.05, ROOM.y * 0.5, (z1 + wz + ww * 0.5) * 0.5), wall)
	Kit.box(root, Vector3(thick, sill, ww), Vector3(wx - thick * 0.5 + 0.05, sill * 0.5, wz), wall)
	# The arch: the wall above the opening, cut by a half circle (stacked slices).
	var n := 14
	for i in n:
		var y0 := spring + (ROOM.y - spring) * float(i) / n
		var y1 := spring + (ROOM.y - spring) * float(i + 1) / n
		var ym := (y0 + y1) * 0.5 - spring
		var half := 0.0
		if ym < ww * 0.5:
			half = sqrt(maxf(ww * ww * 0.25 - ym * ym, 0.0))
		var side := (ww * 0.5 - half)
		if half <= 0.001:
			Kit.box(root, Vector3(thick, y1 - y0 + 0.002, ww), Vector3(wx - thick * 0.5 + 0.05, (y0 + y1) * 0.5, wz), wall)
		else:
			for s in [-1.0, 1.0]:
				Kit.box(root, Vector3(thick, y1 - y0 + 0.002, side + 0.002), Vector3(wx - thick * 0.5 + 0.05, (y0 + y1) * 0.5, wz + s * (half + side * 0.5)), wall)
	# The sandstone reveal and the teak frame with glazing bars; glass (clear) and curtains half drawn.
	var stone := Kit.mat("#b98a5e", 0.85)
	Kit.box(root, Vector3(0.06, 0.06, ww + 0.2), Vector3(wx + 0.06, sill, wz), stone)
	var frame := Kit.mat("#3a2414", 0.5)
	for k in 3:
		Kit.box(root, Vector3(0.05, spring - sill, 0.05), Vector3(wx - 0.2, (spring + sill) * 0.5, wz - ww * 0.5 + ww * float(k) / 2.0), frame)
	for k in 4:
		Kit.box(root, Vector3(0.04, 0.04, ww), Vector3(wx - 0.2, sill + (spring - sill) * float(k) / 3.0, wz), frame)
	var curtain := Kit.mat("#c9b48a", 0.95)
	for s in [-1.0, 1.0]:
		var cur := Kit.box(root, Vector3(0.06, 3.3, 0.5), Vector3(wx + 0.12, 2.15, wz + s * (ww * 0.5 + 0.12)), curtain)
		cur.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	Kit.rod(root, Vector3(wx + 0.16, 3.85, wz - ww * 0.5 - 0.5), Vector3(wx + 0.16, 3.85, wz + ww * 0.5 + 0.5), 0.02, Kit.mat("#8a6a3a", 0.4, 0.6), 8)
	# Teak dado round the walls, a picture rail, the cornice.
	for e in [[Vector3(ROOM.x, 1.1, 0.03), Vector3(0, 0.55, z0 + 0.015)], [Vector3(0.03, 1.1, ROOM.z), Vector3(hx - 0.015, 0.55, zc)]]:
		Kit.box(root, e[0], e[1], teak)
	Kit.box(root, Vector3(ROOM.x, 0.05, 0.05), Vector3(0, 1.12, z0 + 0.03), teak)
	Kit.box(root, Vector3(ROOM.x, 0.12, 0.12), Vector3(0, ROOM.y - 0.06, z0 + 0.06), Kit.mat("#f2eee4", 0.8))
	# Behind the PM: a framed portrait of Gandhi (drawn simply: a sepia print), and a bookcase with files.
	var pf := Kit.box(root, Vector3(0.62, 0.78, 0.04), Vector3(0, 2.25, z0 + 0.03), Kit.mat("#2a1a0e", 0.5))
	var print_m := Kit.shader("""
shader_type spatial;
varying vec2 uv2;
void vertex() { uv2 = UV; }
void fragment() {
	vec2 p = uv2 - vec2(0.5, 0.45);
	float head = 1.0 - smoothstep(0.17, 0.19, length(p * vec2(1.0, 0.85)));
	float body = (1.0 - smoothstep(0.32, 0.34, length((p - vec2(0.0, 0.42)) * vec2(0.8, 1.2)))) * step(0.15, p.y);
	float spect = smoothstep(0.012, 0.0, abs(length((p - vec2(-0.06, -0.01)) * vec2(1.0, 1.4)) - 0.045)) + smoothstep(0.012, 0.0, abs(length((p - vec2(0.06, -0.01)) * vec2(1.0, 1.4)) - 0.045));
	vec3 bg = vec3(0.72, 0.62, 0.46);
	vec3 c = mix(bg, vec3(0.45, 0.36, 0.26), max(head * 0.6, body * 0.75));
	c = mix(c, vec3(0.15, 0.1, 0.06), clamp(spect, 0.0, 1.0));
	ALBEDO = c;
	ROUGHNESS = 0.6;
}
""")
	Kit.quad(root, Vector2(0.48, 0.64), Vector3(0, 2.25, z0 + 0.052), print_m)
	var shelf := Kit.mat("#3a2414", 0.5)
	for k in 5:
		Kit.box(root, Vector3(1.6, 0.03, 0.36), Vector3(2.4, 0.3 + 0.45 * k, z0 + 0.2), shelf)
	for s in [-1.0, 1.0]:
		Kit.box(root, Vector3(0.03, 2.1, 0.36), Vector3(2.4 + s * 0.8, 1.05, z0 + 0.2), shelf)
	var rf := Kit.rng("office_files")
	for k in 4:
		var x := 1.7
		while x < 3.1:
			var w := rf.randf_range(0.03, 0.07)
			var h := rf.randf_range(0.26, 0.36)
			var colr: String = ["#c8b48a", "#b89a6a", "#8a2a22", "#2a3a5a", "#d8cfb8"][rf.randi() % 5]
			Kit.box(root, Vector3(w, h, 0.26), Vector3(x + w * 0.5, 0.315 + 0.45 * k + h * 0.5, z0 + 0.2), Kit.mat(colr, 0.85))
			x += w + 0.004
	# The ceiling fan (three blades, turning) and a tube light on the side wall.
	_fan = Node3D.new()
	_fan.position = Vector3(0, ROOM.y - 0.55, 0.4)
	root.add_child(_fan)
	var fanm := Kit.mat("#e8e4d8", 0.4, 0.2)
	Kit.rod(root, Vector3(0, ROOM.y, 0.4), Vector3(0, ROOM.y - 0.5, 0.4), 0.015, fanm, 8)
	Kit.cyl(_fan, 0.11, 0.13, 0.12, Vector3.ZERO, fanm, 20)
	for k in 3:
		var pivot := Node3D.new()
		pivot.rotation.y = TAU * k / 3.0
		_fan.add_child(pivot)
		var bl := Kit.slab(pivot, Vector3(0.62, 0.012, 0.13), 0.02, Vector3(0.42, -0.02, 0), fanm)
		bl.rotation.x = 0.1
	Kit.box(root, Vector3(0.06, 0.05, 1.22), Vector3(hx - 0.06, 3.1, 1.2), Kit.mat("#d8d6d0", 0.5))
	var tube := Kit.cyl(root, 0.016, 0.016, 1.18, Vector3(hx - 0.1, 3.07, 1.2), Kit.lit("#f4f8ff", 2.2), 10, Vector3(PI / 2, 0, 0))
	tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Kit.omni(root, Vector3(hx - 0.4, 3.0, 1.2), "#dfe8ff", 0.35, 6.0)
	# Warm bounce off the sunlit floor by the window, behind the PM's right shoulder: a rim on his head and on
	# whatever he holds up on that side (the telephone receiver).
	Kit.omni(root, Vector3(-1.1, 1.35, -1.25), "#ffcf9a", 0.32, 2.4)


func _desk(root: Node3D) -> void:
	var teak := Kit.shader(TEAK)
	var teak_top := Kit.shader(TEAK)
	teak_top.set_shader_parameter("gloss", 0.22)
	# The top (teak border round a green leather inlay), the modesty panel, two pedestals of drawers.
	Kit.slab(root, Vector3(1.95, 0.05, 1.0), 0.02, Vector3(0, TOP - 0.025, 0), teak_top)
	Kit.box(root, Vector3(1.6, 0.004, 0.72), Vector3(0, TOP + 0.002, 0.03), Kit.shader(LEATHER))
	for s in [-1.0, 1.0]:
		Kit.box(root, Vector3(0.5, TOP - 0.05, 0.9), Vector3(s * 0.68, (TOP - 0.05) * 0.5, 0), teak)
		for k in 3:
			Kit.box(root, Vector3(0.44, 0.2, 0.01), Vector3(s * 0.68, 0.12 + 0.23 * k, 0.455), teak_top)
			Kit.box(root, Vector3(0.1, 0.015, 0.02), Vector3(s * 0.68, 0.2 + 0.23 * k, 0.465), Kit.mat("#b08a40", 0.3, 0.8))
	Kit.box(root, Vector3(0.86, 0.5, 0.03), Vector3(0, 0.45, 0.35), teak)
	# Files tied with red tape, stacked on the PM's left.
	var rf := Kit.rng("desk_files")
	var red := Kit.mat("#b0181a", 0.7)
	for k in 5:
		var fx := 0.58 + rf.randf_range(-0.02, 0.02)
		var fz := -0.12 + rf.randf_range(-0.02, 0.02)
		var y := TOP + 0.012 + 0.024 * k
		var f := Kit.box(root, Vector3(0.36, 0.022, 0.25), Vector3(fx, y, fz), Kit.mat(["#d6c39a", "#c8ad7c", "#dccba6"][k % 3], 0.9), Vector3(0, rf.randf_range(-0.08, 0.08), 0))
		Kit.box(f, Vector3(0.012, 0.026, 0.252), Vector3(0, 0, 0), red)
		Kit.box(f, Vector3(0.362, 0.026, 0.012), Vector3(0, 0, 0), red)
		_jiggle.append([f, f.position, k])
	# The black dial phone (PM's right) and the beige push-button phone.
	var blk := Kit.mat("#16161a", 0.18, 0.0, 0.9)
	var ph := Node3D.new()
	ph.name = "phone_black"
	ph.position = Vector3(-0.62, TOP, -0.12)
	ph.rotation.y = 0.35
	root.add_child(ph)
	Kit.slab(ph, Vector3(0.22, 0.09, 0.24), 0.04, Vector3(0, 0.045, 0), blk)
	# The rotary dial: a cream disc with the finger holes ringed in black, a chrome stop.
	Kit.cyl(ph, 0.07, 0.075, 0.015, Vector3(0, 0.08, 0.04), Kit.mat("#d8d4c8", 0.5), 24, Vector3(-0.5, 0, 0))
	for k in 10:
		var a := -0.6 + 5.0 * float(k) / 10.0
		Kit.cyl(ph, 0.008, 0.008, 0.018, Vector3(cos(a) * 0.05, 0.083 + sin(-0.5) * cos(a) * 0.0, 0.04 + sin(a) * 0.05 * cos(0.5)), blk, 8, Vector3(-0.5, 0, 0))
	# Cradle prongs; the handset is its own node so it can rattle and be lifted (pose).
	for s in [-1.0, 1.0]:
		Kit.box(ph, Vector3(0.03, 0.035, 0.05), Vector3(s * 0.08, 0.1, -0.04), blk)
	_handset = Node3D.new()
	_handset.name = "handset"
	ph.add_child(_handset)
	_handset.position = HANDSET_REST
	_handset.scale = Vector3.ONE * 1.25
	Kit.slab(_handset, Vector3(0.22, 0.04, 0.055), 0.02, Vector3(0, 0, 0), blk)
	for s in [-1.0, 1.0]:
		Kit.ball(_handset, 0.035, Vector3(s * 0.1, 0.006, 0), blk, 12, Vector3(1, 0.8, 1.2))
	_phone = ph
	# The coiled cord from the base's side to the handset's end (rebuilt each frame in pose).
	for k in 16:
		var seg := Kit.rod(root, Vector3.ZERO, Vector3(0, 0.01, 0), 0.007, blk, 6)
		_cord.append(seg)
	_jiggle.append([ph, ph.position, 7])
	var beige := Kit.mat("#d8cdb0", 0.45)
	var ph2 := Node3D.new()
	ph2.name = "phone_beige"
	ph2.position = Vector3(-0.42, TOP, -0.3)
	ph2.rotation.y = 0.1
	root.add_child(ph2)
	Kit.slab(ph2, Vector3(0.2, 0.06, 0.22), 0.02, Vector3(0, 0.03, 0), beige, Vector3(-0.15, 0, 0))
	Kit.slab(ph2, Vector3(0.2, 0.04, 0.055), 0.02, Vector3(0, 0.085, -0.05), beige)
	for i in 4:
		for j in 3:
			Kit.box(ph2, Vector3(0.022, 0.008, 0.018), Vector3(-0.03 + 0.03 * j, 0.06, 0.02 + 0.026 * i), Kit.mat("#efe9da", 0.4))
	# The desk flag: the tricolour on a brass pole (saffron, white with the navy Ashoka Chakra, green).
	var fl := Node3D.new()
	fl.name = "flag"
	fl.position = Vector3(0.82, TOP, -0.3)
	root.add_child(fl)
	var brass := Kit.mat("#b08a40", 0.3, 0.8)
	Kit.cyl(fl, 0.04, 0.05, 0.02, Vector3(0, 0.01, 0), brass, 16)
	Kit.rod(fl, Vector3(0, 0.02, 0), Vector3(0, 0.34, 0), 0.004, brass, 6)
	Kit.ball(fl, 0.009, Vector3(0, 0.345, 0), brass, 8)
	var flag_m := Kit.shader("""
shader_type spatial;
render_mode cull_disabled;
varying vec2 uv2;
void vertex() { uv2 = UV; VERTEX.z += 0.004 * sin(UV.x * 6.0); }
void fragment() {
	vec3 c = uv2.y < 1.0 / 3.0 ? vec3(1.0, 0.6, 0.2) : (uv2.y < 2.0 / 3.0 ? vec3(0.97, 0.97, 0.95) : vec3(0.07, 0.53, 0.03));
	vec2 p = (uv2 - vec2(0.5, 0.5)) * vec2(1.5, 1.0);
	float r = length(p);
	float a = atan(p.y, p.x);
	float wheel = smoothstep(0.012, 0.0, abs(r - 0.135)) + smoothstep(0.012, 0.0, r - 0.025);
	wheel += step(r, 0.135) * smoothstep(0.08, 0.0, abs(fract(a / 6.2831853 * 24.0) - 0.5) - 0.42);
	c = mix(c, vec3(0.0, 0.0, 0.5), clamp(wheel, 0.0, 1.0) * step(1.0 / 3.0, uv2.y) * step(uv2.y, 2.0 / 3.0));
	ALBEDO = c;
	ROUGHNESS = 0.8;
}
""")
	Kit.quad(fl, Vector2(0.15, 0.1), Vector3(0.077, 0.29, 0), flag_m)
	# A glass of water under a saucer lid; a brass pen stand.
	var glass := Kit.mat(Color(0.85, 0.9, 0.95, 0.35), 0.05, 0.0, 0.9)
	Kit.cyl(root, 0.034, 0.03, 0.11, Vector3(0.38, TOP + 0.055, -0.28), glass, 20)
	Kit.cyl(root, 0.029, 0.027, 0.07, Vector3(0.38, TOP + 0.04, -0.28), Kit.mat(Color(0.7, 0.8, 0.85, 0.5), 0.02, 0.0, 0.9), 20)
	Kit.cyl(root, 0.05, 0.045, 0.012, Vector3(0.38, TOP + 0.116, -0.28), Kit.mat("#f2f0ea", 0.3), 24)
	Kit.cyl(root, 0.06, 0.06, 0.012, Vector3(-0.15, TOP + 0.006, -0.3), brass, 24)
	for k in 3:
		Kit.rod(root, Vector3(-0.15 + 0.015 * (k - 1), TOP + 0.01, -0.3), Vector3(-0.17 + 0.03 * (k - 1), TOP + 0.16, -0.34), 0.005, Kit.mat(["#1a2a6a", "#101010", "#8a1010"][k], 0.3), 8)


func _chair(root: Node3D) -> void:
	# The PM's high-backed chair: dark leather, teak arms, a white towel over the back.
	var leather := Kit.mat("#2a1a12", 0.5)
	var teak := Kit.shader(TEAK)
	_chair_base = Node3D.new()
	root.add_child(_chair_base)
	Kit.box(_chair_base, Vector3(0.62, 0.42, 0.58), Vector3(0, 0.21, 0), leather)
	_chair_top = Node3D.new()
	root.add_child(_chair_top)
	Kit.slab(_chair_top, Vector3(0.62, 0.09, 0.58), 0.06, Vector3(0, -0.045, 0), leather)
	Kit.slab(_chair_top, Vector3(0.62, 0.95, 0.12), 0.08, Vector3(0, 0.45, -0.32), leather, Vector3(-0.1, 0, 0))
	for s in [-1.0, 1.0]:
		Kit.box(_chair_top, Vector3(0.07, 0.06, 0.5), Vector3(s * 0.34, 0.22, -0.02), teak)
		Kit.box(_chair_top, Vector3(0.05, 0.22, 0.05), Vector3(s * 0.34, 0.1, 0.18), teak)
	# The white towel folded over the top of the back (front and back flaps).
	var towel := Kit.mat("#f6f5f0", 0.95)
	Kit.slab(_chair_top, Vector3(0.5, 0.36, 0.02), 0.03, Vector3(0, 0.77, -0.25), towel, Vector3(-0.1, 0, 0))
	Kit.slab(_chair_top, Vector3(0.5, 0.3, 0.02), 0.03, Vector3(0, 0.8, -0.39), towel, Vector3(-0.1, 0, 0))
	Kit.slab(_chair_top, Vector3(0.5, 0.05, 0.16), 0.02, Vector3(0, 0.93, -0.32), towel)
	_chair_top.position = Vector3(0, 0.46, -0.8)
	_chair_base.position = Vector3(0, 0, -0.8)


func _paper_build(root: Node3D) -> void:
	var pp: Dictionary = _p.get("paper", {})
	if pp.is_empty():
		return
	_paper = Node3D.new()
	_paper.name = "paper"
	root.add_child(_paper)
	var page := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = PAPER
	pm.subdivide_width = 8
	pm.subdivide_depth = 8
	page.mesh = pm
	page.material_override = Kit.shader(NEWSPRINT)
	page.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_paper.add_child(page)
	# Type laid flat on the page, reading toward +z (the visitors' side). Page-local: x right, z down the page.
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Times New Roman", "serif"])
	serif.font_weight = 700
	var roman := SystemFont.new()
	roman.font_names = PackedStringArray(["Times New Roman", "Georgia", "serif"])
	var ink := Color(0.08, 0.08, 0.08)
	var top := -PAPER.y * 0.5
	_flat_text(_paper, String(pp.get("folio", "")), roman, 0.0055, ink, Vector3(0, 0.0012, top + 0.016))
	Kit.box(_paper, Vector3(PAPER.x - 0.03, 0.0004, 0.0009), Vector3(0, 0.0011, top + 0.026), Kit.mat("#202020", 0.9))
	var lines: Array = pp.get("headline", [])
	for i in lines.size():
		_flat_text(_paper, String(lines[i]), serif, 0.02, ink, Vector3(0, 0.0012, top + 0.054 + 0.027 * i), PAPER.x - 0.05)
	var after := top + 0.054 + 0.027 * lines.size()
	_flat_text(_paper, String(pp.get("byline", "")), roman, 0.0065, ink, Vector3(0, 0.0012, after + 0.004))
	_flat_text(_paper, String(pp.get("dateline", "")), roman, 0.0055, ink, Vector3(-PAPER.x * 0.5 + 0.075, 0.0012, after + 0.02), 0.12)
	(page.material_override as ShaderMaterial).set_shader_parameter("body_top", clampf((after + 0.03 - top) / PAPER.y, 0.0, 1.0))
	# The aide's arm (a toon's stick arm and ball hand) that carries it in.
	var limb := Toon.material(Color("1a1a1a"), Toon.OUTLINE * 0.4)
	_arm_upper = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.022
	cm.bottom_radius = 0.022
	cm.height = 1.0
	_arm_upper.mesh = cm
	_arm_upper.material_override = limb
	root.add_child(_arm_upper)
	_hand = MeshInstance3D.new()
	_hand.mesh = Toon.sphere(0.05)
	_hand.material_override = limb
	root.add_child(_hand)


func _photos_build(root: Node3D) -> void:
	var pd: Dictionary = _p.get("photos", {})
	if pd.is_empty():
		return
	_photo_view = SubViewport.new()
	_photo_view.size = Vector2i(768, 768)
	_photo_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_photo_view.own_world_3d = false
	_photo_view.msaa_3d = Viewport.MSAA_2X
	root.add_child(_photo_view)
	_photo_cam = Camera3D.new()
	_photo_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_photo_cam.size = float(pd.get("ortho", 40.0))
	_photo_cam.near = 1.0
	_photo_cam.far = 2000.0
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.5, 0.48, 0.44)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.58, 0.55)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_photo_cam.environment = env
	_photo_view.add_child(_photo_cam)
	# Three prints: two lying squared on the visitors' side, the top one slides across.
	for k in 3:
		var q := MeshInstance3D.new()
		var qm := PlaneMesh.new()
		qm.size = Vector2(0.254, 0.203)
		q.mesh = qm
		var m := Kit.shader(PRINT)
		m.set_shader_parameter("view", _photo_view.get_texture())
		m.set_shader_parameter("ring", 1.0 if k == 2 else 0.0)
		m.set_shader_parameter("seed", float(k) * 3.1)
		q.material_override = m
		q.position = Vector3(0.28 + 0.01 * k, TOP + 0.009 + 0.0015 * k, 0.33 - 0.008 * k)
		q.rotation.y = 0.08 - 0.05 * k
		root.add_child(q)
		_prints.append(q)


func _pose_photos(gt: Transform3D, t: float, ctx: Dictionary) -> Vector3:
	var pd: Dictionary = _p.get("photos", {})
	if pd.is_empty() or _prints.is_empty():
		return Vector3.ZERO
	# The live overhead view (straight down from the given point).
	var cp: Dictionary = ctx["point"].call(pd["cam"]) if pd.has("cam") else {}
	if cp.has("pos"):
		var at: Vector3 = cp["pos"]
		_photo_cam.global_transform = Transform3D(Basis.looking_at(Vector3.DOWN, Vector3.FORWARD), at)
	# The slide: the top print glides across toward the PM, eased, a small turn as it goes; it lands on `slide`.
	var ts := float(pd.get("slide", 1e9))
	var u := Motion.out_cubic(Motion.seg(t, ts - 0.55, ts))
	var top_print: MeshInstance3D = _prints[2]
	var from := Vector3(0.3, TOP + 0.012, 0.316)
	var to := Vector3(0.02, TOP + 0.012, -0.08)
	top_print.position = from.lerp(to, u)
	top_print.rotation.y = lerpf(-0.02, 0.18, u)
	# His fingers on its near corner until it lands, then the hand lifts away.
	var hid := String(pd.get("hand", ""))
	var actor = ctx["actor"].call(hid) if hid != "" and ctx.has("actor") else null
	if actor != null:
		var corner := top_print.position + Basis(Vector3.UP, top_print.rotation.y) * Vector3(0.09, 0.0, 0.085)
		var away := Motion.smooth(Motion.seg(t, ts + 0.1, ts + 0.5))
		var w := 1.0 - away
		if t > ts - 1.2:
			var lead := Motion.smooth(Motion.seg(t, ts - 1.2, ts - 0.55))
			actor.aim_hand("r", gt * (corner + Vector3(0, 0.05, 0)), w * lead, 0.02)
	return top_print.position


## The black phone: rattling while it rings; lifted to the ear by the actor's right hand.
func _pose_phone(gt: Transform3D, t: float, ctx: Dictionary) -> Vector3:
	var rd: Dictionary = _p.get("ring", {})
	_handset.position = HANDSET_REST
	_handset.rotation = Vector3.ZERO
	var inv_ph := _phone.transform.affine_inverse()
	var hand_world := Vector3.ZERO
	if not rd.is_empty():
		var t0 := float(rd.get("from", 1e9))
		var tl := float(rd.get("lift", 1e9))
		# A double ring (0.4 s on, 0.2 off, 0.4 on, 2 s quiet) while it rings and before it is lifted.
		var c := fposmod(t - t0, 3.0)
		var on := (c < 0.4 or (c > 0.6 and c < 1.0)) and t >= t0 and t < tl + 0.1
		if on:
			_handset.position = HANDSET_REST + Vector3(0, 0.011 * absf(sin(t * 95.0)), 0)
			_handset.rotation = Vector3(0.04 * sin(t * 83.0), 0, 0.07 * sin(t * 71.0))
		var hid := String(rd.get("hand", ""))
		var actor = ctx["actor"].call(hid) if hid != "" and ctx.has("actor") else null
		# Only while the caller is on screen: once they are gone (a later year) the handset is back on its cradle.
		if actor != null and actor.visible and t > tl - 0.5:
			var inv := gt.affine_inverse()
			var reach := Motion.smooth(Motion.seg(t, tl - 0.5, tl))
			var lift := Motion.in_out(Motion.seg(t, tl, tl + 0.85))
			var rest_local: Vector3 = _phone.transform * HANDSET_REST
			var head: Vector3 = inv * actor.bone_world("Head")
			var yaw := float(actor.rotation.y)
			var right := -Vector3(cos(yaw), 0, -sin(yaw))
			var fwd := Vector3(sin(yaw), 0, cos(yaw))
			# A toon's head is huge and its arms short: the receiver goes against the side of the head at eye level,
			# held out a little, and the arm is lengthened to reach it.
			# The Head bone sits at the neck; the drawn face is far above it. Use the actor's face anchor (eye level
			# on the front of the head) and go back round the side to where an ear would be.
			var face_p: Dictionary = ctx["point"].call(hid + ".face")
			var face: Vector3 = inv * (face_p["pos"] as Vector3) if face_p.has("pos") else head + Vector3(0, 0.3, 0)
			var ear := face + right * 0.3 - fwd * 0.1 + Vector3(0, -0.06, 0)
			Crawl.long_arms(actor, lerpf(1.0, 1.55, maxf(reach, lift)))
			var hold := rest_local.lerp(ear, lift) + Vector3(0, 0.08 * sin(lift * PI), 0)
			actor.aim_hand("r", gt * (hold + Vector3(0, -0.02, 0)), reach, 0.03 * lift)
			if lift > 0.0:
				_handset.position = inv_ph * hold
				_handset.rotation = Vector3(0, 0, -1.2 * lift) + Vector3(0, -0.35, 0) * lift
	# The coiled cord: from the base's side, sagging to the handset's end, a tight helix along the way.
	var a: Vector3 = _phone.transform * Vector3(0.11, 0.04, -0.06)
	var b: Vector3 = _phone.transform * (_handset.position + Basis.from_euler(_handset.rotation) * Vector3(0.11, -0.01, 0))
	var n := _cord.size()
	var prev := a
	var span := a.distance_to(b)
	for i in n:
		var f := float(i + 1) / n
		var p := a.lerp(b, f) + Vector3(0, -maxf(0.25 - span * 0.6, 0.02) * sin(f * PI), 0)
		var side := Vector3(cos(f * 40.0), 0, sin(f * 40.0)) * 0.008
		p += side
		var seg: MeshInstance3D = _cord[i]
		var d := p - prev
		if d.length() > 0.0001:
			seg.transform = Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())) * Basis.from_scale(Vector3(1, d.length(), 1)), (p + prev) * 0.5)
		prev = p
	return _phone.transform * _handset.position


func _calendar_build(root: Node3D) -> void:
	if _p.get("calendar", {}).is_empty():
		return
	# A nail and a string loop; two pages (the one underneath, the one flipping), hung from the top edge.
	Kit.ball(root, 0.008, CAL_AT + Vector3(0, CAL_SIZE.y * 0.5 + 0.05, 0.01), Kit.mat("#8a8a86", 0.4, 0.6), 8)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Georgia", "Times New Roman", "serif"])
	font.font_weight = 700
	var plain := SystemFont.new()
	plain.font_names = PackedStringArray(["Arial", "Helvetica", "sans-serif"])
	plain.font_weight = 600
	for k in 2:
		var pivot := Node3D.new()
		pivot.position = CAL_AT + Vector3(0, CAL_SIZE.y * 0.5, 0.004 * (k + 1))   # page 1 (the top one) in front
		root.add_child(pivot)
		var sheet := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = CAL_SIZE
		sheet.mesh = qm
		var m := Kit.shader(CAL_PRINT)
		sheet.material_override = m
		sheet.position = Vector3(0, -CAL_SIZE.y * 0.5, 0)
		pivot.add_child(sheet)
		# The month flush left, the year flush right (long names like SEPTEMBER never run into it).
		var month := _label(pivot, font, 0.024, Color(0.1, 0.1, 0.12), Vector3(-CAL_SIZE.x * 0.5 + 0.03, -CAL_SIZE.y * 0.545, 0.001))
		month.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var year := _label(pivot, font, 0.04, Color(0.72, 0.08, 0.08), Vector3(CAL_SIZE.x * 0.5 - 0.03, -CAL_SIZE.y * 0.545, 0.001))
		year.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var heads := []
		var names := ["S", "M", "T", "W", "T", "F", "S"]
		for d in 7:
			var hl := _label(pivot, plain, 0.016, Color(0.72, 0.08, 0.08) if d == 0 else Color(0.2, 0.2, 0.22), _cell(d, -1))
			hl.text = names[d]
			heads.append(hl)
		var days := []
		for i in 42:
			days.append(_label(pivot, plain, 0.02, Color(0.15, 0.15, 0.17), _cell(i % 7, i / 7)))
		_cal_pages.append([pivot, {"month": month, "year": year, "days": days}, m])


func _cell(col: int, row: int) -> Vector3:
	var x0 := -CAL_SIZE.x * 0.5 + 0.045
	var w := (CAL_SIZE.x - 0.09) / 6.0
	return Vector3(x0 + w * col, -CAL_SIZE.y * 0.66 - 0.042 * row, 0.001)


func _label(parent: Node3D, font: Font, h: float, col: Color, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.font = font
	l.font_size = 64
	l.pixel_size = h / 48.0
	l.modulate = col
	l.outline_size = 0
	l.shaded = true
	l.double_sided = false
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	l.position = pos
	parent.add_child(l)
	return l


## Show month index `mi` (months since Jan 1900) on page k: name, year, the date grid from the right weekday.
func _cal_show(k: int, mi: int) -> void:
	var page: Array = _cal_pages[k]
	var lab: Dictionary = page[1]
	var y := mi / 12
	var m := mi % 12
	(lab["month"] as Label3D).text = MONTHS[m]
	(lab["year"] as Label3D).text = str(y)
	var first := Time.get_unix_time_from_datetime_dict({"year": y, "month": m + 1, "day": 1, "hour": 12})
	var wd := int(Time.get_datetime_dict_from_unix_time(first)["weekday"])
	var ny := y + (1 if m == 11 else 0)
	var nm := 1 if m == 11 else m + 2
	var nfirst := Time.get_unix_time_from_datetime_dict({"year": ny, "month": nm, "day": 1, "hour": 12})
	var ndays := int(round(float(nfirst - first) / 86400.0))
	var days: Array = lab["days"]
	for i in 42:
		var dnum := i - wd + 1
		(days[i] as Label3D).text = str(dnum) if dnum >= 1 and dnum <= ndays else ""
		(days[i] as Label3D).modulate = Color(0.72, 0.08, 0.08) if i % 7 == 0 else Color(0.15, 0.15, 0.17)
	(page[2] as ShaderMaterial).set_shader_parameter("variant", float(mi % 7))


func _pose_calendar(t: float) -> void:
	var cd: Dictionary = _p.get("calendar", {})
	if cd.is_empty():
		return
	var fr: Array = cd.get("from", [1995, 12])
	var to: Array = cd.get("to", [1998, 3])
	var m0 := int(fr[0]) * 12 + int(fr[1]) - 1
	var m1 := int(to[0]) * 12 + int(to[1]) - 1
	var fl: Array = cd.get("flip", [1e9, 1e9])
	# Pages flip faster and faster, then the last one settles.
	var u := Motion.seg(t, float(fl[0]), float(fl[1]))
	var pos := float(m1 - m0) * pow(u, 1.6)
	var i := mini(int(floorf(pos)), m1 - m0)
	var f: float = pos - floorf(pos) if i < m1 - m0 else 0.0
	_cal_show(0, m0 + mini(i + 1, m1 - m0))     # underneath: the next month
	_cal_show(1, m0 + i)                          # on top: this month, flipping up over the top edge
	var top: Node3D = (_cal_pages[1] as Array)[0]
	var under: Node3D = (_cal_pages[0] as Array)[0]
	# Landed: the top page simply rests on the last month (no visibility switch on the landing frame).
	top.rotation.x = -PI * 0.92 * Motion.in_cubic(f)
	top.visible = true
	under.visible = true


## Type laid flat on the page; shrunk to `max_w` metres wide if it would run off the page.
func _flat_text(parent: Node3D, s: String, font: Font, height: float, col: Color, pos: Vector3, max_w: float = PAPER.x - 0.03) -> void:
	if s == "":
		return
	var l := Label3D.new()
	l.text = s
	l.font = font
	l.font_size = 96
	l.pixel_size = height / 70.0
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 96).x * l.pixel_size
	if w > max_w:
		l.pixel_size *= max_w / w
	l.modulate = col
	l.outline_size = 0
	l.shaded = true
	l.double_sided = false
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	l.position = pos
	l.rotation = Vector3(-PI / 2, 0, 0)
	parent.add_child(l)


func _pose_chair(gt: Transform3D, ctx: Dictionary) -> void:
	var ids = _p.get("sitter", "")
	var actor = null
	for id in (ids if ids is Array else [ids]):
		var a = ctx["actor"].call(String(id)) if String(id) != "" and ctx.has("actor") else null
		if a != null and a.visible:
			actor = a
	if actor == null:
		return
	var inv := gt.affine_inverse()
	var yaw := float(actor.rotation.y) - gt.basis.get_euler().y
	var fwd := Vector3(sin(yaw), 0, cos(yaw))
	var hip: Vector3 = inv * ((actor.bone_world("thigh_l") + actor.bone_world("thigh_r")) * 0.5)
	var seat := hip - fwd * 0.08
	seat.y = hip.y - 0.095
	_chair_top.position = seat
	_chair_top.rotation = Vector3(0, yaw, 0)
	_chair_base.position = Vector3(seat.x, 0, seat.z)
	_chair_base.rotation = Vector3(0, yaw, 0)
	_chair_base.scale = Vector3(1, maxf(seat.y - 0.09, 0.1) / 0.42, 1)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	_pose_chair(gt, ctx)
	_fan.rotation.y = t * 2.4
	_pose_calendar(t)
	var print_at := _pose_photos(gt, t, ctx)
	var handset_at := _pose_phone(gt, t, ctx)
	var paper_anchor := PAPER_AT
	if _paper:
		var pp: Dictionary = _p.get("paper", {})
		var ts := float(pp.get("slap", 1e9))
		# The slap: the arm swings in high (anticipation lift), whips down, the paper smacks flat on the word,
		# bounces a hair, the hand lets go and pulls back out of frame.
		var from := Vector3(0.45, TOP + 0.3, 0.75)
		var lift := Vector3(0.1, TOP + 0.2, 0.2)
		var land := PAPER_AT
		var p0 := Motion.seg(t, ts - 0.5, ts - 0.12)
		var p1 := Motion.seg(t, ts - 0.12, ts)
		var pos: Vector3
		var tilt := 0.0
		if t < ts:
			pos = from.lerp(lift, Motion.out_cubic(p0))
			pos = pos.lerp(land + Vector3(0, 0.002, 0), Motion.in_cubic(p1))
			tilt = lerpf(0.9, 0.0, Motion.in_cubic(p1)) * Motion.smooth(p0)
		else:
			pos = land + Vector3(0, 0.006 * maxf(Motion.impact(t - ts, 0.6, 7.0, 14.0), 0.0), 0)
		_paper.visible = t > ts - 0.55
		_paper.position = pos
		_paper.rotation = Vector3(tilt, 0.12 - 0.12 * Motion.smooth(p1), 0)
		# The hand holds the near edge until the slap, then rises and leaves.
		var grip := pos + Vector3(0.02, 0.03, PAPER.y * 0.5 - 0.01)
		var away := Motion.smooth(Motion.seg(t, ts + 0.06, ts + 0.42))
		var hand := grip.lerp(Vector3(0.3, TOP + 0.5, 1.2), away)
		var shoulder := Vector3(0.45, TOP + 0.75, 1.55)
		_hand.visible = _paper.visible and away < 0.99
		_arm_upper.visible = _hand.visible
		_hand.position = hand
		var d := hand - shoulder
		_arm_upper.transform = Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())) * Basis.from_scale(Vector3(1, d.length(), 1)), (hand + shoulder) * 0.5)
		# The desk jumps a little: the files and the phone rattle on the slap.
		for j in _jiggle:
			var n: Node3D = j[0]
			var base: Vector3 = j[1]
			var k := float(j[2])
			var hit := maxf(Motion.impact(t - ts - 0.01 * k, 0.5, 9.0, 16.0), 0.0) if t > ts else 0.0
			n.position = base + Vector3(0, 0.004 * hit, 0)
		paper_anchor = pos
	return {"desk": gt * Vector3(0, TOP, 0), "paper": gt * paper_anchor, "chair": gt * (_chair_top.position + Vector3(0, 0.4, 0)),
		"phone_black": gt * Vector3(-0.62, TOP + 0.1, -0.12), "phone_beige": gt * Vector3(-0.42, TOP + 0.08, -0.3),
		"window": gt * Vector3(-ROOM.x * 0.5, 2.2, -0.3), "flag": gt * Vector3(0.82, TOP + 0.3, -0.3),
		"print": gt * print_at, "handset": gt * handset_at, "calendar": gt * CAL_AT}
