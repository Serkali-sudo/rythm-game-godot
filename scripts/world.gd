extends Node3D

var speed = 30.0
var spectrum
@onready var music_player = $MusicPlayer

var building_scene = preload("res://scenes/building.tscn")
var spike_scene = preload("res://scenes/spike.tscn")
var speed_boost_scene = preload("res://scenes/speed_boost.tscn")
var speed_lines_scene = preload("res://scenes/speed_lines.tscn")
var enemy_drill_scene = preload("res://scenes/enemy_drill.tscn")
var player_scene = preload("res://scenes/player.tscn")

var spawn_timer = 0.0
var spawn_interval = 0.5 # Seconds
var spike_timer = 0.0
var spike_interval = 0.8
var boost_timer = 0.0
var boost_spawn_timer = 5.0
var base_speed = 30.0
var boost_multiplier = 2.5
var spike_protection_timer = 0.0

var is_boosted = false
var boost_charges = 0
var max_boost_charges = 3
var collectible_progress = 0
var items_per_charge = 5
var enemy_instance = null
var enemy_timer = 5.0 # Initial delay for enemy possibility

var player_ref = null
var distance = 0.0
var is_game_over = false
var cached_energy = 0.0

@onready var score_label = $CanvasLayer/ScoreLabel
@onready var boost_label = $CanvasLayer/BoostLabel
@onready var road = $Road
@onready var ground = $Ground
@onready var game_over_panel = $CanvasLayer/GameOverPanel
@onready var restart_button = $CanvasLayer/GameOverPanel/Button
@onready var camera = $Camera3D
@onready var screen_flash = $CanvasLayer/ScreenFlash

var camera_base_pos = Vector3.ZERO

var lane_last_spawn_dist = {-3: -999.0, 0: -999.0, 3: -999.0}
var min_spawn_spacing = 20.0


var shake_intensity = 0.0
var speed_lines_instance = null

func _ready():
	spectrum = AudioServer.get_bus_effect_instance(0, 0)
	
	# UI Setup
	game_over_panel.visible = false
	restart_button.pressed.connect(restart_game)
	
	# Reset shader speeds (in case we reloaded after game over)
	var road_mat = road.get_active_material(0) as ShaderMaterial
	if road_mat:
		road_mat.set_shader_parameter("speed", speed)
		
	var ground_mat = ground.get_active_material(0) as ShaderMaterial
	if ground_mat:
		ground_mat.set_shader_parameter("speed", speed)
	
	# Spawn Player
	var player = player_scene.instantiate()
	player.name = "Player"
	add_child(player)
	player.position = Vector3(0, 0, 0)
	player_ref = player
	
	# Load selected song
	var song = load(GameData.selected_song)
	if song:
		music_player.stream = song
		music_player.play()
	
	# Store camera base position for shake
	if camera:
		camera_base_pos = camera.position
		speed_lines_instance = speed_lines_scene.instantiate()
		camera.add_child(speed_lines_instance)
		
	# Initialize base speed
	base_speed = speed
	update_boost_ui()

func update_boost_ui():
	if boost_label:
		boost_label.text = "BOOST: %d [%d/%d]" % [boost_charges, collectible_progress, items_per_charge]

func _process(delta):
	if is_game_over:
		return

	# Spawn Buildings based on distance effectively (timer adjusted by speed)
	var speed_factor = speed / base_speed if base_speed > 0 else 1.0
	spawn_timer -= delta * speed_factor
	if spawn_timer <= 0:
		spawn_building()
		spawn_timer = spawn_interval
		
	# Update cached energy once per frame for all objects to use
	cached_energy = get_energy()
	
	# Update Road Energy
	var road_mat = road.get_active_material(0) as ShaderMaterial
	if road_mat:
		road_mat.set_shader_parameter("energy", cached_energy)
		
	# Spawn Spikes consistent with speed
	spike_timer -= delta * speed_factor
	if spike_timer <= 0:
		spawn_spike()
		# Random interval
		spike_interval = randf_range(0.5, 1.2)
		spike_timer = spike_interval
	
	# Spawn Speed Boost (Energy Items)
	boost_spawn_timer -= delta * speed_factor # Spawn faster as game speeds up
	if boost_spawn_timer <= 0:
		spawn_speed_boost()
		boost_spawn_timer = randf_range(0.5, 1.5) # Much more frequent spawning
		
	# Handle Speed Boost Logic
	if speed_lines_instance:
		speed_lines_instance.emitting = is_boosted

	if is_boosted:
		boost_timer -= delta
		speed = lerp(speed, base_speed * boost_multiplier, 5.0 * delta)
		
		# FOV Effect
		if camera:
			camera.fov = lerp(camera.fov, 90.0, 5.0 * delta)
			
		if boost_timer <= 0:
			is_boosted = false
			spike_protection_timer = 1.0 # 1 second extra protection
	else:
		speed = lerp(speed, base_speed, 2.0 * delta)
		if camera:
			camera.fov = lerp(camera.fov, 75.0, 2.0 * delta)
			
	# Update Spike Protection Timer
	if spike_protection_timer > 0:
		spike_protection_timer -= delta
		
	# Spawn Enemy Logic
	# Only countdown spawn timer if NOT boosted (wait for calm period)
	if (not enemy_instance or not is_instance_valid(enemy_instance)) and not is_game_over and not is_boosted:
		enemy_timer -= delta
		if enemy_timer <= 0:
			spawn_enemy()
			enemy_timer = randf_range(5.0, 10.0)
				
	distance += speed * delta
	score_label.text = "DISTANCE: %d m" % int(distance / 10.0)
	
	# Camera Shake on bass
	if cached_energy > 0.5:
		shake_intensity = cached_energy * 0.3
	else:
		shake_intensity = lerp(shake_intensity, 0.0, 10.0 * delta)
	
	if camera and shake_intensity > 0.01:
		camera.position = camera_base_pos + Vector3(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity),
			0
		)
	elif camera:
		camera.position = camera_base_pos
	
	# Screen Flash on high energy
	if screen_flash:
		if cached_energy > 0.7:
			screen_flash.visible = true
			screen_flash.modulate.a = (cached_energy - 0.7) * 2.0
		else:
			screen_flash.visible = false

func spawn_spike():
	var spike = spike_scene.instantiate()
	spike.world_ref = self
	add_child(spike)
	
	# Random Lane with Safety Check
	var valid_lanes = []
	for l in [-3, 0, 3]:
		if distance - lane_last_spawn_dist[l] > min_spawn_spacing:
			valid_lanes.append(l)
			
	if valid_lanes.is_empty():
		spike.queue_free()
		return
		
	var lane = valid_lanes.pick_random()
	lane_last_spawn_dist[lane] = distance
	spike.position = Vector3(lane, 0, -100)

func spawn_building():
	# Spawn Left
	var b_left = building_scene.instantiate()
	b_left.world_ref = self
	add_child(b_left)
	b_left.position = Vector3(-8, 0, -100)
	
	# Spawn Right
	var b_right = building_scene.instantiate()
	b_right.world_ref = self
	add_child(b_right)
	b_right.position = Vector3(8, 0, -100)

func get_energy():
	if spectrum:
		# Get magnitude of low frequencies (bass) - Expanded range 20-400Hz
		return spectrum.get_magnitude_for_frequency_range(20, 400).length()
	return 0.0

func add_energy():
	# Called when collecting an item
	if boost_charges < max_boost_charges:
		collectible_progress += 1
		if collectible_progress >= items_per_charge:
			collectible_progress = 0
			boost_charges += 1
			print("Boost Charge Gained! Total: ", boost_charges)
		
		update_boost_ui()
			
func activate_speed_boost():
	if boost_charges > 0:
		boost_charges -= 1
		update_boost_ui()
		print("Boost Consumed! Remaining: ", boost_charges)
		
		is_boosted = true
		boost_timer = 3.0 # 3 seconds of boost
		
		# Repel Enemy
		if enemy_instance and is_instance_valid(enemy_instance):
			if enemy_instance.has_method("repel"):
				enemy_instance.repel()
	else:
		print("No Boost Charges!")
		
func spawn_speed_boost():
	var boost = speed_boost_scene.instantiate()
	# boost.world_ref = self # Set later with check
	add_child(boost)
	
	# Random Lane with Safety Check
	var valid_lanes = []
	for l in [-3, 0, 3]:
		# Check distance AND ensure we don't spawn on top of a just-spawned spike
		if distance - lane_last_spawn_dist[l] > min_spawn_spacing:
			valid_lanes.append(l)
			
	if valid_lanes.is_empty():
		boost.queue_free()
		return
		
	var lane = valid_lanes.pick_random()
	lane_last_spawn_dist[lane] = distance
	boost.position = Vector3(lane, 0, -100)
	
	if "world_ref" in boost:
		boost.world_ref = self
		# print("SpeedBoost spawned successfully at ", boost.position)
	else:
		push_error("Spawned SpeedBoost but it is missing 'world_ref' property! Script might be detached.")

func spawn_enemy():
	var enemy = enemy_drill_scene.instantiate()
	enemy.world_ref = self
	add_child(enemy)
	enemy_instance = enemy

func game_over():
	is_game_over = true
	game_over_panel.visible = true
	
	# Stop everything
	speed = 0.0
	music_player.stop()
	
	# Stop Road/Ground Scroll
	var road_mat = road.get_active_material(0) as ShaderMaterial
	if road_mat:
		road_mat.set_shader_parameter("speed", 0.0)
		
	var ground_mat = ground.get_active_material(0) as ShaderMaterial
	if ground_mat:
		ground_mat.set_shader_parameter("speed", 0.0)

func restart_game():
	get_tree().reload_current_scene()
