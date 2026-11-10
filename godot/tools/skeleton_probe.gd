## Prints a model's skeleton for retarget work: node path, bone names with
## parents, rest positions (global, metres) and rest rotations, mesh surfaces.
## godot --headless --path godot --script res://tools/skeleton_probe.gd -- <res://path> [...]
extends SceneTree


func _init() -> void:
	for path in OS.get_cmdline_user_args():
		_probe(String(path))
	quit()


func _probe(path: String) -> void:
	var ps := load(path) as PackedScene
	if ps == null:
		print("cannot load ", path)
		return
	var inst := ps.instantiate()
	print("== ", path)
	_walk(inst, inst, 0)
	inst.free()


func _walk(n: Node, root: Node, depth: int) -> void:
	var line := "  ".repeat(depth) + "%s (%s)" % [n.name, n.get_class()]
	if n is Node3D:
		var t := (n as Node3D).transform
		if not t.is_equal_approx(Transform3D.IDENTITY):
			line += " pos=%s rot=%s scale=%s" % [t.origin, t.basis.get_euler() * 180.0 / PI, t.basis.get_scale()]
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		line += " surfaces=%d skin=%s" % [mi.mesh.get_surface_count() if mi.mesh else 0, mi.skin != null]
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				var m := mi.mesh.surface_get_material(s)
				line += " [%s %s]" % [m.resource_name if m else "-", (m as BaseMaterial3D).albedo_color.to_html(false) if m is BaseMaterial3D else ""]
	if n is AnimationPlayer:
		line += " anims=%s" % [(n as AnimationPlayer).get_animation_list().slice(0, 8)]
	print(line)
	if n is Skeleton3D:
		var sk := n as Skeleton3D
		for b in sk.get_bone_count():
			var g := sk.get_bone_global_rest(b)
			var r := sk.get_bone_rest(b)
			print("  ".repeat(depth + 1) + "#%d %s <- %s  gpos=%s  rest_rot=%s" % [b, sk.get_bone_name(b),
				sk.get_bone_name(sk.get_bone_parent(b)) if sk.get_bone_parent(b) >= 0 else "-",
				g.origin.snapped(Vector3.ONE * 0.001), (r.basis.get_euler() * 180.0 / PI).snapped(Vector3.ONE * 0.1)])
	for c in n.get_children():
		_walk(c, root, depth + 1)
