extends RefCounted
## The mountain cut open along the Silkyara bore: a cutaway (section) for the explainer beats.
##
## The cut plane is z = 0 and the camera looks at it from +z. The bore runs along X: the way out
## (the portal, the yard) is at -X, the trapped men at +X. Between them the plug of rubble fills
## the bore from PLUG_A to PLUG_B (60 m), its top a hand's breadth under the crown. Behind the cut
## plane you see the back half of the lined tunnel. Above it: banded rock, soil, pines, the sky.
##
## Beat 4 also lives here: a surveyor's tape. The engineer flings its hook (param `throw`), it
## zips up the toe, along the gap under the crown, down the far slope into the catcher's hand
## (param `catch`). The tape stays strung over the plug afterwards.
##
## params:
##   throw, catch   scene times (the hook leaves the hand / lands in the catcher's hand)
##   thrower, catcher   actor ids (their .hand anchors drive the reel and the hook)
## anchors: hook (the tape's end), plug (middle of the plug, just under the crown), rescue, trapped,
##          portal (the mouth on the left), summit (the mountain top over the plug)

const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const TunnelFinish = preload("res://scripts/world/silkyara_tunnel_finish.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")

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
	p = vec3(p.x * 0.8 - p.z * 0.6, p.y * 0.9 + p.x * 0.2, p.x * 0.6 + p.z * 0.8) * 2.17 + 11.7;
	a += n3(p) * 0.3;
	p = vec3(p.x * 0.6 - p.z * 0.8, p.y * 0.9 - p.z * 0.2, p.x * 0.8 + p.z * 0.6) * 2.31 + 5.1;
	return a + n3(p) * 0.15;
}
vec2 cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	float id = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(h3(vec3(i + g, 1.0)), h3(vec3(i + g, 2.0)));
			float d = length(g + o - f);
			if (d < d1) { d2 = d1; d1 = d; id = h3(vec3(i + g, 3.0)); }
			else if (d < d2) { d2 = d; }
		}
	}
	return vec2(d2 - d1, id);
}
"""

## The cut face of the mountain: tilted strata of phyllite and quartzite, a soil band under the
## surface (COLOR.r = 1 at the surface), cracks.
const CUT_SHADER := """
shader_type spatial;
render_mode cull_disabled;
varying vec3 wp;
void vertex() { wp = VERTEX; }
//NOISE
void fragment() {
	float tilt = wp.y + wp.x * 0.18;
	float bands = fbm(vec3(tilt * 0.22, wp.x * 0.012, 3.0));
	float fine = fbm(vec3(wp.x * 0.6, wp.y * 1.4, 1.0));
	float layer = fract(tilt * 0.11 + bands * 0.6);
	vec3 a = vec3(0.25, 0.225, 0.195);
	vec3 b = vec3(0.16, 0.153, 0.145);
	vec3 c = vec3(0.30, 0.245, 0.195);
	vec3 rock = mix(a, b, smoothstep(0.35, 0.65, layer));
	rock = mix(rock, c, smoothstep(0.82, 0.9, layer) * 0.8);
	rock *= 0.72 + fine * 0.5;
	float crack = 1.0 - smoothstep(0.0, 0.035, abs(n3(vec3(wp.x * 0.09, wp.y * 0.35, 7.0)) - 0.5));
	rock *= 1.0 - crack * 0.45;
	vec3 soil = vec3(0.17, 0.12, 0.08) * (0.7 + fine * 0.5);
	ALBEDO = mix(rock, soil, smoothstep(0.55, 0.85, COLOR.r));
	ROUGHNESS = 0.95;
	float e = 0.05;
	vec3 q = wp * 0.9;
	float c0 = fbm(q);
	vec3 g = vec3(fbm(q + vec3(e, 0.0, 0.0)) - c0, fbm(q + vec3(0.0, e, 0.0)) - c0, 0.0) / e;
	NORMAL = normalize(NORMAL - (VIEW_MATRIX * vec4(g, 0.0)).xyz * 0.06);
}
"""

## The plug: broken rock packed tight, grey shotcrete fragments among it, dark voids.
const RUBBLE_SHADER := """
shader_type spatial;
render_mode cull_disabled;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
//NOISE
void fragment() {
	vec2 p = wp.xy + wp.zz * vec2(0.64, 0.92);
	p += vec2(fbm(wp * 0.6), fbm(wp * 0.6 + 13.0)) * 0.5;
	vec2 c = cells(p * 0.9);
	vec2 s = cells(p * 2.6 + 4.0);
	float edge = smoothstep(0.02, 0.14, c.x) * (0.55 + 0.45 * smoothstep(0.02, 0.1, s.x));
	vec3 stone = mix(vec3(0.23, 0.215, 0.2), vec3(0.15, 0.135, 0.12), c.y);
	stone = mix(stone, vec3(0.42, 0.41, 0.38), step(0.86, c.y));          // shotcrete fragments
	stone = mix(stone, vec3(0.3, 0.16, 0.08), step(0.97, c.y) * 0.8);      // rusted steel
	stone *= 0.75 + fbm(wp * 3.0) * 0.4;
	ALBEDO = stone * mix(0.15, 1.0, edge);
	ROUGHNESS = 0.92;
	float e = 0.03;
	float c0 = cells(p * 0.9).x;
	vec2 g = vec2(cells((p + vec2(e, 0.0)) * 0.9).x - c0, cells((p + vec2(0.0, e)) * 0.9).x - c0) / e;
	NORMAL = normalize(NORMAL - (VIEW_MATRIX * vec4(-g.x, -g.y, 0.0, 0.0)).xyz * 0.35);
}
"""

## Sprayed concrete lining, ring joints every 1.2 m, wet streaks.
const LINING_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 tint : source_color = vec3(0.42, 0.4, 0.37);
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
//NOISE
void fragment() {
	float base = fbm(wp * 0.6);
	float fine = fbm(wp * 5.0);
	float joint = smoothstep(0.93, 1.0, abs(fract(wp.x / 1.2) - 0.5) * 2.0);
	float streak = smoothstep(0.55, 0.8, n3(vec3(wp.x * 1.7, wp.y * 0.1, wp.z * 1.7)));
	vec3 col = tint * (0.7 + base * 0.45 + fine * 0.15) * (1.0 - joint * 0.5);
	ALBEDO = mix(col, col * 0.5, streak * 0.6);
	ROUGHNESS = mix(0.9, 0.5, streak);
}
"""

## The mountain's top and the yard: dry grass and needle litter, grey gravel in the yard.
const SURFACE_SHADER := """
shader_type spatial;
render_mode cull_disabled;
varying vec3 wp;
void vertex() { wp = VERTEX; }
//NOISE
void fragment() {
	float m = fbm(wp * 0.08);
	float f = fbm(wp * 0.8);
	vec3 grass = mix(vec3(0.17, 0.135, 0.075), vec3(0.08, 0.085, 0.055), smoothstep(0.35, 0.65, m));
	vec3 gravel = vec3(0.16, 0.15, 0.14) * (0.7 + f * 0.5);
	ALBEDO = mix(grass * (0.7 + f * 0.5), gravel, COLOR.g);
	ROUGHNESS = mix(0.95, 0.8, COLOR.g);
}
"""

const R := 5.9            # bore radius (8.5 m to the crown)
const PS := 2.6           # where the arch springs
const CROWN := PS + R
const X_PORTAL := -92.0
const X_DEEP := 170.0
const PLUG_A := 0.0       # rescue-side top edge of the plug
const PLUG_B := 60.0      # trapped-side top edge
const TOE_A := -7.5       # where the slopes meet the floor
const TOE_B := 68.0
const HEAP := 7.8         # top of the plug (the gap under the crown is CROWN - HEAP)
const SLOT := 8.12        # the tape runs here
const BACK := -60.0       # how deep the top surface runs behind the cut

var _shaders := {}
var _trapped_lights: Array = []
var _opposite_lights: Array = []
var _road_mat: ShaderMaterial
var _opposite_bore: Node3D
var _tape_node: MeshInstance3D
var _tape: ImmediateMesh
var _tape_mat: StandardMaterial3D
var _hook: Node3D
var _reel: Node3D
var _lifeline: Node3D
var _spanner: Node3D
var _noise: FastNoiseLite


func build(_g: Dictionary) -> Node3D:
	var _p: Dictionary = _g.get("params", {})
	var root := Node3D.new()
	_noise = FastNoiseLite.new()
	_noise.seed = 60
	_noise.frequency = 0.02
	_build_cut(root)
	_build_surface(root)
	_build_bore(root)
	_build_opposite_bore(root)
	_build_portal(root)
	_build_plug(root)
	_build_lights(root)
	_build_tape(root)
	_build_lifeline(root)
	_build_feed_out(root)
	_build_rig(root)
	_build_xpipe(root)
	_build_xauger(root)
	_build_ridge(root)
	_build_escape(root)
	_build_stretchers(root, _p)
	return root


# ------------------------------------------------------------------------------ helpers

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


func _rod(parent: Node3D, a: Vector3, b: Vector3, r: float, mat: Material, sides: int = 10) -> MeshInstance3D:
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


func _aim(dir: Vector3) -> Basis:
	var d := dir.normalized()
	return Basis.looking_at(d, Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ca: Color = Color.BLACK, cb: Color = Color.BLACK, cc: Color = Color.BLACK, cd: Color = Color.BLACK) -> void:
	# a b on the bottom edge, c d on the top edge, wound to face +z.
	for v in [[a, ca], [c, cc], [b, cb], [b, cb], [c, cc], [d, cd]]:
		st.set_color(v[1])
		st.add_vertex(v[0])


## Height of the mountain's surface above the bore's floor, at x (and depth z behind the cut).
func top(x: float, z: float = 0.0) -> float:
	if x < X_PORTAL - 4.0:
		return 0.0
	var h := 14.0 + 92.0 * smoothstep(X_PORTAL, 40.0, x) + 26.0 * smoothstep(40.0, 200.0, x)
	h += _noise.get_noise_2d(x, z) * 5.0 + _noise.get_noise_2d(x * 4.0, z * 4.0) * 1.2
	h += maxf(-z, 0.0) * 0.35
	var face := smoothstep(X_PORTAL - 4.0, X_PORTAL + 8.0, x)
	return h * face


# ------------------------------------------------------------------------------ the cut face

func _build_cut(root: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := 1.5
	var x := -170.0
	while x < 230.0:
		var x1 := x + step
		# Below the floor: bedrock all the way across.
		_quad(st, Vector3(x, -40.0, 0), Vector3(x1, -40.0, 0), Vector3(x, 0, 0), Vector3(x1, 0, 0))
		var t0 := top(x)
		var t1 := top(x1)
		var in_bore := x >= X_PORTAL and x1 <= X_DEEP + 0.01
		var lo := CROWN if in_bore else 0.0
		if t0 > lo + 0.01 or t1 > lo + 0.01:
			var a0 := minf(lo, t0)
			var a1 := minf(lo, t1)
			_quad(st, Vector3(x, a0, 0), Vector3(x1, a1, 0), Vector3(x, t0, 0), Vector3(x1, t1, 0),
				Color(_soil(a0, t0), 0, 0), Color(_soil(a1, t1), 0, 0), Color(1, 0, 0), Color(1, 0, 0))
		x = x1
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _shader(CUT_SHADER)
	root.add_child(mi)
	# The soil band needs vertices near the surface: a thin strip just under the top edge.
	var band := SurfaceTool.new()
	band.begin(Mesh.PRIMITIVE_TRIANGLES)
	x = X_PORTAL - 4.0
	while x < 230.0:
		var x1 := x + step
		var t0 := top(x)
		var t1 := top(x1)
		var d0 := maxf(t0 - 3.0, CROWN + 0.05 if x > X_PORTAL else 0.0)
		var d1 := maxf(t1 - 3.0, CROWN + 0.05 if x1 > X_PORTAL else 0.0)
		if t0 > d0 + 0.05:
			_quad(band, Vector3(x, d0, 0.01), Vector3(x1, d1, 0.01), Vector3(x, t0, 0.01), Vector3(x1, t1, 0.01),
				Color(0.4, 0, 0), Color(0.4, 0, 0), Color(1, 0, 0), Color(1, 0, 0))
		x = x1
	band.generate_normals()
	var bm := MeshInstance3D.new()
	bm.mesh = band.commit()
	bm.material_override = _shader(CUT_SHADER)
	root.add_child(bm)


func _soil(y: float, surface: float) -> float:
	return clampf(1.0 - (surface - y) / 6.0, 0.0, 1.0)


## The mountain's surface running back from the cut, and the yard outside the portal.
func _build_surface(root: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := 2.0
	var x := -170.0
	while x < 230.0:
		var x1 := x + step
		var z := 0.0
		while z > BACK:
			var z1 := z - 3.0
			var yard := 1.0 if x1 < X_PORTAL - 2.0 else 0.0
			var c := Color(0, yard, 0)
			var p := [Vector3(x, top(x, z), z), Vector3(x1, top(x1, z), z), Vector3(x, top(x, z1), z1), Vector3(x1, top(x1, z1), z1)]
			for k in [0, 2, 1, 1, 2, 3]:
				st.set_color(c)
				st.add_vertex(p[k])
			z = z1
		x = x1
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _shader(SURFACE_SHADER)
	root.add_child(mi)
	# Pines along the top (Quaternius, CC0), thinning out toward the summit.
	var pines := ["quaternius_nature_mega/Pine_1", "quaternius_nature_mega/Pine_2", "quaternius_nature_mega/Pine_4", "quaternius_nature_mega/Pine_5"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 60
	for i in 150:
		var px := rng.randf_range(X_PORTAL + 6.0, 220.0)
		var pz := -rng.randf_range(1.5, 45.0)
		var id: String = pines[rng.randi() % pines.size()]
		var tree := KitDB.static_node(id, rng.randf_range(1.6, 2.6))
		tree.position = Vector3(px, top(px, pz) - 0.3, pz)
		tree.rotation.y = rng.randf() * TAU
		root.add_child(tree)


# ------------------------------------------------------------------------------ the bore

## The back half of the lined bore (floor and arch behind the cut plane) from x0 to x1.
func _build_bore(root: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var prof: Array = [Vector2(0.0, 0.0), Vector2(-R, 0.0)]          # (z, y): floor, then the wall
	var n := 16
	for k in n + 1:
		var th := PI - PI * 0.5 * float(k) / n                       # from the springing line to the crown
		prof.append(Vector2(-R * absf(cos(th)), PS + sin(th) * R))
	var x := X_PORTAL
	while x < X_DEEP:
		var x1 := minf(x + 2.0, X_DEEP)
		for k in prof.size() - 1:
			var a: Vector2 = prof[k]
			var b: Vector2 = prof[k + 1]
			var q := [Vector3(x, a.y, a.x), Vector3(x1, a.y, a.x), Vector3(x, b.y, b.x), Vector3(x1, b.y, b.x)]
			for o in [0, 1, 2, 1, 3, 2]:
				st.add_vertex(q[o])
		x = x1
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _shader(TunnelFinish.ROCK_SHADER)
	mi.name = "section_lining"
	root.add_child(mi)
	# The same wheel ruts and puddles as the hook, rotated into the cutaway's coordinates.
	_road_mat = _shader(TunnelFinish.FLOOR_SHADER)
	_road_mat.set_shader_parameter("section_axis", true)
	var road := _box(root, Vector3(X_DEEP - X_PORTAL, 0.05, R), Vector3((X_DEEP + X_PORTAL) * 0.5, 0.0, -R * 0.5), _road_mat)
	road.name = "section_floor"
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_build_ribs(root)
	# Services along the back wall: the duct at the crown, the water main low down.
	var duct := _mat("#d68a1d", 0.7)
	_rod(root, Vector3(X_PORTAL, CROWN - 1.2, -2.2), Vector3(TOE_A - 1.0, CROWN - 1.2, -2.2), 0.6, duct, 14)
	_rod(root, Vector3(TOE_B + 1.0, CROWN - 1.2, -2.2), Vector3(X_DEEP, CROWN - 1.2, -2.2), 0.6, duct, 14)
	var pipe := _mat("#3b4148", 0.45, 0.6)
	_rod(root, Vector3(X_PORTAL, 0.55, -R + 0.4), Vector3(X_DEEP, 0.55, -R + 0.4), 0.16, pipe, 10)


## Use the hook's steel rib profile and spacing, retaining the back half in section.
func _build_ribs(root: Node3D) -> void:
	var stations: Array[float] = []
	for metre in range(int(X_PORTAL) + 2, int(X_DEEP), 2):
		if metre < TOE_A or metre > TOE_B:
			stations.append(float(metre))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = TunnelFinish.rib_mesh(R, PS, 32, true)
	mm.instance_count = stations.size()
	var turn := Basis(Vector3.UP, PI * 0.5)
	for i in stations.size():
		mm.set_instance_transform(i, Transform3D(turn, Vector3(stations[i], 0, 0)))
	var ribs := MultiMeshInstance3D.new()
	ribs.multimesh = mm
	ribs.name = "section_ribs"
	var steel := _mat("#3d3531", 0.62, 0.55)
	steel.cull_mode = BaseMaterial3D.CULL_DISABLED
	ribs.material_override = steel
	ribs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ribs)


## Close the cut plane for interior shots; the mirrored lining uses the hook's same geometry.
func _build_opposite_bore(root: Node3D) -> void:
	_opposite_bore = Node3D.new()
	_opposite_bore.scale = Vector3(1, 1, -1)
	root.add_child(_opposite_bore)
	for name in ["section_lining", "section_floor", "section_ribs"]:
		var copy := root.get_node(NodePath(name)).duplicate() as Node3D
		if name == "section_lining":
			var lining := copy as MeshInstance3D
			lining.material_override = _shader(TunnelFinish.ROCK_SHADER.replace("void fragment() {", "void fragment() { NORMAL = -NORMAL;"))
		_opposite_bore.add_child(copy)
	_box(_opposite_bore, Vector3(0.2, CROWN + 1.0, R * 2.0), Vector3(X_DEEP, CROWN * 0.5, 0), _mat("#13110f", 1.0))
	# Matching practical fixtures on the opposite wall, staggered along the bore.
	var x := TOE_B + 7.0
	while x < X_DEEP - 2.0:
		var at := Vector3(x, 3.05, -R + 0.2)
		var housing := _mat("#26282b", 0.5, 0.5)
		_box(_opposite_bore, Vector3(0.64, 0.25, 0.12), at, housing)
		var lens_mat := _lit("#e3ecff", 6.0)
		_box(_opposite_bore, Vector3(0.56, 0.18, 0.08), at + Vector3(0, 0, 0.08), lens_mat)
		var lamp := OmniLight3D.new()
		lamp.position = at + Vector3(0, -0.15, 0.55)
		lamp.light_color = Color("#e3ecff")
		lamp.light_energy = 2.8
		lamp.omni_range = 15.0
		lamp.omni_attenuation = 1.0
		lamp.light_volumetric_fog_energy = 1.2
		_opposite_bore.add_child(lamp)
		_opposite_lights.append({"lamp": lamp, "material": lens_mat})
		x += 9.0
	_opposite_bore.visible = false


## Section through the concrete headwall and the illuminated first rings of the bore.
func _build_portal(root: Node3D) -> void:
	var concrete := _shader(LINING_SHADER)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner: Array[Vector2] = [Vector2(-R, 0.0)]
	var outer: Array[Vector2] = [Vector2(-R - 0.8, 0.0)]
	for k in 17:
		var angle := PI * 0.5 * float(k) / 16.0
		var radial := Vector2(-cos(angle), sin(angle))
		var spring := Vector2(0.0, PS)
		inner.append(spring + radial * R)
		outer.append(spring + radial * (R + 0.8))
	for k in inner.size() - 1:
		var a := inner[k]
		var b := inner[k + 1]
		var c := outer[k]
		var d := outer[k + 1]
		_quad(st, Vector3(X_PORTAL - 1.2, a.y, a.x), Vector3(X_PORTAL - 1.2, b.y, b.x),
			Vector3(X_PORTAL - 1.2, c.y, c.x), Vector3(X_PORTAL - 1.2, d.y, d.x))
		_quad(st, Vector3(X_PORTAL - 1.2, c.y, c.x), Vector3(X_PORTAL - 1.2, d.y, d.x),
			Vector3(X_PORTAL + 2.0, c.y, c.x), Vector3(X_PORTAL + 2.0, d.y, d.x))
		_quad(st, Vector3(X_PORTAL - 1.2, a.y, a.x), Vector3(X_PORTAL - 1.2, b.y, b.x),
			Vector3(X_PORTAL + 2.0, a.y, a.x), Vector3(X_PORTAL + 2.0, b.y, b.x))
	st.generate_normals()
	var collar := MeshInstance3D.new()
	collar.mesh = st.commit()
	collar.material_override = concrete
	root.add_child(collar)

	# Match the hook's red dumper and cold light tower on the portal apron.
	var truck := KitDB.static_node("majadroid_construction/Trucks#Dumper Truck Red", 0.82)
	truck.position = Vector3(X_PORTAL - 16.0, 0.0, -4.8)
	truck.rotation.y = PI * 0.5
	root.add_child(truck)
	var mast_at := Vector3(X_PORTAL - 26.0, 0.0, -8.5)
	var steel := _mat("#55595c", 0.52, 0.55)
	_box(root, Vector3(1.7, 0.85, 1.2), mast_at + Vector3(0, 0.425, 0), steel)
	_rod(root, mast_at, mast_at + Vector3(0, 7.0, 0), 0.09, steel)
	_box(root, Vector3(1.6, 0.12, 0.15), mast_at + Vector3(0, 7.0, 0), steel)
	var white := _lit("#e6efff", 10.0)
	for dx in [-0.56, 0.56]:
		_box(root, Vector3(0.47, 0.26, 0.13), mast_at + Vector3(dx, 7.08, 0.06), white)
	var tower := OmniLight3D.new()
	tower.position = mast_at + Vector3(0, 6.9, 0.55)
	tower.light_color = Color("#dbe8ff")
	tower.light_energy = 5.0
	tower.omni_range = 21.0
	root.add_child(tower)

	var fixture := _lit("#ffc282", 7.0)
	for k in 5:
		var at := Vector3(X_PORTAL + 1.5 + k * 7.0, 3.8, -R + 0.2)
		_box(root, Vector3(0.52, 0.22, 0.14), at, fixture)
		var lamp := OmniLight3D.new()
		lamp.position = at + Vector3(0, 0, 1.1)
		lamp.light_color = Color("#ffb472")
		lamp.light_energy = 3.2
		lamp.omni_range = 10.5
		lamp.light_volumetric_fog_energy = 1.2
		root.add_child(lamp)


# ------------------------------------------------------------------------------ the plug

func _heap_top(x: float) -> float:
	if x <= TOE_A or x >= TOE_B:
		return 0.0
	if x < PLUG_A:
		var u := (x - TOE_A) / (PLUG_A - TOE_A)
		return HEAP * pow(u, 0.85) + sin(x * 1.7) * 0.25 * u
	if x > PLUG_B:
		var u := (TOE_B - x) / (TOE_B - PLUG_B)
		return HEAP * pow(u, 0.85) + sin(x * 1.3) * 0.25 * u
	return HEAP + _noise.get_noise_1d(x * 6.0) * 0.12


func _build_plug(root: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x := TOE_A
	var step := 0.5
	while x < TOE_B:
		var x1 := minf(x + step, TOE_B)
		var h0 := _heap_top(x)
		var h1 := _heap_top(x1)
		# The cut face of the plug.
		_quad(st, Vector3(x, 0, 0.0), Vector3(x1, 0, 0.0), Vector3(x, h0, 0.0), Vector3(x1, h1, 0.0))
		# Break up the slope in depth so the cold work lights pick up real relief.
		for j in 12:
			var z0 := -R * float(j) / 12.0
			var z1 := -R * float(j + 1) / 12.0
			var a := _plug_surface(x, h0, z0)
			var b := _plug_surface(x1, h1, z0)
			var c := _plug_surface(x, h0, z1)
			var d := _plug_surface(x1, h1, z1)
			_quad(st, a, b, c, d)
		x = x1
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _shader(RUBBLE_SHADER)
	root.add_child(mi)
	# Boulders and wreckage bulging from the face: lining panels, a bent rib.
	var rock := _shader(RUBBLE_SHADER)
	var rng := RandomNumberGenerator.new()
	rng.seed = 61
	for i in 70:
		var bx := rng.randf_range(TOE_A + 1.0, TOE_B - 1.0)
		var by := rng.randf_range(0.3, maxf(_heap_top(bx) - 0.4, 0.4))
		var s := rng.randf_range(0.5, 1.6)
		var stone := MeshInstance3D.new()
		stone.mesh = _stone_mesh(i, 0.35)
		stone.material_override = rock
		stone.transform = Transform3D(Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, 0)).scaled(Vector3(s, s * 0.7, s * 0.6)), Vector3(bx, by, -0.05))
		root.add_child(stone)
		_plug_bits.append(stone)
	var shot := _mat("#6f6b63", 0.9)
	var steel := _mat("#5a3a24", 0.6, 0.6)
	for i in 9:
		var px := rng.randf_range(PLUG_A + 3.0, PLUG_B - 3.0)
		var panel := _box(root, Vector3(rng.randf_range(1.8, 3.2), 0.25, rng.randf_range(1.2, 2.0)), Vector3(px, rng.randf_range(1.5, 6.5), -0.3), shot)
		panel.rotation = Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * PI, rng.randf_range(-1.2, 1.2))
		_plug_bits.append(panel)
	for i in 4:
		var px := rng.randf_range(PLUG_A + 6.0, PLUG_B - 6.0)
		var py := rng.randf_range(2.0, 6.0)
		var a := Vector3(px, py, -0.2)
		var b := a + Vector3(rng.randf_range(-2.5, 2.5), rng.randf_range(0.8, 2.0), 0.0)
		_rod(root, a, b, 0.11, steel, 6)
		_rod(root, b, b + Vector3(rng.randf_range(0.8, 2.0), rng.randf_range(-1.0, 0.6), 0.0), 0.11, steel, 6)


func _plug_surface(x: float, height: float, z: float) -> Vector3:
	var depth := -z / R
	var relief := _noise.get_noise_2d(x * 58.0, z * 54.0) * 0.62
	var rough_height := height + depth * (relief - 0.38)
	return Vector3(x, maxf(rough_height, 0.0), z)


func _stone_mesh(seed: int, lump: float) -> ArrayMesh:
	var src := SphereMesh.new()
	src.radius = 0.5
	src.height = 1.0
	src.radial_segments = 9
	src.rings = 5
	var arr := src.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var nz := FastNoiseLite.new()
	nz.seed = seed
	nz.frequency = 1.3
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in idx:
		var v := verts[i]
		st.add_vertex(v * (1.0 + nz.get_noise_3dv(v * 2.0) * lump))
	st.generate_normals()
	return st.commit()


# ------------------------------------------------------------------------------ light

func _build_lights(root: Node3D) -> void:
	# Trapped side: the sodium wall lamps that kept burning (reports: power survived inside).
	var x := TOE_B + 4.0
	while x < X_DEEP - 2.0:
		var at := Vector3(x, 3.05, -R + 0.25)
		var lens_mat := _lit("#ffb25e", 7.0)
		_box(root, Vector3(0.6, 0.26, 0.12), at, lens_mat)
		var lamp := OmniLight3D.new()
		lamp.position = at + Vector3(0, -0.2, 1.4)
		lamp.light_color = Color("#ffab5c")
		lamp.light_energy = 3.8
		lamp.omni_range = 13.0
		lamp.omni_attenuation = 1.1
		lamp.light_volumetric_fog_energy = 1.2
		root.add_child(lamp)
		_trapped_lights.append({"lamp": lamp, "material": lens_mat})
		x += 9.0
	# Rescue side: cold floods on stands aimed at the rubble.
	for fx in [TOE_A - 9.0, TOE_A - 26.0]:
		var base := Vector3(fx, 0, -3.8)
		var frame := _mat("#c9a224", 0.6, 0.3)
		_rod(root, base, base + Vector3(0, 4.2, 0), 0.05, frame, 6)
		var head := base + Vector3(0, 4.3, 0)
		var lens := _box(root, Vector3(0.12, 0.45, 0.6), head, _lit("#eef4ff", 14.0))
		lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var spot := SpotLight3D.new()
		spot.transform = Transform3D(_aim(Vector3(TOE_A + 3.0, 2.5, -1.5) - head), head)
		spot.light_color = Color("#dfe9ff")
		spot.light_energy = 9.0
		spot.spot_range = 45.0
		spot.spot_angle = 34.0
		spot.shadow_enabled = true
		spot.light_volumetric_fog_energy = 1.0
		root.add_child(spot)
	# The sodium fixture behind the engineer uses the same warm lamp as the hook.
	var fixture_at := Vector3(TOE_A - 1.2, 3.05, -R + 0.15)
	_box(root, Vector3(0.57, 0.26, 0.12), fixture_at, _mat("#242628", 0.5, 0.6))
	_box(root, Vector3(0.47, 0.16, 0.08), fixture_at + Vector3(0, 0, 0.09), _lit("#ffab5c", 6.0))
	var practical := OmniLight3D.new()
	practical.position = fixture_at + Vector3(0, -0.15, 0.55)
	practical.light_color = Color("#ffab5c")
	practical.light_energy = 3.0
	practical.omni_range = 13.0
	practical.omni_attenuation = 1.1
	practical.light_volumetric_fog_energy = 1.6
	root.add_child(practical)
	# Light from the equipment on the cut side falls back across the hands and wet road.
	for entry in [[TOE_A - 4.5, "#e3ecff", 2.8], [TOE_B + 0.0, "#ffd2a2", 2.4]]:
		var bounce := OmniLight3D.new()
		bounce.position = Vector3(entry[0], 2.8, 1.05)
		bounce.light_color = Color(entry[1])
		bounce.light_energy = entry[2]
		bounce.omni_range = 7.0
		root.add_child(bounce)
	# Outside the portal, the yard's light tower glow.
	var yard := OmniLight3D.new()
	yard.position = Vector3(X_PORTAL - 8.0, 7.0, -2.0)
	yard.light_color = Color("#dfe9ff")
	yard.light_energy = 6.0
	yard.omni_range = 40.0
	yard.light_volumetric_fog_energy = 1.5
	root.add_child(yard)
	# A soft fill on the cut face so the strata read, from in front and above.
	var fill := SpotLight3D.new()
	fill.transform = Transform3D(_aim(Vector3(0, -0.5, -1.0)), Vector3(20.0, 60.0, 120.0))
	fill.light_color = Color("#9ba7bf")
	fill.light_energy = 1.9
	fill.spot_range = 400.0
	fill.spot_angle = 50.0
	fill.spot_attenuation = 0.4
	root.add_child(fill)


## The surviving supply pipe emerging from the rubble and a metal spanner.
func _build_lifeline(root: Node3D) -> void:
	_lifeline = Node3D.new()
	root.add_child(_lifeline)
	var steel := _mat("#888c8a", 0.38, 0.8)
	var dark := _mat("#262b2d", 0.5, 0.7)
	var a := Vector3(TOE_B - 2.4, 0.76, -1.25)
	var b := Vector3(TOE_B + 0.95, 0.76, -1.25)
	_rod(_lifeline, a, b, 0.19, steel, 18)
	_rod(_lifeline, b - Vector3(0.16, 0, 0), b - Vector3(0.05, 0, 0), 0.23, dark, 18)
	var hole := CylinderMesh.new()
	hole.top_radius = 0.145
	hole.bottom_radius = 0.145
	hole.height = 0.015
	var mouth := MeshInstance3D.new()
	mouth.mesh = hole
	mouth.material_override = dark
	mouth.rotation.z = PI * 0.5
	mouth.position = b + Vector3(0.012, 0, 0)
	_lifeline.add_child(mouth)
	_spanner = Node3D.new()
	root.add_child(_spanner)
	_rod(_spanner, Vector3.ZERO, Vector3(0, 0.38, 0), 0.035, steel, 8)
	_rod(_spanner, Vector3(-0.10, 0.38, 0), Vector3(0.10, 0.38, 0), 0.045, steel, 8)


# ------------------------------------------------------------------------------ the tape

func _build_tape(root: Node3D) -> void:
	_tape = ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = _tape
	_tape_node = mi
	_tape_mat = _lit("#ffd21f", 1.05)
	_tape_mat.roughness = 0.56
	_tape_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = _tape_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	# The hook: a brass ring with a lead weight.
	_hook = Node3D.new()
	root.add_child(_hook)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.046
	tm.outer_radius = 0.079
	ring.mesh = tm
	ring.material_override = _mat("#c7a043", 0.35, 0.8)
	ring.rotation.x = PI * 0.5
	_hook.add_child(ring)
	var weight := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.056
	sm.height = 0.112
	weight.mesh = sm
	weight.material_override = _mat("#55585c", 0.4, 0.7)
	weight.position = Vector3(0, -0.091, 0)
	_hook.add_child(weight)
	# The reel: an open surveyor's frame with a yellow drum.
	_reel = Node3D.new()
	root.add_child(_reel)
	var drum := CylinderMesh.new()
	drum.top_radius = 0.17
	drum.bottom_radius = 0.17
	drum.height = 0.07
	var dm := MeshInstance3D.new()
	dm.mesh = drum
	dm.material_override = _mat("#e0b21a", 0.5)
	dm.rotation.x = PI * 0.5
	_reel.add_child(dm)
	_rod(_reel, Vector3(0, -0.17, 0), Vector3(0, -0.42, 0), 0.025, _mat("#1b1b1b", 0.6), 6)


## The hook's path: up the rescue toe, along the slot under the crown, down to the catcher.
func _path(start: Vector3) -> Array:
	var pts: Array = [start, Vector3(TOE_A + 0.8, 3.1, -0.9), Vector3(TOE_A + 3.2, 5.6, -0.6), Vector3(PLUG_A - 0.5, SLOT, -0.35)]
	var x := PLUG_A + 4.0
	while x < PLUG_B:
		pts.append(Vector3(x, SLOT, -0.35))
		x += 4.0
	pts.append(Vector3(PLUG_B + 0.5, SLOT, -0.35))
	pts.append(Vector3(TOE_B - 3.0, 4.2, -0.5))
	pts.append(Vector3(TOE_B + 0.23, 2.02, -1.1))
	return pts


func _along(pts: Array, s: float) -> Array:
	# Returns [point at fraction s of the length, index of the last full vertex before it].
	var total := 0.0
	for k in pts.size() - 1:
		total += (pts[k] as Vector3).distance_to(pts[k + 1])
	var want := s * total
	for k in pts.size() - 1:
		var d := (pts[k] as Vector3).distance_to(pts[k + 1])
		if want <= d:
			return [(pts[k] as Vector3).lerp(pts[k + 1], want / maxf(d, 1e-4)), k]
		want -= d
	return [pts[pts.size() - 1], pts.size() - 2]


func _ribbon(pts: Array, width: float) -> void:
	_tape.clear_surfaces()
	if pts.size() < 2:
		return
	_tape.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in pts.size() - 1:
		var a: Vector3 = pts[k]
		var b: Vector3 = pts[k + 1]
		var d := (b - a).normalized()
		var side := d.cross(Vector3(0, 0, 1)).normalized() * width * 0.5
		if side.length() < 0.001:
			side = Vector3(width * 0.5, 0, 0)
		for v in [a - side, a + side, b - side, b - side, a + side, b + side]:
			_tape.surface_add_vertex(v)
	_tape.surface_end()


func pose(root: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	var origin: Vector3 = ctx["holder"].global_position
	_road_mat.set_shader_parameter("origin", origin)
	_pose_feed_out(p, t, ctx)
	_pose_rig(p, t, ctx)
	var light_start := float(p.get("light_start", INF))
	_opposite_bore.visible = t >= light_start and t < light_start + 1.5
	var light_on := float(p.get("light_on", INF))
	if t >= light_start and t < light_on + 0.8:
		for i in _trapped_lights.size():
			var k := Motion.smooth(_seg(t, light_on + i * 0.07, light_on + i * 0.07 + 0.12))
			var light: OmniLight3D = _trapped_lights[i]["lamp"]
			var mat: StandardMaterial3D = _trapped_lights[i]["material"]
			light.light_energy = 3.8 * k
			mat.emission_energy_multiplier = 0.1 + 6.9 * k
	else:
		for entry in _trapped_lights:
			var light: OmniLight3D = entry["lamp"]
			var mat: StandardMaterial3D = entry["material"]
			light.light_energy = 3.8
			mat.emission_energy_multiplier = 7.0
	if _opposite_bore.visible:
		for i in _opposite_lights.size():
			var k := Motion.smooth(_seg(t, light_on + i * 0.07 + 0.04, light_on + i * 0.07 + 0.16))
			var light: OmniLight3D = _opposite_lights[i]["lamp"]
			var mat: StandardMaterial3D = _opposite_lights[i]["material"]
			light.light_energy = 2.8 * k
			mat.emission_energy_multiplier = 0.1 + 5.9 * k
	var measuring := t < float(p.get("measure_until", INF))
	_tape_node.visible = measuring
	_hook.visible = measuring
	_reel.visible = measuring
	_lifeline.visible = not measuring
	_spanner.visible = not measuring
	var t_throw := float(p.get("throw", 1.0))
	var t_catch := float(p.get("catch", 2.2))
	var thrower_id := String(p.get("thrower", ""))
	var hand_a := _hand(ctx, thrower_id, origin, Vector3(TOE_A - 1.0, 1.3, -1.5))
	var chest_a := _point(ctx, thrower_id + ".chest", origin, hand_a)
	_reel.position = chest_a + Vector3(0.05, -0.25, 0.32)
	if ctx.has("actor"):
		var thrower: Node3D = ctx["actor"].call(thrower_id)
		if thrower != null:
			var grip := chest_a + Vector3(0.25, -0.40, -0.28)
			thrower.aim_hand("l", origin + grip)
			_reel.position = thrower.bone_world("hand_l") - origin + Vector3(0.0, -0.15, 0.08)
	var catcher_id := String(p.get("catcher", ""))
	var hand_b := _hand(ctx, catcher_id, origin, Vector3(TOE_B + 1.0, 1.3, -1.5))
	if ctx.has("actor"):
		var catcher: Node3D = ctx["actor"].call(catcher_id)
		if catcher != null:
			# The left hand is on the cutaway side. Reach, then draw the tape toward the chest.
			var catch_weight := Motion.out_cubic(_seg(t, t_catch - 0.4, t_catch))
			var settle := Motion.smooth(_seg(t, t_catch, t_catch + 0.32))
			var recoil := 0.12 * sin(PI * _seg(t, t_catch, t_catch + 0.22))
			var chest := _point(ctx, catcher_id + ".chest", origin, hand_b) + origin
			var reach := Vector3(-0.50, 0.03, 0.19).lerp(Vector3(-0.16, -0.12, 0.25), settle)
			if measuring:
				catcher.aim_hand("l", chest + reach + Vector3(recoil, -recoil * 0.5, 0), catch_weight)
			else:
				var strike := float(p.get("point_pipe", INF))
				var ready := Motion.smooth(_seg(t, strike - 1.0, strike - 0.6))
				var hit := Motion.smooth(_seg(t, strike - 0.22, strike))
				var release := Motion.out_cubic(_seg(t, strike + 0.12, strike + 0.45))
				var raised := chest + Vector3(-0.32, 0.15, 0.35)
				var contact := origin + Vector3(TOE_B + 1.0, 0.94, -1.08)
				var target := raised.lerp(contact, hit).lerp(chest + Vector3(-0.25, -0.25, 0.25), release)
				catcher.aim_hand("l", target, ready)
				var hand: Vector3 = catcher.bone_world("hand_l")
				_spanner.position = hand - origin
				_spanner.rotation = Vector3(0, 0, lerpf(-0.6, 1.05, hit))
			hand_b = catcher.bone_world("hand_l") - origin
	var hook: Vector3
	var shown: Array = []
	if t < t_throw:
		hook = hand_a + Vector3(0, -0.05, 0.05)
		shown = [_reel.position, hook]
	else:
		var path := _path(hand_a)
		var approach_start := t_catch - 0.26
		var last_vertex: int
		if t < approach_start:
			var u := _seg(t, t_throw, approach_start)
			var at: Array = _along(path, 1.0 - pow(1.0 - u, 1.25))
			hook = at[0]
			last_vertex = at[1]
		else:
			var approach: Vector3 = path.back()
			var k := _seg(t, approach_start, t_catch)
			hook = Motion.arc(approach, hand_b, 0.11, 1.0 - pow(1.0 - k, 1.5))
			last_vertex = path.size() - 1
		shown.append(_reel.position)
		for k in last_vertex + 1:
			shown.append(path[k])
		shown.append(hook)
		# Once caught, the tape is pulled taut: it lifts off the heap a touch.
		var taut := Motion.out_cubic(_seg(t, t_catch, t_catch + 0.35))
		for k in shown.size():
			var v: Vector3 = shown[k]
			if v.y > HEAP and v.y < CROWN:
				shown[k] = v + Vector3(0, 0.12 * taut, 0)
	_hook.position = hook
	_hook.rotation.z = t * 9.0 if (t > t_throw and t < t_catch) else 0.0
	var close := t < float(p.get("wide", t_catch + 0.82))
	_tape_mat.emission_energy_multiplier = 0.09 if close else 1.05
	_ribbon(shown, 0.023 if close else 0.065)
	var xp_out := _pose_xpipe(p, t, origin)
	xp_out.merge(_pose_xauger(p, t, origin, ctx))
	xp_out.merge(_pose_ridge(p, t, ctx, origin))
	_pose_escape(p, t, ctx, origin)
	_pose_stretchers(p, t, ctx, origin)
	var res := {"hook": hook, "plug": Vector3((PLUG_A + PLUG_B) * 0.5, CROWN + 1.5, 0.0),
		"rescue": Vector3(TOE_A - 6.0, 1.6, -1.5), "trapped": Vector3(TOE_B + 6.0, 1.6, -1.5),
		"portal": Vector3(X_PORTAL, 4.0, -1.0), "summit": Vector3((PLUG_A + PLUG_B) * 0.5, top(30.0), 0.0)}
	res.merge(xp_out)
	return res


func _seg(t: float, t0: float, t1: float) -> float:
	return clampf((t - t0) / (t1 - t0), 0.0, 1.0)


func _hand(ctx: Dictionary, id: String, origin: Vector3, fallback: Vector3) -> Vector3:
	return _point(ctx, id + ".hand", origin, fallback)


func _point(ctx: Dictionary, ref: String, origin: Vector3, fallback: Vector3) -> Vector3:
	if ref.begins_with("."):
		return fallback
	var r: Dictionary = ctx["point"].call(ref)
	if r.has("error"):
		return fallback
	return (r["pos"] as Vector3) - origin


# ------------------------------------------------------------------------------ line 7: feeding the pipe

## params.feed_out = {"from" (all of it appears: pipe end, packet, hose), "shove" (the packet goes into
## the pipe), "couple" (the hose coupling seats on the pipe), "pusher", "hoser" (actor ids)}.
## params.appear = {actor id: scene time}: those actors are hidden before it.
const FEED_M := Vector3(TOE_A - 0.8, 0.8, -1.25)      # the pipe's open end on the rescue side

var _fo: Node3D
var _fo_packet: Node3D
var _fo_coupling: Node3D
var _fo_hose: Array = []


func _build_feed_out(root: Node3D) -> void:
	_fo = Node3D.new()
	_fo.visible = false
	root.add_child(_fo)
	var steel := _mat("#6d7376", 0.38, 0.8)
	var dark := _mat("#151719", 0.6, 0.4)
	# The supply pipe out of the rubble, a flange and its dark bore.
	_rod(_fo, FEED_M + Vector3(2.0, 0.0, 0.0), FEED_M, 0.085, steel, 16)
	_rod(_fo, FEED_M + Vector3(0.05, 0, 0), FEED_M - Vector3(0.04, 0, 0), 0.13, steel, 18)
	var mouth := MeshInstance3D.new()
	var mm := CylinderMesh.new()
	mm.top_radius = 0.07
	mm.bottom_radius = 0.07
	mm.height = 0.01
	mouth.mesh = mm
	mouth.material_override = dark
	mouth.rotation.z = PI * 0.5
	mouth.position = FEED_M - Vector3(0.045, 0, 0)
	_fo.add_child(mouth)
	# A clear packet of puffed rice.
	_fo_packet = Node3D.new()
	_fo.add_child(_fo_packet)
	var rice := _lit("#f4e3b8", 0.2)
	rice.roughness = 0.95
	_box(_fo_packet, Vector3(0.3, 0.1, 0.12), Vector3.ZERO, rice)
	# The grains you can see through the bag.
	var grain := CapsuleMesh.new()
	grain.radius = 0.012
	grain.height = 0.04
	grain.radial_segments = 6
	grain.rings = 2
	grain.material = rice
	var gm := MultiMesh.new()
	gm.transform_format = MultiMesh.TRANSFORM_3D
	gm.mesh = grain
	gm.instance_count = 140
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in gm.instance_count:
		var at := Vector3(rng.randf_range(-0.17, 0.17), rng.randf_range(-0.07, 0.07), rng.randf_range(-0.08, 0.08))
		gm.set_instance_transform(i, Transform3D(Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)), at))
	var gmi := MultiMeshInstance3D.new()
	gmi.multimesh = gm
	_fo_packet.add_child(gmi)
	var bag := _mat("#ffffff", 0.05)
	bag.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bag.albedo_color = Color(1, 1, 1, 0.22)
	_box(_fo_packet, Vector3(0.39, 0.175, 0.19), Vector3.ZERO, bag)
	_box(_fo_packet, Vector3(0.03, 0.14, 0.195), Vector3(-0.2, 0.0, 0.0), _mat("#d23c2a", 0.6))   # the red-printed seal
	# The compressor hose: a brass coupling and a yellow hose trailing off to the compressor.
	_fo_coupling = Node3D.new()
	_fo.add_child(_fo_coupling)
	var brass := _mat("#c49a3c", 0.3, 0.85)
	_rod(_fo_coupling, Vector3(0.0, 0, 0), Vector3(-0.16, 0, 0), 0.1, brass, 14)
	_rod(_fo_coupling, Vector3(-0.08, 0.1, 0), Vector3(-0.08, 0.22, 0), 0.018, brass, 6)
	var yellow := _mat("#e2b11b", 0.55)
	for i in 14:
		var seg := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.055
		cm.bottom_radius = 0.055
		cm.height = 1.0
		cm.radial_segments = 10
		seg.mesh = cm
		seg.material_override = yellow
		_fo.add_child(seg)
		_fo_hose.append(seg)


func _set_rod(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var y := d.normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y, x.cross(y).normalized()) * Basis.from_scale(Vector3(1, maxf(d.length(), 0.001), 1)), (a + b) * 0.5)


func _pose_feed_out(p: Dictionary, t: float, ctx: Dictionary) -> void:
	for id in p.get("appear", {}):
		var a = ctx["actor"].call(String(id)) if ctx.has("actor") else null
		if a != null:
			a.visible = t >= float(p["appear"][id])
	if not p.has("feed_out"):
		return
	var f: Dictionary = p["feed_out"]
	_fo.visible = t >= float(f.get("from", 1.0e9))
	if not _fo.visible:
		return
	var shove := float(f.get("shove", 1.0e9))
	var couple := float(f.get("couple", 1.0e9))
	# The packet: held ready, pulled back, rammed into the pipe, gone.
	var hold := FEED_M + Vector3(-0.45, 0.05, 0.05)
	var back := FEED_M + Vector3(-0.62, 0.08, 0.08)
	var inside := FEED_M + Vector3(0.3, 0.0, 0.0)
	var pk := hold.lerp(back, Motion.smooth(Motion.seg(t, shove - 0.32, shove - 0.1)))
	pk = pk.lerp(inside, Motion.in_cubic(Motion.seg(t, shove - 0.1, shove)))
	var squeeze := Motion.seg(t, shove - 0.06, shove)
	_fo_packet.position = pk
	_fo_packet.scale = Vector3(1.0, 1.0 - 0.45 * squeeze, 1.0 - 0.35 * squeeze)
	_fo_packet.visible = t < shove + 0.02
	var pusher = ctx["actor"].call(String(f.get("pusher", ""))) if ctx.has("actor") else null
	if pusher != null:
		var origin: Vector3 = ctx["holder"].global_position
		var w := 1.0 - Motion.smooth(Motion.seg(t, shove + 0.05, shove + 0.35))
		pusher.aim_hand("l", origin + pk + Vector3(-0.14, 0.0, 0.1), w)
		pusher.aim_hand("r", origin + pk + Vector3(-0.14, 0.0, -0.1), w)
	# The coupling: carried in, then seated on the pipe with a shove.
	var ready := FEED_M + Vector3(-0.55, 0.32, -0.55)
	var seat := FEED_M + Vector3(-0.05, 0, 0)
	var cp := ready.lerp(seat, Motion.in_out(Motion.seg(t, couple - 0.42, couple)))
	cp += Vector3(-0.02, 0, 0) * Motion.impact(t - couple, 1.0, 9.0, 12.0) if t > couple else Vector3.ZERO
	_fo_coupling.position = cp
	var hoser = ctx["actor"].call(String(f.get("hoser", ""))) if ctx.has("actor") else null
	if hoser != null:
		var origin2: Vector3 = ctx["holder"].global_position
		hoser.aim_hand("r", origin2 + cp + Vector3(-0.12, 0.05, 0.0), 1.0)
		hoser.aim_hand("l", origin2 + cp + Vector3(-0.2, 0.0, -0.08), 1.0)
	# The hose sags from the coupling to the floor and away to the compressor.
	var ctrl := [cp + Vector3(-0.16, 0, 0), cp + Vector3(-0.55, -0.1, 0.0), Vector3(cp.x - 0.9, 0.06, cp.z - 0.4),
		Vector3(cp.x - 3.0, 0.06, cp.z - 1.4), Vector3(cp.x - 8.0, 0.06, cp.z - 1.6)]
	var pts := []
	for i in _fo_hose.size() + 1:
		var u := float(i) / _fo_hose.size() * (ctrl.size() - 1)
		var k := mini(int(u), ctrl.size() - 2)
		var fr := u - k
		var c0: Vector3 = ctrl[maxi(k - 1, 0)]
		var c1: Vector3 = ctrl[k]
		var c2: Vector3 = ctrl[k + 1]
		var c3: Vector3 = ctrl[mini(k + 2, ctrl.size() - 1)]
		pts.append(0.5 * ((2.0 * c1) + (-c0 + c2) * fr + (2.0 * c0 - 5.0 * c1 + 4.0 * c2 - c3) * fr * fr + (-c0 + 3.0 * c1 - 3.0 * c2 + c3) * fr * fr * fr))
	for i in _fo_hose.size():
		_set_rod(_fo_hose[i], pts[i], pts[i + 1])


func _hash(n: float) -> float:
	return fposmod(sin(n * 127.1 + 3.7) * 43758.5453, 1.0)


# ------------------------------------------------------------------------------ line 10: the auger at the rubble

## params.rig = {"from", "push0", "push1" (the carriage drives the pipe in between these times), "dist",
## "bite" (when the pipe meets the rubble)}; params.spare = {"from", "crawler", "squeeze0", "squeeze1"}:
## a spare 800 mm pipe on the floor that a rescuer squeezes into (cartoon squash).
const AugerRig = preload("res://scripts/world/auger_rig.gd")
const RIG_AT := Vector3(TOE_A - 5.6, 0.0, -2.5)         # rig origin; its +Z points along +X (into the rubble)
const SPARE_A := Vector3(TOE_A - 33.0, 0.43, -2.6)      # the spare pipe's closed-off far end
const SPARE_B := Vector3(TOE_A - 27.0, 0.43, -2.6)      # its open mouth

var _rig: Node3D
var _rig_moving: Array = []
var _rig_home: Array = []
var _debris: MultiMesh
var _spare: Node3D


func _build_rig(root: Node3D) -> void:
	_rig = AugerRig.build(true)
	_rig.position = RIG_AT
	_rig.rotation.y = PI * 0.5
	_rig.visible = false
	root.add_child(_rig)
	for n in ["carriage", "casing", "lip", "flight"]:
		var node := _rig.get_node_or_null(n) as Node3D
		if node != null:
			_rig_moving.append(node)
			_rig_home.append(node.position)
	# A timber platform under it, a hydraulic power pack, hoses, a stack of pipe sections waiting.
	var timber := _mat("#6b4a2b", 0.9)
	for k in 6:
		_box(_rig, Vector3(2.6, 0.12, 0.22), Vector3(0, -0.06, -4.6 + k * 1.8), timber)
	_rig.position.y = 0.12
	var pack := _mat("#2f6b3a", 0.6, 0.3)
	_box(root, Vector3(1.2, 1.1, 2.0), Vector3(TOE_A - 12.5, 0.55, -4.4), pack)
	_rod(root, Vector3(TOE_A - 12.0, 0.8, -3.6), Vector3(TOE_A - 8.0, 0.25, -3.4), 0.04, _mat("#111111", 0.6), 6).name = "hose_a"
	_rod(root, Vector3(TOE_A - 8.0, 0.25, -3.4), Vector3(TOE_A - 6.4, 0.9, -3.1), 0.04, _mat("#111111", 0.6), 6)
	var pipe_m := _mat("#5b5f60", 0.45, 0.7)
	for k in 3:
		var y := 0.43 + (0.86 if k == 2 else 0.0)
		var z := -4.6 + (0.9 * k if k < 2 else 0.45)
		_rod(root, Vector3(TOE_A - 21.0, y, z), Vector3(TOE_A - 15.0, y, z), 0.43, pipe_m, 26)
	# Rubble kicked out where the pipe bites.
	var stone := SphereMesh.new()
	stone.radius = 0.5
	stone.height = 1.0
	stone.radial_segments = 7
	stone.rings = 4
	stone.material = _mat("#5c544b", 0.95)
	_debris = MultiMesh.new()
	_debris.transform_format = MultiMesh.TRANSFORM_3D
	_debris.mesh = stone
	_debris.instance_count = 40
	var dmi := MultiMeshInstance3D.new()
	dmi.multimesh = _debris
	root.add_child(dmi)
	# The spare pipe: an open steel tube you can see into (rust, a weld seam, a lit mouth).
	_spare = Node3D.new()
	_spare.visible = false
	root.add_child(_spare)
	var tube := CylinderMesh.new()
	tube.top_radius = 0.43
	tube.bottom_radius = 0.43
	tube.height = SPARE_A.distance_to(SPARE_B)
	tube.radial_segments = 40
	tube.rings = 8
	tube.cap_top = false
	tube.cap_bottom = false
	var steel := _mat("#6a5244", 0.6, 0.55)
	steel.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = tube
	mi.material_override = steel
	mi.rotation.z = PI * 0.5
	mi.position = (SPARE_A + SPARE_B) * 0.5
	_spare.add_child(mi)
	var seam := TorusMesh.new()
	seam.inner_radius = 0.42
	seam.outer_radius = 0.445
	seam.rings = 40
	seam.ring_segments = 6
	for x in [SPARE_A.x + 2.0, SPARE_A.x + 4.0, SPARE_B.x]:
		var r := MeshInstance3D.new()
		r.mesh = seam
		r.material_override = _mat("#3d3a37", 0.5, 0.7)
		r.rotation.z = PI * 0.5
		r.position = Vector3(x, SPARE_A.y, SPARE_A.z)
		_spare.add_child(r)
	# A work lamp on a stand outside throws light into the mouth (and onto whoever crawls in).
	var lamp := SpotLight3D.new()
	lamp.transform = Transform3D(Basis.looking_at(Vector3(-1.0, -0.35, 0.15).normalized()), SPARE_B + Vector3(3.2, 1.6, -0.5))
	lamp.light_color = Color("#ffe2b8")
	lamp.light_energy = 6.0
	lamp.spot_range = 14.0
	lamp.spot_angle = 30.0
	lamp.shadow_enabled = true
	_spare.add_child(lamp)
	# The far end is blanked off with a plate.
	_box(_spare, Vector3(0.04, 0.9, 0.9), SPARE_A - Vector3(0.02, 0, 0), _mat("#3a3634", 0.7, 0.5))
	for z in [-0.35, 0.35]:
		_box(_spare, Vector3(0.12, 0.1, 0.12), SPARE_B + Vector3(-0.4, -0.38, z), timber)     # chocks


func _pose_rig(p: Dictionary, t: float, ctx: Dictionary) -> void:
	for id in p.get("vanish", {}):
		var a = ctx["actor"].call(String(id)) if ctx.has("actor") else null
		if a != null and t >= float(p["vanish"][id]):
			a.visible = false
	if p.has("feed_out") and t >= float(p["feed_out"].get("until", 1.0e9)):
		_fo.visible = false
	if p.has("rig"):
		var r: Dictionary = p["rig"]
		_rig.visible = t >= float(r.get("from", 1.0e9)) and t < float(r.get("until", 1.0e9))
		var push0 := float(r.get("push0", 1.0e9))
		var push1 := float(r.get("push1", 1.0e9))
		var dist := float(r.get("dist", 2.0))
		# Rams take up the load (a small kick back), then a steady shove that slows as the rubble resists.
		var k := Motion.out_cubic(Motion.seg(t, push0, push1))
		var kick := -0.06 * Motion.smooth(Motion.seg(t, push0 - 0.25, push0)) * (1.0 - Motion.seg(t, push0, push0 + 0.2))
		for i in _rig_moving.size():
			(_rig_moving[i] as Node3D).position = (_rig_home[i] as Vector3) + Vector3(0, 0, dist * k + kick)
		var flight := _rig.get_node_or_null("flight") as Node3D
		if flight != null and t > push0 - 0.3:
			flight.rotation.z = -(t - push0 + 0.3) * 9.0
		_rig.position.y = 0.12 + 0.012 * sin(t * 47.0) * Motion.seg(t, push0 - 0.3, push0)
		# Debris spat out round the casing where it bites into the heap.
		var bite := float(r.get("bite", 1.0e9))
		var mouth := RIG_AT + Vector3(4.95 + dist * k, 1.37, 0.0)
		for i in _debris.instance_count:
			var born := bite + _hash(i * 3.3) * (push1 - bite)
			var age := t - born
			var xf := Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), mouth)
			if age > 0.0 and age < 1.2:
				var ang := _hash(i * 7.1) * TAU
				var v := Vector3(-1.2 - _hash(i * 2.2) * 1.5, 1.0 + _hash(i * 4.4) * 1.2, cos(ang) * 1.1)
				var pos := mouth + Vector3(0, sin(ang) * 0.45, cos(ang) * 0.45) + v * age + Vector3(0, -6.0 * age * age, 0)
				pos.y = maxf(pos.y, 0.06)
				var s := 0.05 + _hash(i * 9.9) * 0.12
				xf = Transform3D(Basis.from_euler(Vector3(age * 6.0, i, age * 4.0)).scaled(Vector3.ONE * s), pos)
			_debris.set_instance_transform(i, xf)
	if p.has("spare"):
		var sp: Dictionary = p["spare"]
		_spare.visible = t >= float(sp.get("from", 1.0e9))
		var who = ctx["actor"].call(String(sp.get("crawler", ""))) if ctx.has("actor") else null
		if who != null and _spare.visible:
			var origin: Vector3 = ctx["holder"].global_position
			var x: float = who.global_position.x - origin.x
			# Squashed flat to fit, from the moment his head reaches the mouth.
			var inside := smoothstep(SPARE_B.x + 0.9, SPARE_B.x - 0.2, x)
			who.scale = Vector3(1.0 + 0.22 * inside, 1.0 - 0.5 * inside, 1.0 + 0.22 * inside)


# ------------------------------------------------------------------------------ line 7 (revised): oxygen and a jar through the pipe

## params.xpipe = {"from", "until", "flow" (blue oxygen lines start), "jar0", "jar1" (the jar rides the air from
## x0 to x1 between these times), "x0", "x1"}: the supply pipe cut open along the section plane, running through
## the rubble at hip height, with glowing blue streaks of oxygen racing through it and a jar of puffed rice riding them.
## Anchor: jar.
const XP_Y := 0.95
const XP_R := 0.17
const XP_Z := 0.19
const STREAKS := 240

var _xp: Node3D
var _xp_streaks: MultiMesh
var _xp_jar: Node3D
var _xp_glow: OmniLight3D
var _xp_col: MeshInstance3D
var _xp_ring: MeshInstance3D


func _build_xpipe(root: Node3D) -> void:
	_xp = Node3D.new()
	_xp.visible = false
	root.add_child(_xp)
	var x0 := TOE_A - 6.0
	var x1 := TOE_B + 6.0
	# The back half of the pipe (open toward the camera): dark worn steel inside, bright cut edges.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 16
	var x := x0
	while x < x1:
		var xb := minf(x + 2.0, x1)
		for k in n:
			var a0 := PI * 0.5 + PI * float(k) / n
			var a1 := PI * 0.5 + PI * float(k + 1) / n
			var p := [Vector3(x, XP_Y + sin(a0) * XP_R, XP_Z + cos(a0) * XP_R), Vector3(xb, XP_Y + sin(a0) * XP_R, XP_Z + cos(a0) * XP_R),
				Vector3(x, XP_Y + sin(a1) * XP_R, XP_Z + cos(a1) * XP_R), Vector3(xb, XP_Y + sin(a1) * XP_R, XP_Z + cos(a1) * XP_R)]
			for o in [0, 2, 1, 1, 2, 3]:
				st.add_vertex(p[o])
		x = xb
	st.generate_normals()
	var half := MeshInstance3D.new()
	half.mesh = st.commit()
	var inner := _mat("#2b3036", 0.45, 0.7)
	inner.cull_mode = BaseMaterial3D.CULL_DISABLED
	half.material_override = inner
	_xp.add_child(half)
	var edge := _mat("#c9ced2", 0.25, 0.9)
	for sy in [-1.0, 1.0]:
		_rod(_xp, Vector3(x0, XP_Y + sy * XP_R, XP_Z), Vector3(x1, XP_Y + sy * XP_R, XP_Z), 0.018, edge, 6)
	# Weld collars every 6 m.
	var collar := _mat("#7d8287", 0.4, 0.8)
	x = x0 + 3.0
	while x < x1:
		_box(_xp, Vector3(0.05, XP_R * 2.2, 0.03), Vector3(x, XP_Y, XP_Z - XP_R * 0.95), collar)
		# Bright cut-edge clamps on both lips: they whip past when we ride with the jar.
		for sy in [-1.0, 1.0]:
			_box(_xp, Vector3(0.06, 0.05, 0.06), Vector3(x, XP_Y + sy * XP_R, XP_Z), edge)
		x += 1.2
	# Oxygen: thin glowing blue dashes.
	var dash := CapsuleMesh.new()
	dash.radius = 0.012
	dash.height = 0.5
	dash.radial_segments = 6
	dash.rings = 1
	var blue := _lit("#4fb6ff", 4.5)
	blue.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dash.material = blue
	_xp_streaks = MultiMesh.new()
	_xp_streaks.transform_format = MultiMesh.TRANSFORM_3D
	_xp_streaks.mesh = dash
	_xp_streaks.instance_count = STREAKS
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = _xp_streaks
	smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_xp.add_child(smi)
	var colm := BoxMesh.new()
	colm.size = Vector3(1.0, XP_R * 1.5, XP_R * 1.2)
	_xp_col = MeshInstance3D.new()
	_xp_col.mesh = colm
	var cm := _lit("#3c9dff", 1.2)
	cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cm.albedo_color = Color(0.25, 0.6, 1.0, 0.22)
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_xp_col.material_override = cm
	_xp_col.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_xp.add_child(_xp_col)
	var ring := CylinderMesh.new()
	ring.top_radius = XP_R * 0.85
	ring.bottom_radius = XP_R * 0.85
	ring.height = 0.04
	_xp_ring = MeshInstance3D.new()
	_xp_ring.mesh = ring
	var rm := _lit("#8fd2ff", 3.0)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color = Color(0.6, 0.85, 1.0, 0.55)
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_xp_ring.material_override = rm
	_xp_ring.rotation.z = PI * 0.5
	_xp_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_xp.add_child(_xp_ring)
	_xp_glow = OmniLight3D.new()
	_xp_glow.light_color = Color("#5ab8ff")
	_xp_glow.light_energy = 1.4
	_xp_glow.omni_range = 1.2
	_xp.add_child(_xp_glow)
	# The jar: a glass jar of puffed rice with a red lid, lying on its side, riding the air.
	_xp_jar = Node3D.new()
	_xp.add_child(_xp_jar)
	var glass := _mat("#ffffff", 0.05)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.85, 0.95, 1.0, 0.28)
	glass.metallic_specular = 1.0
	_rod(_xp_jar, Vector3(-0.13, 0, 0), Vector3(0.13, 0, 0), 0.11, glass, 18)
	var rice := _lit("#f2e2b5", 0.25)
	var grain := CapsuleMesh.new()
	grain.radius = 0.014
	grain.height = 0.042
	grain.radial_segments = 6
	grain.rings = 2
	grain.material = rice
	var gm := MultiMesh.new()
	gm.transform_format = MultiMesh.TRANSFORM_3D
	gm.mesh = grain
	gm.instance_count = 120
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in gm.instance_count:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 0.09
		gm.set_instance_transform(i, Transform3D(Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, 0)),
			Vector3(rng.randf_range(-0.11, 0.11), sin(a) * r, cos(a) * r)))
	var gmi := MultiMeshInstance3D.new()
	gmi.multimesh = gm
	_xp_jar.add_child(gmi)
	_rod(_xp_jar, Vector3(-0.155, 0, 0), Vector3(-0.12, 0, 0), 0.105, _mat("#c3352a", 0.4), 18)


## The air column: where its front is (it rushes down the pipe, hits the jar's lid on "hit", then drives it).
func _xp_front(t: float, flow: float, hit: float, jx: float) -> float:
	var start := TOE_A - 6.0
	if t < hit:
		return lerpf(start, jx - 0.16, Motion.in_cubic(Motion.seg(t, flow, hit)))
	return jx - 0.16


func _pose_xpipe(p: Dictionary, t: float, origin: Vector3) -> Dictionary:
	if not p.has("xpipe"):
		return {}
	var xp: Dictionary = p["xpipe"]
	_xp.visible = t >= float(xp.get("from", 1.0e9)) and t < float(xp.get("until", 1.0e9))
	if not _xp.visible:
		return {}
	var flow := float(xp.get("flow", 1.0e9))
	var hit := float(xp.get("hit", 1.0e9))
	var j1 := float(xp.get("jar1", 1.0e9))
	var x0 := float(xp.get("x0", TOE_A))
	var x1 := float(xp.get("x1", TOE_A + 8.0))
	# The jar: at rest, squashed by the blast, then shoved down the pipe faster and faster.
	# An impulse, not an ease-in: the instant the air hits it leaps off at speed, then keeps accelerating.
	var dur := maxf(j1 - hit, 0.1)
	var v0 := 7.0
	var acc := maxf(2.0 * ((x1 - x0) - v0 * dur) / (dur * dur), 0.0)
	var dt := clampf(t - hit, 0.0, dur)
	var jx := x0 + v0 * dt + 0.5 * acc * dt * dt
	var squash := Motion.impact(t - hit, 0.35, 5.0, 9.0) if t > hit else 0.0
	var stretch := 0.25 * Motion.seg(t, hit + 0.15, j1)
	_xp_jar.position = Vector3(jx, XP_Y - XP_R + 0.12 + 0.01 * sin(t * 57.0) * Motion.seg(t, hit, hit + 0.1), XP_Z - XP_R * 0.3)
	_xp_jar.scale = Vector3(1.0 - squash + stretch, 1.0 + squash * 0.5, 1.0 + squash * 0.5)
	_xp_jar.rotation.x = 0.0
	var front := _xp_front(t, flow, hit, jx)
	var on := Motion.smooth(Motion.seg(t, flow, flow + 0.2))
	# Streaks fill the column behind the front, rushing forward into it (bunched up near the front).
	var start := TOE_A - 6.0
	for i in STREAKS:
		var lane := Vector2((_hash(i * 2.1) - 0.5) * 1.5, (_hash(i * 4.7) - 0.5) * 1.5) * XP_R * 0.75
		var u := fposmod(_hash(i * 1.1) - (t - flow) * (1.1 + _hash(i * 7.3) * 0.8), 1.0)
		var d := u * u * 9.0
		var x := front - d - 0.05
		var xf := Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), Vector3(x, XP_Y, XP_Z))
		if on > 0.0 and x > start:
			var len := (0.6 + _hash(i * 5.5) * 1.0) * (1.6 if t > hit else 1.0)
			xf = Transform3D(Basis(Vector3.FORWARD, PI * 0.5).scaled(Vector3(1.0, len * on, 1.0)),
				Vector3(x - len * 0.25, XP_Y + lane.y, XP_Z - XP_R * 0.3 + lane.x * 0.5))
		_xp_streaks.set_instance_transform(i, xf)
	# The column's body and the pressure ring pressing on the lid.
	_xp_col.visible = on > 0.0 and front > start + 0.1
	var col_len := maxf(front - start, 0.01)
	_xp_col.position = Vector3(start + col_len * 0.5, XP_Y, XP_Z - XP_R * 0.25)
	_xp_col.scale = Vector3(col_len, 1.0, 1.0)
	_xp_ring.visible = _xp_col.visible
	_xp_ring.position = Vector3(front + 0.02, XP_Y, XP_Z - XP_R * 0.25)
	var press := 1.0 + 0.6 * Motion.impact(t - hit, 1.0, 6.0, 7.0) if t > hit else 1.0
	_xp_ring.scale = Vector3.ONE * press
	(_xp_ring.material_override as StandardMaterial3D).emission_energy_multiplier = 3.0 + (5.0 if t > hit else 0.0)
	_xp_glow.light_energy = 0.0
	return {"jar": origin + _xp_jar.position}


# ------------------------------------------------------------------------------ line 13: the auger chews through the plug

## params.xauger = {"from", "until", "keys": [[t, metres], ...], "chew" (the head bites the boulder), "metres" (how
## many spoken metres the whole plug is at pipe height, 57)}: the 800 mm casing string cut open along the section
## plane (an x-ray, like the oxygen pipe of line 7), its back half lying on the plug's cut face, the auger's flight
## spinning inside it, spoil riding back along the flight, a cutting head at the nose. Between consecutive keys the
## bored distance eases in and out; equal values are a stall. A boulder sits in the way at the start and shatters
## on "chew". Anchor: nose (the cutting head).
const AX_Y := 1.37          # the casing's axis, the same height as the rig's casing
const AX_R := 0.42
const AX_Z := 0.44          # the back half lies on the cut face (z = 0)
const AX_LEN := 72.0        # length of the pipe string behind the nose (clipped where it leaves the rubble)
const AX_PITCH := 0.55
const SPOIL := 90
const GRIT := 36

## Steel, clipped to the part of the string inside the rubble: model-space x < -keep is discarded.
const XA_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform float keep = 1000.0;
uniform float front = -1000.0;
uniform vec3 color : source_color = vec3(0.3, 0.32, 0.34);
uniform float metal = 0.7;
uniform float rough = 0.45;
uniform float glow = 0.0;
varying vec3 lp;
void vertex() { lp = VERTEX; }
//NOISE
void fragment() {
	if (lp.x < -keep || lp.x > -front) { discard; }
	float n = fbm(vec3(lp.x * 2.0, lp.y * 6.0, lp.z * 6.0));
	ALBEDO = color * (0.8 + 0.4 * n);
	METALLIC = metal;
	ROUGHNESS = rough + 0.2 * n;
	EMISSION = color * glow;
}
"""

var _xa: Node3D
var _xa_string: Node3D
var _xa_flight: Node3D
var _xa_mats: Array = []
var _xa_spoil: MultiMesh
var _xa_grit: MultiMesh
var _xa_boulder: MeshInstance3D
var _xa_chunks: Array = []
var _xa_glow: OmniLight3D
var _xa_hand_tools: Node3D
var _xa_hammer: Node3D
var _xa_entry := 0.0
var _xa_collars: Array = []
var _xa_flight_mat: ShaderMaterial
var _xa_girder: Node3D
var _xa_sparks: MultiMesh
var _xa_pieces: Array = []
var _plug_bits: Array = []      # boulders and wreckage on the plug's cut face (cleared off the auger's path)
var _xa_exit := 0.0


func _xa_mat(color: String, metal: float, rough: float, glow: float = 0.0) -> ShaderMaterial:
	var m := _shader(XA_SHADER)
	m.set_shader_parameter("color", Color(color))
	m.set_shader_parameter("metal", metal)
	m.set_shader_parameter("rough", rough)
	m.set_shader_parameter("glow", glow)
	_xa_mats.append(m)
	return m


## A cylinder of radius r along -x from 0 to -AX_LEN (in the string's own frame, so the clip shader cuts it).
func _xa_cyl(st: SurfaceTool, r: float, cy: float, cz: float, sides: int) -> void:
	var x := 0.0
	while x > -AX_LEN:
		var xb := x - 2.0
		for k in sides:
			var a0 := TAU * k / sides
			var a1 := TAU * (k + 1) / sides
			var q := [Vector3(x, cy + cos(a0) * r, cz + sin(a0) * r), Vector3(xb, cy + cos(a0) * r, cz + sin(a0) * r),
				Vector3(x, cy + cos(a1) * r, cz + sin(a1) * r), Vector3(xb, cy + cos(a1) * r, cz + sin(a1) * r)]
			for o in [0, 1, 2, 1, 3, 2]:
				st.add_vertex(q[o])
		x = xb


func _build_xauger(root: Node3D) -> void:
	_xa = Node3D.new()
	_xa.visible = false
	root.add_child(_xa)
	# Where the casing enters and would leave the plug at its height.
	var x := TOE_A
	while x < PLUG_A and _heap_top(x) < AX_Y:
		x += 0.05
	_xa_entry = x
	x = TOE_B
	while x > PLUG_B and _heap_top(x) < AX_Y:
		x -= 0.05
	_xa_exit = x
	_xa_string = Node3D.new()
	_xa.add_child(_xa_string)
	# The back half of the casing (model x from 0 at the nose back to -AX_LEN), open toward the camera.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 20
	var xs := 0.0
	while xs > -AX_LEN:
		var xb := xs - 1.0
		for k in n:
			var a0 := PI * 0.5 + PI * float(k) / n
			var a1 := PI * 0.5 + PI * float(k + 1) / n
			var p := [Vector3(xs, sin(a0) * AX_R, cos(a0) * AX_R), Vector3(xb, sin(a0) * AX_R, cos(a0) * AX_R),
				Vector3(xs, sin(a1) * AX_R, cos(a1) * AX_R), Vector3(xb, sin(a1) * AX_R, cos(a1) * AX_R)]
			for o in [0, 2, 1, 1, 2, 3]:
				st.add_vertex(p[o])
		xs = xb
	st.generate_normals()
	var half := MeshInstance3D.new()
	half.mesh = st.commit()
	half.material_override = _xa_mat("#3a3f44", 0.65, 0.5)
	_xa_string.add_child(half)
	# Bright cut edges along both lips, and weld collars every 6 m of pipe (each a section added at the rig).
	var ls := SurfaceTool.new()
	ls.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sy in [-1.0, 1.0]:
		_xa_cyl(ls, 0.018, sy * AX_R, 0.0, 6)
	ls.generate_normals()
	var lips := MeshInstance3D.new()
	lips.mesh = ls.commit()
	lips.material_override = _xa_mat("#d4d8dc", 0.9, 0.25, 0.15)
	_xa_string.add_child(lips)
	var collar := _xa_mat("#8a8f94", 0.8, 0.35)
	var cx := -1.5
	while cx > -AX_LEN:
		var c := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = AX_R - 0.01
		tm.outer_radius = AX_R + 0.035
		tm.rings = 32
		tm.ring_segments = 6
		c.mesh = tm
		c.material_override = collar
		c.rotation.z = PI * 0.5
		c.position = Vector3(cx, 0, 0)
		_xa_string.add_child(c)
		_xa_collars.append(c)
		cx -= 6.0
	# The cutting shoe: a heavier ring at the nose.
	var shoe := MeshInstance3D.new()
	var sm := TorusMesh.new()
	sm.inner_radius = AX_R - 0.02
	sm.outer_radius = AX_R + 0.06
	sm.rings = 36
	sm.ring_segments = 8
	shoe.mesh = sm
	shoe.material_override = _xa_mat("#b9a77a", 0.85, 0.3)
	shoe.rotation.z = PI * 0.5
	_xa_string.add_child(shoe)
	# The auger: a helical flight round a shaft, along -x from the nose, spinning about x.
	_xa_flight = Node3D.new()
	_xa_string.add_child(_xa_flight)
	var fs := SurfaceTool.new()
	fs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := int(AX_LEN / AX_PITCH * 22.0)
	for i in steps:
		var u0 := float(i) / steps
		var u1 := float(i + 1) / steps
		var b0 := AX_LEN * u0 / AX_PITCH * TAU
		var b1 := AX_LEN * u1 / AX_PITCH * TAU
		var xa := -0.25 - AX_LEN * u0
		var xb2 := -0.25 - AX_LEN * u1
		var q := [Vector3(xa, cos(b0) * 0.1, sin(b0) * 0.1), Vector3(xa, cos(b0) * 0.37, sin(b0) * 0.37),
			Vector3(xb2, cos(b1) * 0.1, sin(b1) * 0.1), Vector3(xb2, cos(b1) * 0.37, sin(b1) * 0.37)]
		for o in [0, 1, 2, 1, 3, 2]:
			fs.add_vertex(q[o])
	fs.generate_normals()
	_xa_cyl(fs, 0.1, 0.0, 0.0, 14)
	var flight := MeshInstance3D.new()
	flight.mesh = fs.commit()
	_xa_flight_mat = _xa_mat("#9aa0a6", 0.85, 0.3)
	flight.material_override = _xa_flight_mat
	# The front of the flight in three pieces, for when it shears (line 14).
	for seg in [[-0.25, -0.7], [-0.7, -1.15], [-1.15, -1.6]]:
		var ps := SurfaceTool.new()
		ps.begin(Mesh.PRIMITIVE_TRIANGLES)
		var x0: float = seg[0]
		var x1: float = seg[1]
		var cxp := (x0 + x1) * 0.5
		var pn := 60
		for i in pn:
			var xa0 := lerpf(x0, x1, float(i) / pn)
			var xa1 := lerpf(x0, x1, float(i + 1) / pn)
			var c0 := (-0.25 - xa0) / AX_PITCH * TAU
			var c1 := (-0.25 - xa1) / AX_PITCH * TAU
			var q := [Vector3(xa0 - cxp, cos(c0) * 0.1, sin(c0) * 0.1), Vector3(xa0 - cxp, cos(c0) * 0.37, sin(c0) * 0.37),
				Vector3(xa1 - cxp, cos(c1) * 0.1, sin(c1) * 0.1), Vector3(xa1 - cxp, cos(c1) * 0.37, sin(c1) * 0.37)]
			for o in [0, 1, 2, 1, 3, 2]:
				ps.add_vertex(q[o])
		ps.generate_normals()
		var piece := MeshInstance3D.new()
		piece.mesh = ps.commit()
		var pm := _mat("#9aa0a6", 0.3, 0.85)
		pm.cull_mode = BaseMaterial3D.CULL_DISABLED
		piece.material_override = pm
		piece.visible = false
		piece.set_meta("cx", cxp)
		_xa_string.add_child(piece)
		_xa_pieces.append(piece)
	# The steel in the rubble: a buried H-section girder from the collapsed ribs, rusty, slanting across the path.
	_xa_girder = Node3D.new()
	_xa_girder.visible = false
	_xa.add_child(_xa_girder)
	var rust := _mat("#5e3320", 0.75, 0.55)
	_box(_xa_girder, Vector3(0.24, 3.2, 0.03), Vector3(0, 0, 0.16), rust)
	_box(_xa_girder, Vector3(0.24, 3.2, 0.03), Vector3(0, 0, -0.16), rust)
	_box(_xa_girder, Vector3(0.03, 3.2, 0.32), Vector3.ZERO, rust)
	_xa_girder.rotation = Vector3(0.0, 0.0, 0.55)
	# Sparks: thin white-hot streaks fanning out of the cut.
	var spark := CapsuleMesh.new()
	spark.radius = 0.006
	spark.height = 0.09
	spark.radial_segments = 4
	spark.rings = 1
	var spark_m := _lit("#ffd28a", 9.0)
	spark_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark.material = spark_m
	_xa_sparks = MultiMesh.new()
	_xa_sparks.transform_format = MultiMesh.TRANSFORM_3D
	_xa_sparks.mesh = spark
	_xa_sparks.instance_count = 140
	var spmi := MultiMeshInstance3D.new()
	spmi.multimesh = _xa_sparks
	spmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_xa.add_child(spmi)
	_xa_flight.add_child(flight)
	# The cutting head: a hub and four arms of carbide teeth, just proud of the shoe.
	var head_m := _xa_mat("#2a2c2e", 0.8, 0.4)
	var tooth_m := _xa_mat("#e3e5e8", 0.95, 0.15, 0.1)
	_rod(_xa_flight, Vector3(-0.3, 0, 0), Vector3(0.12, 0, 0), 0.17, head_m, 12)
	for k in 4:
		var a := k * PI * 0.5
		var arm := _box(_xa_flight, Vector3(0.1, 0.36, 0.07), Vector3(0.08, cos(a) * 0.2, sin(a) * 0.2), head_m)
		arm.rotation.x = -a
		for j in 3:
			var r := 0.14 + j * 0.11
			var tooth := _box(_xa_flight, Vector3(0.09, 0.05, 0.05), Vector3(0.15, cos(a) * r, sin(a) * r), tooth_m)
			tooth.rotation.x = -a
	# Spoil riding back along the flight, and grit spat out at the face.
	var stone := SphereMesh.new()
	stone.radius = 0.5
	stone.height = 1.0
	stone.radial_segments = 6
	stone.rings = 3
	stone.material = _mat("#5e564c", 0.95)
	_xa_spoil = MultiMesh.new()
	_xa_spoil.transform_format = MultiMesh.TRANSFORM_3D
	_xa_spoil.mesh = stone
	_xa_spoil.instance_count = SPOIL
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = _xa_spoil
	_xa.add_child(smi)
	_xa_grit = MultiMesh.new()
	_xa_grit.transform_format = MultiMesh.TRANSFORM_3D
	_xa_grit.mesh = stone
	_xa_grit.instance_count = GRIT
	var gmi := MultiMeshInstance3D.new()
	gmi.multimesh = _xa_grit
	_xa.add_child(gmi)
	# The boulder in the way, bulging out of the cut face, and the chunks it breaks into.
	var rock := _shader(RUBBLE_SHADER)
	_xa_boulder = MeshInstance3D.new()
	_xa_boulder.mesh = _stone_mesh(901, 0.3)
	_xa_boulder.material_override = rock
	_xa.add_child(_xa_boulder)
	for i in 6:
		var ch := MeshInstance3D.new()
		ch.mesh = _stone_mesh(910 + i, 0.4)
		ch.material_override = rock
		ch.visible = false
		_xa.add_child(ch)
		_xa_chunks.append(ch)
	# Hot work-light at the head (the grinding face), off between bites.
	_xa_glow = OmniLight3D.new()
	_xa_glow.light_color = Color("#ffb46a")
	_xa_glow.omni_range = 1.2
	_xa_glow.omni_attenuation = 1.8
	_xa_glow.light_energy = 0.0
	_xa_glow.shadow_enabled = false
	_xa.add_child(_xa_glow)
	# Hand tools are only visible during the manual excavation cutaway.
	_xa_hand_tools = Node3D.new()
	_xa.add_child(_xa_hand_tools)
	var tool_steel := _mat("#a3a7a3", 0.48)
	var handle := _mat("#79563b", 0.85)
	_rod(_xa_hand_tools, Vector3(-0.35, -0.2, -0.46), Vector3(0.03, -0.13, -0.46), 0.025, tool_steel, 8)
	_xa_hammer = Node3D.new()
	_xa_hand_tools.add_child(_xa_hammer)
	_rod(_xa_hammer, Vector3.ZERO, Vector3(0.0, 0.31, 0.0), 0.025, handle, 8)
	_box(_xa_hammer, Vector3(0.22, 0.09, 0.09), Vector3(0.0, 0.32, 0.0), tool_steel)


## Metres bored at t: between consecutive keys it eases in and out (a held value is a stall).
func _xa_metres(keys: Array, t: float) -> Array:
	if keys.is_empty():
		return [0.0, 0.0]
	if t <= float(keys[0][0]):
		return [float(keys[0][1]), 0.0]
	for i in keys.size() - 1:
		var t0 := float(keys[i][0])
		var t1 := float(keys[i + 1][0])
		if t < t1:
			var d0 := float(keys[i][1])
			var d1 := float(keys[i + 1][1])
			var k := Motion.seg(t, t0, t1)
			var moving := 1.0 if absf(d1 - d0) > 0.01 else 0.0
			return [lerpf(d0, d1, Motion.in_out(k)), moving * sin(k * PI)]
	return [float(keys.back()[1]), 0.0]


func _pose_xauger(p: Dictionary, t: float, origin: Vector3, ctx: Dictionary = {}) -> Dictionary:
	if not p.has("xauger"):
		return {}
	var xa: Dictionary = p["xauger"]
	var per := (_xa_exit - _xa_entry) / float(xa.get("metres", 57.0))
	var keys: Array = xa.get("keys", [])
	var md := _xa_metres(keys, t)
	var d: float = md[0]
	var surge: float = md[1]
	var chew := float(xa.get("chew", 1.0e9))
	var nose := _xa_entry + d * per
	# The anchor exists at every time (reveals and cameras riding the nose are checked outside the scene too).
	var res := {"nose": origin + Vector3(nose, AX_Y, AX_Z)}
	_xa.visible = t >= float(xa.get("from", 1.0e9)) and t < float(xa.get("until", 1.0e9))
	for w in xa.get("hide", []):
		if t >= float(w[0]) and t < float(w[1]):
			_xa.visible = false
	# By hand (line 20): the auger and its broken blades are out, the girder cut away; miners lie in the pipe's nose.
	var manual := t >= float(xa.get("manual", 1.0e9))
	_xa_hand_tools.visible = manual and _xa.visible
	_xa_flight.visible = not manual
	for pc in _xa_pieces:
		if manual:
			(pc as Node3D).visible = false
	for ins in xa.get("inside", []):
		var ia = ctx_actor(ctx, String(ins.get("id", "")))
		if ia == null or not manual or not _xa.visible:
			continue
		ia.visible = true
		var back := float(ins.get("back", 1.0))
		var floor_y := origin.y + AX_Y - AX_R + 0.04
		var chest := origin + Vector3(nose - back - 0.93, AX_Y - AX_R + 0.2, AX_Z - 0.05)
		var progress := maxf(0.0, t - float(xa.get("manual", t)))
		Crawl.pose(ia, chest, Vector3.RIGHT, Vector3.UP, progress * 0.12 + back, {"tilt": 0.2, "floor_y": floor_y, "stride": 0.55, "arm_scale": 1.3})
		if back < 0.1:
			var beat := fposmod(progress, 0.7) / 0.7
			var lift := sin(PI * clampf(beat / 0.8, 0.0, 1.0))
			var grip := origin + Vector3(nose - 0.3 - 0.09 * lift, AX_Y - 0.12 + 0.18 * lift, AX_Z - 0.46)
			Crawl.arm(ia, "r", grip, Vector3(0, 0, -1))
			Crawl.arm(ia, "l", origin + Vector3(nose - 0.28, AX_Y - 0.2, AX_Z - 0.46), Vector3(0, 0, -1))
			_xa_hand_tools.position = Vector3(nose, AX_Y, AX_Z)
			_xa_hammer.position = grip - origin - _xa_hand_tools.position
			_xa_hammer.rotation.z = -1.0 + lift * 1.15
	if not manual or not _xa.visible:
		for ins in xa.get("inside", []):
			var ha = ctx_actor(ctx, String(ins.get("id", "")))
			if ha != null and t >= float(xa.get("manual", 1.0e9)):
				ha.visible = false
	for b in _plug_bits:
		(b as Node3D).visible = not (_xa.visible and absf((b as Node3D).position.y - AX_Y) < 2.2)
	if not _xa.visible:
		return res
	# The rig shoves in pulses: a judder on the string while it bites.
	var grind := clampf(surge + (1.0 - Motion.seg(t, chew + 0.45, chew + 0.8)) * Motion.seg(t, chew - 0.1, chew), 0.0, 1.0)
	var steel := Motion.seg(t, float(xa.get("hit", 1.0e9)), float(xa.get("hit", 1.0e9)) + 0.05) * (1.0 - Motion.seg(t, float(xa.get("snap", 1.0e9)), float(xa.get("snap", 1.0e9)) + 0.3))
	grind = maxf(grind, steel)
	var judder := Vector3(0.0, sin(t * 61.0) * 0.012, cos(t * 47.0) * 0.008) * grind
	_xa_string.position = Vector3(nose, AX_Y, AX_Z) + judder
	var keep := maxf(nose - _xa_entry + 0.25, 0.0)
	for m in _xa_mats:
		(m as ShaderMaterial).set_shader_parameter("keep", keep)
	for c in _xa_collars:
		(c as Node3D).visible = (c as Node3D).position.x > -keep
	# The flight turns all the time; once its blades snap it is jammed dead.
	var hit := float(xa.get("hit", 1.0e9))
	var snap := float(xa.get("snap", 1.0e9))
	var spin := minf(t, snap) * 7.0 + d * 3.0 + 4.0 * maxf(minf(t, snap) - hit, 0.0)
	_xa_flight.rotation.x = -spin
	_xa_girder.visible = t >= float(xa.get("girder", 1.0e9)) and not manual
	_xa_girder.position = Vector3(_xa_entry + 47.0 * per + 0.62, AX_Y + 0.05, 0.22)
	# Steel: sparks fan out of the cut from "hit" until the blades go.
	var sparking := Motion.seg(t, hit, hit + 0.05) * (1.0 - Motion.seg(t, snap, snap + 0.25))
	for i in _xa_sparks.instance_count:
		var life := 0.45 + _hash(i * 1.9) * 0.35
		var age := fposmod(t + _hash(i * 4.3) * life, life)
		var born := t - age
		var xf := Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), Vector3(nose, AX_Y, AX_Z))
		if born >= hit and born < snap and sparking > 0.0:
			var a := (_hash(i * 2.7) - 0.5) * 2.4
			var v := Vector3(-0.6 + _hash(i * 6.1) * 2.6, sin(a) * 3.2 + 1.2, 1.6 + _hash(i * 3.7) * 2.8)
			var pos := Vector3(nose + 0.32, AX_Y + (_hash(i * 8.8) - 0.5) * 0.5, AX_Z + 0.25) + v * age + Vector3(0, -6.0 * age * age, 0)
			var vel := v + Vector3(0, -12.0 * age, 0)
			var basis := Basis.looking_at(vel.normalized(), Vector3.UP if absf(vel.normalized().y) < 0.95 else Vector3.RIGHT) * Basis(Vector3.RIGHT, PI * 0.5)
			xf = Transform3D(basis.scaled(Vector3(1.0, 0.6 + vel.length() * 0.25, 1.0) * (1.0 - age / life)), pos)
		_xa_sparks.set_instance_transform(i, xf)
	# Snap: the front of the flight is gone from the spinning auger; its three pieces twist and wedge in the casing,
	# one flies out of the cut.
	var sheared := t >= snap
	_xa_flight_mat.set_shader_parameter("front", 1.6 if sheared else -1000.0)
	for i in _xa_pieces.size():
		var pc := _xa_pieces[i] as MeshInstance3D
		pc.visible = sheared and _xa.visible and not manual
		if not pc.visible:
			continue
		var age := t - snap
		var cxp: float = pc.get_meta("cx")
		var base := Basis(Vector3.RIGHT, -spin)
		if i == 0:
			# Thrown out of the open side toward us, tumbling.
			var v := Vector3(1.2, 1.6, 4.2)
			pc.position = Vector3(cxp, 0, 0) + v * age + Vector3(0, -7.0 * age * age, 0)
			pc.basis = base * Basis(Vector3(0.3, 1.0, 0.4).normalized(), age * 11.0)
		else:
			var k := Motion.out_back(clampf(age / 0.18, 0.0, 1.0), 2.0)
			var twist := Vector3(0.4, 0.8, 0.5).normalized() if i == 1 else Vector3(-0.6, 0.3, 0.7).normalized()
			pc.position = Vector3(cxp + 0.08 * k * (1.0 if i == 1 else -1.0), -0.12 * k, (0.06 if i == 1 else -0.08) * k)
			pc.basis = base * Basis(twist, (0.9 if i == 1 else -1.1) * k)
	# Spoil: chunks walk back along the flight inside the casing, one turn per pitch.
	for i in SPOIL:
		var life := 2.2
		var age := fposmod(t * (1.0 + grind) + _hash(i * 1.7) * life, life)
		var back := age * 1.6
		var ang := spin + _hash(i * 3.1) * TAU
		var r := 0.2 + _hash(i * 5.3) * 0.14
		var pos := Vector3(nose - 0.35 - back, AX_Y + cos(ang) * r * 0.8 - 0.06, AX_Z + sin(ang) * r * 0.5 - 0.12)
		var s := 0.04 + _hash(i * 7.9) * 0.08
		var show := back < keep - 0.4
		_xa_spoil.set_instance_transform(i, Transform3D(Basis.from_euler(Vector3(age * 5.0, i, age * 3.0)).scaled(Vector3.ONE * (s if show else 0.0001)), pos))
	# Grit spat out of the gap at the face while it bites.
	for i in GRIT:
		var life := 0.55
		var age := fposmod(t + _hash(i * 2.9) * life, life)
		var dir := Vector3(-0.4 - _hash(i * 4.1) * 1.2, 0.6 + _hash(i * 6.2) * 1.6, 0.8 + _hash(i * 8.3) * 1.4)
		var pos := Vector3(nose + 0.1, AX_Y + (_hash(i * 9.4) - 0.5) * 0.6, AX_Z + 0.3) + dir * age + Vector3(0, -5.0 * age * age, 0)
		var s := (0.025 + _hash(i * 1.3) * 0.045) * grind
		_xa_grit.set_instance_transform(i, Transform3D(Basis.from_euler(Vector3(age * 9.0, i, 0)).scaled(Vector3.ONE * maxf(s, 0.0001)), pos))
	# The boulder: in the way until "chew", then it splits and the pieces fly out of the face.
	var bx := _xa_entry + float(xa.get("boulder_at", 1.3)) * per + 0.55
	var bc := Vector3(bx, AX_Y + 0.05, 0.12)
	var broken := t >= chew
	_xa_boulder.visible = not broken
	var shiver := Vector3(sin(t * 80.0), cos(t * 67.0), 0.0) * 0.02 * Motion.seg(t, chew - 0.3, chew)
	_xa_boulder.transform = Transform3D(Basis.from_euler(Vector3(0.4, 1.1, 0.2)).scaled(Vector3(0.95, 0.75, 0.7)), bc + shiver)
	for i in _xa_chunks.size():
		var ch := _xa_chunks[i] as MeshInstance3D
		ch.visible = broken
		if broken:
			var age := t - chew
			var a := TAU * i / _xa_chunks.size()
			var v := Vector3(0.6 + _hash(i * 3.3) * 1.2, 1.2 + sin(a) * 1.4, 1.6 + _hash(i * 5.1) * 1.4)
			var pos := bc + Vector3(cos(a) * 0.2, sin(a) * 0.2, 0.0) + v * age + Vector3(0, -7.0 * age * age, 0)
			pos.y = maxf(pos.y, 0.15)
			var s := 0.32 + _hash(i * 7.7) * 0.18
			ch.transform = Transform3D(Basis.from_euler(Vector3(age * 6.0 + i, age * 4.0, i)).scaled(Vector3(s, s * 0.8, s * 0.7)), pos)
	var flick := 0.8 + 0.2 * sin(t * 37.0) + 0.1 * sin(t * 71.0)
	_xa_glow.position = Vector3(nose + 0.25, AX_Y + 0.1, AX_Z + 0.45)
	_xa_glow.light_energy = 1.1 * grind * flick + 2.2 * steel * flick
	return res


# ------------------------------------------------------------------------------ line 16: the vertical drill on the ridge

## params.ridge = {"from", "lever" (the operator throws it), "start" (the rotary head spins), "down0", "down1"
## (it feeds down), "deep" (metres the bit is in by down1), "crew": [actor ids standing on the ridge, placed on the
## surface by this gag], "op" (the operator, his hand on the lever)}: a crawler drill rig with a lattice mast on the
## mountain top over the trapped section, and an x-ray of the borehole on the cut face below it with the planned
## line glowing down to the crown. Anchors: ridge (the rig's base), hole (the top of the x-ray borehole), deep (the
## crown below it).
const RIDGE_X := 76.0
const RIDGE_Z := -1.8
const HOLE_Z := 0.35
const MAST_H := 11.0

var _ridge: Node3D
var _ridge_head: Node3D
var _ridge_spindle: Node3D
var _ridge_rod: MeshInstance3D
var _ridge_lever: Node3D
var _ridge_hole: MeshInstance3D
var _ridge_bit: Node3D
var _ridge_dashes: MultiMesh
var _ridge_mud: MultiMesh
var _ridge_ys := 0.0
var _ridge_ys0 := 0.0


func _build_ridge(root: Node3D) -> void:
	_ridge = Node3D.new()
	_ridge.visible = false
	root.add_child(_ridge)
	_ridge_ys = top(RIDGE_X, RIDGE_Z)
	_ridge_ys0 = top(RIDGE_X, 0.0)
	var base := Vector3(RIDGE_X, _ridge_ys, RIDGE_Z)
	var yellow := _mat("#e0a21c", 0.5, 0.25)
	var dark := _mat("#1d1f21", 0.7, 0.4)
	var steel := _mat("#6a6f74", 0.45, 0.7)
	# A levelled pad of gravel cut into the slope, a ramp of the access road coming up to it.
	_box(_ridge, Vector3(11.0, 0.6, 8.0), base + Vector3(-1.5, -0.25, -0.6), _mat("#6d6458", 0.95))
	var hx := RIDGE_X + 1.85
	# Crawler undercarriage: continuous track shoes, rollers and a heavy revolving deck.
	# A truck chassis made the vertical drilling rig read as a toy crane.
	var track := _mat("#30302d", 0.94)
	var worn := _mat("#77746b", 0.8)
	for side in [-1.0, 1.0]:
		var z: float = RIDGE_Z + side * 1.18
		_box(_ridge, Vector3(5.8, 0.65, 0.72), Vector3(hx - 3.85, _ridge_ys + 0.48, z), track)
		for k in 19:
			_box(_ridge, Vector3(0.11, 0.035, 0.76), Vector3(hx - 6.55 + k * 0.3, _ridge_ys + 0.82, z), worn)
			_box(_ridge, Vector3(0.11, 0.58, 0.035), Vector3(hx - 6.55 + k * 0.3, _ridge_ys + 0.48, z + side * 0.37), worn)
		for k in 7:
			_rod(_ridge, Vector3(hx - 6.25 + k * 0.8, _ridge_ys + 0.42, z + side * 0.37), Vector3(hx - 6.25 + k * 0.8, _ridge_ys + 0.42, z + side * 0.39), 0.23, dark, 16)
	_box(_ridge, Vector3(5.5, 0.35, 2.9), Vector3(hx - 3.85, _ridge_ys + 1.02, RIDGE_Z), dark)
	# Operator's glazed cab, with a protective frame and a roof overhang.
	var cab := Vector3(hx - 5.75, _ridge_ys + 1.85, RIDGE_Z + 0.65)
	_box(_ridge, Vector3(1.55, 1.45, 1.3), cab, yellow)
	_box(_ridge, Vector3(1.36, 0.92, 0.025), cab + Vector3(0, 0.12, 0.665), _mat("#344b50", 0.24))
	_box(_ridge, Vector3(0.025, 0.92, 1.05), cab + Vector3(-0.79, 0.12, 0), _mat("#344b50", 0.24))
	_box(_ridge, Vector3(1.7, 0.12, 1.42), cab + Vector3(0, 0.78, 0), dark)
	_box(_ridge, Vector3(0.07, 0.96, 0.05), cab + Vector3(0, 0.12, 0.69), dark)
	# Outrigger jacks at the four corners take its weight off the tyres.
	for c in [Vector3(-6.4, 0, -1.75), Vector3(-6.4, 0, 1.75), Vector3(-1.3, 0, -1.75), Vector3(-1.3, 0, 1.75)]:
		var at: Vector3 = Vector3(hx, _ridge_ys, RIDGE_Z) + c
		_box(_ridge, Vector3(0.22, 0.95, 0.22), at + Vector3(0, 0.55, 0), yellow)
		_box(_ridge, Vector3(0.6, 0.06, 0.6), at + Vector3(0, 0.08, 0), steel)
		_box(_ridge, Vector3(0.18, 0.18, 1.2), at + Vector3(0, 1.0, -signf(c.z) * 0.55), yellow)
	# On the bed: the hydraulic power pack (louvred, an exhaust) and hoses running to the mast.
	var pack := Vector3(hx - 3.6, _ridge_ys + 1.95, RIDGE_Z)
	_box(_ridge, Vector3(2.2, 1.3, 2.0), pack, yellow)
	for k in 7:
		_box(_ridge, Vector3(0.06, 0.8, 0.02), pack + Vector3(-0.9 + k * 0.28, 0.0, 1.01), dark)
	_rod(_ridge, pack + Vector3(-0.8, 0.65, -0.6), pack + Vector3(-0.8, 1.6, -0.6), 0.07, dark, 8)
	var hose := _mat("#141414", 0.7)
	for k in 3:
		_rod(_ridge, pack + Vector3(1.1, 0.2 - k * 0.15, 0.4 - k * 0.3), Vector3(hx - 0.9, _ridge_ys + 2.4 + k * 0.6, RIDGE_Z + 0.3 - k * 0.25), 0.035, hose, 6)
	# The mast has box-section guide rails and cross bracing, with the rotary carriage
	# travelling on its front face. Keep the drilling axis unchanged for drill_down.
	var mast := Vector3(hx - 0.75, _ridge_ys + 0.1, RIDGE_Z)
	for sz in [-0.32, 0.32]:
		_box(_ridge, Vector3(0.32, MAST_H, 0.22), mast + Vector3(0, MAST_H * 0.5, sz), yellow)
		_box(_ridge, Vector3(0.08, MAST_H, 0.07), mast + Vector3(0.19, MAST_H * 0.5, sz), steel)
	var y := 0.5
	while y < MAST_H:
		_rod(_ridge, mast + Vector3(0, y, -0.32), mast + Vector3(0, y + 0.8, 0.32), 0.03, yellow, 6)
		_rod(_ridge, mast + Vector3(0, y, 0.32), mast + Vector3(0, y, -0.32), 0.03, yellow, 6)
		y += 0.8
	_box(_ridge, Vector3(0.6, 0.4, 0.9), mast + Vector3(0, MAST_H + 0.1, 0), steel)          # crown block
	_box(_ridge, Vector3(1.4, 0.12, 1.6), mast + Vector3(0.4, 0.06, 0), steel)                # mast foot plate
	_rod(_ridge, Vector3(hx - 2.6, _ridge_ys + 1.4, RIDGE_Z + 0.9), mast + Vector3(0, 5.0, 0.3), 0.07, steel, 8)
	_rod(_ridge, Vector3(hx - 2.6, _ridge_ys + 1.4, RIDGE_Z - 0.9), mast + Vector3(0, 5.0, -0.3), 0.07, steel, 8)
	# The driller's console beside the tail, angled to the hole: gauges and the feed lever.
	var console := Vector3(hx - 1.05, _ridge_ys + 0.05, RIDGE_Z + 2.15)
	var cn := Node3D.new()
	cn.position = console
	cn.rotation.y = -PI * 0.5          # side-on to us: its face (gauges, lever) toward the driller, who faces the hole
	_ridge.add_child(cn)
	_box(cn, Vector3(0.7, 1.0, 0.45), Vector3(0, 0.5, 0), steel)
	_box(cn, Vector3(0.75, 0.06, 0.55), Vector3(0, 1.03, 0.04), dark)
	for k in 3:
		var gauge := _rod(cn, Vector3(-0.22 + k * 0.22, 0.85, 0.23), Vector3(-0.22 + k * 0.22, 0.85, 0.25), 0.07, _mat("#e8e6df", 0.4), 12)
		gauge.name = "gauge_%d" % k
	# Drill pipes racked on timber sleepers on the near side of the pad, and a couple of drums.
	var timber := _mat("#6b4a2b", 0.9)
	for sx in [-3.2, 0.2]:
		_box(_ridge, Vector3(0.25, 0.2, 2.0), Vector3(hx + sx - 2.5, _ridge_ys + 0.15, RIDGE_Z + 4.1), timber)
	var pipe_m := _mat("#5d6064", 0.45, 0.7)
	for k in 7:
		var row := 0 if k < 4 else 1
		var col := k if k < 4 else k - 4
		var zz := RIDGE_Z + 3.45 + col * 0.22 + row * 0.11
		var yy := _ridge_ys + 0.33 + row * 0.19
		_rod(_ridge, Vector3(hx - 6.6, yy, zz), Vector3(hx - 0.6, yy, zz), 0.1, pipe_m, 12)
	for k in 2:
		var drum := KitDB.static_node("majadroid_construction/Construction-Materials#Barrel", 0.85)
		drum.position = Vector3(hx - 7.6 + k * 0.95, _ridge_ys + 0.05, RIDGE_Z + 2.6 - k * 0.3)
		_ridge.add_child(drum)
	# The control lever on the console.
	_ridge_lever = Node3D.new()
	_ridge_lever.position = Vector3(0.18, 1.06, 0.12)
	cn.add_child(_ridge_lever)
	_rod(_ridge_lever, Vector3.ZERO, Vector3(0, 0.38, 0), 0.02, steel, 6)
	_box(_ridge_lever, Vector3(0.07, 0.07, 0.07), Vector3(0, 0.4, 0), _mat("#c0392b", 0.4))
	# The rotary head (slides down the mast) and the drill rod under it.
	_ridge_head = Node3D.new()
	_ridge.add_child(_ridge_head)
	_box(_ridge_head, Vector3(0.8, 0.7, 1.0), Vector3(0.3, 0, 0), _mat("#c0392b", 0.5, 0.3))
	_ridge_spindle = Node3D.new()
	_ridge_spindle.position = Vector3(0.75, -0.2, 0)
	_ridge_head.add_child(_ridge_spindle)
	_rod(_ridge_spindle, Vector3.ZERO, Vector3(0, -0.35, 0), 0.16, steel, 14)
	_box(_ridge_spindle, Vector3(0.38, 0.08, 0.08), Vector3(0, -0.22, 0), dark)
	var rm := CylinderMesh.new()
	rm.top_radius = 0.07
	rm.bottom_radius = 0.07
	rm.height = 1.0
	rm.radial_segments = 10
	_ridge_rod = MeshInstance3D.new()
	_ridge_rod.mesh = rm
	_ridge_rod.material_override = _mat("#9aa0a6", 0.3, 0.85)
	_ridge.add_child(_ridge_rod)
	# Casing collar where it goes in, a generator, a work light on the mast.
	_rod(_ridge, base + Vector3(1.85, -0.1, 0), base + Vector3(1.85, 0.45, 0), 0.32, steel, 18)
	_box(_ridge, Vector3(1.8, 1.2, 1.0), base + Vector3(-1.2, 0.3, -3.0), _mat("#2f6b3a", 0.6, 0.3))
	var lamp := SpotLight3D.new()
	lamp.transform = Transform3D(Basis.looking_at(Vector3(-0.2, -1.0, 0.45).normalized()), mast + Vector3(-0.3, 7.5, 0.6))
	lamp.light_color = Color("#ffe2b8")
	lamp.light_energy = 9.0
	lamp.spot_range = 16.0
	lamp.spot_angle = 48.0
	lamp.shadow_enabled = true
	_ridge.add_child(lamp)
	_box(_ridge, Vector3(0.25, 0.2, 0.35), mast + Vector3(-0.3, 7.6, 0.6), _lit("#fff1d6", 8.0))
	# The x-ray: the borehole cut open on the section face, growing as the bit goes in; the bit; the planned line.
	var hm := CylinderMesh.new()
	hm.top_radius = 0.33
	hm.bottom_radius = 0.33
	hm.height = 1.0
	hm.radial_segments = 20
	hm.cap_top = false
	hm.cap_bottom = false
	_ridge_hole = MeshInstance3D.new()
	_ridge_hole.mesh = hm
	var hmat := _mat("#2b2e31", 0.6, 0.5)
	hmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ridge_hole.material_override = hmat
	_ridge.add_child(_ridge_hole)
	_ridge_bit = Node3D.new()
	_ridge.add_child(_ridge_bit)
	for k in 3:
		var a := TAU * k / 3.0
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.13
		cm.height = 0.24
		cone.mesh = cm
		cone.material_override = _mat("#b9a77a", 0.35, 0.85)
		cone.position = Vector3(cos(a) * 0.12, -0.05, sin(a) * 0.12)
		cone.rotation = Vector3(PI + sin(a) * 0.5, 0, -cos(a) * 0.5)
		_ridge_bit.add_child(cone)
	_rod(_ridge_bit, Vector3(0, 0.05, 0), Vector3(0, 3.0, 0), 0.07, _mat("#9aa0a6", 0.3, 0.85), 10)
	var bit_glow := OmniLight3D.new()
	bit_glow.light_color = Color("#ffcf8a")
	bit_glow.light_energy = 1.6
	bit_glow.omni_range = 3.5
	bit_glow.position = Vector3(0, 0.3, 0.6)
	_ridge_bit.add_child(bit_glow)
	var dash := BoxMesh.new()
	dash.size = Vector3(0.08, 1.2, 0.08)
	var dm := _lit("#ffd84a", 3.0)
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dash.material = dm
	_ridge_dashes = MultiMesh.new()
	_ridge_dashes.transform_format = MultiMesh.TRANSFORM_3D
	_ridge_dashes.mesh = dash
	_ridge_dashes.instance_count = 60
	var dmi := MultiMeshInstance3D.new()
	dmi.multimesh = _ridge_dashes
	dmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ridge.add_child(dmi)
	# Mud and chips spat out round the collar.
	var mud := SphereMesh.new()
	mud.radius = 0.5
	mud.height = 1.0
	mud.radial_segments = 6
	mud.rings = 3
	mud.material = _mat("#5b4a3a", 0.95)
	_ridge_mud = MultiMesh.new()
	_ridge_mud.transform_format = MultiMesh.TRANSFORM_3D
	_ridge_mud.mesh = mud
	_ridge_mud.instance_count = 40
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _ridge_mud
	_ridge.add_child(mmi)


func _pose_ridge(p: Dictionary, t: float, ctx: Dictionary, origin: Vector3) -> Dictionary:
	var res := {"ridge": origin + Vector3(RIDGE_X, _ridge_ys, RIDGE_Z), "hole": origin + Vector3(RIDGE_X + 1.85, _ridge_ys0, HOLE_Z),
		"deep": origin + Vector3(RIDGE_X + 1.85, CROWN + 1.0, HOLE_Z)}
	if not p.has("ridge"):
		return res
	var rp: Dictionary = p["ridge"]
	_ridge.visible = t >= float(rp.get("from", 1.0e9))
	# The ridge crew stand on the mountain's surface wherever they are.
	var holder: Node3D = ctx["holder"]
	for id in rp.get("crew", []):
		var a = ctx["actor"].call(String(id)) if ctx.has("actor") else null
		if a == null:
			continue
		a.visible = _ridge.visible
		# They all work on the levelled pad (height is the same in the gag's frame and the world's).
		a.global_position.y = holder.global_position.y + _ridge_ys + 0.05
	if not _ridge.visible:
		return res
	var base := Vector3(RIDGE_X, _ridge_ys, RIDGE_Z)
	var mast := Vector3(RIDGE_X + 1.85 - 0.75, _ridge_ys + 0.1, RIDGE_Z)
	var lever := float(rp.get("lever", 1.0e9))
	var start := float(rp.get("start", 1.0e9))
	var d0 := float(rp.get("down0", 1.0e9))
	var d1 := float(rp.get("down1", 1.0e9))
	var throw := Motion.out_back(Motion.seg(t, lever - 0.05, lever + 0.18), 2.0)
	_ridge_lever.rotation.x = 0.75 * throw
	var op = ctx["actor"].call(String(rp.get("op", ""))) if ctx.has("actor") else null
	if op != null:
		var grip: Vector3 = _ridge_lever.global_transform * Vector3(0, 0.4, 0)
		op.aim_hand("r", grip, Motion.smooth(Motion.seg(t, lever - 0.5, lever - 0.15)), 0.05)
		op.aim_hand("l", op.global_position + (op.global_transform.basis * Vector3(0.25, 0.95, 0.35)), 0.0)
	# The rotary head: spins from "start", feeds down the mast between down0 and down1.
	var feed := Motion.in_out(Motion.seg(t, d0, d1))
	var hy := lerpf(MAST_H - 1.0, 2.0, feed)
	var judder := Vector3(0, sin(t * 53.0), 0) * 0.015 * Motion.seg(t, start, start + 0.1)
	_ridge_head.position = mast + Vector3(0, hy, 0) + judder
	_ridge_spindle.rotation.y = maxf(t - start, 0.0) * 9.0
	var rod_top := mast + Vector3(0.75, hy - 0.55, 0)
	var rod_bot := base + Vector3(1.85, -0.1, 0)
	_ridge_rod.transform = Transform3D(Basis.from_scale(Vector3(1, maxf(rod_top.y - rod_bot.y, 0.01), 1)), (rod_top + rod_bot) * 0.5)
	_ridge_rod.position.x = rod_bot.x
	# The x-ray: drilled depth and the bit at its bottom; the planned line glows down to the crown.
	var depth := float(rp.get("deep", 6.0)) * Motion.in_out(Motion.seg(t, start + 0.2, d1))
	var hx := RIDGE_X + 1.85
	var xray_on := t >= float(rp.get("xray", 0.0))
	_ridge_hole.visible = depth > 0.05 and xray_on
	_ridge_bit.visible = xray_on
	_ridge_hole.transform = Transform3D(Basis.from_scale(Vector3(1, maxf(depth, 0.01), 1)), Vector3(hx, _ridge_ys0 - depth * 0.5, HOLE_Z))
	_ridge_bit.position = Vector3(hx, _ridge_ys0 - depth, HOLE_Z)
	_ridge_bit.rotation.y = maxf(t - start, 0.0) * 9.0
	var line_on := Motion.smooth(Motion.seg(t, start, start + 0.6))
	var span := _ridge_ys0 - depth - (CROWN + 0.5)
	for i in _ridge_dashes.instance_count:
		var u := (float(i) + 0.5) / _ridge_dashes.instance_count
		var yy := _ridge_ys0 - depth - u * span
		var vis := xray_on and line_on > 0.0 and u < line_on * 1.05
		_ridge_dashes.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * (1.0 if vis else 0.0001) * minf(span / _ridge_dashes.instance_count / 1.6, 1.0)), Vector3(hx, yy, HOLE_Z)))
	for i in _ridge_mud.instance_count:
		var life := 0.8
		var age := fposmod(t + _hash(i * 2.1) * life, life)
		var on := t > start + 0.15 and t - age > start
		var dir := Vector3(cos(i * 2.4) * 0.8, 1.2 + _hash(i * 3.3), sin(i * 2.4) * 0.8)
		var pos := base + Vector3(1.85, 0.45, 0) + dir * age * 1.4 + Vector3(0, -4.0 * age * age, 0)
		var s := (0.04 + _hash(i * 5.5) * 0.06) if on else 0.0001
		_ridge_mud.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * s), pos))
	return res


# ------------------------------------------------------------------------------ line 19: into the pipe, one after another

## params.escape = {"from", "until", "crew": [{"id", "t0" (steps up to the mouth), "t1" (goes in head first),
## "t2" (out of sight)}]}: the auger is gone; the 800 mm escape pipe's open end sticks out of the rubble's toe over a
## timber platform, a yellow air duct snaking into it, a work lamp on a stand. The miners queue on the platform and
## crawl in one after another (the gag drives their positions: queue, step up, dive, slide in).
const ESC_X0 := TOE_A - 1.2       # the pipe's open mouth
const ESC_Y := 1.0                # its axis
const ESC_Z := -2.6
const ESC_R := 0.42
const DECK_Y := 0.55

var _esc: Node3D
var _esc_lamp: SpotLight3D
var _rescue_rim: SpotLight3D


func _build_escape(root: Node3D) -> void:
	_esc = Node3D.new()
	_esc.visible = false
	root.add_child(_esc)
	var steel := _mat("#5b5f60", 0.5, 0.65)
	steel.cull_mode = BaseMaterial3D.CULL_DISABLED
	var tube := CylinderMesh.new()
	tube.top_radius = ESC_R
	tube.bottom_radius = ESC_R
	tube.height = 7.0
	tube.radial_segments = 36
	tube.cap_top = false
	tube.cap_bottom = false
	var t := MeshInstance3D.new()
	t.mesh = tube
	t.material_override = steel
	t.rotation.z = PI * 0.5
	t.position = Vector3(ESC_X0 + 3.5, ESC_Y, ESC_Z)
	_esc.add_child(t)
	# The cut, ground-off lip of the mouth, a weld collar, and the dark inside.
	var lip := MeshInstance3D.new()
	var lm := TorusMesh.new()
	lm.inner_radius = ESC_R - 0.02
	lm.outer_radius = ESC_R + 0.03
	lm.rings = 40
	lm.ring_segments = 8
	lip.mesh = lm
	lip.material_override = _mat("#9a9fa3", 0.3, 0.85)
	lip.rotation.z = PI * 0.5
	lip.position = Vector3(ESC_X0, ESC_Y, ESC_Z)
	_esc.add_child(lip)
	var inside := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = ESC_R - 0.01
	dm.bottom_radius = ESC_R - 0.01
	dm.height = 0.01
	inside.mesh = dm
	inside.material_override = _mat("#050505", 0.9)
	inside.rotation.z = PI * 0.5
	inside.position = Vector3(ESC_X0 + 3.0, ESC_Y, ESC_Z)
	_esc.add_child(inside)
	# A timber platform up to the mouth: planks on cribbing, two steps.
	var timber := _mat("#6b4a2b", 0.9)
	for k in 7:
		_box(_esc, Vector3(3.4, 0.06, 0.24), Vector3(ESC_X0 - 1.7, DECK_Y, ESC_Z - 0.78 + k * 0.26), timber)
	for c in [Vector3(-0.2, 0, -0.7), Vector3(-0.2, 0, 0.7), Vector3(-3.1, 0, -0.7), Vector3(-3.1, 0, 0.7), Vector3(-1.6, 0, 0.0)]:
		_box(_esc, Vector3(0.3, DECK_Y - 0.03, 0.3), Vector3(ESC_X0 + c.x, (DECK_Y - 0.03) * 0.5, ESC_Z + c.z), timber)
	for k in 2:
		_box(_esc, Vector3(0.32, 0.06, 1.0), Vector3(ESC_X0 - 3.6 - k * 0.32, DECK_Y * (0.66 - k * 0.33), ESC_Z), timber)
	# The air duct: a ribbed yellow flexible hose from the blower into the mouth, along the pipe's floor.
	var duct := _mat("#e2b21b", 0.6)
	var pts := [Vector3(ESC_X0 - 6.0, 0.25, ESC_Z + 1.9), Vector3(ESC_X0 - 3.8, 0.3, ESC_Z + 1.3), Vector3(ESC_X0 - 1.6, DECK_Y + 0.1, ESC_Z + 0.6),
		Vector3(ESC_X0 - 0.3, ESC_Y - 0.28, ESC_Z + 0.2), Vector3(ESC_X0 + 1.2, ESC_Y - 0.3, ESC_Z + 0.2)]
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		_rod(_esc, a, b, 0.1, duct, 12)
		var n := int(a.distance_to(b) / 0.12)
		for k in n:
			var r := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.095
			tm.outer_radius = 0.112
			tm.rings = 14
			tm.ring_segments = 5
			r.mesh = tm
			r.material_override = duct
			var dir := (b - a).normalized()
			var ref := Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT
			var x := ref.cross(dir).normalized()
			r.transform = Transform3D(Basis(x, dir, x.cross(dir)), a.lerp(b, (k + 0.5) / n))
			_esc.add_child(r)
	_box(_esc, Vector3(1.0, 0.8, 0.8), Vector3(ESC_X0 - 6.5, 0.4, ESC_Z + 2.1), _mat("#2f6b3a", 0.6, 0.3))   # blower
	# A work lamp on a tripod stand, aimed into the mouth.
	var stand := Vector3(ESC_X0 - 2.6, 0.0, ESC_Z - 1.5)
	for k in 3:
		var a := TAU * k / 3.0
		_rod(_esc, stand + Vector3(cos(a) * 0.35, 0, sin(a) * 0.35), stand + Vector3(0, 1.9, 0), 0.02, _mat("#2a2a2a", 0.5, 0.6), 5)
	_box(_esc, Vector3(0.3, 0.22, 0.12), stand + Vector3(0, 2.0, 0.05), _lit("#fff1d6", 6.0))
	var lamp := SpotLight3D.new()
	lamp.transform = Transform3D(Basis.looking_at((Vector3(ESC_X0, ESC_Y, ESC_Z) - (stand + Vector3(0, 2.0, 0))).normalized()), stand + Vector3(0, 2.0, 0.1))
	lamp.light_color = Color("#ffe6c4")
	lamp.light_energy = 5.0
	lamp.spot_range = 9.0
	lamp.spot_angle = 40.0
	lamp.shadow_enabled = true
	_esc.add_child(lamp)
	_esc_lamp = SpotLight3D.new()
	_esc_lamp.light_color = Color("#fff0d6")
	_esc_lamp.light_energy = 4.0
	_esc_lamp.spot_range = 6.0
	_esc_lamp.spot_angle = 28.0
	_esc_lamp.shadow_enabled = true
	_esc_lamp.visible = false
	_esc.add_child(_esc_lamp)
	# Motivated by a work lamp behind the rescue team; used only during extraction.
	_rescue_rim = SpotLight3D.new()
	var rim_at := Vector3(ESC_X0 + 1.1, 2.0, ESC_Z + 0.8)
	var rim_dir := (Vector3(ESC_X0 - 1.7, 0.8, ESC_Z) - rim_at).normalized()
	_rescue_rim.transform = Transform3D(Basis.looking_at(rim_dir), rim_at)
	_rescue_rim.light_color = Color("#ffd3a1")
	_rescue_rim.light_energy = 2.0
	_rescue_rim.spot_range = 7.0
	_rescue_rim.spot_angle = 38.0
	_rescue_rim.visible = false
	_esc.add_child(_rescue_rim)


## Height of the timber platform (and its two steps) under a point, in the gag's frame.
func _deck_y(x: float) -> float:
	if x >= ESC_X0 - 3.45:
		return DECK_Y + 0.03
	return (DECK_Y + 0.03) * clampf((x - (ESC_X0 - 4.15)) / 0.7, 0.0, 1.0)


func _pose_escape(p: Dictionary, t: float, ctx: Dictionary, origin: Vector3) -> void:
	if not p.has("escape"):
		return
	var ep: Dictionary = p["escape"]
	_esc.visible = t >= float(ep.get("from", 1.0e9)) and t < float(ep.get("until", 1.0e9))
	if _esc_lamp != null:
		_esc_lamp.visible = false
	if t >= float(ep.get("until", 1.0e9)):
		return          # the crew are someone else's after this (line 20: in the x-ray pipe)
	var crew: Array = ep.get("crew", [])
	for i in crew.size():
		var c: Dictionary = crew[i]
		var a = ctx["actor"].call(String(c.get("id", ""))) if ctx.has("actor") else null
		if a == null:
			continue
		var t0 := float(c.get("t0", 1.0e9))          # starts going down onto hands and knees
		a.visible = _esc.visible
		if not a.visible:
			continue
		# Walking up and waiting: the route moves him, the platform carries him.
		var here: Vector3 = a.global_position - origin
		if t < t0:
			a.global_position.y = origin.y + _deck_y(here.x)
			continue
		# Down and in: tip forward onto the hands (the chest drops and travels), then crawl, flattening onto the
		# belly as the head ducks under the pipe's rim. Hands and knees stay planted; the body is pulled past them.
		var h: float = a._height_scale * 1.83
		var stride := 0.46 * h
		var k := Motion.in_out(Motion.seg(t, t0, t0 + 0.44))
		var d := Crawl.surge(maxf(t - (t0 + 0.34), 0.0), float(c.get("speed", 0.85)), stride, 0.6)
		var duck := Motion.smooth(Motion.seg(d, 0.0, 0.42))
		var x0 := float(c.get("x", ESC_X0 - 1.3))
		var tilt := lerpf(PI * 0.5, lerpf(0.52, 0.17, duck), k)
		# A small dip of the knees before he goes down (anticipation), eased into the drop.
		var dip := 0.05 * sin(Motion.seg(t, t0, t0 + 0.2) * PI) * (1.0 - k)
		var chest_y := lerpf(DECK_Y + 0.03 + 0.5 * h - dip, lerpf(DECK_Y + 0.4, ESC_Y - ESC_R + 0.26, duck), k)
		var chest_x := x0 + 0.44 * k + d
		var in_pipe := chest_x + 0.2 > ESC_X0
		var info := Crawl.pose(a, origin + Vector3(chest_x, chest_y, ESC_Z), Vector3(1, 0, 0), Vector3.UP, d + float(i) * 0.3 * stride,
			{"stride": stride, "tilt": tilt, "weight": k, "floor_y": origin.y + (ESC_Y - ESC_R if in_pipe else DECK_Y + 0.03),
			"pipe_r": ESC_R if in_pipe else 0.0, "spread": 0.16 * h, "reach": 0.24 * h, "leg_back": 0.24 * h, "leg_spread": 0.11 * h,
			"look": Vector2(0.0, 0.1 * (1.0 - duck))})
		a.visible = chest_x < ESC_X0 + 2.0
		if i == 0 and _esc_lamp != null and a.visible:
			# The leader's headlamp: its beam sweeps down onto the rim and into the bore as he goes in.
			var r: float = a._head_r
			var face: Vector3 = info["face"]
			var hup: Vector3 = info["head_up"]
			_esc_lamp.visible = true
			_esc_lamp.global_transform = Transform3D(Basis.looking_at(face, hup), (info["head"] as Vector3) + face * r * 1.12 + hup * r * 0.62)


func ctx_actor(ctx: Dictionary, id: String):
	return ctx["actor"].call(id) if ctx.has("actor") else null


# ------------------------------------------------------------------------------ line 22: out on wheeled stretchers

## params.stretchers = {"from", "until", "list": [{"who" (the rescued man, lying on it), "t0", "t1" (it slides out of
## the escape pipe onto the platform between these), "puller" (a rescuer hauling its rope)}], "garland"}: shallow steel
## trays on four casters, pulled out of the 800 mm pipe on a rope. Garlands of marigolds are put on the men.
var _stretchers: Array = []


func _stretcher() -> Node3D:
	var n := Node3D.new()
	var steel := _mat("#9aa0a6", 0.35, 0.8)
	var dark := _mat("#202224", 0.6, 0.4)
	# The tray: a flat bed with low sides, about 1.9 m x 0.55 m.
	_box(n, Vector3(1.9, 0.025, 0.55), Vector3(0, 0.1, 0), steel)
	for sz in [-0.27, 0.27]:
		_box(n, Vector3(1.9, 0.06, 0.02), Vector3(0, 0.14, sz), steel)
	for sx in [-0.94, 0.94]:
		_box(n, Vector3(0.02, 0.06, 0.55), Vector3(sx, 0.14, 0), steel)
	# Four casters.
	for c in [Vector2(-0.8, -0.2), Vector2(-0.8, 0.2), Vector2(0.8, -0.2), Vector2(0.8, 0.2)]:
		_rod(n, Vector3(c.x, 0.085, c.y), Vector3(c.x, 0.05, c.y), 0.012, dark, 6)
		var w := _rod(n, Vector3(c.x, 0.04, c.y - 0.015), Vector3(c.x, 0.04, c.y + 0.015), 0.04, dark, 12)
		w.name = "wheel"
	# Thin padded rescue board, cross straps and paired hand grips.
	_box(n, Vector3(1.8, 0.05, 0.49), Vector3(0, 0.145, 0), _mat("#c16a32", 0.86))
	for sx in [-0.35, 0.48]:
		_box(n, Vector3(0.085, 0.012, 0.51), Vector3(sx, 0.178, 0), dark)
	for sz in [-0.2, 0.2]:
		_rod(n, Vector3(-0.9, 0.16, sz), Vector3(-1.12, 0.16, sz), 0.025, steel, 10)
	return n


func _garland() -> Node3D:
	var n := Node3D.new()
	var marigold := _mat("#f29a12", 0.85)
	var red := _mat("#c0261c", 0.8)
	var ball := SphereMesh.new()
	ball.radius = 0.028
	ball.height = 0.05
	ball.radial_segments = 8
	ball.rings = 4
	for i in 40:
		var a := TAU * i / 40.0
		var mi := MeshInstance3D.new()
		mi.mesh = ball
		mi.material_override = red if i % 8 == 0 else marigold
		# A loop that hangs: wide at the neck, a V down the chest.
		mi.position = Vector3(sin(a) * 0.17, -0.12 * (1.0 - cos(a)) * 0.5 - 0.1 * pow(absf(cos(a * 0.5)), 6.0), cos(a) * 0.1)
		n.add_child(mi)
	return n


func _build_stretchers(root: Node3D, p: Dictionary) -> void:
	if not p.has("stretchers"):
		return
	for item in p["stretchers"].get("list", []):
		var st := _stretcher()
		st.visible = false
		root.add_child(st)
		var gl := _garland()
		gl.visible = false
		root.add_child(gl)
		_stretchers.append({"node": st, "garland": gl})


func _pose_stretchers(p: Dictionary, t: float, ctx: Dictionary, origin: Vector3) -> void:
	if not p.has("stretchers"):
		return
	var sp: Dictionary = p["stretchers"]
	var on := t >= float(sp.get("from", 1.0e9)) and t < float(sp.get("until", 1.0e9))
	_rescue_rim.visible = on
	if on:
		_esc.visible = true
	var list: Array = sp.get("list", [])
	for i in mini(list.size(), _stretchers.size()):
		var it: Dictionary = list[i]
		var e: Dictionary = _stretchers[i]
		var st := e["node"] as Node3D
		var gl := e["garland"] as Node3D
		var t0 := float(it.get("t0", 1.0e9))
		var t1 := float(it.get("t1", 1.0e9))
		var who = ctx_actor(ctx, String(it.get("who", "")))
		var vis := on and t >= t0 - 0.05
		st.visible = vis
		gl.visible = false
		if who != null:
			who.visible = vis
		if not vis:
			continue
		# Out of the mouth and along the platform, slowing as the rescuers take it.
		var k := Motion.in_out(Motion.seg(t, t0, t1))
		var x := lerpf(ESC_X0 + 0.7, ESC_X0 - 1.45 - float(it.get("stop_back", 0.0)), k)
		# Then it is wheeled away along the platform, toward the ambulances.
		var away := Motion.in_cubic(Motion.seg(t, t1 + 1.5, t1 + 2.5))
		x -= 5.0 * away
		var y := lerpf(ESC_Y - ESC_R - 0.02, DECK_Y + 0.02, Motion.smooth(Motion.seg(t, t0 + (t1 - t0) * 0.45, t1)))
		var z := ESC_Z + float(it.get("dz", 0.0)) * Motion.smooth(Motion.seg(t, t1, t1 + 0.4))
		st.position = Vector3(x, y, z)
		for w in st.get_children():
			if w.name.begins_with("wheel"):
				(w as Node3D).rotation.y = 0.0
		if who != null:
			# The frozen first frame of get_up already lies on the back; retain its
			# natural pose instead of rotating an upright idle onto the board.
			who.global_transform = Transform3D(Basis(Vector3.UP, PI * 0.5), origin + st.position + Vector3(0.1, 0.19, 0.0))
			var id := String(it.get("who", ""))
			var chest: Vector3 = who.anchor_points()[id + ".chest"]["pos"] - origin
			gl.position = chest + Vector3(0.0, 0.12, 0.0)
			gl.rotation = Vector3(PI * 0.5, 0.0, PI * 0.5)
		var puller = ctx_actor(ctx, String(it.get("puller", "")))
		if puller != null:
			puller.global_position = origin + Vector3(x - 1.08, _deck_y(x - 1.08), z + 0.6)
			puller.aim_hand("l", origin + st.position + Vector3(-1.05, 0.17, -0.2), 1.0)
			puller.aim_hand("r", origin + st.position + Vector3(-1.05, 0.17, 0.2), 1.0)
