extends Control

@onready var title_label: Label = $UILayer/CenterContainer/VBoxContainer/TitleLabel
@onready var play_button: Button = $UILayer/CenterContainer/VBoxContainer/PlayButton
@onready var quit_button: Button = $UILayer/CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	play_button.grab_focus()
	_start_title_pulsate()


func _start_title_pulsate() -> void:
	if title_label == null:
		return
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(title_label, "scale", Vector2(1.08, 1.08), 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
