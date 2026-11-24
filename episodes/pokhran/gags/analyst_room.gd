extends RefCounted
## A US imagery analyst's office near Washington, the night of 10-11 May 1998 (EDT): 15:45 IST is 06:15
## in Washington, the end of a night shift. A stand-in for "America's spies" (no real person).
##
## Local frame: the floor centre is the origin; the analyst's desk stands against the front wall (z -2.2),
## its top at y 0.62; the analyst sits at (0, 0, -0.6) facing -z, at the hero CRT (screen centre
## SCREEN). The wall TV hangs on the back wall (z +2.2) on a bracket, facing -z. The window with venetian
## blinds is in the -x wall (frame right when the camera looks +z from the desk): sodium street light
## leaks through the slats in hard stripes (real shadows of real slats).
##
## params:
##   wh      {"blast", "rewind", "switch"}  the hook: the feed shows America's White House, which blows up at
##           `blast`; from `rewind` the tape runs backwards; at `switch` the feed glitches over to Pokhran
##   blast   [t, ...]  the ground on the Pokhran feed lifts and throws a dust ring (11 May tests)
##   rewind  {"from", "until", "to": "DEC 1995"}  the feed rewinds like a VHS tape: the picture runs backwards faster
##           and faster with day-night flicker and tracking bars; the stamp's date rolls back day by day from
##           11 May 1998 and lands on "to" (month and year only: the exact day of the 1995 imagery isn't public)
##   tv      {"on": t, "cam": point, "look": point, "fov": deg, "feeds": [[t, cam, look, fov, {"bg": "#rrggbb",
##           "ambient": e}], ...]}  the wall TV flicks on and shows the live view of a SubViewport camera placed in the
##           world (the PM's lawn), from `on`; from each feed's t the TV cuts to that camera (another place: the blast
##           footage), with its own background colour and ambient light (the room's look has no sun)
##   knock   t   the analyst's elbow knocks the snow globe; the snow swirls
##   spill   t   the analyst jolts awake and knocks his coffee over: the mug tips and rolls a little, a pool spreads
##   loop    {"from": t, "end": t}   the Short's loop: from `from` the feed glitches back to America's White House, intact,
##           its feed clock running so that at `end` it is exactly where the hook starts (feed time 0)
##   report  {"hand": actor id, "drop": t, "at": [x, z]}   a thick bound report (navy covers, a red SECRET stamp)
##           held in the actor's right hand, slammed down flat onto the desk at (x, z) at `drop`: a hard landing, a
##           bounce, the mug and the globe jump, the snow swirls
##   stamp   "11 MAY 1998"  the date on the feed (default)
##   live    {"from": t, "until": t, "cam": point, "ortho": 26, "stamp": "MAY 1998"}   the hero CRT shows a live overhead view straight down
##           from `cam` (the place's own actors as specks), with the same sensor look
##   prints  {"cam": point, "ortho": 34, "slide": t, "hand": actor id, "shrug": t}   two satellite prints of the same
##           place (a live overhead view of `cam`, looking straight down) on the desk: the hand slides the second one in
##           beside the first, landing at `slide`; at `shrug` the actor shrugs, both hands out, shoulders up
## anchors: screen, tv, globe, mug, desk, chair, window, prints

const Kit = preload("res://scripts/world/gag_kit.gd")
const Motion = preload("res://scripts/timeline/motion.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")

const ROOM := Vector3(5.2, 2.65, 4.4)
const DESK_TOP := 0.62
const SCREEN := Vector3(0.0, 1.02, -1.86)      # hero CRT screen centre (faces +z)
const SCREEN_SIZE := Vector2(0.44, 0.33)
const TV_AT := Vector3(-0.55, 1.95, 2.0)       # wall TV screen centre (faces -z)
const TV_SIZE := Vector2(0.78, 0.585)
const GLOBE_AT := Vector3(0.52, DESK_TOP, -1.42)
const MUG_AT := Vector3(-0.42, DESK_TOP, -1.38)
const PH := "incoming/polyhaven_pokhran/models/"
const CHAIR_AT := Vector3(0.25, 0.0, -0.45)

## The satellite feed: a greyscale top-down view of the Pokhran range drifting under the crosshair, on a
## curved CRT with scanlines, RGB fringing and phosphor glow. blast: the ground lifts, a dust ring rolls out.
const FEED := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float t = 0.0;           // feed time (runs backwards while the tape rewinds)
uniform float tr = 0.0;          // real time (grain, tracking bars)
uniform float blast = 1000000.0;
uniform float rewind = 0.0;      // 0..1 strength of the tape-rewind look
uniform float scene = 1.0;       // 0 = the White House, Washington; 1 = the Pokhran range
uniform float glitch = 0.0;      // 0..1 the feed switching source
uniform float energy = 0.62;
uniform float power = 1.0;       // 0 = off
uniform sampler2D aerial : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D live : source_color, filter_linear;
uniform float live_mix = 0.0;    // 1 = the live overhead view (a SubViewport) instead of the drawn terrain
varying vec2 uv2;
//NOISE
void vertex() { uv2 = UV; }


float sdr(vec2 p, vec2 c, vec2 h) { vec2 d = abs(p - c) - h; return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); }
float fill(float sd) { return 1.0 - smoothstep(-0.2, 0.25, sd); }

float wh_build(vec2 m) {
	// The buildings' footprint, metres (north up): the residence, porticoes, colonnades, East and West Wings.
	float b = fill(sdr(m, vec2(0.0, 0.0), vec2(26.0, 11.5)));
	b = max(b, fill(length(m - vec2(0.0, 11.5)) - 8.5) * step(11.0, m.y));
	b = max(b, fill(sdr(m, vec2(0.0, -14.5), vec2(9.0, 3.5))));
	b = max(b, fill(sdr(m, vec2(-40.0, 1.0), vec2(14.0, 3.0))));
	b = max(b, fill(sdr(m, vec2(39.0, 0.0), vec2(13.0, 3.0))));
	b = max(b, fill(sdr(m, vec2(-68.0, 2.0), vec2(13.0, 14.0))));
	b = max(b, fill(sdr(m, vec2(66.0, 0.0), vec2(12.0, 10.0))));
	return b;
}

float whitehouse(vec2 w) {
	// America's White House from orbit, greyscale, at real proportions (metres, north up): the residence with the
	// round South Portico, the north drive's arc and fountain, the South Lawn opening to the south with its
	// fountain, the colonnades and wings, dense tree crowns round the grounds, shadows from a low morning sun.
	vec2 m = w * 420.0;
	vec3 ph = texture(aerial, m * 0.006 + vec2(0.7, 0.2)).rgb;
	float grain = dot(ph, vec3(0.33)) - 0.45;
	float g = 0.4 + 0.08 * (fbm(vec3(m * 0.03, 2.0)) - 0.5) + 0.06 * grain;
	g += 0.018 * sin((m.x + 0.3 * m.y) * 0.5) * step(14.0, m.y);
	// The north drive (an arc) and the south drive (a wide oval, mostly beyond the frame).
	float nd = abs(length((m - vec2(0.0, -14.0)) * vec2(1.0, 1.1)) - 46.0);
	g = mix(g, 0.72 + 0.03 * grain, (1.0 - smoothstep(1.8, 2.6, nd)) * step(m.y, -14.0));
	float sd = abs(length((m - vec2(0.0, 98.0)) * vec2(0.74, 1.0)) - 78.0);
	g = mix(g, 0.72 + 0.03 * grain, (1.0 - smoothstep(1.6, 2.4, sd)) * step(10.0, m.y));
	for (int i = 0; i < 2; i++) {
		vec2 c = i == 0 ? vec2(0.0, -44.0) : vec2(0.0, 62.0);
		float rr = i == 0 ? 4.0 : 5.5;
		float r = length(m - c);
		g = mix(g, 0.2, 1.0 - smoothstep(rr, rr + 0.4, r));
		g = mix(g, 0.84, 1.0 - smoothstep(0.3, 0.8, abs(r - rr - 0.6)));
	}
	// Tree crowns: clumps round the grounds (thick east and west, a screen along the south), each with a
	// lit top, a dark core and a cast shadow; never on the drives, lawns' centre or the buildings.
	float lawn = (1.0 - smoothstep(30.0, 44.0, abs(m.x))) * step(-60.0, m.y);
	float dens = clamp(smoothstep(34.0, 56.0, abs(m.x)) + smoothstep(48.0, 64.0, m.y) * smoothstep(12.0, 30.0, abs(m.x)), 0.0, 1.0) * (1.0 - lawn * 0.6);
	float crown = smoothstep(0.5, 0.62, fbm(vec3(m * 0.11, 5.0)) + 0.25 * dens) * dens;
	float crs = smoothstep(0.5, 0.62, fbm(vec3((m + vec2(-3.0, 1.0)) * 0.11, 5.0)) + 0.25 * dens) * dens;
	float leaf = n3(vec3(m * 1.4, 6.0)) * 0.5 + n3(vec3(m * 3.1, 7.0)) * 0.5;
	g = mix(g, g * 0.5, crs * (1.0 - crown) * 0.8);
	g = mix(g, 0.18 + 0.2 * leaf + 0.1 * smoothstep(0.55, 0.75, fbm(vec3(m * 0.11 + 0.6, 5.0))), crown);
	// Building shadows (morning sun from the east), then the roofs.
	float sh = wh_build(m + vec2(3.5, 1.0));
	float b = wh_build(m);
	g *= 1.0 - 0.5 * sh * (1.0 - b);
	float roof = 0.84 + 0.05 * grain;
	float wings = max(fill(sdr(m, vec2(-68.0, 2.0), vec2(13.0, 14.0))), fill(sdr(m, vec2(66.0, 0.0), vec2(12.0, 10.0))));
	roof = mix(roof, 0.6 + 0.05 * grain, wings);
	float inner = fill(sdr(m, vec2(0.0, 0.0), vec2(24.0, 9.8)));
	roof -= 0.1 * inner;
	roof += 0.06 * fill(sdr(m, vec2(0.0, 0.0), vec2(16.0, 4.0)));
	roof -= 0.3 * step(0.93, n3(vec3(floor(m * 0.6), 4.0))) * inner;
	g = mix(g, roof, b);
	return g;
}

float terrain(vec2 p) {
	// A real aerial photograph of stony ground (Poly Haven, CC0), greyed, as the desert floor seen from orbit,
	// with broad tone variation and scrub bushes (dark dots with shadows) on top.
	vec3 ph = texture(aerial, p * 4.5 + vec2(0.31, 0.17)).rgb;
	float g = dot(ph, vec3(0.3, 0.55, 0.15));
	g = 0.2 + 0.95 * g;
	g += 0.16 * (fbm(vec3(p * 2.0, 1.0)) - 0.5);
	float bush = smoothstep(0.88, 0.96, n3(vec3(p * 130.0, 7.0)));
	float bsh = smoothstep(0.88, 0.96, n3(vec3((p + vec2(0.0015, -0.0015)) * 130.0, 7.0)));
	g -= 0.2 * bush + 0.1 * bsh * (1.0 - bush);
	// A dirt track sweeping through, two wheel ruts.
	float d = abs(p.y - 0.12 * sin(p.x * 2.2) - 0.18 + 0.05 * p.x);
	g += 0.07 * (1.0 - smoothstep(0.004, 0.012, d));
	g -= 0.08 * (1.0 - smoothstep(0.0, 0.002, abs(d - 0.006)));
	// The site at the origin: a scraped pad, a square steel plate, a spoil heap, tents and trucks.
	vec2 q = p;
	float pad = 1.0 - smoothstep(0.035, 0.05, length(q * vec2(1.0, 1.3)));
	g = mix(g, 0.6, pad * 0.35);
	float plate = step(abs(q.x), 0.004) * step(abs(q.y), 0.004);
	g = mix(g, 0.18, plate);
	float heap = 1.0 - smoothstep(0.0, 0.018, length((q - vec2(0.03, -0.012)) * vec2(1.0, 1.8)));
	g += 0.12 * heap;
	g -= 0.25 * (1.0 - smoothstep(0.0, 0.012, length((q - vec2(0.038, -0.022)) * vec2(1.4, 3.0)))) * (1.0 - heap);
	for (int i = 0; i < 5; i++) {
		vec2 c = vec2(-0.09 + 0.022 * float(i), 0.055 + 0.004 * float(i % 2));
		float tent = step(abs(q.x - c.x), 0.007) * step(abs(q.y - c.y), 0.005);
		g = mix(g, 0.86, tent);
		g -= 0.3 * step(abs(q.x - c.x - 0.004), 0.007) * step(abs(q.y - c.y + 0.006), 0.002) * (1.0 - tent);
	}
	for (int i = 0; i < 3; i++) {
		vec2 c = vec2(0.07 + 0.016 * float(i), 0.03);
		float truck = step(abs(q.x - c.x), 0.0035) * step(abs(q.y - c.y), 0.009);
		g = mix(g, 0.35, truck);
	}
	return g;
}

void fragment() {
	vec2 uv = uv2;
	// CRT barrel distortion.
	vec2 cc = uv - 0.5;
	uv = 0.5 + cc * (1.0 + 0.09 * dot(cc, cc));
	float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
	float db = t - blast;
	// Shake after the blast; tape jitter while rewinding.
	vec2 jit = vec2(0.0);
	if (db > 0.0) jit += vec2(sin(db * 61.0), cos(db * 47.0)) * 0.012 * exp(-db * 2.2);
	jit.x += rewind * (0.02 * sin(uv.y * 40.0 + tr * 30.0) + 0.05 * step(0.92, fract(uv.y * 3.0 - tr * 2.0)));
	// Switching source: blocks of the picture tear sideways.
	float band = floor(uv.y * 14.0 + floor(tr * 20.0));
	jit.x += glitch * 0.15 * (h3(vec3(band, floor(tr * 24.0), 3.0)) - 0.5) * step(0.5, h3(vec3(band, floor(tr * 24.0), 8.0)));
	vec2 w = (uv + jit - 0.5) * vec2(0.42, 0.32) + vec2(0.0025 * t, 0.001 * t);
	float g = scene < 0.5 ? whitehouse(w) : terrain(w);
	if (live_mix > 0.0) {
		vec3 lv = texture(live, clamp(uv + jit, 0.0, 1.0)).rgb;
		g = mix(g, dot(lv, vec3(0.3, 0.59, 0.11)) * 1.05, live_mix);
	}
	// The blast: the ground domes up (a bright crown with a shadowed edge), then a ring of dust rolls out.
	if (db > 0.0) {
		float r = length(w);
		float dome = exp(-db * 0.6) * (1.0 - smoothstep(0.0, 0.05 + 0.02 * min(db, 1.0), r));
		g += 0.35 * dome * (1.0 - exp(-db * 6.0));
		float ring = 0.03 + 0.09 * (1.0 - exp(-db * 1.4));
		float band = exp(-pow((r - ring) / (0.012 + 0.02 * min(db, 1.5)), 2.0));
		float dust = (1.0 - smoothstep(0.0, ring, r)) * (0.5 + 0.5 * fbm(vec3(w * 40.0, db)));
		g = mix(g, 0.78, clamp(band * 0.7 + dust * 0.4 * min(db * 2.0, 1.0), 0.0, 0.7));
		g -= 0.18 * exp(-pow((r - ring - 0.02) / 0.012, 2.0)) * min(db, 1.0);
	}
	// Sensor look: contrast, grain, a slight vignette.
	g = clamp((g - 0.5) * 1.45 + 0.5, 0.02, 0.97);
	g += (h3(vec3(uv * 900.0, floor(tr * 24.0))) - 0.5) * (0.1 + 0.5 * glitch);
	g = mix(g, 0.9, glitch * 0.35 * step(0.7, h3(vec3(floor(uv.y * 40.0), floor(tr * 24.0), 2.0))));
	// Overlay: crosshair, corner brackets, ticks along the edges.
	vec2 o = uv - 0.5;
	float ch = (1.0 - smoothstep(0.0012, 0.0024, abs(o.x))) * step(0.03, abs(o.y)) * step(abs(o.y), 0.12);
	ch += (1.0 - smoothstep(0.0012, 0.0024, abs(o.y))) * step(0.04, abs(o.x)) * step(abs(o.x), 0.16);
	vec2 a = abs(o);
	float br = step(abs(a.x - 0.42), 0.002) * step(0.34, a.y) * step(a.y, 0.43) + step(abs(a.y - 0.43), 0.002) * step(0.34, a.x) * step(a.x, 0.42);
	float tick = step(abs(uv.y - 0.025), 0.008) * step(fract(uv.x * 20.0), 0.06) + step(abs(uv.x - 0.02), 0.008) * step(fract(uv.y * 16.0), 0.06);
	g = mix(g, 1.0, clamp(ch + br + tick, 0.0, 1.0) * 0.85);
	// Rewind: bright horizontal tracking bars and colour bleed.
	g += rewind * 0.5 * step(0.96, fract(uv.y * 2.0 + tr * 3.0));
	// Scanlines and a slow rolling bar, phosphor tint (cold), RGB fringe.
	float scan = 0.82 + 0.18 * sin(uv.y * 900.0);
	float roll = 0.94 + 0.06 * sin(uv.y * 6.0 - tr * 1.7);
	vec3 col = vec3(g) * vec3(0.86, 0.97, 1.0) * scan * roll;
	col.r *= 1.0 - 0.06 * sin(uv.x * 1400.0);
	float vig = 1.0 - 0.55 * pow(length(o) * 1.35, 2.6);
	col *= vig * inside * power;
	ALBEDO = col * energy;
}
"""

## A wall TV: a SubViewport's picture on a curved CRT, with scanlines; turns on with a white line.
const TV := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D feed : source_color, filter_linear;
uniform float on = 0.0;          // seconds since it was switched on (<0: off)
uniform float energy = 1.2;
uniform float t = 0.0;
varying vec2 uv2;
//NOISE
void vertex() { uv2 = UV; }
void fragment() {
	vec2 uv = uv2;
	vec2 cc = uv - 0.5;
	uv = 0.5 + cc * (1.0 + 0.07 * dot(cc, cc));
	float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
	vec3 pic = texture(feed, vec2(uv.x, uv.y)).rgb;
	// Power-on: a bright horizontal line opens vertically, a flash, then the picture settles.
	float k = clamp(on / 0.22, 0.0, 1.0);
	float open = step(abs(uv.y - 0.5), 0.5 * k * k + 0.004);
	float flash = exp(-max(on, 0.0) * 7.0) * step(0.0, on);
	vec3 col = pic * open + vec3(0.9, 0.95, 1.0) * flash * open;
	col *= 0.86 + 0.14 * sin(uv.y * 700.0);
	col += (h3(vec3(uv * 600.0, floor(t * 30.0))) - 0.5) * 0.05;
	col *= (1.0 - 0.5 * pow(length(cc) * 1.3, 2.5)) * inside * step(0.0, on);
	ALBEDO = vec3(0.012, 0.013, 0.015) + col * energy;
}
"""

## Office carpet: low-pile blue-grey with a tight speckle and traffic wear.
const CARPET := """
shader_type spatial;
//NOISE
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float s = h3(floor(wp * 260.0));
	float m = fbm(wp * 1.3);
	vec3 base = mix(vec3(0.16, 0.18, 0.22), vec3(0.24, 0.26, 0.3), s);
	base *= 0.85 + 0.3 * m;
	base = mix(base, vec3(0.2, 0.19, 0.18), smoothstep(0.6, 0.9, fbm(wp * 0.6 + 3.0)) * 0.4);
	ALBEDO = base;
	ROUGHNESS = 0.95;
}
"""

## Painted drywall: off-white, faint roller texture, scuffs and grime near the floor.
const WALL := """
shader_type spatial;
//NOISE
uniform vec3 paint = vec3(0.78, 0.76, 0.7);
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float r = fbm(wp * 9.0) * 0.06 + fbm(wp * 0.8) * 0.08;
	vec3 c = paint * (0.92 + r);
	c *= 1.0 - 0.18 * (1.0 - smoothstep(0.0, 0.35, wp.y - floor(wp.y / 1000.0)));
	c = mix(c, c * 0.8, smoothstep(0.55, 0.8, fbm(wp * 2.5 + 9.0)) * 0.3);
	ALBEDO = c;
	ROUGHNESS = 0.88;
	SPECULAR = 0.2;
}
"""

## Steam over the coffee: soft additive wisps that rise and curl.
const STEAM := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform float t = 0.0;
uniform float seed = 0.0;
varying vec2 uv2;
//NOISE
void vertex() { uv2 = UV; }
void fragment() {
	vec2 p = uv2;
	float x = p.x - 0.5 + 0.12 * sin(p.y * 6.0 + t * 1.3 + seed) * p.y;
	float body = exp(-pow(x / (0.08 + 0.12 * p.y), 2.0));
	float n = fbm(vec3(p.x * 3.0, p.y * 4.0 - t * 0.7, seed));
	float a = body * smoothstep(0.0, 0.15, p.y) * (1.0 - smoothstep(0.55, 1.0, p.y)) * smoothstep(0.35, 0.75, n);
	ALBEDO = vec3(0.55, 0.6, 0.7) * a * 0.35;
}
"""

const PRINT := """
shader_type spatial;
uniform sampler2D view : source_color, filter_linear;
uniform float ring = 1.0;
uniform float seed = 0.0;
varying vec2 uvp;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453); }
void vertex() { uvp = UV; }
void fragment() {
	vec2 b = abs(uvp - 0.5);
	float border = step(0.455, max(b.x, b.y));
	vec2 iuv = (uvp - 0.5) / 0.91 + 0.5;
	vec3 v = texture(view, iuv).rgb;
	float g = dot(v, vec3(0.3, 0.59, 0.11));
	g = clamp((g - 0.5) * 1.15 + 0.46, 0.0, 1.0);
	g += (h(floor(uvp * 700.0)) - 0.5) * 0.12;
	vec3 c = vec3(g) * vec3(0.98, 0.97, 0.94);
	float r = abs(length((uvp - vec2(0.5, 0.5)) * vec2(1.0, 1.0)) - 0.12 - 0.01 * sin(atan(uvp.y - 0.5, uvp.x - 0.5) * 3.0));
	c = mix(c, vec3(0.75, 0.1, 0.08), (1.0 - smoothstep(0.004, 0.009, r)) * ring * (1.0 - border));
	c = mix(c, vec3(0.95, 0.94, 0.9), border);
	ALBEDO = c;
	ROUGHNESS = 0.18;
	SPECULAR = 0.7;
}
"""


var _p := {}
var _prints: Array = []
var _print_view: SubViewport
var _print_cam: Camera3D
var _print_sun: SpotLight3D
var _live_view: SubViewport
var _live_cam: Camera3D
var _live_sun: SpotLight3D
var _chair_top: Node3D
var _chair_base: Node3D
var _chair_post: MeshInstance3D
var _feed_mat: ShaderMaterial
var _tv_mat: ShaderMaterial
var _tv_view: SubViewport
var _tv_cam: Camera3D
var _steam: Array = []
var _globe_snow: MultiMeshInstance3D
var _globe: Node3D
var _fluoro: MeshInstance3D
var _fluoro_light: Light3D
var _stamp: Label3D
var _stamp_px := 0.0
var _stamp_mod := Color.WHITE
var _coord: Label3D
var _clock: Label3D


func _prints_build(root: Node3D) -> void:
	var pd: Dictionary = _p.get("prints", {})
	if pd.is_empty():
		return
	_print_view = SubViewport.new()
	_print_view.size = Vector2i(768, 768)
	_print_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_print_view.own_world_3d = false
	_print_view.msaa_3d = Viewport.MSAA_2X
	root.add_child(_print_view)
	_print_cam = Camera3D.new()
	_print_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_print_cam.size = float(pd.get("ortho", 34.0))
	_print_cam.near = 1.0
	_print_cam.far = 2000.0
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.5, 0.48, 0.44)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.6, 0.56)
	env.ambient_light_energy = 1.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_print_cam.environment = env
	_print_view.add_child(_print_cam)
	# The morning sun over the photographed place (far from this room): a narrow, distant spot at a low angle, so the
	# trucks and the tripod throw the long shadows analysts read. On only around the prints.
	_print_sun = SpotLight3D.new()
	_print_sun.light_color = Color(1.0, 0.92, 0.8)
	_print_sun.light_energy = 14.0
	_print_sun.spot_range = 900.0
	_print_sun.spot_angle = 6.0
	_print_sun.spot_attenuation = 0.0
	_print_sun.shadow_enabled = true
	_print_sun.visible = false
	root.add_child(_print_sun)
	for k in 2:
		var q := MeshInstance3D.new()
		var qm := PlaneMesh.new()
		qm.size = Vector2(0.254, 0.203)
		q.mesh = qm
		var m := Kit.shader(PRINT)
		m.set_shader_parameter("view", _print_view.get_texture())
		m.set_shader_parameter("ring", 0.0)
		m.set_shader_parameter("seed", float(k) * 3.1)
		q.material_override = m
		q.position = Vector3(0.06, DESK_TOP + 0.004, -1.2)
		q.rotation.y = 0.07
		root.add_child(q)
		_prints.append(q)


func _live_build(root: Node3D) -> void:
	var ld: Dictionary = _p.get("live", {})
	if ld.is_empty():
		return
	_live_view = SubViewport.new()
	_live_view.size = Vector2i(800, 640)
	_live_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_live_view.own_world_3d = false
	root.add_child(_live_view)
	_live_cam = Camera3D.new()
	_live_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_live_cam.size = float(ld.get("ortho", 26.0))
	_live_cam.near = 1.0
	_live_cam.far = 2000.0
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.5, 0.48, 0.44)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.6, 0.56)
	env.ambient_light_energy = 1.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_live_cam.environment = env
	_live_view.add_child(_live_cam)
	_live_sun = SpotLight3D.new()
	_live_sun.light_color = Color(1.0, 0.95, 0.85)
	_live_sun.light_energy = 14.0
	_live_sun.spot_range = 900.0
	_live_sun.spot_angle = 6.0
	_live_sun.spot_attenuation = 0.0
	_live_sun.shadow_enabled = true
	_live_sun.visible = false
	root.add_child(_live_sun)
	_feed_mat.set_shader_parameter("live", _live_view.get_texture())


func _pose_live(t: float, ctx: Dictionary) -> void:
	var ld: Dictionary = _p.get("live", {})
	if ld.is_empty() or _live_view == null:
		return
	var on := t >= float(ld.get("from", 1e9)) and t < float(ld.get("until", 1e9))
	_feed_mat.set_shader_parameter("live_mix", 1.0 if on else 0.0)
	_live_sun.visible = on
	if not on:
		return
	# Its own date on the stamp (the rewind's landing date stays only until a live feed takes over).
	_stamp.pixel_size = _stamp_px
	_stamp.modulate = _stamp_mod
	_stamp.text = "%s  09:42:%02dZ" % [String(ld.get("stamp", "MAY 1998")), int(fposmod(floor(t * 1.0), 60.0))]
	var cp: Dictionary = ctx["point"].call(ld["cam"]) if ld.has("cam") else {}
	if cp.has("pos"):
		var cpos: Vector3 = cp["pos"]
		# The feed scrolls slowly as the satellite moves; north up.
		_live_cam.global_transform = Transform3D(Basis.looking_at(Vector3.DOWN, Vector3.FORWARD), cpos + Vector3(0.12 * t, 0, 0.05 * t) - Vector3(0.12, 0, 0.05) * float(ld.get("from", 0.0)))
		var ground := cpos - Vector3(0, 260.0, 0)
		var from := ground + Vector3(-220.0, 230.0, 260.0)
		_live_sun.global_transform = Transform3D(Basis.looking_at(ground - from, Vector3.UP), from)


func _pose_prints(gt: Transform3D, t: float, ctx: Dictionary) -> Vector3:
	var pd: Dictionary = _p.get("prints", {})
	if pd.is_empty() or _prints.is_empty():
		return Vector3.ZERO
	var cp: Dictionary = ctx["point"].call(pd["cam"]) if pd.has("cam") else {}
	var ts := float(pd.get("slide", 1e9))
	if cp.has("pos"):
		var cpos: Vector3 = cp["pos"]
		_print_cam.global_transform = Transform3D(Basis.looking_at(Vector3.DOWN, Vector3.FORWARD), cpos)
		var ground := cpos - Vector3(0, 260.0, 0)
		var from := ground + Vector3(260.0, 140.0, -330.0)
		_print_sun.global_transform = Transform3D(Basis.looking_at(ground - from, Vector3.UP), from)
		_print_sun.visible = t > ts - 2.0 and t < float(pd.get("shrug", ts)) + 3.0
	# The second print slides in from the right beside the first, under his fingers, easing to a stop.
	var u := Motion.out_cubic(Motion.seg(t, ts - 0.6, ts))
	var p2: MeshInstance3D = _prints[1]
	var from := Vector3(0.72, DESK_TOP + 0.006, -1.06)
	var to := Vector3(0.36, DESK_TOP + 0.006, -1.19)
	p2.position = from.lerp(to, u)
	p2.rotation.y = lerpf(-0.25, -0.05, u)
	var aid := String(pd.get("hand", ""))
	var actor = ctx["actor"].call(aid) if aid != "" and ctx.has("actor") else null
	if actor != null and actor.visible:
		var on := Motion.smooth(Motion.seg(t, ts - 0.95, ts - 0.6)) * (1.0 - Motion.smooth(Motion.seg(t, ts + 0.1, ts + 0.45)))
		actor.aim_hand("r", gt * (p2.position + Vector3(0.09, 0.03, 0.06)), on)
		# The shrug: both hands out to the sides, palms up, shoulders raised; held a beat, then dropped.
		var tsh := float(pd.get("shrug", 1e9))
		var w := Motion.smooth(Motion.seg(t, tsh - 0.25, tsh + 0.05)) * (1.0 - Motion.smooth(Motion.seg(t, tsh + 0.75, tsh + 1.1)))
		if w > 0.0:
			var inv := gt.affine_inverse()
			var chest: Vector3 = inv * actor.bone_world("spine_03")
			var ay := float(actor.rotation.y)
			var fwd := Vector3(sin(ay), 0, cos(ay))
			var left := Vector3(cos(ay), 0, -sin(ay))
			for side in ["l", "r"]:
				var sg := 1.0 if side == "l" else -1.0
				actor.aim_hand(side, gt * (chest + left * sg * 0.34 + fwd * 0.2 + Vector3(0, 0.02, 0)), w, 0.06 * w)
	return (_prints[0] as Node3D).position.lerp(p2.position, 0.5)


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	_shell(root)
	_window(root)
	_desk(root)
	_prints_build(root)
	_live_build(root)
	_shelves(root)
	_tv(root)
	_report_build(root)
	return root


var _report: Node3D
var _mug: Node3D
var _spill: MeshInstance3D


func _report_build(root: Node3D) -> void:
	var rd: Dictionary = _p.get("report", {})
	if rd.is_empty():
		return
	_report = Node3D.new()
	_report.name = "report"
	root.add_child(_report)
	var navy := Kit.mat("#1c2a48", 0.6)
	Kit.box(_report, Vector3(0.23, 0.008, 0.3), Vector3(0, 0.004, 0), navy)
	Kit.box(_report, Vector3(0.22, 0.07, 0.29), Vector3(0.004, 0.043, 0), Kit.mat("#efeadc", 0.9))
	Kit.box(_report, Vector3(0.23, 0.008, 0.3), Vector3(0, 0.082, 0), navy)
	Kit.box(_report, Vector3(0.012, 0.086, 0.3), Vector3(-0.115, 0.043, 0), Kit.mat("#0c0c10", 0.5))
	for k in 6:
		Kit.box(_report, Vector3(0.21, 0.0015, 0.28), Vector3(0.005, 0.012 + 0.011 * k, 0.0), Kit.mat("#d8d2c0", 0.95))
	Kit.text(_report, "SECRET", 0.04, "#c0201a", Vector3(0.0, 0.0865, -0.08), Vector3(-PI / 2, 0, 0), true)
	Kit.box(_report, Vector3(0.16, 0.001, 0.03), Vector3(0.0, 0.0868, -0.08), Kit.mat("#c0201a", 0.7))
	Kit.text(_report, "SECRET", 0.03, "#f4f0e8", Vector3(0.0, 0.0872, -0.08), Vector3(-PI / 2, 0, 0), true)


func _pose_report(gt: Transform3D, t: float, ctx: Dictionary) -> float:
	## Returns how long ago it landed (negative before).
	var rd: Dictionary = _p.get("report", {})
	if _report == null:
		return -1e9
	var drop := float(rd["drop"])
	var desk := Vector3(float(rd["at"][0]), DESK_TOP, float(rd["at"][1]))
	var inv := gt.affine_inverse()
	var a = ctx["actor"].call(String(rd["hand"])) if ctx.has("actor") else null
	_report.visible = a != null and a.visible or t >= drop
	if a == null or not _report.visible:
		return t - drop
	var ay := float(a.rotation.y)
	var fwd := Vector3(sin(ay), 0, cos(ay))
	var held: Vector3 = inv * (a.bone_world("spine_03") + fwd * 0.32 + Vector3(0, 0.25, 0))
	var lift := held + Vector3(0, 0.35, 0)
	if t < drop - 0.45:
		_report.position = held
		_report.rotation = Vector3(-0.3, ay - gt.basis.get_euler().y, 0.0)
	elif t < drop:
		# Wind-up (raise it high) then slam down: anticipation, then a fast in-cubic fall.
		var u := Motion.seg(t, drop - 0.45, drop - 0.2)
		var v := Motion.in_cubic(Motion.seg(t, drop - 0.2, drop))
		var top := held.lerp(lift, Motion.out_cubic(u))
		_report.position = top.lerp(desk, v)
		_report.rotation = Vector3(lerpf(-0.6, 0.0, v), lerpf(ay - gt.basis.get_euler().y, 0.25, v), 0.0)
	else:
		var k := t - drop
		var bounce := 0.025 * exp(-k * 14.0) * absf(sin(k * 40.0))
		_report.position = desk + Vector3(0, bounce, 0)
		_report.rotation = Vector3(0.0, 0.25, 0.04 * exp(-k * 10.0) * sin(k * 50.0))
		var sq := Motion.squash(-0.25 * exp(-k * 18.0))
		_report.scale = sq
	# The hand follows the report until the slam.
	if t < drop + 0.15:
		Crawl.long_arms(a, 1.4)
		a.aim_hand("r", gt * (_report.position + Vector3(0.0, 0.09, 0.0)), 1.0)
	return t - drop


# --- the room ---------------------------------------------------------------------------

func _shell(root: Node3D) -> void:
	var hx := ROOM.x * 0.5
	var hz := ROOM.z * 0.5
	Kit.box(root, Vector3(ROOM.x, 0.04, ROOM.z), Vector3(0, -0.02, 0), Kit.shader(CARPET))
	var wall := Kit.shader(WALL)
	Kit.box(root, Vector3(ROOM.x, ROOM.y, 0.12), Vector3(0, ROOM.y * 0.5, -hz - 0.06), wall)
	Kit.box(root, Vector3(ROOM.x, ROOM.y, 0.12), Vector3(0, ROOM.y * 0.5, hz + 0.06), wall)
	Kit.box(root, Vector3(0.12, ROOM.y, ROOM.z), Vector3(hx + 0.06, ROOM.y * 0.5, 0), wall)
	# The window wall (-x) is built around the window opening (z -0.4 .. 1.1, y 0.85 .. 2.05).
	var wx := -hx - 0.06
	Kit.box(root, Vector3(0.12, 0.85, ROOM.z), Vector3(wx, 0.425, 0), wall)
	Kit.box(root, Vector3(0.12, ROOM.y - 2.05, ROOM.z), Vector3(wx, (ROOM.y + 2.05) * 0.5, 0), wall)
	Kit.box(root, Vector3(0.12, 1.2, hz - 0.4), Vector3(wx, 1.45, (-hz - 0.4) * 0.5), wall)
	Kit.box(root, Vector3(0.12, 1.2, hz - 1.1), Vector3(wx, 1.45, (hz + 1.1) * 0.5), wall)
	# Skirting (vinyl cove base), dark grey.
	var cove := Kit.mat("#2a2a2c", 0.6)
	Kit.box(root, Vector3(ROOM.x, 0.1, 0.02), Vector3(0, 0.05, -hz + 0.01), cove)
	Kit.box(root, Vector3(ROOM.x, 0.1, 0.02), Vector3(0, 0.05, hz - 0.01), cove)
	Kit.box(root, Vector3(0.02, 0.1, ROOM.z), Vector3(hx - 0.01, 0.05, 0), cove)
	# Drop ceiling: off-white tiles in a T-bar grid; one fluorescent troffer lit (flickering), one dead.
	var tile := Kit.mat("#bdbab2", 0.95)
	var grid := Kit.mat("#d8d6d0", 0.5, 0.0, 0.6)
	Kit.box(root, Vector3(ROOM.x, 0.03, ROOM.z), Vector3(0, ROOM.y + 0.015, 0), tile)
	var x := -hx
	while x <= hx + 0.01:
		Kit.box(root, Vector3(0.025, 0.02, ROOM.z), Vector3(x, ROOM.y - 0.005, 0), grid)
		x += 0.6
	var z := -hz
	while z <= hz + 0.01:
		Kit.box(root, Vector3(ROOM.x, 0.02, 0.025), Vector3(0, ROOM.y - 0.005, z), grid)
		z += 0.6
	for i in 2:
		var at := Vector3(-0.3 + 1.2 * i, ROOM.y - 0.02, -0.6 + 1.8 * i)
		Kit.box(root, Vector3(0.6, 0.03, 1.2), at, Kit.mat("#cfcdc6", 0.4))
		var lens := Kit.box(root, Vector3(0.54, 0.01, 1.14), at - Vector3(0, 0.02, 0), Kit.lit("#dfe9ee", 0.12) if i == 0 else Kit.mat("#8f9396", 0.3))
		if i == 0:
			_fluoro = lens
	_fluoro_light = Kit.spot(root, Vector3(-0.3, ROOM.y - 0.08, -0.6), Vector3(-0.3, 0, -0.4), "#cfe3e8", 0.9, 4.5, 70.0, true, 0.4)


func _window(root: Node3D) -> void:
	var hx := ROOM.x * 0.5
	var wx := -hx - 0.06
	# Aluminium frame, the glass, and a night outside: a sodium street lamp below and beyond.
	var alu := Kit.mat("#9a9b98", 0.35, 0.0, 0.7)
	Kit.box(root, Vector3(0.14, 0.05, 1.6), Vector3(wx, 0.85, 0.35), alu)
	Kit.box(root, Vector3(0.14, 0.05, 1.6), Vector3(wx, 2.05, 0.35), alu)
	for zz in [-0.42, 1.12]:
		Kit.box(root, Vector3(0.14, 1.25, 0.05), Vector3(wx, 1.45, zz), alu)
	Kit.box(root, Vector3(0.3, 0.03, 1.6), Vector3(wx + 0.12, 0.84, 0.35), Kit.mat("#cfcbc0", 0.6))
	# Outside: a dark parking lot facade far off and the lamp's glow.
	Kit.box(root, Vector3(0.1, 6, 12), Vector3(wx - 9.0, 2, 0.4), Kit.mat("#0b0c10", 0.9))
	Kit.ball(root, 0.16, Vector3(wx - 3.0, 3.1, 1.6), Kit.lit("#ff9a3a", 10.0), 16)
	# Venetian blinds: 1-inch aluminium slats, tilted half open, real geometry that throws stripes.
	var slat := Kit.mat("#c9c6bb", 0.45, 0.0, 0.6)
	var y := 2.02
	while y > 0.9:
		Kit.box(root, Vector3(0.028, 0.002, 1.5), Vector3(wx + 0.1, y, 0.35), slat, Vector3(0, 0, -0.75))
		y -= 0.024
	Kit.box(root, Vector3(0.05, 0.04, 1.56), Vector3(wx + 0.1, 2.04, 0.35), Kit.mat("#bdb9ad", 0.5))
	for zz in [-0.1, 0.8]:
		Kit.rod(root, Vector3(wx + 0.1, 2.02, zz), Vector3(wx + 0.1, 0.9, zz), 0.0015, Kit.mat("#e8e4d8", 0.6), 4)
	# The sodium light through the slats: a hard spot from outside, low and from behind the analyst.
	Kit.spot(root, Vector3(wx - 3.0, 3.1, 1.6), Vector3(0.2, 0.9, -1.2), "#ff9440", 30.0, 9.0, 22.0, true, 1.6)


func _desk(root: Node3D) -> void:
	# The steel desk (Poly Haven, scaled to the toon world), against the front wall.
	var desk := Kit.model(PH + "metal_office_desk/metal_office_desk_2k.gltf")
	desk.scale = Vector3.ONE * (DESK_TOP / 0.787)
	desk.position = Vector3(0, 0, -1.78)
	root.add_child(desk)
	# The hero CRT: a 21-inch beige monitor, deep tapered back, the feed on a curved screen.
	var beige := Kit.mat("#cfc6b0", 0.55, 0.0, 0.45)
	var beige_d := Kit.mat("#b6ad96", 0.6, 0.0, 0.4)
	var mon := Node3D.new()
	mon.position = Vector3(SCREEN.x, DESK_TOP, SCREEN.z - 0.04)
	root.add_child(mon)
	Kit.slab(mon, Vector3(0.3, 0.03, 0.26), 0.012, Vector3(0, 0.015, -0.12), beige_d)
	Kit.cyl(mon, 0.07, 0.09, 0.08, Vector3(0, 0.07, -0.14), beige_d, 20)
	Kit.slab(mon, Vector3(0.56, 0.46, 0.16), 0.03, Vector3(0, SCREEN.y - DESK_TOP, 0.0), beige)
	Kit.slab(mon, Vector3(0.44, 0.36, 0.3), 0.06, Vector3(0, SCREEN.y - DESK_TOP + 0.01, -0.2), beige_d)
	Kit.box(mon, Vector3(0.5, 0.38, 0.01), Vector3(0, SCREEN.y - DESK_TOP, 0.078), Kit.mat("#0a0b0c", 0.2, 0.0, 0.8))
	Kit.box(mon, Vector3(0.04, 0.012, 0.004), Vector3(0.21, SCREEN.y - DESK_TOP - 0.205, 0.081), Kit.mat("#7c776a", 0.5))
	Kit.ball(mon, 0.004, Vector3(0.245, SCREEN.y - DESK_TOP - 0.205, 0.082), Kit.lit("#7dff6a", 3.0), 6)
	_feed_mat = Kit.shader(FEED)
	_feed_mat.set_shader_parameter("aerial", Kit.texture("incoming/polyhaven_textures/aerial_rocks_02_diff_2k.jpg"))
	var feed := Kit.quad(mon, SCREEN_SIZE, Vector3(0, SCREEN.y - DESK_TOP, 0.084), _feed_mat)
	feed.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The screen's cold light on the analyst (the key).
	Kit.spot(root, SCREEN + Vector3(0, 0, 0.15), Vector3(0.25, 1.1, -0.6), "#bfe0ff", 0.3, 3.0, 50.0, true, 0.5)
	# Stamp and coordinates burned into the feed.
	var stamp: String = String(_p.get("stamp", "11 MAY 1998"))
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas", "Lucida Console", "Courier New", "monospace"])
	_stamp = Kit.text(mon, stamp + "  10:15:00Z", 0.014, Color("eaf6ff"), Vector3(-0.07, SCREEN.y - DESK_TOP + 0.138, 0.086), Vector3.ZERO, false, 0.55)
	_stamp.font = mono
	_stamp_px = _stamp.pixel_size
	_stamp_mod = _stamp.modulate
	_coord = Kit.text(mon, "27 05N  071 45E", 0.011, Color("d6ebff"), Vector3(0.12, SCREEN.y - DESK_TOP - 0.143, 0.086), Vector3.ZERO, false, 0.5)
	_coord.font = mono
	# A second CRT angled in, green terminal text; a beige tower; keyboard, mouse, papers.
	var mon2 := Node3D.new()
	mon2.position = Vector3(-0.66, DESK_TOP, -1.86)
	mon2.rotation = Vector3(0, 0.35, 0)
	root.add_child(mon2)
	Kit.slab(mon2, Vector3(0.42, 0.36, 0.14), 0.025, Vector3(0, 0.26, 0), beige)
	Kit.slab(mon2, Vector3(0.34, 0.28, 0.24), 0.05, Vector3(0, 0.27, -0.17), beige_d)
	Kit.cyl(mon2, 0.06, 0.08, 0.06, Vector3(0, 0.04, -0.1), beige_d, 18)
	var term := Kit.quad(mon2, Vector2(0.32, 0.24), Vector3(0, 0.27, 0.071), Kit.lit("#0f2a12", 1.0))
	term.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 9:
		var wv := 0.08 + 0.18 * Kit.rng("term", i).randf()
		Kit.box(mon2, Vector3(wv, 0.008, 0.001), Vector3(-0.13 + wv * 0.5, 0.37 - 0.022 * i, 0.073), Kit.lit("#4dff6a", 1.4))
	Kit.omni(root, Vector3(-0.6, 0.95, -1.55), "#3aff6a", 0.06, 1.0, false, 0.1)
	Kit.slab(root, Vector3(0.2, 0.44, 0.46), 0.015, Vector3(0.82, 0.22, -1.7), beige)
	Kit.box(root, Vector3(0.012, 0.005, 0.03), Vector3(0.82, 0.38, -1.468), Kit.lit("#ffb020", 2.0))
	Kit.slab(root, Vector3(0.46, 0.03, 0.17), 0.01, Vector3(0.0, DESK_TOP + 0.015, -1.46), beige)
	for row in 5:
		for k in 15:
			Kit.box(root, Vector3(0.022, 0.008, 0.022), Vector3(-0.2 + 0.028 * k, DESK_TOP + 0.034, -1.52 + 0.028 * row), Kit.mat("#ded6c2", 0.6))
	Kit.slab(root, Vector3(0.06, 0.03, 0.1), 0.012, Vector3(0.3, DESK_TOP + 0.015, -1.45), beige)
	# Two beige desk phones with rows of line buttons.
	for s in [0, 1]:
		var ph := Node3D.new()
		ph.position = Vector3(-0.95 + 0.2 * s, DESK_TOP, -1.6 + 0.25 * s)
		ph.rotation = Vector3(0, 0.25 + 0.2 * s, 0)
		root.add_child(ph)
		Kit.slab(ph, Vector3(0.2, 0.07, 0.22), 0.02, Vector3(0, 0.035, 0), beige, Vector3(-0.15, 0, 0))
		Kit.slab(ph, Vector3(0.22, 0.045, 0.06), 0.022, Vector3(0, 0.09, -0.04), beige_d)
		for b in 6:
			Kit.box(ph, Vector3(0.022, 0.006, 0.014), Vector3(-0.07 + 0.028 * b, 0.07, 0.07), Kit.mat("#efe9da", 0.5))
	# Papers, a clipboard (Poly Haven), notepads, the arm lamp (warm practical, low).
	var cb := Kit.model(PH + "clipboard/clipboard_2k.gltf")
	cb.position = Vector3(0.45, DESK_TOP, -1.62)
	cb.rotation = Vector3(0, -0.5, 0)
	root.add_child(cb)
	for i in 4:
		Kit.box(root, Vector3(0.21, 0.002, 0.29), Vector3(-0.35 + 0.05 * i, DESK_TOP + 0.002 + 0.002 * i, -1.25 - 0.03 * i), Kit.mat("#ece8de", 0.85), Vector3(0, -0.3 + 0.2 * i, 0))
	var lamp := Kit.model(PH + "desk_lamp_arm_01/desk_lamp_arm_01_2k.gltf")
	lamp.position = Vector3(-1.2, DESK_TOP, -1.98)
	lamp.rotation = Vector3(0, 2.3, 0)
	root.add_child(lamp)
	Kit.spot(root, Vector3(-1.05, DESK_TOP + 0.62, -1.78), Vector3(-0.6, DESK_TOP, -1.45), "#ffc27a", 1.6, 1.8, 40.0, true, 0.3)
	# The coffee mug, half drunk, with steam; the White House snow globe (souvenir).
	var mug := Node3D.new()
	mug.position = MUG_AT
	root.add_child(mug)
	_mug = mug
	# The spill (param "spill"): a coffee pool spreading over the desk from the tipped mug.
	_spill = Kit.cyl(root, 1.0, 1.0, 0.003, MUG_AT + Vector3(0.12, 0.002, 0.04), Kit.mat("#2a140a", 0.08, 0.0, 0.9), 24)
	_spill.visible = false
	Kit.cyl(mug, 0.042, 0.04, 0.1, Vector3(0, 0.05, 0), Kit.mat("#f0ece4", 0.25, 0.0, 0.7), 24)
	Kit.cyl(mug, 0.038, 0.038, 0.005, Vector3(0, 0.085, 0), Kit.mat("#2a160a", 0.15, 0.0, 0.8), 24)
	var handle := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.022
	tor.outer_radius = 0.032
	handle.mesh = tor
	handle.material_override = Kit.mat("#f0ece4", 0.25, 0.0, 0.7)
	handle.position = Vector3(0.045, 0.05, 0)
	handle.rotation = Vector3(PI / 2, 0, 0)
	mug.add_child(handle)
	for i in 3:
		var sm := Kit.shader(STEAM).duplicate() as ShaderMaterial
		sm.set_shader_parameter("seed", float(i) * 3.1)
		var q := Kit.quad(mug, Vector2(0.09, 0.26), Vector3(0.0, 0.22, 0.0), sm, Vector3(0, float(i) * 1.05, 0))
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_steam.append(sm)
	_globe = Node3D.new()
	_globe.position = GLOBE_AT
	root.add_child(_globe)
	Kit.cyl(_globe, 0.05, 0.058, 0.035, Vector3(0, 0.0175, 0), Kit.mat("#2b1a12", 0.35, 0.0, 0.6), 28)
	Kit.cyl(_globe, 0.052, 0.052, 0.006, Vector3(0, 0.032, 0), Kit.mat("#c9a14a", 0.3, 0.0, 0.8), 28)
	# The tiny White House, south front: the main block with two rows of windows and a balustrade, the
	# round two-storey south portico with six columns, low wings either side, a lawn and a fountain.
	var wh := Kit.mat("#f4f2ec", 0.55)
	var win := Kit.mat("#3a4048", 0.3)
	Kit.cyl(_globe, 0.044, 0.044, 0.004, Vector3(0, 0.037, 0), Kit.mat("#3f6a2e", 0.8), 28)
	Kit.box(_globe, Vector3(0.062, 0.022, 0.022), Vector3(0, 0.05, -0.012), wh)
	Kit.box(_globe, Vector3(0.064, 0.0025, 0.024), Vector3(0, 0.0622, -0.012), wh)
	for k in 13:
		Kit.box(_globe, Vector3(0.0012, 0.0025, 0.001), Vector3(-0.03 + 0.005 * k, 0.0648, -0.0005), wh)
	Kit.box(_globe, Vector3(0.064, 0.0008, 0.024), Vector3(0, 0.066, -0.012), wh)
	for row in 2:
		for k in 8:
			var xx := -0.027 + 0.0077 * k
			if absf(xx) < 0.009:
				continue
			Kit.box(_globe, Vector3(0.0028, 0.005, 0.0006), Vector3(xx, 0.0445 + 0.0095 * row, -0.0007), win)
	for s2 in [-1.0, 1.0]:
		Kit.box(_globe, Vector3(0.016, 0.009, 0.016), Vector3(s2 * 0.039, 0.0435, -0.012), wh)
	Kit.cyl(_globe, 0.0105, 0.0105, 0.021, Vector3(0, 0.0495, 0.0), Kit.mat("#ebe8e0", 0.55), 20, Vector3.ZERO)
	Kit.cyl(_globe, 0.0118, 0.0118, 0.002, Vector3(0, 0.0605, 0.0), wh, 20)
	for c in 6:
		var a := -1.15 + 0.46 * c
		Kit.cyl(_globe, 0.0009, 0.0009, 0.02, Vector3(sin(a) * 0.0112, 0.0495, cos(a) * 0.0112), Kit.mat("#ffffff", 0.5), 6)
	Kit.cyl(_globe, 0.004, 0.004, 0.0015, Vector3(0, 0.0395, 0.026), Kit.mat("#9fb8c8", 0.2, 0.0, 0.8), 16)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.9, 0.95, 1.0, 0.05)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.02
	glass.metallic_specular = 1.0
	glass.rim_enabled = true
	glass.rim = 0.15
	var shell := Kit.ball(_globe, 0.05, Vector3(0, 0.08, 0), glass, 32)
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_globe_snow = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var flake := SphereMesh.new()
	flake.radius = 0.0007
	flake.height = 0.0014
	flake.radial_segments = 4
	flake.rings = 2
	mm.mesh = flake
	mm.instance_count = 160
	_globe_snow.multimesh = mm
	_globe_snow.material_override = Kit.lit("#ffffff", 0.6)
	_globe.add_child(_globe_snow)
	# The office chair under the analyst. It follows his hips every frame (pose), so the seat sits just under
	# his thighs and the backrest just behind his back, whatever the seated pose does: no clipping.
	var dark := Kit.mat("#1e2026", 0.75)
	var steel := Kit.mat("#7f838a", 0.35, 0.0, 0.7)
	_chair_base = Node3D.new()
	_chair_base.name = "chair_base"
	root.add_child(_chair_base)
	for k in 5:
		var a := TAU * k / 5.0
		Kit.rod(_chair_base, Vector3(0, 0.06, 0), Vector3(sin(a) * 0.28, 0.04, cos(a) * 0.28), 0.015, steel, 6)
		Kit.ball(_chair_base, 0.03, Vector3(sin(a) * 0.28, 0.03, cos(a) * 0.28), dark, 8)
	_chair_post = Kit.cyl(_chair_base, 0.025, 0.025, 1.0, Vector3(0, 0.5, 0), steel, 10)
	# Seat-top frame: origin at the top of the cushion, +z the way he faces.
	_chair_top = Node3D.new()
	_chair_top.name = "chair_top"
	root.add_child(_chair_top)
	Kit.slab(_chair_top, Vector3(0.48, 0.07, 0.46), 0.06, Vector3(0, -0.035, 0), dark)
	var back := Node3D.new()
	back.position = Vector3(0, 0.0, -0.25)
	back.rotation.x = -0.12
	_chair_top.add_child(back)
	Kit.slab(back, Vector3(0.46, 0.62, 0.07), 0.06, Vector3(0, 0.38, 0), dark)
	Kit.box(back, Vector3(0.05, 0.12, 0.03), Vector3(0, 0.03, 0.0), steel)
	_chair_top.position = CHAIR_AT + Vector3(0, 0.43, 0)
	_chair_top.rotation.y = PI
	_chair_base.position = CHAIR_AT
	_fit_post()
	# A grey 4-drawer filing cabinet with a plant and a mug of pens, in the corner (+x, front).
	var grey := Kit.mat("#8c8e8c", 0.5, 0.0, 0.5)
	Kit.slab(root, Vector3(0.46, 1.32, 0.62), 0.01, Vector3(2.2, 0.66, -1.85), grey)
	for d in 4:
		Kit.box(root, Vector3(0.42, 0.29, 0.01), Vector3(2.2, 0.17 + 0.32 * d, -1.535), Kit.mat("#959794", 0.45, 0.0, 0.5))
		Kit.box(root, Vector3(0.12, 0.018, 0.02), Vector3(2.2, 0.26 + 0.32 * d, -1.525), steel)
		Kit.box(root, Vector3(0.07, 0.04, 0.003), Vector3(2.2, 0.21 + 0.32 * d, -1.527), Kit.mat("#ece6d2", 0.7))


func _shelves(root: Node3D) -> void:
	# A steel bookcase along the +x wall with ring binders (spines in faded office colours).
	var steel := Kit.mat("#6e7276", 0.45, 0.0, 0.5)
	var at := Vector3(ROOM.x * 0.5 - 0.2, 0, 0.6)
	for side in [-0.5, 0.5]:
		Kit.box(root, Vector3(0.32, 1.9, 0.025), at + Vector3(0, 0.95, side * 1.2), steel)
	var cols := ["#2a3f6a", "#6a1f22", "#2c4a32", "#1b1c20", "#8a7a52", "#3a3a40", "#5a2d4a"]
	for s in 5:
		var y := 0.08 + 0.4 * s
		Kit.box(root, Vector3(0.32, 0.02, 1.2), at + Vector3(0, y, 0), steel)
		if s == 4:
			continue
		var r := Kit.rng("binders", s)
		var z := -0.56
		while z < 0.55:
			var wv := r.randf_range(0.04, 0.075)
			var hv := r.randf_range(0.29, 0.33)
			var tilt := 0.0 if r.randf() < 0.85 else r.randf_range(-0.25, 0.25)
			Kit.box(root, Vector3(0.27, hv, wv), at + Vector3(0.0, y + 0.01 + hv * 0.5, z + wv * 0.5), Kit.mat(cols[r.randi() % cols.size()], 0.7), Vector3(tilt, 0, 0))
			Kit.box(root, Vector3(0.002, 0.07, wv * 0.6), at + Vector3(-0.136, y + 0.08 + hv * 0.45, z + wv * 0.5), Kit.mat("#e9e4d6", 0.8))
			z += wv + 0.004
			if r.randf() < 0.08:
				z += 0.12
	# The wall clock (Poly Haven) above the desk; and a framed agency seal-free photo of a satellite dish.
	var clock := Kit.model(PH + "wall_clock/wall_clock_2k.gltf")
	clock.position = Vector3(-1.4, 2.0, -ROOM.z * 0.5)
	root.add_child(clock)


func _tv(root: Node3D) -> void:
	# A CRT TV on a ceiling-corner bracket on the back wall, tilted down at the desk.
	var black := Kit.mat("#141416", 0.45, 0.0, 0.5)
	var tvn := Node3D.new()
	tvn.position = TV_AT
	tvn.rotation = Vector3(-0.26, PI, 0)
	root.add_child(tvn)
	Kit.slab(tvn, Vector3(0.94, 0.76, 0.52), 0.04, Vector3(0, 0, -0.2), black)
	Kit.slab(tvn, Vector3(0.98, 0.8, 0.08), 0.03, Vector3(0, 0, 0.04), Kit.mat("#202124", 0.4, 0.0, 0.5))
	Kit.box(tvn, Vector3(0.5, 0.06, 0.05), Vector3(0, -0.47, -0.16), black)
	Kit.rod(root, TV_AT + Vector3(0, 0.3, 0.25), TV_AT + Vector3(0, 0.65, 0.18), 0.02, black, 8)
	_tv_mat = Kit.shader(TV).duplicate() as ShaderMaterial
	var scr := Kit.quad(tvn, TV_SIZE, Vector3(0, 0, 0.082), _tv_mat)
	scr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_tv_view = SubViewport.new()
	_tv_view.size = Vector2i(640, 480)
	_tv_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_tv_view.own_world_3d = false
	_tv_view.msaa_3d = Viewport.MSAA_2X
	tvn.add_child(_tv_view)
	_tv_cam = Camera3D.new()
	_tv_cam.fov = 30.0
	_tv_cam.near = 0.05
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.1, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.5, 0.48)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.85
	_tv_cam.environment = env
	_tv_view.add_child(_tv_cam)
	_tv_mat.set_shader_parameter("feed", _tv_view.get_texture())
	_tv_mat.set_shader_parameter("on", -1.0)
	# The TV's own glow into the room when it is on (driven in pose).
	var gl := Kit.omni(root, TV_AT + Vector3(0, -0.1, -0.35), "#b8c8ff", 0.0, 3.0, false, 0.5)
	gl.name = "tv_glow"
	tvn.name = "tv"


## The gas post runs from the star base up to the seat's underside.
func _fit_post() -> void:
	var top := _chair_top.position.y - 0.07
	_chair_post.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(1, maxf(top - 0.06, 0.05), 1)), Vector3(0, 0.06 + (top - 0.06) * 0.5, 0))
	_chair_base.position.x = _chair_top.position.x
	_chair_base.position.z = _chair_top.position.z


func _pose_chair(gt: Transform3D, ctx: Dictionary) -> void:
	var actor = ctx["actor"].call("analyst") if ctx.has("actor") else null
	if actor == null:
		return
	var inv := gt.affine_inverse()
	var yaw := float(actor.rotation.y) - gt.basis.get_euler().y
	var fwd := Vector3(sin(yaw), 0, cos(yaw))
	# The bean torso hangs about 9 cm below the hip joints when seated (measured from the side): the seat top
	# goes there, centred a little behind the hips. Bones are exact right after posing (attachments lag a frame).
	var hip: Vector3 = inv * ((actor.bone_world("thigh_l") + actor.bone_world("thigh_r")) * 0.5)
	var seat := hip - fwd * 0.08
	seat.y = hip.y - 0.095
	_chair_top.position = seat
	_chair_top.rotation = Vector3(0, yaw, 0)
	_fit_post()


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	_pose_chair(gt, ctx)
	# The feed. The hook (params "wh"): the White House blows up at `blast`; from `rewind` the tape runs
	# backwards (feed time falls back past the blast, faster and faster); at `switch` the feed glitches over to
	# the Pokhran range. Later shots use "blast" (Pokhran test times) and "rewind" (1998 -> 1995).
	var wh = _p.get("wh", {})
	var ft := t
	var scene := 1.0
	var rew := 0.0
	var glitch := 0.0
	var blast := 1e6
	if wh is Dictionary and wh.has("blast"):
		var tb := float(wh["blast"])
		var tr0 := float(wh.get("rewind", 1e9))
		var ts := float(wh.get("switch", 1e9))
		if t < ts:
			scene = 0.0
			if t >= tr0:
				var k := clampf((t - tr0) / maxf(ts - tr0, 0.05), 0.0, 1.0)
				ft = lerpf(tr0, tb - 0.4, Motion.in_cubic(k))
				rew = clampf((t - tr0) / 0.12, 0.0, 1.0)
			blast = tb if ft >= tb else 1e6
		else:
			rew = 1.0 - clampf((t - ts) / 0.3, 0.0, 1.0)
		glitch = exp(-pow((t - ts) / 0.12, 2.0))
	if scene > 0.5:
		for bt in _p.get("blast", []):
			if float(bt) <= t:
				blast = float(bt) if blast > 1e5 else maxf(blast, float(bt))
	var stamp_text := ""
	var flicker := 1.0
	var rw = _p.get("rewind", {})
	if rw is Dictionary and rw.has("from"):
		var a := float(rw["from"])
		var b := float(rw.get("until", a + 1.5))
		var r2 := clampf((t - a) / 0.25, 0.0, 1.0) * (1.0 - clampf((t - b) / 0.25, 0.0, 1.0))
		rew = maxf(rew, r2)
		if t >= a:
			# The tape runs back: slow at first, then a blur of days; it brakes into the landing month.
			var k := clampf((t - a) / maxf(b - a, 0.1), 0.0, 1.0)
			var e := Motion.in_out(k)
			var days := e * 880.0       # 11 May 1998 back to mid-December 1995
			# The picture runs backwards (the pass drifts back across the crosshair), then plays on from the landing.
			ft = lerpf(a, a - 7.0, e) + maxf(t - b, 0.0)
			var unix := 894844800 - int(days * 86400.0)     # 1998-05-11 00:00 UTC
			var dt := Time.get_datetime_dict_from_unix_time(unix)
			var months := ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
			if k < 1.0:
				stamp_text = "%02d %s %d" % [dt["day"], months[int(dt["month"]) - 1], dt["year"]]
			else:
				stamp_text = String(rw.get("to", "DEC 1995"))
			# Day-night flicker while the days strobe past; steady once it lands.
			flicker = 1.0 - 0.45 * r2 * (0.5 + 0.5 * sin(t * 57.0)) * smoothstep(0.05, 0.3, k) * (1.0 - smoothstep(0.85, 1.0, k))
	var loopd = _p.get("loop", {})
	if loopd is Dictionary and loopd.has("from") and t >= float(loopd["from"]):
		scene = 0.0
		ft = t - float(loopd.get("end", t))
		blast = 1e6
		rew = 0.0
		glitch = exp(-pow((t - float(loopd["from"])) / 0.12, 2.0))
		stamp_text = ""
		flicker = 1.0
	_feed_mat.set_shader_parameter("t", ft)
	_feed_mat.set_shader_parameter("tr", t)
	_feed_mat.set_shader_parameter("blast", blast)
	_feed_mat.set_shader_parameter("rewind", rew)
	_feed_mat.set_shader_parameter("scene", scene)
	_feed_mat.set_shader_parameter("glitch", glitch)
	_feed_mat.set_shader_parameter("energy", 0.62 * flicker)
	var secs := int(fposmod(floor(ft), 60.0))
	_stamp.pixel_size = _stamp_px
	_stamp.modulate = _stamp_mod
	if stamp_text != "":
		_stamp.text = stamp_text
		var rb := float((rw as Dictionary).get("until", 0.0))
		if t >= rb:
			# The landing: the date pops a little bigger and brighter, then settles (a counter landing).
			var age := t - rb
			_stamp.pixel_size = _stamp_px * (1.18 + 0.35 * exp(-age * 9.0) * cos(age * 18.0))
			_stamp.modulate = _stamp_mod * Color(1.6, 1.6, 1.6, 1.0)
	else:
		_stamp.text = "%s  10:15:%02dZ" % [String(_p.get("stamp", "11 MAY 1998")), secs]
	_coord.text = "38 53N  077 02W" if scene < 0.5 else "27 05N  071 45E"
	# The fluorescent tube's faint flicker (a dying starter).
	var fl := 0.92 + 0.08 * sin(t * 47.0) * sin(t * 3.1)
	if fmod(t * 0.7, 5.0) < 0.06:
		fl = 0.55
	_fluoro_light.light_energy = 0.9 * fl
	# Steam.
	for sm in _steam:
		(sm as ShaderMaterial).set_shader_parameter("t", t)
	# The snow globe: an elbow knock tips it; the snow swirls up and settles.
	var knock := float(_p.get("knock", 1e9))
	var slam := _pose_report(gt, t, ctx)
	var spill := float(_p.get("spill", 1e9))
	var ks := t - spill
	if _mug != null:
		if ks >= 0.0:
			var tip := Motion.out_bounce(clampf(ks / 0.35, 0.0, 1.0))
			_mug.rotation = Vector3(0.0, 0.4, -1.5 * tip)
			_mug.position = MUG_AT + Vector3(0.06 * tip, 0.04 * tip, 0.0)
			_spill.visible = ks > 0.12
			var r := 0.03 + 0.17 * (1.0 - exp(-(ks - 0.12) * 2.5))
			_spill.scale = Vector3(r * 1.3, 1.0, r)
		else:
			_mug.rotation = Vector3.ZERO
			_mug.position = MUG_AT
			_spill.visible = false
	if slam >= 0.0 and slam < 4.0:
		knock = t - slam
	var dk := t - knock
	var tip := 0.0
	if dk > 0.0:
		tip = 0.22 * Motion.wobble(dk, 3.5, 4.5)
	_globe.rotation = Vector3(tip, 0, tip * 0.4)
	var mm := _globe_snow.multimesh
	var r := Kit.rng("snow")
	for i in mm.instance_count:
		var a := r.randf() * TAU
		var rad := sqrt(r.randf()) * 0.04
		var rest := Vector3(cos(a) * rad, 0.044 + r.randf() * 0.004, sin(a) * rad)
		var swirl := 0.0
		if dk > 0.0:
			swirl = exp(-dk * 0.45) * clampf(dk * 4.0, 0.0, 1.0)
		var ph := r.randf() * TAU + t * (1.2 + r.randf())
		var lift := r.randf() * 0.07
		var up := Vector3(cos(ph) * rad * 1.1, 0.05 + lift * (0.5 + 0.5 * sin(ph * 0.7)), sin(ph) * rad * 1.1)
		mm.set_instance_transform(i, Transform3D(Basis(), rest.lerp(up, swirl)))
	# The wall TV: off until `on`, then the live SubViewport picture of the camera given in params.
	var tv = _p.get("tv", {})
	var glow := node.find_child("tv_glow", true, false) as OmniLight3D
	if tv is Dictionary and tv.has("on"):
		var on := t - float(tv["on"])
		_tv_mat.set_shader_parameter("on", on)
		_tv_mat.set_shader_parameter("t", t)
		_tv_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS if on > -0.5 else SubViewport.UPDATE_DISABLED
		var feed := [tv.get("cam"), tv.get("look"), tv.get("fov", 30.0), {}]
		for f in tv.get("feeds", []):
			if t >= float(f[0]):
				feed = [f[1], f[2], f[3], f[4] if (f as Array).size() > 4 else {}]
		var env := _tv_cam.environment
		var fe: Dictionary = feed[3]
		env.background_color = Color(String(fe.get("bg", "#1f1a1f")))
		env.ambient_light_energy = float(fe.get("ambient", 0.5))
		env.ambient_light_color = Color(String(fe.get("ambient_color", "#8c807a")))
		if feed[0] != null and feed[1] != null:
			var cp: Dictionary = ctx["point"].call(feed[0])
			var lp: Dictionary = ctx["point"].call(feed[1])
			if cp.has("pos") and lp.has("pos"):
				_tv_cam.global_position = cp["pos"]
				_tv_cam.look_at(lp["pos"], Vector3.UP)
			_tv_cam.fov = float(feed[2])
		if glow:
			glow.light_energy = 0.6 * clampf(on / 0.2, 0.0, 1.0) * (0.9 + 0.1 * sin(t * 9.0))
	elif glow:
		glow.light_energy = 0.0
	_pose_live(t, ctx)
	var prints_at := _pose_prints(gt, t, ctx)
	return {"screen": gt * SCREEN, "tv": gt * TV_AT, "globe": gt * (GLOBE_AT + Vector3(0, 0.08, 0)),
			"prints": gt * prints_at, "mug": gt * MUG_AT, "desk": gt * Vector3(0, DESK_TOP, -1.6), "chair": gt * (_chair_top.position + Vector3(0, 0.02, 0)),
			"window": gt * Vector3(-ROOM.x * 0.5, 1.45, 0.35)}
