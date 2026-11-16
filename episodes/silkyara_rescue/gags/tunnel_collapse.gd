extends RefCounted
## The Silkyara tunnel on the night shift, and the roof coming down between the crew and the way out.
##
## A working bore: sprayed-concrete lining on steel ribs, a ventilation duct, service pipes, site
## lights, a light tower, a dumper driving in, a scaffold crew welding a rib, spoil, stores. Then the
## crown lets go: lining panels peel off, rock pours through, cables arc, the lamps die one after
## another as the dust comes down the bore, and the way out is a wall of rubble.
##
## Local frame: the tunnel runs along Z. -Z is the way out (the portal), +Z is deeper into the
## mountain. The crew works around z = -14..+10. The collapse plugs z = -36..-20.
##
## params:
##   impact    scene time the roof lets go (the word "collapses")
##   alive     scene time the power stutters back (the word "alive")
##   crew      {actor id: {"role", "y" (floor height they stand on), "lamp" (a real headlamp beam),
##             "cower" (seconds after the impact they cover their heads), "rise" (they straighten
##             up again once it is over), "hero" (anchor name)}}
##   trickles  [{"x", "z", "t"}] threads of dust from the crown before the collapse
##   valve     {"z", "open"}: a gate valve on the water main (the +X wall) at z; its handwheel is spun
##             open by the crew member with role "valve" and water bursts out at scene time "open"
##   feed      line 7: air / puffed rice / dry fruit out of the valve's spout into a helmet (see _pose_feed)
##   mats      {"from", "at": [[x, z, yaw], ...]}: flattened cardboard sheets laid on the floor (yoga)
##   crew extras: "until" (hidden from this scene time on), role "yoga" with "yoga": {"start", "pose"
##             ("y" arms up | "tree" + one foot on the other knee | "wobble": tree, sways, falls at "fall")},
##             "from" (hidden before this scene time), "lamp_off" (clicks the headlamp off then;
##             role "lamp_click" reaches up to it)
## anchors: truck, weld, plug, and one per crew member with "hero" (their head).
const KitDB = preload("res://scripts/world/kit_db.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const SiteKitchen = preload("res://scripts/world/site_kitchen.gd")
const TunnelFinish = preload("res://scripts/world/silkyara_tunnel_finish.gd")

const R := 5.0                 # arch radius
const SPRING := 2.3            # height of the side walls, where the arch springs
const Z_EXIT := -88.0
const Z_DEEP := 30.0
const ARC := 32                # cells round the arch
const CZ0 := -36.0             # the stretch of crown that falls
const CZ1 := -20.0
const HOLE0 := 6               # arch cells [HOLE0, HOLE1) fall
const HOLE1 := 26
const PLUG_TOE := -16.5        # where the rubble slope meets the floor
const GRAVITY := 14.0          # a little heavier than real: reads better at 30 fps
const WELD := Vector3(-4.52, 4.2, -6.0)
const DUCT := Vector2(-2.3, 5.75)
const TOWER := Vector3(-3.95, 0.0, -15.2)
const LAMPS := 20

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

## Sprayed concrete / broken rock: lumpy, stained, wet where water runs down it.
const ROCK_SHADER := TunnelFinish.ROCK_SHADER

## The invert: wheel-churned mud with standing water that mirrors the lamps.
const FLOOR_SHADER := TunnelFinish.FLOOR_SHADER

## Dust in the air: a cloud that bursts out of the fall and rolls down the bore behind a billowing
## front, then hangs. Lit by whatever lamps are still burning inside it.
const DUST_SHADER := """
shader_type fog;
uniform vec3 origin;
uniform vec3 color : source_color = vec3(0.33, 0.295, 0.255);
uniform float density = 0.0;
uniform float front = -24.0;
uniform float back = -44.0;
uniform float drift = 0.0;
//NOISE
void fog() {
	vec3 p = WORLD_POSITION - origin;
	float n = fbm(p * 0.42 + vec3(0.0, -drift * 0.22, -drift * 0.7));
	float lead = front + (n - 0.5) * 6.0 - abs(p.y - 1.8) * 0.45;
	float edge = 1.0 - smoothstep(lead - 3.0, lead, p.z);
	float rear = smoothstep(back - 8.0, back, p.z);
	DENSITY = density * edge * rear * (0.5 + n);
	ALBEDO = color;
}
"""

## The rolling face of the dust: lumpy billows, lit from whatever still burns around them.
const PUFF_SHADER := """
shader_type spatial;
uniform vec3 color : source_color = vec3(0.43, 0.39, 0.345);
uniform float drift = 0.0;
varying vec3 wp;
//NOISE
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float n = fbm(w * 0.5 + vec3(0.0, -drift * 0.5, drift * 0.6));
	float m = fbm(w * 1.7 + vec3(3.0, -drift * 0.8, drift * 0.9));
	VERTEX += NORMAL * ((n - 0.35) * 0.5 + (m - 0.4) * 0.28);
	wp = w;
}
void fragment() {
	float n = fbm(wp * 1.4 + vec3(0.0, -drift * 0.5, drift * 0.6));
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = color * (0.74 + n * 0.45) * mix(0.92, 1.35, rim);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	BACKLIGHT = vec3(0.35);
}
"""

var _noise: FastNoiseLite
var _puffs: MultiMesh
var _puff := []
var _puff_mat: ShaderMaterial
var _rock_shader: Shader
var _wall_lights := []      # {"light", "mat", "z", "e", "salt"}
var _tower_spots := []
var _tower_mat: StandardMaterial3D
var _truck: Node3D
var _truck_wheels := []
var _truck_spots := []
var _truck_beam: StandardMaterial3D
var _beacons := []          # {"pivot", "light", "mat", "z" (or null for the truck)}
var _weld_light: OmniLight3D
var _weld_sparks: MultiMesh
var _arc_sparks: MultiMesh
var _arc_lights := []
var _slabs := []            # {"node", "home", "rest", "rel", "axis", "spin"}
var _zone_ribs := []
var _zone_duct: Node3D
var _rocks: MultiMesh
var _rock := []             # per rock: {"s", "from", "rest", "land", "fall", "rot"}
var _plug: Node3D
var _dust: ShaderMaterial
var _floor: ShaderMaterial
var _grains: MultiMesh
var _lamps := []            # pool of SpotLight3D
var _bounce: OmniLight3D
var _lenses := {}
var _props := {}
var _crown_spot: SpotLight3D
var _valve: Node3D
var _wheel: Node3D
var _stream: MeshInstance3D
var _stream_mat: ShaderMaterial
var _spray: MultiMesh
var _puddle: MeshInstance3D
var _valve_z := 0.0
var _mats: Node3D
var _full_power := 1.0e9
var _crown_mat: StandardMaterial3D


# ============================================================================== build

func build(g: Dictionary) -> Node3D:
	var root := Node3D.new()
	_noise = FastNoiseLite.new()
	_noise.seed = 411
	_noise.frequency = 0.31
	_build_tube(root)
	_build_services(root)
	_build_lights(root)
	_build_site(root)
	_build_truck(root)
	_build_crew_props(root, g.get("params", {}))
	_build_valve(root, g.get("params", {}))
	_build_mats(root, g.get("params", {}))
	_build_meal(root, g.get("params", {}))
	_build_scope(root, g.get("params", {}))
	_build_feed(root, g.get("params", {}))
	_build_jars(root, g.get("params", {}))
	_build_collapse(root)
	return root


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


func _rock_mat(tint: String, bump: float, wet: float, scale: float = 1.0) -> ShaderMaterial:
	if _rock_shader == null:
		_rock_shader = Shader.new()
		_rock_shader.code = ROCK_SHADER.replace("//NOISE", NOISE_GLSL)
	var m := ShaderMaterial.new()
	m.shader = _rock_shader
	m.set_shader_parameter("tint", Color(tint))
	m.set_shader_parameter("bump", bump)
	m.set_shader_parameter("wet", wet)
	m.set_shader_parameter("scale", scale)
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


## A cylinder between two points (pipes, poles, braces, hoses).
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


func _step(edge: float, x: float) -> float:
	return 1.0 if x >= edge else 0.0


func _hash(n: float) -> float:
	return fposmod(sin(n * 127.1 + 3.7) * 43758.5453, 1.0)


# ------------------------------------------------------------------------------ the bore

## A point of the lining: col 0 = foot of the +X wall, 1..ARC+1 round the arch, ARC+2 = foot of the
## -X wall. The sprayed surface wanders a few centimetres.
func _lining(col: int, z: float, out: float = 0.0) -> Vector3:
	var wob := _noise.get_noise_2d(col * 1.7, z * 0.6) * 0.07 + out
	if col <= 0:
		return Vector3(R + wob, 0.0, z)
	if col >= ARC + 2:
		return Vector3(-R - wob, 0.0, z)
	var th := float(col - 1) / ARC * PI
	return Vector3(cos(th) * (R + wob), SPRING + sin(th) * (R + wob), z)


## The lining over cells [c0, c1) x [z0, z1) (1 m rows); `skip` leaves the falling crown out.
## thick > 0 makes a free-standing panel (back face and edges), relative to `origin`.
func _shell(c0: int, c1: int, z0: float, z1: float, skip: bool, thick: float = 0.0, origin: Vector3 = Vector3.ZERO, hollow: bool = false) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := roundi(z1 - z0)
	for row in rows:
		var z := z0 + row
		for c in range(c0, c1):
			if skip and z >= CZ0 and z < CZ1 and c - 1 >= HOLE0 and c - 1 < HOLE1:
				continue
			var a := _lining(c, z) - origin
			var b := _lining(c + 1, z) - origin
			var cc := _lining(c, z + 1.0) - origin
			var d := _lining(c + 1, z + 1.0) - origin
			if not hollow:
				for v in [a, b, cc, b, d, cc]:
					st.add_vertex(v)
			if thick > 0.0:
				var a2 := _lining(c, z, thick) - origin
				var b2 := _lining(c + 1, z, thick) - origin
				var c2 := _lining(c, z + 1.0, thick) - origin
				var d2 := _lining(c + 1, z + 1.0, thick) - origin
				for v in [a2, c2, b2, b2, c2, d2]:
					st.add_vertex(v)
				if row == 0:
					for v in [a, a2, b, b, a2, b2]:
						st.add_vertex(v)
				if row == rows - 1:
					for v in [cc, d, c2, d, d2, c2]:
						st.add_vertex(v)
				if c == c0:
					for v in [a, cc, a2, cc, c2, a2]:
						st.add_vertex(v)
				if c == c1 - 1:
					for v in [b, b2, d, d, b2, d2]:
						st.add_vertex(v)
	st.index()
	st.generate_normals()
	return st.commit()


func _build_tube(root: Node3D) -> void:
	var lining := _rock_mat("#65615b", 1.0, 1.0)
	var tube := MeshInstance3D.new()
	tube.name = "lining"
	tube.mesh = _shell(0, ARC + 2, Z_EXIT, Z_DEEP, true)
	tube.material_override = lining
	tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(tube)
	# What is behind the lining where it falls: black rock, so the hole is a hole.
	var void_mat := _mat("#0b0908", 1.0)
	void_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cavity := MeshInstance3D.new()
	cavity.name = "cavity"
	cavity.mesh = _shell(HOLE0 + 1, HOLE1 + 1, CZ0, CZ1, false, 2.6, Vector3.ZERO, true)
	cavity.material_override = _rock_mat("#2b2622", 2.0, 0.0, 1.4)
	cavity.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(cavity)
	for z in [Z_EXIT - 0.2, Z_DEEP + 0.2]:
		_box(root, Vector3(2.0 * R + 2.0, 10.0, 0.3), Vector3(0, 4.5, z), void_mat)

	var sh := Shader.new()
	sh.code = FLOOR_SHADER.replace("//NOISE", NOISE_GLSL)
	_floor = ShaderMaterial.new()
	_floor.shader = sh
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.0 * R + 0.4, Z_DEEP - Z_EXIT)
	plane.subdivide_depth = 8
	var invert := MeshInstance3D.new()
	invert.name = "invert"
	invert.mesh = plane
	invert.material_override = _floor
	invert.position = Vector3(0, 0.0, (Z_EXIT + Z_DEEP) * 0.5)
	invert.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(invert)
	# A cast kerb and drain down the -X side.
	var kerb := _rock_mat("#6a6660", 0.6, 0.4)
	_box(root, Vector3(0.5, 0.22, Z_DEEP - Z_EXIT), Vector3(-R + 0.3, 0.11, (Z_EXIT + Z_DEEP) * 0.5), kerb)


## One steel arch rib (an I-section following the lining), built round z = 0.
func _rib_mesh() -> ArrayMesh:
	return TunnelFinish.rib_mesh(R, SPRING, ARC)


func _build_services(root: Node3D) -> void:
	# Steel ribs every 2 m. The ones under the falling crown are separate: they come down with it.
	var steel := _mat("#3d3531", 0.62, 0.55)
	steel.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rib := _rib_mesh()
	var zs := []
	var z := Z_EXIT + 2.0
	while z < Z_DEEP:
		if z > CZ0 - 0.5 and z < CZ1 + 0.5:
			var node := MeshInstance3D.new()
			node.mesh = rib
			node.material_override = steel
			node.position = Vector3(0, 0, z)
			root.add_child(node)
			_zone_ribs.append(node)
		else:
			zs.append(z)
		z += 2.0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = rib
	mm.instance_count = zs.size()
	for i in zs.size():
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(0, 0, zs[i])))
	var ribs := MultiMeshInstance3D.new()
	ribs.name = "ribs"
	ribs.multimesh = mm
	ribs.material_override = steel
	ribs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ribs)

	# Ventilation duct: a fat yellow fabric tube slung under the crown, ribbed every metre and a half.
	var fabric := _mat("#c9981f", 0.78)
	var band := _mat("#8a6a17", 0.7)
	var hanger := _mat("#2b2a29", 0.6, 0.5)
	for part in [[Z_EXIT, CZ0], [CZ1, Z_DEEP]]:
		var a := Vector3(DUCT.x, DUCT.y, part[0])
		var b := Vector3(DUCT.x, DUCT.y, part[1])
		_rod(root, a, b, 0.62, fabric, 20).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_zone_duct = Node3D.new()
	_zone_duct.name = "torn_duct"
	_zone_duct.position = Vector3(DUCT.x, DUCT.y, CZ1)
	root.add_child(_zone_duct)
	_rod(_zone_duct, Vector3.ZERO, Vector3(0, 0, CZ0 - CZ1), 0.62, fabric, 20)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.6
	ring.outer_radius = 0.68
	ring.rings = 20
	ring.ring_segments = 6
	var rings := []
	z = Z_EXIT + 1.0
	while z < Z_DEEP:
		if z < CZ0 or z > CZ1:
			rings.append(z)
		z += 1.5
	var rm := MultiMesh.new()
	rm.transform_format = MultiMesh.TRANSFORM_3D
	rm.mesh = ring
	rm.instance_count = rings.size()
	var hm := MultiMesh.new()
	hm.transform_format = MultiMesh.TRANSFORM_3D
	var strap := BoxMesh.new()
	strap.size = Vector3(0.04, 1.0, 0.04)
	hm.mesh = strap
	hm.instance_count = rings.size()
	var top := SPRING + sqrt(R * R - DUCT.x * DUCT.x)
	for i in rings.size():
		rm.set_instance_transform(i, Transform3D(Basis.from_euler(Vector3(PI / 2, 0, 0)), Vector3(DUCT.x, DUCT.y, rings[i])))
		var drop := top - DUCT.y - 0.55
		hm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(1, drop, 1)), Vector3(DUCT.x, DUCT.y + 0.6 + drop * 0.5, rings[i])))
	for pair in [[rm, band], [hm, hanger]]:
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = pair[0]
		mi.material_override = pair[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)

	# +X wall: water and compressed-air mains on brackets. -X wall: a cable tray.
	var main := _mat("#4d5258", 0.45, 0.7)
	var blue := _mat("#2c4f73", 0.5, 0.4)
	_rod(root, Vector3(R - 0.32, 0.95, Z_EXIT), Vector3(R - 0.32, 0.95, Z_DEEP), 0.11, main)
	_rod(root, Vector3(R - 0.28, 1.32, Z_EXIT), Vector3(R - 0.28, 1.32, Z_DEEP), 0.07, blue)
	var cable := _mat("#141414", 0.6)
	for i in 3:
		_rod(root, Vector3(-R + 0.16, 2.05 + i * 0.07, Z_EXIT), Vector3(-R + 0.16, 2.05 + i * 0.07, Z_DEEP), 0.022, cable, 6)
	var bm := MultiMesh.new()
	bm.transform_format = MultiMesh.TRANSFORM_3D
	var bracket := BoxMesh.new()
	bracket.size = Vector3(0.5, 0.05, 0.06)
	bm.mesh = bracket
	var n := int((Z_DEEP - Z_EXIT) / 4.0)
	bm.instance_count = n * 3
	for i in n:
		var bz := Z_EXIT + 1.0 + i * 4.0
		bm.set_instance_transform(i * 3, Transform3D(Basis.IDENTITY, Vector3(R - 0.26, 0.82, bz)))
		bm.set_instance_transform(i * 3 + 1, Transform3D(Basis.IDENTITY, Vector3(R - 0.26, 1.23, bz)))
		bm.set_instance_transform(i * 3 + 2, Transform3D(Basis.IDENTITY.scaled(Vector3(0.6, 1, 1)), Vector3(-R + 0.16, 1.99, bz)))
	var brackets := MultiMeshInstance3D.new()
	brackets.multimesh = bm
	brackets.material_override = hanger
	root.add_child(brackets)


# ------------------------------------------------------------------------------ light

func _wall_light(root: Node3D, x: float, z: float, color: String, energy: float, real: bool) -> void:
	var side := signf(x)
	var mat := _lit(color, 6.0)
	var at := Vector3(x, 3.05, z)
	_box(root, Vector3(0.12, 0.24, 0.62), at, _mat("#26282b", 0.5, 0.5))
	var lens := _box(root, Vector3(0.05, 0.19, 0.56), at - Vector3(side * 0.07, 0, 0), mat)
	lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lamp: OmniLight3D = null
	if real:
		lamp = OmniLight3D.new()
		lamp.position = at - Vector3(side * 0.55, 0.15, 0)
		lamp.light_color = Color(color)
		lamp.light_energy = energy
		lamp.omni_range = 13.0
		lamp.omni_attenuation = 1.1
		lamp.light_volumetric_fog_energy = 1.6
		lamp.light_specular = 1.0
		root.add_child(lamp)
	_wall_lights.append({"light": lamp, "mat": mat, "z": z, "e": energy, "salt": _wall_lights.size() * 1.7})


func _build_lights(root: Node3D) -> void:
	# Sodium floods down the +X wall every 8 m, cooler tubes down the -X wall between them.
	var z := 20.0
	while z > Z_EXIT + 4.0:
		_wall_light(root, R - 0.12, z, "#ffab5c", 3.0, z > -50.0)
		z -= 8.0
	z = 16.0
	while z > Z_EXIT + 4.0:
		_wall_light(root, -R + 0.12, z, "#e3ecff", 1.1, z > -34.0)
		z -= 16.0

	# A diesel light tower near the working end, aimed back up the bore: it backlights the crew.
	var yellow := _mat("#d0a11c", 0.55, 0.2)
	var dark := _mat("#232426", 0.55, 0.5)
	_box(root, Vector3(1.0, 0.95, 1.7), TOWER + Vector3(0, 0.62, 0), yellow)
	_box(root, Vector3(1.04, 0.2, 1.74), TOWER + Vector3(0, 0.2, 0), dark)
	for wz in [-0.55, 0.55]:
		for wx in [-0.56, 0.56]:
			var wheel := _rod(root, TOWER + Vector3(wx - 0.07, 0.24, wz), TOWER + Vector3(wx + 0.07, 0.24, wz), 0.24, dark, 14)
			wheel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rod(root, TOWER + Vector3(0, 1.0, 0.4), TOWER + Vector3(0, 5.1, 0.4), 0.06, dark)
	_rod(root, TOWER + Vector3(-0.7, 5.05, 0.4), TOWER + Vector3(0.7, 5.05, 0.4), 0.04, dark)
	_tower_mat = _lit("#eaf2ff", 9.0)
	var target := Vector3(0.8, 0.6, -3.0)
	for i in 2:
		var head := TOWER + Vector3(-0.42 + i * 0.84, 5.0, 0.52)
		var aim := _aim(target + Vector3(i * 1.6 - 0.8, 0, i * 3.0) - head)
		var case := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(0.5, 0.36, 0.16)
		case.mesh = cm
		case.material_override = dark
		case.transform = Transform3D(aim, head)
		root.add_child(case)
		var lens := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.44, 0.3, 0.03)
		lens.mesh = lm
		lens.material_override = _tower_mat
		lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lens.transform = Transform3D(aim, head + aim * Vector3(0, 0, -0.09))
		root.add_child(lens)
		var spot := SpotLight3D.new()
		spot.transform = Transform3D(aim, head + aim * Vector3(0, 0, -0.14))
		spot.light_color = Color("#cfe0ff")
		spot.light_energy = 8.0
		spot.spot_range = 30.0
		spot.spot_angle = 34.0
		spot.spot_attenuation = 0.8
		spot.shadow_enabled = i == 0
		spot.light_volumetric_fog_energy = 2.2
		root.add_child(spot)
		_tower_spots.append(spot)

	# A stand light at the working end, turned up at the crown they were checking.
	var stand := Vector3(0.9, 0.0, CZ1 + 4.2)
	for k in 3:
		var ang := k * TAU / 3.0
		_rod(root, stand + Vector3(cos(ang) * 0.45, 0.02, sin(ang) * 0.45), stand + Vector3(0, 0.75, 0), 0.016, dark, 6)
	_rod(root, stand + Vector3(0, 0.7, 0), stand + Vector3(0, 1.75, 0), 0.02, dark, 8)
	_crown_mat = _lit("#fff0cf", 8.0)
	var up := _aim(Vector3(-0.5, 7.0, CZ1 - 3.5) - (stand + Vector3(0, 1.8, 0)))
	var head := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(0.42, 0.28, 0.12)
	head.mesh = hm
	head.material_override = yellow
	head.transform = Transform3D(up, stand + Vector3(0, 1.8, 0))
	root.add_child(head)
	var face := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(0.36, 0.22, 0.02)
	face.mesh = fm
	face.material_override = _crown_mat
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	face.transform = Transform3D(up, stand + Vector3(0, 1.8, 0) + up * Vector3(0, 0, -0.07))
	root.add_child(face)
	_crown_spot = SpotLight3D.new()
	_crown_spot.transform = Transform3D(up, stand + Vector3(0, 1.8, 0) + up * Vector3(0, 0, -0.12))
	_crown_spot.light_color = Color("#ffe9c2")
	_crown_spot.light_energy = 11.0
	_crown_spot.spot_range = 20.0
	_crown_spot.spot_angle = 44.0
	_crown_spot.spot_attenuation = 0.6
	_crown_spot.light_volumetric_fog_energy = 1.8
	root.add_child(_crown_spot)


# ------------------------------------------------------------------------------ the site

## A lumpy stone, flat-shaded, radius about 0.5.
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


func _build_site(root: Node3D) -> void:
	var steel := _mat("#55585c", 0.5, 0.75)
	var galv := _mat("#7d8185", 0.42, 0.8)
	var plank := _mat("#6a5138", 0.9)
	var dark := _mat("#222325", 0.6, 0.4)

	# Rolling scaffold tower under the rib being welded (-X side).
	var sc := Vector3(-3.45, 0, WELD.z)
	var legs := []
	for sx in [-0.95, 0.95]:
		for sz in [-0.9, 0.9]:
			legs.append(sc + Vector3(sx, 0.16, sz))
			_rod(root, sc + Vector3(sx, 0.16, sz), sc + Vector3(sx, 4.25, sz), 0.03, galv, 8)
			var castor := _rod(root, sc + Vector3(sx - 0.04, 0.09, sz), sc + Vector3(sx + 0.04, 0.09, sz), 0.09, dark, 10)
			castor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for y in [0.45, 1.65, 3.15, 3.7, 4.22]:
		for sz in [-0.9, 0.9]:
			_rod(root, sc + Vector3(-0.95, y, sz), sc + Vector3(0.95, y, sz), 0.022, galv, 6)
		for sx in [-0.95, 0.95]:
			if sx < 0.0 and y > 3.2:
				continue    # open toward the wall they are working on
			_rod(root, sc + Vector3(sx, y, -0.9), sc + Vector3(sx, y, 0.9), 0.022, galv, 6)
	for k in [[0.45, 1.65], [1.65, 3.15]]:
		_rod(root, sc + Vector3(-0.95, k[0], -0.9), sc + Vector3(0.95, k[1], -0.9), 0.018, galv, 6)
		_rod(root, sc + Vector3(0.95, k[0], 0.9), sc + Vector3(-0.95, k[1], 0.9), 0.018, galv, 6)
	for i in 4:
		_box(root, Vector3(0.46, 0.05, 1.86), sc + Vector3(-0.72 + i * 0.48, 3.2, 0), plank)
	for i in 2:
		_box(root, Vector3(0.46, 0.05, 1.86), sc + Vector3(-0.24 + i * 0.48, 1.7, 0), plank)
	for i in 10:   # ladder on the aisle side
		_rod(root, sc + Vector3(0.99, 0.5 + i * 0.3, 0.25), sc + Vector3(0.99, 0.5 + i * 0.3, 0.7), 0.014, galv, 6)
	_box(root, Vector3(0.42, 0.42, 0.62), sc + Vector3(0.35, 3.44, 0.5), _mat("#b5341f", 0.5, 0.2))   # welding set

	# Stacked pipe by the +X wall near the camera end: where the tea break happens.
	var pipe := _mat("#5b6066", 0.48, 0.7)
	var bore := _mat("#101112", 0.9)
	for i in 3:
		var a := Vector3(3.22 + i * 0.3, 0.15, 2.4)
		_rod(root, a, a + Vector3(0, 0, 4.6), 0.15, pipe, 16)
		_rod(root, a + Vector3(0, 0, 4.6), a + Vector3(0, 0, 4.605), 0.125, bore, 16)
	for i in 2:
		var a := Vector3(3.37 + i * 0.3, 0.41, 2.4)
		_rod(root, a, a + Vector3(0, 0, 4.6), 0.15, pipe, 16)
		_rod(root, a + Vector3(0, 0, 4.6), a + Vector3(0, 0, 4.605), 0.125, bore, 16)
	for pz in [3.0, 6.4]:
		_box(root, Vector3(1.2, 0.07, 0.1), Vector3(3.52, 0.035, pz), plank)

	# Spoil heap on the +X side, cement bags, drums, gas bottles, reinforcement, cones.
	var spoil := _rock_mat("#4a4139", 1.6, 0.3, 2.0)
	var stones := [_stone_mesh(5, 0.5), _stone_mesh(9, 0.7), _stone_mesh(14, 0.4)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 2311
	var heap := MultiMesh.new()
	heap.transform_format = MultiMesh.TRANSFORM_3D
	heap.mesh = stones[0]
	heap.instance_count = 70
	for i in 70:
		var big := i < 9
		var ang := rng.randf() * TAU
		var rad := rng.randf() * (1.3 if big else 2.3)
		var s := rng.randf_range(1.4, 2.4) if big else rng.randf_range(0.18, 0.7)
		var y := maxf(0.0, 0.75 - rad * 0.36) * (0.5 if big else 1.0) + s * 0.2
		var at := Vector3(3.25 + cos(ang) * rad * 0.62, y, -9.5 + sin(ang) * rad)
		heap.set_instance_transform(i, Transform3D(Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, 0)).scaled(Vector3(s, s * 0.62, s)), at))
	var heap_mi := MultiMeshInstance3D.new()
	heap_mi.multimesh = heap
	heap_mi.material_override = spoil
	root.add_child(heap_mi)

	var bag := _mat("#a89a80", 0.92)
	for i in 14:
		var layer := i / 4
		var bx := -3.9 + (i % 2) * 0.66 + (0.33 if layer % 2 == 1 and i % 4 > 1 else 0.0)
		var bz := 1.4 + ((i % 4) / 2) * 0.46
		var b := _box(root, Vector3(0.62, 0.15, 0.42), Vector3(bx, 0.3 + layer * 0.155, bz), bag)
		b.rotation.y = (rng.randf() - 0.5) * 0.25
	_box(root, Vector3(1.5, 0.14, 1.1), Vector3(-3.57, 0.07, 1.63), plank)   # the pallet under them

	var drum_blue := _mat("#27507a", 0.5, 0.3)
	var drum_rust := _mat("#7a4326", 0.75, 0.3)
	for d in [[4.1, -1.4, drum_blue], [3.55, -1.75, drum_blue], [4.15, -2.3, drum_rust], [-4.2, -11.0, drum_blue], [-4.15, -11.7, drum_rust]]:
		_rod(root, Vector3(d[0], 0, d[1]), Vector3(d[0], 0.9, d[1]), 0.29, d[2], 18)
	for i in 3:   # oxygen / acetylene bottles chained to the wall
		_rod(root, Vector3(-4.45, 0, -3.6 - i * 0.3), Vector3(-4.45, 1.35, -3.6 - i * 0.3), 0.115, _mat("#8b1f1b" if i == 1 else "#1d2a3a", 0.4, 0.5), 12)
	var rebar := _mat("#5a3a2c", 0.7, 0.6)
	for i in 14:
		var rx := -4.3 + (i % 5) * 0.07 + rng.randf() * 0.02
		_rod(root, Vector3(rx, 0.05 + (i / 5) * 0.06, -13.2), Vector3(rx + rng.randf_range(-0.05, 0.05), 0.05 + (i / 5) * 0.06, -8.2), 0.016, rebar, 5)
	for c in [[1.9, -4.5], [1.95, -7.5], [2.0, -11.5], [-1.9, 0.6], [-1.95, -2.6], [2.3, 1.2]]:
		var cone := KitDB.static_node("kenney_cars/cone", 1.25)
		cone.position = Vector3(c[0], 0, c[1])
		root.add_child(cone)
	# Loose stones and offcuts along both walls.
	var litter := MultiMesh.new()
	litter.transform_format = MultiMesh.TRANSFORM_3D
	litter.mesh = stones[1]
	litter.instance_count = 160
	for i in 160:
		var side := -1.0 if i % 2 == 0 else 1.0
		var s := rng.randf_range(0.06, 0.28)
		var at := Vector3(side * rng.randf_range(3.4, 4.75), s * 0.25, rng.randf_range(Z_EXIT + 20.0, Z_DEEP - 2.0))
		litter.set_instance_transform(i, Transform3D(Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, 0)).scaled(Vector3(s, s * 0.7, s)), at))
	var litter_mi := MultiMeshInstance3D.new()
	litter_mi.multimesh = litter
	litter_mi.material_override = spoil
	litter_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(litter_mi)


# ------------------------------------------------------------------------------ the dumper

func _build_truck(root: Node3D) -> void:
	_truck = Node3D.new()
	_truck.name = "dumper"
	root.add_child(_truck)
	# Majadroid's dumper (CC0), the same machine seen driving in outside. Cab toward +Z.
	_truck.add_child(KitDB.static_node("majadroid_construction/Trucks#Dumper Truck Red", 0.82))
	_truck_beam = _lit("#fff2d6", 14.0)
	for sx in [-1.0, 1.0]:
		var lens := _box(_truck, Vector3(0.3, 0.16, 0.05), Vector3(sx * 0.85, 0.95, 2.9), _truck_beam)
		lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var spot := SpotLight3D.new()
		spot.transform = Transform3D(_aim(Vector3(sx * 0.04, -0.04, 1.0)), Vector3(sx * 0.85, 0.95, 3.0))
		spot.light_color = Color("#fff0d0")
		spot.light_energy = 13.0
		spot.spot_range = 34.0
		spot.spot_angle = 24.0
		spot.spot_attenuation = 0.7
		spot.shadow_enabled = sx < 0.0
		spot.light_volumetric_fog_energy = 1.6
		_truck.add_child(spot)
		_truck_spots.append(spot)
	_beacon(_truck, Vector3(0, 2.62, 2.0), null)


## An amber rotating beacon.
func _beacon(parent: Node3D, at: Vector3, z) -> void:
	var mat := _lit("#ff9a1f", 5.0)
	_rod(parent, at, at + Vector3(0, 0.16, 0), 0.085, mat, 10).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pivot := Node3D.new()
	pivot.position = at + Vector3(0, 0.1, 0)
	parent.add_child(pivot)
	var spot := SpotLight3D.new()
	spot.rotation.x = -0.12
	spot.light_color = Color("#ff9416")
	spot.light_energy = 5.0
	spot.spot_range = 13.0
	spot.spot_angle = 42.0
	spot.light_volumetric_fog_energy = 2.0
	pivot.add_child(spot)
	_beacons.append({"pivot": pivot, "light": spot, "mat": mat, "z": z})


# ------------------------------------------------------------------------------ what the crew holds

func _build_crew_props(root: Node3D, p: Dictionary) -> void:
	var steel := _mat("#6b7075", 0.4, 0.8)
	var dark := _mat("#1b1c1e", 0.7, 0.3)
	var crew: Dictionary = p.get("crew", {})
	for id in crew:
		var role := String(crew[id].get("role", ""))
		var prop: Node3D = null
		match role:
			"barrow":
				prop = Node3D.new()
				var tray := _box(prop, Vector3(0.62, 0.24, 0.86), Vector3(0, 0.5, 0.42), _mat("#2f6b3a", 0.6, 0.3))
				tray.rotation.x = -0.1
				var muck := MeshInstance3D.new()
				muck.mesh = _stone_mesh(77, 0.5)
				muck.material_override = _rock_mat("#4a4139", 1.6, 0.2, 2.5)
				muck.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(0.58, 0.36, 0.8)), Vector3(0, 0.63, 0.44))
				prop.add_child(muck)
				_rod(prop, Vector3(-0.045, 0.2, 0.92), Vector3(0.045, 0.2, 0.92), 0.2, dark, 16)
				for sx in [-1.0, 1.0]:
					_rod(prop, Vector3(sx * 0.27, 0.6, -0.42), Vector3(sx * 0.2, 0.36, 0.45), 0.018, steel, 6)
					_rod(prop, Vector3(sx * 0.2, 0.36, 0.45), Vector3(sx * 0.06, 0.2, 0.92), 0.018, steel, 6)
					_rod(prop, Vector3(sx * 0.24, 0.42, 0.05), Vector3(sx * 0.24, 0.0, 0.0), 0.016, steel, 6)
			"pipe_a":
				prop = Node3D.new()
				_rod(prop, Vector3(0, 0, -1.9), Vector3(0, 0, 1.9), 0.055, steel, 10)
			"chai":
				prop = Node3D.new()
				_rod(prop, Vector3(0, 0, 0), Vector3(0, 0.13, 0), 0.05, _mat("#c3c8cb", 0.2, 0.9), 16)
				_rod(prop, Vector3(0, 0.124, 0), Vector3(0, 0.133, 0), 0.044, _mat("#a8632e", 0.3), 16)
			"engineer":
				prop = Node3D.new()
				_box(prop, Vector3(0.25, 0.34, 0.015), Vector3.ZERO, _mat("#6d4a2a", 0.8))
				_box(prop, Vector3(0.21, 0.29, 0.005), Vector3(0, -0.01, 0.01), _mat("#e9e5d8", 0.9))
			"welder":
				prop = Node3D.new()
				_rod(prop, Vector3(0, 0, 0), Vector3(0, 0, -0.26), 0.014, dark, 6)
			"sprayer":
				prop = Node3D.new()
				_rod(prop, Vector3(0, 0, -0.3), Vector3(0, 0, 0.5), 0.04, dark, 8)
				_rod(prop, Vector3(0, 0, 0.5), Vector3(0, 0, 0.62), 0.028, steel, 8)
			"bag":
				prop = Node3D.new()
				_box(prop, Vector3(0.6, 0.16, 0.4), Vector3.ZERO, _mat("#a89a80", 0.92))
		if prop != null:
			prop.name = "prop_" + String(id)
			root.add_child(prop)
			_props[id] = prop
	# Headlamp beams for the crew members that get a real light, and the fill their beams
	# throw back off the dust and the rock.
	for i in LAMPS:
		var spot := SpotLight3D.new()
		spot.light_color = Color("#fff1d2")
		spot.spot_range = 16.0
		spot.spot_angle = 17.0
		spot.spot_attenuation = 0.9
		spot.light_volumetric_fog_energy = 0.9
		spot.light_energy = 0.0
		root.add_child(spot)
		_lamps.append(spot)
	_bounce = OmniLight3D.new()
	_bounce.light_color = Color("#d8c4a6")
	_bounce.omni_range = 16.0
	_bounce.omni_attenuation = 0.6
	_bounce.light_energy = 0.0
	_bounce.light_volumetric_fog_energy = 0.0
	_bounce.light_specular = 0.0
	root.add_child(_bounce)


# ------------------------------------------------------------------------------ the fall

## Height of the rubble where it comes to rest.
func _plug_h(x: float, z: float) -> float:
	var top := SPRING + sqrt(maxf(R * R - x * x, 0.0)) + 0.5
	var slope := (PLUG_TOE - z) * 0.8
	var n := _noise.get_noise_2d(x * 3.3 + 40.0, z * 3.3) * 0.45 + _noise.get_noise_2d(x * 0.9, z * 0.9 + 70.0) * 0.5
	return clampf(slope + n * clampf(slope, 0.0, 1.0), 0.0, top)


func _build_collapse(root: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5233
	# Lining panels over the falling stretch: 5 round the crown x 8 along the bore.
	var lining := _rock_mat("#65615b", 1.0, 1.0)
	var centre_z := (CZ0 + CZ1) * 0.5 + 3.0
	for pj in 8:
		for pi in 5:
			var c0 := HOLE0 + 1 + pi * 4
			var z0 := CZ0 + pj * 2.0
			var home := (_lining(c0, z0) + _lining(c0 + 4, z0 + 2.0)) * 0.5
			home.y = (_lining(c0 + 2, z0 + 1.0)).y
			var slab := MeshInstance3D.new()
			slab.mesh = _shell(c0, c0 + 4, z0, z0 + 2.0, false, 0.3, home)
			slab.material_override = lining
			slab.position = home
			root.add_child(slab)
			var rest_z := home.z + rng.randf_range(0.5, 3.5)
			var rest_x := home.x * rng.randf_range(0.5, 0.95)
			_slabs.append({"node": slab, "home": home,
				"rest": Vector3(rest_x, _plug_h(rest_x, rest_z) + 0.25, rest_z),
				"rel": -0.05 + (home.z - CZ0) / (CZ1 - CZ0) * 0.8 + absf(pi - 2) * 0.05 + rng.randf() * 0.1,
				"axis": Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 0.3), rng.randf_range(-1, 1)).normalized(),
				"spin": rng.randf_range(1.2, 3.4)})

	# The heap that fills the bore.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cell := 0.5
	var x := -R
	while x < R - 0.01:
		var z := CZ0 - 2.0
		while z < PLUG_TOE + 1.0:
			var a := Vector3(x, _plug_h(x, z), z)
			var b := Vector3(x + cell, _plug_h(x + cell, z), z)
			var c := Vector3(x, _plug_h(x, z + cell), z + cell)
			var d := Vector3(x + cell, _plug_h(x + cell, z + cell), z + cell)
			for v in [a, c, b, b, c, d]:
				st.add_vertex(v)
			z += cell
		x += cell
	st.generate_normals()
	var heap := MeshInstance3D.new()
	heap.mesh = st.commit()
	heap.material_override = _rock_mat("#5a5148", 2.2, 0.15, 1.6)
	_plug = Node3D.new()
	_plug.name = "plug"
	_plug.add_child(heap)
	root.add_child(_plug)

	# Rock that pours through: a few boulders, a lot of rubble.
	var count := 360
	_rocks = MultiMesh.new()
	_rocks.transform_format = MultiMesh.TRANSFORM_3D
	_rocks.mesh = _stone_mesh(3, 0.55)
	_rocks.instance_count = count
	for i in count:
		var big := i < 46
		var s := rng.randf_range(0.7, 1.7) if big else rng.randf_range(0.12, 0.5)
		# Rest: on the face of the slope the crew will see, some rolled out past the toe.
		var rz := lerpf(PLUG_TOE + (1.6 if big else 3.2), CZ0 + 6.0, pow(rng.randf(), 1.6))
		var rx := rng.randf_range(-R + 0.5, R - 0.5)
		var rest := Vector3(rx, _plug_h(rx, rz) + s * 0.22, rz)
		var from := Vector3(rx * 0.55 + rng.randf_range(-1.0, 1.0), SPRING + R * 0.75 + rng.randf_range(0.0, 2.5),
			clampf(rz - rng.randf_range(0.5, 5.0), CZ0 + 1.0, CZ1 - 1.0))
		var land := 0.35 + clampf((rz - CZ0) / (CZ1 - CZ0), 0.0, 1.2) * 0.85 + rng.randf() * 0.5
		_rock.append({"s": Vector3(s, s * rng.randf_range(0.55, 0.9), s * rng.randf_range(0.8, 1.25)), "from": from, "rest": rest,
			"land": land, "rot": Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU),
			"spin": Vector3(rng.randf_range(-5, 5), rng.randf_range(-5, 5), rng.randf_range(-5, 5))})
	var rocks := MultiMeshInstance3D.new()
	rocks.name = "rocks"
	rocks.multimesh = _rocks
	rocks.material_override = _rock_mat("#5f564d", 1.6, 0.15, 2.2)
	rocks.custom_aabb = AABB(Vector3(-R - 1, -1, CZ0 - 8), Vector3(2 * R + 2, 12, 40))
	root.add_child(rocks)

	# Dust: one volume the length of the working bore, shaped by its shader.
	var sh := Shader.new()
	sh.code = DUST_SHADER.replace("//NOISE", NOISE_GLSL)
	_dust = ShaderMaterial.new()
	_dust.shader = sh
	var fog := FogVolume.new()
	fog.name = "dust"
	fog.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	fog.size = Vector3(2.0 * R + 1.0, 9.0, 84.0)
	fog.position = Vector3(0, 4.0, -12.0)
	fog.material = _dust
	root.add_child(fog)

	var ps := Shader.new()
	ps.code = PUFF_SHADER.replace("//NOISE", NOISE_GLSL)
	_puff_mat = ShaderMaterial.new()
	_puff_mat.shader = ps
	var ball := SphereMesh.new()
	ball.radius = 1.0
	ball.height = 2.0
	ball.radial_segments = 28
	ball.rings = 16
	_puffs = MultiMesh.new()
	_puffs.transform_format = MultiMesh.TRANSFORM_3D
	_puffs.mesh = ball
	_puffs.instance_count = 130
	for i in 130:
		var lag := rng.randf_range(0.0, 9.0)
		_puff.append({"x": rng.randf_range(-R + 0.6, R - 0.6), "y": rng.randf_range(0.3, SPRING + R - 1.2), "lag": lag,
			"r": rng.randf_range(1.3, 2.7), "t0": 0.02 + lag * 0.02 + rng.randf() * 0.25,
			"spin": Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 0.4), rng.randf_range(-0.4, 0.4)), "ph": rng.randf() * TAU})
	var billows := MultiMeshInstance3D.new()
	billows.name = "billows"
	billows.multimesh = _puffs
	billows.material_override = _puff_mat
	billows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	billows.custom_aabb = AABB(Vector3(-R - 3, -3, CZ0 - 12), Vector3(2 * R + 6, 16, 90))
	root.add_child(billows)

	# Sparks: the welder's, and the cables tearing.
	var streak := BoxMesh.new()
	streak.size = Vector3(0.012, 0.012, 0.16)
	var hot := _lit("#ffc56e", 9.0)
	hot.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hot.albedo_color = Color("#ffd9a0")
	_weld_sparks = MultiMesh.new()
	_arc_sparks = MultiMesh.new()
	for pair in [[_weld_sparks, 70, "weld_sparks"], [_arc_sparks, 150, "arc_sparks"]]:
		var mm: MultiMesh = pair[0]
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = streak
		mm.instance_count = pair[1]
		var mi := MultiMeshInstance3D.new()
		mi.name = pair[2]
		mi.multimesh = mm
		mi.material_override = hot
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.custom_aabb = AABB(Vector3(-R - 1, -1, CZ0 - 8), Vector3(2 * R + 2, 12, 60))
		root.add_child(mi)
	_weld_light = OmniLight3D.new()
	_weld_light.position = WELD + Vector3(0.25, -0.05, 0)
	_weld_light.light_color = Color("#bcd6ff")
	_weld_light.omni_range = 9.0
	_weld_light.omni_attenuation = 1.1
	_weld_light.shadow_enabled = true
	_weld_light.light_volumetric_fog_energy = 1.5
	root.add_child(_weld_light)
	for at in [Vector3(1.5, 6.4, CZ1 - 8.0), Vector3(-R + 0.7, 2.6, CZ1 - 3.0), Vector3(R - 0.6, 3.4, CZ1 + 1.0)]:
		var arc := OmniLight3D.new()
		arc.position = at
		arc.light_color = Color("#a9c6ff")
		arc.omni_range = 17.0
		arc.omni_attenuation = 0.8
		arc.light_energy = 0.0
		arc.shadow_enabled = _arc_lights.is_empty()
		arc.light_volumetric_fog_energy = 2.5
		root.add_child(arc)
		_arc_lights.append(arc)

	# Threads of dust and grit from the crown before it goes.
	var grain := BoxMesh.new()
	grain.size = Vector3(0.012, 0.03, 0.012)
	_grains = MultiMesh.new()
	_grains.transform_format = MultiMesh.TRANSFORM_3D
	_grains.mesh = grain
	_grains.instance_count = 700
	var pale := _mat("#cfc4b2", 0.9)
	pale.emission_enabled = true
	pale.emission = Color("#b9ad9b")
	pale.emission_energy_multiplier = 0.35
	var grains := MultiMeshInstance3D.new()
	grains.name = "grit"
	grains.multimesh = _grains
	grains.material_override = pale
	grains.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	grains.custom_aabb = AABB(Vector3(-R - 1, -1, CZ0 - 8), Vector3(2 * R + 2, 12, 70))
	root.add_child(grains)


# ============================================================================== pose

func pose(root: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	var impact := float(p.get("impact", 1.0e9))
	var alive := float(p.get("alive", 1.0e9))
	_full_power = float(p.get("full_power", 1.0e9))
	var origin: Vector3 = (ctx["holder"] as Node3D).position
	var dt := t - impact
	_floor.set_shader_parameter("origin", origin)
	_dust.set_shader_parameter("origin", origin)
	_pose_power(t, impact, alive)
	_pose_truck(t, impact)
	_pose_weld(t, dt)
	_pose_grit(t, dt, p)
	_pose_collapse(t, dt)
	var out := {"truck": origin + _truck.position + Vector3(0, 1.6, 0), "weld": origin + WELD,
		"plug": origin + Vector3(0, 2.2, PLUG_TOE - 2.0)}
	_pose_crew(p, t, dt, ctx, origin, out)
	_pose_valve(p, t, out, origin)
	_pose_meal(p, t, ctx, origin)
	_pose_scope(p, t, out, origin)
	if _mats != null:
		_mats.visible = t >= float(p["mats"].get("from", 0.0)) and t < float(p["mats"].get("until", 1.0e9))
	if p.has("feed"):
		_pose_feed(p, t, ctx, origin)
	if p.has("jars"):
		_pose_jars(p, t, ctx, origin)
	# Until the power stutters back, the crew is lamps and reflective tape in the dark.
	_bounce.light_energy *= 0.25 + 0.75 * Motion.seg(t, alive - 0.05, alive + 0.6)
	return out


## The dust front, in metres down the bore, and when it reaches a point.
func _front(dt: float) -> float:
	if dt < 0.85:
		return lerpf(CZ0 + 3.0, CZ1, Motion.smooth(Motion.seg(dt, 0.0, 0.85)))
	return CZ1 + 40.0 * (1.0 - exp(-1.1 * (dt - 0.85)))


func _reach(z: float) -> float:
	if z <= CZ1:
		return clampf((z - CZ0) / (CZ1 - CZ0), 0.0, 1.0) * 0.8
	var f := (z - CZ1) / 40.0
	return 60.0 if f >= 0.98 else 0.85 - log(1.0 - f) / 1.1


## How brightly a lamp at z burns (0..1): the mountain's warning, the stutter when it goes, death as
## the dust (and the torn feed) reaches it, and the weak return of power afterwards.
func _power(z: float, t: float, impact: float, alive: float, salt: float) -> float:
	# Days later the lamps on the trapped side burn at full strength again.
	if t >= _full_power and z > CZ1 + 9.0:
		return 1.0
	var dt := t - impact
	var k := 1.0
	if dt > -0.82 and dt < -0.6:
		k *= 0.35 + 0.65 * _step(0.45, _hash(floorf(t * 30.0) + salt))
	if dt > -0.1:
		k *= 0.62 + 0.38 * _step(0.35, _hash(floorf(t * 24.0) + salt * 3.0))
	var reach := _reach(z) + (0.0 if z <= CZ1 else 0.32)
	if dt > reach - 0.25:
		k *= 0.25 + 0.75 * _step(0.5, _hash(floorf(t * 30.0) + salt * 5.0))
	if dt > reach or dt > 1.95:
		k = 0.0
	if t > alive and z > CZ1 + 9.0:
		var back := t - alive - (z - CZ1 - 9.0) * 0.014 - _hash(salt) * 0.2
		if back > 0.0:
			k = 0.5 if back > 0.55 else 0.5 * _step(0.4, _hash(floorf(t * 20.0) + salt))
	return k


func _pose_power(t: float, impact: float, alive: float) -> void:
	for w in _wall_lights:
		var k := _power(float(w["z"]), t, impact, alive, float(w["salt"]))
		(w["mat"] as StandardMaterial3D).emission_energy_multiplier = 0.02 + 6.0 * k
		if w["light"] != null:
			(w["light"] as OmniLight3D).light_energy = float(w["e"]) * k
	var tower := _power(TOWER.z, t, impact, 1.0e9, 31.0)
	for s in _tower_spots:
		(s as SpotLight3D).light_energy = 8.0 * tower
	_tower_mat.emission_energy_multiplier = 0.02 + 9.0 * tower
	# The stand light that was on the crown: on until the rock reaches it.
	var crown := _power(CZ1 + 0.5, t, impact, 1.0e9, 57.0)
	_crown_spot.light_energy = 11.0 * crown
	_crown_mat.emission_energy_multiplier = 0.02 + 8.0 * crown
	for b in _beacons:
		(b["pivot"] as Node3D).rotation.y = t * TAU * 1.15
	_weld_light.visible = true


## Crawls in along the +X side and stops short of the spoil heap, a second before the roof goes.
func _truck_z(t: float, impact: float) -> float:
	var stop := impact - 1.1
	var v := 3.4
	if t >= stop:
		return -15.8
	var u := stop - t
	return -15.8 - (v * u - 0.5 * (v / 1.2) * u * u if u < 1.2 else v * 0.6 + v * (u - 1.2))


func _pose_truck(t: float, impact: float) -> void:
	var z := _truck_z(t, impact)
	var moving := t < impact - 1.1
	var bob := sin(z * 2.1) * 0.025 + sin(z * 5.3) * 0.012
	# Nose dips under the brakes.
	var dive := Motion.seg(t, impact - 1.9, impact - 1.3) * (1.0 - Motion.seg(t, impact - 1.1, impact - 0.7))
	_truck.position = Vector3(2.95, bob if moving else sin(t * 47.0) * 0.004, z)
	_truck.rotation = Vector3(0.03 * dive + sin(z * 1.7) * 0.004, 0, sin(z * 1.3) * 0.006)
	for w in _truck_wheels:
		(w as Node3D).rotation.x = z / 0.55
	var dim := 1.0 - 0.93 * Motion.seg(t, impact + 0.35, impact + 1.3)   # swallowed, then lenses caked in dust
	for s in _truck_spots:
		(s as SpotLight3D).light_energy = 13.0 * dim
		(s as SpotLight3D).light_volumetric_fog_energy = 1.6 * dim * dim
	_truck_beam.emission_energy_multiplier = 1.0 + 13.0 * dim


func _spark(mm: MultiMesh, i: int, at: Vector3, v: Vector3, age: float, life: float) -> void:
	if age <= 0.0 or age >= life:
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), at))
		return
	var pos := at + v * age + Vector3(0, -0.5 * 9.8 * age * age, 0)
	if pos.y < 0.02:
		pos.y = 0.02
	var vel := v + Vector3(0, -9.8 * age, 0)
	var streak := clampf(vel.length() * 0.3, 0.5, 2.4) * (1.0 - age / life * 0.6)
	mm.set_instance_transform(i, Transform3D(_aim(vel).scaled(Vector3(1.0, 1.0, streak)), pos))


func _pose_weld(t: float, dt: float) -> void:
	# Arc on for a second, off for a breath; stops for good when the mountain speaks.
	var cycle := fposmod(t, 1.5)
	var on := cycle < 1.1 and dt < -0.8
	_weld_light.light_energy = (5.0 + 7.0 * _hash(floorf(t * 30.0))) if on else 0.0
	var rng := RandomNumberGenerator.new()
	for i in _weld_sparks.instance_count:
		rng.seed = 900 + i
		var life := rng.randf_range(0.35, 0.8)
		var period := 0.85
		var birth := floorf((t - rng.randf() * period) / period) * period + rng.randf() * period
		if birth > t:
			birth -= period
		var born_on := fposmod(birth, 1.5) < 1.1 and birth - (t - dt) < -0.8
		var v := Vector3(rng.randf_range(0.6, 2.6), rng.randf_range(-0.5, 2.2), rng.randf_range(-1.6, 1.6))
		_spark(_weld_sparks, i, WELD + Vector3(0.05, 0, 0), v, (t - birth) if born_on else -1.0, life)

	# Torn cables: three bursts as the lining tears them, each with a blue-white flash.
	var bursts := [0.12, 0.5, 0.85]
	for b in bursts.size():
		var age := dt - float(bursts[b])
		var arc := _arc_lights[b] as OmniLight3D
		arc.light_energy = 0.0 if age < 0.0 else 13.0 * exp(-age * 11.0) * (0.3 + 0.7 * _hash(floorf(t * 30.0) + b))
	var per := _arc_sparks.instance_count / bursts.size()
	for i in _arc_sparks.instance_count:
		rng.seed = 4000 + i
		var b := mini(i / per, bursts.size() - 1)
		var at: Vector3 = (_arc_lights[b] as OmniLight3D).position
		var v := Vector3(rng.randf_range(-3.5, 3.5), rng.randf_range(-1.0, 4.5), rng.randf_range(0.5, 6.5))
		_spark(_arc_sparks, i, at, v, dt - float(bursts[b]) - rng.randf() * 0.12, rng.randf_range(0.5, 1.1))


func _pose_grit(t: float, dt: float, p: Dictionary) -> void:
	# Each thread owns a share of the grains; a grain falls from the crown, again and again.
	var streams: Array = p.get("trickles", [])
	var n := _grains.instance_count
	var hide := Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3.ZERO)
	if streams.is_empty():
		for i in n:
			_grains.set_instance_transform(i, hide)
		return
	var per := n / streams.size()
	var rng := RandomNumberGenerator.new()
	for i in n:
		var s: Dictionary = streams[mini(i / per, streams.size() - 1)]
		rng.seed = 7000 + i
		var x := float(s["x"])
		var z := float(s["z"])
		var top := SPRING + sqrt(maxf(R * R - x * x, 0.0)) - 0.1
		var floor_y := float(s.get("land", 0.0))
		var fall := sqrt(2.0 * (top - floor_y) / 9.8)
		var period := fall * 1.15
		var phase := rng.randf() * period
		var spread := float(s.get("spread", 0.07))
		var jx := rng.randf_range(-spread, spread)
		var jz := rng.randf_range(-spread, spread)
		var since := t - float(s["t"])
		var age := fposmod(since - phase, period)
		# The thread thickens: later grains only join once it has been running a while.
		var joined := since - age > rng.randf() * float(s.get("build", 1.2))
		if since < 0.0 or not joined or age > fall or dt > 0.25:
			_grains.set_instance_transform(i, hide)
			continue
		var y := top - 0.5 * 9.8 * age * age
		var stretch := clampf(1.0 + age * 7.0, 1.0, 5.0)
		_grains.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(1, stretch, 1)), Vector3(x + jx * (1.0 + age), y, z + jz * (1.0 + age))))


func _pose_collapse(t: float, dt: float) -> void:
	# Lining panels: hang, let go from the middle outward, tumble, lie in the heap.
	for s in _slabs:
		var node := s["node"] as Node3D
		var home: Vector3 = s["home"]
		var rest: Vector3 = s["rest"]
		var age := dt - float(s["rel"])
		if age <= 0.0:
			# A shudder just before it lets go.
			var pre := Motion.seg(age, -0.22, 0.0)
			node.position = home + Vector3(0, -0.05 * pre * pre, 0)
			node.rotation = Vector3.ZERO
			continue
		var fall := sqrt(2.0 * maxf(home.y - rest.y, 0.1) / GRAVITY)
		var k := minf(age / fall, 1.0)
		var pos := home.lerp(rest, k)
		pos.y = home.y - 0.5 * GRAVITY * minf(age, fall) * minf(age, fall)
		node.position = pos
		node.basis = Basis(s["axis"] as Vector3, float(s["spin"]) * minf(age, fall) + 0.25 * Motion.impact(age - fall, 0.3))

	# Ribs buckle and come down with the crown; the duct tears and hangs from its last strap.
	for i in _zone_ribs.size():
		var rib := _zone_ribs[i] as Node3D
		var near := 1.0 - absf(rib.position.z - (CZ0 + CZ1) * 0.5) / ((CZ1 - CZ0) * 0.5)
		var age := dt - 0.1 - (1.0 - near) * 0.35
		var k := Motion.out_cubic(Motion.seg(age, 0.0, 0.9))
		rib.rotation.x = (0.55 + 0.7 * near) * k * (1.0 if i % 2 == 0 else -0.8)
		rib.rotation.z = 0.25 * k * (1.0 if i % 3 == 0 else -1.0)
		rib.position.y = -3.6 * near * Motion.in_cubic(Motion.seg(age, 0.0, 0.7))
	var tear := dt - 0.25
	_zone_duct.rotation.x = 0.0 if tear < 0.0 else -(1.2 * Motion.out_cubic(Motion.seg(tear, 0.0, 0.8)) + 0.16 * Motion.wobble(tear - 0.8, 0.7, 1.6))

	# Rock pours through the hole and piles up; the heap rises under it.
	var grow := Motion.smooth(Motion.seg(dt, 0.25, 1.75))
	_plug.visible = dt > 0.25
	_plug.scale = Vector3(1, maxf(grow, 0.001), 1)
	for i in _rock.size():
		var r: Dictionary = _rock[i]
		var land := float(r["land"])
		var from: Vector3 = r["from"]
		var rest: Vector3 = r["rest"]
		var settle := Motion.smooth(Motion.seg(land, 0.25, 1.75))
		var target := Vector3(rest.x, rest.y * settle, rest.z)
		var fall := sqrt(2.0 * maxf(from.y - target.y, 0.1) / GRAVITY)
		var age := dt - (land - fall)
		if age <= 0.0:
			_rocks.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), from))
			continue
		var k := minf(age / fall, 1.0)
		var pos := from.lerp(target, k)
		pos.y = from.y - 0.5 * GRAVITY * minf(age, fall) * minf(age, fall)
		if age > fall:
			# Rides the heap as it builds; a short hop where it hit.
			var after := age - fall
			pos.y = rest.y * maxf(grow, settle) + maxf(0.0, after * 1.6 - 5.0 * after * after)
		var rot: Vector3 = r["rot"] + (r["spin"] as Vector3) * minf(age, fall + 0.15)
		_rocks.set_instance_transform(i, Transform3D(Basis.from_euler(rot).scaled(r["s"] as Vector3), pos))

	# Dust: bursts with the fall, runs the bore, then hangs and slowly thins.
	var density := 0.0
	if dt > 0.0:
		density = 2.4 * Motion.smooth(Motion.seg(dt, 0.0, 0.6))
		if dt > 2.0:
			density = 0.058 + (2.4 - 0.058) * exp(-(dt - 2.0) / 2.6)
	_dust.set_shader_parameter("density", density)
	_dust.set_shader_parameter("back", CZ0 - 2.0 - 30.0 * Motion.seg(dt, 0.2, 1.5))
	_dust.set_shader_parameter("front", (_front(dt) + 3.5) if dt > 0.0 else CZ0)
	_dust.set_shader_parameter("drift", maxf(dt, 0.0))
	_puff_mat.set_shader_parameter("drift", maxf(dt, 0.0))
	var face := _front(dt)
	var fade := 1.0 - Motion.seg(dt, 2.3, 3.6)      # the billows thin into the haze that hangs
	for i in _puff.size():
		var pf: Dictionary = _puff[i]
		var born := Motion.smooth(Motion.seg(dt - float(pf["t0"]), 0.0, 0.55)) * fade
		if born <= 0.0:
			_puffs.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3(0, 0, CZ1)))
			continue
		var ph := float(pf["ph"])
		var at := Vector3(float(pf["x"]) + sin(dt * 1.7 + ph) * 0.35,
			float(pf["y"]) + sin(dt * 2.3 + ph * 1.7) * 0.35 + dt * 0.12 + (1.0 - minf(born / maxf(fade, 0.001), 1.0)) * 6.0,
			face - float(pf["lag"]) - 1.0)
		var roll: Vector3 = (pf["spin"] as Vector3) * dt * 1.6
		var size := float(pf["r"]) * (0.6 + 0.4 * born) * fade * (1.0 + 0.25 * Motion.seg(dt, 0.0, 2.0))
		_puffs.set_instance_transform(i, Transform3D(Basis.from_euler(roll).scaled(Vector3.ONE * size), at))


func _pose_crew(p: Dictionary, t: float, dt: float, ctx: Dictionary, origin: Vector3, out: Dictionary) -> void:
	if not ctx.has("actor"):
		return
	var crew: Dictionary = p.get("crew", {})
	var lamp := 0
	var lit := 0.0
	for id in crew:
		var c: Dictionary = crew[id]
		var actor = ctx["actor"].call(id)
		if actor == null:
			continue
		if c.has("from") or c.has("until"):
			actor.visible = t >= float(c.get("from", -1.0e9)) and t < float(c.get("until", 1.0e9))
			if _props.has(id):
				(_props[id] as Node3D).visible = actor.visible
			if not actor.visible:
				continue
		actor.position.y = origin.y + float(c.get("y", 0.0))
		var yaw: float = actor.rotation.y
		var fwd := Vector3(sin(yaw), 0, cos(yaw))
		var left := Vector3(cos(yaw), 0, -sin(yaw))
		var feet: Vector3 = actor.position
		var role := String(c.get("role", ""))
		var prop: Node3D = _props.get(id)
		# Hands over the head when the roof goes (for those who duck instead of running).
		var brace := 0.0
		if c.has("cower"):
			brace = Motion.smooth(Motion.seg(dt - float(c["cower"]), 0.0, 0.28))
			if bool(c.get("rise", false)):
				brace *= 1.0 - Motion.smooth(Motion.seg(dt, 5.0, 6.2))
		var work := 1.0 - brace
		match role:
			"barrow":
				var base := feet + fwd * 0.52
				prop.position = base - origin
				prop.rotation = Vector3(0.0, yaw, 0.0)
				for side in ["l", "r"]:
					var sgn := 1.0 if side == "l" else -1.0
					actor.aim_hand(side, base + left * sgn * 0.27 - fwd * 0.42 + Vector3.UP * 0.6, work)
			"pipe_a":
				var mate = ctx["actor"].call(String(c.get("mate", "")))
				if mate != null:
					var a: Vector3 = actor.bone_world("upperarm_r") + Vector3.UP * 0.13
					var b: Vector3 = mate.bone_world("upperarm_r") + Vector3.UP * 0.13
					b.y = a.y + (float(crew.get(String(c["mate"]), {}).get("y", 0.0)) - float(c.get("y", 0.0)))
					var drop := Vector3.DOWN * (a.y - feet.y - 0.06) * Motion.out_bounce(Motion.seg(dt, 0.05, 0.55))
					prop.transform = Transform3D(_aim(b - a), (a + b) * 0.5 - origin + drop)
					actor.aim_hand("r", a + fwd * 0.2 + Vector3.UP * 0.02, work)
					mate.aim_hand("r", b + Vector3(sin(mate.rotation.y), 0, cos(mate.rotation.y)) * 0.2 + Vector3.UP * 0.02,
						1.0 - Motion.smooth(Motion.seg(dt, 0.0, 0.2)))
			"chai":
				# Sip, lower, sip. The glass trembles as the rumble builds.
				var chest: Vector3 = actor.bone_world("spine_03")
				var head: Vector3 = actor.anchor_points()[id + ".head"]["pos"]
				var sip := Motion.smooth(Motion.seg(sin(t * 1.9 + float(c.get("phase", 0.0))), 0.1, 0.8)) * (1.0 - Motion.seg(dt, -1.0, -0.6))
				var low := chest + fwd * 0.3 - left * 0.1 - Vector3.UP * 0.08
				var high := head + fwd * 0.3 - left * 0.03 - Vector3.UP * 0.2
				var hold := low.lerp(high, sip)
				var shiver := Motion.seg(dt, -1.3, -0.1) * 0.006
				hold += Vector3(sin(t * 61.0), sin(t * 83.0), 0) * shiver
				actor.aim_hand("r", hold, work)
				var hand: Vector3 = actor.bone_world("hand_r")
				prop.position = hand - origin + Vector3(0, -0.07, 0) + fwd * 0.05 + Vector3.DOWN * 0.9 * Motion.in_cubic(Motion.seg(dt, 0.1, 0.45))
				prop.rotation = Vector3(-0.5 * sip, yaw, 0)
				prop.visible = dt < 0.45
			"engineer":
				var chest: Vector3 = actor.bone_world("spine_03")
				var at := chest + fwd * 0.3 + left * 0.12 - Vector3.UP * 0.02
				actor.aim_hand("l", at, work)
				prop.transform = Transform3D(Basis.from_euler(Vector3(-0.5, yaw, 0)), actor.bone_world("hand_l") - origin + fwd * 0.05 + Vector3.UP * 0.1)
				# Points up at the crown every few seconds.
				var point := Motion.smooth(Motion.seg(sin(t * 1.1 + 0.6), 0.2, 0.7)) * work
				actor.aim_hand("r", chest + fwd * 0.35 - left * 0.25 + Vector3.UP * 0.75, point)
			"welder":
				actor.aim_hand("r", origin + WELD + Vector3(0.22, -0.02, 0), work)
				actor.aim_hand("l", origin + WELD + Vector3(0.3, -0.3, 0.2), work * 0.8)
				var hand: Vector3 = actor.bone_world("hand_r")
				prop.transform = Transform3D(_aim(origin + WELD - hand), hand - origin)
				prop.visible = work > 0.5
			"sprayer":
				var chest: Vector3 = actor.bone_world("spine_03")
				var sway := sin(t * 1.3) * 0.25
				var nozzle := chest + fwd * 0.42 + left * (0.1 + sway * 0.3) + Vector3.UP * (0.12 + 0.1 * sin(t * 0.9))
				actor.aim_hand("r", nozzle, work)
				actor.aim_hand("l", nozzle - fwd * 0.22 - Vector3.UP * 0.08, work)
				prop.transform = Transform3D(_aim(-(fwd + left * sway * 0.5 + Vector3.UP * 0.35)), actor.bone_world("hand_r") - origin + Vector3.DOWN * 0.8 * (1.0 - work))
			"bag":
				var shoulder: Vector3 = actor.bone_world("upperarm_r") + Vector3.UP * 0.16 - left * 0.02
				var drop := Motion.out_bounce(Motion.seg(dt, 0.1, 0.6))
				prop.transform = Transform3D(Basis.from_euler(Vector3(0, yaw + PI * 0.5, 0.12)), shoulder - origin + Vector3.DOWN * (shoulder.y - feet.y - 0.08) * drop)
				actor.aim_hand("r", shoulder + fwd * 0.16 + Vector3.UP * 0.05, work)
			"signal":
				var chest: Vector3 = actor.bone_world("spine_03")
				var wave := sin(t * 5.0)
				actor.aim_hand("r", chest - left * (0.3 + 0.12 * wave) + Vector3.UP * (0.62 + 0.08 * wave) + fwd * 0.12, work)
			"yoga":
				_pose_yoga(actor, c, t, id, fwd, left)
			"wave":
				_pose_wave(actor, c, t, id, fwd, left)
			"lamp_click":
				# Reach up, thumb the switch on the headlamp, bring the hand down.
				var off := float(c.get("lamp_off", 1.0e9))
				var k := Motion.smooth(Motion.seg(t, off - 0.34, off - 0.04)) * (1.0 - Motion.smooth(Motion.seg(t, off + 0.16, off + 0.5)))
				var hd: Vector3 = actor.anchor_points()[id + ".head"]["pos"]
				actor.aim_hand("r", hd - left * 0.42 + fwd * 0.34 + Vector3.UP * 0.2, k, 0.06)
			"valve":
				# Both hands on the rim of the handwheel, going round with it; let go when it bursts.
				var vp: Dictionary = p.get("valve", {})
				var open := float(vp.get("open", 1.0e9))
				var grip := Motion.smooth(Motion.seg(t, open - 1.25, open - 1.0)) * (1.0 - Motion.out_cubic(Motion.seg(t, open, open + 0.14)))
				if _wheel != null:
					var hub := _wheel.global_position
					var ang := _wheel.rotation.y
					for side in ["l", "r"]:
						var a := ang + (0.0 if side == "l" else PI)
						actor.aim_hand(side, hub + Vector3(cos(a) * 0.2, 0.03, sin(a) * 0.2), grip)
			"point":
				var chest: Vector3 = actor.bone_world("spine_03")
				var k := Motion.smooth(Motion.seg(sin(t * 0.9 + float(c.get("phase", 0.0))), 0.0, 0.6))
				actor.aim_hand("r", chest + fwd * 0.4 - left * 0.15 + Vector3.UP * 0.35, k * work)
		if brace > 0.0:
			var head: Vector3 = actor.anchor_points()[id + ".head"]["pos"]
			actor.aim_hand("l", head + left * 0.2 + Vector3.UP * 0.2 + fwd * 0.12, brace)
			actor.aim_hand("r", head - left * 0.2 + Vector3.UP * 0.18 + fwd * 0.12, brace)
		if c.has("hero"):
			out[String(c["hero"])] = actor.anchor_points()[id + ".head"]["pos"]
		# Headlamps: a soft working beam before, the only light afterwards.
		if not _lenses.has(id):
			_lenses[id] = actor.find_child("lamp_lens", true, false)
		var lens := _lenses[id] as MeshInstance3D
		if lens == null:
			continue
		var bright := 1.0 if dt < 0.0 else (0.35 + 0.65 * _step(0.3, _hash(floorf(t * 14.0) + lamp * 2.3))) if dt < 0.5 else 1.0
		if c.has("lamp_off"):
			var off := float(c["lamp_off"])
			if t >= off + 0.07:
				bright = 0.0
			elif t >= off:
				bright = 0.3
		(lens.material_override as StandardMaterial3D).emission_energy_multiplier = maxf((2.2 if dt < 0.0 else 6.0) * bright, 0.05)
		lit += 1.0
		if bool(c.get("lamp", false)) and lamp < _lamps.size():
			var spot := _lamps[lamp] as SpotLight3D
			lamp += 1
			var head: Vector3 = actor.anchor_points()[id + ".head"]["pos"]
			var nod := -0.1 + 0.05 * sin(t * 1.7 + lamp)
			var dir := (fwd + Vector3.UP * nod).normalized()
			spot.transform = Transform3D(_aim(dir), head + fwd * 0.36 + Vector3.UP * 0.22 - origin)
			spot.light_energy = (0.9 if dt < 0.0 else 4.2) * bright
	for i in range(lamp, _lamps.size()):
		(_lamps[i] as SpotLight3D).light_energy = 0.0
	# What the beams give back off the dust and the rubble once everything else is dark.
	_bounce.position = Vector3(0.0, 2.4, -9.0)
	_bounce.light_energy = 0.0 if dt < 1.0 else 0.02 * lit * Motion.seg(dt, 1.0, 2.5)


# ------------------------------------------------------------------------------ the water main's valve

const WATER_SHADER := """
shader_type spatial;
render_mode cull_disabled, depth_draw_always;
uniform float flow = 0.0;
uniform float reach = 1.0;
//NOISE
void fragment() {
	if (UV.y > reach) { discard; }
	float n = n3(vec3(UV.x * 7.0, UV.y * 16.0 - flow * 11.0, flow * 0.9));
	float streak = smoothstep(0.3, 0.85, n);
	float rim = pow(1.0 - abs(dot(NORMAL, VIEW)), 1.5);
	// The jet holds together out of the spout and tears into ropes as it falls.
	float tear = smoothstep(0.45, 1.0, UV.y) * (1.0 - smoothstep(0.2, 0.75, n3(vec3(UV.x * 9.0, UV.y * 22.0 - flow * 14.0, 3.0))));
	if (tear > 0.55) { discard; }
	ALBEDO = mix(vec3(0.78, 0.8, 0.8), vec3(1.0), streak);
	ALPHA = clamp(0.12 + rim * 0.6 + streak * 0.35, 0.0, 0.85);
	ROUGHNESS = 0.02;
	SPECULAR = 1.0;
	EMISSION = vec3(0.22, 0.16, 0.09) * (0.3 + streak);
}
"""

const SPOUT := Vector3(R - 1.08, 0.5, 0.0)       # where the water leaves (z added at build)
const JET := Vector3(-2.5, 0.75, 0.0)             # its velocity


func _build_valve(root: Node3D, p: Dictionary) -> void:
	if not p.has("valve"):
		return
	_valve_z = float(p["valve"].get("z", -11.0))
	var z := _valve_z
	_valve = Node3D.new()
	_valve.name = "valve"
	root.add_child(_valve)
	var steel := _mat("#4d5258", 0.45, 0.7)
	var cast := _mat("#3a4d3a", 0.6, 0.5)            # green-painted cast iron
	var red := _mat("#b0261c", 0.45, 0.4)
	# A branch drops off the main to hip height, then the gate valve (stem up) and a short spout.
	_rod(_valve, Vector3(R - 0.32, 0.95, z - 0.17), Vector3(R - 0.32, 0.95, z + 0.17), 0.13, steel, 14)
	_rod(_valve, Vector3(R - 0.32, 0.95, z), Vector3(R - 0.32, 0.55, z), 0.085, steel, 12)
	_rod(_valve, Vector3(R - 0.32, 0.55, z), Vector3(R - 0.62, 0.55, z), 0.085, steel, 12)
	_rod(_valve, Vector3(R - 0.62, 0.55, z), Vector3(R - 0.88, 0.55, z), 0.14, cast, 16)
	_box(_valve, Vector3(0.1, 0.32, 0.32), Vector3(R - 0.62, 0.55, z), cast)
	_box(_valve, Vector3(0.1, 0.32, 0.32), Vector3(R - 0.88, 0.55, z), cast)
	_rod(_valve, Vector3(R - 0.75, 0.68, z), Vector3(R - 0.75, 0.78, z), 0.06, cast, 10)       # bonnet
	_rod(_valve, Vector3(R - 0.75, 0.78, z), Vector3(R - 0.75, 0.86, z), 0.022, steel, 8)       # stem
	_rod(_valve, Vector3(R - 0.88, 0.55, z), SPOUT + Vector3(0, 0, z), 0.075, steel, 12)
	# A support clamp down to the floor.
	_rod(_valve, Vector3(R - 0.32, 0.47, z), Vector3(R - 0.32, 0.0, z), 0.03, steel, 6)
	# The handwheel: a rim on four spokes.
	_wheel = Node3D.new()
	_wheel.position = Vector3(R - 0.75, 0.87, z)
	_valve.add_child(_wheel)
	var rim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.17
	tm.outer_radius = 0.215
	tm.rings = 24
	tm.ring_segments = 8
	rim.mesh = tm
	rim.material_override = red
	_wheel.add_child(rim)
	for k in 4:
		var a := k * PI * 0.5
		_rod(_wheel, Vector3.ZERO, Vector3(cos(a) * 0.19, 0, sin(a) * 0.19), 0.014, red, 6)
	_rod(_wheel, Vector3(0, -0.02, 0), Vector3(0, 0.03, 0), 0.035, red, 10)
	# The jet: a tube along its arc, revealed from the spout outward.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 18
	var sides := 10
	var pts := []
	var p0 := SPOUT + Vector3(0, 0, z)
	var vy := JET.y
	var t_land := (vy + sqrt(vy * vy + 2.0 * 9.8 * p0.y)) / 9.8
	for i in n + 1:
		var u := float(i) / n
		var tt := u * t_land
		pts.append(p0 + JET * tt + Vector3(0, -4.9 * tt * tt, 0))
	for i in n:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var d := (b - a).normalized()
		var x := d.cross(Vector3.FORWARD).normalized()
		var y := x.cross(d).normalized()
		var ra := 0.038 + 0.03 * float(i) / n
		var rb := 0.038 + 0.03 * float(i + 1) / n
		for k in sides:
			var a0 := TAU * k / sides
			var a1 := TAU * (k + 1) / sides
			var q := [[a + (x * cos(a0) + y * sin(a0)) * ra, Vector2(float(k) / sides, float(i) / n)],
				[a + (x * cos(a1) + y * sin(a1)) * ra, Vector2(float(k + 1) / sides, float(i) / n)],
				[b + (x * cos(a0) + y * sin(a0)) * rb, Vector2(float(k) / sides, float(i + 1) / n)],
				[b + (x * cos(a1) + y * sin(a1)) * rb, Vector2(float(k + 1) / sides, float(i + 1) / n)]]
			for o in [0, 2, 1, 1, 2, 3]:
				st.set_uv(q[o][1])
				st.add_vertex(q[o][0])
	st.generate_normals()
	_stream = MeshInstance3D.new()
	_stream.mesh = st.commit()
	var sh := Shader.new()
	sh.code = WATER_SHADER.replace("//NOISE", NOISE_GLSL)
	_stream_mat = ShaderMaterial.new()
	_stream_mat.shader = sh
	_stream.material_override = _stream_mat
	_stream.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stream.visible = false
	root.add_child(_stream)
	_stream.set_meta("land", pts[n])
	# Spray where it hits, and the spreading puddle.
	var drop := SphereMesh.new()
	drop.radius = 0.011
	drop.height = 0.022
	drop.radial_segments = 6
	drop.rings = 3
	var dm := _lit("#ffe2b8", 0.5)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.albedo_color = Color(0.95, 0.95, 0.95, 0.55)
	dm.roughness = 0.02
	drop.material = dm
	_spray = MultiMesh.new()
	_spray.transform_format = MultiMesh.TRANSFORM_3D
	_spray.mesh = drop
	_spray.instance_count = 90
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = _spray
	smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(smi)
	_puddle = MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 1.0
	pm.bottom_radius = 1.0
	pm.height = 0.01
	pm.radial_segments = 32
	_puddle.mesh = pm
	var wm := _mat("#0b0d0e", 0.02, 0.0)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.albedo_color = Color(0.04, 0.04, 0.045, 0.45)
	wm.metallic_specular = 1.0
	_puddle.material_override = wm
	_puddle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(_puddle)


func _pose_valve(p: Dictionary, t: float, out: Dictionary, origin: Vector3) -> void:
	if _valve == null:
		return
	var vp: Dictionary = p["valve"]
	var open := float(vp.get("open", 1.0e9))
	# A turn and a quarter: stiff to start, then it gives (in-out), done on the word.
	var turn := Motion.in_out(Motion.seg(t, open - 1.0, open - 0.02))
	_wheel.rotation.y = -turn * TAU * 1.25
	var age := t - open
	var on := age >= 0.0 and t < float(vp.get("close", 1.0e9))
	_stream.visible = on
	var land: Vector3 = _stream.get_meta("land")
	if on:
		# The first slug of water shoots out in 0.12 s.
		_stream_mat.set_shader_parameter("reach", Motion.out_cubic(Motion.seg(age, 0.0, 0.12)))
		_stream_mat.set_shader_parameter("flow", t)
	for i in _spray.instance_count:
		var xf := Transform3D(Basis.from_scale(Vector3.ONE * 0.001), land)
		if on and age > 0.1 + _hash(i * 3.1) * 0.15:
			var life := 0.35 + _hash(i * 1.7) * 0.3
			var a := fposmod(age - 0.1 + _hash(i * 3.1) * life, life)
			var ang := _hash(i * 5.3) * TAU
			var sp := 0.6 + _hash(i * 7.7) * 1.4
			var v := Vector3(cos(ang) * sp, 1.4 + _hash(i * 9.1) * 1.6, sin(ang) * sp)
			var pos := land + v * a + Vector3(0, -4.9 * a * a, 0)
			if pos.y > 0.0:
				xf = Transform3D(Basis.from_scale(Vector3.ONE * (0.6 + _hash(i * 2.9) * 1.2)), pos)
		_spray.set_instance_transform(i, xf)
	var spread := Motion.out_cubic(Motion.seg(age, 0.05, 1.6)) if age >= 0.0 else 0.0
	_puddle.visible = spread > 0.01
	_puddle.position = land + Vector3(0.1, 0.012, 0)
	_puddle.scale = Vector3(0.25 + 0.95 * spread, 1.0, 0.2 + 0.75 * spread)
	out["valve"] = origin + _wheel.position + Vector3(0, 0.05, 0)
	out["spout"] = origin + SPOUT + Vector3(0, 0, _valve_z)


# ------------------------------------------------------------------------------ line 7: what comes through the pipe

## params.feed = {"air", "rice", "fruit" (scene times: the blast, the first puffed rice, the first dry
## fruit), "holder" (crew id who catches it in his upturned helmet), "doff" (when his helmet leaves his
## head for his hands), "bowl" [x, y, z] (where he holds it)}.
const RICE_N := 260
const FRUIT_N := 46

var _feed_air: MultiMesh
var _feed_rice: MultiMesh
var _feed_fruit: MultiMesh
var _feed_bowl: Node3D
var _feed_hat: Node3D
var _feed_ready := false


func _build_feed(root: Node3D, p: Dictionary) -> void:
	if not p.has("feed"):
		return
	# Puffs of grit and air: soft, short-lived spheres.
	var puff := SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	puff.radial_segments = 12
	puff.rings = 6
	var pm := _mat("#b9a68c", 1.0)
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.albedo_color = Color(0.82, 0.76, 0.66, 0.12)
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	puff.material = pm
	_feed_air = MultiMesh.new()
	_feed_air.transform_format = MultiMesh.TRANSFORM_3D
	_feed_air.mesh = puff
	_feed_air.instance_count = 14
	# Puffed rice: a puffy, creamy grain (cartoon-big so it reads on a phone).
	var grain := CapsuleMesh.new()
	grain.radius = 0.011
	grain.height = 0.036
	grain.radial_segments = 6
	grain.rings = 2
	grain.material = _mat("#efe4c8", 0.95)
	_feed_rice = MultiMesh.new()
	_feed_rice.transform_format = MultiMesh.TRANSFORM_3D
	_feed_rice.mesh = grain
	_feed_rice.instance_count = RICE_N
	# Dry fruit: almonds, cashews, raisins (one mesh, coloured per instance).
	var nut := SphereMesh.new()
	nut.radius = 0.5
	nut.height = 1.0
	nut.radial_segments = 8
	nut.rings = 5
	var nm := _mat("#ffffff", 0.6)
	nm.vertex_color_use_as_albedo = true
	nut.material = nm
	_feed_fruit = MultiMesh.new()
	_feed_fruit.transform_format = MultiMesh.TRANSFORM_3D
	_feed_fruit.use_colors = true
	_feed_fruit.mesh = nut
	_feed_fruit.instance_count = FRUIT_N
	for i in FRUIT_N:
		var kind := i % 3
		var c := Color("#8a5a33") if kind == 0 else (Color("#e3cf9f") if kind == 1 else Color("#3d1f1c"))
		_feed_fruit.set_instance_color(i, c)
	for mm in [_feed_air, _feed_rice, _feed_fruit]:
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	_feed_bowl = Node3D.new()
	root.add_child(_feed_bowl)


func _fruit_scale(i: int) -> Vector3:
	var kind := i % 3
	if kind == 0:
		return Vector3(0.022, 0.014, 0.034)     # almond
	if kind == 1:
		return Vector3(0.03, 0.016, 0.02)       # cashew
	return Vector3(0.016, 0.013, 0.016)         # raisin


## A grain's flight from the spout to where it ends up (in the helmet, or spilled on the floor).
func _feed_flight(i: int, n: int, t: float, t0: float, span: float, rest: Vector3, salt: float) -> Transform3D:
	var born := t0 + span * float(i) / n + _hash(i * 1.3 + salt) * 0.04
	var hide := Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), rest)
	if t < born:
		return hide
	var spout := SPOUT + Vector3(0, 0, _valve_z) + Vector3(-0.08, 0.0, (_hash(i * 2.1 + salt) - 0.5) * 0.06)
	var fly := 0.16 + _hash(i * 4.7 + salt) * 0.08
	var k := clampf((t - born) / fly, 0.0, 1.0)
	var at := Motion.arc(spout, rest, 0.12 + _hash(i * 6.1 + salt) * 0.1, k)
	var spin := Basis.from_euler(Vector3(_hash(i * 3.3 + salt) * TAU + k * 9.0, _hash(i * 8.9 + salt) * TAU, k * 6.0))
	return Transform3D(spin, at)


func _pose_feed(p: Dictionary, t: float, ctx: Dictionary, origin: Vector3) -> void:
	if _feed_air == null:
		return
	var f: Dictionary = p["feed"]
	var air := float(f.get("air", 1.0e9))
	var rice := float(f.get("rice", 1.0e9))
	var fruit := float(f.get("fruit", 1.0e9))
	var doff := float(f.get("doff", 1.0e9))
	var bowl_at: Array = f.get("bowl", [3.4, 0.62, -6.38])
	var bowl := Vector3(float(bowl_at[0]), float(bowl_at[1]), float(bowl_at[2]))
	var holder = ctx["actor"].call(String(f.get("holder", ""))) if ctx.has("actor") else null
	# The helmet: off his head and into his hands, upside down under the spout.
	if holder != null and not _feed_ready:
		var hat := holder.find_child("hardhat", true, false) as Node3D
		if hat != null:
			_feed_hat = hat
			var copy := hat.duplicate() as Node3D
			_feed_bowl.add_child(copy)
			copy.transform = Transform3D.IDENTITY
			_feed_bowl.set_meta("scale", hat.global_basis.get_scale())
			_feed_ready = true
	var held := t >= doff
	if _feed_hat != null:
		_feed_hat.visible = not held
	_feed_bowl.visible = held
	if held and _feed_ready:
		var sc: Vector3 = _feed_bowl.get_meta("scale")
		# Lands in his hands with a small dip when the rice starts to weigh in.
		var dip := 0.025 * Motion.out_cubic(Motion.seg(t, rice, rice + 0.6))
		if t > fruit:
			dip += 0.02 * Motion.impact(t - fruit, 0.6, 5.0, 8.0)
		_feed_bowl.transform = Transform3D(Basis(Vector3.RIGHT, PI).scaled(sc), bowl + Vector3(0, -dip, 0))
		if holder != null:
			var hb := _feed_bowl.global_position
			holder.aim_hand("l", hb + Vector3(0, 0.02, 0.17), 1.0)
			holder.aim_hand("r", hb + Vector3(0, 0.02, -0.17), 1.0)
	# The blast: grit and air bursting out of the spout and rolling over him.
	for i in _feed_air.instance_count:
		var age := t - air - i * 0.025
		var xf := Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), bowl)
		if age > 0.0 and age < 0.9:
			var spout := SPOUT + Vector3(0, 0, _valve_z)
			var dir := Vector3(-1.0, 0.25 + (_hash(i * 2.7) - 0.4) * 0.5, (_hash(i * 5.1) - 0.5) * 0.7).normalized()
			var dist := 1.4 * (1.0 - exp(-age * 4.5))
			var size := 0.12 + age * 0.9
			xf = Transform3D(Basis.from_scale(Vector3.ONE * size), spout + dir * dist + Vector3(0, age * 0.15, 0))
		_feed_air.set_instance_transform(i, xf)
	# Puffed rice: fills the helmet (a mound that grows), a few spill over the rim.
	var fill := 0.0
	for i in RICE_N:
		var spill := _hash(i * 9.7) < 0.14
		var a := _hash(i * 7.3) * TAU
		var rr := sqrt(_hash(i * 1.9)) * 0.15
		var layer := float(i) / RICE_N
		var rest := bowl + Vector3(cos(a) * rr, -0.05 + layer * 0.13 - rr * 0.25, sin(a) * rr)
		if spill:
			rest = bowl + Vector3(cos(a) * (0.28 + _hash(i * 3.9) * 0.3), -bowl.y + 0.012, sin(a) * (0.28 + _hash(i * 3.9) * 0.3))
		var xf := _feed_flight(i, RICE_N, t, rice, 0.95, rest, 0.0)
		_feed_rice.set_instance_transform(i, xf)
	# Dry fruit on top of the rice.
	for i in FRUIT_N:
		var a := _hash(i * 4.1 + 2.0) * TAU
		var rr := sqrt(_hash(i * 2.3 + 1.0)) * 0.13
		var spill := _hash(i * 6.6) < 0.12
		var rest := bowl + Vector3(cos(a) * rr, 0.09 + _hash(i * 8.2) * 0.04, sin(a) * rr)
		if spill:
			rest = bowl + Vector3(cos(a) * 0.4, -bowl.y + 0.01, sin(a) * 0.4)
		var xf := _feed_flight(i, FRUIT_N, t, fruit, 0.55, rest, 5.0)
		xf.basis = xf.basis.scaled(_fruit_scale(i) / 1.0)
		if xf.basis.get_scale().x < 0.001:
			xf.basis = Basis.from_scale(Vector3.ONE * 0.0001)
		_feed_fruit.set_instance_transform(i, xf)


# ------------------------------------------------------------------------------ line 8: laps and yoga

func _build_mats(root: Node3D, p: Dictionary) -> void:
	if not p.has("mats"):
		return
	_mats = Node3D.new()
	root.add_child(_mats)
	var board := _mat("#8a6a45", 0.95)
	var worn := _mat("#6f5233", 0.95)
	var k := 0
	for m in p["mats"].get("at", []):
		var sheet := _box(_mats, Vector3(0.78, 0.018, 1.55), Vector3(float(m[0]), 0.012, float(m[1])), board if k % 2 == 0 else worn)
		sheet.rotation.y = float(m[2]) if m.size() > 2 else 0.0
		sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# A fold line across the middle where the carton was opened flat.
		_box(_mats, Vector3(0.78, 0.02, 0.02), Vector3(float(m[0]), 0.013, float(m[1])), worn if k % 2 == 0 else board).rotation.y = sheet.rotation.y
		k += 1


## Arms up in a stretch (a Y over the head), optionally a tree pose, optionally a wobble and a fall.
func _pose_yoga(actor, c: Dictionary, t: float, id: String, fwd: Vector3, left: Vector3) -> void:
	var y: Dictionary = c.get("yoga", {})
	var st := float(y.get("start", 1.0e9))
	var pose := String(y.get("pose", "y"))
	var up := clampf(Motion.out_back(Motion.seg(t, st, st + 0.38), 1.4), 0.0, 1.15)
	var hd: Vector3 = actor.anchor_points()[id + ".head"]["pos"]
	if up > 0.0:
		var w := minf(up, 1.0)
		# Warrior pose: arms straight out to the sides at shoulder height, a touch forward.
		var chest: Vector3 = actor.bone_world("spine_03")
		actor.aim_hand("l", chest + left * 0.75 + Vector3.UP * 0.12 + fwd * 0.08, w, 0.04 * w)
		actor.aim_hand("r", chest - left * 0.75 + Vector3.UP * 0.12 + fwd * 0.08, w, 0.04 * w)
	if pose == "tree" or pose == "wobble":
		var lift := Motion.smooth(Motion.seg(t, st + 0.15, st + 0.5))
		if lift > 0.0:
			var knee: Vector3 = actor.bone_world("calf_r")
			var rest: Vector3 = actor.bone_world("foot_l")
			actor.aim_foot("l", rest.lerp(knee + left * 0.07 - Vector3.UP * 0.04, lift), left + fwd * 0.5)
	if pose == "wobble":
		var fall := float(y.get("fall", 1.0e9))
		var sway := sin((t - st) * 10.0) * 0.08 * Motion.seg(t, st + 0.35, fall)
		var tip := Motion.in_cubic(Motion.seg(t, fall, fall + 0.42)) * 1.4
		var bounce := 0.06 * Motion.impact(t - fall - 0.42, 1.0, 6.0, 9.0) if t > fall + 0.42 else 0.0
		actor.rotation.z = sway + tip - bounce


# ------------------------------------------------------------------------------ line 11: day nine, the narrow pipe, khichdi

## params.tally = {"from", "x", "y", "z", "draw0", "draw1", "drawer"}: eight chalk marks on the -X wall and the
## ninth drawn between draw0 and draw1 by the crew member "drawer" (hand IK on the chalk).
## params.narrow = {"from", "at": [x, y, z] (where its mouth ends up), "t0", "t1", "bottle", "catch", "open",
## "catcher"}: a 6-inch pipe slides out of the rubble, a bottle of khichdi shoots out into the catcher's
## hands, the cap comes off and it steams.
var _tally: Node3D
var _tally_new: MeshInstance3D
var _tally_later: Array = []
var _narrow: Node3D
var _narrow_pipe: Node3D
var _bottle: Node3D
var _cap: Node3D
var _meal_puff: MultiMesh
var _steam: MultiMesh
var _bottle_steam: MultiMeshInstance3D


func _chalk() -> StandardMaterial3D:
	var m := _mat("#e9e6dc", 0.95)
	m.emission_enabled = true
	m.emission = Color("#e9e6dc")
	m.emission_energy_multiplier = 0.25
	return m


func _build_meal(root: Node3D, p: Dictionary) -> void:
	if p.has("tally"):
		var tp: Dictionary = p["tally"]
		# Chalk on the shotcrete: a decal projected flat onto the wall (a five-gate and three more),
		# and the ninth stroke as its own decal that grows top-down while it is being drawn.
		_tally = Node3D.new()
		_tally.position = Vector3(float(tp.get("x", -4.6)), float(tp.get("y", 1.35)), float(tp.get("z", 1.0)))
		root.add_child(_tally)
		var marks := Decal.new()
		marks.texture_albedo = _chalk_texture(8, 256, 160)
		marks.size = Vector3(0.36, 0.9, 0.56)
		marks.rotation.z = -PI * 0.5
		marks.albedo_mix = 1.0
		_tally.add_child(marks)
		_tally_new = null
		var stroke := Decal.new()
		stroke.texture_albedo = _chalk_texture(1, 128, 24)
		stroke.size = Vector3(0.3, 0.9, 0.05)
		stroke.rotation.z = -PI * 0.5
		stroke.name = "ninth"
		_tally.add_child(stroke)
		# Later days (params.tally.later = [{"t", "marks", "draw0", "draw1"}]): the wall with more marks, and the
		# next stroke drawn the same way.
		for lt in tp.get("later", []):
			var lay := _tally_layout(int(lt.get("marks", 12)))
			var md := Decal.new()
			md.texture_albedo = _chalk_groups(int(lt.get("marks", 12)), 256, int(160.0 * float(lay["span"])), float(lay["span"]))
			md.size = Vector3(0.36, 0.9, float(lay["len"]))
			md.rotation.z = -PI * 0.5
			md.albedo_mix = 1.0
			md.position = Vector3(0, 0, float(lay["c"]))
			md.visible = false
			_tally.add_child(md)
			var sd := Decal.new()
			sd.texture_albedo = _chalk_texture(1, 128, 24)
			sd.size = Vector3(0.3, 0.9, 0.05)
			sd.rotation.z = -PI * 0.5
			sd.visible = false
			_tally.add_child(sd)
			_tally_later.append({"marks": md, "stroke": sd, "z": float(lay["next_z"])})
	if p.has("narrow"):
		var np: Dictionary = p["narrow"]
		_narrow = Node3D.new()
		_narrow.visible = false
		root.add_child(_narrow)
		_narrow_pipe = Node3D.new()
		_narrow.add_child(_narrow_pipe)
		var steel := _mat("#7c8083", 0.4, 0.75)
		var outer := _rod(_narrow_pipe, Vector3(0, 0, -2.4), Vector3.ZERO, 0.085, steel, 16)
		outer.name = "narrow_outer"
		var lip := _rod(_narrow_pipe, Vector3(0, 0, -0.05), Vector3(0, 0, 0.0), 0.1, steel, 16)
		for m in [outer, lip]:
			var cm := (m as MeshInstance3D).mesh as CylinderMesh
			cm.cap_top = false
			cm.cap_bottom = false
		var hole := MeshInstance3D.new()
		var hm := CylinderMesh.new()
		hm.top_radius = 0.07
		hm.bottom_radius = 0.07
		hm.height = 0.005
		hole.mesh = hm
		hole.material_override = _mat("#0b0b0b", 0.9)
		hole.rotation.x = PI * 0.5
		hole.position = Vector3(0, 0, -0.3)
		hole.name = "narrow_hole"
		_narrow_pipe.add_child(hole)
		# A bare bulb the men have strung up on a pole by the rubble: the warm key on the pipe and their faces.
		var bulb_at := Vector3(-2.9, 2.4, -14.3)
		_rod(_narrow, Vector3(-2.9, 0, -14.3), bulb_at + Vector3(0, 0.1, 0), 0.025, _mat("#5b4a38", 0.8), 6)
		var bulb := _box(_narrow, Vector3(0.09, 0.12, 0.09), bulb_at, _lit("#ffd28a", 9.0))
		bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var key := OmniLight3D.new()
		key.position = bulb_at - Vector3(0, 0.1, 0)
		key.light_color = Color("#ffc47e")
		key.light_energy = 2.4
		key.omni_range = 7.0
		key.shadow_enabled = true
		key.light_volumetric_fog_energy = 0.8
		_narrow.add_child(key)
		# A hand lamp left on the rubble beside the pipe: catches the pipe's lip and the faces from the front.
		var hand_lamp := OmniLight3D.new()
		hand_lamp.position = Vector3(-1.05, 1.55, -15.95)
		hand_lamp.light_color = Color("#ffd8a8")
		hand_lamp.light_energy = 0.7
		hand_lamp.omni_range = 3.2
		hand_lamp.omni_attenuation = 1.5
		hand_lamp.shadow_enabled = true
		_narrow.add_child(hand_lamp)
		# The bottle: the same wide-mouth plastic bottle of khichdi the kitchen fills, a little big so it reads
		# (origin at its middle here).
		_bottle = Node3D.new()
		_bottle.visible = false
		root.add_child(_bottle)
		var real := SiteKitchen.wide_bottle(true)
		real.position = Vector3(0, -0.144, 0)
		real.scale = Vector3.ONE * 1.25
		_bottle.add_child(real)
		_cap = real.get_node("cap")
		_bottle_steam = SiteKitchen.steam(14, 0.34)
		root.add_child(_bottle_steam)
		# Dust out of the rubble, steam out of the bottle.
		var puff := SphereMesh.new()
		puff.radius = 0.5
		puff.height = 1.0
		puff.radial_segments = 10
		puff.rings = 5
		var dm := _mat("#b9a68c", 1.0)
		dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dm.albedo_color = Color(0.75, 0.68, 0.58, 0.16)
		puff.material = dm
		_meal_puff = MultiMesh.new()
		_meal_puff.transform_format = MultiMesh.TRANSFORM_3D
		_meal_puff.mesh = puff
		_meal_puff.instance_count = 12
		var steam_mesh := SphereMesh.new()
		steam_mesh.radius = 0.5
		steam_mesh.height = 1.0
		steam_mesh.radial_segments = 10
		steam_mesh.rings = 5
		var sm := _mat("#ffffff", 1.0)
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.albedo_color = Color(1, 1, 1, 0.13)
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		steam_mesh.material = sm
		_steam = MultiMesh.new()
		_steam.transform_format = MultiMesh.TRANSFORM_3D
		_steam.mesh = steam_mesh
		_steam.instance_count = 10
		for mm in [_meal_puff, _steam]:
			var mi := MultiMeshInstance3D.new()
			mi.multimesh = mm
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(mi)


func _pose_meal(p: Dictionary, t: float, ctx: Dictionary, origin: Vector3) -> void:
	if _tally != null:
		var tp: Dictionary = p["tally"]
		_tally.visible = t >= float(tp.get("from", 0.0)) and t < float(tp.get("until", 1.0e9))
		var d0 := float(tp.get("draw0", 1.0e9))
		var d1 := float(tp.get("draw1", 1.0e9))
		var k := Motion.in_out(Motion.seg(t, d0, d1))
		var ninth := _tally.get_node("ninth") as Decal
		var h := 0.3 * maxf(k, 0.001)
		ninth.size = Vector3(h, 0.9, 0.05)
		ninth.position = Vector3(0, 0.15 - h * 0.5, -0.27)
		ninth.visible = k > 0.0
		var drawer = ctx["actor"].call(String(tp.get("drawer", ""))) if ctx.has("actor") else null
		if drawer != null and drawer.visible:
			var tip := origin + _tally.position + Vector3(-0.3, 0.15 - 0.3 * k, -0.27)
			var w := Motion.smooth(Motion.seg(t, d0 - 0.35, d0)) * (1.0 - Motion.smooth(Motion.seg(t, d1 + 0.15, d1 + 0.5)))
			drawer.aim_hand("l", tip, w, 0.05 * w)
		var later: Array = tp.get("later", [])
		var current := -1
		for i in later.size():
			if t >= float(later[i].get("t", 1.0e9)):
				current = i
		if current >= 0:
			(_tally.get_child(0) as Node3D).visible = false
			ninth.visible = false
		for i in _tally_later.size():
			var e: Dictionary = _tally_later[i]
			var on := i == current
			(e["marks"] as Decal).visible = on
			var sd := e["stroke"] as Decal
			sd.visible = false
			if not on:
				continue
			var l0 := float(later[i].get("draw0", 1.0e9))
			var l1 := float(later[i].get("draw1", 1.0e9))
			var lk := Motion.in_out(Motion.seg(t, l0, l1))
			var lh := 0.3 * maxf(lk, 0.001)
			sd.size = Vector3(lh, 0.9, 0.05)
			sd.position = Vector3(0, 0.15 - lh * 0.5, float(e["z"]))
			sd.visible = lk > 0.0
			if drawer != null and drawer.visible:
				var ltip := origin + _tally.position + Vector3(-0.3, 0.15 - 0.3 * lk, float(e["z"]))
				var lw := Motion.smooth(Motion.seg(t, l0 - 0.35, l0)) * (1.0 - Motion.smooth(Motion.seg(t, l1 + 0.15, l1 + 0.5)))
				drawer.aim_hand("l", ltip, lw, 0.05 * lw)
	if _narrow == null:
		return
	var np: Dictionary = p["narrow"]
	_narrow.visible = t >= float(np.get("from", 0.0)) and t < float(np.get("until", 1.0e9))
	var at: Array = np.get("at", [-1.6, 1.0, -16.5])
	var mouth := Vector3(float(at[0]), float(at[1]), float(at[2]))
	var t0 := float(np.get("t0", 1.0e9))
	var t1 := float(np.get("t1", 1.0e9))
	# It noses out of the rubble in jerks (the drill behind it), then a last shove.
	var out := Motion.out_back(Motion.seg(t, t0, t1), 1.3) + 0.04 * sin((t - t0) * 30.0) * Motion.seg(t, t0, t1) * (1.0 - Motion.seg(t, t1 - 0.1, t1))
	_narrow_pipe.position = mouth + Vector3(0, 0, -0.75 + 0.75 * out)
	for i in _meal_puff.instance_count:
		var age := t - t0 - i * 0.04
		var xf := Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), mouth)
		if age > 0.0 and age < 1.4:
			var dir := Vector3((_hash(i * 2.7) - 0.5) * 1.2, 0.3 + _hash(i * 5.1) * 0.6, 0.6 + _hash(i * 1.3) * 0.6).normalized()
			xf = Transform3D(Basis.from_scale(Vector3.ONE * (0.08 + age * 0.45)), mouth + dir * 0.9 * (1.0 - exp(-age * 3.0)) + Vector3(0, -0.05, 0))
		_meal_puff.set_instance_transform(i, xf)
	# The bottle: out of the pipe on a short arc into his hands; the cap twists off; steam.
	var tb := float(np.get("bottle", 1.0e9))
	var tc := float(np.get("catch", tb + 0.35))
	var top := float(np.get("open", 1.0e9))
	var catcher = ctx["actor"].call(String(np.get("catcher", ""))) if ctx.has("actor") else null
	_bottle.visible = t >= tb and t < float(np.get("bottle_until", 1.0e9)) and _narrow.visible
	if _bottle.visible:
		var hands := mouth + Vector3(0, -0.25, 0.75)
		var show := hands
		if catcher != null:
			var cid := String(np.get("catcher", ""))
			var head: Vector3 = catcher.anchor_points()[cid + ".head"]["pos"] - origin
			var yaw: float = catcher.rotation.y
			var fwd := Vector3(sin(yaw), 0, cos(yaw))
			var left := Vector3(cos(yaw), 0, -sin(yaw))
			hands = head + fwd * 0.45 + Vector3(0, -0.45, 0)
			# Held up beside his face like a trophy once it is caught: on his left, the side the bulb lights.
			show = head + fwd * 0.55 + left * 0.17 + Vector3(0, -0.08, 0)
		hands = hands.lerp(show, Motion.out_back(Motion.seg(t, tc + 0.05, tc + 0.4), 1.4))
		var k := clampf((t - tb) / maxf(tc - tb, 0.01), 0.0, 1.0)
		var start := _narrow_pipe.position + Vector3(0, 0, -0.1)
		var pos := Motion.arc(start, hands, 0.28, Motion.out_cubic(k)) if t < tc else hands
		_bottle.position = pos
		_bottle.rotation = Vector3(PI * 0.5 * (1.0 - k), 0, 0)
		var lift := Motion.out_cubic(Motion.seg(t, top, top + 0.35))
		_cap.position = Vector3(0, 0.206 + 0.08 * lift, 0.03 * lift)
		_cap.rotation.y = -6.0 * Motion.seg(t, top - 0.3, top)
		_cap.visible = t < top + 0.45
		if catcher != null and t >= tc - 0.12:
			var bw := origin + _bottle.position
			catcher.aim_hand("l", bw + Vector3(0, -0.08, 0), 1.0, 0.05)
			if t > top - 0.35 and t < top + 0.4:
				catcher.aim_hand("r", bw + Vector3(0, 0.17, 0), 1.0, 0.05)
	if _bottle_steam != null:
		var on := Motion.smooth(Motion.seg(t, top, top + 0.3)) if _bottle.visible else 0.0
		SiteKitchen.steam_pose(_bottle_steam, t, _bottle.position + Vector3(0, 0.16, 0), 0.025, 0.32, 1.4, 0.09, on, Vector3(0.05, 0, 0.1))
	for i in _steam.instance_count:
		var xf := Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), mouth)
		if false and _bottle.visible and t > top:
			var life := 1.3
			var age := fposmod(t - top + i * life / _steam.instance_count, life)
			if t - top > i * life / _steam.instance_count * 0.6:
				var rise := Vector3(sin(age * 3.0 + i) * 0.05 * age, age * 0.45, cos(age * 2.0 + i) * 0.04 * age)
				xf = Transform3D(Basis.from_scale(Vector3.ONE * (0.04 + age * 0.12)), _bottle.position + Vector3(0, 0.24, 0) + rise)
		_steam.set_instance_transform(i, xf)


# ------------------------------------------------------------------------------ line 12: the camera down the pipe

## params.scope = {"from", "t0", "t_out", "t_stop"}: an endoscope crawls the narrow pipe from deep in the plug
## (t0) to its mouth (t_out) and pokes out (t_stop). The narrow pipe gets a long open interior for the POV.
## Anchors: scope (the lens), scope_ahead (where it looks), scope_chase / scope_chase_ahead (a camera riding
## just behind the head, inside the pipe). Role "wave": a hand waving over the head.
const SCOPE_LEN := 22.0
## The inside of the narrow pipe: dark mill-scaled steel, rust blooms, and scratches running along its length
## (the drill string scraped through), so the walls rushing past read as speed. Mesh-local: the pipe's axis is Y.
## Lit in the shader, not by the scene: inside the rubble the tunnel's lamps would shine straight through the thin
## tube. Light = a pool round the endoscope's LEDs (mostly ahead of it), the warm daylight of the mouth bleeding
## in, and nearly black between. `head` / `mouth` are world positions, `fwd` the pipe's direction (set per frame).
const PIPE_SHADER := """
shader_type spatial;
render_mode cull_disabled, unshaded;
uniform vec3 head = vec3(0.0);
uniform vec3 mouth = vec3(0.0);
uniform vec3 fwd = vec3(0.0, 0.0, 1.0);
uniform float out_light = 1.0;
varying vec3 lp;
varying vec3 wp;
void vertex() { lp = VERTEX; wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
//NOISE
float lighting() {
	float s = dot(wp - head, fwd);                  // + ahead of the head
	float led = s > 0.0 ? 0.65 * exp(-s * 0.45) : 0.4 * exp(s * 7.0);
	float m = dot(mouth - wp, fwd);                 // distance back from the mouth
	float day = out_light * 1.4 * exp(-max(m, 0.0) * 0.9);
	return 0.015 + led + day;
}
void fragment() {
	float a = atan(lp.z, lp.x);
	float rust = smoothstep(0.45, 0.75, fbm(vec3(a * 3.0, lp.y * 1.6, 0.0)));
	float scratch = smoothstep(0.82, 0.97, n3(vec3(a * 40.0, lp.y * 0.6, 0.0)));
	float band = smoothstep(0.7, 0.95, n3(vec3(a * 4.0, lp.y * 0.25, 3.0)));
	vec3 steel = vec3(0.16, 0.15, 0.145) * (0.8 + 0.4 * fbm(vec3(a * 9.0, lp.y * 6.0, 1.0)));
	vec3 col = mix(steel, vec3(0.34, 0.16, 0.07), rust * 0.85);
	col = mix(col, vec3(0.55, 0.53, 0.5), scratch * (1.0 - rust) * 0.6);
	col *= 1.0 - band * 0.35;
	float l = lighting();
	// Scratches glint where the light is.
	col += vec3(0.5, 0.52, 0.55) * scratch * (1.0 - rust) * 0.12 * min(l, 1.0);
	ALBEDO = col * l * vec3(1.0, 0.97, 0.92);
}
"""

var _scope: Node3D
var _scope_tube: MeshInstance3D
var _pipe_mat: ShaderMaterial
var _scope_light: SpotLight3D
var _scope_cable: MeshInstance3D


func _build_scope(root: Node3D, p: Dictionary) -> void:
	if not p.has("scope") or _narrow == null:
		return
	# The pipe's inside, open, as long as the plug: rusty steel, weld seams every 6 m, scratches.
	var tube := CylinderMesh.new()
	tube.top_radius = 0.078
	tube.bottom_radius = 0.078
	tube.height = SCOPE_LEN
	tube.radial_segments = 64
	tube.rings = 40
	tube.cap_top = false
	tube.cap_bottom = false
	var pipe_sh := Shader.new()
	pipe_sh.code = PIPE_SHADER.replace("//NOISE", NOISE_GLSL)
	var inner := ShaderMaterial.new()
	inner.shader = pipe_sh
	_pipe_mat = inner
	_scope_tube = MeshInstance3D.new()
	_scope_tube.mesh = tube
	_scope_tube.material_override = inner
	_scope_tube.rotation.x = PI * 0.5
	_scope_tube.position = Vector3(0, 0, -SCOPE_LEN * 0.5 - 0.06)
	_narrow_pipe.add_child(_scope_tube)
	var seam := TorusMesh.new()
	seam.inner_radius = 0.07
	seam.outer_radius = 0.079
	seam.rings = 24
	seam.ring_segments = 6
	var seam_m := _mat("#3a2e27", 0.5, 0.6)
	var z := -0.6
	while z > -SCOPE_LEN:
		var r := MeshInstance3D.new()
		r.mesh = seam
		r.material_override = seam_m
		r.rotation.x = PI * 0.5
		r.position = Vector3(0, 0, z)
		_narrow_pipe.add_child(r)
		z -= 1.5 if fposmod(-z, 6.0) > 0.5 else 1.2
	# The endoscope: a slim head with a ring of LEDs on a black cable.
	_scope = Node3D.new()
	root.add_child(_scope)
	var head := _rod(_scope, Vector3(0, 0, -0.12), Vector3(0, 0, 0.0), 0.028, _mat("#2a2c2f", 0.3, 0.8), 14)
	head.name = "scope_head"
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.016
	tm.outer_radius = 0.026
	ring.mesh = tm
	ring.material_override = _lit("#eaf6ff", 6.0)
	ring.rotation.x = PI * 0.5
	ring.position = Vector3(0, 0, 0.002)
	_scope.add_child(ring)
	_scope_light = SpotLight3D.new()
	_scope_light.light_color = Color("#e6f3ff")
	_scope_light.light_energy = 0.9
	_scope_light.spot_range = 9.0
	_scope_light.spot_angle = 55.0
	_scope_light.rotation.y = PI          # SpotLight shines along -Z; the scope looks along +Z
	_scope.add_child(_scope_light)
	# LED spill on the pipe wall right round the head, so the steel rushing past reads.
	var spill := OmniLight3D.new()
	spill.light_color = Color("#dfeeff")
	spill.light_energy = 0.05
	spill.omni_range = 0.9
	spill.omni_attenuation = 2.0
	spill.position = Vector3(0, 0, 0.05)
	spill.name = "spill"
	_scope.add_child(spill)
	var cm := CylinderMesh.new()
	cm.top_radius = 0.011
	cm.bottom_radius = 0.011
	cm.height = 1.0
	cm.radial_segments = 10
	cm.rings = 1
	_scope_cable = MeshInstance3D.new()
	_scope_cable.mesh = cm
	_scope_cable.material_override = _mat("#141414", 0.45, 0.2)
	root.add_child(_scope_cable)


func _pose_scope(p: Dictionary, t: float, out: Dictionary, origin: Vector3) -> void:
	if _scope == null:
		return
	var sp: Dictionary = p["scope"]
	var on := t >= float(sp.get("from", 1.0e9))
	_scope.visible = on
	_scope_cable.visible = on
	var hole := _narrow_pipe.get_node_or_null("narrow_hole") as Node3D
	if hole != null:
		hole.visible = not on
	if not on:
		return
	var at: Array = p["narrow"].get("at", [-1.6, 1.0, -16.45])
	var mouth := Vector3(float(at[0]), float(at[1]), float(at[2]))
	var t0 := float(sp.get("t0", 1.0e9))
	var t_out := float(sp.get("t_out", 1.0e9))
	var t_stop := float(sp.get("t_stop", 1.0e9))
	var z: float
	if t < t_out:
		var k := Motion.seg(t, t0, t_out)
		z = mouth.z - (SCOPE_LEN - 1.5) * (1.0 - (0.7 * k + 0.3 * Motion.smooth(k)))
	else:
		z = mouth.z + 0.38 * Motion.out_cubic(Motion.seg(t, t_out, t_stop))
	# Inside, the head slides along the floor of the pipe (its weight and the cable's keep it down), juddering over
	# the weld seams; just before the mouth it is lifted to the axis, and once out it nods (steered from outside).
	var low := -0.045 * (1.0 - Motion.smooth(Motion.seg(t, t_out - 0.45, t_out - 0.05)))
	var base := Vector3(mouth.x, mouth.y + low, z)
	var wob := Vector3(sin(t * 7.3) * 0.005, absf(sin(t * 23.0)) * 0.003, 0.0) if t < t_out else Vector3(sin(t * 7.3) * 0.004, cos(t * 5.1) * 0.004, 0.0)
	_scope.position = base + wob
	var look := Vector3(0.0, 0.0, 1.0)
	if t > t_out:
		var u := Motion.smooth(Motion.seg(t, t_out, t_stop + 0.4))
		look = Vector3(0.12 * sin((t - t_out) * 1.3), 0.32 * u, 1.0).normalized()
	_scope.basis = Basis.looking_at(-look, Vector3.UP)
	# Out of the pipe the LEDs dim so the faces in front of the lens do not burn out.
	_scope_light.light_energy = lerpf(0.9, 0.7, Motion.smooth(Motion.seg(t, t_out - 0.2, t_out + 0.25)))
	(_scope.get_node("spill") as OmniLight3D).light_energy = lerpf(0.05, 0.15, Motion.smooth(Motion.seg(t, t_out - 0.2, t_out + 0.25)))
	_pipe_mat.set_shader_parameter("head", origin + _scope.position)
	_pipe_mat.set_shader_parameter("mouth", origin + mouth)
	_pipe_mat.set_shader_parameter("fwd", Vector3(0, 0, 1))
	# The cable comes out of the back of the head and trails along the floor of the pipe to the rig outside.
	var back := _scope.position - look * 0.12
	var tail := Vector3(mouth.x, mouth.y - 0.06, mouth.z - SCOPE_LEN)
	_span(_scope_cable, back, tail)
	out["scope"] = origin + _scope.position + look * 0.03
	out["scope_ahead"] = origin + _scope.position + look * 3.0
	# The chase camera rides steady just above and behind the head (not with its judder), looking down the pipe.
	out["scope_chase"] = origin + Vector3(base.x, mouth.y, base.z - 0.3)
	out["scope_chase_ahead"] = origin + Vector3(base.x, mouth.y - 0.01, base.z + 4.0)


## Stretch a unit-length (height 1, centred, along +Y) cylinder node from a to b.
func _span(node: Node3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.99 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	node.transform = Transform3D(Basis(x, y * maxf(d.length(), 0.001), z), (a + b) * 0.5)


## Waving: the right hand over the head, swinging side to side.
func _pose_wave(actor, c: Dictionary, t: float, id: String, fwd: Vector3, left: Vector3) -> void:
	var w: Dictionary = c.get("wave", {})
	var st := float(w.get("start", 1.0e9))
	var k := Motion.out_back(Motion.seg(t, st, st + 0.3), 1.3)
	if k <= 0.0:
		return
	var hd: Vector3 = actor.anchor_points()[id + ".head"]["pos"]
	var swing := sin((t - st) * float(w.get("speed", 9.0)) + float(w.get("phase", 0.0))) * 0.22
	var side := -left if String(w.get("hand", "r")) == "r" else left
	var hand := "r" if String(w.get("hand", "r")) == "r" else "l"
	actor.aim_hand(hand, hd + side * (0.42 + swing * 0.5) + Vector3.UP * (0.22 + swing * 0.15) + fwd * 0.25, minf(k, 1.0), 0.06)



## Chalk strokes on a transparent image. n = 8: a five-gate (four and a slash) and three more; n = 1: one stroke.
## Image x runs down the wall (the decal's local X points down after its roll), image y runs along it.
## Where a tally of n marks sits on the wall (same scale and left edge as the eight-mark tally): its length, its
## centre along z, the span in gate units, and where the next stroke goes.
func _tally_layout(n: int) -> Dictionary:
	var gates := n / 5
	var rem := n % 5
	var u_next := gates * 0.6 + 0.02 + rem * 0.12
	var span := u_next + 0.1
	var length := 0.56 * span
	var c := 0.28 - 0.5 * length
	return {"span": span, "len": length, "c": c, "next_z": (1.0 - u_next / span - 0.5) * length + c}


## A tally of n chalk marks in gates of five (four strokes and a slash), the same hand as _chalk_texture.
func _chalk_groups(n: int, w: int, h: int, span: float) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 190 + n
	var strokes := []
	var gates := n / 5
	for gi in gates:
		var base := gi * 0.6
		for k in 4:
			var v := base + 0.08 + k * 0.1
			strokes.append([v + rng.randf_range(-0.01, 0.01), 0.06, v + rng.randf_range(-0.015, 0.015), 0.94])
		strokes.append([base + 0.02, 0.82, base + 0.44, 0.18])
	for k in n % 5:
		var v := gates * 0.6 + 0.02 + k * 0.12
		strokes.append([v + rng.randf_range(-0.01, 0.01), 0.06, v + rng.randf_range(-0.015, 0.015), 0.94])
	for st in strokes:
		for i in 221:
			var u := float(i) / 220.0
			var cx := lerpf(float(st[1]), float(st[3]), u) * (w - 1)
			var cy := (1.0 - lerpf(float(st[0]), float(st[2]), u) / span) * (h - 1)
			for dx in range(-4, 5):
				for dy in range(-4, 5):
					var px := int(cx) + dx
					var py := int(cy) + dy
					if px < 0 or py < 0 or px >= w or py >= h:
						continue
					var d := Vector2(dx, dy).length()
					if d > 3.2:
						continue
					var a := (1.0 - d / 3.2) * (0.55 + 0.45 * _hash(px * 0.37 + py * 1.91))
					var old := img.get_pixel(px, py)
					img.set_pixel(px, py, Color(0.93, 0.92, 0.88, maxf(old.a, a)))
	return ImageTexture.create_from_image(img)


func _chalk_texture(n: int, w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 90 + n
	var strokes := []
	if n == 1:
		strokes.append([0.5, 0.0, 0.5, 1.0])
	else:
		for k in 4:
			var v := 0.08 + k * 0.1
			strokes.append([v + rng.randf_range(-0.01, 0.01), 0.06, v + rng.randf_range(-0.015, 0.015), 0.94])
		strokes.append([0.02, 0.82, 0.44, 0.18])        # the slash across the gate
		for k in 3:
			var v := 0.62 + k * 0.12
			strokes.append([v + rng.randf_range(-0.01, 0.01), 0.06, v + rng.randf_range(-0.015, 0.015), 0.94])
	for st in strokes:
		# st = [y0 (along), x0 (down), y1, x1] in 0..1
		var steps := 220
		for i in steps + 1:
			var u := float(i) / steps
			var cx := lerpf(float(st[1]), float(st[3]), u) * (w - 1)
			var along := lerpf(float(st[0]), float(st[2]), u)
			if n > 1:
				along = 1.0 - along          # read from the room the gate comes first, on the left
			var cy := along * (h - 1)
			var r := 2.6 if n == 1 else 3.2
			for dx in range(-4, 5):
				for dy in range(-4, 5):
					var px := int(cx) + dx
					var py := int(cy) + dy
					if px < 0 or py < 0 or px >= w or py >= h:
						continue
					var d := Vector2(dx, dy).length()
					if d > r:
						continue
					var a := (1.0 - d / r) * (0.55 + 0.45 * _hash(px * 0.37 + py * 1.91))
					var old := img.get_pixel(px, py)
					img.set_pixel(px, py, Color(0.93, 0.92, 0.88, maxf(old.a, a)))
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------------------ line 7 (revised): jars out of the pipe

## params.jars = {"from", "list": [{"t" (leaves the outlet), "kind" ("rice" | "fruit"), "catcher" (crew id)}]}:
## a wide outlet on the supply line at the valve; each jar shoots out on a puff of blue air into the catcher's
## hands, then is held up beside his face.
var _outlet: Node3D
var _jars: Array = []
var _jar_air: MultiMesh


func _jar(kind: String) -> Node3D:
	var j := Node3D.new()
	var glass := _mat("#ffffff", 0.05)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.85, 0.95, 1.0, 0.28)
	glass.metallic_specular = 1.0
	_rod(j, Vector3(0, -0.1, 0), Vector3(0, 0.1, 0), 0.075, glass, 18)
	var lid := "#c3352a" if kind == "rice" else "#2f8a3e"
	_rod(j, Vector3(0, 0.1, 0), Vector3(0, 0.135, 0), 0.07, _mat(lid, 0.4), 18)
	var mesh: Mesh
	if kind == "rice":
		var g := CapsuleMesh.new()
		g.radius = 0.011
		g.height = 0.034
		g.radial_segments = 6
		g.rings = 2
		g.material = _lit("#f2e2b5", 0.2)
		mesh = g
	else:
		var n := SphereMesh.new()
		n.radius = 0.5
		n.height = 1.0
		n.radial_segments = 8
		n.rings = 5
		var nm := _mat("#ffffff", 0.6)
		nm.vertex_color_use_as_albedo = true
		n.material = nm
		mesh = n
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = kind != "rice"
	mm.mesh = mesh
	mm.instance_count = 110 if kind == "rice" else 46
	var rng := RandomNumberGenerator.new()
	rng.seed = 31 if kind == "rice" else 32
	for i in mm.instance_count:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 0.058
		var at := Vector3(cos(a) * r, rng.randf_range(-0.09, 0.08), sin(a) * r)
		var b := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, 0))
		if kind != "rice":
			var k := i % 3
			b = b.scaled(Vector3(0.022, 0.014, 0.034) if k == 0 else (Vector3(0.03, 0.016, 0.02) if k == 1 else Vector3(0.016, 0.013, 0.016)))
			mm.set_instance_color(i, Color("#8a5a33") if k == 0 else (Color("#e3cf9f") if k == 1 else Color("#3d1f1c")))
		mm.set_instance_transform(i, Transform3D(b, at))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	j.add_child(mi)
	return j


func _build_jars(root: Node3D, p: Dictionary) -> void:
	if not p.has("jars") or _valve == null:
		return
	# The outlet: a short wide pipe end with a flange off the main, aimed out over the floor.
	_outlet = Node3D.new()
	_outlet.visible = false
	root.add_child(_outlet)
	var steel := _mat("#5c6166", 0.4, 0.75)
	var mouth := SPOUT + Vector3(0, 0.25, _valve_z)
	_rod(_outlet, Vector3(R - 0.32, 0.95, _valve_z), Vector3(R - 0.32, 0.75, _valve_z), 0.11, steel, 16)
	_rod(_outlet, Vector3(R - 0.32, 0.75, _valve_z), mouth, 0.11, steel, 16)
	var lip := _rod(_outlet, mouth, mouth + Vector3(-0.05, 0, 0), 0.14, _mat("#7a7f84", 0.35, 0.8), 18)
	lip.name = "lip"
	var hole := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.1
	hm.bottom_radius = 0.1
	hm.height = 0.005
	hole.mesh = hm
	hole.material_override = _mat("#060606", 0.9)
	hole.rotation.z = PI * 0.5
	hole.position = mouth + Vector3(-0.053, 0, 0)
	_outlet.add_child(hole)
	_outlet.set_meta("mouth", mouth + Vector3(-0.08, 0, 0))
	for j in p["jars"].get("list", []):
		var node := _jar(String(j.get("kind", "rice")))
		node.visible = false
		root.add_child(node)
		_jars.append(node)
	# Blue puffs of air at each launch (same blue as the pipe x-ray).
	var puff := SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	puff.radial_segments = 10
	puff.rings = 5
	var pm := _mat("#8fcfff", 1.0)
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.albedo_color = Color(0.55, 0.8, 1.0, 0.22)
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	puff.material = pm
	_jar_air = MultiMesh.new()
	_jar_air.transform_format = MultiMesh.TRANSFORM_3D
	_jar_air.mesh = puff
	_jar_air.instance_count = 24
	var ami := MultiMeshInstance3D.new()
	ami.multimesh = _jar_air
	ami.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ami)


func _pose_jars(p: Dictionary, t: float, ctx: Dictionary, origin: Vector3) -> void:
	if _outlet == null:
		return
	var jp: Dictionary = p["jars"]
	_outlet.visible = t >= float(jp.get("from", 1.0e9)) and t < float(jp.get("until", 1.0e9))
	var mouth: Vector3 = _outlet.get_meta("mouth")
	var list: Array = jp.get("list", [])
	for i in list.size():
		var j: Dictionary = list[i]
		var node := _jars[i] as Node3D
		var t0 := float(j.get("t", 1.0e9))
		var catcher = ctx["actor"].call(String(j.get("catcher", ""))) if ctx.has("actor") else null
		node.visible = _outlet.visible and t >= t0 - 0.05
		if not node.visible or catcher == null:
			continue
		var cid := String(j.get("catcher", ""))
		var head: Vector3 = catcher.anchor_points()[cid + ".head"]["pos"] - origin
		var yaw: float = catcher.rotation.y
		var fwd := Vector3(sin(yaw), 0, cos(yaw))
		var left := Vector3(cos(yaw), 0, -sin(yaw))
		var catch_at := head + fwd * 0.42 + Vector3(0, -0.5, 0)
		var show := head + fwd * 0.48 + Vector3(0, -0.36, 0)
		var fly := 0.32
		var k := clampf((t - t0) / fly, 0.0, 1.0)
		var pos: Vector3
		if t < t0:
			pos = mouth + Vector3(0.12, 0, 0)            # just inside the mouth
		elif k < 1.0:
			pos = Motion.arc(mouth, catch_at, 0.22, Motion.out_cubic(k))
		else:
			pos = catch_at.lerp(show, Motion.out_back(Motion.seg(t, t0 + fly + 0.08, t0 + fly + 0.45), 1.4))
		var dip := 0.04 * Motion.impact(t - t0 - fly, 0.6, 6.0, 9.0) if t > t0 + fly else 0.0
		node.position = pos + Vector3(0, -dip, 0)
		# Tumbling in flight (lid first out of the pipe), upright once caught.
		var spin := (1.0 - Motion.out_cubic(Motion.seg(t, t0 + fly - 0.1, t0 + fly + 0.1)))
		node.rotation = Vector3(0, 0, PI * 0.5 * spin + (t - t0) * 7.0 * spin * (1.0 if t < t0 + fly else 0.0))
		if t >= t0 + fly - 0.12:
			var w := Motion.smooth(Motion.seg(t, t0 + fly - 0.12, t0 + fly))
			var at := origin + node.position
			catcher.aim_hand("l", at + left * 0.08 + Vector3(0, -0.02, 0), w, 0.04)
			catcher.aim_hand("r", at - left * 0.08 + Vector3(0, -0.02, 0), w, 0.04)
	for i in _jar_air.instance_count:
		var xf := Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), mouth)
		var which := i % maxi(list.size(), 1)
		if which < list.size():
			var age := t - float(list[which].get("t", 1.0e9)) - float(i / maxi(list.size(), 1)) * 0.02
			if age > 0.0 and age < 0.7:
				var dir := Vector3(-1.0, 0.15 + (_hash(i * 2.7) - 0.4) * 0.6, (_hash(i * 5.1) - 0.5) * 0.8).normalized()
				xf = Transform3D(Basis.from_scale(Vector3.ONE * (0.06 + age * 0.5)), mouth + dir * 0.8 * (1.0 - exp(-age * 5.0)))
		_jar_air.set_instance_transform(i, xf)
