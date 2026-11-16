shader_type spatial;

varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

float grain(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = local_position.xz + local_position.y * vec2(0.41, 0.72);
	float fine = grain(floor(uv * 530.0));
	float coarse = grain(floor(uv * 170.0));
	float fleck = smoothstep(0.86, 1.0, coarse) * fine;
	ALBEDO = vec3(0.042, 0.051, 0.049) + fine * 0.012 + fleck * 0.037;
	ROUGHNESS = 0.29 + coarse * 0.12;
	SPECULAR = 0.42;
}
