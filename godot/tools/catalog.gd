## Builds library/catalog.json and thumbnails for every model in res://assets.
## Run windowed (it renders):  godot --path godot res://tools/catalog.tscn
## Optional: -- --pack <id>   only that pack (catalog entries of other packs are kept)
extends Node

const Paths = preload("res://scripts/core/paths.gd")

const EXTS := ["glb", "gltf", "fbx"]
const THUMB := 256
const SHEET_COLS := 8
const SHEET_ROWS := 6

var viewport: SubViewport
var camera: Camera3D
var label: Label
var holder: Node3D


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var only_pack := ""
	var i := args.find("--pack")
	if i >= 0 and i + 1 < args.size():
		only_pack = args[i + 1]
	_setup_studio()
	var files := []
	_scan("res://assets", files)
	files.sort()
	var catalog_path := Paths.repo_path("library/catalog.json")
	var entries := {}
	if only_pack != "":
		var old := Paths.load_json(catalog_path)
		if old["ok"]:
			for e in old["data"]["models"]:
				if e["pack"] != only_pack:
					entries[e["id"]] = e
	var by_pack := {}
	for f in files:
		var pack := String(f).trim_prefix("res://assets/").split("/")[0]
		if only_pack != "" and pack != only_pack:
			continue
		var e := await _process_model(f, pack)
		if e.is_empty():
			continue
		entries[e["id"]] = e
		if not by_pack.has(pack):
			by_pack[pack] = []
		by_pack[pack].append(e)
	for pack in by_pack:
		_write_sheets(pack, by_pack[pack])
	var ids := entries.keys()
	ids.sort()
	var models := []
	for id in ids:
		models.append(entries[id])
	var f := FileAccess.open(catalog_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "count": models.size(), "models": models}, "  "))
	f.close()
	print("[TownForge] catalog: %d models -> %s" % [models.size(), catalog_path])
	get_tree().quit(0)


func _scan(dir: String, out: Array) -> void:
	for d in DirAccess.get_directories_at(dir):
		_scan(dir.path_join(d), out)
	for f in DirAccess.get_files_at(dir):
		if f.get_extension().to_lower() in EXTS:
			out.append(dir.path_join(f))


func _setup_studio() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(THUMB, THUMB)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	add_child(viewport)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#5a6270")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#c8d0dc")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we := WorldEnvironment.new()
	we.environment = env
	viewport.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 35, 0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	viewport.add_child(sun)
	camera = Camera3D.new()
	camera.fov = 35.0
	viewport.add_child(camera)
	holder = Node3D.new()
	viewport.add_child(holder)
	label = Label.new()
	label.position = Vector2(4, THUMB - 22)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	viewport.add_child(label)


## AABB of all meshes under node, in node's space (computed from local transforms).
func _aabb(node: Node, xf: Transform3D, acc: Array) -> void:
	var t := xf
	if node is Node3D:
		t = xf * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh:
		var box: AABB = t * (node as MeshInstance3D).mesh.get_aabb()
		acc[0] = box if acc[0] == null else (acc[0] as AABB).merge(box)
		var mesh: Mesh = (node as MeshInstance3D).mesh
		for s in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			var idx = arr[Mesh.ARRAY_INDEX]
			acc[1] += (idx.size() if idx != null else arr[Mesh.ARRAY_VERTEX].size()) / 3
	for c in node.get_children():
		_aabb(c, t, acc)


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var a := _find_anim_player(c)
		if a:
			return a
	return null


func _has_skeleton(node: Node) -> bool:
	if node is Skeleton3D:
		return true
	for c in node.get_children():
		if _has_skeleton(c):
			return true
	return false


func _category(pack: String, rel: String, name: String, rigged: bool) -> String:
	var n := name.to_lower()
	match pack:
		"kenney_suburban":
			if n.begins_with("building"): return "house"
			if n.begins_with("fence"): return "fence"
			if n.begins_with("driveway") or n.begins_with("path"): return "path"
			if n.begins_with("tree"): return "tree"
			return "prop"
		"kenney_cars":
			if n.begins_with("debris") : return "debris"
			if n.begins_with("wheel"): return "vehicle_part"
			if n in ["cone", "cone-flat", "box"]: return "prop"
			if n.begins_with("kart"): return "vehicle_toy"
			return "vehicle"
		"quaternius_nature":
			if n.contains("tree") or n.begins_with("willow"): return "tree"
			if n.begins_with("bush"): return "bush"
			if n.begins_with("rock"): return "rock"
			if n.begins_with("cactus"): return "cactus"
			if n.contains("log") or n.contains("stump"): return "deadwood"
			return "plant"
		"quaternius_downtown":
			if n.begins_with("building_"): return "building"
			if n.begins_with("street_") or n.begins_with("sidewalk_") or n.begins_with("decal_"): return "street"
			if n.begins_with("prop_"): return "prop"
			return "building_part"
		"quaternius_fantasy_props":
			return "prop"
		"quaternius_ual":
			return "character"
		"kenney_characters":
			return "animation" if rel.contains("/Animations/") else "character"
	return "character" if rigged else "prop"


func _tags(name: String, category: String) -> Array:
	var out := [category]
	var parts := name.to_lower().replace("-", "_").split("_", false)
	for p in parts:
		if not p.is_valid_int() and not (p in out):
			out.append(p)
	return out


func _process_model(path: String, pack: String) -> Dictionary:
	var res = load(path)
	if not (res is PackedScene):
		push_warning("not a scene: " + path)
		return {}
	var inst: Node = (res as PackedScene).instantiate()
	holder.add_child(inst)
	var acc := [null, 0]
	_aabb(inst, Transform3D.IDENTITY, acc)
	var name := path.get_file().get_basename()
	var rel := path.trim_prefix("res://assets/")
	var ap := _find_anim_player(inst)
	var anims := []
	if ap:
		for a in ap.get_animation_list():
			anims.append(String(a))
	var rigged := _has_skeleton(inst)
	var entry := {
		"id": "%s/%s" % [pack, name],
		"pack": pack,
		"name": name,
		"path": path,
		"category": _category(pack, rel, name, rigged),
		"tags": [],
		"tris": acc[1],
		"rigged": rigged,
		"animations": anims,
	}
	entry["tags"] = _tags(name, entry["category"])
	if acc[0] != null:
		var box: AABB = acc[0]
		entry["size"] = [snappedf(box.size.x, 0.001), snappedf(box.size.y, 0.001), snappedf(box.size.z, 0.001)]
		entry["min"] = [snappedf(box.position.x, 0.001), snappedf(box.position.y, 0.001), snappedf(box.position.z, 0.001)]
		# Frame from front-right-above. The model's front is assumed to face +Z.
		var c := box.get_center()
		var r := maxf(box.size.length() * 0.5, 0.05)
		var dir := Vector3(0.55, 0.42, 1.0).normalized()
		camera.position = c + dir * (r / sin(deg_to_rad(camera.fov * 0.5))) * 1.05
		camera.look_at(c, Vector3.UP)
		camera.near = r * 0.02
		camera.far = r * 20.0
	else:
		entry["size"] = [0, 0, 0]
		entry["min"] = [0, 0, 0]
	label.text = name
	for k in 3:
		await RenderingServer.frame_post_draw
	var img := viewport.get_texture().get_image()
	var thumb_rel := "library/thumbs/%s/%s.png" % [pack, name]
	DirAccess.make_dir_recursive_absolute(Paths.repo_path(thumb_rel).get_base_dir())
	img.save_png(Paths.repo_path(thumb_rel))
	entry["thumb"] = thumb_rel
	entry["_img"] = img
	holder.remove_child(inst)
	inst.queue_free()
	return entry


func _write_sheets(pack: String, list: Array) -> void:
	var per := SHEET_COLS * SHEET_ROWS
	var n_sheets := ceili(list.size() / float(per))
	for s in n_sheets:
		var sheet := Image.create(SHEET_COLS * THUMB, SHEET_ROWS * THUMB, false, Image.FORMAT_RGBA8)
		sheet.fill(Color("#20242a"))
		for k in per:
			var idx := s * per + k
			if idx >= list.size():
				break
			var img: Image = list[idx]["_img"]
			img.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(img, Rect2i(0, 0, THUMB, THUMB), Vector2i((k % SHEET_COLS) * THUMB, (k / SHEET_COLS) * THUMB))
		var path := Paths.repo_path("library/thumbs/_sheets/%s_%d.png" % [pack, s + 1])
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		sheet.save_png(path)
	for e in list:
		e.erase("_img")
