extends RefCounted
## MOM, the Mars Orbiter spacecraft, shared by the space and clean-room gags. Build it with
## mom_model.new().build(k) (the gags compile this file at runtime: see _mom_script() in space.gd).
## Parts are named: bus, hga (with led), wing (panel_0..2), engine (flame, flame_light, bell_glow).

const Kit = preload("res://scripts/world/gag_kit.gd")

## Multi-layer insulation: crinkled gold foil (the spacecraft's blanket).
const FOIL_SHADER := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec3 tint : source_color = vec3(0.86, 0.62, 0.22);
uniform float crinkle = 34.0;
varying vec3 lp;
//NOISE
void vertex() { lp = VERTEX; }
void fragment() {
	float n = fbm(lp * crinkle);
	float m = fbm(lp * crinkle * 0.31 + 9.0);
	vec3 g = vec3(fbm(lp * crinkle + vec3(1.7, 0.0, 0.0)) - n, fbm(lp * crinkle + vec3(0.0, 1.7, 0.0)) - n, 0.0);
	NORMAL_MAP = normalize(vec3(g.xy * 3.5, 1.0)) * 0.5 + 0.5;
	ALBEDO = tint * (0.78 + 0.35 * m);
	METALLIC = 0.0;
	ROUGHNESS = 0.18 + 0.2 * n;
	SPECULAR = 0.95;
}
"""

## Solar cells: dark blue with a silver grid.
const CELL_SHADER := """
shader_type spatial;
uniform vec2 cells = vec2(14.0, 10.0);
varying vec2 uv2;
void vertex() { uv2 = UV; }
void fragment() {
	vec2 g = fract(uv2 * cells);
	float line = 1.0 - step(0.06, g.x) * step(0.06, g.y) * step(g.x, 0.94) * step(g.y, 0.94);
	vec3 c = mix(vec3(0.03, 0.06, 0.16), vec3(0.62, 0.65, 0.7), line * 0.8);
	float frame = 1.0 - step(0.01, uv2.x) * step(0.01, uv2.y) * step(uv2.x, 0.99) * step(uv2.y, 0.99);
	ALBEDO = mix(c, vec3(0.75), frame);
	ROUGHNESS = mix(0.22, 0.5, line);
	SPECULAR = 0.9;
}
"""

## Engine plume: additive, hot white core to orange edge, flickering; `power` 0..1.
const FLAME_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform float power = 0.0;
uniform float flick = 0.0;
uniform vec3 core : source_color = vec3(1.0, 0.92, 0.75);
uniform vec3 edge : source_color = vec3(1.0, 0.42, 0.12);
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	float along = clamp(-lp.y, 0.0, 1.0);
	float r = length(lp.xz) / max(0.02, 0.5 * (0.35 + along));
	float body = (1.0 - smoothstep(0.0, 1.0, r)) * (1.0 - along) * (1.0 - along);
	float fl = 0.85 + 0.15 * sin(flick * 37.0 + along * 18.0) * sin(flick * 23.0 - along * 9.0);
	vec3 c = mix(edge, core, smoothstep(0.35, 0.0, r) * (1.0 - along));
	ALBEDO = c * body * power * fl * 1.6;
}
"""

## MOM: a 1.5 m bus in gold MLI, one three-panel solar wing on +X, the 2.2 m high-gain dish on +Y,
## the 440 N engine on -Y, payload boxes and thrusters. Scale `k` (hero props read better a bit big).
func build(k: float = 1.0) -> Node3D:
	var n := Node3D.new()
	var foil := Kit.shader(FOIL_SHADER)
	var silver := Kit.mat("#c9ccd2", 0.25, 0.0, 0.9)
	var white := Kit.mat("#666c74", 0.3, 0.0, 0.8)   # optical solar reflector tiles (radiators)
	var black := Kit.mat("#1b1c20", 0.6)
	var bus := Kit.slab(n, Vector3(1.5, 1.4, 1.5) * k, 0.06 * k, Vector3.ZERO, foil)
	bus.name = "bus"
	# Radiator panels (white) on two faces and a silver deck on top.
	Kit.box(n, Vector3(0.02, 1.1, 1.1) * k, Vector3(-0.76, 0, 0) * k, white)
	Kit.box(n, Vector3(1.1, 1.0, 0.02) * k, Vector3(0, 0, -0.76) * k, white)
	Kit.box(n, Vector3(1.52, 0.04, 1.52) * k, Vector3(0, 0.72, 0) * k, silver)
	Kit.box(n, Vector3(1.52, 0.04, 1.52) * k, Vector3(0, -0.72, 0) * k, silver)
	# Payloads on the +Z face (the Mars Colour Camera and its friends) and star sensors.
	Kit.box(n, Vector3(0.32, 0.28, 0.22) * k, Vector3(-0.35, -0.3, 0.84) * k, black)
	Kit.cyl(n, 0.07 * k, 0.07 * k, 0.12 * k, Vector3(-0.35, -0.3, 1.0) * k, black, 16, Vector3(PI / 2, 0, 0))
	Kit.box(n, Vector3(0.26, 0.2, 0.18) * k, Vector3(0.3, -0.35, 0.82) * k, white)
	Kit.box(n, Vector3(0.2, 0.18, 0.16) * k, Vector3(0.35, 0.25, 0.82) * k, foil)
	Kit.cyl(n, 0.06 * k, 0.05 * k, 0.16 * k, Vector3(-0.5, 0.55, 0.6) * k, black, 12, Vector3(0.4, 0, 0.3))
	# High-gain antenna: a 2.2 m white dish on a short mast, its feed on struts.
	var hga := Node3D.new()
	hga.name = "hga"
	hga.position = Vector3(0, 0.95, 0) * k
	n.add_child(hga)
	Kit.cyl(hga, 0.08 * k, 0.1 * k, 0.4 * k, Vector3(0, -0.12, 0) * k, silver, 12)
	var dish := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.1 * k
	sm.height = 0.5 * k
	sm.is_hemisphere = true
	sm.radial_segments = 48
	sm.rings = 12
	dish.mesh = sm
	dish.material_override = Kit.mat("#bdb8ae", 0.7, 0.0, 0.35)
	dish.rotation = Vector3(PI, 0, 0)
	dish.position = Vector3(0, 0.38, 0) * k
	hga.add_child(dish)
	Kit.cyl(hga, 1.1 * k, 1.1 * k, 0.03 * k, Vector3(0, 0.38, 0) * k, Kit.mat("#a9a59c", 0.6), 48)
	for i in 3:
		var a := TAU * float(i) / 3.0
		Kit.rod(hga, Vector3(cos(a) * 0.95, 0.4, sin(a) * 0.95) * k, Vector3(0, 0.95, 0) * k, 0.015 * k, silver, 6)
	Kit.cyl(hga, 0.06 * k, 0.09 * k, 0.16 * k, Vector3(0, 0.98, 0) * k, white, 12)
	var led := Kit.ball(hga, 0.05 * k, Vector3(0, 1.07, 0) * k, Kit.lit("#ffe9b0", 0.0), 10)
	led.name = "led"
	# Solar wing: a yoke and three panels in a row along +X.
	var wing := Node3D.new()
	wing.name = "wing"
	wing.position = Vector3(0.76, 0, 0) * k
	n.add_child(wing)
	Kit.rod(wing, Vector3.ZERO, Vector3(0.7, 0, 0) * k, 0.03 * k, silver, 8)
	var cells := Kit.shader(CELL_SHADER)
	for i in 3:
		var pnl := Kit.quad(wing, Vector2(1.8, 1.4) * k, Vector3(0.7 + 0.95 + 1.84 * i, 0, 0) * k, cells, Vector3(-PI / 2, 0, 0))
		pnl.name = "panel_%d" % i
		var back := Kit.quad(wing, Vector2(1.8, 1.4) * k, Vector3(0.7 + 0.95 + 1.84 * i, -0.01, 0) * k, Kit.mat("#3a3d44", 0.7), Vector3(PI / 2, 0, 0))
		back.name = "pback_%d" % i
		Kit.box(wing, Vector3(1.82, 0.03, 0.03) * k, Vector3(0.7 + 0.95 + 1.84 * i, 0, 0.71) * k, silver)
		Kit.box(wing, Vector3(1.82, 0.03, 0.03) * k, Vector3(0.7 + 0.95 + 1.84 * i, 0, -0.71) * k, silver)
	# Engine: the 440 N liquid apogee motor on -Y with a short dark bell; thruster nubs on the corners.
	var eng := Node3D.new()
	eng.name = "engine"
	eng.position = Vector3(0, -0.74, 0) * k
	n.add_child(eng)
	Kit.cyl(eng, 0.1 * k, 0.12 * k, 0.12 * k, Vector3(0, -0.05, 0) * k, silver, 16)
	Kit.cyl(eng, 0.08 * k, 0.2 * k, 0.32 * k, Vector3(0, -0.26, 0) * k, Kit.mat("#2a2622", 0.45, 0.0, 0.8), 24)
	var bell_glow := Kit.cyl(eng, 0.075 * k, 0.19 * k, 0.3 * k, Vector3(0, -0.27, 0) * k, Kit.lit("#ff6a1c", 0.0), 24)
	bell_glow.name = "bell_glow"
	bell_glow.scale = Vector3(1.02, 1.0, 1.02)
	for x in [-0.68, 0.68]:
		for z in [-0.68, 0.68]:
			Kit.cyl(n, 0.025 * k, 0.04 * k, 0.07 * k, Vector3(x, -0.74, z) * k, black, 8)
	var flame := MeshInstance3D.new()
	flame.name = "flame"
	var fm := CylinderMesh.new()
	fm.top_radius = 0.25
	fm.bottom_radius = 0.55
	fm.height = 1.0
	fm.radial_segments = 24
	fm.rings = 8
	flame.mesh = fm
	var fmat := Kit.shader(FLAME_SHADER)
	flame.material_override = fmat
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flame.position = Vector3(0, -0.45, 0) * k
	eng.add_child(flame)
	var fl := Kit.omni(eng, Vector3(0, -1.2, 0) * k, "#ffae5c", 0.0, 9.0 * k, false)
	fl.name = "flame_light"
	return n


