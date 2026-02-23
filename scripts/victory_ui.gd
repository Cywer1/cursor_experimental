extends CanvasLayer

@onready var play_again_button: Button = $Panel/CenterContainer/VBoxContainer/PlayAgainButton
@onready var main_menu_button: Button = $Panel/CenterContainer/VBoxContainer/MainMenuButton


func _ready() -> void:
	hide()
	play_again_button.pressed.connect(_on_play_again_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)


func show_victory() -> void:
	show()
	get_tree().paused = true


func _on_play_again_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
