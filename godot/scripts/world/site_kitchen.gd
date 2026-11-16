extends RefCounted
## Real-object props for the Silkyara site kitchen (khichdi for the trapped men, packed in bottles).
##
## lathe() turns a (radius, height) profile into a mesh. On top of it: an aluminium degchi with soot and a
## rolled rim, a long karchi (ladle), a steel funnel, a ribbed PET bottle with a blue cap and a khichdi fill,
## a commercial LPG cylinder, a gas bhatti (iron ring stand) with a ring of blue flames, a jute sack, and
## soft lit steam sprites. khichdi_material() is turmeric-yellow rice and dal with cumin and peas, glossy with ghee.

const NOISE_GLSL := """
float h3(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float n3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
float fbm(vec3 p) {
	float a = n3(p) * 0.55;
	p = p * 2.17 + 11.7;
	a += n3(p) * 0.3;
	p = p * 2.31 + 5.1;
	return a + n3(p) * 0.15;
}
vec2 cells(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	float d1 = 8.0;
	float id = 0.0;
	for (int z = -1; z <= 1; z++) for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
		vec3 g = vec3(float(x), float(y), float(z));
		vec3 o = vec3(h3(i + g), h3(i + g + 3.1), h3(i + g + 7.7));
		float d = length(g + o - f);
		if (d < d1) { d1 = d; id = h3(i + g + 1.3); }
	}
	return vec2(d1, id);
}
"""

const KHICHDI_SHADER := """
shader_type spatial;
varying vec3 lp;
void vertex() { lp = VERTEX; }
//NOISE
void fragment() {
	vec3 p = lp * 62.0;
	vec2 c = cells(p);
	float grain = 1.0 - smoothstep(0.25, 0.55, c.x);
	vec3 base = mix(vec3(0.8, 0.44, 0.02), vec3(1.0, 0.66, 0.08), fbm(lp * 18.0));
	vec3 rice = vec3(1.0, 0.8, 0.32);
	vec3 col = mix(base, rice, grain * 0.55);
	float cumin = step(0.965, c.y) * grain;
	float pea = step(0.93, c.y) * (1.0 - step(0.965, c.y)) * grain;
	col = mix(col, vec3(0.2, 0.12, 0.05), cumin);
	col = mix(col, vec3(0.32, 0.55, 0.12), pea);
	ALBEDO = col;
	ROUGHNESS = mix(0.32, 0.6, grain);
	SPECULAR = 0.6;
	float e = 0.004;
	float c0 = cells(lp * 62.0).x;
	vec3 g = vec3(cells((lp + vec3(e, 0, 0)) * 62.0).x - c0, cells((lp + vec3(0, e, 0)) * 62.0).x - c0, cells((lp + vec3(0, 0, e)) * 62.0).x - c0) / e;
	NORMAL = normalize(NORMAL + (VIEW_MATRIX * vec4(g, 0.0)).xyz * 0.0025);
}
"""

## Spun aluminium, blackened by the flame toward the bottom (soot), bright and scuffed at the rim.
const ALU_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform float soot_top = 0.18;
varying vec3 lp;
void vertex() { lp = VERTEX; }
//NOISE
void fragment() {
	float n = fbm(lp * 14.0);
	float brush = n3(vec3(atan(lp.z, lp.x) * 40.0, lp.y * 300.0, 0.0));
	float soot = (1.0 - smoothstep(soot_top * 0.4, soot_top + n * 0.08, lp.y));
	vec3 metal = vec3(0.78, 0.79, 0.8) * (0.85 + brush * 0.12 + n * 0.08);
	ALBEDO = mix(metal, vec3(0.04, 0.035, 0.03), soot * 0.95);
	METALLIC = mix(0.85, 0.2, soot);
	ROUGHNESS = mix(0.3 + brush * 0.12, 0.85, soot);
}
"""

static var _shaders := {}


static func shader_mat(code: String) -> ShaderMaterial:
	if not _shaders.has(code):
		var s := Shader.new()
		s.code = code.replace("//NOISE", NOISE_GLSL)
		_shaders[code] = s
	var m := ShaderMaterial.new()
	m.shader = _shaders[code]
	return m


static func khichdi_material() -> ShaderMaterial:
	return shader_mat(KHICHDI_SHADER)


static func mat(color: String, rough: float = 0.6, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = rough
	m.metallic = metal
	return m


## A surface of revolution about +Y: profile = [Vector2(radius, height), ...] from bottom to top.
static func lathe(profile: Array, segments: int = 40, close_bottom: bool = false) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in profile.size() - 1:
		var a: Vector2 = profile[i]
		var b: Vector2 = profile[i + 1]
		for k in segments:
			var t0 := TAU * float(k) / segments
			var t1 := TAU * float(k + 1) / segments
			var q := [Vector3(cos(t0) * a.x, a.y, sin(t0) * a.x), Vector3(cos(t1) * a.x, a.y, sin(t1) * a.x),
				Vector3(cos(t0) * b.x, b.y, sin(t0) * b.x), Vector3(cos(t1) * b.x, b.y, sin(t1) * b.x)]
			var uvs := [Vector2(float(k) / segments, float(i) / profile.size()), Vector2(float(k + 1) / segments, float(i) / profile.size()),
				Vector2(float(k) / segments, float(i + 1) / profile.size()), Vector2(float(k + 1) / segments, float(i + 1) / profile.size())]
			for o in [0, 2, 1, 1, 2, 3]:
				st.set_uv(uvs[o])
				st.add_vertex(q[o])
	if close_bottom:
		var p0: Vector2 = profile[0]
		for k in segments:
			var t0 := TAU * float(k) / segments
			var t1 := TAU * float(k + 1) / segments
			st.add_vertex(Vector3(0, p0.y, 0))
			st.add_vertex(Vector3(cos(t0) * p0.x, p0.y, sin(t0) * p0.x))
			st.add_vertex(Vector3(cos(t1) * p0.x, p0.y, sin(t1) * p0.x))
	st.generate_normals()
	return st.commit()


static func _mi(parent: Node3D, mesh: Mesh, m: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi


## A big aluminium degchi, radius ~r. The khichdi surface is the node "food" (move its y to change the level).
static func degchi(r: float = 0.36, h: float = 0.4) -> Node3D:
	var n := Node3D.new()
	var alu := shader_mat(ALU_SHADER)
	alu.set_shader_parameter("soot_top", h * 0.45)
	var outer := [Vector2(r * 0.86, 0.0), Vector2(r * 0.96, 0.02), Vector2(r, 0.07), Vector2(r, h * 0.92), Vector2(r * 1.01, h),
		Vector2(r * 1.06, h + 0.008), Vector2(r * 1.06, h + 0.022), Vector2(r * 0.99, h + 0.026), Vector2(r * 0.975, h)]
	_mi(n, lathe(outer, 48, true), alu)
	var inner := [Vector2(r * 0.975, h), Vector2(r * 0.975, 0.05), Vector2(r * 0.9, 0.02), Vector2(0.0, 0.015)]
	_mi(n, lathe(inner, 48), shader_mat(ALU_SHADER))
	for sx in [-1.0, 1.0]:
		var hd := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.035
		tm.outer_radius = 0.052
		hd.mesh = tm
		hd.material_override = mat("#8d9093", 0.35, 0.85)
		hd.position = Vector3(sx * (r + 0.035), h * 0.82, 0)
		hd.rotation.x = PI * 0.5
		n.add_child(hd)
	var food := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = r * 0.97
	fm.bottom_radius = r * 0.97
	fm.height = 0.02
	fm.radial_segments = 48
	food.mesh = fm
	food.material_override = khichdi_material()
	food.position = Vector3(0, h * 0.78, 0)
	food.name = "food"
	n.add_child(food)
	return n


## A karchi: a deep steel cup on a long flat handle. The cup's centre is at the origin, handle along -X then up.
static func karchi(length: float = 0.75) -> Node3D:
	var n := Node3D.new()
	var steel := mat("#c7cacd", 0.22, 0.95)
	steel.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cup := [Vector2(0.0, -0.045), Vector2(0.035, -0.04), Vector2(0.055, -0.02), Vector2(0.062, 0.01), Vector2(0.063, 0.02)]
	_mi(n, lathe(cup, 28), steel)
	var handle := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(length, 0.006, 0.022)
	handle.mesh = bm
	handle.material_override = steel
	handle.position = Vector3(-length * 0.5 - 0.05, 0.02 + length * 0.18, 0)
	handle.rotation.z = -0.38
	n.add_child(handle)
	var load := MeshInstance3D.new()
	var lm := SphereMesh.new()
	lm.radius = 0.054
	lm.height = 0.06
	load.mesh = lm
	load.material_override = khichdi_material()
	load.position = Vector3(0, 0.005, 0)
	load.name = "load"
	n.add_child(load)
	return n


## A steel funnel, mouth up, spout at the origin.
static func funnel() -> Node3D:
	var n := Node3D.new()
	var steel := mat("#bfc3c6", 0.25, 0.9)
	steel.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mi(n, lathe([Vector2(0.012, 0.0), Vector2(0.013, 0.05), Vector2(0.02, 0.06), Vector2(0.11, 0.15), Vector2(0.115, 0.165), Vector2(0.112, 0.17)], 32), steel)
	return n


## A 1 l PET bottle: clear ribbed body, neck, blue ridged cap; the khichdi inside is node "fill" (scale.y 0..1).
static func pet_bottle(capped: bool = true) -> Node3D:
	var n := Node3D.new()
	var prof := [Vector2(0.03, 0.0), Vector2(0.037, 0.004), Vector2(0.04, 0.015)]
	var y := 0.02
	var k := 0
	while y < 0.17:
		prof.append(Vector2(0.04 if k % 2 == 0 else 0.0385, y))
		y += 0.012
		k += 1
	prof.append_array([Vector2(0.039, 0.18), Vector2(0.03, 0.205), Vector2(0.016, 0.225), Vector2(0.0145, 0.24), Vector2(0.017, 0.242), Vector2(0.0145, 0.245), Vector2(0.0145, 0.252)])
	var pet := mat("#ffffff", 0.04)
	pet.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pet.albedo_color = Color(0.88, 0.95, 1.0, 0.1)
	pet.metallic_specular = 1.0
	pet.rim_enabled = true
	pet.rim = 0.35
	pet.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mi(n, lathe(prof, 32, true), pet)
	var fill := Node3D.new()
	fill.name = "fill"
	n.add_child(fill)
	var food := MeshInstance3D.new()
	food.mesh = lathe([Vector2(0.0, 0.004), Vector2(0.034, 0.006), Vector2(0.037, 0.02), Vector2(0.037, 0.16), Vector2(0.0, 0.165)], 28)
	food.material_override = khichdi_material()
	fill.add_child(food)
	if capped:
		var cap := Node3D.new()
		cap.name = "cap"
		cap.position = Vector3(0, 0.25, 0)
		n.add_child(cap)
		var blue := mat("#1f56b5", 0.35)
		_mi(cap, lathe([Vector2(0.0, 0.021), Vector2(0.0175, 0.021), Vector2(0.0185, 0.018), Vector2(0.0185, 0.0), Vector2(0.016, 0.0)], 24, false), blue)
		for i in 18:
			var a := TAU * i / 18.0
			var rib := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.0025, 0.016, 0.003)
			rib.mesh = bm
			rib.material_override = blue
			rib.position = Vector3(cos(a) * 0.0188, 0.01, sin(a) * 0.0188)
			rib.rotation.y = -a
			cap.add_child(rib)
	return n


## A 19 kg commercial LPG cylinder (red, steel collar and valve).
static func lpg_cylinder() -> Node3D:
	var n := Node3D.new()
	var red := mat("#b3261c", 0.45, 0.25)
	_mi(n, lathe([Vector2(0.15, 0.0), Vector2(0.155, 0.04), Vector2(0.16, 0.08), Vector2(0.16, 0.62), Vector2(0.15, 0.68), Vector2(0.11, 0.72), Vector2(0.05, 0.74), Vector2(0.0, 0.745)], 32, true), red)
	_mi(n, lathe([Vector2(0.155, 0.0), Vector2(0.16, 0.0), Vector2(0.16, 0.06), Vector2(0.155, 0.06)], 32), mat("#5b1510", 0.6, 0.3))
	var steel := mat("#8f9396", 0.4, 0.8)
	_mi(n, lathe([Vector2(0.09, 0.74), Vector2(0.095, 0.74), Vector2(0.095, 0.85), Vector2(0.09, 0.85)], 24), steel)
	_mi(n, lathe([Vector2(0.02, 0.745), Vector2(0.022, 0.80), Vector2(0.03, 0.81), Vector2(0.03, 0.84), Vector2(0.0, 0.845)], 16), mat("#c9a536", 0.3, 0.8))
	return n


## A gas bhatti: a cast-iron ring stand on three legs with a burner ring of blue flames (node "flames").
static func bhatti(top: float = 0.42) -> Node3D:
	var n := Node3D.new()
	var iron := mat("#1c1b1a", 0.75, 0.6)
	for i in 3:
		var a := TAU * i / 3.0
		var leg := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.022
		cm.bottom_radius = 0.028
		cm.height = top
		leg.mesh = cm
		leg.material_override = iron
		leg.position = Vector3(cos(a) * 0.3, top * 0.5, sin(a) * 0.3)
		n.add_child(leg)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.28
	tm.outer_radius = 0.34
	ring.mesh = tm
	ring.material_override = iron
	ring.position = Vector3(0, top, 0)
	n.add_child(ring)
	_mi(n, lathe([Vector2(0.13, top - 0.12), Vector2(0.15, top - 0.08), Vector2(0.15, top - 0.06), Vector2(0.0, top - 0.06)], 24), mat("#2b2a28", 0.6, 0.6))
	var flames := Node3D.new()
	flames.name = "flames"
	n.add_child(flames)
	var blue := mat("#3d7bff", 0.4)
	blue.emission_enabled = true
	blue.emission = Color("#4a86ff")
	blue.emission_energy_multiplier = 5.0
	blue.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blue.albedo_color = Color(0.3, 0.5, 1.0, 0.7)
	blue.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 22:
		var a := TAU * i / 22.0
		var f := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.012
		cm.height = 0.06
		cm.radial_segments = 6
		f.mesh = cm
		f.material_override = blue
		f.position = Vector3(cos(a) * 0.13, top - 0.03, sin(a) * 0.13)
		f.rotation = Vector3(sin(a) * 0.5, 0, -cos(a) * 0.5)
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flames.add_child(f)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, top - 0.02, 0)
	glow.light_color = Color("#ff9a4a")
	glow.light_energy = 1.2
	glow.omni_range = 1.6
	glow.name = "flame_glow"
	n.add_child(glow)
	return n


## A jute sack, slumped (squashed lumpy sphere with a tied neck).
static func sack(seed: int = 1) -> Node3D:
	var n := Node3D.new()
	var src := SphereMesh.new()
	src.radius = 0.5
	src.height = 1.0
	src.radial_segments = 18
	src.rings = 10
	var arr := src.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var nz := FastNoiseLite.new()
	nz.seed = seed
	nz.frequency = 2.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in idx:
		var v := verts[i]
		var slump := 1.0 + maxf(-v.y, 0.0) * 0.5
		st.add_vertex(Vector3(v.x * 0.36 * slump, (v.y + 0.5) * 0.62, v.z * 0.3 * slump) * (1.0 + nz.get_noise_3dv(v * 2.0) * 0.08))
	st.generate_normals()
	var jute := mat("#9b7a4a", 0.95)
	_mi(n, st.commit(), jute)
	return n


static var _puff_tex: ImageTexture


## A soft, wispy round puff (white, alpha falls off with some noise), made once.
static func puff_texture() -> ImageTexture:
	if _puff_tex != null:
		return _puff_tex
	var w := 64
	var img := Image.create(w, w, false, Image.FORMAT_RGBA8)
	var nz := FastNoiseLite.new()
	nz.seed = 5
	nz.frequency = 0.08
	for y in w:
		for x in w:
			var d := Vector2(x - w * 0.5, y - w * 0.5).length() / (w * 0.5)
			var a := clampf(1.0 - smoothstep(0.15, 1.0, d + nz.get_noise_2d(x, y) * 0.35), 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	_puff_tex = ImageTexture.create_from_image(img)
	return _puff_tex


## Steam: n soft lit puffs. Returns the MultiMeshInstance3D; pose with steam_pose().
static func steam(n: int, alpha: float = 0.28) -> MultiMeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	var m := StandardMaterial3D.new()
	m.albedo_texture = puff_texture()
	m.albedo_color = Color(0.95, 0.93, 0.9, alpha)
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.roughness = 1.0
	m.backlight_enabled = true
	m.backlight = Color(0.7, 0.7, 0.7)
	m.disable_receive_shadows = true
	q.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = q
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Steam rising from a disc of radius r at `at` (local to the steam node's parent), life seconds per puff.
static func steam_pose(mi: MultiMeshInstance3D, t: float, at: Vector3, r: float, rise: float = 0.5, life: float = 2.2, size: float = 0.25, on: float = 1.0) -> void:
	var mm := mi.multimesh
	for i in mm.instance_count:
		var h := fposmod(sin(i * 127.1 + 3.7) * 43758.5453, 1.0)
		var h2 := fposmod(sin(i * 311.7 + 1.3) * 43758.5453, 1.0)
		var age := fposmod(t + h * life, life)
		var k := age / life
		var a := h2 * TAU
		var p := at + Vector3(cos(a) * r * 0.7 * h, 0, sin(a) * r * 0.7 * h)
		p += Vector3(sin(age * 1.7 + i) * 0.06 * k + 0.08 * k, rise * age, cos(age * 1.3 + i) * 0.05 * k)
		var s := size * (0.35 + k * 1.4)
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(s, s, s)), p))
		mm.set_instance_color(i, Color(1, 1, 1, on * smoothstep(0.0, 0.15, k) * (1.0 - smoothstep(0.55, 1.0, k))))
