shader_type spatial;

uniform vec3 base_color : source_color;
uniform float emission_energy : hint_range(0.0, 10.0) = 2.0;
uniform float building_height = 1.0;

void fragment() {
	// Adjust vertical tiling based on height to modify aspect ratio
	// UV.y goes from 0 to 1. 
	// We want roughly 1 window per unit height?
	// The mesh is 1 unit high originally.
	
	// Create a grid pattern
	// Increase tiling density for smaller windows
	vec2 tiled_uv = UV * vec2(8.0, building_height * 2.0);
	vec2 grid = fract(tiled_uv);
	vec2 cell_id = floor(tiled_uv); // ID for randomization
	
	// Randomly turn off windows
	float random_val = fract(sin(dot(cell_id, vec2(12.9898, 78.233))) * 43758.5453);
	float window_active = step(0.4, random_val); // 60% chance of window
	
	// Define window size (Smaller windows, more wall)
	float window_x = step(0.35, grid.x) - step(0.65, grid.x); 
	float window_y = step(0.35, grid.y) - step(0.65, grid.y);
	float is_window = window_x * window_y * window_active;
	
	// Base is dark structure
	vec3 final_color = base_color;
	
	ALBEDO = final_color * 0.05; // Very dark base
	EMISSION = final_color * is_window * emission_energy;
	
	// Better Edge Highlight (Rim)
	// Highlight the actual corners of the mesh
	float rim = 1.0 - (step(0.02, UV.x) * step(0.02, 1.0 - UV.x) * step(0.02, UV.y));
	EMISSION += final_color * rim * 2.0; // Strong edge glow
}
