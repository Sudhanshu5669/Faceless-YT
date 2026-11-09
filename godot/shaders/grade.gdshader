// Full-screen finishing pass: vignette and film grain.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float vignette = 0.0;
uniform float grain = 0.0;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	vec2 q = SCREEN_UV - 0.5;
	c *= 1.0 - vignette * smoothstep(0.2, 0.85, length(q * vec2(1.2, 1.0)));
	float n = fract(sin(dot(SCREEN_UV * (1.0 + fract(TIME * 7.0)), vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
	c += n * grain * 0.12;
	COLOR = vec4(c, 1.0);
}
