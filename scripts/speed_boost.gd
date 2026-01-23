extends Area3D
class_name SpeedBoost

var world_ref = null
# var collect_effect_scene = preload("res://scenes/collect_explosion.tscn")

func _ready():
	connect("body_entered", _on_body_entered)

func _process(delta):
	if world_ref:
		position.z += world_ref.speed * delta
		
		# Rotate for visual flair
		rotate_y(2.0 * delta)
		
		# Pulse scale
		var energy = world_ref.cached_energy
		scale = Vector3.ONE * (1.0 + energy * 0.5)
		
		# Clean up when out of view
		if position.z > 20.0:
			queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		if world_ref:
			if world_ref.has_method("add_energy"):
				world_ref.add_energy()
		
		# Spawn particle effect
		var effect_scene = load("res://scenes/collect_explosion.tscn")
		if effect_scene:
			var effect = effect_scene.instantiate()
			get_parent().add_child(effect)
			effect.global_position = global_position + Vector3(0, 1.0, 0) # Raise it up
			effect.emitting = true
			print("Spawned particle effect at ", effect.global_position)
		else:
			print("Failed to load particle scene!")
		
		queue_free()
