## Measures catalog models for kit curation: materials per surface and the
## heights of upward-facing surfaces (shelf boards, counter tops), in the
## model's normalised frame (footprint centred, base at y = 0, unscaled).
## godot --headless --path godot --script res://tools/fixture_probe.gd -- <model id> [<model id> ...]
extends SceneTree

const KitDB = preload("res://scripts/world/kit_db.gd")


func _init() -> void:
	var ids := OS.get_cmdline_user_args()
	for id in ids:
		_probe(String(id))
	quit()


func _probe(id: String) -> void:
	var m := KitDB.model(id)
	if m.is_empty():
		print("unknown model ", id)
		return
	print("== %s  size %s" % [id, KitDB.size(id)])
	var mats := {}
	var levels := {}   # y (cm) -> [area, xmin, xmax, zmin, zmax]
	for p in KitDB.parts(id):
		var mesh: Mesh = p["mesh"]
		var xf: Transform3D = p["xf"]
		for s in mesh.get_surface_count():
			var mat := mesh.surface_get_material(s)
			var key := "?"
			if mat is BaseMaterial3D:
				var bm := mat as BaseMaterial3D
				key = "%s albedo=%s tex=%s" % [mat.resource_name, bm.albedo_color.to_html(false), bm.albedo_texture.resource_path if bm.albedo_texture else "-"]
			mats[key] = mats.get(key, 0) + 1
			var a := mesh.surface_get_arrays(s)
			var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var tri := idx.size() / 3 if idx.size() > 0 else v.size() / 3
			for t in tri:
				var i0 := idx[t * 3] if idx.size() > 0 else t * 3
				var i1 := idx[t * 3 + 1] if idx.size() > 0 else t * 3 + 1
				var i2 := idx[t * 3 + 2] if idx.size() > 0 else t * 3 + 2
				var p0 := xf * v[i0]
				var p1 := xf * v[i1]
				var p2 := xf * v[i2]
				var n := (p1 - p0).cross(p2 - p0)
				var area := n.length() / 2.0
				if area < 1e-5 or n.normalized().y < 0.95:
					continue
				var y := int(round((p0.y + p1.y + p2.y) / 3.0 * 100.0))
				var e: Array = levels.get(y, [0.0, 1e9, -1e9, 1e9, -1e9])
				e[0] += area
				for q in [p0, p1, p2]:
					e[1] = minf(e[1], q.x)
					e[2] = maxf(e[2], q.x)
					e[3] = minf(e[3], q.z)
					e[4] = maxf(e[4], q.z)
				levels[y] = e
	for k in mats:
		print("  mat x%d  %s" % [mats[k], k])
	var ys := levels.keys()
	ys.sort()
	for y in ys:
		var e: Array = levels[y]
		if e[0] < 0.02:
			continue
		print("  up y=%.2f  area=%.2f  x[%.2f,%.2f] z[%.2f,%.2f]" % [y / 100.0, e[0], e[1], e[2], e[3], e[4]])
