extends Area2D

const CUBE_SIZE := 24
const POP_DISTANCE := 25.0
const POP_DURATION := 0.2
const COLLECT_DELAY := 0.6

var _can_pickup := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Cube visual: 24x24 white square, then color by type
	var img := Image.create(CUBE_SIZE, CUBE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex := ImageTexture.create_from_image(img)
	var sprite := $Sprite2D
	sprite.texture = tex
	sprite.scale = Vector2(0.7, 0.7)
	if not has_meta("pickup_type"):
		return
	var type: String = get_meta("pickup_type")
	if type == "health":
		sprite.modulate = Color(1, 0.25, 0.25)
	elif type == "stamina":
		sprite.modulate = Color(0.2, 0.85, 0.2)
	# Pop-out: start inside crate, tween to rest position
	var rest_pos := global_position
	var dir := Vector2.RIGHT.rotated(randf() * TAU)
	global_position = rest_pos - dir * POP_DISTANCE
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", rest_pos, POP_DURATION)
	await get_tree().create_timer(COLLECT_DELAY).timeout
	_can_pickup = true

func _on_body_entered(body: Node2D) -> void:
	if not _can_pickup:
		return
	if not body.is_in_group("player"):
		return
	if not has_meta("pickup_type"):
		queue_free()
		return
	var type: String = get_meta("pickup_type")
	var value: float = get_meta("pickup_value")
	if type == "health" and "heal" in body:
		body.heal(value)
	elif type == "stamina" and "stamina" in body and "stamina_max" in body:
		body.stamina = minf(body.stamina + value, body.stamina_max)
	var pickup_snd := load("res://assets/sounds/pickup.wav") as AudioStream
	if pickup_snd and SoundManager:
		SoundManager.play_sfx(pickup_snd)
	queue_free()
