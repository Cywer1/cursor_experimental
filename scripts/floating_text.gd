extends Node2D

const DURATION := 0.5
const FLOAT_SPEED := 60.0

@onready var label: Label = $Label

var _elapsed := 0.0
var _base_color := Color.WHITE

func setup(text: String, color: Color) -> void:
	if label == null:
		label = $Label
	label.text = text
	_base_color = color
	label.modulate = color

func _process(delta: float) -> void:
	_elapsed += delta
	var t := _elapsed / DURATION
	if t >= 1.0:
		queue_free()
		return
	position.y -= FLOAT_SPEED * delta
	label.modulate = Color(_base_color.r, _base_color.g, _base_color.b, 1.0 - t)
