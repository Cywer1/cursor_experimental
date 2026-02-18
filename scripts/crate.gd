extends StaticBody2D

const CRATE_BREAK_EFFECT_SCENE := preload("res://scenes/crate_break_effect.tscn") as PackedScene
const PICKUP_SCENE := preload("res://scenes/pickup.tscn") as PackedScene
const COLLECTABLE_SCENE := preload("res://scenes/collectable.tscn") as PackedScene

var is_active: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("destructible")
	modulate = Color(1, 1, 1, 0)
	collision.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 2.0)
	tween.tween_callback(_on_spawn_finished)

func _on_spawn_finished() -> void:
	is_active = true
	collision.set_deferred("disabled", false)
	var flash := create_tween()
	flash.tween_property(sprite, "modulate", Color.WHITE, 0.05)
	flash.tween_property(sprite, "modulate", Color(0.2, 0.8, 0.2, 1.0), 0.1)

func take_damage(_amount: float) -> void:
	if not is_active:
		return
	break_crate()

func break_crate() -> void:
	is_active = false
	var pos := global_position
	var parent := get_parent()
	# Effect
	var effect := CRATE_BREAK_EFFECT_SCENE.instantiate() as Node2D
	effect.global_position = pos
	parent.add_child(effect)
	# Loot
	var roll := randf()
	if roll < 0.40:
		pass  # Empty
	elif roll < 0.70:
		_spawn_pickup(pos, "stamina", 50.0)
	elif roll < 0.90:
		_spawn_pickup(pos, "health", 30.0)
	else:
		for i in 10:
			var c := COLLECTABLE_SCENE.instantiate() as Node2D
			c.global_position = pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
			parent.call_deferred("add_child", c)
	queue_free()

func _spawn_pickup(at: Vector2, type: String, value: float) -> void:
	var pickup := PICKUP_SCENE.instantiate() as Node2D
	pickup.global_position = at
	pickup.set_meta("pickup_type", type)
	pickup.set_meta("pickup_value", value)
	get_parent().call_deferred("add_child", pickup)
