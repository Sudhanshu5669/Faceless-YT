extends RefCounted
## The Pokhran field firing range, Thar desert (Jaisalmer district), May 1998.
##
## Not dunes everywhere: a flat, pale, gravelly plain of buff sand with sewan-grass tufts, ker bushes and
## khejri trees, low dunes rising far off in heat haze. At the origin, the shaft code-named "White House": a
## concrete collar with a bolted steel plate, a steel tripod over it with a sheave and a hook block, a diesel
## winch on a skid behind a low sandbag wall, a spoil heap, crates, jerrycans and a cable reel. An army camp
## (olive ridge tents) stands off to the north-west, a windsock to the north-east. A truck track with two
## tyre ruts curves past in front of the shaft. Heat shimmer bends everything beyond ~35 m.
##
## Local frame: the White House plate centre is the origin, ground y 0 there; +z is "south" (where cameras
## usually stand, looking -z). The terrain height anywhere is height(x, z) (the same function in the shader).
## Plants, rocks and props sit on it.
##
## Assets: khejri, ker, sewan grass and sandbags from episodes/pokhran/blender/range_assets.py
## (incoming/pokhran_blender/); ground textures and crates/jerrycans from Poly Haven (CC0,
## incoming/polyhaven_pokhran/).
##
## params:
##   carry      [{"actor": id, "what": "sandbag" | "jerrycans"}, ...]   sandbag: hugged in both hands (gait
##              walk_carry), riding between the hands; jerrycans: one hanging from each hand (gait walk), upright
##              under the grip with a little lag
##   wind       [[t, yaw_deg, strength], ...]   the windsock's heading (degrees, 0 = blowing toward -z) and
##              strength 0..1 over time (default [[0, 120, 0.55]])
##   shimmer    0..1   heat-haze strength (default 1; 0 at night)
##   tufts      [[x, z, scale], ...]   hero grass tufts placed for a camera (foreground framing)
##   bushes     [[x, z, scale, yaw], ...]   hero ker bushes
##   clear      [[x, z, radius], ...]   keep the scattered plants and stones out of these circles (camera spots)
##   y1995      [[t0, t1], ...]   December 1995 instead of May 1998: the shaft is open (no plate, no tripod), a crane
##              truck on outriggers lowers a section of steel casing into it, trucks stand in the open, a pipe stack
##   lower      {"from": t, "to": t}   the crane lowers the casing into the shaft (1995)
##   leave      {"from": t, "truck": i}   a parked 1995 truck pulls away (eases off, gathers speed) in its own dust
##   piles      [[x, z, r], ...]   loose spoil spread beside the collar (1995)
##   shovel     [{"actor": id, "phase": s, "period": s}, ...]   the actor shovels the spoil back into the open shaft:
##              dig into the heap, lift, swing and throw (the sand flies in an arc into the shaft), back
##   drip       t   the shaft leaks: drops fall from the bore's lip and the roof on their own rhythms (onto the lid or into
##              the floor puddles); the hero drop lands on the canister's lid at t
##   dive       {"from": t, "to": t, "y1": -188}   the camera's fall down the shaft: anchors dive_cam / dive_look /
##              dive_count follow it (from just under the plate down the bore, circling the cable bundle,
##              accelerating, easing out near the bottom); a lamp travels with it
##   night      {"on": [[t0, t1], ...], "lamp": [x, z], "torch": [actor ids]}   work at night (only inside the
##              windows): a work lamp on a pole, its bulb under a tin shade throwing a warm cone straight down; each
##              torch actor holds a hand torch whose cool beam runs from the right hand along their facing, tipped down,
##              sweeping slowly over the ground
##   park       {"at": [x, z, yaw_deg], "from": t, "to": t, "back": 6.0, "actor": id}   1998: a canopy truck reverses
##              `back` metres into its parking spot, slowing to a stop exactly at `to` (a brake dip and settle), its
##              wheels turning; its own old tyre ruts and rear-wheel imprints are pressed into the sand there; the
##              actor marshals it in, palm raised to stop it
##   dune       {"at": [x, z, yaw_deg], "shape": [t0, t1], "blow": t, "hands": [actor ids], "blower": id}   1998: a heap
##              of dug sand patted by hand into a crescent (barchan) dune between t0 and t1 (the hands' actors pat it,
##              crouched, two-handed); at `blow` the blower leans in and blows, and fine wind ripples spread across the
##              windward slope from his lips. The dune's local +z is the wind's way (windward slope toward -z);
##              "scale" sizes it (1 = 4.6 m across, 0.82 m high)
##   net        {"at": [x, z, yaw_deg], "size": [w, d], "land": t, "fly": 1.6, "hands": [id, id]}   1998: a second
##              shaft head (collar and plate, no tripod) ringed by net poles; the two actors fling a garnished
##              camouflage net from its near edge (net-local -z): it unfurls in an arc, the middle billowing, leading edge
##              first, and settles over the poles (a low, broken canopy) at `land`, bouncing a little
##   watch      {"actor": id, "fist": t, "time": "13:47", "list": ["09:12", ...]}   a lookout: a wristwatch on his
##              left wrist and a handwritten list of satellite pass times in that hand, held up before his face; the
##              watch reads `time` exactly at `fist` (its second hand sweeping), when his right fist shoots up
##   chai       [actor ids]   each holds a small glass of milky tea in the right hand
##   cricket    {"bat": id, "bowl": id, "release": t, "hit": t, "stumps": [x, z]}   gully cricket: tent-peg stumps behind
##              the batsman; the ball sits in the bowler's right hand until `release`, bounces once on the way, meets
##              the bat (swung from the backlift through the hit on `hit`) and is lofted back over the bowler's head
##   jeep       {"at": [x, z, yaw_deg], "stop": t, "speed": 15, "slide": 70, "driver": id, "slip": {"actor": id, "t": t}}
##              a light army jeep tears in across the desert (bouncing on the ruts, a hop off a hump 7.5 m out, a plume of dust) and
##              handbrake-slides `slide` degrees into its parked pose at `at`, stopping dead at `stop` in a burst of dust;
##              the driver rides in the right-hand seat, "riders" [[id, fwd, side], ...] sit elsewhere (side + = right);
##              at slip.t the actor's oversized patrol cap slides over his eyes
##   disguise   [{"actor": id, "cap": true, "tape": "NAME", "off": t}]   dress an actor for the field: an army patrol cap
##              perched on top of their own hair (it escapes all round), a name tape over the right chest pocket; at `off`
##              the right hand lifts the cap off and holds it out to the side, and the hair springs up free
##   convoy     {"on": [[t0, t1]], "t0": t, "start": [x, z], "heading": deg, "speed": 9, "n": 4, "gap": 16, "carry": 1,
##              "cam0": [x, y, z], "look0": [...], "cam1": [...], "look1": [...], "lining_until": t}   an army convoy of canopy trucks rolling
##              across the desert in their dust (truck i is i*gap behind the lead); truck `carry` holds the device on
##              its cradle inside a ribbed lining (the canvas's inside, the rear flap closed, a warm work light): the same
##              picture as the An-32's hold (gags/flight.gd), for a match cut. Anchors convoy_cam0/look0/cam1/look1 are
##              those points in the carrying truck's own frame (+x forward, +y up, +z its right), moving with it
##   lowering   {"on": [[t0, t1]], "down": t, "shafts": [[x, z, yaw, [flood_x, flood_z], down_t], ...], "trucks": [[x, z, yaw]]}
##              night: three shaft heads, each with an open collar, a 6 m tripod, a steel cage carrying a device stood on
##              end, lowered steadily (it passes the collar at its down_t, or `down`), and a sodium floodlight on a pole
##              (position in the rig's frame); trucks parked with their headlights on
##   blast      {"t": t, "at": [x, z], "h": 30, "r": 130, "shock": 450, "ring_to": 1600, "toward": [x, z], "on": [[t0, t1]],
##              "post": {"at": [x, z], "face": [x, z]}}   the underground test, at massive scale (accurate: no fireball, no
##              mushroom cloud): at t the crust heaves up into a dome (h m high, radius r) that breaks into ~9 m slabs with
##              black fissures between them (GPU, in the ground's height), sand jets spurt from the cracks, a towering
##              column of dust climbs hundreds of metres, rocks fly out on ballistic arcs, a base surge rolls outward along
##              the ground, and the shock races across the plain at `shock` m/s raising a ring of dust (denser in the
##              `toward` direction, the camera's side) out to `ring_to`; from ~3 s the dome slumps into a crater. `post`:
##              an observation post (a parked truck) shown only inside the windows. A window [t0, t1, t_blast] replays the
##              blast from t_blast instead of t (the same moment from another angle, like news footage). The 1998 site gear
##              and the heat-haze ring are hidden inside the windows
##   relic      {"at": [x, z], "yaw": deg, "on": [[t0, t1]], "lines": ["WHITE", "HOUSE"]}   after the test: the White
##              House shaft's steel plate lying blown out and bent on the crater's rim, half sunk in the sand, the chalk
##              still on it
##   goggles    {"actor": id, "on": [[t0, t1]], "looks": [[x, y, z], [x, y, z]], "fov": 40, "r": 0.26}   safety goggles on
##              the actor's face (a rubber strap round the head, two round lenses in black cups); each lens mirrors a live
##              view from that eye toward its `looks` point (a SubViewport, flipped like a reflection, tinted, over the
##              faint eye behind it): aimed either side of the site, the lenses show the blast twice
##   village_far {"at": [x, z], "on": [[t0, t1], ...], "n": 9}   Khetolai on the horizon (only inside the windows): a
##              cluster of round mud huts with thatched cones inside a low mud wall, khejri trees, two threads of cooking
##              smoke rising: the village the wind must not blow toward (dramatised much closer than its real ~5 km)
## The shaft: a 205 m steel-cased bore (1.8 m) under the plate, the firing-cable bundle hanging down its axis
## with clamps, a work lamp glowing at the bottom. No sky light reaches inside (ambient off).
## anchors: plate, apex, winch, spoil, tree, camp, windsock, track, jeep (its cab), dive_cam, dive_look, dive_count, dive_face
## (the counter's facing point: along the camera's view axis, so it stays parallel to the image), bottom

const Kit = preload("res://scripts/world/gag_kit.gd")
const Crawl = preload("res://scripts/actors/toon_crawl.gd")
const Motion = preload("res://scripts/timeline/motion.gd")

const PB := "incoming/pokhran_blender/"
const PH := "incoming/polyhaven_pokhran/"
const TX := "incoming/polyhaven_pokhran/textures/"

const PAD_R := 6.0                       # the scraped pad round the shaft
const TRIPOD_H := 5.2
const WINCH_AT := Vector3(3.1, 0.0, -2.6)
const SPOIL_AT := Vector3(-4.6, 0.0, 1.4)
const TREE_AT := Vector3(-10.2, 0.0, -8.4)
const SOCK_AT := Vector3(-7.6, 0.0, -23.6)
const SOCK_H := 6.2
const SHAFT_R := 0.9
const SHAFT_D := 205.0
const CHAMBER_R := 2.0          # the chamber mined out at the bottom of the shaft
const CHAMBER_H := 3.2
const CAN_R := 0.42             # the sealed canister (in its lowering cage) under the bore
const CAN_H := 1.5
const LAMP_AT := Vector3(-0.42, -SHAFT_D + 2.3, 0.8)
const CAMP := [Vector3(-10.0, 0, -29.2), Vector3(-9.7, 0, -36.4), Vector3(-3.3, 0, -34.6), Vector3(-17.8, 0, -36.1)]

## Terrain height (metres) at local (x, z). Mirrors height() in GROUND.
static var post_pad := Vector4(0.0, 0.0, 0.0, 0.0)   # x, z, height, on: a flat pad for the observation post


static func height(x: float, z: float) -> float:
	var raw := _height_raw(x, z)
	if post_pad.w < 0.5:
		return raw
	var k := smoothstep(60.0, 120.0, Vector2(x - post_pad.x, z - post_pad.y).length())
	return lerpf(post_pad.z, raw, k)


static func _height_raw(x: float, z: float) -> float:
	var h := 0.22 * sin(0.11 * x + 0.7) * cos(0.083 * z + 1.3) + 0.12 * sin(0.23 * x - 0.17 * z + 2.1)
	h += 0.05 * sin(0.47 * x + 0.31 * z) + 0.025 * sin(1.3 * x - 0.9 * z + 0.4)
	var d := sqrt(x * x + z * z)
	var far := smoothstep(90.0, 420.0, d)
	var dn := 0.5 + 0.5 * sin(0.021 * x + 1.7 * sin(0.006 * z) + 0.3)
	h += far * (5.0 * dn * dn * dn + 2.0 * sin(0.013 * z + 0.9) * sin(0.017 * x))
	h += smoothstep(700.0, 2200.0, d) * (16.0 + 10.0 * sin(0.004 * x + 2.0) * sin(0.0031 * z))
	var k := smoothstep(PAD_R, PAD_R * 2.2, d)
	h = lerpf(-0.02, h - 0.0, k)
	h += _ruts(x, z)
	return h


static func _track_z(x: float) -> float:
	return 5.6 + 4.0 * sin(x * 0.04 + 0.5)


static func _ruts(x: float, z: float) -> float:
	var dz := absf(z - _track_z(x))
	var on := 1.0 - smoothstep(60.0, 90.0, absf(x))
	var g := -0.05 * exp(-pow((dz - 0.85) / 0.15, 2.0)) + 0.012 * exp(-pow(dz / 0.35, 2.0))
	return g * on


static func ground(x: float, z: float) -> Vector3:
	return Vector3(x, height(x, z), z)


const HEIGHT_GLSL := """
uniform float now = 0.0;
uniform vec4 blast = vec4(0.0, 0.0, 1e9, 0.0);   // centre x, z; t0; on
uniform vec3 blast_hr = vec3(30.0, 130.0, 450.0);  // dome height, dome radius, shock speed (m/s)
vec2 bl_hash2(vec2 p) { p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3))); return fract(sin(p) * 43758.5453); }
// Voronoi: x = distance to the nearest cell edge (F2 - F1), yz = the nearest cell's centre (in cell units).
vec3 bl_vor(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	vec2 c1 = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = bl_hash2(i + g);
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < d1) { d2 = d1; d1 = d; c1 = i + g + o; } else if (d < d2) { d2 = d; }
		}
	}
	return vec3(sqrt(d2) - sqrt(d1), c1);
}
float bl_rise(float s) { return 1.0 - pow(1.0 - clamp(s / 0.5, 0.0, 1.0), 3.0); }
float blast_h(vec2 p) {
	if (blast.w < 0.5) return 0.0;
	float s = now - blast.z;
	if (s < 0.0) return 0.0;
	vec2 q = p - blast.xy;
	float d = length(q);
	float H = blast_hr.x;
	float R = blast_hr.y;
	float slump = smoothstep(3.0, 8.0, s);
	float wob = 1.0 + 0.05 * sin(s * 9.0) * exp(-s * 2.0);
	// The heave breaks the crust into slabs (Voronoi cells about 9 m): each lifts by the dome's height at its centre,
	// tilted down the dome's flank, so the edges step: a broken, heaving skin.
	vec3 v = bl_vor(q / 9.0);
	vec2 cc = v.yz * 9.0;
	float dc = length(cc);
	float prof = exp(-pow(dc / R, 2.0));
	float jit = 0.85 + 0.3 * bl_hash2(v.yz).x;
	float rs = bl_rise(s - dc / 1200.0);
	float lift = H * prof * jit * rs * wob;
	vec2 dir = dc > 0.01 ? cc / dc : vec2(0.0);
	lift += dot(q - cc, dir) * (-2.0 * H * dc / (R * R)) * prof * rs * 0.9;
	// Fissures open between the slabs.
	float fis = (1.0 - smoothstep(0.0, 0.08, v.x)) * smoothstep(0.03, 0.25, prof) * rs * (1.0 - slump);
	lift -= fis * 2.5;
	// The slump: a subsidence crater with a sharp raised rim of thrown-out earth.
	float crater = -0.3 * H * (1.0 - smoothstep(R * 0.3, R * 0.5, d)) + 0.12 * H * exp(-pow((d - R * 0.52) / (R * 0.07), 2.0));
	float dome = mix(lift, crater, slump);
	// The shock ring racing out across the plain.
	float rr = s * blast_hr.z;
	float ring = 1.8 * exp(-pow((d - rr) / 16.0, 2.0)) * exp(-s * 0.45) * smoothstep(R * 0.8, R * 1.4, d);
	return dome + ring;
}
float blast_fis(vec2 p) {
	if (blast.w < 0.5) return 0.0;
	float s = now - blast.z;
	if (s < 0.0) return 0.0;
	vec3 v = bl_vor((p - blast.xy) / 9.0);
	float prof = exp(-pow(length(v.yz * 9.0) / blast_hr.y, 2.0));
	return (1.0 - smoothstep(0.0, 0.06, v.x)) * smoothstep(0.03, 0.25, prof) * bl_rise(s) * (1.0 - smoothstep(3.0, 8.0, s));
}
float track_z(float x) { return 5.6 + 4.0 * sin(x * 0.04 + 0.5); }
float ruts(vec2 p) {
	float dz = abs(p.y - track_z(p.x));
	float on = 1.0 - smoothstep(60.0, 90.0, abs(p.x));
	return (-0.05 * exp(-pow((dz - 0.85) / 0.15, 2.0)) + 0.012 * exp(-pow(dz / 0.35, 2.0))) * on;
}
uniform vec4 post_pad = vec4(0.0);
float height_raw(vec2 p) {
	float x = p.x, z = p.y;
	float h = 0.22 * sin(0.11 * x + 0.7) * cos(0.083 * z + 1.3) + 0.12 * sin(0.23 * x - 0.17 * z + 2.1);
	h += 0.05 * sin(0.47 * x + 0.31 * z) + 0.025 * sin(1.3 * x - 0.9 * z + 0.4);
	float d = length(p);
	float far = smoothstep(90.0, 420.0, d);
	float dn = 0.5 + 0.5 * sin(0.021 * x + 1.7 * sin(0.006 * z) + 0.3);
	h += far * (5.0 * dn * dn * dn + 2.0 * sin(0.013 * z + 0.9) * sin(0.017 * x));
	h += smoothstep(700.0, 2200.0, d) * (16.0 + 10.0 * sin(0.004 * x + 2.0) * sin(0.0031 * z));
	float k = smoothstep(PAD_R, PAD_R * 2.2, d);
	h = mix(-0.02, h, k);
	return h + ruts(p) + blast_h(p);
}
float height(vec2 p) {
	float raw = height_raw(p);
	if (post_pad.w < 0.5) return raw;
	return mix(post_pad.z, raw, smoothstep(60.0, 120.0, length(p - post_pad.xy)));
}
"""

## The desert floor: gravelly buff sand (two Poly Haven sand textures, anti-tiled and graded toward the
## Thar's pale ochre), trampled sand with footprints on the pad and along the track, darker compacted ruts,
## pale wind-blown sand in the hollows, broad tone patches that read from far off.
const GROUND := """
shader_type spatial;
render_mode skip_vertex_transform;
uniform sampler2D a_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D a_nor : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D b_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D b_nor : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D s_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D s_nor : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint = vec3(1.0);
varying vec3 lp;
//NOISE
//HEIGHT
void vertex() {
	vec2 p = VERTEX.xz;
	float h = height(p);
	float e = 0.12 * max(1.0, length(p) * 0.02);
	float hx = height(p + vec2(e, 0.0)) - height(p - vec2(e, 0.0));
	float hz = height(p + vec2(0.0, e)) - height(p - vec2(0.0, e));
	VERTEX.y = h;
	lp = VERTEX;
	vec3 n = normalize(vec3(-hx, 2.0 * e, -hz));
	vec3 tg = normalize(vec3(1.0, 0.0, 0.0) - n * n.x);
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(n, 0.0)).xyz);
	TANGENT = normalize((MODELVIEW_MATRIX * vec4(tg, 0.0)).xyz);
	BINORMAL = normalize((MODELVIEW_MATRIX * vec4(cross(tg, n), 0.0)).xyz);
}
vec3 tex2(sampler2D s, vec2 uv) {
	// Two samples at unrelated scales and rotations, blended by noise: no visible tiling.
	vec2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * uv * 0.43 + 0.31;
	float m = smoothstep(0.35, 0.65, n3(vec3(uv * 0.21, 3.0)));
	return mix(texture(s, uv).rgb, texture(s, r).rgb, m);
}
void fragment() {
	vec2 p = lp.xz;
	float d = length(p);
	vec2 uv = p * 0.42;
	vec3 a = tex2(a_alb, uv);
	vec3 b = tex2(b_alb, uv * 0.8 + 0.5);
	vec3 s = tex2(s_alb, p * 0.3);
	float mab = smoothstep(0.4, 0.6, fbm(vec3(p * 0.05, 1.0)));
	vec3 col = mix(a, b, mab);
	// Grade the orange-brown gravel toward the Thar's pale buff.
	float l = dot(col, vec3(0.3, 0.55, 0.15));
	col = mix(vec3(l), col, 0.55) * vec3(1.18, 1.04, 0.84) * 1.25;
	// Pale blown sand in hollows and far off; trampled sand (footprints) on the pad and the track.
	float hollow = smoothstep(0.55, 0.75, fbm(vec3(p * 0.09, 4.0)));
	float pad = 1.0 - smoothstep(PAD_R * 0.9, PAD_R * 2.0, d + 2.0 * (fbm(vec3(p * 0.3, 7.0)) - 0.5));
	float tz = abs(p.y - track_z(p.x));
	float trk = (1.0 - smoothstep(1.1, 1.8, tz)) * (1.0 - smoothstep(60.0, 90.0, abs(p.x)));
	float rut = exp(-pow((tz - 0.85) / 0.17, 2.0)) * (1.0 - smoothstep(60.0, 90.0, abs(p.x)));
	vec3 sand = s * vec3(1.12, 1.0, 0.82) * 1.12;
	col = mix(col, sand * 1.08, hollow * 0.55);
	col = mix(col, sand, max(pad, trk * 0.8));
	col *= 1.0 - 0.18 * rut;
	// Broad tone patches (gravel fans, darker crusts) that read at a distance.
	col *= 0.88 + 0.24 * fbm(vec3(p * 0.012, 9.0));
	col *= tint;
	// The blast: the torn crust darker and damper (subsoil turned up), black fissures between the slabs.
	if (blast.w > 0.5 && now > blast.z) {
		float bs = now - blast.z;
		float bprof = exp(-pow(length(p - blast.xy) / blast_hr.y, 2.0));
		col = mix(col, col * vec3(0.72, 0.64, 0.55), bprof * bl_rise(bs));
		col *= 1.0 - 0.9 * blast_fis(p);
	}
	ALBEDO = col;
	vec3 na = mix(texture(a_nor, uv).rgb, texture(b_nor, uv * 0.8 + 0.5).rgb, mab);
	vec3 ns = texture(s_nor, p * 0.3).rgb;
	NORMAL_MAP = mix(na, ns, max(max(pad, trk * 0.8), hollow * 0.55));
	NORMAL_MAP_DEPTH = 1.0 - smoothstep(30.0, 120.0, d) * 0.7;
	ROUGHNESS = 0.96 - 0.12 * rut;
	SPECULAR = 0.3;
}
"""

## Khejri leaflets and grass: vertex colour, wind sway that grows with height, light through the leaves.
const FOLIAGE := """
shader_type spatial;
render_mode cull_disabled;
uniform float t = 0.0;
uniform float wind = 1.0;
uniform float base_h = 1.2;
uniform float span_h = 3.0;
uniform float amp = 0.035;
uniform vec3 tint = vec3(1.0);
uniform float back = 0.55;
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float k = smoothstep(base_h, base_h + span_h, VERTEX.y) * wind;
	VERTEX.x += k * (amp * sin(t * 1.7 + w.x * 0.6 + w.z * 0.35) + amp * 0.35 * sin(t * 5.1 + w.y * 3.1 + w.x * 2.0));
	VERTEX.z += k * amp * 0.8 * sin(t * 1.4 + w.z * 0.7 + 1.0);
	VERTEX.y += k * amp * 0.3 * sin(t * 6.3 + w.x * 3.0);
}
void fragment() {
	vec3 c = COLOR.rgb * tint;
	ALBEDO = c;
	ROUGHNESS = 0.72;
	SPECULAR = 0.3;
	BACKLIGHT = c * vec3(0.95, 1.0, 0.6) * back;
	AO = 0.75 + 0.25 * smoothstep(0.0, 4.0, VERTEX.y);
}
"""

## Bark (khejri, ker): the Blender vertex colour (fissures) over fine noise; dust settles on top surfaces.
const BARK := """
shader_type spatial;
uniform vec3 tint = vec3(1.0);
varying vec3 wp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 c = COLOR.rgb * tint;
	c *= 0.8 + 0.4 * fbm(wp * vec3(40.0, 8.0, 40.0));
	float up = clamp((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y, 0.0, 1.0);
	c = mix(c, vec3(0.62, 0.52, 0.4), smoothstep(0.6, 0.95, up) * 0.45);
	ALBEDO = c;
	ROUGHNESS = 0.95;
	SPECULAR = 0.25;
}
"""

## Hessian sandbags: a coarse weave in object space, dusty, darker where they touch the ground.
const HESSIAN := """
shader_type spatial;
varying vec3 lp;
varying vec3 wp;
//NOISE
void vertex() { lp = VERTEX; wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 base = vec3(0.34, 0.27, 0.17);
	float wv = sin(lp.x * 700.0) * sin(lp.z * 700.0 + lp.y * 300.0);
	float fade = 1.0 - smoothstep(0.0, 0.004, fwidth(lp.x * 700.0) * 0.001);
	vec3 c = base * (0.9 + 0.08 * wv * fade);
	c *= 0.82 + 0.3 * fbm(wp * 3.0);
	c = mix(c, vec3(0.7, 0.6, 0.45), smoothstep(0.08, 0.14, lp.y) * 0.35);
	c *= 0.75 + 0.25 * smoothstep(0.0, 0.05, lp.y);
	ALBEDO = c;
	ROUGHNESS = 0.98;
	SPECULAR = 0.2;
}
"""

## Cast concrete: beige-grey with form lines, stains and chipped corners; sand lies on the top faces.
const CONCRETE := """
shader_type spatial;
varying vec3 wp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 c = vec3(0.33, 0.31, 0.28);
	c *= 0.85 + 0.25 * fbm(wp * 2.5);
	c *= 0.93 + 0.14 * h3(floor(wp * 220.0));
	c = mix(c, c * 0.62, smoothstep(0.62, 0.8, fbm(wp * vec3(1.0, 6.0, 1.0) + 3.0)) * 0.5);
	float up = clamp((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y, 0.0, 1.0);
	c = mix(c, vec3(0.6, 0.5, 0.37), smoothstep(0.7, 1.0, up) * smoothstep(0.35, 0.7, fbm(wp * 4.0 + 1.0)) * 0.7);
	ALBEDO = c;
	ROUGHNESS = 0.92;
	SPECULAR = 0.3;
}
"""

## Shaft casing from inside: dark steel with vertical rust runs and wet streaks, a welded joint every 12 m,
## no sky light (the only light down here is a lamp).
const BORE := """
shader_type spatial;
render_mode ambient_light_disabled, cull_disabled;
varying vec3 wp;
varying vec3 lp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; lp = VERTEX; }
void fragment() {
	float a = atan(lp.z, lp.x);
	vec3 q = vec3(a * 1.6, lp.y * 0.12, 0.0);
	vec3 c = vec3(0.1, 0.095, 0.09) * (0.75 + 0.5 * fbm(vec3(a * 5.0, lp.y * 0.8, 1.0)));
	float runs = smoothstep(0.55, 0.8, fbm(vec3(a * 9.0, lp.y * 0.08, 3.0)));
	c = mix(c, vec3(0.26, 0.12, 0.05), runs * 0.75);
	float joint = 1.0 - smoothstep(0.0, 0.05, abs(fract(lp.y / 12.0) - 0.5) - 0.0);
	c = mix(c, vec3(0.42, 0.4, 0.37), joint);
	ALBEDO = c;
	ROUGHNESS = mix(0.5, 0.85, runs);
	SPECULAR = 0.55;
}
"""

## Damp rock in the chamber: dark sandstone and shale bands, wet sheen in the hollows, no sky light.
const ROCK := """
shader_type spatial;
render_mode ambient_light_disabled, cull_disabled;
uniform float wet = 0.0;
varying vec3 wp;
//NOISE
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX += NORMAL * (fbm(w * 2.2) - 0.5) * 0.05;
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float band = sin(wp.y * 7.0 + fbm(wp * 1.5) * 5.0) * 0.5 + 0.5;
	vec3 c = mix(vec3(0.2, 0.15, 0.11), vec3(0.32, 0.25, 0.18), band);
	c *= 0.7 + 0.5 * fbm(wp * 6.0);
	float damp = smoothstep(0.45, 0.7, fbm(wp * 1.2 + 4.0));
	float pud = wet * smoothstep(0.55, 0.62, fbm(vec3(wp.xz * 0.9, 2.0)));
	c *= 1.0 - 0.35 * max(damp, pud);
	ALBEDO = c;
	ROUGHNESS = mix(0.9, 0.18, max(damp * 0.7, pud));
	SPECULAR = mix(0.3, 0.7, max(damp, pud));
	NORMAL_MAP = vec3(0.5 + 0.35 * (fbm(wp * 14.0) - 0.5), 0.5 + 0.35 * (fbm(wp * 14.0 + 3.0) - 0.5), 1.0);
	NORMAL_MAP_DEPTH = 1.0 - pud;
}
"""

## Heavy steel plate: dark mill scale, rust bleeding from the bolt line and edges, scuffs to bright steel,
## sand in the low spots. Slightly metallic so it picks up the sky.
const STEEL := """
shader_type spatial;
uniform float rust = 1.0;
varying vec3 wp;
varying vec3 lp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; lp = VERTEX; }
void fragment() {
	vec3 c = vec3(0.2, 0.2, 0.21) * (0.85 + 0.3 * fbm(wp * 6.0));
	float r = smoothstep(0.5, 0.75, fbm(wp * 1.6 + vec3(0.0, 0.0, 2.0))) * rust;
	vec3 rc = mix(vec3(0.36, 0.16, 0.07), vec3(0.55, 0.28, 0.12), fbm(wp * 9.0));
	c = mix(c, rc, r);
	float scuff = smoothstep(0.72, 0.85, fbm(wp * vec3(14.0, 2.0, 30.0)));
	c = mix(c, vec3(0.5, 0.5, 0.5), scuff * 0.5);
	float up = clamp((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y, 0.0, 1.0);
	float dust = smoothstep(0.55, 0.8, fbm(wp * 3.0 + 5.0)) * smoothstep(0.7, 1.0, up);
	c = mix(c, vec3(0.56, 0.47, 0.35), dust * 0.5);
	ALBEDO = c;
	METALLIC = 0.35 * (1.0 - r) * (1.0 - dust);
	ROUGHNESS = mix(0.62, 0.92, max(r, dust));
	SPECULAR = 0.5;
}
"""

## Army olive paint on steel: faded on top, chipped to bare and rusty steel, dust on the upper faces.
const OLIVE := """
shader_type spatial;
uniform vec3 paint = vec3(0.25, 0.26, 0.15);
varying vec3 wp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float up = clamp((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y, 0.0, 1.0);
	vec3 c = paint * (0.85 + 0.25 * fbm(wp * 3.0));
	c = mix(c, c * 1.35 + vec3(0.04, 0.03, 0.0), up * 0.5);
	float chip = smoothstep(0.7, 0.78, fbm(wp * 18.0));
	c = mix(c, mix(vec3(0.3, 0.3, 0.3), vec3(0.4, 0.2, 0.09), fbm(wp * 30.0)), chip);
	c = mix(c, vec3(0.7, 0.6, 0.45), smoothstep(0.75, 1.0, up) * smoothstep(0.4, 0.7, fbm(wp * 5.0)) * 0.6);
	ALBEDO = c;
	ROUGHNESS = mix(0.7, 0.5, chip);
	SPECULAR = 0.45;
	METALLIC = chip * 0.4;
}
"""

## Tent canvas: olive-khaki duck with a weave, sun-bleached on top, dusty and darker at the hem.
const CANVAS := """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 cloth = vec3(0.36, 0.35, 0.22);
varying vec3 wp;
varying vec3 lp;
//NOISE
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; lp = VERTEX; }
void fragment() {
	vec3 c = cloth * (0.85 + 0.25 * fbm(wp * 1.5));
	float up = clamp((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y, 0.0, 1.0);
	c = mix(c, c * 1.15 + vec3(0.02, 0.02, 0.0), up * 0.4);
	c = mix(c, vec3(0.55, 0.47, 0.34), (1.0 - smoothstep(0.0, 0.5, lp.y)) * 0.6);
	c *= 0.95 + 0.05 * sin(wp.x * 400.0) * sin(wp.y * 400.0);
	ALBEDO = c;
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
	BACKLIGHT = c * 0.25;
}
"""

## Steel cable: dark, greasy, a twisted-strand highlight.
const CABLE := """
shader_type spatial;
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	float s = sin((lp.y + atan(lp.x, lp.z) * 0.004) * 1600.0);
	ALBEDO = vec3(0.12, 0.12, 0.12) * (0.8 + 0.2 * s);
	METALLIC = 0.7;
	ROUGHNESS = 0.4;
}
"""

## The windsock: a cone of bands bent by the wind and fluttering. Local +x runs from the ring to the tail.
const SOCK := """
shader_type spatial;
render_mode cull_disabled;
uniform float t = 0.0;
uniform float strength = 0.6;
uniform float length_m = 1.9;
varying float u;
void vertex() {
	u = clamp(VERTEX.x / length_m, 0.0, 1.0);
	float sag = (1.0 - strength) * 1.1 * u * u;
	VERTEX.y -= sag * length_m * 0.7;
	VERTEX.x -= sag * length_m * 0.35 * u;
	float fl = u * u * (0.25 + 0.75 * strength);
	VERTEX.y += fl * 0.07 * sin(t * 11.0 - u * 7.0);
	VERTEX.z += fl * 0.09 * sin(t * 8.3 - u * 5.0 + 1.3);
	VERTEX *= vec3(1.0, 1.0 + 0.05 * fl * sin(t * 15.0 - u * 9.0), 1.0);
}
void fragment() {
	float band = step(0.5, fract(u * 2.5));
	vec3 c = mix(vec3(0.85, 0.2, 0.08), vec3(0.92, 0.9, 0.86), band);
	c *= 0.85 + 0.15 * u;
	ALBEDO = c;
	ROUGHNESS = 0.8;
	BACKLIGHT = c * 0.5;
}
"""

## Heat shimmer: a ring of screen-space refraction round the site; whatever lies beyond it wobbles, most
## near the ground. Distortion is in pixels (resolution-independent), driven by t.
const SHIMMER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform sampler2D scr : hint_screen_texture, filter_linear_mipmap;
uniform float t = 0.0;
uniform float strength = 1.0;
uniform float top = 7.0;
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	float k = (1.0 - smoothstep(0.0, top, lp.y)) * strength;
	vec2 px = 1.0 / VIEWPORT_SIZE;
	vec2 off = vec2(
		sin(SCREEN_UV.y * 420.0 - t * 7.0 + sin(SCREEN_UV.x * 60.0 + t * 2.3) * 2.0),
		sin(SCREEN_UV.y * 310.0 + SCREEN_UV.x * 90.0 - t * 9.0)) * vec2(1.6, 1.1) * px * (VIEWPORT_SIZE.y / 1080.0) * k;
	ALBEDO = textureLod(scr, SCREEN_UV + off, 0.0).rgb;
}
"""

## Dug sand: paler and lumpier than the plain.
const SPOIL_SHADER := """
shader_type spatial;
uniform sampler2D s_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D s_nor : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 wp;
varying vec3 wn;
//NOISE
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX += NORMAL * ((fbm(w * 1.3) - 0.5) * 0.35 + (n3(w * 7.0) - 0.5) * 0.05);
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	// The same sand as the ground's trampled sand (triplanar), a touch darker and damper where freshly dug.
	vec3 b = pow(abs(wn), vec3(4.0));
	b /= b.x + b.y + b.z;
	vec3 s = texture(s_alb, wp.zy * 0.3).rgb * b.x + texture(s_alb, wp.xz * 0.3).rgb * b.y + texture(s_alb, wp.xy * 0.3).rgb * b.z;
	vec3 c = s * vec3(1.12, 1.0, 0.82) * 1.0;
	c *= 0.78 + 0.22 * smoothstep(0.3, 0.7, fbm(wp * 3.0));
	ALBEDO = c;
	NORMAL_MAP = texture(s_nor, wp.xz * 0.3).rgb;
	ROUGHNESS = 0.97;
	SPECULAR = 0.2;
}
"""

var _p := {}
var _foliage_mats: Array = []
var _sock: MeshInstance3D
var _sock_pivot: Node3D
var _sock_mat: ShaderMaterial
var _shimmer_mat: ShaderMaterial
var _shimmer_node: MeshInstance3D
var _bags := {}
var _hook: Node3D
var _kites_n: Array = []
var _dive_light: OmniLight3D
var _g98: Node3D
var _g95: Node3D
var _crane_hook: Node3D
var _crane_cable: MeshInstance3D
var _crane_tip := Vector3.ZERO
var _clip: Node3D
var _crane_rig: Node3D
var _trucks95: Array = []
var _dust: Array = []
var _shovels: Array = []
var _lamp: Node3D
var _drips: Array = []        # [{"from", "to", "period", "phase", "drop", "ring", "spray": [[node, angle], ...]}]


func build(g: Dictionary) -> Node3D:
	_p = g.get("params", {})
	var root := Node3D.new()
	post_pad = Vector4(0.0, 0.0, 0.0, 0.0)
	var post: Dictionary = (_p.get("blast", {}) as Dictionary).get("post", {})
	if not post.is_empty():
		var px := float(post["at"][0])
		var pz := float(post["at"][1])
		post_pad = Vector4(px, pz, _height_raw(px, pz), 1.0)
	_ground(root)
	_g98 = Node3D.new()
	_g98.name = "era_1998"
	root.add_child(_g98)
	_g95 = Node3D.new()
	_g95.name = "era_1995"
	_g95.visible = false
	root.add_child(_g95)
	_shaft(root)
	_bore(root)
	_tripod(_g98)
	_y1995(_g95)
	_winch(root)
	_spoil(root)
	_props(root)
	_camp(root)
	_windsock(root)
	_vegetation(root)
	_shimmer(root)
	_kites(root)
	_night_build(root)
	_park_build(_g98)
	_dune_build(_g98)
	_net_build(_g98)
	_watch_build(root)
	_convoy_build(root)
	_lowering_build(root)
	_cricket_build(root)
	_village_far_build(root)
	_goggles_build(root)
	_relic_build(root)
	_blast_build(root)
	if not (_p.get("jeep", {}) as Dictionary).is_empty():
		_jeep = _vehicle(PB + "jeep.glb")
		_jeep.name = "jeep"
		root.add_child(_jeep)
		var dm := StandardMaterial3D.new()
		dm.albedo_color = Color(0.8, 0.7, 0.54, 0.55)
		dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		dm.billboard_keep_scale = true
		dm.albedo_texture = _puff_tex()
		dm.roughness = 1.0
		for k in 56:
			var q := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(1.0, 1.0)
			q.mesh = qm
			q.material_override = dm.duplicate()
			q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			q.visible = false
			root.add_child(q)
			_jeep_dust.append(q)
	for aid in _p.get("chai", []):
		var gl := Node3D.new()
		gl.name = "chai_" + String(aid)
		root.add_child(gl)
		var glass := Kit.mat("#d8e2e0", 0.05, 0.0, 0.9)
		glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass.albedo_color.a = 0.35
		Kit.cyl(gl, 0.028, 0.022, 0.08, Vector3(0, 0.04, 0), glass, 16)
		Kit.cyl(gl, 0.025, 0.021, 0.06, Vector3(0, 0.031, 0), Kit.mat("#b07a48", 0.4), 16)
		_chai[String(aid)] = gl
	for c in _p.get("carry", []):
		var what := String(c.get("what", "sandbag"))
		var held: Array = []
		if what == "jerrycans":
			for side in ["l", "r"]:
				var jc := Kit.model(PH + "models/metal_jerrycan_green/metal_jerrycan_green_2k.gltf")
				jc.name = "carried_%s_%s" % [c["actor"], side]
				root.add_child(jc)
				held.append(jc)
		else:
			var bag := _model(PB + "sandbag.glb", Kit.shader(HESSIAN))
			bag.name = "carried_" + String(c["actor"])
			root.add_child(bag)
			held.append(bag)
		_bags[String(c["actor"])] = {"what": what, "nodes": held}
	return root


var _night: Node3D
var _park_truck: Node3D
var _dune: MeshInstance3D
var _net: MeshInstance3D
var _watch: Node3D
var _convoy: Node3D
var _low: Node3D
var _low_rigs: Array = []
var _cv_anchors := {}
var _cv_trucks: Array = []
var _cv_dust: Array = []
var _cv_lining: Node3D
var _cv_canvas: Array = []
const CV_DEVICE := Vector3(-0.9, 1.28, 0.0)      # the device's cradle base in the carrying truck's frame (turned to face aft)
var _bat: Node3D
var _jeep: Node3D
var _jeep_dust: Array = []
var _dressed := {}
var _ball: MeshInstance3D
var _chai := {}
var _watch_mat: ShaderMaterial
var _list: Node3D

const DIAL := """
shader_type spatial;
uniform float secs = 0.0;
varying vec2 uvp;
void vertex() { uvp = UV; }
float hand(vec2 p, float a, float len, float w) {
	vec2 d = vec2(sin(a), cos(a));
	float along = dot(p, d);
	float across = abs(dot(p, vec2(-d.y, d.x)));
	return step(-0.02, along) * step(along, len) * step(across, w);
}
void fragment() {
	vec2 p = (uvp - 0.5) * vec2(2.0, -2.0);
	float r = length(p);
	vec3 c = vec3(0.93, 0.92, 0.86);
	float ang = atan(p.x, p.y);
	float tick = step(0.82, r) * step(r, 0.95) * step(0.96, cos(ang * 12.0));
	c = mix(c, vec3(0.08), tick);
	float s = mod(secs, 60.0);
	float m = mod(secs / 60.0, 60.0);
	float h = mod(secs / 3600.0, 12.0);
	c = mix(c, vec3(0.06), hand(p, h / 12.0 * 6.2832, 0.48, 0.05));
	c = mix(c, vec3(0.06), hand(p, m / 60.0 * 6.2832, 0.74, 0.035));
	c = mix(c, vec3(0.8, 0.1, 0.06), hand(p, floor(s) / 60.0 * 6.2832, 0.82, 0.015));
	c = mix(c, vec3(0.15), step(r, 0.06));
	c = mix(c, vec3(0.55, 0.55, 0.52), step(0.95, r));
	ALBEDO = c;
	ROUGHNESS = 0.25;
	SPECULAR = 0.7;
	ALPHA = 1.0 - step(1.0, r);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
"""


## Gully cricket (param "cricket"): a bat, a tennis ball, tent-peg stumps.
func _cricket_build(root: Node3D) -> void:
	var cd: Dictionary = _p.get("cricket", {})
	if cd.is_empty():
		return
	_bat = Node3D.new()
	_bat.name = "bat"
	root.add_child(_bat)
	# The bat hangs from its handle top at the node's origin, along -Y: grip, handle, the willow blade.
	Kit.cyl(_bat, 0.017, 0.017, 0.2, Vector3(0, -0.1, 0), Kit.mat("#1c1c22", 0.7), 10)
	Kit.cyl(_bat, 0.015, 0.016, 0.07, Vector3(0, -0.235, 0), Kit.mat("#c9a76c", 0.5), 10)
	Kit.slab(_bat, Vector3(0.11, 0.5, 0.045), 0.012, Vector3(0, -0.52, 0.005), Kit.mat("#d9c28e", 0.55))
	_ball = Kit.ball(root, 0.05, Vector3.ZERO, Kit.mat("#d9e64a", 0.6), 14)
	var st: Array = cd.get("stumps", [0.0, 0.0])
	var sb := ground(float(st[0]), float(st[1]))
	var peg := Kit.mat("#8a6a44", 0.8)
	for k in 3:
		Kit.rod(root, sb + Vector3(-0.11 + 0.11 * k, -0.02, 0), sb + Vector3(-0.11 + 0.11 * k + 0.01 * (k - 1), 0.62, 0.01 * k), 0.016, peg, 6)


## The bat's angle from hanging straight down in the swing plane (negative: back, away from the bowler; positive:
## through toward him). Tapping at the crease, the backlift as the bowler runs in, the downswing, a high finish.
static func _bat_angle(t: float, hit: float) -> float:
	var tap := -0.25 + 0.07 * maxf(0.0, sin(t * 7.0))
	var back := Motion.in_out(Motion.seg(t, hit - 1.0, hit - 0.42))
	var down := Motion.in_cubic(Motion.seg(t, hit - 0.24, hit))
	var through := Motion.out_cubic(Motion.seg(t, hit, hit + 0.35))
	return lerpf(lerpf(lerpf(tap, -2.4, back), 0.1, down), 2.5, through)


func _pose_cricket(gt: Transform3D, t: float, ctx: Dictionary) -> void:
	if _bat == null:
		return
	var cd: Dictionary = _p.get("cricket", {})
	var bat = ctx["actor"].call(String(cd.get("bat", ""))) if ctx.has("actor") else null
	var bowl = ctx["actor"].call(String(cd.get("bowl", ""))) if ctx.has("actor") else null
	var on: bool = bat != null and bat.visible
	_bat.visible = on
	_ball.visible = on
	if not on:
		return
	var inv := gt.affine_inverse()
	var hit := float(cd.get("hit", 1e9))
	var rel := float(cd.get("release", hit - 0.55))
	# A right-hander, side-on: his left shoulder to the bowler (`pitch`, toward the bowler), chest to the off side.
	var pitch := Vector3(0, 0, -1)
	if bowl != null:
		pitch = (inv * (bowl.global_position as Vector3)) - (inv * (bat.global_position as Vector3))
		pitch.y = 0.0
		pitch = pitch.normalized()
	var down := Motion.in_cubic(Motion.seg(t, hit - 0.24, hit))
	var through := Motion.out_cubic(Motion.seg(t, hit, hit + 0.35))
	# The stroke opens his body toward the bowler and his front foot strides down the pitch.
	var side := Vector3(-pitch.z, 0, pitch.x)          # his chest's way at address: left shoulder to the bowler
	var open := 0.9 * (0.35 * down + 0.65 * through)
	var facing := side.rotated(Vector3.UP, open * signf(side.cross(pitch).y))
	bat.rotation = Vector3(0, atan2(facing.x, facing.z), 0)
	bat.position += gt.basis * (pitch * 0.2 * Motion.smooth(Motion.seg(t, hit - 0.3, hit - 0.05)))
	var chest: Vector3 = inv * bat.bone_world("spine_03")
	var a := _bat_angle(t, hit)
	# The hands: low in front of the body at address, up by the back shoulder at the top of the backlift, high past the
	# front shoulder at the finish; the bat turns about the axis across the pitch.
	var raise := 0.5 * (1.0 - cos(a))
	var pivot := chest + side * 0.42 + Vector3(0, -0.14 + 0.2 * raise, 0) - pitch * 0.1 * sin(a)
	var dir := (Vector3.DOWN * cos(a) + pitch * sin(a)).normalized()
	var across := pitch.cross(Vector3.UP).normalized()
	var b := Basis(across, -dir, across.cross(-dir)).orthonormalized()
	_bat.transform = Transform3D(b, pivot)
	Crawl.long_arms(bat, 1.6)
	bat.aim_hand("l", gt * (pivot + dir * 0.02), 1.0, 0.03 * raise)
	bat.aim_hand("r", gt * (pivot + dir * 0.11), 1.0, 0.03 * raise)
	var fwd := pitch
	# The ball: in the bowler's hand, then down the pitch with one bounce two-thirds of the way, then lofted away.
	var contact := pivot + (Vector3.DOWN * cos(0.1) + fwd * sin(0.1)).normalized() * 0.55
	if t < rel and bowl != null and bowl.visible:
		_ball.position = inv * (bowl.bone_world("hand_r") as Vector3)
	elif t < hit:
		var from: Vector3 = (inv * (bowl.global_position as Vector3) + Vector3(0, 1.75, 0) - fwd * 0.3) if bowl != null else contact + fwd * 9.0
		var u := (t - rel) / maxf(hit - rel, 0.01)
		var bounce := from.lerp(contact, 0.68)
		bounce.y = height(bounce.x, bounce.z) + 0.034
		var p: Vector3
		if u < 0.68:
			var k := u / 0.68
			p = from.lerp(bounce, k)
			p.y = lerpf(from.y, bounce.y, k * k)
		else:
			var k2 := (u - 0.68) / 0.32
			p = bounce.lerp(contact, k2)
			p.y = lerpf(bounce.y, contact.y, k2) + 0.35 * sin(PI * k2) * 0.5
		_ball.position = p
	else:
		var dt := t - hit
		_ball.position = contact + (fwd * 13.0 + Vector3(0, 9.5, 0)) * dt + Vector3(0, -4.9 * dt * dt, 0)


## The jeep's state at time t: [centre, yaw, body pitch, body roll, distance still to go].
func _jeep_state(jd: Dictionary, t: float) -> Array:
	var at: Array = jd.get("at", [0.0, 0.0, 0.0])
	var yaw1 := deg_to_rad(float(at[2]))
	var slide := deg_to_rad(float(jd.get("slide", 70.0)))
	var yaw0 := yaw1 - slide
	var travel := Vector3(cos(yaw0), 0, -sin(yaw0))       # it keeps moving the way it was heading as it slides
	var ts := float(jd.get("stop", 1e9))
	var v := float(jd.get("speed", 15.0))
	var tsl := 0.5                                        # the slide: full speed to nothing in half a second
	var left: float
	if t >= ts:
		left = 0.0
	elif t >= ts - tsl:
		var u := (ts - t) / tsl
		left = v * tsl * 0.5 * u * u
	else:
		left = v * tsl * 0.5 + v * (ts - tsl - t)
	var c := Vector3(float(at[0]), 0, float(at[1])) - travel * left
	var k := Motion.in_out(clampf(1.0 - (ts - t) / tsl, 0.0, 1.0)) if t < ts else 1.0
	var yaw := lerpf(yaw0, yaw1, k)
	# Bouncing on the ruts at speed, a hop off a hump about 14 m out; leaning out and squatting through the slide.
	var fast := clampf(left / 6.0, 0.0, 1.0)
	var hop := maxf(0.0, 1.0 - pow((left - 7.5) / 1.8, 2.0)) * 0.42
	c.y = height(c.x, c.z) + 0.06 * absf(sin(left * 1.9)) * fast + hop
	var pitch := 0.05 * sin(left * 1.4) * fast - hop * 0.25
	var roll := -0.13 * sin(PI * k) if t < ts else 0.0
	if t >= ts:
		pitch += 0.04 * Motion.wobble(t - ts, 2.4, 4.0)
		roll += 0.05 * Motion.wobble(t - ts, 2.0, 4.5)
	return [c, yaw, pitch, roll, left, travel]


func _pose_jeep(gt: Transform3D, t: float, ctx: Dictionary) -> void:
	if _jeep == null:
		return
	var jd: Dictionary = _p.get("jeep", {})
	var st := _jeep_state(jd, t)
	var c: Vector3 = st[0]
	var yaw: float = st[1]
	var left: float = st[4]
	var travel: Vector3 = st[5]
	var ts := float(jd.get("stop", 1e9))
	_jeep.position = c
	_jeep.rotation = Vector3(float(st[3]), yaw, -float(st[2]))
	_jeep.visible = left < 45.0 and t > ts - 3.5
	var fwd := Vector3(cos(yaw), 0, -sin(yaw))
	var side := Vector3(-fwd.z, 0, fwd.x)
	# Dust: puffs thrown up behind the wheels as it goes (each where the jeep was when it was born), a big burst in
	# the slide; they swell, drift and thin out.
	for k in _jeep_dust.size():
		var q: MeshInstance3D = _jeep_dust[k]
		var burst := k >= 40
		var born := ts - 2.2 + float(k) * 0.05 if not burst else ts - 0.35 + float(k - 40) * 0.03
		var age := t - born
		var life := 2.4 if not burst else 3.0
		q.visible = age > 0.0 and age < life and _jeep.visible
		if not q.visible:
			continue
		var sb := _jeep_state(jd, born)
		var bc: Vector3 = sb[0]
		var byaw: float = sb[1]
		var bf := Vector3(cos(byaw), 0, -sin(byaw))
		var bs := Vector3(-bf.z, 0, bf.x)
		var spread := 0.7 * sin(float(k) * 2.3)
		var at: Vector3 = bc - bf * 1.6 + bs * spread
		if burst:
			at = c + travel * (0.6 + 0.5 * sin(float(k) * 1.7)) + side * (1.2 * sin(float(k) * 2.9)) - fwd * (0.8 * cos(float(k) * 1.3))
		at.y = height(at.x, at.z) + 0.25 + 0.45 * age
		q.position = at + Vector3(0.3 * sin(float(k) * 1.7) * age, 0, 0.3 * cos(float(k) * 1.3) * age) + travel * (0.8 * age if burst else 0.0)
		var sz := (0.9 + 2.2 * age) * (1.5 if burst else 1.0)
		q.scale = Vector3(sz, sz, sz)
		var fade := 1.0 - smoothstep(life * 0.5, life, age)
		(q.material_override as StandardMaterial3D).albedo_color.a = 0.55 * fade
	if not ctx.has("actor"):
		return
	# The driver rides in the right-hand seat.
	var dr = ctx["actor"].call(String(jd.get("driver", "")))
	if dr != null:
		dr.position = gt * (c + fwd * 0.3 + side * 0.36 + Vector3(0, 0.36, 0))
		# "turn": [t0, t1, degrees] twists him in his seat toward the camera (a look, a wink), and back.
		var tw: Array = jd.get("turn", [1e9, 1e9, 0.0])
		var tk := Motion.smooth(Motion.seg(t, float(tw[0]), float(tw[0]) + 0.1)) * (1.0 - Motion.smooth(Motion.seg(t, float(tw[1]) - 0.1, float(tw[1]))))
		dr.rotation = Vector3(0, atan2(fwd.x, fwd.z) + deg_to_rad(float(tw[2])) * tk, 0)
		dr.visible = _jeep.visible
	for rd in jd.get("riders", []):
		var ra = ctx["actor"].call(String(rd[0]))
		if ra != null and ra.visible:
			ra.position = gt * (c + fwd * float(rd[1]) + side * float(rd[2]) + Vector3(0, 0.36, 0))
			ra.rotation = Vector3(0, atan2(fwd.x, fwd.z), 0)
	# The oversized cap slides down over his eyes, tips, and stops on his glasses.
	var sl: Dictionary = jd.get("slip", {})
	var sa = ctx["actor"].call(String(sl.get("actor", ""))) if not sl.is_empty() else null
	if sa != null:
		var cap := sa.find_child("cap", true, false) as Node3D
		if cap != null:
			var k := Motion.out_back(Motion.seg(t, float(sl.get("t", 1e9)), float(sl.get("t", 1e9)) + 0.3), 2.0)
			cap.scale = Vector3.ONE * 1.16
			cap.position = Vector3(0, -0.035 - 0.05 * k, 0.012 + 0.03 * k)
			cap.rotation = Vector3(0.12 * k, 0, 0.05 * k)


## Field disguise: a patrol cap perched on the actor's own hair, a name tape on the chest (made once, on the actor).
func _pose_disguise(ctx: Dictionary, t: float = 0.0) -> void:
	if not ctx.has("actor"):
		return
	# Caps coming off (every frame).
	for dd in _p.get("disguise", []):
		if not dd.has("off"):
			continue
		var a = ctx["actor"].call(String(dd["actor"]))
		if a == null or not a.visible:
			continue
		var head := a.find_child("toon_head", true, false) as Node3D
		if head == null:
			continue
		var cap := head.find_child("field_cap", true, false) as Node3D
		var off := float(dd["off"])
		var reach := Motion.in_out(Motion.seg(t, off - 0.45, off - 0.08))
		var lift := Motion.out_cubic(Motion.seg(t, off - 0.08, off + 0.35))
		var ay := float(a.rotation.y)
		var fwd := Vector3(sin(ay), 0, cos(ay))
		var right := -Vector3(cos(ay), 0, -sin(ay))
		# World-space placement from the head bone (the head node's own frame differs between rigs).
		var crown: Vector3 = a.bone_world("Head") + Vector3(0, float(dd.get("crown", 0.47)), 0) - fwd * 0.02
		var out: Vector3 = a.bone_world("spine_03") + right * 0.42 + fwd * 0.18 + Vector3(0, 0.1, 0)
		if cap != null:
			var w: Vector3 = crown.lerp(crown + Vector3(0, 0.16, 0), minf(lift * 2.0, 1.0)).lerp(out, clampf(lift * 1.3 - 0.3, 0.0, 1.0))
			var bs := Basis.from_euler(Vector3(-0.14 - 0.9 * lift, ay, 0.05 - 0.6 * lift))
			cap.global_transform = Transform3D(bs.scaled(cap.global_transform.basis.get_scale()), w)
			if reach > 0.0:
				Crawl.long_arms(a, 1.45)
				a.aim_hand("r", crown.lerp(w, lift) + Vector3(0, 0.04, 0), reach * (1.0 if lift < 1.0 else 1.0))
		# The hair springs up free.
		var k := t - off
		var spring := 1.0
		if k > 0.0:
			spring = 1.0 + 0.14 * (1.0 - exp(-k * 6.0)) + 0.12 * exp(-k * 5.0) * sin(k * 22.0)
		for h in head.get_children():
			if String(h.name).contains("hair"):
				(h as Node3D).scale = Vector3(1.0 + (spring - 1.0) * 0.6, spring, 1.0 + (spring - 1.0) * 0.6)
	for dd in _p.get("disguise", []):
		var aid := String(dd.get("actor", ""))
		if _dressed.has(aid):
			continue
		var a = ctx["actor"].call(aid)
		if a == null:
			continue
		var head := a.find_child("toon_head", true, false) as Node3D
		var torso := a.find_child("toon_torso", true, false) as Node3D
		if head == null or torso == null:
			continue
		_dressed[aid] = true
		var hm := head.get_node_or_null("head") as MeshInstance3D
		var hr := hm.get_aabb().size.x * 0.5 if hm != null else 0.28
		if bool(dd.get("cap", false)):
			var olive := Kit.mat("#4c5434", 0.75)
			var cap := Node3D.new()
			cap.name = "field_cap"
			head.add_child(cap)
			# Perched high on the mop, tipped back a little: crown, flat top, short stiff peak.
			cap.position = Vector3(0, hr * 0.86, -hr * 0.06)
			cap.rotation = Vector3(-0.14, 0, 0.05)
			Kit.cyl(cap, hr * 0.72, hr * 0.8, hr * 0.42, Vector3(0, hr * 0.12, 0), olive, 28)
			Kit.cyl(cap, hr * 0.7, hr * 0.7, hr * 0.04, Vector3(0, hr * 0.34, 0), Kit.mat("#454d2f", 0.75), 28)
			Kit.ball(cap, 1.0, Vector3(0, -hr * 0.04, hr * 0.78), Kit.mat("#3c4428", 0.7), 20, Vector3(hr * 0.5, hr * 0.05, hr * 0.32))
		var tape := String(dd.get("tape", ""))
		if tape != "":
			var bm := torso.get_child(0) as MeshInstance3D
			var ab := bm.get_aabb() if bm != null else AABB(Vector3(-0.2, 0, -0.15), Vector3(0.4, 0.55, 0.3))
			var tp := Node3D.new()
			tp.name = "name_tape"
			torso.add_child(tp)
			var y := ab.position.y + ab.size.y * 0.66
			tp.position = Vector3(-ab.size.x * 0.17, y, ab.end.z * 0.93)
			tp.rotation = Vector3(-0.12, -0.28, 0)
			Kit.box(tp, Vector3(ab.size.x * 0.42, 0.034, 0.004), Vector3.ZERO, Kit.mat("#3e4428", 0.85))
			var l := Label3D.new()
			l.text = tape
			var sf := SystemFont.new()
			sf.font_names = PackedStringArray(["Arial Narrow", "Arial", "sans-serif"])
			sf.font_weight = 800
			l.font = sf
			l.font_size = 64
			l.pixel_size = 0.00034
			l.modulate = Color(0.04, 0.04, 0.04)
			l.outline_size = 0
			l.shaded = true
			l.double_sided = false
			l.position = Vector3(0, 0, 0.0035)
			tp.add_child(l)


func _convoy_build(root: Node3D) -> void:
	var cd: Dictionary = _p.get("convoy", {})
	if cd.is_empty():
		return
	_convoy = Node3D.new()
	_convoy.name = "convoy"
	root.add_child(_convoy)
	var n := int(cd.get("n", 4))
	for i in n:
		var tr := _vehicle(PB + "truck_canopy.glb")
		_convoy.add_child(tr)
		var wheels := []
		for w in tr.find_children("w*", "Node3D", true, false):
			if String(w.name).length() <= 4:
				wheels.append([w, (w as Node3D).transform])
		_cv_trucks.append([tr, wheels])
	# The carrying truck: the An-32's hold, rebuilt around the device (the same picture for the match cut); its lining is
	# hidden once the camera is out through the canvas ("lining_until").
	var tr0: Node3D = (_cv_trucks[int(cd.get("carry", 1))] as Array)[0]
	# (episode gags live outside the Godot project: load the sibling script from the repo path)
	var fs := GDScript.new()
	fs.source_code = FileAccess.get_file_as_string(Kit.Paths.repo_path("episodes/pokhran/gags/flight.gd"))
	fs.reload()
	var pivot := Node3D.new()
	pivot.name = "cargo"
	pivot.position = CV_DEVICE
	pivot.rotation.y = PI
	tr0.add_child(pivot)
	_cv_lining = fs.cargo_hold(pivot, Vector3.ZERO)
	# The truck itself (canvas, bows, bed, cab) is hidden while the lining is shown: the hold surrounds it.
	for nd in tr0.find_children("*", "MeshInstance3D", true, false):
		if not pivot.is_ancestor_of(nd):
			_cv_canvas.append(nd)
	# Dust: puffs thrown up behind each truck.
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.82, 0.7, 0.55, 0.5)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dm.billboard_keep_scale = true
	dm.albedo_texture = _puff_tex()
	dm.roughness = 1.0
	for k in n * 16:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1.0, 1.0)
		q.mesh = qm
		q.material_override = dm.duplicate()
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_convoy.add_child(q)
		_cv_dust.append(q)


## Where convoy truck i is at time t: [position, yaw, distance travelled].
func _cv_truck_at(cd: Dictionary, i: int, t: float) -> Array:
	var st: Array = cd.get("start", [0.0, 60.0])
	var yaw := deg_to_rad(float(cd.get("heading", 0.0)))
	var fwd := Vector3(cos(yaw), 0, -sin(yaw))
	var d := float(cd.get("speed", 9.0)) * (t - float(cd.get("t0", 0.0))) - float(cd.get("gap", 16.0)) * i
	var p := Vector3(float(st[0]), 0, float(st[1])) + fwd * d
	p.y = height(p.x, p.z)
	return [p, yaw, d]


func _pose_convoy(gt: Transform3D, t: float) -> Dictionary:
	if _convoy == null:
		return {}
	var cd: Dictionary = _p.get("convoy", {})
	var on := false
	for w in cd.get("on", []):
		if t >= float(w[0]) and t < float(w[1]):
			on = true
	_convoy.visible = on
	_cv_lining.visible = t < float(cd.get("lining_until", 1e9))
	for nd in _cv_canvas:
		(nd as Node3D).visible = not _cv_lining.visible
	var out := {}
	for i in _cv_trucks.size():
		var e: Array = _cv_trucks[i]
		var st := _cv_truck_at(cd, i, t)
		var tr: Node3D = e[0]
		var p: Vector3 = st[0]
		var yaw: float = st[1]
		var d: float = st[2]
		# Riding the ruts: a little bounce and roll; the wheels turn with the distance.
		tr.position = p + Vector3(0, 0.03 * absf(sin(d * 1.3 + i)), 0)
		tr.rotation = Vector3(0.012 * sin(d * 0.9 + i * 2.0), yaw, 0.008 * sin(d * 1.1 + i))
		for w in e[1]:
			var xf: Transform3D = w[1]
			(w[0] as Node3D).transform = Transform3D(xf.basis * Basis(Vector3(0, 0, 1), -d / 0.55), xf.origin)
	for k in _cv_dust.size():
		var q: MeshInstance3D = _cv_dust[k]
		var i := k / 16
		var j := k % 16
		var age := fposmod(t * 1.6 + float(j) / 16.0 * 2.2, 2.2)
		var st2 := _cv_truck_at(cd, i, t - age)
		var bp: Vector3 = st2[0]
		var byaw: float = st2[1]
		var bf := Vector3(cos(byaw), 0, -sin(byaw))
		var bs := Vector3(-bf.z, 0, bf.x)
		var at := bp - bf * 3.4 + bs * (0.9 * sin(float(k) * 2.3))
		at.y = height(at.x, at.z) + 0.3 + 0.5 * age
		q.position = at
		var sz := 1.0 + 2.4 * age
		q.scale = Vector3(sz, sz, sz)
		(q.material_override as StandardMaterial3D).albedo_color.a = 0.5 * (1.0 - smoothstep(1.0, 2.2, age))
		# (no dust until the camera is out of the hold: transparent billboards draw through the lining's depth)
		q.visible = t >= float(cd.get("lining_until", -1e9)) + 0.15
	if on:
		var tr0: Node3D = (_cv_trucks[int(cd.get("carry", 1))] as Array)[0]
		var x := tr0.transform
		for key in ["cam0", "look0", "cam1", "look1"]:
			var v: Array = cd.get(key, [0, 0, 0])
			out["convoy_" + key] = gt * (x * Vector3(float(v[0]), float(v[1]), float(v[2])))
	return out


## The night lowering (param "lowering"): three shaft heads, each with an open collar, a tall tripod, a steel cage
## carrying a device (stood on end, strapped to its strongback) and a sodium floodlight on a pole; a truck with its
## headlights on. Each cage goes down its shaft on its own `down` time.
func _lowering_build(root: Node3D) -> void:
	var ld: Dictionary = _p.get("lowering", {})
	if ld.is_empty():
		return
	_low = Node3D.new()
	_low.name = "lowering"
	root.add_child(_low)
	var conc := Kit.shader(CONCRETE)
	var olive := Kit.shader(OLIVE)
	var steel := Kit.shader(STEEL)
	var cable := Kit.shader(CABLE)
	var black := Kit.flat("#020202")
	for sh in ld.get("shafts", []):
		var base := ground(float(sh[0]), float(sh[1]))
		var rig := Node3D.new()
		rig.position = base
		rig.rotation.y = deg_to_rad(float(sh[2]) if (sh as Array).size() > 2 else 0.0)
		_low.add_child(rig)
		# The open collar and the black mouth of the shaft.
		Kit.slab(rig, Vector3(2.7, 0.3, 2.7), 0.05, Vector3(0, 0.07, 0), conc)
		Kit.cyl(rig, SHAFT_R, SHAFT_R, 0.02, Vector3(0, 0.235, 0), black, 32)
		var bore := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = SHAFT_R
		bm.bottom_radius = SHAFT_R
		bm.height = 6.0
		bm.radial_segments = 32
		bm.cap_top = false
		bm.flip_faces = true
		bore.mesh = bm
		bore.material_override = Kit.mat("#1a1814", 0.9)
		bore.position = Vector3(0, -2.8, 0)
		rig.add_child(bore)
		# The tripod: three legs to a 6 m apex, bracing, the sheave.
		var apex := Vector3(0, 6.2, 0)
		var feet := []
		for k in 3:
			var a := deg_to_rad(90.0 + 120.0 * k + 15.0)
			var foot := Vector3(cos(a) * 2.4, 0, sin(a) * 2.4)
			feet.append(foot)
			Kit.rod(rig, foot + Vector3(0, 0.05, 0), apex, 0.06, olive, 12)
			Kit.box(rig, Vector3(0.4, 0.05, 0.4), foot + Vector3(0, 0.02, 0), steel)
		for hf in [0.3, 0.6]:
			for k in 3:
				Kit.rod(rig, (feet[k] as Vector3).lerp(apex, hf), (feet[(k + 1) % 3] as Vector3).lerp(apex, hf), 0.024, olive, 6)
		var sheave := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.22
		tm.outer_radius = 0.3
		tm.rings = 32
		sheave.mesh = tm
		sheave.material_override = steel
		sheave.position = apex + Vector3(0, -0.2, 0)
		sheave.rotation = Vector3(0, 0, PI / 2)
		rig.add_child(sheave)
		# The cage: four posts, three rings, a top bridle to the hook; the device stood on end inside it.
		var cage := Node3D.new()
		cage.name = "cage"
		rig.add_child(cage)
		var hs := 0.62
		var ch := 2.9
		for cx in [-hs, hs]:
			for cz in [-hs, hs]:
				Kit.rod(cage, Vector3(cx, 0, cz), Vector3(cx, ch, cz), 0.035, steel, 8)
				Kit.rod(cage, Vector3(cx, ch, cz), Vector3(0, ch + 0.7, 0), 0.012, cable, 6)
		for hy in [0.05, ch * 0.5, ch]:
			for e in [[Vector3(-hs, hy, -hs), Vector3(hs, hy, -hs)], [Vector3(hs, hy, -hs), Vector3(hs, hy, hs)],
					[Vector3(hs, hy, hs), Vector3(-hs, hy, hs)], [Vector3(-hs, hy, hs), Vector3(-hs, hy, -hs)]]:
				Kit.rod(cage, e[0], e[1], 0.03, steel, 6)
		Kit.box(cage, Vector3(hs * 2, 0.05, hs * 2), Vector3(0, 0.02, 0), steel)
		var dev := Kit.model(PB + "device.glb")
		dev.transform = Transform3D(Basis(Vector3(0, 0, 1), PI / 2), Vector3(0.62 - 0.0, 1.26, 0.0))
		cage.add_child(dev)
		for mi in dev.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			for si in m.mesh.get_surface_count():
				var mt := m.mesh.surface_get_material(si)
				if mt != null and String(mt.resource_name) == "indicator":
					m.set_surface_override_material(si, Kit.lit("#3dff7a", 5.0))
		var hookc := Kit.rod(rig, Vector3.ZERO, Vector3(0, 1, 0), 0.016, cable, 6)
		# The floodlight: a pole beside the collar, two shaded sodium heads aimed at the cage; a halo in the haze.
		var fl: Array = sh[3] if (sh as Array).size() > 3 else [3.2, 2.4]
		var pb := Vector3(float(fl[0]), 0, float(fl[1]))
		var top := pb + Vector3(0, 5.0, 0)
		Kit.rod(rig, pb, top, 0.045, Kit.mat("#3c4232", 0.55, 0.3), 8)
		for k in 2:
			var head: Vector3 = top + Vector3(-0.25 + 0.5 * k, 0.05, 0)
			Kit.box(rig, Vector3(0.36, 0.26, 0.2), head, Kit.mat("#2c2f28", 0.5, 0.3))
			Kit.box(rig, Vector3(0.3, 0.2, 0.02), head + (Vector3(0, 0.2, 0) - head).normalized() * 0.12, Kit.lit("#ffcf86", 14.0))
		# Two ground work lights at the collar throw hard light up onto the cage (the device glints out of the dark).
		for gw in [Vector3(1.3, 0.3, 1.1), Vector3(-1.2, 0.3, 1.3)]:
			Kit.box(rig, Vector3(0.28, 0.22, 0.18), gw, Kit.mat("#2c2f28", 0.5, 0.3))
			var up := Kit.spot(rig, gw + Vector3(0, 0.12, 0), Vector3(0, 2.4, 0), Color(1.0, 0.86, 0.66), 12.0, 7.0, 30.0, true, 1.2)
			up.spot_attenuation = 1.0
		var sp := Kit.spot(rig, top + Vector3(0, -0.1, 0), Vector3(0, 1.6, 0), Color(1.0, 0.72, 0.38), 34.0, 22.0, 34.0, true, 4.0)
		sp.spot_attenuation = 0.9
		_low_rigs.append({"rig": rig, "cage": cage, "cable": hookc, "apex": apex})
	# Sandbags (props: [[x, z, yaw_deg], ...]) and a cable drum ([x, z]).
	var hess := Kit.shader(HESSIAN)
	for sb in ld.get("sandbags", []):
		var bag := _model(PB + "sandbag.glb", hess)
		bag.position = ground(float(sb[0]), float(sb[1])) + Vector3(0, float(sb[3]) if (sb as Array).size() > 3 else 0.0, 0)
		bag.rotation.y = deg_to_rad(float(sb[2]))
		bag.scale = Vector3.ONE * 1.25
		_low.add_child(bag)
	if ld.has("drum"):
		var dr: Array = ld["drum"]
		var dp := ground(float(dr[0]), float(dr[1]))
		var wood := Kit.mat("#5a4632", 0.85)
		for sx in [-0.42, 0.42]:
			Kit.cyl(_low, 0.75, 0.75, 0.06, dp + Vector3(sx, 0.75, 0), wood, 28, Vector3(0, 0, PI / 2))
		Kit.cyl(_low, 0.5, 0.5, 0.8, dp + Vector3(0, 0.75, 0), Kit.mat("#141414", 0.5), 28, Vector3(0, 0, PI / 2))
	for tk in ld.get("trucks", []):
		var tr := _vehicle(PB + "truck_canopy.glb")
		tr.position = ground(float(tk[0]), float(tk[1]))
		tr.rotation.y = deg_to_rad(float(tk[2]))
		_low.add_child(tr)
		var fwd := Vector3(cos(tr.rotation.y), 0, -sin(tr.rotation.y))
		var side := Vector3(-fwd.z, 0, fwd.x)
		for s in [-0.95, 0.95]:
			var lp: Vector3 = tr.position + fwd * 3.0 + side * s + Vector3(0, 1.33, 0)
			Kit.ball(_low, 0.11, lp, Kit.lit("#fff2d6", 10.0), 12)
			var hl := Kit.spot(_low, lp + fwd * 0.12, lp + fwd * 12.0 + Vector3(0, -1.2, 0), Color(1.0, 0.95, 0.82), 9.0, 30.0, 22.0, false, 3.0)
			hl.spot_attenuation = 0.8


func _pose_lowering(t: float) -> void:
	if _low == null:
		return
	var ld: Dictionary = _p.get("lowering", {})
	var on := false
	for w in ld.get("on", []):
		if t >= float(w[0]) and t < float(w[1]):
			on = true
	_low.visible = on
	if not on:
		return
	var shafts: Array = ld.get("shafts", [])
	for i in _low_rigs.size():
		var r: Dictionary = _low_rigs[i]
		var sh: Array = shafts[i]
		var td := float(sh[4]) if sh.size() > 4 else float(ld.get("down", 1e9))
		# Lowered steadily from 1.4 m above the collar to well down the shaft, passing the collar at `down`;
		# the cage turns a touch and sways on its cable.
		var y := minf(0.25 + 1.2 - 1.8 * (t - td), 2.2)
		var cage: Node3D = r["cage"]
		cage.position = Vector3(0.02 * sin(t * 1.3 + i), y, 0.02 * sin(t * 1.7 + i * 2.0))
		cage.rotation.y = 0.12 * sin(t * 0.4 + i)
		var apex: Vector3 = r["apex"]
		var bridle := cage.position + Vector3(0, 2.9 + 0.7, 0)
		var cb: MeshInstance3D = r["cable"]
		var d := apex + Vector3(0, -0.2, 0) - bridle
		cb.transform = Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())) * Basis.from_scale(Vector3(1, d.length(), 1)), bridle + d * 0.5)


## The lookout's wristwatch and his handwritten list of pass times (param "watch").
func _watch_build(root: Node3D) -> void:
	var wd: Dictionary = _p.get("watch", {})
	if wd.is_empty():
		return
	_watch = Node3D.new()
	_watch.name = "watch"
	root.add_child(_watch)
	Kit.cyl(_watch, 0.034, 0.034, 0.012, Vector3(0, -0.004, 0), Kit.mat("#9a9a94", 0.3, 0.8), 24)
	var dial := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.06, 0.06)
	dial.mesh = qm
	_watch_mat = Kit.shader(DIAL)
	dial.material_override = _watch_mat
	dial.position = Vector3(0, 0.0025, 0)
	dial.rotation = Vector3(-PI / 2, 0, 0)
	_watch.add_child(dial)
	for sg in [-1.0, 1.0]:
		Kit.box(_watch, Vector3(0.028, 0.006, 0.05), Vector3(0, -0.006, sg * 0.05), Kit.mat("#2a2418", 0.8))
	# The list: a torn notebook page, pencilled times, the next pass ringed in red.
	_list = Node3D.new()
	_list.name = "pass_list"
	root.add_child(_list)
	Kit.box(_list, Vector3(0.13, 0.17, 0.002), Vector3.ZERO, Kit.mat("#efe8d4", 0.9))
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe Print", "Ink Free", "Comic Sans MS", "sans-serif"])
	var lines: Array = wd.get("list", ["09:12", "11:30", "13:47", "16:05"])
	var hl := String(wd.get("time", "13:47"))
	for i in lines.size():
		var l := Label3D.new()
		l.font = font
		l.font_size = 64
		l.pixel_size = 0.00042
		l.text = String(lines[i])
		l.modulate = Color(0.16, 0.16, 0.2)
		l.outline_size = 0
		l.shaded = true
		l.double_sided = false
		l.position = Vector3(-0.005, 0.055 - 0.034 * i, 0.0015)
		_list.add_child(l)
		if String(lines[i]) == hl:
			var ring := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.026
			tm.outer_radius = 0.029
			ring.mesh = tm
			ring.material_override = Kit.mat("#b0201a", 0.7)
			ring.position = l.position + Vector3(0, 0, 0.001)
			ring.rotation = Vector3(PI / 2, 0, 0)
			ring.scale = Vector3(1.7, 1, 0.55)
			_list.add_child(ring)


func _pose_watch(gt: Transform3D, t: float, ctx: Dictionary) -> void:
	if _watch == null:
		return
	var wd: Dictionary = _p.get("watch", {})
	var actor = ctx["actor"].call(String(wd.get("actor", ""))) if ctx.has("actor") else null
	var vis: bool = actor != null and actor.visible
	_watch.visible = vis
	_list.visible = vis
	if not vis:
		return
	var tf := float(wd.get("fist", 1e9))
	var hm := String(wd.get("time", "13:47")).split(":")
	_watch_mat.set_shader_parameter("secs", float(hm[0]) * 3600.0 + float(hm[1]) * 60.0 + (t - tf))
	var inv := gt.affine_inverse()
	var ay := float(actor.rotation.y)
	var fwd := Vector3(sin(ay), 0, cos(ay))
	var left := Vector3(cos(ay), 0, -sin(ay))
	var head: Vector3 = inv * actor.bone_world("Head")
	var chest: Vector3 = inv * actor.bone_world("spine_03")
	# The left forearm up before his face, the list in that hand; the right fist shoots up on `fist`. Toon arms are
	# short: stretch them first so the fist clears his head.
	var up := Motion.out_back(Motion.seg(t, tf - 0.12, tf + 0.1), 1.6)
	Crawl.long_arms(actor, lerpf(1.25, 2.1, clampf(up, 0.0, 1.0)))
	actor.aim_hand("l", gt * (chest + fwd * 0.34 + Vector3(0, 0.02, 0) + left * 0.24), 1.0, 0.03)
	if up > 0.0:
		actor.aim_hand("r", gt * (head + Vector3(0, 0.3, 0) + fwd * 0.12 - left * 0.46), clampf(up, 0.0, 1.0), 0.08 * clampf(up, 0.0, 1.0))
	var hand: Vector3 = inv * actor.bone_world("hand_l")
	var elbow: Vector3 = inv * actor.bone_world("lowerarm_l")
	var along := (hand - elbow).normalized()
	var wrist := hand - along * 0.07
	# Faces him, cheated halfway toward the `show` point (the camera) so the audience can read it.
	var face := (head - wrist).normalized()
	if wd.has("show"):
		var sp: Dictionary = ctx["point"].call(wd["show"])
		if sp.has("pos"):
			face = (face + (inv * (sp["pos"] as Vector3) - wrist).normalized() * 1.2).normalized()
	var xax := along.cross(face).normalized()
	_watch.transform = Transform3D(Basis(xax, face, xax.cross(face)).orthonormalized() if absf(xax.length()) > 0.0 else Basis.IDENTITY, wrist + face * 0.03)
	# The list beside the watch, gripped at its bottom edge, facing him.
	var lb := Basis.looking_at(-face, Vector3.UP)
	_list.transform = Transform3D(lb, hand + along * 0.05 + Vector3(0, 0.07, 0) + face * 0.02)
var _net_mat: ShaderMaterial

## The flung camouflage net. Net-local (u, v) in metres across the sheet (v from the near edge, -d/2, to the far edge).
## Start: bunched in the throwers' hands at the near edge; each point flies on an arc to its draped place, the far
## edge first; the middle billows; after landing it bounces and settles. Mirrored in net_point() for the hands.
const NET_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform float t_rel = -10.0;   // seconds since the throw began
uniform float fly = 1.6;
uniform vec2 size = vec2(7.0, 6.0);
varying vec2 uvp;
varying vec3 wp;
//NOISE
float bump(vec2 p, vec2 c, float h, float r) { vec2 d = p - c; return h * exp(-dot(d, d) / (r * r)); }
float smax(float a, float b) { return log(exp(a * 7.0) + exp(b * 7.0)) / 7.0; }
float drape(vec2 p) {
	vec2 q = p / size;
	// Soft humps over the poles, sagging between them, down to the ground at the edges (pegged).
	float h = bump(p, vec2(0.0), 1.5, 2.0);
	h = smax(h, bump(p, vec2(-0.33, -0.3) * size, 1.1, 1.35));
	h = smax(h, bump(p, vec2(0.33, -0.3) * size, 1.15, 1.35));
	h = smax(h, bump(p, vec2(-0.32, 0.32) * size, 1.05, 1.35));
	h = smax(h, bump(p, vec2(0.34, 0.3) * size, 1.2, 1.35));
	float edge = 1.0 - smoothstep(0.22, 0.5, max(abs(q.x), abs(q.y)));
	return max(h - 0.1, 0.0) * edge + 0.07 * (fbm(vec3(p * 0.9, 1.0)) - 0.5) + 0.03;
}
vec3 net_pos(vec2 p) {
	float vn = p.y / size.y + 0.5;                       // 0 near edge .. 1 far edge
	vec3 fin = vec3(p.x, drape(p), p.y);
	vec3 st = vec3(p.x * 0.18, 1.25 + 0.25 * vn, -size.y * 0.5 - 0.35);
	float delay = (1.0 - vn) * 0.28;
	float s = clamp((t_rel - delay) / (fly - delay), 0.0, 1.0);
	float e = 1.0 - pow(1.0 - s, 2.2);
	vec3 pos = mix(st, fin, e);
	pos.y += 4.0 * s * (1.0 - s) * (0.45 + 0.8 * vn);
	// The billow: air under the middle while it flies (a soft dome, flutter along it); then a bounce on landing.
	float mid = 1.0 - abs(p.x) / (size.x * 0.5);
	pos.y += sin(3.14159 * s) * (0.3 * mid * vn + 0.06 * sin(p.x * 2.3 + t_rel * 9.0) * vn);
	float dt = t_rel - fly;
	if (dt > 0.0) {
		pos.y += 0.09 * exp(-dt * 4.0) * sin(dt * 14.0 - vn * 5.0) * (1.0 - abs(p.x) / (size.x * 0.5) * 0.6);
	}
	return pos;
}
void vertex() {
	vec2 p = VERTEX.xz;
	float e = 0.04;
	vec3 c = net_pos(p);
	vec3 tu = net_pos(p + vec2(e, 0.0)) - net_pos(p - vec2(e, 0.0));
	vec3 tv = net_pos(p + vec2(0.0, e)) - net_pos(p - vec2(0.0, e));
	VERTEX = c;
	NORMAL = normalize(cross(tv, tu));
	uvp = p;
	wp = (MODEL_MATRIX * vec4(c, 1.0)).xyz;
}
void fragment() {
	// A knotted diamond mesh with garnish strips: olive, brown, dark green and khaki tatters; holes between.
	vec2 g = vec2(uvp.x + uvp.y, uvp.x - uvp.y) / 0.09;
	vec2 f = abs(fract(g) - 0.5);
	float cord = step(0.43, max(f.x, f.y));
	float n = fbm(vec3(uvp * 2.6, 3.0));
	float leaf = step(0.5, fbm(vec3(uvp * 9.0, 7.0)) + 0.18 * (n - 0.5));
	vec3 c = vec3(0.30, 0.33, 0.20);
	c = mix(c, vec3(0.38, 0.29, 0.18), step(0.55, n));
	c = mix(c, vec3(0.17, 0.21, 0.12), step(0.62, fbm(vec3(uvp * 1.7, 9.0))));
	c = mix(c, vec3(0.55, 0.50, 0.34), step(0.68, fbm(vec3(uvp * 2.2, 13.0))));
	c = mix(c, vec3(0.16, 0.15, 0.10), cord * (1.0 - leaf));
	ALBEDO = c;
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
	ALPHA = max(leaf, cord);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	BACKLIGHT = vec3(0.35, 0.38, 0.2);
}
"""


## A net point (net-local metres) at time t_rel since the throw (no noise; the thrower's hands follow the near edge).
static func net_point(p: Vector2, t_rel: float, fly: float, size: Vector2) -> Vector3:
	var vn := p.y / size.y + 0.5
	var st := Vector3(p.x * 0.18, 1.25 + 0.25 * vn, -size.y * 0.5 - 0.35)
	var fin := Vector3(p.x, 0.03, p.y)
	var delay := (1.0 - vn) * 0.28
	var sv := clampf((t_rel - delay) / (fly - delay), 0.0, 1.0)
	var e := 1.0 - pow(1.0 - sv, 2.2)
	var pos := st.lerp(fin, e)
	pos.y += 4.0 * sv * (1.0 - sv) * (0.45 + 0.8 * vn)
	return pos


func _net_build(parent: Node3D) -> void:
	var nd: Dictionary = _p.get("net", {})
	if nd.is_empty():
		return
	var at: Array = nd.get("at", [13.0, -5.0, 0.0])
	var sz: Array = nd.get("size", [7.0, 6.0])
	var holder := Node3D.new()
	holder.name = "net_site"
	holder.position = ground(float(at[0]), float(at[1]))
	holder.rotation.y = deg_to_rad(float(at[2]))
	parent.add_child(holder)
	# The second shaft head: collar and bolted plate (no tripod).
	Kit.slab(holder, Vector3(2.5, 0.3, 2.5), 0.05, Vector3(0, 0.07, 0), Kit.shader(CONCRETE))
	Kit.slab(holder, Vector3(1.7, 0.04, 1.7), 0.015, Vector3(0, 0.24, 0), Kit.shader(STEEL))
	# Net poles (rough wooden props) where the canopy peaks.
	var wood := Kit.mat("#6a5238", 0.9)
	var w := float(sz[0])
	var d := float(sz[1])
	for pp in [[0.0, 0.0, 1.3], [-0.33, -0.3, 0.88], [0.33, -0.3, 0.93], [-0.32, 0.32, 0.83], [0.34, 0.3, 0.98]]:
		var b := Vector3(float(pp[0]) * w, 0, float(pp[1]) * d)
		Kit.rod(holder, b, b + Vector3(0.02, float(pp[2]), -0.015), 0.03, wood, 6)
	_net = MeshInstance3D.new()
	_net.name = "net"
	var pm := PlaneMesh.new()
	pm.size = Vector2(w, d)
	pm.subdivide_width = 90
	pm.subdivide_depth = 80
	_net.mesh = pm
	_net.extra_cull_margin = 6.0
	_net_mat = Kit.shader(NET_SHADER)
	_net_mat.set_shader_parameter("size", Vector2(w, d))
	_net_mat.set_shader_parameter("fly", float(nd.get("fly", 1.6)))
	_net.material_override = _net_mat
	holder.add_child(_net)


func _pose_net(gt: Transform3D, t: float, ctx: Dictionary) -> void:
	if _net == null:
		return
	var nd: Dictionary = _p.get("net", {})
	var fly := float(nd.get("fly", 1.6))
	var t_rel := t - (float(nd.get("land", 1e9)) - fly)
	_net_mat.set_shader_parameter("t_rel", t_rel)
	# Before the throw the net is a bundle in their hands (the sheet collapsed to the start line).
	if not ctx.has("actor"):
		return
	var sz: Array = nd.get("size", [7.0, 6.0])
	var size := Vector2(float(sz[0]), float(sz[1]))
	var hx := (_net.get_parent() as Node3D).transform
	var hands: Array = nd.get("hands", [])
	for i in hands.size():
		var actor = ctx["actor"].call(String(hands[i]))
		if actor == null or not actor.visible:
			continue
		# Each thrower holds a near corner region until it leaves his hands (just after the throw starts).
		var u := (-0.18 if i == 0 else 0.18) * size.x
		var hold := 1.0 - Motion.smooth(Motion.seg(t_rel, 0.25, 0.6))
		if hold <= 0.0:
			continue
		var np := net_point(Vector2(u, -size.y * 0.5), maxf(t_rel, 0.0), fly, size)
		for side in ["l", "r"]:
			var off := Vector3(0.12 if side == "l" else -0.12, 0, 0)
			actor.aim_hand(side, gt * (hx * (np + off)), hold, 0.05 * hold)
var _dune_mat: ShaderMaterial

## A hand-made dune: the heap (k 0) shaped into a barchan (k 1); wind ripples spread from the blow point. The same
## height function is in dune_h() for hands.
const DUNE_SHADER := """
shader_type spatial;
uniform sampler2D s_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D s_nor : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float k = 0.0;
uniform float rip_r = 0.0;
uniform vec2 blow_at = vec2(0.0, -1.6);
varying vec3 wp;
//NOISE
float g2(vec2 p, vec2 c, vec2 s) { vec2 d = (p - c) / s; return exp(-dot(d, d)); }
float heap(vec2 p) {
	return 0.78 * g2(p, vec2(0.0), vec2(0.8)) + 0.16 * g2(p, vec2(0.45, 0.3), vec2(0.3)) + 0.12 * g2(p, vec2(-0.4, -0.35), vec2(0.28))
		+ 0.1 * g2(p, vec2(-0.2, 0.5), vec2(0.25)) + 0.08 * g2(p, vec2(0.5, -0.4), vec2(0.22));
}
float barchan(vec2 p) {
	float sz = p.y < 0.0 ? 1.2 : 0.58;
	float body = 0.82 * exp(-(p.x * p.x) / (1.05 * 1.05) - (p.y * p.y) / (sz * sz));
	float scoop = 0.7 * g2(p, vec2(0.0, 0.8), vec2(0.5, 0.42));
	float horns = 0.2 * (g2(p, vec2(0.95, 0.55), vec2(0.3, 0.5)) + g2(p, vec2(-0.95, 0.55), vec2(0.3, 0.5)));
	return max(body - scoop + horns, 0.0);
}
float ripples(vec2 p, float b) {
	float front = 1.0 - smoothstep(rip_r - 0.35, rip_r, distance(p, blow_at));
	float wind = 1.0 - smoothstep(-0.1, 0.35, p.y);
	float ph = p.y * 6.2831 / 0.11 + 0.8 * sin(p.x * 2.7) + 0.3 * sin(p.x * 7.1);
	return 0.011 * sin(ph) * smoothstep(0.03, 0.2, b) * wind * front;
}
float h(vec2 p) {
	float b = mix(heap(p), barchan(p), k);
	return b + ripples(p, b) - 0.06 * smoothstep(1.9, 2.3, length(p));
}
void vertex() {
	vec2 p = VERTEX.xz;
	float e = 0.02;
	VERTEX.y = h(p);
	NORMAL = normalize(vec3(h(p - vec2(e, 0.0)) - h(p + vec2(e, 0.0)), 2.0 * e, h(p - vec2(0.0, e)) - h(p + vec2(0.0, e))));
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec3 c = texture(s_alb, wp.xz * 0.3).rgb * vec3(1.1, 1.0, 0.84);
	// Freshly patted sand is a touch darker and smoother; the finished dune dries pale.
	c *= mix(0.86, 1.0, k) * (0.9 + 0.1 * fbm(wp * 2.0));
	ALBEDO = c;
	NORMAL_MAP = texture(s_nor, wp.xz * 0.3).rgb;
	NORMAL_MAP_DEPTH = 0.6;
	ROUGHNESS = 0.97;
	SPECULAR = 0.2;
}
"""


## The dune's height (no ripples) at dune-local p for shape k, mirroring DUNE_SHADER.
static func dune_h(p: Vector2, k: float) -> float:
	var hp := 0.78 * _g2(p, Vector2.ZERO, Vector2(0.8, 0.8)) + 0.16 * _g2(p, Vector2(0.45, 0.3), Vector2(0.3, 0.3)) 		+ 0.12 * _g2(p, Vector2(-0.4, -0.35), Vector2(0.28, 0.28)) + 0.1 * _g2(p, Vector2(-0.2, 0.5), Vector2(0.25, 0.25)) 		+ 0.08 * _g2(p, Vector2(0.5, -0.4), Vector2(0.22, 0.22))
	var sz := 1.2 if p.y < 0.0 else 0.58
	var body := 0.82 * exp(-(p.x * p.x) / (1.05 * 1.05) - (p.y * p.y) / (sz * sz))
	var scoop := 0.7 * _g2(p, Vector2(0.0, 0.8), Vector2(0.5, 0.42))
	var horns := 0.2 * (_g2(p, Vector2(0.95, 0.55), Vector2(0.3, 0.5)) + _g2(p, Vector2(-0.95, 0.55), Vector2(0.3, 0.5)))
	return lerpf(hp, maxf(body - scoop + horns, 0.0), k)


static func _g2(p: Vector2, c: Vector2, sz: Vector2) -> float:
	var d := (p - c) / sz
	return exp(-d.dot(d))


func _dune_build(parent: Node3D) -> void:
	var dd: Dictionary = _p.get("dune", {})
	if dd.is_empty():
		return
	var at: Array = dd.get("at", [-7.0, 2.5, 0.0])
	_dune = MeshInstance3D.new()
	_dune.name = "dune"
	var pm := PlaneMesh.new()
	pm.size = Vector2(4.6, 4.6)
	pm.subdivide_width = 150
	pm.subdivide_depth = 150
	_dune.mesh = pm
	_dune.extra_cull_margin = 1.5
	_dune_mat = Kit.shader(DUNE_SHADER)
	_dune_mat.set_shader_parameter("s_alb", Kit.texture(TX + "sand_01_diff_2k.jpg"))
	_dune_mat.set_shader_parameter("s_nor", Kit.texture(TX + "sand_01_nor_gl_2k.jpg", true))
	_dune.material_override = _dune_mat
	_dune.position = ground(float(at[0]), float(at[1])) + Vector3(0, -0.02, 0)
	_dune.rotation.y = deg_to_rad(float(at[2]))
	_dune.scale = Vector3.ONE * float(dd.get("scale", 1.0))
	parent.add_child(_dune)


func _pose_dune(gt: Transform3D, t: float, ctx: Dictionary) -> void:
	if _dune == null:
		return
	var dd: Dictionary = _p.get("dune", {})
	var sh: Array = dd.get("shape", [0.0, 1.0])
	var t0 := float(sh[0])
	var t1 := float(sh[1])
	var k := Motion.in_out(Motion.seg(t, t0, t1))
	_dune_mat.set_shader_parameter("k", k)
	var tb := float(dd.get("blow", 1e9))
	_dune_mat.set_shader_parameter("rip_r", 3.2 * Motion.out_cubic(Motion.seg(t, tb, tb + 0.9)))
	if not ctx.has("actor"):
		return
	var inv := gt.affine_inverse()
	var dx := _dune.transform
	# The ripples start from the blower's lips (just in front of him, toward the dune).
	var bl = ctx["actor"].call(String(dd.get("blower", "")))
	if bl != null and bl.visible:
		var bp: Vector3 = dx.affine_inverse() * (inv * (bl.global_position as Vector3))
		_dune_mat.set_shader_parameter("blow_at", Vector2(bp.x, bp.z) * 0.8)
	# The patting: each worker's two palms come down on the dune in turn (pat-pat), working round as it takes shape.
	var hands: Array = dd.get("hands", [])
	for i in hands.size():
		var actor = ctx["actor"].call(String(hands[i]))
		if actor == null or not actor.visible:
			continue
		var on := Motion.smooth(Motion.seg(t, t0 - 0.4, t0)) * (1.0 - Motion.smooth(Motion.seg(t, t1 + 0.2, t1 + 0.6)))
		if on <= 0.0:
			continue
		var me: Vector3 = dx.affine_inverse() * (inv * (actor.global_position as Vector3))
		var to_c := Vector2(-me.x, -me.z).normalized()
		var sidev := Vector2(-to_c.y, to_c.x)
		for j in 2:
			var sg := -1.0 if j == 0 else 1.0
			var drift := 0.12 * sin(t * 1.3 + i * 2.0 + j)
			var pl := Vector2(me.x, me.z) + to_c * (0.62 + 0.08 * sin(t * 0.9 + i)) + sidev * (0.18 * sg + drift)
			var lift := 0.13 * maxf(0.0, sin(t * 7.5 + j * PI + i * 1.1))
			var pt := dx * Vector3(pl.x, dune_h(pl, k) + 0.035 + lift, pl.y)
			actor.aim_hand("l" if j == 0 else "r", gt * pt, on)
var _park_wheels: Array = []

## Tyre marks in sand: a pressed band with tread bars, darker and smoother than the loose sand round it.
const TREAD := """
shader_type spatial;
render_mode unshaded, blend_mul, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform float len = 1.0;
uniform float depth = 1.0;
varying vec2 uvp;
void vertex() { uvp = UV; }
float h(float x) { return fract(sin(x * 91.7) * 43758.5); }
void fragment() {
	// Darkens the sand under it (multiply): a pressed band with tread bars, a lighter berm along each edge.
	float across = abs(uvp.x - 0.5) * 2.0;
	float along = uvp.y * len;
	float bar = step(0.55, fract(along / 0.09 + across * 0.35 + h(floor(along / 0.09)) * 0.1));
	float inner = 1.0 - smoothstep(0.55, 0.9, across);
	float k = mix(0.8, 0.66, bar * inner);
	k = mix(k, 1.07, smoothstep(0.8, 0.95, across));
	float fade = 1.0 - smoothstep(0.9, 1.0, across);
	ALBEDO = vec3(mix(1.0, k * depth, fade));
}
"""


## The parked-truck gag (param "park"): the truck, its wheels found by name, and its old tyre marks.
func _park_build(parent: Node3D) -> void:
	var pk: Dictionary = _p.get("park", {})
	if pk.is_empty():
		return
	var at: Array = pk.get("at", [8.0, 10.0, 90.0])
	var yaw := deg_to_rad(float(at[2]))
	var fwd := Vector3(cos(yaw), 0, -sin(yaw))
	var side := Vector3(-fwd.z, 0, fwd.x)
	var c := Vector3(float(at[0]), 0, float(at[1]))
	_park_truck = _vehicle(PB + "truck_canopy.glb")
	_park_truck.name = "park_truck"
	parent.add_child(_park_truck)
	for n in _park_truck.find_children("w*", "Node3D", true, false):
		if String(n.name).length() <= 4 and String(n.name) != "wings":
			_park_wheels.append([n, (n as Node3D).transform])
	# The old ruts: two pressed bands from the rear wheels' spot forward along the way it drove out, laid in 1 m
	# pieces on the ground's height; heavier imprints where the rear wheels stood.
	var mat := Kit.shader(TREAD)
	mat.set_shader_parameter("len", 1.0)
	for s in [-1.0, 1.0]:
		for k in 10:
			var mid: Vector3 = c + fwd * (-1.85 - 0.3 + 0.5 + float(k)) + side * (0.95 * s)
			var q := MeshInstance3D.new()
			var pm := PlaneMesh.new()
			pm.size = Vector2(0.34, 1.02)
			q.mesh = pm
			q.material_override = mat
			var y0 := height(mid.x - fwd.x * 0.5, mid.z - fwd.z * 0.5)
			var y1 := height(mid.x + fwd.x * 0.5, mid.z + fwd.z * 0.5)
			var b := Basis(side, Vector3.UP, -fwd)
			b = Basis(b.x, Vector3(0, 1, 0).rotated(side, atan2(y1 - y0, 1.0)), b.z.rotated(side, atan2(y1 - y0, 1.0)))
			q.transform = Transform3D(b, Vector3(mid.x, (y0 + y1) * 0.5 + 0.012, mid.z))
			q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(q)
		# The rear wheel's own imprint, deeper, where it stood (the wheel lands back on it).
		var im := Kit.shader(TREAD)
		im.set_shader_parameter("len", 0.75)
		im.set_shader_parameter("depth", 0.6)
		var wp: Vector3 = c - fwd * 1.85 + side * (0.95 * s)
		var iq := MeshInstance3D.new()
		var ipm := PlaneMesh.new()
		ipm.size = Vector2(0.4, 0.75)
		iq.mesh = ipm
		iq.material_override = im
		iq.transform = Transform3D(Basis(side, Vector3.UP, -fwd), Vector3(wp.x, height(wp.x, wp.z) + 0.016, wp.z))
		iq.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(iq)


func _pose_park(gt: Transform3D, t: float, ctx: Dictionary) -> void:
	if _park_truck == null:
		return
	var pk: Dictionary = _p.get("park", {})
	var at: Array = pk.get("at", [8.0, 10.0, 90.0])
	var yaw := deg_to_rad(float(at[2]))
	var fwd := Vector3(cos(yaw), 0, -sin(yaw))
	var c := Vector3(float(at[0]), 0, float(at[1]))
	var t0 := float(pk.get("from", 0.0))
	var t1 := float(pk.get("to", 1.0))
	var back := float(pk.get("back", 6.0))
	# Reversing: already rolling at t0, decelerating to a stop exactly at t1 (out-quad on distance).
	var u := Motion.seg(t, t0, t1)
	var d := back * (1.0 - (1.0 - u) * (1.0 - u)) if t >= t0 else back * 2.0 * (t - t0) / maxf(t1 - t0, 0.01)
	var off := back - d
	var p := c + fwd * off
	p.y = height(p.x, p.z)
	_park_truck.position = p
	# The brake: the body dips toward the motion (the rear, reversing) and rocks back.
	var dip := 0.025 * Motion.wobble(t - t1, 2.6, 5.0) if t >= t1 else 0.0
	_park_truck.rotation = Vector3(0, yaw, dip)
	# The wheels roll backwards with the distance covered (radius 0.55).
	for w in _park_wheels:
		var xf: Transform3D = w[1]
		(w[0] as Node3D).transform = Transform3D(xf.basis * Basis(Vector3(0, 0, 1), off / 0.55), xf.origin)
	# The marshal: palm up to stop it, raised as it nears the spot, lowered after the stop.
	var aid := String(pk.get("actor", ""))
	var actor = ctx["actor"].call(aid) if aid != "" and ctx.has("actor") else null
	if actor != null and actor.visible:
		var inv := gt.affine_inverse()
		var w := Motion.smooth(Motion.seg(t, t1 - 0.7, t1 - 0.3)) * (1.0 - Motion.smooth(Motion.seg(t, t1 + 0.9, t1 + 1.3)))
		var ay := float(actor.rotation.y)
		var afwd := Vector3(sin(ay), 0, cos(ay))
		var head: Vector3 = inv * actor.bone_world("Head")
		var palm := head + afwd * 0.42 + Vector3(0, 0.12, 0) + Vector3(-afwd.z, 0, afwd.x) * -0.12
		actor.aim_hand("r", gt * palm, w, 0.04 * w)
var _torches: Dictionary = {}


## The night work lights (param "night"): a shaded lamp on a pole and hand torches, hidden outside the windows.
func _night_build(root: Node3D) -> void:
	var nd: Dictionary = _p.get("night", {})
	if nd.is_empty():
		return
	_night = Node3D.new()
	_night.name = "night"
	root.add_child(_night)
	var lz: Array = nd.get("lamp", [1.8, 1.6])
	var base := ground(float(lz[0]), float(lz[1]))
	var paint := Kit.mat("#3c4232", 0.55, 0.3)
	var top := base + Vector3(0, 2.35, 0)
	# A steel pole on a cross foot, an arm out over the work, a conical tin shade, the bulb under it.
	Kit.rod(_night, base, top, 0.025, paint, 8)
	for a in [0.0, PI / 2]:
		Kit.rod(_night, base + Vector3(cos(a) * 0.32, 0.02, sin(a) * 0.32), base - Vector3(cos(a) * 0.32, -0.02, sin(a) * 0.32), 0.02, paint, 6)
	var tip := top + Vector3(-0.55, -0.05, -0.2)
	Kit.rod(_night, top, tip, 0.018, paint, 6)
	var shade := Kit.cyl(_night, 0.035, 0.2, 0.15, tip + Vector3(0, -0.1, 0), Kit.mat("#4a5238", 0.5, 0.4))
	shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var inner := Kit.cyl(_night, 0.034, 0.195, 0.148, tip + Vector3(0, -0.102, 0), Kit.lit("#ffd9a0", 1.2))
	(inner.mesh as CylinderMesh).flip_faces = true
	Kit.ball(_night, 0.045, tip + Vector3(0, -0.15, 0), Kit.lit("#fff0d0", 9.0), 12)
	var cone := Kit.spot(_night, tip + Vector3(0, -0.17, 0), tip + Vector3(0, -3.0, 0), Color(1.0, 0.76, 0.46), 9.0, 9.0, 58.0, true, 1.5)
	cone.spot_attenuation = 1.2
	Kit.omni(_night, tip + Vector3(0, -0.12, 0), Color(1.0, 0.8, 0.55), 0.35, 1.6)
	for aid in nd.get("torch", []):
		var l := Kit.spot(_night, Vector3.ZERO, Vector3(0, 0, -1), Color(0.86, 0.92, 1.0), 7.0, 16.0, 17.0, true, 2.0)
		var lens := Kit.cyl(_night, 0.028, 0.028, 0.012, Vector3.ZERO, Kit.lit("#eef4ff", 6.0), 12)
		var body := Kit.cyl(_night, 0.024, 0.02, 0.16, Vector3.ZERO, Kit.mat("#1c1c1e", 0.5, 0.4), 10)
		_torches[String(aid)] = [l, lens, body]


func _pose_night(gt: Transform3D, t: float, ctx: Dictionary) -> void:
	if _night == null:
		return
	var on := false
	for w in (_p.get("night", {}) as Dictionary).get("on", []):
		if t >= float(w[0]) and t < float(w[1]):
			on = true
	_night.visible = on
	if not on:
		return
	var inv := gt.affine_inverse()
	for aid in _torches:
		var parts: Array = _torches[aid]
		var actor = ctx["actor"].call(aid) if ctx.has("actor") else null
		var vis: bool = actor != null and actor.visible
		for n in parts:
			(n as Node3D).visible = vis
		if not vis:
			continue
		var hand: Vector3 = inv * actor.bone_world("hand_r")
		var yaw := float(actor.rotation.y) + 0.35 * sin(t * 0.8 + 0.6) + 0.12 * sin(t * 2.1)
		var fwd := Vector3(sin(yaw), 0, cos(yaw))
		var dir := (fwd + Vector3(0, -0.42 + 0.08 * sin(t * 1.3), 0)).normalized()
		var b := Basis.looking_at(dir, Vector3.UP)
		(parts[0] as SpotLight3D).transform = Transform3D(b, hand + dir * 0.12)
		# The torch body along the beam, the lens at its front.
		var yb := Basis(b.x, -b.z, b.y)
		(parts[2] as Node3D).transform = Transform3D(yb, hand + dir * 0.03)
		(parts[1] as Node3D).transform = Transform3D(yb, hand + dir * 0.115)


# --- the ground ------------------------------------------------------------------------------------

## A radial grid: dense round the site, coarser with distance, out to the haze (2.4 km).
func _ground(root: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = [0.0]
	var r := 0.0
	while r < 2400.0:
		r += 0.22 if r < 25.0 else (r * 0.009 if r < 120.0 else r * 0.035)
		rings.append(r)
	var seg := 384
	var verts := PackedVector3Array()
	for ri in rings.size():
		var rr: float = rings[ri]
		for k in seg:
			var a := TAU * float(k) / float(seg)
			verts.append(Vector3(cos(a) * rr, 0.0, sin(a) * rr))
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	var idx := PackedInt32Array()
	for ri in rings.size() - 1:
		for k in seg:
			var a := ri * seg + k
			var b := ri * seg + (k + 1) % seg
			var c := a + seg
			var d := b + seg
			idx.append_array([a, c, b, b, c, d])
	var nrm := PackedVector3Array()
	nrm.resize(verts.size())
	nrm.fill(Vector3.UP)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = nrm
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mesh.custom_aabb = AABB(Vector3(-2500, -15, -2500), Vector3(5000, 100, 5000))
	var mi := MeshInstance3D.new()
	mi.name = "ground"
	mi.mesh = mesh
	var code := GROUND.replace("//HEIGHT", HEIGHT_GLSL).replace("PAD_R", "%.1f" % PAD_R)
	var m := Kit.shader(code)
	m.set_shader_parameter("a_alb", Kit.texture(TX + "gravelly_sand_diff_2k.jpg"))
	m.set_shader_parameter("a_nor", Kit.texture(TX + "gravelly_sand_nor_gl_2k.jpg", true))
	m.set_shader_parameter("b_alb", Kit.texture(TX + "sandy_gravel_02_diff_2k.jpg"))
	m.set_shader_parameter("b_nor", Kit.texture(TX + "sandy_gravel_02_nor_gl_2k.jpg", true))
	m.set_shader_parameter("s_alb", Kit.texture(TX + "sand_01_diff_2k.jpg"))
	m.set_shader_parameter("s_nor", Kit.texture(TX + "sand_01_nor_gl_2k.jpg", true))
	m.set_shader_parameter("post_pad", post_pad)
	mi.material_override = m
	_ground_mat = m
	root.add_child(mi)


# --- the shaft head --------------------------------------------------------------------------------

func _shaft(root_all: Node3D) -> void:
	var conc := Kit.shader(CONCRETE)
	var steel := Kit.shader(STEEL)
	# The collar: a cast square ring, its top 0.22 m above the scraped pad.
	Kit.slab(root_all, Vector3(2.7, 0.3, 2.7), 0.05, Vector3(0, 0.07, 0), conc)
	var root := _g98
	# The plate: 1.8 m square, 40 mm thick, bolted down all round; lifting lugs at the corners;
	# a cable gland in the middle where the firing cables come up.
	Kit.slab(root, Vector3(1.8, 0.04, 1.8), 0.015, Vector3(0, 0.24, 0), steel)
	var bolt := Kit.mat("#3a3632", 0.55, 0.6)
	for i in 16:
		var side := i / 4
		var f := (float(i % 4) + 0.5) / 4.0 * 1.6 - 0.8
		var bp: Vector3 = [Vector3(f, 0, -0.82), Vector3(0.82, 0, f), Vector3(-f, 0, 0.82), Vector3(-0.82, 0, -f)][side]
		Kit.cyl(root, 0.022, 0.022, 0.025, bp + Vector3(0, 0.27, 0), bolt, 6)
	for s in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		var lug := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.035
		tm.outer_radius = 0.06
		lug.mesh = tm
		lug.material_override = steel
		lug.position = Vector3(s.x * 0.68, 0.3, s.y * 0.68)
		lug.rotation = Vector3(PI / 2, PI / 4 * s.x * s.y, 0)
		root.add_child(lug)
	Kit.cyl(root, 0.09, 0.11, 0.12, Vector3(0.0, 0.32, 0.0), steel, 16)
	# Firing cables: two black cables from the gland, over the collar and away across the sand toward the
	# bunker (north-east), sagging into the ground.
	var cab := Kit.mat("#141414", 0.5)
	for k in 2:
		var off := Vector3(0.04 * (k * 2 - 1), 0, 0)
		var pts := [Vector3(0, 0.36, 0) + off, Vector3(0.5, 0.33, -0.55) + off, Vector3(1.2, 0.27, -1.3) + off,
			Vector3(1.6, 0.05, -1.75) + off]
		for j in range(1, 7):
			pts.append(ground(1.6 + 2.2 * j, -1.75 - 3.1 * j) + off + Vector3(0, 0.02, 0))
		for j in pts.size() - 1:
			Kit.rod(root, pts[j], pts[j + 1], 0.012, cab, 6)


func _tripod(root: Node3D) -> void:
	var olive := Kit.shader(OLIVE)
	var apex := Vector3(0, TRIPOD_H, 0)
	var feet := []
	for k in 3:
		var a := deg_to_rad(90.0 + 120.0 * k + 15.0)
		var foot := Vector3(cos(a) * 2.2, 0, sin(a) * 2.2)
		foot.y = height(foot.x, foot.z)
		feet.append(foot)
		Kit.rod(root, foot + Vector3(0, 0.05, 0), apex, 0.055, olive, 12)
		Kit.box(root, Vector3(0.36, 0.04, 0.36), foot + Vector3(0, 0.02, 0), Kit.shader(STEEL))
	# Bracing rings of angle iron between the legs.
	for hf in [0.32, 0.62]:
		for k in 3:
			var a: Vector3 = (feet[k] as Vector3).lerp(apex, hf)
			var b: Vector3 = (feet[(k + 1) % 3] as Vector3).lerp(apex, hf)
			Kit.rod(root, a, b, 0.022, olive, 6)
	# The head: a plate, the sheave (grooved wheel) on its axle, the hook block hanging on two falls.
	Kit.cyl(root, 0.2, 0.2, 0.06, apex + Vector3(0, 0.05, 0), olive, 12)
	var sheave := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.2
	tm.outer_radius = 0.28
	tm.rings = 32
	sheave.mesh = tm
	sheave.material_override = Kit.shader(STEEL)
	sheave.position = apex + Vector3(0.0, -0.18, 0.0)
	sheave.rotation = Vector3(0, 0, PI / 2)
	root.add_child(sheave)
	Kit.cyl(root, 0.06, 0.06, 0.2, apex + Vector3(0, -0.18, 0), olive, 12, Vector3(0, 0, PI / 2))
	var cable := Kit.shader(CABLE)
	_hook = Node3D.new()
	_hook.name = "hook"
	_hook.position = apex + Vector3(0, -0.18, 0)
	root.add_child(_hook)
	var drop := 3.4
	for s in [-1.0, 1.0]:
		Kit.rod(_hook, Vector3(0, -0.02, 0.25 * s), Vector3(0, -drop, 0.08 * s), 0.009, cable, 6)
	var block := Kit.slab(_hook, Vector3(0.12, 0.34, 0.26), 0.05, Vector3(0, -drop - 0.12, 0), olive)
	block.name = "block"
	var hook := MeshInstance3D.new()
	var hm := TorusMesh.new()
	hm.inner_radius = 0.05
	hm.outer_radius = 0.075
	hook.mesh = hm
	hook.material_override = Kit.shader(STEEL)
	hook.position = Vector3(0, -drop - 0.4, 0)
	hook.rotation = Vector3(PI / 2, 0, 0)
	_hook.add_child(hook)


func _winch(root: Node3D) -> void:
	var olive := Kit.shader(OLIVE)
	var w := Node3D.new()
	w.name = "winch"
	w.position = Vector3(WINCH_AT.x, height(WINCH_AT.x, WINCH_AT.z), WINCH_AT.z)
	w.rotation.y = atan2(-WINCH_AT.z, WINCH_AT.x)
	root.add_child(w)
	# Skid frame, the drum wound with cable between two side cheeks, a diesel engine block with an exhaust
	# stack and a radiator grille, a hand brake lever.
	for s in [-0.45, 0.45]:
		Kit.slab(w, Vector3(2.4, 0.14, 0.12), 0.02, Vector3(0, 0.07, s), olive)
	Kit.slab(w, Vector3(2.3, 0.05, 1.0), 0.02, Vector3(0, 0.16, 0), olive)
	Kit.cyl(w, 0.32, 0.32, 0.72, Vector3(-0.55, 0.62, 0), Kit.shader(CABLE), 28, Vector3(PI / 2, 0, 0))
	for s in [-0.4, 0.4]:
		Kit.cyl(w, 0.45, 0.45, 0.05, Vector3(-0.55, 0.62, s), olive, 28, Vector3(PI / 2, 0, 0))
		Kit.box(w, Vector3(0.12, 0.5, 0.06), Vector3(-0.55, 0.38, s), olive)
	Kit.slab(w, Vector3(0.9, 0.7, 0.72), 0.08, Vector3(0.55, 0.53, 0), olive)
	Kit.slab(w, Vector3(0.06, 0.55, 0.6), 0.02, Vector3(1.02, 0.52, 0), Kit.mat("#1c1c18", 0.6, 0.3))
	Kit.rod(w, Vector3(0.4, 0.88, 0.2), Vector3(0.4, 1.55, 0.2), 0.04, Kit.mat("#2a241e", 0.5, 0.4), 10)
	Kit.cyl(w, 0.05, 0.04, 0.05, Vector3(0.4, 1.57, 0.2), Kit.mat("#141210", 0.6), 10)
	Kit.rod(w, Vector3(-1.0, 0.2, -0.3), Vector3(-1.15, 1.05, -0.3), 0.018, olive, 8)
	Kit.ball(w, 0.035, Vector3(-1.15, 1.06, -0.3), Kit.mat("#1a1a1a", 0.6), 10)
	# The cable from the top of the drum up to the sheave.
	var drum_top := w.transform * Vector3(-0.55, 0.94, 0)
	Kit.rod(_g98, drum_top, Vector3(0, TRIPOD_H - 0.05, 0), 0.01, Kit.shader(CABLE), 6)
	# A sandbag wall: a low horseshoe on the winch's far side, three courses, bags staggered like bricks.
	var bag := _first_mesh(PB + "sandbag.glb")
	var xfs := []
	var r := Kit.rng("bags")
	var centre := w.position
	var face := atan2(centre.x, centre.z)
	for course in 3:
		var n := 13 - course
		for i in n:
			var a := face + deg_to_rad(-95.0 + 190.0 * (float(i) + 0.5 * (course % 2)) / float(13))
			var rr := 1.85
			var p := centre + Vector3(sin(a) * rr, 0, cos(a) * rr)
			p.y = height(p.x, p.z) + 0.115 * course - 0.01
			var b := Basis(Vector3.UP, a + r.randf_range(-0.12, 0.12))
			b = b * Basis(Vector3.RIGHT, r.randf_range(-0.05, 0.05))
			xfs.append(Transform3D(b.scaled(Vector3(1.0, r.randf_range(0.9, 1.1), 1.0)), p))
	_multi(root, bag, xfs, Kit.shader(HESSIAN), true)


func _spoil(root: Node3D) -> void:
	# The spoil heap: dug sand, paler and looser than the plain, with a shovel stuck in it.
	var sp := Kit.shader(SPOIL_SHADER)
	sp.set_shader_parameter("s_alb", Kit.texture(TX + "sand_01_diff_2k.jpg"))
	sp.set_shader_parameter("s_nor", Kit.texture(TX + "sand_01_nor_gl_2k.jpg", true))

	var g := height(SPOIL_AT.x, SPOIL_AT.z)
	var heap := Kit.ball(root, 1.0, Vector3(SPOIL_AT.x, g - 0.35, SPOIL_AT.z), sp, 48, Vector3(2.6, 1.55, 1.9))
	heap.rotation.y = 0.5
	Kit.ball(root, 1.0, Vector3(SPOIL_AT.x + 1.9, g - 0.2, SPOIL_AT.z + 0.9), sp, 32, Vector3(1.2, 0.6, 1.0))
	# A shovel stuck in the heap: a wooden shaft with a D-grip and a steel blade.
	var wood := Kit.mat("#6b4a2e", 0.75)
	var top := Vector3(SPOIL_AT.x + 1.2, g + 1.75, SPOIL_AT.z + 0.6)
	var bottom := Vector3(SPOIL_AT.x + 0.95, g + 0.8, SPOIL_AT.z + 0.45)
	Kit.rod(root, bottom, top, 0.02, wood, 8)
	Kit.box(root, Vector3(0.16, 0.025, 0.025), top + Vector3(0, 0.04, 0), wood)
	Kit.box(root, Vector3(0.24, 0.3, 0.01), bottom + Vector3(-0.03, -0.1, -0.02), Kit.shader(STEEL), Vector3(0.2, 0.6, 0.25))


func _props(root: Node3D) -> void:
	# Ammunition crates stacked by the winch, three jerrycans, a wooden cable reel on its rim.
	var crate := _tinted(Kit.model(PH + "models/wooden_military_crate/wooden_military_crate_2k.gltf"), Color(0.72, 0.78, 0.6))
	crate.position = ground(3.06, 0.0)
	crate.rotation.y = 0.35
	root.add_child(crate)
	var crate2 := _tinted(Kit.model(PH + "models/wooden_military_crate/wooden_military_crate_2k.gltf"), Color(0.72, 0.78, 0.6))
	crate2.position = ground(3.06, 0.0) + Vector3(0.05, 0.465, 0.02)
	crate2.rotation.y = 0.2
	root.add_child(crate2)
	var crate3 := Kit.model(PH + "models/old_military_crate/old_military_crate_2k.gltf")
	crate3.position = ground(2.2, -1.2)
	crate3.rotation.y = -0.4
	root.add_child(crate3)
	for i in 3:
		var jc := Kit.model(PH + "models/metal_jerrycan_green/metal_jerrycan_green_2k.gltf")
		jc.position = ground(5.1 + 0.42 * i, -2.0 - 0.3 * i)
		jc.rotation.y = 1.2 + 0.25 * i
		root.add_child(jc)
	# The cable reel: two plywood flanges on a drum, black cable wound on it, standing on its rim.
	var reel := Node3D.new()
	reel.position = ground(-2.9, 3.0)
	reel.rotation.y = 0.9
	root.add_child(reel)
	var ply := Kit.mat("#8a6a44", 0.85)
	for s in [-0.32, 0.32]:
		Kit.cyl(reel, 0.62, 0.62, 0.04, Vector3(0, 0.62, s), ply, 32, Vector3(PI / 2, 0, 0))
	Kit.cyl(reel, 0.42, 0.42, 0.6, Vector3(0, 0.62, 0), Kit.mat("#151515", 0.55), 32, Vector3(PI / 2, 0, 0))
	Kit.cyl(reel, 0.09, 0.09, 0.72, Vector3(0, 0.62, 0), ply, 16, Vector3(PI / 2, 0, 0))


func _camp(root: Node3D) -> void:
	var canvas := Kit.shader(CANVAS)
	var rope := Kit.mat("#8a7a5a", 0.9)
	var pole := Kit.mat("#4a3a28", 0.8)
	for i in CAMP.size():
		var at: Vector3 = CAMP[i]
		var t := Node3D.new()
		t.name = "tent_%d" % i
		t.position = ground(at.x, at.z)
		t.rotation.y = 0.35 + 0.12 * i
		root.add_child(t)
		var mi := MeshInstance3D.new()
		mi.mesh = _tent_mesh(4.8, 3.8, 1.5, 2.8)
		mi.material_override = canvas
		t.add_child(mi)
		for s in [-1.0, 1.0]:
			Kit.rod(t, Vector3(0, 0, 2.25 * s), Vector3(0, 2.9, 2.25 * s), 0.035, pole, 8)
			Kit.rod(t, Vector3(0, 2.8, 2.4 * s), Vector3(0, 0.02, 3.8 * s), 0.006, rope, 4)
			for k in 3:
				var z := -1.6 + 1.6 * k
				Kit.rod(t, Vector3(1.9 * s, 1.5, z), Vector3(3.1 * s, 0.02, z), 0.006, rope, 4)
				Kit.rod(t, Vector3(3.1 * s, -0.1, z), Vector3(3.1 * s, 0.12, z), 0.02, pole, 6)


## The shaft below the plate: steel casing seen from inside, cables down the axis, a lamp at the bottom.
func _bore(root: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 28
	var step := 1.5
	var n := int(ceil((SHAFT_D - CHAMBER_H + 0.3) / step))
	for i in n:
		for k in seg:
			var q := []
			for c in [[i, k], [i, k + 1], [i + 1, k + 1], [i + 1, k]]:
				var a := TAU * float(c[1]) / seg
				q.append(Vector3(cos(a) * SHAFT_R, -0.12 - float(c[0]) * step, sin(a) * SHAFT_R))
			_quad(st, q, false)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "bore"
	mi.mesh = st.commit()
	mi.material_override = Kit.shader(BORE)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	# The firing cables: three black cables hanging from the gland down the axis, a steel clamp every 6 m.
	var cab := Kit.mat("#121212", 0.45)
	for k in 3:
		var a := TAU * k / 3.0
		var o := Vector3(cos(a) * 0.035, 0, sin(a) * 0.035)
		Kit.rod(root, o + Vector3(0, 0.2, 0), o + Vector3(0, -SHAFT_D + CAN_H + 0.2, 0), 0.016, cab, 6)
	var clamp := Kit.mat("#8a8a86", 0.4, 0.5)
	for j in int((SHAFT_D - CHAMBER_H) / 6.0):
		Kit.cyl(root, 0.07, 0.07, 0.05, Vector3(0, -3.0 - 6.0 * j, 0), clamp, 12)
	# The underside of the plate closes the bore at the top (no sky down here).
	Kit.cyl(root, SHAFT_R + 0.05, SHAFT_R + 0.05, 0.04, Vector3(0, -0.1, 0), Kit.shader(BORE), 28)
	_chamber(root)
	# The light that falls with the camera (only during the dive).
	_dive_light = Kit.omni(root, Vector3(0, -SHAFT_D, 0), "#fff0dc", 0.0, 9.0)


## The chamber at the bottom: damp rock (a rough cylinder with a domed roof, the bore opening in its crown),
## a wet floor with puddles; the canister in its cage under the bore; a caged work lamp on its own cable.
func _chamber(root: Node3D) -> void:
	var fl := -SHAFT_D
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 40
	var rows := 20
	var r := Kit.rng("chamber")
	var bumps := []
	for k in 6:
		bumps.append([r.randf() * TAU, r.randf_range(0.03, 0.07), float(r.randi_range(2, 6))])
	for i in rows:
		for k in seg:
			var q := []
			for c in [[i, k], [i, k + 1], [i + 1, k + 1], [i + 1, k]]:
				var v := float(c[0]) / rows
				var ang := TAU * float(c[1]) / seg
				var pr := _chamber_profile(v)
				var rr := pr.x
				var fade := 1.0 - smoothstep(0.45, 0.6, v)
				for b in bumps:
					rr += float(b[1]) * sin(ang * float(b[2]) + float(b[0]) + pr.y * 1.7) * fade
				q.append(Vector3(cos(ang) * rr, fl + pr.y, sin(ang) * rr))
			_quad(st, q, true)
	st.generate_normals()
	var wall := MeshInstance3D.new()
	wall.name = "chamber"
	wall.mesh = st.commit()
	wall.material_override = Kit.shader(ROCK)
	root.add_child(wall)
	# The floor: rock and grit, dark puddles.
	var floor_m := Kit.shader(ROCK)
	floor_m.set_shader_parameter("wet", 1.0)
	Kit.cyl(root, CHAMBER_R + 0.3, CHAMBER_R + 0.3, 0.1, Vector3(0, fl - 0.05, 0), floor_m, 40)
	# The canister: a sealed steel cylinder on a low skid, a bolted lid flange, two weld seams, lifting eyes and a
	# junction box where the firing cables go in. No markings.
	var steel := Kit.shader(STEEL)
	steel.set_shader_parameter("rust", 0.35)
	Kit.box(root, Vector3(0.95, 0.08, 0.95), Vector3(0, fl + 0.04, 0), Kit.shader(OLIVE))
	Kit.cyl(root, CAN_R, CAN_R, CAN_H, Vector3(0, fl + 0.08 + CAN_H * 0.5, 0), steel, 40)
	var top := fl + 0.08 + CAN_H
	Kit.cyl(root, CAN_R + 0.035, CAN_R + 0.035, 0.05, Vector3(0, top - 0.02, 0), steel, 40)
	var bolt := Kit.mat("#3a3632", 0.5, 0.6)
	for k in 16:
		var a := TAU * k / 16.0
		Kit.cyl(root, 0.014, 0.014, 0.03, Vector3(cos(a) * (CAN_R + 0.015), top + 0.015, sin(a) * (CAN_R + 0.015)), bolt, 6)
	for hh in [0.35, 1.0]:
		var seam := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = CAN_R - 0.004
		tm.outer_radius = CAN_R + 0.008
		tm.rings = 48
		tm.ring_segments = 6
		seam.mesh = tm
		seam.material_override = steel
		seam.position = Vector3(0, fl + 0.08 + float(hh), 0)
		root.add_child(seam)
	Kit.slab(root, Vector3(0.22, 0.12, 0.16), 0.02, Vector3(0, top + 0.08, 0), Kit.shader(OLIVE))
	for k in 3:
		Kit.cyl(root, 0.022, 0.026, 0.05, Vector3(-0.05 + 0.05 * k, top + 0.16, 0), bolt, 8)
	for s2 in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var em := TorusMesh.new()
		em.inner_radius = 0.03
		em.outer_radius = 0.05
		eye.mesh = em
		eye.material_override = steel
		eye.position = Vector3(s2 * 0.3, top + 0.05, 0)
		eye.rotation = Vector3(0, 0, PI / 2)
		root.add_child(eye)
	# The lowering cage: four angle-iron posts, square frames at the foot, middle and head, X braces on each side,
	# a four-leg chain bridle up to the shackle on the winch cable.
	var cage := Kit.shader(OLIVE)
	var hw := 0.56
	var ch := 1.95
	var corners := [Vector3(hw, 0, hw), Vector3(-hw, 0, hw), Vector3(-hw, 0, -hw), Vector3(hw, 0, -hw)]
	for c in corners:
		Kit.box(root, Vector3(0.05, ch, 0.05), Vector3((c as Vector3).x, fl + ch * 0.5, (c as Vector3).z), cage)
	for hy in [0.06, 0.95, ch - 0.03]:
		for k in 4:
			Kit.rod(root, (corners[k] as Vector3) + Vector3(0, fl + float(hy), 0), (corners[(k + 1) % 4] as Vector3) + Vector3(0, fl + float(hy), 0), 0.02, cage, 6)
	for k in 4:
		var a: Vector3 = corners[k]
		var b: Vector3 = corners[(k + 1) % 4]
		Kit.rod(root, a + Vector3(0, fl + 0.06, 0), b + Vector3(0, fl + 0.95, 0), 0.012, cage, 6)
		Kit.rod(root, b + Vector3(0, fl + 0.06, 0), a + Vector3(0, fl + 0.95, 0), 0.012, cage, 6)
	var shackle := Vector3(0.0, fl + ch + 0.75, 0.0)
	var chain := Kit.mat("#4a4844", 0.45, 0.6)
	for c in corners:
		Kit.rod(root, (c as Vector3) + Vector3(0, fl + ch, 0), shackle, 0.01, chain, 5)
	Kit.rod(root, shackle, Vector3(0.12, fl + CHAMBER_H + 0.6, 0.0), 0.011, Kit.shader(CABLE), 6)
	# The work lamp: a bulb in a wire guard on its own cable from the roof; it swings a little (pose).
	_lamp = Node3D.new()
	_lamp.name = "lamp"
	_lamp.position = Vector3(LAMP_AT.x, fl + CHAMBER_H + 0.2, LAMP_AT.z)
	root.add_child(_lamp)
	var drop := _lamp.position.y - LAMP_AT.y
	Kit.rod(_lamp, Vector3.ZERO, Vector3(0, -drop + 0.12, 0), 0.008, Kit.mat("#111111", 0.5), 5)
	Kit.cyl(_lamp, 0.03, 0.04, 0.07, Vector3(0, -drop + 0.1, 0), Kit.mat("#202020", 0.5), 10)
	var bulb := Kit.ball(_lamp, 0.045, Vector3(0, -drop + 0.03, 0), Kit.lit("#ffd9a0", 14.0), 12)
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var guard := Kit.mat("#2a2a2a", 0.5, 0.5)
	for k in 6:
		var a := TAU * k / 6.0
		Kit.rod(_lamp, Vector3(0, -drop + 0.1, 0), Vector3(cos(a) * 0.07, -drop + 0.02, sin(a) * 0.07), 0.003, guard, 4)
		Kit.rod(_lamp, Vector3(cos(a) * 0.07, -drop + 0.02, sin(a) * 0.07), Vector3(0, -drop - 0.06, 0), 0.003, guard, 4)
	# A conical tin shade over the bulb: the light falls in a cone onto the canister, the bore above stays dark.
	var shade := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.035
	sm.bottom_radius = 0.16
	sm.height = 0.13
	sm.radial_segments = 20
	sm.cap_bottom = false
	shade.mesh = sm
	var shade_m := Kit.shader(OLIVE)
	shade.material_override = shade_m
	shade.position = Vector3(0, -drop + 0.075, 0)
	_lamp.add_child(shade)
	var shade_in := Kit.mat("#d8d2c4", 0.5)
	var inner := MeshInstance3D.new()
	var im := CylinderMesh.new()
	im.top_radius = 0.032
	im.bottom_radius = 0.155
	im.height = 0.125
	im.radial_segments = 20
	im.cap_bottom = false
	im.flip_faces = true
	inner.mesh = im
	inner.material_override = shade_in
	inner.position = shade.position
	_lamp.add_child(inner)
	var aim := Vector3(-LAMP_AT.x * 0.85, -drop - 1.2, -LAMP_AT.z * 0.85)
	var key := Kit.spot(_lamp, Vector3(0, -drop + 0.0, 0), Vector3(0, -drop + 0.0, 0) + aim, "#ffb46a", 7.0, 7.0, 62.0, true, 1.6)
	key.name = "key"
	Kit.omni(_lamp, Vector3(0, -drop - 0.05, 0), "#ffb46a", 0.35, 3.5)
	# A faint cool fill from the far side so the blacks keep detail.
	Kit.omni(root, Vector3(0.9, fl + 2.1, -1.4), "#6a7a9a", 0.4, 4.5)
	# The leak: water seeps down the shaft and drips from several points on the bore's lip and the roof, each on
	# its own rhythm, onto the lid or into the puddles on the floor. Source 0 lands on the lid at params.drip.
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.75, 0.8, 0.82, 0.45)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.roughness = 0.02
	wm.metallic_specular = 1.0
	wm.emission_enabled = true
	wm.emission = Color("ffd9a0")
	wm.emission_energy_multiplier = 3.0
	var lid_y := fl + 0.08 + CAN_H + 0.01
	var rl := Kit.rng("leak")
	var sources := [[Vector3(0.18, fl + CHAMBER_H, 0.1), 1.35]]
	for k in 3:
		var a := rl.randf() * TAU
		sources.append([Vector3(cos(a) * rl.randf_range(0.05, CAN_R - 0.08), fl + CHAMBER_H, sin(a) * rl.randf_range(0.05, CAN_R - 0.08)), rl.randf_range(1.1, 1.9)])
	for k in 5:
		var a := rl.randf() * TAU
		var rr := rl.randf_range(0.95, 1.55)
		var roof := _chamber_profile(lerpf(0.62, 0.9, (rr - 0.9) / 0.7)).y
		sources.append([Vector3(cos(a) * rr, fl + roof - 0.05, sin(a) * rr), rl.randf_range(1.3, 2.4)])
	for i in sources.size():
		var src: Vector3 = sources[i][0]
		var on_lid := Vector2(src.x, src.z).length() < CAN_R - 0.04
		var dst := Vector3(src.x, lid_y if on_lid else fl + 0.005, src.z)
		var d := {"from": src, "to": dst, "period": float(sources[i][1]), "phase": rl.randf() * 3.0,
			"fall": sqrt(2.0 * (src.y - dst.y) / 9.81)}
		d["drop"] = Kit.ball(root, 0.009, Vector3.ZERO, wm, 10)
		(d["drop"] as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ring := MeshInstance3D.new()
		var rm := TorusMesh.new()
		rm.inner_radius = 0.92
		rm.outer_radius = 1.0
		rm.rings = 28
		rm.ring_segments = 4
		ring.mesh = rm
		# A ripple is only a moving highlight on the wet surface: nearly clear, glossy, fading as it spreads.
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = Color(0.85, 0.88, 0.9, 0.0)
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.roughness = 0.04
		rmat.metallic_specular = 1.0
		ring.material_override = rmat
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(ring)
		d["ring"] = ring
		d["ring_mat"] = rmat
		var spray := []
		for k in 5:
			var b := Kit.ball(root, 0.005, Vector3.ZERO, wm, 6)
			b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			spray.append([b, TAU * k / 5.0 + rl.randf() * 0.8, rl.randf_range(0.6, 1.0)])
		d["spray"] = spray
		_drips.append(d)

## The chamber's cross-section: v 0..1 runs up the wall (0..0.6) and over the domed roof to the bore (radius, height).
static func _chamber_profile(v: float) -> Vector2:
	if v < 0.6:
		return Vector2(CHAMBER_R, CHAMBER_H * 0.8 * v / 0.6)
	var a := (v - 0.6) / 0.4
	return Vector2(lerpf(CHAMBER_R, SHAFT_R, sin(a * PI * 0.5)), CHAMBER_H * 0.8 + CHAMBER_H * 0.2 * sin(a * PI * 0.5))


## December 1995: the same site, nothing hidden. The shaft stands open in its collar; a crane truck (the army truck
## chassis with a slewing crane on outriggers) lowers a 6 m section of steel casing into it; two canopy trucks are
## parked in the open; casing pipes lie stacked on sleepers.
func _y1995(root: Node3D) -> void:
	# The open shaft: a dark mouth inside the collar with the casing's rim.
	Kit.cyl(root, 0.86, 0.86, 0.02, Vector3(0, 0.222, 0), Kit.flat("#040404"), 40)
	var rim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.82
	tm.outer_radius = 0.9
	tm.rings = 48
	tm.ring_segments = 8
	rim.mesh = tm
	rim.material_override = Kit.shader(STEEL)
	rim.position = Vector3(0, 0.235, 0)
	root.add_child(rim)
	var crane := Node3D.new()
	crane.name = "crane_rig"
	root.add_child(crane)
	_crane_rig = crane
	# The crane truck: rear to the shaft, outriggers down, a slewing turret and a box boom up over the shaft.
	var truck := _vehicle(PB + "truck_flat.glb")
	truck.position = ground(-6.6, -0.6)
	truck.rotation.y = PI
	crane.add_child(truck)
	var olive := Kit.shader(OLIVE)
	var yellow := Kit.shader(OLIVE)
	yellow.set_shader_parameter("paint", Vector3(0.62, 0.48, 0.12))
	var piv := Vector3(-4.2, truck.position.y + 2.05, -0.6)
	Kit.cyl(crane, 0.75, 0.75, 0.25, piv + Vector3(0, -0.35, 0), olive, 28)
	Kit.slab(crane, Vector3(1.4, 0.95, 1.5), 0.08, piv + Vector3(-0.55, 0.2, 0), olive)
	Kit.slab(crane, Vector3(0.7, 0.7, 0.75), 0.06, piv + Vector3(-0.35, 0.3, 0.75), olive)
	Kit.box(crane, Vector3(0.04, 0.4, 0.5), piv + Vector3(-0.0, 0.42, 1.13), Kit.mat("#0b0d0f", 0.1, 0.3))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var base := Vector3(-6.6 + sx * 2.0, 0, -0.6 + sz * 1.0)
			var foot := Vector3(base.x, 0, -0.6 + sz * 2.1)
			foot.y = height(foot.x, foot.z)
			Kit.box(crane, Vector3(0.16, 0.16, 1.2), Vector3(base.x, truck.position.y + 0.75, -0.6 + sz * 1.55), olive)
			Kit.rod(crane, Vector3(foot.x, truck.position.y + 0.75, foot.z), foot + Vector3(0, 0.08, 0), 0.06, olive, 10)
			Kit.box(crane, Vector3(0.5, 0.06, 0.5), foot + Vector3(0, 0.03, 0), Kit.mat("#5a4a32", 0.9))
	_crane_tip = Vector3(0.0, 9.2, 0.0)
	var boom := Node3D.new()
	boom.position = piv + Vector3(0, 0.35, 0)
	crane.add_child(boom)
	boom.look_at_from_position(boom.position, _crane_tip, Vector3.UP)
	var blen := boom.position.distance_to(_crane_tip)
	for k in 3:
		var w := 0.42 - 0.08 * k
		Kit.slab(boom, Vector3(w, w, blen / 3.0 + 0.2), 0.03, Vector3(0, 0, -blen * (k + 0.5) / 3.0), yellow)
	Kit.cyl(boom, 0.16, 0.16, 0.12, Vector3(0, 0, -blen), olive, 16, Vector3(0, 0, PI / 2))
	Kit.rod(crane, piv + Vector3(0.5, 0.2, 0), boom.position + (_crane_tip - boom.position) * 0.4, 0.07, olive, 10)
	# The hoist cable and the hook block, the casing hanging from a lifting clamp on two short slings.
	_crane_cable = Kit.rod(crane, _crane_tip, _crane_tip - Vector3(0, 1, 0), 0.012, Kit.shader(CABLE), 6)
	_crane_hook = Node3D.new()
	_crane_hook.name = "crane_hook"
	crane.add_child(_crane_hook)
	Kit.slab(_crane_hook, Vector3(0.28, 0.4, 0.14), 0.05, Vector3(0, 0.2, 0), yellow)
	var steel := Kit.shader(STEEL)
	steel.set_shader_parameter("rust", 0.7)
	for s2 in [-1.0, 1.0]:
		Kit.rod(_crane_hook, Vector3(0, 0.0, 0), Vector3(s2 * 0.3, -0.55, 0), 0.012, Kit.mat("#3a3a38", 0.4, 0.6), 5)
	Kit.cyl(_crane_hook, 0.34, 0.34, 0.1, Vector3(0, -0.6, 0), Kit.mat("#2e2c28", 0.45, 0.6), 24)
	var pipe := Kit.cyl(_crane_hook, 0.3, 0.3, 6.0, Vector3(0, -3.6, 0), steel, 32)
	pipe.name = "casing"
	Kit.cyl(_crane_hook, 0.27, 0.27, 0.02, Vector3(0, -0.66, 0), Kit.flat("#060606"), 24)
	# The scientist's clipboard (held in pose).
	_clip = Kit.model(PH + "models/clipboard/clipboard_2k.gltf")
	_clip.name = "clipboard"
	root.add_child(_clip)
	# Two canopy trucks parked in the open; casing pipes stacked on sleepers.
	for e in [[Vector3(7.8, 0, -8.6), 2.35], [Vector3(11.6, 0, -3.2), 2.05], [Vector3(-12.5, 0, 7.5), -0.6], [Vector3(-10.5, 0, -8.0), 2.3]]:
		var tr := _vehicle(PB + "truck_canopy.glb")
		var p: Vector3 = e[0]
		tr.position = ground(p.x, p.z)
		tr.rotation.y = float(e[1])
		root.add_child(tr)
		_trucks95.append([tr, tr.position, tr.rotation.y])
	# Dust kicked up behind a moving truck: soft alpha puffs (shaded, so they take the sun).
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.78, 0.68, 0.52, 0.5)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dm.billboard_keep_scale = true
	dm.albedo_texture = _puff_tex()
	dm.roughness = 1.0
	for k in 26:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1, 1)
		q.mesh = qm
		q.material_override = dm
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		q.visible = false
		root.add_child(q)
		_dust.append(q)
	# Loose spoil spread beside the collar (what the shovellers scoop).
	for pl in _p.get("piles", []):
		var pp := ground(float(pl[0]), float(pl[1]))
		var r := float(pl[2])
		Kit.ball(root, 1.0, pp + Vector3(0, -r * 0.35, 0), sand_pile_mat(), 24, Vector3(r, r * 0.55, r * 0.8))
	# Shovels for the shovellers, and the sand they throw.
	var wood := Kit.mat("#6b4a2e", 0.75)
	var blade_m := Kit.shader(STEEL)
	var sand := Kit.shader(SPOIL_SHADER)
	sand.set_shader_parameter("s_alb", Kit.texture(TX + "sand_01_diff_2k.jpg"))
	sand.set_shader_parameter("s_nor", Kit.texture(TX + "sand_01_nor_gl_2k.jpg", true))
	for sh in _p.get("shovel", []):
		var n := Node3D.new()
		root.add_child(n)
		Kit.rod(n, Vector3(0, 0, 0), Vector3(0, 1.0, 0), 0.02, wood, 8)
		Kit.box(n, Vector3(0.15, 0.025, 0.025), Vector3(0, 1.02, 0), wood)
		var blade := Kit.slab(n, Vector3(0.24, 0.3, 0.012), 0.04, Vector3(0, -0.14, 0.02), blade_m, Vector3(0.25, 0, 0))
		var load := Kit.ball(n, 1.0, Vector3(0, -0.17, 0.07), sand, 10, Vector3(0.1, 0.07, 0.11))
		var clumps := []
		for k in 7:
			clumps.append(Kit.ball(root, 1.0, Vector3.ZERO, sand, 8, Vector3.ONE * (0.045 + 0.018 * (k % 3))))
		_shovels.append({"actor": String(sh["actor"]), "node": n, "load": load, "clumps": clumps,
			"phase": float(sh.get("phase", 0.0)), "period": float(sh.get("period", 1.05))})
	var stack := Vector3(-4.6, 0, 3.4)
	for i in 2:
		Kit.box(root, Vector3(2.2, 0.15, 0.18), ground(stack.x, stack.z + 2.0 * i - 1.0) + Vector3(0, 0.075, 0), Kit.mat("#5a4632", 0.9))
	for row in 2:
		for i in (3 - row):
			var x := stack.x - 0.62 + 0.62 * i + 0.31 * row
			Kit.cyl(root, 0.3, 0.3, 5.0, Vector3(x, height(stack.x, stack.z) + 0.45 + 0.54 * row, stack.z), steel, 24, Vector3(PI / 2, 0, 0))


## A Poly Haven model with its materials' albedo multiplied by `tint` (copies; the cached originals stay).
func _tinted(m: Node3D, tint: Color) -> Node3D:
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var inst := mi as MeshInstance3D
		for si in inst.mesh.get_surface_count():
			var sm := inst.mesh.surface_get_material(si)
			if sm is StandardMaterial3D:
				var c := (sm as StandardMaterial3D).duplicate() as StandardMaterial3D
				c.albedo_color = c.albedo_color * tint
				inst.set_surface_override_material(si, c)
	return m


## An army truck model with its materials replaced by the set's shaders (dusty olive paint, sun-bleached canvas,
## dusty tyres), cached per material name.
func _vehicle(rel: String) -> Node3D:
	var m := Kit.model(rel)
	var olive := Kit.shader(OLIVE)
	var canvas := Kit.shader(CANVAS)
	var tyre := Kit.mat("#1b1a18", 0.95)
	var glass := Kit.mat("#0a0d0f", 0.08, 0.3, 0.9)
	var lamp := Kit.mat("#cfcabc", 0.2, 0.5)
	var dark := Kit.mat("#141412", 0.6)
	var wood := Kit.mat("#5a4632", 0.85)
	var red := Kit.mat("#7a1a10", 0.4)
	var rope := Kit.mat("#7a6a4c", 0.9)
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var inst := mi as MeshInstance3D
		for si in inst.mesh.get_surface_count():
			var name := String(inst.mesh.surface_get_material(si).resource_name) if inst.mesh.surface_get_material(si) else ""
			var o: Material = {"paint": olive, "rim": olive, "canvas": canvas, "tyre": tyre, "glass": glass, "lamp": lamp,
				"dark": dark, "wood": wood, "red": red, "rope": rope}.get(name, null)
			if o:
				inst.set_surface_override_material(si, o)
	return m


var _pile_mat: ShaderMaterial
func sand_pile_mat() -> ShaderMaterial:
	if _pile_mat == null:
		_pile_mat = Kit.shader(SPOIL_SHADER)
		_pile_mat.set_shader_parameter("s_alb", Kit.texture(TX + "sand_01_diff_2k.jpg"))
		_pile_mat.set_shader_parameter("s_nor", Kit.texture(TX + "sand_01_nor_gl_2k.jpg", true))
	return _pile_mat


## A soft round puff (for dust sprites), generated once.
static var _puff: ImageTexture
var _vfar: Node3D
var _vfar_smoke: Array = []
var _ground_mat: ShaderMaterial
var _blast_mm: Array = []          # [MultiMeshInstance3D, kind]
var _blast_seeds := {}             # kind -> Array of seed dictionaries
var _blast_debris: MultiMeshInstance3D
var _post: Node3D
const BLAST_KINDS := {"column": 2200, "surge": 900, "jet": 380, "ring": 800}
const BLAST_DEBRIS := 380


## A soft, cloudy puff (value-noise fbm under a radial falloff): no visible pattern at any size.
static var _dust_t: ImageTexture
static func _dust_tex() -> ImageTexture:
	if _dust_t == null:
		var n := 128
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		var rng := RandomNumberGenerator.new()
		rng.seed = 4242
		var grid := []
		for i in 17 * 17:
			grid.append(rng.randf())
		for y in n:
			for x in n:
				var v := 0.0
				var amp := 0.55
				var f := 4.0
				for o in 5:
					var gx := float(x) / n * f
					var gy := float(y) / n * f
					var ix := int(gx) % 16
					var iy := int(gy) % 16
					var fx: float = gx - floor(gx)
					var fy: float = gy - floor(gy)
					fx = fx * fx * (3.0 - 2.0 * fx)
					fy = fy * fy * (3.0 - 2.0 * fy)
					var a: float = lerpf(grid[iy * 17 + ix], grid[iy * 17 + ix + 1], fx)
					var b: float = lerpf(grid[(iy + 1) * 17 + ix], grid[(iy + 1) * 17 + ix + 1], fx)
					v += amp * lerpf(a, b, fy)
					amp *= 0.5
					f *= 2.0
				var d := Vector2(x - n * 0.5 + 0.5, y - n * 0.5 + 0.5).length() / (n * 0.5)
				var fall := clampf(1.0 - d, 0.0, 1.0)
				var al := smoothstep(0.32, 0.62, fall * (0.35 + 1.1 * v))
				var sh := 0.62 + 0.5 * v * (0.6 + 0.4 * (1.0 - float(y) / n))
				img.set_pixel(x, y, Color(sh, sh, sh, al))
		img.generate_mipmaps()
		_dust_t = ImageTexture.create_from_image(img)
	return _dust_t


func _blast_build(root: Node3D) -> void:
	var bd: Dictionary = _p.get("blast", {})
	if bd.is_empty():
		return
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.9, 0.82, 0.7, 1.0)
	dm.vertex_color_use_as_albedo = true
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dm.billboard_keep_scale = true
	dm.albedo_texture = _dust_tex()
	dm.roughness = 1.0
	dm.backlight_enabled = true
	dm.backlight = Color(0.85, 0.72, 0.5)
	for kind in BLAST_KINDS:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		var q := QuadMesh.new()
		q.size = Vector2(1.0, 1.0)
		if kind == "jet":
			q.center_offset = Vector3(0, 0.5, 0)
		mm.mesh = q
		mm.instance_count = int(BLAST_KINDS[kind])
		var mi := MultiMeshInstance3D.new()
		mi.name = "blast_" + kind
		mi.multimesh = mm
		mi.material_override = dm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.extra_cull_margin = 2000.0
		root.add_child(mi)
		_blast_mm.append([mi, kind])
	var dmm := MultiMesh.new()
	dmm.transform_format = MultiMesh.TRANSFORM_3D
	dmm.mesh = BoxMesh.new()
	dmm.instance_count = BLAST_DEBRIS
	_blast_debris = MultiMeshInstance3D.new()
	_blast_debris.name = "blast_debris"
	_blast_debris.multimesh = dmm
	_blast_debris.material_override = Kit.mat("#4a3a2a", 0.95)
	_blast_debris.extra_cull_margin = 2000.0
	root.add_child(_blast_debris)
	var R := float(bd.get("r", 130.0))
	var cam2: Array = bd.get("toward", [0.0, 1.0])
	var tow := Vector2(float(cam2[0]), float(cam2[1])).normalized()
	var tow_a := atan2(tow.y, tow.x)
	var rng := Kit.rng("blast")
	for kind in BLAST_KINDS:
		var arr: Array = []
		for k in int(BLAST_KINDS[kind]):
			var a := rng.randf() * TAU
			var e := {"shade": rng.randf_range(0.65, 1.08)}
			if kind == "column":
				var d := sqrt(rng.randf()) * R * 0.95
				var core := 1.0 - d / R
				e["p"] = Vector3(cos(a) * d, 0, sin(a) * d)
				e["v"] = Vector3(cos(a), 0, sin(a)) * rng.randf_range(4.0, 26.0) + Vector3(0, rng.randf_range(70.0, 210.0) * (0.2 + 0.8 * pow(core, 0.6)), 0)
				e["t0"] = 0.32 + rng.randf() * 0.6 + d / 1200.0
				e["s0"] = rng.randf_range(8.0, 26.0)
				e["grow"] = rng.randf_range(18.0, 60.0)
				e["k"] = 0.5
			elif kind == "surge":
				var d := R * rng.randf_range(0.75, 1.1)
				e["p"] = Vector3(cos(a) * d, 0, sin(a) * d)
				e["v"] = Vector3(cos(a), 0, sin(a)) * rng.randf_range(50.0, 150.0) + Vector3(0, rng.randf_range(2.0, 14.0), 0)
				e["t0"] = 0.5 + rng.randf() * 0.8
				e["s0"] = rng.randf_range(18.0, 32.0)
				e["grow"] = rng.randf_range(40.0, 90.0)
				e["k"] = 0.32
			elif kind == "jet":
				var d := sqrt(rng.randf()) * R * 0.85
				e["p"] = Vector3(cos(a) * d, 0, sin(a) * d)
				e["v"] = Vector3(0, rng.randf_range(90.0, 220.0) * (1.0 - 0.5 * d / R), 0)
				e["t0"] = 0.05 + rng.randf() * 0.35 + d / 1500.0
				e["w"] = rng.randf_range(2.0, 6.0)
				e["h"] = rng.randf_range(20.0, 70.0)
				e["k"] = 1.3
			else:
				# The shock ring's dust: half of it in the sector facing the camera, where it reads.
				var aa := a if k % 2 == 0 else tow_a + rng.randf_range(-0.45, 0.45)
				var d := lerpf(R * 1.3, float(bd.get("ring_to", 1600.0)), pow(rng.randf(), 0.8))
				e["p"] = Vector3(cos(aa) * d, 0, sin(aa) * d)
				e["dir"] = Vector3(cos(aa), 0, sin(aa))
				e["t0"] = d / float(bd.get("shock", 450.0)) + rng.randf_range(-0.05, 0.05)
				e["s0"] = rng.randf_range(6.0, 14.0)
				e["grow"] = rng.randf_range(14.0, 34.0)
				e["rise"] = rng.randf_range(6.0, 26.0)
			arr.append(e)
		_blast_seeds[kind] = arr
	var deb: Array = []
	for k in BLAST_DEBRIS:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * R * 0.7
		var core := 1.0 - d / R
		deb.append({"p": Vector3(cos(a) * d, 0, sin(a) * d),
			"v": Vector3(cos(a), 0, sin(a)) * rng.randf_range(10.0, 55.0) + Vector3(0, rng.randf_range(35.0, 130.0) * core, 0),
			"t0": 0.15 + rng.randf() * 0.4, "size": rng.randf_range(0.6, 3.2), "spin": Vector3(rng.randf_range(-6, 6), rng.randf_range(-6, 6), rng.randf_range(-6, 6))})
	_blast_seeds["debris"] = deb
	# The observation post: a sandbag parapet facing the blast, a field radio, a canopy truck parked behind.
	var post: Dictionary = bd.get("post", {})
	if not post.is_empty():
		_post = Node3D.new()
		_post.name = "obs_post"
		root.add_child(_post)
		var pa := Vector2(float(post["at"][0]), float(post["at"][1]))
		var pf := (Vector2(float(post["face"][0]), float(post["face"][1])) - pa).normalized()
		var side := Vector2(-pf.y, pf.x)
		var tr := _vehicle(PB + "truck_canopy.glb")
		var tp := pa - pf * 9.0 + side * 7.5
		tr.position = ground(tp.x, tp.y)
		tr.rotation.y = atan2(pf.x, pf.y) + 1.2
		_post.add_child(tr)


func _pose_blast(t: float) -> void:
	var bd: Dictionary = _p.get("blast", {})
	if bd.is_empty():
		return
	var on := false
	var t0 := float(bd["t"])
	for w in bd.get("on", []):
		if t >= float(w[0]) and t < float(w[1]):
			on = true
			# A window can replay the blast from its own start time (news footage of the same moment, another angle).
			if (w as Array).size() > 2:
				t0 = float(w[2])
	var c := Vector2(float(bd["at"][0]), float(bd["at"][1]))
	var c3 := Vector3(c.x, 0, c.y)
	var H := float(bd.get("h", 30.0))
	var R := float(bd.get("r", 130.0))
	_ground_mat.set_shader_parameter("now", t)
	_ground_mat.set_shader_parameter("blast", Vector4(c.x, c.y, t0, 1.0 if on else 0.0))
	_ground_mat.set_shader_parameter("blast_hr", Vector3(H, R, float(bd.get("shock", 450.0))))
	_shimmer_node.visible = not on
	if _post != null:
		_post.visible = on
	var live := on and t >= t0
	for e in _blast_mm:
		(e[0] as Node3D).visible = live
	_blast_debris.visible = live
	if not live:
		return
	var s := t - t0
	for e in _blast_mm:
		var mm: MultiMesh = (e[0] as MultiMeshInstance3D).multimesh
		var kind: String = e[1]
		var seeds: Array = _blast_seeds[kind]
		for k in seeds.size():
			var sd: Dictionary = seeds[k]
			var a := s - float(sd["t0"])
			if a <= 0.0:
				mm.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3.ZERO), c3))
				continue
			var p0: Vector3 = sd["p"]
			var dome := H * exp(-pow(p0.length() / R, 2.0)) * bl_rise_cpu(a)
			var pos: Vector3
			var size := 1.0
			var alpha := 1.0
			var sh := float(sd["shade"])
			if kind == "ring":
				var rise := float(sd["rise"]) * (1.0 - exp(-1.8 * a))
				pos = c3 + p0 + (sd["dir"] as Vector3) * 6.0 * a + Vector3(0, rise * 0.6, 0)
				pos.y += height(pos.x, pos.z)
				size = float(sd["s0"]) + float(sd["grow"]) * (1.0 - exp(-0.8 * a))
				alpha = clampf(a / 0.15, 0.0, 1.0) * (1.0 - clampf((a - 0.8) / 3.5, 0.0, 1.0)) * 0.55
				sh *= 0.8
				mm.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3(size * 1.6, size * 0.7, 1.0)), pos))
			elif kind == "jet":
				var kk := float(sd["k"])
				var travel := (sd["v"] as Vector3) * (1.0 - exp(-kk * a)) / kk
				pos = c3 + p0 + Vector3(0, dome, 0) + travel * 0.35
				var hh := float(sd["h"]) * minf(a / 0.25, 1.0) * (1.0 + a)
				alpha = clampf(a / 0.05, 0.0, 1.0) * (1.0 - clampf((a - 0.5) / 1.2, 0.0, 1.0)) * 0.7
				mm.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3(float(sd["w"]) * (1.0 + a), hh, 1.0)), pos))
			else:
				var kk := float(sd["k"])
				var travel := (sd["v"] as Vector3) * (1.0 - exp(-kk * a)) / kk
				pos = c3 + p0 + travel + Vector3(0, dome, 0)
				if kind == "column":
					# The column spreads as it climbs, and sags a little as it slows.
					var up0 := travel.y
					pos += Vector3(p0.x, 0, p0.z).normalized() * up0 * 0.22 if p0.length() > 0.1 else Vector3.ZERO
					pos.y -= 1.2 * a * a
				else:
					pos.y = minf(pos.y, height(pos.x, pos.z) + 14.0 + 0.25 * float(sd["grow"]) * (1.0 - exp(-0.4 * a)))
				pos.y = maxf(pos.y, height(pos.x, pos.z) + 2.0)
				size = float(sd["s0"]) + float(sd["grow"]) * (1.0 - exp(-0.45 * a))
				alpha = clampf(a / 0.12, 0.0, 1.0) * (0.8 - 0.3 * clampf((a - 3.0) / 8.0, 0.0, 1.0)) * (1.0 - smoothstep(12.0, 20.0, a))
				# Backlit: a dark core and a low dark skirt, a bright lining at the edges and the crown.
				var up := clampf((pos.y - height(pos.x, pos.z)) / 300.0, 0.0, 1.0)
				var col_r := R * (0.9 + up * 1.2) + 1.0
				var edge := clampf(Vector2(pos.x - c.x, pos.z - c.y).length() / col_r, 0.0, 1.0)
				sh *= 0.3 + 0.5 * up + 0.5 * edge * edge * edge
				mm.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3.ONE * size), pos))
			mm.set_instance_color(k, Color(sh, sh * 0.96, sh * 0.9, alpha))
	# Debris: rocks thrown out on ballistic arcs, tumbling; they lie where they land.
	var dmm := _blast_debris.multimesh
	var deb: Array = _blast_seeds["debris"]
	for k in deb.size():
		var sd: Dictionary = deb[k]
		var a := s - float(sd["t0"])
		if a <= 0.0:
			dmm.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3.ZERO), c3))
			continue
		var p0: Vector3 = sd["p"]
		var v: Vector3 = sd["v"]
		var pos := c3 + p0 + Vector3(0, H * exp(-pow(p0.length() / R, 2.0)), 0) + v * a + Vector3(0, -4.9 * a * a, 0)
		var g := height(pos.x, pos.z)
		var spin: Vector3 = sd["spin"] * a
		if pos.y < g:
			pos.y = g
			spin = Vector3.ZERO
		var sz := float(sd["size"])
		dmm.set_instance_transform(k, Transform3D(Basis.from_euler(spin).scaled(Vector3(sz, sz * 0.7, sz * 0.85)), pos))


static func bl_rise_cpu(s: float) -> float:
	return 1.0 - pow(1.0 - clampf(s / 0.5, 0.0, 1.0), 3.0)


func _village_far_build(root: Node3D) -> void:
	var vd: Dictionary = _p.get("village_far", {})
	if vd.is_empty():
		return
	_vfar = Node3D.new()
	_vfar.name = "village_far"
	root.add_child(_vfar)
	var c := Vector2(float(vd["at"][0]), float(vd["at"][1]))
	var mud := Kit.mat("#b98a5a", 0.95)
	var mud2 := Kit.mat("#c9a070", 0.95)
	var thatch := Kit.mat("#8a7448", 0.95)
	var rng := Kit.rng("village_far")
	var n := int(vd.get("n", 9))
	for i in n:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * 26.0
		var x := c.x + cos(a) * d
		var z := c.y + sin(a) * d * 0.6
		var g := ground(x, z)
		var r := rng.randf_range(2.3, 3.1)
		var h := rng.randf_range(2.2, 2.8)
		Kit.cyl(_vfar, r, r * 1.04, h, g + Vector3(0, h * 0.5 - 0.1, 0), mud if i % 2 == 0 else mud2, 14)
		Kit.cyl(_vfar, 0.05, r * 1.25, r * 1.15, g + Vector3(0, h + r * 0.55, 0), thatch, 14)
		# A flat-roofed block house here and there.
		if i % 4 == 3:
			Kit.box(_vfar, Vector3(4.5, 2.6, 3.4), ground(x + 5.0, z) + Vector3(0, 1.2, 0), mud2, Vector3(0, a, 0))
	# The low mud wall round the cluster.
	for k in 28:
		var a0 := TAU * float(k) / 28.0
		var a1 := TAU * float(k + 1) / 28.0
		if k % 9 == 4:
			continue
		var p0 := Vector3(c.x + cos(a0) * 30.0, 0, c.y + sin(a0) * 19.0)
		var p1 := Vector3(c.x + cos(a1) * 30.0, 0, c.y + sin(a1) * 19.0)
		var m := (p0 + p1) * 0.5
		var seg := Kit.box(_vfar, Vector3((p1 - p0).length() + 0.2, 1.0, 0.45), ground(m.x, m.z) + Vector3(0, 0.4, 0), mud)
		seg.rotation.y = -atan2(p1.z - p0.z, p1.x - p0.x)
	for k in 3:
		var tr := Kit.model(PB + ["khejri_a_far.glb", "khejri_b_far.glb", "khejri_c_far.glb"][k])
		tr.position = ground(c.x - 20.0 + 18.0 * k, c.y + 8.0 - 12.0 * (k % 2))
		tr.scale = Vector3.ONE * 1.2
		_vfar.add_child(tr)
	# Two threads of cooking smoke (billboard puffs that rise, grow and fade on a loop).
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.85, 0.83, 0.8, 0.35)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dm.billboard_keep_scale = true
	dm.albedo_texture = _puff_tex()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for s2 in 2:
		var base := ground(c.x - 6.0 + 13.0 * s2, c.y - 3.0 + 4.0 * s2) + Vector3(0, 2.0, 0)
		for k in 10:
			var q := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(1.0, 1.0)
			q.mesh = qm
			q.material_override = dm.duplicate()
			q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_vfar.add_child(q)
			_vfar_smoke.append([q, base, float(k) / 10.0, float(s2)])


func _pose_village_far(t: float) -> void:
	if _vfar == null:
		return
	var on := false
	for w in (_p.get("village_far", {}) as Dictionary).get("on", []):
		if t >= float(w[0]) and t < float(w[1]):
			on = true
	_vfar.visible = on
	if not on:
		return
	for e in _vfar_smoke:
		var q: MeshInstance3D = e[0]
		var base: Vector3 = e[1]
		var k := fposmod(t * 0.12 + float(e[2]) + 0.37 * float(e[3]), 1.0)
		q.position = base + Vector3(2.5 * k * k + 0.4 * sin(k * 9.0 + float(e[3])), 9.0 * k, 0.6 * k)
		q.scale = Vector3.ONE * (0.8 + 3.2 * k)
		(q.material_override as StandardMaterial3D).albedo_color.a = 0.32 * sin(PI * k)


const LENS := """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D view : source_color, filter_linear;
void fragment() {
	vec2 q = UV - 0.5;
	float r = length(q) * 2.0;
	// A mirror image (flipped), bulged a little like a curved lens, tinted amber-green; a bright rim highlight.
	vec2 uv = vec2(1.0 - UV.x, UV.y);
	uv = 0.5 + (uv - 0.5) * (0.85 + 0.15 * r * r);
	vec3 c = texture(view, uv).rgb * vec3(0.95, 0.9, 0.7) * 1.15;
	c += vec3(1.0) * smoothstep(0.8, 0.95, r) * 0.25;
	ALBEDO = c * 0.2;
	EMISSION = c * 0.85;
	ALPHA = 0.92 * (1.0 - smoothstep(0.97, 1.0, r));
	ROUGHNESS = 0.05;
	SPECULAR = 0.9;
}
"""

var _gog: Node3D
var _relic: Node3D


func _relic_build(root: Node3D) -> void:
	var rd: Dictionary = _p.get("relic", {})
	if rd.is_empty():
		return
	_relic = Node3D.new()
	_relic.name = "relic"
	root.add_child(_relic)
	var at := Vector2(float(rd["at"][0]), float(rd["at"][1]))
	_relic.position = ground(at.x, at.y) + Vector3(0, -0.12, 0)
	_relic.rotation = Vector3(0.32, deg_to_rad(float(rd.get("yaw", 0.0))), -0.12)
	var steel := Kit.shader(STEEL)
	# The plate, buckled: two halves at a slight angle, a torn corner, bolt holes round the edge.
	Kit.box(_relic, Vector3(1.9, 0.05, 0.95), Vector3(0, 0, -0.47), steel)
	Kit.box(_relic, Vector3(1.9, 0.05, 0.95), Vector3(0, 0.08, 0.45), steel, Vector3(-0.16, 0, 0))
	for k in 8:
		var bx := -0.85 + 0.243 * k
		Kit.cyl(_relic, 0.03, 0.03, 0.052, Vector3(bx, 0.002, -0.88), Kit.mat("#1a1612", 0.9), 10)
	# Sand drifted over its lower edge.
	Kit.ball(_relic, 1.0, Vector3(0.0, -0.06, -1.0), sand_pile_mat(), 16, Vector3(1.2, 0.1, 0.25))
	# The chalk, still there.
	var lines: Array = rd.get("lines", ["WHITE", "HOUSE"])
	for i in lines.size():
		var l := Kit.text(_relic, String(lines[i]), 0.22, "#e8e4da", Vector3(0, 0.03 + 0.04 * i, -0.55 + 0.62 * i), Vector3(-PI / 2 - (0.16 if i == 1 else 0.0), 0, 0), true, 0.0, Color(0, 0, 0, 0), "body")
		l.modulate.a = 0.9
var _gog_lens: Array = []     # [MeshInstance3D, Camera3D, SubViewport]


func _goggles_build(root: Node3D) -> void:
	var gd: Dictionary = _p.get("goggles", {})
	if gd.is_empty():
		return
	_gog = Node3D.new()
	_gog.name = "goggles"
	root.add_child(_gog)
	var r := float(gd.get("r", 0.26))
	var rubber := Kit.mat("#1a1a1a", 0.7)
	# The strap: a band round the head at eye level.
	var strap := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = r * 1.0
	tm.outer_radius = r * 1.07
	tm.rings = 48
	tm.ring_segments = 6
	strap.mesh = tm
	strap.material_override = rubber
	strap.scale = Vector3(1, 0.35, 0.96)
	_gog.add_child(strap)
	for side: float in [-1.0, 1.0]:
		var cup := Node3D.new()
		cup.position = Vector3(side * r * 0.36, 0.0, r * 1.06)
		_gog.add_child(cup)
		Kit.cyl(cup, r * 0.27, r * 0.3, r * 0.2, Vector3(0, 0, 0), rubber, 24, Vector3(PI / 2, 0, 0))
		var rim := MeshInstance3D.new()
		var rt := TorusMesh.new()
		rt.inner_radius = r * 0.22
		rt.outer_radius = r * 0.28
		rim.mesh = rt
		rim.material_override = Kit.mat("#2a2a2a", 0.35, 0.6)
		rim.rotation.x = PI / 2
		rim.position = Vector3(0, 0, r * 0.1)
		cup.add_child(rim)
		var vp := SubViewport.new()
		vp.size = Vector2i(384, 384)
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.own_world_3d = false
		vp.msaa_3d = Viewport.MSAA_2X
		root.add_child(vp)
		var vc := Camera3D.new()
		vc.fov = float(gd.get("fov", 40.0))
		vc.far = 6000.0
		vp.add_child(vc)
		var lm := ShaderMaterial.new()
		lm.shader = Shader.new()
		lm.shader.code = LENS
		lm.set_shader_parameter("view", vp.get_texture())
		var lens := Kit.quad(cup, Vector2(r * 0.46, r * 0.46), Vector3(0, 0, r * 0.105), lm)
		lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_gog_lens.append([lens, vc, vp, side])
	_gog.visible = false


func _pose_goggles(gt: Transform3D, t: float, ctx: Dictionary) -> void:
	var gd: Dictionary = _p.get("goggles", {})
	if _gog == null:
		return
	var on := false
	for w in gd.get("on", []):
		if t >= float(w[0]) and t < float(w[1]):
			on = true
	var a = ctx["actor"].call(String(gd["actor"])) if ctx.has("actor") else null
	_gog.visible = on and a != null and a.visible
	for e in _gog_lens:
		(e[2] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ALWAYS if _gog.visible else SubViewport.UPDATE_DISABLED
	if not _gog.visible:
		return
	var inv := gt.affine_inverse()
	var ay := float(a.rotation.y)
	var head: Vector3 = a.bone_world("Head")
	var r := float(gd.get("r", 0.26))
	var centre := head + Vector3(0, float(gd.get("up", 0.2)), 0)
	_gog.transform = Transform3D(Basis(Vector3.UP, ay - gt.basis.get_euler().y), inv * centre)
	var looks: Array = gd.get("looks", [])
	for i in _gog_lens.size():
		var e: Array = _gog_lens[i]
		var lens: MeshInstance3D = e[0]
		var vc: Camera3D = e[1]
		var eye := lens.global_position
		var lk: Array = looks[i] if i < looks.size() else [0.0, 30.0, 0.0]
		vc.global_position = eye
		vc.look_at(gt * Vector3(float(lk[0]), float(lk[1]), float(lk[2])), Vector3.UP)


static func _puff_tex() -> ImageTexture:
	if _puff == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		for y in 64:
			for x in 64:
				var d := Vector2(x - 31.5, y - 31.5).length() / 31.5
				var n := 0.75 + 0.25 * sin(x * 0.7) * sin(y * 0.9)
				img.set_pixel(x, y, Color(1, 1, 1, clampf((1.0 - d) * 1.4, 0.0, 1.0) * n))
		_puff = ImageTexture.create_from_image(img)
	return _puff


## The 1995 trucks: one pulls away from `leave.from`, eased off the line, its dust trailing.
func _pose_leave(t: float) -> void:
	var lv: Dictionary = _p.get("leave", {})
	for i in _trucks95.size():
		var e: Array = _trucks95[i]
		(e[0] as Node3D).position = e[1]
	if lv.is_empty():
		for q in _dust:
			(q as Node3D).visible = false
		return
	var idx := int(lv.get("truck", 1))
	var e2: Array = _trucks95[idx]
	var tr: Node3D = e2[0]
	var yaw := float(e2[2])
	var fwd := Vector3(cos(yaw), 0, -sin(yaw))     # the truck model's forward is its local +X
	var t0 := float(lv["from"])
	var dt := maxf(t - t0, 0.0)
	var dist := 0.9 * dt * dt + 0.6 * maxf(dt - 1.0, 0.0) * maxf(dt - 1.0, 0.0)
	var p: Vector3 = (e2[1] as Vector3) + fwd * dist
	p.y = height(p.x, p.z)
	tr.position = p
	tr.rotation.z = 0.01 * sin(t * 13.0) * minf(dt, 1.0)
	# Dust: puffs released behind the rear wheels along the path, each growing and fading over ~1.6 s.
	for k in _dust.size():
		var q: MeshInstance3D = _dust[k]
		var born := t0 + 0.15 + k * 0.09
		var age := t - born
		q.visible = age > 0.0 and age < 1.8
		if not q.visible:
			continue
		var bd := 0.9 * pow(born - t0, 2.0)
		var at: Vector3 = (e2[1] as Vector3) + fwd * (bd - 2.4) + Vector3(-fwd.z, 0, fwd.x) * (0.6 * sin(k * 2.1))
		at.y = height(at.x, at.z) + 0.3 + 0.5 * age
		q.position = at + Vector3(0.25 * sin(k * 1.7) * age, 0, 0.25 * cos(k * 1.3) * age)
		var sz := 0.8 + 2.2 * age
		q.scale = Vector3(sz, sz, sz)
		(q.material_override as StandardMaterial3D).albedo_color.a = 0.5


## The shovellers: a dig-lift-throw cycle driven by time; the shovel sits in both hands (left at the D-grip,
## right down the shaft); the throw sends a clump of sand in an arc into the open shaft.
func _pose_shovels(gt: Transform3D, t: float, ctx: Dictionary) -> void:
	var inv := gt.affine_inverse()
	for sv in _shovels:
		var n: Node3D = sv["node"]
		var actor = ctx["actor"].call(String(sv["actor"])) if ctx.has("actor") else null
		n.visible = actor != null and actor.visible
		for c in sv["clumps"]:
			(c as Node3D).visible = false
		if not n.visible:
			continue
		var me: Vector3 = inv * (actor as Node3D).global_position
		var yaw := float(actor.rotation.y)
		var fwd := Vector3(sin(yaw), 0, cos(yaw))
		var right := -Vector3(cos(yaw), 0, -sin(yaw))
		var per := float(sv["period"])
		var ph := fposmod((t + float(sv["phase"])) / per, 1.0)
		# Key poses of the blade tip (relative to the body) and the shaft's tilt: dig low in front, lift, swing to
		# the side toward the shaft and throw, come back.
		var dig := me + fwd * 0.62 + right * 0.05 + Vector3(0, 0.02, 0)
		var lift := me + fwd * 0.48 + right * 0.08 + Vector3(0, 0.42, 0)
		var throw_p := me + fwd * 0.6 - right * 0.32 + Vector3(0, 0.62, 0)
		var tip: Vector3
		var k: float
		if ph < 0.3:
			k = Motion.in_out(ph / 0.3)
			tip = throw_p.lerp(dig, k)
		elif ph < 0.55:
			k = Motion.in_out((ph - 0.3) / 0.25)
			tip = dig.lerp(lift, k)
		elif ph < 0.72:
			k = Motion.out_cubic((ph - 0.55) / 0.17)
			tip = lift.lerp(throw_p, k)
		else:
			tip = throw_p
		var handle_top := me + fwd * 0.05 + right * 0.18 + Vector3(0, 0.62, 0)
		var axis := (handle_top - tip).normalized()
		var basis := Basis(Quaternion(Vector3.UP, axis))
		# Face the blade toward the body's forward.
		basis = basis * Basis(Vector3.UP, yaw - basis.get_euler().y)
		n.transform = Transform3D(basis, tip + axis * 0.26)
		var loaded := ph >= 0.3 and ph < 0.62
		(sv["load"] as Node3D).visible = loaded
		actor.aim_hand("l", gt * (tip + axis * 1.2), 1.0, 0.02)
		actor.aim_hand("r", gt * (tip + axis * 0.6), 1.0, 0.0)
		# The throw: a clump flies from the blade at ph 0.62 in an arc to the shaft mouth.
		var tt := (ph - 0.62) * per
		if tt > 0.0 and tt < 0.6:
			var mouth := Vector3(0.0, 0.22, 0.0)
			for ci in (sv["clumps"] as Array).size():
				var c: Node3D = sv["clumps"][ci]
				var spread := Vector3(0.12 * sin(ci * 2.3), 0.05 * cos(ci * 1.7), 0.12 * cos(ci * 2.9))
				var u := clampf(tt / 0.5, 0.0, 1.0)
				c.visible = u < 1.0
				c.position = Motion.arc(throw_p + spread * 0.3, mouth + spread, 0.45, u) - Vector3(0, 0.0, 0)


## Dive path at scene time t (gag-local): {"cam", "look", "count", "on"}.
func _dive(t: float) -> Dictionary:
	var d: Dictionary = _p.get("dive", {})
	if d.is_empty():
		return {"on": false}
	var u := Motion.seg(t, float(d["from"]), float(d["to"]))
	var y1 := float(d.get("y1", -188.0))
	# Already falling inside the bore mouth at the cut, accelerating, easing out near the bottom.
	var y := lerpf(-0.4, y1, Motion.in_out(u))
	# Off the cable axis, circling it slowly as it falls.
	var ang := 0.4 + 1.1 * Motion.smooth(u)
	var off := Vector3(cos(ang), 0, sin(ang)) * lerpf(0.12, 0.44, Motion.smooth(clampf(u * 3.0, 0.0, 1.0)))
	var cam := off + Vector3(0, y, 0)
	var look := off * 0.55 + Vector3(0, y - 10.0, 0)
	return {"on": t >= float(d["from"]) - 0.05 and t <= float(d["to"]) + 0.3, "cam": cam, "look": look,
		"count": cam + (look - cam).normalized() * 1.9 + Vector3(-off.z, 0, off.x).normalized() * 0.2}


## A ridge tent: two sagging roof slopes from the ridge to the eaves, short side walls, gable ends.
func _tent_mesh(length: float, width: float, wall: float, ridge: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hl := length * 0.5
	var hw := width * 0.5
	var nu := 10
	var nv := 4
	for s in [-1.0, 1.0]:
		for i in nu:
			for j in nv:
				var q := []
				for c in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]:
					var u := float(c[0]) / nu
					var v := float(c[1]) / nv
					var z := -hl + length * u
					var x: float = s * hw * v
					var y := ridge + (wall - ridge) * v - 0.12 * sin(PI * u) * sin(PI * v)
					q.append(Vector3(x, y, z))
				_quad(st, q, s < 0.0)
		# Side wall.
		for i in nu:
			var z0 := -hl + length * float(i) / nu
			var z1 := -hl + length * float(i + 1) / nu
			_quad(st, [Vector3(s * hw, 0, z0), Vector3(s * hw, 0, z1), Vector3(s * hw, wall, z1), Vector3(s * hw, wall, z0)], s > 0.0)
	# Gables (front and back): a pentagon each.
	for s in [-1.0, 1.0]:
		var z: float = s * hl
		var p := [Vector3(-hw, 0, z), Vector3(hw, 0, z), Vector3(hw, wall, z), Vector3(0, ridge, z), Vector3(-hw, wall, z)]
		for k in [[0, 1, 2], [0, 2, 4], [4, 2, 3]]:
			for idx in (k if s > 0.0 else [k[0], k[2], k[1]]):
				st.add_vertex(p[idx])
	st.generate_normals()
	return st.commit()


static func _quad(st: SurfaceTool, q: Array, flip: bool) -> void:
	var order := [0, 1, 2, 0, 2, 3] if not flip else [0, 2, 1, 0, 3, 2]
	for k in order:
		st.add_vertex(q[k])


func _windsock(root: Node3D) -> void:
	var base := ground(SOCK_AT.x, SOCK_AT.z)
	var galv := Kit.mat("#8f9296", 0.45, 0.6)
	Kit.rod(root, base, base + Vector3(0, SOCK_H, 0), 0.045, galv, 12)
	Kit.cyl(root, 0.25, 0.3, 0.12, base + Vector3(0, 0.06, 0), Kit.shader(CONCRETE), 16)
	for k in 3:
		var a := TAU * k / 3.0
		Kit.rod(root, base + Vector3(0, SOCK_H * 0.6, 0), base + Vector3(cos(a) * 2.6, 0.02, sin(a) * 2.6), 0.005, galv, 4)
	_sock_pivot = Node3D.new()
	_sock_pivot.name = "sock_pivot"
	_sock_pivot.position = base + Vector3(0, SOCK_H - 0.1, 0)
	root.add_child(_sock_pivot)
	var ring := MeshInstance3D.new()
	var rt := TorusMesh.new()
	rt.inner_radius = 0.27
	rt.outer_radius = 0.3
	ring.mesh = rt
	ring.material_override = galv
	ring.position = Vector3(0.05, 0, 0)
	ring.rotation = Vector3(0, 0, PI / 2)
	_sock_pivot.add_child(ring)
	Kit.rod(_sock_pivot, Vector3(0, 0, 0), Vector3(0.05, 0.28, 0), 0.012, galv, 6)
	# The sock: an open cone of 5 bands from r 0.28 at the ring to 0.13 at the tail.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var L := 1.9
	var nr := 16
	var nl := 14
	for i in nl:
		for k in nr:
			var q := []
			for c in [[i, k], [i + 1, k], [i + 1, k + 1], [i, k + 1]]:
				var u := float(c[0]) / nl
				var a := TAU * float(c[1]) / nr
				var rr := lerpf(0.28, 0.13, u)
				q.append(Vector3(0.05 + L * u, cos(a) * rr, sin(a) * rr))
			_quad(st, q, false)
	st.generate_normals()
	_sock = MeshInstance3D.new()
	_sock.mesh = st.commit()
	_sock_mat = Kit.shader(SOCK)
	_sock.material_override = _sock_mat
	_sock_pivot.add_child(_sock)


func _vegetation(root: Node3D) -> void:
	var leaf_mat := Kit.shader(FOLIAGE)
	leaf_mat.set_shader_parameter("tint", Vector3(0.66, 0.66, 0.56))
	var bark_mat := Kit.shader(BARK)
	_foliage_mats.append(leaf_mat)
	# The hero khejri behind the shaft, then trees scattered across the plain, thinning with distance.
	_tree(root, "khejri_a", TREE_AT, 0.4, 1.0, leaf_mat, bark_mat)
	_tree(root, "khejri_b", Vector3(19.0, 0, -46.0), 2.1, 1.05, leaf_mat, bark_mat)
	_tree(root, "khejri_c", Vector3(-41.0, 0, -12.0), 4.0, 0.95, leaf_mat, bark_mat)
	var r := Kit.rng("trees")
	for i in 26:
		var a := r.randf() * TAU
		var d := r.randf_range(55.0, 520.0)
		var p := Vector3(cos(a) * d, 0, sin(a) * d)
		if p.z > 20.0 and absf(p.x) < 40.0:
			continue
		_tree(root, ["khejri_a", "khejri_b", "khejri_c"][i % 3], p, r.randf() * TAU, r.randf_range(0.8, 1.15), leaf_mat, bark_mat)
	# Hero plants placed per camera (params "tufts": [[x, z, scale], ...], "bushes": [[x, z, scale, yaw], ...]).
	var tm := _first_mesh(PB + "grass_a.glb")
	var txf := []
	for e in _p.get("tufts", []):
		txf.append(Transform3D(Basis(Vector3.UP, float(e[0]) * 3.7).scaled(Vector3.ONE * float(e[2])), ground(float(e[0]), float(e[1])) - Vector3(0, 0.02, 0)))
	if not txf.is_empty():
		_multi(root, tm, txf, grass_mat_hero(), true)
	for e in _p.get("bushes", []):
		var b := _model(PB + "ker_a.glb", Kit.shader(BARK))
		b.position = ground(float(e[0]), float(e[1])) - Vector3(0, 0.05, 0)
		b.scale = Vector3.ONE * float(e[2])
		b.rotation.y = float(e[3]) if e.size() > 3 else 0.0
		root.add_child(b)
	# Ker bushes: clumps across the plain, none on the pad or the track.
	var ker_mat := Kit.shader(BARK)
	ker_mat.set_shader_parameter("tint", Vector3(1.05, 1.0, 0.95))
	for kname in ["ker_a", "ker_b"]:
		var mesh := _first_mesh(PB + kname + ".glb")
		var xfs := []
		var rk := Kit.rng(kname)
		var n := 0
		while n < 45:
			var a := rk.randf() * TAU
			var d := pow(rk.randf(), 1.6) * 180.0 + 5.0
			var x := cos(a) * d
			var z := sin(a) * d
			if not _free(x, z, 1.5):
				continue
			var s := rk.randf_range(0.55, 1.15)
			xfs.append(Transform3D(Basis(Vector3.UP, rk.randf() * TAU).scaled(Vector3(s, s * rk.randf_range(0.8, 1.1), s)),
				ground(x, z) - Vector3(0, 0.05, 0)))
			n += 1
		_multi(root, mesh, xfs, ker_mat, true)
	# Sewan grass: tufts in drifts (noise-clumped), dense near the site, sparse far off.
	var grass_mat := Kit.shader(FOLIAGE)
	grass_mat.set_shader_parameter("base_h", 0.0)
	grass_mat.set_shader_parameter("span_h", 0.55)
	grass_mat.set_shader_parameter("amp", 0.04)
	grass_mat.set_shader_parameter("tint", Vector3(1.15, 1.05, 0.9))
	grass_mat.set_shader_parameter("back", 0.8)
	_foliage_mats.append(grass_mat)
	for gname in ["grass_a", "grass_b"]:
		var mesh := _first_mesh(PB + gname + ".glb")
		var xfs := []
		var rg := Kit.rng(gname)
		var n := 0
		var tries := 0
		while n < 1400 and tries < 20000:
			tries += 1
			var a := rg.randf() * TAU
			var d := pow(rg.randf(), 1.8) * 120.0 + 2.5
			var x := cos(a) * d
			var z := sin(a) * d
			var clump := 0.5 + 0.5 * sin(x * 0.31 + 1.3 * sin(z * 0.17)) * sin(z * 0.27 + 0.8)
			if rg.randf() > clump * 1.3 or not _free(x, z, 0.4):
				continue
			var s := rg.randf_range(0.6, 1.25)
			xfs.append(Transform3D(Basis(Vector3.UP, rg.randf() * TAU).scaled(Vector3(s, s, s)), ground(x, z) - Vector3(0, 0.02, 0)))
			n += 1
		_multi(root, mesh, xfs, grass_mat, false)
	# Stones: scattered pebbles and a few fist-sized rocks, more on the gravel than on the pad.
	var stones := Kit.model(PH + "models/namaqualand_stones_01/namaqualand_stones_01_2k.gltf")
	var rocks := Kit.model(PH + "models/namaqualand_rocks_01/namaqualand_rocks_01_2k.gltf")
	var meshes := []
	for src in [stones, rocks]:
		for mi in src.find_children("*", "MeshInstance3D", true, false):
			var sm := (mi as MeshInstance3D).get_active_material(0)
			if sm is StandardMaterial3D:
				sm = (sm as StandardMaterial3D).duplicate()
				(sm as StandardMaterial3D).albedo_color = Color(0.62, 0.66, 0.7)
			meshes.append([(mi as MeshInstance3D).mesh, sm, src == rocks])
	var rs := Kit.rng("stones")
	for k in meshes.size():
		var xfs := []
		var big: bool = meshes[k][2]
		for i in (60 if big else 140):
			var a := rs.randf() * TAU
			var d := pow(rs.randf(), 1.5) * 45.0 + 1.6
			var x := cos(a) * d
			var z := sin(a) * d
			if d < PAD_R * 0.8 and rs.randf() < 0.7:
				continue
			var blocked := false
			for c in _p.get("clear", []):
				if Vector2(x - float(c[0]), z - float(c[1])).length() < float(c[2]):
					blocked = true
			if blocked:
				continue
			var s := rs.randf_range(0.5, 1.1) * (0.9 if big else 0.8)
			xfs.append(Transform3D(Basis.from_euler(Vector3(0, rs.randf() * TAU, 0)).scaled(Vector3(s, s, s)), ground(x, z) - Vector3(0, 0.01, 0)))
		_multi(root, meshes[k][0], xfs, meshes[k][1], false, true)
	stones.free()
	rocks.free()


func grass_mat_hero() -> ShaderMaterial:
	var m := Kit.shader(FOLIAGE)
	m.set_shader_parameter("base_h", 0.0)
	m.set_shader_parameter("span_h", 0.55)
	m.set_shader_parameter("amp", 0.04)
	m.set_shader_parameter("tint", Vector3(1.15, 1.05, 0.9))
	m.set_shader_parameter("back", 0.8)
	_foliage_mats.append(m)
	return m


func _tree(root: Node3D, name: String, at: Vector3, yaw: float, s: float, leaf_mat: Material, bark_mat: Material) -> void:
	var m := Kit.model(PB + name + ("_far" if at.length() > 60.0 else "") + ".glb")
	m.position = ground(at.x, at.z) - Vector3(0, 0.06, 0)
	m.rotation.y = yaw
	m.scale = Vector3.ONE * s
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var inst := mi as MeshInstance3D
		inst.material_override = leaf_mat if inst.name.ends_with("leaves") else bark_mat
		var far := at.length() > 90.0
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if far else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(m)


## Keep plants off the pad, the track, the tripod, the winch, the heap and the cameras' spots.
func _free(x: float, z: float, margin: float) -> bool:
	for c in _p.get("clear", []):
		if Vector2(x - float(c[0]), z - float(c[1])).length() < float(c[2]) + margin:
			return false
	if sqrt(x * x + z * z) < PAD_R + margin:
		return false
	if absf(z - _track_z(x)) < 1.6 + margin and absf(x) < 80.0:
		return false
	for c in [WINCH_AT, SPOIL_AT, TREE_AT]:
		if Vector2(x - c.x, z - c.z).length() < 2.6 + margin:
			return false
	for c in CAMP:
		if Vector2(x - c.x, z - c.z).length() < 4.0 + margin:
			return false
	if Vector2(x - SOCK_AT.x, z - SOCK_AT.z).length() < 2.0 + margin:
		return false
	return true


## Black kites (Milvus migrans) circling high on the thermals: a dark body, long bent wings and a forked tail.
func _kites(root: Node3D) -> void:
	var dark := Kit.mat("#2a221c", 0.8)
	for i in int(_p.get("kites", 3)):
		var k := Node3D.new()
		k.name = "kite_%d" % i
		root.add_child(k)
		Kit.ball(k, 1.0, Vector3.ZERO, dark, 10, Vector3(0.09, 0.08, 0.32))
		for s in [-1.0, 1.0]:
			var w := Node3D.new()
			w.name = "wing_l" if s < 0.0 else "wing_r"
			k.add_child(w)
			Kit.ball(w, 1.0, Vector3(s * 0.32, 0.0, 0.02), dark, 10, Vector3(0.34, 0.025, 0.13)).rotation.y = s * 0.12
			Kit.ball(w, 1.0, Vector3(s * 0.78, 0.04, -0.06), dark, 10, Vector3(0.24, 0.02, 0.09)).rotation.y = -s * 0.35
		Kit.box(k, Vector3(0.16, 0.015, 0.26), Vector3(0, 0, -0.38), dark)
		_kites_n.append(k)


func _shimmer(root: Node3D) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = 34.0
	cm.bottom_radius = 34.0
	cm.height = 8.0
	cm.radial_segments = 96
	cm.rings = 1
	cm.cap_top = false
	cm.cap_bottom = false
	var mi := MeshInstance3D.new()
	mi.name = "shimmer"
	mi.mesh = cm
	mi.position = Vector3(0, 3.6, 0)
	_shimmer_mat = Kit.shader(SHIMMER)
	_shimmer_mat.set_shader_parameter("top", 8.0)
	mi.material_override = _shimmer_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	_shimmer_node = mi


# --- helpers ----------------------------------------------------------------------------------------

func _model(rel: String, mat: Material) -> Node3D:
	var m := Kit.model(rel)
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = mat
	return m


static var _mesh_cache := {}

func _first_mesh(rel: String) -> Mesh:
	if not _mesh_cache.has(rel):
		var m := Kit.model(rel)
		var mi := m.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		_mesh_cache[rel] = mi.mesh
		m.free()
	return _mesh_cache[rel]


func _multi(root: Node3D, mesh: Mesh, xfs: Array, mat: Material, shadows: bool, keep_mat: bool = false) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	if mat != null:
		mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)


func pose(node: Node3D, g: Dictionary, t: float, ctx: Dictionary) -> Dictionary:
	_p = g.get("params", {})
	var gt := node.global_transform
	var content := node.get_node_or_null("content") as Node3D
	if content == null:
		content = node
	for m in _foliage_mats:
		(m as ShaderMaterial).set_shader_parameter("t", t)
	_shimmer_mat.set_shader_parameter("t", t)
	_shimmer_mat.set_shader_parameter("strength", float(_p.get("shimmer", 1.0)))
	# The windsock: heading and strength from the wind keys, a slow hunting swing on top.
	_pose_village_far(t)
	_pose_goggles(gt, t, ctx)
	if _relic != null:
		var ron := false
		for w in (_p.get("relic", {}) as Dictionary).get("on", []):
			if t >= float(w[0]) and t < float(w[1]):
				ron = true
		_relic.visible = ron
	_pose_blast(t)
	var keys: Array = _p.get("wind", [[0.0, 120.0, 0.55]])
	var yaw := float(keys[0][1])
	var strength := float(keys[0][2])
	for i in keys.size():
		var k0: Array = keys[i]
		if float(k0[0]) > t:
			break
		if i == 0:
			continue
		var kp: Array = keys[i - 1]
		var u := Motion.out_back(clampf((t - float(k0[0])) / 1.3, 0.0, 1.0), 1.4)
		yaw = lerpf(float(kp[1]), float(k0[1]), u)
		strength = lerpf(float(kp[2]), float(k0[2]), clampf(u, 0.0, 1.0))
	yaw += 6.0 * sin(t * 0.9) + 2.5 * sin(t * 2.3 + 1.0)
	_sock_pivot.rotation = Vector3(0, deg_to_rad(yaw) + PI / 2, 0)
	_sock_mat.set_shader_parameter("t", t)
	_sock_mat.set_shader_parameter("strength", clampf(strength + 0.08 * sin(t * 1.7), 0.0, 1.0))
	# Kites circle on the thermals over the plain, banking into the turn, a few lazy wingbeats.
	for i in _kites_n.size():
		var k: Node3D = _kites_n[i]
		var r := 18.0 + 9.0 * i
		var w := 0.16 - 0.03 * i
		var a := t * w + 2.1 * i
		var c := Vector3(-14.0 + 12.0 * i, 42.0 + 11.0 * i, -46.0 - 14.0 * i)
		k.position = c + Vector3(cos(a) * r, 2.0 * sin(a * 0.5), sin(a) * r)
		var tangent := Vector3(-sin(a), 0, cos(a))
		k.basis = Basis.looking_at(-tangent, Vector3.UP).rotated(tangent, 0.35) * Basis.IDENTITY.scaled(Vector3.ONE * 2.2)
		var flap := sin(t * 9.0 + i) * maxf(0.0, sin(t * 0.7 + i * 1.3) - 0.6) * 1.6
		(k.get_node("wing_l") as Node3D).rotation.z = 0.12 + flap * 0.5
		(k.get_node("wing_r") as Node3D).rotation.z = -0.12 - flap * 0.5
	_pose_night(gt, t, ctx)
	_pose_park(gt, t, ctx)
	_pose_dune(gt, t, ctx)
	_pose_net(gt, t, ctx)
	_pose_watch(gt, t, ctx)
	_pose_cricket(gt, t, ctx)
	_cv_anchors = _pose_convoy(gt, t)
	_pose_lowering(t)
	_pose_jeep(gt, t, ctx)
	_pose_disguise(ctx, t)
	for aid in _chai:
		var ca = ctx["actor"].call(aid) if ctx.has("actor") else null
		var gl: Node3D = _chai[aid]
		gl.visible = ca != null and ca.visible
		if gl.visible:
			gl.transform = Transform3D(Basis.IDENTITY, gt.affine_inverse() * (ca.bone_world("hand_r") as Vector3) + Vector3(0, -0.03, 0))
	# The hook block swings a little on its falls.
	_hook.rotation = Vector3(0.012 * sin(t * 1.1), 0, 0.016 * sin(t * 0.83 + 0.6))
	# Carried loads: a sandbag rides between the hands; jerrycans hang upright under each grip, lagging a touch.
	for aid in _bags:
		var info: Dictionary = _bags[aid]
		var nodes: Array = info["nodes"]
		var actor = ctx["actor"].call(aid) if ctx.has("actor") else null
		var shown: bool = actor != null and actor.visible
		for n in nodes:
			(n as Node3D).visible = shown
		if not shown:
			continue
		var yaw_a := float(actor.rotation.y)
		var inv := gt.affine_inverse()
		if String(info["what"]) == "jerrycans":
			for i in 2:
				var side := "l" if i == 0 else "r"
				var hand: Vector3 = inv * actor.bone_world("hand_" + side)
				var jc: Node3D = nodes[i]
				var sway := 0.12 * sin(t * 6.2 + i * PI)
				# Handle in the fist: the can's top-centre sits just under the hand, its broad side along the walk.
				jc.transform = Transform3D((Basis(Vector3.UP, yaw_a + PI / 2) * Basis(Vector3.RIGHT, sway)).scaled(Vector3.ONE * 0.72), hand + Vector3(0, -0.37, 0))
		else:
			var hl: Vector3 = actor.bone_world("hand_l")
			var hr: Vector3 = actor.bone_world("hand_r")
			var local := inv * ((hl + hr) * 0.5)
			(nodes[0] as Node3D).transform = Transform3D((Basis(Vector3.UP, yaw_a) * Basis(Vector3.RIGHT, -0.25)).scaled(Vector3(1.25, 1.5, 1.25)), local + Vector3(0, -0.1, 0))
	# Era: December 1995 inside the y1995 windows, May 1998 otherwise.
	var is95 := false
	for w in _p.get("y1995", []):
		if t >= float(w[0]) and t < float(w[1]):
			is95 = true
	_g95.visible = is95
	_g98.visible = not is95
	for w in (_p.get("blast", {}) as Dictionary).get("on", []):
		if t >= float(w[0]) and t < float(w[1]):
			_g98.visible = false
	if is95:
		_pose_leave(t)
		_pose_shovels(gt, t, ctx)
	if is95:
		# The crane lowers the casing: its foot from 0.9 m above the collar to 1.4 m down the shaft, eased; it sways
		# a touch on the slings.
		var lw: Dictionary = _p.get("lower", {})
		var k := Motion.in_out(Motion.seg(t, float(lw.get("from", 0.0)), float(lw.get("to", 1.0))))
		var foot_y := lerpf(1.12, -1.2, k)
		var hook := Vector3(0.0, foot_y + 6.0 + 0.66, 0.0)
		# Later (the call-off), the casing is long since down the shaft and the hook hangs clear, empty.
		var done := t > float(lw.get("to", 1.0)) + 1.0
		for ci in _crane_hook.get_child_count():
			(_crane_hook.get_child(ci) as Node3D).visible = ci == 0 or not done
		if done:
			hook = _crane_tip - Vector3(0, 2.2, 0)
		# Days later (the call-off) the crane has gone from the site.
		_crane_rig.visible = t < float(lw.get("to", 1.0)) + 3.0
		_crane_hook.position = hook + Vector3(0.015 * sin(t * 1.3), 0, 0.012 * sin(t * 1.7 + 1.0))
		_crane_hook.rotation = Vector3(0.006 * sin(t * 1.7), 0, -0.006 * sin(t * 1.3))
		var top := hook + Vector3(0, 0.4, 0)
		var d := _crane_tip - top
		_crane_cable.transform = Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())) * Basis.from_scale(Vector3(1, d.length(), 1)), (top + _crane_tip) * 0.5)
		# The guide's hands ride on the casing, either side of it toward him; the scientist holds his clipboard.
		var inv := gt.affine_inverse()
		var gd: Dictionary = _p.get("guide", {})
		var ga = ctx["actor"].call(String(gd.get("actor", ""))) if gd.has("actor") and ctx.has("actor") else null
		if ga != null:
			var me: Vector3 = inv * (ga as Node3D).global_position
			var to_me := Vector3(me.x, 0, me.z).normalized()
			var side := Vector3(-to_me.z, 0, to_me.x)
			var sh: Vector3 = inv * ga.bone_world("spine_03")
			for k2 in 2:
				var sgn := -1.0 if k2 == 0 else 1.0
				var on_pipe := (to_me * 0.27 + side * sgn * 0.14) + Vector3(0, sh.y - 0.12 + 0.04 * sgn, 0)
				ga.aim_hand("l" if k2 == 0 else "r", gt * on_pipe, 1.0)
		var cd: Dictionary = _p.get("clipboard", {})
		var ca = ctx["actor"].call(String(cd.get("actor", ""))) if cd.has("actor") and ctx.has("actor") else null
		if ca != null and _clip != null:
			var cf := Vector3(sin(float(ca.rotation.y)), 0, cos(float(ca.rotation.y)))
			var chest: Vector3 = inv * ca.bone_world("spine_03")
			var hold := chest + cf * 0.22 + Vector3(0, -0.06, 0)
			ca.aim_hand("l", gt * (hold + Vector3(-cf.z, 0, cf.x) * 0.08), 1.0)
			_clip.transform = Transform3D(Basis(Vector3.UP, float(ca.rotation.y)) * Basis(Vector3.RIGHT, -0.9), hold)
	# The work lamp swings a little on its cable (the cage's shadow sweeps the rock).
	_lamp.rotation = Vector3(0.05 * sin(t * 2.6 + 0.4), 0, 0.07 * sin(t * 2.1))
	# The leak: each source swells a drop, lets it go, it falls (free fall, stretching as it speeds up) and
	# splashes (a ripple ring and a little spray). Source 0's drop lands on the lid at params.drip.
	var drip_t := float(_p.get("drip", -100.0))
	for i in _drips.size():
		var d: Dictionary = _drips[i]
		var per := float(d["period"])
		var fall := float(d["fall"])
		var land := float(d["phase"]) if i > 0 else drip_t
		# The latest landing at or before t + fall (so a drop in flight is the next one to land).
		var n := floorf((t + fall - land) / per)
		var next_land := land + per * n
		var last_land := next_land if next_land <= t else next_land - per
		var drop: MeshInstance3D = d["drop"]
		var from: Vector3 = d["from"]
		var to: Vector3 = d["to"]
		var ft := t - (next_land - fall)     # 0..fall while falling; negative while it swells
		drop.visible = ft > -0.45 and ft < fall
		if drop.visible:
			if ft < 0.0:
				var sw := clampf(1.0 + ft / 0.45, 0.25, 1.0)
				drop.position = from - Vector3(0, 0.012 * sw, 0)
				drop.scale = Vector3(sw, sw * 1.2, sw)
			else:
				var k := ft / fall
				drop.position = from.lerp(to, k * k)
				var v := 9.81 * ft
				drop.scale = Vector3(0.7, 1.0 + v * 0.9, 0.7)
		var sage := t - last_land
		var ring: MeshInstance3D = d["ring"]
		ring.visible = sage >= 0.0 and sage < 0.7
		if ring.visible:
			var rr := 0.015 + (0.12 if to.y > -SHAFT_D + 0.5 else 0.2) * Motion.out_cubic(clampf(sage / 0.6, 0.0, 1.0))
			ring.position = to + Vector3(0, 0.002, 0)
			ring.scale = Vector3(rr, 0.004, rr)
			(d["ring_mat"] as StandardMaterial3D).albedo_color.a = 0.22 * (1.0 - sage / 0.7)
		for sp in d["spray"]:
			var b: MeshInstance3D = sp[0]
			var k2 := clampf(sage / 0.3, 0.0, 1.0)
			b.visible = sage >= 0.0 and sage < 0.3
			if b.visible:
				var a := float(sp[1])
				var h := float(sp[2])
				b.position = to + Vector3(cos(a) * 0.07 * k2 * h, 0.08 * h * sin(k2 * PI), sin(a) * 0.07 * k2 * h)
				b.scale = Vector3.ONE * maxf(1.0 - k2, 0.05)
	var dv := _dive(t)
	_dive_light.light_energy = 0.9 if dv["on"] else 0.0
	if dv["on"]:
		_dive_light.position = (dv["cam"] as Vector3) + Vector3(0, -0.6, 0)
	var apex := gt * Vector3(0, TRIPOD_H, 0)
	var extra := {}
	if dv.has("cam"):
		var axis := ((dv["cam"] as Vector3) - (dv["look"] as Vector3)).normalized()
		extra = {"dive_cam": gt * (dv["cam"] as Vector3), "dive_look": gt * (dv["look"] as Vector3), "dive_count": gt * (dv["count"] as Vector3),
			"dive_face": gt * ((dv["count"] as Vector3) + axis)}
	else:
		extra = {"dive_cam": gt * Vector3(0.2, 2.4, 0), "dive_look": gt * Vector3(0.1, -8, 0), "dive_count": gt * Vector3(0.1, 0.5, 0),
			"dive_face": gt * Vector3(0.1, 1.5, 0)}
	extra["bottom"] = gt * Vector3(0, -SHAFT_D + 0.8, 0)
	extra.merge(_cv_anchors)
	# The jeep (its cab, at the driver's head height), for cameras that track it.
	if _jeep != null:
		extra["jeep"] = gt * (_jeep.position + Vector3(0, 1.25, 0))
	extra["canister"] = gt * Vector3(0, -SHAFT_D + 0.08 + CAN_H * 0.6, 0)
	extra["lid"] = gt * Vector3(0, -SHAFT_D + 0.08 + CAN_H, 0)
	return extra.merged({"plate": gt * Vector3(0, 0.26, 0), "apex": apex, "winch": gt * (WINCH_AT + Vector3(0, 0.8, 0)),
		"spoil": gt * (SPOIL_AT + Vector3(0, 0.8, 0)), "tree": gt * (TREE_AT + Vector3(0, 3.0, 0)),
		"camp": gt * (CAMP[0] as Vector3), "windsock": gt * (SOCK_AT + Vector3(0, SOCK_H, 0)),
		"track": gt * Vector3(0, 0, _track_z(0.0))})
