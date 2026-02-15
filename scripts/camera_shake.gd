extends Camera2D

var _shake_remaining := 0.0
var _shake_intensity := 0.0
var _shake_duration := 0.0

func apply_shake(intensity: float, duration: float) -> void:
	if duration <= 0.0 or intensity <= 0.0:
		return
	_shake_intensity = intensity
	_shake_duration = duration
	_shake_remaining = duration

func _process(delta: float) -> void:
	if _shake_remaining <= 0.0:
		offset = Vector2.ZERO
		return
	_shake_remaining -= delta
	var t := 1.0 - (_shake_remaining / _shake_duration)
	var current_intensity := _shake_intensity * (1.0 - t)
	offset = Vector2(
		randf_range(-current_intensity, current_intensity),
		randf_range(-current_intensity, current_intensity)
	)
