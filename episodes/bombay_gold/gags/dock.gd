## Victoria Dock, Bombay, 14 April 1944: the whole afternoon in one set. The basin of green harbour water between
## stone quays; the Fort Stikine berthed along the near quay (bow toward +x); the Fort Crevier bow-to-bow beyond it;
## the Jalapadma astern; ships across the basin; quayside cranes, transit sheds, the dock office with its clock
## tower and fire bell; a crowd of dockworkers; the city beyond in haze.
##
## The day plays out by time: smoke from No. 2 hold, the alarm bell, fire engines racing down the quay, fireboats,
## hoses, the fire breaking through, the blast (flash, fireball, mushroom, a shockwave across the water, shed roofs
## torn off, debris, burning cotton), the Jalapadma thrown onto the quay, the second blast; night (sunken ships'
## masts against the fires); dawn (ruins, smoke, the 66 helmets).
##
## Local frame: water surface y 0; the near quay edge at z +QZ, deck y QH; ship centreline z 0, midships x 0, bow +x;
## No. 2 hold at x +33. Cameras usually on or above the near quay looking -z.
##
## params (all times are scene seconds, resolved from word references):
##   smoke, alarm, engines, boats, hoses, pops, abandon, blast, surge, land, second, night, dawn, helmets
##   clock [[t, minutes since midnight], ...]   the dock clock shows the last key; it ticks to each new key
##   bell  {"actor": id}   the dock officer's hands on the bell rope while it rings
##   megaphone {"actor": id, "from": t}   the fire chief raises a megaphone
##   nozzles [{"actor": id, "aim": [x, y, z]}]   firemen holding hose nozzles (local coords of the aim)
## anchors: ship, hold2, bow, foremast, quay, clock, bell, crevier_fo, jalapadma, blast, gangway, smoke
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Paths = preload("res://scripts/core/paths.gd")

const SK := "incoming/bombay_gold/sketchfab/"
const PH := "incoming/bombay_gold/polyhaven/"
const QZ := 11.5           # near quay edge
const QH := 2.6            # quay deck above the water
const SHIP_LEN := 150.0    # model length incl. booms; the hull comes out ~134 m
const SHIP_SINK := 7.0     # loaded: the keel this far under the water (deck ~5 m up)
const HOLD2 := Vector3(32.0, 8.4, 0.0)
const FOREMAST := Vector3(40.0, 24.0, 0.0)
const BOW := Vector3(66.0, 7.0, 0.0)
const TOWER := Vector3(6.0, QH, QZ + 27.0)
const TOWER_H := 24.0
const CREVIER := Vector3(166.0, -SHIP_SINK, 0.0)    # yaw PI: her bow toward -x, near the Stikine's bow
const JALA := Vector3(-168.0, -SHIP_SINK, 0.0)
const GANGWAY_X := 24.0

const WATER := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform float t = 0.0;
uniform vec3 deep : source_color = vec3(0.05, 0.085, 0.075);
uniform vec3 shallow : source_color = vec3(0.14, 0.18, 0.14);
uniform vec3 ring_c = vec3(0.0);
uniform float ring_age = -1.0;
uniform float ring2_age = -1.0;
uniform vec3 ring2_c = vec3(0.0);
uniform float glow = 0.0;
uniform vec3 glow_col : source_color = vec3(1.0, 0.45, 0.15);
varying vec3 wp;
varying float foam;
//NOISE
float ring(vec2 p, vec3 c, float age, float speed, float amp) {
	if (age < 0.0) return 0.0;
	float d = length(p - c.xz);
	float r = age * speed;
	float w = 6.0 + age * 4.0;
	return amp * exp(-pow((d - r) / w, 2.0)) * exp(-age * 0.35) * sin((d - r) * 0.25);
}
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = 0.05 * sin(wp.x * 0.35 + t * 1.1) + 0.04 * sin(wp.z * 0.5 - t * 0.9) + 0.03 * sin((wp.x + wp.z) * 0.8 + t * 1.7);
	float rr = ring(wp.xz, ring_c, ring_age, 70.0, 4.5) + ring(wp.xz, ring2_c, ring2_age, 60.0, 2.5);
	foam = clamp(abs(rr) * 0.35, 0.0, 1.0);
	VERTEX.y += h + rr;
}
void fragment() {
	vec2 p = wp.xz;
	float n1 = fbm(vec3(p * 0.18 + vec2(t * 0.05, t * 0.03), t * 0.05));
	float n2 = fbm(vec3(p * 0.9 - vec2(t * 0.12, -t * 0.08), t * 0.1));
	vec3 nrm = normalize(vec3((n1 - 0.5) * 0.35 + (n2 - 0.5) * 0.25, 1.0, (n2 - 0.5) * 0.35 - (n1 - 0.5) * 0.2));
	NORMAL = normalize((VIEW_MATRIX * vec4(nrm, 0.0)).xyz);
	vec3 col = mix(deep, shallow, n1 * 0.6);
	col = mix(col, vec3(0.85, 0.86, 0.84), foam * smoothstep(0.3, 0.7, n2));
	ALBEDO = col;
	EMISSION = glow_col * glow * (0.4 + 0.6 * n1);
	ROUGHNESS = 0.07 + foam * 0.5;
	SPECULAR = 0.6;
}
"""

var FX
var _p := {}
var _water_mat: ShaderMaterial
var _stikine: Node3D
var _crevier: Node3D
var _jala: Node3D
var _jala_crane: Node3D
var _others: Array[Node3D] = []
var _wreck: Node3D
var _masts: Node3D
var _sheds: Array[Node3D] = []
var _roofs: Array[MeshInstance3D] = []
var _roof_home: Array[Vector3] = []
var _ruins: Node3D
var _hands: Array = []          # [[hour, minute], ...] for the four faces
var _bell: Node3D
var _rope: MeshInstance3D
var _engines: Array[Node3D] = []
var _boats: Array[Node3D] = []
var _crowd: MultiMesh
var _crowd_heads: MultiMesh
var _helmets: Node3D
var _debris: MultiMesh
var _megaphone: Node3D
var _hoses: Array[MeshInstance3D] = []
var _smoke
var _fire
var _spray
var _flash: OmniLight3D
var _hold_light: OmniLight3D
var _fire_lights: Array[OmniLight3D] = []
var _night_lights: Array[OmniLight3D] = []


func _tex(name: String, scale: float, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var b := PH + "textures/" + name
	return Kit.textured(b + "_diff_2k.jpg", b + "_nor_gl_2k.jpg", b + "_rough_2k.jpg", Vector3.ONE * scale, tint, true)


func _place(root: Node3D, rel: String, pos: Vector3, yaw: float = 0.0, scale: float = 1.0) -> Node3D:
	var n := Kit.model(rel)
	n.position = pos
	n.rotation.y = yaw
	n.scale = Vector3.ONE * scale
	root.add_child(n)
	return n


func _h(i: int, salt: int) -> float:
	var x := sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453
	return x - floor(x)


func _ft(key: String) -> float:
	return float(_p.get(key, 1e9))


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	FX = load(Paths.repo_path("episodes/bombay_gold/gags/fx.gd"))
	var root := Node3D.new()
	root.name = String(g.get("id", "dock"))
	_build_water(root)
	_build_quays(root)
	_build_tower(root)
	_build_ships(root)
	_build_city(root)
	_build_crowd(root)
	_build_fire_service(root)
	_build_aftermath(root)
	_smoke = FX.layer(root, 900, "smoke")
	_fire = FX.layer(root, 700, "fire")
	_spray = FX.layer(root, 900, "spray")
	_flash = Kit.omni(root, HOLD2 + Vector3(0, 30, 0), "#ffe2b0", 0.0, 900.0, false, 3.0)
	_hold_light = Kit.omni(root, HOLD2 + Vector3(0, 4, 0), "#ff7a2a", 0.0, 60.0, false, 1.5)
	for k in 4:
		_fire_lights.append(Kit.omni(root, Vector3(-60 + k * 50, 12, 20), "#ff6a20", 0.0, 140.0, false, 1.0))
	return root


# --- build ----------------------------------------------------------------------------

func _build_water(root: Node3D) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2600, 2600)
	plane.subdivide_width = 220
	plane.subdivide_depth = 220
	var wmi := MeshInstance3D.new()
	wmi.mesh = plane
	_water_mat = Kit.shader(WATER)
	wmi.material_override = _water_mat
	wmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(wmi)


func _build_quays(root: Node3D) -> void:
	var wall := _tex("seaworn_sandstone_brick", 0.35)
	var paving := _tex("stone_pavers", 0.3, Color(0.9, 0.86, 0.78))
	var iron_dark := Kit.mat("#2a2a2c", 0.5, 0.6)
	# Near quay: the wall into the water, the apron, a coping-stone edge, rails, bollards, tyre fenders.
	Kit.box(root, Vector3(1000, QH + 7.94, 6.0), Vector3(0, (QH - 0.06 - 8.0) * 0.5, QZ + 3.0), wall)
	Kit.box(root, Vector3(1000, 0.4, 140), Vector3(0, QH - 0.2, QZ + 70.0), paving)
	Kit.box(root, Vector3(1000, 0.35, 0.9), Vector3(0, QH + 0.05, QZ + 0.45), Kit.mat("#8c8478", 0.85))
	for k in 34:
		var x := -480.0 + k * 29.0
		Kit.cyl(root, 0.32, 0.4, 0.75, Vector3(x, QH + 0.37, QZ + 1.1), iron_dark, 16)
		Kit.ball(root, 0.42, Vector3(x, QH + 0.8, QZ + 1.1), iron_dark, 12, Vector3(1, 0.5, 1))
		var ty := _place(root, PH + "models/old_tyre/old_tyre_2k.gltf", Vector3(x + 9.0, QH - 1.6, QZ - 0.12), 0.0, 1.7)
		ty.rotation.x = PI * 0.5
	var rail := Kit.mat("#4a4440", 0.35, 0.85)
	for rz: float in [QZ + 5.0, QZ + 6.45, QZ + 14.0, QZ + 15.45]:
		Kit.box(root, Vector3(1000, 0.14, 0.09), Vector3(0, QH + 0.08, rz), rail)
	# Mooring lines from the Stikine to the bollards.
	var rope := Kit.mat("#b8a27a", 0.9)
	for x: float in [-58.0, -40.0, 46.0, 62.0]:
		Kit.rod(root, Vector3(x * 0.95, 7.6, 8.6), Vector3(x + (-6.0 if x < 0 else 6.0), QH + 0.6, QZ + 1.1), 0.09, rope, 6)
	# Quayside cranes (one stands where the Jalapadma will land).
	for k in 13:
		var x := -300.0 + k * 50.0
		if x > -18.0 and x < 82.0:
			continue
		var c := _place(root, SK + "simple_industry_crane_1.glb", Vector3(x, QH, QZ + 5.7), PI * 0.5, 3.4)
		if _jala_crane == null and absf(x - JALA.x) < 30.0:
			_jala_crane = c
	if _jala_crane == null:
		_jala_crane = _place(root, SK + "simple_industry_crane_1.glb", Vector3(JALA.x + 4.0, QH, QZ + 5.7), PI * 0.5, 3.4)
	# Transit sheds: brick walls, iron clerestory roofs (separate, so the blast can tear them off).
	var brick := _tex("red_plaster_weathered", 0.22)
	var iron := _tex("corrugated_iron_02", 0.4, Color(0.72, 0.69, 0.64))
	var dark := Kit.mat("#16120e", 0.95)
	for k in 6:
		var x := -380.0 + k * 150.0
		var shed := Node3D.new()
		shed.position = Vector3(x, QH, QZ + 56.0)
		root.add_child(shed)
		Kit.box(shed, Vector3(124, 10, 34), Vector3(0, 5.0, 0), brick)
		for d in 10:
			Kit.box(shed, Vector3(5.0, 5.5, 0.2), Vector3(-54.0 + d * 12.0, 2.75, -17.05), dark)
		_sheds.append(shed)
		for part in 2:
			var home := Vector3(x, QH + 10.6 + part * 3.4, QZ + 56.0 + (-8.0 if part == 0 else 6.0))
			var r := Kit.box(root, Vector3(124, 0.5, 18), home, iron, Vector3(0.12 if part == 0 else -0.12, 0, 0))
			_roofs.append(r)
			_roof_home.append(home)
	# The far quay across the basin, godowns and cranes behind.
	Kit.box(root, Vector3(1600, QH + 7.94, 8.0), Vector3(0, (QH - 0.06 - 8.0) * 0.5, -164.0), wall)
	Kit.box(root, Vector3(1600, 0.4, 160), Vector3(0, QH - 0.2, -244.0), paving)
	for k in 8:
		var x := -500.0 + k * 140.0
		Kit.box(root, Vector3(112, 12, 30), Vector3(x, QH + 6.0, -205.0), brick)
		Kit.box(root, Vector3(114, 0.6, 32), Vector3(x, QH + 12.3, -205.0), iron)
	for k in 9:
		var x := -420.0 + k * 100.0
		_place(root, SK + "simple_industry_crane_1.glb", Vector3(x, QH, -169.0), -PI * 0.5, 3.4)


func _build_tower(root: Node3D) -> void:
	# The dock office: a two-storey plastered block with a clock tower. Four faces, hands animated in pose().
	var stone := _tex("plastered_wall_04", 0.25, Color(0.93, 0.88, 0.8))
	var trim := Kit.mat("#7a5a3a", 0.8)
	Kit.box(root, Vector3(26, 9, 14), TOWER + Vector3(0, 4.5, 4.0), stone)
	Kit.box(root, Vector3(26.6, 0.6, 14.6), TOWER + Vector3(0, 9.2, 4.0), trim)
	for w in 6:
		var wx := -10.0 + w * 4.0
		if absf(wx + 2.2) < 1.6:
			continue
		Kit.box(root, Vector3(2.0, 2.8, 0.1), TOWER + Vector3(wx, 5.6, -3.05), Kit.mat("#1c2026", 0.3, 0.2))
		Kit.ball(root, 1.0, TOWER + Vector3(wx, 7.0, -3.06), Kit.mat("#1c2026", 0.3, 0.2), 16, Vector3(1.0, 0.6, 0.08))
		Kit.box(root, Vector3(2.4, 0.2, 0.3), TOWER + Vector3(wx, 4.1, -3.12), trim)
	# The board over the door: the real name of the dock authority (Bombay Port Trust, since 1873).
	Kit.box(root, Vector3(11.0, 1.3, 0.12), TOWER + Vector3(0, 8.0, -3.15), Kit.mat("#20304a", 0.6))
	Kit.text(root, "BOMBAY PORT TRUST", 0.62, "#f0e2b8", TOWER + Vector3(0, 8.0, -3.23), Vector3(0, PI, 0))
	Kit.box(root, Vector3(2.6, 3.6, 0.15), TOWER + Vector3(-2.2 + 4.0, 1.8, -3.1), Kit.mat("#3a2818", 0.7))
	Kit.box(root, Vector3(6.4, TOWER_H, 6.4), TOWER + Vector3(0, TOWER_H * 0.5, 0), stone)
	Kit.box(root, Vector3(7.0, 0.7, 7.0), TOWER + Vector3(0, TOWER_H + 0.35, 0), trim)
	Kit.cyl(root, 0.0, 4.8, 4.0, TOWER + Vector3(0, TOWER_H + 2.7, 0), _tex("clay_roof_tiles_02", 0.5), 4, Vector3(0, PI * 0.25, 0))
	var face := Kit.mat("#f2ead6", 0.6)
	var ring := Kit.mat("#2a2520", 0.4, 0.4)
	var hand := Kit.mat("#141210", 0.4, 0.3)
	var cy := TOWER_H - 3.2
	for side in 4:
		var yaw := side * PI * 0.5
		var dirv := Vector3(sin(yaw), 0, cos(yaw))
		var holder := Node3D.new()
		holder.position = TOWER + Vector3(0, cy, 0) + dirv * 3.25
		holder.rotation.y = yaw
		root.add_child(holder)
		Kit.cyl(holder, 2.2, 2.2, 0.12, Vector3.ZERO, ring, 48, Vector3(PI * 0.5, 0, 0))
		Kit.cyl(holder, 2.0, 2.0, 0.14, Vector3(0, 0, 0.02), face, 48, Vector3(PI * 0.5, 0, 0))
		for m in 12:
			var a := m * TAU / 12.0
			Kit.box(holder, Vector3(0.14, 0.42 if m % 3 == 0 else 0.26, 0.05), Vector3(sin(a) * 1.68, cos(a) * 1.68, 0.1), hand, Vector3(0, 0, -a))
		var hr := Node3D.new()
		hr.position = Vector3(0, 0, 0.14)
		holder.add_child(hr)
		Kit.box(hr, Vector3(0.18, 1.15, 0.05), Vector3(0, 0.45, 0), hand)
		var mn := Node3D.new()
		mn.position = Vector3(0, 0, 0.18)
		holder.add_child(mn)
		Kit.box(mn, Vector3(0.12, 1.65, 0.05), Vector3(0, 0.7, 0), hand)
		Kit.ball(holder, 0.13, Vector3(0, 0, 0.22), hand, 12)
		_hands.append([hr, mn])
	# The fire bell on a bracket on the tower's ship side, with its pull rope.
	_bell = Node3D.new()
	_bell.position = TOWER + Vector3(-2.2, 5.4, -3.9)
	root.add_child(_bell)
	var brass := Kit.mat("#b8892e", 0.3, 0.9)
	Kit.box(root, Vector3(0.12, 0.12, 1.2), TOWER + Vector3(-2.2, 5.95, -3.6), Kit.mat("#2a2a2a", 0.5, 0.6))
	Kit.cyl(_bell, 0.18, 0.42, 0.55, Vector3(0, -0.3, 0), brass, 24)
	Kit.ball(_bell, 0.07, Vector3(0, -0.62, 0), brass, 10)
	_rope = MeshInstance3D.new()
	_rope.material_override = Kit.mat("#c8b48a", 0.9)
	root.add_child(_rope)


func _ship_model(root: Node3D, pos: Vector3, yaw: float, k: float) -> Node3D:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = yaw
	root.add_child(holder)
	var m := Kit.model(SK + "liberty_ship/scene_fort.gltf")
	m.scale = Vector3.ONE * (SHIP_LEN / 0.141 * k)
	m.rotation.y = PI * 0.5
	holder.add_child(m)
	return holder


func _build_ships(root: Node3D) -> void:
	_stikine = _ship_model(root, Vector3(0, -SHIP_SINK, 0), 0.0, 1.0)
	_crevier = _ship_model(root, CREVIER, PI, 0.98)
	_jala = _ship_model(root, JALA, 0.0, 0.82)
	for spec in [[Vector3(-150, -SHIP_SINK, -146), PI, 0.95], [Vector3(30, -SHIP_SINK, -146), PI, 1.0],
			[Vector3(205, -SHIP_SINK, -146), PI, 0.9], [Vector3(-320, -SHIP_SINK, 0), 0.0, 0.9]]:
		_others.append(_ship_model(root, spec[0], spec[1], spec[2]))
	# The gangway from the quay up to the Stikine's deck.
	var plank := _tex("weathered_brown_planks", 0.8)
	var g0 := Vector3(GANGWAY_X, QH + 0.1, QZ + 2.2)
	var g1 := Vector3(GANGWAY_X, 7.3, 8.6)
	var gd := g1 - g0
	Kit.box(root, Vector3(1.1, 0.12, gd.length()), (g0 + g1) * 0.5, plank, Vector3(atan2(gd.y, -gd.z), 0, 0))
	for s: float in [-0.55, 0.55]:
		Kit.rod(root, g0 + Vector3(s, 1.0, 0), g1 + Vector3(s, 1.0, 0), 0.03, Kit.mat("#d8d0c0", 0.6), 6)
	# The wreck (after the blast): the bow and stern sections, broken, black, settling at angles.
	_wreck = Node3D.new()
	_wreck.visible = false
	root.add_child(_wreck)
	var burnt := Kit.mat("#141110", 0.9, 0.3)
	var rust := _tex("rusty_metal_02", 0.2, Color(0.35, 0.28, 0.24))
	var bow := Node3D.new()
	bow.position = Vector3(46, -3.0, 0)
	bow.rotation = Vector3(0.0, 0.08, 0.12)
	_wreck.add_child(bow)
	Kit.box(bow, Vector3(40, 9, 17), Vector3(0, 0, 0), rust)
	Kit.box(bow, Vector3(8, 9, 12), Vector3(22, 0.5, 0), rust, Vector3(0, 0.6, 0))
	Kit.rod(bow, Vector3(2, 4, 0), Vector3(6, 22, 1), 0.4, burnt, 8)
	var stern := Node3D.new()
	stern.position = Vector3(-28, -4.0, 0.5)
	stern.rotation = Vector3(0.05, -0.05, -0.1)
	_wreck.add_child(stern)
	Kit.box(stern, Vector3(62, 9, 17), Vector3(0, 0, 0), rust)
	Kit.box(stern, Vector3(16, 7, 13), Vector3(4, 7.5, 0), burnt)
	Kit.cyl(stern, 1.6, 1.8, 6, Vector3(4, 13, 0), burnt, 16, Vector3(0, 0, 0.25))
	Kit.rod(stern, Vector3(-18, 4, 0), Vector3(-20, 20, 0), 0.4, burnt, 8)
	# Night: the masts and funnels of sunken ships standing out of the water.
	_masts = Node3D.new()
	_masts.visible = false
	root.add_child(_masts)
	var mm := Kit.mat("#0c0a09", 0.9)
	for spec in [[Vector3(-150, 0, -146), 0.2], [Vector3(30, 0, -146), -0.15], [Vector3(205, 0, -146), 0.1],
			[Vector3(166, 0, 0), -0.25], [Vector3(-320, 0, 0), 0.18], [Vector3(-90, 0, -60), 0.3], [Vector3(110, 0, -70), -0.1],
			[Vector3(10, 0, 0), 0.08]]:
		var c: Vector3 = spec[0]
		var lean: float = spec[1]
		var grp := Node3D.new()
		grp.position = c
		grp.rotation.z = lean
		_masts.add_child(grp)
		for mx: float in [-36.0, -10.0, 24.0]:
			Kit.rod(grp, Vector3(mx, -2, 0), Vector3(mx, 22, 0), 0.35, mm, 6)
			Kit.rod(grp, Vector3(mx - 5, 16, 0), Vector3(mx + 5, 16, 0), 0.15, mm, 6)
			Kit.rod(grp, Vector3(mx, 14, 0), Vector3(mx + 14, 3, 0), 0.18, mm, 6)
		Kit.cyl(grp, 1.5, 1.7, 7.0, Vector3(-2, 2.0, 0), mm, 14)


func _build_city(root: Node3D) -> void:
	var rng := Kit.rng("dock_city")
	var plasters := [_tex("plastered_wall_04", 0.15, Color(0.88, 0.82, 0.72)), _tex("yellow_plaster", 0.15, Color(0.9, 0.85, 0.75)),
		_tex("worn_mossy_plasterwall", 0.15, Color(0.85, 0.82, 0.76)), _tex("peeling_painted_wall", 0.15, Color(0.88, 0.86, 0.8))]
	var roofs := _tex("clay_roof_tiles_02", 0.3)
	var win := Kit.mat("#20242a", 0.4, 0.2)
	for band in 2:
		var z0 := QZ + 112.0 + band * 60.0
		for k in 90:
			var x := -820.0 + k * 19.0 + rng.randf_range(-5, 5)
			var h := rng.randf_range(12, 26) + band * 6.0
			var w := rng.randf_range(14, 20)
			var d := rng.randf_range(14, 22)
			var c := Vector3(x, QH + h * 0.5, z0 + rng.randf_range(0, 30))
			Kit.box(root, Vector3(w, h, d), c, plasters[rng.randi() % plasters.size()])
			if rng.randf() < 0.6:
				Kit.box(root, Vector3(w + 1.2, 2.2, d + 1.2), c + Vector3(0, h * 0.5 + 1.0, 0), roofs)
			var floors := int(h / 3.6)
			for f in floors:
				for wi in 3:
					Kit.box(root, Vector3(1.3, 1.8, 0.1), Vector3(c.x - w * 0.3 + wi * w * 0.3, QH + 2.4 + f * 3.6, c.z - d * 0.5 - 0.03), win)
	for k in 60:
		var x := -900.0 + k * 32.0 + rng.randf_range(-8, 8)
		var h := rng.randf_range(15, 36)
		Kit.box(root, Vector3(rng.randf_range(18, 30), h, 20), Vector3(x, QH + h * 0.5, -335.0 - rng.randf_range(0, 70)), plasters[k % 4])


func _build_crowd(root: Node3D) -> void:
	# Dockworkers on the apron: a cotton-vest body and a head, walking their loads up and down.
	var body := CapsuleMesh.new()
	body.radius = 0.24
	body.height = 1.25
	var head := SphereMesh.new()
	head.radius = 0.16
	head.height = 0.32
	_crowd = MultiMesh.new()
	_crowd.transform_format = MultiMesh.TRANSFORM_3D
	_crowd.use_colors = true
	_crowd.mesh = body
	_crowd.instance_count = 220
	_crowd_heads = MultiMesh.new()
	_crowd_heads.transform_format = MultiMesh.TRANSFORM_3D
	_crowd_heads.use_colors = true
	_crowd_heads.mesh = head
	_crowd_heads.instance_count = 220
	var rng := Kit.rng("dock_crowd")
	var cols := [Color("#b8ae98"), Color("#9c8a64"), Color("#7a6448"), Color("#5e6a78"), Color("#a08c64"), Color("#c4baa6")]
	for i in 220:
		_crowd.set_instance_color(i, cols[rng.randi() % cols.size()])
		_crowd_heads.set_instance_color(i, Color("#5a3a26").lerp(Color("#e8dcc8"), rng.randf() * 0.5))
	for mmv in [_crowd, _crowd_heads]:
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mmv
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 0.9
		mi.material_override = m
		mi.extra_cull_margin = 600.0
		root.add_child(mi)


func _build_fire_service(root: Node3D) -> void:
	var trucks := [SK + "free_1938_vairogs_fire_truck_based_on_ford.glb", SK + "free_1940s_us_fire_truck_american_lafrance.glb",
		SK + "free_1938_vairogs_fire_truck_based_on_ford.glb"]
	for i in 3:
		var holder := Node3D.new()
		root.add_child(holder)
		var m := Kit.model(trucks[i])
		m.rotation.y = -PI * 0.5      # the models face +z; they drive toward -x
		holder.add_child(m)
		_engines.append(holder)
	for i in 2:
		var holder := Node3D.new()
		root.add_child(holder)
		var m := Kit.model(SK + "fireboat_alexander_grantham.glb")
		var b := Kit.bounds(m)
		m.scale = Vector3.ONE * 0.62
		m.position = Vector3(-b.get_center().x, -b.position.y - 2.2 / 0.62, -b.get_center().z) * 0.62
		holder.add_child(m)
		_boats.append(holder)
	var hose_mat := Kit.mat("#8a6a3e", 0.8)
	for i in 8:
		var h := MeshInstance3D.new()
		h.material_override = hose_mat
		h.visible = false
		root.add_child(h)
		_hoses.append(h)
	_megaphone = Kit.model(PH + "models/Megaphone_01/Megaphone_01_2k.gltf")
	_megaphone.visible = false
	root.add_child(_megaphone)


func _build_aftermath(root: Node3D) -> void:
	_ruins = Node3D.new()
	_ruins.visible = false
	root.add_child(_ruins)
	var rng := Kit.rng("ruins")
	var brick := _tex("red_plaster_weathered", 0.22, Color(0.55, 0.45, 0.4))
	var char_m := Kit.mat("#1a1512", 0.95)
	var rubble := _tex("cobblestone_floor_04", 0.4, Color(0.5, 0.44, 0.4))
	for k in 6:
		var x := -380.0 + k * 150.0
		for seg in 14:
			if absf(x - 56 + seg * 8.6 + 30.0) < 7.0:
				continue
			var h := rng.randf_range(1.0, 7.5)
			Kit.box(_ruins, Vector3(8.0, h, 0.6), Vector3(x - 56 + seg * 8.6, QH + h * 0.5, QZ + 39.0), brick, Vector3(0, 0, rng.randf_range(-0.08, 0.08)))
			if rng.randf() < 0.7:
				var h2 := rng.randf_range(0.8, 5.0)
				Kit.box(_ruins, Vector3(8.0, h2, 0.6), Vector3(x - 56 + seg * 8.6, QH + h2 * 0.5, QZ + 73.0), brick)
		for p in 18:
			var c := Vector3(x + rng.randf_range(-58, 58), QH, QZ + 56 + rng.randf_range(-15, 15))
			Kit.ball(_ruins, rng.randf_range(1.5, 4.0), c, rubble if p % 2 == 0 else char_m, 10, Vector3(1.6, 0.45, 1.2))
			if p % 3 == 0:
				Kit.rod(_ruins, c + Vector3(0, 0.5, 0), c + Vector3(rng.randf_range(-4, 4), rng.randf_range(2, 6), rng.randf_range(-3, 3)), 0.15, char_m, 5)
	# The 66 brass helmets, laid in rows on the quay at dawn (6 rows of 11).
	_helmets = Node3D.new()
	_helmets.visible = false
	root.add_child(_helmets)
	var brass := Kit.mat("#c9973a", 0.28, 0.95)
	var dome := SphereMesh.new()
	dome.radius = 0.2
	dome.height = 0.2
	dome.is_hemisphere = true
	var comb := BoxMesh.new()
	comb.size = Vector3(0.05, 0.09, 0.36)
	var brim := CylinderMesh.new()
	brim.top_radius = 0.26
	brim.bottom_radius = 0.28
	brim.height = 0.03
	for spec in [[dome, Vector3(1.0, 1.4, 1.15), 0.03], [comb, Vector3.ONE, 0.29], [brim, Vector3(1.0, 1.0, 1.25), 0.015]]:
		var mmx := MultiMesh.new()
		mmx.transform_format = MultiMesh.TRANSFORM_3D
		mmx.mesh = spec[0]
		mmx.instance_count = 66
		for i in 66:
			var row := i / 11
			var col := i % 11
			var p := Vector3(HOLD2.x - 5.0 + (col - 5) * 1.15, QH + float(spec[2]), QZ + 6.0 + row * 1.3)
			mmx.set_instance_transform(i, Transform3D(Basis.from_scale(spec[1]), p))
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mmx
		mi.material_override = brass
		_helmets.add_child(mi)
	# Blast debris: steel plates on ballistic arcs.
	var plate := BoxMesh.new()
	plate.size = Vector3(2.4, 0.15, 1.6)
	_debris = MultiMesh.new()
	_debris.transform_format = MultiMesh.TRANSFORM_3D
	_debris.mesh = plate
	_debris.instance_count = 120
	_debris.visible_instance_count = 0
	var dmi := MultiMeshInstance3D.new()
	dmi.multimesh = _debris
	dmi.material_override = Kit.mat("#2a2420", 0.7, 0.5)
	dmi.extra_cull_margin = 2000.0
	root.add_child(dmi)
	for i in 8:
		_night_lights.append(Kit.omni(root, Vector3(-300 + i * 90, 10, 50 if i % 2 == 0 else -150), "#ff6a24", 0.0, 220.0, false, 1.2))


# --- pose ------------------------------------------------------------------------------

func _clock_minutes(t: float) -> float:
	var keys: Array = _p.get("clock", [])
	var cur := 12.0 * 60.0 + 30.0
	var prev := cur
	var since := 99.0
	for kv in keys:
		if t >= float(kv[0]):
			prev = cur
			cur = float(kv[1])
			since = t - float(kv[0])
	# A one-minute tick jumps with a small overshoot; a bigger change sweeps.
	var k := Motion.out_back(clampf(since / 0.35, 0.0, 1.0), 2.2)
	if absf(cur - prev) > 2.0:
		k = Motion.smooth(clampf(since / 1.1, 0.0, 1.0))
	return lerpf(prev, cur, k)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var inv := gt.affine_inverse()
	var cam := node.get_viewport().get_camera_3d()
	var cam_l: Vector3 = (inv * cam.global_position) if cam else Vector3(0, 10, 100)
	var smoke_t := _ft("smoke")
	var alarm_t := _ft("alarm")
	var hoses_t := _ft("hoses")
	var pops_t := _ft("pops")
	var abandon_t := _ft("abandon")
	var blast_t := _ft("blast")
	var second_t := _ft("second")
	var night_t := _ft("night")
	var dawn_t := _ft("dawn")
	var post := t >= blast_t + 0.06
	var night := t >= night_t and t < dawn_t
	var dawn := t >= dawn_t
	var later := night or dawn
	_water_mat.set_shader_parameter("t", t)
	_water_mat.set_shader_parameter("ring_c", HOLD2)
	_water_mat.set_shader_parameter("ring_age", (t - blast_t) if (t > blast_t and t < blast_t + 12.0) else -1.0)
	_water_mat.set_shader_parameter("ring2_c", HOLD2 + Vector3(-20, 0, 0))
	_water_mat.set_shader_parameter("ring2_age", (t - second_t) if (t > second_t and t < second_t + 10.0) else -1.0)
	_water_mat.set_shader_parameter("glow", 0.25 if night else (0.12 if (post and not dawn) else 0.0))
	# Ships.
	_stikine.visible = not post
	_wreck.visible = post and not later
	_masts.visible = later
	_crevier.visible = not later
	for o in _others:
		o.visible = not later
	# The Jalapadma: the surge lifts her out of the water and drops her on the quay, crushing the crane.
	var surge_t := _ft("surge")
	var land_t := _ft("land")
	var jl := Motion.smooth(clampf((t - surge_t) / maxf(land_t - surge_t, 0.3), 0.0, 1.0))
	var arc := sin(jl * PI) * 9.0
	var bounce := 0.0
	if t >= land_t:
		var a := t - land_t
		bounce = -0.6 * exp(-a * 5.0) * absf(cos(a * 14.0))
	_jala.position = JALA + Vector3(jl * 10.0, jl * (QH + SHIP_SINK + 0.4) + arc + bounce, jl * 22.0)
	_jala.rotation = Vector3(-jl * 0.06, jl * 0.1, jl * 0.09)
	var crush := Motion.out_back(clampf((t - land_t + 0.05) / 0.5, 0.0, 1.0), 1.3)
	_jala_crane.rotation = Vector3(-crush * 1.25, PI * 0.5, crush * 0.2)
	# Sheds: roofs torn off by the shockwave; ruins by night.
	for s in _sheds:
		s.visible = not later
	_ruins.visible = later
	for i in _roofs.size():
		var r := _roofs[i]
		var home := _roof_home[i]
		var d := absf(home.x - HOLD2.x)
		var a2 := t - (blast_t + d / 340.0)
		r.visible = not later and a2 < 4.0
		if a2 > 0.0:
			var fly := Vector3(signf(home.x - HOLD2.x) * 8.0, 26.0, 18.0) * (1.0 + 56.0 / maxf(d, 40.0))
			r.position = home + fly * a2 + Vector3(0, -4.9 * a2 * a2, 0)
			r.rotation = Vector3((0.12 if i % 2 == 0 else -0.12) + a2 * 1.4, a2 * 0.3, a2 * 0.5)
		else:
			r.position = home
			r.rotation = Vector3(0.12 if i % 2 == 0 else -0.12, 0, 0)
	# The clock.
	var mins := _clock_minutes(t)
	for hm in _hands:
		hm[0].rotation.z = -fmod(mins / 60.0, 12.0) / 12.0 * TAU
		hm[1].rotation.z = -fmod(mins, 60.0) / 60.0 * TAU
	# The fire bell rings on the alarm; the dock officer hauls the rope.
	var ring := t - alarm_t
	var swing := 0.0
	if ring > 0.0 and ring < 6.0:
		swing = 0.55 * sin(ring * 9.0) * (1.0 - ring / 6.0)
	_bell.rotation.x = swing
	var rope_top := _bell.position + Vector3(0, -0.6, 0.3 * sin(swing))
	var rope_bot := TOWER + Vector3(-2.2, 1.3, -4.3)
	var bd: Dictionary = _p.get("bell", {})
	if not bd.is_empty() and ctx.has("actor"):
		var a = ctx["actor"].call(String(bd["actor"]))
		if a != null and a.visible:
			var pull := 0.18 * absf(sin(ring * 4.5)) if (ring > 0.0 and ring < 5.0) else 0.0
			var hw: Vector3 = gt * (rope_top.lerp(rope_bot, 0.55) + Vector3(0, -pull, 0))
			a.aim_hand("r", hw, 1.0)
			a.aim_hand("l", hw + Vector3(0, -0.22, 0), 0.9)
			rope_bot = inv * a.bone_world("hand_l")
	_set_rod(_rope, rope_top, rope_bot, 0.025)
	# Fire engines race down the quay from far +x and park by the gangway.
	var eng_t := _ft("engines")
	var parks := [Vector3(GANGWAY_X + 9.0, QH, QZ + 9.2), Vector3(GANGWAY_X + 22.0, QH, QZ + 9.5), Vector3(GANGWAY_X + 36.0, QH, QZ + 9.0)]
	for i in _engines.size():
		var arrive := eng_t + 1.6 + i * 0.5
		var start := arrive - 4.5
		var u := clampf((t - start) / (arrive - start), 0.0, 1.0)
		var e := 1.0 - pow(1.0 - u, 2.2)
		var pk: Vector3 = parks[i]
		var moving := u > 0.0 and u < 1.0
		_engines[i].position = (pk + Vector3(320.0, 0, 0)).lerp(pk, e) + Vector3(0, (0.04 * sin(t * 23.0 + i)) if moving else 0.0, 0)
		_engines[i].rotation.z = (0.02 * sin(t * 11.0 + i)) if moving else 0.0
		_engines[i].visible = t >= start - 0.01 and not post
	# Fireboats come alongside on the far (port) side.
	var boat_t := _ft("boats")
	for i in _boats.size():
		var arrive := boat_t + 2.0 + i * 0.8
		var u := Motion.out_cubic(clampf((t - (arrive - 6.0)) / 6.0, 0.0, 1.0))
		var spot := Vector3(HOLD2.x - 4.0 - i * 26.0, 0.0, -21.0 - i * 2.0)
		_boats[i].position = (spot + Vector3(160.0, 0, -40.0)).lerp(spot, u) + Vector3(0, 0.15 * sin(t * 1.3 + i), 0)
		_boats[i].rotation = Vector3(0.012 * sin(t * 1.1 + i), PI + (1.0 - u) * 0.25, 0.015 * sin(t * 0.9 + i * 2.0))
		_boats[i].visible = t >= arrive - 6.0 and not post
	_pose_crowd(t, abandon_t, blast_t)
	# The megaphone in the fire chief's hand.
	var md: Dictionary = _p.get("megaphone", {})
	_megaphone.visible = false
	if not md.is_empty() and ctx.has("actor") and t >= float(md.get("from", 0.0)) and not post:
		var a = ctx["actor"].call(String(md["actor"]))
		if a != null and a.visible:
			var raise := Motion.out_back(clampf((t - float(md["from"])) / 0.4, 0.0, 1.0), 1.4)
			var head: Vector3 = a.bone_world("head")
			var fwd := Vector3(sin(a.rotation.y), 0, cos(a.rotation.y))
			var chest: Vector3 = a.bone_world("spine_03")
			a.aim_hand("r", chest.lerp(head + fwd * 0.36 + Vector3(0, -0.12, 0), raise) + fwd * 0.08, 1.0)
			_megaphone.visible = true
			_megaphone.position = inv * (a.bone_world("hand_r") + fwd * 0.12)
			_megaphone.rotation = Vector3(0, a.rotation.y - gt.basis.get_euler().y - PI * 0.5, 0)
			_megaphone.scale = Vector3.ONE * 1.6
	# FX.
	FX.begin(_smoke)
	FX.begin(_fire)
	FX.begin(_spray)
	var vent := HOLD2 + Vector3(0, 1.0, 0)
	for h in _hoses:
		h.visible = false
	if not post:
		# Smoke from No. 2 hold: thin at first, thicker after the alarm, a black column by the abandon order.
		var grow := clampf((t - alarm_t) / 30.0, 0.0, 1.0) * 0.5 + clampf((t - hoses_t) / 15.0, 0.0, 1.0) * 0.3 + (0.4 if t > pops_t else 0.0)
		FX.plume(_smoke, vent, t, {"t0": smoke_t - 6.0, "rate": 7.0 + grow * 10.0, "life": 9.0 + grow * 7.0, "rise": 3.0 + grow * 4.0,
			"spread": 1.5 + grow * 2.5, "grow": 1.1 + grow * 1.6, "size0": 2.4 + grow * 3.0, "wind": Vector3(-1.6, 0, -0.8),
			"alpha": 0.72 + grow * 0.2, "dark": 0.5 + grow * 0.45, "glow": (0.8 if t > pops_t else 0.0), "seed": 11})
		if t > pops_t:
			FX.flames(_fire, vent + Vector3(0, 0.5, 0), Vector2(4.0, 3.0), t, {"t0": pops_t, "ramp": 3.0, "count": 16, "height": 6.0, "size": 4.5, "seed": 3})
			var k := int(floor((t - pops_t) / 0.45))
			var ph := fmod(t - pops_t, 0.45) / 0.45
			_hold_light.light_energy = 6.0 + 30.0 * (1.0 - ph) * (0.5 + 0.5 * _h(k, 9))
		else:
			_hold_light.light_energy = 0.0
		# Hose jets from the fireboats' monitors and the firemen's nozzles, arcing into the hold.
		if t > hoses_t:
			var targets := [HOLD2 + Vector3(-2, 2, 1), HOLD2 + Vector3(2, 2, -1), HOLD2 + Vector3(0, 2, 2)]
			var i := 0
			for b in _boats:
				if b.visible:
					var from: Vector3 = b.position + Vector3(0, 7.5, 0)
					FX.jet(_spray, from, _jet_vel(from, targets[i % 3], 1.2), t, {"t0": hoses_t + 0.3 * i, "rate": 70.0, "life": 2.0,
						"size0": 0.45, "grow": 2.0, "alpha": 0.45, "seed": 40 + i})
					i += 1
			var hi := 0
			for nz in _p.get("nozzles", []):
				var nd: Dictionary = nz
				if not ctx.has("actor"):
					break
				var a = ctx["actor"].call(String(nd["actor"]))
				if a == null or not a.visible:
					continue
				var hand: Vector3 = inv * a.bone_world("hand_r")
				var aim: Array = nd["aim"]
				var tgt := Vector3(float(aim[0]), float(aim[1]), float(aim[2]))
				FX.jet(_spray, hand, _jet_vel(hand, tgt, 0.9), t, {"t0": hoses_t, "rate": 160.0, "life": 1.3, "size0": 0.3, "grow": 1.2,
					"alpha": 0.32, "seed": 60 + i, "scatter": 0.4})
				i += 1
				if hi + 1 < _hoses.size():
					var ground := Vector3(hand.x - 0.4, QH + 0.06, hand.z + 0.6)
					_set_rod(_hoses[hi], hand, ground, 0.045)
					_set_rod(_hoses[hi + 1], ground, Vector3(GANGWAY_X + 9.0, QH + 0.06, QZ + 8.0), 0.045)
					_hoses[hi].visible = true
					_hoses[hi + 1].visible = true
					hi += 2
	else:
		_hold_light.light_energy = 0.0
	# The blast, and the second one.
	var ba := t - blast_t
	_flash.light_energy = 0.0
	if ba >= 0.0 and ba < 30.0 and not later:
		_flash.light_energy = 400.0 * exp(-ba * 6.0) + 40.0 * exp(-ba * 0.8)
		_blast_fx(ba, HOLD2, 1.0, 21)
	var sa := t - second_t
	if sa >= 0.0 and sa < 30.0 and not later:
		_flash.light_energy += 260.0 * exp(-sa * 6.0)
		_blast_fx(sa, HOLD2 + Vector3(-25, 0, 0), 0.7, 33)
	_debris_pose(ba)
	# After the blast (afternoon): the wreck burns, the sheds burn, a towering smoke column.
	if post and not later:
		FX.flames(_fire, Vector3(44, 3, 0), Vector2(18, 7), t, {"t0": blast_t + 0.5, "ramp": 2.0, "count": 40, "height": 14.0, "size": 9.0, "seed": 5})
		FX.flames(_fire, Vector3(-28, 3, 0), Vector2(28, 7), t, {"t0": blast_t + 0.8, "ramp": 2.0, "count": 40, "height": 12.0, "size": 8.0, "seed": 6})
		for k in 5:
			var x := -380.0 + k * 150.0 + 75.0
			FX.flames(_fire, Vector3(x * 0.6, QH + 6, QZ + 52), Vector2(40, 12), t, {"t0": blast_t + 1.5 + k * 0.2, "ramp": 3.0, "count": 14,
				"height": 10.0, "size": 8.0, "seed": 70 + k})
		FX.plume(_smoke, Vector3(10, 6, 0), t, {"t0": blast_t + 0.5, "rate": 10.0, "life": 18.0, "rise": 9.0, "spread": 22.0, "grow": 3.2,
			"size0": 16.0, "wind": Vector3(-3.0, 0, -1.5), "alpha": 0.85, "dark": 0.85, "glow": 0.7, "seed": 17, "slow": 0.2})
	# Night: everything burns; masts against the fire.
	if night:
		for k in 12:
			var c := Vector3(-330.0 + k * 60.0, QH + 2.0, QZ + 40.0 + (k % 3) * 12.0)
			FX.flames(_fire, c, Vector2(22, 8), t, {"t0": night_t - 10.0, "ramp": 0.1, "count": 12, "height": 12.0, "size": 10.0, "seed": 100 + k})
		for spec in [[Vector3(-150, 1, -146), 30.0], [Vector3(30, 1, -146), 34.0], [Vector3(205, 1, -146), 26.0], [Vector3(166, 1, 0), 30.0],
				[Vector3(15, 1, 0), 40.0]]:
			FX.flames(_fire, spec[0], Vector2(spec[1], 6), t, {"t0": night_t - 10.0, "ramp": 0.1, "count": 18, "height": 14.0, "size": 11.0,
				"seed": int(spec[1])})
		FX.plume(_smoke, Vector3(0, 10, 20), t, {"t0": night_t - 30.0, "rate": 8.0, "life": 20.0, "rise": 7.0, "spread": 120.0, "grow": 3.0,
			"size0": 20.0, "wind": Vector3(-2.0, 0, -1.0), "alpha": 0.75, "dark": 0.9, "glow": 1.0, "seed": 23, "slow": 0.2})
	for i in _night_lights.size():
		_night_lights[i].light_energy = (6.0 + 2.5 * sin(t * 7.0 + i * 1.7)) if night else 0.0
	for i in _fire_lights.size():
		_fire_lights[i].light_energy = (5.0 + 2.0 * sin(t * 9.0 + i)) if (post and not later) else 0.0
	# Dawn: smoke wisps over the ruins, a few embers.
	if dawn:
		for k in 8:
			var c := Vector3(-300.0 + k * 80.0, QH + 1.0, QZ + 45.0 + (k % 2) * 20.0)
			FX.plume(_smoke, c, t, {"t0": dawn_t - 20.0, "rate": 1.5, "life": 16.0, "rise": 2.0, "spread": 6.0, "grow": 1.5,
				"size0": 5.0, "wind": Vector3(-1.2, 0, -0.5), "alpha": 0.45, "dark": 0.5, "seed": 200 + k})
			FX.flames(_fire, c, Vector2(3, 2), t, {"t0": dawn_t - 5.0, "ramp": 0.1, "count": 3, "height": 1.2, "size": 1.2, "heat": 0.6, "seed": 300 + k})
	_helmets.visible = dawn and t >= _ft("helmets") - 0.01
	FX.finish(_smoke, cam_l, t)
	FX.finish(_fire, cam_l, t)
	FX.finish(_spray, cam_l, t)
	var smoke_c: Vector3 = vent + Vector3(-1.6, 1, -0.8) * clampf(t - smoke_t, 0.0, 6.0)
	return {"ship": gt * Vector3(0, 8, 0), "hold2": gt * HOLD2, "bow": gt * BOW, "foremast": gt * FOREMAST,
		"quay": gt * Vector3(0, QH, QZ + 6), "clock": gt * (TOWER + Vector3(0, TOWER_H - 3.2, -3.3)),
		"bell": gt * _bell.position, "crevier_fo": gt * Vector3(116.0, 9.2, -5.0),
		"jalapadma": gt * (_jala.position + Vector3(0, 10, 0)), "blast": gt * (HOLD2 + Vector3(0, 30, 0)),
		"gangway": gt * Vector3(GANGWAY_X, QH, QZ + 2.0), "smoke": gt * smoke_c}


func _jet_vel(from: Vector3, to: Vector3, flight: float) -> Vector3:
	var d := to - from
	return Vector3(d.x / flight, (d.y + 4.9 * flight * flight) / flight, d.z / flight)


func _blast_fx(a: float, c: Vector3, k: float, seed: int) -> void:
	# The fireball: white-hot puffs expanding from the hold, cooling to orange and turning to black smoke.
	var n := int(46 * k)
	for i in n:
		var dir := Vector3(_h(i, seed) - 0.5, _h(i, seed + 1) * 0.9 + 0.15, _h(i, seed + 2) - 0.5).normalized()
		var sp := (60.0 + 80.0 * _h(i, seed + 3)) * k
		var r := sp * (1.0 - exp(-a * 2.2)) / 2.2
		var p := c + dir * r + Vector3(0, a * 9.0 * k, 0)
		var sz := (14.0 + 34.0 * (1.0 - exp(-a * 1.2))) * k * (0.7 + 0.6 * _h(i, seed + 4))
		var heat := clampf(1.3 - a * 0.55, 0.0, 1.3)
		if a < 4.5:
			FX.add(_fire, p, sz * 1.1, Color(_h(i, seed + 5), heat, 0, clampf(1.0 - a / 4.5, 0.0, 1.0)))
		if a > 0.4:
			FX.add(_smoke, p + Vector3(0, 3.0, 0), sz * 1.25, Color(_h(i, seed + 6), clampf(1.2 - a * 0.3, 0.0, 1.0), 0.85,
				clampf((a - 0.4) / 1.2, 0.0, 0.92)))
	# The mushroom column: a stem rising to ~400 m and a cap rolling outward.
	var stem_h := 420.0 * k * (1.0 - exp(-a * 0.32))
	var ns := int(34 * k)
	for j in ns:
		var u := float(j) / float(ns)
		var w := (10.0 + 14.0 * u) * k
		var p := c + Vector3((_h(j, seed + 7) - 0.5) * w, u * stem_h, (_h(j, seed + 8) - 0.5) * w) + Vector3(-1.5, 0, -0.8) * a * u
		FX.add(_smoke, p, (18.0 + 16.0 * u) * k, Color(_h(j, seed + 9), clampf(0.9 - u - a * 0.1, 0.0, 1.0), 0.8, clampf(a * 1.5, 0.0, 0.9)))
	for j in int(30 * k):
		var ang := _h(j, seed + 10) * TAU
		var rr := (20.0 + 60.0 * _h(j, seed + 11)) * k * (1.0 - exp(-a * 0.5))
		var p := c + Vector3(cos(ang) * rr, stem_h + (_h(j, seed + 12) - 0.3) * 40.0 * k, sin(ang) * rr) + Vector3(-1.5, 0, -0.8) * a
		FX.add(_smoke, p, (34.0 + 30.0 * _h(j, seed + 13)) * k, Color(_h(j, seed + 14), clampf(0.6 - a * 0.1, 0.0, 1.0) * 0.6, 0.75,
			clampf(a * 0.8, 0.0, 0.9)))
	# A base surge of white spray rolling out over the water.
	if a < 6.0:
		for j in 40:
			var ang := _h(j, seed + 15) * TAU
			var rr := a * 55.0 * k
			FX.add(_spray, c + Vector3(cos(ang) * rr, 2.0 + _h(j, seed + 16) * 5.0, sin(ang) * rr), (10.0 + a * 6.0) * k,
				Color(_h(j, seed + 17), 0, 0, clampf(0.55 - a * 0.09, 0.0, 0.55)))
	# Burning cotton bales thrown out on arcs.
	for j in int(26 * k):
		var v := Vector3((_h(j, seed + 18) - 0.5) * 80.0, 40.0 + 45.0 * _h(j, seed + 19), (_h(j, seed + 20) - 0.3) * 80.0) * k
		var p := c + v * a + Vector3(0, -4.9 * a * a, 0)
		if p.y > 0.0:
			FX.add(_fire, p, 3.5, Color(_h(j, seed + 21), 1.0, 0, 1.0))
			FX.add(_smoke, p - v.normalized() * 4.0, 4.0, Color(_h(j, seed + 22), 0.4, 0.8, 0.6))


func _debris_pose(a: float) -> void:
	if a < 0.0 or a > 14.0:
		_debris.visible_instance_count = 0
		return
	var n := 0
	for i in _debris.instance_count:
		var v := Vector3((_h(i, 50) - 0.5) * 130.0, 30.0 + 70.0 * _h(i, 51), (_h(i, 52) - 0.4) * 130.0)
		var p := HOLD2 + v * a + Vector3(0, -4.9 * a * a, 0)
		if p.y < -2.0:
			continue
		var b := Basis.from_euler(Vector3(a * (2.0 + _h(i, 53) * 6.0), a * (1.0 + _h(i, 54) * 4.0), a * 3.0 * _h(i, 55)))
		_debris.set_instance_transform(n, Transform3D(b.scaled(Vector3.ONE * (0.6 + _h(i, 56) * 1.8)), p))
		n += 1
	_debris.visible_instance_count = n


func _pose_crowd(t: float, abandon_t: float, blast_t: float) -> void:
	var n := _crowd.instance_count
	if t >= blast_t:
		_crowd.visible_instance_count = 0
		_crowd_heads.visible_instance_count = 0
		return
	_crowd.visible_instance_count = n
	_crowd_heads.visible_instance_count = n
	for i in n:
		var spd := (0.9 + _h(i, 2) * 0.5) * (1.0 if _h(i, 3) > 0.5 else -1.0)
		var x := -260.0 + fmod(_h(i, 4) * 520.0 + t * spd + 5200.0, 520.0)
		var z := QZ + 24.0 + _h(i, 1) * 16.0
		if absf(x - TOWER.x) < 16.0 and absf(z - TOWER.z) < 12.0:
			z += 14.0
		var bob := absf(sin(t * 6.0 + i)) * 0.06
		var yaw := PI * 0.5 if spd > 0.0 else -PI * 0.5
		var run := clampf((t - abandon_t - _h(i, 5) * 1.5) / 6.0, 0.0, 1.0)
		if run > 0.0:
			z += run * 42.0
			bob = absf(sin(t * 11.0 + i)) * 0.12
			yaw = 0.0
		var base := Vector3(x, QH + 0.85 + bob, z)
		var bs := Basis(Vector3.UP, yaw)
		_crowd.set_instance_transform(i, Transform3D(bs, base))
		_crowd_heads.set_instance_transform(i, Transform3D(bs, base + Vector3(0, 0.82, 0)))


func _set_rod(mi: MeshInstance3D, a: Vector3, b: Vector3, r: float) -> void:
	var d := b - a
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = maxf(d.length(), 0.01)
	c.radial_segments = 6
	mi.mesh = c
	var y := d.normalized() if d.length() > 0.0001 else Vector3.UP
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT).normalized()
	mi.transform = Transform3D(Basis(x, y, x.cross(y)), (a + b) * 0.5)
