extends RefCounted
## Inside the 800 mm escape pipe (line 19 onward): the rat-hole miners' workplace.
##
## Local frame: the pipe's axis runs along x at y = R (its floor at y = 0), from the open mouth at x = -LEN to the
## face at x = 0, where the rubble of the collapse (broken rock, soil, a bent rib bar) fills the bore and spills a
## little way back along the floor. Spiral-welded steel gone rusty, a scuffed track along the floor, a blower hose
## and a rope for the spoil trolley. Lit by the miners' headlamps, a caged hand lamp at the face and the work lamp
## shining in at the mouth; nothing else reaches in here.
##
## params:
##   digger   {"id", "strikes": [t, ...], "from", "until"}: lies at the face, a cold chisel in his left hand, a club
##            hammer in his right; every strike lands on its time (wind-up before it, recoil after)
##   hauler   {"id", "from", "until"}: behind him, rakes spoil into a tasla and shoves it back down the pipe
##   crawlers [{"id", "t0", "x0", "speed", "until"}]: crawl in from the mouth one after another (pull and rest)
## anchors: face (the chisel's point), mouth (centre of the open end), crawl_<n> (head of crawler n)

const Motion = preload("res://scripts/timeline/motion.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")

const R := 0.42
const LEN := 14.0
const CHISEL := 0.36
const DIG_X := -1.5             # the digger's chest
const DIG_Z := 0.0
const HAUL_X := -3.7
const HAUL_Z := 0.13
const ROCK := Vector3(-0.5, 0.04, -0.25)     # the stone he is splitting

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

## The inside of a spiral-welded steel pipe: blue-grey mill scale, rust blooming from the seams, a bright scuffed
## track and dried mud along the floor, chalk ticks every metre. Mesh local: y along the pipe, x/z across.
const STEEL_SHADER := """
shader_type spatial;
render_mode cull_front;
varying vec3 lp;
void vertex() { lp = VERTEX; }
//NOISE
void fragment() {
	float ang = atan(lp.z, lp.x);                       // 0 = +x of the mesh = the pipe's floor after the turn
	float along = lp.y;
	// The helical weld seam and the butt welds between lengths.
	float helix = fract(ang / 6.2831853 + along / 1.7);
	float seam = smoothstep(0.022, 0.006, abs(helix - 0.5));
	float butt = smoothstep(0.03, 0.008, abs(fract(along / 6.0 + 0.5) - 0.5) * 6.0);
	float weld = max(seam, butt);
	float heat = max(smoothstep(0.09, 0.0, abs(helix - 0.5)), smoothstep(0.16, 0.0, abs(fract(along / 6.0 + 0.5) - 0.5) * 6.0));
	float n = fbm(lp * vec3(2.4, 0.5, 2.4));
	float fine = n3(lp * 170.0) * 0.6 + n3(lp * 420.0) * 0.4;
	float streak = fbm(vec3(ang * 2.5, along * 0.22, 1.0));       // long stains running along the pipe
	float rust = smoothstep(0.25, 0.8, fbm(lp * vec3(1.6, 0.3, 1.6) + 4.0) * 0.65 + streak * 0.35 + heat * 0.25);
	vec3 scale_col = vec3(0.115, 0.12, 0.13) * (0.8 + 0.4 * n);
	vec3 rust_col = mix(vec3(0.21, 0.115, 0.06), vec3(0.33, 0.19, 0.095), streak);
	vec3 col = mix(scale_col, rust_col, rust) * (0.92 + 0.16 * fine);
	// Floor: how close to the bottom line. Mud at the very bottom, a polished drag track either side of it.
	float low = smoothstep(0.55, 1.0, cos(ang));
	float scratch = smoothstep(0.35, 0.9, n3(vec3(ang * 140.0, along * 0.5, 3.0)));
	float track = low * (0.35 + 0.65 * scratch);
	col = mix(col, vec3(0.42, 0.42, 0.43) * (0.7 + 0.5 * fine), track * 0.55);
	float mud = smoothstep(0.86, 0.99, cos(ang) + (fbm(vec3(along * 1.5, 2.0, ang * 3.0)) - 0.5) * 0.12);
	col = mix(col, vec3(0.23, 0.185, 0.14) * (0.7 + 0.5 * n), mud * 0.9);
	// Roll marks: faint hoops every half metre, a darker stain line downhill of each weld.
	float hoop = smoothstep(0.5, 0.0, abs(fract(along * 2.0 + n * 0.15) - 0.5) * 2.0);
	col *= 1.0 - 0.22 * hoop * hoop;
	col = mix(col, rust_col * 0.75, heat * 0.5);
	col = mix(col, vec3(0.2, 0.2, 0.21) * (0.8 + 0.5 * fine), weld * 0.8);
	// Chalk: a tick every metre on the side wall.
	float tick = smoothstep(0.012, 0.004, abs(fract(along) - 0.5)) * smoothstep(0.1, 0.06, abs(ang - 1.25)) * step(0.3, fine + 0.2);
	col = mix(col, vec3(0.8, 0.8, 0.76), tick * 0.7);
	ALBEDO = col * 0.5;
	// No environment reaches in here, so a true metal would render black: keep it dielectric and let the lamps'
	// highlights (low roughness on bare and scuffed steel) say "steel".
	METALLIC = 0.0;
	SPECULAR = mix(0.75, 0.3, max(rust, mud));
	ROUGHNESS = mix(mix(mix(0.42, 0.85, rust), 0.3, track * 0.7), 0.95, mud);
}
"""

## Broken rock, shotcrete and soil.
const ROCK_SHADER := """
shader_type spatial;
uniform vec3 tint : source_color = vec3(0.42, 0.39, 0.35);
varying vec3 wp;
varying vec3 lp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; lp = VERTEX; }
//NOISE
void fragment() {
	float n = fbm(lp * 5.0 + wp * 0.7);
	float band = fbm(vec3(lp.y * 7.0 + n * 2.0, lp.x * 1.5, lp.z * 1.5));
	vec3 col = tint * (0.55 + 0.6 * n) * (0.8 + 0.4 * band) * (0.9 + 0.2 * n3(lp * 90.0));
	ALBEDO = col;
	ROUGHNESS = 0.93;
	SPECULAR = 0.25;
	float e = 0.02;
	float c0 = fbm(lp * 9.0);
	vec3 g = vec3(fbm((lp + vec3(e, 0.0, 0.0)) * 9.0) - c0, fbm((lp + vec3(0.0, e, 0.0)) * 9.0) - c0, fbm((lp + vec3(0.0, 0.0, e)) * 9.0) - c0) / e;
	NORMAL = normalize(NORMAL - (VIEW_MATRIX * MODEL_MATRIX * vec4(g, 0.0)).xyz * 0.05);
}
"""

## A soft round puff of dust (billboard quad).
const PUFF_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform float alpha = 0.0;
uniform vec3 tint : source_color = vec3(0.62, 0.55, 0.46);
uniform float seed = 0.0;
//NOISE
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}
void fragment() {
	vec2 c = UV - 0.5;
	float r = length(c) * 2.0;
	float body = smoothstep(1.0, 0.25, r + (fbm(vec3(UV * 3.5, seed)) - 0.5) * 0.7);
	ALBEDO = tint;
	ALPHA = body * alpha;
}
"""

var _shaders := {}
var _tools := {}
var _chips: MultiMesh
var _sparks: MultiMesh
var _motes: MultiMesh
var _puffs: Array = []
var _pan: Node3D
var _chunk: MeshInstance3D
var _rock: MeshInstance3D
var _lamps := {}
var _fills := {}
var _bounce: OmniLight3D
var _hand_lamp: OmniLight3D
var _mouth_light: SpotLight3D
var _stones: Array = []
var _stone_homes: Array = []
var _stone_meshes: Array = []
var _break_meshes: Array = []
var _toe_stones: Array = []
var _toe_meshes: Array = []
var _break_light: OmniLight3D
var _break_fill: OmniLight3D
var _break_set: Node3D


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


func _lit(color: String, energy: float) -> StandardMaterial3D:
	var m := _mat(color, 0.4)
	m.emission_enabled = true
	m.emission = Color(color)
	m.emission_energy_multiplier = energy
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
	mi.transform = Transform3D(_aim_y((b - a).normalized()), (a + b) * 0.5)
	parent.add_child(mi)
	return mi


## A basis whose +Y points along dir.
func _aim_y(dir: Vector3) -> Basis:
	var ref := Vector3.FORWARD if absf(dir.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(dir).normalized()
	return Basis(x, dir, x.cross(dir).normalized())


func _hash(n: float) -> float:
	return fposmod(sin(n * 127.1 + 311.7) * 43758.5453, 1.0)


func _stone_mesh(seed: int, lump: float) -> ArrayMesh:
	var src := SphereMesh.new()
	src.radius = 0.5
	src.height = 1.0
	src.radial_segments = 10
	src.rings = 6
	var arr := src.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var nz := FastNoiseLite.new()
	nz.seed = seed
	nz.frequency = 1.4
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in idx:
		var v := verts[i]
		st.add_vertex(v * (1.0 + nz.get_noise_3dv(v * 2.0) * lump))
	st.generate_normals()
	return st.commit()


func _floor_y(z: float) -> float:
	return R - sqrt(maxf(R * R - z * z, 0.0))


## Faceted, asymmetric fractured rock, with flat faces and sharp edges.
func _fractured_stone(seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var v: Array[Vector3] = []
	for y in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			for x in [-1.0, 1.0]:
				v.append(Vector3(x * rng.randf_range(0.3, 0.55), y * rng.randf_range(0.3, 0.55), z * rng.randf_range(0.3, 0.55)))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in [0,2,3, 0,3,1, 4,5,7, 4,7,6, 0,1,5, 0,5,4, 2,6,7, 2,7,3, 0,4,6, 0,6,2, 1,3,7, 1,7,5]:
		st.add_vertex(v[i])
	st.generate_normals()
	return st.commit()


func build(_g: Dictionary) -> Node3D:
	var root := Node3D.new()
	# The pipe.
	var tube := CylinderMesh.new()
	tube.top_radius = R
	tube.bottom_radius = R
	tube.height = LEN + 1.0
	tube.radial_segments = 64
	tube.rings = 40
	tube.cap_top = false
	tube.cap_bottom = false
	var t := MeshInstance3D.new()
	t.mesh = tube
	t.material_override = _shader(STEEL_SHADER)
	# Mesh +y -> the pipe's +x, mesh +x -> down (the floor line is the mesh's +x).
	t.transform = Transform3D(Basis(Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)), Vector3(-LEN * 0.5 + 0.5, R, 0))
	t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF      # a thin curved shell shadowing itself only gives acne
	root.add_child(t)
	# A dark shell round it so nothing outside ever shows through a seam.
	var shell := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = R + 0.03
	sm.bottom_radius = R + 0.03
	sm.height = LEN + 1.0
	sm.radial_segments = 24
	shell.mesh = sm
	var black := _mat("#030303", 1.0)
	black.cull_mode = BaseMaterial3D.CULL_FRONT
	shell.material_override = black
	shell.transform = t.transform
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(shell)
	_build_face(root)
	for i in 8:
		_break_meshes.append(_fractured_stone(461 + i))
	_build_services(root)
	_build_mouth(root)
	_build_fx(root)
	_break_light = OmniLight3D.new()
	_break_light.position = Vector3(-0.65, 0.55, 0.0)
	_break_light.light_color = Color("#ffe3af")
	_break_light.omni_range = 3.0
	_break_light.light_energy = 0.0
	root.add_child(_break_light)
	# The trapped side is a rubble face around the opening, not the empty world
	# surrounding this remote pipe set. Leave the central aperture unobstructed.
	_break_set = Node3D.new()
	root.add_child(_break_set)
	var break_rock := _shader(ROCK_SHADER)
	break_rock.set_shader_parameter("tint", Color(0.25, 0.235, 0.21))
	_box(_break_set, Vector3(0.4, 3.0, 2.2), Vector3(0.5, 1.15, -1.55), break_rock)
	_box(_break_set, Vector3(0.4, 3.0, 2.2), Vector3(0.5, 1.15, 1.55), break_rock)
	_box(_break_set, Vector3(0.4, 2.2, 0.9), Vector3(0.5, 1.95, 0.0), break_rock)
	_box(_break_set, Vector3(3.5, 0.22, 5.0), Vector3(1.6, -0.12, 0.0), break_rock)
	_break_set.visible = false
	_break_fill = OmniLight3D.new()
	_break_fill.position = Vector3(1.35, 1.1, -0.7)
	_break_fill.light_color = Color("#b3c2d1")
	_break_fill.omni_range = 4.0
	_break_fill.light_energy = 0.0
	root.add_child(_break_fill)
	return root


## The rubble that fills the bore at the face and spills back along the floor.
func _build_face(root: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2111
	var tints := [Color(0.42, 0.39, 0.35), Color(0.36, 0.35, 0.34), Color(0.47, 0.42, 0.34), Color(0.3, 0.29, 0.28)]
	var meshes := []
	for i in 6:
		meshes.append(_stone_mesh(40 + i, 0.5))
	# The packed face.
	for i in 70:
		var s := MeshInstance3D.new()
		s.mesh = meshes[i % meshes.size()]
		var m := _shader(ROCK_SHADER)
		m.set_shader_parameter("tint", tints[i % tints.size()])
		s.material_override = m
		var sz := rng.randf_range(0.13, 0.36)
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * (R - 0.03)
		var back := rng.randf_range(0.0, 0.45)
		s.transform = Transform3D(Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)).scaled(Vector3(sz, sz * rng.randf_range(0.6, 0.9), sz * rng.randf_range(0.8, 1.2))),
			Vector3(0.02 + back, R + sin(a) * r, cos(a) * r))
		root.add_child(s)
		_stones.append(s)
		_stone_homes.append(s.transform)
		_stone_meshes.append(s.mesh)
	# The toe: stones and soil spilling back along the floor, where he works.
	for i in 30:
		var s := MeshInstance3D.new()
		s.mesh = meshes[i % meshes.size()]
		var m := _shader(ROCK_SHADER)
		m.set_shader_parameter("tint", tints[(i + 1) % tints.size()])
		s.material_override = m
		var x := -rng.randf_range(0.0, 0.62)
		var z := rng.randf_range(-0.32, 0.32)
		var rise := (1.0 - absf(x) / 0.62) * 0.3
		var sz := rng.randf_range(0.07, 0.2)
		s.transform = Transform3D(Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, 0)).scaled(Vector3(sz, sz * 0.7, sz)),
			Vector3(x, _floor_y(z) + rise * rng.randf_range(0.3, 1.0) + sz * 0.2, z))
		if s.position.distance_to(ROCK) < 0.2:
			s.position.y -= 0.2
		if z > -0.02 and x > -0.5:
			# Keep the lens side clear (a stone 5 cm from the camera is a wall): only low ones there.
			s.position.y = _floor_y(z) + sz * 0.15
			if x > -0.28:
				continue
		root.add_child(s)
		_toe_stones.append(s)
		_toe_meshes.append(s.mesh)
	# The stone he is splitting: big, half buried in the toe; a wedge of it comes away on the last strike.
	_rock = MeshInstance3D.new()
	_rock.mesh = _stone_mesh(77, 0.35)
	var rm := _shader(ROCK_SHADER)
	rm.set_shader_parameter("tint", Color(0.5, 0.47, 0.43))
	_rock.material_override = rm
	_rock.transform = Transform3D(Basis.from_euler(Vector3(0.3, 0.8, 0.1)).scaled(Vector3(0.42, 0.34, 0.4)), ROCK + Vector3(0.1, -0.03, -0.06))
	root.add_child(_rock)
	_chunk = MeshInstance3D.new()
	_chunk.mesh = _stone_mesh(91, 0.45)
	_chunk.material_override = rm
	root.add_child(_chunk)
	# Twisted reinforcement out of the lining: two bars and a strip of crushed lattice girder.
	var bar := _mat("#5a2e1c", 0.7, 0.55)
	_rod(root, Vector3(0.25, 0.74, -0.12), Vector3(-0.34, 0.6, -0.3), 0.012, bar, 6)
	_rod(root, Vector3(-0.34, 0.6, -0.3), Vector3(-0.46, 0.42, -0.36), 0.012, bar, 6)
	_rod(root, Vector3(0.3, 0.15, -0.3), Vector3(-0.22, 0.42, -0.34), 0.014, bar, 6)
	_rod(root, Vector3(0.2, 0.78, 0.05), Vector3(-0.1, 0.72, -0.1), 0.01, bar, 6)


func _build_services(root: Node3D) -> void:
	# The blower's hose along one side of the floor, ribbed; it ends short of the face.
	var duct := _mat("#d9a916", 0.65)
	var dz := 0.27
	var dy := _floor_y(dz) + 0.055
	_rod(root, Vector3(-LEN - 0.5, dy, dz), Vector3(-2.3, dy, dz), 0.055, duct, 12)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.05
	ring.outer_radius = 0.064
	ring.rings = 12
	ring.ring_segments = 5
	var rmm := MultiMesh.new()
	rmm.transform_format = MultiMesh.TRANSFORM_3D
	rmm.mesh = ring
	rmm.instance_count = 96
	for i in 96:
		rmm.set_instance_transform(i, Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(-2.3 - i * 0.12, dy, dz)))
	var rmi := MultiMeshInstance3D.new()
	rmi.multimesh = rmm
	rmi.material_override = duct
	root.add_child(rmi)
	# The trolley rope, slack along the floor.
	var rope := _mat("#cdbb8f", 0.95)
	for i in 14:
		var x0 := -LEN + i * 0.8
		var z0 := -0.06 + 0.05 * sin(i * 1.7)
		var z1 := -0.06 + 0.05 * sin((i + 1) * 1.7)
		_rod(root, Vector3(x0, _floor_y(z0) + 0.012, z0), Vector3(x0 + 0.8, _floor_y(z1) + 0.012, z1), 0.008, rope, 5)
	# A caged hand lamp on its cable, lying by the digger's elbow: the warm practical at the face.
	var cage := Node3D.new()
	cage.position = Vector3(-2.5, _floor_y(-0.12) + 0.06, -0.12)
	cage.rotation = Vector3(0.0, -0.5, 1.2)
	root.add_child(cage)
	var bulb := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.032
	bm.height = 0.07
	bulb.mesh = bm
	bulb.material_override = _lit("#ffcf8a", 7.0)
	cage.add_child(bulb)
	var wire := _mat("#22201e", 0.5, 0.7)
	for k in 6:
		var a := TAU * k / 6.0
		_rod(cage, Vector3(cos(a) * 0.045, -0.05, sin(a) * 0.045), Vector3(cos(a) * 0.045, 0.06, sin(a) * 0.045), 0.003, wire, 4)
	_rod(cage, Vector3(0, -0.14, 0), Vector3(0, -0.05, 0), 0.02, _mat("#c7541c", 0.6), 8)
	_rod(root, Vector3(-LEN, 0.05, -0.2), Vector3(-2.65, 0.07, -0.29), 0.006, _mat("#111111", 0.6), 4)
	_hand_lamp = OmniLight3D.new()
	_hand_lamp.position = cage.position + Vector3(0.0, 0.07, 0.05)
	_hand_lamp.light_color = Color("#ffb968")
	_hand_lamp.light_energy = 0.55
	_hand_lamp.omni_range = 3.0
	_hand_lamp.omni_attenuation = 1.4
	_hand_lamp.shadow_enabled = true
	root.add_child(_hand_lamp)
	# The headlamp's light coming back off the rock: what lights his face from below.
	_bounce = OmniLight3D.new()
	_bounce.position = ROCK + Vector3(-0.1, 0.1, 0.12)
	_bounce.light_color = Color("#ffd3a0")
	_bounce.light_energy = 0.34
	_bounce.omni_range = 1.4
	# What comes back off the whole rubble face behind the lens: lifts the helmet and the stones out of pure black.
	var back_fill := OmniLight3D.new()
	back_fill.position = Vector3(-0.05, 0.6, 0.08)
	back_fill.light_color = Color("#ffe6c8")
	back_fill.light_energy = 0.14
	back_fill.omni_range = 2.2
	back_fill.omni_attenuation = 1.0
	root.add_child(back_fill)
	_bounce.omni_attenuation = 1.2
	root.add_child(_bounce)


## The open end: the lit tunnel beyond it (a work lamp glaring in, the timber deck, the lining far behind).
func _build_mouth(root: Node3D) -> void:
	var lip := MeshInstance3D.new()
	var lm := TorusMesh.new()
	lm.inner_radius = R - 0.012
	lm.outer_radius = R + 0.03
	lm.rings = 48
	lm.ring_segments = 8
	lip.mesh = lm
	lip.material_override = _mat("#a5a9ad", 0.3, 0.9)
	lip.rotation.z = PI * 0.5
	lip.position = Vector3(-LEN, R, 0)
	root.add_child(lip)
	var timber := _mat("#7a5632", 0.9)
	for k in 7:
		_box(root, Vector3(3.6, 0.06, 0.25), Vector3(-LEN - 1.85, -0.08, -0.81 + k * 0.27), timber)
	var wall := _mat("#8f8a80", 0.9)
	_box(root, Vector3(0.2, 9.0, 14.0), Vector3(-LEN - 22.0, 3.0, 0.0), wall)
	_box(root, Vector3(24.0, 0.2, 14.0), Vector3(-LEN - 11.0, -0.75, 0.0), _mat("#3a3531", 0.9))
	var lampm := _lit("#fff3da", 14.0)
	_box(root, Vector3(0.1, 0.24, 0.34), Vector3(-LEN - 3.3, 1.0, -0.55), lampm)
	_rod(root, Vector3(-LEN - 3.3, -0.7, -0.55), Vector3(-LEN - 3.3, 0.9, -0.55), 0.02, _mat("#222222", 0.5, 0.6), 6)
	var haze := _box(root, Vector3(0.05, 7.0, 9.0), Vector3(-LEN - 9.0, 2.0, 0.0), _lit("#d8b98a", 0.5))
	haze.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fill := OmniLight3D.new()
	fill.position = Vector3(-LEN - 2.0, 1.6, 1.2)
	fill.light_color = Color("#ffdcae")
	fill.light_energy = 2.2
	fill.omni_range = 7.0
	root.add_child(fill)
	_mouth_light = SpotLight3D.new()
	_mouth_light.transform = Transform3D(Basis.looking_at(Vector3(1, -0.03, 0.04).normalized()), Vector3(-LEN - 3.2, 1.0, -0.5))
	_mouth_light.light_color = Color("#ffe6c0")
	_mouth_light.light_energy = 16.0
	_mouth_light.spot_range = 10.0
	_mouth_light.spot_angle = 14.0
	_mouth_light.spot_attenuation = 0.6
	_mouth_light.shadow_enabled = true
	_mouth_light.light_volumetric_fog_energy = 2.5
	root.add_child(_mouth_light)


func _build_fx(root: Node3D) -> void:
	var rock := _shader(ROCK_SHADER)
	_chips = MultiMesh.new()
	_chips.transform_format = MultiMesh.TRANSFORM_3D
	_chips.mesh = _stone_mesh(5, 0.5)
	_chips.instance_count = 96
	var cmi := MultiMeshInstance3D.new()
	cmi.multimesh = _chips
	cmi.material_override = rock
	root.add_child(cmi)
	# Sparks: short bright streaks.
	var sm := BoxMesh.new()
	sm.size = Vector3(1.0, 0.12, 0.12)
	var smat := _lit("#ffb347", 9.0)
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color("#ffcf7a")
	sm.material = smat
	_sparks = MultiMesh.new()
	_sparks.transform_format = MultiMesh.TRANSFORM_3D
	_sparks.mesh = sm
	_sparks.instance_count = 40
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = _sparks
	smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(smi)
	# Dust hanging in the air: only the lamps make it show.
	var mote := SphereMesh.new()
	mote.radius = 0.5
	mote.height = 1.0
	mote.radial_segments = 5
	mote.rings = 3
	var mm := _mat("#ffe2b8", 1.0)
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mm.albedo_color = Color(1.0, 0.86, 0.66, 0.16)
	mote.material = mm
	_motes = MultiMesh.new()
	_motes.transform_format = MultiMesh.TRANSFORM_3D
	_motes.mesh = mote
	_motes.instance_count = 180
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _motes
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)
	for i in 8:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1, 1)
		q.mesh = qm
		var pm := _shader(PUFF_SHADER)
		pm.set_shader_parameter("seed", float(i) * 3.7)
		q.material_override = pm
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		q.visible = false
		root.add_child(q)
		_puffs.append(q)
	# The hauler's tasla, heaped with spoil.
	_pan = Node3D.new()
	root.add_child(_pan)
	var pan := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.21
	cm.bottom_radius = 0.13
	cm.height = 0.085
	cm.radial_segments = 24
	cm.cap_top = false
	pan.mesh = cm
	var pm2 := _mat("#8a8d90", 0.38, 0.8)
	pm2.cull_mode = BaseMaterial3D.CULL_DISABLED
	pan.material_override = pm2
	pan.position = Vector3(0, 0.045, 0)
	_pan.add_child(pan)
	var prim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.2
	tm.outer_radius = 0.222
	tm.rings = 28
	tm.ring_segments = 6
	prim.mesh = tm
	prim.material_override = pm2
	prim.position = Vector3(0, 0.088, 0)
	_pan.add_child(prim)
	for i in 12:
		var s := MeshInstance3D.new()
		s.mesh = _chips.mesh
		s.material_override = rock
		var sz := 0.06 + _hash(i * 2.0) * 0.06
		s.transform = Transform3D(Basis.from_euler(Vector3(i, i * 2.0, 0)).scaled(Vector3(sz, sz * 0.75, sz)),
			Vector3((_hash(i) - 0.5) * 0.24, 0.085 + _hash(i * 5.0) * 0.04, (_hash(i * 3.0) - 0.5) * 0.24))
		_pan.add_child(s)
	_pan.visible = false


func _tool(kind: String) -> Node3D:
	var n := Node3D.new()
	var wood := _mat("#8a6238", 0.75)
	var steel := _mat("#55595e", 0.4, 0.85)
	if kind == "hammer":
		# A club hammer: origin at the grip, the head up the handle (+y), its striking face toward +x.
		_rod(n, Vector3(0, -0.08, 0), Vector3(0, 0.25, 0), 0.019, wood, 8)
		_box(n, Vector3(0.17, 0.085, 0.085), Vector3(0, 0.265, 0), steel)
		_box(n, Vector3(0.176, 0.07, 0.07), Vector3(0, 0.265, 0), _mat("#9a9ea3", 0.28, 0.9))
	else:
		# A cold chisel: origin at the butt, the point at +y * CHISEL.
		_rod(n, Vector3(0, 0, 0), Vector3(0, CHISEL - 0.07, 0), 0.016, _mat("#7c8186", 0.35, 0.8), 6)
		_rod(n, Vector3(0, -0.008, 0), Vector3(0, 0.016, 0), 0.024, _mat("#8d9196", 0.35, 0.85), 8)
		var tip := _box(n, Vector3(0.036, 0.08, 0.01), Vector3(0, CHISEL - 0.04, 0), _mat("#c5c9cd", 0.25, 0.9))
		tip.name = "tip"
	return n


func _lamp_for(root: Node3D, id: String, shadows: bool) -> SpotLight3D:
	if not _lamps.has(id):
		var lamp := SpotLight3D.new()
		lamp.light_color = Color("#fff0d6")
		lamp.light_energy = 7.0
		lamp.spot_range = 7.0
		lamp.spot_angle = 30.0
		lamp.spot_angle_attenuation = 0.8
		lamp.shadow_enabled = shadows
		lamp.light_volumetric_fog_energy = 3.0
		root.add_child(lamp)
		_lamps[id] = lamp
		var fill := OmniLight3D.new()
		fill.light_color = Color("#ffd9aa")
		fill.light_energy = 0.0
		fill.omni_range = 1.5
		fill.omni_attenuation = 1.2
		root.add_child(fill)
		_fills[id] = fill
	return _lamps[id]


## Put a headlamp's beam on the helmet, along the face direction (G: gag -> world; all inputs world).
func _aim_lamp(root: Node3D, Gi: Transform3D, id: String, info: Dictionary, a, shadows: bool, fill: float, at = null) -> void:
	var lamp := _lamp_for(root, id, shadows)
	var face: Vector3 = (Gi.basis * (info["face"] as Vector3)).normalized()
	var hup: Vector3 = (Gi.basis * (info["head_up"] as Vector3)).normalized()
	var head: Vector3 = Gi * (info["head"] as Vector3)
	var r: float = a._head_r
	lamp.visible = true
	var from := head + face * r * 1.12 + hup * r * 0.62
	lamp.transform = Transform3D(Basis.looking_at(face, hup), from)
	if at != null:
		# The beam is trimmed onto what he is working on (a lamp on its strap is tilted by hand).
		lamp.transform = Transform3D(Basis.looking_at(((at as Vector3) - from).normalized(), hup), from)
	var f := _fills[id] as OmniLight3D
	f.visible = fill > 0.0
	f.light_energy = fill
	f.position = head + face * (r + 0.55) - hup * r * 0.5


func _visible(a, on: bool) -> bool:
	a.visible = on
	return on


func pose(root: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	# Everything in this gag's own frame: the anchor it sits on is turned, so map through the root's transform.
	var G: Transform3D = root.global_transform
	var Gi: Transform3D = G.affine_inverse()
	var fwd: Vector3 = (G.basis * Vector3(1, 0, 0)).normalized()
	var up: Vector3 = (G.basis * Vector3(0, 1, 0)).normalized()
	var res := {"mouth": G * Vector3(-LEN, R, 0.0)}
	for id in _lamps:
		(_lamps[id] as SpotLight3D).visible = false
		(_fills[id] as OmniLight3D).visible = false
	var face_pt := ROCK + Vector3(-0.06, 0.1, 0.05)
	res["face"] = G * face_pt
	var strikes: Array = []
	var digging := false
	# On the trapped side the last packed stones shift, then tumble clear to
	# expose the miner. Every pose is derived from time, including reverse seeks.
	var bp: Dictionary = p.get("breakthrough", {})
	var bt := float(bp.get("hit", 1.0e9))
	var active := t >= float(bp.get("from", 1.0e9)) and t < float(bp.get("until", 1.0e9))
	_break_set.visible = active
	for i in _toe_stones.size():
		var toe: MeshInstance3D = _toe_stones[i]
		toe.mesh = _break_meshes[i % _break_meshes.size()] if active else _toe_meshes[i]
	var breakthrough_fall := Motion.out_cubic(Motion.seg(t, bt, bt + 0.38)) if active else 0.0
	for i in _stones.size():
		var stone: MeshInstance3D = _stones[i]
		var home: Transform3D = _stone_homes[i]
		stone.mesh = _break_meshes[i % _break_meshes.size()] if active else _stone_meshes[i]
		var scatter := Vector3(0.42 + float(i % 4) * 0.06, -0.72 - float(i % 3) * 0.1, (float(i % 7) - 3.0) * 0.14)
		var shape := home.basis.scaled(Vector3.ONE * 1.35) if active else home.basis
		stone.transform = Transform3D(shape.rotated(Vector3.FORWARD, breakthrough_fall * (float(i % 5) - 2.0)), home.origin + scatter * breakthrough_fall)
	_break_light.light_energy = 1.1 * Motion.smooth(Motion.seg(t, bt, bt + 0.4)) if active else 0.0
	_break_fill.light_energy = 0.8 if active else 0.0
	if active:
		var miner = ctx["actor"].call(String(bp.get("miner", "")))
		var survivor = ctx["actor"].call(String(bp.get("survivor", "")))
		if miner != null:
			miner.visible = true
			var reach := Motion.smooth(Motion.seg(t, bt + 0.12, bt + 0.55))
			var mi := Crawl.pose(miner, G * Vector3(-1.0 + 0.18 * reach, 0.25, 0.0), fwd, up, 0.0, {"tilt": 0.2, "floor_y": (G * Vector3.ZERO).y, "pipe_r": R, "arms": false, "arm_scale": 1.35})
			_aim_lamp(root, Gi, String(bp.get("miner", "")), mi, miner, true, 0.0, Vector3(0.8, 0.4, 0.0))
			Crawl.arm(miner, "r", G * Vector3(-0.15 + 0.32 * reach, 0.22, -0.1), G.basis * Vector3(0, 1, 0.5))
		if survivor != null:
			survivor.visible = true
			var reach := Motion.smooth(Motion.seg(t, bt + 0.2, bt + 0.65))
			survivor.aim_hand("r", G * Vector3(0.55 - 0.38 * reach, 0.22, -0.1), reach)
	# ------------------------------------------------------------------ the digger at the face
	if p.has("digger"):
		var dp: Dictionary = p["digger"]
		var id := String(dp.get("id", ""))
		var a = ctx["actor"].call(id) if ctx.has("actor") else null
		strikes = dp.get("strikes", [])
		digging = a != null and t >= float(dp.get("from", -1.0e9)) and t < float(dp.get("until", 1.0e9))
		if a != null and not active:
			_visible(a, digging)
		if digging:
			# Where the swing is: 0 on the chisel, 1 drawn back. Wind-up eases out, the blow accelerates in,
			# and the head bounces off the chisel after contact.
			var swing := 0.12 + 0.03 * sin(t * 2.1)
			var since := 1.0e9          # seconds since the last strike
			var n_hit := 0
			for st in strikes:
				var s0 := float(st)
				if t >= s0 - 0.34 and t < s0 - 0.1:
					swing = lerpf(0.12, 1.0, Motion.out_cubic(Motion.seg(t, s0 - 0.34, s0 - 0.1)))
				elif t >= s0 - 0.1 and t < s0:
					swing = 1.0 - Motion.in_cubic(Motion.seg(t, s0 - 0.1, s0))
				if t >= s0:
					since = minf(since, t - s0)
					n_hit += 1
			if since < 0.3:
				swing = maxf(swing, 0.16 * absf(Motion.wobble(since, 5.0, 9.0)) + 0.12 * Motion.seg(since, 0.1, 0.3))
			var jolt := Motion.wobble(since, 6.0, 12.0) if since < 1.0 else 0.0
			# The body: flat on the belly, shoved a little into every blow; the head tucks on impact.
			var lunge := 0.02 * jolt + 0.012 * (1.0 - swing)
			var chest := Vector3(DIG_X + lunge, 0.25 + 0.004 * sin(t * 2.4), DIG_Z)
			var info := Crawl.pose(a, G * chest, fwd, up, 0.0, {"tilt": 0.2, "floor_y": (G * Vector3.ZERO).y, "pipe_r": R, "arms": false,
				"roll": 0.0, "sway": 0.0, "look": Vector2(float(dp.get("look_yaw", 0.3)), float(dp.get("look_pitch", 0.2)) + 0.05 * jolt), "leg_back": 0.3, "leg_spread": 0.13,
				"head_up": 0.92, "arm_scale": 1.45})
			_aim_lamp(root, Gi, id, info, a, true, 0.0, face_pt)
			for kind in ["hammer", "chisel"]:
				if not _tools.has(id + kind):
					var n := _tool(kind)
					root.add_child(n)
					_tools[id + kind] = n
			# The chisel lies across the frame: point on the stone at the pipe's side, driven a few millimetres deeper
			# by every blow, ringing after each.
			var cdir := Vector3(0.55, -0.15, -0.82).normalized()
			var bite := 0.012 * n_hit + 0.006 * Motion.out_cubic(Motion.seg(since, 0.0, 0.05)) - 0.006
			var tip := face_pt + cdir * bite
			var ring := Vector3(0, 0.014, 0.0) * jolt
			var butt := tip - cdir * CHISEL + ring
			var chisel := _tools[id + "chisel"] as Node3D
			chisel.visible = true
			chisel.transform = Transform3D(_aim_y((tip - butt).normalized()), butt)
			var left: Vector3 = Gi.basis * (info["left"] as Vector3)
			Crawl.arm(a, "l", G * (butt + cdir * 0.2), G.basis * Vector3(-0.6, 0.7, -0.3), 1.0)
			# The hammer: its face meets the chisel's butt along the chisel's own line; drawn back up and toward
			# his right shoulder, the wrist cocking the head further than the hand moves.
			var strike_dir := cdir
			var head_hit := butt - strike_dir * 0.088
			var back := Vector3(-0.3, 0.6, 0.5).normalized()
			var head_pos := head_hit + (back * 0.3 - strike_dir * 0.1) * swing
			var handle := (Vector3(-0.8, 0.12, 0.55).normalized() * (1.0 - swing) + Vector3(-0.75, -0.55, 0.3).normalized() * swing).normalized()   # head -> grip
			var grip := head_pos + handle * 0.265
			var hammer := _tools[id + "hammer"] as Node3D
			hammer.visible = true
			# Tool local: +y from grip to head, +x the striking face.
			var hy := -handle
			var hx := (strike_dir - hy * strike_dir.dot(hy)).normalized()
			hammer.transform = Transform3D(Basis(hx, hy, hx.cross(hy)), grip)
			Crawl.arm(a, "r", G * grip, G.basis * Vector3(-0.5, 0.6, 0.6), 1.0)
			# The stone: shudders with each blow; the wedge splits off on the last one that lands in the shot.
			var crack_t := float(dp.get("split", 1.0e9))
			var split := t - crack_t
			_rock.position = ROCK + Vector3(0.1, -0.03, -0.06) + Vector3(0.004, -0.003, 0) * jolt
			var c0 := ROCK + Vector3(-0.1, 0.04, 0.16)
			if split < 0.0:
				_chunk.transform = Transform3D(Basis.from_euler(Vector3(0.4, 0.2, 0.3)).scaled(Vector3(0.2, 0.17, 0.19)), c0 + Vector3(0.003, 0, 0) * jolt)
			else:
				var fall := Vector3(-0.42, 0.55, 0.42) * split + Vector3(0, -4.9 * split * split, 0)
				var pos := c0 + fall
				var rest_y := _floor_y(pos.z) + 0.06
				var landed := pos.y < rest_y
				if landed:
					var tl := (0.55 + sqrt(0.55 * 0.55 + 4.0 * 4.9 * (c0.y - 0.09))) / 9.8
					pos = c0 + Vector3(-0.42, 0, 0.42) * minf(split, tl + 0.2) + Vector3(0, 0, 0)
					pos.y = _floor_y(pos.z) + 0.06 + 0.03 * absf(Motion.wobble(split - tl, 4.0, 9.0))
				_chunk.transform = Transform3D(Basis.from_euler(Vector3(0.4 + split * 5.0 * (0.0 if landed else 1.0) + (2.0 if landed else 0.0), 0.2, 0.3 + minf(split, 0.4) * 4.0)).scaled(Vector3(0.2, 0.17, 0.19)), pos)
			_bounce.light_energy = 0.34 + 0.25 * maxf(jolt, 0.0)
			_pose_fx(t, strikes, tip, cdir)
		else:
			for kind in ["hammer", "chisel"]:
				if _tools.has(id + kind):
					(_tools[id + kind] as Node3D).visible = false
	if not digging:
		_pose_fx(t, [], face_pt, Vector3(1, 0, 0))
	# ------------------------------------------------------------------ the hauler behind him
	var hauling := false
	if p.has("hauler"):
		var hp: Dictionary = p["hauler"]
		var id := String(hp.get("id", ""))
		var a = ctx["actor"].call(id) if ctx.has("actor") else null
		hauling = a != null and _visible(a, t >= float(hp.get("from", -1.0e9)) and t < float(hp.get("until", 1.0e9)))
		if hauling:
			# A slow cycle: rake spoil toward himself with both hands on the pan, shove the full pan back, reach again.
			var cyc := fposmod(t * 0.62 + 0.3, 1.0)
			var pull := Motion.in_out(Motion.seg(cyc, 0.05, 0.45)) - Motion.in_out(Motion.seg(cyc, 0.6, 0.95))
			var chest := Vector3(HAUL_X - 0.1 * pull, 0.25 + 0.006 * sin(t * 2.0 + 1.0), HAUL_Z)
			var info := Crawl.pose(a, G * chest, fwd, up, 0.0, {"tilt": 0.22, "floor_y": (G * Vector3.ZERO).y, "pipe_r": R, "arms": false,
				"roll": 0.0, "sway": 0.0, "look": Vector2(-0.12, 0.1 + 0.12 * pull), "leg_back": 0.3, "leg_spread": 0.12, "arm_scale": 1.45})
			a.rotate_object_local(Vector3(0, 1, 0), 0.12 * (pull - 0.5))
			# His lamp is the digger's back light: it rims the helmet and shoulders and shows the dust between them.
			_aim_lamp(root, Gi, id, info, a, false, 0.35, Vector3(DIG_X + 0.25, 0.62, DIG_Z))
			(_lamps[id] as SpotLight3D).light_energy = 2.2
			(_lamps[id] as SpotLight3D).spot_angle = 38.0
			(_lamps[id] as SpotLight3D).light_volumetric_fog_energy = 0.5
			var pan_at := Vector3(HAUL_X + 0.95 - 0.3 * pull, _floor_y(HAUL_Z) + 0.01, HAUL_Z - 0.03 * pull)
			_pan.position = pan_at
			_pan.rotation = Vector3(0.0, t * 0.0, -0.12 * sin(pull * PI))
			var left: Vector3 = Gi.basis * (info["left"] as Vector3)
			for side in ["l", "r"]:
				var sg := 1.0 if side == "l" else -1.0
				Crawl.arm(a, side, G * (pan_at + Vector3(-0.19, 0.09, 0.0) + left * sg * 0.12), G.basis * (left * sg + Vector3(-0.2, 0.6, 0)), 1.0)
	_pan.visible = hauling
	_hand_lamp.visible = digging or hauling
	_bounce.visible = digging
	# ------------------------------------------------------------------ crawling in from the mouth
	var crawlers: Array = p.get("crawlers", [])
	for i in crawlers.size():
		var c: Dictionary = crawlers[i]
		var id := String(c.get("id", ""))
		var a = ctx["actor"].call(id) if ctx.has("actor") else null
		if a == null:
			continue
		var t0 := float(c.get("t0", 0.0))
		if not _visible(a, t >= t0 - 0.05 and t < float(c.get("until", 1.0e9))):
			continue
		var h: float = a._height_scale * 1.83
		var stride := 0.46 * h
		var d := Crawl.surge(maxf(t - t0, 0.0), float(c.get("speed", 0.7)), stride, 0.6)
		var x := float(c.get("x0", -LEN - 0.6)) + d
		var zc := float(c.get("z", 0.0))
		var chest := Vector3(x, 0.255, zc)
		var info := Crawl.pose(a, G * chest, fwd, up, d + float(i) * 0.37 * stride, {"stride": stride, "tilt": 0.17, "floor_y": (G * Vector3.ZERO).y, "pipe_r": R,
			"spread": 0.17 * h, "reach": 0.25 * h, "leg_back": 0.26 * h, "leg_spread": 0.12 * h, "look": Vector2(0.0, 0.04)})
		_aim_lamp(root, Gi, id, info, a, i == 0, 0.5)
		res["crawl_%d" % (i + 1)] = info["head"]
	_mouth_light.visible = true
	return res


## Chips, sparks, dust puffs and the motes in the lamp beams.
func _pose_fx(t: float, strikes: Array, tip: Vector3, cdir: Vector3) -> void:
	var n := maxi(strikes.size(), 1)
	var per := _chips.instance_count / n
	for i in _chips.instance_count:
		var si := mini(i / maxi(per, 1), n - 1)
		var xf := Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), tip)
		if strikes.size() > 0:
			var age := t - float(strikes[si]) - _hash(i * 1.3) * 0.03
			if age > 0.0 and age < 1.2:
				# Thrown back and up from the point, a spread toward the lens; they land on the pipe floor and skitter.
				var v := Vector3(-0.5 - _hash(i * 2.9) * 2.4, 0.5 + _hash(i * 4.4) * 1.9, (_hash(i * 6.6) - 0.5) * 2.6)
				var pos := tip + v * age + Vector3(0, -6.5 * age * age, 0)
				var gy := _floor_y(clampf(pos.z, -R + 0.02, R - 0.02)) + 0.012
				if pos.y < gy:
					pos.y = gy
				pos.z = clampf(pos.z, -R + 0.05, R - 0.05)
				var sz := (0.008 + _hash(i * 8.1) * 0.026) * (1.0 - Motion.seg(age, 0.9, 1.2))
				xf = Transform3D(Basis.from_euler(Vector3(age * 14.0, float(i), age * 9.0)).scaled(Vector3(sz, sz * 0.6, sz)), pos)
		_chips.set_instance_transform(i, xf)
	var sper := _sparks.instance_count / n
	for i in _sparks.instance_count:
		var si := mini(i / maxi(sper, 1), n - 1)
		var xf := Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), tip)
		if strikes.size() > 0:
			var age := t - float(strikes[si])
			var life := 0.1 + _hash(i * 3.1) * 0.16
			if age > 0.0 and age < life:
				var v := (Vector3(-1.0, 0.7, 0.0) + Vector3(_hash(i * 1.9) - 0.5, _hash(i * 2.7) - 0.3, _hash(i * 4.1) - 0.5) * 2.2).normalized() * (1.6 + _hash(i * 7.7) * 2.6)
				var pos := tip + v * age + Vector3(0, -5.0 * age * age, 0)
				var vel := v + Vector3(0, -10.0 * age, 0)
				var stretch := 0.035 * (1.0 - age / life)
				var d := vel.normalized()
				var ref := Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT
				var yb := ref.cross(d).normalized()
				xf = Transform3D(Basis(d * stretch, yb * 0.02, d.cross(yb) * 0.02), pos)
		_sparks.set_instance_transform(i, xf)
	for i in _puffs.size():
		var q := _puffs[i] as MeshInstance3D
		var si := i % n
		var age := (t - float(strikes[si])) if strikes.size() > 0 else -1.0
		var k := i / n
		if age < 0.0 or age > 1.1:
			q.visible = false
			continue
		q.visible = true
		var grow := Motion.out_cubic(Motion.seg(age, 0.0, 0.7))
		var sz := 0.1 + (0.32 + 0.12 * k) * grow
		q.transform = Transform3D(Basis.from_scale(Vector3(sz, sz, sz)), tip + Vector3(-0.1 - 0.22 * grow - 0.08 * k, 0.05 + 0.12 * grow + 0.05 * k, (k - 0.5) * 0.12))
		(q.material_override as ShaderMaterial).set_shader_parameter("alpha", 0.42 * (1.0 - Motion.seg(age, 0.15, 1.1)) * Motion.seg(age, 0.0, 0.04))
	# Motes drift slowly up the pipe on the blower's air; kicked up near the face after a blow.
	for i in _motes.instance_count:
		var hx := _hash(i * 1.1)
		var ang := _hash(i * 2.3) * TAU
		var rr := sqrt(_hash(i * 3.7)) * (R - 0.04)
		var drift := fposmod(hx * 9.0 - t * (0.05 + 0.08 * _hash(i * 5.3)), 9.0)
		var pos := Vector3(-drift, R + sin(ang + t * 0.2 * (hx - 0.5)) * rr, cos(ang + t * 0.2) * rr)
		var sz := 0.002 + 0.003 * _hash(i * 9.1)
		_motes.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * sz), pos))
