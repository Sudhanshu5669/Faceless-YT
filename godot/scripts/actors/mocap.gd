## Generated motions (library/motions/*.json, written by pipeline/import_motion.py)
## as animations on the mannequin skeleton, so actions play them like any clip and
## the usual retargeting carries them to toons and models.
##
## Source rotations are away from a T-pose facing +Z, in body space, which is the
## mannequin's rest convention too; limb bones are first swung so their rest
## direction matches the source's. The hips travel is part of the clip: the actor
## stays at its "at" point and the body moves forward from there.
extends RefCounted

const Paths = preload("res://scripts/core/paths.gd")

const SKELETON_TRACK := "Armature/Skeleton3D:"
## limb bone -> the child that gives its direction
const LIMB_CHILD := {"upperarm_l": "lowerarm_l", "lowerarm_l": "hand_l", "thigh_l": "calf_l", "calf_l": "foot_l",
	"upperarm_r": "lowerarm_r", "lowerarm_r": "hand_r", "thigh_r": "calf_r", "calf_r": "foot_r"}
## bones that take their parent limb's alignment
const INHERIT := {"hand_l": "lowerarm_l", "hand_r": "lowerarm_r"}


## Adds every motion as "mocap_<name>". `body` is an instance of the mannequin.
static func add_to(lib: AnimationLibrary, body: Node3D, skeleton: Skeleton3D) -> void:
	for name in Paths.list_json("library/motions"):
		var r := Paths.load_json(Paths.repo_path("library/motions/%s.json" % name))
		if not r["ok"]:
			push_error("motion %s: could not read it" % name)
			continue
		lib.add_animation("mocap_" + name, build(r["data"], body, skeleton))


static func _vec(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


static func build(clip: Dictionary, body: Node3D, sk: Skeleton3D) -> Animation:
	# skeleton space -> body space
	var x := Transform3D.IDENTITY
	var n: Node = sk
	while n != null and n != body:
		if n is Node3D:
			x = (n as Node3D).transform * x
		n = n.get_parent()
	var x_rot := x.basis.get_rotation_quaternion()

	var count := sk.get_bone_count()
	var rest: Array = []  # body-space rest rotation per bone
	for b in count:
		rest.append(x_rot * sk.get_bone_global_rest(b).basis.get_rotation_quaternion())
	var align := {}  # bone name -> swing from the mannequin's rest direction to the source's
	for bone in LIMB_CHILD:
		var a := x * sk.get_bone_global_rest(sk.find_bone(bone)).origin
		var c := x * sk.get_bone_global_rest(sk.find_bone(LIMB_CHILD[bone])).origin
		align[bone] = Quaternion((c - a).normalized(), _vec(clip["rest_dir"][bone]).normalized())

	var fps := float(clip["fps"])
	var hips: Array = clip["hips"]
	var frames := hips.size()
	var anim := Animation.new()
	anim.length = float(frames - 1) / fps
	var rot_track := []
	for b in count:
		var track := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(track, NodePath(SKELETON_TRACK + sk.get_bone_name(b)))
		rot_track.append(track)

	var pelvis := sk.find_bone("pelvis")
	var rest_hips := x * sk.get_bone_global_rest(pelvis).origin
	var ratio := rest_hips.y / float(clip["hip_height"])
	var parent := sk.get_bone_parent(pelvis)
	var parent_rest := sk.get_bone_global_rest(parent) if parent >= 0 else Transform3D.IDENTITY
	# Every bone keeps a position key, so nothing is left over from the clip played before.
	var hips_track := -1
	for b in count:
		var track := anim.add_track(Animation.TYPE_POSITION_3D)
		anim.track_set_path(track, NodePath(SKELETON_TRACK + sk.get_bone_name(b)))
		if b == pelvis:
			hips_track = track
		else:
			anim.position_track_insert_key(track, 0.0, sk.get_bone_rest(b).origin)

	var rotations: Dictionary = clip["rotations"]
	for f in frames:
		var time := f / fps
		var global: Array = []
		global.resize(count)
		for b in count:  # parents come first
			var bone := sk.get_bone_name(b)
			var p := sk.get_bone_parent(b)
			var parent_g: Quaternion = x_rot if p < 0 else global[p]
			var g: Quaternion
			if rotations.has(bone):
				var q: Array = rotations[bone][f]
				var delta := Quaternion(float(q[0]), float(q[1]), float(q[2]), float(q[3])).normalized()
				var swing: Quaternion = align.get(INHERIT.get(bone, bone), Quaternion.IDENTITY)
				g = delta * swing * (rest[b] as Quaternion)
			else:
				g = parent_g * sk.get_bone_rest(b).basis.get_rotation_quaternion()
			global[b] = g
			anim.rotation_track_insert_key(rot_track[b], time, (parent_g.inverse() * g).normalized())
		var h := _vec(hips[f])
		var target := Vector3(rest_hips.x, 0.0, rest_hips.z) \
			+ Vector3(h.x, h.y, h.z) * ratio
		anim.position_track_insert_key(hips_track, time, parent_rest.affine_inverse() * (x.affine_inverse() * target))
	return anim
