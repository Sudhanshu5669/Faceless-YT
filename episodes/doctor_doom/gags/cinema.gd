## A big cinema: a stadium-raked auditorium (stepped rows of red seats, a packed MultiMesh audience, warm wall
## sconces), a giant screen, the projector beam from the booth through haze; and outside, the marquee on a wet night
## street with chasing bulbs.
##
## Local frame: the screen on the wall at z -14 (centre (0, 4.6)), rows rising toward +z (row k at z -8 + 1.1k,
## floor y 0.35k), the booth at (0, 6.6, 8.2). The marquee facade stands apart at x 80 facing +z (street at z > 0 there).
##
## params:
##   screen   [{"t": t, "show": "title" | "white" | "trailer" | "black", "text": "AVENGERS: ENDGAME"}]
##   cheer    t   the audience leaps up cheering (staggered)
##   ticket   t   a ticket (AVENGERS: DOOMSDAY / 18 DEC) flutters down through the projector beam, landing at t + 2
##   marquee  ["LINE 1", "LINE 2"]   the marquee letters; poster: the lightbox poster's text
##   marquee_sets [{"t": t, "lines": ["...", "..."]}]   change the marquee letters from t (e.g. IRON MAN in 2008)
## anchors: screen, beam, ticket, marquee, front_row
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const SCREEN := Vector3(0, 4.6, -13.9)
const BOOTH := Vector3(0, 6.6, 8.2)
const MARQ := Vector3(80, 0, 0)

const BEAM_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec3 color : source_color = vec3(0.8, 0.85, 1.0);
uniform float strength = 0.2;
uniform float height = 22.0;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
varying float vy;
void vertex() { vy = VERTEX.y; }
void fragment() {
	float along = clamp(vy / height + 0.5, 0.0, 1.0);
	float edge = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float a = strength * pow(edge, 2.0) * (0.35 + 0.65 * (1.0 - along));
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 up = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	a *= clamp((-up.z / up.w + VERTEX.z) / 2.0, 0.0, 1.0) * smoothstep(0.5, 3.0, -VERTEX.z);
	ALBEDO = color * a;
}
"""

var _p := {}
var _screen_mat: StandardMaterial3D
var _title: Label3D
var _logo: MeshInstance3D       # show "logo": the film's real title logo on the screen
var _logo_mat: StandardMaterial3D
var _date: Label3D
var _spill: SpotLight3D
var _beam_mat: ShaderMaterial
var _seats := []
var _mm_body: MultiMesh
var _mm_head: MultiMesh
var _mm_arm: MultiMesh
var _ticket: Node3D
var _bulbs: Array[MeshInstance3D] = []
var _bulb_on: StandardMaterial3D
var _bulb_off: StandardMaterial3D
var _marquee_labels: Array[Label3D] = []


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "cinema"))
	var dark := Kit.mat("#120d0e", 0.9)
	var carpet := Kit.mat("#2a0f14", 0.95)
	# Walls, ceiling, the stepped floor.
	Kit.box(root, Vector3(20, 0.1, 6), Vector3(0, -0.05, -11.5), carpet)
	for k in 15:
		Kit.box(root, Vector3(20, 0.35 * (k + 1), 1.1), Vector3(0, 0.175 * (k + 1), -8.0 + k * 1.1 + 0.55), carpet)
	Kit.box(root, Vector3(20, 10, 0.3), Vector3(0, 5, -14.2), dark)
	Kit.box(root, Vector3(20, 10, 0.3), Vector3(0, 5, 8.6), dark)
	for s: float in [-1.0, 1.0]:
		Kit.box(root, Vector3(0.3, 10, 23), Vector3(s * 10, 5, -2.8), Kit.mat("#2a1416", 0.85))
		for k in 5:
			var z := -11.0 + k * 4.0
			Kit.box(root, Vector3(0.12, 0.6, 0.3), Vector3(s * 9.8, 3.0 + 0.3 * k, z), Kit.lit("#ffb070", 1.2))
			Kit.omni(root, Vector3(s * 9.5, 3.0 + 0.3 * k, z), "#ff9a50", 1.6, 5.0, false, 0.3)
		# Velvet curtain swags beside the screen.
		Kit.box(root, Vector3(1.2, 8, 0.4), Vector3(s * 7.9, 4.5, -13.8), Kit.mat("#5a0f18", 0.9))
	Kit.box(root, Vector3(20, 0.3, 23), Vector3(0, 10, -2.8), Kit.mat("#0a0809", 0.9))
	# The screen.
	_screen_mat = StandardMaterial3D.new()
	_screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_screen_mat.albedo_color = Color(0.05, 0.05, 0.06)
	var scr := Kit.quad(root, Vector2(14.4, 6.0), SCREEN, _screen_mat)
	scr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_title = Kit.text(root, "", 0.6, Color(1, 1, 1), SCREEN + Vector3(0, 0, 0.05), Vector3.ZERO, true, 1.6)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# The logo mode: the real title logo (params.screen[].image, 2.51:1) with a date line under it.
	_logo_mat = StandardMaterial3D.new()
	_logo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_logo_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD   # the logo file sits on opaque black: add it, black vanishes
	_logo_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_logo = Kit.quad(root, Vector2(9.6, 9.6 / 2.514), SCREEN + Vector3(0, 0.55, 0.08), _logo_mat)
	_logo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_logo.visible = false
	_date = Kit.text(root, "", 0.55, Color(1, 1, 1), SCREEN + Vector3(0, -2.05, 0.08), Vector3.ZERO, true, 1.6)
	_date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spill = Kit.spot(root, SCREEN + Vector3(0, 0, 0.5), Vector3(0, 2.5, 6), "#dfe6ff", 14.0, 30.0, 55.0, false, 0.2)
	# The projector beam.
	Kit.box(root, Vector3(1.4, 0.8, 0.1), BOOTH + Vector3(0, 0, 0.3), Kit.lit("#fff4dc", 2.0))
	var beam := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	var length := (SCREEN - BOOTH).length()
	cm.height = length
	cm.bottom_radius = 0.25
	cm.top_radius = 4.0
	cm.radial_segments = 48
	cm.cap_top = false
	cm.cap_bottom = false
	beam.mesh = cm
	_beam_mat = Kit.shader(BEAM_SHADER)
	_beam_mat.set_shader_parameter("height", length)
	beam.material_override = _beam_mat
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var holder := Node3D.new()
	root.add_child(holder)
	holder.look_at_from_position(BOOTH, SCREEN, Vector3.UP)
	holder.add_child(beam)
	beam.rotation = Vector3(-PI / 2, 0, 0)
	beam.position = Vector3(0, 0, -length * 0.5)
	_build_crowd(root)
	_build_ticket(root)
	_build_marquee(root)
	return root


func _build_crowd(root: Node3D) -> void:
	var rng := Kit.rng("cinema_crowd")
	var shirts := ["#1b1d22", "#2b2f38", "#3a3f4a", "#6a1c1c", "#26354a", "#3b4a2e", "#5a5048", "#8a6a2a", "#2c2c2c", "#4a2a5a"]
	var hair := ["#17120f", "#2a1f18", "#3a2c20", "#0f0f10", "#5a4632", "#6b5a48", "#8a6a3a"]
	var seat_mesh := BoxMesh.new()
	seat_mesh.size = Vector3(0.52, 0.6, 0.12)
	var mm_seat := MultiMesh.new()
	for k in 14:
		var x := -8.6
		while x < 8.7:
			if absf(x) > 0.6 and not (k == 0 and absf(x) < 2.7):
				_seats.append([x, -8.0 + k * 1.1 + 0.55, 0.35 * (k + 1), Color(shirts[rng.randi() % shirts.size()]),
					Color(hair[rng.randi() % hair.size()]), rng.randf(), rng.randf(), rng.randf(), rng.randf()])
			x += 0.62
	var n := _seats.size()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.75
	var body := CapsuleMesh.new()
	body.radius = 0.21
	body.height = 0.78
	var head := SphereMesh.new()
	head.radius = 0.115
	head.height = 0.25
	var arm := CapsuleMesh.new()
	arm.radius = 0.045
	arm.height = 0.6
	_mm_body = _mm(root, body, mat, n, true)
	_mm_head = _mm(root, head, mat, n, true)
	_mm_arm = _mm(root, arm, mat, n * 2, true)
	mm_seat = _mm(root, seat_mesh, Kit.mat("#7a1420", 0.7), n, false)
	for i in n:
		var s: Array = _seats[i]
		_mm_body.set_instance_color(i, s[3])
		_mm_head.set_instance_color(i, s[4])
		_mm_arm.set_instance_color(i * 2, s[3])
		_mm_arm.set_instance_color(i * 2 + 1, s[3])
		mm_seat.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(s[0], s[2] + 0.55, s[1] + 0.28)))


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


func _build_ticket(root: Node3D) -> void:
	_ticket = Node3D.new()
	root.add_child(_ticket)
	Kit.box(_ticket, Vector3(0.2, 0.09, 0.002), Vector3.ZERO, Kit.mat("#f3ead2", 0.7))
	Kit.box(_ticket, Vector3(0.05, 0.09, 0.0025), Vector3(0.075, 0, 0), Kit.mat("#b0182a", 0.6))
	var l1 := Kit.text(_ticket, "AVENGERS: DOOMSDAY", 0.016, Color("#1a1a1a"), Vector3(-0.025, 0.018, 0.002), Vector3.ZERO, true)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var l2 := Kit.text(_ticket, "18 DEC   ADMIT ONE", 0.012, Color("#5a1a1a"), Vector3(-0.025, -0.016, 0.002), Vector3.ZERO, false)
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ticket.visible = false


func _build_marquee(root: Node3D) -> void:
	var m := Node3D.new()
	m.position = MARQ
	root.add_child(m)
	# Wet street and pavement, the facade, the marquee box with bulbs and two letter lines, a lightbox poster.
	Kit.box(m, Vector3(40, 0.1, 30), Vector3(0, -0.05, 8), Kit.mat("#0c0d10", 0.08, 0.0, 0.9))
	Kit.box(m, Vector3(40, 0.2, 4), Vector3(0, 0.1, 1.5), Kit.mat("#2a2a2e", 0.6))
	Kit.box(m, Vector3(22, 14, 1), Vector3(0, 7, -0.5), Kit.mat("#3a2a24", 0.85))
	Kit.box(m, Vector3(16, 3.2, 2.4), Vector3(0, 6.2, 1.0), Kit.mat("#1a1418", 0.5))
	var face := Kit.box(m, Vector3(15, 2.4, 0.05), Vector3(0, 6.2, 2.23), Kit.lit("#fff3da", 1.1))
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lines: Array = _p.get("marquee", ["AVENGERS: DOOMSDAY", "OPENS DEC 18"])
	for i in lines.size():
		var l := Kit.text(m, String(lines[i]), 0.62, Color("#151515"), Vector3(0, 6.75 - i * 0.95, 2.27), Vector3.ZERO, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_marquee_labels.append(l)
	_bulb_on = Kit.lit("#ffd27a", 5.0)
	_bulb_off = Kit.mat("#5a4a2a", 0.4)
	var bulb := SphereMesh.new()
	bulb.radius = 0.06
	bulb.height = 0.12
	for k in 120:
		var u := float(k) / 120.0
		var p := Vector3.ZERO
		var per := 2.0 * (16.0 + 3.2)
		var d := u * per
		if d < 16.0:
			p = Vector3(-8.0 + d, 7.8, 2.25)
		elif d < 19.2:
			p = Vector3(8.0, 7.8 - (d - 16.0), 2.25)
		elif d < 35.2:
			p = Vector3(8.0 - (d - 19.2), 4.6, 2.25)
		else:
			p = Vector3(-8.0, 4.6 + (d - 35.2), 2.25)
		var b := MeshInstance3D.new()
		b.mesh = bulb
		b.position = p
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.add_child(b)
		_bulbs.append(b)
	var poster := String(_p.get("poster", "AVENGERS: SECRET WARS\nDECEMBER 2027"))
	Kit.box(m, Vector3(2.0, 3.0, 0.2), Vector3(6.5, 2.2, 0.05), Kit.mat("#202024", 0.4, 0.6))
	Kit.box(m, Vector3(1.8, 2.8, 0.02), Vector3(6.5, 2.2, 0.16), Kit.lit("#1e2a5a", 1.0))
	var pl := Kit.text(m, poster, 0.2, Color("#f0e8d0"), Vector3(6.5, 2.2, 0.18), Vector3.ZERO, true, 1.2)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Kit.spot(m, Vector3(0, 4.3, 3.2), Vector3(0, 0, 5), "#ffd9a0", 30.0, 12.0, 60.0, true, 0.6)
	Kit.omni(m, Vector3(0, 6.2, 4.0), "#ffe6b8", 6.0, 14.0, false, 0.5)
	for x: float in [-12.0, 12.0]:
		Kit.rod(m, Vector3(x, 0, 4.5), Vector3(x, 5.5, 4.5), 0.08, Kit.mat("#1a1a1a", 0.5, 0.6), 8)
		Kit.ball(m, 0.25, Vector3(x, 5.6, 4.5), Kit.lit("#ffcf8a", 3.0), 12)
		Kit.omni(m, Vector3(x, 5.4, 4.5), "#ffb860", 3.0, 10.0, false, 0.4)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var show := "black"
	var text := ""
	var image := ""
	var bg := ""
	var logo_aspect := 2.514
	var since := 0.0
	for s in _p.get("screen", []):
		if t >= float(s["t"]):
			show = String(s.get("show", "black"))
			text = String(s.get("text", ""))
			image = String(s.get("image", ""))
			bg = String(s.get("bg", ""))
			logo_aspect = float(s.get("aspect", 2.514))
			since = t - float(s["t"])
	var col := Color(0.03, 0.03, 0.035)
	var spill := 0.0
	match show:
		"title":
			col = Color(0.05, 0.22, 0.1) if text.contains("DOOMSDAY") else Color(0.16, 0.12, 0.32)
			spill = 0.7
		"poster":
			# The screen glows in the poster's own colour ("bg") so it reads as a lit screen, the one-sheet centred.
			col = Color(bg) * 0.55 if bg != "" else Color(0.015, 0.015, 0.02)
			spill = 0.7
		"logo":
			# Near-black with a green breath behind the logo; the logo blooms in over 0.8 s.
			var tint := Color(bg) if bg != "" else Color(0.05, 0.16, 0.08)
			col = (tint * 0.35).lerp(tint, clampf(since / 0.8, 0.0, 1.0))
			spill = 0.55
		"white":
			col = Color(0.9, 0.92, 1.0)
			spill = 1.0
		"trailer":
			var f := 0.5 + 0.5 * sin(t * 7.0) * sin(t * 2.3)
			col = Color(0.25 + 0.5 * f, 0.3 + 0.25 * sin(t * 3.1 + 1.0), 0.6 - 0.3 * f)
			spill = 0.55 + 0.45 * f
	_screen_mat.albedo_color = col
	_title.text = text if show == "title" else ""
	# "logo": a wide title logo on black, added (its black vanishes). "poster": a film's one-sheet, opaque, screen height.
	_logo.visible = (show == "logo" or show == "poster") and image != ""
	if _logo.visible:
		if _logo_mat.albedo_texture == null or _logo_mat.get_meta("src", "") != image:
			_logo_mat.albedo_texture = Kit.texture(image)
			_logo_mat.set_meta("src", image)
		var k := Motion.out_cubic(clampf(since / 0.8, 0.0, 1.0))
		var grow := lerpf(0.92, 1.0, k) * (1.0 + 0.01 * since)
		if show == "poster":
			var tex: Texture2D = _logo_mat.albedo_texture
			var aspect := float(tex.get_width()) / float(tex.get_height())
			var h := 5.6
			_logo_mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
			_logo_mat.albedo_color = Color(1.15, 1.15, 1.15) * k
			_logo.position = SCREEN + Vector3(0, 0, 0.08)
			_logo.scale = Vector3(h * aspect / 9.6, h / (9.6 / 2.514), 1.0) * grow
		else:
			_logo_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			_logo_mat.albedo_color = Color(1.3, 1.3, 1.3) * k
			_logo.position = SCREEN + Vector3(0, 0.55, 0.08)
			_logo.scale = Vector3(1.0, 2.514 / logo_aspect, 1.0) * grow
	_date.text = text if show == "logo" else ""
	_date.modulate = Color(1.5, 1.45, 1.3) * clampf((since - 0.5) / 0.6, 0.0, 1.0)
	_title.modulate = Color(1.6, 1.5, 1.2) * clampf(since / 0.6, 0.0, 1.0)
	_spill.light_color = col.lightened(0.3)
	_spill.light_energy = 14.0 * spill
	_beam_mat.set_shader_parameter("strength", 0.06 + 0.12 * spill)
	_beam_mat.set_shader_parameter("color", col.lightened(0.5))
	# Crowd.
	var cheer := float(_p.get("cheer", 1e9))
	var hidden := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.001), Vector3(0, -5, 0))
	for i in _seats.size():
		var s: Array = _seats[i]
		var c := Motion.out_cubic(Motion.seg(t, cheer + s[5] * 0.5, cheer + s[5] * 0.5 + 0.35))
		var stand := c * (0.4 if s[6] < 0.7 else 0.0)
		var jump := absf(sin((t - cheer) * (7.0 + 3.0 * s[7]) + s[8] * 6.28)) * 0.1 * c if c > 0.0 else 0.0
		var lean := sin(t * (0.5 + s[7]) + s[8] * 6.28) * 0.03
		var base := Vector3(s[0] + lean, s[2] + 0.8 + stand + jump, s[1])
		_mm_body.set_instance_transform(i, Transform3D(Basis.IDENTITY, base))
		_mm_head.set_instance_transform(i, Transform3D(Basis.IDENTITY, base + Vector3(0, 0.55, 0)))
		if c > 0.0 and s[6] < 0.85:
			var pump := sin((t - cheer) * 8.0 + s[7] * 6.28) * 0.18
			for side in 2:
				var sg := -1.0 if side == 0 else 1.0
				var b := Basis.from_euler(Vector3(0, 0, sg * (0.35 + pump * sg) * c + sg * (1.0 - c) * 2.9))
				_mm_arm.set_instance_transform(i * 2 + side, Transform3D(b, base + Vector3(sg * 0.17, 0.28, 0) + b * Vector3(0, 0.3, 0)))
		else:
			_mm_arm.set_instance_transform(i * 2, hidden)
			_mm_arm.set_instance_transform(i * 2 + 1, hidden)
	# The ticket flutters down through the beam.
	var tt := float(_p.get("ticket", 1e9))
	var k := t - tt
	_ticket.visible = k >= 0.0 and k < 4.0
	if _ticket.visible:
		var fall := minf(k, 2.0)
		var p := Vector3(0.3 + 0.25 * sin(fall * 3.0), 6.0 - 1.0 * fall, -6.0 + 0.1 * cos(fall * 2.5))
		var hold := Motion.smooth(Motion.seg(t, tt + 1.6, tt + 2.0))
		var rot := Vector3(0.5 * sin(fall * 4.0) * (1.0 - hold), sin(fall * 2.0) * 0.7 * (1.0 - hold) + 0.2, 0.3 * cos(fall * 3.0) * (1.0 - hold))
		_ticket.transform = Transform3D(Basis.from_euler(rot), p)
	var mlines: Array = _p.get("marquee", ["AVENGERS: DOOMSDAY", "OPENS DEC 18"])
	for ms in _p.get("marquee_sets", []):
		if t >= float(ms["t"]):
			mlines = ms["lines"]
	for i in _marquee_labels.size():
		_marquee_labels[i].text = String(mlines[i]) if i < mlines.size() else ""
	# Chasing marquee bulbs.
	for i in _bulbs.size():
		_bulbs[i].material_override = _bulb_on if (i + int(t * 8.0)) % 3 != 0 else _bulb_off
	return {"screen": node.global_transform * SCREEN, "beam": node.global_transform * Vector3(0, 5.6, 0.0),
		"ticket": node.global_transform * Vector3(0.3, 4.2, -6.0), "marquee": node.global_transform * (MARQ + Vector3(0, 6.2, 2.2)),
		"front_row": node.global_transform * Vector3(0, 1.2, -7.4)}
