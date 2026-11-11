## jio_story gag: Mukesh sips crude oil from a little barrel through a bendy straw.
## Put the gag at the actor's chest ("m.chest"), with "hands": "chest" on the actor.
##   params: {"mouth": point (e.g. {"anchor": "m.face", "offset": [0, -0.13, 0.16]}),
##            "sips": {"from": t, "until": t, "every": s} or [t, ...], "sip_time": 0.45}
## Each sip: a dark slug of crude travels up the straw and the barrel squeezes.
extends RefCounted

const Toon = preload("res://scripts/actors/toon.gd")

const R := 0.13      # barrel radius
const H := 0.3       # barrel height


func _sips(p: Dictionary) -> Array:
	var s = p.get("sips", [])
	if typeof(s) == TYPE_DICTIONARY:
		var out := []
		var t := float(s["from"])
		while t <= float(s["until"]) + 0.0001:
			out.append(t)
			t += float(s.get("every", 0.9))
		return out
	return s


func validate(g: Dictionary) -> Array:
	return [] if g.get("params", {}).has("mouth") else ["straw_barrel: params.mouth is required"]


func _cyl(r: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = r
	m.bottom_radius = r
	m.height = h
	m.radial_segments = 20
	return m


func build(g: Dictionary) -> Node3D:
	var n := Node3D.new()
	var barrel := Node3D.new()
	barrel.name = "barrel"
	n.add_child(barrel)
	# An oil drum, built: the catalog only has wooden barrels (tf props barrel), which read as wine.
	var body := MeshInstance3D.new()
	body.mesh = _cyl(R, H)
	body.material_override = Toon.material(Color("1d2a5e"), Toon.OUTLINE * 0.7)
	body.position = Vector3(0, H * 0.5, 0)
	barrel.add_child(body)
	for y in [0.2, 0.8]:
		var band := MeshInstance3D.new()
		band.mesh = _cyl(R * 1.04, H * 0.07)
		band.material_override = Toon.material(Color("d6453d"), 0.0)
		band.position = Vector3(0, H * y, 0)
		barrel.add_child(band)
	var lid := MeshInstance3D.new()
	lid.mesh = _cyl(R * 0.98, 0.012)
	lid.material_override = Toon.material(Color("c9ced6"), 0.0)
	lid.position = Vector3(0, H, 0)
	barrel.add_child(lid)
	for nm in ["seg_a", "seg_b", "slug"]:
		var mi := MeshInstance3D.new()
		mi.name = nm
		mi.mesh = _cyl(0.014 if nm != "slug" else 0.016, 1.0)
		mi.material_override = Toon.material(Color("ff5ca8") if nm != "slug" else Color("120d08"), Toon.OUTLINE * 0.4 if nm != "slug" else 0.0)
		n.add_child(mi)
	return n


## Orient a unit-height cylinder from a to b (in node space).
func _span(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var len := maxf(d.length(), 0.001)
	var y := d / len
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y * len, x.cross(y)), (a + b) * 0.5)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	var sip_time := float(p.get("sip_time", 0.45))
	var sip := -1.0
	for s in _sips(p):
		var dt := t - float(s)
		if dt >= 0.0 and dt < sip_time:
			sip = dt / sip_time
	var barrel := node.get_node("barrel") as Node3D
	# The barrel sits in front of the chest, a little low, and squeezes while he sips.
	barrel.position = Vector3(0, -0.22, 0.2)
	var squeeze := sin(sip * PI) if sip >= 0.0 else 0.0
	barrel.scale = Vector3(1.0 - 0.1 * squeeze, 1.0 - 0.06 * squeeze, 1.0 - 0.1 * squeeze)
	var top := barrel.position + Vector3(R * 0.4, H * barrel.scale.y, 0)
	var mouth_pt: Dictionary = ctx["point"].call(p["mouth"])
	var mouth := node.to_local(mouth_pt["pos"]) if not mouth_pt.has("error") else top + Vector3(0, 0.3, 0.1)
	# A bendy straw: straight up from the lid, then bending to the mouth.
	var bend := Vector3(top.x, lerpf(top.y, mouth.y, 0.65), top.z)
	_span(node.get_node("seg_a") as MeshInstance3D, top, bend)
	_span(node.get_node("seg_b") as MeshInstance3D, bend, mouth)
	var slug := node.get_node("slug") as MeshInstance3D
	slug.visible = sip >= 0.0
	if sip >= 0.0:
		# The slug of crude climbs the straw: along seg_a, then seg_b.
		var u := sip * 2.0
		var a: Vector3 = top.lerp(bend, clampf(u, 0.0, 1.0)) if u < 1.0 else bend.lerp(mouth, clampf(u - 1.0, 0.0, 1.0))
		var b: Vector3 = top.lerp(bend, clampf(u - 0.25, 0.0, 1.0)) if u < 1.25 else bend.lerp(mouth, clampf(u - 1.25, 0.0, 1.0))
		_span(slug, b, a)
	return {"barrel": node.to_global(barrel.position + Vector3(0, H * 0.5, 0))}
