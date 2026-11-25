## Mumbai port, February 2011, dusk: a grab dredger working the old dock basin. Its steel deck with a crane and a
## clamshell grab on wire ropes; the grab rises out of the brown water streaming mud, opens over the hopper, and in the
## mud, a gold bar glints. Container cranes and stacked boxes on the far quay, the city's lights coming on.
##
## Local frame: the water at y 0; the dredger's deck at y 2.2, centred at the origin, crane on the deck at (0, 2.2, -4)
## slewing toward the water at +z; the grab works at GRAB (0, *, 9); cameras on the deck or on the water.
##
## params: rise t (the grab breaks the surface); open t (it opens over the hopper); bar t (the bar shows in the mud)
## anchors: grab, bar, crane, sky
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Paths = preload("res://scripts/core/paths.gd")

const PH := "incoming/bombay_gold/polyhaven/"
const SK := "incoming/bombay_gold/sketchfab/"
const GRAB := Vector3(0.0, 0.0, 9.0)

const WATER := """
shader_type spatial;
uniform float t = 0.0;
uniform vec3 ring_c = vec3(0.0, 0.0, 9.0);
uniform float ring_age = -1.0;
varying vec3 wp;
//NOISE
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = 0.05 * sin(wp.x * 0.4 + t) + 0.04 * sin(wp.z * 0.6 - t * 0.8);
	if (ring_age > 0.0) {
		float d = length(wp.xz - ring_c.xz);
		h += 0.25 * exp(-pow((d - ring_age * 3.0) / 1.2, 2.0)) * exp(-ring_age * 0.6);
	}
	VERTEX.y += h;
}
void fragment() {
	float n = fbm(vec3(wp.xz * 0.2, t * 0.05));
	ALBEDO = mix(vec3(0.16, 0.13, 0.09), vec3(0.26, 0.21, 0.14), n);
	ROUGHNESS = 0.12;
	SPECULAR = 0.55;
}
"""

var FX
var _p := {}
var _water: ShaderMaterial
var _grab: Node3D
var _jaws: Array[Node3D] = []
var _wires: Array[MeshInstance3D] = []
var _bar: MeshInstance3D
var _mud: MeshInstance3D
var _spray
var _smoke
var _glint: OmniLight3D


func _tex(name: String, scale: float, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var b := PH + "textures/" + name
	return Kit.textured(b + "_diff_2k.jpg", b + "_nor_gl_2k.jpg", b + "_rough_2k.jpg", Vector3.ONE * scale, tint, true)


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	FX = load(Paths.repo_path("episodes/bombay_gold/gags/fx.gd"))
	var root := Node3D.new()
	root.name = String(g.get("id", "port"))
	var plane := PlaneMesh.new()
	plane.size = Vector2(1600, 1600)
	plane.subdivide_width = 160
	plane.subdivide_depth = 160
	var wmi := MeshInstance3D.new()
	wmi.mesh = plane
	_water = Kit.shader(WATER)
	wmi.material_override = _water
	root.add_child(wmi)
	# The dredger: hull, deck, hopper, wheelhouse, the crane on a slewing base with its jib out over the water.
	var hull := Kit.mat("#1e2a3a", 0.6, 0.4)
	var deck := _tex("rusty_metal_02", 0.3, Color(0.5, 0.42, 0.36))
	var orange := Kit.mat("#d8641c", 0.5, 0.3)
	var white := Kit.mat("#e4e2da", 0.6)
	Kit.box(root, Vector3(14, 3.0, 40), Vector3(0, 0.7, -12), hull)
	Kit.box(root, Vector3(14.2, 0.2, 40), Vector3(0, 2.25, -12), deck)
	Kit.box(root, Vector3(10, 1.8, 14), Vector3(0, 3.2, -14), Kit.mat("#3a2a1c", 0.8))
	Kit.box(root, Vector3(9.4, 0.4, 13.4), Vector3(0, 3.6, -14), Kit.mat("#4a3622", 0.95))
	Kit.box(root, Vector3(8, 5, 6), Vector3(0, 4.7, -28), white)
	for k in 5:
		Kit.box(root, Vector3(1.0, 0.9, 0.05), Vector3(-3.0 + k * 1.5, 6.0, -24.97), Kit.lit("#ffd8a0", 1.2))
	Kit.cyl(root, 2.2, 2.4, 1.2, Vector3(0, 2.9, -4), orange, 24)
	Kit.box(root, Vector3(3.2, 3.0, 3.6), Vector3(0, 5.0, -4.4), orange)
	Kit.box(root, Vector3(1.4, 1.0, 0.05), Vector3(0.6, 5.6, -2.58), Kit.lit("#cfe8ff", 0.6))
	Kit.rod(root, Vector3(-0.6, 4.0, -3.0), Vector3(-0.3, 16.0, 9.0), 0.25, orange, 8)
	Kit.rod(root, Vector3(0.6, 4.0, -3.0), Vector3(0.3, 16.0, 9.0), 0.25, orange, 8)
	for k in 8:
		var a := Vector3(-0.6, 4.0, -3.0).lerp(Vector3(-0.3, 16.0, 9.0), k / 8.0)
		var b := Vector3(0.6, 4.0, -3.0).lerp(Vector3(0.3, 16.0, 9.0), (k + 1) / 8.0)
		Kit.rod(root, a, b, 0.07, orange, 6)
	Kit.cyl(root, 0.45, 0.45, 0.8, Vector3(0, 16.0, 9.0), Kit.mat("#2a2a2a", 0.5, 0.7), 16, Vector3(0, 0, PI * 0.5))
	for k in 4:
		var w := MeshInstance3D.new()
		w.material_override = Kit.mat("#2a2a2a", 0.4, 0.8)
		root.add_child(w)
		_wires.append(w)
	# The clamshell grab: a head and two jaws.
	_grab = Node3D.new()
	root.add_child(_grab)
	var steel := Kit.mat("#3a3a38", 0.55, 0.75)
	Kit.box(_grab, Vector3(1.2, 0.8, 1.0), Vector3(0, 1.6, 0), steel)
	for s in 2:
		var jaw := Node3D.new()
		jaw.position = Vector3(0, 1.2, 0)
		_grab.add_child(jaw)
		var sx := -1.0 if s == 0 else 1.0
		Kit.box(jaw, Vector3(1.5, 0.12, 1.6), Vector3(sx * 0.7, -0.75, 0), steel, Vector3(0, 0, sx * 0.5))
		Kit.box(jaw, Vector3(0.12, 1.2, 1.6), Vector3(sx * 1.35, -0.6, 0), steel)
		Kit.rod(jaw, Vector3(0, 0, -0.7), Vector3(sx * 1.3, -1.1, -0.7), 0.06, steel, 6)
		Kit.rod(jaw, Vector3(0, 0, 0.7), Vector3(sx * 1.3, -1.1, 0.7), 0.06, steel, 6)
		_jaws.append(jaw)
	# Mud in the grab, and the bar in it.
	_mud = MeshInstance3D.new()
	var mm := SphereMesh.new()
	mm.radius = 1.0
	mm.height = 1.2
	_mud.mesh = mm
	_mud.material_override = _tex("brown_mud_02", 1.2, Color(0.55, 0.45, 0.32))
	_mud.position = Vector3(0, 0.55, 0)
	_mud.scale = Vector3(1.25, 0.6, 0.75)
	_grab.add_child(_mud)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("#e8c050")
	gold.metallic = 1.0
	gold.roughness = 0.35
	gold.emission_enabled = true
	gold.emission = Color("#ffb428")
	gold.emission_energy_multiplier = 0.45
	var bm := BoxMesh.new()
	bm.size = Vector3(0.26, 0.075, 0.13)
	_bar = MeshInstance3D.new()
	_bar.mesh = bm
	_bar.material_override = gold
	_bar.position = Vector3(0.2, 1.08, 0.2)
	_bar.rotation = Vector3(0.35, 0.5, 0.25)
	_grab.add_child(_bar)
	_glint = Kit.omni(_grab, Vector3(0.2, 1.5, 0.7), "#ffd890", 0.0, 2.5, false, 0.0)
	# The far quay: container cranes and stacks, lights coming on.
	var rng := Kit.rng("port")
	for k in 6:
		var c := Kit.model(SK + "ship_to_shore_crane.glb")
		c.scale = Vector3.ONE * 0.1
		c.position = Vector3(-160.0 + k * 70.0, 2.0, -260.0)
		c.rotation.y = PI * 0.5
		root.add_child(c)
	Kit.box(root, Vector3(900, 4, 120), Vector3(0, 0, -330), _tex("stone_pavers", 0.3, Color(0.6, 0.58, 0.55)))
	var box_cols := ["#a8342a", "#2a5a8a", "#d8a23a", "#3a6a4a", "#8a8a8a", "#c85a1a"]
	for k in 160:
		var x := -300.0 + (k % 40) * 15.0
		var y := 2.0 + 1.3 + (k / 40) * 2.6
		Kit.box(root, Vector3(12.0, 2.5, 2.4), Vector3(x, y, -300.0 - (k % 3) * 2.6), Kit.mat(box_cols[rng.randi() % box_cols.size()], 0.6, 0.3))
	for k in 40:
		Kit.box(root, Vector3(rng.randf_range(20, 40), rng.randf_range(20, 80), 20), Vector3(-500.0 + k * 26.0, 30, -480.0 - rng.randf_range(0, 80)), Kit.mat("#2a2e36", 0.8))
		for w in 6:
			Kit.box(root, Vector3(2.0, 1.2, 0.2), Vector3(-505.0 + k * 26.0 + (w % 3) * 5.0, 15.0 + w * 6.0, -469.0), Kit.lit("#ffcf8a", 0.9))
	_spray = FX.layer(root, 400, "spray")
	_spray.mat.set_shader_parameter("col", Color(0.42, 0.34, 0.24))
	_smoke = FX.layer(root, 80, "smoke")
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var inv := gt.affine_inverse()
	var cam := node.get_viewport().get_camera_3d()
	var cam_l: Vector3 = (inv * cam.global_position) if cam else Vector3(0, 3, 20)
	var rise := float(_p.get("rise", 1e9))
	var open_t := float(_p.get("open", 1e9))
	var bar_t := float(_p.get("bar", 1e9))
	_water.set_shader_parameter("t", t)
	_water.set_shader_parameter("ring_age", (t - rise) if t > rise else -1.0)
	# The grab: under water until `rise`, hauled up to 9 m, swinging slightly; jaws closed until `open`.
	var u := Motion.smooth(clampf((t - (rise - 0.6)) / 3.2, 0.0, 1.0))
	var y := lerpf(-3.0, 7.5, u)
	var sw := 0.05 * sin(t * 1.6) * u
	_grab.position = GRAB + Vector3(sin(sw) * 1.0, y, 0)
	_grab.rotation = Vector3(0, 0.3, sw)
	var op := Motion.out_back(clampf((t - open_t) / 0.6, 0.0, 1.0), 1.2)
	_jaws[0].rotation.z = -op * 0.5
	_jaws[1].rotation.z = op * 0.5
	var top := Vector3(0, 16.0, 9.0)
	for k in 4:
		var off := Vector3(-0.35 + (k % 2) * 0.7, 0, -0.3 + (k / 2) * 0.6)
		var a := _grab.position + Vector3(0, 2.0, 0) + off * 0.6
		var d := top + off * 0.2 - a
		var c := CylinderMesh.new()
		c.top_radius = 0.025
		c.bottom_radius = 0.025
		c.height = d.length()
		c.radial_segments = 5
		_wires[k].mesh = c
		var yv := d.normalized()
		var xv := yv.cross(Vector3.FORWARD).normalized()
		_wires[k].transform = Transform3D(Basis(xv, yv, xv.cross(yv)), (a + top + off * 0.2) * 0.5)
	# Streams of muddy water off the grab as it rises.
	FX.begin(_spray)
	FX.begin(_smoke)
	if t > rise - 0.2 and _grab.position.y > 0.2:
		for k in 5:
			var from := _grab.position + Vector3(-1.2 + k * 0.6, 0.15, (k % 2) * 0.5 - 0.25)
			FX.jet(_spray, from, Vector3(0, -0.5, 0), t, {"t0": rise - 0.2, "rate": 40.0, "life": 1.0, "size0": 0.12, "grow": 0.5,
				"alpha": 0.6, "seed": 1100 + k, "floor": 0.0, "scatter": 0.25})
	FX.finish(_spray, cam_l, t)
	FX.finish(_smoke, cam_l, t)
	var bk := clampf((t - bar_t) / 0.4, 0.0, 1.0)
	_glint.light_energy = bk * (2.2 + 1.0 * sin(t * 6.0))
	return {"grab": gt * (_grab.position + Vector3(0, 1.0, 0)), "bar": gt * (_grab.position + Vector3(0.2, 1.1, 0.2)),
		"crane": gt * Vector3(0, 10, 3), "sky": gt * (_grab.position + Vector3(0, 60, -20))}
