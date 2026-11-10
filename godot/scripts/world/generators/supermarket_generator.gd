## TownForge supermarket generator: a deterministic supermarket *layout*
## (pure data): a single-storey store with numbered aisles of double-sided
## shelving, a cross aisle at the front and back, checkouts by the glass
## storefront, a freezer wall at the back, a toy section, and a parking lot.
##
## Conventions: metres, Y up. Rects are [x0, z0, x1, z1]. The storefront glass
## is at z = 0 and faces +Z (the parking lot); the store interior is z < 0.
## Aisle k (1..N) is the walkway between gondola k-1 and gondola k; aisles are
## numbered left to right as seen from the entrance (+X). supermarket_builder.gd
## turns the layout into nodes.
extends RefCounted

const DEFAULTS := {
	"aisles": 8,
	"aisle_length": 18.0,
	"aisle_w": 2.4,
	"shelf_d": 1.1,
	"shelf_h": 2.1,
	"front_zone": 9.0,
	"back_zone": 4.0,
	"side_zone": 3.0,
	"checkouts": 4,
	"parking_depth": 34.0,
	"car_density": 0.25,
	"power": "night",
	"toy_aisle": 6,
	"name": "FRESHWAY",
}

const LIMITS := {
	"aisles": [2, 14], "aisle_length": [8.0, 40.0], "aisle_w": [1.6, 4.0], "shelf_d": [0.6, 1.6],
	"shelf_h": [1.4, 2.6], "front_zone": [6.0, 16.0], "back_zone": [3.0, 8.0], "side_zone": [2.0, 6.0],
	"checkouts": [1, 10], "parking_depth": [12.0, 80.0], "car_density": [0.0, 1.0], "toy_aisle": [0, 14],
}
## Ceiling lights: "on" (open store), "night" (closed: every third fixture),
## "emergency" (only exit signs and a few fixtures), "off".
const POWER := ["on", "night", "emergency", "off"]
const STORE_H := 4.6
const SHELF_LEVELS := 4
## What each aisle side stocks (cycled); the toy aisle gets a toy section.
const CATEGORIES := ["cereal", "snacks", "cans", "drinks", "pasta", "cleaning", "bakery", "household",
	"drinks", "cans", "snacks", "cereal", "pasta", "household"]
const AISLE_TITLES := {"cereal": "CEREAL", "snacks": "SNACKS", "cans": "CANNED", "drinks": "DRINKS",
	"pasta": "PASTA & RICE", "cleaning": "CLEANING", "bakery": "BAKERY", "household": "HOUSEHOLD", "toys": "TOYS & GAMES"}
const CAR_COLORS := ["#8c1f1f", "#1f3a5c", "#d6d6d2", "#2a2a2c", "#5c6a72", "#6b5a3a", "#3a5a40"]
const TOY_COLORS := ["#d8473c", "#3f7fd6", "#e8c23a", "#4fb36a", "#9a5ad0", "#ef8a3c"]


static func validate_params(p: Dictionary) -> Array:
	var e := []
	for k in p:
		if not DEFAULTS.has(k):
			e.append("supermarket: unknown param '%s' (known: %s)" % [k, ", ".join(PackedStringArray(DEFAULTS.keys()))])
			continue
		if LIMITS.has(k):
			var lim: Array = LIMITS[k]
			if not (typeof(p[k]) in [TYPE_INT, TYPE_FLOAT]) or float(p[k]) < float(lim[0]) or float(p[k]) > float(lim[1]):
				e.append("supermarket: %s must be a number in [%s, %s]" % [k, lim[0], lim[1]])
	if p.has("power") and not (String(p["power"]) in POWER):
		e.append("supermarket: power must be one of %s" % [POWER])
	var aisles := int(p.get("aisles", DEFAULTS["aisles"]))
	if int(p.get("toy_aisle", DEFAULTS["toy_aisle"])) > aisles:
		e.append("supermarket: toy_aisle %d is beyond the last aisle (%d); 0 = no toys" % [p["toy_aisle"], aisles])
	return e


static func resolve_params(p: Dictionary) -> Dictionary:
	var out := DEFAULTS.duplicate()
	out.merge(p, true)
	for k in ["aisles", "checkouts", "toy_aisle"]:
		out[k] = int(out[k])
	return out


static func _rng(seed_value: int, stream: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash("%d/%s" % [seed_value, stream])
	return r


static func _p3(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]


static func _anchor(pos: Vector3, fwd: Vector3) -> Dictionary:
	return {"pos": _p3(pos), "forward": _p3(fwd.normalized())}


static func generate(params: Dictionary, seed_value: int) -> Dictionary:
	var p := resolve_params(params)
	var n: int = p["aisles"]
	var sd: float = p["shelf_d"]
	var aw: float = p["aisle_w"]
	var pitch := sd + aw
	var total := (n + 1) * sd + n * aw
	var half_w := total / 2.0 + float(p["side_zone"])
	var z_front_aisle := -float(p["front_zone"])          # where aisles begin
	var z_aisle_end := z_front_aisle - float(p["aisle_length"])
	var z_back := z_aisle_end - float(p["back_zone"])
	var L := {
		"generator": "supermarket", "seed": seed_value, "params": p,
		"store": {"rect": [-half_w, z_back, half_w, 0.0], "height": STORE_H},
		"bounds": [-half_w - 12.0, z_back - 4.0, half_w + 12.0, float(p["parking_depth"])],
	}
	# Gondolas (double-sided shelving runs) and the shelf faces they carry.
	var gondolas := []
	var shelves := []
	var cr := _rng(seed_value, "stock")
	var cat_offset := cr.randi_range(0, CATEGORIES.size() - 1)
	var aisle_cats := {}
	for k in range(1, n + 1):
		aisle_cats[k] = CATEGORIES[(k - 1 + cat_offset) % CATEGORIES.size()]
	var toy_aisle: int = p["toy_aisle"]
	if toy_aisle > 0:
		aisle_cats[toy_aisle] = "toys"
	for i in n + 1:
		var gx := -total / 2.0 + sd / 2.0 + i * pitch
		var rect := [gx - sd / 2.0, z_aisle_end, gx + sd / 2.0, z_front_aisle]
		gondolas.append({"id": "gondola_%d" % i, "rect": rect, "h": float(p["shelf_h"])})
		# Left face (-X) serves aisle i, right face (+X) serves aisle i+1.
		for side in [-1, 1]:
			var aisle := i if side < 0 else i + 1
			if aisle < 1 or aisle > n:
				continue
			shelves.append({"id": "shelf_%d_%s" % [i, "w" if side < 0 else "e"], "gondola": i, "aisle": aisle,
				"x": gx + side * sd / 2.0, "z0": z_aisle_end + 0.05, "z1": z_front_aisle - 0.05, "facing": [side, 0],
				"category": "grocery" if aisle_cats[aisle] == "toys" else aisle_cats[aisle],
				"seed": cr.randi()})
	L["gondolas"] = gondolas
	L["shelves"] = shelves
	var aisles := []
	for k in range(1, n + 1):
		var ax := -total / 2.0 + sd + (k - 1) * pitch + aw / 2.0
		aisles.append({"id": "aisle_%d" % k, "number": k, "x": ax, "z0": z_front_aisle, "z1": z_aisle_end,
			"category": aisle_cats[k], "title": AISLE_TITLES[aisle_cats[k]]})
	L["aisles"] = aisles
	_add_toys(L, p, seed_value)
	_add_front(L, p, seed_value)
	_add_lights(L, p)
	_add_parking(L, p, seed_value)
	var occ := []
	for g in gondolas:
		occ.append({"id": g["id"], "rect": g["rect"], "h": g["h"]})
	for c in L["checkouts"]:
		occ.append({"id": c["id"], "rect": c["rect"], "h": 1.1})
	L["occluders"] = occ
	_add_anchors(L, p)
	return L


## The toy section: a stretch of one shelf face in the toy aisle, stocked with
## small robots. "toy_hero" is the one at eye level nearest the aisle front.
static func _add_toys(L: Dictionary, p: Dictionary, seed_value: int) -> void:
	L["toys"] = []
	var k: int = p["toy_aisle"]
	if k <= 0:
		return
	var face: Dictionary = {}
	for s in L["shelves"]:
		if s["aisle"] == k and s["facing"][0] < 0:   # the gondola on the aisle's right
			face = s
	face["category"] = "toys_section"
	var z_start := float(p["front_zone"]) * -1.0 - 1.4
	var z_end := z_start - 3.6
	face["toy_span"] = [z_end, z_start]
	var r := _rng(seed_value, "toys")
	var levels := _shelf_levels(float(p["shelf_h"]))
	var toys := []
	var idx := 0
	for li in range(1, levels.size()):
		var z := z_start - 0.2
		while z > z_end + 0.15:
			var hero := li == 2 and idx > 0 and toys.filter(func(t): return t["hero"]).is_empty()
			toys.append({"id": "toy_hero" if hero else "toy_%d" % idx,
				"pos": _p3(Vector3(float(face["x"]) + 0.22, float(levels[li]), z)),  # on the board, inside the face
				"facing": _p3(Vector3(-1, 0, 0)), "color": TOY_COLORS[r.randi_range(0, TOY_COLORS.size() - 1)],
				"scale": r.randf_range(0.9, 1.1), "hero": hero})
			idx += 1
			z -= r.randf_range(0.36, 0.46)
	L["toys"] = toys


## Shelf board heights for a gondola of height h (bottom shelf near the floor).
static func _shelf_levels(h: float) -> Array:
	var out := []
	for i in SHELF_LEVELS:
		out.append(snappedf(0.14 + i * (h - 0.45) / (SHELF_LEVELS - 1), 0.001))
	return out


static func _add_front(L: Dictionary, p: Dictionary, seed_value: int) -> void:
	var store: Array = L["store"]["rect"]
	var half_w := float(store[2])
	# Checkouts left of the entrance, perpendicular to the storefront.
	var checkouts := []
	var count: int = p["checkouts"]
	var x := -half_w + 3.0
	for i in count:
		var z0 := -float(p["front_zone"]) * 0.32 - 3.2
		checkouts.append({"id": "checkout_%d" % (i + 1), "rect": [x - 0.45, z0, x + 0.45, z0 + 3.2],
			"cashier": _p3(Vector3(x - 1.0, 0, z0 + 1.0))})
		x += 3.1
		if x > -3.0:
			break
	L["checkouts"] = checkouts
	L["entrance"] = {"x": 0.0, "width": 3.6}
	L["exit_signs"] = [{"id": "exit_sign_0", "pos": _p3(Vector3(0, 3.0, -0.25))},
		{"id": "exit_sign_1", "pos": _p3(Vector3(float(store[0]) + 0.3, 2.6, float(store[1]) + 4.0))}]


static func _add_lights(L: Dictionary, p: Dictionary) -> void:
	var store: Array = L["store"]["rect"]
	var fixtures := []
	var power := String(p["power"])
	var idx := 0
	var xs := []
	for a in L["aisles"]:
		xs.append(float(a["x"]))
	var z := -2.0
	while z > float(store[1]) + 1.5:
		for x in xs:
			var on := power == "on" or (power == "night" and idx % 3 == 0) or (power == "emergency" and idx % 9 == 0)
			fixtures.append({"id": "fixture_%d" % idx, "pos": _p3(Vector3(x, STORE_H - 0.15, z)), "on": on})
			idx += 1
		z -= 4.0
	L["fixtures"] = fixtures
	L["freezers"] = []
	var n := int((float(store[2]) - float(store[0]) - 4.0) / 2.6)
	for i in n:
		var fx := float(store[0]) + 2.0 + 1.3 + i * 2.6
		L["freezers"].append({"id": "freezer_%d" % i, "rect": [fx - 1.25, float(store[1]), fx + 1.25, float(store[1]) + 0.9],
			"on": power != "off"})


static func _add_parking(L: Dictionary, p: Dictionary, seed_value: int) -> void:
	var store: Array = L["store"]["rect"]
	var depth := float(p["parking_depth"])
	var w := float(store[2]) + 10.0
	L["parking"] = {"rect": [-w, 0.0, w, depth]}
	var lamps := []
	var i := 0
	for lx in [-w * 0.55, w * 0.55]:
		for lz in [depth * 0.35, depth * 0.8]:
			lamps.append({"id": "lamp_%d" % i, "pos": _p3(Vector3(lx, 0, lz))})
			i += 1
	L["lamps"] = lamps
	var r := _rng(seed_value, "cars")
	var cars := []
	var rows := [depth * 0.45, depth * 0.62]
	for ri in rows.size():
		var cx := -w + 3.0
		while cx < w - 3.0:
			if absf(cx) > 4.0 and r.randf() < float(p["car_density"]):
				cars.append({"id": "car_%d" % cars.size(), "pos": _p3(Vector3(cx, 0, float(rows[ri]))),
					"yaw": (0.0 if ri == 0 else PI) + r.randf_range(-0.05, 0.05),
					"color": CAR_COLORS[r.randi_range(0, CAR_COLORS.size() - 1)], "model_pick": r.randi()})
			cx += 2.9
	L["cars"] = cars


static func _add_anchors(L: Dictionary, p: Dictionary) -> void:
	var store: Array = L["store"]["rect"]
	var A := {}
	var into := Vector3(0, 0, -1)
	var out := Vector3(0, 0, 1)
	var cz := (float(store[1]) + 0.0) / 2.0
	A["store_center"] = _anchor(Vector3(0, 0, cz), into)
	A["entrance"] = _anchor(Vector3(0, 0, -1.2), into)
	A["storefront"] = _anchor(Vector3(0, 0, 1.2), out)
	A["storefront.left"] = _anchor(Vector3(float(store[0]) * 0.55, 0, 1.2), out)
	A["storefront.right"] = _anchor(Vector3(float(store[2]) * 0.55, 0, 1.2), out)
	A["storefront.inside"] = _anchor(Vector3(0, 0, -0.8), out)
	A["parking_lot"] = _anchor(Vector3(0, 0, float(p["parking_depth"]) * 0.5), into)
	var fz := -float(p["front_zone"]) + 1.4
	A["front_aisle"] = _anchor(Vector3(0, 0, fz), Vector3(1, 0, 0))
	A["front_aisle.start"] = _anchor(Vector3(float(store[0]) + 1.5, 0, fz), Vector3(1, 0, 0))
	A["front_aisle.end"] = _anchor(Vector3(float(store[2]) - 1.5, 0, fz), Vector3(-1, 0, 0))
	var bz := float(store[1]) + 2.4
	A["back_aisle"] = _anchor(Vector3(0, 0, bz), Vector3(1, 0, 0))
	A["freezers"] = _anchor(Vector3(0, 0, float(store[1]) + 1.6), out)
	for a in L["aisles"]:
		var ax := float(a["x"])
		var id := String(a["id"])
		A[id] = _anchor(Vector3(ax, 0, (float(a["z0"]) + float(a["z1"])) / 2.0), into)
		A[id + ".start"] = _anchor(Vector3(ax, 0, float(a["z0"]) + 0.6), into)
		A[id + ".mid"] = _anchor(Vector3(ax, 0, (float(a["z0"]) + float(a["z1"])) / 2.0), into)
		A[id + ".end"] = _anchor(Vector3(ax, 0, float(a["z1"]) - 0.6), out)
		A[id + ".front"] = _anchor(Vector3(ax, 0, fz), into)  # in the front aisle, facing into aisle id
	for c in L["checkouts"]:
		var r: Array = c["rect"]
		A[String(c["id"])] = _anchor(Vector3((float(r[0]) + float(r[2])) / 2.0 - 0.9, 0, (float(r[1]) + float(r[3])) / 2.0), out)
	for t in L["toys"]:
		if t["hero"]:
			var tp := Vector3(t["pos"][0], t["pos"][1], t["pos"][2])
			A["toy_hero"] = _anchor(tp, Vector3(-1, 0, 0))
			# Where you stand to reach it: in the aisle, facing the shelf.
			A["toys"] = _anchor(Vector3(tp.x - 0.85, 0, tp.z - 0.4), Vector3(1, 0, 0))
			A["toys.shelf"] = _anchor(Vector3(tp.x - 0.25, 1.1, tp.z - 1.4), Vector3(-1, 0, 0))
	L["anchors"] = A


## Floor height where feet stand: store floor 0.04, parking lot 0.02.
static func ground_height(L: Dictionary, x: float, z: float) -> float:
	var s: Array = L["store"]["rect"]
	if x >= float(s[0]) and x <= float(s[2]) and z >= float(s[1]) and z <= float(s[3]):
		return 0.04
	return 0.02


static func manifest(L: Dictionary) -> Dictionary:
	var aisles := []
	for a in L["aisles"]:
		aisles.append({"id": a["id"], "title": a["title"], "anchors": [a["id"] + ".start", a["id"] + ".mid", a["id"] + ".end", a["id"] + ".front"]})
	var checkouts := []
	for c in L["checkouts"]:
		checkouts.append(c["id"])
	return {
		"generator": "supermarket",
		"seed": L["seed"],
		"store": L["store"],
		"anchors": L["anchors"].keys(),
		"aisles": aisles,
		"checkouts": checkouts,
		"switchable": {"toys": "all toys (eyes)", "toy_hero": "the toy at eye level, aisle front",
			"fixtures": "ceiling lights", "freezers": "freezer cases"},
		"counts": {"aisles": L["aisles"].size(), "toys": L["toys"].size(), "fixtures": L["fixtures"].size(),
			"fixtures_on": L["fixtures"].filter(func(f): return f["on"]).size(), "cars": L["cars"].size()},
	}
