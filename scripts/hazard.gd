extends Area2D

@export var damage_to_player: float = 10.0
@export var damage_to_enemy: float = 50.0
const BOUNCE_STRENGTH := 200.0
const PLAYER_KNOCKBACK_STRENGTH := 800.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.get("is_dashing") == true:
			return
		body.take_damage(damage_to_player)
		var away := (body.global_position - global_position).normalized()
		if away.length() > 0.01:
			body.apply_knockback(away * PLAYER_KNOCKBACK_STRENGTH)
		else:
			body.apply_knockback(Vector2.RIGHT * PLAYER_KNOCKBACK_STRENGTH)
	elif body.is_in_group("enemies"):
		body.take_hazard_damage(damage_to_enemy)
		# If enemy survived, apply bounce so they don't get stuck
		if body.get("health") != null and (body.get("health") as float) > 0.0:
			body.take_damage(0.0, _bounce_direction(body), BOUNCE_STRENGTH)

func _bounce_direction(body: Node2D) -> Vector2:
	var away := (body.global_position - global_position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	return away
