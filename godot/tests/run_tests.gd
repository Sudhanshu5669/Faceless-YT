## Headless test runner. No addons needed.
##   godot --headless --path godot --script res://tests/run_tests.gd
extends SceneTree

const TownGen = preload("res://scripts/world/generators/town_generator.gd")
const SetBuilder = preload("res://scripts/world/set_builder.gd")
const Spec = preload("res://scripts/core/spec.gd")
const LookCompiler = preload("res://scripts/look/look_compiler.gd")
const Kit = preload("res://scripts/world/prop_kit.gd")
const Views = preload("res://scripts/camera/views.gd")
const Shot = preload("res://scripts/camera/shot.gd")
const Anchors = preload("res://scripts/camera/anchors.gd")
const KitDB = preload("res://scripts/world/kit_db.gd")
const Cast = preload("res://scripts/actors/cast.gd")
const ActorDirector = preload("res://scripts/actors/actor_director.gd")
const Episode = preload("res://scripts/timeline/episode.gd")
const Paths = preload("res://scripts/core/paths.gd")
const SetEvents = preload("res://scripts/timeline/set_events.gd")
const Toon = preload("res://scripts/actors/toon.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const SEEDS := [1, 333, 9001]
const PARAM_SETS := [
	{},
	{"blocks_x": 1, "blocks_z": 1},
	{"blocks_x": 5, "blocks_z": 3, "lot_w": 12.0},
	{"block_d": 40.0, "block_w": 30.0},
	{"exit_roads": false, "forest_band": 0.0, "house_density": 0.5},
]

var _passed := 0
var _failed := 0


var _started := false


func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	_run_all()
	return false


func _run_all() -> void:
	print("[TownForge] running Godot tests")
	_run("layout is identical for the same seed", _t_deterministic)
	_run("different seeds give different towns", _t_seed_changes)
	_run("houses stay inside their lots and never overlap", _t_houses_valid)
	_run("every house has a unique address and all anchors", _t_addresses)
	_run("trees avoid houses, driveways and walkways", _t_trees_clear)
	_run("streetlights avoid driveways and intersections", _t_lights_clear)
	_run("param validation catches typos and bad ranges", _t_param_validation)
	_run("sample specs in specs/sets validate", _t_sample_specs)
	_run("all look presets compile", _t_looks)
	_run("look validation catches typos and bad values", _t_look_validation)
	_run("time model: day is lit by the sun, night by moon + streetlights", _t_time_model)
	_run("weather: rain wets roads, snow covers lawns, clouds dim the sun", _t_weather)
	_run("inline absurd look with base + overrides compiles", _t_absurd_inline)
	_run("every anchor named in the manifest resolves", _t_anchors)
	_run("every shot template frames every test town", _t_shot_templates)
	_run("shot validation catches unknown keys and anchors", _t_shot_errors)
	_run("every named view frames every test town", _t_views)
	_run("builder creates named nodes for a full town", _t_builder_smoke)
	_run("kits reference only catalogued models", _t_kits)
	_run("kit houses take their size from the model", _t_kit_houses)
	_run("primitive kit still builds without assets", _t_primitive_kit)
	_run("every action maps to an animation; gaits have speeds", _t_actions)
	_run("all characters are valid", _t_characters)
	_run("actor validation catches bad characters, actions, keys", _t_actor_validation)
	_run("pose_at(t) is a pure function of t", _t_actor_pose_deterministic)
	_run("character models: retargeted pose follows the mannequin, deterministic", _t_retarget)
	_run("routes: wait, walk at speed, arrive and switch action", _t_actor_route)
	_run("jump leaves the ground at apex and lands on its feet", _t_jump)
	_run("crowds expand deterministically with unique ids", _t_crowd)
	_run("actor anchors work as camera targets", _t_actor_anchors_for_cameras)
	_run("cues switch actions; holds freeze the actor's clock", _t_cues_holds)
	_run("facing an actor tracks them and turns smoothly", _t_facing_tracks)
	_run("episode validation catches bad shots and moves", _t_episode_validation)
	_run("episode timeline: frames, cuts and scene_t jumps", _t_episode_timeline)
	_run("camera moves start at 'from' and end at 'to'", _t_camera_move)
	_run("sample episodes in episodes/ validate", _t_sample_episodes)
	_run("supermarket: deterministic, anchors, shelves occlude, switchable toys", _t_supermarket)
	_run("supermarket kit: segments tile the aisles, toys on real boards, primitive fallback", _t_supermarket_kit)
	_run("downtown: deterministic, anchors, lots in blocks, tiles clear of crossings, walkways", _t_downtown)
	_run("toons: faces valid, short legs, retargeted, expressions follow cues", _t_toons)
	_run("reveals: validation, enter/exit timing, counters land on time", _t_reveals)
	_run("motion: easings hit their ends, squash keeps volume, shake is pure and decays", _t_motion)
	print("[TownForge] tests: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _run(test_name: String, fn: Callable) -> void:
	var errors: Array = fn.call()
	if errors.is_empty():
		_passed += 1
		print("  PASS  " + test_name)
	else:
		_failed += 1
		print("  FAIL  " + test_name)
		for e in errors.slice(0, 8):
			print("        - " + str(e))
		if errors.size() > 8:
			print("        ... and %d more" % (errors.size() - 8))


func _all_layouts() -> Array:
	var out := []
	for s in SEEDS:
		for p in PARAM_SETS:
			out.append({"tag": "seed %d params %s" % [s, p], "L": TownGen.generate(p, s)})
	return out


func _t_deterministic() -> Array:
	for p in PARAM_SETS:
		if JSON.stringify(TownGen.generate(p, 333)) != JSON.stringify(TownGen.generate(p, 333)):
			return ["two generations with seed 333 differ for params %s" % [p]]
	return []


func _t_seed_changes() -> Array:
	if JSON.stringify(TownGen.generate({}, 333)) == JSON.stringify(TownGen.generate({}, 334)):
		return ["seed 333 and 334 produced identical towns"]
	return []


func _t_houses_valid() -> Array:
	var e := []
	for item in _all_layouts():
		var L: Dictionary = item["L"]
		var grass := []
		for blk in L["blocks"]:
			grass.append(TownGen.grow(blk["grass"], 0.01))
		var houses: Array = L["houses"]
		for h in houses:
			var inside := false
			for g in grass:
				var r: Array = h["rect"]
				if r[0] >= g[0] and r[1] >= g[1] and r[2] <= g[2] and r[3] <= g[3]:
					inside = true
					break
			if not inside:
				e.append("%s: %s rect %s is not inside any block's grass" % [item["tag"], h["id"], h["rect"]])
		for i in houses.size():
			for j in range(i + 1, houses.size()):
				if TownGen.rects_overlap(houses[i]["rect"], houses[j]["rect"]):
					e.append("%s: %s overlaps %s" % [item["tag"], houses[i]["id"], houses[j]["id"]])
	return e


func _t_addresses() -> Array:
	var e := []
	for item in _all_layouts():
		var L: Dictionary = item["L"]
		var seen := {}
		for h in L["houses"]:
			var a: String = h["address"]
			if a == "":
				e.append("%s: %s has no address" % [item["tag"], h["id"]])
			elif seen.has(a):
				e.append("%s: duplicate address '%s'" % [item["tag"], a])
			seen[a] = true
			for k in ["front_door", "lawn", "driveway", "backyard", "curb"]:
				if not h["anchors"].has(k):
					e.append("%s: %s missing anchor %s" % [item["tag"], h["id"], k])
	return e


func _t_trees_clear() -> Array:
	var e := []
	for item in _all_layouts():
		var L: Dictionary = item["L"]
		var blockers := []
		for h in L["houses"]:
			blockers.append(h["rect"])
		for d in L["driveways"]:
			blockers.append(d["rect"])
		for w in L["walkways"]:
			blockers.append(w["rect"])
		for t in L["trees"]:
			for r in blockers:
				if TownGen.in_rect(t["pos"][0], t["pos"][2], r):
					e.append("%s: tree at %s inside %s" % [item["tag"], t["pos"], r])
	return e


func _t_lights_clear() -> Array:
	var e := []
	for item in _all_layouts():
		var L: Dictionary = item["L"]
		var drives := []
		for d in L["driveways"]:
			drives.append(d["rect"])
		var p: Dictionary = L["params"]
		var half: float = float(p["road_w"]) / 2.0
		for l in L["streetlights"]:
			var x: float = l["pos"][0]
			var z: float = l["pos"][2]
			for r in drives:
				if TownGen.in_rect(x, z, r):
					e.append("%s: %s stands on a driveway" % [item["tag"], l["id"]])
			for it in L["intersections"]:
				if absf(x - float(it["pos"][0])) < half and absf(z - float(it["pos"][2])) < half:
					e.append("%s: %s stands in intersection %s" % [item["tag"], l["id"], it["id"]])
	return e


func _t_param_validation() -> Array:
	var e := []
	if TownGen.validate_params({"block_x": 3}).is_empty():
		e.append("typo 'block_x' was not reported")
	if TownGen.validate_params({"blocks_x": 50}).is_empty():
		e.append("blocks_x=50 was not reported as out of range")
	if TownGen.validate_params({"exit_roads": 1}).is_empty():
		e.append("exit_roads=1 (not a bool) was not reported")
	if not TownGen.validate_params({"blocks_x": 2, "tree_density": 1.2}).is_empty():
		e.append("valid params were rejected")
	if Spec.validate_set_spec({"schema_version": "0.1", "set": {"generator": "castle", "seed": 1}, "look": "day"}).is_empty():
		e.append("unknown generator 'castle' was not reported")
	if Spec.validate_set_spec({"schema_version": "0.1", "set": {"generator": "town", "seed": 1}, "look": "no_such_look"}).is_empty():
		e.append("unknown look was not reported")
	return e


func _t_sample_specs() -> Array:
	var e := []
	var dir := Spec.repo_path("specs/sets")
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".json"):
			continue
		var r := Spec.load_json(dir.path_join(f))
		if not r["ok"]:
			e.append(r["error"])
			continue
		for err in Spec.validate_set_spec(r["data"]):
			e.append("%s: %s" % [f, err])
	return e


func _t_looks() -> Array:
	var e := []
	var looks := LookCompiler.list_presets()
	if looks.size() < 3:
		return ["expected at least 3 look presets, found %d" % looks.size()]
	for id in looks:
		var r := LookCompiler.compile(id)
		if not r["ok"]:
			e.append("%s: %s" % [id, r["errors"]])
		elif r["raw"].get("id", "") != id:
			e.append("look file %s.json has id '%s'" % [id, r["raw"].get("id", "")])
	return e


func _t_look_validation() -> Array:
	var e := []
	var cases := [
		[{"sky": {"topp": "#000000"}}, "typo sky.topp"],
		[{"sun": {"color": "red-ish"}}, "invalid colour"],
		[{"weather": {"rain": 3}}, "rain out of 0..1"],
		[{"time": "25:99:00"}, "bad time"],
		[{"base": "no_such_look"}, "unknown base"],
		[{"sky": {"bodies": [{"kind": "comet"}]}}, "unknown body kind"],
	]
	for c in cases:
		if LookCompiler.compile(c[0])["ok"]:
			e.append("not reported: " + c[1])
	if absf(LookCompiler.parse_time("03:33") - 3.55) > 0.001:
		e.append("parse_time('03:33') = %s" % LookCompiler.parse_time("03:33"))
	return e


func _t_time_model() -> Array:
	var e := []
	var day: Dictionary = LookCompiler.compile({"time": "13:00"})["look"]
	var night: Dictionary = LookCompiler.compile({"time": "03:00"})["look"]
	if float(day["sun"]["elevation"]) < 30.0 or float(day["sun"]["energy"]) < 1.0:
		e.append("13:00 sun too low/dim: %s" % [day["sun"]])
	if float(day["practical_lights"]["level"]) > 0.0:
		e.append("streetlights on at 13:00")
	if float(night["sun"]["energy"]) > 0.0:
		e.append("sun shining at 03:00")
	if float(night["moon"]["energy"]) <= 0.0 or float(night["moon"]["elevation"]) <= 0.0:
		e.append("no moon at 03:00: %s" % [night["moon"]])
	if float(night["practical_lights"]["level"]) < 1.0:
		e.append("streetlights not fully on at 03:00")
	return e


func _t_weather() -> Array:
	var e := []
	var clear: Dictionary = LookCompiler.compile({"time": 12})["look"]
	var rain: Dictionary = LookCompiler.compile({"time": 12, "weather": {"rain": 1.0}})["look"]
	var snow: Dictionary = LookCompiler.compile({"time": 12, "weather": {"snow": 1.0}})["look"]
	if float(rain["surface"]["wetness"]) < 0.9:
		e.append("rain=1 wetness %s" % rain["surface"]["wetness"])
	if float(rain["sun"]["energy"]) >= float(clear["sun"]["energy"]):
		e.append("rain clouds did not dim the sun")
	if float(snow["surface"]["snow_cover"]) < 0.9:
		e.append("snow=1 cover %s" % snow["surface"]["snow_cover"])
	Kit.configure(snow)
	var lawn := Kit.surface_color("lawn", "#3f5233")
	Kit.configure({})
	if lawn.get_luminance() < 0.7:
		e.append("snow-covered lawn is not white-ish: %s" % lawn)
	return e


func _t_absurd_inline() -> Array:
	var r := LookCompiler.compile({
		"base": "night_fog", "time": "12:00",
		"sun": {"disc_color": "#000000", "glow": 3.0, "glow_color": "#ffffff", "energy": 0.2},
		"sky": {"top": "#00ff88", "bodies": [{"kind": "planet", "elevation": 25, "azimuth": -30, "size": 14, "color": "#b48cff"}]},
		"palette": {"lawn": "#ff8ad8", "foliage": ["#7af0ff", "#b38aff"]},
		"grade": {"gradient_map": ["#000000", "#ff0040", "#ffffff"]},
		"lights": [{"elevation": 20, "azimuth": 90, "color": "#00ff00", "energy": 1.5}],
	})
	if not r["ok"]:
		return r["errors"]
	var lk: Dictionary = r["look"]
	var e := []
	if lk["sky"]["top"] != "#00ff88":
		e.append("explicit sky.top lost to the time model")
	if float(lk["ground_fog"]["density"]) <= 0.0:
		e.append("night_fog base's fog was not inherited")
	if lk["sky"]["bodies"].size() != 1:
		e.append("extra planet missing")
	return e


func _t_anchors() -> Array:
	var e := []
	for item in _all_layouts():
		var L: Dictionary = item["L"]
		var m := TownGen.manifest(L)
		var refs := []
		for k in m["anchors"]:
			if typeof(m["anchors"][k]) == TYPE_ARRAY:
				refs.append(k)
		for h in m["houses"]:
			refs.append(h["id"])
			refs.append(h["id"] + ".roof")
			for k in h["anchors"]:
				refs.append("%s.%s" % [h["id"], k])
		for s in m["streets"]:
			for k in ["start", "mid", "end"]:
				refs.append("%s.%s" % [s["id"], k])
		for it in m["intersections"]:
			refs.append(it["id"])
		for v in m["vacant_lots"]:
			refs.append(v["id"])
		if L["streetlights"].size() > 0:
			refs.append(L["streetlights"][0]["id"] + ".lamp")
		for ref in refs:
			var a := Anchors.resolve(L, ref)
			if a.has("error"):
				e.append("%s: %s -> %s" % [item["tag"], ref, a["error"]])
	return e


func _t_shot_templates() -> Array:
	var e := []
	var templates := Shot.list_templates()
	if templates.is_empty():
		return ["no shot templates in library/shots"]
	for item in _all_layouts():
		var L: Dictionary = item["L"]
		if L["houses"].is_empty():
			continue
		for t in templates:
			for subject in [L["houses"][0]["id"] + ".front_door", "town_center"]:
				var s := Shot.resolve({"template": t, "subject": subject}, L)
				if s.has("error"):
					e.append("%s: %s on %s: %s" % [item["tag"], t, subject, s["error"]])
	return e


func _t_shot_errors() -> Array:
	var e := []
	var L := TownGen.generate({}, 333)
	if Shot.validate({"att": "town_center"}).is_empty():
		e.append("typo 'att' not reported")
	if not Shot.resolve({"at": "house_999.curb", "look_at": "town_center"}, L).has("error"):
		e.append("unknown house anchor not reported")
	if not Shot.resolve({"template": "low_hero"}, L).has("error"):
		e.append("template without subject not reported")
	var ok := Shot.resolve({"at": {"anchor": "house_0.curb", "offset": [0, 1.6, 2]}, "look_at": "house_0.front_door", "lens_mm": 35, "roll": 10}, L)
	if ok.has("error"):
		e.append("valid shot failed: " + ok["error"])
	return e


func _t_views() -> Array:
	var e := []
	for item in _all_layouts():
		var L: Dictionary = item["L"]
		for v in Views.NAMES:
			if v == "entrance" and not L["params"]["exit_roads"]:
				continue
			var f := Views.frame(v, L)
			if f.has("error"):
				e.append("%s: view %s: %s" % [item["tag"], v, f["error"]])
	return e


func _t_builder_smoke() -> Array:
	var e := []
	var lk: Dictionary = LookCompiler.compile("night_fog")["look"]
	var L := TownGen.generate({}, 333)
	Kit.configure(lk)
	var root := SetBuilder.build(L, lk)
	var meshes := root.find_children("*", "MeshInstance3D", true, false).size()
	if meshes < 200:
		e.append("only %d mesh instances built" % meshes)
	if root.find_child("house_0", true, false) == null:
		e.append("no node named house_0")
	if root.find_children("*", "SpotLight3D", true, false).size() != L["streetlights"].size():
		e.append("streetlight spot count does not match layout at night")
	root.free()
	Kit.configure({})
	return e


func _t_kits() -> Array:
	var e := []
	var kits := KitDB.list_kits()
	if kits.is_empty():
		return ["no kits in library/kits"]
	for k in kits:
		e.append_array(KitDB.validate_kit(k))
	if TownGen.validate_params({"kit": "no_such_kit"}).is_empty():
		e.append("unknown kit not reported")
	if TownGen.validate_params({"season": "monsoon"}).is_empty():
		e.append("unknown season not reported")
	return e


func _t_kit_houses() -> Array:
	var e := []
	var L := TownGen.generate({"kit": "suburban"}, 333)
	for h in L["houses"]:
		if not h.has("model"):
			e.append("%s has no model" % h["id"])
			continue
		var sz := KitDB.size(h["model"]) * float(h["model_scale"])
		if absf(sz.x - float(h["w"])) > 0.05 or absf(sz.z - float(h["d"])) > 0.05:
			e.append("%s footprint %s does not match model %s" % [h["id"], [h["w"], h["d"]], sz])
	return e


func _t_primitive_kit() -> Array:
	var lk: Dictionary = LookCompiler.compile("day")["look"]
	var L := TownGen.generate({"kit": "primitive"}, 333)
	Kit.configure(lk)
	var root := SetBuilder.build(L, lk)
	var ok: bool = root.find_child("house_0", true, false) != null and L["houses"][0].get("model", "") == ""
	root.free()
	Kit.configure({})
	return [] if ok else ["primitive kit did not build procedural houses"]


# --- actors ------------------------------------------------------------------

func _t_actions() -> Array:
	var e := []
	var lib := Cast.anim_library()
	for id in Cast.actions():
		var a: Dictionary = Cast.action(id)
		e.append_array(Cast.validate_action(id))
		if a.has("anim") and not lib.has_animation(String(a["anim"])):
			e.append("action %s -> animation '%s' not in the library" % [id, a["anim"]])
		if a.get("gait", false) and float(a.get("speed", 0.0)) <= 0.0:
			e.append("gait %s has no measured speed" % id)
	return e


func _t_characters() -> Array:
	var e := []
	var chars := Cast.list_characters()
	if chars.size() < 3:
		return ["expected at least 3 characters"]
	for c in chars:
		e.append_array(Cast.validate_character(c))
	return e


func _actor_layout() -> Dictionary:
	return TownGen.generate({"kit": "primitive"}, 333)


func _t_actor_validation() -> Array:
	var e := []
	var cases := [
		[[{"id": "a", "character": "nobody", "at": "town_center"}], "unknown character"],
		[[{"id": "a", "character": "you", "at": "town_center", "action": "moonwalk"}], "unknown action"],
		[[{"id": "a", "character": "you", "at": "town_center", "spin": 1}], "unknown key"],
		[[{"id": "a", "character": "you", "at": "town_center"}, {"id": "a", "character": "you", "at": "town_center"}], "duplicate id"],
		[[{"id": "a", "character": "you", "at": "town_center", "route": {"via": ["int_0_0"], "gait": "idle"}}], "non-moving gait"],
		[[{"id": "a", "character": "you", "at": "town_center", "action": "jump", "freeze": "peak"}], "unknown freeze mark"],
		[[{"id": "a", "character": "you", "at": "town_center", "action": "idle", "freeze": 1.5}], "freeze out of range"],
		[[{"id": "a", "character": "you", "at": "town_center", "cues": [{"t": 3, "action": "jump"}, {"t": 1, "action": "idle"}]}], "cues out of order"],
		[[{"id": "a", "character": "you", "at": "town_center", "cues": [{"t": 1, "hold": true, "action": "jump"}]}], "hold cue with an action"],
		[[{"id": "a", "character": "you", "at": "town_center", "cues": [{"t": 1, "freeze": 0.5}]}], "freeze cue without action"],
		[[{"id": "a", "character": "you", "at": "town_center", "cues": [{"t": 1, "action": "moonwalk"}]}], "unknown cue action"],
	]
	for c in cases:
		if ActorDirector.validate(c[0]).is_empty():
			e.append("not reported: " + c[1])
	return e


func _t_actor_pose_deterministic() -> Array:
	var L := _actor_layout()
	var res := ActorDirector.plan_all([{"id": "w", "character": "you", "at": "town_center",
		"route": {"via": ["int_0_0"], "gait": "walk", "start": 1.0}}], L)
	if res.has("error"):
		return [res["error"]]
	var node := ActorDirector.build(res["plans"], L)
	root.add_child(node)
	var actor = node.get_child(0)
	var sk: Skeleton3D = actor.skeleton
	var snap := func() -> Array:
		var out := [actor.position]
		for b in [sk.find_bone("thigh_l"), sk.find_bone("hand_r"), sk.find_bone("Head")]:
			out.append(sk.get_bone_pose(b))
		return out
	actor.pose_at(3.7)
	var a: Array = snap.call()
	actor.pose_at(11.0)
	actor.pose_at(0.2)
	actor.pose_at(3.7)
	var b: Array = snap.call()
	node.free()
	var e := []
	for i in a.size():
		if a[i] != b[i]:
			e.append("pose_at(3.7) differs after other poses: item %d %s vs %s" % [i, a[i], b[i]])
	return e


func _t_retarget() -> Array:
	var e := []
	for c in Cast.list_characters():
		if String(c).begins_with("city_"):
			for err in Cast.validate_character(c):
				e.append(err)
	var L := _actor_layout()
	var res := ActorDirector.plan_all([
		{"id": "m", "character": "you", "at": "town_center", "action": "walk"},
		{"id": "c", "character": "city_suit_navy", "at": "town_center", "action": "walk"}], L)
	if res.has("error"):
		return [res["error"]]
	var node := ActorDirector.build(res["plans"], L)
	root.add_child(node)
	var man = node.get_child(0)
	var cit = node.get_child(1)
	if cit.retarget == null:
		node.free()
		return ["city_suit_navy has no retarget"]
	var dst: Skeleton3D = cit.retarget.dst
	var snap := func() -> Array:
		var out := []
		for b in ["Hips", "UpperLeg.L", "Hand.R", "Head"]:
			out.append(dst.get_bone_pose(dst.find_bone(b)))
		return out
	for t in [0.3, 0.8]:
		man.pose_at(t)
		cit.pose_at(t)
		# Same animation, same spot: the model's head and hands track the mannequin's.
		for b in ["Head", "hand_r", "foot_l"]:
			var d: float = man.bone_world(b).distance_to(cit.bone_world(b))
			if d > 0.2:
				e.append("t=%.1f: %s is %.2f m from the mannequin's" % [t, b, d])
	cit.pose_at(0.8)
	var a: Array = snap.call()
	cit.pose_at(2.5)
	cit.pose_at(0.8)
	var b2: Array = snap.call()
	for i in a.size():
		if not (a[i] as Transform3D).is_equal_approx(b2[i]):
			e.append("retargeted pose at 0.8 s differs after another pose (bone %d)" % i)
	node.free()
	return e


func _t_actor_route() -> Array:
	var L := _actor_layout()
	var res := ActorDirector.plan_all([{"id": "w", "character": "you", "at": "int_0_0",
		"route": {"via": ["int_1_0"], "gait": "walk", "start": 2.0, "then": "phone"}}], L)
	if res.has("error"):
		return [res["error"]]
	var node := ActorDirector.build(res["plans"], L)
	root.add_child(node)
	var actor = node.get_child(0)
	var plan: Dictionary = res["plans"][0]
	var r: Dictionary = plan["route"]
	var a: Vector3 = r["points"][0]
	var b: Vector3 = r["points"][-1]
	var e := []
	var s0: Dictionary = actor.state_at(1.0)
	if Vector2(s0["pos"].x, s0["pos"].z).distance_to(Vector2(a.x, a.z)) > 0.01 or s0["action"] == "walk":
		e.append("before start the actor should stand at the start, not walk")
	var s1: Dictionary = actor.state_at(2.0 + 5.0)
	var walked := Vector2(s1["pos"].x, s1["pos"].z).distance_to(Vector2(a.x, a.z))
	if absf(walked - 5.0 * float(r["speed"])) > 0.05 or s1["action"] != "walk":
		e.append("after 5 s of walking at %.2f m/s the actor moved %.2f m" % [r["speed"], walked])
	var s2: Dictionary = actor.state_at(10000.0)
	if Vector2(s2["pos"].x, s2["pos"].z).distance_to(Vector2(b.x, b.z)) > 0.01 or s2["action"] != "phone":
		e.append("after arriving the actor should stand at the end doing 'phone'")
	node.free()
	return e


func _t_crowd() -> Array:
	var L := _actor_layout()
	var spec := [{"id": "horde", "character": "zombie", "at": "town_center",
		"crowd": {"count": 9, "radius": 5, "characters": ["zombie", "zombie_f"]},
		"route": {"via": ["int_0_0"], "gait": "zombie_walk"}}]
	var a := ActorDirector.plan_all(spec, L)
	var b := ActorDirector.plan_all(spec, L)
	if a.has("error"):
		return [a["error"]]
	var e := []
	if a["plans"].size() != 9:
		e.append("crowd of 9 produced %d actors" % a["plans"].size())
	var ids := {}
	for i in a["plans"].size():
		var p: Dictionary = a["plans"][i]
		ids[p["id"]] = true
		if p["pos"] != b["plans"][i]["pos"] or p["character"] != b["plans"][i]["character"]:
			e.append("crowd member %d differs between two expansions" % i)
	if ids.size() != a["plans"].size():
		e.append("crowd ids are not unique")
	return e


func _t_actor_anchors_for_cameras() -> Array:
	var L := _actor_layout()
	var res := ActorDirector.plan_all([{"id": "you", "character": "you", "at": "house_0.front_door"}], L)
	if res.has("error"):
		return [res["error"]]
	var node := ActorDirector.build(res["plans"], L)
	root.add_child(node)
	ActorDirector.pose_all(node, 1.0)
	var LA := L.duplicate(false)
	LA["actor_anchors"] = ActorDirector.anchors(node)
	var e := []
	for ref in ["you", "you.head", "you.eyes", "you.chest", "you.hand"]:
		if Anchors.resolve(LA, ref).has("error"):
			e.append("anchor %s does not resolve" % ref)
	var head: Vector3 = LA["actor_anchors"]["you.head"]["pos"]
	var feet: Vector3 = LA["actor_anchors"]["you"]["pos"]
	if head.y - feet.y < 1.4 or head.y - feet.y > 2.1:
		e.append("head is %.2f m above the feet for a 1.8 m character" % (head.y - feet.y))
	var shot := Shot.resolve({"at": {"anchor": "you", "offset": [0, 1.6, 3]}, "look_at": "you.head"}, LA)
	if shot.has("error"):
		e.append("shot on an actor failed: " + shot["error"])
	node.free()
	return e


## Lowest foot height above the actor's ground point, in metres.
func _foot_clearance(actor) -> float:
	var ground: float = actor.anchor_points()[actor.actor_id]["pos"].y
	var lowest := INF
	for b in ["foot_l", "foot_r", "ball_l", "ball_r"]:
		lowest = minf(lowest, actor.bone_world(b).y - ground)
	return lowest


func _t_jump() -> Array:
	var L := _actor_layout()
	var res := ActorDirector.plan_all([{"id": "k", "character": "you", "at": "town_center",
		"action": "jump", "freeze": "apex"}], L)
	if res.has("error"):
		return [res["error"]]
	var e := []
	var cp := Cast.clip_plan("jump")
	if absf(float(res["plans"][0]["freeze"]) * float(cp["length"]) - 0.7) > 0.001:
		e.append("freeze 'apex' did not resolve to the apex mark")
	var node := ActorDirector.build(res["plans"], L)
	root.add_child(node)
	var actor = node.get_child(0)
	actor.pose_at(0.0)
	if _foot_clearance(actor) < 0.5:
		e.append("at apex the feet are only %.2f m off the ground" % _foot_clearance(actor))
	var head_y: float = actor.anchor_points()["k.head"]["pos"].y - actor.anchor_points()["k"]["pos"].y
	if head_y < 1.9:
		e.append("at apex the head anchor is %.2f m up: anchors do not follow the lift" % head_y)
	# Unfrozen: on the ground before takeoff and after landing, never through it.
	actor.plan["freeze"] = -1.0
	actor.plan["phase"] = 0.0
	for i in 41:
		var t := i * 0.05
		actor.pose_at(t)
		var c := _foot_clearance(actor)
		if c < -0.04:
			e.append("t=%.2f: a foot is %.2f m below the ground" % [t, -c])
		if (t < 0.35 or t > 1.6) and c > 0.06:
			e.append("t=%.2f: feet %.2f m off the ground outside the jump" % [t, c])
	node.free()
	return e



func _t_cues_holds() -> Array:
	var L := _actor_layout()
	var res := ActorDirector.plan_all([
		{"id": "s", "character": "you", "at": "town_center", "action": "idle",
			"cues": [{"t": 1.0, "action": "jump"}, {"t": 3.0, "facing": "int_0_0"}]},
		{"id": "w", "character": "you", "at": "int_0_0",
			"route": {"via": ["int_1_0"], "gait": "walk", "start": 0.0},
			"cues": [{"t": 2.0, "hold": true}, {"t": 5.0, "hold": false}]}], L)
	if res.has("error"):
		return [res["error"]]
	var node := ActorDirector.build(res["plans"], L)
	root.add_child(node)
	var s = node.get_child(0)
	var w = node.get_child(1)
	var e := []
	if s.state_at(0.5)["action"] != "idle":
		e.append("before its cue the actor should do its base action")
	var j: Dictionary = s.state_at(1.2)
	if j["action"] != "jump" or absf(float(j["anim_time"]) - 0.2) > 0.001:
		e.append("a cued action should start from its beginning at the cue (got %s at %.2f)" % [j["action"], j["anim_time"]])
	var turned: Dictionary = s.state_at(3.5)
	if turned["action"] != "jump" or absf(float(turned["yaw"]) - float(j["yaw"])) < 0.01:
		e.append("a facing cue should turn the actor and keep the current action")
	var p2: Vector3 = w.state_at(2.0)["pos"]
	var p4: Vector3 = w.state_at(4.0)["pos"]
	if p2.distance_to(p4) > 0.001:
		e.append("a held actor moved %.2f m during the hold" % p2.distance_to(p4))
	var p6: Vector3 = w.state_at(6.0)["pos"]
	if p6.distance_to(p4) < 0.1:
		e.append("after the hold is released the actor should walk on")
	# 6 s scene time = 3 s of the actor's own clock (3 s were held).
	var free := ActorDirector.plan_all([{"id": "f", "character": "you", "at": "int_0_0",
		"route": {"via": ["int_1_0"], "gait": "walk", "start": 0.0}}], L)
	var fnode := ActorDirector.build(free["plans"], L)
	root.add_child(fnode)
	if fnode.get_child(0).state_at(3.0)["pos"].distance_to(p6) > 0.001:
		e.append("after a 3 s hold, scene 6 s should match 3 s of walking")
	node.free()
	fnode.free()
	return e


func _episode(shots: Array) -> Dictionary:
	return {"schema_version": "0.1", "id": "t", "set": "specs/sets/blackwood.json", "shots": shots}


func _t_episode_validation() -> Array:
	var ok_cam := {"at": "town_center", "look_at": "int_0_0"}
	var cases := [
		[{"schema_version": "0.1", "id": "t", "set": "x"}, "no shots"],
		[_episode([{"name": "a", "duration": 0, "camera": ok_cam}]), "zero duration"],
		[_episode([{"name": "a", "duration": 2, "camera": ok_cam, "zoom": 2}]), "unknown shot key"],
		[_episode([{"name": "a", "duration": 2, "camera": ok_cam}, {"name": "a", "duration": 2, "camera": ok_cam}]), "duplicate shot names"],
		[_episode([{"name": "a", "duration": 2, "camera": {"from": ok_cam}}]), "move without 'to'"],
		[_episode([{"name": "a", "duration": 2, "camera": {"from": ok_cam, "to": ok_cam, "ease": "bounce"}}]), "unknown ease"],
		[_episode([{"name": "a", "duration": 2, "camera": {"at": "town_center", "look_at": "int_0_0", "t": 3}}]), "camera with 't'"],
		[_episode([{"name": "a b", "duration": 2, "camera": ok_cam}]), "shot name with a space"],
	]
	var e := []
	for c in cases:
		if Episode.validate(c[0]).is_empty():
			e.append("not reported: " + c[1])
	if not Episode.validate(_episode([{"name": "a", "duration": 2, "camera": ok_cam}])).is_empty():
		e.append("a valid episode was rejected: %s" % [Episode.validate(_episode([{"name": "a", "duration": 2, "camera": ok_cam}]))])
	return e


func _t_episode_timeline() -> Array:
	var cam := {"at": "town_center", "look_at": "int_0_0"}
	var ep := _episode([{"name": "a", "duration": 2.0, "camera": cam},
		{"name": "b", "duration": 1.5, "scene_t": 0.5, "camera": cam},
		{"name": "c", "duration": 1.0, "camera": cam}])
	var tl := Episode.timeline(ep, 30)
	var e := []
	var want := [[60, 0, 0.0], [45, 60, 0.5], [30, 105, 2.0]]
	for i in 3:
		if int(tl[i]["frames"]) != want[i][0] or int(tl[i]["first_frame"]) != want[i][1] or absf(float(tl[i]["scene_t"]) - want[i][2]) > 0.0001:
			e.append("shot %d: frames %d first %d scene_t %.2f, want %s" % [i, tl[i]["frames"], tl[i]["first_frame"], tl[i]["scene_t"], want[i]])
	var last := Episode.frame_time(tl[0], 59, 30)
	if absf(float(last["p"]) - 1.0) > 0.0001 or absf(float(last["t"]) - 59.0 / 30.0) > 0.0001:
		e.append("last frame of a shot should have progress 1 at its own time")
	return e


func _t_camera_move() -> Array:
	var L := _actor_layout()
	var a := {"at": {"anchor": "town_center", "offset": [0, 2, 10]}, "look_at": "town_center", "lens_mm": 24}
	var b := {"at": {"anchor": "int_0_0", "offset": [3, 6, 5]}, "look_at": "int_0_0", "lens_mm": 85}
	var shot := {"camera": {"from": a, "to": b, "ease": "in_out"}}
	var e := []
	var s0 := Episode.camera_at(shot, 0.0, L, {})
	var s1 := Episode.camera_at(shot, 1.0, L, {})
	var ra := Shot.resolve(a, L)
	var rb := Shot.resolve(b, L)
	if not (s0["transform"] as Transform3D).is_equal_approx(ra["transform"]) or absf(float(s0["fov"]) - float(ra["fov"])) > 0.001:
		e.append("move does not start at 'from'")
	if not (s1["transform"] as Transform3D).is_equal_approx(rb["transform"]) or absf(float(s1["fov"]) - float(rb["fov"])) > 0.001:
		e.append("move does not end at 'to'")
	var mid := Episode.camera_at(shot, 0.5, L, {})
	var mo: Vector3 = mid["transform"].origin
	var half: Vector3 = (ra["transform"].origin + rb["transform"].origin) * 0.5
	if mo.distance_to(half) > 0.01:
		e.append("in_out move should be halfway at p = 0.5")
	return e


func _t_sample_episodes() -> Array:
	var e := []
	var dir := DirAccess.open(Paths.repo_path("episodes"))
	if dir == null:
		return e
	for id in dir.get_directories():
		var path := Paths.repo_path("episodes/%s/episode.json" % id)
		if not FileAccess.file_exists(path):
			continue
		# Voice-first episodes hold time references that only the Python
		# resolver turns into numbers; Godot always renders the resolved file.
		var resolved := Paths.repo_path("episodes/%s/build/episode.resolved.json" % id)
		var raw := Paths.load_json(path)
		if raw["ok"] and raw["data"].has("lines"):
			if not FileAccess.file_exists(resolved):
				continue
			path = resolved
		var le := Episode.load_episode(path)
		if le.has("error"):
			e.append("%s: %s" % [id, le["error"]])
			continue
		for m in Episode.validate(le["episode"]) + Spec.validate_set_spec(le["spec"]):
			e.append("%s: %s" % [id, m])
	return e


func _t_facing_tracks() -> Array:
	var L := _actor_layout()
	var res := ActorDirector.plan_all([
		{"id": "you", "character": "you", "at": {"anchor": "int_0_0", "offset": [6, 0, 6]}, "action": "idle",
			"cues": [{"t": 4.0, "facing": "w"}, {"t": 8.0, "hold": true}]},
		{"id": "w", "character": "you", "at": "int_0_0",
			"route": {"via": ["int_1_0"], "gait": "walk", "start": 0.0}}], L)
	if res.has("error"):
		return [res["error"]]
	var node := ActorDirector.build(res["plans"], L)
	root.add_child(node)
	var you = node.get_child(0)
	var w = node.get_child(1)
	var e := []
	var yaw_toward := func(t: float) -> float:
		var d: Vector3 = w.position_at(t) - you.position_at(t)
		return atan2(d.x, d.z)
	# Turning: halfway through the 0.6 s turn the yaw is between old and new.
	var before := float(you.state_at(3.99)["yaw"])
	var mid := float(you.state_at(4.3)["yaw"])
	if absf(angle_difference(mid, before)) < 0.01 or absf(angle_difference(mid, yaw_toward.call(4.3))) < 0.01:
		e.append("a facing cue should turn gradually, not snap")
	# Tracking: after the turn, the actor faces where the walker is now, not where they started.
	for t in [5.0, 7.0]:
		if absf(angle_difference(float(you.state_at(t)["yaw"]), yaw_toward.call(t))) > 0.02:
			e.append("at %.1f s the actor does not face the walker's current position" % t)
	if absf(angle_difference(yaw_toward.call(5.0), yaw_toward.call(7.0))) < 0.02:
		e.append("test setup: the walker should move across the actor's view")
	# Held: keeps facing where the walker was when the hold began.
	if absf(angle_difference(float(you.state_at(12.0)["yaw"]), yaw_toward.call(8.0))) > 0.02:
		e.append("a held actor kept tracking a moving target")
	node.free()
	return e


func _t_supermarket() -> Array:
	var e := []
	var a := SetBuilder.generate({"generator": "supermarket", "seed": 7, "params": {}})
	var b := SetBuilder.generate({"generator": "supermarket", "seed": 7, "params": {}})
	if JSON.stringify(a) != JSON.stringify(b):
		e.append("supermarket layout differs for the same seed")
	if not SetBuilder.validate({"generator": "supermarket", "seed": 1, "params": {"aisles": 3, "toy_aisle": 5}}).size() > 0:
		e.append("toy_aisle beyond the last aisle was not reported")
	if not SetBuilder.validate({"generator": "supermarket", "seed": 1, "params": {"isles": 3}}).size() > 0:
		e.append("unknown supermarket param was not reported")
	for ref in ["entrance", "storefront", "front_aisle.start", "aisle_6.start", "aisle_6.front", "toys", "toy_hero", "checkout_2", "freezers"]:
		if Anchors.resolve(a, ref).has("error"):
			e.append("anchor %s does not resolve" % ref)
	if not Anchors.resolve(a, "house_3").has("error"):
		e.append("town anchors should not resolve in a supermarket")
	# Shelves block the view across aisles.
	var across := Shot.blockers(a, Anchors.resolve(a, "aisle_1.mid")["pos"] + Vector3.UP * 1.5, Anchors.resolve(a, "aisle_3.mid")["pos"] + Vector3.UP * 1.5)
	if across.is_empty():
		e.append("shelving between aisles 1 and 3 should block the line of sight")
	var node := SetBuilder.build(a, LookCompiler.compile("night_fog")["look"])
	root.add_child(node)
	var events := [{"t": 1.0, "target": "toy_hero", "state": "on"}, {"t": 3.0, "target": "toys", "state": "on"}]
	if not SetEvents.check_targets(node, events).is_empty():
		e.append("toy switch targets missing: %s" % [SetEvents.check_targets(node, events)])
	if not SetEvents.check_targets(node, [{"t": 0, "target": "disco_ball", "state": "on"}]).size() > 0:
		e.append("unknown event target was not reported")
	var hero: Node = node.find_child("toy_hero", true, false)
	var other: Node = node.find_child("toy_3", true, false)
	SetEvents.apply(node, events, 0.5)
	if hero.get_node("on").visible:
		e.append("toy_hero should be off before its event")
	SetEvents.apply(node, events, 2.0)
	if not hero.get_node("on").visible or other.get_node("on").visible:
		e.append("at 2 s only toy_hero should be on")
	SetEvents.apply(node, events, 4.0)
	if not other.get_node("on").visible:
		e.append("at 4 s every toy should be on")
	SetEvents.apply(node, events, 0.5)
	if hero.get_node("on").visible:
		e.append("events are not a pure function of time (going back to 0.5 s)")
	node.free()
	return e


func _t_supermarket_kit() -> Array:
	var e := []
	var SMGen = load("res://scripts/world/generators/supermarket_generator.gd")
	if not SetBuilder.validate({"generator": "supermarket", "seed": 1, "params": {"kit": "no_such_kit"}}).size() > 0:
		e.append("unknown kit was not reported")
	if not SetBuilder.validate({"generator": "supermarket", "seed": 1, "params": {"shelf_d": 1.0}}).size() > 0:
		e.append("shelf_d with a model kit was not reported")
	if not SetBuilder.validate({"generator": "supermarket", "seed": 1, "params": {"kit": "primitive", "shelf_d": 1.0}}).is_empty():
		e.append("shelf_d with kit primitive should be valid")
	var L := SetBuilder.generate({"generator": "supermarket", "seed": 7, "params": {}})
	var seg := float(L["shelving"]["seg"])
	for g in L["gondolas"]:
		var r: Array = g["rect"]
		if absf(g["segments"].size() * seg - (float(r[3]) - float(r[1]))) > 0.01:
			e.append("%s: segments do not tile its length" % g["id"])
	for t in L["toys"]:
		if L["shelving"]["levels"].filter(func(y): return absf(float(y) - float(t["pos"][1])) < 0.002).is_empty():
			e.append("%s is not on a shelf board (y %s)" % [t["id"], t["pos"][1]])
	var face: Dictionary = L["shelves"].filter(func(s): return s.has("toy_span"))[0]
	for t in L["toys"]:
		if not SMGen.in_spans(face["spans"], float(t["pos"][2]), 0.1):
			e.append("%s stands on an upright, not a shelf" % t["id"])
	if L["clutter"].filter(func(c): return c["kind"] == "cart").is_empty():
		e.append("no carts in the clutter")
	var tidy := SetBuilder.generate({"generator": "supermarket", "seed": 7, "params": {"clutter": 0.0}})
	if tidy["clutter"].size() >= L["clutter"].size():
		e.append("clutter 0 should leave fewer items")
	var P := SetBuilder.generate({"generator": "supermarket", "seed": 7, "params": {"kit": "primitive"}})
	var node := SetBuilder.build(P, LookCompiler.compile("night_fog")["look"])
	root.add_child(node)
	if node.find_child("toy_hero", true, false) == null or node.find_child("wall_shelf_w_0", true, false) == null:
		e.append("primitive supermarket is missing toy_hero or wall shelves")
	node.free()
	return e


func _t_downtown() -> Array:
	var e := []
	var DT = load("res://scripts/world/generators/downtown_generator.gd")
	var spec := {"generator": "downtown", "seed": 21, "params": {}}
	var a := SetBuilder.generate(spec)
	if JSON.stringify(a) != JSON.stringify(SetBuilder.generate(spec)):
		e.append("downtown layout differs for the same seed")
	if JSON.stringify(a) == JSON.stringify(SetBuilder.generate({"generator": "downtown", "seed": 22, "params": {}})):
		e.append("downtown layout ignores the seed")
	for bad in [{"blocs": 3}, {"floors": [5, 2]}, {"styles": ["glass"]}, {"kit": "nope"}, {"outskirts": 1}]:
		if SetBuilder.validate({"generator": "downtown", "seed": 1, "params": bad}).is_empty():
			e.append("bad downtown params %s were not reported" % [bad])
	for ref in ["city_center", "cross_1_1", "cross_1_1.ne", "ave_1", "ave_1.start", "st_2.walk_l", "block_1_1", "bldg_0", "bldg_0.top"]:
		if Anchors.resolve(a, ref).has("error"):
			e.append("anchor %s does not resolve" % ref)
	var blocks := {}
	for b in a["blocks"]:
		blocks[b["id"]] = b["rect"]
	var by_block := {}
	for bl in a["buildings"]:
		var r: Array = bl["rect"]
		var br: Array = blocks[bl["block"]]
		if float(r[0]) < float(br[0]) - 0.01 or float(r[1]) < float(br[1]) - 0.01 or float(r[2]) > float(br[2]) + 0.01 or float(r[3]) > float(br[3]) + 0.01:
			e.append("%s lies outside %s" % [bl["id"], bl["block"]])
		for other in by_block.get(bl["block"], []):
			var o: Array = other["rect"]
			if float(r[0]) < float(o[2]) - 0.01 and float(o[0]) < float(r[2]) - 0.01 and float(r[1]) < float(o[3]) - 0.01 and float(o[1]) < float(r[3]) - 0.01:
				e.append("%s overlaps %s" % [bl["id"], other["id"]])
		if not by_block.has(bl["block"]):
			by_block[bl["block"]] = []
		by_block[bl["block"]].append(bl)
	for st in a["streets"]:
		for t in st["tiles"]:
			for c in st["crossings"]:
				if absf(float(t) - float(c)) < DT.CROSS_HALF + DT.TILE / 2.0 - 0.01:
					e.append("%s: tile at %.2f overlaps the crossing at %.2f" % [st["id"], t, c])
	var nodes: Dictionary = a["walkways"]["nodes"]
	for ed in a["walkways"]["edges"]:
		if not nodes.has(ed[0]) or not nodes.has(ed[1]):
			e.append("walkway edge %s references a missing node" % [ed])
	var c0: Array = a["anchors"]["ave_1"]["pos"]
	if DT.ground_height(a, float(c0[0]), float(c0[2])) != 0.0:
		e.append("the middle of ave_1 should be road (y 0)")
	var w0: Array = a["anchors"]["ave_1.walk_l"]["pos"]
	if absf(DT.ground_height(a, float(w0[0]), float(w0[2])) - DT.SIDEWALK_TOP) > 0.001:
		e.append("ave_1.walk_l should be on the sidewalk")
	var small := SetBuilder.generate({"generator": "downtown", "seed": 3, "params": {"kit": "primitive", "blocks_x": 1, "blocks_z": 1}})
	var node := SetBuilder.build(small, LookCompiler.compile("day")["look"])
	root.add_child(node)
	if node.find_child("bldg_0", true, false) == null or node.find_child("light_0", true, false) == null:
		e.append("primitive downtown is missing bldg_0 or light_0")
	node.free()
	return e


func _t_toons() -> Array:
	var e := Toon.validate_faces()
	var bad := Toon.validate({"hair": {"style": "mohawk"}, "outfit": {"style": "tee", "color": "nope"}, "hat": 1}, "x")
	for want in ["hair style", "not a hex", "unknown key 'hat'"]:
		if not bad.any(func(m): return String(m).contains(want)):
			e.append("toon validation did not report: " + want)
	if ActorDirector.validate([{"id": "a", "character": "toon_you", "at": "town_center",
			"cues": [{"t": 1, "expression": "flabbergasted"}]}]).is_empty():
		e.append("unknown expression not reported")
	var L := _actor_layout()
	var res := ActorDirector.plan_all([
		{"id": "m", "character": "you", "at": "town_center", "action": "walk"},
		{"id": "t", "character": "toon_you", "at": "town_center", "action": "walk",
			"cues": [{"t": 2.0, "expression": "shocked"}]}], L)
	if res.has("error"):
		return [res["error"]]
	var node := ActorDirector.build(res["plans"], L)
	root.add_child(node)
	var man = node.get_child(0)
	var toon = node.get_child(1)
	if toon.retarget == null or toon.retarget.dst.name != "toon_skeleton":
		node.free()
		return e + ["toon has no toon skeleton"]
	toon.pose_at(0.5)
	man.pose_at(0.5)
	# Short legs: the toon's hips sit much lower than the mannequin's; the head is high.
	var hip_t: float = toon.bone_world("pelvis").y - toon.position.y
	var hip_m: float = man.bone_world("pelvis").y - man.position.y
	if hip_t > hip_m * 0.6:
		e.append("toon hips at %.2f m, mannequin's at %.2f m: legs not shortened" % [hip_t, hip_m])
	var foot: float = toon.bone_world("foot_l").y - toon.position.y
	if foot < -0.02 or foot > 0.2:
		e.append("toon ankle at %.2f m above the ground" % foot)
	if toon.expression_at(1.0) != "smug" or toon.expression_at(2.5) != "shocked":
		e.append("expressions: %s at 1 s, %s at 2.5 s" % [toon.expression_at(1.0), toon.expression_at(2.5)])
	toon.pose_at(2.5)
	var mat: ShaderMaterial = toon._face_mat
	if int(mat.get_shader_parameter("mouth")) != Toon.MOUTHS.find("open"):
		e.append("face material not switched to 'shocked'")
	toon.pose_at(0.5)
	if int(mat.get_shader_parameter("mouth")) != Toon.MOUTHS.find("smirk"):
		e.append("face did not return to 'smug' at 0.5 s")
	node.free()
	return e


func _t_reveals() -> Array:
	var e := []
	var cases := [
		[[{"id": "a", "t": 1, "at": "town_center"}], "needs exactly one"],
		[[{"id": "a", "t": 1, "at": "town_center", "shape": "blob"}], "shape 'blob'"],
		[[{"id": "a", "t": 1, "at": "town_center", "shape": "box", "enter": "teleport"}], "enter 'teleport'"],
		[[{"id": "a", "t": 1, "shape": "box"}], "needs 'at'"],
		[[{"id": "a", "t": 2, "until": 1, "at": "town_center", "shape": "box"}], "'until'"],
		[[{"id": "a", "t": 1, "at": "town_center", "counter": {"from": 0}}], "counter needs 'to'"],
		[[{"id": "a", "t": 1, "at": "town_center", "text": "x"}, {"id": "a", "t": 1, "at": "town_center", "text": "y"}], "unique 'id'"],
	]
	for c in cases:
		var errs := Reveals.validate(c[0])
		if not errs.any(func(m): return String(m).contains(c[1])):
			e.append("not reported: %s (got %s)" % [c[1], errs])
	var reveals := [
		{"id": "box", "t": 1.0, "until": 3.0, "at": "town_center", "shape": "box", "enter": "pop"},
		{"id": "n", "t": 0.0, "at": "town_center", "counter": {"from": 0, "to": 1000, "land": 2.0, "suffix": " PEOPLE"}},
	]
	e.append_array(Reveals.validate(reveals))
	var L := _actor_layout()
	var node := Reveals.build(reveals)
	root.add_child(node)
	var box: Node3D = node.get_node("box")
	var n: Node3D = node.get_node("n")
	var value: TextMesh = (n.get_node("content/value") as MeshInstance3D).mesh
	Reveals.pose(node, reveals, 0.5, L)
	if box.visible:
		e.append("box visible before its time")
	Reveals.pose(node, reveals, 1.1, L)
	if not box.visible or box.scale.x >= 1.0:
		e.append("box should be popping in at 1.1 s (visible, scale < 1), got scale %.2f" % box.scale.x)
	Reveals.pose(node, reveals, 2.0, L)
	if absf(box.scale.x - 1.0) > 0.001:
		e.append("box at full size after its entrance, got %.3f" % box.scale.x)
	if value.text != "1,000 PEOPLE":
		e.append("counter at its land time reads '%s'" % value.text)
	Reveals.pose(node, reveals, 3.5, L)
	if box.visible:
		e.append("box still visible after until + exit")
	Reveals.pose(node, reveals, 1.0, L)
	if value.text == "0 PEOPLE" or value.text == "1,000 PEOPLE":
		e.append("counter should be mid-count at 1.0 s, reads '%s'" % value.text)
	var one: String = value.text
	Reveals.pose(node, reveals, 2.5, L)
	Reveals.pose(node, reveals, 1.0, L)
	if value.text != one:
		e.append("counter at 1.0 s is not a pure function of t")
	if Reveals.format_number(3.5, 1, true, "", " BILLION") != "3.5 BILLION" or Reveals.format_number(6880, 0, true, "", "") != "6,880":
		e.append("format_number: %s / %s" % [Reveals.format_number(3.5, 1, true, "", " BILLION"), Reveals.format_number(6880, 0, true, "", "")])
	node.free()
	return e


func _t_motion() -> Array:
	var e := []
	for f in [Motion.out_cubic, Motion.out_quint, Motion.in_cubic, Motion.in_out, Motion.smooth, Motion.out_back, Motion.in_back, Motion.out_bounce]:
		if absf(f.call(0.0)) > 0.001 or absf(f.call(1.0) - 1.0) > 0.001:
			e.append("an easing does not run 0 -> 1: %s" % f)
	if Motion.out_back(0.8) <= 1.0:
		e.append("out_back should overshoot past 1")
	if Motion.in_back(0.2) >= 0.0:
		e.append("in_back should dip below 0 (anticipation)")
	for a in [-0.4, -0.1, 0.0, 0.3]:
		var v := Motion.squash(a)
		if absf(v.x * v.y * v.z - 1.0) > 0.001:
			e.append("squash(%s) does not keep volume: %s" % [a, v])
	var table := [["wind", 0.2], ["throw", 0.1], ["settle", 0.3]]
	if Motion.phase(1.25, 1.0, table)["name"] != "throw":
		e.append("phase lookup: 1.25 s should be in 'throw'")
	if absf(Motion.phase_start(1.0, table, "settle") - 1.3) > 0.0001:
		e.append("phase_start of 'settle' should be 1.3")
	if Motion.wobble(-0.1) != 0.0 or absf(Motion.wobble(0.0) - 1.0) > 0.001 or absf(Motion.wobble(2.0)) > 0.01:
		e.append("wobble should be 0 before, 1 at, ~0 long after the event")
	var ev := [{"t": 2.0, "amount": 0.8}]
	if Motion.shake(1.9, ev) != Vector3.ZERO:
		e.append("shake before its event")
	if Motion.shake(2.1, ev) == Vector3.ZERO:
		e.append("no shake just after a heavy hit")
	if Motion.shake(2.1, ev) != Motion.shake(2.1, ev):
		e.append("shake is not a pure function of t")
	if Motion.shake(3.0, ev) != Vector3.ZERO:
		e.append("shake should have decayed to zero by 1 s after an 0.8 hit")
	var bad := Episode.validate({"shots": [{"name": "a", "duration": 1.0, "camera": "street", "shake": [{"t": 0.5, "amount": 3}]}]})
	if not "
".join(PackedStringArray(bad)).contains("shake amount"):
		e.append("episode validation should reject a shake amount > 1")
	return e
