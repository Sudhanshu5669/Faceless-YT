extends RefCounted
## Satish Dhawan Space Centre, Sriharikota: the First Launch Pad with PSLV-C25 (lines 7, 9, 10), and a launch
## control room with the countdown clock (line 9).
##
## Pad frame: the rocket stands at the origin. PSLV-XL at real proportions: 44 m, a 2.8 m core (PS1 + PS2),
## six 1 m strap-ons 13.5 m tall round the base, a 3.2 m heat shield on top. The umbilical tower stands at
## x +7; four lightning masts at the corners; the mobile service tower rolled back to z -160. Flat sandy scrub
## with casuarina trees, the Bay of Bengal along the horizon at +z. Launch: 5 Nov 2013, 14:38 IST, daylight.
## Control room at x +900 (local): a wide window toward the pad, consoles, the countdown clock on the wall.
##
## params: arc [t0, t1] (the trajectory that falls short), launch t (ignition), hold [t0, t1] (countdown on
##         HOLD; the date slides from 28 OCT 2013 to 05 NOV 2013), tap {"t0", "t1", "actor"} (finger drumming)
## anchors: rocket (its nose), base, tower, control, clock, window

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const CTRL := Vector3(900, 0, 0)

const SMOKE := """
shader_type spatial;
render_mode diffuse_burley, cull_back;
uniform float seed = 0.0;
uniform float age = 0.0;
varying vec3 lp;
//NOISE
void vertex() {
	// Lumpy billows: push the sphere out by two octaves of noise that slowly churn.
	vec3 q = VERTEX * 1.6 + vec3(seed, seed * 0.7, age * 0.3);
	float d = (fbm(q) - 0.5) * 0.9 + (n3(q * 3.1) - 0.5) * 0.25;
	VERTEX += NORMAL * d;
	lp = VERTEX;
}
void fragment() {
	float n = fbm(lp * 3.0 + vec3(seed));
	ALBEDO = vec3(0.9, 0.89, 0.86) * (0.72 + 0.38 * n);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	BACKLIGHT = vec3(0.35);
}
"""

const SAND := """
shader_type spatial;
varying vec3 wp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = fbm(wp * 0.05);
	vec3 col = mix(vec3(0.74, 0.66, 0.52), vec3(0.6, 0.56, 0.42), n);
	float scrub = smoothstep(0.55, 0.7, fbm(wp * 0.12 + 3.0));
	col = mix(col, vec3(0.32, 0.38, 0.22), scrub * 0.7);
	ALBEDO = col;
	ROUGHNESS = 0.95;
}
"""

const SEA := """
shader_type spatial;
varying vec3 wp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = fbm(vec3(wp.x * 0.02, 0.0, wp.z * 0.08));
	ALBEDO = mix(vec3(0.08, 0.26, 0.36), vec3(0.18, 0.4, 0.5), n);
	ROUGHNESS = 0.12;
	SPECULAR = 0.8;
}
"""

const PLUME := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform float power = 0.0;
uniform float flick = 0.0;
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	float along = clamp(-lp.y + 0.5, 0.0, 1.0);
	float r = length(lp.xz) * 2.0;
	float core = (1.0 - smoothstep(0.0, 0.9, r)) * (1.0 - along * 0.85);
	float fl = 0.85 + 0.15 * sin(flick * 50.0 + along * 20.0);
	ALBEDO = mix(vec3(1.0, 0.55, 0.18), vec3(1.0, 0.95, 0.8), (1.0 - r) * (1.0 - along)) * core * power * fl * 9.0;
}
"""

var _p := {}
var _rocket: Node3D
var _plumes: Array = []
var _puffs: Array = []
var _puff_data: Array = []
var _arc: MeshInstance3D
var _arc_mat: ShaderMaterial
var _clock: Label3D
var _date: Label3D
var _flare: OmniLight3D


func validate(g: Dictionary) -> Array:
	var e := []
	for k in g.get("params", {}):
		if not (k in ["arc", "launch", "hold", "tap"]):
			e.append("sriharikota: unknown param '%s'" % k)
	return e


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	_land(root)
	_pad(root)
	_rocket = _pslv()
	root.add_child(_rocket)
	_smoke(root)
	_trajectory(root)
	_control_room(root)
	return root


func _land(root: Node3D) -> void:
	Kit.box(root, Vector3(3000, 0.2, 3000), Vector3(0, -0.1, 0), Kit.shader(SAND))
	var sea := Kit.box(root, Vector3(6000, 0.2, 2400), Vector3(0, -0.05, 1700 + 1200), Kit.shader(SEA))
	var r := Kit.rng("casuarina")
	var trunk := Kit.mat("#4a3a2a", 0.9)
	var leaf := Kit.mat("#3b4a2e", 0.95)
	for i in 160:
		var a := r.randf() * TAU
		var d := r.randf_range(140.0, 700.0)
		var p := Vector3(cos(a) * d, 0, sin(a) * d * 0.7 + 60.0)
		if absf(p.x) < 70.0 and p.z > -200.0 and p.z < 60.0:
			continue
		var h := r.randf_range(9.0, 16.0)
		Kit.rod(root, p, p + Vector3(0, h, 0), 0.22, trunk, 5)
		Kit.cyl(root, 0.4, 2.6, h * 0.75, p + Vector3(0, h * 0.62, 0), leaf, 7)


func _pad(root: Node3D) -> void:
	var conc := Kit.mat("#a9a59b", 0.85)
	var steel := Kit.mat("#8a8e93", 0.45, 0.0, 0.7)
	var red := Kit.mat("#b0342a", 0.6)
	Kit.box(root, Vector3(60, 1.2, 60), Vector3(0, 0.6, 0), conc)
	Kit.box(root, Vector3(10, 1.4, 10), Vector3(0, 1.0, 0), Kit.mat("#7f7b72", 0.8))
	# Flame deflector trench running off to -z.
	Kit.box(root, Vector3(9, 0.3, 40), Vector3(0, 1.25, -28), Kit.mat("#3a3632", 0.9))
	# Umbilical tower: a square lattice, 55 m, with swing arms toward the rocket.
	var tw := Node3D.new()
	tw.position = Vector3(9.5, 1.2, 0)
	root.add_child(tw)
	for x in [-2.5, 2.5]:
		for z in [-2.5, 2.5]:
			Kit.rod(tw, Vector3(x, 0, z), Vector3(x, 55, z), 0.22, steel, 6)
	for k in 22:
		var y := 2.5 * k
		for side in 4:
			var a := Vector3(-2.5, y, -2.5).rotated(Vector3.UP, side * PI / 2)
			var b := Vector3(2.5, y + 2.5, -2.5).rotated(Vector3.UP, side * PI / 2)
			Kit.rod(tw, a, b, 0.07, steel, 4)
			Kit.rod(tw, a, Vector3(2.5, y, -2.5).rotated(Vector3.UP, side * PI / 2), 0.08, steel, 4)
	for y in [14.0, 26.0, 36.0]:
		Kit.box(tw, Vector3(6.5, 0.6, 1.2), Vector3(-5.2, y, 0), red)
	Kit.box(tw, Vector3(6, 3, 6), Vector3(0, 56.5, 0), Kit.mat("#d8d4ca", 0.7))
	# Lightning masts at the corners, with their catenary wires.
	var tops := []
	for c in [Vector3(-34, 0, -34), Vector3(34, 0, -34), Vector3(-34, 0, 34), Vector3(34, 0, 34)]:
		Kit.rod(root, c, c + Vector3(0, 72, 0), 0.5, Kit.mat("#c9c5bb", 0.6), 8)
		for k in 6:
			Kit.box(root, Vector3(1.6, 0.4, 0.4), c + Vector3(0, 10 + k * 11, 0), red)
		tops.append(c + Vector3(0, 72, 0))
	for i in 4:
		for j in range(i + 1, 4):
			if (i + j) % 3 == 0:
				continue
			var a: Vector3 = tops[i]
			var b: Vector3 = tops[j]
			var prev := a
			for k in range(1, 10):
				var u := float(k) / 9.0
				var p := a.lerp(b, u) - Vector3(0, 6.0 * 4.0 * u * (1.0 - u), 0)
				Kit.rod(root, prev, p, 0.05, Kit.mat("#2a2a2a", 0.5), 4)
				prev = p
	# The mobile service tower, rolled back on its rails.
	var mst := Node3D.new()
	mst.position = Vector3(0, 0, -170)
	root.add_child(mst)
	Kit.box(mst, Vector3(30, 76, 26), Vector3(0, 38, 0), Kit.mat("#d6d2c6", 0.75))
	for k in 12:
		Kit.box(mst, Vector3(30.4, 0.6, 26.4), Vector3(0, 6.0 * k + 3.0, 0), Kit.mat("#a39f95", 0.7))
	Kit.box(mst, Vector3(8, 70, 0.4), Vector3(0, 35, 13.2), Kit.mat("#3a3a3a", 0.6))
	for x in [-6.0, 6.0]:
		Kit.box(root, Vector3(0.6, 0.3, 200), Vector3(x, 0.15, -80), steel)


## PSLV-C25 (XL): stacked cylinders with interstage cones, six strap-ons, the heat shield; ISRO and the flag.
func _pslv() -> Node3D:
	var n := Node3D.new()
	n.position = Vector3(0, 1.7, 0)
	var white := Kit.mat("#efede6", 0.5, 0.0, 0.5)
	var grey := Kit.mat("#8e9196", 0.45)
	var dark := Kit.mat("#2a2b2e", 0.5)
	Kit.cyl(n, 1.4, 1.4, 20.0, Vector3(0, 10.0, 0), white, 32)
	Kit.cyl(n, 1.42, 1.42, 1.0, Vector3(0, 0.5, 0), grey, 32)
	Kit.cyl(n, 1.4, 1.4, 12.0, Vector3(0, 26.6, 0), white, 32)
	Kit.cyl(n, 1.42, 1.42, 0.5, Vector3(0, 20.4, 0), dark, 32)
	Kit.cyl(n, 1.6, 1.4, 1.2, Vector3(0, 33.2, 0), grey, 32)
	Kit.cyl(n, 1.6, 1.6, 6.2, Vector3(0, 36.9, 0), white, 32)
	# The ogive nose of the heat shield.
	var nose := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.6
	sm.height = 6.0
	sm.is_hemisphere = true
	sm.radial_segments = 32
	sm.rings = 16
	nose.mesh = sm
	nose.material_override = white
	nose.position = Vector3(0, 40.0, 0)
	n.add_child(nose)
	# Strap-ons (PSOM-XL), with nose cones and nozzles.
	for i in 6:
		var a := TAU * float(i) / 6.0 + PI / 6.0
		var c := Vector3(cos(a) * 2.45, 0, sin(a) * 2.45)
		Kit.cyl(n, 0.5, 0.5, 13.0, c + Vector3(0, 7.3, 0), white, 20)
		Kit.cyl(n, 0.52, 0.52, 0.6, c + Vector3(0, 1.0, 0), grey, 20)
		Kit.cyl(n, 0.0, 0.5, 1.8, c + Vector3(0, 14.7, 0), white, 20)
		Kit.cyl(n, 0.3, 0.45, 0.8, c + Vector3(0, 0.3, 0), dark, 16)
		Kit.rod(n, c * 0.7 + Vector3(0, 12.0, 0), c * 0.58 + Vector3(0, 12.0, 0), 0.12, grey, 6)
		var pl := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.45
		cm.bottom_radius = 1.4
		cm.height = 1.0
		pl.mesh = cm
		var pm := Kit.shader(PLUME)
		pl.material_override = pm
		pl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pl.position = c + Vector3(0, -5.0, 0)
		pl.scale = Vector3(1, 10, 1)
		n.add_child(pl)
		_plumes.append([pl, pm])
	var core_pl := MeshInstance3D.new()
	var cm2 := CylinderMesh.new()
	cm2.top_radius = 1.0
	cm2.bottom_radius = 2.6
	cm2.height = 1.0
	core_pl.mesh = cm2
	var cpm := Kit.shader(PLUME)
	core_pl.material_override = cpm
	core_pl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	core_pl.position = Vector3(0, -7.0, 0)
	core_pl.scale = Vector3(1, 14, 1)
	n.add_child(core_pl)
	_plumes.append([core_pl, cpm])
	_flare = Kit.omni(n, Vector3(0, -4, 0), "#ffb46a", 0.0, 120.0, false, 0.6)
	# Markings: ISRO (Devanagari and Latin) down the core, the tricolour on the heat shield.
	var marks := Node3D.new()
	marks.position = Vector3(0, 0, 1.43)
	n.add_child(marks)
	Kit.text(marks, "इसरो isro", 1.1, Color("1d3f8f"), Vector3(0, 28.5, 0), Vector3(0, 0, PI / 2), true, 0.0, Color(0, 0, 0, 0), "body")
	var flag := Node3D.new()
	flag.position = Vector3(0, 37.2, 1.62)
	n.add_child(flag)
	Kit.quad(flag, Vector2(1.5, 0.33), Vector3(0, 0.33, 0), Kit.mat("#ff9933", 0.6))
	Kit.quad(flag, Vector2(1.5, 0.33), Vector3(0, 0, 0), Kit.mat("#ffffff", 0.6))
	Kit.quad(flag, Vector2(1.5, 0.33), Vector3(0, -0.33, 0), Kit.mat("#138808", 0.6))
	Kit.cyl(flag, 0.13, 0.13, 0.01, Vector3(0, 0, 0.01), Kit.mat("#000080", 0.6), 24, Vector3(PI / 2, 0, 0))
	Kit.text(marks, "PSLV-C25", 0.7, Color("1a1a1a"), Vector3(0, 35.5, 0.2), Vector3.ZERO, true)
	return n


## Exhaust and steam: lit smoke puffs that boil out of the trench and up round the rocket after ignition.
func _smoke(root: Node3D) -> void:
	var r := Kit.rng("smoke")
	for i in 160:
		var m := Kit.shader(SMOKE)
		m.set_shader_parameter("seed", float(i) * 3.3)
		var b := Kit.ball(root, 1.0, Vector3.ZERO, m, 28)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_puffs.append(b)
		var a := r.randf_range(-PI, PI)
		var trench := r.randf() < 0.55
		var dir := Vector3(r.randf_range(-0.35, 0.35), r.randf_range(0.05, 0.3), -1.0).normalized() if trench else Vector3(cos(a), r.randf_range(0.1, 0.5), sin(a)).normalized()
		_puff_data.append([dir, r.randf_range(0.0, 2.6), r.randf_range(10.0, 38.0), r.randf_range(2.5, 8.0), trench])


func _trajectory(root: Node3D) -> void:
	# The throw that falls short: a dashed arc from the nose up toward Mars, bending back down.
	var pts := []
	for i in 80:
		var u := float(i) / 79.0
		pts.append(Vector3(-u * 120.0, 44.0 + sin(u * PI * 0.92) * 120.0 - u * 20.0, u * 60.0))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var side := (b - a).cross(Vector3.FORWARD).normalized() * 1.6
		var u0 := float(i) / 79.0
		var u1 := float(i + 1) / 79.0
		st.set_uv(Vector2(u0, 0)); st.add_vertex(a - side)
		st.set_uv(Vector2(u1, 0)); st.add_vertex(b - side)
		st.set_uv(Vector2(u1, 1)); st.add_vertex(b + side)
		st.set_uv(Vector2(u0, 0)); st.add_vertex(a - side)
		st.set_uv(Vector2(u1, 1)); st.add_vertex(b + side)
		st.set_uv(Vector2(u0, 1)); st.add_vertex(a + side)
	_arc = MeshInstance3D.new()
	_arc.mesh = st.commit()
	_arc_mat = Kit.shader("""
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform float reveal = 0.0;
varying vec2 uv2;
void vertex() { uv2 = UV; }
void fragment() {
	if (uv2.x > reveal) { discard; }
	float dash = step(0.5, fract(uv2.x * 26.0));
	ALBEDO = mix(vec3(1.0), vec3(1.0, 0.35, 0.25), smoothstep(0.55, 1.0, uv2.x));
	ALPHA = dash * 0.9;
}
""")
	_arc.material_override = _arc_mat
	_arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(_arc)
	# Mars, out of reach: a red disc high in the afternoon sky beyond where the arc falls.
	var mars := Kit.ball(root, 7.0, Vector3(-175, 175, 95), Kit.lit("#e0582c", 1.6), 24)
	mars.name = "mars_target"
	mars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _control_room(root: Node3D) -> void:
	var c := Node3D.new()
	c.position = CTRL
	root.add_child(c)
	var wall := Kit.mat("#c9c6bd", 0.85)
	Kit.box(c, Vector3(10, 0.1, 8), Vector3(0, -0.05, 0), Kit.mat("#4a4f57", 0.7))
	Kit.box(c, Vector3(10, 3.2, 0.2), Vector3(0, 1.6, -4), wall)
	Kit.box(c, Vector3(0.2, 3.2, 8), Vector3(-5, 1.6, 0), wall)
	Kit.box(c, Vector3(0.2, 3.2, 8), Vector3(5, 1.6, 0), wall)
	Kit.box(c, Vector3(10, 0.1, 8), Vector3(0, 3.2, 0), Kit.mat("#d8d6cf", 0.9))
	# The window wall toward the pad (+z), with a long sill and mullions.
	Kit.box(c, Vector3(10, 0.9, 0.2), Vector3(0, 0.45, 4), wall)
	Kit.box(c, Vector3(10, 0.4, 0.2), Vector3(0, 3.0, 4), wall)
	for x in range(-5, 6, 2):
		Kit.box(c, Vector3(0.1, 2.0, 0.12), Vector3(x, 1.9, 4), Kit.mat("#3a3c40", 0.5))
	# Consoles, the countdown clock and the date on the back wall.
	Kit.box(c, Vector3(6, 0.75, 0.9), Vector3(0, 0.375, 1.2), Kit.mat("#3a3f47", 0.6))
	for x in [-2.0, 0.0, 2.0]:
		Kit.box(c, Vector3(0.6, 0.38, 0.04), Vector3(x, 1.0, 1.55), Kit.lit("#6f9fd6", 0.9), Vector3(-0.2, PI, 0))
	var cb := Node3D.new()
	cb.position = Vector3(-4.86, 2.2, 0.6)
	cb.rotation = Vector3(0, PI / 2, 0)
	c.add_child(cb)
	Kit.box(cb, Vector3(2.6, 0.8, 0.1), Vector3.ZERO, Kit.mat("#0b0c0e", 0.4))
	_clock = Kit.text(cb, "T- 00:00:00", 0.36, Color(1.0, 0.25, 0.15), Vector3(0, 0.1, 0.07), Vector3.ZERO, true, 3.0)
	_date = Kit.text(cb, "28 OCT 2013", 0.18, Color(1.0, 0.8, 0.3), Vector3(0, -0.24, 0.07), Vector3.ZERO, true, 2.5)
	Kit.spot(c, Vector3(0, 3.0, 0), Vector3(0, 0, 0.5), "#fff0dc", 2.0, 8.0, 70.0, true, 0.2)
	Kit.omni(c, Vector3(0, 1.2, 1.8), "#7fa8e0", 0.5, 4.0, false, 0.2)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var lt := float(_p.get("launch", 1e9))
	var age := t - lt
	# Lift-off: a beat of thrust build-up, then the climb.
	var lift := 0.0
	if age > 0.6:
		var a := age - 0.6
		lift = 3.6 * a * a + 2.0 * a
	_rocket.position = Vector3(0, 1.7 + lift, 0)
	var power := clampf(age / 0.5, 0.0, 1.0) if age > 0.0 else 0.0
	for pl in _plumes:
		(pl[1] as ShaderMaterial).set_shader_parameter("power", power)
		(pl[1] as ShaderMaterial).set_shader_parameter("flick", t)
		(pl[0] as MeshInstance3D).visible = power > 0.0
	_flare.light_energy = 18.0 * power
	# Smoke: puffs boil out after ignition, grow, slow and drift.
	for i in _puffs.size():
		var b: MeshInstance3D = _puffs[i]
		var d: Array = _puff_data[i]
		var pa: float = age - float(d[1]) * 0.5
		b.visible = pa > 0.0
		if pa <= 0.0:
			continue
		var reach: float = float(d[2]) * (1.0 - exp(-pa * 1.2))
		var start := Vector3(0, 2.0, -6.0) if bool(d[4]) else Vector3(0, 2.0, 0)
		b.position = start + (d[0] as Vector3) * reach + Vector3(0, pa * 1.2, 0)
		b.scale = Vector3.ONE * float(d[3]) * clampf(0.3 + pa * 0.6, 0.0, 1.0)
		(b.material_override as ShaderMaterial).set_shader_parameter("age", pa)
	# The arc that falls short.
	var aw = _p.get("arc", [])
	var rv := 0.0
	if aw is Array and aw.size() >= 2:
		rv = Motion.in_out(clampf((t - float(aw[0])) / maxf(float(aw[1]) - float(aw[0]), 0.01), 0.0, 1.0))
	_arc_mat.set_shader_parameter("reveal", rv)
	_arc.visible = rv > 0.0 and age < 0.0 and aw is Array and aw.size() >= 2 and t < float(aw[1]) + 2.0
	# The countdown: HOLD, and the date slides on a week.
	var hw = _p.get("hold", [])
	var days := 0
	if hw is Array and hw.size() >= 2:
		days = int(round(clampf((t - float(hw[0])) / maxf(float(hw[1]) - float(hw[0]), 0.01), 0.0, 1.0) * 8.0))
	var dates := ["28 OCT 2013", "29 OCT 2013", "30 OCT 2013", "31 OCT 2013", "01 NOV 2013", "02 NOV 2013", "03 NOV 2013", "04 NOV 2013", "05 NOV 2013"]
	_date.text = dates[clampi(days, 0, 8)]
	_clock.text = "HOLD" if fposmod(t, 1.0) < 0.6 else ""
	# Finger drumming on the console.
	var tap = _p.get("tap", null)
	if tap is Dictionary:
		var act = ctx.get("actor", null)
		var who = act.call(String(tap.get("actor", ""))) if act else null
		if who and t > float(tap.get("t0", 1e9)) and t < float(tap.get("t1", 0.0)):
			var desk := gt * (CTRL + Vector3(0.25, 0.78, 0.95))
			var lift2 := 0.035 * maxf(0.0, sin(t * 26.0))
			who.aim_hand("r", desk + Vector3(0, lift2, 0), 1.0)
	return {"rocket": gt * (_rocket.position + Vector3(0, 40, 0)), "base": gt * (_rocket.position + Vector3(0, 6, 0)),
		"tower": gt * Vector3(9.5, 30, 0), "control": gt * CTRL, "clock": gt * (CTRL + Vector3(-4.86, 2.2, 0.6)),
		"window": gt * (CTRL + Vector3(0, 1.8, 4.0))}
