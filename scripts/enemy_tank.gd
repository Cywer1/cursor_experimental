extends "res://scripts/enemy.gd"

const TANK_MAX_HEALTH := 80.0
const TANK_SPEED := 60.0
const KNOCKBACK_RESISTANCE := 0.1
const CONTACT_KNOCKBACK := 1000.0

func _ready() -> void:
	health = TANK_MAX_HEALTH
	set("max_health", TANK_MAX_HEALTH)

func take_damage(amount: float, knockback_force: Vector2 = Vector2.ZERO, knockback_strength: float = 0.0) -> void:
	var reduced_strength := knockback_strength * KNOCKBACK_RESISTANCE
	super.take_damage(amount, knockback_force, reduced_strength)

func _chase_player(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		velocity = Vector2.ZERO
		return
	var direction := (player.global_position - global_position).normalized()
	for hazard in get_tree().get_nodes_in_group("hazards"):
		var node := hazard as Node2D
		if node != null:
			var d := global_position.distance_to(node.global_position)
			if d < hazard_avoid_distance and d > 0.01:
				direction += (global_position - node.global_position).normalized()
	if direction.length() > 0.01:
		direction = direction.normalized()
	velocity = direction * TANK_SPEED

func _check_hitbox_overlap(delta: float) -> void:
	if is_knocked_back:
		return
	for body in hitbox.get_overlapping_bodies():
		if body == self:
			continue
		if body.is_in_group("player"):
			if body.get("thorns_damage") != null and body.thorns_damage > 0.0:
				take_damage(body.thorns_damage * delta)
			if hit_cooldown_timer <= 0.0 and body.take_damage(CONTACT_DAMAGE):
				hit_cooldown_timer = HIT_COOLDOWN
				var dir := (body.global_position - global_position).normalized()
				if dir.length() < 0.01:
					dir = Vector2.RIGHT
				body.apply_knockback(dir * CONTACT_KNOCKBACK)
			break
