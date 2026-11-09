## Which colormap swatches do Kenney houses use for roofs vs walls?
## godot --path godot --script res://tools/swatch_probe.gd
extends SceneTree


func _init() -> void:
	var up := {}
	var wall := {}
	var small_wall := {}
	for c in "abcdefghijklmnopqrstu":
		var scene: PackedScene = load("res://assets/kenney_suburban/building-type-%s.glb" % c)
		var inst := scene.instantiate()
		_walk(inst, Transform3D.IDENTITY, up, wall, small_wall)
		inst.free()
	_print("UP-FACING (roofs, ledges)", up)
	_print("VERTICAL (walls)", wall)
	_print("VERTICAL, SMALL TRIANGLES (window/door detail)", small_wall)
	quit()


func _walk(n: Node, xf: Transform3D, up: Dictionary, wall: Dictionary, small: Dictionary) -> void:
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D:
		var mesh: Mesh = (n as MeshInstance3D).mesh
		for s in mesh.get_surface_count():
			var a := mesh.surface_get_arrays(s)
			var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var uv: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
			var idx = a[Mesh.ARRAY_INDEX]
			if uv.is_empty():
				continue
			var count: int = idx.size() if idx != null else v.size()
			for i in range(0, count, 3):
				var i0: int = idx[i] if idx != null else i
				var i1: int = idx[i + 1] if idx != null else i + 1
				var i2: int = idx[i + 2] if idx != null else i + 2
				var p0 := t * v[i0]
				var cr := (t * v[i1] - p0).cross(t * v[i2] - p0)
				var area := cr.length() * 0.5
				if area <= 0.0:
					continue
				var nrm := cr.normalized()
				var u := (uv[i0] + uv[i1] + uv[i2]) / 3.0
				var key := "col%02d_row%d" % [clampi(int(u.x * 16.0), 0, 15), clampi(int(u.y * 4.0), 0, 3)]
				var bucket := up if nrm.y > 0.35 else wall
				if absf(nrm.y) <= 0.35 and area < 0.004:
					small[key] = small.get(key, 0.0) + area
				bucket[key] = bucket.get(key, 0.0) + area
	for c in n.get_children():
		_walk(c, t, up, wall, small)


func _print(title: String, d: Dictionary) -> void:
	var keys := d.keys()
	keys.sort_custom(func(a, b): return d[a] > d[b])
	var total := 0.0
	for k in keys:
		total += d[k]
	print(title)
	for k in keys.slice(0, 8):
		print("   %s  %5.1f%%" % [k, 100.0 * d[k] / total])
