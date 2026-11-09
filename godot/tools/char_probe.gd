## Inspect character assets: node tree, skeleton bones, materials, animation tracks.
## godot --headless --path godot --script res://tools/char_probe.gd
extends SceneTree

const FILES := [
	"res://assets/quaternius_ual/UAL1_Standard.glb",
	"res://assets/quaternius_ual/UAL2_Standard.glb",
	"res://assets/quaternius_ual/Mannequin_F.glb",
	"res://assets/kenney_characters/characterMedium.fbx",
	"res://assets/kenney_characters/Animations/run.fbx",
]


func _init() -> void:
	for f in FILES:
		print("\n=== ", f)
		var inst: Node = (load(f) as PackedScene).instantiate()
		_tree(inst, 0)
		inst.free()
	quit()


func _tree(n: Node, depth: int) -> void:
	var line := "  ".repeat(depth) + "%s [%s]" % [n.name, n.get_class()]
	if n is Node3D:
		var t := (n as Node3D).transform
		if not t.is_equal_approx(Transform3D.IDENTITY):
			line += " pos=%s scale=%s" % [t.origin.snapped(Vector3.ONE * 0.001), t.basis.get_scale().snapped(Vector3.ONE * 0.001)]
	print(line)
	if n is Skeleton3D:
		var sk := n as Skeleton3D
		var names := []
		for i in sk.get_bone_count():
			names.append(sk.get_bone_name(i))
		print("  ".repeat(depth + 1) + "%d bones: %s" % [sk.get_bone_count(), ", ".join(PackedStringArray(names))])
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(s)
			var desc := "null"
			if m is BaseMaterial3D:
				desc = "%s albedo=%s tex=%s" % [m.resource_name, (m as BaseMaterial3D).albedo_color.to_html(false), (m as BaseMaterial3D).albedo_texture != null]
			print("  ".repeat(depth + 1) + "surface %d: %s" % [s, desc])
	if n is AnimationPlayer:
		var ap := n as AnimationPlayer
		var list := ap.get_animation_list()
		print("  ".repeat(depth + 1) + "%d animations, root_node=%s" % [list.size(), ap.root_node])
		if list.size() > 0:
			var a := ap.get_animation(list[min(1, list.size() - 1)])
			var paths := []
			for t in mini(a.get_track_count(), 4):
				paths.append(String(a.track_get_path(t)))
			print("  ".repeat(depth + 1) + "sample '%s' len=%.2fs tracks=%d e.g. %s" % [list[min(1, list.size() - 1)], a.length, a.get_track_count(), paths])
			var lens := []
			for name in list:
				lens.append("%s=%.2f" % [name, ap.get_animation(name).length])
			print("  ".repeat(depth + 1) + ", ".join(PackedStringArray(lens)))
	if depth < 6:
		for c in n.get_children():
			_tree(c, depth + 1)
