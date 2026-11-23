## The Pokhran devices in flight, dawn, 1998: an IAF An-32 high over the Thar (the desert scrolls past far below) and,
## inside its cargo hold, the device strapped to its cradle under one warm work light.
##
## Local frame: the aircraft's nose is +X, up +Y (glTF from blender/aircraft.py: the fuselage axis at y 2.25, the
## fuselage skin at radius ~1.45; the right side, Blender -Y, is +Z here). The hold runs x -3.6..6.5 with its floor at
## y 1.15; the device sits on its cradle with its base at DEVICE_AT.
##
## params:
##   speed     ground speed in m/s (default 75): how fast the desert scrolls past below
##   altitude  metres above the ground (default 380)
## anchors: plane (fuselage centre), device (the cradle's base centre), device_mid (the casing's middle)
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const PB := "incoming/pokhran_blender/"
const TX := "incoming/polyhaven_pokhran/textures/"
const DEVICE_AT := Vector3(0.8, 1.15, 0.0)

const GROUND := """
shader_type spatial;
render_mode diffuse_lambert;
uniform sampler2D sand : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float scroll = 0.0;
varying vec2 wp;
//NOISE
void vertex() { wp = VERTEX.xz + vec2(scroll, 0.0); }
void fragment() {
	vec3 s = texture(sand, wp * 0.02).rgb;
	float big = fbm(vec3(wp * 0.0015, 1.0));
	float mid = fbm(vec3(wp * 0.012, 4.0));
	// Dune swells and darker gravel flats, scattered scrub.
	vec3 c = s * vec3(1.12, 0.98, 0.8) * (0.72 + 0.45 * big) * (0.85 + 0.25 * mid);
	float scrub = step(0.78, fbm(vec3(wp * 0.09, 9.0)));
	c = mix(c, vec3(0.2, 0.2, 0.12), scrub * 0.6);
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
"""

var _p := {}
var _plane: Node3D
var _props: Array = []
var _ground_mat: ShaderMaterial


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "flight"))
	# The desert far below (a big plane; its texture scrolls under the aircraft).
	var gr := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(16000, 16000)
	gr.mesh = pm
	_ground_mat = Kit.shader(GROUND)
	_ground_mat.set_shader_parameter("sand", Kit.texture(TX + "sand_01_diff_2k.jpg"))
	gr.material_override = _ground_mat
	gr.position = Vector3(0, -float(_p.get("altitude", 380.0)), 0)
	gr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(gr)
	# The aircraft.
	_plane = Node3D.new()
	_plane.name = "an32"
	root.add_child(_plane)
	var ac := Kit.model(PB + "an32.glb")
	_plane.add_child(ac)
	for n in ac.find_children("prop_*", "Node3D", true, false):
		_props.append(n)
	_hold(_plane)
	return root


## The cargo hold: a ribbed shell in green-grey primer, a floor with roller tracks, ceiling lamps, cargo nets; the
## device on its cradle, strapped down, under a warm work light.
func _hold(parent: Node3D) -> void:
	var primer := Kit.mat("#56705f", 0.72, 0.15)
	var rib := Kit.mat("#4a6152", 0.6, 0.3)
	var floor_m := Kit.mat("#2f3230", 0.55, 0.6)
	var shell := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.38
	cm.bottom_radius = 1.38
	cm.height = 10.4
	cm.radial_segments = 40
	cm.flip_faces = true
	shell.mesh = cm
	shell.material_override = primer
	shell.position = Vector3(1.45, 2.25, 0)
	shell.rotation = Vector3(0, 0, PI / 2)
	parent.add_child(shell)
	for i in 19:
		var x := -3.5 + 0.55 * i
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 1.3
		tm.outer_radius = 1.38
		tm.rings = 40
		tm.ring_segments = 6
		ring.mesh = tm
		ring.material_override = rib
		ring.position = Vector3(x, 2.25, 0)
		ring.rotation = Vector3(0, 0, PI / 2)
		parent.add_child(ring)
	Kit.box(parent, Vector3(10.2, 0.06, 2.3), Vector3(1.45, 1.12, 0), floor_m)
	for z in [-0.5, 0.5]:
		Kit.box(parent, Vector3(10.0, 0.03, 0.12), Vector3(1.45, 1.165, z), Kit.mat("#5a5d5a", 0.35, 0.8))
	# Ceiling lamps: small warm lenses and a dim fill each.
	for i in 4:
		var x := -2.6 + 2.7 * i
		Kit.box(parent, Vector3(0.3, 0.03, 0.12), Vector3(x, 3.6, 0), Kit.lit("#ffd9a0", 3.0))
		Kit.omni(parent, Vector3(x, 3.45, 0), Color(1.0, 0.82, 0.6), 0.35, 3.2, false, 0.2)
	# Cargo nets on the walls (a diamond of thin cords).
	var cord := Kit.mat("#2b2b22", 0.9)
	for side in []:          # (cargo nets read as stray sticks at this scale: off)
		for i in 9:
			var x := -3.2 + 1.0 * i
			Kit.rod(parent, Vector3(x, 1.4, side * 1.22), Vector3(x + 0.9, 2.8, side * 0.95), 0.008, cord, 4)
			Kit.rod(parent, Vector3(x + 0.9, 1.4, side * 1.22), Vector3(x, 2.8, side * 0.95), 0.008, cord, 4)
	# The device on its cradle, the indicator lamps lit.
	var dev := Kit.model(PB + "device.glb")
	dev.position = DEVICE_AT
	parent.add_child(dev)
	for mi in dev.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for si in m.mesh.get_surface_count():
			var mat := m.mesh.surface_get_material(si)
			if mat != null and String(mat.resource_name) == "indicator":
				m.set_surface_override_material(si, Kit.lit("#3dff7a", 4.0))
	# Ratchet straps over the casing: yellow webbing from floor rings, over the top, to the rings opposite.
	var web := Kit.mat("#d6ad1c", 0.75)
	for dx in [-0.6, 0.55]:
		var r := 0.43 if dx < 0.0 else 0.36
		var c := DEVICE_AT + Vector3(dx, 0.62, 0)
		var prev := DEVICE_AT + Vector3(dx, 0.1, 0.55)
		for k in 15:
			var a := -0.35 + (PI + 0.7) * float(k) / 14.0
			var p := c + Vector3(0, sin(a) * r, cos(a) * r)
			Kit.rod(parent, prev, p, 0.018, web, 4)
			prev = p
		Kit.rod(parent, prev, DEVICE_AT + Vector3(dx, 0.1, -0.55), 0.018, web, 4)
		Kit.box(parent, Vector3(0.05, 0.06, 0.03), c + Vector3(0, r * 0.7, r * 0.72), Kit.mat("#8a8a86", 0.3, 0.9))
	# The work light: a warm spot from above and forward, the device the brightest thing in the hold.
	var key := Kit.spot(parent, DEVICE_AT + Vector3(1.6, 2.2, 0.7), DEVICE_AT + Vector3(0, 0.6, 0), Color(1.0, 0.78, 0.5), 7.0, 6.0, 32.0, true, 0.6)
	key.name = "device_key"
	Kit.omni(parent, DEVICE_AT + Vector3(-1.2, 1.9, -0.9), Color(0.55, 0.7, 0.9), 0.4, 3.0, false, 0.2)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	_ground_mat.set_shader_parameter("scroll", t * float(_p.get("speed", 75.0)))
	# The propellers turn (fast enough to blur at the motion-blurred final), the aircraft rides gently on the air.
	for p in _props:
		(p as Node3D).rotation.x = t * 11.0     # a readable spin at 30 fps (faster strobes to a standstill)
	_plane.position = Vector3(0, 0.12 * sin(t * 0.7), 0)
	_plane.rotation = Vector3(0.012 * sin(t * 0.5), 0, 0.008 * sin(t * 0.37 + 1.0))
	return {"plane": gt * (_plane.position + Vector3(1.0, 2.25, 0)), "device": gt * (_plane.transform * DEVICE_AT),
		"device_mid": gt * (_plane.transform * (DEVICE_AT + Vector3(0, 0.62, 0)))}
