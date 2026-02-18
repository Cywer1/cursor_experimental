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
const KNOCKBACK_STOP_SPEED := 50.0

var hazard_avoid_distance: float = 100.0
var health := MAX_HEALTH
var max_health: float = MAX_HEALTH
var hit_cooldown_timer := 0.0
var knockback_velocity := Vector2.ZERO
var is_knocked_back := false

@export var hit_sfx: AudioStream
@export var death_sfx: AudioStream

@onready var hitbox: Area2D = $Hitbox

func _physics_process(delta: float) -> void:
	hit_cooldown_timer = maxf(0.0, hit_cooldown_timer - delta)
	_check_hitbox_overlap(delta)
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
			if d < hazard_avoid_distance and d > 0.01:
				direction += (global_position - node.global_position).normalized()
	if direction.length() > 0.01:
		direction = direction.normalized()
	velocity = direction * SPEED

const COLLECTABLE_SCENE := preload("res://scenes/collectable.tscn") as PackedScene
const EXPLOSION_EFFECT_SCENE := preload("res://scenes/explosion_effect.tscn") as PackedScene
const EXPLOSION_RADIUS := 150.0
const EXPLOSION_DAMAGE := 50.0
const EXPLOSION_KNOCKBACK_STRENGTH := 500.0
const VAMPIRE_HEAL_AMOUNT := 2.0
const LOOT_LUCKY_CHANCE := 0.1
const LOOT_OFFSET_RADIUS := 12.0

func take_hazard_damage(amount: float) -> void:
	if is_knocked_back:
		take_damage(amount)

func take_damage(amount: float, knockback_force: Vector2 = Vector2.ZERO, knockback_strength: float = 0.0) -> void:
	FloatingTextManager.show_damage(global_position, amount)
	if hit_sfx:
		SoundManager.play_sfx(hit_sfx)
	health -= amount
	if knockback_force != Vector2.ZERO and knockback_strength > 0.0:
		var force := knockback_force.normalized() * knockback_strength
		var random_angle := deg_to_rad(randf_range(-25, 25))
		knockback_velocity = force.rotated(random_angle)
		velocity = knockback_velocity
		is_knocked_back = true
	if health <= 0.0:
		if death_sfx:
			SoundManager.play_sfx(death_sfx)
		var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
		if player != null:
			if randf() < player.vampire_chance:
				player.heal(VAMPIRE_HEAL_AMOUNT)
			if randf() < player.explosive_chance:
				_trigger_explosion()
		var spawn_pos := global_position
		for hazard in get_tree().get_nodes_in_group("hazards"):
			var node := hazard as Node2D
			if node != null and spawn_pos.distance_to(node.global_position) < 80.0:
				var away := (spawn_pos - node.global_position).normalized()
				if away.length() > 0.01:
					spawn_pos += away * 100.0
		var scrap_count := 3 if randf() < LOOT_LUCKY_CHANCE else 1
		var scene := get_tree().current_scene
		for i in scrap_count:
			var collectable := COLLECTABLE_SCENE.instantiate() as Node2D
			var offset := Vector2.ZERO
			if scrap_count > 1:
				offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * LOOT_OFFSET_RADIUS
				if offset.length() < 2.0:
					offset = Vector2.RIGHT.rotated(randf() * TAU) * LOOT_OFFSET_RADIUS
			collectable.global_position = spawn_pos + offset
			scene.call_deferred("add_child", collectable)
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
				var direction := (body.global_position - global_position).normalized()
				if direction.length() < 0.01:
					direction = Vector2.RIGHT
				body.apply_knockback(direction * 400.0)
			break

func _trigger_explosion() -> void:
	var center := global_position
	var space := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = EXPLOSION_RADIUS
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, center)
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var results := space.intersect_shape(params)
	for result in results:
		var collider = result.collider
		if collider == self:
			continue
		if collider is CharacterBody2D and collider.is_in_group("enemies"):
			var dir: Vector2 = (collider.global_position - center).normalized()
			if dir.length() < 0.01:
				dir = Vector2.RIGHT
			collider.take_damage(EXPLOSION_DAMAGE, dir, EXPLOSION_KNOCKBACK_STRENGTH)
	var effect := EXPLOSION_EFFECT_SCENE.instantiate() as Node2D
	effect.global_position = center
	get_parent().add_child(effect)
