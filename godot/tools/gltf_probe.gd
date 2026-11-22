## Prints the bounding box (metres) of repo-relative glTF/GLB files, as loaded by gag_kit.model().
## godot --headless --path godot --script res://tools/gltf_probe.gd -- <path> [<path> ...]
extends SceneTree

const Kit = preload("res://scripts/world/gag_kit.gd")


func _init() -> void:
	for rel in OS.get_cmdline_user_args():
		var n := Kit.model(String(rel))
		get_root().add_child(n)
		var b := Kit.bounds(n)
		print("%-70s size %s  min %s" % [rel, b.size.snapped(Vector3.ONE * 0.001), b.position.snapped(Vector3.ONE * 0.001)])
		n.free()
	quit()
