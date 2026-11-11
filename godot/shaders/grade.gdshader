// Full-screen finishing pass: vignette and film grain.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float vignette = 0.0;
uniform float grain = 0.0;
// Scene time (set by main.gd), not engine TIME: a shot looks the same whatever was rendered before it.
global uniform float scene_time;
// Iris transitions (main.gd sets them per frame): 0 = circle, 1 = binoculars; radius in screen
// heights, >= 2 = no mask.
global uniform float iris_shape;
global uniform float iris_radius;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	vec2 q = SCREEN_UV - 0.5;
	c *= 1.0 - vignette * smoothstep(0.2, 0.85, length(q * vec2(1.2, 1.0)));
	float n = fract(sin(dot(SCREEN_UV * (1.0 + fract(scene_time * 7.0)), vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
	c += n * grain * 0.12;
	if (iris_radius < 2.0) {
		vec2 px = q * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);  // aspect-correct, height = 1
		float d;
		if (iris_shape > 0.5) {
			// Two overlapping lenses side by side, a dark rim, spreading apart as they open.
			float sep = iris_radius * 0.62;
			d = min(length(px - vec2(-sep, 0.0)), length(px - vec2(sep, 0.0))) - iris_radius * 0.72;
		} else {
			d = length(px) - iris_radius;
		}
		c *= 1.0 - smoothstep(-0.012, 0.004, d);
		c *= 1.0 - 0.45 * smoothstep(-0.08, 0.0, d);  // soft inner rim, like looking through glass
	}
	COLOR = vec4(c, 1.0);
}
