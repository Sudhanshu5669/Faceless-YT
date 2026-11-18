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
const Toon = preload("res://scripts/actors/toon.gd")

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
var _stride := 1.0
var _face_mat: ShaderMaterial      # toon face (expressions)
var _expression := ""
## Head anchor: offset above the Head bone, and how far in front of it the eyes are.
var _head_lift := 0.08
var _eyes_fwd := 0.28
var _eyes_lift := 0.1
var _head_r := 0.12
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
	_stride = Cast.stride(character)
	if character.has("toon"):
		var built := Toon.build(body, skeleton, character["toon"])
		retarget = Retarget.new(skeleton, built["skeleton"], "toon", body)
		_face_mat = built["face"]
		_expression = String(character["toon"].get("face", "smug"))
		_head_lift = (float((built["head_center"] as Vector3).y) - float(built["head_bone"])) * hs
		_eyes_lift = _head_lift
		_eyes_fwd = float(built["head_r"]) * hs + 0.05
		_head_r = float(built["head_r"]) * hs
		_attach_props(hs)
		return
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
	# Toons hold props on their own (short-legged) skeleton.
	var sk := retarget.dst if character.has("toon") else skeleton
	for p in character.get("props", []):
		var ba := BoneAttachment3D.new()
		ba.bone_name = String(p.get("bone", "hand_r"))
		sk.add_child(ba)
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

var _pose_t := 0.0


func pose_at(t: float) -> void:
	_pose_t = t
	var st := state_at(t)
	position = st["pos"]
	rotation = Vector3(0, float(st["yaw"]), 0)
	_play(String(st["action"]), float(st["anim_time"]), float(st["freeze"]))
	if _face_mat != null:
		var ex := expression_at(t)
		if ex != _expression:
			_expression = ex
			Toon.apply_face(_face_mat, ex)


## Where the hands are held at scene time t: the last "hands" cue.
func hands_at(t: float) -> String:
	var tau := Cast.warp(plan.get("holds", []), t)
	var h := "none"
	for c in plan.get("cues", []):
		if float(c["tau"]) <= tau and String(c.get("hands", "")) != "":
			h = String(c["hands"])
	return h


## Two-bone arm IK after the animation pose, for held props and the chin rest.
## Pure function of the pose.
func _pose_hands(where: String) -> void:
	var sk: Skeleton3D = retarget.dst if retarget != null else skeleton
	var skw := _world_of(sk)
	var inv := skw.affine_inverse()
	var fwd := Vector3(sin(rotation.y), 0, cos(rotation.y))
	var left := Vector3(cos(rotation.y), 0, -sin(rotation.y))
	var head := bone_world("Head") + Vector3.UP * _head_lift
	var sides := ["r"] if where == "chin" else ["l", "r"]
	for side in sides:
		var sgn := 1.0 if side == "l" else -1.0
		var target: Vector3
		if where == "face":
			target = head + fwd * (_head_r * 1.15) + left * sgn * (_head_r * 0.62) - Vector3.UP * (_head_r * 0.3)
		elif where == "chin":
			target = head + fwd * (_head_r * 0.82) - left * (_head_r * 0.60) - Vector3.UP * (_head_r * 0.68)
		else:
			target = bone_world("spine_03") + fwd * 0.32 + left * sgn * 0.16 - Vector3.UP * 0.05
		_ik_limb(sk, "upperarm_" + side, "lowerarm_" + side, "hand_" + side, inv * target,
			inv.basis * (Vector3.DOWN * 0.7 + left * sgn * 0.7 - fwd * 0.2))


## Aim one arm after pose_at(), for a choreographed handoff or contact.
func aim_hand(side: String, target: Vector3, weight: float = 1.0, shoulder_lift: float = 0.0) -> void:
	if weight <= 0.0:
		return
	var sk: Skeleton3D = retarget.dst if retarget != null else skeleton
	var inv := _world_of(sk).affine_inverse()
	var fwd := Vector3(sin(rotation.y), 0, cos(rotation.y))
	var left := Vector3(cos(rotation.y), 0, -sin(rotation.y))
	var side_sign := 1.0 if side == "l" else -1.0
	var upper := "upperarm_" + side
	if shoulder_lift > 0.0:
		var bone := sk.find_bone(upper)
		if bone >= 0:
			var parent := sk.get_bone_parent(bone)
			var parent_basis := Cast.bone_global(sk, parent).basis if parent >= 0 else Basis.IDENTITY
			var up := parent_basis.inverse() * inv.basis * Vector3.UP
			sk.set_bone_pose_position(bone, sk.get_bone_pose_position(bone) + up * shoulder_lift * weight)
	_ik_limb(sk, upper, "lowerarm_" + side, "hand_" + side, inv * target,
		inv.basis * (Vector3.DOWN + left * side_sign * 0.72 - fwd * 0.26), weight)


## Brace one foot against a surface, with the knee bent toward the given direction.
func aim_foot(side: String, target: Vector3, knee: Vector3) -> void:
	var sk: Skeleton3D = retarget.dst if retarget != null else skeleton
	var inv := _world_of(sk).affine_inverse()
	_ik_limb(sk, "thigh_" + side, "calf_" + side, "foot_" + side, inv * target, inv.basis * knee)


## Lower the chair-sit pose to a floor seat and fold the legs forward.
func sit_on_floor(drop: float, floor_y: float, lean: float = 0.0) -> void:
	body.position.y -= drop
	body.rotation.x = lean
	var sk: Skeleton3D = retarget.dst if retarget != null else skeleton
	var inv := _world_of(sk).affine_inverse()
	var fwd := Vector3(sin(rotation.y), 0, cos(rotation.y))
	var left := Vector3(cos(rotation.y), 0, -sin(rotation.y))
	var base := Vector3(position.x, floor_y, position.z)
	for side in ["l", "r"]:
		var side_sign := 1.0 if side == "l" else -1.0
		var target := base + fwd * (0.20 * _height_scale) + left * side_sign * (0.09 * _height_scale)
		target.y += 0.095 * _height_scale
		_ik_limb(sk, "thigh_" + side, "calf_" + side, "foot_" + side, inv * target,
			inv.basis * (left * side_sign + Vector3.UP * 0.42 + fwd * 0.34))


func _ik_limb(sk: Skeleton3D, upper: String, lower: String, end_bone: String, target: Vector3, pole: Vector3,
		weight: float = 1.0) -> void:
	var iu := sk.find_bone(upper)
	var il := sk.find_bone(lower)
	var ih := sk.find_bone(end_bone)
	if iu < 0 or il < 0 or ih < 0:
		return
	var gu := Cast.bone_global(sk, iu)
	var gl := Cast.bone_global(sk, il)
	var gh := Cast.bone_global(sk, ih)
	var a := gu.origin
	var l1 := a.distance_to(gl.origin)
	var l2 := gl.origin.distance_to(gh.origin)
	var to_t := target - a
	var d := clampf(to_t.length(), absf(l1 - l2) + 0.001, l1 + l2 - 0.001)
	var dir := to_t.normalized()
	# Elbow: law of cosines, bent toward the pole.
	var cos_a := (l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d)
	var bend := (pole - dir * pole.dot(dir)).normalized()
	var elbow := a + dir * (l1 * cos_a) + bend * (l1 * sqrt(maxf(0.0, 1.0 - cos_a * cos_a)))
	var tgt := a + dir * d
	var pu := sk.get_bone_parent(iu)
	var gp := Cast.bone_global(sk, pu) if pu >= 0 else Transform3D.IDENTITY
	var r1 := Quaternion((gl.origin - a).normalized(), (elbow - a).normalized())
	var gu2 := Transform3D(Basis(r1) * gu.basis, a)
	var gl2 := gu2 * sk.get_bone_pose(il)
	var gh2 := gl2 * sk.get_bone_pose(ih)
	var r2 := Quaternion((gh2.origin - gl2.origin).normalized(), (tgt - gl2.origin).normalized())
	var gl3 := Transform3D(Basis(r2) * gl2.basis, gl2.origin)
	var upper_pose := (gp.basis.inverse() * gu2.basis).get_rotation_quaternion()
	var lower_pose := (gu2.basis.inverse() * gl3.basis).get_rotation_quaternion()
	sk.set_bone_pose_rotation(iu, sk.get_bone_pose_rotation(iu).slerp(upper_pose, weight))
	sk.set_bone_pose_rotation(il, sk.get_bone_pose_rotation(il).slerp(lower_pose, weight))


## A toon's expression at scene time t: the last "expression" cue at or before t.
func expression_at(t: float) -> String:
	var tau := Cast.warp(plan.get("holds", []), t)
	var ex := String(character.get("toon", {}).get("face", "smug"))
	for c in plan.get("cues", []):
		if float(c["tau"]) <= tau and String(c.get("expression", "")) != "":
			ex = String(c["expression"])
	return ex


func _grounded(p: Vector3) -> Vector3:
	# "keep_y": feet stay at the point's own height (tiers, galleries, decks built by gags).
	if bool(plan.get("keep_y", false)):
		return p
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
			var natural := float(Cast.action(String(r["gait"])).get("speed", 1.0)) * _stride
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
	body.rotation.x = 0.0
	if retarget != null:
		retarget.apply()
	_pose_head(_head_angles_at(_pose_t))
	var hands := hands_at(_pose_t)
	if hands != "none":
		_pose_hands(hands)


func _head_angles_at(t: float) -> Vector3:
	var tau := Cast.warp(plan.get("holds", []), t)
	var from := Vector3.ZERO
	var to := Vector3.ZERO
	var start := 0.0
	var duration := 0.0
	for cue in plan.get("cues", []):
		var at := float(cue["tau"])
		if at > tau:
			break
		if cue.has("head"):
			from = to if duration <= 0.0 else from.lerp(to, smoothstep(start, start + duration, at))
			to = cue["head"]
			start = at
			duration = float(cue["head_turn"])
	return to if duration <= 0.0 else from.lerp(to, smoothstep(start, start + duration, tau))


func _pose_head(angles: Vector3) -> void:
	if angles.is_zero_approx():
		return
	var sk := skeleton
	var bone_name := "Head"
	if retarget != null and retarget.target_bone(bone_name) != "":
		sk = retarget.dst
		bone_name = retarget.target_bone(bone_name)
	var head := sk.find_bone(bone_name)
	if head < 0:
		return
	var parent := sk.get_bone_parent(head)
	var parent_basis := Cast.bone_global(sk, parent).basis.orthonormalized() if parent >= 0 else Basis.IDENTITY
	var actor_basis := _world_of(self).basis.orthonormalized()
	var skeleton_basis := _world_of(sk).basis.orthonormalized()
	var actor_in_parent := parent_basis.inverse() * skeleton_basis.inverse() * actor_basis
	var offset := actor_in_parent * Basis.from_euler(angles) * actor_in_parent.inverse()
	sk.set_bone_pose_rotation(head, offset.get_rotation_quaternion() * sk.get_bone_pose_rotation(head))


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
		actor_id + ".head": {"pos": bone_world("Head") + Vector3.UP * _head_lift, "forward": fwd},
		# Just in front of the face: where a point-of-view camera goes.
		actor_id + ".eyes": {"pos": bone_world("Head") + Vector3.UP * _eyes_lift + fwd * _eyes_fwd, "forward": fwd},
		# On the face, at eye height: where glasses and binoculars sit.
		actor_id + ".face": {"pos": bone_world("Head") + Vector3.UP * (_head_lift + _head_r * 0.06) + fwd * (_head_r * 0.86), "forward": fwd},
		actor_id + ".chest": {"pos": bone_world("spine_03"), "forward": fwd},
		actor_id + ".hand": {"pos": bone_world("hand_r"), "forward": fwd},
	}
