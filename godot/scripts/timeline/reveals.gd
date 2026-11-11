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

const KEYS := ["id", "t", "until", "prop", "shape", "text", "counter", "at", "size", "color", "yaw", "face",
	"enter", "enter_time", "exit", "exit_time", "spin", "bob", "glow", "sound", "note"]
const KINDS := ["prop", "shape", "text", "counter"]
const COUNTER_KEYS := ["from", "to", "land", "keys", "decimals", "prefix", "suffix", "commas", "label", "land_color"]
const ENTERS := ["pop", "drop", "rise", "slide_left", "slide_right", "beam", "grow", "none"]
const EXITS := ["shrink", "pop", "drop", "rise", "none"]
const SHAPES := ["box", "sphere", "cylinder", "cone", "card", "coin", "cash", "ring", "bottle", "pin", "chip", "phone"]
const DEFAULT_COLORS := {"box": "#f2f2f2", "sphere": "#f2f2f2", "cylinder": "#f2f2f2", "cone": "#f2f2f2",
	"card": "#ffffff", "coin": "#f2c230", "cash": "#4fbf6a", "ring": "#5fe3ff", "bottle": "#4a90e2",
	"pin": "#ff4d5a", "chip": "#2b2f36", "phone": "#16181d"}
const ENTER_TIME := 0.35
const EXIT_TIME := 0.25
const LAND_COLOR := "#ffd84a"


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
		for k in ["spin", "bob", "glow", "yaw"]:
			if r.has(k) and not (typeof(r[k]) in [TYPE_INT, TYPE_FLOAT]):
				e.append("%s: %s must be a number" % [w, k])
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
	if c.has("decimals") and (int(c["decimals"]) < 0 or int(c["decimals"]) > 3):
		e.append(w + ": counter.decimals must be 0..3")
	return e


static func _is_time(v) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and float(v) >= 0.0


## Errors for reveals whose 'at' / 'face' don't resolve in this set (L has actor anchors).
static func check(reveals, L: Dictionary) -> Array:
	var e := []
	for r in (reveals if reveals is Array else []):
		for k in ["at", "face"]:
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
		elif r.has("text"):
			content = _text(String(r["text"]), size, Color(String(r.get("color", "#ffffff"))), float(r.get("glow", 0.8)))
		else:
			content = _counter_node(r["counter"], size, Color(String(r.get("color", "#ffffff"))), float(r.get("glow", 0.8)))
		content.name = "content"
		h.add_child(content)
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
	for p in parts:
		var mi := MeshInstance3D.new()
		mi.mesh = p[0]
		mi.transform = p[1]
		mi.material_override = p[2]
		n.add_child(mi)
	return n


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
static func _text_mesh(text: String, height: float, col: Color, glow: float) -> MeshInstance3D:
	var tm := TextMesh.new()
	tm.text = text
	tm.font_size = 64
	tm.pixel_size = height / 64.0
	tm.depth = height * 0.12
	tm.curve_step = 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.5
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = glow
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
		match String(r.get("enter", "pop")):
			"pop":
				s = _back_out(a)
			"grow":
				s = smoothstep(0.0, 1.0, a)
			"drop":
				off.y = (1.0 - _bounce_out(a)) * (2.5 + size * 2.0)
			"rise":
				off.y = -(1.0 - _cubic_out(a)) * (size * 2.0 + 0.5)
				s = minf(1.0, a * 4.0)
			"slide_left":
				off = -right * (1.0 - _cubic_out(a)) * (2.0 + size * 3.0)
			"slide_right":
				off = right * (1.0 - _cubic_out(a)) * (2.0 + size * 3.0)
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
		var age := t - t0
		yaw += deg_to_rad(float(r.get("spin", 0.0))) * age
		off.y += sin(age * 2.6) * float(r.get("bob", 0.0))
		if r.has("counter"):
			s *= _pose_counter(h.get_node("content"), r["counter"], t, t0, Color(String(r.get("color", "#ffffff"))))
		h.position = p["pos"] + off
		h.rotation = Vector3(0, yaw, 0)
		h.scale = Vector3.ONE * maxf(s, 0.001)
		out[String(r["id"])] = {"pos": h.position + Vector3.UP * size * 0.5, "forward": Vector3(sin(yaw), 0, cos(yaw))}
	return out


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
		bool(c.get("commas", true)), String(c.get("prefix", "")), String(c.get("suffix", "")))
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


static func format_number(v: float, decimals: int, commas: bool, prefix: String, suffix: String) -> String:
	var s := String.num(absf(v), decimals) if decimals > 0 else str(int(round(absf(v))))
	if decimals > 0 and not s.contains("."):
		s += "." + "0".repeat(decimals)
	elif decimals > 0:
		var frac := s.get_slice(".", 1)
		s = s.get_slice(".", 0) + "." + (frac + "0".repeat(decimals)).substr(0, decimals)
	if commas:
		var ip := s.get_slice(".", 0)
		var grouped := ""
		while ip.length() > 3:
			grouped = "," + ip.substr(ip.length() - 3) + grouped
			ip = ip.substr(0, ip.length() - 3)
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
