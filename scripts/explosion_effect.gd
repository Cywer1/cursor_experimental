extends Node2D

const RADIUS := 150.0
const DURATION := 0.18

var _progress := 0.0

func _ready() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_method(_set_progress, 0.0, 1.0, DURATION)
	tween.tween_callback(queue_free)

func _set_progress(p: float) -> void:
	_progress = p
	queue_redraw()

func _draw() -> void:
	var r := _progress * RADIUS
	var alpha := 1.0 - _progress
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, alpha))
