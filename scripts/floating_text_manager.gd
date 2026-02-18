extends Node

const FLOATING_TEXT_SCENE := preload("res://scenes/floating_text.tscn") as PackedScene
const CRITICAL_DAMAGE_THRESHOLD := 50.0

func show_damage(world_position: Vector2, amount: float) -> void:
	var is_critical := amount > CRITICAL_DAMAGE_THRESHOLD
	var color := Color.RED if is_critical else Color.WHITE
	var text := str(int(amount))
	call_deferred("_deferred_show_damage", world_position, text, color)


func _deferred_show_damage(world_position: Vector2, text: String, color: Color) -> void:
	var instance := FLOATING_TEXT_SCENE.instantiate() as Node2D
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	parent.add_child(instance)
	instance.global_position = world_position
	instance.setup(text, color)
