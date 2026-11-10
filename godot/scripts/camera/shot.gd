## Resolves a camera description into concrete camera settings.
##
## A camera description is a named view ("house:house_4") or an object:
##   view        start from a named view, then override
##   template    a saved shot in library/shots/<name>.json; "$subject" in it is
##               replaced by "subject"
##   subject     anchor the template is about
##   at          where the camera stands      } point: "house_4.curb"
##   look_at     what it looks at             }   | {"anchor": ref, "offset": [right, up, forward]}
##                                            }   | {"anchor": ref, "orbit": {"distance", "angle", "height"}}
##                                            }   | {"world": [x, y, z]}   (last resort)
##   direction   instead of look_at: {"yaw": deg, "pitch": deg}
##   height      force camera height above ground (m)
##   lens_mm     focal length (full-frame equivalent on the frame's long side); or "fov" in degrees
##   roll        dutch angle (deg); "pan", "tilt" add rotation after aiming (deg)
##   dof         {"focus": "look_at" | metres, "strength": 0..1}
##   exposure    EV offset (+1 = twice as bright)
##   orthographic  view height in metres (switches to orthographic projection)
extends RefCounted

const Paths = preload("res://scripts/core/paths.gd")
const Anchors = preload("res://scripts/camera/anchors.gd")
const Views = preload("res://scripts/camera/views.gd")

const KEYS := ["name", "t", "view", "template", "subject", "at", "look_at", "direction", "height",
	"lens_mm", "fov", "roll", "pan", "tilt", "dof", "exposure", "orthographic"]


static func lens_to_fov(mm: float) -> float:
	return rad_to_deg(2.0 * atan(18.0 / maxf(mm, 1.0)))


static func list_templates() -> PackedStringArray:
	return Paths.list_json("library/shots")


## Key-level validation, usable before a set exists.
static func validate(entry) -> Array:
	if typeof(entry) == TYPE_STRING:
		return [] if String(entry).split(":")[0] in Views.NAMES else ["unknown view '%s' (known: %s)" % [entry, ", ".join(PackedStringArray(Views.NAMES))]]
	if typeof(entry) != TYPE_DICTIONARY:
		return ["a shot must be a view name or an object"]
	var e := []
	for k in entry:
		if not (k in KEYS):
			e.append("shot: unknown key '%s' (known: %s)" % [k, ", ".join(PackedStringArray(KEYS))])
	if entry.has("template") and not FileAccess.file_exists(Paths.repo_path("library/shots/%s.json" % entry["template"])):
		e.append("unknown shot template '%s' (available: %s)" % [entry["template"], ", ".join(list_templates())])
	return e


static func _substitute(v, subject: String):
	match typeof(v):
		TYPE_STRING:
			return String(v).replace("$subject", subject)
		TYPE_DICTIONARY:
			var out := {}
			for k in v:
				out[k] = _substitute(v[k], subject)
			return out
		TYPE_ARRAY:
			var out := []
			for x in v:
				out.append(_substitute(x, subject))
			return out
	return v


## Returns {"pos": Vector3} or {"error": String}.
static func point(L: Dictionary, p) -> Dictionary:
	if typeof(p) == TYPE_STRING:
		var a := Anchors.resolve(L, p)
		return a if a.has("error") else {"pos": a["pos"]}
	if typeof(p) != TYPE_DICTIONARY:
		return {"error": "a point must be an anchor name or an object"}
	if p.has("world"):
		var w: Array = p["world"]
		return {"pos": Vector3(w[0], w[1], w[2])}
	if not p.has("anchor"):
		return {"error": "a point object needs 'anchor' (or 'world')"}
	var a := Anchors.resolve(L, String(p["anchor"]))
	if a.has("error"):
		return a
	if p.has("orbit"):
		var o: Dictionary = p["orbit"]
		var fwd: Vector3 = a["forward"]
		var dir := fwd.rotated(Vector3.UP, deg_to_rad(float(o.get("angle", 0.0))))
		return {"pos": a["pos"] + dir * float(o.get("distance", 10.0)) + Vector3.UP * float(o.get("height", 1.6))}
	if p.has("offset"):
		return {"pos": Anchors.offset_point(a, p["offset"])}
	return {"pos": a["pos"]}


## Returns camera settings or {"error": String}:
## {"transform", "fov", "orthographic" (0 = perspective), "dof": {...}, "exposure", "focus_distance"}
static func resolve(entry, L: Dictionary, look: Dictionary = {}) -> Dictionary:
	var errs := validate(entry)
	if not errs.is_empty():
		return {"error": "; ".join(PackedStringArray(errs))}
	var spec: Dictionary = {"view": entry} if typeof(entry) == TYPE_STRING else entry.duplicate(true)

	if spec.has("template"):
		var r := Paths.load_json(Paths.repo_path("library/shots/%s.json" % spec["template"]))
		if not r["ok"]:
			return {"error": r["error"]}
		var cam: Dictionary = r["data"].get("camera", {})
		var subject := String(spec.get("subject", r["data"].get("default_subject", "")))
		if subject == "" and JSON.stringify(cam).contains("$subject"):
			return {"error": "template '%s' needs a 'subject' anchor" % spec["template"]}
		var own := spec.duplicate(true)
		own.erase("template")
		spec = Paths.deep_merge(_substitute(cam, subject), own)

	var pos := Vector3.ZERO
	var target := Vector3.ZERO
	var fov := 55.0
	var have_pos := false
	var have_target := false
	if spec.has("view"):
		var f := Views.frame(String(spec["view"]), L)
		if f.has("error"):
			return f
		var t: Transform3D = f["transform"]
		pos = t.origin
		target = t.origin - t.basis.z * 20.0
		fov = f["fov"]
		have_pos = true
		have_target = true
	if spec.has("at"):
		var r := point(L, spec["at"])
		if r.has("error"):
			return {"error": "at: " + r["error"]}
		pos = r["pos"]
		have_pos = true
	if spec.has("height"):
		pos.y = float(spec["height"])
	if spec.has("look_at") and typeof(spec["look_at"]) == TYPE_DICTIONARY and spec["look_at"].has("sky"):
		# Aim at a sky body: {"sky": "sun"} / {"sky": "moon"} / {"sky": {"elevation", "azimuth"}}
		var sky_ref = spec["look_at"]["sky"]
		var el := 0.0
		var az := 0.0
		if typeof(sky_ref) == TYPE_STRING:
			if not look.has(sky_ref):
				return {"error": "look_at.sky '%s' needs a compiled look with a %s (use sun or moon)" % [sky_ref, sky_ref]}
			el = float(look[sky_ref]["elevation"])
			az = float(look[sky_ref]["azimuth"])
		else:
			el = float(sky_ref.get("elevation", 30.0))
			az = float(sky_ref.get("azimuth", 0.0))
		var d := -(Basis.from_euler(Vector3(deg_to_rad(-el), deg_to_rad(az), 0)) * Vector3.FORWARD)
		target = pos + d * 1000.0
		have_target = true
	elif spec.has("look_at"):
		var r := point(L, spec["look_at"])
		if r.has("error"):
			return {"error": "look_at: " + r["error"]}
		target = r["pos"]
		have_target = true
	elif spec.has("direction"):
		var d: Dictionary = spec["direction"]
		var b := Basis.from_euler(Vector3(deg_to_rad(float(d.get("pitch", 0.0))), deg_to_rad(float(d.get("yaw", 0.0))), 0))
		target = pos + b * Vector3.FORWARD * 10.0
		have_target = true
	elif spec.has("subject") and not have_target:
		var r := point(L, spec["subject"])
		if not r.has("error"):
			target = r["pos"]
			have_target = true
	if not have_pos:
		return {"error": "shot needs 'at' (or a 'view'/'template')"}
	if not have_target:
		return {"error": "shot needs 'look_at', 'direction' or a 'subject'"}
	if pos.distance_to(target) < 0.01:
		return {"error": "camera position and look_at are the same point"}

	var up := Vector3.UP
	if absf((target - pos).normalized().dot(Vector3.UP)) > 0.999:
		up = Vector3.FORWARD  # looking straight down/up
	var xf := Transform3D(Basis(), pos).looking_at(target, up)
	if spec.has("pan"):
		xf.basis = Basis(Vector3.UP, deg_to_rad(float(spec["pan"]))) * xf.basis
	if spec.has("tilt"):
		xf.basis = xf.basis * Basis(Vector3.RIGHT, deg_to_rad(float(spec["tilt"])))
	if spec.has("roll"):
		xf.basis = xf.basis * Basis(Vector3.BACK, deg_to_rad(float(spec["roll"])))

	if spec.has("lens_mm"):
		fov = lens_to_fov(float(spec["lens_mm"]))
	elif spec.has("fov"):
		fov = float(spec["fov"])

	var focus := pos.distance_to(target)
	var dof: Dictionary = spec.get("dof", {})
	if dof.has("focus") and typeof(dof["focus"]) != TYPE_STRING:
		focus = float(dof["focus"])
	return {
		"blocked_by": blockers(L, pos, target) if pos.distance_to(target) < 400.0 else [],
		"transform": xf,
		"fov": clampf(fov, 1.0, 170.0),
		"orthographic": float(spec.get("orthographic", 0.0)),
		"dof_strength": clampf(float(dof.get("strength", 0.0)), 0.0, 1.0),
		"focus_distance": focus,
		"exposure": float(spec.get("exposure", 0.0)),
	}


## What blocks the straight line from the camera to its subject? Samples the
## line against yard-tree canopies and house volumes. Returns descriptions like
## "tree at (12, -30)" or "house_4"; empty = clear line of sight.
static func blockers(L: Dictionary, from: Vector3, to: Vector3) -> Array:
	var out := []
	var length := from.distance_to(to)
	if length < 1.0:
		return out
	var steps := int(length / 0.5)
	for i in range(1, steps):
		var d := i * 0.5
		if d < 0.5 or d > length - 1.5:
			continue
		var p := from.lerp(to, d / length)
		for t in L.get("trees", []):
			if t["ground"] != "grass":
				continue
			var sc := float(t["scale"])
			var dx := p.x - float(t["pos"][0])
			var dz := p.z - float(t["pos"][2])
			# Canopy radius per variant (kit trees are wide and low-hanging).
			var rad: float = {"round": 3.0, "tall": 1.8, "pine": 2.2}.get(t["variant"], 2.5) * sc
			if dx * dx + dz * dz < rad * rad and p.y > 1.3 * sc and p.y < 9.0 * sc:
				var desc := "tree at (%d, %d)" % [roundi(float(t["pos"][0])), roundi(float(t["pos"][2]))]
				if not (desc in out):
					out.append(desc)
		for h in L.get("houses", []):
			var r: Array = h["rect"]
			# The house being looked at doesn't hide itself.
			if to.x > float(r[0]) and to.x < float(r[2]) and to.z > float(r[1]) and to.z < float(r[3]):
				continue
			if p.x > float(r[0]) and p.x < float(r[2]) and p.z > float(r[1]) and p.z < float(r[3]) 					and p.y < float(h["wall_h"]) + float(h["roof"]["h"]):
				if not (h["id"] in out):
					out.append(h["id"])
	return out


static func apply(camera: Camera3D, s: Dictionary) -> void:
	camera.global_transform = s["transform"]
	if float(s["orthographic"]) > 0.0:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = float(s["orthographic"])
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = float(s["fov"])
	var attrs := CameraAttributesPractical.new()
	var strength := float(s["dof_strength"])
	if strength > 0.0:
		var fd := float(s["focus_distance"])
		attrs.dof_blur_far_enabled = true
		attrs.dof_blur_far_distance = fd * 1.15 + 0.5
		attrs.dof_blur_far_transition = fd * 1.2 + 1.0
		attrs.dof_blur_near_enabled = true
		attrs.dof_blur_near_distance = maxf(fd * 0.6, 0.3)
		attrs.dof_blur_near_transition = maxf(fd * 0.4, 0.2)
		attrs.dof_blur_amount = 0.03 + 0.17 * strength
	attrs.exposure_multiplier = pow(2.0, float(s["exposure"]))
	camera.attributes = attrs
