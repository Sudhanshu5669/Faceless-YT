extends RefCounted
## Line 9: the Indian Air Force flies the 25-tonne auger in from Delhi (C-130J Hercules to the
## Chinyalisaur airstrip, 15 Nov 2023).
##
## A valley airstrip on the edge of a reservoir: pine slopes, a far snow range, morning haze. A C-130J
## (built here: lofted fuselage, high wing, four engines with six-blade props, the tall fin, sponsons,
## IAF roundels and the tricolour fin flash) with a ribbed hold, the auger rig chained inside, and a
## rear ramp that lowers.
##
## Local frame: the runway runs along Z at y = 0; the plane travels toward -Z and stops at STOP_Z.
## params: land (touchdown, scene time), stop (it comes to rest), ramp (the ramp starts down)
## anchors: plane (its origin, on the centreline at the cargo floor), rig (top of the rig), ramp (its foot)

const AugerRig = preload("res://scripts/world/auger_rig.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")

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

const GROUND_SHADER := """
shader_type spatial;
render_mode cull_disabled;
varying vec3 wp;
varying vec3 wn;
void vertex() { wp = VERTEX; wn = NORMAL; }
//NOISE
void fragment() {
	float near = 1.0 - smoothstep(80.0, 400.0, length(VERTEX));
	float m = fbm(wp * 0.02);
	float f = fbm(wp * 0.3) * near;
	float steep = smoothstep(0.7, 0.45, wn.y);
	vec3 grass = mix(vec3(0.34, 0.27, 0.13), vec3(0.15, 0.17, 0.08), smoothstep(0.35, 0.65, m));
	vec3 rock = vec3(0.24, 0.22, 0.2) * (0.7 + fbm(wp * 0.05) * 0.5);
	vec3 col = mix(grass * (0.75 + f * 0.4 + m * 0.3), rock, steep);
	col = mix(col, vec3(0.33, 0.3, 0.26) * (0.8 + f * 0.3), COLOR.r);          // the airfield's gravel apron
	float snow = smoothstep(380.0, 470.0, wp.y + m * 60.0) * (1.0 - steep * 0.6);
	ALBEDO = mix(col, vec3(0.86, 0.88, 0.92), snow);
	ROUGHNESS = 0.95;
}
"""

## The Hercules' skin: IAF grey, panel lines, a little grime. sag bends the fuselage down in the middle
## and droop flexes the wing tips (the plane straining under the load).
const SKIN_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 tint : source_color = vec3(0.4, 0.43, 0.46);
uniform float sag = 0.0;
uniform float droop = 0.0;
varying vec3 lp;
void vertex() {
	lp = VERTEX;
	VERTEX.y -= sag * exp(-pow(VERTEX.z / 8.0, 2.0)) + droop * pow(clamp(abs(VERTEX.x) / 20.0, 0.0, 1.0), 2.0);
}
//NOISE
void fragment() {
	float panel = max(smoothstep(0.96, 1.0, abs(fract(lp.z / 1.6) - 0.5) * 2.0), smoothstep(0.97, 1.0, abs(fract((lp.y + lp.x) / 1.1) - 0.5) * 2.0));
	float grime = fbm(lp * 0.6);
	vec3 col = tint * (0.86 + grime * 0.22) * (1.0 - panel * 0.25);
	ALBEDO = col;
	ROUGHNESS = 0.55;
	METALLIC = 0.25;
}
"""

const STOP_Z := 0.0
const FLOOR_Y := 1.45           # the cargo floor above the runway when the plane sits on its wheels
const RAMP_HINGE := Vector2(5.2, -1.62)   # (z, y) of the ramp's hinge in plane space

var _plane: Node3D
var _skins: Array = []
var _props: Array = []
var _blur: Array = []
var _ramp: Node3D
var _rig: Node3D
var _beacon: StandardMaterial3D
var _noise: FastNoiseLite


func build(_g: Dictionary) -> Node3D:
	var root := Node3D.new()
	_noise = FastNoiseLite.new()
	_noise.seed = 915
	_noise.frequency = 0.004
	_noise.fractal_octaves = 5
	_build_valley(root)
	_build_airfield(root)
	_build_plane(root)
	return root


# ------------------------------------------------------------------------------ helpers

func _shader(code: String) -> ShaderMaterial:
	var s := Shader.new()
	s.code = code.replace("//NOISE", NOISE_GLSL)
	var m := ShaderMaterial.new()
	m.shader = s
	return m


func _mat(color: String, rough: float = 0.8, metal: float = 0.0) -> StandardMaterial3D:
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
	var y := (b - a).normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y, x.cross(y).normalized()), (a + b) * 0.5)
	parent.add_child(mi)
	return mi


func _disc(parent: Node3D, r: float, pos: Vector3, axis_x: bool, mat: Material, thick: float = 0.02) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = thick
	mesh.radial_segments = 32
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	if axis_x:
		mi.rotation.z = PI * 0.5
	else:
		mi.rotation.x = PI * 0.5
	parent.add_child(mi)
	return mi


func _hash(n: float) -> float:
	return fposmod(sin(n * 127.1 + 3.7) * 43758.5453, 1.0)


# ------------------------------------------------------------------------------ the valley

func _height(x: float, z: float) -> float:
	var bend := 60.0 * sin(z / 900.0)
	var d := absf(x - bend)
	var h := 470.0 * smoothstep(110.0, 1100.0, d) + _noise.get_noise_2d(x, z) * 90.0 * smoothstep(80.0, 400.0, d)
	# The reservoir in the valley floor on the +X side.
	var lake := smoothstep(150.0, 230.0, x - bend) * (1.0 - smoothstep(480.0, 620.0, x - bend))
	h -= 18.0 * lake
	h += _noise.get_noise_2d(x * 6.0, z * 6.0) * 1.2 * smoothstep(60.0, 120.0, d)
	# Far range at the head of the valley.
	h += 1300.0 * smoothstep(-2200.0, -4200.0, z) * (0.6 + 0.4 * _noise.get_noise_2d(x * 0.5, z * 0.5))
	return h


func _axis(lo: float, hi: float, fine: float, grow: float, c0: float, c1: float) -> PackedFloat32Array:
	var vals: Array = []
	var v := c0
	while v > lo:
		vals.append(v)
		v -= fine + maxf(c0 - v, 0.0) * grow
	v = c0
	while v < hi:
		v += fine + maxf(v - c1, 0.0) * grow
		vals.append(v)
	vals.sort()
	var out := PackedFloat32Array()
	for x in vals:
		out.append(x)
	return out


func _build_valley(root: Node3D) -> void:
	var xs := _axis(-3000.0, 3000.0, 4.0, 0.05, -80.0, 80.0)
	var zs := _axis(-4600.0, 1600.0, 4.0, 0.05, -300.0, 300.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := []
	for z in zs:
		var r := PackedFloat32Array()
		for x in xs:
			r.append(_height(x, z))
		rows.append(r)
	for j in zs.size() - 1:
		var ra: PackedFloat32Array = rows[j]
		var rb: PackedFloat32Array = rows[j + 1]
		for i in xs.size() - 1:
			var q := [Vector3(xs[i], ra[i], zs[j]), Vector3(xs[i + 1], ra[i + 1], zs[j]), Vector3(xs[i], rb[i], zs[j + 1]), Vector3(xs[i + 1], rb[i + 1], zs[j + 1])]
			for k in [0, 2, 1, 1, 2, 3]:
				var p: Vector3 = q[k]
				st.set_color(Color(1.0 - smoothstep(30.0, 45.0, absf(p.x)) if absf(p.z) < 700.0 else 0.0, 0, 0))
				st.add_vertex(p)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _shader(GROUND_SHADER)
	root.add_child(mi)
	# The reservoir: still, milky turquoise, mirroring the slopes.
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(700, 5000)
	water.mesh = plane
	var wm := _mat("#4f7f7c", 0.06, 0.0)
	wm.metallic_specular = 0.8
	water.material_override = wm
	water.position = Vector3(390, -6.0, -1200)
	root.add_child(water)
	# Pines on the slopes (a simple conifer far off, Quaternius pines near the strip).
	var tree_mat := _mat("#ffffff", 0.95)
	tree_mat.vertex_color_use_as_albedo = true
	tree_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var far := MultiMesh.new()
	far.transform_format = MultiMesh.TRANSFORM_3D
	far.use_colors = true
	far.mesh = _conifer()
	var rng := RandomNumberGenerator.new()
	rng.seed = 916
	var xfs: Array[Transform3D] = []
	var cols: Array[Color] = []
	for i in 70000:
		var x := rng.randf_range(-2600.0, 2600.0)
		var z := rng.randf_range(-3800.0, 1400.0)
		var h := _height(x, z)
		if h < 3.0 or h > 380.0 or absf(x) < 70.0:
			continue
		if _noise.get_noise_2d(x * 2.0, z * 2.0) < -0.2:
			continue
		var tall := rng.randf_range(16.0, 30.0)
		var wide := tall * rng.randf_range(0.7, 0.95)
		xfs.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(wide, tall, wide)), Vector3(x, h - 0.6, z)))
		cols.append(Color(1, 1, 1).darkened(rng.randf() * 0.3))
	far.instance_count = xfs.size()
	for k in xfs.size():
		far.set_instance_transform(k, xfs[k])
		far.set_instance_color(k, cols[k])
	var fmi := MultiMeshInstance3D.new()
	fmi.multimesh = far
	fmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fmi.material_override = tree_mat
	root.add_child(fmi)
	var pines := ["quaternius_nature_mega/Pine_1", "quaternius_nature_mega/Pine_2", "quaternius_nature_mega/Pine_4", "quaternius_nature_mega/Pine_5"]
	for i in 90:
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * rng.randf_range(62.0, 140.0)
		var z := rng.randf_range(-260.0, 260.0)
		var tree := KitDB.static_node(pines[i % pines.size()], rng.randf_range(1.8, 2.8))
		tree.position = Vector3(x, _height(x, z) - 0.3, z)
		tree.rotation.y = rng.randf() * TAU
		root.add_child(tree)


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


# ------------------------------------------------------------------------------ the airfield

func _build_airfield(root: Node3D) -> void:
	var asphalt := _mat("#2c2c2e", 0.85)
	var white := _mat("#d8d8d2", 0.7)
	_box(root, Vector3(30.0, 0.1, 1400.0), Vector3(0, 0.0, 0), asphalt)
	_box(root, Vector3(0.9, 0.11, 1400.0), Vector3(14.2, 0.005, 0), white)
	_box(root, Vector3(0.9, 0.11, 1400.0), Vector3(-14.2, 0.005, 0), white)
	var z := -680.0
	while z < 680.0:
		_box(root, Vector3(0.9, 0.11, 18.0), Vector3(0, 0.01, z), white)       # centre-line dashes
		z += 36.0
	for k in 8:
		_box(root, Vector3(1.8, 0.11, 30.0), Vector3(-12.0 + k * 3.4, 0.01, 660.0), white)   # threshold piano keys
	# A windsock on its mast, a small control hut, edge lights.
	var mast := _rod(root, Vector3(36, 0, 40), Vector3(36, 7, 40), 0.08, _mat("#c9c9c3", 0.5, 0.4), 8)
	mast.name = "windsock_mast"
	var sock := _rod(root, Vector3(36, 6.9, 40), Vector3(36.4, 6.6, 42.8), 0.38, _mat("#e5631c", 0.7), 12)
	sock.name = "windsock"
	_box(root, Vector3(6, 3.2, 5), Vector3(-44, 1.6, 30), _mat("#c7c1b1", 0.85))
	_box(root, Vector3(6.4, 0.25, 5.4), Vector3(-44, 3.3, 30), _mat("#5f6a73", 0.6))
	_box(root, Vector3(0.06, 1.0, 3.2), Vector3(-40.95, 1.9, 30), _mat("#1f2a33", 0.1, 0.5))
	for k in 30:
		for sx in [-16.0, 16.0]:
			_box(root, Vector3(0.25, 0.4, 0.25), Vector3(sx, 0.2, -560.0 + k * 40.0), _lit("#fff3c4", 1.2))
	# What waits for the cargo: a heavy truck and a jeep on the apron.
	var truck := KitDB.static_node("majadroid_construction/Trucks#Base Truck", 1.0)
	truck.position = Vector3(-24, 0, 26)
	truck.rotation.y = PI * 0.5
	root.add_child(truck)
	var truck2 := KitDB.static_node("majadroid_construction/Trucks#Small Truck", 0.9)
	truck2.position = Vector3(-25, 0, 40)
	truck2.rotation.y = PI * 0.62
	root.add_child(truck2)


# ------------------------------------------------------------------------------ the Hercules

## Fuselage stations: z (toward the tail), centre height, vertical radius, half width.
const STATIONS := [
	[-15.2, -0.2, 0.08, 0.08], [-14.9, -0.25, 0.75, 0.7], [-14.2, -0.1, 1.45, 1.35], [-13.0, 0.15, 1.95, 1.85],
	[-11.5, 0.3, 2.1, 2.1], [5.2, 0.3, 2.1, 2.1], [7.0, 0.65, 1.8, 2.0], [9.5, 1.2, 1.3, 1.65],
	[12.0, 1.85, 0.8, 1.05], [14.2, 2.3, 0.4, 0.5], [15.3, 2.45, 0.12, 0.15]]


func _ring(st: Array, k: int, n: int) -> Vector3:
	var th := TAU * float(k) / n
	return Vector3(cos(th) * float(st[3]), float(st[1]) + sin(th) * float(st[2]), float(st[0]))


func _loft(scale: float, ramp: bool, hole: bool) -> ArrayMesh:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 36
	for j in STATIONS.size() - 1:
		var a: Array = STATIONS[j].duplicate()
		var b: Array = STATIONS[j + 1].duplicate()
		for s in [a, b]:
			s[2] = float(s[2]) * scale
			s[3] = float(s[3]) * scale
		# Split the long middle station so the sag shader has vertices to bend.
		var parts := 1 if (float(b[0]) - float(a[0])) < 3.0 else int((float(b[0]) - float(a[0])) / 1.6)
		for p in parts:
			var u0 := float(p) / parts
			var u1 := float(p + 1) / parts
			var sa := [lerpf(a[0], b[0], u0), lerpf(a[1], b[1], u0), lerpf(a[2], b[2], u0), lerpf(a[3], b[3], u0)]
			var sb := [lerpf(a[0], b[0], u1), lerpf(a[1], b[1], u1), lerpf(a[2], b[2], u1), lerpf(a[3], b[3], u1)]
			for k in n:
				var on_ramp := float(sa[0]) >= RAMP_HINGE.x - 0.01 and float(sb[0]) <= 12.1 and sin(TAU * (k + 0.5) / n) < -0.42
				if on_ramp != ramp and (hole or ramp):
					continue
				var q := [_ring(sa, k, n), _ring(sa, k + 1, n), _ring(sb, k, n), _ring(sb, k + 1, n)]
				for o in [0, 2, 1, 1, 2, 3]:
					var v: Vector3 = q[o]
					if ramp:
						v -= Vector3(0, RAMP_HINGE.y, RAMP_HINGE.x)
					mesh.add_vertex(v)
	mesh.generate_normals()
	return mesh.commit()


func _build_plane(root: Node3D) -> void:
	_plane = Node3D.new()
	_plane.name = "hercules"
	root.add_child(_plane)
	var skin := _shader(SKIN_SHADER)
	_skins.append(skin)
	var shell := MeshInstance3D.new()
	shell.mesh = _loft(1.0, false, true)
	shell.material_override = skin
	_plane.add_child(shell)
	# The hold: an inner skin of quilted insulation, ribs, floor rollers, red webbing seats, lights.
	var quilt := _mat("#57604f", 0.95)
	var inner := MeshInstance3D.new()
	inner.mesh = _loft(0.95, false, true)
	inner.material_override = quilt
	_plane.add_child(inner)
	var rib := TorusMesh.new()
	rib.inner_radius = 1.88
	rib.outer_radius = 2.0
	rib.rings = 36
	rib.ring_segments = 4
	rib.material = _mat("#3e4440", 0.7, 0.3)
	var z := -11.0
	while z < 5.0:
		var r := MeshInstance3D.new()
		r.mesh = rib
		r.position = Vector3(0, 0.3, z)
		r.rotation.x = PI * 0.5
		r.scale = Vector3(1.0, 1.0, 1.0)
		_plane.add_child(r)
		z += 0.9
	_box(_plane, Vector3(3.1, 0.12, 17.0), Vector3(0, -1.32, -3.0), _mat("#2e3133", 0.6, 0.5))
	for sx in [-1.0, -0.35, 0.35, 1.0]:
		_box(_plane, Vector3(0.12, 0.05, 16.5), Vector3(sx, -1.24, -3.0), _mat("#8b8f92", 0.3, 0.8))
	var web := _mat("#8e2a24", 0.9)
	for sx in [-1.0, 1.0]:
		_box(_plane, Vector3(0.05, 0.7, 14.0), Vector3(sx * 1.78, -0.35, -3.5), web)
		_box(_plane, Vector3(0.35, 0.06, 14.0), Vector3(sx * 1.6, -0.75, -3.5), web)
	for k in 5:
		var lamp := _box(_plane, Vector3(0.5, 0.06, 0.25), Vector3(0, 2.2, -10.0 + k * 3.2), _lit("#ffd6a0", 1.4))
		lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var light := OmniLight3D.new()
		light.position = Vector3(0, 1.9, -10.0 + k * 3.2)
		light.light_color = Color("#ffcf94")
		light.light_energy = 0.45
		light.omni_range = 5.5
		_plane.add_child(light)
	# A work light clamped to the roof, aimed at the rig: the brightest thing in the hold.
	var key := SpotLight3D.new()
	key.transform = Transform3D(Basis.looking_at(Vector3(-0.9, -2.6, 3.6).normalized()), Vector3(0.9, 1.9, -9.0))
	key.light_color = Color("#fff0d8")
	key.light_energy = 7.0
	key.spot_range = 14.0
	key.spot_angle = 32.0
	key.spot_attenuation = 0.7
	key.shadow_enabled = true
	key.light_volumetric_fog_energy = 1.2
	_plane.add_child(key)
	# The cargo: the auger rig on its pallet, nose toward the cockpit, chained down.
	_rig = AugerRig.build(true)
	_rig.position = Vector3(0, -1.26, -3.2)
	_rig.rotation.y = PI
	_rig.scale = Vector3.ONE * 0.92
	_plane.add_child(_rig)
	var chain := _mat("#7a7d80", 0.4, 0.8)
	for p in [[-1.4, -7.0], [1.4, -7.0], [-1.4, 0.8], [1.4, 0.8], [-1.4, -3.0], [1.4, -3.0]]:
		_rod(_plane, Vector3(p[0] * 0.75, 0.0, p[1]), Vector3(p[0], -1.25, p[1] + 0.6), 0.035, chain, 6)
	# Cockpit glass.
	var glass := _mat("#1a2530", 0.05, 0.7)
	_box(_plane, Vector3(2.6, 0.55, 0.9), Vector3(0, 1.25, -13.6), glass).rotation.x = -0.45
	for sx in [-1.0, 1.0]:
		_box(_plane, Vector3(0.1, 0.45, 1.1), Vector3(sx * 1.55, 1.05, -13.0), glass)
	# Wing on top, four engines under it.
	var wing := MeshInstance3D.new()
	var wst := SurfaceTool.new()
	wst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := 20.2
	for side in [-1.0, 1.0]:
		for i in 10:
			var x0: float = side * half * float(i) / 10.0
			var x1: float = side * half * float(i + 1) / 10.0
			var c0 := lerpf(4.9, 2.4, float(i) / 10.0)
			var c1 := lerpf(4.9, 2.4, float(i + 1) / 10.0)
			var t0 := lerpf(0.55, 0.28, float(i) / 10.0)
			var t1 := lerpf(0.55, 0.28, float(i + 1) / 10.0)
			var y := 2.45
			var zf0 := -3.4
			var zf1 := -3.4 + (4.9 - c1) * 0.3
			var corners := [
				Vector3(x0, y + t0 * 0.6, zf0), Vector3(x1, y + t1 * 0.6, zf1), Vector3(x0, y + t0 * 0.6, zf0 + c0), Vector3(x1, y + t1 * 0.6, zf1 + c1),
				Vector3(x0, y - t0 * 0.4, zf0), Vector3(x1, y - t1 * 0.4, zf1), Vector3(x0, y - t0 * 0.4, zf0 + c0), Vector3(x1, y - t1 * 0.4, zf1 + c1)]
			for f in [[0, 2, 1, 1, 2, 3], [4, 5, 6, 5, 7, 6], [0, 1, 4, 1, 5, 4], [2, 6, 3, 3, 6, 7]]:
				for o in f:
					wst.add_vertex(corners[o])
	wst.generate_normals()
	wing.mesh = wst.commit()
	var wskin := _shader(SKIN_SHADER)
	_skins.append(wskin)
	wing.material_override = wskin
	_plane.add_child(wing)
	var nacelle := _mat("#7f868c", 0.5, 0.35)
	var hub := _mat("#2b2d30", 0.4, 0.6)
	var blade := _mat("#1e1f21", 0.5, 0.3)
	var blur_m := _mat("#2a2b2d", 0.6)
	blur_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blur_m.albedo_color = Color(0.12, 0.12, 0.13, 0.32)
	for x in [-10.8, -5.3, 5.3, 10.8]:
		_rod(_plane, Vector3(x, 2.05, -6.6), Vector3(x, 2.15, -1.0), 0.62, nacelle, 18)
		_rod(_plane, Vector3(x, 1.6, -5.0), Vector3(x, 1.65, -2.0), 0.35, nacelle, 12)      # intake below
		var prop := Node3D.new()
		prop.position = Vector3(x, 2.05, -6.85)
		_plane.add_child(prop)
		_rod(prop, Vector3(0, 0, 0.25), Vector3(0, 0, -0.45), 0.32, hub, 14)
		for k in 6:
			var a := TAU * k / 6.0
			var bl := _box(prop, Vector3(0.24, 1.9, 0.05), Vector3(cos(a) * 1.05, sin(a) * 1.05, 0), blade)
			bl.rotation = Vector3(0.25, 0, a - PI * 0.5)
		_props.append(prop)
		var disc := _disc(_plane, 2.05, Vector3(x, 2.05, -6.85), false, blur_m, 0.01)
		_blur.append(disc)
	# Tail: the tall fin with the tricolour flash, the stabiliser.
	var fin := MeshInstance3D.new()
	var fst := SurfaceTool.new()
	fst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fp := [Vector3(-0.18, 2.4, 8.6), Vector3(-0.18, 2.4, 15.2), Vector3(-0.1, 9.0, 13.1), Vector3(-0.1, 9.0, 15.4),
		Vector3(0.18, 2.4, 8.6), Vector3(0.18, 2.4, 15.2), Vector3(0.1, 9.0, 13.1), Vector3(0.1, 9.0, 15.4)]
	for f in [[0, 2, 1, 1, 2, 3], [4, 5, 6, 5, 7, 6], [0, 4, 2, 2, 4, 6], [1, 3, 5, 5, 3, 7], [2, 6, 3, 3, 6, 7]]:
		for o in f:
			fst.add_vertex(fp[o])
	fst.generate_normals()
	fin.mesh = fst.commit()
	var fskin := _shader(SKIN_SHADER)
	_skins.append(fskin)
	fin.material_override = fskin
	_plane.add_child(fin)
	var colours := ["#ff9933", "#f2f2ef", "#138808"]
	for k in 3:
		for sx in [-0.2, 0.2]:
			_box(_plane, Vector3(0.02, 1.3, 0.55), Vector3(sx, 6.3, 13.55 + k * 0.55), _mat(colours[k], 0.6))
	_box(_plane, Vector3(16.0, 0.22, 2.8), Vector3(0, 2.75, 13.6), fskin)
	# Sponsons for the main gear, the wheels, the nose gear.
	var tyre := _mat("#151515", 0.9)
	for sx in [-1.0, 1.0]:
		var sp := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.75
		cap.height = 7.5
		sp.mesh = cap
		sp.material_override = skin
		sp.rotation.x = PI * 0.5
		sp.position = Vector3(sx * 1.95, -1.25, -0.6)
		_plane.add_child(sp)
		for zz in [-1.6, 0.4]:
			_rod(_plane, Vector3(sx * 1.6, -2.27, zz), Vector3(sx * 2.15, -2.27, zz), 0.55, tyre, 20)
	for sx in [-0.2, 0.2]:
		_rod(_plane, Vector3(sx, -2.4, -11.6), Vector3(sx + signf(sx) * 0.28, -2.4, -11.6), 0.42, tyre, 18)
	_rod(_plane, Vector3(0, -2.4, -11.6), Vector3(0, -1.6, -11.6), 0.08, _mat("#a6a9ac", 0.3, 0.8), 8)
	# IAF roundels (saffron, white, green) on the rear fuselage, both sides.
	for sx in [-1.0, 1.0]:
		var rc := ["#ff9933", "#f2f2ef", "#138808"]
		for k in 3:
			_disc(_plane, 0.95 - k * 0.3, Vector3(sx * (2.06 + k * 0.005), 0.75, 7.2), true, _mat(rc[k], 0.6), 0.02)
	_beacon = _lit("#ff2a1a", 6.0)
	_box(_plane, Vector3(0.25, 0.12, 0.4), Vector3(0, 2.55, -1.0), _beacon)
	# The ramp (the lower rear fuselage) on its hinge.
	_ramp = Node3D.new()
	_ramp.position = Vector3(0, RAMP_HINGE.y, RAMP_HINGE.x)
	_plane.add_child(_ramp)
	var rmi := MeshInstance3D.new()
	rmi.mesh = _loft(1.0, true, false)
	rmi.material_override = skin
	_ramp.add_child(rmi)
	var rin := MeshInstance3D.new()
	rin.mesh = _loft(0.95, true, false)
	rin.material_override = _mat("#3a3f3a", 0.9)
	rin.position = Vector3(0, 0.05, 0)
	_ramp.add_child(rin)


# ------------------------------------------------------------------------------ pose

func _plane_state(t: float, land: float, stop: float) -> Array:
	# Returns [z, height of the wheels above the runway, pitch].
	if t < land:
		var u := land - t
		var z := STOP_Z + 6.0 + 62.0 * u
		var y := 20.0 * u + 4.0 * u * u
		return [z, y, -0.05 + 0.06 * Motion.smooth(clampf(1.0 - u * 2.5, 0.0, 1.0))]
	var k := Motion.out_cubic(clampf((t - land) / maxf(stop - land, 0.01), 0.0, 1.0))
	var z := lerpf(STOP_Z + 6.0, STOP_Z, k)
	var bounce := 0.35 * Motion.impact(t - land, 1.0, 4.0, 6.0)
	var dive := 0.035 * Motion.impact(t - stop, 1.0, 3.0, 5.0) if t > stop else 0.0
	return [z, bounce, dive]


func pose(root: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	var land := float(p.get("land", 1.0e9))
	var stop := float(p.get("stop", 1.0e9))
	var ramp_t := float(p.get("ramp", 1.0e9))
	var s: Array = _plane_state(t, land, stop)
	var air := t < land
	_plane.position = Vector3(0, FLOOR_Y + 1.32 + float(s[1]) + (sin(t * 3.1) * 0.12 if air else 0.0), float(s[0]))
	_plane.rotation = Vector3(float(s[2]), 0, sin(t * 1.7) * 0.02 if air else 0.0)
	# Straining: the fuselage sags and the wing tips droop while it carries the rig.
	var strain := 1.0 if air else 1.0 - Motion.smooth(Motion.seg(t, land, land + 0.6))
	for m in _skins:
		(m as ShaderMaterial).set_shader_parameter("sag", 0.22 * strain + 0.04 * sin(t * 5.0) * strain)
		(m as ShaderMaterial).set_shader_parameter("droop", 0.85 * strain + 0.2)
	var spin := t * (34.0 if t < stop + 0.5 else 34.0 - minf((t - stop - 0.5) * 20.0, 26.0))
	for k in _props.size():
		(_props[k] as Node3D).rotation.z = spin * (1.0 if k % 2 == 0 else 1.0) + k
	var fast := t < stop + 0.9
	for d in _blur:
		(d as MeshInstance3D).visible = fast
	for pr in _props:
		for c in (pr as Node3D).get_children():
			if c is MeshInstance3D and (c as MeshInstance3D).mesh is BoxMesh:
				(c as MeshInstance3D).visible = not fast
	_beacon.emission_energy_multiplier = 8.0 if fposmod(t, 1.1) < 0.12 else 0.2
	# The ramp swings down to the runway.
	var open := Motion.out_back(Motion.seg(t, ramp_t, ramp_t + 0.85), 1.2)
	_ramp.rotation.x = 0.6 * open
	var flight := _rig.get_node("flight") as Node3D
	if flight != null:
		flight.rotation.z = 0.0
	var origin: Vector3 = ctx["holder"].global_position
	return {"plane": origin + _plane.position, "rig": origin + _plane.position + Vector3(0, 1.4, -3.0),
		"ramp": origin + _plane.position + Vector3(0, -2.6, 11.5)}
