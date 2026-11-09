## Turns a town layout (town_generator.gd) into Godot nodes.
## Node names match layout ids (house_3, light_12, ...) so later stages can find them.
extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Atlas = preload("res://scripts/world/atlas_recolor.gd")

const ROAD_TOP := 0.02
const SIDEWALK_TOP := 0.15
const GRASS_TOP := 0.17
const PAVE_TOP := 0.18

const FOLIAGE_TINTS := ["#3d5a35", "#4a6638", "#33502f", "#566b3a"]


static func build(L: Dictionary, look: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Set"
	var practical: Dictionary = look.get("practical_lights", {})
	var kit_id := String(L["params"].get("kit", "primitive"))
	var kit: Dictionary = {} if kit_id == "primitive" else KitDB.kit(kit_id)
	_build_ground(root)
	_build_roads(root, L)
	_build_blocks(root, L)
	_build_paving(root, L)
	_build_fences(root, L)
	_build_houses(root, L, practical, kit, look)
	_build_streetlights(root, L, practical)
	if kit.is_empty():
		_build_cars(root, L, practical)
		_build_vegetation(root, L)
	else:
		_build_kit_cars(root, L, kit)
		_build_kit_vegetation(root, L, kit, _season(L, look))
	return root


## The set's season, pushed to winter when the look has snow on the ground.
static func _season(L: Dictionary, look: Dictionary) -> String:
	var season := String(L["params"].get("season", "summer"))
	if float(look.get("surface", {}).get("snow_cover", 0.0)) >= 0.4:
		return "dead_winter" if season.begins_with("dead") else "winter"
	return season


static func _group(root: Node3D, group_name: String) -> Node3D:
	var g := Node3D.new()
	g.name = group_name
	root.add_child(g)
	return g


static func _inside_town(L: Dictionary, x: float, z: float) -> bool:
	var b: Array = L["bounds"]
	return x >= b[0] and x <= b[2] and z >= b[1] and z <= b[3]


static func _build_ground(root: Node3D) -> void:
	var g := _group(root, "Ground")
	Kit.add_mesh(g, Kit.plane(Vector2(1600, 1600), Kit.surface("ground", "#2b3327", 1.0)), Vector3.ZERO)


# --- roads ------------------------------------------------------------------

static func _build_roads(root: Node3D, L: Dictionary) -> void:
	var grp := _group(root, "Roads")
	var p: Dictionary = L["params"]
	var rw: float = p["road_w"]
	var road_x: Array = L["road_x"]
	var road_z: Array = L["road_z"]
	var b: Array = L["bounds"]
	var asphalt := Kit.surface("asphalt", "#2a2c30", 0.95)
	var paint := Kit.surface("lane_paint", "#c9a640", 0.8)
	for i in road_x.size():
		for j in road_z.size():
			Kit.add_box(grp, Vector3(rw, 0.04, rw), Vector3(road_x[i], ROAD_TOP - 0.02, road_z[j]), asphalt)
	for j in road_z.size():
		for i in road_x.size() - 1:
			var xa: float = road_x[i] + rw / 2.0
			var xb: float = road_x[i + 1] - rw / 2.0
			_segment(grp, Vector3((xa + xb) / 2.0, 0, road_z[j]), xb - xa, rw, 90.0, asphalt, paint)
	for i in road_x.size():
		for j in road_z.size() - 1:
			var za: float = road_z[j] + rw / 2.0
			var zb: float = road_z[j + 1] - rw / 2.0
			_segment(grp, Vector3(road_x[i], 0, (za + zb) / 2.0), zb - za, rw, 0.0, asphalt, paint)
	if p["exit_roads"]:
		for s in L["streets"]:
			if not s["main"]:
				continue
			var mz: float = s["from"][2]
			var x_from: float = s["from"][0]
			var x_to: float = s["to"][0]
			var west_len: float = float(b[0]) - x_from
			var east_len: float = x_to - float(b[2])
			_segment(grp, Vector3(x_from + west_len / 2.0, 0, mz), west_len, rw, 90.0, asphalt, paint)
			_segment(grp, Vector3(float(b[2]) + east_len / 2.0, 0, mz), east_len, rw, 90.0, asphalt, paint)


## A straight road piece; local Z runs along the road.
static func _segment(grp: Node3D, center: Vector3, length: float, width: float, rot_y: float, asphalt: Material, paint: Material) -> void:
	if length <= 0.1:
		return
	var seg := Node3D.new()
	seg.position = center
	seg.rotation_degrees = Vector3(0, rot_y, 0)
	grp.add_child(seg)
	Kit.add_box(seg, Vector3(width, 0.04, length), Vector3(0, ROAD_TOP - 0.02, 0), asphalt)
	var dash := Kit.box(Vector3(0.15, 0.02, 2.4), paint)
	var n := floori(length / 5.0)
	var start := -length / 2.0 + (length - n * 5.0) / 2.0 + 2.5
	for k in n:
		Kit.add_mesh(seg, dash, Vector3(0, ROAD_TOP + 0.005, start + k * 5.0), Vector3.ZERO, "", false)


# --- blocks, paving, fences ---------------------------------------------------

static func _build_blocks(root: Node3D, L: Dictionary) -> void:
	var grp := _group(root, "Blocks")
	var concrete := Kit.surface("sidewalk", "#8f8d88", 0.9)
	var lawn := Kit.surface("lawn", "#3f5233", 1.0)
	for blk in L["blocks"]:
		var r: Array = blk["rect"]
		var g: Array = blk["grass"]
		var node := Node3D.new()
		node.name = blk["id"]
		grp.add_child(node)
		Kit.add_box(node, Vector3(r[2] - r[0], SIDEWALK_TOP, r[3] - r[1]), Vector3((r[0] + r[2]) / 2.0, SIDEWALK_TOP / 2.0, (r[1] + r[3]) / 2.0), concrete, 0.0, "sidewalk")
		Kit.add_box(node, Vector3(g[2] - g[0], GRASS_TOP, g[3] - g[1]), Vector3((g[0] + g[2]) / 2.0, GRASS_TOP / 2.0, (g[1] + g[3]) / 2.0), lawn, 0.0, "lawn")


static func _build_paving(root: Node3D, L: Dictionary) -> void:
	var grp := _group(root, "Paving")
	var drive_m := Kit.surface("driveway", "#76736d", 0.95)
	var walk_m := Kit.surface("walkway", "#a29e95", 0.9)
	for d in L["driveways"]:
		var r: Array = d["rect"]
		Kit.add_box(grp, Vector3(r[2] - r[0], 0.04, r[3] - r[1]), Vector3((r[0] + r[2]) / 2.0, PAVE_TOP - 0.02, (r[1] + r[3]) / 2.0), drive_m, 0.0, "", false)
	for w in L["walkways"]:
		var r: Array = w["rect"]
		Kit.add_box(grp, Vector3(r[2] - r[0], 0.04, r[3] - r[1]), Vector3((r[0] + r[2]) / 2.0, PAVE_TOP - 0.02, (r[1] + r[3]) / 2.0), walk_m, 0.0, "", false)


static func _build_fences(root: Node3D, L: Dictionary) -> void:
	var grp := _group(root, "Fences")
	var wood := Kit.surface("fence", "#6e5d4b", 0.95)
	for f in L["fences"]:
		var a := Vector2(f["from"][0], f["from"][1])
		var b := Vector2(f["to"][0], f["to"][1])
		var length := a.distance_to(b)
		if length < 0.2:
			continue
		var mid := (a + b) / 2.0
		var ang := rad_to_deg(atan2(b.x - a.x, b.y - a.y))
		Kit.add_box(grp, Vector3(0.08, 1.6, length), Vector3(mid.x, GRASS_TOP + 0.8, mid.y), wood, ang)


# --- houses -----------------------------------------------------------------

static func _build_houses(root: Node3D, L: Dictionary, practical: Dictionary, kit: Dictionary, look: Dictionary) -> void:
	var grp := _group(root, "Houses")
	var ctx := {
		"lit_chance": float(practical.get("window_lit_chance", 0.0)),
		"porch_chance": float(practical.get("porch_light_chance", 0.0)),
		"porch_color": String(practical.get("porch_light_color", "#ffc98a")),
		"porch_energy": float(practical.get("porch_light_energy", 1.0)),
		"win_on": Kit.glow_mat(String(practical.get("window_color", "#ffc98a")), float(practical.get("window_energy", 2.0))),
		"win_off": Kit.glass_mat(),
		"trim": Kit.surface("trim", "#e9e5dc", 0.8),
		"foundation": Kit.mat("#6f6a64", 0.95),
		"brick": Kit.mat("#7a4a3a", 0.95),
		"concrete": Kit.surface("sidewalk", "#8f8d88", 0.9),
		"garage_door": Kit.surface("trim", "#d9d4c8", 0.7),
		"lamp_off": Kit.mat("#cfc8b8", 0.6),
	}
	for h in L["houses"]:
		if h.has("model") and not kit.is_empty():
			_build_kit_house(grp, h, ctx, kit, look)
		else:
			_build_house(grp, h, ctx)
	if not kit.is_empty():
		return  # kit bushes are built with the vegetation
	var bush_grp := _group(root, "Bushes")
	var tints := []
	for t in FOLIAGE_TINTS:
		tints.append(Kit.surface("foliage", t, 0.95))
	for bsh in L["bushes"]:
		var pos: Array = bsh["pos"]
		var r: float = bsh["r"]
		var mi := Kit.add_mesh(bush_grp, Kit.sphere(1.0, 1.6, tints[int(bsh["tint"])], 10), Vector3(pos[0], GRASS_TOP + r * 0.55, pos[2]))
		mi.scale = Vector3(r, r, r)


static func _build_house(parent: Node3D, h: Dictionary, ctx: Dictionary) -> void:
	var node := Node3D.new()
	node.name = h["id"]
	var pos: Array = h["pos"]
	node.position = Vector3(pos[0], GRASS_TOP, pos[2])
	node.rotation_degrees = Vector3(0, h["rot_y"], 0)
	parent.add_child(node)

	var w: float = h["w"]
	var d: float = h["d"]
	var wh: float = h["wall_h"]
	var fz := d / 2.0
	var side: int = h["side"]
	var door_x: float = h["door_x"]
	var siding := Kit.surface("siding", h["siding"], 0.85)
	var roof: Dictionary = h["roof"]
	var roof_m := Kit.surface("roof", roof["color"], 0.9)
	var rh: float = roof["h"]
	var trim: Material = ctx["trim"]

	Kit.add_box(node, Vector3(w + 0.2, 0.35, d + 0.2), Vector3(0, 0.175, 0), ctx["foundation"])
	Kit.add_box(node, Vector3(w, wh, d), Vector3(0, wh / 2.0, 0), siding, 0.0, "body")
	if roof["style"] == "side_gable":
		Kit.add_mesh(node, Kit.prism(Vector3(d + 0.8, rh, w + 0.8), roof_m), Vector3(0, wh + rh / 2.0, 0), Vector3(0, 90, 0), "roof")
	else:
		Kit.add_mesh(node, Kit.prism(Vector3(w + 0.8, rh, d + 0.8), roof_m), Vector3(0, wh + rh / 2.0, 0), Vector3.ZERO, "roof")
	if h["chimney"]:
		var ch := rh + 1.4
		Kit.add_box(node, Vector3(0.8, ch, 0.8), Vector3(-side * (w / 2.0 - 1.1), wh + ch / 2.0, -d * 0.15), ctx["brick"])

	# Door, frame, step / porch.
	Kit.add_box(node, Vector3(1.3, 2.3, 0.06), Vector3(door_x, 1.15, fz + 0.01), trim, 0.0, "", false)
	Kit.add_box(node, Vector3(1.0, 2.1, 0.1), Vector3(door_x, 1.05, fz + 0.03), Kit.surface("door", h["door_color"], 0.6), 0.0, "door", false)
	if h["porch"]:
		Kit.add_box(node, Vector3(2.8, 0.3, 1.9), Vector3(door_x, 0.15, fz + 0.95), ctx["concrete"])
		for px in [-1.25, 1.25]:
			Kit.add_box(node, Vector3(0.16, 2.6, 0.16), Vector3(door_x + px, 1.6, fz + 1.75), trim)
		Kit.add_box(node, Vector3(3.2, 0.14, 2.1), Vector3(door_x, 2.85, fz + 1.0), roof_m)
	else:
		Kit.add_box(node, Vector3(1.6, 0.18, 0.8), Vector3(door_x, 0.09, fz + 0.4), ctx["concrete"])

	# Porch light: a lamp by the door, and a real light only when it is on.
	var porch_on := float(h["porch_light_roll"]) < float(ctx["porch_chance"])
	var lamp_m: Material = Kit.glow_mat(ctx["porch_color"], 3.0) if porch_on else ctx["lamp_off"]
	Kit.add_box(node, Vector3(0.18, 0.3, 0.12), Vector3(door_x + 0.85, 2.0, fz + 0.06), lamp_m, 0.0, "porch_lamp", false)
	if porch_on:
		var ol := OmniLight3D.new()
		ol.position = Vector3(door_x + 0.85, 2.0, fz + 0.5)
		ol.light_color = Color(ctx["porch_color"])
		ol.light_energy = ctx["porch_energy"]
		ol.omni_range = 5.0
		node.add_child(ol)

	# Windows.
	for win in h["windows"]:
		var lit := float(win["roll"]) < float(ctx["lit_chance"])
		var m: Material = ctx["win_on"] if lit else ctx["win_off"]
		var y: float = win["y"]
		var wx: float = win["x"]
		match win["face"]:
			"front":
				_window(node, Vector3(wx, y, fz), 0.0, m, trim)
			"left":
				_window(node, Vector3(-w / 2.0, y, wx), -90.0, m, trim)
			"right":
				_window(node, Vector3(w / 2.0, y, wx), 90.0, m, trim)

	if h["garage"]:
		var gx := side * (w / 2.0 + 1.9)
		Kit.add_box(node, Vector3(3.6, 3.0, 6.0), Vector3(gx, 1.5, fz - 3.0), siding, 0.0, "garage")
		Kit.add_box(node, Vector3(2.9, 2.35, 0.08), Vector3(gx, 1.18, fz + 0.03), ctx["garage_door"], 0.0, "", false)
		Kit.add_mesh(node, Kit.prism(Vector3(3.9, 1.0, 6.3), roof_m), Vector3(gx, 3.5, fz - 3.0))


## A window on a wall. rot_y turns the local +Z normal to face outward.
static func _window(node: Node3D, pos: Vector3, rot_y: float, glass: Material, trim: Material) -> void:
	var n := Vector3(0, 0, 1).rotated(Vector3.UP, deg_to_rad(rot_y))
	Kit.add_box(node, Vector3(1.35, 1.45, 0.06), pos + n * 0.02, trim, rot_y, "", false)
	Kit.add_box(node, Vector3(1.1, 1.2, 0.08), pos + n * 0.03, glass, rot_y, "", false)


# --- streetlights, cars -----------------------------------------------------

static func _build_streetlights(root: Node3D, L: Dictionary, practical: Dictionary) -> void:
	var grp := _group(root, "Streetlights")
	var level := float(practical.get("level", 0.0))
	var on := level > 0.05
	var color := String(practical.get("street_light_color", "#ffb066"))
	var energy := float(practical.get("street_light_energy", 6.0)) * level
	var fog_energy := float(practical.get("street_light_fog", 1.0))
	var pole_m := Kit.surface("pole", "#3b3f45", 0.6, 0.3)
	var head_m: Material = Kit.glow_mat(color, 5.0 * level) if on else Kit.mat("#8d939a", 0.5)
	for l in L["streetlights"]:
		var pos: Array = l["pos"]
		var dir: Array = l["dir"]
		var n := Node3D.new()
		n.name = l["id"]
		var y := SIDEWALK_TOP if _inside_town(L, pos[0], pos[2]) else 0.0
		n.position = Vector3(pos[0], y, pos[2])
		n.rotation.y = atan2(dir[0], dir[1])
		grp.add_child(n)
		Kit.add_mesh(n, Kit.cylinder(0.07, 0.11, 6.0, pole_m, 8), Vector3(0, 3.0, 0))
		Kit.add_box(n, Vector3(0.08, 0.08, 1.9), Vector3(0, 5.95, 0.9), pole_m)
		Kit.add_box(n, Vector3(0.42, 0.16, 0.7), Vector3(0, 5.85, 1.75), head_m, 0.0, "", false)
		if on:
			var sl := SpotLight3D.new()
			sl.position = Vector3(0, 5.7, 1.75)
			sl.rotation_degrees = Vector3(-90, 0, 0)
			sl.light_color = Color(color)
			sl.light_energy = energy
			sl.spot_range = 16.0
			sl.spot_angle = 58.0
			sl.shadow_enabled = false
			sl.light_volumetric_fog_energy = fog_energy
			n.add_child(sl)


static func _build_cars(root: Node3D, L: Dictionary, practical: Dictionary) -> void:
	var grp := _group(root, "Cars")
	var glass := Kit.glass_mat()
	var tire := Kit.cylinder(0.34, 0.34, 0.24, Kit.mat("#1a1a1a", 0.9), 12)
	var night := float(practical.get("level", 0.0)) > 0.3
	var tail: Material = Kit.glow_mat("#ff2a1a", 1.2) if night else Kit.mat("#8a1a14", 0.5)
	var idx := 0
	for c in L["cars"]:
		var pos: Array = c["pos"]
		var n := Node3D.new()
		n.name = "car_%d" % idx
		idx += 1
		var y := PAVE_TOP if c["surface"] == "pave" else ROAD_TOP
		n.position = Vector3(pos[0], y, pos[2])
		n.rotation_degrees = Vector3(0, c["rot_y"], 0)
		grp.add_child(n)
		var body := Kit.surface("car", c["color"], 0.35, 0.25)
		Kit.add_box(n, Vector3(1.8, 0.7, 4.3), Vector3(0, 0.62, 0), body)
		Kit.add_box(n, Vector3(1.6, 0.62, 2.3), Vector3(0, 1.27, -0.25), glass)
		for wx in [-0.82, 0.82]:
			for wz in [-1.38, 1.38]:
				Kit.add_mesh(n, tire, Vector3(wx, 0.34, wz), Vector3(0, 0, 90), "", false)
		for tx in [-0.6, 0.6]:
			Kit.add_box(n, Vector3(0.35, 0.12, 0.05), Vector3(tx, 0.75, -2.16), tail, 0.0, "", false)


# --- vegetation (MultiMesh: hundreds of trees, a handful of draw calls) -------

static func _build_vegetation(root: Node3D, L: Dictionary) -> void:
	var grp := _group(root, "Vegetation")
	var bark := Kit.surface("bark", "#4a3a2c", 0.95)
	var leaf := Kit.tint_mat(0.92)
	var parts := {
		"trunk": {"mesh": Kit.cylinder(0.13, 0.2, 2.6, bark, 8), "xf": Transform3D(Basis(), Vector3(0, 1.3, 0)), "tinted": false},
		"round_a": {"mesh": Kit.sphere(1.9, 3.4, leaf), "xf": Transform3D(Basis(), Vector3(0, 3.6, 0)), "tinted": true},
		"round_b": {"mesh": Kit.sphere(1.3, 2.4, leaf), "xf": Transform3D(Basis(), Vector3(0.8, 4.7, 0.3)), "tinted": true},
		"tall": {"mesh": Kit.sphere(1.2, 5.0, leaf), "xf": Transform3D(Basis(), Vector3(0, 4.4, 0)), "tinted": true},
		"pine_a": {"mesh": Kit.cylinder(0.0, 2.0, 2.8, leaf, 9), "xf": Transform3D(Basis(), Vector3(0, 2.4, 0)), "tinted": true},
		"pine_b": {"mesh": Kit.cylinder(0.0, 1.5, 2.4, leaf, 9), "xf": Transform3D(Basis(), Vector3(0, 3.8, 0)), "tinted": true},
		"pine_c": {"mesh": Kit.cylinder(0.0, 1.0, 2.0, leaf, 9), "xf": Transform3D(Basis(), Vector3(0, 5.1, 0)), "tinted": true},
	}
	var variant_parts := {
		"round": ["trunk", "round_a", "round_b"],
		"tall": ["trunk", "tall"],
		"pine": ["trunk", "pine_a", "pine_b", "pine_c"],
	}
	var tints := []
	for t in FOLIAGE_TINTS:
		tints.append(Kit.surface_color("foliage", t))
	var buckets := {}
	for t in L["trees"]:
		var pos: Array = t["pos"]
		var s: float = t["scale"]
		var y := GRASS_TOP if t["ground"] == "grass" else 0.0
		var basis := Basis(Vector3.UP, deg_to_rad(t["rot_y"])).scaled(Vector3.ONE * s)
		var base := Transform3D(basis, Vector3(pos[0], y, pos[2]))
		var tint: Color = tints[int(t["tint"])]
		if t["variant"] == "pine":
			tint = tint.darkened(0.15)
		for part in variant_parts[t["variant"]]:
			if not buckets.has(part):
				buckets[part] = {"xfs": [], "cols": []}
			buckets[part]["xfs"].append(base * parts[part]["xf"])
			buckets[part]["cols"].append(tint)
	for part in buckets:
		var xfs: Array = buckets[part]["xfs"]
		var cols: Array = buckets[part]["cols"]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = parts[part]["tinted"]
		mm.mesh = parts[part]["mesh"]
		mm.instance_count = xfs.size()
		for k in xfs.size():
			mm.set_instance_transform(k, xfs[k])
			if mm.use_colors:
				mm.set_instance_color(k, cols[k])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "trees_" + part
		mmi.multimesh = mm
		grp.add_child(mmi)


# --- kit models ----------------------------------------------------------------

## Deterministic pick from a list, keyed by something stable (an id or a position).
static func _pick_by(list: Array, key) -> String:
	return list[absi(hash(key)) % list.size()]


static func _build_kit_house(parent: Node3D, h: Dictionary, ctx: Dictionary, kit: Dictionary, look: Dictionary) -> void:
	var node := Node3D.new()
	node.name = h["id"]
	var pos: Array = h["pos"]
	node.position = Vector3(pos[0], GRASS_TOP, pos[2])
	node.rotation_degrees = Vector3(0, h["rot_y"], 0)
	parent.add_child(node)
	var model := KitDB.instance(h["model"], float(h["model_scale"]))
	model.name = "model"
	node.add_child(model)

	var kh: Dictionary = kit["house"]
	var atlas: Dictionary = kh.get("atlas", {})
	if not atlas.is_empty():
		var palette: Dictionary = look.get("palette", {})
		var roofs: Array = palette["roof"] if typeof(palette.get("roof")) == TYPE_ARRAY else ([palette["roof"]] if palette.has("roof") else kh["roof_colors"])
		var walls := Kit.surface_color("siding", h["siding"])
		var opts := {"roof": roofs[int(h["roof_pick"]) % roofs.size()], "walls": "#" + walls.to_html(false)}
		var snow := float(look.get("surface", {}).get("snow_cover", 0.0))
		if snow >= 0.4:
			opts["roof"] = "#e9eef5"
		var level := float(look.get("practical_lights", {}).get("level", 0.0))
		if level > 0.3:
			var lit := float(h["window_roll"]) < float(ctx["lit_chance"])
			opts["glass"] = "lit" if lit else "dark"
			if lit:
				opts["window_color"] = String(look["practical_lights"].get("window_color", "#ffc27a"))
				opts["window_energy"] = float(look["practical_lights"].get("window_energy", 1.4))
		Atlas.apply(model, atlas, opts)

	# Porch light: a warm pool by the front door when it is on.
	if float(h["porch_light_roll"]) < float(ctx["porch_chance"]):
		var ol := OmniLight3D.new()
		ol.position = Vector3(0, 2.2, float(h["d"]) / 2.0 + 0.8)
		ol.light_color = Color(ctx["porch_color"])
		ol.light_energy = float(ctx["porch_energy"]) * 1.4
		ol.omni_range = 6.0
		node.add_child(ol)


static func _build_kit_cars(root: Node3D, L: Dictionary, kit: Dictionary) -> void:
	var grp := _group(root, "Cars")
	var kc: Dictionary = kit["car"]
	var idx := 0
	for c in L["cars"]:
		var pos: Array = c["pos"]
		var key := "%s,%s" % [pos[0], pos[2]]
		var rare := (absi(hash(key + "r")) % 1000) / 1000.0 < float(kc.get("rare_chance", 0.0))
		var mid := _pick_by(kc["rare"] if rare else kc["models"], key)
		var n := KitDB.instance(mid, float(kc.get("scale", 1.0)))
		n.name = "car_%d" % idx
		idx += 1
		var y := PAVE_TOP if c["surface"] == "pave" else ROAD_TOP
		n.position = Vector3(pos[0], y, pos[2])
		n.rotation_degrees = Vector3(0, c["rot_y"], 0)
		grp.add_child(n)


## Trees and bushes from the kit, batched into one MultiMesh per mesh part.
static func _build_kit_vegetation(root: Node3D, L: Dictionary, kit: Dictionary, season: String) -> void:
	var grp := _group(root, "Vegetation")
	var kt: Dictionary = kit["tree"]
	var seasons: Dictionary = kt["seasons"]
	var sets: Dictionary = seasons.get(season, seasons["summer"])
	var heights: Dictionary = kt["height"]
	var placements := {}  # model id -> Array[Transform3D]
	for t in L["trees"]:
		var pos: Array = t["pos"]
		var variant := String(t["variant"])
		var mid := _pick_by(sets[variant], "%s,%s" % [pos[0], pos[2]])
		var target := float(heights.get(variant, 8.0)) * float(t["scale"])
		var s := target / maxf(KitDB.size(mid).y, 0.01)
		var y := GRASS_TOP if t["ground"] == "grass" else 0.0
		var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(t["rot_y"])).scaled(Vector3.ONE * s), Vector3(pos[0], y, pos[2]))
		if not placements.has(mid):
			placements[mid] = []
		placements[mid].append(xf)
	var bush_sets: Dictionary = kit["bush"]["seasons"]
	var bushes: Array = bush_sets.get(season, bush_sets["summer"])
	for b in L["bushes"]:
		var pos: Array = b["pos"]
		var mid := _pick_by(bushes, "%s,%s" % [pos[0], pos[2]])
		var s := float(b["r"]) * 1.7 / maxf(KitDB.size(mid).y, 0.01)
		var xf := Transform3D(Basis(Vector3.UP, float(absi(hash(mid + str(pos))) % 360)).scaled(Vector3.ONE * s), Vector3(pos[0], GRASS_TOP, pos[2]))
		if not placements.has(mid):
			placements[mid] = []
		placements[mid].append(xf)
	for mid in placements:
		var xfs: Array = placements[mid]
		var parts := KitDB.parts(mid)
		for pi in parts.size():
			var part: Dictionary = parts[pi]
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = part["mesh"]
			mm.instance_count = xfs.size()
			for k in xfs.size():
				mm.set_instance_transform(k, xfs[k] * part["xf"])
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "%s_%d" % [String(mid).get_file(), pi]
			mmi.multimesh = mm
			grp.add_child(mmi)
