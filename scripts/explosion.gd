extends GPUParticles3D

func _ready():
	emitting = true
	# Wait for lifetime + buffer
	await get_tree().create_timer(lifetime + 0.5).timeout
	queue_free()
