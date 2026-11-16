extends RefCounted
## Window-lit Dadar kitchen with a dark stone worktop.

const KitDB = preload("res://scripts/world/kit_db.gd")
const STONE = preload("res://shaders/kitchen_stone.gdshader")

static func build(depth: float, plaster: Color) -> Node3D:
	var room := Node3D.new()
	room.name = "kitchen_dressing"
	var z := -depth * 0.5
	var tiles := [
		material(Color("#a9ad97"), 0.46),
		material(Color("#b5b6a1"), 0.52),
		material(Color("#a3a990"), 0.48),
	]
	var wall := material(plaster, 0.9)
	var frame := material(Color("#635243"), 0.62)
	var stone := ShaderMaterial.new()
	stone.shader = STONE
	var wood := material(Color("#735647"), 0.66)
	var sky := material(Color("#d9e6dc"), 0.95)
	sky.emission_enabled = true
	sky.emission = Color("#c0dbdd")
	sky.emission_energy_multiplier = 0.68
	# Leave an actual opening behind the grille.
	box(room, Vector3(1.78, 3.2, 0.13), Vector3(-1.27, 1.6, z), wall)
	box(room, Vector3(1.78, 3.2, 0.13), Vector3(1.71, 1.6, z), wall)
	box(room, Vector3(1.2, 0.88, 0.13), Vector3(0.22, 0.44, z), wall)
	box(room, Vector3(1.2, 0.97, 0.13), Vector3(0.22, 2.715, z), wall)
	box(room, Vector3(1.32, 0.12, 0.29), Vector3(0.22, 0.88, z + 0.07), stone)
	box(room, Vector3(1.24, 0.05, 0.16), Vector3(0.22, 2.21, z), frame)
	for i in range(8):
		box(room, Vector3(0.017, 1.31, 0.023), Vector3(-0.34 + i * 0.16, 1.54, z + 0.08), frame)
	for y in [1.06, 1.52, 1.98]:
		box(room, Vector3(1.2, 0.018, 0.022), Vector3(0.22, y, z + 0.08), frame)
	box(room, Vector3(6.0, 4.0, 0.06), Vector3(0.22, 1.62, z - 3.4), sky).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_courtyard(room, z)
	for row in range(3):
		for col in range(12):
			var x := -1.62 + col * 0.25
			if x < -0.5 or x > 0.94:
				box(room, Vector3(0.244, 0.238, 0.018), Vector3(x, 0.98 + row * 0.245, z + 0.08),
					tiles[(col * 7 + row * 5) % tiles.size()])
	box(room, Vector3(2.25, 0.76, 0.59), Vector3(0, 0.41, -0.01), wood)
	box(room, Vector3(2.42, 0.058, 0.66), Vector3(0, 0.871, 0), stone)
	box(room, Vector3(2.37, 0.025, 0.67), Vector3(0, 0.835, 0), frame)
	for x in [-0.72, 0.0, 0.72]:
		box(room, Vector3(0.69, 0.62, 0.04), Vector3(x, 0.42, 0.303), wood)
		box(room, Vector3(0.12, 0.016, 0.028), Vector3(x, 0.65, 0.336), frame)
	_prop(room, "fab_cartoon_food/Plate", Vector3(0.233, 0.9, 0.018), 0.78)
	_prop(room, "quaternius_nature/Plant_1", Vector3(0.68, 0.96, z + 0.12), 0.28)
	_prop(room, "kenney_suburban/planter", Vector3(0.68, 0.93, z + 0.12), 0.60)
	# A ledge and steel storage canisters in the half-light behind the cook.
	box(room, Vector3(1.06, 0.04, 0.25), Vector3(-0.94, 1.47, z + 0.16), wood)
	var canister := material(Color("#b6b6ad"), 0.32, 0.68)
	for i in range(3):
		var height := 0.12 + i * 0.026
		var center := Vector3(-0.64 - i * 0.17, 1.49 + height * 0.5, z + 0.18)
		_cylinder(room, center, 0.065, height, canister)
		_cylinder(room, center + Vector3.UP * height * 0.50, 0.070, 0.014, canister)
	var key := SpotLight3D.new()
	key.position = Vector3(0.68, 1.94, -0.67)
	key.light_color = Color("#ffce92")
	key.light_energy = 6.3
	key.spot_range = 6.0
	key.spot_angle = 24.0
	key.shadow_enabled = true
	key.shadow_blur = 0.8
	key.rotation = Basis.looking_at(Vector3(0, 1.14, 0) - key.position).get_euler()
	room.add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0.7, 1.85, 1.0)
	fill.light_color = Color("#d3e7ef")
	fill.light_energy = 0.55
	fill.omni_range = 4.2
	room.add_child(fill)
	var reflection := ReflectionProbe.new()
	reflection.position = Vector3(0, 1.25, -0.3)
	reflection.size = Vector3(3.8, 2.4, 3.4)
	reflection.intensity = 0.9
	room.add_child(reflection)
	return room


static func _courtyard(room: Node3D, z: float) -> void:
	var exterior := material(Color("#a37a61"), 0.94)
	var sill := material(Color("#d4b68c"), 0.78)
	var glass := material(Color("#52706c"), 0.4)
	# The neighboring building sits across a narrow gap from the window.
	box(room, Vector3(2.05, 2.7, 0.14), Vector3(0.95, 0.76, z - 2.8), exterior)
	for x in [0.28, 1.13, 1.72]:
		box(room, Vector3(0.39, 0.62, 0.03), Vector3(x, 1.38, z - 2.717), glass)
		box(room, Vector3(0.48, 0.08, 0.10), Vector3(x, 1.04, z - 2.70), sill)
	_prop(room, "quaternius_nature/Plant_4", Vector3(0.10, 0.86, z - 1.60), 0.72)
	_prop(room, "quaternius_nature/Plant_2", Vector3(-0.40, 0.70, z - 1.70), 0.60)


static func _prop(parent: Node3D, id: String, position: Vector3, scale_factor: float) -> void:
	var prop := KitDB.static_node(id, scale_factor)
	prop.position = position
	parent.add_child(prop)


static func _cylinder(parent: Node3D, position: Vector3, radius: float, height: float, surface: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = surface
	part.position = position
	parent.add_child(part)


static func material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var surface := StandardMaterial3D.new()
	surface.albedo_color = color
	surface.roughness = roughness
	surface.metallic = metallic
	return surface


static func box(parent: Node3D, size: Vector3, position: Vector3, surface: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = surface
	part.position = position
	parent.add_child(part)
	return part
