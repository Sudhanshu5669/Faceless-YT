// Stage floors and walls: procedural patterns in the toon diorama style.
// pattern: 0 checker, 1 tiles, 2 grid (glowing lines), 3 wood, 4 plain, 5 carpet, 6 road,
//          10 panels, 11 brick. Coordinates are local metres (axis = which plane).
shader_type spatial;

uniform int pattern = 0;
uniform vec3 color_a : source_color = vec3(0.23, 0.16, 0.48);
uniform vec3 color_b : source_color = vec3(0.16, 0.11, 0.36);
uniform vec3 line_color : source_color = vec3(0.37, 0.89, 1.0);
uniform float cell = 1.0;
uniform float line_glow = 2.5;
uniform bool vertical = false;
uniform float foot_z = -3.6;

varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

float grid_line(vec2 uv, float w) {
	vec2 g = abs(fract(uv - 0.5) - 0.5) / max(fwidth(uv), vec2(1e-4));
	float l = min(g.x, g.y);
	return 1.0 - smoothstep(w, w + 1.0, l);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = (vertical ? lp.xy : lp.xz) / cell;
	vec3 col = color_a;
	vec3 em = vec3(0.0);
	float rough = 0.55;
	if (pattern == 0) {
		vec2 c = floor(uv);
		col = mod(c.x + c.y, 2.0) < 1.0 ? color_a : color_b;
		rough = 0.35;
	} else if (pattern == 1) {
		col = mix(color_a, color_b, hash(floor(uv)) * 0.35);
		col = mix(col, color_b * 0.6, grid_line(uv, 0.8));
		rough = 0.3;
	} else if (pattern == 2) {
		col = color_b * 0.6;
		float l = grid_line(uv, 0.6);
		em = line_color * l * line_glow;
		col = mix(col, line_color, l);
		rough = 0.25;
	} else if (pattern == 3) {
		vec2 p = vec2(uv.x * 0.25, uv.y);
		float row = floor(p.y);
		p.x += hash(vec2(row, 1.0)) * 3.0;
		float plank = floor(p.x);
		col = mix(color_a, color_b, hash(vec2(plank, row)) * 0.6);
		col *= 0.92 + 0.08 * sin(uv.x * 9.0 + hash(vec2(row, plank)) * 6.0);
		float seam = max(1.0 - smoothstep(0.0, 0.03, abs(fract(p.y) - 0.0)), 1.0 - smoothstep(0.0, 0.012, abs(fract(p.x))));
		col = mix(col, color_b * 0.5, seam * 0.7);
	} else if (pattern == 4) {
		col = color_a;
	} else if (pattern == 5) {
		col = mix(color_a, color_b, step(0.5, fract((uv.x + uv.y) * 2.0)) * 0.25);
		rough = 0.9;
	} else if (pattern == 6) {
		// Dusty Indian street: worn asphalt (color_a), a paved footpath strip
		// along the back (color_b) with a painted kerb, scattered patches.
		vec2 w = vertical ? lp.xy : lp.xz;
		float n = hash(floor(w * 3.0)) * 0.5 + hash(floor(w * 0.7)) * 0.5;
		col = color_a * (0.85 + 0.3 * n);
		float walk = step(w.y, foot_z);
		vec2 tile = w / 0.6;
		vec3 paving = mix(color_b, color_b * 0.8, step(0.5, fract((floor(tile.x) + floor(tile.y)) * 0.5)));
		col = mix(col, paving, walk);
		float kerb = step(abs(w.y - foot_z), 0.12);
		float stripe = step(0.5, fract(w.x * 0.8));
		col = mix(col, mix(vec3(0.95, 0.85, 0.2), vec3(0.12), stripe), kerb);
		rough = 0.8;
	} else if (pattern == 10) {
		vec2 p = uv * vec2(0.5, 0.33);
		col = mix(color_a, color_a * 1.15, step(0.5, fract(floor(p.x) * 0.5)));
		col = mix(col, color_b, grid_line(p, 0.7));
	} else if (pattern == 11) {
		vec2 p = uv * vec2(2.0, 4.0);
		p.x += step(1.0, mod(floor(p.y), 2.0)) * 0.5;
		col = mix(color_a, color_a * (0.85 + hash(floor(p)) * 0.3), 1.0);
		col = mix(col, color_b * 0.6, grid_line(p, 0.6));
	}
	ALBEDO = col;
	EMISSION = em;
	ROUGHNESS = rough;
	SPECULAR = 0.35;
}
