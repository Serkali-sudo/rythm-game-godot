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

func _input(event):
	if event.is_action_pressed("move_left"):
		change_lane(-1)
	elif event.is_action_pressed("move_right"):
		change_lane(1)
	elif event.is_action_pressed("jump") and not is_jumping:
		jump()

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

	# Sync Trail Color with Music
	var parent = get_parent()
	if parent.has_method("get_energy"):
		var energy = parent.get_energy() 
		# Color Shift: Cyan -> Pink/Red
		var target_color = Color(0.0, 1.0, 1.0).lerp(Color(1.0, 0.0, 0.5), energy * 2.0)
		
		# Update Material (Shared by both trails)
		var trail_mesh = $TrailLeft.draw_pass_1
		if trail_mesh and trail_mesh.material:
			var mat = trail_mesh.material as StandardMaterial3D
			# Keep alpha at 0.5 for albedo, but pulse emission
			mat.albedo_color = Color(target_color.r, target_color.g, target_color.b, 0.5)
			mat.emission = target_color
			mat.emission_energy_multiplier = 2.0 + (energy * 5.0)
