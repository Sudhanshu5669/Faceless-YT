## Stage: a row of small neon diorama "bays", the toon explainer style's sets
## (a reference video uses ~20 tiny night sets: an office, a club booth, a
## war room, a product pedestal...). Each bay is a floor, a back wall (or an
## open skyline), neon tubes / rings, coloured lights and an optional pedestal
## (glowing disc, a pile of oil drums, a pile of cash, a crate stack).
## Bays sit far apart in a dark void so a camera only ever sees one.
##
##   "set": {"generator": "stage", "seed": 1, "params": {"bays": [
##     {"id": "empire", "floor": "tiles", "wall": "skyline", "pedestal": {"style": "drums"}},
##     {"id": "tribute", "floor": "wood", "wall": "panels", "neon": ["strip"]}
##   ]}}
##
## Anchors per bay (forward = toward the open front): <id>, <id>.left,
## <id>.right, <id>.back, <id>.front, <id>.wall (on the back wall, 2.2 m up),
## <id>.pedestal (top of the pedestal), <id>.sky (5 m above the centre).
extends RefCounted

const FLOORS := ["checker", "tiles", "grid", "wood", "plain", "carpet"]
const WALLS := ["tiles", "panels", "plain", "grid", "brick", "skyline", "none"]
const NEONS := ["ring", "tubes", "strip", "arch", "frame"]
const PEDESTALS := ["neon", "drums", "cash", "crates", "plain"]
const BAY_KEYS := ["id", "floor", "floor_colors", "wall", "wall_color", "neon", "neon_colors", "size",
	"pedestal", "sides", "light", "note"]
const PEDESTAL_KEYS := ["style", "height", "radius", "color"]
const SPACING := 60.0
const WALL_H := 6.0

## Colour schemes the director can lean on (picked per bay by index when not given).
const FLOOR_SCHEMES := [["#3b2a7a", "#2a1d5c"], ["#1d2b6b", "#16204f"], ["#5a2a6e", "#3d1d4d"], ["#1f4a5c", "#173845"]]
const WALL_SCHEMES := ["#2b2f8f", "#3a1f6e", "#1f2f6e", "#4a1f5a"]
const NEON_SCHEMES := [["#5fe3ff", "#ff4fd8"], ["#ff4fd8", "#ffd84a"], ["#7cff6b", "#5fe3ff"], ["#ffd84a", "#ff6a3a"]]


static func validate_params(p: Dictionary) -> Array:
	var e := []
	for k in p:
		if k != "bays":
			e.append("stage: unknown param '%s' (known: bays)" % k)
	var bays = p.get("bays")
	if typeof(bays) != TYPE_ARRAY or bays.is_empty():
		return e + ["stage: params.bays must be a non-empty array of bays"]
	var ids := {}
	for i in bays.size():
		var b = bays[i]
		var w := "stage bays[%d]" % i
		if typeof(b) != TYPE_DICTIONARY:
			e.append(w + " must be an object")
			continue
		for k in b:
			if not (k in BAY_KEYS):
				e.append("%s: unknown key '%s' (known: %s)" % [w, k, ", ".join(PackedStringArray(BAY_KEYS))])
		var id := String(b.get("id", ""))
		if id == "" or id.contains(".") or ids.has(id):
			e.append(w + ": needs a unique 'id' without dots")
		ids[id] = true
		if b.has("floor") and not (String(b["floor"]) in FLOORS):
			e.append("%s: floor '%s' (known: %s)" % [w, b["floor"], ", ".join(PackedStringArray(FLOORS))])
		if b.has("wall") and not (String(b["wall"]) in WALLS):
			e.append("%s: wall '%s' (known: %s)" % [w, b["wall"], ", ".join(PackedStringArray(WALLS))])
		for n in b.get("neon", []):
			if not (String(n) in NEONS):
				e.append("%s: neon '%s' (known: %s)" % [w, n, ", ".join(PackedStringArray(NEONS))])
		for k in ["floor_colors", "neon_colors"]:
			for c in b.get(k, []):
				if not Color.html_is_valid(String(c)):
					e.append("%s: %s has a bad colour '%s'" % [w, k, c])
		if b.has("wall_color") and not Color.html_is_valid(String(b["wall_color"])):
			e.append(w + ": wall_color is not a hex colour")
		if b.has("size"):
			var s = b["size"]
			if typeof(s) != TYPE_ARRAY or s.size() != 2 or float(s[0]) < 3 or float(s[1]) < 3 or float(s[0]) > 40 or float(s[1]) > 40:
				e.append(w + ": size must be [width, depth], 3..40 m")
		if b.has("pedestal"):
			var pd = b["pedestal"]
			if typeof(pd) != TYPE_DICTIONARY:
				e.append(w + ": pedestal must be an object")
			else:
				for k in pd:
					if not (k in PEDESTAL_KEYS):
						e.append("%s: pedestal has unknown key '%s'" % [w, k])
				if not (String(pd.get("style", "neon")) in PEDESTALS):
					e.append("%s: pedestal style '%s' (known: %s)" % [w, pd.get("style"), ", ".join(PackedStringArray(PEDESTALS))])
	return e


static func _p3(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]


static func _anchor(pos: Vector3, fwd: Vector3) -> Dictionary:
	return {"pos": _p3(pos), "forward": _p3(fwd.normalized())}


static func generate(params: Dictionary, seed_value: int) -> Dictionary:
	var bays := []
	var A := {}
	var i := 0
	for b in params["bays"]:
		var size: Array = b.get("size", [9.0, 7.0])
		var w := float(size[0])
		var d := float(size[1])
		var c := Vector3(i * SPACING, 0, 0)
		var ped: Dictionary = b.get("pedestal", {})
		var bay := {
			"id": String(b["id"]), "center": _p3(c), "size": [w, d],
			"floor": String(b.get("floor", "checker")),
			"floor_colors": b.get("floor_colors", FLOOR_SCHEMES[i % FLOOR_SCHEMES.size()]),
			"wall": String(b.get("wall", "tiles")),
			"wall_color": String(b.get("wall_color", WALL_SCHEMES[i % WALL_SCHEMES.size()])),
			"neon": b.get("neon", ["tubes"]),
			"neon_colors": b.get("neon_colors", NEON_SCHEMES[i % NEON_SCHEMES.size()]),
			"sides": bool(b.get("sides", false)),
			"light": String(b.get("light", "#fff1dc")),
			"pedestal": {} if ped.is_empty() else {
				"style": String(ped.get("style", "neon")),
				"height": float(ped.get("height", 0.35 if String(ped.get("style", "neon")) in ["neon", "plain"] else 1.2)),
				"radius": float(ped.get("radius", 1.1)),
				"color": String(ped.get("color", "#2a2f6e")),
			},
		}
		bays.append(bay)
		var id := bay["id"] as String
		var fwd := Vector3(0, 0, 1)
		A[id] = _anchor(c, fwd)
		A[id + ".left"] = _anchor(c + Vector3(-w * 0.25, 0, 0), fwd)
		A[id + ".right"] = _anchor(c + Vector3(w * 0.25, 0, 0), fwd)
		A[id + ".back"] = _anchor(c + Vector3(0, 0, -d * 0.5 + 1.0), fwd)
		A[id + ".front"] = _anchor(c + Vector3(0, 0, d * 0.5 - 0.8), fwd)
		A[id + ".wall"] = _anchor(c + Vector3(0, 2.2, -d * 0.5 + 0.06), fwd)
		A[id + ".sky"] = _anchor(c + Vector3(0, 5.0, 0), fwd)
		if not bay["pedestal"].is_empty():
			A[id + ".pedestal"] = _anchor(c + Vector3(0, float(bay["pedestal"]["height"]), 0), fwd)
		i += 1
	return {"generator": "stage", "seed": seed_value, "params": params, "bays": bays, "anchors": A}


## Feet stand on the floor, or on top of a bay's pedestal.
static func ground_height(L: Dictionary, x: float, z: float) -> float:
	for b in L["bays"]:
		var ped: Dictionary = b["pedestal"]
		if ped.is_empty():
			continue
		var c: Array = b["center"]
		if Vector2(x - float(c[0]), z - float(c[2])).length() <= float(ped["radius"]) * 0.92:
			return float(ped["height"])
	return 0.0


static func manifest(L: Dictionary) -> Dictionary:
	var bays := []
	for b in L["bays"]:
		var names := []
		for k in L["anchors"]:
			if String(k) == b["id"] or String(k).begins_with(String(b["id"]) + "."):
				names.append(k)
		bays.append({"id": b["id"], "floor": b["floor"], "wall": b["wall"], "neon": b["neon"],
			"pedestal": b["pedestal"].get("style", "none") if not b["pedestal"].is_empty() else "none",
			"size": b["size"], "anchors": names})
	return {"generator": "stage", "seed": L["seed"], "bays": bays, "anchors": L["anchors"].keys()}
