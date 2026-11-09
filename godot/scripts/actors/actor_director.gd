## Turns actor specs (JSON) into posed actors.
##
##   { "id": "you", "character": "you", "at": "house_9.front_door",
##     "facing": "house_9.curb" | 90 | "forward" | "back",
##     "action": "phone", "freeze": 0.4, "phase": 0.0,
##     "route": { "via": ["house_9.curb", "street_h1.mid"], "gait": "run", "speed": 4.0,
##                "start": 2.0, "then": "idle", "then_facing": "town_center", "then_freeze": 0.5 },
##     "crowd": { "count": 12, "radius": 8, "characters": ["zombie", "zombie_f"], "start_spread": 4.0 } }
##
## Positions use the same point forms as cameras (anchor, offset, orbit, world).
extends RefCounted

const Cast = preload("res://scripts/actors/cast.gd")
const Actor = preload("res://scripts/actors/actor.gd")
const Shot = preload("res://scripts/camera/shot.gd")
const Anchors = preload("res://scripts/camera/anchors.gd")

const ACTOR_KEYS := ["id", "character", "at", "facing", "action", "freeze", "phase", "route", "crowd"]
const ROUTE_KEYS := ["via", "gait", "speed", "start", "then", "then_facing", "then_freeze"]
const CROWD_KEYS := ["count", "radius", "characters", "start_spread", "seed"]


## Key-level validation, usable before a set exists.
static func validate(actors) -> Array:
	if actors == null:
		return []
	if typeof(actors) != TYPE_ARRAY:
		return ["'actors' must be an array"]
	var e := []
	var ids := {}
	for i in actors.size():
		var a = actors[i]
		var where := "actors[%d]" % i
		if typeof(a) != TYPE_DICTIONARY:
			e.append(where + " must be an object")
			continue
		for k in a:
			if not (k in ACTOR_KEYS):
				e.append("%s: unknown key '%s' (known: %s)" % [where, k, ", ".join(PackedStringArray(ACTOR_KEYS))])
		var id := String(a.get("id", ""))
		if id == "" or id.contains(".") or id.contains(":"):
			e.append(where + ": needs an 'id' without '.' or ':'")
		elif ids.has(id):
			e.append("%s: duplicate id '%s'" % [where, id])
		ids[id] = true
		if not a.has("at"):
			e.append("%s (%s): needs 'at'" % [where, id])
		var chars := []
		if a.has("crowd") and typeof(a["crowd"]) == TYPE_DICTIONARY and a["crowd"].has("characters"):
			chars = a["crowd"]["characters"]
		elif a.has("character"):
			chars = [a["character"]]
		else:
			e.append("%s (%s): needs 'character'" % [where, id])
		for c in chars:
			e.append_array(Cast.validate_character(String(c)))
		for k in ["action"]:
			if a.has(k) and Cast.action(String(a[k])).is_empty():
				e.append("%s (%s): unknown action '%s' (see library/actions.json)" % [where, id, a[k]])
		if a.has("route"):
			var r = a["route"]
			if typeof(r) != TYPE_DICTIONARY:
				e.append(where + ": route must be an object")
			else:
				for k in r:
					if not (k in ROUTE_KEYS):
						e.append("%s: route has unknown key '%s' (known: %s)" % [where, k, ", ".join(PackedStringArray(ROUTE_KEYS))])
				if typeof(r.get("via")) != TYPE_ARRAY or r["via"].is_empty():
					e.append(where + ": route.via must be a non-empty list of points")
				if r.has("gait") and not Cast.action(String(r["gait"])).get("gait", false):
					e.append("%s: route.gait '%s' is not a moving action (walk, run, jog, sneak, zombie_walk...)" % [where, r["gait"]])
				if r.has("then") and Cast.action(String(r["then"])).is_empty():
					e.append("%s: route.then '%s' is not an action" % [where, r["then"]])
		if a.has("crowd"):
			var c = a["crowd"]
			if typeof(c) != TYPE_DICTIONARY:
				e.append(where + ": crowd must be an object")
			else:
				for k in c:
					if not (k in CROWD_KEYS):
						e.append("%s: crowd has unknown key '%s'" % [where, k])
				if int(c.get("count", 0)) < 1 or int(c.get("count", 0)) > 200:
					e.append(where + ": crowd.count must be 1..200")
	return e


static func _yaw_to(from: Vector3, to: Vector3, fallback: float) -> float:
	var d := to - from
	return atan2(d.x, d.z) if Vector2(d.x, d.z).length() > 0.01 else fallback


## Natural facing of an "at" point: the anchor's forward direction.
static func _anchor_yaw(L: Dictionary, at) -> float:
	var ref := ""
	if typeof(at) == TYPE_STRING:
		ref = at
	elif typeof(at) == TYPE_DICTIONARY and at.has("anchor"):
		ref = String(at["anchor"])
	if ref == "":
		return 0.0
	var a := Anchors.resolve(L, ref)
	if a.has("error"):
		return 0.0
	var f: Vector3 = a["forward"]
	return atan2(f.x, f.z)


static func _facing(L: Dictionary, spec_facing, at, pos: Vector3, starts: Dictionary = {}) -> Dictionary:
	var base := _anchor_yaw(L, at)
	if spec_facing == null:
		return {"yaw": base}
	if typeof(spec_facing) == TYPE_INT or typeof(spec_facing) == TYPE_FLOAT:
		return {"yaw": deg_to_rad(float(spec_facing))}
	if typeof(spec_facing) == TYPE_STRING:
		if spec_facing == "forward":
			return {"yaw": base}
		if spec_facing == "back":
			return {"yaw": base + PI}
		# Another actor: face where they start.
		var other := String(spec_facing).split(".")[0]
		if starts.has(other):
			return {"yaw": _yaw_to(pos, starts[other], base)}
	var p := Shot.point(L, spec_facing)
	if p.has("error"):
		return {"error": "facing: " + p["error"]}
	return {"yaw": _yaw_to(pos, p["pos"], base)}


## Expands crowds and resolves every point. Returns {"plans": [...]} or {"error": String}.
static func plan_all(actors, L: Dictionary) -> Dictionary:
	var plans := []
	if actors == null:
		return {"plans": plans}
	# Pass 1: where everyone starts, so actors can face each other.
	var starts := {}
	for a in actors:
		var p := Shot.point(L, a["at"])
		if p.has("error"):
			return {"error": "actor %s: at: %s" % [a.get("id", "?"), p["error"]]}
		starts[String(a["id"])] = p["pos"]
	for a in actors:
		if a.has("crowd"):
			var c: Dictionary = a["crowd"]
			var r := RandomNumberGenerator.new()
			r.seed = hash("%s/%s" % [a["id"], c.get("seed", 0)])
			var radius := float(c.get("radius", 6.0))
			var chars: Array = c.get("characters", [a.get("character", "zombie")])
			var offsets := []
			var tries := 0
			while offsets.size() < int(c["count"]) and tries < 4000:
				tries += 1
				var o := Vector2(r.randf_range(-radius, radius), r.randf_range(-radius, radius))
				if o.length() > radius:
					continue
				var ok := true
				for q in offsets:
					if (q as Vector2).distance_to(o) < 0.9:
						ok = false
						break
				if ok:
					offsets.append(o)
			for i in offsets.size():
				var m: Dictionary = a.duplicate(true)
				m.erase("crowd")
				m["id"] = "%s_%d" % [a["id"], i]
				m["character"] = chars[r.randi_range(0, chars.size() - 1)]
				var o: Vector2 = offsets[i]
				var res := _plan_one(m, L, Vector3(o.x, 0, o.y), r.randf_range(-0.4, 0.4), starts)
				if res.has("error"):
					return res
				var plan: Dictionary = res["plan"]
				if plan.has("route"):
					plan["route"]["start"] = float(plan["route"]["start"]) + r.randf() * float(c.get("start_spread", 2.0))
					plan["route"]["speed"] = float(plan["route"]["speed"]) * r.randf_range(0.85, 1.15)
				plan["phase"] = r.randf() * 3.0
				plans.append(plan)
		else:
			var res := _plan_one(a, L, Vector3.ZERO, 0.0, starts)
			if res.has("error"):
				return res
			plans.append(res["plan"])
	return {"plans": plans}


static func _plan_one(a: Dictionary, L: Dictionary, offset: Vector3, yaw_jitter: float, starts: Dictionary) -> Dictionary:
	var id := String(a["id"])
	var at := Shot.point(L, a["at"])
	if at.has("error"):
		return {"error": "actor %s: at: %s" % [id, at["error"]]}
	var pos: Vector3 = at["pos"] + offset
	var f := _facing(L, a.get("facing"), a["at"], pos, starts)
	if f.has("error"):
		return {"error": "actor %s: %s" % [id, f["error"]]}
	var chr := Cast.character(String(a["character"]))
	var plan := {
		"id": id,
		"character": String(a["character"]),
		"pos": pos,
		"yaw": float(f["yaw"]) + yaw_jitter,
		"action": String(a.get("action", chr.get("idle", "idle"))),
		"freeze": float(a.get("freeze", -1.0)),
		"phase": float(a.get("phase", (absi(hash(id)) % 1000) / 1000.0 * 2.0)),
	}
	if a.has("route"):
		var rs: Dictionary = a["route"]
		var pts := [pos]
		for v in rs["via"]:
			var p := Shot.point(L, v)
			if p.has("error"):
				return {"error": "actor %s: route.via: %s" % [id, p["error"]]}
			pts.append(p["pos"] + offset)
		var cum := [0.0]
		for i in range(1, pts.size()):
			cum.append(float(cum[-1]) + (pts[i] as Vector3).distance_to(pts[i - 1]))
		var gait := String(rs.get("gait", chr.get("gait", "walk")))
		var end_yaw := _yaw_to(pts[-2], pts[-1], plan["yaw"])
		if rs.has("then_facing"):
			var tf := _facing(L, rs["then_facing"], rs["via"][-1], pts[-1], starts)
			if tf.has("error"):
				return {"error": "actor %s: then_%s" % [id, tf["error"]]}
			end_yaw = tf["yaw"]
		plan["route"] = {
			"points": pts, "cum": cum, "total": cum[-1],
			"gait": gait,
			"speed": float(rs.get("speed", Cast.action(gait).get("speed", 1.0))),
			"start": float(rs.get("start", 0.0)),
			"then": String(rs.get("then", chr.get("idle", "idle"))),
			"then_freeze": float(rs.get("then_freeze", -1.0)),
			"end_yaw": end_yaw,
		}
	return {"plan": plan}


static func build(plans: Array, L: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Actors"
	for p in plans:
		var actor := Actor.new()
		actor.setup(p["id"], p["character"], p, L)
		root.add_child(actor)
	return root


static func pose_all(actors_node: Node, t: float) -> void:
	if actors_node == null:
		return
	for a in actors_node.get_children():
		a.pose_at(t)


static func anchors(actors_node: Node) -> Dictionary:
	var out := {}
	if actors_node == null:
		return out
	for a in actors_node.get_children():
		out.merge(a.anchor_points())
	return out
