shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque, cull_back;

uniform vec3 top_color : source_color = vec3(1.0, 0.8, 0.0); // Yellow/Orange
uniform vec3 bottom_color : source_color = vec3(1.0, 0.0, 0.5); // Pink/Magenta
uniform float sun_radius = 0.45;

void fragment() {
	vec2 uv = UV;
	
	// Circle Shape
	float dist = distance(uv, vec2(0.5));
	if (dist > sun_radius) {
		discard;
	}
	
	// Gradient
	vec3 color = mix(bottom_color, top_color, uv.y);
	
	// Stripes / Blinds effect
	// Stripes appear at the bottom and get thicker? Or just uniform?
	// Reference image has stripes usually at the bottom half.
	
	float stripe_count = 20.0;
	float stripe_y = fract(uv.y * stripe_count);
	
	// Cutout logic: 
	// We want the cutout gap size to increase as we go down (lower Y).
	// Threshold determines if we show the color or gap.
	// Near top (Y=1), threshold is high (little gap). Near bottom (Y=0), threshold is lower.
	
	float threshold = 0.6 + (uv.y * 0.3); // 0.6 at bottom, 0.9 at top
	if (uv.y < 0.6 && stripe_y > threshold) {
		// discard; // Hard cutout
		// Or smooth cutout?
		discard;
	}
	
	ALBEDO = color;
	EMISSION = color * 4.0; // High glow
}
