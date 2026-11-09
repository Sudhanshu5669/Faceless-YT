## Compiles an authored look into concrete render settings for Look.apply().
##
## An authored look is either a preset name ("night_fog") or an object:
##   { "base": <preset name or look object>,     inherit everything from another look
##     "time": "03:33" | 3.55,                   sun, moon, sky, ambient, streetlights
##     "weather": {fog, clouds, rain, snow, wind, snow_cover},
##     ...any render field below, to override } (absurd values welcome)
##
## Order: defaults -> time model -> weather model -> explicit overrides.
## Explicit overrides always win, so "time": "12:00" + a black sun is an eclipse.
extends RefCounted

const Paths = preload("res://scripts/core/paths.gd")

const INTENT_KEYS := ["id", "description", "tags", "base", "time", "weather"]

const LIGHT_BODY := {
	"elevation": "number", "azimuth": "number", "color": "color", "energy": "number",
	"shadows": "bool", "softness": "number", "visible": "bool", "size": "number",
	"disc_color": "color", "glow": "number", "glow_color": "color",
}

## Authoring schema. Unknown keys are errors, so typos never pass silently.
const SCHEMA := {
	"id": "string", "description": "string", "tags": "strings",
	"base": "look_ref",
	"time": "time",
	"weather": {"fog": "unit", "clouds": "unit", "rain": "unit", "snow": "unit", "wind": "unit", "snow_cover": "unit"},
	"sky": {
		"top": "color", "horizon": "color", "stars": "number", "star_color": "color",
		"clouds": "unit", "cloud_color": "color", "cloud_shadow": "color", "cloud_speed": "number",
		"bodies": "bodies",
	},
	"sun": LIGHT_BODY,
	"moon": LIGHT_BODY,
	"lights": "lights",
	"ambient": {"color": "color", "energy": "number"},
	"exposure": "number",
	"fog": {
		"begin": "number", "end": "number", "curve": "number", "volumetric": "number",
		"color": "color", "emission": "color", "anisotropy": "number", "length": "number",
	},
	"ground_fog": {"density": "number", "height": "number", "falloff": "number", "color": "color", "emission": "color"},
	"glow": {"enabled": "bool", "intensity": "number", "bloom": "number", "threshold": "number"},
	"ssao": "bool",
	"grade": {
		"brightness": "number", "contrast": "number", "saturation": "number",
		"gradient_map": "colors", "vignette": "number", "grain": "number",
	},
	"palette": {
		"ground": "palette", "lawn": "palette", "asphalt": "palette", "lane_paint": "palette",
		"sidewalk": "palette", "driveway": "palette", "walkway": "palette", "fence": "palette",
		"siding": "palette", "roof": "palette", "trim": "palette", "door": "palette",
		"foliage": "palette", "bark": "palette", "car": "palette", "pole": "palette",
	},
	"practical_lights": {
		"level": "unit", "street_light_color": "color", "street_light_energy": "number",
		"street_light_fog": "number", "window_lit_chance": "unit", "window_color": "color",
		"window_energy": "number", "porch_light_chance": "unit", "porch_light_color": "color",
		"porch_light_energy": "number",
	},
}

const BODY_SCHEMA := {
	"kind": "string", "elevation": "number", "azimuth": "number", "size": "number",
	"color": "color", "glow": "number", "glow_color": "color",
}
const BODY_KINDS := ["sun", "moon", "planet"]
const EXTRA_LIGHT_SCHEMA := {"elevation": "number", "azimuth": "number", "color": "color", "energy": "number", "shadows": "bool"}

const RENDER_DEFAULTS := {
	"sky": {
		"top": "#4a78b8", "horizon": "#c4d6e6", "stars": 0.0, "star_color": "#ffffff",
		"clouds": 0.0, "cloud_color": "#ffffff", "cloud_shadow": "#9aa4b4", "cloud_speed": 0.006,
		"bodies": [],
	},
	"sun": {
		"elevation": 50.0, "azimuth": 40.0, "color": "#fff2dd", "energy": 2.2, "shadows": true,
		"softness": 0.5, "visible": true, "size": 1.6, "glow": 1.0,
	},
	"moon": {
		"elevation": -30.0, "azimuth": 0.0, "color": "#9db4e6", "energy": 0.0, "shadows": false,
		"softness": 0.5, "visible": true, "size": 2.2, "glow": 0.35, "disc_color": "#dfe6f2",
	},
	"lights": [],
	"ambient": {"color": "#b8c4d6", "energy": 0.6},
	"exposure": 1.0,
	"fog": {
		"begin": 120.0, "end": 700.0, "curve": 1.4, "volumetric": 0.0, "color": "#8090a0",
		"emission": "#000000", "anisotropy": 0.45, "length": 120.0,
	},
	"ground_fog": {"density": 0.0, "height": 8.0, "falloff": 0.25, "color": "#9aa6bb", "emission": "#000000"},
	"glow": {"enabled": true, "intensity": 0.85, "bloom": 0.03, "threshold": 0.9},
	"ssao": true,
	"grade": {"brightness": 1.0, "contrast": 1.05, "saturation": 1.05, "gradient_map": [], "vignette": 0.2, "grain": 0.0},
	"palette": {},
	"weather": {"rain": 0.0, "snow": 0.0, "wind": 0.2},
	"surface": {"wetness": 0.0, "snow_cover": 0.0},
	"practical_lights": {
		"level": 0.0, "street_light_color": "#ffaa5c", "street_light_energy": 9.0, "street_light_fog": 3.5,
		"window_lit_chance": 0.0, "window_color": "#ffc27a", "window_energy": 1.4,
		"porch_light_chance": 0.0, "porch_light_color": "#ffc98a", "porch_light_energy": 1.5,
	},
}

## Time-of-day keyframes (hours). Sun and moon positions are computed
## analytically; these hold the colours and energies at each time.
const TIME_KEYS := [
	{"t": 0.0, "top": "#050a17", "horizon": "#1d2533", "stars": 1.0, "sun": "#ff9a60", "sun_e": 0.0, "moon": "#9db4e6", "moon_e": 0.6, "amb": "#40527a", "amb_e": 0.85, "exp": 1.45, "prac": 1.0, "win": 0.3},
	{"t": 4.8, "top": "#050a17", "horizon": "#1d2533", "stars": 1.0, "sun": "#ff9a60", "sun_e": 0.0, "moon": "#9db4e6", "moon_e": 0.55, "amb": "#40527a", "amb_e": 0.85, "exp": 1.45, "prac": 1.0, "win": 0.12},
	{"t": 5.8, "top": "#1c2a50", "horizon": "#7a6a88", "stars": 0.25, "sun": "#ff9a70", "sun_e": 0.0, "moon": "#a8b0d8", "moon_e": 0.3, "amb": "#5a6080", "amb_e": 0.7, "exp": 1.3, "prac": 1.0, "win": 0.2},
	{"t": 6.8, "top": "#4a6aa0", "horizon": "#f0a080", "stars": 0.0, "sun": "#ffb08a", "sun_e": 1.0, "moon": "#c0c8e0", "moon_e": 0.0, "amb": "#8a7a90", "amb_e": 0.55, "exp": 1.1, "prac": 0.3, "win": 0.12},
	{"t": 9.0, "top": "#4f7fc0", "horizon": "#cfdbe6", "stars": 0.0, "sun": "#fff0dc", "sun_e": 1.9, "moon": "#c0c8e0", "moon_e": 0.0, "amb": "#b0bcd0", "amb_e": 0.6, "exp": 1.0, "prac": 0.0, "win": 0.0},
	{"t": 13.0, "top": "#4a78b8", "horizon": "#c4d6e6", "stars": 0.0, "sun": "#fff6e8", "sun_e": 2.3, "moon": "#c0c8e0", "moon_e": 0.0, "amb": "#b8c4d6", "amb_e": 0.65, "exp": 1.0, "prac": 0.0, "win": 0.0},
	{"t": 16.5, "top": "#4a74b0", "horizon": "#d8d4c8", "stars": 0.0, "sun": "#ffe6c0", "sun_e": 2.0, "moon": "#c0c8e0", "moon_e": 0.0, "amb": "#b0b4c4", "amb_e": 0.6, "exp": 1.0, "prac": 0.0, "win": 0.0},
	{"t": 18.3, "top": "#3e5a92", "horizon": "#f0b080", "stars": 0.0, "sun": "#ffc488", "sun_e": 1.7, "moon": "#c0c8e0", "moon_e": 0.0, "amb": "#8a7a88", "amb_e": 0.55, "exp": 1.0, "prac": 0.2, "win": 0.2},
	{"t": 19.3, "top": "#2b3a66", "horizon": "#d98a64", "stars": 0.0, "sun": "#ffb27a", "sun_e": 1.2, "moon": "#9db4e6", "moon_e": 0.0, "amb": "#7a6a80", "amb_e": 0.55, "exp": 1.0, "prac": 0.6, "win": 0.45},
	{"t": 20.3, "top": "#141e40", "horizon": "#3e4466", "stars": 0.5, "sun": "#ff8a5a", "sun_e": 0.0, "moon": "#9db4e6", "moon_e": 0.35, "amb": "#4a5a82", "amb_e": 0.7, "exp": 1.3, "prac": 1.0, "win": 0.55},
	{"t": 22.5, "top": "#050a17", "horizon": "#1d2533", "stars": 1.0, "sun": "#ff9a60", "sun_e": 0.0, "moon": "#9db4e6", "moon_e": 0.6, "amb": "#40527a", "amb_e": 0.85, "exp": 1.45, "prac": 1.0, "win": 0.4},
	{"t": 24.0, "top": "#050a17", "horizon": "#1d2533", "stars": 1.0, "sun": "#ff9a60", "sun_e": 0.0, "moon": "#9db4e6", "moon_e": 0.6, "amb": "#40527a", "amb_e": 0.85, "exp": 1.45, "prac": 1.0, "win": 0.3},
]

const SUNRISE := 6.3
const SUNSET := 19.7
const MOONRISE := 18.5


# --- public -------------------------------------------------------------------

static func list_presets() -> PackedStringArray:
	return Paths.list_json("library/looks")


## Returns {"ok": bool, "look": compiled Dictionary, "raw": merged authored look, "errors": Array}.
static func compile(ref) -> Dictionary:
	var r := resolve_raw(ref, 0)
	if not r["errors"].is_empty():
		return {"ok": false, "look": {}, "raw": {}, "errors": r["errors"]}
	var raw: Dictionary = r["raw"]
	var errors := validate(raw)
	if not errors.is_empty():
		return {"ok": false, "look": {}, "raw": raw, "errors": errors}
	var out: Dictionary = RENDER_DEFAULTS.duplicate(true)
	var t := parse_time(raw.get("time", 13.0))
	_apply_time(out, t)
	_apply_weather(out, raw.get("weather", {}))
	for k in raw:
		if k in INTENT_KEYS:
			continue
		out[k] = Paths.deep_merge(out.get(k), raw[k]) if out.has(k) else raw[k]
	out["time"] = t
	out["id"] = raw.get("id", "inline")
	return {"ok": true, "look": out, "raw": raw, "errors": []}


## Flattens the base chain into one authored look (base removed).
static func resolve_raw(ref, depth: int) -> Dictionary:
	if depth > 8:
		return {"raw": {}, "errors": ["look base chain is too deep (cycle?)"]}
	var spec: Dictionary
	if typeof(ref) == TYPE_STRING:
		var r := Paths.load_json(Paths.repo_path("library/looks/%s.json" % ref))
		if not r["ok"]:
			return {"raw": {}, "errors": ["unknown look '%s' (%s). Available: %s" % [ref, r["error"], ", ".join(list_presets())]]}
		if typeof(r["data"]) != TYPE_DICTIONARY:
			return {"raw": {}, "errors": ["look '%s' must be a JSON object" % ref]}
		spec = r["data"]
	elif typeof(ref) == TYPE_DICTIONARY:
		spec = ref
	else:
		return {"raw": {}, "errors": ["a look must be a preset name or an object"]}
	if not spec.has("base"):
		return {"raw": spec.duplicate(true), "errors": []}
	var b := resolve_raw(spec["base"], depth + 1)
	if not b["errors"].is_empty():
		return b
	var own: Dictionary = spec.duplicate(true)
	own.erase("base")
	var merged: Dictionary = Paths.deep_merge(b["raw"], own)
	# A child without its own id/description must not claim the base's.
	if not own.has("id"):
		merged.erase("id")
	return {"raw": merged, "errors": []}


static func validate(look: Dictionary) -> Array:
	var e := []
	_validate_obj(look, SCHEMA, "look", e)
	return e


## Accepts 3.55, "03:33", "3:33", "19:10". Returns hours in [0, 24).
static func parse_time(v) -> float:
	if typeof(v) == TYPE_STRING:
		var parts := String(v).split(":")
		if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
			return fposmod(float(parts[0]) + float(parts[1]) / 60.0, 24.0)
		return -1.0
	return fposmod(float(v), 24.0)


static func format_time(t: float) -> String:
	var m := roundi(t * 60.0) % (24 * 60)
	return "%02d:%02d" % [m / 60, m % 60]


# --- validation -----------------------------------------------------------------

static func _validate_obj(obj, schema: Dictionary, path: String, e: Array) -> void:
	if typeof(obj) != TYPE_DICTIONARY:
		e.append("%s must be an object" % path)
		return
	for k in obj:
		if not schema.has(k):
			e.append("%s: unknown key '%s' (known: %s)" % [path, k, ", ".join(PackedStringArray(schema.keys()))])
			continue
		_validate_value(obj[k], schema[k], "%s.%s" % [path, k], e)


static func _validate_value(v, kind, path: String, e: Array) -> void:
	if typeof(kind) == TYPE_DICTIONARY:
		_validate_obj(v, kind, path, e)
		return
	match kind:
		"string":
			if typeof(v) != TYPE_STRING:
				e.append("%s must be a string" % path)
		"strings":
			if typeof(v) != TYPE_ARRAY:
				e.append("%s must be an array of strings" % path)
		"number":
			if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
				e.append("%s must be a number" % path)
		"unit":
			if (typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT) or float(v) < 0.0 or float(v) > 1.0:
				e.append("%s must be a number from 0 to 1" % path)
		"bool":
			if typeof(v) != TYPE_BOOL:
				e.append("%s must be true or false" % path)
		"color":
			if typeof(v) != TYPE_STRING or not Color.html_is_valid(v):
				e.append("%s must be a hex colour like \"#ff8800\" (got %s)" % [path, v])
		"colors":
			if typeof(v) != TYPE_ARRAY:
				e.append("%s must be an array of hex colours" % path)
			else:
				for i in v.size():
					_validate_value(v[i], "color", "%s[%d]" % [path, i], e)
		"palette":
			if typeof(v) == TYPE_ARRAY:
				_validate_value(v, "colors", path, e)
			else:
				_validate_value(v, "color", path, e)
		"time":
			if parse_time(v) < 0.0:
				e.append("%s must be hours (3.5) or \"HH:MM\" (got %s)" % [path, v])
		"look_ref":
			if typeof(v) != TYPE_STRING and typeof(v) != TYPE_DICTIONARY:
				e.append("%s must be a preset name or a look object" % path)
		"bodies":
			if typeof(v) != TYPE_ARRAY:
				e.append("%s must be an array" % path)
				return
			for i in v.size():
				_validate_obj(v[i], BODY_SCHEMA, "%s[%d]" % [path, i], e)
				if typeof(v[i]) == TYPE_DICTIONARY and v[i].has("kind") and not (v[i]["kind"] in BODY_KINDS):
					e.append("%s[%d].kind must be one of %s" % [path, i, BODY_KINDS])
			if v.size() > 4:
				e.append("%s: at most 4 extra sky bodies" % path)
		"lights":
			if typeof(v) != TYPE_ARRAY:
				e.append("%s must be an array" % path)
				return
			for i in v.size():
				_validate_obj(v[i], EXTRA_LIGHT_SCHEMA, "%s[%d]" % [path, i], e)


# --- time model -------------------------------------------------------------------

static func sun_position(t: float) -> Vector2:
	var f := (t - SUNRISE) / (SUNSET - SUNRISE)
	return Vector2(62.0 * sin(PI * f), -100.0 + 200.0 * f)  # (elevation, azimuth)


static func moon_position(t: float) -> Vector2:
	var f := fposmod(t - MOONRISE, 24.0) / 12.0
	return Vector2(45.0 * sin(PI * f), -100.0 + 200.0 * f)


static func _apply_time(out: Dictionary, t: float) -> void:
	var k0: Dictionary = TIME_KEYS[0]
	var k1: Dictionary = TIME_KEYS[1]
	for i in TIME_KEYS.size() - 1:
		if t >= float(TIME_KEYS[i]["t"]) and t <= float(TIME_KEYS[i + 1]["t"]):
			k0 = TIME_KEYS[i]
			k1 = TIME_KEYS[i + 1]
			break
	var f := (t - float(k0["t"])) / maxf(0.001, float(k1["t"]) - float(k0["t"]))
	var c := func(key: String) -> String: return Color(k0[key]).lerp(Color(k1[key]), f).to_html(false)
	var n := func(key: String) -> float: return lerpf(float(k0[key]), float(k1[key]), f)

	out["sky"]["top"] = "#" + c.call("top")
	out["sky"]["horizon"] = "#" + c.call("horizon")
	out["sky"]["stars"] = n.call("stars")
	var sp := sun_position(t)
	var mp := moon_position(t)
	var sun_e: float = n.call("sun_e")
	var moon_e: float = n.call("moon_e")
	out["sun"].merge({"elevation": sp.x, "azimuth": sp.y, "color": "#" + c.call("sun"), "energy": sun_e, "shadows": sun_e >= moon_e}, true)
	out["moon"].merge({"elevation": mp.x, "azimuth": mp.y, "color": "#" + c.call("moon"), "energy": moon_e, "shadows": moon_e > sun_e}, true)
	out["ambient"] = {"color": "#" + c.call("amb"), "energy": n.call("amb_e")}
	out["exposure"] = n.call("exp")
	var win: float = n.call("win")
	out["practical_lights"].merge({"level": n.call("prac"), "window_lit_chance": win, "porch_light_chance": minf(1.0, win * 1.4)}, true)


# --- weather model ----------------------------------------------------------------

static func _apply_weather(out: Dictionary, w: Dictionary) -> void:
	var rain := float(w.get("rain", 0.0))
	var snow := float(w.get("snow", 0.0))
	var wind := float(w.get("wind", 0.2))
	var clouds := maxf(float(w.get("clouds", 0.0)), maxf(0.55 + 0.45 * rain if rain > 0.0 else 0.0, 0.5 + 0.3 * snow if snow > 0.0 else 0.0))
	var fog := maxf(float(w.get("fog", 0.0)), maxf(rain * 0.3, snow * 0.25))
	var sky: Dictionary = out["sky"]
	var horizon := Color(sky["horizon"])

	sky["clouds"] = clouds
	sky["cloud_speed"] = 0.002 + 0.02 * wind
	sky["cloud_color"] = "#" + horizon.lerp(Color.WHITE, 0.55).to_html(false)
	sky["cloud_shadow"] = "#" + horizon.darkened(0.25).to_html(false)
	sky["stars"] = float(sky["stars"]) * (1.0 - clouds)
	sky["top"] = "#" + Color(sky["top"]).lerp(horizon, clouds * 0.55).to_html(false)
	out["sun"]["energy"] = float(out["sun"]["energy"]) * (1.0 - 0.75 * clouds)
	out["sun"]["softness"] = 0.5 + 6.0 * clouds
	out["moon"]["energy"] = float(out["moon"]["energy"]) * (1.0 - 0.6 * clouds)
	var amb := Color(out["ambient"]["color"])
	var grey := Color(amb.get_luminance(), amb.get_luminance(), amb.get_luminance())
	out["ambient"]["color"] = "#" + amb.lerp(grey.lerp(amb, 0.5), clouds * 0.6).to_html(false)
	out["ambient"]["energy"] = float(out["ambient"]["energy"]) * (1.0 + 0.25 * clouds)

	if fog > 0.0:
		out["fog"].merge({
			"volumetric": 0.012 * fog,
			"begin": lerpf(120.0, 15.0, fog),
			"end": lerpf(700.0, 160.0, fog),
			"color": "#" + horizon.lerp(Color.WHITE, 0.15).to_html(false),
		}, true)
		out["ground_fog"].merge({
			"density": 0.1 * fog,
			"height": 4.0 + 8.0 * fog,
			"color": "#" + horizon.lerp(Color("#c8d2e6"), 0.45).to_html(false),
		}, true)
	out["grade"]["saturation"] = float(out["grade"]["saturation"]) * (1.0 - 0.2 * maxf(fog, clouds * 0.6))
	out["weather"] = {"rain": rain, "snow": snow, "wind": wind}
	out["surface"] = {
		"wetness": 0.35 + 0.65 * rain if rain > 0.0 else 0.0,
		"snow_cover": float(w.get("snow_cover", 0.35 + 0.65 * snow if snow > 0.0 else 0.0)),
	}
