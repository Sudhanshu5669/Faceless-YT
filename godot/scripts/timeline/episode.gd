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
##         (+ "start"/"end": scene seconds the move runs between, holding before and after)
##       { "name": "replay", "duration": 2, "scene_t": 6.0, "camera": "street" }   jump back in scene time
##     ] }
##
## Scene time runs continuously across cuts unless a shot sets "scene_t".
## Both ends of a move are resolved at every frame, so moves follow actors.
extends RefCounted

const Paths = preload("res://scripts/core/paths.gd")
const Shot = preload("res://scripts/camera/shot.gd")
const SetEvents = preload("res://scripts/timeline/set_events.gd")

const KEYS := ["schema_version", "id", "title", "description", "set", "look", "actors", "format", "shots", "events", "reveals", "gags"]
## Sound keys: resolved by the Python pipeline (pipeline/episode_audio.py), which
## also turns "fit" durations and time references into numbers before Godot runs.
const AUDIO_KEYS := ["narration", "lines", "sfx", "music", "ambience", "captions", "end_black", "review"]
const FORMAT_KEYS := ["resolution", "fps", "motion_blur"]
const SHOT_KEYS := ["name", "duration", "scene_t", "camera", "look", "note", "whip_in", "whip_out", "iris_in", "iris_out", "shake"]
const LookCompiler = preload("res://scripts/look/look_compiler.gd")
## Camera shake on impacts: "shake": [{"t": word ref, "amount": 0..1}] (docs/MOTION_SPEC.md).
## Trauma model: light 0.15, medium 0.4, heavy 0.8. These are the offsets at full trauma.
const SHAKE_MOVE := 0.07      # metres, camera-local x / y
const SHAKE_ROLL := 2.5       # degrees
const Motion = preload("res://scripts/timeline/motion.gd")
## Iris transitions: the frame seen through a mask that opens (in) or closes (out).
const IRISES := ["circle", "binoculars"]
const IRIS_HOLD := 0.7   # iris_in: seconds the mask holds before opening
const IRIS_OPEN := 0.6   # seconds to open / close
## Whip pans: the camera swings this far (degrees) in this long (s) at a cut.
const WHIPS := ["left", "right", "up", "down"]
const WHIP_ANGLE := 55.0
const WHIP_TIME := 0.3
const MOVE_KEYS := ["from", "to", "ease", "start", "end"]
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
	if ep.has("gags"):
		spec["gags"] = ep["gags"]
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
		if s.has("look"):
			for error in LookCompiler.compile(s["look"])["errors"]:
				e.append("%s look: %s" % [where, error])
		for k in ["whip_in", "whip_out"]:
			if s.has(k) and not (String(s[k]) in WHIPS):
				e.append("%s: %s must be one of %s" % [where, k, WHIPS])
		for k in ["iris_in", "iris_out"]:
			if s.has(k) and not (String(s[k]) in IRISES):
				e.append("%s: %s must be one of %s" % [where, k, IRISES])
		if s.has("shake"):
			if typeof(s["shake"]) != TYPE_ARRAY:
				e.append(where + ": shake must be a list of {\"t\", \"amount\"}")
			else:
				for sh in s["shake"]:
					if typeof(sh) != TYPE_DICTIONARY or not (typeof(sh.get("t")) in [TYPE_INT, TYPE_FLOAT]):
						e.append(where + ": each shake needs 't' (scene seconds or a word reference, resolved by tf)")
					elif sh.has("amount") and (float(sh["amount"]) <= 0.0 or float(sh["amount"]) > 1.0):
						e.append(where + ": shake amount must be in (0, 1] (light 0.15, medium 0.4, heavy 0.8)")
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
			for k in ["start", "end"]:
				if cam.has(k) and not (typeof(cam[k]) in [TYPE_INT, TYPE_FLOAT]):
					e.append("%s: camera move %s must be scene seconds (a time reference before resolving)" % [where, k])
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
			"first_frame": frame, "scene_t": scene_t, "camera": s["camera"], "look": s.get("look"),
			"whip_in": String(s.get("whip_in", "")), "whip_out": String(s.get("whip_out", "")),
			"iris_in": String(s.get("iris_in", "")), "iris_out": String(s.get("iris_out", "")),
			"shake": s.get("shake", [])})
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
		# "start"/"end" (scene seconds): the move runs only between them, holding its ends before and after.
		var q := p
		if cam.has("start") or cam.has("end"):
			var t0 := float(shot.get("scene_t", 0.0))
			var t := t0 + p * float(shot.get("duration", 1.0))
			q = Motion.seg(t, float(cam.get("start", t0)), float(cam.get("end", t0 + float(shot.get("duration", 1.0)))))
		s = mix(a, b, ease_progress(q, String(cam.get("ease", "in_out"))))
	if s.has("error"):
		return s
	return _shake(_whip(s, shot, p), shot, p)


## Camera shake: trauma from the shot's impacts, moved in the camera's own plane (+ a roll).
static func _shake(s: Dictionary, shot: Dictionary, p: float) -> Dictionary:
	var ev: Array = shot.get("shake", [])
	if ev.is_empty():
		return s
	var t := float(shot.get("scene_t", 0.0)) + p * float(shot.get("duration", 1.0))
	var k := Motion.shake(t, ev, 1.6, float(String(shot.get("name", "")).hash() % 97))
	if k == Vector3.ZERO:
		return s
	var tr: Transform3D = s["transform"]
	var out := s.duplicate()
	var b := tr.basis.rotated(tr.basis.z.normalized(), deg_to_rad(SHAKE_ROLL) * k.z)
	out["transform"] = Transform3D(b, tr.origin + tr.basis.x * SHAKE_MOVE * k.x + tr.basis.y * SHAKE_MOVE * k.y)
	return out


## The iris mask at move progress p: {"shape": 0 circle | 1 binoculars, "radius": screen heights}
## (radius >= 2 means no mask).
static func iris_at(shot: Dictionary, p: float) -> Dictionary:
	var dur := float(shot.get("duration", 1.0))
	var t := p * dur
	var shape := ""
	var r := 9.0
	if String(shot.get("iris_in", "")) != "" and t < IRIS_HOLD + IRIS_OPEN:
		shape = String(shot["iris_in"])
		var k := clampf((t - IRIS_HOLD) / IRIS_OPEN, 0.0, 1.0)
		r = lerpf(0.2, 1.4, k * k * (3.0 - 2.0 * k))
	elif String(shot.get("iris_out", "")) != "" and t > dur - IRIS_OPEN:
		shape = String(shot["iris_out"])
		var k := clampf((dur - t) / IRIS_OPEN, 0.0, 1.0)
		r = lerpf(0.0, 1.4, k * k)
	if shape == "" or r >= 1.39:
		return {"shape": 0, "radius": 9.0}
	return {"shape": IRISES.find(shape), "radius": r}


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
	out["far"] = maxf(float(a.get("far", 4000.0)), float(b.get("far", 4000.0)))
	if w >= 0.5:
		out["orthographic"] = b["orthographic"]
		out["blocked_by"] = b["blocked_by"]
	return out
