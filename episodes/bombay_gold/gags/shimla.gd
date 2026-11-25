## Shimla, 14 April 1944, ~16:06: (1) the hill town on its ridge, colonial buildings with red and green tin roofs among
## deodar forest, ranges fading into haze; (2) a quiet instrument room in the observatory: a seismograph's smoked-paper
## drum turning under a stylus, a glass case, a desk with a glass of water, a hanging lamp. On `shock` the stylus
## swings and scrawls a spike; the water ripples; the lamp sways.
##
## Local frame: (1) the town around the origin, the ridge along x, valley toward +z (cameras out in the valley at +z);
## (2) the room at ROOM (z +600): the drum at ROOM + (0, 1.1, 0) along x, cameras at +z looking -z.
##
## params: shock t
## anchors: ridge, drum, stylus, glass
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")

const PH := "incoming/bombay_gold/polyhaven/"
const PH0 := "incoming/polyhaven_pokhran/models/"
const ROOM := Vector3(0, 0, 600)

const TRACE := """
shader_type spatial;
render_mode cull_back;
uniform float t = 0.0;
uniform float shock = 1000000.0;
uniform float turn_speed = 0.06;
float trace_at(float tt) {
	float a = 0.015 * sin(tt * 23.0) + 0.01 * sin(tt * 51.0 + 1.3);
	if (tt > shock) {
		float k = tt - shock;
		a += 0.32 * exp(-k * 1.1) * sin(k * 38.0) * smoothstep(0.0, 0.08, k);
	}
	return a;
}
void fragment() {
	// UV.x runs round the drum; the stylus sits at u = 0.25 (facing the camera). The paper behind it holds the past.
	float u = fract(UV.x - t * turn_speed);
	float age = fract(0.25 - u) / turn_speed;
	float tt = t - age;
	vec3 paper = vec3(0.12, 0.11, 0.1);
	float lanes = 0.0;
	for (int i = 0; i < 7; i++) {
		float y = 0.14 + float(i) * 0.12;
		float tr = (i == 3) ? trace_at(tt) : 0.012 * sin(tt * 19.0 + float(i) * 7.0);
		lanes = max(lanes, 1.0 - smoothstep(0.003, 0.007, abs(UV.y - y - tr)));
	}
	ALBEDO = mix(paper, vec3(0.92, 0.9, 0.84), lanes);
	ROUGHNESS = 0.8;
}
"""

const RIPPLE := """
shader_type spatial;
uniform float amp = 0.0;
uniform float t = 0.0;
void vertex() {
	float r = length(VERTEX.xz);
	VERTEX.y += amp * sin(r * 160.0 - t * 30.0) * exp(-r * 18.0);
}
void fragment() {
	ALBEDO = vec3(0.6, 0.7, 0.75);
	ROUGHNESS = 0.05;
	METALLIC = 0.3;
	ALPHA = 0.7;
}
"""

var _p := {}
var _trace_mat: ShaderMaterial
var _drum: Node3D
var _stylus: Node3D
var _water: ShaderMaterial
var _lamp: Node3D
var _glass_pos := Vector3.ZERO


func _tex(name: String, scale: float, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var b := PH + "textures/" + name
	return Kit.textured(b + "_diff_2k.jpg", b + "_nor_gl_2k.jpg", b + "_rough_2k.jpg", Vector3.ONE * scale, tint, true)


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "shimla"))
	_town(root)
	_room(root)
	return root


var _noise: FastNoiseLite


func _height(x: float, z: float) -> float:
	var h := 0.0
	if z > 10.0:
		h = -(z - 10.0) * 0.42
	elif z < -40.0:
		h = (-40.0 - z) * 0.22
	h += _noise.get_noise_2d(x, z) * (14.0 + maxf(-z, 0.0) * 0.06 + maxf(z, 0.0) * 0.05)
	return h


func _terrain(root: Node3D, x0: float, x1: float, z0: float, z1: float, n: int, hf: Callable, colf: Callable) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dx := (x1 - x0) / n
	var dz := (z1 - z0) / n
	var pts := []
	for j in n + 1:
		for i in n + 1:
			var x := x0 + i * dx
			var z := z0 + j * dz
			pts.append(Vector3(x, hf.call(x, z), z))
	for j in n:
		for i in n:
			var a: Vector3 = pts[j * (n + 1) + i]
			var b: Vector3 = pts[j * (n + 1) + i + 1]
			var c: Vector3 = pts[(j + 1) * (n + 1) + i]
			var d: Vector3 = pts[(j + 1) * (n + 1) + i + 1]
			for tri in [[a, b, c], [b, d, c]]:
				for v in tri:
					var e := 2.0 * dx
					var nrm := Vector3(float(hf.call(v.x - e, v.z)) - float(hf.call(v.x + e, v.z)), 2.0 * e,
						float(hf.call(v.x, v.z - e)) - float(hf.call(v.x, v.z + e))).normalized()
					st.set_color(colf.call(v, nrm))
					st.set_normal(nrm)
					st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	root.add_child(mi)


func _town(root: Node3D) -> void:
	var rng := Kit.rng("shimla")
	_noise = FastNoiseLite.new()
	_noise.seed = 1944
	_noise.frequency = 0.006
	_noise.fractal_octaves = 5
	# The near hills: the town ridge, the valley falling toward the camera, foothills rising behind.
	_terrain(root, -900.0, 900.0, -900.0, 500.0, 180, func(x, z): return _height(x, z),
		func(v: Vector3, nrm: Vector3) -> Color:
			var forest := Color("#1f3018")
			var grass := Color("#4e5e34")
			var rock := Color("#6a6458")
			var c := forest.lerp(grass, clampf(_noise.get_noise_2d(v.x * 3.0, v.z * 3.0) * 1.5 + 0.2, 0.0, 1.0))
			return c.lerp(rock, clampf((0.75 - nrm.y) * 3.0, 0.0, 1.0)))
	# The far ranges: blue foothills, then the snow peaks.
	var far := FastNoiseLite.new()
	far.seed = 7
	far.frequency = 0.0012
	far.fractal_octaves = 5
	_terrain(root, -4000.0, 4000.0, -5200.0, -900.0, 160,
		func(x, z):
			var k := clampf((-900.0 - z) / 4300.0, 0.0, 1.0)
			return 200.0 + k * 1900.0 * (0.55 + 0.45 * far.get_noise_2d(x, z)) + far.get_noise_2d(x * 3.0, z * 3.0) * 160.0 * k,
		func(v: Vector3, nrm: Vector3) -> Color:
			var c := Color("#2e3a44").lerp(Color("#5a6a80"), clampf((v.y - 200.0) / 900.0, 0.0, 1.0))
			if v.y > 1350.0 and nrm.y > 0.55:
				c = c.lerp(Color("#f2f4f8"), clampf((v.y - 1350.0) / 250.0, 0.0, 1.0))
			return c)
	# Colonial buildings strung along the ridge: plastered walls, tin roofs (red / green), on the ground.
	var walls := [_tex("white_plaster_rough_02", 0.3, Color(0.92, 0.9, 0.84)), _tex("yellow_plaster", 0.3, Color(0.94, 0.86, 0.7))]
	var roofs := [Kit.mat("#8a2e26", 0.6, 0.5), Kit.mat("#2e5a3c", 0.6, 0.5)]
	for k in 46:
		var x := -300.0 + k * 13.0 + rng.randf_range(-4, 4)
		var z := rng.randf_range(-35, 30)
		var w := rng.randf_range(9, 16)
		var hgt := rng.randf_range(7, 13)
		var y := minf(_height(x - w * 0.4, z), _height(x + w * 0.4, z)) - 1.0
		var c := Vector3(x, y + hgt * 0.5, z)
		Kit.box(root, Vector3(w, hgt + 2.0, 9), c - Vector3(0, 1.0, 0), walls[k % 2])
		var roof := Kit.cyl(root, 0.0, w * 0.72, 4.0, c + Vector3(0, hgt * 0.5 + 2.0, 0), roofs[(k / 2) % 2], 4, Vector3(0, PI * 0.25, 0))
		roof.scale = Vector3(1.0, 1.0, 0.7)
		for wi in int(w / 3.0):
			Kit.box(root, Vector3(1.2, 1.8, 0.1), Vector3(x - w * 0.5 + 1.5 + wi * 3.0, y + hgt * 0.6, z + 4.55), Kit.mat("#1a1c20", 0.3, 0.2))
	# Christ Church's tower on the Ridge, a landmark.
	var cy := _height(30, -18)
	Kit.box(root, Vector3(7, 26, 7), Vector3(30, cy + 13, -18), walls[1])
	Kit.cyl(root, 0.0, 5.0, 9.0, Vector3(30, cy + 30.5, -18), roofs[0], 4, Vector3(0, PI * 0.25, 0))
	# Deodar forest on the slopes (on the ground height).
	var ps: PackedScene = KitDB.scene("quaternius_nature/PineTree_2")
	var ps2: PackedScene = KitDB.scene("quaternius_nature/PineTree_4")
	for k in 900:
		var x := rng.randf_range(-600, 600)
		var z := rng.randf_range(-260, 420)
		if absf(x) < 320.0 and z > -45.0 and z < 35.0:
			continue
		if _noise.get_noise_2d(x * 3.0, z * 3.0) > 0.25:
			continue
		var tr: Node3D = (ps if k % 2 == 0 else ps2).instantiate()
		tr.position = Vector3(x, _height(x, z) - 0.5, z)
		tr.scale = Vector3.ONE * rng.randf_range(6.5, 10.0)
		tr.rotation.y = rng.randf() * TAU
		root.add_child(tr)


func _room(root: Node3D) -> void:
	var r := ROOM
	var wall := _tex("white_plaster_rough_02", 0.6, Color(0.88, 0.86, 0.8))
	Kit.box(root, Vector3(8, 0.1, 8), r + Vector3(0, -0.05, 0), _tex("old_wooden_floor_02", 0.8))
	Kit.box(root, Vector3(8, 4, 0.2), r + Vector3(0, 2, -3.0), wall)
	Kit.box(root, Vector3(0.2, 4, 8), r + Vector3(-3.5, 2, 0), wall)
	Kit.box(root, Vector3(0.2, 4, 8), r + Vector3(3.5, 2, 0), wall)
	Kit.box(root, Vector3(8, 0.1, 8), r + Vector3(0, 4.0, 0), Kit.mat("#e8e4da", 0.9))
	# A window onto the hills (bright), the instrument on a heavy pier with a glass case.
	Kit.box(root, Vector3(1.6, 1.8, 0.05), r + Vector3(2.2, 2.2, -2.88), Kit.flat("#c8d4dc"))
	Kit.box(root, Vector3(1.4, 1.0, 0.9), r + Vector3(0, 0.5, -1.8), Kit.mat("#6a6460", 0.9))
	var brass := Kit.mat("#b8892e", 0.3, 0.9)
	var black := Kit.mat("#141414", 0.4, 0.5)
	Kit.box(root, Vector3(1.3, 0.05, 0.8), r + Vector3(0, 1.02, -1.8), Kit.mat("#3a2a1e", 0.6))
	_drum = Node3D.new()
	_drum.position = r + Vector3(0, 1.28, -1.85)
	root.add_child(_drum)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.17
	cyl.bottom_radius = 0.17
	cyl.height = 0.72
	cyl.radial_segments = 64
	var dm := MeshInstance3D.new()
	dm.mesh = cyl
	_trace_mat = Kit.shader(TRACE)
	dm.material_override = _trace_mat
	dm.rotation = Vector3(0, 0, PI * 0.5)
	_drum.add_child(dm)
	for sx: float in [-1.0, 1.0]:
		Kit.cyl(root, 0.04, 0.04, 0.3, r + Vector3(sx * 0.42, 1.14, -1.85), brass, 12)
		Kit.box(root, Vector3(0.04, 0.3, 0.04), r + Vector3(sx * 0.42, 1.14, -1.85), brass)
	Kit.rod(root, r + Vector3(-0.42, 1.28, -1.85), r + Vector3(0.42, 1.28, -1.85), 0.012, brass, 8)
	# The stylus: a long thin arm from the pendulum housing behind, its tip on the drum's front.
	_stylus = Node3D.new()
	_stylus.position = r + Vector3(-0.05, 1.28, -1.4)
	root.add_child(_stylus)
	Kit.rod(_stylus, Vector3(0, 0, 0), Vector3(0, 0, -0.27), 0.004, black, 6)
	Kit.box(root, Vector3(0.3, 0.3, 0.3), r + Vector3(-0.05, 1.28, -1.2), brass)
	# The glass case.
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.8, 0.9, 0.95, 0.12)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.02
	glass.metallic = 0.4
	Kit.box(root, Vector3(1.3, 0.6, 0.02), r + Vector3(0, 1.35, -1.38), glass)
	Kit.box(root, Vector3(1.3, 0.02, 0.8), r + Vector3(0, 1.66, -1.8), glass)
	# A desk with a log book, a lamp, a glass of water.
	_place(root, PH0 + "metal_office_desk/metal_office_desk_2k.gltf", r + Vector3(1.6, 0, -0.6), PI, 1.0)
	_glass_pos = r + Vector3(1.1, 0.78, -0.4)
	Kit.cyl(root, 0.035, 0.03, 0.11, _glass_pos + Vector3(0, 0.055, 0), glass, 16)
	var wplane := PlaneMesh.new()
	wplane.size = Vector2(0.064, 0.064)
	wplane.subdivide_width = 24
	wplane.subdivide_depth = 24
	var wmi := MeshInstance3D.new()
	wmi.mesh = wplane
	_water = Kit.shader(RIPPLE)
	wmi.material_override = _water
	wmi.position = _glass_pos + Vector3(0, 0.09, 0)
	root.add_child(wmi)
	_lamp = Node3D.new()
	_lamp.position = r + Vector3(0, 4.0, -1.4)
	root.add_child(_lamp)
	Kit.rod(_lamp, Vector3.ZERO, Vector3(0, -1.6, 0), 0.008, black, 5)
	Kit.cyl(_lamp, 0.06, 0.26, 0.2, Vector3(0, -1.7, 0), Kit.mat("#2e4a3a", 0.5, 0.3), 20)
	Kit.ball(_lamp, 0.06, Vector3(0, -1.78, 0), Kit.lit("#ffdca0", 4.0), 12)
	var l := Kit.omni(_lamp, Vector3(0, -1.85, 0), "#ffd8a0", 2.2, 5.0, true, 0.6)
	l.name = "lamp_light"
	Kit.spot(root, r + Vector3(4.0, 3.2, -4.0), r + Vector3(0, 1.2, -1.8), "#ffe4c0", 6.0, 10.0, 25.0, true, 2.0)


func _place(root: Node3D, rel: String, pos: Vector3, yaw: float, s: float) -> Node3D:
	var n := Kit.model(rel)
	n.position = pos
	n.rotation.y = yaw
	n.scale = Vector3.ONE * s
	root.add_child(n)
	return n


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var shock := float(_p.get("shock", 1e9))
	_trace_mat.set_shader_parameter("t", t)
	_trace_mat.set_shader_parameter("shock", shock)
	var k := t - shock
	var amp := 0.0
	if k > 0.0:
		amp = 0.32 * exp(-k * 1.1) * sin(k * 38.0) * clampf(k / 0.08, 0.0, 1.0)
	var idle := 0.015 * sin(t * 23.0) + 0.01 * sin(t * 51.0 + 1.3)
	# The stylus tip follows the trace (the lane at v 0.5 of a 0.72 m drum: 1 unit = 0.72 m).
	_stylus.rotation.y = (idle + amp) * 0.72 / 0.27
	_drum.rotation.x = -t * 0.06 * TAU
	_water.set_shader_parameter("t", t)
	_water.set_shader_parameter("amp", 0.004 * exp(-maxf(k, 0.0) * 0.6) if k > 0.0 else 0.0)
	_lamp.rotation.z = (0.08 * exp(-k * 0.5) * sin(k * 3.0)) if k > 0.0 else 0.0
	return {"ridge": gt * Vector3(0, 10, -10), "drum": gt * (ROOM + Vector3(0, 1.28, -1.68)), "stylus": gt * (ROOM + Vector3(-0.05, 1.3, -1.65)),
		"glass": gt * _glass_pos}
