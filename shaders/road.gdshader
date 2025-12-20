shader_type spatial;

uniform vec3 grid_color : source_color = vec3(0.0, 1.0, 1.0);
uniform float speed = 30.0;
uniform float line_thickness = 0.02;
uniform float scale = 10.0;

uniform float energy = 0.0;

void fragment() {
	// UV scrolling logic to be handled by TIME or script uniform. Only Y moves.
	// Since we are moving Z+ in world, texturing scrolling should match.
	// We'll use TIME * speed if consistent, or manual uniform offset.
	
	vec2 uv = UV * scale;
	// Plane length 200m, Scale 10 -> 20m per tile. Speed 30m/s -> 1.5 tiles/sec.
	float scroll_rate = speed / 20.0; 
	uv.y += TIME * scroll_rate;
	
	vec2 grid = fract(uv);
	
	// Lanes (Vertical lines)
	// Draw lines at 1/3 and 2/3 of the UV width to create 3 visible lanes
	float lane_1 = step(abs(UV.x - 0.333), 0.005);
	float lane_2 = step(abs(UV.x - 0.666), 0.005);
	
	// Edge Outlines
	float edge_left = step(UV.x, 0.01);
	float edge_right = step(1.0 - UV.x, 0.01);
	
	// Dynamic vertical lines (Lanes) based on beat?
	// Let's make them stable but maybe glow brighter with energy
	float is_line = max(max(lane_1, lane_2), max(edge_left, edge_right));
	
	// Waveform Effect (Horizontal representation)
	// We center it at UV.x = 0.5
	float center_dist = abs(UV.x - 0.5);
	
	// Generate pseudo-random wave based on Y (distance) and Time
	float wave_scroll = uv.y; // Already scrolled
	float high_freq = sin(wave_scroll * 30.0) * sin(wave_scroll * 13.0 + TIME * 5.0);
	
	// Amplitude controlled by energy
	float wave_width = 0.01 + energy * 0.4 * abs(high_freq); 
	
	// Draw the waveform
	float is_wave = step(center_dist, wave_width);
	
	ALBEDO = vec3(0.05); // Dark asphalt
	
	// Combine: Lanes + Waveform
	// Lanes are Cyan, Waveform matches the pink/red high energy vibe? Or keep it Cyan?
	// User image is Cyan.
	vec3 lane_color = grid_color;
	vec3 wave_color = mix(grid_color, vec3(1.0, 0.0, 0.5), energy); // Pulse to pink on beat
	
	vec3 final_emission = (is_line * lane_color) + (is_wave * wave_color * 2.0);
	
	EMISSION = final_emission; 
	ROUGHNESS = 0.8;
}
