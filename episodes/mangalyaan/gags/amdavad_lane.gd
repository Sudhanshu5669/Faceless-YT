extends RefCounted
## A pol lane in old Ahmedabad at night, with an auto-rickshaw and its fare meter (lines 1 and 24).
##
## Local frame: the lane runs along z (the auto faces -z, the way it will drive), 4.6 m between the house
## fronts (x -2.3..2.3), houses from z -26 to +10. Pol houses: 2-3 storeys of brick under lime plaster in faded
## blue, ochre, pink and green, carved teak balconies on brackets, shuttered shops at street level with signs.
## A chabutro (the pol's bird-feeding tower) stands at z -12. A sodium lamp on a bracket, a tube light over a
## shop, wires everywhere. The auto: black body, yellow canopy, a red LED meter on the left of the dash.
##
## params (scene seconds):
##   meter   {"start", "land", "to": 10}     the fare counts up from 0 and stops on the word
##   meter2  {"start", "land", "to": 7}      (line 24) the same meter, now ₹7
##   streak  [t0, t1]                       a gold glint (MOM) climbs from behind the auto over the roofs
##   streak2 [t0, t1]                       crossing the sky again at the end
##   drive   t                              the auto pulls away
## anchors: meter, auto, sky, chabutro, driver_seat

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Paths = preload("res://scripts/core/paths.gd")

const AUTO_AT := Vector3(0.6, 0, 0)

const PLASTER := """
shader_type spatial;
uniform vec3 paint : source_color = vec3(0.5, 0.62, 0.72);
uniform float seed = 0.0;
varying vec3 wp;
varying vec3 wn;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }
void fragment() {
	vec3 q = wp + vec3(seed);
	// Lime plaster in a faded colour, peeling to brick in patches, streaked by monsoon runoff, grimy at the base.
	float peel = smoothstep(0.62, 0.68, fbm(q * vec3(0.9, 1.4, 0.9)));
	vec2 b = (abs(wn.x) > 0.5 ? wp.zy : wp.xy) / vec2(0.23, 0.08);
	b.x += step(1.0, mod(floor(b.y), 2.0)) * 0.5;
	float joint = 1.0 - step(0.06, fract(b.x)) * step(0.1, fract(b.y));
	vec3 brick = mix(vec3(0.5, 0.25, 0.16), vec3(0.62, 0.34, 0.22), h3(vec3(floor(b), 2.0)));
	brick = mix(brick, vec3(0.55, 0.52, 0.47), joint);
	vec3 col = paint * (0.82 + 0.25 * fbm(q * 2.5));
	col *= 1.0 - 0.28 * smoothstep(0.45, 0.8, fbm(vec3(q.x * 3.0, q.y * 0.4, q.z * 3.0) + 5.0));
	col *= 1.0 - 0.35 * smoothstep(1.2, 0.0, wp.y);
	col = mix(col, brick, peel);
	ALBEDO = col;
	ROUGHNESS = 0.93;
}
"""

const STREET := """
shader_type spatial;
varying vec3 wp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	// Patched concrete with a drain channel, dust, dark stains, a few wet patches that catch the lamp.
	float n = fbm(wp * 0.7);
	vec3 col = mix(vec3(0.36, 0.34, 0.31), vec3(0.25, 0.24, 0.22), n);
	float patchv = smoothstep(0.6, 0.62, fbm(wp * 0.25 + 3.0));
	col = mix(col, vec3(0.3, 0.3, 0.3), patchv * 0.6);
	float wet = smoothstep(0.66, 0.7, fbm(wp * 0.5 + 9.0));
	col *= 1.0 - 0.3 * wet;
	ALBEDO = col;
	ROUGHNESS = mix(0.9, 0.15, wet);
	SPECULAR = mix(0.3, 0.8, wet);
}
"""

## The LED fare display: dark red glass with lit segments (drawn as text over it).
var _p := {}
var _auto: Node3D
var _meter_text: Label3D
var _meter_flag: Node3D
var _streak: Node3D
var _trail: MeshInstance3D
var _trail_mat: StandardMaterial3D
var _wheel_nodes: Array = []
static var _mom_gd: GDScript


static func mom_script() -> GDScript:
	if _mom_gd == null:
		_mom_gd = GDScript.new()
		_mom_gd.source_code = FileAccess.get_file_as_string(Paths.repo_path("episodes/mangalyaan/gags/mom_model.gd"))
		_mom_gd.reload()
	return _mom_gd


func validate(g: Dictionary) -> Array:
	var e := []
	for k in g.get("params", {}):
		if not (k in ["meter", "meter2", "streak", "streak2", "drive"]):
			e.append("amdavad_lane: unknown param '%s'" % k)
	return e


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	Kit.box(root, Vector3(4.8, 0.1, 40), Vector3(0, -0.05, -8), Kit.shader(STREET))
	Kit.box(root, Vector3(0.35, 0.06, 40), Vector3(-2.1, 0.0, -8), Kit.mat("#1d1c1a", 0.4, 0.0, 0.7))
	_houses(root, -1.0)
	_houses(root, 1.0)
	_chabutro(root, Vector3(-0.2, 0, -13))
	_wires(root)
	_lights(root)
	_auto = _build_auto()
	root.add_child(_auto)
	_streak = Node3D.new()
	root.add_child(_streak)
	var mom: Node3D = mom_script().new().build(1.2)
	mom.get_node("engine/flame").visible = false
	_streak.add_child(mom)
	Kit.omni(_streak, Vector3(0, 0, 0), "#ffd27a", 1.5, 14.0, false, 0.5)
	_trail = MeshInstance3D.new()
	root.add_child(_trail)
	_trail_mat = Kit.flat(Color(1.0, 0.82, 0.45, 0.85), true) as StandardMaterial3D
	return root


func _houses(root: Node3D, side: float) -> void:
	var r := Kit.rng("pol", int(side * 10))
	var paints := ["#6f93ad", "#c7a25a", "#c98a86", "#7fa37a", "#b6b0a2", "#9b7fb0", "#d6c08a"]
	var z := 10.0
	var wood := Kit.mat("#4a2e1a", 0.7)
	var dark_wood := Kit.mat("#2e1c10", 0.75)
	var i := 0
	while z > -26.0:
		var w := r.randf_range(3.2, 5.0)
		var floors := r.randi_range(2, 3)
		var h := 3.1 * floors
		var x := side * (2.3 + 4.0)
		var paint := Color(String(paints[r.randi_range(0, paints.size() - 1)]))
		var m := Kit.shader(PLASTER)
		m.set_shader_parameter("paint", paint)
		m.set_shader_parameter("seed", float(i) * 13.1 + side * 5.0)
		var front := side * 2.3
		Kit.box(root, Vector3(8.0, h, w - 0.05), Vector3(x, h * 0.5, z - w * 0.5), m)
		# Plinth step and a shop shutter or a carved door at street level.
		Kit.box(root, Vector3(0.5, 0.35, w - 0.1), Vector3(front - side * 0.2, 0.17, z - w * 0.5), Kit.mat("#6e6a62", 0.9))
		var mid := z - w * 0.5
		if r.randf() < 0.6:
			var sh := Kit.mat("#7d8287", 0.5, 0.0, 0.6)
			Kit.box(root, Vector3(0.06, 2.3, w * 0.7), Vector3(front + side * 0.03, 1.5, mid), sh)
			for k in 18:
				Kit.box(root, Vector3(0.07, 0.015, w * 0.7), Vector3(front + side * 0.0, 0.45 + k * 0.12, mid), Kit.mat("#5f6469", 0.5))
			var names := ["SHREE GANESH STORES", "PATEL TEA DEPOT", "MOBILE REPAIRING", "JAY AMBE KIRANA", "NEW SHAH TAILORS", "SAI XEROX"]
			var board := Node3D.new()
			board.position = Vector3(front + side * 0.06, 2.95, mid)
			board.rotation = Vector3(0, -side * PI / 2, 0)
			root.add_child(board)
			var bc := Color(String(["#c0392b", "#1f6fb2", "#e2b23a", "#2f8a4a"][r.randi_range(0, 3)]))
			Kit.box(board, Vector3(w * 0.8, 0.5, 0.04), Vector3.ZERO, Kit.mat(bc, 0.6))
			Kit.text(board, names[(i + int(side * 3.0 + 3.0)) % names.size()], 0.2, Color("fbf6e8"), Vector3(0, 0, 0.03))
		else:
			var door := Node3D.new()
			door.position = Vector3(front + side * 0.02, 0, mid)
			door.rotation = Vector3(0, -side * PI / 2, 0)
			root.add_child(door)
			Kit.box(door, Vector3(1.3, 2.4, 0.08), Vector3(0, 1.2, 0), dark_wood)
			for k in 4:
				for j in 2:
					Kit.box(door, Vector3(0.5, 0.45, 0.03), Vector3(-0.3 + 0.6 * j, 0.4 + 0.55 * k, 0.05), wood)
			Kit.box(door, Vector3(1.6, 0.25, 0.14), Vector3(0, 2.55, 0.0), wood)
		# Upper floors: carved balconies (jharokha) on brackets, windows with wooden shutters.
		for f in range(1, floors):
			var y := 3.1 * f
			var bal := Node3D.new()
			bal.position = Vector3(front, y, mid)
			bal.rotation = Vector3(0, -side * PI / 2, 0)
			root.add_child(bal)
			var bw := w * 0.78
			Kit.box(bal, Vector3(bw, 0.12, 0.8), Vector3(0, 0, 0.4), wood)
			for k in 5:
				var bx := -bw * 0.5 + 0.15 + (bw - 0.3) * float(k) / 4.0
				Kit.box(bal, Vector3(0.12, 0.5, 0.12), Vector3(bx, -0.28, 0.25), dark_wood, Vector3(0.6, 0, 0))
				Kit.rod(bal, Vector3(bx, 0.06, 0.74), Vector3(bx, 1.9, 0.74), 0.045, wood, 8)
			for k in 18:
				var bx := -bw * 0.5 + 0.1 + (bw - 0.2) * float(k) / 17.0
				Kit.rod(bal, Vector3(bx, 0.1, 0.76), Vector3(bx, 0.85, 0.76), 0.018, wood, 6)
			Kit.box(bal, Vector3(bw, 0.07, 0.07), Vector3(0, 0.88, 0.76), wood)
			Kit.box(bal, Vector3(bw + 0.2, 0.14, 0.95), Vector3(0, 1.95, 0.42), dark_wood)
			# A window behind, with a dim warm light in some.
			var lit_win := r.randf() < 0.45
			Kit.box(bal, Vector3(0.9, 1.3, 0.04), Vector3(0, 1.0, 0.02), Kit.lit("#ffcf86", 1.4) if lit_win else Kit.mat("#141210", 0.6))
			Kit.box(bal, Vector3(0.06, 1.3, 0.06), Vector3(0, 1.0, 0.04), dark_wood)
			if lit_win:
				Kit.omni(root, Vector3(front + side * 0.6, y + 1.0, mid), "#ffbf72", 0.35, 3.5, false, 0.6)
			# Laundry, a plant pot, a water tank on the roof.
			if r.randf() < 0.4:
				Kit.box(bal, Vector3(0.6, 0.5, 0.01), Vector3(r.randf_range(-0.6, 0.6), 1.35, 0.78), Kit.mat(String(["#b8323a", "#2e6ea8", "#e3c04a"][r.randi_range(0, 2)]), 0.9))
		Kit.cyl(root, 0.5, 0.5, 1.0, Vector3(side * (2.3 + 2.0), h + 0.5, mid), Kit.mat("#141414", 0.6), 16)
		z -= w
		i += 1


func _chabutro(root: Node3D, at: Vector3) -> void:
	var stone := Kit.mat("#b6ab95", 0.85)
	var n := Node3D.new()
	n.position = at
	root.add_child(n)
	Kit.cyl(n, 0.9, 1.0, 0.5, Vector3(0, 0.25, 0), stone, 8)
	Kit.cyl(n, 0.22, 0.26, 3.4, Vector3(0, 2.2, 0), stone, 8)
	for k in 3:
		Kit.cyl(n, 0.32, 0.32, 0.08, Vector3(0, 1.0 + k * 1.1, 0), Kit.mat("#a39780", 0.85), 8)
	Kit.cyl(n, 1.0, 0.85, 0.12, Vector3(0, 3.95, 0), stone, 8)
	for k in 8:
		var a := TAU * float(k) / 8.0
		Kit.rod(n, Vector3(cos(a) * 0.8, 4.0, sin(a) * 0.8), Vector3(cos(a) * 0.8, 4.8, sin(a) * 0.8), 0.04, stone, 6)
	Kit.cyl(n, 0.0, 1.1, 0.7, Vector3(0, 5.15, 0), Kit.mat("#8a7d66", 0.8), 8)
	Kit.ball(n, 0.12, Vector3(0, 5.55, 0), Kit.mat("#c9a14a", 0.4, 0.0, 0.8), 10)


func _wires(root: Node3D) -> void:
	var r := Kit.rng("wires")
	var black := Kit.mat("#0d0d0e", 0.6)
	for i in 14:
		var z := r.randf_range(-24.0, 8.0)
		var y0 := r.randf_range(4.6, 6.4)
		var a := Vector3(-2.3, y0, z)
		var b := Vector3(2.3, y0 + r.randf_range(-0.6, 0.6), z + r.randf_range(-4.0, 4.0))
		var sag := r.randf_range(0.25, 0.7)
		var prev := a
		for k in range(1, 9):
			var u := float(k) / 8.0
			var p := a.lerp(b, u) - Vector3(0, sag * 4.0 * u * (1.0 - u), 0)
			Kit.rod(root, prev, p, 0.012, black, 4)
			prev = p


func _lights(root: Node3D) -> void:
	# The sodium lamp on a bracket over the auto; a tube light at a shop further down; spill from windows.
	var lamp := Vector3(-2.1, 5.2, 1.2)
	Kit.rod(root, Vector3(-2.3, 5.4, 1.2), Vector3(-1.4, 5.25, 1.2), 0.035, Kit.mat("#2b2b2b", 0.6), 6)
	Kit.box(root, Vector3(0.45, 0.12, 0.22), Vector3(-1.3, 5.2, 1.2), Kit.mat("#30302e", 0.5))
	Kit.box(root, Vector3(0.36, 0.03, 0.16), Vector3(-1.3, 5.13, 1.2), Kit.lit("#ffb043", 6.0))
	Kit.spot(root, Vector3(-1.3, 5.05, 1.2), Vector3(0.4, 0, -0.5), "#ffa53c", 14.0, 18.0, 62.0, true, 1.2)
	Kit.box(root, Vector3(0.04, 0.04, 1.2), Vector3(2.15, 3.1, -6.5), Kit.lit("#eef6ff", 4.0))
	Kit.spot(root, Vector3(2.0, 3.0, -6.5), Vector3(0.0, 0, -6.5), "#dfeaff", 3.0, 9.0, 70.0, false, 0.8)
	Kit.omni(root, Vector3(0, 6.0, -18.0), "#ffb15a", 2.0, 14.0, false, 0.8)
	Kit.omni(root, Vector3(0.5, 1.6, 4.5), "#8a9cc4", 0.4, 6.0, false, 0.3)


## The auto-rickshaw: a single front wheel under a rounded nose, a windshield, a black body with a
## yellow canvas canopy on a frame, a bench seat at the back, two rear wheels, the meter on the left.
func _build_auto() -> Node3D:
	var a := Node3D.new()
	a.position = AUTO_AT
	var black := Kit.mat("#141414", 0.32, 0.0, 0.75)
	var yellow := Kit.mat("#e3b41c", 0.55)
	var chrome := Kit.mat("#c9ccd0", 0.15, 0.0, 0.95)
	var tyre := Kit.mat("#121212", 0.85)
	# Body: floor pan and side tub (y 0.3..0.85), nose at -z.
	Kit.slab(a, Vector3(1.3, 0.12, 1.9), 0.15, Vector3(0, 0.32, 0.35), black)
	Kit.slab(a, Vector3(1.32, 0.42, 0.95), 0.25, Vector3(0, 0.58, 0.85), black)
	for s in [-1.0, 1.0]:
		Kit.box(a, Vector3(0.04, 0.38, 0.9), Vector3(s * 0.64, 0.62, 0.0), black)
	# Nose (rounded front fascia), headlight, indicators, the front mudguard and wheel.
	Kit.slab(a, Vector3(0.8, 0.7, 0.45), 0.2, Vector3(0, 0.7, -0.75), black)
	Kit.ball(a, 0.42, Vector3(0, 0.95, -0.8), black, 20, Vector3(1.0, 0.85, 0.6))
	var hl := Kit.cyl(a, 0.1, 0.1, 0.06, Vector3(0, 0.82, -1.0), Kit.lit("#fff3d6", 2.5), 18, Vector3(PI / 2, 0, 0))
	Kit.cyl(a, 0.115, 0.115, 0.05, Vector3(0, 0.82, -0.99), chrome, 18, Vector3(PI / 2, 0, 0))
	Kit.spot(a, Vector3(0, 0.82, -1.05), Vector3(0, 0.0, -7.0), "#fff1d0", 2.5, 12.0, 30.0, true, 0.8)
	for s in [-1.0, 1.0]:
		Kit.ball(a, 0.035, Vector3(s * 0.3, 0.98, -0.98), Kit.lit("#ffa21a", 1.2), 8)
	Kit.ball(a, 0.23, Vector3(0, 0.3, -0.98), black, 16, Vector3(0.5, 0.6, 1.0))
	var fw := Node3D.new()
	fw.position = Vector3(0, 0.2, -0.98)
	a.add_child(fw)
	Kit.cyl(fw, 0.2, 0.2, 0.1, Vector3.ZERO, tyre, 20, Vector3(0, 0, PI / 2))
	Kit.cyl(fw, 0.1, 0.1, 0.11, Vector3.ZERO, chrome, 12, Vector3(0, 0, PI / 2))
	_wheel_nodes.append(fw)
	for s in [-1.0, 1.0]:
		var rw := Node3D.new()
		rw.position = Vector3(s * 0.58, 0.2, 0.95)
		a.add_child(rw)
		Kit.cyl(rw, 0.2, 0.2, 0.12, Vector3.ZERO, tyre, 20, Vector3(0, 0, PI / 2))
		Kit.cyl(rw, 0.1, 0.1, 0.13, Vector3.ZERO, chrome, 12, Vector3(0, 0, PI / 2))
		_wheel_nodes.append(rw)
	# Windshield with a black frame, a wiper; handlebar; the driver's seat.
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.7, 0.8, 0.85, 0.18)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	glass.metallic_specular = 1.0
	Kit.box(a, Vector3(1.0, 0.6, 0.02), Vector3(0, 1.42, -0.62), glass, Vector3(0.18, 0, 0))
	Kit.box(a, Vector3(1.06, 0.05, 0.05), Vector3(0, 1.72, -0.57), black)
	Kit.box(a, Vector3(1.06, 0.05, 0.05), Vector3(0, 1.12, -0.68), black)
	Kit.rod(a, Vector3(-0.2, 1.15, -0.66), Vector3(0.1, 1.55, -0.6), 0.008, black, 4)
	Kit.rod(a, Vector3(-0.32, 1.12, -0.42), Vector3(0.32, 1.12, -0.42), 0.018, chrome, 8)
	Kit.rod(a, Vector3(0, 1.0, -0.58), Vector3(0, 1.12, -0.42), 0.025, black, 8)
	Kit.slab(a, Vector3(0.5, 0.1, 0.42), 0.08, Vector3(0, 0.82, -0.05), Kit.mat("#2a1c14", 0.6))
	# Passenger bench (red rexine) and backrest.
	Kit.slab(a, Vector3(1.15, 0.14, 0.45), 0.08, Vector3(0, 0.9, 0.78), Kit.mat("#7a1e1c", 0.45))
	Kit.slab(a, Vector3(1.15, 0.5, 0.1), 0.06, Vector3(0, 1.2, 1.02), Kit.mat("#7a1e1c", 0.45))
	# Canopy: steel frame, yellow canvas roof with a black band, open sides.
	var frame := Kit.mat("#1a1a1a", 0.4, 0.0, 0.6)
	for s in [-1.0, 1.0]:
		Kit.rod(a, Vector3(s * 0.62, 0.85, -0.5), Vector3(s * 0.6, 1.95, -0.45), 0.02, frame, 6)
		Kit.rod(a, Vector3(s * 0.62, 0.85, 1.1), Vector3(s * 0.62, 1.95, 1.05), 0.02, frame, 6)
	Kit.slab(a, Vector3(1.36, 0.1, 1.85), 0.3, Vector3(0, 2.0, 0.3), yellow)
	Kit.box(a, Vector3(1.38, 0.08, 1.87), Vector3(0, 1.92, 0.3), black)
	Kit.box(a, Vector3(1.3, 1.05, 0.02), Vector3(0, 1.45, 1.22), yellow)
	Kit.box(a, Vector3(0.6, 0.18, 0.025), Vector3(0, 1.65, 1.235), Kit.mat("#1a1a1a", 0.6))
	# Number plate (Gujarat), a small tassel of lemons and chillies hanging under the nose.
	var plate := Node3D.new()
	plate.position = Vector3(0, 0.5, -0.99)
	plate.rotation = Vector3(0, PI, 0)
	a.add_child(plate)
	Kit.box(plate, Vector3(0.36, 0.12, 0.01), Vector3.ZERO, Kit.mat("#f1eee4", 0.5))
	Kit.text(plate, "GJ 01 TX 4721", 0.05, Color("161616"), Vector3(0, 0, -0.008), Vector3(0, PI, 0))
	Kit.rod(a, Vector3(0, 0.42, -1.0), Vector3(0, 0.25, -1.02), 0.004, Kit.mat("#2a2a2a", 0.6), 4)
	Kit.ball(a, 0.025, Vector3(0, 0.25, -1.02), Kit.mat("#e2d443", 0.5), 8, Vector3(1, 1.3, 1))
	for k in 3:
		Kit.cyl(a, 0.006, 0.0, 0.07, Vector3(-0.015 + 0.015 * k, 0.19, -1.02), Kit.mat("#2e7d2e", 0.5), 6)
	# The fare meter: a black box on a bracket left of the handlebar, red LED digits, a flag lever.
	var meter := Node3D.new()
	meter.name = "meter"
	meter.position = Vector3(-0.38, 1.24, -0.5)
	meter.rotation = Vector3(-0.35, 0.25, 0)
	a.add_child(meter)
	Kit.rod(a, Vector3(-0.38, 1.0, -0.56), Vector3(-0.38, 1.17, -0.52), 0.015, black, 6)
	Kit.slab(meter, Vector3(0.24, 0.13, 0.1), 0.02, Vector3.ZERO, Kit.mat("#17181b", 0.35, 0.0, 0.7))
	Kit.box(meter, Vector3(0.19, 0.06, 0.01), Vector3(0, 0.02, 0.05), Kit.mat("#2a0606", 0.1, 0.0, 0.9))
	_meter_text = Kit.text(meter, "0.00", 0.045, Color(1.0, 0.16, 0.1), Vector3(0, 0.02, 0.057), Vector3.ZERO, true, 4.0)
	Kit.text(meter, "FARE  ₹", 0.014, Color("b9b9b9"), Vector3(0, -0.035, 0.056), Vector3.ZERO, false)
	_meter_flag = Node3D.new()
	_meter_flag.position = Vector3(0.13, 0.05, 0)
	meter.add_child(_meter_flag)
	Kit.box(_meter_flag, Vector3(0.012, 0.1, 0.012), Vector3(0, 0.05, 0), chrome)
	Kit.box(_meter_flag, Vector3(0.05, 0.03, 0.01), Vector3(0.02, 0.1, 0), Kit.mat("#c4282b", 0.5))
	Kit.omni(meter, Vector3(0, 0.03, 0.15), "#ff3a22", 0.06, 0.6, false, 0.1)
	Kit.omni(a, Vector3(0, 1.75, 0.2), "#ffd9a0", 0.35, 2.2, false, 0.2)
	return a


func _fare(key: String, t: float) -> float:
	var m = _p.get(key, null)
	if not (m is Dictionary):
		return -1.0
	var s := float(m.get("start", 1e9))
	var l := float(m.get("land", s + 1.0))
	if t < s:
		return -1.0
	return float(m.get("to", 10)) * Motion.out_cubic(clampf((t - s) / maxf(l - s, 0.01), 0.0, 1.0))


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	# Meter: flag down when it starts, digits run up and land.
	var f1 := _fare("meter", t)
	var f2 := _fare("meter2", t)
	var fare := f2 if f2 >= 0.0 else f1
	_meter_text.text = "%.2f" % maxf(fare, 0.0) if fare >= 0.0 else "- - -"
	var flag_down := fare >= 0.0
	_meter_flag.rotation = Vector3(0, 0, -1.4 if flag_down else 0.0)
	# The auto pulls away at the end.
	var dt := float(_p.get("drive", 1e9))
	var dz := 0.0
	if t > dt:
		dz = -0.9 * pow(t - dt, 2.0)
	_auto.position = AUTO_AT + Vector3(0, 0, dz)
	for w in _wheel_nodes:
		(w as Node3D).rotation = Vector3(dz / 0.2, 0, 0)
	# The gold streak: MOM climbs from behind the auto over the roofs into the sky, with a trail.
	var s_on := false
	var path := func(u: float) -> Vector3: return Vector3(0.3, 1.4, 2.5).lerp(Vector3(-0.5, 30.0, 26.0), u) + Vector3(sin(u * PI) * 1.5, 0, -sin(u * PI) * 6.0)
	for key in ["streak", "streak2"]:
		var w = _p.get(key, null)
		if w is Array and w.size() >= 2 and t >= float(w[0]) - 0.1 and t <= float(w[1]) + 0.6:
			s_on = true
			var u := Motion.in_out(clampf((t - float(w[0])) / maxf(float(w[1]) - float(w[0]), 0.01), 0.0, 1.0))
			var p: Vector3 = path.call(u) if key == "streak" else Vector3(-12.0, 15.0, 22.0).lerp(Vector3(12.0, 19.0, 30.0), u)
			_streak.position = p
			_streak.rotation = Vector3(-0.6, t * 0.8, 0.3)
			var im := ImmediateMesh.new()
			im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _trail_mat)
			for k in 24:
				var uu := maxf(u - 0.012 * k, 0.0)
				var q: Vector3 = path.call(uu) if key == "streak" else Vector3(-12.0, 15.0, 22.0).lerp(Vector3(12.0, 19.0, 30.0), uu)
				var wdt := 0.35 * (1.0 - float(k) / 24.0)
				im.surface_add_vertex(q + Vector3(wdt, 0, 0))
				im.surface_add_vertex(q - Vector3(wdt, 0, 0))
			im.surface_end()
			_trail.mesh = im
	_streak.visible = s_on
	_trail.visible = s_on
	return {"meter": gt * (_auto.position + Vector3(-0.38, 1.24, -0.5)), "auto": gt * _auto.position,
		"sky": gt * Vector3(-1.0, 20.0, -30.0), "streak": gt * _streak.position, "chabutro": gt * Vector3(-0.2, 3.0, -13),
		"driver_seat": gt * (_auto.position + Vector3(0, 0.88, -0.05))}
