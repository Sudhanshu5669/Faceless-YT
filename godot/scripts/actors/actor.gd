## One actor: a character body posed deterministically by time.
##
## pose_at(t) is a pure function of t: the same t always gives the same
## position, facing and skeleton pose, whatever was posed before. Stills,
## the live explore window and (later) video renders all call it.
extends Node3D

const Cast = preload("res://scripts/actors/cast.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const TownGen = preload("res://scripts/world/generators/town_generator.gd")

static var _materials: Dictionary = {}

var actor_id := ""
var character: Dictionary
var plan: Dictionary
var layout: Dictionary
var body: Node3D
var ap: AnimationPlayer
var skeleton: Skeleton3D
var _bones := {}


func setup(id: String, char_id: String, p: Dictionary, L: Dictionary) -> void:
	actor_id = id
	name = id
	character = Cast.character(char_id)
	plan = p
	layout = L
	body = Cast.body_instance(String(character.get("body", "male")))
	body.name = "body"
	var hs := float(character.get("height", Cast.BASE_HEIGHT)) / Cast.BASE_HEIGHT
	var ws := float(character.get("width", 1.0))
	body.scale = Vector3(hs * ws, hs, hs * ws)
	add_child(body)
	ap = body.find_child("AnimationPlayer", true, false)
	skeleton = body.find_child("Skeleton3D", true, false)
	for b in ["Head", "spine_03", "hand_r", "hand_l"]:
		_bones[b] = skeleton.find_bone(b)
	_apply_colors(char_id)
	_attach_props(hs)


func _apply_colors(char_id: String) -> void:
	var cols: Dictionary = character.get("colors", {})
	var glow := float(character.get("glow", 0.0))
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (mi as MeshInstance3D).mesh
		for s in mesh.get_surface_count():
			var m := mesh.surface_get_material(s) as BaseMaterial3D
			if m == null:
				continue
			var slot := "joints" if String(m.resource_name).to_lower().contains("joint") else "body"
			if not cols.has(slot):
				continue
			var key := "%s|%s" % [char_id, slot]
			if not _materials.has(key):
				var nm: BaseMaterial3D = m.duplicate()
				nm.albedo_color = Color(String(cols[slot]))
				if slot == "joints" and glow > 0.0:
					nm.emission_enabled = true
					nm.emission = nm.albedo_color
					nm.emission_energy_multiplier = glow
				_materials[key] = nm
			(mi as MeshInstance3D).set_surface_override_material(s, _materials[key])


func _attach_props(body_scale: float) -> void:
	for p in character.get("props", []):
		var ba := BoneAttachment3D.new()
		ba.bone_name = String(p.get("bone", "hand_r"))
		skeleton.add_child(ba)
		var mid := String(p["model"])
		var sz := KitDB.size(mid)
		var s := float(p.get("size", 0.3)) / maxf(maxf(sz.x, sz.y), maxf(sz.z, 0.001))
		var inst := KitDB.instance(mid, s / body_scale)
		var off: Array = p.get("offset", [0, 0, 0])
		var rot: Array = p.get("rotation", [0, 0, 0])
		inst.position = Vector3(off[0], off[1], off[2]) / body_scale
		inst.rotation_degrees = Vector3(rot[0], rot[1], rot[2])
		ba.add_child(inst)


# --- time -> pose ---------------------------------------------------------------

func pose_at(t: float) -> void:
	var st := state_at(t)
	position = st["pos"]
	rotation = Vector3(0, float(st["yaw"]), 0)
	_play(String(st["action"]), float(st["anim_time"]), float(st["freeze"]))


func _grounded(p: Vector3) -> Vector3:
	return Vector3(p.x, TownGen.ground_height(layout, p.x, p.z), p.z)


func _along(d: float) -> Vector3:
	var r: Dictionary = plan["route"]
	var pts: Array = r["points"]
	var cum: Array = r["cum"]
	for i in range(1, pts.size()):
		if d <= float(cum[i]) or i == pts.size() - 1:
			var seg := float(cum[i]) - float(cum[i - 1])
			var f := 0.0 if seg <= 0.0 else clampf((d - float(cum[i - 1])) / seg, 0.0, 1.0)
			return (pts[i - 1] as Vector3).lerp(pts[i], f)
	return pts[-1]


## {"pos", "yaw", "action", "anim_time", "freeze"} at time t.
func state_at(t: float) -> Dictionary:
	var phase := float(plan.get("phase", 0.0))
	var r: Dictionary = plan.get("route", {})
	if r.is_empty() or t < float(r["start"]):
		return {"pos": _grounded(plan["pos"]), "yaw": plan["yaw"], "action": plan["action"],
			"anim_time": t + phase, "freeze": float(plan.get("freeze", -1.0))}
	var total := float(r["total"])
	var d := (t - float(r["start"])) * float(r["speed"])
	if d < total:
		# Look a little ahead and behind so turns at waypoints are smooth.
		var dir := _along(minf(d + 0.6, total)) - _along(maxf(d - 0.6, 0.0))
		var yaw := atan2(dir.x, dir.z) if dir.length() > 0.01 else float(plan["yaw"])
		var natural := float(Cast.action(String(r["gait"])).get("speed", 1.0))
		# Animation phase follows distance travelled, so feet stay planted.
		return {"pos": _grounded(_along(d)), "yaw": yaw, "action": r["gait"],
			"anim_time": d / natural + phase, "freeze": -1.0}
	var arrive := float(r["start"]) + total / float(r["speed"])
	return {"pos": _grounded(r["points"][-1]), "yaw": r["end_yaw"], "action": r["then"],
		"anim_time": t - arrive, "freeze": float(r.get("then_freeze", -1.0))}


func _play(action_id: String, time: float, freeze: float) -> void:
	var a := Cast.action(action_id)
	var anim := String(a.get("anim", "Idle"))
	var anim_res := ap.get_animation(anim)
	if anim_res == null:
		return
	var length := anim_res.length
	var tt: float
	if freeze >= 0.0:
		tt = clampf(freeze, 0.0, 1.0) * length
	elif bool(a.get("loop", true)):
		tt = fposmod(time, length)
	else:
		tt = clampf(time, 0.0, length - 0.001)
	if ap.current_animation != anim:
		ap.play(anim)
	ap.seek(tt, true)
	ap.advance(0.0)


# --- anchors -----------------------------------------------------------------

func _bone_world(bone: String) -> Vector3:
	var i := int(_bones.get(bone, -1))
	if i < 0:
		return global_position + Vector3.UP * 1.6
	return skeleton.global_transform * Cast.bone_global(skeleton, i).origin


## Anchors other systems can target: "<id>", "<id>.head", "<id>.eyes", "<id>.chest", "<id>.hand".
func anchor_points() -> Dictionary:
	var fwd := Vector3(sin(rotation.y), 0, cos(rotation.y))
	return {
		actor_id: {"pos": global_position, "forward": fwd},
		actor_id + ".head": {"pos": _bone_world("Head") + Vector3.UP * 0.08, "forward": fwd},
		# Just in front of the face: where a point-of-view camera goes.
		actor_id + ".eyes": {"pos": _bone_world("Head") + Vector3.UP * 0.1 + fwd * 0.28, "forward": fwd},
		actor_id + ".chest": {"pos": _bone_world("spine_03"), "forward": fwd},
		actor_id + ".hand": {"pos": _bone_world("hand_r"), "forward": fwd},
	}
