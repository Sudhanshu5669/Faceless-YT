extends RefCounted
## The Silkyara portal before dawn: a concrete tunnel mouth cut into a steep Garhwal slope.
##
## Blue hour, 12 Nov 2023 (Diwali morning). Pine forest and dry winter grass on the slopes, a snow
## range catching the first pale light beyond the saddle, mist lying in the Yamuna valley. In the
## yard: a light tower, site cabins with a string of Diwali bulbs, a black water tank, steel ribs and
## pipes, a fire drum the night shift warms its hands at, and the dumper heading in, its beams
## lighting the mouth. Inside the mouth, sodium lamps run away into the mountain.
##
## Local frame: the portal faces +Z (toward the camera). +X is screen right when looking at it. The
## yard is flat at y = 0 (z = 0..75). The bore runs to -Z under the mountain.
## In make_episode.py, S(x, y, z) converts a point here to the "slope" anchor (it negates x).
##
## params:
##   lamps     actor ids whose headlamps throw a real beam (they walk toward the portal)
##   truck     {"t0", "t1", "z0", "z1"}: the dumper rolls from z0 to z1 between scene times t0..t1
## anchors: portal (centre of the mouth), fire, truck

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
"""

## The hillside: dry winter grass and needle litter on the gentle ground, banded rock where it is
## steep, wheel-churned mud and puddles in the yard (COLOR.r), packed gravel on the road (COLOR.g).
const GROUND_SHADER := """
shader_type spatial;
render_mode cull_disabled;
varying vec3 wp;
varying vec3 wn;
void vertex() {
	wp = VERTEX;
	wn = NORMAL;
}
//NOISE
void fragment() {
	float dist = length(VERTEX);
	float near = 1.0 - smoothstep(60.0, 260.0, dist);
	float big = fbm(wp * 0.011);
	float mid = fbm(wp * 0.09);
	float fine = fbm(wp * 0.9) * near;
	float steep = smoothstep(0.62, 0.42, wn.y);
	// Dry grass (tawny) and needle litter (dark olive) in patches.
	vec3 grass = mix(vec3(0.20, 0.155, 0.085), vec3(0.11, 0.105, 0.07), smoothstep(0.35, 0.65, mid));
	vec3 ground = grass * (0.72 + big * 0.5 + fine * 0.3);
	// Rock: grey-brown phyllite in tilted bands.
	float band = fbm(vec3(wp.x * 0.05 + wp.y * 0.06, wp.y * 0.09 - wp.z * 0.04, wp.z * 0.05));
	vec3 rock = vec3(0.15, 0.14, 0.13) * (0.6 + band * 0.55 + mid * 0.35 + fine * 0.2);
	vec3 col = mix(ground, rock, steep);
	float yard = COLOR.r;
	float road = COLOR.g;
	// The yard: grey-brown mud, wheel ruts, standing water.
	float rut = 1.0 - smoothstep(0.15, 0.55, abs(fract(wp.x * 0.33 + mid * 0.6) - 0.5) * 2.0);
	float water = smoothstep(0.55, 0.61, fbm(vec3(wp.x * 0.16, 7.0, wp.z * 0.1)) + rut * 0.05) * yard;
	vec3 mud = vec3(0.12, 0.105, 0.09) * (0.7 + mid * 0.45 + fine * 0.35);
	vec3 gravel = vec3(0.16, 0.15, 0.14) * (0.65 + fine * 0.7 + mid * 0.3);
	col = mix(col, mix(mud, gravel, 0.35), yard);
	col = mix(col, gravel * mix(1.0, 0.7, rut), road * (1.0 - yard));
	col = mix(col, vec3(0.02, 0.022, 0.025), water);
	ALBEDO = col;
	ROUGHNESS = mix(mix(0.96, 0.85, yard + road), 0.06, water);
	SPECULAR = mix(0.25, 0.6, water);
	if (near > 0.0) {
		float e = 0.06;
		float c0 = fbm(wp * 1.7);
		vec3 g = vec3(fbm((wp + vec3(e, 0.0, 0.0)) * 1.7) - c0, fbm((wp + vec3(0.0, e, 0.0)) * 1.7) - c0,
			fbm((wp + vec3(0.0, 0.0, e)) * 1.7) - c0) / e;
		NORMAL = normalize(NORMAL - (VIEW_MATRIX * vec4(g, 0.0)).xyz * 0.05 * near * (1.0 - water));
	}
}
"""

## Cast concrete: shuttering lines, rain stains running down, darker where it meets the ground.
const CONCRETE_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 tint : source_color = vec3(0.52, 0.51, 0.48);
uniform float stain = 1.0;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
//NOISE
void fragment() {
	float base = fbm(wp * 0.7);
	float fine = fbm(wp * 6.0);
	float streak = smoothstep(0.45, 0.8, n3(vec3(wp.x * 2.3, wp.y * 0.08, wp.z * 2.3))) * stain;
	float lines = smoothstep(0.92, 1.0, abs(fract(wp.y / 1.2) - 0.5) * 2.0) * 0.12;
	float foot = 1.0 - smoothstep(0.0, 1.6, wp.y - 0.0);
	vec3 col = tint * (0.7 + base * 0.45 + fine * 0.12 - lines);
	col = mix(col, col * vec3(0.45, 0.43, 0.4), streak * 0.7);
	col *= 1.0 - foot * 0.45;
	ALBEDO = col;
	ROUGHNESS = 0.93;
	float e = 0.03;
	float c0 = fbm(wp * 4.0);
	vec3 g = vec3(fbm((wp + vec3(e, 0.0, 0.0)) * 4.0) - c0, fbm((wp + vec3(0.0, e, 0.0)) * 4.0) - c0,
		fbm((wp + vec3(0.0, 0.0, e)) * 4.0) - c0) / e;
	NORMAL = normalize(NORMAL - (VIEW_MATRIX * vec4(g, 0.0)).xyz * 0.03);
}
"""

## The far range: snow above the tree line, dark rock on the cliffs, a faint cold glow so the
## snow reads against the predawn sky, the very tops just warming.
const SNOW_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform float top = 2400.0;
varying vec3 wp;
varying vec3 wn;
void vertex() {
	wp = VERTEX;
	wn = NORMAL;
}
//NOISE
void fragment() {
	float n = fbm(wp * 0.004);
	float m = fbm(wp * 0.03);
	float line = 620.0 + n * 260.0;
	float flat_ = smoothstep(0.35, 0.7, wn.y + m * 0.25);
	float snow = smoothstep(line, line + 140.0, wp.y) * mix(0.15, 1.0, flat_) * smoothstep(0.25, 0.5, fbm(wp * 0.012));
	vec3 rock = vec3(0.07, 0.075, 0.09) * (0.7 + m * 0.6);
	vec3 white = vec3(0.42, 0.47, 0.6) * (0.75 + m * 0.35);
	ALBEDO = mix(rock, white, snow);
	ROUGHNESS = 0.9;
	float lift = smoothstep(top * 0.55, top, wp.y);
	EMISSION = snow * (vec3(0.03, 0.035, 0.06) + vec3(0.12, 0.065, 0.06) * lift);
}
"""

## Mist: soft drifting sheets that fade where they touch the ground.
const MIST_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec3 tint : source_color = vec3(0.45, 0.5, 0.6);
uniform float alpha = 0.5;
uniform float drift = 0.0;
uniform float fade = 12.0;
uniform float seed = 0.0;
uniform sampler2D depth_tex : hint_depth_texture, filter_linear;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
//NOISE
void fragment() {
	vec2 e = min(UV, 1.0 - UV) * 2.0;
	float edge = smoothstep(0.0, 0.5, e.x) * smoothstep(0.0, 0.6, e.y);
	float n = fbm(vec3(UV.x * 5.0 + drift + seed, UV.y * 2.2, seed * 0.37 + drift * 0.3));
	float body = smoothstep(0.28, 0.75, n);
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 up = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float scene_z = -up.z / up.w;
	float soft = clamp((scene_z + VERTEX.z) / fade, 0.0, 1.0);
	ALBEDO = tint;
	ALPHA = alpha * edge * body * soft;
}
"""

const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const PINES := ["quaternius_nature_mega/Pine_1", "quaternius_nature_mega/Pine_2", "quaternius_nature_mega/Pine_3",
	"quaternius_nature_mega/Pine_4", "quaternius_nature_mega/Pine_5"]
const DUMPER := "majadroid_construction/Trucks#Dumper Truck Red"
const TRUCK_SCALE := 0.82
const TRUCK_YAW := 0.0
const FIRE_AT := Vector3(-6.2, 0.0, 17.5)
const PR := 5.6            # radius of the mouth
const PS := 2.6            # where the arch springs
const HW := 0.7            # front face of the headwall
const LAMP_STEP := 9.0

var _noise: FastNoiseLite
var _ridge: FastNoiseLite
var _cache := {}
var _truck: Node3D
var _truck_wheels: Array = []
var _beacons: Array = []
var _fire_light: OmniLight3D
var _flames: Array = []
var _embers: MultiMesh
var _smoke: MultiMesh
var _mists: Array = []
var _lamps := {}


func build(g: Dictionary) -> Node3D:
	var root := Node3D.new()
	_noise = FastNoiseLite.new()
	_noise.seed = 334
	_noise.frequency = 0.0042
	_noise.fractal_octaves = 6
	_ridge = FastNoiseLite.new()
	_ridge.seed = 81
	_ridge.frequency = 0.0021
	_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_ridge.fractal_octaves = 5
	_build_ground(root)
	_build_range(root)
	_build_portal(root)
	_build_bore(root)
	_build_yard(root)
	_build_tower(root)
	_build_fire(root)
	_build_truck(root)
	_build_forest(root)
	_build_mist(root)
	_build_kitchen(root)
	_build_tv(root)
	_build_miners(root)
	for id in g.get("params", {}).get("lamps", []):
		var spot := SpotLight3D.new()
		spot.light_color = Color("#e9f2ff")
		spot.light_energy = 3.2
		spot.spot_range = 16.0
		spot.spot_angle = 17.0
		spot.spot_attenuation = 0.8
		spot.light_volumetric_fog_energy = 2.2
		root.add_child(spot)
		_lamps[String(id)] = spot
	return root


# ------------------------------------------------------------------------------ helpers

func _shader(code: String) -> Shader:
	if not _cache.has(code):
		var s := Shader.new()
		s.code = code.replace("//NOISE", NOISE_GLSL)
		_cache[code] = s
	return _cache[code]


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


func _concrete(tint: String, stain: float = 1.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(CONCRETE_SHADER)
	m.set_shader_parameter("tint", Color(tint))
	m.set_shader_parameter("stain", stain)
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


func _rod(parent: Node3D, a: Vector3, b: Vector3, r: float, mat: Material, sides: int = 12) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = a.distance_to(b)
	mesh.radial_segments = sides
	mesh.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = Transform3D(_basis_y(b - a), (a + b) * 0.5)
	parent.add_child(mi)
	return mi


func _basis_y(dir: Vector3) -> Basis:
	var y := dir.normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	return Basis(x, y, x.cross(y).normalized())


func _aim(dir: Vector3) -> Basis:
	var d := dir.normalized()
	return Basis.looking_at(d, Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT)


func _hash(n: float) -> float:
	return fposmod(sin(n * 127.1 + 3.7) * 43758.5453, 1.0)


func _seg(t: float, t0: float, t1: float) -> float:
	return clampf((t - t0) / (t1 - t0), 0.0, 1.0)


# ------------------------------------------------------------------------------ the land

func _road_x(z: float) -> float:
	var u := maxf(z - 48.0, 0.0)
	return 6.0 + u * u * 0.0032


## 1 in the flat yard, 0 outside it (soft edge).
func _yard(x: float, z: float) -> float:
	var inx := smoothstep(30.0, 24.0, absf(x - 1.0))
	var inz := smoothstep(-0.5, 0.3, z) * smoothstep(80.0, 68.0, z)
	return inx * inz


func _road(x: float, z: float) -> float:
	if z < 40.0:
		return 0.0
	return smoothstep(7.5, 5.0, absf(x - _road_x(z))) * smoothstep(40.0, 60.0, z)


func _height(x: float, z: float) -> float:
	var back := maxf(-z, 0.0)
	# The massif behind the portal, with a saddle up and to the right where the far range shows.
	var crest := 300.0 + 240.0 * smoothstep(60.0, 560.0, absf(x - 90.0))
	var massif := crest * (1.0 - exp(-back / 330.0)) * (1.0 - 0.75 * smoothstep(750.0, 1400.0, back))
	# The valley: the left wall climbs, the right falls to the river, then the far wall climbs.
	var left := 250.0 * smoothstep(34.0, 330.0, -x)
	var right := -78.0 * smoothstep(30.0, 190.0, x) + 620.0 * smoothstep(320.0, 950.0, x)
	# The ledge the yard sits on keeps going toward the camera and falls away below the road.
	var front := -maxf(z - 90.0, 0.0) * 0.12
	var h := massif + left + right + front
	var wild := smoothstep(20.0, 160.0, Vector2(maxf(absf(x) - 25.0, 0.0), maxf(maxf(-z, z - 75.0), 0.0)).length())
	h += (_noise.get_noise_2d(x, z) * 70.0 + (_ridge.get_noise_2d(x, z) - 0.2) * 90.0 * smoothstep(80.0, 400.0, back)) * wild
	# Yard and road flatten what they cross.
	var y := _yard(x, z)
	h = lerpf(h, _noise.get_noise_2d(x * 9.0, z * 9.0) * 0.12, y)
	var r := _road(x, z)
	h = lerpf(h, -maxf(z - 70.0, 0.0) * 0.07, r * (1.0 - y))
	# Over the bore the hill sits behind the headwall and the wing walls.
	if z < 0.4:
		var cover := 1.0 - smoothstep(14.0, 32.0, absf(x))
		cover *= 1.0 - smoothstep(25.0, 60.0, back)
		h = maxf(h, (11.2 + minf(back, 25.0) * 0.9) * cover)
	return h


## Grid lines: dense around the yard, stretching out toward the horizon.
func _axis(lo: float, hi: float, c0: float, c1: float, fine: float, grow: float, extra: Array) -> PackedFloat32Array:
	var vals: Array = []
	var v := c0
	while v > lo:
		vals.append(v)
		v -= fine + maxf(c0 - v, 0.0) * grow
	v = c0
	while v < hi:
		v += fine + maxf(v - c1, 0.0) * grow
		if v > c0:
			vals.append(v)
	for e in extra:
		vals.append(e)
	vals.sort()
	var out := PackedFloat32Array()
	for k in vals.size():
		if k == 0 or float(vals[k]) - float(vals[k - 1]) > 0.05:
			out.append(vals[k])
	return out


func _build_ground(root: Node3D) -> void:
	var xs := _axis(-2200.0, 2200.0, -70.0, 70.0, 2.0, 0.055, [])
	var zs := _axis(-1800.0, 380.0, -50.0, 110.0, 2.0, 0.055, [HW - 0.1, 0.25])
	var heights := []
	for z in zs:
		var row := PackedFloat32Array()
		for x in xs:
			row.append(_height(x, z))
		heights.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in zs.size() - 1:
		var za := zs[j]
		var zb := zs[j + 1]
		var ra: PackedFloat32Array = heights[j]
		var rb: PackedFloat32Array = heights[j + 1]
		for i in xs.size() - 1:
			var xa := xs[i]
			var xb := xs[i + 1]
			# The slot behind the headwall: leave the mouth open.
			if za >= 0.2 and zb <= HW + 0.01 and absf((xa + xb) * 0.5) < PR + 1.5:
				continue
			var quad := [Vector3(xa, ra[i], za), Vector3(xb, ra[i + 1], za), Vector3(xa, rb[i], zb), Vector3(xb, rb[i + 1], zb)]
			for k in [0, 2, 1, 1, 2, 3]:
				var p: Vector3 = quad[k]
				st.set_color(Color(_yard(p.x, p.z), _road(p.x, p.z), 0.0))
				st.add_vertex(p)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := ShaderMaterial.new()
	m.shader = _shader(GROUND_SHADER)
	mi.material_override = m
	root.add_child(mi)


## The snow range far beyond the saddle (Bandarpunch stands over the upper Yamuna).
func _build_range(root: Node3D) -> void:
	var peaks := [Vector3(-900, 1500, 0), Vector3(-300, 1850, 0), Vector3(380, 2350, 0), Vector3(820, 2050, 0),
		Vector3(1500, 1650, 0), Vector3(2300, 1400, 0), Vector3(-1800, 1250, 0)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := 320
	var nz := 70
	var pts := []
	for j in nz + 1:
		var row := []
		var z := -2350.0 - j * 28.0
		for i in nx + 1:
			var x := -4200.0 + i * (8400.0 / nx)
			var h := 0.0
			for pk in peaks:
				var d := Vector2(x - pk.x, (z + 3050.0) * 1.6)
				h = maxf(h, pk.y * exp(-d.length_squared() / (2.0 * 620.0 * 620.0)))
			h += (_ridge.get_noise_2d(x * 3.0, z * 3.0) - 0.3) * 380.0 * smoothstep(0.0, 600.0, h)
			h += _noise.get_noise_2d(x * 2.0, z * 2.0) * 90.0
			h = maxf(h, 120.0 + _noise.get_noise_2d(x, z) * 80.0)
			row.append(Vector3(x, h, z))
		pts.append(row)
	for j in nz:
		for i in nx:
			var a: Vector3 = pts[j][i]
			var b: Vector3 = pts[j][i + 1]
			var c: Vector3 = pts[j + 1][i]
			var d: Vector3 = pts[j + 1][i + 1]
			for p in [a, c, b, b, c, d]:
				st.add_vertex(p)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := ShaderMaterial.new()
	m.shader = _shader(SNOW_SHADER)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)


# ------------------------------------------------------------------------------ the portal

## The opening's edge, wall foot to wall foot over the arch.
func _mouth(k: int, n: int, r: float) -> Vector2:
	var th := PI - PI * float(k) / n
	return Vector2(cos(th) * r, PS + sin(th) * r)


## A flat slab with the mouth cut out of it, between z0 (front) and z1 (back).
func _headwall(w: float, h: float, z0: float, z1: float, r: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 40
	var inner := [Vector2(-r, 0.0)]
	for k in n + 1:
		inner.append(_mouth(k, n, r))
	inner.append(Vector2(r, 0.0))
	var c := Vector2(0, PS)
	var outer := []
	for p in inner:
		var d: Vector2 = (p - c)
		if p.y <= 0.01:
			outer.append(Vector2(signf(p.x) * w * 0.5, 0.0))
			continue
		var s := minf((w * 0.5) / maxf(absf(d.x), 1e-4), (h - PS) / maxf(d.y, 1e-4)) if d.y > 0.0 else (w * 0.5) / maxf(absf(d.x), 1e-4)
		outer.append(c + d * s)
	for k in inner.size() - 1:
		var a: Vector2 = inner[k]
		var b: Vector2 = inner[k + 1]
		var oa: Vector2 = outer[k]
		var ob: Vector2 = outer[k + 1]
		for z in [z0, z1]:
			var fa := Vector3(a.x, a.y, z)
			var fb := Vector3(b.x, b.y, z)
			var foa := Vector3(oa.x, oa.y, z)
			var fob := Vector3(ob.x, ob.y, z)
			if z == z0:
				for p in [fa, foa, fb, fb, foa, fob]:
					st.add_vertex(p)
			else:
				for p in [fa, fb, foa, fb, fob, foa]:
					st.add_vertex(p)
	# The top corners the rays skip.
	for sx in [-1.0, 1.0]:
		var q := [Vector3(sx * w * 0.5, h, z0), Vector3(0, h, z0), Vector3(sx * w * 0.5, PS, z0)]
		if sx < 0.0:
			q = [q[0], q[1], q[2]]
		else:
			q = [q[0], q[2], q[1]]
		for p in q:
			st.add_vertex(p)
	# Top and sides.
	for quad in [[Vector3(-w * 0.5, h, z0), Vector3(w * 0.5, h, z0), Vector3(-w * 0.5, h, z1), Vector3(w * 0.5, h, z1)],
			[Vector3(-w * 0.5, 0, z0), Vector3(-w * 0.5, h, z0), Vector3(-w * 0.5, 0, z1), Vector3(-w * 0.5, h, z1)],
			[Vector3(w * 0.5, h, z0), Vector3(w * 0.5, 0, z0), Vector3(w * 0.5, h, z1), Vector3(w * 0.5, 0, z1)]]:
		for k in [0, 2, 1, 1, 2, 3]:
			st.add_vertex(quad[k])
	st.generate_normals()
	return st.commit()


## The canopy's front edge: a flat horseshoe band between radius r0 and r1 at z.
func _ring(r0: float, r1: float, z: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 40
	var a := [Vector2(-r0, 0.0)]
	var b := [Vector2(-r1, 0.0)]
	for k in n + 1:
		a.append(_mouth(k, n, r0))
		b.append(_mouth(k, n, r1))
	a.append(Vector2(r0, 0.0))
	b.append(Vector2(r1, 0.0))
	for k in a.size() - 1:
		var q := [Vector3(a[k].x, a[k].y, z), Vector3(b[k].x, b[k].y, z), Vector3(a[k + 1].x, a[k + 1].y, z), Vector3(b[k + 1].x, b[k + 1].y, z)]
		for o in [0, 1, 2, 2, 1, 3]:
			st.add_vertex(q[o])
	st.generate_normals()
	return st.commit()


## The inside of the bore (and the canopy's outer shell when outside = true).
func _tube(z0: float, z1: float, r: float, outside: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 40
	var ring := [Vector2(-r, 0.0)]
	for k in n + 1:
		ring.append(_mouth(k, n, r))
	ring.append(Vector2(r, 0.0))
	var rows := int(ceil(absf(z1 - z0) / 2.0))
	for j in rows:
		var za := lerpf(z0, z1, float(j) / rows)
		var zb := lerpf(z0, z1, float(j + 1) / rows)
		for k in ring.size() - 1:
			var a: Vector2 = ring[k]
			var b: Vector2 = ring[k + 1]
			var q := [Vector3(a.x, a.y, za), Vector3(b.x, b.y, za), Vector3(a.x, a.y, zb), Vector3(b.x, b.y, zb)]
			var order := [0, 1, 2, 1, 3, 2] if outside else [0, 2, 1, 1, 2, 3]
			for o in order:
				st.add_vertex(q[o])
	st.generate_normals()
	return st.commit()


func _build_portal(root: Node3D) -> void:
	var face := _concrete("#77746d", 1.0)
	var old := _concrete("#4f4d49", 1.6)
	var wall := MeshInstance3D.new()
	wall.mesh = _headwall(25.0, 10.8, HW, HW - 4.0, PR + 0.75)
	wall.material_override = old
	root.add_child(wall)
	# The canopy: a cast arch standing proud of the headwall.
	var shell := MeshInstance3D.new()
	shell.mesh = _tube(HW + 5.2, HW - 0.5, PR + 0.75, true)
	shell.material_override = face
	root.add_child(shell)
	var lip := MeshInstance3D.new()
	lip.mesh = _ring(PR, PR + 0.75, HW + 5.2)
	lip.material_override = face
	root.add_child(lip)
	# Parapet and drain along the top of the headwall, and the wing walls holding the cut slope.
	_box(root, Vector3(25.4, 0.35, 0.6), Vector3(0, 10.9, HW - 0.2), old)
	for sx in [-1.0, 1.0]:
		var wing := _box(root, Vector3(13.0, 9.0, 0.8), Vector3(sx * 20.5, 3.2, HW - 0.5), old)
		wing.rotation = Vector3(0, -sx * 0.22, sx * 0.42)
		_box(root, Vector3(1.0, 0.5, 4.2), Vector3(sx * (PR + 2.0), 0.25, HW + 2.6), face)
	# Edge warning stripes on the canopy foot (painted, worn).
	var yellow := _mat("#b8901e", 0.8)
	var black := _mat("#141414", 0.8)
	for sx in [-1.0, 1.0]:
		for k in 6:
			_box(root, Vector3(0.04, 0.32, 0.6), Vector3(sx * (PR + 0.78), 0.2 + k * 0.42, HW + 5.0), yellow if k % 2 == 0 else black)


## Inside the mouth: the lining, a roadway, lamps running away into the mountain, the duct.
func _build_bore(root: Node3D) -> void:
	var lining := MeshInstance3D.new()
	lining.mesh = _tube(HW + 5.0, -140.0, PR, false)
	lining.material_override = _concrete("#6f6b63", 1.6)
	root.add_child(lining)
	var floor_mat := _mat("#151311", 0.55)
	_box(root, Vector3(PR * 2.0, 0.1, 146.0), Vector3(0, -0.04, HW + 5.0 - 73.0), floor_mat)
	# The far end is black: the mountain swallows the light.
	_box(root, Vector3(PR * 2.0, PR + PS, 0.2), Vector3(0, (PR + PS) * 0.5, -139.5), _mat("#000000", 1.0))
	var z := HW - 4.0
	var k := 0
	while z > -130.0:
		var sx := 1.0 if k % 2 == 0 else -1.0
		var at := Vector3(sx * (PR - 0.25), 3.6, z)
		_box(root, Vector3(0.12, 0.26, 0.6), at, _lit("#ffb25e", 7.0))
		if k < 6:
			var lamp := OmniLight3D.new()
			lamp.position = at - Vector3(sx * 0.7, 0.2, 0)
			lamp.light_color = Color("#ffae5c")
			lamp.light_energy = 2.6
			lamp.omni_range = 11.0
			lamp.omni_attenuation = 1.2
			lamp.light_volumetric_fog_energy = 1.4
			root.add_child(lamp)
		z -= LAMP_STEP * 0.5
		k += 1
	# Ventilation duct: hangs from the crown, comes out of the mouth and drops to the fan.
	var duct := _mat("#d68a1d", 0.7)
	var cx := -2.4
	var cy := PS + PR - 1.1
	_rod(root, Vector3(cx, cy, -130.0), Vector3(cx, cy, HW - 3.0), 0.62, duct, 18)
	var fan := _rod(root, Vector3(cx, cy, HW - 3.0), Vector3(cx, cy, HW - 0.4), 0.9, _mat("#3d4146", 0.5, 0.6), 22)
	fan.name = "fan"
	_rod(root, Vector3(cx, cy + 0.9, HW - 1.7), Vector3(cx, PS + PR, HW - 1.7), 0.05, _mat("#2a2c2e", 0.6, 0.6), 6)
	for z2 in range(-128, int(HW - 3), 4):
		_rod(root, Vector3(cx, cy + 0.62, z2), Vector3(cx, cy + 0.66, z2 + 0.08), 0.65, _mat("#1e1f21", 0.6), 18)
	# Water main and cables down the -X wall.
	_rod(root, Vector3(-PR + 0.35, 0.6, -130.0), Vector3(-PR + 0.35, 0.6, HW + 6.0), 0.15, _mat("#3b4148", 0.45, 0.6), 10)
	_rod(root, Vector3(PR - 0.3, 2.4, -130.0), Vector3(PR - 0.3, 2.4, HW + 4.5), 0.05, _mat("#111111", 0.6), 6)


# ------------------------------------------------------------------------------ the yard

func _build_yard(root: Node3D) -> void:
	# Site cabins on the right, end on to the portal; lit windows; Diwali bulbs along the eaves.
	var shell := _mat("#2f5f8f", 0.55, 0.35)
	var white := _mat("#c9c7c0", 0.6, 0.2)
	var frame := _mat("#1a1b1d", 0.6, 0.5)
	var window := _lit("#ffcf8a", 2.4)
	for c in [[Vector3(17.5, 0, 10.0), 0.0], [Vector3(17.5, 0, 17.0), 0.0], [Vector3(17.5, 2.75, 13.5), 0.0]]:
		var at: Vector3 = c[0]
		var cab := Node3D.new()
		cab.position = at
		root.add_child(cab)
		_box(cab, Vector3(2.5, 2.6, 6.0), Vector3(0, 1.4, 0), shell if at.y == 0.0 else white)
		for k in 8:
			_box(cab, Vector3(0.06, 2.5, 0.08), Vector3(-1.27, 1.4, -2.7 + k * 0.78), frame)
		_box(cab, Vector3(2.6, 0.12, 6.1), Vector3(0, 2.76, 0), frame)
		_box(cab, Vector3(0.05, 0.9, 1.3), Vector3(-1.28, 1.6, -1.2), window)
		_box(cab, Vector3(0.05, 0.9, 1.3), Vector3(-1.28, 1.6, 1.4), window if at.z < 15.0 else _mat("#111418", 0.1, 0.4))
		_box(cab, Vector3(0.05, 2.0, 0.9), Vector3(-1.28, 1.15, 0.2), _mat("#3c3f43", 0.6, 0.4))
		if at.y == 0.0:
			_box(cab, Vector3(0.9, 0.18, 1.2), Vector3(-1.75, 0.09, 0.2), _concrete("#6b6862", 0.3))
	var glow := OmniLight3D.new()
	glow.position = Vector3(15.6, 1.8, 9.0)
	glow.light_color = Color("#ffc27a")
	glow.light_energy = 1.4
	glow.omni_range = 5.5
	root.add_child(glow)
	# A string of Diwali bulbs sagging along the upper cabin's eave.
	var bulb_cols := ["#ffcf6a", "#ff7a3a", "#ffe9a8", "#ff4f6a", "#ffcf6a", "#7fd0ff"]
	for k in 26:
		var u := float(k) / 25.0
		var p := Vector3(16.2, 5.5 - sin(fposmod(u * 3.0, 1.0) * PI) * 0.35, 10.6 + u * 5.8)
		var b := _box(root, Vector3(0.07, 0.09, 0.07), p, _lit(bulb_cols[k % bulb_cols.size()], 9.0))
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The black water tank on its stand, the generator, the stacks.
	var tank := _rod(root, Vector3(22.0, 3.0, 21.5), Vector3(22.0, 5.0, 21.5), 1.1, _mat("#101112", 0.45), 24)
	tank.name = "tank"
	for sx in [-0.8, 0.8]:
		for sz in [-0.8, 0.8]:
			_rod(root, Vector3(22.0 + sx, 0, 21.5 + sz), Vector3(22.0 + sx, 3.0, 21.5 + sz), 0.06, frame, 6)
	_box(root, Vector3(2.6, 0.12, 2.6), Vector3(22.0, 3.0, 21.5), frame)
	_box(root, Vector3(1.6, 1.6, 3.4), Vector3(11.2, 0.8, 4.2), _mat("#3e6d43", 0.6, 0.3))     # DG set
	_box(root, Vector3(1.62, 0.3, 0.6), Vector3(11.2, 1.75, 3.0), frame)
	# Arched steel ribs waiting on dunnage, left of the mouth.
	var steel := _mat("#4a4440", 0.55, 0.6)
	for k in 5:
		var rib := Node3D.new()
		rib.position = Vector3(-14.5, 0.3 + k * 0.24, 9.0)
		rib.rotation = Vector3(-PI * 0.5, 0.0, 0.25)
		root.add_child(rib)
		for s in 10:
			var a0 := PI * 0.5 + (s - 5) * 0.12
			var a1 := a0 + 0.12
			_rod(rib, Vector3(cos(a0) * 5.0, sin(a0) * 5.0 - 5.0, 0), Vector3(cos(a1) * 5.0, sin(a1) * 5.0 - 5.0, 0), 0.11, steel, 6)
	for k in 7:
		_rod(root, Vector3(-11.0 + (k % 4) * 0.85, 0.42 + floorf(k / 4.0) * 0.74, 27.0), Vector3(-11.0 + (k % 4) * 0.85, 0.42 + floorf(k / 4.0) * 0.74, 33.0), 0.4, _mat("#4f5458", 0.5, 0.65), 18)
	for k in 4:
		_box(root, Vector3(1.1, 0.2, 7.0), Vector3(-10.0, 0.1, 27.0 + k * 0.1 + 3.0), _mat("#2b231c", 0.9))
	# Cement bags under a tarp, and the spoil heap.
	var tarp := _box(root, Vector3(3.2, 1.3, 2.4), Vector3(-17.0, 0.65, 18.5), _mat("#2c4d78", 0.75))
	tarp.rotation.y = 0.3
	var heap := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 1.0
	heap.mesh = sm
	heap.material_override = _mat("#2d2722", 0.98)
	heap.transform = Transform3D(Basis.from_scale(Vector3(7.0, 3.6, 5.0)), Vector3(-21.0, -0.4, 4.5))
	root.add_child(heap)
	# Aggregate heap, a parked shift jeep, precast drain sections by the road.
	var agg := MeshInstance3D.new()
	agg.mesh = sm
	agg.material_override = _mat("#575049", 0.98)
	agg.transform = Transform3D(Basis.from_scale(Vector3(5.0, 2.4, 4.0)), Vector3(16.0, -0.3, 36.0))
	root.add_child(agg)
	var jeep := Node3D.new()
	jeep.position = Vector3(12.5, 0, 46.0)
	jeep.rotation.y = 0.35
	root.add_child(jeep)
	var paint := _mat("#d8d6cf", 0.45, 0.2)
	_box(jeep, Vector3(1.75, 0.8, 4.1), Vector3(0, 0.85, 0), paint)
	_box(jeep, Vector3(1.65, 0.75, 2.3), Vector3(0, 1.6, -0.45), paint)
	_box(jeep, Vector3(1.6, 0.6, 0.05), Vector3(0, 1.62, 0.72), _mat("#1b2329", 0.05, 0.7)).rotation.x = -0.25
	for sx in [-1.0, 1.0]:
		_box(jeep, Vector3(0.05, 0.5, 2.0), Vector3(sx * 0.84, 1.65, -0.45), _mat("#1b2329", 0.05, 0.7))
		for zz in [1.3, -1.3]:
			_rod(jeep, Vector3(sx * 0.7, 0.38, zz), Vector3(sx * 0.95, 0.38, zz), 0.38, _mat("#121212", 0.9), 16)
	for k in 4:
		_rod(root, Vector3(-15.0 + k * 1.3, 0.55, 40.0 + (k % 2) * 0.4), Vector3(-15.0 + k * 1.3, 0.55, 41.6 + (k % 2) * 0.4), 0.55, _concrete("#77746d", 0.6), 20)
	# Cones and the barrier at the mouth.
	var cone := _mat("#d4561c", 0.6)
	var band := _mat("#d8d8d0", 0.4)
	for p in [Vector3(-4.8, 0, 9.5), Vector3(-3.0, 0, 11.0), Vector3(4.9, 0, 9.0), Vector3(6.5, 0, 12.5), Vector3(3.0, 0, 30.0)]:
		var c := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.04
		cm.bottom_radius = 0.2
		cm.height = 0.72
		cm.radial_segments = 12
		c.mesh = cm
		c.material_override = cone
		c.position = p + Vector3(0, 0.36, 0)
		root.add_child(c)
		_rod(root, p + Vector3(0, 0.36, 0), p + Vector3(0, 0.48, 0), 0.115, band, 12)


## A towable light tower: four metal-halide heads on a mast, cold white over the yard.
func _build_tower(root: Node3D) -> void:
	var base := Vector3(-11.5, 0, 22.0)
	var frame := _mat("#c9a224", 0.6, 0.3)
	_box(root, Vector3(1.5, 1.3, 2.6), base + Vector3(0, 1.0, 0), frame)
	for sz in [-1.0, 1.0]:
		_rod(root, base + Vector3(-0.8, 0.4, sz * 0.9), base + Vector3(0.8, 0.4, sz * 0.9), 0.36, _mat("#101010", 0.9), 14)
	var top := base + Vector3(0, 9.0, 0)
	_rod(root, base + Vector3(0, 1.6, 0), top, 0.09, _mat("#8c8c88", 0.4, 0.7), 8)
	_box(root, Vector3(2.0, 0.12, 0.12), top, frame)
	var head := _lit("#eef4ff", 16.0)
	var target := Vector3(1.0, 0.0, 6.0)
	for k in 4:
		var hp := top + Vector3(-0.75 + k * 0.5, 0.35 if k % 2 == 0 else -0.1, 0)
		var lamp := _box(root, Vector3(0.42, 0.42, 0.16), hp, head)
		lamp.basis = _aim(target - hp)
		lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in 2:
		var spot := SpotLight3D.new()
		var at := top + Vector3(-0.5 + k, 0.2, 0.2)
		spot.transform = Transform3D(_aim((target + Vector3(-5.0 + k * 10.0, 0, k * 4.0)) - at), at)
		spot.light_color = Color("#dfe9ff")
		spot.light_energy = 7.0
		spot.spot_range = 60.0
		spot.spot_angle = 38.0
		spot.spot_attenuation = 0.6
		spot.shadow_enabled = true
		spot.light_volumetric_fog_energy = 1.3
		root.add_child(spot)


	var up := SpotLight3D.new()
	var from := top + Vector3(0.3, 0.4, 0)
	up.transform = Transform3D(_aim(Vector3(2.0, 26.0, -14.0) - from), from)
	up.light_color = Color("#d9e4ff")
	up.light_energy = 9.0
	up.spot_range = 80.0
	up.spot_angle = 30.0
	up.spot_attenuation = 0.9
	up.light_volumetric_fog_energy = 1.0
	root.add_child(up)


## The fire drum the night shift stands around.
func _build_fire(root: Node3D) -> void:
	var drum := _rod(root, FIRE_AT, FIRE_AT + Vector3(0, 0.9, 0), 0.3, _mat("#3a2418", 0.9, 0.4), 18)
	drum.name = "drum"
	for k in 3:
		_rod(root, FIRE_AT + Vector3(0, 0.2 + k * 0.3, 0), FIRE_AT + Vector3(0, 0.24 + k * 0.3, 0), 0.31, _mat("#22150f", 0.8, 0.5), 18)
	# A soft tongue of flame: hot yellow core, orange edge, fading to nothing.
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.92, 0.6, 1.0))
	grad.set_color(1, Color(1.0, 0.25, 0.02, 0.0))
	grad.add_point(0.45, Color(1.0, 0.55, 0.12, 0.75))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.78)
	tex.fill_to = Vector2(0.5, 0.3)
	tex.width = 64
	tex.height = 128
	var flame_mat := StandardMaterial3D.new()
	flame_mat.albedo_texture = tex
	flame_mat.albedo_color = Color(1.6, 1.3, 1.0, 1.0)
	flame_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	flame_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for k in 5:
		var q := QuadMesh.new()
		q.size = Vector2(0.5, 0.95)
		var f := MeshInstance3D.new()
		f.mesh = q
		f.material_override = flame_mat
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(f)
		_flames.append(f)
	_fire_light = OmniLight3D.new()
	_fire_light.position = FIRE_AT + Vector3(0, 1.4, 0)
	_fire_light.light_color = Color("#ff8c3a")
	_fire_light.light_energy = 3.0
	_fire_light.omni_range = 9.0
	_fire_light.omni_attenuation = 1.3
	_fire_light.shadow_enabled = true
	_fire_light.light_volumetric_fog_energy = 0.8
	root.add_child(_fire_light)
	var ember := QuadMesh.new()
	ember.size = Vector2(0.03, 0.03)
	var em := _lit("#ffb050", 14.0)
	em.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ember.material = em
	_embers = MultiMesh.new()
	_embers.transform_format = MultiMesh.TRANSFORM_3D
	_embers.mesh = ember
	_embers.instance_count = 40
	var emi := MultiMeshInstance3D.new()
	emi.multimesh = _embers
	emi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(emi)
	var puff := SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	puff.radial_segments = 10
	puff.rings = 6
	var sm := _mat("#3b3a3c", 1.0)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_color = Color(0.23, 0.23, 0.25, 0.16)
	puff.material = sm
	_smoke = MultiMesh.new()
	_smoke.transform_format = MultiMesh.TRANSFORM_3D
	_smoke.mesh = puff
	_smoke.instance_count = 14
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = _smoke
	smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(smi)


## The dumper (same machine that crawls into the bore in the next shot).
func _build_truck(root: Node3D) -> void:
	_truck = Node3D.new()
	_truck.name = "dumper"
	root.add_child(_truck)
	# Majadroid's dumper (CC0): a cab-over tipper. Its cab faces local +Z here.
	var body := KitDB.static_node(DUMPER, TRUCK_SCALE)
	body.rotation.y = TRUCK_YAW
	_truck.add_child(body)
	var beam := _lit("#fff2d6", 14.0)
	var red := _lit("#ff2a1a", 6.0)
	for sx in [-1.0, 1.0]:
		_box(_truck, Vector3(0.3, 0.16, 0.05), Vector3(sx * 0.85, 0.95, 2.9), beam).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_box(_truck, Vector3(0.24, 0.16, 0.05), Vector3(sx * 1.05, 0.9, -2.92), red).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var spot := SpotLight3D.new()
		spot.transform = Transform3D(_aim(Vector3(sx * 0.04, -0.05, 1.0)), Vector3(sx * 0.85, 0.95, 3.0))
		spot.light_color = Color("#fff0d0")
		spot.light_energy = 12.0
		spot.spot_range = 40.0
		spot.spot_angle = 22.0
		spot.spot_attenuation = 0.7
		spot.shadow_enabled = sx < 0.0
		spot.light_volumetric_fog_energy = 2.4
		_truck.add_child(spot)
	var tail_glow := OmniLight3D.new()
	tail_glow.position = Vector3(0, 1.0, -3.3)
	tail_glow.light_color = Color("#ff2a1a")
	tail_glow.light_energy = 0.8
	tail_glow.omni_range = 4.0
	_truck.add_child(tail_glow)
	_beacon(_truck, Vector3(0, 2.62, 2.0))


func _beacon(parent: Node3D, at: Vector3) -> void:
	var mat := _lit("#ff9a1f", 5.0)
	_rod(parent, at, at + Vector3(0, 0.16, 0), 0.085, mat, 10).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pivot := Node3D.new()
	pivot.position = at + Vector3(0, 0.1, 0)
	parent.add_child(pivot)
	var spot := SpotLight3D.new()
	spot.rotation.x = -0.12
	spot.light_color = Color("#ff9416")
	spot.light_energy = 6.0
	spot.spot_range = 16.0
	spot.spot_angle = 40.0
	spot.light_volumetric_fog_energy = 2.4
	pivot.add_child(spot)
	_beacons.append({"pivot": pivot, "light": spot, "mat": mat})


# ------------------------------------------------------------------------------ the forest

## A Himalayan conifer (chir pine / deodar silhouette): a trunk and drooping, ragged tiers.
func _conifer() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nz := FastNoiseLite.new()
	nz.seed = 9
	nz.frequency = 2.3
	var bark := Color("#1d1611")
	for k in 6:
		var a0 := TAU * k / 6.0
		var a1 := TAU * (k + 1) / 6.0
		var b0 := Vector3(cos(a0) * 0.022, 0, sin(a0) * 0.022)
		var b1 := Vector3(cos(a1) * 0.022, 0, sin(a1) * 0.022)
		for p in [b0, b0 * 0.3 + Vector3(0, 0.6, 0), b1, b1, b0 * 0.3 + Vector3(0, 0.6, 0), b1 * 0.3 + Vector3(0, 0.6, 0)]:
			st.set_color(bark)
			st.add_vertex(p)
	var tiers := 7
	for t in tiers:
		var u := float(t) / tiers
		var top := 0.2 + u * 0.72 + 0.08
		var bottom := top - 0.2 + u * 0.05
		var r := (0.3 - u * 0.25) * (1.0 + 0.12 * sin(t * 2.7))
		var seg := 11
		for k in seg:
			var a0 := TAU * k / seg + t * 0.7
			var a1 := TAU * (k + 1) / seg + t * 0.7
			var j0 := 1.0 + nz.get_noise_2d(a0 * 3.0, t * 5.0) * 0.35
			var j1 := 1.0 + nz.get_noise_2d(a1 * 3.0, t * 5.0) * 0.35
			if k == seg - 1:
				j1 = 1.0 + nz.get_noise_2d(t * 0.7 * 3.0 + TAU * 3.0, t * 5.0) * 0.35
			var tip := Vector3(0, top, 0)
			var e0 := Vector3(cos(a0) * r * j0, bottom - (j0 - 1.0) * 0.06, sin(a0) * r * j0)
			var e1 := Vector3(cos(a1) * r * j1, bottom - (j1 - 1.0) * 0.06, sin(a1) * r * j1)
			var under := Vector3(0, bottom + 0.06, 0)
			var lit := Color("#2b3a2c").lerp(Color("#3d4a33"), 0.5 + nz.get_noise_2d(k * 3.0, t * 7.0) * 0.5)
			var dark := Color("#0e140f")
			st.set_color(lit)
			st.add_vertex(tip)
			st.set_color(lit.darkened(0.25))
			st.add_vertex(e1)
			st.set_color(lit.darkened(0.25))
			st.add_vertex(e0)
			st.set_color(dark)
			st.add_vertex(under)
			st.add_vertex(e0)
			st.add_vertex(e1)
	st.generate_normals()
	return st.commit()


func _build_forest(root: Node3D) -> void:
	var mesh := _conifer()
	var mat := _mat("#ffffff", 0.95)
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rng := RandomNumberGenerator.new()
	rng.seed = 334
	var near: Array[Transform3D] = []
	var far: Array[Transform3D] = []
	var near_col: Array[Color] = []
	var far_col: Array[Color] = []
	var clump := FastNoiseLite.new()
	clump.seed = 12
	clump.frequency = 0.012
	for i in 52000:
		var x := rng.randf_range(-1300.0, 1300.0)
		var z := rng.randf_range(-1150.0, 300.0)
		var d := Vector2(x, z - 30.0).length()
		# Denser sampling near the camera.
		if d > 260.0 and rng.randf() < 0.55:
			continue
		if _yard(x, z) > 0.02 or _road(x, z) > 0.02:
			continue
		if z < 2.0 and z > -60.0 and absf(x) < 34.0:
			continue
		if absf(x) < 40.0 and z > -4.0 and z < 85.0:
			continue
		var h := _height(x, z)
		var dx := _height(x + 3.0, z) - h
		var dz := _height(x, z + 3.0) - h
		var slope := Vector2(dx, dz).length() / 3.0
		if slope > 1.7:
			continue
		var c := clump.get_noise_2d(x, z) + (rng.randf() - 0.5) * 0.5
		if c < -0.28:
			continue
		if h > 470.0 + clump.get_noise_2d(x * 3.0, z * 3.0) * 80.0:
			continue
		var tall := rng.randf_range(13.0, 30.0) * (1.0 if d < 200.0 else 1.25)
		var wide := tall * rng.randf_range(0.75, 1.05)
		var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(wide, tall, wide))
		var xf := Transform3D(b, Vector3(x, h - 0.6, z))
		var shade := Color(1, 1, 1).darkened(rng.randf() * 0.35)
		if d < 260.0:
			near.append(xf)
			near_col.append(shade)
		else:
			far.append(xf)
			far_col.append(shade)
	# Near: Quaternius' textured pines (CC0), one MultiMesh per model part.
	var by_kind := []
	for k in PINES.size():
		by_kind.append([])
	for k in near.size():
		by_kind[int(_hash(k * 1.37) * PINES.size()) % PINES.size()].append(near[k])
	for k in PINES.size():
		var id: String = PINES[k]
		var model_h := KitDB.size(id).y
		var xfs: Array = by_kind[k]
		for part in KitDB.parts(id):
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = part["mesh"]
			mm.instance_count = xfs.size()
			for j in xfs.size():
				var xf: Transform3D = xfs[j]
				# The instance basis holds (wide, tall, wide); the pine keeps its own proportions.
				var tall := xf.basis.y.length()
				var b := Basis(Vector3.UP, _hash(j * 2.9 + k) * TAU).scaled(Vector3.ONE * (tall / model_h))
				mm.set_instance_transform(j, Transform3D(b, xf.origin + Vector3(0, 0.5, 0)) * (part["xf"] as Transform3D))
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			root.add_child(mmi)
	for group in [[far, far_col, false]]:
		var xfs: Array = group[0]
		var cols: Array = group[1]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = mesh
		mm.instance_count = xfs.size()
		for k in xfs.size():
			mm.set_instance_transform(k, xfs[k])
			mm.set_instance_color(k, cols[k])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if group[2] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mmi)


# ------------------------------------------------------------------------------ mist

func _sheet(root: Node3D, at: Vector3, size: Vector2, yaw: float, flat: bool, tint: String, alpha: float, seed: float) -> void:
	var q := QuadMesh.new()
	q.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = q
	var m := ShaderMaterial.new()
	m.shader = _shader(MIST_SHADER)
	m.set_shader_parameter("tint", Color(tint))
	m.set_shader_parameter("alpha", alpha)
	m.set_shader_parameter("seed", seed)
	m.set_shader_parameter("fade", 30.0 if flat else 14.0)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = at
	mi.rotation = Vector3(-PI * 0.5 if flat else 0.0, yaw, 0)
	root.add_child(mi)
	_mists.append(m)


func _build_mist(root: Node3D) -> void:
	# Cloud lying in the valley below the road, and banners caught on the slopes.
	_sheet(root, Vector3(260, -52, -150), Vector2(900, 700), 0.0, true, "#6b7792", 0.7, 1.0)
	_sheet(root, Vector3(120, -40, 120), Vector2(500, 300), 0.0, true, "#65718c", 0.55, 4.0)
	_sheet(root, Vector3(-40, 95, -170), Vector2(420, 70), 0.05, false, "#7a87a2", 0.45, 2.0)
	_sheet(root, Vector3(170, 160, -420), Vector2(620, 110), -0.1, false, "#7a86a0", 0.5, 3.0)
	_sheet(root, Vector3(-260, 150, -260), Vector2(380, 80), 0.3, false, "#717d98", 0.4, 5.0)
	_sheet(root, Vector3(520, 260, -380), Vector2(500, 120), -0.4, false, "#7a86a0", 0.45, 6.0)


# ------------------------------------------------------------------------------ pose

func pose(root: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	_pose_kitchen(p, t, ctx)
	_pose_tv(p, t, ctx)
	_pose_miners(root, p, t, ctx)
	# The dumper rolls toward the mouth, easing to a crawl.
	var tr: Dictionary = p.get("truck", {})
	var t0 := float(tr.get("t0", 0.0))
	var t1 := float(tr.get("t1", 3.0))
	var z0 := float(tr.get("z0", 26.0))
	var z1 := float(tr.get("z1", 16.0))
	var u := _seg(t, t0, t1)
	var e := u * (2.0 - u)                     # decelerating
	var z := lerpf(z0, z1, e)
	_truck.position = Vector3(2.6, sin(z * 2.1) * 0.025, z)
	_truck.rotation = Vector3(sin(z * 1.7) * 0.006, PI, sin(z * 1.3) * 0.008)
	for w in _truck_wheels:
		(w as Node3D).rotation.x = -z / 0.55
	for b in _beacons:
		(b["pivot"] as Node3D).rotation.y = t * 7.5
		var flash := 0.5 + 0.5 * cos(t * 7.5)
		(b["mat"] as StandardMaterial3D).emission_energy_multiplier = 2.0 + 6.0 * flash
	# Fire: flicker, flames, embers rising, smoke drifting off.
	var fl := 0.75 + 0.15 * sin(t * 23.0) + 0.1 * sin(t * 37.0 + 1.3) + 0.08 * sin(t * 61.0)
	_fire_light.light_energy = 7.0 * fl
	for k in _flames.size():
		var f := _flames[k] as MeshInstance3D
		var a := t * (2.3 + k * 0.4) + k * 1.9
		f.position = FIRE_AT + Vector3(sin(a) * 0.09, 1.25 + 0.08 * sin(a * 1.7), cos(a * 0.8) * 0.09)
		f.scale = Vector3(0.8 + 0.2 * sin(a * 2.3), 0.7 + 0.35 * fposmod(a * 0.6, 1.0), 1.0) * (1.0 - k * 0.1)
	for k in _embers.instance_count:
		var life := 1.6 + _hash(k * 3.1) * 1.2
		var age := fposmod(t + _hash(k) * life, life)
		var up := age * (0.9 + _hash(k * 1.7) * 0.6)
		var sway := Vector3(sin(age * 3.0 + k) * 0.15 * age, 0, cos(age * 2.4 + k) * 0.15 * age)
		var at := FIRE_AT + Vector3((_hash(k * 5.3) - 0.5) * 0.4, 1.0 + up, (_hash(k * 7.9) - 0.5) * 0.4) + sway + Vector3(0.25, 0, 0) * age
		var s := 1.0 - age / life
		_embers.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3.ONE * maxf(s, 0.01) * (0.6 + _hash(k * 2.2))), at))
	for k in _smoke.instance_count:
		var life := 4.0
		var age := fposmod(t + k * life / _smoke.instance_count, life)
		var at := FIRE_AT + Vector3(age * 0.35 + sin(age + k) * 0.1, 1.3 + age * 0.75, age * 0.12)
		var s := 0.25 + age * 0.4
		_smoke.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3(s, s * 0.8, s)), at))
	for m in _mists:
		(m as ShaderMaterial).set_shader_parameter("drift", t * 0.035)
	# Headlamps: the beam goes where the walker is heading (the mouth).
	var origin: Vector3 = ctx["holder"].global_position
	for id in _lamps:
		var spot := _lamps[id] as SpotLight3D
		var hp: Dictionary = ctx["point"].call(id + ".head")
		if hp.has("error"):
			spot.visible = false
			continue
		var head: Vector3 = hp["pos"] - origin
		var at := head + Vector3(0, 0.1, -0.05)
		var target := Vector3(head.x * 0.7, 0.0, head.z - 9.0)
		spot.transform = Transform3D(_aim(target - at), at)
	return {"portal": Vector3(0, 4.2, HW), "fire": FIRE_AT + Vector3(0, 1.2, 0), "truck": _truck.position + Vector3(0, 2.0, 0)}


# ------------------------------------------------------------------------------ line 11: the site kitchen

## params.kitchen = {"from", "pour0" (the khichdi leaves the karchi), "pour1" (the karchi goes back), "cook", "pourer"};
## params.appear = {actor id: scene time}: hidden before it (so the kitchen crew never shows in the hook).
## Local layout: the bhatti and degchi at the origin, the cook at (0, 0, -0.72) facing +z stirring with both hands;
## the bottling table at TABLE with the pourer behind it at (1.5, 0, -0.6): he ladles khichdi from the steel
## bucket at BUCKET into an open wide-mouth bottle standing at BOTTLE_AT.
## Light: a tube light lashed to the front pole (key, 3/4 from camera right), a bare bulb behind the cook (rim, and
## it backlights the steam), the orange flame glow under the pot.
const KITCHEN := Vector3(11.0, 0.0, 28.0)
const SiteKitchen = preload("res://scripts/world/site_kitchen.gd")
const TABLE := Vector3(1.5, 0.0, 0.05)
const TABLE_TOP := 0.78
const BUCKET := Vector3(1.13, TABLE_TOP, -0.02)
const BOTTLE_AT := Vector3(1.56, TABLE_TOP, -0.1)
const KARCHI_DIR := Vector3(-0.93, 0.37, 0.0)     # a karchi's handle direction in its own frame
const POT_Y := 0.31                               # the bhatti ring (toon bodies are short under the big heads)
const POT_R := 0.34
const POT_H := 0.37

var _kitchen: Node3D
var _ladle: Node3D
var _stir: Node3D
var _pot_steam: MultiMeshInstance3D
var _bucket_steam: MultiMeshInstance3D
var _bottle_fill: Node3D
var _fill_bottle: Node3D
var _dollop: MeshInstance3D
var _bhatti_flames: Node3D
var _bubbles: MultiMesh


## A karchi with its cup at `cup` and its handle running toward `toward`, rolled by `roll` about the handle.
func _karchi_xf(cup: Vector3, toward: Vector3, roll: float) -> Transform3D:
	var h := KARCHI_DIR.normalized()
	var hy := Vector3(-h.y, h.x, 0.0)
	var local := Basis(h, hy, h.cross(hy))
	var d := (toward - cup).normalized()
	var up := (Vector3.UP - d * Vector3.UP.dot(d)).normalized()
	var world := Basis(d, up, d.cross(up))
	var b := Basis(d, roll) * world * local.inverse()
	return Transform3D(b.orthonormalized(), cup)


func _build_kitchen(root: Node3D) -> void:
	_kitchen = Node3D.new()
	_kitchen.position = KITCHEN
	_kitchen.visible = false
	root.add_child(_kitchen)
	# The bhatti, the degchi on it, the LPG cylinder and its hose.
	var bh := SiteKitchen.bhatti(POT_Y - 0.01)
	_kitchen.add_child(bh)
	_bhatti_flames = bh.get_node("flames")
	var pot := SiteKitchen.degchi(POT_R, POT_H)
	pot.position = Vector3(0, POT_Y, 0)
	_kitchen.add_child(pot)
	var cyl := SiteKitchen.lpg_cylinder()
	cyl.position = Vector3(-0.72, 0, 0.42)
	_kitchen.add_child(cyl)
	var hose := _mat("#1c1c1c", 0.7)
	_rod(_kitchen, Vector3(-0.72, 0.8, 0.42), Vector3(-0.55, 0.3, 0.3), 0.012, hose, 6)
	_rod(_kitchen, Vector3(-0.55, 0.3, 0.3), Vector3(-0.15, POT_Y - 0.1, 0.12), 0.012, hose, 6)
	# Khichdi blurping in the pot: small bubbles that swell and burst.
	var bub := SphereMesh.new()
	bub.radius = 0.5
	bub.height = 0.5
	bub.is_hemisphere = true
	bub.radial_segments = 12
	bub.rings = 4
	bub.material = SiteKitchen.khichdi_material()
	_bubbles = MultiMesh.new()
	_bubbles.transform_format = MultiMesh.TRANSFORM_3D
	_bubbles.mesh = bub
	_bubbles.instance_count = 6
	var bmi := MultiMeshInstance3D.new()
	bmi.multimesh = _bubbles
	_kitchen.add_child(bmi)
	# The cook's long stirring karchi and the pourer's shorter one.
	_stir = SiteKitchen.karchi(0.5)
	_stir.get_node("load").visible = false
	_kitchen.add_child(_stir)
	_ladle = SiteKitchen.karchi(0.45)
	_ladle.scale = Vector3.ONE * 0.8
	_kitchen.add_child(_ladle)
	# The bottling table: planks on trestles, a steel sheet on top.
	var wood := _mat("#5d4129", 0.85)
	for k in 4:
		_box(_kitchen, Vector3(1.1, 0.035, 0.16), Vector3(TABLE.x, TABLE_TOP - 0.02, TABLE.z - 0.24 + k * 0.16), wood)
	for c in [Vector3(-0.48, 0, -0.26), Vector3(0.48, 0, -0.26), Vector3(-0.48, 0, 0.26), Vector3(0.48, 0, 0.26)]:
		_box(_kitchen, Vector3(0.05, TABLE_TOP - 0.04, 0.05), TABLE + c + Vector3(0, (TABLE_TOP - 0.04) * 0.5, 0), wood)
	_box(_kitchen, Vector3(1.08, 0.004, 0.62), Vector3(TABLE.x, TABLE_TOP - 0.001, TABLE.z), _mat("#8f9396", 0.45, 0.75))
	# The steel bucket of khichdi, a lumpy top, steaming.
	var steel := _mat("#b9bdc0", 0.28, 0.9)
	steel.cull_mode = BaseMaterial3D.CULL_DISABLED
	var b := MeshInstance3D.new()
	b.mesh = SiteKitchen.lathe([Vector2(0.11, 0.0), Vector2(0.115, 0.01), Vector2(0.14, 0.2), Vector2(0.146, 0.21), Vector2(0.14, 0.212)], 32, true)
	b.material_override = steel
	b.position = BUCKET
	_kitchen.add_child(b)
	var bf := MeshInstance3D.new()
	bf.mesh = SiteKitchen.khichdi_surface(0.133, 11)
	bf.material_override = SiteKitchen.khichdi_material()
	bf.position = BUCKET + Vector3(0, 0.185, 0)
	_kitchen.add_child(bf)
	# The bottle being filled (open), empties waiting, and the filled, capped ones in a blue crate.
	_fill_bottle = SiteKitchen.wide_bottle(false)
	_fill_bottle.position = BOTTLE_AT
	_kitchen.add_child(_fill_bottle)
	_bottle_fill = _fill_bottle.get_node("fill")
	for i in 3:
		var e := SiteKitchen.wide_bottle(false)
		e.position = Vector3(1.2 + i * 0.1, TABLE_TOP, 0.22 + (i % 2) * 0.03)
		(e.get_node("fill") as Node3D).visible = false
		_kitchen.add_child(e)
	var crate_m := _mat("#1e5aa8", 0.55)
	var crate_at := Vector3(1.86, TABLE_TOP, 0.05)
	_box(_kitchen, Vector3(0.3, 0.012, 0.42), crate_at + Vector3(0, 0.006, 0), crate_m)
	for side in [[Vector3(0.3, 0.11, 0.012), Vector3(0, 0.055, 0.21)], [Vector3(0.3, 0.11, 0.012), Vector3(0, 0.055, -0.21)],
			[Vector3(0.012, 0.11, 0.42), Vector3(0.15, 0.055, 0)], [Vector3(0.012, 0.11, 0.42), Vector3(-0.15, 0.055, 0)]]:
		_box(_kitchen, side[0], crate_at + side[1], crate_m)
	for i in 8:
		var full := SiteKitchen.wide_bottle(true)
		full.position = crate_at + Vector3(-0.07 + (i % 2) * 0.14, 0.012, -0.15 + (i / 2) * 0.1)
		full.rotation.y = i * 0.7
		_kitchen.add_child(full)
	# Behind: sacks of rice and dal, a blue water drum.
	for i in 3:
		var sk := SiteKitchen.sack(i + 3)
		sk.position = Vector3(-1.2 + i * 0.5, 0, -0.95 - (i % 2) * 0.2)
		sk.rotation.y = i * 1.3
		_kitchen.add_child(sk)
	var drum := MeshInstance3D.new()
	drum.mesh = SiteKitchen.lathe([Vector2(0.25, 0.0), Vector2(0.27, 0.05), Vector2(0.27, 0.45), Vector2(0.26, 0.5), Vector2(0.27, 0.55), Vector2(0.27, 0.85), Vector2(0.24, 0.9), Vector2(0.0, 0.9)], 32, true)
	drum.material_override = _mat("#2a62b8", 0.5)
	drum.position = Vector3(2.15, 0, -0.75)
	_kitchen.add_child(drum)
	# The tarp: blue, sagging between bamboo poles.
	var bamboo := _mat("#a8874f", 0.8)
	var corners := [Vector3(-1.4, 0, -1.3), Vector3(2.4, 0, -1.3), Vector3(-1.4, 0, 1.4), Vector3(2.4, 0, 1.4)]
	for c in corners:
		_rod(_kitchen, c, c + Vector3(0, 2.45 if c.z < 0.0 else 2.2, 0), 0.04, bamboo, 8)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := 14
	var nz := 12
	for j in nz:
		for i in nx:
			var q := []
			for d in [[0, 0], [1, 0], [0, 1], [1, 1]]:
				var u := float(i + d[0]) / nx
				var v := float(j + d[1]) / nz
				var x := lerpf(-1.45, 2.45, u)
				var z := lerpf(-1.35, 1.45, v)
				var y := lerpf(2.47, 2.22, v) - 0.22 * sin(u * PI) * sin(v * PI) + 0.02 * sin(u * 23.0 + v * 11.0)
				q.append(Vector3(x, y, z))
			for o in [0, 2, 1, 1, 2, 3]:
				st.add_vertex(q[o])
	st.generate_normals()
	var tarp := MeshInstance3D.new()
	tarp.mesh = st.commit()
	var tm := _mat("#1f4f8f", 0.75)
	tm.cull_mode = BaseMaterial3D.CULL_DISABLED
	tarp.material_override = tm
	_kitchen.add_child(tarp)
	# Key: a tube light lashed to the front-right pole with wire, angled in at the pot.
	var tube_a := Vector3(2.33, 1.62, 1.18)
	var tube_b := Vector3(2.33, 2.12, 1.32)
	var tube := _rod(_kitchen, tube_a, tube_b, 0.014, _lit("#fff3dc", 6.0), 8)
	tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rod(_kitchen, tube_a + Vector3(0.03, -0.02, 0), tube_b + Vector3(0.03, 0.02, 0), 0.02, _mat("#d8d6d0", 0.5), 6)
	var key := OmniLight3D.new()
	key.position = (tube_a + tube_b) * 0.5 + Vector3(-0.12, 0, -0.1)
	key.light_color = Color("#ffeed6")
	key.light_energy = 1.7
	key.omni_range = 5.0
	key.omni_attenuation = 1.4
	key.shadow_enabled = true
	key.light_size = 0.25
	_kitchen.add_child(key)
	# Rim: a bare bulb on a flex behind the cook; it also lights the steam from behind.
	var bulb_at := Vector3(0.3, 1.85, -1.15)
	_rod(_kitchen, bulb_at + Vector3(0, 0.06, 0), bulb_at + Vector3(0, 0.45, 0), 0.006, _mat("#111111", 0.6), 5)
	var bulb := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.035
	bm.height = 0.08
	bulb.mesh = bm
	bulb.material_override = _lit("#ffd9a0", 14.0)
	bulb.position = bulb_at
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_kitchen.add_child(bulb)
	var rim := OmniLight3D.new()
	rim.position = bulb_at - Vector3(0, 0.05, 0)
	rim.light_color = Color("#ffb86a")
	rim.light_energy = 1.6
	rim.omni_range = 4.0
	rim.omni_attenuation = 1.2
	rim.shadow_enabled = true
	rim.light_volumetric_fog_energy = 2.0
	_kitchen.add_child(rim)
	_pot_steam = SiteKitchen.steam(22, 0.2)
	_kitchen.add_child(_pot_steam)
	_bucket_steam = SiteKitchen.steam(8, 0.16)
	_kitchen.add_child(_bucket_steam)
	# The dollop of khichdi sliding off the karchi into the bottle's mouth.
	_dollop = MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 0.034
	dm.height = 0.05
	_dollop.mesh = dm
	_dollop.material_override = SiteKitchen.khichdi_material()
	_kitchen.add_child(_dollop)


func _pose_kitchen(p: Dictionary, t: float, ctx: Dictionary) -> void:
	for id in p.get("appear", {}):
		var a = ctx["actor"].call(String(id)) if ctx.has("actor") else null
		if a != null:
			a.visible = t >= float(p["appear"][id])
	for id in p.get("vanish", {}):
		var a = ctx["actor"].call(String(id)) if ctx.has("actor") else null
		if a != null and t >= float(p["vanish"][id]):
			a.visible = false
	if _kitchen == null or not p.has("kitchen"):
		return
	var kp: Dictionary = p["kitchen"]
	_kitchen.visible = t >= float(kp.get("from", 1.0e9))
	if not _kitchen.visible:
		return
	var origin: Vector3 = _kitchen.global_position
	for i in _bhatti_flames.get_child_count():
		var f := _bhatti_flames.get_child(i) as Node3D
		f.scale = Vector3(1, 0.8 + 0.4 * absf(sin(t * 19.0 + i * 1.7)), 1)
	# Steam leans away from the cook's face (toward -x, the camera's left) in a light breeze.
	SiteKitchen.steam_pose(_pot_steam, t, Vector3(0, POT_Y + POT_H * 0.82, 0.04), 0.28, 0.38, 2.6, 0.26, 1.0, Vector3(-0.55, 0, 0.25))
	SiteKitchen.steam_pose(_bucket_steam, t + 3.0, BUCKET + Vector3(0, 0.2, 0), 0.1, 0.26, 1.8, 0.12, 1.0, Vector3(-0.2, 0, 0.1))
	for i in _bubbles.instance_count:
		var life := 0.9 + _hash(i * 4.1) * 0.7
		var age := fposmod(t + _hash(i * 2.3) * life, life) / life
		var ba := _hash(i * 7.7) * TAU
		var br := 0.06 + _hash(i * 3.9) * 0.22
		var at := Vector3(cos(ba) * br * POT_R / 0.36, POT_Y + POT_H * 0.78 + 0.012, sin(ba) * br * POT_R / 0.36)
		var s := 0.035 * Motion.out_cubic(minf(age / 0.85, 1.0)) * (1.0 if age < 0.85 else 0.0) + 0.0001
		_bubbles.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(s, s * 0.8, s)), at))
	# The cook folds the khichdi over: the cup sweeps the pot slowly, both hands on the handle.
	var a := t * 2.1
	var cup := Vector3(cos(a) * 0.14, POT_Y + POT_H * 0.78 - 0.02 - 0.03 * (0.5 + 0.5 * sin(a)), 0.03 + sin(a) * 0.09)
	var grip := Vector3(0.08 + 0.05 * cos(a), 0.83 + 0.02 * sin(a * 2.0), -0.36 + 0.03 * sin(a))
	_stir.transform = _karchi_xf(cup, grip, 0.0)
	var cook = ctx["actor"].call(String(kp.get("cook", ""))) if ctx.has("actor") else null
	if cook != null:
		var d := (grip - cup).normalized()
		cook.aim_hand("r", origin + grip + d * 0.08, 1.0)
		cook.aim_hand("l", origin + grip - d * 0.17 + Vector3(0.03, 0, 0), 1.0)
	# The pour: scoop in the bucket, lift, carry over the bottle, tip; the khichdi slides out and plops in; two
	# taps on the rim to shake the karchi clean; back to the bucket. The bottle stands on the table (a hand
	# on it shows through the clear plastic and hides the fill).
	var pour0 := float(kp.get("pour0", 1.0e9))
	var pour1 := float(kp.get("pour1", 1.0e9))
	var mouth := BOTTLE_AT + Vector3(0, 0.218, 0)
	var dip := BUCKET + Vector3(0, 0.15, 0)
	var over := mouth + Vector3(-0.035, 0.075, 0.0)
	var carry := Motion.in_out(Motion.seg(t, pour0 - 0.62, pour0 - 0.12)) * (1.0 - Motion.in_out(Motion.seg(t, pour1 + 0.15, pour1 + 0.75)))
	var lp := dip.lerp(over, carry) + Vector3(0, 0.12 * sin(carry * PI), 0)
	var taps := 0.0
	for tt in [pour0 + 0.34, pour0 + 0.5]:
		if t > tt:
			taps += Motion.impact(t - tt, 0.012, 9.0, 18.0)
	lp.y += taps
	var tip := Motion.out_cubic(Motion.seg(t, pour0 - 0.14, pour0 + 0.12)) * (1.0 - Motion.smooth(Motion.seg(t, pour1, pour1 + 0.3)))
	var hand_at := lp + Vector3(-0.3, 0.2, -0.18)
	_ladle.transform = _karchi_xf(lp, hand_at, 1.75 * tip).scaled_local(Vector3.ONE * 0.8)
	var load := _ladle.get_node("load") as Node3D
	load.visible = t < pour0 + 0.02 or t > pour1 + 0.4
	var fall := Motion.in_cubic(Motion.seg(t, pour0, pour0 + 0.16))
	_dollop.visible = t > pour0 and t < pour0 + 0.17
	_dollop.position = lp.lerp(mouth + Vector3(0, -0.02, 0), fall) + Vector3(0, 0.02, 0)
	_dollop.scale = Vector3(1.0 - 0.3 * fall, 1.0 + 0.7 * fall, 1.0 - 0.3 * fall)
	var fill := 0.3 + 0.45 * Motion.out_back(Motion.seg(t, pour0 + 0.14, pour0 + 0.36), 1.2)
	_bottle_fill.scale = Vector3(1, fill, 1)
	# The bottle jolts as the dollop lands.
	var jolt := Motion.impact(t - pour0 - 0.15, 0.006, 6.0, 14.0) if t > pour0 + 0.15 else 0.0
	_fill_bottle.position = BOTTLE_AT + Vector3(0, -absf(jolt), 0)
	var pourer = ctx["actor"].call(String(kp.get("pourer", ""))) if ctx.has("actor") else null
	if pourer != null:
		var hold := _ladle.global_transform * (KARCHI_DIR.normalized() * 0.44)
		pourer.aim_hand("r", hold, 1.0)


# ------------------------------------------------------------------------------ line 12: the monitor in the yard

## params.tv = {"from", "feed" (gag anchor of the camera: "collapse.scope"), "aim" ("collapse.scope_ahead")}:
## a monitor on a table in the yard showing the live feed from that camera (a SubViewport sharing the world).
const TV_AT := Vector3(-17.5, 0.0, 31.0)

var _tv: Node3D
var _tv_view: SubViewport
var _tv_cam: Camera3D


func _build_tv(root: Node3D) -> void:
	_tv = Node3D.new()
	_tv.position = TV_AT
	_tv.visible = false
	root.add_child(_tv)
	var wood := _mat("#5a3f28", 0.85)
	_box(_tv, Vector3(1.6, 0.06, 0.8), Vector3(0, 0.78, 0), wood)
	for c in [Vector3(-0.72, 0.39, -0.33), Vector3(0.72, 0.39, -0.33), Vector3(-0.72, 0.39, 0.33), Vector3(0.72, 0.39, 0.33)]:
		_box(_tv, Vector3(0.05, 0.78, 0.05), c, wood)
	# The monitor: bezel, stand, and the screen showing the feed.
	var black := _mat("#121314", 0.4, 0.3)
	_box(_tv, Vector3(1.02, 0.62, 0.06), Vector3(0, 1.31, -0.1), black)
	_box(_tv, Vector3(0.08, 0.22, 0.06), Vector3(0, 0.92, -0.1), black)
	_box(_tv, Vector3(0.36, 0.02, 0.22), Vector3(0, 0.82, -0.1), black)
	_tv_view = SubViewport.new()
	_tv_view.size = Vector2i(640, 384)
	_tv_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_tv_view.own_world_3d = false
	_tv.add_child(_tv_view)
	_tv_cam = Camera3D.new()
	_tv_cam.fov = 82.0
	_tv_cam.near = 0.02
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.45, 0.4)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.8
	env.adjustment_contrast = 1.15
	_tv_cam.environment = env
	_tv_view.add_child(_tv_cam)
	var screen := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.96, 0.56)
	screen.mesh = q
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_texture = _tv_view.get_texture()
	sm.albedo_color = Color(1.25, 1.25, 1.25)
	screen.material_override = sm
	screen.position = Vector3(0, 1.31, -0.066)
	_tv.add_child(screen)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 1.3, 0.35)
	glow.light_color = Color("#cfe0ff")
	glow.light_energy = 1.6
	glow.omni_range = 3.0
	_tv.add_child(glow)
	# A bare bulb over the table, a laptop, a walkie-talkie, cables.
	var bulb := _box(_tv, Vector3(0.08, 0.1, 0.08), Vector3(0.3, 2.3, 0.4), _lit("#ffd28a", 9.0))
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var key := OmniLight3D.new()
	key.position = Vector3(0.3, 2.2, 0.5)
	key.light_color = Color("#ffc983")
	key.light_energy = 1.6
	key.omni_range = 5.0
	key.shadow_enabled = true
	_tv.add_child(key)
	_box(_tv, Vector3(0.34, 0.02, 0.24), Vector3(-0.55, 0.82, 0.12), _mat("#2b2d30", 0.4, 0.6))
	_box(_tv, Vector3(0.06, 0.18, 0.04), Vector3(0.6, 0.9, 0.2), _mat("#1a1a1a", 0.5))
	_rod(_tv, Vector3(0.0, 0.82, -0.2), Vector3(0.9, 0.0, -0.9), 0.012, _mat("#0e0e0e", 0.6), 5)


func _pose_tv(p: Dictionary, t: float, ctx: Dictionary) -> void:
	if _tv == null or not p.has("tv"):
		return
	var tp: Dictionary = p["tv"]
	_tv.visible = t >= float(tp.get("from", 1.0e9))
	if not _tv.visible:
		return
	var a: Dictionary = ctx["point"].call(String(tp.get("feed", "collapse.scope")))
	var b: Dictionary = ctx["point"].call(String(tp.get("aim", "collapse.scope_ahead")))
	if a.has("error") or b.has("error"):
		return
	var from: Vector3 = a["pos"]
	var to: Vector3 = b["pos"]
	_tv_cam.global_transform = Transform3D(Basis.looking_at(to - from, Vector3.UP), from)


# ------------------------------------------------------------------------------ line 17: the rat-hole miners arrive

## params.miners = {"from", "until", "truck": {"t0", "t1", "z0", "z1", "x"} (a pickup rolls up and stops),
## "tools": {actor id: "hammer" | "phawda" | "tasla" | "chisel"}}: their own tools, held in the right hand (the
## tasla, a steel pan, rides on the head with the left hand steadying its rim, the way it is carried on Indian
## sites). Tools follow the hand bone every frame.
const PICKUP := "majadroid_construction/Trucks#Small Truck"

var _pickup: Node3D
var _tools := {}


func _tool(kind: String) -> Node3D:
	var n := Node3D.new()
	var wood := _mat("#7a5532", 0.8)
	var steel := _mat("#5e6266", 0.45, 0.75)
	match kind:
		"hammer":
			# A club hammer: a short ash handle (along +Y from the grip) and a heavy steel head.
			_rod(n, Vector3(0, -0.06, 0), Vector3(0, 0.26, 0), 0.016, wood, 8)
			_box(n, Vector3(0.13, 0.055, 0.055), Vector3(0, 0.27, 0), steel)
		"chisel":
			_rod(n, Vector3(0, -0.08, 0), Vector3(0, 0.22, 0), 0.011, steel, 6)
			_box(n, Vector3(0.018, 0.03, 0.012), Vector3(0, 0.235, 0), _mat("#c9ccd0", 0.3, 0.85))
		"phawda":
			# A phawda: a long handle with the blade at right angles, like a hoe.
			_rod(n, Vector3(0, -0.35, 0), Vector3(0, 0.65, 0), 0.02, wood, 8)
			_box(n, Vector3(0.24, 0.22, 0.012), Vector3(0, 0.73, 0.1), steel)
			_box(n, Vector3(0.05, 0.05, 0.08), Vector3(0, 0.66, 0.04), steel)
		"tasla":
			# A tasla: a shallow pressed-steel pan, about 45 cm across.
			var pan := MeshInstance3D.new()
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var prof := [Vector2(0.0, 0.0), Vector2(0.15, 0.0), Vector2(0.21, 0.07), Vector2(0.225, 0.1), Vector2(0.23, 0.105)]
			for i in prof.size() - 1:
				var a: Vector2 = prof[i]
				var b: Vector2 = prof[i + 1]
				for k in 28:
					var t0 := TAU * k / 28.0
					var t1 := TAU * (k + 1) / 28.0
					var q := [Vector3(cos(t0) * a.x, a.y, sin(t0) * a.x), Vector3(cos(t1) * a.x, a.y, sin(t1) * a.x),
						Vector3(cos(t0) * b.x, b.y, sin(t0) * b.x), Vector3(cos(t1) * b.x, b.y, sin(t1) * b.x)]
					for o in [0, 2, 1, 1, 2, 3]:
						st.add_vertex(q[o])
			st.generate_normals()
			pan.mesh = st.commit()
			var pm := _mat("#a3a8ad", 0.38, 0.75)
			pm.cull_mode = BaseMaterial3D.CULL_DISABLED
			pan.material_override = pm
			n.add_child(pan)
	return n


func _build_miners(root: Node3D) -> void:
	_pickup = KitDB.static_node(PICKUP, 0.92)
	_pickup.visible = false
	root.add_child(_pickup)


## The world transform of an actor's bone (orthonormal), or null.
func _bone_xf(a, bone: String):
	var sk: Skeleton3D = a.retarget.dst if a.retarget != null else a.skeleton
	if sk == null:
		return null
	var bi := sk.find_bone(bone)
	if bi < 0:
		return null
	var xf := sk.global_transform * sk.get_bone_global_pose(bi)
	return Transform3D(xf.basis.orthonormalized(), xf.origin)


func _pose_miners(root: Node3D, p: Dictionary, t: float, ctx: Dictionary) -> void:
	if not p.has("miners"):
		return
	var mp: Dictionary = p["miners"]
	var on := t >= float(mp.get("from", 1.0e9)) and t < float(mp.get("until", 1.0e9))
	var tr: Dictionary = mp.get("truck", {})
	_pickup.visible = on
	if on:
		var k := Motion.out_cubic(Motion.seg(t, float(tr.get("t0", 0.0)), float(tr.get("t1", 0.0))))
		var z := lerpf(float(tr.get("z0", 26.0)), float(tr.get("z1", 15.0)), k)
		var brake := Motion.impact(t - float(tr.get("t1", 0.0)), 0.04, 2.0, 6.0) if t > float(tr.get("t1", 0.0)) else 0.0
		_pickup.position = Vector3(float(tr.get("x", -5.0)), 0.0, z)
		_pickup.rotation = Vector3(brake, PI, 0.0)
	for id in mp.get("tools", {}):
		var kind := String(mp["tools"][id])
		var a = ctx["actor"].call(String(id)) if ctx.has("actor") else null
		if not _tools.has(id):
			var node := _tool(kind)
			root.add_child(node)
			_tools[id] = node
		var tn := _tools[id] as Node3D
		tn.visible = on and a != null and a.visible
		if not tn.visible:
			continue
		if kind == "tasla":
			var hd: Vector3 = a.anchor_points()[String(id) + ".head"]["pos"]
			var yaw: float = a.rotation.y
			# Scaled to the toon head (a real 45 cm pan would sit on it like a cap).
			tn.global_transform = Transform3D(Basis(Vector3.UP, yaw).rotated(Vector3(cos(yaw), 0, -sin(yaw)), 0.1).scaled(Vector3.ONE * 1.55), hd + Vector3(0, 0.33, 0))
			var left := Vector3(cos(yaw), 0, -sin(yaw))
			a.aim_hand("l", hd + Vector3(0, 0.45, 0) + left * 0.36, 1.0, 0.08)
		else:
			var xf = _bone_xf(a, "hand_r")
			if xf != null:
				tn.global_transform = xf
