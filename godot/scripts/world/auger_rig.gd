extends RefCounted
## The horizontal auger boring rig of the Silkyara rescue (a jack-and-push earth auger, about 25 t).
##
## Built along +Z (the boring direction), base at y = 0, about 9.5 m long and 2.4 m wide:
## two heavy track beams on cross ties, the thrust carriage with its hydraulic rams at the rear,
## the drive unit (engine-gearbox housing, exhaust, control stand), and in front a length of the
## 800 mm casing pipe with the auger's spiral flight showing at its mouth.
## build() returns the rig; the node "flight" is the spiral (spin it about Z), "carriage" slides along Z.

const YELLOW := "#d9a21b"
const STEEL := "#3f4347"


static func _mat(color: String, rough: float = 0.6, metal: float = 0.3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = rough
	m.metallic = metal
	return m


static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _rod(parent: Node3D, a: Vector3, b: Vector3, r: float, mat: Material, sides: int = 14) -> MeshInstance3D:
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


## A helical screw flight around a shaft, along +Z from z0 to z1.
static func _flight(r_in: float, r_out: float, z0: float, z1: float, pitch: float, mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := int((z1 - z0) / pitch * 28.0)
	for i in steps:
		var u0 := float(i) / steps
		var u1 := float(i + 1) / steps
		var a0 := (z1 - z0) * u0 / pitch * TAU
		var a1 := (z1 - z0) * u1 / pitch * TAU
		var za := lerpf(z0, z1, u0)
		var zb := lerpf(z0, z1, u1)
		var p := [Vector3(cos(a0) * r_in, sin(a0) * r_in, za), Vector3(cos(a0) * r_out, sin(a0) * r_out, za),
			Vector3(cos(a1) * r_in, sin(a1) * r_in, zb), Vector3(cos(a1) * r_out, sin(a1) * r_out, zb)]
		for k in [0, 1, 2, 1, 3, 2]:
			st.add_vertex(p[k])
	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return mesh


static func build(with_pipe: bool = true) -> Node3D:
	var rig := Node3D.new()
	rig.name = "auger_rig"
	var steel := _mat(STEEL, 0.55, 0.6)
	var dark := _mat("#1d1f21", 0.6, 0.5)
	var paint := _mat(YELLOW, 0.5, 0.25)
	var worn := _mat("#9a7a2a", 0.7, 0.3)
	var chrome := _mat("#c9ccd0", 0.2, 0.9)
	var red := _mat("#a3241a", 0.5, 0.2)
	# Track: two I-beams on cross ties.
	for sx in [-0.85, 0.85]:
		_box(rig, Vector3(0.32, 0.34, 9.6), Vector3(sx, 0.32, 0.0), steel)
		_box(rig, Vector3(0.46, 0.05, 9.6), Vector3(sx, 0.5, 0.0), steel)
		_box(rig, Vector3(0.46, 0.05, 9.6), Vector3(sx, 0.15, 0.0), steel)
	for k in 7:
		_box(rig, Vector3(2.3, 0.14, 0.3), Vector3(0, 0.07, -4.5 + k * 1.5), dark)
	# Thrust block and the two hydraulic rams at the rear.
	_box(rig, Vector3(2.2, 0.9, 0.6), Vector3(0, 0.95, -4.6), paint)
	for sx in [-0.55, 0.55]:
		_rod(rig, Vector3(sx, 0.95, -4.3), Vector3(sx, 0.95, -2.4), 0.16, paint)
		_rod(rig, Vector3(sx, 0.95, -2.4), Vector3(sx, 0.95, -1.2), 0.09, chrome)
	# The carriage: the drive unit that rides the track.
	var carriage := Node3D.new()
	carriage.name = "carriage"
	rig.add_child(carriage)
	_box(carriage, Vector3(2.1, 0.25, 3.2), Vector3(0, 0.62, -0.4), steel)
	_box(carriage, Vector3(1.9, 1.35, 2.4), Vector3(0, 1.45, -0.6), paint)                # engine housing
	_box(carriage, Vector3(1.95, 0.08, 2.45), Vector3(0, 2.15, -0.6), worn)
	for k in 6:
		_box(carriage, Vector3(0.02, 0.9, 0.06), Vector3(0.96, 1.45, -1.5 + k * 0.32), dark)   # louvres
	_rod(carriage, Vector3(-0.6, 2.15, -1.3), Vector3(-0.6, 2.95, -1.3), 0.07, dark, 10)   # exhaust
	_rod(carriage, Vector3(-0.6, 2.95, -1.3), Vector3(-0.6, 3.0, -1.18), 0.07, dark, 10)
	_rod(carriage, Vector3(0, 1.25, 0.6), Vector3(0, 1.25, 1.35), 0.55, paint, 22)        # gearbox
	_rod(carriage, Vector3(0, 1.25, 1.35), Vector3(0, 1.25, 1.55), 0.42, steel, 22)       # drive flange
	_box(carriage, Vector3(0.5, 1.0, 0.5), Vector3(1.25, 1.1, 0.6), steel)                # control stand
	_box(carriage, Vector3(0.45, 0.3, 0.06), Vector3(1.25, 1.55, 0.86), dark)
	for k in 3:
		_box(carriage, Vector3(0.05, 0.05, 0.05), Vector3(1.12 + k * 0.12, 1.6, 0.9), red if k == 0 else _mat("#2fa84f", 0.4))
	for sx in [-1.0, 1.0]:
		_rod(carriage, Vector3(sx * 0.6, 2.2, -1.8), Vector3(sx * 0.6, 2.2, 0.6), 0.04, dark, 6)   # lifting bars
	# Front: casing pipe with the auger flight at its mouth, on a cradle.
	if with_pipe:
		_box(rig, Vector3(1.5, 0.55, 0.4), Vector3(0, 0.62, 3.6), steel)
		var casing := _rod(rig, Vector3(0, 1.25, 1.6), Vector3(0, 1.25, 4.9), 0.42, _mat("#5b5f60", 0.45, 0.7), 28)
		casing.name = "casing"
		var lip := _rod(rig, Vector3(0, 1.25, 4.85), Vector3(0, 1.25, 4.95), 0.45, steel, 28)
		lip.name = "lip"
		var flight := Node3D.new()
		flight.name = "flight"
		flight.position = Vector3(0, 1.25, 0)
		rig.add_child(flight)
		var mi := MeshInstance3D.new()
		mi.mesh = _flight(0.11, 0.37, 1.6, 5.15, 0.55, _mat("#8d9196", 0.35, 0.85))
		flight.add_child(mi)
		_rod(flight, Vector3(0, 0, 1.6), Vector3(0, 0, 5.3), 0.11, chrome, 12)
		_rod(flight, Vector3(0, 0, 5.15), Vector3(0, 0, 5.4), 0.2, _mat("#2a2c2e", 0.4, 0.8), 10)   # cutting head hub
		for k in 4:
			var a := k * PI * 0.5
			_box(flight, Vector3(0.08, 0.06, 0.14), Vector3(cos(a) * 0.34, sin(a) * 0.34, 5.3), _mat("#d7d9db", 0.25, 0.9))   # teeth
	return rig
