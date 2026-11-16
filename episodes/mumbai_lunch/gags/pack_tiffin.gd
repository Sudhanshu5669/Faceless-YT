extends RefCounted
## A steel tiffin, packed and latched by the cook before she shows the painted lid.

const Motion = preload("res://scripts/timeline/motion.gd")
const Meshes = preload("res://scripts/world/builders/kitchen_dressing.gd")
const Tiffin = preload("res://scripts/world/builders/steel_tiffin.gd")
const ROTI_START := Vector3(0.233, 0.036, 0.018)
const ROTI_END := Vector3(0, 0.185, 0)

func build(_gag: Dictionary) -> Node3D:
	var root := Node3D.new()
	var carrier := Tiffin.build()
	carrier.name = "carrier"
	root.add_child(carrier)
	var roti := Tiffin._disc(root, 0.080, 0.010, ROTI_START, Meshes.material(Color("#d4ac6f"), 0.92))
	roti.name = "roti"
	roti.scale.z = 0.64
	var blister := Meshes.material(Color("#ad7747"), 1.0)
	for mark in [Vector2(-0.035, 0.02), Vector2(0.025, -0.018), Vector2(0.039, 0.022), Vector2(0.0, 0.04)]:
		Tiffin._disc(roti, 0.007, 0.001, Vector3(mark.x, 0.0052, mark.y), blister)
	return root


func pose(root: Node3D, gag: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = gag["params"]
	var fold := float(p["fold"])
	var click := float(p["click"])
	var show := float(p["show"])
	var carrier := root.get_node("carrier") as Node3D
	var lid := carrier.get_node("lid") as Node3D
	var latch := carrier.get_node("latch") as Node3D
	var roti := root.get_node("roti") as Node3D
	var pack := Motion.smooth(Motion.seg(t, fold - 0.71, fold))
	roti.position = ROTI_START.lerp(ROTI_END, pack) + Vector3.UP * (sin(PI * pack) * 0.21)
	roti.rotation.z = sin(PI * pack) * 0.17
	var close := Motion.smooth(Motion.seg(t, click - 0.86, click - 0.18))
	lid.position = Motion.arc(Vector3(-0.058, 0.310, -0.035), Vector3(0, Tiffin.LID_HEIGHT, 0), 0.044, close)
	lid.rotation.z = -sin(PI * close) * 0.18
	latch.rotation.z = lerpf(-0.85, 0.0, Motion.out_cubic(Motion.seg(t, click - 0.18, click)))
	latch.rotation.z -= sin(maxf(t - click, 0.0) * 33.0) * 0.055 * exp(-13.0 * maxf(t - click, 0.0))
	var lift := Motion.smooth(Motion.seg(t, show - 0.45, show + 0.07))
	carrier.position = Vector3(0, lift * 0.062, lift * 0.025)
	carrier.rotation.x = lift * 0.53
	carrier.rotation.y = lift * 0.33
	var settle := maxf(t - show - 0.07, 0.0)
	carrier.rotation.x += 0.022 * sin(settle * 15.0) * exp(-5.0 * settle)
	roti.visible = t < show - 0.45
	var holder := ctx["holder"] as Node3D
	if ctx.has("actor"):
		var cook = ctx["actor"].call("packer")
		if cook != null:
			var pack_weight := Motion.smooth(Motion.seg(t, fold - 1.09, fold - 0.71))
			pack_weight *= 1.0 - Motion.smooth(Motion.seg(t, fold + 0.02, fold + 0.32))
			var carry_weight := Motion.smooth(Motion.seg(t, show - 0.7, show - 0.45))
			var grip := carrier.position + carrier.basis * Vector3(-0.048, Tiffin.HANDLE_HEIGHT + 0.013, 0.022)
			cook.aim_hand("l", holder.position + roti.position + Vector3(0, 0.026, -0.022), pack_weight)
			cook.aim_hand("r", holder.position + grip, carry_weight, 0.05)
			var close_weight := 1.0
			close_weight *= 1.0 - Motion.smooth(Motion.seg(t, click + 0.09, click + 0.37))
			var latch_grip := latch.position + latch.basis * Vector3(0.027, 0.057, 0.018)
			cook.aim_hand("r", holder.position + lid.position + lid.basis * Vector3(-0.062, 0.052, 0.032),
				close_weight * (1.0 - Motion.smooth(Motion.seg(t, click - 0.18, click + 0.01))))
			cook.aim_hand("l", holder.position + latch_grip,
				close_weight * Motion.smooth(Motion.seg(t, click - 0.40, click - 0.15)))
			var support := carrier.position + carrier.basis * Vector3(0.111, 0.088, 0.068)
			cook.aim_hand("l", holder.position + support, carry_weight)
	return {"focus": holder.position + Vector3(0.025 - lift * 0.025, 0.20 + lift * 0.115, 0)}
