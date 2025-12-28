extends Node3D

var world_ref = null

func _ready():
	# Each building gets its own copy of the material for individual control
	# But we don't recreate the shader, just duplicate the existing one
	var mesh = $MeshInstance3D
	if mesh.get_active_material(0):
		mesh.set_surface_override_material(0, mesh.get_active_material(0).duplicate())

func _process(delta):
	if world_ref:
		position.z += world_ref.speed * delta
		
		# React to music - use cached energy from world
		var energy = world_ref.cached_energy
		# Taller scale (Base 4.0, max +20.0)
		var target_scale = 4.0 + energy * 20.0
		scale.y = lerp(scale.y, target_scale, 10.0 * delta)
		
		# Color Shift: Blue -> Pink/Red
		# Increase color intensity
		var target_color = Color(0.1, 0.1, 1.0).lerp(Color(2.0, 0.0, 0.5), energy * 3.0)
		
		var mat = $MeshInstance3D.get_surface_override_material(0) as ShaderMaterial
		if mat:
			mat.set_shader_parameter("base_color", target_color)
			mat.set_shader_parameter("building_height", scale.y)
		
		if position.z > 20.0: # Behind camera
			queue_free()
