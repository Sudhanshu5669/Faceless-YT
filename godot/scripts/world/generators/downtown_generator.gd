## TownForge downtown generator: a deterministic city *layout* (pure data).
##
## A grid of blocks (plus an "outskirts" ring) separated by 4-lane avenues (along X, "ave_N") and streets
## (along Z, "st_N") that meet at 4-way intersections ("cross_I_J"). Streets
## run past the city edge so the grid feels like part of a bigger city. Each
## block is lined with buildings flush to the sidewalk: rectangular lots in two
## rows, each building a number of 3 m floors in one facade style, or (rarely)
## a premade landmark. Streetlights, trees, parked cars and props line the
## sidewalks; a pedestrian network (sidewalk corners, sidewalks, crosswalks)
## gives crowds somewhere to walk.
##
## Conventions: metres, Y up, rects [x0, z0, x1, z1]. Road surface y = 0,
## sidewalks and blocks y = 0.15. Street geometry follows the kit's tiles
## (library/kits/downtown.json "street"): a 6 m tile, 12 m road, 3 m sidewalks,
## 24.67 m intersections; "primitive" uses the same numbers.
extends RefCounted

const KitDB = preload("res://scripts/world/kit_db.gd")

const DEFAULTS := {
	"blocks_x": 4,
	"blocks_z": 3,
	"block_tiles_x": 4,
	"block_tiles_z": 4,
	"floors": [3, 9],
	"skyline": 0.6,
	"styles": ["brick", "metal", "stone"],
	"landmarks": 0.15,
	"trees": 0.5,
	"parked_cars": 0.35,
	"outskirts": true,
	"kit": "downtown",
}
const LIMITS := {
	"blocks_x": [1, 8], "blocks_z": [1, 8], "block_tiles_x": [2, 8], "block_tiles_z": [2, 8],
	"skyline": [0.0, 1.0], "landmarks": [0.0, 1.0], "trees": [0.0, 1.0], "parked_cars": [0.0, 1.0],
}
const STYLES := ["brick", "metal", "stone"]
const KIT_ROLES := ["street", "styles", "roof", "landmarks", "props", "trees", "cars"]

## Street geometry (the kit's tile sizes).
const TILE := 6.0
const ROAD_HALF := 6.0
const WALK := 3.0
const CROSS_HALF := 12.333
const STREET_HALF := ROAD_HALF + WALK      # centreline to building line
const WALK_MID := ROAD_HALF + WALK / 2.0   # centreline to the middle of the sidewalk
const SIDEWALK_TOP := 0.15
const FLOOR_H := 3.0
const MODULE := 2.0
## Tiles past the city edge so streets don't just stop.
const RUN_OUT := 4
const CAR_COLORS := ["#8c1f1f", "#1f3a5c", "#d6d6d2", "#2a2a2c", "#5c6a72", "#6b5a3a", "#3a5a40", "#c9a227"]


static func validate_params(p: Dictionary) -> Array:
	var e := []
	for k in p:
		if not DEFAULTS.has(k):
			e.append("downtown: unknown param '%s' (known: %s)" % [k, ", ".join(PackedStringArray(DEFAULTS.keys()))])
			continue
		var v = p[k]
		if k == "kit":
			if typeof(v) != TYPE_STRING:
				e.append("downtown: param 'kit' must be a string")
			elif v != "primitive":
				var ke := KitDB.validate_kit(v)
				e.append_array(ke)
				if ke.is_empty():
					for role in KIT_ROLES:
						if not KitDB.kit(v).has(role):
							e.append("downtown: kit '%s' has no '%s' role" % [v, role])
			continue
		if k == "outskirts":
			if typeof(v) != TYPE_BOOL:
				e.append("downtown: outskirts must be true or false")
			continue
		if k == "floors":
			if typeof(v) != TYPE_ARRAY or v.size() != 2 or int(v[0]) < 1 or int(v[1]) < int(v[0]) or int(v[1]) > 30:
				e.append("downtown: floors must be [min, max] with 1 <= min <= max <= 30")
			continue
		if k == "styles":
			if typeof(v) != TYPE_ARRAY or v.is_empty():
				e.append("downtown: styles must be a non-empty list of %s" % [STYLES])
			else:
				for st in v:
					if not (String(st) in STYLES):
						e.append("downtown: unknown style '%s' (known: %s)" % [st, STYLES])
			continue
		if LIMITS.has(k):
			var lim: Array = LIMITS[k]
			if not (typeof(v) in [TYPE_INT, TYPE_FLOAT]) or float(v) < float(lim[0]) or float(v) > float(lim[1]):
				e.append("downtown: %s must be a number in [%s, %s]" % [k, lim[0], lim[1]])
	return e


static func resolve_params(p: Dictionary) -> Dictionary:
	var out := DEFAULTS.duplicate(true)
	out.merge(p, true)
	for k in ["blocks_x", "blocks_z", "block_tiles_x", "block_tiles_z"]:
		out[k] = int(out[k])
	out["floors"] = [int(out["floors"][0]), int(out["floors"][1])]
	return out


static func _rng(seed_value: int, stream: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash("%d/%s" % [seed_value, stream])
	return r


static func _p3(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]


static func _anchor(pos: Vector3, fwd: Vector3) -> Dictionary:
	return {"pos": _p3(pos), "forward": _p3(fwd.normalized())}


## Grid lines: centre coordinates of the street lines 0..n (0 and n are the city
## edges, where no street runs).
static func _lines(n: int, tiles: int) -> Array:
	var pitch := 2.0 * CROSS_HALF + TILE * tiles
	var out := []
	for i in n + 1:
		out.append(snappedf((i - n / 2.0) * pitch, 0.001))
	return out


static func generate(params: Dictionary, seed_value: int) -> Dictionary:
	var p := resolve_params(params)
	# Outskirts: one more ring of blocks, so the city's edge streets have
	# buildings on both sides instead of facing empty ground.
	var ring := 2 if bool(p["outskirts"]) else 0
	var xs := _lines(p["blocks_x"] + ring, p["block_tiles_x"])
	var zs := _lines(p["blocks_z"] + ring, p["block_tiles_z"])
	var L := {
		"generator": "downtown", "seed": seed_value, "params": p,
		"lines_x": xs, "lines_z": zs,
		"bounds": [float(xs[0]) - 60.0, float(zs[0]) - 60.0, float(xs[-1]) + 60.0, float(zs[-1]) + 60.0],
	}
	_add_streets(L)
	_add_blocks(L, p, seed_value)
	_add_street_furniture(L, p, seed_value)
	_add_walkways(L)
	_add_anchors(L)
	var occ := []
	for b in L["buildings"]:
		occ.append({"id": b["id"], "rect": b["rect"], "h": b["height"]})
	L["occluders"] = occ
	return L


## Streets: interior grid lines only. Each street lists its straight tiles
## (centres) and the intersections it crosses.
static func _add_streets(L: Dictionary) -> void:
	var xs: Array = L["lines_x"]
	var zs: Array = L["lines_z"]
	var streets := []
	var crosses := []
	for j in range(1, zs.size() - 1):
		streets.append(_street("ave_%d" % j, "x", float(zs[j]), xs))
	for i in range(1, xs.size() - 1):
		streets.append(_street("st_%d" % i, "z", float(xs[i]), zs))
	for i in range(1, xs.size() - 1):
		for j in range(1, zs.size() - 1):
			crosses.append({"id": "cross_%d_%d" % [i, j], "i": i, "j": j, "pos": [float(xs[i]), 0.0, float(zs[j])]})
	L["streets"] = streets
	L["intersections"] = crosses


## A street along `axis` at `at`, crossing the perpendicular interior lines in `cross_lines`.
static func _street(id: String, axis: String, at: float, cross_lines: Array) -> Dictionary:
	var stops := []   # interior crossings
	for k in range(1, cross_lines.size() - 1):
		stops.append(float(cross_lines[k]))
	var tiles := []
	var lo := float(cross_lines[0]) - RUN_OUT * TILE
	var hi := float(cross_lines[-1]) + RUN_OUT * TILE
	# Fill [lo, hi] with 6 m tiles, skipping the intersection squares; tiles are
	# laid outward from each intersection so they meet its edges exactly.
	var edges := [lo]
	for c in stops:
		edges.append(c - CROSS_HALF)
		edges.append(c + CROSS_HALF)
	edges.append(hi)
	for k in range(0, edges.size(), 2):
		var a := float(edges[k])
		var b := float(edges[k + 1])
		var n := int(floor((b - a) / TILE + 0.001))
		var from_right := k == 0  # the run before the first intersection hugs it
		for t in n:
			var c := (b - TILE * (t + 0.5)) if from_right else (a + TILE * (t + 0.5))
			tiles.append(snappedf(c, 0.001))
	tiles.sort()
	return {"id": id, "axis": axis, "at": at, "tiles": tiles, "crossings": stops,
		"span": [snappedf(lo, 0.001), snappedf(hi, 0.001)]}


## Blocks between grid lines, lined with buildings in two rows.
static func _add_blocks(L: Dictionary, p: Dictionary, seed_value: int) -> void:
	var xs: Array = L["lines_x"]
	var zs: Array = L["lines_z"]
	var r := _rng(seed_value, "buildings")
	var blocks := []
	var buildings := []
	var styles: Array = p["styles"]
	var kit := String(p["kit"])
	var landmark_ids: Array = [] if kit == "primitive" else KitDB.kit(kit)["landmarks"]
	var cx := (float(xs[0]) + float(xs[-1])) / 2.0
	var cz := (float(zs[0]) + float(zs[-1])) / 2.0
	var max_d := Vector2(float(xs[-1]) - cx, float(zs[-1]) - cz).length()
	for a in xs.size() - 1:
		for b in zs.size() - 1:
			var rect := [float(xs[a]) + STREET_HALF, float(zs[b]) + STREET_HALF, float(xs[a + 1]) - STREET_HALF, float(zs[b + 1]) - STREET_HALF]
			var bid := "block_%d_%d" % [a, b]
			var outer := bool(p["outskirts"]) and (a == 0 or b == 0 or a == xs.size() - 2 or b == zs.size() - 2)
			blocks.append({"id": bid, "a": a, "b": b, "rect": _rect(rect), "outskirts": outer})
			var w := float(rect[2]) - float(rect[0])
			var d := float(rect[3]) - float(rect[1])
			var nx := int(floor(w / MODULE))
			var nz := int(floor(d / MODULE))
			var sx := w / (nx * MODULE)
			var sz := d / (nz * MODULE)
			# Two rows: the south row faces -Z, the north row faces +Z.
			var south_n := nz / 2
			for row in 2:
				var z0 := float(rect[1]) if row == 0 else float(rect[1]) + south_n * MODULE * sz
				var z1 := float(rect[1]) + south_n * MODULE * sz if row == 0 else float(rect[3])
				var face := Vector2(0, -1) if row == 0 else Vector2(0, 1)
				var m := 0
				while m < nx:
					var span := r.randi_range(4, 7)
					# A landmark claims a lot sized to its footprint, if it fits here.
					var landmark := ""
					if not landmark_ids.is_empty() and r.randf() < float(p["landmarks"]):
						var cand := String(landmark_ids[r.randi_range(0, landmark_ids.size() - 1)])
						var lsz := KitDB.size(cand)
						var need := int(ceil(lsz.x / (MODULE * sx) + 0.05))
						var depth := (south_n if row == 0 else nz - south_n) * MODULE * sz
						# Mid-row only: landmark side walls are plain, so they go between neighbours.
						if m > 0 and nx - (m + need) >= 3 and lsz.z <= depth + 0.2:
							landmark = cand
							span = need
					if nx - (m + span) < 3:
						span = nx - m
					var x0 := float(rect[0]) + m * MODULE * sx
					var x1 := float(rect[0]) + (m + span) * MODULE * sx
					# Taller toward the middle of the city ("skyline").
					var mid := Vector2((x0 + x1) / 2.0 - cx, (z0 + z1) / 2.0 - cz)
					var centrality := 1.0 - clampf(mid.length() / maxf(max_d, 1.0), 0.0, 1.0)
					var fmin: int = p["floors"][0]
					var fmax: int = p["floors"][1]
					var f := r.randf()
					f = lerpf(f, maxf(f, centrality), float(p["skyline"]))
					var floors := clampi(int(round(lerpf(fmin, fmax, f))), fmin, fmax)
					var style: String = styles[r.randi_range(0, styles.size() - 1)]
					var bseed := r.randi()
					var bld := {"id": "bldg_%d" % buildings.size(), "block": bid,
						"rect": _rect([x0, z0, x1, z1]), "floors": floors, "style": style,
						"face": [face.x, face.y], "modules": [span, south_n if row == 0 else nz - south_n],
						"module_scale": [snappedf(sx, 0.0001), snappedf(sz, 0.0001)], "seed": bseed,
						"landmark": landmark, "height": snappedf(SIDEWALK_TOP + floors * FLOOR_H + 1.0, 0.01)}
					if landmark != "":
						bld["height"] = snappedf(SIDEWALK_TOP + KitDB.size(landmark).y, 0.01)
					buildings.append(bld)
					m += span
	L["blocks"] = blocks
	L["buildings"] = buildings


static func _rect(r: Array) -> Array:
	return [snappedf(float(r[0]), 0.001), snappedf(float(r[1]), 0.001), snappedf(float(r[2]), 0.001), snappedf(float(r[3]), 0.001)]


## Streetlights, trees, parked cars and props along every street's sidewalks.
static func _add_street_furniture(L: Dictionary, p: Dictionary, seed_value: int) -> void:
	var r := _rng(seed_value, "furniture")
	var lights := []
	var trees := []
	var cars := []
	var props := []
	var xs: Array = L["lines_x"]
	var zs: Array = L["lines_z"]
	for s in L["streets"]:
		var along_x: bool = s["axis"] == "x"
		var at := float(s["at"])
		var lines: Array = xs if along_x else zs
		# Sidewalk runs between intersections (and out to the run-out ends).
		var cuts := [float(s["span"][0])]
		for c in s["crossings"]:
			cuts.append(float(c) - CROSS_HALF)
			cuts.append(float(c) + CROSS_HALF)
		cuts.append(float(s["span"][1]))
		for k in range(0, cuts.size(), 2):
			var a := float(cuts[k]) + 2.0
			var b := float(cuts[k + 1]) - 2.0
			for side in [-1, 1]:
				var t := a + (3.0 if side < 0 else 9.0)
				var n := 0
				while t < b:
					var curb: float = at + side * (ROAD_HALF + 0.55)
					var pos := Vector3(t, 0, curb) if along_x else Vector3(curb, 0, t)
					var to_road := Vector3(0, 0, -side) if along_x else Vector3(-side, 0, 0)
					if n % 2 == 0:
						lights.append({"id": "light_%d" % lights.size(), "pos": _p3(pos), "dir": [to_road.x, to_road.z]})
					elif r.randf() < float(p["trees"]):
						var tp := Vector3(t, 0, at + side * (ROAD_HALF + 0.9)) if along_x else Vector3(at + side * (ROAD_HALF + 0.9), 0, t)
						trees.append({"id": "tree_%d" % trees.size(), "pos": _p3(tp), "pick": r.randi(), "scale": snappedf(r.randf_range(0.85, 1.15), 0.01)})
					t += 9.0
					n += 1
				# Parked cars in the curb lane.
				var ct := a + 4.0
				while ct < b - 3.0:
					if r.randf() < float(p["parked_cars"]):
						var lane: float = at + side * (ROAD_HALF - 1.2)
						var cp := Vector3(ct, 0, lane) if along_x else Vector3(lane, 0, ct)
						var yaw := (PI / 2.0 if side > 0 else -PI / 2.0) if along_x else (0.0 if side < 0 else PI)
						cars.append({"id": "car_%d" % cars.size(), "pos": _p3(cp), "yaw": snappedf(yaw + r.randf_range(-0.03, 0.03), 0.001),
							"pick": r.randi(), "color": CAR_COLORS[r.randi_range(0, CAR_COLORS.size() - 1)]})
					ct += 5.6
		# Manholes down the middle of the road, between intersections.
		for tc in s["tiles"]:
			if r.randf() < 0.12:
				var mp := Vector3(float(tc), 0, at + r.randf_range(-2.5, 2.5)) if along_x else Vector3(at + r.randf_range(-2.5, 2.5), 0, float(tc))
				props.append({"id": "manhole_%d" % props.size(), "kind": "manhole", "pos": _p3(mp), "yaw": 0.0})
	# Bollards at every sidewalk corner.
	for c in L["intersections"]:
		for sx in [-1, 1]:
			for sz in [-1, 1]:
				var cp := Vector3(float(c["pos"][0]) + sx * (ROAD_HALF + 0.4), 0, float(c["pos"][2]) + sz * (ROAD_HALF + 0.4))
				props.append({"id": "bollard_%d" % props.size(), "kind": "bollard", "pos": _p3(cp), "yaw": 0.0})
	L["streetlights"] = lights
	L["street_trees"] = trees
	L["cars"] = cars
	L["props"] = props


## Pedestrian network: a node on each sidewalk corner of every intersection,
## edges along the sidewalks between intersections and across the crosswalks.
static func _add_walkways(L: Dictionary) -> void:
	var nodes := {}
	var edges := []
	for c in L["intersections"]:
		var cp := Vector3(c["pos"][0], 0, c["pos"][2])
		for corner in ["ne", "nw", "se", "sw"]:
			var sx := 1.0 if corner.contains("e") else -1.0
			var sz := 1.0 if corner.contains("n") else -1.0
			nodes["%s.%s" % [c["id"], corner]] = _p3(cp + Vector3(sx * WALK_MID, SIDEWALK_TOP, sz * WALK_MID))
		# Crosswalks: the four arms.
		var cid := String(c["id"])
		edges.append([cid + ".nw", cid + ".ne"])
		edges.append([cid + ".sw", cid + ".se"])
		edges.append([cid + ".sw", cid + ".nw"])
		edges.append([cid + ".se", cid + ".ne"])
	# Sidewalks between neighbouring intersections.
	var nxl: int = L["lines_x"].size()
	var nzl: int = L["lines_z"].size()
	for i in range(1, nxl - 1):
		for j in range(1, nzl - 1):
			var here := "cross_%d_%d" % [i, j]
			if i + 1 < nxl - 1:
				var east := "cross_%d_%d" % [i + 1, j]
				edges.append([here + ".ne", east + ".nw"])
				edges.append([here + ".se", east + ".sw"])
			if j + 1 < nzl - 1:
				var north := "cross_%d_%d" % [i, j + 1]
				edges.append([here + ".ne", north + ".se"])
				edges.append([here + ".nw", north + ".sw"])
	L["walkways"] = {"nodes": nodes, "edges": edges}


static func _add_anchors(L: Dictionary) -> void:
	var A := {}
	var xs: Array = L["lines_x"]
	var zs: Array = L["lines_z"]
	var cx := (float(xs[0]) + float(xs[-1])) / 2.0
	var cz := (float(zs[0]) + float(zs[-1])) / 2.0
	A["city_center"] = _anchor(Vector3(cx, 0, cz), Vector3(0, 0, -1))
	for c in L["intersections"]:
		var cp := Vector3(c["pos"][0], 0, c["pos"][2])
		A[String(c["id"])] = _anchor(cp, Vector3(0, 0, -1))
	for n in L["walkways"]["nodes"]:
		var np: Array = L["walkways"]["nodes"][n]
		var cid := String(n).get_slice(".", 0)
		var cp: Array = L["intersections"].filter(func(c): return c["id"] == cid)[0]["pos"]
		# Corners face the intersection.
		A[String(n)] = _anchor(Vector3(np[0], np[1], np[2]), Vector3(float(cp[0]) - float(np[0]), 0, float(cp[2]) - float(np[2])))
	for s in L["streets"]:
		var along_x: bool = s["axis"] == "x"
		var at := float(s["at"])
		var span: Array = s["span"]
		var mid := 0.0
		# The middle of the street: halfway between its first two crossings (or the centre).
		var cr: Array = s["crossings"]
		if cr.size() >= 2:
			mid = (float(cr[0]) + float(cr[1])) / 2.0
		elif cr.size() == 1:
			mid = float(cr[0]) + (float(cr[0]) - float(span[0])) * 0.5 * (1.0 if float(cr[0]) < (cx if along_x else cz) else -1.0)
		var dir := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
		var pos := Vector3(mid, 0, at) if along_x else Vector3(at, 0, mid)
		var id := String(s["id"])
		A[id] = _anchor(pos, dir)
		var start := Vector3(float(span[0]) + 6.0, 0, at) if along_x else Vector3(at, 0, float(span[0]) + 6.0)
		var end := Vector3(float(span[1]) - 6.0, 0, at) if along_x else Vector3(at, 0, float(span[1]) - 6.0)
		A[id + ".start"] = _anchor(start, dir)
		A[id + ".end"] = _anchor(end, -dir)
		# Sidewalks on both sides, facing along the street.
		var side_off := Vector3(0, 0, WALK_MID) if along_x else Vector3(WALK_MID, 0, 0)
		A[id + ".walk_l"] = _anchor(pos - side_off + Vector3.UP * SIDEWALK_TOP, dir)
		A[id + ".walk_r"] = _anchor(pos + side_off + Vector3.UP * SIDEWALK_TOP, dir)
	for b in L["blocks"]:
		var r: Array = b["rect"]
		A[String(b["id"])] = _anchor(Vector3((float(r[0]) + float(r[2])) / 2.0, SIDEWALK_TOP, (float(r[1]) + float(r[3])) / 2.0), Vector3(0, 0, -1))
	for bl in L["buildings"]:
		var r: Array = bl["rect"]
		var f := Vector3(bl["face"][0], 0, bl["face"][1])
		var front_z := float(r[3]) if f.z > 0 else float(r[1])
		var door := Vector3((float(r[0]) + float(r[2])) / 2.0, SIDEWALK_TOP, front_z + f.z * 1.5)
		A[String(bl["id"])] = _anchor(door, -f)   # on the sidewalk, facing the building
		A[String(bl["id"]) + ".top"] = _anchor(Vector3(door.x, float(bl["height"]), (float(r[1]) + float(r[3])) / 2.0), f)
	L["anchors"] = A


## Where feet stand: road 0, sidewalks and blocks 0.15.
static func ground_height(L: Dictionary, x: float, z: float) -> float:
	for s in L["streets"]:
		var at := float(s["at"])
		var d := absf((z if s["axis"] == "x" else x) - at)
		var along := x if s["axis"] == "x" else z
		var span: Array = s["span"]
		if d < ROAD_HALF and along >= float(span[0]) and along <= float(span[1]):
			return 0.0
	return SIDEWALK_TOP


static func manifest(L: Dictionary) -> Dictionary:
	var streets := []
	for s in L["streets"]:
		streets.append({"id": s["id"], "runs": "east-west" if s["axis"] == "x" else "north-south",
			"anchors": [s["id"], s["id"] + ".start", s["id"] + ".end", s["id"] + ".walk_l", s["id"] + ".walk_r"]})
	var tallest: Array = L["buildings"].duplicate()
	tallest.sort_custom(func(a, b): return float(a["height"]) > float(b["height"]))
	return {
		"generator": "downtown",
		"seed": L["seed"],
		"streets": streets,
		"intersections": L["intersections"].map(func(c): return c["id"]),
		"blocks": L["blocks"].map(func(b): return b["id"]),
		"tallest_buildings": tallest.slice(0, 5).map(func(b): return "%s (%d floors%s)" % [b["id"], b["floors"], ", " + String(b["landmark"]).get_file() if b["landmark"] != "" else ""]),
		"anchors": L["anchors"].keys(),
		"walkway_nodes": L["walkways"]["nodes"].size(),
		"counts": {"buildings": L["buildings"].size(), "streetlights": L["streetlights"].size(),
			"trees": L["street_trees"].size(), "cars": L["cars"].size()},
	}
