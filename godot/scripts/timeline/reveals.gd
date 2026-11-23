## Reveals: things that appear in the world on a word: props, shapes, 3D text
## and counters. The style's core rule is that everything the narrator names
## shows up on screen exactly when it is said (docs/REVEALS_SPEC.md).
##
##   "reveals": [
##     { "id": "ig_bottle", "t": {"line": "n3", "word": "Instagram"},
##       "shape": "bottle", "color": "#e1306c", "at": {"anchor": "robot.head", "offset": [0.3, 0.4, 0.2]},
##       "size": 0.5, "enter": "drop", "spin": 30 },
##     { "id": "users", "t": {"line": "n2", "word": "billion", "offset": -1.2}, "at": "globe_top",
##       "counter": {"from": 0.5, "to": 3.5, "decimals": 1, "suffix": " BILLION",
##                   "land": {"line": "n2", "word": "billion"}, "label": "PEOPLE OPEN THEIR APPS"},
##       "size": 0.8, "color": "#ffffff" }
##   ]
##
## Times are scene seconds here (the Python resolver turns word references into
## numbers). State at t is a pure function of t, like actors.
extends RefCounted

const KitDB = preload("res://scripts/world/kit_db.gd")
const Shot = preload("res://scripts/camera/shot.gd")
const Toon = preload("res://scripts/actors/toon.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const KEYS := ["id", "t", "until", "prop", "shape", "text", "counter", "at", "size", "color", "yaw", "face",
	"enter", "enter_time", "exit", "exit_time", "spin", "bob", "glow", "sound", "note", "label", "label_color", "roll", "from", "moves",
	"tilt", "to", "billboard"]
const KINDS := ["prop", "shape", "text", "counter"]
const COUNTER_KEYS := ["from", "to", "land", "keys", "decimals", "prefix", "suffix", "commas", "group", "label", "land_color"]
const ENTERS := ["pop", "drop", "settle", "rise", "slide_left", "slide_right", "beam", "grow", "move", "none"]
const EXITS := ["shrink", "pop", "drop", "rise", "none"]
const SHAPES := ["box", "sphere", "cylinder", "cone", "card", "coin", "cash", "ring", "bottle", "pin", "chip", "phone",
	"refinery", "pump", "postcard", "scales", "frame", "garland", "cake", "cake_half", "binoculars", "sign", "spinner", "tower",
	"rickshaw", "plaque", "india", "crown", "moneybag", "vitrine", "laptop", "tank", "receipt", "podium",
	"cake_slice", "bowling_ball", "globe", "tape", "link", "knife", "orbit",
	"snail", "rocket", "meter", "bin", "clock", "clock_hand", "garage"]
## Shapes that print their "label" on their face: [x, y, z, text height] as fractions of size.
const LABELLED := {"card": [0.0, 0.62, 0.025, 0.09], "sign": [0.0, 1.12, 0.045, 0.13], "cake": [0.0, 0.2, 0.52, 0.1],
	"pump": [0.0, 0.98, 0.22, 0.08], "postcard": [-0.2, 0.08, 0.02, 0.08], "box": [0.0, 0.5, 0.505, 0.15],
	"cake_half": [0.0, 0.2, 0.52, 0.09], "plaque": [0.0, 0.1, 0.022, 0.085], "moneybag": [0.0, 0.3, 0.37, 0.14],
	"tank": [0.0, 0.42, 0.16, 0.1], "receipt": [0.0, 0.86, 0.016, 0.08], "bowling_ball": [0.0, -0.08, 0.5, 0.22],
	"garage": [0.0, 0.83, 0.43, 0.12], "meter": [0.0, 0.42, 0.21, 0.1]}
const DEFAULT_COLORS := {"box": "#f2f2f2", "sphere": "#f2f2f2", "cylinder": "#f2f2f2", "cone": "#f2f2f2",
	"card": "#ffffff", "coin": "#f2c230", "cash": "#4fbf6a", "ring": "#5fe3ff", "bottle": "#4a90e2",
	"pin": "#ff4d5a", "chip": "#2b2f36", "phone": "#16181d", "refinery": "#c9ced6", "pump": "#d6453d",
	"postcard": "#f6ecd2", "scales": "#e8b52a", "frame": "#d9a632", "garland": "#ff8c1a", "cake": "#ff9ec4",
	"cake_half": "#ff9ec4", "binoculars": "#1b1c22", "sign": "#ffffff", "spinner": "#ffffff", "tower": "#c9ced6", "rickshaw": "#2f9e44", "plaque": "#d9a632",
	"india": "#ff9a3c", "crown": "#f2c230", "moneybag": "#c8a26a", "vitrine": "#7a1f2a", "laptop": "#9aa3b2", "tank": "#2f9e6a",
	"receipt": "#fbfbf6", "podium": "#5a3fa0", "cake_slice": "#ff9ec4", "bowling_ball": "#1f4fd8", "globe": "#2f7fd8",
	"tape": "#b9b9b4", "link": "#ff3b4a", "knife": "#dfe4ea", "orbit": "#5fe3ff", "snail": "#9ccf6a",
	"rocket": "#f4f4f2", "meter": "#1b1b22", "bin": "#3f7a5a", "clock": "#fbfbf6", "clock_hand": "#d6453d", "garage": "#c9b28a"}
## Chunky display font for text and counters (OFL, godot/fonts/lilita_one).
const FONT_PATH := "res://fonts/lilita_one/LilitaOne-Regular.ttf"
## Fallback for what Lilita lacks (the rupee sign, Devanagari): Baloo 2 at ExtraBold.
const FALLBACK_PATH := "res://fonts/baloo2/Baloo2.ttf"
const ENTER_TIME := 0.35
const EXIT_TIME := 0.25
const LAND_COLOR := "#ffd84a"


static var _font: FontFile


## Loaded straight from the .ttf (the project runs without an editor import step).
static func font() -> FontFile:
	if _font == null:
		_font = FontFile.new()
		var err := _font.load_dynamic_font(ProjectSettings.globalize_path(FONT_PATH))
		assert(err == OK, "reveals: cannot load " + FONT_PATH)
		var fb := FontFile.new()
		if fb.load_dynamic_font(ProjectSettings.globalize_path(FALLBACK_PATH)) == OK:
			var heavy := FontVariation.new()
			heavy.base_font = fb
			heavy.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 800}
			_font.fallbacks = [heavy, fb]
	return _font


static func validate(reveals) -> Array:
	if reveals == null:
		return []
	if typeof(reveals) != TYPE_ARRAY:
		return ["'reveals' must be an array"]
	var e := []
	var ids := {}
	for i in reveals.size():
		var r = reveals[i]
		var w := "reveals[%d]" % i
		if typeof(r) != TYPE_DICTIONARY:
			e.append(w + " must be an object")
			continue
		w = "reveals[%d] (%s)" % [i, r.get("id", "?")]
		for k in r:
			if not (k in KEYS):
				e.append("%s: unknown key '%s' (known: %s)" % [w, k, ", ".join(PackedStringArray(KEYS))])
		var id := String(r.get("id", ""))
		if id == "" or ids.has(id):
			e.append(w + ": needs a unique 'id'")
		ids[id] = true
		if not _is_time(r.get("t")):
			e.append(w + ": 't' must be scene seconds >= 0 (or a word reference, resolved by the pipeline)")
		if r.has("until") and (not _is_time(r["until"]) or (_is_time(r.get("t")) and float(r["until"]) <= float(r["t"]))):
			e.append(w + ": 'until' must be a time after 't'")
		var kinds := 0
		for k in KINDS:
			if r.has(k):
				kinds += 1
		if kinds != 1:
			e.append(w + ": needs exactly one of prop, shape, text, counter")
		if r.has("prop") and KitDB.model(String(r["prop"])).is_empty():
			e.append("%s: prop '%s' is not in library/catalog.json" % [w, r["prop"]])
		if r.has("shape") and not (String(r["shape"]) in SHAPES):
			e.append("%s: shape '%s' (known: %s)" % [w, r["shape"], ", ".join(PackedStringArray(SHAPES))])
		if r.has("text") and String(r["text"]).strip_edges() == "":
			e.append(w + ": text is empty")
		if r.has("billboard") and not (String(r["billboard"]) in ["y", "full"]):
			e.append(w + ": billboard must be 'y' (turn about the vertical, default) or 'full'")
		if String(r.get("billboard", "y")) == "full" and not r.has("face"):
			e.append(w + ": billboard 'full' needs 'face' (the point to turn toward, usually the camera's anchor)")
		if r.has("counter"):
			e.append_array(_validate_counter(r["counter"], w))
		if not r.has("at"):
			e.append(w + ": needs 'at' (an anchor, actor anchor like \"you.hand\", or {anchor, offset})")
		if r.has("color") and not Color.html_is_valid(String(r["color"])):
			e.append(w + ": color is not a hex colour")
		if r.has("enter") and not (String(r["enter"]) in ENTERS):
			e.append("%s: enter '%s' (known: %s)" % [w, r["enter"], ", ".join(PackedStringArray(ENTERS))])
		if r.has("exit") and not (String(r["exit"]) in EXITS):
			e.append("%s: exit '%s' (known: %s)" % [w, r["exit"], ", ".join(PackedStringArray(EXITS))])
		for k in ["size", "enter_time", "exit_time"]:
			if r.has(k) and (not (typeof(r[k]) in [TYPE_INT, TYPE_FLOAT]) or float(r[k]) <= 0.0):
				e.append("%s: %s must be a number > 0" % [w, k])
		if r.has("label") and not (r.has("shape") and LABELLED.has(String(r["shape"]))):
			e.append("%s: 'label' works on shapes %s" % [w, ", ".join(PackedStringArray(LABELLED.keys()))])
		if r.has("label_color") and not Color.html_is_valid(String(r["label_color"])):
			e.append(w + ": label_color is not a hex colour")
		for k in ["spin", "bob", "glow", "yaw", "roll"]:
			if r.has(k) and not (typeof(r[k]) in [TYPE_INT, TYPE_FLOAT]):
				e.append("%s: %s must be a number" % [w, k])
		if String(r.get("enter", "pop")) == "move" and (typeof(r.get("from")) != TYPE_ARRAY or r["from"].size() != 3):
			e.append(w + ": enter 'move' needs 'from': [x, y, z], the start offset in metres from 'at'")
		for m in r.get("moves", []):
			if typeof(m) != TYPE_DICTIONARY or not _is_time(m.get("t")) or (m.has("by") and (typeof(m["by"]) != TYPE_ARRAY \
					or m["by"].size() != 3)) or not (m.has("by") or m.has("turn") or m.has("tip") or m.has("scale")):
				e.append(w + ": each move is {\"t\": time, \"by\": [x, y, z] metres, \"dur\": s, \"turn\": degrees, \"tip\": degrees, \"scale\": n | [x, y, z], \"pulse\": bool}")
		if (String(r.get("shape", "")) == "link") != r.has("to"):
			e.append(w + ": shape 'link' needs 'to' (the point it reaches), and 'to' only works on links")
		if r.has("tilt") and not (typeof(r["tilt"]) in [TYPE_INT, TYPE_FLOAT]):
			e.append(w + ": tilt must be a number (degrees, sideways lean)")
		if r.has("yaw") and r.has("face"):
			e.append(w + ": give 'yaw' or 'face', not both")
	return e


static func _validate_counter(c, w: String) -> Array:
	if typeof(c) != TYPE_DICTIONARY:
		return [w + ": counter must be an object"]
	var e := []
	for k in c:
		if not (k in COUNTER_KEYS):
			e.append("%s: counter has unknown key '%s' (known: %s)" % [w, k, ", ".join(PackedStringArray(COUNTER_KEYS))])
	if c.has("keys"):
		if c.has("from") or c.has("to") or c.has("land"):
			e.append(w + ": counter takes 'keys' or from/to/land, not both")
		if typeof(c["keys"]) != TYPE_ARRAY or c["keys"].size() < 2:
			e.append(w + ": counter.keys must be [[time, value], ...] with at least 2 keys")
		else:
			var last := -1.0
			for k in c["keys"]:
				if typeof(k) != TYPE_ARRAY or k.size() != 2 or not _is_time(k[0]) or not (typeof(k[1]) in [TYPE_INT, TYPE_FLOAT]):
					e.append(w + ": each counter key is [time, value]")
				elif float(k[0]) < last:
					e.append(w + ": counter keys must be in time order")
				else:
					last = float(k[0])
	elif not c.has("to"):
		e.append(w + ": counter needs 'to' (and optional 'from', 'land') or 'keys'")
	if c.has("land") and not _is_time(c["land"]):
		e.append(w + ": counter.land must be a time")
	if c.has("land_color") and not Color.html_is_valid(String(c["land_color"])):
		e.append(w + ": counter.land_color is not a hex colour")
	if c.has("group") and not (String(c["group"]) in ["western", "indian"]):
		e.append(w + ": counter.group must be \"western\" (1,000,000) or \"indian\" (10,00,000)")
	if c.has("decimals") and (int(c["decimals"]) < 0 or int(c["decimals"]) > 3):
		e.append(w + ": counter.decimals must be 0..3")
	return e


static func _is_time(v) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and float(v) >= 0.0


## Errors for reveals whose 'at' / 'face' don't resolve in this set (L has actor anchors).
static func check(reveals, L: Dictionary) -> Array:
	var e := []
	for r in (reveals if reveals is Array else []):
		for k in ["at", "face", "to"]:
			if r.has(k):
				var p := Shot.point(L, r[k])
				if p.has("error"):
					e.append("reveal %s: %s: %s" % [r.get("id", "?"), k, p["error"]])
	return e


# --- build ----------------------------------------------------------------------------

static func build(reveals) -> Node3D:
	var root := Node3D.new()
	root.name = "Reveals"
	for r in (reveals if reveals is Array else []):
		var h := Node3D.new()
		h.name = String(r["id"])
		h.visible = false
		var size := float(r.get("size", 0.5))
		var content: Node3D
		if r.has("prop"):
			var mid := String(r["prop"])
			var sz := KitDB.size(mid)
			content = KitDB.instance(mid, size / maxf(maxf(sz.x, sz.y), maxf(sz.z, 0.001)))
		elif r.has("shape"):
			content = _shape(String(r["shape"]), size, Color(String(r.get("color", DEFAULT_COLORS[String(r["shape"])]))),
				float(r.get("glow", 0.0)))
			if r.has("label"):
				var lp: Array = LABELLED[String(r["shape"])]
				var lt := _text_mesh(String(r["label"]), size * float(lp[3]), Color(String(r.get("label_color", "#1b1b22"))), 0.0, false)
				lt.position = Vector3(float(lp[0]), float(lp[1]), float(lp[2])) * size
				content.add_child(lt)
		elif r.has("text"):
			content = _text(String(r["text"]), size, Color(String(r.get("color", "#ffffff"))), float(r.get("glow", 0.8)))
		else:
			content = _counter_node(r["counter"], size, Color(String(r.get("color", "#ffffff"))), float(r.get("glow", 0.8)))
		content.name = "content"
		h.add_child(content)
		if String(r.get("billboard", "y")) == "full":
			# Turned as a whole toward the "face" point every frame (pose), so the text meshes stop
			# billboarding on their own: the label stays under the number even seen from straight above.
			for mi in content.find_children("*", "MeshInstance3D", true, false):
				var mat := (mi as MeshInstance3D).material_override as BaseMaterial3D
				if mat:
					mat.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		if String(r.get("enter", "pop")) == "beam":
			var beam := MeshInstance3D.new()
			beam.name = "beam"
			var cm := CylinderMesh.new()
			cm.top_radius = 1.0
			cm.bottom_radius = 1.0
			cm.height = 1.0
			beam.mesh = cm
			var bm := StandardMaterial3D.new()
			bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			bm.albedo_color = Color(1, 1, 1, 0.85)
			bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			bm.emission_enabled = true
			bm.emission = Color(String(r.get("color", "#bfefff")))
			bm.emission_energy_multiplier = 4.0
			beam.material_override = bm
			beam.visible = false
			h.add_child(beam)
		root.add_child(h)
	return root


static func _shape(kind: String, size: float, col: Color, glow: float) -> Node3D:
	var n := Node3D.new()
	var mat := Toon.material(col, Toon.OUTLINE * 0.7)
	if glow > 0.0:
		mat = mat.duplicate()
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = glow
	var parts := []  # [mesh, transform, material]
	match kind:
		"box":
			parts.append([_box(Vector3.ONE * size), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.5, 0)), mat])
		"sphere":
			parts.append([Toon.sphere(size * 0.5), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.5, 0)), mat])
		"cylinder":
			parts.append([_cyl(size * 0.35, size * 0.35, size), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.5, 0)), mat])
		"cone":
			parts.append([_cyl(0.0, size * 0.4, size), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.5, 0)), mat])
		"ring":
			var tm := TorusMesh.new()
			tm.inner_radius = size * 0.38
			tm.outer_radius = size * 0.5
			tm.rings = 48
			parts.append([tm, Transform3D(Basis.from_euler(Vector3(PI / 2, 0, 0)), Vector3(0, size * 0.5, 0)), mat])
		"coin":
			parts.append([_cyl(size * 0.5, size * 0.5, size * 0.12), Transform3D(Basis.from_euler(Vector3(PI / 2, 0, 0)), Vector3(0, size * 0.5, 0)), mat])
		"card":
			# A white panel with a coloured header bar (profile cards, UI panels).
			parts.append([_box(Vector3(size * 0.7, size, size * 0.04)), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.5, 0)),
				Toon.material(Color("fbfbfb"), Toon.OUTLINE * 0.7)])
			parts.append([_box(Vector3(size * 0.7, size * 0.16, size * 0.05)), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.92, 0.002)), mat])
		"cash":
			parts.append([_box(Vector3(size, size * 0.3, size * 0.5)), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.15, 0)), mat])
			parts.append([_box(Vector3(size * 0.16, size * 0.31, size * 0.51)), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.15, 0)),
				Toon.material(Color("f4f1e4"), 0.0)])
		"bottle":
			parts.append([_cyl(size * 0.22, size * 0.22, size * 0.6), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.3, 0)), mat])
			parts.append([Toon.sphere(size * 0.22), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.6, 0)), mat])
			parts.append([_cyl(size * 0.1, size * 0.12, size * 0.2), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.85, 0)),
				Toon.material(Color("f6d8a8"), Toon.OUTLINE * 0.5)])
		"pin":
			# Map pin: a ball on a cone pointing down.
			parts.append([Toon.sphere(size * 0.3), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.7, 0)), mat])
			parts.append([_cyl(size * 0.22, 0.0, size * 0.5), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.3, 0)), mat])
			parts.append([Toon.sphere(size * 0.11), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.72, size * 0.22)),
				Toon.material(Color("ffffff"), 0.0)])
		"chip":
			parts.append([_box(Vector3(size, size * 0.12, size)), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.06, 0)), mat])
			parts.append([_box(Vector3(size * 0.55, size * 0.14, size * 0.55)), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.08, 0)),
				Toon.material(Color("c9ced6"), 0.0)])
		"phone":
			parts.append([_box(Vector3(size * 0.5, size, size * 0.06)), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.5, 0)), mat])
			var screen := Toon.material(Color("e9f1ff"), 0.0).duplicate() as StandardMaterial3D
			screen.emission_enabled = true
			screen.emission = Color("e9f1ff")
			screen.emission_energy_multiplier = 0.6
			parts.append([_box(Vector3(size * 0.44, size * 0.9, size * 0.01)), Transform3D(Basis.IDENTITY, Vector3(0, size * 0.5, size * 0.032)), screen])
	parts.append_array(_story_parts(kind, size, col, mat))
	for p in parts:
		var mi := MeshInstance3D.new()
		mi.mesh = p[0]
		mi.transform = p[1]
		mi.material_override = p[2]
		n.add_child(mi)
	return n


## Story props: [mesh, transform, material] parts, built from primitives in the toon style.
static func _story_parts(kind: String, size: float, col: Color, mat: Material) -> Array:
	var P := []
	var o := Toon.OUTLINE * 0.7
	match kind:
		"refinery":
			# Two banded towers, a round tank and a chimney with a flame.
			for t in [[-0.2, 0.9, 0.13], [0.12, 0.7, 0.16]]:
				P.append(_part(_cyl(size * t[2], size * t[2], size * t[1]), Vector3(size * t[0], size * t[1] * 0.5, 0), mat))
				for k in 3:
					P.append(_part(_cyl(size * t[2] * 1.06, size * t[2] * 1.06, size * 0.05),
						Vector3(size * t[0], size * t[1] * (0.25 + 0.25 * k), 0), Toon.material(Color("d6453d"), 0.0)))
			P.append(_part(Toon.sphere(size * 0.2), Vector3(size * 0.38, size * 0.16, size * 0.12), Toon.material(col.darkened(0.15), o)))
			P.append(_part(_cyl(size * 0.04, size * 0.05, size * 1.1), Vector3(size * -0.42, size * 0.55, -size * 0.1), Toon.material(Color("6b6f78"), o)))
			P.append(_part(_cyl(0.0, size * 0.07, size * 0.2), Vector3(size * -0.42, size * 1.2, -size * 0.1), _glow_mat(Color("ff8a1a"))))
		"pump":
			P.append(_part(_box(Vector3(size * 0.45, size * 0.85, size * 0.38)), Vector3(0, size * 0.425, 0), mat))
			P.append(_part(_box(Vector3(size * 0.32, size * 0.22, size * 0.02)), Vector3(0, size * 0.62, size * 0.2), Toon.material(Color("e9f1ff"), 0.0)))
			P.append(_part(_box(Vector3(size * 0.55, size * 0.16, size * 0.42)), Vector3(0, size * 0.97, 0), Toon.material(Color("f4f4f2"), o)))
			P.append(_part(_cyl(size * 0.025, size * 0.025, size * 0.5), Vector3(size * 0.27, size * 0.45, size * 0.05), Toon.material(Color("1b1b22"), 0.0)))
			P.append(_part(_box(Vector3(size * 0.08, size * 0.16, size * 0.08)), Vector3(size * 0.27, size * 0.72, size * 0.08), Toon.material(Color("1b1b22"), o)))
		"postcard":
			P.append(_part(_box(Vector3(size, size * 0.66, size * 0.02)), Vector3(0, size * 0.33, 0), mat))
			P.append(_part(_box(Vector3(size * 0.2, size * 0.24, size * 0.025)), Vector3(size * 0.33, size * 0.48, size * 0.003), Toon.material(Color("d6453d"), 0.0)))
			for k in 3:
				P.append(_part(_box(Vector3(size * 0.4, size * 0.012, size * 0.025)), Vector3(size * -0.2, size * (0.22 + 0.1 * k), size * 0.003), Toon.material(Color("8a7a66"), 0.0)))
		"scales":
			# Balance: base, pole, beam and two pans hanging on strings.
			P.append(_part(_cyl(size * 0.22, size * 0.28, size * 0.08), Vector3(0, size * 0.04, 0), mat))
			P.append(_part(_cyl(size * 0.03, size * 0.03, size * 0.8), Vector3(0, size * 0.44, 0), mat))
			P.append(_part(_box(Vector3(size * 1.1, size * 0.04, size * 0.05)), Vector3(0, size * 0.84, 0), mat))
			P.append(_part(Toon.sphere(size * 0.06), Vector3(0, size * 0.86, 0), mat))
			for sx in [-0.5, 0.5]:
				P.append(_part(_cyl(size * 0.006, size * 0.006, size * 0.36), Vector3(size * sx, size * 0.66, 0), Toon.material(Color("6b5a2a"), 0.0)))
				P.append(_part(_cyl(size * 0.2, size * 0.14, size * 0.05), Vector3(size * sx, size * 0.47, 0), mat))
		"frame":
			# A portrait frame, open: stand a character behind it.
			var fw := size * 0.8
			var fh := size
			var t := size * 0.07
			for y in [0.0, fh]:
				P.append(_part(_box(Vector3(fw + t, t, t * 0.8)), Vector3(0, y, 0), mat))
			for sx in [-0.5, 0.5]:
				P.append(_part(_box(Vector3(t, fh + t, t * 0.8)), Vector3(fw * sx, fh * 0.5, 0), mat))
		"garland":
			# Marigold beads on a sagging string; the ends hang at (+-size/2, 0).
			# Ends at (+-size/2, 0): put it on a frame's top corners. Deep U down the sides.
			var n := 44
			for i in n + 1:
				var u := float(i) / n
				var v := absf(2.0 * u - 1.0)
				var c := Color("ff8c1a") if i % 2 == 0 else Color("ffc21a")
				var x := (u - 0.5) * size * (0.9 + 0.1 * v)
				var y := -size * 0.95 * (1.0 - pow(v, 4.0))
				P.append(_part(Toon.sphere(size * 0.045), Vector3(x, y, 0), Toon.material(c, 0.0)))
			P.append(_part(Toon.sphere(size * 0.07), Vector3(0, -size * 0.97, size * 0.01), Toon.material(Color("e8452a"), 0.0)))
		"cake", "cake_half":
			var half := kind == "cake_half"
			P.append(_part(_cyl(size * 0.62, size * 0.62, size * 0.04), Vector3(0, size * 0.02, 0), Toon.material(Color("f4f4f2"), o)))
			for tier in [[0.5, 0.0, 0.32], [0.33, 0.32, 0.26]]:
				var m: Mesh = _half_cyl(size * tier[0], size * tier[2]) if half else _cyl(size * tier[0], size * tier[0], size * tier[2])
				P.append(_part(m, Vector3(0, size * (0.04 + tier[1] + tier[2] * 0.5), 0), mat))
				if not half:
					var tm := TorusMesh.new()
					tm.inner_radius = size * tier[0] * 0.94
					tm.outer_radius = size * tier[0] * 1.06
					P.append(_part(tm, Vector3(0, size * (0.04 + tier[1] + tier[2]), 0), Toon.material(Color("fffaf0"), 0.0)))
			if half:
				P.append(_part(_box(Vector3(size * 1.0, size * 0.32, size * 0.01)), Vector3(0, size * 0.2, 0), Toon.material(Color("f5d29a"), 0.0)))
				P.append(_part(_box(Vector3(size * 0.66, size * 0.26, size * 0.01)), Vector3(0, size * 0.49, 0), Toon.material(Color("f5d29a"), 0.0)))
			var cherries := 2 if half else 5
			for k in cherries:
				var a := (float(k) + 0.5) / float(cherries) * (PI if half else TAU) + (PI if half else 0.0)
				P.append(_part(Toon.sphere(size * 0.05), Vector3(cos(a) * size * 0.2, size * 0.66, sin(a) * size * 0.2), Toon.material(Color("d61f3a"), 0.0)))
		"binoculars":
			# Eyepieces at z = 0 (put it on "<actor>.face"), lenses toward +z, open tubes.
			var tube := _cyl(size * 0.13, size * 0.15, size * 0.36)
			tube.cap_top = false
			tube.cap_bottom = false
			var tube_mat := Toon.material(col, o).duplicate() as StandardMaterial3D
			tube_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			var glass := StandardMaterial3D.new()
			glass.albedo_color = Color(0.7, 0.88, 1.0, 0.22)
			glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			glass.roughness = 0.05
			glass.metallic_specular = 0.9
			for sx in [-0.17, 0.17]:
				P.append(_part(tube, Vector3(size * sx, 0, size * 0.18), tube_mat, Vector3(PI / 2, 0, 0)))
				var rim := TorusMesh.new()
				rim.inner_radius = size * 0.135
				rim.outer_radius = size * 0.17
				P.append(_part(rim, Vector3(size * sx, 0, size * 0.36), mat, Vector3(PI / 2, 0, 0)))
				P.append(_part(_cyl(size * 0.14, size * 0.14, size * 0.004), Vector3(size * sx, 0, size * 0.355), glass, Vector3(PI / 2, 0, 0)))
			P.append(_part(_box(Vector3(size * 0.16, size * 0.07, size * 0.1)), Vector3(0, 0, size * 0.16), mat))
		"sign":
			P.append(_part(_cyl(size * 0.03, size * 0.03, size * 0.9), Vector3(0, size * 0.45, 0), Toon.material(Color("8a5a2a"), o)))
			P.append(_part(_box(Vector3(size * 0.9, size * 0.42, size * 0.06)), Vector3(0, size * 1.1, 0), mat))
			P.append(_part(_box(Vector3(size * 0.96, size * 0.48, size * 0.04)), Vector3(0, size * 1.1, -size * 0.014), Toon.material(Color("d6453d"), 0.0)))
		"spinner":
			# Loading spinner: dots on a circle, fading. Spin it with "roll".
			for i in 8:
				var a := TAU * float(i) / 8.0
				var c := col.lerp(Color(0.25, 0.25, 0.3), float(i) / 8.0)
				P.append(_part(Toon.sphere(size * (0.1 - 0.006 * i)), Vector3(cos(a) * size * 0.4, sin(a) * size * 0.4, 0), Toon.material(c, 0.0)))
		"tower":
			# Telecom tower: a tapering lattice with dishes and a red tip light.
			for i in 4:
				var a := TAU * float(i) / 4.0 + PI / 4
				var b0 := Vector3(cos(a), 0, sin(a)) * size * 0.16
				var b1 := Vector3(cos(a), 0, sin(a)) * size * 0.04 + Vector3(0, size, 0)
				P.append([_cyl(size * 0.012, size * 0.012, b0.distance_to(b1)), Transform3D(_ybasis(b1 - b0), (b0 + b1) * 0.5), mat])
			for k in 5:
				var y := size * (0.15 + 0.17 * k)
				var w := size * 0.32 * (1.0 - y / size * 0.75)
				P.append(_part(_box(Vector3(w, size * 0.012, size * 0.012)), Vector3(0, y, w * 0.5), mat))
				P.append(_part(_box(Vector3(w, size * 0.012, size * 0.012)), Vector3(0, y, -w * 0.5), mat))
			for sx in [-1.0, 1.0]:
				P.append(_part(_cyl(size * 0.07, size * 0.07, size * 0.02), Vector3(sx * size * 0.07, size * 0.82, size * 0.05), Toon.material(Color("f4f4f2"), o), Vector3(PI / 2, 0, 0)))
			P.append(_part(Toon.sphere(size * 0.025), Vector3(0, size * 1.02, 0), _glow_mat(Color("ff4d5a"))))
		"plaque":
			# A brass name plate (put a "label" on it): wide, thin, with a darker rim.
			P.append(_part(_box(Vector3(size * 1.04, size * 0.24, size * 0.03)), Vector3(0, size * 0.1, -size * 0.004), Toon.material(col.darkened(0.35), o)))
			P.append(_part(_box(Vector3(size, size * 0.2, size * 0.035)), Vector3(0, size * 0.1, 0), mat))
		"rickshaw":
			# Auto-rickshaw: green lower body, yellow canopy, three wheels; faces +z.
			var yellow := Toon.material(Color("f2c230"), o)
			var black := Toon.material(Color("1b1b20"), o)
			P.append(_part(_box(Vector3(size * 0.55, size * 0.32, size * 0.95)), Vector3(0, size * 0.32, -size * 0.05), mat))
			P.append(_part(_box(Vector3(size * 0.3, size * 0.3, size * 0.25)), Vector3(0, size * 0.3, size * 0.5), mat))
			P.append(_part(_box(Vector3(size * 0.6, size * 0.06, size * 1.0)), Vector3(0, size * 0.98, -size * 0.05), yellow))
			for sx in [-0.27, 0.27]:
				P.append(_part(_box(Vector3(size * 0.04, size * 0.5, size * 0.04)), Vector3(size * sx, size * 0.72, size * 0.38), black))
			P.append(_part(_box(Vector3(size * 0.6, size * 0.48, size * 0.04)), Vector3(0, size * 0.72, -size * 0.53), yellow))
			P.append(_part(_box(Vector3(size * 0.5, size * 0.3, size * 0.02)), Vector3(0, size * 0.74, size * 0.42), Toon.material(Color("bfe2ff"), 0.0)))
			P.append(_part(_box(Vector3(size * 0.4, size * 0.08, size * 0.3)), Vector3(0, size * 0.5, -size * 0.25), black))
			for w in [Vector3(0, 0.12, 0.55), Vector3(-0.27, 0.12, -0.35), Vector3(0.27, 0.12, -0.35)]:
				P.append(_part(_cyl(size * 0.12, size * 0.12, size * 0.08), w * size, black, Vector3(0, 0, PI / 2)))
			P.append(_part(Toon.sphere(size * 0.05), Vector3(0, size * 0.42, size * 0.63), _glow_mat(Color("fff2c0"))))
		"india":
			# The map of India (official outline), lying flat: north toward -z, size = its height.
			# india_point() gives the spot of a (lon, lat) on it, for pins.
			var poly := PackedVector2Array()
			for q in INDIA:
				var v := india_point(q[0], q[1], size)
				poly.append(Vector2(v.x, v.z))
			P.append(_part(_slab(poly, size * 0.03), Vector3.ZERO, mat))
		"crown":
			P.append(_part(_cyl(size * 0.42, size * 0.4, size * 0.3), Vector3(0, size * 0.15, 0), mat))
			for k in 5:
				var a := TAU * float(k) / 5.0
				P.append(_part(_cyl(0.0, size * 0.1, size * 0.32), Vector3(cos(a) * size * 0.36, size * 0.44, sin(a) * size * 0.36), mat))
				P.append(_part(Toon.sphere(size * 0.05), Vector3(cos(a) * size * 0.36, size * 0.62, sin(a) * size * 0.36), mat))
			for k in 3:
				var a := TAU * (float(k) + 0.5) / 3.0 + PI * 0.5
				P.append(_part(Toon.sphere(size * 0.06), Vector3(cos(a) * size * 0.42, size * 0.15, sin(a) * size * 0.42),
					Toon.material(Color("d61f3a"), 0.0)))
		"moneybag":
			var bag := Toon.sphere(size * 0.38)
			P.append([bag, Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 0.92, 1.0)), Vector3(0, size * 0.36, 0)), mat])
			P.append(_part(_cyl(size * 0.1, size * 0.16, size * 0.14), Vector3(0, size * 0.74, 0), mat))
			P.append(_part(_cyl(size * 0.17, size * 0.17, size * 0.05), Vector3(0, size * 0.69, 0), Toon.material(Color("8a5a2a"), o)))
			P.append(_part(_cyl(0.0, size * 0.18, size * 0.12), Vector3(0, size * 0.86, 0), mat, Vector3(PI, 0, 0)))
		"vitrine":
			# A museum case: a plinth, a glass box, brass posts and a velvet rope in front.
			var gl := StandardMaterial3D.new()
			gl.albedo_color = Color(0.75, 0.9, 1.0, 0.18)
			gl.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gl.roughness = 0.05
			gl.metallic_specular = 1.0
			P.append(_part(_box(Vector3(size * 0.5, size * 0.45, size * 0.5)), Vector3(0, size * 0.225, 0), Toon.material(Color("efe6d6"), o)))
			P.append(_part(_box(Vector3(size * 0.46, size * 0.5, size * 0.46)), Vector3(0, size * 0.7, 0), gl))
			var brass := Toon.material(Color("d9a632"), o)
			for sx in [-0.45, 0.45]:
				P.append(_part(_cyl(size * 0.025, size * 0.03, size * 0.42), Vector3(size * sx, size * 0.21, size * 0.45), brass))
				P.append(_part(Toon.sphere(size * 0.045), Vector3(size * sx, size * 0.44, size * 0.45), brass))
			for k in 9:
				var u := float(k) / 8.0
				P.append(_part(Toon.sphere(size * 0.028), Vector3(size * (u - 0.5) * 0.9, size * (0.4 - sin(u * PI) * 0.1), size * 0.45), mat))
		"laptop":
			# Base toward +z, the screen hinged at the back, tilted back a little, lit.
			P.append(_part(_box(Vector3(size, size * 0.04, size * 0.65)), Vector3(0, size * 0.02, 0), mat))
			var lid := Basis.from_euler(Vector3(-0.22, 0, 0))
			P.append([_box(Vector3(size, size * 0.62, size * 0.035)), Transform3D(lid, Vector3(0, size * 0.33, -size * 0.36)), mat])
			var scr := Toon.material(Color("e9f1ff"), 0.0).duplicate() as StandardMaterial3D
			scr.emission_enabled = true
			scr.emission = Color("cfe3ff")
			scr.emission_energy_multiplier = 0.9
			P.append([_box(Vector3(size * 0.9, size * 0.52, size * 0.01)), Transform3D(lid, Vector3(0, size * 0.33, -size * 0.336)), scr])
			P.append(_part(_box(Vector3(size * 0.8, size * 0.008, size * 0.35)), Vector3(0, size * 0.042, size * 0.05), Toon.material(Color("3a3f4a"), 0.0)))
		"tank":
			# Oxygen cylinder: a tall rounded bottle, a white shoulder and a brass valve.
			P.append(_part(_cyl(size * 0.17, size * 0.17, size * 0.72), Vector3(0, size * 0.36, 0), mat))
			P.append(_part(Toon.sphere(size * 0.17), Vector3(0, size * 0.72, 0), Toon.material(Color("f4f4f2"), o)))
			P.append(_part(_cyl(size * 0.05, size * 0.06, size * 0.1), Vector3(0, size * 0.9, 0), Toon.material(Color("d9a632"), o)))
			P.append(_part(_cyl(size * 0.09, size * 0.09, size * 0.025), Vector3(0, size * 0.96, 0), Toon.material(Color("d9a632"), o), Vector3(PI / 2, 0, 0)))
		"receipt":
			# A long printed bill: paper strip, grey rows, a zigzag tear at the bottom.
			P.append(_part(_box(Vector3(size * 0.42, size, size * 0.01)), Vector3(0, size * 0.5, 0), mat))
			for k in 9:
				var wv := 0.3 if k % 3 else 0.22
				P.append(_part(_box(Vector3(size * wv, size * 0.012, size * 0.012)), Vector3(size * (wv * 0.5 - 0.17), size * (0.15 + 0.065 * k), size * 0.006),
					Toon.material(Color("9a9aa2"), 0.0)))
			for k in 6:
				P.append(_part(_box(Vector3(size * 0.05, size * 0.05, size * 0.012)), Vector3(size * (-0.175 + 0.07 * k), size * 0.0, 0), mat,
					Vector3(0, 0, PI / 4)))
		"cake_slice":
			# A wedge (36 degrees) of the two-tier cake, tip at the centre, crust toward +z.
			P.append(_part(_wedge(size * 0.5, size * 0.32, 0.63), Vector3(0, size * 0.04, 0), mat))
			P.append(_part(_wedge(size * 0.33, size * 0.26, 0.63), Vector3(0, size * 0.36, 0), mat))
			P.append(_part(Toon.sphere(size * 0.05), Vector3(0, size * 0.66, size * 0.22), Toon.material(Color("d61f3a"), 0.0)))
		"bowling_ball":
			# Centred on its own origin (place it 'size / 2' up) so 'roll' turns it in place.
			P.append(_part(Toon.sphere(size * 0.5), Vector3.ZERO, mat))
			for hole in [Vector3(-0.09, 0.2, 0.42), Vector3(0.09, 0.2, 0.42), Vector3(0.0, 0.31, 0.37)]:
				P.append(_part(Toon.sphere(size * 0.05), hole * size, Toon.material(Color("0b0d14"), 0.0)))
		"globe":
			# Blue sphere with green land blobs, centred on its origin (spin it).
			P.append(_part(Toon.sphere(size * 0.5), Vector3.ZERO, mat))
			var land := Toon.material(Color("5fbf5a"), 0.0)
			for b in [[0.3, 0.25, 0.32, 0.2], [-0.25, 0.1, 0.38, 0.22], [0.05, -0.3, 0.38, 0.16], [0.4, -0.1, -0.2, 0.18],
					[-0.35, 0.3, -0.2, 0.17], [0.0, 0.42, -0.2, 0.15], [-0.1, -0.15, -0.45, 0.2]]:
				var dir := Vector3(b[0], b[1], b[2]).normalized()
				P.append([Toon.sphere(size * float(b[3])), Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 0.7, 1.0)), dir * size * 0.43), land])
		"tape":
			# Duct tape: two crossed grey strips (an X), facing +z.
			for a in [0.6, -0.6]:
				P.append([_box(Vector3(size, size * 0.18, size * 0.02)), Transform3D(Basis.from_euler(Vector3(0, 0, a)), Vector3(0, size * 0.5, 0)), mat])
		"knife":
			# A giant kitchen knife standing tip-down (size = its length), blade facing +z.
			P.append(_part(_box(Vector3(size * 0.16, size * 0.62, size * 0.025)), Vector3(0, size * 0.33, 0), mat))
			P.append(_part(_cyl(0.0, size * 0.08, size * 0.08), Vector3(size * 0.0, size * 0.0, 0), mat, Vector3(PI, 0, 0)))
			P.append(_part(_box(Vector3(size * 0.2, size * 0.04, size * 0.06)), Vector3(0, size * 0.66, 0), Toon.material(Color("3a3f4a"), o)))
			P.append(_part(_box(Vector3(size * 0.12, size * 0.3, size * 0.07)), Vector3(0, size * 0.83, 0), Toon.material(Color("5a3420"), o)))
		"orbit":
			# A thin ring centred on its own origin (unlike "ring"), so yaw / tilt turn it about its centre:
			# cables wound round a globe.
			var om := TorusMesh.new()
			om.inner_radius = size * 0.485
			om.outer_radius = size * 0.5
			om.rings = 64
			om.ring_segments = 8
			P.append(_part(om, Vector3.ZERO, _glow_mat(col), Vector3(PI / 2, 0, 0)))
		"snail":
			# Faces +x (it crawls toward screen right): a soft body, a striped shell, eye stalks.
			var shell := Toon.material(Color("b5763a"), o)
			P.append([Toon.sphere(size * 0.16), Transform3D(Basis.IDENTITY.scaled(Vector3(3.2, 0.7, 1.0)), Vector3(size * 0.05, size * 0.1, 0)), mat])
			P.append(_part(Toon.sphere(size * 0.27), Vector3(-size * 0.08, size * 0.38, 0), shell))
			var sp := TorusMesh.new()
			sp.inner_radius = size * 0.1
			sp.outer_radius = size * 0.16
			for zz in [-1.0, 1.0]:
				P.append(_part(sp, Vector3(-size * 0.08, size * 0.38, zz * size * 0.24), Toon.material(Color("7a4a20"), 0.0), Vector3(PI / 2, 0, 0)))
			for zz in [-0.06, 0.06]:
				P.append(_part(_cyl(size * 0.015, size * 0.015, size * 0.22), Vector3(size * 0.5, size * 0.28, zz * size), mat, Vector3(0, 0, -0.35)))
				P.append(_part(Toon.sphere(size * 0.04), Vector3(size * 0.54, size * 0.39, zz * size), Toon.material(Color("ffffff"), o)))
		"rocket":
			# Points +y (tilt -90 to fly toward screen right): body, red nose, fins, window, flame.
			var red := Toon.material(Color("d6453d"), o)
			P.append(_part(_cyl(size * 0.13, size * 0.13, size * 0.55), Vector3(0, size * 0.42, 0), mat))
			P.append(_part(_cyl(0.0, size * 0.13, size * 0.25), Vector3(0, size * 0.82, 0), red))
			P.append(_part(_cyl(size * 0.06, size * 0.06, size * 0.02), Vector3(0, size * 0.55, size * 0.125), Toon.material(Color("5fe3ff"), 0.0), Vector3(PI / 2, 0, 0)))
			for k in 3:
				var a := TAU * float(k) / 3.0
				P.append([_box(Vector3(size * 0.02, size * 0.2, size * 0.14)), Transform3D(Basis.from_euler(Vector3(0, a, 0)),
					Vector3(sin(a) * size * 0.14, size * 0.2, cos(a) * size * 0.14)), red])
			P.append(_part(_cyl(size * 0.1, 0.0, size * 0.3), Vector3(0, size * 0.0, 0), _glow_mat(Color("ff9a1a"))))
		"meter":
			# A taxi fare meter: black box, red display (put a counter in front), a flag on top.
			P.append(_part(_box(Vector3(size, size * 0.6, size * 0.4)), Vector3(0, size * 0.3, 0), mat))
			P.append(_part(_box(Vector3(size * 0.86, size * 0.3, size * 0.02)), Vector3(0, size * 0.32, size * 0.2), _glow_mat(Color("ff3b2a"))))
			P.append(_part(_cyl(size * 0.02, size * 0.02, size * 0.35), Vector3(size * 0.38, size * 0.77, 0), Toon.material(Color("c9ced6"), o)))
			P.append(_part(_box(Vector3(size * 0.3, size * 0.16, size * 0.02)), Vector3(size * 0.24, size * 0.88, 0), Toon.material(Color("d6453d"), o)))
		"bin":
			# A dustbin, open at the top.
			P.append(_part(_cyl(size * 0.32, size * 0.25, size * 0.9), Vector3(0, size * 0.45, 0), mat))
			var rim := TorusMesh.new()
			rim.inner_radius = size * 0.3
			rim.outer_radius = size * 0.35
			P.append(_part(rim, Vector3(0, size * 0.9, 0), mat))
			P.append(_part(_cyl(size * 0.3, size * 0.3, size * 0.01), Vector3(0, size * 0.89, 0), Toon.material(Color("141418"), 0.0)))
		"clock":
			# A wall clock facing +z, centred on its origin (put a clock_hand on the same spot).
			P.append(_part(_cyl(size * 0.5, size * 0.5, size * 0.06), Vector3.ZERO, mat, Vector3(PI / 2, 0, 0)))
			var cr := TorusMesh.new()
			cr.inner_radius = size * 0.47
			cr.outer_radius = size * 0.53
			P.append(_part(cr, Vector3.ZERO, Toon.material(Color("1b1b22"), 0.0), Vector3(PI / 2, 0, 0)))
			for k in 12:
				var a := TAU * float(k) / 12.0
				P.append(_part(_box(Vector3(size * 0.025, size * 0.08, size * 0.02)), Vector3(sin(a) * size * 0.4, cos(a) * size * 0.4, size * 0.035),
					Toon.material(Color("1b1b22"), 0.0), Vector3(0, 0, -a)))
			P.append(_part(_box(Vector3(size * 0.04, size * 0.24, size * 0.02)), Vector3(size * 0.06, size * 0.08, size * 0.04), Toon.material(Color("1b1b22"), 0.0), Vector3(0, 0, -0.9)))
		"clock_hand":
			# A second hand pointing up from its origin; give it "roll" to sweep.
			P.append(_part(_box(Vector3(size * 0.03, size * 0.42, size * 0.015)), Vector3(0, size * 0.17, size * 0.06), mat))
			P.append(_part(Toon.sphere(size * 0.04), Vector3(0, 0, size * 0.06), mat))
		"garage":
			# A garage: body, roll-up door with slats, flat roof, a sign board above the door (label).
			P.append(_part(_box(Vector3(size, size * 0.72, size * 0.8)), Vector3(0, size * 0.36, 0), mat))
			P.append(_part(_box(Vector3(size * 1.08, size * 0.06, size * 0.88)), Vector3(0, size * 0.75, 0), Toon.material(col.darkened(0.35), o)))
			P.append(_part(_box(Vector3(size * 0.7, size * 0.5, size * 0.02)), Vector3(0, size * 0.25, size * 0.405), Toon.material(Color("9aa3b2"), o)))
			for k in 6:
				P.append(_part(_box(Vector3(size * 0.7, size * 0.008, size * 0.025)), Vector3(0, size * (0.06 + 0.075 * k), size * 0.41), Toon.material(Color("6b7280"), 0.0)))
			P.append(_part(_box(Vector3(size * 0.8, size * 0.16, size * 0.03)), Vector3(0, size * 0.85, size * 0.41), Toon.material(Color("f2c230"), o)))
		"link":
			# Unit length along +y; the pose stretches it from 'at' to 'to'.
			P.append(_part(_cyl(size * 0.5, size * 0.5, 1.0), Vector3(0, 0.5, 0), _glow_mat(col)))
		"podium":
			# Winners' podium: 1 in the middle (tallest), 2 on screen left, 3 on screen right.
			for b in [[0.0, 0.5, "1"], [-0.36, 0.34, "2"], [0.36, 0.24, "3"]]:
				var hgt := size * float(b[1])
				# Facing +z, screen left is world -x.
				var c := col if b[2] == "1" else col.darkened(0.2)
				P.append(_part(_box(Vector3(size * 0.36, hgt, size * 0.36)), Vector3(size * float(b[0]), hgt * 0.5, 0), Toon.material(c, o)))
				var num := _text_mesh(b[2], size * 0.16, Color("ffd84a"), 0.6, false)
				P.append([num.mesh, Transform3D(Basis.IDENTITY, Vector3(size * float(b[0]), hgt * 0.55, size * 0.185)), num.material_override])
	return P


## The official outline of India (with all of Jammu & Kashmir and Ladakh), coarse:
## [longitude, latitude] going round clockwise from the northern tip.
const INDIA := [[74.6, 37.0], [77.0, 35.5], [78.2, 35.6], [80.2, 35.4], [79.4, 32.5], [78.8, 31.2], [80.2, 30.2],
	[81.1, 28.6], [83.3, 27.4], [85.0, 26.9], [87.9, 26.4], [88.2, 27.9], [88.9, 27.3], [89.8, 26.8], [92.0, 26.9],
	[92.1, 27.8], [94.4, 29.2], [96.2, 29.4], [97.4, 28.2], [96.9, 27.2], [95.3, 26.6], [94.7, 25.2], [94.2, 23.9],
	[93.4, 23.1], [92.7, 21.9], [92.3, 23.6], [91.9, 24.3], [90.2, 25.2], [89.8, 25.9], [88.5, 25.2], [88.8, 24.2],
	[88.9, 22.0], [87.0, 21.5], [86.5, 20.2], [85.0, 19.3], [84.0, 18.3], [82.3, 16.6], [80.3, 15.7], [80.2, 13.4],
	[79.8, 11.5], [79.8, 10.3], [78.4, 9.0], [77.5, 8.1], [76.4, 9.5], [75.7, 11.5], [74.8, 13.0], [74.1, 14.8],
	[73.4, 16.3], [72.8, 19.0], [72.6, 21.0], [72.2, 21.7], [70.9, 20.7], [69.0, 22.3], [70.2, 22.9], [68.5, 23.6],
	[70.0, 24.3], [71.0, 24.6], [70.5, 25.7], [69.6, 26.6], [70.6, 27.9], [72.4, 28.9], [73.4, 29.9], [74.6, 31.0],
	[74.7, 32.5], [74.0, 33.4], [73.8, 34.7]]
const INDIA_CENTER := [82.5, 22.5]
const INDIA_SPAN := 29.0


## Where a (lon, lat) sits on an "india" shape of this size, in its local space (north = -z).
static func india_point(lon: float, lat: float, size: float) -> Vector3:
	var k := size / INDIA_SPAN
	return Vector3((lon - INDIA_CENTER[0]) * k, size * 0.03, -(lat - INDIA_CENTER[1]) * k)


## A wedge of a cylinder: tip on the axis, opening toward +z, 'angle' radians wide, y from 0 to h.
static func _wedge(r: float, h: float, angle: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 10
	var up := Vector3(0, h, 0)
	var o := Vector3.ZERO
	for i in n:
		var a0 := PI * 0.5 - angle * 0.5 + angle * float(i) / n
		var a1 := PI * 0.5 - angle * 0.5 + angle * float(i + 1) / n
		var p0 := Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, 0, sin(a1) * r)
		for v in [o + up, p1 + up, p0 + up, o, p0, p1, p0, p1, p1 + up, p0, p1 + up, p0 + up]:
			st.add_vertex(v)
	var e0 := Vector3(cos(PI * 0.5 - angle * 0.5) * r, 0, sin(PI * 0.5 - angle * 0.5) * r)
	var e1 := Vector3(cos(PI * 0.5 + angle * 0.5) * r, 0, sin(PI * 0.5 + angle * 0.5) * r)
	for v in [o, e0 + up, e0, o, o + up, e0 + up, o, e1, e1 + up, o, e1 + up, o + up]:
		st.add_vertex(v)
	st.generate_normals()
	return st.commit()


## A flat extruded polygon (XZ outline), from y = 0 to y = h.
static func _slab(poly: PackedVector2Array, h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tris := Geometry2D.triangulate_polygon(poly)
	if tris.is_empty():
		tris = Geometry2D.triangulate_polygon(PackedVector2Array(Array(poly).duplicate()))
	for i in range(0, tris.size(), 3):
		for j in [0, 1, 2]:
			var v: Vector2 = poly[tris[i + j]]
			st.add_vertex(Vector3(v.x, h, v.y))
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var p0 := Vector3(a.x, 0, a.y)
		var p1 := Vector3(b.x, 0, b.y)
		var up := Vector3(0, h, 0)
		for v in [p0, p1, p1 + up, p0, p1 + up, p0 + up]:
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()


static func _part(m: Mesh, at: Vector3, material: Material, rot: Vector3 = Vector3.ZERO) -> Array:
	return [m, Transform3D(Basis.from_euler(rot), at), material]


static func _glow_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c.lerp(Color.WHITE, 0.3)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 4.0
	return m


static func _ybasis(dir: Vector3) -> Basis:
	var y := dir.normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	return Basis(x, y, x.cross(y))


## A half cylinder: the cut face on the local XY plane (facing +Z), the round side toward -Z.
static func _half_cyl(r: float, h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 24
	var lo := Vector3(0, -h * 0.5, 0)
	var up := Vector3(0, h, 0)
	for i in n:
		var a0 := PI + PI * float(i) / n
		var a1 := PI + PI * float(i + 1) / n
		var p0 := Vector3(cos(a0) * r, 0, sin(a0) * r) + lo
		var p1 := Vector3(cos(a1) * r, 0, sin(a1) * r) + lo
		for v in [p0, p1, p1 + up, p0, p1 + up, p0 + up, lo + up, p0 + up, p1 + up, lo, p1, p0]:
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()


## A flat (not billboarded) text mesh, for set dressing (shop signs).
static func text_node(text: String, height: float, col: Color) -> MeshInstance3D:
	return _text_mesh(text, height, col, 0.0, false)


## A shape as a node, for set dressing (builders reuse the reveal shapes).
static func shape_node(kind: String, size: float, col: Color) -> Node3D:
	return _shape(kind, size, col, 0.0)


static func _box(s: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = s
	return m


static func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 32
	return m


## Extruded 3D text, always turned toward the camera (Y billboard).
static func _text_mesh(text: String, height: float, col: Color, glow: float, billboard: bool = true) -> MeshInstance3D:
	var tm := TextMesh.new()
	tm.font = font()
	tm.text = text
	tm.font_size = 64
	tm.pixel_size = height / 64.0
	tm.depth = height * 0.12
	tm.curve_step = 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	# Floating text and counters never cast shadows (a key light would print them on the walls).
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.5
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = glow
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		m.billboard_keep_scale = true
	mi.material_override = m
	return mi


static func _text(text: String, size: float, col: Color, glow: float) -> Node3D:
	var n := Node3D.new()
	var mi := _text_mesh(text, size, col, glow)
	mi.name = "text"
	mi.position = Vector3(0, size * 0.5, 0)
	n.add_child(mi)
	return n


static func _counter_node(c: Dictionary, size: float, col: Color, glow: float) -> Node3D:
	var n := Node3D.new()
	var v := _text_mesh("0", size, col, glow)
	v.name = "value"
	v.position = Vector3(0, size * 0.5 + (size * 0.45 if c.has("label") else 0.0), 0)
	n.add_child(v)
	if c.has("label"):
		var l := _text_mesh(String(c["label"]), size * 0.3, col, glow)
		l.name = "label"
		l.position = Vector3(0, size * 0.25, 0)
		n.add_child(l)
	return n


# --- pose -------------------------------------------------------------------------------

## Show, place and animate every reveal for scene time t. L must hold the
## actor anchors for t. Returns anchors {id: {"pos", "forward"}} for shots.
static func pose(root: Node3D, reveals, t: float, L: Dictionary) -> Dictionary:
	var out := {}
	if root == null:
		return out
	for r in (reveals if reveals is Array else []):
		var h := root.get_node_or_null(NodePath(String(r["id"]))) as Node3D
		if h == null:
			continue
		var t0 := float(r["t"])
		var until := float(r.get("until", INF))
		var et := float(r.get("enter_time", 0.5 if String(r.get("enter", "pop")) == "beam" else ENTER_TIME))
		var xt := float(r.get("exit_time", EXIT_TIME))
		var exit := String(r.get("exit", "shrink"))
		var p := Shot.point(L, r["at"])
		# The anchor exists before and after the reveal is visible, so a camera can
		# frame the spot where something is about to pop in.
		if not p.has("error"):
			out[String(r["id"])] = {"pos": p["pos"] + Vector3.UP * float(r.get("size", 0.5)) * 0.5,
				"forward": Vector3(sin(deg_to_rad(float(r.get("yaw", 0.0)))), 0, cos(deg_to_rad(float(r.get("yaw", 0.0)))))}
		if t < t0 or p.has("error") or (t >= until and (exit == "none" or t >= until + xt)):
			h.visible = false
			continue
		h.visible = true
		var size := float(r.get("size", 0.5))
		var a := clampf((t - t0) / et, 0.0, 1.0)
		var s := 1.0
		var off := Vector3.ZERO
		var yaw := deg_to_rad(float(r.get("yaw", 0.0)))
		if r.has("face"):
			var f := Shot.point(L, r["face"])
			if not f.has("error"):
				var d: Vector3 = f["pos"] - p["pos"]
				yaw = atan2(d.x, d.z)
		var right := Vector3(cos(yaw), 0, -sin(yaw))
		var beam := h.get_node_or_null("beam") as MeshInstance3D
		# Squash/stretch around force and contact only (docs/MOTION_SPEC.md); volume preserved,
		# about the base (the contact point). Text and counters stay rigid so they read.
		var sq := 0.0
		var rigid: bool = r.has("text") or r.has("counter")
		match String(r.get("enter", "pop")):
			"pop":
				s = _back_out(a)
				# Shoots up tall as it grows, then the overshoot settles it round.
				sq = 0.22 * sin(minf(a * 1.5, 1.0) * PI)
			"grow":
				s = smoothstep(0.0, 1.0, a)
			"drop":
				off.y = (1.0 - _bounce_out(a)) * (2.5 + size * 2.0)
				# Stretched by the fall, squashed flat on the first contact, springs back.
				var contact := 1.0 / 2.75
				if a < contact:
					sq = 0.28 * pow(a / contact, 2.0)
				else:
					sq = Motion.impact((a - contact) * et, 0.4, 3.5, 8.0)
			"settle":
				# A soft fall: drifts down from a little above, eases in, a small sway.
				var k := 1.0 - pow(1.0 - a, 3.0)
				off.y = (1.0 - k) * (0.7 + size)
				yaw += sin(a * PI * 2.0) * (1.0 - a) * 0.35
			"rise":
				off.y = -(1.0 - _cubic_out(a)) * (size * 2.0 + 0.5)
				s = minf(1.0, a * 4.0)
			"slide_left":
				off = -right * (1.0 - _cubic_out(a)) * (2.0 + size * 3.0)
			"slide_right":
				off = right * (1.0 - _cubic_out(a)) * (2.0 + size * 3.0)
			"move":
				var f: Array = r["from"]
				off = Vector3(float(f[0]), float(f[1]), float(f[2])) * (1.0 - _cubic_out(a))
			"beam":
				s = _back_out(clampf((a - 0.35) / 0.65, 0.0, 1.0))
				if beam:
					beam.visible = a < 1.0
					var w := size * 0.45 * (1.0 - smoothstep(0.5, 1.0, a))
					var hh := 6.0 * (1.0 - _cubic_out(a) * 0.3)
					beam.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(maxf(w, 0.001), hh, maxf(w, 0.001))), Vector3(0, hh * 0.5, 0))
		if beam and String(r.get("enter", "pop")) != "beam":
			beam.visible = false
		if t >= until:
			var x := clampf((t - until) / xt, 0.0, 1.0)
			match exit:
				"shrink":
					s *= 1.0 - x * x * (3.0 - 2.0 * x)
				"pop":
					s *= 1.0 - _back_in(x)
				"drop":
					off.y -= x * x * (2.0 + size * 2.0)
				"rise":
					off.y += x * x * (3.0 + size * 2.0)
		if r.has("to"):
			_pose_link(h, r, p["pos"], Shot.point(L, r["to"]), a, t, until, xt)
			continue
		var age := t - t0
		var tip := deg_to_rad(float(r.get("tilt", 0.0)))
		yaw += deg_to_rad(float(r.get("spin", 0.0))) * age
		off.y += sin(age * 2.6) * float(r.get("bob", 0.0))
		# Timed moves after the entrance: slide by an offset (world metres), maybe turn.
		var sv := Vector3.ONE if rigid else Motion.squash(sq)
		for m in r.get("moves", []):
			var mk := clampf((t - float(m["t"])) / maxf(float(m.get("dur", 0.6)), 0.001), 0.0, 1.0)
			mk = mk * mk * (3.0 - 2.0 * mk)
			# "scale": squash / stretch / inflate / grow toward a multiplier (number or [x, y, z]);
			# "pulse": go there and back (a squash on impact, a gulp).
			if m.has("scale"):
				var sc = m["scale"]
				var target := Vector3.ONE * float(sc) if typeof(sc) in [TYPE_INT, TYPE_FLOAT] else Vector3(float(sc[0]), float(sc[1]), float(sc[2]))
				var raw := clampf((t - float(m["t"])) / maxf(float(m.get("dur", 0.6)), 0.001), 0.0, 1.0)
				var kk := sin(raw * PI) if bool(m.get("pulse", false)) else mk
				sv *= Vector3.ONE.lerp(target, kk)
			var by: Array = m.get("by", [0, 0, 0])
			off += Vector3(float(by[0]), float(by[1]), float(by[2])) * mk
			yaw += deg_to_rad(float(m.get("turn", 0.0))) * mk
			# "tip": fall over sideways about the base (+ = toward screen left when facing the camera),
			# with a small bounce as it lands.
			var tk := clampf((t - float(m["t"])) / maxf(float(m.get("dur", 0.6)), 0.001), 0.0, 1.0)
			tip += deg_to_rad(float(m.get("tip", 0.0))) * _bounce_out(tk * tk)
		if r.has("counter"):
			s *= _pose_counter(h.get_node("content"), r["counter"], t, t0, Color(String(r.get("color", "#ffffff"))))
		h.position = p["pos"] + off
		h.rotation = Vector3(0, yaw, tip)
		if String(r.get("billboard", "y")) == "full" and r.has("face"):
			var fp := Shot.point(L, r["face"])
			if not fp.has("error"):
				var z: Vector3 = (fp["pos"] - h.position).normalized()
				# The same up as the camera (shot.gd): world up, or world forward when looking straight down.
				var ref := Vector3.FORWARD if absf(z.dot(Vector3.UP)) > 0.999 else Vector3.UP
				var up := (ref - z * z.dot(ref)).normalized()
				h.basis = Basis(up.cross(z).normalized(), up, z)
		if r.has("roll"):
			(h.get_node("content") as Node3D).rotation.z = -deg_to_rad(float(r["roll"])) * age
		h.scale = (Vector3.ONE * maxf(s, 0.001)) * sv
		out[String(r["id"])] = {"pos": h.position + Vector3.UP * size * 0.5, "forward": Vector3(sin(yaw), 0, cos(yaw))}
	return out


## A link: a glowing line from 'at' to 'to' that grows out along its length (red link graphs, cables).
static func _pose_link(h: Node3D, r: Dictionary, p: Vector3, q: Dictionary, a: float, t: float, until: float, xt: float) -> void:
	if q.has("error"):
		h.visible = false
		return
	var d: Vector3 = q["pos"] - p
	var k := _cubic_out(a) if String(r.get("enter", "grow")) != "none" else 1.0
	if t >= until:
		k *= 1.0 - clampf((t - until) / xt, 0.0, 1.0)
	var length := maxf(d.length() * k, 0.001)
	var b := _ybasis(d if d.length() > 0.0001 else Vector3.UP)
	h.transform = Transform3D(Basis(b.x, b.y * length, b.z), p)


## Counter value at t, set on its text; returns the landing pop scale.
static func _pose_counter(n: Node3D, c: Dictionary, t: float, t0: float, col: Color) -> float:
	var keys: Array = c.get("keys", [])
	if keys.is_empty():
		keys = [[t0, float(c.get("from", 0.0))], [float(c.get("land", t0 + 1.5)), float(c["to"])]]
	var v := float(keys[0][1])
	for i in range(1, keys.size()):
		var ta := float(keys[i - 1][0])
		var tb := float(keys[i][0])
		if t >= tb:
			v = float(keys[i][1])
		elif t > ta:
			v = lerpf(float(keys[i - 1][1]), float(keys[i][1]), _cubic_out((t - ta) / maxf(tb - ta, 0.001)))
			break
	var land := float(keys[-1][0])
	var landed := t >= land
	var value := n.get_node("value") as MeshInstance3D
	var txt := format_number(v if not landed else float(keys[-1][1]), int(c.get("decimals", 0)),
		bool(c.get("commas", true)), String(c.get("prefix", "")), String(c.get("suffix", "")), String(c.get("group", "western")))
	var tm := value.mesh as TextMesh
	if tm.text != txt:
		tm.text = txt
	var m := value.material_override as StandardMaterial3D
	var want := Color(String(c.get("land_color", LAND_COLOR))) if landed else col
	if m.albedo_color != want:
		m.albedo_color = want
		m.emission = want
	if landed:
		var k := clampf((t - land) / 0.3, 0.0, 1.0)
		return 1.0 + 0.18 * sin(k * PI)
	return 1.0


static func format_number(v: float, decimals: int, commas: bool, prefix: String, suffix: String, group: String = "western") -> String:
	var s := String.num(absf(v), decimals) if decimals > 0 else str(int(round(absf(v))))
	if decimals > 0 and not s.contains("."):
		s += "." + "0".repeat(decimals)
	elif decimals > 0:
		var frac := s.get_slice(".", 1)
		s = s.get_slice(".", 0) + "." + (frac + "0".repeat(decimals)).substr(0, decimals)
	if commas:
		var ip := s.get_slice(".", 0)
		var grouped := ""
		# Indian grouping: the last three digits, then pairs (3,00,000; 1,50,000).
		var n := 3
		while ip.length() > n:
			grouped = "," + ip.substr(ip.length() - n) + grouped
			ip = ip.substr(0, ip.length() - n)
			n = 2 if group == "indian" else 3
		grouped = ip + grouped
		s = grouped + ("." + s.get_slice(".", 1) if s.contains(".") else "")
	return prefix + ("-" if v < 0.0 else "") + s + suffix


static func _cubic_out(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)


static func _back_out(x: float) -> float:
	var c1 := 1.9
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)


static func _back_in(x: float) -> float:
	var c1 := 1.7
	return (c1 + 1.0) * x * x * x - c1 * x * x


static func _bounce_out(x: float) -> float:
	var n1 := 7.5625
	var d1 := 2.75
	if x < 1.0 / d1:
		return n1 * x * x
	elif x < 2.0 / d1:
		x -= 1.5 / d1
		return n1 * x * x + 0.75
	elif x < 2.5 / d1:
		x -= 2.25 / d1
		return n1 * x * x + 0.9375
	x -= 2.625 / d1
	return n1 * x * x + 0.984375
