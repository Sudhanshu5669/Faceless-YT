## jio_story gag: a toy cash cannon on wheels (Mukesh fires money at Infotel).
## Barrel points along local +z (give the gag a "face" target). It kicks back and flashes
## on every shot in params.shots (scene times), and rolls in from params.roll_from.
##
##   params: {"shots": [t, ...] or {"from": t, "until": t, "every": s},
##            "roll_in": {"line", "word"} (time it arrives), "roll_from": [x, y, z] (local offset)}
## Anchors: "<id>.muzzle", "<id>.breech".
extends RefCounted

const Toon = preload("res://scripts/actors/toon.gd")

const BARREL_LEN := 1.1
const TILT := 0.32   # radians, barrel raised


func validate(g: Dictionary) -> Array:
	return []


func _shots(p: Dictionary) -> Array:
	var s = p.get("shots", [])
	if typeof(s) == TYPE_DICTIONARY:
		var out := []
		var t := float(s["from"])
		while t <= float(s["until"]) + 0.0001:
			out.append(t)
			t += float(s.get("every", 0.12))
		return out
	return s


func build(g: Dictionary) -> Node3D:
	var n := Node3D.new()
	var gold := Toon.material(Color("f2c230"), Toon.OUTLINE * 0.7)
	var dark := Toon.material(Color("2b2f36"), Toon.OUTLINE * 0.7)
	var red := Toon.material(Color("d6453d"), Toon.OUTLINE * 0.7)
	var carriage := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(0.62, 0.22, 0.9)
	carriage.mesh = cb
	carriage.material_override = red
	carriage.position = Vector3(0, 0.36, -0.05)
	n.add_child(carriage)
	for sx in [-0.36, 0.36]:
		var w := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.3
		cm.bottom_radius = 0.3
		cm.height = 0.09
		w.mesh = cm
		w.material_override = dark
		w.rotation = Vector3(0, 0, PI / 2)
		w.position = Vector3(sx, 0.3, -0.05)
		w.name = "wheel_%s" % ("l" if sx < 0 else "r")
		n.add_child(w)
	var pivot := Node3D.new()
	pivot.name = "pivot"
	pivot.position = Vector3(0, 0.55, -0.1)
	n.add_child(pivot)
	var barrel := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.17
	bm.bottom_radius = 0.22
	bm.height = BARREL_LEN
	barrel.mesh = bm
	barrel.material_override = gold
	barrel.rotation = Vector3(PI / 2, 0, 0)
	barrel.position = Vector3(0, 0, BARREL_LEN * 0.5 - 0.2)
	barrel.name = "barrel"
	pivot.add_child(barrel)
	var rim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.15
	tm.outer_radius = 0.21
	rim.mesh = tm
	rim.material_override = dark
	rim.rotation = Vector3(PI / 2, 0, 0)
	rim.position = Vector3(0, 0, BARREL_LEN - 0.2)
	pivot.add_child(rim)
	var flash := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.22
	sm.height = 0.44
	flash.mesh = sm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color("fff2b0")
	fm.emission_enabled = true
	fm.emission = Color("ffd84a")
	fm.emission_energy_multiplier = 6.0
	flash.material_override = fm
	flash.position = Vector3(0, 0, BARREL_LEN - 0.05)
	flash.name = "flash"
	pivot.add_child(flash)
	return n


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	# Roll in: slide from roll_from to the spot, wheels turning, settle with a tiny bounce.
	var off := Vector3.ZERO
	var spin := 0.0
	if p.has("roll_in"):
		var arrive := float(p["roll_in"])
		var start := arrive - float(p.get("roll_time", 0.8))
		var k := clampf((t - start) / maxf(arrive - start, 0.01), 0.0, 1.0)
		k = 1.0 - pow(1.0 - k, 3.0)
		var rf: Array = p.get("roll_from", [0, 0, -2.5])
		off = Vector3(float(rf[0]), float(rf[1]), float(rf[2])) * (1.0 - k)
		spin = -off.length() / 0.3
	node.position = off
	for w in ["wheel_l", "wheel_r"]:
		(node.get_node(w) as Node3D).rotation = Vector3(spin, 0, PI / 2)
	# Recoil: each shot kicks the barrel back and up, then it springs home; a flash at the muzzle.
	var kick := 0.0
	var flash := 0.0
	for s in _shots(p):
		var dt := t - float(s)
		if dt >= 0.0 and dt < 0.5:
			kick = maxf(kick, exp(-dt * 9.0) * cos(dt * 30.0) * (1.0 if dt > 0.02 else dt / 0.02))
		if dt >= 0.0 and dt < 0.08:
			flash = maxf(flash, 1.0 - dt / 0.08)
	var pivot := node.get_node("pivot") as Node3D
	pivot.rotation = Vector3(-TILT - kick * 0.12, 0, 0)
	pivot.position = Vector3(0, 0.55, -0.1 - kick * 0.16)
	node.position += Vector3(0, 0, -absf(kick) * 0.05)
	var fl := pivot.get_node("flash") as Node3D
	fl.visible = flash > 0.0
	fl.scale = Vector3.ONE * (0.4 + flash)
	var muzzle := pivot.to_global(Vector3(0, 0, BARREL_LEN - 0.1))
	return {"muzzle": muzzle, "breech": pivot.to_global(Vector3(0, 0, -0.25))}
