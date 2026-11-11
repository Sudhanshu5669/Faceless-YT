## Turns a downtown layout (downtown_generator.gd) into Godot nodes. Node
## names match layout ids (bldg_12, light_40, car_3 ...).
##
## With the "downtown" kit, buildings are assembled from facade modules
## (2 m wide, 3 m tall, outer face at the module's z = 0) placed around each
## footprint floor by floor: shopfronts and a door on the ground floor, one
## window pattern per building above, a cornice and roof tiles on top. Every
## module type is one MultiMesh per mesh part, so a whole city is a few
## hundred draw calls. Kit "primitive" draws boxes with window bands.
extends RefCounted

const Kit = preload("res://scripts/world/prop_kit.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Gen = preload("res://scripts/world/generators/downtown_generator.gd")

const SIDEWALK_TOP := 0.15


static func build(L: Dictionary, look: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Set"
	var kit_id := String(L["params"]["kit"])
	var kit: Dictionary = {} if kit_id == "primitive" else KitDB.kit(kit_id)
	var practical: Dictionary = look.get("practical_lights", {})
	_build_ground(root, L)
	if kit.is_empty():
		_build_primitive_streets(root, L)
		_build_primitive_buildings(root, L)
	else:
		_build_streets(root, L, kit)
		_build_buildings(root, L, kit)
	_build_streetlights(root, L, practical)
	_build_trees(root, L, kit)
	_build_cars(root, L, kit)
	_build_props(root, L, kit)
	return root


static func _group(root: Node3D, group_name: String) -> Node3D:
	var g := Node3D.new()
	g.name = group_name
	root.add_child(g)
	return g


static func _build_ground(root: Node3D, L: Dictionary) -> void:
	Kit.add_mesh(root, Kit.plane(Vector2(1600, 1600), Kit.surface("ground", "#3a3c3a", 1.0)), Vector3(0, -0.02, 0), Vector3.ZERO, "Ground")
	var g := _group(root, "Blocks")
	var m := Kit.surface("sidewalk", "#9a968e", 0.95)
	for b in L["blocks"]:
		var r: Array = b["rect"]
		var w := float(r[2]) - float(r[0])
		var d := float(r[3]) - float(r[1])
		Kit.add_box(g, Vector3(w, SIDEWALK_TOP, d), Vector3((float(r[0]) + float(r[2])) / 2.0, SIDEWALK_TOP / 2.0, (float(r[1]) + float(r[3])) / 2.0), m, 0.0, b["id"], false)


# --- MultiMesh batching ---------------------------------------------------------

## Collects transforms per model; flush() turns them into MultiMeshes.
class Batch:
	var by_model := {}   # model id -> [Transform3D]
	var raw := {}        # model id -> bool (keep the model's own pivot)
	var vertex_colors := true

	func add(model_id: String, xf: Transform3D, keep_pivot: bool) -> void:
		if not by_model.has(model_id):
			by_model[model_id] = []
			raw[model_id] = keep_pivot
		by_model[model_id].append(xf)

	func flush(parent: Node3D, shadows: bool) -> void:
		var ids := by_model.keys()
		ids.sort()
		for mid in ids:
			var parts := KitDB.parts(String(mid), not bool(raw[mid]))
			var xfs: Array = by_model[mid]
			for pi in parts.size():
				var mm := MultiMesh.new()
				mm.transform_format = MultiMesh.TRANSFORM_3D
				mm.mesh = parts[pi]["mesh"] if vertex_colors else KitDB.without_vertex_colors(parts[pi]["mesh"])
				mm.instance_count = xfs.size()
				for k in xfs.size():
					mm.set_instance_transform(k, (xfs[k] as Transform3D) * (parts[pi]["xf"] as Transform3D))
				var mmi := MultiMeshInstance3D.new()
				mmi.name = "%s_%d" % [String(mid).get_file(), pi]
				mmi.multimesh = mm
				mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				parent.add_child(mmi)


# --- streets ----------------------------------------------------------------------

static func _build_streets(root: Node3D, L: Dictionary, kit: Dictionary) -> void:
	var g := _group(root, "Streets")
	var st: Dictionary = kit["street"]
	var batch := Batch.new()
	batch.vertex_colors = bool(kit.get("vertex_colors", true))
	for s in L["streets"]:
		var along_x: bool = s["axis"] == "x"
		var yaw := 0.0 if along_x else PI / 2.0
		for t in s["tiles"]:
			var pos := Vector3(float(t), 0, float(s["at"])) if along_x else Vector3(float(s["at"]), 0, float(t))
			batch.add(String(st["straight"]), Transform3D(Basis(Vector3.UP, yaw), pos), false)
	for c in L["intersections"]:
		batch.add(String(st["intersection"]), Transform3D(Basis(), Vector3(c["pos"][0], 0, c["pos"][2])), false)
	batch.flush(g, false)


static func _build_primitive_streets(root: Node3D, L: Dictionary) -> void:
	var g := _group(root, "Streets")
	var asphalt := Kit.surface("asphalt", "#2c2e31", 0.95)
	var walk := Kit.surface("sidewalk", "#8d8a84", 0.95)
	for s in L["streets"]:
		var along_x: bool = s["axis"] == "x"
		var span: Array = s["span"]
		var len := float(span[1]) - float(span[0])
		var mid := (float(span[0]) + float(span[1])) / 2.0
		var at := float(s["at"])
		var c := Vector3(mid, 0, at) if along_x else Vector3(at, 0, mid)
		var road := Vector3(len, 0.02, Gen.ROAD_HALF * 2.0) if along_x else Vector3(Gen.ROAD_HALF * 2.0, 0.02, len)
		Kit.add_box(g, road, c + Vector3(0, 0.01, 0), asphalt, 0.0, s["id"], false)
		for side in [-1, 1]:
			var off := Gen.ROAD_HALF + Gen.WALK / 2.0
			var wc := c + (Vector3(0, 0, side * off) if along_x else Vector3(side * off, 0, 0))
			var ws := Vector3(len, SIDEWALK_TOP, Gen.WALK) if along_x else Vector3(Gen.WALK, SIDEWALK_TOP, len)
			Kit.add_box(g, ws, wc + Vector3(0, SIDEWALK_TOP / 2.0, 0), walk, 0.0, "", false)


# --- buildings ----------------------------------------------------------------------

static func _build_buildings(root: Node3D, L: Dictionary, kit: Dictionary) -> void:
	var g := _group(root, "Buildings")
	var batch := Batch.new()
	batch.vertex_colors = bool(kit.get("vertex_colors", true))
	var styles: Dictionary = kit["styles"]
	for b in L["buildings"]:
		if String(b["landmark"]) != "":
			_place_landmark(g, b, kit)
			continue
		var marker := Node3D.new()   # an empty node per building, so ids resolve
		marker.name = b["id"]
		var r: Array = b["rect"]
		marker.position = Vector3((float(r[0]) + float(r[2])) / 2.0, SIDEWALK_TOP, (float(r[1]) + float(r[3])) / 2.0)
		g.add_child(marker)
		_facades(batch, b, styles[String(b["style"])], kit)
	batch.flush(g, true)


static func _place_landmark(parent: Node3D, b: Dictionary, kit: Dictionary) -> void:
	var mid := String(b["landmark"])
	var sz := KitDB.size(mid)
	var r: Array = b["rect"]
	var f := Vector3(b["face"][0], 0, b["face"][1])
	var front := float(r[3]) if f.z > 0 else float(r[1])
	var n := KitDB.static_node(mid, 1.0, {}, bool(kit.get("vertex_colors", true)))
	n.name = b["id"]
	n.position = Vector3((float(r[0]) + float(r[2])) / 2.0, SIDEWALK_TOP, front - f.z * sz.z / 2.0)
	n.rotation.y = atan2(f.x, f.z)
	parent.add_child(n)


## The four sides of a footprint: outward normal, first slot's start corner,
## direction along the side (matching the module's local +X), slot count, slot width.
static func _sides(b: Dictionary) -> Array:
	var r: Array = b["rect"]
	var x0 := float(r[0])
	var z0 := float(r[1])
	var x1 := float(r[2])
	var z1 := float(r[3])
	var nx: int = b["modules"][0]
	var nz: int = b["modules"][1]
	var wx := (x1 - x0) / nx
	var wz := (z1 - z0) / nz
	return [
		{"n": Vector3(0, 0, 1), "start": Vector3(x0, 0, z1), "dir": Vector3(1, 0, 0), "count": nx, "w": wx},
		{"n": Vector3(0, 0, -1), "start": Vector3(x1, 0, z0), "dir": Vector3(-1, 0, 0), "count": nx, "w": wx},
		{"n": Vector3(1, 0, 0), "start": Vector3(x1, 0, z1), "dir": Vector3(0, 0, -1), "count": nz, "w": wz},
		{"n": Vector3(-1, 0, 0), "start": Vector3(x0, 0, z0), "dir": Vector3(0, 0, 1), "count": nz, "w": wz},
	]


static func _facades(batch: Batch, b: Dictionary, style: Dictionary, kit: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(b["seed"])
	var floors: int = b["floors"]
	var face := Vector3(b["face"][0], 0, b["face"][1])
	var walls: Array = style["wall"]
	var windows: Array = style["window"]
	var shops: Array = style["shop"]
	var doors: Array = style["door"]
	# One look per building: its window module and pattern.
	var win := String(windows[rng.randi_range(0, windows.size() - 1)])
	var wall := String(walls[rng.randi_range(0, walls.size() - 1)])
	var shop := String(shops[rng.randi_range(0, shops.size() - 1)])
	var door := String(doors[rng.randi_range(0, doors.size() - 1)])
	var pattern := rng.randi_range(0, 2)   # 0 every slot a window, 1 alternate, 2 pairs with a pier
	for side in _sides(b):
		var n: Vector3 = side["n"]
		var yaw := atan2(n.x, n.z)
		var count: int = side["count"]
		var w := float(side["w"])
		var is_front := n.is_equal_approx(face)
		var door_slot := rng.randi_range(0, count - 1) if is_front else -1
		for f in floors:
			var y := SIDEWALK_TOP + f * Gen.FLOOR_H
			for k in count:
				var mid: String
				if f == 0:
					if is_front:
						mid = door if k == door_slot else shop
					else:
						mid = String(style["base"]) if k % 3 != 1 else shop
				else:
					match pattern:
						0: mid = win
						1: mid = win if k % 2 == 0 else wall
						_: mid = wall if k % 3 == 2 else win
					if f == floors - 1 and k % 2 == 1 and pattern == 0:
						mid = String(style["top"])
				_module(batch, mid, side, k, w, y, yaw)
		# Cornice along the roof line.
		for k in count:
			_module(batch, String(style["cornice"]), side, k, w, SIDEWALK_TOP + floors * Gen.FLOOR_H, yaw)
	# Roof tiles over the footprint.
	var r: Array = b["rect"]
	var nx: int = b["modules"][0]
	var nz: int = b["modules"][1]
	var wx := (float(r[2]) - float(r[0])) / nx
	var wz := (float(r[3]) - float(r[1])) / nz
	var top := SIDEWALK_TOP + floors * Gen.FLOOR_H + 0.2
	for i in nx:
		for j in nz:
			var c := Vector3(float(r[0]) + (i + 0.5) * wx, top, float(r[1]) + (j + 0.5) * wz)
			batch.add(String(kit["roof"]), Transform3D(Basis().scaled(Vector3(wx / Gen.MODULE, 1, wz / Gen.MODULE)), c), true)
	# A few AC units on the roof.
	var props: Array = kit.get("roof_props", [])
	if not props.is_empty():
		for i in rng.randi_range(0, 3):
			var c := Vector3(rng.randf_range(float(r[0]) + 1.5, float(r[2]) - 1.5), top - 0.2, rng.randf_range(float(r[1]) + 1.5, float(r[3]) - 1.5))
			batch.add(String(props[0]), Transform3D(Basis(Vector3.UP, rng.randi_range(0, 3) * PI / 2.0), c), false)


## One facade module in slot k of a side, floor at height y.
static func _module(batch: Batch, mid: String, side: Dictionary, k: int, w: float, y: float, yaw: float) -> void:
	var start: Vector3 = side["start"]
	var dir: Vector3 = side["dir"]
	var pos := start + dir * (w * (k + 0.5)) + Vector3(0, y, 0)
	var basis := Basis(Vector3.UP, yaw) * Basis().scaled(Vector3(w / Gen.MODULE, 1, 1))
	batch.add(mid, Transform3D(basis, pos), true)


static func _build_primitive_buildings(root: Node3D, L: Dictionary) -> void:
	var g := _group(root, "Buildings")
	var cols := {"brick": "#8a4a3a", "metal": "#3a3e44", "stone": "#c9bfa6"}
	var band := Kit.mat("#20262e", 0.2, 0.4)
	for b in L["buildings"]:
		var r: Array = b["rect"]
		var w := float(r[2]) - float(r[0])
		var d := float(r[3]) - float(r[1])
		var h := int(b["floors"]) * Gen.FLOOR_H
		var n := Node3D.new()
		n.name = b["id"]
		n.position = Vector3((float(r[0]) + float(r[2])) / 2.0, SIDEWALK_TOP, (float(r[1]) + float(r[3])) / 2.0)
		g.add_child(n)
		Kit.add_box(n, Vector3(w, h, d), Vector3(0, h / 2.0, 0), Kit.mat(String(cols[String(b["style"])]), 0.9))
		for f in range(1, int(b["floors"])):
			Kit.add_box(n, Vector3(w + 0.04, 1.2, d + 0.04), Vector3(0, f * Gen.FLOOR_H + 1.5, 0), band, 0.0, "", false)


# --- street furniture ------------------------------------------------------------

static func _build_streetlights(root: Node3D, L: Dictionary, practical: Dictionary) -> void:
	var grp := _group(root, "Streetlights")
	var level := float(practical.get("level", 0.0))
	var on := level > 0.05
	var color := String(practical.get("street_light_color", "#ffd9a0"))
	var energy := float(practical.get("street_light_energy", 6.0)) * level
	var fog_energy := float(practical.get("street_light_fog", 1.0))
	var pole_m := Kit.surface("pole", "#2f3338", 0.6, 0.4)
	var head_m: Material = Kit.glow_mat(color, 5.0 * level) if on else Kit.mat("#8d939a", 0.5)
	for l in L["streetlights"]:
		var pos: Array = l["pos"]
		var dir: Array = l["dir"]
		var n := Node3D.new()
		n.name = l["id"]
		n.position = Vector3(pos[0], SIDEWALK_TOP, pos[2])
		n.rotation.y = atan2(dir[0], dir[1])
		grp.add_child(n)
		Kit.add_mesh(n, Kit.cylinder(0.08, 0.12, 7.0, pole_m, 8), Vector3(0, 3.5, 0))
		Kit.add_box(n, Vector3(0.08, 0.08, 2.0), Vector3(0, 6.95, 0.95), pole_m)
		Kit.add_box(n, Vector3(0.38, 0.14, 0.8), Vector3(0, 6.85, 1.85), head_m, 0.0, "", false)
		if on:
			var sl := SpotLight3D.new()
			sl.position = Vector3(0, 6.7, 1.85)
			sl.rotation_degrees = Vector3(-90, 0, 0)
			sl.light_color = Color(color)
			sl.light_energy = energy
			sl.spot_range = 18.0
			sl.spot_angle = 60.0
			sl.shadow_enabled = false
			sl.light_volumetric_fog_energy = fog_energy
			n.add_child(sl)


static func _build_trees(root: Node3D, L: Dictionary, kit: Dictionary) -> void:
	var g := _group(root, "Trees")
	var tk: Dictionary = kit.get("trees", {})
	var models: Array = tk.get("models", [])
	var trunk := Kit.surface("trunk", "#5a4632", 0.9)
	var leaves := Kit.surface("foliage", "#4f7a3a", 0.9)
	for t in L["street_trees"]:
		var pos := Vector3(t["pos"][0], SIDEWALK_TOP, t["pos"][2])
		var s := float(t["scale"])
		if not models.is_empty():
			var mid := String(models[int(t["pick"]) % models.size()])
			var n := KitDB.static_node(mid, float(tk.get("height", 6.0)) * s / maxf(KitDB.size(mid).y, 0.01))
			n.name = t["id"]
			n.position = pos
			n.rotation.y = float(int(t["pick"]) % 360) * PI / 180.0
			g.add_child(n)
		else:
			var n := Node3D.new()
			n.name = t["id"]
			n.position = pos
			g.add_child(n)
			Kit.add_mesh(n, Kit.cylinder(0.12, 0.16, 2.6 * s, trunk, 6), Vector3(0, 1.3 * s, 0))
			Kit.add_mesh(n, Kit.sphere(1.6 * s, 3.0 * s, leaves, 8), Vector3(0, 3.6 * s, 0))


static func _build_cars(root: Node3D, L: Dictionary, kit: Dictionary) -> void:
	var g := _group(root, "Cars")
	var ck: Dictionary = kit.get("cars", {})
	var models: Array = KitDB.kit(String(ck["kit"])).get("car", {}).get("models", []) if ck.has("kit") else []
	for c in L["cars"]:
		var pos := Vector3(c["pos"][0], 0.0, c["pos"][2])
		if not models.is_empty():
			var mid := String(models[int(c["pick"]) % models.size()])
			var inst := KitDB.instance(mid, float(ck.get("scale", 1.45)))
			inst.name = c["id"]
			inst.position = pos
			inst.rotation.y = float(c["yaw"])
			g.add_child(inst)
		else:
			Kit.add_box(g, Vector3(1.8, 1.3, 4.3), pos + Vector3(0, 0.65, 0), Kit.mat(String(c["color"]), 0.4, 0.3), float(c["yaw"]), c["id"])


static func _build_props(root: Node3D, L: Dictionary, kit: Dictionary) -> void:
	var g := _group(root, "Props")
	var pk: Dictionary = kit.get("props", {})
	var batch := Batch.new()
	batch.vertex_colors = bool(kit.get("vertex_colors", true))
	var bollard := Kit.mat("#2a2d31", 0.6, 0.4)
	for p in L["props"]:
		var kind := String(p["kind"])
		var y := 0.0 if kind == "manhole" else SIDEWALK_TOP
		var pos := Vector3(p["pos"][0], y, p["pos"][2])
		if pk.has(kind):
			batch.add(String(pk[kind]), Transform3D(Basis(Vector3.UP, float(p["yaw"])), pos), false)
		elif kind == "bollard":
			Kit.add_mesh(g, Kit.cylinder(0.1, 0.11, 0.9, bollard, 8), pos + Vector3(0, 0.45, 0), Vector3.ZERO, p["id"], false)
	batch.flush(g, false)
