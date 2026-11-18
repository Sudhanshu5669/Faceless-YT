extends RefCounted
## An ATM kiosk in an Indian market, November 2016 (line 22): the new ₹2,000 note, which carries a Mangalyaan
## motif on its back (RBI). The note is shown stylised (magenta, the numerals, the orbiter motif), not as a
## faithful banknote reproduction.
##
## Local frame: the kiosk's glass front faces +z at z 0 (3 m wide), the ATM inside against the back wall at
## z -1.6, its slot at (0, 1.05, -1.25). Outside: a queue along the shopfronts, fairy lights, a vegetable cart.
## params: note {"out", "flip"} (the note slides out of the slot; turns to show its back)
## anchors: slot, note, kiosk

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

## The note: magenta paper, guilloche lines, a darker panel with the orbiter motif on the back.
const NOTE := """
shader_type spatial;
render_mode cull_disabled;
uniform float back = 1.0;
varying vec2 uv2;
//NOISE
void vertex() { uv2 = UV; }
void fragment() {
	vec2 p = uv2;
	vec3 col = vec3(0.78, 0.32, 0.58);
	float g = sin(p.x * 120.0 + sin(p.y * 40.0) * 3.0) * sin(p.y * 90.0 + sin(p.x * 30.0) * 2.0);
	col *= 0.88 + 0.12 * g;
	col = mix(col, vec3(0.9, 0.62, 0.78), smoothstep(0.42, 0.0, length(p - vec2(0.8, 0.5))) * 0.5);
	// The orbiter motif: a body, one panel wing, a dish, over a dotted orbit round a planet.
	vec2 q = (p - vec2(0.42, 0.5)) * vec2(2.2, 1.0);
	float orbit = 1.0 - smoothstep(0.0, 0.01, abs(length(q / vec2(0.75, 0.32)) - 1.0));
	orbit *= step(0.5, fract(atan(q.y, q.x) * 8.0));
	float planet = 1.0 - smoothstep(0.17, 0.18, length(q - vec2(0.35, -0.05)));
	vec2 b = q - vec2(-0.25, 0.12);
	float body = step(abs(b.x), 0.07) * step(abs(b.y), 0.08);
	float wing = step(abs(b.x - 0.22), 0.14) * step(abs(b.y), 0.035);
	float dish = 1.0 - smoothstep(0.05, 0.06, length((b - vec2(0.0, 0.12)) * vec2(1.0, 2.2)));
	float ink = clamp(orbit + planet * 0.8 + body + wing + dish, 0.0, 1.0) * back;
	col = mix(col, vec3(0.42, 0.08, 0.3), ink * 0.85);
	ALBEDO = col;
	ROUGHNESS = 0.7;
}
"""

var _p := {}
var _note: Node3D
var _bulbs: Array = []


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	Kit.box(root, Vector3(30, 0.1, 20), Vector3(0, -0.05, 4), Kit.mat("#3a3835", 0.85))
	# Kiosk: tiled floor, steel and glass front, a lit sign band (generic "ATM"), the machine.
	Kit.box(root, Vector3(3, 0.04, 1.8), Vector3(0, 0.02, -0.9), Kit.mat("#cfc9bd", 0.4, 0.0, 0.6))
	Kit.box(root, Vector3(3.2, 3, 0.1), Vector3(0, 1.5, -1.85), Kit.mat("#e6e2d8", 0.6))
	for s in [-1.0, 1.0]:
		Kit.box(root, Vector3(0.1, 3, 1.9), Vector3(s * 1.55, 1.5, -0.9), Kit.mat("#e6e2d8", 0.6))
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.7, 0.8, 0.85, 0.15)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	Kit.box(root, Vector3(1.0, 2.3, 0.04), Vector3(-0.95, 1.2, 0.0), glass)
	Kit.box(root, Vector3(3.2, 0.7, 0.2), Vector3(0, 2.75, 0.0), Kit.mat("#1f4e9e", 0.5))
	Kit.text(root, "ATM", 0.42, Color("ffffff"), Vector3(0, 2.75, 0.12), Vector3.ZERO, true, 2.2)
	Kit.box(root, Vector3(2.9, 0.04, 0.04), Vector3(0, 2.38, 0.05), Kit.lit("#eef6ff", 3.0))
	var atm := Node3D.new()
	atm.position = Vector3(0.1, 0, -1.45)
	root.add_child(atm)
	Kit.slab(atm, Vector3(0.9, 1.7, 0.7), 0.05, Vector3(0, 0.85, 0), Kit.mat("#2d3a4a", 0.45, 0.0, 0.6))
	Kit.box(atm, Vector3(0.7, 0.45, 0.05), Vector3(0, 1.3, 0.36), Kit.mat("#141a22", 0.3))
	Kit.box(atm, Vector3(0.36, 0.26, 0.02), Vector3(0, 1.32, 0.39), Kit.lit("#6fb2ff", 1.4))
	Kit.box(atm, Vector3(0.34, 0.15, 0.12), Vector3(0, 0.98, 0.42), Kit.mat("#7d8590", 0.4), Vector3(0.6, 0, 0))
	Kit.box(atm, Vector3(0.22, 0.012, 0.06), Vector3(0, 1.05, 0.36), Kit.mat("#050505", 0.5))
	Kit.ball(atm, 0.012, Vector3(0.14, 1.07, 0.37), Kit.lit("#29ff6a", 3.0), 6)
	Kit.box(atm, Vector3(0.32, 0.05, 0.03), Vector3(0, 0.75, 0.36), Kit.mat("#050505", 0.5))
	Kit.omni(root, Vector3(0, 2.2, -0.6), "#e8f2ff", 1.4, 4.0, true, 0.3)
	# The note.
	_note = Node3D.new()
	root.add_child(_note)
	var qm := QuadMesh.new()
	qm.size = Vector2(0.166, 0.066)
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	mi.material_override = Kit.shader(NOTE)
	_note.add_child(mi)
	Kit.text(_note, "2000", 0.016, Color("5a0e3e"), Vector3(0.058, 0.02, 0.001), Vector3.ZERO, true)
	# The market outside: shopfronts, fairy lights, a queue, a vegetable cart.
	var r := Kit.rng("market")
	for i in 8:
		var x := -14.0 + 3.6 * i
		if absf(x) < 2.0:
			continue
		Kit.box(root, Vector3(3.4, 4, 0.2), Vector3(x, 2, -2.0), Kit.mat(Color(r.randf_range(0.4, 0.7), r.randf_range(0.35, 0.55), r.randf_range(0.3, 0.5)), 0.85))
		Kit.box(root, Vector3(3.0, 2.4, 0.1), Vector3(x, 1.2, -1.9), Kit.lit(Color(1.0, 0.82, 0.55), 0.6))
	for i in 60:
		var x := -12.0 + 0.4 * i
		var y := 3.4 + 0.18 * sin(float(i) * 0.6)
		var b := Kit.ball(root, 0.035, Vector3(x, y, 0.4), Kit.lit(["#ffcf5a", "#ff6a5a", "#7ad6ff", "#9dff7a"][i % 4], 4.0), 6)
		_bulbs.append(b)
	var cart := Node3D.new()
	cart.position = Vector3(5.0, 0, 2.5)
	cart.rotation = Vector3(0, -0.4, 0)
	root.add_child(cart)
	Kit.box(cart, Vector3(1.8, 0.1, 1.0), Vector3(0, 0.9, 0), Kit.mat("#6a4a2a", 0.7))
	for k in 24:
		Kit.ball(cart, 0.08, Vector3(r.randf_range(-0.8, 0.8), 1.0, r.randf_range(-0.4, 0.4)), Kit.mat(["#c02a1a", "#e8a22a", "#3a8a2a", "#6a2a6a"][k % 4], 0.6), 8)
	for s in [-1.0, 1.0]:
		Kit.cyl(cart, 0.35, 0.35, 0.06, Vector3(s * 0.95, 0.35, 0), Kit.mat("#2a2a2a", 0.7), 16, Vector3(0, 0, PI / 2))
	Kit.omni(root, Vector3(5.0, 2.0, 2.5), "#ffc070", 1.0, 5.0, false, 0.4)
	return root


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var nt = _p.get("note", {})
	var out := float(nt.get("out", 1e9)) if nt is Dictionary else 1e9
	var flip := float(nt.get("flip", out + 1.2)) if nt is Dictionary else 1e9
	var slot := Vector3(0.1, 1.05, -1.06)
	var u := Motion.out_cubic(clampf((t - out) / 0.6, 0.0, 1.0))
	var lift := Motion.in_out(clampf((t - flip) / 0.5, 0.0, 1.0))
	_note.position = slot + Vector3(0, 0.0, 0.09 * u) + Vector3(0, 0.12, 0.25) * lift
	_note.rotation = Vector3(-PI / 2 * (1.0 - lift), PI * lift, 0)
	_note.visible = t > out - 0.05
	for i in _bulbs.size():
		(_bulbs[i] as Node3D).visible = fposmod(t * 2.0 + float(i % 3) * 0.33, 1.0) < 0.75
	return {"slot": gt * slot, "note": gt * _note.position, "kiosk": gt * Vector3(0, 1.5, 0)}
