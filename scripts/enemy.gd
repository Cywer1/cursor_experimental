extends CharacterBody2D

const SPEED := 220.0
const FRICTION := 1200.0
const CONTACT_DAMAGE := 10
const HIT_COOLDOWN := 1.0
const MAX_HEALTH := 30.0
const KNOCKBACK_FORCE := 350.0
const KNOCKBACK_MIN_DISTANCE := 80.0
const PINBALL_DAMAGE := 15.0
const PINBALL_SPEED_THRESHOLD := 200.0
const PINBALL_BOUNCE_DAMPING := 0.5
const HAZARD_AVOID_DISTANCE := 100.0
const KNOCKBACK_STOP_SPEED := 50.0

var health := MAX_HEALTH
var max_health: float = MAX_HEALTH
var hit_cooldown_timer := 0.0
var knockback_velocity := Vector2.ZERO
var is_knocked_back := false

@onready var hitbox: Area2D = $Hitbox

func _physics_process(delta: float) -> void:
	hit_cooldown_timer = maxf(0.0, hit_cooldown_timer - delta)
	_check_hitbox_overlap()
	if is_knocked_back:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		knockback_velocity = velocity
		rotation += velocity.length() * 0.008 * delta
		if velocity.length() < KNOCKBACK_STOP_SPEED:
			is_knocked_back = false
			knockback_velocity = Vector2.ZERO
	else:
		rotation = lerp_angle(rotation, 0.0, delta * 5.0)
		_chase_player(delta)
	move_and_slide()
	_check_pinball_collision()

func _chase_player(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		return
	var direction := (player.global_position - global_position).normalized()
	# Avoid hazards: repulsion from any hazard within range
	for hazard in get_tree().get_nodes_in_group("hazards"):
		var node := hazard as Node2D
		if node != null:
			var d := global_position.distance_to(node.global_position)
			if d < HAZARD_AVOID_DISTANCE and d > 0.01:
				direction += (global_position - node.global_position).normalized()
	if direction.length() > 0.01:
		direction = direction.normalized()
	velocity = direction * SPEED

const COLLECTABLE_SCENE := preload("res://scenes/collectable.tscn") as PackedScene

func take_damage(amount: float, knockback_force: Vector2 = Vector2.ZERO, knockback_strength: float = 0.0) -> void:
	FloatingTextManager.show_damage(global_position, amount)
	health -= amount
	if knockback_force != Vector2.ZERO and knockback_strength > 0.0:
		velocity = knockback_force.normalized() * knockback_strength
		knockback_velocity = velocity
		is_knocked_back = true
	if health <= 0.0:
		var collectable := COLLECTABLE_SCENE.instantiate() as Node2D
		collectable.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", collectable)
		call_deferred("queue_free")

func _check_pinball_collision() -> void:
	# Only deal damage when launched by knockback; normal bumping does nothing
	if not is_knocked_back or velocity.length() < PINBALL_SPEED_THRESHOLD:
		return
	var count := get_slide_collision_count()
	for i in count:
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is CharacterBody2D and collider.is_in_group("enemies") and collider != self:
			collider.take_damage(PINBALL_DAMAGE)
			velocity = velocity.bounce(collision.get_normal()) * PINBALL_BOUNCE_DAMPING
			knockback_velocity = velocity
			break

func _check_hitbox_overlap() -> void:
	for body in hitbox.get_overlapping_bodies():
		if body == self:
			continue
		if body.is_in_group("player"):
			if hit_cooldown_timer <= 0.0 and body.take_damage(CONTACT_DAMAGE):
				hit_cooldown_timer = HIT_COOLDOWN
				var direction := (body.global_position - global_position).normalized()
				if direction.length() < 0.01:
					direction = Vector2.RIGHT
				body.apply_knockback(direction * 400.0)
			break
