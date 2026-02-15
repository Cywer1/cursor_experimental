extends CharacterBody2D

signal died
signal health_changed(current: float, max_val: float)
signal currency_changed(amount: int)

const BASE_SPEED := 600.0
const BASE_HEALTH_MAX := 100.0
const DASH_SPEED := 1200.0
const DASH_DURATION := 0.45
const DASH_COOLDOWN := 0.8
const BASE_STAMINA_MAX := 100.0
const STAMINA_DASH_COST := 25.0
const STAMINA_REGEN_PER_SEC := 30.0
const INVINCIBILITY_DURATION := 1.0
const HIT_ALPHA_PULSE_DURATION := 0.5
const BASE_DASH_DAMAGE := 20.0
const DASH_KNOCKBACK_STRENGTH := 800.0
const KNOCKBACK_FRICTION := 800.0
const KNOCKBACK_STOP_SPEED := 50.0
const MAGNET_MAX_DISTANCE := 400.0
const MAGNET_MAX_ANGLE_RAD := 0.5

var health_max: float = BASE_HEALTH_MAX
var health: float = BASE_HEALTH_MAX
var stamina_max: float = BASE_STAMINA_MAX
var stamina: float = BASE_STAMINA_MAX
var speed: float = BASE_SPEED
var dash_damage: float = BASE_DASH_DAMAGE
var dash_knockback_strength: float = DASH_KNOCKBACK_STRENGTH
var stamina_regen_per_sec: float = STAMINA_REGEN_PER_SEC
var currency: int = 0
var invincibility_timer := 0.0
var hit_effect_timer := 0.0
var is_dashing := false
var dash_timer := 0.0
var dash_direction := Vector2.ZERO
var dash_cooldown_timer := 0.0
var knockback_velocity := Vector2.ZERO
var _dash_hit_enemies: Array[Node] = []

@onready var dash_damage_area: Area2D = $DashDamageArea
@onready var ghosts_container: Node2D = $Ghosts
@onready var ghost1: Sprite2D = $Ghosts/Ghost1
@onready var ghost2: Sprite2D = $Ghosts/Ghost2
@onready var ghost3: Sprite2D = $Ghosts/Ghost3

func _ready() -> void:
	health_changed.emit(health, health_max)

func _process(delta: float) -> void:
	invincibility_timer = maxf(0.0, invincibility_timer - delta)
	hit_effect_timer = maxf(0.0, hit_effect_timer - delta)
	_update_hit_effect()
	_update_ghosts()

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

	# Knocked back: ignore input, apply friction, show stunned
	if knockback_velocity.length() > KNOCKBACK_STOP_SPEED:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_FRICTION * delta)
		$Sprite2D.modulate = Color(1, 0.5, 0.5)
		move_and_slide()
		return

	# Normal: white sprite, input + speed
	$Sprite2D.modulate = Color.WHITE
	if dash_cooldown_timer <= 0.0:
		stamina = minf(stamina_max, stamina + stamina_regen_per_sec * delta)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_action_just_pressed("dash"):
		if dash_cooldown_timer <= 0.0 and stamina >= STAMINA_DASH_COST:
			dash_direction = direction if direction != Vector2.ZERO else Vector2.RIGHT
			stamina -= STAMINA_DASH_COST
			_dash_hit_enemies.clear()
			is_dashing = true
			dash_timer = DASH_DURATION
			return
	velocity = direction * speed
	move_and_slide()

func _update_ghosts() -> void:
	var sprite := $Sprite2D
	if is_dashing:
		ghosts_container.visible = true
		var dir := -dash_direction
		var color := Color(0.4, 0.7, 1.0)
		ghost1.position = dir * 20.0
		ghost1.modulate = Color(color.r, color.g, color.b, 0.6)
		ghost1.flip_h = sprite.flip_h
		ghost2.position = dir * 40.0
		ghost2.modulate = Color(color.r, color.g, color.b, 0.4)
		ghost2.flip_h = sprite.flip_h
		ghost3.position = dir * 60.0
		ghost3.modulate = Color(color.r, color.g, color.b, 0.2)
		ghost3.flip_h = sprite.flip_h
	elif knockback_velocity.length() > KNOCKBACK_STOP_SPEED:
		ghosts_container.visible = true
		var dir := -knockback_velocity.normalized()
		if dir.length() < 0.01:
			dir = Vector2.RIGHT
		var color := Color(1.0, 0.35, 0.35)
		ghost1.position = dir * 20.0
		ghost1.modulate = Color(color.r, color.g, color.b, 0.6)
		ghost1.flip_h = sprite.flip_h
		ghost2.position = dir * 40.0
		ghost2.modulate = Color(color.r, color.g, color.b, 0.4)
		ghost2.flip_h = sprite.flip_h
		ghost3.position = dir * 60.0
		ghost3.modulate = Color(color.r, color.g, color.b, 0.2)
		ghost3.flip_h = sprite.flip_h
	else:
		ghosts_container.visible = false

func add_currency(amount: int) -> void:
	currency += amount
	currency_changed.emit(currency)

func apply_knockback(force: Vector2) -> void:
	knockback_velocity = force

func take_damage(amount: float) -> bool:
	if invincibility_timer > 0.0 or is_dashing:
		return false
	health -= amount
	health_changed.emit(health, health_max)
	invincibility_timer = INVINCIBILITY_DURATION
	hit_effect_timer = HIT_ALPHA_PULSE_DURATION
	_spawn_hit_effect()
	if health <= 0.0:
		died.emit()
		queue_free()
	return true

func _check_dash_damage() -> void:
	var knockback_dir := _get_magnetized_knockback_dir(global_position, dash_direction)
	if knockback_dir == Vector2.ZERO:
		knockback_dir = dash_direction
	for body in dash_damage_area.get_overlapping_bodies():
		if body.is_in_group("enemies") and body not in _dash_hit_enemies:
			body.take_damage(dash_damage, knockback_dir, dash_knockback_strength)
			_dash_hit_enemies.append(body)
			$Camera2D.apply_shake(8.0, 0.15)

func _get_magnetized_knockback_dir(start_pos: Vector2, original_dir: Vector2) -> Vector2:
	if original_dir.length() < 0.01:
		return original_dir
	var tree := get_tree()
	var candidates: Array = []
	for group_name in ["hazards", "enemies"]:
		for node in tree.get_nodes_in_group(group_name):
			var n2d := node as Node2D
			if n2d == null:
				continue
			var to_target := n2d.global_position - start_pos
			var dist := to_target.length()
			if dist < 0.01 or dist > MAGNET_MAX_DISTANCE:
				continue
			var dir_to_target := to_target.normalized()
			var angle_diff: float = abs(original_dir.angle_to(dir_to_target))
			if angle_diff > MAGNET_MAX_ANGLE_RAD:
				continue
			candidates.append({"dir": dir_to_target, "angle": angle_diff})
	if candidates.is_empty():
		return original_dir
	var best: Dictionary = candidates[0]
	for c in candidates:
		if (c as Dictionary).angle < best.angle:
			best = c as Dictionary
	return best.dir as Vector2

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
