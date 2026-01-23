extends Area3D

var world_ref = null
var current_lane = 1
var lanes = [-3.0, 0.0, 3.0]
var target_x = 0.0
var chase_speed_offset = 5.0 # How much faster than world speed
var repel_force = 0.0



func _ready():
	target_x = lanes[current_lane]
	# Start very close behind player (just behind camera)
	position.z = 12.0
	position.x = 0.0
	connect("body_entered", _on_body_entered)
	
	# Setup Police Lights
	find_and_setup_lights(self)

var red_lights = []
var blue_lights = []
var red_materials = []
var blue_materials = []
var light_timer = 0.0
var light_state = 0 # 0=Red, 1=Blue

func find_and_setup_lights(node):
	# Look for specific mesh names from the model
	if "MaterialRed" in node.name:
		create_light(node, Color(1, 0, 0), red_lights, red_materials)
	elif "Blue" in node.name and "Material" not in node.name: # Differentiator if needed, or just "Blue"
		# The node name in screenshot is "Sketchfab_Scene_Cube_002_Blue_0"
		create_light(node, Color(0, 0, 1), blue_lights, blue_materials)
	elif "Blue" in node.name:
		create_light(node, Color(0, 0, 1), blue_lights, blue_materials)
		
	for child in node.get_children():
		find_and_setup_lights(child)

func create_light(parent_node, color, list, mat_list):
	var light = OmniLight3D.new()
	light.light_color = color
	light.light_energy = 0.0 # Start off
	light.omni_range = 5.0
	parent_node.add_child(light)
	
	# Position slightly above/outside to be visible
	light.position = Vector3(0, 0.2, 0) 
	
	list.append(light)
	
	if parent_node is MeshInstance3D:
		var mat = parent_node.get_active_material(0)
		if mat:
			# Make unique so we don't flash other cars if we had multiple
			var unique_mat = mat.duplicate() 
			parent_node.set_surface_override_material(0, unique_mat)
			mat_list.append(unique_mat)

func _process(delta):
	# Police Light Flashing
	light_timer += delta
	if light_timer > 0.1: # Fast flash
		light_timer = 0.0
		light_state = 1 - light_state # Toggle 0/1
		
		var red_energy = 5.0 if light_state == 0 else 0.0
		var blue_energy = 5.0 if light_state == 1 else 0.0
		
		for l in red_lights:
			l.light_energy = red_energy
		for l in blue_lights:
			l.light_energy = blue_energy
			
		var red_emit = 5.0 if light_state == 0 else 0.0
		var blue_emit = 5.0 if light_state == 1 else 0.0
		
		for m in red_materials:
			m.emission_enabled = true
			m.emission = Color(1, 0, 0)
			m.emission_energy_multiplier = red_emit
			
		for m in blue_materials:
			m.emission_enabled = true
			m.emission = Color(0, 0, 1)
			m.emission_energy_multiplier = blue_emit

	if world_ref:
		# Chase Logic
		# Moves forward relative to the world? 
		# No, world moves backward. Enemy should move forward (negative Z) to catch player at 0.
		# Wait, typically player is at 0. World moves towards +Z.
		# If enemy is behind, it is at +Z. To catch up, it needs to move -Z relative to world flow?
		# Actually, if player is static and world moves +Z, then things at +Z (behind) move further away if they are static.
		# So enemy needs to move -Z *faster* than the world speed to catch up.
		
		# Current World Speed
		var ws = world_ref.speed
		
		# Enemy movement:
		# We want it to slowly approach Z=0 (Player).
		# If it's repelled, it moves +Z (away).
		
		if repel_force > 0:
			position.z += repel_force * delta
			repel_force = lerp(repel_force, 0.0, 2.0 * delta)
		else:
			# Variable Catchup Speed
			if position.z > 12.0:
				# Far behind (invisible), catch up FAST
				position.z -= 8.0 * delta 
			else:
				# In view, creep closer slowly
				position.z -= 0.2 * delta
			
		# Limit how close it gets (2.0 is closest)
		position.z = max(position.z, 2.0)
		
		# Despawn if repelled far enough
		# Despawn if repelled far enough
		if position.z > 40.0:
			if world_ref:
				world_ref.enemy_instance = null
			queue_free()
		
		# Lane Following
		if world_ref.player_ref:
			var player_lane = world_ref.player_ref.current_lane
			if current_lane != player_lane:
				# Delay/Reaction time
				if randf() < 0.05: # Random chance to switch per frame
					current_lane = player_lane
					target_x = lanes[current_lane]
		
		position.x = lerp(position.x, target_x, 5.0 * delta)

func repel():
	repel_force = 120.0 # Push back MUCH harder to ensure it crosses Despawn threshold

func _on_body_entered(body):
	if body.name == "Player":
		if world_ref:
			world_ref.game_over()
