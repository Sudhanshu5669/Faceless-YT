## Smoke, fire and spray for the Bombay Gold gags: camera-facing billboard puffs in one MultiMesh per layer, each
## puff a pure function of time (born on a schedule, rising, drifting, growing, fading), sorted back to front for
## the camera every frame so the alpha blends correctly.
##
## Load it at runtime (episode scripts live outside res://):
##   var FX = load(Paths.repo_path("episodes/bombay_gold/gags/fx.gd"))
##   var smoke = FX.layer(root, 600, "smoke")          # or "fire", "spray"
##   FX.begin(smoke)                                   # every frame
##   FX.plume(smoke, origin, t, {...})                 # adds puffs
##   FX.finish(smoke, camera_pos_local)                # writes them, sorted
extends RefCounted

const Kit = preload("res://scripts/world/gag_kit.gd")

const BILLBOARD := """
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
"""

## Smoke: lit from above (sun side), dark underneath, glowing orange from below where custom.g (heat) > 0.
## custom: r = seed, g = fire glow, b = darkness (0 grey .. 1 black), a = opacity.
const SMOKE := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec3 lit_col : source_color = vec3(0.62, 0.58, 0.52);
uniform vec3 shade_col : source_color = vec3(0.2, 0.18, 0.16);
uniform vec3 black_col : source_color = vec3(0.05, 0.045, 0.04);
uniform vec3 glow_col : source_color = vec3(1.0, 0.42, 0.12);
uniform vec3 fog_col : source_color = vec3(0.8, 0.76, 0.68);
uniform float fog_far = 3000.0;
uniform float t = 0.0;
varying vec4 cd;
varying float depth;
//NOISE
void vertex() {
	cd = INSTANCE_CUSTOM;
	float a = cd.r * 6.2831;
	VERTEX.xy = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * VERTEX.xy;
//BILLBOARD
	depth = -(MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z;
}
void fragment() {
	vec2 c = UV - 0.5;
	float r = length(c) * 2.0;
	float n = fbm(vec3(c * 2.6 + cd.r * 31.0, cd.r * 7.0 + t * 0.07));
	float n2 = fbm(vec3(c * 6.0 - cd.r * 13.0, t * 0.11));
	float dens = smoothstep(1.0, 0.15, r + (n - 0.5) * 1.1 + (n2 - 0.5) * 0.35);
	// Up in world space is roughly up on screen for these cameras: lit on top, shaded below.
	float up = clamp(0.55 - c.y * 1.1 + (n - 0.5) * 0.7, 0.0, 1.0);
	vec3 col = mix(shade_col, lit_col, up);
	col = mix(col, black_col, cd.b);
	col += glow_col * cd.g * clamp(0.3 + c.y * 1.4 + (n2 - 0.5), 0.0, 1.2);
	col = mix(col, fog_col, clamp(depth / fog_far, 0.0, 0.85));
	ALBEDO = col;
	ALPHA = clamp(dens * cd.a, 0.0, 1.0);
}
"""

## Fire: additive, white-yellow core to red edges, licking upward. custom: r seed, g heat, a opacity.
const FIRE := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform float t = 0.0;
varying vec4 cd;
//NOISE
void vertex() {
	cd = INSTANCE_CUSTOM;
//BILLBOARD
}
void fragment() {
	vec2 c = UV - 0.5;
	float n = fbm(vec3(c.x * 3.0 + cd.r * 19.0, c.y * 2.0 + t * 2.2 + cd.r * 5.0, t * 0.6));
	float shape = smoothstep(0.95, 0.1, length(vec2(c.x * 2.1, (c.y + 0.12) * 1.7)) + (n - 0.5) * 0.9 - (0.5 + c.y) * 0.25);
	float heat = clamp(cd.g * (0.55 + 0.9 * n) * shape * 1.3, 0.0, 1.5);
	vec3 col = mix(vec3(0.6, 0.08, 0.01), vec3(1.0, 0.55, 0.12), clamp(heat * 1.4, 0.0, 1.0));
	col = mix(col, vec3(1.0, 0.92, 0.7), clamp(heat - 0.7, 0.0, 1.0));
	ALBEDO = col * shape * cd.a * (0.6 + heat * 1.6);
}
"""

## Spray (fire-hose water, splashes): soft white, semi-transparent. custom: r seed, a opacity.
const SPRAY := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec3 col : source_color = vec3(0.92, 0.94, 0.95);
uniform float t = 0.0;
varying vec4 cd;
//NOISE
void vertex() {
	cd = INSTANCE_CUSTOM;
//BILLBOARD
}
void fragment() {
	vec2 c = UV - 0.5;
	float n = fbm(vec3(c * 4.0 + cd.r * 11.0, t * 0.5));
	float dens = smoothstep(1.0, 0.2, length(c) * 2.0 + (n - 0.5) * 0.8);
	ALBEDO = col * (0.85 + 0.3 * n);
	ALPHA = dens * cd.a;
}
"""


## Raw cotton bales: jute weave (fine threads + blotchy fbm), three dark iron bands, a soft bulge in the shading.
const BALE := """
shader_type spatial;
render_mode diffuse_burley;
uniform vec3 base : source_color = vec3(0.78, 0.7, 0.54);
varying vec3 lp;
//NOISE
void vertex() { lp = VERTEX; }
void fragment() {
	vec3 a = abs(lp);
	float weave = 0.5 + 0.5 * sin(lp.x * 260.0) * sin((lp.y + lp.z) * 260.0);
	float blot = fbm(lp * 3.0 + COLOR.r * 9.0);
	vec3 col = base * (0.78 + 0.22 * weave) * (0.82 + 0.36 * blot) * mix(vec3(1.0), COLOR.rgb, 0.6);
	float band = 0.0;
	for (int i = -1; i <= 1; i++) { band = max(band, 1.0 - smoothstep(0.018, 0.03, abs(lp.x - float(i) * 0.4))); }
	col = mix(col, vec3(0.16, 0.15, 0.14), band);
	ALBEDO = col;
	ROUGHNESS = mix(0.95, 0.45, band);
	METALLIC = band * 0.6;
}
"""


static func bale_material() -> ShaderMaterial:
	return Kit.shader(BALE)


class Layer:
	var mm: MultiMesh
	var mi: MultiMeshInstance3D
	var mat: ShaderMaterial
	var items: Array = []      # [pos, size, Color(custom)]


static func layer(parent: Node3D, count: int, kind: String) -> Layer:
	var code: String = {"smoke": SMOKE, "fire": FIRE, "spray": SPRAY}[kind]
	code = code.replace("//BILLBOARD
", BILLBOARD)
	var L := Layer.new()
	L.mat = Kit.shader(code)
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	L.mm = MultiMesh.new()
	L.mm.transform_format = MultiMesh.TRANSFORM_3D
	L.mm.use_custom_data = true
	L.mm.mesh = q
	L.mm.instance_count = count
	L.mm.visible_instance_count = 0
	L.mi = MultiMeshInstance3D.new()
	L.mi.multimesh = L.mm
	L.mi.material_override = L.mat
	L.mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	L.mi.extra_cull_margin = 4000.0
	parent.add_child(L.mi)
	return L


static func begin(L: Layer) -> void:
	L.items.clear()


static func add(L: Layer, pos: Vector3, size: float, custom: Color) -> void:
	if custom.a > 0.003 and size > 0.001:
		L.items.append([pos, size, custom])


## Writes this frame's puffs, farthest from `cam_local` first (in the layer's parent space).
static func finish(L: Layer, cam_local: Vector3, t: float) -> void:
	var n := mini(L.items.size(), L.mm.instance_count)
	if L.items.size() > 1:
		L.items.sort_custom(func(a, b): return a[0].distance_squared_to(cam_local) > b[0].distance_squared_to(cam_local))
	for i in n:
		var it: Array = L.items[i]
		L.mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * float(it[1])), it[0]))
		L.mm.set_instance_custom_data(i, it[2])
	L.mm.visible_instance_count = n
	L.mat.set_shader_parameter("t", t)


static func _h(i: int, salt: int) -> float:
	var x := sin(float(i) * 12.9898 + float(salt) * 78.233) * 43758.5453
	return x - floor(x)


## A rising plume from `origin`: puffs born every `every` seconds from t0 (until t1), each living `life` s.
## o: rate (puffs/s), life, rise (m/s), spread (m at the source), grow (m/s of size), size0, wind (Vector3 m/s),
##    alpha, dark (0..1), glow (fire light at the base, 0..1, fading with age), t0, t1, seed, jitter (m), slow (rise
##    slows with age: 0..1)
static func plume(L: Layer, origin: Vector3, t: float, o: Dictionary) -> void:
	var t0 := float(o.get("t0", 0.0))
	if t < t0:
		return
	var t1 := float(o.get("t1", 1e9))
	var rate := float(o.get("rate", 4.0))
	var life := float(o.get("life", 8.0))
	var rise := float(o.get("rise", 3.0))
	var spread := float(o.get("spread", 1.0))
	var grow := float(o.get("grow", 1.0))
	var size0 := float(o.get("size0", 2.0))
	var wind: Vector3 = o.get("wind", Vector3(1.0, 0, 0))
	var alpha := float(o.get("alpha", 0.8))
	var dark := float(o.get("dark", 0.3))
	var glow := float(o.get("glow", 0.0))
	var seed := int(o.get("seed", 1))
	var slow := float(o.get("slow", 0.35))
	var ramp := float(o.get("ramp", 0.0))     # seconds for the plume to reach full strength
	var every := 1.0 / rate
	var k_last := int(floor((minf(t, t1) - t0) / every))
	var k_first := maxi(0, int(floor((t - life - t0) / every)))
	for k in range(k_first, k_last + 1):
		var born := t0 + k * every
		var age := t - born
		if age < 0.0 or age > life:
			continue
		var u := age / life
		var strength := 1.0 if ramp <= 0.0 else clampf((born - t0) / ramp, 0.08, 1.0)
		var ang := _h(k, seed) * TAU
		var rad := sqrt(_h(k, seed + 1)) * spread
		var p := origin + Vector3(cos(ang) * rad, 0, sin(ang) * rad)
		var h := rise * age * (1.0 - slow * u)
		p += Vector3(0, h, 0) + wind * age * (0.4 + 0.6 * u)
		p += Vector3(sin(age * 0.7 + k) * 0.6, 0, cos(age * 0.5 + k * 1.3) * 0.6) * (0.5 + u * 2.0)
		var sz := (size0 + grow * age) * (0.75 + 0.5 * _h(k, seed + 2)) * (0.55 + 0.45 * strength)
		var fade_in := clampf(age / 0.6, 0.0, 1.0)
		var a := alpha * fade_in * (1.0 - u) * (1.0 - u * 0.3) * (0.5 + 0.5 * strength)
		var gl := glow * clampf(1.0 - u * 2.5, 0.0, 1.0)
		add(L, p, sz, Color(_h(k, seed + 3), gl, dark, a))


## Flames: a cluster of flickering fire sprites over a patch (centre, half-extents ext in x/z), from t0.
## o: count, height, size, heat, t0, t1, ramp, seed
static func flames(L: Layer, centre: Vector3, ext: Vector2, t: float, o: Dictionary) -> void:
	var t0 := float(o.get("t0", 0.0))
	if t < t0 or t > float(o.get("t1", 1e9)):
		return
	var ramp := clampf((t - t0) / maxf(float(o.get("ramp", 1.0)), 0.001), 0.0, 1.0)
	var count := int(o.get("count", 10))
	var height := float(o.get("height", 3.0))
	var size := float(o.get("size", 3.0))
	var heat := float(o.get("heat", 1.0))
	var seed := int(o.get("seed", 7))
	for i in count:
		var px := (_h(i, seed) * 2.0 - 1.0) * ext.x
		var pz := (_h(i, seed + 1) * 2.0 - 1.0) * ext.y
		var cyc := 0.7 + _h(i, seed + 2) * 0.8
		var ph := fmod(t / cyc + _h(i, seed + 3), 1.0)
		var y := ph * height * (0.6 + 0.4 * _h(i, seed + 4))
		var sz := size * (0.6 + 0.6 * _h(i, seed + 5)) * (1.0 - ph * 0.55) * (0.3 + 0.7 * ramp)
		var a := sin(ph * PI) * ramp
		add(L, centre + Vector3(px, y + sz * 0.35, pz), sz, Color(_h(i, seed + 6), heat * (0.7 + 0.5 * (1.0 - ph)), 0, a))


## A water jet along a ballistic arc from `from` with velocity `vel` (m/s), gravity g; drops spaced in time.
## o: rate (drops/s), life (s), size0, grow, alpha, t0, t1, seed, scatter (m/s)
static func jet(L: Layer, from: Vector3, vel: Vector3, t: float, o: Dictionary) -> void:
	var t0 := float(o.get("t0", 0.0))
	if t < t0:
		return
	var t1 := float(o.get("t1", 1e9))
	var rate := float(o.get("rate", 40.0))
	var life := float(o.get("life", 2.5))
	var size0 := float(o.get("size0", 0.3))
	var grow := float(o.get("grow", 1.2))
	var alpha := float(o.get("alpha", 0.5))
	var seed := int(o.get("seed", 3))
	var scatter := float(o.get("scatter", 0.8))
	var floor_y := float(o.get("floor", -1e9))
	var every := 1.0 / rate
	var k_last := int(floor((minf(t, t1) - t0) / every))
	var k_first := maxi(0, int(floor((t - life - t0) / every)))
	for k in range(k_first, k_last + 1):
		var age := t - (t0 + k * every)
		if age < 0.0 or age > life:
			continue
		var v := vel + Vector3(_h(k, seed) - 0.5, _h(k, seed + 1) - 0.5, _h(k, seed + 2) - 0.5) * scatter * 2.0
		var p := from + v * age + Vector3(0, -4.9 * age * age, 0)
		if p.y < floor_y:
			continue
		var u := age / life
		add(L, p, size0 + grow * age, Color(_h(k, seed + 3), 0, 0, alpha * (1.0 - u) * clampf(age / 0.08, 0.0, 1.0)))
