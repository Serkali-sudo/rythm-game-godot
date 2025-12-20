extends Node3D

var speed = 30.0
var spectrum
@onready var music_player = $MusicPlayer

var building_scene = preload("res://scenes/building.tscn")
var spike_scene = preload("res://scenes/spike.tscn")
var player_scene = preload("res://scenes/player.tscn")

var spawn_timer = 0.0
var spawn_interval = 0.5 # Seconds
var spike_timer = 0.0
var spike_interval = 0.8

var player_ref = null
var distance = 0.0
var is_game_over = false

@onready var score_label = $CanvasLayer/ScoreLabel
@onready var road = $Road
@onready var ground = $Ground
@onready var game_over_panel = $CanvasLayer/GameOverPanel
@onready var restart_button = $CanvasLayer/GameOverPanel/Button
@onready var camera = $Camera3D
@onready var screen_flash = $CanvasLayer/ScreenFlash

var camera_base_pos = Vector3.ZERO
var shake_intensity = 0.0

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

func _process(delta):
	if is_game_over:
		return

	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_building()
		spawn_timer = spawn_interval
		
	# Update Road Energy
	var energy = get_energy()
	var road_mat = road.get_active_material(0) as ShaderMaterial
	if road_mat:
		road_mat.set_shader_parameter("energy", energy)
		
	spike_timer -= delta
	if spike_timer <= 0:
		spawn_spike()
		# Random interval
		spike_interval = randf_range(0.5, 1.2)
		spike_timer = spike_interval
		
	distance += speed * delta
	score_label.text = "DISTANCE: %d m" % int(distance / 10.0)
	
	# Camera Shake on bass
	if energy > 0.5:
		shake_intensity = energy * 0.3
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
		if energy > 0.7:
			screen_flash.visible = true
			screen_flash.modulate.a = (energy - 0.7) * 2.0
		else:
			screen_flash.visible = false

func spawn_spike():
	var spike = spike_scene.instantiate()
	spike.world_ref = self
	add_child(spike)
	
	# Random Lane
	var lanes = [-3, 0, 3]
	var lane = lanes.pick_random()
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
