## TownForge entry point.
##
## Usage (arguments after "--"):
##   --spec <path>        set spec JSON (default specs/sets/blackwood.json)
##   --look <id>          replace the spec's look with a preset
##   --time <HH:MM|h>     override time of day on top of the look
##   --weather <k=v,...>  override weather, e.g. fog=0.8,rain=0.5
##   --seed <n>           override the set seed
##   --validate           validate the spec and exit (works with --headless)
##   --stills <dir>       render the spec's preview shots to PNGs, write
##                        layout.json + manifest.json + look.json, then exit
##   --episode <path>     film an episode.json instead of a bare set spec, with:
##     --frames <dir>       render every frame: <dir>/<NN>_<shot>/<00000>.png + timeline.json
##     --shots a,b          only these shots (with --frames)
##     --storyboard <dir>   render start/mid/end stills of every shot: <dir>/<NN>_<shot>_<a|b|c>.png
##     --scale <f>          resolution multiplier (draft renders), --fps <n> override
##     (run with --fixed-fps <fps> so particles and shader time are deterministic)
##   (no mode)            interactive explore window with a fly camera
extends Node3D

const Paths = preload("res://scripts/core/paths.gd")
const Spec = preload("res://scripts/core/spec.gd")
const SetBuilder = preload("res://scripts/world/set_builder.gd")
const Kit = preload("res://scripts/world/prop_kit.gd")
const Look = preload("res://scripts/look/look.gd")
const LookCompiler = preload("res://scripts/look/look_compiler.gd")
const Views = preload("res://scripts/camera/views.gd")
const Shot = preload("res://scripts/camera/shot.gd")
const FlyCamera = preload("res://scripts/camera/fly_camera.gd")
const ActorDirector = preload("res://scripts/actors/actor_director.gd")
const Episode = preload("res://scripts/timeline/episode.gd")
const SetEvents = preload("res://scripts/timeline/set_events.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")

const DEFAULT_SPEC := "specs/sets/blackwood.json"
const SETTLE_FRAMES := 30
## Frames rendered (not saved) after each cut so temporal effects (volumetric
## fog reprojection, auto exposure) settle on the new camera.
const CUT_WARMUP_FRAMES := 30
## PNG encodes in flight on worker threads (each holds a full frame in memory).
const MAX_PENDING_SAVES := 8
const EXPLORE_RES := Vector2i(540, 960)
const WEATHER_STEPS := [0.0, 0.35, 0.7, 1.0]

var args := {}
var spec: Dictionary
var episode: Dictionary = {}  # set when filming an episode.json
var look_overrides := {}   # {"time": ..., "weather": {...}} layered over the spec's look
var look: Dictionary       # compiled
var layout: Dictionary
var set_node: Node3D
var actors_node: Node3D
var reveals_node: Node3D
var clock := 0.0          # scene time in seconds (actors are posed from it)
var playing := true
var camera: Camera3D
var hud: Label
var seed_value := 0
var view_idx := 0
var exploring := false


func _ready() -> void:
	args = _parse_args(OS.get_cmdline_user_args())
	var spec_path := Paths.resolve(String(args.get("spec", DEFAULT_SPEC)))
	var ep_errors := []
	if args.has("episode"):
		spec_path = Paths.resolve(String(args["episode"]))
		var le := Episode.load_episode(spec_path)
		if le.has("error"):
			_fail("%s: %s" % [spec_path, le["error"]])
			return
		episode = le["episode"]
		spec = le["spec"]
		ep_errors = Episode.validate(episode)
	else:
		var loaded := Paths.load_json(spec_path)
		if not loaded["ok"]:
			_fail(loaded["error"])
			return
		spec = loaded["data"]
	if args.has("look"):
		spec["look"] = String(args["look"])
	if args.has("seed"):
		spec["set"]["seed"] = int(args["seed"])
	if args.has("time"):
		look_overrides["time"] = String(args["time"]) if String(args["time"]).contains(":") else float(args["time"])
	if args.has("weather"):
		var w := {}
		for pair in String(args["weather"]).split(",", false):
			var kv := pair.split("=")
			if kv.size() == 2:
				w[kv[0].strip_edges()] = float(kv[1])
		look_overrides["weather"] = w
	var errors := Spec.validate_set_spec(spec)
	errors.append_array(ep_errors)
	var lc := LookCompiler.compile(_look_ref())
	errors.append_array(lc["errors"])
	if not errors.is_empty():
		_fail("invalid spec %s:\n  - %s" % [spec_path, "\n  - ".join(PackedStringArray(errors))])
		return
	if args.has("validate"):
		_log("spec OK: %s" % spec_path)
		get_tree().quit(0)
		return

	seed_value = int(spec["set"]["seed"])
	camera = FlyCamera.new()
	camera.name = "Camera"
	add_child(camera)
	camera.current = true
	var t0 := Time.get_ticks_msec()
	if not _build():
		return
	_log("built set '%s' (seed %d, look %s, %s) in %d ms" % [spec["set"].get("id", spec["set"]["generator"]), seed_value,
		look["id"], LookCompiler.format_time(look["time"]), Time.get_ticks_msec() - t0])

	if not episode.is_empty():
		if not _check_episode_cameras():
			return
		if args.has("framing"):
			_framing_report(Paths.resolve(String(args["framing"])))
		if args.has("frames"):
			await _run_frames(Paths.resolve(String(args["frames"])))
		elif args.has("storyboard"):
			await _run_storyboard(Paths.resolve(String(args["storyboard"])))
		elif args.has("framing"):
			get_tree().quit(0)
		else:
			_log("episode OK (%d shots); add --frames or --storyboard to render" % episode["shots"].size())
			get_tree().quit(0)
	elif args.has("stills"):
		await _run_stills(Paths.resolve(String(args["stills"])))
	else:
		_start_explore()


## The spec's look with any CLI / explore overrides layered on top.
func _look_ref():
	if look_overrides.is_empty():
		return spec["look"]
	var ref: Dictionary = look_overrides.duplicate(true)
	ref["base"] = spec["look"]
	return ref


func _build() -> bool:
	var lc := LookCompiler.compile(_look_ref())
	if not lc["ok"]:
		_fail("\n  - ".join(PackedStringArray(lc["errors"])))
		return false
	look = lc["look"]
	Look.apply(self, look, camera)
	Kit.configure(look)
	if set_node:
		remove_child(set_node)
		set_node.queue_free()
	var set_spec: Dictionary = spec["set"].duplicate(true)
	set_spec["seed"] = seed_value
	layout = SetBuilder.generate(set_spec)
	set_node = SetBuilder.build(layout, look)
	add_child(set_node)
	if actors_node:
		remove_child(actors_node)
		actors_node.queue_free()
		actors_node = null
	var planned := ActorDirector.plan_all(spec.get("actors"), layout)
	if planned.has("error"):
		_fail(planned["error"])
		return false
	actors_node = ActorDirector.build(planned["plans"], layout)
	add_child(actors_node)
	ActorDirector.pose_all(actors_node, clock)
	if reveals_node:
		remove_child(reveals_node)
		reveals_node.queue_free()
	reveals_node = Reveals.build(spec.get("reveals", []))
	add_child(reveals_node)
	var reveal_errors := Reveals.check(spec.get("reveals", []), _at_time(clock))
	if not reveal_errors.is_empty():
		_fail("
  - ".join(PackedStringArray(reveal_errors)))
		return false
	return true


## Pose every actor at time t and return the layout with their anchors added,
## so shots can target "you" or "you.head" at that moment.
func _at_time(t: float) -> Dictionary:
	ActorDirector.pose_all(actors_node, t)
	RenderingServer.global_shader_parameter_set("scene_time", t)
	if not episode.is_empty():
		SetEvents.apply(set_node, episode.get("events", []), t)
	var L := layout.duplicate(false)
	L["actor_anchors"] = ActorDirector.anchors(actors_node)
	# Reveals are placed from actor anchors, and become anchors themselves.
	L["actor_anchors"].merge(Reveals.pose(reveals_node, spec.get("reveals", []), t, L))
	return L


func _entry_time(entry) -> float:
	return float(entry.get("t", 0.0)) if typeof(entry) == TYPE_DICTIONARY else 0.0


# --- stills -----------------------------------------------------------------

func _shot_name(entry, i: int) -> String:
	if typeof(entry) == TYPE_STRING:
		return String(entry).replace(":", "_")
	return String(entry.get("name", entry.get("template", "shot%d" % i))).replace(":", "_")


func _run_stills(out_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	var preview: Dictionary = spec.get("preview", {})
	var res: Array = preview.get("resolution", [540, 960])
	get_window().content_scale_size = Vector2i(int(res[0]), int(res[1]))
	_write_json(out_dir.path_join("layout.json"), layout)
	_write_json(out_dir.path_join("manifest.json"), SetBuilder.manifest(layout))
	_write_json(out_dir.path_join("look.json"), look)
	var entries: Array = preview.get("views", Views.NAMES)
	# Resolve every shot first, so a bad anchor fails before any rendering.
	var shots := []
	for i in entries.size():
		var s := Shot.resolve(entries[i], _at_time(_entry_time(entries[i])), look)
		if s.has("error"):
			_fail("shot %d (%s): %s" % [i, _shot_name(entries[i], i), s["error"]])
			return
		if not s["blocked_by"].is_empty():
			_log("WARN shot %s: subject hidden behind %s" % [_shot_name(entries[i], i), ", ".join(PackedStringArray(s["blocked_by"]))])
		shots.append(s)
	for i in shots.size():
		_at_time(_entry_time(entries[i]))
		Shot.apply(camera, shots[i])
		for k in SETTLE_FRAMES:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path := out_dir.path_join("%02d_%s.png" % [i, _shot_name(entries[i], i)])
		img.save_png(path)
		_log("still %s -> %s (%dx%d)" % [_shot_name(entries[i], i), path, img.get_width(), img.get_height()])
	get_tree().quit(0)


# --- episodes ---------------------------------------------------------------

func _fps() -> int:
	return int(args.get("fps", Episode.fps_of(episode)))


## Output size: the episode resolution times --scale, rounded to even numbers (H.264).
func _out_size(scale: float) -> Vector2i:
	var res: Array = Episode.resolution_of(episode)
	return Vector2i(maxi(2, roundi(float(res[0]) * scale / 2.0) * 2), maxi(2, roundi(float(res[1]) * scale / 2.0) * 2))


## Poses actors and places the camera for frame k of a timeline shot.
func _frame_state(shot: Dictionary, k: int) -> Dictionary:
	var ft := Episode.frame_time(shot, k, _fps())
	var s := Episode.camera_at(shot, float(ft["p"]), _at_time(float(ft["t"])), look)
	if not s.has("error"):
		Shot.apply(camera, s)
	var iris := Episode.iris_at(shot, float(ft["p"]))
	RenderingServer.global_shader_parameter_set("iris_shape", float(iris["shape"]))
	RenderingServer.global_shader_parameter_set("iris_radius", float(iris["radius"]))
	return s


## Resolves every shot's camera at its start, middle and end before rendering,
## so a bad anchor fails fast; warns when the subject is hidden.
func _check_episode_cameras() -> bool:
	var target_errors := SetEvents.check_targets(set_node, episode.get("events", []))
	if not target_errors.is_empty():
		_fail("
  - ".join(PackedStringArray(target_errors)))
		return false
	for shot in Episode.timeline(episode, _fps()):
		var frames := int(shot["frames"])
		var warned := {}
		for k in [0, frames / 2, frames - 1]:
			var ft := Episode.frame_time(shot, k, _fps())
			var s := Episode.camera_at(shot, float(ft["p"]), _at_time(float(ft["t"])), look)
			if s.has("error"):
				_fail("shot %d (%s) at %.2f s: %s" % [shot["index"], shot["name"], ft["t"], s["error"]])
				return false
			for b in s["blocked_by"]:
				if not warned.has(b):
					warned[b] = true
					_log("WARN shot %s: subject hidden behind %s (around scene %.1f s)" % [shot["name"], b, ft["t"]])
	return true


## Rain/snow restart (fixed seed) at every cut, so a shot never depends on
## what was rendered before it.
func _restart_particles() -> void:
	for p in find_children("*", "GPUParticles3D", true, false):
		(p as GPUParticles3D).restart()


func _shot_dir_name(shot: Dictionary) -> String:
	return "%02d_%s" % [int(shot["index"]), shot["name"]]


func _run_frames(out_dir: String) -> void:
	var fps := _fps()
	var size := _out_size(float(args.get("scale", 1.0)))
	get_window().content_scale_size = size
	var shots := Episode.timeline(episode, fps)
	var only := PackedStringArray(String(args.get("shots", "")).split(",", false))
	DirAccess.make_dir_recursive_absolute(out_dir)
	var summary := []
	for shot in shots:
		summary.append({"index": shot["index"], "name": shot["name"], "dir": _shot_dir_name(shot),
			"frames": shot["frames"], "duration": shot["duration"], "scene_t": shot["scene_t"]})
	_write_json(out_dir.path_join("timeline.json"), {"id": episode["id"], "fps": fps,
		"resolution": [size.x, size.y], "shots": summary})
	var pending := []
	var t0 := Time.get_ticks_msec()
	# --stream DIR: pipe raw frames straight into ffmpeg (one encoder per shot, DIR/<shot>.mp4);
	# no PNGs on disk. Otherwise every frame is saved as a PNG under out_dir.
	var stream_dir := String(args.get("stream", ""))
	if stream_dir != "":
		stream_dir = Paths.resolve(stream_dir)
		DirAccess.make_dir_recursive_absolute(stream_dir)
	for shot in shots:
		if not only.is_empty() and not (String(shot["name"]) in only):
			continue
		var dir := out_dir.path_join(_shot_dir_name(shot))
		if stream_dir == "":
			DirAccess.make_dir_recursive_absolute(dir)
		_frame_state(shot, 0)
		_restart_particles()
		for w in CUT_WARMUP_FRAMES:
			await get_tree().process_frame
		var enc := {}
		for k in int(shot["frames"]):
			_frame_state(shot, k)
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			if stream_dir != "":
				if enc.is_empty():
					enc = _open_encoder(stream_dir.path_join(_shot_dir_name(shot) + ".mp4"), img)
					if enc.has("error"):
						_fail(String(enc["error"]))
						return
				if img.get_format() != int(enc["format"]):
					img.convert(int(enc["format"]))
				(enc["stdio"] as FileAccess).store_buffer(img.get_data())
				continue
			var path := dir.path_join("%05d.png" % k)
			# Keep the image referenced until its encode finishes.
			pending.append([WorkerThreadPool.add_task(img.save_png.bind(path)), img])
			while pending.size() > MAX_PENDING_SAVES:
				WorkerThreadPool.wait_for_task_completion(pending.pop_front()[0])
		if stream_dir != "":
			var err := _close_encoder(enc)
			if err != "":
				_fail("shot %s: ffmpeg failed: %s" % [shot["name"], err])
				return
			_log("shot %s: %d frames -> %s.mp4" % [shot["name"], shot["frames"], _shot_dir_name(shot)])
			continue
		_log("shot %s: %d frames -> %s" % [shot["name"], shot["frames"], dir])
	for p in pending:
		WorkerThreadPool.wait_for_task_completion(p[0])
	_log("rendered %s at %dx%d %d fps in %.1f s" % [episode["id"], size.x, size.y, fps, (Time.get_ticks_msec() - t0) / 1000.0])
	get_tree().quit(0)


## Starts ffmpeg reading raw frames of img's size from a pipe. Args from tf.py: --ffmpeg (path),
## --vcodec ("|"-separated encoder args), --blur (sub-frames averaged per output frame), --out_fps.
func _open_encoder(out_path: String, img: Image) -> Dictionary:
	var fmt := img.get_format()
	var pix := "rgb24"
	if fmt == Image.FORMAT_RGBA8:
		pix = "rgba"
	elif fmt != Image.FORMAT_RGB8:
		fmt = Image.FORMAT_RGBA8
		pix = "rgba"
	var blur := int(args.get("blur", "1"))
	var a := PackedStringArray(["-y", "-loglevel", "error", "-nostats", "-f", "rawvideo", "-pix_fmt", pix,
		"-s", "%dx%d" % [img.get_width(), img.get_height()], "-r", str(_fps()), "-i", "-"])
	if blur > 1:
		a.append_array(["-vf", "tmix=frames=%d,framestep=%d" % [blur, blur]])
	a.append_array(String(args.get("vcodec", "-c:v|libx264|-preset|medium|-crf|18")).split("|", false))
	a.append_array(["-pix_fmt", "yuv420p", "-r", str(args.get("out_fps", _fps())), "-movflags", "+faststart", out_path])
	var p := OS.execute_with_pipe(String(args.get("ffmpeg", "ffmpeg")), a)
	if p.is_empty():
		return {"error": "could not start ffmpeg (%s)" % args.get("ffmpeg", "ffmpeg")}
	p["format"] = fmt
	return p


## Closes the pipe (end of input), waits for ffmpeg, returns "" or its error text.
func _close_encoder(enc: Dictionary) -> String:
	if enc.is_empty():
		return "no frames"
	(enc["stdio"] as FileAccess).close()
	var pid := int(enc["pid"])
	while OS.is_process_running(pid):
		OS.delay_msec(10)
	var code := OS.get_process_exit_code(pid)
	if code == 0:
		return ""
	var msg := (enc["stderr"] as FileAccess).get_buffer(8192).get_string_from_utf8()
	return "exit %d: %s" % [code, msg.strip_edges()]


## 9:16 framing check: for every reveal that appears during a shot, is it inside the frame while
## it is on screen in that shot? Poses the scene every 0.1 s (no drawing) and projects the reveal's
## extent. Writes [{"shot", "id", "off", "side", "first", "from", "to"}] to path ("off" = fraction of
## its on-screen time it is cut off; "first" = cut off at the moment it appears).
func _framing_report(path: String) -> void:
	var fps := _fps()
	var size := _out_size(float(args.get("scale", 1.0)))
	get_window().content_scale_size = size
	var vs := Vector2(size)
	var only := PackedStringArray(String(args.get("shots", "")).split(",", false))
	var issues := []
	var reveals: Array = spec.get("reveals", [])
	for shot in Episode.timeline(episode, fps):
		if not only.is_empty() and not (String(shot["name"]) in only):
			continue
		var t0 := float(shot["scene_t"])
		var t1 := t0 + float(shot["duration"])
		var mine := []
		for r in reveals:
			# Interest points: things that appear during this shot (set dressing at t=0 is skipped).
			if float(r["t"]) > 0.0 and float(r["t"]) >= t0 - 0.05 and float(r["t"]) < t1 - 0.1 and String(r.get("shape", "")) != "link":
				mine.append(r)
		if mine.is_empty():
			continue
		var stats := {}
		var n := maxi(2, int(float(shot["duration"]) * 10.0))
		for k in n:
			var p := float(k) / float(n - 1)
			var t := t0 + p * float(shot["duration"])
			var L := _at_time(t)
			var cam := Episode.camera_at(shot, p, L, look)
			if cam.has("error"):
				continue
			Shot.apply(camera, cam)
			for r in mine:
				var id := String(r["id"])
				var h := reveals_node.get_node_or_null(NodePath(id)) as Node3D
				# Skip the entrance (a drop starts above the frame, a rise below it).
				var et := float(r.get("enter_time", 0.5 if String(r.get("enter", "pop")) == "beam" else 0.35))
				if String(r.get("enter", "pop")) == "none":
					et = 0.0
				if h == null or not h.visible or t < float(r["t"]) + et:
					continue
				var a: Dictionary = L["actor_anchors"].get(id, {})
				if a.is_empty():
					continue
				# Another bay (sets sit 60 m apart): not in this shot.
				if camera.global_position.distance_to(a["pos"]) > 30.0:
					continue
				var st: Dictionary = stats.get(id, {"seen": 0, "off": 0, "first": "", "side": {}, "from": t, "to": t})
				var side := _offscreen_side(a["pos"], r, vs)
				st["seen"] += 1
				st["to"] = t
				if side != "":
					st["off"] += 1
					st["side"][side] = int(st["side"].get(side, 0)) + 1
					if st["seen"] == 1:
						st["first"] = side
				stats[id] = st
		for id in stats:
			var st: Dictionary = stats[id]
			if st["off"] == 0:
				continue
			var side := ""
			var best := 0
			for sd in st["side"]:
				if int(st["side"][sd]) > best:
					best = int(st["side"][sd])
					side = sd
			issues.append({"shot": shot["name"], "id": id, "off": snappedf(float(st["off"]) / float(st["seen"]), 0.01),
				"side": side, "first": st["first"] != "", "from": snappedf(st["from"], 0.01), "to": snappedf(st["to"], 0.01)})
	_write_json(path, issues)
	_log("framing: %d issue(s) -> %s" % [issues.size(), path])


## "" if the reveal's extent is inside the frame, else which side it leaves by (left/right/top/bottom/behind).
func _offscreen_side(center: Vector3, r: Dictionary, vs: Vector2) -> String:
	var size := float(r.get("size", 0.5))
	var half_w := size * 0.5
	var half_h := size * 0.5
	if r.has("text"):
		half_w = 0.27 * size * String(r["text"]).length()
	elif r.has("counter"):
		var c: Dictionary = r["counter"]
		var digits := str(int(absf(float(c.get("to", 0))))).length() + int(c.get("decimals", 0))
		var label_len := String(c.get("label", "")).length() * 0.3
		half_w = 0.27 * size * maxf(float(digits + String(c.get("prefix", "")).length() + String(c.get("suffix", "")).length()), label_len)
		half_h = size * 0.75 if c.has("label") else size * 0.5
	var right := camera.global_transform.basis.x
	var up := camera.global_transform.basis.y
	var margin := vs * 0.02
	for d in [Vector3.ZERO, right * half_w, -right * half_w, up * half_h, -up * half_h]:
		var q: Vector3 = center + d
		if camera.is_position_behind(q):
			return "behind"
		var sp := camera.unproject_position(q)
		if sp.x < margin.x:
			return "left"
		if sp.x > vs.x - margin.x:
			return "right"
		if sp.y < margin.y:
			return "top"
		if sp.y > vs.y - margin.y:
			return "bottom"
	return ""


func _run_storyboard(out_dir: String) -> void:
	var fps := _fps()
	get_window().content_scale_size = _out_size(float(args.get("scale", 1.0 / 3.0)))
	DirAccess.make_dir_recursive_absolute(out_dir)
	for shot in Episode.timeline(episode, fps):
		var frames := int(shot["frames"])
		var keys := [0, frames / 2, frames - 1]
		for j in keys.size():
			_frame_state(shot, keys[j])
			_restart_particles()
			for w in SETTLE_FRAMES:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var path := out_dir.path_join("%s_%s.png" % [_shot_dir_name(shot), "abc"[j]])
			get_viewport().get_texture().get_image().save_png(path)
		_log("storyboard %s (scene %.1f-%.1f s)" % [shot["name"], shot["scene_t"], float(shot["scene_t"]) + float(shot["duration"])])
	get_tree().quit(0)


# --- explore ----------------------------------------------------------------

func _start_explore() -> void:
	exploring = true
	get_window().content_scale_size = EXPLORE_RES
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(12, 12)
	hud.add_theme_font_size_override("font_size", 14)
	hud.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	hud.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	hud.add_theme_constant_override("outline_size", 6)
	layer.add_child(hud)
	_goto_view(0)


func _goto_view(i: int) -> void:
	view_idx = clampi(i, 0, Views.NAMES.size() - 1)
	var s := Shot.resolve(Views.NAMES[view_idx], _at_time(clock), look)
	if s.has("error"):
		_log(s["error"])
		return
	Shot.apply(camera, s)
	camera.sync_from_transform()
	_update_hud()


func _cycle_weather(key: String) -> void:
	var w: Dictionary = look_overrides.get("weather", {})
	var cur := float(w.get(key, 0.0))
	var idx := WEATHER_STEPS.find(cur)
	w[key] = WEATHER_STEPS[(idx + 1) % WEATHER_STEPS.size()]
	look_overrides["weather"] = w
	_rebuild_keep_camera()


func _rebuild_keep_camera() -> void:
	var xf := camera.global_transform
	_build()
	camera.global_transform = xf
	_update_hud()


func _update_hud() -> void:
	if not hud:
		return
	var w: Dictionary = look["weather"]
	var look_name := String(spec["look"]) if typeof(spec["look"]) == TYPE_STRING else "inline"
	hud.text = "TOWNFORGE  ·  seed %d  ·  look %s\n" % [seed_value, look_name] \
		+ "time %s  ·  fog %.2f  clouds %.2f  rain %.2f  snow %.2f\n" % [LookCompiler.format_time(look["time"]), float(look["ground_fog"]["density"]) * 10.0, float(look["sky"]["clouds"]), float(w["rain"]), float(w["snow"])] \
		+ "[1-5] views  [RMB+mouse] look  [WASD QE] fly  [Shift] fast  [wheel] speed\n" \
		+ "[T]/[Y] time ±1h  [F] fog  [C] clouds  [R] rain  [X] snow  [0] reset weather\n" \
		+ "[N]/[B] seed ±1  [L] next look  [P] screenshot  [H] hide
" 		+ "[Space] %s  [Backspace] restart   t = %.1fs  ·  %d actors" % ["pause" if playing else "play", clock, actors_node.get_child_count() if actors_node else 0]


func _process(delta: float) -> void:
	if exploring and playing:
		clock += delta
		ActorDirector.pose_all(actors_node, clock)
		RenderingServer.global_shader_parameter_set("scene_time", clock)
		if Engine.get_process_frames() % 10 == 0:
			_update_hud()


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if not exploring or not k or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			_goto_view(k.keycode - KEY_1)
		KEY_N, KEY_B:
			seed_value += 1 if k.keycode == KEY_N else -1
			_build()
			_goto_view(view_idx)
		KEY_L:
			var looks := LookCompiler.list_presets()
			var cur := String(spec["look"]) if typeof(spec["look"]) == TYPE_STRING else ""
			spec["look"] = looks[(looks.find(cur) + 1) % looks.size()]
			look_overrides.clear()
			_rebuild_keep_camera()
		KEY_T, KEY_Y:
			look_overrides["time"] = fposmod(float(look["time"]) + (1.0 if k.keycode == KEY_T else -1.0), 24.0)
			_rebuild_keep_camera()
		KEY_F:
			_cycle_weather("fog")
		KEY_C:
			_cycle_weather("clouds")
		KEY_R:
			_cycle_weather("rain")
		KEY_X:
			_cycle_weather("snow")
		KEY_0:
			look_overrides.erase("weather")
			_rebuild_keep_camera()
		KEY_P:
			hud.visible = false
			await RenderingServer.frame_post_draw
			var dir := Paths.repo_path("output/screens")
			DirAccess.make_dir_recursive_absolute(dir)
			var path := dir.path_join("seed%d_%s_%d.png" % [seed_value, LookCompiler.format_time(look["time"]).replace(":", ""), Time.get_unix_time_from_system()])
			get_viewport().get_texture().get_image().save_png(path)
			hud.visible = true
			_log("screenshot -> %s" % path)
		KEY_H:
			hud.visible = not hud.visible
		KEY_SPACE:
			playing = not playing
			_update_hud()
		KEY_BACKSPACE:
			clock = 0.0
			ActorDirector.pose_all(actors_node, clock)
			_update_hud()
		KEY_ESCAPE:
			get_tree().quit()


# --- utils ------------------------------------------------------------------

static func _parse_args(raw: PackedStringArray) -> Dictionary:
	var out := {}
	var i := 0
	while i < raw.size():
		var a := raw[i]
		if a.begins_with("--"):
			var key := a.substr(2)
			if i + 1 < raw.size() and not raw[i + 1].begins_with("--"):
				out[key] = raw[i + 1]
				i += 2
				continue
			out[key] = true
		i += 1
	return out


func _write_json(path: String, data) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  "))
	f.close()


func _log(msg: String) -> void:
	print("[TownForge] " + msg)


func _fail(msg: String) -> void:
	printerr("[TownForge] ERROR: " + msg)
	get_tree().quit(1)
