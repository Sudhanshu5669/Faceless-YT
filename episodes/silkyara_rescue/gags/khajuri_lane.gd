extends RefCounted
## A lane in Khajuri Khas, north-east Delhi (lines 24-26): Vakeel Hasan's house and its demolition.
##
## Local frame: the lane runs along z, 3.6 m wide (x -1.8..1.8), unpaved concrete with a drain on one side. Self-built
## houses of exposed brick and patchy plaster line both sides, 2-3 storeys, steel grilles, a balcony slab, black water
## tanks on the roofs, a tangle of cables overhead. Hasan's house is on the +x side at z 0..5 (two storeys, a blue
## steel door); its front comes down in pieces when the excavator's bucket hits it, leaving a heap of brick, bent
## rebar and the exposed pink room behind. One sodium streetlamp on a pole across the lane.
##
## params:
##   machine  {"t0", "t1" (rolls in), "bites": [t, ...] (each one a swing of the bucket into the front)}
##   held     {actor id: "garland" | "plan"}: what each holds (in the right hand)
##   night    t: from then the street is dark and the lamp is the light
##   sit      {actor id: [x, z, lie]}: the family on the ground (lie 1 = lying down to sleep)
## anchors: house (the middle of its front), lamp, bucket

const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")

const W := 1.8               # half the lane's width
const HOUSE_Z0 := 0.0
const HOUSE_Z1 := 5.0
const STOREY := 3.0
const LAMP_AT := Vector3(-1.55, 0.0, 3.8)

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

## Exposed brick (Delhi's red-orange brick, cement joints) with patches of grey plaster; `plaster` 0..1 how much.
const BRICK_SHADER := """
shader_type spatial;
uniform float plaster = 0.35;
uniform vec3 paint : source_color = vec3(0.78, 0.76, 0.7);
varying vec3 wp;
varying vec3 wn;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }
//NOISE
void fragment() {
	vec2 uv = abs(wn.x) > 0.5 ? wp.zy : wp.xy;
	uv *= vec2(1.0 / 0.23, 1.0 / 0.085);
	uv.x += step(1.0, mod(floor(uv.y), 2.0)) * 0.5;
	vec2 f = fract(uv);
	float joint = 1.0 - step(0.06, f.x) * step(0.1, f.y);
	float id = h3(vec3(floor(uv), 1.0));
	vec3 brick = mix(vec3(0.55, 0.26, 0.17), vec3(0.68, 0.36, 0.22), id) * (0.85 + 0.25 * n3(wp * 6.0));
	vec3 col = mix(brick, vec3(0.62, 0.6, 0.56), joint);
	float pl = smoothstep(1.0 - plaster - 0.05, 1.0 - plaster + 0.05, fbm(wp * 0.45));
	vec3 plaster_col = paint * (0.8 + 0.25 * fbm(wp * 3.0)) * (1.0 - 0.25 * smoothstep(0.5, 0.8, fbm(wp * vec3(2.0, 0.3, 2.0) + 5.0)));
	col = mix(col, plaster_col, pl);
	ALBEDO = col;
	ROUGHNESS = 0.92;
}
"""

const GROUND_SHADER := """
shader_type spatial;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
//NOISE
void fragment() {
	float n = fbm(wp * 0.8);
	vec3 col = mix(vec3(0.4, 0.39, 0.36), vec3(0.3, 0.29, 0.27), n);
	col *= 1.0 - 0.3 * smoothstep(0.62, 0.8, fbm(wp * 2.5 + 3.0));
	ALBEDO = col;
	ROUGHNESS = 0.9;
}
"""

var _shaders := {}
var _panels: Array = []
var _rubble: Node3D
var _room: Node3D
var _ruin: Node3D
var _machine: Node3D
var _boom: Node3D
var _stick: Node3D
var _bucket: Node3D
var _dust: MultiMesh
var _lamp: SpotLight3D
var _lamp_mat: StandardMaterial3D
var _sun_fill: OmniLight3D
var _family_bedding: Node3D
var _props := {}
var _fragments: Array = []


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
	var y := (b - a).normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y, x.cross(y).normalized()), (a + b) * 0.5)
	parent.add_child(mi)
	return mi


func _hash(n: float) -> float:
	return fposmod(sin(n * 127.1 + 311.7) * 43758.5453, 1.0)


## Irregular chunks of masonry, substituted for intact panels only after impact.
func _fragment(seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var v: Array[Vector3] = []
	for y in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			for x in [-1.0, 1.0]:
				v.append(Vector3(x * rng.randf_range(0.07, 0.13), y * rng.randf_range(0.14, 0.26), z * rng.randf_range(0.14, 0.26)))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in [0,2,3, 0,3,1, 4,5,7, 4,7,6, 0,1,5, 0,5,4, 2,6,7, 2,7,3, 0,4,6, 0,6,2, 1,3,7, 1,7,5]:
		st.add_vertex(v[i])
	st.generate_normals()
	return st.commit()


## A neighbour's house front on side s (+1 = +x side), from z0 to z1, n storeys, a paint colour for its plaster.
func _house(root: Node3D, s: float, z0: float, z1: float, n: int, paint: String, plaster: float, seed: int) -> void:
	var wall := _shader(BRICK_SHADER)
	wall.set_shader_parameter("plaster", plaster)
	wall.set_shader_parameter("paint", Color(paint))
	var h := n * STOREY
	var d := 8.0
	var x := s * (W + d * 0.5)
	_box(root, Vector3(d, h, z1 - z0), Vector3(x, h * 0.5, (z0 + z1) * 0.5), wall)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var dark := _mat("#141414", 0.9)
	var grille := _mat("#2b2d2f", 0.5, 0.6)
	var face := s * W
	# Drainpipe, brackets and an electrical junction give each frontage depth.
	var pipe_z := z0 + 0.35
	_rod(root, Vector3(face - s * 0.08, 0.12, pipe_z), Vector3(face - s * 0.08, h - 0.1, pipe_z), 0.035, _mat("#777c78", 0.75), 8)
	for level in range(n):
		_box(root, Vector3(0.1, 0.07, 0.12), Vector3(face - s * 0.08, 1.0 + level * STOREY, pipe_z), grille)
	_box(root, Vector3(0.16, 0.38, 0.29), Vector3(face - s * 0.1, 1.6, z1 - 0.4), _mat("#626864", 0.78))
	for k in n:
		var y0 := k * STOREY
		# A slab edge between storeys.
		_box(root, Vector3(0.25, 0.18, z1 - z0), Vector3(face - s * 0.02, y0 + STOREY - 0.05, (z0 + z1) * 0.5), _mat("#8d8a83", 0.9))
		var nw := maxi(1, int((z1 - z0) / 2.4))
		for w in nw:
			var zc := lerpf(z0, z1, (w + 0.5) / nw)
			if k == 0 and w == 0:
				# A ground-floor shutter or door.
				var col: String = ["#3a6ea5", "#7a3b2e", "#4f6b3a", "#5a5a5a"][rng.randi() % 4]
				_box(root, Vector3(0.06, 2.1, 1.0), Vector3(face - s * 0.03, 1.05, zc), _mat(col, 0.6, 0.4))
				_box(root, Vector3(0.48, 0.07, 1.3), Vector3(face - s * 0.24, 2.25, zc), _mat("#72695b", 0.88))
				continue
			_box(root, Vector3(0.06, 1.1, 1.0), Vector3(face - s * 0.02, y0 + 1.6, zc), dark)
			for b in 6:
				_rod(root, Vector3(face - s * 0.06, y0 + 1.05, zc - 0.45 + b * 0.18), Vector3(face - s * 0.06, y0 + 2.15, zc - 0.45 + b * 0.18), 0.008, grille, 4)
			_box(root, Vector3(0.12, 0.04, 1.1), Vector3(face - s * 0.06, y0 + 2.2, zc), grille)
			if k == 1 and w == 0:
				_box(root, Vector3(0.45, 0.08, 1.25), Vector3(face - s * 0.22, y0 + 0.86, zc), _mat("#8f8e88", 0.9))
				_rod(root, Vector3(face - s * 0.42, y0 + 1.45, zc - 0.58), Vector3(face - s * 0.42, y0 + 1.45, zc + 0.58), 0.018, grille, 6)
				for b in 5:
					_rod(root, Vector3(face - s * 0.42, y0 + 0.9, zc - 0.52 + b * 0.26), Vector3(face - s * 0.42, y0 + 1.45, zc - 0.52 + b * 0.26), 0.01, grille, 5)
	# A black water tank on the roof.
	_rod(root, Vector3(x - s * 2.5, h, (z0 + z1) * 0.5 + 0.6), Vector3(x - s * 2.5, h + 1.1, (z0 + z1) * 0.5 + 0.6), 0.55, _mat("#171717", 0.6), 16)


func build(g: Dictionary) -> Node3D:
	var root := Node3D.new()
	# The lane: concrete with a drain along the -x side, and the ground beyond.
	var gr := _shader(GROUND_SHADER)
	_box(root, Vector3(2.0 * W, 0.1, 80.0), Vector3(0, -0.05, 0), gr)
	_box(root, Vector3(0.3, 0.05, 80.0), Vector3(-W + 0.2, 0.005, 0), _mat("#1f1d1a", 0.4))
	# Neighbours down both sides.
	var z := -38.0
	var i := 0
	while z < 38.0:
		var len := 4.0 + _hash(i * 3.7) * 3.0
		var paints := ["#c9c3b4", "#b8c7c9", "#d6c9a8", "#c7b2b2", "#a9b49a"]
		if not (z < HOUSE_Z1 and z + len > HOUSE_Z0):
			_house(root, 1.0, z, z + len, 2 + int(_hash(i) * 2.0), paints[i % 5], 0.2 + _hash(i * 1.3) * 0.6, i)
		_house(root, -1.0, z, z + len, 2 + int(_hash(i * 2.2) * 2.0), paints[(i + 2) % 5], 0.2 + _hash(i * 2.9) * 0.6, i + 50)
		z += len
		i += 1
	# Hasan's house: the room behind the front (pink walls, a calendar, a shelf), then the front in panels.
	var room := Node3D.new()
	_room = room
	root.add_child(room)
	var pink := _mat("#d9a3a8", 0.9)
	_box(room, Vector3(0.1, 2.0 * STOREY, HOUSE_Z1 - HOUSE_Z0), Vector3(W + 4.0, STOREY, 2.5), pink)
	_box(room, Vector3(4.0, 0.15, HOUSE_Z1 - HOUSE_Z0), Vector3(W + 2.0, STOREY, 2.5), _mat("#8d8a83", 0.9))
	_box(room, Vector3(4.0, 2.0 * STOREY, 0.1), Vector3(W + 2.0, STOREY, HOUSE_Z0), pink)
	_box(room, Vector3(4.0, 2.0 * STOREY, 0.1), Vector3(W + 2.0, STOREY, HOUSE_Z1), pink)
	_box(room, Vector3(0.03, 0.5, 0.36), Vector3(W + 3.93, 1.6, 1.2), _mat("#f1eee6", 0.8))      # a calendar
	_box(room, Vector3(0.3, 0.04, 1.4), Vector3(W + 3.8, 1.7, 3.5), _mat("#6b4a2b", 0.8))         # a shelf
	_box(room, Vector3(0.03, 0.6, 0.45), Vector3(W + 3.93, STOREY + 1.6, 3.0), _mat("#5d7ea8", 0.6)) # a framed picture
	# After the cut, replace the intact room and suspended floor with uneven
	# remnants of a low brick wall. The first demolition shot keeps the intact room.
	_ruin = Node3D.new()
	_ruin.visible = false
	root.add_child(_ruin)
	var ruin_brick := _shader(BRICK_SHADER)
	ruin_brick.set_shader_parameter("plaster", 0.28)
	ruin_brick.set_shader_parameter("paint", Color("#bfa79b"))
	for k in 10:
		var h := 0.72 + _hash(k * 4.7 + 9.0) * 1.15
		_box(_ruin, Vector3(0.18, h, 0.5), Vector3(W + 3.95, h * 0.5, (k + 0.5) * 0.5), ruin_brick)
	for end in [0.0, 5.0]:
		for k in 6:
			var h := 0.45 + _hash(k * 2.1 + end + 21.0) * 1.25
			_box(_ruin, Vector3(0.65, h, 0.17), Vector3(W + 0.32 + k * 0.65, h * 0.5, end), ruin_brick)
	var wall := _shader(BRICK_SHADER)
	wall.set_shader_parameter("plaster", 0.55)
	wall.set_shader_parameter("paint", Color("#e2d6b8"))
	var pw := 0.5
	var ph := 0.5
	for k in 12:
		_fragments.append(_fragment(1031 + k))
	var nz := int((HOUSE_Z1 - HOUSE_Z0) / pw)
	var ny := int(2.0 * STOREY / ph)
	for yy in ny:
		for zz in nz:
			var c := Vector3(W + 0.12, (yy + 0.5) * ph, HOUSE_Z0 + (zz + 0.5) * pw)
			var mat: Material = wall
			# The blue door (ground floor, left), a window with a grille upstairs.
			if yy < 4 and zz >= 1 and zz <= 2:
				mat = _mat("#2f62a6", 0.55, 0.45)
			elif yy >= 7 and yy <= 8 and zz >= 5 and zz <= 7:
				mat = _mat("#121212", 0.9)
			var pnl := _box(root, Vector3(0.24, ph, pw), c, mat)
			if yy >= 7 and yy <= 8 and zz >= 5 and zz <= 7:
				_box(pnl, Vector3(0.035, ph, 0.025), Vector3(-0.13, 0, 0), _mat("#333638", 0.55))
				_box(pnl, Vector3(0.035, 0.025, pw), Vector3(-0.13, 0, 0), _mat("#333638", 0.55))
			elif yy < 4 and zz >= 1 and zz <= 2:
				_box(pnl, Vector3(0.025, ph, 0.018), Vector3(-0.13, 0, 0.15), _mat("#213e5c", 0.65))
			_panels.append({"node": pnl, "mesh": pnl.mesh, "home": c, "row": yy, "col": zz,
				"spin": Vector3(_hash(yy * 7.0 + zz) - 0.5, _hash(yy + zz * 3.0) - 0.5, _hash(yy * 2.0 + zz * 5.0) - 0.5) * 6.0,
				"land": Vector3(c.x - 0.6 - _hash(yy * 1.7 + zz) * 2.2, 0.0, c.z + (_hash(zz * 2.3 + yy) - 0.5) * 1.6)})
	# The rubble heap that is left (grows as the front comes down) and bent rebar sticking out of it.
	_rubble = Node3D.new()
	_rubble.scale = Vector3(1, 0.001, 1)
	root.add_child(_rubble)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2402
	var bm := _mat("#8e4a30", 0.95)
	var cm := _mat("#9a968d", 0.95)
	for k in 70:
		var s := MeshInstance3D.new()
		s.mesh = _fragments[k % _fragments.size()]
		s.material_override = bm if k % 3 else cm
		var sz := rng.randf_range(0.7, 1.5)
		var px := W + rng.randf_range(-1.4, 1.6)
		var pz := rng.randf_range(HOUSE_Z0 - 0.3, HOUSE_Z1 + 0.3)
		var hh := 1.1 * (1.0 - clampf(absf(px - (W + 0.4)) / 2.2, 0.0, 1.0))
		s.transform = Transform3D(Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, 0)).scaled(Vector3(sz, sz * 0.6, sz)),
			Vector3(px, rng.randf_range(0.0, hh), pz))
		_rubble.add_child(s)
	var rebar := _mat("#5a3424", 0.6, 0.6)
	for k in 6:
		var a := Vector3(W + rng.randf_range(-0.2, 1.0), 0.8, rng.randf_range(0.6, 4.4))
		var b := a + Vector3(rng.randf_range(-1.0, 0.4), rng.randf_range(0.6, 1.4), rng.randf_range(-0.6, 0.6))
		_rod(_rubble, a, b, 0.012, rebar, 5)
		_rod(_rubble, b, b + Vector3(rng.randf_range(-0.6, 0.0), rng.randf_range(-0.4, 0.2), rng.randf_range(-0.3, 0.3)), 0.012, rebar, 5)
	# Cables strung across the lane between the houses.
	var cable := _mat("#0d0d0d", 0.6)
	for k in 9:
		var zc := -16.0 + k * 4.3
		var sag := 0.3 + _hash(k * 1.1) * 0.4
		var ya := 5.2 + _hash(k) * 1.2
		var yb := 5.0 + _hash(k * 2.0) * 1.4
		var mid := Vector3(0, minf(ya, yb) - sag, zc + 0.3)
		_rod(root, Vector3(-W, ya, zc), mid, 0.01, cable, 4)
		_rod(root, mid, Vector3(W, yb, zc + 0.6), 0.01, cable, 4)
	# The streetlamp: a steel pole, a bracket, a sodium lantern.
	_rod(root, LAMP_AT, LAMP_AT + Vector3(0, 5.6, 0), 0.06, _mat("#4a4d50", 0.5, 0.6), 8)
	_rod(root, LAMP_AT + Vector3(0, 5.5, 0), LAMP_AT + Vector3(0.9, 5.7, 0), 0.04, _mat("#4a4d50", 0.5, 0.6), 6)
	_lamp_mat = _lit("#ffb15a", 0.3)
	_box(root, Vector3(0.45, 0.12, 0.25), LAMP_AT + Vector3(0.95, 5.62, 0), _lamp_mat)
	_lamp = SpotLight3D.new()
	_lamp.transform = Transform3D(Basis.looking_at(Vector3(0.25, -1.0, 0.05).normalized()), LAMP_AT + Vector3(0.95, 5.5, 0))
	_lamp.light_color = Color("#ffad55")
	_lamp.light_energy = 0.0
	_lamp.spot_range = 12.0
	_lamp.spot_angle = 52.0
	_lamp.shadow_enabled = true
	_lamp.light_volumetric_fog_energy = 1.5
	root.add_child(_lamp)
	# Gentle daylight bounce for the aftermath portrait, kept off in the
	# approved demolition shot and during the later night scene.
	_sun_fill = OmniLight3D.new()
	_sun_fill.position = Vector3(-0.7, 2.4, 6.6)
	_sun_fill.light_color = Color("#ffe4c4")
	_sun_fill.light_energy = 0.0
	_sun_fill.omni_range = 4.0
	_sun_fill.shadow_enabled = false
	root.add_child(_sun_fill)
	# Simple bedding makes contact with the street explicit; it is visual staging,
	# not a claim about the family's specific possessions.
	_family_bedding = Node3D.new()
	_family_bedding.visible = false
	root.add_child(_family_bedding)
	var bedding := _mat("#665957", 0.96)
	_box(_family_bedding, Vector3(2.2, 0.02, 2.7), Vector3(0.0, 0.025, 4.65), bedding)
	_build_machine(root)
	# Dust from the falling front.
	var puff := SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	puff.radial_segments = 8
	puff.rings = 4
	var pm := _mat("#b7a993", 1.0)
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.albedo_color = Color(0.72, 0.66, 0.57, 0.10)
	puff.material = pm
	_dust = MultiMesh.new()
	_dust.transform_format = MultiMesh.TRANSFORM_3D
	_dust.mesh = puff
	_dust.instance_count = 40
	var dmi := MultiMeshInstance3D.new()
	dmi.multimesh = _dust
	dmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(dmi)
	return root


## A tracked excavator (yellow, in the style of the backhoes and excavators Indian demolition drives use): tracks,
## a turntable house with the cab, the boom, the stick and a toothed bucket. Faces +z; the arm swings toward +x.
func _build_machine(root: Node3D) -> void:
	_machine = Node3D.new()
	root.add_child(_machine)
	var yellow := _mat("#e3a71c", 0.5, 0.25)
	var dark := _mat("#1c1d1f", 0.7, 0.4)
	var steel := _mat("#6a6f74", 0.45, 0.7)
	var glass := _mat("#4b6b78", 0.28)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.29, 0.42, 0.47, 0.34)
	for sx in [-0.95, 0.95]:
		_box(_machine, Vector3(0.55, 0.75, 3.6), Vector3(sx, 0.38, 0), dark)
		for k in 6:
			_rod(_machine, Vector3(sx - 0.28, 0.38, -1.5 + k * 0.6), Vector3(sx + 0.28, 0.38, -1.5 + k * 0.6), 0.2, steel, 10)
		# Individual steel shoes make the tracks read as heavy machinery in close-up.
		for k in 18:
			var zz := -1.65 + k * 0.19
			_box(_machine, Vector3(0.59, 0.055, 0.075), Vector3(sx, 0.78, zz), steel)
			_box(_machine, Vector3(0.035, 0.58, 0.075), Vector3(sx + signf(sx) * 0.29, 0.38, zz), steel)
	_box(_machine, Vector3(1.5, 0.3, 1.5), Vector3(0, 0.9, 0), dark)
	var house := Node3D.new()
	house.name = "house"
	house.position = Vector3(0, 1.05, 0)
	_machine.add_child(house)
	_box(house, Vector3(2.3, 1.0, 2.6), Vector3(0, 0.5, -0.4), yellow)
	_box(house, Vector3(0.95, 0.26, 1.1), Vector3(-0.65, 0.99, 0.5), yellow)                # cab sill
	_box(house, Vector3(0.9, 1.0, 0.05), Vector3(-0.65, 1.6, 1.06), glass)
	_box(house, Vector3(0.05, 0.9, 0.9), Vector3(-1.13, 1.6, 0.5), glass)
	for xx in [-1.1, -0.2]:
		_box(house, Vector3(0.06, 1.25, 0.06), Vector3(xx, 1.58, 1.03), dark)
	_box(house, Vector3(1.05, 0.1, 1.2), Vector3(-0.65, 2.25, 0.5), dark)
	_box(house, Vector3(0.06, 0.95, 0.08), Vector3(-0.65, 1.6, 1.1), dark)
	_box(house, Vector3(0.95, 0.07, 0.06), Vector3(-0.65, 1.24, 1.1), dark)
	for k in 7:
		_box(house, Vector3(0.06, 0.48, 0.025), Vector3(0.25 + k * 0.17, 0.58, -1.71), dark)
	_rod(house, Vector3(-1.18, 1.12, 0.0), Vector3(-1.18, 1.12, -1.05), 0.025, dark)
	_box(house, Vector3(2.3, 0.5, 0.6), Vector3(0, 0.6, -1.65), _mat("#2a2b2c", 0.6, 0.5))     # counterweight
	_rod(house, Vector3(0.6, 1.0, -1.2), Vector3(0.6, 1.8, -1.2), 0.06, dark, 8)              # exhaust
	# Boom pivots at the front of the house, stick at its end, bucket at the stick's end.
	_boom = Node3D.new()
	_boom.position = Vector3(0.35, 0.9, 0.9)
	house.add_child(_boom)
	_box(_boom, Vector3(0.35, 0.5, 3.6), Vector3(0, 0, 1.8), yellow)
	_rod(_boom, Vector3(0, -0.35, 0.3), Vector3(0, -0.2, 2.2), 0.08, _mat("#c9ccd0", 0.25, 0.9), 8)   # ram
	for side in [-1.0, 1.0]:
		_rod(_boom, Vector3(side * 0.22, 0.12, 0.25), Vector3(side * 0.22, 0.18, 3.1), 0.035, dark, 7)
	_rod(_boom, Vector3(0.0, -0.42, 0.3), Vector3(0.0, -0.28, 1.45), 0.12, dark, 10)
	_stick = Node3D.new()
	_stick.position = Vector3(0, 0, 3.6)
	_boom.add_child(_stick)
	_box(_stick, Vector3(0.3, 0.38, 2.4), Vector3(0, 0, 1.2), yellow)
	_bucket = Node3D.new()
	_bucket.position = Vector3(0, 0, 2.4)
	_stick.add_child(_bucket)
	_box(_bucket, Vector3(0.9, 0.06, 0.7), Vector3(0, -0.25, 0.3), steel)
	_box(_bucket, Vector3(0.9, 0.6, 0.06), Vector3(0, 0.0, 0.0), steel)
	for sx in [-0.45, 0.45]:
		_box(_bucket, Vector3(0.05, 0.55, 0.7), Vector3(sx, -0.02, 0.3), steel)
	for k in 5:
		_box(_bucket, Vector3(0.08, 0.06, 0.16), Vector3(-0.36 + k * 0.18, -0.26, 0.7), _mat("#c9ccd0", 0.3, 0.85))


func _hold(kind: String) -> Node3D:
	var n := Node3D.new()
	if kind == "garland":
		var marigold := _mat("#f29a12", 0.85)
		var ball := SphereMesh.new()
		ball.radius = 0.035
		ball.height = 0.06
		ball.radial_segments = 8
		ball.rings = 4
		for i in 36:
			var a := TAU * i / 36.0
			var mi := MeshInstance3D.new()
			mi.mesh = ball
			mi.material_override = _mat("#c0261c", 0.8) if i % 7 == 0 else marigold
			mi.position = Vector3(sin(a) * 0.12, -0.32 * (0.5 - 0.5 * cos(a)), cos(a) * 0.04)
			n.add_child(mi)
	elif kind == "plan":
		# Illustrative paperwork: no invented quote, map boundary or official decision text.
		_box(n, Vector3(0.36, 0.48, 0.012), Vector3(0, 0.0, 0), _mat("#6b4a2b", 0.8))
		_box(n, Vector3(0.32, 0.42, 0.004), Vector3(0, -0.01, 0.008), _mat("#f1eee6", 0.85))
		var ink := _mat("#7d8992", 0.85)
		for k in 6:
			_box(n, Vector3(0.22 - (k % 3) * 0.025, 0.004, 0.002), Vector3(-0.02, 0.09 - k * 0.045, 0.0105), ink)
		var lb := Label3D.new()
		lb.text = "DDA"
		lb.font = load("res://fonts/baloo2/Baloo2.ttf")
		lb.font_size = 48
		lb.pixel_size = 0.0012
		lb.outline_size = 0
		lb.modulate = Color("#1c2a4a")
		lb.position = Vector3(0, 0.16, 0.012)
		n.add_child(lb)
	return n


func pose(root: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	var G: Transform3D = root.global_transform
	var Gi := G.affine_inverse()
	# The machine rolls up the lane, swings its arm at the front, bucket by bucket.
	var mp: Dictionary = p.get("machine", {})
	var scene_t := t
	var aftermath := float(p.get("aftermath", 1.0e9))
	_room.visible = scene_t < aftermath
	_ruin.visible = scene_t >= aftermath
	var bites: Array = mp.get("bites", [])
	# A cut to the aftermath advances the destruction, while leaving every frame
	# of the preceding approved demolition shot unchanged.
	if scene_t >= aftermath and not bites.is_empty():
		t = maxf(t, float(bites.back()) + 3.0)
	var k_in := Motion.out_cubic(Motion.seg(t, float(mp.get("t0", 0.0)), float(mp.get("t1", 0.0))))
	_machine.position = Vector3(-0.15, 0.0, lerpf(-16.0, -3.5, k_in))
	_machine.visible = scene_t < aftermath
	var house := _machine.get_node("house") as Node3D
	var op_id := String(mp.get("operator", ""))
	if not op_id.is_empty() and ctx.has("actor"):
		var op = ctx["actor"].call(op_id)
		if op != null:
			op.visible = _machine.visible and scene_t >= float(mp.get("t0", 1.0e9)) and scene_t < float(mp.get("until", 1.0e9))
			if op.visible:
				op.global_transform = house.global_transform * Transform3D(Basis.IDENTITY, Vector3(-0.65, 1.05, 0.45))
	var swing := 0.0       # 0 = arm straight ahead, 1 = swung toward the house and the bucket in the wall
	var down := 0.0
	var fallen_rows := 0.0
	for i in bites.size():
		var tb := float(bites[i])
		var a := Motion.in_out(Motion.seg(t, tb - 0.9, tb - 0.25))
		var hit := Motion.in_cubic(Motion.seg(t, tb - 0.25, tb))
		var back := Motion.in_out(Motion.seg(t, tb + 0.35, tb + 1.0))
		if t > tb - 0.9 and t < tb + 1.0:
			swing = a
			down = hit * (1.0 - back)
		if t >= tb:
			fallen_rows = float(i + 1)
	if bites.size() > 0 and t >= float(bites.back()) + 1.0:
		swing = 1.0
		down = 0.0
	house.rotation.y = 0.29 * swing
	_boom.rotation.x = -0.55 + 0.35 * down
	_stick.rotation.x = 0.95 - 0.5 * down
	_bucket.rotation.x = 0.4 + 0.9 * down
	# Each bite brings down a band of the front from the top; the panels tumble out into the lane and settle.
	for e in _panels:
		var node := e["node"] as Node3D
		var row: int = e["row"]
		# The impact opens the middle of the facade first; neighbouring masonry
		# breaks later instead of an entire perfectly horizontal row falling.
		var col: int = e["col"]
		var distance := absf(float(col) - 6.0) * 0.22 + absf(float(row) - 4.5) * 0.14
		var band := floorf(distance / 0.75)
		var tf := 1.0e9
		if int(band) < bites.size():
			tf = float(bites[int(band)]) + distance * 0.12 + _hash(row * 3.1 + float(col)) * 0.18
		var age := t - tf
		if age <= 0.0:
			node.mesh = e["mesh"]
			node.position = e["home"]
			node.rotation = Vector3.ZERO
			node.visible = true
			continue
		var fall := clampf(age / 0.8, 0.0, 1.0)
		var home: Vector3 = e["home"]
		var land: Vector3 = e["land"]
		node.mesh = _fragments[(row * 7 + col) % _fragments.size()]
		node.position = Vector3(lerpf(home.x, land.x, fall), maxf(home.y * (1.0 - fall * fall) + 0.1, 0.1), lerpf(home.z, land.z, fall))
		node.rotation = (e["spin"] as Vector3) * fall
		node.visible = age < 2.5
	var demolished := clampf(fallen_rows / maxf(bites.size(), 1.0), 0.0, 1.0)
	_rubble.visible = not bites.is_empty() and t >= float(bites[0])
	_rubble.scale = Vector3(1, maxf(Motion.smooth(clampf((t - (float(bites[0]) if bites.size() > 0 else 1.0e9)) / 4.0, 0.0, 1.0)), 0.001), 1)
	# Dust rolling out at each bite.
	for i in _dust.instance_count:
		var tb := float(bites[i % maxi(bites.size(), 1)]) if bites.size() > 0 else 1.0e9
		var age := t - tb - _hash(i * 1.3) * 0.3
		var xf := Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), Vector3.ZERO)
		if age > 0.0 and age < 3.0:
			var dir := Vector3(-0.6 - _hash(i * 2.1), 0.25 + _hash(i * 3.3) * 0.4, (_hash(i * 4.4) - 0.5) * 1.6)
			var pos := Vector3(W + 0.2, 1.0 + _hash(i * 5.5) * 4.0, HOUSE_Z0 + _hash(i * 6.6) * 5.0) + dir * (1.0 - exp(-age * 1.2)) * 3.0
			xf = Transform3D(Basis.from_scale(Vector3.ONE * (0.4 + age * 0.7)), pos)
		_dust.set_instance_transform(i, xf)
	# Night: the lamp comes on.
	var night := t >= float(p.get("night", 1.0e9))
	_sun_fill.light_energy = 0.18 if night and scene_t >= float(p.get("family_from", 1.0e9)) else (0.22 if scene_t >= aftermath and not night else 0.0)
	_lamp.light_energy = 4.5 if night else 0.0
	_lamp_mat.emission_energy_multiplier = 9.0 if night else 0.3
	_family_bedding.visible = scene_t >= float(p.get("family_from", 1.0e9))
	for id in p.get("appear", {}):
		var person = ctx["actor"].call(String(id)) if ctx.has("actor") else null
		if person != null:
			var span: Dictionary = p["appear"][id]
			person.visible = (scene_t >= float(span.get("from", 1.0e9)) and scene_t < float(span.get("until", 1.0e9))) or (scene_t >= float(span.get("again", 1.0e9)) and scene_t < float(span.get("again_until", 1.0e9)))
	# What people hold.
	for id in p.get("held", {}):
		var kind := String(p["held"][id])
		var a = ctx["actor"].call(String(id)) if ctx.has("actor") else null
		if not _props.has(String(id)):
			var n := _hold(kind)
			root.add_child(n)
			_props[String(id)] = n
		var pn := _props[String(id)] as Node3D
		pn.visible = a != null and a.visible
		if not pn.visible:
			continue
		var hd: Vector3 = Gi * (a.anchor_points()[String(id) + ".head"]["pos"] as Vector3)
		var yaw: float = a.rotation.y - root.global_rotation.y
		var fwd := Vector3(sin(yaw), 0, cos(yaw))
		var left := Vector3(cos(yaw), 0, -sin(yaw))
		if kind == "garland":
			# Held up in both hands in front of his chest.
			var at := hd + fwd * 0.42 + Vector3(0, -0.42, 0)
			pn.transform = Transform3D(Basis(Vector3.UP, yaw), at)
			a.aim_hand("l", G * (at + left * 0.13), 1.0)
			a.aim_hand("r", G * (at - left * 0.13), 1.0)
		else:
			var present: Dictionary = p.get("present", {}).get(String(id), {})
			var lift := Motion.smooth(Motion.seg(scene_t, float(present.get("from", 1.0e9)), float(present.get("until", 1.0e9))))
			var at := hd + fwd * 0.38 + Vector3(0, -0.48 + 0.08 * lift, 0) - left * 0.05
			pn.transform = Transform3D(Basis(Vector3.UP, yaw).rotated(left, -0.3), at)
			Crawl.long_arms(a, 1.35)
			a.aim_hand("l", G * (at + left * 0.19 + fwd * 0.06 + Vector3(0, -0.1, 0)), 1.0)
			a.aim_hand("r", G * (at - left * 0.19 + fwd * 0.06 + Vector3(0, -0.1, 0)), 1.0)
	# The family on the ground for the night.
	for id in p.get("sit", {}):
		if scene_t < float(p.get("family_from", 1.0e9)):
			continue
		var a = ctx["actor"].call(String(id)) if ctx.has("actor") else null
		if a == null or not a.visible:
			continue
		var sp: Array = p["sit"][id]
		var lie := float(sp[2])
		if lie > 0.5:
			a.global_transform = Transform3D(G.basis * Basis(Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0)), G * Vector3(float(sp[0]), 0.22, float(sp[1])))
		else:
			a.global_position = G * Vector3(float(sp[0]), 0.0, float(sp[1]))
			a.sit_on_floor(0.24, (G * Vector3.ZERO).y, 0.1)
	# The child slowly nods off beside the family on "slept".
	var sleeping: Dictionary = p.get("sleep", {})
	if not sleeping.is_empty() and ctx.has("actor"):
		var child = ctx["actor"].call(String(sleeping.get("id", "")))
		if child != null and child.visible:
			var x := float(sleeping.get("x", 0.0))
			var z := float(sleeping.get("z", 5.5))
			var settle_sleep := Motion.in_out(Motion.seg(scene_t, float(sleeping.get("at", 1.0e9)) - 0.25, float(sleeping.get("at", 1.0e9)) + 0.35))
			child.global_position = G * Vector3(x, 0.02, z)
			child.sit_on_floor(0.22, (G * Vector3.ZERO).y, 0.05)
			child._pose_head(Vector3(0.18 * settle_sleep, 0.0, -0.22 * settle_sleep))
	return {"house": G * Vector3(W, 3.0, (HOUSE_Z0 + HOUSE_Z1) * 0.5), "lamp": G * (LAMP_AT + Vector3(0.95, 5.5, 0)),
		"bucket": _bucket.global_position}
