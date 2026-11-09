## Bodies, animations, actions and characters for actors.
##
## Both Universal Animation Library files and the female mannequin share one
## 65-bone skeleton at Armature/Skeleton3D, so their 86 animations merge into
## a single library that plays on every body.
extends RefCounted

const Paths = preload("res://scripts/core/paths.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")

const BODIES := {
	"male": "res://assets/quaternius_ual/UAL1_Standard.glb",
	"female": "res://assets/quaternius_ual/Mannequin_F.glb",
}
const ANIM_SOURCES := [
	"res://assets/quaternius_ual/UAL1_Standard.glb",
	"res://assets/quaternius_ual/UAL2_Standard.glb",
]
## Height of the mannequins as authored (metres), used to scale characters.
const BASE_HEIGHT := 1.83

const CHARACTER_KEYS := ["id", "description", "tags", "body", "colors", "height", "width",
	"idle", "gait", "glow", "props"]
const PROP_KEYS := ["model", "bone", "size", "offset", "rotation"]

static var _library: AnimationLibrary
static var _actions: Dictionary = {}
static var _characters: Dictionary = {}


static func anim_library() -> AnimationLibrary:
	if _library == null:
		_library = AnimationLibrary.new()
		for src in ANIM_SOURCES:
			var ps := load(src) as PackedScene
			if ps == null:
				continue
			var inst := ps.instantiate()
			var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
			if ap:
				for anim_name in ap.get_animation_list():
					if anim_name != &"RESET" and not _library.has_animation(anim_name):
						_library.add_animation(anim_name, ap.get_animation(anim_name))
			inst.free()
	return _library


## A body with a fresh AnimationPlayer holding the merged library.
static func body_instance(body: String) -> Node3D:
	var ps := load(BODIES.get(body, BODIES["male"])) as PackedScene
	var inst: Node3D = ps.instantiate()
	for c in inst.get_children():
		if c is AnimationPlayer:
			inst.remove_child(c)
			c.free()
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	ap.root_node = NodePath("..")
	ap.add_animation_library("", anim_library())
	ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	inst.add_child(ap)
	return inst


## Bone transform in skeleton space, computed from local poses up the parent
## chain. Unlike get_bone_global_pose() this never returns a stale cache, so it
## is exact right after seeking an animation, even outside a running frame.
static func bone_global(sk: Skeleton3D, bone: int) -> Transform3D:
	var t := sk.get_bone_pose(bone)
	var p := sk.get_bone_parent(bone)
	while p >= 0:
		t = sk.get_bone_pose(p) * t
		p = sk.get_bone_parent(p)
	return t


static func actions() -> Dictionary:
	if _actions.is_empty():
		var r := Paths.load_json(Paths.repo_path("library/actions.json"))
		if r["ok"]:
			_actions = r["data"]["actions"]
	return _actions


static func action(id: String) -> Dictionary:
	return actions().get(id, {})


static func list_characters() -> PackedStringArray:
	return Paths.list_json("library/characters")


static func character(id: String) -> Dictionary:
	if not _characters.has(id):
		var r := Paths.load_json(Paths.repo_path("library/characters/%s.json" % id))
		_characters[id] = r["data"] if r["ok"] and typeof(r["data"]) == TYPE_DICTIONARY else {}
	return _characters[id]


static func validate_character(id: String) -> Array:
	var c := character(id)
	if c.is_empty():
		return ["unknown character '%s' (available: %s)" % [id, ", ".join(list_characters())]]
	var e := []
	for k in c:
		if not (k in CHARACTER_KEYS):
			e.append("character %s: unknown key '%s' (known: %s)" % [id, k, ", ".join(PackedStringArray(CHARACTER_KEYS))])
	if not BODIES.has(String(c.get("body", "male"))):
		e.append("character %s: body must be one of %s" % [id, BODIES.keys()])
	for k in ["body", "joints"]:
		var col = c.get("colors", {}).get(k)
		if col != null and not Color.html_is_valid(String(col)):
			e.append("character %s: colors.%s is not a hex colour" % [id, k])
	for k in ["idle", "gait"]:
		if c.has(k) and action(String(c[k])).is_empty():
			e.append("character %s: %s action '%s' does not exist" % [id, k, c[k]])
	if c.has("gait") and not action(String(c["gait"])).get("gait", false):
		e.append("character %s: gait '%s' is not a moving action" % [id, c["gait"]])
	for p in c.get("props", []):
		for k in p:
			if not (k in PROP_KEYS):
				e.append("character %s: prop has unknown key '%s'" % [id, k])
		if KitDB.model(String(p.get("model", ""))).is_empty():
			e.append("character %s: prop model '%s' is not in the catalog" % [id, p.get("model", "")])
	return e
