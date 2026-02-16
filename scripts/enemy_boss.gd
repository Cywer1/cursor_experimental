extends "res://scripts/enemy.gd"

enum State { CHASE, NOVA, SUMMON }

const BASE_HP := 2000.0
const BASE_SPEED := 50.0
const NOVA_INTERVAL := 4.0
const SUMMON_INTERVAL := 8.0
const NOVA_PROJECTILE_COUNT := 8
const SUMMON_COUNT := 2
const SUMMON_OFFSET_RADIUS := 80.0
const KNOCKBACK_RESISTANCE := 0.1
const CONTACT_KNOCKBACK := 1000.0
const PROJECTILE_BASE_SPEED := 400.0

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn") as PackedScene
const ENEMY_CHASER_SCENE := preload("res://scenes/enemy.tscn") as PackedScene

signal boss_health_changed(current: float, max_hp: float)
signal boss_died

var tier: int = 1
var state := State.CHASE
var nova_timer: float = 0.0
var summon_timer: float = 0.0
var _current_speed: float = BASE_SPEED
var _bullet_speed_mult: float = 1.0

func _ready() -> void:
	# Scaling by tier
	health = BASE_HP * tier
	set("max_health", BASE_HP * tier)
	_current_speed = BASE_SPEED * (1.0 + (tier * 0.1))
	_bullet_speed_mult = 1.0 + (tier * 0.2)
	nova_timer = NOVA_INTERVAL
	summon_timer = SUMMON_INTERVAL
	boss_health_changed.emit(health, max_health)

func take_damage(amount: float, knockback_force: Vector2 = Vector2.ZERO, knockback_strength: float = 0.0) -> void:
	FloatingTextManager.show_damage(global_position, amount)
	var reduced_strength := knockback_strength * KNOCKBACK_RESISTANCE
	health -= amount
	if knockback_force != Vector2.ZERO and reduced_strength > 0.0:
		velocity = knockback_force.normalized() * reduced_strength
		knockback_velocity = velocity
		is_knocked_back = true
	boss_health_changed.emit(health, max_health)
	if health <= 0.0:
		boss_died.emit()
		queue_free()

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

	match state:
		State.CHASE:
			nova_timer -= delta
			summon_timer -= delta
			if summon_timer <= 0.0:
				state = State.SUMMON
				velocity = Vector2.ZERO
				_do_summon()
				summon_timer = SUMMON_INTERVAL
				state = State.CHASE
			elif nova_timer <= 0.0:
				state = State.NOVA
				velocity = Vector2.ZERO
				_do_nova()
				nova_timer = NOVA_INTERVAL
				state = State.CHASE
			else:
				_chase_player(delta)
		State.NOVA:
			velocity = Vector2.ZERO
		State.SUMMON:
			velocity = Vector2.ZERO

	rotation = lerp_angle(rotation, 0.0, delta * 5.0)
	move_and_slide()
	_check_pinball_collision()

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
			if d < HAZARD_AVOID_DISTANCE and d > 0.01:
				direction += (global_position - node.global_position).normalized()
	if direction.length() > 0.01:
		direction = direction.normalized()
	velocity = direction * _current_speed

func _check_hitbox_overlap() -> void:
	for body in hitbox.get_overlapping_bodies():
		if body == self:
			continue
		if body.is_in_group("player"):
			if hit_cooldown_timer <= 0.0 and body.take_damage(CONTACT_DAMAGE):
				hit_cooldown_timer = HIT_COOLDOWN
				var dir := (body.global_position - global_position).normalized()
				if dir.length() < 0.01:
					dir = Vector2.RIGHT
				body.apply_knockback(dir * CONTACT_KNOCKBACK)
			break

func _do_nova() -> void:
	var step_angle := TAU / float(NOVA_PROJECTILE_COUNT)
	for i in NOVA_PROJECTILE_COUNT:
		var angle := step_angle * i
		var dir := Vector2.from_angle(angle)
		var proj := PROJECTILE_SCENE.instantiate() as Area2D
		proj.global_position = global_position
		proj.direction = dir
		proj.speed = PROJECTILE_BASE_SPEED * _bullet_speed_mult
		get_parent().add_child(proj)

func _do_summon() -> void:
	for i in SUMMON_COUNT:
		var offset := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * SUMMON_OFFSET_RADIUS
		if offset.length() < 10.0:
			offset = Vector2.RIGHT * SUMMON_OFFSET_RADIUS
		var spawn_pos := global_position + offset
		var chaser := ENEMY_CHASER_SCENE.instantiate() as Node2D
		chaser.global_position = spawn_pos
		get_parent().add_child(chaser)
