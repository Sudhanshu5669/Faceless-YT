extends RefCounted
## Lining, wet invert, and steel ribs used by the Silkyara tunnel shots.

const ROCK_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 tint : source_color = vec3(0.46, 0.44, 0.41);
uniform float bump = 1.0;
uniform float wet = 1.0;
uniform float scale = 1.0;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
//NOISE
void fragment() {
	vec3 p = wp * scale;
	float base = fbm(p * 1.3);
	float fine = fbm(p * 7.0);
	float streak = smoothstep(0.5, 0.78, n3(vec3(p.x * 0.3, p.y * 0.1, p.z * 1.5) + 7.3)) * wet;
	vec3 col = tint * (0.66 + base * 0.56 + fine * 0.14);
	col = mix(col, col * vec3(0.42, 0.40, 0.39), streak * 0.75);
	ALBEDO = col;
	ROUGHNESS = mix(0.97, 0.55, streak);
	SPECULAR = 0.2;
	float e = 0.05;
	float c0 = fbm(p * 3.1);
	vec3 g = vec3(fbm((p + vec3(e, 0.0, 0.0)) * 3.1) - c0, fbm((p + vec3(0.0, e, 0.0)) * 3.1) - c0,
		fbm((p + vec3(0.0, 0.0, e)) * 3.1) - c0) / e;
	NORMAL = normalize(NORMAL - (VIEW_MATRIX * vec4(g, 0.0)).xyz * 0.075 * bump);
}
"""

const FLOOR_SHADER := """
shader_type spatial;
uniform vec3 origin;
uniform bool section_axis = false;
varying vec3 lp;
void vertex() {
	vec3 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz - origin;
	lp = section_axis ? p.zyx : p;
}
//NOISE
void fragment() {
	float n = fbm(vec3(lp.x, 0.0, lp.z) * 0.55);
	float fine = fbm(vec3(lp.x, 0.0, lp.z) * 5.0 + 3.0);
	float rut = 1.0 - smoothstep(0.18, 0.5, abs(abs(lp.x + 0.5) - 1.05));
	float water = smoothstep(0.53, 0.6, fbm(vec3(lp.x * 0.5, 3.0, lp.z * 0.22)) + rut * 0.1);
	vec3 mud = vec3(0.115, 0.096, 0.082) * (0.75 + n * 0.4 + fine * 0.25);
	mud = mix(mud, mud * 0.66, rut * 0.7);
	ALBEDO = mix(mud, vec3(0.03, 0.028, 0.026), water);
	ROUGHNESS = mix(0.9 - rut * 0.15, 0.13, water);
	SPECULAR = mix(0.3, 0.55, water);
	float e = 0.04;
	vec3 q = vec3(lp.x, 0.0, lp.z);
	float c0 = fbm(q * 2.6);
	vec3 g = vec3(fbm((q + vec3(e, 0.0, 0.0)) * 2.6) - c0, 0.0, fbm((q + vec3(0.0, 0.0, e)) * 2.6) - c0) / e;
	NORMAL = normalize(NORMAL - (VIEW_MATRIX * vec4(section_axis ? g.zyx : g, 0.0)).xyz * 0.022 * (1.0 - water));
}
"""

static func rib_mesh(radius: float, spring: float, segments: int, half: bool = false) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := []
	pts.append([Vector3(radius - 0.02, 0.0, 0.0), Vector3(-1, 0, 0)])
	var end := segments / 2 if half else segments
	for i in end + 1:
		var th := float(i) / segments * PI
		pts.append([Vector3(cos(th) * (radius - 0.02), spring + sin(th) * (radius - 0.02), 0.0), Vector3(-cos(th), -sin(th), 0)])
	if not half:
		pts.append([Vector3(-radius + 0.02, 0.0, 0.0), Vector3(1, 0, 0)])
	var w := 0.085   # half width along the bore
	var d := 0.17    # how far it stands off the lining
	for i in pts.size() - 1:
		var p0: Vector3 = pts[i][0]
		var p1: Vector3 = pts[i + 1][0]
		var q0: Vector3 = p0 + (pts[i][1] as Vector3) * d
		var q1: Vector3 = p1 + (pts[i + 1][1] as Vector3) * d
		var f := Vector3(0, 0, w)
		# inner flange, then the two sides
		for v in [q0 - f, q1 - f, q0 + f, q1 - f, q1 + f, q0 + f]:
			st.add_vertex(v)
		for v in [p0 + f, q0 + f, p1 + f, p1 + f, q0 + f, q1 + f]:
			st.add_vertex(v)
		for v in [p0 - f, p1 - f, q0 - f, p1 - f, q1 - f, q0 - f]:
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()
