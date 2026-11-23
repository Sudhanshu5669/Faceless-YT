## Toon characters, the "meme stick figure" style: a big white sphere head with
## a drawn face, a helmet of hair, a bean-shaped torso that IS the outfit, thin
## black stick limbs, ball hands and round shoes, all with a dark outline.
##
## Parts are primitive meshes hung (BoneAttachment3D) on a short-legged copy of
## the mannequin skeleton. The actor retargets the mannequin's pose onto that
## copy (rig "toon" in library/rigs.json), so every action in
## library/actions.json plays on a toon. Faces are a shader (toon_face.gdshader);
## expressions are presets in library/toon/faces.json, swapped by actor cues.
##
## Character JSON: "toon": {"skin", "hair": {...}, "outfit": {...}, "shoes",
## "accessories": [...], "face", "girth"}. See docs/TOON_SPEC.md.
extends RefCounted

const Paths = preload("res://scripts/core/paths.gd")
const FACE_SHADER := preload("res://shaders/toon_face.gdshader")
const OUTLINE_SHADER := preload("res://shaders/toon_outline.gdshader")
const HAIR_SHADER := preload("res://shaders/toon_hair.gdshader")

## Proportions as fractions of the body-space height (the mannequin's 1.83 m;
## the actor scales the body to the character's height). Measured on the
## reference: head ~38 % of the height, bean torso ~32 %, legs ~28 %.
const H := 1.83
const MANNEQUIN_HIP := 0.917   # pelvis height of the mannequin (m)
const HIP := 0.28
const ANKLE := 0.035
const HEAD_R := 0.19
const HEAD_C := 0.81
const BEAN_BOTTOM := 0.255
const BEAN_TOP := 0.65
const BEAN_R := 0.142
const BEAN_R_TOP := 0.098
const BEAN_DEPTH := 0.84
const LIMB_R := 0.0125
const HAND_R := 0.031
const OUTLINE := 0.013
const LIMB_COLOR := Color("17171a")
const INK := Color("0a0a0c")
const SHORTEN := ["calf_l", "foot_l", "calf_r", "foot_r"]

const KEYS := ["skin", "hair", "outfit", "shoes", "accessories", "face", "girth", "mustache", "beard"]
const HAIR_KEYS := ["style", "color", "lamp"]
const OUTFIT_KEYS := ["style", "color", "chain", "tie", "accent", "vest", "bow", "badge", "camo"]
const HAIR_STYLES := ["bowl", "tuft", "slick", "curly", "cap", "beanie", "bob", "bun", "bald", "hardhat", "hood", "turban", "side", "patrol"]
const OUTFIT_STYLES := ["hoodie", "suit", "tee", "labcoat", "dress", "shirt", "hivis", "kurta", "coverall", "fatigues"]
const ACCESSORIES := ["glasses", "round_glasses", "sunglasses", "smart_glasses", "rimless", "mask"]
const EYES := ["lazy", "dot", "wide", "happy", "closed", "x", "star", "heart", "sleepy", "none"]
const MOUTHS := ["smirk", "smile", "flat", "frown", "open", "grin", "laugh", "wavy", "o", "none"]
const FACE_KEYS := ["description", "eyes", "look", "eye_size", "eye_y", "lid", "lid_tilt", "brows",
	"brow_tilt", "brow_y", "mouth", "mouth_x", "mouth_w", "sweat", "blush", "tears"]

## Hairline polar angles (degrees from the crown) at the front, sides and back.
const HAIRLINES := {
	"bowl": [52, 84, 104, 1.07], "tuft": [52, 84, 104, 1.07], "slick": [46, 80, 100, 1.05],
	"curly": [50, 82, 100, 1.02], "cap": [48, 74, 86, 1.06], "beanie": [44, 76, 88, 1.08],
	"bob": [50, 104, 116, 1.1], "bun": [50, 86, 104, 1.06],
	"hood": [44, 118, 150, 1.07], "side": [47, 82, 102, 1.05], "patrol": [50, 72, 84, 1.07],
}

static var _faces: Dictionary = {}
static var _mats: Dictionary = {}
static var _meshes: Dictionary = {}


# --- expressions ----------------------------------------------------------------

static func faces() -> Dictionary:
	if _faces.is_empty():
		var r := Paths.load_json(Paths.repo_path("library/toon/faces.json"))
		_faces = r["data"]["faces"] if r["ok"] else {}
	return _faces


## Set a face material to an expression preset (every value reset first).
static func apply_face(mat: ShaderMaterial, id: String) -> void:
	var f: Dictionary = faces().get(id, {})
	var eyes = f.get("eyes", "dot")
	var el := String(eyes[0] if eyes is Array else eyes)
	var er := String(eyes[1] if eyes is Array else eyes)
	mat.set_shader_parameter("eye_l", EYES.find(el))
	mat.set_shader_parameter("eye_r", EYES.find(er))
	var lk: Array = f.get("look", [0, 0])
	mat.set_shader_parameter("look", Vector2(float(lk[0]), float(lk[1])))
	for k in ["eye_size", "mouth_w"]:
		mat.set_shader_parameter(k, float(f.get(k, 1.0)))
	for k in ["eye_y", "lid", "lid_tilt", "brow_tilt", "brow_y", "mouth_x", "sweat", "blush", "tears"]:
		mat.set_shader_parameter(k, float(f.get(k, 0.0)))
	mat.set_shader_parameter("brows", 1.0 if bool(f.get("brows", true)) else 0.0)
	mat.set_shader_parameter("mouth", MOUTHS.find(String(f.get("mouth", "flat"))))


static func validate_faces() -> Array:
	var e := []
	if faces().is_empty():
		return ["library/toon/faces.json has no faces"]
	for id in faces():
		var f: Dictionary = faces()[id]
		for k in f:
			if not (k in FACE_KEYS):
				e.append("face %s: unknown key '%s' (known: %s)" % [id, k, ", ".join(PackedStringArray(FACE_KEYS))])
		var eyes = f.get("eyes", "dot")
		for s in (eyes if eyes is Array else [eyes]):
			if not (String(s) in EYES):
				e.append("face %s: eye style '%s' (known: %s)" % [id, s, ", ".join(PackedStringArray(EYES))])
		if not (String(f.get("mouth", "flat")) in MOUTHS):
			e.append("face %s: mouth '%s' (known: %s)" % [id, f.get("mouth"), ", ".join(PackedStringArray(MOUTHS))])
	return e


## Errors in a character's "toon" block.
static func validate(t, where: String) -> Array:
	if typeof(t) != TYPE_DICTIONARY:
		return [where + ": toon must be an object"]
	var e := []
	for k in t:
		if not (k in KEYS):
			e.append("%s: toon has unknown key '%s' (known: %s)" % [where, k, ", ".join(PackedStringArray(KEYS))])
	for k in ["skin", "shoes", "mustache", "beard"]:
		if t.has(k) and not Color.html_is_valid(String(t[k])):
			e.append("%s: toon.%s is not a hex colour" % [where, k])
	var hair: Dictionary = t.get("hair", {})
	for k in hair:
		if not (k in HAIR_KEYS):
			e.append("%s: toon.hair has unknown key '%s'" % [where, k])
	if not (String(hair.get("style", "bowl")) in HAIR_STYLES):
		e.append("%s: hair style '%s' (known: %s)" % [where, hair.get("style"), ", ".join(PackedStringArray(HAIR_STYLES))])
	var o: Dictionary = t.get("outfit", {})
	for k in o:
		if not (k in OUTFIT_KEYS):
			e.append("%s: toon.outfit has unknown key '%s'" % [where, k])
	if not (String(o.get("style", "tee")) in OUTFIT_STYLES):
		e.append("%s: outfit style '%s' (known: %s)" % [where, o.get("style"), ", ".join(PackedStringArray(OUTFIT_STYLES))])
	for k in ["color", "tie", "accent"]:
		if o.has(k) and not Color.html_is_valid(String(o[k])):
			e.append("%s: toon.outfit.%s is not a hex colour" % [where, k])
	if hair.has("color") and not Color.html_is_valid(String(hair["color"])):
		e.append("%s: toon.hair.color is not a hex colour" % where)
	for a in t.get("accessories", []):
		if not (String(a) in ACCESSORIES):
			e.append("%s: accessory '%s' (known: %s)" % [where, a, ", ".join(PackedStringArray(ACCESSORIES))])
	if t.has("face") and not faces().has(String(t["face"])):
		e.append("%s: face '%s' is not in library/toon/faces.json" % [where, t["face"]])
	if t.has("girth") and (float(t["girth"]) < 0.7 or float(t["girth"]) > 1.5):
		e.append("%s: girth must be 0.7..1.5" % where)
	return e


## Walk animations come from the mannequin; a toon's legs are shorter, so it
## covers less ground per cycle (feet stay planted at the slower speed).
static func stride_ratio() -> float:
	return HIP * H / MANNEQUIN_HIP


# --- build --------------------------------------------------------------------------

## Builds the toon on a mannequin body (whose meshes are hidden; its skeleton
## stays the animation source). Returns {"skeleton", "face", "head_center",
## "head_r", "head_bone"} (body space; head_bone = the Head bone's rest height).
static func build(body: Node3D, src: Skeleton3D, t: Dictionary) -> Dictionary:
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visible = false
	var sk := _skeleton(src)
	src.get_parent().add_child(sk)
	sk.transform = src.transform
	var ctx := {"sk": sk, "x": _chain(sk, body), "att": {}}
	var girth := float(t.get("girth", 1.0))
	# Head and face.
	var hr := HEAD_R * H
	var hc := Vector3(0, HEAD_C * H, 0.0)
	var face := ShaderMaterial.new()
	face.shader = FACE_SHADER
	face.set_shader_parameter("radius", hr)
	face.set_shader_parameter("skin", Color(String(t.get("skin", "#f4f4f2"))))
	if t.has("mustache"):
		face.set_shader_parameter("mustache", 1.0)
		face.set_shader_parameter("mustache_color", Color(String(t["mustache"])))
	if t.has("beard"):
		face.set_shader_parameter("beard", 1.0)
		face.set_shader_parameter("beard_color", Color(String(t["beard"])))
	face.next_pass = _outline(OUTLINE)
	apply_face(face, String(t.get("face", "smug")))
	var head := MeshInstance3D.new()
	head.name = "head"
	head.mesh = _sphere(hr, 48, 24)
	head.material_override = face
	var head_root := Node3D.new()
	head_root.name = "toon_head"
	_attach(ctx, "Head", Transform3D(Basis.IDENTITY, hc), head_root)
	head_root.add_child(head)
	_hair(head_root, t.get("hair", {}), hr)
	for a in t.get("accessories", []):
		_accessory(head_root, String(a), hr)
	# Torso (the outfit).
	var o: Dictionary = t.get("outfit", {})
	var style := String(o.get("style", "tee"))
	var col := Color(String(o.get("color", "#2f7be0" if style == "hoodie" else ("#f2f2f2" if style in ["labcoat", "shirt", "kurta", "coverall"] else "#1c1c20"))))
	var bh := (BEAN_TOP - BEAN_BOTTOM) * H
	var rb := BEAN_R * H * girth * (1.25 if style == "dress" else 1.0)
	var rt := BEAN_R_TOP * H * lerpf(1.0, girth, 0.5)
	var torso := Node3D.new()
	torso.name = "toon_torso"
	_attach(ctx, "spine_01", Transform3D(Basis.IDENTITY, Vector3(0, BEAN_BOTTOM * H, -0.025)), torso)
	var bean := MeshInstance3D.new()
	bean.mesh = _bean(rb, rt, bh)
	bean.material_override = _camo(o, col, OUTLINE) if style == "fatigues" else _mat(col, OUTLINE)
	torso.add_child(bean)
	_outfit(torso, o, style, col, rb, rt, bh)
	# Limbs, hands, shoes.
	for s in ["l", "r"]:
		_limb(ctx, "upperarm_" + s, "lowerarm_" + s)
		_limb(ctx, "lowerarm_" + s, "hand_" + s)
		_limb(ctx, "thigh_" + s, "calf_" + s)
		_limb(ctx, "calf_" + s, "foot_" + s)
		_ball(ctx, "lowerarm_" + s, _rest(ctx, "lowerarm_" + s), LIMB_R * H, LIMB_COLOR, 0.0)
		_ball(ctx, "calf_" + s, _rest(ctx, "calf_" + s), LIMB_R * H, LIMB_COLOR, 0.0)
		_ball(ctx, "foot_" + s, _rest(ctx, "foot_" + s), LIMB_R * H, LIMB_COLOR, 0.0)
		var hand := _rest(ctx, "hand_" + s)
		var dir := (hand - _rest(ctx, "lowerarm_" + s)).normalized()
		_ball(ctx, "hand_" + s, hand + dir * HAND_R * H * 0.55, HAND_R * H, LIMB_COLOR, 0.0)
		var foot := _rest(ctx, "foot_" + s)
		var shoe := MeshInstance3D.new()
		shoe.mesh = _sphere(1.0, 24, 12)
		shoe.material_override = _mat(Color(String(t.get("shoes", "#1f2a44"))), OUTLINE * 0.8)
		var sr := Vector3(0.03, 0.024, 0.048) * H
		var holder := Node3D.new()
		_attach(ctx, "foot_" + s, Transform3D(Basis.IDENTITY.scaled(sr), Vector3(foot.x, sr.y, foot.z + sr.z * 0.35)), holder)
		holder.add_child(shoe)
	return {"skeleton": sk, "face": face, "head_center": hc, "head_r": hr, "head_bone": _rest(ctx, "Head").y}


## Body-space rest position of a toon bone.
static func _rest(ctx: Dictionary, bone: String) -> Vector3:
	var sk: Skeleton3D = ctx["sk"]
	return ((ctx["x"] as Transform3D) * sk.get_bone_global_rest(sk.find_bone(bone))).origin


## Hang `node` on a bone so that at rest it sits at `body_xf` (body space).
static func _attach(ctx: Dictionary, bone: String, body_xf: Transform3D, node: Node3D) -> void:
	var sk: Skeleton3D = ctx["sk"]
	var att: Dictionary = ctx["att"]
	if not att.has(bone):
		var ba := BoneAttachment3D.new()
		ba.name = "toon_" + bone
		ba.bone_name = bone
		sk.add_child(ba)
		att[bone] = ba
	var g: Transform3D = (ctx["x"] as Transform3D) * sk.get_bone_global_rest(sk.find_bone(bone))
	node.transform = g.affine_inverse() * body_xf
	(att[bone] as Node3D).add_child(node)


## A copy of the mannequin skeleton with the toon's proportions: hips dropped,
## shins and thighs shortened, everything else (and every rest rotation) kept.
static func _skeleton(src: Skeleton3D) -> Skeleton3D:
	var n := src.get_bone_count()
	var g := []
	for i in n:
		g.append(src.get_bone_global_rest(i))
	var pelvis := src.find_bone("pelvis")
	var drop: float = (g[pelvis] as Transform3D).origin.y - HIP * H
	var thigh: Vector3 = (g[src.find_bone("thigh_l")] as Transform3D).origin
	var foot: Vector3 = (g[src.find_bone("foot_l")] as Transform3D).origin
	var k := (thigh.y - drop - ANKLE * H) / (thigh.y - foot.y)
	var sk := Skeleton3D.new()
	sk.name = "toon_skeleton"
	var pos := []
	var gn := []
	for i in n:
		sk.add_bone(src.get_bone_name(i))
		var p := src.get_bone_parent(i)
		assert(p < i, "toon: skeleton bones must be ordered parents first")
		var o: Vector3 = (g[i] as Transform3D).origin
		if p >= 0:
			var off: Vector3 = o - (g[p] as Transform3D).origin
			if src.get_bone_name(i) in SHORTEN:
				off *= k
			o = pos[p] + off
			if i == pelvis:
				o = (g[i] as Transform3D).origin - Vector3(0, drop, 0)
		pos.append(o)
		gn.append(Transform3D((g[i] as Transform3D).basis, o))
	for i in n:
		var p := src.get_bone_parent(i)
		sk.set_bone_parent(i, p)
		sk.set_bone_rest(i, gn[i] if p < 0 else (gn[p] as Transform3D).affine_inverse() * gn[i])
	sk.reset_bone_poses()
	return sk


static func _chain(n: Node, top: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	while n != null and n != top:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


# --- parts ------------------------------------------------------------------------

## A stick between two bones' rest positions, hung on the first.
static func _limb(ctx: Dictionary, a: String, b: String) -> void:
	var pa := _rest(ctx, a)
	var pb := _rest(ctx, b)
	var mi := MeshInstance3D.new()
	mi.mesh = _cylinder()
	mi.material_override = _mat(LIMB_COLOR, 0.0)
	var r := LIMB_R * H
	var basis := _cols(_basis_y(pb - pa), Vector3(r, pa.distance_to(pb), r))
	_attach(ctx, a, Transform3D(basis, (pa + pb) * 0.5), mi)


static func _ball(ctx: Dictionary, bone: String, at: Vector3, r: float, col: Color, outline: float) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _sphere(r, 16, 8)
	mi.material_override = _mat(col, outline)
	_attach(ctx, bone, Transform3D(Basis.IDENTITY, at), mi)


## Basis with its columns (local axes) scaled.
static func _cols(b: Basis, s: Vector3) -> Basis:
	return Basis(b.x * s.x, b.y * s.y, b.z * s.z)


## Basis whose Y axis points along `dir` (unit length columns).
static func _basis_y(dir: Vector3) -> Basis:
	var y := dir.normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)


static func _hair(head: Node3D, h: Dictionary, hr: float) -> void:
	var style := String(h.get("style", "bowl"))
	if style == "bald":
		return
	if style == "hardhat":
		_hardhat(head, h, hr)
		return
	if style == "turban":
		_turban(head, h, hr)
		return
	var col := Color(String(h.get("color", "#5a3a22")))
	var hl: Array = HAIRLINES[style]
	var shell := MeshInstance3D.new()
	shell.name = "hair"
	shell.mesh = _cap(float(hl[0]), float(hl[1]), float(hl[2]), hr * float(hl[3]), 0.0)
	var mat := ShaderMaterial.new()
	mat.shader = HAIR_SHADER
	mat.set_shader_parameter("color", col.darkened(0.25) if style == "curly" else col)
	mat.set_shader_parameter("radius", hr)
	mat.set_shader_parameter("mode", 1 if style == "slick" else 0)
	mat.set_shader_parameter("strands", 0.0 if style in ["curly", "cap", "beanie", "hood", "patrol"] else (0.07 if style == "slick" else (0.12 if style == "side" else 0.22)))
	mat.next_pass = _outline(OUTLINE * 0.8)
	shell.material_override = mat
	if style == "beanie":
		shell.scale = Vector3(1.0, 1.1, 1.0)
	head.add_child(shell)
	match style:
		"tuft":
			var tuft := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.0
			cm.bottom_radius = hr * 0.12
			cm.height = hr * 0.26
			tuft.mesh = cm
			tuft.material_override = _mat(col, OUTLINE * 0.6)
			tuft.position = Vector3(0, hr * 1.12, -hr * 0.04)
			tuft.rotation_degrees = Vector3(-12, 0, 0)
			head.add_child(tuft)
		"curly":
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = _sphere(hr * 0.17, 12, 6)
			var pts := []
			var total := 420
			for i in total:
				var y := 1.0 - (float(i) + 0.5) / float(total) * 2.0
				var phi := float(i) * 2.399963
				var th := rad_to_deg(acos(y))
				var ph := fposmod(phi, TAU)
				if th < _hairline(float(hl[0]), float(hl[1]), float(hl[2]), ph) - 6.0:
					var rr := sqrt(1.0 - y * y)
					pts.append(Vector3(rr * sin(ph), y, rr * cos(ph)) * hr * 1.02)
			mm.instance_count = pts.size()
			for i in pts.size():
				mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, pts[i]))
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "curls"
			mmi.multimesh = mm
			mmi.material_override = _mat(col, OUTLINE * 0.45)
			head.add_child(mmi)
		"cap":
			var brim := MeshInstance3D.new()
			brim.mesh = _sphere(1.0, 24, 8)
			brim.material_override = _mat(col.darkened(0.1), OUTLINE * 0.6)
			var a := deg_to_rad(float(hl[0]) + 4.0)
			brim.transform = Transform3D(_cols(Basis.from_euler(Vector3(deg_to_rad(12), 0, 0)), Vector3(hr * 0.62, hr * 0.06, hr * 0.5)),
				Vector3(0, cos(a) * hr * 1.04, sin(a) * hr * 1.04 + hr * 0.12))
			head.add_child(brim)
		"patrol":
			# An army patrol cap: the crown rises straight to a flat top, a short stiff peak in front.
			shell.scale = Vector3(1.0, 1.06, 1.0)
			var top := MeshInstance3D.new()
			var cm2 := CylinderMesh.new()
			cm2.top_radius = hr * 0.74
			cm2.bottom_radius = hr * 0.9
			cm2.height = hr * 0.34
			cm2.radial_segments = 24
			top.mesh = cm2
			top.material_override = mat
			top.position = Vector3(0, hr * 0.98, -hr * 0.03)
			top.rotation_degrees = Vector3(-6, 0, 0)
			head.add_child(top)
			var peak := MeshInstance3D.new()
			peak.mesh = _sphere(1.0, 24, 8)
			peak.material_override = _mat(col.darkened(0.2), OUTLINE * 0.6)
			var a2 := deg_to_rad(float(hl[0]) + 6.0)
			peak.transform = Transform3D(_cols(Basis.from_euler(Vector3(deg_to_rad(18), 0, 0)), Vector3(hr * 0.5, hr * 0.05, hr * 0.36)),
				Vector3(0, cos(a2) * hr * 1.05, sin(a2) * hr * 1.05 + hr * 0.08))
			head.add_child(peak)
		"beanie":
			var band := MeshInstance3D.new()
			band.mesh = _cap(float(hl[0]), float(hl[1]), float(hl[2]), hr * 1.12, 16.0)
			band.material_override = _mat(col.darkened(0.15), OUTLINE * 0.6)
			band.scale = shell.scale
			head.add_child(band)
		"side":
			# A side parting: the hair sweeps from a parting on the left into a soft wave over the right brow.
			var wave := MeshInstance3D.new()
			wave.mesh = _sphere(1.0, 20, 10)
			wave.material_override = mat
			wave.transform = Transform3D(_cols(Basis.from_euler(Vector3(deg_to_rad(-30), deg_to_rad(-18), deg_to_rad(12))),
				Vector3(hr * 0.42, hr * 0.13, hr * 0.3)), Vector3(-hr * 0.22, hr * 0.78, hr * 0.5))
			head.add_child(wave)
			var part := MeshInstance3D.new()
			part.mesh = _cylinder()
			part.material_override = _mat(col.darkened(0.45), 0.0)
			part.transform = Transform3D(_cols(Basis.from_euler(Vector3(PI / 2 - 0.5, 0, 0)), Vector3(hr * 0.012, hr * 0.5, hr * 0.012)),
				Vector3(hr * 0.3, hr * 0.92, hr * 0.12))
			head.add_child(part)
		"hood":
			# A clean-room hood: the shell reaches down round the cheeks and under the chin, with a
			# soft elastic rim framing the face.
			var rim := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = hr * 0.82
			tm.outer_radius = hr * 0.98
			tm.rings = 32
			tm.ring_segments = 8
			rim.mesh = tm
			rim.material_override = _mat(col.darkened(0.05), OUTLINE * 0.5)
			rim.transform = Transform3D(Basis.from_euler(Vector3(PI / 2, 0, 0)).scaled(Vector3(1.0, 1.0, 1.12)), Vector3(0, -hr * 0.02, hr * 0.5))
			head.add_child(rim)
			var collar := MeshInstance3D.new()
			collar.mesh = _sphere(1.0, 24, 10)
			collar.material_override = _mat(col.darkened(0.03), OUTLINE * 0.6)
			collar.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(hr * 0.72, hr * 0.32, hr * 0.62)), Vector3(0, -hr * 0.82, -hr * 0.12))
			head.add_child(collar)
		"bun":
			var bun := MeshInstance3D.new()
			bun.mesh = _sphere(hr * 0.3, 20, 10)
			bun.material_override = _mat(col, OUTLINE * 0.7)
			bun.position = Vector3(0, hr * 0.8, -hr * 0.75)
			head.add_child(bun)


## A site hard hat: ribbed dome tilted back a little, a brim all round, a front peak and
## (with "lamp": true) a strapped headlamp whose lens is the node "lamp_lens" (its own emissive
## material, so a gag can switch one worker's lamp).
static func _hardhat(head: Node3D, h: Dictionary, hr: float) -> void:
	var col := Color(String(h.get("color", "#f2c230")))
	var shell := _mat(col, OUTLINE * 0.8)
	var hat := Node3D.new()
	hat.name = "hardhat"
	hat.rotation_degrees = Vector3(-7, 0, 0)
	head.add_child(hat)
	var rim_deg := 62.0
	var r := hr * 1.08
	var tall := 1.12
	var rim_y := cos(deg_to_rad(rim_deg)) * r * tall
	var rim_r := sin(deg_to_rad(rim_deg)) * r
	var dome := MeshInstance3D.new()
	dome.mesh = _cap(rim_deg, rim_deg, rim_deg, r, 0.0)
	dome.material_override = shell
	dome.scale = Vector3(1, tall, 1)
	hat.add_child(dome)
	var brim := MeshInstance3D.new()
	brim.mesh = _sphere(1.0, 32, 8)
	brim.material_override = shell
	brim.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(rim_r * 1.14, hr * 0.055, rim_r * 1.14)), Vector3(0, rim_y, 0))
	hat.add_child(brim)
	var peak := MeshInstance3D.new()
	peak.mesh = _sphere(1.0, 24, 8)
	peak.material_override = shell
	peak.transform = Transform3D(_cols(Basis.from_euler(Vector3(deg_to_rad(9), 0, 0)), Vector3(rim_r * 0.74, hr * 0.05, rim_r * 0.56)),
		Vector3(0, rim_y - hr * 0.02, rim_r * 0.84))
	hat.add_child(peak)
	# Three raised ribs over the crown, front to back.
	for x in [-0.36, 0.0, 0.36]:
		var rib := MeshInstance3D.new()
		rib.mesh = _half_sphere()
		rib.material_override = _mat(col.lightened(0.12), OUTLINE * 0.35)
		var off: float = x * r
		var run := sqrt(maxf(rim_r * rim_r - off * off, 0.0001))
		var rise := (sqrt(r * r - off * off) - r * cos(deg_to_rad(rim_deg))) * tall
		rib.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(hr * (0.075 if x == 0.0 else 0.055), rise + hr * 0.035, run * 0.99)),
			Vector3(off, rim_y, 0))
		hat.add_child(rib)
	if not bool(h.get("lamp", false)):
		return
	var strap := MeshInstance3D.new()
	strap.mesh = _cap(rim_deg, rim_deg, rim_deg, r * 1.025, 11.0)
	strap.material_override = _mat(Color("1d1f24"), 0.0)
	strap.scale = Vector3(1, tall, 1)
	hat.add_child(strap)
	var a := deg_to_rad(rim_deg - 9.0)
	var at := Vector3(0, cos(a) * r * tall, sin(a) * r * 1.03)
	var aim := Basis.looking_at(Vector3(0, -0.12, 1.0), Vector3.UP)   # -Z of this basis: out of the forehead, a touch down
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(hr * 0.34, hr * 0.24, hr * 0.2)
	body.mesh = bm
	body.material_override = _mat(Color("26282e"), OUTLINE * 0.4)
	body.transform = Transform3D(aim, at)
	hat.add_child(body)
	var lens := MeshInstance3D.new()
	lens.name = "lamp_lens"
	var lm := CylinderMesh.new()
	lm.top_radius = hr * 0.095
	lm.bottom_radius = hr * 0.095
	lm.height = hr * 0.05
	lm.radial_segments = 16
	lens.mesh = lm
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("fff6dc")
	glow.emission_enabled = true
	glow.emission = Color("fff0c4")
	glow.emission_energy_multiplier = 3.5
	lens.material_override = glow
	lens.transform = Transform3D(aim * Basis.from_euler(Vector3(PI / 2, 0, 0)), at + aim * Vector3(0, 0, -hr * 0.1))
	hat.add_child(lens)


## A wrapped turban (pagdi): a full dome over the crown with diagonal wraps crossing in front.
static func _turban(head: Node3D, h: Dictionary, hr: float) -> void:
	var col := Color(String(h.get("color", "#f2efe6")))
	var t := Node3D.new()
	t.name = "turban"
	head.add_child(t)
	var dome := MeshInstance3D.new()
	dome.mesh = _cap(58, 80, 96, hr * 1.13, 0.0)
	dome.material_override = _mat(col, OUTLINE * 0.8)
	dome.scale = Vector3(1.04, 1.12, 1.02)
	t.add_child(dome)
	for i in 4:
		var wrap := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = hr * 0.86
		tm.outer_radius = hr * 1.08
		tm.rings = 28
		tm.ring_segments = 10
		wrap.mesh = tm
		wrap.material_override = _mat(col.darkened(0.04 + 0.03 * float(i % 2)), OUTLINE * 0.45)
		var tilt := deg_to_rad(16.0 + 7.0 * float(i)) * (1.0 if i % 2 == 0 else -1.0)
		wrap.transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(-10.0), 0, tilt)).scaled(Vector3(1.0, 0.5, 1.0)),
			Vector3(0, hr * (0.42 + 0.13 * float(i)), -hr * 0.02))
		t.add_child(wrap)
	var knot := MeshInstance3D.new()
	knot.mesh = _sphere(hr * 0.2, 16, 8)
	knot.material_override = _mat(col.darkened(0.08), OUTLINE * 0.5)
	knot.position = Vector3(hr * 0.05, hr * 0.98, hr * 0.62)
	t.add_child(knot)


static func _accessory(head: Node3D, a: String, hr: float) -> void:
	if a == "mask":
		var mask := MeshInstance3D.new()
		mask.mesh = _sphere(1.0, 24, 12)
		mask.material_override = _mat(Color("e9eef2"), OUTLINE * 0.4)
		mask.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(hr * 0.58, hr * 0.36, hr * 0.3)), Vector3(0, -hr * 0.36, hr * 0.8))
		head.add_child(mask)
		return
	if a == "rimless":
		# Rimless glasses: two pale lenses with a thin gold bridge and temples, no frame.
		for s in [-1.0, 1.0]:
			var lens := MeshInstance3D.new()
			lens.mesh = _sphere(1.0, 16, 8)
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(0.85, 0.9, 0.95, 0.35)
			lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			lm.roughness = 0.05
			lm.metallic_specular = 1.0
			lens.material_override = lm
			lens.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(hr * 0.19, hr * 0.14, hr * 0.02)), Vector3(0.40 * hr * s, hr * 0.07, hr * 0.98))
			head.add_child(lens)
			var temple := MeshInstance3D.new()
			temple.mesh = _cylinder()
			temple.material_override = _mat(Color("c9a64a"), 0.0)
			var from := Vector3(0.59 * hr * s, hr * 0.1, hr * 0.92)
			var to := Vector3(0.94 * hr * s, hr * 0.1, hr * 0.12)
			temple.transform = Transform3D(_cols(_basis_y(to - from), Vector3(hr * 0.012, from.distance_to(to), hr * 0.012)), (from + to) * 0.5)
			head.add_child(temple)
		var br := MeshInstance3D.new()
		br.mesh = _cylinder()
		br.material_override = _mat(Color("c9a64a"), 0.0)
		br.transform = Transform3D(_cols(_basis_y(Vector3.RIGHT), Vector3(hr * 0.012, hr * 0.42, hr * 0.012)), Vector3(0, hr * 0.12, hr * 1.0))
		head.add_child(br)
		return
	var dark := a in ["sunglasses", "smart_glasses"]
	var frame_col := Color("101012")
	var lens_col := Color("15171c") if dark else Color("dfe8f0")
	var z := hr * 0.97
	var y := hr * 0.07
	var size := Vector2(0.36, 0.27) * hr if a != "smart_glasses" else Vector2(0.4, 0.3) * hr
	if a == "round_glasses":
		for s in [-1.0, 1.0]:
			var ring := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = hr * 0.17
			tm.outer_radius = hr * 0.205
			ring.mesh = tm
			ring.material_override = _mat(Color("f4f4f4"), OUTLINE * 0.5)
			ring.transform = Transform3D(Basis.from_euler(Vector3(PI / 2, 0, 0)), Vector3(0.40 * hr * s, y, z))
			head.add_child(ring)
		return
	for s in [-1.0, 1.0]:
		var frame := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(size.x, size.y, hr * 0.06)
		frame.mesh = bm
		frame.material_override = _mat(frame_col, OUTLINE * 0.5)
		frame.position = Vector3(0.40 * hr * s, y, z)
		head.add_child(frame)
		var lens := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(size.x * 0.8, size.y * 0.72, hr * 0.02)
		lens.mesh = lm
		lens.material_override = _mat(lens_col, 0.0)
		lens.position = Vector3(0.40 * hr * s, y, z + hr * 0.025)
		head.add_child(lens)
		var temple := MeshInstance3D.new()
		var tb := BoxMesh.new()
		var from := Vector3((0.40 * hr + size.x * 0.5) * s, y, z)
		var to := Vector3(hr * 0.93 * s, y, hr * 0.15)
		tb.size = Vector3(hr * 0.035, hr * 0.035, from.distance_to(to))
		temple.mesh = tb
		temple.material_override = _mat(frame_col, 0.0)
		temple.transform = Transform3D(Basis.looking_at(to - from, Vector3.UP), (from + to) * 0.5)
		head.add_child(temple)
	var bridge := MeshInstance3D.new()
	var brm := BoxMesh.new()
	brm.size = Vector3(0.8 * hr - size.x, hr * 0.04, hr * 0.04)
	bridge.mesh = brm
	bridge.material_override = _mat(frame_col, 0.0)
	bridge.position = Vector3(0, y + size.y * 0.2, z)
	head.add_child(bridge)
	if a == "smart_glasses":
		var led := MeshInstance3D.new()
		led.mesh = _sphere(hr * 0.03, 8, 4)
		var lm2 := StandardMaterial3D.new()
		lm2.albedo_color = Color("5fe3ff")
		lm2.emission_enabled = true
		lm2.emission = Color("5fe3ff")
		lm2.emission_energy_multiplier = 3.0
		led.material_override = lm2
		led.position = Vector3(0.40 * hr + size.x * 0.5, y + size.y * 0.35, z + hr * 0.03)
		head.add_child(led)


## Outfit details on the bean (torso-local: y from 0 at the bottom to bh).
static func _outfit(torso: Node3D, o: Dictionary, style: String, col: Color, rb: float, rt: float, bh: float) -> void:
	var accent := Color(String(o.get("accent", "#f4f4f4")))
	match style:
		"hoodie":
			for s in [-1.0, 1.0]:
				_surface_line(torso, [Vector2(0.034 * s, 0.9), Vector2(0.036 * s, 0.66)], rb, rt, bh, 0.0085, accent)
			var pocket := MeshInstance3D.new()
			pocket.mesh = _sphere(1.0, 24, 10)
			pocket.material_override = _mat(col.darkened(0.12), OUTLINE * 0.4)
			var py := 0.26
			pocket.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(rb * 0.5, bh * 0.1, rb * 0.04)),
				_surface(0.0, py, rb, rt, bh))
			torso.add_child(pocket)
			var hood := MeshInstance3D.new()
			var tm := TorusMesh.new()
			var hs := 0.93
			var r_at := _bean_r(hs, rb, rt)
			tm.inner_radius = r_at * 0.62
			tm.outer_radius = r_at * 1.02
			tm.rings = 24
			tm.ring_segments = 10
			hood.mesh = tm
			hood.material_override = _mat(col.darkened(0.06), OUTLINE * 0.8)
			hood.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 1.0, BEAN_DEPTH)), Vector3(0, bh * hs, 0))
			torso.add_child(hood)
		"suit":
			if o.has("tie"):
				for s in [-1.0, 1.0]:
					_surface_line(torso, [Vector2(0.07 * s, 0.97), Vector2(0.0, 0.84)], rb, rt, bh, 0.011, Color("f2f2f2"))
				_surface_line(torso, [Vector2(0.0, 0.88), Vector2(0.0, 0.55)], rb, rt, bh, 0.02, Color(String(o["tie"])))
			if bool(o.get("chain", false)):
				for s in [-1.0, 1.0]:
					_surface_line(torso, [Vector2(0.085 * s, 0.97), Vector2(0.06 * s, 0.8), Vector2(0.0, 0.64)], rb, rt, bh, 0.006, Color("e9b51f"))
				var pend := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(0.028, 0.045, 0.014)
				pend.mesh = bm
				pend.material_override = _mat(Color("f0bd28"), 0.0)
				pend.position = _surface(0.0, 0.6, rb, rt, bh)
				torso.add_child(pend)
		"shirt":
			# Collar points, a button placket and buttons.
			for s in [-1.0, 1.0]:
				_surface_line(torso, [Vector2(0.085 * s, 0.975), Vector2(0.02 * s, 0.87)], rb, rt, bh, 0.016, col.darkened(0.12))
			_surface_line(torso, [Vector2(0.0, 0.86), Vector2(0.0, 0.2)], rb, rt, bh, 0.004, col.darkened(0.2))
			for s2 in [0.78, 0.62, 0.46, 0.3]:
				var b := MeshInstance3D.new()
				b.mesh = _sphere(0.011, 8, 4)
				b.material_override = _mat(Color("b9bec6"), 0.0)
				b.position = _surface(0.012, s2, rb, rt, bh) + Vector3(0, 0, 0.004)
				torso.add_child(b)
			if o.has("tie"):
				_surface_line(torso, [Vector2(0.0, 0.88), Vector2(0.0, 0.55)], rb, rt, bh, 0.02, Color(String(o["tie"])))
		"labcoat":
			for s in [-1.0, 1.0]:
				_surface_line(torso, [Vector2(0.075 * s, 0.97), Vector2(0.012 * s, 0.68)], rb, rt, bh, 0.006, Color("9aa3ad"))
			_surface_line(torso, [Vector2(0.0, 0.68), Vector2(0.0, 0.08)], rb, rt, bh, 0.005, Color("9aa3ad"))
			if o.has("tie"):
				_surface_line(torso, [Vector2(0.0, 0.92), Vector2(0.0, 0.7)], rb, rt, bh, 0.018, Color(String(o["tie"])))
		"hivis":
			# A safety vest: the bean is the vest, trousers below, reflective tape round the
			# waist and over both shoulders (front and back), a zip down the front.
			_patch(torso, _bean_patch(rb, rt, bh, 0.0, 0.3, 0.0, 360.0, 0.02), _mat(Color(String(o.get("accent", "#2a3550"))), 0.0))
			_patch(torso, _bean_patch(rb, rt, bh, 0.345, 0.415, 0.0, 360.0, 0.04), _tape())
			for a in [-25.0, 25.0, 155.0, 205.0]:
				_patch(torso, _bean_patch(rb, rt, bh, 0.415, 0.93, a - 5.5, a + 5.5, 0.04), _tape())
			_surface_line(torso, [Vector2(0.0, 0.94), Vector2(0.0, 0.31)], rb, rt, bh, 0.0045, col.darkened(0.5))


		"kurta":
			# A kurta (the bean, in `color`) with a band collar and a short placket; with "vest": a
			# sleeveless band-collared jacket over it (Modi jacket) from the hips up, buttoned down the front.
			if o.has("vest"):
				var vc := Color(String(o["vest"]))
				_patch(torso, _bean_patch(rb, rt, bh, 0.27, 0.955, 0.0, 360.0, 0.035), _mat(vc, OUTLINE * 0.5))
				_surface_line(torso, [Vector2(0.0, 0.95), Vector2(0.0, 0.28)], rb, rt, bh, 0.0035, vc.darkened(0.35))
				for s2 in [0.85, 0.7, 0.55, 0.4]:
					var b := MeshInstance3D.new()
					b.mesh = _sphere(0.012, 8, 4)
					b.material_override = _mat(vc.lightened(0.35), 0.0)
					b.position = _surface(0.0, s2, rb, rt, bh) * Vector3(1, 1, 1.04) + Vector3(0, 0, 0.01)
					torso.add_child(b)
				for s in [-1.0, 1.0]:
					var pk := MeshInstance3D.new()
					pk.mesh = BoxMesh.new()
					(pk.mesh as BoxMesh).size = Vector3(0.05, 0.006, 0.01)
					pk.material_override = _mat(vc.darkened(0.25), 0.0)
					pk.position = _surface(0.045 * s, 0.62, rb, rt, bh) * Vector3(1, 1, 1.04) + Vector3(0, 0, 0.012)
					torso.add_child(pk)
			_surface_line(torso, [Vector2(-0.045, 0.975), Vector2(0.045, 0.975)], rb, rt, bh, 0.012, (Color(String(o["vest"])) if o.has("vest") else col).darkened(0.1))
		"fatigues":
			# Army fatigues (the bean in camouflage, see _camo): a web belt with a buckle, collar points, a button
			# placket and two buttoned chest pocket flaps.
			var dk := col.darkened(0.45)
			_patch(torso, _bean_patch(rb, rt, bh, 0.3, 0.355, 0.0, 360.0, 0.03), _mat(Color("4a4630"), OUTLINE * 0.3))
			var buckle := MeshInstance3D.new()
			buckle.mesh = BoxMesh.new()
			(buckle.mesh as BoxMesh).size = Vector3(0.036, 0.026, 0.01)
			buckle.material_override = _mat(Color("8a8a7a"), 0.0)
			buckle.position = _surface(0.0, 0.327, rb, rt, bh) * Vector3(1, 1, 1.03) + Vector3(0, 0, 0.01)
			torso.add_child(buckle)
			for s in [-1.0, 1.0]:
				_surface_line(torso, [Vector2(0.085 * s, 0.975), Vector2(0.02 * s, 0.87)], rb, rt, bh, 0.016, dk)
				_surface_line(torso, [Vector2(0.03 * s, 0.73), Vector2(0.095 * s, 0.73)], rb, rt, bh, 0.009, dk)
				var bt := MeshInstance3D.new()
				bt.mesh = _sphere(0.008, 8, 4)
				bt.material_override = _mat(Color("2c2a1e"), 0.0)
				bt.position = _surface(0.062 * s, 0.705, rb, rt, bh) + Vector3(0, 0, 0.008)
				torso.add_child(bt)
			_surface_line(torso, [Vector2(0.0, 0.86), Vector2(0.0, 0.37)], rb, rt, bh, 0.004, dk)
		"coverall":
			# A clean-room coverall: the zip runs from the collar to the crotch, with a chest pocket.
			_surface_line(torso, [Vector2(0.0, 0.96), Vector2(0.0, 0.08)], rb, rt, bh, 0.004, col.darkened(0.28))
			_surface_line(torso, [Vector2(0.04, 0.72), Vector2(0.11, 0.72)], rb, rt, bh, 0.003, col.darkened(0.2))
			for s in [-1.0, 1.0]:
				_surface_line(torso, [Vector2(0.08 * s, 0.97), Vector2(0.02 * s, 0.9)], rb, rt, bh, 0.012, col.darkened(0.08))
	if bool(o.get("bow", false)):
		# A black bow tie at the collar (tuxedo).
		for s in [-1.0, 1.0]:
			var w := MeshInstance3D.new()
			w.mesh = _sphere(1.0, 12, 6)
			w.material_override = _mat(Color("0d0d10"), OUTLINE * 0.3)
			w.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(0.028, 0.017, 0.01)), _surface(0.027 * s, 0.94, rb, rt, bh) + Vector3(0, 0, 0.012))
			torso.add_child(w)
		for s in [-1.0, 1.0]:
			_surface_line(torso, [Vector2(0.07 * s, 0.97), Vector2(0.03 * s, 0.6)], rb, rt, bh, 0.012, Color("f2f2ee"))
	if o.has("badge"):
		# An ID card on a lanyard: the strap in `badge` colour round the neck, a white card on the chest.
		var bc := Color(String(o["badge"]))
		for s in [-1.0, 1.0]:
			_surface_line(torso, [Vector2(0.06 * s, 0.97), Vector2(0.035 * s, 0.75), Vector2(0.0, 0.62)], rb, rt, bh, 0.0045, bc)
		var card := MeshInstance3D.new()
		card.name = "id_card"
		var cm := BoxMesh.new()
		cm.size = Vector3(0.05, 0.07, 0.004)
		card.mesh = cm
		card.material_override = _mat(Color("f4f4f0"), OUTLINE * 0.25)
		card.position = _surface(0.0, 0.55, rb, rt, bh) + Vector3(0, 0, 0.012)
		torso.add_child(card)
		var stripe := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.05, 0.016, 0.005)
		stripe.mesh = sm
		stripe.material_override = _mat(bc, 0.0)
		stripe.position = card.position + Vector3(0, 0.024, 0.001)
		torso.add_child(stripe)


## Camouflage cloth for fatigues: blotches of the outfit `camo` colours (default: the Indian Army's 1990s
## disruptive pattern, olive with brown, dark green and khaki) over `color`, in the bean's own space so the
## pattern moves with the body. Same plastic sheen and outline as _mat.
const CAMO_SHADER := """
shader_type spatial;
uniform vec4 base : source_color;
uniform vec4 c1 : source_color;
uniform vec4 c2 : source_color;
uniform vec4 c3 : source_color;
varying vec3 lp;
float h3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float n3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1,0,0)), f.x), mix(h3(i + vec3(0,1,0)), h3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h3(i + vec3(0,0,1)), h3(i + vec3(1,0,1)), f.x), mix(h3(i + vec3(0,1,1)), h3(i + vec3(1,1,1)), f.x), f.y), f.z);
}
float blot(vec3 p) { return n3(p) * 0.65 + n3(p * 2.3) * 0.35; }
void vertex() { lp = VERTEX; }
void fragment() {
	vec3 p = lp * vec3(14.0, 9.0, 14.0);
	vec3 col = base.rgb;
	col = mix(col, c1.rgb, step(0.62, blot(p + vec3(3.1, 0.0, 1.7))));
	col = mix(col, c2.rgb, step(0.64, blot(p * 1.1 + vec3(-5.2, 2.0, 0.4))));
	col = mix(col, c3.rgb, step(0.7, blot(p * 1.25 + vec3(8.0, -1.0, 4.4))));
	ALBEDO = col;
	ROUGHNESS = 0.62;
	SPECULAR = 0.4;
	RIM = 0.3;
	RIM_TINT = 0.75;
}
"""

static func _camo(o: Dictionary, col: Color, outline: float) -> ShaderMaterial:
	var cs: Array = o.get("camo", ["#5c4a32", "#2f3826", "#8c8459"])
	var key := "camo|%s|%s" % [col.to_html(), ",".join(PackedStringArray(cs))]
	if not _mats.has(key):
		var m := ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = CAMO_SHADER
		m.shader = sh
		m.set_shader_parameter("base", col)
		for i in 3:
			m.set_shader_parameter("c%d" % (i + 1), Color(String(cs[mini(i, cs.size() - 1)])))
		m.next_pass = _outline(outline)
		_mats[key] = m
	return _mats[key]


static func _patch(torso: Node3D, mesh: Mesh, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	torso.add_child(mi)


## Retro-reflective tape: pale silver that still reads in a dark set.
static func _tape() -> StandardMaterial3D:
	if not _mats.has("tape"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color("e4eaec")
		m.roughness = 0.32
		m.metallic = 0.25
		m.emission_enabled = true
		m.emission = Color("cdd6da")
		m.emission_energy_multiplier = 0.4
		_mats["tape"] = m
	return _mats["tape"]


static func _half_sphere() -> SphereMesh:
	if not _meshes.has("half"):
		var m := SphereMesh.new()
		m.radius = 1.0
		m.height = 1.0
		m.is_hemisphere = true
		m.radial_segments = 20
		m.rings = 8
		_meshes["half"] = m
	return _meshes["half"]


## A patch of the bean's surface (height fractions s0..s1, azimuth a0..a1 in degrees, 0 = front),
## puffed out from the bean's middle so it lies on top: bands, stripes, panels.
static func _bean_patch(rb: float, rt: float, bh: float, s0: float, s1: float, a0: float, a1: float, puff: float) -> ArrayMesh:
	var key := "patch|%.4f|%.4f|%.4f|%.3f|%.3f|%.1f|%.1f|%.3f" % [rb, rt, bh, s0, s1, a0, a1, puff]
	if _meshes.has(key):
		return _meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var na := maxi(2, ceili(absf(a1 - a0) / 9.0))
	var ns := maxi(2, ceili((s1 - s0) * 28.0))
	var mid := Vector3(0, bh * 0.45, 0)
	for i in ns + 1:
		var s := lerpf(s0, s1, float(i) / ns)
		var r := _bean_r(s, rb, rt)
		for j in na + 1:
			var a := deg_to_rad(lerpf(a0, a1, float(j) / na))
			var p := Vector3(sin(a) * r, s * bh, cos(a) * r * BEAN_DEPTH)
			st.add_vertex(mid + (p - mid) * (1.0 + puff))
	for i in ns:
		for j in na:
			var a := i * (na + 1) + j
			var b := a + 1
			var c := a + na + 1
			var d := c + 1
			st.add_index(a); st.add_index(c); st.add_index(b)
			st.add_index(b); st.add_index(c); st.add_index(d)
	st.generate_normals()
	var m := st.commit()
	_meshes[key] = m
	return m


## Radius of the bean at height fraction s (0 bottom .. 1 top).
static func _bean_r(s: float, rb: float, rt: float) -> float:
	var w := lerpf(rb, rt, smoothstep(0.25, 1.0, s))
	return w * pow(maxf(sin(PI * s), 0.0), 0.36)


## Point on the front of the bean at side offset x (m) and height fraction s.
static func _surface(x: float, s: float, rb: float, rt: float, bh: float) -> Vector3:
	var r := _bean_r(s, rb, rt)
	return Vector3(x, s * bh, BEAN_DEPTH * sqrt(maxf(r * r - x * x, 0.0)))


## A thin tube lying on the bean's front through (x, s) points.
static func _surface_line(torso: Node3D, pts: Array, rb: float, rt: float, bh: float, r: float, col: Color) -> void:
	var path := []
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		for j in 6:
			var f := float(j) / 6.0
			path.append(a.lerp(b, f))
	path.append(pts[-1])
	var prev := Vector3.ZERO
	for i in path.size():
		var p := _surface((path[i] as Vector2).x, (path[i] as Vector2).y, rb, rt, bh)
		p.z += r * 0.5
		if i > 0:
			var mi := MeshInstance3D.new()
			mi.mesh = _cylinder()
			mi.material_override = _mat(col, 0.0)
			mi.transform = Transform3D(_cols(_basis_y(p - prev), Vector3(r, prev.distance_to(p), r)), (p + prev) * 0.5)
			torso.add_child(mi)
		var j := MeshInstance3D.new()
		j.mesh = _sphere(r, 8, 4)
		j.material_override = _mat(col, 0.0)
		j.position = p
		torso.add_child(j)
		prev = p


# --- meshes and materials -----------------------------------------------------------

## Shared toon material (flat colour, soft shading, dark outline when outline > 0).
static func material(col: Color, outline: float) -> StandardMaterial3D:
	return _mat(col, outline)


static func sphere(r: float) -> SphereMesh:
	return _sphere(r, 32, 16)


static func _mat(col: Color, outline: float) -> StandardMaterial3D:
	var key := "%s|%.4f" % [col.to_html(), outline]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		# Toy plastic: a soft sheen and a Fresnel rim that picks up the coloured rim lights.
		m.roughness = 0.42
		m.metallic_specular = 0.55
		m.rim_enabled = true
		m.rim = 0.35
		m.rim_tint = 0.75
		if outline > 0.0:
			m.next_pass = _outline(outline)
		_mats[key] = m
	return _mats[key]


static func _outline(width: float) -> ShaderMaterial:
	var key := "outline|%.4f" % width
	if not _mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = OUTLINE_SHADER
		m.set_shader_parameter("color", INK)
		m.set_shader_parameter("width", width)
		_mats[key] = m
	return _mats[key]


static func _sphere(r: float, seg: int, rings: int) -> SphereMesh:
	var key := "sphere|%.4f|%d|%d" % [r, seg, rings]
	if not _meshes.has(key):
		var m := SphereMesh.new()
		m.radius = r
		m.height = r * 2.0
		m.radial_segments = seg
		m.rings = rings
		_meshes[key] = m
	return _meshes[key]


static func _cylinder() -> CylinderMesh:
	if not _meshes.has("cyl"):
		var m := CylinderMesh.new()
		m.top_radius = 1.0
		m.bottom_radius = 1.0
		m.height = 1.0
		m.radial_segments = 10
		m.rings = 1
		_meshes["cyl"] = m
	return _meshes["cyl"]


## Polar angle (degrees from the crown) of the hairline at azimuth phi (0 = front).
static func _hairline(front: float, side: float, back: float, phi: float) -> float:
	var a := (front + back) * 0.25 + side * 0.5
	var b := (front - back) * 0.5
	var c := (front + back) * 0.25 - side * 0.5
	return a + b * cos(phi) + c * cos(2.0 * phi)


## A spherical shell from the crown down to the hairline (band > 0: only the
## last `band` degrees above the hairline, for a beanie's fold).
static func _cap(front: float, side: float, back: float, r: float, band: float) -> ArrayMesh:
	var key := "cap|%.1f|%.1f|%.1f|%.4f|%.1f" % [front, side, back, r, band]
	if _meshes.has(key):
		return _meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nphi := 48
	var nth := 16
	for i in nth + 1:
		for j in nphi + 1:
			var phi := float(j) / nphi * TAU
			var hl := _hairline(front, side, back, phi)
			var t0 := 0.0 if band <= 0.0 else hl - band
			var th := deg_to_rad(lerpf(t0, hl, float(i) / nth))
			var n := Vector3(sin(th) * sin(phi), cos(th), sin(th) * cos(phi))
			st.set_normal(n)
			st.add_vertex(n * r)
	for i in nth:
		for j in nphi:
			var a := i * (nphi + 1) + j
			var b := a + 1
			var c := a + nphi + 1
			var d := c + 1
			# Godot front faces wind clockwise seen from outside.
			st.add_index(a); st.add_index(b); st.add_index(c)
			st.add_index(b); st.add_index(d); st.add_index(c)
	var m := st.commit()
	_meshes[key] = m
	return m


## The bean torso: a surface of revolution, wide and round at the bottom,
## narrower at the top, a little flattened front to back.
static func _bean(rb: float, rt: float, bh: float) -> ArrayMesh:
	var key := "bean|%.4f|%.4f|%.4f" % [rb, rt, bh]
	if _meshes.has(key):
		return _meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var na := 40
	var ns := 28
	for i in ns + 1:
		var s := float(i) / ns
		var r := _bean_r(s, rb, rt)
		for j in na + 1:
			var a := float(j) / na * TAU
			st.add_vertex(Vector3(sin(a) * r, s * bh, cos(a) * r * BEAN_DEPTH))
	for i in ns:
		for j in na:
			var a := i * (na + 1) + j
			var b := a + 1
			var c := a + na + 1
			var d := c + 1
			st.add_index(a); st.add_index(c); st.add_index(b)
			st.add_index(b); st.add_index(c); st.add_index(d)
	st.generate_normals()
	var m := st.commit()
	_meshes[key] = m
	return m
