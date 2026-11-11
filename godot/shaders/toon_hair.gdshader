// Toon hair shell: a flat colour with painted lighter strands, either
// radiating from the crown (mode 0) or combed straight back (mode 1).
shader_type spatial;
render_mode cull_disabled;

uniform vec3 color : source_color = vec3(0.42, 0.26, 0.14);
uniform float strands = 0.22;
uniform int mode = 0;
uniform float count = 9.0;
uniform float radius = 0.35;

varying vec3 lp;

void vertex() {
	lp = VERTEX / radius;
}

void fragment() {
	vec3 p = normalize(lp);
	float line;
	if (mode == 0) {
		float phi = atan(p.x, p.z);
		float theta = acos(clamp(p.y, -1.0, 1.0));
		float u = phi / 6.2831853 * count + theta * 0.9;
		float d = abs(fract(u) - 0.5);
		line = 1.0 - smoothstep(0.03, 0.06 + fwidth(u), d);
		line *= smoothstep(0.15, 0.5, theta);
	} else {
		float u = p.x * count * 0.5 + p.z * 0.15;
		float d = abs(fract(u) - 0.5);
		line = 1.0 - smoothstep(0.04, 0.07 + fwidth(u), d);
	}
	vec3 c = color;
	if (!FRONT_FACING) {
		c *= 0.55;
		line = 0.0;
	}
	ALBEDO = mix(c, mix(c, vec3(1.0), 0.45), line * strands / 0.22 * 0.6);
	ROUGHNESS = 0.55;
	SPECULAR = 0.35;
}
