extends "res://scripts/enemy.gd"

enum State { CHASE, PREPARE, DASH, TIRED }

# Ranges for unpredictable AI
const CHASE_SPEED_MIN := 100.0
const CHASE_SPEED_MAX := 140.0
const CHARGE_RANGE_MIN := 220.0
const CHARGE_RANGE_MAX := 280.0
const CIRCLE_STRAFE_SPEED := 55.0
const CHARGE_DELAY_MIN := 0.5
const CHARGE_DELAY_MAX := 2.0
const PREPARE_DURATION_MIN := 0.4
const PREPARE_DURATION_MAX := 1.0
const CHARGE_SPEED_MIN := 750.0
const CHARGE_SPEED_MAX := 850.0
const DASH_DURATION_MIN := 0.25
const DASH_DURATION_MAX := 0.35
const TIRED_DURATION_MIN := 1.2
const TIRED_DURATION_MAX := 1.8
const TIRED_FRICTION := 400.0
const AIM_LINE_MAX_LENGTH := 600.0
const CHARGE_ENEMY_DAMAGE := 50.0
const CHARGE_KNOCKBACK_STRENGTH := 1000.0
const DASH_ROTATION_SPEED := 25.0
const GHOST_OFFSET_1 := 20.0
const GHOST_OFFSET_2 := 40.0
const GHOST_OFFSET_3 := 60.0
const AIM_WOBBLE_AMOUNT := 0.15

var state := State.CHASE
var charge_delay_timer := 0.0
var prepare_timer := 0.0
var dash_timer := 0.0
var tired_timer := 0.0
var aim_direction := Vector2.RIGHT
var charge_speed := 800.0
var tired_rotation_speed := DASH_ROTATION_SPEED

@onready var aim_line: Line2D = $AimLine
@onready var sprite: Sprite2D = $Sprite2D
@onready var ghosts_container: Node2D = get_node_or_null("Ghosts")
@onready var ghost1: Sprite2D = get_node_or_null("Ghosts/Ghost1")
@onready var ghost2: Sprite2D = get_node_or_null("Ghosts/Ghost2")
@onready var ghost3: Sprite2D = get_node_or_null("Ghosts/Ghost3")

func _ready() -> void:
	_setup_dashed_aim_line()
	if ghosts_container != null:
		ghosts_container.visible = false

func _setup_dashed_aim_line() -> void:
	var gradient := Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	gradient.add_point(0.0, Color(1, 0, 0, 1))
	gradient.add_point(0.5, Color(1, 0, 0, 0))
	var tex := GradientTexture1D.new()
	tex.gradient = gradient
	aim_line.texture = tex
	aim_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	aim_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	aim_line.width = 4.0

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
	match state:
		State.CHASE:
			_chase_state(delta, player)
		State.PREPARE:
			_prepare_state(delta)
		State.DASH:
			_dash_state(delta)
		State.TIRED:
			_tired_state(delta)

	# If we are in a normal state (CHASE or PREPARE) and not knocked back,
	# smoothly rotate back to upright (0 degrees).
	if state == State.CHASE or state == State.PREPARE:
		rotation = lerp_angle(rotation, 0.0, delta * 8.0)

	move_and_slide()
	if state == State.DASH:
		_check_charge_collisions()
	_check_pinball_collision()
	_update_ghosts()

func _chase_state(delta: float, player: CharacterBody2D) -> void:
	if player == null:
		velocity = Vector2.ZERO
		return
	var dir := (player.global_position - global_position).normalized()
	var dist := global_position.distance_to(player.global_position)
	var charge_range := randf_range(CHARGE_RANGE_MIN, CHARGE_RANGE_MAX)
	if dist < charge_range:
		if charge_delay_timer <= 0.0:
			charge_delay_timer = randf_range(CHARGE_DELAY_MIN, CHARGE_DELAY_MAX)
		charge_delay_timer -= delta
		# Circle strafe: move perpendicular to player while waiting to charge
		var perpendicular := Vector2(-dir.y, dir.x)
		velocity = perpendicular * CIRCLE_STRAFE_SPEED
		if charge_delay_timer <= 0.0:
			state = State.PREPARE
			prepare_timer = randf_range(PREPARE_DURATION_MIN, PREPARE_DURATION_MAX)
			aim_direction = dir
	else:
		var chase_speed := randf_range(CHASE_SPEED_MIN, CHASE_SPEED_MAX)
		velocity = dir * chase_speed

func _prepare_state(delta: float) -> void:
	velocity = Vector2.ZERO
	aim_line.visible = true
	var line_length := _get_aim_line_length()
	var wobble := randf_range(-AIM_WOBBLE_AMOUNT, AIM_WOBBLE_AMOUNT)
	var local_dir := aim_direction.rotated(-global_rotation + wobble)
	aim_line.points = [Vector2.ZERO, local_dir * line_length]
	prepare_timer -= delta
	if prepare_timer <= 0.0:
		state = State.DASH
		dash_timer = randf_range(DASH_DURATION_MIN, DASH_DURATION_MAX)
		charge_speed = randf_range(CHARGE_SPEED_MIN, CHARGE_SPEED_MAX)
		aim_line.visible = false
		tired_rotation_speed = DASH_ROTATION_SPEED

func _dash_state(delta: float) -> void:
	velocity = aim_direction * charge_speed
	rotation += DASH_ROTATION_SPEED * delta
	dash_timer -= delta
	if dash_timer <= 0.0:
		state = State.TIRED
		tired_rotation_speed = 0.0
		tired_timer = randf_range(TIRED_DURATION_MIN, TIRED_DURATION_MAX)

func _tired_state(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, TIRED_FRICTION * delta)
	tired_rotation_speed = move_toward(tired_rotation_speed, 0.0, 40.0 * delta)
	if tired_rotation_speed > 0.01:
		rotation += tired_rotation_speed * delta
	tired_timer -= delta
	if tired_timer <= 0.0:
		state = State.CHASE
		charge_delay_timer = 0.0

func _update_ghosts() -> void:
	if ghosts_container == null or ghost1 == null or ghost2 == null or ghost3 == null:
		return
	if state == State.DASH and velocity.length() > 10.0:
		ghosts_container.visible = true
		var dir := -velocity.normalized()
		if dir.length() < 0.01:
			dir = Vector2.RIGHT
		var color := Color(1.0, 0.6, 0.1)
		ghost1.position = dir * GHOST_OFFSET_1
		ghost1.modulate = Color(color.r, color.g, color.b, 0.6)
		ghost1.flip_h = sprite.flip_h
		ghost2.position = dir * GHOST_OFFSET_2
		ghost2.modulate = Color(color.r, color.g, color.b, 0.4)
		ghost2.flip_h = sprite.flip_h
		ghost3.position = dir * GHOST_OFFSET_3
		ghost3.modulate = Color(color.r, color.g, color.b, 0.2)
		ghost3.flip_h = sprite.flip_h
	else:
		ghosts_container.visible = false

func _get_aim_line_length() -> float:
	var from_pos := global_position
	var to_pos := global_position + aim_direction * AIM_LINE_MAX_LENGTH
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.exclude = [get_rid()]
	var result := space.intersect_ray(query)
	if not result:
		return AIM_LINE_MAX_LENGTH
	return from_pos.distance_to(result.position)

func _check_charge_collisions() -> void:
	var count := get_slide_collision_count()
	for i in count:
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider.is_in_group("enemies") and collider != self:
			collider.take_damage(CHARGE_ENEMY_DAMAGE, velocity.normalized(), CHARGE_KNOCKBACK_STRENGTH)
			_trigger_screen_shake(12.0, 0.2)
		elif collider.is_in_group("player"):
			if collider.take_damage(CONTACT_DAMAGE):
				var dir: Vector2 = (collider.global_position - global_position).normalized()
				if dir.length() > 0.01:
					collider.apply_knockback(dir * 400.0)
			_trigger_screen_shake(8.0, 0.15)

func _trigger_screen_shake(intensity: float, duration: float) -> void:
	var player_node := get_tree().get_first_node_in_group("player")
	if player_node != null and player_node.has_node("Camera2D"):
		var cam := player_node.get_node("Camera2D")
		if cam.has_method("apply_shake"):
			cam.apply_shake(intensity, duration)
