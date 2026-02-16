extends Area2D

var speed: float = 400.0
var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0
var is_hostile: bool = true

@export var deflect_sfx: AudioStream

const HOMING_RANGE := 800.0

func _get_homing_target() -> Vector2:
	var nearest: Node2D = null
	var nearest_dist := HOMING_RANGE
	for node in get_tree().get_nodes_in_group("enemies"):
		var n2d := node as Node2D
		if n2d == null:
			continue
		var d := global_position.distance_to(n2d.global_position)
		if d < nearest_dist and d > 0.01:
			nearest_dist = d
			nearest = n2d
	if nearest != null:
		var to_enemy := (nearest.global_position - global_position).normalized()
		if to_enemy.length() > 0.01:
			return to_enemy
	return -direction

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	rotation = direction.angle()
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.get("is_dashing") == true:
			# Deflect: homing toward nearest enemy or reverse path
			if deflect_sfx:
				SoundManager.play_sfx(deflect_sfx)
			is_hostile = false
			direction = _get_homing_target()
			if direction.length() < 0.01:
				direction = Vector2.RIGHT
			rotation = direction.angle()
			speed *= 1.5
			modulate = Color(0, 1, 1)
			set_collision_mask_value(1, false)
			set_collision_mask_value(2, true)
			return
		body.take_damage(damage)
		queue_free()
	elif body.is_in_group("enemies"):
		if not is_hostile:
			body.take_damage(50.0, direction, 1000.0)
			queue_free()
	else:
		queue_free()
