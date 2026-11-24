## Chapter 3's escalation, in six areas of one gag (all local to the gag):
##   SKY (0, 0, 0)        a storm above the clouds: towering cloud banks, lightning, the silver board under Doom's feet
##   VOID (0, 0, 600)     deep space; the Beyonder's power, a white-gold star, drawn into Doom's open hand; then a tiny
##                        universe swirling in his palm
##   WORLD (0, 0, 1200)   Battleworld: twelve mismatched world-patches (desert, ice, jungle, ocean, lava, cities) that
##                        fly together and stitch into one planet, seams glowing
##   GOD (0, 0, 1800)     a golden world tree above the clouds, a throne at its crown
##   EARTH (0, 0, 5000)   the real Earth (Solar System Scope maps, CC BY 4.0) with the night side's cities turning
##                        green and Doom's banners rising across it
##   PAD (0, 0, 7000)     a retro rocket on its pad at dawn whose long shadow is Doom's mask
##
## params:
##   board     {"actor": id}   a silver board rides under the actor's feet, crackling
##   lightning [t, ...]   flashes in the SKY
##   beyonder  {"actor": id, "t": t}   the star crosses the void into the actor's right hand by t + 1.2, then shrinks
##             into a palm-sized universe
##   stitch    t   Battleworld's patches converge (2.5 s), seams glow
##   stretch   {"t": t}   Reed's stretching arm reaches in from off-frame toward the throne (GOD), glowing white
##   cloak     {"actor": id, "t": t}   a red cloak and a gold amulet drop onto the actor's shoulders (EARTH)
##   green     t   Earth's city lights turn green, banners rise across the globe
## anchors: board, star, palm, planet, throne, earth, rocket
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Paths = preload("res://scripts/core/paths.gd")

const SKY := Vector3(0, 0, 0)
const VOID := Vector3(0, 0, 600)
const WORLD := Vector3(0, 0, 1200)
const GOD := Vector3(0, 0, 1800)
const EARTH := Vector3(0, 0, 5000)
const PAD := Vector3(0, 0, 7000)
const PLANET_R := 30.0
const EARTH_R := 40.0

const EARTH_SHADER := """
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;
uniform sampler2D day : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D night : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 sun_dir = vec3(1.0, 0.2, 0.3);
uniform vec3 city = vec3(1.0, 0.78, 0.45);
uniform float night_gain = 2.6;
uniform float spin = 0.0;
varying vec3 wn;
varying vec3 on;
void vertex() {
	on = normalize(VERTEX);
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	float lo = atan(on.x, on.z);
	float la = asin(clamp(on.y, -1.0, 1.0));
	vec2 uv = vec2(fract(0.5 + lo / 6.2831853 + spin), 0.5 - la / 3.14159265);
	vec3 c = texture(day, uv).rgb;
	ALBEDO = c;
	ROUGHNESS = 0.7;
	float lit = dot(normalize(wn), normalize(sun_dir));
	float dark = 1.0 - smoothstep(-0.12, 0.08, lit);
	vec3 nl = texture(night, uv).rgb;
	EMISSION = nl * nl * city * night_gain * dark * 3.0 + c * vec3(0.5, 0.6, 0.9) * 0.035 * dark;
}
"""

var _p := {}
var _board: Node3D
var _arcs: MeshInstance3D
var _flash: OmniLight3D
var _star: Node3D
var _star_light: OmniLight3D
var _palm: Node3D
var _streams: MultiMesh
var _patches: Array[MeshInstance3D] = []
var _patch_dirs: Array[Vector3] = []
var _seams: Array[MeshInstance3D] = []
var _seam_mat: StandardMaterial3D
var _arm: MeshInstance3D
var _arm_light: OmniLight3D
var _earth: MeshInstance3D
var _earth_mat: ShaderMaterial
var _banners: Array[Node3D] = []
var _banner_dirs: Array[Vector3] = []
var _cloak: Node3D


## A patch of a sphere (unit radius) between longitudes a0..a1 and latitudes b0..b1.
static func _patch(a0: float, a1: float, b0: float, b1: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 10
	var pt := func(i: int, j: int) -> Vector3:
		var a := lerpf(a0, a1, float(i) / n)
		var b := lerpf(b0, b1, float(j) / n)
		return Vector3(cos(b) * sin(a), sin(b), cos(b) * cos(a))
	for i in n:
		for j in n:
			var q := [pt.call(i, j), pt.call(i + 1, j), pt.call(i + 1, j + 1), pt.call(i, j + 1)]
			for k in [0, 2, 1, 0, 3, 2]:
				st.set_normal(q[k])
				st.set_uv(Vector2(float(i) / n, float(j) / n))
				st.add_vertex(q[k])
	return st.commit()


static var _suit: GDScript


func _suit_mask() -> Mesh:
	if _suit == null:
		_suit = GDScript.new()
		_suit.source_code = FileAccess.get_file_as_string(Paths.repo_path("library/gags/doom_suit.gd"))
		_suit.reload()
	return _suit.call("_mask", 1.0)


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "cosmos"))
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	# SKY: cloud banks (flattened puffs), the board, arcs, a lightning light.
	var cloud := Kit.mat("#a8b0c4", 0.95)
	var rng := Kit.rng("cosmos")
	for i in 60:
		var c := MeshInstance3D.new()
		c.mesh = sphere
		c.material_override = cloud
		var r := rng.randf_range(8.0, 22.0)
		c.scale = Vector3(r * 1.6, r * 0.6, r)
		c.position = SKY + Vector3(rng.randf_range(-120, 120), rng.randf_range(-30, -12), rng.randf_range(-160, 40))
		root.add_child(c)
	for i in 14:
		var c := MeshInstance3D.new()
		c.mesh = sphere
		c.material_override = Kit.mat("#4a5060", 0.95)
		var r := rng.randf_range(20.0, 40.0)
		c.scale = Vector3(r, r * 2.2, r)
		c.position = SKY + Vector3(rng.randf_range(-200, 200), rng.randf_range(10, 60), rng.randf_range(-260, -120))
		root.add_child(c)
	_board = Node3D.new()
	root.add_child(_board)
	var silver := Kit.mat("#d8dde2", 0.12, 1.0)
	Kit.slab(_board, Vector3(0.7, 0.06, 1.9), 0.33, Vector3.ZERO, silver)
	Kit.slab(_board, Vector3(0.5, 0.065, 1.5), 0.24, Vector3(0, 0.003, 0), Kit.lit("#cfe8ff", 1.2))
	_arcs = MeshInstance3D.new()
	_arcs.mesh = ImmediateMesh.new()
	_arcs.material_override = Kit.lit("#bfe0ff", 6.0)
	_arcs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(_arcs)
	_flash = Kit.omni(root, SKY + Vector3(-30, 60, -40), "#d8e4ff", 0.0, 260.0, false, 0.0)
	Kit.spot(root, SKY + Vector3(40, 40, 30), SKY + Vector3(0, 5, 0), "#ffd9a8", 30.0, 120.0, 25.0, true, 0.2)
	# VOID: star dust, the star, the palm universe, the streams.
	for i in 300:
		var b := Kit.ball(root, rng.randf_range(0.05, 0.25), VOID + Vector3(rng.randf_range(-150, 150), rng.randf_range(-90, 90), rng.randf_range(-250, -40)),
			Kit.lit(["#ffffff", "#9fc8ff", "#ffd9a0"][i % 3], 3.0), 6)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_star = Node3D.new()
	root.add_child(_star)
	var core := Kit.ball(_star, 1.0, Vector3.ZERO, Kit.lit("#fff6d8", 8.0), 32)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in 3:
		var halo := MeshInstance3D.new()
		halo.mesh = sphere
		var hm := Kit.lit(["#ffd27a", "#ffb04a", "#ff8a2a"][k], 1.2 - 0.35 * k).duplicate()
		hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		hm.albedo_color.a = 0.25 - 0.06 * k
		halo.material_override = hm
		halo.scale = Vector3.ONE * (1.6 + 0.8 * k)
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_star.add_child(halo)
	_star_light = Kit.omni(root, VOID, "#ffe0a0", 20.0, 40.0, false, 0.5)
	Kit.spot(root, VOID + Vector3(3, 4, 5), VOID + Vector3(0, 1.0, 0), "#b8c8ff", 6.0, 12.0, 30.0, true, 0.0)
	Kit.spot(root, EARTH + Vector3(3, 0, 58), EARTH + Vector3(0, -4.2, 52), "#d8e0ff", 8.0, 12.0, 30.0, true, 0.0)
	_palm = Node3D.new()
	root.add_child(_palm)
	var pcore := Kit.ball(_palm, 0.09, Vector3.ZERO, Kit.lit("#cfd8ff", 4.0), 24)
	pcore.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in 40:
		var a := k * 2.39996
		var r := 0.04 + 0.05 * sqrt(float(k) / 40.0)
		var d := Kit.ball(_palm, 0.006, Vector3(cos(a) * r, 0.01 * sin(k), sin(a) * r), Kit.lit(["#ffffff", "#ffcf8a", "#8fc8ff"][k % 3], 6.0), 4)
		d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Kit.omni(_palm, Vector3(0, 0.1, 0), "#bfd0ff", 1.5, 2.0, false, 0.3)
	var sm := SphereMesh.new()
	sm.radius = 0.04
	sm.height = 0.08
	_streams = MultiMesh.new()
	_streams.transform_format = MultiMesh.TRANSFORM_3D
	_streams.mesh = sm
	_streams.instance_count = 200
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = _streams
	smi.material_override = Kit.lit("#ffe6a8", 5.0)
	smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(smi)
	# WORLD: Battleworld's patches.
	var looks := [["#c8a060", 0.0], ["#e8f0ff", 0.0], ["#2a6a2a", 0.0], ["#1a3a6a", 0.0], ["#5a1a0a", 1.5], ["#2a2a34", 0.6],
		["#8a7a5a", 0.0], ["#3a5a2a", 0.0], ["#d8d0c0", 0.0], ["#4a2a5a", 0.4], ["#a05030", 0.0], ["#203048", 0.8]]
	var idx := 0
	for la in 3:
		for lo in 4:
			var a0 := -PI + lo * PI / 2.0
			var b0 := -PI / 2.0 + la * PI / 3.0
			var mi := MeshInstance3D.new()
			mi.mesh = _patch(a0 + 0.02, a0 + PI / 2.0 - 0.02, b0 + 0.02, b0 + PI / 3.0 - 0.02)
			var lk: Array = looks[idx % looks.size()]
			var mat := Kit.mat(String(lk[0]), 0.85).duplicate()
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			if float(lk[1]) > 0.0:
				mat.emission_enabled = true
				mat.emission = Color(String(lk[0])).lightened(0.4)
				mat.emission_energy_multiplier = float(lk[1])
			mi.material_override = mat
			mi.scale = Vector3.ONE * PLANET_R
			root.add_child(mi)
			_patches.append(mi)
			var am := a0 + PI / 4.0
			var bm := b0 + PI / 6.0
			_patch_dirs.append(Vector3(cos(bm) * sin(am), sin(bm), cos(bm) * cos(am)))
			idx += 1
	_seam_mat = Kit.lit("#7dffb0", 0.0)
	var seam := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = PLANET_R * 0.985
	sp.height = PLANET_R * 1.97
	seam.mesh = sp
	seam.material_override = _seam_mat
	seam.position = WORLD
	root.add_child(seam)
	_seams.append(seam)

	# GOD: the world tree, the throne, clouds below, a golden light; Reed's stretching arm.
	var gold := Kit.mat("#d8aa3a", 0.3, 0.9)
	var bark := Kit.mat("#6a5030", 0.8)
	Kit.cyl(root, 4.0, 9.0, 60.0, GOD + Vector3(0, -32, -6), bark, 16)
	for k in 9:
		var a := k * TAU / 9.0
		Kit.rod(root, GOD + Vector3(0, -6 - (k % 3) * 6, -6), GOD + Vector3(cos(a) * 26, 4 + (k % 3) * 3, -6 + sin(a) * 26), 1.6 - 0.3 * (k % 3), bark, 8, 0.4)
		Kit.ball(root, 6.0, GOD + Vector3(cos(a) * 26, 6 + (k % 3) * 3, -6 + sin(a) * 26), Kit.mat("#c8a040", 0.5, 0.6), 12, Vector3(1, 0.5, 1))
	Kit.cyl(root, 5.0, 5.5, 1.0, GOD + Vector3(0, -0.5, -6), gold, 24)
	var th := Node3D.new()
	th.position = GOD + Vector3(0, 0, -6)
	root.add_child(th)
	Kit.box(th, Vector3(1.6, 0.55, 1.3), Vector3(0, 0.27, 0), gold)
	Kit.box(th, Vector3(1.9, 5.5, 0.3), Vector3(0, 2.7, -0.6), gold)
	Kit.cyl(th, 0.0, 1.3, 2.0, Vector3(0, 6.4, -0.6), gold, 16)
	for i in 30:
		var c := MeshInstance3D.new()
		c.mesh = sphere
		c.material_override = Kit.mat("#f2ead8", 0.95)
		var r := rng.randf_range(10.0, 26.0)
		c.scale = Vector3(r * 1.6, r * 0.5, r)
		c.position = GOD + Vector3(rng.randf_range(-140, 140), rng.randf_range(-48, -34), rng.randf_range(-160, 60))
		root.add_child(c)
	Kit.omni(root, WORLD + Vector3(45, 30, 70), "#fff2dc", 40.0, 160.0, false, 0.0)
	Kit.spot(root, GOD + Vector3(30, 60, 50), GOD + Vector3(0, 1, -6), "#ffe2a8", 120.0, 120.0, 20.0, true, 0.4)
	_arm = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.09
	cm.bottom_radius = 0.09
	cm.height = 1.0
	_arm.mesh = cm
	_arm.material_override = Kit.mat("#2a4a9a", 0.6)
	root.add_child(_arm)
	_arm_light = Kit.omni(root, GOD, "#ffffff", 0.0, 10.0, false, 0.6)
	# EARTH: the globe; banners.
	_earth_mat = Kit.shader(EARTH_SHADER)
	_earth_mat.set_shader_parameter("day", Kit.texture("incoming/sss_textures/8k_earth_daymap.jpg"))
	_earth_mat.set_shader_parameter("night", Kit.texture("incoming/sss_textures/8k_earth_nightmap.jpg"))
	_earth = MeshInstance3D.new()
	var es := SphereMesh.new()
	es.radius = EARTH_R
	es.height = EARTH_R * 2.0
	es.radial_segments = 96
	es.rings = 48
	_earth.mesh = es
	_earth.material_override = _earth_mat
	_earth.position = EARTH
	root.add_child(_earth)
	
	for i in 24:
		var b := Node3D.new()
		root.add_child(b)
		Kit.rod(b, Vector3.ZERO, Vector3(0, 2.4, 0), 0.06, Kit.mat("#2a2c2e", 0.4, 0.8), 6)
		Kit.box(b, Vector3(0.05, 1.4, 1.0), Vector3(0, 1.7, 0.5), Kit.mat("#1f5229", 0.8))
		var a := rng.randf_range(-0.9, 0.9)
		var la := rng.randf_range(-0.7, 0.9)
		_banner_dirs.append(Vector3(cos(la) * sin(a), sin(la), cos(la) * cos(a)))
		b.visible = false
		_banners.append(b)
	# The red cloak and the gold amulet for `cloak`.
	_cloak = Node3D.new()
	root.add_child(_cloak)
	var red := Kit.mat("#a3141c", 0.75)
	red = red.duplicate()
	red.cull_mode = BaseMaterial3D.CULL_DISABLED
	Kit.box(_cloak, Vector3(0.9, 1.4, 0.04), Vector3(0, -0.65, -0.18), red, Vector3(0.12, 0, 0))
	Kit.box(_cloak, Vector3(1.0, 0.35, 0.5), Vector3(0, 0.05, 0.0), red)
	Kit.cyl(_cloak, 0.08, 0.08, 0.03, Vector3(0, -0.05, 0.27), Kit.lit("#ffd24a", 3.0), 16, Vector3(PI / 2, 0, 0))
	_cloak.visible = false
	# PAD: the rocket, its gantry, dawn; a hidden mask shape high on the rocket throws the shadow.
	var pad := Node3D.new()
	pad.position = PAD
	root.add_child(pad)
	Kit.box(pad, Vector3(400, 1, 400), Vector3(0, -0.5, 0), Kit.mat("#b8a890", 0.95))
	Kit.cyl(pad, 8.0, 9.0, 1.5, Vector3(0, 0.75, 0), Kit.mat("#8a8a88", 0.8), 24)
	var hull := Kit.mat("#e8e2d4", 0.4, 0.3)
	var blue := Kit.mat("#2a5ab0", 0.4, 0.3)
	Kit.cyl(pad, 2.2, 2.4, 22.0, Vector3(0, 13.5, 0), hull, 32)
	Kit.cyl(pad, 2.25, 2.25, 1.5, Vector3(0, 9.0, 0), blue, 32)
	Kit.cyl(pad, 0.0, 2.2, 9.0, Vector3(0, 29.0, 0), hull, 32)
	for k in 4:
		var a := k * PI / 2.0
		Kit.box(pad, Vector3(0.25, 6.0, 3.5), Vector3(cos(a) * 3.0, 5.0, sin(a) * 3.0), blue, Vector3(0, -a, 0))
	for k in 10:
		Kit.rod(pad, Vector3(6.0, k * 3.0, -1.5), Vector3(6.0, k * 3.0 + 3.0, 1.5), 0.12, Kit.mat("#a8341c", 0.6, 0.5), 6)
		Kit.rod(pad, Vector3(6.0, k * 3.0, 1.5), Vector3(6.0, k * 3.0 + 3.0, -1.5), 0.12, Kit.mat("#a8341c", 0.6, 0.5), 6)
	for x: float in [4.5, 7.5]:
		for z: float in [-1.5, 1.5]:
			Kit.rod(pad, Vector3(x, 0, z), Vector3(x, 32, z), 0.18, Kit.mat("#a8341c", 0.6, 0.5), 6)
	# A porthole on the rocket's flank glowing green, Doom's mask inside: he rides along.
	var port := Node3D.new()
	port.position = Vector3(0, 18.0, 2.3)
	pad.add_child(port)
	var ring := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.55
	tor.outer_radius = 0.72
	ring.mesh = tor
	ring.material_override = Kit.mat("#9aa2aa", 0.3, 0.9)
	ring.rotation = Vector3(PI / 2, 0, 0)
	port.add_child(ring)
	var glass := Kit.cyl(port, 0.56, 0.56, 0.04, Vector3(0, 0, -0.05), Kit.lit("#2aff6a", 0.9), 32, Vector3(PI / 2, 0, 0))
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mk := MeshInstance3D.new()
	mk.mesh = _suit_mask()
	mk.material_override = Kit.mat("#7a8086", 0.45, 0.7)
	mk.scale = Vector3.ONE * 0.32
	mk.position = Vector3(0, 0, -0.02)
	port.add_child(mk)
	Kit.omni(port, Vector3(0, 0, 0.6), "#2aff6a", 2.0, 4.0, false, 0.3)
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var out := {}
	var inv: Transform3D = node.global_transform.affine_inverse()
	# The board under the actor's feet, crackling.
	var bd: Dictionary = _p.get("board", {})
	var im := _arcs.mesh as ImmediateMesh
	im.clear_surfaces()
	if bd.has("actor") and ctx.has("actor"):
		var a = ctx["actor"].call(String(bd["actor"]))
		if a != null:
			var feet: Vector3 = inv * ((a.bone_world("foot_l") + a.bone_world("foot_r")) * 0.5)
			var ay := float(a.rotation.y)
			_board.transform = Transform3D(Basis.from_euler(Vector3(0.12 * sin(t * 1.3), ay, 0.08 * sin(t * 0.9))), feet - Vector3(0, 0.06, 0))
			var bucket := int(floor(t * 20.0))
			im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			for k in 5:
				var rng := RandomNumberGenerator.new()
				rng.seed = bucket * 13 + k
				var p0 := feet + Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.9, 0.9))
				var p1 := p0 + Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(0.3, 1.4), rng.randf_range(-0.6, 0.6))
				var prev := p0
				for s in 6:
					var u := float(s + 1) / 6.0
					var q := p0.lerp(p1, u) + Vector3(rng.randf_range(-0.08, 0.08), 0, rng.randf_range(-0.08, 0.08))
					var w := Vector3(0.008, 0, 0.008)
					for v in [prev - w, prev + w, q + w, prev - w, q + w, q - w]:
						im.surface_add_vertex(v)
					prev = q
			im.surface_end()
	var fl := 0.0
	for lt in _p.get("lightning", []):
		var k := t - float(lt)
		if k >= 0.0 and k < 0.6:
			fl = maxf(fl, exp(-k * 9.0))
	_flash.light_energy = 300.0 * fl
	# The Beyonder's star into the hand; the palm universe.
	var byd: Dictionary = _p.get("beyonder", {})
	var bt := float(byd.get("t", 1e9))
	var hand := VOID + Vector3(0, 1.0, 0)
	if byd.has("actor") and ctx.has("actor"):
		var a2 = ctx["actor"].call(String(byd["actor"]))
		if a2 != null:
			hand = inv * a2.bone_world("hand_r")
			var reach := Motion.in_out(Motion.seg(t, bt - 1.0, bt))
			if reach > 0.0:
				a2.aim_hand("r", a2.bone_world("spine_03") + Vector3(0, 0.45, 0) + Vector3(sin(float(a2.rotation.y)), 0, cos(float(a2.rotation.y))) * 0.5, reach)
				hand = inv * a2.bone_world("hand_r")
	var k3 := Motion.in_cubic(Motion.seg(t, bt - 1.2, bt + 0.6))
	var far := VOID + Vector3(-4.0, 6.0, -30.0)
	_star.position = far.lerp(hand + Vector3(0, 0.15, 0), k3)
	var size := lerpf(3.0, 0.12, k3)
	_star.scale = Vector3.ONE * size
	_star.visible = t < bt + 0.7
	_star_light.position = _star.position
	_star_light.light_energy = 20.0 * (1.0 - 0.8 * k3) if _star.visible else 0.0
	_palm.visible = t >= bt + 0.5
	_palm.position = hand + Vector3(0, 0.1, 0)
	_palm.rotation = Vector3(0.2, t * 1.4, 0)
	var hidden := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.001), Vector3(0, -50, 0))
	var rng2 := RandomNumberGenerator.new()
	for i in _streams.instance_count:
		rng2.seed = 300 + i
		var u := fposmod(t * 0.8 + rng2.randf(), 1.0)
		var on := t > bt - 1.4 and t < bt + 0.6
		if not on:
			_streams.set_instance_transform(i, hidden)
			continue
		var off := Vector3(rng2.randf_range(-1, 1), rng2.randf_range(-1, 1), rng2.randf_range(-1, 1)) * size * 0.9
		_streams.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * (1.2 - u)), (_star.position + off).lerp(hand, u)))
	# Battleworld: patches converge on `stitch`.
	var st := float(_p.get("stitch", 1e9))
	var conv := Motion.out_cubic(Motion.seg(t, st - 0.5, st + 2.0))
	for i in _patches.size():
		var d := _patch_dirs[i]
		var spread := (1.0 - conv) * (18.0 + 6.0 * (i % 3))
		_patches[i].position = WORLD + d * spread
		_patches[i].rotation = Vector3(0, (1.0 - conv) * (0.5 - 0.1 * i), (1.0 - conv) * 0.3 * sin(i))
	_seam_mat.emission_energy_multiplier = 3.0 * conv * (0.8 + 0.2 * sin(t * 3.0))
	_seams[0].visible = conv > 0.6
	# Reed's arm stretching in toward the throne.
	var sd: Dictionary = _p.get("stretch", {})
	var stt := float(sd.get("t", 1e9))
	var reachk := Motion.in_out(Motion.seg(t, stt, stt + 1.4))
	var from := GOD + Vector3(14.0, 3.0, 8.0)
	var tip := from.lerp(GOD + Vector3(0.25, 2.1, -5.1), reachk)
	_arm.visible = reachk > 0.0
	if _arm.visible:
		var mid := (from + tip) * 0.5
		var len := (tip - from).length()
		_arm.transform = Transform3D(Basis.looking_at((tip - from).normalized(), Vector3.UP) * Basis.from_euler(Vector3(-PI / 2, 0, 0)), mid)
		_arm.scale = Vector3(1, len, 1)
	_arm_light.position = tip
	_arm_light.light_energy = 12.0 * Motion.smooth(Motion.seg(t, stt + 1.2, stt + 1.8))
	# The cloak drops onto the actor's shoulders.
	var cd: Dictionary = _p.get("cloak", {})
	var ct := float(cd.get("t", 1e9))
	_cloak.visible = t >= ct - 0.6
	if _cloak.visible and cd.has("actor") and ctx.has("actor"):
		var a3 = ctx["actor"].call(String(cd["actor"]))
		if a3 != null:
			var sh: Vector3 = inv * a3.bone_world("spine_03") + Vector3(0, 0.2, 0)
			var k := Motion.out_bounce(Motion.seg(t, ct - 0.6, ct))
			_cloak.position = sh + Vector3(0, 2.5 * (1.0 - k), 0)
			_cloak.rotation = Vector3(0, float(a3.rotation.y), 0.6 * (1.0 - k))
	# Earth turns green; banners rise.
	var gt := float(_p.get("green", 1e9))
	var gk := Motion.smooth(Motion.seg(t, gt, gt + 1.5))
	var cc := Color(1.0, 0.78, 0.45).lerp(Color(0.3, 1.0, 0.45), gk)
	_earth_mat.set_shader_parameter("city", Vector3(cc.r, cc.g, cc.b))
	_earth_mat.set_shader_parameter("night_gain", 2.6 + 1.5 * gk)
	_earth_mat.set_shader_parameter("spin", t * 0.004)
	for i in _banners.size():
		var b := _banners[i]
		var bk := Motion.out_back(Motion.seg(t, gt + 0.05 * i, gt + 0.05 * i + 0.4), 1.6)
		b.visible = bk > 0.0
		if b.visible:
			var d := _banner_dirs[i].normalized()
			b.transform = Transform3D(Basis.looking_at(d.cross(Vector3.UP).normalized(), d).orthonormalized().scaled(Vector3.ONE * bk * 1.6),
				EARTH + d * EARTH_R)
	out["board"] = node.global_transform * _board.position
	out["star"] = node.global_transform * _star.position
	out["palm"] = node.global_transform * _palm.position
	out["planet"] = node.global_transform * WORLD
	out["throne"] = node.global_transform * (GOD + Vector3(0, 2.0, -6))
	out["earth"] = node.global_transform * EARTH
	out["rocket"] = node.global_transform * (PAD + Vector3(0, 15, 0))
	return out
