// Toon head: a white sphere with a flat, drawn face (brows, eyes, mouth and
// extras) painted from signed distance fields in the head's local space.
// The face looks down +Z. Expressions are only uniform values, so a face swap
// is instant and costs nothing (scripts/actors/toon.gd sets them from
// library/toon/faces.json).
shader_type spatial;
render_mode cull_back;

uniform float radius = 0.35;
uniform vec3 skin : source_color = vec3(0.95, 0.95, 0.94);
uniform vec3 ink : source_color = vec3(0.30, 0.30, 0.31);
// A little self-light keeps the head reading bright white, as in the style.
uniform float glow = 0.16;
// Eye styles: 0 lazy, 1 dot, 2 wide, 3 happy, 4 closed, 5 x, 6 star, 7 heart, 8 sleepy, 9 none.
uniform int eye_l = 0;
uniform int eye_r = 0;
uniform vec2 look = vec2(0.0);
uniform float eye_size = 1.0;
uniform float eye_y = 0.0;
uniform float lid = 0.0;
uniform float lid_tilt = 0.0;
uniform float brows = 1.0;
uniform float brow_tilt = 0.0;
uniform float brow_y = 0.0;
// Mouth styles: 0 smirk, 1 smile, 2 flat, 3 frown, 4 open, 5 grin, 6 laugh, 7 wavy, 8 o, 9 none.
uniform int mouth = 2;
uniform float mouth_x = 0.0;
uniform float mouth_w = 1.0;
uniform float sweat = 0.0;
uniform float blush = 0.0;
uniform float tears = 0.0;
// Character features (not expressions): a moustache in the hair colour.
uniform float mustache = 0.0;
uniform vec3 mustache_color : source_color = vec3(0.1, 0.1, 0.11);
// A short trimmed beard along the jaw and chin, in beard_color (drawn under the mouth).
uniform float beard = 0.0;
uniform vec3 beard_color : source_color = vec3(0.9, 0.9, 0.9);

const vec3 MOUTH_IN = vec3(0.20, 0.13, 0.13);
const vec3 TONGUE = vec3(0.93, 0.50, 0.56);
const vec3 TEETH = vec3(0.98, 0.98, 0.96);
const vec3 SWEAT = vec3(0.45, 0.72, 1.0);
const vec3 BLUSH = vec3(1.0, 0.55, 0.62);
const vec3 STAR = vec3(1.0, 0.82, 0.22);
const vec3 HEART = vec3(1.0, 0.27, 0.40);
const vec3 TEAR = vec3(0.55, 0.88, 1.0);

varying vec3 lp;

void vertex() {
	lp = VERTEX / radius;
}

float sd_seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

float sd_ellipse(vec2 p, vec2 r) {
	float k0 = length(p / r);
	float k1 = length(p / (r * r));
	return k0 * (k0 - 1.0) / max(k1, 1e-5);
}

// Arc centred on +y with half-aperture given by sc = (sin, cos), radius ra, thickness rb.
float sd_arc(vec2 p, vec2 sc, float ra, float rb) {
	p.x = abs(p.x);
	return ((sc.y * p.x > sc.x * p.y) ? length(p - sc * ra) : abs(length(p) - ra)) - rb;
}

float sd_star5(vec2 p, float r, float rf) {
	const vec2 k1 = vec2(0.809016994375, -0.587785252292);
	const vec2 k2 = vec2(-k1.x, k1.y);
	p.x = abs(p.x);
	p -= 2.0 * max(dot(k1, p), 0.0) * k1;
	p -= 2.0 * max(dot(k2, p), 0.0) * k2;
	p.x = abs(p.x);
	p.y -= r;
	vec2 ba = rf * vec2(-k1.y, k1.x) - vec2(0.0, 1.0);
	float h = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
	return length(p - ba * h) * sign(p.y * ba.x - p.x * ba.y);
}

float sd_heart(vec2 p) {
	p.x = abs(p.x);
	if (p.y + p.x > 1.0) {
		return sqrt(dot(p - vec2(0.25, 0.75), p - vec2(0.25, 0.75))) - sqrt(2.0) / 4.0;
	}
	vec2 a = p - vec2(0.0, 1.0);
	vec2 b = p - 0.5 * max(p.x + p.y, 0.0);
	return sqrt(min(dot(a, a), dot(b, b))) * sign(p.x - p.y);
}

float cover(float d) {
	float aa = max(fwidth(d) * 0.75, 1e-4);
	return 1.0 - smoothstep(-aa, aa, d);
}

vec2 rot(vec2 p, float a) {
	float c = cos(a), s = sin(a);
	return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

// side: +1 for the eye at +x (the character's left), -1 at -x.
void paint_eye(inout vec3 col, vec2 p, int style, float side) {
	vec2 c = vec2(0.40 * side, 0.06 + eye_y);
	vec2 q = p - c;
	float s = eye_size;
	if (style == 0) {
		// Lazy: a half-lidded half disc under a flat (or tilted) lid line.
		float re = 0.15 * s;
		vec2 pq = q - look * 0.06;
		float top = re * (0.18 - lid) + q.x * lid_tilt * -side;
		float d = max(length(pq) - re, q.y - top);
		col = mix(col, ink, cover(d));
		// The lid line follows the tilt.
		vec2 a = vec2(-re * 1.15, re * (0.18 - lid) + re * 1.15 * lid_tilt * side);
		vec2 b = vec2(re * 1.15, re * (0.18 - lid) - re * 1.15 * lid_tilt * side);
		float lidl = sd_seg(q, a, b) - 0.026 * s;
		col = mix(col, ink, cover(lidl));
	} else if (style == 1) {
		col = mix(col, ink, cover(sd_ellipse(q - look * 0.05, vec2(0.075, 0.1) * s)));
	} else if (style == 2) {
		float ring = abs(length(q) - 0.21 * s) - 0.03 * s;
		col = mix(col, ink, cover(ring));
		col = mix(col, ink, cover(length(q - look * 0.09) - 0.05 * s));
	} else if (style == 3) {
		float d = max(abs(length(q + vec2(0.0, 0.05)) - 0.12 * s) - 0.028 * s, -(q.y + 0.03));
		col = mix(col, ink, cover(d));
	} else if (style == 4) {
		col = mix(col, ink, cover(sd_seg(q, vec2(-0.13, 0.0) * s, vec2(0.13, 0.0) * s) - 0.028 * s));
	} else if (style == 5) {
		float d = min(sd_seg(q, vec2(-0.1, -0.1) * s, vec2(0.1, 0.1) * s),
			sd_seg(q, vec2(-0.1, 0.1) * s, vec2(0.1, -0.1) * s)) - 0.03 * s;
		col = mix(col, ink, cover(d));
	} else if (style == 6) {
		float d = sd_star5(q, 0.17 * s, 0.45);
		col = mix(col, ink, cover(d - 0.02));
		col = mix(col, STAR, cover(d));
	} else if (style == 7) {
		float d = sd_heart((q + vec2(0.0, 0.12 * s)) / (0.24 * s)) * 0.24 * s;
		col = mix(col, HEART, cover(d));
	} else if (style == 8) {
		// Sleepy: a lower arc (eyes closed, relaxed).
		float d = max(abs(length(q - vec2(0.0, 0.07)) - 0.12 * s) - 0.026 * s, q.y - 0.02);
		col = mix(col, ink, cover(d));
	}
}

void paint_mouth(inout vec3 col, vec2 p) {
	vec2 m = vec2(mouth_x, -0.30);
	vec2 q = p - m;
	float w = mouth_w;
	if (mouth == 0) {
		// Smirk: a short arc pushed to one side and tilted up.
		vec2 r = rot(q - vec2(0.06, 0.0), -0.32);
		vec2 a = r - vec2(0.0, 0.26);
		a.y = -a.y;
		col = mix(col, ink, cover(sd_arc(a, vec2(sin(0.42 * w), cos(0.42 * w)), 0.26, 0.024)));
	} else if (mouth == 1) {
		vec2 a = q - vec2(0.0, 0.24);
		a.y = -a.y;
		col = mix(col, ink, cover(sd_arc(a, vec2(sin(0.6 * w), cos(0.6 * w)), 0.24, 0.025)));
	} else if (mouth == 2) {
		col = mix(col, ink, cover(sd_seg(q, vec2(-0.1 * w, 0.0), vec2(0.1 * w, 0.0)) - 0.024));
	} else if (mouth == 3) {
		vec2 a = q + vec2(0.0, 0.22);
		col = mix(col, ink, cover(sd_arc(a, vec2(sin(0.5 * w), cos(0.5 * w)), 0.22, 0.025)));
	} else if (mouth == 4) {
		float d = sd_ellipse(q, vec2(0.085 * w, 0.11));
		col = mix(col, MOUTH_IN, cover(d));
		float t = max(d, length(q - vec2(0.0, -0.12)) - 0.075);
		col = mix(col, TONGUE, cover(t));
	} else if (mouth == 5) {
		vec2 h = vec2(0.22 * w, 0.075);
		vec2 dq = abs(q) - h + 0.03;
		float box = length(max(dq, 0.0)) + min(max(dq.x, dq.y), 0.0) - 0.03;
		col = mix(col, ink, cover(box));
		col = mix(col, TEETH, cover(box + 0.022));
		float lines = abs(q.y) - 0.006;
		float teeth_x = abs(fract(q.x / 0.07 + 0.5) - 0.5) * 0.07 - 0.006;
		float grid = max(min(lines, teeth_x), box + 0.022);
		col = mix(col, ink, cover(grid));
	} else if (mouth == 6) {
		float d = max(sd_ellipse(q - vec2(0.0, 0.04), vec2(0.17 * w, 0.17)), q.y - 0.04);
		col = mix(col, MOUTH_IN, cover(d));
		float t = max(d, length(q - vec2(0.0, -0.15)) - 0.09);
		col = mix(col, TONGUE, cover(t));
	} else if (mouth == 7) {
		float d = abs(q.y - 0.022 * sin(q.x * 42.0)) - 0.02;
		d = max(d, abs(q.x) - 0.14 * w);
		col = mix(col, ink, cover(d));
	} else if (mouth == 8) {
		col = mix(col, ink, cover(abs(length(q) - 0.05) - 0.022));
	}
}

void fragment() {
	vec3 n = normalize(lp);
	vec2 p = lp.xy;
	vec3 col = skin;
	if (lp.z > 0.0) {
		if (blush > 0.0) {
			for (float s = -1.0; s <= 1.0; s += 2.0) {
				float d = sd_ellipse(p - vec2(0.50 * s, -0.12), vec2(0.13, 0.06));
				col = mix(col, BLUSH, (1.0 - smoothstep(-0.04, 0.03, d)) * 0.55 * blush);
			}
		}
		if (brows > 0.0) {
			for (float s = -1.0; s <= 1.0; s += 2.0) {
				vec2 c = vec2(0.38 * s, 0.40 + brow_y);
				// Tilt: positive raises the inner ends (worried), negative lowers them (angry).
				vec2 a = c + vec2(-0.16 * s, 0.16 * brow_tilt);
				vec2 b = c + vec2(0.16 * s, -0.16 * brow_tilt);
				col = mix(col, ink, cover(sd_seg(p, a, b) - 0.045));
			}
		}
		paint_eye(col, p, eye_r, -1.0);
		paint_eye(col, p, eye_l, 1.0);
		if (tears > 0.0) {
			for (float s = -1.0; s <= 1.0; s += 2.0) {
				float d = sd_seg(p, vec2(0.40 * s, -0.06), vec2(0.43 * s, -0.55)) - 0.045 * tears;
				col = mix(col, TEAR, cover(d));
			}
		}
		if (beard > 0.0) {
			// The jawline rises toward the ears; the beard fills everything under it on the front half.
			float jaw = -0.24 + 0.34 * smoothstep(0.42, 0.92, abs(lp.x));
			float d = lp.y - jaw;
			float fuzz = 0.025 * sin(lp.x * 60.0) * sin(lp.y * 47.0);
			float cov = (1.0 - smoothstep(-0.02, 0.02, d + fuzz)) * smoothstep(-0.25, 0.05, lp.z);
			vec3 bc = beard_color * (0.9 + 0.1 * sin(lp.x * 90.0 + lp.y * 40.0));
			col = mix(col, bc, cov);
			col = mix(col, beard_color * 0.72, (1.0 - smoothstep(0.0, 0.025, abs(d + fuzz))) * smoothstep(-0.25, 0.05, lp.z) * 0.6);
		}
		paint_mouth(col, p);
		if (mustache > 0.0) {
			float d = 1e9;
			for (float s = -1.0; s <= 1.0; s += 2.0) {
				vec2 q = rot(p - vec2(0.085 * s + mouth_x * 0.5, -0.185), 0.28 * s);
				d = min(d, sd_ellipse(q, vec2(0.11, 0.052)));
			}
			col = mix(col, mustache_color, cover(d));
		}
		if (sweat > 0.0) {
			vec2 q = p - vec2(0.62, 0.24);
			float k = clamp(q.y / 0.2 + 0.5, 0.0, 1.0);
			float d = length(vec2(q.x / max(1.0 - k * 0.9, 0.05), q.y)) - 0.075;
			col = mix(col, SWEAT, cover(d));
			col = mix(col, vec3(1.0), cover(length(q - vec2(-0.025, -0.02)) - 0.018));
		}
	}
	ALBEDO = col;
	EMISSION = col * glow;
	ROUGHNESS = 0.62;
	SPECULAR = 0.3;
}
