extends RefCounted
## ISRO Satellite Centre, Bengaluru: (a) the engineer's office at night, (b) the clean room where MOM is built.
##
## (a) Office, local frame: 4.4 x 4.4 m, the window wall at z +2 (window x -1..1, y 1..2.3, a painted steel
##     grille), the desk against it at z 1.25 (top 0.76), the engineer's chair at z 0.55 facing +Z. Back wall
##     z -2.4: a grey steel almirah, a whiteboard of orbit sketches. Left wall (x -2.2): the wall calendar.
##     Right wall (x +2.2): a framed photo of the Moon (Chandrayaan-1, 2008). A tube light, a ceiling fan.
##     Outside: Bengaluru at night (far windows, tree silhouettes); the look's sky shows the Moon and Mars.
## (b) Clean room at x +40: white walls, ceiling filter panels, a pale green epoxy floor with yellow lines,
##     MOM on its handling stand, technicians in coveralls.
##
## params (scene seconds):
##   file      {"drop", "untie", "stamp"}       a file tied with red string lands; untied; APPROVED stamped
##   orrery    t                                  the brass orrery spins up (Earth and Mars line up)
##   calendar  [t0, t1]                           pages flip from NOVEMBER 2013 on to 2016
##   build     [t0, t1]                           the clean-room time-lapse: MOM goes from bare frame to finished
##   cash      t,  gravity  t                     the scale: a bundle of notes, then GRAVITY's film can and clapper
##   gulel     {"t", "actor"}                     a catapult out of the drawer, band pulled back
##   diya      t                                  a lit diya on the sill
## anchors: desk, file, orrery, calendar, scale, gulel, window, sill, photo, mom_clean, clean

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Paths = preload("res://scripts/core/paths.gd")

const CLEAN := Vector3(40, 0, 0)
const DESK_Y := 0.76
const SCALE_K := 1.6
const SCALE_YAW := PI / 2   # the beam runs along z: seen broadside from the right wall

const PLASTER := """
shader_type spatial;
uniform vec3 base : source_color = vec3(0.72, 0.78, 0.7);
uniform vec3 dado : source_color = vec3(0.42, 0.5, 0.44);
uniform float dado_h = 1.1;
varying vec3 wp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = fbm(wp * 3.0);
	vec3 col = mix(dado, base, step(dado_h, wp.y - floor(wp.y / 100.0) * 100.0));
	col *= 0.88 + 0.16 * n;
	col *= 1.0 - 0.25 * smoothstep(0.65, 0.85, fbm(wp * vec3(1.5, 6.0, 1.5) + 4.0));
	col = mix(col, col * 0.7, smoothstep(0.02, 0.0, abs(wp.y - dado_h)));
	ALBEDO = col;
	ROUGHNESS = 0.92;
}
"""

const TILE := """
shader_type spatial;
varying vec3 wp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	// Grey Kota stone slabs, 0.6 m, polished by years of chappals.
	vec2 c = floor(wp.xz / 0.6);
	vec2 f = fract(wp.xz / 0.6);
	float seam = 1.0 - step(0.012, f.x) * step(0.012, f.y);
	vec3 col = vec3(0.38, 0.42, 0.38) * (0.85 + 0.2 * h3(vec3(c, 1.0))) * (0.9 + 0.15 * fbm(wp * 6.0));
	ALBEDO = mix(col, col * 0.5, seam);
	ROUGHNESS = 0.35;
	SPECULAR = 0.6;
}
"""

const EPOXY := """
shader_type spatial;
varying vec3 wp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 col = vec3(0.62, 0.74, 0.66) * (0.95 + 0.06 * fbm(wp * 2.0));
	vec2 lp = wp.xz - vec2(40.0, 0.0);
	float lane = step(abs(abs(lp.x) - 3.2), 0.05) + step(abs(abs(lp.y) - 3.2), 0.05) * step(abs(lp.x), 3.25);
	col = mix(col, vec3(0.95, 0.78, 0.15), clamp(lane, 0.0, 1.0));
	ALBEDO = col;
	ROUGHNESS = 0.18;
	SPECULAR = 0.7;
}
"""

## A whiteboard: off-white with marker sketches (Earth, nested ellipses, an arrow to Mars).
const BOARD := """
shader_type spatial;
varying vec2 uv2;
void vertex() { uv2 = UV; }
float ring(vec2 p, vec2 r, float w) { return 1.0 - smoothstep(0.0, w, abs(length(p / r) - 1.0)); }
void fragment() {
	vec2 p = (uv2 - vec2(0.35, 0.5)) * vec2(1.7, 1.0);
	vec3 col = vec3(0.93, 0.94, 0.95);
	float ink = 0.0;
	ink += ring(p, vec2(0.05), 0.08);
	for (int i = 0; i < 5; i++) { float k = 1.0 + float(i) * 0.45; ink += ring(p + vec2(0.06 * k, 0.0), vec2(0.12 * k, 0.07 * k), 0.025); }
	vec2 q = uv2 - vec2(0.86, 0.32);
	ink += 1.0 - smoothstep(0.035, 0.045, length(q));
	float arrow = 1.0 - smoothstep(0.0, 0.006, abs((uv2.y - 0.5) - (uv2.x - 0.62) * -0.75));
	ink += arrow * step(0.62, uv2.x) * step(uv2.x, 0.84);
	col = mix(col, vec3(0.12, 0.22, 0.6), clamp(ink, 0.0, 1.0) * 0.85);
	col = mix(col, vec3(0.75, 0.12, 0.1), (1.0 - smoothstep(0.035, 0.045, length(q))) * 0.9);
	ALBEDO = col;
	ROUGHNESS = 0.25;
	SPECULAR = 0.6;
}
"""

static var _mom_gd: GDScript

var _p := {}
var _file: Node3D
var _file_cover: Node3D
var _string: Node3D
var _stamp: Node3D
var _stamp_mark: Node3D
var _orrery_arms: Array = []
var _cal_pages: Array = []
var _cal_label: Label3D
var _fan: Node3D
var _scale_beam: Node3D
var _pans: Array = []
var _cash: Node3D
var _gravity: Node3D
var _gulel: Node3D
var _band: MeshInstance3D
var _diya: Node3D
var _mom_clean: Node3D
var _mom_parts: Array = []
var _techs: Array = []


static func mom_script() -> GDScript:
	if _mom_gd == null:
		_mom_gd = GDScript.new()
		_mom_gd.source_code = FileAccess.get_file_as_string(Paths.repo_path("episodes/mangalyaan/gags/mom_model.gd"))
		_mom_gd.reload()
	return _mom_gd


func validate(g: Dictionary) -> Array:
	var e := []
	for k in g.get("params", {}):
		if not (k in ["file", "orrery", "calendar", "build", "cash", "gravity", "gulel", "diya"]):
			e.append("isro_lab: unknown param '%s'" % k)
	return e


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	_office(root)
	_outside(root)
	_desk(root)
	_walls_dressing(root)
	_scale(root)
	_cleanroom(root)
	return root


# --- the office ---------------------------------------------------------------------

func _office(root: Node3D) -> void:
	var wall := Kit.shader(PLASTER)
	Kit.box(root, Vector3(4.4, 0.1, 4.4), Vector3(0, -0.05, -0.2), Kit.shader(TILE))
	Kit.box(root, Vector3(4.4, 0.1, 4.4), Vector3(0, 3.05, -0.2), Kit.mat("#d9d6cc", 0.95))
	Kit.box(root, Vector3(0.12, 3.1, 4.4), Vector3(-2.2, 1.5, -0.2), wall)
	Kit.box(root, Vector3(0.12, 3.1, 4.4), Vector3(2.2, 1.5, -0.2), wall)
	Kit.box(root, Vector3(4.4, 3.1, 0.12), Vector3(0, 1.5, -2.4), wall)
	# Window wall at z 2 with an opening x -1..1, y 1..2.3.
	Kit.box(root, Vector3(1.2, 3.1, 0.2), Vector3(-1.6, 1.5, 2.0), wall)
	Kit.box(root, Vector3(1.2, 3.1, 0.2), Vector3(1.6, 1.5, 2.0), wall)
	Kit.box(root, Vector3(2.0, 1.0, 0.2), Vector3(0, 0.5, 2.0), wall)
	Kit.box(root, Vector3(2.0, 0.8, 0.2), Vector3(0, 2.7, 2.0), wall)
	var sill := Kit.mat("#8f8a80", 0.6)
	Kit.box(root, Vector3(2.2, 0.05, 0.36), Vector3(0, 1.0, 2.02), sill)
	# Steel window frame with two open shutters and the green-painted grille (bars + a diamond band).
	var green := Kit.mat("#2f5a3e", 0.55, 0.0, 0.6)
	for x in range(-9, 10, 3):
		Kit.box(root, Vector3(0.025, 1.3, 0.025), Vector3(float(x) * 0.105, 1.65, 2.13), green)
	for y in [1.32, 1.98]:
		Kit.box(root, Vector3(2.0, 0.03, 0.025), Vector3(0, y, 2.13), green)
	for i in 8:
		var x := -0.88 + 0.25 * float(i)
		Kit.box(root, Vector3(0.02, 0.32, 0.02), Vector3(x, 1.65, 2.135), green, Vector3(0, 0, 0.6))
		Kit.box(root, Vector3(0.02, 0.32, 0.02), Vector3(x + 0.12, 1.65, 2.135), green, Vector3(0, 0, -0.6))
	Kit.box(root, Vector3(2.04, 0.05, 0.08), Vector3(0, 2.3, 2.1), green)
	Kit.box(root, Vector3(2.04, 0.05, 0.08), Vector3(0, 1.02, 2.1), green)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.6, 0.7, 0.75, 0.12)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	for s in [-1.0, 1.0]:
		var sh := Node3D.new()
		sh.position = Vector3(s * 1.0, 1.65, 2.02)
		sh.rotation = Vector3(0, s * -1.2, 0)
		root.add_child(sh)
		Kit.box(sh, Vector3(0.5, 1.28, 0.03), Vector3(-s * 0.25, 0, 0), glass)
		Kit.box(sh, Vector3(0.5, 0.04, 0.04), Vector3(-s * 0.25, 0.62, 0), green)
		Kit.box(sh, Vector3(0.5, 0.04, 0.04), Vector3(-s * 0.25, -0.62, 0), green)
	# Tube light on the back wall above the almirah, a ceiling fan.
	Kit.box(root, Vector3(1.22, 0.035, 0.035), Vector3(0, 2.62, -2.3), Kit.lit("#eef6ff", 3.0))
	Kit.box(root, Vector3(1.3, 0.04, 0.06), Vector3(0, 2.62, -2.33), Kit.mat("#e6e4dc", 0.6))
	_fan = Node3D.new()
	_fan.position = Vector3(0, 2.62, -0.2)
	root.add_child(_fan)
	Kit.rod(root, Vector3(0, 3.0, -0.2), Vector3(0, 2.65, -0.2), 0.012, Kit.mat("#7a7a76", 0.5), 8)
	Kit.cyl(_fan, 0.11, 0.11, 0.09, Vector3.ZERO, Kit.mat("#d9d5cb", 0.5), 16)
	for i in 3:
		var a := TAU * float(i) / 3.0
		Kit.box(_fan, Vector3(0.6, 0.008, 0.11), Vector3(cos(a) * 0.38, -0.03, sin(a) * 0.38), Kit.mat("#d9d5cb", 0.5), Vector3(0.08, -a, 0))
	Kit.spot(root, Vector3(0, 2.55, -2.2), Vector3(0, 0.6, 0.8), "#e8f2ff", 1.6, 7.0, 75.0, true, 0.4)
	Kit.omni(root, Vector3(0, 2.0, -0.4), "#d8e4f0", 0.25, 6.0, false, 0.2)


func _outside(root: Node3D) -> void:
	# Far Bengaluru: windows of other buildings, a street light, tree crowns against the sky.
	var r := Kit.rng("city")
	for i in 70:
		var x := r.randf_range(-60.0, 60.0)
		var y := r.randf_range(1.0, 14.0)
		var z := r.randf_range(35.0, 120.0)
		var c := Color("ffd59a") if r.randf() < 0.7 else Color("cfe6ff")
		Kit.box(root, Vector3(0.9, 0.6, 0.05), Vector3(x, y, z), Kit.lit(c, r.randf_range(0.6, 2.2)))
	for i in 9:
		var x := -14.0 + 3.6 * float(i) + r.randf_range(-1.0, 1.0)
		var z := r.randf_range(20.0, 30.0)
		Kit.rod(root, Vector3(x * 1.8, -2.0, z), Vector3(x * 1.8, 1.5, z), 0.2, Kit.mat("#0b0d0c", 0.9), 6)
		for k in 4:
			Kit.ball(root, r.randf_range(1.4, 2.2), Vector3(x * 1.8 + r.randf_range(-1.5, 1.5), r.randf_range(1.8, 3.2), z + r.randf_range(-1, 1)),
				Kit.mat("#070a09", 0.95), 10)
	Kit.box(root, Vector3(200, 0.2, 200), Vector3(0, -2.0, 80), Kit.mat("#050606", 0.95))


func _desk(root: Node3D) -> void:
	var steel := Kit.mat("#5d646b", 0.45, 0.0, 0.6)
	var top := Kit.mat("#1f3a2c", 0.3, 0.0, 0.7)
	# Government steel desk with a green top under glass, a drawer pedestal.
	Kit.box(root, Vector3(1.6, 0.04, 0.8), Vector3(0, DESK_Y, 1.3), top)
	Kit.box(root, Vector3(1.6, 0.012, 0.8), Vector3(0, DESK_Y + 0.026, 1.3), Kit.mat(Color(0.8, 0.9, 0.9, 0.18), 0.05, 0.0, 0.9))
	Kit.box(root, Vector3(0.45, 0.72, 0.75), Vector3(0.55, 0.37, 1.3), steel)
	for i in 3:
		Kit.box(root, Vector3(0.4, 0.2, 0.01), Vector3(0.55, 0.62 - 0.23 * i, 0.925), Kit.mat("#666e75", 0.45))
		Kit.box(root, Vector3(0.1, 0.015, 0.02), Vector3(0.55, 0.62 - 0.23 * i, 0.915), Kit.mat("#b8bdc2", 0.3))
	Kit.rod(root, Vector3(-0.75, 0, 0.95), Vector3(-0.75, DESK_Y, 0.95), 0.02, steel)
	Kit.rod(root, Vector3(-0.75, 0, 1.65), Vector3(-0.75, DESK_Y, 1.65), 0.02, steel)
	# Chair (wooden, cane-backed office chair).
	var wood := Kit.mat("#5a3a22", 0.6)
	for x in [-0.22, 0.22]:
		for z in [0.35, 0.75]:
			Kit.rod(root, Vector3(x, 0, z), Vector3(x, 0.45, z), 0.02, wood, 6)
	Kit.box(root, Vector3(0.5, 0.04, 0.46), Vector3(0, 0.46, 0.55), wood)
	Kit.box(root, Vector3(0.5, 0.5, 0.03), Vector3(0, 0.75, 0.32), Kit.mat("#b99d6b", 0.8), Vector3(-0.12, 0, 0))
	# Monitor, keyboard, landline phone, steel tumbler, a stack of files, a pen stand, a table lamp.
	Kit.slab(root, Vector3(0.52, 0.03, 0.32), 0.01, Vector3(-0.42, DESK_Y + 0.3, 1.6), Kit.mat("#141518", 0.4), Vector3(PI / 2 - 0.12, 0, 0))
	var scr := Kit.quad(root, Vector2(0.48, 0.28), Vector3(-0.42, DESK_Y + 0.3, 1.583), Kit.lit("#7fa9d8", 0.9), Vector3(-0.12, PI, 0))
	scr.rotation = Vector3(0.12, PI, 0)
	Kit.box(root, Vector3(0.06, 0.16, 0.06), Vector3(-0.42, DESK_Y + 0.1, 1.65), Kit.mat("#141518", 0.4))
	Kit.box(root, Vector3(0.42, 0.02, 0.14), Vector3(-0.42, DESK_Y + 0.04, 1.3), Kit.mat("#d8d6cf", 0.6))
	Kit.slab(root, Vector3(0.2, 0.08, 0.22), 0.04, Vector3(0.66, DESK_Y + 0.05, 1.6), Kit.mat("#24252a", 0.4))
	Kit.cyl(root, 0.035, 0.03, 0.11, Vector3(0.68, DESK_Y + 0.07, 1.05), Kit.mat("#c9ccd0", 0.2, 0.0, 0.9), 16)
	for i in 5:
		Kit.box(root, Vector3(0.26, 0.035, 0.34), Vector3(-0.66, DESK_Y + 0.04 + 0.036 * i, 1.0), Kit.mat(["#c9a66b", "#b9905a", "#d4b37a"][i % 3], 0.85),
			Vector3(0, 0.05 * float(i % 2) - 0.03, 0))
	var lamp := Node3D.new()
	lamp.position = Vector3(-0.68, DESK_Y + 0.02, 1.58)
	root.add_child(lamp)
	Kit.cyl(lamp, 0.07, 0.08, 0.03, Vector3.ZERO, Kit.mat("#1d2a20", 0.4), 16)
	Kit.rod(lamp, Vector3(0, 0, 0), Vector3(0.05, 0.38, -0.08), 0.01, Kit.mat("#1d2a20", 0.4), 6)
	Kit.cyl(lamp, 0.04, 0.09, 0.12, Vector3(0.1, 0.36, -0.08), Kit.mat("#1d2a20", 0.4), 16, Vector3(0.5, 0, -0.6))
	Kit.spot(root, Vector3(-0.58, DESK_Y + 0.33, 1.5), Vector3(-0.2, DESK_Y, 1.15), "#ffc27a", 1.6, 2.2, 55.0, true, 0.2)
	# The file (with red string), for the approval.
	_file = Node3D.new()
	root.add_child(_file)
	Kit.box(_file, Vector3(0.25, 0.012, 0.34), Vector3.ZERO, Kit.mat("#e2c68c", 0.85))
	Kit.box(_file, Vector3(0.24, 0.02, 0.33), Vector3(0, -0.012, 0), Kit.mat("#f2eee2", 0.9))
	_file_cover = Node3D.new()
	_file_cover.position = Vector3(-0.125, 0.008, 0)
	_file.add_child(_file_cover)
	Kit.box(_file_cover, Vector3(0.25, 0.006, 0.34), Vector3(0.125, 0, 0), Kit.mat("#d9b878", 0.85))
	Kit.text(_file_cover, "MARS ORBITER MISSION", 0.022, Color("3a2a18"), Vector3(0.125, 0.004, -0.06), Vector3(-PI / 2, PI, 0), true)
	Kit.text(_file_cover, "PROPOSAL", 0.018, Color("3a2a18"), Vector3(0.125, 0.004, -0.1), Vector3(-PI / 2, PI, 0), false)
	_string = Node3D.new()
	_file.add_child(_string)
	Kit.box(_string, Vector3(0.006, 0.03, 0.35), Vector3(0.0, 0.0, 0), Kit.mat("#b0201c", 0.7))
	Kit.box(_string, Vector3(0.26, 0.03, 0.006), Vector3(0.0, 0.0, 0), Kit.mat("#b0201c", 0.7))
	Kit.ball(_string, 0.016, Vector3(0, 0.014, 0), Kit.mat("#b0201c", 0.7), 8)
	_stamp = Node3D.new()
	root.add_child(_stamp)
	Kit.cyl(_stamp, 0.03, 0.035, 0.07, Vector3(0, 0.06, 0), Kit.mat("#3b2416", 0.5), 12)
	Kit.ball(_stamp, 0.035, Vector3(0, 0.11, 0), Kit.mat("#3b2416", 0.5), 12)
	Kit.box(_stamp, Vector3(0.11, 0.025, 0.05), Vector3(0, 0.012, 0), Kit.mat("#2a2a2c", 0.6))
	_stamp_mark = Node3D.new()
	_file_cover.add_child(_stamp_mark)
	var mark := Kit.text(_stamp_mark, "APPROVED", 0.034, Color("b51d1a"), Vector3(0.0, 0.0, 0.0), Vector3(-PI / 2, PI, -0.18), true)
	mark.outline_size = 0
	# The orrery: a brass sun on a stand, Earth and Mars on arms.
	var orr := Node3D.new()
	orr.position = Vector3(0.18, DESK_Y + 0.02, 1.58)
	root.add_child(orr)
	var brass := Kit.mat("#b98a34", 0.28, 0.0, 0.9)
	Kit.cyl(orr, 0.07, 0.09, 0.03, Vector3.ZERO, Kit.mat("#3b2a1c", 0.5), 20)
	Kit.rod(orr, Vector3.ZERO, Vector3(0, 0.2, 0), 0.008, brass, 8)
	Kit.ball(orr, 0.035, Vector3(0, 0.22, 0), Kit.lit("#ffcf6a", 0.35), 16)
	for spec in [[0.11, 0.016, "#3d6fd6", 0.2], [0.17, 0.012, "#c4532c", 0.205]]:
		var arm := Node3D.new()
		arm.position = Vector3(0, float(spec[3]), 0)
		orr.add_child(arm)
		Kit.rod(arm, Vector3.ZERO, Vector3(float(spec[0]), 0, 0), 0.003, brass, 6)
		Kit.ball(arm, float(spec[1]), Vector3(float(spec[0]), 0, 0), Kit.mat(String(spec[2]), 0.45), 12)
		_orrery_arms.append(arm)
	# The catapult (gulel) in the open drawer: a Y of wood with a rubber band and a leather pouch.
	_gulel = Node3D.new()
	_gulel.scale = Vector3.ONE * 1.8
	root.add_child(_gulel)
	var gwood := Kit.mat("#9a6a3a", 0.55)
	Kit.rod(_gulel, Vector3(0, -0.1, 0), Vector3(0, 0, 0), 0.012, gwood, 8)
	Kit.rod(_gulel, Vector3(0, 0, 0), Vector3(-0.045, 0.07, 0), 0.01, gwood, 8)
	Kit.rod(_gulel, Vector3(0, 0, 0), Vector3(0.045, 0.07, 0), 0.01, gwood, 8)
	_band = MeshInstance3D.new()
	_gulel.add_child(_band)
	_band.material_override = Kit.mat("#9a5a2a", 0.6)
	for k in 2:
		var b := Kit.rod(_gulel, Vector3.ZERO, Vector3(0, 0.1, 0), 0.0045, Kit.mat("#c4492e", 0.5), 6)
		b.name = "band_%d" % k
	var pouch := Kit.ball(_gulel, 0.016, Vector3.ZERO, Kit.mat("#5a3a22", 0.7), 10, Vector3(1.3, 0.8, 1))
	pouch.name = "pouch"
	# The diya: a clay lamp with a flame.
	_diya = Node3D.new()
	_diya.position = Vector3(-0.35, 1.03, 1.95)
	root.add_child(_diya)
	Kit.ball(_diya, 0.045, Vector3.ZERO, Kit.mat("#a5532a", 0.8), 12, Vector3(1, 0.4, 1))
	Kit.ball(_diya, 0.012, Vector3(0, 0.035, 0), Kit.lit("#ffb547", 6.0), 8, Vector3(1, 1.8, 1))
	Kit.omni(_diya, Vector3(0, 0.1, -0.05), "#ffad52", 0.35, 2.0, false, 0.3)


func _walls_dressing(root: Node3D) -> void:
	# Steel almirah, whiteboard, calendar, the Moon photo, a clock, an ISRO poster.
	var grey := Kit.mat("#6f757a", 0.45, 0.0, 0.6)
	Kit.box(root, Vector3(0.9, 1.9, 0.48), Vector3(-1.4, 0.95, -2.1), grey)
	Kit.box(root, Vector3(0.006, 1.8, 0.01), Vector3(-1.4, 0.95, -1.855), Kit.mat("#4a4f53", 0.5))
	Kit.box(root, Vector3(0.03, 0.12, 0.02), Vector3(-1.37, 1.0, -1.85), Kit.mat("#c9ccd0", 0.3))
	Kit.box(root, Vector3(1.5, 0.95, 0.03), Vector3(0.65, 1.6, -2.33), Kit.mat("#c9cdd2", 0.4))
	Kit.quad(root, Vector2(1.42, 0.87), Vector3(0.65, 1.6, -2.31), Kit.shader(BOARD))
	# Calendar on the left wall: a big printed page (month name, year, a grid of dates) on a nail.
	var cal := Node3D.new()
	cal.position = Vector3(-2.13, 1.55, 0.35)
	cal.rotation = Vector3(0, PI / 2, 0)
	root.add_child(cal)
	Kit.box(cal, Vector3(0.44, 0.6, 0.006), Vector3(0, 0, -0.004), Kit.mat("#c33a2a", 0.7))
	for i in 12:
		var page := Node3D.new()
		page.position = Vector3(0, 0.29, 0.003 + 0.0015 * (12 - i))
		cal.add_child(page)
		Kit.box(page, Vector3(0.42, 0.5, 0.002), Vector3(0, -0.27, 0), Kit.mat("#f4f1e8", 0.85))
		_cal_pages.append(page)
	_cal_label = Kit.text(cal, "NOVEMBER 2013", 0.045, Color("b8251c"), Vector3(0, 0.18, 0.03), Vector3.ZERO, true)
	for r in 5:
		for c in 7:
			Kit.text(cal, str(r * 7 + c - 4) if r * 7 + c - 4 > 0 and r * 7 + c - 4 <= 30 else "", 0.03, Color("2a2a2a"),
				Vector3(-0.17 + c * 0.057, 0.08 - r * 0.075, 0.03), Vector3.ZERO, false)
	# A red circle round the 5th.
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.026
	tm.outer_radius = 0.032
	ring.mesh = tm
	ring.material_override = Kit.mat("#d01c1c", 0.6)
	ring.rotation = Vector3(PI / 2, 0, 0)
	ring.position = Vector3(-0.17 + 1 * 0.057, 0.093 - 1 * 0.075, 0.032)
	ring.name = "circle"
	cal.add_child(ring)
	# The Moon photo on the right wall (Chandrayaan-1, 2008): a framed print of the Moon.
	var ph := Node3D.new()
	ph.position = Vector3(2.13, 1.6, 0.6)
	ph.rotation = Vector3(0, -PI / 2, 0)
	root.add_child(ph)
	Kit.box(ph, Vector3(0.5, 0.42, 0.03), Vector3.ZERO, Kit.mat("#2a1c12", 0.5))
	Kit.quad(ph, Vector2(0.44, 0.36), Vector3(0, 0, 0.017), Kit.mat("#0c0c0e", 0.7))
	Kit.ball(ph, 0.13, Vector3(0, 0.01, 0.0), Kit.mat("#b9b6ae", 0.85), 24, Vector3(1, 1, 0.12))
	Kit.text(ph, "CHANDRAYAAN-1 · 2008", 0.022, Color("dedad0"), Vector3(0, -0.155, 0.02), Vector3.ZERO, false)
	# ISRO logo poster above the desk, beside the window.
	var logo := StandardMaterial3D.new()
	logo.albedo_texture = Kit.texture("library/logos/isro.svg", false, 2.0)
	logo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	logo.alpha_scissor_threshold = 0.5
	Kit.box(root, Vector3(0.5, 0.5, 0.01), Vector3(1.55, 2.0, 1.89), Kit.mat("#f3f1ea", 0.8))
	Kit.quad(root, Vector2(0.42, 0.42), Vector3(1.55, 2.0, 1.883), logo, Vector3(0, PI, 0))


## The brass balance on the desk, right side: pans at y DESK_Y + 0.42.
func _scale(root: Node3D) -> void:
	var at := Vector3(0.55, DESK_Y + 0.02, 1.2)
	var n := Node3D.new()
	n.position = at
	n.name = "scale"
	n.scale = Vector3.ONE * SCALE_K
	n.rotation = Vector3(0, SCALE_YAW, 0)
	root.add_child(n)
	var brass := Kit.mat("#c99a3a", 0.25, 0.0, 0.9)
	Kit.cyl(n, 0.08, 0.1, 0.03, Vector3(0, 0.015, 0), brass, 24)
	Kit.rod(n, Vector3(0, 0, 0), Vector3(0, 0.42, 0), 0.008, brass, 8)
	_scale_beam = Node3D.new()
	_scale_beam.position = Vector3(0, 0.42, 0)
	n.add_child(_scale_beam)
	Kit.box(_scale_beam, Vector3(0.5, 0.014, 0.014), Vector3.ZERO, brass)
	Kit.ball(_scale_beam, 0.02, Vector3.ZERO, brass, 12)
	for s in [-1.0, 1.0]:
		var pan := Node3D.new()
		pan.scale = Vector3.ONE * SCALE_K
		root.add_child(pan)
		for k in 3:
			var a := TAU * float(k) / 3.0
			var rope := Kit.rod(pan, Vector3(0, 0.2, 0), Vector3(cos(a) * 0.075, 0.0, sin(a) * 0.075), 0.002, Kit.mat("#8a7a5a", 0.6), 4)
		Kit.cyl(pan, 0.085, 0.07, 0.015, Vector3.ZERO, brass, 24)
		_pans.append(pan)
	# What goes on the pans: a bundle of notes (left), Gravity's film can and clapperboard (right).
	_cash = Node3D.new()
	_cash.scale = Vector3.ONE * SCALE_K
	root.add_child(_cash)
	for i in 4:
		Kit.box(_cash, Vector3(0.14, 0.012, 0.065), Vector3(0, 0.006 + 0.012 * i, 0), Kit.mat(["#c8b3d6", "#c9a9cf"][i % 2], 0.8), Vector3(0, 0.04 * float(i % 2), 0))
	Kit.box(_cash, Vector3(0.02, 0.052, 0.067), Vector3(0, 0.026, 0), Kit.mat("#e8e2cc", 0.7))
	_gravity = Node3D.new()
	_gravity.scale = Vector3.ONE * SCALE_K
	root.add_child(_gravity)
	Kit.cyl(_gravity, 0.07, 0.07, 0.025, Vector3(0, 0.0125, 0), Kit.mat("#9da3a8", 0.3, 0.0, 0.85), 24)
	Kit.cyl(_gravity, 0.07, 0.07, 0.025, Vector3(0, 0.0375, 0), Kit.mat("#8d9398", 0.3, 0.0, 0.85), 24)
	var clap := Node3D.new()
	clap.position = Vector3(0, 0.1, -0.01)
	clap.rotation = Vector3(-0.25, 0, 0)
	_gravity.add_child(clap)
	Kit.box(clap, Vector3(0.13, 0.09, 0.008), Vector3.ZERO, Kit.mat("#18181b", 0.5))
	Kit.box(clap, Vector3(0.13, 0.02, 0.009), Vector3(0, 0.055, 0), Kit.mat("#efefef", 0.5))
	Kit.text(clap, "GRAVITY", 0.022, Color("f2f2f2"), Vector3(0, 0.012, 0.006), Vector3.ZERO, true)
	Kit.text(clap, "SCENE 1  TAKE 1", 0.012, Color("d0d0d0"), Vector3(0, -0.025, 0.006), Vector3.ZERO, false)


func _cleanroom(root: Node3D) -> void:
	var c := Node3D.new()
	c.position = CLEAN
	root.add_child(c)
	Kit.box(c, Vector3(14, 0.1, 12), Vector3(0, -0.05, 0), Kit.shader(EPOXY))
	var white := Kit.mat("#e9ecef", 0.6)
	for s in [-1.0, 1.0]:
		Kit.box(c, Vector3(0.15, 5, 12), Vector3(s * 7.0, 2.5, 0), white)
		Kit.box(c, Vector3(14, 5, 0.15), Vector3(0, 2.5, s * 6.0), white)
	Kit.box(c, Vector3(14, 0.1, 12), Vector3(0, 5.0, 0), Kit.mat("#d7dbe0", 0.7))
	# Ceiling filter panels (HEPA), lit; wall return grilles.
	for x in range(-5, 6, 2):
		for z in range(-4, 5, 2):
			Kit.box(c, Vector3(1.6, 0.02, 1.6), Vector3(x, 4.94, z), Kit.lit("#f4f8ff", 1.4))
	for x in range(-6, 7, 3):
		Kit.box(c, Vector3(1.0, 0.3, 0.02), Vector3(x, 0.4, -5.92), Kit.mat("#aab1b8", 0.5))
	Kit.spot(c, Vector3(0, 4.8, 2), Vector3(0, 0.8, 0), "#f2f6ff", 3.5, 12.0, 60.0, true, 0.2)
	Kit.spot(c, Vector3(-4, 4.5, -3), Vector3(0, 1.2, 0), "#fff2dc", 2.0, 10.0, 45.0, false, 0.2)
	Kit.omni(c, Vector3(3, 3, 3), "#eaf2ff", 1.0, 10.0, false, 0.1)
	# The handling stand: a steel ring frame on a yellow trolley.
	Kit.box(c, Vector3(2.4, 0.25, 2.4), Vector3(0, 0.3, 0), Kit.mat("#d8b21c", 0.5))
	Kit.cyl(c, 0.9, 1.0, 0.5, Vector3(0, 0.67, 0), Kit.mat("#8b9097", 0.35, 0.0, 0.8), 32)
	for k in 4:
		var a := TAU * float(k) / 4.0 + PI / 4
		Kit.cyl(c, 0.12, 0.12, 0.12, Vector3(cos(a) * 1.0, 0.1, sin(a) * 1.0), Kit.mat("#1b1c20", 0.6), 12, Vector3(PI / 2, 0, 0))
	# A gantry hoist over it; a parts cart; a cable reel; an ISRO banner.
	for s in [-1.0, 1.0]:
		Kit.rod(c, Vector3(s * 3.2, 0, -1.5), Vector3(s * 3.2, 4.2, -1.5), 0.08, Kit.mat("#3a6cb3", 0.4), 10)
	Kit.box(c, Vector3(6.6, 0.25, 0.25), Vector3(0, 4.2, -1.5), Kit.mat("#3a6cb3", 0.4))
	Kit.rod(c, Vector3(0.4, 4.1, -1.5), Vector3(0.4, 3.4, -1.5), 0.01, Kit.mat("#c0c0c0", 0.3), 6)
	Kit.box(c, Vector3(1.0, 0.7, 0.6), Vector3(-3.5, 0.45, 2.0), Kit.mat("#bfc5cc", 0.4, 0.0, 0.8))
	var banner := StandardMaterial3D.new()
	banner.albedo_texture = Kit.texture("library/logos/isro.svg", false, 3.0)
	banner.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	banner.alpha_scissor_threshold = 0.5
	Kit.quad(c, Vector2(1.6, 1.6), Vector3(0, 3.0, -5.9), banner)
	Kit.text(c, "MARS ORBITER MISSION", 0.28, Color("2c3e66"), Vector3(0, 2.05, -5.9), Vector3.ZERO, true)
	# MOM on the stand; its parts appear through the time-lapse.
	_mom_clean = mom_script().new().build(1.0)
	_mom_clean.position = Vector3(0, 1.75, 0)
	_mom_clean.rotation = Vector3(0, 0.6, 0)
	c.add_child(_mom_clean)
	for path in ["hga", "wing", "engine"]:
		_mom_parts.append(_mom_clean.get_node(path))
	var skeleton := Node3D.new()
	skeleton.name = "frame"
	_mom_clean.add_child(skeleton)
	var al := Kit.mat("#b9bec4", 0.35, 0.0, 0.8)
	for x in [-0.72, 0.72]:
		for z in [-0.72, 0.72]:
			Kit.rod(skeleton, Vector3(x, -0.7, z), Vector3(x, 0.7, z), 0.03, al, 6)
	for y in [-0.7, 0.0, 0.7]:
		Kit.box(skeleton, Vector3(1.48, 0.04, 0.04), Vector3(0, y, 0.72), al)
		Kit.box(skeleton, Vector3(1.48, 0.04, 0.04), Vector3(0, y, -0.72), al)
		Kit.box(skeleton, Vector3(0.04, 0.04, 1.48), Vector3(0.72, y, 0), al)
		Kit.box(skeleton, Vector3(0.04, 0.04, 1.48), Vector3(-0.72, y, 0), al)


# --- pose ----------------------------------------------------------------------------

func _t(key: String, sub: String = "", fallback: float = 1e9) -> float:
	var v = _p.get(key, null)
	if v is Dictionary:
		return float(v.get(sub, fallback))
	if v is Array:
		return float(v[0]) if v.size() > 0 else fallback
	return float(v) if v != null else fallback


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	_fan.rotation = Vector3(0, t * 5.5, 0)
	# The file: slides in from off the desk edge, lands with a slap; the string comes off; the stamp.
	var drop := _t("file", "drop")
	var untie := _t("file", "untie")
	var stamp := _t("file", "stamp")
	var rest := Vector3(0.1, DESK_Y + 0.035, 1.12)
	var u := Motion.out_cubic(clampf((t - drop) / 0.35, 0.0, 1.0))
	_file.position = Motion.arc(rest + Vector3(-0.6, 0.35, -0.5), rest, 0.12, u)
	_file.rotation = Vector3(0, lerpf(0.9, 0.08, u), 0)
	_file.visible = t > drop - 0.05
	var sq := Motion.impact(t - drop - 0.35, 0.25) if t > drop + 0.35 else 0.0
	_file.scale = Vector3(1.0 + sq * 0.2, 1.0 - sq, 1.0 + sq * 0.2)
	_string.visible = t < untie + 0.15
	_string.position = Vector3(0, 0.02 * clampf((t - untie) / 0.15, 0.0, 1.0), 0)
	# The stamp: lifts in, slams down on "yes", lifts away leaving the mark.
	var sp := 0.0
	if t < stamp - 0.25:
		sp = 1.0
	elif t < stamp:
		sp = 1.0 - Motion.in_cubic((t - stamp + 0.25) / 0.25)
	else:
		sp = Motion.out_cubic(clampf((t - stamp - 0.25) / 0.4, 0.0, 1.0))
	_stamp.position = rest + Vector3(0.02, 0.02 + 0.22 * sp, 0.05) + Vector3(0.35, 0, -0.2) * maxf(0.0, (sp - 0.6) / 0.4) * float(t > stamp)
	_stamp.visible = t > stamp - 0.7 and t < stamp + 1.2
	_stamp_mark.visible = t >= stamp
	_stamp_mark.position = Vector3(0.12, 0.006, 0.1)
	# The orrery: Earth laps the Sun faster than Mars; they line up on the beat.
	var ot := _t("orrery")
	var spin := 0.0
	if t > ot - 0.3:
		spin = Motion.out_cubic(clampf((t - ot + 0.3) / 2.2, 0.0, 1.0))
	(_orrery_arms[0] as Node3D).rotation = Vector3(0, 0.4 + spin * TAU * 2.0, 0)
	(_orrery_arms[1] as Node3D).rotation = Vector3(0, 0.4 + spin * TAU * 1.0 + PI * (1.0 - spin), 0)
	# The calendar: pages flip up one by one, the month label runs on to 2016.
	var cw = _p.get("calendar", [])
	var months := ["NOVEMBER 2013", "DECEMBER 2013", "JANUARY 2014", "MARCH 2014", "JUNE 2014", "SEPTEMBER 2014",
		"DECEMBER 2014", "APRIL 2015", "AUGUST 2015", "NOVEMBER 2015", "JANUARY 2016"]
	var flips := 0
	if cw is Array and cw.size() >= 2:
		var f := clampf((t - float(cw[0])) / maxf(float(cw[1]) - float(cw[0]), 0.01), 0.0, 1.0)
		flips = int(floor(Motion.in_cubic(f) * float(months.size() - 1)))
		for i in _cal_pages.size():
			var pg: Node3D = _cal_pages[i]
			var pf := clampf(Motion.in_cubic(f) * float(months.size() - 1) - float(i), 0.0, 1.0)
			pg.rotation = Vector3(-PI * 0.95 * Motion.out_cubic(pf), 0, 0)
			pg.visible = true
	_cal_label.text = months[clampi(flips, 0, months.size() - 1)]
	# The scale: cash lands on the left pan, the film on the right; the beam tips to the heavier side.
	var ct := _t("cash")
	var gvt := _t("gravity")
	var tilt := 0.0
	if t > ct:
		tilt = 0.18 * Motion.out_back(clampf((t - ct) / 0.4, 0.0, 1.0)) * (1.0 - clampf((t - gvt) / 0.01, 0.0, 1.0))
	if t > gvt:
		tilt = lerpf(0.18, -0.32, Motion.out_back(clampf((t - gvt) / 0.45, 0.0, 1.0), 2.2)) + 0.03 * Motion.wobble(t - gvt - 0.45, 3.0, 5.0) * float(t > gvt + 0.45)
	elif t > ct:
		tilt += 0.02 * Motion.wobble(t - ct - 0.4, 3.0, 5.0) * float(t > ct + 0.4)
	_scale_beam.rotation = Vector3(0, 0, tilt)
	var scale_on := t > ct - 1.5 and t < gvt + 4.0
	_scale_beam.get_parent().visible = scale_on
	for pan in _pans:
		(pan as Node3D).visible = scale_on
	var sc_at := Vector3(0.55, DESK_Y + 0.02, 1.2)
	for i in 2:
		var s := -1.0 if i == 0 else 1.0
		var tip := Vector3(s * 0.24 * cos(tilt), 0.42 + s * 0.24 * sin(tilt), 0) * SCALE_K
		(_pans[i] as Node3D).position = sc_at + Basis(Vector3.UP, SCALE_YAW) * tip - Vector3(0, 0.2, 0) * SCALE_K
	var lp: Vector3 = (_pans[0] as Node3D).position + Vector3(0, 0.008, 0) * SCALE_K
	var rp: Vector3 = (_pans[1] as Node3D).position + Vector3(0, 0.008, 0) * SCALE_K
	var cu := Motion.out_cubic(clampf((t - ct + 0.3) / 0.3, 0.0, 1.0))
	_cash.position = lp + Vector3(0, 0.25 * (1.0 - cu), 0)
	_cash.visible = t > ct - 0.3 and scale_on
	var gu := Motion.in_cubic(clampf((t - gvt + 0.25) / 0.25, 0.0, 1.0))
	_gravity.position = rp + Vector3(0, 0.3 * (1.0 - gu), 0)
	_gravity.visible = t > gvt - 0.25 and scale_on
	# The gulel: out of the drawer into the left hand, the right hand pulls the band back.
	var gl = _p.get("gulel", null)
	var hold := false
	var pull := 0.0
	if gl is Dictionary:
		var t0 := float(gl.get("t", 1e9))
		var act = ctx.get("actor", null)
		var who = act.call(String(gl.get("actor", ""))) if act else null
		if who and t > t0 - 0.6 and t < t0 + 3.0:
			hold = true
			var hp: Dictionary = ctx["point"].call(String(gl.get("actor", "")) + ".head")
			var head: Vector3 = hp.get("pos", who.bone_world("Head"))
			var fwd := Vector3(sin(who.rotation.y), 0, cos(who.rotation.y))
			var left := Vector3(cos(who.rotation.y), 0, -sin(who.rotation.y))
			var up_u := Motion.out_back(clampf((t - t0 + 0.6) / 0.5, 0.0, 1.0))
			var chest: Vector3 = who.bone_world("spine_03")
			var hold_at := chest + fwd * 0.42 + left * 0.08 + Vector3(0, 0.22 + 0.08 * up_u, 0)
			pull = Motion.in_out(clampf((t - t0 - 0.3) / 0.7, 0.0, 1.0))
			var gp := node.global_transform.affine_inverse() * hold_at
			_gulel.position = gp
			_gulel.basis = Basis.looking_at(-(node.global_transform.basis.inverse() * fwd), Vector3.UP).scaled(Vector3.ONE * 1.8)
			who.aim_hand("l", hold_at + Vector3(0, -0.06, 0), up_u)
			var pouch := hold_at + Vector3(0, 0.05, 0) - fwd * (0.05 + 0.15 * pull) - left * 0.06
			who.aim_hand("r", pouch, up_u)
	_gulel.visible = hold
	if hold:
		var back := Vector3(0, 0.07, 0.04 + 0.13 * pull)
		for k in 2:
			var a := Vector3((-1.0 if k == 0 else 1.0) * 0.045, 0.07, 0)
			var b := _gulel.get_node("band_%d" % k) as MeshInstance3D
			var d := back - a
			var y := d.normalized()
			var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
			b.transform = Transform3D(Basis(x, y * d.length(), y.cross(x)), (a + back) * 0.5)
		(_gulel.get_node("pouch") as Node3D).position = back
	# The diya.
	_diya.visible = t > _t("diya") - 0.2
	# The clean room: the time-lapse.
	var bw = _p.get("build", [])
	var bf := 1.0
	if bw is Array and bw.size() >= 2:
		bf = clampf((t - float(bw[0])) / maxf(float(bw[1]) - float(bw[0]), 0.01), 0.0, 1.0)
	var bus := _mom_clean.get_node("bus") as Node3D
	_mom_clean.get_node("frame").visible = bf < 0.45
	bus.visible = bf >= 0.25
	bus.scale = Vector3.ONE * (0.96 + 0.04 * clampf((bf - 0.25) / 0.1, 0.0, 1.0))
	for ch in _mom_clean.get_children():
		if ch is MeshInstance3D and ch != bus:
			(ch as MeshInstance3D).visible = bf >= 0.35
	(_mom_parts[2] as Node3D).visible = bf >= 0.45
	(_mom_parts[0] as Node3D).visible = bf >= 0.62
	(_mom_parts[1] as Node3D).visible = bf >= 0.8
	_mom_clean.get_node("engine/flame").visible = false
	_mom_clean.rotation = Vector3(0, 0.6 + bf * 1.2, 0)
	return {"desk": gt * Vector3(0, DESK_Y, 1.3), "file": gt * rest, "orrery": gt * Vector3(0.18, DESK_Y + 0.2, 1.58),
		"calendar": gt * Vector3(-2.12, 1.55, 0.35), "scale": gt * (sc_at + Vector3(0, 0.3, 0) * SCALE_K),
		"gulel": gt * _gulel.position, "window": gt * Vector3(0, 1.65, 2.0), "sill": gt * Vector3(0, 1.03, 2.0),
		"photo": gt * Vector3(2.12, 1.6, 0.6), "mom_clean": gt * (CLEAN + Vector3(0, 1.75, 0)), "clean": gt * CLEAN}
