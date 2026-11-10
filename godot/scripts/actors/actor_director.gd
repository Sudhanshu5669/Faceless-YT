## Turns actor specs (JSON) into posed actors.
##
##   { "id": "you", "character": "you", "at": "house_9.front_door",
##     "facing": "house_9.curb" | 90 | "forward" | "back",
##     "action": "phone", "freeze": 0.4 | "apex", "phase": 0.0,
##     "route": { "via": ["house_9.curb", "street_h1.mid"], "gait": "run", "speed": 4.0,
##                "start": 2.0, "then": "idle", "then_facing": "town_center", "then_freeze": 0.5 },
##     "crowd": { "count": 12, "radius": 8, "characters": ["zombie", "zombie_f"], "start_spread": 4.0 },
##              ("area": [width, depth] instead of radius: a rectangle in the at-anchor's
##               frame, e.g. a line of zombies pressed against a window)
##     "cues": [ { "t": 6.0, "action": "jump" }, { "t": 6.7, "hold": true }, { "t": 12, "hold": false },
##               { "t": 14, "facing": "stranger" } ] }
##
## Cue times are scene seconds. A hold freezes the actor completely (pose,
## position, route progress) until released: the actor's own clock stops.
## Facing another actor ("facing": "stranger") tracks them every frame; facing
## cues turn smoothly over "turn" seconds (default Actor.TURN_TIME).
##
## Positions use the same point forms as cameras (anchor, offset, orbit, world).
extends RefCounted

const Cast = preload("res://scripts/actors/cast.gd")
const Actor = preload("res://scripts/actors/actor.gd")
const Shot = preload("res://scripts/camera/shot.gd")
const Anchors = preload("res://scripts/camera/anchors.gd")

const ACTOR_KEYS := ["id", "character", "at", "facing", "action", "freeze", "phase", "route", "crowd", "cues"]
const CUE_KEYS := ["t", "action", "freeze", "facing", "turn", "hold"]
const ROUTE_KEYS := ["via", "gait", "speed", "arrive", "start", "then", "then_facing", "then_freeze"]
const CROWD_KEYS := ["count", "radius", "area", "characters", "start_spread", "seed", "spacing"]


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
		var act := String(a.get("action", ""))
		if act == "" and not chars.is_empty():
			act = String(Cast.character(String(chars[0])).get("idle", "idle"))
		if a.has("action") and Cast.action(act).is_empty():
			e.append("%s (%s): unknown action '%s' (see library/actions.json)" % [where, id, act])
		elif a.has("freeze"):
			var fe := Cast.validate_freeze(act, a["freeze"])
			if fe != "":
				e.append("%s (%s): %s" % [where, id, fe])
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
				if r.has("speed") and r.has("arrive"):
					e.append(where + ": route takes 'speed' or 'arrive' (scene time to reach the end), not both")
				if r.has("arrive") and float(r["arrive"]) <= float(r.get("start", 0.0)):
					e.append(where + ": route.arrive must be after route.start")
				if r.has("gait") and not Cast.action(String(r["gait"])).get("gait", false):
					e.append("%s: route.gait '%s' is not a moving action (walk, run, jog, sneak, zombie_walk...)" % [where, r["gait"]])
				if r.has("then") and Cast.action(String(r["then"])).is_empty():
					e.append("%s: route.then '%s' is not an action" % [where, r["then"]])
				elif r.has("then_freeze"):
					var then_act := String(r.get("then", "idle"))
					if not r.has("then") and not chars.is_empty():
						then_act = String(Cast.character(String(chars[0])).get("idle", "idle"))
					var tfe := Cast.validate_freeze(then_act, r["then_freeze"])
					if tfe != "":
						e.append("%s: route.then_%s" % [where, tfe])
		if a.has("cues"):
			e.append_array(_validate_cues(a["cues"], "%s (%s)" % [where, id]))
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
				if c.has("area") and (typeof(c["area"]) != TYPE_ARRAY or c["area"].size() != 2):
					e.append(where + ": crowd.area must be [width, depth] in metres")
				if c.has("area") and c.has("radius"):
					e.append(where + ": crowd takes 'radius' or 'area', not both")
	return e


static func _validate_cues(cues, where: String) -> Array:
	if typeof(cues) != TYPE_ARRAY:
		return [where + ": cues must be an array"]
	var e := []
	var last_t := -1.0
	for i in cues.size():
		var c = cues[i]
		var cw := "%s cues[%d]" % [where, i]
		if typeof(c) != TYPE_DICTIONARY:
			e.append(cw + " must be an object")
			continue
		for k in c:
			if not (k in CUE_KEYS):
				e.append("%s: unknown key '%s' (known: %s)" % [cw, k, ", ".join(PackedStringArray(CUE_KEYS))])
		if not (typeof(c.get("t")) in [TYPE_INT, TYPE_FLOAT]) or float(c["t"]) < 0.0:
			e.append(cw + ": needs 't' (scene seconds, >= 0)")
			continue
		if float(c["t"]) < last_t:
			e.append(cw + ": cues must be in time order")
		last_t = float(c["t"])
		if c.has("hold"):
			if typeof(c["hold"]) != TYPE_BOOL:
				e.append(cw + ": hold must be true or false")
			if c.has("action") or c.has("facing") or c.has("freeze") or c.has("turn"):
				e.append(cw + ": a hold cue only takes 't' and 'hold'")
			continue
		if not (c.has("action") or c.has("facing")):
			e.append(cw + ": needs 'action', 'facing' or 'hold'")
		if c.has("action"):
			if Cast.action(String(c["action"])).is_empty():
				e.append("%s: unknown action '%s'" % [cw, c["action"]])
			elif c.has("freeze"):
				var fe := Cast.validate_freeze(String(c["action"]), c["freeze"])
				if fe != "":
					e.append("%s: %s" % [cw, fe])
		elif c.has("freeze"):
			e.append(cw + ": 'freeze' needs an 'action' in the same cue")
		if c.has("turn") and (not c.has("facing") or not (typeof(c["turn"]) in [TYPE_INT, TYPE_FLOAT]) or float(c["turn"]) < 0.0):
			e.append(cw + ": 'turn' is seconds >= 0 and needs a 'facing' in the same cue")
	return e


## Hold intervals [[from, to], ...] in scene seconds from hold cues.
static func _holds(cues: Array) -> Array:
	var out := []
	var start := -1.0
	for c in cues:
		if not c.has("hold"):
			continue
		if bool(c["hold"]) and start < 0.0:
			start = float(c["t"])
		elif not bool(c["hold"]) and start >= 0.0:
			out.append([start, float(c["t"])])
			start = -1.0
	if start >= 0.0:
		out.append([start, 1.0e9])
	return out


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
		# Another actor: track them (yaw here = toward where they start, the
		# fallback when they can't be looked up).
		var other := String(spec_facing).split(".")[0]
		if starts.has(other):
			return {"yaw": _yaw_to(pos, starts[other], base), "track": other}
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
			var area: Array = c.get("area", [])
			var spacing := float(c.get("spacing", 0.9))
			# Rectangle axes in the at-anchor's frame (right, forward) in world XZ.
			var ay := _anchor_yaw(L, a["at"])
			var fwd2 := Vector2(sin(ay), cos(ay))
			var right2 := Vector2(-fwd2.y, fwd2.x)
			var chars: Array = c.get("characters", [a.get("character", "zombie")])
			var offsets := []
			var tries := 0
			while offsets.size() < int(c["count"]) and tries < 4000:
				tries += 1
				var o: Vector2
				if area.is_empty():
					o = Vector2(r.randf_range(-radius, radius), r.randf_range(-radius, radius))
					if o.length() > radius:
						continue
				else:
					var u := r.randf_range(-0.5, 0.5) * float(area[0])
					var v := r.randf_range(-0.5, 0.5) * float(area[1])
					o = right2 * u + fwd2 * v
				var ok := true
				for q in offsets:
					if (q as Vector2).distance_to(o) < spacing:
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
		"face": String(f.get("track", "")),
		"action": String(a.get("action", chr.get("idle", "idle"))),
		"freeze": Cast.freeze_fraction(String(a.get("action", chr.get("idle", "idle"))), a.get("freeze")),
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
		var then_face := ""
		if rs.has("then_facing"):
			var tf := _facing(L, rs["then_facing"], rs["via"][-1], pts[-1], starts)
			if tf.has("error"):
				return {"error": "actor %s: then_%s" % [id, tf["error"]]}
			end_yaw = tf["yaw"]
			then_face = String(tf.get("track", ""))
		plan["route"] = {
			"points": pts, "cum": cum, "total": cum[-1],
			"gait": gait,
			# "arrive": reach the end at that scene time (speed follows from the distance).
			"speed": cum[-1] / maxf(float(rs["arrive"]) - float(rs.get("start", 0.0)), 0.01) if rs.has("arrive") \
				else float(rs.get("speed", Cast.action(gait).get("speed", 1.0))),
			"start": float(rs.get("start", 0.0)),
			"then": String(rs.get("then", chr.get("idle", "idle"))),
			"then_freeze": Cast.freeze_fraction(String(rs.get("then", chr.get("idle", "idle"))), rs.get("then_freeze")),
			"end_yaw": end_yaw,
			"arrive_yaw": _yaw_to(pts[-2], pts[-1], plan["yaw"]),
			"then_face": then_face,
		}
	# Cues and holds: everything time-based is stored on the actor's own clock.
	var cues: Array = a.get("cues", [])
	var holds := _holds(cues)
	plan["holds"] = holds
	if plan.has("route"):
		plan["route"]["start"] = Cast.warp(holds, float(plan["route"]["start"]))
	var planned_cues := []
	for c in cues:
		if c.has("hold"):
			continue
		var pc := {"tau": Cast.warp(holds, float(c["t"])), "action": String(c.get("action", "")), "yaw": null}
		if c.has("action"):
			pc["freeze"] = Cast.freeze_fraction(String(c["action"]), c.get("freeze"))
		if c.has("facing"):
			var where_then: Vector3 = pos
			if plan.has("route") and float(pc["tau"]) >= float(plan["route"]["start"]):
				where_then = plan["route"]["points"][-1]
			var cf := _facing(L, c["facing"], a["at"], where_then, starts)
			if cf.has("error"):
				return {"error": "actor %s: cue at %.2f s: %s" % [id, float(c["t"]), cf["error"]]}
			pc["yaw"] = cf["yaw"]
			pc["face"] = String(cf.get("track", ""))
			pc["turn"] = float(c.get("turn", Actor.TURN_TIME))
		planned_cues.append(pc)
	plan["cues"] = planned_cues
	return {"plan": plan}


static func build(plans: Array, L: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Actors"
	var peers := {}
	for p in plans:
		var actor := Actor.new()
		actor.setup(p["id"], p["character"], p, L)
		root.add_child(actor)
		peers[String(p["id"])] = actor
	# Every actor can look up the others (to face / track them).
	for a in root.get_children():
		a.peers = peers
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
