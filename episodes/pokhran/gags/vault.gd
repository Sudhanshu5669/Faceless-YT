## The device vault, deep under the range, May 1998 (a dramatised assembly chamber: the real shaft chambers were smaller).
## A tall cylindrical concrete chamber with two steel gantry rings, a spiral stair climbing the wall, a lift cage on a
## rail, the round opening of the shaft far above letting in a cold shaft of light. Welders on the upper gantry rain
## sparks down to the floor. In front, the device stands on end on a plinth, cabled up, with a code-name sticker on its
## casing that changes with the line.
##
## Local frame: the chamber's axis at x 0, z 0; floor y 0; the device (scaled DEV_SCALE) on its plinth at DEVICE_AT on the axis, facing +z (the camera
## usually stands at +z looking -z).
##
## params:
##   stickers  [[t, "res path or repo path"], ...]   the sticker on the casing from each t
##   welders   [[x, y, z], ...]   spark sources (welding points on the upper gantries)
##   clipboards [actor ids]   each holds a clipboard in the left hand and writes on it with the right
##   crates    [actor ids]    each carries a wooden crate in both hands
##   lift      [[t, y], ...]   the lift cage's height over time (eased between keys)
## anchors: device (its mid), sticker, top (the opening)
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")
const PB := "incoming/pokhran_blender/"
const PH := "incoming/polyhaven_pokhran/models/"
const R := 7.0
const H := 16.0
const DEVICE_AT := Vector3(0.0, 0.0, 0.0)
const NSPARK := 110
const DEV_SCALE := 2.2          # the device is imposing: about 5 m tall on its plinth
const PLINTH := 0.7             # plinth height (the device stands on it)
const PLINTH_R := 1.5
# On the label plate, relative to DEVICE_AT (the model's plate sits 1.74 m up, 0.344 m out at scale 1).
const STICKER_AT := Vector3(0.0, PLINTH + 1.74 * DEV_SCALE, 0.344 * DEV_SCALE)

const CONCRETE := """
shader_type spatial;
render_mode cull_disabled;
varying vec3 wp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 c = vec3(0.3, 0.29, 0.27);
	c *= 0.8 + 0.3 * fbm(wp * 1.8);
	// Shuttering lines every 1.2 m, damp streaks running down.
	c *= 0.86 + 0.14 * smoothstep(0.0, 0.04, abs(fract(wp.y / 1.2) - 0.5) * 2.0 - 0.92 + 0.92);
	c = mix(c, c * 0.55, smoothstep(0.55, 0.8, fbm(wp * vec3(2.0, 0.25, 2.0) + 7.0)) * 0.6);
	ALBEDO = c;
	ROUGHNESS = 0.9;
	SPECULAR = 0.25;
}
"""

const SPARK := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
varying float heat;
void vertex() { heat = INSTANCE_CUSTOM.r; }
void fragment() {
	float r = abs(UV.x - 0.5) * 2.0;
	float a = (1.0 - r * r) * smoothstep(0.0, 0.3, UV.y);
	vec3 hot = mix(vec3(1.0, 0.35, 0.05), vec3(1.0, 0.92, 0.6), heat);
	ALBEDO = hot * a * (3.0 + 5.0 * heat);
}
"""

const STICKER := """
shader_type spatial;
render_mode cull_back;
uniform sampler2D img : source_color, filter_linear_mipmap;
void fragment() {
	vec4 c = texture(img, UV);
	ALBEDO = c.rgb;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.45;
	SPECULAR = 0.5;
}
"""

var _p := {}
var _sparks: MultiMeshInstance3D
var _sticker_mat: ShaderMaterial
var _stickers: Array = []
var _sticker_tex := {}
var _lift: Node3D
var _held := {}
var _spark_lights: Array = []
var _beacon: Node3D


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "vault"))
	var conc := Kit.shader(CONCRETE)
	var steel := Kit.mat("#3c3e3e", 0.45, 0.8)
	var olive := Kit.mat("#3f4632", 0.6, 0.3)
	var rail := Kit.mat("#a08a2a", 0.5, 0.4)
	# The chamber: the wall (open at the top round the shaft's mouth), the floor, the roof slab with its round opening.
	var wall := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = R
	cm.bottom_radius = R
	cm.height = H
	cm.radial_segments = 64
	cm.rings = 8
	cm.cap_top = false
	cm.cap_bottom = false
	cm.flip_faces = true
	wall.mesh = cm
	wall.material_override = conc
	wall.position = Vector3(0, H * 0.5, 0)
	root.add_child(wall)
	Kit.cyl(root, R, R, 0.2, Vector3(0, -0.1, 0), conc, 64)
	var roof := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.0
	tm.outer_radius = R
	tm.rings = 64
	tm.ring_segments = 4
	roof.mesh = tm
	roof.material_override = conc
	roof.position = Vector3(0, H, 0)
	roof.scale = Vector3(1, 0.06, 1)
	root.add_child(roof)
	# Two gantry rings round the wall at 5 m and 10 m: decking, posts, a yellow handrail.
	for gy: float in [5.0, 10.0]:
		var deck := MeshInstance3D.new()
		var dm := TorusMesh.new()
		dm.inner_radius = R - 1.4
		dm.outer_radius = R
		dm.rings = 64
		dm.ring_segments = 4
		deck.mesh = dm
		deck.material_override = Kit.mat("#2e302f", 0.5, 0.7)
		deck.position = Vector3(0, gy, 0)
		deck.scale = Vector3(1, 0.05, 1)
		root.add_child(deck)
		for k in 32:
			var a := TAU * float(k) / 32.0
			var p := Vector3(cos(a), 0, sin(a)) * (R - 1.4)
			Kit.rod(root, p + Vector3(0, gy, 0), p + Vector3(0, gy + 1.05, 0), 0.025, steel, 6)
			var a2 := TAU * float(k + 1) / 32.0
			var p2 := Vector3(cos(a2), 0, sin(a2)) * (R - 1.4)
			Kit.rod(root, p + Vector3(0, gy + 1.05, 0), p2 + Vector3(0, gy + 1.05, 0), 0.03, rail, 6)
			Kit.rod(root, p + Vector3(0, gy + 0.55, 0), p2 + Vector3(0, gy + 0.55, 0), 0.02, rail, 6)
			# Brackets under the deck into the wall.
			Kit.rod(root, p + Vector3(0, gy - 0.05, 0), Vector3(cos(a), 0, sin(a)) * R + Vector3(0, gy - 1.2, 0), 0.03, steel, 6)
	# The spiral stair: treads climbing the wall from the floor to the top gantry (two turns), a rail on the inside.
	var steps := 96
	var prev := Vector3.ZERO
	for i in steps:
		var a := -0.9 + TAU * 2.0 * float(i) / float(steps)
		var y := 0.2 + 10.0 * float(i) / float(steps)
		var c := Vector3(cos(a), 0, sin(a)) * (R - 0.7)
		var tread := Kit.box(root, Vector3(1.1, 0.06, 0.32), c + Vector3(0, y, 0), Kit.mat("#2b2d2c", 0.5, 0.7))
		tread.rotation.y = -a
		var inner := Vector3(cos(a), 0, sin(a)) * (R - 1.3) + Vector3(0, y + 1.0, 0)
		if i > 0:
			Kit.rod(root, prev, inner, 0.02, rail, 6)
		if i % 4 == 0:
			Kit.rod(root, inner - Vector3(0, 1.0, 0), inner, 0.02, steel, 6)
		prev = inner
	# The lift: a rail pair up the wall and an open steel cage on it.
	var la := 2.35
	var lc := Vector3(cos(la), 0, sin(la)) * (R - 1.1)
	for s: float in [-0.6, 0.6]:
		var off := Vector3(-sin(la), 0, cos(la)) * s
		Kit.rod(root, lc + off + Vector3(0, 0, 0), lc + off + Vector3(0, H, 0), 0.06, steel, 8)
	_lift = Node3D.new()
	_lift.position = lc
	_lift.rotation.y = -la
	root.add_child(_lift)
	Kit.box(_lift, Vector3(1.6, 0.08, 1.6), Vector3(0, 0, 0), Kit.mat("#2b2d2c", 0.5, 0.7))
	for cx: float in [-0.78, 0.78]:
		for cz: float in [-0.78, 0.78]:
			Kit.rod(_lift, Vector3(cx, 0, cz), Vector3(cx, 2.3, cz), 0.03, rail, 6)
	Kit.box(_lift, Vector3(1.6, 0.06, 1.6), Vector3(0, 2.3, 0), steel)
	Kit.ball(_lift, 0.06, Vector3(0.7, 2.2, 0.7), Kit.lit("#ff9a30", 6.0), 8)
	# Hanging industrial lamps round the chamber; work floodlights on stands aimed at the device.
	for k in 5:
		var a := TAU * float(k) / 5.0 + 0.3
		var lp := Vector3(cos(a), 0, sin(a)) * 3.8 + Vector3(0, 7.6, 0)
		var lamp := Kit.model(PH + "hanging_industrial_lamp/hanging_industrial_lamp_2k.gltf")
		lamp.position = lp
		root.add_child(lamp)
		Kit.rod(root, lp + Vector3(0, 0.4, 0), lp + Vector3(0, H - 7.6, 0), 0.008, steel, 4)
		# Dim practicals: a small warm pool under each, the chamber stays black between them.
		var sl := Kit.spot(root, lp + Vector3(0, -0.1, 0), lp + Vector3(0, -8, 0), Color(1.0, 0.7, 0.4), 0.7, 9.0, 30.0, false, 0.6)
		sl.spot_attenuation = 1.6
	# The key: one low work flood on the floor, front left, raking UP the device (hard, warm, ominous under-light).
	var stand := DEVICE_AT + Vector3(-2.9, 0, 3.0)
	Kit.rod(root, stand, stand + Vector3(0, 0.45, 0), 0.03, steel, 6)
	Kit.box(root, Vector3(0.45, 0.32, 0.22), stand + Vector3(0, 0.55, 0), Kit.mat("#202220", 0.5, 0.3))
	var key := Kit.spot(root, stand + Vector3(0.4, 0.62, -0.4), DEVICE_AT + Vector3(0, PLINTH + 1.6, 0), Color(1.0, 0.78, 0.5), 24.0, 14.0, 30.0, true, 0.5)
	key.spot_attenuation = 0.8
	# A weaker warm work lamp on the floor front right, so the crew at the plinth's foot read as people.
	var st2 := DEVICE_AT + Vector3(2.7, 0, 3.4)
	Kit.box(root, Vector3(0.4, 0.28, 0.2), st2 + Vector3(0, 0.3, 0), Kit.mat("#202220", 0.5, 0.3))
	var fill := Kit.spot(root, st2 + Vector3(-0.35, 0.4, -0.35), DEVICE_AT + Vector3(0, 0.9, 1.0), Color(1.0, 0.72, 0.42), 3.5, 9.0, 40.0, true, 0.3)
	fill.spot_attenuation = 1.2
	# The rim: a cold hard light from high behind right, outlining the casing against the black.
	var rim := Kit.spot(root, DEVICE_AT + Vector3(3.2, 8.5, -4.2), DEVICE_AT + Vector3(0, PLINTH + 2.4, 0), Color(0.6, 0.75, 1.0), 40.0, 16.0, 14.0, true, 0.4)
	rim.spot_attenuation = 0.7
	# The cold shaft of light from the opening far above, a narrow column through the haze onto the device's top.
	var shaft := Kit.spot(root, Vector3(0, H + 4.0, 0), DEVICE_AT + Vector3(0, PLINTH + 5.0, 0), Color(0.55, 0.68, 1.0), 22.0, 30.0, 5.5, true, 7.0)
	shaft.spot_attenuation = 0.6
	# A rotating red warning beacon on the lower gantry behind the device: its beam sweeps the walls.
	var bpos := Vector3(0, 6.15, -(R - 1.0))
	Kit.cyl(root, 0.13, 0.15, 0.22, bpos + Vector3(0, -0.11, 0), Kit.mat("#1a1a1a", 0.5, 0.5), 12)
	Kit.ball(root, 0.13, bpos + Vector3(0, 0.08, 0), Kit.lit("#ff1a10", 9.0), 10)
	Kit.omni(root, bpos + Vector3(0, 0.1, 0.3), Color(1.0, 0.1, 0.05), 1.4, 5.0, false, 1.0)
	_beacon = Node3D.new()
	_beacon.position = bpos + Vector3(0, 0.08, 0)
	root.add_child(_beacon)
	for d: float in [1.0, -1.0]:
		var bl := Kit.spot(_beacon, Vector3.ZERO, Vector3(d, -0.18, 0), Color(1.0, 0.08, 0.04), 30.0, 20.0, 16.0, false, 2.5)
		bl.spot_attenuation = 0.5
	# The device on its plinth: stood on end, cabled to a junction box; the sticker on its casing.
	Kit.cyl(root, PLINTH_R - 0.1, PLINTH_R, PLINTH, DEVICE_AT + Vector3(0, PLINTH * 0.5, 0), conc, 40)
	Kit.cyl(root, PLINTH_R + 0.05, PLINTH_R + 0.05, 0.06, DEVICE_AT + Vector3(0, PLINTH - 0.03, 0), Kit.mat("#a08a2a", 0.6, 0.3), 40)
	var dev := Kit.model(PB + "device.glb")
	var db := (Basis(Vector3(0, 0, 1), PI / 2) * Basis(Vector3(1, 0, 0), PI / 2)).scaled(Vector3.ONE * DEV_SCALE)
	dev.transform = Transform3D(db, DEVICE_AT + Vector3(0, PLINTH, 0) + Vector3(0.0, 1.12, -0.62) * DEV_SCALE)
	root.add_child(dev)
	for mi in dev.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for si in m.mesh.get_surface_count():
			var mt := m.mesh.surface_get_material(si)
			if mt != null and String(mt.resource_name) == "indicator":
				m.set_surface_override_material(si, Kit.lit("#3dff7a", 5.0))
	var cab := Kit.mat("#111111", 0.5)
	for k in 5:
		var a := -0.9 + 0.4 * k
		var p0 := DEVICE_AT + Vector3(sin(a) * 0.36 * DEV_SCALE, PLINTH + (0.5 + 0.12 * k) * DEV_SCALE, cos(a) * 0.36 * DEV_SCALE)
		var p1 := DEVICE_AT + Vector3(-2.3 + 0.18 * k, 0.03, -1.9)
		var mid := p0.lerp(p1, 0.5) + Vector3(0, -0.8, 0)
		Kit.rod(root, p0, mid, 0.04, cab, 6)
		Kit.rod(root, mid, p1, 0.04, cab, 6)
	Kit.box(root, Vector3(0.7, 0.9, 0.45), DEVICE_AT + Vector3(-2.4, 0.45, -2.0), olive)
	# The sticker, slapped on the label plate (which faces the camera with the device stood on end).
	_sticker_mat = Kit.shader(STICKER)
	var patch := MeshInstance3D.new()
	var sq := QuadMesh.new()
	sq.size = Vector2(0.34, 0.34) * DEV_SCALE
	patch.mesh = sq
	patch.material_override = _sticker_mat
	patch.position = DEVICE_AT + STICKER_AT
	patch.rotation.z = 0.06
	root.add_child(patch)
	for st in _p.get("stickers", []):
		var path := String(st[1])
		if not _sticker_tex.has(path):
			_sticker_tex[path] = Kit.texture(path)
		_stickers.append([float(st[0]), _sticker_tex[path]])
	# Sparks: thin hot streaks (a MultiMesh), recomputed each frame from deterministic seeds; a flicker light per welder.
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var qm := QuadMesh.new()
	qm.size = Vector2(0.028, 1.0)
	qm.center_offset = Vector3(0, -0.5, 0)
	mm.mesh = qm
	var welders: Array = _p.get("welders", [])
	mm.instance_count = NSPARK * maxi(welders.size(), 1)
	_sparks = MultiMeshInstance3D.new()
	_sparks.multimesh = mm
	_sparks.material_override = Kit.shader(SPARK)
	_sparks.extra_cull_margin = 20.0
	_sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(_sparks)
	for w in welders:
		var wp := Vector3(float(w[0]), float(w[1]), float(w[2]))
		Kit.ball(root, 0.05, wp, Kit.lit("#fff3c8", 18.0), 8)
		var ol := Kit.omni(root, wp, Color(1.0, 0.72, 0.4), 3.0, 12.0, false, 2.5)
		_spark_lights.append(ol)
	# Props held by actors.
	for aid in _p.get("clipboards", []):
		var cb := Kit.model(PH + "clipboard/clipboard_2k.gltf")
		root.add_child(cb)
		_held[String(aid)] = ["clipboard", cb]
	for aid in _p.get("crates", []):
		var cr := Kit.model(PH + "old_military_crate/old_military_crate_2k.gltf")
		cr.scale = Vector3.ONE * 0.6
		root.add_child(cr)
		_held[String(aid)] = ["crate", cr]
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	# The sticker for this moment.
	for st in _stickers:
		if t >= float(st[0]):
			_sticker_mat.set_shader_parameter("img", st[1])
	# The lift rides between its keys.
	var keys: Array = _p.get("lift", [[0.0, 0.0]])
	var ly := float((keys[0] as Array)[1])
	for i in range(1, keys.size()):
		var a: Array = keys[i - 1]
		var b: Array = keys[i]
		if t >= float(a[0]):
			ly = lerpf(float(a[1]), float(b[1]), Motion.in_out(Motion.seg(t, float(a[0]), float(b[0]))))
	_lift.position.y = ly
	# The beacon turns (about one sweep a second and a half).
	_beacon.rotation.y = t * 4.2
	# Sparks: each lives ~1.5 s, thrown out from its welder and falling under gravity, the streak along its velocity.
	var welders: Array = _p.get("welders", [])
	var mm := _sparks.multimesh
	for wi in welders.size():
		var w: Array = welders[wi]
		var wp := Vector3(float(w[0]), float(w[1]), float(w[2]))
		var burst := 0.6 + 0.4 * sin(t * 13.0 + wi * 2.1) * sin(t * 5.3 + wi)
		(_spark_lights[wi] as OmniLight3D).light_energy = 1.6 + 4.0 * maxf(burst, 0.0)
		for k in NSPARK:
			var idx := wi * NSPARK + k
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(Vector2i(wi, k))
			var life := rng.randf_range(1.2, 1.7)
			var ph := rng.randf() * life
			var age := fposmod(t + ph, life)
			var v0 := Vector3(rng.randf_range(-1.6, 1.6), rng.randf_range(-0.5, 1.4), rng.randf_range(-1.6, 1.6))
			var p := wp + v0 * age + Vector3(0, -4.9 * age * age, 0)
			var v := v0 + Vector3(0, -9.8 * age, 0)
			if p.y < 0.02:
				mm.set_instance_transform(idx, Transform3D(Basis.from_scale(Vector3.ZERO), wp))
				continue
			var spd := v.length()
			var dir := v / maxf(spd, 0.001)
			var b := Basis(Quaternion(Vector3.DOWN, dir)) if dir.dot(Vector3.DOWN) > -0.999 else Basis()
			var len := clampf(spd * 0.035, 0.04, 0.5)
			mm.set_instance_transform(idx, Transform3D(Basis(b.x, b.y * len, b.z), p))
			mm.set_instance_custom_data(idx, Color(clampf(1.0 - age / life * 1.3, 0.0, 1.0), 0, 0, 0))
	# Held props.
	if ctx.has("actor"):
		var inv := gt.affine_inverse()
		for aid in _held:
			var e: Array = _held[aid]
			var a = ctx["actor"].call(aid)
			var nd: Node3D = e[1]
			nd.visible = a != null and a.visible
			if not nd.visible:
				continue
			var ay := float(a.rotation.y)
			var fwd := Vector3(sin(ay), 0, cos(ay))
			var left := Vector3(cos(ay), 0, -sin(ay))
			var chest: Vector3 = inv * a.bone_world("spine_03")
			if String(e[0]) == "clipboard":
				Crawl.long_arms(a, 1.3)
				var board := chest + fwd * 0.3 + left * 0.06 + Vector3(0, -0.02, 0)
				nd.transform = Transform3D(Basis.looking_at(-fwd, Vector3.UP) * Basis(Vector3(1, 0, 0), -1.0), board)
				a.aim_hand("l", gt * (board + left * 0.11), 1.0)
				var scrib := Vector3(0.05 * sin(t * 9.0 + float(aid.hash() % 7)), 0.02 * sin(t * 4.0), 0.0)
				a.aim_hand("r", gt * (board + Vector3(0, 0.03, 0) - left * 0.02 + Basis.looking_at(-fwd, Vector3.UP) * scrib), 1.0)
			else:
				Crawl.long_arms(a, 1.25)
				var box := chest + fwd * 0.32 + Vector3(0, -0.14, 0)
				nd.transform = Transform3D(Basis.looking_at(-fwd, Vector3.UP).scaled(Vector3.ONE * 0.6), box + Vector3(0, -0.12, 0))
				a.aim_hand("l", gt * (box + left * 0.2), 1.0)
				a.aim_hand("r", gt * (box - left * 0.2), 1.0)
	return {"device": gt * (DEVICE_AT + Vector3(0, PLINTH + 2.5, 0)), "sticker": gt * (DEVICE_AT + STICKER_AT),
		"top": gt * Vector3(0, H, 0)}
