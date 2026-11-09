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

const DEFAULT_SPEC := "specs/sets/blackwood.json"
const SETTLE_FRAMES := 30
const EXPLORE_RES := Vector2i(540, 960)
const WEATHER_STEPS := [0.0, 0.35, 0.7, 1.0]

var args := {}
var spec: Dictionary
var look_overrides := {}   # {"time": ..., "weather": {...}} layered over the spec's look
var look: Dictionary       # compiled
var layout: Dictionary
var set_node: Node3D
var actors_node: Node3D
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

	if args.has("stills"):
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
	return true


## Pose every actor at time t and return the layout with their anchors added,
## so shots can target "you" or "you.head" at that moment.
func _at_time(t: float) -> Dictionary:
	ActorDirector.pose_all(actors_node, t)
	var L := layout.duplicate(false)
	L["actor_anchors"] = ActorDirector.anchors(actors_node)
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
