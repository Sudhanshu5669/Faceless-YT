## Bodies, animations, actions and characters for actors.
##
## Both Universal Animation Library files and the female mannequin share one
## 65-bone skeleton at Armature/Skeleton3D, so their 86 animations merge into
## a single library that plays on every body.
extends RefCounted

const Paths = preload("res://scripts/core/paths.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Retarget = preload("res://scripts/actors/retarget.gd")
const Toon = preload("res://scripts/actors/toon.gd")

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

const CHARACTER_KEYS := ["id", "description", "tags", "body", "model", "colors", "height", "width",
	"idle", "gait", "glow", "props", "toon"]
const MANNEQUIN_SKELETON := "Armature/Skeleton3D"
const PROP_KEYS := ["model", "bone", "size", "offset", "rotation"]
const ACTION_KEYS := ["anim", "sequence", "loop", "gait", "speed", "lift", "marks", "description"]
const SEGMENT_KEYS := ["anim", "from", "to", "duration", "blend"]

static var _library: AnimationLibrary
static var _actions: Dictionary = {}
static var _clips: Dictionary = {}
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


## A body with a fresh AnimationPlayer holding the merged library. With a
## character model (a catalog id covered by library/rigs.json), the mannequin
## stays as the hidden animation source and the model is added as "model",
## scaled so its head bone sits at the mannequin's head height; the actor
## retargets the pose onto it (retarget.gd).
static func body_instance(body: String, model_id: String = "") -> Node3D:
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
	if model_id != "":
		_add_model(inst, model_id)
	return inst


static func _add_model(inst: Node3D, model_id: String) -> void:
	var src := inst.get_node(MANNEQUIN_SKELETON) as Skeleton3D
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visible = false
	var m: Node3D = KitDB.scene(model_id).instantiate()
	for c in m.find_children("*", "AnimationPlayer", true, false):
		c.get_parent().remove_child(c)
		c.free()
	m.name = "model"
	inst.add_child(m)
	var dst := model_skeleton(inst, model_id)
	var head_name := String(Retarget.rigs()[Retarget.rig_for(model_id)]["bones"]["Head"])
	var src_head := (Retarget._chain(src, inst) * src.get_bone_global_rest(src.find_bone("Head")).origin).y
	var dst_head := (Retarget._chain(dst, inst) * dst.get_bone_global_rest(dst.find_bone(head_name)).origin).y
	m.scale = Vector3.ONE * (src_head / dst_head)


static func model_skeleton(inst: Node3D, model_id: String) -> Skeleton3D:
	# A rig may pin the skeleton's node path; without one (or if it is absent) use the model's first Skeleton3D, so one
	# rig map serves several downloads whose node trees differ (VLTXD's three witches).
	var path := String(Retarget.rigs()[Retarget.rig_for(model_id)].get("skeleton", ""))
	if path != "" and inst.has_node("model/" + path):
		return inst.get_node("model/" + path) as Skeleton3D
	var found := inst.get_node("model").find_children("*", "Skeleton3D", true, false)
	return found[0] as Skeleton3D if not found.is_empty() else null


static var _model_materials: Dictionary = {}


## Material names on a character model's meshes (what "colors" can repaint).
static func model_materials(model_id: String) -> PackedStringArray:
	if not _model_materials.has(model_id):
		var names := PackedStringArray()
		var ps := KitDB.scene(model_id)
		if ps:
			var inst := ps.instantiate()
			for mi in inst.find_children("*", "MeshInstance3D", true, false):
				var mesh: Mesh = (mi as MeshInstance3D).mesh
				for si in mesh.get_surface_count():
					var mat := mesh.surface_get_material(si)
					if mat and not (String(mat.resource_name) in names):
						names.append(String(mat.resource_name))
			inst.free()
		_model_materials[model_id] = names
	return _model_materials[model_id]


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


## An action as a timeline of clip segments played back to back:
##   {"length", "loop", "segments": [{"anim", "from", "to", "start", "dur", "blend"}],
##    "lift": {"from", "to", "height"} | {}, "marks": {name: seconds}}
## A plain action ({"anim": "Idle"}) is one segment covering the whole clip.
## A "sequence" action lists segments; each plays clip time from -> to (backwards
## when to < from) over "duration" seconds and may "blend" in from the previous
## segment's last pose. "lift" raises the body on a ballistic arc (airborne
## clips are authored in place). "marks" name moments for "freeze".
static func clip_plan(id: String) -> Dictionary:
	if not _clips.has(id):
		var a := action(id)
		_clips[id] = {} if a.is_empty() else _build_clip_plan(a)
	return _clips[id]


static func _build_clip_plan(a: Dictionary) -> Dictionary:
	var lib := anim_library()
	var src: Array = a.get("sequence", [{"anim": a.get("anim", "")}])
	var segs := []
	var t := 0.0
	for s in src:
		var anim := String(s.get("anim", ""))
		if not lib.has_animation(anim):
			return {"error": "animation '%s' not in the library" % anim}
		var alen := lib.get_animation(anim).length
		var from := float(s.get("from", 0.0))
		var to := float(s.get("to", alen))
		var dur := float(s.get("duration", absf(to - from)))
		segs.append({"anim": anim, "from": from, "to": to, "start": t, "dur": dur,
			"blend": float(s.get("blend", 0.0)), "anim_len": alen})
		t += dur
	return {"length": t, "loop": bool(a.get("loop", true)), "segments": segs,
		"lift": a.get("lift", {}), "marks": a.get("marks", {})}


## Height of the body above the ground (metres, before character scale) at action time tt.
static func lift_at(cp: Dictionary, tt: float) -> float:
	var l: Dictionary = cp.get("lift", {})
	if l.is_empty():
		return 0.0
	var a := float(l["from"])
	var b := float(l["to"])
	if tt <= a or tt >= b:
		return 0.0
	var s := (tt - a) / (b - a)
	return 4.0 * float(l["height"]) * s * (1.0 - s)


## Actor clock at scene time t: scene time minus everything spent on hold
## (holds = [[from, to], ...] in scene seconds).
static func warp(holds: Array, t: float) -> float:
	var held := 0.0
	for h in holds:
		if t > float(h[0]):
			held += minf(t, float(h[1])) - float(h[0])
	return t - held


## A spec's "freeze" (number 0..1, mark name, or null) as a fraction 0..1, or -1 for none.
static func freeze_fraction(action_id: String, f) -> float:
	if f == null:
		return -1.0
	if typeof(f) == TYPE_STRING:
		var cp := clip_plan(action_id)
		return float(cp["marks"][f]) / float(cp["length"])
	return float(f)


## "" if a spec's freeze value is valid for the action, else an error.
static func validate_freeze(action_id: String, f) -> String:
	if f == null:
		return ""
	if typeof(f) == TYPE_STRING:
		var marks: Dictionary = clip_plan(action_id).get("marks", {})
		if not marks.has(f):
			return "freeze '%s' is not a mark of action '%s' (marks: %s)" % [f, action_id,
				", ".join(PackedStringArray(marks.keys())) if not marks.is_empty() else "none"]
		return ""
	if typeof(f) != TYPE_INT and typeof(f) != TYPE_FLOAT or float(f) < 0.0 or float(f) > 1.0:
		return "freeze must be 0..1 or a mark name"
	return ""


## Errors in one action definition (library/actions.json).
static func validate_action(id: String) -> Array:
	var a := action(id)
	if a.is_empty():
		return ["unknown action '%s'" % id]
	var e := []
	for k in a:
		if not (k in ACTION_KEYS):
			e.append("action %s: unknown key '%s' (known: %s)" % [id, k, ", ".join(PackedStringArray(ACTION_KEYS))])
	if a.has("anim") == a.has("sequence"):
		e.append("action %s: needs exactly one of 'anim' or 'sequence'" % id)
	if a.has("sequence") and a.get("gait", false):
		e.append("action %s: a gait must be a single 'anim'" % id)
	var cp := clip_plan(id)
	if cp.has("error"):
		e.append("action %s: %s" % [id, cp["error"]])
		return e
	for i in a.get("sequence", []).size():
		var s: Dictionary = a["sequence"][i]
		for k in s:
			if not (k in SEGMENT_KEYS):
				e.append("action %s: sequence[%d] unknown key '%s'" % [id, i, k])
		var seg: Dictionary = cp["segments"][i]
		for k in ["from", "to"]:
			if float(seg[k]) < 0.0 or float(seg[k]) > float(seg["anim_len"]) + 0.001:
				e.append("action %s: sequence[%d].%s outside clip '%s' (0..%.2f s)" % [id, i, k, seg["anim"], seg["anim_len"]])
		if float(seg["dur"]) <= 0.0:
			e.append("action %s: sequence[%d] has no duration (give 'duration' when from == to)" % [id, i])
		if float(seg["blend"]) > float(seg["dur"]) + 0.001 or (i == 0 and float(seg["blend"]) > 0.0):
			e.append("action %s: sequence[%d].blend must be within the segment and not on the first" % [id, i])
	var length := float(cp["length"])
	var l: Dictionary = cp["lift"]
	if not l.is_empty():
		if not (l.has("from") and l.has("to") and l.has("height")) or float(l.get("from", 0)) >= float(l.get("to", 0)) \
				or float(l.get("to", 0)) > length + 0.001 or float(l.get("height", 0)) <= 0.0:
			e.append("action %s: lift needs from < to within %.2f s and height > 0" % [id, length])
	for m in cp["marks"]:
		if float(cp["marks"][m]) < 0.0 or float(cp["marks"][m]) > length + 0.001:
			e.append("action %s: mark '%s' outside 0..%.2f s" % [id, m, length])
	return e


## Ground covered per walk cycle relative to the mannequin: 1 for regular
## characters; a toon's short legs cover less (scaled by its height).
static func stride(c: Dictionary) -> float:
	if not c.has("toon"):
		return 1.0
	return float(c.get("height", BASE_HEIGHT)) / BASE_HEIGHT * Toon.stride_ratio()


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
	var model := String(c.get("model", ""))
	if c.has("toon"):
		e.append_array(Toon.validate(c["toon"], "character " + id))
		if model != "" or c.has("colors"):
			e.append("character %s: a toon takes no 'model' or 'colors' (colours live in 'toon')" % id)
	if model != "":
		if KitDB.model(model).is_empty():
			e.append("character %s: model '%s' is not in the catalog" % [id, model])
		elif Retarget.rig_for(model) == "":
			e.append("character %s: model '%s' is from a pack no rig covers (library/rigs.json)" % [id, model])
		else:
			var mats := model_materials(model)
			for k in c.get("colors", {}):
				if not (String(k) in mats):
					e.append("character %s: colors.%s is not a material of %s (has: %s)" % [id, k, model, ", ".join(mats)])
	for k in c.get("colors", {}):
		if model == "" and not (k in ["body", "joints"]):
			e.append("character %s: mannequin colors are 'body' and 'joints', not '%s'" % [id, k])
		elif not Color.html_is_valid(String(c["colors"][k])):
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
