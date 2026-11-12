## A held pair of binoculars with an eased lift to the actor's eyes.
extends RefCounted

const Motion = preload("res://scripts/timeline/motion.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")

const BINS_SIZE := 0.58
const GRIP := Vector3(0.173, -0.025, 0.043)


static func build() -> Node3D:
	var bins := Reveals.shape_node("binoculars", BINS_SIZE, Color("26313b"))
	bins.name = "binoculars"
	for part in bins.get_children():
		var surface := (part as MeshInstance3D).material_override as StandardMaterial3D
		if surface != null and surface.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA:
			surface.albedo_color = Color(0.11, 0.29, 0.38, 0.93)
			surface.roughness = 0.19
	return bins


static func pose(bins: Node3D, actor, t: float, watch: float, origin: Vector3,
		sight_pitch: float = -0.023, sight_offset: Vector3 = Vector3(0.015, 0.004, -0.028),
		grip_depth: float = GRIP.z) -> void:
	var anchors: Dictionary = actor.anchor_points()
	var eyes: Vector3 = anchors[actor.actor_id + ".face"]["pos"]
	var chest: Vector3 = anchors[actor.actor_id + ".chest"]["pos"]
	var lift := Motion.smooth(Motion.seg(t, watch - 0.39, watch))
	var settle := 0.009 * Motion.wobble(t - watch, 3.5, 8.0)
	var yaw := lerpf(-0.11, 0.06, lift)
	var aim := Basis.from_euler(Vector3(lerpf(0.27, sight_pitch, lift), yaw, -0.025 * (1.0 - lift)))
	var rest := chest + Vector3(0, 0.12, 0.19)
	var sight := eyes + sight_offset + Vector3.UP * settle
	var position := Motion.arc(rest, sight, 0.031, lift)
	bins.position = position - origin
	bins.basis = aim
	var grip_z := lerpf(GRIP.z, grip_depth, lift)
	actor.aim_hand("l", position + aim * Vector3(GRIP.x, GRIP.y, grip_z))
	actor.aim_hand("r", position + aim * Vector3(-GRIP.x, GRIP.y, grip_z))
