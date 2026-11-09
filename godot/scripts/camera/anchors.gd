## Named places in a set, resolved to a position and a facing direction.
##
##   town_center, main_street_mid, town_entrance_east ...   global anchors
##   house_4  house_4.front_door  .lawn .driveway .backyard .curb .roof
##   street_h1  street_h1.start  .mid  .end
##   int_1_1                        intersections
##   light_12  light_12.lamp        streetlights
##   vacant_0                       vacant lots
##
## "forward" is the anchor's natural facing: out of a house toward its street,
## along a street from start to end, from a streetlight over the road.
## Offsets are written [right, up, forward] in that frame.
extends RefCounted


static func _v(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])


static func _find(list: Array, id: String) -> Dictionary:
	for item in list:
		if item["id"] == id:
			return item
	return {}


## Returns {"pos": Vector3, "forward": Vector3} or {"error": String}.
static func resolve(L: Dictionary, ref: String) -> Dictionary:
	# Actors (posed for the current moment) are anchors too: "you", "you.head".
	var actor_anchors: Dictionary = L.get("actor_anchors", {})
	if actor_anchors.has(ref):
		return actor_anchors[ref]
	var parts := ref.split(".")
	var entity := parts[0]
	var sub := parts[1] if parts.size() > 1 else ""
	var anchors: Dictionary = L["anchors"]

	if anchors.has(entity) and typeof(anchors[entity]) == TYPE_ARRAY:
		var fwd := Vector3(0, 0, 1)
		if entity.begins_with("main_street"):
			fwd = Vector3(1, 0, 0)
		elif entity == "town_entrance_east":
			fwd = Vector3(-1, 0, 0)
		elif entity == "town_entrance_west":
			fwd = Vector3(1, 0, 0)
		return {"pos": _v(anchors[entity]), "forward": fwd}

	if entity.begins_with("house_"):
		var h := _find(L["houses"], entity)
		if h.is_empty():
			return {"error": "no house '%s'" % entity}
		var fwd := Vector3(0, 0, float(h["facing"]))
		var base := _v(h["pos"])
		match sub:
			"", "center":
				return {"pos": base + Vector3(0, float(h["wall_h"]) * 0.5, 0), "forward": fwd}
			"roof":
				return {"pos": base + Vector3(0, float(h["wall_h"]) + float(h["roof"]["h"]), 0), "forward": fwd}
		if h["anchors"].has(sub):
			return {"pos": _v(h["anchors"][sub]), "forward": fwd}
		return {"error": "house anchor '%s' unknown (use center, roof, %s)" % [sub, ", ".join(PackedStringArray(h["anchors"].keys()))]}

	if entity.begins_with("street_"):
		var s := _find(L["streets"], entity)
		if s.is_empty():
			return {"error": "no street '%s'" % entity}
		var a := _v(s["from"])
		var b := _v(s["to"])
		var fwd := (b - a).normalized()
		match sub:
			"start":
				return {"pos": a, "forward": fwd}
			"end":
				return {"pos": b, "forward": -fwd}
			"", "mid":
				return {"pos": (a + b) / 2.0, "forward": fwd}
		return {"error": "street anchor '%s' unknown (use start, mid, end)" % sub}

	if entity.begins_with("int_"):
		var it := _find(L["intersections"], entity)
		if it.is_empty():
			return {"error": "no intersection '%s'" % entity}
		return {"pos": _v(it["pos"]), "forward": Vector3(1, 0, 0)}

	if entity.begins_with("light_"):
		var l := _find(L["streetlights"], entity)
		if l.is_empty():
			return {"error": "no streetlight '%s'" % entity}
		var d := Vector3(l["dir"][0], 0, l["dir"][1])
		var p := _v(l["pos"])
		if sub == "lamp":
			p += Vector3(0, 5.8, 0) + d * 1.75
		return {"pos": p, "forward": d}

	if entity.begins_with("vacant_"):
		var v := _find(L["vacant_lots"], entity)
		if v.is_empty():
			return {"error": "no vacant lot '%s'" % entity}
		var s := _find(L["streets"], v["street"])
		var c := _v(v["center"])
		var fwd := Vector3(0, 0, signf(float(s["from"][2]) - c.z)) if not s.is_empty() else Vector3(0, 0, 1)
		return {"pos": c, "forward": fwd}

	return {"error": "unknown anchor '%s' (try town_center, house_N.front_door, street_h1.mid, int_1_1, light_N, vacant_N)" % ref}


## Applies an [right, up, forward] offset in the anchor's frame.
static func offset_point(anchor: Dictionary, offset: Array) -> Vector3:
	var fwd: Vector3 = anchor["forward"]
	var right := fwd.cross(Vector3.UP).normalized()
	return anchor["pos"] + right * float(offset[0]) + Vector3.UP * float(offset[1]) + fwd * float(offset[2])
