extends "res://scripts/enemy.gd"

enum State { MAINTAIN_DIST, SHOOT }

const SHOOTER_SPEED := 100.0
const MIN_DIST := 300.0
const MAX_DIST := 500.0
const SHOOT_INTERVAL := 2.0
const SHOOT_FLASH_DURATION := 0.2
const AIM_RANDOM_RANGE := 25.0

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn") as PackedScene

var state := State.MAINTAIN_DIST
var shoot_timer := 0.0
var shoot_flash_timer := 0.0
var _normal_modulate: Color = Color(0.65, 0.2, 0.9, 1)

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_normal_modulate = sprite.modulate

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
		move_and_slide()
		_check_pinball_collision()
		return

	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D

	if shoot_flash_timer > 0.0:
		shoot_flash_timer -= delta
		if shoot_flash_timer <= 0.0:
			sprite.modulate = _normal_modulate

	match state:
		State.MAINTAIN_DIST:
			shoot_timer -= delta
			if shoot_timer <= 0.0:
				state = State.SHOOT
				velocity = Vector2.ZERO
				sprite.modulate = Color.WHITE
				shoot_flash_timer = SHOOT_FLASH_DURATION
				_fire_projectile(player)
				shoot_timer = SHOOT_INTERVAL
			elif player != null:
				var dist := global_position.distance_to(player.global_position)
				var dir: Vector2
				if dist < MIN_DIST:
					dir = (global_position - player.global_position).normalized()
				elif dist > MAX_DIST:
					dir = (player.global_position - global_position).normalized()
				else:
					dir = Vector2.ZERO
				if dir.length() > 0.01:
					velocity = dir * SHOOTER_SPEED
				else:
					velocity = Vector2.ZERO
			else:
				velocity = Vector2.ZERO
		State.SHOOT:
			velocity = Vector2.ZERO
			state = State.MAINTAIN_DIST

	rotation = lerp_angle(rotation, 0.0, delta * 5.0)
	move_and_slide()
	_check_pinball_collision()

func _fire_projectile(player: CharacterBody2D) -> void:
	if player == null:
		return
	var target := player.global_position + Vector2(
		randf_range(-AIM_RANDOM_RANGE, AIM_RANDOM_RANGE),
		randf_range(-AIM_RANDOM_RANGE, AIM_RANDOM_RANGE)
	)
	var dir := (target - global_position).normalized()
	if dir.length() < 0.01:
		dir = Vector2.RIGHT
	var proj := PROJECTILE_SCENE.instantiate() as Area2D
	proj.global_position = global_position
	proj.direction = dir
	get_parent().add_child(proj)
