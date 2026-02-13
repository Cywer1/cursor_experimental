extends CharacterBody2D

signal died
signal health_changed(current: float, max_val: float)

const SPEED = 600.0
const HEALTH_MAX := 100.0
const DASH_SPEED := 1200.0
const DASH_DURATION := 0.45
const DASH_COOLDOWN := 0.8
const STAMINA_MAX := 100.0
const STAMINA_DASH_COST := 25.0
const STAMINA_REGEN_PER_SEC := 30.0
const INVINCIBILITY_DURATION := 1.0
const HIT_ALPHA_PULSE_DURATION := 0.5
const DASH_DAMAGE := 20.0

var health: float = HEALTH_MAX
var stamina: float = STAMINA_MAX
var invincibility_timer := 0.0
var hit_effect_timer := 0.0
var is_dashing := false
var dash_timer := 0.0
var dash_direction := Vector2.ZERO
var dash_cooldown_timer := 0.0
var _dash_hit_enemies: Array[Node] = []

@onready var dash_damage_area: Area2D = $DashDamageArea

func _ready() -> void:
	health_changed.emit(health, HEALTH_MAX)

func _process(delta: float) -> void:
	invincibility_timer = maxf(0.0, invincibility_timer - delta)
	hit_effect_timer = maxf(0.0, hit_effect_timer - delta)
	_update_hit_effect()

func _physics_process(delta: float) -> void:
	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)

	if is_dashing:
		velocity = dash_direction * DASH_SPEED
		move_and_slide()
		_check_dash_damage()
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			dash_cooldown_timer = DASH_COOLDOWN
		return

	# Regenerate stamina when not on cooldown
	if dash_cooldown_timer <= 0.0:
		stamina = minf(STAMINA_MAX, stamina + STAMINA_REGEN_PER_SEC * delta)

	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Try to start dash (add "dash" in Project → Input Map, e.g. Shift or Space)
	if Input.is_action_just_pressed("dash"):
		if dash_cooldown_timer <= 0.0 and stamina >= STAMINA_DASH_COST:
			dash_direction = direction if direction != Vector2.ZERO else Vector2.RIGHT
			stamina -= STAMINA_DASH_COST
			_dash_hit_enemies.clear()
			is_dashing = true
			dash_timer = DASH_DURATION
			return

	velocity = direction * SPEED
	move_and_slide()

func take_damage(amount: float) -> bool:
	if invincibility_timer > 0.0 or is_dashing:
		return false
	health -= amount
	health_changed.emit(health, HEALTH_MAX)
	invincibility_timer = INVINCIBILITY_DURATION
	hit_effect_timer = HIT_ALPHA_PULSE_DURATION
	_spawn_hit_effect()
	if health <= 0.0:
		died.emit()
		queue_free()
	return true

func _check_dash_damage() -> void:
	for body in dash_damage_area.get_overlapping_bodies():
		if body.is_in_group("enemies") and body not in _dash_hit_enemies:
			body.take_damage(DASH_DAMAGE)
			_dash_hit_enemies.append(body)

func _update_hit_effect() -> void:
	var sprite := $Sprite2D as Sprite2D
	if hit_effect_timer <= 0.0:
		sprite.modulate = Color(1, 1, 1, 1)
		return
	var t := 1.0 - hit_effect_timer / HIT_ALPHA_PULSE_DURATION
	var alpha := 0.2 + 0.8 * (0.5 + 0.5 * sin(t * TAU * 4.0))
	sprite.modulate = Color(1, 1, 1, alpha)

func _spawn_hit_effect() -> void:
	var scene := preload("res://scenes/hit_effect.tscn") as PackedScene
	var effect := scene.instantiate() as Node2D
	effect.global_position = global_position
	get_parent().add_child(effect)
