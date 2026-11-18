## Shared building blocks for gag scripts (episodes/<id>/gags/*.gd): materials (incl. noise
## shaders with //NOISE injected), primitives placed by points, rounded slabs, text, images and
## glTF models loaded at runtime from repo-relative paths, and lights. Everything is cached, so
## hundreds of calls stay cheap. Preload it: const Kit = preload("res://scripts/world/gag_kit.gd").
extends RefCounted

const Paths = preload("res://scripts/core/paths.gd")

## Value noise + fbm in 3D (GLSL), injected into shader code at "//NOISE".
const NOISE_GLSL := """
float h3(vec3 p) { p = fract(p * vec3(0.1031, 0.1030, 0.0973)); p += dot(p, p.yxz + 33.33); return fract((p.x + p.y) * p.z); }
float n3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
float fbm(vec3 p) { return n3(p) * 0.5 + n3(p * 2.03 + 7.0) * 0.25 + n3(p * 4.1 + 3.0) * 0.15 + n3(p * 8.3 + 1.0) * 0.1; }
"""

static var _shaders := {}
static var _mats := {}
static var _meshes := {}
static var _textures := {}
static var _scenes := {}


# --- materials ------------------------------------------------------------------

static func shader(code: String) -> ShaderMaterial:
	if not _shaders.has(code):
		var s := Shader.new()
		s.code = code.replace("//NOISE", NOISE_GLSL)
		_shaders[code] = s
	var m := ShaderMaterial.new()
	m.shader = _shaders[code]
	return m


## A plain PBR material (cached by its values).
static func mat(color, rough: float = 0.8, metal: float = 0.0, spec: float = 0.5) -> StandardMaterial3D:
	var c: Color = color if color is Color else Color(String(color))
	var key := "m|%s|%.3f|%.3f|%.3f" % [c.to_html(), rough, metal, spec]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rough
		m.metallic = metal
		m.metallic_specular = spec
		if c.a < 0.999:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mats[key] = m
	return _mats[key]


## Emissive (a lamp, a screen, an LED).
static func lit(color, energy: float = 2.0) -> StandardMaterial3D:
	var c: Color = color if color is Color else Color(String(color))
	var key := "l|%s|%.3f" % [c.to_html(), energy]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = energy
		m.roughness = 0.4
		_mats[key] = m
	return _mats[key]


## Unshaded colour (UI cards, glow sprites).
static func flat(color, additive: bool = false) -> StandardMaterial3D:
	var c: Color = color if color is Color else Color(String(color))
	var key := "f|%s|%s" % [c.to_html(), additive]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = c
		if c.a < 0.999 or additive:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		if additive:
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			m.no_depth_test = false
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mats[key] = m
	return _mats[key]


## A textured PBR material from repo-relative image paths (albedo, optional normal, roughness).
static func textured(albedo: String, normal: String = "", rough_tex: String = "", uv_scale: Vector3 = Vector3.ONE,
		tint: Color = Color.WHITE, triplanar: bool = false) -> StandardMaterial3D:
	var key := "t|%s|%s|%s|%s|%s|%s" % [albedo, normal, rough_tex, uv_scale, tint.to_html(), triplanar]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_texture = texture(albedo)
		m.albedo_color = tint
		if normal != "":
			m.normal_enabled = true
			m.normal_texture = texture(normal, true)
		if rough_tex != "":
			m.roughness_texture = texture(rough_tex, true)
			m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		m.uv1_scale = uv_scale
		m.uv1_triplanar = triplanar
		m.uv1_world_triplanar = triplanar
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		_mats[key] = m
	return _mats[key]


# --- textures and models ----------------------------------------------------------

## An image from a repo-relative path (png/jpg/webp/svg), mipmapped, cached. `svg_scale` rasterises SVGs.
static func texture(rel: String, linear: bool = false, svg_scale: float = 4.0) -> Texture2D:
	var key := "%s|%s|%.2f" % [rel, linear, svg_scale]
	if _textures.has(key):
		return _textures[key]
	var path := Paths.repo_path(rel)
	var img := Image.new()
	var err := OK
	if rel.to_lower().ends_with(".svg"):
		err = img.load_svg_from_string(FileAccess.get_file_as_string(path), svg_scale)
	else:
		err = img.load(path)
	if err != OK:
		push_error("gag_kit: cannot load image " + path)
		_textures[key] = null
		return null
	if img.get_format() != Image.FORMAT_RGBA8 and img.detect_alpha() != Image.ALPHA_NONE:
		img.convert(Image.FORMAT_RGBA8)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_textures[key] = tex
	return tex


## A glTF/GLB model (repo-relative) as a new node tree. Cached as a PackedScene.
static func model(rel: String) -> Node3D:
	if not _scenes.has(rel):
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var err := doc.append_from_file(Paths.repo_path(rel), state)
		if err != OK:
			push_error("gag_kit: cannot load model " + rel)
			_scenes[rel] = null
		else:
			var root := doc.generate_scene(state)
			var ps := PackedScene.new()
			_own(root, root)
			ps.pack(root)
			root.free()
			_scenes[rel] = ps
	var ps2: PackedScene = _scenes[rel]
	return ps2.instantiate() if ps2 else Node3D.new()


static func _own(n: Node, owner: Node) -> void:
	for c in n.get_children():
		c.owner = owner
		_own(c, owner)


## Axis-aligned bounds of every mesh under `n`, in n's parent space.
static func bounds(n: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var xf := _rel_xf(m, n)
		var a := xf * m.mesh.get_aabb()
		out = a if first else out.merge(a)
		first = false
	return out


static func _rel_xf(node: Node3D, top: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = node
	while cur != null and cur != top.get_parent():
		if cur is Node3D:
			t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t


# --- primitives ---------------------------------------------------------------------

static func box(parent: Node3D, size: Vector3, pos: Vector3, m: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var key := "box|%s" % size
	if not _meshes.has(key):
		var bm := BoxMesh.new()
		bm.size = size
		_meshes[key] = bm
	var mi := MeshInstance3D.new()
	mi.mesh = _meshes[key]
	mi.material_override = m
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


## A cylinder between two points.
static func rod(parent: Node3D, a: Vector3, b: Vector3, r: float, m: Material, sides: int = 10, r2: float = -1.0) -> MeshInstance3D:
	var key := "cyl|%.4f|%.4f|%d" % [r, r2, sides]
	if not _meshes.has(key):
		var cm := CylinderMesh.new()
		cm.top_radius = r
		cm.bottom_radius = r if r2 < 0.0 else r2
		cm.height = 1.0
		cm.radial_segments = sides
		cm.rings = 1
		_meshes[key] = cm
	var mi := MeshInstance3D.new()
	mi.mesh = _meshes[key]
	mi.material_override = m
	var d := b - a
	var y := d.normalized() if d.length() > 1e-6 else Vector3.UP
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	var z := x.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y * maxf(d.length(), 1e-4), z), (a + b) * 0.5)
	parent.add_child(mi)
	return mi


static func cyl(parent: Node3D, r_top: float, r_bot: float, h: float, pos: Vector3, m: Material, sides: int = 24, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var key := "c|%.4f|%.4f|%.4f|%d" % [r_top, r_bot, h, sides]
	if not _meshes.has(key):
		var cm := CylinderMesh.new()
		cm.top_radius = r_top
		cm.bottom_radius = r_bot
		cm.height = h
		cm.radial_segments = sides
		cm.rings = 1
		_meshes[key] = cm
	var mi := MeshInstance3D.new()
	mi.mesh = _meshes[key]
	mi.material_override = m
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func ball(parent: Node3D, r: float, pos: Vector3, m: Material, seg: int = 24, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var key := "s|%.4f|%d" % [r, seg]
	if not _meshes.has(key):
		var sm := SphereMesh.new()
		sm.radius = r
		sm.height = r * 2.0
		sm.radial_segments = seg
		sm.rings = maxi(seg / 2, 4)
		_meshes[key] = sm
	var mi := MeshInstance3D.new()
	mi.mesh = _meshes[key]
	mi.material_override = m
	mi.position = pos
	mi.scale = scale
	parent.add_child(mi)
	return mi


## A flat quad facing +Z (signs, screens, posters), optional texture.
static func quad(parent: Node3D, size: Vector2, pos: Vector3, m: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var key := "q|%s" % size
	if not _meshes.has(key):
		var qm := QuadMesh.new()
		qm.size = size
		_meshes[key] = qm
	var mi := MeshInstance3D.new()
	mi.mesh = _meshes[key]
	mi.material_override = m
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


## A box with rounded vertical edges (a superellipse prism): cabinets, bodies, panels.
static func slab(parent: Node3D, size: Vector3, radius: float, pos: Vector3, m: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var key := "slab|%s|%.3f" % [size, radius]
	if not _meshes.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var r := minf(radius, minf(size.x, size.z) * 0.49)
		var pts := []
		var hx := size.x * 0.5 - r
		var hz := size.z * 0.5 - r
		var corners := [Vector2(hx, hz), Vector2(-hx, hz), Vector2(-hx, -hz), Vector2(hx, -hz)]
		for ci in 4:
			for k in 5:
				var a := (float(ci) + float(k) / 4.0) * PI * 0.5
				pts.append((corners[ci] as Vector2) + Vector2(cos(a), sin(a)) * r)
		var h := size.y * 0.5
		var n := pts.size()
		for i in n:
			var p0: Vector2 = pts[i]
			var p1: Vector2 = pts[(i + 1) % n]
			var a0 := Vector3(p0.x, -h, p0.y)
			var a1 := Vector3(p1.x, -h, p1.y)
			var b0 := Vector3(p0.x, h, p0.y)
			var b1 := Vector3(p1.x, h, p1.y)
			for v in [a0, b1, b0, a0, a1, b1]:
				st.add_vertex(v)
			for v in [Vector3(0, h, 0), b0, b1]:
				st.add_vertex(v)
			for v in [Vector3(0, -h, 0), a1, a0]:
				st.add_vertex(v)
		st.generate_normals()
		_meshes[key] = st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = _meshes[key]
	mi.material_override = m
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


## 3D text (Label3D), shaded so it sits in the scene's light unless `glow` > 0.
static func text(parent: Node3D, s: String, height: float, color, pos: Vector3, rot: Vector3 = Vector3.ZERO,
		bold: bool = true, glow: float = 0.0, outline: Color = Color(0, 0, 0, 0), font_name: String = "") -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.pixel_size = height / 64.0
	l.font_size = 64
	l.outline_size = 0 if outline.a <= 0.0 else 10
	l.outline_modulate = outline
	l.modulate = color if color is Color else Color(String(color))
	l.position = pos
	l.rotation = rot
	l.shaded = glow <= 0.0
	l.double_sided = false
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	l.font = font(font_name if font_name != "" else ("display" if bold else "body"))
	if glow > 0.0:
		l.modulate = l.modulate * glow
	parent.add_child(l)
	return l


static var _fonts := {}


## A font by name: "display" (Lilita One, chunky), "body" (Baloo 2), or a repo-relative .ttf/.otf path.
static func font(name: String) -> FontFile:
	if _fonts.has(name):
		return _fonts[name]
	var path := ""
	match name:
		"display":
			path = ProjectSettings.globalize_path("res://fonts/lilita_one/LilitaOne-Regular.ttf")
		"body":
			path = ProjectSettings.globalize_path("res://fonts/baloo2/Baloo2.ttf")
		_:
			path = Paths.repo_path(name)
	var f := FontFile.new()
	if f.load_dynamic_font(path) != OK:
		push_error("gag_kit: cannot load font " + path)
	if name == "display":
		# Lilita One has no ₹ or Devanagari: fall back to Baloo 2.
		f.fallbacks = [font("body")]
	_fonts[name] = f
	return f


# --- lights -------------------------------------------------------------------------

static func spot(parent: Node3D, pos: Vector3, target: Vector3, color, energy: float, rng: float, angle: float,
		shadows: bool = true, fog: float = 1.0) -> SpotLight3D:
	var l := SpotLight3D.new()
	l.light_color = color if color is Color else Color(String(color))
	l.light_energy = energy
	l.spot_range = rng
	l.spot_angle = angle
	l.spot_attenuation = 1.0
	l.shadow_enabled = shadows
	l.light_volumetric_fog_energy = fog
	parent.add_child(l)
	l.position = pos
	if not pos.is_equal_approx(target):
		var up := Vector3.UP if absf((target - pos).normalized().dot(Vector3.UP)) < 0.98 else Vector3.FORWARD
		l.look_at_from_position(pos, target, up)
	return l


static func omni(parent: Node3D, pos: Vector3, color, energy: float, rng: float, shadows: bool = false, fog: float = 1.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = color if color is Color else Color(String(color))
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.2
	l.shadow_enabled = shadows
	l.light_volumetric_fog_energy = fog
	l.position = pos
	parent.add_child(l)
	return l


# --- deterministic randomness -------------------------------------------------------

static func rng(id: String, salt: int = 0) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash(id) + salt * 7919
	return r
