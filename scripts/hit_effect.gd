extends Node2D

@onready var particles: CPUParticles2D = $CPUParticles2D

func _ready() -> void:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex := ImageTexture.create_from_image(img)
	particles.texture = tex
	particles.emitting = true
	await get_tree().create_timer(particles.lifetime + 0.05).timeout
	queue_free()
