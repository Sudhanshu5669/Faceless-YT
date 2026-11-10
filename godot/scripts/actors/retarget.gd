## Runtime retargeting: drives a character model's skeleton from the posed
## mannequin skeleton (the Universal Animation Library rig), so every action
## plays on any humanoid model listed in library/rigs.json.
##
## Both rigs rest in a T-pose facing +Z. For each mapped bone, its rotation
## away from rest is taken in body space on the source and applied in body
## space on the target (unmapped target bones keep their rest). The hips move
## with the source hips, scaled by leg length. Pure function of the source
## pose, so actors stay deterministic.
extends RefCounted

const Paths = preload("res://scripts/core/paths.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")

static var _rigs: Dictionary = {}

var src: Skeleton3D
var dst: Skeleton3D
var _map := {}            # dst bone index -> src bone index
var _names := {}          # src bone name -> dst bone name
var _src_rest_inv := {}   # src index -> inverse body-space rest rotation
var _dst_rest: Array = [] # dst index -> body-space rest rotation
var _dst_rest_local: Array = []
var _xs_rot: Quaternion
var _xd_rot: Quaternion
var _xs: Transform3D
var _xd: Transform3D
var _src_hips := -1
var _dst_hips := -1
var _hip_ratio := 1.0


static func rigs() -> Dictionary:
	if _rigs.is_empty():
		var r := Paths.load_json(Paths.repo_path("library/rigs.json"))
		_rigs = r["data"]["rigs"] if r["ok"] else {}
	return _rigs


## Rig id for a catalog model, or "" if no rig covers its pack.
static func rig_for(model_id: String) -> String:
	var pack := model_id.get_slice("/", 0)
	for id in rigs():
		if pack in rigs()[id]["packs"]:
			return id
	return ""


## Transform from a node's space up to (not including) `top`.
static func _chain(n: Node, top: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	while n != null and n != top:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


func _init(src_sk: Skeleton3D, dst_sk: Skeleton3D, rig_id: String, body: Node3D) -> void:
	src = src_sk
	dst = dst_sk
	_xs = _chain(src, body)
	_xd = _chain(dst, body)
	_xs_rot = _xs.basis.get_rotation_quaternion()
	_xd_rot = _xd.basis.get_rotation_quaternion()
	var bones: Dictionary = rigs()[rig_id]["bones"]
	for s_name in bones:
		var s := src.find_bone(String(s_name))
		var d := dst.find_bone(String(bones[s_name]))
		if s < 0 or d < 0:
			continue
		_map[d] = s
		_names[String(s_name)] = String(bones[s_name])
		_src_rest_inv[s] = (_xs_rot * src.get_bone_global_rest(s).basis.get_rotation_quaternion()).inverse()
	for d in dst.get_bone_count():
		_dst_rest.append(_xd_rot * dst.get_bone_global_rest(d).basis.get_rotation_quaternion())
		_dst_rest_local.append(dst.get_bone_rest(d))
	_src_hips = src.find_bone("pelvis")
	_dst_hips = dst.find_bone(String(bones.get("pelvis", "")))
	if _src_hips >= 0 and _dst_hips >= 0:
		var sh := (_xs * src.get_bone_global_rest(_src_hips).origin).y
		var dh := (_xd * dst.get_bone_global_rest(_dst_hips).origin).y
		_hip_ratio = dh / sh if sh > 0.001 else 1.0


## Target bone name for a source (mannequin) bone name, or "".
func target_bone(src_name: String) -> String:
	return _names.get(src_name, "")


func apply() -> void:
	# Source globals (skeleton space), computed from poses, parents first.
	var n_src := src.get_bone_count()
	var sg: Array = []
	sg.resize(n_src)
	for b in n_src:
		var q := src.get_bone_pose_rotation(b)
		var p := src.get_bone_parent(b)
		sg[b] = q if p < 0 else (sg[p] as Quaternion) * q
	var n_dst := dst.get_bone_count()
	var dg: Array = []
	dg.resize(n_dst)
	for d in n_dst:
		var p := dst.get_bone_parent(d)
		var pg: Quaternion = _xd_rot if p < 0 else dg[p]
		var g: Quaternion
		if _map.has(d):
			var s: int = _map[d]
			var delta: Quaternion = (_xs_rot * (sg[s] as Quaternion)) * (_src_rest_inv[s] as Quaternion)
			g = delta * (_dst_rest[d] as Quaternion)
		else:
			g = pg * (_dst_rest_local[d] as Transform3D).basis.get_rotation_quaternion()
		dg[d] = g
		dst.set_bone_pose_rotation(d, (pg.inverse() * g).normalized())
		dst.set_bone_pose_position(d, (_dst_rest_local[d] as Transform3D).origin)
	if _src_hips >= 0 and _dst_hips >= 0:
		var now := _xs * _global(src, _src_hips).origin
		var rest := _xs * src.get_bone_global_rest(_src_hips).origin
		var target := _xd * dst.get_bone_global_rest(_dst_hips).origin + (now - rest) * _hip_ratio
		var p := dst.get_bone_parent(_dst_hips)
		var parent_g := _global(dst, p) if p >= 0 else Transform3D.IDENTITY
		dst.set_bone_pose_position(_dst_hips, parent_g.affine_inverse() * (_xd.affine_inverse() * target))


## Skeleton-space transform of a bone from current poses (never stale).
static func _global(sk: Skeleton3D, bone: int) -> Transform3D:
	var t := sk.get_bone_pose(bone)
	var p := sk.get_bone_parent(bone)
	while p >= 0:
		t = sk.get_bone_pose(p) * t
		p = sk.get_bone_parent(p)
	return t
