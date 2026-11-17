shader_type canvas_item;
// Whole-sprite white flash when a unit is hit.
uniform float flash = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	c.rgb = mix(c.rgb, vec3(1.0), flash);
	COLOR = c;
}
