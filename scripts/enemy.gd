extends CharacterBody2D

const SPEED := 220.0
const CONTACT_DAMAGE := 10
const HIT_COOLDOWN := 1.0
const MAX_HEALTH := 30.0
const KNOCKBACK_FORCE := 350.0
const KNOCKBACK_DECAY := 0.92
const KNOCKBACK_MIN_DISTANCE := 80.0
const PINBALL_DAMAGE := 15.0
const PINBALL_SPEED_THRESHOLD := 200.0
const PINBALL_BOUNCE_DAMPING := 0.5

var health := MAX_HEALTH
var hit_cooldown_timer := 0.0
var knockback_velocity := Vector2.ZERO

@onready var hitbox: Area2D = $Hitbox

func _physics_process(delta: float) -> void:
	hit_cooldown_timer = maxf(0.0, hit_cooldown_timer - delta)
	_check_hitbox_overlap()
	if knockback_velocity.length() > 5.0:
		velocity = knockback_velocity
		knockback_velocity *= KNOCKBACK_DECAY
		rotation += velocity.length() * 0.008 * delta
	else:
		knockback_velocity = Vector2.ZERO
		rotation = lerp_angle(rotation, 0.0, delta * 5.0)
		_chase_player(delta)
	move_and_slide()
	_check_pinball_collision()

func _chase_player(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		return
	var direction := (player.global_position - global_position).normalized()
	velocity = direction * SPEED

const COLLECTABLE_SCENE := preload("res://scenes/collectable.tscn") as PackedScene

func take_damage(amount: float, knockback_force: Vector2 = Vector2.ZERO, knockback_strength: float = 0.0) -> void:
	health -= amount
	if knockback_force != Vector2.ZERO and knockback_strength > 0.0:
		knockback_velocity = knockback_force.normalized() * knockback_strength
	if health <= 0.0:
		var collectable := COLLECTABLE_SCENE.instantiate() as Node2D
		collectable.global_position = global_position
		get_parent().add_child(collectable)
		queue_free()

func _check_pinball_collision() -> void:
	if velocity.length() < PINBALL_SPEED_THRESHOLD:
		return
	var count := get_slide_collision_count()
	for i in count:
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is CharacterBody2D and collider.is_in_group("enemies") and collider != self:
			collider.take_damage(PINBALL_DAMAGE)
			knockback_velocity = velocity.bounce(collision.get_normal()) * PINBALL_BOUNCE_DAMPING
			break

func _check_hitbox_overlap() -> void:
	for body in hitbox.get_overlapping_bodies():
		if body == self:
			continue
		if body.is_in_group("player"):
			if hit_cooldown_timer <= 0.0 and body.take_damage(CONTACT_DAMAGE):
				hit_cooldown_timer = HIT_COOLDOWN
				var away := (global_position - body.global_position).normalized()
				if away == Vector2.ZERO:
					away = Vector2.RIGHT
				global_position += away * KNOCKBACK_MIN_DISTANCE
				knockback_velocity = away * KNOCKBACK_FORCE
			break
