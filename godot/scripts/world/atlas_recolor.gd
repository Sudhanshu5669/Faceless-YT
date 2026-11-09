## Per-instance variants of palette-atlas models (Kenney kits): every face
## samples one swatch of a shared colour atlas, so repainting a swatch
## recolours that part (roof, walls, window glass) without touching the mesh.
## Variants are cached, so identical combinations share one material.
extends RefCounted

static var _materials: Dictionary = {}
static var _images: Dictionary = {}


static func clear_cache() -> void:
	_materials.clear()


static func _source_image(tex: Texture2D) -> Image:
	var path := tex.resource_path
	if not _images.has(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img == null or img.is_empty():
			img = tex.get_image()
			if img.is_compressed():
				img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		_images[path] = img
	return _images[path]


static func _region(img: Image, atlas: Dictionary, cell: Array) -> Rect2i:
	var w := img.get_width() / int(atlas.get("cols", 16))
	var h := img.get_height() / int(atlas.get("rows", 4))
	return Rect2i(int(cell[0]) * w, int(cell[1]) * h, w, h)


## Repaint a swatch with a target colour, keeping its light-to-dark gradient.
static func _paint(img: Image, r: Rect2i, target: Color) -> void:
	var total := 0.0
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			total += img.get_pixel(x, y).v
	var ref := maxf(total / float(r.get_area()), 0.001)
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var v := clampf(target.v * img.get_pixel(x, y).v / ref, 0.0, 1.0)
			img.set_pixel(x, y, Color.from_hsv(target.h, target.s, v))


## opts: {"roof": hex, "walls": hex, "glass": "day"|"dark"|"lit",
##        "window_color": hex, "window_energy": float}
static func variant(src: Material, atlas: Dictionary, opts: Dictionary) -> Material:
	var base := src as BaseMaterial3D
	if base == null or base.albedo_texture == null:
		return src
	var key := "%d|%s" % [src.get_instance_id(), JSON.stringify(opts)]
	if _materials.has(key):
		return _materials[key]
	var img := _source_image(base.albedo_texture).duplicate()
	if opts.has("roof"):
		_paint(img, _region(img, atlas, atlas["roof"]), Color(String(opts["roof"])))
	if opts.has("walls"):
		_paint(img, _region(img, atlas, atlas["walls"]), Color(String(opts["walls"])))
	var glass := String(opts.get("glass", "day"))
	var win_rect := _region(img, atlas, atlas["windows"])
	var mat: BaseMaterial3D = base.duplicate()
	if glass == "dark":
		_paint(img, win_rect, Color("#1c2430"))
	elif glass == "lit":
		var wc := Color(String(opts.get("window_color", "#ffc27a")))
		_paint(img, win_rect, wc)
		var em := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
		em.fill(Color.BLACK)
		em.fill_rect(win_rect, wc)
		em.generate_mipmaps()
		mat.emission_enabled = true
		# Emission operator is ADD (colour + texture): black colour = only the mask glows.
		mat.emission = Color.BLACK
		mat.emission_texture = ImageTexture.create_from_image(em)
		mat.emission_energy_multiplier = float(opts.get("window_energy", 1.4))
	img.generate_mipmaps()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	_materials[key] = mat
	return mat


## Apply a variant to every surface of every mesh under node that uses the atlas.
static func apply(node: Node, atlas: Dictionary, opts: Dictionary) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				var m := mi.mesh.surface_get_material(s)
				var bm := m as BaseMaterial3D
				if bm and bm.albedo_texture and bm.albedo_texture.resource_path.ends_with(String(atlas["texture"])):
					mi.set_surface_override_material(s, variant(m, atlas, opts))
	for c in node.get_children():
		apply(c, atlas, opts)
