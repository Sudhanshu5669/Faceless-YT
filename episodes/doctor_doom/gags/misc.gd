## The smaller places, as areas of one gag:
##   HELL (0, 0, 0)       a red cavern over a lava river: Doom's green spell meets a towering horned shadow's red
##   HOSP (0, 0, 300)     a hospital room at night: the bed, a heart monitor, the red-and-gold helmet on the table
##   CITY (0, 0, 600)     a rooftop over a night city (Doom in his Iron Man armour stands here)
##   DRESS (0, 0, 900)    a dressing room: a bulb-ringed mirror, a vanity, a gold statuette, the folded cloak and mask
##   REELS (0, 0, 1200)   three film frames sliding past in the dark, a different Doom mask in each, year on the edge
##   CAMPUS (0, 0, 1500)  a university gate in the rain at night: iron gates, the arch sign, lamps, a lit building
##   MIRROR (0, 0, 1800)  a cheap room with a mirror: the reflection is a second figure behind the frame
##
## params:
##   clash   t   the two spells meet with sparks (HELL)
##   take    {"actor": id, "t": t}   the actor's hand takes the helmet from the table (HOSP)
##   slide   t   the film frames slide in, one by one, from t (REELS; each 1.3 s apart)
##   scar    {"actor": id, "warp": t}   a small scar on that actor's cheek; from `warp` his head distorts and the scar
##           grows (MIRROR, the reflection)
##   ironhead {"actor": id}   the actor's head (and Doom's mask) is replaced by the Iron Man helmet (Doom as Iron Man)
##   bandage {"actor": id}   a white bandage round that actor's head (CAMPUS)
## anchors: devil, doom_ledge, bed, helmet, roof, statue, reels, gate, window, mirror
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Paths = preload("res://scripts/core/paths.gd")

const HELL := Vector3(0, 0, 0)
const DEVIL := Vector3(9.0, -6.0, -11.0)   # the Devil's foot (in the lava), HELL-relative
const DEVIL_S := 2.0
const HOSP := Vector3(0, 0, 300)
const CITY := Vector3(0, 0, 600)
const DRESS := Vector3(0, 0, 900)
const REELS := Vector3(0, 0, 1200)
const CAMPUS := Vector3(0, 0, 1500)
const MIRROR := Vector3(0, 0, 1800)
const TABLE := Vector3(0, 0, 2100)   # reels_mcmahon: the Fox posters thrown down on a table
const TABLE_Y := 0.9

const LAVA_SHADER := """
shader_type spatial;
render_mode unshaded;
uniform float time = 0.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y); }
void fragment() {
	vec2 p = UV * 18.0 + vec2(time * 0.3, time * 0.1);
	float v = n(p) * 0.6 + n(p * 2.3 - time * 0.2) * 0.4;
	vec3 c = mix(vec3(0.5, 0.06, 0.0), vec3(1.0, 0.55, 0.1), smoothstep(0.35, 0.85, v));
	ALBEDO = c * 2.2;
}
"""

static var _suit: GDScript


static func suit_mask() -> Mesh:
	if _suit == null:
		_suit = GDScript.new()
		_suit.source_code = FileAccess.get_file_as_string(Paths.repo_path("library/gags/doom_suit.gd"))
		_suit.reload()
	return _suit.call("_mask", 1.0)



## The downloaded helmet (Sketchfab "Iron-Man Helmet (MK3)" by designpill, CC BY 4.0), if present: the first
## .gltf/.glb under incoming/ironman_helmet/, scaled so its height is `height` and centred on the node's origin.
static func helmet_model(height: float) -> Node3D:
	var dir := Paths.repo_path("incoming/ironman_helmet")
	var found := ""
	var stack := [dir]
	while not stack.is_empty() and found == "":
		var d: String = stack.pop_back()
		var da := DirAccess.open(d)
		if da == null:
			continue
		for f in da.get_files():
			if f.get_extension().to_lower() in ["gltf", "glb"]:
				found = d.path_join(f)
				break
		for sub in da.get_directories():
			stack.append(d.path_join(sub))
	if found == "":
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(found, state) != OK:
		return null
	var model := doc.generate_scene(state) as Node3D
	var holder := Node3D.new()
	holder.add_child(model)
	var bb := Kit.bounds(model)
	var s := height / maxf(bb.size.y, 0.001)
	model.scale = Vector3.ONE * s
	model.position = -(bb.position + bb.size * 0.5) * s
	return holder

var _p := {}
var _lava_mat: ShaderMaterial
var _green_beam: MeshInstance3D
var _red_beam: MeshInstance3D
var _clash_light: OmniLight3D
var _thrown: Array[Node3D] = []
var _sparks: MultiMesh
var _helmet: Node3D
var _monitor_line: MeshInstance3D
var _frames: Array[Node3D] = []
var _rain: MultiMesh
var _dressed := {}


func _helmet_node(parent: Node3D, r: float) -> Node3D:
	var h := Node3D.new()
	parent.add_child(h)
	var dl := helmet_model(r * 2.35)
	if dl != null:
		h.add_child(dl)
		return h
	Kit.ball(h, r, Vector3(0, 0.02, -0.05), Kit.mat("#a3121b", 0.28, 0.8), 24, Vector3(1.0, 1.1, 0.98))
	var plate := MeshInstance3D.new()
	plate.mesh = suit_mask()
	plate.material_override = Kit.mat("#d9a441", 0.25, 0.9)
	plate.scale = Vector3.ONE * r * 1.06
	plate.position = Vector3(0, -0.01, 0.03)
	h.add_child(plate)
	for s: float in [-1.0, 1.0]:
		Kit.box(h, Vector3(r * 0.46, r * 0.12, 0.01), Vector3(s * r * 0.4, r * 0.075, r * 0.94), Kit.lit("#dff4ff", 2.0), Vector3(0, s * 0.35, s * -0.18))
	return h


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "misc"))
	var rng := Kit.rng("misc")
	# HELL.
	var rock := Kit.mat("#2a1612", 0.95)
	Kit.box(root, Vector3(80, 1, 80), HELL + Vector3(0, -6.5, 0), rock)
	_lava_mat = Kit.shader(LAVA_SHADER)
	var lava := Kit.quad(root, Vector2(60, 60), HELL + Vector3(0, -5.9, 0), _lava_mat, Vector3(-PI / 2, 0, 0))
	lava.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 30:
		var a := rng.randf() * TAU
		var d := rng.randf_range(14, 30)
		var hgt := rng.randf_range(10, 28)
		Kit.cyl(root, 0.0, rng.randf_range(2, 5), hgt, HELL + Vector3(cos(a) * d, hgt * 0.5 - 6, sin(a) * d), rock, 7)
		Kit.cyl(root, rng.randf_range(1.5, 3.5), 0.0, rng.randf_range(4, 10), HELL + Vector3(cos(a + 0.3) * d * 0.7, 16, sin(a + 0.3) * d * 0.7), rock, 7)
	Kit.box(root, Vector3(4, 6, 4), HELL + Vector3(-5, -3, 2), rock)
	Kit.omni(root, HELL + Vector3(0, -3, 0), "#ff5a1a", 12.0, 40.0, false, 1.5)
	Kit.spot(root, HELL + Vector3(2, -5, 4), HELL + Vector3(6, 6, -6), "#ff6a2a", 40.0, 30.0, 35.0, true, 0.6)
	Kit.spot(root, HELL + Vector3(10, 14, -14), HELL + Vector3(6, 7, -6), "#ffb08a", 30.0, 30.0, 25.0, false, 1.0)
	# A furnace glow behind the shadow so his silhouette reads against it.
	Kit.omni(root, HELL + Vector3(8, 4, -16), "#ff6a1a", 60.0, 30.0, false, 3.0)
	var back := Kit.quad(root, Vector2(40, 24), HELL + Vector3(6, 6, -18), Kit.lit("#ff4a10", 0.9))   # dimmer: its bloom ate Doom's silhouette
	back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The horned shadow: a towering silhouette (twice the old size, pure unlit black so the haze and the lava light
	# can't grey it out), red eyes. DEVIL = its foot, DEVIL_S = its scale.
	var shadow := StandardMaterial3D.new()
	shadow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.albedo_color = Color(0.0, 0.0, 0.0)
	shadow.disable_fog = true
	var dv := DEVIL
	var dk := DEVIL_S
	Kit.cyl(root, 1.2 * dk, 2.6 * dk, 9.0 * dk, dv + Vector3(0, 4.5, 0) * dk, shadow, 12)
	Kit.ball(root, 1.4 * dk, dv + Vector3(0, 10.0, 0) * dk, shadow, 16)
	for s: float in [-1.0, 1.0]:
		Kit.rod(root, dv + Vector3(s * 0.8, 10.8, 0) * dk, dv + Vector3(s * 2.0, 13.0, 0.4) * dk, 0.3 * dk, shadow, 8, 0.02 * dk)
		Kit.ball(root, 0.2 * dk, dv + Vector3(s * 0.45, 10.1, 1.25) * dk, Kit.lit("#ff2a1a", 12.0), 8)
		Kit.rod(root, dv + Vector3(s * 2.0, 7.5, 0) * dk, dv + Vector3(s * 3.4, 4.0, 2.0) * dk, 0.5 * dk, shadow, 8, 0.2 * dk)
	# The beams.
	var gb := CylinderMesh.new()
	gb.top_radius = 0.12
	gb.bottom_radius = 0.12
	gb.height = 1.0
	_green_beam = MeshInstance3D.new()
	_green_beam.mesh = gb
	_green_beam.material_override = Kit.lit("#4dff7a", 6.0)
	root.add_child(_green_beam)
	_red_beam = MeshInstance3D.new()
	_red_beam.mesh = gb
	_red_beam.material_override = Kit.lit("#ff3a1a", 6.0)
	root.add_child(_red_beam)
	_clash_light = Kit.omni(root, HELL, "#ffffff", 0.0, 14.0, false, 1.0)
	var sm := BoxMesh.new()
	sm.size = Vector3(0.02, 0.02, 0.15)
	_sparks = MultiMesh.new()
	_sparks.transform_format = MultiMesh.TRANSFORM_3D
	_sparks.mesh = sm
	_sparks.instance_count = 120
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = _sparks
	smi.material_override = Kit.lit("#ffd27a", 6.0)
	smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(smi)
	# HOSP.
	var ho := Node3D.new()
	ho.position = HOSP
	root.add_child(ho)
	Kit.box(ho, Vector3(8, 0.1, 7), Vector3(0, -0.05, 0), Kit.mat("#8a9a9a", 0.4))
	Kit.box(ho, Vector3(8, 3.2, 0.2), Vector3(0, 1.6, -2.6), Kit.mat("#a8b8b8", 0.8))
	for s: float in [-1.0, 1.0]:
		Kit.box(ho, Vector3(0.2, 3.2, 7), Vector3(s * 4.0, 1.6, 0), Kit.mat("#a8b8b8", 0.8))
	Kit.box(ho, Vector3(1.1, 0.5, 2.2), Vector3(0, 0.35, -1.2), Kit.mat("#d8dcdc", 0.5, 0.4))
	Kit.box(ho, Vector3(1.0, 0.18, 2.1), Vector3(0, 0.69, -1.2), Kit.mat("#eef0f2", 0.9))
	Kit.box(ho, Vector3(1.0, 0.7, 0.06), Vector3(0, 0.95, -2.3), Kit.mat("#c8ccd0", 0.4, 0.5))
	Kit.box(ho, Vector3(0.6, 0.12, 0.35), Vector3(0, 0.84, -2.0), Kit.mat("#f4f6f8", 0.9))
	for s: float in [-1.0, 1.0]:
		Kit.rod(ho, Vector3(s * 0.55, 0.8, -1.8), Vector3(s * 0.55, 0.8, -0.4), 0.02, Kit.mat("#c8ccd0", 0.3, 0.8), 8)
	Kit.box(ho, Vector3(0.6, 0.6, 0.5), Vector3(1.0, 0.3, -1.9), Kit.mat("#c8ccd0", 0.5, 0.4))
	_helmet = _helmet_node(ho, 0.2)
	_helmet.position = Vector3(1.0, 0.82, -1.9)
	_helmet.rotation = Vector3(0, -0.5, 0)
	Kit.box(ho, Vector3(0.5, 0.35, 0.3), Vector3(-1.0, 1.4, -2.2), Kit.mat("#1a1c20", 0.4, 0.5))
	Kit.box(ho, Vector3(0.44, 0.28, 0.02), Vector3(-1.0, 1.4, -2.04), Kit.lit("#0a2a1a", 1.0))
	_monitor_line = MeshInstance3D.new()
	_monitor_line.mesh = ImmediateMesh.new()
	_monitor_line.material_override = Kit.lit("#4dff7a", 4.0)
	ho.add_child(_monitor_line)
	Kit.omni(ho, Vector3(-1.0, 1.4, -1.7), "#4dff7a", 0.8, 3.0, false, 0.2)
	var win := Kit.box(ho, Vector3(0.05, 1.6, 2.0), Vector3(3.9, 1.7, -0.4), Kit.lit("#1a2a4a", 0.6))
	win.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Kit.spot(ho, Vector3(3.5, 2.6, -0.4), Vector3(0, 0.8, -1.2), "#8fa8e8", 6.0, 8.0, 40.0, true, 0.3)
	Kit.omni(ho, Vector3(0, 2.8, 0.5), "#c8d8e8", 0.8, 8.0, false, 0.1)
	# CITY: a rooftop and a skyline.
	var ci := Node3D.new()
	ci.position = CITY
	root.add_child(ci)
	Kit.box(ci, Vector3(12, 1, 12), Vector3(0, -0.5, 0), Kit.mat("#3a3c40", 0.8))
	Kit.box(ci, Vector3(12, 0.6, 0.3), Vector3(0, 0.3, 6.0), Kit.mat("#4a4c50", 0.8))
	var lit := Kit.lit("#ffd9a0", 2.2)
	for i in 70:
		var bw := rng.randf_range(6, 16)
		var bh := rng.randf_range(20, 110)
		var p := Vector3(rng.randf_range(-160, 160), -40 + bh * 0.5, rng.randf_range(30, 220))
		Kit.box(ci, Vector3(bw, bh, bw), p, Kit.mat("#1c2028", 0.8)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for w in 4:
			var wl := Kit.box(ci, Vector3(bw * 0.7, 0.9, 0.2), Vector3(p.x, p.y - bh * 0.4 + rng.randf() * bh * 0.8, p.z - bw * 0.5 - 0.1), lit)
			wl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Kit.spot(ci, Vector3(-4, 6, -6), Vector3(0, 1.2, 0), "#9fb8ff", 14.0, 14.0, 30.0, true, 0.3)
	Kit.spot(ci, Vector3(1.5, 3.0, 1.0), Vector3(0, 1.3, 4.5), "#ffd0b0", 12.0, 8.0, 35.0, true, 0.2)
	Kit.spot(ci, Vector3(0, 3.5, 9.0), Vector3(0, 1.5, 4.5), "#7fa0ff", 10.0, 10.0, 30.0, false, 0.4)
	Kit.spot(ci, Vector3(3, 2, 5), Vector3(0, 1.2, 0), "#ff6a4a", 5.0, 10.0, 40.0, false, 0.2)
	# DRESS.
	var dr := Node3D.new()
	dr.position = DRESS
	root.add_child(dr)
	Kit.box(dr, Vector3(6, 0.1, 5), Vector3(0, -0.05, 0), Kit.mat("#3a2a24", 0.6))
	Kit.box(dr, Vector3(6, 3, 0.2), Vector3(0, 1.5, -1.6), Kit.mat("#4a3a40", 0.8))
	Kit.box(dr, Vector3(2.4, 0.06, 0.7), Vector3(0, 0.75, -1.2), Kit.mat("#2a1e18", 0.4))
	Kit.box(dr, Vector3(2.4, 0.73, 0.6), Vector3(0, 0.36, -1.2), Kit.mat("#2a1e18", 0.5))
	Kit.box(dr, Vector3(1.6, 1.0, 0.04), Vector3(0, 1.45, -1.48), Kit.mat("#b8c4cc", 0.05, 0.9))
	for k in 16:
		var u := float(k) / 16.0
		var bp := Vector3.ZERO
		if u < 0.5:
			bp = Vector3(-0.85, 0.95 + u * 2.0 * 1.0, -1.45)
		else:
			bp = Vector3(0.85, 0.95 + (u - 0.5) * 2.0 * 1.0, -1.45)
		Kit.ball(dr, 0.05, bp, Kit.lit("#fff2d8", 4.0), 10)
	Kit.omni(dr, Vector3(0, 1.5, -1.0), "#ffe8c8", 2.0, 5.0, true, 0.2)
	var gold := Kit.mat("#d8aa3a", 0.25, 0.95)
	var st := Node3D.new()
	st.position = Vector3(-0.6, 0.78, -1.1)
	dr.add_child(st)
	Kit.cyl(st, 0.07, 0.08, 0.08, Vector3(0, 0.04, 0), Kit.mat("#1a1a1a", 0.4), 16)
	Kit.cyl(st, 0.03, 0.04, 0.24, Vector3(0, 0.2, 0), gold, 12)
	Kit.ball(st, 0.035, Vector3(0, 0.35, 0), gold, 12)
	Kit.box(dr, Vector3(0.5, 0.06, 0.35), Vector3(0.55, 0.81, -1.1), Kit.mat("#1f5229", 0.8))
	var mk := MeshInstance3D.new()
	mk.mesh = suit_mask()
	mk.material_override = Kit.mat("#8a9096", 0.45, 0.7)
	mk.scale = Vector3.ONE * 0.16
	mk.position = Vector3(0.55, 0.92, -1.1)
	mk.rotation = Vector3(-1.2, 0.2, 0)
	dr.add_child(mk)
	# REELS: three frames.
	for i in 3:
		var fr := Node3D.new()
		root.add_child(fr)
		Kit.box(fr, Vector3(3.2, 2.4, 0.02), Vector3.ZERO, Kit.lit("#e8dcc0", 0.25))
		for s: float in [-1.0, 1.0]:
			Kit.box(fr, Vector3(3.6, 0.35, 0.025), Vector3(0, s * 1.35, 0), Kit.mat("#141414", 0.6))
			for k in 10:
				Kit.box(fr, Vector3(0.14, 0.14, 0.03), Vector3(-1.6 + k * 0.36, s * 1.35, 0), Kit.lit("#e8dcc0", 0.4))
		# The film's real poster (Wikipedia, commentary use) on the frame.
		var pm := Kit.textured("library/logos/doom/posters/" + ["ff2005.jpg", "ff2007.jpg", "ff2015.jpg"][i]).duplicate()
		pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var pq := Kit.quad(fr, Vector2(1.5, 2.22), Vector3(0, 0, 0.06), pm)   # >= 4 float steps proud at z 221 km
		pq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var yr := Kit.text(fr, ["2005", "2007", "2015"][i], 0.18, Color("#f2e6c8"), Vector3(1.2, -1.35, 0.08), Vector3.ZERO, true, 1.2)
		yr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_frames.append(fr)
	Kit.spot(root, REELS + Vector3(0, 3, 6), REELS, "#fff0d8", 8.0, 14.0, 40.0, false, 0.4)
	# CAMPUS.
	var ca := Node3D.new()
	ca.position = CAMPUS
	root.add_child(ca)
	Kit.box(ca, Vector3(60, 0.1, 60), Vector3(0, -0.05, 0), Kit.mat("#14161a", 0.08, 0.0, 0.9))
	var brick := Kit.mat("#5a2e24", 0.85)
	Kit.box(ca, Vector3(30, 14, 8), Vector3(0, 7, -16), brick)
	for r in 3:
		for c in 10:
			var w := Kit.box(ca, Vector3(1.2, 1.8, 0.2), Vector3(-12.6 + c * 2.8, 2.5 + r * 4.0, -11.9),
				Kit.lit("#ffcf8a", 2.0) if (r * 3 + c) % 4 != 0 else Kit.mat("#141414", 0.4))
			w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var iron := Kit.mat("#141414", 0.4, 0.7)
	for s: float in [-1.0, 1.0]:
		Kit.box(ca, Vector3(1.2, 4.2, 1.2), Vector3(s * 3.2, 2.1, -2.0), Kit.mat("#7a6a5a", 0.8))
		for k in 9:
			Kit.rod(ca, Vector3(s * (0.3 + k * 0.3), 0, -2.0), Vector3(s * (0.3 + k * 0.3), 3.0, -2.0), 0.03, iron, 6)
		Kit.ball(ca, 0.3, Vector3(s * 3.2, 4.6, -2.0), Kit.lit("#ffd9a0", 3.0), 12)
		Kit.omni(ca, Vector3(s * 3.2, 4.6, -1.5), "#ffc880", 4.0, 12.0, true, 0.6)
	Kit.box(ca, Vector3(7.6, 0.6, 0.3), Vector3(0, 4.6, -2.0), iron)
	var sign := Kit.text(ca, "EMPIRE STATE UNIVERSITY", 0.32, Color("#e8dcc0"), Vector3(0, 4.6, -1.82), Vector3.ZERO, true, 1.1)
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var drop := BoxMesh.new()
	drop.size = Vector3(0.006, 0.4, 0.006)
	_rain = MultiMesh.new()
	_rain.transform_format = MultiMesh.TRANSFORM_3D
	_rain.mesh = drop
	_rain.instance_count = 1400
	var rmi := MultiMeshInstance3D.new()
	rmi.multimesh = _rain
	var rmat := Kit.mat("#9fb4d0", 0.2).duplicate()
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.albedo_color = Color(0.7, 0.8, 0.95, 0.35)
	rmi.material_override = rmat
	rmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ca.add_child(rmi)
	# MIRROR: a cheap room; the mirror frame is an opening onto the reflection's side.
	var mi := Node3D.new()
	mi.position = MIRROR
	root.add_child(mi)
	Kit.box(mi, Vector3(8, 0.1, 8), Vector3(0, -0.05, 0), Kit.mat("#4a3a2e", 0.7))
	Kit.box(mi, Vector3(3.0, 3.0, 0.2), Vector3(-2.2, 1.5, 0), Kit.mat("#7a7458", 0.9))
	Kit.box(mi, Vector3(3.0, 3.0, 0.2), Vector3(2.2, 1.5, 0), Kit.mat("#7a7458", 0.9))
	Kit.box(mi, Vector3(1.4, 0.9, 0.2), Vector3(0, 0.45, 0), Kit.mat("#7a7458", 0.9))
	Kit.box(mi, Vector3(1.4, 0.9, 0.2), Vector3(0, 2.55, 0), Kit.mat("#7a7458", 0.9))
	for s: float in [-1.0, 1.0]:
		Kit.box(mi, Vector3(0.08, 1.3, 0.24), Vector3(s * 0.7, 1.55, 0), Kit.mat("#6a5030", 0.6))
		Kit.box(mi, Vector3(1.48, 0.08, 0.24), Vector3(0, 1.55 + s * 0.65, 0), Kit.mat("#6a5030", 0.6))
	Kit.box(mi, Vector3(8, 3, 0.2), Vector3(0, 1.5, -4.0), Kit.mat("#7a7458", 0.9))
	Kit.ball(mi, 0.08, Vector3(0, 2.8, 1.5), Kit.lit("#ffe0a8", 4.0), 10)
	Kit.omni(mi, Vector3(0, 2.6, 1.5), "#ffd8a0", 3.0, 7.0, true, 0.3)
	Kit.omni(mi, Vector3(0, 2.6, -1.5), "#ffd8a0", 3.0, 7.0, true, 0.3)
	# TABLE: a dark wooden table under one hanging lamp; the real FF (2005) and FF: Rise of the Silver Surfer (2007)
	# one-sheets are thrown down on it, one per year (params.thrown = [t2005, t2007]).
	var tb := Node3D.new()
	tb.position = TABLE
	root.add_child(tb)
	var wood := Kit.mat("#3a2414", 0.55)
	Kit.box(tb, Vector3(2.6, 0.08, 1.6), Vector3(0, TABLE_Y - 0.04, 0), wood)
	for lx: float in [-1.15, 1.15]:
		for lz: float in [-0.65, 0.65]:
			Kit.box(tb, Vector3(0.08, TABLE_Y - 0.08, 0.08), Vector3(lx, (TABLE_Y - 0.08) * 0.5, lz), wood)
	Kit.box(tb, Vector3(30, 0.1, 30), Vector3(0, -0.05, 0), Kit.mat("#0c0b0a", 0.9))
	Kit.cyl(tb, 0.02, 0.3, 0.22, Vector3(0, 2.25, 0), Kit.mat("#1a1a1a", 0.5, 0.6), 24)
	Kit.ball(tb, 0.05, Vector3(0, 2.15, 0), Kit.lit("#ffe6b8", 6.0), 10)
	Kit.spot(tb, Vector3(0, 2.15, 0), Vector3(0, TABLE_Y, 0), "#ffdcab", 3.2, 4.0, 48.0, true, 0.05)
	for i in 3:
		var pm := Kit.textured("library/logos/doom/posters/" + ["ff2005.jpg", "ff2007.jpg", "ff2015.jpg"][i]).duplicate()
		pm.roughness = 0.45
		var pn := Node3D.new()
		tb.add_child(pn)
		# One-sheets are 27 x 40 in; face up (+Y), 1 cm apart so they never z-fight.
		var q := Kit.quad(pn, Vector2(0.62, 0.92), Vector3.ZERO, pm, Vector3(-PI / 2, 0, 0))
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		pn.visible = false
		_thrown.append(pn)
	return root


func _dress_once(a: Node3D, key: String, f: Callable) -> void:
	var k := key + String(a.name)
	if _dressed.has(k):
		return
	var head := a.find_child("toon_head", true, false) as Node3D
	if head == null:
		return
	_dressed[k] = true
	f.call(head)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var inv: Transform3D = node.global_transform.affine_inverse()
	_lava_mat.set_shader_parameter("time", t)
	# HELL: beams from Doom's hand (the ledge) and the shadow's hand, meeting in the middle.
	var from_g := HELL + Vector3(-4.6, 1.4, 2.4)
	var from_r := HELL + DEVIL + Vector3(-3.4, 4.0, 2.0) * DEVIL_S   # the Devil's near hand
	var meet := (from_g + from_r) * 0.5 + Vector3(0.3 * sin(t * 3.0), 0.2 * sin(t * 4.1), 0)
	for pair in [[_green_beam, from_g], [_red_beam, from_r]]:
		var b: MeshInstance3D = pair[0]
		var a: Vector3 = pair[1]
		var dir := meet - a
		b.transform = Transform3D(Basis.looking_at(dir.normalized(), Vector3.UP) * Basis.from_euler(Vector3(-PI / 2, 0, 0)), (a + meet) * 0.5)
		b.scale = Vector3(1.0 + 0.3 * sin(t * 20.0), dir.length(), 1.0 + 0.3 * sin(t * 20.0))
	var ct := float(_p.get("clash", 1e9))
	var cl := Motion.smooth(Motion.seg(t, ct - 0.2, ct + 0.3))
	_green_beam.visible = t >= ct - 0.6
	_red_beam.visible = t >= ct - 0.6
	_clash_light.position = meet
	_clash_light.light_energy = 20.0 * cl * (0.8 + 0.2 * sin(t * 30.0))
	var hidden := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.001), Vector3(0, -50, 0))
	var rng := RandomNumberGenerator.new()
	for i in _sparks.instance_count:
		rng.seed = 600 + i
		var k := fposmod(t * 1.5 + rng.randf(), 1.0)
		if cl <= 0.0:
			_sparks.set_instance_transform(i, hidden)
			continue
		var v := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 1), rng.randf_range(-1, 1)).normalized() * 4.0
		_sparks.set_instance_transform(i, Transform3D(Basis.looking_at(v.normalized(), Vector3.UP), meet + v * k * 0.6 + Vector3(0, -2.0 * k * k, 0)))
	# HOSP: the monitor line; the helmet taken.
	var im := _monitor_line.mesh as ImmediateMesh
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var prev := Vector3.ZERO
	for i in 41:
		var u := float(i) / 40.0
		var ph := fposmod(u * 2.0 - t * 0.8, 1.0)
		var y := 0.0
		if ph > 0.45 and ph < 0.5:
			y = 0.1 * sin((ph - 0.45) / 0.05 * PI)
		elif ph > 0.5 and ph < 0.53:
			y = -0.04
		var q := Vector3(-1.2 + u * 0.4, 1.4 + y, -2.025)
		if i > 0:
			var w := Vector3(0, 0.004, 0)
			for vv in [prev - w, prev + w, q + w, prev - w, q + w, q - w]:
				im.surface_add_vertex(vv - HOSP + HOSP)
		prev = q
	im.surface_end()
	var td: Dictionary = _p.get("take", {})
	if td.has("actor") and ctx.has("actor"):
		var a = ctx["actor"].call(String(td["actor"]))
		var tt := float(td.get("t", 1e9))
		if a != null:
			var reach := Motion.in_out(Motion.seg(t, tt - 0.6, tt))
			var lift := Motion.in_out(Motion.seg(t, tt, tt + 0.8))
			var rest := Vector3(1.0, 0.82, -1.9)
			var held: Vector3 = inv * a.bone_world("hand_r") - HOSP + Vector3(0, 0.12, 0)
			if reach > 0.0 and lift <= 0.0:
				a.aim_hand("r", node.global_transform * (HOSP + rest + Vector3(0, 0.15, 0)), reach)
			_helmet.position = rest.lerp(held, lift)
			if lift > 0.0:
				a.aim_hand("r", node.global_transform * (HOSP + rest.lerp(rest + Vector3(-0.3, 0.6, 0.6), lift)), 1.0)
				_helmet.position = rest.lerp(rest + Vector3(-0.3, 0.75, 0.6), lift)
	# REELS slide in.
	var sl := float(_p.get("slide", 1e9))
	var slides: Array = _p.get("slides", [sl, sl + 1.3, sl + 2.6])
	for i in _frames.size():
		var ti := float(slides[i])
		var k := Motion.out_cubic(Motion.seg(t, ti, ti + 0.6))
		var drift := (t - ti) * 0.15
		_frames[i].position = REELS + Vector3(lerpf(9.0, 0.0, k) - maxf(drift, 0.0), 0, -0.5 * i)
		_frames[i].visible = k > 0.0
		if i < _frames.size() - 1:
			var tn := float(slides[i + 1])
			var nxt := Motion.in_cubic(Motion.seg(t, tn - 0.2, tn + 0.4))
			_frames[i].position.x -= 9.0 * nxt
	# CAMPUS rain.
	for i in _rain.instance_count:
		rng.seed = 2000 + i
		var x := rng.randf_range(-12, 12)
		var z := rng.randf_range(-6, 12)
		var y := fposmod(rng.randf() * 10.0 - t * 9.0, 10.0)
		_rain.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(x, y, z)))
	# Scar and bandage dressing.
	if ctx.has("actor"):
		var sd: Dictionary = _p.get("scar", {})
		if sd.has("actor"):
			var a2 = ctx["actor"].call(String(sd["actor"]))
			if a2 != null:
				_dress_once(a2, "scar", func(head: Node3D):
					var scar := Kit.box(head, Vector3(0.012, 0.07, 0.01), Vector3(0.1, -0.02, 0.255), Kit.mat("#c0605a", 0.6), Vector3(0, 0.3, 0.4))
					scar.name = "scar")
				var head := a2.find_child("toon_head", true, false) as Node3D
				if head != null:
					var wt := float(sd.get("warp", 1e9))
					var wk := Motion.in_out(Motion.seg(t, wt, wt + 1.8))
					head.scale = Vector3(1.0 + 0.25 * wk * sin(t * 3.0), 1.0 - 0.15 * wk * cos(t * 2.3), 1.0)
					var sc := head.find_child("scar", false, false) as Node3D
					if sc != null:
						sc.scale = Vector3(1.0 + 8.0 * wk, 1.0 + 3.0 * wk, 1.0)
		var ih: Dictionary = _p.get("ironhead", {})
		if ih.has("actor"):
			var a4 = ctx["actor"].call(String(ih["actor"]))
			if a4 != null:
				var head4 := a4.find_child("toon_head", true, false) as Node3D
				if head4 != null:
					if head4.get_node_or_null("iron_head") == null:
						var hm4 := head4.get_node_or_null("head") as MeshInstance3D
						var hr4 := hm4.get_aabb().size.x * 0.5 if hm4 != null else 0.28
						var ir := helmet_model(hr4 * 2.6)
						if ir != null:
							ir.name = "iron_head"
							head4.add_child(ir)
					for c in head4.get_children():
						(c as Node3D).visible = String(c.name) == "iron_head"
		var bd: Dictionary = _p.get("bandage", {})
		if bd.has("actor"):
			var a3 = ctx["actor"].call(String(bd["actor"]))
			if a3 != null:
				_dress_once(a3, "bandage", func(head: Node3D):
					var hm := head.get_node_or_null("head") as MeshInstance3D
					var hr := hm.get_aabb().size.x * 0.5 if hm != null else 0.28
					var tor := TorusMesh.new()
					tor.inner_radius = hr * 0.96
					tor.outer_radius = hr * 1.08
					var b := MeshInstance3D.new()
					b.mesh = tor
					b.material_override = Kit.mat("#f2f0ea", 0.9)
					b.position = Vector3(0, hr * 0.35, 0)
					b.rotation = Vector3(0.25, 0, 0.1)
					head.add_child(b))
	# TABLE: each poster sails in from above the lens, flat-spinning, slaps down on its word and skids to rest.
	var th: Array = _p.get("thrown", [])
	for i in _thrown.size():
		var pn := _thrown[i]
		var tl := float(th[i]) if i < th.size() else 1e9
		pn.visible = t >= tl - 0.45
		if not pn.visible:
			continue
		var land: Vector3 = [Vector3(-0.22, 0, 0.32), Vector3(0.22, 0, 0.24), Vector3(0.0, 0, 0.36)][i] + Vector3(0, TABLE_Y + 0.004 + 0.01 * i, 0)
		var yaw_rest: float = [0.12, -0.2, 0.05][i]
		var start: Vector3 = land + Vector3([-1.4, 1.6, 0.2][i], 1.3, 1.6)
		var k := Motion.in_cubic(Motion.seg(t, tl - 0.45, tl))
		var skid := Motion.out_cubic(Motion.seg(t, tl, tl + 0.3))
		var pos: Vector3 = start.lerp(land, k) + Vector3([-0.06, 0.07, 0.0][i], 0, -0.05) * skid
		pos.y += sin(k * PI) * 0.25
		var tilt := (1.0 - k) * 0.9
		var spin: float = yaw_rest + (1.0 - k) * float([2.4, -2.8, 3.1][i]) + 0.06 * skid
		var sq := Motion.squash(Motion.impact(t - tl, 0.12, 6.0, 12.0)) if t > tl else Vector3.ONE
		pn.transform = Transform3D(Basis(Vector3.UP, spin) * Basis(Vector3.RIGHT, tilt), pos).scaled_local(Vector3(sq.x, 1.0, sq.z))
	return {"devil": node.global_transform * (HELL + DEVIL + Vector3(0, 10, 0) * DEVIL_S), "doom_ledge": node.global_transform * (HELL + Vector3(-5, 0, 2)),
		"bed": node.global_transform * (HOSP + Vector3(0, 0.8, -1.2)), "helmet": node.global_transform * (HOSP + _helmet.position),
		"roof": node.global_transform * CITY, "statue": node.global_transform * (DRESS + Vector3(-0.6, 1.0, -1.1)),
		"reels": node.global_transform * REELS, "gate": node.global_transform * (CAMPUS + Vector3(0, 2, -2)),
		"window": node.global_transform * (CAMPUS + Vector3(-1.4, 6.5, -11.9)), "mirror": node.global_transform * (MIRROR + Vector3(0, 1.55, 0))}
