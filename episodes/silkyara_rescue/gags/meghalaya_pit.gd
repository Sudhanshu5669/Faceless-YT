extends RefCounted
## A rat-hole coal pit in Meghalaya's Jaintia Hills (line 18): a square shaft dug straight down through sandstone to
## a thin black coal seam, with low "rat holes" burrowed sideways into the seam, just big enough to crawl into.
##
## Local frame: the grassy plateau at y = 0; the pit centred on the origin, PIT wide, DEPTH deep; the seam near the
## bottom; the rat holes go into the north wall (toward -z). A bamboo ladder on the east wall, a wooden tripod with a
## rope and a cane basket at the rim, coal heaps and sacks around, pines on the ridges.
##
## params:
##   crawl  {"who", "t0", "t1" (he crawls into the middle hole between these), "grit" (the roof sheds grit)}
##   tape   {"who", "t0", "t1" (the official walks the barrier tape from post A to post B)}
## anchors: hole (the middle rat hole's mouth), notice (the order pinned on post A), rim (the pit's south edge)

const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const PIT := 5.0
const DEPTH := 10.0
const SEAM0 := -10.05       # the coal seam, at the bottom of the shaft (the holes open at floor level)
const SEAM1 := -9.05
const HOLES := [-1.5, 0.0, 1.5]   # rat-hole centres along x on the north wall
const HOLE_W := 0.85
const HOLE_H := 0.72
const HOLE_LEN := 4.0
const POST_A := Vector3(-3.4, 0.0, 3.4)
const POST_B := Vector3(3.4, 0.0, 3.4)

const NOISE_GLSL := """
float h3(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float n3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
float fbm(vec3 p) { return n3(p) * 0.55 + n3(p * 2.1 + 7.0) * 0.3 + n3(p * 4.3 + 3.0) * 0.15; }
"""

## The plateau: dry winter grass, bare earth, black coal dust spreading out from the pit and the heaps.
const GROUND_SHADER := """
shader_type spatial;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
//NOISE
uniform vec3 pit_world = vec3(0.0);
void fragment() {
	vec3 lp = wp - pit_world;
	float n = fbm(lp * 0.35);
	vec3 grass = mix(vec3(0.33, 0.36, 0.17), vec3(0.47, 0.42, 0.24), n);
	vec3 earth = vec3(0.36, 0.27, 0.19) * (0.8 + 0.4 * fbm(lp * 2.0));
	vec3 col = mix(grass, earth, smoothstep(0.5, 0.7, fbm(lp * 0.8 + 4.0)));
	float coal = (1.0 - smoothstep(3.5, 9.0, length(lp.xz))) * (0.6 + 0.4 * fbm(lp * 1.5));
	col = mix(col, vec3(0.06, 0.06, 0.065), clamp(coal, 0.0, 0.9));
	ALBEDO = col;
	ROUGHNESS = 0.95;
}
"""

## The pit walls: sandstone and shale in bands, wet streaks, the coal seam black and glinting near the bottom.
const WALL_SHADER := """
shader_type spatial;
render_mode cull_disabled;
varying vec3 lp;
void vertex() { lp = VERTEX; }
//NOISE
void fragment() {
	float y = lp.y + fbm(lp * 0.6) * 0.5;
	float band = fbm(vec3(0.0, y * 2.2, 0.0));
	vec3 sand = mix(vec3(0.55, 0.43, 0.3), vec3(0.42, 0.36, 0.3), band);
	sand = mix(sand, vec3(0.3, 0.29, 0.28), smoothstep(0.55, 0.7, fbm(vec3(lp.x * 0.3, y * 6.0, lp.z * 0.3))));
	float seam = smoothstep(-10.1, -10.0, lp.y) * (1.0 - smoothstep(-9.1, -9.0, lp.y));
	vec3 coal = vec3(0.035, 0.035, 0.04) * (0.7 + 0.6 * n3(lp * 9.0));
	vec3 col = mix(sand, coal, seam);
	float wet = smoothstep(0.62, 0.8, fbm(vec3(lp.x * 1.5, lp.y * 0.25, lp.z * 1.5))) * (1.0 - seam);
	col *= 1.0 - wet * 0.35;
	ALBEDO = col * (0.85 + 0.3 * fbm(lp * 3.0));
	ROUGHNESS = mix(0.92, 0.45, max(seam, wet));
	METALLIC = seam * 0.15;
}
"""

## Raw coal: near-black, matt, broken into lumps, with small bright glints where the light catches a facet.
const COAL_SHADER := """
shader_type spatial;
render_mode cull_disabled;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
//NOISE
void fragment() {
	float n = fbm(wp * 7.0);
	float facet = n3(wp * 23.0);
	ALBEDO = vec3(0.028, 0.027, 0.03) * (0.6 + 0.8 * n);
	ROUGHNESS = mix(0.8, 0.55, smoothstep(0.55, 0.8, facet));
	SPECULAR = 0.45;
	float e = 0.02;
	vec3 g = vec3(fbm((wp + vec3(e, 0, 0)) * 7.0) - n, fbm((wp + vec3(0, e, 0)) * 7.0) - n, fbm((wp + vec3(0, 0, e)) * 7.0) - n) / e;
	NORMAL = normalize(NORMAL - (VIEW_MATRIX * vec4(g, 0.0)).xyz * 0.06);
}
"""

var _shaders := {}
var _crawler_scale_set := false
var _grit: MultiMesh
var _tape: MeshInstance3D
var _tape_roll: Node3D
var _root: Node3D
var _ground_mat: ShaderMaterial
var _headlamp: SpotLight3D


func _shader(code: String) -> ShaderMaterial:
	if not _shaders.has(code):
		var s := Shader.new()
		s.code = code.replace("//NOISE", NOISE_GLSL)
		_shaders[code] = s
	var m := ShaderMaterial.new()
	m.shader = _shaders[code]
	return m


func _mat(color: String, rough: float = 0.85, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = rough
	m.metallic = metal
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _rod(parent: Node3D, a: Vector3, b: Vector3, r: float, mat: Material, sides: int = 8) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = a.distance_to(b)
	mesh.radial_segments = sides
	mesh.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	var y := (b - a).normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y, x.cross(y).normalized()), (a + b) * 0.5)
	parent.add_child(mi)
	return mi


func _hash(n: float) -> float:
	return fposmod(sin(n * 127.1 + 311.7) * 43758.5453, 1.0)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for v in [a, c, b, b, c, d]:
		st.add_vertex(v)


func build(_g: Dictionary) -> Node3D:
	var root := Node3D.new()
	_root = root
	var h := PIT * 0.5
	# The plateau round the pit (four slabs leave the hole open), gently rolling away.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nz := FastNoiseLite.new()
	nz.seed = 18
	nz.frequency = 0.03
	var step := 1.0
	var x := -60.0
	while x < 60.0:
		var z := -60.0
		while z < 60.0:
			var cx := x + step * 0.5
			var cz := z + step * 0.5
			if not (absf(cx) < h and absf(cz) < h):
				var f := func(px: float, pz: float) -> float:
					var r := maxf(absf(px), absf(pz))
					return nz.get_noise_2d(px, pz) * 2.5 * smoothstep(6.0, 25.0, r) + smoothstep(25.0, 60.0, r) * 9.0
				# (b and c swapped: wound to face up)
				_quad(st, Vector3(x, f.call(x, z), z), Vector3(x, f.call(x, z + step), z + step),
					Vector3(x + step, f.call(x + step, z), z), Vector3(x + step, f.call(x + step, z + step), z + step))
			z += step
		x += step
	st.generate_normals()
	var ground := MeshInstance3D.new()
	ground.mesh = st.commit()
	var gm := _shader(GROUND_SHADER)
	ground.material_override = gm
	root.add_child(ground)
	_ground_mat = gm
	# The four walls of the shaft, the north one with the rat holes left open in the seam.
	var ws := SurfaceTool.new()
	ws.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cell := 0.25
	for side in 4:
		var u := -h
		while u < h - 0.001:
			var y := -DEPTH
			while y < -0.001:
				var mid_u := u + cell * 0.5
				var mid_y := y + cell * 0.5
				var hole := false
				if side == 0:
					for hx in HOLES:
						if absf(mid_u - float(hx)) < HOLE_W * 0.5 and mid_y > SEAM0 + 0.07 and mid_y < SEAM0 + 0.07 + HOLE_H:
							hole = true
				if not hole:
					var j := func(px: float, py: float) -> float:
						return nz.get_noise_2d(px * 9.0 + side * 50.0, py * 9.0) * 0.08
					var p := []
					for d in [[0.0, 0.0], [cell, 0.0], [0.0, cell], [cell, cell]]:
						var uu: float = u + d[0]
						var yy: float = y + d[1]
						var out: float = j.call(uu, yy)
						match side:
							0: p.append(Vector3(uu, yy, -h - out))
							1: p.append(Vector3(-uu, yy, h + out))
							2: p.append(Vector3(h + out, yy, uu))
							3: p.append(Vector3(-h - out, yy, -uu))
					_quad(ws, p[0], p[1], p[2], p[3])
				y += cell
			u += cell
	ws.generate_normals()
	var walls := MeshInstance3D.new()
	walls.mesh = ws.commit()
	walls.material_override = _shader(WALL_SHADER)
	root.add_child(walls)
	# The floor of the pit: black wet mud, puddles, coal lumps.
	_box(root, Vector3(PIT, 0.1, PIT), Vector3(0, -DEPTH - 0.05, 0), _mat("#121112", 0.35, 0.1))
	# The rat holes: low tunnels into the seam, coal on every side.
	var coal := _shader(COAL_SHADER)
	for hx in HOLES:
		var cxh := float(hx)
		var t := Node3D.new()
		t.position = Vector3(cxh, SEAM0 + 0.07 + HOLE_H * 0.5, -h - HOLE_LEN * 0.5)
		root.add_child(t)
		_box(t, Vector3(HOLE_W, 0.04, HOLE_LEN), Vector3(0, -HOLE_H * 0.5, 0), coal)
		_box(t, Vector3(HOLE_W, 0.04, HOLE_LEN), Vector3(0, HOLE_H * 0.5, 0), coal)
		_box(t, Vector3(0.04, HOLE_H, HOLE_LEN), Vector3(-HOLE_W * 0.5, 0, 0), coal)
		_box(t, Vector3(0.04, HOLE_H, HOLE_LEN), Vector3(HOLE_W * 0.5, 0, 0), coal)
		_box(t, Vector3(HOLE_W, HOLE_H, 0.04), Vector3(0, 0, -HOLE_LEN * 0.5), coal)
		# Lumps of coal bulging round the mouth break up its outline; more inside on the walls.
		var lr := RandomNumberGenerator.new()
		lr.seed = int(cxh * 10.0) + 77
		var bump := SphereMesh.new()
		bump.radius = 0.5
		bump.height = 1.0
		bump.radial_segments = 7
		bump.rings = 4
		for k in 26:
			var a := lr.randf() * TAU
			var rr := Vector2(HOLE_W * 0.55, HOLE_H * 0.55)
			var bx := MeshInstance3D.new()
			bx.mesh = bump
			bx.material_override = coal
			var sz := lr.randf_range(0.08, 0.2)
			var depth := -lr.randf_range(0.0, HOLE_LEN * 0.9) if k >= 14 else 0.02
			bx.transform = Transform3D(Basis.from_euler(Vector3(lr.randf() * TAU, lr.randf() * TAU, 0)).scaled(Vector3(sz, sz * 0.8, sz * 0.6)),
				Vector3(cxh + cos(a) * rr.x, SEAM0 + 0.07 + HOLE_H * 0.5 + sin(a) * rr.y, -h + depth))
			root.add_child(bx)
	# Lumps of coal on the floor and a cane basket half full.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1818
	var lump := SphereMesh.new()
	lump.radius = 0.5
	lump.height = 1.0
	lump.radial_segments = 6
	lump.rings = 3
	for i in 60:
		var l := MeshInstance3D.new()
		l.mesh = lump
		l.material_override = coal
		var s := rng.randf_range(0.05, 0.2)
		l.transform = Transform3D(Basis.from_euler(Vector3(rng.randf(), rng.randf() * TAU, 0)).scaled(Vector3(s, s * 0.7, s)),
			Vector3(rng.randf_range(-h + 0.2, h - 0.2), -DEPTH + s * 0.25, rng.randf_range(-h + 0.2, h - 1.0)))
		root.add_child(l)
	var cane := _mat("#8a6a3e", 0.9)
	_basket(root, Vector3(1.4, -DEPTH, -0.8), cane)
	# A bamboo ladder lashed together on the east wall, from the floor to the rim.
	var bamboo := _mat("#9c8550", 0.8)
	var foot := Vector3(h - 0.55, -DEPTH, 1.0)
	var topp := Vector3(h - 0.05, 0.6, 1.0)
	for sz in [-0.22, 0.22]:
		_rod(root, foot + Vector3(0, 0, sz), topp + Vector3(0, 0, sz), 0.035, bamboo, 7)
	for k in 24:
		var u := (k + 0.5) / 24.0
		var p := foot.lerp(topp, u)
		_rod(root, p + Vector3(0, 0, -0.22), p + Vector3(0, 0, 0.22), 0.022, bamboo, 6)
	# The tripod hoist over the pit's south edge: three poles, a pulley, the rope down to a basket in the shaft.
	var apex := Vector3(0.0, 3.4, h - 0.3)
	for leg in [Vector3(-1.6, 0, h + 1.0), Vector3(1.6, 0, h + 1.0), Vector3(0.0, 0, h - 2.4)]:
		_rod(root, leg, apex, 0.06, _mat("#5b4430", 0.9), 7)
	_rod(root, apex + Vector3(-0.08, -0.05, 0), apex + Vector3(0.08, -0.05, 0), 0.12, _mat("#3b3b3b", 0.6, 0.5), 10)
	_rod(root, apex + Vector3(0, -0.15, 0), Vector3(0, -5.2, h - 0.3), 0.012, _mat("#c9b48a", 0.9), 5)
	_basket(root, Vector3(0, -5.75, h - 0.3), cane)
	# Round the rim: coal heaps, sacks, a couple of baskets, a hurricane lamp.
	for i in 6:
		var a := rng.randf() * TAU
		var r := rng.randf_range(7.0, 14.0)
		var heap := MeshInstance3D.new()
		heap.mesh = lump
		heap.material_override = _mat("#101012", 0.8)
		var s := rng.randf_range(1.6, 3.2)
		heap.transform = Transform3D(Basis.from_scale(Vector3(s * 1.4, s * 0.55, s)), Vector3(cos(a) * r, 0.0, sin(a) * r))
		root.add_child(heap)
	for i in 4:
		var sack := MeshInstance3D.new()
		sack.mesh = lump
		sack.material_override = _mat("#b4a27a", 0.95)
		sack.transform = Transform3D(Basis.from_scale(Vector3(0.45, 0.32, 0.35)), Vector3(-h - 1.2 - i * 0.55, 0.15, -1.0 + (i % 2) * 0.5))
		root.add_child(sack)
	_basket(root, Vector3(h + 1.5, 0.0, -1.6), cane)
	# Pines on the low ridges all round.
	var pines := ["quaternius_nature_mega/Pine_1", "quaternius_nature_mega/Pine_2", "quaternius_nature_mega/Pine_4"]
	for i in 70:
		var a := rng.randf() * TAU
		var r := rng.randf_range(16.0, 55.0)
		var tree := KitDB.static_node(pines[i % pines.size()], rng.randf_range(1.4, 2.4))
		var px := cos(a) * r
		var pz := sin(a) * r
		var rr := maxf(absf(px), absf(pz))
		tree.position = Vector3(px, nz.get_noise_2d(px, pz) * 2.5 * smoothstep(6.0, 25.0, rr) + smoothstep(25.0, 60.0, rr) * 9.0 - 0.2, pz)
		tree.rotation.y = rng.randf() * TAU
		root.add_child(tree)
	# Posts for the barrier tape, and the order pinned to the first.
	for post in [POST_A, POST_B]:
		_rod(root, post, post + Vector3(0, 1.3, 0), 0.05, _mat("#6b5035", 0.9), 7)
	_build_notice(root)
	var tm := StandardMaterial3D.new()
	tm.albedo_texture = _tape_texture()
	tm.uv1_scale = Vector3(6.8 / 0.6, 1, 1)
	tm.cull_mode = BaseMaterial3D.CULL_DISABLED
	tm.roughness = 0.5
	var q := QuadMesh.new()
	q.size = Vector2(1.0, 0.07)
	_tape = MeshInstance3D.new()
	_tape.mesh = q
	_tape.material_override = tm
	_tape.visible = false
	root.add_child(_tape)
	_tape_roll = Node3D.new()
	root.add_child(_tape_roll)
	_rod(_tape_roll, Vector3(0, -0.04, 0), Vector3(0, 0.04, 0), 0.06, _mat("#d8d6cf", 0.6), 12)
	_tape_roll.visible = false
	# The crawler's headlamp (the helmet's lamp is only a lens): a real beam that follows his head.
	_headlamp = SpotLight3D.new()
	_headlamp.light_color = Color("#fff1d8")
	_headlamp.light_energy = 2.6
	_headlamp.spot_range = 7.0
	_headlamp.spot_angle = 24.0
	_headlamp.shadow_enabled = true
	_headlamp.light_volumetric_fog_energy = 2.0
	root.add_child(_headlamp)
	# Grit from the hole's roof.
	_grit = MultiMesh.new()
	_grit.transform_format = MultiMesh.TRANSFORM_3D
	_grit.mesh = lump
	_grit.instance_count = 50
	var gmi := MultiMeshInstance3D.new()
	gmi.multimesh = _grit
	gmi.material_override = _mat("#2a2622", 0.9)
	root.add_child(gmi)
	# Light: the sun from above leaves the bottom in deep shadow; skylight bouncing down the shaft.
	var bounce := OmniLight3D.new()
	bounce.position = Vector3(0, -5.0, 1.0)
	bounce.light_color = Color("#c9b99a")
	bounce.light_energy = 0.35
	bounce.omni_range = 9.0
	root.add_child(bounce)
	return root


func _basket(root: Node3D, at: Vector3, cane: Material) -> void:
	var b := MeshInstance3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var prof := [Vector2(0.12, 0.0), Vector2(0.2, 0.15), Vector2(0.24, 0.32), Vector2(0.25, 0.34)]
	for i in prof.size() - 1:
		var a: Vector2 = prof[i]
		var c: Vector2 = prof[i + 1]
		for k in 16:
			var t0 := TAU * k / 16.0
			var t1 := TAU * (k + 1) / 16.0
			_quad(st, Vector3(cos(t0) * a.x, a.y, sin(t0) * a.x), Vector3(cos(t1) * a.x, a.y, sin(t1) * a.x),
				Vector3(cos(t0) * c.x, c.y, sin(t0) * c.x), Vector3(cos(t1) * c.x, c.y, sin(t1) * c.x))
	st.generate_normals()
	b.mesh = st.commit()
	var m := (cane as StandardMaterial3D).duplicate() as StandardMaterial3D
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	b.material_override = m
	b.position = at
	root.add_child(b)


## Red and white diagonal barrier tape (no words on it).
func _tape_texture() -> ImageTexture:
	var img := Image.create(64, 8, false, Image.FORMAT_RGBA8)
	for x in 64:
		for y in 8:
			var red := int(floor((x + y) / 8.0)) % 2 == 0
			img.set_pixel(x, y, Color("#c8261d") if red else Color("#f1eee6"))
	return ImageTexture.create_from_image(img)


## The order, pinned to post A: a printed sheet under a strip of clear plastic, a nail at each corner.
func _build_notice(root: Node3D) -> void:
	var n := Node3D.new()
	n.position = POST_A + Vector3(0, 1.05, 0.06)
	n.name = "notice"
	root.add_child(n)
	_box(n, Vector3(0.32, 0.42, 0.006), Vector3.ZERO, _mat("#f2efe6", 0.85))
	var font := load("res://fonts/baloo2/Baloo2.ttf")
	var lines := [["NATIONAL GREEN TRIBUNAL", 0.16, 30, "#1c2a4a"], ["ORDER", 0.1, 36, "#1c2a4a"],
		["Rat-hole coal mining", 0.0, 26, "#222222"], ["in Meghalaya: banned", -0.05, 26, "#222222"],
		["April 2014", -0.13, 32, "#8a1c16"]]
	for l in lines:
		var lb := Label3D.new()
		lb.text = String(l[0])
		lb.font = font
		lb.font_size = int(l[2])
		lb.pixel_size = 0.00042
		lb.outline_size = 0
		lb.modulate = Color(String(l[3]))
		lb.position = Vector3(0, float(l[1]), 0.005)
		lb.double_sided = false
		n.add_child(lb)
	for c in [Vector2(-0.14, 0.19), Vector2(0.14, 0.19), Vector2(-0.14, -0.19), Vector2(0.14, -0.19)]:
		_box(n, Vector3(0.012, 0.012, 0.012), Vector3(c.x, c.y, 0.006), _mat("#4a4a4a", 0.4, 0.8))


func pose(root: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	var origin: Vector3 = ctx["holder"].global_position
	var h := PIT * 0.5
	_ground_mat.set_shader_parameter("pit_world", origin)
	# params.floor = {actor id: y}: the set's ground knows nothing of the pit, so stand them on it here.
	for id in p.get("floor", {}):
		var fa = ctx["actor"].call(String(id)) if ctx.has("actor") else null
		if fa != null:
			fa.global_position.y = origin.y + float(p["floor"][id])
	# The crawler: into the middle hole on hands and knees, squashed to fit.
	if p.has("crawl"):
		var cp: Dictionary = p["crawl"]
		var who = ctx["actor"].call(String(cp.get("who", ""))) if ctx.has("actor") else null
		if who != null:
			var holder: Node3D = ctx["holder"]
			var lp: Vector3 = holder.to_local(who.global_position)
			# Down on hands and knees before the mouth, pitched forward, crawling.
			var prone := smoothstep(-h + 2.4, -h + 1.2, lp.z)
			who.rotation.x = 0.75 * prone
			who.global_position.y = origin.y + float(p.get("floor", {}).get(String(cp.get("who", "")), 0.0)) - 0.05 * prone
			var cfwd := Vector3(sin(who.rotation.y), 0, cos(who.rotation.y))
			var cleft := Vector3(cos(who.rotation.y), 0, -sin(who.rotation.y))
			var hdp: Vector3 = who.anchor_points()[String(cp.get("who", "")) + ".head"]["pos"]
			var cyc := t * 5.0
			for side in ["l", "r"]:
				var sg := 1.0 if side == "l" else -1.0
				var reach := 0.18 * sin(cyc + (0.0 if side == "l" else PI))
				var floor_y := origin.y - DEPTH + 0.06
				who.aim_hand(side, Vector3(hdp.x, floor_y, hdp.z) + cfwd * (0.2 + reach) + cleft * sg * 0.22, prone)
			var hd: Vector3 = who.anchor_points()[String(cp.get("who", "")) + ".head"]["pos"]
			var fwd := Vector3(sin(who.rotation.y), 0, cos(who.rotation.y))
			_headlamp.global_transform = Transform3D(Basis.looking_at((fwd - Vector3(0, 0.18, 0)).normalized(), Vector3.UP), hd + Vector3(0, 0.18, 0) + fwd * 0.25)
		# Grit and small stones sifting from the hole's roof.
		var g0 := float(cp.get("grit", 1.0e9))
		for i in _grit.instance_count:
			var age := t - g0 - _hash(i * 3.1) * 0.6
			var xf := Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), Vector3.ZERO)
			if age > 0.0 and age < 1.2:
				var x0 := (_hash(i * 1.7) - 0.5) * HOLE_W * 0.9
				var z0 := -h - 0.1 - _hash(i * 5.3) * 1.2
				var y := SEAM0 + 0.07 + HOLE_H - 4.9 * age * age
				y = maxf(y, SEAM0 + 0.07)
				var s := 0.012 + _hash(i * 7.7) * 0.03
				xf = Transform3D(Basis.from_scale(Vector3.ONE * s), Vector3(x0, y, z0))
			_grit.set_instance_transform(i, xf)
	# The barrier tape: unrolled from post A to post B by the official.
	if p.has("tape"):
		var tp: Dictionary = p["tape"]
		var t0 := float(tp.get("t0", 1.0e9))
		var t1 := float(tp.get("t1", 1.0e9))
		var k := Motion.in_out(Motion.seg(t, t0, t1))
		var a := POST_A + Vector3(0, 1.15, 0)
		var b := a.lerp(POST_B + Vector3(0, 1.15, 0), k)
		var who = ctx["actor"].call(String(tp.get("who", ""))) if ctx.has("actor") else null
		if who != null and t >= t0 - 0.3:
			var hand: Vector3 = who.bone_world("hand_r") - origin
			if t < t1 + 0.1:
				b = hand
			who.aim_hand("r", origin + a.lerp(POST_B + Vector3(0, 1.15, 0), k) + Vector3(0, -0.05, 0.25), 1.0, 0.05)
		_tape.visible = k > 0.01
		var d := b - a
		var sag := Vector3(0, -0.04 * k, 0)
		_tape.transform = Transform3D(Basis(d.normalized(), Vector3.UP, d.normalized().cross(Vector3.UP)).scaled(Vector3(d.length(), 1, 1)), (a + b) * 0.5 + sag)
		_tape_roll.visible = k > 0.0 and k < 0.999
		_tape_roll.position = b
	var res := {"hole": origin + Vector3(HOLES[1], SEAM0 + 0.07 + HOLE_H * 0.5, -h),
		"notice": origin + POST_A + Vector3(0, 1.05, 0.06), "rim": origin + Vector3(0, 0, h)}
	return res
