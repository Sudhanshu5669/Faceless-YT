## Doctor Doom's costume on any toon actor (our own toon design, not a copy of a film or comic model): a riveted
## iron faceplate over the sphere head, with eye slits (the drawn toon eyes show through, so Doom acts with his eyes)
## and a barred mouth slot; a green hood; a green mantle over the shoulders; a long green cloak; a green tunic
## with an iron belt and a round clasp.
##
## params:
##   actors   [{"actor": id, "hood": true, "cloak": true, "unmask": t, "hand": "r", "hood_back": true,
##              "rust": 0.0}]
##            unmask: on t the actor reaches up (anticipation from t - 0.45), lifts the mask up and off the face
##            (out-cubic, 0.4 s) and lowers it to hold at his chest; the hood slides back off the head with it
##            (hood_back, default true). Before t the mask sits on the face.
##   metal    "#8d9399" the plate colour; tunic "#2b6a35"; cloak "#1d4a26"
## anchors: "<actor>.mask" (the mask's world position) for every dressed actor.
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")
const Toon = preload("res://scripts/actors/toon.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")

var _p := {}
var _dressed := {}
var _mask_mesh: ArrayMesh
var _hood_mesh: ArrayMesh


func validate(g: Dictionary) -> Array:
	var e := []
	for d in g.get("params", {}).get("actors", []):
		if not (d is Dictionary) or not d.has("actor"):
			e.append("doom_suit: every entry of actors needs an 'actor'")
	return e


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	root.name = String(g.get("id", "doom_suit"))
	return root


## The faceplate: the front of a sphere shell, open at the slits and the mouth slot. Unit radius; the face's
## drawn eyes sit at (±0.40, 0.06) and the mouth near (0, -0.33) in the shader's unit face coordinates.
static func _mask(r: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var na := 56
	var nb := 40
	var a0 := -1.62
	var a1 := 1.62
	var b0 := -1.12
	var b1 := 1.0
	var pt := func(i: int, j: int) -> Vector3:
		var a := lerpf(a0, a1, float(i) / na)
		var b := lerpf(b0, b1, float(j) / nb)
		# A slightly squared, longer face: flatten the front, stretch the jaw.
		var v := Vector3(sin(a) * cos(b), sin(b), cos(a) * cos(b))
		v.z = v.z * 0.94 + 0.04
		if v.y < 0.0:
			v.y *= 1.12
		return v * r
	for i in na:
		for j in nb:
			var c: Vector3 = (pt.call(i, j) + pt.call(i + 1, j + 1)) * 0.5 / r
			var x := absf(c.x)
			# Eye slits: narrow, angled down toward the nose (a scowl).
			var slit_y := 0.07 + (x - 0.40) * 0.18
			if c.z > 0.0 and x > 0.17 and x < 0.62 and absf(c.y - slit_y) < 0.055:
				continue
			# Mouth slot.
			if c.z > 0.0 and x < 0.26 and c.y > -0.46 and c.y < -0.33:
				continue
			var q := [pt.call(i, j), pt.call(i + 1, j), pt.call(i + 1, j + 1), pt.call(i, j + 1)]
			for k in [0, 2, 1, 0, 3, 2]:
				st.set_normal((q[k] as Vector3).normalized())
				st.add_vertex(q[k])
	return st.commit()


## The hood: a shell round the head, open at the front.
static func _hood(r: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var na := 48
	var nb := 32
	var pt := func(i: int, j: int) -> Vector3:
		var a := lerpf(-PI, PI, float(i) / na)
		var b := lerpf(-1.25, 1.45, float(j) / nb)
		var v := Vector3(sin(a) * cos(b), sin(b), cos(a) * cos(b))
		# A peak at the brow, a fuller back.
		if v.z < 0.0:
			v.z *= 1.12
		return v * r
	for i in na:
		for j in nb:
			var c: Vector3 = (pt.call(i, j) + pt.call(i + 1, j + 1)) * 0.5 / r
			if c.z > 0.38 and c.y < 0.74:
				continue
			var q := [pt.call(i, j), pt.call(i + 1, j), pt.call(i + 1, j + 1), pt.call(i, j + 1)]
			for k in [0, 2, 1, 0, 3, 2]:
				st.set_normal((q[k] as Vector3).normalized())
				st.add_vertex(q[k])
	return st.commit()


## A partial cone (the cloak or the mantle) in torso space: angles a0..a1 round y (pi = straight back).
static func _drape(y_top: float, y_bot: float, r_top: float, r_bot: float, a0: float, a1: float, wave: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var na := 36
	var nb := 14
	var pt := func(i: int, j: int) -> Vector3:
		var a := lerpf(a0, a1, float(i) / na)
		var v := float(j) / nb
		var y := lerpf(y_top, y_bot, v)
		var r := lerpf(r_top, r_bot, pow(v, 0.8)) * (1.0 + wave * v * sin(a * 9.0) * 0.5)
		return Vector3(sin(a) * r, y, cos(a) * r)
	for i in na:
		for j in nb:
			var q := [pt.call(i, j), pt.call(i + 1, j), pt.call(i + 1, j + 1), pt.call(i, j + 1)]
			var n := ((q[1] - q[0]) as Vector3).cross(q[3] - q[0]).normalized()
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_normal(-n)
				st.add_vertex(q[k])
	return st.commit()


func _dress(a: Node3D, d: Dictionary) -> void:
	var head := a.find_child("toon_head", true, false) as Node3D
	var torso := a.find_child("toon_torso", true, false) as Node3D
	if head == null or torso == null:
		return
	var hm := head.get_node_or_null("head") as MeshInstance3D
	var hr := hm.get_aabb().size.x * 0.5 if hm != null else Toon.HEAD_R * Toon.H
	var metal := Kit.mat(String(_p.get("metal", "#8a9096")), 0.52, 0.7)
	var metal_dark := Kit.mat("#4a4f54", 0.55, 0.7)
	var tunic_col := Color(String(_p.get("tunic", "#1f5229")))
	var cloak_mat := Toon.material(Color(String(_p.get("cloak", "#173d20"))), Toon.OUTLINE * 0.7)
	cloak_mat = cloak_mat.duplicate()
	cloak_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# The mask.
	var mask := Node3D.new()
	mask.name = "doom_mask"
	head.add_child(mask)
	if _mask_mesh == null:
		_mask_mesh = _mask(1.0)
		_hood_mesh = _hood(1.0)
	var shell := MeshInstance3D.new()
	shell.mesh = _mask_mesh
	shell.material_override = metal
	shell.scale = Vector3.ONE * hr * 1.045
	mask.add_child(shell)
	var mr := hr * 1.06
	# The nose ridge, the brow band, the mouth bars, the cheek seams, the rivets.
	Kit.box(mask, Vector3(hr * 0.09, hr * 0.42, hr * 0.12), Vector3(0, -hr * 0.12, mr * 0.95), metal, Vector3(0.12, 0, 0))
	Kit.box(mask, Vector3(hr * 1.2, hr * 0.07, hr * 0.1), Vector3(0, hr * 0.3, mr * 0.93), metal_dark, Vector3(-0.3, 0, 0))
	for k in 5:
		var x := (-0.2 + 0.1 * k) * hr
		Kit.box(mask, Vector3(hr * 0.035, hr * 0.16, hr * 0.05), Vector3(x, -hr * 0.4 * 1.12, mr * 0.9), metal_dark)
	for s: float in [-1.0, 1.0]:
		for k in 4:
			var ang := s * (0.62 + 0.12 * k)
			var y := -0.15 - 0.17 * k
			Kit.ball(mask, hr * 0.03, Vector3(sin(ang) * cos(y) * mr, sin(y) * mr * 1.1, cos(ang) * cos(y) * mr), metal_dark, 8)
		Kit.ball(mask, hr * 0.034, Vector3(s * 0.75 * mr, 0.42 * mr, 0.5 * mr), metal_dark, 8)
	# Hood (on the head, so it turns with it). The hair hides under it (it shows again when the hood goes back).
	if bool(d.get("hood", true)):
		for h in head.get_children():
			if String(h.name).contains("hair") or (h is MeshInstance3D and h.name != "head" and not String(h.name).begins_with("doom")):
				(h as Node3D).set_meta("doom_hair", true)
				(h as Node3D).visible = false
		var hood := Node3D.new()
		hood.name = "doom_hood"
		head.add_child(hood)
		var hs := MeshInstance3D.new()
		hs.mesh = _hood_mesh
		hs.material_override = cloak_mat
		hs.scale = Vector3.ONE * hr * 1.17
		hs.position = Vector3(0, hr * 0.04, -hr * 0.04)
		hood.add_child(hs)
	# Tunic: the bean turns green; an iron belt with a round clasp.
	var bean := torso.get_child(0) as MeshInstance3D
	var bh := bean.get_aabb().size.y if bean != null else 0.7
	var rb := bean.get_aabb().size.x * 0.5 if bean != null else 0.26
	if bean != null:
		bean.material_override = Toon.material(tunic_col, Toon.OUTLINE)
	Kit.cyl(torso, rb * 0.96, rb * 0.99, bh * 0.07, Vector3(0, bh * 0.2, 0), metal_dark, 32)
	Kit.cyl(torso, rb * 0.22, rb * 0.22, rb * 0.08, Vector3(0, bh * 0.2, rb * 0.95), metal, 24, Vector3(PI / 2, 0, 0))
	# Mantle over the shoulders and the cloak down the back.
	var mantle := MeshInstance3D.new()
	mantle.mesh = _drape(bh * 1.03, bh * 0.78, rb * 0.62, rb * 1.12, -PI, PI, 0.04)
	mantle.material_override = cloak_mat
	torso.add_child(mantle)
	if bool(d.get("cloak", true)):
		var cloak := MeshInstance3D.new()
		cloak.name = "doom_cloak"
		var ground := -Toon.BEAN_BOTTOM * Toon.H + 0.06
		cloak.mesh = _drape(bh * 0.95, ground, rb * 1.08, rb * 1.75, PI * 0.42, PI * 1.58, 0.08)
		cloak.material_override = cloak_mat
		torso.add_child(cloak)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var out := {}
	if not ctx.has("actor"):
		return out
	for d in _p.get("actors", []):
		var aid := String(d["actor"])
		var a = ctx["actor"].call(aid)
		if a == null:
			continue
		if not _dressed.has(aid):
			_dress(a, d)
			_dressed[aid] = true
		var head := a.find_child("toon_head", true, false) as Node3D
		if head == null:
			continue
		var mask := head.find_child("doom_mask", false, false) as Node3D
		var hood := head.find_child("doom_hood", false, false) as Node3D
		if mask == null:
			continue
		# Rest: on the face.
		mask.transform = Transform3D.IDENTITY
		if hood != null:
			hood.transform = Transform3D.IDENTITY
			for h in head.get_children():
				if h.has_meta("doom_hair"):
					(h as Node3D).visible = false
		if d.has("unmask"):
			var off := float(d["unmask"])
			var side := String(d.get("hand", "r"))
			var reach := Motion.in_out(Motion.seg(t, off - 0.45, off - 0.05))
			var lift := Motion.out_cubic(Motion.seg(t, off - 0.05, off + 0.4))
			var lower := Motion.in_out(Motion.seg(t, off + 0.4, off + 1.1))
			var face_xf: Transform3D = mask.global_transform
			if lift > 0.0:
				var ay := float(a.rotation.y)
				var fwd := Vector3(sin(ay), 0, cos(ay))
				var right := -Vector3(cos(ay), 0, -sin(ay))
				var up_xf := face_xf
				up_xf.origin += Vector3(0, 0.28, 0) + fwd * 0.22
				up_xf.basis = Basis.from_euler(Vector3(-0.55, ay, 0)).scaled(face_xf.basis.get_scale())
				# Held down at his side, face out, like a helmet carried by the chin.
				var held: Vector3 = a.bone_world("spine_01") + fwd * 0.1 + right * (0.36 if side == "r" else -0.36) + Vector3(0, -0.02, 0)
				var held_xf := Transform3D(Basis.from_euler(Vector3(0.1, ay + (0.5 if side == "r" else -0.5), 0.15 if side == "r" else -0.15)).scaled(face_xf.basis.get_scale() * 0.92), held)
				var p1: Vector3 = Motion.arc(face_xf.origin, up_xf.origin, 0.06, lift)
				var w := p1.lerp(held_xf.origin, lower)
				var sc := face_xf.basis.get_scale()
				var q0 := face_xf.basis.get_rotation_quaternion()
				var q1 := up_xf.basis.get_rotation_quaternion()
				var q2 := held_xf.basis.get_rotation_quaternion()
				mask.global_transform = Transform3D(Basis(q0.slerp(q1, lift).slerp(q2, lower)).scaled(sc), w)
				if hood != null and bool(d.get("hood_back", true)):
					var hb := Motion.out_cubic(Motion.seg(t, off + 0.05, off + 0.55))
					hood.transform = Transform3D(Basis.from_euler(Vector3(-1.05 * hb, 0, 0)), Vector3(0, -0.05 * hb, -0.09 * hb))
					for h in head.get_children():
						if h.has_meta("doom_hair"):
							(h as Node3D).visible = hb > 0.35
			# The hand: up to the chin, with the mask, then down to hold it.
			if reach > 0.0:
				Crawl.long_arms(a, 1.35)
				var chin: Vector3 = face_xf.origin + Vector3(0, -0.12, 0) + Vector3(sin(float(a.rotation.y)), 0, cos(float(a.rotation.y))) * 0.2
				var target: Vector3 = chin if lift <= 0.0 else mask.global_transform.origin + Vector3(0, -0.1, 0)
				a.aim_hand(side, target, minf(reach, 1.0))
		out[aid + "_mask"] = mask.global_transform.origin
	return out
