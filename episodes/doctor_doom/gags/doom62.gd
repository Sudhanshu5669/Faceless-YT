## Fantastic Four #5 (1962), Doom's first story, in two areas:
##   LAB (origin): Doom's castle laboratory, 1962 pulp style: stone walls, banks of dials and blinking lamps, a force-
##       field cage (a glowing cyan cylinder) holding the Invisible Woman, and the time platform (a ring of coils round a
##       disc) that flashes to send the others back in time; on `chest` Blackbeard's chest lands at Doom's feet.
##   SEA (400, 0, 0): Blackbeard's ship (Quaternius sail ship, CC0) rolling on a stormy night sea, rain, lightning; the
##       treasure chest hauled up over the rail on `haul`; a tricorn hat for the Thing.
##
## params:
##   platform  t   the time platform charges (0.8 s) and flashes white; whoever stands on it is gone after t
##   gone      [actor ids]   the actors who vanish on the platform's flash
##   chest     t   the chest appears on the lab floor at (0.9, 0, 1.2) with a flash
##   haul      t   the chest rises on a rope from the sea to the deck (1.5 s)
##   hat       {"actor": id}   a black tricorn hat on that actor
##   lightning [t, ...]
## anchors: cage, platform, chest_lab, ship, chest_sea
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const SEA := Vector3(400, 0, 0)
const PLATFORM := Vector3(-2.2, 0, -1.5)
const CAGE := Vector3(2.4, 0, -1.8)
const CHEST_LAB := Vector3(0.9, 0, 1.2)
const SHIP := "incoming/quaternius_ships/sail_ship.glb"

var _p := {}
var _plat_mat: StandardMaterial3D
var _plat_light: OmniLight3D
var _flash: OmniLight3D
var _cage_mat: StandardMaterial3D
var _lamps: Array[MeshInstance3D] = []
var _lamp_on: StandardMaterial3D
var _lamp_off: StandardMaterial3D
var _chest_lab: Node3D
var _ship: Node3D
var _chest_sea: Node3D
var _rope: MeshInstance3D
var _rain: MultiMesh
var _bolt: OmniLight3D
var _hat_done := false


func _chest(parent: Node3D) -> Node3D:
	var c := Node3D.new()
	parent.add_child(c)
	var oak := Kit.mat("#5a3a20", 0.7)
	var brass := Kit.mat("#c89a3a", 0.3, 0.85)
	Kit.box(c, Vector3(0.8, 0.45, 0.5), Vector3(0, 0.225, 0), oak)
	Kit.cyl(c, 0.25, 0.25, 0.8, Vector3(0, 0.45, 0), oak, 16, Vector3(0, 0, PI / 2))
	for s: float in [-1.0, 1.0]:
		Kit.box(c, Vector3(0.05, 0.7, 0.52), Vector3(s * 0.3, 0.35, 0), brass)
	var glow := Kit.box(c, Vector3(0.6, 0.03, 0.3), Vector3(0, 0.47, 0.18), Kit.lit("#4dff7a", 2.0))
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return c


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "doom62"))
	# LAB.
	var stone := Kit.mat("#3a3c40", 0.9)
	Kit.box(root, Vector3(14, 0.1, 12), Vector3(0, -0.05, 0), Kit.mat("#2a2c30", 0.8))
	Kit.box(root, Vector3(14, 6, 0.3), Vector3(0, 3, -4.2), stone)
	for s: float in [-1.0, 1.0]:
		Kit.box(root, Vector3(0.3, 6, 12), Vector3(s * 6.5, 3, 0), stone)
	Kit.box(root, Vector3(14, 0.3, 12), Vector3(0, 6, 0), Kit.mat("#14161a", 0.9))
	# Banks of dials along the back wall.
	_lamp_on = Kit.lit("#ffd24a", 3.0)
	_lamp_off = Kit.mat("#3a3020", 0.6)
	var panel := Kit.mat("#4a5a4a", 0.5, 0.5)
	for k in 5:
		var x := -4.0 + k * 2.0
		Kit.box(root, Vector3(1.8, 2.4, 0.5), Vector3(x, 1.2, -3.8), panel)
		for r in 3:
			for c in 4:
				var l := Kit.ball(root, 0.06, Vector3(x - 0.6 + c * 0.4, 1.4 + r * 0.3, -3.53), _lamp_off, 8)
				l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				_lamps.append(l)
		Kit.cyl(root, 0.22, 0.22, 0.04, Vector3(x, 0.8, -3.52), Kit.lit("#e8f0d0", 0.8), 20, Vector3(PI / 2, 0, 0))
	# The time platform: a disc, a ring of coils, a crown above.
	_plat_mat = Kit.lit("#7dd8ff", 0.4)
	Kit.cyl(root, 1.4, 1.5, 0.25, PLATFORM + Vector3(0, 0.125, 0), Kit.mat("#2a2c30", 0.5, 0.7), 32)
	var disc := Kit.cyl(root, 1.2, 1.2, 0.03, PLATFORM + Vector3(0, 0.26, 0), _plat_mat, 32)
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in 8:
		var a := k * TAU / 8.0
		Kit.cyl(root, 0.08, 0.08, 2.6, PLATFORM + Vector3(cos(a) * 1.35, 1.5, sin(a) * 1.35), Kit.mat("#b0612e", 0.35, 0.9), 10)
	var crown := Kit.cyl(root, 1.5, 1.5, 0.15, PLATFORM + Vector3(0, 2.85, 0), Kit.mat("#2a2c30", 0.5, 0.7), 32)
	crown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_plat_light = Kit.omni(root, PLATFORM + Vector3(0, 1.2, 0), "#7dd8ff", 0.5, 6.0, false, 1.0)
	_flash = Kit.omni(root, PLATFORM + Vector3(0, 1.4, 0.5), "#ffffff", 0.0, 14.0, false, 1.5)
	# The force-field cage.
	_cage_mat = StandardMaterial3D.new()
	_cage_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cage_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cage_mat.albedo_color = Color(0.4, 0.9, 1.0, 0.22)
	_cage_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cage := Kit.cyl(root, 0.9, 0.9, 2.4, CAGE + Vector3(0, 1.2, 0), _cage_mat, 32)
	cage.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for y: float in [0.05, 2.4]:
		Kit.cyl(root, 1.0, 1.0, 0.12, CAGE + Vector3(0, y, 0), Kit.mat("#2a2c30", 0.5, 0.7), 32)
	Kit.omni(root, CAGE + Vector3(0, 1.4, 0.6), "#7de8ff", 2.0, 5.0, false, 0.6)
	# Green key light and a cool fill.
	Kit.spot(root, Vector3(0, 5.6, 3.0), Vector3(0, 0, -0.5), "#7dff9a", 18.0, 12.0, 45.0, true, 1.0)
	Kit.omni(root, Vector3(0, 3.0, 4.0), "#8aa0c8", 1.0, 10.0, false, 0.2)
	_chest_lab = _chest(root)
	_chest_lab.position = CHEST_LAB
	_chest_lab.visible = false
	# SEA.
	var sea := Node3D.new()
	sea.position = SEA
	root.add_child(sea)
	Kit.box(sea, Vector3(600, 0.1, 600), Vector3(0, -0.6, 0), Kit.mat("#0c1a24", 0.1, 0.0, 0.9))
	_ship = Node3D.new()
	sea.add_child(_ship)
	var ship := Kit.model(SHIP)
	ship.scale = Vector3.ONE * 2.2
	_ship.add_child(ship)
	var bb := Kit.bounds(ship)
	ship.position = Vector3(-(bb.position.x + bb.size.x * 0.5), -bb.position.y - 1.0, -(bb.position.z + bb.size.z * 0.5))
	_chest_sea = _chest(sea)
	_rope = Kit.rod(sea, Vector3.ZERO, Vector3(0, 1, 0), 0.025, Kit.mat("#8a7050", 0.8), 6)
	Kit.spot(sea, Vector3(-12, 18, 14), Vector3(0, 2, 0), "#9fb4ff", 30.0, 60.0, 35.0, true, 0.6)
	Kit.omni(sea, Vector3(1.5, 4.0, 2.0), "#ffb060", 3.0, 10.0, true, 0.4)
	_bolt = Kit.omni(sea, Vector3(-40, 60, -60), "#d8e4ff", 0.0, 220.0, false, 0.0)
	var drop := BoxMesh.new()
	drop.size = Vector3(0.008, 0.5, 0.008)
	_rain = MultiMesh.new()
	_rain.transform_format = MultiMesh.TRANSFORM_3D
	_rain.mesh = drop
	_rain.instance_count = 1500
	var rmi := MultiMeshInstance3D.new()
	rmi.multimesh = _rain
	var rmat := Kit.mat("#9fb4d0", 0.2).duplicate()
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.albedo_color = Color(0.7, 0.8, 0.95, 0.35)
	rmi.material_override = rmat
	rmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sea.add_child(rmi)
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	for i in _lamps.size():
		_lamps[i].material_override = _lamp_on if (i * 7 + int(t * 4.0)) % 5 < 2 else _lamp_off
	# The platform charges and flashes.
	var pt := float(_p.get("platform", 1e9))
	var charge := Motion.in_cubic(Motion.seg(t, pt - 0.8, pt))
	_plat_mat.emission_energy_multiplier = 0.4 + 6.0 * charge
	_plat_light.light_energy = 0.5 + 8.0 * charge
	_flash.light_energy = 60.0 * exp(-(t - pt) * 6.0) if t >= pt else 0.0
	if ctx.has("actor"):
		for aid in _p.get("gone", []):
			var a = ctx["actor"].call(String(aid))
			if a != null and t >= pt:
				a.visible = false
		var hd: Dictionary = _p.get("hat", {})
		if hd.has("actor") and not _hat_done:
			var a2 = ctx["actor"].call(String(hd["actor"]))
			if a2 != null:
				var head := a2.find_child("toon_head", true, false) as Node3D
				if head != null:
					_hat_done = true
					var hm := head.get_node_or_null("head") as MeshInstance3D
					var hr := hm.get_aabb().size.x * 0.5 if hm != null else 0.28
					var hat := Node3D.new()
					hat.position = Vector3(0, hr * 0.85, 0)
					head.add_child(hat)
					var black := Kit.mat("#141414", 0.7)
					Kit.cyl(hat, hr * 0.7, hr * 0.8, hr * 0.5, Vector3(0, hr * 0.2, 0), black, 3)
					Kit.cyl(hat, hr * 1.25, hr * 1.25, hr * 0.06, Vector3(0, 0, 0), black, 3)
					Kit.box(hat, Vector3(hr * 0.5, hr * 0.3, 0.01), Vector3(0, hr * 0.25, hr * 0.62), Kit.mat("#efe9dc", 0.8))
	# The chest arrives at Doom's feet.
	var ct := float(_p.get("chest", 1e9))
	_chest_lab.visible = t >= ct
	if t >= ct:
		var k := Motion.out_back(Motion.seg(t, ct, ct + 0.4), 1.4)
		_chest_lab.scale = Vector3.ONE * maxf(k, 0.01)
	# The ship rolls; the chest is hauled up; rain; lightning.
	_ship.rotation = Vector3(0.06 * sin(t * 0.7), 0, 0.09 * sin(t * 0.55 + 0.4))
	_ship.position = Vector3(0, 0.35 * sin(t * 0.9), 0)
	var ht := float(_p.get("haul", 1e9))
	var hk := Motion.in_out(Motion.seg(t, ht, ht + 1.5))
	var deck := Vector3(0.0, 2.6, 2.0)
	var sea_p := Vector3(3.6, -0.5, 2.4)
	var cp := sea_p.lerp(deck, hk) + Vector3(0, 1.2 * sin(PI * hk), 0)
	_chest_sea.position = cp
	_chest_sea.rotation = Vector3(0.2 * sin(t * 3.0) * (1.0 - hk), 0.3 * hk, 0)
	var top := Vector3(2.0, 6.5, 2.2)
	var mid := (top + cp + Vector3(0, 0.6, 0)) * 0.5
	var dir := (top - (cp + Vector3(0, 0.6, 0)))
	_rope.transform = Transform3D(Basis.looking_at(dir.normalized(), Vector3.FORWARD if absf(dir.normalized().y) > 0.99 else Vector3.UP)
		* Basis.from_euler(Vector3(-PI / 2, 0, 0)), mid)
	_rope.scale = Vector3(1, dir.length(), 1)
	var fl := 0.0
	for lt in _p.get("lightning", []):
		var k := t - float(lt)
		if k >= 0.0 and k < 0.6:
			fl = maxf(fl, exp(-k * 9.0))
	_bolt.light_energy = 300.0 * fl
	var rng := RandomNumberGenerator.new()
	for i in _rain.instance_count:
		rng.seed = 40 + i
		var x := rng.randf_range(-15, 15)
		var z := rng.randf_range(-12, 14)
		var y := fposmod(rng.randf() * 14.0 - t * 12.0, 14.0) - 1.0
		_rain.set_instance_transform(i, Transform3D(Basis.from_euler(Vector3(0.15, 0, 0.1)), Vector3(x, y, z)))
	return {"cage": node.global_transform * (CAGE + Vector3(0, 1.2, 0)), "platform": node.global_transform * (PLATFORM + Vector3(0, 1.2, 0)),
		"chest_lab": node.global_transform * CHEST_LAB, "ship": node.global_transform * (SEA + Vector3(0, 3, 0)),
		"chest_sea": node.global_transform * (SEA + cp)}
