## Measures the real ground speed of every gait in library/actions.json, so a
## walking actor's animation phase can be driven by distance (no foot sliding).
## Speed = average backward velocity of whichever foot is planted (lowest).
##   godot --headless --path godot --script res://tools/locomotion_probe.gd
extends SceneTree

const Paths = preload("res://scripts/core/paths.gd")
const Cast = preload("res://scripts/actors/cast.gd")

const SAMPLES := 120


func _initialize() -> void:
	var path := Paths.repo_path("library/actions.json")
	var data: Dictionary = Paths.load_json(path)["data"]
	var body := Cast.body_instance("male")
	root.add_child(body)
	var ap: AnimationPlayer = body.find_child("AnimationPlayer", true, false)
	var sk: Skeleton3D = body.find_child("Skeleton3D", true, false)
	ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var foot_l := sk.find_bone("ball_l")
	var foot_r := sk.find_bone("ball_r")
	for id in data["actions"]:
		var a: Dictionary = data["actions"][id]
		if not a.get("gait", false):
			continue
		var anim := String(a["anim"])
		var length := ap.get_animation(anim).length
		var dt := length / SAMPLES
		# Pass 1: sample both feet. Pass 2: average the backward velocity of a
		# foot only while it is on the ground (within 3 cm of its lowest point),
		# so flight phases of a run don't count.
		var pls := []
		var prs := []
		for i in SAMPLES + 1:
			ap.play(anim)
			ap.seek(i * dt, true)
			ap.advance(0.0)
			pls.append(Cast.bone_global(sk, foot_l).origin)
			prs.append(Cast.bone_global(sk, foot_r).origin)
		var floor_y := INF
		for p in pls + prs:
			floor_y = minf(floor_y, p.y)
		# Stance stride: while a foot is grounded it travels backward at ground
		# speed, so speed = (backward travel while grounded) / (time grounded).
		var travel := 0.0
		var grounded_time := 0.0
		for feet in [pls, prs]:
			var zs := []
			for i in SAMPLES:
				if feet[i].y < floor_y + 0.04:
					zs.append(feet[i].z)
			if zs.size() > 2:
				travel += zs.max() - zs.min()
				grounded_time += zs.size() * dt
		var total := travel
		var n := 1
		if grounded_time > 0.0:
			total = travel / grounded_time
		var speed := snappedf(total / maxi(n, 1), 0.01)
		print("%-14s %-18s length %.2fs  measured %.2f m/s (was %s)" % [id, anim, length, speed, a.get("speed")])
		if speed > 0.1:
			a["speed"] = speed
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  ", false))
	f.close()
	body.free()
	quit()
