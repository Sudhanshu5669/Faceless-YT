## Applies a *compiled* look (see look_compiler.gd) to the scene: environment,
## sky shader, sun/moon/extra lights, ground fog, weather particles and the
## grade overlay. All nodes it creates are named "Look_*" and replaced on
## every apply, so looks can be switched live.
extends RefCounted

const Paths = preload("res://scripts/core/paths.gd")
const LookCompiler = preload("res://scripts/look/look_compiler.gd")
const SKY_SHADER = preload("res://shaders/sky.gdshader")
const GRADE_SHADER = preload("res://shaders/grade.gdshader")

const MAX_BODIES := 6
const KIND_IDS := {"sun": 0.0, "moon": 1.0, "planet": 2.0}


## Direction *towards* a body at (elevation, azimuth) degrees. Matches the
## direction a DirectionalLight with the same angles shines from.
static func sky_dir(elevation: float, azimuth: float) -> Vector3:
	var b := Basis.from_euler(Vector3(deg_to_rad(-elevation), deg_to_rad(azimuth), 0))
	return -(b * Vector3.FORWARD)


static func _c(v) -> Color:
	return Color(String(v))


static func _clear(node: Node) -> void:
	if node == null:
		return
	for c in node.get_children():
		if String(c.name).begins_with("Look_"):
			node.remove_child(c)
			c.queue_free()


static func apply(parent: Node, look: Dictionary, camera: Node3D = null) -> void:
	_clear(parent)
	_clear(camera)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var s := Sky.new()
	s.sky_material = _sky_material(look)
	env.sky = s

	var amb: Dictionary = look["ambient"]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = _c(amb["color"])
	env.ambient_light_energy = float(amb["energy"])

	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = float(look["exposure"])

	var glow: Dictionary = look["glow"]
	env.glow_enabled = bool(glow["enabled"])
	env.glow_intensity = float(glow["intensity"])
	env.glow_bloom = float(glow["bloom"])
	env.glow_hdr_threshold = float(glow["threshold"])

	env.ssao_enabled = bool(look["ssao"])
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6

	# Distance fog fades to the sky's horizon colour: no seam where the ground ends.
	var fog: Dictionary = look["fog"]
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = _c(look["sky"]["horizon"])
	env.fog_density = 1.0
	env.fog_depth_begin = float(fog["begin"])
	env.fog_depth_end = float(fog["end"])
	env.fog_depth_curve = float(fog["curve"])
	env.fog_sky_affect = 0.0
	var vol := float(fog["volumetric"])
	var ground_density := float(look["ground_fog"]["density"])
	env.volumetric_fog_enabled = vol > 0.0 or ground_density > 0.0
	env.volumetric_fog_density = vol
	env.volumetric_fog_albedo = _c(fog["color"])
	env.volumetric_fog_emission = _c(fog["emission"])
	env.volumetric_fog_length = float(fog["length"])
	env.volumetric_fog_anisotropy = float(fog["anisotropy"])
	# Fogging the sky hides the horizon seam on clear nights, but the low-res
	# fog volume makes blocky artifacts over detailed (cloudy) skies.
	env.volumetric_fog_sky_affect = 1.0 if float(look["sky"]["clouds"]) < 0.05 else 0.0

	var grade: Dictionary = look["grade"]
	env.adjustment_enabled = true
	env.adjustment_brightness = float(grade["brightness"])
	env.adjustment_contrast = float(grade["contrast"])
	env.adjustment_saturation = float(grade["saturation"])
	var gmap: Array = grade["gradient_map"]
	if gmap.size() >= 2:
		var offsets := PackedFloat32Array()
		var colors := PackedColorArray()
		for i in gmap.size():
			offsets.append(float(i) / (gmap.size() - 1))
			colors.append(_c(gmap[i]))
		var g := Gradient.new()
		g.offsets = offsets
		g.colors = colors
		var gt := GradientTexture1D.new()
		gt.gradient = g
		env.adjustment_color_correction = gt

	var we := WorldEnvironment.new()
	we.name = "Look_Environment"
	we.environment = env
	parent.add_child(we)

	_add_body_light(parent, "Look_Sun", look["sun"])
	_add_body_light(parent, "Look_Moon", look["moon"])
	var i := 0
	for l in look["lights"]:
		var dl := DirectionalLight3D.new()
		dl.name = "Look_Light%d" % i
		dl.rotation_degrees = Vector3(-float(l.get("elevation", 45.0)), float(l.get("azimuth", 0.0)), 0)
		dl.light_color = _c(l.get("color", "#ffffff"))
		dl.light_energy = float(l.get("energy", 1.0))
		dl.shadow_enabled = bool(l.get("shadows", false))
		parent.add_child(dl)
		i += 1

	_add_ground_fog(parent, look["ground_fog"])
	if camera:
		var w: Dictionary = look["weather"]
		if float(w["rain"]) > 0.0:
			camera.add_child(_rain(float(w["rain"]), float(w["wind"])))
		if float(w["snow"]) > 0.0:
			camera.add_child(_snow(float(w["snow"]), float(w["wind"])))
	_add_grade_overlay(parent, grade)


static func _add_body_light(parent: Node, node_name: String, b: Dictionary) -> void:
	var energy := float(b["energy"])
	if energy <= 0.0:
		return
	var dl := DirectionalLight3D.new()
	dl.name = node_name
	# Keep the light a little above the horizon so it never shines upward.
	dl.rotation_degrees = Vector3(-maxf(float(b["elevation"]), 2.0), float(b["azimuth"]), 0)
	dl.light_color = _c(b["color"])
	dl.light_energy = energy
	dl.shadow_enabled = bool(b["shadows"])
	dl.light_angular_distance = float(b["softness"])
	dl.directional_shadow_max_distance = 250.0
	dl.light_volumetric_fog_energy = 0.6
	parent.add_child(dl)


static func _sky_material(look: Dictionary) -> ShaderMaterial:
	var sky: Dictionary = look["sky"]
	var m := ShaderMaterial.new()
	m.shader = SKY_SHADER
	m.set_shader_parameter("top_color", _c(sky["top"]))
	m.set_shader_parameter("horizon_color", _c(sky["horizon"]))
	m.set_shader_parameter("stars", float(sky["stars"]))
	m.set_shader_parameter("star_color", _c(sky["star_color"]))
	m.set_shader_parameter("clouds", float(sky["clouds"]))
	m.set_shader_parameter("cloud_color", _c(sky["cloud_color"]))
	m.set_shader_parameter("cloud_shadow", _c(sky["cloud_shadow"]))
	m.set_shader_parameter("cloud_speed", float(sky["cloud_speed"]))

	var bodies := []
	var sun: Dictionary = look["sun"]
	if bool(sun["visible"]) and float(sun["elevation"]) > -4.0:
		var sc := _c(sun.get("disc_color", sun["color"]))
		bodies.append({"kind": "sun", "dir": sky_dir(sun["elevation"], sun["azimuth"]), "size": float(sun["size"]),
			"color": sc * 6.0, "glow_color": _c(sun.get("glow_color", sun["color"])), "glow": float(sun["glow"])})
	var moon: Dictionary = look["moon"]
	if bool(moon["visible"]) and float(moon["elevation"]) > -4.0:
		bodies.append({"kind": "moon", "dir": sky_dir(moon["elevation"], moon["azimuth"]), "size": float(moon["size"]),
			"color": _c(moon.get("disc_color", "#dfe6f2")) * 1.3, "glow_color": _c(moon.get("glow_color", moon["color"])), "glow": float(moon["glow"])})
	for b in sky["bodies"]:
		var col := _c(b.get("color", "#ffffff"))
		bodies.append({"kind": String(b.get("kind", "planet")), "dir": sky_dir(float(b.get("elevation", 30.0)), float(b.get("azimuth", 0.0))),
			"size": float(b.get("size", 6.0)), "color": col * (6.0 if b.get("kind", "planet") == "sun" else 1.0),
			"glow_color": _c(b.get("glow_color", b.get("color", "#ffffff"))), "glow": float(b.get("glow", 0.3))})

	var dirs := []
	var cols := []
	var glows := []
	for k in MAX_BODIES:
		if k < bodies.size():
			var b: Dictionary = bodies[k]
			var dv: Vector3 = b["dir"]
			var cv: Color = b["color"]
			var gv: Color = b["glow_color"]
			dirs.append(Vector4(dv.x, dv.y, dv.z, deg_to_rad(b["size"])))
			cols.append(Vector4(cv.r, cv.g, cv.b, KIND_IDS.get(b["kind"], 2.0)))
			glows.append(Vector4(gv.r, gv.g, gv.b, b["glow"]))
		else:
			dirs.append(Vector4(0, 1, 0, 0))
			cols.append(Vector4())
			glows.append(Vector4())
	m.set_shader_parameter("body_count", mini(bodies.size(), MAX_BODIES))
	m.set_shader_parameter("body_dir", dirs)
	m.set_shader_parameter("body_color", cols)
	m.set_shader_parameter("body_glow", glows)
	return m


static func _add_ground_fog(parent: Node, gf: Dictionary) -> void:
	if float(gf["density"]) <= 0.0:
		return
	var fm := FogMaterial.new()
	fm.density = float(gf["density"])
	fm.albedo = _c(gf["color"])
	fm.emission = _c(gf["emission"])
	fm.height_falloff = float(gf["falloff"])
	fm.edge_fade = 0.2
	var fv := FogVolume.new()
	fv.name = "Look_GroundFog"
	var h := float(gf["height"])
	fv.size = Vector3(900, h, 900)
	fv.position = Vector3(0, h / 2.0 - 0.5, 0)
	fv.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	fv.material = fm
	parent.add_child(fv)


static func _particles(node_name: String, amount: int, lifetime: float, mesh: Mesh, pm: ParticleProcessMaterial) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = node_name
	p.amount = amount
	p.lifetime = lifetime
	p.preprocess = lifetime
	p.local_coords = false
	p.draw_pass_1 = mesh
	p.process_material = pm
	p.visibility_aabb = AABB(Vector3(-40, -40, -40), Vector3(80, 80, 80))
	if "use_fixed_seed" in p:
		p.set("use_fixed_seed", true)
		p.set("seed", 1234)
	return p


static func _rain(amount: float, wind: float) -> GPUParticles3D:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(22, 8, 22)
	pm.direction = Vector3(wind * 0.4, -1, 0).normalized()
	pm.spread = 2.0
	pm.initial_velocity_min = 22.0
	pm.initial_velocity_max = 27.0
	pm.gravity = Vector3.ZERO
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.78, 0.82, 0.92, 0.32)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	var q := QuadMesh.new()
	q.size = Vector2(0.025, 0.75)
	q.material = mat
	var p := _particles("Look_Rain", int(5000 * amount), 1.3, q, pm)
	p.position = Vector3(0, 12, -6)
	return p


static func _snow(amount: float, wind: float) -> GPUParticles3D:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(26, 10, 26)
	pm.direction = Vector3(wind, -1, 0).normalized()
	pm.spread = 15.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 2.0
	pm.gravity = Vector3(wind * 0.8, -0.4, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_influence_min = 0.05
	pm.turbulence_influence_max = 0.15
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.95, 0.97, 1.0)
	var s := SphereMesh.new()
	s.radius = 0.035
	s.height = 0.07
	s.radial_segments = 6
	s.rings = 3
	s.material = mat
	var p := _particles("Look_Snow", int(4000 * amount), 9.0, s, pm)
	p.position = Vector3(0, 9, -6)
	return p


static func _add_grade_overlay(parent: Node, grade: Dictionary) -> void:
	var vig := float(grade["vignette"])
	var grain := float(grade["grain"])
	# Always present: besides vignette and grain it draws the iris transitions.
	var layer := CanvasLayer.new()
	layer.name = "Look_Grade"
	layer.layer = 5
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = GRADE_SHADER
	m.set_shader_parameter("vignette", vig)
	m.set_shader_parameter("grain", grain)
	rect.material = m
	layer.add_child(rect)
	parent.add_child(layer)
