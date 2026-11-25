## Gags: custom animated set pieces written in GDScript, per episode
## (episodes/<id>/gags/*.gd) or reused from library/gags/. When the vocabulary
## (reveals, actors, cues) can't express an idea (a cash cannon that buries a
## man in bills, a cord hauling a nuclear plant), the director writes a gag.
##
##   "gags": [
##     { "id": "cannon", "script": "gags/cash_cannon.gd", "t": {"line": "n8d", "word": "Within"},
##       "until": {"line": "n9a"}, "at": {"anchor": "office", "offset": [1.2, 0, 1.5]},
##       "face": "rep", "params": {"fire": {"line": "n8d", "word": "buy"}, "target": "rep.chest"} }
##   ]
##
## A gag script is a plain GDScript file (extends RefCounted) with:
##   func build(g: Dictionary) -> Node3D
##       Make the nodes once. g is the gag entry (times already in scene seconds).
##   func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary
##       Place everything for scene time t. MUST be a pure function of t (renders seek in any
##       order): no accumulated state, no randf(); use RandomNumberGenerator seeded from g["id"].
##       ctx: {"point": Callable(ref) -> {"pos", "forward"} or {"error"}, "age": t - g.t,
##             "holder": the Node3D placed at g.at}.
##       Return extra anchors {name: Vector3 (world)}: they become "<id>.<name>" for cameras,
##       reveals and other gags.
##   func validate(g: Dictionary) -> Array   (optional) param errors
##
## The script path is resolved by the pipeline (relative to the episode, or "library:<name>").
## Times inside params ({"line", "word"} refs) are resolved to scene seconds too.
extends RefCounted

const Shot = preload("res://scripts/camera/shot.gd")

const KEYS := ["id", "script", "t", "until", "shown", "at", "face", "params", "note"]

static var _scripts := {}
static var _errors := {}


static func _load(path: String) -> GDScript:
	if _scripts.has(path):
		return _scripts[path]
	if not FileAccess.file_exists(path):
		_errors[path] = "script not found: " + path
		return null
	var s := GDScript.new()
	s.source_code = FileAccess.get_file_as_string(path)
	var err := s.reload()
	if err != OK:
		_errors[path] = "script does not compile (error %d): %s" % [err, path]
		return null
	_scripts[path] = s
	return s


static func validate(gags) -> Array:
	if gags == null:
		return []
	if typeof(gags) != TYPE_ARRAY:
		return ["'gags' must be an array"]
	var e := []
	var ids := {}
	for i in gags.size():
		var g = gags[i]
		var w := "gags[%d]" % i
		if typeof(g) != TYPE_DICTIONARY:
			e.append(w + " must be an object")
			continue
		w = "gags[%d] (%s)" % [i, g.get("id", "?")]
		for k in g:
			if not (k in KEYS):
				e.append("%s: unknown key '%s' (known: %s)" % [w, k, ", ".join(PackedStringArray(KEYS))])
		var id := String(g.get("id", ""))
		if id == "" or id.contains(".") or ids.has(id):
			e.append(w + ": needs a unique 'id' without dots")
		ids[id] = true
		if String(g.get("script", "")) == "":
			e.append(w + ": needs 'script' (a .gd file)")
		if not (typeof(g.get("t")) in [TYPE_INT, TYPE_FLOAT]):
			e.append(w + ": 't' must be scene seconds (or a word reference, resolved by the pipeline)")
		if not g.has("at"):
			e.append(w + ": needs 'at' (where the gag stands)")
		if g.has("params") and typeof(g["params"]) != TYPE_DICTIONARY:
			e.append(w + ": params must be an object")
		if g.has("shown"):
			var ok: bool = typeof(g["shown"]) == TYPE_ARRAY
			if ok:
				for sp in g["shown"]:
					ok = ok and typeof(sp) == TYPE_ARRAY and sp.size() == 2 and typeof(sp[0]) in [TYPE_INT, TYPE_FLOAT] 						and typeof(sp[1]) in [TYPE_INT, TYPE_FLOAT]
			if not ok:
				e.append(w + ": 'shown' must be [[from, to], ...] (scene seconds or time references)")
		var s := _load(String(g.get("script", "")))
		if s == null:
			e.append("%s: %s" % [w, _errors.get(String(g.get("script", "")), "cannot load the script")])
			continue
		var inst = s.new()
		for m in ["build", "pose"]:
			if not inst.has_method(m):
				e.append("%s: the script has no %s() (see godot/scripts/timeline/gags.gd)" % [w, m])
		if inst.has_method("validate"):
			for msg in inst.validate(g):
				e.append("%s: %s" % [w, msg])
	return e


static func build(gags) -> Node3D:
	var root := Node3D.new()
	root.name = "Gags"
	for g in (gags if gags is Array else []):
		var s := _load(String(g["script"]))
		if s == null:
			continue
		var inst = s.new()
		var holder := Node3D.new()
		holder.name = String(g["id"])
		holder.visible = false
		holder.set_meta("gag", inst)
		root.add_child(holder)
		var content: Node3D = inst.build(g)
		content.name = "content"
		holder.add_child(content)
	return root


## Place and animate every gag for scene time t (L carries actor + reveal anchors).
## Returns anchors {"<id>": ..., "<id>.<name>": ...}.
static func pose(root: Node3D, gags, t: float, L: Dictionary, actors: Node3D = null) -> Dictionary:
	var out := {}
	if root == null:
		return out
	for g in (gags if gags is Array else []):
		var id := String(g["id"])
		var holder := root.get_node_or_null(NodePath(id)) as Node3D
		if holder == null:
			continue
		var p := Shot.point(L, g["at"])
		if p.has("error"):
			holder.visible = false
			continue
		var yaw := 0.0
		if g.has("face"):
			var f := Shot.point(L, g["face"])
			if not f.has("error"):
				var d: Vector3 = f["pos"] - p["pos"]
				yaw = atan2(d.x, d.z)
		holder.position = p["pos"]
		holder.rotation = Vector3(0, yaw, 0)
		out[id] = {"pos": p["pos"], "forward": Vector3(sin(yaw), 0, cos(yaw))}
		var t0 := float(g["t"])
		var until := float(g.get("until", INF))
		holder.visible = t >= t0 and t < until and _in_spans(g, t)
		if not holder.visible:
			continue
		var ctx := {"point": func(ref): return Shot.point(L, ref), "age": t - t0, "holder": holder}
		if actors != null:
			ctx["actor"] = func(actor_id: String): return actors.get_node_or_null(NodePath(actor_id))
		var extra = (holder.get_meta("gag")).pose(holder.get_node("content"), g, t, ctx)
		if typeof(extra) == TYPE_DICTIONARY:
			for k in extra:
				out["%s.%s" % [id, k]] = {"pos": extra[k], "forward": Vector3(sin(yaw), 0, cos(yaw))}
		# Later gags can use this one's anchors (a cash stream fired from a cannon's muzzle):
		# list the source gag first.
		if L.has("actor_anchors"):
			L["actor_anchors"].merge(out, true)
	return out


## "shown": [[from, to], ...] in scene seconds (resolved by the pipeline). Without it the gag is always eligible.
## Places far apart used to be kept apart by distance (20-220 km), which cost float precision (shaking cameras,
## z-fighting); with spans, every place can sit near the origin and only the active one is drawn.
static func _in_spans(g: Dictionary, t: float) -> bool:
	if not g.has("shown"):
		return true
	for sp in g["shown"]:
		if t >= float(sp[0]) and t < float(sp[1]):
			return true
	return false
