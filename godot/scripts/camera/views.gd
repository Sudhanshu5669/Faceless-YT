## Named camera views of a town set. These are the first entries in the shot
## vocabulary: a director asks for "house:house_4", never for coordinates.
##   aerial        high establishing shot down the main street
##   street        eye level, looking down the main street
##   house[:id]    across the street from a house (default: most central house on main street)
##   intersection  low angle across the town-center intersection
##   entrance      on the road outside town, looking in
extends RefCounted

const NAMES := ["aerial", "street", "house", "intersection", "entrance"]


static func _v(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])


static func _shot(pos: Vector3, target: Vector3, fov: float) -> Dictionary:
	return {"transform": Transform3D(Basis(), pos).looking_at(target, Vector3.UP), "fov": fov}


## Same horizontal direction as from->to, tilted up by deg degrees.
static func _pitched(from: Vector3, to: Vector3, deg: float) -> Vector3:
	var flat := Vector3(to.x - from.x, 0, to.z - from.z)
	return from + flat + Vector3(0, flat.length() * tan(deg_to_rad(deg)), 0)


## Camera position and look-at target for the establishing shot of a house.
static func house_camera(L: Dictionary, h: Dictionary) -> Array:
	var rw: float = L["params"]["road_w"]
	var facing := Vector3(0, 0, float(h["facing"]))
	var curb := _v(h["anchors"]["curb"])
	var pos := curb + facing * (rw * 0.55) + Vector3(2.0, 1.5, 0)
	var roof_top := float(h["wall_h"]) + float(h["roof"]["h"])
	var target := _v(h["pos"]) + Vector3(0, roof_top * 0.62, 0)
	return [pos, target]


## How many trees stand between the camera and the house (2D line-of-sight test).
static func occluders(L: Dictionary, from: Vector3, to: Vector3) -> int:
	var a := Vector2(from.x, from.z)
	var b := Vector2(to.x, to.z)
	var n := 0
	for t in L["trees"]:
		if t["ground"] != "grass":
			continue
		var q := Vector2(t["pos"][0], t["pos"][2])
		var closest := Geometry2D.get_closest_point_to_segment(q, a, b)
		if q.distance_to(closest) < 2.2 * float(t["scale"]):
			n += 1
	return n


## With an id, returns that house. Without, the most central house on the
## main street that has a clear view from the road.
static func find_house(L: Dictionary, house_id: String) -> Dictionary:
	if house_id != "":
		for h in L["houses"]:
			if h["id"] == house_id:
				return h
		return {}
	var best: Dictionary = {}
	var best_score := INF
	for h in L["houses"]:
		var score := absf(float(h["pos"][0]))
		if h["street"] != L["main_street"]:
			score += 1000.0
		var cam := house_camera(L, h)
		score += 60.0 * occluders(L, cam[0], cam[1])
		if score < best_score:
			best_score = score
			best = h
	return best


## Returns {"transform": Transform3D, "fov": float} or {"error": String}.
static func frame(view: String, L: Dictionary) -> Dictionary:
	if String(L.get("generator", "town")) != "town":
		return {"error": "named views (%s) exist only for towns; frame shots on anchors (see manifest.json)" % ", ".join(PackedStringArray(NAMES))}
	var parts := view.split(":")
	var kind := parts[0]
	var arg := parts[1] if parts.size() > 1 else ""
	var b: Array = L["bounds"]
	var p: Dictionary = L["params"]
	var rw: float = p["road_w"]
	var sw: float = p["sidewalk_w"]
	var anchors: Dictionary = L["anchors"]
	var mz: float = anchors["main_street_mid"][2]
	# Portrait framing: eye-level shots pitch up a few degrees so the horizon
	# sits in the lower third instead of filling half the frame with asphalt.
	match kind:
		"aerial":
			return _shot(Vector3(float(b[2]) + 8.0, 36.0, mz + 16.0), Vector3(lerpf(b[0], b[2], 0.55), 0.0, mz), 55.0)
		"street":
			var start := Vector3(float(b[0]) + 9.0, 1.65, mz + rw * 0.3)
			return _shot(start, _pitched(start, Vector3(float(b[2]), 1.65, mz - 0.6), 7.0), 55.0)
		"house":
			var h := find_house(L, arg)
			if h.is_empty():
				return {"error": "no house '%s' in this set" % arg}
			var cam := house_camera(L, h)
			return _shot(cam[0], cam[1], 68.0)
		"intersection":
			var c := _v(anchors["town_center"])
			var pos := c + Vector3(rw * 0.35, 1.4, rw * 0.35)
			return _shot(pos, _pitched(pos, c + Vector3(-30.0, 1.4, -30.0), 8.0), 62.0)
		"entrance":
			if not anchors.has("town_entrance_east"):
				return {"error": "this town has no exit roads (exit_roads=false)"}
			var e := _v(anchors["town_entrance_east"])
			var pos := e + Vector3(18.0, 1.7, 1.8)
			return _shot(pos, _pitched(pos, Vector3(float(b[2]) - 20.0, 1.7, mz), 6.0), 52.0)
	return {"error": "unknown view '%s' (known: %s)" % [view, ", ".join(PackedStringArray(NAMES))]}
