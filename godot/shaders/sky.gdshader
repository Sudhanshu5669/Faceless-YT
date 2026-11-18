// TownForge sky: gradient + stars + procedural clouds + up to 6 sky bodies
// (sun, moon, planets). Everything is driven by uniforms from look.gd, so a
// look can ask for a giant red moon or two suns without new code.
shader_type sky;

uniform vec3 top_color : source_color = vec3(0.29, 0.47, 0.72);
uniform vec3 horizon_color : source_color = vec3(0.77, 0.84, 0.9);
uniform float stars = 0.0;
uniform vec3 star_color : source_color = vec3(1.0);
uniform float clouds = 0.0;
uniform vec3 cloud_color : source_color = vec3(1.0);
uniform vec3 cloud_shadow : source_color = vec3(0.6);
uniform float cloud_speed = 0.006;
// An equirectangular star map (space shots): added over everything when panorama_energy > 0.
uniform sampler2D panorama : source_color, filter_linear_mipmap, repeat_enable;
uniform float panorama_energy = 0.0;
uniform float panorama_yaw = 0.0;
uniform float panorama_tilt = 0.0;
// Scene time (set by main.gd), not engine TIME: a shot looks the same whatever was rendered before it.
global uniform float scene_time;

uniform int body_count = 0;
uniform vec4 body_dir[6];    // xyz = direction to body, w = angular radius (radians)
uniform vec4 body_color[6];  // rgb = disc colour (HDR), a = kind (0 sun, 1 moon, 2 planet)
uniform vec4 body_glow[6];   // rgb = halo colour, a = halo strength

// Sine-free hash (Dave Hoskins): sin()-based hashes lose precision on GPUs
// and turn smooth noise into visible blocks.
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y;
	vec3 col = mix(horizon_color, top_color, smoothstep(0.0, 1.0, pow(max(h, 0.0), 0.45)));

	if (panorama_energy > 0.0) {
		vec3 q = d;
		float ct = cos(panorama_tilt), st = sin(panorama_tilt);
		q = vec3(q.x, q.y * ct - q.z * st, q.y * st + q.z * ct);
		vec2 uv = vec2(atan(q.x, -q.z) / 6.2831853 + 0.5 + panorama_yaw / 6.2831853, acos(clamp(q.y, -1.0, 1.0)) / 3.14159265);
		col += texture(panorama, uv).rgb * panorama_energy;
	}

	if (stars > 0.0 && h > 0.0) {
		vec2 uv = vec2(atan(d.x, d.z), asin(clamp(h, -1.0, 1.0))) * 90.0;
		vec2 cell = floor(uv);
		float r = hash(cell);
		if (r > 0.982) {
			vec2 off = vec2(hash(cell + 3.1), hash(cell + 7.7)) * 0.6 + 0.2;
			float dist = length(fract(uv) - off);
			float twinkle = 0.75 + 0.25 * sin(scene_time * (1.5 + r * 6.0) + r * 100.0);
			float size = 0.06 + 0.08 * hash(cell + 1.7);
			col += star_color * (1.0 - smoothstep(0.0, size, dist)) * stars * twinkle * smoothstep(0.0, 0.2, h) * 2.0;
		}
	}

	for (int i = 0; i < body_count; i++) {
		vec3 bd = normalize(body_dir[i].xyz);
		float rad = body_dir[i].w;
		float ang = acos(clamp(dot(d, bd), -1.0, 1.0));
		float kind = body_color[i].a;
		vec3 bc = body_color[i].rgb;
		float disc = 1.0 - smoothstep(rad * 0.96, rad, ang);
		if (disc > 0.0) {
			vec3 u = normalize(cross(bd, abs(bd.y) > 0.99 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0)));
			vec3 v = cross(u, bd);
			vec2 p = vec2(dot(d, u), dot(d, v)) / max(sin(rad), 0.0001);
			float limb = sqrt(max(0.0, 1.0 - dot(p, p)));
			vec3 surface = bc;
			if (kind > 0.5 && kind < 1.5) {
				surface = bc * (0.72 + 0.4 * fbm(p * 3.0 + 11.0)) * (0.6 + 0.4 * limb);
			} else if (kind > 1.5) {
				float bands = 0.75 + 0.25 * sin(p.y * 11.0 + fbm(p * 2.5) * 5.0);
				surface = bc * bands * (0.35 + 0.65 * limb);
			}
			col = mix(col, surface, disc);  // opaque: a black sun disc hides what is behind it
		}
		// Halo only outside the disc, so a dark disc (eclipse) stays dark.
		col += body_glow[i].rgb * body_glow[i].a * exp(-max(ang - rad, 0.0) / (rad * 1.2 + 0.02)) * 0.5 * (1.0 - disc);
	}

	if (clouds > 0.0 && h > 0.0) {
		vec2 cp = d.xz / (h + 0.08) * 0.6 + vec2(scene_time * cloud_speed, scene_time * cloud_speed * 0.4);
		float n = fbm(cp);
		float cover = smoothstep(1.0 - clouds, 1.0 - clouds + 0.35, n);
		vec3 cc = mix(cloud_shadow, cloud_color, smoothstep(0.3, 0.9, fbm(cp * 2.0 + 5.0)));
		col = mix(col, cc, cover * smoothstep(0.0, 0.12, h));
	}

	COLOR = col;
}
