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


func _init() -> void:
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
