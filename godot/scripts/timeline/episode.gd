## Episodes: an ordered list of timed shots filmed in one set (episode.json).
##
##   { "schema_version": "0.1", "id": "blackwood_333", "title": "...",
##     "set": "specs/sets/blackwood_333.json",      set spec: set + look (+ actors)
##     "look": "night_fog",                          optional: replaces the spec's look
##     "actors": [ ... ],                            optional: replaces the spec's actors (cues live here)
##     "format": { "resolution": [1080, 1920], "fps": 30 },
##     "shots": [
##       { "name": "porch", "duration": 3.5,
##         "camera": { "at": {...}, "look_at": "you.head", "lens_mm": 35 } },     static (tracks moving anchors)
##       { "name": "push_in", "duration": 4,
##         "camera": { "from": {...shot}, "to": {...shot}, "ease": "in_out" } },  a move between two shots
##       { "name": "replay", "duration": 2, "scene_t": 6.0, "camera": "street" }   jump back in scene time
##     ] }
##
## Scene time runs continuously across cuts unless a shot sets "scene_t".
## Both ends of a move are resolved at every frame, so moves follow actors.
extends RefCounted

const Paths = preload("res://scripts/core/paths.gd")
const Shot = preload("res://scripts/camera/shot.gd")
const SetEvents = preload("res://scripts/timeline/set_events.gd")

const KEYS := ["schema_version", "id", "title", "description", "set", "look", "actors", "format", "shots", "events", "reveals"]
## Sound keys: resolved by the Python pipeline (pipeline/episode_audio.py), which
## also turns "fit" durations and time references into numbers before Godot runs.
const AUDIO_KEYS := ["narration", "lines", "sfx", "music", "ambience", "captions", "end_black", "review"]
const FORMAT_KEYS := ["resolution", "fps", "motion_blur"]
const SHOT_KEYS := ["name", "duration", "scene_t", "camera", "note", "whip_in", "whip_out"]
## Whip pans: the camera swings this far (degrees) in this long (s) at a cut.
const WHIPS := ["left", "right", "up", "down"]
const WHIP_ANGLE := 55.0
const WHIP_TIME := 0.3
const MOVE_KEYS := ["from", "to", "ease"]
const EASES := ["linear", "in", "out", "in_out"]
const DEFAULT_RESOLUTION := [1080, 1920]
const DEFAULT_FPS := 30


## Loads an episode and the set spec it films in. The returned spec has the
## episode's look/actors applied and no "preview". -> {"episode", "spec"} | {"error"}
static func load_episode(path: String) -> Dictionary:
	var r := Paths.load_json(path)
	if not r["ok"]:
		return {"error": r["error"]}
	var ep = r["data"]
	if typeof(ep) != TYPE_DICTIONARY:
		return {"error": "episode must be a JSON object"}
	if typeof(ep.get("set")) != TYPE_STRING:
		return {"error": "episode 'set' must be the path of a set spec (e.g. specs/sets/blackwood_333.json)"}
	var sr := Paths.load_json(Paths.resolve(String(ep["set"])))
	if not sr["ok"]:
		return {"error": "episode set: " + String(sr["error"])}
	var spec: Dictionary = sr["data"].duplicate(true)
	if ep.has("look"):
		spec["look"] = ep["look"]
	if ep.has("actors"):
		spec["actors"] = ep["actors"]
	if ep.has("reveals"):
		spec["reveals"] = ep["reveals"]
	spec.erase("preview")
	return {"episode": ep, "spec": spec}


## Key-level validation (no set needed). Cameras are resolved later, per frame.
static func validate(ep: Dictionary) -> Array:
	var e := []
	for k in ep:
		if not (k in KEYS) and not (k in AUDIO_KEYS):
			e.append("episode: unknown key '%s' (known: %s)" % [k, ", ".join(PackedStringArray(KEYS + AUDIO_KEYS))])
	if String(ep.get("id", "")) == "":
		e.append("episode needs an 'id'")
	var fmt = ep.get("format", {})
	if typeof(fmt) != TYPE_DICTIONARY:
		e.append("format must be an object")
	else:
		for k in fmt:
			if not (k in FORMAT_KEYS):
				e.append("format: unknown key '%s' (known: %s)" % [k, ", ".join(PackedStringArray(FORMAT_KEYS))])
		var res = fmt.get("resolution", DEFAULT_RESOLUTION)
		if typeof(res) != TYPE_ARRAY or res.size() != 2 or int(res[0]) < 64 or int(res[1]) < 64 \
				or int(res[0]) > 4096 or int(res[1]) > 4096:
			e.append("format.resolution must be [width, height] between 64 and 4096")
		var fps = fmt.get("fps", DEFAULT_FPS)
		if not (typeof(fps) in [TYPE_INT, TYPE_FLOAT]) or int(fps) < 1 or int(fps) > 60:
			e.append("format.fps must be 1..60")
	e.append_array(SetEvents.validate(ep.get("events")))
	var shots = ep.get("shots")
	if typeof(shots) != TYPE_ARRAY or shots.is_empty():
		e.append("episode needs a non-empty 'shots' list")
		return e
	var names := {}
	for i in shots.size():
		var s = shots[i]
		var where := "shots[%d]" % i
		if typeof(s) != TYPE_DICTIONARY:
			e.append(where + " must be an object")
			continue
		where += " (%s)" % s.get("name", "?")
		for k in s:
			if not (k in SHOT_KEYS):
				e.append("%s: unknown key '%s' (known: %s)" % [where, k, ", ".join(PackedStringArray(SHOT_KEYS))])
		for k in ["whip_in", "whip_out"]:
			if s.has(k) and not (String(s[k]) in WHIPS):
				e.append("%s: %s must be one of %s" % [where, k, WHIPS])
		var n := String(s.get("name", ""))
		if n == "" or not n.is_valid_filename() or n.contains(" "):
			e.append(where + ": needs a 'name' usable as a file name (no spaces)")
		elif names.has(n):
			e.append(where + ": duplicate shot name")
		names[n] = true
		var d = s.get("duration")
		if typeof(d) == TYPE_STRING or typeof(d) == TYPE_DICTIONARY:
			e.append(where + ": duration '%s' is resolved from the narration; render through `tf` (it resolves voice timing first)" % [d])
		elif not (typeof(d) in [TYPE_INT, TYPE_FLOAT]) or float(d) <= 0.0 or float(d) > 120.0:
			e.append(where + ": duration must be seconds in (0, 120]")
		if s.has("scene_t") and (not (typeof(s["scene_t"]) in [TYPE_INT, TYPE_FLOAT]) or float(s["scene_t"]) < 0.0):
			e.append(where + ": scene_t must be seconds >= 0")
		if not s.has("camera"):
			e.append(where + ": needs a 'camera'")
			continue
		var cam = s["camera"]
		if is_move(cam):
			for k in cam:
				if not (k in MOVE_KEYS):
					e.append("%s: camera move has unknown key '%s' (known: %s)" % [where, k, ", ".join(PackedStringArray(MOVE_KEYS))])
			if not cam.has("to"):
				e.append(where + ": a camera move needs 'from' and 'to'")
			if not (String(cam.get("ease", "in_out")) in EASES):
				e.append("%s: ease must be one of %s" % [where, EASES])
			for end in ["from", "to"]:
				if cam.has(end):
					e.append_array(_camera_errors(cam[end], "%s camera.%s" % [where, end]))
		else:
			e.append_array(_camera_errors(cam, where + " camera"))
	return e


static func _camera_errors(cam, where: String) -> Array:
	var e := []
	for m in Shot.validate(cam):
		e.append("%s: %s" % [where, m])
	if typeof(cam) == TYPE_DICTIONARY and cam.has("t"):
		e.append(where + ": no 't' in episode cameras (time comes from the timeline)")
	return e


static func is_move(cam) -> bool:
	return typeof(cam) == TYPE_DICTIONARY and cam.has("from")


static func fps_of(ep: Dictionary) -> int:
	return int(ep.get("format", {}).get("fps", DEFAULT_FPS))


static func resolution_of(ep: Dictionary) -> Array:
	return ep.get("format", {}).get("resolution", DEFAULT_RESOLUTION)


## The expanded timeline: one entry per shot with its frame range and scene time.
##   [{"index", "name", "duration", "frames", "first_frame", "scene_t", "camera"}]
static func timeline(ep: Dictionary, fps: int) -> Array:
	var out := []
	var scene_t := 0.0
	var frame := 0
	for i in ep["shots"].size():
		var s: Dictionary = ep["shots"][i]
		if s.has("scene_t"):
			scene_t = float(s["scene_t"])
		var dur := float(s["duration"])
		var frames := maxi(1, roundi(dur * fps))
		out.append({"index": i, "name": String(s["name"]), "duration": dur, "frames": frames,
			"first_frame": frame, "scene_t": scene_t, "camera": s["camera"],
			"whip_in": String(s.get("whip_in", "")), "whip_out": String(s.get("whip_out", ""))})
		scene_t += dur
		frame += frames
	return out


## Scene time and move progress (0..1) of frame k of a timeline shot.
static func frame_time(shot: Dictionary, k: int, fps: int) -> Dictionary:
	var frames := int(shot["frames"])
	return {"t": float(shot["scene_t"]) + float(k) / fps,
		"p": 0.0 if frames <= 1 else float(k) / (frames - 1)}


static func ease_progress(p: float, kind: String) -> float:
	p = clampf(p, 0.0, 1.0)
	match kind:
		"in":
			return p * p
		"out":
			return 1.0 - (1.0 - p) * (1.0 - p)
		"in_out":
			return p * p * (3.0 - 2.0 * p)
	return p


## Camera settings for a timeline shot at move progress p. L must carry the
## actor anchors of that moment. Same result format as Shot.resolve().
static func camera_at(shot: Dictionary, p: float, L: Dictionary, look: Dictionary) -> Dictionary:
	var cam = shot["camera"]
	var s: Dictionary
	if not is_move(cam):
		s = Shot.resolve(cam, L, look)
	else:
		var a := Shot.resolve(cam["from"], L, look)
		if a.has("error"):
			return {"error": "from: " + String(a["error"])}
		var b := Shot.resolve(cam["to"], L, look)
		if b.has("error"):
			return {"error": "to: " + String(b["error"])}
		s = mix(a, b, ease_progress(p, String(cam.get("ease", "in_out"))))
	if s.has("error"):
		return s
	return _whip(s, shot, p)


## Whip pans at the cuts: the camera swings in from (or out toward) a side,
## fast, so motion blur smears the frame (the style's main transition).
static func _whip(s: Dictionary, shot: Dictionary, p: float) -> Dictionary:
	var dur := float(shot.get("duration", 1.0))
	var t := p * dur
	var angle := 0.0
	var dir := ""
	if String(shot.get("whip_in", "")) != "" and t < WHIP_TIME:
		var k := t / WHIP_TIME
		angle = -(1.0 - (1.0 - pow(1.0 - k, 3.0))) * WHIP_ANGLE
		dir = String(shot["whip_in"])
	elif String(shot.get("whip_out", "")) != "" and t > dur - WHIP_TIME:
		var k := (t - (dur - WHIP_TIME)) / WHIP_TIME
		angle = k * k * k * WHIP_ANGLE
		dir = String(shot["whip_out"])
	if dir == "":
		return s
	var tr: Transform3D = s["transform"]
	var axis: Vector3 = tr.basis.y if dir in ["left", "right"] else tr.basis.x
	var sign := 1.0 if dir in ["left", "up"] else -1.0
	var out := s.duplicate()
	out["transform"] = Transform3D(tr.basis.rotated(axis.normalized(), deg_to_rad(angle * sign)), tr.origin)
	return out


## Blend two resolved shots: position and lens linearly, rotation by slerp.
static func mix(a: Dictionary, b: Dictionary, w: float) -> Dictionary:
	var ta: Transform3D = a["transform"]
	var tb: Transform3D = b["transform"]
	var q := ta.basis.get_rotation_quaternion().slerp(tb.basis.get_rotation_quaternion(), w)
	var out := a.duplicate()
	out["transform"] = Transform3D(Basis(q), ta.origin.lerp(tb.origin, w))
	for k in ["fov", "dof_strength", "focus_distance", "exposure"]:
		out[k] = lerpf(float(a[k]), float(b[k]), w)
	if w >= 0.5:
		out["orthographic"] = b["orthographic"]
		out["blocked_by"] = b["blocked_by"]
	return out
