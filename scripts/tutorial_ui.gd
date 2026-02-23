extends CanvasLayer

@onready var _dash_label: Label = $RootControl/DashLabel
@onready var _root_control: Control = $RootControl

var _dismiss_timer: float = -1.0
var _ready_delay: float = 1.0
var _fading: bool = false


func _ready() -> void:
	if SaveManager.high_score > 0:
		queue_free()
		return
	_start_flash()


func _start_flash() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(_dash_label, "modulate:a", 0.2, 0.5)
	tween.tween_property(_dash_label, "modulate:a", 1.0, 0.5)


func _process(delta: float) -> void:
	if _fading:
		return

	if _ready_delay > 0.0:
		_ready_delay -= delta
		return

	if _dismiss_timer >= 0.0:
		_dismiss_timer -= delta
		if _dismiss_timer <= 0.0:
			_fade_out()
		return

	var moved := (
		Input.is_action_pressed("ui_left") or
		Input.is_action_pressed("ui_right") or
		Input.is_action_pressed("ui_up") or
		Input.is_action_pressed("ui_down") or
		Input.is_action_just_pressed("dash")
	)
	if moved:
		_dismiss_timer = 3.0


func _fade_out() -> void:
	_fading = true
	var tween := create_tween()
	tween.tween_property(_root_control, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)
