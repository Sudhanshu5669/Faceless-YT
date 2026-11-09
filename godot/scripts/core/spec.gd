## Loads and validates TownForge JSON specs (schema 0.1).
## Paths in specs are relative to the repo root unless absolute.
extends RefCounted

const Paths = preload("res://scripts/core/paths.gd")
const SetBuilder = preload("res://scripts/world/set_builder.gd")
const LookCompiler = preload("res://scripts/look/look_compiler.gd")
const Shot = preload("res://scripts/camera/shot.gd")
const ActorDirector = preload("res://scripts/actors/actor_director.gd")

const SUPPORTED_VERSIONS := ["0.1"]


static func repo_root() -> String:
	return Paths.repo_root()


static func repo_path(rel: String) -> String:
	return Paths.repo_path(rel)


static func resolve(p: String) -> String:
	return Paths.resolve(p)


static func load_json(path: String) -> Dictionary:
	return Paths.load_json(path)


## Validates a set spec. Returns a list of human-readable errors (empty = valid).
static func validate_set_spec(spec) -> Array:
	var e := []
	if typeof(spec) != TYPE_DICTIONARY:
		return ["spec must be a JSON object"]
	var v = spec.get("schema_version")
	if not (v in SUPPORTED_VERSIONS):
		e.append("schema_version must be one of %s (got %s)" % [SUPPORTED_VERSIONS, v])
	var s = spec.get("set")
	if typeof(s) != TYPE_DICTIONARY:
		e.append("'set' must be an object")
	else:
		e.append_array(SetBuilder.validate(s))
	if not spec.has("look"):
		e.append("'look' is required (a preset name or a look object)")
	else:
		var c := LookCompiler.compile(spec["look"])
		e.append_array(c["errors"])
	e.append_array(ActorDirector.validate(spec.get("actors")))
	if spec.has("preview"):
		var pv = spec["preview"]
		if typeof(pv) != TYPE_DICTIONARY:
			e.append("'preview' must be an object")
		else:
			if pv.has("resolution"):
				var r = pv["resolution"]
				if typeof(r) != TYPE_ARRAY or r.size() != 2 or float(r[0]) < 64 or float(r[1]) < 64 or float(r[0]) > 4096 or float(r[1]) > 4096:
					e.append("preview.resolution must be [width, height] between 64 and 4096")
			if pv.has("views"):
				if typeof(pv["views"]) != TYPE_ARRAY:
					e.append("preview.views must be an array")
				else:
					for view in pv["views"]:
						e.append_array(Shot.validate(view))
	return e
