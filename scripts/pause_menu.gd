extends CanvasLayer

signal quit_to_desktop_requested

var _shop_ui: CanvasLayer = null

@onready var _resume_button: Button = $Panel/CenterContainer/VBoxContainer/ResumeButton
@onready var _restart_button: Button = $Panel/CenterContainer/VBoxContainer/RestartButton
@onready var _quit_button: Button = $Panel/CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	if _resume_button:
		_resume_button.pressed.connect(_on_resume_pressed)
	if _restart_button:
		_restart_button.pressed.connect(_on_restart_pressed)
	if _quit_button:
		_quit_button.pressed.connect(_on_quit_pressed)


func set_shop_ui(shop: CanvasLayer) -> void:
	_shop_ui = shop


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if _shop_ui != null and _shop_ui.visible:
		return
	get_viewport().set_input_as_handled()
	if visible:
		get_tree().paused = false
		hide()
	else:
		get_tree().paused = true
		show()
		_resume_button.grab_focus()


func _on_resume_pressed() -> void:
	get_tree().paused = false
	hide()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	quit_to_desktop_requested.emit()
