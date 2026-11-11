## Registry of set generators. Each generator is a pair:
##   generator: pure layout data (params + seed -> Dictionary), testable headless
##   builder:   layout + look -> Godot nodes
## To add a new kind of location (supermarket, school...), add a pair here.
extends RefCounted

const TownGenerator = preload("res://scripts/world/generators/town_generator.gd")
const TownBuilder = preload("res://scripts/world/builders/town_builder.gd")
const SupermarketGenerator = preload("res://scripts/world/generators/supermarket_generator.gd")
const SupermarketBuilder = preload("res://scripts/world/builders/supermarket_builder.gd")
const DowntownGenerator = preload("res://scripts/world/generators/downtown_generator.gd")
const DowntownBuilder = preload("res://scripts/world/builders/downtown_builder.gd")
const StageGenerator = preload("res://scripts/world/generators/stage_generator.gd")
const StageBuilder = preload("res://scripts/world/builders/stage_builder.gd")

const GENERATORS := {
	"town": {"generator": TownGenerator, "builder": TownBuilder},
	"supermarket": {"generator": SupermarketGenerator, "builder": SupermarketBuilder},
	"downtown": {"generator": DowntownGenerator, "builder": DowntownBuilder},
	"stage": {"generator": StageGenerator, "builder": StageBuilder},
}


static func validate(set_spec: Dictionary) -> Array:
	var e := []
	var g = set_spec.get("generator")
	if not GENERATORS.has(g):
		e.append("set.generator must be one of %s (got %s)" % [GENERATORS.keys(), g])
		return e
	var sd = set_spec.get("seed")
	if typeof(sd) != TYPE_INT and typeof(sd) != TYPE_FLOAT:
		e.append("set.seed must be a number")
	var params = set_spec.get("params", {})
	if typeof(params) != TYPE_DICTIONARY:
		e.append("set.params must be an object")
	else:
		e.append_array(GENERATORS[g]["generator"].validate_params(params))
	return e


static func generate(set_spec: Dictionary) -> Dictionary:
	var entry: Dictionary = GENERATORS[set_spec["generator"]]
	return entry["generator"].generate(set_spec.get("params", {}), int(set_spec["seed"]))


static func build(layout: Dictionary, look: Dictionary) -> Node3D:
	var entry: Dictionary = GENERATORS[layout["generator"]]
	return entry["builder"].build(layout, look)


## Height of the walkable surface at (x, z) in this layout (where feet stand).
static func ground_height(L: Dictionary, x: float, z: float) -> float:
	var entry: Dictionary = GENERATORS[L.get("generator", "town")]
	return entry["generator"].ground_height(L, x, z)


## Compact description of a layout for the director (LLM): named places, not geometry.
static func manifest(layout: Dictionary) -> Dictionary:
	var entry: Dictionary = GENERATORS[layout["generator"]]
	return entry["generator"].manifest(layout)
