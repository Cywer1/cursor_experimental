extends CanvasLayer

@onready var retry_button: Button = $Panel/CenterContainer/VBoxContainer/RetryButton
@onready var quit_button: Button = $Panel/CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
	hide()
	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func show_game_over() -> void:
	show()
	get_tree().paused = true

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().quit()
