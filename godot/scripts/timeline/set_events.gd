## Timed switches on set objects: an episode's "events".
##
##   "events": [ { "t": 0.4, "target": "toy_hero", "state": "on" },
##               { "t": 30.2, "target": "toys", "state": "on" },
##               { "t": 12.0, "target": "fixture_9", "state": "flicker" } ]
##
## A target is a switchable node's name (toy_hero, fixture_9, freezer_2) or a
## switch group (toys, fixtures, freezers, exit_signs); manifest.json lists
## them. Switchables are built as a Node3D with "on"/"off" children and meta
## "switch" = [groups]. The state at time t is a pure function of t: every
## switchable an event touches starts at its built default, then events up to
## t apply in time order. "flicker" is a deterministic stutter.
extends RefCounted

const KEYS := ["t", "target", "state"]
const STATES := ["on", "off", "flicker"]

static var _index: Dictionary = {}   # set instance id -> {"by_name", "by_group", "default"}


static func validate(events) -> Array:
	if events == null:
		return []
	if typeof(events) != TYPE_ARRAY:
		return ["'events' must be an array"]
	var e := []
	for i in events.size():
		var ev = events[i]
		var w := "events[%d]" % i
		if typeof(ev) != TYPE_DICTIONARY:
			e.append(w + " must be an object")
			continue
		for k in ev:
			if not (k in KEYS):
				e.append("%s: unknown key '%s' (known: %s)" % [w, k, ", ".join(PackedStringArray(KEYS))])
		if not (typeof(ev.get("t")) in [TYPE_INT, TYPE_FLOAT]) or float(ev["t"]) < 0.0:
			e.append(w + ": 't' must be scene seconds >= 0")
		if String(ev.get("target", "")) == "":
			e.append(w + ": needs a 'target' (a switchable name or group, see manifest.json)")
		if not (String(ev.get("state", "")) in STATES):
			e.append("%s: state must be one of %s" % [w, STATES])
	return e


static func _build_index(set_node: Node) -> Dictionary:
	var key := set_node.get_instance_id()
	if _index.has(key):
		return _index[key]
	var by_name := {}
	var by_group := {}
	var defaults := {}
	var stack: Array = [set_node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.has_meta("switch"):
			by_name[String(n.name)] = n
			defaults[n] = (n.get_node("on") as Node3D).visible
			for g in n.get_meta("switch"):
				if not by_group.has(g):
					by_group[g] = []
				by_group[g].append(n)
		stack.append_array(n.get_children())
	_index[key] = {"by_name": by_name, "by_group": by_group, "default": defaults}
	return _index[key]


static func _nodes(idx: Dictionary, target: String) -> Array:
	if idx["by_name"].has(target):
		return [idx["by_name"][target]]
	return idx["by_group"].get(target, [])


## Errors for targets that don't exist in this built set.
static func check_targets(set_node: Node, events: Array) -> Array:
	var idx := _build_index(set_node)
	var e := []
	for ev in events:
		if _nodes(idx, String(ev["target"])).is_empty():
			var groups := PackedStringArray(idx["by_group"].keys())
			e.append("event target '%s' is not a switchable in this set (groups: %s; or a name like toy_hero)" % [ev["target"], ", ".join(groups)])
	return e


static func _switch_to(n: Node, on: bool) -> void:
	(n.get_node("on") as Node3D).visible = on
	(n.get_node("off") as Node3D).visible = not on


static func _flicker(n: Node, t: float) -> bool:
	var step := floorf(t * 14.0)
	var h := absf(sin(step * 12.9898 + float(hash(String(n.name)) % 1000)) * 43758.5453)
	return h - floorf(h) > 0.32


static func apply(set_node: Node, events: Array, t: float) -> void:
	if events.is_empty() or set_node == null:
		return
	var idx := _build_index(set_node)
	var ordered := events.duplicate()
	ordered.sort_custom(func(a, b): return float(a["t"]) < float(b["t"]))
	var state := {}  # node -> "on" | "off" | "flicker"
	for ev in ordered:
		for n in _nodes(idx, String(ev["target"])):
			if not state.has(n):
				state[n] = "on" if idx["default"][n] else "off"
			if float(ev["t"]) <= t:
				state[n] = String(ev["state"])
	for n in state:
		var s := String(state[n])
		_switch_to(n, _flicker(n, t) if s == "flicker" else s == "on")
