extends CharacterBody2D

const SPEED := 220.0
const CONTACT_DAMAGE := 10
const HIT_COOLDOWN := 1.0
const MAX_HEALTH := 30.0
const KNOCKBACK_FORCE := 350.0
const KNOCKBACK_DECAY := 0.92
const KNOCKBACK_MIN_DISTANCE := 80.0

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
	else:
		knockback_velocity = Vector2.ZERO
		_chase_player(delta)
	move_and_slide()

func _chase_player(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		return
	var direction := (player.global_position - global_position).normalized()
	velocity = direction * SPEED

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		queue_free()

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
