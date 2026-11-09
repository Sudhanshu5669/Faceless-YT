## TownForge town generator: a deterministic suburban town *layout* (pure data).
##
## generate(params, seed) returns a Dictionary describing every street, house,
## streetlight, car and tree. It creates no nodes, so it is fast, testable
## headless, and can be saved as JSON. town_builder.gd turns it into nodes.
##
## Conventions: metres, Y up. Rects are [x0, z0, x1, z1] in world XZ.
## A house's local +Z is its front (the street side).
## Each subsystem draws from its own named RNG stream, so changing tree
## density never reshuffles the houses.
extends RefCounted

const KitDB = preload("res://scripts/world/kit_db.gd")

const DEFAULTS := {
	"blocks_x": 3,
	"blocks_z": 2,
	"block_w": 64.0,
	"block_d": 52.0,
	"road_w": 8.0,
	"sidewalk_w": 2.2,
	"lot_w": 15.0,
	"house_density": 0.9,
	"two_story_chance": 0.35,
	"garage_chance": 0.6,
	"tree_density": 0.6,
	"car_density": 0.4,
	"light_spacing": 22.0,
	"exit_roads": true,
	"forest_band": 45.0,
	"forest_density": 0.5,
	"kit": "suburban",
	"season": "summer",
}

const LIMITS := {
	"blocks_x": [1, 8], "blocks_z": [1, 8],
	"block_w": [30.0, 150.0], "block_d": [40.0, 120.0],
	"road_w": [5.0, 16.0], "sidewalk_w": [1.0, 5.0],
	"lot_w": [12.0, 40.0],
	"house_density": [0.0, 1.0], "two_story_chance": [0.0, 1.0], "garage_chance": [0.0, 1.0],
	"tree_density": [0.0, 3.0], "car_density": [0.0, 1.0],
	"light_spacing": [8.0, 80.0],
	"forest_band": [0.0, 150.0], "forest_density": [0.0, 2.0],
}

const STREET_NAMES := [
	"Maple", "Oak", "Elm", "Birch", "Cedar", "Willow", "Pine", "Ash", "Hawthorne",
	"Juniper", "Linden", "Alder", "Chestnut", "Hollow", "Ridge", "Mill", "Church",
	"Orchard", "Sycamore", "Magnolia", "Laurel", "Spruce", "Holly", "Aspen",
]
const SIDING := ["#c9c2b0", "#9fb3c8", "#b8c4a8", "#d8d2c4", "#c7a98f", "#a7a3a0", "#c99c8f", "#e0d6b8", "#8fa39a"]
const ROOFS := ["#3e3f45", "#5a4638", "#4a5560", "#6b3d33", "#2f3438"]
const DOORS := ["#7a2e2a", "#2f3e57", "#3d5a3e", "#e8e4da", "#3a2d24", "#8a6a2a"]
const CAR_COLORS := ["#8c1f1f", "#1f3a5c", "#d6d6d2", "#2a2a2c", "#5c6a72", "#6b5a3a", "#3a5a40", "#b0a48a"]

const YARD_TREES := {"round": 0.55, "tall": 0.2, "pine": 0.25}
const FOREST_TREES := {"pine": 0.65, "round": 0.2, "tall": 0.15}


# --- params -----------------------------------------------------------------

static func validate_params(p: Dictionary) -> Array:
	var errors := []
	for k in p.keys():
		if not DEFAULTS.has(k):
			errors.append("town: unknown param '%s' (known: %s)" % [k, ", ".join(PackedStringArray(DEFAULTS.keys()))])
			continue
		var v = p[k]
		if k == "kit":
			if typeof(v) != TYPE_STRING:
				errors.append("town: param 'kit' must be a string")
			elif v != "primitive":
				errors.append_array(KitDB.validate_kit(v))
			continue
		if k == "season":
			if not (v in KitDB.SEASONS):
				errors.append("town: param 'season' must be one of %s" % [KitDB.SEASONS])
			continue
		if typeof(DEFAULTS[k]) == TYPE_BOOL:
			if typeof(v) != TYPE_BOOL:
				errors.append("town: param '%s' must be true or false" % k)
			continue
		if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
			errors.append("town: param '%s' must be a number" % k)
			continue
		if LIMITS.has(k):
			var lim: Array = LIMITS[k]
			if float(v) < float(lim[0]) or float(v) > float(lim[1]):
				errors.append("town: param '%s'=%s is outside [%s, %s]" % [k, v, lim[0], lim[1]])
	return errors


static func resolve_params(p: Dictionary) -> Dictionary:
	var out := DEFAULTS.duplicate()
	for k in p.keys():
		if not DEFAULTS.has(k):
			continue
		match typeof(DEFAULTS[k]):
			TYPE_INT:
				out[k] = int(p[k])
			TYPE_FLOAT:
				out[k] = float(p[k])
			_:
				out[k] = p[k]
	return out


# --- helpers ----------------------------------------------------------------

static func _rng(seed_value: int, stream: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash("%d/%s" % [seed_value, stream])
	return r


static func _pick(r: RandomNumberGenerator, arr: Array):
	return arr[r.randi_range(0, arr.size() - 1)]


static func _weighted(r: RandomNumberGenerator, weights: Dictionary) -> String:
	var total := 0.0
	for k in weights:
		total += float(weights[k])
	var roll := r.randf() * total
	for k in weights:
		roll -= float(weights[k])
		if roll <= 0.0:
			return k
	return weights.keys()[-1]


static func _shuffle(arr: Array, r: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t


static func _s(v: float) -> float:
	return snappedf(v, 0.001)


static func _p3(v: Vector3) -> Array:
	return [_s(v.x), _s(v.y), _s(v.z)]


static func _rect_xf(xf: Transform3D, lx0: float, lz0: float, lx1: float, lz1: float) -> Array:
	var a := xf * Vector3(lx0, 0, lz0)
	var b := xf * Vector3(lx1, 0, lz1)
	return [_s(minf(a.x, b.x)), _s(minf(a.z, b.z)), _s(maxf(a.x, b.x)), _s(maxf(a.z, b.z))]


static func grow(r: Array, m: float) -> Array:
	return [r[0] - m, r[1] - m, r[2] + m, r[3] + m]


static func rects_overlap(a: Array, b: Array) -> bool:
	return a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]


static func in_rect(x: float, z: float, r: Array) -> bool:
	return x >= r[0] and x <= r[2] and z >= r[1] and z <= r[3]


static func _hits(x: float, z: float, rects: Array) -> bool:
	for r in rects:
		if in_rect(x, z, r):
			return true
	return false


static func _near_any(v: float, centers: Array, radius: float) -> bool:
	for c in centers:
		if absf(v - float(c)) < radius:
			return true
	return false


# Spatial hash for minimum-spacing checks between trees.
static func _too_close(grid: Dictionary, x: float, z: float, dist: float) -> bool:
	var cell := Vector2i(floori(x / 4.0), floori(z / 4.0))
	var reach := ceili(dist / 4.0)
	for dx in range(-reach, reach + 1):
		for dz in range(-reach, reach + 1):
			var key := cell + Vector2i(dx, dz)
			if grid.has(key):
				for q in grid[key]:
					if Vector2(x, z).distance_to(q) < dist:
						return true
	return false


static func _grid_add(grid: Dictionary, x: float, z: float) -> void:
	var cell := Vector2i(floori(x / 4.0), floori(z / 4.0))
	if not grid.has(cell):
		grid[cell] = []
	grid[cell].append(Vector2(x, z))


# --- generation -------------------------------------------------------------

static func generate(params: Dictionary, seed_value: int) -> Dictionary:
	var p := resolve_params(params)
	var nbx: int = p["blocks_x"]
	var nbz: int = p["blocks_z"]
	var bw: float = p["block_w"]
	var bd: float = p["block_d"]
	var rw: float = p["road_w"]
	var total_w := nbx * bw + (nbx + 1) * rw
	var total_d := nbz * bd + (nbz + 1) * rw
	var x0 := -total_w / 2.0
	var z0 := -total_d / 2.0
	var road_x := []
	for i in nbx + 1:
		road_x.append(_s(x0 + rw / 2.0 + i * (bw + rw)))
	var road_z := []
	for j in nbz + 1:
		road_z.append(_s(z0 + rw / 2.0 + j * (bd + rw)))

	var L := {
		"generator": "town",
		"seed": seed_value,
		"params": p,
		"bounds": [_s(x0), _s(z0), _s(x0 + total_w), _s(z0 + total_d)],
		"road_x": road_x,
		"road_z": road_z,
	}
	_add_streets(L, p, seed_value)
	_add_lots_and_houses(L, p, seed_value)
	_add_streetlights(L, p)
	_add_street_cars(L, p, seed_value)
	_add_trees(L, p, seed_value)
	_add_anchors(L, p)
	L.erase("_obstacles")
	return L


static func _exit_len(p: Dictionary) -> float:
	return float(p["forest_band"]) + 25.0 if p["exit_roads"] else 0.0


static func _add_streets(L: Dictionary, p: Dictionary, seed_value: int) -> void:
	var r := _rng(seed_value, "names")
	var names: Array = STREET_NAMES.duplicate()
	_shuffle(names, r)
	var b: Array = L["bounds"]
	var rw: float = p["road_w"]
	var road_x: Array = L["road_x"]
	var road_z: Array = L["road_z"]
	var main_j := floori((road_z.size() - 1) / 2.0)
	var ext := _exit_len(p)
	var streets := []
	var n := 0
	for j in road_z.size():
		var is_main := j == main_j
		var e := ext if is_main else 0.0
		streets.append({
			"id": "street_h%d" % j,
			"name": "%s %s" % [names[n % names.size()], _pick(r, ["Street", "Lane", "Drive"])],
			"axis": "x", "main": is_main, "width": rw,
			"from": _p3(Vector3(float(b[0]) - e, 0, float(road_z[j]))),
			"to": _p3(Vector3(float(b[2]) + e, 0, float(road_z[j]))),
		})
		n += 1
	for i in road_x.size():
		streets.append({
			"id": "street_v%d" % i,
			"name": "%s %s" % [names[n % names.size()], _pick(r, ["Avenue", "Road"])],
			"axis": "z", "main": false, "width": rw,
			"from": _p3(Vector3(float(road_x[i]), 0, float(b[1]))),
			"to": _p3(Vector3(float(road_x[i]), 0, float(b[3]))),
		})
		n += 1
	L["streets"] = streets
	L["main_street"] = "street_h%d" % main_j
	var ints := []
	for i in road_x.size():
		for j in road_z.size():
			ints.append({
				"id": "int_%d_%d" % [i, j],
				"pos": _p3(Vector3(float(road_x[i]), 0, float(road_z[j]))),
				"streets": ["street_v%d" % i, "street_h%d" % j],
			})
	L["intersections"] = ints


static func _add_lots_and_houses(L: Dictionary, p: Dictionary, seed_value: int) -> void:
	var r := _rng(seed_value, "houses")
	var rw: float = p["road_w"]
	var sw: float = p["sidewalk_w"]
	var lot_w: float = p["lot_w"]
	var road_x: Array = L["road_x"]
	var road_z: Array = L["road_z"]
	var blocks := []
	var houses := []
	var vacant := []
	var driveways := []
	var walkways := []
	var fences := []
	var obstacles := []
	var cars := []
	var bushes := []
	for j in road_z.size() - 1:
		for i in road_x.size() - 1:
			var rect := [_s(road_x[i] + rw / 2.0), _s(road_z[j] + rw / 2.0), _s(road_x[i + 1] - rw / 2.0), _s(road_z[j + 1] - rw / 2.0)]
			var g := [_s(rect[0] + sw), _s(rect[1] + sw), _s(rect[2] - sw), _s(rect[3] - sw)]
			var block_id := "block_%d_%d" % [i, j]
			blocks.append({"id": block_id, "rect": rect, "grass": g})
			var zmid: float = (g[1] + g[3]) / 2.0
			fences.append({"from": [g[0], _s(zmid)], "to": [g[2], _s(zmid)]})
			var n := maxi(1, floori((g[2] - g[0]) / lot_w))
			var lw: float = (g[2] - g[0]) / n
			var row_depth: float = (g[3] - g[1]) / 2.0
			for row in 2:
				var facing := -1 if row == 0 else 1
				var street_id := "street_h%d" % (j if row == 0 else j + 1)
				var edge: float = g[1] if row == 0 else g[3]
				for k in n:
					var lx0: float = g[0] + k * lw
					var lot_rect := [_s(lx0), _s(minf(edge, zmid)), _s(lx0 + lw), _s(maxf(edge, zmid))]
					if k > 0:
						fences.append({"from": [_s(lx0), _s(zmid)], "to": [_s(lx0), _s(zmid + facing * row_depth * 0.45)]})
					if r.randf() > float(p["house_density"]):
						vacant.append({
							"id": "vacant_%d" % vacant.size(), "street": street_id, "rect": lot_rect,
							"center": _p3(Vector3(lx0 + lw / 2.0, 0, (lot_rect[1] + lot_rect[3]) / 2.0)),
						})
						continue
					var made := _make_house(r, p, houses.size(), street_id, facing, edge, lx0, lw, row_depth, sw)
					houses.append(made["house"])
					driveways.append(made["driveway"])
					walkways.append(made["walkway"])
					obstacles.append_array(made["obstacles"])
					bushes.append_array(made["bushes"])
					if made.has("car"):
						cars.append(made["car"])

	_assign_addresses(L, houses)
	L["blocks"] = blocks
	L["houses"] = houses
	L["vacant_lots"] = vacant
	L["driveways"] = driveways
	L["walkways"] = walkways
	L["fences"] = fences
	L["cars"] = cars
	L["bushes"] = bushes
	L["_obstacles"] = obstacles


static func _make_house(r: RandomNumberGenerator, p: Dictionary, idx: int, street_id: String,
		facing: int, edge: float, lx0: float, lw: float, row_depth: float, sw: float) -> Dictionary:
	var stories := 2 if r.randf() < float(p["two_story_chance"]) else 1
	var w_max := minf(11.5, lw - 5.5)
	var w := r.randf_range(minf(8.0, w_max), w_max)
	var setback := r.randf_range(6.5, 8.0)
	var d_max := minf(10.0, row_depth - setback - 3.0)
	var d := r.randf_range(minf(7.5, d_max), d_max)
	var wall_h := 3.0 if stories == 1 else 5.8
	var side := 1 if r.randf() < 0.5 else -1
	var garage := r.randf() < float(p["garage_chance"]) and w + 4.4 <= lw - 2.0
	var roof_style := "side_gable" if r.randf() < 0.6 else "front_gable"
	var roof_h := r.randf_range(1.6, 2.6)
	var porch := r.randf() < 0.35
	var chimney := r.randf() < 0.4
	var door_x := -side * r.randf_range(0.0, w * 0.18)
	var siding: String = _pick(r, SIDING)
	var roof_c: String = _pick(r, ROOFS)
	var door_c: String = _pick(r, DOORS)

	# Kit houses: the model's measured proportions decide footprint and height.
	var model_id := ""
	var model_scale := 1.0
	if String(p["kit"]) != "primitive":
		var kh: Dictionary = KitDB.kit(p["kit"])["house"]
		model_id = _pick(r, kh["models"])
		var msz := KitDB.size(model_id)
		var tw: Array = kh["target_width"]
		var target_w := minf(r.randf_range(float(tw[0]), float(tw[1])), lw - 5.5)
		model_scale = minf(target_w / msz.x, (row_depth - setback - 3.0) / msz.z)
		w = msz.x * model_scale
		d = msz.z * model_scale
		wall_h = msz.y * model_scale
		stories = 2 if wall_h > 7.5 else 1
		garage = false
		porch = false
		chimney = false
		door_x = 0.0

	var rot := 0.0 if facing == 1 else 180.0
	var sgn := float(facing)  # rot 180 flips local X
	var cx := lx0 + lw / 2.0 - sgn * side * 1.9
	var cz := edge - facing * (setback + d / 2.0)
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(rot)), Vector3(cx, 0, cz))

	var front_z := d / 2.0
	var lot_front_z := front_z + setback
	var drive_x := side * (w / 2.0 + 1.9)
	var drive_z0 := front_z if garage else front_z - 5.5
	var driveway := {"rect": _rect_xf(xf, drive_x - 1.6, drive_z0, drive_x + 1.6, lot_front_z + sw)}
	var walk_z0 := front_z + (1.8 if porch else 0.0)
	var walkway := {"rect": _rect_xf(xf, door_x - 0.6, walk_z0, door_x + 0.6, lot_front_z)}

	var windows := []
	for fl in stories:
		var y := 1.55 + fl * 2.8
		for wx in [-w * 0.3, w * 0.3]:
			if fl == 0 and absf(wx - door_x) < 1.4:
				continue
			windows.append({"face": "front", "x": _s(wx), "y": y, "roll": _s(r.randf())})
		if fl == 1:
			windows.append({"face": "front", "x": _s(door_x), "y": y, "roll": _s(r.randf())})
		for face in ["left", "right"]:
			var garage_face := "right" if side > 0 else "left"
			if garage and fl == 0 and face == garage_face:
				continue
			windows.append({"face": face, "x": 0.0, "y": y, "roll": _s(r.randf())})

	var hx0 := -w / 2.0
	var hx1 := w / 2.0
	if garage:
		if side > 0:
			hx1 = w / 2.0 + 3.7
		else:
			hx0 = -(w / 2.0 + 3.7)
	var house_rect := _rect_xf(xf, hx0, -d / 2.0, hx1, front_z + (1.9 if porch else 0.3))

	var bushes := []
	var nb := r.randi_range(1, 4)
	for b in nb:
		var bx := r.randf_range(-w / 2.0 + 0.7, w / 2.0 - 0.7)
		var br := r.randf_range(0.45, 0.85)
		var tint := r.randi_range(0, 3)
		if absf(bx - door_x) < (1.9 if porch else 1.1):
			continue
		bushes.append({"pos": _p3(xf * Vector3(bx, 0, front_z + 0.9)), "r": _s(br), "tint": tint})

	var house := {
		"id": "house_%d" % idx,
		"street": street_id,
		"address": "",
		"pos": _p3(Vector3(cx, 0, cz)),
		"rot_y": rot,
		"facing": facing,
		"w": _s(w), "d": _s(d), "wall_h": wall_h, "stories": stories,
		"setback": _s(setback), "side": side,
		"roof": {"style": roof_style, "h": _s(roof_h), "color": roof_c},
		"siding": siding, "door_color": door_c, "door_x": _s(door_x),
		"garage": garage, "porch": porch, "chimney": chimney,
		"porch_light_roll": _s(r.randf()),
		"window_roll": _s(r.randf()),
		"roof_pick": r.randi_range(0, 999),
		"windows": windows if model_id == "" else [],
		"rect": house_rect,
		"anchors": {
			"front_door": _p3(xf * Vector3(door_x, 0, front_z + (2.0 if porch else 0.8))),
			"lawn": _p3(xf * Vector3(-side * w * 0.25, 0, front_z + setback * 0.5)),
			"driveway": _p3(xf * Vector3(drive_x, 0, lot_front_z - 1.5)),
			"backyard": _p3(xf * Vector3(0, 0, -d / 2.0 - 2.0)),
			"curb": _p3(xf * Vector3(door_x, 0, lot_front_z + sw + 0.8)),
		},
	}
	if model_id != "":
		house["model"] = model_id
		house["model_scale"] = _s(model_scale)
	var out := {
		"house": house,
		"driveway": driveway,
		"walkway": walkway,
		"bushes": bushes,
		"obstacles": [grow(house_rect, 1.5), grow(driveway["rect"], 0.8), grow(walkway["rect"], 0.6)],
	}
	if r.randf() < float(p["car_density"]) * 1.4:
		var car_z := lot_front_z - 2.6 if garage else front_z - 1.2
		out["car"] = {
			"pos": _p3(xf * Vector3(drive_x, 0, car_z)),
			"rot_y": fposmod(rot + 180.0, 360.0),
			"color": _pick(r, CAR_COLORS),
			"surface": "pave",
		}
	return out


## Odd numbers on one side of each street, even on the other, increasing along +X.
static func _assign_addresses(L: Dictionary, houses: Array) -> void:
	var names := {}
	for s in L["streets"]:
		names[s["id"]] = s["name"]
	var by_street := {}
	for h in houses:
		if not by_street.has(h["street"]):
			by_street[h["street"]] = []
		by_street[h["street"]].append(h)
	for sid in by_street:
		var list: Array = by_street[sid]
		list.sort_custom(func(a, b): return a["pos"][0] < b["pos"][0])
		var odd := 1
		var even := 2
		for h in list:
			if h["facing"] == 1:
				h["address"] = "%d %s" % [odd, names[sid]]
				odd += 2
			else:
				h["address"] = "%d %s" % [even, names[sid]]
				even += 2


static func _add_streetlights(L: Dictionary, p: Dictionary) -> void:
	var rw: float = p["road_w"]
	var sw: float = p["sidewalk_w"]
	var spacing: float = p["light_spacing"]
	var road_x: Array = L["road_x"]
	var road_z: Array = L["road_z"]
	var b: Array = L["bounds"]
	var blockers := []
	for d in L["driveways"]:
		blockers.append(grow(d["rect"], 0.6))
	for w in L["walkways"]:
		blockers.append(grow(w["rect"], 0.6))
	var lights := []
	var off := rw / 2.0 + 0.45
	var clear := rw / 2.0 + sw + 1.0

	# E-W streets (constant z). Sides alternate between the two sidewalks.
	for j in road_z.size():
		var sides := []
		if j > 0:
			sides.append(-1)
		if j < road_z.size() - 1:
			sides.append(1)
		var alt := 0
		var t: float = float(b[0]) + spacing * 0.5
		while t < float(b[2]):
			var s: int = sides[alt % sides.size()]
			alt += 1
			for shift in [0.0, 2.5, -2.5, 5.0]:
				var x: float = t + shift
				var z: float = float(road_z[j]) + s * off
				if _near_any(x, road_x, clear) or _hits(x, z, blockers):
					continue
				lights.append({"id": "light_%d" % lights.size(), "pos": _p3(Vector3(x, 0, z)), "dir": [0.0, float(-s)], "street": "street_h%d" % j})
				break
			t += spacing

	# N-S streets (constant x).
	for i in road_x.size():
		var sides := []
		if i > 0:
			sides.append(-1)
		if i < road_x.size() - 1:
			sides.append(1)
		var alt := 0
		var t: float = float(b[1]) + spacing * 0.5
		while t < float(b[3]):
			var s: int = sides[alt % sides.size()]
			alt += 1
			if not _near_any(t, road_z, clear):
				var x: float = float(road_x[i]) + s * off
				lights.append({"id": "light_%d" % lights.size(), "pos": _p3(Vector3(x, 0, t)), "dir": [float(-s), 0.0], "street": "street_v%d" % i})
			t += spacing

	# Exit roads: a few lonely lights leading out of town along the main street.
	var ext := _exit_len(p)
	if ext > 0.0:
		var mz: float = road_z[floori((road_z.size() - 1) / 2.0)]
		var t := 14.0
		while t < ext - 10.0:
			lights.append({"id": "light_%d" % lights.size(), "pos": _p3(Vector3(float(b[2]) + t, 0, mz + off)), "dir": [0.0, -1.0], "street": L["main_street"]})
			lights.append({"id": "light_%d" % lights.size(), "pos": _p3(Vector3(float(b[0]) - t, 0, mz - off)), "dir": [0.0, 1.0], "street": L["main_street"]})
			t += spacing * 1.8
	L["streetlights"] = lights


static func _add_street_cars(L: Dictionary, p: Dictionary, seed_value: int) -> void:
	var r := _rng(seed_value, "street_cars")
	var rw: float = p["road_w"]
	var sw: float = p["sidewalk_w"]
	var road_x: Array = L["road_x"]
	var road_z: Array = L["road_z"]
	var b: Array = L["bounds"]
	var cars: Array = L["cars"]
	for i in road_x.size():
		for s in [-1, 1]:
			var x: float = float(road_x[i]) + s * (rw / 2.0 - 1.15)
			var t: float = float(b[1]) + 6.0
			while t < float(b[3]) - 6.0:
				if not _near_any(t, road_z, rw / 2.0 + sw + 3.0) and r.randf() < float(p["car_density"]) * 0.3:
					cars.append({"pos": _p3(Vector3(x, 0, t)), "rot_y": 0.0 if s < 0 else 180.0, "color": _pick(r, CAR_COLORS), "surface": "road"})
					t += 7.0
				else:
					t += 3.5


static func _tree(r: RandomNumberGenerator, x: float, z: float, weights: Dictionary, s_min: float, s_max: float, ground: String) -> Dictionary:
	return {
		"pos": _p3(Vector3(x, 0, z)),
		"variant": _weighted(r, weights),
		"scale": _s(r.randf_range(s_min, s_max)),
		"rot_y": _s(r.randf() * 360.0),
		"tint": r.randi_range(0, 3),
		"ground": ground,
	}


static func _add_trees(L: Dictionary, p: Dictionary, seed_value: int) -> void:
	var r := _rng(seed_value, "trees")
	var trees := []
	var grid := {}
	var obstacles: Array = L["_obstacles"]
	for blk in L["blocks"]:
		var g: Array = blk["grass"]
		var zmid: float = (g[1] + g[3]) / 2.0
		var area: float = (g[2] - g[0]) * (g[3] - g[1])
		var want := roundi(float(p["tree_density"]) * area / 110.0)
		var placed := 0
		var tries := 0
		while placed < want and tries < want * 20:
			tries += 1
			var x := r.randf_range(g[0] + 0.8, g[2] - 0.8)
			var z := r.randf_range(g[1] + 0.8, g[3] - 0.8)
			if absf(z - zmid) < 0.8 or _hits(x, z, obstacles) or _too_close(grid, x, z, 3.2):
				continue
			_grid_add(grid, x, z)
			trees.append(_tree(r, x, z, YARD_TREES, 0.8, 1.3, "grass"))
			placed += 1

	var band: float = p["forest_band"]
	if band > 0.0 and float(p["forest_density"]) > 0.0:
		var b: Array = L["bounds"]
		var inner := grow(b, 4.0)
		var outer := grow(b, 4.0 + band)
		var area: float = (outer[2] - outer[0]) * (outer[3] - outer[1]) - (inner[2] - inner[0]) * (inner[3] - inner[1])
		var want := roundi(float(p["forest_density"]) * area / 45.0)
		var keep_clear := []
		if p["exit_roads"]:
			var road_z: Array = L["road_z"]
			var mz: float = road_z[floori((road_z.size() - 1) / 2.0)]
			var rw: float = p["road_w"]
			keep_clear.append([outer[0] - 1.0, mz - rw / 2.0 - 3.5, outer[2] + 1.0, mz + rw / 2.0 + 3.5])
		var placed := 0
		var tries := 0
		while placed < want and tries < want * 6:
			tries += 1
			var x := r.randf_range(outer[0], outer[2])
			var z := r.randf_range(outer[1], outer[3])
			if in_rect(x, z, inner) or _hits(x, z, keep_clear) or _too_close(grid, x, z, 2.6):
				continue
			_grid_add(grid, x, z)
			trees.append(_tree(r, x, z, FOREST_TREES, 0.9, 1.6, "ground"))
			placed += 1
	L["trees"] = trees


static func _add_anchors(L: Dictionary, p: Dictionary) -> void:
	var b: Array = L["bounds"]
	var best: Dictionary = {}
	var best_d := INF
	for it in L["intersections"]:
		var pos: Array = it["pos"]
		var dd := Vector2(pos[0], pos[2]).length()
		if dd < best_d:
			best_d = dd
			best = it
	var road_z: Array = L["road_z"]
	var mz: float = road_z[floori((road_z.size() - 1) / 2.0)]
	var anchors := {
		"town_center": best["pos"],
		"town_center_intersection": best["id"],
		"main_street_west": _p3(Vector3(float(b[0]) + 4.0, 0, mz)),
		"main_street_mid": _p3(Vector3((float(b[0]) + float(b[2])) / 2.0, 0, mz)),
		"main_street_east": _p3(Vector3(float(b[2]) - 4.0, 0, mz)),
	}
	if p["exit_roads"]:
		anchors["town_entrance_east"] = _p3(Vector3(float(b[2]) + 25.0, 0, mz))
		anchors["town_entrance_west"] = _p3(Vector3(float(b[0]) - 25.0, 0, mz))
	L["anchors"] = anchors


## Height of the walkable surface at (x, z): what an actor's feet stand on.
## Matches the builder: road 0.02, sidewalk 0.15, lawn 0.17, driveway/path 0.18.
static func ground_height(L: Dictionary, x: float, z: float) -> float:
	for blk in L["blocks"]:
		if in_rect(x, z, blk["rect"]):
			for d in L["driveways"]:
				if in_rect(x, z, d["rect"]):
					return 0.18
			for w in L["walkways"]:
				if in_rect(x, z, w["rect"]):
					return 0.18
			return 0.17 if in_rect(x, z, blk["grass"]) else 0.15
	var b: Array = L["bounds"]
	if in_rect(x, z, b):
		return 0.02
	for s in L["streets"]:
		if s["main"] and absf(z - float(s["from"][2])) <= float(s["width"]) / 2.0 and x >= float(s["from"][0]) and x <= float(s["to"][0]):
			return 0.02
	return 0.0


## What the director (LLM) needs: named places and addresses, not geometry.
static func manifest(L: Dictionary) -> Dictionary:
	var houses := []
	for h in L["houses"]:
		houses.append({
			"id": h["id"], "address": h["address"], "street": h["street"],
			"stories": h["stories"], "garage": h["garage"], "porch": h["porch"],
			"anchors": h["anchors"],
		})
	var streets := []
	for s in L["streets"]:
		streets.append({"id": s["id"], "name": s["name"], "main": s["main"], "from": s["from"], "to": s["to"]})
	var vacant := []
	for v in L["vacant_lots"]:
		vacant.append({"id": v["id"], "street": v["street"], "center": v["center"]})
	return {
		"generator": "town",
		"seed": L["seed"],
		"bounds": L["bounds"],
		"anchors": L["anchors"],
		"main_street": L["main_street"],
		"streets": streets,
		"intersections": L["intersections"],
		"houses": houses,
		"vacant_lots": vacant,
		"counts": {
			"houses": houses.size(),
			"vacant_lots": vacant.size(),
			"streetlights": L["streetlights"].size(),
			"cars": L["cars"].size(),
			"trees": L["trees"].size(),
		},
	}
