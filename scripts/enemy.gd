extends Node3D

var world_ref = null
var target_z = 2.0 # Desired distance behind player (Player is at 0)
var current_lane = 1
var lane_speed = 5.0

func _ready():
	# Start further back
	position.z = 5.0
	position.x = 0.0

func _process(delta):
	if not world_ref or not world_ref.player_ref:
		return
		
	var player = world_ref.player_ref
	
	# Lane Following Logic
	# Enemy tries to be in the same lane as player
	var desired_x = player.position.x
	position.x = move_toward(position.x, desired_x, lane_speed * delta)
	
	# Chase / Retreat Logic
	if player.is_jumping:
		# Player jumped! Flash and retreat
		# Visual flash could be added here
		target_z = 6.0 # Move further back
		position.z = move_toward(position.z, target_z, 10.0 * delta)
	else:
		# Chase
		target_z = 1.5 # Close behind
		position.z = move_toward(position.z, target_z, 2.0 * delta)
		
	# Wobble effect for aggression
	position.x += sin(Time.get_ticks_msec() / 100.0) * 0.05
