extends RefCounted
## A US optical reconnaissance satellite in low orbit over India, December 1995 (a generic one: no real
## satellite's design is shown). A 12 m cylinder in crinkled gold insulation blankets with white radiator panels; at
## the front a sunshade baffle over the telescope's aperture (a dark mirror with its secondary on a spider); two
## solar wings on short masts; a dish on a boom; small thruster quads.
##
## Local frame: the satellite's centre at the origin; at rest its telescope looks along -Z (along the track);
## the Earth (library:earth in the same bay) lies below, -Y.
##
## params:
##   aim     [x, y, z]   gag-local point the telescope turns to (the target on the ground)
##   turn    {"from": t, "to": t}   the slew: a small counter-move, the turn (thrusters puff), a settle
##   click   t   the shutter: a glint off the aperture
## anchors: sat (centre), lens (aperture), tail
const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const LEN := 12.0
const RAD := 1.5

## Multi-layer insulation: gold-coated foil, crinkled into facets that catch the sun, seams and tape.
const MLI := """
shader_type spatial;
uniform vec3 foil : source_color = vec3(0.78, 0.52, 0.16);
varying vec3 lp;
//NOISE
void vertex() { lp = VERTEX; }
void fragment() {
	float n1 = n3(lp * 6.0);
	float n2 = n3(lp * 17.0 + 3.0);
	vec3 nm = vec3(0.5 + 0.45 * (n1 - 0.5) + 0.25 * (n2 - 0.5), 0.5 + 0.45 * (n3(lp * 6.0 + 9.0) - 0.5) + 0.25 * (n3(lp * 17.0 + 7.0) - 0.5), 1.0);
	NORMAL_MAP = nm;
	NORMAL_MAP_DEPTH = 0.7;
	// Blanket seams every 1.5 m along the body: thin taped lines.
	float seam = 1.0 - smoothstep(0.0, 0.012, 0.5 - abs(fract(lp.y / 1.5) - 0.5));
	vec3 c = foil * (0.8 + 0.3 * n2);
	c = mix(c, vec3(0.75, 0.72, 0.66), seam * 0.8);
	// Lit like a coating, not a mirror: in orbit a mirror would only show the black sky (no Earth reflection
	// here), so the gold is mostly diffuse with a strong sheen.
	ALBEDO = c;
	METALLIC = 0.3;
	ROUGHNESS = 0.28 + 0.2 * n1;
	SPECULAR = 0.9;
	RIM = 0.25;
	RIM_TINT = 0.9;
}
"""

## Solar cells: dark blue glass in a grid of silver busbars; the back is white.
const CELLS := """
shader_type spatial;
render_mode cull_disabled;
varying vec2 uvp;
void vertex() { uvp = UV; }
void fragment() {
	vec2 g = fract(uvp * vec2(10.0, 24.0));
	float line = max(step(g.x, 0.06), step(g.y, 0.05));
	vec3 cell = vec3(0.04, 0.06, 0.16) + 0.03 * sin(uvp.y * 80.0);
	vec3 c = mix(cell, vec3(0.7, 0.72, 0.75), line);
	if (!FRONT_FACING) { c = vec3(0.85, 0.85, 0.82); }
	ALBEDO = c;
	METALLIC = FRONT_FACING ? mix(0.3, 0.9, line) : 0.0;
	ROUGHNESS = FRONT_FACING ? 0.12 : 0.7;
	SPECULAR = 0.9;
}
"""

const PUFF := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform float a = 0.0;
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	float r = length(lp.xz) / max(0.2 + lp.y, 0.05);
	ALBEDO = vec3(0.9, 0.95, 1.0) * a * (1.0 - smoothstep(0.0, 0.5, r)) * (1.0 - smoothstep(0.0, 1.0, lp.y));
}
"""

var _p := {}
var _sat: Node3D
var _glint: MeshInstance3D
var _puffs: Array = []
var _rest := Basis.IDENTITY
var _aimed := Basis.IDENTITY


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	_sat = Node3D.new()
	_sat.name = "sat"
	root.add_child(_sat)
	var gold := Kit.shader(MLI)
	var silver := Kit.shader(MLI)
	silver.set_shader_parameter("foil", Vector3(0.62, 0.63, 0.66))
	var white := Kit.mat("#e8e6e0", 0.55, 0.0, 0.5)
	var dark := Kit.mat("#16171a", 0.35, 0.6)
	# The body: gold blankets over most of it, a silver band aft, white radiator panels along one side.
	Kit.cyl(_sat, RAD, RAD, LEN * 0.72, Vector3(0, 0, -LEN * 0.06), gold, 48, Vector3(PI / 2, 0, 0))
	Kit.cyl(_sat, RAD * 1.02, RAD * 1.02, LEN * 0.18, Vector3(0, 0, LEN * 0.37), silver, 48, Vector3(PI / 2, 0, 0))
	for k in 3:
		Kit.box(_sat, Vector3(0.03, 0.5, 1.8), Vector3(RAD * 0.98, -0.62 + 0.62 * k, LEN * 0.05), Kit.mat("#cfcdc6", 0.4, 0.0, 0.7))
	# The sunshade baffle at the front, cut at an angle, with the aperture inside: a black mirror, a secondary on
	# four struts.
	var baffle := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = RAD * 1.04
	bm.bottom_radius = RAD * 1.04
	bm.height = 2.2
	bm.cap_top = false
	bm.cap_bottom = false
	bm.radial_segments = 48
	baffle.mesh = bm
	var bmat := Kit.shader(MLI)
	bmat.set_shader_parameter("foil", Vector3(0.7, 0.7, 0.68))
	baffle.material_override = bmat
	baffle.rotation = Vector3(PI / 2, 0, 0)
	baffle.position = Vector3(0, 0, -LEN * 0.42 - 1.1)
	_sat.add_child(baffle)
	var inner := MeshInstance3D.new()
	var im := CylinderMesh.new()
	im.top_radius = RAD * 1.0
	im.bottom_radius = RAD * 1.0
	im.height = 2.2
	im.cap_top = false
	im.cap_bottom = false
	im.flip_faces = true
	im.radial_segments = 48
	inner.mesh = im
	inner.material_override = Kit.mat("#0c0c0e", 0.8)
	inner.rotation = baffle.rotation
	inner.position = baffle.position
	_sat.add_child(inner)
	var mirror := Kit.cyl(_sat, RAD * 0.92, RAD * 0.92, 0.05, Vector3(0, 0, -LEN * 0.42 + 0.1), Kit.mat("#0a0f1a", 0.04, 0.9, 1.0), 48, Vector3(PI / 2, 0, 0))
	mirror.name = "mirror"
	for k in 4:
		var a := PI / 4 + PI / 2 * k
		Kit.rod(_sat, Vector3(cos(a) * RAD * 0.95, sin(a) * RAD * 0.95, -LEN * 0.42 - 1.6), Vector3(0, 0, -LEN * 0.42 - 1.6), 0.02, dark, 6)
	Kit.cyl(_sat, 0.3, 0.3, 0.3, Vector3(0, 0, -LEN * 0.42 - 1.6), dark, 20, Vector3(PI / 2, 0, 0))
	# The shutter's glint (a flash off the aperture, shown on "click").
	_glint = MeshInstance3D.new()
	var gq := QuadMesh.new()
	gq.size = Vector2(9.0, 9.0)
	_glint.mesh = gq
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	gm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5) / 32.0
			var v := clampf(exp(-d.length_squared() * 8.0) + 0.6 * exp(-absf(d.x) * 30.0 - absf(d.y) * 2.5) + 0.6 * exp(-absf(d.y) * 30.0 - absf(d.x) * 2.5), 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 0.97, 0.9, v))
	gm.albedo_texture = ImageTexture.create_from_image(img)
	_glint.material_override = gm
	_glint.position = Vector3(0, 0, -LEN * 0.42 - 2.3)
	_glint.visible = false
	_sat.add_child(_glint)
	# Aft: the bus with a thruster quad at each corner, a dish on a boom.
	Kit.cyl(_sat, RAD * 0.85, RAD * 0.95, 1.2, Vector3(0, 0, LEN * 0.5 + 0.4), Kit.mat("#3a3a3c", 0.5, 0.5), 32, Vector3(PI / 2, 0, 0))
	for k in 4:
		var a := PI / 4 + PI / 2 * k
		var at := Vector3(cos(a) * RAD * 0.9, sin(a) * RAD * 0.9, LEN * 0.5 + 0.8)
		for d in [Vector3(cos(a), sin(a), 0), Vector3(-sin(a), cos(a), 0), Vector3(sin(a), -cos(a), 0)]:
			Kit.rod(_sat, at, at + (d as Vector3) * 0.25, 0.05, dark, 8, 0.09)
			var puff := MeshInstance3D.new()
			var pm := CylinderMesh.new()
			pm.top_radius = 0.6
			pm.bottom_radius = 0.05
			pm.height = 1.6
			puff.mesh = pm
			var pmat := Kit.shader(PUFF)
			puff.material_override = pmat
			puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var dir := (d as Vector3)
			puff.transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)), at + dir * 1.05)
			_sat.add_child(puff)
			_puffs.append([pmat, dir, k])
	Kit.rod(_sat, Vector3(0, -RAD, LEN * 0.3), Vector3(0, -RAD - 1.4, LEN * 0.3), 0.06, white, 8)
	var dish := MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 0.9
	dm.height = 0.5
	dm.is_hemisphere = true
	dish.mesh = dm
	dish.material_override = white
	dish.position = Vector3(0, -RAD - 1.5, LEN * 0.3)
	dish.rotation = Vector3(PI, 0, 0)
	_sat.add_child(dish)
	# Solar wings: a mast each side, two panels per wing.
	for s in [-1.0, 1.0]:
		Kit.rod(_sat, Vector3(s * RAD, 0, LEN * 0.18), Vector3(s * (RAD + 1.2), 0, LEN * 0.18), 0.07, white, 8)
		for k in 2:
			var panel := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(3.2, 2.0)
			panel.mesh = qm
			panel.material_override = Kit.shader(CELLS)
			panel.position = Vector3(s * (RAD + 1.3 + 1.65 + 3.3 * k), 0, LEN * 0.18)
			panel.rotation = Vector3(-PI / 2 + 0.35, 0, 0)
			_sat.add_child(panel)
			Kit.box(_sat, Vector3(3.2, 0.04, 0.04), panel.position + Vector3(0, 0.33, -0.95), white, Vector3(0.35, 0, 0))
	# Attitudes: at rest along the track; aimed at the target.
	_rest = Basis.IDENTITY
	var aim: Array = _p.get("aim", [0.0, -600.0, -300.0])
	var to := Vector3(float(aim[0]), float(aim[1]), float(aim[2])).normalized()
	# Turned to the target with its old forward (-Z, the track) as 'up', like a telescope tipping down.
	_aimed = Basis.looking_at(to, Vector3.FORWARD if absf(to.dot(Vector3.UP)) > 0.9 else Vector3.UP)
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var tw: Dictionary = _p.get("turn", {})
	var t0 := float(tw.get("from", 1e9))
	var t1 := float(tw.get("to", t0 + 1.0))
	# Anticipation: a small counter-swing, then the slew eased in and out, then a slight overshoot that settles.
	var u := Motion.seg(t, t0, t1)
	var k := Motion.in_out(u)
	var pre := -0.04 * sin(clampf((t - t0 + 0.25) / 0.25, 0.0, 1.0) * PI) if t < t0 + 0.05 else 0.0
	var post := 0.035 * Motion.wobble(t - t1, 2.2, 4.0) if t > t1 else 0.0
	var q := Quaternion(_rest).slerp(Quaternion(_aimed), clampf(k + pre + post, -0.2, 1.2))
	_sat.basis = Basis(q)
	# A slow roll drift and orbital wobble so it never sits dead still.
	_sat.rotate_object_local(Vector3(0, 0, 1), 0.02 * sin(t * 0.4))
	# Thruster puffs: fire during the slew's start and stop (short pulses), from the quads on opposite corners.
	var firing := 0.0
	if u > 0.0 and u < 1.0:
		firing = maxf(exp(-pow((u - 0.08) / 0.07, 2.0)), exp(-pow((u - 0.88) / 0.07, 2.0)))
	for pf in _puffs:
		var pm: ShaderMaterial = pf[0]
		var on := 1.0 if int(pf[2]) % 2 == (0 if u < 0.5 else 1) else 0.0
		pm.set_shader_parameter("a", firing * on * (0.7 + 0.3 * sin(t * 50.0 + float(pf[2]))))
	# The shutter click: a glint flashes off the aperture.
	var ck := float(_p.get("click", 1e9))
	var dc := t - ck
	_glint.visible = dc > -0.02 and dc < 0.55
	if _glint.visible:
		var f := exp(-maxf(dc, 0.0) * 6.0)
		_glint.scale = Vector3.ONE * (0.5 + 1.0 * f) * (1.0 + 0.15 * sin(dc * 40.0) * f)
		(_glint.material_override as StandardMaterial3D).albedo_color = Color(1.6, 1.55, 1.4, clampf(f * 1.5, 0.0, 1.0))
	var lens := _sat.transform * Vector3(0, 0, -LEN * 0.42 - 2.2)
	return {"sat": gt * Vector3.ZERO, "lens": gt * lens, "tail": gt * (_sat.transform * Vector3(0, 0, LEN * 0.5))}
