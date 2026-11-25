## National Fire Service Day today, at a Mumbai fire station: the station's red-brick and stone front with its bay
## doors open, red fire engines inside, a memorial plinth with an eternal flame and wreaths of marigolds, firefighters in
## khaki drawn up in two rows, the tricolour on a mast. Morning sun, haze.
##
## Local frame: the memorial at the origin facing +z; the rows of firefighters at z +3..+5 facing -z (toward it); the
## station front at z -10; cameras at +z or to the side.
##
## params: salute t (the rows salute)
## anchors: memorial, flame, rows, flag
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Paths = preload("res://scripts/core/paths.gd")

const PH := "incoming/bombay_gold/polyhaven/"
const SK := "incoming/bombay_gold/sketchfab/"

var FX
var _p := {}
var _fire
var _flag: MeshInstance3D
var _flag_mat: ShaderMaterial


func _tex(name: String, scale: float, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var b := PH + "textures/" + name
	return Kit.textured(b + "_diff_2k.jpg", b + "_nor_gl_2k.jpg", b + "_rough_2k.jpg", Vector3.ONE * scale, tint, true)


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	FX = load(Paths.repo_path("episodes/bombay_gold/gags/fx.gd"))
	var root := Node3D.new()
	root.name = String(g.get("id", "firestation"))
	Kit.box(root, Vector3(80, 0.2, 60), Vector3(0, -0.1, 0), _tex("stone_pavers", 0.4, Color(0.8, 0.76, 0.7)))
	# The station front: red-brick with stone bands, three tall bay doors open on red engines.
	var brick := _tex("red_plaster_weathered", 0.3, Color(0.8, 0.5, 0.42))
	var stone := Kit.mat("#d8ccb4", 0.85)
	Kit.box(root, Vector3(40, 14, 2), Vector3(0, 7, -12), brick)
	for y: float in [5.4, 9.8, 13.6]:
		Kit.box(root, Vector3(40.2, 0.5, 2.2), Vector3(0, y, -12), stone)
	for k in 3:
		var x := -10.0 + k * 10.0
		Kit.box(root, Vector3(6.0, 5.0, 0.3), Vector3(x, 2.5, -10.9), Kit.mat("#141210", 0.9))
		Kit.ball(root, 3.0, Vector3(x, 5.0, -10.88), stone, 16, Vector3(1.0, 0.35, 0.05))
		var truck := Kit.model(SK + "free_1940s_us_fire_truck_american_lafrance.glb")
		truck.position = Vector3(x, 0, -13.5)
		truck.rotation.y = 0.0
		truck.scale = Vector3.ONE * 1.05
		root.add_child(truck)
		for w in 4:
			Kit.box(root, Vector3(1.4, 2.0, 0.1), Vector3(x - 3.0 + w * 2.0, 8.0, -10.95), Kit.mat("#1e2228", 0.3, 0.2))
	# The memorial: a stepped plinth, an obelisk, a bronze flame bowl, wreaths of marigolds.
	Kit.box(root, Vector3(4.0, 0.3, 4.0), Vector3(0, 0.15, 0), stone)
	Kit.box(root, Vector3(3.0, 0.3, 3.0), Vector3(0, 0.45, 0), stone)
	Kit.box(root, Vector3(1.4, 3.6, 1.4), Vector3(0, 2.4, 0), Kit.mat("#3a3632", 0.4, 0.2))
	Kit.cyl(root, 0.0, 0.75, 1.2, Vector3(0, 4.8, 0), Kit.mat("#3a3632", 0.4, 0.2), 4, Vector3(0, PI * 0.25, 0))
	Kit.cyl(root, 0.5, 0.3, 0.35, Vector3(0, 1.0, 1.4), Kit.mat("#8a6a3a", 0.3, 0.9), 24)
	Kit.box(root, Vector3(0.1, 0.7, 0.1), Vector3(0, 0.55, 1.4), Kit.mat("#8a6a3a", 0.3, 0.9))
	var marigold := Kit.mat("#f2a20c", 0.7)
	var green := Kit.mat("#2e5a2a", 0.8)
	for k in 5:
		var c := Vector3(-1.6 + k * 0.8, 0.95, 1.85)
		var torus := TorusMesh.new()
		torus.inner_radius = 0.28
		torus.outer_radius = 0.42
		var wr := MeshInstance3D.new()
		wr.mesh = torus
		wr.material_override = marigold if k % 2 == 0 else Kit.mat("#e85a12", 0.7)
		wr.position = c
		wr.rotation.x = PI * 0.5 - 0.25
		root.add_child(wr)
		Kit.box(root, Vector3(0.05, 0.9, 0.05), c + Vector3(0, -0.45, -0.1), green, Vector3(0.25, 0, 0))
	# The flag on its mast.
	Kit.rod(root, Vector3(8, 0, -3), Vector3(8, 14, -3), 0.08, Kit.mat("#e8e4dc", 0.5, 0.4), 10)
	_flag = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(3.0, 2.0)
	pm.subdivide_width = 24
	pm.subdivide_depth = 16
	pm.orientation = PlaneMesh.FACE_Z
	_flag.mesh = pm
	_flag_mat = Kit.shader("""
shader_type spatial;
render_mode cull_disabled;
uniform float t = 0.0;
void vertex() {
	float u = UV.x;
	VERTEX.z += sin(u * 6.0 - t * 4.0) * 0.18 * u;
	VERTEX.y += sin(u * 4.0 - t * 3.0) * 0.05 * u;
}
void fragment() {
	vec3 c = UV.y < 0.333 ? vec3(1.0, 0.6, 0.2) : (UV.y < 0.667 ? vec3(0.97) : vec3(0.07, 0.53, 0.03));
	float d = length((UV - vec2(0.5)) * vec2(3.0, 2.0));
	float wheel = (1.0 - smoothstep(0.26, 0.29, d)) * smoothstep(0.2, 0.23, d);
	float spokes = step(0.85, fract(atan(UV.y - 0.5, (UV.x - 0.5) * 1.5) / 6.2831 * 24.0)) * (1.0 - smoothstep(0.25, 0.27, d));
	c = mix(c, vec3(0.0, 0.0, 0.5), clamp(wheel + spokes, 0.0, 1.0));
	ALBEDO = c;
	ROUGHNESS = 0.85;
}
""")
	_flag.material_override = _flag_mat
	_flag.position = Vector3(9.5, 12.8, -3)
	root.add_child(_flag)
	_fire = FX.layer(root, 60, "fire")
	Kit.omni(root, Vector3(0, 1.6, 1.5), "#ffb050", 1.2, 4.0, false, 0.5)
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var inv := gt.affine_inverse()
	var cam := node.get_viewport().get_camera_3d()
	var cam_l: Vector3 = (inv * cam.global_position) if cam else Vector3(0, 2, 10)
	_flag_mat.set_shader_parameter("t", t)
	FX.begin(_fire)
	FX.flames(_fire, Vector3(0, 1.2, 1.4), Vector2(0.18, 0.18), t, {"count": 8, "height": 0.7, "size": 0.55, "heat": 0.9, "seed": 4})
	FX.finish(_fire, cam_l, t)
	# The salute: each firefighter's right hand to the brow on `salute`, staggered along the rows.
	var salute := float(_p.get("salute", 1e9))
	if ctx.has("actor"):
		for i in 16:
			var a = ctx["actor"].call("ff_%d" % i)
			if a == null or not a.visible:
				continue
			var k := Motion.out_back(clampf((t - salute - (i % 8) * 0.06) / 0.35, 0.0, 1.0), 1.4)
			if k > 0.0:
				var head: Vector3 = a.bone_world("head")
				var fwd := Vector3(sin(a.rotation.y), 0, cos(a.rotation.y))
				var right := Vector3(cos(a.rotation.y), 0, -sin(a.rotation.y))
				a.aim_hand("r", head + fwd * 0.18 + right * 0.12 + Vector3(0, 0.05, 0), k)
	return {"memorial": gt * Vector3(0, 2.6, 0), "flame": gt * Vector3(0, 1.3, 1.4), "rows": gt * Vector3(0, 1.4, 4.0), "flag": gt * Vector3(9.5, 12.8, -3)}
