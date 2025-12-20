extends Node3D

var world_ref = null

@onready var shader = preload("res://shaders/building_windows.gdshader")

func _ready():
	var mat = ShaderMaterial.new()
	mat.shader = shader
	# Initial random tint logic can be moved to process or just simple logic
	mat.set_shader_parameter("base_color", Color(0.1, 0.1, 1.0))
	mat.set_shader_parameter("emission_energy", 2.0)
	$MeshInstance3D.material_override = mat

func _process(delta):
	if world_ref:
		position.z += world_ref.speed * delta
		
		# React to music
		var energy = world_ref.get_energy()
		# Taller scale (Base 4.0, max +20.0)
		var target_scale = 4.0 + energy * 20.0
		scale.y = lerp(scale.y, target_scale, 10.0 * delta)
		
		# Color Shift: Blue -> Pink/Red
		# Increase color intensity
		var target_color = Color(0.1, 0.1, 1.0).lerp(Color(2.0, 0.0, 0.5), energy * 3.0)
		
		var mat = $MeshInstance3D.material_override
		if mat:
			mat.set_shader_parameter("base_color", target_color)
			mat.set_shader_parameter("building_height", scale.y)
		
		if position.z > 20.0: # Behind camera
			queue_free()
