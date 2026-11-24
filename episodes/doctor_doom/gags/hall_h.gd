## Hall H, San Diego Convention Center, the Marvel Studios panel (27 July 2024): a dark exhibit hall with a raised
## stage, a giant centre screen and two angled side screens (the logo, or a live close-up of an actor: IMAG), a
## lighting truss of moving heads throwing green beams through haze, backlights that cut the figures on stage into
## silhouettes, a follow spot from the back of the hall, and 6,500 seats of fans (MultiMesh): phones up, then the
## whole hall erupts (arms up, standing, jumping) on `cheer`.
##
## Local frame: the stage's front edge at z 0, x 0; the stage top at y STAGE (1.4); the stage runs back to z -12;
## the seats run from z 4 to z 75 (+z), cameras in the hall look -z.
##
## params:
##   screens  [{"t": t, "show": "logo" | "live" | "black" | "title", "actor": id, "text": "..."}]   what the screens
##            show from t (title: big white letters on black, e.g. AVENGERS: THE KANG DYNASTY)
##   flare    t   the screens flare green (the bookend)
##   beams    {"focus": t, "x": 0.0, "z": -3.0}   the moving heads sweep, then converge on (x, z) from `focus`
##   flash    t   every light spikes white on the reveal and settles warm on the follow spot
##   phones   t   phones come up across the hall from t (a quarter of the fans), more on cheer
##   cheer    t   the hall erupts (staggered over 0.5 s)
##   follow   {"x": 0.0, "z": -3.0}   the follow spot's mark on the stage
## anchors: stage (the stage centre, at the top), screen (the centre screen), seats_mid
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Paths = preload("res://scripts/core/paths.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const STAGE := 1.4
const PH := "incoming/polyhaven_doom/"
const PH0 := "incoming/polyhaven_pokhran/models/"

const SCREEN_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D logo : source_color, filter_linear_mipmap;
uniform sampler2D live : source_color, filter_linear;
uniform float show_logo = 1.0;
uniform float show_live = 0.0;
uniform float bright = 1.0;
uniform float flare = 0.0;
uniform float logo_aspect = 2.1;
uniform float aspect = 1.78;
void fragment() {
	vec2 uv = UV;
	vec3 col = vec3(0.01);
	// The logo centred on black, 42 % of the width.
	float lw = 0.42;
	float lh = lw * aspect / logo_aspect;
	vec2 luv = vec2((uv.x - 0.5 + lw * 0.5) / lw, (uv.y - 0.5 + lh * 0.5) / lh);
	if (luv.x > 0.0 && luv.x < 1.0 && luv.y > 0.0 && luv.y < 1.0) {
		vec4 l = texture(logo, luv);
		col = mix(col, l.rgb, l.a * show_logo);
	}
	vec3 lv = texture(live, vec2(uv.x, uv.y)).rgb;
	col = mix(col, lv * 0.5, show_live);
	// LED pixel grid, faint.
	vec2 px = fract(uv * vec2(aspect, 1.0) * 220.0);
	col *= 0.86 + 0.14 * step(0.18, px.x) * step(0.18, px.y);
	col = mix(col, vec3(0.25, 1.0, 0.45), flare);
	ALBEDO = col * bright;
}
"""

const BEAM_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec3 color : source_color = vec3(0.3, 1.0, 0.5);
uniform float strength = 0.2;
uniform float height = 30.0;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
varying float vy;
void vertex() { vy = VERTEX.y; }
void fragment() {
	float along = clamp(vy / height + 0.5, 0.0, 1.0);
	float edge = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float a = strength * pow(edge, 2.2) * pow(1.0 - along, 1.6) * smoothstep(0.0, 0.04, along);
	// Soft where the cone meets geometry, and fading near the lens.
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 up = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	float scene_z = -up.z / up.w;
	float frag_z = -VERTEX.z;
	a *= clamp((scene_z - frag_z) / 2.5, 0.0, 1.0) * smoothstep(0.8, 4.0, frag_z);
	ALBEDO = color * a;
}
"""

var _p := {}
var _beams := []        # [light, material, base strength]
var _screens: Array[MeshInstance3D] = []
var _titles: Array[Label3D] = []
var _screen_mat: ShaderMaterial
var _view: SubViewport
var _cam: Camera3D
var _heads: Array[SpotLight3D] = []
var _backs: Array[SpotLight3D] = []
var _follow: SpotLight3D
var _fill: OmniLight3D
var _seats := []          # [x, z, colour, seed...]
var _mm_body: MultiMesh
var _mm_head: MultiMesh
var _mm_arm: MultiMesh
var _mm_phone: MultiMesh
var _lip: MeshInstance3D


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "hall"))
	var black := Kit.mat("#09090b", 0.9)
	var gloss := Kit.mat("#060607", 0.22, 0.0, 0.7)
	# The hall: carpet, black walls and a dark ceiling high above, with truss rows for scale.
	var carpet := Kit.textured(PH + "textures/dirty_carpet_diff_2k.jpg", PH + "textures/dirty_carpet_nor_gl_2k.jpg",
		PH + "textures/dirty_carpet_rough_2k.jpg", Vector3(60, 60, 1), Color("#4a4f5c"))
	Kit.box(root, Vector3(130, 0.1, 120), Vector3(0, -0.05, 40), carpet)
	Kit.box(root, Vector3(130, 24, 1), Vector3(0, 12, -16), black)
	Kit.box(root, Vector3(1, 24, 120), Vector3(-62, 12, 40), black)
	Kit.box(root, Vector3(1, 24, 120), Vector3(62, 12, 40), black)
	Kit.box(root, Vector3(130, 1, 120), Vector3(0, 20, 40), Kit.mat("#0c0d10", 0.9))
	var steel := Kit.mat("#2a2c30", 0.5, 0.7)
	for k in 12:
		var z := -6.0 + k * 8.0
		Kit.rod(root, Vector3(-60, 18.6, z), Vector3(60, 18.6, z), 0.12, steel, 6)
		Kit.rod(root, Vector3(-60, 17.8, z), Vector3(60, 17.8, z), 0.08, steel, 6)
		for i in 15:
			var x := -56.0 + i * 8.0
			Kit.ball(root, 0.16, Vector3(x, 17.6, z), Kit.lit("#ffd9a8", 1.2), 8)
	# The stage: glossy black, a green LED lip, steps at the sides.
	Kit.box(root, Vector3(30, STAGE, 12), Vector3(0, STAGE * 0.5, -6), gloss)
	_lip = Kit.box(root, Vector3(30, 0.06, 0.05), Vector3(0, STAGE - 0.04, 0.03), Kit.lit("#39ff6a", 3.0))
	Kit.box(root, Vector3(30.2, 0.08, 0.3), Vector3(0, 0.04, 0.1), Kit.lit("#1fbf4a", 1.2))
	for s: float in [-1.0, 1.0]:
		for k in 4:
			Kit.box(root, Vector3(2.0, STAGE * (k + 1) / 4.0, 0.4), Vector3(s * 13.0, STAGE * (k + 1) / 8.0, 0.2 + 0.4 * (3 - k)), gloss)
	# The back drape: folds of black velour.
	var velour := Kit.mat("#0b0b0e", 0.95)
	for i in 40:
		Kit.box(root, Vector3(1.0, 16, 0.4), Vector3(-20.0 + i * 1.0, 8, -12.6 + 0.25 * sin(i * 1.7)), velour)
	# Screens: the centre one over the stage, two angled at the sides.
	_screen_mat = Kit.shader(SCREEN_SHADER)
	var logo_path := "library/logos/doom/marvel-studios.svg"
	if FileAccess.file_exists(Paths.repo_path(logo_path)):
		_screen_mat.set_shader_parameter("logo", Kit.texture(logo_path, false, 6.0))
	else:
		_screen_mat.set_shader_parameter("logo", _text_logo())
	for sc in [[Vector2(19.2, 10.8), Vector3(0, 8.6, -12.2), 0.0], [Vector2(12.8, 7.2), Vector3(-21, 8.4, -8.5), 0.42],
			[Vector2(12.8, 7.2), Vector3(21, 8.4, -8.5), -0.42]]:
		var frame := Kit.box(root, Vector3(sc[0].x + 0.4, sc[0].y + 0.4, 0.3), sc[1] - Vector3(0, 0, 0.2).rotated(Vector3.UP, sc[2]), black, Vector3(0, sc[2], 0))
		var q := Kit.quad(root, sc[0], sc[1], _screen_mat, Vector3(0, sc[2], 0))
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_screens.append(q)
		var tl := Kit.text(root, "", sc[0].y * 0.11, Color(1, 1, 1), sc[1] + Vector3(0, 0, 0.06).rotated(Vector3.UP, sc[2]),
			Vector3(0, sc[2], 0), true, 1.4)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tl.width = sc[0].x * 0.8 / tl.pixel_size
		_titles.append(tl)
		frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The live (IMAG) camera.
	_view = SubViewport.new()
	_view.size = Vector2i(960, 540)
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_view.own_world_3d = false
	root.add_child(_view)
	_cam = Camera3D.new()
	_cam.fov = 18.0
	_cam.near = 0.05
	_view.add_child(_cam)
	_screen_mat.set_shader_parameter("live", _view.get_texture())
	# The lighting truss over the stage front: moving heads.
	Kit.rod(root, Vector3(-16, 10.5, -1.5), Vector3(16, 10.5, -1.5), 0.1, steel, 6)
	Kit.rod(root, Vector3(-16, 10.0, -1.5), Vector3(16, 10.0, -1.5), 0.1, steel, 6)
	for i in 10:
		var x := -13.5 + i * 3.0
		Kit.cyl(root, 0.22, 0.25, 0.45, Vector3(x, 9.7, -1.5), Kit.mat("#141418", 0.5, 0.5), 12)
		var l := Kit.spot(root, Vector3(x, 9.45, -1.5), Vector3(x * 0.4, STAGE, -4.0), "#46ff78", 55.0, 30.0, 6.5, false, 3.0)
		_heads.append(l)
		_beam(l, 10.5, 0.3)
	# Backlights at the rear of the stage, aimed out over the hall: silhouettes and beams.
	for i in 6:
		var x := -11.0 + i * 4.4
		var y := 1.8 if i % 2 == 0 else 6.5
		var l := Kit.spot(root, Vector3(x, y, -11.5), Vector3(x * 1.6, 1.0, 30.0), "#c8ffd8", 40.0, 60.0, 9.0, false, 1.6)
		_backs.append(l)
		_beam(l, 34.0, 0.09)
		Kit.cyl(root, 0.2, 0.2, 0.35, Vector3(x, y, -11.7), Kit.mat("#141418", 0.5), 12, Vector3(PI / 2, 0, 0))
	# The follow spot from the back of the hall, and a weak fill on the front rows.
	var fd: Dictionary = _p.get("follow", {})
	_follow = Kit.spot(root, Vector3(0, 18.5, 74), Vector3(float(fd.get("x", 0.0)), STAGE + 1.0, float(fd.get("z", -3.0))),
		"#fff2dc", 260.0, 110.0, 2.0, true, 0.35)
	_fill = Kit.omni(root, Vector3(0, 4, 6), "#3a6a8a", 1.2, 18.0, false, 0.2)
	# House lights: warm cones from the ceiling over the seats, dimmed (they read as shafts in the haze).
	for k in 5:
		for i in 7:
			Kit.spot(root, Vector3(-33.0 + i * 11.0, 17.4, 10.0 + k * 13.0), Vector3(-33.0 + i * 11.0, 0.0, 10.0 + k * 13.0),
				"#ffbf7a", 22.0, 26.0, 26.0, false, 1.4)
	# Flood lights on the stage corners (props).
	for s: float in [-1.0, 1.0]:
		var fl := Kit.model(PH0 + "flood_lights/flood_lights_2k.gltf")
		fl.position = Vector3(s * 14.2, STAGE, -1.0)
		fl.rotation = Vector3(0, PI + s * 0.3, 0)
		root.add_child(fl)
	_build_crowd(root)
	return root


## A soft additive cone along a spot light (the beam you see in stage haze), parented to the light.
func _beam(l: SpotLight3D, length: float, strength: float) -> void:
	var cm := CylinderMesh.new()
	cm.height = length
	cm.bottom_radius = 0.12
	cm.top_radius = tan(deg_to_rad(l.spot_angle)) * length * 0.85
	cm.radial_segments = 48
	cm.rings = 8
	cm.cap_top = false
	cm.cap_bottom = false
	var m := Kit.shader(BEAM_SHADER)
	m.set_shader_parameter("height", length)
	m.set_shader_parameter("color", l.light_color)
	m.set_shader_parameter("strength", strength)
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.rotation = Vector3(-PI / 2, 0, 0)
	mi.position = Vector3(0, 0, -length * 0.5)
	l.add_child(mi)
	_beams.append([l, m, strength])


## A stand-in logo (red box, white letters) when the logo file is missing.
func _text_logo() -> Texture2D:
	var img := Image.create(840, 400, false, Image.FORMAT_RGBA8)
	img.fill(Color("#ec1d24"))
	img.fill_rect(Rect2i(40, 170, 760, 8), Color(1, 1, 1))
	return ImageTexture.create_from_image(img)


func _build_crowd(root: Node3D) -> void:
	var rng := Kit.rng("hall_crowd")
	var shirts := ["#1b1d22", "#23262d", "#2b2f38", "#3a3f4a", "#17181c", "#4a2a2a", "#26354a", "#3b4a2e", "#5a5048", "#1e2a3a",
		"#6a1c1c", "#2c2c2c"]
	var hair := ["#17120f", "#2a1f18", "#3a2c20", "#0f0f10", "#5a4632", "#6b5a48", "#20180f"]
	var z := 4.0
	while z < 75.0:
		var x := -38.0
		while x < 38.0:
			var ax := absf(x)
			if not ((ax > 9.0 and ax < 10.6) or (ax > 25.0 and ax < 26.6)):
				_seats.append([x + rng.randf_range(-0.04, 0.04), z, Color(shirts[rng.randi() % shirts.size()]),
					Color(hair[rng.randi() % hair.size()]), rng.randf(), rng.randf(), rng.randf(), rng.randf()])
			x += 0.62
		z += 1.0
	var n := _seats.size()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.75
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.21
	body_mesh.height = 0.8
	body_mesh.radial_segments = 10
	body_mesh.rings = 4
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.115
	head_mesh.height = 0.25
	head_mesh.radial_segments = 10
	head_mesh.rings = 6
	var arm_mesh := CapsuleMesh.new()
	arm_mesh.radius = 0.045
	arm_mesh.height = 0.6
	arm_mesh.radial_segments = 6
	arm_mesh.rings = 2
	var phone_mesh := QuadMesh.new()
	phone_mesh.size = Vector2(0.075, 0.14)
	var phone_mat := StandardMaterial3D.new()
	phone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	phone_mat.albedo_color = Color(0.85, 0.92, 1.0)
	phone_mat.emission_enabled = true
	phone_mat.emission = Color(0.75, 0.85, 1.0)
	phone_mat.emission_energy_multiplier = 3.0
	phone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mm_body = _mm(root, body_mesh, mat, n, true)
	_mm_head = _mm(root, head_mesh, mat, n, true)
	_mm_arm = _mm(root, arm_mesh, mat, n * 2, true)
	_mm_phone = _mm(root, phone_mesh, phone_mat, n, false)
	for i in n:
		var s: Array = _seats[i]
		_mm_body.set_instance_color(i, s[2])
		_mm_head.set_instance_color(i, s[3])
		_mm_arm.set_instance_color(i * 2, s[2])
		_mm_arm.set_instance_color(i * 2 + 1, s[2])
	# Seat backs (static).
	var seat_mesh := BoxMesh.new()
	seat_mesh.size = Vector3(0.5, 0.5, 0.06)
	var mm_seat := _mm(root, seat_mesh, Kit.mat("#202228", 0.7), n, false)
	for i in n:
		var s: Array = _seats[i]
		mm_seat.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(s[0], 0.72, s[1] + 0.27)))


func _mm(root: Node3D, mesh: Mesh, mat: Material, n: int, colors: bool) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = colors
	mm.mesh = mesh
	mm.instance_count = n
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)
	return mm


func _pose_crowd(t: float) -> void:
	var cheer := float(_p.get("cheer", 1e9))
	var phones := float(_p.get("phones", 1e9))
	var hidden := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.001), Vector3(0, -5, 0))
	for i in _seats.size():
		var s: Array = _seats[i]
		var x: float = s[0]
		var z: float = s[1]
		var r1: float = s[4]
		var r2: float = s[5]
		var r3: float = s[6]
		var r4: float = s[7]
		var c := Motion.out_cubic(Motion.seg(t, cheer + r1 * 0.5, cheer + r1 * 0.5 + 0.35))
		var stand := c * (0.42 if r2 < 0.55 else 0.0)
		var jump := 0.0
		if c > 0.0:
			jump = absf(sin((t - cheer) * (7.0 + 3.0 * r3) + r4 * 6.28)) * 0.13 * c * (1.0 if r2 < 0.8 else 0.3)
		# Idle life: a slow lean and a turn of the head.
		var lean := sin(t * (0.5 + r3) + r4 * 6.28) * 0.04
		var base := Vector3(x + lean, 0.82 + stand + jump, z)
		_mm_body.set_instance_transform(i, Transform3D(Basis.from_euler(Vector3(0, 0, lean)), base))
		var head := base + Vector3(lean * 0.5, 0.56, 0)
		_mm_head.set_instance_transform(i, Transform3D(Basis.IDENTITY, head))
		# Arms: down (hidden in the body) until the cheer, then thrown up in a V, pumping.
		if c > 0.0 and r2 < 0.9:
			var pump := sin((t - cheer) * (8.0 + 2.0 * r1) + r3 * 6.28) * 0.18
			for side in 2:
				var sg := -1.0 if side == 0 else 1.0
				var ang := sg * (0.35 + pump * sg) * c + sg * (1.0 - c) * 2.9
				var b := Basis.from_euler(Vector3(0, 0, ang))
				var sh := base + Vector3(sg * 0.17, 0.28, 0)
				_mm_arm.set_instance_transform(i * 2 + side, Transform3D(b, sh + b * Vector3(0, 0.3, 0)))
		else:
			_mm_arm.set_instance_transform(i * 2, hidden)
			_mm_arm.set_instance_transform(i * 2 + 1, hidden)
		# Phones: a quarter of the hall from `phones`, half once the cheer starts; held up toward the stage.
		var up := Motion.out_cubic(Motion.seg(t, phones + r3 * 1.2, phones + r3 * 1.2 + 0.4)) * (1.0 if r4 < 0.25 else 0.0)
		up = maxf(up, Motion.out_cubic(Motion.seg(t, cheer + 0.3 + r3, cheer + 0.7 + r3)) * (1.0 if r4 < 0.5 else 0.0))
		if up > 0.0:
			var ph := head + Vector3(0.12 * (r1 - 0.5), 0.2 + 0.18 * up + jump * 0.5, -0.3)
			_mm_phone.set_instance_transform(i, Transform3D(Basis.from_euler(Vector3(0.1, 0, (r2 - 0.5) * 0.3)).scaled(Vector3.ONE * up), ph))
		else:
			_mm_phone.set_instance_transform(i, hidden)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	# Screens.
	var show := "logo"
	var live_actor := ""
	var since := 0.0
	var title := ""
	for s in _p.get("screens", []):
		if t >= float(s["t"]):
			show = String(s.get("show", "logo"))
			live_actor = String(s.get("actor", ""))
			title = String(s.get("text", ""))
			since = t - float(s["t"])
	for tl in _titles:
		tl.text = title if show == "title" else ""
		tl.modulate = Color(1.4, 1.4, 1.4) * Motion.smooth(clampf(since / 0.5, 0.0, 1.0))
	var fade := Motion.smooth(clampf(since / 0.35, 0.0, 1.0))
	_screen_mat.set_shader_parameter("show_logo", fade if show == "logo" else 0.0)
	_screen_mat.set_shader_parameter("show_live", fade if show == "live" else 0.0)
	if show == "live" and live_actor != "" and ctx.has("actor"):
		var a = ctx["actor"].call(live_actor)
		if a != null:
			var hd: Vector3 = a.bone_world("Head") + Vector3(0, 0.2, 0)
			var ay := float(a.rotation.y)
			var fwd := Vector3(sin(ay), 0, cos(ay))
			var cp := hd + fwd * 3.2 + Vector3(0.25 + 0.05 * sin(t * 0.7), -0.05, 0)
			_cam.global_transform = Transform3D(Basis.looking_at(hd - cp, Vector3.UP), cp)
	# Beams: sweep, then converge.
	var bd: Dictionary = _p.get("beams", {})
	var focus := float(bd.get("focus", 1e9))
	var conv := Motion.in_out(Motion.seg(t, focus, focus + 0.9))
	var fx := float(bd.get("x", 0.0))
	var fz := float(bd.get("z", -3.0))
	var flash_t := float(_p.get("flash", 1e9))
	var fl := 0.0
	if t >= flash_t:
		fl = exp(-(t - flash_t) * 3.2)
	for i in _heads.size():
		var l := _heads[i]
		var x0 := -13.5 + i * 3.0
		var sweep := Vector3(x0 * 0.45 + sin(t * 0.55 + i * 1.3) * 3.2, STAGE, -4.5 + cos(t * 0.4 + i * 0.7) * 2.5)
		var tgt := sweep.lerp(Vector3(fx + (i - 4.5) * 0.12, STAGE + 0.5, fz), conv)
		l.look_at(tgt, Vector3.UP)
		l.light_energy = 55.0 * (1.0 - 0.92 * conv) * (1.0 + 0.6 * fl)
		l.light_color = Color("#46ff78").lerp(Color("#d8ffe2"), fl * 0.5)
	for i in _backs.size():
		_backs[i].light_energy = 40.0 * (1.0 + 2.5 * fl) * (1.0 - 0.2 * conv)
		_backs[i].light_color = Color("#c8ffd8").lerp(Color("#ffffff"), fl)
	var fdd: Dictionary = _p.get("follow", {})
	_follow.look_at(Vector3(float(fdd.get("x", 0.0)), STAGE + 1.0, float(fdd.get("z", -3.0))), Vector3.UP)
	_follow.light_energy = 120.0 * (0.5 + 0.5 * conv)
	var flare := Motion.smooth(Motion.seg(t, float(_p.get("flare", 1e9)), float(_p.get("flare", 1e9)) + 0.4))
	_screen_mat.set_shader_parameter("bright", 0.9 + 0.6 * fl + 1.5 * flare)
	_screen_mat.set_shader_parameter("flare", flare)
	if flare > 0.0:
		_screen_mat.set_shader_parameter("show_logo", 0.0)
		_screen_mat.set_shader_parameter("show_live", 1.0 - flare)
	for b in _beams:
		var l: SpotLight3D = b[0]
		var base := 55.0 if _heads.has(l) else 40.0
		(b[1] as ShaderMaterial).set_shader_parameter("strength", float(b[2]) * l.light_energy / base)
		(b[1] as ShaderMaterial).set_shader_parameter("color", l.light_color)
	_pose_crowd(t)
	return {"stage": node.global_transform * Vector3(0, STAGE, -4.0), "screen": node.global_transform * Vector3(0, 8.6, -12.2),
		"seats_mid": node.global_transform * Vector3(0, 1.2, 30.0)}
