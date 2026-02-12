extends CharacterBody2D

const SPEED = 300.0
const DASH_SPEED := 600.0
const DASH_DURATION := 0.45
const DASH_COOLDOWN := 0.8
const STAMINA_MAX := 100.0
const STAMINA_DASH_COST := 25.0
const STAMINA_REGEN_PER_SEC := 30.0

var stamina: float = STAMINA_MAX
var is_dashing := false
var dash_timer := 0.0
var dash_direction := Vector2.ZERO
var dash_cooldown_timer := 0.0

func _physics_process(delta: float) -> void:
	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)

	if is_dashing:
		velocity = dash_direction * DASH_SPEED
		move_and_slide()
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
			is_dashing = true
			dash_timer = DASH_DURATION
			return

	velocity = direction * SPEED
	move_and_slide()
