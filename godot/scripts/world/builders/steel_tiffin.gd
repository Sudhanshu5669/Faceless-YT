extends RefCounted
## The same steel carrier and painted routing code across handoffs.

const Meshes = preload("res://scripts/world/builders/kitchen_dressing.gd")
const LID_HEIGHT := 0.204
const HANDLE_HEIGHT := LID_HEIGHT + 0.070


static func build(marking: String = "CH  4") -> Node3D:
	var steel := Meshes.material(Color("#adb8ba"), 0.29, 0.84)
	steel.anisotropy_enabled = true
	steel.anisotropy = 0.35
	var edge := Meshes.material(Color("#ccd0c8"), 0.34, 0.7)
	var seam := Meshes.material(Color("#455357"), 0.43, 0.66)
	var carrier := Node3D.new()
	for tier in range(2):
		var height := 0.035 + tier * 0.069
		_disc(carrier, 0.104, 0.063, Vector3(0, height, 0), steel)
		_disc(carrier, 0.108, 0.007, Vector3(0, height + 0.028, 0), edge)
		_disc(carrier, 0.103, 0.004, Vector3(0, height - 0.031, 0), seam)
	_disc(carrier, 0.104, 0.037, Vector3(0, 0.160, 0), steel)
	var rim := TorusMesh.new()
	rim.inner_radius = 0.090
	rim.outer_radius = 0.109
	rim.rings = 64
	rim.ring_segments = 16
	var rim_node := MeshInstance3D.new()
	rim_node.mesh = rim
	rim_node.material_override = edge
	rim_node.position.y = 0.187
	carrier.add_child(rim_node)
	var lid := Node3D.new()
	lid.name = "lid"
	carrier.add_child(lid)
	_disc(lid, 0.112, 0.017, Vector3.ZERO, steel)
	_disc(lid, 0.107, 0.007, Vector3(0, 0.009, 0), edge)
	var label := Label3D.new()
	label.text = marking
	label.font_size = 58
	label.pixel_size = 0.00081
	label.outline_size = 0
	label.modulate = Color("#142b23")
	label.position = Vector3(0, 0.013, 0.028)
	label.rotation.x = -PI * 0.5
	lid.add_child(label)
	for side in [-1.0, 1.0]:
		Meshes.box(lid, Vector3(0.011, 0.052, 0.018), Vector3(side * 0.049, 0.044, -0.023), steel)
	Meshes.box(lid, Vector3(0.105, 0.015, 0.024), Vector3(0, 0.070, -0.023), edge)
	var latch := Node3D.new()
	latch.name = "latch"
	latch.position = Vector3(0.109, 0.151, 0.014)
	carrier.add_child(latch)
	Meshes.box(latch, Vector3(0.013, 0.072, 0.022), Vector3(0.004, 0.024, 0), edge)
	Meshes.box(latch, Vector3(0.027, 0.012, 0.030), Vector3(0.004, 0.057, 0), steel)
	lid.position.y = LID_HEIGHT
	return carrier


static func _disc(parent: Node3D, radius: float, height: float, position: Vector3, surface: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 64
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = surface
	part.position = position
	parent.add_child(part)
	return part
