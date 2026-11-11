## library:door — a free-standing door in a frame that slams shut (with a bounce), can be padlocked,
## and later unlocked and flung open. A sign on the door (label).
##
##   {"id": "door", "script": "library:door", "t": 0, "at": {...}, "face": <the side we see>,
##    "params": {"label": "TELECOM|ANIL ONLY", "close": <t>, "lock": <t>, "unlock": <t>, "open": <t>,
##               "start_open": true, "width": 0.95, "height": 2.0, "color": "#7a4a2a", "sign_color": "#f4f0e0"}}
##
## Hinge on the screen-left side (facing the camera). "start_open": the door begins swung open (90°).
## Anchors: "<id>.sign" (the sign's centre), "<id>.lock".
extends RefCounted

const Toon = preload("res://scripts/actors/toon.gd")
const Reveals = preload("res://scripts/timeline/reveals.gd")


func validate(g: Dictionary) -> Array:
	var e := []
	for k in g.get("params", {}):
		if not (k in ["label", "close", "lock", "unlock", "open", "start_open", "width", "height", "color", "sign_color", "label_color"]):
			e.append("door: unknown param '%s'" % k)
	return e


func _box(sz: Vector3, mat: Material, pos: Vector3, nm := "") -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = sz
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	if nm != "":
		mi.name = nm
	return mi


func build(g: Dictionary) -> Node3D:
	var p: Dictionary = g.get("params", {})
	var w := float(p.get("width", 0.95))
	var h := float(p.get("height", 2.0))
	var wood := Toon.material(Color(String(p.get("color", "#7a4a2a"))), Toon.OUTLINE * 0.7)
	var frame := Toon.material(Color(String(p.get("color", "#7a4a2a"))).darkened(0.35), Toon.OUTLINE * 0.7)
	var n := Node3D.new()
	# The frame: two posts and a lintel.
	for sx in [-1.0, 1.0]:
		n.add_child(_box(Vector3(0.08, h + 0.08, 0.14), frame, Vector3(sx * (w * 0.5 + 0.04), (h + 0.08) * 0.5, 0)))
	n.add_child(_box(Vector3(w + 0.16, 0.08, 0.14), frame, Vector3(0, h + 0.04, 0)))
	# The leaf hangs from a hinge at the screen-left post (local +x when facing the camera).
	var hinge := Node3D.new()
	hinge.name = "hinge"
	hinge.position = Vector3(w * 0.5, 0, 0)
	n.add_child(hinge)
	var leaf := Node3D.new()
	leaf.name = "leaf"
	leaf.position = Vector3(-w * 0.5, 0, 0)
	hinge.add_child(leaf)
	leaf.add_child(_box(Vector3(w, h, 0.06), wood, Vector3(0, h * 0.5, 0)))
	for y in [0.28, 0.72]:
		leaf.add_child(_box(Vector3(w * 0.72, h * 0.3, 0.02), frame, Vector3(0, h * y, 0.035)))
	var knob := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.045
	sm.height = 0.09
	knob.mesh = sm
	knob.material_override = Toon.material(Color("e8b52a"), Toon.OUTLINE * 0.5)
	knob.position = Vector3(-w * 0.36, h * 0.48, 0.06)
	leaf.add_child(knob)
	var sign := _box(Vector3(w * 0.8, h * 0.2, 0.025), Toon.material(Color(String(p.get("sign_color", "#f4f0e0"))), Toon.OUTLINE * 0.5),
		Vector3(0, h * 0.78, 0.055), "sign")
	leaf.add_child(sign)
	if p.has("label"):
		var lines := String(p["label"]).split("|")
		for i in lines.size():
			var lbl := Reveals.text_node(lines[i], h * 0.055, Color(String(p.get("label_color", "#c0262d"))))
			lbl.position = Vector3(0, h * (0.8 - 0.065 * i) + (h * 0.03 if lines.size() > 1 else 0.0), 0.07)
			leaf.add_child(lbl)
	# Padlock: a gold body and a shackle (a half torus), across the leaf and the frame.
	var lock := Node3D.new()
	lock.name = "lock"
	n.add_child(lock)
	lock.add_child(_box(Vector3(0.16, 0.14, 0.06), Toon.material(Color("e8b52a"), Toon.OUTLINE * 0.6), Vector3.ZERO))
	var tm := TorusMesh.new()
	tm.inner_radius = 0.045
	tm.outer_radius = 0.065
	var sh := MeshInstance3D.new()
	sh.mesh = tm
	sh.material_override = Toon.material(Color("c9ced6"), Toon.OUTLINE * 0.5)
	sh.rotation = Vector3(PI / 2, 0, 0)
	sh.position = Vector3(0, 0.09, 0)
	lock.add_child(sh)
	return n


## 0 = shut, 1 = wide open (90°). Slams shut with a bounce; swings open with an overshoot.
func _openness(p: Dictionary, t: float) -> float:
	var o := 1.0 if bool(p.get("start_open", true)) else 0.0
	if p.has("close") and t >= float(p["close"]):
		var dt := t - float(p["close"])
		o = 0.0 if dt > 0.5 else maxf(0.0, (1.0 - dt / 0.12)) if dt < 0.12 else absf(sin(dt * 25.0)) * 0.12 * exp(-dt * 9.0)
	if p.has("open") and t >= float(p["open"]):
		var dt := t - float(p["open"])
		o = minf(1.15, dt / 0.25) if dt < 0.25 else 1.0 + 0.15 * exp(-(dt - 0.25) * 6.0) * cos((dt - 0.25) * 14.0)
	return o


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	var p: Dictionary = g.get("params", {})
	var w := float(p.get("width", 0.95))
	var h := float(p.get("height", 2.0))
	var hinge := node.get_node("hinge") as Node3D
	# Open: the leaf swings toward the viewer around the hinge.
	hinge.rotation = Vector3(0, -_openness(p, t) * PI * 0.5, 0)
	var lock := node.get_node("lock") as Node3D
	var locked := p.has("lock") and t >= float(p["lock"]) and not (p.has("unlock") and t >= float(p["unlock"]) + 0.6)
	lock.visible = locked
	var lp := Vector3(-w * 0.5 + 0.02, h * 0.48, 0.1)
	if p.has("lock") and t < float(p["lock"]) + 0.25 and t >= float(p["lock"]):
		lp.y += (1.0 - (t - float(p["lock"])) / 0.25) * 0.5   # drops in and clamps
	if p.has("unlock") and t >= float(p["unlock"]):
		var dt := t - float(p["unlock"])
		lp += Vector3(-dt * 0.8, dt * 1.6 - dt * dt * 5.0, dt * 1.2)   # pops off and flies away
		lock.rotation = Vector3(dt * 12.0, 0, dt * 8.0)
	else:
		lock.rotation = Vector3.ZERO
	lock.position = lp
	return {"sign": node.to_global(Vector3(0, h * 0.78, 0.1)), "lock": node.to_global(lp)}
