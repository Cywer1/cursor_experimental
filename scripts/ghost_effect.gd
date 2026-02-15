extends Sprite2D

# How long the ghost stays visible.
# 0.4 seconds is enough to see the "echo" stay behind for a moment.
const FADE_DURATION := 0.4

func _ready() -> void:
	# We assume the 'modulate' (color and alpha) is already set by the Player script.
	var end_color := modulate
	end_color.a = 0.0
	
	var tween := create_tween()
	# Transition from current alpha to 0.0
	tween.tween_property(self, "modulate", end_color, FADE_DURATION)
	tween.finished.connect(queue_free)
