## One actor: a character body posed deterministically by time.
##
## pose_at(t) is a pure function of t: the same t always gives the same
## position, facing and skeleton pose, whatever was posed before. Stills,
## the live explore window and (later) video renders all call it.
extends Node3D

const Cast = preload("res://scripts/actors/cast.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const SetBuilder = preload("res://scripts/world/set_builder.gd")
const Retarget = preload("res://scripts/actors/retarget.gd")

static var _materials: Dictionary = {}
## Seconds to turn to a new facing (cue "turn" overrides; also used on arrival).
const TURN_TIME := 0.6

var actor_id := ""
var character: Dictionary
var plan: Dictionary
var layout: Dictionary
var body: Node3D
var ap: AnimationPlayer
var skeleton: Skeleton3D          # the mannequin's: animations and blends pose this one
var retarget: Retarget            # set when the character has a model
var _bones := {}
var _height_scale := 1.0
## id -> actor node for everyone in the scene (set by ActorDirector.build).
var peers: Dictionary = {}


func setup(id: String, char_id: String, p: Dictionary, L: Dictionary) -> void:
	actor_id = id
	name = id
	character = Cast.character(char_id)
	plan = p
	layout = L
	var model := String(character.get("model", ""))
	body = Cast.body_instance(String(character.get("body", "male")), model)
	body.name = "body"
	var hs := float(character.get("height", Cast.BASE_HEIGHT)) / Cast.BASE_HEIGHT
	_height_scale = hs
	var ws := float(character.get("width", 1.0))
	body.scale = Vector3(hs * ws, hs, hs * ws)
	add_child(body)
	ap = body.find_child("AnimationPlayer", true, false)
	skeleton = body.get_node(Cast.MANNEQUIN_SKELETON) as Skeleton3D
	if model != "":
		retarget = Retarget.new(skeleton, Cast.model_skeleton(body, model), Retarget.rig_for(model), body)
	_apply_colors(char_id)
	_attach_props(hs)


func _apply_colors(char_id: String) -> void:
	var cols: Dictionary = character.get("colors", {})
	var glow := float(character.get("glow", 0.0))
	if retarget != null:
		_apply_model_colors(char_id, cols)
		return
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


## Character models: "colors" repaint materials by name ({"Suit": "#5a3a2a"}).
func _apply_model_colors(char_id: String, cols: Dictionary) -> void:
	for mi in body.get_node("model").find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (mi as MeshInstance3D).mesh
		for s in mesh.get_surface_count():
			var m := mesh.surface_get_material(s) as BaseMaterial3D
			if m == null or not cols.has(String(m.resource_name)):
				continue
			var key := "%s|%s" % [char_id, m.resource_name]
			if not _materials.has(key):
				var nm: BaseMaterial3D = m.duplicate()
				nm.albedo_color = Color(String(cols[String(m.resource_name)]))
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
	return Vector3(p.x, SetBuilder.ground_height(layout, p.x, p.z), p.z)


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


## {"pos", "yaw", "action", "anim_time", "freeze"} at scene time t.
## Holds stop the actor's own clock (tau); then the latest of "arrived at the
## end of the route" and each cue decides what the actor is doing.
func state_at(t: float) -> Dictionary:
	return _state(t, true)


## Where the actor stands at scene time t (never looks at other actors, so
## actors that face each other can't recurse).
func position_at(t: float) -> Vector3:
	return _state(t, false)["pos"]


## Scene time whose world the actor sees at t: while held, the moment the hold
## began (a frozen actor doesn't keep tracking someone who moves).
func _seen_time(t: float) -> float:
	for h in plan.get("holds", []):
		if t >= float(h[0]) and t < float(h[1]):
			return float(h[0])
	return t


## Yaw toward actor `id` as seen at scene time t, or `fallback`.
func _face(id: String, from: Vector3, fallback: float, t: float, track: bool) -> float:
	if not track or id == "" or not peers.has(id) or peers[id] == self:
		return fallback
	var d: Vector3 = peers[id].position_at(_seen_time(t)) - from
	return atan2(d.x, d.z) if Vector2(d.x, d.z).length() > 0.05 else fallback


static func _turn(from_yaw: float, to_yaw: float, elapsed: float, duration: float) -> float:
	if duration <= 0.0 or elapsed >= duration:
		return to_yaw
	return lerp_angle(from_yaw, to_yaw, smoothstep(0.0, 1.0, elapsed / duration))


func _state(t: float, track: bool) -> Dictionary:
	var tau := Cast.warp(plan.get("holds", []), t)
	var phase := float(plan.get("phase", 0.0))
	var r: Dictionary = plan.get("route", {})
	var start_pos := _grounded(plan["pos"])
	var st := {"pos": start_pos, "yaw": _face(String(plan.get("face", "")), start_pos, float(plan["yaw"]), t, track),
		"action": plan["action"], "anim_time": tau + phase, "freeze": float(plan.get("freeze", -1.0))}
	var latest := -INF
	if not r.is_empty() and tau >= float(r["start"]):
		var total := float(r["total"])
		var d := (tau - float(r["start"])) * float(r["speed"])
		if d < total:
			# Look a little ahead and behind so turns at waypoints are smooth.
			var dir := _along(minf(d + 0.6, total)) - _along(maxf(d - 0.6, 0.0))
			var yaw := atan2(dir.x, dir.z) if dir.length() > 0.01 else float(plan["yaw"])
			var natural := float(Cast.action(String(r["gait"])).get("speed", 1.0))
			# Animation phase follows distance travelled, so feet stay planted.
			return {"pos": _grounded(_along(d)), "yaw": yaw, "action": r["gait"],
				"anim_time": d / natural + phase, "freeze": -1.0}
		var arrive := float(r["start"]) + total / float(r["speed"])
		var end_pos := _grounded(r["points"][-1])
		var end_yaw := _face(String(r.get("then_face", "")), end_pos, float(r["end_yaw"]), t, track)
		st = {"pos": end_pos, "action": r["then"], "anim_time": tau - arrive,
			"yaw": _turn(float(r.get("arrive_yaw", r["end_yaw"])), end_yaw, tau - arrive, TURN_TIME),
			"freeze": float(r.get("then_freeze", -1.0))}
		latest = arrive
	for c in plan.get("cues", []):
		var ct := float(c["tau"])
		if ct > tau or ct < latest:
			continue
		latest = ct
		if String(c["action"]) != "":
			st["action"] = c["action"]
			st["anim_time"] = tau - ct
			st["freeze"] = float(c["freeze"])
		if c["yaw"] != null:
			var target := _face(String(c.get("face", "")), st["pos"], float(c["yaw"]), t, track)
			st["yaw"] = _turn(float(st["yaw"]), target, tau - ct, float(c.get("turn", TURN_TIME)))
	return st


func _play(action_id: String, time: float, freeze: float) -> void:
	var cp := Cast.clip_plan(action_id)
	if cp.is_empty() or cp.has("error"):
		return
	var length := float(cp["length"])
	var tt: float
	if freeze >= 0.0:
		tt = clampf(freeze, 0.0, 1.0) * length
	elif bool(cp["loop"]):
		tt = fposmod(time, length)
	else:
		tt = clampf(time, 0.0, length - 0.001)
	var segs: Array = cp["segments"]
	var i := segs.size() - 1
	while i > 0 and tt < float(segs[i]["start"]):
		i -= 1
	var seg: Dictionary = segs[i]
	var local := tt - float(seg["start"])
	var blend := float(seg["blend"])
	if i > 0 and blend > 0.0 and local < blend:
		# Crossfade from the previous segment's last pose.
		var prev: Dictionary = segs[i - 1]
		_seek(String(prev["anim"]), _clip_time(prev, float(prev["dur"])))
		var from_pose := _capture_pose()
		_seek(String(seg["anim"]), _clip_time(seg, local))
		_mix_pose(from_pose, smoothstep(0.0, 1.0, local / blend))
	else:
		_seek(String(seg["anim"]), _clip_time(seg, local))
	body.position = Vector3(0, Cast.lift_at(cp, tt) * _height_scale, 0)
	if retarget != null:
		retarget.apply()


static func _clip_time(seg: Dictionary, local: float) -> float:
	var dur := float(seg["dur"])
	var f := 1.0 if dur <= 0.0 else clampf(local / dur, 0.0, 1.0)
	return lerpf(float(seg["from"]), float(seg["to"]), f)


func _seek(anim: String, clip_t: float) -> void:
	if ap.current_animation != anim:
		ap.play(anim)
	ap.seek(clip_t, true)
	ap.advance(0.0)


func _capture_pose() -> Array:
	var out := []
	for b in skeleton.get_bone_count():
		out.append([skeleton.get_bone_pose_position(b), skeleton.get_bone_pose_rotation(b),
			skeleton.get_bone_pose_scale(b)])
	return out


func _mix_pose(from_pose: Array, w: float) -> void:
	for b in skeleton.get_bone_count():
		var p: Array = from_pose[b]
		skeleton.set_bone_pose_position(b, (p[0] as Vector3).lerp(skeleton.get_bone_pose_position(b), w))
		skeleton.set_bone_pose_rotation(b, (p[1] as Quaternion).slerp(skeleton.get_bone_pose_rotation(b), w))
		skeleton.set_bone_pose_scale(b, (p[2] as Vector3).lerp(skeleton.get_bone_pose_scale(b), w))


# --- anchors -----------------------------------------------------------------

## World transform from the local transform chain. Node3D global transforms
## update lazily, so right after pose_at() (before a frame runs) they can lag.
static func _world_of(n: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	while n is Node3D:
		t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


## World position of a skeleton bone, exact right after pose_at().
## Bones are named as on the mannequin; with a model, the matching model bone is used.
func bone_world(bone: String) -> Vector3:
	var sk := skeleton
	var name_on := bone
	if retarget != null and retarget.target_bone(bone) != "":
		sk = retarget.dst
		name_on = retarget.target_bone(bone)
	var key := "%s|%s" % [sk.get_instance_id(), name_on]
	if not _bones.has(key):
		_bones[key] = sk.find_bone(name_on)
	var i := int(_bones[key])
	if i < 0:
		return _world_of(self).origin + Vector3.UP * 1.6
	return _world_of(sk) * Cast.bone_global(sk, i).origin


## Anchors other systems can target: "<id>", "<id>.head", "<id>.eyes", "<id>.chest", "<id>.hand".
func anchor_points() -> Dictionary:
	var fwd := Vector3(sin(rotation.y), 0, cos(rotation.y))
	return {
		actor_id: {"pos": _world_of(self).origin, "forward": fwd},
		actor_id + ".head": {"pos": bone_world("Head") + Vector3.UP * 0.08, "forward": fwd},
		# Just in front of the face: where a point-of-view camera goes.
		actor_id + ".eyes": {"pos": bone_world("Head") + Vector3.UP * 0.1 + fwd * 0.28, "forward": fwd},
		actor_id + ".chest": {"pos": bone_world("spine_03"), "forward": fwd},
		actor_id + ".hand": {"pos": bone_world("hand_r"), "forward": fwd},
	}
