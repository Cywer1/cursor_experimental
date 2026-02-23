extends Node

var high_score: int = 0
var total_scrap: int = 0

const SAVE_PATH := "user://savegame.cfg"


func _ready() -> void:
	load_game()


func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("Game", "high_score", high_score)
	config.set_value("Game", "total_scrap", total_scrap)
	var err := config.save(SAVE_PATH)
	if err != OK:
		push_error("SaveManager: Failed to save to %s (error %d)" % [SAVE_PATH, err])


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		return
	high_score = config.get_value("Game", "high_score", 0)
	total_scrap = config.get_value("Game", "total_scrap", 0)
