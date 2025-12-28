extends CharacterBody3D

var current_lane = 1 # 0: Left, 1: Center, 2: Right
var lanes = [-3.0, 0.0, 3.0]
var target_x = 0.0
var is_jumping = false

@onready var mesh = $CarModel
var wheels = []

func _ready():
	target_x = lanes[current_lane]
	find_wheels(mesh)

func find_wheels(node):
	var n_name = node.name.to_lower()
	if "tire" in n_name or "wheel" in n_name or "rim" in n_name or "disc" in n_name:
		wheels.append(node)
	
	for child in node.get_children():
		find_wheels(child)

var touch_start_pos = Vector2.ZERO
var min_swipe_distance = 50.0

func _input(event):
	if event.is_action_pressed("move_left"):
		change_lane(-1)
	elif event.is_action_pressed("move_right"):
		change_lane(1)
	elif event.is_action_pressed("jump") and not is_jumping:
		jump()
		
	# Swipe Controls
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start_pos = event.position
			
	elif event is InputEventScreenDrag:
		if touch_start_pos == Vector2.ZERO:
			# Ignore drags if we didn't catch the start (or already processed it)
			return
			
		var drag_vector = event.position - touch_start_pos
		
		# Check if swipe is long enough
		if drag_vector.length() > min_swipe_distance:
			if abs(drag_vector.x) > abs(drag_vector.y):
				# Horizontal Swipe
				if drag_vector.x > 0:
					change_lane(1)
				else:
					change_lane(-1)
			else:
				# Vertical Swipe
				if drag_vector.y < 0: # Up
					if not is_jumping:
						jump()
			
			# Reset start pos so we don't trigger multiple times for one swipe
			touch_start_pos = Vector2.ZERO

func change_lane(dir):
	current_lane += dir
	current_lane = clamp(current_lane, 0, 2)
	target_x = lanes[current_lane]

func jump():
	is_jumping = true
	$JumpFlash.visible = true
	var tween = create_tween()
	tween.tween_property(mesh, "position:y", 3.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): 
		is_jumping = false
		$JumpFlash.visible = false
	)

func _process(delta):
	# Smooth lane switching
	position.x = lerp(position.x, target_x, 15.0 * delta)
	
	# Rotate Wheels
	var speed = 30.0 # Match world speed roughly
	for wheel in wheels:
		wheel.rotate_x(speed * delta * 0.5)

	# Sync Trail Color with Music - use cached energy
	var parent = get_parent()
	if parent and "cached_energy" in parent:
		var energy = parent.cached_energy
		# Color Shift: Hot Pink -> Bright White/Pink
		var target_color = Color(1, 0.41, 0.71).lerp(Color(1.0, 0.8, 1.0), energy * 2.0)
		
		# Update Material (Shared by both trails)
		var trail_mesh = $TrailLeft.draw_pass_1
		if trail_mesh and trail_mesh.material:
			var mat = trail_mesh.material as StandardMaterial3D
			# Keep alpha at 0.5 for albedo, but pulse emission
			mat.albedo_color = Color(target_color.r, target_color.g, target_color.b, 0.5)
			mat.emission = target_color
			mat.emission_energy_multiplier = 2.0 + (energy * 5.0)
