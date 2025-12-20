shader_type canvas_item;

uniform vec3 color1 : source_color = vec3(0.0, 0.8, 1.0);
uniform vec3 color2 : source_color = vec3(1.0, 0.0, 0.5);

void fragment() {
	vec2 uv = UV;
	
	// Animated diagonal gradient
	float wave = sin(uv.x * 3.0 + uv.y * 2.0 + TIME * 0.5) * 0.5 + 0.5;
	
	vec3 color = mix(color1, color2, wave);
	
	// Add some scanlines for retro effect
	float scanline = sin(uv.y * 400.0) * 0.05;
	
	COLOR = vec4(color + scanline, 1.0);
}
