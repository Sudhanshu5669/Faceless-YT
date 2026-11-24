## Empire State University, a physics lab at night, early 1960s: plaster walls, worn concrete, tall windows of
## moonlight, steel desks and shelves of apparatus (Poly Haven props), a standing chalkboard of equations, and Victor's
## machine: a tall copper-wound ring on a steel dais (a portal to the realm of the dead), two Tesla pylons, a rack of
## glowing vacuum tubes and the control console with a knife-switch lever.
##
## Local frame: the ring's centre at (0, 2.1, -4.6) facing +z; the console at (1.5, 0, -1.9) facing -z (the operator
## stands at about (1.5, 0, -1.2) facing the machine); the chalkboard at (-3.3, 0, -2.2); cameras at +z looking -z.
##
## params:
##   power     t   the machine wakes: tubes brighten, the rings start to turn, the portal clouds over green
##   warn      t   a chalk circle is drawn round the flaw on the board (0.5 s), then underlined
##   chalk     {"actor": id}   that actor's right hand writes the circle (aim_hand) on `warn`
##   lever     {"actor": id, "t": t}   the actor's hand reaches for the knife switch and throws it on t
##   overload  t   arcs go wild, the ring spins up, sparks rain
##   blast     t   the console explodes in the operator's face: a white flash, a fireball, sparks, debris, smoke
## anchors: ring, console, board, flaw, lever, blast
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Toon = preload("res://scripts/actors/toon.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")

const PH := "incoming/polyhaven_doom/"
const PH0 := "incoming/polyhaven_pokhran/models/"
const RING := Vector3(0, 2.1, -4.6)
const CONSOLE := Vector3(1.5, 0, -1.9)
const LEVER := Vector3(1.85, 1.12, -1.78)

const PORTAL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform float power = 0.0;
uniform float time = 0.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y); }
void fragment() {
	vec2 c = UV - 0.5;
	float r = length(c) * 2.0;
	float a = atan(c.y, c.x);
	float sw = a + time * 0.9 + 3.0 / (r + 0.35);
	float f = n(vec2(cos(sw), sin(sw)) * 3.0 * r + time * 0.6) * 0.6 + n(vec2(sw * 2.0, r * 6.0 - time * 1.4)) * 0.4;
	float edge = 1.0 - smoothstep(0.55, 1.0, r);
	vec3 col = mix(vec3(0.05, 0.5, 0.18), vec3(0.65, 1.0, 0.55), f) * (0.25 + 1.6 * f * f);
	col += vec3(0.6, 1.0, 0.7) * pow(max(1.0 - r, 0.0), 6.0) * 2.0;
	ALBEDO = col * edge * power * 0.6;
}
"""

const FIRE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform float heat = 1.0;     // 1 white-hot .. 0 dark smoke
uniform float alpha = 1.0;
uniform float seed = 0.0;
varying vec3 lp;
void vertex() { lp = VERTEX; }
float h3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float n3(vec3 p) { vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1,0,0)), f.x), mix(h3(i + vec3(0,1,0)), h3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h3(i + vec3(0,0,1)), h3(i + vec3(1,0,1)), f.x), mix(h3(i + vec3(0,1,1)), h3(i + vec3(1,1,1)), f.x), f.y), f.z); }
void fragment() {
	float rim = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float b = n3(lp * 3.0 + seed) * 0.6 + n3(lp * 7.0 - seed) * 0.4;
	float body = smoothstep(0.25, 0.75, rim * (0.55 + 0.7 * b));
	vec3 hot = mix(vec3(0.55, 0.12, 0.02), vec3(1.0, 0.78, 0.4), clamp(heat * (0.6 + 0.8 * b), 0.0, 1.0));
	ALBEDO = hot * body * alpha * (0.25 + 1.4 * heat);
}
"""

var _p := {}
var _rings: Array[Node3D] = []
var _portal_mat: ShaderMaterial
var _portal_light: OmniLight3D
var _tube_mat: StandardMaterial3D
var _arcs: MeshInstance3D
var _arc_mat: StandardMaterial3D
var _emit: Array[Vector3] = []
var _lever: Node3D
var _circle: MeshInstance3D
var _underline: MeshInstance3D
var _chalk_mat: StandardMaterial3D
var _board_xf := Transform3D.IDENTITY
var _flaw := Vector3.ZERO
var _fire: Array[MeshInstance3D] = []
var _fire_mats: Array[ShaderMaterial] = []
var _flash: OmniLight3D
var _spark_mm: MultiMesh
var _debris: Array[MeshInstance3D] = []
var _hang: Array[OmniLight3D] = []


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "lab"))
	_room(root)
	_props(root)
	_machine(root)
	_board(root)
	_blast_build(root)
	return root


func _room(root: Node3D) -> void:
	var floor_m := Kit.textured(PH + "textures/concrete_floor_worn_001_diff_2k.jpg", PH + "textures/concrete_floor_worn_001_nor_gl_2k.jpg",
		PH + "textures/concrete_floor_worn_001_rough_2k.jpg", Vector3(6, 6, 1), Color("#b8b2a6"))
	var wall_m := Kit.textured(PH + "textures/painted_plaster_wall_diff_2k.jpg", PH + "textures/painted_plaster_wall_nor_gl_2k.jpg",
		PH + "textures/painted_plaster_wall_rough_2k.jpg", Vector3(4, 2, 1), Color("#9fb3a2"))
	var dado := Kit.mat("#3f5546", 0.6)
	Kit.box(root, Vector3(16, 0.1, 15), Vector3(0, -0.05, -1.5), floor_m)
	Kit.box(root, Vector3(16, 4.6, 0.3), Vector3(0, 2.3, -8.2), wall_m)
	Kit.box(root, Vector3(16, 1.1, 0.32), Vector3(0, 0.55, -8.18), dado)
	Kit.box(root, Vector3(16, 0.2, 15), Vector3(0, 4.7, -1.5), Kit.mat("#2a2d2c", 0.9))
	for s: float in [-1.0, 1.0]:
		var x := s * 7.6
		# Side walls with tall windows (night: deep blue panes, mullions).
		for k in 4:
			var z := -6.6 + k * 3.0
			Kit.box(root, Vector3(0.3, 4.6, 1.2), Vector3(x, 2.3, z - 0.9), wall_m)
			Kit.box(root, Vector3(0.3, 1.1, 1.85), Vector3(x, 0.55, z + 0.62), dado)
			Kit.box(root, Vector3(0.3, 0.9, 1.85), Vector3(x, 4.25, z + 0.62), wall_m)
			var pane := Kit.box(root, Vector3(0.05, 2.7, 1.8), Vector3(x + s * 0.05, 2.45, z + 0.62), Kit.lit("#1a2c55", 0.35))
			pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for m in 3:
				Kit.box(root, Vector3(0.08, 2.7, 0.05), Vector3(x - s * 0.02, 2.45, z - 0.25 + m * 0.6), Kit.mat("#2b2f2c", 0.6))
			Kit.box(root, Vector3(0.08, 0.05, 1.8), Vector3(x - s * 0.02, 2.9, z + 0.62), Kit.mat("#2b2f2c", 0.6))
	# Moonlight through the left windows, raking across the floor.
	Kit.spot(root, Vector3(-11.5, 6.5, -2.0), Vector3(0.5, 0.0, -2.5), "#7d9cff", 24.0, 22.0, 32.0, true, 2.2)
	# Two caged lamps over the benches, warm and low.
	for x: float in [-4.6, 4.6]:
		var lamp := Kit.model(PH + "models/caged_hanging_light/caged_hanging_light_2k.gltf")
		lamp.position = Vector3(x, 3.6, -4.2)
		root.add_child(lamp)
		Kit.rod(root, Vector3(x, 3.95, -4.2), Vector3(x, 4.6, -4.2), 0.01, Kit.mat("#111111", 0.5), 4)
		_hang.append(Kit.omni(root, Vector3(x, 3.45, -4.2), "#ffb46a", 4.5, 7.5, true, 0.6))


func _place(root: Node3D, rel: String, pos: Vector3, yaw: float = 0.0, scale: float = 1.0) -> Node3D:
	var n := Kit.model(rel)
	n.position = pos
	n.rotation = Vector3(0, yaw, 0)
	n.scale = Vector3.ONE * scale
	root.add_child(n)
	return n


func _props(root: Node3D) -> void:
	var M := PH + "models/"
	# Left bench: chemistry, a microscope, a notebook.
	_place(root, PH0 + "metal_office_desk/metal_office_desk_2k.gltf", Vector3(-5.6, 0, -5.4), 0.0)
	_place(root, M + "chemistry_set/chemistry_set_2k.gltf", Vector3(-6.0, 0.76, -5.5), 0.3)
	_place(root, M + "vintage_microscope/vintage_microscope_2k.gltf", Vector3(-5.0, 0.76, -5.3), -0.5)
	_place(root, M + "bunsen_burner/bunsen_burner_2k.gltf", Vector3(-5.5, 0.76, -5.0), 0.0)
	_place(root, M + "binder_notebook/binder_notebook_2k.gltf", Vector3(-5.2, 0.77, -4.95), 0.4)
	_place(root, M + "metal_stool_01/metal_stool_01_2k.gltf", Vector3(-5.2, 0, -4.4), 0.7)
	# Right bench: radio set, multimeter, the spacecraft instrument (a dial-faced box).
	_place(root, PH0 + "metal_office_desk/metal_office_desk_2k.gltf", Vector3(5.6, 0, -5.4), PI)
	_place(root, PH0 + "vintage_radio_transceiver/vintage_radio_transceiver_2k.gltf", Vector3(5.9, 0.76, -5.5), PI + 0.2)
	_place(root, M + "retro_multimeter/retro_multimeter_2k.gltf", Vector3(5.1, 0.76, -5.2), PI - 0.3)
	_place(root, M + "vintage_spacecraft_instrument/vintage_spacecraft_instrument_2k.gltf", Vector3(5.5, 0.76, -5.0), PI)
	_place(root, M + "metal_stool_01/metal_stool_01_2k.gltf", Vector3(4.9, 0, -4.3), 2.2)
	# Shelves on the back wall, the compressor and the power box by the machine.
	_place(root, PH0 + "steel_frame_shelves_01/steel_frame_shelves_01_2k.gltf", Vector3(-4.2, 0, -7.7), 0.0)
	_place(root, PH0 + "steel_frame_shelves_01/steel_frame_shelves_01_2k.gltf", Vector3(4.2, 0, -7.7), 0.0)
	_place(root, M + "old_military_compressor/old_military_compressor_2k.gltf", Vector3(3.3, 0, -6.6), -0.6)
	_place(root, M + "power_box_01/power_box_01_2k.gltf", Vector3(2.3, 1.3, -8.02), 0.0)
	_place(root, M + "modular_electric_cables/modular_electric_cables_2k.gltf", Vector3(1.4, 0.0, -5.6), 0.4)


func _machine(root: Node3D) -> void:
	var copper := Kit.mat("#b0612e", 0.32, 0.9)
	var steel := Kit.mat("#4d5358", 0.42, 0.85)
	var dark := Kit.mat("#1a1c1e", 0.6, 0.5)
	var rivet := Kit.textured(PH + "textures/metal_plate_02_diff_2k.jpg", PH + "textures/metal_plate_02_nor_gl_2k.jpg",
		PH + "textures/metal_plate_02_rough_2k.jpg", Vector3(2, 2, 1), Color("#8a8f94"))
	# The dais: two steps of riveted plate.
	Kit.box(root, Vector3(5.2, 0.25, 3.0), Vector3(0, 0.125, -4.6), rivet)
	Kit.box(root, Vector3(4.2, 0.25, 2.2), Vector3(0, 0.375, -4.7), rivet)
	# The ring: an outer steel torus, a copper-wound inner ring, clamps; two counter-rotating gimbal rings.
	var holder := Node3D.new()
	holder.position = RING
	root.add_child(holder)
	var outer := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.45
	tm.outer_radius = 1.75
	tm.rings = 64
	tm.ring_segments = 16
	outer.mesh = tm
	outer.material_override = steel
	outer.rotation = Vector3(PI / 2, 0, 0)
	holder.add_child(outer)
	for k in 36:
		var a := TAU * k / 36.0
		var coil := Kit.cyl(holder, 0.2, 0.2, 0.12, Vector3(cos(a), sin(a), 0) * 1.6, copper, 14)
		coil.rotation = Vector3(0, 0, a)
	for k in 8:
		var a := TAU * k / 8.0 + 0.2
		Kit.box(holder, Vector3(0.18, 0.42, 0.5), Vector3(cos(a), sin(a), 0) * 1.6, dark, Vector3(0, 0, a))
	for k in 2:
		var g := Node3D.new()
		holder.add_child(g)
		var gm := MeshInstance3D.new()
		var t2 := TorusMesh.new()
		t2.inner_radius = 1.12 - 0.18 * k
		t2.outer_radius = 1.2 - 0.18 * k
		t2.rings = 48
		t2.ring_segments = 8
		gm.mesh = t2
		gm.material_override = copper
		g.add_child(gm)
		_rings.append(g)
	# The portal disc.
	_portal_mat = Kit.shader(PORTAL_SHADER)
	var disc := Kit.quad(holder, Vector2(2.9, 2.9), Vector3.ZERO, _portal_mat)
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_portal_light = Kit.omni(root, RING + Vector3(0, 0, 0.9), "#55ff8a", 0.0, 9.0, true, 0.0)
	# Legs of the ring into the dais.
	for s: float in [-1.0, 1.0]:
		Kit.box(root, Vector3(0.35, 1.0, 0.5), Vector3(s * 1.05, 0.9, -4.6), steel, Vector3(0, 0, s * 0.35))
	# Tesla pylons with stacked coils and top spheres (the arc emitters).
	for s: float in [-1.0, 1.0]:
		var x := s * 2.6
		Kit.cyl(root, 0.32, 0.42, 0.5, Vector3(x, 0.75, -4.4), steel, 20)
		Kit.cyl(root, 0.14, 0.14, 2.2, Vector3(x, 2.1, -4.4), dark, 14)
		for k in 7:
			Kit.cyl(root, 0.3 - 0.02 * k, 0.3 - 0.02 * k, 0.07, Vector3(x, 1.3 + 0.26 * k, -4.4), copper, 20)
		Kit.ball(root, 0.36, Vector3(x, 3.45, -4.4), Kit.mat("#c9ced2", 0.25, 0.95), 24)
		_emit.append(Vector3(x, 3.45, -4.4))
	# The tube rack behind the console: rows of glass bottles with orange filaments.
	_tube_mat = Kit.lit("#ff8a3a", 0.3)
	var glass := Kit.mat("#c8d8d8", 0.08, 0.0, 0.9)
	glass = glass.duplicate()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.8, 0.9, 0.9, 0.25)
	Kit.box(root, Vector3(1.8, 1.2, 0.5), Vector3(2.9, 0.6, -2.9), steel)
	for r in 2:
		for k in 6:
			var tp := Vector3(2.25 + k * 0.26, 1.35 + r * 0.0, -2.95 + r * 0.2)
			Kit.cyl(root, 0.07, 0.07, 0.3, tp, glass, 12)
			Kit.cyl(root, 0.025, 0.025, 0.2, tp, _tube_mat, 8)
	# The console: a slanted desk of dials, a big knife switch.
	Kit.box(root, Vector3(1.4, 0.95, 0.7), CONSOLE + Vector3(0, 0.475, 0), steel)
	var panel := Kit.box(root, Vector3(1.4, 0.06, 0.75), CONSOLE + Vector3(0, 1.0, 0.05), dark, Vector3(-0.45, 0, 0))
	panel.name = "panel"
	for k in 5:
		Kit.cyl(root, 0.07, 0.07, 0.02, CONSOLE + Vector3(-0.5 + k * 0.2, 1.04, 0.02), Kit.lit("#fff1c8", 0.6), 16, Vector3(-0.45 + PI / 2, 0, 0))
	for k in 6:
		Kit.ball(root, 0.025, CONSOLE + Vector3(-0.5 + k * 0.17, 0.98, 0.2), Kit.lit("#ff3a2a" if k % 2 == 0 else "#46ff78", 1.5), 8)
	# The dial lamps throw a low warm light up onto the operator's face.
	Kit.omni(root, CONSOLE + Vector3(0, 1.2, 0.55), "#ffc98a", 2.2, 2.4, false, 0.2)
	# The knife switch: a base, two copper blades on a hinge, a black handle.
	Kit.box(root, Vector3(0.28, 0.05, 0.3), LEVER + Vector3(0, -0.04, 0), dark)
	_lever = Node3D.new()
	_lever.position = LEVER
	root.add_child(_lever)
	for s: float in [-1.0, 1.0]:
		Kit.box(_lever, Vector3(0.025, 0.32, 0.04), Vector3(s * 0.06, 0.16, 0), copper)
	Kit.cyl(_lever, 0.035, 0.035, 0.22, Vector3(0, 0.33, 0), Kit.mat("#0d0d0d", 0.4), 12, Vector3(0, 0, PI / 2))
	# Arcs (rebuilt each frame).
	_arc_mat = StandardMaterial3D.new()
	_arc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_arc_mat.albedo_color = Color(0.75, 1.0, 0.85)
	_arc_mat.emission_enabled = true
	_arc_mat.emission = Color(0.6, 1.0, 0.75)
	_arc_mat.emission_energy_multiplier = 6.0
	_arcs = MeshInstance3D.new()
	_arcs.mesh = ImmediateMesh.new()
	_arcs.material_override = _arc_mat
	_arcs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(_arcs)


func _board(root: Node3D) -> void:
	var bpos := Vector3(-3.3, 0, -2.2)
	var yaw := 0.35
	# A standing slate on an A-frame of oak: 1.9 x 1.15 m, centred 1.45 m up.
	var oak := Kit.mat("#6b4a2c", 0.6)
	var slate := Kit.mat("#24342c", 0.85)
	var holder := Node3D.new()
	holder.position = bpos
	holder.rotation = Vector3(0, yaw, 0)
	root.add_child(holder)
	Kit.box(holder, Vector3(1.9, 1.15, 0.03), Vector3(0, 1.45, 0), slate)
	for s2: float in [-1.0, 1.0]:
		Kit.box(holder, Vector3(0.06, 1.27, 0.06), Vector3(s2 * 0.98, 1.45, 0.0), oak)
		Kit.box(holder, Vector3(1.98, 0.06, 0.06), Vector3(0, 1.45 + s2 * 0.6, 0.0), oak)
		# Legs: front and back of the A-frame.
		Kit.box(holder, Vector3(0.06, 2.2, 0.06), Vector3(s2 * 1.05, 1.08, 0.12), oak, Vector3(-0.1, 0, 0))
		Kit.box(holder, Vector3(0.06, 2.2, 0.06), Vector3(s2 * 1.05, 1.08, -0.35), oak, Vector3(0.22, 0, 0))
	Kit.box(holder, Vector3(1.9, 0.05, 0.1), Vector3(0, 0.86, 0.06), oak)
	Kit.box(holder, Vector3(0.12, 0.03, 0.03), Vector3(0.5, 0.9, 0.08), Kit.mat("#f2f0e6", 0.9))
	var face_z := 0.02
	_board_xf = Transform3D(Basis.from_euler(Vector3(0, yaw, 0)), bpos + Vector3(0, 1.45, 0))
	var frame := Node3D.new()
	frame.transform = _board_xf
	root.add_child(frame)
	var chalk := Color("#e9ece6")
	var eqs := ["d²ψ/dx² + (8π²m/h²)(E − V)ψ = 0", "E = hν = 6.626 × 10⁻³⁴ ν", "Φ(r, t) = Σ cₙ ψₙ e^(−iEₙt/ħ)",
		"λ = h / p", "Δt · ΔE ≥ ħ / 2"]
	for i in eqs.size():
		var l := Kit.text(frame, eqs[i], 0.075, Color("#b9bdb6"), Vector3(-0.05, 0.4 - i * 0.17, face_z), Vector3.ZERO, false, 0.9,
			Color(0, 0, 0, 0), "body")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# The flaw: the exponent in the second line.
	_flaw = Vector3(0.36, 0.23, face_z + 0.005)
	_chalk_mat = StandardMaterial3D.new()
	_chalk_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_chalk_mat.albedo_color = Color("#f4f2e8")
	_circle = MeshInstance3D.new()
	_circle.mesh = ImmediateMesh.new()
	_circle.material_override = _chalk_mat
	frame.add_child(_circle)


func _blast_build(root: Node3D) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 20
	sphere.rings = 10
	for i in 40:
		var m := Kit.shader(FIRE_SHADER)
		var mi := MeshInstance3D.new()
		mi.mesh = sphere
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		root.add_child(mi)
		_fire.append(mi)
		_fire_mats.append(m)
	_flash = Kit.omni(root, CONSOLE + Vector3(0, 1.3, 0.4), "#ffd9a0", 0.0, 14.0, true, 2.0)
	var sm := BoxMesh.new()
	sm.size = Vector3(0.012, 0.012, 0.12)
	var smat := Kit.lit("#ffcf6a", 6.0)
	_spark_mm = MultiMesh.new()
	_spark_mm.transform_format = MultiMesh.TRANSFORM_3D
	_spark_mm.mesh = sm
	_spark_mm.instance_count = 160
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = _spark_mm
	smi.material_override = smat
	smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(smi)
	var dark := Kit.mat("#2a2c2e", 0.5, 0.7)
	for i in 14:
		var d := Kit.box(root, Vector3(0.12, 0.03, 0.09) * (1.0 + (i % 3) * 0.5), CONSOLE, dark)
		d.visible = false
		_debris.append(d)


## A jagged bolt between a and b, seeded by k (the frame bucket), into the immediate mesh as a ribbon.
func _bolt(im: ImmediateMesh, a: Vector3, b: Vector3, seed: int, width: float, cam_dir: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var n := 14
	var pts: Array[Vector3] = []
	var dir := (b - a)
	var side := dir.cross(cam_dir).normalized()
	var up := dir.cross(side).normalized()
	for i in n + 1:
		var u := float(i) / n
		var off := Vector3.ZERO
		if i > 0 and i < n:
			off = side * rng.randf_range(-1, 1) * 0.28 * sin(PI * u) + up * rng.randf_range(-1, 1) * 0.2 * sin(PI * u)
		pts.append(a.lerp(b, u) + off)
	for i in n:
		var p0 := pts[i]
		var p1 := pts[i + 1]
		var w := side * width
		im.surface_add_vertex(p0 - w)
		im.surface_add_vertex(p0 + w)
		im.surface_add_vertex(p1 + w)
		im.surface_add_vertex(p0 - w)
		im.surface_add_vertex(p1 + w)
		im.surface_add_vertex(p1 - w)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var power := Motion.smooth(Motion.seg(t, float(_p.get("power", 1e9)), float(_p.get("power", 1e9)) + 1.5))
	var over_t := float(_p.get("overload", 1e9))
	var blast_t := float(_p.get("blast", 1e9))
	var over := Motion.in_cubic(Motion.seg(t, over_t, over_t + 0.9))
	var dead := 1.0 - Motion.smooth(Motion.seg(t, blast_t + 0.1, blast_t + 0.6))
	var flick := 0.85 + 0.15 * sin(t * 37.0) * sin(t * 13.0)
	# Rings turn, faster on overload.
	var spin := t * (0.6 * power) + Motion.in_cubic(Motion.seg(t, over_t, over_t + 1.5)) * 9.0
	if _rings.size() == 2:
		_rings[0].rotation = Vector3(spin, 0, 0)
		_rings[1].rotation = Vector3(0, -spin * 1.3, 0)
	_portal_mat.set_shader_parameter("power", (0.15 + 0.85 * power + 0.8 * over) * dead * flick)
	_portal_mat.set_shader_parameter("time", t)
	_portal_light.light_energy = (0.3 + 2.8 * power + 4.0 * over) * dead * flick
	_tube_mat.emission_energy_multiplier = (0.4 + 3.0 * power + 3.0 * over) * dead * flick
	for l in _hang:
		l.light_energy = 4.5 * (1.0 - 0.6 * over * (0.5 + 0.5 * sin(t * 51.0)))
	# Arcs: from the pylon spheres to the ring, re-struck 24 times a second.
	var im := _arcs.mesh as ImmediateMesh
	im.clear_surfaces()
	var arcs_on := power * dead
	if arcs_on > 0.05:
		var bucket := int(floor(t * 24.0))
		var begun := false
		var count := 1 + int(over * 4.0)
		for e in _emit.size():
			for k in count:
				var rng := RandomNumberGenerator.new()
				rng.seed = bucket * 97 + e * 13 + k
				if rng.randf() > 0.55 + 0.45 * over:
					continue
				var ang := rng.randf_range(-1.2, 1.2) + (0.0 if e == 1 else PI)
				var b := RING + Vector3(cos(ang), sin(ang), 0) * 1.6
				if not begun:
					im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
					begun = true
				_bolt(im, _emit[e], b, bucket * 31 + e * 7 + k, 0.012 + 0.02 * over, Vector3(0, 0, 1))
		if begun:
			im.surface_end()
	_arc_mat.emission_energy_multiplier = 6.0 + 10.0 * over
	# The chalk circle and underline on `warn`.
	var warn := float(_p.get("warn", 1e9))
	var cw := Motion.in_out(Motion.seg(t, warn, warn + 0.55))
	var ul := Motion.in_out(Motion.seg(t, warn + 0.6, warn + 0.85))
	var cim := _circle.mesh as ImmediateMesh
	cim.clear_surfaces()
	if cw > 0.0:
		cim.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		var n := int(48 * cw) + 1
		var prev := Vector3.ZERO
		for i in n + 1:
			var a := -PI * 0.3 + TAU * 1.08 * float(i) / 48.0
			var pnt := _flaw + Vector3(cos(a) * 0.2, sin(a) * 0.075, 0)
			if i > 0:
				var w := Vector3(0, 0.006, 0)
				for v in [prev - w, prev + w, pnt + w, prev - w, pnt + w, pnt - w]:
					cim.surface_add_vertex(v)
			prev = pnt
		if ul > 0.0:
			var a0 := _flaw + Vector3(-0.22, -0.11, 0)
			var a1 := a0 + Vector3(0.44 * ul, 0, 0)
			var w2 := Vector3(0, 0.007, 0)
			for v in [a0 - w2, a0 + w2, a1 + w2, a0 - w2, a1 + w2, a1 - w2]:
				cim.surface_add_vertex(v)
		cim.surface_end()
	if ctx.has("actor"):
		var cd: Dictionary = _p.get("chalk", {})
		if cd.has("actor") and cw > 0.0 and t < warn + 1.2:
			var a = ctx["actor"].call(String(cd["actor"]))
			if a != null:
				var ang := -PI * 0.3 + TAU * 1.08 * cw
				var tip := _flaw + Vector3(cos(ang) * 0.2, sin(ang) * 0.075, 0) if ul <= 0.0 else _flaw + Vector3(-0.22 + 0.44 * ul, -0.11, 0)
				var reach := Motion.in_out(Motion.seg(t, warn - 0.35, warn)) * (1.0 - Motion.smooth(Motion.seg(t, warn + 0.9, warn + 1.2)))
				Crawl.long_arms(a, 1.5)
				a.aim_hand("r", node.global_transform * (_board_xf * tip), reach)
		# The lever: reach, grip, throw.
		var ld: Dictionary = _p.get("lever", {})
		if ld.has("actor"):
			var a2 = ctx["actor"].call(String(ld["actor"]))
			var lt := float(ld.get("t", 1e9))
			var throw := Motion.out_back(Motion.seg(t, lt - 0.05, lt + 0.22), 1.2)
			_lever.rotation = Vector3(-1.15 + 1.35 * throw, 0, 0)
			if a2 != null:
				var reach2 := Motion.in_out(Motion.seg(t, lt - 0.6, lt - 0.1)) * dead
				var grip := LEVER + Basis.from_euler(_lever.rotation) * Vector3(0, 0.33, 0)
				if reach2 > 0.0:
					Crawl.long_arms(a2, 1.4)
					a2.aim_hand("r", node.global_transform * grip, reach2)
		else:
			_lever.rotation = Vector3(-1.15, 0, 0)
	# The blast.
	var bt := minf(t - blast_t, 3.0)
	_flash.light_energy = 0.0
	for mi in _fire:
		mi.visible = false
	for d in _debris:
		d.visible = false
	var hidden := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.001), Vector3(0, -10, 0))
	var srng := RandomNumberGenerator.new()
	for i in _spark_mm.instance_count:
		srng.seed = 7000 + i
		var t0 := over_t + srng.randf() * maxf(blast_t - over_t, 0.1)
		var life := 0.5 + srng.randf() * 0.4
		var from := CONSOLE + Vector3(srng.randf_range(-0.5, 0.5), 1.05, 0.1) if i % 2 == 0 else _emit[i % _emit.size()]
		if i >= 100:
			t0 = blast_t
			life = 1.2 + srng.randf()
			from = CONSOLE + Vector3(0, 1.1, 0.2)
		var k := t - t0
		if k < 0.0 or k > life or t0 > 1e8:
			_spark_mm.set_instance_transform(i, hidden)
			continue
		var v := Vector3(srng.randf_range(-1, 1), srng.randf_range(0.2, 1.4), srng.randf_range(-0.3, 1.4)).normalized() * srng.randf_range(2.5, 6.0)
		if i >= 100:
			v *= 1.6
		var p := from + v * k + Vector3(0, -4.9 * k * k, 0)
		var vel := v + Vector3(0, -9.8 * k, 0)
		var bs := Basis.looking_at(vel.normalized() if vel.length() > 0.01 else Vector3.FORWARD, Vector3.UP)
		_spark_mm.set_instance_transform(i, Transform3D(bs.scaled(Vector3(1, 1, 1.0 + vel.length() * 0.3)), p))
	if bt >= 0.0:
		_flash.light_energy = 30.0 * exp(-bt * 5.0) + 2.5 * exp(-bt * 1.2)
		var frng := RandomNumberGenerator.new()
		for i in _fire.size():
			frng.seed = 400 + i
			var delay := frng.randf() * 0.12
			var k := bt - delay
			if k < 0.0:
				continue
			var dir := Vector3(frng.randf_range(-1, 1), frng.randf_range(-0.2, 1.0), frng.randf_range(0.2, 1.2)).normalized()
			var grow := Motion.out_cubic(clampf(k / 0.5, 0.0, 1.0))
			var pos := CONSOLE + Vector3(0, 1.1, 0.2) + dir * (0.15 + 0.85 * grow) + Vector3(0, 0.5 * k, 0)
			var r := (0.22 + 0.32 * frng.randf()) * (0.3 + 1.0 * grow) * (1.6 if i == 0 else 1.0)
			var mi := _fire[i]
			mi.visible = true
			mi.position = pos
			mi.scale = Vector3.ONE * r
			var heat := clampf(1.0 - k / (0.7 if i < 6 else 0.4), 0.0, 1.0)
			_fire_mats[i].set_shader_parameter("heat", heat)
			_fire_mats[i].set_shader_parameter("seed", float(i) * 3.7 + k * 1.5)
			_fire_mats[i].set_shader_parameter("alpha", clampf(1.0 - k / 1.6, 0.0, 1.0))
		var drng := RandomNumberGenerator.new()
		for i in _debris.size():
			drng.seed = 900 + i
			var v := Vector3(drng.randf_range(-1, 1), drng.randf_range(0.5, 1.5), drng.randf_range(0.2, 1.3)) * drng.randf_range(2.0, 4.5)
			var p := CONSOLE + Vector3(0, 1.0, 0.1) + v * bt + Vector3(0, -4.9 * bt * bt, 0)
			if p.y < 0.03:
				p.y = 0.03
			var d := _debris[i]
			d.visible = true
			d.position = p
			d.rotation = Vector3(bt * (6 + i), bt * (4 + i * 0.5), 0)
	return {"ring": node.global_transform * RING, "console": node.global_transform * (CONSOLE + Vector3(0, 1.1, 0)),
		"board": node.global_transform * _board_xf.origin, "flaw": node.global_transform * (_board_xf * _flaw),
		"lever": node.global_transform * LEVER, "blast": node.global_transform * (CONSOLE + Vector3(0, 1.3, 0.3))}
