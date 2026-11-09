## Shared materials and primitive meshes. Everything is cached, so identical
## props share one mesh + material and the renderer can batch them.
## Placeholder geometry for now; real models will come from library/ later.
extends RefCounted

static var _mats: Dictionary = {}
static var _meshes: Dictionary = {}
static var _palette: Dictionary = {}
static var _wetness := 0.0
static var _snow := 0.0

## How strongly each surface slot reacts to rain (gets darker + glossy) and
## snow cover (turns white). Slots not listed are unaffected.
const WET_SLOTS := {"asphalt": 1.0, "sidewalk": 0.9, "driveway": 0.9, "walkway": 0.9, "lane_paint": 0.8, "roof": 0.5, "car": 0.4}
const SNOW_SLOTS := {"lawn": 1.0, "ground": 1.0, "roof": 0.9, "foliage": 0.55, "sidewalk": 0.6, "driveway": 0.6, "walkway": 0.6, "asphalt": 0.3, "fence": 0.3, "car": 0.45, "lane_paint": 0.3}
const SNOW_COLOR := Color("#e9eef5")


static func clear_cache() -> void:
	_mats.clear()
	_meshes.clear()


## Called with a compiled look before building a set: palette overrides
## (absurd colour worlds) and weather (wet roads, snow cover).
static func configure(look: Dictionary) -> void:
	_palette = look.get("palette", {})
	var s: Dictionary = look.get("surface", {})
	_wetness = float(s.get("wetness", 0.0))
	_snow = float(s.get("snow_cover", 0.0))
	clear_cache()


## The final colour for a named surface slot. A palette entry can be one
## colour (replaces all) or a list (each original colour maps to one entry,
## deterministically, so variety is kept).
static func surface_color(slot: String, hex: String) -> Color:
	var c := Color(hex)
	if _palette.has(slot):
		var v = _palette[slot]
		if typeof(v) == TYPE_ARRAY and v.size() > 0:
			c = Color(String(v[absi(hash(hex)) % v.size()]))
		elif typeof(v) == TYPE_STRING:
			c = Color(v)
	if _wetness > 0.0 and WET_SLOTS.has(slot):
		c = c.darkened(0.3 * _wetness * float(WET_SLOTS[slot]))
	if _snow > 0.0 and SNOW_SLOTS.has(slot):
		c = c.lerp(SNOW_COLOR, _snow * float(SNOW_SLOTS[slot]))
	return c


## A material for a named surface slot (see surface_color).
static func surface(slot: String, hex: String, roughness: float = 0.9, metallic: float = 0.0) -> StandardMaterial3D:
	var c := surface_color(slot, hex)
	var r := roughness
	if _wetness > 0.0 and WET_SLOTS.has(slot):
		r = lerpf(roughness, 0.12, _wetness * float(WET_SLOTS[slot]))
	if _snow > 0.0 and SNOW_SLOTS.has(slot):
		r = lerpf(r, 0.85, _snow * float(SNOW_SLOTS[slot]))
	return mat("#" + c.to_html(false), r, metallic)


static func mat(hex: String, roughness: float = 0.9, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "m|%s|%.2f|%.2f" % [hex, roughness, metallic]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = roughness
	m.metallic = metallic
	_mats[key] = m
	return m


static func glow_mat(hex: String, energy: float) -> StandardMaterial3D:
	var key := "g|%s|%.2f" % [hex, energy]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.emission_enabled = true
	m.emission = Color(hex)
	m.emission_energy_multiplier = energy
	_mats[key] = m
	return m


static func glass_mat() -> StandardMaterial3D:
	return mat("#1a222c", 0.15, 0.4)


## For MultiMesh instances that carry their own tint colour.
static func tint_mat(roughness: float = 0.9) -> StandardMaterial3D:
	var key := "t|%.2f" % roughness
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color.WHITE
	m.roughness = roughness
	_mats[key] = m
	return m


static func box(size: Vector3, m: Material) -> BoxMesh:
	var key := "box|%s|%d" % [size, m.get_instance_id()]
	if _meshes.has(key):
		return _meshes[key]
	var b := BoxMesh.new()
	b.size = size
	b.material = m
	_meshes[key] = b
	return b


static func cylinder(top_r: float, bottom_r: float, height: float, m: Material, segments: int = 10) -> CylinderMesh:
	var key := "cyl|%.3f|%.3f|%.3f|%d|%d" % [top_r, bottom_r, height, segments, m.get_instance_id()]
	if _meshes.has(key):
		return _meshes[key]
	var c := CylinderMesh.new()
	c.top_radius = top_r
	c.bottom_radius = bottom_r
	c.height = height
	c.radial_segments = segments
	c.rings = 1
	c.material = m
	_meshes[key] = c
	return c


static func sphere(radius: float, height: float, m: Material, segments: int = 12) -> SphereMesh:
	var key := "sph|%.3f|%.3f|%d|%d" % [radius, height, segments, m.get_instance_id()]
	if _meshes.has(key):
		return _meshes[key]
	var s := SphereMesh.new()
	s.radius = radius
	s.height = height
	s.radial_segments = segments
	s.rings = maxi(4, segments / 2)
	s.material = m
	_meshes[key] = s
	return s


static func prism(size: Vector3, m: Material) -> PrismMesh:
	var key := "prism|%s|%d" % [size, m.get_instance_id()]
	if _meshes.has(key):
		return _meshes[key]
	var p := PrismMesh.new()
	p.size = size
	p.material = m
	_meshes[key] = p
	return p


static func plane(size: Vector2, m: Material) -> PlaneMesh:
	var p := PlaneMesh.new()
	p.size = size
	p.material = m
	return p


static func add_mesh(parent: Node, mesh: Mesh, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		node_name: String = "", shadows: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot_deg
	if node_name != "":
		mi.name = node_name
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func add_box(parent: Node, size: Vector3, pos: Vector3, m: Material, rot_y: float = 0.0,
		node_name: String = "", shadows: bool = true) -> MeshInstance3D:
	return add_mesh(parent, box(size, m), pos, Vector3(0, rot_y, 0), node_name, shadows)
