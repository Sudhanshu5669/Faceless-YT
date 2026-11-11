## Builds stage bays (stage_generator.gd): floors, walls, neon, lights,
## skylines and pedestals, in the toon style (outlined props, emissive neon).
extends RefCounted

const Gen = preload("res://scripts/world/generators/stage_generator.gd")
const Toon = preload("res://scripts/actors/toon.gd")
const SURFACE := preload("res://shaders/stage_surface.gdshader")

const FLOOR_PATTERNS := {"checker": 0, "tiles": 1, "grid": 2, "wood": 3, "plain": 4, "carpet": 5}
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
	var outdoor := String(b["wall"]) == "skyline"
	# Floor (slightly bigger than the bay so wide shots never see its edge).
	var fw := w + (30.0 if outdoor else 2.0)
	var fd := d + (30.0 if outdoor else 2.0)
	var floor := _plane(Vector2(fw, fd), _surface(FLOOR_PATTERNS[String(b["floor"])], Color(String(fc[0])),
		Color(String(fc[1])), Color(String(nc[0])), 1.0 if String(b["floor"]) != "wood" else 0.25, false))
	floor.name = "floor"
	floor.position = Vector3(0, 0, (fd - d) * -0.5 + (fd - d) * 0.5)
	n.add_child(floor)
	# Back wall (and sides) or an open skyline.
	var wall_kind := String(b["wall"])
	if wall_kind == "skyline":
		_skyline(n, b, seed_value)
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
