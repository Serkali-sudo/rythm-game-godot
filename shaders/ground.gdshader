shader_type spatial;

uniform vec3 grid_color : source_color = vec3(0.5, 0.0, 0.5); // Purple grid
uniform vec3 bg_color : source_color = vec3(0.02, 0.02, 0.05);
uniform float speed = 30.0;
uniform float scale = 20.0; // Larger grid cells

void fragment() {
	vec2 uv = UV * scale;
	// Scroll Y to match road speed (approximate sync)
	// Plane is 200m long. Scale 20 -> 10m per tile.
	// Speed 30m/s -> 3 tiles/sec.
	float scroll_rate = speed / 10.0;
	uv.y += TIME * scroll_rate;
	
	vec2 grid = fract(uv);
	float line_thickness = 0.02;
	
	float line_x = step(1.0 - line_thickness, grid.x) + step(grid.x, line_thickness);
	float line_y = step(1.0 - line_thickness, grid.y) + step(grid.y, line_thickness);
	float is_line = max(line_x, line_y);
	
	ALBEDO = bg_color;
	EMISSION = grid_color * is_line * 2.0;
}
