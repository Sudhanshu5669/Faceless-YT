## Builds stage bays (stage_generator.gd): floors, walls, neon, lights,
## skylines and pedestals, in the toon style (outlined props, emissive neon).
extends RefCounted

const Gen = preload("res://scripts/world/generators/stage_generator.gd")
const Toon = preload("res://scripts/actors/toon.gd")
const SURFACE := preload("res://shaders/stage_surface.gdshader")
const Reveals = preload("res://scripts/timeline/reveals.gd")
const Kitchen = preload("res://scripts/world/builders/kitchen_dressing.gd")

const FLOOR_PATTERNS := {"checker": 0, "tiles": 1, "grid": 2, "wood": 3, "plain": 4, "carpet": 5, "road": 6, "marble": 7}
const WALL_PATTERNS := {"tiles": 1, "panels": 10, "plain": 4, "grid": 2, "brick": 11}
const DRUM_COLORS := ["#d6453d", "#2f6fd6", "#e8b52a", "#3aa35b"]

static var _neon_mats: Dictionary = {}


static func build(L: Dictionary, _look: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Set"
	for b in L["bays"]:
		root.add_child(_bay(b, int(L["seed"])))
	return root


static func _bay(b: Dictionary, seed_value: int) -> Node3D:
	var n := Node3D.new()
	n.name = String(b["id"])
	var c: Array = b["center"]
	n.position = Vector3(c[0], c[1], c[2])
	var w := float(b["size"][0])
	var d := float(b["size"][1])
	var fc: Array = b["floor_colors"]
	var nc: Array = b["neon_colors"]
	var outdoor := String(b["wall"]) in ["skyline", "bazaar"]
	# Floor (slightly bigger than the bay so wide shots never see its edge).
	var fw := w + (30.0 if outdoor else 2.0)
	var fd := d + (30.0 if outdoor else 2.0)
	var floor_kind := String(b["floor"])
	if floor_kind != "none":
		var floor := _plane(Vector2(fw, fd), _surface(FLOOR_PATTERNS[floor_kind], Color(String(fc[0])),
			Color(String(fc[1])), Color(String(nc[0])), 1.0 if floor_kind != "wood" else 0.25, false))
		floor.name = "floor"
		if floor_kind == "road":
			# The footpath runs along the shop fronts.
			(floor.material_override as ShaderMaterial).set_shader_parameter("foot_z", -d * 0.5 + 2.2)
		n.add_child(floor)
	# Back wall (and sides) or an open skyline.
	var wall_kind := String(b["wall"])
	if wall_kind == "skyline":
		_skyline(n, b, seed_value)
	elif wall_kind == "bazaar":
		_bazaar(n, b, seed_value)
		_skyline(n, b, seed_value)
	elif wall_kind == "haveli":
		_haveli(n, b, seed_value)
	elif wall_kind == "kitchen":
		n.add_child(Kitchen.build(d, Color(String(b["wall_color"]))))
	elif wall_kind != "none":
		var wc := Color(String(b["wall_color"]))
		var mat := _surface(WALL_PATTERNS[wall_kind], wc, wc.darkened(0.35), Color(String(nc[0])), 0.6, true)
		var back := _wall(Vector2(w + 2.0, Gen.WALL_H), mat)
		back.name = "wall_back"
		back.position = Vector3(0, Gen.WALL_H * 0.5, -d * 0.5)
		n.add_child(back)
		if bool(b["sides"]):
			for s in [-1.0, 1.0]:
				var side := _wall(Vector2(d + 2.0, Gen.WALL_H), mat)
				side.name = "wall_side_%s" % ("l" if s < 0 else "r")
				side.position = Vector3(s * (w * 0.5), Gen.WALL_H * 0.5, 0)
				side.rotation_degrees = Vector3(0, -90.0 * s, 0)
				n.add_child(side)
	_neon(n, b, w, d)
	if wall_kind != "kitchen":
		_lights(n, b, w, d)
	if not b["pedestal"].is_empty():
		_pedestal(n, b["pedestal"], nc, seed_value, String(b["id"]))
	return n


static func _surface(pattern: int, a: Color, bcol: Color, line: Color, cell: float, vertical: bool) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SURFACE
	m.set_shader_parameter("pattern", pattern)
	m.set_shader_parameter("color_a", a)
	m.set_shader_parameter("color_b", bcol)
	m.set_shader_parameter("line_color", line)
	m.set_shader_parameter("cell", cell)
	m.set_shader_parameter("vertical", vertical)
	return m


static func _plane(size: Vector2, mat: Material) -> MeshInstance3D:
	var pm := PlaneMesh.new()
	pm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = mat
	return mi


static func _wall(size: Vector2, mat: Material) -> MeshInstance3D:
	var qm := QuadMesh.new()
	qm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	mi.material_override = mat
	return mi


static func neon_material(col: Color, energy: float = 4.0) -> StandardMaterial3D:
	var key := "%s|%.2f" % [col.to_html(), energy]
	if not _neon_mats.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = col.lerp(Color.WHITE, 0.35)
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = energy
		_neon_mats[key] = m
	return _neon_mats[key]


static func _tube(a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var cm := CapsuleMesh.new()
	cm.radius = r
	cm.height = a.distance_to(b) + r * 2.0
	cm.radial_segments = 12
	cm.rings = 2
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = mat
	var y := (b - a).normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y, x.cross(y)), (a + b) * 0.5)
	return mi


static func _neon(n: Node3D, b: Dictionary, w: float, d: float) -> void:
	var nc: Array = b["neon_colors"]
	var c0 := neon_material(Color(String(nc[0])))
	var c1 := neon_material(Color(String(nc[min(1, nc.size() - 1)])))
	var z := -d * 0.5 + 0.08
	var g := Node3D.new()
	g.name = "neon"
	n.add_child(g)
	for kind in b["neon"]:
		match String(kind):
			"tubes":
				for i in 4:
					var x: float = [-0.42, -0.3, 0.3, 0.42][i] * w
					g.add_child(_tube(Vector3(x, 0.6, z), Vector3(x, 3.6 + (i % 2) * 0.6, z), 0.045, c0 if i % 2 == 0 else c1))
			"ring":
				var tm := TorusMesh.new()
				tm.inner_radius = 1.62
				tm.outer_radius = 1.76
				tm.rings = 64
				tm.ring_segments = 8
				var ring := MeshInstance3D.new()
				ring.mesh = tm
				ring.material_override = c1
				ring.transform = Transform3D(Basis.from_euler(Vector3(PI / 2, 0, 0)), Vector3(0, 3.0, z + 0.05))
				g.add_child(ring)
			"strip":
				g.add_child(_tube(Vector3(-w * 0.5, 0.12, z), Vector3(w * 0.5, 0.12, z), 0.04, c0))
				g.add_child(_tube(Vector3(-w * 0.5, Gen.WALL_H - 0.35, z), Vector3(w * 0.5, Gen.WALL_H - 0.35, z), 0.04, c1))
			"arch":
				var segs := 14
				var prev := Vector3(-1.9, 0.0, z)
				for i in range(1, segs + 1):
					var a := PI * float(i) / segs
					var p := Vector3(-1.9 * cos(a), 1.9 * sin(a) * 1.5, z)
					g.add_child(_tube(prev + Vector3(0, 0.5, 0), p + Vector3(0, 0.5, 0), 0.05, c0))
					prev = p
			"frame":
				var fw := w * 0.32
				var pts := [Vector3(-fw, 1.0, z), Vector3(fw, 1.0, z), Vector3(fw, 4.2, z), Vector3(-fw, 4.2, z)]
				for i in 4:
					g.add_child(_tube(pts[i], pts[(i + 1) % 4], 0.045, c1 if i % 2 == 0 else c0))


static func _lights(n: Node3D, b: Dictionary, w: float, d: float) -> void:
	var nc: Array = b["neon_colors"]
	if String(b.get("mood", "flat")) == "dramatic":
		_lights_dramatic(n, b, w, d)
		return
	var key := SpotLight3D.new()
	key.name = "key"
	key.light_color = Color(String(b["light"]))
	key.light_energy = 7.0
	key.spot_range = 22.0
	key.spot_angle = 42.0
	key.spot_attenuation = 0.6
	key.shadow_enabled = true
	key.position = Vector3(0, 7.5, d * 0.7)
	n.add_child(key)
	key.look_at_from_position(key.position, Vector3(0, 0.6, -d * 0.1), Vector3.UP)
	for s in [-1.0, 1.0]:
		var o := OmniLight3D.new()
		o.light_color = Color(String(nc[0 if s < 0 else min(1, nc.size() - 1)]))
		o.light_energy = 2.6
		o.omni_range = maxf(w, d) * 0.9
		o.position = Vector3(s * w * 0.38, 2.6, -d * 0.5 + 1.2)
		n.add_child(o)
	var fill := OmniLight3D.new()
	fill.light_color = Color("c8b8ff")
	fill.light_energy = 0.8
	fill.omni_range = maxf(w, d) * 1.4
	fill.position = Vector3(0, 3.0, d * 0.6)
	n.add_child(fill)


## "dramatic": a tight pool of warm key light on the subject (front, high), a coloured rim light
## from behind that outlines heads and props, a second colour kicking from the side, dim washes on
## the back wall and a weak fill. Darker edges, the subject pops.
static func _lights_dramatic(n: Node3D, b: Dictionary, w: float, d: float) -> void:
	var nc: Array = b["neon_colors"]
	var key := SpotLight3D.new()
	key.name = "key"
	key.light_color = Color(String(b["light"]))
	key.light_energy = 5.5
	key.spot_range = 20.0
	key.spot_angle = 30.0
	key.spot_angle_attenuation = 1.8
	key.spot_attenuation = 0.4
	key.shadow_enabled = true
	key.position = Vector3(0.0, 7.0, d * 0.55)
	n.add_child(key)
	key.look_at_from_position(key.position, Vector3(0, 0.9, 0.0), Vector3.UP)
	var rim := SpotLight3D.new()
	rim.name = "rim"
	rim.light_color = Color(String(nc[0]))
	rim.light_energy = 6.0
	rim.spot_range = 16.0
	rim.spot_angle = 38.0
	rim.spot_angle_attenuation = 1.4
	rim.position = Vector3(0.0, 4.8, -d * 0.45)
	n.add_child(rim)
	rim.look_at_from_position(rim.position, Vector3(0, 1.1, 0.6), Vector3.UP)
	var kick := OmniLight3D.new()
	kick.name = "kick"
	kick.light_color = Color(String(nc[min(1, nc.size() - 1)]))
	kick.light_energy = 2.2
	kick.omni_range = 6.0
	kick.position = Vector3(w * 0.36, 2.2, 0.8)
	n.add_child(kick)
	for s in [-1.0, 1.0]:
		var o := OmniLight3D.new()
		o.light_color = Color(String(nc[0 if s < 0 else min(1, nc.size() - 1)]))
		o.light_energy = 1.3
		o.omni_range = maxf(w, d) * 0.7
		o.position = Vector3(s * w * 0.38, 3.2, -d * 0.5 + 1.0)
		n.add_child(o)
	var fill := OmniLight3D.new()
	fill.light_color = Color("b8b0ff")
	fill.light_energy = 0.3
	fill.omni_range = maxf(w, d) * 1.4
	fill.position = Vector3(0, 3.0, d * 0.7)
	n.add_child(fill)


## An Indian market street behind the bay: a row of narrow painted buildings,
## lit shop fronts with signboards (English + Hindi), striped awnings, balconies,
## AC units, rooftop water tanks, tangled overhead wires with fairy lights, tube
## lights on poles and a couple of parked autos. Deterministic per bay.
const SHOP_SIGNS := ["MOBILE RECHARGE", "CHAI", "KIRANA STORE", "SHARMA ELECTRONICS", "STD ISD PCO",
	"SWEETS", "GUPTA MEDICAL", "PAN SHOP", "CYBER CAFE", "TAILOR", "मिठाई", "चाय", "AGARWAL TRADERS", "XEROX"]
const SIGN_COLORS := ["#d6453d", "#f2c230", "#2f6fd6", "#2f9e44", "#e8742a", "#8a3fd6", "#ffffff"]
const FACADE_COLORS := ["#e8a0b4", "#f0c86a", "#5fbfb0", "#e88a50", "#7aa0d8", "#c8d870", "#d8b8e8", "#f2e6c8"]
const AWNING_COLORS := [["#d6453d", "#f4f1e4"], ["#2f6fd6", "#f4f1e4"], ["#2f9e44", "#f2c230"], ["#e8742a", "#f4f1e4"]]


static func _bazaar(n: Node3D, b: Dictionary, seed_value: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash("%d/bazaar/%s" % [seed_value, b["id"]])
	var w := float(b["size"][0])
	var d := float(b["size"][1])
	var g := Node3D.new()
	g.name = "bazaar"
	n.add_child(g)
	var z0 := -d * 0.5          # building fronts
	var x := -w * 0.5 - 6.0
	var poles := []
	var signs := SHOP_SIGNS.duplicate()
	while x < w * 0.5 + 6.0:
		var bw := r.randf_range(2.6, 3.6)
		var floors := r.randi_range(2, 3)
		var fh := 2.7
		var col := Color(FACADE_COLORS[r.randi_range(0, FACADE_COLORS.size() - 1)])
		var cx := x + bw * 0.5
		var h := fh * floors
		# Building body (set back a little from the shop front).
		g.add_child(_boxm(Vector3(bw - 0.04, h, 3.0), Vector3(cx, h * 0.5, z0 - 1.5), Toon.material(col, Toon.OUTLINE * 0.5)))
		# Shop at street level: a lit recess, a shutter half up, a counter.
		var ow := bw - 0.6
		g.add_child(_boxm(Vector3(ow, 2.1, 0.08), Vector3(cx, 1.05, z0 + 0.01), neon_material(Color("ffd9a0"), 0.55)))
		g.add_child(_boxm(Vector3(ow + 0.04, 0.5, 0.12), Vector3(cx, 2.05, z0 + 0.05), Toon.material(Color("8a8f98"), Toon.OUTLINE * 0.4)))
		g.add_child(_boxm(Vector3(ow, 0.75, 0.4), Vector3(cx, 0.375, z0 + 0.22), Toon.material(col.darkened(0.35), Toon.OUTLINE * 0.4)))
		for k in r.randi_range(2, 4):
			var item_col := Color(SIGN_COLORS[r.randi_range(0, SIGN_COLORS.size() - 1)])
			g.add_child(_boxm(Vector3(0.22, r.randf_range(0.18, 0.35), 0.18),
				Vector3(cx - ow * 0.35 + k * 0.32, 0.86, z0 + 0.22), Toon.material(item_col, Toon.OUTLINE * 0.3)))
		# Signboard with the shop's name.
		var sc := Color(SIGN_COLORS[r.randi_range(0, SIGN_COLORS.size() - 1)])
		g.add_child(_boxm(Vector3(bw - 0.3, 0.6, 0.1), Vector3(cx, 2.65, z0 + 0.08), Toon.material(sc, Toon.OUTLINE * 0.5)))
		var label := String(signs.pop_at(r.randi_range(0, signs.size() - 1)) if not signs.is_empty() else "STORE")
		var txt_col := Color("1b1b22") if sc.get_luminance() > 0.55 else Color("fff6e0")
		var t := Reveals.text_node(label, minf(0.34, (bw - 0.5) / maxf(1.0, label.length() * 0.52)), txt_col)
		t.position = Vector3(cx, 2.65 - 0.12, z0 + 0.14)
		g.add_child(t)
		# Striped awning over the signboard, sloping out.
		var ac: Array = AWNING_COLORS[r.randi_range(0, AWNING_COLORS.size() - 1)]
		var stripes := int(bw / 0.35)
		for k in stripes:
			var sw := bw / stripes
			var aw := _boxm(Vector3(sw, 0.04, 0.9), Vector3(x + sw * (k + 0.5), 3.2, z0 + 0.42),
				Toon.material(Color(String(ac[k % 2])), 0.0))
			aw.rotation_degrees = Vector3(-18, 0, 0)
			g.add_child(aw)
		# Upper floors: windows (some lit), a balcony, an AC unit.
		for f in range(1, floors):
			var y := f * fh + 1.25
			for k in 2:
				var wx := cx + (k - 0.5) * bw * 0.45
				var lit := r.randf() < 0.45
				var wm := neon_material(Color("ffd27a"), 1.4) if lit else Toon.material(Color("2a2440"), 0.0)
				g.add_child(_boxm(Vector3(0.62, 0.95, 0.06), Vector3(wx, y, z0 + 0.01 - 1.5 + 1.5), wm))
				g.add_child(_boxm(Vector3(0.74, 0.08, 0.14), Vector3(wx, y - 0.52, z0 + 0.05), Toon.material(col.darkened(0.25), 0.0)))
			if r.randf() < 0.55:
				g.add_child(_boxm(Vector3(bw * 0.8, 0.07, 0.6), Vector3(cx, f * fh + 0.1, z0 + 0.3), Toon.material(col.darkened(0.3), Toon.OUTLINE * 0.4)))
				for k in int(bw * 0.8 / 0.18):
					g.add_child(_boxm(Vector3(0.025, 0.7, 0.025), Vector3(cx - bw * 0.4 + 0.09 + k * 0.18, f * fh + 0.45, z0 + 0.58), Toon.material(Color("2b2b30"), 0.0)))
				g.add_child(_boxm(Vector3(bw * 0.8, 0.04, 0.04), Vector3(cx, f * fh + 0.8, z0 + 0.58), Toon.material(Color("2b2b30"), 0.0)))
			if r.randf() < 0.6:
				g.add_child(_boxm(Vector3(0.7, 0.42, 0.3), Vector3(cx + bw * 0.3, f * fh + 2.25, z0 + 0.16), Toon.material(Color("eef0f2"), Toon.OUTLINE * 0.4)))
		# Rooftop: a black water tank (and sometimes a dish).
		if r.randf() < 0.75:
			var tank := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.45
			cm.bottom_radius = 0.5
			cm.height = 0.9
			tank.mesh = cm
			tank.material_override = Toon.material(Color("1d1d22"), Toon.OUTLINE * 0.5)
			tank.position = Vector3(cx + r.randf_range(-0.5, 0.5), h + 0.45, z0 - 1.2)
			g.add_child(tank)
		poles.append(Vector3(x + bw, 0, z0 + 0.9))
		x += bw
	# Utility poles with tube lights, and wires sagging between them.
	var wire := Toon.material(Color("141418"), 0.0)
	var prev := Vector3.INF
	for i in range(0, poles.size(), 2):
		var p: Vector3 = poles[i]
		g.add_child(_boxm(Vector3(0.12, 6.4, 0.12), p + Vector3(0, 3.2, 0), Toon.material(Color("6b6f78"), Toon.OUTLINE * 0.5)))
		g.add_child(_boxm(Vector3(0.9, 0.07, 0.07), p + Vector3(0, 5.2, 0.3), neon_material(Color("eaf6ff"), 3.0)))
		if prev != Vector3.INF:
			for k in 3:
				var hk := 6.0 + k * 0.18
				_sag(g, prev + Vector3(0, hk, 0), p + Vector3(0, hk, 0), 0.45 + 0.15 * k, 0.012, wire, null)
			_sag(g, prev + Vector3(0, 5.6, 0.1), p + Vector3(0, 5.6, 0.1), 0.6, 0.008, wire, r)
		prev = p
	# Parked autos along the shop line.
	for k in 2:
		var ax := r.randf_range(-w * 0.45, w * 0.45)
		var auto := Reveals.shape_node("rickshaw", 1.7, Color("2f9e44"))
		auto.position = Vector3(ax, 0, z0 + 1.6)
		auto.rotation_degrees = Vector3(0, 90.0 if k == 0 else -90.0, 0)
		g.add_child(auto)


## A sagging wire between two points; with an rng, also a string of fairy lights.
static func _sag(g: Node3D, a: Vector3, b: Vector3, sag: float, r: float, mat: Material, lights) -> void:
	var n := 12
	var prev := a
	var cols := [Color("ffd27a"), Color("ff6a9a"), Color("5fe3ff"), Color("7cff6b")]
	for i in range(1, n + 1):
		var u := float(i) / n
		var p := a.lerp(b, u) - Vector3(0, sag * 4.0 * u * (1.0 - u), 0)
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = r
		cm.bottom_radius = r
		cm.height = prev.distance_to(p)
		cm.radial_segments = 4
		cm.rings = 1
		mi.mesh = cm
		mi.material_override = mat
		var y := (p - prev).normalized()
		var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
		var xx := ref.cross(y).normalized()
		mi.transform = Transform3D(Basis(xx, y, xx.cross(y)), (p + prev) * 0.5)
		g.add_child(mi)
		if lights != null:
			var bulb := MeshInstance3D.new()
			bulb.mesh = Toon.sphere(0.045)
			bulb.material_override = neon_material(cols[i % cols.size()], 4.0)
			bulb.position = p - Vector3(0, 0.05, 0)
			g.add_child(bulb)
		prev = p


static func _boxm(s: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = s
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = mat
	mi.position = at
	return mi


## An Indian haveli room: warm plaster walls with a painted dado and border,
## carved arched windows glowing with the night outside, pillars at the
## corners, a marigold toran across the top and hanging brass lanterns.
const HAVELI_ACCENTS := ["#b8322a", "#1f6f6a", "#d9a632", "#7a2a6e"]


static func _haveli(n: Node3D, b: Dictionary, seed_value: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash("%d/haveli/%s" % [seed_value, b["id"]])
	var w := float(b["size"][0])
	var d := float(b["size"][1])
	var wall := Color(String(b["wall_color"]))
	var accent := Color(HAVELI_ACCENTS[r.randi_range(0, HAVELI_ACCENTS.size() - 1)])
	var g := Node3D.new()
	g.name = "haveli"
	n.add_child(g)
	var z := -d * 0.5
	var walls := [[Vector3(0, 0, z), 0.0, w + 2.0]]
	if bool(b["sides"]):
		walls.append([Vector3(-w * 0.5, 0, 0), 90.0, d + 2.0])
		walls.append([Vector3(w * 0.5, 0, 0), -90.0, d + 2.0])
	for wd in walls:
		var holder := Node3D.new()
		holder.position = wd[0]
		holder.rotation_degrees = Vector3(0, wd[1], 0)
		g.add_child(holder)
		var ww: float = wd[2]
		holder.add_child(_boxm(Vector3(ww, Gen.WALL_H, 0.2), Vector3(0, Gen.WALL_H * 0.5, -0.1), Toon.material(wall, 0.0)))
		# Dado (lower band), a painted border line and a top frieze.
		holder.add_child(_boxm(Vector3(ww, 1.0, 0.04), Vector3(0, 0.5, 0.02), Toon.material(wall.darkened(0.25), 0.0)))
		holder.add_child(_boxm(Vector3(ww, 0.08, 0.05), Vector3(0, 1.02, 0.03), Toon.material(accent, 0.0)))
		holder.add_child(_boxm(Vector3(ww, 0.35, 0.06), Vector3(0, Gen.WALL_H - 0.6, 0.03), Toon.material(accent.darkened(0.15), 0.0)))
		for k in int(ww / 0.5):
			var dot := MeshInstance3D.new()
			dot.mesh = Toon.sphere(0.06)
			dot.material_override = Toon.material(Color("f2d27a"), 0.0)
			dot.position = Vector3(-ww * 0.5 + 0.25 + k * 0.5, Gen.WALL_H - 0.6, 0.08)
			holder.add_child(dot)
	# Arched windows on the back wall (night sky beyond), with carved frames.
	var nwin := 3 if w >= 8.0 else 2
	for k in nwin:
		var x := (float(k) - (nwin - 1) * 0.5) * (w / nwin) * 0.95
		_arch_window(g, Vector3(x, 1.35, z + 0.01), 1.0, 2.1, accent)
	# Pillars at the back corners.
	for s in [-1.0, 1.0]:
		var px: float = s * (w * 0.5 - 0.35)
		g.add_child(_cylm(0.17, Gen.WALL_H, Vector3(px, Gen.WALL_H * 0.5, z + 0.35), Toon.material(wall.lightened(0.25), Toon.OUTLINE * 0.6)))
		g.add_child(_boxm(Vector3(0.5, 0.25, 0.5), Vector3(px, 0.125, z + 0.35), Toon.material(accent, Toon.OUTLINE * 0.5)))
		g.add_child(_boxm(Vector3(0.5, 0.22, 0.5), Vector3(px, Gen.WALL_H - 0.95, z + 0.35), Toon.material(accent, Toon.OUTLINE * 0.5)))
	# Marigold toran: festoons across the top of the back wall.
	var fest := 4
	for k in fest:
		var x0 := -w * 0.45 + k * (w * 0.9 / fest)
		var x1 := x0 + w * 0.9 / fest
		var steps := 12
		for i in steps + 1:
			var u := float(i) / steps
			var c := Color("ff8c1a") if i % 2 == 0 else Color("ffc21a")
			var bead := MeshInstance3D.new()
			bead.mesh = Toon.sphere(0.06)
			bead.material_override = Toon.material(c, 0.0)
			bead.position = Vector3(lerpf(x0, x1, u), Gen.WALL_H - 1.0 - 0.35 * 4.0 * u * (1.0 - u), z + 0.15)
			g.add_child(bead)
		var leaf := _boxm(Vector3(0.1, 0.22, 0.03), Vector3(x1, Gen.WALL_H - 1.15, z + 0.15), Toon.material(Color("3f9e3a"), 0.0))
		g.add_child(leaf)
	# Hanging brass lanterns (small warm lights).
	for s in [-1.0, 1.0]:
		var lx: float = s * w * 0.3
		g.add_child(_boxm(Vector3(0.02, 1.2, 0.02), Vector3(lx, Gen.WALL_H - 0.6, z + 1.2), Toon.material(Color("6b5a2a"), 0.0)))
		g.add_child(_cylm(0.16, 0.34, Vector3(lx, Gen.WALL_H - 1.35, z + 1.2), Toon.material(Color("d9a632"), Toon.OUTLINE * 0.5)))
		var glow := MeshInstance3D.new()
		glow.mesh = Toon.sphere(0.1)
		glow.material_override = neon_material(Color("ffb84a"), 3.5)
		glow.position = Vector3(lx, Gen.WALL_H - 1.55, z + 1.2)
		g.add_child(glow)
		var lamp := OmniLight3D.new()
		lamp.light_color = Color("ffb06a")
		lamp.light_energy = 1.6
		lamp.omni_range = 5.0
		lamp.position = glow.position
		g.add_child(lamp)


## A glowing arched window (rectangle + half circle) with a carved frame.
static func _arch_window(g: Node3D, base: Vector3, w: float, h: float, accent: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rr := w * 0.5
	var body := h - rr
	var pts := [Vector3(-rr, 0, 0), Vector3(rr, 0, 0), Vector3(rr, body, 0)]
	for i in range(1, 16):
		var a := PI * float(i) / 16.0
		pts.append(Vector3(rr * cos(a), body + rr * sin(a), 0))
	pts.append(Vector3(-rr, body, 0))
	var c := Vector3(0, body * 0.5, 0)
	for i in pts.size():
		st.add_vertex(c)
		st.add_vertex(pts[(i + 1) % pts.size()])
		st.add_vertex(pts[i])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = neon_material(Color("5a46b8"), 1.1)
	mi.position = base
	g.add_child(mi)
	var frame := Toon.material(accent.lightened(0.2), 0.0)
	for i in pts.size():
		g.add_child(_tube(base + pts[i] + Vector3(0, 0, 0.04), base + pts[(i + 1) % pts.size()] + Vector3(0, 0, 0.04), 0.05, frame))
	# Jaali bars and a sill.
	for k in 3:
		var x := (float(k) - 1.0) * w * 0.28
		g.add_child(_boxm(Vector3(0.03, body + rr * 0.8, 0.03), base + Vector3(x, (body + rr * 0.8) * 0.5, 0.05), Toon.material(Color("2a1d3a"), 0.0)))
	g.add_child(_boxm(Vector3(w + 0.3, 0.1, 0.25), base + Vector3(0, -0.05, 0.1), Toon.material(accent.darkened(0.2), Toon.OUTLINE * 0.4)))


static func _cylm(r: float, h: float, at: Vector3, mat: Material) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 20
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = mat
	mi.position = at
	return mi


## Distant night skyline: blocks with lit window bands, behind an open bay.
static func _skyline(n: Node3D, b: Dictionary, seed_value: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash("%d/skyline/%s" % [seed_value, b["id"]])
	var d := float(b["size"][1])
	var g := Node3D.new()
	g.name = "skyline"
	n.add_child(g)
	var body := StandardMaterial3D.new()
	body.albedo_color = Color("1a1440")
	body.roughness = 0.8
	var nc: Array = b["neon_colors"]
	var window_cols := [Color("ffd27a"), Color(String(nc[0])), Color(String(nc[min(1, nc.size() - 1)])), Color("ff9ad5")]
	for row in 2:
		var z := -d * 0.5 - 14.0 - row * 16.0
		var x := -46.0
		while x < 46.0:
			var bw := r.randf_range(3.0, 7.0)
			var bh := r.randf_range(8.0, 26.0) + row * 8.0
			var bm := BoxMesh.new()
			bm.size = Vector3(bw, bh, 4.0)
			var mi := MeshInstance3D.new()
			mi.mesh = bm
			mi.material_override = body
			mi.position = Vector3(x + bw * 0.5, bh * 0.5, z)
			g.add_child(mi)
			# Window bands: thin emissive strips on the front face.
			var wc: Color = window_cols[r.randi_range(0, window_cols.size() - 1)]
			var bands := int(bh / 2.2)
			for k in bands:
				if r.randf() < 0.35:
					continue
				var sm := BoxMesh.new()
				sm.size = Vector3(bw * r.randf_range(0.5, 0.85), 0.28, 0.05)
				var s := MeshInstance3D.new()
				s.mesh = sm
				s.material_override = neon_material(wc, 2.2)
				s.position = Vector3(x + bw * 0.5, 1.4 + k * 2.2, z + 2.03)
				g.add_child(s)
			x += bw + r.randf_range(0.3, 2.0)


static func _pedestal(n: Node3D, p: Dictionary, nc: Array, seed_value: int, bay_id: String) -> void:
	var g := Node3D.new()
	g.name = "pedestal"
	n.add_child(g)
	var h := float(p["height"])
	var rad := float(p["radius"])
	match String(p["style"]):
		"neon", "plain":
			var cm := CylinderMesh.new()
			cm.top_radius = rad
			cm.bottom_radius = rad * 1.04
			cm.height = h
			cm.radial_segments = 48
			var mi := MeshInstance3D.new()
			mi.mesh = cm
			mi.material_override = Toon.material(Color(String(p["color"])), Toon.OUTLINE)
			mi.position = Vector3(0, h * 0.5, 0)
			g.add_child(mi)
			if String(p["style"]) == "neon":
				for y in [h - 0.02, 0.04]:
					var tm := TorusMesh.new()
					tm.inner_radius = rad * 0.97
					tm.outer_radius = rad * 1.03
					tm.rings = 64
					var ring := MeshInstance3D.new()
					ring.mesh = tm
					ring.material_override = neon_material(Color(String(nc[0])), 5.0)
					ring.position = Vector3(0, y, 0)
					g.add_child(ring)
		"drums", "cash", "crates":
			# A pile: layers of items, each layer a smaller disc; the top is flat at h.
			var r := RandomNumberGenerator.new()
			r.seed = hash("%d/pedestal/%s" % [seed_value, bay_id])
			var style := String(p["style"])
			var item_h := 0.9 if style == "drums" else (0.3 if style == "cash" else 0.6)
			var layers := maxi(1, int(round(h / item_h)))
			var step := 0.62 if style == "drums" else (0.55 if style == "cash" else 0.62)
			for layer in layers:
				var lr := rad * (1.0 - 0.28 * float(layer) / maxf(1.0, float(layers - 1)) if layers > 1 else 1.0)
				var y0 := float(layer) * (h / layers)
				var gx := -lr
				while gx <= lr + 0.001:
					var gz := -lr
					while gz <= lr + 0.001:
						if Vector2(gx, gz).length() <= lr + 0.05:
							g.add_child(_pile_item(style, Vector3(gx, y0, gz), h / layers, r))
						gz += step
					gx += step


static func _pile_item(style: String, at: Vector3, h: float, r: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	n.position = at
	n.rotation_degrees = Vector3(0, r.randf_range(-25, 25), 0)
	match style:
		"drums":
			var col := Color(DRUM_COLORS[r.randi_range(0, DRUM_COLORS.size() - 1)])
			var cm := CylinderMesh.new()
			cm.top_radius = 0.3
			cm.bottom_radius = 0.3
			cm.height = h
			cm.radial_segments = 20
			var mi := MeshInstance3D.new()
			mi.mesh = cm
			mi.material_override = Toon.material(col, Toon.OUTLINE * 0.7)
			mi.position = Vector3(0, h * 0.5, 0)
			n.add_child(mi)
			for y in [h * 0.3, h * 0.7]:
				var tm := TorusMesh.new()
				tm.inner_radius = 0.29
				tm.outer_radius = 0.325
				tm.rings = 24
				var ring := MeshInstance3D.new()
				ring.mesh = tm
				ring.material_override = Toon.material(col.darkened(0.3), 0.0)
				ring.position = Vector3(0, y, 0)
				n.add_child(ring)
		"cash":
			var bm := BoxMesh.new()
			bm.size = Vector3(0.5, h, 0.26)
			var mi := MeshInstance3D.new()
			mi.mesh = bm
			mi.material_override = Toon.material(Color("4fbf6a"), Toon.OUTLINE * 0.6)
			mi.position = Vector3(0, h * 0.5, 0)
			n.add_child(mi)
			var band := MeshInstance3D.new()
			var bb := BoxMesh.new()
			bb.size = Vector3(0.09, h + 0.01, 0.27)
			band.mesh = bb
			band.material_override = Toon.material(Color("f4f1e4"), 0.0)
			band.position = mi.position
			n.add_child(band)
		"crates":
			var bm := BoxMesh.new()
			bm.size = Vector3(0.58, h, 0.58)
			var mi := MeshInstance3D.new()
			mi.mesh = bm
			mi.material_override = Toon.material(Color("b07a45"), Toon.OUTLINE * 0.7)
			mi.position = Vector3(0, h * 0.5, 0)
			n.add_child(mi)
	return n
