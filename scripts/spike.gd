extends Area3D

var world_ref = null
var explosion_scene = preload("res://scenes/spike_explosion.tscn")

func _ready():
	connect("body_entered", _on_body_entered)

func _process(delta):
	if world_ref:
		position.z += world_ref.speed * delta
		
		# Spikes pulse and change color to music - use cached energy
		var energy = world_ref.cached_energy
		scale = Vector3.ONE * (1.0 + energy * 1.5)
		
		# Bob up and down with music
		position.y = energy * 2.0
		
		# Color Shift: Purple -> Bright Pink/Red
		var base_color = Color(0.6, 0.0, 0.8)
		var pulse_color = Color(1.0, 0.0, 0.5)
		var target_color = base_color.lerp(pulse_color, energy * 2.0)
		
		var mat = $MeshInstance3D.get_active_material(0) as StandardMaterial3D
		if mat:
			mat.albedo_color = target_color
			mat.emission = target_color
			mat.emission_energy_multiplier = 3.0 + energy * 5.0

		if position.z > 20.0:
			queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		if world_ref and (world_ref.is_boosted or world_ref.spike_protection_timer > 0):
			# Destroy Spike
			var explosion = explosion_scene.instantiate()
			get_parent().add_child(explosion)
			explosion.position = position
			explosion.emitting = true
			queue_free()
		elif world_ref:
			print("Player hit spike!")
			world_ref.game_over()
