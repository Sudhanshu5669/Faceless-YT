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
##
## Fixtures come from a kit (library/kits/<id>.json): with a kit, gondolas are
## tiled from the kit's rack model, so its size, shelf heights and segment
## length shape the layout (aisle_length rounds to whole segments). The kit
## "primitive" builds procedural boxes from the shelf_d / shelf_h params.
extends RefCounted

const KitDB = preload("res://scripts/world/kit_db.gd")

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
	"kit": "supermarket",
	"clutter": 0.5,
}

const LIMITS := {
	"aisles": [2, 14], "aisle_length": [8.0, 40.0], "aisle_w": [1.6, 4.0], "shelf_d": [0.6, 1.6],
	"shelf_h": [1.4, 2.6], "front_zone": [6.0, 16.0], "back_zone": [3.0, 8.0], "side_zone": [2.0, 6.0],
	"checkouts": [1, 10], "parking_depth": [12.0, 80.0], "car_density": [0.0, 1.0], "toy_aisle": [0, 14],
	"clutter": [0.0, 1.0],
}
## Kit roles the supermarket needs (all of them, so a kit is never half-used).
const KIT_ROLES := ["gondola", "wall_shelf", "fridge", "checkout", "clutter", "recolor"]
const CLUTTER_KINDS := ["cart", "basket", "box", "trash"]
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
		if k == "kit":
			if typeof(p[k]) != TYPE_STRING:
				e.append("supermarket: param 'kit' must be a string")
			elif p[k] != "primitive":
				var ke := KitDB.validate_kit(p[k])
				e.append_array(ke)
				if ke.is_empty():
					for role in KIT_ROLES:
						if not KitDB.kit(p[k]).has(role):
							e.append("supermarket: kit '%s' has no '%s' role" % [p[k], role])
					for kind in CLUTTER_KINDS:
						if not KitDB.kit(p[k]).get("clutter", {}).has(kind):
							e.append("supermarket: kit '%s' has no clutter '%s'" % [p[k], kind])
			continue
		if LIMITS.has(k):
			var lim: Array = LIMITS[k]
			if not (typeof(p[k]) in [TYPE_INT, TYPE_FLOAT]) or float(p[k]) < float(lim[0]) or float(p[k]) > float(lim[1]):
				e.append("supermarket: %s must be a number in [%s, %s]" % [k, lim[0], lim[1]])
	if p.has("power") and not (String(p["power"]) in POWER):
		e.append("supermarket: power must be one of %s" % [POWER])
	if String(p.get("kit", DEFAULTS["kit"])) != "primitive":
		for k in ["shelf_d", "shelf_h"]:
			if p.has(k):
				e.append("supermarket: %s only applies to kit 'primitive' (the kit's gondola model sets it)" % k)
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
	var gs := _gondola_spec(p)
	var sd: float = gs["depth"]
	var aw: float = p["aisle_w"]
	var pitch := sd + aw
	var total := (n + 1) * sd + n * aw
	var half_w := total / 2.0 + float(p["side_zone"])
	var z_front_aisle := -float(p["front_zone"])          # where aisles begin
	var aisle_len := float(p["aisle_length"])
	var nseg := 1
	if float(gs["seg"]) > 0.0:
		nseg = maxi(1, roundi(aisle_len / float(gs["seg"])))
		aisle_len = snappedf(nseg * float(gs["seg"]), 0.001)
	var z_aisle_end := z_front_aisle - aisle_len
	var z_back := z_aisle_end - float(p["back_zone"])
	var L := {
		"generator": "supermarket", "seed": seed_value, "params": p,
		"store": {"rect": [-half_w, z_back, half_w, 0.0], "height": STORE_H},
		"bounds": [-half_w - 12.0, z_back - 4.0, half_w + 12.0, float(p["parking_depth"])],
		"shelving": gs,
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
		var segs := []
		var spans := []
		if float(gs["seg"]) > 0.0:
			var half_shelf := float(gs["shelf_len"]) / 2.0 - 0.02
			for si in nseg:
				var zc := snappedf(z_front_aisle - (si + 0.5) * float(gs["seg"]), 0.001)
				segs.append(zc)
				spans.append([snappedf(zc - half_shelf, 0.001), snappedf(zc + half_shelf, 0.001)])
		else:
			spans.append([z_aisle_end + 0.05, z_front_aisle - 0.05])
		gondolas.append({"id": "gondola_%d" % i, "rect": rect, "h": gs["h"], "segments": segs})
		# Left face (-X) serves aisle i, right face (+X) serves aisle i+1.
		for side in [-1, 1]:
			var aisle := i if side < 0 else i + 1
			if aisle < 1 or aisle > n:
				continue
			shelves.append({"id": "shelf_%d_%s" % [i, "w" if side < 0 else "e"], "gondola": i, "aisle": aisle,
				"x": snappedf(gx + side * float(gs["reach"]), 0.001), "spans": spans, "levels": gs["levels"],
				"depth": float(gs["reach"]) - 0.03, "facing": [side, 0],
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
	_add_wall_shelves(L, p, cr, z_front_aisle, z_aisle_end)
	_add_toys(L, p, seed_value)
	_add_front(L, p, seed_value)
	_add_lights(L, p)
	_add_parking(L, p, seed_value)
	_add_clutter(L, p, seed_value)
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
	# Toys stand on every board above the floor; the hero on the one nearest 1.2 m.
	var levels := toy_levels(face)
	var hero_y := float(levels[0])
	for y in levels:
		if absf(float(y) - 1.2) < absf(hero_y - 1.2):
			hero_y = float(y)
	var toys := []
	var idx := 0
	for y in levels:
		var z := z_start - 0.2
		while z > z_end + 0.15:
			var col: String = TOY_COLORS[r.randi_range(0, TOY_COLORS.size() - 1)]
			var sc := r.randf_range(0.9, 1.1)
			if in_spans(face["spans"], z, 0.12):
				var hero := float(y) == hero_y and idx > 0 and toys.filter(func(t): return t["hero"]).is_empty()
				toys.append({"id": "toy_hero" if hero else "toy_%d" % idx,
					"pos": _p3(Vector3(float(face["x"]) + 0.22, float(y), z)),  # on the board, inside the face
					"facing": _p3(Vector3(-1, 0, 0)), "color": col, "scale": sc, "hero": hero})
				idx += 1
			z -= r.randf_range(0.36, 0.46)
	L["toys"] = toys


## Boards of a shelf face that toys stand on (not the floor-level one).
static func toy_levels(face: Dictionary) -> Array:
	return face["levels"].filter(func(y): return float(y) >= 0.3)


## Is z inside one of the shelf runs [[z0, z1], ...], at least margin from its ends?
static func in_spans(spans: Array, z: float, margin: float) -> bool:
	for s in spans:
		if z >= float(s[0]) + margin and z <= float(s[1]) - margin:
			return true
	return false


## Gondola geometry: from the kit's rack model, or shelf_d / shelf_h for "primitive".
## levels are board-top heights above the floor; reach is centre-to-board-edge;
## seg is the tiled segment length (0 = one continuous run).
static func _gondola_spec(p: Dictionary) -> Dictionary:
	if String(p["kit"]) == "primitive":
		var lv := []
		for y in _shelf_levels(float(p["shelf_h"])):
			lv.append(snappedf(float(y) + 0.0125, 0.001))
		return {"kit": "primitive", "seg": 0.0, "depth": float(p["shelf_d"]), "h": float(p["shelf_h"]), "levels": lv,
			"reach": float(p["shelf_d"]) / 2.0, "shelf_len": 0.0}
	var g: Dictionary = KitDB.kit(p["kit"])["gondola"]
	var sz := KitDB.size(g["model"])
	return {"kit": p["kit"], "seg": snappedf(sz.x, 0.001), "depth": snappedf(sz.z, 0.001), "h": snappedf(sz.y, 0.001),
		"levels": g["levels"], "reach": float(g["reach"]), "shelf_len": float(g["shelf_len"])}


## Shelving units along the side walls, from the front aisle to the back aisle,
## backs against the wall, facing into the store. Their faces are stocked like
## gondola faces (aisle 0 = not in a numbered aisle).
static func _add_wall_shelves(L: Dictionary, p: Dictionary, cr: RandomNumberGenerator, z0: float, z1: float) -> void:
	var store: Array = L["store"]["rect"]
	var kit := String(p["kit"])
	var seg := 3.0
	var half_d := 0.3
	var front := 0.28
	var depth := 0.55
	var levels := [0.06, 0.6, 1.14, 1.68]
	var shelf_len := 2.9
	var h := 2.0
	if kit != "primitive":
		var w: Dictionary = KitDB.kit(kit)["wall_shelf"]
		var sz := KitDB.size(w["model"])
		seg = snappedf(sz.x, 0.001)
		half_d = snappedf(sz.z / 2.0, 0.001)
		h = snappedf(sz.y, 0.001)
		front = float(w["front"])
		depth = float(w["depth"])
		levels = w["levels"]
		shelf_len = float(w["shelf_len"])
	var units := []
	var count := int((z0 - z1) / seg)
	for side in [-1, 1]:
		var wall_x := float(store[0]) if side < 0 else float(store[2])
		var cx: float = wall_x - side * half_d
		var tag := "w" if side < 0 else "e"
		var spans := []
		for i in count:
			var zc := snappedf(z0 - (i + 0.5) * seg, 0.001)
			units.append({"id": "wall_shelf_%s_%d" % [tag, i], "pos": [snappedf(cx, 0.001), 0.0, zc], "facing": [-side, 0]})
			spans.append([snappedf(zc - shelf_len / 2.0 + 0.02, 0.001), snappedf(zc + shelf_len / 2.0 - 0.02, 0.001)])
		L["shelves"].append({"id": "wall_%s" % tag, "gondola": -1, "aisle": 0,
			"x": snappedf(cx - side * front, 0.001), "spans": spans, "levels": levels,
			"depth": depth, "facing": [-side, 0], "category": "household" if side < 0 else "cleaning", "seed": cr.randi()})
	L["wall_shelves"] = {"units": units, "seg": seg, "half_d": half_d, "h": h}


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
	var fd := 0.9
	if String(p["kit"]) != "primitive":
		fd = snappedf(KitDB.size(KitDB.kit(p["kit"])["fridge"]["model"]).z, 0.001)
	var n := int((float(store[2]) - float(store[0]) - 4.0) / 2.6)
	for i in n:
		var fx := float(store[0]) + 2.0 + 1.3 + i * 2.6
		L["freezers"].append({"id": "freezer_%d" % i, "rect": [fx - 1.25, float(store[1]), fx + 1.25, float(store[1]) + fd],
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


## Signs of a store left in a hurry: a cart corral by the entrance, trash bags
## outside, and (scaled by "clutter") abandoned carts, baskets and boxes in the
## aisles and the back aisle. The toy aisle and the front aisle stay clear:
## that's where the action is staged.
static func _add_clutter(L: Dictionary, p: Dictionary, seed_value: int) -> void:
	var r := _rng(seed_value, "clutter")
	var store: Array = L["store"]["rect"]
	var items := []
	var amount := float(p["clutter"])
	# Cart corral: nested carts just inside the glass, right of the entrance.
	var corral := int(round(2 + 4 * amount))
	for i in corral:
		items.append({"kind": "cart", "pos": _p3(Vector3(3.2 + i * 0.32, 0, -1.3)), "yaw": 0.0})
	# Trash bags outside, against the facade, beyond the horde.
	if amount > 0.0:
		items.append({"kind": "trash", "pos": _p3(Vector3(float(store[2]) - 2.6, 0, 1.0)), "yaw": snappedf(PI + r.randf_range(-0.1, 0.1), 0.001)})
	var aw := float(p["aisle_w"])
	for a in L["aisles"]:
		if int(a["number"]) == int(p["toy_aisle"]):
			continue
		var count := int(floor(amount * 2.0 + r.randf()))
		for i in count:
			var kind: String = ["cart", "basket", "box", "box"][r.randi_range(0, 3)]
			var side := -1.0 if r.randf() < 0.5 else 1.0
			var x := float(a["x"]) + side * (aw / 2.0 - (0.55 if kind == "cart" else 0.35))
			var z := r.randf_range(float(a["z1"]) + 2.0, float(a["z0"]) - 3.0)
			items.append({"kind": kind, "pos": _p3(Vector3(x, 0, z)), "yaw": snappedf(r.randf_range(-0.4, 0.4) + (PI if r.randf() < 0.5 else 0.0) + (PI / 2.0 if kind == "cart" else 0.0), 0.001)})
	# The back aisle: a few boxes stacked by the freezers.
	var bz := float(store[1]) + 2.9
	for i in int(round(amount * 6)):
		var x := r.randf_range(float(store[0]) + 3.0, float(store[2]) - 3.0)
		items.append({"kind": "box", "pos": _p3(Vector3(x, 0, bz + r.randf_range(-0.3, 0.3))), "yaw": snappedf(r.randf_range(-PI, PI), 0.001)})
	for i in items.size():
		items[i]["id"] = "%s_%d" % [items[i]["kind"], i]
	L["clutter"] = items


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
			"fixtures_on": L["fixtures"].filter(func(f): return f["on"]).size(), "cars": L["cars"].size(),
			"clutter": L["clutter"].size()},
		"kit": L["params"]["kit"],
	}
