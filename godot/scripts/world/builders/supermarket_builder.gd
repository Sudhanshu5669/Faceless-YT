## Turns a supermarket layout (supermarket_generator.gd) into Godot nodes.
## Node names match layout ids (aisle_6, toy_hero, fixture_12, lamp_0 ...).
##
## Switchable things (toys, ceiling fixtures, freezers, exit signs) are a
## Node3D with two children, "on" and "off"; exactly one is visible. Their
## switch groups are stored as meta "switch" (e.g. ["toys"]), so timeline
## events can flip a single node ("toy_hero") or a group ("toys").
## Fixtures come from the layout's kit (gondola segments, wall shelves,
## fridges, checkouts, clutter), recoloured to the kit's palette; kit
## "primitive" builds boxes. Shelf stock is MultiMeshes: one per kit product
## mesh, plus a unit box and a unit cylinder scaled per primitive item.
extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Gen = preload("res://scripts/world/generators/supermarket_generator.gd")

const FLOOR_TOP := 0.04
const LAMP_COLOR := "#ffa552"
const FLUO_COLOR := "#e6eeff"
const TOY_EYES := "#53e8ff"
## Product shapes per category: [shape, w, h, d] ranges and colour palette.
const STOCK := {
	"cereal": {"items": [["box", 0.22, 0.32, 0.07], ["box", 0.19, 0.27, 0.07]], "colors": ["#e8c23a", "#d8473c", "#3f6fc6", "#4fb36a", "#ef8a3c", "#f2efe6"]},
	"snacks": {"items": [["box", 0.18, 0.24, 0.09], ["box", 0.14, 0.2, 0.08]], "colors": ["#e23b2e", "#f2c12e", "#2e7fe2", "#7a3fc4", "#2fb35a"]},
	"cans": {"items": [["cyl", 0.08, 0.12, 0.08], ["cyl", 0.1, 0.14, 0.1]], "colors": ["#c8302a", "#e8e2d4", "#2f8a4a", "#d9a43a", "#8a3a2a"]},
	"drinks": {"items": [["cyl", 0.09, 0.3, 0.09], ["cyl", 0.11, 0.34, 0.11], ["cyl", 0.07, 0.2, 0.07]], "colors": ["#e86a2a", "#3aa84a", "#5a2a1a", "#9fd0e8", "#e8d43a", "#c02a3a"]},
	"pasta": {"items": [["box", 0.14, 0.22, 0.06], ["box", 0.2, 0.12, 0.08]], "colors": ["#2a4fa8", "#e8c23a", "#f2efe6", "#c8302a"]},
	"cleaning": {"items": [["box", 0.12, 0.28, 0.08], ["cyl", 0.1, 0.26, 0.1]], "colors": ["#f2f2f2", "#3a7ad8", "#4ac08a", "#e8e05a", "#d84a8a"]},
	"bakery": {"items": [["box", 0.28, 0.12, 0.14], ["box", 0.2, 0.1, 0.12]], "colors": ["#b9853f", "#e2c48a", "#8a5a2a", "#f0e2c0"]},
	"household": {"items": [["box", 0.2, 0.2, 0.15], ["box", 0.25, 0.14, 0.2]], "colors": ["#8a96a6", "#c8bca8", "#5a7a9a", "#d8d2c4", "#a8564a"]},
	"grocery": {"items": [["box", 0.16, 0.22, 0.08], ["cyl", 0.08, 0.12, 0.08], ["box", 0.2, 0.14, 0.1]], "colors": ["#d8473c", "#3f6fc6", "#e8c23a", "#4fb36a", "#f2efe6", "#8a5a2a"]},
}


static func build(L: Dictionary, _look: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Set"
	_build_shell(root, L)
	_build_storefront(root, L)
	_build_gondolas(root, L)
	_build_wall_shelves(root, L)
	_build_stock(root, L)
	_build_toys(root, L)
	_build_checkouts(root, L)
	_build_freezers(root, L)
	_build_fixtures(root, L)
	_build_signs(root, L)
	_build_parking(root, L)
	_build_clutter(root, L)
	return root


## The layout's kit, or {} for "primitive".
static func _kit(L: Dictionary) -> Dictionary:
	var id := String(L["params"]["kit"])
	return {} if id == "primitive" else KitDB.kit(id)


static func _fixture(kit: Dictionary, model_id: String) -> Node3D:
	return KitDB.static_node(model_id, 1.0, kit.get("recolor", {}))


static func _group(root: Node3D, group_name: String) -> Node3D:
	var g := Node3D.new()
	g.name = group_name
	root.add_child(g)
	return g


## A switchable: node with "on"/"off" children, member of switch groups.
static func _switch(parent: Node3D, id: String, groups: Array, on: bool) -> Array:
	var n := Node3D.new()
	n.name = id
	n.set_meta("switch", groups)
	parent.add_child(n)
	var on_n := Node3D.new()
	on_n.name = "on"
	on_n.visible = on
	n.add_child(on_n)
	var off_n := Node3D.new()
	off_n.name = "off"
	off_n.visible = not on
	n.add_child(off_n)
	return [n, on_n, off_n]


static func _floor_mat() -> StandardMaterial3D:
	var key := "supermarket_floor"
	if Kit._mats.has(key):
		return Kit._mats[key]
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	var a := Color("#d7d4ca")
	var b := Color("#c9c6bb")
	var grout := Color("#a9a69d")
	for y in 64:
		for x in 64:
			var c := a if ((x / 32) + (y / 32)) % 2 == 0 else b
			if x % 32 == 0 or y % 32 == 0:
				c = grout
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.83, 0.83, 0.83)  # 0.6 m tiles
	m.roughness = 0.3
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	Kit._mats[key] = m
	return m


static func _glass_mat() -> StandardMaterial3D:
	var key := "supermarket_glass"
	if Kit._mats.has(key):
		return Kit._mats[key]
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.62, 0.74, 0.8, 0.14)
	m.roughness = 0.05
	m.metallic = 0.3
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	Kit._mats[key] = m
	return m


static func _build_shell(root: Node3D, L: Dictionary) -> void:
	var g := _group(root, "Shell")
	var s: Array = L["store"]["rect"]
	var h := float(L["store"]["height"])
	var w := float(s[2]) - float(s[0])
	var d := float(s[3]) - float(s[1])
	var cx := (float(s[0]) + float(s[2])) / 2.0
	var cz := (float(s[1]) + float(s[3])) / 2.0
	Kit.add_mesh(root, Kit.plane(Vector2(1200, 1200), Kit.surface("ground", "#1f2620", 1.0)), Vector3(0, -0.01, 0), Vector3.ZERO, "Ground")
	Kit.add_box(g, Vector3(w, FLOOR_TOP, d), Vector3(cx, FLOOR_TOP / 2.0, cz), _floor_mat(), 0.0, "floor", false)
	var wall_in := Kit.mat("#d9d5c8", 0.85)
	var wall_out := Kit.surface("siding", "#b9ad94", 0.9)
	var t := 0.25
	Kit.add_box(g, Vector3(w + 2 * t, h, t), Vector3(cx, h / 2.0, float(s[1]) - t / 2.0), wall_in, 0.0, "wall_back")
	Kit.add_box(g, Vector3(t, h, d), Vector3(float(s[0]) - t / 2.0, h / 2.0, cz), wall_in, 0.0, "wall_west")
	Kit.add_box(g, Vector3(t, h, d), Vector3(float(s[2]) + t / 2.0, h / 2.0, cz), wall_in, 0.0, "wall_east")
	# Ceiling (inside) and a roof slab with a parapet (outside).
	Kit.add_box(g, Vector3(w, 0.1, d), Vector3(cx, h + 0.05, cz), Kit.mat("#4a4c50", 0.9), 0.0, "ceiling")
	Kit.add_box(g, Vector3(w + 1.0, 1.2, d + 1.0), Vector3(cx, h + 0.7, cz), wall_out, 0.0, "roof")
	# Outside skin of the side and back walls.
	Kit.add_box(g, Vector3(0.05, h, d), Vector3(float(s[0]) - t - 0.03, h / 2.0, cz), wall_out, 0.0, "", false)
	Kit.add_box(g, Vector3(0.05, h, d), Vector3(float(s[2]) + t + 0.03, h / 2.0, cz), wall_out, 0.0, "", false)


static func _build_storefront(root: Node3D, L: Dictionary) -> void:
	var g := _group(root, "Storefront")
	var s: Array = L["store"]["rect"]
	var h := float(L["store"]["height"])
	var glass := _glass_mat()
	var frame := Kit.mat("#2b2e33", 0.4, 0.6)
	var base_m := Kit.surface("siding", "#8f8676", 0.9)
	var top := 3.0
	var door_w := float(L["entrance"]["width"])
	# Header above the glass, inside and out.
	Kit.add_box(g, Vector3(float(s[2]) - float(s[0]) + 0.5, h - top + 1.2, 0.3), Vector3(0, top + (h - top + 1.2) / 2.0, 0.0), Kit.surface("siding", "#b9ad94", 0.9), 0.0, "header")
	var x := float(s[0])
	var i := 0
	while x < float(s[2]) - 0.01:
		var x1 := minf(x + 2.0, float(s[2]))
		var mid := (x + x1) / 2.0
		var in_door := absf(mid) < door_w / 2.0
		if not in_door:
			Kit.add_box(g, Vector3(x1 - x, 0.45, 0.3), Vector3(mid, 0.225, 0.0), base_m, 0.0, "", false)
			Kit.add_box(g, Vector3(x1 - x - 0.06, top - 0.45, 0.02), Vector3(mid, 0.45 + (top - 0.45) / 2.0, 0.0), glass, 0.0, "glass_%d" % i, false)
			i += 1
		Kit.add_box(g, Vector3(0.08, top, 0.12), Vector3(x, top / 2.0, 0.0), frame, 0.0, "", false)
		x = x1
	Kit.add_box(g, Vector3(0.08, top, 0.12), Vector3(float(s[2]), top / 2.0, 0.0), frame, 0.0, "", false)
	# Automatic doors (closed): two glass leaves in a frame.
	var doors := Node3D.new()
	doors.name = "doors"
	g.add_child(doors)
	for side in [-1, 1]:
		var cx: float = side * door_w / 4.0
		Kit.add_box(doors, Vector3(door_w / 2.0 - 0.04, 2.5, 0.03), Vector3(cx, 1.25 + FLOOR_TOP, 0.0), glass, 0.0, "", false)
		Kit.add_box(doors, Vector3(door_w / 2.0, 0.06, 0.06), Vector3(cx, 2.5 + FLOOR_TOP, 0.0), frame, 0.0, "", false)
		Kit.add_box(doors, Vector3(0.05, 2.5, 0.05), Vector3(cx + side * (door_w / 4.0 - 0.03), 1.25 + FLOOR_TOP, 0.0), frame, 0.0, "", false)
	Kit.add_box(doors, Vector3(door_w + 0.2, top - 2.55, 0.12), Vector3(0, 2.55 + (top - 2.55) / 2.0, 0.0), frame, 0.0, "", false)


static func _build_gondolas(root: Node3D, L: Dictionary) -> void:
	var g := _group(root, "Gondolas")
	var kit := _kit(L)
	var shelf_m := Kit.mat("#e4e4e0", 0.5, 0.2)
	var panel_m := Kit.mat("#cfd0cc", 0.6, 0.1)
	var kick_m := Kit.mat("#3a3d42", 0.7)
	var cap_m := Kit.mat("#c23a32", 0.7)
	var levels: Array = L["shelving"]["levels"]
	for gd in L["gondolas"]:
		var r: Array = gd["rect"]
		var h := float(gd["h"])
		var n := Node3D.new()
		n.name = gd["id"]
		g.add_child(n)
		var w := float(r[2]) - float(r[0])
		var l := float(r[3]) - float(r[1])
		var cx := (float(r[0]) + float(r[2])) / 2.0
		var cz := (float(r[1]) + float(r[3])) / 2.0
		if not kit.is_empty():
			# Segments: the model's shelf run is along its X; turn it to run along Z.
			for si in gd["segments"].size():
				var m := _fixture(kit, String(kit["gondola"]["model"]))
				m.name = "segment_%d" % si
				m.position = Vector3(cx, FLOOR_TOP, float(gd["segments"][si]))
				m.rotation.y = PI / 2.0
				n.add_child(m)
			continue
		Kit.add_box(n, Vector3(w, 0.12, l), Vector3(cx, FLOOR_TOP + 0.06, cz), kick_m, 0.0, "", false)
		Kit.add_box(n, Vector3(0.05, h, l), Vector3(cx, FLOOR_TOP + h / 2.0, cz), panel_m)
		for y in levels:
			Kit.add_box(n, Vector3(w, 0.025, l), Vector3(cx, FLOOR_TOP + float(y) - 0.0125, cz), shelf_m, 0.0, "", false)
		# End caps: coloured panels at both ends.
		for ez in [float(r[1]), float(r[3])]:
			Kit.add_box(n, Vector3(w + 0.04, h + 0.1, 0.05), Vector3(cx, FLOOR_TOP + (h + 0.1) / 2.0, ez), cap_m)


static func _build_wall_shelves(root: Node3D, L: Dictionary) -> void:
	var g := _group(root, "WallShelves")
	var kit := _kit(L)
	var ws: Dictionary = L["wall_shelves"]
	var board := Kit.mat("#e4e4e0", 0.5, 0.2)
	var back := Kit.mat("#cfd0cc", 0.6, 0.1)
	var levels: Array = []
	for s in L["shelves"]:
		if int(s["aisle"]) == 0:
			levels = s["levels"]
	for u in ws["units"]:
		var pos := Vector3(float(u["pos"][0]), FLOOR_TOP, float(u["pos"][2]))
		var yaw := atan2(float(u["facing"][0]), float(u["facing"][1]))
		if not kit.is_empty():
			var m := _fixture(kit, String(kit["wall_shelf"]["model"]))
			m.name = u["id"]
			m.position = pos
			m.rotation.y = yaw   # the model's open side (+Z) faces into the store
			g.add_child(m)
			continue
		var n := Node3D.new()
		n.name = u["id"]
		n.position = pos
		n.rotation.y = yaw
		g.add_child(n)
		var seg := float(ws["seg"])
		var d := float(ws["half_d"]) * 2.0
		Kit.add_box(n, Vector3(seg - 0.05, float(ws["h"]), 0.05), Vector3(0, float(ws["h"]) / 2.0, -d / 2.0 + 0.025), back)
		for y in levels:
			Kit.add_box(n, Vector3(seg - 0.05, 0.025, d), Vector3(0, float(y) - 0.0125, 0), board, 0.0, "", false)


## Shelf stock. Per shelf face, per board, runs of the same product along the
## face's shelf spans, up to three rows deep. Kit categories ("stock") use
## product models (a share "mix" of runs stays primitive); others use boxes and
## cylinders in the category's palette.
static func _build_stock(root: Node3D, L: Dictionary) -> void:
	var g := _group(root, "Stock")
	var stock_kit: Dictionary = _kit(L).get("stock", {})
	var stock_scale := float(_kit(L).get("stock_scale", 1.0))
	var boxes := []
	var cyls := []
	var placed := {}   # model id -> [Transform3D]
	for s in L["shelves"]:
		var cat := String(s["category"])
		var span: Array = s.get("toy_span", [])
		if cat == "toys_section":
			cat = "grocery"
		var spec: Dictionary = STOCK.get(cat, STOCK["grocery"])
		var ks: Dictionary = stock_kit.get(cat, {})
		var r := RandomNumberGenerator.new()
		r.seed = int(s["seed"])
		var fx := float(s["facing"][0])
		var levels: Array = s["levels"]
		var avail := float(s["depth"])
		for li in levels.size():
			var y := FLOOR_TOP + float(levels[li])
			var max_h := (float(levels[li + 1]) - float(levels[li]) - 0.07) if li + 1 < levels.size() else 0.34
			var toy_level := float(levels[li]) >= 0.3
			for sp in s["spans"]:
				var z := float(sp[1])
				var limit := float(sp[0])
				var run := 0
				var item: Array = []
				var mid := ""
				var col := Color.WHITE
				while z > limit + 0.08:
					if run <= 0:
						mid = ""
						if not ks.is_empty() and r.randf() >= float(ks.get("mix", 0.0)):
							mid = String(ks["models"][r.randi_range(0, ks["models"].size() - 1)])
							var sz := KitDB.size(mid)
							var sc := minf(stock_scale, max_h / maxf(sz.y, 0.01))
							item = ["model", sz.x * sc, sz.y * sc, sz.z * sc, sc]
						else:
							item = spec["items"][r.randi_range(0, spec["items"].size() - 1)]
							col = Color(String(spec["colors"][r.randi_range(0, spec["colors"].size() - 1)]))
							col = col.lightened(r.randf_range(-0.1, 0.12))
						run = r.randi_range(3, 7)
					var iw := float(item[1])
					var ih := minf(float(item[2]), max_h)
					var idd := float(item[3])
					var zc := z - iw / 2.0
					z -= iw + 0.012
					run -= 1
					if zc - iw / 2.0 < limit:
						break
					if not span.is_empty() and zc < float(span[1]) + 0.1 and zc > float(span[0]) - 0.1 and toy_level:
						continue  # the toy section
					if r.randf() < 0.07:
						continue  # gaps: a picked-over shelf
					for row in 3:
						var depth := idd / 2.0 + 0.03 + row * (idd + 0.025)
						if depth + idd / 2.0 > avail:
							break
						var x := float(s["x"]) - fx * depth
						if item[0] == "model":
							# The product's front (+Z) faces the aisle.
							var b := Basis(Vector3.UP, atan2(fx, 0.0) + r.randf_range(-0.08, 0.08)).scaled(Vector3.ONE * float(item[4]))
							if not placed.has(mid):
								placed[mid] = []
							placed[mid].append(Transform3D(b, Vector3(x, y, zc)))
						else:
							var xf := Transform3D(Basis().scaled(Vector3(idd, ih, iw)), Vector3(x, y + ih / 2.0, zc))
							(cyls if item[0] == "cyl" else boxes).append([xf, col])
	_multimesh(g, "stock_boxes", BoxMesh.new(), boxes)
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.5
	cm.height = 1.0
	cm.radial_segments = 10
	cm.rings = 1
	_multimesh(g, "stock_cans", cm, cyls)
	var ids := placed.keys()
	ids.sort()
	for mid in ids:
		var parts := KitDB.parts(mid)
		for pi in parts.size():
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = parts[pi]["mesh"]
			var xfs: Array = placed[mid]
			mm.instance_count = xfs.size()
			for k in xfs.size():
				mm.set_instance_transform(k, xfs[k] * parts[pi]["xf"])
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "stock_%s_%d" % [String(mid).get_file().replace(".", "_"), pi]
			mmi.multimesh = mm
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			g.add_child(mmi)


static func _multimesh(parent: Node3D, node_name: String, mesh: Mesh, items: Array) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = items.size()
	for i in items.size():
		mm.set_instance_transform(i, items[i][0])
		mm.set_instance_color(i, items[i][1])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = Kit.tint_mat(0.6)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)


## Little toy robots. Eyes are a switch ("on" glows and lights the shelf).
static func _build_toys(root: Node3D, L: Dictionary) -> void:
	if L["toys"].is_empty():
		return
	var g := _group(root, "Toys")
	var eye_on := Kit.glow_mat(TOY_EYES, 3.5)
	var eye_off := Kit.mat("#0e1113", 0.95)
	var metal := Kit.mat("#9aa0a8", 0.4, 0.5)
	for t in L["toys"]:
		var pos := Vector3(t["pos"][0], FLOOR_TOP + float(t["pos"][1]), t["pos"][2])
		var s := float(t["scale"])
		var sw := _switch(g, String(t["id"]), ["toys"], false)
		var n: Node3D = sw[0]
		n.position = pos
		n.rotation.y = atan2(float(t["facing"][0]), float(t["facing"][2]))
		n.scale = Vector3.ONE * s
		var body := Kit.mat(String(t["color"]), 0.5)
		Kit.add_box(n, Vector3(0.14, 0.13, 0.1), Vector3(0, 0.08, 0), body, 0.0, "body")
		Kit.add_box(n, Vector3(0.12, 0.1, 0.1), Vector3(0, 0.2, 0), body, 0.0, "head")
		Kit.add_box(n, Vector3(0.1, 0.05, 0.005), Vector3(0, 0.205, 0.051), Kit.mat("#14181c", 0.2), 0.0, "visor", false)
		Kit.add_mesh(n, Kit.cylinder(0.006, 0.006, 0.06, metal, 6), Vector3(0, 0.28, 0), Vector3.ZERO, "antenna", false)
		Kit.add_mesh(n, Kit.sphere(0.012, 0.024, metal, 8), Vector3(0, 0.31, 0), Vector3.ZERO, "", false)
		for ex in [-0.025, 0.025]:
			Kit.add_mesh(sw[1], Kit.sphere(0.013, 0.026, eye_on, 8), Vector3(ex, 0.21, 0.054), Vector3.ZERO, "", false)
			Kit.add_mesh(sw[2], Kit.sphere(0.013, 0.026, eye_off, 8), Vector3(ex, 0.21, 0.054), Vector3.ZERO, "", false)
		var light := OmniLight3D.new()
		light.light_color = Color(TOY_EYES)
		light.light_energy = 0.7 if t["hero"] else 0.22
		light.omni_range = 2.6 if t["hero"] else 0.7
		light.position = Vector3(0, 0.21, 0.45 if t["hero"] else 0.3)
		light.shadow_enabled = false
		sw[1].add_child(light)


static func _build_checkouts(root: Node3D, L: Dictionary) -> void:
	var g := _group(root, "Checkouts")
	var kit := _kit(L)
	var counter := Kit.mat("#5a6068", 0.6, 0.2)
	var belt := Kit.mat("#1e2022", 0.8)
	var reg := Kit.mat("#2a2c30", 0.5, 0.3)
	for c in L["checkouts"]:
		var r: Array = c["rect"]
		var n := Node3D.new()
		n.name = c["id"]
		g.add_child(n)
		var cx := (float(r[0]) + float(r[2])) / 2.0
		var cz := (float(r[1]) + float(r[3])) / 2.0
		var l := float(r[3]) - float(r[1])
		if not kit.is_empty():
			# Belt counter on the store side of the lane, register stand by the exit.
			var ck: Dictionary = kit["checkout"]
			var cm := _fixture(kit, String(ck["counter"]))
			cm.name = "counter"
			cm.position = Vector3(cx, FLOOR_TOP, float(r[1]) + KitDB.size(ck["counter"]).x / 2.0 + 0.1)
			cm.rotation.y = PI / 2.0
			n.add_child(cm)
			var rm := _fixture(kit, String(ck["register"]))
			rm.name = "register"
			rm.position = Vector3(cx, FLOOR_TOP, float(r[3]) - KitDB.size(ck["register"]).z / 2.0 - 0.05)
			rm.rotation.y = -PI / 2.0
			n.add_child(rm)
		else:
			Kit.add_box(n, Vector3(0.9, 0.86, l), Vector3(cx, FLOOR_TOP + 0.43, cz), counter)
			Kit.add_box(n, Vector3(0.62, 0.02, l * 0.6), Vector3(cx, FLOOR_TOP + 0.87, cz - l * 0.15), belt, 0.0, "", false)
			Kit.add_box(n, Vector3(0.36, 0.22, 0.3), Vector3(cx - 0.2, FLOOR_TOP + 0.97, float(r[3]) - 0.4), reg, 0.0, "register")
			Kit.add_box(n, Vector3(0.04, 0.24, 0.3), Vector3(cx - 0.2, FLOOR_TOP + 1.2, float(r[3]) - 0.4), reg, 0.0, "", false)
		# Lane light post with a number.
		Kit.add_mesh(n, Kit.cylinder(0.03, 0.03, 1.4, reg, 6), Vector3(float(r[2]) - 0.1, FLOOR_TOP + 1.56, float(r[3]) - 0.1), Vector3.ZERO, "", false)
		var lbl := Label3D.new()
		lbl.text = String(c["id"]).trim_prefix("checkout_")
		lbl.font_size = 48
		lbl.pixel_size = 0.004
		lbl.shaded = true
		lbl.position = Vector3(float(r[2]) - 0.1, FLOOR_TOP + 2.35, float(r[3]) - 0.1)
		n.add_child(lbl)


static func _build_freezers(root: Node3D, L: Dictionary) -> void:
	var g := _group(root, "Freezers")
	var kit := _kit(L)
	var body := Kit.mat("#e8e8e4", 0.5, 0.1)
	var door_on := Kit.glow_mat("#bfe2ff", 0.9)
	var door_off := Kit.mat("#22303a", 0.15, 0.3)
	var i := 0
	for f in L["freezers"]:
		var r: Array = f["rect"]
		var cx := (float(r[0]) + float(r[2])) / 2.0
		var w := float(r[2]) - float(r[0])
		var sw := _switch(g, String(f["id"]), ["freezers"], bool(f["on"]))
		var n: Node3D = sw[0]
		n.position = Vector3(cx, FLOOR_TOP, float(r[1]))
		if not kit.is_empty():
			# Two upright fridges per bay; the "on" copy has glowing doors.
			var fk: Dictionary = kit["fridge"]
			var sz := KitDB.size(fk["model"])
			for k in 2:
				for state in 2:
					var m := _fixture(kit, String(fk["model"]))
					m.position = Vector3((k - 0.5) * sz.x, 0, sz.z / 2.0)
					KitDB.override_named(m, fk["door_materials"], door_on if state == 0 else door_off)
					sw[1 + state].add_child(m)
		else:
			Kit.add_box(n, Vector3(w, 2.3, 0.9), Vector3(0, 1.15, 0.45), body)
			Kit.add_box(sw[1], Vector3(w - 0.12, 1.9, 0.02), Vector3(0, 1.12, 0.91), door_on, 0.0, "", false)
			Kit.add_box(sw[2], Vector3(w - 0.12, 1.9, 0.02), Vector3(0, 1.12, 0.91), door_off, 0.0, "", false)
		if i % 2 == 0:
			var light := OmniLight3D.new()
			light.light_color = Color("#bfe2ff")
			light.light_energy = 0.7
			light.omni_range = 5.0
			light.position = Vector3(0, 1.4, float(r[3]) - float(r[1]) + 0.7)
			sw[1].add_child(light)
		i += 1


static func _build_fixtures(root: Node3D, L: Dictionary) -> void:
	var g := _group(root, "Fixtures")
	var lit := Kit.glow_mat(FLUO_COLOR, 3.5)
	var dark := Kit.mat("#8a8e94", 0.4)
	var housing := Kit.mat("#5a5e64", 0.6)
	for f in L["fixtures"]:
		var sw := _switch(g, String(f["id"]), ["fixtures"], bool(f["on"]))
		var n: Node3D = sw[0]
		n.position = Vector3(f["pos"][0], f["pos"][1], f["pos"][2])
		Kit.add_box(n, Vector3(0.32, 0.06, 1.3), Vector3(0, 0.04, 0), housing, 0.0, "", false)
		Kit.add_box(sw[1], Vector3(0.24, 0.02, 1.2), Vector3.ZERO, lit, 0.0, "", false)
		Kit.add_box(sw[2], Vector3(0.24, 0.02, 1.2), Vector3.ZERO, dark, 0.0, "", false)
		var light := OmniLight3D.new()
		light.light_color = Color(FLUO_COLOR)
		light.light_energy = 1.6
		light.omni_range = 8.0
		light.omni_attenuation = 1.2
		light.position = Vector3(0, -0.2, 0)
		light.shadow_enabled = false
		sw[1].add_child(light)


static func _build_signs(root: Node3D, L: Dictionary) -> void:
	var g := _group(root, "Signs")
	var board := Kit.mat("#2a4f8a", 0.6)
	var y := float(L["store"]["height"]) - 1.15
	for a in L["aisles"]:
		var n := Node3D.new()
		n.name = "sign_" + String(a["id"])
		n.position = Vector3(float(a["x"]), y, float(a["z0"]) - 0.3)
		g.add_child(n)
		Kit.add_box(n, Vector3(1.5, 0.75, 0.04), Vector3.ZERO, board, 0.0, "", false)
		Kit.add_box(n, Vector3(0.02, 0.9, 0.02), Vector3(-0.5, 0.8, 0), board, 0.0, "", false)
		Kit.add_box(n, Vector3(0.02, 0.9, 0.02), Vector3(0.5, 0.8, 0), board, 0.0, "", false)
		for side in [1, -1]:
			var num := Label3D.new()
			num.text = str(a["number"])
			num.font_size = 160
			num.pixel_size = 0.002
			num.shaded = true
			num.outline_size = 0
			num.position = Vector3(0, 0.12, 0.025 * side)
			num.rotation.y = 0.0 if side > 0 else PI
			n.add_child(num)
			var title := Label3D.new()
			title.text = String(a["title"])
			title.font_size = 48
			title.pixel_size = 0.002
			title.shaded = true
			title.outline_size = 0
			title.position = Vector3(0, -0.22, 0.025 * side)
			title.rotation.y = 0.0 if side > 0 else PI
			n.add_child(title)
	# Store name on the facade, lit; OPEN 24 HOURS over the doors.
	var name_lbl := Label3D.new()
	name_lbl.name = "store_name"
	name_lbl.text = String(L["params"]["name"])
	name_lbl.font_size = 220
	name_lbl.pixel_size = 0.012
	name_lbl.modulate = Color(2.2, 0.35, 0.3)
	name_lbl.outline_size = 0
	name_lbl.position = Vector3(0, float(L["store"]["height"]) + 0.6, 0.35)
	g.add_child(name_lbl)
	var open_lbl := Label3D.new()
	open_lbl.name = "open_sign"
	open_lbl.text = "OPEN 24 HOURS"
	open_lbl.font_size = 64
	open_lbl.pixel_size = 0.006
	open_lbl.modulate = Color(0.4, 1.8, 0.6)
	open_lbl.outline_size = 0
	open_lbl.position = Vector3(0, 3.35, 0.2)
	g.add_child(open_lbl)
	for e in L["exit_signs"]:
		var sw := _switch(g, String(e["id"]), ["exit_signs"], true)
		var n: Node3D = sw[0]
		n.position = Vector3(e["pos"][0], e["pos"][1], e["pos"][2])
		Kit.add_box(sw[1], Vector3(0.5, 0.2, 0.06), Vector3.ZERO, Kit.glow_mat("#3aff6a", 2.5), 0.0, "", false)
		Kit.add_box(sw[2], Vector3(0.5, 0.2, 0.06), Vector3.ZERO, Kit.mat("#2a3a2e", 0.5), 0.0, "", false)
		var light := OmniLight3D.new()
		light.light_color = Color("#3aff6a")
		light.light_energy = 0.5
		light.omni_range = 3.5
		light.shadow_enabled = false
		sw[1].add_child(light)


static func _build_parking(root: Node3D, L: Dictionary) -> void:
	var g := _group(root, "Parking")
	var r: Array = L["parking"]["rect"]
	var w := float(r[2]) - float(r[0])
	var d := float(r[3]) - float(r[1])
	Kit.add_box(g, Vector3(w, 0.02, d), Vector3(0, 0.01, d / 2.0), Kit.surface("asphalt", "#2c2e31", 0.95), 0.0, "asphalt", false)
	Kit.add_box(g, Vector3(w, 0.025, 3.0), Vector3(0, 0.0125, 1.5), Kit.surface("sidewalk", "#8d8a84", 0.95), 0.0, "sidewalk", false)
	var paint := Kit.surface("lane_paint", "#d8d4c4", 0.8)
	for row in [d * 0.45, d * 0.62]:
		var x := float(r[0]) + 1.55
		while x < float(r[2]) - 1.5:
			Kit.add_box(g, Vector3(0.1, 0.03, 4.6), Vector3(x, 0.015, float(row)), paint, 0.0, "", false)
			x += 2.9
	var pole := Kit.mat("#3b3f45", 0.6, 0.3)
	var head := Kit.glow_mat(LAMP_COLOR, 5.0)
	for i in L["lamps"].size():
		var l: Dictionary = L["lamps"][i]
		var n := Node3D.new()
		n.name = l["id"]
		n.position = Vector3(l["pos"][0], 0, l["pos"][2])
		g.add_child(n)
		Kit.add_mesh(n, Kit.cylinder(0.09, 0.13, 8.0, pole, 8), Vector3(0, 4.0, 0))
		Kit.add_box(n, Vector3(0.9, 0.18, 0.5), Vector3(0, 7.95, 0), head, 0.0, "", false)
		var sl := SpotLight3D.new()
		sl.position = Vector3(0, 7.8, 0)
		sl.rotation_degrees = Vector3(-90, 0, 0)
		sl.light_color = Color(LAMP_COLOR)
		sl.light_energy = 14.0
		sl.spot_range = 22.0
		sl.spot_angle = 62.0
		sl.light_volumetric_fog_energy = 2.5
		# The lamps nearest the store cast the horde's shadows toward the glass.
		sl.shadow_enabled = float(l["pos"][2]) < float(r[3]) * 0.5
		n.add_child(sl)
	var kit := KitDB.kit("suburban")
	var models: Array = kit.get("car", {}).get("models", [])
	var g_cars := _group(root, "Cars")
	for c in L["cars"]:
		var pos := Vector3(c["pos"][0], 0.02, c["pos"][2])
		var mid := String(models[int(c["model_pick"]) % models.size()]) if not models.is_empty() else ""
		if mid != "" and not KitDB.model(mid).is_empty():
			var inst := KitDB.instance(mid, float(kit["car"].get("scale", 1.45)))
			inst.name = c["id"]
			inst.position = pos
			inst.rotation.y = float(c["yaw"])
			g_cars.add_child(inst)
		else:
			Kit.add_box(g_cars, Vector3(1.8, 1.3, 4.3), pos + Vector3(0, 0.65, 0), Kit.mat(String(c["color"]), 0.4, 0.3), float(c["yaw"]), c["id"])


## Abandoned carts, baskets, boxes and trash bags (layout "clutter").
const CLUTTER_BOX := {"cart": Vector3(0.6, 1.0, 0.95), "basket": Vector3(0.45, 0.45, 0.5), "box": Vector3(0.5, 0.3, 0.45), "trash": Vector3(1.4, 1.1, 0.8)}


static func _build_clutter(root: Node3D, L: Dictionary) -> void:
	var g := _group(root, "Clutter")
	var kit := _kit(L)
	for c in L["clutter"]:
		var kind := String(c["kind"])
		var pos := Vector3(float(c["pos"][0]), 0.0, float(c["pos"][2]))
		pos.y = Gen.ground_height(L, pos.x, pos.z)
		var n: Node3D
		if not kit.is_empty():
			var ck: Dictionary = kit["clutter"][kind]
			n = KitDB.static_node(String(ck["model"]), float(ck.get("scale", 1.0)))
		else:
			n = Node3D.new()
			var sz: Vector3 = CLUTTER_BOX[kind]
			Kit.add_box(n, sz, Vector3(0, sz.y / 2.0, 0), Kit.mat("#8a8478", 0.8), 0.0, "", false)
		n.name = c["id"]
		n.position = pos
		n.rotation.y = float(c["yaw"])
		g.add_child(n)
