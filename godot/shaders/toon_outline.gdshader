// Inverted-hull outline for toon meshes: the back faces, pushed out along the
// normals and drawn flat. Used as next_pass on toon materials.
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;

uniform vec3 color : source_color = vec3(0.04, 0.04, 0.05);
uniform float width = 0.012;

void vertex() {
	VERTEX += normalize(NORMAL) * width;
}

void fragment() {
	ALBEDO = color;
}
