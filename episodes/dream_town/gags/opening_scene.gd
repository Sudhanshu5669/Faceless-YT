## First-look fantasy town. Kenney CC0 modular buildings and blocky characters.
## Models stay in their original packs; motion is a deterministic function of time.
extends RefCounted

func _model(parent: Node3D, pack: String, model: String, pos: Vector3, factor: float = 1.0) -> Node3D:
	var resource := load("res://assets/%s/%s.glb" % [pack, model]) as PackedScene
	if resource == null:
		push_error("Missing model %s/%s" % [pack, model])
		return Node3D.new()
	var node := resource.instantiate() as Node3D
	parent.add_child(node)
	node.position = pos
	node.scale = Vector3.ONE * factor
	return node

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	parent.add_child(node)

func _animated(parent: Node3D, character: String, pos: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.name = character
	holder.position = pos
	parent.add_child(holder)
	_model(holder, "kenney_blocky_characters", character, Vector3.ZERO, 1.6)
	return holder

func build(_g: Dictionary) -> Node3D:
	var root := Node3D.new()
	# Stepped rocky hill raises the castle above the street.
	_box(root, Vector3(0, 1.0, -9.0), Vector3(16, 2, 5), Color("273547"))
	_box(root, Vector3(0, 2.2, -10.0), Vector3(12, 1.2, 3), Color("354259"))
	for x in [-4.0, 4.0]:
		_model(root, "kenney_castle", "tower-square", Vector3(x, 2.8, -10), 3.1)
		_model(root, "kenney_castle", "tower-square-roof", Vector3(x, 6.7, -10), 3.1)
	_model(root, "kenney_castle", "wall-narrow-gate", Vector3(0, 2.8, -10), 3.0)
	_model(root, "kenney_castle", "tower-square", Vector3(0, 3.2, -10.5), 4.0)
	_model(root, "kenney_castle", "tower-square-roof", Vector3(0, 8.3, -10.5), 4.0)
	# Modular town fronts step away on both sides, leaving a clear central street.
	for side in [-1.0, 1.0]:
		for z in [-4.5, -0.5, 3.5]:
			var x: float = side * 4.4
			_model(root, "kenney_fantasy_town", "wall-window-shutters", Vector3(x, 0, z), 3.4)
			_model(root, "kenney_fantasy_town", "roof-high", Vector3(x, 3.35, z), 3.4)
			_model(root, "kenney_fantasy_town", "lantern", Vector3(x - side * 1.3, 2.0, z + 0.8), 1.0)
	var prisoner := _animated(root, "character-a", Vector3(0, 0, 2.0))
	prisoner.name = "prisoner"
	var dot := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("ffdf32")
	glow.emission_enabled = true
	glow.emission = Color("ffce20")
	glow.emission_energy_multiplier = 3.0
	dot.mesh = sphere
	dot.material_override = glow
	dot.position = Vector3(0, 4.4, 0.65)
	prisoner.add_child(dot)
	var guard := _animated(root, "character-c", Vector3(-1.1, 0, 1.0))
	guard.name = "guard"
	var light := OmniLight3D.new()
	light.position = Vector3(0, 4, 5)
	light.light_color = Color("ffe2ad")
	light.light_energy = 2.2
	light.omni_range = 16
	root.add_child(light)
	return root

func _seek_walk(node: Node, t: float) -> void:
	if node is AnimationPlayer:
		var player := node as AnimationPlayer
		if player.has_animation("walk"):
			player.play("walk")
			player.seek(fposmod(t, player.get_animation("walk").length), true)
			player.pause()
	for child in node.get_children():
		_seek_walk(child, t)

func pose(node: Node3D, _g: Dictionary, t: float, _ctx: Dictionary) -> Dictionary:
	var prisoner := node.get_node("prisoner") as Node3D
	var guard := node.get_node("guard") as Node3D
	prisoner.position.z = 2.0 - 0.28 * t
	guard.position.z = 1.0 - 0.28 * t
	prisoner.rotation.y = PI
	guard.rotation.y = PI
	_seek_walk(prisoner, t)
	_seek_walk(guard, t + 0.2)
	return {"dot": prisoner.global_position + Vector3(0, 4.4, 0.65)}
